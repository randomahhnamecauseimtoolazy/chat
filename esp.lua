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
    local cachedProperties = self.State.CachedProperties
    local cameraFOV = Camera.FieldOfView
    local boxEnabled = self.Settings.ESP.Features.Box.Enabled
    local tracerEnabled = self.Settings.ESP.Features.Tracer.Enabled
    local nameEnabled = self.Settings.ESP.Features.Name.Enabled
    local distanceEnabled = self.Settings.ESP.Features.DistanceText.Enabled
    local headDotEnabled = self.Settings.ESP.Features.HeadDot.Enabled

    for p, _ in pairs(self.State.PlayersToDraw) do
        if not self.Utilities:isValidPlayer(p) then
            self.Utilities:uncacheObject(p)
            cachedProperties[p] = nil
        else
            local cache = cacheTable[p] or (self.Utilities:cacheObject(p) and cacheTable[p])
            local torsoPos = cachedProperties[p].TorsoPos
            local headPos = cachedProperties[p].HeadPos
            local distCam = cachedProperties[p].Dist
            local torsoScreenPos, torsoOn = Camera:WorldToViewportPoint(torsoPos)
            local headScreenPos, headOn = Camera:WorldToViewportPoint(headPos)

            if not torsoOn then
                for _, e in ipairs(cache) do
                    e.Visible = false
                end
            else
                local screenPos = Vector2.new(torsoScreenPos.X, torsoScreenPos.Y)
                local distCenter = (screenPos - center).Magnitude
                if useFOV and distCenter > fovRad then
                    for _, e in ipairs(cache) do
                        e.Visible = false
                    end
                else
                    local scale = 1000 / distCam * 80 / cameraFOV
                    local boxW, boxH = math.floor(3 * scale), math.floor(4 * scale)
                    local boxPos = Vector2.new(torsoScreenPos.X - boxW / 2, torsoScreenPos.Y - boxH / 2)
                    local vis = cachedProperties[p].IsVisible
                    local boxCol = vis and self.Settings.ESP.Features.Box.Color or Color3.fromRGB(255, 0, 0)

                    if boxEnabled and cache.BoxSquare.Position ~= boxPos then
                        cache.BoxSquare.Visible = true
                        cache.BoxSquare.Color = boxCol
                        cache.BoxSquare.Position = boxPos
                        cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                        cache.BoxOutline.Position = Vector2.new(boxPos.X - 1, boxPos.Y - 1)
                        cache.BoxOutline.Size = Vector2.new(boxW + 2, boxH + 2)
                    else
                        cache.BoxSquare.Visible = false
                    end

                    if tracerEnabled then
                        cache.TracerLine.Visible = true
                        cache.TracerLine.Color = vis and self.Settings.ESP.Features.Tracer.Color or Color3.fromRGB(255, 0, 0)
                        cache.TracerLine.From = center
                        cache.TracerLine.To = screenPos
                    else
                        cache.TracerLine.Visible = false
                    end

                    if nameEnabled and cachedProperties[p].Name then
                        cache.NameLabel.Visible = true
                        cache.NameLabel.Text = cachedProperties[p].Name
                        cache.NameLabel.Color = self.Settings.ESP.Features.Name.Color
                        cache.NameLabel.Size = math.max(12, math.min(16, scale * 2.5))
                        cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 15)
                    else
                        cache.NameLabel.Visible = false
                    end

                    if distanceEnabled then
                        cache.DistanceLabel.Visible = true
                        cache.DistanceLabel.Text = math.floor(distCam) .. " studs"
                        cache.DistanceLabel.Color = self.Settings.ESP.Features.DistanceText.Color
                        cache.DistanceLabel.Size = math.max(14, math.min(18, scale * 2.5))
                        cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 5)
                    else
                        cache.DistanceLabel.Visible = false
                    end

                    if headDotEnabled and headOn then
                        cache.HeadDot.Visible = true
                        cache.HeadDot.Color = self.Settings.ESP.Features.HeadDot.Color
                        cache.HeadDot.Radius = boxH / 20
                        cache.HeadDot.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
                    else
                        cache.HeadDot.Visible = false
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
