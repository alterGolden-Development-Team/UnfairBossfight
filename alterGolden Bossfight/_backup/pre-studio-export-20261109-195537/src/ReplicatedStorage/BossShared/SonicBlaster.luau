--[[
 SonicBlaster (shared by the server and every client) - Phase 5's final attack, alterGolden's last spell card.
 After his last line the soundtrack "Sonic Blaster" (asset 108440513814741) plays from the top, and the attack lasts
 exactly as long as the song: when the music ends, the attack ends. Every bullet is fired on the song's beat.

 The beat grid was measured from the track (librosa: ~143.5 BPM, 415 beats, music audible from 0 to 175.5s):
   Beats[i]  song time of beat i (seconds from the first sample)
   Kick[i]   0-9, how hard the kick/bass lands on that beat (9 = among the hardest in the song)
   Hat[i]    0-9, how bright the hats/treble are on that beat
 Offset shifts the whole grid if the uploaded audio starts later/earlier than the analysed mp3.

 Bullets are deterministic: the server sends small volley descriptors (Expand turns one into its bullets) and both
 sides run Advance with the same fixed step, so every client draws each bullet exactly where the server has it.
]]
local M = {}
M.SoundId = "rbxassetid://108440513814741"
M.SongName = "Sonic Blaster"
M.Length = 175.5  -- the music is over here (the file is 182s; the rest is silence)
M.Offset = 0
M.Space = Vector3.new(0, 2400, 9000)  -- the middle of the stage's top surface (far away from the arena)
M.Radius = 175
M.Core = 10  -- nobody stands on top of him either
M.End = 147.888
M.Last = 170.9  -- the last beat of that attack: every bullet is drawn into the hole, then he says his last words
M.FlyAt = 171.4  -- he lets go and flies into the black hole...
M.GoneAt = 174.0
M.Height = 3  -- bullets fly this far over the floor
M.Dt = 1 / 60
M.MaxAge = 34
 -- one star (a life), your health comes back, every bullet near you is wiped and you are untouchable for MissGrace
 -- seconds. Your last star can't be lost to this attack.
