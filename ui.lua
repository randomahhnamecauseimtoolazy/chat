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
    local Window = self.Library:CreateWindow({
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
        Default = self.Settings.Crosshair.Enabled,
        Callback = function(value)
            self.Settings.Crosshair.Enabled = value
            self.Crosshair:toggleCrosshair(value)
        end,
    })

    CrosshairGroup:AddDropdown('CrosshairStyle', {
        Text = 'Style',
        Values = { 'Default', 'Plus' },
        Default = self.Settings.Crosshair.TStyle == "Default" and 1 or 2,
        Callback = function(value)
            self.Settings.Crosshair.TStyle = value
        end,
    })

    CrosshairGroup:AddToggle('CrosshairDot', {
        Text = 'Center Dot',
        Default = self.Settings.Crosshair.Dot,
        Callback = function(value)
            self.Settings.Crosshair.Dot = value
        end,
    })

    CrosshairGroup:AddSlider('CrosshairSize', {
        Text = 'Size',
        Default = self.Settings.Crosshair.Size,
        Min = 1,
        Max = 30,
        Rounding = 0,
        Callback = function(value)
            self.Settings.Crosshair.Size = value
        end,
    })

    CrosshairGroup:AddSlider('CrosshairThickness', {
        Text = 'Thickness',
        Default = self.Settings.Crosshair.Thickness,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(value)
            self.Settings.Crosshair.Thickness = value
        end,
    })

    CrosshairGroup:AddSlider('CrosshairGap', {
        Text = 'Gap',
        Default = self.Settings.Crosshair.Gap,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Callback = function(value)
            self.Settings.Crosshair.Gap = value
        end,
    })

    CrosshairGroup:AddLabel('Color'):AddColorPicker('CrosshairColor', {
        Default = self.Settings.Crosshair.Color,
        Transparency = 0,
        Callback = function(value)
            self.Settings.Crosshair.Color = value
        end,
    })

    CrosshairGroup:AddSlider('CrosshairTransparency', {
        Text = 'Transparency',
        Default = self.Settings.Crosshair.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            self.Settings.Crosshair.Transparency = value
        end,
    })

    -- Aimbot UI
    if self.hasMouseMoveRel then
        local AimbotGroup = Tabs.Main:AddLeftGroupbox('Aimbot')
        AimbotGroup:AddToggle('AimbotEnabled', {
            Text = 'Enabled',
            Default = self.Settings.Aimbot.Enabled,
            Callback = function(value)
                self.Settings.Aimbot.Enabled = value
                if value then
                    self.Aimbot:startMousePreload()
                    self.State.InputBeganConnection = game:GetService("UserInputService").InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton2 then
                            self.State.IsRightClickHeld = true
                            self.State.TargetPart = self.Aimbot:getClosestPlayer()
                        end
                    end)
                    self.State.InputEndedConnection = game:GetService("UserInputService").InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton2 then
                            self.State.IsRightClickHeld = false
                            self.State.TargetPart = nil
                        end
                    end)
                    self.State.RenderSteppedConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        if self.State.IsRightClickHeld and self.State.TargetPart then
                            if self.Settings.Aimbot.WallCheck then
                                if self.Utilities:isVisible(self.State.TargetPart, true) then
                                    self.Aimbot:aimAt()
                                end
                            else
                                self.Aimbot:aimAt()
                            end
                        end
                    end)
                else
                    self.Aimbot:stopMousePreload()
                    if self.State.InputBeganConnection then
                        self.State.InputBeganConnection:Disconnect()
                    end
                    if self.State.InputEndedConnection then
                        self.State.InputEndedConnection:Disconnect()
                    end
                    if self.State.RenderSteppedConnection then
                        self.State.RenderSteppedConnection:Disconnect()
                    end
                end
            end,
        })

        AimbotGroup:AddDropdown('AimbotHitPart', {
            Text = 'Hit Part',
            Values = { 'Head', 'Torso' },
            Default = self.Settings.Aimbot.HitPart == "Head" and 1 or 2,
            Callback = function(value)
                self.Settings.Aimbot.HitPart = value
            end,
        })

        AimbotGroup:AddToggle('AimbotWallCheck', {
            Text = 'Wall Check',
            Default = self.Settings.Aimbot.WallCheck,
            Callback = function(value)
                self.Settings.Aimbot.WallCheck = value
            end,
        })

        AimbotGroup:AddToggle('AimbotAutoTargetSwitch', {
            Text = 'Auto Target Switch',
            Default = self.Settings.Aimbot.AutoTargetSwitch,
            Callback = function(value)
                self.Settings.Aimbot.AutoTargetSwitch = value
            end,
        })

        AimbotGroup:AddToggle('AimbotMaxDistanceEnabled', {
            Text = 'Use Max Distance',
            Default = self.Settings.Aimbot.MaxDistance.Enabled,
            Callback = function(value)
                self.Settings.Aimbot.MaxDistance.Enabled = value
            end,
        })

        AimbotGroup:AddSlider('AimbotMaxDistance', {
            Text = 'Max Distance',
            Default = self.Settings.Aimbot.MaxDistance.Value,
            Min = 10,
            Max = 1000,
            Rounding = 0,
            Callback = function(value)
                self.Settings.Aimbot.MaxDistance.Value = value
            end,
        })

        AimbotGroup:AddSlider('AimbotEasingStrength', {
            Text = 'Strength',
            Default = self.Settings.Aimbot.Easing.Strength,
            Min = 0.1,
            Max = 1.5,
            Rounding = 1,
            Callback = function(value)
                self.Settings.Aimbot.Easing.Strength = value
                self.Aimbot:updateSensitivity(value)
            end,
        })
    end

    -- ESP UI
    local ESPGroup = Tabs.Visuals:AddLeftGroupbox('ESP')
    ESPGroup:AddToggle('ESPEnabled', {
        Text = 'Enabled',
        Default = self.Settings.ESP.Enabled,
        Callback = function(value)
            self.Settings.ESP.Enabled = value
            if value then
                self.ESP:initializeESP()
                self.State.PlayerCacheUpdate = game:GetService("RunService").Heartbeat:Connect(function() self.ESP:updatePlayerCache() end)
                local last = tick()
                local interval = 1 / 240
                self.State.ESPLoop = game:GetService("RunService").Heartbeat:Connect(function()
                    local now = tick()
                    if now - last >= interval then
                        self.ESP:renderESP()
                        last = now
                    end
                end)
            else
                if self.State.PlayerCacheUpdate then
                    self.State.PlayerCacheUpdate:Disconnect()
                end
                if self.State.ESPLoop then
                    self.State.ESPLoop:Disconnect()
                end
                for p in pairs(self.State.Storage.ESPCache) do
                    self.Utilities:uncacheObject(p)
                end
                self.State.PlayersToDraw = {}
                self.State.CachedProperties = {}
            end
        end,
    })

    local function updateESPFeature(f, s)
        self.Settings.ESP.Features[f].Enabled = s
        for _, c in pairs(self.State.Storage.ESPCache) do
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
        Default = self.Settings.ESP.Features.Box.Enabled,
        Callback = function(value)
            updateESPFeature('Box', value)
        end,
    })

    ESPGroup:AddToggle('ESPTracer', {
        Text = 'Tracer',
        Default = self.Settings.ESP.Features.Tracer.Enabled,
        Callback = function(value)
            updateESPFeature('Tracer', value)
        end,
    })

    ESPGroup:AddToggle('ESPHeadDot', {
        Text = 'Head Dot',
        Default = self.Settings.ESP.Features.HeadDot.Enabled,
        Callback = function(value)
            updateESPFeature('HeadDot', value)
        end,
    })

    ESPGroup:AddToggle('ESPDistance', {
        Text = 'Distance',
        Default = self.Settings.ESP.Features.DistanceText.Enabled,
        Callback = function(value)
            updateESPFeature('DistanceText', value)
        end,
    })

    ESPGroup:AddToggle('ESPName', {
        Text = 'Name',
        Default = self.Settings.ESP.Features.Name.Enabled,
        Callback = function(value)
            updateESPFeature('Name', value)
        end,
    })

    ESPGroup:AddToggle('ESPVisibilityCheck', {
        Text = 'Wall Check',
        Default = self.Settings.ESP.VisibilityCheck,
        Callback = function(value)
            self.Settings.ESP.VisibilityCheck = value
        end,
    })

    -- ESP Colors
    local ESPCustomization = Tabs.Visuals:AddRightGroupbox('ESP Colors')
    local function updateESPColor(f, c)
        self.Settings.ESP.Features[f].Color = c
        for _, cache in pairs(self.State.Storage.ESPCache) do
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
        Default = self.Settings.ESP.Features.Box.Color,
        Callback = function(value)
            updateESPColor('Box', value)
        end,
    })

    ESPCustomization:AddLabel('Tracer Color'):AddColorPicker('ESPTracerColor', {
        Default = self.Settings.ESP.Features.Tracer.Color,
        Callback = function(value)
            updateESPColor('Tracer', value)
        end,
    })

    ESPCustomization:AddLabel('Distance Color'):AddColorPicker('ESPDistanceColor', {
        Default = self.Settings.ESP.Features.DistanceText.Color,
        Callback = function(value)
            updateESPColor('DistanceText', value)
        end,
    })

    ESPCustomization:AddLabel('Head Dot Color'):AddColorPicker('ESPHeadDotColor', {
        Default = self.Settings.ESP.Features.HeadDot.Color,
        Callback = function(value)
            updateESPColor('HeadDot', value)
        end,
    })

    ESPCustomization:AddLabel('Name Color'):AddColorPicker('ESPNameColor', {
        Default = self.Settings.ESP.Features.Name.Color,
        Callback = function(value)
            updateESPColor('Name', value)
        end,
    })

    -- Distance Settings
    local DistanceCustomization = Tabs.Visuals:AddRightGroupbox('Distance Settings')
    DistanceCustomization:AddToggle('ESPMaxDistanceEnabled', {
        Text = 'Use Max Distance',
        Default = self.Settings.ESP.MaxDistance.Enabled,
        Callback = function(value)
            self.Settings.ESP.MaxDistance.Enabled = value
            if self.Settings.ESP.Enabled then self.ESP:updatePlayerCache() end
        end,
    })

    DistanceCustomization:AddSlider('ESPMaxDistance', {
        Text = 'Max Distance',
        Default = self.Settings.ESP.MaxDistance.Value,
        Min = 50,
        Max = 1000,
        Rounding = 0,
        Callback = function(value)
            self.Settings.ESP.MaxDistance.Value = value
            if self.Settings.ESP.Enabled then self.ESP:updatePlayerCache() end
        end,
    })

    -- FOV UI
    local FOVGroup = Tabs.Main:AddRightGroupbox('FOV')
    FOVGroup:AddToggle('FOVEnabled', {
        Text = 'Show FOV Circle',
        Default = self.Settings.FOV.Enabled,
        Callback = function(value)
            self.Settings.FOV.Enabled = value
            self.Settings.FOV.Circle.Visible = value
            self.Settings.FOV.OutlineCircle.Visible = value
        end,
    })

    FOVGroup:AddToggle('FOVFollowGun', {
        Text = 'Follow Gun',
        Default = self.Settings.FOV.FollowGun,
        Callback = function(value)
            self.Settings.FOV.FollowGun = value
        end,
    })

    FOVGroup:AddToggle('FOVFilled', {
        Text = 'Fill FOV Circle',
        Default = self.Settings.FOV.Filled,
        Callback = function(value)
            self.Settings.FOV.Filled = value
            self.Settings.FOV.Circle.Filled = value
            self.Settings.FOV.Circle.Color = value and self.Settings.FOV.FillColor or self.Settings.FOV.OutlineColor
            self.Settings.FOV.Circle.Transparency = value and self.Settings.FOV.FillTransparency or self.Settings.FOV.OutlineTransparency
            self.Settings.FOV.Circle.Thickness = value and 0 or 1
        end,
    })

    FOVGroup:AddLabel('Inline Color'):AddColorPicker('FOVFillColor', {
        Default = self.Settings.FOV.FillColor,
        Transparency = self.Settings.FOV.FillTransparency,
        Callback = function(value)
            self.Settings.FOV.FillColor = value
            if self.Settings.FOV.Filled then
                self.Settings.FOV.Circle.Color = value
            end
        end,
    })

    FOVGroup:AddSlider('FOVFillTransparency', {
        Text = 'Inline Transparency',
        Default = self.Settings.FOV.FillTransparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            self.Settings.FOV.FillTransparency = value
            if self.Settings.FOV.Filled then
                self.Settings.FOV.Circle.Transparency = value
            end
        end,
    })

    FOVGroup:AddLabel('Outline Color'):AddColorPicker('FOVOutlineColor', {
        Default = self.Settings.FOV.OutlineColor,
        Transparency = self.Settings.FOV.OutlineTransparency,
        Callback = function(value)
            self.Settings.FOV.OutlineColor = value
            self.Settings.FOV.OutlineCircle.Color = value
            if not self.Settings.FOV.Filled then
                self.Settings.FOV.Circle.Color = value
            end
        end,
    })

    FOVGroup:AddSlider('FOVOutlineTransparency', {
        Text = 'Outline Transparency',
        Default = self.Settings.FOV.OutlineTransparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            self.Settings.FOV.OutlineTransparency = value
            self.Settings.FOV.OutlineCircle.Transparency = value
            if not self.Settings.FOV.Filled then
                self.Settings.FOV.Circle.Transparency = value
            end
        end,
    })

    FOVGroup:AddSlider('FOVRadius', {
        Text = 'FOV Radius',
        Default = self.Settings.FOV.Radius,
        Min = 50,
        Max = 1000,
        Rounding = 0,
        Callback = function(value)
            self.Settings.FOV.Radius = value
            self.Settings.FOV.Circle.Radius = value
            self.Settings.FOV.OutlineCircle.Radius = value
        end,
    })

    -- Chams UI
    local ChamsGroup = Tabs.Visuals:AddLeftGroupbox('Chams')
    ChamsGroup:AddToggle('ChamsEnabled', {
        Text = 'Enabled',
        Default = self.Settings.Chams.Enabled,
        Callback = function(value)
            self.Settings.Chams.Enabled = value
            if value then
                self.State.ChamsUpdateConnection = game:GetService("RunService").RenderStepped:Connect(function() self.Chams:updateChams() end)
            else
                if self.State.ChamsUpdateConnection then
                    self.State.ChamsUpdateConnection:Disconnect()
                    self.State.ChamsUpdateConnection = nil
                end
                for p in pairs(self.State.Highlights) do
                    self.Chams:removeHighlight(p)
                end
            end
        end,
    })

    ChamsGroup:AddLabel('Fill Color'):AddColorPicker('ChamsFillColor', {
        Default = self.Settings.Chams.Fill.Color,
        Transparency = self.Settings.Chams.Fill.Transparency,
        Callback = function(value)
            self.Settings.Chams.Fill.Color = value
            for _, h in pairs(self.State.Highlights) do
                h.FillColor = value
            end
        end,
    })

    ChamsGroup:AddLabel('Outline Color'):AddColorPicker('ChamsOutlineColor', {
        Default = self.Settings.Chams.Outline.Color,
        Transparency = self.Settings.Chams.Outline.Transparency,
        Callback = function(value)
            self.Settings.Chams.Outline.Color = value
            for _, h in pairs(self.State.Highlights) do
                h.OutlineColor = value
            end
        end,
    })

    ChamsGroup:AddSlider('ChamsFillTransparency', {
        Text = 'Fill Transparency',
        Default = self.Settings.Chams.Fill.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 1,
        Callback = function(value)
            self.Settings.Chams.Fill.Transparency = value
            for _, h in pairs(self.State.Highlights) do
                h.FillTransparency = value
            end
        end,
    })

    ChamsGroup:AddSlider('ChamsOutlineTransparency', {
        Text = 'Outline Transparency',
        Default = self.Settings.Chams.Outline.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 1,
        Callback = function(value)
            self.Settings.Chams.Outline.Transparency = value
            for _, h in pairs(self.State.Highlights) do
                h.OutlineTransparency = value
            end
        end,
    })

    -- Player UI
    local PlayerGroup = Tabs.Player:AddLeftGroupbox('Player')
    PlayerGroup:AddToggle('BhopEnabled', {
        Text = 'Bunny Hop',
        Default = self.Settings.Player.Bhop.Enabled,
        Callback = function(value)
            self.Settings.Player.Bhop.Enabled = value
        end,
    })

    -- Misc UI
    local Optimizations = Tabs.Misc:AddLeftGroupbox('Miscellaneous')
    Optimizations:AddToggle('MiscTextures', {
        Text = 'Toggle Textures',
        Default = self.Settings.Misc.Textures,
        Callback = function(value)
            self.Settings.Misc.Textures = value
            if value then
                self.Misc:optimizeMap()
            else
                self.Misc:revertMap()
            end
        end,
    })

    local Safety = Tabs.Misc:AddRightGroupbox('Safety')
    Safety:AddToggle('VotekickRejoiner', {
        Text = 'Rejoin on Votekick',
        Default = self.Settings.Misc.VotekickRejoiner,
        Callback = function(value)
            self.Settings.Misc.VotekickRejoiner = value
            if value then
                self.Misc:initializeVotekickRejoiner()
            end
        end,
    })

    -- Non-UI Setup
    game:GetService("Workspace").Camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
        self.FOV:updateFOVCirclePosition()
    end)
    game:GetService("RunService").Heartbeat:Connect(function()
        self.FOV:updateFOVCirclePosition()
    end)

    local lastJumpTime = 0
    local jumpCooldown = 0.1
    local function handleBhop()
        if self.Settings.Player.Bhop.Enabled then
            local t = tick()
            if (t - lastJumpTime) >= jumpCooldown then
                local hum = self.PlayerMod:getCharacter() and self.PlayerMod:getCharacter():FindFirstChildOfClass('Humanoid')
                if hum then
                    hum.Jump = true
                end
                lastJumpTime = t
            end
        end
    end

    game:GetService("UserInputService").InputBegan:Connect(function(i, gp)
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
            self.Library:Unload()
        end,
    })
    local menuKeyPicker = MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
        Default = 'RightShift',
        NoUI = true,
        Text = 'Menu keybind',
    })

    self.Library.ToggleKeybind = menuKeyPicker

    -- Addons
    SaveManager:SetLibrary(self.Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
    SaveManager:SetFolder('kaotiksoftworks/PhantomForces/Nullwave')
    SaveManager:BuildConfigSection(Tabs.UISettings)
    SaveManager:LoadAutoloadConfig()
end

function UI:Cleanup()
    -- UI cleanup is handled by Library:OnUnload
end

return UI
