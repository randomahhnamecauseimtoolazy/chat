-- // Services \\
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local executor = identifyexecutor() or getexecutorname()

if executor == "Xeno" then
    Players.LocalPlayer:Kick("You're using a detected executor.")
	return
end

-- // Global State \\
if _G.ScriptIsRunning then
    game:GetService('StarterGui'):SetCore('SendNotification', {
        Title = 'Script Already Running',
        Text = 'The script is already executing. Please do not attempt to run it again.',
        Duration = 5,
    })
    return
end
_G.ScriptIsRunning = true

local library = loadstring(
    game:HttpGet(
        'https://raw.githubusercontent.com/randomahhnamecauseimtoolazy/chat/refs/heads/main/lib.lua'
    )
)()

local drawhelper = loadstring(
    game:HttpGet(
        'https://raw.githubusercontent.com/bottomnoah/UI/refs/heads/main/drawingbeta'
    )
)()

-- // Shared State \\
local State = {
    IsRightClickHeld = false,
    TargetPart = nil,
    OriginalProperties = {},
    CachedProperties = {},
    PlayersToDraw = {},
    Highlights = {},
    Storage = { ESPCache = {} },
    MousePreload = {
        Active = false,
        LastTime = 0,
        Interval = 5,
        Connection = nil,
    },
    CrosshairUpdate = nil,
    ChamsUpdateConnection = nil,
    PlayerCacheUpdate = nil,
    ESPLoop = nil,
    InputBeganConnection = nil,
    InputEndedConnection = nil,
    RenderSteppedConnection = nil,
}

-- // Check for mousemoverel support \\
local hasMouseMoveRel = type(mousemoverel) == 'function'
if not hasMouseMoveRel then
    game:GetService('StarterGui'):SetCore('SendNotification', {
        Title = 'Aimbot Unavailable',
        Text = 'This executor does not support mousemoverel. Aimbot functionality is not available.',
        Duration = 6,
    })
end

local baseUrl =
    'https://raw.githubusercontent.com/randomahhnamecauseimtoolazy/chat/refs/heads/main/'

-- // Load Modules \\
local Settings = loadstring(game:HttpGet(baseUrl .. 'settings.lua'))()
local Utilities = loadstring(game:HttpGet(baseUrl .. 'utilities.lua'))()
local Aimbot = hasMouseMoveRel
        and loadstring(game:HttpGet(baseUrl .. 'aimbot.lua'))()
    or nil
local ESP = loadstring(game:HttpGet(baseUrl .. 'esp.lua'))()
local FOV = loadstring(game:HttpGet(baseUrl .. 'fov.lua'))()
local Chams = loadstring(game:HttpGet(baseUrl .. 'chams.lua'))()
local Crosshair = loadstring(game:HttpGet(baseUrl .. 'crosshair.lua'))()
local PlayerMod = loadstring(game:HttpGet(baseUrl .. 'player.lua'))()
local Misc = loadstring(game:HttpGet(baseUrl .. 'misc.lua'))()
local UI = loadstring(game:HttpGet(baseUrl .. 'ui.lua'))()

-- // Initialize Modules \\
Utilities:Init(Settings, State)
if Aimbot then
    Aimbot:Init(Settings, State, Utilities)
end
ESP:Init(Settings, State, Utilities)
FOV:Init(Settings, State, Utilities)
Chams:Init(Settings, State, Utilities)
Crosshair:Init(Settings, State, Utilities)
PlayerMod:Init(Settings, State, Utilities)
Misc:Init(Settings, State, Utilities)
UI:Init(
    Settings,
    State,
    Library,
    hasMouseMoveRel,
    Aimbot,
    ESP,
    FOV,
    Chams,
    Crosshair,
    PlayerMod,
    Misc,
    Utilities
)

-- // Cleanup \\
Library:OnUnload(function()
    if Aimbot then
        Aimbot:Cleanup()
    end
    ESP:Cleanup()
    FOV:Cleanup()
    Chams:Cleanup()
    Crosshair:Cleanup()
    PlayerMod:Cleanup()
    Misc:Cleanup()
    UI:Cleanup()
    _G.ScriptIsRunning = false
end)

-- // Notification \\
game:GetService('StarterGui'):SetCore('SendNotification', {
    Title = 'Join the Server!',
    Text = 'dsc.gg/kaotiksoftworks',
    Duration = 6,
})
