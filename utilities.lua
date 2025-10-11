local Utilities = {}
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

function Utilities:Init(Settings, State)
    self.Settings = Settings
    self.State = State

    -- Setup ESP container
    if not CoreGui:FindFirstChild("ESP_UI") then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "ESP_UI"
        screenGui.IgnoreGuiInset = true
        screenGui.ResetOnSpawn = false
        screenGui.Parent = CoreGui
        self.ESP_UI = screenGui
    else
        self.ESP_UI = CoreGui:FindFirstChild("ESP_UI")
    end
end

-- Detects the gun barrel part from the viewmodel
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

-- Gets all entities in the Workspace.Players
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

-- Determines if a model is an enemy
function Utilities:isEnemy(player)
    if not player then return false end
    local helmet = player:FindFirstChildWhichIsA("Folder")
    helmet = helmet and helmet:FindFirstChildOfClass("MeshPart")
    if not helmet then return false end
    local color = helmet.BrickColor.Name
    local localTeam = LocalPlayer.Team and LocalPlayer.Team.Name
    return (color == "Black" and localTeam == "Ghosts") or (color ~= "Black" and localTeam == "Phantoms")
end

-- Caches ESP objects (uses Roblox UIs now)
function Utilities:cacheObject(object)
    local cache = self.State.Storage.ESPCache
    if cache[object] then return end

    local uiObjects = {}

    -- Box Frame
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundColor3 = Color3.new(1, 0, 0)
    box.BorderSizePixel = 1
    box.Size = UDim2.new(0, 50, 0, 100)
    box.Visible = false
    box.Parent = self.ESP_UI
    uiObjects.Box = box

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.AnchorPoint = Vector2.new(0.5, 1)
    nameLabel.Visible = false
    nameLabel.Parent = self.ESP_UI
    uiObjects.NameLabel = nameLabel

    -- Distance Label
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    distanceLabel.TextSize = 12
    distanceLabel.Font = Enum.Font.SourceSans
    distanceLabel.AnchorPoint = Vector2.new(0.5, 0)
    distanceLabel.Visible = false
    distanceLabel.Parent = self.ESP_UI
    uiObjects.DistanceLabel = distanceLabel

    -- Head Dot (BillboardGui)
    local headGui = Instance.new("BillboardGui")
    headGui.Name = "HeadDot"
    headGui.Size = UDim2.new(0, 6, 0, 6)
    headGui.AlwaysOnTop = true
    headGui.Enabled = false
    local headDot = Instance.new("Frame", headGui)
    headDot.Size = UDim2.new(1, 0, 1, 0)
    headDot.BackgroundColor3 = Color3.new(1, 0, 0)
    headDot.BorderSizePixel = 0
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    uiObjects.HeadGui = headGui

    cache[object] = uiObjects
end

function Utilities:uncacheObject(object)
    local cache = self.State.Storage.ESPCache
    if cache[object] then
        for _, ui in pairs(cache[object]) do
            ui:Destroy()
        end
        cache[object] = nil
    end
end

-- Helper for body parts
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
