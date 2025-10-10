local ESP = {}
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local UPDATE_INTERVAL = 0.25
local VISIBILITY_INTERVAL = 0.5
local MAX_PLAYERS = 100

function ESP:Init(Settings, State, Utilities)
	self.Settings = Settings
	self.State = State
	self.Utilities = Utilities
end

function ESP:initializeESP()
	local cache = self.State.Storage.ESPCache
	for i = 1, #cache do
		self.Utilities:uncacheObject(cache[i])
	end
	self.State.PlayersToDraw = table.create(MAX_PLAYERS)
	self.State.CachedProperties = {}
	self.State.LastUpdate = 0
	self.State.LastVisUpdate = 0

	for i = 1, MAX_PLAYERS do
		cache[i] = self.Utilities:createESPObject and self.Utilities:createESPObject() or {}
	end
end

function ESP:cleanupStalePlayers()
	local cache = self.State.Storage.ESPCache
	local cachedProps = self.State.CachedProperties
	for i = #cache, 1, -1 do
		local p = cache[i]
		if p and not self.Utilities:isValidPlayer(p) then
			self.Utilities:uncacheObject(p)
			cachedProps[p] = nil
			cache[i] = nil
		end
	end
end

function ESP:updatePlayerCache()
	self:cleanupStalePlayers()

	local playersToDraw = self.State.PlayersToDraw
	local cachedProps = self.State.CachedProperties
	local settings = self.Settings.ESP
	local maxDistEnabled = settings.MaxDistance.Enabled
	local maxDistValue = settings.MaxDistance.Value
	local cameraPos = Camera.CFrame.Position
	local idx = 0

	local allPlayers = self.Utilities:getPlayers()
	for i = 1, #allPlayers do
		local p = allPlayers[i]
		if self.Utilities:isValidPlayer(p) and self.Utilities:isEnemy(p) then
			local torso, head = self.Utilities:getBodyPart(p, "Torso"), self.Utilities:getBodyPart(p, "Head")
			if torso and head then
				local dist = (head.Position - cameraPos).Magnitude
				if (not maxDistEnabled) or dist <= maxDistValue then
					idx += 1
					playersToDraw[idx] = p
					local gui = head:FindFirstChildOfClass("BillboardGui")
					local label = gui and gui:FindFirstChildOfClass("TextLabel")
					if gui and label then
						local cached = cachedProps[p] or {}
						if cached.Name ~= label.Text then
							cached.Name = label.Text
							cachedProps[p] = cached
						end
					end
				end
			end
		end
	end

	for i = idx + 1, #playersToDraw do
		playersToDraw[i] = nil
	end
end

function ESP:renderESP()
	local now = tick()
	local state = self.State
	local settings = self.Settings
	local camPos = Camera.CFrame.Position
	local viewSize = Camera.ViewportSize
	local center = Vector2.new(viewSize.X / 2, viewSize.Y)
	local fovEnabled = settings.ESP.UseFOV
	local fovRadius = fovEnabled and settings.FOV.OutlineCircle.Radius or nil
	local playersToDraw = state.PlayersToDraw
	local cachedProps = state.CachedProperties
	local cacheTable = state.Storage.ESPCache

	if now - state.LastUpdate >= UPDATE_INTERVAL then
		self:updatePlayerCache()
		state.LastUpdate = now
	end

	local checkVisibility = now - state.LastVisUpdate >= VISIBILITY_INTERVAL
	if checkVisibility then
		state.LastVisUpdate = now
	end

	for i = 1, #playersToDraw do
		local p = playersToDraw[i]
		if not self.Utilities:isValidPlayer(p) then continue end

		local cache = cacheTable[p] or (self.Utilities:cacheObject(p) and cacheTable[p])
		local torso, head = self.Utilities:getBodyPart(p, "Torso"), self.Utilities:getBodyPart(p, "Head")
		if not torso or not head then
			if cache then
				for _, e in pairs(cache) do e.Visible = false end
			end
			continue
		end

		local torsoPos, torsoOn = Camera:WorldToViewportPoint(torso.Position)
		local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
		if not torsoOn then
			if cache then
				for _, e in pairs(cache) do e.Visible = false end
			end
			continue
		end

		local distCam = (torso.Position - camPos).Magnitude
		local screenPos = Vector2.new(torsoPos.X, torsoPos.Y)
		if fovEnabled then
			local distCenter = (screenPos - center).Magnitude
			if distCenter > fovRadius then
				for _, e in pairs(cache) do e.Visible = false end
				continue
			end
		end

		local scale = 80000 / (distCam * Camera.FieldOfView)
		local boxW, boxH = math.floor(3 * scale), math.floor(4 * scale)
		local boxPos = Vector2.new(torsoPos.X - boxW / 2, torsoPos.Y - boxH / 2)
		local visible = (not checkVisibility) or self.Utilities:isVisible(head, settings.ESP.VisibilityCheck)
		local boxCol = visible and settings.ESP.Features.Box.Color or Color3.fromRGB(255, 0, 0)
		local prop = cachedProps[p] or {}

		-- BOX
		if settings.ESP.Features.Box.Enabled then
			local b = cache.BoxSquare
			if b.Color ~= boxCol then b.Color = boxCol end
			b.Visible = true
			b.Position = boxPos
			b.Size = Vector2.new(boxW, boxH)
			cache.BoxOutline.Position = Vector2.new(boxPos.X - 1, boxPos.Y - 1)
			cache.BoxOutline.Size = Vector2.new(boxW + 2, boxH + 2)
		else
			cache.BoxSquare.Visible = false
		end

		-- TRACER
		if settings.ESP.Features.Tracer.Enabled then
			local t = cache.TracerLine
			t.Visible = true
			t.Color = visible and settings.ESP.Features.Tracer.Color or Color3.fromRGB(255, 0, 0)
			t.From = Vector2.new(viewSize.X / 2, viewSize.Y)
			t.To = screenPos
		else
			cache.TracerLine.Visible = false
		end

		-- NAME
		if settings.ESP.Features.Name.Enabled and prop.Name then
			local n = cache.NameLabel
			n.Visible = true
			n.Text = prop.Name
			n.Color = settings.ESP.Features.Name.Color
			n.Size = math.clamp(scale * 2.5, 12, 16)
			n.Center = true
			n.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y - 15)
			n.Outline = true
		else
			cache.NameLabel.Visible = false
		end

		-- DISTANCE
		if settings.ESP.Features.DistanceText.Enabled then
			local d = cache.DistanceLabel
			d.Visible = true
			d.Text = math.floor(distCam) .. " studs"
			d.Color = settings.ESP.Features.DistanceText.Color
			d.Size = math.clamp(scale * 2.5, 14, 18)
			d.Position = Vector2.new(boxPos.X + (boxW / 2), boxPos.Y + boxH + 5)
			d.Outline = true
		else
			cache.DistanceLabel.Visible = false
		end

		-- HEAD DOT
		if settings.ESP.Features.HeadDot.Enabled and headOn then
			local h = cache.HeadDot
			h.Visible = true
			h.Color = settings.ESP.Features.HeadDot.Color
			h.Radius = boxH / 20
			h.Position = Vector2.new(headPos.X, headPos.Y)
		else
			cache.HeadDot.Visible = false
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
