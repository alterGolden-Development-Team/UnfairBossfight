local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Tween = game:GetService("TweenService")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local active = {}
	local COOLDOWN_SCALE = 0.85
	local WINDUP_SCALE = 0.9
	local RADIUS_SCALE = 1.1
	local WARNING_SCALE = 0.85
	local INTERVAL_SCALE = 0.8
	local ACTIVE_SCALE = 1.15
	local RETURN_DELAY_SCALE = 0.7
	local AIM_LEAD = 0.3
	local REAIM_RETURN = true
	local RETURN_LEAD = 0.4
	local api = { Cooldown = (Config.P4RiftColumnCooldown or Config.RiftColumnsCooldown or 16) * COOLDOWN_SCALE }

	local GOLD = Style.GOLD
	local AMBER = Style.AMBER
	local WHITE = Style.WHITE
	local EMBER = Style.EMBER
	local EMBER_LIGHT = Style.EMBER_LIGHT
	local DUST = Style.DUST
	local SCORCH = Style.SCORCH
	local SPARKLE = Style.SPARKLE
	local SMOKE = Style.SMOKE
	local key = Visuals.key({})

	local shake = Visuals.shake({
		core = core,
	})
	local disc = Visuals.disc({
		core = core,
	})
	local pulse = Visuals.pulse({
		disc = disc,
		Effects = Effects,
	})

	function api.CanUse(target)
		return math.min(4, math.floor(actor:GetAttribute("Phase") or 1)) == 4 and core.Active() and core.Alive(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, "P4RiftColumn", function()
			core.Face(target)
			core.PoseAngles(
				{ RightShoulder = { 145, 0, -20 }, LeftShoulder = { 30, 0, 20 }, Waist = { -12, 0, 0 } },
				0.18
			)
			actor:SetAttribute("AttackState", "Rift Columns: ground slash")
			Audio.Emit(actor, "SplitCharge", core.Root)

			local windup = (Config.RiftColumnsWindup or 0.65) * WINDUP_SCALE
			local charge = Effects.NewCast(actor, "P4RiftColumnCharge", windup + 0.8)
			local feet = Placement.GroundPoint(core.Root.Position, { Margin = 6, Clamp = true })
			if feet then
				local gather = disc(charge, feet + Vector3.new(0, 0.15, 0), 26, AMBER, 0.92)
				Effects:Create(
					gather,
					TweenInfo.new(windup, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Size = Vector3.new(0.1, 5, 5), Transparency = 0.3 }
				):Play()
				local core_ = disc(charge, feet + Vector3.new(0, 0.2, 0), 4, WHITE, 0.85)
				Effects:Create(core_, TweenInfo.new(windup), { Size = Vector3.new(0.1, 7, 7), Transparency = 0.45 })
					:Play()
			end
			local hand = actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm")
			if hand then
				local gatherSparks = Instance.new("ParticleEmitter")
				gatherSparks.Name = "RiftChargeSparks"
				gatherSparks.Texture = SPARKLE
				gatherSparks.Color = ColorSequence.new(WHITE, GOLD)
				gatherSparks.LightEmission = 0.7
				gatherSparks.Rate = 70
				gatherSparks.Lifetime = NumberRange.new(0.3, 0.55)
				gatherSparks.Speed = NumberRange.new(2, 7)
				gatherSparks.SpreadAngle = Vector2.new(180, 180)
				gatherSparks.Size = NumberSequence.new({ key(0, 0.4), key(1, 0) })
				gatherSparks.Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) })
				gatherSparks.Parent = hand
				charge:Add(gatherSparks)
			end
			local waited = core.WaitFor(windup)
			charge:Dispose()
			if not waited then
				return false
			end

			local origin = Placement.GroundPoint(core.Root.Position, { Margin = 6, Clamp = true })
			local targetRoot = target.HumanoidRootPart
			local runVelocity = targetRoot.AssemblyLinearVelocity
			local ahead = Vector3.new(runVelocity.X, 0, runVelocity.Z) * AIM_LEAD
			local targetGround = Placement.GroundPoint(targetRoot.Position + ahead, { Margin = 6, Clamp = true })
			if not origin or not targetGround then
				return false
			end
			local direction = Vector3.new(targetGround.X - origin.X, 0, targetGround.Z - origin.Z)
			if direction.Magnitude < 0.1 then
				direction = core.Root.CFrame.LookVector
			end
			direction = Vector3.new(direction.X, 0, direction.Z).Unit
			local count = math.clamp(math.floor(Config.P4RiftColumnCount or 12), 3, 12)
			local range = math.clamp(Config.P4RiftColumnRange or 145, 60, 180)
			local spacing = (range - 4) / (count - 1)
			local radius = math.clamp((Config.P4RiftColumnRadius or 18) * RADIUS_SCALE, 6, 24)
			local mainRadius = radius
			local warning = math.clamp((Config.P4RiftColumnWarning or 0.5) * WARNING_SCALE, 0.3, 1.5)
			local interval = math.clamp((Config.P4RiftColumnInterval or 0.07) * INTERVAL_SCALE, 0.04, 0.15)
			local activeDuration = math.clamp((Config.RiftColumnsActiveDuration or 0.28) * ACTIVE_SCALE, 0.15, 0.6)
			local height = math.clamp(Config.P4RiftColumnHeight or 48, 12, 64)
			local columns = {}
			local mainPoints = {}
			for index = 1, count do
				local point =
					Placement.GroundPoint(origin + direction * (4 + (index - 1) * spacing), { Margin = mainRadius })
				if point then
					table.insert(mainPoints, point)
					table.insert(columns, {
						Point = point,
						Main = true,
						Outbound = true,
						At = (index - 1) * interval,
						Radius = mainRadius,
						Shake = #mainPoints == 1,
					})
				end
			end
			if #mainPoints == 0 then
				return false
			end
			local returnAt = #mainPoints * interval + math.clamp((Config.P4RiftColumnReturnDelay or 0.35) * RETURN_DELAY_SCALE, 0.15, 0.8)
			for index = #mainPoints, 1, -1 do
				table.insert(columns, {
					Point = mainPoints[index],
					Main = true,
					Outbound = false,
					Radius = mainRadius,
					At = returnAt + (#mainPoints - index) * interval,
					Shake = index == #mainPoints,
				})
			end
			local lastAt = 0
			for _, column in ipairs(columns) do
				lastAt = math.max(lastAt, column.At)
			end
			local cast = Effects.NewCast(actor, "P4RiftColumnOutAndBack", lastAt + warning + activeDuration + 1.2)
			api.LastCast = cast
			api.LastColumns = columns
			active[cast] = true
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			cast.OnDispose = function()
				active[cast] = nil
			end
			cast:Step(function()
				if
					(actor:GetAttribute("PhaseGeneration") or 0) ~= generation
					or math.min(4, math.floor(actor:GetAttribute("Phase") or 1)) ~= 4
				then
					cast:Dispose()
					return false
				end
				return true
			end)
			local part = Visuals.part({
				cast = cast,
				core = core,
			})
			local ring = Visuals.ring({
				AMBER = AMBER,
			})

			local function sendWave(startAt, points, heading, color, glow)
				cast:Schedule(startAt, function()
					if not cast:Alive() or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
						return
					end
					local width = mainRadius * 1.9
					local lift = Vector3.new(0, 2.4, 0)
					local low = Vector3.new(0, 0.3, 0)
					local blade = part(
						"RiftSlashBlade",
						CFrame.lookAt(points[1] + lift, points[1] + lift + heading),
						Vector3.new(width, 4.4, 0.22),
						color,
						0.18
					)
					blade.Material = Enum.Material.Neon
					local edge = part(
						"RiftSlashEdge",
						CFrame.lookAt(points[1] + low, points[1] + low + heading),
						Vector3.new(width, 0.2, 1.4),
						glow,
						0.1
					)
					edge.Material = Enum.Material.Neon
					local a0 = Instance.new("Attachment")
					a0.Position = Vector3.new(-width / 2, -2.1, 0)
					a0.Parent = blade
					local a1 = Instance.new("Attachment")
					a1.Position = Vector3.new(width / 2, -2.1, 0)
					a1.Parent = blade
					local trail = Instance.new("Trail")
					trail.Name = "RiftSlashRibbon"
					trail.Attachment0 = a0
					trail.Attachment1 = a1
					trail.Lifetime = 0.45
					trail.LightEmission = 0.8
					trail.Color = ColorSequence.new(color, glow)
					trail.Transparency = NumberSequence.new(0.35, 1)
					trail.Parent = blade
					local began = cast:Now()
					local total = #points
					cast:Step(function(_, now)
						if (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
							return false
						end
						local f = (now - began) / interval + 1
						local finished = f >= total
						local i = math.clamp(math.floor(f), 1, math.max(1, total - 1))
						local nextPoint = points[math.min(i + 1, total)]
						local position = points[i]:Lerp(nextPoint, math.clamp(f - i, 0, 1))
						local flat = Vector3.new(nextPoint.X - points[i].X, 0, nextPoint.Z - points[i].Z)
						local look = flat.Magnitude > 0.01 and flat.Unit or heading
						blade.CFrame = CFrame.lookAt(position + lift, position + lift + look)
						edge.CFrame = CFrame.lookAt(position + low, position + low + look)
						if finished then
							trail.Enabled = false
							Effects:Create(blade, TweenInfo.new(0.15), { Transparency = 1 }):Play()
							Effects:Create(edge, TweenInfo.new(0.15), { Transparency = 1 }):Play()
							cast:Schedule(0.5, function()
								Effects.Release(blade)
								Effects.Release(edge)
							end)
							return false
						end
						return true
					end)
				end)
			end

			local first = mainPoints[1]
			core.PoseAngles(
				{ RightShoulder = { 10, 0, -35 }, LeftShoulder = { -15, 0, 10 }, Waist = { 24, 0, 0 } },
				0.1
			)
			Audio.Emit(actor, "NormalSwing", core.Root)
			Audio.Emit(actor, "SplitActivate", first, { VolumeScale = 0.6 })
			pulse(cast, origin + Vector3.new(0, 0.25, 0), 4, 28, 0.4, WHITE, 0.2)
			shake(origin, 0.3, 0.9)
			local reversed = {}
			for index = #mainPoints, 1, -1 do
				table.insert(reversed, mainPoints[index])
			end
			sendWave(0, mainPoints, direction, WHITE, AMBER)
			sendWave(returnAt, reversed, -direction, EMBER_LIGHT, EMBER)
			 
			if REAIM_RETURN then
				cast:Schedule(math.max(0, returnAt - 0.1), function()
					if not cast:Alive() or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
						return
					end
					local aimCharacter = core.Alive(target) and target or nil
					if not aimCharacter then
						for _, candidate in ipairs(core.Characters()) do
							if core.Alive(candidate) then
								aimCharacter = candidate
								break
							end
						end
					end
					if not aimCharacter then
						return
					end
					local aimRoot = aimCharacter.HumanoidRootPart
					local aimVelocity = aimRoot.AssemblyLinearVelocity
					local aimAhead = Vector3.new(aimVelocity.X, 0, aimVelocity.Z) * RETURN_LEAD
					local aimPoint = Placement.GroundPoint(aimRoot.Position + aimAhead, { Margin = 6, Clamp = true })
					local far = mainPoints[#mainPoints]
					if not aimPoint then
						return
					end
					local flat = Vector3.new(aimPoint.X - far.X, 0, aimPoint.Z - far.Z)
					if flat.Magnitude < 8 then
						return
					end
					local returnDirection = flat.Unit
					local lastValid = far
					for j = 1, #mainPoints do
						local want = far + returnDirection * ((j - 1) * spacing)
						local p = Placement.GroundPoint(want, { Margin = mainRadius, Clamp = true })
						local column = columns[#mainPoints + j]
						if p and (j == 1 or (p - lastValid).Magnitude > spacing * 0.5) then
							lastValid = p
							column.Point = p
							reversed[j] = p
						else
							 
							column.Skip = true
							reversed[j] = lastValid
						end
					end
				end)
			end
			cast:Schedule(returnAt, function()
				local turn = mainPoints[#mainPoints] + Vector3.new(0, 0.25, 0)
				pulse(cast, turn, 3, mainRadius * 2.4, 0.4, EMBER_LIGHT, 0.25)
			end)
			actor:SetAttribute("LastRiftColumnsRange", range)
			actor:SetAttribute("LastRiftColumnsMainCount", #mainPoints)
			actor:SetAttribute("LastRiftColumnsTotalCount", #columns)
			actor:SetAttribute("RiftColumnReturns", true)
			actor:SetAttribute("RiftColumnsCasts", (actor:GetAttribute("RiftColumnsCasts") or 0) + 1)
			for _, column in ipairs(columns) do
				cast:Schedule(column.At, function()
					if column.Skip then
						return
					end
					local point, r = column.Point, column.Radius
					local color = column.Outbound and GOLD or EMBER
					local accent = column.Outbound and AMBER or EMBER_LIGHT

					local footprint = part(
						column.Main and "RiftMainColumnWarning" or "RiftColumnWarning",
						CFrame.new(point + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
						Vector3.new(0.08, r * 2, r * 2),
						color,
						0.88
					)
					footprint.Shape = Enum.PartType.Cylinder
					local fill = part(
						"RiftColumnWarningFill",
						CFrame.new(point + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
						Vector3.new(0.08, 0.5, 0.5),
						accent,
						0.62
					)
					fill.Shape = Enum.PartType.Cylinder
					fill.Material = Enum.Material.Neon
					Effects:Create(
						fill,
						TweenInfo.new(warning, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Size = Vector3.new(0.08, r * 2, r * 2), Transparency = 0.42 }
					):Play()
					local center = part(
						"RiftColumnWarningCenter",
						CFrame.new(point + Vector3.new(0, 0.2, 0)),
						Vector3.new(0.1, 0.1, 0.1),
						color,
						1
					)
					ring(center, r, 0, 0.15, color, 0.27)

					cast:Schedule(warning, function()
						if not cast:Alive() or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
							return
						end
						Effects.Release(footprint)
						Effects.Release(fill)
						Effects.Release(center)
						if column.Shake then
							shake(point, 0.4, 1.2)
						end

						local plume, beamCore, energy, chunks, rings, streaks, embers = require(script.Column).Create({
							point = point,
							part = part,
							r = r,
							color = color,
							WHITE = WHITE,
							Effects = Effects,
							cast = cast,
							pulse = pulse,
							accent = accent,
							disc = disc,
							SCORCH = SCORCH,
							activeDuration = activeDuration,
							column = column,
							ring = ring,
							height = height,
							SPARKLE = SPARKLE,
							key = key,
							SMOKE = SMOKE,
							DUST = DUST,
							Tween = Tween,
							Audio = Audio,
							actor = actor,
						})
						local started = cast:Now()
						local hits = {}
						local scan, visual = 0, 0
						local embersOff = false
						cast:Step(function(dt, now)
							local elapsed = now - started
							if (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
								cast:Dispose()
								return false
							end
							if elapsed >= activeDuration + 0.3 then
								Effects.Release(plume)
								Effects.Release(beamCore)
								Effects.Release(energy)
								for _, chunk in ipairs(chunks) do
									Effects.Release(chunk.Part)
								end
								return false
							end
							local rise = math.clamp(elapsed / 0.12, 0, 1)
							local h = height * (0.15 + 0.85 * rise)
							plume.Size = Vector3.new(h, r * 2, r * 2)
							plume.CFrame = CFrame.new(point + Vector3.new(0, h * 0.5, 0))
								* CFrame.Angles(0, 0, math.pi * 0.5)
							local fade = math.clamp((elapsed - activeDuration) / 0.3, 0, 1)
							plume.Transparency = 0.8 + 0.2 * fade
							local coreWidth = r * 0.8 * (1 - 0.6 * fade)
							beamCore.Size = Vector3.new(h, coreWidth, coreWidth)
							beamCore.CFrame = plume.CFrame
							beamCore.Transparency = 0.3 + 0.7 * fade
							if elapsed >= activeDuration and not embersOff then
								embersOff = true
								embers.Enabled = false
							end
							for _, chunk in ipairs(chunks) do
								local age = math.min(elapsed, chunk.Life)
								local position = chunk.Origin + chunk.Velocity * age - Vector3.new(0, 35 * age * age, 0)
								chunk.Part.CFrame = CFrame.new(position)
									* CFrame.Angles(age * chunk.Spin, age * chunk.Spin * 0.6, 0)
								chunk.Part.Transparency = 0.05 + 0.95 * fade
							end
							visual += dt
							if visual >= 0.04 then
								visual = 0
								for index, band in ipairs(rings) do
									local spin = elapsed * (4 + index * 0.7) * (index % 2 == 0 and -1 or 1)
									for segment, a in ipairs(band.Points) do
										local angle = (segment - 1) * math.pi * 2 / 8 + spin
										a.Position = Vector3.new(
											math.cos(angle) * band.Radius,
											band.Y * rise + math.sin(angle * 2 + index) * 0.4,
											math.sin(angle) * band.Radius
										)
										band.Beams[segment].Transparency = NumberSequence.new(
											math.clamp(band.Alpha + fade * 0.6 + (segment % 3 == 0 and 0.15 or 0), 0, 1)
										)
									end
								end
								for index, streak in ipairs(streaks) do
									local angle = elapsed * 5 + index * math.pi
									streak.A.Position =
										Vector3.new(math.cos(angle) * r * 0.8, 0.3, math.sin(angle) * r * 0.8)
									streak.B.Position =
										Vector3.new(math.cos(angle + 1) * r * 0.25, h, math.sin(angle + 1) * r * 0.25)
								end
							end
							scan += dt
							if elapsed <= activeDuration and scan >= 0.05 then
								scan = 0
								for _, character in ipairs(core.Characters()) do
									if not hits[character] and core.Alive(character) then
										local delta = character.HumanoidRootPart.Position - point
										if
											delta.Y >= -2
											and delta.Y <= height + 2
											and delta.X * delta.X + delta.Z * delta.Z <= r ^ 2
										then
											local damage = core.Damage(character, Config.P4RiftColumnDamage or 75,"P4RiftColumn")
           if damage and damage>0 then AttackDebuffs.Apply(actor,character,"CooldownFreeze",1,cast) end
											if damage and damage > 0 then
												hits[character] = true
											end
										end
									end
								end
							end
							return true
						end)
					end)
				end)
			end
			actor:SetAttribute("AttackState", "Rift Columns: erupting lines")
			return core.WaitFor(0.2)
		end)
	end
	function api.Dispose()
		local pending = {}
		for cast in pairs(active) do
			table.insert(pending, cast)
		end
		for _, cast in ipairs(pending) do
			cast:Dispose()
		end
	end
	return api
end
