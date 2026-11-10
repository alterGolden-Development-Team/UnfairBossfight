--!nonstrict
-- Every player's class floats above their head, read from the replicated PlayerClass attribute.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)

local GOLD = Color3.fromRGB(255, 196, 64)
local tags = {}

local function updateTag(other)
	local character = other.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	-- no tag on a showroom performer (TryoutClass set): it is a dummy showing a class, not the player's pick
	local def = other:GetAttribute("TryoutClass") == nil and ClassConfig.Classes[other:GetAttribute("PlayerClass")]
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
		tag.Size = UDim2.fromOffset(150, 24)
		tag.StudsOffset = Vector3.new(0, 3.2, 0)
		tag.MaxDistance = 80
		tag.Adornee = head
		tag.Parent = head
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextStrokeTransparency = 0.3
		label.Parent = tag
		tags[other] = tag
	end
	tag.Label.Text = def.Name
	tag.Label.TextColor3 = def.Color or GOLD
end

local function track(other)
	other:GetAttributeChangedSignal("PlayerClass"):Connect(function()
		updateTag(other)
	end)
	other:GetAttributeChangedSignal("TryoutClass"):Connect(function()
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
