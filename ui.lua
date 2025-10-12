local UI = {}

function UI:Init(Settings, State, Library, hasMouseMoveRel, Aimbot, ESP, FOV, Chams, Crosshair, PlayerMod, Misc, Utilities)
    self.Settings = Settings
    self.State = State
    self.Library = Library
    self.hasMouseMoveRel = hasMouseMoveRel
    self.Aimbot = Aimbot
    self.ESP = ESP
    self.FOV = FOV
    self.Chams = Chams
    self.Crosshair = Crosshair
    self.PlayerMod = PlayerMod
    self.Misc = Misc
    self.Utilities = Utilities
    self:setupUI()
end

function UI:setupUI()
    local Window = Library:CreateWindow({
    Title = 'Nullwave',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Player = Window:AddTab('Player'),
    Misc = Window:AddTab('Misc'),
    UISettings = Window:AddTab('UI Settings'),
}

-- Crosshair UI
local CrosshairGroup = Tabs.Misc:AddLeftGroupbox('Crosshair')
CrosshairGroup:AddToggle('CrosshairEnabled', {
    Text = 'Enabled',
    Default = Settings.Crosshair.Enabled,
    Callback = function(value)
        Settings.Crosshair.Enabled = value
        toggleCrosshair(value)
    end,
})
Toggles.CrosshairEnabled:OnChanged(function()
    Settings.Crosshair.Enabled = Toggles.CrosshairEnabled.Value
    toggleCrosshair(Toggles.CrosshairEnabled.Value)
end)

CrosshairGroup:AddDropdown('CrosshairStyle', {
    Text = 'Style',
    Values = { 'Default', 'Plus' },
    Default = 1,
    Callback = function(value)
        Settings.Crosshair.TStyle = value
    end,
})
Options.CrosshairStyle:OnChanged(function()
    Settings.Crosshair.TStyle = Options.CrosshairStyle.Value
end)

CrosshairGroup:AddToggle('CrosshairDot', {
    Text = 'Center Dot',
    Default = Settings.Crosshair.Dot,
    Callback = function(value)
        Settings.Crosshair.Dot = value
    end,
})
Toggles.CrosshairDot:OnChanged(function()
    Settings.Crosshair.Dot = Toggles.CrosshairDot.Value
end)

CrosshairGroup:AddSlider('CrosshairSize', {
    Text = 'Size',
    Default = Settings.Crosshair.Size,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        Settings.Crosshair.Size = value
    end,
})
Options.CrosshairSize:OnChanged(function()
    Settings.Crosshair.Size = Options.CrosshairSize.Value
end)

CrosshairGroup:AddSlider('CrosshairThickness', {
    Text = 'Thickness',
    Default = Settings.Crosshair.Thickness,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(value)
        Settings.Crosshair.Thickness = value
    end,
})
Options.CrosshairThickness:OnChanged(function()
    Settings.Crosshair.Thickness = Options.CrosshairThickness.Value
end)

CrosshairGroup:AddSlider('CrosshairGap', {
    Text = 'Gap',
    Default = Settings.Crosshair.Gap,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(value)
        Settings.Crosshair.Gap = value
    end,
})
Options.CrosshairGap:OnChanged(function()
    Settings.Crosshair.Gap = Options.CrosshairGap.Value
end)

CrosshairGroup:AddLabel('Color'):AddColorPicker('CrosshairColor', {
    Default = Settings.Crosshair.Color,
    Transparency = 0,
    Callback = function(value)
        Settings.Crosshair.Color = value
    end,
})
Options.CrosshairColor:OnChanged(function()
    Settings.Crosshair.Color = Options.CrosshairColor.Value
end)

CrosshairGroup:AddSlider('CrosshairTransparency', {
    Text = 'Transparency',
    Default = Settings.Crosshair.Transparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Settings.Crosshair.Transparency = value
    end,
})
Options.CrosshairTransparency:OnChanged(function()
    Settings.Crosshair.Transparency = Options.CrosshairTransparency.Value
end)

-- Aimbot UI
if hasMouseMoveRel then
    local AimbotGroup = Tabs.Main:AddLeftGroupbox('Aimbot')
    AimbotGroup:AddToggle('AimbotEnabled', {
        Text = 'Enabled',
        Default = Settings.Aimbot.Enabled,
        Callback = function(value)
            Settings.Aimbot.Enabled = value
            if value then
                startMousePreload()
                State.InputBeganConnection = UserInputService.InputBegan:Connect(
                    function(i)
                        if
                            i.UserInputType == Enum.UserInputType.MouseButton2
                        then
                            State.IsRightClickHeld = true
                            State.TargetPart = getClosestPlayer()
                        end
                    end
                )
                State.InputEndedConnection = UserInputService.InputEnded:Connect(
                    function(i)
                        if
                            i.UserInputType == Enum.UserInputType.MouseButton2
                        then
                            State.IsRightClickHeld = false
                            State.TargetPart = nil
                        end
                    end
                )
                State.RenderSteppedConnection = RunService.RenderStepped:Connect(
                    function()
                        if State.IsRightClickHeld and State.TargetPart then
                            if Settings.Aimbot.WallCheck then
                                if isVisible(State.TargetPart, true) then
                                    aimAt()
                                end
                            else
                                aimAt()
                            end
                        end
                    end
                )
            else
                stopMousePreload()
                if State.InputBeganConnection then
                    State.InputBeganConnection:Disconnect()
                end
                if State.InputEndedConnection then
                    State.InputEndedConnection:Disconnect()
                end
                if State.RenderSteppedConnection then
                    State.RenderSteppedConnection:Disconnect()
                end
            end
        end,
    })
    Toggles.AimbotEnabled:OnChanged(function()
        Settings.Aimbot.Enabled = Toggles.AimbotEnabled.Value
    end)

    AimbotGroup:AddDropdown('AimbotHitPart', {
        Text = 'Hit Part',
        Values = { 'Head', 'Torso' },
        Default = 1,
        Callback = function(value)
            Settings.Aimbot.HitPart = value
        end,
    })
    Options.AimbotHitPart:OnChanged(function()
        Settings.Aimbot.HitPart = Options.AimbotHitPart.Value
    end)

    AimbotGroup:AddToggle('AimbotWallCheck', {
        Text = 'Wall Check',
        Default = Settings.Aimbot.WallCheck,
        Callback = function(value)
            Settings.Aimbot.WallCheck = value
        end,
    })
    Toggles.AimbotWallCheck:OnChanged(function()
        Settings.Aimbot.WallCheck = Toggles.AimbotWallCheck.Value
    end)

    AimbotGroup:AddToggle('AimbotAutoTargetSwitch', {
        Text = 'Auto Target Switch',
        Default = Settings.Aimbot.AutoTargetSwitch,
        Callback = function(value)
            Settings.Aimbot.AutoTargetSwitch = value
        end,
    })
    Toggles.AimbotAutoTargetSwitch:OnChanged(function()
        Settings.Aimbot.AutoTargetSwitch = Toggles.AimbotAutoTargetSwitch.Value
    end)

    AimbotGroup:AddToggle('AimbotMaxDistanceEnabled', {
        Text = 'Use Max Distance',
        Default = Settings.Aimbot.MaxDistance.Enabled,
        Callback = function(value)
            Settings.Aimbot.MaxDistance.Enabled = value
        end,
    })
    Toggles.AimbotMaxDistanceEnabled:OnChanged(function()
        Settings.Aimbot.MaxDistance.Enabled =
            Toggles.AimbotMaxDistanceEnabled.Value
    end)

    AimbotGroup:AddSlider('AimbotMaxDistance', {
        Text = 'Max Distance',
        Default = Settings.Aimbot.MaxDistance.Value,
        Min = 10,
        Max = 1000,
        Rounding = 0,
        Callback = function(value)
            Settings.Aimbot.MaxDistance.Value = value
        end,
    })
    Options.AimbotMaxDistance:OnChanged(function()
        Settings.Aimbot.MaxDistance.Value = Options.AimbotMaxDistance.Value
    end)

    AimbotGroup:AddSlider('AimbotEasingStrength', {
        Text = 'Strength',
        Default = Settings.Aimbot.Easing.Strength,
        Min = 0.1,
        Max = 1.5,
        Rounding = 1,
        Callback = function(value)
            Settings.Aimbot.Easing.Strength = value
            updateSensitivity(value)
        end,
    })
    Options.AimbotEasingStrength:OnChanged(function()
        Settings.Aimbot.Easing.Strength = Options.AimbotEasingStrength.Value
        updateSensitivity(Options.AimbotEasingStrength.Value)
    end)
end

-- ESP UI
local ESPGroup = Tabs.Visuals:AddLeftGroupbox('ESP')
ESPGroup:AddToggle('ESPEnabled', {
    Text = 'Enabled',
    Default = Settings.ESP.Enabled,
    Callback = function(value)
        Settings.ESP.Enabled = value
        if value then
            initializeESP()
            State.PlayerCacheUpdate =
                RunService.Heartbeat:Connect(updatePlayerCache)
            local last = tick()
            local interval = 1 / 240
            State.ESPLoop = RunService.Heartbeat:Connect(function()
                local now = tick()
                if now - last >= interval then
                    renderESP()
                    last = now
                end
            end)
        else
            if State.PlayerCacheUpdate then
                State.PlayerCacheUpdate:Disconnect()
            end
            if State.ESPLoop then
                State.ESPLoop:Disconnect()
            end
            for p in pairs(State.Storage.ESPCache) do
                uncacheObject(p)
            end
            State.PlayersToDraw = {}
            State.CachedProperties = {}
        end
    end,
})
Toggles.ESPEnabled:OnChanged(function()
    Settings.ESP.Enabled = Toggles.ESPEnabled.Value
end)

local function updateESPFeature(f, s)
    Settings.ESP.Features[f].Enabled = s
    for _, c in pairs(State.Storage.ESPCache) do
        if f == 'Box' then
            c.BoxSquare.Visible = s
            c.BoxOutline.Visible = s
        elseif f == 'Tracer' then
            c.TracerLine.Visible = s
        elseif f == 'HeadDot' then
            c.HeadDot.Visible = s
        elseif f == 'DistanceText' then
            c.DistanceLabel.Visible = s
        elseif f == 'Name' then
            c.NameLabel.Visible = s
        end
    end
end

ESPGroup:AddToggle('ESPBox', {
    Text = 'Box',
    Default = Settings.ESP.Features.Box.Enabled,
    Callback = function(value)
        updateESPFeature('Box', value)
    end,
})
Toggles.ESPBox:OnChanged(function()
    updateESPFeature('Box', Toggles.ESPBox.Value)
end)

ESPGroup:AddToggle('ESPTracer', {
    Text = 'Tracer',
    Default = Settings.ESP.Features.Tracer.Enabled,
    Callback = function(value)
        updateESPFeature('Tracer', value)
    end,
})
Toggles.ESPTracer:OnChanged(function()
    updateESPFeature('Tracer', Toggles.ESPTracer.Value)
end)

ESPGroup:AddToggle('ESPHeadDot', {
    Text = 'Head Dot',
    Default = Settings.ESP.Features.HeadDot.Enabled,
    Callback = function(value)
        updateESPFeature('HeadDot', value)
    end,
})
Toggles.ESPHeadDot:OnChanged(function()
    updateESPFeature('HeadDot', Toggles.ESPHeadDot.Value)
end)

ESPGroup:AddToggle('ESPDistance', {
    Text = 'Distance',
    Default = Settings.ESP.Features.DistanceText.Enabled,
    Callback = function(value)
        updateESPFeature('DistanceText', value)
    end,
})
Toggles.ESPDistance:OnChanged(function()
    updateESPFeature('DistanceText', Toggles.ESPDistance.Value)
end)

ESPGroup:AddToggle('ESPName', {
    Text = 'Name',
    Default = Settings.ESP.Features.Name.Enabled,
    Callback = function(value)
        updateESPFeature('Name', value)
    end,
})
Toggles.ESPName:OnChanged(function()
    updateESPFeature('Name', Toggles.ESPName.Value)
end)

ESPGroup:AddToggle('ESPVisibilityCheck', {
    Text = 'Wall Check',
    Default = Settings.ESP.VisibilityCheck,
    Callback = function(value)
        Settings.ESP.VisibilityCheck = value
    end,
})
Toggles.ESPVisibilityCheck:OnChanged(function()
    Settings.ESP.VisibilityCheck = Toggles.ESPVisibilityCheck.Value
end)

-- ESP Colors
local ESPCustomization = Tabs.Visuals:AddRightGroupbox('ESP Colors')
local function updateESPColor(f, c)
    Settings.ESP.Features[f].Color = c
    for _, cache in pairs(State.Storage.ESPCache) do
        if f == 'Box' then
            cache.BoxSquare.Color = c
        elseif f == 'Tracer' then
            cache.TracerLine.Color = c
        elseif f == 'HeadDot' then
            cache.HeadDot.Color = c
        elseif f == 'DistanceText' then
            cache.DistanceLabel.Color = c
        elseif f == 'Name' then
            cache.NameLabel.Color = c
        end
    end
end

ESPCustomization:AddLabel('Box Color'):AddColorPicker('ESPBoxColor', {
    Default = Settings.ESP.Features.Box.Color,
    Callback = function(value)
        updateESPColor('Box', value)
    end,
})
Options.ESPBoxColor:OnChanged(function()
    updateESPColor('Box', Options.ESPBoxColor.Value)
end)

ESPCustomization:AddLabel('Tracer Color'):AddColorPicker('ESPTracerColor', {
    Default = Settings.ESP.Features.Tracer.Color,
    Callback = function(value)
        updateESPColor('Tracer', value)
    end,
})
Options.ESPTracerColor:OnChanged(function()
    updateESPColor('Tracer', Options.ESPTracerColor.Value)
end)

ESPCustomization:AddLabel('Distance Color'):AddColorPicker('ESPDistanceColor', {
    Default = Settings.ESP.Features.DistanceText.Color,
    Callback = function(value)
        updateESPColor('DistanceText', value)
    end,
})
Options.ESPDistanceColor:OnChanged(function()
    updateESPColor('DistanceText', Options.ESPDistanceColor.Value)
end)

ESPCustomization:AddLabel('Head Dot Color'):AddColorPicker('ESPHeadDotColor', {
    Default = Settings.ESP.Features.HeadDot.Color,
    Callback = function(value)
        updateESPColor('HeadDot', value)
    end,
})
Options.ESPHeadDotColor:OnChanged(function()
    updateESPColor('HeadDot', Options.ESPHeadDotColor.Value)
end)

ESPCustomization:AddLabel('Name Color'):AddColorPicker('ESPNameColor', {
    Default = Settings.ESP.Features.Name.Color,
    Callback = function(value)
        updateESPColor('Name', value)
    end,
})
Options.ESPNameColor:OnChanged(function()
    updateESPColor('Name', Options.ESPNameColor.Value)
end)

-- Distance Settings
local DistanceCustomization = Tabs.Visuals:AddRightGroupbox('Distance Settings')
DistanceCustomization:AddToggle('ESPMaxDistanceEnabled', {
    Text = 'Use Max Distance',
    Default = Settings.ESP.MaxDistance.Enabled,
    Callback = function(value)
        Settings.ESP.MaxDistance.Enabled = value
        refreshPlayerCache()
    end,
})
Toggles.ESPMaxDistanceEnabled:OnChanged(function()
    Settings.ESP.MaxDistance.Enabled = Toggles.ESPMaxDistanceEnabled.Value
    refreshPlayerCache()
end)

DistanceCustomization:AddSlider('ESPMaxDistance', {
    Text = 'Max Distance',
    Default = Settings.ESP.MaxDistance.Value,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        Settings.ESP.MaxDistance.Value = value
        refreshPlayerCache()
    end,
})
Options.ESPMaxDistance:OnChanged(function()
    Settings.ESP.MaxDistance.Value = Options.ESPMaxDistance.Value
    refreshPlayerCache()
end)

-- FOV UI
local FOVGroup = Tabs.Main:AddRightGroupbox('FOV')
FOVGroup:AddToggle('FOVEnabled', {
    Text = 'Show FOV Circle',
    Default = Settings.FOV.Enabled,
    Callback = function(value)
        Settings.FOV.Enabled = value
        Settings.FOV.Circle.Visible = value
        Settings.FOV.OutlineCircle.Visible = value
    end,
})
Toggles.FOVEnabled:OnChanged(function()
    Settings.FOV.Enabled = Toggles.FOVEnabled.Value
    Settings.FOV.Circle.Visible = Toggles.FOVEnabled.Value
    Settings.FOV.OutlineCircle.Visible = Toggles.FOVEnabled.Value
end)

FOVGroup:AddToggle('FOVFollowGun', {
    Text = 'Follow Gun',
    Default = Settings.FOV.FollowGun,
    Callback = function(value)
        Settings.FOV.FollowGun = value
    end,
})
Toggles.FOVFollowGun:OnChanged(function()
    Settings.FOV.FollowGun = Toggles.FOVFollowGun.Value
end)

FOVGroup:AddToggle('FOVFilled', {
    Text = 'Fill FOV Circle',
    Default = Settings.FOV.Filled,
    Callback = function(value)
        Settings.FOV.Filled = value
        Settings.FOV.Circle.Filled = value
        Settings.FOV.Circle.Color = value and Settings.FOV.FillColor
            or Settings.FOV.OutlineColor
        Settings.FOV.Circle.Transparency = value
                and Settings.FOV.FillTransparency
            or Settings.FOV.OutlineTransparency
        Settings.FOV.Circle.Thickness = value and 0 or 1
    end,
})
Toggles.FOVFilled:OnChanged(function()
    Settings.FOV.Filled = Toggles.FOVFilled.Value
    Settings.FOV.Circle.Filled = Toggles.FOVFilled.Value
    Settings.FOV.Circle.Color = Toggles.FOVFilled.Value
            and Settings.FOV.FillColor
        or Settings.FOV.OutlineColor
    Settings.FOV.Circle.Transparency = Toggles.FOVFilled.Value
            and Settings.FOV.FillTransparency
        or Settings.FOV.OutlineTransparency
    Settings.FOV.Circle.Thickness = Toggles.FOVFilled.Value and 0 or 1
end)

FOVGroup:AddLabel('Inline Color'):AddColorPicker('FOVFillColor', {
    Default = Settings.FOV.FillColor,
    Transparency = Settings.FOV.FillTransparency,
    Callback = function(value)
        Settings.FOV.FillColor = value
        if Settings.FOV.Filled then
            Settings.FOV.Circle.Color = value
        end
    end,
})
Options.FOVFillColor:OnChanged(function()
    Settings.FOV.FillColor = Options.FOVFillColor.Value
    if Settings.FOV.Filled then
        Settings.FOV.Circle.Color = Options.FOVFillColor.Value
    end
end)

FOVGroup:AddSlider('FOVFillTransparency', {
    Text = 'Inline Transparency',
    Default = Settings.FOV.FillTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Settings.FOV.FillTransparency = value
        if Settings.FOV.Filled then
            Settings.FOV.Circle.Transparency = value
        end
    end,
})
Options.FOVFillTransparency:OnChanged(function()
    Settings.FOV.FillTransparency = Options.FOVFillTransparency.Value
    if Settings.FOV.Filled then
        Settings.FOV.Circle.Transparency = Options.FOVFillTransparency.Value
    end
end)

FOVGroup:AddLabel('Outline Color'):AddColorPicker('FOVOutlineColor', {
    Default = Settings.FOV.OutlineColor,
    Transparency = Settings.FOV.OutlineTransparency,
    Callback = function(value)
        Settings.FOV.OutlineColor = value
        Settings.FOV.OutlineCircle.Color = value
        if not Settings.FOV.Filled then
            Settings.FOV.Circle.Color = value
        end
    end,
})
Options.FOVOutlineColor:OnChanged(function()
    Settings.FOV.OutlineColor = Options.FOVOutlineColor.Value
    Settings.FOV.OutlineCircle.Color = Options.FOVOutlineColor.Value
    if not Settings.FOV.Filled then
        Settings.FOV.Circle.Color = Options.FOVOutlineColor.Value
    end
end)

FOVGroup:AddSlider('FOVOutlineTransparency', {
    Text = 'Outline Transparency',
    Default = Settings.FOV.OutlineTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Settings.FOV.OutlineTransparency = value
        Settings.FOV.OutlineCircle.Transparency = value
        if not Settings.FOV.Filled then
            Settings.FOV.Circle.Transparency = value
        end
    end,
})
Options.FOVOutlineTransparency:OnChanged(function()
    Settings.FOV.OutlineTransparency = Options.FOVOutlineTransparency.Value
    Settings.FOV.OutlineCircle.Transparency =
        Options.FOVOutlineTransparency.Value
    if not Settings.FOV.Filled then
        Settings.FOV.Circle.Transparency = Options.FOVOutlineTransparency.Value
    end
end)

FOVGroup:AddSlider('FOVRadius', {
    Text = 'FOV Radius',
    Default = Settings.FOV.Radius,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        Settings.FOV.Radius = value
        Settings.FOV.Circle.Radius = value
        Settings.FOV.OutlineCircle.Radius = value
    end,
})
Options.FOVRadius:OnChanged(function()
    Settings.FOV.Radius = Options.FOVRadius.Value
    Settings.FOV.Circle.Radius = Options.FOVRadius.Value
    Settings.FOV.OutlineCircle.Radius = Options.FOVRadius.Value
end)

-- Chams UI
local ChamsGroup = Tabs.Visuals:AddLeftGroupbox('Chams')
ChamsGroup:AddToggle('ChamsEnabled', {
    Text = 'Enabled',
    Default = Settings.Chams.Enabled,
    Callback = function(value)
        Settings.Chams.Enabled = value
        if value then
            State.ChamsUpdateConnection =
                RunService.RenderStepped:Connect(updateChams)
        else
            if State.ChamsUpdateConnection then
                State.ChamsUpdateConnection:Disconnect()
                State.ChamsUpdateConnection = nil
            end
            for p in pairs(State.Highlights) do
                removeHighlight(p)
            end
        end
    end,
})
Toggles.ChamsEnabled:OnChanged(function()
    Settings.Chams.Enabled = Toggles.ChamsEnabled.Value
end)

ChamsGroup:AddLabel('Fill Color'):AddColorPicker('ChamsFillColor', {
    Default = Settings.Chams.Fill.Color,
    Transparency = Settings.Chams.Fill.Transparency,
    Callback = function(value)
        Settings.Chams.Fill.Color = value
        for _, h in pairs(State.Highlights) do
            h.FillColor = value
        end
    end,
})
Options.ChamsFillColor:OnChanged(function()
    Settings.Chams.Fill.Color = Options.ChamsFillColor.Value
    for _, h in pairs(State.Highlights) do
        h.FillColor = Options.ChamsFillColor.Value
    end
end)

ChamsGroup:AddLabel('Outline Color'):AddColorPicker('ChamsOutlineColor', {
    Default = Settings.Chams.Outline.Color,
    Transparency = Settings.Chams.Outline.Transparency,
    Callback = function(value)
        Settings.Chams.Outline.Color = value
        for _, h in pairs(State.Highlights) do
            h.OutlineColor = value
        end
    end,
})
Options.ChamsOutlineColor:OnChanged(function()
    Settings.Chams.Outline.Color = Options.ChamsOutlineColor.Value
    for _, h in pairs(State.Highlights) do
        h.OutlineColor = Options.ChamsOutlineColor.Value
    end
end)

ChamsGroup:AddSlider('ChamsFillTransparency', {
    Text = 'Fill Transparency',
    Default = Settings.Chams.Fill.Transparency,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        Settings.Chams.Fill.Transparency = value
        for _, h in pairs(State.Highlights) do
            h.FillTransparency = value
        end
    end,
})
Options.ChamsFillTransparency:OnChanged(function()
    Settings.Chams.Fill.Transparency = Options.ChamsFillTransparency.Value
    for _, h in pairs(State.Highlights) do
        h.FillTransparency = Options.ChamsFillTransparency.Value
    end
end)

ChamsGroup:AddSlider('ChamsOutlineTransparency', {
    Text = 'Outline Transparency',
    Default = Settings.Chams.Outline.Transparency,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        Settings.Chams.Outline.Transparency = value
        for _, h in pairs(State.Highlights) do
            h.OutlineTransparency = value
        end
    end,
})
Options.ChamsOutlineTransparency:OnChanged(function()
    Settings.Chams.Outline.Transparency = Options.ChamsOutlineTransparency.Value
    for _, h in pairs(State.Highlights) do
        h.OutlineTransparency = Options.ChamsOutlineTransparency.Value
    end
end)

-- Player UI
local PlayerGroup = Tabs.Player:AddLeftGroupbox('Player')
PlayerGroup:AddToggle('BhopEnabled', {
    Text = 'Bunny Hop',
    Default = Settings.Player.Bhop.Enabled,
    Callback = function(value)
        Settings.Player.Bhop.Enabled = value
    end,
})
Toggles.BhopEnabled:OnChanged(function()
    Settings.Player.Bhop.Enabled = Toggles.BhopEnabled.Value
end)

-- Misc UI
local Optimizations = Tabs.Misc:AddLeftGroupbox('Miscellaneous')
Optimizations:AddToggle('MiscTextures', {
    Text = 'Toggle Textures',
    Default = Settings.Misc.Textures,
    Callback = function(value)
        Settings.Misc.Textures = value
        if value then
            optimizeMap()
        else
            revertMap()
        end
    end,
})
Toggles.MiscTextures:OnChanged(function()
    Settings.Misc.Textures = Toggles.MiscTextures.Value
    if Toggles.MiscTextures.Value then
        optimizeMap()
    else
        revertMap()
    end
end)

local Safety = Tabs.Misc:AddRightGroupbox('Safety')
Safety:AddToggle('VotekickRejoiner', {
    Text = 'Rejoin on Votekick',
    Default = Settings.Misc.VotekickRejoiner,
    Callback = function(value)
        Settings.Misc.VotekickRejoiner = value
        if value then
            initializeVotekickRejoiner()
        end
    end,
})
Toggles.VotekickRejoiner:OnChanged(function()
    Settings.Misc.VotekickRejoiner = Toggles.VotekickRejoiner.Value
    if Toggles.VotekickRejoiner.Value then
        initializeVotekickRejoiner()
    end
end)

-- Non-UI Setup
Camera:GetPropertyChangedSignal('ViewportSize'):Connect(updateFOVCirclePosition)
RunService.Heartbeat:Connect(updateFOVCirclePosition)

local function handleBhop()
    if Settings.Player.Bhop.Enabled then
        local t = tick()
        if (t - lastJumpTime) < jumpCooldown then
            local hum = getCharacter():FindFirstChildOfClass('Humanoid')
            if hum then
                hum.Jump = true
            end
        end
        lastJumpTime = t
    end
end

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then
        return
    end
    if i.KeyCode == Enum.KeyCode.Space then
        handleBhop()
    end
end)

-- UI Settings
local MenuGroup = Tabs.UISettings:AddLeftGroupbox('Menu')
MenuGroup:AddButton({
    Text = 'Unload',
    Func = function()
        Library:Unload()
    end,
})
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'RightShift',
    NoUI = true,
    Text = 'Menu keybind',
})

Library.ToggleKeybind = Options.MenuKeybind
end

function UI:Cleanup()
    -- UI cleanup is handled by Library:OnUnload
end

return UI
