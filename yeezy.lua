-- UI Library
local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Redacted = {
    Username = OverrideUserSettings and 'admin' or 'user1',
    Build = OverrideUserSettings and 'developer' or 'live',

    Accent = Color3.fromRGB(140, 130, 255),
}

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
    Registry = {},
    RegistryMap = {},

    HudRegistry = {},

    AccentColor = Redacted.Accent,
    FontColor = Color3.fromRGB(255, 255, 255),
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Code,

    OpenedFrames = {},
    DependencyBoxes = {},

    Signals = {},
    ScreenGui = ScreenGui,
}

local RainbowStep = 0
local Hue = 0

table.insert(
    Library.Signals,
    RenderStepped:Connect(function(Delta)
        RainbowStep = RainbowStep + Delta

        if RainbowStep >= (1 / 60) then
            RainbowStep = 0

            Hue = Hue + (1 / 400)

            if Hue > 1 then
                Hue = 0
            end

            Library.CurrentRainbowHue = Hue
            Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
        end
    end)
)

local function GetPlayersString()
    local PlayerList = Players:GetPlayers()

    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name
    end

    table.sort(PlayerList, function(str1, str2)
        return str1 < str2
    end)

    return PlayerList
end

local function GetTeamsString()
    local TeamList = Teams:GetTeams()

    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name
    end

    table.sort(TeamList, function(str1, str2)
        return str1 < str2
    end)

    return TeamList
end

function Library:SafeCallback(f, ...)
    if not f then
        return
    end

    if not Library.NotifyOnError then
        return f(...)
    end

    local success, event = pcall(f, ...)

    if not success then
        local _, i = event:find(':%d+: ')

        if not i then
            return Library:Notify(event)
        end

        return Library:Notify(event:sub(i + 1), 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save()
    end
end

function Library:Create(Class, Properties)
    local success, _Instance = pcall(function()
        local instance
        if type(Class) == 'string' then
            instance = Instance.new(Class)
        else
            instance = Class
        end

        for Property, Value in next, Properties do
            pcall(function()
                instance[Property] = Value
            end)
        end

        return instance
    end)

    if success and _Instance then
        return _Instance
    else
        -- Fallback: create in a safe context
        return task.spawn(function()
            local instance
            if type(Class) == 'string' then
                instance = Instance.new(Class)
            else
                instance = Class
            end

            for Property, Value in next, Properties do
                pcall(function()
                    instance[Property] = Value
                end)
            end

            return instance
        end)
    end
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = Inst,
    })
end

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 16,
        TextStrokeTransparency = 0,
    })

    Library:ApplyTextStroke(_Instance)

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor',
    }, IsHud)

    return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            )

            if ObjPos.Y > (Cutoff or 40) then
                return
            end

            while
                InputService:IsMouseButtonPressed(
                    Enum.UserInputType.MouseButton1
                )
            do
                Instance.Position = UDim2.new(
                    0,
                    Mouse.X
                        - ObjPos.X
                        + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0,
                    Mouse.Y
                        - ObjPos.Y
                        + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                )

                RenderStepped:Wait()
            end
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14)
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y),
        TextSize = 14,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip,
    })

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    })

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(
    HighlightInstance,
    Instance,
    Properties,
    PropertiesDefault
)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize

        if
            Mouse.X >= AbsPos.X
            and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y
            and Mouse.Y <= AbsPos.Y + AbsSize.Y
        then
            return true
        end
    end
end

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize

    if
        Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
    then
        return true
    end
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB
        + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(
        Text,
        Size,
        Font,
        Resolution or Vector2.new(1920, 1080)
    )
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1
    local Data = {
        Instance = Instance,
        Properties = Properties,
        Idx = Idx,
    }

    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data

    if IsHud then
        table.insert(Library.HudRegistry, Data)
    end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx)
            end
        end

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx)
            end
        end

        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an 'active' list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the 'Visible' propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:GiveSignal(Signal)
    -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    -- Unload all of the signals
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

    -- Call our unload callback, maybe to undo some hooks etc
    if Library.OnUnload then
        Library.OnUnload()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance)
    end
end))

local BaseAddons = {}

