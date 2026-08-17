#include <lua.hpp>
#include <security/pam_appl.h>
#include <pwd.h>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

struct conversation_data {
    const char *username;
    const char *password;
};

static void free_responses(struct pam_response *responses, int count) {
    if (responses == nullptr) {
        return;
    }

    for (int i = 0; i < count; ++i) {
        if (responses[i].resp != nullptr) {
            std::memset(responses[i].resp, 0, std::strlen(responses[i].resp));
            std::free(responses[i].resp);
        }
    }

    std::free(responses);
}

static int pam_conversation(int num_msg, const struct pam_message **msg,
                            struct pam_response **resp, void *appdata_ptr) {
    if (num_msg <= 0 || msg == nullptr || resp == nullptr || appdata_ptr == nullptr) {
        return PAM_CONV_ERR;
    }

    const auto *data = static_cast<const conversation_data *>(appdata_ptr);
    auto *responses = static_cast<struct pam_response *>(
        std::calloc(static_cast<size_t>(num_msg), sizeof(struct pam_response)));

    if (responses == nullptr) {
        return PAM_BUF_ERR;
    }

    for (int i = 0; i < num_msg; ++i) {
        if (msg[i] == nullptr) {
            free_responses(responses, num_msg);
            return PAM_CONV_ERR;
        }

        switch (msg[i]->msg_style) {
        case PAM_PROMPT_ECHO_OFF:
            responses[i].resp = strdup(data->password);
            break;
        case PAM_PROMPT_ECHO_ON:
            responses[i].resp = strdup(data->username);
            break;
        case PAM_ERROR_MSG:
        case PAM_TEXT_INFO:
            // No response is required for informational PAM messages.
            break;
        default:
            free_responses(responses, num_msg);
            return PAM_CONV_ERR;
        }

        if ((msg[i]->msg_style == PAM_PROMPT_ECHO_OFF ||
             msg[i]->msg_style == PAM_PROMPT_ECHO_ON) &&
            responses[i].resp == nullptr) {
            free_responses(responses, num_msg);
            return PAM_BUF_ERR;
        }

        responses[i].resp_retcode = 0;
    }

    *resp = responses;
    return PAM_SUCCESS;
}

static int auth_current_user(lua_State *L) {
    const char *pass = luaL_checkstring(L, -1);

    const uid_t uid = getuid();
    passwd *pw = getpwuid(uid);
    if (pw == nullptr) {
        lua_pushboolean(L, 0);
        return 1;
    }

    conversation_data data = { pw->pw_name, pass };

    pam_handle_t *pamh = nullptr;
    struct pam_conv conv = { pam_conversation, &data };
    int retval = pam_start("login", pw->pw_name, &conv, &pamh);

    if (retval == PAM_SUCCESS) {
        retval = pam_authenticate(pamh, 0);
        pam_end(pamh, retval);
    }

    lua_pushboolean(L, retval == PAM_SUCCESS);
    return 1;
}

static const struct luaL_Reg lua_pam[] = {
    {"auth_current_user", auth_current_user},
    {nullptr, nullptr}
};

extern "C" int luaopen_liblua_pam(lua_State *L) {
    luaL_newlib(L, lua_pam);
    return 1;
}
