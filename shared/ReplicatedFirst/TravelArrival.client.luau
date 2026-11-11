--!nonstrict
-- Mounted in ReplicatedFirst of the lobby and the side places. If you came through a portal from another place, the travel card
-- you left with (UnfairShared/TravelScreen.ForTeleport) stays up until this place has loaded, then fades away.
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local ok, gui = pcall(TeleportService.GetArrivingTeleportGui, TeleportService)
if not ok or not gui then
	return
end
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
	game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
end)
if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(1)
local card = gui:FindFirstChild("Card")
if card and card:IsA("CanvasGroup") then
	TweenService:Create(card, TweenInfo.new(0.9), { GroupTransparency = 1 }):Play()
end
task.delay(1, function()
	gui:Destroy()
end)