do
    local Funcs = {}

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel
        -- local Container = self.Container;

        assert(Info.Default, 'AddColorPicker: Missing default value.')

        local ColorPicker = {
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Type = 'ColorPicker',
            Title = type(Info.Title) == 'string' and Info.Title
                or 'Color picker',
            Callback = Info.Callback or function(Color) end,
        }

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)

            ColorPicker.Hue = H
            ColorPicker.Sat = S
            ColorPicker.Vib = V
        end

        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 28, 0, 14),
            ZIndex = 6,
            Parent = ToggleLabel,
        })

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0,
            Size = UDim2.new(0, 27, 0, 13),
            ZIndex = 5,
            Image = 'http://www.roblox.com/asset/?id=12977615774',
            Visible = Info.Transparency,
            Parent = DisplayFrame,
        })

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color',
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(
                DisplayFrame.AbsolutePosition.X,
                DisplayFrame.AbsolutePosition.Y + 18
            ),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
            Visible = false,
            ZIndex = 15,
            Parent = ScreenGui,
        })

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition')
            :Connect(function()
                PickerFrameOuter.Position = UDim2.fromOffset(
                    DisplayFrame.AbsolutePosition.X,
                    DisplayFrame.AbsolutePosition.Y + 18
                )
            end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 16,
            Parent = PickerFrameOuter,
        })

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 4, 0, 25),
            Size = UDim2.new(0, 200, 0, 200),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = SatVibMapOuter,
        })

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Image = 'rbxassetid://4155801252',
            Parent = SatVibMapInner,
        })

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ImageColor3 = Color3.new(0, 0, 0),
            ZIndex = 19,
            Parent = SatVibMap,
        })

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(
                0,
                CursorOuter.Size.X.Offset - 2,
                0,
                CursorOuter.Size.Y.Offset - 2
            ),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ZIndex = 20,
            Parent = CursorOuter,
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 208, 0, 25),
            Size = UDim2.new(0, 15, 0, 200),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = HueSelectorOuter,
        })

        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0, 0.5),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 18,
            Parent = HueSelectorInner,
        })

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner,
        })

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = HueBoxOuter,
        })

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = HueBoxInner,
        })

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            Font = Library.Font,
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor,
            TextSize = 14,
            TextStrokeTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 20,
            Parent = HueBoxInner,
        })

        Library:ApplyTextStroke(HueBox)

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner,
        })

        local RgbBox =
            Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
                Text = '255, 255, 255',
                PlaceholderText = 'RGB color',
                TextColor3 = Library.FontColor,
            })

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor

        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0),
                Position = UDim2.fromOffset(4, 251),
                Size = UDim2.new(1, -8, 0, 15),
                ZIndex = 19,
                Parent = PickerFrameInner,
            })

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 19,
                Parent = TransparencyBoxOuter,
            })

            Library:AddToRegistry(
                TransparencyBoxInner,
                { BorderColor3 = 'OutlineColor' }
            )

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Image = 'http://www.roblox.com/asset/?id=12978095818',
                ZIndex = 20,
                Parent = TransparencyBoxInner,
            })

            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                AnchorPoint = Vector2.new(0.5, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 21,
                Parent = TransparencyBoxInner,
            })
        end

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.fromOffset(5, 5),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 14,
            Text = ColorPicker.Title, --Info.Default;
            TextWrapped = false,
            ZIndex = 16,
            Parent = PickerFrameInner,
        })

        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui,
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 15,
                Parent = ContextMenu.Container,
            })

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = ContextMenu.Inner,
            })

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            })

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (
                        DisplayFrame.AbsolutePosition.X
                        + DisplayFrame.AbsoluteSize.X
                    ) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition')
                :Connect(updateMenuPosition)
            ContextMenu.Inner.Layout
                :GetPropertyChangedSignal('AbsoluteContentSize')
                :Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, 0, 0, 15),
                    TextSize = 13,
                    Text = Str,
                    ZIndex = 16,
                    Parent = self.Inner,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                Library:OnHighlight(
                    Button,
                    Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                )

                Button.InputBegan:Connect(function(Input)
                    if
                        Input.UserInputType ~= Enum.UserInputType.MouseButton1
                    then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)

            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(
                    setclipboard,
                    table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ', ')
                )
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)
        end

        Library:AddToRegistry(PickerFrameInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' })
        Library:AddToRegistry(SatVibMapInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })

        Library:AddToRegistry(
            HueBoxInner,
            { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' }
        )
        Library:AddToRegistry(
            RgbBoxBase.Frame,
            { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' }
        )
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor' })
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor' })

        local SequenceTable = {}

        for Hue = 0, 1, 0.1 do
            table.insert(
                SequenceTable,
                ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1))
            )
        end

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable),
            Rotation = 90,
            Parent = HueSelectorInner,
        })

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib =
                        Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib =
                        Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(
                ColorPicker.Hue,
                ColorPicker.Sat,
                ColorPicker.Vib
            )
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value,
                BackgroundTransparency = ColorPicker.Transparency,
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            })

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position =
                    UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end

            CursorOuter.Position =
                UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ', ')

            Library:SafeCallback(
                ColorPicker.Callback,
                ColorPicker.Value,
                ColorPicker.Transparency
            )
            Library:SafeCallback(
                ColorPicker.Changed,
                ColorPicker.Value,
                ColorPicker.Transparency
            )
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
            Func(ColorPicker.Value)
        end

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end

            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
        end

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while
                    InputService:IsMouseButtonPressed(
                        Enum.UserInputType.MouseButton1
                    )
                do
                    local MinX = SatVibMap.AbsolutePosition.X
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX)

                    local MinY = SatVibMap.AbsolutePosition.Y
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()

                    RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while
                    InputService:IsMouseButtonPressed(
                        Enum.UserInputType.MouseButton1
                    )
                do
                    local MinY = HueSelectorInner.AbsolutePosition.Y
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()

                    RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        DisplayFrame.InputBegan:Connect(function(Input)
            if
                Input.UserInputType == Enum.UserInputType.MouseButton1
                and not Library:MouseIsOverOpenedFrame()
            then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end
            elseif
                Input.UserInputType == Enum.UserInputType.MouseButton2
                and not Library:MouseIsOverOpenedFrame()
            then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end)

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while
                        InputService:IsMouseButtonPressed(
                            Enum.UserInputType.MouseButton1
                        )
                    do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX)

                        ColorPicker.Transparency = 1
                            - ((MouseX - MinX) / (MaxX - MinX))

                        ColorPicker:Display()

                        RenderStepped:Wait()
                    end

                    Library:AttemptSave()
                end
            end)
        end

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize =
                    PickerFrameOuter.AbsolutePosition,
                    PickerFrameOuter.AbsoluteSize

                if
                    Mouse.X < AbsPos.X
                    or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1)
                    or Mouse.Y > AbsPos.Y + AbsSize.Y
                then
                    ColorPicker:Hide()
                end

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end

            if
                Input.UserInputType == Enum.UserInputType.MouseButton2
                and ContextMenu.Container.Visible
            then
                if
                    not Library:IsMouseOverFrame(ContextMenu.Container)
                    and not Library:IsMouseOverFrame(DisplayFrame)
                then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker

        return self
    end

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        local Container = self.Container

        assert(Info.Default, 'AddKeyPicker: Missing default value.')

        local KeyPicker = {
            Value = Info.Default,
            Toggled = false,
            Mode = Info.Mode or 'Toggle', -- Always, Toggle, Hold
            Type = 'KeyPicker',
            Callback = Info.Callback or function(Value) end,
            ChangedCallback = Info.ChangedCallback or function(New) end,

            SyncToggleState = Info.SyncToggleState or false,
        }

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 28, 0, 15),
            ZIndex = 6,
            Parent = ToggleLabel,
        })

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7,
            Parent = PickOuter,
        })

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 13,
            Text = Info.Default,
            TextWrapped = true,
            ZIndex = 8,
            Parent = PickInner,
        })

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(
                ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4,
                ToggleLabel.AbsolutePosition.Y + 1
            ),
            Size = UDim2.new(0, 60, 0, 45 + 2),
            Visible = false,
            ZIndex = 14,
            Parent = ScreenGui,
        })

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition')
            :Connect(function()
                ModeSelectOuter.Position = UDim2.fromOffset(
                    ToggleLabel.AbsolutePosition.X
                        + ToggleLabel.AbsoluteSize.X
                        + 4,
                    ToggleLabel.AbsolutePosition.Y + 1
                )
            end)

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 15,
            Parent = ModeSelectOuter,
        })

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ModeSelectInner,
        })

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 18),
            TextSize = 13,
            Visible = false,
            ZIndex = 110,
            Parent = Library.KeybindContainer,
        }, true)

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' }
        local ModeButtons = {}

        for Idx, Mode in next, Modes do
            local ModeButton = {}

            local Label = Library:CreateLabel({
                Active = false,
                Size = UDim2.new(1, 0, 0, 15),
                TextSize = 13,
                Text = Mode,
                ZIndex = 16,
                Parent = ModeSelectInner,
            })

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Label.TextColor3 = Library.AccentColor
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor'

                ModeSelectOuter.Visible = false
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor'
            end

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select()
                    Library:AttemptSave()
                end
            end)

            if Mode == KeyPicker.Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Update()
            if Info.NoUI then
                return
            end

            local State = KeyPicker:GetState()

            ContainerLabel.Text = string.format(
                '[%s] %s (%s)',
                KeyPicker.Value,
                Info.Text,
                KeyPicker.Mode
            )

            ContainerLabel.Visible = true
            ContainerLabel.TextColor3 = State and Library.AccentColor
                or Library.FontColor

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State
                    and 'AccentColor'
                or 'FontColor'

            local YSize = 0
            local XSize = 0

            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 18
                    if Label.TextBounds.X > XSize then
                        XSize = Label.TextBounds.X
                    end
                end
            end

            Library.KeybindFrame.Size =
                UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false
                end

                local Key = KeyPicker.Value

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1'
                            and InputService:IsMouseButtonPressed(
                                Enum.UserInputType.MouseButton1
                            )
                        or Key == 'MB2'
                            and InputService:IsMouseButtonPressed(
                                Enum.UserInputType.MouseButton2
                            )
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2]
            DisplayLabel.Text = Key
            KeyPicker.Value = Key
            ModeButtons[Mode]:Select()
            KeyPicker:Update()
        end

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false

        PickOuter.InputBegan:Connect(function(Input)
            if
                Input.UserInputType == Enum.UserInputType.MouseButton1
                and not Library:MouseIsOverOpenedFrame()
            then
                Picking = true

                DisplayLabel.Text = ''

                local Break
                local Text = ''

                task.spawn(function()
                    while not Break do
                        if Text == '...' then
                            Text = ''
                        end

                        Text = Text .. '.'
                        DisplayLabel.Text = Text

                        wait(0.4)
                    end
                end)

                wait(0.2)

                local Event
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name
                    elseif
                        Input.UserInputType == Enum.UserInputType.MouseButton1
                    then
                        Key = 'MB1'
                    elseif
                        Input.UserInputType == Enum.UserInputType.MouseButton2
                    then
                        Key = 'MB2'
                    end

                    Break = true
                    Picking = false

                    DisplayLabel.Text = Key
                    KeyPicker.Value = Key

                    Library:SafeCallback(
                        KeyPicker.ChangedCallback,
                        Input.KeyCode or Input.UserInputType
                    )
                    Library:SafeCallback(
                        KeyPicker.Changed,
                        Input.KeyCode or Input.UserInputType
                    )

                    Library:AttemptSave()

                    Event:Disconnect()
                end)
            elseif
                Input.UserInputType == Enum.UserInputType.MouseButton2
                and not Library:MouseIsOverOpenedFrame()
            then
                ModeSelectOuter.Visible = true
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Picking then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value

                    if Key == 'MB1' or Key == 'MB2' then
                        if
                            Key == 'MB1'
                                and Input.UserInputType == Enum.UserInputType.MouseButton1
                            or Key == 'MB2'
                                and Input.UserInputType == Enum.UserInputType.MouseButton2
                        then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    elseif
                        Input.UserInputType == Enum.UserInputType.Keyboard
                    then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    end
                end

                KeyPicker:Update()
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize =
                    ModeSelectOuter.AbsolutePosition,
                    ModeSelectOuter.AbsoluteSize

                if
                    Mouse.X < AbsPos.X
                    or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1)
                    or Mouse.Y > AbsPos.Y + AbsSize.Y
                then
                    ModeSelectOuter.Visible = false
                end
            end
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if not Picking then
                KeyPicker:Update()
            end
        end))

        KeyPicker:Update()

        Options[Idx] = KeyPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}

