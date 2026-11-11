local BossSystem = script:FindFirstAncestor("BossSystem")
local Observer = require(BossSystem.Players.PlayerObserver)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local api = {}
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local clocks = setmetatable({}, { __mode = "k" })
local decelerations = setmetatable({}, { __mode = "k" })
local accelerations = setmetatable({}, { __mode = "k" })
local playerTimers = {}
local stops = {}
local frozenParts, frozenCharacters, frozenTracks, frozenParticles = {}, {}, {}, {}
local freezeAdded
local realAt = os.clock()
local encounterTime = realAt
local stopSequence = 0
local deferred = setmetatable({}, { __mode = "k" })
local deferredOrder = setmetatable({}, { __mode = "k" })
local deferredTouched = setmetatable({}, { __mode = "k" })
local deferredSequence = 0
local collapseQueues = setmetatable({}, { __mode = "k" })
local function event(kind, data)
	local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
	if remote then
		remote:FireAllClients(kind, data)
	end
end
local function ownerOf(actor)
	if not actor then
		return nil
	end
	local ref = actor:FindFirstChild("EncounterOwner")
	return ref and ref:IsA("ObjectValue") and ref.Value or actor
end
local function valid(character)
	local h = character and character:FindFirstChildOfClass("Humanoid")
	return character and character.Parent and h and h.Health > 0
end
local function set(instance, key, value)
	if instance and instance.Parent and instance:GetAttribute(key) ~= value then
		instance:SetAttribute(key, value)
	end
end
local function publish(character, key, value)
	set(character, key, value)
	local player = Players:GetPlayerFromCharacter(character)
	if player and player.Character == character then
		set(player, key, value)
	end
end
local function exempt(instance)
	local ancestor = instance
	while ancestor and ancestor ~= workspace do
		if ancestor:GetAttribute("TimeStopExempt") == true
			or ancestor:IsA("Model") and Observer.IsCharacter(ancestor) then
			return true
		end
		ancestor = ancestor.Parent
	end
	for token in pairs(stops) do
		if instance == token.owner or instance:IsDescendantOf(token.owner) then
			return true
		end
	end
	return false
end
function api.IsStopped(_actor)
	return next(stops) ~= nil
end
function api.ActiveStop(actor)
	local owner = ownerOf(actor)
	for handle in pairs(stops) do
		if not handle.closed and handle.owner == owner then
			return handle
		end
	end
end
function api.IsGoldenHour(actor)
	return api.ActiveStop(actor) ~= nil
end
 
 
function api.RegisterDeferred(actor, token)
	deferredSequence += 1
	deferredOrder[token] = deferredSequence
	deferredTouched[token] = 0
	deferred[token] = ownerOf(actor)
	return token
end
function api.UnregisterDeferred(token)
	deferred[token] = nil
	deferredOrder[token] = nil
	deferredTouched[token] = nil
end
local function deferredAlive(token)
	local ok, result = xpcall(token.Alive, debug.traceback)
	if not ok then
		warn("Temporal deadline validity: " .. tostring(result))
	end
	return ok and result
end
local function deferredAdvance(token, seconds, force)
	if not deferredAlive(token) then
		api.UnregisterDeferred(token)
		return false
	end
	local ok, result = xpcall(token.Advance, debug.traceback, seconds, force)
	if not ok then
		warn("Temporal deadline advance: " .. tostring(result))
		api.UnregisterDeferred(token)
	end
	return ok and result
end
local function selectedDeferred(owner)
	local selected = {}
	for token, boss in pairs(deferred) do
		if not deferredAlive(token) then
			api.UnregisterDeferred(token)
		elseif boss == owner then
			table.insert(selected, token)
		end
	end
	table.sort(selected, function(a, b)
		local ta, tb = deferredTouched[a] or 0, deferredTouched[b] or 0
		return ta == tb and (deferredOrder[a] or 0) < (deferredOrder[b] or 0) or ta < tb
	end)
	return selected
