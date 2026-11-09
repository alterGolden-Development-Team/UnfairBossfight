local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Motion = require(Shared:WaitForChild("Movement"):WaitForChild("R6DashMotion"))
local Classes = require(Shared.Classes.ClassConfig)
local Status = require(BossSystem.Combat.StatusEffectService)
local Immunity = require(BossSystem.Players.PlayerImmunity)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local api = {
	Cost = Motion.Cost,
	Duration = Motion.Duration,
	Immunity = Motion.Immunity,
	Distance = Motion.Distance,
	Cooldown = 0,
}
local states = {}
local remote
local function blocked(player, char, h, root)
	return not char
		or player.Character ~= char
		or not char.Parent
		or not h
		or h.Health <= 0
		or h.RigType ~= Enum.HumanoidRigType.R6
		or not root
		or root.Anchored
		or h.Sit
		or Status.IsMovementLocked(player)
		or char:GetAttribute("DashLocked")
		or char:GetAttribute("ShieldBreakDashLocked")
		or char:GetAttribute("TimeFrozen")
		or char:GetAttribute("ParryFrozen")
		or player:GetAttribute("ExecutionPending")
		or player:GetAttribute("PermanentlyDefeated")
end
local function filterFor(char)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local list = { char }
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character ~= char then
			table.insert(list, player.Character)
		end
	end
	for _, name in ipairs({ "GoldenSummons", "GoldenCombatEffects", "BossEncounterActors", "BossEncounterEffects" }) do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(list, folder)
		end
	end
	params.FilterDescendantsInstances = list
	return params
end
local function cancel(state)
	state.untilTime = 0
	if state.char.Parent and state.char:GetAttribute("Dashing") then
		state.char:SetAttribute("Dashing", false)
	end
end
function api.Cancel(player, reason)
	local state = states[player]
	if not state then
		return
	end
	cancel(state)
	if remote and state.lastRequest ~= -math.huge then
		remote:FireClient(player, state.lastRequest, false, reason or "interrupted")
	end
end
local function configure(player, char)
	local h = char:WaitForChild("Humanoid", 10)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not h or not root or player.Character ~= char then
		return
	end
	local previous = states[player]
	if previous then
		cancel(previous)
	end
	if not char:GetAttribute("ClassId") then
		local def = Classes.Classes[player:GetAttribute("PlayerClass")] or Classes.Classes[Classes.Default]
		char:SetAttribute("MaxStamina", def.Stamina)
		char:SetAttribute("Stamina", def.Stamina)
	end
	char:SetAttribute("Dashing", false)
	char:SetAttribute("DashMovementMode", "LocalNetworkOwner")
	Immunity.Refresh(char)
	states[player] = {
		char = char,
		h = h,
		root = root,
		regenAt = 0,
		untilTime = 0,
		sequence = 0,
		lastRequest = -math.huge,
		rateAt = 0,
		rateCount = 0,
		params = filterFor(char),
	}
end
function api.TryDash(player, direction, _, requestedAt)
	local state = states[player]
	if not state then
		return false, "character"
	end
	local now = workspace:GetServerTimeNow()
	if now - state.rateAt >= 1 then
		state.rateAt = now
		state.rateCount = 0
	end
	state.rateCount += 1
	if state.rateCount > 24 then
		return false, "rate"
	end
	local flat = Motion.FlatUnit(direction)
	if not flat then
		return false, "direction"
	end
	local char, h, root = state.char, state.h, state.root
	if blocked(player, char, h, root) then
		return false, "unavailable"
	end
	if type(requestedAt) ~= "number" or requestedAt ~= requestedAt or math.abs(now - requestedAt) > 1 then
		return false, "deadline"
	end
	 
	if requestedAt <= state.lastRequest then
		return false, "replay"
	end
	local stamina = char:GetAttribute("Stamina") or 0
	if stamina < (char:GetAttribute("ClassDashCost") or Motion.Cost) then
		return false, "stamina"
	end
	state.lastRequest = requestedAt
	local lag = math.clamp(now - requestedAt, 0, 0.15)
	state.sequence += 1
	state.direction = flat
	state.origin = root.Position
	state.lastSafe = root.CFrame
	local actionNow = Time.ActionNow(char)
	state.untilTime = actionNow + Motion.Duration - lag * Time.Rate(char)
	state.regenAt = actionNow + Motion.RegenDelay
	state.params = filterFor(char)
	char:SetAttribute("DashDirection", Motion.Kind(root, flat))
	char:SetAttribute("DashStartedAt", now - lag)
	char:SetAttribute("DashSequence", state.sequence)
	char:SetAttribute("Stamina", stamina - (char:GetAttribute("ClassDashCost") or Motion.Cost))
	char:SetAttribute("Dashing", true)
	Status.OnDash(char)
	Immunity.Grant(char, "DashInvulnerableUntil", char:GetAttribute("ClassDashImmunity") or Motion.Immunity)
	require(BossSystem.Presentation.CharacterEffects).Skill(char, "Dash", Motion.Duration)
	return true, nil, state.sequence, stamina - (char:GetAttribute("ClassDashCost") or Motion.Cost)
