--!nonstrict
-- Full-screen fade with an optional title card, shared by portals and the shop. Client only.
-- Given a theme (an area name: Hub, Palace, Island, Forest, Stage, Shop, Tutorial, Glitch), it shows that destination's travel card
-- (UnfairShared/TravelScreen) instead of plain black.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TravelScreen = require(game:GetService("ReplicatedStorage"):WaitForChild("UnfairShared"):WaitForChild("TravelScreen"))

local Fade = {}

local gui = Instance.new("ScreenGui")
gui.Name = "FadeGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local black = Instance.new("Frame")
black.Size = UDim2.fromScale(1, 1)
black.BackgroundColor3 = Color3.new(0, 0, 0)
black.BackgroundTransparency = 1
black.BorderSizePixel = 0
black.Active = false
black.Parent = gui

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.45)
title.Size = UDim2.new(0.9, 0, 0, 70)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Garamond
title.TextSize = 56
title.TextColor3 = Color3.fromRGB(246, 211, 117)
title.TextTransparency = 1
title.Text = ""
title.Parent = gui

local themed = false

function Fade.Out(seconds, text, theme)
	if theme and TravelScreen.Themes[theme] then
		themed = true
		TravelScreen.Show(theme, seconds or 0.35)
		return
	end
	black.Active = true
	title.Text = text or ""
	TweenService:Create(black, TweenInfo.new(seconds or 0.35), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(title, TweenInfo.new(seconds or 0.35), { TextTransparency = 0 }):Play()
	task.wait(seconds or 0.35)
end

function Fade.In(seconds)
	local time = seconds or 0.5
	if themed then
		themed = false
		TravelScreen.Hide(time + 0.2)
	end
	TweenService:Create(black, TweenInfo.new(time), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(title, TweenInfo.new(time), { TextTransparency = 1 }):Play()
	task.delay(time, function()
		black.Active = false
	end)
end

return Fade
