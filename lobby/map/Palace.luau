--!nonstrict
-- alterGolden's palace. Reached through the Midas portal; holds the four party portals (Workspace.PartyRooms.Room1..4 for PartyService).
-- A long black-and-gold hall on one axis: you arrive at the south end and the great door is the only thing you can look at.
local Kit = require(script.Parent.Kit)
local C, M = Kit.C, Kit.M

local Palace = {}
local O = Vector3.new(3000, -400, 0)
local W, L, H = 96, 240, 70 -- width, length, height

local function at(x, y, z)
	return O + Vector3.new(x, y, z)
end

local function stepped(m, x, z, width, depth, height, levels)
	-- an art-deco tower: each tier narrower and taller, like the reference hall
	for i = 0, levels - 1 do
		local w = width - i * (width / levels) * 0.75
		local h = height * (1 - i * 0.14)
		Kit.box(m, "Tier", Vector3.new(w, h, depth), CFrame.new(at(x, h / 2, z + i * 0.6)), i % 2 == 0 and C.GoldDeep or C.Gold, i % 2 == 0 and M.Metal or M.Foil)
	end
end

local function hall(m)
	Kit.box(m, "Floor", Vector3.new(W, 2, L), CFrame.new(at(0, -1, 0)), Kit.rgb(14, 12, 14), M.Marble, { Reflectance = 0.12 })
	Kit.box(m, "Ceiling", Vector3.new(W, 2, L), CFrame.new(at(0, H + 1, 0)), Kit.rgb(26, 20, 12), M.Metal)
	for _, side in { -1, 1 } do
		Kit.box(m, "Wall", Vector3.new(2, H, L), CFrame.new(at(side * (W / 2 + 1), H / 2, 0)), Kit.rgb(34, 26, 16), M.Metal)
	end
	Kit.box(m, "BackWall", Vector3.new(W, H, 2), CFrame.new(at(0, H / 2, -L / 2 - 1)), Kit.rgb(34, 26, 16), M.Metal)
	Kit.box(m, "EntryWall", Vector3.new(W, H, 2), CFrame.new(at(0, H / 2, L / 2 + 1)), Kit.rgb(34, 26, 16), M.Metal)
	-- gold inlay: a central runner and cross lines, all pointing at the door
	local line = C.Gold
	Kit.noShadow(Kit.box(m, "Runner", Vector3.new(1, 0.1, L - 20), CFrame.new(at(-13, 0.06, 0)), line, M.Metal))
	Kit.noShadow(Kit.box(m, "Runner", Vector3.new(1, 0.1, L - 20), CFrame.new(at(13, 0.06, 0)), line, M.Metal))
	for z = -100, 100, 20 do
		Kit.noShadow(Kit.box(m, "Cross", Vector3.new(26, 0.08, 0.5), CFrame.new(at(0, 0.05, z)), C.GoldDeep, M.Metal))
		Kit.noShadow(Kit.box(m, "Diamond", Vector3.new(5, 0.1, 5), CFrame.new(at(0, 0.06, z)) * CFrame.Angles(0, math.rad(45), 0), C.GoldDeep, M.Metal))
		Kit.noShadow(Kit.box(m, "DiamondIn", Vector3.new(3.2, 0.12, 3.2), CFrame.new(at(0, 0.07, z)) * CFrame.Angles(0, math.rad(45), 0), Kit.rgb(14, 12, 14), M.Marble))
	end
	-- rows of deco columns down both walls
	for z = -105, 105, 30 do
		for _, side in { -1, 1 } do
			local x = side * (W / 2 - 4)
			Kit.box(m, "Pilaster", Vector3.new(6, H, 8), CFrame.new(at(x, H / 2, z)), C.GoldDeep, M.Metal)
			for i = -1, 1 do
				Kit.box(m, "Flute", Vector3.new(1.2, H, 1.2), CFrame.new(at(x - side * 3.2, H / 2, z + i * 2.5)), C.Gold, M.Foil)
			end
			local glow = Kit.noShadow(Kit.box(m, "Sconce", Vector3.new(0.8, 7, 2), CFrame.new(at(x - side * 4.2, 28, z)), Kit.rgb(255, 200, 120), M.Neon))
			Kit.light(glow, Kit.rgb(255, 196, 110), 36, 0.8)
		end
	end
	-- ceiling coffers
	for z = -96, 96, 24 do
		Kit.box(m, "Coffer", Vector3.new(W, 3, 3), CFrame.new(at(0, H - 1.5, z)), C.GoldDeep, M.Metal)
	end
