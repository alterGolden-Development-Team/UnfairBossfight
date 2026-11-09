

local Launcher = {}

local TAU = math.pi * 2
local function smooth(a) return a * a * (3 - 2 * a) end

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end

function Launcher.Build(ctx)
	local Style, cast, actor, V = ctx.Style, ctx.Cast, ctx.Actor, ctx.V
	local GOLD, WHITE, SHADOW = Style.Gold, Style.White, Style.Shadow
	local LG = Style.Launcher or {}
	local BODY = LG.Body or Color3.fromRGB(32, 28, 30)  
	local DEEP = LG.Trim or Color3.fromRGB(224, 170, 40)  
	local EBONY = LG.Grip or Color3.fromRGB(28, 20, 10)
	local IVORY = Color3.fromRGB(250, 244, 226)
	local SCALE = LG.Scale or 0.92

	local model = make("Model", { Name = "TrueIllusionRoyalFlush" })
	local root = make("Part", {
		Name = "GunRoot", Size = Vector3.one * 0.2, Transparency = 1, Anchored = false, Massless = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	}, model)
	model.PrimaryPart = root
	cast:Add(model)

	local entries = {}  
	local roles = { Suit = {}, Chamber = {} }
	local function add(part, alpha, role)
		part.Size = part.Size * SCALE
		part.CFrame = CFrame.new(part.CFrame.Position * SCALE) * part.CFrame.Rotation
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = false, false, false, false
		part.Massless, part.CastShadow = true, false
		make("Weld", { Part0 = root, Part1 = part, C0 = part.CFrame }, part)
		part.Parent = model
		table.insert(entries, { Part = part, Alpha = alpha or 0 })
		if role then table.insert(roles[role], part) end
		return part
	end
	local function block(name, size, frame, color, material, alpha, role)
		return add(make("Part", { Name = name, Size = size, CFrame = frame, Color = color, Material = material or Enum.Material.Metal }), alpha, role)
	end
	local function wedge(name, size, frame, color, material, alpha)
		return add(make("WedgePart", { Name = name, Size = size, CFrame = frame, Color = color, Material = material or Enum.Material.Metal }), alpha)
	end
	 
	local function tube(name, length, diameter, center, color, material, alpha, role)
		return add(make("Part", {
			Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter),
			CFrame = CFrame.new(center) * CFrame.Angles(0, math.pi / 2, 0), Color = color, Material = material or Enum.Material.Metal,
		}), alpha, role)
	end
	local function neon(name, size, frame, color, alpha, role)
		return block(name, size, frame, color, Enum.Material.Neon, alpha, role)
	end

	 
	local rake = CFrame.Angles(math.rad(-16), 0, 0)
	local gripFrame = CFrame.new(0, -0.18, 0.12) * rake
	block("Grip", Vector3.new(0.5, 1.45, 0.66), gripFrame, EBONY, Enum.Material.SmoothPlastic)
	for _, x in ipairs({ -0.27, 0.27 }) do
		block("GripPlate", Vector3.new(0.05, 1.05, 0.48), gripFrame * CFrame.new(x, -0.05, 0), DEEP)
		neon("GripInlay", Vector3.new(0.06, 0.34, 0.06), gripFrame * CFrame.new(x * 1.04, 0.05, 0) * CFrame.Angles(0, 0, 0), GOLD)
		neon("GripInlay", Vector3.new(0.06, 0.06, 0.34), gripFrame * CFrame.new(x * 1.04, 0.05, 0), GOLD)
	end
	block("Pommel", Vector3.new(0.6, 0.18, 0.76), gripFrame * CFrame.new(0, -0.78, 0.02), DEEP)
	neon("PommelGem", Vector3.new(0.22, 0.12, 0.22), gripFrame * CFrame.new(0, -0.9, 0.02), GOLD)

	 
	block("Frame", Vector3.new(0.56, 0.62, 1.55), CFrame.new(0, 0.72, -0.12), BODY)
	block("FrameTop", Vector3.new(0.44, 0.16, 1.7), CFrame.new(0, 1.08, -0.18), DEEP)
	for _, x in ipairs({ -0.29, 0.29 }) do
		neon("Engraving", Vector3.new(0.03, 0.05, 1.25), CFrame.new(x, 0.86, -0.12), GOLD, 0.15)
		neon("Engraving", Vector3.new(0.03, 0.05, 0.9), CFrame.new(x, 0.56, -0.02), GOLD, 0.3)
	end
	 
	wedge("Hammer", Vector3.new(0.2, 0.42, 0.34), CFrame.new(0, 1.16, 0.7) * CFrame.Angles(0, math.pi, 0), DEEP)
	block("RearSight", Vector3.new(0.34, 0.14, 0.12), CFrame.new(0, 1.2, 0.5), DEEP)
	 
	local guardCenter = Vector3.new(0, 0.32, -0.42)
	local segments = 7
	for i = 0, segments - 1 do
		local a0 = math.pi * (0.05 + 0.9 * i / segments)
		local a1 = math.pi * (0.05 + 0.9 * (i + 1) / segments)
		local p0 = guardCenter + Vector3.new(0, -math.sin(a0) * 0.42, math.cos(a0) * 0.36)
		local p1 = guardCenter + Vector3.new(0, -math.sin(a1) * 0.42, math.cos(a1) * 0.36)
		block("TriggerGuard", Vector3.new(0.1, 0.1, (p1 - p0).Magnitude + 0.04), CFrame.lookAt((p0 + p1) / 2, p1), DEEP)
	end
	wedge("Trigger", Vector3.new(0.08, 0.32, 0.14), CFrame.new(0, 0.16, -0.36) * CFrame.Angles(math.rad(-12), 0, 0), DEEP)

	 
	local drumCenter = Vector3.new(0, 0.74, -1.1) * SCALE
	local drum = make("Part", {
		Name = "DrumRoot", Size = Vector3.one * 0.2, Transparency = 1, Anchored = false, Massless = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, CFrame = CFrame.new(drumCenter),
	}, model)
	local drumWeld = make("Weld", { Part0 = root, Part1 = drum, C0 = CFrame.new(drumCenter) }, drum)
	local function drumPart(part, alpha, role)
		part.Size = part.Size * SCALE
		part.CFrame = CFrame.new(part.CFrame.Position * SCALE) * part.CFrame.Rotation
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = false, false, false, false
		part.Massless, part.CastShadow = true, false
		make("Weld", { Part0 = drum, Part1 = part, C0 = CFrame.new(drumCenter):ToObjectSpace(part.CFrame) }, part)
		part.Parent = model
		table.insert(entries, { Part = part, Alpha = alpha or 0 })
		if role then table.insert(roles[role], part) end
		return part
	end
	local dc = drumCenter / SCALE
	drumPart(make("Part", { Name = "Drum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.86, 1.08, 1.08),
		CFrame = CFrame.new(dc) * CFrame.Angles(0, math.pi / 2, 0), Color = BODY, Material = Enum.Material.Metal }))
	for _, z in ipairs({ -0.44, 0.44 }) do
		drumPart(make("Part", { Name = "DrumBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.08, 1.16, 1.16),
			CFrame = CFrame.new(dc + Vector3.new(0, 0, z)) * CFrame.Angles(0, math.pi / 2, 0), Color = DEEP, Material = Enum.Material.Metal }))
	end
	local chambers = {}
	for index, name in ipairs(Style.Order) do
		local angle = (index - 1) / #Style.Order * TAU
		local offset = Vector3.new(math.sin(angle) * 0.34, math.cos(angle) * 0.34, -0.45)
		local chamber = drumPart(make("Part", { Name = "Chamber" .. name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.06, 0.26, 0.26),
			CFrame = CFrame.new(dc + offset) * CFrame.Angles(0, math.pi / 2, 0), Color = Style.Suits[name].Color, Material = Enum.Material.Neon }), 0.35)
		chambers[name] = { Part = chamber, Angle = angle }
		 
		local flute = angle + math.pi / #Style.Order
		drumPart(make("Part", { Name = "Flute", Size = Vector3.new(0.12, 0.12, 0.7),
			CFrame = CFrame.new(dc + Vector3.new(math.sin(flute) * 0.5, math.cos(flute) * 0.5, 0)), Color = DEEP, Material = Enum.Material.Metal }))
	end

	 
	local barrelY, barrelZ, barrelLength = 0.78, -2.45, 2.5
	tube("Barrel", barrelLength, 0.5, Vector3.new(0, barrelY, barrelZ), BODY)
	block("UnderLug", Vector3.new(0.34, 0.32, barrelLength - 0.2), CFrame.new(0, barrelY - 0.3, barrelZ + 0.05), DEEP)
	block("TopRib", Vector3.new(0.2, 0.12, barrelLength + 0.15), CFrame.new(0, barrelY + 0.32, barrelZ), DEEP)
	neon("RibLight", Vector3.new(0.07, 0.05, barrelLength - 0.2), CFrame.new(0, barrelY + 0.39, barrelZ), WHITE, 0.1, "Suit")
	for _, x in ipairs({ -0.29, 0.29 }) do
		neon("BarrelVein", Vector3.new(0.04, 0.06, barrelLength - 0.35), CFrame.new(x, barrelY, barrelZ), WHITE, 0.2, "Suit")
	end
	for i, z in ipairs({ -1.55, -2.35, -3.15 }) do
		tube("BarrelBand", 0.12, 0.64, Vector3.new(0, barrelY, z), DEEP)
	end
	block("FrontSight", Vector3.new(0.08, 0.2, 0.22), CFrame.new(0, barrelY + 0.44, barrelZ - barrelLength / 2 + 0.25), DEEP)

	 
	local muzzleZ = barrelZ - barrelLength / 2
	tube("MuzzleCrown", 0.3, 0.78, Vector3.new(0, barrelY, muzzleZ - 0.05), DEEP)
	local muzzleGlow = tube("MuzzleGlow", 0.04, 0.42, Vector3.new(0, barrelY, muzzleZ - 0.21), WHITE, Enum.Material.Neon, 0.05, "Suit")
	for _, side in ipairs({ -1, 1 }) do
		local fin = CFrame.new(side * 0.4, barrelY + 0.02, muzzleZ + 0.42) * CFrame.Angles(0, side * math.rad(22), side * math.rad(-10))
		block("CardFinBorder", Vector3.new(0.05, 0.74, 0.54), fin, DEEP)
		block("CardFin", Vector3.new(0.06, 0.64, 0.44), fin, IVORY, Enum.Material.SmoothPlastic)
		neon("CardFinPip", Vector3.new(0.07, 0.16, 0.16), fin * CFrame.Angles(math.pi / 4, 0, 0), WHITE, 0.1, "Suit")
	end

	 
	for i = 1, 4 do
		local name = Style.Order[i]
		local fan = CFrame.new(-0.36, 0.5, 0.25) * CFrame.Angles(math.rad(-20 + i * 12), 0, 0) * CFrame.new(0, 0.28, 0)
		block("HolsterCard", Vector3.new(0.04, 0.62, 0.44), fan * CFrame.new(-i * 0.012, 0, 0), IVORY, Enum.Material.SmoothPlastic)
		neon("HolsterPip", Vector3.new(0.045, 0.14, 0.14), fan * CFrame.new(-i * 0.012 - 0.01, 0.12, 0) * CFrame.Angles(math.pi / 4, 0, 0),
			Style.Suits[name].Color, 0.1)
	end

	 
	local muzzleAttachment = make("Attachment", { Name = "Muzzle", Position = Vector3.new(0, barrelY, muzzleZ - 0.3) * SCALE }, root)
	local light = make("PointLight", { Color = GOLD, Brightness = 1.2, Range = 9, Shadows = false }, muzzleGlow)
	 
	local orb = make("Part", { Name = "ChargeOrb", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.2, Transparency = 1, Color = WHITE,
		Material = Enum.Material.Neon, Anchored = false, Massless = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }, model)
	make("Weld", { Part0 = root, Part1 = orb, C0 = CFrame.new(muzzleAttachment.Position) }, orb)
	local chargeStart, chargeLength, chargeSize = 0, 0, 1
	local embers = make("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(WHITE, GOLD), LightEmission = 1,
		Rate = 6, Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(1, 3),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		EmissionDirection = Enum.NormalId.Front, SpreadAngle = Vector2.new(20, 20),
	}, muzzleAttachment)

	 
	local badge = make("BillboardGui", { Name = "SuitBadge", Size = UDim2.fromScale(3, 3), StudsOffsetWorldSpace = Vector3.new(0, 2.6, -1.2),
		AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 450 }, root)
	local glyphGlow = make("TextLabel", { Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.5, 1.5), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, Text = "♠",
		TextColor3 = GOLD, TextTransparency = 0.6 }, badge)
	local glyph = make("TextLabel", { Name = "Glyph", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, Text = "♠",
		TextColor3 = WHITE }, badge)
	make("UIStroke", { Color = SHADOW, Thickness = 2 }, glyph)
	local badgeScale = make("UIScale", { Scale = 1 }, glyph)

	model.Parent = ctx.Parent or workspace

	 
	local handle = { Model = model, Root = root, Energy = 0 }
	local hand, handWeld, floating
	local grip = CFrame.fromMatrix(Vector3.new(0, -0.05, 0.05), Vector3.xAxis, -Vector3.zAxis, Vector3.yAxis)  
	local drumAngle, drumGoal = 0, 0
	local recoil, recoilKick = 0, 0
	local twirlFrom, twirlLength = nil, 0
	local fade, fadeFrom, fadeTo, fadeStart, fadeLength = 0, 0, 0, 0, 0
	local suitColor = GOLD
	local function setTransparency(amount)
		for _, entry in ipairs(entries) do
			entry.Part.Transparency = entry.Alpha + (1 - entry.Alpha) * amount
		end
		badge.Enabled = amount < 0.6
		light.Enabled = amount < 0.6
		embers.Enabled = amount < 0.4
	end

	function handle:Attach()
		local rig = actor:IsA("Model") and actor or actor.Parent
		hand = rig and (rig:FindFirstChild("RightHand") or rig:FindFirstChild("Right Arm"))
		local attachment = hand and hand:FindFirstChild("RightGripAttachment")
		if hand then
			local base = attachment and CFrame.new(attachment.Position) or CFrame.new(0, -hand.Size.Y * 0.5, 0)
			handle.Base = base * grip
			handWeld = make("Weld", { Name = "TrueIllusionGunWeld", Part0 = hand, Part1 = root, C0 = handle.Base }, root)
			root.CFrame = hand.CFrame * handle.Base
		else
			floating = true
			root.Anchored = true
		end
	end

	function handle:SetSuit(spec)
		suitColor = spec.Color
		for _, part in ipairs(roles.Suit) do part.Color = spec.Color:Lerp(WHITE, 0.25) end
		for name, chamber in pairs(chambers) do
			local active = Style.Suits[name] and Style.Suits[name].Symbol == spec.Symbol
			chamber.Part.Transparency = active and 0 or 0.55
			if active then
				 
				local goal = chamber.Angle
				local delta = (goal - drumGoal + math.pi) % TAU - math.pi
				drumGoal += delta
			end
		end
		glyph.Text, glyphGlow.Text = spec.Symbol, spec.Symbol
		glyph.TextColor3 = spec.Color:Lerp(WHITE, 0.35)
		glyphGlow.TextColor3 = spec.Color
		light.Color = spec.Color
		badgeScale.Scale = 1.6
	end

	function handle:Recoil(strength)
		recoil = 1
		recoilKick = strength or 1
		drumGoal -= TAU / #Style.Order * 0.25  
	end

	function handle:Twirl(seconds)
		twirlFrom, twirlLength = os.clock(), math.max(seconds or 0.6, 0.1)
	end

	function handle:Reveal(seconds)
		fadeFrom, fadeTo, fadeStart, fadeLength = 1, 0, os.clock(), math.max(seconds or 0.4, 0.01)
		fade = 1
		setTransparency(1)
	end

	function handle:Dismiss(seconds)
		fadeFrom, fadeTo, fadeStart, fadeLength = fade, 1, os.clock(), math.max(seconds or 0.35, 0.01)
	end

	function handle:Charge(spec, windup)
		handle.Energy = 1
		chargeStart, chargeLength = os.clock(), math.max(windup or 0.3, 0.05)
		chargeSize = 0.9 + (spec.Radius or 3) * 0.1
		orb.Color = spec.Color:Lerp(WHITE, 0.35)
		if V and V.GunCharge then V.GunCharge(cast, handle:Muzzle(), spec, windup) end
	end
	function handle:Fired()
		chargeLength = 0
		orb.Transparency = 1
	end

	function handle:Muzzle()
		return muzzleAttachment.WorldPosition
	end
	function handle:Aim()
		return muzzleAttachment.WorldCFrame.LookVector
	end

	 
	function handle:Step(dt, followFrame)
		dt = math.min(dt or 1 / 60, 0.1)
		local now = os.clock()
		handle.Energy = math.max(0, handle.Energy - dt * 2.2)
		drumAngle += (drumGoal - drumAngle) * math.min(1, dt * 18)
		drumWeld.C0 = CFrame.new(drumCenter) * CFrame.Angles(0, 0, drumAngle)
		recoil = math.max(0, recoil - dt * 7)
		local kick = smooth(recoil) * recoilKick
		local twirl = 0
		if twirlFrom then
			local a = (now - twirlFrom) / twirlLength
			if a >= 1 then twirlFrom = nil else twirl = smooth(a) * TAU * 2 end
		end
		 
		local motion = CFrame.new(0, 0.05 * kick, 0.35 * kick) * CFrame.Angles(math.rad(22) * kick + twirl, 0, 0)
		if handWeld then
			handWeld.C0 = handle.Base * motion
		elseif floating and followFrame then
			root.CFrame = followFrame * motion
		end
		if fadeLength > 0 then
			local a = math.clamp((now - fadeStart) / fadeLength, 0, 1)
			local value = fadeFrom + (fadeTo - fadeFrom) * smooth(a)
			if math.abs(value - fade) > 0.02 or a >= 1 then
				fade = value
				setTransparency(fade)
			end
			if a >= 1 then fadeLength = 0 end
		end
		if chargeLength > 0 then
			local a = math.clamp((now - chargeStart) / chargeLength, 0, 1)
			orb.Size = Vector3.one * (0.2 + chargeSize * a ^ 1.3) * SCALE
			orb.Transparency = 0.3 - 0.25 * a
			if a >= 1 and now - chargeStart > chargeLength + 0.25 then handle:Fired() end
		end
		badgeScale.Scale += (1 - badgeScale.Scale) * math.min(1, dt * 10)
		light.Brightness = 1.2 + 4 * handle.Energy + 0.3 * math.sin(now * 6)
		light.Range = 9 + 8 * handle.Energy
	end

	setTransparency(0)
	return handle
end

return table.freeze(Launcher)
