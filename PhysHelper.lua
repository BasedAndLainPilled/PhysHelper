local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PhysHelper = {
	Pool = {},             -- [part] = {ownerSet = false}
	partsList = {},        -- ordered list of parts
	currentIndex = 1,
	chunkSize = 25,       -- number of parts per frame
	heartbeat = nil,

	thresh = 0.2,
	nudge = Vector3.new(0, 0.0001, 0), -- small nudge up (increasing 2 much will cause physics instability, scale as you wish tho)
	FramesSkip = 2,
	neighborMultiplier = 2, -- chunkSize multiplier for nearby parts
	frameCounter = 0,
	playerIndex = 1,
}

-- normalize input into a BasePart (No meshes, only models and baseparts)
local function resolvePart(obj)
	if typeof(obj) ~= "Instance" then return nil end
	if obj:IsA("BasePart") then return obj end
	if obj:IsA("Model") then
		if obj.PrimaryPart then return obj.PrimaryPart end
		return obj:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

--get nearby unanchored parts
local function getNearbyParts(part, multiplier)
	local radius = math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2 * multiplier
	local parts = workspace:GetPartBoundsInRadius(part.Position, radius)
	local filtered = {}
	for _, p in ipairs(parts) do
		if p:IsA("BasePart") and not p.Anchored then
			filtered[p] = true
		end
	end
	return filtered
end

-- Main loop
local function stirParts()
	PhysHelper.frameCounter = (PhysHelper.frameCounter + 1) % PhysHelper.FramesSkip
	if PhysHelper.frameCounter ~= 0 then return end

	if #PhysHelper.partsList == 0 then
		if PhysHelper.heartbeat then
			PhysHelper.heartbeat:Disconnect()
			PhysHelper.heartbeat = nil
		end
		return
	end

	local startIndex = PhysHelper.currentIndex
	local endIndex = math.min(startIndex + PhysHelper.chunkSize - 1, #PhysHelper.partsList)
	local activeParts = {}

	for i = startIndex, endIndex do
		local part = PhysHelper.partsList[i]
		local info = PhysHelper.Pool[part]

		if not part or not part.Parent or not part:IsDescendantOf(workspace) or part.Anchored or not info then
			PhysHelper.Pool[part] = nil
			PhysHelper.partsList[i] = false
		else
			local neighbors = getNearbyParts(part, PhysHelper.neighborMultiplier)
			for neighbor in pairs(neighbors) do
				if neighbor ~= part then
					activeParts[part] = true
					break
				end
			end
		end
	end

	local players = Players:GetPlayers()
	for part in pairs(activeParts) do
		local info = PhysHelper.Pool[part]
		if info then
			if not info.ownerSet and #players > 0 then
				local player = players[PhysHelper.playerIndex]
				part:SetNetworkOwner(player)
				info.ownerSet = true
				PhysHelper.playerIndex = (PhysHelper.playerIndex % #players) + 1
			end

			if part.AssemblyLinearVelocity.Magnitude < PhysHelper.thresh then
				-- scale nudge by mass
				local mass = part:GetMass()
                   local masscap = math.min(mass, 50) --You can probably remove the cap
                part.AssemblyLinearVelocity += PhysHelper.nudge * masscap
			end
		end
	end

	-- Cleanup false entries per frame
	local newList = {}
	for _, p in ipairs(PhysHelper.partsList) do
		if p and p ~= false then
			table.insert(newList, p)
		end
	end
	PhysHelper.partsList = newList

	-- Update index
	PhysHelper.currentIndex = endIndex + 1
	if PhysHelper.currentIndex > #PhysHelper.partsList then
		PhysHelper.currentIndex = 1
	end
end


--API
function PhysHelper:StopSleep(obj)
	local part = resolvePart(obj)
	if not part or part.Anchored then return end

	if not self.Pool[part] then
		self.Pool[part] = {ownerSet = false}
		table.insert(self.partsList, part)
	end

	if not self.heartbeat then
		self.heartbeat = RunService.Heartbeat:Connect(stirParts)
	end
end

function PhysHelper:LetSleep(obj)
	local part = resolvePart(obj)
	if not part then return end

	self.Pool[part] = nil
	for i, p in ipairs(self.partsList) do
		if p == part then
			self.partsList[i] = false
			break
		end
	end

	if next(self.Pool) == nil and self.heartbeat then
		self.heartbeat:Disconnect()
		self.heartbeat = nil
	end
end

function PhysHelper:ClearAllWatched()
	for part, _ in pairs(self.Pool) do
		if part and part:IsA("BasePart") then
			part:SetNetworkOwner(nil)
		end
	end
	self.Pool = {}
	self.partsList = {}
	self.currentIndex = 1
	self.playerIndex = 1

	if self.heartbeat then
		self.heartbeat:Disconnect()
		self.heartbeat = nil
	end
end

return PhysHelper