end

local function greatDoor(m)
	local z = -L / 2 + 8
	-- stairs
	for i = 0, 5 do
		Kit.box(m, "Stair", Vector3.new(50 - i * 4, 1.5, 22 - i * 3), CFrame.new(at(0, 0.75 + i * 1.5, z + 8 - i * 1.5)), i % 2 == 0 and C.GoldDeep or Kit.rgb(26, 20, 16), M.Marble)
	end
	local base = 9
	-- door leaves, with the king's mark
	Kit.box(m, "DoorFrame", Vector3.new(44, 44, 3), CFrame.new(at(0, base + 22, z - 6)), C.GoldDeep, M.Metal)
	for _, side in { -1, 1 } do
		Kit.box(m, "Leaf", Vector3.new(17.5, 37, 2), CFrame.new(at(side * 9, base + 18.5, z - 4.4)), C.Gold, M.Foil)
		for row = 0, 4 do
			Kit.box(m, "Panel", Vector3.new(12, 4.8, 0.6), CFrame.new(at(side * 9, base + 5 + row * 7, z - 3.2)), C.GoldDeep, M.Metal)
		end
	end
	Kit.box(m, "Seam", Vector3.new(0.5, 37, 2.4), CFrame.new(at(0, base + 18.5, z - 4.2)), Kit.rgb(40, 28, 14), M.Metal)
	Kit.wedge(m, "PedimentL", Vector3.new(4, 10, 24), CFrame.new(at(-12, base + 49, z - 6)) * CFrame.Angles(0, math.rad(-90), 0), C.Gold, M.Foil)
	Kit.wedge(m, "PedimentR", Vector3.new(4, 10, 24), CFrame.new(at(12, base + 49, z - 6)) * CFrame.Angles(0, math.rad(90), 0), C.Gold, M.Foil)
	-- the crown over the door, lit from below
	local crown = Kit.noShadow(Kit.box(m, "CrownGlow", Vector3.new(12, 1, 1), CFrame.new(at(0, base + 44, z - 3.5)), C.GoldPale, M.Neon))
	Kit.light(crown, Kit.rgb(255, 210, 130), 60, 2)
	-- stepped towers flanking the door, as in the reference
	for _, side in { -1, 1 } do
		stepped(m, side * 33, z + 6, 16, 8, 62, 4)
		-- gilded organ-pipe walls filling the corners
		for i = 0, 6 do
			local h = 30 + (6 - i) * 4
			Kit.column(m, "Pipe", at(side * (25 + i * 3.1), 0, z + 18), h, 2.4, C.Gold, M.Foil)
		end
	end
end

