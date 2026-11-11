--!strict
-- Items a player can carry (the inventory, the bag icon on the left of the screen). Pure data, read by every place.
-- Items are found in the world and saved in the player's record (CashLedger.Items); nothing here can be bought.

export type Item = { Name: string, Color: Color3, Text: string, Limit: number }

local Items = {}

Items.Order = table.freeze({ "RealityOrb" })

Items.Items = table.freeze({
	RealityOrb = table.freeze({
		Name = "Reality Orb",
		Color = Color3.fromRGB(255, 80, 225),
		Text = "Found somewhere outside the Golden Encounter's walls. It hums when you hold it near anything glitched. Someone at the end of a broken place has been waiting for one.",
		Limit = 1,
	}),
} :: { [string]: Item })

return Items
