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
                        local boxW, boxH = math.floor(2.5 * scale), math.floor(5.5 * scale) -- Adjusted for tighter, more professional fit
                        local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2 + (0.5 * scale)) -- Slight offset for better centering
                        local vis = self.Utilities:isVisible(head, self.Settings.ESP.VisibilityCheck)
                        local boxCol = vis and self.Settings.ESP.Features.Box.Color or Color3.fromRGB(255, 0, 0)

                        if self.Settings.ESP.Features.Box.Enabled then
                            -- Add subtle fill for depth and professionalism
                            if not cache.BoxFill then
                                cache.BoxFill = Drawing.new("Square")
                                cache.BoxFill.Filled = true
                                cache.BoxFill.Transparency = 0.15 -- Low opacity for subtle highlight
                                table.insert(cache, cache.BoxFill)
                            end
                            cache.BoxFill.Visible = true
                            cache.BoxFill.Color = boxCol
                            cache.BoxFill.Position = boxPos
                            cache.BoxFill.Size = Vector2.new(boxW, boxH)

                            cache.BoxSquare.Visible = true
                            cache.BoxSquare.Color = boxCol
                            cache.BoxSquare.Position = boxPos
                            cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                            cache.BoxSquare.Filled = false
                            cache.BoxSquare.Thickness = 1 -- Clean thin lines

                            cache.BoxOutline.Visible = true
                            cache.BoxOutline.Color = Color3.new(0, 0, 0) -- Black outline for contrast
                            cache.BoxOutline.Transparency = 1
                            cache.BoxOutline.Filled = false
                            cache.BoxOutline.Thickness = 1
                            cache.BoxOutline.Position = Vector2.new(boxPos.X - 1, boxPos.Y - 1)
                            cache.BoxOutline.Size = Vector2.new(boxW + 2, boxH + 2)
                        else
                            cache.BoxSquare.Visible = false
                            cache.BoxOutline.Visible = false
                            if cache.BoxFill then cache.BoxFill.Visible = false end
                        end

                        if self.Settings.ESP.Features.Tracer.Enabled then
                            cache.TracerLine.Visible = true
                            cache.TracerLine.Color = vis and self.Settings.ESP.Features.Tracer.Color or Color3.fromRGB(255, 0, 0)
                            cache.TracerLine.Thickness = 1 -- Clean thickness
                            cache.TracerLine.From = Vector2.new(viewSize.X / 2, viewSize.Y)
                            cache.TracerLine.To = boxPos + Vector2.new(boxW / 2, boxH) -- To bottom of box for better flow
                        else
                            cache.TracerLine.Visible = false
                        end

                        if self.Settings.ESP.Features.Name.Enabled and cachedProperties[p] then
                            cache.NameLabel.Visible = true
                            cache.NameLabel.Text = cachedProperties[p].Name
                            cache.NameLabel.Color = self.Settings.ESP.Features.Name.Color
                            cache.NameLabel.Size = math.max(12, math.min(16, scale * 2.5))
                            cache.NameLabel.Center = true
                            cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - cache.NameLabel.Size - 2) -- Slightly higher for spacing
                            cache.NameLabel.Outline = true
                            cache.NameLabel.Transparency = 1
                        else
                            cache.NameLabel.Visible = false
                        end

                        if self.Settings.ESP.Features.DistanceText.Enabled then
                            cache.DistanceLabel.Visible = true
                            cache.DistanceLabel.Text = math.floor(distCam) .. " studs"
                            cache.DistanceLabel.Color = self.Settings.ESP.Features.DistanceText.Color
                            cache.DistanceLabel.Size = math.max(14, math.min(18, scale * 2.5))
                            cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 2) -- Better spacing
                            cache.DistanceLabel.Center = true
                            cache.DistanceLabel.Outline = true
                            cache.DistanceLabel.Transparency = 1
                        else
                            cache.DistanceLabel.Visible = false
                        end

                        -- Added health bar for more informative and professional look
                        if self.Settings.ESP.Features.HealthBar and self.Settings.ESP.Features.HealthBar.Enabled then -- Assuming added to settings
                            local humanoid = p.Character:FindFirstChild("Humanoid")
                            if humanoid then
                                local healthPct = humanoid.Health / humanoid.MaxHealth
                                local barWidth = 4 -- Thin bar for clean look
                                local barHeight = boxH
                                local barPos = Vector2.new(boxPos.X - barWidth - 4, boxPos.Y) -- Left of box with spacing

                                if not cache.HealthBarBG then
                                    cache.HealthBarBG = Drawing.new("Square")
                                    cache.HealthBarBG.Filled = true
                                    cache.HealthBarBG.Transparency = 0.5
                                    cache.HealthBarBG.Color = Color3.new(0, 0, 0) -- Dark background
                                    table.insert(cache, cache.HealthBarBG)
                                end

                                if not cache.HealthBarFill then
                                    cache.HealthBarFill = Drawing.new("Square")
                                    cache.HealthBarFill.Filled = true
                                    cache.HealthBarFill.Transparency = 1
                                    table.insert(cache, cache.HealthBarFill)
                                end

                                cache.HealthBarBG.Visible = true
                                cache.HealthBarBG.Position = barPos
                                cache.HealthBarBG.Size = Vector2.new(barWidth, barHeight)

                                cache.HealthBarFill.Visible = true
                                cache.HealthBarFill.Position = barPos + Vector2.new(0, barHeight * (1 - healthPct))
                                cache.HealthBarFill.Size = Vector2.new(barWidth, barHeight * healthPct)

                                -- Dynamic color for health (red low, yellow mid, green high)
                                if healthPct < 0.3 then
                                    cache.HealthBarFill.Color = Color3.fromRGB(255, 0, 0)
                                elseif healthPct < 0.6 then
                                    cache.HealthBarFill.Color = Color3.fromRGB(255, 255, 0)
                                else
                                    cache.HealthBarFill.Color = Color3.fromRGB(0, 255, 0)
                                end
                            else
                                if cache.HealthBarBG then cache.HealthBarBG.Visible = false end
                                if cache.HealthBarFill then cache.HealthBarFill.Visible = false end
                            end
                        else
                            if cache.HealthBarBG then cache.HealthBarBG.Visible = false end
                            if cache.HealthBarFill then cache.HealthBarFill.Visible = false end
                        end

                        if self.Settings.ESP.Features.HeadDot.Enabled and headOn then
                            cache.HeadDot.Visible = true
                            cache.HeadDot.Color = self.Settings.ESP.Features.HeadDot.Color
                            cache.HeadDot.Radius = boxH / 15 -- Slightly larger for visibility
                            cache.HeadDot.NumSides = 32 -- Smoother circle
                            cache.HeadDot.Thickness = 1
                            cache.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                        else
                            cache.HeadDot.Visible = false
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
