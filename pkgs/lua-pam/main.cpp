#include <lua.hpp>
#include <security/pam_appl.h>
#include <pwd.h>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

static struct pam_response *reply = nullptr;

static int simple_conversation(int num_msg, const struct pam_message **msg,
                               struct pam_response **resp, void *appdata_ptr) {
    (void)num_msg;
    (void)msg;
    (void)appdata_ptr;
    *resp = reply;
    return PAM_SUCCESS;
}

static int auth_current_user(lua_State *L) {
    const char *pass = luaL_checkstring(L, -1);

    uid_t uid = getuid();
    passwd *pw = getpwuid(uid);
    if (pw == nullptr) {
        lua_pushboolean(L, 0);
        return 1;
    }

    pam_handle_t *pamh = nullptr;
    struct pam_conv conv = { simple_conversation, nullptr };
    int retval = pam_start("login", pw->pw_name, &conv, &pamh);

    struct pam_response response = {};
    reply = &response;

    if (retval == PAM_SUCCESS) {
        response.resp = strdup(pass);
        response.resp_retcode = 0;
        retval = pam_authenticate(pamh, 0);
        pam_end(pamh, retval);
    }

    if (response.resp != nullptr) {
        std::memset(response.resp, 0, std::strlen(response.resp));
        std::free(response.resp);
    }
    reply = nullptr;

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
