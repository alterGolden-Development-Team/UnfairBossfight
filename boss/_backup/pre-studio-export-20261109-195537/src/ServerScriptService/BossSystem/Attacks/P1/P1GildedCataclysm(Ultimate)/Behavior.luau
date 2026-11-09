local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local registry = require(BossSystem.Combat.AttackRegistry)
	local effects = require(BossSystem.Combat.EffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local status = require(BossSystem.Combat.StatusEffectService)
	local qte = require(BossSystem.Combat.CataclysmQTEService)
	local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local placement = require(BossSystem.Encounter.ArenaPlacement)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local Debris = game:GetService("Debris")
	local core = registry.For(actor, "P1CombatCore")
	local root, humanoid, melee = core.Root, core.Humanoid, core.Melee
	local api = {
		IsUltimate = true,
		UltimatePhase = 1,
		Cooldown = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig")).CataclysmCooldown or 45,
	}
	local gold = Style.gold
	local whiteGold = Style.whiteGold
	local stone = Style.stone
	local arena = workspace:FindFirstChild("GoldenGrasslandArena")
	local grass = arena and arena:FindFirstChild("Grassland")
	local random = Random.new()
	local repeatedLines = {
		"Have this one. All for you.",
		"Let's play with this one.",
		"You survived it once. Let's try again.",
		"Think you can dodge it twice?",
	}
	local ownerReference = actor:FindFirstChild("EncounterOwner")
	local encounterOwner = ownerReference and ownerReference:IsA("ObjectValue") and ownerReference.Value or actor
	local encounterHumanoid = encounterOwner:FindFirstChildOfClass("Humanoid")
	local UPRIGHT = CFrame.Angles(0, 0, math.pi * 0.5)
	local DEBRIS_GRAVITY = 120

	local function encounterAlive()
		return encounterOwner.Parent
			and encounterHumanoid
			and encounterHumanoid.Health > 0
			and not encounterOwner:GetAttribute("EncounterEnded")
	end

	local function phase()
		return tonumber(actor:GetAttribute("Phase")) or 1
	end
	function api.CanUse(char)
		return phase() >= 1
			and phase() <= 1.5
			and actor:GetAttribute("IsGoldenClone") ~= true
			and core.Active()
			and core.Alive(char)
	end
	local function targetOrNext(char)
		if core.Alive(char) then
			return char
		end
		return melee.GetTarget()
	end
	local function canChain(char)
		if not core.Alive(char) then
			return false
		end
		local player = Players:GetPlayerFromCharacter(char)
		local targetRoot = char:FindFirstChild("HumanoidRootPart")
		return player
			and targetRoot
			and not targetRoot.Anchored
			and not char:GetAttribute("ParryFrozen")
			and not char:GetAttribute("ExecutionPending")
			and not player:GetAttribute("ExecutionPending")
			and not player:GetAttribute("PermanentlyDefeated")
			and not player:GetAttribute("ViewAsServer")
			and not status.IsLocked(player)
			and not status.IsDebuffImmune(char)
	end
	local function chainTarget(preferred)
		if canChain(preferred) then
			return preferred
		end
		local closest, distance
		for _, char in ipairs(core.Characters()) do
			if canChain(char) then
				local current = (char.HumanoidRootPart.Position - root.Position).Magnitude
				if not distance or current < distance then
					closest = char
					distance = current
				end
			end
		end
		return closest
	end
	local function groundAt(position)
		local ground = placement.GroundPoint(position, { Margin = 2, Clamp = true })
		if ground then
			return ground.Y
		end
		local _, y = core.FloorY(position + Vector3.new(0, 30, 0), core.Params())
		return y or (arena and arena:GetAttribute("GroundY")) or 0
	end
	local function distanceToSegment(point, a, b)
		local delta = b - a
		local t = delta.Magnitude > 0.001 and math.clamp((point - a):Dot(delta) / delta:Dot(delta), 0, 1) or 0
		return (point - (a + delta * t)).Magnitude, t
	end
	local makePart = Visuals.makePart({
		core = core,
	})

	local setupDisc = Visuals.setupDisc({})

	local sparkEmitter = Visuals.sparkEmitter({
		whiteGold = whiteGold,
		gold = gold,
	})

	local screenGrade = Visuals.screenGrade({
		effects = effects,
		actor = actor,
		Lighting = Lighting,
		Debris = Debris,
		Time = Time,
	})

	local telegraph = Visuals.telegraph({
		effects = effects,
		actor = actor,
		groundAt = groundAt,
		UPRIGHT = UPRIGHT,
		setupDisc = setupDisc,
		makePart = makePart,
		gold = gold,
		whiteGold = whiteGold,
		Time = Time,
	})

	local impactBurst = Visuals.impactBurst({
		effects = effects,
		actor = actor,
		groundAt = groundAt,
		makePart = makePart,
		gold = gold,
		setupDisc = setupDisc,
		UPRIGHT = UPRIGHT,
		whiteGold = whiteGold,
		sparkEmitter = sparkEmitter,
		DEBRIS_GRAVITY = DEBRIS_GRAVITY,
		random = random,
		stone = stone,
		Time = Time,
	})

	local sigil = Visuals.sigil({
		effects = effects,
		actor = actor,
		groundAt = groundAt,
		makePart = makePart,
		gold = gold,
		setupDisc = setupDisc,
		UPRIGHT = UPRIGHT,
		whiteGold = whiteGold,
		Time = Time,
	})

	function api.Shockwave(center, radius, damage, final, excludedCharacter)
		local duration = final and 1.9 or 1.5
		local cast = effects.NewCast(actor, final and "CataclysmFinalWave" or "CataclysmBlockWave", duration + 0.2)
		local anchor = makePart(cast, "CataclysmWaveAnchor", CFrame.new(center), Vector3.one * 0.1, gold, 1)
		local count = math.clamp(math.floor(radius / 5), 32, 80)
		local puff = math.clamp(radius * math.pi * 2 / count * 0.4, 5, 26)
		local height = final and 1.6 or 1.1

		local layers = {
			{ Width = final and 4.5 or 3.2, Base = 0.02, Color = whiteGold },
			{ Width = final and 12 or 8, Base = 0.55, Color = gold },
		}
		if final then
			layers[3] = { Width = 26, Base = 0.82, Color = gold }
		end

		local directions, attachments = {}, {}
		local groundColor = Visuals.groundLook(center)
		for index = 1, count do
			local angle = (index - 1) * math.pi * 2 / count
			directions[index] = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local attachment = Instance.new("Attachment")
			attachment.Parent = anchor
			attachments[index] = attachment
			local dust = Instance.new("ParticleEmitter")
			dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
			dust.Color = ColorSequence.new(groundColor:Lerp(Color3.new(1, 1, 1), 0.25), groundColor:Lerp(Color3.new(0, 0, 0), 0.2))
			dust.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
			dust.Size =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, puff * 0.5), NumberSequenceKeypoint.new(1, puff) })
			dust.Lifetime = NumberRange.new(0.7, 1.2)
			dust.Speed = NumberRange.new(2, 6)
			dust.SpreadAngle = Vector2.new(40, 40)
			dust.Drag = 2
			dust.Rate = final and 10 or 7
			dust.Parent = attachment
		end
		for _, layer in ipairs(layers) do
			layer.Beams = {}
			for index = 1, count do
				local beam = Instance.new("Beam")
				beam.Name = final and "CataclysmArenaShockwave" or "CataclysmGroundShockwave"
				beam.Attachment0 = attachments[index]
				beam.Attachment1 = attachments[index % count + 1]
				beam.Width0 = layer.Width
				beam.Width1 = layer.Width
				beam.FaceCamera = true
				beam.LightEmission = 1
				beam.Color = ColorSequence.new(layer.Color)
				beam.Transparency = NumberSequence.new(layer.Base)
				beam.Segments = 1
				beam.Parent = anchor
				layer.Beams[index] = beam
			end
		end

		local began, previous, hit, shown = Time.EncounterNow(actor), 0, {}, -1
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			if not encounterAlive() then
				cast:Dispose()
				return false
			end
			local t = math.clamp((Time.EncounterNow(actor) - began) / duration, 0, 1)
			local current = 2 + (radius - 2) * t

			for index, attachment in ipairs(attachments) do
				local dir = directions[index]
				attachment.Position = Vector3.new(dir.X * current, height, dir.Z * current)
			end
			local level = math.floor(t ^ 2 * 30) / 30
			if level ~= shown then
				shown = level
				for _, layer in ipairs(layers) do
					local fade = NumberSequence.new(layer.Base + (1 - layer.Base) * level)
					for _, beam in ipairs(layer.Beams) do
						beam.Transparency = fade
					end
				end
			end

			for _, char in ipairs(core.Characters()) do
				if char ~= excludedCharacter and core.Alive(char) then
					local h = char:FindFirstChildOfClass("Humanoid")
					local offset = char.HumanoidRootPart.Position - center
					local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
					if
						not hit[h]
						and offset.Y >= -1
						and offset.Y <= 5
						and distance >= math.max(0, previous - 3)
						and distance <= current + 3
					then
						hit[h] = true
						core.Damage(char, damage)
					end
				end
			end
			previous = current
			return t < 1
		end)
		return cast
	end

	local chainVisual = Visuals.chainVisual({
		makePart = makePart,
		gold = gold,
		whiteGold = whiteGold,
		sparkEmitter = sparkEmitter,
	})

	local spawnChunk = Visuals.spawnChunk({
		effects = effects,
		actor = actor,
		random = random,
		grass = grass,
		groundAt = groundAt,
		makePart = makePart,
		stone = stone,
		Audio = Audio,
		impactBurst = impactBurst,
		gold = gold,
		sparkEmitter = sparkEmitter,
		Time = Time,
	})

	local function launchChunk(chunk, char)
		chunk.Launched = true
		chunk.Phase = "Launched"
		Audio.Emit(actor, "CataclysmRockThrow", chunk.Part)
		local start = chunk.Part.Position
		local target = char.HumanoidRootPart.Position
		local goal = Vector3.new(target.X, groundAt(target) + chunk.Part.Size.Y * 0.5, target.Z)
		local duration = math.max(0.18, (goal - start).Magnitude / (actor:GetAttribute("CataclysmBlockSpeed") or 145))
		telegraph(goal, chunk.Part.Size.Magnitude * 0.5 + 3, duration)
		core.ScreenEffect("Shake", { Origin = start, Radius = 200, Duration = 0.2, Intensity = 0.3 })

		local trailAnchor = makePart(chunk.Cast, "CataclysmTrailAnchor", CFrame.new(start), Vector3.one * 0.1, gold, 1)
		local half = chunk.Part.Size.Magnitude * 0.3
		local upper, lower = Instance.new("Attachment"), Instance.new("Attachment")
		upper.Position = Vector3.new(0, half, 0)
		lower.Position = Vector3.new(0, -half, 0)
		upper.Parent = trailAnchor
		lower.Parent = trailAnchor
		local trail = Instance.new("Trail")
		trail.Attachment0 = upper
		trail.Attachment1 = lower
		trail.Lifetime = 0.45
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Color = ColorSequence.new(whiteGold, gold)
		trail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		trail.Parent = trailAnchor

		local began, previous = Time.EncounterNow(actor), start
		chunk.Cast:Step(function()
			if not encounterAlive() then
				chunk.Done = true
				chunk.Cast:Dispose()
				return false
			end
			local t = math.clamp((Time.EncounterNow(actor) - began) / duration, 0, 1)
			local position = start:Lerp(goal, t) + Vector3.new(0, math.sin(t * math.pi) * 4, 0)
			local step = position - previous
			local wall = step.Magnitude > 0.001
				and workspace:Blockcast(chunk.Part.CFrame, chunk.Part.Size, step, core.Params())
			local hitChar, hitFraction = nil, 2
			for _, candidate in ipairs(core.Characters()) do
				if core.Alive(candidate) then
					local point = candidate.HumanoidRootPart.Position
					local _, fraction = distanceToSegment(point, previous, position)
					local sweptFrame = CFrame.new(previous:Lerp(position, fraction)) * chunk.Part.CFrame.Rotation
					local offset = sweptFrame:PointToObjectSpace(point)
					local limit = chunk.Part.Size * 0.5 + Vector3.new(1.5, 2.5, 1.5)
					if
						math.abs(offset.X) <= limit.X
						and math.abs(offset.Y) <= limit.Y
						and math.abs(offset.Z) <= limit.Z
						and fraction < hitFraction
					then
						hitChar = candidate
						hitFraction = fraction
					end
				end
			end
			if wall and (not hitChar or wall.Distance <= step.Magnitude * hitFraction) then
				position = previous + step.Unit * wall.Distance
				hitChar = nil
				t = 1
			elseif hitChar then
				position = previous:Lerp(position, hitFraction)
				core.Damage(hitChar, 15)
				t = 1
			end
			chunk.Part.CFrame = CFrame.new(position) * CFrame.Angles(t * 3, t * 7, t * 2)
			trailAnchor.CFrame = CFrame.new(position)
			if t >= 1 then
				chunk.Done = true
				local center = Vector3.new(position.X, groundAt(position) + 0.15, position.Z)
				Audio.Emit(actor, "BlockImpact", center, { Scale = chunk.Part.Size.Magnitude })
				local radius = actor:GetAttribute("CataclysmBlockWaveRadius")
					or actor:GetAttribute("FallingBladeRadius")
					or 225
				api.Shockwave(center, radius, actor:GetAttribute("CataclysmBlockWaveDamage") or 15, false, hitChar)
				impactBurst(center, chunk.Part.Size.Magnitude * 0.6, 14, 8)
				screenGrade({ Brightness = 0.1, Bloom = 0.6, Tint = whiteGold }, 0.03, 0.03, 0.35)
				core.ScreenEffect("Shake", { Origin = center, Radius = radius + 25, Duration = 0.5, Intensity = 0.7 })
				chunk.Cast:Dispose()
				return false
			end
			previous = position
			return true
		end)
	end

	local function runAttack(initialTarget)
		local cast = effects.NewCast(actor, "GildedCataclysmSequence", 35)
		local chunks = {}
		local chain = chainVisual(cast)
		local chainedPlayer, chainedChar, chainedRoot, oldAnchored, lockToken, session
		local released = false
		local groundFrame
		local circle, mood
		local function restoreBoss()
			if not groundFrame then
				return
			end
			if root.Parent then
				local floor = core.FloorY(root.Position, core.Params()) or groundFrame.Y
				root.CFrame = CFrame.new(root.Position.X, floor, root.Position.Z) * root.CFrame.Rotation
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			core.AirborneFloor = nil
			groundFrame = nil
		end
		local function releasePlayer()
			if released then
				return
			end
			released = true
			if chainedRoot and chainedRoot.Parent then
				Audio.Emit(actor, "ChainBreak", chainedRoot)
			end
			if chainedRoot and chainedRoot.Parent then
				chainedRoot.AssemblyLinearVelocity = Vector3.zero
				chainedRoot.AssemblyAngularVelocity = Vector3.zero
				Time.SetAnchored(chainedRoot, oldAnchored)
				if not oldAnchored and chainedPlayer and chainedPlayer.Parent == Players then
					pcall(function()
						chainedRoot:SetNetworkOwner(chainedPlayer)
					end)
				end
			end
			if chainedChar and chainedChar.Parent then
				chainedChar:SetAttribute("CataclysmChained", false)
			end
			if chainedPlayer and lockToken then
				status.SetLocked(chainedPlayer, lockToken, false)
			end
		end
		local function valid()
			return cast:Alive() and core.Active() and root.Parent and humanoid.Health > 0
		end
		local function animate(seconds, fn)
			local began = Time.EncounterNow(actor)
			repeat
				if not Time.WaitForActor(actor) or not valid() then
					return false
				end
				if chainedChar and not core.Alive(chainedChar) then
					return false
				end
				local t = math.clamp((Time.EncounterNow(actor) - began) / seconds, 0, 1)
				fn(t)
				if t == 1 then
					return true
				end
				RunService.Heartbeat:Wait()
			until false
		end
		local function sequence()
			local char = targetOrNext(initialTarget)
			if not char then
				return false
			end
			core.Face(char)
			actor:SetAttribute("AttackState", "Gilded Cataclysm: stomp")
			core.PoseAngles({
				RightHip = { -35, 0, 0 },
				LeftHip = { 8, 0, 0 },
				Waist = { 5, 0, 0 },
				RightShoulder = { 85, 0, -10 },
				RightElbow = { 30, 0, 0 },
				LeftShoulder = { 10, 0, -10 },
			}, 0.15)
			if not core.WaitFor(0.25) then
				return false
			end
			core.PoseAngles({
				RightHip = { 0, 0, 0 },
				LeftHip = { 0, 0, 0 },
				Waist = { 12, 0, 0 },
				RightShoulder = { 20, 0, -15 },
				RightElbow = { 20, 0, 0 },
			}, 0.08)
			local origin = root.Position
			Audio.Emit(actor, "CataclysmStomp", origin)
			core.ScreenEffect("Shake", { Origin = origin, Radius = 450, Duration = 0.9, Intensity = 0.9 })
			impactBurst(origin, 38, 18, 14)
			screenGrade({ Brightness = 0.12, Bloom = 0.8, Tint = whiteGold }, 0.03, 0.04, 0.5)
			circle = sigil(origin, actor:GetAttribute("CataclysmSigilRadius") or 100)
			mood = screenGrade({
				Brightness = -0.07,
				Contrast = 0.12,
				Saturation = -0.12,
				Tint = Color3.fromRGB(255, 236, 190),
				Bloom = 0.7,
			}, 0.7, math.huge, 1.2)
			 
			local blocks = Difficulty.Mercy("CataclysmBlocks", actor) or { 3, 8 }
			local count = random:NextInteger(blocks[1], blocks[2])
			local smallIndex = random:NextInteger(1, count)
			local largeIndex = random:NextInteger(1, count - 1)
			if largeIndex >= smallIndex then
				largeIndex += 1
			end
			local startAngle = random:NextNumber(0, math.pi * 2)
			actor:SetAttribute("LastCataclysmBlockCount", count)
			for index = 1, count do
				local angle = startAngle + index * math.pi * 2 / count + random:NextNumber(-0.22, 0.22)
				local distance = random:NextNumber(45, 85)
				local scale = index == smallIndex and random:NextNumber(9, 13)
					or index == largeIndex and random:NextNumber(27, 34)
					or random:NextNumber(13, 30)
				chunks[index] = spawnChunk(
					index,
					origin + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance),
					scale
				)
			end
			actor:SetAttribute("AttackState", "Gilded Cataclysm: rising earth")
			groundFrame = root.CFrame
			core.AirborneFloor = groundFrame.Y
			local airborneFrame = groundFrame + Vector3.new(0, actor:GetAttribute("CataclysmHoverHeight") or 70, 0)
			local aura = makePart(cast, "CataclysmAirborneAura", root.CFrame, Vector3.one * 14, gold, 0.85)
			aura.Shape = Enum.PartType.Ball
			local auraLight = Instance.new("PointLight")
			auraLight.Color = gold
			auraLight.Range = 60
			auraLight.Brightness = 4
			auraLight.Shadows = false
			auraLight.Parent = aura
			local auraSparks = sparkEmitter(aura, 60, 1.6)
			local floorY = groundAt(groundFrame.Position)
			local pillarX, pillarZ = groundFrame.X, groundFrame.Z
			local pillar = setupDisc(
				makePart(
					cast,
					"CataclysmAscentPillar",
					CFrame.new(pillarX, floorY + 0.5, pillarZ) * UPRIGHT,
					Vector3.new(1, 8, 8),
					whiteGold,
					0.55
				)
			)
			local function followPillar(thickness)
				local height = math.max(root.Position.Y - floorY, 1)
				local width = math.max(thickness, 0.05)
				pillar.Size = Vector3.new(height, width, width)
				pillar.CFrame = CFrame.new(pillarX, floorY + height * 0.5, pillarZ) * UPRIGHT
			end
			core.ScreenEffect("Shake", { Origin = origin, Radius = 450, Duration = 0.75, Intensity = 0.35 })
			core.MotionLine("CataclysmAscent", root.Position, airborneFrame.Position, 1.4, whiteGold, 0.75)
			if
				not animate(0.75, function(t)
					root.CFrame = groundFrame:Lerp(airborneFrame, 1 - (1 - t) ^ 3)
					root.AssemblyLinearVelocity = Vector3.zero
					aura.CFrame = root.CFrame
					followPillar(8)
				end)
			then
				return false
			end
			actor:SetAttribute("LastCataclysmHoverHeight", root.Position.Y - groundFrame.Y)
			for index, chunk in ipairs(chunks) do
				char = targetOrNext(char)
				if not valid() or not char then
					return false
				end
				core.Face(char)
				aura.CFrame = root.CFrame
				actor:SetAttribute("AttackState", "Gilded Cataclysm: chain block " .. index)
				Audio.Emit(actor, "ChainRattle", chunk.Part)
				chunk.Phase = "Pulled"
				melee.Pose("Windup", 0.12)
				local from = chunk.Part.CFrame
				local goal = root.CFrame * CFrame.new(22 + chunk.Part.Size.X * 0.5, 8 + chunk.Part.Size.Y * 0.5, -20)
				if
					not animate(0.28, function(t)
						chunk.Part.CFrame = from:Lerp(goal, 1 - (1 - t) ^ 2)
						chain:Connect(root.Position + Vector3.new(0, 1, 0), chunk.Part.Position)
					end)
				then
					return false
				end
				actor:SetAttribute("AttackState", "Gilded Cataclysm: launch block " .. index)
				melee.Pose("Slash1", 0.07)
				launchChunk(chunk, char)
				actor:SetAttribute("CataclysmBlocksLaunched", index)
				while not chunk.Done do
					if not valid() then
						return false
					end
					if not chunk.Cast:Alive() then
						return false
					end
					chain:Connect(root.Position + Vector3.new(0, 1, 0), chunk.Part.Position)
					RunService.Heartbeat:Wait()
				end
				if index < #chunks and not core.WaitFor(Difficulty.Mercy("CataclysmLaunchGap", actor) or 0.16) then
					return false
				end
			end
			actor:SetAttribute("AttackState", "Gilded Cataclysm: descending")
			circle.Close()
			mood.Release()
			local airborneFrom = root.CFrame
			local landing = CFrame.new(root.Position.X, groundFrame.Y, root.Position.Z) * root.CFrame.Rotation
			if
				not animate(0.35, function(t)
					root.CFrame = airborneFrom:Lerp(landing, t * t)
					aura.CFrame = root.CFrame
					followPillar(8 * (1 - t))
				end)
			then
				return false
			end
			restoreBoss()
			auraLight:Destroy()
			auraSparks:Destroy()
			effects.Release(aura)
			effects.Release(pillar)
			impactBurst(root.Position, 30, 14, 10)
			core.ScreenEffect("Shake", { Origin = root.Position, Radius = 450, Duration = 0.6, Intensity = 0.8 })
			char = chainTarget(char)
			if not char then
				return true
			end
			chainedPlayer = Players:GetPlayerFromCharacter(char)
			if not chainedPlayer then
				return true
			end
			chainedChar, chainedRoot = char, char.HumanoidRootPart
			oldAnchored = chainedRoot.Anchored
			lockToken = cast
			status.SetLocked(chainedPlayer, lockToken, true)
			chainedChar:SetAttribute("CataclysmChained", true)
			Time.SetAnchored(chainedRoot, true)
			chainedRoot.AssemblyLinearVelocity = Vector3.zero
			chainedRoot.AssemblyAngularVelocity = Vector3.zero
			actor:SetAttribute("AttackState", "Gilded Cataclysm: break the chains")
			Audio.Emit(actor, "QTEChain", chainedRoot)
			melee.Pose("Windup3", 0.12)
			session = qte.Begin(chainedPlayer, actor, {
				OnResolved = function(outcome)
					if outcome == "Success" then
						Audio.Emit(actor, "CataclysmChainSuccess", chainedRoot)
					end
					if outcome ~= "Failure" then
						releasePlayer()
					end
				end,
			})
			if not session then
				return false
			end
			while not session:IsFinished() do
				if not Time.WaitForActor(actor) or not valid() or not core.Alive(chainedChar) then
					session:Close("attack interrupted")
					return false
				end
				chain:Connect(root.Position + Vector3.new(0, 1, 0), chainedRoot.Position)
				RunService.Heartbeat:Wait()
			end
			if not Time.WaitForActor(actor) or not valid() then
				return false
			end
			actor:SetAttribute("CataclysmQTEOutcome", session:Outcome())
			if session:Outcome() ~= "Failure" then
				return session:Outcome() == "Success"
			end
			if not valid() or not core.Alive(chainedChar) then
				return false
			end

			actor:SetAttribute("AttackState", "Gilded Cataclysm: execution carry")
			Audio.Emit(actor, "CataclysmChainFailure", chainedRoot)
			local carryFrom = chainedRoot.CFrame
			local carryGoal = root.CFrame * CFrame.new(0, 4, -4)
			if
				not animate(0.24, function(t)
					chainedRoot.CFrame = carryFrom:Lerp(carryGoal, 1 - (1 - t) ^ 2)
					chain:Connect(root.Position, chainedRoot.Position)
				end)
			then
				return false
			end
			local bossFrom = root.CFrame
			local bossAbove = bossFrom + Vector3.new(0, 28, 0)
			core.AirborneFloor = bossFrom.Y
			if
				not animate(0.42, function(t)
					root.CFrame = bossFrom:Lerp(bossAbove, math.sin(t * math.pi * 0.5))
					chainedRoot.CFrame = root.CFrame * CFrame.new(0, -1, -4)
					chain:Connect(root.Position, chainedRoot.Position)
				end)
			then
				return false
			end
			actor:SetAttribute("AttackState", "Gilded Cataclysm: execution slam")
			melee.Pose("Slash3", 0.08)
			local impactY = groundAt(bossFrom.Position)
			local playerGoal = CFrame.new(carryGoal.X, impactY + 3, carryGoal.Z) * carryGoal.Rotation
			local heldFrom = chainedRoot.CFrame
			if
				not animate(0.2, function(t)
					local eased = t * t
					root.CFrame = bossAbove:Lerp(bossFrom, eased)
					chainedRoot.CFrame = heldFrom:Lerp(playerGoal, eased)
					chain:Connect(root.Position, chainedRoot.Position)
				end)
			then
				return false
			end
			core.AirborneFloor = nil
			core.Damage(chainedChar, 75)
			releasePlayer()
			local center = Vector3.new(playerGoal.X, impactY + 0.15, playerGoal.Z)
			Audio.Emit(actor, "CataclysmSlam", center)
			local width, depth =
				workspace:GetAttribute("ArenaWidth") or 336, workspace:GetAttribute("ArenaDepth") or 240
			local radius = actor:GetAttribute("CataclysmFinalWaveRadius") or math.sqrt(width * width + depth * depth)
			api.Shockwave(center, radius, actor:GetAttribute("CataclysmFinalWaveDamage") or 15, true, chainedChar)
			impactBurst(center, 55, 36, 22)
			screenGrade(
				{ Brightness = 0.3, Contrast = 0.15, Saturation = 0.1, Tint = whiteGold, Bloom = 1.6 },
				0.04,
				0.08,
				1.1
			)
			core.ScreenEffect("Shake", { Origin = center, Radius = radius + 30, Duration = 1.2, Intensity = 1.2 })
			return true
		end
		local ok, result = xpcall(sequence, debug.traceback)
		if session and not session:IsFinished() then
			session:Close("attack ended")
		end
		releasePlayer()
		restoreBoss()
		if circle then
			circle.Close()
		end
		if mood then
			mood.Release()
		end
		for _, chunk in ipairs(chunks) do
			if not chunk.Launched then
				chunk.Cast:Dispose()
			end
		end
		cast:Dispose()
		if not ok then
			error(result, 0)
		end
		return result
	end

	function api.Combo(char)
		if not api.CanUse(char) then
			return false
		end
		return require(BossSystem.Boss.GoldenGuardService).Run(actor, function()
			return core.Perform(char, "P1GildedCataclysm(Ultimate)", function()
				local count = actor:GetAttribute("CataclysmDialogueCount") or 0
				local line = count == 0 and "Let's see if you can handle this."
					or repeatedLines[random:NextInteger(1, #repeatedLines)]
				actor:SetAttribute("AttackState", "Gilded Cataclysm: declaration")
				actor:SetAttribute("CataclysmLastDialogue", line)
				if not Encounter.SayAndWait(line, actor) or not core.Active() then
					return false
				end
				actor:SetAttribute("CataclysmDialogueCount", count + 1)
				actor:SetAttribute("CataclysmDialogueFinishedAt", workspace:GetServerTimeNow())
				return runAttack(char)
			end)
		end)
	end
	return api
end
