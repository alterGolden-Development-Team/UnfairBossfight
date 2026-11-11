--!nonstrict
--[[
 BossKit.BossBar - the boss's health bar at the top of the screen, for any BossKit boss (Workspace.BossKitBoss points at it).
 Shows the boss's title and subtitle, its HP (a bright bar with a slower "lost" bar trailing behind it), its shield laid over the
 HP, the phase pips (attributes BossPhase / BossPhases), and a flash when it is hit. Colour from the boss's BossColor attribute.
   require(ReplicatedStorage.UnfairShared.BossKit.BossBar).Mount()
]]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BossBar = {}
local mounted = false

local function make(className, props, parent)
	local i = Instance.new(className)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

function BossBar.Mount()
	if mounted then
		return
	end
	mounted = true
	local gui = make("ScreenGui", { Name = "BossKitBar", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 20, Enabled = false },
		Players.LocalPlayer:WaitForChild("PlayerGui"))
	local frame = make("Frame", { Name = "Bar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.new(0.5, 0, 0, 74), BackgroundTransparency = 1 }, gui)
	make("UISizeConstraint", { MinSize = Vector2.new(320, 74), MaxSize = Vector2.new(760, 74) }, frame)
	local title = make("TextLabel", { Name = "Title", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.Fondamento, TextSize = 28,
		TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.3, Text = "" }, frame)
	local titleGradient = make("UIGradient", { Rotation = 90 }, title)
	local sub = make("TextLabel", { Name = "Subtitle", Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
		TextSize = 14, TextColor3 = Color3.fromRGB(235, 225, 230), TextStrokeTransparency = 0.4, Text = "" }, frame)
	local track = make("Frame", { Name = "Track", Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = Color3.fromRGB(16, 12, 16),
		BackgroundTransparency = 0.1, BorderSizePixel = 0, ClipsDescendants = true }, frame)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, track)
	local stroke = make("UIStroke", { Thickness = 1.5, Transparency = 0.2 }, track)
	local lost = make("Frame", { Name = "Lost", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 240, 240), BackgroundTransparency = 0.25, BorderSizePixel = 0 }, track)
	local fill = make("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
	local fillGradient = make("UIGradient", {}, fill)
	local shield = make("Frame", { Name = "Shield", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(235, 245, 255), BackgroundTransparency = 0.15, BorderSizePixel = 0 }, track)
	make("UIGradient", { Transparency = NumberSequence.new(0.1, 0.5), Rotation = 90 }, shield)
	local value = make("TextLabel", { Name = "Value", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.2, ZIndex = 3 }, track)
	local pips = make("Frame", { Name = "Phases", Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1 }, frame)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }, pips)

	local boss, conns = nil, {}
	local lostTween
	local lastHealth
	local function refresh()
		if not boss then
			return
		end
		local h = boss:FindFirstChildOfClass("Humanoid")
		if not h then
			return
		end
		local color = boss:GetAttribute("BossColor") or Color3.fromRGB(255, 206, 90)
		title.Text = boss:GetAttribute("BossTitle") or boss.Name
		sub.Text = boss:GetAttribute("BossSubtitle") or ""
		titleGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
		fillGradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color)
		stroke.Color = color
		local ratio = math.clamp(h.Health / math.max(1, h.MaxHealth), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		if lastHealth and h.Health < lastHealth then
			-- hit: flash the bar, let the "lost" part catch up after a beat
			fill.BackgroundColor3 = Color3.new(1, 1, 1)
			fillGradient.Enabled = false
			task.delay(0.06, function()
				fillGradient.Enabled = true
			end)
			if lostTween then
				lostTween:Cancel()
			end
			lostTween = TweenService:Create(lost, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.35), { Size = UDim2.fromScale(ratio, 1) })
			lostTween:Play()
		elseif not lastHealth or h.Health > lastHealth then
			lost.Size = UDim2.fromScale(ratio, 1)
		end
		lastHealth = h.Health
		local s, maxS = boss:GetAttribute("Shield") or 0, boss:GetAttribute("MaxShield") or 0
		shield.Size = UDim2.fromScale(maxS > 0 and math.clamp(s / maxS, 0, 1) or 0, 1)
		value.Text = string.format("%d / %d", math.ceil(h.Health), h.MaxHealth) .. (s > 0 and string.format("   +%d shield", math.ceil(s)) or "")
		local count, at = boss:GetAttribute("BossPhases") or 0, boss:GetAttribute("BossPhase") or 1
		for _, c in pips:GetChildren() do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		for i = 1, count do
			local pip = make("Frame", { Size = UDim2.fromOffset(26, 5), BackgroundColor3 = i <= at and color or Color3.fromRGB(60, 50, 60), BorderSizePixel = 0 }, pips)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, pip)
		end
		gui.Enabled = h.Health > 0 and boss:GetAttribute("BossHidden") ~= true
	end
	local function bind(model)
		for _, c in conns do
			c:Disconnect()
		end
		conns, boss, lastHealth = {}, model, nil
		if not model then
			gui.Enabled = false
			return
		end
		local h = model:WaitForChild("Humanoid", 10)
		if not h or boss ~= model then
			return
		end
		table.insert(conns, h.HealthChanged:Connect(refresh))
		table.insert(conns, h:GetPropertyChangedSignal("MaxHealth"):Connect(refresh))
		table.insert(conns, model.AttributeChanged:Connect(refresh))
		refresh()
	end
	task.spawn(function()
		local pointer = workspace:WaitForChild("BossKitBoss", math.huge)
		pointer:GetPropertyChangedSignal("Value"):Connect(function()
			bind(pointer.Value)
		end)
		bind(pointer.Value)
	end)
end

return BossBar
