local ESP = {}
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

function ESP:Init(Settings, State, Utilities)
    self.Settings = Settings
    self.State = State
    self.Utilities = Utilities
end

function ESP:initializeESP()
    -- Clear cache using indexed loop for performance
    local cache = self.State.Storage.ESPCache
    for i = 1, #cache do
        self.Utilities:uncacheObject(cache[i])
    end
    self.State.PlayersToDraw = {}
    self.State.CachedProperties = {}
end

function ESP:cleanupStalePlayers()
    local cache = self.State.Storage.ESPCache
    for i = #cache, 1, -1 do -- Reverse to safely remove elements
        local p = cache[i]
        if not self.Utilities:isValidPlayer(p) then
            self.Utilities:uncacheObject(p)
            self.State.CachedProperties[p] = nil
            table.remove(cache, i)
        end
    end
end

function ESP:updatePlayerCache()
    self:cleanupStalePlayers()
    local playersToDraw = {}
    local cachedProperties = self.State.CachedProperties
    local settings = self.Settings.ESP
    local maxDistEnabled = settings.MaxDistance.Enabled
    local maxDistValue = settings.MaxDistance.Value
    local cameraPos = Camera.CFrame.Position

    for _, p in ipairs(self.Utilities:getPlayers()) do
        if self.Utilities:isValidPlayer(p) and self.Utilities:isEnemy(p) then
            local torso, head = self.Utilities:getBodyPart(p, "Torso"), self.Utilities:getBodyPart(p, "Head")
            if torso and head then
                local dist = (head.Position - cameraPos).Magnitude
                if not maxDistEnabled or dist <= maxDistValue then
                    self.Utilities:cacheObject(p)
                    table.insert(playersToDraw, p)
                    local gui = head:FindFirstChildOfClass("BillboardGui")
                    local label = gui and gui:FindFirstChildOfClass("TextLabel")
                    if gui and label then
                        cachedProperties[p] = { Name = label.Text }
                    end
                else
                    self.Utilities:uncacheObject(p)
                    cachedProperties[p] = nil
                end
            else
                self.Utilities:uncacheObject(p)
                cachedProperties[p] = nil
            end
        end
    end
    self.State.PlayersToDraw = playersToDraw
end