-- Chandeliers down the hall: a hoop of candles on a long chain.
local function chandeliers(m)
	for _, z in { -60, 0, 60 } do
		local c = at(0, 50, z)
		Kit.detail(Kit.box(m, "Chain", Vector3.new(0.4, H - 50, 0.4), CFrame.new(c + Vector3.new(0, (H - 50) / 2 + 2, 0)), C.GoldDeep, M.Metal))
		Kit.detail(Kit.ball(m, "Boss", 2.6, c + Vector3.new(0, 1.6, 0), C.Gold, M.Foil))
		Kit.ring(m, "Hoop", c, 16, 0.6, 0.6, 20, C.Gold, M.Foil)
		Kit.ring(m, "Hoop", c + Vector3.new(0, 3, 0), 9, 0.5, 0.5, 14, C.GoldDeep, M.Metal)
		for k = 1, 4 do
			local a = k / 4 * math.pi * 2
			local from, to = c + Vector3.new(0, 1.6, 0), c + Vector3.new(math.cos(a) * 8, 0.3, math.sin(a) * 8)
			Kit.detail(Kit.box(m, "Spoke", Vector3.new(0.3, 0.3, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), C.GoldDeep, M.Metal))
		end
		for k = 1, 12 do
			local a = k / 12 * math.pi * 2
			local p = c + Vector3.new(math.cos(a) * 8, 0.6, math.sin(a) * 8)
			Kit.detail(Kit.column(m, "Candle", p, 1.4, 0.45, Kit.rgb(250, 240, 220), M.SmoothPlastic))
			Kit.detail(Kit.ball(m, "Flame", 0.45, p + Vector3.new(0, 1.7, 0), Kit.rgb(255, 210, 130), M.Neon))
		end
		local glow = Kit.detail(Kit.box(m, "ChandelierLight", Vector3.new(1, 1, 1), CFrame.new(c - Vector3.new(0, 1, 0)), nil, nil, { Transparency = 1 }))
		Kit.light(glow, Kit.rgb(255, 200, 130), 48, 1.2)
	end
end

local function statues(m)
	-- gold busts on black plinths along the runner: everyone who ever knelt to him
	local r = Kit.R
	for _, z in { 72, 36, -36, -72 } do
		for _, side in { -1, 1 } do
			local x = side * 20
			Kit.box(m, "Plinth", Vector3.new(9, 8, 9), CFrame.new(at(x, 4, z)), Kit.rgb(20, 16, 14), M.Marble)
			Kit.noShadow(Kit.box(m, "PlinthTrim", Vector3.new(9.6, 0.6, 9.6), CFrame.new(at(x, 8, z)), C.Gold, M.Foil))
			local base = CFrame.lookAt(at(x, 8.3, z), at(0, 8.3, z))
			Kit.box(m, "BustChest", Vector3.new(7, 4, 3.4), base * CFrame.new(0, 2, 0), C.Gold, M.Foil)
			Kit.box(m, "BustNeck", Vector3.new(1.8, 1.4, 1.8), base * CFrame.new(0, 4.5, 0), C.Gold, M.Foil)
			local head = Kit.ball(m, "BustHead", 4.4, (base * CFrame.new(0, 7, 0)).Position, C.Gold, M.Foil)
			-- enough of a face to read as a person from down the hall: brow, nose, chin, and sloped shoulders
			Kit.noShadow(Kit.box(m, "BustBrow", Vector3.new(2.6, 0.5, 0.6), base * CFrame.new(0, 7.6, -1.95), C.GoldDeep, M.Foil))
			Kit.noShadow(Kit.box(m, "BustNose", Vector3.new(0.6, 1.1, 0.8), base * CFrame.new(0, 6.9, -2.15) * CFrame.Angles(math.rad(-12), 0, 0), C.Gold, M.Foil))
			Kit.noShadow(Kit.box(m, "BustChin", Vector3.new(1.4, 0.8, 0.8), base * CFrame.new(0, 5.6, -1.6), C.Gold, M.Foil))
			for _, s in { -1, 1 } do
				Kit.wedge(m, "BustShoulder", Vector3.new(3.4, 1.4, 1.8), base * CFrame.new(s * 1.8, 4.7, 0) * CFrame.Angles(0, s * math.rad(-90), 0), C.Gold, M.Foil)
			end
			if r:NextNumber() > 0.5 then
				-- a laurel wreath: leaves round the brow, open at the front
				for k = 1, 12 do
					local a = math.rad(-130 + (k - 1) * 260 / 11) -- 0 is the back of the head
					local spot = base * CFrame.new(math.sin(a) * 2.1, 7.7, math.cos(a) * 2.1)
					local p = spot.Position
					local tangent = (base * CFrame.new(math.sin(a + 0.1) * 2.1, 7.7, math.cos(a + 0.1) * 2.1)).Position - p
					Kit.noShadow(Kit.box(m, "Laurel", Vector3.new(0.35, 0.5, 1.3), CFrame.lookAt(p, p + tangent) * CFrame.Angles(0.35, 0, 0), C.GoldDeep, M.Metal))
				end
			end
		end
	end
