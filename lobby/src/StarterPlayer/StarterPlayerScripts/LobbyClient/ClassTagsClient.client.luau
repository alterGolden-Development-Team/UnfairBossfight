--!nonstrict
-- Every player's class floats above their head: the class icon and its name, read from the replicated PlayerClass attribute.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local StatusIcons = require(ReplicatedStorage.BossShared.Presentation.StatusIcons)

local GOLD = Color3.fromRGB(255, 196, 64)
local tags = {}

local function updateTag(other)
	local character = other.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local id = other:GetAttribute("PlayerClass")
	local def = ClassConfig.Classes[id]
	local tag = tags[other]
	if not def then
		if tag then
			tag:Destroy()
			tags[other] = nil
		end
		return
	end
	if not tag or tag.Parent ~= head then
		if tag then
			tag:Destroy()
		end
		tag = Instance.new("BillboardGui")
		tag.Name = "ClassTag"
		tag.Size = UDim2.fromOffset(190, 28)
		tag.StudsOffset = Vector3.new(0, 3.3, 0)
		tag.MaxDistance = 80
		tag.LightInfluence = 0
		tag.Adornee = head
		tag.Parent = head
		local row = Instance.new("Frame")
		row.Name = "Row"
		row.BackgroundTransparency = 1
		row.Size = UDim2.fromScale(1, 1)
		row.Parent = tag
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 5)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = row
		local iconBox = Instance.new("Frame")
		iconBox.Name = "IconBox"
		iconBox.BackgroundTransparency = 1
		iconBox.Size = UDim2.fromOffset(24, 24)
		iconBox.LayoutOrder = 1
		iconBox.Parent = row
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.LayoutOrder = 2
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromOffset(0, 24)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextStrokeTransparency = 0.3
		label.Parent = row
		tags[other] = tag
	end
	local row = tag.Row
	if row:GetAttribute("ClassId") ~= id then
		row:SetAttribute("ClassId", id)
		row.IconBox:ClearAllChildren()
		StatusIcons.Create(row.IconBox, "Logo" .. id, UDim2.fromScale(1, 1), UDim2.new(), def.Color or GOLD)
	end
	row.Label.Text = def.Name
	row.Label.TextColor3 = def.Color or GOLD
end

local function track(other)
	other:GetAttributeChangedSignal("PlayerClass"):Connect(function()
		updateTag(other)
	end)
	other.CharacterAdded:Connect(function()
		task.wait(0.2)
		updateTag(other)
	end)
	updateTag(other)
end

for _, other in Players:GetPlayers() do
	track(other)
end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(other)
	tags[other] = nil
end)
