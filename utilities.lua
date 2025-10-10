local Utilities = {}
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

function Utilities:Init(Settings, State)
    self.Settings = Settings
    self.State = State
end

function Utilities:getGunBarrel()
    local furthestPart, maxZ = nil, -math.huge
    for _, model in pairs(workspace.Camera:GetChildren()) do
        if model:IsA("Model") and not model.Name:lower():find("arm") then
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > maxZ then maxZ = pos.Z furthestPart = part end
                end
            end
        end
    end
    return furthestPart
end

function Utilities:getPlayers()
    local entityList = {}
    for _, team in pairs(workspace.Players:GetChildren()) do
        for _, player in pairs(team:GetChildren()) do
            if player:IsA("Model") then table.insert(entityList, player) end
        end
    end
    return entityList
end

function Utilities:isEnemy(player)
    local localTeam = Players.LocalPlayer.Team.Name
    local helmet = player:FindFirstChildWhichIsA("Folder") and player:FindFirstChildWhichIsA("Folder"):FindFirstChildOfClass("MeshPart")
    if not helmet then return false end
    local color = helmet.BrickColor.Name
    return (color == "Black" and localTeam == "Ghosts") or (color ~= "Black" and localTeam == "Phantoms")
end

function Utilities:cacheObject(object)
    local cache = self.State.Storage.ESPCache
    if cache[object] then return end 

    local drawings = {
        BoxSquare = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        TracerLine = Drawing.new("Line"),
        DistanceLabel = Drawing.new("Text"),
        NameLabel = Drawing.new("Text"),
        HeadDot = Drawing.new("Circle")
    }

    for _, d in pairs(drawings) do
        d.Visible = false
        d.ZIndex = 1
    end

    cache[object] = drawings
end

function Utilities:uncacheObject(object)
    if self.State.Storage.ESPCache[object] then
        for _, e in pairs(self.State.Storage.ESPCache[object]) do e:Remove() end
        self.State.Storage.ESPCache[object] = nil
    end
end

function Utilities:getBodyPart(player, name)
    for _, part in pairs(player:GetChildren()) do
        if part:IsA("BasePart") then
            local mesh = part:FindFirstChildOfClass("SpecialMesh")
            if mesh and ((name == "Head" and mesh.MeshId == "rbxassetid://6179256256") or (name ~= "Head" and mesh.MeshId == "rbxassetid://4049240078")) then
                return part
            end
        end
    end
    return nil
end

function Utilities:isAlly(player)
    local helmet = player:FindFirstChildWhichIsA("Folder") and player:FindFirstChildWhichIsA("Folder"):FindFirstChildOfClass("MeshPart")
    if not helmet then return false end
    return helmet.BrickColor.Name == "Black" and Players.LocalPlayer.Team == Teams.Phantoms or helmet.BrickColor.Name ~= "Black" and Players.LocalPlayer.Team == Teams.Ghosts
end

function Utilities:isVisible(part, check)
    if check then
        local hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000), {Players.LocalPlayer.Character}, false, true)
        return hit == part
    end
    return true
end

function Utilities:isValidPlayer(player)
    return player and player.Parent and player:IsDescendantOf(workspace.Players)
end

function Utilities:getCharacter()
    local char
    while not char do char = workspace.Ignore:FindFirstChildWhichIsA("Model") task.wait() end
    return char
end

return Utilities
