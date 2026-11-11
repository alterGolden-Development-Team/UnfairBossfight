local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Effects = require(BossSystem.Combat.EffectService)
local Clones = require(BossSystem.Mechanics.Clones.CloneController)
local Registry = require(BossSystem.Combat.AttackRegistry)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Status = require(BossSystem.Combat.StatusEffectService)
local Players = game:GetService("Players")
local api = {}
local playerEffects = setmetatable({}, { __mode = "k" })
local playerOwners = setmetatable({}, { __mode = "k" })
local random = Random.new()
local GOLD = Color3.fromRGB(255, 207, 36)
local function alive(actor)
	if Observer.IsCharacter(actor) then
		return false
	end
	local h = actor and actor:FindFirstChildOfClass("Humanoid")
	return actor
		and actor.Parent
		and h
		and h.Health > 0
		and actor:FindFirstChild("HumanoidRootPart")
		and not actor:GetAttribute("EncounterEnded")
end
local function aliveTarget(actor, character)
	local player = character and Players:GetPlayerFromCharacter(character)
	return alive(actor)
		and math.floor(actor:GetAttribute("Phase") or 1) == 3
		and player
		and player.Character == character
		and alive(character)
		and not actor:GetAttribute("ExecutionLocked")
		and not actor:GetAttribute("PhaseTransitionInProgress")
end
local function validTarget(actor, character)
	return aliveTarget(actor, character)
		and not character:GetAttribute("MovementLocked")
		and not character:GetAttribute("Chained")
		and not character:GetAttribute("Downed")
end
local function send(kind, data, player)
	local remote = game.ReplicatedStorage.BossCombatEffects
	if player then
		remote:FireClient(player, kind, data)
	else
		remote:FireAllClients(kind, data)
	end
