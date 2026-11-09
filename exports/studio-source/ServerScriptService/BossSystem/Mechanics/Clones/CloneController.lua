local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Players=game:GetService("Players")
 
 
local Audio = require(BossSystem.Presentation.CombatAudio)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Registry = require(BossSystem.Combat.AttackRegistry)
local Selector = require(BossSystem.Combat.AttackSelector)
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Collision = require(BossSystem.Boss.BossNoCollision)
local Indicator = require(BossSystem.Presentation.BossAttackIndicator)
local Whitelist = require(BossSystem.Mechanics.Clones.CloneWhitelist)
local QTE = require(BossSystem.Combat.CataclysmQTEService)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Weapon = require(BossSystem.Boss.WeaponController)
local api = {}
local owners = {}
local monitor
local serial = 0
local validModes = { Normal = true, Persistent = true, HourDebt = true, ShieldGate = true, Illusion = true, Past = true }
 -- anything from P1 to P4.5, ultimates included - as the era they come from (the clone's Phase is set to the attack's own while it
 -- casts). The ones left out reach into the boss's own state (time stops, saves, illusions, the Phase 2.5 and 3.5 set pieces).
local PAST_BANNED = {
	P1GoldenParry = true, P1BlockGrab = true, P2Save = true, P2Load = true, P2Acceleration = true, P2Deceleration = true,
	["P2GoldenClock(Ultimate)"] = true, ["P2.5StolenSecond"] = true, ["P2.5FalseFuture"] = true, ["P2.5MissingFrame"] = true,
	["P2.5CircularBarrage"] = true, ["P2.5LastMinute(Ultimate)"] = true, P3Thief = true, P3Illusion = true, P3ControlDistortion = true,
	P3Clone = true, P3PlayerClone = true, ["P3PickThePupils(Ultimate)"] = true, ["P3.5TrueIllusion(Ultimate)"] = true, ["P3.5MysteriousGuy(Ultimate)"] = true,
	["P3.5IllusionBomb"] = true,
}
local pastPool
local function buildPastPool()
	if pastPool then
		return pastPool
	end
	pastPool = {}
	for _, name in ipairs(Metadata.ActiveNames) do
		local e = Metadata.Get(name)
		if e and e.NativePhase <= 4.5 and not e.Passive and not e.TimeStopOnly and not e.ShieldBreakOnly and not e.TriggerOnly
			and not e.Linked and not PAST_BANNED[name] and Registry.Module(name) then
			pastPool[#pastPool + 1] = name
		end
	end
	return pastPool
end
api.PastPool = buildPastPool
local cardRandom = Random.new()

local function illusionCard(cast, index)
	local card = Effects.AcquirePart()
	card.Name = "IllusionJokerCard"
	card.Material = Enum.Material.SmoothPlastic
	card.Color = Color3.fromRGB(250, 210, 58)
	card.Size = Vector3.new(0.8, 1.2, 0.05)
	card.Transparency = 0.12
	card.Parent = Runtime.Effects
	cast:Add(card)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "JokerFace"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 60
		gui.LightInfluence = 0.6
		gui.Parent = card
		local border = Instance.new("Frame")
		border.BackgroundTransparency = 1
		border.Size = UDim2.fromScale(0.9, 0.92)
		border.Position = UDim2.fromScale(0.05, 0.04)
		border.Parent = gui
		local rim = Instance.new("UIStroke")
		rim.Color = Color3.fromRGB(103, 65, 13)
		rim.Thickness = 2
		rim.Parent = border
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Text = index % 3 == 0 and "J\n★\nJ" or index % 2 == 0 and "♠" or "♦"
		text.TextColor3 = index % 2 == 0 and Color3.fromRGB(43, 30, 47) or Color3.fromRGB(144, 34, 53)
		text.TextScaled = true
		text.Font = Enum.Font.GothamBold
		text.Parent = gui
	end
	return card
end
api.Card = illusionCard

function api.IllusionCardRing(owner, entity, duration)
	local root = entity and entity:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	duration = math.max(0.1, duration or 1.5)
	local cast = Effects.NewCast(owner, "IllusionJokerPreparation", duration)
	local generation = owner:GetAttribute("PhaseGeneration") or 0
	local cards = {}
	local count = math.clamp(Config.IllusionCardCount or 12, 4, 16)
	for index = 1, count do
		cards[index] = illusionCard(cast, index)
		cards[index].CFrame = CFrame.new(root.Position)
	end
	local started = cast:Now()
	cast:Step(function(_, now)
		if not entity.Parent or not root.Parent or (owner:GetAttribute("PhaseGeneration") or 0) ~= generation then
			cast:Dispose()
			return false
		end
		local elapsed = now - started
		for index, card in ipairs(cards) do
			local angle = elapsed * 4.5 + (index - 1) * math.pi * 2 / count
			local radius = 3 + 0.3 * math.sin(elapsed * 5 + index)
			local center = root.Position
				+ Vector3.new(math.cos(angle) * radius, 0.6 + math.sin(angle * 2) * 1.7, math.sin(angle) * radius)
			card.CFrame = CFrame.new(center)
				* CFrame.Angles(0.15 * math.sin(angle), -angle + math.pi * 0.5, elapsed * 3 + index)
		end
		return true
	end)
	return cast
end

local function illusionExpiry(record)
	if record.ExpiryEffect then
		return
	end
	record.ExpiryEffect = true
	local root = record.Actor:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local duration = math.clamp(Config.IllusionExpiryDuration or 1.1, 0.5, 2)
	 
	 
	local cast = Effects.NewCast(record.Owner, "IllusionFallingCards", duration)
	local origin = root.Position + Vector3.new(0, 1, 0)
	Audio.Emit(record.Actor, "CardBurst", origin, { VolumeScale = 0.45 })
	local count = math.clamp(Config.IllusionExpiryCardCount or 8, 4, 12)
	local cards = {}
	for index = 1, count do
		local angle = index * math.pi * 2 / count
		local floor = Placement.GroundPoint(origin, { Margin = 1, Clamp = true })
		local card = illusionCard(cast, index)
		card.CFrame = CFrame.new(origin)
		table.insert(cards, {
			Part = card,
			Velocity = Vector3.new(
				math.cos(angle) * cardRandom:NextNumber(3, 6),
				cardRandom:NextNumber(2, 6),
				math.sin(angle) * cardRandom:NextNumber(3, 6)
			),
			Floor = floor and floor.Y or origin.Y - 4,
			Spin = cardRandom:NextNumber(-7, 7),
		})
	end
	local started = cast:Now()
	cast:Step(function(_, now)
		local elapsed = now - started
		for index, item in ipairs(cards) do
			local position = origin + item.Velocity * elapsed + Vector3.new(0, -12 * elapsed * elapsed, 0)
			local landed = position.Y <= item.Floor + 0.12
			position = Vector3.new(position.X, math.max(item.Floor + 0.12, position.Y), position.Z)
			item.Part.CFrame = CFrame.new(position)
				* CFrame.Angles(landed and math.pi * 0.5 or elapsed * item.Spin, index, elapsed * item.Spin * 0.6)
			item.Part.Transparency = 0.12 + 0.88 * math.clamp((elapsed - duration * 0.45) / (duration * 0.55), 0, 1)
		end
		return true
	end)
end

local function beginAudio(record)
	if record.AudioCast or record.Closed then
		return
	end
	local root = record.Actor:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local cast = Effects.NewCast(record.Actor, "CloneAudioLifecycle", math.huge)
	record.AudioCast = cast
	Audio.Emit(record.Actor, "CloneMaterialize", root, { VolumeScale = record.Mode == "Illusion" and 0.4 or 1 })
	if record.Mode ~= "Illusion" then
		Audio.Loop(cast, record.Actor, "CloneAura", root)
	end
end
local function endAudio(record, fade)
	if fade and record.AudioCast and not record.Closed then
		Audio.Emit(
			record.Actor,
			"CloneFade",
			record.Actor:FindFirstChild("HumanoidRootPart"),
			{ VolumeScale = record.Mode == "Illusion" and 0.4 or 1 }
		)
	end
	if record.AudioCast then
		record.AudioCast:Dispose()
		record.AudioCast = nil
	end
end

local function alive(character)
	if Observer.IsCharacter(character) then
		return false
	end
	local h = character and character:FindFirstChildOfClass("Humanoid")
	return character and character.Parent and h and h.Health > 0 and character:FindFirstChild("HumanoidRootPart")
end
local function ownerValid(record)
	local owner = record.Owner
	local h = record.OwnerHumanoid
	if
		not owner
		or not owner:IsDescendantOf(workspace)
		or not h
		or h.Health <= 0
		or owner:GetAttribute("EncounterEnded")
	then
		return false
	end
	local phase = tonumber(owner:GetAttribute("Phase")) or 1
	if record.Mode == "ShieldGate" then
		return owner:GetAttribute("ShieldCloneGateActive") == true
			and (phase == 1 or phase == 1.5)
			and (owner:GetAttribute("PhaseGeneration") or 0) == record.Generation
	end
	if
		owner:GetAttribute("AIEnabled") == false
		or owner:GetAttribute("PhaseTransitionInProgress") and not owner:GetAttribute("TransitionKeepsTemporal")
	then
		return false
	end
	return record.Mode == "HourDebt" and (phase >= 2 and phase < 3
			or Difficulty.Mercy("EchoAllPhases", owner) == true)  
		or record.Mode == "Normal" and (phase >= 1.5 and phase < 3 or math.min(4, math.floor(phase)) == 4)
		or record.Mode == "Persistent" and phase == 1.5
		or record.Mode == "Illusion" and math.floor(phase) == 3
		or record.Mode == "Past" and phase >= 5 and owner:GetAttribute("P5Mode") == "Time"
end
local function canCopy(record, name)
	if record.Mode == "Past" then
		return not PAST_BANNED[name]
	end
	if record.Mode == "ShieldGate" then
		return require(BossSystem.Mechanics.Clones.ShieldGateAttacks).Allows(record.Role, name)
	end
	return Metadata.CanCopy(name, record.Mode)
end
local function close(record)
	if record.Closed then
		return
	end
	endAudio(record, false)
	record.Closed = true
	if record.MovementCast then
		record.MovementCast:Dispose()
		record.MovementCast = nil
	end
	if record.AppearanceCast then
		record.AppearanceCast:Dispose()
		record.AppearanceCast = nil
	end
	local set = owners[record.Owner]
	if set then
		set[record] = nil
		if not next(set) then
			owners[record.Owner] = nil
		end
	end
	record.Actor:SetAttribute("AIEnabled", false)
	if record.Mode == "Illusion" then
		Effects.CancelEmitter(record.Actor, "visual illusion ended")
	end
	QTE.CancelForActor(record.Actor, "echo removed")
	 
	 
	if record.Busy and record.Thread then
		pcall(task.cancel, record.Thread)
	end
	Registry.Release(record.Actor)
	Weapon.Clear(record.Actor)
	record.Actor:Destroy()
	record.Target = nil
	record.Choices = nil
	record.Thread = nil
	table.clear(record.Parts)
end
local function cancel(record, reason)
	if record.Closed or record.Cancelled then
		return
	end
	endAudio(record, true)
	record.Cancelled = true
	record.CancelAt = Time.EncounterNow(nil)
	record.State = "Cancelled"
	record.Actor:SetAttribute("CloneState", "Cancelled")
	record.Actor:SetAttribute("AIEnabled", false)
	if record.Mode == "Illusion" then
		Effects.CancelEmitter(record.Actor, "illusion interrupted")
		if record.Thread then
			pcall(task.cancel, record.Thread)
			record.Thread = nil
		end
		record.Busy = false
	end
	for part in pairs(record.Parts) do
		if part.Parent then
			part.Transparency = 1
		end
	end
	for _, value in ipairs(record.Actor:GetDescendants()) do
		if value:IsA("BillboardGui") or value:IsA("Trail") or value:IsA("ParticleEmitter") then
			value.Enabled = false
		end
	end
	QTE.CancelForActor(record.Actor, reason or "echo cancelled")
	if not record.Busy then
		close(record)
	end
end

local targetTurns=setmetatable({},{__mode="k"})
local function chooseTarget(record,force)
 local taunted=require(BossSystem.Combat.TauntService).Target(record.Actor)
 if taunted then record.Target=taunted record.Actor:SetAttribute("CloneTargetUserId",Players:GetPlayerFromCharacter(taunted).UserId) return taunted end
 if record.Mode=="HourDebt" then
  local char=require(BossSystem.Combat.AttackTargetContinuity).Character(record.Target)
  local player=char and Players:GetPlayerFromCharacter(char)
  if alive(char) and player and not player:GetAttribute("PermanentlyDefeated") and not player:GetAttribute("ViewAsServer") then record.Target=char return char end
 end
 local now=workspace:GetServerTimeNow()
 if not force and alive(record.Target) and (record.Busy or now<(record.TargetUntil or 0)) then return record.Target end
 local turns=targetTurns[record.Owner]
 if not turns then turns={} targetTurns[record.Owner]=turns end
 local encounter=require(BossSystem.Players.PlayerEncounter)
 local origin=record.Actor.HumanoidRootPart.Position
 local best,bestVisits,bestDistance
 for _,p in Players:GetPlayers() do
  local char=p.Character
  if alive(char) and not p:GetAttribute("ViewAsServer") and not encounter.IsDefeated(p)
   and not p:GetAttribute("ExecutionPending") and Placement.Contains(char.HumanoidRootPart.Position) then
   local visits=turns[p.UserId] or 0
   local distance=(char.HumanoidRootPart.Position-origin).Magnitude
   if char==record.Target then distance+=12 end
   if not best or visits<bestVisits or visits==bestVisits and distance<bestDistance then
    best,bestVisits,bestDistance=char,visits,distance
   end
  end
 end
 if best then
  local p=Players:GetPlayerFromCharacter(best)
  turns[p.UserId]=(turns[p.UserId] or 0)+1
  record.Actor:SetAttribute("CloneTargetUserId",p.UserId)
 end
 record.Target=best record.TargetUntil=now+2.5
 return best
end
local function finishAttack(record, attackName, successful)
	record.Busy = false
	record.Thread = nil
	if record.Closed then
		return
	end
	record.Actor:SetAttribute("AttackInProgress", false)
	record.Actor:SetAttribute("CloneAttackFinishedAt", workspace:GetServerTimeNow())
	if successful then
		record.Actor:SetAttribute("CloneAttackCount", (record.Actor:GetAttribute("CloneAttackCount") or 0) + 1)
	end
	if record.Cancelled or not ownerValid(record) then
		close(record)
		return
	end
	if record.Mode == "Persistent" or record.Mode == "ShieldGate" or record.Mode == "Illusion" or record.Mode == "Past" then
		record.State = "Waiting"
		local interval = record.Mode == "ShieldGate" and require(BossSystem.Attacks.Shared.ShieldBreakCombat).AttackInterval(record.Role)
			or record.AttackInterval
			or Config.PersistentCloneAttackInterval
			or 1.5
		if record.Mode ~= "ShieldGate" then interval *= Difficulty.Get(record.Actor).Cooldown end
		record.ReadyAt = record.Mode == "ShieldGate"
				and record.Role
				and math.max(Time.EncounterNow(nil), (record.AttackStartedAt or Time.EncounterNow(nil)) + interval)
			or Time.EncounterNow(nil) + interval
	else
		record.State = "Holding"
		record.ReadyAt = Time.EncounterNow(nil) + record.HoldDuration
	end
	record.Actor:SetAttribute("CloneState", record.State)
end
local function attack(record)
	beginAudio(record)
	record.AttackStartedAt = Time.EncounterNow(nil)
	record.State = "Attacking"
	record.Busy = true
	record.Actor:SetAttribute("CloneState", "Attacking")
	record.Thread = task.spawn(function()
		local attackName, successful
		local ok, result = xpcall(function()
			if record.Cancelled or not ownerValid(record) then
				return false
			end
			local target=chooseTarget(record,true)
			if not target then
				return false
			end
			if record.Mode == "ShieldGate" then
				attackName =
					require(BossSystem.Mechanics.Clones.ShieldGateAttacks).Select(record.Actor, record.Role, target)
				if not attackName then
					return false
				end
				record.Actor:SetAttribute("CloneSelectedAttack", attackName)
				record.Actor:SetAttribute("AttackInProgress", true)
				record.Actor:SetAttribute("AttackStartedAt", workspace:GetServerTimeNow())
				return require(BossSystem.Mechanics.Clones.ShieldGateAttacks).Cast(
					record.Actor,
					record.Role,
					target,
					attackName
				)
			end
			local chosen
			if record.Mode == "HourDebt" then
				if
					not Metadata.CanCopy(record.AttackName, record.Mode)
					or not Metadata.Available(record.AttackName, record.Owner:GetAttribute("Phase"))
				then
					return false
				end
				local skill = Registry.For(record.Actor, record.AttackName)
				if not skill.CanUse or skill.CanUse(target) then
					chosen = { Name = record.AttackName, Skill = skill }
				end
			elseif record.Mode == "Past" then
				 -- a random move from any era: cast as that era (a few tries for one that can go now)
				local pool = buildPastPool()
				for _ = 1, 12 do
					local name = pool[cardRandom:NextInteger(1, #pool)]
					local entry = Metadata.Get(name)
					if entry and name ~= record.LastAttack then
						record.Actor:SetAttribute("Phase", entry.NativePhase)
						local okSkill, skill = pcall(Registry.For, record.Actor, name)
						if okSkill and skill and skill.Combo and (not skill.CanUse or skill.CanUse(target)) then
							chosen = { Name = name, Skill = skill }
							break
						end
					end
				end
			else
				if not record.Choices then
					record.Choices = {}
					for _, name in ipairs(record.Pool or Whitelist) do
						if canCopy(record, name) then
							table.insert(record.Choices, { Name = name, Skill = Registry.For(record.Actor, name) })
						end
					end
				end
				chosen = Selector.Choose(
					record.Choices,
					target,
					record.LastAttack,
					record.Repeats or 0,
					nil,
					record.Actor:GetAttribute("Phase"),
					record.Actor,
					"Active"
				)
			end
			if not chosen then
				return false
			end
			if not canCopy(record, chosen.Name) then
				return false
			end
			attackName = chosen.Name
			record.Repeats = record.LastAttack == attackName and (record.Repeats or 0) + 1 or 1
			record.LastAttack = attackName
			record.Actor:SetAttribute("CloneSelectedAttack", attackName)
			record.Actor:SetAttribute("LastAttackName", attackName)
			record.Actor:SetAttribute("AttackInProgress", true)
			record.Actor:SetAttribute("CurrentAttackFile", attackName)
			record.Actor:SetAttribute("AttackStartedAt", workspace:GetServerTimeNow())
			record.Owner:SetAttribute("LastCloneAttack", attackName)
			if Audio.Attack then
				Audio.Attack(record.Actor, attackName, "Cast", record.Actor:FindFirstChild("HumanoidRootPart"))
			end
			if record.Mode ~= "Past" then
				return chosen.Skill.Combo(target)
			end
			 -- cast this move started has finished (at most 15s) before the clone may pick another.
			local before = Effects.CastsOf(record.Actor)
			local result = chosen.Skill.Combo(target)
			local mine = {}
			for cast in pairs(Effects.CastsOf(record.Actor)) do
				if not before[cast] and cast ~= record.MovementCast and cast ~= record.AppearanceCast then mine[cast] = true end
			end
			local deadline = os.clock() + 15
			while os.clock() < deadline and not record.Cancelled and not record.Closed do
				local busy = false
				for cast in pairs(mine) do
					if not cast.closed and cast:Alive() then busy = true break end
				end
				if not busy then break end
				task.wait(0.1)
			end
			return result
		end, debug.traceback)
		if not ok then
			warn("Golden echo: " .. tostring(result))
		end
		successful = ok and result ~= false and result ~= nil
		finishAttack(record, attackName, successful)
	end)
end

local function ensureMonitor()
	if monitor and not monitor.closed then
		return
	end
	monitor = Effects.NewCast(nil, "CloneController", math.huge)
	local accumulated = 0
	monitor:Step(function(dt)
		accumulated += dt
		if accumulated < 0.05 then
			return true
		end
		accumulated = 0
		local now = Time.EncounterNow(nil)
		local any = false
		for _, set in pairs(owners) do
			for record in pairs(set) do
				any = true
				if not record.Closed then
					if not ownerValid(record) or not record.Actor.Parent or record.Humanoid.Health <= 0 then
						if
							record.Actor:GetAttribute("DamageableClone")
							and ownerValid(record)
							and record.Actor.Parent
							and record.Humanoid.Health <= 0
						then
							if not record.Dead then
								endAudio(record, true)
								record.Dead = true
								record.State = "Dissolving"
								record.DeathAt = now
								record.Actor:SetAttribute("AIEnabled", false)
								record.Actor:SetAttribute("CloneState", "Dissolving")
								record.Actor:SetAttribute(
									"MovementRevision",
									(record.Actor:GetAttribute("MovementRevision") or 0) + 1
								)
								if record.Thread then
									pcall(task.cancel, record.Thread)
									record.Thread = nil
									record.Busy = false
								end
								QTE.CancelForActor(record.Actor, "clone defeated")
								Effects.CancelEmitter(record.Actor, "clone defeated")
								if record.OnDefeated then
									local ok, err =
										pcall(record.OnDefeated, record.Handle, record.Actor.HumanoidRootPart.Position)
									if not ok then
										warn("Clone defeat: " .. tostring(err))
									end
								end
							end
						else
							cancel(record, "owner or echo unavailable")
						end
					end
					if record.OnHealthUpdate and record.PublishedHealth ~= record.Humanoid.Health then
						record.PublishedHealth = record.Humanoid.Health
						local ok, err = pcall(record.OnHealthUpdate, record.PublishedHealth, record.Humanoid.MaxHealth)
						if not ok then
							warn("Clone health: " .. tostring(err))
						end
					end
					if record.ExpiresAt and now >= record.ExpiresAt and not record.Cancelled then
						if record.Mode == "Illusion" then
							illusionExpiry(record)
						end
						cancel(record, "illusion duration ended")
					end
					if record.Cancelled then
						if not record.Busy or now - record.CancelAt >= 3 then
							close(record)
						end
					elseif record.State == "Dissolving" then
						local alpha = math.clamp((now - record.DeathAt) / 1.1, 0, 1)
						for part, base in pairs(record.Parts) do
							if part.Parent then
								part.Transparency = base + (1 - base) * alpha
							end
						end
						if alpha >= 1 then
							close(record)
						end
					elseif record.Actor:GetAttribute("ClassStunFrame") or workspace:GetServerTimeNow()<(record.Actor:GetAttribute("ClassStunnedUntil") or 0) then
      if record.Thread then pcall(task.cancel,record.Thread) record.Thread=nil record.Busy=false
       record.State="Waiting" record.Actor:SetAttribute("AttackInProgress",false) end
      local r=record.Actor.HumanoidRootPart
      local frame=record.Actor:GetAttribute("ClassStunFrame")
      if typeof(frame)=="CFrame" then r.CFrame=frame end
      r.AssemblyLinearVelocity=Vector3.zero
     elseif record.MirrorOwner then
						 
						 
						if now >= record.MirrorReadyAt then
							local source = record.Owner.HumanoidRootPart
							local target = record.Actor.HumanoidRootPart
							local desired = source.CFrame + record.WorldOffset
							local frame = Placement.ResolveRecorded(
								record.Actor,
								desired,
								{ Margin = 6, MaxHeight = 60, SearchRadius = 6 }
							)
							if frame then
								target.CFrame = frame
							end
							for _, joint in ipairs(record.MirrorMotors) do
								if joint.Source.Parent and joint.Copy.Parent then
									joint.Copy.C0 = joint.Source.C0
									joint.Copy.Transform = joint.Source.Transform
								end
							end
							Weapon.Mirror(record.Owner, record.Actor)
							record.Actor:SetAttribute("CloneState", "Mirroring")
							record.Actor:SetAttribute("AttackState", record.Owner:GetAttribute("AttackState"))
							record.Actor:SetAttribute("CurrentSkill", record.Owner:GetAttribute("CurrentSkill"))
							record.Actor:SetAttribute(
								"AttackInProgress",
								record.Owner:GetAttribute("AttackInProgress") == true
							)
						end
					elseif record.State == "Materializing" then
						local alpha = math.clamp((now - record.AppearanceAt) / record.AppearanceDuration, 0, 1)
						local ease = 0.5 - 0.5 * math.cos(alpha * math.pi)
						for part, base in pairs(record.Parts) do
							if part.Parent then
								part.Transparency = 1 - (1 - base) * ease
							end
						end
						if alpha >= 1 then
							record.State = "Waiting"
							record.ReadyAt = now
							record.Actor:SetAttribute("CloneState", "Waiting")
							record.Actor:SetAttribute("CloneMaterializedAt", workspace:GetServerTimeNow())
							if record.Actor:GetAttribute("DamageableClone") then
								record.Actor:SetAttribute("Invulnerable", false)
							end
							if record.AppearanceCast then
								record.AppearanceCast:Dispose()
								record.AppearanceCast = nil
							end
						end
					elseif
						record.State == "Waiting"
						and now >= record.ReadyAt
						and not record.Actor:GetAttribute("ShieldGateDodging")
						and (
							record.Mode == "ShieldGate"
							or not record.Owner:GetAttribute("ExecutionLocked")
								and not record.Owner:GetAttribute("PhaseTransitionInProgress")
						)
					then
						attack(record)
					elseif record.State == "Holding" and now >= record.ReadyAt then
						endAudio(record, true)
						record.State = "Fading"
						record.FadeAt = now
						record.Actor:SetAttribute("CloneState", "Fading")
						for _, effect in ipairs(record.Actor:GetDescendants()) do
							if effect:IsA("Trail") or effect:IsA("ParticleEmitter") then
								effect.Enabled = false
							end
						end
					elseif record.State == "Fading" then
						local alpha = math.clamp((now - record.FadeAt) / record.FadeDuration, 0, 1)
						for part, base in pairs(record.Parts) do
							if part.Parent then
								part.Transparency = base + (1 - base) * alpha
							end
						end
						if alpha >= 1 then
							close(record)
						end
					end
				end
			end
		end
		if not any or not next(owners) then
			monitor:Dispose()
			monitor = nil
			return false
		end
		return true
	end)
end

local function spawnFrame(owner, index)
	local root = owner.HumanoidRootPart
	local frame = root.CFrame * CFrame.new(index % 2 == 0 and 8 or -8, 0, 4)
	return Placement.Validate(owner, frame) or Placement.ResolveRecorded(owner, root.CFrame)
end

function api.Create(owner, options)
	options = options or {}
	local mode = options.Mode or "Normal"
	if mode == "ShieldGate" and options.Role ~= "Elementalist" and options.Role ~= "Swordsmaster" then
		return nil
	end
	if
		not validModes[mode]
		or not owner
		or owner:GetAttribute("IsGoldenClone")
		or not alive(owner)
		or owner:GetAttribute("AIEnabled") == false
			and not (mode == "ShieldGate" and owner:GetAttribute("ShieldCloneGateActive"))
	then
		return nil
	end
	local phase = tonumber(owner:GetAttribute("Phase")) or 1
	if
		mode == "HourDebt"
		and (
			phase < 2 and Difficulty.Mercy("EchoAllPhases", owner) ~= true
			or type(options.AttackName) ~= "string"
			or not Metadata.CanCopy(options.AttackName, mode)
			or not Metadata.Available(options.AttackName, phase)
		)
	then
		return nil
	end
	if mode == "Normal" and (phase < 1.5 or phase >= 3 and math.min(4, math.floor(phase)) ~= 4) then
		return nil
	end
	if mode == "Persistent" and phase ~= 1.5 then
		return nil
	end
	if
		mode == "ShieldGate" and (not owner:GetAttribute("ShieldCloneGateActive") or phase ~= 1 and phase ~= 1.5)
		or mode == "Illusion" and math.floor(phase) ~= 3
	then
		return nil
	end
	if owner:GetAttribute("PhaseTransitionInProgress") and mode ~= "ShieldGate" then
		return nil
	end
	local appearanceDuration = math.max(0, options.MaterializeDuration or 0)
	if mode == "Normal" and api.Count(owner, mode) >= 1 then
		return nil
	end
	if mode == "Persistent" and api.Count(owner, mode) >= 2 then
		return nil
	end
	if mode == "Past" and (phase < 5 or api.Count(owner, mode) >= 1) then
		return nil
	end
	if (mode == "ShieldGate" or mode == "Illusion") and api.Count(owner, mode) >= 2 then
		return nil
	end
	if
		mode == "HourDebt"
		and api.Count(owner, mode) >= math.clamp(tonumber(owner:GetAttribute("HourDebtMaxCopies")) or 6, 1, 12)
	then
		return nil
	end
	if mode == "HourDebt" and not Registry.Module(options.AttackName) then
		return nil
	end
	serial += 1
	local clone = owner:Clone()
	 
	 
	local form = clone:FindFirstChild("Phase3GoldenRegalia")
	if form and mode ~= "Illusion" then
		form:Destroy()
	end
	for _, value in ipairs(clone:GetDescendants()) do
		if value:GetAttribute("BossFormVisual") and mode ~= "Illusion" then
			value:Destroy()
		end
	end
	Weapon.CopyTo(owner, clone)
	clone.Name = mode == "Illusion" and "alterGolden"
		or mode == "HourDebt" and "alterGolden's Hour Debt"
		or mode == "Persistent" and "alterGolden's Gilded Echo"
		or "alterGolden's Echo"
	if mode == "ShieldGate" and options.Role then
		clone.Name = options.Role
	end
	clone:SetAttribute("CloneRoleTitle", options.Role)
	clone:SetAttribute("IsGoldenClone", true)
	clone:SetAttribute("IsLinkedClone", false)
	clone:SetAttribute("IsShieldGateClone", mode == "ShieldGate")
	clone:SetAttribute("DamageableClone", mode == "ShieldGate")
	clone:SetAttribute("IsIllusion", mode == "Illusion")
	clone:SetAttribute("CloneMode", mode)
	clone:SetAttribute("CloneId", serial)
	clone:SetAttribute("Phase", mode == "ShieldGate" and 1 or phase)
	clone:SetAttribute("PastClone", mode == "Past")
	clone:SetAttribute("PhaseTransitionInProgress", false)
	if mode == "ShieldGate" then
		clone:SetAttribute("ShieldBreakInProgress", false)
	end
	clone:SetAttribute("ParryActive", false)
	clone:SetAttribute("AttackInProgress", false)
	clone:SetAttribute("ExecutionLocked", false)
	clone:SetAttribute("ExecutionLockToken", nil)
	clone:SetAttribute("AIEnabled", true)
	clone:SetAttribute("Invulnerable", mode ~= "ShieldGate" or appearanceDuration > 0)
	clone:SetAttribute("LinkedProtection", false)
	clone:SetAttribute("Phase4LinkedActive", false)
	clone:SetAttribute("ShieldDamageLocked", false)
	clone:SetAttribute("Shield", 0)
	clone:SetAttribute("MaxShield", 0)
	clone:SetAttribute("FutureSightCharges", 0)
	clone:SetAttribute("Defense", 0)
	for name in pairs(clone:GetAttributes()) do
		if name:sub(1, 8) == "Passive_" then
			clone:SetAttribute(name, false)
		end
	end
	clone:SetAttribute("EncounterEnded", false)
	clone:SetAttribute("CloneAttackCount", 0)
	clone:SetAttribute("CloneState", appearanceDuration > 0 and "Materializing" or "Waiting")
	local parts = {}
	for _, value in ipairs(clone:GetDescendants()) do
		if
			value:IsA("LuaSourceContainer")
			or value:IsA("BillboardGui")
			or value:IsA("Highlight")
			or mode ~= "Illusion"
				and (value:IsA("Shirt") or value:IsA("Pants") or value:IsA("Decal") or value:IsA("Texture"))
		then
			value:Destroy()
		elseif value:IsA("BasePart") then
			if mode ~= "Illusion" then
				value.Material = Enum.Material.Neon
				value.Color = Color3.fromRGB(255, 226, 54)
				value.Transparency = value.Name == "HumanoidRootPart" and 1 or mode == "HourDebt" and 0.7 or 0.42
			end
			value.CanCollide = false
			value.CanTouch = false
			value.CanQuery = mode == "ShieldGate" or mode == "Normal"
			value.CastShadow = mode == "Illusion"
			parts[value] = value.Transparency
			if appearanceDuration > 0 then
				value.Transparency = 1
			end
			if value:IsA("MeshPart") and mode ~= "Illusion" then
				value.TextureID = ""
			end
		elseif value:IsA("SpecialMesh") and mode ~= "Illusion" then
			value.TextureId = ""
			value.VertexColor = Vector3.one
		elseif value:IsA("Trail") then
			value.Enabled = false
		end
	end
	local reference = clone:FindFirstChild("EncounterOwner")
	if reference then
		reference:Destroy()
	end
	reference = Instance.new("ObjectValue")
	reference.Name = "EncounterOwner"
	reference.Value = owner
	reference.Parent = clone
	clone.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	clone.Humanoid.DisplayName = clone.Name
	clone.Humanoid.BreakJointsOnDeath = false
	clone.Humanoid.RequiresNeck = false
	if mode == "ShieldGate" or mode == "Normal" then
		clone.Humanoid.MaxHealth = math.clamp(
			options.MaxHealth
				or (mode == "ShieldGate" and Config.ShieldGateCloneMaxHealth or Config.NormalCloneMaxHealth)
				or 1000,
			1,
			10000
		)
	end
	clone.Humanoid.Health = clone.Humanoid.MaxHealth
	if mode~="ShieldGate" then
		local immunity=Instance.new("ForceField") immunity.Name="GoldenCloneProtection" immunity.Visible=false immunity.Parent=clone
	end
	local frame = options.Frame and Placement.Validate(owner, options.Frame) or spawnFrame(owner, serial)
	if not frame then
		clone:Destroy()
		return nil
	end
	clone:PivotTo(frame * clone.HumanoidRootPart.CFrame:Inverse() * clone:GetPivot())
	clone.Parent = Runtime.Summons
	Collision.Configure(clone)
	Indicator.Configure(clone)
	Registry.For(clone, "P1NormalSlash").Pose("Idle", 0.15)
	if mode == "ShieldGate" then
  Weapon.SetUnarmed(clone, options.Role == "Elementalist")
 elseif math.floor(phase) == 3 then
  Weapon.SetUnarmed(clone, true)
 end
	local now = Time.EncounterNow(nil)
	local record = {
		Owner = owner,
		OwnerHumanoid = owner.Humanoid,
		Actor = clone,
		Humanoid = clone.Humanoid,
		Mode = mode,
		Target = options.Target,
		AttackName = options.AttackName,
		Parts = parts,
		State = appearanceDuration > 0 and "Materializing" or "Waiting",
		AppearanceAt = now,
		AppearanceDuration = appearanceDuration,
		ReadyAt = now + (mode == "HourDebt" and (options.Delay or 15) or 0),
		HoldDuration = math.max(0, options.HoldDuration or (mode == "Normal" and 2 or 0)),
		FadeDuration = math.max(0.1, options.FadeDuration or 1.2),
		Pool = options.Pool,
		AttackInterval = mode == "ShieldGate"
   and require(BossSystem.Attacks.Shared.ShieldBreakCombat).AttackInterval(options.Role)
   or options.AttackInterval,
		Role = options.Role,
		ExpiresAt = options.Duration and now + options.Duration,
		OnDefeated = options.OnDefeated,
		OnHealthUpdate = options.OnHealthUpdate,
		Generation = owner:GetAttribute("PhaseGeneration") or 0,
		MirrorOwner = mode == "Illusion" and options.MirrorOwner == true,
		MirrorReadyAt = now + (options.MirrorDelay or 0),
		WorldOffset = Vector3.zero,
		MirrorMotors = {},
	}
	if record.MirrorOwner then
		require(BossSystem.Boss.BossLocomotion).Release(clone)
		record.Actor.HumanoidRootPart.Anchored = true
		record.WorldOffset = clone.HumanoidRootPart.Position - owner.HumanoidRootPart.Position
		for _, joint in ipairs(clone:GetDescendants()) do
			if joint:IsA("Motor6D") and joint.Name ~= "RightGrip" and joint.Name ~= "BossSwordGrip" then
				local source = owner:FindFirstChild(joint.Name, true)
				if source and source:IsA("Motor6D") then
					table.insert(record.MirrorMotors, { Source = source, Copy = joint })
				end
			end
		end
	end
	if appearanceDuration > 0 and mode ~= "Illusion" then
		 
		local cast = Effects.NewCast(owner, "CloneMaterialization", appearanceDuration + 0.2)
		record.AppearanceCast = cast
		local halo = Effects.AcquirePart()
		halo.Name = "GildedEchoEntrance"
		halo.Size = Vector3.new(0.1, 8, 8)
		halo.Shape = Enum.PartType.Cylinder
		halo.Color = Color3.fromRGB(255, 232, 81)
		halo.Transparency = 0.45
		halo.CFrame = CFrame.new(clone.HumanoidRootPart.Position - Vector3.new(0, 2.8, 0))
			* CFrame.Angles(0, 0, math.pi / 2)
		halo.Parent = Runtime.Effects
		cast:Add(halo)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "CloneEntranceGoldenMotes"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 242, 160), Color3.fromRGB(255, 198, 20))
		sparks.LightEmission = 1
		sparks.Rate = 35
		sparks.Lifetime = NumberRange.new(0.4, 0.8)
		sparks.Speed = NumberRange.new(3, 7)
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		sparks.Parent = halo
		Effects:Create(halo, TweenInfo.new(appearanceDuration), { Size = Vector3.new(0.1, 12, 12), Transparency = 1 })
			:Play()
		clone:SetAttribute("CloneAppearanceStartedAt", workspace:GetServerTimeNow())
	elseif appearanceDuration > 0 then
		record.AppearanceCast = api.IllusionCardRing(owner, clone, appearanceDuration)
		clone:SetAttribute("CloneAppearanceStartedAt", workspace:GetServerTimeNow())
	end
	if mode == "HourDebt" then
		clone:SetAttribute("RecordedAttack", options.AttackName)
	end
	 
	 
	if mode ~= "HourDebt" then
		beginAudio(record)
	end
	local set = owners[owner]
	if not set then
		set = {}
		owners[owner] = set
	end
	set[record] = true
	owner:SetAttribute("CloneSummons", (owner:GetAttribute("CloneSummons") or 0) + 1)
	local handle = { Actor = clone, Mode = mode }
	function handle:Cancel(reason)
		cancel(record, reason)
	end
	function handle:IsActive()
		return not record.Closed and not record.Cancelled
	end
	function handle:IsAlive()
		return not record.Closed and not record.Cancelled and not not alive(record.Actor)
	end
	function handle:SetMirrorOffset(offset)
		if record.MirrorOwner and typeof(offset) == "Vector3" then
			record.WorldOffset = offset
		end
	end
	record.Handle = handle
	if mode == "ShieldGate" then
		record.MovementCast = require(BossSystem.Mechanics.Clones.ShieldGateMovement).Start(
			clone,
			options.Role,
			function()
				return chooseTarget(record)
			end
		)
	end
	ensureMonitor()
	return handle
end
function api.Count(owner, mode)
	local count = 0
	for record in pairs(owners[owner] or {}) do
		if not record.Closed and not record.Cancelled and (not mode or record.Mode == mode) then
			count += 1
		end
	end
	return count
end
function api.SpawnPersistent(owner, target, count, materializeDuration)
	local result = {}
	for _ = api.Count(owner, "Persistent") + 1, math.clamp(count or 2, 0, 2) do
		local handle =
			api.Create(owner, { Mode = "Persistent", Target = target, MaterializeDuration = materializeDuration })
		if handle then
			table.insert(result, handle)
		end
	end
	return result
end
function api.CancelMode(owner, mode, reason)
	local pending = {}
	for record in pairs(owners[owner] or {}) do
		if record.Mode == mode then
			table.insert(pending, record)
		end
	end
	for _, record in ipairs(pending) do
		cancel(record, reason)
	end
end
function api.CancelAll(owner, reason)
	local pending = {}
	for record in pairs(owners[owner] or {}) do
		table.insert(pending, record)
	end
	for _, record in ipairs(pending) do
		cancel(record, reason)
	end
end
function api.AdvanceDeferred(owner, seconds, force, limit)
	local now = Time.EncounterNow(nil)
	local changed = 0
	for record in pairs(owners[owner] or {}) do
		if record.Mode == "HourDebt" and record.State == "Waiting" and not record.Closed and not record.Cancelled then
			if limit and changed >= limit then
				break
			end
			record.ReadyAt = force and now + changed * 0.15
				or math.max(now + changed * 0.15, record.ReadyAt - math.clamp(seconds, 0, 60))
			changed += 1
		end
	end
	return changed
end
return api
