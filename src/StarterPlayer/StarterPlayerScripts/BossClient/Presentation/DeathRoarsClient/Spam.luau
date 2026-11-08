 
 
 
 
 
local Run = game:GetService("RunService")
local Players = game:GetService("Players")
local Spam = {}

local WHITE = Color3.fromRGB(255, 252, 235)
local YELLOW = Color3.fromRGB(255, 214, 50)
local GOLD = Color3.fromRGB(255, 160, 20)
local NK, CK = NumberSequenceKeypoint.new, ColorSequenceKeypoint.new
local CORE_COLOR = ColorSequence.new({ CK(0, YELLOW), CK(0.5, WHITE), CK(1, YELLOW) })
local GLOW_COLOR = ColorSequence.new({ CK(0, GOLD), CK(0.5, YELLOW), CK(1, GOLD) })
local TAPER = NumberSequence.new({ NK(0, 1), NK(0.1, 0.15), NK(0.5, 0), NK(0.9, 0.15), NK(1, 1) })
local SOFT_TAPER = NumberSequence.new({ NK(0, 1), NK(0.15, 0.5), NK(0.5, 0.3), NK(0.85, 0.5), NK(1, 1) })
local GLOW_TAPER = NumberSequence.new({ NK(0, 1), NK(0.5, 0.55), NK(1, 1) })
local MAX_EFFECTS = 1500

local rng = Random.new()
local live = {}
local pool = {}
local KINDS = { "Swirl", "Near", "ArenaCrescent", "ArenaCut", "Streak" }
local rates, carry = {}, {}
for _, kind in ipairs(KINDS) do rates[kind], carry[kind] = 0, 0 end
local arena  
local density = 1
local connection
local frozenAt  

local function randomUnit()
	local z = rng:NextNumber(-1, 1)
	local a = rng:NextNumber(0, math.pi * 2)
	local r = math.sqrt(1 - z * z)
	return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end
local function newBeam(a0, a1, color, alpha)
	local b = Instance.new("Beam")
	b.Name = "DeathRoarsSpam"
	b.Attachment0, b.Attachment1 = a0, a1
	b.FaceCamera = true
	b.Color, b.Transparency = color, alpha
	b.LightEmission, b.LightInfluence, b.Brightness = 1, 0, 4
	b.Width0, b.Width1 = 0, 0
	b.Enabled = false
	b.Parent = workspace.Terrain
	return b
end
 
local function acquire()
	local slot = table.remove(pool)
	if not slot then
		local a0 = Instance.new("Attachment")
		a0.Name = "DeathRoarsSpam"
		a0.Parent = workspace.Terrain
		local a1 = Instance.new("Attachment")
		a1.Name = "DeathRoarsSpam"
		a1.Parent = workspace.Terrain
		slot = { A0 = a0, A1 = a1, Core = newBeam(a0, a1, CORE_COLOR, TAPER), Glow = newBeam(a0, a1, GLOW_COLOR, GLOW_TAPER) }
	end
	return slot
end
local function release(slot)
	slot.Core.Enabled, slot.Glow.Enabled = false, false
	table.insert(pool, slot)
end
local function destroySlot(slot)
	slot.Core:Destroy()
	slot.Glow:Destroy()
	slot.A0:Destroy()
	slot.A1:Destroy()
end

local function start(slot, effect, curve, segments, glow, soft)
	slot.Core.CurveSize0, slot.Core.CurveSize1 = curve, -curve
	slot.Glow.CurveSize0, slot.Glow.CurveSize1 = curve, -curve
	slot.Core.Segments, slot.Glow.Segments = segments, segments
	slot.Core.Transparency = soft and SOFT_TAPER or TAPER
	slot.Core.Width0, slot.Core.Width1, slot.Glow.Width0, slot.Glow.Width1 = 0, 0, 0, 0
	slot.Core.Enabled = true
	slot.Glow.Enabled = glow
	effect.Slot = slot
	effect.Born = os.clock()
	table.insert(live, effect)
end

 
local function crescent(center, radius, width, life, glow, soft)
	if #live >= MAX_EFFECTS then return end
	local u = randomUnit()
	local n = randomUnit()
	n = n - u * n:Dot(u)
	if n.Magnitude < 1e-3 then n = u:Cross(Vector3.xAxis) end
	n = n.Unit
	local base = center - n * radius * 0.55
	local k = radius * 1.33
	local slot = acquire()
	slot.A0.CFrame = CFrame.fromMatrix(base - u * radius, n, u)
	slot.A1.CFrame = CFrame.fromMatrix(base + u * radius, n, u)
	start(slot, { Life = life, Width = width, Glow = glow and width * 3.2 or 0, K = k }, k, radius > 6 and 16 or 10, glow, soft)
