local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Players = game:GetService("Players")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Status = require(BossSystem.Combat.StatusEffectService)
local records = setmetatable({}, { __mode = "k" })
local api = {}
local CYAN = Color3.fromRGB(119, 227, 255)
local GOLD = Color3.fromRGB(255, 216, 70)
local function ownerOf(actor)
	local reference = actor and actor:FindFirstChild("EncounterOwner")
	return reference and reference:IsA("ObjectValue") and reference.Value or actor
end
local function alive(player, character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return player.Parent == Players
		and player.Character == character
		and character.Parent
		and humanoid
		and humanoid.Health > 0
		and root
		and not player:GetAttribute("PermanentlyDefeated")
		and not player:GetAttribute("ViewAsServer")
		and not player:GetAttribute("ExecutionPending")
		and not character:GetAttribute("ExecutionPending")
end
local function vector(value, maxMagnitude)
	if
		typeof(value) ~= "Vector3"
		or value.X ~= value.X
		or value.Y ~= value.Y
		or value.Z ~= value.Z
		or math.abs(value.X) == math.huge
		or math.abs(value.Y) == math.huge
		or math.abs(value.Z) == math.huge
	then
		return Vector3.zero
	end
	return value.Magnitude > maxMagnitude and value.Unit * maxMagnitude or value
end
local function capture(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if
		not root
		or not Placement.Contains(root.Position, 4)
		or not Placement.GroundPoint(root.Position, { Margin = 4 })
	then
		return nil
	end
	return {
		Character = character,
		Root = root,
		Humanoid = character:FindFirstChildOfClass("Humanoid"),
		Frame = root.CFrame,
		Linear = vector(root.AssemblyLinearVelocity, 200),
		Angular = vector(root.AssemblyAngularVelocity, 25),
	}
end
local function mark(cast, snapshot, color)
	local point = Placement.GroundPoint(snapshot.Frame.Position, { Margin = 4 })
	local anchor = Effects.AcquirePart()
	anchor.Name = "SavedTimeMarker"
	anchor.Size = Vector3.one * 0.1
	anchor.CFrame = CFrame.new(point + Vector3.new(0, 0.14, 0))
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.Parent = Runtime.Effects
	cast:Add(anchor)
	local corners =
		{ Vector3.new(-2.5, 0, -2.5), Vector3.new(2.5, 0, -2.5), Vector3.new(2.5, 0, 2.5), Vector3.new(-2.5, 0, 2.5) }
	local attachments = {}
	for _, offset in ipairs(corners) do
		local attachment = Instance.new("Attachment")
		attachment.Position = offset
		attachment.Parent = anchor
		table.insert(attachments, attachment)
	end
	for index, attachment in ipairs(attachments) do
		local beam = Instance.new("Beam")
		beam.Name = "SavedTimeBoundary"
		beam.Attachment0 = attachment
		beam.Attachment1 = attachments[index % 4 + 1]
		beam.Color = ColorSequence.new(color)
		beam.Width0 = 0.12
		beam.Width1 = 0.12
		beam.FaceCamera = true
		beam.LightEmission = 0.6
		beam.Transparency = NumberSequence.new(0.35)
		beam.Parent = anchor
	end
	return anchor
end
local function publish(owner, ready, expires, count)
	if not owner or not owner.Parent then
		return
	end
	owner:SetAttribute("TimeSnapshotReady", ready)
	owner:SetAttribute("TimeSnapshotExpiresAt", expires or 0)
	owner:SetAttribute("TimeSnapshotSavedPlayerCount", count or 0)
end
local function valid(owner, record)
	local humanoid = owner and owner:FindFirstChildOfClass("Humanoid")
	local phase = owner and owner:GetAttribute("Phase")
	return record
		and owner.Parent
		and humanoid
		and humanoid.Health > 0
		and owner:FindFirstChild("HumanoidRootPart") == record.Boss.Root
		and not owner:GetAttribute("EncounterEnded")
		and owner:GetAttribute("AIEnabled") ~= false
		and not owner:GetAttribute("PhaseTransitionInProgress")
		and (phase == 2 or phase == 2.5)
		and (owner:GetAttribute("PhaseGeneration") or 0) == record.Generation
		and workspace:GetServerTimeNow() < record.ExpiresAt
		and not record.Cast.closed
end
function api.Clear(actor, reason)
	local owner = ownerOf(actor)
	local record = owner and records[owner]
	if not record then
		return false
	end
	records[owner] = nil
	publish(owner, false, 0, 0)
	record.Reason = reason or "Cleared"
	record.Cast:Dispose()
	return true
end
function api.Has(actor)
	local owner = ownerOf(actor)
	local record = owner and records[owner]
	if not valid(owner, record) then
		if record then
			api.Clear(owner, "Snapshot stale")
		end
		return false
	end
	return true
end
function api.Save(actor)
	local owner = ownerOf(actor)
	local humanoid = owner and owner:FindFirstChildOfClass("Humanoid")
	if
		not owner
		or not owner.Parent
		or not humanoid
		or humanoid.Health <= 0
		or owner:GetAttribute("EncounterEnded")
		or owner:GetAttribute("PhaseTransitionInProgress")
		or (owner:GetAttribute("Phase") ~= 2 and owner:GetAttribute("Phase") ~= 2.5)
	then
		return false
	end
	local boss = capture(owner)
	if not boss then
		return false
	end
	local targets = {}
	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if alive(player, character) then
			local snapshot = capture(character)
			if snapshot then
				targets[player] = snapshot
				count += 1
			end
		end
	end
	if count == 0 then
		return false
	end
	api.Clear(owner, "Overwritten")
	local age = math.clamp(Config.TimeSnapshotMaxAge or 20, 0.1, 20)
	local cast = Effects.NewCast(owner, "SharedTimeSnapshot", age + 0.1)
	cast.TimeStopExempt = true
	local record = {
		Boss = boss,
		Players = targets,
		Cast = cast,
		Generation = owner:GetAttribute("PhaseGeneration") or 0,
		StartedAt = workspace:GetServerTimeNow(),
		ExpiresAt = workspace:GetServerTimeNow() + age,
	}
	records[owner] = record
	boss.Marker = mark(cast, boss, GOLD)
	local function retire(player, snapshot)
		targets[player] = nil
		if snapshot.Died then
			snapshot.Died:Disconnect()
			snapshot.Died = nil
		end
		cast.objects[snapshot.Marker] = nil
		Effects.Release(snapshot.Marker)
	end
	for player, snapshot in pairs(targets) do
		snapshot.Marker = mark(cast, snapshot, CYAN)
		snapshot.Died = snapshot.Humanoid.Died:Connect(function()
			if records[owner] == record then
				retire(player, snapshot)
			end
		end)
	end
	owner:SetAttribute("TimeSaveSequence", (owner:GetAttribute("TimeSaveSequence") or 0) + 1)
	publish(owner, true, record.ExpiresAt, count)
	cast.OnDispose = function()
		for _, snapshot in pairs(targets) do
			if snapshot.Died then
				snapshot.Died:Disconnect()
				snapshot.Died = nil
			end
		end
		if records[owner] == record then
			records[owner] = nil
			publish(owner, false, 0, 0)
		end
	end
	local elapsed = 0
	cast:Step(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return true
		end
		elapsed = 0
		if not valid(owner, record) then
			api.Clear(owner, "Snapshot expired or encounter changed")
			return false
		end
		local remaining = 0
		for player, snapshot in pairs(targets) do
			if not alive(player, snapshot.Character) or snapshot.Root.Parent ~= snapshot.Character then
				retire(player, snapshot)
			else
				remaining += 1
			end
		end
		owner:SetAttribute("TimeSnapshotSavedPlayerCount", remaining)
		return true
	end)
	return true, count
end
local function restore(snapshot, frame)
	snapshot.Root.CFrame = frame
	snapshot.Root.AssemblyLinearVelocity = snapshot.Linear
	snapshot.Root.AssemblyAngularVelocity = snapshot.Angular
end
function api.Load(actor)
	local owner = ownerOf(actor)
	if not api.Has(owner) then
		return false, 0
	end
	local record = records[owner]
	local loaded = 0
	for player, snapshot in pairs(record.Players) do
		if
			alive(player, snapshot.Character)
			and snapshot.Root.Parent == snapshot.Character
			and not snapshot.Root.Anchored
			and not Status.IsLocked(player)
			and not Status.IsMovementLocked(player)
			and not snapshot.Character:GetAttribute("TimeFrozen")
		then
			local frame =
				Placement.ResolveRecorded(snapshot.Character, snapshot.Frame, { Margin = 4, SearchRadius = 12 })
			if frame then
				require(BossSystem.Players.R6DashService).Cancel(player, "Time Load")
				restore(snapshot, frame)
				loaded += 1
				snapshot.Character:SetAttribute(
					"TimeLoadSequence",
					(snapshot.Character:GetAttribute("TimeLoadSequence") or 0) + 1
				)
			end
		end
	end
	local bossFrame = Placement.ResolveRecorded(owner, record.Boss.Frame, { Margin = 4, SearchRadius = 12 })
	 
	 
	if bossFrame and not owner:GetAttribute("TimeFrozen") and not owner:GetAttribute("ExecutionPending") then
		owner:SetAttribute("MovementRevision", (owner:GetAttribute("MovementRevision") or 0) + 1)
		restore(record.Boss, bossFrame)
	else
		bossFrame = nil
	end
	owner:SetAttribute("TimeLoadSequence", (owner:GetAttribute("TimeLoadSequence") or 0) + 1)
	owner:SetAttribute("TimeLoadAffectedPlayerCount", loaded)
	owner:SetAttribute("TimeLoadBossRestored", bossFrame ~= nil)
	api.Clear(owner, "Loaded")
	return loaded > 0 or bossFrame ~= nil, loaded
end
function api.Stats(actor)
	local ready = api.Has(actor)
	local owner = ownerOf(actor)
	local record = owner and records[owner]
	local count = 0
	if record then
		for _ in pairs(record.Players) do
			count += 1
		end
	end
	return { Ready = ready, PlayerCount = count, ExpiresAt = record and record.ExpiresAt or 0 }
end
return api
