local Chams = {}
local RunService = game:GetService("RunService")

function Chams:Init(Settings, State, Utilities)
    self.Settings = Settings
    self.State = State
    self.Utilities = Utilities
end

function Chams:applyHighlight(p)
    if self.State.Highlights[p] then return self.State.Highlights[p] end
    local h = Instance.new("Highlight")
    h.FillColor = self.Settings.Chams.Fill.Color
    h.OutlineColor = self.Settings.Chams.Outline.Color
    h.FillTransparency = self.Settings.Chams.Fill.Transparency
    h.OutlineTransparency = self.Settings.Chams.Outline.Transparency
    h.Adornee = p
    h.Parent = game.CoreGui
    self.State.Highlights[p] = h
    return h
end

function Chams:removeHighlight(p)
    if self.State.Highlights[p] then
        self.State.Highlights[p]:Destroy()
        self.State.Highlights[p] = nil
    end
end

function Chams:updateChams()
    if not self.Settings.Chams.Enabled then
        for p in pairs(self.State.Highlights) do self:removeHighlight(p) end
        return
    end
    for _, p in pairs(self.Utilities:getPlayers()) do
        if self.Utilities:isValidPlayer(p) then
            local ally = self.Utilities:isAlly(p)
            if ally and not self.Settings.Chams.Teammates then
                self:removeHighlight(p)
            else
                local torso = self.Utilities:getBodyPart(p, "Torso")
                if not torso then
                    self:removeHighlight(p)
                else
                    local dist = (torso.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                    if self.Settings.ESP.MaxDistance.Enabled and dist > self.Settings.ESP.MaxDistance.Value then
                        self:removeHighlight(p)
                    else
                        local h = self:applyHighlight(p)
                        local vis = self.Utilities:isVisible(torso, self.Settings.ESP.VisibilityCheck)
                        if self.Settings.ESP.VisibilityCheck and not vis then
                            h.FillColor = Color3.fromRGB(255, 0, 0)
                            h.OutlineColor = Color3.fromRGB(255, 0, 0)
                            h.FillTransparency = 0.5
                            h.OutlineTransparency = 0.2
                        else
                            h.FillColor = self.Settings.Chams.Fill.Color
                            h.OutlineColor = self.Settings.Chams.Outline.Color
                            h.FillTransparency = self.Settings.Chams.Fill.Transparency
                            h.OutlineTransparency = self.Settings.Chams.Outline.Transparency
                        end
                    end
                end
            end
        end
    end
    for p in pairs(self.State.Highlights) do
        if not self.Utilities:isValidPlayer(p) then self:removeHighlight(p) end
    end
end

function Chams:Cleanup()
    if self.State.ChamsUpdateConnection then
        self.State.ChamsUpdateConnection:Disconnect()
        self.State.ChamsUpdateConnection = nil
    end
    for p in pairs(self.State.Highlights) do self:removeHighlight(p) end
end

return Chams
