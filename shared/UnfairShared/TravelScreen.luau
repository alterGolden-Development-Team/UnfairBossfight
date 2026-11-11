--!nonstrict
--[[
 TravelScreen - the screen you see while a portal takes you somewhere (instead of a plain black fade). Client only.
 Every destination has its own look: colours, lettering and a small moving motif.

   TravelScreen.Show(theme, seconds?, title?, subtitle?)   -- fades the card in (yields `seconds`)
   TravelScreen.Hide(seconds?)                             -- fades it out
   TravelScreen.ForTeleport(theme)                         -- a still copy for TeleportService:SetTeleportGui (place to place)
   TravelScreen.Arrive(seconds?)                           -- in the place you arrive in: shows the card you left with, then fades it

 Themes: Hub, Palace, Island, Forest, Stage, Shop, Tutorial, Glitch, Golden (the Golden Encounter itself).
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local TravelScreen = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local function seq(...)
	local points, args = {}, { ... }
	for i = 1, #args, 2 do
		table.insert(points, ColorSequenceKeypoint.new(args[i], args[i + 1]))
	end
	return ColorSequence.new(points)
end

-- title, subtitle, background gradient (top to bottom), title gradient, outline, fonts, motif
local THEMES = {
	Hub = { "The Sanctum", "where every road begins", seq(0, rgb(255, 196, 150), 0.55, rgb(196, 150, 200), 1, rgb(70, 64, 120)),
		seq(0, rgb(255, 255, 255), 1, rgb(255, 230, 196)), rgb(90, 60, 80), Enum.Font.Garamond, Enum.Font.GothamMedium, "Motes" },
	Palace = { "The Golden Palace", "the king's door stands open", seq(0, rgb(20, 14, 6), 0.6, rgb(54, 36, 10), 1, rgb(8, 6, 2)),
		seq(0, rgb(255, 248, 200), 0.45, rgb(255, 206, 84), 1, rgb(176, 104, 24)), rgb(58, 32, 6), Enum.Font.Bodoni, Enum.Font.Bodoni, "Rays" },
	Golden = { "The Golden Encounter", "alterGolden is waiting", seq(0, rgb(30, 20, 4), 0.5, rgb(96, 64, 12), 1, rgb(10, 6, 0)),
		seq(0, rgb(255, 250, 214), 0.5, rgb(255, 196, 60), 1, rgb(160, 92, 16)), rgb(50, 26, 0), Enum.Font.Bodoni, Enum.Font.Bodoni, "Rays" },
	Island = { "The Private Island", "the tide brings you in", seq(0, rgb(170, 236, 246), 0.5, rgb(40, 150, 190), 1, rgb(8, 44, 74)),
		seq(0, rgb(255, 255, 255), 0.45, rgb(170, 240, 250), 1, rgb(64, 190, 222)), rgb(12, 40, 64), Enum.Font.Fondamento, Enum.Font.SpecialElite, "Waves" },
	Forest = { "The Divided Wood", "one half white, one half black", nil,
		seq(0, rgb(255, 255, 255), 0.499, rgb(236, 236, 240), 0.5, rgb(26, 26, 30), 1, rgb(8, 8, 10)), rgb(128, 128, 134),
		Enum.Font.PermanentMarker, Enum.Font.Michroma, "Split" },
	Stage = { "The Training Hall", "watch closely", seq(0, rgb(40, 28, 22), 1, rgb(10, 8, 6)),
		seq(0, rgb(255, 244, 220), 1, rgb(220, 180, 130)), rgb(30, 20, 14), Enum.Font.Garamond, Enum.Font.GothamMedium, "Motes" },
	Shop = { "The Reliquary", "fair prices, no refunds", seq(0, rgb(70, 18, 26), 1, rgb(18, 6, 8)),
		seq(0, rgb(255, 240, 200), 1, rgb(230, 170, 80)), rgb(40, 10, 14), Enum.Font.Bodoni, Enum.Font.Garamond, "Motes" },
	Tutorial = { "Azusa's Training Grounds", "the blossoms are falling", seq(0, rgb(255, 196, 206), 0.5, rgb(190, 110, 170), 1, rgb(46, 26, 70)),
		seq(0, rgb(255, 255, 255), 1, rgb(255, 196, 220)), rgb(90, 30, 70), Enum.Font.Fondamento, Enum.Font.GothamMedium, "Petals" },
	Glitch = { "!A GL!TC3D PL@CE!", "y0u sh0uld n0t b3 h3r3", seq(0, rgb(0, 0, 0), 1, rgb(18, 18, 18)),
		seq(0, rgb(255, 255, 255), 1, rgb(200, 200, 200)), rgb(0, 0, 0), Enum.Font.Code, Enum.Font.Code, "Glitch" },
}
TravelScreen.Themes = THEMES

local function make(className, props, parent)
	local i = Instance.new(className)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

-- Builds the card (no animation). Returns the ScreenGui and a table of the parts the motif moves.
local function build(themeName, title, subtitle)
	local t = THEMES[themeName] or THEMES.Hub
	local gui = make("ScreenGui", { Name = "TravelScreen", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1000, Enabled = true })
	local root = make("CanvasGroup", { Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, GroupTransparency = 0 }, gui)
	local parts = { motif = t[9], items = {} }
	if t[9] == "Split" then
		root.BackgroundColor3 = rgb(246, 246, 248)
		local dark = make("Frame", { Name = "Dark", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = rgb(10, 10, 12), BorderSizePixel = 0 }, root)
		parts.cut = make("Frame", { Name = "Cut", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = rgb(140, 140, 146), BorderSizePixel = 0, Rotation = 8 }, root)
		parts.dark = dark
	else
		make("UIGradient", { Color = t[3], Rotation = 90 }, root)
	end
	-- the motif layer
	local layer = make("Frame", { Name = "Motif", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true }, root)
	local r = Random.new(7)
	if t[9] == "Rays" then
		for i = 1, 12 do
			local ray = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.new(0, 34, 1.4, 0), BackgroundColor3 = rgb(255, 206, 90), BackgroundTransparency = 0.82, BorderSizePixel = 0, Rotation = i * 30 }, layer)
			make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.2), NumberSequenceKeypoint.new(1, 0) }), Rotation = 90 }, ray)
			table.insert(parts.items, ray)
		end
	elseif t[9] == "Waves" then
		for i = 1, 7 do
			local wave = make("Frame", { Position = UDim2.new(-0.2, 0, 0.55 + i * 0.06, 0), Size = UDim2.new(1.4, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55 + i * 0.05, BorderSizePixel = 0 }, layer)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, wave)
			table.insert(parts.items, wave)
		end
	elseif t[9] == "Glitch" then
		for _ = 1, 22 do
			local bar = make("Frame", { Position = UDim2.fromScale(r:NextNumber(-0.2, 0.9), r:NextNumber(0, 1)), Size = UDim2.new(r:NextNumber(0.1, 0.6), 0, 0, r:NextInteger(2, 14)), BackgroundColor3 = r:NextNumber() > 0.5 and Color3.new(1, 1, 1) or rgb(90, 90, 90), BackgroundTransparency = r:NextNumber(0.2, 0.8), BorderSizePixel = 0 }, layer)
			table.insert(parts.items, bar)
		end
	else -- Motes and Petals: little lights drifting (up) or blossoms falling (down)
		for _ = 1, 26 do
			local size = r:NextInteger(4, 10)
			local dot = make("Frame", { Position = UDim2.fromScale(r:NextNumber(), r:NextNumber()), Size = UDim2.fromOffset(size, t[9] == "Petals" and size * 0.7 or size), BackgroundColor3 = t[9] == "Petals" and rgb(255, 200, 220) or rgb(255, 236, 200), BackgroundTransparency = r:NextNumber(0.1, 0.6), BorderSizePixel = 0, Rotation = r:NextNumber(0, 360) }, layer)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
			dot:SetAttribute("Speed", r:NextNumber(0.03, 0.09))
			table.insert(parts.items, dot)
		end
	end
	-- the title and the line under it
	local head = make("TextLabel", { Name = "Title", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.new(0.86, 0, 0.13, 0),
		BackgroundTransparency = 1, Font = t[6], TextScaled = true, Text = title or t[1], TextColor3 = Color3.new(1, 1, 1) }, root)
	make("UIGradient", { Color = t[4], Rotation = t[9] == "Split" and 0 or 90 }, head)
	make("UIStroke", { Color = t[5], Thickness = 2.5 }, head)
	make("UITextSizeConstraint", { MaxTextSize = 84 }, head)
	local line = make("Frame", { Name = "Rule", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.new(0.3, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, root)
	make("UIGradient", { Color = t[4], Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, line)
	local sub = make("TextLabel", { Name = "Subtitle", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.new(0.7, 0, 0.04, 0),
		BackgroundTransparency = 1, Font = t[7], TextScaled = true, Text = subtitle or t[2], TextColor3 = t[9] == "Split" and rgb(120, 120, 126) or Color3.new(1, 1, 1), TextTransparency = 0.15 }, root)
	make("UITextSizeConstraint", { MaxTextSize = 26 }, sub)
	parts.title, parts.sub, parts.text = head, sub, title or t[1]
	return gui, root, parts
end

local active -- { gui, root, parts, conn }

local function animate(state)
	local p = state.parts
	local started = os.clock()
	state.conn = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - started
		if p.motif == "Rays" then
			for i, ray in p.items do
				ray.Rotation = i * 30 + t * 6
			end
		elseif p.motif == "Waves" then
			for i, wave in p.items do
				wave.Position = UDim2.new(-0.2 + math.sin(t * 0.8 + i) * 0.08, 0, 0.55 + i * 0.06 + math.sin(t * 1.4 + i * 0.7) * 0.01, 0)
			end
		elseif p.motif == "Split" then
			p.cut.Size = UDim2.new(0, 3, math.clamp(t * 1.6, 0, 1.3), 0)
		elseif p.motif == "Glitch" then
			if math.random() < 0.5 then
				for _, bar in p.items do
					if math.random() < 0.3 then
						bar.Position = UDim2.fromScale(math.random() * 1.1 - 0.2, math.random())
					end
				end
				local chars = {}
				for c in p.text:gmatch(".") do
					table.insert(chars, math.random() < 0.12 and string.char(math.random(33, 90)) or c)
				end
				p.title.Text = table.concat(chars)
				p.title.Position = UDim2.new(0.5, math.random(-6, 6), 0.44, math.random(-3, 3))
			end
		else
			local down = p.motif == "Petals"
			for _, dot in p.items do
				local y = dot.Position.Y.Scale + (down and 1 or -1) * dot:GetAttribute("Speed") * dt
				local x = dot.Position.X.Scale + (down and 0.02 or 0.004) * dt * math.sin(t + y * 6)
				if y > 1.05 then
					y = -0.05
				elseif y < -0.05 then
					y = 1.05
				end
				dot.Position = UDim2.fromScale(x % 1, y)
				dot.Rotation += dt * 40
			end
		end
	end)
end

local function clear()
	if active then
		if active.conn then
			active.conn:Disconnect()
		end
		active.gui:Destroy()
		active = nil
	end
end

function TravelScreen.Show(themeName, seconds, title, subtitle)
	clear()
	local gui, root, parts = build(themeName, title, subtitle)
	root.GroupTransparency = 1
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	active = { gui = gui, root = root, parts = parts }
	animate(active)
	local time = seconds or 0.35
	TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()
	task.wait(time)
end

function TravelScreen.Hide(seconds)
	local state = active
	if not state then
		return
	end
	local time = seconds or 0.6
	TweenService:Create(state.root, TweenInfo.new(time, Enum.EasingStyle.Quad), { GroupTransparency = 1 }):Play()
	task.delay(time, function()
		if active == state then
			clear()
		end
	end)
end

-- For TeleportService:SetTeleportGui: Roblox shows it while the next place loads (scripts do not run in it, so it is still).
function TravelScreen.ForTeleport(themeName, title, subtitle)
	local gui = build(themeName, title, subtitle)
	pcall(TeleportService.SetTeleportGui, TeleportService, gui)
	return gui
end

-- In the place you land in: keep the card you travelled with up until the world is there, then fade it away.
function TravelScreen.Arrive(seconds)
	local ok, gui = pcall(TeleportService.GetArrivingTeleportGui, TeleportService)
	if not ok or not gui then
		return false
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	task.wait(0.6)
	local card = gui:FindFirstChild("Card")
	if card and card:IsA("CanvasGroup") then
		TweenService:Create(card, TweenInfo.new(seconds or 0.9), { GroupTransparency = 1 }):Play()
	end
	task.delay((seconds or 0.9) + 0.1, function()
		gui:Destroy()
	end)
	return true
end

return TravelScreen
