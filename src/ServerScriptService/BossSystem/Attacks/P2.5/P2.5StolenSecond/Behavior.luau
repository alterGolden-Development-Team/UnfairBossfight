local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local Replicated = game:GetService("ReplicatedStorage")
local inputs = {}
local remote = Replicated:WaitForChild("TemporalInput")
local Balance = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))

local function finite(value)
	return value == value and math.abs(value) < 1e5
end
local inputConnection = remote.OnServerEvent:Connect(function(player, kind, id, sequence, direction)
	local record = inputs[player]
	if
		(kind ~= "Input" and kind ~= "Dash")
		or not record
		or record.closed
		or id ~= record.id
		or player.Character ~= record.character
		or record.mode ~= "Recording"
		or os.clock() > record.inputDeadline
		or typeof(direction) ~= "Vector3"
		or not finite(direction.X)
		or not finite(direction.Y)
		or not finite(direction.Z)
		or math.abs(direction.Y) > 0.05
		or direction.Magnitude > 1.05
	then
		return
	end
	if kind == "Dash" then
		if not record.storedDash and direction.Magnitude > 0.1 then
			record.storedDash = direction.Unit
		end
		return
	end
	if
		type(sequence) ~= "number"
		or sequence % 1 ~= 0
		or sequence <= record.sequence
		or sequence > (Balance.StolenSecondMaxSamples or 40) + 24
	then
		return
	end
	local now = os.clock()
	if now - record.lastPacket < 0.03 then
		return
	end
	record.lastPacket = now
	record.sequence = sequence
	record.direction = Vector3.new(direction.X, 0, direction.Z)
end)
script.Destroying:Connect(function()
	inputConnection:Disconnect()
	local owned = {}
	for _, record in pairs(inputs) do
		table.insert(owned, record.cast)
	end
	for _, cast in ipairs(owned) do
		cast:Dispose()
	end
	table.clear(inputs)
end)

