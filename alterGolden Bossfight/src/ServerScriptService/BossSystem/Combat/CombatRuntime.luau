local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local BossSystem = script:FindFirstAncestor("BossSystem")
 
local Players = game:GetService("Players")
local api = {}
local characters, targets = {}, {}
local charSet, targetSet = {}, {}
local humanoidModels = {}
local version = 0
local knockbacks = setmetatable({}, { __mode = "k" })
local function add(list, set, value)
	if not set[value] then
		set[value] = true
		table.insert(list, value)
		version += 1
	end
end
local function remove(list, set, value)
	if set[value] then
		set[value] = nil
		local i = table.find(list, value)
		if i then
			table.remove(list, i)
		end
		version += 1
	end
end
local function joined(player)
	player.CharacterAdded:Connect(function(char)
		add(characters, charSet, char)
	end)
	player.CharacterRemoving:Connect(function(char)
		remove(characters, charSet, char)
	end)
	if player.Character then
		add(characters, charSet, player.Character)
	end
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(p)
	if p.Character then
		remove(characters, charSet, p.Character)
	end
end)
for _, p in ipairs(Players:GetPlayers()) do
	joined(p)
end
local function descendant(v)
	if v:IsA("Humanoid") and v.Parent and v.Parent:IsA("Model") then
		humanoidModels[v] = v.Parent
		add(targets, targetSet, v.Parent)
	end
end
for _, v in ipairs(workspace:GetDescendants()) do
	descendant(v)
end
workspace.DescendantAdded:Connect(descendant)
workspace.DescendantRemoving:Connect(function(v)
	if v:IsA("Humanoid") then
		 
		local model = humanoidModels[v]
		if model then
			remove(targets, targetSet, model)
		end
		humanoidModels[v] = nil
	end
end)
local actors = workspace:FindFirstChild("GoldenSummons") or Instance.new("Folder", workspace)
actors.Name = "GoldenSummons"
local effects = workspace:FindFirstChild("GoldenCombatEffects") or Instance.new("Folder", workspace)
effects.Name = "GoldenCombatEffects"
-- Callers may supply a private buffer to avoid allocating on every collision check.
function api.Characters(result)
	result = result or {}
	table.clear(result)
	for _, character in ipairs(characters) do
		local h = character:FindFirstChildOfClass("Humanoid")
  if character.Parent and h and h.Health > 0 and not Observer.IsCharacter(character) then
			table.insert(result, character)
		end
	end
	return result
end
 
function api.AllTargets()
	return targets
end
function api.Targets(result)
	result = result or {}
	table.clear(result)
	for _, character in ipairs(targets) do
		local h = character:FindFirstChildOfClass("Humanoid")
  if character.Parent and h and h.Health > 0 and not character:GetAttribute("AttackAimOnly") and not Observer.IsCharacter(character) then
			table.insert(result, character)
		end
	end
	return result
end
local function aimContainerChanged(child)
	if child.Name == "BossAttackAimTargets" then
		version += 1
	end
end
workspace.ChildAdded:Connect(aimContainerChanged)
workspace.ChildRemoved:Connect(aimContainerChanged)
function api.FilterFor(boss, localEffects)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.RespectCanCollide = true
	local last = -1
	return function()
		if last ~= version then
			local exclude = { boss, actors, effects }
   local aim = workspace:FindFirstChild("BossAttackAimTargets")
   if aim then table.insert(exclude, aim) end
			if localEffects then
				table.insert(exclude, localEffects)
			end
			for _, char in ipairs(characters) do
				table.insert(exclude, char)
			end
			p.FilterDescendantsInstances = exclude
			last = version
		end
		return p
	end
