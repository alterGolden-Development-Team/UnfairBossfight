 
 
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared"):WaitForChild("Presentation"):WaitForChild("TrueIllusion")
local Cinematic = require(shared:WaitForChild("Cinematic"))
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")

local connection = remote.OnClientEvent:Connect(function(kind, data)
	if kind ~= "TrueIllusion" or type(data) ~= "table" then return end
	local ok, err = pcall(Cinematic.Handle, data)
	if not ok then
		warn("[TrueIllusion cinematic] " .. tostring(err))
		pcall(Cinematic.Stop)
	end
end)
local removing = player.CharacterRemoving:Connect(Cinematic.ResetView)
script.Destroying:Connect(function()
	Cinematic.Stop()
	connection:Disconnect()
	removing:Disconnect()
end)
