--!strict
-- Text for the portals of bosses that are not built yet. Keyed by the ComingSoon attribute on the portal face.
-- Pure data: change a line here and nothing else needs touching. These places have NO teleport path at all.

export type Info = { title: string, subtitle: string, body: string }

local PadInfo: { [string]: Info } = {
	JeffAndFred = {
		title = "Jeff n' Fred Bizzare Brother",
		subtitle = "Coming soon",
		body = "The brothers will not stop fighting long enough to let anyone through. This trial opens in a later update.",
	},
	FallenNoob = {
		title = "TheFallenNoob's Private Island",
		subtitle = "Coming soon",
		body = "The tide has not given this door back yet. This trial opens in a later update.",
	},
}

return PadInfo
