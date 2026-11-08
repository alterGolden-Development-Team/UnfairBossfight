

local Cards = {}

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end

local IVORY = Color3.fromRGB(252, 247, 232)
local INK = Color3.fromRGB(26, 20, 12)

 
local function drawFront(gui, rank, symbol, color, gold)
	local page = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = IVORY, BorderSizePixel = 0 }, gui)
	make("UIStroke", { Color = gold, Thickness = 10, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, page)
	local inner = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.86),
		BackgroundTransparency = 1 }, page)
	make("UIStroke", { Color = gold, Thickness = 3, Transparency = 0.25 }, inner)
	local function index(anchor, position, rotation)
		local box = make("Frame", { AnchorPoint = anchor, Position = position, Size = UDim2.fromScale(0.2, 0.24), BackgroundTransparency = 1, Rotation = rotation }, page)
		make("TextLabel", { Size = UDim2.fromScale(1, 0.55), BackgroundTransparency = 1, Font = Enum.Font.Garamond, TextScaled = true,
			Text = rank, TextColor3 = INK }, box)
		make("TextLabel", { Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.45), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
			TextScaled = true, Text = symbol, TextColor3 = color:Lerp(INK, 0.15) }, box)
	end
	index(Vector2.new(0, 0), UDim2.fromScale(0.03, 0.02), 0)
	index(Vector2.new(1, 1), UDim2.fromScale(0.97, 0.98), 180)
	make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.85, 0.6),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, Text = symbol, TextColor3 = color, TextTransparency = 0.65 }, page)
	local glyph = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.8, 0.56),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, Text = symbol, TextColor3 = color:Lerp(INK, 0.1) }, page)
	make("UIStroke", { Color = INK, Thickness = 4 }, glyph)
	 
	if rank == "J" or rank == "Q" or rank == "K" or rank == "A" or rank == "10" then
		make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.5, 0.14),
			BackgroundTransparency = 1, Font = Enum.Font.Garamond, TextScaled = true, Text = rank, TextColor3 = gold:Lerp(INK, 0.35) }, page)
	end
	return page
end

 
local function drawBack(gui, gold)
	local page = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BorderSizePixel = 0, ClipsDescendants = true }, gui)
	make("UIStroke", { Color = gold, Thickness = 10, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, page)
	for i = -4, 4 do
		for _, rotation in ipairs({ 45, -45 }) do
			make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + i * 0.16, 0.5), Size = UDim2.new(0, 3, 1.6, 0),
				Rotation = rotation, BackgroundColor3 = gold, BackgroundTransparency = 0.55, BorderSizePixel = 0 }, page)
		end
	end
	local crest = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.42, 0.3),
		BackgroundColor3 = INK, Rotation = 0, BorderSizePixel = 0 }, page)
	make("UIStroke", { Color = gold, Thickness = 6 }, crest)
	make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, crest)
	make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true,
		Text = "♠", TextColor3 = gold }, crest)
	return page
end