end
 
 
function api.FlushDeferred(actor, options)
	local owner = ownerOf(actor)
	options = options or {}
	local queue = collapseQueues[owner]
	if not queue then
		queue = {
			Items = {},
			Seen = {},
			Index = 1,
			At = os.clock(),
			Generation = owner:GetAttribute("PhaseGeneration") or 0,
		}
		collapseQueues[owner] = queue
	end
	queue.MaxCount = math.clamp(options.MaxCount or 4, 1, 8)
	queue.Interval = math.clamp(options.Interval or options.Stagger or 0.15, 0.05, 0.5)
	local added = 0
	for _, token in ipairs(selectedDeferred(owner)) do
		if not queue.Seen[token] then
			queue.Seen[token] = true
			table.insert(queue.Items, token)
			added += 1
		end
	end
	return added
end
function api.AdvanceDeferred(actor, seconds, force, options)
	local owner = ownerOf(actor)
	local changed = 0
	if force and options and options.Stagger then
		return api.FlushDeferred(owner, options)
	end
	local selected = selectedDeferred(owner)
	local limit = options and math.clamp(options.MaxCount or 4, 1, 8) or #selected
	for index, token in ipairs(selected) do
		if index > limit then
			break
		end
		deferredTouched[token] = os.clock()
		if deferredAdvance(token, math.clamp(seconds or 0, 0, 60), force == true) then
			changed += 1
		end
	end
	return changed
end
 
 
 
function api.WaitForActor(actor)
	if not actor or not actor.Parent then
		return false
	end
	if not actor:GetAttribute("TimeFrozen") then
		return true
	end
	repeat
		local owner = ownerOf(actor)
		if
			not valid(actor)
			or actor:GetAttribute("AIEnabled") == false
			or actor:GetAttribute("EncounterEnded")
			or not valid(owner)
			or owner:GetAttribute("AIEnabled") == false
			or owner:GetAttribute("EncounterEnded")
		then
			return false
		end
		Run.Heartbeat:Wait()
	until not actor:GetAttribute("TimeFrozen")
	return valid(actor) and actor:GetAttribute("AIEnabled") ~= false and not actor:GetAttribute("EncounterEnded")
end
local currentBossRate
local function currentRate(character)
	if character:GetAttribute("TimeFrozen") then
		return 0
	end
	local entry = decelerations[character]
	if entry and entry.expires > os.clock() then
		return 0.5
	end
	return Players:GetPlayerFromCharacter(character) and 1 or currentBossRate(character)
end
currentBossRate = function(actor)
	if actor:GetAttribute("TimeFrozen") then
		return 0
	end
	local entry = accelerations[actor]
	return entry and entry.expires > os.clock() and 1.5 or 1
end
local function currentCooldownRate(actor)
	if actor:GetAttribute("TimeFrozen") then
		return 0
	end
	if Players:GetPlayerFromCharacter(actor) then
		return currentRate(actor)
	end
	return currentBossRate(actor) > 1 and 2 or 1
end
local function updateClock(character)
	local now = os.clock()
	local clock = clocks[character]
	if not clock then
		clock = {
			action = now,
			cooldown = now,
			at = now,
			rate = currentRate(character),
			cooldownRate = currentCooldownRate(character),
		}
		clocks[character] = clock
	end
	local delta = math.max(0, now - clock.at)
	clock.action += delta * clock.rate
	clock.cooldown += delta * clock.cooldownRate
	clock.at = now
	clock.rate = currentRate(character)
	clock.cooldownRate = currentCooldownRate(character)
	return clock
end
function api.Rate(character)
	if not character then
		return 1
	end
	return updateClock(character).rate
end
function api.ActionNow(character)
	return character and updateClock(character).action or os.clock()
end
function api.CooldownNow(character)
	return character and updateClock(character).cooldown or os.clock()
end
function api.BossRate(actor)
	return actor and currentBossRate(actor) or 1
end
function api.BossDelta(actor, dt)
	return dt * api.BossRate(actor)
