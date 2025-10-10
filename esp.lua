local ESP = {}
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

function ESP:Init(Settings, State, Utilities)
    self.Settings = Settings
    self.State = State
    self.Utilities = Utilities
end

function ESP:initializeESP()
    for p in pairs(self.State.Storage.ESPCache) do self.Utilities:uncacheObject(p) end
    self.State.PlayersToDraw = {}
    self.State.CachedProperties = {}
end

function ESP:cleanupStalePlayers()
    for p in pairs(self.State.Storage.ESPCache) do
        if not self.Utilities:isValidPlayer(p) then
            self.Utilities:uncacheObject(p)
            self.State.CachedProperties[p] = nil
        end
    end
end

function ESP:updatePlayerCache()
    self:cleanupStalePlayers()
    self.State.PlayersToDraw = {}
    for _, p in pairs(self.Utilities:getPlayers()) do
        if self.Utilities:isValidPlayer(p) and self.Utilities:isEnemy(p) then
            local torso, head = self.Utilities:getBodyPart(p, "Torso"), self.Utilities:getBodyPart(p, "Head")
            if torso and head then
                local dist = (head.Position - Camera.CFrame.Position).Magnitude
                if not self.Settings.ESP.MaxDistance.Enabled or dist <= self.Settings.ESP.MaxDistance.Value then
                    self.Utilities:cacheObject(p)
                    table.insert(self.State.PlayersToDraw, p)
                    local gui = head:FindFirstChildOfClass("BillboardGui")
                    local label = gui and gui:FindFirstChildOfClass("TextLabel")
                    if gui and label then self.State.CachedProperties[p] = { Name = label.Text } end
                else
                    self.Utilities:uncacheObject(p)
                    self.State.CachedProperties[p] = nil
                end
            else
                self.Utilities:uncacheObject(p)
                self.State.CachedProperties[p] = nil
            end
        end
    end
end

function ESP:renderESP()
    local camPos = Camera.CFrame.Position
    local viewSize = Camera.ViewportSize
    local center = Vector2.new(viewSize.X / 2, viewSize.Y)
    local fovRad = self.Settings.FOV.OutlineCircle.Radius
    for _, p in pairs(self.State.PlayersToDraw) do
        if not self.Utilities:isValidPlayer(p) then
            self.Utilities:uncacheObject(p)
            self.State.CachedProperties[p] = nil
        else
            local cache = self.State.Storage.ESPCache[p] or (self.Utilities:cacheObject(p) and self.State.Storage.ESPCache[p])
            local torso, head = self.Utilities:getBodyPart(p, "Torso"), self.Utilities:getBodyPart(p, "Head")
            if not torso or not head then
                for _, e in pairs(cache) do e.Visible = false end
            else
                local torsoPos, torsoOn = Camera:WorldToViewportPoint(torso.Position)
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                if not torsoOn then
                    for _, e in pairs(cache) do e.Visible = false end
                else
                    local distCam = (torso.Position - camPos).Magnitude
                    local screenPos = Vector2.new(torsoPos.X, torsoPos.Y)
                    local distCenter = (screenPos - center).Magnitude
                    if self.Settings.ESP.UseFOV and distCenter > fovRad then
                        for _, e in pairs(cache) do e.Visible = false end
                    else
                        local scale = 1000 / distCam * 80 / Camera.FieldOfView
                        local boxW, boxH = math.floor(3 * scale), math.floor(4 * scale)
                        local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2)
                        local vis = self.Utilities:isVisible(head, self.Settings.ESP.VisibilityCheck)
                        local boxCol = vis and self.Settings.ESP.Features.Box.Color or Color3.fromRGB(255, 0, 0)

                        cache.BoxSquare.Visible = self.Settings.ESP.Features.Box.Enabled
                        if self.Settings.ESP.Features.Box.Enabled then
                            cache.BoxSquare.Color = boxCol
                            cache.BoxSquare.Position = boxPos
                            cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                            cache.BoxOutline.Position = Vector2.new(boxPos.X - 1, boxPos.Y - 1)
                            cache.BoxOutline.Size = Vector2.new(boxW + 2, boxH + 2)
                        end
                        cache.TracerLine.Visible = self.Settings.ESP.Features.Tracer.Enabled
                        if self.Settings.ESP.Features.Tracer.Enabled then
                            cache.TracerLine.Color = vis and self.Settings.ESP.Features.Tracer.Color or Color3.fromRGB(255, 0, 0)
                            cache.TracerLine.From = Vector2.new(viewSize.X / 2, viewSize.Y)
                            cache.TracerLine.To = screenPos
                        end
                        cache.NameLabel.Visible = self.Settings.ESP.Features.Name.Enabled and self.State.CachedProperties[p]
                        if self.Settings.ESP.Features.Name.Enabled and self.State.CachedProperties[p] then
                            cache.NameLabel.Text = self.State.CachedProperties[p].Name
                            cache.NameLabel.Color = self.Settings.ESP.Features.Name.Color
                            cache.NameLabel.Size = math.max(12, math.min(16, scale * 2.5))
                            cache.NameLabel.Center = true
                            cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 15)
                            cache.NameLabel.Outline = true
                        end
                        cache.DistanceLabel.Visible = self.Settings.ESP.Features.DistanceText.Enabled
                        if self.Settings.ESP.Features.DistanceText.Enabled then
                            local dist = math.floor(distCam)
                            cache.DistanceLabel.Text = dist .. " studs"
                            cache.DistanceLabel.Color = self.Settings.ESP.Features.DistanceText.Color
                            cache.DistanceLabel.Size = math.max(14, math.min(18, scale * 2.5))
                            cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 5)
                            cache.DistanceLabel.Outline = true
                        end
                        cache.HeadDot.Visible = self.Settings.ESP.Features.HeadDot.Enabled and headOn
                        if self.Settings.ESP.Features.HeadDot.Enabled and headOn then
                            cache.HeadDot.Color = self.Settings.ESP.Features.HeadDot.Color
                            cache.HeadDot.Radius = (boxH / 20)
                            cache.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                        end
                    end
                end
            end
        end
    end
end

function ESP:Cleanup()
    if self.State.PlayerCacheUpdate then self.State.PlayerCacheUpdate:Disconnect() end
    if self.State.ESPLoop then self.State.ESPLoop:Disconnect() end
    for p in pairs(self.State.Storage.ESPCache) do self.Utilities:uncacheObject(p) end
    self.State.PlayersToDraw = {}
    self.State.CachedProperties = {}
end

return ESP
