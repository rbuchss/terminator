hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.ShiftIt = {
  url = "https://github.com/peterklijn/hammerspoon-shiftit",
  desc = "ShiftIt spoon repository",
  branch = "master",
}

spoon.SpoonInstall:andUse("ShiftIt", { repo = "ShiftIt" })

spoon.ShiftIt:setWindowCyclingSizes({ 50, 33, 67 }, { 50, 33, 67 })
spoon.ShiftIt:bindHotkeys({})

hs.hotkey.bind({"alt"}, "R", function()
  hs.reload()
  -- hs.alert.show("Config reloaded")
end)

-- app launcher

local hotkey_q_app = os.getenv("TERMINATOR_HAMMERSPOON_HOTKEY_Q_APP") or "ChatGPT"

hs.hotkey.bind({"cmd", "alt"}, "Q", function()
  hs.application.launchOrFocus(hotkey_q_app)
end)

local hotkey_w_app = os.getenv("TERMINATOR_HAMMERSPOON_HOTKEY_W_APP") or "Spotify"

hs.hotkey.bind({"cmd", "alt"}, "W", function()
  hs.application.launchOrFocus(hotkey_w_app)
end)

local hotkey_a_app = os.getenv("TERMINATOR_HAMMERSPOON_HOTKEY_A_APP") or "Arc"

hs.hotkey.bind({"cmd", "alt"}, "A", function()
  hs.application.launchOrFocus(hotkey_a_app)
end)

local hotkey_s_app = os.getenv("TERMINATOR_HAMMERSPOON_HOTKEY_S_APP") or "Slack"

hs.hotkey.bind({"cmd", "alt"}, "S", function()
  hs.application.launchOrFocus(hotkey_s_app)
end)

local hotkey_z_app = os.getenv("TERMINATOR_HAMMERSPOON_HOTKEY_Z_APP") or "iTerm"

hs.hotkey.bind({"cmd", "alt"}, "Z", function()
  hs.application.launchOrFocus(hotkey_z_app)
end)

local hotkey_x_app = os.getenv("TERMINATOR_HAMMERSPOON_HOTKEY_X_APP") or "PyCharm Professional Edition"

hs.hotkey.bind({"cmd", "alt"}, "X", function()
  hs.application.launchOrFocus(hotkey_x_app)
end)

local hotkey_c_app = os.getenv("TERMINATOR_HAMMERSPOON_HOTKEY_C_APP") or "IntelliJ IDEA Ultimate"

hs.hotkey.bind({"cmd", "alt"}, "C", function()
  hs.application.launchOrFocus(hotkey_c_app)
end)

