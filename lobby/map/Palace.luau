--!nonstrict
-- alterGolden's palace. Reached through the Midas portal; holds the four party portals (Workspace.PartyRooms.Room1..4 for PartyService).
-- A long black-and-gold art-deco hall on one axis: you arrive at the south end and the great door is the only thing you can look at.
-- The architecture is Blender meshes (lobby/blender/palace.py, kit "Palace" in Assets.luau): the hall shell, the party gates, the
-- chandeliers and the urns. This file places them and adds what has to be live: lights, fire, the party pads and the way back.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local Gates = require(script.Parent.Gates)
local C, M = Kit.C, Kit.M

local Palace = {}
local O = Vector3.new(3000, -400, 0)
local W, L, H = 96, 240, 70 -- width, length, height (the vault's crown); must match palace.py

local function at(x, y, z)
	return O + Vector3.new(x, y, z)
end

local function place(parent, piece, cf, name)
	local model = Assets.Get(piece)
	model:PivotTo(cf)
	model.Name = name or piece
	model.Parent = parent
	return model
end

local function glow(parent, name, pos, color, range, brightness)
	local p = Kit.detail(Kit.box(parent, name, Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), nil, nil, { Transparency = 1, CanQuery = false, CanTouch = false }))
	Kit.light(p, color, range, brightness)
	return p
end

local function hall(m)
	place(m, "PalaceHall", CFrame.new(O), "Hall")
	-- flames in the torch cups on every pilaster (cups at 4.6 in from the wall, 28.6 up; pilasters every 30 from z = -105)
	for z = -105, 105, 30 do
		for _, side in { -1, 1 } do
			local p = Kit.detail(Kit.box(m, "TorchFlame", Vector3.new(0.6, 0.6, 0.6), CFrame.new(at(side * (W / 2 - 4.6), 29.2, z)), nil, nil, { Transparency = 1, CanQuery = false, CanTouch = false }))
			local fire = Instance.new("Fire")
			fire.Size, fire.Heat = 2.2, 6
			fire.Color, fire.SecondaryColor = Kit.rgb(255, 170, 60), Kit.rgb(255, 230, 140)
			fire.Parent = p
			Kit.light(p, Kit.rgb(255, 190, 110), 30, 0.9)
		end
	end
	-- the sun over the great door, lit from in front
	glow(m, "SunGlow", at(0, 47, -L / 2 + 10), Kit.rgb(255, 210, 130), 60, 2)
end

-- Gold urns burning on black pedestals down the runner, between the party gates (at z = +-60) so they never crowd a pad.
-- The bowl's rim is 15 up.
local function urns(m)
	for _, z in { 96, 30, -30, -96 } do
		for _, side in { -1, 1 } do
			local pos = at(side * 18, 0, z)
			place(m, "PalaceUrn", CFrame.new(pos), "Urn")
			local p = Kit.detail(Kit.box(m, "UrnFire", Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(0, 15, 0)), nil, nil, { Transparency = 1, CanQuery = false, CanTouch = false }))
			local fire = Instance.new("Fire")
			fire.Size, fire.Heat = 6, 10
			fire.Color, fire.SecondaryColor = Kit.rgb(255, 150, 40), Kit.rgb(255, 220, 120)
			fire.Parent = p
			Kit.light(p, Kit.rgb(255, 180, 90), 34, 1.2)
		end
	end
end

-- Chandeliers hang from the vault's crown on three of its gold ribs.
local function chandeliers(m)
	for _, z in { -60, 0, 60 } do
		place(m, "PalaceChandelier", CFrame.new(at(0, H, z)), "Chandelier")
		glow(m, "ChandelierLight", at(0, H - 18, z), Kit.rgb(255, 200, 130), 56, 1.4)
	end
end

-- Four gold gates, two each side. A Pad in front is where a party gathers; PartyService and PartyClient use these names.
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
		Kit.noShadow(Kit.box(room, "DaisTrim", Vector3.new(26.4, 0.2, 20.4), base * CFrame.new(0, 1.15, -3), C.GoldDeep, M.Metal))
		-- the gate: a baroque gold frame on twisted columns; its glowing face is the portal (no separate slab poking through)
		local gate = Gates.place(room, "GateParty", base * CFrame.new(0, 1.2, 6), "Gate")
		local face = Gates.glow(gate, Kit.rgb(255, 190, 90), 0.2, 26)
		if face then
			face.Name = "Console"
		end
		local roster = Kit.box(room, "RosterDisplay", Vector3.new(12, 3, 0.5), base * CFrame.new(0, 28.0, 3.5), C.Ink, M.SmoothPlastic)
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
	urns(m)
	chandeliers(m)
	partyPortals(m)
	local arrive = CFrame.lookAt(at(0, 3.5, 100), at(0, 3.5, -100))
	Kit.arrival(m, arrive, 7).Name = "ArrivalPalace"
	-- the way back: the winged return gate, behind where you arrive, under the round gold frame on the entry wall
	Gates.returnGate(m, CFrame.lookAt(at(0, 0, L / 2 - 8), at(0, 0, 0)), "GateReturnPalace")
	return m
end

return Palace
