-- Crystal Aura Wayland entrypoint for SomeWM.
--
-- SomeWM implements the AwesomeWM Lua API, so Aura's Lua modules can remain
-- upstream. Keep the upstream autorun hook, but use the repository's
-- Wayland-safe replacement instead of Crystal's original X11 script.

local awful = require "awful"
local gears = require "gears"
local beautiful = require "beautiful"

awful.spawn.with_shell("bash ~/.config/awesome/main/autorun.sh")

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
