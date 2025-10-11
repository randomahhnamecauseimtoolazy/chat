local Aimbot = {}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

function Aimbot:Init(Settings, State, Utilities)
    self.Settings = Settings
    self.State = State
    self.Utilities = Utilities
    self.Settings.Aimbot.Easing.Sensitivity.Value = self.Settings.Aimbot.Easing.Strength
end

function Aimbot:safeMouseMoveRel(x, y)
    if type(mousemoverel) == "function" then
        pcall(mousemoverel, x, y)
    end
end

function Aimbot:preloadMouse()
    local t = tick()
    if t - self.State.MousePreload.LastTime >= self.State.MousePreload.Interval then
        self:safeMouseMoveRel(0.01, 0.01)
        self.State.MousePreload.LastTime = t
    end
end

function Aimbot:startMousePreload()
    if self.State.MousePreload.Active then return end
    self.State.MousePreload.Active = true
    self.State.MousePreload.Connection = RunService.Heartbeat:Connect(function() self:preloadMouse() end)
end

function Aimbot:stopMousePreload()
    if not self.State.MousePreload.Active then return end
    self.State.MousePreload.Active = false
    if self.State.MousePreload.Connection then
        self.State.MousePreload.Connection:Disconnect()
        self.State.MousePreload.Connection = nil
    end
end

function Aimbot:getClosestPlayer()
    local closest, shortestDistSq = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovEnabled = self.Settings.FOV.Enabled
    local fovRadiusSq = fovEnabled and (self.Settings.FOV.Radius ^ 2) or nil
    local maxDistEnabled = self.Settings.Aimbot.MaxDistance.Enabled
    local maxDistSq = maxDistEnabled and (self.Settings.Aimbot.MaxDistance.Value ^ 2) or nil
    local camPos = Camera.CFrame.Position
    local players = self.Utilities:getPlayers()

    for _, player in ipairs(players) do 
        if not player:IsDescendantOf(workspace.Ignore.DeadBody) then
            local ally = self.Utilities:isAlly(player)
            if not (self.Settings.Chams.TeamCheck and ally) then
                local part = self.Utilities:getBodyPart(player, self.Settings.Aimbot.HitPart)
                if part then
                    local partPos = part.Position
                    local diffToCam = partPos - camPos
                    local distToCamSq = diffToCam:Dot(diffToCam)
                    if not maxDistEnabled or distToCamSq <= maxDistSq then
                        local pos, onScreen = Camera:WorldToViewportPoint(partPos)
                        if onScreen then
                            local screenPos = Vector2.new(pos.X, pos.Y)
                            local deltaToCenter = screenPos - center
                            local distToCenterSq = deltaToCenter:Dot(deltaToCenter)
                            local inFOV = not fovEnabled or distToCenterSq <= fovRadiusSq
                            if inFOV then
                                if distToCamSq <= 900 then  -- 30^2 = 900
                                    return part  -- Early return for close targets
                                end
                                if distToCenterSq < shortestDistSq then
                                    closest = part
                                    shortestDistSq = distToCenterSq
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

function Aimbot:aimAt()
    if not self.Settings.Aimbot.Easing.Strength or not self.State.TargetPart or not self.State.TargetPart:IsDescendantOf(workspace.Players) then return end
    if self.State.IsRightClickHeld then
        if self.Settings.Aimbot.AutoTargetSwitch and not self.State.TargetPart then
            self.State.TargetPart = self:getClosestPlayer()
            if not self.State.TargetPart then
                self.State.IsRightClickHeld = false
                return
            end
        end
        local pos, onScreen = Camera:WorldToViewportPoint(self.State.TargetPart.Position)
        if onScreen then
            local mouse = UserInputService:GetMouseLocation()
            local delta = Vector2.new(pos.X - mouse.X, pos.Y - mouse.Y)
            local distSq = delta:Dot(delta)
            if distSq > 1 then 
                local sens = self.Settings.Aimbot.Easing.Sensitivity.Value
                self:safeMouseMoveRel(delta.X * sens, delta.Y * sens)
            end
        else
            self.State.TargetPart = nil 
        end
    end
end

function Aimbot:updateSensitivity(val)
    local tween = TweenService:Create(self.Settings.Aimbot.Easing.Sensitivity, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Value = val})
    tween:Play()
end

function Aimbot:Cleanup()
    self:stopMousePreload()
    if self.State.InputBeganConnection then self.State.InputBeganConnection:Disconnect() end
    if self.State.InputEndedConnection then self.State.InputEndedConnection:Disconnect() end
    if self.State.RenderSteppedConnection then self.State.RenderSteppedConnection:Disconnect() end
end

return Aimbot
