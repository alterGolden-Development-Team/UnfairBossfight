


local Geometry = {}

 
local ARC_A, ARC_B = 32, 21       
local BASE_V = 27                 
local PHI_MAX = 1.22              
local BASE_WIDTH = 13             
local SPINE, EDGE = 0.56, 0.44    
local HOLE_A, HOLE_B = 0.14, 0.52  

local function width(t)
	return BASE_WIDTH * (1 - t) ^ 0.75
end

 
local function sample(t, offset)
	local phi = t * PHI_MAX
	local px, py = ARC_A * math.sin(phi), BASE_V - ARC_B * (1 - math.cos(phi))
	local tx, ty = ARC_A * math.cos(phi), -ARC_B * math.sin(phi)
	local len = math.sqrt(tx * tx + ty * ty)
	tx, ty = tx / len, ty / len
	local nx, ny = -ty, tx
	return { px + nx * offset, py + ny * offset }, tx, ty, nx, ny
end

local function spine(t) return (sample(t, width(t) * SPINE)) end
local function edge(t) return (sample(t, -width(t) * EDGE)) end

 
local function holeHalf(t)
	local s = (t - HOLE_A) / (HOLE_B - HOLE_A)
	local shape
	if s < 0.32 then
		local k = (0.32 - s) / 0.32
		shape = math.sqrt(math.max(0, 1 - k * k))
	else
		shape = 1 - ((s - 0.32) / 0.68) ^ 1.3
	end
	return 0.27 * width(t) * math.max(shape, 0)
end
local function holeTop(t) return (sample(t, width(t) * 0.05 + holeHalf(t))) end
local function holeBottom(t) return (sample(t, width(t) * 0.05 - holeHalf(t))) end

local function area(a, b, c)
	return math.abs((b[1] - a[1]) * (c[2] - a[2]) - (c[1] - a[1]) * (b[2] - a[2])) * 0.5
end

 
function Geometry.Build(detail)
	detail = detail or 1
	local function steps(n) return math.max(2, math.floor(n * detail + 0.5)) end
	local tris = {}

	local function tri(a, b, c, thick, kind)
		if area(a, b, c) < 0.02 then return end  
		table.insert(tris, { a, b, c, thick, kind })
	end
	local function thick(t) return 1.25 - 0.9 * t end

	 
	local function strip(fa, fb, t0, t1, n)
		local pa, pb = fa(t0), fb(t0)
		for i = 1, n do
			local t = t0 + (t1 - t0) * i / n
			local qa, qb = fa(t), fb(t)
			local th = thick(t - (t1 - t0) / (2 * n))
			tri(pa, pb, qa, th, "body")
			tri(pb, qb, qa, th, "body")
			pa, pb = qa, qb
		end
	end

	strip(spine, edge, 0, HOLE_A, steps(3))               
	strip(spine, holeTop, HOLE_A, HOLE_B, steps(7))       
	strip(holeBottom, edge, HOLE_A, HOLE_B, steps(7))     
	strip(spine, edge, HOLE_B, 1, steps(9))               

	 
	tri({ 0, BASE_V + 7.2 }, { 0, BASE_V + 0.5 }, { -11, BASE_V + 13 }, 1.0, "horn")
	tri({ 0, BASE_V - 2 }, { 0, BASE_V - 5.5 }, { -8, BASE_V - 10 }, 0.9, "horn")

	 
	for _, t in ipairs({ 0.56, 0.65, 0.73, 0.81, 0.89 }) do
		local p, tx, ty, nx, ny = sample(t, width(t) * SPINE)
		local len = 6.2 * (1 - t) ^ 0.45 + 1
		local a = spine(t - 0.04)
		local b = spine(t + 0.035)
		local tip = { p[1] + nx * len * 0.75 - tx * len * 1.15, p[2] + ny * len * 0.75 - ty * len * 1.15 }
		tri(a, b, tip, 0.7, "barb")
	end

	 
	local edgeLine, rimTop, rimBottom = {}, {}, {}
	local nEdge, nRim = steps(18), steps(8)
	for i = 0, nEdge do table.insert(edgeLine, edge(0.99 * i / nEdge)) end
	for i = 0, nRim do
		local t = HOLE_A + (HOLE_B - HOLE_A) * i / nRim
		table.insert(rimTop, holeTop(t))
		table.insert(rimBottom, holeBottom(t))
	end

	return {
		Triangles = tris,
		EdgeLine = edgeLine,
		RimTop = rimTop,
		RimBottom = rimBottom,
		Tip = edge(1),
		TrailBack = spine(0.62),
		BladeBase = { 0, BASE_V },
		DripPoints = { edge(0.35), edge(0.6), edge(0.82) },
		MistPoint = sample(0.5, 0),
	}
end

return Geometry

