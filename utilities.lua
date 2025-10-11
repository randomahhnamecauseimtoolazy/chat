local Utilities = {}
local Camera = game:GetService("Workspace").CurrentCamera
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

function Utilities:Init(Settings, State)
    self.Settings = Settings
    self.State = State
end

function Utilities:getGunBarrel()
    local furthestPart, maxZ = nil, -math.huge
    for _, model in ipairs(Workspace.Camera:GetChildren()) do
        if model:IsA("Model") and not model.Name:lower():match("arm") then
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > maxZ then
                        maxZ = pos.Z
                        furthestPart = part
                    end
                end
            end
        end
    end
    return furthestPart
end

function Utilities:getPlayers()
    local entityList = {}
    for _, team in ipairs(Workspace.Players:GetChildren()) do
        for _, player in ipairs(team:GetChildren()) do
            if player:IsA("Model") then
                table.insert(entityList, player)
            end
        end
    end
    return entityList
end

function Utilities:isEnemy(player)
    if not player then return false end
    local helmet = player:FindFirstChildWhichIsA("Folder")
    helmet = helmet and helmet:FindFirstChildOfClass("MeshPart")
    if not helmet then return false end
    local color = helmet.BrickColor.Name
    local localTeam = LocalPlayer.Team.Name
    return (color == "Black" and localTeam == "Ghosts") or (color ~= "Black" and localTeam == "Phantoms")
end

function Utilities:cacheObject(object)
    local cache = self.State.Storage.ESPCache
    if cache[object] then return end

    local drawings = {
        BoxSquare = drawing.new("Square"),
        BoxOutline = drawing.new("Square"),
        TracerLine = drawing.new("Line"),
        DistanceLabel = drawing.new("Text"),
        NameLabel = drawing.new("Text"),
        HeadDot = drawing.new("Circle")
    }

    for _, drawing in pairs(drawings) do
        drawing.Visible = false
        drawing.ZIndex = 1
    end

    cache[object] = drawings
end

function Utilities:uncacheObject(object)
    local cache = self.State.Storage.ESPCache
    if cache[object] then
        for _, drawing in pairs(cache[object]) do
            drawing:Remove()
        end
        cache[object] = nil
    end
end

function Utilities:getBodyPart(player, name)
    if not player then return nil end
    for _, part in ipairs(player:GetChildren()) do
        if part:IsA("BasePart") then
            local mesh = part:FindFirstChildOfClass("SpecialMesh")
            if mesh and (
                (name == "Head" and mesh.MeshId == "rbxassetid://6179256256") or
                (name ~= "Head" and mesh.MeshId == "rbxassetid://4049240078")
            ) then
                return part
            end
        end
    end
    return nil
end

function Utilities:isAlly(player)
    if not player then return false end
    local helmet = player:FindFirstChildWhichIsA("Folder")
    helmet = helmet and helmet:FindFirstChildOfClass("MeshPart")
    if not helmet then return false end
    local color = helmet.BrickColor.Name
    return (color == "Black" and LocalPlayer.Team == Teams.Phantoms) or
           (color ~= "Black" and LocalPlayer.Team == Teams.Ghosts)
end

function Utilities:isVisible(part, check)
    if not part or not check then return true end
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
    return hit == part
end

function Utilities:isValidPlayer(player)
    return player and player.Parent and player:IsDescendantOf(Workspace.Players)
end

function Utilities:getCharacter()
    local char
    while not char do
        char = Workspace.Ignore:FindFirstChildWhichIsA("Model")
        task.wait()
    end
    return char
end

return Utilities
