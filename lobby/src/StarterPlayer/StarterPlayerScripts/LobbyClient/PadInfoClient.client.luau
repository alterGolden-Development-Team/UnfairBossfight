--!nonstrict
-- "Coming soon" panels (plan task 24, spec 7). Walk up to the Jeff n' Fred arch, the TheFallenNoob's Private Island arch
-- or the shop and a small panel says what it is. Nothing here can teleport anyone: this script never touches
-- TeleportService and the pads it watches have no prompt, so the only effect of stepping on them is the panel.
--
-- Which models are watched: every child of Workspace.Pads whose attribute Status is "ComingSoon", plus Workspace.Shop.
-- The text comes from ReplicatedStorage.Lobby.PadInfo (by the model's name).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PadInfo = require(ReplicatedStorage.Lobby.PadInfo)

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 196, 64)
local RADIUS = 9 -- studs from the model's box at which the panel shows

local gui = Instance.new("ScreenGui")
gui.Name = "PadInfoGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.new(0.5, 0, 1, -90)
card.Size = UDim2.new(0.9, 0, 0, 120)
card.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
card.BackgroundTransparency = 0.05
card.Visible = false
card.Parent = gui
local cap = Instance.new("UISizeConstraint")
cap.MaxSize = Vector2.new(460, 120)
cap.Parent = card
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = card
local stroke = Instance.new("UIStroke")
stroke.Color = GOLD
stroke.Thickness = 2
stroke.Parent = card

local function label(name, y, height, size, color, font)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = UDim2.new(0, 16, 0, y)
	item.Size = UDim2.new(1, -32, 0, height)
	item.BackgroundTransparency = 1
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Top
	item.TextWrapped = true
	item.Font = font
	item.TextSize = size
	item.TextColor3 = color
	item.Parent = card
	return item
end
local title = label("Title", 10, 28, 22, GOLD, Enum.Font.GothamBold)
local subtitle = label("Subtitle", 38, 20, 15, Color3.fromRGB(255, 150, 130), Enum.Font.GothamBold)
local body = label("Body", 62, 52, 14, Color3.fromRGB(205, 200, 215), Enum.Font.Gotham)

local watched = {} -- { name = string, model = Model, cframe = CFrame, half = Vector3 }

local function addTarget(model)
	if not model:IsA("Model") then
		return
	end
	if not PadInfo[model.Name] then
		return
	end
	local cframe, size = model:GetBoundingBox()
	table.insert(watched, { name = model.Name, model = model, cframe = cframe, half = size / 2 })
end

-- distance from a world point to the box, 0 when inside it
local function distanceTo(target, point)
	local offset = target.cframe:PointToObjectSpace(point)
	local dx = math.max(math.abs(offset.X) - target.half.X, 0)
	local dy = math.max(math.abs(offset.Y) - target.half.Y, 0)
	local dz = math.max(math.abs(offset.Z) - target.half.Z, 0)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local current = nil
local function show(target)
	if current == target.name then
		return
	end
	current = target.name
	local info = PadInfo[target.name]
	title.Text = info.title
	subtitle.Text = info.subtitle
	body.Text = info.body
	card.Visible = true
end
local function hide()
	current = nil
	card.Visible = false
end

task.spawn(function()
	local pads = workspace:WaitForChild("Pads", 30)
	if pads then
		for _, pad in ipairs(pads:GetChildren()) do
			if pad:GetAttribute("Status") == "ComingSoon" then
				addTarget(pad)
			end
		end
	end
	local shop = workspace:FindFirstChild("Shop")
	if shop then
		addTarget(shop)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			hide()
		else
			local nearest, nearestDistance = nil, RADIUS
			for _, target in ipairs(watched) do
				if target.model.Parent then
					local distance = distanceTo(target, root.Position)
					if distance <= nearestDistance then
						nearest, nearestDistance = target, distance
					end
				end
			end
			if nearest then
				show(nearest)
			else
				hide()
			end
		end
	end
end)