do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        local Groupbox = self
        local Container = Groupbox.Container

        Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Size),
            ZIndex = 1,
            Parent = Container,
        })
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {}

        local Groupbox = self
        local Container = Groupbox.Container

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = 14,
            Text = Text,
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })

        if DoesWrap then
            local Y = select(
                2,
                Library:GetTextBounds(
                    Text,
                    Library.Font,
                    14,
                    Vector2.new(TextLabel.AbsoluteSize.X, math.huge)
                )
            )
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextLabel,
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(
                    2,
                    Library:GetTextBounds(
                        Text,
                        Library.Font,
                        14,
                        Vector2.new(TextLabel.AbsoluteSize.X, math.huge)
                    )
                )
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize()
        end

        if not DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        return Label
    end

    function Funcs:AddButton(...)
        -- TODO: Eventually redo this
        local Button = {}
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(
                type(Obj.Func) == 'function',
                'AddButton: `Func` callback is missing.'
            )
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self
        local Container = Groupbox.Container

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -4, 0, 20),
                ZIndex = 5,
            })

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = Outer,
            })

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = 14,
                Text = Button.Text,
                ZIndex = 6,
                Parent = Inner,
            })

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
                }),
                Rotation = 90,
                Parent = Inner,
            })

            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black',
            })

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor',
                BorderColor3 = 'OutlineColor',
            })

            Library:OnHighlight(
                Outer,
                Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            )

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)
                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then
                    return
                end
                if Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(
                        Button.Label,
                        { TextColor3 = 'AccentColor' }
                    )

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(
                        Button.Outer.InputBegan,
                        0.5,
                        ValidateClick
                    )

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(
                        Button.Label,
                        { TextColor3 = 'FontColor' }
                    )

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label =
                CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(
                self.Outer.AbsoluteSize.X - 2,
                self.Outer.AbsoluteSize.Y
            )
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        return Button
    end

    function Funcs:AddDivider()
        local Groupbox = self
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2)
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 5),
            ZIndex = 5,
            Parent = Container,
        })

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DividerOuter,
        })

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black',
        })

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })

        Groupbox:AddBlank(9)
        Groupbox:Resize()
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '',
            Numeric = Info.Numeric or false,
            Finished = Info.Finished or false,
            Type = 'Input',
            Callback = Info.Callback or function(Value) end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15),
            TextSize = 14,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })

        Groupbox:AddBlank(1)

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = TextBoxOuter,
        })

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })

        Library:OnHighlight(
            TextBoxOuter,
            TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = TextBoxInner,
        })

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1,
            ClipsDescendants = true,

            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),

            ZIndex = 7,
            Parent = TextBoxInner,
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1,

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font,
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
            PlaceholderText = Info.Placeholder or '',

            Text = Info.Default or '',
            TextColor3 = Library.FontColor,
            TextSize = 14,
            TextStrokeTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Left,

            ZIndex = 7,
            Parent = Container,
        })

        Library:ApplyTextStroke(Box)

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text
            Box.Text = Text

            Library:SafeCallback(Textbox.Callback, Textbox.Value)
            Library:SafeCallback(Textbox.Changed, Textbox.Value)
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then
                    return
                end

                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if
                not Box:IsFocused()
                or Box.TextBounds.X <= reveal - 2 * PADDING
            then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor - 1)
                    local width = TextService:GetTextSize(
                        subtext,
                        Box.TextSize,
                        Box.Font,
                        Vector2.new(math.huge, math.huge)
                    ).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING - width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position =
                            UDim2.fromOffset(reveal - width - PADDING - 1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor',
        })

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func
            Func(Textbox.Value)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        Options[Idx] = Textbox

        return Textbox
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false,
            Type = 'Toggle',

            Callback = Info.Callback or function(Value) end,
            Addons = {},
            Risky = Info.Risky,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 13, 0, 13),
            ZIndex = 5,
            Parent = Container,
        })

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black',
        })

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = ToggleOuter,
        })

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0),
            Position = UDim2.new(1, 6, 0, 0),
            TextSize = 14,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
            Parent = ToggleInner,
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ToggleLabel,
        })

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 170, 1, 0),
            ZIndex = 8,
            Parent = ToggleOuter,
        })

        Library:OnHighlight(
            ToggleRegion,
            ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor
                or Library.MainColor
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark
                or Library.OutlineColor

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value
                    and 'AccentColor'
                or 'MainColor'
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value
                    and 'AccentColorDark'
                or 'OutlineColor'
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
            Func(Toggle.Value)
        end

        function Toggle:SetValue(Bool)
            Bool = not not Bool

            Toggle.Value = Bool
            Toggle:Display()

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        ToggleRegion.InputBegan:Connect(function(Input)
            if
                Input.UserInputType == Enum.UserInputType.MouseButton1
                and not Library:MouseIsOverOpenedFrame()
            then
                Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
                Library:AttemptSave()
            end
        end)

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display()
        Groupbox:AddBlank(Info.BlankSize or 5 + 2)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggles[Idx] = Toggle

        Library:UpdateDependencyBoxes()

        return Toggle
    end

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.')
        assert(Info.Text, 'AddSlider: Missing slider text.')
        assert(Info.Min, 'AddSlider: Missing minimum value.')
        assert(Info.Max, 'AddSlider: Missing maximum value.')
        assert(Info.Rounding, 'AddSlider: Missing rounding value.')

        local Slider = {
            Value = Info.Default,
            Min = Info.Min,
            Max = Info.Max,
            Rounding = Info.Rounding,
            MaxSize = 232,
            Type = 'Slider',
            Callback = Info.Callback or function(Value) end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = 14,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })

            Groupbox:AddBlank(3)
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 13),
            ZIndex = 5,
            Parent = Container,
        })

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black',
        })

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = SliderOuter,
        })

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderColor3 = Library.AccentColorDark,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 7,
            Parent = SliderInner,
        })

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor',
            BorderColor3 = 'AccentColorDark',
        })

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 8,
            Parent = Fill,
        })

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor',
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 14,
            Text = 'Infinite',
            ZIndex = 9,
            Parent = SliderInner,
        })

        Library:OnHighlight(
            SliderOuter,
            SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor
            Fill.BorderColor3 = Library.AccentColorDark
        end

        function Slider:Display()
            local Suffix = Info.Suffix or ''

            if Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format(
                    '%s/%s',
                    Slider.Value .. Suffix,
                    Slider.Max .. Suffix
                )
            end

            local X = math.ceil(
                Library:MapValue(
                    Slider.Value,
                    Slider.Min,
                    Slider.Max,
                    0,
                    Slider.MaxSize
                )
            )
            Fill.Size = UDim2.new(0, X, 1, 0)

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
            Func(Slider.Value)
        end

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value)
            end

            return tonumber(
                string.format('%.' .. Slider.Rounding .. 'f', Value)
            )
        end

        function Slider:GetValueFromXOffset(X)
            return Round(
                Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max)
            )
        end

        function Slider:SetValue(Str)
            local Num = tonumber(Str)

            if not Num then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        SliderInner.InputBegan:Connect(function(Input)
            if
                Input.UserInputType == Enum.UserInputType.MouseButton1
                and not Library:MouseIsOverOpenedFrame()
            then
                local mPos = Mouse.X
                local gPos = Fill.Size.X.Offset
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos)

                while
                    InputService:IsMouseButtonPressed(
                        Enum.UserInputType.MouseButton1
                    )
                do
                    local nMPos = Mouse.X
                    local nX = math.clamp(
                        gPos + (nMPos - mPos) + Diff,
                        0,
                        Slider.MaxSize
                    )

                    local nValue = Slider:GetValueFromXOffset(nX)
                    local OldValue = Slider.Value
                    Slider.Value = nValue

                    Slider:Display()

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        Library:SafeCallback(Slider.Changed, Slider.Value)
                    end

                    RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        Slider:Display()
        Groupbox:AddBlank(Info.BlankSize or 6)
        Groupbox:Resize()

        Options[Idx] = Slider

        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString()
            Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString()
            Info.AllowNull = true
        end

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.')
        assert(
            Info.AllowNull or Info.Default,
            'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.'
        )

        if not Info.Text then
            Info.Compact = true
        end

        local Dropdown = {
            Values = Info.Values,
            Value = Info.Multi and {},
            Multi = Info.Multi,
            Type = 'Dropdown',
            SpecialType = Info.SpecialType, -- can be either 'Player' or 'Team'
            Callback = Info.Callback or function(Value) end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local RelativeOffset = 0

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = 14,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })

            Groupbox:AddBlank(3)
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset
            end
        end

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black',
        })

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DropdownOuter,
        })

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = DropdownInner,
        })

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            Image = 'http://www.roblox.com/asset/?id=6282522798',
            ZIndex = 8,
            Parent = DropdownInner,
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            TextSize = 14,
            Text = '--',
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 7,
            Parent = DropdownInner,
        })

        Library:OnHighlight(
            DropdownOuter,
            DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            ZIndex = 20,
            Visible = false,
            Parent = ScreenGui,
        })

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(
                DropdownOuter.AbsolutePosition.X,
                DropdownOuter.AbsolutePosition.Y
                    + DropdownOuter.Size.Y.Offset
                    + 1
            )
        end

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(
                DropdownOuter.AbsoluteSize.X,
                YSize or (MAX_DROPDOWN_ITEMS * 20 + 2)
            )
        end

        RecalculateListPosition()
        RecalculateListSize()

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition')
            :Connect(RecalculateListPosition)

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = ListOuter,
        })

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = ListInner,

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        })

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor',
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Scrolling,
        })

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ''

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', '
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value or ''
            end

            ItemList.Text = (Str == '' and '--' or Str)
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value)
                end

                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy()
                end
            end

            local Count = 0

            for Idx, Value in next, Values do
                local Table = {}

                Count = Count + 1

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Middle,
                    Size = UDim2.new(1, -1, 0, 20),
                    ZIndex = 23,
                    Active = true,
                    Parent = Scrolling,
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor',
                    BorderColor3 = 'OutlineColor',
                })

                local ButtonLabel = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, -6, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextSize = 14,
                    Text = Value,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 25,
                    Parent = Button,
                })

                Library:OnHighlight(
                    Button,
                    Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                )

                local Selected

                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor
                        or Library.FontColor
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected
                            and 'AccentColor'
                        or 'FontColor'
                end

                ButtonLabel.InputBegan:Connect(function(Input)
                    if
                        Input.UserInputType == Enum.UserInputType.MouseButton1
                    then
                        local Try = not Selected

                        if
                            Dropdown:GetActiveValues() == 1
                            and not Try
                            and not Info.AllowNull
                        then
                        else
                            if Info.Multi then
                                Selected = Try

                                if Selected then
                                    Dropdown.Value[Value] = true
                                else
                                    Dropdown.Value[Value] = nil
                                end
                            else
                                Selected = Try

                                if Selected then
                                    Dropdown.Value = Value
                                else
                                    Dropdown.Value = nil
                                end

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton()
                                end
                            end

                            Table:UpdateButton()
                            Dropdown:Display()

                            Library:SafeCallback(
                                Dropdown.Callback,
                                Dropdown.Value
                            )
                            Library:SafeCallback(
                                Dropdown.Changed,
                                Dropdown.Value
                            )

                            Library:AttemptSave()
                        end
                    end
                end)

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1
            RecalculateListSize(Y)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            DropdownArrow.Rotation = 180
        end

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            DropdownArrow.Rotation = 0
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
            Func(Dropdown.Value)
        end

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {}

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end
                end

                Dropdown.Value = nTable
            else
                if not Val then
                    Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val
                end
            end

            Dropdown:BuildDropdownList()

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if
                Input.UserInputType == Enum.UserInputType.MouseButton1
                and not Library:MouseIsOverOpenedFrame()
            then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown()
                else
                    Dropdown:OpenDropdown()
                end
            end
        end)

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize =
                    ListOuter.AbsolutePosition, ListOuter.AbsoluteSize

                if
                    Mouse.X < AbsPos.X
                    or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1)
                    or Mouse.Y > AbsPos.Y + AbsSize.Y
                then
                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif
            type(Info.Default) == 'number'
            and Dropdown.Values[Info.Default] ~= nil
        then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if not Info.Multi then
                    break
                end
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        Groupbox:AddBlank(Info.BlankSize or 5)
        Groupbox:Resize()

        Options[Idx] = Dropdown

        return Dropdown
    end

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {},
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Container,
        })

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = true,
            Parent = Holder,
        })

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Frame,
        })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end

        Layout:GetPropertyChangedSignal('AbsoluteContentSize')
            :Connect(function()
                Depbox:Resize()
            end)

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize()
        end)

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end

            Holder.Visible = true
            Depbox:Resize()
        end

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(
                    type(Dependency) == 'table',
                    'SetupDependencies: Dependency is not of type `table`.'
                )
                assert(
                    Dependency[1],
                    'SetupDependencies: Dependency is missing element argument.'
                )
                assert(
                    Dependency[2] ~= nil,
                    'SetupDependencies: Dependency is missing value argument.'
                )
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        Depbox.Container = Frame

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 300, 0, 200),
        ZIndex = 100,
        Parent = ScreenGui,
    })

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.NotificationArea,
    })

    local WatermarkOuter = Library:Create('Frame', {
    AnchorPoint = Vector2.new(1, 1),
    BorderColor3 = Color3.new(0, 0, 0),
    Position = UDim2.new(1, -1, 1, -1),
    Size = UDim2.new(0, 213, 0, 20),
    ZIndex = 200,
    Visible = false,
    Parent = ScreenGui,
})

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 201,
        Parent = WatermarkOuter,
    })

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor',
    })

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 202,
        Parent = WatermarkInner,
    })

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Library:GetDarkerColor(Library.MainColor)
            ),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }),
        Rotation = -90,
        Parent = InnerFrame,
    })

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(
                    0,
                    Library:GetDarkerColor(Library.MainColor)
                ),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            })
        end,
    })

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = InnerFrame,
    })

    Library.Watermark = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)

    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5),
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 210, 0, 20),
        Visible = false,
        ZIndex = 100,
        Parent = ScreenGui,
    })

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = KeybindOuter,
    })

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    }, true)

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102,
        Parent = KeybindInner,
    })

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor',
    }, true)

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds',
        ZIndex = 104,
        Parent = KeybindInner,
    })

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        ZIndex = 1,
        Parent = KeybindInner,
    })

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = KeybindContainer,
    })

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool
end

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14)
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14)

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 100, 0, 10),
        Size = UDim2.new(0, 0, 0, YSize),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = Library.NotificationArea,
    })

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = NotifyOuter,
    })

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    }, true)

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 102,
        Parent = NotifyInner,
    })

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Library:GetDarkerColor(Library.MainColor)
            ),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }),
        Rotation = -90,
        Parent = InnerFrame,
    })

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(
                    0,
                    Library:GetDarkerColor(Library.MainColor)
                ),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            })
        end,
    })

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        Text = Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 14,
        ZIndex = 103,
        Parent = InnerFrame,
    })

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -1, 0, -1),
        Size = UDim2.new(0, 3, 1, 2),
        ZIndex = 104,
        Parent = NotifyOuter,
    })

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor',
    }, true)

    pcall(
        NotifyOuter.TweenSize,
        NotifyOuter,
        UDim2.new(0, XSize + 8 + 4, 0, YSize),
        'Out',
        'Quad',
        0.4,
        true
    )

    task.spawn(function()
        wait(Time or 5)

        pcall(
            NotifyOuter.TweenSize,
            NotifyOuter,
            UDim2.new(0, 0, 0, YSize),
            'Out',
            'Quad',
            0.4,
            true
        )

        wait(0.4)

        NotifyOuter:Destroy()
    end)
