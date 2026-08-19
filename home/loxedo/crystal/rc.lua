-- Crystal Aura Wayland entrypoint for SomeWM.
--
-- SomeWM implements the AwesomeWM Lua API, so Aura's Lua modules can remain
-- upstream. The session wrapper prepares the Wayland environment and cache.

local awful = require "awful"
local gears = require "gears"
local beautiful = require "beautiful"
local awful = require "awful"

-- Preserve Crystal's startup contract: SomeWM must launch main/autorun.sh.
-- The Wayland-safe replacement imports the compositor's runtime environment
-- into the systemd user manager after WAYLAND_DISPLAY has been created.
awful.spawn.with_shell("bash ~/.config/awesome/main/autorun.sh")

-- Keep manual `somewm --config` launches deterministic too: Crystal's setup
-- module expects these parent directories to exist before it writes settings.
local cache_dir = gears.filesystem.get_cache_dir()
os.execute('mkdir -p "' .. cache_dir .. 'json" "' .. cache_dir .. 'lock"')

-- Crystal's upstream rc.lua starts main/autorun.sh before loading the rest of
-- the desktop. Keep that startup hook, but use the configuration directory so
-- it also works when Home Manager installs the config through /nix/store.
awful.spawn.with_shell(gears.filesystem.get_configuration_dir() .. "main/autorun.sh")

require "setup":generate()
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme/init.lua")
require "main"
require "awful.autofocus"
require "misc"
require "ui"
require "signal"

gears.timer {
  timeout = 5,
  autostart = true,
  call_now = true,
  callback = function()
    collectgarbage "collect"
  end,
}

collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)
