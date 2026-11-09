local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Config = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
local Effects = require(BossSystem.Combat.EffectService)
local remote = game.ReplicatedStorage:WaitForChild("BossCombatEffects")
local Players = game:GetService("Players")
local Content = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local api = {}
local times = setmetatable({}, { __mode = "k" })
local loops = {}
local serial = 0
local audit
local owners = setmetatable({}, { __mode = "k" })
local attackNames = setmetatable({}, { __mode = "k" })
local durationCache = {}
local function encounterOwner(actor)
	if not actor then
		return nil
	end
	local cached = owners[actor]
	if cached then
		return cached
	end
	local reference = actor:FindFirstChild("EncounterOwner")
	local owner = reference and reference:IsA("ObjectValue") and reference.Value or actor
	owners[actor] = owner
	return owner
end
local function origin(actor, source)
	if typeof(source) == "Vector3" then
		return source, nil
	end
	if typeof(source) == "Instance" and source:IsA("BasePart") then
		return source.Position, source
	end
	local root = actor and actor:FindFirstChild("HumanoidRootPart")
	return root and root.Position or Vector3.zero, root
end
local function emit(actor, cue, source, options, token)
	local definition = Config.Cues[cue]
	if not definition then
		return false
	end
	options = options or {}
	local owner = encounterOwner(actor)
	if owner and (not owner.Parent or owner:GetAttribute("EncounterEnded")) then
		return false
	end
	local position, part = origin(actor, source)
	local overrides = {}
	if actor then
		local sword = actor:FindFirstChild("Basic Sword")
		if sword then
			for _, item in ipairs(sword:GetDescendants()) do
				if item:IsA("Sound") and item.SoundId ~= "" then
					local name = string.lower(item.Name)
					if name:find("slash") then
						overrides.Slash = item.SoundId
					elseif name:find("lunge") then
						overrides.Lunge = item.SoundId
					elseif name:find("unsheath") then
						overrides.Unsheath = item.SoundId
					end
				end
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local r = char and char:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - position).Magnitude <= definition.Range + 30 then
			remote:FireClient(player, "CombatAudio", {
				Cue = cue,
				Position = position,
				Emitter = part,
				Owner = owner,
				Token = token,
				VolumeScale = math.clamp(
					options.VolumeScale or (actor and actor:GetAttribute("IsIllusion") and 0.5) or 1,
					0,
					1.5
				),
				Pitch = options.Pitch,
				Overrides = overrides,
				Duration = options.Duration,
				StartedAt = options.StartedAt,
			})
		end
	end
	return true
end
 
 
local function requestDuration(cue)
	local definition = Config.Cues[cue]
	if not definition or definition.Loop or #definition.Layers ~= 1 then
		return nil, "finite cue must contain one non-looping clip"
	end
	local layer = definition.Layers[1]
	local asset = layer.Asset
	local record = durationCache[asset]
	if record and (not record.Done or record.Duration or os.clock() < (record.RetryAt or 0)) then
		return record
	end
	record = { Done = false }
	durationCache[asset] = record
	local sound = Instance.new("Sound")
	sound.Name = "BossFiniteDurationProbe"
	sound.Volume = 0
	sound.PlaybackSpeed = 1
	sound.SoundId = asset
	sound.Parent = SoundService
	local function finish(duration, reason)
		if record.Done then
			return
		end
		record.Duration = duration
		record.Error = reason
		record.Done = true
		record.RetryAt = os.clock() + 2
		sound:Destroy()
	end
	task.delay(Config.AssetLoadTimeout, function()
		finish(nil, "server sound load timed out: " .. asset)
	end)
	task.spawn(function()
		local ok, reason = pcall(Content.PreloadAsync, Content, { sound })
		if record.Done then
			return
		end
		if ok and sound.IsLoaded and sound.TimeLength > 0 then
			finish(sound.TimeLength)
		else
			finish(nil, "server could not read sound length: " .. asset .. " (" .. tostring(reason) .. ")")
		end
	end)
	return record
end
function api.PreloadFinite(cue)
	local record, reason = requestDuration(cue)
	return record ~= nil, reason
end
function api.GetDuration(cue, timeout)
	local record, reason = requestDuration(cue)
	if not record then
		return nil, reason
	end
	local ends = os.clock() + math.clamp(timeout or Config.AssetLoadTimeout, 0, Config.AssetLoadTimeout)
	while not record.Done and os.clock() < ends do
		task.wait(0.03)
	end
	if not record.Done then
		return nil, "server sound length is still loading"
	end
	return record.Duration, record.Error