end

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false
    end

    if type(Config.Title) ~= 'string' then
        Config.Title = 'No title'
    end
    if type(Config.TabPadding) ~= 'number' then
        Config.TabPadding = 0
    end
    if type(Config.MenuFadeTime) ~= 'number' then
        Config.MenuFadeTime = 0.2
    end

    if typeof(Config.Position) ~= 'UDim2' then
        Config.Position = UDim2.fromOffset(175, 50)
    end
    if typeof(Config.Size) ~= 'UDim2' then
        Config.Size = UDim2.fromOffset(550, 600)
    end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {},
    }

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Position = Config.Position,
        Size = Config.Size,
        Visible = false,
        ZIndex = 1,
        Parent = ScreenGui,
    })

    Library:MakeDraggable(Outer, 25)

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
        Parent = Outer,
    })

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'AccentColor',
    })

    local WindowImage = Library:Create('ImageLabel', {
        Position = UDim2.new(0, 7, 0, 0),
        Size = UDim2.new(0, 200, 0, 25), -- Adjust size as needed
        BackgroundTransparency = 1,
        Image = "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",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 1,
        Parent = Inner,
    })


    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 1, -33),
        ZIndex = 1,
        Parent = Inner,
    })

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor',
        BorderColor3 = 'OutlineColor',
    })

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Color3.new(0, 0, 0),
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = MainSectionOuter,
    })

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor',
    })

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 21),
        ZIndex = 1,
        Parent = MainSectionInner,
    })

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabArea,
    })

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 30),
        Size = UDim2.new(1, -16, 1, -38),
        ZIndex = 2,
        Parent = MainSectionInner,
    })

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })


    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {},
            Tabboxes = {},
        }

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16)

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0),
            ZIndex = 1,
            Parent = TabArea,
        })

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -1),
            Text = Name,
            ZIndex = 1,
            Parent = TabButton,
        })

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundTransparency = 1,
            ZIndex = 3,
            Parent = TabButton,
        })

        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = 'MainColor',
        })

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2,
            Parent = TabContainer,
        })

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1),
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = '',
            TopImage = '',
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1),
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = '',
            TopImage = '',
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = LeftSide,
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = RightSide,
        })

        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout')
                :GetPropertyChangedSignal('AbsoluteContentSize')
                :Connect(function()
                    Side.CanvasSize = UDim2.fromOffset(
                        0,
                        Side.UIListLayout.AbsoluteContentSize.Y
                    )
                end)
        end

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab()
            end

            Blocker.BackgroundTransparency = 0
            TabButton.BackgroundColor3 = Library.MainColor
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 =
                'MainColor'
            TabFrame.Visible = true
        end

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1
            TabButton.BackgroundColor3 = Library.BackgroundColor
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 =
                'BackgroundColor'
            TabFrame.Visible = false
        end

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position
            TabListLayout:ApplyLayout()
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 0, 507 + 2),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor',
            })

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 5,
                Parent = BoxInner,
            })

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor',
            })

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18),
                Position = UDim2.new(0, 4, 0, 2),
                TextSize = 14,
                Text = Info.Name,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = BoxInner,
            })

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, 20),
                Size = UDim2.new(1, -4, 1, -20),
                ZIndex = 1,
                Parent = BoxInner,
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })

            function Groupbox:Resize()
                local Size = 0

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if
                        (not Element:IsA('UIListLayout')) and Element.Visible
                    then
                        Size = Size + Element.Size.Y.Offset
                    end
                end

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
            end

            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:AddBlank(3)
            Groupbox:Resize()

            Tab.Groupboxes[Info.Name] = Groupbox

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2, Name = Name })
        end

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {},
            }

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor',
            })

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 10,
                Parent = BoxInner,
            })

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor',
            })

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 1),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 5,
                Parent = BoxInner,
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabboxButtons,
            })

            function Tabbox:AddTab(Name)
                local Tab = {}

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    ZIndex = 6,
                    Parent = TabboxButtons,
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor',
                })

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    TextSize = 14,
                    Text = Name,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7,
                    Parent = Button,
                })

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    Visible = false,
                    ZIndex = 9,
                    Parent = Button,
                })

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor',
                })

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 4, 0, 20),
                    Size = UDim2.new(1, -4, 1, -20),
                    ZIndex = 1,
                    Visible = false,
                    Parent = BoxInner,
                })

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = Container,
                })

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide()
                    end

                    Container.Visible = true
                    Block.Visible = true

                    Button.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 =
                        'BackgroundColor'

                    Tab:Resize()
                end

                function Tab:Hide()
                    Container.Visible = false
                    Block.Visible = false

                    Button.BackgroundColor3 = Library.MainColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 =
                        'MainColor'
                end

                function Tab:Resize()
                    local TabCount = 0

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1
                    end

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                        end
                    end

                    if not Container.Visible then
                        return
                    end

                    local Size = 0

                    for _, Element in next, Tab.Container:GetChildren() do
                        if
                            (not Element:IsA('UIListLayout'))
                            and Element.Visible
                        then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
                end

                Button.InputBegan:Connect(function(Input)
                    if
                        Input.UserInputType
                            == Enum.UserInputType.MouseButton1
                        and not Library:MouseIsOverOpenedFrame()
                    then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)

                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab

                setmetatable(Tab, BaseGroupbox)

                Tab:AddBlank(3)
                Tab:Resize()

                -- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show()
                end

                return Tab
            end

            Tab.Tabboxes[Info.Name or ''] = Tabbox

            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1 })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2 })
        end

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab()
            end
        end)

        -- This was the first tab added, so we show it by default.
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab()
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = true,
        Text = '',
        Modal = false,
        Parent = ScreenGui,
    })

    local TransparencyCache = {}
    local Toggled = false
    local Fading = false

    function Library:Toggle()
        if Fading then
            return
        end

        local FadeTime = Config.MenuFadeTime
        Fading = true
        Toggled = not Toggled
        ModalElement.Modal = Toggled

        if Toggled then
            -- A bit scuffed, but if we're going from not toggled -> toggled we want to show the frame immediately so that the fade is visible.
            Outer.Visible = true

            task.spawn(function()
                -- TODO: add cursor fade?
                local State = InputService.MouseIconEnabled

                local Cursor = Drawing.new('Triangle')
                Cursor.Thickness = 1
                Cursor.Filled = true
                Cursor.Visible = true

                local CursorOutline = Drawing.new('Triangle')
                CursorOutline.Thickness = 1
                CursorOutline.Filled = false
                CursorOutline.Color = Color3.new(0, 0, 0)
                CursorOutline.Visible = true

                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false

                    local mPos = InputService:GetMouseLocation()

                    Cursor.Color = Library.AccentColor

                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y)
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6)
                    Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16)

                    CursorOutline.PointA = Cursor.PointA
                    CursorOutline.PointB = Cursor.PointB
                    CursorOutline.PointC = Cursor.PointC

                    RenderStepped:Wait()
                end

                InputService.MouseIconEnabled = State

                Cursor:Remove()
                CursorOutline:Remove()
            end)
        end

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {}

            if Desc:IsA('ImageLabel') then
                table.insert(Properties, 'ImageTransparency')
                table.insert(Properties, 'BackgroundTransparency')
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                table.insert(Properties, 'TextTransparency')
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                table.insert(Properties, 'BackgroundTransparency')
            elseif Desc:IsA('UIStroke') then
                table.insert(Properties, 'Transparency')
            end

            local Cache = TransparencyCache[Desc]

            if not Cache then
                Cache = {}
                TransparencyCache[Desc] = Cache
            end

            for _, Prop in next, Properties do
                if not Cache[Prop] then
                    Cache[Prop] = Desc[Prop]
                end

                if Cache[Prop] == 1 then
                    continue
                end

                TweenService
                    :Create(
                        Desc,
                        TweenInfo.new(FadeTime, Enum.EasingStyle.Linear),
                        { [Prop] = Toggled and Cache[Prop] or 1 }
                    )
                    :Play()
            end
        end

        task.wait(FadeTime)

        Outer.Visible = Toggled

        Fading = false
    end

    Library:GiveSignal(
        InputService.InputBegan:Connect(function(Input, Processed)
            if
                type(Library.ToggleKeybind) == 'table'
                and Library.ToggleKeybind.Type == 'KeyPicker'
            then
                if
                    Input.UserInputType == Enum.UserInputType.Keyboard
                    and Input.KeyCode.Name == Library.ToggleKeybind.Value
                then
                    task.spawn(Library.Toggle)
                end
            elseif Input.KeyCode == Enum.KeyCode.Insert then
                task.spawn(Library.Toggle)
            end
        end)
    )

    if Config.AutoShow then
        task.spawn(Library.Toggle)
    end

    Window.Holder = Outer

    return Window
