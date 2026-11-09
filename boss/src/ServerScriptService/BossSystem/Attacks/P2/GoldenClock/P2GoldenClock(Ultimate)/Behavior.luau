local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Locomotion = require(BossSystem.Boss.BossLocomotion)
	local VFX = require(BossSystem.Mechanics.Time.GoldenHourVFX)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Run = game:GetService("RunService")
	local core = Registry.For(actor, "P1CombatCore")
	local api = { IsUltimate = true, UltimatePhase = 2, Cooldown = 120, Duration = 10 }

	local GOLD = Style.GOLD
	local BRIGHT = Style.BRIGHT
	local STONE = Style.STONE
	local DIAL = Style.DIAL
	local AMBER = Style.AMBER
	local TAU = math.pi * 2
	local presentation

	local function easeOutCubic(t)
		return 1 - (1 - t) ^ 3
	end

	local function easeOutBack(t)
		local c = t - 1
		return 1 + 2.70158 * c ^ 3 + 1.70158 * c ^ 2
	end

	 
	 
	local groundClock = Visuals.groundClock({
		core = core,
		BRIGHT = BRIGHT,
		VFX = VFX,
		GOLD = GOLD,
		TAU = TAU,
	})

	local function waitReal(seconds, generation, cast)
		local elapsed = 0
		repeat
			elapsed += Run.Heartbeat:Wait()
			if
				cast and cast.closed
				or not core.Active()
				or actor:GetAttribute("EncounterEnded")
				or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
			then
				return false
			end
		until elapsed >= seconds
		return true
	end

	 
	 
	local function construct(cast, frame)
		local rig = {
			pieces = {},
			beams = {},
			angle = { hour = 0, minute = 0, second = 0 },
			spin = { cogA = 0, cogB = 0, orbit = 0, rays = 0, gearL = 0, gearR = 0 },
			swing = 0,
		}

		local part = Visuals.part({
			cast = cast,
			core = core,
			frame = frame,
			rig = rig,
		})

		 
		local FLAT = CFrame.Angles(0, math.pi / 2, 0)
		local disc = Visuals.disc({
			part = part,
			FLAT = FLAT,
		})

		 
		local function anchor(name, offset, dyn)
			return part(name, offset, Vector3.one * 0.1, BRIGHT, 1, nil, dyn)
		end

		 
		local body =
			part("AncientClockStoneBody", CFrame.new(0, 2, 2), Vector3.new(40, 64, 7), STONE, 0.16, Enum.Material.Slate)
		for _, x in ipairs({ -23, 23 }) do
			part("AncientClockPillar", CFrame.new(x, 1, 0), Vector3.new(5, 69, 10), GOLD, 0.05)
			part(
				"AncientClockPillarGroove",
				CFrame.new(x, 1, -5.15),
				Vector3.new(0.35, 61, 0.22),
				BRIGHT,
				0.08,
				Enum.Material.Neon
			)
			part("AncientClockSpire", CFrame.new(x, 41, 0), Vector3.new(2.8, 12, 5), GOLD, 0.1)
			local finial =
				part("AncientClockFinial", CFrame.new(x, 48.5, 0), Vector3.one * 3.4, BRIGHT, 0.05, Enum.Material.Neon)
			finial.Shape = Enum.PartType.Ball
			VFX.Emitter(finial, {
				Name = "FinialSparks",
				Rate = 5,
				Life = NumberRange.new(1, 1.8),
				Speed = NumberRange.new(2, 6),
				Acceleration = Vector3.new(0, -4, 0),
				Size0 = 0.5,
				Exempt = true,
			})
		end
		for _, level in ipairs({ { -36, 51, 7 }, { 35, 51, 7 }, { 41, 43, 5 }, { 46, 31, 5 } }) do
			part("AncientClockPediment", CFrame.new(0, level[1], 0), Vector3.new(level[2], level[3], 11), GOLD, 0.03)
		end

		 
		local sun = disc("AncientClockSunDisc", CFrame.new(0, 15, 9), 78, 0.4, GOLD, 0.64, Enum.Material.Neon)
		rig.dust = VFX.Emitter(sun, {
			Name = "ClockGoldDust",
			Rate = 0,
			Life = NumberRange.new(2.6, 4),
			Speed = NumberRange.new(0.5, 2),
			Acceleration = Vector3.new(0, -3, 0),
			Size0 = 0.7,
			Exempt = true,
		})
		local raysOffset = CFrame.new(0, 15, 8.4)
		local rays = anchor("AncientClockSunRays", raysOffset, function()
			return raysOffset * CFrame.Angles(0, 0, rig.spin.rays)
		end)
		for index = 1, 24 do
			local angle = (index - 1) * TAU / 24
			local long = index % 2 == 1
			local c, s = math.cos(angle), math.sin(angle)
			local tip = long and 78 or 60
			VFX.Ribbon(rays, { Vector3.new(c * 38, s * 38, 0), Vector3.new(c * tip, s * tip, 0) }, false, {
				Label = "SunRay",
				Width0 = long and 2.4 or 1.6,
				Width1 = 0,
				Color = BRIGHT,
				Alpha = 0.35,
				Alpha1 = 1,
				Collect = rig.beams,
			})
		end

		 
		disc("AncientClockBezel", CFrame.new(0, 15, -3), 37.6, 1.6, GOLD, 0.03)
		disc("AncientClockDial", CFrame.new(0, 15, -3.7), 32.4, 0.8, DIAL, 0.08, Enum.Material.Slate)
		local plate = part("AncientClockNumeralPlate", CFrame.new(0, 15, -4.2), Vector3.new(30, 30, 0.1), STONE, 1)
		VFX.Circle(plate, 16.3, 32, {
			Plane = "XY",
			Height = -0.1,
			Label = "DialRim",
			Width = 0.3,
			Color = BRIGHT,
			Alpha = 0.15,
			Collect = rig.beams,
		})
		VFX.Circle(plate, 15.3, 32, {
			Plane = "XY",
			Height = -0.1,
			Label = "DialRimInner",
			Width = 0.14,
			Color = GOLD,
			Alpha = 0.4,
			Collect = rig.beams,
		})

		 
		local numerals = Instance.new("SurfaceGui")
		numerals.Name = "AncientClockRomanNumerals"
		numerals.Face = Enum.NormalId.Front
		numerals.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		numerals.PixelsPerStud = 22
		numerals.LightInfluence = 0
		numerals.Parent = plate
		rig.numerals = numerals
		local ROMAN = { "XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI" }
		for index, text in ipairs(ROMAN) do
			local angle = (index - 1) * TAU / 12
			local glyph = Instance.new("TextLabel")
			glyph.AnchorPoint = Vector2.new(0.5, 0.5)
			glyph.Position = UDim2.fromScale(0.5 + math.sin(angle) * 0.3, 0.5 - math.cos(angle) * 0.3)
			glyph.Size = UDim2.fromScale(0.15, 0.1)
			glyph.BackgroundTransparency = 1
			glyph.Font = Enum.Font.Garamond
			glyph.TextScaled = true
			glyph.Text = text
			glyph.TextColor3 = BRIGHT
			glyph.TextStrokeTransparency = 0.45
			glyph.Parent = numerals
		end
		for index = 1, 12 do
			local angle = index * TAU / 12
			local major = index % 3 == 0
			part(
				"AncientClockHourGlyph",
				CFrame.new(-math.sin(angle) * 13.2, 15 + math.cos(angle) * 13.2, -4.35) * CFrame.Angles(0, 0, angle),
				Vector3.new(0.7, major and 3.8 or 2.2, 0.45),
				BRIGHT,
				0.04,
				Enum.Material.Neon
			)
		end

		 
		local function hand(name, z, length, width, color, material, key)
			local base = CFrame.new(0, 15, z)
			local function pivot()
				return base * CFrame.Angles(0, 0, rig.angle[key])
			end
			part(name .. "Shaft", base, Vector3.new(width, length, 0.55), color, 0.02, material, function()
				return pivot() * CFrame.new(0, length / 2, 0)
			end)
			part(name .. "Tip", base, Vector3.new(width * 2.4, width * 2.4, 0.5), color, 0.02, material, function()
				return pivot() * CFrame.new(0, length, 0) * CFrame.Angles(0, 0, math.pi / 4)
			end)
			part(name .. "Tail", base, Vector3.new(width * 1.6, length * 0.24, 0.5), color, 0.02, material, function()
				return pivot() * CFrame.new(0, -length * 0.12, 0)
			end)
		end
		hand("AncientClockHour", -4.9, 7.5, 1.1, GOLD, nil, "hour")
		hand("AncientClockMinute", -5.2, 11.5, 0.6, BRIGHT, Enum.Material.Neon, "minute")
		hand("AncientClockSecond", -5.5, 13.2, 0.22, AMBER, Enum.Material.Neon, "second")
		local cap = part("AncientClockCenter", CFrame.new(0, 15, -5.9), Vector3.one * 2.6, GOLD, 0.02)
		cap.Shape = Enum.PartType.Ball
		rig.burst = VFX.Emitter(cap, {
			Name = "ClockTickSparks",
			Rate = 0,
			Life = NumberRange.new(0.5, 1),
			Speed = NumberRange.new(12, 30),
			Acceleration = Vector3.new(0, -12, 0),
			Size0 = 0.7,
			Exempt = true,
		})
		rig.dissolve = VFX.Emitter(body, {
			Name = "ClockDissolve",
			Rate = 0,
			Life = NumberRange.new(0.9, 1.6),
			Speed = NumberRange.new(3, 10),
			Acceleration = Vector3.new(0, -8, 0),
			Size0 = 1.4,
			Exempt = true,
		})

		 
		local function spinner(name, z, key)
			local offset = CFrame.new(0, 15, z)
			return anchor(name, offset, function()
				return offset * CFrame.Angles(0, 0, rig.spin[key])
			end)
		end
		VFX.Cog(
			spinner("AncientClockCogA", -7, "cogA"),
			18.9,
			21.1,
			12,
			{ Plane = "XY", Label = "ClockCogA", Width = 0.28, Color = BRIGHT, Alpha = 0.15, Collect = rig.beams }
		)
		VFX.Cog(spinner("AncientClockCogB", -8.2, "cogB"), 23.6, 25.6, 12, {
			Plane = "XY",
			Label = "ClockCogB",
			Width = 0.26,
			Color = GOLD,
			Alpha = 0.2,
			Offset = 0.2,
			Collect = rig.beams,
		})
		local orbit = spinner("AncientClockOrbit", -9.5, "orbit")
		VFX.Circle(
			orbit,
			30.5,
			32,
			{ Plane = "XY", Label = "ClockOrbit", Width = 0.22, Color = GOLD, Alpha = 0.25, Collect = rig.beams }
		)
		VFX.Spokes(
			orbit,
			12,
			28.6,
			32.4,
			{ Plane = "XY", Label = "ClockOrbitTick", Width = 0.45, Color = BRIGHT, Alpha = 0.2, Collect = rig.beams }
		)

		 
		for side, x in ipairs({ -11, 11 }) do
			local key = side == 1 and "gearL" or "gearR"
			disc("AncientClockGear", CFrame.new(x, -12, -4.5), 10.8, 0.8, GOLD, 0.08)
			local offset = CFrame.new(x, -12, -5.1)
			local teeth = anchor("AncientClockGearTeeth", offset, function()
				return offset * CFrame.Angles(0, 0, rig.spin[key])
			end)
			VFX.Cog(
				teeth,
				5.4,
				7,
				9,
				{
					Plane = "XY",
					Label = "ClockGearTeeth",
					Width = 0.3,
					Color = BRIGHT,
					Alpha = 0.12,
					Collect = rig.beams,
				}
			)
		end

		 
		local function pivot()
			return CFrame.new(0, -6, -6) * CFrame.Angles(0, 0, rig.swing)
		end
		part("AncientClockPendulumRod", CFrame.new(0, -17, -6), Vector3.new(0.8, 22, 0.8), GOLD, 0.05, nil, function()
			return pivot() * CFrame.new(0, -11, 0)
		end)
		disc("AncientClockPendulumWeight", CFrame.new(0, -29, -6), 8, 2.4, GOLD, 0.06, nil, function()
			return pivot() * CFrame.new(0, -23, 0)
		end)
		local bob = part(
			"AncientClockPendulumCore",
			CFrame.new(0, -29, -7.4),
			Vector3.one * 3.2,
			BRIGHT,
			0.04,
			Enum.Material.Neon,
			function()
				return pivot() * CFrame.new(0, -23, -1.4)
			end
		)
		bob.Shape = Enum.PartType.Ball
		VFX.Emitter(bob, {
			Name = "PendulumEmbers",
			Rate = 14,
			Life = NumberRange.new(0.6, 1.1),
			Speed = NumberRange.new(1, 4),
			Acceleration = Vector3.new(0, -6, 0),
			Size0 = 0.45,
			Exempt = true,
		})
		for index = 1, 5 do
			part(
				"AncientClockEnergyRune",
				CFrame.new((index - 3) * 5, -7, -6) * CFrame.Angles(0, 0, math.rad(45)),
				Vector3.new(0.35, 3, 0.3),
				BRIGHT,
				0.15,
				Enum.Material.Neon
			)
		end

		return rig
	end

	function api.CanUse(character)
		local phase = tonumber(actor:GetAttribute("Phase")) or 1
		return phase >= 2
			and phase <= 2.5
			and actor:GetAttribute("IsGoldenClone") ~= true
			and not actor:GetAttribute("LastMinutePreparing")
			and not actor:GetAttribute("LastMinuteActive")
			and core.Active()
			and core.Alive(character)
			and not Time.IsStopped(actor)
			and actor:GetAttribute("GoldenClockIntroActive") ~= true
	end

	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P2GoldenClock(Ultimate)", function()
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local token = (actor:GetAttribute("GoldenClockPresentationSequence") or 0) + 1
			actor:SetAttribute("GoldenClockPresentationSequence", token)
			actor:SetAttribute("GoldenClockIntroActive", true)
			actor:SetAttribute("AttackState", "Golden Clock: ancient construct descending")
			core.Melee.Pose("Windup3", 0.25)
			local cast = Effects.NewCast(actor, "AncientGoldenClockConstruct", api.Duration + 8)
			cast.TimeStopExempt = true
			presentation = cast
			local ground = Placement.GroundPoint(core.Root.Position, { Clamp = true })
				or core.Root.Position - Vector3.new(0, 3, 0)
			local facing = character.HumanoidRootPart.Position - ground
			facing = Vector3.new(facing.X, 0, facing.Z)
			if facing.Magnitude < 0.01 then
				facing = core.Root.CFrame.LookVector
			end
			local endPosition = ground + Vector3.new(0, 85, 0)
			local finalFrame = CFrame.lookAt(endPosition, endPosition + facing.Unit)
			local rig = construct(cast, finalFrame + Vector3.new(0, 62, 0))

			 
			local dialFrame = finalFrame * CFrame.new(0, 15, -4) * CFrame.Angles(math.pi / 2, 0, 0)
			local sigilCenter = ground

			 
			 
			local pulses = {}
			local ringPulse = Visuals.ringPulse({
				cast = cast,
				core = core,
				BRIGHT = BRIGHT,
				VFX = VFX,
				pulses = pulses,
			})
			local function updatePulses(clock)
				for index = #pulses, 1, -1 do
					local pulse = pulses[index]
					local t = math.clamp((clock - pulse.Start) / pulse.Duration, 0, 1)
					local radius = pulse.Radius * easeOutCubic(t)
					for point, attachment in ipairs(pulse.Attachments) do
						attachment.Position = pulse.Directions[point] * radius
					end
					local transparency = NumberSequence.new(pulse.Alpha + (1 - pulse.Alpha) * t * t)
					local width = pulse.Width * (1 - 0.7 * t)
					for _, beam in ipairs(pulse.Strands) do
						beam.Transparency = transparency
						beam.Width0 = width
						beam.Width1 = width
					end
					if t >= 1 then
						for _, beam in ipairs(pulse.Strands) do
							beam:Destroy()
						end
						for _, attachment in ipairs(pulse.Attachments) do
							attachment:Destroy()
						end
						Effects.Release(pulse.Carrier)
						table.remove(pulses, index)
					end
				end
			end

			local began = os.clock()
			local fadeAt, stop, stopAt
			local ended = false
			local targetPosition = character.HumanoidRootPart.Position
			local orbitFrame, nextOrbitAt, orbitIndex, orbitRunning = nil, 0, 0, false
			local sigil, sigilOpacity
			local lastTick, lastOpacity, lastFrame = 0, nil, nil
			local spinMinute, spinHour, spinSecond, gearSpin = 0, 0, 0, 0
			local settle, settleAt
			local arrived = false

			local function endPresentation(reason)
				if ended then
					return
				end
				ended = true
				actor:SetAttribute("GoldenClockIntroActive", false)
				actor:SetAttribute("GoldenClockRepositioning", false)
				if orbitRunning then
					Locomotion.Idle(actor, 0.18)
					orbitRunning = false
				end
				core.ScreenEffect(
					"GoldenClockIntroEnd",
					{ Token = token, Reason = reason, Duration = 0.65, Radius = math.huge }
				)
			end

			cast.OnDispose = function()
				if stop and not stop.closed then
					stop:Dispose("presentation interrupted")
				end
				endPresentation("cleanup")
				if presentation == cast then
					presentation = nil
				end
			end
			core.ScreenEffect(
				"GoldenClockIntro",
				{ Token = token, Origin = ground, Duration = api.Duration + 5, Radius = math.huge }
			)

			cast:Step(function(dt)
				if
					(actor:GetAttribute("PhaseGeneration") or 0) ~= generation
					or actor:GetAttribute("AIEnabled") == false
					or actor:GetAttribute("EncounterEnded")
					or not core.Alive(character)
				then
					cast:Dispose()
					return false
				end
				local clock = os.clock()
				local age = clock - began
				local progress = math.clamp(age / 1.8, 0, 1)
				progress = progress * progress * (3 - 2 * progress)
				local frame = finalFrame + Vector3.new(0, 62 * (1 - progress), 0)
				local opacity = math.clamp(age / 1.1, 0, 1)
				if fadeAt then
					opacity *= 1 - math.clamp((clock - fadeAt) / 0.7, 0, 1)
				end
				rig.numerals.Enabled = opacity > 0.25
				local stopAge = (stop and stopAt) and clock - stopAt or 0
				local sweep = 0

				 
				if not arrived and age >= 1.8 then
					arrived = true
					ringPulse(dialFrame, 55, 0.9, 1.4, 0.25, BRIGHT)
					core.ScreenEffect("Shake", { Origin = ground, Radius = 500, Duration = 0.5, Intensity = 0.6 })
				end

				 
				 
				if not (stop and stopAt) then
					local wind = math.clamp(age / 3.4, 0, 1)
					wind *= wind
					spinMinute += dt * (1.2 + 16 * wind)
					spinHour += dt * (0.36 + 1.4 * wind)
					spinSecond += dt * (4 + 26 * wind)
					gearSpin += dt * (0.3 + 2.4 * wind)
					rig.angle.minute, rig.angle.hour, rig.angle.second = spinMinute, spinHour, spinSecond
				else
					if not settle then
						settleAt = clock
						settle = {
							hour = { spinHour, math.ceil(spinHour / TAU) * TAU },
							minute = { spinMinute, math.ceil(spinMinute / TAU) * TAU },
							second = { spinSecond, math.ceil(spinSecond / TAU) * TAU },
						}
					end
					local blend = easeOutCubic(math.clamp((clock - settleAt) / 0.35, 0, 1))
					local whole = math.min(math.floor(stopAge), api.Duration)
					local frac = stopAge - math.floor(stopAge)
					local kick = stopAge >= api.Duration and 0 or easeOutBack(math.clamp(frac / 0.22, 0, 1))
					sweep = (whole + kick) * (TAU / api.Duration)
					rig.angle.hour = settle.hour[1] + (settle.hour[2] - settle.hour[1]) * blend
					rig.angle.minute = settle.minute[1] + (settle.minute[2] - settle.minute[1]) * blend
					rig.angle.second = settle.second[1] + (settle.second[2] - settle.second[1]) * blend + sweep
					gearSpin += dt * 0.3
				end
				rig.swing = math.cos(age * math.pi) * 0.36
				local spin = rig.spin
				spin.cogA = gearSpin * 0.6
				spin.cogB = -gearSpin * 0.45
				spin.orbit = gearSpin * 0.25
				spin.rays = gearSpin * 0.1
				spin.gearL = gearSpin * 2.2
				spin.gearR = -gearSpin * 2.2

				 
				local frameChanged = frame ~= lastFrame
				local opacityChanged = lastOpacity == nil
					or math.abs(opacity - lastOpacity) > 0.02
					or (opacity ~= lastOpacity and (opacity == 0 or opacity == 1))
				lastFrame = frame
				if opacityChanged then
					lastOpacity = opacity
					VFX.ApplyOpacity(rig.beams, opacity)
					rig.dust.Rate = (opacity > 0.6 and not fadeAt) and 26 or 0
				end
				for _, entry in ipairs(rig.pieces) do
					if entry.dyn then
						entry.part.CFrame = frame * entry.dyn()
					elseif frameChanged then
						entry.part.CFrame = frame * entry.offset
					end
					if opacityChanged then
						entry.part.Transparency = 1 - opacity * (1 - entry.alpha)
					end
				end

				 
				if sigil then
					local fade = fadeAt and 1 - math.clamp((clock - fadeAt) / 0.7, 0, 1) or 1
					local value = math.clamp(stopAge / 0.6, 0, 1) * fade * (0.9 + 0.1 * math.sin(age * 3))
					if not sigilOpacity or math.abs(value - sigilOpacity) > 0.025 then
						sigilOpacity = value
						VFX.ApplyOpacity(sigil.Records, value)
					end
					sigil.Update(sweep, gearSpin)
				end
				if stop and not stop.closed and stopAt then
					local whole = math.floor(stopAge)
					if whole > lastTick and whole < api.Duration then
						lastTick = whole
						ringPulse(CFrame.new(sigilCenter + Vector3.new(0, 0.3, 0)), 48, 0.75, 0.9, 0.55, BRIGHT)
						rig.burst:Emit(16)
					end
				end

				updatePulses(clock)
				if fadeAt and clock - fadeAt >= 0.7 and #pulses == 0 then
					cast:Dispose()
					return false
				end

				 
				 
				if stop and not stop.closed then
					orbitRunning = true
					if os.clock() >= nextOrbitAt then
						nextOrbitAt = os.clock() + 1.65
						orbitIndex += 1
						for attempt = 0, 7 do
							local phase = orbitIndex * 2.399963 + attempt * math.pi / 4
							local position = character.HumanoidRootPart.Position
								+ Vector3.new(math.cos(phase) * 43, 0, math.sin(phase) * 43)
							local point = Placement.GroundPoint(position, { Margin = 8, Clamp = true })
							if point then
								local desired =
									CFrame.lookAt(point, Vector3.new(targetPosition.X, point.Y, targetPosition.Z))
								local valid = Placement.Validate(actor, desired, { Margin = 8 })
								if valid and (valid.Position - core.Root.Position).Magnitude > 8 then
									orbitFrame = valid
									actor:SetAttribute(
										"GoldenClockRepositions",
										(actor:GetAttribute("GoldenClockRepositions") or 0) + 1
									)
									break
								end
							end
						end
					end
					if orbitFrame then
						local delta = orbitFrame.Position - core.Root.Position
						local step = math.min(delta.Magnitude, 40 * math.min(dt, 0.1))
						if step > 0.001 then
							 
							 
							if actor:GetAttribute("BossAnimationPriority") ~= "Run" then
								Locomotion.Run(actor, 40)
							end
							local destination = core.Root.Position + delta.Unit * step
							if
								workspace:Blockcast(
									core.Root.CFrame,
									Vector3.new(3.1, 3.1, 3.1),
									destination - core.Root.Position,
									core.Params()
								)
							then
								orbitFrame = nil
								nextOrbitAt = 0
								return true
							end
							local lookAt = Vector3.new(targetPosition.X, destination.Y, targetPosition.Z)
							local desired = (lookAt - destination).Magnitude > 0.01
									and CFrame.lookAt(destination, lookAt)
								or CFrame.new(destination) * core.Root.CFrame.Rotation
							local rotation = core.Root.CFrame.Rotation:Lerp(desired.Rotation, 1 - math.exp(-12 * dt))
							core.Root.CFrame = CFrame.new(destination) * rotation
							core.Root.AssemblyLinearVelocity = Vector3.zero
							actor:SetAttribute(
								"GoldenClockTravelDistance",
								(actor:GetAttribute("GoldenClockTravelDistance") or 0) + step
							)
						elseif actor:GetAttribute("BossAnimationPriority") ~= "Idle" then
							Locomotion.Idle(actor, 0.12)
						end
					end
				end
				return true
			end)

			if not waitReal(1.85, generation, cast) then
				cast:Dispose()
				return false
			end
			actor:SetAttribute("AttackState", "Golden Clock: GOLDEN HOUR!")
			actor:SetAttribute("GoldenClockCueStartedAt", workspace:GetServerTimeNow())
			Encounter.Say("GOLDEN HOUR!")
			local graphemes = 0
			for _ in utf8.graphemes("GOLDEN HOUR!") do
				graphemes += 1
			end
			if not waitReal(graphemes * Config.DialogueCharacterInterval + 0.45, generation, cast) then
				cast:Dispose()
				return false
			end
			actor:SetAttribute("GoldenClockCueCompletedAt", workspace:GetServerTimeNow())
			actor:SetAttribute("GoldenClockIntroActive", false)
			stop = Time.StopTime(actor, api.Duration)
			if not stop then
				cast:Dispose()
				return false
			end
			stopAt = os.clock()
			stop:OnFinished(function(reason)
				fadeAt = os.clock()
				endPresentation(reason)
				if reason == "completed" then
					actor:SetAttribute("GoldenClockResumedAt", workspace:GetServerTimeNow())
					core.ScreenEffect("GoldenClockRelease", {
						Origin = ground,
						Radius = math.huge,
						Duration = 0.7,
						Intensity = 1.15,
						Sequence = stop.sequence,
					})
					core.ScreenEffect("Shake", { Origin = ground, Radius = 500, Duration = 0.85, Intensity = 1.25 })
					 
					local floorFrame = CFrame.new(sigilCenter + Vector3.new(0, 0.3, 0))
					ringPulse(floorFrame, 70, 0.9, 2.2, 0.15, BRIGHT, 48)
					ringPulse(floorFrame, 105, 1.2, 1.6, 0.3, GOLD, 48)
					ringPulse(dialFrame, 80, 1, 2, 0.2, BRIGHT, 48)
					if not cast.closed then
						rig.dissolve:Emit(160)
						rig.burst:Emit(60)
					end
				end
			end)
			targetPosition = character.HumanoidRootPart.Position
			sigilCenter = Placement.GroundPoint(targetPosition, { Clamp = true }) or ground
			sigil = groundClock(cast, sigilCenter)
			actor:SetAttribute("GoldenHourSetupCount", 0)
			actor:SetAttribute("GoldenClockRepositions", 0)
			actor:SetAttribute("GoldenClockTravelDistance", 0)
			actor:SetAttribute("GoldenClockRepositioning", true)
			actor:SetAttribute(
				"GoldenClockUltimatesActivated",
				(actor:GetAttribute("GoldenClockUltimatesActivated") or 0) + 1
			)
			actor:SetAttribute("GoldenClockStoppedAt", workspace:GetServerTimeNow())
			core.ScreenEffect("Shake", { Origin = ground, Radius = 500, Duration = 0.65, Intensity = 0.9 })
			 
			ringPulse(dialFrame, 70, 0.8, 2.2, 0.1, BRIGHT, 48)
			ringPulse(CFrame.new(sigilCenter + Vector3.new(0, 0.3, 0)), 60, 0.8, 1.6, 0.2, GOLD, 48)
			rig.burst:Emit(60)
			return true
		end)
	end

	function api.Dispose()
		if presentation then
			presentation:Dispose()
		end
	end

	return api
end