end
 
local function line(a, b, width, life, draw, glow)
	if #live >= MAX_EFFECTS then return end
	local slot = acquire()
	slot.A0.CFrame = CFrame.new(a)
	slot.A1.CFrame = CFrame.new(a)
	start(slot, { Life = life, Width = width, Glow = glow and width * 4 or 0, From = a, To = b, Draw = draw }, 0, 2, glow, false)
end

local function myRoot()
	local character = Players.LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end
local arenaCell = rng:NextInteger(0, 8)
local function arenaPoint(height)
	if not arena then
		local root = myRoot()
		return root and root.Position + Vector3.new(rng:NextNumber(-70, 70), height, rng:NextNumber(-70, 70)) or Vector3.zero
	end
	local cell = arenaCell
	arenaCell = (arenaCell + 1) % 9
	local x = ((cell % 3 + rng:NextNumber()) / 3 * 2 - 1) * arena.HalfX
	local z = ((math.floor(cell / 3) + rng:NextNumber()) / 3 * 2 - 1) * arena.HalfZ
	local point = arena.Frame:PointToWorldSpace(Vector3.new(x, 0, z))
	return Vector3.new(point.X, arena.FloorY + height, point.Z)
end

local spawners = {
	 
	Swirl = function()
		local root = myRoot()
		if not root then return end
		local offset = randomUnit() * rng:NextNumber(2, 8)
		crescent(root.Position + Vector3.new(offset.X, math.abs(offset.Y) * 0.6, offset.Z), rng:NextNumber(5, 10), rng:NextNumber(0.15, 0.35), rng:NextNumber(0.16, 0.26), false, true)
	end,
	 
	Near = function()
		local root = myRoot()
		if not root then return end
		local mid = root.Position + Vector3.new(rng:NextNumber(-16, 16), rng:NextNumber(-2, 8), rng:NextNumber(-16, 16))
		local d = randomUnit()
		local half = rng:NextNumber(5, 15)
		line(mid - d * half, mid + d * half, rng:NextNumber(0.15, 0.4), rng:NextNumber(0.14, 0.22), 0.04, true)
	end,
	 
	ArenaCrescent = function()
		local center = arenaPoint(rng:NextNumber(0.5, 22))
		crescent(center, rng:NextNumber(7, 18), rng:NextNumber(0.3, 1.1), rng:NextNumber(0.16, 0.3), rng:NextNumber() < 0.35, false)
	end,
	 
	ArenaCut = function()
		local mid = arenaPoint(rng:NextNumber(0.5, 26))
		local d = randomUnit()
		local half = rng:NextNumber(6, 30)
		line(mid - d * half, mid + d * half, rng:NextNumber(0.2, 0.7), rng:NextNumber(0.13, 0.24), 0.04, rng:NextNumber() < 0.45)
	end,
	 
	Streak = function()
		local mid = arenaPoint(rng:NextNumber(2, 60))
		local a = rng:NextNumber(0, math.pi * 2)
		local d = Vector3.new(math.cos(a), rng:NextNumber(-0.45, 0.45), math.sin(a)).Unit
		local diagonal = arena and math.sqrt(arena.HalfX ^ 2 + arena.HalfZ ^ 2) * 2 or 220
		local half = diagonal * rng:NextNumber(0.7, 1.1) / 2
		line(mid - d * half, mid + d * half, rng:NextNumber(0.2, 0.7), rng:NextNumber(0.2, 0.36), 0.06, rng:NextNumber() < 0.6)
	end,
}

