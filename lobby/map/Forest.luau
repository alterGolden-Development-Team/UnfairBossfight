--!nonstrict
-- The black-and-white forest (Jeff n' Fred). The world is split down the path: white ground with black trees on one side, black ground with
-- white trees on the other. Walking the path leads to The Cut, a clearing where the two brothers fight forever. A trigger there starts a
-- short cutscene (AreaClient). The client also drains all colour from the screen here.
local Kit = require(script.Parent.Kit)
local C, M = Kit.C, Kit.M

local Forest = {}
local O = Vector3.new(0, -400, 4000)

local function at(x, y, z)
	return O + Vector3.new(x, y, z)
end

local function bareTree(parent, base, height, color, material, leafColor)
	local m = Kit.model(parent, "Tree")
	local r = Kit.R
	local p = base
	local lean = Vector3.new(r:NextNumber(-3, 3), 0, r:NextNumber(-3, 3))
	local top
	for i = 1, 4 do
		local t = i / 4
		local nextP = base + Vector3.new(0, height * t, 0) + lean * (t * t)
		local width = height * 0.05 * (1.25 - t * 0.7)
		Kit.box(m, "Trunk", Vector3.new(width, (nextP - p).Magnitude + 0.5, width), CFrame.lookAt((p + nextP) / 2, nextP) * CFrame.Angles(math.rad(90), 0, 0), color, material)
		p = nextP
		top = nextP
	end
	-- jagged branches and a thin pointed canopy
	for i = 1, 5 do
		local a = i / 5 * 6.28 + r:NextNumber(-0.4, 0.4)
		local h = height * r:NextNumber(0.45, 0.95)
		local from = base + Vector3.new(0, h, 0) + lean * ((h / height) ^ 2)
		local to = from + Vector3.new(math.cos(a), r:NextNumber(0.25, 0.8), math.sin(a)) * height * r:NextNumber(0.2, 0.36)
		Kit.noShadow(Kit.box(m, "Branch", Vector3.new(0.7, 0.7, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material))
	end
	for i = 1, 3 do
		local y = top + Vector3.new(0, (i - 2) * height * 0.13, 0)
		local d = height * (0.46 - i * 0.08)
		Kit.noShadow(Kit.ball(m, "Leaves", d, y + Vector3.new(r:NextNumber(-2, 2), 0, r:NextNumber(-2, 2)), leafColor, M.Slate))
	end
	return m
end

local function ground(m)
	local length = 620
	local centerZ = -250
	Kit.box(m, "WhiteGround", Vector3.new(420, 4, length), CFrame.new(at(-210, -2, centerZ)), C.White, M.Marble)
	Kit.box(m, "BlackGround", Vector3.new(420, 4, length), CFrame.new(at(210, -2, centerZ)), C.Black, M.Slate)
	-- the path follows the seam
	local r = Kit.R
	for z = 40, -350, -7 do
		local jitter = math.sin(z * 0.03) * 1.4
		Kit.noShadow(Kit.box(m, "PathLeft", Vector3.new(4, 0.3, 6.6), CFrame.new(at(-2 + jitter, 0.1, z)) * CFrame.Angles(0, r:NextNumber(-0.08, 0.08), 0), Kit.rgb(70, 70, 72), M.Slate))
		Kit.noShadow(Kit.box(m, "PathRight", Vector3.new(4, 0.3, 6.6), CFrame.new(at(2 + jitter, 0.1, z)) * CFrame.Angles(0, r:NextNumber(-0.08, 0.08), 0), Kit.rgb(190, 190, 192), M.Marble))
	end
end

local function trees(m)
	local f = Kit.folder(m, "Trees")
	local r = Kit.R
	for _ = 1, 240 do
		local side = r:NextNumber() > 0.5 and 1 or -1
		local x = side * r:NextNumber(11, 190)
		local z = r:NextNumber(-500, 60)
		local inClearing = (Vector2.new(x, z + 400)).Magnitude < 78
		if not inClearing then
			local height = r:NextNumber(34, 66)
			if side < 0 then
				bareTree(f, at(x, 0, z), height, C.Black, M.Slate, Kit.rgb(26, 26, 30))
			else
				bareTree(f, at(x, 0, z), height, C.White, M.Marble, Kit.rgb(226, 226, 230))
			end
		end
	end
end

local function clearing(m)
	local center = at(0, 0, -400)
	Kit.box(m, "CutWhite", Vector3.new(74, 1, 148), CFrame.new(center + Vector3.new(-37, 0.1, 0)), C.White, M.Marble)
	Kit.box(m, "CutBlack", Vector3.new(74, 1, 148), CFrame.new(center + Vector3.new(37, 0.1, 0)), C.Black, M.Slate)
	-- a slash scorched through the seam: the cut itself
	Kit.noShadow(Kit.box(m, "TheCut", Vector3.new(1.6, 0.2, 110), CFrame.new(center + Vector3.new(0, 0.72, 0)) * CFrame.Angles(0, math.rad(8), 0), C.Black, M.Neon))
	-- the brothers: statues in shape, animated by the client
	local fight = Kit.model(m, "TheFight")
	Kit.figure(fight, "Jeff", CFrame.lookAt(center + Vector3.new(-9, 0.6, 0), center + Vector3.new(0, 0.6, 0)), C.Black, M.Slate, 1.7)
	Kit.figure(fight, "Fred", CFrame.lookAt(center + Vector3.new(9, 0.6, 0), center + Vector3.new(0, 0.6, 0)), C.White, M.Marble, 1.7)
	local trigger = Kit.box(m, "CutTrigger", Vector3.new(80, 20, 10), CFrame.new(center + Vector3.new(0, 10, 66)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	trigger:SetAttribute("Cut", true)
	-- four portals behind the fight, on the far edge of the clearing
	local spots = { -48, -16, 16, 48 }
	for i, x in spots do
		local m2 = Kit.model(m, "Portal" .. i)
		local color, other = x < 0 and C.White or C.Black, x < 0 and C.Black or C.White
		local material = x < 0 and M.Marble or M.Slate
		local base = CFrame.lookAt(center + Vector3.new(x, 0.6, -58), center + Vector3.new(x * 0.5, 0.6, 40))
		local ringCenter = base * CFrame.new(0, 12, 0)
		for k = 1, 20 do
			local a = k / 20 * 6.28
			local onOther = k % 2 == 0
			Kit.box(m2, "RingSlab", Vector3.new(2.6, 2.2, 3), ringCenter * CFrame.new(math.cos(a) * 10, math.sin(a) * 10, 0) * CFrame.Angles(0, 0, a), onOther and other or color, material)
		end
		local face = Kit.cyl(m2, "Face", 0.4, 18, ringCenter * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(128, 128, 132), M.Neon, { Transparency = 0.3, CanCollide = false })
		Kit.particles(face, Color3.new(1, 1, 1), 12, 2, 1.6, 0.7)
		Kit.nameplate(face, "Portal " .. i, "Coming soon", C.White, 13, 70)
		face:SetAttribute("ComingSoon", "JeffAndFred")
		Kit.tag(face, "UnfairComingSoon")
	end
end

function Forest.Build(root)
	local m = Kit.folder(root, "Forest")
	ground(m)
	trees(m)
	clearing(m)
	Kit.arrival(m, CFrame.lookAt(at(0, 3.5, 44), at(0, 3.5, -300)), 6).Name = "ArrivalForest"
	-- the way back, beside the arrival point
	local exitCF = CFrame.lookAt(at(0, 9, 66), at(0, 9, 0))
	Kit.noShadow(Kit.cyl(m, "ExitFace", 0.4, 18, exitCF * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(200, 200, 205), M.Neon, { Transparency = 0.2 }))
	Kit.trigger(m, Vector3.new(16, 18, 4), exitCF * CFrame.new(0, 0, -1), "Hub")
	local label = Kit.box(m, "ExitLabel", Vector3.new(1, 1, 1), exitCF * CFrame.new(0, -7, 0), nil, nil, { Transparency = 1, CanCollide = false })
	Kit.nameplate(label, "Back to the Sanctum", "", C.White, 2, 60)
	return m
end

return Forest
