local ESP = {}
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

function ESP:Init(Settings, State, Utilities)
    self.Settings = Settings or {}
    self.State = State or {}
    self.Utilities = Utilities or {}
    -- Initialize default ESP settings if not provided
    self.Settings.ESP = self.Settings.ESP or {
        MaxDistance = { Enabled = true, Value = 1000 },
        UseFOV = true,
        VisibilityCheck = true,
        Features = {
            Box = { Enabled = true, Color = Color3.fromRGB(0, 255, 0), Gradient = true },
            Tracer = { Enabled = true, Color = Color3.fromRGB(0, 255, 0) },
            Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
            DistanceText = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
            HeadDot = { Enabled = true, Color = Color3.fromRGB(255, 0, 0) }
        }
    }
end

function ESP:initializeESP()
    local cache = self.State.Storage and self.State.Storage.ESPCache or {}
    for i = 1, #cache do
        self.Utilities:uncacheObject(cache[i])
    end
    self.State.PlayersToDraw = {}
    self.State.CachedProperties = {}
end

function ESP:cleanupStalePlayers()
    local cache = self.State.Storage and self.State.Storage.ESPCache or {}
    for i = #cache, 1, -1 do
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
    local cachedProperties = self.State.CachedProperties or {}
    local settings = self.Settings.ESP or {}
    local maxDistEnabled = settings.MaxDistance and settings.MaxDistance.Enabled or true
    local maxDistValue = settings.MaxDistance and settings.MaxDistance.Value or 1000
    local cameraPos = Camera.CFrame.Position

    for _, p in ipairs(self.Utilities:getPlayers() or {}) do
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
    if not self.Settings.ESP then
        warn("ESP settings not initialized. Using default settings.")
        self.Settings.ESP = {
            MaxDistance = { Enabled = true, Value = 1000 },
            UseFOV = true,
            VisibilityCheck = true,
            Features = {
                Box = { Enabled = true, Color = Color3.fromRGB(0, 255, 0), Gradient = true },
                Tracer = { Enabled = true, Color = Color3.fromRGB(0, 255, 0) },
                Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
                DistanceText = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
                HeadDot = { Enabled = true, Color = Color3.fromRGB(255, 0, 0) }
            }
        }
    end

    local camPos = Camera.CFrame.Position
    local viewSize = Camera.ViewportSize
    local center = Vector2.new(viewSize.X / 2, viewSize.Y)
    local fovRad = self.Settings.FOV and self.Settings.FOV.OutlineCircle and self.Settings.FOV.OutlineCircle.Radius or 100
    local useFOV = self.Settings.ESP.UseFOV or true
    local cacheTable = self.State.Storage and self.State.Storage.ESPCache or {}
    local playersToDraw = self.State.PlayersToDraw or {}
    local cachedProperties = self.State.CachedProperties or {}
    local settings = self.Settings.ESP

    for i = 1, #playersToDraw do
        local p = playersToDraw[i]
        if not self.Utilities:isValidPlayer(p) then
            self.Utilities:uncacheObject(p)
            cachedProperties[p] = nil
        else
            local cache = cacheTable[p] or (self.Utilities:cacheObject(p) and cacheTable[p])
            local torso, head = self.Utilities:getBodyPart(p, "Torso"), self.Utilities:getBodyPart(p, "Head")
            if not torso or not head then
                for _, e in ipairs(cache or {}) do
                    e.Visible = false
                end
            else
                local torsoPos, torsoOn = Camera:WorldToViewportPoint(torso.Position)
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                if not torsoOn then
                    for _, e in ipairs(cache or {}) do
                        e.Visible = false
                    end
                else
                    local distCam = (torso.Position - camPos).Magnitude
                    local screenPos = Vector2.new(torsoPos.X, torsoPos.Y)
                    local distCenter = (screenPos - center).Magnitude
                    if useFOV and distCenter > fovRad then
                        for _, e in ipairs(cache or {}) do
                            e.Visible = false
                        end
                    else
                        local scale = 1000 / distCam * 80 / Camera.FieldOfView
                        local boxW, boxH = math.floor(3.5 * scale), math.floor(5 * scale)
                        local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2)
                        local vis = self.Utilities:isVisible(head, settings.VisibilityCheck)
                        local baseColor = settings.Features.Box.Color or Color3.fromRGB(0, 255, 0)
                        local gradientColor = settings.Features.Box.Gradient and Color3.fromRGB(baseColor.R * 255 * 0.7, baseColor.G * 255 * 0.7, baseColor.B * 255 * 0.7) or baseColor

                        if settings.Features.Box.Enabled then
                            cache.BoxSquare.Visible = true
                            cache.BoxSquare.Color = baseColor
                            cache.BoxSquare.Position = boxPos
                            cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                            cache.BoxOutline.Position = Vector2.new(boxPos.X - 2, boxPos.Y - 2)
                            cache.BoxOutline.Size = Vector2.new(boxW + 4, boxH + 4)
                            cache.BoxOutline.Color = gradientColor
                            cache.BoxOutline.Thickness = 2
                        else
                            cache.BoxSquare.Visible = false
                            cache.BoxOutline.Visible = false
                        end

                        if settings.Features.Tracer.Enabled then
                            cache.TracerLine.Visible = true
                            cache.TracerLine.Color = vis and settings.Features.Tracer.Color or Color3.fromRGB(255, 0, 0)
                            cache.TracerLine.From = Vector2.new(viewSize.X / 2, viewSize.Y * 0.9)
                            cache.TracerLine.To = screenPos
                            cache.TracerLine.Thickness = math.max(1, scale / 20)
                            cache.TracerLine.Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0.3),
                                NumberSequenceKeypoint.new(1, 1)
                            })
                        else
                            cache.TracerLine.Visible = false
                        end

                        if settings.Features.Name.Enabled and cachedProperties[p] then
                            cache.NameLabel.Visible = true
                            cache.NameLabel.Text = cachedProperties[p].Name
                            cache.NameLabel.Color = settings.Features.Name.Color
                            cache.NameLabel.Size = math.max(14, math.min(18, scale * 2.8))
                            cache.NameLabel.Center = true
                            cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 20)
                            cache.NameLabel.Outline = true
                            cache.NameLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                            cache.NameLabel.TextTransparency = 0.1
                            cache.NameLabel.TextStrokeTransparency = 0.5
                        else
                            cache.NameLabel.Visible = false
                        end

                        if settings.Features.DistanceText.Enabled then
                            cache.DistanceLabel.Visible = true
                            cache.DistanceLabel.Text = math.floor(distCam) .. " studs"
                            cache.DistanceLabel.Color = settings.Features.DistanceText.Color
                            cache.DistanceLabel.Size = math.max(12, math.min(16, scale * 2.3))
                            cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 10)
                            cache.DistanceLabel.Outline = true
                            cache.DistanceLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                            cache.DistanceLabel.TextTransparency = 0.1
                            cache.DistanceLabel.TextStrokeTransparency = 0.5
                        else
                            cache.DistanceLabel.Visible = false
                        end

                        if settings.Features.HeadDot.Enabled and headOn then
                            cache.HeadDot.Visible = true
                            cache.HeadDot.Color = settings.Features.HeadDot.Color
                            cache.HeadDot.Radius = math.max(4, boxH / 15)
                            cache.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                            cache.HeadDot.NumSides = 32
                            cache.HeadDot.Transparency = 0.2
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
    local cache = self.State.Storage and self.State.Storage.ESPCache or {}
    for i = 1, #cache do
        self.Utilities:uncacheObject(cache[i])
    end
    self.State.PlayersToDraw = {}
    self.State.CachedProperties = {}
end

return ESP