function ESP:renderESP()
    local camPos = Camera.CFrame.Position
    local viewSize = Camera.ViewportSize
    local center = Vector2.new(viewSize.X / 2, viewSize.Y)
    local fovRad = self.Settings.FOV.OutlineCircle.Radius
    local useFOV = self.Settings.ESP.UseFOV
    local cacheTable = self.State.Storage.ESPCache
    local playersToDraw = self.State.PlayersToDraw
    local cachedProperties = self.State.CachedProperties

    for i = 1, #playersToDraw do
        local p = playersToDraw[i]
        if not self.Utilities:isValidPlayer(p) then
            self.Utilities:uncacheObject(p)
            cachedProperties[p] = nil
        else
            local cache = cacheTable[p] or (self.Utilities:cacheObject(p) and cacheTable[p])
            local torso, head = self.Utilities:getBodyPart(p, "Torso"), self.Utilities:getBodyPart(p, "Head")
            if not torso or not head then
                for _, e in ipairs(cache) do
                    e.Visible = false
                end
            else
                local torsoPos, torsoOn = Camera:WorldToViewportPoint(torso.Position)
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                if not torsoOn then
                    for _, e in ipairs(cache) do
                        e.Visible = false
                    end
                else
                    local distCam = (torso.Position - camPos).Magnitude
                    local screenPos = Vector2.new(torsoPos.X, torsoPos.Y)
                    local distCenter = (screenPos - center).Magnitude
                    if useFOV and distCenter > fovRad then
                        for _, e in ipairs(cache) do
                            e.Visible = false
                        end
                    else
                        local scale = 1000 / distCam * 80 / Camera.FieldOfView
                        local boxW, boxH = math.floor(3 * scale), math.floor(4 * scale)
                        local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2)
                        local vis = self.Utilities:isVisible(head, self.Settings.ESP.VisibilityCheck)
                        
                        -- Enhanced color handling with smooth transitions
                        local boxCol = vis and self.Settings.ESP.Features.Box.Color or Color3.fromRGB(255, 50, 50)
                        local outlineCol = vis and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(80, 20, 20)
                        local textCol = vis and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 150, 150)
                        
                        -- Calculate health-based color tint (if health info is available)
                        local healthTint = Color3.fromRGB(255, 255, 255)
                        if p.Character and p.Character:FindFirstChild("Humanoid") then
                            local humanoid = p.Character.Humanoid
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            healthTint = Color3.new(1, healthPercent, healthPercent)
                        end

                        if self.Settings.ESP.Features.Box.Enabled then
                            -- Enhanced box with multiple outlines for better visibility
                            cache.BoxSquare.Visible = true
                            cache.BoxSquare.Color = boxCol
                            cache.BoxSquare.Position = boxPos
                            cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                            cache.BoxSquare.Thickness = 1.5
                            
                            -- Main outline
                            cache.BoxOutline.Position = Vector2.new(boxPos.X - 2, boxPos.Y - 2)
                            cache.BoxOutline.Size = Vector2.new(boxW + 4, boxH + 4)
                            cache.BoxOutline.Color = outlineCol
                            cache.BoxOutline.Thickness = 2
                            
                            -- Inner glow effect
                            cache.BoxInner.Position = Vector2.new(boxPos.X + 1, boxPos.Y + 1)
                            cache.BoxInner.Size = Vector2.new(boxW - 2, boxH - 2)
                            cache.BoxInner.Color = Color3.new(boxCol.R * 1.3, boxCol.G * 1.3, boxCol.B * 1.3)
                            cache.BoxInner.Thickness = 1
                            cache.BoxInner.Transparency = 0.7
                        else
                            cache.BoxSquare.Visible = false
                            cache.BoxOutline.Visible = false
                            cache.BoxInner.Visible = false
                        end

                        if self.Settings.ESP.Features.Tracer.Enabled then
                            cache.TracerLine.Visible = true
                            cache.TracerLine.Color = vis and self.Settings.ESP.Features.Tracer.Color or Color3.fromRGB(255, 80, 80)
                            cache.TracerLine.From = Vector2.new(viewSize.X / 2, viewSize.Y)
                            cache.TracerLine.To = screenPos
                            cache.TracerLine.Thickness = 1.2
                            
                            -- Tracer outline for better visibility
                            cache.TracerOutline.Visible = true
                            cache.TracerOutline.Color = Color3.fromRGB(20, 20, 20)
                            cache.TracerOutline.From = Vector2.new(viewSize.X / 2, viewSize.Y)
                            cache.TracerOutline.To = screenPos
                            cache.TracerOutline.Thickness = 2.4
                            cache.TracerOutline.Transparency = 0.3
                        else
                            cache.TracerLine.Visible = false
                            cache.TracerOutline.Visible = false
                        end

                        if self.Settings.ESP.Features.Name.Enabled and cachedProperties[p] then
                            cache.NameLabel.Visible = true
                            cache.NameLabel.Text = cachedProperties[p].Name
                            cache.NameLabel.Color = textCol
                            cache.NameLabel.Size = math.max(14, math.min(18, scale * 2.8)) -- Slightly larger for better readability
                            cache.NameLabel.Center = true
                            cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 18) -- More spacing
                            cache.NameLabel.Outline = true
                            cache.NameLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                            cache.NameLabel.Font = Drawing.Fonts.UI
                        else
                            cache.NameLabel.Visible = false
                        end

                        if self.Settings.ESP.Features.DistanceText.Enabled then
                            cache.DistanceLabel.Visible = true
                            cache.DistanceLabel.Text = math.floor(distCam) .. "m"
                            cache.DistanceLabel.Color = textCol
                            cache.DistanceLabel.Size = math.max(12, math.min(16, scale * 2.3))
                            cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 8)
                            cache.DistanceLabel.Outline = true
                            cache.DistanceLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                            cache.DistanceLabel.Font = Drawing.Fonts.UI
                        else
                            cache.DistanceLabel.Visible = false
                        end

                        if self.Settings.ESP.Features.HeadDot.Enabled and headOn then
                            cache.HeadDot.Visible = true
                            cache.HeadDot.Color = self.Settings.ESP.Features.HeadDot.Color
                            cache.HeadDot.Radius = math.max(2, boxH / 15) -- Minimum size for visibility
                            cache.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                            cache.HeadDot.Filled = true
                            
                            -- Head dot outline
                            cache.HeadDotOutline.Visible = true
                            cache.HeadDotOutline.Color = outlineCol
                            cache.HeadDotOutline.Radius = cache.HeadDot.Radius + 1
                            cache.HeadDotOutline.Position = Vector2.new(headPos.X, headPos.Y)
                            cache.HeadDotOutline.Filled = false
                            cache.HeadDotOutline.Thickness = 1.5
                        else
                            cache.HeadDot.Visible = false
                            cache.HeadDotOutline.Visible = false
                        end

                        -- Health bar (new feature)
                        if self.Settings.ESP.Features.HealthBar.Enabled and p.Character and p.Character:FindFirstChild("Humanoid") then
                            local humanoid = p.Character.Humanoid
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            
                            cache.HealthBarBG.Visible = true
                            cache.HealthBarBG.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
                            cache.HealthBarBG.Size = Vector2.new(3, boxH)
                            cache.HealthBarBG.Color = Color3.fromRGB(40, 40, 40)
                            cache.HealthBarBG.Filled = true
                            
                            cache.HealthBar.Visible = true
                            local healthHeight = math.floor(boxH * healthPercent)
                            cache.HealthBar.Position = Vector2.new(boxPos.X - 6, boxPos.Y + (boxH - healthHeight))
                            cache.HealthBar.Size = Vector2.new(3, healthHeight)
                            
                            -- Gradient health color (green to red based on health)
                            local healthColor = Color3.new(2 - healthPercent * 2, healthPercent * 2, 0)
                            cache.HealthBar.Color = healthColor
                            cache.HealthBar.Filled = true
                        else
                            cache.HealthBar.Visible = false
                            cache.HealthBarBG.Visible = false
                        end
                    end
                end
            end
        end
    end
end

function ESP:Cleanup()
    if self.State.PlayerCacheUpdate then
        self.State.PlayerCacheUpdate:Disconnect()
    end
    if self.State.ESPLoop then
        self.State.ESPLoop:Disconnect()
    end
    local cache = self.State.Storage.ESPCache
    for i = 1, #cache do
        self.Utilities:uncacheObject(cache[i])
    end
    self.State.PlayersToDraw = {}
    self.State.CachedProperties = {}
end

return ESP
