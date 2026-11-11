local Difficulty=require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local YELLOW, RED = Color3.fromRGB(255, 220, 35), Color3.fromRGB(235, 30, 45)
local api = {}
function api.Configure(actor)
	local boss = actor
	local head = boss:WaitForChild("Head")
	local gui = Instance.new("BillboardGui")
	gui.Name = "BossAttackSign"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(100, 96)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 350
	gui.Enabled = false
	gui.Parent = head
	local warning = Instance.new("Frame")
	warning.Name = "AttackWarning"
	warning.AnchorPoint = Vector2.new(0.5, 0.5)
	warning.Position = UDim2.fromScale(0.5, 0.4)
	warning.Size = UDim2.fromOffset(38, 38)
	warning.Rotation = 45
	warning.BackgroundColor3 = Color3.fromRGB(255, 220, 35)
	warning.BorderSizePixel = 0
	warning.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(85, 51, 7)
	stroke.Thickness = 3
	stroke.Parent = warning
	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Rotation = -45
	mark.Font = Enum.Font.GothamBold
	mark.TextSize = 35
	mark.Text = "!"
	mark.TextColor3 = Color3.fromRGB(40, 29, 10)
	mark.Parent = warning
	local shield = Instance.new("Frame")
	shield.Name = "ParryShield"
	shield.AnchorPoint = Vector2.new(0.5, 0.5)
	shield.Position = UDim2.fromScale(0.5, 0.4)
	shield.Size = UDim2.fromOffset(38, 36)
	shield.BackgroundColor3 = Color3.fromRGB(87, 175, 223)
	shield.BorderSizePixel = 0
	shield.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 7)
	round.Parent = shield
	local bottom = Instance.new("Frame")
	bottom.Size = UDim2.fromOffset(26, 26)
	bottom.Position = UDim2.fromOffset(6, 18)
	bottom.Rotation = 45
	bottom.BackgroundColor3 = shield.BackgroundColor3
	bottom.BorderSizePixel = 0
	bottom.Parent = shield
	local cross = Instance.new("TextLabel")
	cross.Size = UDim2.fromScale(1, 1)
	cross.BackgroundTransparency = 1
	cross.Font = Enum.Font.GothamBold
	cross.TextSize = 29
	cross.Text = "+"
	cross.TextColor3 = Color3.fromRGB(242, 252, 255)
	cross.ZIndex = 3
	cross.Parent = shield
	local function update()
		local active = (
			boss:GetAttribute("AttackInProgress") == true or boss:GetAttribute("PhaseTransitionInProgress") == true
		)
			and boss.Humanoid.Health > 0
			and not boss:GetAttribute("IllusionOutlineHidden")
			and not boss:GetAttribute("IsIllusion")
			and Difficulty.Get(boss).ShowAttackIndicators
		local defending = boss:GetAttribute("ParryActive") == true
		 -- the same ! turns red for a skill that takes lives (EncounterConfig.LethalSkills), and shows on every difficulty
		local lethal = (boss:GetAttribute("AttackInProgress") == true and Config.LethalSkills
			and Config.LethalSkills[boss:GetAttribute("CurrentSkill") or ""] == true or boss:GetAttribute("AttackLethal") == true)
			and boss.Humanoid.Health > 0
		active = active or lethal
		warning.BackgroundColor3 = lethal and RED or YELLOW
		mark.TextColor3 = lethal and Color3.fromRGB(255, 240, 240) or Color3.fromRGB(40, 29, 10)
		stroke.Color = lethal and Color3.fromRGB(70, 0, 8) or Color3.fromRGB(85, 51, 7)
		gui.Enabled = active
		warning.Visible = not defending
		shield.Visible = defending
		boss:SetAttribute("AttackIndicatorState", active and (defending and "Defend" or "Warning") or "Hidden")
	end
	local connections = {
		boss:GetAttributeChangedSignal("AttackInProgress"):Connect(update),
		boss:GetAttributeChangedSignal("EncounterDifficulty"):Connect(update),
		workspace:GetAttributeChangedSignal("ActiveDifficulty"):Connect(update),
		workspace:GetAttributeChangedSignal("SelectedDifficulty"):Connect(update),
		workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(update),
		boss:GetAttributeChangedSignal("PhaseTransitionInProgress"):Connect(update),
		boss:GetAttributeChangedSignal("ParryActive"):Connect(update),
		boss:GetAttributeChangedSignal("CurrentSkill"):Connect(update),
		boss:GetAttributeChangedSignal("AttackLethal"):Connect(update),
		boss:GetAttributeChangedSignal("IllusionOutlineHidden"):Connect(update),
		boss.Humanoid.HealthChanged:Connect(update),
	}
	local ending
	ending = boss.Destroying:Connect(function()
		for _, c in ipairs(connections) do
			c:Disconnect()
		end
		ending:Disconnect()
	end)
	update()
end
return api
