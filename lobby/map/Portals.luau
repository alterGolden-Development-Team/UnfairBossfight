--!nonstrict
-- The three boss portals on the hub, each a different shape so they read from across the island without a sign:
-- the Midas king's gilded door (it swings open as you come near), a galleon torn open on a dune for the island, and two greatswords,
-- white and black, crossed over a split floor for the brothers. The gates are Blender meshes (lobby/blender/gates.py); see Gates.luau.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local Gates = require(script.Parent.Gates)
local R6Pose = require(game:GetService("ReplicatedStorage").Lobby.R6Pose)
local C, M = Kit.C, Kit.M
local B = Gates.B

local Portals = {}

local function facing(pos)
	return CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
end

local function midas(root, pos)
	local m = Kit.model(root, "AlterGolden")
	local base = facing(pos)
	local gate = Gates.place(m, "GateGolden", base, "Gate")
	local gold = Kit.rgb(255, 196, 80)
	Gates.glow(gate, gold, 0.15, 44)
	-- the doors: hinged at the opening's edges, swung open on the client when you come close (AreaClient, tag UnfairDoor)
	for _, side in { { "GoldenLeafL", -9, -1 }, { "GoldenLeafR", 9, 1 } } do
		local leaf = Gates.place(m, side[1], base * B(side[2], 0, 3), side[1] == "GoldenLeafL" and "LeafL" or "LeafR")
		for _, part in leaf:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
		leaf:SetAttribute("Swing", side[3]) -- the sign of the turn that swings it open (outward, toward whoever walks up)
		leaf:SetAttribute("OpenAngle", 100)
		leaf:SetAttribute("Range", 46)
		Kit.tag(leaf, "UnfairDoor")
	end
	Gates.trigger(m, base * CFrame.new(0, 16, -1.6), Vector3.new(16, 26, 3), "Palace")
	-- what the king's touch does: people turned to gold, kneeling at his door, and spilled coin
	for _, side in { -1, 1 } do
		local spot = base * CFrame.new(side * 30, 0, -14)
		Kit.box(m, "Plinth", Vector3.new(10, 4, 10), spot * CFrame.new(0, 2, 0), Kit.rgb(24, 20, 22), M.Marble)
		Kit.noShadow(Kit.box(m, "PlinthTrim", Vector3.new(10.6, 0.5, 10.6), spot * CFrame.new(0, 3.9, 0), C.Gold, M.Foil))
		-- an R6 avatar turned to solid gold, on its knees with its arms thrown up before its face
		local at = (spot * CFrame.new(0, 4.15, 0)).Position
		local home = CFrame.lookAt(at, (base * CFrame.new(0, 4.15, 0)).Position) * CFrame.Angles(0, math.rad(side * 25), 0)
		local statue = R6Pose.build(m, "GildedVictim", { skin = C.Gold, torso = C.Gold, arms = C.Gold, legs = C.Gold }, M.Foil)
		local scale = 1.7
		for _, part in statue:GetChildren() do
			if part:IsA("BasePart") then
				part.Size *= scale
			end
		end
		R6Pose.place(statue, home, {
			spine = { -24, side * 8, 0 }, neck = { 26, 0, 0 },
			shR = { 158, 0, 14 }, shL = { 150, 0, -18 },
			hipR = { -85, 0, 6 }, hipL = { -85, 0, -6 },
		}, scale)
	end
	local r = Kit.R
	for _ = 1, 50 do
		-- on the three front steps (their front edges are 9.5, 11.5 and 13.5 in front of the gate)
		local x, z = r:NextNumber(-21, 21), r:NextNumber(-13.4, -4)
		local y = (z < -11.5 and 1 or z < -9.5 and 2 or 3) + 0.12
		local p = (base * CFrame.new(x, y, z)).Position
		Kit.noShadow(Kit.cyl(m, "Coin", 0.22, 1.5, CFrame.new(p + Vector3.new(0, r:NextNumber(0, 0.3), 0)) * CFrame.Angles(r:NextNumber(-0.2, 0.2), r:NextNumber(0, 6), math.rad(90) + r:NextNumber(-0.2, 0.2)), C.Gold, M.Foil))
	end
	local label = Kit.box(m, "Label", Vector3.new(1, 1, 1), base * CFrame.new(0, 60, 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	Kit.nameplate(label, "alterGolden", "The Golden Encounter  -  Open", C.GoldPale, 2, 110, Kit.PLATE.Golden)
	return m
end

local function fallen(root, pos)
	local m = Kit.model(root, "FallenNoob")
	local base = facing(pos)
	local gate = Gates.place(m, "GateFallen", base, "Gate")
	local sea = Kit.rgb(70, 200, 225)
	local face = Gates.glow(gate, sea, 0.2, 40)
	if face then
		local spray = Instance.new("ParticleEmitter")
		spray.Name = "Spray"
		spray.Color = ColorSequence.new(Color3.new(1, 1, 1))
		spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
		spray.Lifetime = NumberRange.new(0.8, 1.4)
		spray.Rate = 14
		spray.Speed = NumberRange.new(4, 7)
		spray.SpreadAngle = Vector2.new(25, 25)
		spray.Acceleration = Vector3.new(0, -14, 0)
		spray.Parent = face
	end
	-- the lantern hanging at the bow, lit
	local lamp = Kit.noShadow(Kit.ball(m, "BowLamp", 1.2, (base * B(36, 0, 21.6)).Position, C.GoldPale, M.Neon, { CanCollide = false, CanQuery = false, CanTouch = false }))
	Kit.light(lamp, Kit.rgb(255, 210, 140), 22, 1)
	Gates.trigger(m, base * CFrame.new(0, 14, -7.5), Vector3.new(14, 20, 4), "Island")
	Kit.palm(m, (base * CFrame.new(-30, 1.6, 8)).Position, 32)
	Kit.palm(m, (base * CFrame.new(31, 1.2, 12)).Position, 26)
	Kit.palm(m, (base * CFrame.new(27, 1.0, -18)).Position, 20)
	local label = Kit.box(m, "Label", Vector3.new(1, 1, 1), base * CFrame.new(0, 54, 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	Kit.nameplate(label, "TheFallenNoob's Private Island", "Coming soon", Kit.rgb(200, 240, 250), 2, 110, Kit.PLATE.Island)
	return m
end

local function brothers(root, pos)
	local m = Kit.model(root, "JeffAndFred")
	local base = facing(pos)
	local gate = Gates.place(m, "GateBrothers", base, "Gate")
	local face = Gates.glow(gate, Kit.rgb(205, 205, 210), 0.35, 34)
	if face then
		-- petals, half white and half black, drifting off the blades
		local petals = Instance.new("ParticleEmitter")
		petals.Name = "Petals"
		petals.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.51, Color3.new(0.06, 0.06, 0.07)), ColorSequenceKeypoint.new(1, Color3.new(0.06, 0.06, 0.07)),
		})
		petals.Size = NumberSequence.new(0.5)
		petals.Lifetime = NumberRange.new(4, 6)
		petals.Rate = 10
		petals.Speed = NumberRange.new(1, 2.5)
		petals.SpreadAngle = Vector2.new(180, 180)
		petals.Acceleration = Vector3.new(0.6, -1.2, 0)
		petals.Rotation = NumberRange.new(0, 360)
		petals.RotSpeed = NumberRange.new(-120, 120)
		petals.Parent = face
	end
	Gates.trigger(m, base * CFrame.new(0, 11, -1.6), Vector3.new(16, 20, 3), "Forest")
	local label = Kit.box(m, "Label", Vector3.new(1, 1, 1), base * CFrame.new(0, 62, 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	Kit.nameplate(label, "Jeff n' Fred Bizzare Brother", "Coming soon", C.White, 2, 110, Kit.PLATE.Divided)
	return m
end

function Portals.Build(root, positions)
	local folder = Kit.folder(root, "Portals")
	midas(folder, positions.AlterGolden)
	fallen(folder, positions.FallenNoob)
	brothers(folder, positions.JeffAndFred)
	return folder
end

return Portals
