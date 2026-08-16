-- Crystal Aura Wayland entrypoint for SomeWM.
--
-- SomeWM implements the AwesomeWM Lua API, so Aura's Lua modules can remain
-- upstream. This entrypoint removes the old X11 autorun dependency and lets
-- Nix/Home Manager provide the required Wayland-native helper programs.

local gears = require "gears"
local beautiful = require "beautiful"

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
