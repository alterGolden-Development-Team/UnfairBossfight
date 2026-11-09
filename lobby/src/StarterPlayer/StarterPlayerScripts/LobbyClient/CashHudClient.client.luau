--!nonstrict
-- Cash HUD (plan task 22): top-right, shows the player's cash, "--" while it is loading or could not be read.
-- Read-only: it displays the Cash / CashState attributes the lobby's CashService publishes. When the number goes up
-- (a win just paid out) a "+N" floats up beside it.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 196, 64)

local gui = Instance.new("ScreenGui")
gui.Name = "CashHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(1, 0)
box.Position = UDim2.new(1, -16, 0, 16)
box.Size = UDim2.fromOffset(170, 40)
box.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
box.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = box
local stroke = Instance.new("UIStroke")
stroke.Color = GOLD
stroke.Thickness = 1.5
stroke.Parent = box

local text = Instance.new("TextLabel")
text.Name = "Amount"
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBold
text.TextSize = 18
text.TextColor3 = GOLD
text.Parent = box

local last = nil

local function commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function floatGain(amount)
	local gain = Instance.new("TextLabel")
	gain.AnchorPoint = Vector2.new(1, 0)
	gain.Position = UDim2.new(1, 0, 1, 2)
	gain.Size = UDim2.fromOffset(120, 24)
	gain.BackgroundTransparency = 1
	gain.Font = Enum.Font.GothamBold
	gain.TextSize = 18
	gain.TextColor3 = Color3.fromRGB(120, 230, 140)
	gain.Text = `+{commas(amount)}`
	gain.Parent = box
	local tween = TweenService:Create(gain, TweenInfo.new(1.6), { Position = UDim2.new(1, 0, 1, 26), TextTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		gain:Destroy()
	end)
end

local function update()
	local state = player:GetAttribute("CashState")
	local cash = player:GetAttribute("Cash")
	if state == "Ready" and type(cash) == "number" then
		text.Text = `Cash: {commas(cash)}`
		if last and cash > last then
			floatGain(cash - last)
		end
		last = cash
	else
		text.Text = "Cash: --"
	end
end

player:GetAttributeChangedSignal("Cash"):Connect(update)
player:GetAttributeChangedSignal("CashState"):Connect(update)
update()
