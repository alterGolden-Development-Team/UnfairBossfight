 
local Visuals = {}
function Visuals.buildBox(ctx)
	local part = ctx.part
	local BOX_AWAY = ctx.BOX_AWAY
	local PANEL = ctx.PANEL
	local GOLD = ctx.GOLD
	local FX = ctx.FX
	local DEEP = ctx.DEEP
	local GEM = ctx.GEM
	local function buildBox(center, facing, width, height)
		local pivot = CFrame.lookAt(center, center + facing)
		local hw, hh = width / 2, height / 2
		local bits, edges = {}, {}
		local function add(name, offset, size, color, alpha, material, shape, edge)
			local piece = part(name, pivot * offset, size, color, 1)
			piece.Material = material or Enum.Material.Neon
			if shape then
				piece.Shape = shape
			end
			local position = offset.Position
			local bit = {
				Part = piece,
				Offset = offset,
				Alpha = alpha,
				Away = position.Magnitude > 0.01 and position.Unit * BOX_AWAY or Vector3.zero,
			}
			bits[#bits + 1] = bit
			if edge then
				edges[#edges + 1] = bit
			end
		end
		 
		for _, side in ipairs({ -1, 1 }) do
			add(
				"P3DashBoxWall",
				CFrame.new(0, 0, side * hw),
				Vector3.new(width, height, 0.35),
				PANEL,
				0.55,
				Enum.Material.SmoothPlastic
			)
			add(
				"P3DashBoxWall",
				CFrame.new(side * hw, 0, 0),
				Vector3.new(0.35, height, width),
				PANEL,
				0.55,
				Enum.Material.SmoothPlastic
			)
		end
		add(
			"P3DashBoxLid",
			CFrame.new(0, hh, 0),
			Vector3.new(width, 0.45, width),
			PANEL,
			0.4,
			Enum.Material.SmoothPlastic
		)
		add(
			"P3DashBoxFloor",
			CFrame.new(0, -hh + 0.15, 0),
			Vector3.new(width, 0.3, width),
			PANEL,
			0.35,
			Enum.Material.SmoothPlastic
		)
		 
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				add(
					"P3DashBoxEdge",
					CFrame.new(0, sy * hh, sz * hw),
					Vector3.new(width + 0.5, 0.5, 0.5),
					GOLD,
					0.05,
					nil,
					nil,
					true
				)
				add(
					"P3DashBoxEdge",
					CFrame.new(sz * hw, sy * hh, 0),
					Vector3.new(0.5, 0.5, width + 0.5),
					GOLD,
					0.05,
					nil,
					nil,
					true
				)
			end
		end
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				add(
					"P3DashBoxPillar",
					CFrame.new(sx * hw, 0, sz * hw),
					Vector3.new(0.5, height + 0.5, 0.5),
					GOLD,
					0.05,
					nil,
					nil,
					true
				)
			end
		end
		if FX.SwordDetail >= 2 then
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						add(
							"P3DashBoxCorner",
							CFrame.new(sx * hw, sy * hh, sz * hw),
							Vector3.one * 0.95,
							DEEP,
							0,
							Enum.Material.Metal,
							Enum.PartType.Ball
						)
					end
				end
			end
			 
			for _, side in ipairs({ -1, 1 }) do
				add(
					"P3DashBoxEmblem",
					CFrame.new(0, 0, side * (hw + 0.22)) * CFrame.Angles(0, 0, math.pi / 4),
					Vector3.new(1.8, 1.8, 0.12),
					GOLD,
					0.15
				)
				add(
					"P3DashBoxEmblem",
					CFrame.new(side * (hw + 0.22), 0, 0)
						* CFrame.Angles(0, math.pi / 2, 0)
						* CFrame.Angles(0, 0, math.pi / 4),
					Vector3.new(1.8, 1.8, 0.12),
					GOLD,
					0.15
				)
			end
			add(
				"P3DashBoxGem",
				CFrame.new(0, hh + 0.8, 0),
				Vector3.one * 1.1,
				GEM,
				0,
				Enum.Material.Neon,
				Enum.PartType.Ball
			)
		end
		return {
			Pivot = pivot,
			Bits = bits,
			Edges = edges,
			Center = center,
			HalfW = hw,
			HalfH = hh,
			Floor = Vector3.new(center.X, center.Y - hh - 0.25, center.Z),
		}
	end
	return buildBox
end
function Visuals.placeBox(ctx)
	local function placeBox(box, progress, shake)
		local parts, frames, count = {}, {}, 0
		local base = CFrame.new(shake or Vector3.zero) * box.Pivot
		for _, bit in ipairs(box.Bits) do
			if bit.Part.Parent then
				count += 1
				parts[count] = bit.Part
				frames[count] = base
					* CFrame.new(bit.Offset.Position + bit.Away * (1 - progress))
					* bit.Offset.Rotation
			end
		end
		if count > 0 then
			workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
	return placeBox
end
function Visuals.flashEdges(ctx)
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local GOLD = ctx.GOLD
	local function flashEdges(box, duration)
		for _, bit in ipairs(box.Edges) do
			if bit.Part.Parent then
				bit.Part.Color = WHITE
				Effects:Create(bit.Part, TweenInfo.new(duration), { Color = GOLD }):Play()
			end
		end
	end
	return flashEdges
end
function Visuals.boxExit(ctx)
	local function boxExit(box, point, dir)
		local rel = box.Pivot:PointToObjectSpace(point)
		local d = box.Pivot:VectorToObjectSpace(dir)
		local half = { box.HalfW, box.HalfH, box.HalfW }
		local relA, dA = { rel.X, rel.Y, rel.Z }, { d.X, d.Y, d.Z }
		local best = math.huge
		for axis = 1, 3 do
			local component = dA[axis]
			if math.abs(component) > 0.0001 then
				local t = ((component > 0 and half[axis] or -half[axis]) - relA[axis]) / component
				if t >= 0 and t < best then
					best = t
				end
			end
		end
		if best == math.huge then
			best = box.HalfW
		end
		return point + dir * best
	end
	return boxExit
end
return table.freeze(Visuals)
