--!nonstrict
-- Shows the short notices the boss place's Intake sets on the player (LobbyNotice), e.g. when a class from the
-- lobby could not be used and the default class was given instead. Nothing here changes any game state.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LobbyNoticeHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 24)
toast.Size = UDim2.fromOffset(520, 44)
toast.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
toast.BackgroundTransparency = 0.1
toast.TextColor3 = Color3.new(1, 1, 1)
toast.Font = Enum.Font.GothamMedium
toast.TextSize = 16
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toast
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 196, 64)
stroke.Parent = toast

local shown = 0
local function show()
	local text = player:GetAttribute("LobbyNotice")
	if type(text) ~= "string" or text == "" then
		return
	end
	shown += 1
	local mine = shown
	toast.Text = text
	toast.Visible = true
	task.delay(6, function()
		if shown == mine then
			toast.Visible = false
		end
	end)
end

player:GetAttributeChangedSignal("LobbyNoticeId"):Connect(show)
show()