end
function api.EncounterNow(_actor)
	local now = os.clock()
	if next(stops) == nil then
		encounterTime += math.max(0, now - realAt)
	end
	realAt = now
	return encounterTime
end
function api.EncounterDelta(_actor, dt)
	return next(stops) == nil and dt or 0
end

local function cooldownRate(character, key)
	if key ~= "DefensiveReadyAt" and key ~= "BlessingReadyAt" then return 1 end
	return math.clamp(character:GetAttribute("CooldownRecoveryRate") or 1, 0, 1)
end
local function playerTimerRemaining(key, entry)
	local now = api.ActionNow(entry.character)
	local elapsed = math.max(0, now - (entry.lastAction or now))
	entry.deadline += elapsed * (1 - cooldownRate(entry.character, key))
	entry.lastAction = now
	return math.max(0, entry.deadline - now)
end
function api.RefreshPlayerCooldowns(character)
	local player = character and Players:GetPlayerFromCharacter(character)
	for key, entry in pairs(player and playerTimers[player] or {}) do
		if entry.character == character then playerTimerRemaining(key, entry) end
	end
end
function api.SetPlayerTimer(character, key, seconds)
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local timers = playerTimers[player] or {}
	playerTimers[player] = timers
	timers[key] = { character = character, deadline = api.ActionNow(character) + math.max(0, seconds), lastAction = api.ActionNow(character) }
	local rate = api.Rate(character)
	player:SetAttribute(key, workspace:GetServerTimeNow() + seconds / (rate > 0 and rate or 1))
end
function api.PlayerTimerRemaining(player, key)
	local entry = playerTimers[player] and playerTimers[player][key]
	if not entry then
		return math.max(0, (player:GetAttribute(key) or 0) - workspace:GetServerTimeNow())
	end
	if player.Character ~= entry.character then
		playerTimers[player][key] = nil
		player:SetAttribute(key, 0)
		return 0
	end
	return playerTimerRemaining(key, entry)
end
function api.PlayerTimerReady(player, key)
	return api.PlayerTimerRemaining(player, key) <= 0
end
function api.ClearPlayerTimer(player, key)
	if playerTimers[player] then
		playerTimers[player][key] = nil
	end
	if player.Parent then
		player:SetAttribute(key, 0)
	end
end

function api.ApplyDeceleration(character, seconds)
	if not valid(character) or Observer.IsCharacter(character) then
		return nil
	end
	updateClock(character)
	local existing = decelerations[character]
	if existing and not existing.closed then
		return nil, "active"
	end
	local owner = workspace:FindFirstChild("alterGolden, the Nothing")
	local handle = {
		character = character,
		owner = owner,
		generation = owner and (owner:GetAttribute("PhaseGeneration") or 0),
		expires = os.clock() + seconds,
		closed = false,
	}
	decelerations[character] = handle
	publish(character, "DecelerationUntil", workspace:GetServerTimeNow() + seconds)
	publish(character, "TemporalRate", 0.5)
	function handle:Dispose()
		if self.closed then
			return
		end
		self.closed = true
		updateClock(character)
		if decelerations[character] == self then
			decelerations[character] = nil
		end
		publish(character, "DecelerationUntil", 0)
		publish(character, "TemporalRate", character:GetAttribute("TimeFrozen") and 0 or 1)
		updateClock(character)
		require(BossSystem.Combat.StatusEffectService).RefreshMovement(character)
	end
	updateClock(character)
	require(BossSystem.Combat.StatusEffectService).RefreshMovement(character)
	return handle
end

function api.ClearDeceleration(character)
 local handle = decelerations[character]
 if handle then handle:Dispose() end
end

