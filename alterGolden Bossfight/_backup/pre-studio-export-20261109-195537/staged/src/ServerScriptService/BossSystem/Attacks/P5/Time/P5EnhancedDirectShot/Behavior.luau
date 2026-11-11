local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Effects = require(BossSystem.Combat.EffectService)
local Audio = require(BossSystem.Presentation.CombatAudio)
local ArenaRange = require(BossSystem.Combat.ArenaAttackRange)
local TweenService = game:GetService("TweenService")

local NAME = "P5EnhancedDirectShot"
local GOLD, WHITE = Style.GOLD, Style.WHITE
local DANGER = Style.DANGER  
local HIT_RADIUS = Config.P5EnhancedDirectShotRadius or 2.4
local KP = NumberSequenceKeypoint.new

local tw = Visuals.tw({
	Effects = Effects,
	TweenService = TweenService,
})

local facing = Visuals.facing({})

local flashLight = Visuals.flashLight({
	tw = tw,
})

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local api = { Cooldown = Config.P5EnhancedDirectShotCooldown or 12 }
	local current

	local vfxPart = Visuals.vfxPart({
		core = core,
	})

	local ringPart = Visuals.ringPart({
		vfxPart = vfxPart,
	})

	local shockwave = Visuals.shockwave({
		ringPart = ringPart,
		tw = tw,
	})

	local sparkBurst = Visuals.sparkBurst({
		vfxPart = vfxPart,
		WHITE = WHITE,
		KP = KP,
	})

	function api.CanUse(target)
		local phase = actor:GetAttribute("Phase")
		return (phase == 2 or phase == 2.5 or phase == 5) and not current
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and core.Active() and core.Alive(target)
	end

	function api.Combo(target)
		if not api.CanUse(target) then return false end
		local owned
		local ok, result = xpcall(function()
			return core.Perform(target, NAME, function()
				local warning = Config.P5EnhancedDirectShotAimDuration or 0.55
				local interval = Config.P5EnhancedDirectShotInterval or 0.5
				local cast = Effects.NewCast(actor, NAME, warning + interval * 2 + 3)
				current, owned = cast, cast
				api.LastShotCount = 0
				local generation = actor:GetAttribute("PhaseGeneration") or 0
				local hand = actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm") or core.Root
				local parts, coils, frame, lockedDirection = {}, {}, core.Root.CFrame, nil

				local aimStart, aimLength = cast:Now(), warning
				local lastClock = cast:Now()
				local recoil, fading = 0, false

				local function valid()
					return cast:Alive() and core.Active() and core.Alive(target)
						and not actor:GetAttribute("PhaseTransitionInProgress")
						and (actor:GetAttribute("PhaseGeneration") or 0) == generation
				end
				cast.OnDispose = function()
					if current == cast then
						current = nil
						actor:SetAttribute("DirectShotGunHeld", false)
					end
				end
				local piece = Visuals.piece({
					cast = cast,
					core = core,
					coils = coils,
					parts = parts,
					get_frame = function() return frame end,
				})
				piece("DirectShotGun", Vector3.new(1.1, 1.2, 3.3), CFrame.identity, GOLD)
				piece("DirectShotBarrel", Vector3.new(0.5, 0.5, 3), CFrame.new(0, 0.2, -2.7), WHITE)
				piece("DirectShotGrip", Vector3.new(0.55, 1.5, 0.7), CFrame.new(0, -0.9, 0.5) * CFrame.Angles(-0.3, 0, 0), Color3.fromRGB(55, 48, 30))
				piece("DirectShotSight", Vector3.new(0.25, 0.35, 0.5), CFrame.new(0, 0.8, -1.2), GOLD)
				for _, z in ipairs({ -1.9, -2.7, -3.5 }) do
					piece("DirectShotCoil", Vector3.new(0.7, 0.7, 0.14), CFrame.new(0, 0.2, z), WHITE, true)
				end

				local aim = cast:Add(core.Part("DirectShotAim", frame, Vector3.new(0.16, 0.16, 1), GOLD, 0.6))
				aim.Material = Enum.Material.Neon

				local orb = vfxPart(cast, "DirectShotCharge", frame, Vector3.one * 0.3, WHITE, 0.1, Enum.PartType.Ball)
				local orbLight = Instance.new("PointLight")
				orbLight.Color = GOLD
				orbLight.Range = 14
				orbLight.Brightness = 0
				orbLight.Shadows = false
				orbLight.Parent = orb

				local field = vfxPart(cast, "DirectShotChargeField", frame, Vector3.one * 5, GOLD, 1, Enum.PartType.Ball)
				local suction = Instance.new("ParticleEmitter")
				suction.Rate = 0
				suction.Color = ColorSequence.new(GOLD, WHITE)
				suction.LightEmission = 1
				suction.LightInfluence = 0
				suction.Size = NumberSequence.new({ KP(0, 0.5), KP(1, 0) })
				suction.Transparency = NumberSequence.new({ KP(0, 0.3), KP(1, 1) })
				suction.Lifetime = NumberRange.new(0.25, 0.4)
				suction.Speed = NumberRange.new(6, 9)
				suction.Shape = Enum.ParticleEmitterShape.Sphere
				suction.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
				suction.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
				suction.LockedToPart = true
				suction.Parent = field

				 
				local reticle, reticleStrokes = ringPart(cast, frame, HIT_RADIUS * 6, GOLD, 10)

				local muzzle
				local function layout()
					local now = cast:Now()
					local dt = math.min(now - lastClock, 0.1)
					lastClock = now
					recoil *= math.exp(-16 * dt)

					local origin = hand.Position - hand.CFrame.UpVector * hand.Size.Y * 0.42 + Vector3.new(0, 0.65, 0)
					local delta = lockedDirection or (target.HumanoidRootPart.Position - origin)
					local direction = delta.Magnitude > 0.01 and delta.Unit or core.Root.CFrame.LookVector
					frame = facing(origin, direction)

					local kick = CFrame.new(0, 0, recoil) * CFrame.Angles(recoil * 0.12, 0, 0)
					for _, record in ipairs(parts) do record.Part.CFrame = frame * kick * record.Offset end
					for _, record in ipairs(coils) do record.Part.CFrame = frame * kick * record.Offset end

					muzzle = frame:PointToWorldSpace(Vector3.new(0, 0.2, -4.2))
					local range = ArenaRange.From(muzzle, 240)
					local obstruction = workspace:Raycast(muzzle, direction * range, core.Params())
					local length = math.max(0.05, obstruction and obstruction.Distance or range)
					local finish = muzzle + direction * length
					local normal = obstruction and obstruction.Normal or -direction

					local locked = lockedDirection ~= nil
					local progress = locked and 1 or math.clamp((now - aimStart) / aimLength, 0, 1)
					local color = locked and WHITE or GOLD:Lerp(DANGER, progress)

					local width = locked and 0.05 or (0.16 - 0.09 * progress)
					aim.Size = Vector3.new(width, width, length)
					aim.CFrame = CFrame.lookAt(muzzle + direction * length * 0.5, finish)
					orb.CFrame = CFrame.new(muzzle)
					field.CFrame = CFrame.new(muzzle)
					local diameter = HIT_RADIUS * 2 * (1 + 1.1 * (1 - progress) ^ 2)
					reticle.Size = Vector3.new(diameter, diameter, 0.05)
					reticle.CFrame = facing(finish + normal * 0.08, normal)

					if fading then return end

					aim.Color = color
					aim.Transparency = locked and 0 or (0.6 - 0.35 * progress)

					local pulse = 1 + 0.12 * math.sin(now * 32)
					local orbSize = (locked and 2.1 or (0.25 + 1.6 * progress ^ 2)) * pulse
					orb.Size = Vector3.one * orbSize
					orb.Color = color
					orbLight.Color = color
					orbLight.Brightness = locked and 5 or (4 * progress)
					suction.Rate = locked and 0 or (60 * progress)

					for _, stroke in ipairs(reticleStrokes) do
						stroke.Color = color
						stroke.Transparency = locked and 0 or (0.55 - 0.4 * progress)
					end

					for i, record in ipairs(coils) do
						local wave = 0.5 + 0.5 * math.sin(now * (8 + 22 * progress) - i * 1.3)
						record.Part.Transparency = 1 - wave * (0.35 + 0.65 * progress)
						record.Part.Color = color
					end
				end

				actor:SetAttribute("DirectShotGunHeld", true)
				core.Face(target)
				core.PoseAngles({ RightShoulder = { 90, 0, 0 }, LeftShoulder = { 35, 0, -10 } }, 0.12)
				layout()

				for _, record in ipairs(parts) do
					record.Part.Transparency = 1
					tw(record.Part, 0.15, { Transparency = 0 })
				end
				shockwave(cast, facing(hand.Position, core.Root.CFrame.LookVector), 1, 5, GOLD, 0.2)
				sparkBurst(cast, CFrame.new(hand.Position), 14, GOLD, 16, 180, 0.4, 0.5)

				local visualElapsed = 0
				cast:Step(function(dt)
					if not valid() then cast:Dispose(); return false end
					visualElapsed += dt
					if visualElapsed < 1 / 30 then return true end
					visualElapsed %= 1 / 30
					layout()
					return true
				end)

				for index = 1, 3 do
					if not valid() then return false end
					lockedDirection = nil
					core.Face(target)
					actor:SetAttribute("AttackState", "Direct Shot: aiming " .. index .. "/3")
					 
					local beat = index == 1 and warning or interval
					aimStart, aimLength = cast:Now(), math.max(0.1, beat - 0.12)
					if not core.WaitForWindup(math.max(0.1, beat - 0.12), { Skill = NAME }) or not valid() then return false end
					layout()
					local aimDelta = target.HumanoidRootPart.Position - muzzle
					lockedDirection = aimDelta.Magnitude > 0.01 and aimDelta.Unit or frame.LookVector
					sparkBurst(cast, facing(muzzle, lockedDirection), 6, WHITE, 18, 25, 0.25, 0.35)
					if not core.WaitFor(0.12) or not valid() then return false end
					layout()
					local direction = lockedDirection
					local range = ArenaRange.From(muzzle, 240)
					local obstruction = workspace:Raycast(muzzle, direction * range, core.Params())
					local length = math.max(0.05, obstruction and obstruction.Distance or range)
					local finish = muzzle + direction * length

					 
					local shot = Effects.NewCast(actor, "P5EnhancedDirectShotBeam" .. index, 1.2)
					local mid = CFrame.lookAt((muzzle + finish) * 0.5, finish)

					local beam = vfxPart(shot, "DirectShotBeam", mid, Vector3.new(0.55, 0.55, length), WHITE, 0.05)
					tw(beam, 0.2, { Transparency = 1, Size = Vector3.new(0.04, 0.04, length) })
					local glow = vfxPart(shot, "DirectShotBeamGlow", mid, Vector3.new(1.8, 1.8, length), GOLD, 0.65)
					tw(glow, 0.3, { Transparency = 1, Size = Vector3.new(0.3, 0.3, length) })
					local afterimage = vfxPart(shot, "DirectShotAfterimage", mid, Vector3.new(0.1, 0.1, length), GOLD, 0.15)
					tw(afterimage, 0.55, { Transparency = 1 })

					local trail = Instance.new("ParticleEmitter")
					trail.Enabled = false
					trail.Color = ColorSequence.new(WHITE, GOLD)
					trail.LightEmission = 1
					trail.LightInfluence = 0
					trail.Size = NumberSequence.new({ KP(0, 0.6), KP(1, 0) })
					trail.Transparency = NumberSequence.new({ KP(0, 0.1), KP(1, 1) })
					trail.Lifetime = NumberRange.new(0.3, 0.55)
					trail.Speed = NumberRange.new(1, 6)
					trail.SpreadAngle = Vector2.new(180, 180)
					trail.Parent = beam
					trail:Emit(math.clamp(math.floor(length / 2.5), 8, 70))

					local muzzleCF = facing(muzzle, direction)
					local flash = vfxPart(shot, "DirectShotMuzzleFlash", CFrame.new(muzzle), Vector3.one * 2, GOLD, 0, Enum.PartType.Ball)
					tw(flash, 0.2, { Transparency = 1, Size = Vector3.one * 5 })
					flashLight(flash, 5, 16, GOLD, 0.25)
					shockwave(shot, muzzleCF, 1.5, 11, WHITE, 0.25)
					sparkBurst(shot, muzzleCF, 16, GOLD, 45, 32, 0.35, 0.5)

					local scale = obstruction and 1 or 0.55
					local normal = obstruction and obstruction.Normal or -direction
					local impactCF = facing(finish + normal * 0.1, normal)
					local impact = vfxPart(shot, "DirectShotImpact", CFrame.new(finish), Vector3.one * 2.5 * scale, WHITE, 0, Enum.PartType.Ball)
					tw(impact, 0.25, { Transparency = 1, Size = Vector3.one * 8 * scale })
					flashLight(impact, 4, 18, GOLD, 0.3)
					shockwave(shot, impactCF, 2, HIT_RADIUS * 3.5 * scale, GOLD, 0.3)
					sparkBurst(shot, impactCF, math.floor(26 * scale), GOLD, 38, 55, 0.55, 0.5)

					recoil = 1.5
					Audio.Emit(actor, "GoldenBulletWave", muzzle)

					for _, character in ipairs(core.Characters()) do
						if core.Alive(character) then
							local offset = character.HumanoidRootPart.Position - muzzle
							local along = offset:Dot(direction)
							if along >= 0 and along <= length and (offset - direction * along).Magnitude <= HIT_RADIUS then
								if core.Damage(character, Config.P5EnhancedDirectShotDamage or 18, NAME)>0 then AttackDebuffs.Apply(actor,character,"CooldownIncrease",4,cast) end
								local position = character.HumanoidRootPart.Position
								sparkBurst(shot, facing(position, -direction), 18, WHITE, 30, 70, 0.4, 0.45)
								shockwave(shot, facing(position, direction), 2, 8, GOLD, 0.25)
							end
						end
					end
					api.LastShotCount += 1
					actor:SetAttribute("DirectShotsReleased", (actor:GetAttribute("DirectShotsReleased") or 0) + 1)
					actor:SetAttribute("AttackState", "Direct Shot: fired " .. index .. "/3")
				end

				fading = true
				suction.Rate = 0
				for _, record in ipairs(parts) do tw(record.Part, 0.18, { Transparency = 1 }) end
				for _, record in ipairs(coils) do tw(record.Part, 0.18, { Transparency = 1 }) end
				tw(aim, 0.18, { Transparency = 1 })
				tw(orb, 0.18, { Transparency = 1, Size = Vector3.one * 0.05 })
				tw(orbLight, 0.18, { Brightness = 0 })
				for _, stroke in ipairs(reticleStrokes) do tw(stroke, 0.18, { Transparency = 1 }) end
				return core.WaitFor(0.1)
			end)
		end, debug.traceback)
		if owned and not owned.closed then owned:Dispose() end
		if not ok then warn(NAME .. ": " .. tostring(result)); return false end
		return result
	end
	function api.Dispose()
		if current then current:Dispose() end
	end
 -- greatly enhanced (Phase 5): every cast fires twice, straight after each other
	local single = api.Combo
	function api.Combo(target)
		local result = single(target)
		if result and target and target.Parent then
			pcall(single, target)
		end
		return result
	end
	return api
end
