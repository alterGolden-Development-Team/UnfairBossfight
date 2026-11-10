--!nonstrict
--[[
 PortalService - moving around the lobby place (docs/spec/lobby-redesign.md). The hub and the three boss worlds all live in this one place, far
 apart, so walking into a portal is a short fade and a move. Any part tagged UnfairPortal with a Target attribute is a portal.
 The server moves the character, so a client cannot walk itself anywhere it is not supposed to be.
   * Player attribute `Area` tells the client which world they are in (lighting, title card)
   * falling off the sky island, or swimming out of the island's waters, brings you back to that area's arrival point
   * sails the ferry boats on the island
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local remote = LobbyRemotes.get("Area")

local world = workspace:WaitForChild("World", 30)
if not world then
	return -- the map is not built
end

local islandFolder = world:FindFirstChild("Island")
local ISLAND_ORIGIN = islandFolder and islandFolder:GetAttribute("Origin") or Vector3.new(-12000, 0, 0)

local AREAS = {
	Hub = { Arrival = "Hub.Arrival", Floor = 330 },
	Palace = { Arrival = "Palace.ArrivalPalace", Floor = -440 },
	Island = { Arrival = "Island.ArrivalIsland", Floor = -40, Radius = 760, Center = ISLAND_ORIGIN },
	Forest = { Arrival = "Forest.ArrivalForest", Floor = -440 },
	Stage = { Arrival = "Stage.ArrivalStage", Floor = -440 }, -- the training hall; TryoutService sends people there
}

local FADE_TIME = 0.35
local moving = {}

local function find(path)
	local cur = world
	for part in string.gmatch(path, "[^%.]+") do
		cur = cur and cur:FindFirstChild(part)
	end
	return cur
end

local function arrivalCF(area)
	local spot = find(AREAS[area].Arrival)
	if not spot then
		return nil
	end
	local radius = spot:GetAttribute("Radius") or 6
	local a = math.random() * math.pi * 2
	local d = math.random() * radius
	return spot.CFrame + Vector3.new(math.cos(a) * d, 3, math.sin(a) * d)
end

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and humanoid and humanoid.Health > 0 then
		return character, root, humanoid
	end
end

local function moveTo(player, cf, area)
	local character, _, humanoid = rootOf(player)
	if not character then
		return
	end
	humanoid.Sit = false
	character:PivotTo(cf)
	player:SetAttribute("Area", area)
end

local function travel(player, area)
	if moving[player] or not AREAS[area] then
		return
	end
	local cf = arrivalCF(area)
	if not cf then
		return
	end
	moving[player] = true
	remote:FireClient(player, "FadeOut", area)
	task.wait(FADE_TIME)
	moveTo(player, cf, area)
	task.wait(0.25)
	remote:FireClient(player, "FadeIn", area)
	task.wait(0.7) -- a little grace so the exit portal behind you cannot grab you straight back
	moving[player] = nil
end

local function bindPortal(part)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and hit.Name == "HumanoidRootPart" then
			task.spawn(travel, player, part:GetAttribute("Target"))
		end
	end)
end
for _, part in CollectionService:GetTagged("UnfairPortal") do
	bindPortal(part)
end
CollectionService:GetInstanceAddedSignal("UnfairPortal"):Connect(bindPortal)

local function onCharacter(player)
	player:SetAttribute("Area", "Hub")
end
local function onPlayer(player)
	player:SetAttribute("Area", "Hub")
	player.CharacterAdded:Connect(function()
		onCharacter(player)
	end)
end
Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	moving[player] = nil
end)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

-- Falling off or swimming away -----------------------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local _, root = rootOf(player)
			local area = AREAS[player:GetAttribute("Area")]
			if root and area and not moving[player] then
				local out = root.Position.Y < area.Floor
				if not out and area.Radius then
					out = (root.Position - area.Center).Magnitude > area.Radius
				end
				if out then
					task.spawn(travel, player, player:GetAttribute("Area"))
				end
			end
		end
	end
end)

-- The ferry ------------------------------------------------------------------------------------------------------------
local islandFolder = world:FindFirstChild("Island")
local boatsFolder = islandFolder and islandFolder:FindFirstChild("Boats")
local boardSpot = islandFolder and islandFolder:FindFirstChild("BoardingSpot")
local landing = islandFolder and islandFolder:FindFirstChild("BoatLanding")

if boatsFolder and boardSpot and landing then
	local SAIL_TIME, WAIT_DOCK, WAIT_LAND = 12, 7, 3
	local fleet = {}

	local function seatsOf(boat)
		local seats = {}
		for _, item in boat:GetChildren() do
			if item:IsA("Seat") then
				table.insert(seats, item)
			end
		end
		return seats
	end

	local function sail(boat, from, to)
		-- a gentle curve and a little roll, so it does not look like an elevator
		local value = Instance.new("NumberValue")
		local tween = TweenService:Create(value, TweenInfo.new(SAIL_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = 1 })
		local root = boat.PrimaryPart
		local connection = value.Changed:Connect(function(t)
			local arc = math.sin(t * math.pi)
			local offset = Vector3.new(arc * 22 * (to.Position.Z < from.Position.Z and 1 or -1), 0, 0)
			root.CFrame = from:Lerp(to, t) + offset
		end)
		tween:Play()
		tween.Completed:Wait()
		connection:Disconnect()
		value:Destroy()
		root.CFrame = to
	end

	local function unload(boat)
		local sent = 0
		for _, seat in seatsOf(boat) do
			local humanoid = seat.Occupant
			if humanoid then
				local player = Players:GetPlayerFromCharacter(humanoid.Parent)
				humanoid.Sit = false
				if player then
					sent += 1
					task.delay(0.1, function()
						moveTo(player, landing.CFrame + Vector3.new((sent % 5 - 2) * 4, 3, 0), "Island")
					end)
				end
			end
		end
	end

	for index, boat in boatsFolder:GetChildren() do
		local dock = boat.PrimaryPart.CFrame
		local shore = CFrame.new(Vector3.new(ISLAND_ORIGIN.X + (dock.Position.X - ISLAND_ORIGIN.X) * 0.35, dock.Position.Y, ISLAND_ORIGIN.Z + 214)) * dock.Rotation
		local info = { boat = boat, docked = false }
		table.insert(fleet, info)
		task.spawn(function()
			task.wait((index - 1) * ((SAIL_TIME * 2 + WAIT_DOCK + WAIT_LAND) / #boatsFolder:GetChildren()))
			while boat.Parent do
				info.docked = true
				task.wait(WAIT_DOCK)
				info.docked = false
				sail(boat, dock, shore)
				unload(boat)
				task.wait(WAIT_LAND)
				sail(boat, shore, dock)
			end
		end)
	end

	boardSpot:WaitForChild("BoardPrompt").Triggered:Connect(function(player)
		local _, _, humanoid = rootOf(player)
		if not humanoid or humanoid.Sit then
			return
		end
		for _, info in fleet do
			if info.docked then
				for _, seat in seatsOf(info.boat) do
					if not seat.Occupant then
						seat:Sit(humanoid)
						return
					end
				end
			end
		end
		remote:FireClient(player, "Notice", "The next boat is on its way.")
	end)
end
