local Aimbot = {}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Vector2_new = Vector2.new
local math_huge = math.huge

function Aimbot:Init(Settings, State, Utilities)
    self.Settings = Settings
    self.State = State
    self.Utilities = Utilities
    self.Settings.Aimbot.Easing.Sensitivity.Value = self.Settings.Aimbot.Easing.Strength
    self.Center = Vector2_new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
end

function Aimbot:SafeMouseMoveRel(x, y)
    local mousemoverel = mousemoverel
    if mousemoverel then
        pcall(mousemoverel, x, y)
    end
end

function Aimbot:PreloadMouse()
    local t = tick()
    local preload = self.State.MousePreload
    if t - preload.LastTime >= preload.Interval then
        self:SafeMouseMoveRel(0.01, 0.01)
        preload.LastTime = t
    end
end

function Aimbot:StartMousePreload()
    local preload = self.State.MousePreload
    if preload.Active then return end
    preload.Active = true
    preload.Connection = RunService.Heartbeat:Connect(function()
        self:PreloadMouse()
    end)
end

function Aimbot:StopMousePreload()
    local preload = self.State.MousePreload
    if not preload.Active then return end
    preload.Active = false
    if preload.Connection then
        preload.Connection:Disconnect()
        preload.Connection = nil
    end
end

function Aimbot:GetClosestPlayer()
    local closest, shortestDist = nil, math_huge
    local center = self.Center
    local settings = self.Settings
    local fovEnabled = settings.FOV.Enabled
    local fovRadius = settings.FOV.Radius
    local maxDistanceEnabled = settings.Aimbot.MaxDistance.Enabled
    local maxDistance = settings.Aimbot.MaxDistance.Value
    local teamCheck = settings.Chams.TeamCheck
    local hitPart = settings.Aimbot.HitPart
    local utilities = self.Utilities
    local cameraCFrame = Camera.CFrame.Position

    for _, player in ipairs(utilities:getPlayers()) do
        if not player:IsDescendantOf(workspace.Ignore.DeadBody) then
            if not (teamCheck and utilities:isAlly(player)) then
                local part = utilities:getBodyPart(player, hitPart)
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local distToCenter = (Vector2_new(pos.X, pos.Y) - center).Magnitude
                        local distToCam = (part.Position - cameraCFrame).Magnitude
                        if not (maxDistanceEnabled and distToCam > maxDistance) then
                            if distToCam <= 30 then
                                return part
                            end
                            if (not fovEnabled or distToCenter <= fovRadius) and distToCenter < shortestDist then
                                closest = part
                                shortestDist = distToCenter
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

function Aimbot:AimAt()
    local state = self.State
    local settings = self.Settings
    if not settings.Aimbot.Easing.Strength or not state.TargetPart or not state.TargetPart:IsDescendantOf(workspace.Players) then
        return
    end
    if state.IsRightClickHeld then
        if settings.Aimbot.AutoTargetSwitch and not state.TargetPart then
            state.TargetPart = self:GetClosestPlayer()
            if not state.TargetPart then
                state.IsRightClickHeld = false
                return
            end
        end
        local pos, onScreen = Camera:WorldToViewportPoint(state.TargetPart.Position)
        if onScreen then
            local delta = Vector2_new(pos.X, pos.Y) - UserInputService:GetMouseLocation()
            local dist = delta.Magnitude
            if dist > 1 then
                local sensitivity = settings.Aimbot.Easing.Sensitivity.Value
                self:SafeMouseMoveRel(delta.X * sensitivity, delta.Y * sensitivity)
            end
        end
    end
end

function Aimbot:UpdateSensitivity(val)
    TweenService:Create(
        self.Settings.Aimbot.Easing.Sensitivity,
        TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Value = val}
    ):Play()
end

function Aimbot:Cleanup()
    self:StopMousePreload()
    local state = self.State
    if state.InputBeganConnection then state.InputBeganConnection:Disconnect() end
    if state.InputEndedConnection then state.InputEndedConnection:Disconnect() end
    if state.RenderSteppedConnection then state.RenderSteppedConnection:Disconnect() end
end

return Aimbot
