 
 
local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "GoldenBossEntrance"
gui.ResetOnSpawn = false
 
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")
local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(17, 22, 12)
shade.BackgroundTransparency = 1
shade.BorderSizePixel = 0
shade.Parent = gui
local shadeTween
local function sync()
	local ending = workspace:GetAttribute("BossEntranceEndsAt") or 0
	local active = ending > workspace:GetServerTimeNow() and not workspace:GetAttribute("BossEncounterReady")
	if shadeTween then
		shadeTween:Cancel()
	end
	shadeTween =
		Tween:Create(shade, TweenInfo.new(active and 0.25 or 0.4), { BackgroundTransparency = active and 0.82 or 1 })
	shadeTween:Play()
	if active then
		player:SetAttribute("EntranceSentenceSeen", true)
	end
end
workspace:GetAttributeChangedSignal("BossEntranceEndsAt"):Connect(sync)
workspace:GetAttributeChangedSignal("BossEncounterReady"):Connect(sync)
sync()