end

local function OnPlayerChange()
    local PlayerList = GetPlayersString()

    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList)
        end
    end
end

Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library

local httpService = game:GetService('HttpService')

local SaveManager = {}
do
    SaveManager.Folder = 'LinoriaLibSettings'
    SaveManager.Ignore = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = 'Toggle', idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if Toggles[idx] then
                    Toggles[idx]:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return {
                    type = 'Slider',
                    idx = idx,
                    value = tostring(object.Value),
                }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    Options[idx]:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return {
                    type = 'Dropdown',
                    idx = idx,
                    value = object.Value,
                    mutli = object.Multi,
                }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    Options[idx]:SetValue(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return {
                    type = 'ColorPicker',
                    idx = idx,
                    value = object.Value:ToHex(),
                    transparency = object.Transparency,
                }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    Options[idx]:SetValueRGB(
                        Color3.fromHex(data.value),
                        data.transparency
                    )
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return {
                    type = 'KeyPicker',
                    idx = idx,
                    mode = object.Mode,
                    key = object.Value,
                }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    Options[idx]:SetValue({ data.key, data.mode })
                end
            end,
        },

        Input = {
            Save = function(idx, object)
                return { type = 'Input', idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] and type(data.text) == 'string' then
                    Options[idx]:SetValue(data.text)
                end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:Save(name)
        if not name then
            return false, 'no config file is selected'
        end

        local fullPath = self.Folder .. '/settings/' .. name .. '.json'

        local data = {
            objects = {},
        }

        for idx, toggle in next, Toggles do
            if self.Ignore[idx] then
                continue
            end

            table.insert(
                data.objects,
                self.Parser[toggle.Type].Save(idx, toggle)
            )
        end

        for idx, option in next, Options do
            if not self.Parser[option.Type] then
                continue
            end
            if self.Ignore[idx] then
                continue
            end

            table.insert(
                data.objects,
                self.Parser[option.Type].Save(idx, option)
            )
        end

        local success, encoded =
            pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, 'failed to encode data'
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if not name then
            return false, 'no config file is selected'
        end

        local file = self.Folder .. '/settings/' .. name .. '.json'
        if not isfile(file) then
            return false, 'invalid file'
        end

        local success, decoded =
            pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then
            return false, 'decode error'
        end

        for _, option in next, decoded.objects do
            if self.Parser[option.type] then
                task.spawn(function()
                    self.Parser[option.type].Load(option.idx, option)
                end) -- task.spawn() so the config loading wont get stuck.
            end
        end

        return true
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            'BackgroundColor',
            'MainColor',
            'AccentColor',
            'OutlineColor',
            'FontColor', -- themes
            'ThemeManager_ThemeList',
            'ThemeManager_CustomThemeList',
            'ThemeManager_CustomThemeName', -- themes
        })
    end

    function SaveManager:BuildFolderTree()
        local paths = {
            self.Folder,
            self.Folder .. '/themes',
            self.Folder .. '/settings',
        }

        for i = 1, #paths do
            local str = paths[i]
            if not isfolder(str) then
                makefolder(str)
            end
        end
    end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder .. '/settings')

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                -- i hate this but it has to be done ...

                local pos = file:find('.json', 1, true)
                local start = pos

                local char = file:sub(pos, pos)
                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == '/' or char == '\\' then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end

        return out
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
    end

    function SaveManager:LoadAutoloadConfig()
        if isfile(self.Folder .. '/settings/autoload.txt') then
            local name = readfile(self.Folder .. '/settings/autoload.txt')

            local success, err = self:Load(name)
            if not success then
                return self.Library:Notify(
                    'Failed to load autoload config: ' .. err
                )
            end
        end
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, 'Must set SaveManager.Library')

        local section = tab:AddRightGroupbox('Configuration')

        section:AddInput('SaveManager_ConfigName', { Text = 'Config name' })
        section:AddDropdown('SaveManager_ConfigList', {
            Text = 'Config list',
            Values = self:RefreshConfigList(),
            AllowNull = true,
        })

        section:AddDivider()

        section
            :AddButton('Save config', function()
                local name = Options.SaveManager_ConfigList.Value

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify('Failed to save config: ' .. err)
                end

                self.Library:Notify(string.format('Overwrote config %q', name))
            end)
            :AddButton('Load config', function()
                local name = Options.SaveManager_ConfigList.Value

                local success, err = self:Load(name)
                if not success then
                    return self.Library:Notify('Failed to load config: ' .. err)
                end

                self.Library:Notify(string.format('Loaded config %q', name))
            end)

        section:AddButton('Create config', function()
            local name = Options.SaveManager_ConfigName.Value

            if name:gsub(' ', '') == '' then
                return self.Library:Notify('Invalid config name (empty)', 2)
            end

            local success, err = self:Save(name)
            if not success then
                return self.Library:Notify('Failed to save config: ' .. err)
            end

            self.Library:Notify(string.format('Created config %q', name))

            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddButton('Refresh list', function()
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddButton('Set as autoload', function()
            local name = Options.SaveManager_ConfigList.Value
            writefile(self.Folder .. '/settings/autoload.txt', name)
            SaveManager.AutoloadLabel:SetText(
                'Current autoload config: ' .. name
            )
            self.Library:Notify(string.format('Set %q to auto load', name))
        end)

        SaveManager.AutoloadLabel =
            section:AddLabel('Current autoload config: none', true)

        if isfile(self.Folder .. '/settings/autoload.txt') then
            local name = readfile(self.Folder .. '/settings/autoload.txt')
            SaveManager.AutoloadLabel:SetText(
                'Current autoload config: ' .. name
            )
        end

        SaveManager:SetIgnoreIndexes({
            'SaveManager_ConfigList',
            'SaveManager_ConfigName',
        })
    end

    SaveManager:BuildFolderTree()

    getgenv().SaveManager = SaveManager
end

--
-- Renderer
local Renderer = { DrawList = {} }

function Renderer:FindExistingShape(name)
    local Shape = self.DrawList[name]
    if Shape then
        return Shape
    else
        return nil
    end
end

function Renderer:Unrender(name_table)
    for _, v in pairs(name_table) do
        local Shape = self:FindExistingShape(v)

        if Shape then
            Shape.Visible = false
            Shape:Remove()
        end

        self.DrawList[v] = nil
    end
end

function Renderer:UnrenderAll()
    for Name, Shape in pairs(self.DrawList) do
        if Shape then
            Shape.Visible = false
            Shape:Remove()
        end

        self.DrawList[v] = nil
    end
end

function Renderer:UnrenderAllExcept(exclude_table)
    for Name, Shape in pairs(self.DrawList) do
        local ShouldContinue = false

        for _, Exclude in pairs(exclude_table) do
            if Exclude == Name then
                ShouldContinue = true
                break
            end
        end

        if ShouldContinue then
            ShouldContinue = false
            continue
        end

        if Shape then
            Shape.Visible = false
            Shape:Remove()
        end

        self.DrawList[Name] = nil
    end
end

function Renderer:Rectangle(name, position, size, color)
    local Shape = self:FindExistingShape(name)

    if Shape then
        Shape.Visible = true
        Shape.Position = position
        Shape.Size = size
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = false
    else
        Shape = Drawing.new('Square')
        Shape.Visible = true
        Shape.Position = position
        Shape.Size = size
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = false

        self.DrawList[name] = Shape
    end

    return Shape
end

function Renderer:FilledRectangle(name, position, size, color)
    local Shape = self:FindExistingShape(name)

    if Shape then
        Shape.Visible = true
        Shape.Position = position
        Shape.Size = size
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = true
    else
        Shape = Drawing.new('Square')
        Shape.Visible = true
        Shape.Position = position
        Shape.Size = size
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = true

        self.DrawList[name] = Shape
    end

    return Shape
end

function Renderer:Circle(name, position, radius, color)
    local Shape = self:FindExistingShape(name)

    if Shape then
        Shape.Visible = true
        Shape.Position = position
        Shape.Radius = radius
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = false
    else
        Shape = Drawing.new('Circle')
        Shape.Visible = true
        Shape.Position = position
        Shape.Radius = radius
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = false

        self.DrawList[name] = Shape
    end

    return Shape
end

function Renderer:FilledCircle(name, position, radius, color)
    local Shape = self:FindExistingShape(name)

    if Shape then
        Shape.Visible = true
        Shape.Position = position
        Shape.Radius = radius
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = true
    else
        Shape = Drawing.new('Circle')
        Shape.Visible = true
        Shape.Position = position
        Shape.Radius = radius
        Shape.Color = color
        Shape.Transparency = 1
        Shape.Filled = true

        self.DrawList[name] = Shape
    end

    return Shape
end

function Renderer:Line(name, from, to, color, thickness)
    local Shape = self:FindExistingShape(name)

    if Shape then
        Shape.Visible = true
        Shape.From = from
        Shape.To = to
        Shape.Color = color
        Shape.Thickness = thickness
        Shape.Transparency = 1
    else
        Shape = Drawing.new('Line')
        Shape.Visible = true
        Shape.From = from
        Shape.To = to
        Shape.Color = color
        Shape.Thickness = thickness
        Shape.Transparency = 1

        self.DrawList[name] = Shape
    end

    return Shape
end

function Renderer:Text(name, position, text, color, size, font)
    local Shape = self:FindExistingShape(name)

    if Shape then
        Shape.Visible = true
        Shape.Position = position
        Shape.Text = text
        Shape.Color = color
        Shape.Size = size
        Shape.Font = font
        Shape.Transparency = 1
    else
        Shape = Drawing.new('Text')
        Shape.Visible = true
        Shape.Position = position
        Shape.Text = text
        Shape.Color = color
        Shape.Size = size
        Shape.Font = font
        Shape.Transparency = 1

        self.DrawList[name] = Shape
    end

    return Shape
end