M.MissGrace = 3
M.MissClear = 34  -- the bullets within this many studs of you are wiped on a miss
M.HitGrace = 1.0  -- after an ordinary hit, this long before the next one counts
M.Lead = 0.9  -- seconds between the server deciding to start the music and the music starting (time to load and sync)

 -- each spell card is built from one era of his fight (Phase 1 slashes, Phase 2 clocks and knives, Phase 3 illusions,
M.Sections = {
	{ At = 0, Id = "Prologue", Title = "" },
	{ At = 11.70, Id = "Gilded", Title = "Gilded Sign 「Crescent Requiem」" },
	{ At = 38.15, Id = "Clock", Title = "Clock Sign 「Hour Hands of the Golden Clock」" },
	{ At = 65.41, Id = "World", Title = "Time Sign 「The World Stands Still」" },
	{ At = 79.90, Id = "Illusion", Title = "Illusion Sign 「One Hundred Faces」" },
	{ At = 94.39, Id = "Thread", Title = "Thread Sign 「Gilded Loom」" },
	{ At = 106.81, Id = "Cosmos", Title = "Space Sign 「Supernova Constellation」" },
	{ At = 140.85, Id = "Breath", Title = "「Galaxy in a Breath」" },
	{ At = 147.888, Id = "BlackHole", Title = "Last Imagination 「Return to Nothing」" },
}
function M.Section(t)
	local found = M.Sections[1]
	for _, s in ipairs(M.Sections) do
		if t >= s.At then found = s else break end
	end
	return found
end

local BEATS = "1.695,2.113,2.531,2.949,3.344,3.762,4.180,4.598,5.016,5.410,5.828,6.246,6.664,7.082,7.500,7.918,8.313,8.731,9.125,9.543,9.961,10.379,10.820,11.262,11.703,12.121,12.539,12.980,13.398,13.816,14.234,14.652,15.070,15.464,15.906,16.300,16.695,17.113,17.531,17.949,18.367,18.785,19.203,19.598,20.016,20.434,20.852,21.269,21.687,22.082,22.523,22.918,23.336,23.754,24.172,24.567,24.985,25.379,25.797,26.215,26.633,27.051,27.469,27.887,28.305,28.700,29.118,29.536,29.954,30.348,30.766,31.184,31.626,32.020,32.438,32.833,33.251,33.669,34.087,34.505,34.923,35.341,35.736,36.153,36.571,36.966,37.384,37.779,38.150,38.545,38.940,39.358,39.776,40.171,40.588,41.006,41.424,41.842,42.237,42.655,43.073,43.491,43.909,44.327,44.722,45.140,45.558,45.976,46.393,46.788,47.206,47.624,48.042,48.460,48.878,49.273,49.691,50.109,50.527,50.945,51.363,51.780,52.175,52.593,53.011,53.429,53.847,54.335,54.776,55.217,55.681,56.123,56.541,56.935,57.353,57.794,58.212,58.700,59.164,59.582,60.047,60.465,60.883,61.277,61.695,62.113,62.531,62.949,63.367,63.762,64.180,64.598,64.993,65.411,65.829,66.247,66.664,67.082,67.500,67.918,68.313,68.731,69.149,69.567,69.985,70.403,70.821,71.216,71.634,72.052,72.469,72.864,73.282,73.700,74.118,74.536,74.954,75.349,75.767,76.185,76.603,77.021,77.439,77.833,78.251,78.669,79.064,79.482,79.900,80.318,80.736,81.154,81.572,81.966,82.384,82.802,83.220,83.638,84.033,84.451,84.869,85.287,85.705,86.123,86.518,86.936,87.353,87.771,88.189,88.584,89.002,89.420,89.838,90.256,90.674,91.092,91.487,91.905,92.323,92.740,93.158,93.576,93.971,94.389,94.807,95.225,95.643,96.038,96.456,96.874,97.292,97.710,98.128,98.545,98.940,99.358,99.776,100.194,100.612,101.007,101.425,101.843,102.237,102.655,103.073,103.491,103.909,104.327,104.745,105.163,105.558,105.976,106.394,106.812,107.230,107.624,108.042,108.460,108.878,109.296,109.691,110.109,110.527,110.945,111.340,111.758,112.176,112.594,113.012,113.429,113.847,114.242,114.660,115.078,115.496,115.914,116.332,116.727,117.145,117.563,117.981,118.399,118.817,119.234,119.629,120.047,120.465,120.860,121.278,121.696,122.114,122.532,122.950,123.344,123.762,124.180,124.598,125.016,125.411,125.829,126.247,126.665,127.083,127.501,127.896,128.313,128.731,129.149,129.567,129.962,130.380,130.798,131.216,131.634,132.052,132.470,132.888,133.283,133.700,134.118,134.606,135.070,135.488,135.953,136.324,136.719,137.160,137.625,138.019,138.437,138.855,139.273,139.645,140.040,140.434,140.852,141.270,141.688,142.083,142.501,142.919,143.360,143.755,144.149,144.567,144.962,145.380,145.775,146.193,146.611,147.052,147.470,147.888,148.306,148.724,149.142,149.537,149.954,150.349,150.767,151.185,151.603,152.021,152.439,152.857,153.275,153.670,154.088,154.506,154.924,155.341,155.759,156.154,156.595,156.990,157.408,157.803,158.221,158.662,159.080,159.521,159.939,160.334,160.729,161.123,161.541,161.959,162.377,162.795,163.213,163.608,164.026,164.420,164.838,165.256,165.674,166.092,166.510,166.928,167.346,167.741,168.159,168.554,168.972,169.390,169.831,170.249,170.667,171.085,171.503,171.921,172.339,172.757,173.175,173.593"
local KICK = "0089397766318550796152804343545056437743230020110256330046574432142135653266140152221656978697156532889859983575395836888631146345091034100956636847240867702473500989879030112251988994315797957347991797897454873599949989771740896422336848266845474867580530767617998644867646146889688317458679865182769999311061737889992080120129000106432112162568674322340075544235210011104725231520312312310355322525526227555555555"
local HAT = "9090909090809179991012526645085668943746589628664894285716381758589548577796385748952836114445330231186637762441133448473101334717017290600587112232755545593221212254446320212442136540512667989235992999983516902636979999140052565888893512488810021451240271325512738786835234323453733312254685601065789855502060108765481003898069102029627480896170843412756670637583796476617971030301334284797374748063867479777777777"
M.Beats, M.Kick, M.Hat = {}, {}, {}
for v in string.gmatch(BEATS, "[^,]+") do M.Beats[#M.Beats + 1] = tonumber(v) + M.Offset end
for i = 1, #M.Beats do
	M.Kick[i] = tonumber(string.sub(KICK, i, i)) or 5
	M.Hat[i] = tonumber(string.sub(HAT, i, i)) or 5
end
M.Beat = 0.418  -- the typical gap between two beats
 -- the index of the last beat at or before song time t (0 before the first)
function M.BeatAt(t)
	local lo, hi = 1, #M.Beats
	if t < M.Beats[1] then return 0 end
	while lo < hi do
		local mid = (lo + hi + 1) // 2
		if M.Beats[mid] <= t then lo = mid else hi = mid - 1 end
	end
	return lo
end

 -- bullet kinds: Hit is the radius that hurts, Size how big it is drawn, Long makes it a grain of rice / a kunai
M.Kinds = {
	[1] = { Name = "Pellet", Hit = 0.75, Size = 2.2 },
	[2] = { Name = "Orb", Hit = 1.3, Size = 3.4, Damage = 1.15 },
	[3] = { Name = "Big", Hit = 2.8, Size = 7.2, Damage = 1.5 },
	[4] = { Name = "Rice", Hit = 0.7, Size = 1.5, Long = 4.2 },
	[5] = { Name = "Note", Hit = 1.0, Size = 2.8, Damage = 1.1 },
	[6] = { Name = "Knife", Hit = 0.65, Size = 1.3, Long = 5.6 },
	[7] = { Name = "Card", Hit = 1.05, Size = 2.4, Card = true },
}
M.Colors = {
	Color3.fromRGB(255, 206, 84),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(80, 150, 255),
	Color3.fromRGB(170, 100, 255),
	Color3.fromRGB(70, 235, 255),
	Color3.fromRGB(255, 110, 200),
	Color3.fromRGB(110, 255, 140),
	Color3.fromRGB(255, 150, 40),
}

 -- a deterministic 0..1 from (seed, id): the same on every machine
function M.Hash(seed, id)
	local x = (math.floor(seed) % 2147483646 + 1) * 16807 % 2147483647
	x = (x + math.floor(id) * 48271) % 2147483647
	x = x * 48271 % 2147483647
	x = x * 16807 % 2147483647
	return x / 2147483647
end

local TAU = math.pi * 2
 --[[ a volley descriptor -> its bullets
  Id, T (server time it fires), X, Z (where), K kind, C colour, N count, A first angle, S spread (nil: a full ring;
  otherwise a fan S radians wide centred on A), V speed, Acc, Vmin, Vmax, W turn rate (rad/s), L layers, Dv speed
  added per layer, Da angle added per layer, Dl delay between bullets (a stream), Fz/Go freeze then go again at
  those server times (Gm: 1 random heading, 2 aimed at Gx/Gz, 3 away from the centre Cx/Cz; Gs, Gacc, Gw: new
  speed, acceleration and turn rate), Seed, P (explicit points {x1, z1, x2, z2, ...}: one bullet on each, all
  heading A) ]]
function M.Expand(d)
	local out = {}
	local layers = d.L or 1
	local function add(i, x, z, a, v, t0)
		out[#out + 1] = {
			id = d.Id * 4096 + i, k = d.K or 1, c = d.C or 1, x = x, z = z, a = a, v = v, acc = d.Acc or 0,
			vmin = d.Vmin or 0, vmax = d.Vmax or 999, w = d.W or 0, t0 = t0, st = t0,
			fz = d.Fz, go = d.Go, gm = d.Gm, gx = d.Gx, gz = d.Gz, cx = d.Cx, cz = d.Cz, gs = d.Gs, gacc = d.Gacc, gw = d.Gw,
			seed = d.Seed or d.Id,
			bn = d.Bn, sa = d.Sa, sf = d.Sf, sp = (d.Sp or 0) * i,
		}
	end
	if d.P then
		local i = 0
		for j = 1, #d.P, 2 do
			i += 1
			add(i, d.P[j], d.P[j + 1], d.A or 0, d.V or 10, d.T + (d.Dl or 0) * (i - 1))
		end
		return out
	end
	if d.Shape == "Star" then
		 -- a star outline (Pts points, Inner the inner radius as a fraction): every bullet heads straight out from the
		 -- middle at a speed in proportion to its distance, so the star keeps its shape as it grows (Rr: its size at birth)
		local pts = d.Pts or 5
		local verts = {}
		for v = 0, pts * 2 - 1 do
			local r = v % 2 == 0 and 1 or (d.Inner or 0.42)
			local a = (d.A or 0) + v * math.pi / pts
			verts[#verts + 1] = { math.cos(a) * r, math.sin(a) * r }
		end
		local per = math.max(1, d.N or 3)
		local scale = d.Rr or 1
		local i = 0
		for v = 1, #verts do
			local p, q = verts[v], verts[v % #verts + 1]
			for j = 0, per - 1 do
				local u = j / per
				local x, z = p[1] + (q[1] - p[1]) * u, p[2] + (q[2] - p[2]) * u
				local m = math.sqrt(x * x + z * z)
				i += 1
				add(i, d.X + x * scale, d.Z + z * scale, math.atan2(z, x), (d.V or 10) * m, d.T)
			end
		end
		return out
	end
	local n = math.max(1, d.N or 1)
	local i = 0
	for layer = 0, layers - 1 do
		for j = 0, n - 1 do
			i += 1
			local a
			if d.S then
				a = n > 1 and (d.A - d.S / 2 + d.S * j / (n - 1)) or d.A
			else
				a = d.A + TAU * j / n
			end
			a += (d.Da or 0) * layer
			 -- Rr: born on a ring that far out (In: heading inward, at its middle)
			local sx, sz = d.X, d.Z
			if d.Rr then sx += math.cos(a) * d.Rr sz += math.sin(a) * d.Rr end
			add(i, sx, sz, d.In and a + math.pi or a, (d.V or 10) + (d.Dv or 0) * layer, d.T + (d.Dl or 0) * j)
		end
	end
	return out
end

 -- run bullet b forward to server time `now` in fixed steps; false while it has not fired yet
local DT = M.Dt
function M.Advance(b, now)
	if now < b.t0 then return false end
	local cos, sin = math.cos, math.sin
	while b.st + DT <= now do
		local t = b.st + DT
		if b.fz and t >= b.fz and not (b.go and t >= b.go) then
			b.v = 0
		else
			if b.go and t >= b.go and not b.went then
				b.went = true
				local r = M.Hash(b.seed, b.id)
				if b.gm == 1 then
					b.a = r * TAU
				elseif b.gm == 2 then
					b.a = math.atan2((b.gz or 0) - b.z, (b.gx or 0) - b.x) + (r - 0.5) * 0.5
				elseif b.gm == 3 then
					b.a = math.atan2(b.z - (b.cz or 0), b.x - (b.cx or 0)) + (r - 0.5) * 0.9
				elseif b.gm == 4 then  -- straight at Gx/Gz, no spread (the knives of The World)
					b.a = math.atan2((b.gz or 0) - b.z, (b.gx or 0) - b.x)
				elseif b.gm == 5 then  -- a quarter turn, left or right by the bullet (pinwheels, lattices)
					b.a += (r < 0.5 and 1 or -1) * math.pi / 2
				elseif b.gm == 6 then  -- straight back the way it came
					b.a += math.pi
				end
				b.v = b.gs or b.v
				b.acc = b.gacc or 0
				b.w = b.gw or 0
				b.vmin, b.vmax = 0, 999
			end
			b.v = math.clamp(b.v + b.acc * DT, b.vmin, b.vmax)
			b.a += b.w * DT
			if b.sa then b.a += b.sa * math.sin((t - b.t0) * b.sf + (b.sp or 0)) * DT end
			b.x += cos(b.a) * b.v * DT
			b.z += sin(b.a) * b.v * DT
			if b.bn and b.bn > 0 then
				local dx, dz = b.x - M.Space.X, b.z - M.Space.Z
				local lim = M.Radius - 4
				if dx * dx + dz * dz > lim * lim then
					local d = math.sqrt(dx * dx + dz * dz)
					local nx, nz = dx / d, dz / d
					local vx, vz = cos(b.a), sin(b.a)
					local dot = vx * nx + vz * nz
					if dot > 0 then
						b.a = math.atan2(vz - 2 * dot * nz, vx - 2 * dot * nx)
						b.bn -= 1
						b.x, b.z = M.Space.X + nx * (lim - 0.5), M.Space.Z + nz * (lim - 0.5)
					end
				end
			end
		end
		b.st = t
	end
	return true
end
 -- where bullet b is at `now`, between two fixed steps (for drawing)
function M.Where(b, now)
	local e = math.clamp(now - b.st, 0, M.Dt)
	if b.fz and now >= b.fz and not (b.go and now >= b.go) then return b.x, b.z end
	return b.x + math.cos(b.a) * b.v * e, b.z + math.sin(b.a) * b.v * e
end
 -- gone: far outside the stage, or too old
function M.Gone(b, now, cx, cz)
	local dx, dz = b.x - cx, b.z - cz
	return dx * dx + dz * dz > (M.Radius + 26) ^ 2 or now - b.t0 > M.MaxAge
end

 -- lasers: Id, X, Z, A (angle at T), W turn rate, T (the warning line appears), On (it fires), Off, Len, Wid, C
function M.LaserAngle(l, now)
	return l.A + (l.W or 0) * (now - l.T)
end
 -- true while a laser is burning (a ticking laser - Period, Duty - is off for part of every period)
function M.LaserLive(l, now)
	if now < l.On or now > l.Off then return false end
	if l.Period then
		return ((now - l.On) % l.Period) < l.Period * (l.Duty or 0.5)
	end
	return true
end
 -- the illusion mirrors (Illusion Sign): Count mirrors on a circle of radius R round the middle, turning at W rad/s from
 -- angle A0 at server time T0
function M.Mirror(m, k, now)
	local a = m.A0 + m.W * (now - m.T0) + (k - 1) / m.Count * math.pi * 2
	return m.X + math.cos(a) * m.R, m.Z + math.sin(a) * m.R
end

return M
