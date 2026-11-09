--!strict
-- Text for the "coming soon" places in the lobby (plan task 24). Keyed by the model's name in the map (see lobby/MAP.md).
-- Pure data: change a line here and nothing else needs touching. These places have NO teleport path at all.

export type Info = { title: string, subtitle: string, body: string }

local PadInfo: { [string]: Info } = {
	JeffAndFred = {
		title = "Jeff n' Fred Bizzare Brother",
		subtitle = "Coming soon",
		body = "The chains are still on. This trial is not open yet - check back after the next update.",
	},
	FallenNoob = {
		title = "TheFallenNoob's Private Island",
		subtitle = "Coming soon",
		body = "The dock is still being built. This trial is not open yet - check back after the next update.",
	},
	Shop = {
		title = "The Shop",
		subtitle = "Coming soon",
		body = "Powerups and classes you buy with the cash you earn from wins. Keep winning - your cash is saved.",
	},
}

return PadInfo
