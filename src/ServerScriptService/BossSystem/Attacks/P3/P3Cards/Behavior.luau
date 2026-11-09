local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Cards = require(BossSystem.Mechanics.Clones.CloneController)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local DebuffService=require(BossSystem.Combat.CardDebuffService)
 local debuffs=DebuffService.Names
	local Players = game:GetService("Players")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local remote = game.ReplicatedStorage.BossCombatEffects
	local core = Registry.For(actor, "P1CombatCore")
	local GOLD, WHITE = Color3.fromRGB(249, 210, 66), Color3.fromRGB(255, 255, 255)
	local PALE_GOLD = Style.PALE_GOLD
	local SPARKLE = Style.SPARKLE
	local CARD_SIZE = Vector3.new(2.5, 3.5, 0.09)
	local GHOST_INTERVAL = 0.04  
	local SHARD_COUNT = 10  
	local rng = Random.new()
	local api = { Cooldown = Config.P3CardsCooldown or 10 }
	local active = {}
 api.Debuffs=debuffs
	local params = Runtime.FilterFor(actor)
	local function distanceToSegment(point, first, last)
		local delta = last - first
		local length = delta:Dot(delta)
		local alpha = length > 0.001 and math.clamp((point - first):Dot(delta) / length, 0, 1) or 0
		return (point - first - delta * alpha).Magnitude
	end
	function api.CanUse(target)
		return math.floor(actor:GetAttribute("Phase") or 1) == 3
			and core.Active()
			and core.Alive(target)
			and require(BossSystem.Combat.AttackTargetContinuity).Player(target) ~= nil
	end
	function api.Combo(target,options)
  options=options or {}
  local fake=options.Fake==true
  local mis=Registry.For(actor,"P3Misdirection(Passive)")
  local clue=not fake and mis.CueEnabled("P3Cards")
		if not (fake and core.Active() and core.Alive(target)) and not api.CanUse(target) then
			return false
		end
		local function perform(callback)
   if fake then return callback() end
   return core.Perform(target,"P3Cards",callback)
  end
  return perform(function()
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local count = rng:NextInteger(Config.P3CardsMinCount or 8, Config.P3CardsMaxCount or 20)
   actor:SetAttribute("P3CardsCount",count)
			local speed = math.clamp(Config.P3CardsSpeed or 210, 150, 320)
			local interval = math.clamp(Config.P3CardsThrowInterval or 0.1, 0.08, 0.18)
			local range = math.clamp(Config.P3CardsMaxDistance or 420, 300, 600)
			 
			 
			local amplitude = math.clamp(Config.P3CardsZigzagAmplitude or 6.5, 2, 10)
			local frequency = math.clamp(Config.P3CardsZigzagFrequency or 2.5, 1, 4)
			local sharpness = math.clamp(Config.P3CardsZigzagSharpness or 0.85, 0, 1)
			local hitRadius = math.clamp(Config.P3CardsHitRadius or 2.6, 1.8, 3.5)
			local cast = Effects.NewCast(actor, "P3ThrownZigzagCards", range / speed + count * interval + 0.9)
			active[cast] = true
			api.LastCast = cast
   if fake then api.LastFakeCast=cast end
   cast.IsMisdirectionFake=fake
			api.Records = {}
			cast.OnDispose = function()
				active[cast] = nil
			end
			local function valid()
				return cast:Alive()
					and actor.Parent
					and core.Alive(actor)
					and not actor:GetAttribute("EncounterEnded")
					and math.floor(actor:GetAttribute("Phase") or 1) == 3
					and not actor:GetAttribute("PhaseTransitionInProgress")
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
			end
			 
			local flatRing = Visuals.flatRing({
				cast = cast,
				core = core,
				Effects = Effects,
			})
			local puff = Visuals.puff({
				cast = cast,
				core = core,
				GOLD = GOLD,
				SPARKLE = SPARKLE,
				WHITE = WHITE,
				Effects = Effects,
			})

			 
			 
			local shatter = Visuals.shatter({
				cast = cast,
				core = core,
				WHITE = WHITE,
				Effects = Effects,
				SHARD_COUNT = SHARD_COUNT,
				rng = rng,
				puff = puff,
			})

			 
			 
			local handPosition = Visuals.handPosition({
				actor = actor,
				core = core,
			})
			local chargeUp = Visuals.chargeUp({
				cast = cast,
				core = core,
				handPosition = handPosition,
				GOLD = GOLD,
				valid = valid,
				Effects = Effects,
				CARD_SIZE = CARD_SIZE,
				SPARKLE = SPARKLE,
				WHITE = WHITE,
			})

			cast:Step(function()
				if not valid() then
					cast:Dispose()
					return false
				end
				return true
			end)
			if not fake then core.Face(target) end
			if not fake then core.PoseAngles({ RightShoulder = { 55, 0, -20 }, LeftShoulder = { 45, 0, 30 } }, 0.12) end
			if not fake then actor:SetAttribute("AttackState", "Cards: zigzag volley") end
			actor:SetAttribute("P3CardsLaunched", 0)
   actor:SetAttribute("P3CardsProjectileSpeed",speed)
   actor:SetAttribute("P3CardsRange",range)
			actor:SetAttribute("P3CardsBaseDamage", Config.P3CardsDamage or 3)
			chargeUp()
			if clue and core.Alive(target) then
    local origin=core.Root.Position+Vector3.new(0,.5,0)+core.Root.CFrame.LookVector*3
    local delta=target.HumanoidRootPart.Position-origin
    local flight=math.max(0,(delta.Magnitude-hitRadius)/speed)
    local lead=Config.P3MisdirectionClueLead or .25
    if flight<lead then
     local direction=delta.Magnitude>.01 and delta.Unit or core.Root.CFrame.LookVector
     for index=1,count do
      local aim=CFrame.Angles(0,math.rad((index-(count+1)*.5)*2),0):VectorToWorldSpace(direction)
      cast:Schedule(math.max(0,.3+(index-1)*interval+flight-lead),function()
       if valid() then
        mis.Cue(core,nil,origin+aim*4)
        core.MotionLine("MisdirectionTrueCardGlint",origin+aim*3,origin+aim*7,.25,WHITE,.12)
        actor:SetAttribute("MisdirectionCardsClueAt",workspace:GetServerTimeNow());actor:SetAttribute("MisdirectionCard"..index.."ClueAt",workspace:GetServerTimeNow())
       end
      end)
     end
    end
   end
   if not core.WaitFor(0.3) or not valid() then
				cast:Dispose()
				return false
			end
			for index = 1, count do
				if not core.Active() or not core.Alive(target) or not valid() then
					cast:Dispose()
					return false
				end
				local origin = core.Root.Position + Vector3.new(0, 0.5, 0) + core.Root.CFrame.LookVector * 3
				local delta = target.HumanoidRootPart.Position - origin
				local direction = delta.Magnitude > 0.1 and delta.Unit or core.Root.CFrame.LookVector
				direction = CFrame.Angles(0, math.rad((index - (count + 1) * 0.5) * 2), 0):VectorToWorldSpace(direction)
				local right = Vector3.new(-direction.Z, 0, direction.X)
				right = right.Magnitude > 0.01 and right.Unit or core.Root.CFrame.RightVector
				local card = Cards.Card(cast, index)
				card.Name = "P3ThrownZigzagCard"
				card.Size = CARD_SIZE
				card.CFrame = CFrame.lookAt(origin, origin + direction)
				 
				local cardColor = index % 2 == 0 and WHITE or GOLD
				card.Color = cardColor
				card.Material = Enum.Material.Neon
				local fx = {}
				local t0 = Instance.new("Attachment")
				t0.Position = Vector3.new(0, 1.75, 0)
				t0.Parent = card
				table.insert(fx, t0)
				local t1 = Instance.new("Attachment")
				t1.Position = Vector3.new(0, -1.75, 0)
				t1.Parent = card
				table.insert(fx, t1)
				local trail = Instance.new("Trail")
				trail.Name = "CardGoldenTrail"
				trail.Attachment0 = t0
				trail.Attachment1 = t1
				trail.WidthScale =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.3), NumberSequenceKeypoint.new(1, 0) })
				trail.FaceCamera = true
				trail.Lifetime = 0.4
				trail.LightEmission = 1
				trail.Color = ColorSequence.new(cardColor, PALE_GOLD)
				trail.Transparency =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
				trail.Parent = card
				table.insert(fx, trail)
				 
				 
				local light = Instance.new("PointLight")
				light.Color = cardColor
				light.Range = 12
				light.Brightness = 2
				light.Parent = card
				table.insert(fx, light)
				local sparks = Instance.new("ParticleEmitter")
				sparks.Name = "CardTrailSparks"
				sparks.Texture = SPARKLE
				sparks.Rate = 40
				sparks.Color = ColorSequence.new(GOLD, PALE_GOLD)
				sparks.Lifetime = NumberRange.new(0.15, 0.4)
				sparks.Speed = NumberRange.new(0, 2)
				sparks.SpreadAngle = Vector2.new(45, 45)
				sparks.LightEmission = 0.9
				sparks.Size =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
				sparks.Parent = card
				table.insert(fx, sparks)
				local function release()
					for _, item in ipairs(fx) do
						item:Destroy()
					end
					Effects.Release(card)
				end
				 
				local afterimage = Visuals.afterimage({
					cast = cast,
					core = core,
					CARD_SIZE = CARD_SIZE,
					cardColor = cardColor,
					Effects = Effects,
				})
				local lease = Effects.LeaseId(card)
				local started = cast:Now()
				local previous = origin
				local side = index % 2 == 0 and 1 or -1
				local lastNow, lastGhost, lastTurn, flash, bank = started, -1, -1, 0, 0
				local hit = {}
    local cued=clue and (target.HumanoidRootPart.Position-origin).Magnitude/speed<(Config.P3MisdirectionClueLead or .25)
    local fakeImpactDistance=(target.HumanoidRootPart.Position-origin).Magnitude
				local record = {
					Part = card,
					Origin = origin,
					Direction = direction,
					Hit = hit,
					Index = index,
					MaxDistance = range,
				}
				api.Records[#api.Records + 1] = record
				actor:SetAttribute("P3CardsLaunched", index)
				Audio.Emit(actor, "CardThrow", origin)
				puff(origin, 6)  
				cast:Step(function(_, now)
					if not valid() or not card.Parent or Effects.LeaseId(card) ~= lease then
						for _, item in ipairs(fx) do
							item:Destroy()
						end
						return false
					end
					local dt = math.max(now - lastNow, 1 / 240)
					lastNow = now
					local elapsed = now - started
					local distance = math.min(range, elapsed * speed)
					 
					 
					 
					local phase = elapsed * frequency
					local sine = math.sin(phase * math.pi * 2)
					local tri = math.abs(((phase + 0.75) % 1) * 4 - 2) - 1
					local zigzag = (sine * (1 - sharpness) + tri * sharpness) * side
					local position = origin
						+ direction * distance
						+ right * zigzag * amplitude * math.min(1, elapsed / 0.15)
					local motion = position - previous
     if fake and distance>=math.max(0,fakeImpactDistance-speed*.02) then release();return false end
     if clue and not cued and core.Alive(target) then
      local projected=(target.HumanoidRootPart.Position-origin):Dot(direction)
      if distance>=math.max(0,projected-speed*(Config.P3MisdirectionClueLead or .25)) then
       cued=true;mis.Cue(core,card,position);actor:SetAttribute("MisdirectionCardsClueAt",workspace:GetServerTimeNow())
      end
     end
					local wall = motion.Magnitude > 0.01 and workspace:Raycast(previous, motion, params())
					if wall then
						record.Blocked = true
						shatter(wall.Position, wall.Normal, cardColor)  
						release()
						return false
					end
					for _, character in ipairs(core.Characters()) do
						local player = Players:GetPlayerFromCharacter(character)
						local r = character:FindFirstChild("HumanoidRootPart")
						if
							r
							and player
							and not fake
       and player.Character == character
							and core.Alive(character)
							and not hit[character]
							and distanceToSegment(r.Position, previous, position) <= hitRadius
						then
							hit[character] = true
							record.LastDamage = core.Damage(character, Config.P3CardsDamage or 3, "P3Cards")
							if record.LastDamage > 0 then
								record.LastDebuff,record.LastDebuffDuration=nil,nil
        -- P3 cards only deal damage: debuffs come from the P3.5Debuffer passive (any attack, from Phase 3.5)
								Audio.Emit(actor, "CardBurst", r)
								local burstPart = cast:Add(
									core.Part("CardHitBurst", CFrame.new(r.Position), Vector3.one * 1.5, cardColor, 0.3)
								)
								burstPart.Shape = Enum.PartType.Ball
								burstPart.Material = Enum.Material.Neon
								Effects
									:Create(burstPart, TweenInfo.new(0.3), { Size = Vector3.one * 4, Transparency = 1 })
									:Play()
								local hitParticles = Instance.new("ParticleEmitter")
								hitParticles.Name = "CardHitSparkles"
								hitParticles.Texture = SPARKLE
								hitParticles.Rate = 0
								hitParticles.Color = ColorSequence.new(GOLD, WHITE)
								hitParticles.Lifetime = NumberRange.new(0.25, 0.55)
								hitParticles.Speed = NumberRange.new(8, 18)
								hitParticles.SpreadAngle = Vector2.new(180, 180)
								hitParticles.LightEmission = 0.7
								hitParticles.Size = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0.6),
									NumberSequenceKeypoint.new(1, 0),
								})
								hitParticles.Parent = burstPart
								hitParticles:Emit(20)
								 
								Effects.ReleaseAfter(burstPart, 0.6)
								 
								flatRing(r.Position - Vector3.new(0, 2.5, 0), cardColor, 2, 14, 0.35)
								remote:FireClient(player, "EtherealCardHit", { Intensity = 0.6 })
							end
						end
					end
					 
					local turn = math.floor((phase - 0.25) * 2)
					if turn > lastTurn then
						lastTurn = turn
						flash = 1
						sparks:Emit(10)
						afterimage(card.CFrame, 0.15, 0.35)
					end
					flash = math.max(0, flash - dt * 5)
					card.Color = cardColor:Lerp(WHITE, flash)
					light.Brightness = 2 + 4 * flash
					light.Range = 12 + 6 * flash
					 
					if elapsed - lastGhost >= GHOST_INTERVAL then
						lastGhost = elapsed
						afterimage(card.CFrame, 0.45, 0.28)
					end
					 
					local sideways = motion:Dot(right) / dt
					bank = bank + (math.clamp(-sideways / 60, -1, 1) * 0.9 - bank) * (1 - math.exp(-dt * 25))
					card.CFrame = CFrame.lookAt(
						position,
						position + (motion.Magnitude > 0.01 and motion.Unit or direction)
					) * CFrame.Angles(0, 0, bank + math.sin(elapsed * 9 + index) * 0.12)
					previous = position
					record.Distance = distance
					if distance >= range then
						puff(position, 8)
						release()
						return false
					end
					return true
				end)
				if index < count and not core.WaitFor(interval) then
					cast:Dispose()
					return false
				end
			end
			 
			return true
		end)
	end
	function api.Dispose()
		local pending = {}
		for cast in pairs(active) do
			pending[#pending + 1] = cast
		end
		for _, cast in ipairs(pending) do
			cast:Dispose()
		end
	end
	return api
end
