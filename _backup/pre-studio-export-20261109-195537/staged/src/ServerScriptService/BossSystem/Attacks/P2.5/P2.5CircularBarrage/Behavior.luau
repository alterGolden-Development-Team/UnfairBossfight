local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local Effects = require(BossSystem.Combat.EffectService)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Debris = game:GetService("Debris")
	local api = { Cooldown = Config.CircularBarrageCooldown or 18 }
	local NAME = "P2.5CircularBarrage"
	local GOLD = Style.GOLD
	local WHITE = Style.WHITE
	local ORANGE = Style.ORANGE
	local TAU = math.pi * 2

	local makeSparks = Visuals.makeSparks({
		WHITE = WHITE,
		GOLD = GOLD,
		ORANGE = ORANGE,
	})
	local sparkTemplate = makeSparks(Vector2.new(180, 180), 8, 22, -14)
	local impactTemplate = makeSparks(Vector2.new(55, 55), 12, 32, -18)

	function api.CanUse(character)
		return actor:GetAttribute("Phase") == 2.5
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and core.Active()
			and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, NAME, function()
			local count = math.clamp(math.floor(Config.CircularBarrageShotCount or 24), 8, 48)
			local interval = math.clamp(Config.CircularBarrageShotInterval or 0.09, 0.065, 0.3)
			local warning = Config.CircularBarrageAimDuration or 0.35
			local range = require(BossSystem.Combat.ArenaAttackRange).From(core.Root.Position, Config.CircularBarrageRange or 170)
			api.LastRange = range
			local cast = Effects.NewCast(actor, NAME, warning + count * interval + 2)
			local hand = actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm") or core.Root
			local position = hand.Position - hand.CFrame.UpVector * hand.Size.Y * 0.42 + Vector3.new(0, 0.65, 0)
			local rotation = core.Root.CFrame.Rotation
			local forward = core.Root.CFrame.LookVector
			local frame = CFrame.lookAt(position, position + forward)
			local parts = {}
			local fxInstances = {}
			cast.OnDispose = function()
				for _, item in ipairs(fxInstances) do
					item:Destroy()
				end
			end

			 
			local solid = Visuals.solid({
				Effects = Effects,
				Runtime = Runtime,
				cast = cast,
				get_position = function() return position end,
			})
			local flashBall = Visuals.flashBall({
				solid = solid,
				Effects = Effects,
			})
			 
			local ring = Visuals.ring({
				solid = solid,
				Effects = Effects,
			})
			local sparks = Visuals.sparks({
				solid = solid,
				GOLD = GOLD,
				Debris = Debris,
				Effects = Effects,
			})

			 
			local piece = Visuals.piece({
				core = core,
				cast = cast,
				Effects = Effects,
				parts = parts,
				get_frame = function() return frame end,
			})
			local accent = Visuals.accent({
				piece = piece,
			})
			local gold = GOLD
			local gunBody = piece("CircularBarrageGun", Vector3.new(1.1, 1.2, 3.3), CFrame.identity, gold)
			piece(
				"CircularBarrageBarrel",
				Vector3.new(0.5, 0.5, 3),
				CFrame.new(0, 0.2, -2.7),
				Color3.fromRGB(235, 225, 163)
			)
			piece(
				"CircularBarrageGrip",
				Vector3.new(0.55, 1.5, 0.7),
				CFrame.new(0, -0.9, 0.5) * CFrame.Angles(-0.3, 0, 0),
				Color3.fromRGB(55, 48, 30)
			)
			piece("CircularBarrageSight", Vector3.new(0.25, 0.35, 0.5), CFrame.new(0, 0.8, -1.2), gold)
			accent("CircularBarrageCoilA", Vector3.new(0.7, 0.7, 0.14), CFrame.new(0, 0.2, -1.9), WHITE)
			accent("CircularBarrageCoilB", Vector3.new(0.7, 0.7, 0.14), CFrame.new(0, 0.2, -2.7), WHITE)
			accent("CircularBarrageCoilC", Vector3.new(0.7, 0.7, 0.14), CFrame.new(0, 0.2, -3.5), WHITE)
			accent("CircularBarrageMuzzleRing", Vector3.new(0.85, 0.85, 0.12), CFrame.new(0, 0.2, -4.15), gold)
			accent("CircularBarrageSpine", Vector3.new(0.25, 0.06, 2.8), CFrame.new(0, 0.62, 0), WHITE)
			local gunLight = Instance.new("PointLight")
			gunLight.Color = GOLD
			gunLight.Range = 12
			gunLight.Brightness = 1.2
			gunLight.Shadows = false
			gunLight.Parent = gunBody
			table.insert(fxInstances, gunLight)

			 
			local orb = solid("CircularBarrageMuzzleOrb", Enum.PartType.Ball, Vector3.one * 0.45, WHITE, 0.05)
			local orbLight = Instance.new("PointLight")
			orbLight.Color = GOLD
			orbLight.Range = 14
			orbLight.Brightness = 1
			orbLight.Shadows = false
			orbLight.Parent = orb
			table.insert(fxInstances, orbLight)
			local ta = Instance.new("Attachment")
			ta.Position = Vector3.new(0, 0.4, 0)
			ta.Parent = orb
			local tb = Instance.new("Attachment")
			tb.Position = Vector3.new(0, -0.4, 0)
			tb.Parent = orb
			local arc = Instance.new("Trail")
			arc.Name = "CircularBarrageArc"
			arc.Attachment0 = ta
			arc.Attachment1 = tb
			arc.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, WHITE),
				ColorSequenceKeypoint.new(0.35, GOLD),
				ColorSequenceKeypoint.new(1, ORANGE),
			})
			arc.LightEmission = 1
			arc.FaceCamera = true
			arc.Lifetime = 0.3
			arc.MinLength = 0.05
			arc.Enabled = false
			arc.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.6, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			arc.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
			arc.Parent = orb
			table.insert(fxInstances, ta)
			table.insert(fxInstances, tb)
			table.insert(fxInstances, arc)
			 
			local motes = solid("CircularBarrageMotes", Enum.PartType.Ball, Vector3.one * 5, GOLD, 1)
			local converge = Instance.new("ParticleEmitter")
			converge.Name = "CircularBarrageConverge"
			converge.Shape = Enum.ParticleEmitterShape.Sphere
			converge.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
			converge.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			converge.Rate = 55
			converge.Lifetime = NumberRange.new(0.25, 0.4)
			converge.Speed = NumberRange.new(6, 9)
			converge.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.08),
				NumberSequenceKeypoint.new(0.3, 0.3),
				NumberSequenceKeypoint.new(1, 0),
			})
			converge.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			converge.Color =
				ColorSequence.new({ ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(1, WHITE) })
			converge.LightEmission = 1
			converge.Rotation = NumberRange.new(0, 360)
			converge.Enabled = false
			converge.Parent = motes
			table.insert(fxInstances, converge)
			 
			local sightOn = Config.CircularBarrageSightLine ~= false
			local sightLength = Config.CircularBarrageSightLength or 70
			local aim = solid("CircularBarrageAimLine", Enum.PartType.Block, Vector3.new(0.07, 0.07, 5), gold, 1)

			 
			local dialRadius = Config.CircularBarrageDialRadius or 9
			local floorHit = workspace:Raycast(core.Root.Position, Vector3.new(0, -60, 0), core.Params())
			local floor = (floorHit and floorHit.Position or core.Root.Position - Vector3.new(0, 3, 0))
				+ Vector3.new(0, 0.14, 0)
			local dialParts, dialTicks = {}, {}
			local buildDial = Visuals.buildDial({
				floor = floor,
				solid = solid,
				gold = gold,
				Effects = Effects,
				dialRadius = dialRadius,
				WHITE = WHITE,
				dialParts = dialParts,
				count = count,
				rotation = rotation,
				TAU = TAU,
				dialTicks = dialTicks,
			})
			local litTick = Visuals.litTick({
				dialTicks = dialTicks,
				WHITE = WHITE,
				Effects = Effects,
				gold = gold,
			})

			 
			local began = cast:Now()
			local rotating = false
			local fired = 0
			local angle = 0
			local shotStarted = began
			local summonedAt = began
			local kick = 0
			local finished = false
			local function applyFrame()
				position = hand.Position - hand.CFrame.UpVector * hand.Size.Y * 0.42 + Vector3.new(0, 0.65, 0)
				frame = CFrame.lookAt(position, position + core.Root.CFrame.LookVector)
				for _, record in ipairs(parts) do
					record.Part.CFrame = frame * record.Offset
				end
			end
			local function updateFx(dt)
				if finished then
					orb.Transparency = 1
					aim.Transparency = 1
					return
				end
				local look = frame.LookVector
				local muzzle = frame:PointToWorldSpace(Vector3.new(0, 0.2, -4.35))
				local charge = rotating and 1 or math.clamp((cast:Now() - summonedAt) / math.max(warning, 0.05), 0, 1)
				kick = math.max(0, kick - dt * 9)
				orb.Size = Vector3.one * (0.45 + 0.85 * charge + kick * 1.3)
				orb.CFrame = CFrame.new(muzzle)
				orbLight.Brightness = 0.8 + charge * 1.4 + kick * 3
				motes.CFrame = CFrame.new(muzzle)
				if sightOn then
					local hit = workspace:Raycast(muzzle, look * sightLength, core.Params())
					local length = math.max(0.1, hit and hit.Distance or sightLength)
					aim.Size = Vector3.new(0.07, 0.07, length)
					aim.CFrame = CFrame.lookAt(muzzle + look * length * 0.5, muzzle + look * length)
					aim.Transparency = math.clamp(0.95 - 0.2 * charge - 0.35 * math.min(kick, 1), 0.35, 1)
				else
					aim.Transparency = 1
				end
			end
			local function finishFx()
				finished = true
				rotating = false
				arc.Enabled = false
				converge.Enabled = false
				orbLight.Enabled = false
				gunLight.Enabled = false
				local fade = TweenInfo.new(0.3)
				for _, record in ipairs(parts) do
					Effects:Create(record.Part, fade, { Transparency = 1 }):Play()
				end
				for _, item in ipairs(dialParts) do
					Effects:Create(item, fade, { Transparency = 1 }):Play()
				end
				ring(floor, Vector3.yAxis, WHITE, dialRadius * 1.5, 0.45)
			end

			applyFrame()
			updateFx(0)
			cast:Step(function(dt)
				if
					not core.Active()
					or actor:GetAttribute("Phase") ~= 2.5
					or actor:GetAttribute("PhaseTransitionInProgress")
				then
					cast:Dispose()
					return false
				end
				if rotating then
					core.Root.CFrame = CFrame.new(core.Root.Position)
						* rotation
						* CFrame.Angles(
							0,
							math.min(
								angle + math.clamp((cast:Now() - shotStarted) / interval, 0, 1) * math.pi * 2 / count,
								math.pi * 2
							),
							0
						)
				end
				applyFrame()
				updateFx(dt)
				return true
			end)

			local function sequence()
				actor:SetAttribute("AttackState", "Circular Barrage: summoning gun")
				core.PoseAngles({ RightShoulder = { 90, 0, 0 }, LeftShoulder = { 35, 0, -10 } }, 0.12)
				actor:SetAttribute("CircularBarrageGunHeld", true)
				 
				flashBall(position, GOLD, 5, 0.25)
				ring(position, forward, WHITE, 3.5, 0.3)
				sparks(position, 24, sparkTemplate)
				buildDial()
				converge.Enabled = true
				if not core.WaitForWindup(warning, { Skill = NAME }) then
					return false
				end
				converge.Enabled = false
				arc.Enabled = true
				do  
					local muzzle = frame:PointToWorldSpace(Vector3.new(0, 0.2, -4.35))
					flashBall(muzzle, WHITE, 4, 0.2)
					ring(muzzle, frame.LookVector, GOLD, 3.4, 0.25)
					kick = 1
				end
				began = cast:Now()
				rotating = true
				for index = 1, count do
					if not cast:Alive() or not core.Active() then
						return false
					end
					if not core.Alive(character) then
						character = core.Melee.GetTarget()
					end
					if not character then
						return false
					end
					angle = (index - 1) * math.pi * 2 / count
					shotStarted = cast:Now()
					core.Root.CFrame = CFrame.new(core.Root.Position) * rotation * CFrame.Angles(0, angle, 0)
					local direction = core.Root.CFrame.LookVector
					applyFrame()
					local muzzle = frame:PointToWorldSpace(Vector3.new(0, 0.2, -4.2))
					Audio.Emit(actor, "CircularBarrageAim", muzzle)
					Audio.Emit(actor, "GoldenBulletWave", muzzle)
					local obstruction = workspace:Raycast(muzzle, direction * range, core.Params())
					local distance = math.max(0.05, obstruction and obstruction.Distance or range)
					local finish = muzzle + direction * distance
					local length = math.max(distance, 0.05)
					local beamFrame = CFrame.lookAt((muzzle + finish) * 0.5, finish)

					 
					local beamCast = Effects.NewCast(actor, "CircularBarrageBeam", 0.16)
					local glow = beamCast:Add(
						core.Part("CircularBarrageBeamGlow", beamFrame, Vector3.new(1.3, 1.3, length), ORANGE, 0.62)
					)
					glow.Material = Enum.Material.Neon
					local beam = beamCast:Add(
						core.Part("CircularBarrageBeam", beamFrame, Vector3.new(0.55, 0.55, length), gold, 0.25)
					)
					beam.Material = Enum.Material.Neon
					local center = beamCast:Add(
						core.Part(
							"CircularBarrageBeamCore",
							beamFrame,
							Vector3.new(0.18, 0.18, length),
							Color3.fromRGB(255, 249, 211),
							0.3
						)
					)
					center.Material = Enum.Material.Neon
					Effects
						:Create(glow, TweenInfo.new(0.15), { Size = Vector3.new(0.15, 0.15, length), Transparency = 1 })
						:Play()
					Effects
						:Create(beam, TweenInfo.new(0.14), { Size = Vector3.new(0.1, 0.1, length), Transparency = 1 })
						:Play()
					Effects
						:Create(
							center,
							TweenInfo.new(0.14),
							{ Size = Vector3.new(0.04, 0.04, length), Transparency = 1 }
						)
						:Play()
					 
					local after =
						solid("CircularBarrageAfterglow", Enum.PartType.Block, Vector3.new(1.8, 1.8, length), gold, 0.8)
					after.CFrame = beamFrame
					Effects:Create(
						after,
						TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Size = Vector3.new(0.3, 0.3, length), Transparency = 1 }
					):Play()
					Effects.ReleaseAfter(after, 0.43)

					 
					kick = 1
					litTick(index)
					flashBall(muzzle, WHITE, 3.4, 0.14)
					ring(muzzle, direction, gold, 2.8, 0.22)
					sparks(muzzle, 8, sparkTemplate)
					if obstruction then
						flashBall(finish, gold, 4.5, 0.22)
						ring(finish, obstruction.Normal, WHITE, 3.2, 0.28)
						sparks(
							finish,
							18,
							impactTemplate,
							CFrame.lookAt(finish, finish + obstruction.Normal) * CFrame.Angles(-math.pi / 2, 0, 0)
						)
					end

					for _, target in ipairs(core.Characters()) do
						if core.Alive(target) then
							local offset = target.HumanoidRootPart.Position - muzzle
							local along = offset:Dot(direction)
							if
								along >= 0
								and along <= distance
								and (offset - direction * along).Magnitude
									<= (Config.CircularBarrageBeamHitRadius or 1.4) + 1.5
							then
								local applied = core.Damage(target, Config.CircularBarrageDamage or 6,"P2.5CircularBarrage")
        if applied and applied>0 then AttackDebuffs.Apply(actor,target,"DeathMark",8,cast) end
								if applied == nil or applied > 0 then
									local at = target.HumanoidRootPart.Position
									sparks(at, 14, sparkTemplate)
									flashBall(at, WHITE, 3, 0.15)
								end
							end
						end
					end
					actor:SetAttribute(
						"CircularBarrageBeamsReleased",
						(actor:GetAttribute("CircularBarrageBeamsReleased") or 0) + 1
					)
					fired += 1
					actor:SetAttribute(
						"CircularBarrageShotsReleased",
						(actor:GetAttribute("CircularBarrageShotsReleased") or 0) + 1
					)
					actor:SetAttribute("CircularBarrageAngle", angle * 180 / math.pi)
					if index < count and not core.WaitFor(interval) then
						return false
					end
				end
				actor:SetAttribute("CircularBarrageSpinDegrees", 360)
				return core.WaitFor(interval)
			end
			local ok, result = xpcall(sequence, debug.traceback)
			actor:SetAttribute("CircularBarrageLastShotCount", fired)
			actor:SetAttribute("CircularBarrageGunHeld", false)
			if ok and result == true and cast:Alive() then
				 
				pcall(finishFx)
				cast:Schedule(0.5, function()
					cast:Dispose()
				end)
			else
				cast:Dispose()
			end
			if not ok then
				error(result, 0)
			end
			return result
		end)
	end
	return api
end
