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
    local closest, shortestDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in pairs(self.Utilities:getPlayers()) do
        if not player:IsDescendantOf(workspace.Ignore.DeadBody) then
            local ally = self.Utilities:isAlly(player)
            if not (self.Settings.Chams.TeamCheck and ally) then
                local part = self.Utilities:getBodyPart(player, self.Settings.Aimbot.HitPart)
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local distToCenter = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        local distToCam = (part.Position - Camera.CFrame.Position).Magnitude
                        if not (self.Settings.Aimbot.MaxDistance.Enabled and distToCam > self.Settings.Aimbot.MaxDistance.Value) then
                            if self.Settings.FOV.Enabled then
                                if distToCenter <= self.Settings.FOV.Radius then
                                    if distToCam <= 30 then return part end
                                    if distToCenter < shortestDist then closest = part shortestDist = distToCenter end
                                end
                            else
                                if distToCam <= 30 then return part end
                                if distToCenter < shortestDist then closest = part shortestDist = distToCenter end
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
            if not self.State.TargetPart then self.State.IsRightClickHeld = false return end
        end
        local pos, onScreen = Camera:WorldToViewportPoint(self.State.TargetPart.Position)
        if onScreen then
            local mouse = UserInputService:GetMouseLocation()
            local delta = Vector2.new(pos.X - mouse.X, pos.Y - mouse.Y)
            local dist = delta.Magnitude
            if dist > 1 then self:safeMouseMoveRel(delta.X * self.Settings.Aimbot.Easing.Sensitivity.Value, delta.Y * self.Settings.Aimbot.Easing.Sensitivity.Value) end
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