function api.AccelerateBoss(actor, seconds)
	if not valid(actor) then
		return nil
	end
	updateClock(actor)
	local old = accelerations[actor]
	if old and not old.closed then
		return nil, "active"
	end
	local h = actor:FindFirstChildOfClass("Humanoid")
	local owner = ownerOf(actor)
	local handle = {
		owner = owner,
		actor = actor,
		generation = owner:GetAttribute("PhaseGeneration") or 0,
		expires = os.clock() + seconds,
		closed = false,
		baseSpeed = h.WalkSpeed,
	}
	accelerations[actor] = handle
	set(actor, "AccelerationUntil", workspace:GetServerTimeNow() + seconds)
	set(actor, "AccelerationActive", true)
	set(actor, "CombatSpeedMultiplier", 1.5)
	set(actor, "CooldownMultiplier", 0.5)
	set(actor, "AttackDelayMultiplier", 0.5)
	h.WalkSpeed = handle.baseSpeed * 1.5
	function handle:Dispose()
		if self.closed then
			return
		end
		self.closed = true
		updateClock(actor)
		if accelerations[actor] == self then
			accelerations[actor] = nil
		end
		set(actor, "AccelerationUntil", 0)
		set(actor, "AccelerationActive", false)
		set(actor, "CombatSpeedMultiplier", 1)
		set(actor, "CooldownMultiplier", 1)
		set(actor, "AttackDelayMultiplier", 1)
		if h.Parent and math.abs(h.WalkSpeed - self.baseSpeed * 1.5) < 0.01 then
			h.WalkSpeed = self.baseSpeed
		end
		updateClock(actor)
	end
	updateClock(actor)
	return handle
end

local function freezeTrack(track, character)
	if frozenTracks[track] ~= nil then
		return
	end
	frozenTracks[track] = { speed = track.Speed, character = character }
	track:AdjustSpeed(0)
end
local function snapshotPart(assembly)
	local auto, owner = true, nil
	pcall(function()
		auto = assembly:GetNetworkOwnershipAuto()
		owner = assembly:GetNetworkOwner()
	end)
	local Effects = require(BossSystem.Combat.EffectService)
	return {
		anchored = assembly.Anchored,
		velocity = assembly.AssemblyLinearVelocity,
		angular = assembly.AssemblyAngularVelocity,
		auto = auto,
		owner = owner,
		lease = Effects.LeaseId and Effects.LeaseId(assembly),
	}
end
local function freezePart(part)
	if not part:IsA("BasePart") or exempt(part) or part.Anchored then
		return
	end
	local assembly = part.AssemblyRootPart or part
	if frozenParts[assembly] or assembly.Anchored or exempt(assembly) then
		return
	end
	frozenParts[assembly] = snapshotPart(assembly)
	assembly.Anchored = true
end
 
 
 
function api.SetAnchored(part, desired)
	if not part or not part.Parent or not part:IsA("BasePart") then
		return false
	end
	desired = desired == true
	if next(stops) and not exempt(part) then
		local assembly = part.AssemblyRootPart or part
		local record = frozenParts[assembly]
		if not record then
			record = snapshotPart(assembly)
			frozenParts[assembly] = record
		end
		record.anchored = desired
		assembly.Anchored = true
	else
		part.Anchored = desired
	end
	return true
end
local function freezeParticle(emitter)
	if exempt(emitter) or frozenParticles[emitter] ~= nil then
		return
	end
	frozenParticles[emitter] = emitter.TimeScale
	emitter.TimeScale = 0
end
local thawCharacter
local function freezeCharacter(character)
	if frozenCharacters[character] or exempt(character) or not valid(character) then
		return
	end
	updateClock(character)
	local h = character:FindFirstChildOfClass("Humanoid")
	local token = { TimeStopControl = true }
	frozenCharacters[character] =
		{ token = token, walk = h.WalkSpeed, rotate = h.AutoRotate, jumpPower = h.JumpPower, jumpHeight = h.JumpHeight }
	publish(character, "TimeFrozen", true)
	publish(character, "TemporalRate", 0)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		require(BossSystem.Combat.StatusEffectService).SetLocked(player, token, true)
	else
		h.WalkSpeed = 0
		h.AutoRotate = false
		h.JumpPower = 0
		h.JumpHeight = 0
	end
	local animator = h:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			freezeTrack(track, character)
		end
		frozenCharacters[character].playing = animator.AnimationPlayed:Connect(function(track)
			freezeTrack(track, character)
		end)
	end
	frozenCharacters[character].died = h.Died:Connect(function()
		thawCharacter(character)
	end)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			freezePart(part)
		end
	end
	updateClock(character)