return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Dash = require(BossSystem.Players.R6DashService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local api = { Cooldown = Config.StolenSecondCooldown or 30 }
	local current
	local GOLD = Style.GOLD
	local CYAN = Style.CYAN
	local HOT = Style.HOT
	local TAU = math.pi * 2
	local DIAL = 5.4

	local function floorY(position)
		local ground = Placement.GroundPoint(position, { Margin = 2, Clamp = true })
		return ground and ground.Y or position.Y - 2.9
	end
	local shards = Visuals.shards({
		HOT = HOT,
	})
	local flourish = Visuals.flourish({
		Effects = Effects,
		actor = actor,
		floorY = floorY,
		core = core,
		GOLD = GOLD,
		shards = shards,
	})

	function api.CanUse(character,fromCard)
		local phase = tonumber(actor:GetAttribute("Phase")) or 1
		local player = character and Players:GetPlayerFromCharacter(character)
		return (phase >= 2.5 and phase < 3 or fromCard==true and math.floor(phase)==3)
			and core.Active()
			and core.Alive(character)
			and player
			and player.Character == character
			and not inputs[player]
			and not current
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and not Status.IsMovementLocked(player)
			and not Status.IsDebuffImmune(character)
			and not character:GetAttribute("TimeFrozen")
			and not Time.IsStopped(actor)
	end

	function api.Begin(character,fromCard)
		if not api.CanUse(character,fromCard) then
			return false
		end
		local player = Players:GetPlayerFromCharacter(character)
		local root = character.HumanoidRootPart
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if root.Anchored then
			return false
		end
		local recording = math.clamp(Config.StolenSecondRecordingDuration or 2.5, 0.5, 4)
		local replay = math.clamp(Config.StolenSecondReplayDuration or 0.4, 0.25, 0.7)
		local maxSamples = math.clamp(Config.StolenSecondMaxSamples or 40, 8, 48)
		local sampleInterval = recording / maxSamples
		local cast = Effects.NewCast(actor, "StolenSecondMovement", recording + replay + 0.3)
		local generation = actor:GetAttribute("PhaseGeneration") or 0
		local record = {
			id = Http:GenerateGUID(false),
			character = character,
			player = player,
			cast = cast,
			mode = "Recording",
			sequence = 0,
			direction = Vector3.zero,
			lastPacket = -math.huge,
			inputDeadline = os.clock() + recording + 0.1,
			samples = {},
			speed = math.clamp(humanoid.WalkSpeed, 0, 45),
			origin = root.CFrame,
			anchored = root.Anchored,
			closed = false,
		}
		record.ownershipAuto = true
		pcall(function()
			record.ownershipAuto = root:GetNetworkOwnershipAuto()
			record.networkOwner = root:GetNetworkOwner()
		end)
		inputs[player] = record
		current = cast
		api.LastRecord = record
		cast.OnDispose = function()
			record.closed = true
			if current == cast then
				current = nil
			end
			if inputs[player] == record then
				inputs[player] = nil
				if player.Parent == Players then
					player:SetAttribute("StolenSecondRecording", false)
					player:SetAttribute("StolenSecondUntil", 0)
					pcall(function()
						remote:FireClient(player, "End", record.id)
					end)
				end
			end
			if character.Parent then
				character:SetAttribute("StolenSecondActive", false)
				character:SetAttribute("StolenSecondRecording", false)
				character:SetAttribute("StolenSecondUntil", 0)
				character:SetAttribute("StolenSecondReplaying", false)
				if character:GetAttribute("StolenSecondSessionId") == record.id then
					character:SetAttribute("StolenSecondSessionId", nil)
				end
				Time.SetAnchored(root, record.anchored)
				if root.Parent then
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					if not record.anchored and not root.Anchored then
						pcall(function()
							if
								record.ownershipAuto
								or record.networkOwner and record.networkOwner.Parent ~= Players
							then
								root:SetNetworkOwnershipAuto()
							else
								root:SetNetworkOwner(record.networkOwner)
							end
						end)
					end
				end
				Status.ReleaseRestraint(character, cast)
			end
		end
		if not Status.Restrain(character, cast, recording + replay + 0.2, { AllowDefense = true }) then
			cast:Dispose()
			return false
		end
		Dash.Cancel(player, "Stolen Second")
		Time.SetAnchored(root, true)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		character:SetAttribute("StolenSecondActive", true)
		character:SetAttribute("StolenSecondSessionId", record.id)
		local displayUntil = workspace:GetServerTimeNow() + recording
		character:SetAttribute("StolenSecondRecording", true)
		character:SetAttribute("StolenSecondUntil", displayUntil)
		player:SetAttribute("StolenSecondRecording", true)
		player:SetAttribute("StolenSecondUntil", displayUntil)
		character:SetAttribute("StolenSecondReplaying", false)
		local marker = cast:Add(core.Part("StolenSecondPathAnchor", root.CFrame, Vector3.one * 0.1, GOLD, 1))
		local ghosts = {}
		local ribbons = {}
		local waypoints = {}
		local priorNode
		local nodeCount = 0
		for _, name in ipairs({ "Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }) do
			local source = character:FindFirstChild(name)
			if source and source:IsA("BasePart") then
				local part = cast:Add(core.Part("StolenSecondMovementGhost", source.CFrame, source.Size, GOLD, 0.66))
				table.insert(ghosts, { Part = part, Offset = root.CFrame:ToObjectSpace(source.CFrame) })
			end
		end
		record.previewFrame = root.CFrame
		local function node(position)
			local attachment = Instance.new("Attachment")
			attachment.Position = marker.CFrame:PointToObjectSpace(position)
			attachment.Parent = marker
			if priorNode and (priorNode.WorldPosition - position).Magnitude > 0.08 then
				local beam = Instance.new("Beam")
				beam.Name = "StolenSecondGhostMovementPath"
				beam.Attachment0 = priorNode
				beam.Attachment1 = attachment
				beam.Width0 = 0.18
				beam.Width1 = 0.18
				beam.Color = ColorSequence.new(GOLD)
				beam.LightEmission = 1
				beam.FaceCamera = true
				beam.Transparency = NumberSequence.new(0.34)
				beam.Segments = 1
				beam.Parent = marker
				table.insert(ribbons, beam)
			end
			priorNode = attachment
			nodeCount += 1
			if nodeCount % 4 == 0 then
				local diamond = cast:Add(
					core.Part(
						"StolenSecondWaypoint",
						CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, math.pi / 4, 0),
						Vector3.new(0.55, 0.08, 0.55),
						GOLD,
						0.3
					)
				)
				table.insert(waypoints, diamond)
			end
		end
		node(root.Position - Vector3.new(0, 2.2, 0))

		local dialCenter = Vector3.new(root.Position.X, floorY(root.Position) + 0.15, root.Position.Z)
		local dialDisc = cast:Add(
			core.Part(
				"StolenSecondDial",
				CFrame.new(dialCenter) * CFrame.Angles(0, 0, math.pi * 0.5),
				Vector3.new(0.1, DIAL * 2, DIAL * 2),
				GOLD,
				0.9
			)
		)
		dialDisc.Shape = Enum.PartType.Cylinder
		local ticks = {}
		for index = 1, 12 do
			local theta = index * math.pi / 6
			local major = index % 3 == 0
			local length = major and 1.2 or 0.6
			local direction = Vector3.new(math.sin(theta), 0, -math.cos(theta))
			local position = dialCenter + direction * (DIAL - length * 0.5 - 0.2) + Vector3.new(0, 0.03, 0)
			ticks[index] = cast:Add(
				core.Part(
					"StolenSecondDialTick",
					CFrame.lookAt(position, position + direction),
					Vector3.new(major and 0.3 or 0.2, 0.1, length),
					GOLD,
					0.6
				)
			)
		end
		local hand = cast:Add(
			core.Part("StolenSecondDialHand", CFrame.new(dialCenter), Vector3.new(0.24, 0.1, DIAL - 0.8), HOT, 0.1)
		)
		local tail =
			cast:Add(core.Part("StolenSecondDialTail", CFrame.new(dialCenter), Vector3.new(0.24, 0.1, 1.2), GOLD, 0.3))
		local function placeHand(angle)
			local direction = Vector3.new(math.sin(angle), 0, -math.cos(angle))
			local lift = Vector3.new(0, 0.06, 0)
			local handMid = dialCenter + direction * ((DIAL - 0.8) * 0.5) + lift
			local tailMid = dialCenter - direction * 0.6 + lift
			hand.CFrame = CFrame.lookAt(handMid, handMid + direction)
			tail.CFrame = CFrame.lookAt(tailMid, tailMid + direction)
		end
		placeHand(0)

		local bossRoot = actor:FindFirstChild("HumanoidRootPart")
		local tether
		if bossRoot then
			local from = cast:Add(Instance.new("Attachment"))
			from.Name = "StolenSecondTetherSource"
			from.Position = Vector3.new(0, 0.5, 0)
			from.Parent = bossRoot
			local to = cast:Add(Instance.new("Attachment"))
			to.Name = "StolenSecondTetherTarget"
			to.Position = Vector3.new(0, 0.5, 0)
			to.Parent = root
			tether = cast:Add(Instance.new("Beam"))
			tether.Name = "StolenSecondTether"
			tether.Attachment0 = from
			tether.Attachment1 = to
			tether.Width0 = 0.5
			tether.Width1 = 0.15
			tether.CurveSize0 = 5
			tether.CurveSize1 = -5
			tether.Segments = 16
			tether.FaceCamera = true
			tether.LightEmission = 1
			tether.Color = ColorSequence.new(GOLD, HOT)
			tether.Transparency = NumberSequence.new(0.35)
			tether.Parent = bossRoot
		end
		local drain = cast:Add(Instance.new("ParticleEmitter"))
		drain.Name = "StolenSecondDrain"
		drain.Rate = 12
		drain.Lifetime = NumberRange.new(0.6, 1.1)
		drain.Speed = NumberRange.new(0.5, 2)
		drain.Acceleration = Vector3.new(0, 4, 0)
		drain.SpreadAngle = Vector2.new(180, 180)
		drain.LightEmission = 1
		drain.Color = ColorSequence.new(GOLD, HOT)
		drain.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		drain.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		drain.Parent = root
		local head =
			cast:Add(core.Part("StolenSecondHeadMarker", CFrame.new(root.Position), Vector3.one * 0.9, HOT, 0.1))
		head.Shape = Enum.PartType.Ball
		flourish(root.Position, GOLD, 14)

		remote:FireClient(player, "Begin", record.id, character, recording)
		core.ScreenEffect("StolenSecond", { Duration = recording, ReplayDuration = replay }, player)
		local filter = Runtime.FilterFor(actor, core.Effects)
		local began = cast:Now()
		local replayBegan
		local sampleElapsed = 0
		local function valid()
			return cast:Alive()
				and actor.Parent
				and actor.Humanoid.Health > 0
				and not actor:GetAttribute("EncounterEnded")
				and core.Alive(character)
				and player.Parent == Players
				and player.Character == character
				and (actor:GetAttribute("PhaseGeneration") or 0) == generation
				and not actor:GetAttribute("PhaseTransitionInProgress")
				and not Status.IsDebuffImmune(character)
				and not character:GetAttribute("TimeFrozen")
				and not Time.IsStopped(actor)
				and Status.ExclusivelyRestrainedBy(character, cast)
		end
		local function advance(frame, delta)
			if delta.Magnitude < 0.001 then
				return frame
			end
			local hit =
				workspace:Blockcast(frame + Vector3.new(0, -0.2, 0), Vector3.new(2.4, 5.4, 2.4), delta, filter())
			if hit then
				delta = delta.Unit * math.max(0, hit.Distance - 0.15)
			end
			local candidate = frame + delta
			local goal = Placement.Validate(character, candidate, { Margin = 3, PreserveHeight = true, MaxHeight = 55 })
			if goal then
				return goal
			end
			 
			local low, high, best = 0, 1, frame
			for _ = 1, 5 do
				local fraction = (low + high) * 0.5
				local safe = Placement.Validate(
					character,
					frame + delta * fraction,
					{ Margin = 3, PreserveHeight = true, MaxHeight = 55 }
				)
				if safe then
					low = fraction
					best = safe
				else
					high = fraction
				end
			end
			return best
		end
		cast:Step(function(dt, now)
			if not valid() then
				cast:Dispose()
				return false
			end
			if record.mode == "Recording" then
				root.CFrame = record.origin
				sampleElapsed += dt
				while sampleElapsed >= sampleInterval and #record.samples < maxSamples do
					sampleElapsed -= sampleInterval
					local direction = os.clock() - record.lastPacket <= 0.16 and record.direction or Vector3.zero
					local sample = direction * record.speed * sampleInterval
					record.previewFrame = advance(record.previewFrame, sample)
					table.insert(
						record.samples,
						record.previewFrame.Position - (record.previewPosition or record.origin.Position)
					)
					record.previewPosition = record.previewFrame.Position
					node(record.previewFrame.Position - Vector3.new(0, 2.2, 0))
				end
				for _, ghost in ipairs(ghosts) do
					ghost.Part.CFrame = record.previewFrame * ghost.Offset
				end
				local progress = math.clamp((now - began) / recording, 0, 1)
				local urgent = recording - (now - began) < 0.5
				local strobe = math.floor(now * 24) % 2
				placeHand(progress * TAU)
				for index, mark in ipairs(ticks) do
					mark.Transparency = progress * 12 >= index and 0.12 or 0.6
				end
				dialDisc.Transparency = 0.9 - 0.04 * math.sin(now * 6)
				hand.Transparency = urgent and (strobe == 0 and 0.1 or 0.6) or 0.1
				if tether then
					tether.Width0 = 0.5 + 0.12 * math.sin(now * 12)
					tether.Width1 = 0.15 + 0.05 * math.sin(now * 12 + 1)
				end
				head.CFrame = CFrame.new(record.previewFrame.Position - Vector3.new(0, 1.7, 0))
				head.Size = Vector3.one * (0.8 + 0.2 * math.sin(now * 10))
				for index, ghost in ipairs(ghosts) do
					ghost.Part.Transparency = 0.62 + 0.06 * math.sin(now * 14 + index) + (urgent and 0.1 * strobe or 0)
				end
				local total = #ribbons
				for index, beam in ipairs(ribbons) do
					local heat = math.clamp(1 - (total - index) / 6, 0, 1)
					beam.Color = ColorSequence.new(GOLD:Lerp(HOT, heat))
					beam.Width0 = 0.18 + 0.1 * heat
					beam.Width1 = beam.Width0
				end
				if now - began < recording then
					return true
				end
				if record.storedDash then
					local accepted, dashDelta = Dash.AuthorizeStoredDash(player, character, record.storedDash, cast)
					if accepted then
						local before = record.previewFrame.Position
						record.previewFrame = advance(record.previewFrame, dashDelta)
						table.insert(record.samples, record.previewFrame.Position - before)
						node(record.previewFrame.Position - Vector3.new(0, 2.2, 0))
					end
				end
				record.mode = "Replay"
				replayBegan = now
				record.replayProgress = 0
				record.replayFrame = root.CFrame
				character:SetAttribute("StolenSecondRecording", false)
				character:SetAttribute("StolenSecondUntil", 0)
				player:SetAttribute("StolenSecondRecording", false)
				player:SetAttribute("StolenSecondUntil", 0)
				character:SetAttribute("StolenSecondReplaying", true)
				remote:FireClient(player, "Replay", record.id)
				core.ScreenEffect(
					"StolenSecondRelease",
					{ Origin = root.Position, Destination = record.previewFrame.Position },
					player
				)
				drain.Enabled = false
				flourish(root.Position, GOLD, 22)
				local top = cast:Add(Instance.new("Attachment"))
				top.Position = Vector3.new(0, 1.6, 0)
				top.Parent = root
				local bottom = cast:Add(Instance.new("Attachment"))
				bottom.Position = Vector3.new(0, -1.6, 0)
				bottom.Parent = root
				local trail = cast:Add(Instance.new("Trail"))
				trail.Name = "StolenSecondReplayTrail"
				trail.Attachment0 = top
				trail.Attachment1 = bottom
				trail.Lifetime = 0.35
				trail.LightEmission = 1
				trail.FaceCamera = true
				trail.Color = ColorSequence.new(HOT, GOLD)
				trail.Transparency =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
				trail.WidthScale =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
				trail.Parent = root
			end
			local count = #record.samples
			if count == 0 then
				cast:Dispose()
				return false
			end
			local desired = math.clamp((now - replayBegan) / replay, 0, 1) * count
			local progress = record.replayProgress
			while progress < desired - 1e-5 do
				local index = math.floor(progress) + 1
				local finish = math.min(desired, index)
				local delta = record.samples[index] * (finish - progress)
				record.replayFrame = advance(record.replayFrame, delta)
				progress = finish
			end
			record.replayProgress = progress
			root.CFrame = record.replayFrame
			local fade = math.clamp((now - replayBegan) / replay, 0, 1)
			for _, ghost in ipairs(ghosts) do
				ghost.Part.CFrame = record.replayFrame * ghost.Offset
				ghost.Part.Transparency = 0.66 + 0.34 * fade
				ghost.Part.Color = HOT:Lerp(GOLD, fade)
			end
			for _, beam in ipairs(ribbons) do
				beam.Transparency = NumberSequence.new(0.34 + 0.66 * fade)
				beam.Color = ColorSequence.new(HOT:Lerp(GOLD, fade))
			end
			placeHand(TAU * (1 - 2 * fade))
			for _, mark in ipairs(ticks) do
				mark.Transparency = 0.12 + 0.88 * fade
			end
			dialDisc.Transparency = 0.9 + 0.1 * fade
			hand.Transparency = 0.1 + 0.9 * fade
			tail.Transparency = 0.3 + 0.7 * fade
			for _, diamond in ipairs(waypoints) do
				diamond.Transparency = 0.3 + 0.7 * fade
			end
			head.CFrame = CFrame.new(record.replayFrame.Position - Vector3.new(0, 1.7, 0))
			head.Transparency = 0.1 + 0.9 * fade
			if tether then
				tether.Transparency = NumberSequence.new(0.35 + 0.65 * fade)
			end
			if desired >= count then
				actor:SetAttribute("StolenSecondCompleted", (actor:GetAttribute("StolenSecondCompleted") or 0) + 1)
				flourish(record.replayFrame.Position, CYAN, 16)
				cast:Dispose()
				return false
			end
			return true
		end)
		return cast
	end

	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P2.5StolenSecond", function()
			core.Face(character)
			core.PoseAngles(
				{ RightShoulder = { 70, 0, -25 }, LeftShoulder = { 45, 0, 20 }, Waist = { -5, 0, 0 } },
				0.13
			)
			actor:SetAttribute("AttackState", "Stolen Second: recording movement")
			local cast = api.Begin(character)
			if not cast then
				return false
			end
			 
			 
			return core.WaitFor(0.18)
		end)
	end
 function api.CancelTarget(character)
  local record = api.LastRecord
  if record and record.character == character and not record.closed then record.cast:Dispose() end
 end
	function api.Dispose()
		if current then
			current:Dispose()
		end
	end
	return api
end
