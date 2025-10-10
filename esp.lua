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
                        -- Improved scaling calculation
                        local scale = math.clamp(1200 / distCam * 60 / Camera.FieldOfView, 0.8, 2.5)
                        local boxW, boxH = math.floor(3.2 * scale), math.floor(5 * scale)
                        local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2)
                        local vis = self.Utilities:isVisible(head, self.Settings.ESP.VisibilityCheck)
                        
                        -- Enhanced color system with team-based colors
                        local teamColor = self.Utilities:getTeamColor(p)
                        local boxCol = vis and (self.Settings.ESP.Features.Box.UseTeamColor and teamColor or self.Settings.ESP.Features.Box.Color) or Color3.fromRGB(255, 60, 60)
                        local outlineCol = Color3.fromRGB(20, 20, 20)
                        local textCol = Color3.fromRGB(255, 255, 255)
                        
                        -- Health-based coloring (optional)
                        local humanoid = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid and self.Settings.ESP.Features.Box.UseHealthColor then
                            local healthPct = humanoid.Health / humanoid.MaxHealth
                            if healthPct > 0.6 then
                                boxCol = Color3.fromRGB(60, 255, 60) -- Green
                            elseif healthPct > 0.3 then
                                boxCol = Color3.fromRGB(255, 255, 60) -- Yellow
                            else
                                boxCol = Color3.fromRGB(255, 60, 60) -- Red
                            end
                        end

                        -- BOX: Enhanced with rounded corners and better outlines
                        if self.Settings.ESP.Features.Box.Enabled then
                            -- Main box
                            cache.BoxSquare.Visible = true
                            cache.BoxSquare.Color = boxCol
                            cache.BoxSquare.Position = boxPos
                            cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                            cache.BoxSquare.Thickness = 1.5
                            
                            -- Outer outline (dark)
                            cache.BoxOutline.Visible = true
                            cache.BoxOutline.Color = outlineCol
                            cache.BoxOutline.Position = Vector2.new(boxPos.X - 2, boxPos.Y - 2)
                            cache.BoxOutline.Size = Vector2.new(boxW + 4, boxH + 4)
                            cache.BoxOutline.Thickness = 2
                            
                            -- Inner glow (subtle)
                            cache.BoxInner.Visible = true
                            cache.BoxInner.Color = Color3.fromRGB(boxCol.R * 255 * 1.3, boxCol.G * 255 * 1.3, boxCol.B * 255 * 1.3)
                            cache.BoxInner.Position = Vector2.new(boxPos.X + 1, boxPos.Y + 1)
                            cache.BoxInner.Size = Vector2.new(boxW - 2, boxH - 2)
                            cache.BoxInner.Thickness = 1
                        else
                            cache.BoxSquare.Visible = false
                            cache.BoxOutline.Visible = false
                            cache.BoxInner.Visible = false
                        end

                        -- TRACER: Enhanced with fade effect and better positioning
                        if self.Settings.ESP.Features.Tracer.Enabled then
                            cache.TracerLine.Visible = true
                            cache.TracerLine.Color = vis and (self.Settings.ESP.Features.Tracer.UseTeamColor and teamColor or self.Settings.ESP.Features.Tracer.Color) or Color3.fromRGB(255, 60, 60)
                            cache.TracerLine.Thickness = 1.2
                            
                            -- Tracer origin options (bottom center or top center)
                            local tracerOrigin
                            if self.Settings.ESP.Features.Tracer.FromTop then
                                tracerOrigin = Vector2.new(viewSize.X / 2, 0)
                            else
                                tracerOrigin = Vector2.new(viewSize.X / 2, viewSize.Y)
                            end
                            
                            cache.TracerLine.From = tracerOrigin
                            cache.TracerLine.To = Vector2.new(torsoPos.X, torsoPos.Y + boxH/2)
                        else
                            cache.TracerLine.Visible = false
                        end

                        -- NAME: Enhanced with better typography and background
                        if self.Settings.ESP.Features.Name.Enabled and cachedProperties[p] then
                            cache.NameLabel.Visible = true
                            cache.NameLabel.Text = cachedProperties[p].Name
                            cache.NameLabel.Color = textCol
                            cache.NameLabel.Size = math.max(14, math.min(18, scale * 3))
                            cache.NameLabel.Font = Drawing.Fonts.UI
                            cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 20)
                            cache.NameLabel.Outline = true
                            cache.NameLabel.OutlineColor = outlineCol
                            
                            -- Name background for better readability
                            cache.NameBackground.Visible = true
                            cache.NameBackground.Color = Color3.fromRGB(0, 0, 0)
                            cache.NameBackground.Size = Vector2.new(cache.NameLabel.TextBounds.X + 8, cache.NameLabel.TextBounds.Y + 4)
                            cache.NameBackground.Position = Vector2.new(boxPos.X + (boxW / 2) - cache.NameBackground.Size.X / 2, boxPos.Y - 22)
                            cache.NameBackground.Filled = true
                            cache.NameBackground.Transparency = 0.6
                        else
                            cache.NameLabel.Visible = false
                            cache.NameBackground.Visible = false
                        end

                        -- DISTANCE: Enhanced with icon and better formatting
                        if self.Settings.ESP.Features.DistanceText.Enabled then
                            cache.DistanceLabel.Visible = true
                            local distanceText = string.format("%d", math.floor(distCam))
                            if self.Settings.ESP.Features.DistanceText.ShowUnits then
                                distanceText = distanceText .. "m"
                            end
                            cache.DistanceLabel.Text = distanceText
                            cache.DistanceLabel.Color = textCol
                            cache.DistanceLabel.Size = math.max(12, math.min(16, scale * 2.8))
                            cache.DistanceLabel.Font = Drawing.Fonts.UI
                            cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 8)
                            cache.DistanceLabel.Outline = true
                            cache.DistanceLabel.OutlineColor = outlineCol
                            
                            -- Distance background
                            cache.DistanceBackground.Visible = true
                            cache.DistanceBackground.Color = Color3.fromRGB(0, 0, 0)
                            cache.DistanceBackground.Size = Vector2.new(cache.DistanceLabel.TextBounds.X + 8, cache.DistanceLabel.TextBounds.Y + 4)
                            cache.DistanceBackground.Position = Vector2.new(boxPos.X + (boxW / 2) - cache.DistanceBackground.Size.X / 2, boxPos.Y + boxH + 6)
                            cache.DistanceBackground.Filled = true
                            cache.DistanceBackground.Transparency = 0.6
                        else
                            cache.DistanceLabel.Visible = false
                            cache.DistanceBackground.Visible = false
                        end

                        -- HEAD DOT: Enhanced with outline and dynamic sizing
                        if self.Settings.ESP.Features.HeadDot.Enabled and headOn then
                            cache.HeadDot.Visible = true
                            cache.HeadDot.Color = self.Settings.ESP.Features.HeadDot.UseTeamColor and teamColor or self.Settings.ESP.Features.HeadDot.Color
                            cache.HeadDot.Radius = math.max(2, math.min(6, boxH / 15))
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

                        -- HEALTH BAR: New feature for professional ESP
                        if self.Settings.ESP.Features.HealthBar.Enabled and humanoid then
                            local healthPct = humanoid.Health / humanoid.MaxHealth
                            local barWidth = 3
                            local barHeight = boxH
                            local barX = boxPos.X - 6
                            local barY = boxPos.Y
                            
                            -- Health bar background
                            cache.HealthBarBackground.Visible = true
                            cache.HealthBarBackground.Color = Color3.fromRGB(40, 40, 40)
                            cache.HealthBarBackground.Size = Vector2.new(barWidth, barHeight)
                            cache.HealthBarBackground.Position = Vector2.new(barX, barY)
                            cache.HealthBarBackground.Filled = true
                            cache.HealthBarBackground.Transparency = 0.4
                            
                            -- Health bar fill
                            local healthHeight = math.floor(barHeight * healthPct)
                            cache.HealthBar.Visible = true
                            cache.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 60)
                            cache.HealthBar.Size = Vector2.new(barWidth, healthHeight)
                            cache.HealthBar.Position = Vector2.new(barX, barY + (barHeight - healthHeight))
                            cache.HealthBar.Filled = true
                        else
                            cache.HealthBar.Visible = false
                            cache.HealthBarBackground.Visible = false
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