end
local function restorePart(part, record)
	if not part.Parent then
		return
	end
	if record.lease then
		local Effects = require(BossSystem.Combat.EffectService)
		if Effects.LeaseId and Effects.LeaseId(part) ~= record.lease then
			return
		end
	end
	part.Anchored = record.anchored
	if not part.Anchored then
		part.AssemblyLinearVelocity = record.velocity
		part.AssemblyAngularVelocity = record.angular
		pcall(function()
			if record.auto then
				part:SetNetworkOwnershipAuto()
			else
				part:SetNetworkOwner(record.owner and record.owner.Parent == Players and record.owner or nil)
			end
		end)
	end
end
thawCharacter = function(character)
	local record = frozenCharacters[character]
	if not record then
		return
	end
	frozenCharacters[character] = nil
	if record.playing then
		record.playing:Disconnect()
	end
	if record.died then
		record.died:Disconnect()
	end
	if character.Parent then
		updateClock(character)
		local grace = Config.TimeResumeGrace or 0.4
		if valid(character) then
			publish(character, "TimeThawProtectedUntil", workspace:GetServerTimeNow() + grace)
		end
		publish(character, "TimeFrozen", false)
		publish(character, "TemporalRate", decelerations[character] and 0.5 or 1)
		local player = Players:GetPlayerFromCharacter(character)
		local h = character:FindFirstChildOfClass("Humanoid")
		if player then
			require(BossSystem.Combat.StatusEffectService).SetLocked(player, record.token, false)
		elseif h then
			h.WalkSpeed = record.walk
			h.AutoRotate = record.rotate
			h.JumpPower = record.jumpPower
			h.JumpHeight = record.jumpHeight
		end
		updateClock(character)
	end
	for part, snapshot in pairs(frozenParts) do
		if part:IsDescendantOf(character) then
			restorePart(part, snapshot)
			frozenParts[part] = nil
		end
	end
	for track, snapshot in pairs(frozenTracks) do
		if snapshot.character == character then
			pcall(function()
				track:AdjustSpeed(snapshot.speed)
			end)
			frozenTracks[track] = nil
		end
	end
end
local function unfreezeAll()
	if freezeAdded then
		freezeAdded:Disconnect()
		freezeAdded = nil
	end
	for character in pairs(frozenCharacters) do
		thawCharacter(character)
	end
	for part, record in pairs(frozenParts) do
		restorePart(part, record)
	end
	for track, record in pairs(frozenTracks) do
		pcall(function()
			track:AdjustSpeed(record.speed)
		end)
	end
	for emitter, scale in pairs(frozenParticles) do
		if emitter.Parent then
			emitter.TimeScale = scale
		end
	end
	table.clear(frozenCharacters)
	table.clear(frozenParts)
	table.clear(frozenTracks)
	table.clear(frozenParticles)
	workspace:SetAttribute("GoldenTimeStopped", false)
	workspace:SetAttribute("GoldenTimeStopUntil", 0)
	workspace:SetAttribute("TimeStopUntil", 0)