end
 
 
function api.AuthorizeStoredDash(player, character, direction, restraintToken)
	local state = states[player]
	local flat = Motion.FlatUnit(direction)
	if
		not state
		or state.char ~= character
		or player.Character ~= character
		or not flat
		or not character.Parent
		or state.h.Health <= 0
		or state.h.RigType ~= Enum.HumanoidRigType.R6
		or character:GetAttribute("TimeFrozen")
		or character:GetAttribute("ParryFrozen")
		or character:GetAttribute("ShieldBreakDashLocked")
		or player:GetAttribute("ExecutionPending")
		or player:GetAttribute("PermanentlyDefeated")
		or not Status.ExclusivelyRestrainedBy(character, restraintToken)
	then
		return false
	end
	local stamina = character:GetAttribute("Stamina") or 0
	if stamina < (character:GetAttribute("ClassDashCost") or Motion.Cost) then
		return false
	end
	state.regenAt = Time.ActionNow(character) + Motion.RegenDelay
	state.sequence += 1
	character:SetAttribute("Stamina", stamina - (character:GetAttribute("ClassDashCost") or Motion.Cost))
	character:SetAttribute("StoredDashReleasedAt", workspace:GetServerTimeNow())
	character:SetAttribute("StoredDashSequence", state.sequence)
	Status.OnDash(character)
	Immunity.Grant(character, "DashInvulnerableUntil", character:GetAttribute("ClassDashImmunity") or Motion.Immunity)
	require(BossSystem.Presentation.CharacterEffects).Skill(character, "Dash", Motion.Duration)
	return true, flat * Motion.Distance
end
function api.Start(dashRemote)
	if api.started then
		return
	end
	api.started = true
	remote = dashRemote
	local function joined(player)
		player.CharacterAdded:Connect(function(char)
			task.spawn(configure, player, char)
		end)
		player.CharacterRemoving:Connect(function(char)
			local state = states[player]
			if state and state.char == char then
				cancel(state)
				states[player] = nil
			end
		end)
		if player.Character then
			task.spawn(configure, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(function(player)
		local state = states[player]
		if state then
			cancel(state)
		end
		states[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		joined(player)
	end
	remote.OnServerEvent:Connect(function(player, direction, facing, requestedAt)
		local accepted, reason, sequence, stamina = api.TryDash(player, direction, facing, requestedAt)
		if reason == "rate" then
			return
		end
		if type(requestedAt) == "number" and requestedAt == requestedAt then
			remote:FireClient(player, requestedAt, accepted, reason, sequence, stamina)
		end
	end)
	local elapsed = 0
	Run.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.05 then
			return
		end
		local step = elapsed
		elapsed = 0
		local now = workspace:GetServerTimeNow()
		for player, state in pairs(states) do
			local char, h, root = state.char, state.h, state.root
			if blocked(player, char, h, root) then
				cancel(state)
				continue
			end
			local actionNow = Time.ActionNow(char)
			if state.untilTime > 0 then
				if actionNow >= state.untilTime then
					char:SetAttribute(
						"LastDashDistance",
						(Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(
							state.origin.X,
							0,
							state.origin.Z
						)).Magnitude
					)
					cancel(state)
				else
					 
					local delta = root.Position - state.lastSafe.Position
					local horizontal = Vector3.new(delta.X, 0, delta.Z)
					local distance = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(
						state.origin.X,
						0,
						state.origin.Z
					)).Magnitude
					local hit = horizontal.Magnitude > 0.01
						and workspace:Blockcast(state.lastSafe, Vector3.new(2.1, 3.4, 2.1), horizontal, state.params)
					if hit or distance > Motion.Distance + 4 then
						root.CFrame = state.lastSafe
						local velocity = root.AssemblyLinearVelocity
						root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
						char:SetAttribute("LastDashBlockedBy", hit and hit.Instance.Name or "DistanceGuard")
						cancel(state)
						remote:FireClient(player, state.lastRequest, false, "wall")
					else
						state.lastSafe = root.CFrame
					end
				end
			end
			if actionNow >= state.regenAt and not Status.IsRegenBlocked(char, "Stamina") then
				local stamina = char:GetAttribute("Stamina") or 0
				local nextValue = math.min(
					char:GetAttribute("MaxStamina") or Classes.Classes[Classes.Default].Stamina,
					stamina
						+ Classes.StaminaRegen
							* step
							* Time.Rate(char)
							* (char:GetAttribute("StaminaRegenMultiplier") or 1)
				)
				if nextValue ~= stamina then
					char:SetAttribute("Stamina", nextValue)
				end
			end
		end
	end)
end
return api
