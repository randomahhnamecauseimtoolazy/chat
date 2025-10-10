local ESP = {}
local RunService = game:GetService('RunService')
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
            local torso, head =
                self.Utilities:getBodyPart(p, 'Torso'),
                self.Utilities:getBodyPart(p, 'Head')
            if torso and head then
                local dist = (head.Position - cameraPos).Magnitude
                if not maxDistEnabled or dist <= maxDistValue then
                    self.Utilities:cacheObject(p)
                    table.insert(playersToDraw, p)
                    local gui = head:FindFirstChildOfClass('BillboardGui')
                    local label = gui and gui:FindFirstChildOfClass('TextLabel')
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
            continue
        end

        local cache = cacheTable[p]
            or (self.Utilities:cacheObject(p) and cacheTable[p])
        local torso, head =
            self.Utilities:getBodyPart(p, 'Torso'),
            self.Utilities:getBodyPart(p, 'Head')
        if not torso or not head then
            for _, e in pairs(cache) do
                e.Visible = false
            end
            continue
        end

        local torsoPos, torsoOn = Camera:WorldToViewportPoint(torso.Position)
        local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
        if not torsoOn then
            for _, e in pairs(cache) do
                e.Visible = false
            end
            continue
        end

        local distCam = (torso.Position - camPos).Magnitude
        local screenPos = Vector2.new(torsoPos.X, torsoPos.Y)
        local distCenter = (screenPos - center).Magnitude
        if useFOV and distCenter > fovRad then
            for _, e in pairs(cache) do
                e.Visible = false
            end
            continue
        end

        local vis =
            self.Utilities:isVisible(head, self.Settings.ESP.VisibilityCheck)
        local baseColor = vis and self.Settings.ESP.Features.Box.Color
            or Color3.fromRGB(255, 60, 60)
        local fadeFactor = math.clamp(1 - (distCam / 500), 0.3, 1) -- subtle fade with distance
        local boxColor = Color3.new(
            baseColor.R * fadeFactor,
            baseColor.G * fadeFactor,
            baseColor.B * fadeFactor
        )

        local scale = 1000 / distCam * 80 / Camera.FieldOfView
        local boxW, boxH = math.floor(3.5 * scale), math.floor(5.2 * scale)
        local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2)

        -- BOX --
        if self.Settings.ESP.Features.Box.Enabled then
            cache.BoxSquare.Visible = true
            cache.BoxSquare.Color = boxColor
            cache.BoxSquare.Thickness = 2
            cache.BoxSquare.Filled = false
            cache.BoxSquare.Position = boxPos
            cache.BoxSquare.Size = Vector2.new(boxW, boxH)

            -- Soft background fill
            cache.BoxFill.Visible = true
            cache.BoxFill.Color = Color3.new(boxColor.R, boxColor.G, boxColor.B)
            cache.BoxFill.Transparency = 0.85
            cache.BoxFill.Filled = true
            cache.BoxFill.Position = boxPos
            cache.BoxFill.Size = Vector2.new(boxW, boxH)
        else
            cache.BoxSquare.Visible = false
            cache.BoxFill.Visible = false
        end

        -- TRACER --
        if self.Settings.ESP.Features.Tracer.Enabled then
            cache.TracerLine.Visible = true
            cache.TracerLine.Color = boxColor
            cache.TracerLine.Thickness = 1.5
            cache.TracerLine.Transparency = 0.7
            cache.TracerLine.From = Vector2.new(viewSize.X / 2, viewSize.Y)
            cache.TracerLine.To = screenPos
        else
            cache.TracerLine.Visible = false
        end

        -- NAME --
        if self.Settings.ESP.Features.Name.Enabled and cachedProperties[p] then
            cache.NameLabel.Visible = true
            cache.NameLabel.Text = cachedProperties[p].Name
            cache.NameLabel.Color = boxColor
            cache.NameLabel.Center = true
            cache.NameLabel.Size = math.max(12, math.min(18, scale * 2.3))
            cache.NameLabel.Position =
                Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 18)
            cache.NameLabel.Outline = true
            cache.NameLabel.Transparency = 0.8
        else
            cache.NameLabel.Visible = false
        end

        -- DISTANCE --
        if self.Settings.ESP.Features.DistanceText.Enabled then
            cache.DistanceLabel.Visible = true
            cache.DistanceLabel.Text = string.format('%.0f studs', distCam)
            cache.DistanceLabel.Color = Color3.fromRGB(180, 180, 180)
            cache.DistanceLabel.Center = true
            cache.DistanceLabel.Size = math.max(11, math.min(16, scale * 2))
            cache.DistanceLabel.Position =
                Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 10)
            cache.DistanceLabel.Outline = true
            cache.DistanceLabel.Transparency = 0.7
        else
            cache.DistanceLabel.Visible = false
        end

        -- HEAD DOT (with glow) --
        if self.Settings.ESP.Features.HeadDot.Enabled and headOn then
            cache.HeadDot.Visible = true
            cache.HeadDot.Color = boxColor
            cache.HeadDot.Radius = math.max(2, boxH / 25)
            cache.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
            cache.HeadDot.Thickness = 2
            cache.HeadDot.Filled = true

            -- Optional "glow ring" for style
            cache.HeadDotGlow.Visible = true
            cache.HeadDotGlow.Color =
                Color3.new(boxColor.R * 0.8, boxColor.G * 0.8, boxColor.B * 0.8)
            cache.HeadDotGlow.Radius = cache.HeadDot.Radius + 3
            cache.HeadDotGlow.Thickness = 1
            cache.HeadDotGlow.Filled = false
            cache.HeadDotGlow.Transparency = 0.5
            cache.HeadDotGlow.Position = Vector2.new(headPos.X, headPos.Y)
        else
            cache.HeadDot.Visible = false
            cache.HeadDotGlow.Visible = false
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