local function step(dt)
	if frozenAt then return end
	dt = math.min(dt, 0.1)
	for _, kind in ipairs(KINDS) do
		carry[kind] += dt * rates[kind] * density
		local count = math.floor(carry[kind])
		carry[kind] -= count
		for _ = 1, math.min(count, 120) do spawners[kind]() end
	end
	local now = os.clock()
	local i = 1
	while i <= #live do
		local e = live[i]
		local t = (now - e.Born) / e.Life
		if e.Pull then
			 
			local p = math.clamp((now - e.Pull.Start) / e.Pull.Duration, 0, 1) ^ 2.4
			t = p >= 1 and 1 or 0.5
			if p < 1 then
				local slot = e.Slot
				slot.A0.CFrame = slot.A0.CFrame.Rotation + e.Pull.From0:Lerp(e.Pull.Target, p)
				slot.A1.CFrame = slot.A1.CFrame.Rotation + e.Pull.From1:Lerp(e.Pull.Target, p)
				local w = e.Pull.Width * (1 - p * 0.75)
				slot.Core.Width0, slot.Core.Width1 = w, w
				if e.Glow > 0 then slot.Glow.Width0, slot.Glow.Width1 = e.Pull.Glow * (1 - p * 0.6), e.Pull.Glow * (1 - p * 0.6) end
				i += 1
				continue
			end
		end
		if t >= 1 then
			release(e.Slot)
			live[i] = live[#live]
			live[#live] = nil
		else
			 
			local f = t < 0.12 and t / 0.12 or (1 - (t - 0.12) / 0.88) ^ 1.6
			local slot = e.Slot
			local w = e.Width * f
			slot.Core.Width0, slot.Core.Width1 = w, w
			if e.Glow > 0 then
				local g = e.Glow * f
				slot.Glow.Width0, slot.Glow.Width1 = g, g
			end
			if e.Draw and now - e.Born <= e.Draw + 0.02 then
				slot.A1.CFrame = CFrame.new(e.From:Lerp(e.To, math.min(1, (now - e.Born) / e.Draw)))
			end
			i += 1
		end
	end
	local any = false
	for _, kind in ipairs(KINDS) do if rates[kind] > 0 then any = true break end end
	if #live == 0 and not any and connection then
		connection:Disconnect()
		connection = nil
	end
end
local function ensure()
	if not connection then connection = Run.Heartbeat:Connect(step) end
end

function Spam.SetArena(frame, halfX, halfZ, floorY)
	if typeof(frame) == "CFrame" and type(halfX) == "number" and type(halfZ) == "number" then
		arena = { Frame = frame, HalfX = halfX, HalfZ = halfZ, FloorY = type(floorY) == "number" and floorY or frame.Position.Y }
	end
end
function Spam.SetDensity(value) density = math.clamp(value, 0, 2) end
function Spam.SetRates(new)
	for _, kind in ipairs(KINDS) do rates[kind] = math.max(0, new[kind] or 0) end
	ensure()
end
 
function Spam.Burst(counts)
	for _, kind in ipairs(KINDS) do
		for _ = 1, math.floor((counts[kind] or 0) * density) do spawners[kind]() end
	end
	ensure()
end
function Spam.Count() return #live end
 
function Spam.Converge(target, duration)
	frozenAt = nil
	for _, kind in ipairs(KINDS) do rates[kind], carry[kind] = 0, 0 end
	local now = os.clock()
	for _, e in ipairs(live) do
		local slot = e.Slot
		local from0, from1 = slot.A0.CFrame.Position, slot.A1.CFrame.Position
		if e.Draw then from1 = e.To end
		e.Draw = nil
		e.Pull = {
			Start = now, Duration = duration * rng:NextNumber(0.55, 1), Target = target, From0 = from0, From1 = from1,
			Width = math.max(e.Width, 0.3) * 1.3, Glow = math.max(e.Glow, e.Width * 2),
		}
		if e.Glow <= 0 then e.Glow = e.Pull.Glow slot.Glow.Enabled = true end
	end
	ensure()
end
 
function Spam.Radial(center, count, reach)
	for _ = 1, math.floor(count * density) do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = Vector3.new(math.cos(a), rng:NextNumber(-0.05, 0.6), math.sin(a)).Unit
		local from = center + d * rng:NextNumber(1, 6)
		line(from, from + d * reach * rng:NextNumber(0.4, 1), rng:NextNumber(0.3, 1.2), rng:NextNumber(0.35, 0.7), rng:NextNumber(0.08, 0.16), true)
	end
	ensure()
end
 
function Spam.Freeze(on)
	if on and not frozenAt then
		frozenAt = os.clock()
	elseif not on and frozenAt then
		local held = os.clock() - frozenAt
		frozenAt = nil
		for _, e in ipairs(live) do e.Born += held end
	end
end
 
function Spam.Shatter()
	frozenAt = nil
	local now = os.clock()
	for _, e in ipairs(live) do
		e.Born = now - rng:NextNumber(0, 0.02)
		e.Life = rng:NextNumber(0.18, 0.42)
		e.Width *= 2.2
		if e.Glow > 0 then
			e.Glow *= 1.6
		else
			e.Glow = e.Width * 2.4
			e.Slot.Glow.Enabled = true
		end
		if e.Draw then
			e.Draw = nil
			e.Slot.A1.CFrame = CFrame.new(e.To)
		end
	end
	ensure()
end
function Spam.Stop(immediate)
	frozenAt = nil
	for _, kind in ipairs(KINDS) do rates[kind], carry[kind] = 0, 0 end
	if immediate then
		for _, e in ipairs(live) do release(e.Slot) end
		table.clear(live)
	end
	 
	while #pool > 300 do destroySlot(table.remove(pool)) end
end
return Spam
