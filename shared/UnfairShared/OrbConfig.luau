--!strict
-- The orbs sold in the lobby shop. One orb can be equipped at a time; the boss place reads it from the saved record on arrival.
-- Pure data, read by the shop (lobby) and by the boss place (Encounter/Orbs, CashService).
-- Effects are deliberately small: an orb is a build choice, it must not decide whether a boss can be beaten.

export type Orb = {
	Name: string,
	Price: number,
	Color: Color3,
	Passive: string,
	Flavor: string,
	Stat: string, -- "MaxHealth" | "Speed" | "Stamina" | "DashCost" | "Cash"
	Value: number, -- multiplier on that stat
}

local Orbs = {}

Orbs.Order = table.freeze({ "Endurance", "Vitality", "Swiftness", "Ember", "Fortune" })

Orbs.Items = table.freeze({
	Endurance = table.freeze({
		Name = "Orb of Endurance", Price = 40, Color = Color3.fromRGB(255, 214, 92),
		Passive = "+20% maximum stamina.",
		Flavor = "Still warm from the hands of a porter who never put down his load.",
		Stat = "Stamina", Value = 1.2,
	}),
	Vitality = table.freeze({
		Name = "Orb of Vitality", Price = 60, Color = Color3.fromRGB(110, 230, 130),
		Passive = "+10% maximum health.",
		Flavor = "It beats, slowly, if you hold it long enough.",
		Stat = "MaxHealth", Value = 1.1,
	}),
	Swiftness = table.freeze({
		Name = "Orb of Swiftness", Price = 60, Color = Color3.fromRGB(120, 200, 255),
		Passive = "+8% movement speed.",
		Flavor = "Keeps rolling long after the table has stopped.",
		Stat = "Speed", Value = 1.08,
	}),
	Ember = table.freeze({
		Name = "Ember Orb", Price = 120, Color = Color3.fromRGB(255, 120, 70),
		Passive = "Dashing costs 15% less stamina.",
		Flavor = "A coal from the forge that made the first sword.",
		Stat = "DashCost", Value = 0.85,
	}),
	Fortune = table.freeze({
		Name = "Orb of Fortune", Price = 250, Color = Color3.fromRGB(240, 170, 255),
		Passive = "+25% cash from every win.",
		Flavor = "The merchant swears it is not cursed. The merchant is very rich.",
		Stat = "Cash", Value = 1.25,
	}),
} :: { [string]: Orb })

return Orbs
