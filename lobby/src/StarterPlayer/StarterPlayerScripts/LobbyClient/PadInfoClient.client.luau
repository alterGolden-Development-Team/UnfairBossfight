--!nonstrict
-- The panel for portals whose boss is not built yet. Walk up to one and it says so. Nothing here can teleport anyone.
-- Watched: parts tagged UnfairComingSoon; their ComingSoon attribute picks the text in ReplicatedStorage.Lobby.PadInfo.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PadInfo = require(ReplicatedStorage.Lobby.PadInfo)

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 196, 64)
local RADIUS = 14

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
card.BackgroundColor3 = Color3.fromRGB(20, 17, 16)
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
local title = label("Title", 10, 28, 24, GOLD, Enum.Font.Garamond)
local subtitle = label("Subtitle", 40, 20, 15, Color3.fromRGB(255, 150, 130), Enum.Font.GothamBold)
local body = label("Body", 64, 50, 14, Color3.fromRGB(205, 200, 215), Enum.Font.Gotham)

local current = nil

task.spawn(function()
	while true do
		task.wait(0.2)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local nearest = nil
		if root then
			local best = RADIUS
			for _, face in CollectionService:GetTagged("UnfairComingSoon") do
				local distance = (face.Position - root.Position).Magnitude
				if distance <= best then
					nearest, best = face, distance
				end
			end
		end
		if nearest then
			local key = nearest:GetAttribute("ComingSoon")
			local info = PadInfo[key]
			if info and current ~= key then
				current = key
				title.Text, subtitle.Text, body.Text = info.title, info.subtitle, info.body
				card.Visible = true
			end
		elseif current then
			current = nil
			card.Visible = false
		end
	end
end)