end
function api.StartFinite(actor, cue, source, options)
	local definition = Config.Cues[cue]
	if not definition or definition.Loop or #definition.Layers ~= 1 then
		return nil, "invalid finite cue"
	end
	 
	remote:FireAllClients("CombatAudioPreload", { Cue = cue })
	local length, reason = api.GetDuration(cue)
	if not length then
		return nil, reason
	end
	if options and options.Valid and not options.Valid() then
		return nil, "Interrupted"
	end
	local owner = encounterOwner(actor)
	if not actor or not actor.Parent or owner and (not owner.Parent or owner:GetAttribute("EncounterEnded")) then
		return nil, "finite cue owner ended"
	end
	options = table.clone(options or {})
	local speed = definition.FixedPitch and definition.Layers[1].Pitch
		or math.clamp(options.Pitch or definition.Layers[1].Pitch, 0.25, 3)
	options.Duration = length / speed
	options.StartedAt = workspace:GetServerTimeNow()
	options.Pitch = speed
	serial += 1
	local token = "CombatFinite" .. serial
	local handle = { Closed = false, Duration = options.Duration, StartedAt = options.StartedAt }
	handle.EndsAt = handle.StartedAt + handle.Duration
	function handle:Dispose()
		if self.Closed then
			return
		end
		self.Closed = true
		remote:FireAllClients("CombatAudioStop", { Token = token })
	end
	handle.Stop = handle.Dispose
	function handle:IsComplete()
		return self.Closed or workspace:GetServerTimeNow() >= self.EndsAt
	end
	if not emit(actor, cue, source, options, token) then
		handle:Dispose()
		return nil, "finite cue emission rejected"
	end
	return handle
end
function api.Emit(actor, cue, source, options)
	local definition = Config.Cues[cue]
	if not definition then
		return false
	end
	local now = os.clock()
	local key = actor or script
	local record = times[key]
	if not record then
		record = {}
		times[key] = record
	end
	if now < (record[cue] or 0) then
		return false
	end
	record[cue] = now + definition.Interval
	return emit(actor, cue, source, options)
end
function api.Duck(actor, duration, volume, reason)
	 
	if reason ~= "Dialogue" then
		return false
	end
	remote:FireAllClients(
		"CombatAudioDuck",
		{
			Reason = "Dialogue",
			Duration = math.clamp(duration or 2, 0.1, 30),
			Volume = math.clamp(volume or 0.45, 0, 1),
		}
	)
	return true
end
function api.Attack(actor, name, stage, source, options)
	if stage ~= "Cast" and stage ~= "Impact" then
		return false
	end
	name = Config.AttackAliases[name] or name
	if not Config.Attacks[name] and actor then
		local current = actor:GetAttribute("CurrentAttackFile")
		name = Config.AttackAliases[current] or current or attackNames[actor]
	end
	local entry = Config.Attacks[name]
	if not entry then
		return false
	end
	if actor and stage == "Cast" then
		attackNames[actor] = name
	end
	local key = actor or script
	local record = times[key]
	if not record then
		record = {}
		times[key] = record
	end
	local token = "Ability:" .. name .. ":" .. stage
	local now = os.clock()
	if now < (record[token] or 0) then
		return false
	end
	record[token] = now + (stage == "Cast" and Config.AttackCastInterval or Config.AttackImpactInterval)
	return api.Emit(actor, entry[stage], source, options)
end
function api.Phase(actor, phase, source)
	local cue = Config.PhaseCues[tonumber(phase) or phase]
	return cue and api.Emit(actor, cue, source) or false
end
function api.StopMusic(actor, reason)
	remote:FireAllClients(
		"BossMusicStop",
		{
			Owner = encounterOwner(actor),
			Phase = actor and actor:GetAttribute("Phase"),
			Reason = reason or "Transition",
		}
	)
end
function api.Loop(cast, actor, cue, source)
	serial += 1
	local token = "CombatLoop" .. serial
	local _, part = origin(actor, source)
	local lease = part and Effects.LeaseId(part)
	local handle = { Closed = false }
	function handle:Dispose()
		if self.Closed then
			return
		end
		self.Closed = true
		loops[self] = nil
		remote:FireAllClients("CombatAudioStop", { Token = token })
	end
	handle.Stop = handle.Dispose
	if not cast or not cast:Alive() or not emit(actor, cue, source, nil, token) then
		handle:Dispose()
		return handle
	end
	loops[handle] = { Cast = cast, Part = part, Lease = lease }
	local previous = cast.OnDispose
	cast.OnDispose = function()
		handle:Dispose()
		if previous then
			previous()
		end
	end
	if not audit or audit.closed then
		audit = Effects.NewCast(nil, "CombatAudioLoopOwnership", math.huge)
		audit.TimeStopExempt = true
		local elapsed = 0
		audit:Step(function(dt)
			elapsed += dt
			if elapsed < 0.1 then
				return true
			end
			elapsed = 0
			for item, record in pairs(loops) do
				 
				if
					record.Cast.closed
					or record.Part
						and (not record.Part.Parent or record.Lease and Effects.LeaseId(record.Part) ~= record.Lease)
				then
					item:Dispose()
				end
			end
			if not next(loops) then
				audit:Dispose()
				audit = nil
				return false
			end
			return true
		end)
	end
	return handle
end
api.PreloadFinite("P1ShieldBreakScream")
api.PreloadFinite("DeathScytheGoodbye")
return api
