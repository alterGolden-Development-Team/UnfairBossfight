--!nonstrict
-- Jeff and Fred: R6 avatars (R6Pose) holding Blender katanas and wearing headbands, fighting forever in the forest clearing.
-- A brother is a Model built by R6Pose.build with two extra children the builder adds: "Sword" and "Headband" (Models from the
-- Figures/Lobby3 kits). Its WorldPivot is "home": the ground between its feet, facing its brother (-Z); attribute Scale sizes it.
-- Rig.pose places the body and its gear from a pose table, so the builder can pose them at guard and the client can animate them.
local R6Pose = require(script.Parent.R6Pose)

local Rig = {}

function Rig.pose(model, home, p, scale)
	local s = scale or model:GetAttribute("Scale") or 1
	local hand, head = R6Pose.place(model, home, p, s)
	local sword = model:FindFirstChild("Sword")
	if sword then
		sword:PivotTo(hand)
	end
	local band = model:FindFirstChild("Headband")
	if band then
		band:PivotTo(head)
	end
end

Rig.lerp = R6Pose.lerp

-- The duel's poses (degrees). The right hand holds the sword; with the arm hanging down the blade points forward.
Rig.POSES = {
	guard = {
		spine = { 6, -14, 0 }, neck = { 0, 10, 0 },
		shR = { 78, 0, 6 }, wrR = { 8, 0, 0 },
		shL = { 34, 0, -16 },
		hipR = { 22, 0, 4 }, hipL = { -18, 0, -4 },
	},
	windup = {
		spine = { -8, -32, 0 }, neck = { 4, 22, 0 },
		shR = { 172, 0, 14 }, wrR = { 18, 0, 0 },
		shL = { 52, 0, -30 },
		hipR = { 16, 0, 4 }, hipL = { -22, 0, -4 },
	},
	strike = {
		move = { 0, 0, -3.4 }, spine = { 22, 24, 0 }, neck = { -12, -16, 0 },
		shR = { 32, 0, -8 }, wrR = { -42, 0, 0 },
		shL = { -26, 0, -28 },
		hipR = { 48, 0, 4 }, hipL = { -36, 0, -4 },
	},
	parry = {
		move = { 0, 0, 0.8 }, spine = { -10, 12, 0 }, neck = { 10, -8, 0 },
		shR = { 152, 0, 26 }, wrR = { -84, 0, 0 },
		shL = { 128, 0, -32 },
		hipR = { 26, 0, 6 }, hipL = { -26, 0, -6 },
	},
	spin = {
		move = { 1.6, 0, -1.2 }, turn = -40, spine = { 4, -40, 0 }, neck = { 0, 30, 0 },
		shR = { 92, 0, 52 }, wrR = { -60, 0, 0 },
		shL = { 34, 0, -42 },
		hipR = { 30, 0, 10 }, hipL = { -22, 0, -8 },
	},
}

-- One exchange: attacker's beats and defender's beats, each { pose, seconds }. `clash` marks the beat that ends in a spark.
Rig.EXCHANGE = {
	attacker = { { "guard", 0.5 }, { "windup", 0.32 }, { "strike", 0.16, clash = true }, { "strike", 0.12 }, { "guard", 0.42 }, { "spin", 0.3 }, { "guard", 0.36 } },
	defender = { { "guard", 0.62 }, { "parry", 0.26 }, { "parry", 0.12 }, { "parry", 0.1 }, { "guard", 0.4 }, { "guard", 0.3 }, { "guard", 0.38 } },
}

return Rig