end
local function flash(actor, duration)
	local cast = Effects.NewCast(actor, "RealityFlash", duration or 0.5)
	local h = Instance.new("Highlight")
	h.Adornee = actor
	h.FillColor = GOLD
	h.OutlineColor = GOLD
	h.FillTransparency = 0.55
	h.OutlineTransparency = 0.2
	h.Parent = Runtime.Effects
	cast:Add(h)
	Effects:Create(h, TweenInfo.new(duration or 0.5), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	return cast
end
 
function api.Start(_)
	return nil
end
function api.Active(_)
	return nil
end
function api.TryLinkedSwap(_)
	return false
end
function api.Cancel(actor)
	local pending = {}
	for effect in pairs(playerEffects) do
		if effect.Owner == actor then
			table.insert(pending, effect)
		end
	end
	for _, effect in ipairs(pending) do
		effect:Dispose()
	end
end
local function playerEffect(actor, character, key, duration, onEnd, allowImmobile)
	if
		not (allowImmobile and aliveTarget(actor, character) or not allowImmobile and validTarget(actor, character))
		or Status.IsDebuffImmune(character)
	then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	if
		character:GetAttribute(key .. "Until")
		and character:GetAttribute(key .. "Until") > workspace:GetServerTimeNow()
	then
		return nil
	end
	local own = playerOwners[player]
	if not own then
		own = {}
		playerOwners[player] = own
	end
	if own[key] then
		own[key]:Dispose()
	end
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local cast = Effects.NewCast(actor, key, duration + 0.2)
	cast.Owner = actor
	playerEffects[cast] = true
	own[key] = cast
	character:SetAttribute(key .. "Until", workspace:GetServerTimeNow() + duration)
	player:SetAttribute(key .. "Until", workspace:GetServerTimeNow() + duration)
	cast.OnDispose = function()
		playerEffects[cast] = nil
		local owns = own[key] == cast
		if owns then
			own[key] = nil
			character:SetAttribute(key .. "Until", 0)
			player:SetAttribute(key .. "Until", 0)
		elseif player.Character ~= character then
			character:SetAttribute(key .. "Until", 0)
		end
		if onEnd then
			onEnd(player, character, owns)
		end
	end
	cast:Step(function()
		if
			not alive(actor)
			or not alive(character)
			or player.Character ~= character
			or player.Parent ~= Players
			or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
			or Status.IsDebuffImmune(character)
		then
			cast:Dispose()
			return false
		end
		return true
	end)
	return cast, player
end
function api.ClearCharacter(character)
 local player = Players:GetPlayerFromCharacter(character)
 local owned = player and playerOwners[player]
 if not owned then return end
 local pending = {}
 for _, cast in pairs(owned) do table.insert(pending, cast) end
 for _, cast in ipairs(pending) do cast:Dispose() end
end

function api.SealAbilities(actor, character)
	local visuals = {}
	local cast = playerEffect(actor, character, "AbilitiesSealed", Config.ThiefDuration, function(_, char)
		for part, alpha in pairs(visuals) do
			if part.Parent then
				part.Transparency = alpha
			end
		end
	end, true)
	if not cast then
		return false
	end
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			for _, part in ipairs(tool:GetDescendants()) do
				if part:IsA("BasePart") then
					visuals[part] = part.Transparency
					part.Transparency = 1
				end
			end
		end
	end
	local highlight = Instance.new("Highlight")
	highlight.Adornee = character
	highlight.FillColor = GOLD
	highlight.OutlineColor = Color3.fromRGB(90, 67, 16)
	highlight.FillTransparency = 0.8
	highlight.OutlineTransparency = 0.05
	highlight.Parent = Runtime.Effects
	cast:Add(highlight)
	send(
		"P3Thief",
		{ EndsAt = character:GetAttribute("AbilitiesSealedUntil") },
		Players:GetPlayerFromCharacter(character)
	)
	return true
end
function api.Illusion(actor, target)
	if not api.CanIllusion(actor, target) then
		return false
	end
	local core = Registry.For(actor, "P1CombatCore")
	local root = actor.HumanoidRootPart
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local revision = actor:GetAttribute("MovementRevision") or 0
	local duration = math.clamp(Config.IllusionDuration or 5, 3, 8)
	local entryDuration = math.clamp(Config.IllusionMirrorDashDuration or 0.55, 0.25, 0.9)
	local exitDuration = math.clamp(Config.IllusionMirrorExitDuration or 0.75, 0.3, 1.1)
	local cast = Effects.NewCast(actor, "IllusionMirrorPath", duration + entryDuration + exitDuration + 0.5)
	local hidden, outlines = {}, {}
	local outlineConnections, observedHighlights = {}, {}
	local visibilityToken = tostring(cast.realBorn)
	local function hideOutline(value)
		if cast.closed or not value.Parent or not value:IsA("Highlight") then
			return
		end
		 
		local target = value.Adornee or value.Parent
		if not target then
			return
		end
		if target ~= actor and not target:IsDescendantOf(actor) then
			return
		end
		if outlines[value] == nil then
			outlines[value] = value.Enabled
		end
		value:SetAttribute("IllusionOutlineToken", visibilityToken)
		value.Enabled = false
	end
	local function observeOutline(value)
		if cast.closed or not value:IsA("Highlight") then
			return
		end
		if observedHighlights[value] then
			hideOutline(value)
			return
		end
		observedHighlights[value] = true
		for _, property in ipairs({ "Enabled", "Adornee" }) do
			table.insert(
				outlineConnections,
				value:GetPropertyChangedSignal(property):Connect(function()
					hideOutline(value)
				end)
			)
		end
		hideOutline(value)
	end
	for _, container in ipairs({ actor, Runtime.Effects }) do
		table.insert(outlineConnections, container.DescendantAdded:Connect(observeOutline))
		for _, value in ipairs(container:GetDescendants()) do
			observeOutline(value)
		end
	end
	actor:SetAttribute("IllusionOutlineHidden", true)
	local function hide(entity)
		for _, part in ipairs(entity:GetDescendants()) do
			if part:IsA("BasePart") then
				hidden[part] = { Entity = entity, Alpha = part.Transparency }
				part:SetAttribute("IllusionDashVisibilityToken", visibilityToken)
				part.Transparency = 1
			end
		end
	end
	local function restore(entity)
		for part, state in pairs(hidden) do
			if not entity or state.Entity == entity then
				if part.Parent and part:GetAttribute("IllusionDashVisibilityToken") == visibilityToken then
					if part.Transparency == 1 then
						part.Transparency = state.Alpha
					end
					part:SetAttribute("IllusionDashVisibilityToken", nil)
				end
				hidden[part] = nil
			end
		end
	end
	cast.OnDispose = function()
		for _, connection in ipairs(outlineConnections) do
			connection:Disconnect()
		end
		table.clear(outlineConnections)
		table.clear(observedHighlights)
		restore()
		for value, enabled in pairs(outlines) do
			if value.Parent and value:GetAttribute("IllusionOutlineToken") == visibilityToken then
				if not value.Enabled then
					value.Enabled = enabled
				end
				value:SetAttribute("IllusionOutlineToken", nil)
			end
		end
		if actor.Parent then
			actor:SetAttribute("IllusionOutlineHidden", false)
		end
	end
	local function valid()
		return cast:Alive()
			and alive(actor)
			and math.floor(actor:GetAttribute("Phase") or 1) == 3
			and (actor:GetAttribute("PhaseGeneration") or 0) == generation
			and (actor:GetAttribute("MovementRevision") or 0) == revision
			and not actor:GetAttribute("PhaseTransitionInProgress")
	end
	cast:Step(function()
		if not valid() then
			cast:Dispose()
			return false
		end
		return true
	end)
	local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
	local WHITE = Color3.fromRGB(255, 246, 178)
	 
	local function ring(position, color, fromSize, toSize, time, thickness, startTransparency, normal)
		local part = Effects.AcquirePart()
		part.Name = "IllusionRing"
		part.Shape = Enum.PartType.Cylinder
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Transparency = startTransparency or 0.25
		part.Size = Vector3.new(thickness, fromSize, fromSize)
		if normal then
			part.CFrame = CFrame.lookAt(position, position + normal) * CFrame.Angles(0, math.rad(90), 0)
		else
			part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
		end
		part.Parent = Runtime.Effects
		cast:Add(part)
		Effects:Create(
			part,
			TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = Vector3.new(thickness, toSize, toSize), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(part, time + 0.1)
	end
	 
	local function burst(position, count)
		local part = Effects.AcquirePart()
		part.Name = "IllusionBurst"
		part.Shape = Enum.PartType.Block
		part.Size = Vector3.one * 0.1
		part.Transparency = 1
		part.CFrame = CFrame.new(position)
		part.Parent = Runtime.Effects
		cast:Add(part)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Texture = SPARKLE
		sparks.Rate = 0
		sparks.Color = ColorSequence.new(GOLD, WHITE)
		sparks.Lifetime = NumberRange.new(0.3, 0.7)
		sparks.Speed = NumberRange.new(8, 20)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Drag = 4
		sparks.LightEmission = 0.7
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
		sparks.Parent = part
		sparks:Emit(count)
		Effects.ReleaseAfter(part, 1)
	end
	 
	 
	local function followTrail(entity, first, total)
		local anchor = Effects.AcquirePart()
		anchor.Name = "IllusionYellowDashBeam"
		anchor.Size = Vector3.one * 0.1
		anchor.CFrame = CFrame.new(first)
		anchor.Transparency = 1
		anchor.Parent = Runtime.Effects
		cast:Add(anchor)
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Parent = anchor
		b.Parent = anchor
		a.WorldPosition = first
		b.WorldPosition = first
		local beams = {}
		for index, width in ipairs({ 5.5, 3.8, 2.2, 1.15, 0.45 }) do
			local beam = Instance.new("Beam")
			beam.Name = "IllusionLayeredYellowTrail"
			beam.Attachment0 = a
			beam.Attachment1 = b
			beam.FaceCamera = true
			beam.Width0 = width
			beam.Width1 = width * 0.55
			beam.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 249, 194))
			beam.LightEmission = 0.45
			beam.Transparency =
				NumberSequence.new(index == 1 and 0.65 or index == 2 and 0.3 or index == 3 and 0.15 or 0.08)
			beam.Segments = 14
			beam.Parent = anchor
			beams[index] = { Beam = beam, Width = width }
		end
		local motes = Instance.new("ParticleEmitter")
		motes.Name = "IllusionMirrorMotes"
		motes.Texture = SPARKLE
		motes.Rate = 0
		motes.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 246, 178))
		motes.Lifetime = NumberRange.new(0.2, 0.5)
		motes.Speed = NumberRange.new(3, 10)
		motes.SpreadAngle = Vector2.new(180, 180)
		motes.LightEmission = 0.4
		motes.Size = NumberSequence.new(0.3)
		motes.Parent = anchor
		motes:Emit(20)
		local began = cast:Now()
		cast:Step(function(_, now)
			local elapsed = now - began
			if entity.Root.Parent then
				b.WorldPosition = entity.Root.Position
			end
			 
			local fade = 1 - math.clamp((elapsed - (total - 0.25)) / 0.25, 0, 1)
			for _, item in ipairs(beams) do
				item.Beam.Width0 = item.Width * fade
				item.Beam.Width1 = item.Width * 0.55 * fade
			end
			if elapsed >= total then
				Effects.Release(anchor)
				return false
			end
			return true
		end)
	end
	local function portal(frame)
		local panel = Effects.AcquirePart()
		panel.Name = "IllusionGoldenMirror"
		panel.Size = Vector3.new(0.4, 13, 0.12)
		panel.Material = Enum.Material.Glass
		panel.Color = GOLD
		panel.Transparency = 0.72
		panel.CFrame = frame + Vector3.new(0, 2, 0)
		panel.Parent = Runtime.Effects
		cast:Add(panel)
		 
		Effects:Create(
			panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = Vector3.new(9, 13, 0.12) }
		):Play()
		local innerGlow = Effects.AcquirePart()
		innerGlow.Name = "IllusionPortalInnerGlow"
		innerGlow.Shape = Enum.PartType.Ball
		innerGlow.Color = GOLD
		innerGlow.Transparency = 0.55
		innerGlow.Material = Enum.Material.Neon
		innerGlow.Size = Vector3.new(6, 9, 6)
		innerGlow.CFrame = panel.CFrame
		innerGlow.Parent = Runtime.Effects
		cast:Add(innerGlow)
		local swirl = Instance.new("ParticleEmitter")
		swirl.Name = "IllusionPortalSwirl"
		swirl.Texture = SPARKLE
		swirl.Rate = 0
		swirl.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 246, 178))
		swirl.Lifetime = NumberRange.new(0.3, 0.7)
		swirl.Speed = NumberRange.new(2, 5)
		swirl.SpreadAngle = Vector2.new(45, 45)
		swirl.LightEmission = 0.5
		swirl.Size = NumberSequence.new(0.25)
		swirl.Parent = innerGlow
		swirl:Emit(30)
		Effects:Create(
			innerGlow,
			TweenInfo.new(entryDuration + exitDuration),
			{ Transparency = 1, Size = Vector3.new(10, 14, 10) }
		):Play()
		 
		local glowLight = Instance.new("PointLight")
		glowLight.Color = GOLD
		glowLight.Range = 30
		glowLight.Brightness = 8
		glowLight.Parent = innerGlow
		Effects:Create(glowLight, TweenInfo.new(entryDuration + exitDuration + 0.5), { Brightness = 0, Range = 6 })
			:Play()
		 
		ring(frame.Position + Vector3.new(0, 0.3, 0), GOLD, 4, 34, 0.6, 0.3, 0.3)
		ring(frame.Position + Vector3.new(0, 2, 0), WHITE, 5, 26, 0.5, 0.3, 0.2, frame.LookVector)
		burst(frame.Position + Vector3.new(0, 2, 0), 20)
		local pieces = {}
		local lifetime = entryDuration + exitDuration + 0.9
		local at = cast:Now()
		for layer = 1, 2 do
			for index = 1, 24 do
				local piece = Effects.AcquirePart()
				piece.Name = "IllusionPortalRotatingRim"
				piece.Color = layer == 1 and GOLD or Color3.fromRGB(255, 246, 178)
				piece.Transparency = layer == 1 and 0.2 or 0.62
				piece.Size = Vector3.new(0.15, 1.4, layer == 1 and 0.15 or 0.07)
				piece.Parent = Runtime.Effects
				cast:Add(piece)
				pieces[#pieces + 1] = {
					Part = piece,
					Lease = Effects.LeaseId(piece),
					Layer = layer,
					Angle = (index - 1) * math.pi * 2 / 24,
				}
			end
		end
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.LightInfluence = 0.5
			gui.Parent = panel
			local field = Instance.new("Frame")
			field.Size = UDim2.fromScale(1, 1)
			field.BackgroundTransparency = 0.84
			field.BackgroundColor3 = Color3.fromRGB(252, 223, 95)
			field.BorderSizePixel = 0
			field.Parent = gui
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 45
			gradient.Color = ColorSequence.new(Color3.fromRGB(255, 250, 201), Color3.fromRGB(87, 59, 7))
			gradient.Parent = field
			local border = Instance.new("UIStroke")
			border.Color = Color3.fromRGB(255, 246, 178)
			border.Thickness = 2
			border.Parent = field
		end
		cast:Step(function(_, now)
			if not valid() then
				return false
			end
			local t = now - at
			for _, item in ipairs(pieces) do
				if item.Part.Parent and Effects.LeaseId(item.Part) == item.Lease then
					local angle = item.Angle + t * (item.Layer == 1 and 1.6 or -1.2)
					local x = math.cos(angle) * (item.Layer == 1 and 4.9 or 5.35)
					local y = math.sin(angle) * (item.Layer == 1 and 6.9 or 7.35)
					item.Part.CFrame = panel.CFrame * CFrame.new(x, y, 0.05) * CFrame.Angles(0, 0, angle)
				end
			end
			return t < lifetime
		end)
		 
		cast:Schedule(lifetime - 0.3, function()
			if panel.Parent then
				Effects:Create(
					panel,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Transparency = 1, Size = Vector3.new(0.4, 13, 0.12) }
				):Play()
			end
		end)
		Effects.ReleaseAfter(panel, lifetime)
		for _, item in ipairs(pieces) do
			Effects.ReleaseAfter(item.Part, lifetime)
		end
		return panel
	end
	local function move(entities, seconds)
		local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
		local began = Time.ActionNow(actor)
		repeat
			if not valid() then
				cast:Dispose()
				return false
			end
			local globalElapsed = Time.ActionNow(actor) - began
			local globalAlpha = math.clamp(globalElapsed / seconds, 0, 1)
			for _, entity in ipairs(entities) do
				if entity.Root.Parent then
					local delay = entity.Delay or 0
					local localAlpha = math.clamp((globalElapsed - delay) / math.max(seconds - delay, 0.01), 0, 1)
					local eased = entity.Ease and 0.5 - 0.5 * math.cos(localAlpha * math.pi) or localAlpha
					entity.Root.CFrame = entity.First:Lerp(entity.Last, eased)
				end
			end
			if globalAlpha >= 1 then
				return true
			end
			game:GetService("RunService").Heartbeat:Wait()
		until false
	end
	local origin = root.CFrame
	local delta = target.HumanoidRootPart.Position - root.Position
	local direction = Vector3.new(delta.X, 0, delta.Z)
	direction = direction.Magnitude > 0.1 and direction.Unit or root.CFrame.LookVector
	local mirrorGround = Placement.GroundPoint(
		origin.Position + direction * math.clamp(Config.IllusionMirrorDashDistance or 40, 24, 60),
		{ Margin = 32, Clamp = true }
	)
	if not mirrorGround then
		cast:Dispose()
		return false
	end
	local mirror = Placement.Validate(actor, CFrame.lookAt(mirrorGround, mirrorGround + direction), { Margin = 6 })
	if not mirror then
		cast:Dispose()
		return false
	end
	local exits = {}
	for index, angle in ipairs({ -math.pi * 0.42, 0, math.pi * 0.42 }) do
		local heading = CFrame.Angles(0, angle, 0):VectorToWorldSpace(direction)
		local p = Placement.GroundPoint(
			mirror.Position + heading * math.clamp(Config.IllusionMirrorExitDistance or 44, 28, 64),
			{ Margin = 6, Clamp = true }
		)
		exits[index] = p and Placement.Validate(actor, CFrame.lookAt(p, p + heading), { Margin = 6 })
		if not exits[index] then
			cast:Dispose()
			return false
		end
	end
	portal(mirror)
	followTrail({ Root = root }, origin.Position, entryDuration)
	 
	ring(origin.Position + Vector3.new(0, 0.3, 0), GOLD, 3, 24, 0.5, 0.3, 0.3)
	burst(origin.Position + Vector3.new(0, 3, 0), 18)
	hide(actor)
	if not move({ { Root = root, First = origin, Last = mirror } }, entryDuration) then
		return false
	end
	restore(actor)
	 
	ring(mirror.Position + Vector3.new(0, 2, 0), WHITE, 4, 26, 0.45, 0.3, 0.2, direction)
	burst(mirror.Position + Vector3.new(0, 2, 0), 22)
	local realIndex = random:NextInteger(1, 3)
	local copies = {}
	local staggerDelay = math.clamp((exitDuration or 0.75) * 0.22, 0.12, 0.3)
	local entities =
		{ { Root = root, First = mirror, Last = exits[realIndex], Delay = realIndex * staggerDelay, Ease = true } }
	for index = 1, 3 do
		if index ~= realIndex then
			local cloneDelay = index * staggerDelay
			local copy = Clones.Create(actor, {
				Mode = "Illusion",
				MirrorOwner = true,
				MirrorDelay = exitDuration + 0.05 + cloneDelay,
				Frame = mirror,
				Duration = duration + exitDuration + cloneDelay,
				MaterializeDuration = 0,
			})
			if not copy then
				Clones.CancelMode(actor, "Illusion", "mirror incomplete")
				cast:Dispose()
				return false
			end
			table.insert(copies, { Handle = copy, Exit = exits[index] })
			table.insert(entities, {
				Root = copy.Actor.HumanoidRootPart,
				First = mirror,
				Last = exits[index],
				Delay = cloneDelay,
				Ease = true,
			})
			Clones.IllusionCardRing(actor, copy.Actor, 0.35)
		end
	end
	Clones.IllusionCardRing(actor, actor, 0.35)
	 
	ring(mirror.Position + Vector3.new(0, 2, 0), GOLD, 4, 30, 0.5, 0.3, 0.2, direction)
	hide(actor)
	for _, copy in ipairs(copies) do
		hide(copy.Handle.Actor)
	end
	local maxDelay = 0
	for _, e in ipairs(entities) do
		maxDelay = math.max(maxDelay, e.Delay or 0)
	end
	 
	for _, entity in ipairs(entities) do
		followTrail(entity, mirror.Position, exitDuration + maxDelay)
	end
	if not move(entities, exitDuration + maxDelay) then
		Clones.CancelMode(actor, "Illusion", "mirror dash cancelled")
		return false
	end
	restore()
	 
	for index = 1, 3 do
		local landing = exits[index].Position
		ring(landing + Vector3.new(0, 0.3, 0), GOLD, 3, 22, 0.5, 0.3, 0.3)
		burst(landing + Vector3.new(0, 3, 0), 14)
	end
	for _, copy in ipairs(copies) do
		copy.Handle:SetMirrorOffset(copy.Exit.Position - exits[realIndex].Position)
	end
	actor:SetAttribute("IllusionUntil", workspace:GetServerTimeNow() + duration)
	actor:SetAttribute("LastIllusionCount", #copies)
	actor:SetAttribute("IllusionRealExit", realIndex)
	return true
end
function api.ControlDistortion(actor, character)
	local duration = math.clamp(Config.ControlDistortionDuration or 5, 1, 8)
	local cast, player = playerEffect(actor, character, "ControlDistortion", duration, function(p, char, owns)
		if owns or p.Character ~= char then
			char:SetAttribute("ControlDistortionStartedAt", nil)
			char:SetAttribute("ControlDistortionSeed", nil)
			char:SetAttribute("ControlDistortionMaxRotation", nil)
		end
		if owns then
			p:SetAttribute("ControlDistortionStartedAt", nil)
			p:SetAttribute("ControlDistortionSeed", nil)
			p:SetAttribute("ControlDistortionMaxRotation", nil)
		end
	end, true)
	if not cast then
		return false
	end
	local started = workspace:GetServerTimeNow()
	local seed = random:NextNumber(0, math.pi * 2)
	local rotation = math.clamp(Config.ControlDistortionMaxRotationDegrees or 55, 10, 55)
	for _, value in ipairs({ character, player }) do
		value:SetAttribute("ControlDistortionStartedAt", started)
		value:SetAttribute("ControlDistortionSeed", seed)
		value:SetAttribute("ControlDistortionMaxRotation", rotation)
	end
	flash(character, 0.35)
	send(
		"P3ControlDistortion",
		{ EndsAt = character:GetAttribute("ControlDistortionUntil"), MaxRotation = rotation },
		player
	)
	return true
end
function api.CanIllusion(actor, target)
	return math.floor(actor:GetAttribute("Phase") or 1) == 3
		and validTarget(actor, target)
		and Clones.Count(actor, "Illusion") == 0
end
api.AliveTarget = aliveTarget
api.ValidTarget = validTarget
return api
