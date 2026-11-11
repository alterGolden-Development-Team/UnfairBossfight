--!nonstrict
-- The bag icon on the left edge of the screen (UnfairShared/InventoryUI), and a word on arrival from a side place:
-- back from the glitched place with the Reality Disorderer unlocked, or back from Azusa's training grounds.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local InventoryUI = require(ReplicatedStorage:WaitForChild("UnfairShared"):WaitForChild("InventoryUI"))
InventoryUI.Mount()

local ok, data = pcall(TeleportService.GetLocalPlayerTeleportData, TeleportService)
if ok and type(data) == "table" then
	task.delay(2.5, function()
		if data.from == "Glitched" and data.unlocked == "Disorderer" then
			InventoryUI.Toast("The Reality Disorderer is yours. Equip it at the Keeper's shop.", 8)
		elseif data.from == "Tutorial" and data.done == true then
			InventoryUI.Toast("Azusa: \"You're ready. Go show him!\" Gather a party at the palace portals.", 7)
		end
	end)
end