end
function api.StopTime(actor, seconds)
	local owner = ownerOf(actor)
	if not valid(owner) then
		return nil
	end
	if next(stops) ~= nil then
		return nil, "active"
	end
	api.EncounterNow(owner)
	stopSequence += 1
	local handle = {
		owner = owner,
		expires = os.clock() + seconds,
		generation = owner:GetAttribute("PhaseGeneration") or 0,
		closed = false,
		sequence = stopSequence,
		finishedCallbacks = {},
	}
	stops[handle] = true
	workspace:SetAttribute("GoldenTimeStopped", true)
	workspace:SetAttribute("GoldenTimeStopUntil", workspace:GetServerTimeNow() + seconds)
	workspace:SetAttribute("TimeStopUntil", workspace:GetServerTimeNow() + seconds)
	set(owner, "GoldenHourActive", true)
	set(owner, "GoldenHourSequence", handle.sequence)
	set(owner, "GoldenHourEndsAt", workspace:GetServerTimeNow() + seconds)
	workspace:SetAttribute("GoldenHourSequence", handle.sequence)
	function handle:OnFinished(callback)
		if self.closed then
			callback(self.reason, self)
			return { Disconnect = function() end }
		end
		local subscription = { Connected = true }
		self.finishedCallbacks[subscription] = callback
		function subscription:Disconnect()
			self.Connected = false
			handle.finishedCallbacks[self] = nil
		end
		return subscription
	end
	function handle:Dispose(reason)
		if self.closed then
			return
		end
		self.closed = true
		self.reason = reason or "cancelled"
		api.EncounterNow(owner)
		stops[self] = nil
		set(owner, "GoldenHourActive", false)
		set(owner, "GoldenHourEndsAt", 0)
		if next(stops) == nil then
			unfreezeAll()
			realAt = os.clock()
		end
		event("GoldenHourEnd", { Sequence = self.sequence, Reason = self.reason })
		for subscription, callback in pairs(self.finishedCallbacks) do
			if subscription.Connected then
				subscription.Connected = false
				local ok, err = xpcall(callback, debug.traceback, self.reason, self)
				if not ok then
					warn("GoldenHour finish: " .. tostring(err))
				end
			end
		end
		table.clear(self.finishedCallbacks)
	end
	if not freezeAdded then
		 
		freezeAdded = workspace.DescendantAdded:Connect(function(instance)
			if instance:IsA("Humanoid") then
				task.defer(function()
					if instance.Parent and next(stops) then
						freezeCharacter(instance.Parent)
					end
				end)
			elseif instance:IsA("BasePart") then
				task.defer(function()
					if instance.Parent and next(stops) then
						freezePart(instance)
					end
				end)
			elseif instance:IsA("ParticleEmitter") and instance.Parent and next(stops) then
				freezeParticle(instance)
			end
		end)
		for _, instance in ipairs(workspace:GetDescendants()) do
			if instance:IsA("Humanoid") then
				freezeCharacter(instance.Parent)
			elseif instance:IsA("BasePart") then
				freezePart(instance)
			end
			if instance:IsA("ParticleEmitter") then
				freezeParticle(instance)
			end
		end
	end
	event("GoldenHourStart", { Sequence = handle.sequence, Duration = seconds })
	return handle
end
function api.ClearRates(actor)
	local owner = ownerOf(actor)
	for _, handle in pairs(accelerations) do
		if handle.owner == owner then
			handle:Dispose()
		end
	end
	for _, handle in pairs(decelerations) do
		if not handle.owner or handle.owner == owner then
			handle:Dispose()
		end
	end
end
function api.ClearOwner(actor)
	local owner = ownerOf(actor)
	collapseQueues[owner] = nil
	for token, boss in pairs(deferred) do
		if boss == owner then
			api.UnregisterDeferred(token)
		end
	end
	for handle in pairs(stops) do
		if handle.owner == owner then
			handle:Dispose("encounter cancelled")
		end
	end
	api.ClearRates(actor)
end
function api.Stats()
	local result = { ActiveStops = 0, Decelerations = 0, Accelerations = 0, FrozenAssemblies = 0, PlayerTimers = 0 }
	for _ in pairs(stops) do
		result.ActiveStops += 1
	end
	for _ in pairs(decelerations) do
		result.Decelerations += 1
	end
	for _ in pairs(accelerations) do
		result.Accelerations += 1
	end
	for _ in pairs(frozenParts) do
		result.FrozenAssemblies += 1
	end
	for _, timers in pairs(playerTimers) do
		for _ in pairs(timers) do
			result.PlayerTimers += 1
		end
	end
	return result
end
 
