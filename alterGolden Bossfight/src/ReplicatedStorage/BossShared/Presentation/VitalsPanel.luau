--!nonstrict
-- The player's HP and stamina panel (StarterGui.PlayerVitalsHUD.Panel), built in code for places whose file does not carry it:
-- every bossfight map other than the Golden Encounter (UnfairShared/BossKit). Same names as the Golden Encounter's panel, so
-- PlayerVitalsAndDash drives it unchanged: Panel.Health / Panel.Stamina, each with Title, Value, Track.Fill (UIGradient), Underline.
local api = {}

local function make(className, props, parent)
	local i = Instance.new(className)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function row(panel, name, y, title, colors)
	local frame = make("Frame", { Name = name, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, panel)
	local font = Font.fromEnum(Enum.Font.Garamond)
	make("TextLabel", { Name = "Title", Size = UDim2.new(0.5, 0, 0, 22), BackgroundTransparency = 1, FontFace = font, TextSize = 21, Text = title,
		TextColor3 = Color3.fromRGB(245, 235, 210), TextStrokeTransparency = 0.4, TextXAlignment = Enum.TextXAlignment.Left }, frame)
	make("TextLabel", { Name = "Value", Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.5, 0, 0, 22), BackgroundTransparency = 1, FontFace = font, TextSize = 19,
		Text = "100 / 100", TextColor3 = Color3.fromRGB(245, 235, 210), TextStrokeTransparency = 0.4, TextXAlignment = Enum.TextXAlignment.Right }, frame)
	local track = make("Frame", { Name = "Track", Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 13), BackgroundColor3 = Color3.fromRGB(18, 16, 14), BackgroundTransparency = 0.15, BorderSizePixel = 0 }, frame)
	make("UIStroke", { Color = Color3.fromRGB(139, 115, 54), Transparency = 0.3 }, track)
	local fill = make("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
	make("UIGradient", { Color = colors }, fill)
	make("Frame", { Name = "Underline", Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.fromRGB(139, 115, 54), BackgroundTransparency = 0.6, BorderSizePixel = 0 }, frame)
	return frame
end

function api.Build(gui)
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	local panel = make("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0.035, 0, 1, -28), Size = UDim2.new(0.3, 0, 0, 86), BackgroundTransparency = 1 }, gui)
	make("UISizeConstraint", { MinSize = Vector2.new(220, 86), MaxSize = Vector2.new(430, 86) }, panel)
	row(panel, "Health", 0, "Health", ColorSequence.new(Color3.fromRGB(63, 173, 61), Color3.fromRGB(154, 241, 98)))
	row(panel, "Stamina", 44, "Stamina", ColorSequence.new(Color3.fromRGB(70, 150, 230), Color3.fromRGB(140, 210, 255)))
	return panel
end

return api
