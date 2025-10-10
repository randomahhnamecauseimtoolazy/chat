return {
    Aimbot = {
        Enabled = false,
        HitPart = "Head",
        WallCheck = false,
        AutoTargetSwitch = false,
        MaxDistance = { Enabled = false, Value = 500 },
        Easing = { Strength = 0.1, Sensitivity = Instance.new("NumberValue") }
    },
    ESP = {
        Enabled = false,
        MaxDistance = { Enabled = false, Value = 500 },
        VisibilityCheck = false,
        UseFOV = false,
        Features = {
            Box = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
            Tracer = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
            DistanceText = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
            Name = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
            HeadDot = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) }
        }
    },
    FOV = {
        Enabled = false,
        FollowGun = false,
        Radius = 50,
        Circle = drawing.new("Circle"),
        OutlineCircle = drawing.new("Circle"),
        Filled = false,
        FillColor = Color3.fromRGB(0, 0, 0),
        FillTransparency = 0.2,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 1
    },
    Chams = {
        Enabled = false,
        TeamCheck = true,
        Teammates = false,
        Fill = { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.5 },
        Outline = { Color = Color3.fromRGB(255, 255, 255), Transparency = 0 }
    },
    Player = {
        Bhop = { Enabled = false }
    },
    Misc = {
        Textures = false,
        VotekickRejoiner = false,
        Optimized = false
    },
    Crosshair = {
        Enabled = false,
        Size = 10,
        Thickness = 1,
        Gap = 5,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,
        Dot = false,
        TStyle = "Default",
        Drawings = {
            Line1 = drawing.new("Line"),
            Line2 = drawing.new("Line"),
            Line3 = drawing.new("Line"),
            Line4 = drawing.new("Line"),
            CenterDot = drawing.new("Circle")
        }
    }
}