local observerConnections = {}
local function refreshObserver(player)
 local character = player.Character
 if not character then return end
 if Observer.IsActive(player) then
  local slowdown = decelerations[character]
  if slowdown then slowdown:Dispose() end
  thawCharacter(character)
  for emitter, scale in pairs(frozenParticles) do
   if emitter:IsDescendantOf(character) then
    emitter.TimeScale = scale
    frozenParticles[emitter] = nil
   end
  end
 elseif next(stops) then
  freezeCharacter(character)
  for _, instance in ipairs(character:GetDescendants()) do
   if instance:IsA("ParticleEmitter") then freezeParticle(instance) end
  end
 end
end
local function observePlayer(player)
 observerConnections[player] = {
  player:GetAttributeChangedSignal("ViewAsServer"):Connect(function() refreshObserver(player) end),
  player.CharacterAdded:Connect(function()
   task.defer(refreshObserver, player)
  end),
 }
 refreshObserver(player)
end
Players.PlayerAdded:Connect(observePlayer)
Players.PlayerRemoving:Connect(function(player)
 playerTimers[player] = nil
 for _, connection in ipairs(observerConnections[player] or {}) do connection:Disconnect() end
 observerConnections[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do observePlayer(player) end
Run.Heartbeat:Connect(function()
	local now = os.clock()
	api.EncounterNow()
	for owner, queue in pairs(collapseQueues) do
		if
			not valid(owner)
			or owner:GetAttribute("EncounterEnded")
			or (owner:GetAttribute("PhaseGeneration") or 0) ~= queue.Generation
		then
			collapseQueues[owner] = nil
		elseif now >= queue.At and not api.IsStopped(owner) then
			local processed = 0
			while queue.Index <= #queue.Items and processed < queue.MaxCount do
				local token = queue.Items[queue.Index]
				queue.Index += 1
				if deferred[token] == owner and deferredAlive(token) then
					processed += 1
					deferredAdvance(token, 60, true)
				end
			end
			queue.At = now + queue.Interval
			if queue.Index > #queue.Items then
				collapseQueues[owner] = nil
			end
		end
	end
	for handle in pairs(stops) do
		if now >= handle.expires then
			handle:Dispose("completed")
		elseif
			not valid(handle.owner)
			or handle.owner:GetAttribute("EncounterEnded")
			or handle.owner:GetAttribute("AIEnabled") == false
			or (handle.owner:GetAttribute("PhaseGeneration") or 0) ~= handle.generation
		then
			handle:Dispose("interrupted")
		end
	end
	for character, handle in pairs(decelerations) do
		if
			now >= handle.expires
			or not valid(character)
			or handle.owner
				and (not valid(handle.owner) or handle.owner:GetAttribute("EncounterEnded") or (handle.owner:GetAttribute(
					"PhaseGeneration"
				) or 0) ~= handle.generation)
		then
			handle:Dispose()
		end
	end
	for actor, handle in pairs(accelerations) do
		if
			now >= handle.expires
			or not valid(actor)
			or handle.owner:GetAttribute("EncounterEnded")
			or (handle.owner:GetAttribute("PhaseGeneration") or 0) ~= handle.generation
		then
			handle:Dispose()
		end
	end
	for player, timers in pairs(playerTimers) do
		if player.Parent ~= Players then
			playerTimers[player] = nil
			continue
		end
		for key, entry in pairs(timers) do
			if player.Character ~= entry.character or not valid(entry.character) then
				timers[key] = nil
				player:SetAttribute(key, 0)
				continue
			end
			local remaining = playerTimerRemaining(key, entry)
			local rate = api.Rate(entry.character) * cooldownRate(entry.character, key)
			 
			local deadline = remaining > 0 and workspace:GetServerTimeNow() + remaining / (rate > 0 and rate or 1) or 0
			local previous = player:GetAttribute(key) or 0
			if deadline == 0 or math.abs(previous - deadline) > 0.08 then
				set(player, key, deadline)
			end
			if remaining <= 0 then
				timers[key] = nil
			end
		end
		if next(timers) == nil then
			playerTimers[player] = nil
		end
	end
end)
return api
