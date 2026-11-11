--!nonstrict
--[[
 RealityOrb - the mysterious orb hidden somewhere outside the Golden Encounter's walls (the Reality Disorderer quest).
 Every server picks a new random spot in the dunes around the castle (RNG), sets the Blender OrbShrine there (MeshKit "Props") and
 floats the orb in its cradle, with a faint flickering thread of light rising from it so the curious can find it. Hold E to take it:
 it is saved to your record (UnfairShared/RecordStore, Items.RealityOrb, at most one) and shows in your inventory (the bag icon).
 Bring it to the man at the end of the glitched place (reached from the Divided Wood in the lobby) to unlock the Reality Disorderer.
 Each player can take one; the orb stays for everyone else. Also publishes the `Inventory` player attribute when a player joins.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local api = {}
local started = false

local MIN_RADIUS, MAX_RADIUS = 430, 640 -- studs from the arena's centre: past the castle walls, inside the dunes
local CASTLE = Vector3.new(0, 0, 0)
local PINK, CYAN = Color3.fromRGB(255, 80, 225), Color3.fromRGB(70, 235, 255)

local function shared()
	local folder = ReplicatedStorage:WaitForChild("UnfairShared")
	return require(folder.RecordStore), require(folder.ItemConfig)
end

local function publish(player, record)
	local RecordStore = shared()
	RecordStore.PublishInventory(player, record)
end

-- a random point on the sand outside the walls, not on a tree, a spire or the gate court
local function pickSpot(rng)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local arena = workspace:FindFirstChild("GoldenGrasslandArena")
	local ignore = {}
	for _, name in { "CastleKnockbackBarriers", "ExteriorBoundary", "PollenField" } do
		local item = arena and arena:FindFirstChild(name)
		if item then
			table.insert(ignore, item)
		end
	end
	params.FilterDescendantsInstances = ignore
	for _ = 1, 60 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(MIN_RADIUS, MAX_RADIUS)
		local x, z = CASTLE.X + math.cos(a) * r, CASTLE.Z + math.sin(a) * r * 0.85
		local hit = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), params)
		if hit and hit.Instance == workspace.Terrain and hit.Position.Y > -10 and hit.Normal.Y > 0.85 then
			return hit.Position
		end
	end
	return Vector3.new(-470, 4, 140) -- a known patch of sand south-west of the gate
end

local function buildShrine(at)
	local model = Instance.new("Model")
	model.Name = "RealityOrbShrine"
	local ok, MeshKit = pcall(function()
		return require(ReplicatedStorage.BossShared.Presentation.MeshKit)
	end)
	local shrine = ok and MeshKit.Get("OrbShrine")
	local orbHeight = 6.2
	if shrine then
		shrine:PivotTo(CFrame.new(at - Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
		shrine.Parent = model
	else
		local base = Instance.new("Part")
		base.Name = "Pedestal"
		base.Size = Vector3.new(2.4, 4, 2.4)
		base.CFrame = CFrame.new(at + Vector3.new(0, 2, 0))
		base.Anchored = true
		base.Material = Enum.Material.Slate
		base.Color = Color3.fromRGB(150, 142, 128)
		base.Parent = model
		orbHeight = 5.2
	end
	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1.6, 1.6, 1.6)
	orb.CFrame = CFrame.new(at + Vector3.new(0, orbHeight, 0))
	orb.Anchored, orb.CanCollide, orb.CanTouch = true, false, false
	orb.Material = Enum.Material.Neon
	orb.Color = PINK
	orb.Parent = model
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = PINK, 16, 2
	light.Parent = orb
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(PINK, CYAN)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(0.8, 1.6)
	sparks.Rate = 14
	sparks.Speed = NumberRange.new(0.5, 2)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Parent = orb
	-- a thin glitching thread of light up into the sky: visible from the walls if you look for it
	local top = Instance.new("Part")
	top.Name = "ThreadTop"
	top.Size = Vector3.new(0.2, 0.2, 0.2)
	top.Transparency = 1
	top.Anchored, top.CanCollide, top.CanQuery, top.CanTouch = true, false, false, false
	top.CFrame = CFrame.new(at + Vector3.new(0, 140, 0))
	top.Parent = model
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = orb, top
	local beam = Instance.new("Beam")
	beam.Name = "Thread"
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Width0, beam.Width1 = 0.5, 0.05
	beam.Color = ColorSequence.new(PINK, CYAN)
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	beam.FaceCamera = true
	beam.Parent = orb
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakePrompt"
	prompt.ActionText = "Take"
	prompt.ObjectText = "Mysterious Orb"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = orb
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	model.Parent = workspace
	-- the orb bobs and the thread flickers (server side, cheap: 10 Hz)
	task.spawn(function()
		local home = orb.CFrame
		local t = 0
		while model.Parent do
			t += task.wait(0.1)
			orb.CFrame = home * CFrame.new(0, math.sin(t * 1.6) * 0.25, 0) * CFrame.Angles(0, t * 0.8, 0)
			orb.Color = math.random() < 0.15 and CYAN or PINK
			beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, math.random() < 0.2 and 0.9 or 0.25), NumberSequenceKeypoint.new(1, 1) })
		end
	end)
	return model, prompt
end

local function notify(player, text)
	local remote = ReplicatedStorage:FindFirstChild("RealityOrbNotice")
	if remote then
		remote:FireClient(player, text)
	end
end

function api.Start()
	if started then
		return
	end
	started = true
	local remote = Instance.new("RemoteEvent")
	remote.Name = "RealityOrbNotice"
	remote.Parent = ReplicatedStorage
	local RecordStore, ItemConfig = shared()
	-- everyone's inventory, so the bag icon shows what they carry here too
	local function onPlayer(player)
		task.spawn(function()
			local ok, record = RecordStore.Read(player.UserId)
			if ok and player.Parent == Players then
				publish(player, record)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	local rng = Random.new()
	local at = pickSpot(rng)
	workspace:SetAttribute("RealityOrbAt", at)
	local _, prompt = buildShrine(at)
	local busy = {}
	prompt.Triggered:Connect(function(player)
		if busy[player] then
			return
		end
		busy[player] = true
		local def = ItemConfig.Items.RealityOrb
		local worked, applied, record = RecordStore.AddItem(player.UserId, "RealityOrb", 1, def.Limit)
		if not worked then
			notify(player, RunService:IsStudio() and "(Studio) the orb could not be saved: turn on API access to test it." or "The orb slips away. Try again in a moment.")
		elseif applied then
			publish(player, record)
			notify(player, "You found the Reality Orb. Something at the end of a broken place is waiting for it.")
		else
			notify(player, "The orb hums at you. You already carry one.")
		end
		task.delay(2, function()
			busy[player] = nil
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return api
