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

-- Helper function to create rounded corners via additional frames (assuming cacheObject creates these; this is conceptual for visuals)
-- In practice, you'd need to modify cacheObject to use Images for corners or UI gradients/corners if supported.
-- For now, adding subtle thickness and transparency tweaks in render.

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
                        local boxCol = vis and self.Settings.ESP.Features.Box.Color or Color3.fromRGB(255, 0, 0)
                        local boxTransparency = vis and 0.1 or 0.3  -- Softer, semi-transparent fill for professionalism
                        local outlineTransparency = 0  -- Solid outline for crispness

                        if self.Settings.ESP.Features.Box.Enabled then
                            -- Enhanced box: Filled with transparency, thinner outline, add corner accents if possible
                            cache.BoxSquare.Visible = true
                            cache.BoxSquare.Color = boxCol
                            cache.BoxSquare.Transparency = boxTransparency  -- Semi-transparent fill
                            cache.BoxSquare.Position = boxPos
                            cache.BoxSquare.Size = Vector2.new(boxW, boxH)
                            cache.BoxSquare.Filled = true  -- Assume Frame supports Filled; makes it a filled rect
                            
                            cache.BoxOutline.Visible = true
                            cache.BoxOutline.Color = Color3.new(0, 0, 0)  -- Black outline for contrast
                            cache.BoxOutline.Transparency = outlineTransparency
                            cache.BoxOutline.Position = Vector2.new(boxPos.X - 1, boxPos.Y - 1)
                            cache.BoxOutline.Size = Vector2.new(boxW + 2, boxH + 2)
                            cache.BoxOutline.Filled = false  -- Hollow outline
                            
                            -- Simulate rounded corners by adding small UI elements or suggest using UICorner if available in cacheObject
                            -- If cache has UICorner properties, set cache.BoxSquare.UICorner.CornerRadius = UDim.new(0, 4)
                            -- Similarly for outline if separate.
                        else
                            cache.BoxSquare.Visible = false
                            cache.BoxOutline.Visible = false
                        end

                        if self.Settings.ESP.Features.Tracer.Enabled then
                            cache.TracerLine.Visible = true
                            cache.TracerLine.Color = vis and self.Settings.ESP.Features.Tracer.Color or Color3.fromRGB(255, 0, 0)
                            cache.TracerLine.Transparency = vis and 0.2 or 0.4  -- Faded for elegance
                            cache.TracerLine.Thickness = 1.5  -- Thinner, smoother line
                            cache.TracerLine.From = Vector2.new(viewSize.X / 2, viewSize.Y)
                            cache.TracerLine.To = screenPos
                        else
                            cache.TracerLine.Visible = false
                        end

                        if self.Settings.ESP.Features.Name.Enabled and cachedProperties[p] then
                            cache.NameLabel.Visible = true
                            cache.NameLabel.Text = cachedProperties[p].Name
                            cache.NameLabel.TextColor3 = self.Settings.ESP.Features.Name.Color
                            cache.NameLabel.BackgroundTransparency = 0.5  -- Subtle background for readability
                            cache.NameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
                            cache.NameLabel.Font = Enum.Font.GothamBold  -- Modern, professional font
                            cache.NameLabel.TextSize = math.max(12, math.min(16, scale * 2.5))
                            cache.NameLabel.TextStrokeTransparency = 0.5  -- Softer outline
                            cache.NameLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 20)  -- Slightly adjusted spacing
                            -- If UICorner, add rounded bg
                        else
                            cache.NameLabel.Visible = false
                        end

                        if self.Settings.ESP.Features.DistanceText.Enabled then
                            cache.DistanceLabel.Visible = true
                            cache.DistanceLabel.Text = math.floor(distCam) .. " studs"
                            cache.DistanceLabel.TextColor3 = self.Settings.ESP.Features.DistanceText.Color
                            cache.DistanceLabel.BackgroundTransparency = 1  -- No bg for minimalism
                            cache.DistanceLabel.Font = Enum.Font.Gotham
                            cache.DistanceLabel.TextSize = math.max(14, math.min(18, scale * 2.5))
                            cache.DistanceLabel.TextStrokeTransparency = 0.7
                            cache.DistanceLabel.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 5)
                        else
                            cache.DistanceLabel.Visible = false
                        end

                        if self.Settings.ESP.Features.HeadDot.Enabled and headOn then
                            cache.HeadDot.Visible = true
                            cache.HeadDot.Color = self.Settings.ESP.Features.HeadDot.Color
                            cache.HeadDot.Transparency = 0.1
                            cache.HeadDot.Filled = true
                            cache.HeadDot.Radius = math.max(3, boxH / 15)  -- Slightly larger for visibility
                            cache.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                            cache.HeadDot.NumSides = 32  -- Smoother circle
                            -- Add a subtle outline ring: if cache has HeadDotOutline, set similar with Thickness 1, black
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
