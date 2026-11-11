--!nonstrict
-- The bag icon on the left edge of the screen (UnfairShared/InventoryUI), and the message when you take the hidden Reality Orb
-- (Encounter/RealityOrb).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryUI = require(ReplicatedStorage:WaitForChild("UnfairShared"):WaitForChild("InventoryUI"))
InventoryUI.Mount()
local notice = ReplicatedStorage:WaitForChild("RealityOrbNotice", 30)
if notice then
	notice.OnClientEvent:Connect(function(text)
		if type(text) == "string" then
			InventoryUI.Toast(text, 6)
		end
	end)
end
