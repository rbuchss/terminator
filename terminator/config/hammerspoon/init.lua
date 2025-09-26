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

-- helper for app launchers

local function findFirstAvailableApp(bundleList)
  for _, bundle in ipairs(bundleList) do
    local bundleInfo = hs.application.infoForBundleID(bundle)

    if bundleInfo then
      return bundle
    end
  end

  return nil
end

local function resolveAppFromEnvOrList(envVarName, bundleList)
  local envApp = os.getenv(envVarName)


  if envApp then
    return envApp
  end

  return findFirstAvailableApp(bundleList)
end

-- app launcher
-- helper script to get bundle id
-- osascript -e 'id of app "Claude"'

local hotkey_q_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_Q_APP",
  {
    "com.anthropic.claudefordesktop",
    "com.openai.chat",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "Q", function()
  hs.application.launchOrFocusByBundleID(hotkey_q_app)
end)

local hotkey_w_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_W_APP",
  {
    "ai.perplexity.mac",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "W", function()
  hs.application.launchOrFocusByBundleID(hotkey_w_app)
end)

local hotkey_e_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_E_APP",
  {
    "notion.id",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "E", function()
  hs.application.launchOrFocusByBundleID(hotkey_e_app)
end)

local hotkey_a_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_A_APP",
  {
    "company.thebrowser.Browser",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "A", function()
  hs.application.launchOrFocusByBundleID(hotkey_a_app)
end)

local hotkey_s_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_S_APP",
  {
    "com.tinyspeck.slackmacgap",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "S", function()
  hs.application.launchOrFocusByBundleID(hotkey_s_app)
end)

local hotkey_d_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_D_APP",
  {
    "com.spotify.client",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "D", function()
  hs.application.launchOrFocusByBundleID(hotkey_d_app)
end)

local hotkey_z_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_Z_APP",
  {
    "com.googlecode.iterm2",
    "com.apple.Terminal",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "Z", function()
  hs.application.launchOrFocusByBundleID(hotkey_z_app)
end)

local hotkey_x_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_X_APP",
  {
    "com.jetbrains.pycharm",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "X", function()
  hs.application.launchOrFocusByBundleID(hotkey_x_app)
end)

local hotkey_c_app = resolveAppFromEnvOrList(
  "TERMINATOR_HAMMERSPOON_HOTKEY_C_APP",
  {
    "com.jetbrains.goland",
    "com.jetbrains.intellij",
  }
)

hs.hotkey.bind({"cmd", "alt"}, "C", function()
  hs.application.launchOrFocusByBundleID(hotkey_c_app)
end)

