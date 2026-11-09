local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Dash = require(BossSystem.Players.R6DashService)
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local api = {
		Radius = math.clamp(Config.GoldenChainRange or 64, 16, 120),
		Damage = 12,
		WarningTime = 0.65,
		SweepDuration = Config.GoldenChainSpinDuration,
	}
	local GOLD, BRIGHT = Style.GOLD, Style.BRIGHT
	local TAU = math.pi * 2
	local SPARK_TEXTURE = Style.SPARK_TEXTURE
	local FADE_TIME = 0.25
	local GROUND_DROP = 2.7  

	 

	 
	local style = Visuals.style({})

	 
	 
	local makeRing = Visuals.makeRing({})

	local sparks = Visuals.sparks({
		SPARK_TEXTURE = SPARK_TEXTURE,
		BRIGHT = BRIGHT,
		GOLD = GOLD,
	})

	 
	 
	local function segmentContact(first, last, frame, size, padding)
		local start = frame:PointToObjectSpace(first)
		local delta = frame:VectorToObjectSpace(last - first)
		local half = size * 0.5 + Vector3.one * padding
		local enter, leave = 0, 1
		for axis = 1, 3 do
			local origin = axis == 1 and start.X or axis == 2 and start.Y or start.Z
			local direction = axis == 1 and delta.X or axis == 2 and delta.Y or delta.Z
			local bound = axis == 1 and half.X or axis == 2 and half.Y or half.Z
			if math.abs(direction) < 0.00001 then
				if math.abs(origin) > bound then
					return nil
				end
			else
				local near, far = (-bound - origin) / direction, (bound - origin) / direction
				if near > far then
					near, far = far, near
				end
				enter, leave = math.max(enter, near), math.min(leave, far)
				if enter > leave then
					return nil
				end
			end
		end
		return enter
	end
	local function headContact(point, frame, size, radius)
		local localPoint = frame:PointToObjectSpace(point)
		local half = size * 0.5
		local nearest = Vector3.new(
			math.clamp(localPoint.X, -half.X, half.X),
			math.clamp(localPoint.Y, -half.Y, half.Y),
			math.clamp(localPoint.Z, -half.Z, half.Z)
		)
		return (localPoint - nearest).Magnitude <= radius
	end

	 
	function api.Sweep(center, startAngle, direction)
		direction = direction == -1 and -1 or 1
		local count = math.clamp(Config.GoldenChainSegmentCount or 12, 6, 16)
		local lag = math.clamp(Config.GoldenChainLag or 0.18, 0, 0.35)
		local sag = Config.GoldenChainSag or 2.8
		 
		local cast = Effects.NewCast(actor, "GoldenChainSweep", api.SweepDuration + lag + FADE_TIME + 0.5)
		local anchor = cast:Add(core.Part("GoldenChainAnchor", CFrame.new(center), Vector3.one * 0.1, GOLD, 1))
		local attachments, positions = {}, {}
		local bodyCache = {}
		local contactPadding = math.clamp(Config.GoldenChainContactPadding or 0.25, 0, 0.75)
		local collisionStep = math.clamp(Config.GoldenChainMaxCollisionStep or 1 / 240, 1 / 360, 1 / 60)
		local groundCenter = center - Vector3.new(0, GROUND_DROP, 0)

		 
		local shock = Visuals.shock({
			cast = cast,
			core = core,
			GOLD = GOLD,
			style = style,
			makeRing = makeRing,
			BRIGHT = BRIGHT,
			TweenService = TweenService,
		})

		for index = 0, count do
			local point = Instance.new("Attachment")
			point.Parent = anchor
			attachments[index + 1] = point
		end

		 
		 
		local beams, links, emitters = {}, {}, {}
		local segmentLength = api.Radius / count
		for index = 1, count do
			local glow = Instance.new("Beam")
			glow.Name = "GoldenChainGlow"
			glow.Attachment0 = attachments[index]
			glow.Attachment1 = attachments[index + 1]
			glow.Width0, glow.Width1 = 2.4, 2.4
			glow.Color = ColorSequence.new(GOLD)
			glow.Transparency = NumberSequence.new(0.86)
			glow.FaceCamera = true
			glow.LightEmission = 1
			glow.Segments = 1
			glow.Parent = anchor
			beams[#beams + 1] = { Beam = glow, Base = 0.86 }

			local chain = Instance.new("Beam")
			chain.Name = "GoldenChainFollowingSegment"
			chain.Attachment0 = attachments[index]
			chain.Attachment1 = attachments[index + 1]
			chain.Width0, chain.Width1 = index % 2 == 0 and 0.5 or 0.38, index % 2 == 0 and 0.38 or 0.5
			chain.Color = ColorSequence.new(BRIGHT, GOLD)
			chain.Transparency = NumberSequence.new(0.2)
			chain.FaceCamera = true
			chain.LightEmission = 1
			chain.Segments = 2
			chain.Parent = anchor
			beams[#beams + 1] = { Beam = chain, Base = 0.2 }

			local link = style(
				cast:Add(
					core.Part(
						"GoldenChainLink",
						CFrame.identity,
						Vector3.new(0.95, 0.38, segmentLength * 0.92),
						GOLD,
						0
					)
				),
				Enum.Material.Neon
			)
			links[index] = link
		end

		local tip = cast:Add(core.Part("GoldenChainHead", CFrame.identity, Vector3.one * 3.5, GOLD, 0.06))
		tip.Shape = Enum.PartType.Ball
		style(tip, Enum.Material.Neon)
		local aura = cast:Add(core.Part("GoldenChainHeadAura", CFrame.identity, Vector3.one * 8, GOLD, 0.82))
		aura.Shape = Enum.PartType.Ball
		style(aura, Enum.Material.Neon)

		local elapsed, hits = 0, {}
		local captures = {}
		local fading, fadeTime = false, 0
		local owner, generation = cast.owner, cast.owner:GetAttribute("PhaseGeneration") or 0
		local revision = owner:GetAttribute("MovementRevision") or 0
		local pullSpeed = math.clamp(Config.GoldenChainPullSpeed or 9, 2, 18)
		local blendDuration = math.clamp(Config.GoldenChainCaptureBlendDuration or 0.3, 0.15, 0.6)
		local dragSpeed = math.clamp(Config.GoldenChainDragMaxSpeed or 125, 30, 150)
		local sampleWindow = math.clamp(Config.GoldenChainThrowSampleWindow or 0.22, 0.1, 0.35)
		local arenaMargin = math.clamp(Config.GoldenChainArenaMargin or 8, 5, 16)
		local turns = Config.GoldenChainSpinTurns or 1
		local function strandPoint(points, fraction)
			local along = math.clamp(fraction, 0, 1) * count
			local index = math.min(math.floor(along) + 1, count)
			return points[index]:Lerp(points[index + 1], along - index + 1)
		end
		local function throwVelocity(state)
			local r = state.Root
			local physical = Vector3.new(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z)
			local sampled, samples = Vector3.zero, 0
			for _, sample in ipairs(state.MotionSamples) do
				if elapsed - sample.At <= sampleWindow then
					sampled += sample.Velocity
					samples += 1
				end
			end
			local motion = samples > 0 and sampled / samples or state.LastMotion or Vector3.zero
			local movement = physical.Magnitude > 4 and physical or motion
			if physical.Magnitude > 4 and motion.Magnitude > 4 then
				movement = physical * 0.75 + motion.Unit * math.min(motion.Magnitude, dragSpeed) * 0.25
			end
			if movement.Magnitude < 0.1 then
				return Vector3.zero
			end
			local maximum = math.clamp(Config.GoldenChainThrowMaxSpeed or 88, 20, 110)
			local minimum = math.clamp(Config.GoldenChainThrowMinSpeed or 32, 0, maximum)
			local horizontal = movement.Unit * math.clamp(movement.Magnitude, minimum, maximum)
			local lift = math.clamp(Config.GoldenChainThrowUpward or 18, 0, 28)
			local bounds = Placement.GetBounds()
			if not bounds then
				return Vector3.zero
			end
			local position = bounds.Frame:PointToObjectSpace(r.Position)
			local localVelocity = bounds.Frame:VectorToObjectSpace(horizontal)
			 
			 
			 
			local horizon = math.max(
				0.35,
				2 * lift / math.max(workspace.Gravity, 1) + 0.25,
				math.clamp(Config.GoldenChainThrowBoundaryBrakeDistance or 28, 12, 50) / maximum
			)
			local x = math.clamp(
				localVelocity.X,
				-math.max(0, bounds.HalfX - arenaMargin + position.X) / horizon,
				math.max(0, bounds.HalfX - arenaMargin - position.X) / horizon
			)
			local z = math.clamp(
				localVelocity.Z,
				-math.max(0, bounds.HalfZ - arenaMargin + position.Z) / horizon,
				math.max(0, bounds.HalfZ - arenaMargin - position.Z) / horizon
			)
			return bounds.Frame:VectorToWorldSpace(Vector3.new(x, 0, z)) + Vector3.new(0, lift, 0)
		end
		local function release(character, natural)
			local state = captures[character]
			if not state then
				return
			end
			captures[character] = nil
			local r = state.Root
			local launch = natural
					and core.Alive(character)
					and state.Player.Parent == Players
					and state.Player.Character == character
					and not r.Anchored
					and not Status.IsDebuffImmune(character)
					and not character:GetAttribute("ParryFrozen")
					and not character:GetAttribute("ExecutionPending")
					and not character:GetAttribute("TimeFrozen")
					and throwVelocity(state)
				or nil
			if launch and launch.Magnitude < 0.1 then
				launch = nil
			end
			if state.DragAudio then
				state.DragAudio:Dispose()
			end
			if state.Constraint.Parent then
				state.Constraint:Destroy()
			end
			if state.Tether.Parent then
				state.Tether:Destroy()
			end
			if state.Attachment.Parent then
				state.Attachment:Destroy()
			end
			if state.Highlight then
				state.Highlight:Destroy()
			end
			Status.ReleaseRestraint(character, cast)
   if natural and (state.AppliedDamage or 0)>0 then AttackDebuffs.Apply(actor,character,"ChainCurse",4,cast) end
			Audio.Emit(actor, "ChainBreak", state.Root)
			if character.Parent then
				character:SetAttribute("GoldenChainDragged", false)
			end
			if r.Parent and not r.Anchored then
				local velocity = r.AssemblyLinearVelocity
				r.AssemblyLinearVelocity = launch or Vector3.new(0, math.min(velocity.Y, 0), 0)
				state.ReleaseVelocity = r.AssemblyLinearVelocity
			end
			state.ReleaseKind = launch and "Throw" or "Cancel"
			if launch then
				actor:SetAttribute("GoldenChainThrows", (actor:GetAttribute("GoldenChainThrows") or 0) + 1)
				if r.Parent then
					shock(r.Position, 3, 22, 0.4, 28)
				end  
			end
			if state.TookOwnership and r.Parent and not r.Anchored then
				pcall(function()
					if state.Automatic or state.PriorOwner and state.PriorOwner.Parent ~= Players then
						r:SetNetworkOwnershipAuto()
					else
						r:SetNetworkOwner(state.PriorOwner)
					end
				end)
			end
		end
		local function cleanup(natural)
			local selected = {}
			for character in pairs(captures) do
				selected[#selected + 1] = character
			end
			for _, character in ipairs(selected) do
				release(character, natural)
			end
			table.clear(bodyCache)
		end
		 
		 
		cast.OnExpire = function()
			cleanup(false)
		end
		cast.OnDispose = function()
			cleanup(false)
		end
		Audio.Loop(cast, actor, "ChainSpin", anchor)
		local function capture(character, segmentIndex, segmentFraction)
			if
				not core.Alive(character)
				or Status.IsDebuffImmune(character)
				or captures[character]
				or character:GetAttribute("GoldenChainDragged")
			then
				return false
			end
			local r = character.HumanoidRootPart
			local player = Players:GetPlayerFromCharacter(character)
			 
			 
			if
				not player
				or player.Character ~= character
				or r.Anchored
				or player:GetAttribute("PermanentlyDefeated")
				or player:GetAttribute("ViewAsServer")
				or player:GetAttribute("ExecutionPending")
				or character:GetAttribute("ParryFrozen")
				or character:GetAttribute("ExecutionPending")
				or character:GetAttribute("TimeFrozen")
				or character:FindFirstChildOfClass("ForceField")
				or workspace:GetServerTimeNow() < (character:GetAttribute("RespawnInvulnerableUntil") or 0)
			then
				return false
			end
			 
			 
			 
			if not Status.Restrain(character, cast, api.SweepDuration + lag + 0.15, { AllowDefense = true }) then
				return false
			end
			Dash.Cancel(player, "Golden Chain capture")
			local queriedAuto, automatic = pcall(function()
				return r:GetNetworkOwnershipAuto()
			end)
			local queriedOwner, priorOwner = pcall(function()
				return r:GetNetworkOwner()
			end)
			if not queriedAuto then
				automatic = true
			end
			if not queriedOwner then
				priorOwner = player
			end
			local tookOwnership = pcall(function()
				r:SetNetworkOwner(nil)
			end)
			local attachment = Instance.new("Attachment")
			attachment.Name = "GoldenChainDragAttachment"
			attachment.Parent = r
			local constraint = Instance.new("AlignPosition")
			constraint.Name = "GoldenChainPhysicalDrag"
			constraint.Mode = Enum.PositionAlignmentMode.OneAttachment
			constraint.Attachment0 = attachment
			constraint.Position = r.Position
			constraint.ApplyAtCenterOfMass = true
			constraint.RigidityEnabled = false
			constraint.MaxForce = math.max(r.AssemblyMass, 1) * 2000
			constraint.MaxVelocity = dragSpeed
			constraint.Responsiveness = math.clamp(Config.GoldenChainDragResponsiveness or 45, 10, 60)
			constraint.Parent = r
			local firstIndex = math.clamp(segmentIndex, 1, count)
			local tether = Instance.new("Beam")
			tether.Name = "GoldenChainCapturedStrand"
			tether.Attachment0 = attachments[count + 1]
			tether.Attachment1 = attachment
			tether.Width0 = 0.45
			tether.Width1 = 0.45
			tether.FaceCamera = true
			tether.LightEmission = 1
			tether.Segments = 1
			tether.Color = ColorSequence.new(GOLD, BRIGHT)
			tether.Parent = anchor
			local fraction = (firstIndex - 1 + math.clamp(segmentFraction, 0, 1)) / count
			local floor = Placement.GroundPoint(r.Position, { Margin = arenaMargin, Clamp = true })

			 
			local highlight = Instance.new("Highlight")
			highlight.Name = "GoldenChainBind"
			highlight.FillColor = GOLD
			highlight.OutlineColor = BRIGHT
			highlight.FillTransparency = 0.72
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.Adornee = character
			highlight.Parent = character
			sparks(attachment, 40, 14, 0.5, 0.5)  
			shock(r.Position, 2, 16, 0.3, 28)

			captures[character] = {
				Root = r,
				Player = player,
				Constraint = constraint,
				Attachment = attachment,
				TookOwnership = tookOwnership,
				Automatic = automatic,
				PriorOwner = priorOwner,
				Tether = tether,
				FirstIndex = firstIndex,
				SegmentFraction = math.clamp(segmentFraction, 0, 1),
				StartedAt = elapsed,
				Origin = r.Position,
				CaptureFraction = fraction,
				Fraction = fraction,
				FloorOffset = floor and math.clamp(r.Position.Y - floor.Y, 2, 6) or 3,
				MotionSamples = {},
				Highlight = highlight,
			}
			character:SetAttribute("GoldenChainDragged", true)
			Audio.Emit(actor, "ChainContact", r)
			captures[character].DragAudio = Audio.Loop(cast, actor, "ChainDrag", r)
			hits[character] = true
			captures[character].AppliedDamage=core.Damage(character, api.Damage,"P1.5GoldenChain")
			actor:SetAttribute("GoldenChainCaptures", (actor:GetAttribute("GoldenChainCaptures") or 0) + 1)
			return true
		end
		local function bodies(character)
			local records = bodyCache[character]
			if not records then
				records = {}
				 
				 
				for _, part in ipairs(character:GetChildren()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						records[#records + 1] = { Part = part, PreviousFrame = part.CFrame, Frame = part.CFrame }
					end
				end
				bodyCache[character] = records
			end
			for _, record in ipairs(records) do
				if record.Part.Parent == character then
					record.Frame = record.Part.CFrame
				end
			end
			return records
		end
		local function contact(character, records, fraction)
			for _, record in ipairs(records) do
				record.SampleFrame = record.PreviousFrame:Lerp(record.Frame, fraction)
			end
			for index = 1, count do
				for _, record in ipairs(records) do
					local part = record.Part
					if part.Parent == character then
						local along = segmentContact(
							positions[index],
							positions[index + 1],
							record.SampleFrame,
							part.Size,
							0.325 + contactPadding
						)
						if along then
							return index, along
						end
					end
				end
			end
			local tipPosition = positions[count + 1]
			for _, record in ipairs(records) do
				if
					record.Part.Parent == character
					and headContact(
						tipPosition,
						record.SampleFrame,
						record.Part.Size,
						tip.Size.X * 0.5 + contactPadding
					)
				then
					return count, 1
				end
			end
		end

		 
		 
		local function place(time)
			local tighten = math.clamp((time - api.SweepDuration + 0.15) / (0.15 + lag), 0, 1)
			for index = 0, count do
				local fraction = index / count
				local delayed = math.clamp((time - lag * fraction) / api.SweepDuration, 0, 1)
				local angle = startAngle + direction * delayed * TAU * turns
				local ripple = math.sin(time * 12 - fraction * 8) * 0.45 * math.sin(fraction * math.pi) * (1 - tighten)
				local y = -math.sin(fraction * math.pi) * sag * (1 - 0.85 * tighten) + ripple
				positions[index + 1] = center
					+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * (fraction * api.Radius)
					+ Vector3.new(0, y, 0)
			end
		end
		 
		local function render()
			for index = 0, count do
				attachments[index + 1].WorldPosition = positions[index + 1]
			end
			for index = 1, count do
				local a, b = positions[index], positions[index + 1]
				if (b - a).Magnitude > 0.05 then
					local roll = index % 2 == 0 and math.pi * 0.5 or 0
					links[index].CFrame = CFrame.lookAt((a + b) * 0.5, b) * CFrame.Angles(0, 0, roll)
				end
			end
			local tipFrame = CFrame.new(positions[#positions])
			tip.CFrame = tipFrame
			aura.CFrame = tipFrame
		end

		place(0)
		render()

		 
		 
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 24
		light.Brightness = 3
		light.Shadows = false
		light.Parent = tip
		local trailTop, trailBottom = Instance.new("Attachment"), Instance.new("Attachment")
		trailTop.Position = Vector3.new(0, 1.6, 0)
		trailBottom.Position = Vector3.new(0, -1.6, 0)
		trailTop.Parent = tip
		trailBottom.Parent = tip
		local trail = Instance.new("Trail")
		trail.Name = "GoldenChainHeadTrail"
		trail.Attachment0 = trailTop
		trail.Attachment1 = trailBottom
		trail.Lifetime = 0.45
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Color = ColorSequence.new(BRIGHT, GOLD)
		trail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		trail.Parent = tip
		emitters[#emitters + 1] = sparks(tip, 70, 16, 0.7, 0.55)
		for index = 2, count + 1, 2 do  
			emitters[#emitters + 1] = sparks(attachments[index], 9, 6, 0.35, 0.4)
		end
		shock(groundCenter, 6, 36, 0.5, 24)  

		cast:Step(function(dt)
			if
				owner:GetAttribute("PhaseTransitionInProgress")
				or owner:GetAttribute("AIEnabled") == false
				or (owner:GetAttribute("PhaseGeneration") or 0) ~= generation
				or (owner:GetAttribute("MovementRevision") or 0) ~= revision
			then
				cast:Dispose()
				return false
			end
			if Time.IsStopped(actor) then
				return true
			end

			 
			if fading then
				fadeTime += dt
				local alpha = math.clamp(fadeTime / FADE_TIME, 0, 1)
				for _, entry in ipairs(beams) do
					entry.Beam.Transparency = NumberSequence.new(entry.Base + (1 - entry.Base) * alpha)
				end
				for _, link in ipairs(links) do
					link.Transparency = alpha
				end
				tip.Transparency = 0.06 + 0.94 * alpha
				aura.Transparency = 0.82 + 0.18 * alpha
				light.Brightness = 3 * (1 - alpha)
				if alpha >= 1 then
					cast:Dispose()
					return false
				end
				return true
			end

			local previousElapsed = elapsed
			local previousPositions = table.clone(positions)
			 
			 
			 
			elapsed = math.min(elapsed + dt, api.SweepDuration + lag)
			local samples = math.clamp(math.ceil((elapsed - previousElapsed) / collisionStep), 1, 32)
			local candidates = {}
			for _, character in ipairs(core.Characters()) do
				if core.Alive(character) and not hits[character] then
					local records = bodies(character)
					if (character.HumanoidRootPart.Position - center).Magnitude <= api.Radius + 6 then
						candidates[#candidates + 1] = { Character = character, Bodies = records }
					end
				elseif not character.Parent then
					bodyCache[character] = nil
				end
			end
			for sample = 1, samples do
				local fraction = sample / samples
				place(previousElapsed + (elapsed - previousElapsed) * fraction)
				for _, candidate in ipairs(candidates) do
					local character = candidate.Character
					if not hits[character] then
						local index, along = contact(character, candidate.Bodies, fraction)
						if index then
							capture(character, index, along)
						end
					end
				end
			end
			render()
			for character, state in pairs(captures) do
				local r = state.Root
				if
					not core.Alive(character)
					or state.Player.Parent ~= Players
					or state.Player.Character ~= character
					or r.Anchored
					or Status.IsDebuffImmune(character)
					or character:GetAttribute("ParryFrozen")
					or character:GetAttribute("ExecutionPending")
				then
					release(character)
				else
					 
					 
					 
					local since = elapsed - state.StartedAt
					state.Fraction = math.min(1, state.CaptureFraction + since * pullSpeed / api.Radius)
					local desired = strandPoint(positions, state.Fraction)
					local prior = strandPoint(previousPositions, state.Fraction)
					local motion = Vector3.new(desired.X - prior.X, 0, desired.Z - prior.Z)
						/ math.max(elapsed - previousElapsed, 0.001)
					if motion.Magnitude > 2 then
						motion = motion.Unit * math.min(motion.Magnitude, dragSpeed * 2)
						state.LastMotion = motion
						table.insert(state.MotionSamples, { At = elapsed, Velocity = motion })
					end
					while state.MotionSamples[1] and elapsed - state.MotionSamples[1].At > sampleWindow do
						table.remove(state.MotionSamples, 1)
					end
					local ground = Placement.GroundPoint(desired, { Margin = arenaMargin, Clamp = true })
					if not ground then
						release(character, false)
					else
						desired = Vector3.new(ground.X, ground.Y + state.FloorOffset + 0.6, ground.Z)
						state.Constraint.Position = state.Origin:Lerp(desired, math.clamp(since / blendDuration, 0, 1))
						state.Constraint.MaxVelocity = dragSpeed
					end
				end
			end
			for character, records in pairs(bodyCache) do
				if not character.Parent then
					bodyCache[character] = nil
				else
					for _, record in ipairs(records) do
						record.PreviousFrame = record.Frame
					end
				end
			end
			if elapsed >= api.SweepDuration + lag then
				cleanup(true)
				shock(groundCenter, 6, 34, 0.45, 24)  
				for _, emitter in ipairs(emitters) do
					emitter.Enabled = false
				end
				fading = true
			end
			return true
		end)
		actor:SetAttribute("GoldenChainSweeps", (actor:GetAttribute("GoldenChainSweeps") or 0) + 1)
		return {
			Cast = cast,
			Center = center,
			Radius = api.Radius,
			Attachments = attachments,
			Head = tip,
			Captures = captures,
		}
	end
	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5
			and core.Active()
			and core.Alive(character)
			and (character.HumanoidRootPart.Position - core.Root.Position).Magnitude <= api.Radius
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P1.5GoldenChain", function()
			core.Face(character)
			core.Melee.Pose("Windup2", 0.16)
			actor:SetAttribute("AttackState", "Golden Chain: winding up")
			local center = core.Root.Position + Vector3.new(0, 0.2, 0)

			 
			local look = core.Root.CFrame.LookVector
			local startAngle = math.atan2(look.Z, look.X)
			 
			 
			local direction = Config.GoldenChainRandomDirection and (math.random() < 0.5 and -1 or 1) or 1

			local warning = Effects.NewCast(actor, "GoldenChainWarning", api.WarningTime + 0.1)
			Audio.Emit(actor, "ChainSummon", center)

			local diameter = api.Radius * 2
			local groundCenter = center - Vector3.new(0, GROUND_DROP, 0)
			local flat = CFrame.Angles(0, 0, math.pi * 0.5)

			 
			local disk = warning:Add(
				core.Part(
					"GoldenChainSweepWarning",
					CFrame.new(groundCenter) * flat,
					Vector3.new(0.1, diameter, diameter),
					GOLD,
					0.9
				)
			)
			disk.Shape = Enum.PartType.Cylinder
			style(disk)
			 
			local rim = warning:Add(
				core.Part(
					"GoldenChainWarningRim",
					CFrame.new(groundCenter + Vector3.new(0, 0.05, 0)) * flat,
					Vector3.new(0.1, diameter, diameter),
					GOLD,
					1
				)
			)
			rim.Shape = Enum.PartType.Cylinder
			style(rim)
			local rimStroke = makeRing(rim, 5, BRIGHT)
			 
			local fill = warning:Add(
				core.Part(
					"GoldenChainWarningFill",
					CFrame.new(groundCenter + Vector3.new(0, 0.03, 0)) * flat,
					Vector3.new(0.1, 0.5, 0.5),
					GOLD,
					0.8
				)
			)
			fill.Shape = Enum.PartType.Cylinder
			style(fill, Enum.Material.Neon)
			 
			local lineOrigin = groundCenter + Vector3.new(0, 0.1, 0)
			local startDirection = Vector3.new(math.cos(startAngle), 0, math.sin(startAngle))
			local line = warning:Add(
				core.Part(
					"GoldenChainWarningStart",
					CFrame.lookAt(lineOrigin, lineOrigin + startDirection) * CFrame.new(0, 0, -api.Radius * 0.5),
					Vector3.new(0.7, 0.1, api.Radius),
					BRIGHT,
					0.6
				)
			)
			style(line, Enum.Material.Neon)
			local marker =
				warning:Add(core.Part("GoldenChainWarningMarker", CFrame.new(lineOrigin), Vector3.one * 3, BRIGHT, 0.1))
			marker.Shape = Enum.PartType.Ball
			style(marker, Enum.Material.Neon)

			local waited = 0
			warning:Step(function(dt)
				waited += dt
				local alpha = math.clamp(waited / api.WarningTime, 0, 1)
				local size = math.max(diameter * alpha, 0.5)
				fill.Size = Vector3.new(0.1, size, size)
				fill.Transparency = 0.82 - 0.25 * alpha
				local pulse = 0.5 + 0.5 * math.sin(waited * (14 + 26 * alpha))
				rimStroke.Transparency = 0.5 - 0.45 * pulse * (0.4 + 0.6 * alpha)
				line.Transparency = 0.65 - 0.3 * pulse
				local angle = startAngle + direction * alpha * 0.9
				marker.Position = lineOrigin + Vector3.new(math.cos(angle), 0, math.sin(angle)) * api.Radius * 0.97
				return true
			end)

			if not core.WaitFor(api.WarningTime) then
				warning:Dispose()
				return false
			end
			warning:Dispose()
			actor:SetAttribute("AttackState", "Golden Chain: circular sweep")
			core.Melee.Pose("Slash2", 0.08)
			api.Sweep(center, startAngle, direction)
			return core.WaitFor(api.SweepDuration + (Config.GoldenChainLag or 0.18))
		end)
	end
	return api
end