function Cards.Build(options)
	local Style = options.Style
	local gold = Style.Gold
	local height = options.Height or 1
	local width = height * 0.7
	local thickness = math.max(height * 0.02, 0.04)
	local symbol, color = options.Symbol or "♠", options.Color or gold
	local anchored = options.Anchored ~= false

	local model = make("Model", { Name = options.Name or ("Card" .. (options.Rank or "")) })
	local root = make("Part", { Name = "CardRoot", Size = Vector3.one * 0.1, Transparency = 1, Anchored = anchored, Massless = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }, model)
	model.PrimaryPart = root
	if options.Cast then options.Cast:Add(model) end

	local parts = {}
	local function add(part, alpha)
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = false, false, false, false
		part.Massless, part.CastShadow = true, false
		make("Weld", { Part0 = root, Part1 = part, C0 = part.CFrame }, part)
		part.Parent = model
		table.insert(parts, { Part = part, Alpha = alpha or 0 })
		return part
	end
	local body = add(make("Part", { Name = "Face", Size = Vector3.new(width, height, thickness), CFrame = CFrame.identity,
		Color = IVORY, Material = Enum.Material.SmoothPlastic }))
	 
	local rim = math.max(height * 0.025, 0.03)
	local edges = {}
	for _, spec in ipairs({
		{ Vector3.new(width + rim, rim, thickness * 1.6), CFrame.new(0, height / 2, 0) },
		{ Vector3.new(width + rim, rim, thickness * 1.6), CFrame.new(0, -height / 2, 0) },
		{ Vector3.new(rim, height + rim, thickness * 1.6), CFrame.new(width / 2, 0, 0) },
		{ Vector3.new(rim, height + rim, thickness * 1.6), CFrame.new(-width / 2, 0, 0) },
	}) do
		add(make("Part", { Name = "Rim", Size = spec[1], CFrame = spec[2], Color = Color3.fromRGB(224, 170, 40), Material = Enum.Material.Metal }))
		local glow = add(make("Part", { Name = "EdgeGlow", Size = spec[1] * Vector3.new(1.02, 1.02, 0.5) + Vector3.new(rim, rim, 0) * 0.6,
			CFrame = spec[2], Color = color:Lerp(Style.White, 0.3), Material = Enum.Material.Neon }), 1)
		table.insert(edges, glow)
	end

	local pixels = options.Pixels or (height >= 6 and 512 or 256)
	local front = make("SurfaceGui", { Name = "Front", Face = Enum.NormalId.Front, LightInfluence = options.Lit and 1 or 0.15,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, CanvasSize = Vector2.new(pixels * 0.7, pixels), MaxDistance = 600 }, body)
	drawFront(front, options.Rank or "A", symbol, color, gold)
	local back = make("SurfaceGui", { Name = "Back", Face = Enum.NormalId.Back, LightInfluence = options.Lit and 1 or 0.15,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, CanvasSize = Vector2.new(pixels * 0.7, pixels), MaxDistance = 600 }, body)
	drawBack(back, gold)

	 
	if height < 3 then
		local pip = height * 0.2
		for _, z in ipairs({ -1, 1 }) do
			add(make("Part", { Name = "Pip", Size = Vector3.new(pip, pip, thickness * 0.6),
				CFrame = CFrame.new(0, 0, z * thickness * 0.55) * CFrame.Angles(0, 0, math.pi / 4), Color = color, Material = Enum.Material.Neon }))
		end
	end

	local light
	if options.Light then
		light = make("PointLight", { Color = color, Brightness = 0, Range = height * 1.3, Shadows = false }, body)
	end

	local card = { Model = model, Root = root, Body = body, Height = height, Width = width, Rank = options.Rank, Symbol = symbol, Color = color }
	local fade, glow = 0, 0
	local function apply()
		for _, entry in ipairs(parts) do
			if entry.Alpha < 1 then
				entry.Part.Transparency = entry.Alpha + (1 - entry.Alpha) * fade
			end
		end
		for _, edge in ipairs(edges) do
			edge.Transparency = 1 - (1 - fade) * glow * 0.9
		end
		front.Enabled = fade < 0.85
		back.Enabled = fade < 0.85
		if light then light.Brightness = (1 - fade) * glow * 4 end
	end
	function card:SetFade(value)
		value = math.clamp(value, 0, 1)
		if math.abs(value - fade) < 0.01 and value ~= 0 and value ~= 1 then return end
		fade = value
		apply()
	end
	function card:SetGlow(value)
		value = math.clamp(value, 0, 1)
		if math.abs(value - glow) < 0.02 and value ~= 0 and value ~= 1 then return end
		glow = value
		apply()
	end
	function card:SetColor(newColor)
		card.Color = newColor
		for _, edge in ipairs(edges) do edge.Color = newColor:Lerp(Style.White, 0.3) end
		if light then light.Color = newColor end
	end
	apply()
	model.Parent = options.Parent or workspace
	return card
end

 
 
local HOLD = CFrame.new(-0.085, -0.212, -0.188) * CFrame.fromEulerAnglesXYZ(math.rad(-71.9), math.rad(-30.5), math.rad(80.6))
function Cards.Fan(options)
	local Style, actor = options.Style, options.Actor
	local ranks = options.Ranks or { "10", "J", "Q", "K", "A" }
	local suit = Style.Suits[options.Suit or "Spade"] or Style.Suits.Spade
	local fan = { Cards = {} }
	local rig = actor:IsA("Model") and actor or actor.Parent
	local hand = rig and (rig:FindFirstChild("LeftHand") or rig:FindFirstChild("Left Arm"))
	local spread = math.rad(options.Spread or 14)
	local size = options.Height or 1.0
	for index, rank in ipairs(ranks) do
		local card = Cards.Build({ Rank = rank, Symbol = suit.Symbol, Color = suit.Color, Height = size, Style = Style, Cast = options.Cast,
			Anchored = false, Name = "FanCard" .. rank, Pixels = 192, Parent = options.Parent })
		card.Model.Parent = nil
		fan.Cards[index] = card
	end
	local welds = {}
	local fadeFrom, fadeTo, fadeStart, fadeLength, fade = 1, 1, 0, 0, 1
	function fan:Attach()
		if not hand then return false end
		local count = #fan.Cards
		for index, card in ipairs(fan.Cards) do
			local angle = (index - (count + 1) / 2) * spread
			 
			local offset = HOLD * CFrame.Angles(0, 0, -angle) * CFrame.new(0, card.Height * 0.42, -index * 0.012)
			card.Root.Anchored = false
			welds[index] = make("Weld", { Name = "TrueIllusionFanWeld", Part0 = hand, Part1 = card.Root, C0 = offset }, card.Root)
			card.Model.Parent = options.Parent or workspace
		end
		return true
	end
	function fan:Show(seconds)
		fadeFrom, fadeTo, fadeStart, fadeLength = fade, 0, os.clock(), math.max(seconds or 0.3, 0.01)
	end
	function fan:Hide(seconds)
		fadeFrom, fadeTo, fadeStart, fadeLength = fade, 1, os.clock(), math.max(seconds or 0.2, 0.01)
	end
	function fan:Step()
		if fadeLength <= 0 then return end
		local a = math.clamp((os.clock() - fadeStart) / fadeLength, 0, 1)
		fade = fadeFrom + (fadeTo - fadeFrom) * a
		for _, card in ipairs(fan.Cards) do card:SetFade(fade) end
		if a >= 1 then fadeLength = 0 end
	end
	function fan:WorldFrames()
		local frames = {}
		for index, card in ipairs(fan.Cards) do frames[index] = card.Root.CFrame end
		return frames
	end
	for _, card in ipairs(fan.Cards) do card:SetFade(1) end
	return fan
end

return table.freeze(Cards)
