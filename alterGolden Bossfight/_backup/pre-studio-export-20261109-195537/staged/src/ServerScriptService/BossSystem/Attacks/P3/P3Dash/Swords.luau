 
local Visuals = {}
function Visuals.buildSword(ctx)
	local part = ctx.part
	local SWORD = ctx.SWORD
	local STEEL = ctx.STEEL
	local GOLD = ctx.GOLD
	local DEEP = ctx.DEEP
	local GEM = ctx.GEM
	local GRIP = ctx.GRIP
	local FX = ctx.FX
	local WHITE = ctx.WHITE
	local function buildSword(index, tip, up, rotation, hover)
		local pivot = CFrame.new(tip + up * hover) * rotation
		local bits = {}
		local function add(name, offset, size, color, alpha, material, shape)
			local piece = part(name, pivot * offset, size, color, 1)
			piece.Material = material or Enum.Material.Neon
			if shape then
				piece.Shape = shape
			end
			bits[#bits + 1] = { Part = piece, Offset = offset, Alpha = alpha }
			return piece
		end
		local top, start = SWORD.Top, SWORD.BladeStart
		local body = top - start
		 
		add(
			"P3DashBlade",
			CFrame.new(0, start + body / 2, 0),
			Vector3.new(1.05, body, 0.26),
			STEEL,
			0.02,
			Enum.Material.Metal
		)
		for step, width in ipairs(SWORD.Taper) do
			add(
				"P3DashBladePoint",
				CFrame.new(0, start - (step - 0.5) * SWORD.TaperStep, 0),
				Vector3.new(width, SWORD.TaperStep * 1.04, 0.25 - step * 0.016),
				STEEL,
				0.02,
				Enum.Material.Metal
			)
		end
		 
		add(
			"P3DashFuller",
			CFrame.new(0, start + body * 0.5 + 0.4, 0),
			Vector3.new(0.24, body * 0.78, 0.33),
			GOLD,
			0.04
		)
		 
		add(
			"P3DashGuard",
			CFrame.new(0, top + 0.3, 0),
			Vector3.new(4.8, 0.55, 0.85),
			DEEP,
			0,
			Enum.Material.Metal
		)
		for _, side in ipairs({ -1, 1 }) do
			add(
				"P3DashGuardWing",
				CFrame.new(side * 2.55, top + 0.68, 0) * CFrame.Angles(0, 0, side * 0.55),
				Vector3.new(1, 0.5, 0.7),
				DEEP,
				0,
				Enum.Material.Metal
			)
		end
		add(
			"P3DashGem",
			CFrame.new(0, top + 0.3, 0),
			Vector3.one,
			GEM,
			0,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		 
		add(
			"P3DashGrip",
			CFrame.new(0, top + 2.25, 0),
			Vector3.new(0.42, 3.3, 0.42),
			GRIP,
			0,
			Enum.Material.SmoothPlastic
		)
		add(
			"P3DashPommel",
			CFrame.new(0, top + 4.4, 0),
			Vector3.one * 1.05,
			DEEP,
			0,
			Enum.Material.Metal,
			Enum.PartType.Ball
		)
		if FX.SwordDetail >= 2 then
			for _, side in ipairs({ -1, 1 }) do
				 
				add(
					"P3DashEdge",
					CFrame.new(side * 0.5, start + body / 2, 0),
					Vector3.new(0.09, body, 0.31),
					WHITE,
					0.05
				)
				add(
					"P3DashGuardCap",
					CFrame.new(side * 2.4, top + 0.3, 0),
					Vector3.one * 0.6,
					GOLD,
					0.05,
					Enum.Material.Neon,
					Enum.PartType.Ball
				)
			end
			for band = 0, 2 do
				add(
					"P3DashGripBand",
					CFrame.new(0, top + 1.35 + band * 0.9, 0),
					Vector3.new(0.64, 0.16, 0.64),
					DEEP,
					0,
					Enum.Material.Metal
				)
			end
			 
			add("P3DashAura", CFrame.new(0, start + body / 2, 0), Vector3.new(1.9, body + 0.4, 1), GOLD, 0.88)
		end
		return { Index = index, Tip = tip, Up = up, Rotation = rotation, Hover = hover, Bits = bits }
	end
	return buildSword
end
function Visuals.placeSwords(ctx)
	local function placeSwords(list, distanceOf)
		local parts, frames, count = {}, {}, 0
		for _, entry in ipairs(list) do
			local pivot = CFrame.new(entry.Tip + entry.Up * distanceOf(entry)) * entry.Rotation
			for _, bit in ipairs(entry.Bits) do
				if bit.Part.Parent then
					count += 1
					parts[count] = bit.Part
					frames[count] = pivot * bit.Offset
				end
			end
		end
		if count > 0 then
			workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
	return placeSwords
end
function Visuals.swordDirection(ctx)
	local function swordDirection(index, count, toBoss)
		local f = (index - 0.5) / count
		local y = 0.96 - 0.8 * f
		local radius = math.sqrt(1 - y * y)
		local angle = index * 2.39996 + 0.4
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		if y < 0.7 and (x * toBoss.X + z * toBoss.Z) > radius * 0.8 then
			x, z = -x, -z
		end
		return Vector3.new(x, y, z)
	end
	return swordDirection
end
return table.freeze(Visuals)
