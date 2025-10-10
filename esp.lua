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
                        -- Dynamic scaling for smoother visuals
                        local scale = math.clamp(1200 / distCam * 80 / Camera.FieldOfView, 0.5, 3)
                        local boxW, boxH = math.floor(3.5 * scale), math.floor(5 * scale)
                        local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2)
                        local vis = self.Utilities:isVisible(head, self.Settings.ESP.VisibilityCheck)
                        local boxCol = vis and self.Settings.ESP.Features.Box.Color or Color3.fromRGB(255, 80, 80)
                        local alpha = math.clamp(1 - (distCam / self.Settings.ESP.MaxDistance.Value), 0.3, 1)

                        if self.Settings.ESP.Features.Box.Enabled then
                            cache.BoxSquare.Visible = true
                            cache.BoxSquare.Color = boxCol
                            cache.BoxSquare.Transparency = 1 - alpha
                            cache.BoxSquare.Position = boxPos
                            cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                            cache.BoxOutline.Position = Vector2.new(boxPos.X - 2, boxPos.Y - 2)
                            cache.BoxOutline.Size = Vector2.new(boxW + 4, boxH + 4)
                            cache.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
                            cache.BoxOutline.Transparency = 0.7
                        else
                            cache.BoxSquare.Visible = false
                            cache.BoxOutline.Visible = false
                        end

                        if self.Settings.ESP.Features.Tracer.Enabled then
                            cache.TracerLine.Visible = true
                            cache.TracerLine.Color = vis and self.Settings.ESP.Features.Tracer.Color or Color3.fromRGB(255, 80, 80)
                            cache.TracerLine.Transparency = 1 - alpha
                            cache.TracerLine.From = Vector2.new(viewSize.X / 2, viewSize.Y - 50) -- Slightly offset for cleaner look
                            cache.TracerLine.To = screenPos
                            cache.TracerLine.Thickness = math.max(1, scale * 0.5)
                        else
                            cache.TracerLine.Visible = false
                        end

                        if self.Settings.ESP.Features.Name.Enabled and cachedProperties[p] then
                            cache.NameLabel.Visible = true
                            cache.NameLabel.Text = cachedProperties[p].Name
                            cache.NameLabel.Color = self.Settings.ESP.Features.Name.Color
                            cache.NameLabel.Size = math.max(12, math.min(18, scale * 3))
                            cache.NameLabel.Center = true
                            cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 20)
                            cache.NameLabel.Outline = true
                            cache.NameLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                            cache.NameLabel.Font = Enum.Font.SourceSansBold
                            cache.NameLabel.Transparency = 1 - alpha
                        else
                            cache.NameLabel.Visible = false
                        end

                        if self.Settings.ESP.Features.DistanceText.Enabled then
                            cache.DistanceLabel.Visible = true
                            cache.DistanceLabel.Text = math.floor(distCam) .. " studs"
                            cache.DistanceLabel.Color = self.Settings.ESP.Features.DistanceText.Color
                            cache.DistanceLabel.Size = math.max(12, math.min(16, scale * 2.8))
                            cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 10)
                            cache.DistanceLabel.Outline = true
                            cache.DistanceLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                            cache.DistanceLabel.Font = Enum.Font.SourceSans
                            cache.DistanceLabel.Transparency = 1 - alpha
                        else
                            cache.DistanceLabel.Visible = false
                        end

                        if self.Settings.ESP.Features.HeadDot.Enabled and headOn then
                            cache.HeadDot.Visible = true
                            cache.HeadDot.Color = self.Settings.ESP.Features.HeadDot.Color
                            cache.HeadDot.Radius = math.max(3, boxH / 15)
                            cache.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                            cache.HeadDot.Transparency = 0.5
                            cache.HeadDot.NumSides = 32 -- Smoother circle
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
