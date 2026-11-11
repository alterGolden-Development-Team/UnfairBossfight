--!nonstrict
--[[
 InventoryUI - the bag icon on the left edge of the screen, in every place. Click it (or press B) and a black box opens beside it
 listing what you carry; click again to close. The list is read from the player attribute `Inventory` (JSON { [itemId] = count }),
 which only the server writes (lobby PlayerData, boss Orbs pickup, glitched place hand-over). Client only: InventoryUI.Mount().
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ItemConfig = require(script.Parent.ItemConfig)

local api = {}
local mounted = false

local GOLD = Color3.fromRGB(246, 211, 117)
local INK = Color3.fromRGB(8, 8, 10)
local LEATHER = Color3.fromRGB(150, 98, 54)
local LEATHER_DARK = Color3.fromRGB(96, 60, 32)

local function make(className, props, parent)
	local i = Instance.new(className)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function corner(parent, r)
	make("UICorner", { CornerRadius = r or UDim.new(0, 6) }, parent)
end

-- a satchel drawn from frames: strap, body, flap and a gold clasp
local function drawBag(parent)
	local holder = make("Frame", { Name = "Bag", BackgroundTransparency = 1, Size = UDim2.fromScale(0.72, 0.72), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.54), Interactable = false }, parent)
	local strap = make("Frame", { Name = "Strap", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.06), Size = UDim2.fromScale(0.56, 0.5) }, holder)
	corner(strap, UDim.new(0.5, 0))
	make("UIStroke", { Color = LEATHER_DARK, Thickness = 3 }, strap)
	local body = make("Frame", { Name = "Body", BackgroundColor3 = LEATHER, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(0.94, 0.7) }, holder)
	corner(body, UDim.new(0.22, 0))
	make("UIStroke", { Color = LEATHER_DARK, Thickness = 2 }, body)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)) }, body)
	local flap = make("Frame", { Name = "Flap", BackgroundColor3 = LEATHER_DARK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.94, 0.3) }, holder)
	corner(flap, UDim.new(0.3, 0))
	local clasp = make("Frame", { Name = "Clasp", BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.2, 0.16) }, holder)
	corner(clasp, UDim.new(0.3, 0))
	return holder
end

local function decode(raw)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw or "{}")
	return ok and type(data) == "table" and data or {}
end

-- A short message across the top of the screen (the orb pickup, the glitched man's hand-over).
local toastGui, toastLabel, toastToken = nil, nil, 0
function api.Toast(text, seconds)
	local player = Players.LocalPlayer
	if not toastGui then
		toastGui = make("ScreenGui", { Name = "InventoryToast", ResetOnSpawn = false, DisplayOrder = 60 }, player:WaitForChild("PlayerGui"))
		toastLabel = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(560, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = INK, BackgroundTransparency = 0.15, Font = Enum.Font.GothamMedium, TextSize = 17, TextWrapped = true,
			TextColor3 = Color3.new(1, 1, 1), Text = "", Visible = false,
		}, toastGui)
		corner(toastLabel, UDim.new(0, 8))
		make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, toastLabel)
		make("UIStroke", { Color = Color3.fromRGB(255, 80, 225), Transparency = 0.3 }, toastLabel)
	end
	toastToken += 1
	local mine = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(seconds or 5, function()
		if toastToken == mine then
			toastLabel.Visible = false
		end
	end)
end

function api.Mount()
	if mounted then
		return
	end
	mounted = true
	local player = Players.LocalPlayer
	local gui = make("ScreenGui", { Name = "InventoryGui", ResetOnSpawn = false, DisplayOrder = 40, IgnoreGuiInset = false }, player:WaitForChild("PlayerGui"))
	local icon = make("ImageButton", {
		Name = "InventoryButton", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, -40), Size = UDim2.fromOffset(58, 58),
		BackgroundColor3 = INK, BackgroundTransparency = 0.25, AutoButtonColor = true, Image = "",
	}, gui)
	corner(icon, UDim.new(0, 12))
	local stroke = make("UIStroke", { Color = GOLD, Thickness = 1.5, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, icon)
	drawBag(icon)
	local badge = make("TextLabel", {
		Name = "Count", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -6), Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Color3.fromRGB(255, 80, 225), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), Text = "", Visible = false,
	}, icon)
	corner(badge, UDim.new(1, 0))

	local box = make("Frame", {
		Name = "Box", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 80, 0.5, -40), Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = INK, BackgroundTransparency = 0.04, BorderSizePixel = 0, Visible = false,
	}, gui)
	corner(box, UDim.new(0, 10))
	make("UIStroke", { Color = GOLD, Thickness = 1.2, Transparency = 0.35 }, box)
	make("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, box)
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, box)
	make("TextLabel", {
		Name = "Title", LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Font = Enum.Font.Garamond, TextSize = 24,
		TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Text = "Inventory",
	}, box)

	local function refresh()
		for _, child in box:GetChildren() do
			if child.Name == "Item" or child.Name == "Empty" then
				child:Destroy()
			end
		end
		local items = decode(player:GetAttribute("Inventory"))
		local total, order = 0, 0
		for _, id in ItemConfig.Order do
			local count = tonumber(items[id]) or 0
			local def = ItemConfig.Items[id]
			if count > 0 and def then
				total += count
				order += 1
				local row = make("Frame", { Name = "Item", LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, box)
				local orb = make("Frame", { Size = UDim2.fromOffset(34, 34), BackgroundColor3 = def.Color, BorderSizePixel = 0 }, row)
				corner(orb, UDim.new(1, 0))
				make("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(90, 230, 255)) }, orb)
				make("TextLabel", {
					Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -46, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
					TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Text = def.Name .. (count > 1 and ("  x" .. count) or ""),
				}, row)
				make("TextLabel", {
					Position = UDim2.fromOffset(46, 22), Size = UDim2.new(1, -46, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
					Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true, TextColor3 = Color3.fromRGB(190, 186, 176), TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top, Text = def.Text,
				}, row)
			end
		end
		if total == 0 then
			make("TextLabel", {
				Name = "Empty", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14,
				TextColor3 = Color3.fromRGB(150, 146, 136), TextXAlignment = Enum.TextXAlignment.Left, Text = "Nothing yet.",
			}, box)
		end
		badge.Visible = total > 0
		badge.Text = tostring(total)
	end

	local function toggle(open)
		if open == nil then
			open = not box.Visible
		end
		box.Visible = open
		stroke.Thickness = open and 2.5 or 1.5
		if open then
			refresh()
		end
	end
	icon.Activated:Connect(function()
		toggle()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.B then
			toggle()
		end
	end)
	player:GetAttributeChangedSignal("Inventory"):Connect(function()
		local before = badge.Text
		refresh()
		if badge.Text ~= before and badge.Visible then
			-- something new: a short pulse on the icon
			icon.Size = UDim2.fromOffset(70, 70)
			TweenService:Create(icon, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(58, 58) }):Play()
		end
	end)
	refresh()
	return gui
end

return api