end
api.Summons = actors
api.Effects = effects
function api.Knockback(actor, character, direction, options)
	if Observer.IsCharacter(character) then
		return
	end
	if actor and actor:GetAttribute("IsIllusion") then
		return
	end
	options = options or {}
	local Effects = require(BossSystem.Combat.EffectService)
	local Dash = require(BossSystem.Players.R6DashService)
	 
	local fixed = options.UnscaledDifficulty == true and actor
    and require(BossSystem.Combat.AbilityMetadata).Get(actor:GetAttribute("CurrentSkill"))
  local push = fixed and fixed.UnscaledDifficulty and 1
    or require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Mercy("Knockback", actor) or 1
	local speed = (options.Speed or 85) * push
	local lift = (options.Lift or 30) * push
	local hold = options.Duration or 0.4
	local sustain = options.Sustain or 0.22
	-- Phase 5 knockbacks never stun: the server owns the player only for a blink and never cancels their dash
	local skillName = actor and actor:GetAttribute("CurrentSkill")
	local noStun = type(skillName) == "string" and string.sub(skillName, 1, 2) == "P5"
	if noStun and Players:GetPlayerFromCharacter(character) then return end  -- Phase 5 never pushes or stuns players
	if noStun then hold = math.min(hold, 0.1) sustain = math.min(sustain, 0.02) end
	local r = character:FindFirstChild("HumanoidRootPart")
	local h = character:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)
	if not r or r.Anchored or not h or h.Health <= 0 then
		return
	end
	if not options.TransitionControl and (require(BossSystem.Combat.StatusEffectService).IsDebuffImmune(character)
  or require(BossSystem.Combat.StatusEffectService).IsUninterrupted(character)) then
		return
	end
	local previous = knockbacks[r]
	if previous then
		previous:Dispose()
	end
	if player and not options.AllowPlayerControl and not noStun then
		Dash.Cancel(player, "boss knockback")
	end

	local queriedAuto, automatic = pcall(function()
		return r:GetNetworkOwnershipAuto()
	end)
	local queriedOwner, priorOwner = pcall(function()
		return r:GetNetworkOwner()
	end)
	automatic = not queriedAuto or automatic
	if not queriedOwner then
		priorOwner = player
	end
	 
	local tookOwnership = false
	if not (player and (options.AllowPlayerControl or noStun)) then
		tookOwnership = pcall(function()
			r:SetNetworkOwner(nil)
		end)
	end
	local cast = Effects.NewCast(actor, "EncounterKnockback", hold)
	if options.ContainsArena then
		cast.TimeStopExempt = true
	end
	knockbacks[r] = cast
	 
	 
	local contain
	if options.ContainsArena then
		local Placement = require(BossSystem.Encounter.ArenaPlacement)
		local bounds = Placement.GetBounds()
		if bounds then
			local margin = 6
			local leg = character:FindFirstChild("Right Leg") or character:FindFirstChild("Left Leg")
			local standing = r.Size.Y * 0.5
				+ h.HipHeight
				+ (h.RigType == Enum.HumanoidRigType.R6 and (leg and leg.Size.Y or 2) or 0)
			local bodySize = Vector3.new(3.4, math.max(standing + 2.4, 4), 3.4)
			local getFilter = api.FilterFor(character)
			local lastPosition = r.Position
			local lastGrounded = Placement.Validate(character, r.CFrame, { Margin = margin })
			local sampled = 0
			local function groundFrame(point)
				local ground = Placement.GroundPoint(point, { Margin = margin, Clamp = true })
				if not ground then
					return
				end
				local desired = CFrame.new(ground + Vector3.new(0, standing, 0)) * r.CFrame.Rotation
				return Placement.Validate(character, desired, { Margin = margin })
					or Placement.ResolveRecorded(character, desired, { Margin = margin, SearchRadius = 12 })
			end
			lastGrounded = lastGrounded or groundFrame(r.Position)
			contain = function(dt)
				local position, velocity = r.Position, r.AssemblyLinearVelocity
				local moved = position - lastPosition
				local changed = false
				if moved.Magnitude > 0.01 then
					local hit = workspace:Blockcast(CFrame.new(lastPosition), bodySize, moved, getFilter())
					if hit then
						position = lastPosition + moved.Unit * math.max(0, hit.Distance - 0.12)
						local inward = velocity:Dot(hit.Normal)
						if inward < 0 then
							velocity -= hit.Normal * inward
						end
						changed = true
					end
				end
				local localPoint = bounds.Frame:PointToObjectSpace(position)
				local x = math.clamp(localPoint.X, -bounds.HalfX + margin, bounds.HalfX - margin)
				local z = math.clamp(localPoint.Z, -bounds.HalfZ + margin, bounds.HalfZ - margin)
				local localVelocity = bounds.Frame:VectorToObjectSpace(velocity)
				if
					localPoint.X <= -bounds.HalfX + margin and localVelocity.X < 0
					or localPoint.X >= bounds.HalfX - margin and localVelocity.X > 0
				then
					localVelocity = Vector3.new(0, localVelocity.Y, localVelocity.Z)
				end
				if
					localPoint.Z <= -bounds.HalfZ + margin and localVelocity.Z < 0
					or localPoint.Z >= bounds.HalfZ - margin and localVelocity.Z > 0
				then
					localVelocity = Vector3.new(localVelocity.X, localVelocity.Y, 0)
				end
				velocity = bounds.Frame:VectorToWorldSpace(localVelocity)
				if x ~= localPoint.X or z ~= localPoint.Z then
					position = bounds.Frame:PointToWorldSpace(Vector3.new(x, localPoint.Y, z))
					changed = true
				end
				if position.Y < bounds.Frame.Y + standing - 0.75 then
					local recovery = groundFrame(position) or lastGrounded
					if recovery then
						position = recovery.Position
						velocity = Vector3.zero
						changed = true
					end
				end
				if changed then
					r.CFrame = CFrame.new(position) * r.CFrame.Rotation
				end
				r.AssemblyLinearVelocity = velocity
				lastPosition = position
				sampled += (dt or 0)
				if sampled >= 0.15 then
					sampled = 0
					lastGrounded = groundFrame(position) or lastGrounded
				end
			end
			contain(0)
		end
	end
	local restored = false
	local function restore()
		if restored then
			return
		end
		restored = true
		if knockbacks[r] ~= cast then
			return
		end
		knockbacks[r] = nil
		if
			not tookOwnership
			or not r.Parent
			or Observer.IsCharacter(character)
			or not character.Parent
			or h.Health <= 0
			or r.Anchored
			or (player and (player.Parent ~= Players or player.Character ~= character))
		then
			return
		end
		if options.ContainsArena and not character:GetAttribute("Dashing") then
			 
			 
			local velocity = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
		end
		local ok = pcall(function()
			if automatic or (priorOwner and priorOwner.Parent ~= Players) then
				r:SetNetworkOwnershipAuto()
			else
				r:SetNetworkOwner(priorOwner)
			end
		end)
		if not ok and not r.Anchored then
			pcall(function()
				r:SetNetworkOwnershipAuto()
			end)
		end
	end
	cast.OnExpire = restore
	cast.OnDispose = restore
	local away = Vector3.new(direction.X, 0, direction.Z)
	if away.Magnitude < 0.1 then
		away = Vector3.new(0, 0, -1)
	end
	local velocity = away.Unit * speed + Vector3.new(0, lift, 0)
	local mass = math.max(r.AssemblyMass, 0.001)
	if noStun and player then
		-- no ownership swap and no state change: a short constraint shoves the player on their own client, so they never lose control
		local att = Instance.new("Attachment")
		att.Name = "KnockAttachment"
		att.Parent = r
		local lv = Instance.new("LinearVelocity")
		lv.Name = "KnockShove"
		lv.Attachment0 = att
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		lv.VectorVelocity = velocity
		lv.MaxForce = mass * 4000
		lv.Parent = r
		task.delay(math.max(hold, 0.08), function()
			lv:Destroy()
			att:Destroy()
		end)
	else
		h:ChangeState(Enum.HumanoidStateType.Freefall)
		r:ApplyImpulse((velocity - r.AssemblyLinearVelocity) * mass)
		r.AssemblyLinearVelocity = velocity
	end
	local began = cast:Now()
	cast:Step(function(dt, now)
		if
			not r.Parent
			or r.Anchored
			or not character.Parent
			or h.Health <= 0
			or (player and (player.Parent ~= Players or player.Character ~= character))
			or not options.TransitionControl and (require(BossSystem.Combat.StatusEffectService).IsDebuffImmune(character)
    or require(BossSystem.Combat.StatusEffectService).IsUninterrupted(character))
			or character:GetAttribute("Dashing")
		then
			cast:Dispose()
			return false
		end
		 
		 
		 
		local elapsed = now - began
		if tookOwnership and elapsed < sustain then
			local current = r.AssemblyLinearVelocity
			local horizontal = away.Unit * (speed * (1 - 0.24 * math.clamp(elapsed / sustain, 0, 1)))
			r.AssemblyLinearVelocity = Vector3.new(horizontal.X, current.Y, horizontal.Z)
		end
		if contain then
			contain(dt)
		end
		return true
	end)
	return cast
end

return api
