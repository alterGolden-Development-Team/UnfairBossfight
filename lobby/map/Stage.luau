--!nonstrict
-- The private showroom the shop fades to. Each client places its own dummy here (Showcase), so nobody sees anyone else's browsing.
local Kit = require(script.Parent.Kit)
local C, M = Kit.C, Kit.M

local Stage = {}
local O = Vector3.new(0, -400, -4000)
Stage.Origin = O

function Stage.Build(root)
	local m = Kit.folder(root, "Stage")
	Kit.disc(m, "Dais", O, 56, 3, Kit.rgb(26, 22, 22), M.Marble, { Reflectance = 0.1 })
	Kit.noShadow(Kit.disc(m, "Rim", O + Vector3.new(0, 0.06, 0), 54, 0.1, C.GoldDeep, M.Metal))
	Kit.noShadow(Kit.disc(m, "RimIn", O + Vector3.new(0, 0.12, 0), 51, 0.1, Kit.rgb(26, 22, 22), M.Marble))
	Kit.box(m, "Backdrop", Vector3.new(160, 90, 2), CFrame.new(O + Vector3.new(0, 44, -38)), Kit.rgb(16, 12, 14), M.Fabric)
	Kit.box(m, "FloorFar", Vector3.new(220, 2, 220), CFrame.new(O + Vector3.new(0, -5, 0)), Kit.rgb(10, 8, 10), M.Slate)
	for _, x in { -46, -30, 30, 46 } do
		Kit.box(m, "Pillar", Vector3.new(7, 70, 7), CFrame.new(O + Vector3.new(x, 32, -30)), C.GoldDeep, M.Metal)
		local glow = Kit.noShadow(Kit.box(m, "Glow", Vector3.new(1, 22, 1), CFrame.new(O + Vector3.new(x, 26, -26.4)), C.GoldPale, M.Neon))
		Kit.light(glow, Kit.rgb(255, 196, 120), 40, 1.2)
	end
	local key = Kit.box(m, "KeyLight", Vector3.new(1, 1, 1), CFrame.new(O + Vector3.new(0, 26, 14)), nil, nil, { Transparency = 1, CanCollide = false })
	local spot = Instance.new("SpotLight")
	spot.Brightness, spot.Range, spot.Angle = 7, 60, 50
	spot.Color = Kit.rgb(255, 232, 196)
	spot.Face = Enum.NormalId.Bottom
	spot.Parent = key
	local anchor = Kit.box(m, "DummySpot", Vector3.new(1, 1, 1), CFrame.lookAt(O + Vector3.new(0, 0.2, 0), O + Vector3.new(0, 0.2, 40)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	anchor:SetAttribute("Stage", true)
	return m
end

return Stage