end

-- Four gold doors, two each side. A Pad in front is where a party gathers; PartyService and PartyClient use these names.
local function partyPortals(m)
	local rooms = Instance.new("Folder")
	rooms.Name = "PartyRooms"
	rooms.Parent = workspace
	local spots = { { -1, 60 }, { 1, 60 }, { -1, -60 }, { 1, -60 } }
	for index, spot in spots do
		local side, z = spot[1], spot[2]
		local room = Kit.model(rooms, "Room" .. index)
		local x = side * 36
		local base = CFrame.lookAt(at(x, 0, z), at(0, 0, z))
		Kit.box(room, "Dais", Vector3.new(26, 1.2, 20), base * CFrame.new(0, 0.6, -3), Kit.rgb(26, 20, 16), M.Marble)
		for _, s in { -1, 1 } do
			Kit.box(room, "Jamb", Vector3.new(3.4, 26, 3.4), base * CFrame.new(s * 10, 13, 6), C.Gold, M.Foil)
		end
		Kit.box(room, "Head", Vector3.new(26, 3.4, 4.4), base * CFrame.new(0, 27.5, 6), C.GoldDeep, M.Metal)
		local face = Kit.box(room, "Console", Vector3.new(16.6, 24, 0.5), base * CFrame.new(0, 13, 6), C.Gold, M.Neon, { Transparency = 0.18, CanCollide = false })
		Kit.particles(face, C.GoldPale, 18, 2, 1.8, 0.8)
		Kit.light(face, Kit.rgb(255, 196, 110), 26, 1)
		local roster = Kit.box(room, "RosterDisplay", Vector3.new(12, 3, 0.5), base * CFrame.new(0, 31.5, 6), C.Ink, M.SmoothPlastic)
		Kit.sign(roster, Enum.NormalId.Back, "PORTAL " .. index, C.Gold, Enum.Font.Garamond, 0.4)
		local pad = Kit.disc(room, "Pad", (base * CFrame.new(0, 1.25, -5)).Position, 16, 0.5, C.GoldDeep, M.Metal)
		Kit.noShadow(Kit.disc(room, "PadRing", (base * CFrame.new(0, 1.35, -5)).Position, 13, 0.2, C.Gold, M.Foil))
		room.PrimaryPart = pad
	end
end

function Palace.Build(root)
	local m = Kit.folder(root, "Palace")
	local old = workspace:FindFirstChild("PartyRooms")
	if old then old:Destroy() end
	hall(m)
	greatDoor(m)
	statues(m)
	chandeliers(m)
	partyPortals(m)
	local arrive = CFrame.lookAt(at(0, 3.5, 100), at(0, 3.5, -100))
	Kit.arrival(m, arrive, 7).Name = "ArrivalPalace"
	-- the way back, behind where you arrive
	local exitCF = CFrame.lookAt(at(0, 11, L / 2 - 6), at(0, 11, 0))
	Kit.noShadow(Kit.cyl(m, "ExitFace", 0.4, 22, exitCF * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(140, 190, 255), M.Neon, { Transparency = 0.2 }))
	Kit.trigger(m, Vector3.new(20, 22, 4), exitCF * CFrame.new(0, 0, -1), "Hub")
	Kit.spinRing(m, exitCF * CFrame.new(0, 0, -0.5), 11.5, 26, C.GoldPale, M.Neon, 0.3)
	local nameplate = Kit.box(m, "ExitLabel", Vector3.new(1, 1, 1), exitCF * CFrame.new(0, -9, 0), nil, nil, { Transparency = 1, CanCollide = false })
	Kit.nameplate(nameplate, "Back to the Sanctum", "", C.White, 2, 60)
	return m
end

return Palace
