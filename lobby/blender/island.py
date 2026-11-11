# TheFallenNoob's island. Pieces (each modelled round the origin, front = -Y = Roblox -Z):
#   IslandLighthouse  blue-and-white striped tower on a stone keeper's base. Origin = ground centre. Lamp centre at (0, 0, LAMP_Z).
#   IslandBoat        ferry sailboat. Origin = the Root part's centre (deck level); bow toward -Y. Benches under the six Seats.
#   IslandPier        one 12-long pier segment, deck top at z 0, running along Y.
#   IslandHut         thatched beach hut on stilts. Origin = ground centre, door toward -Y.
#   IslandArch        sea-rock arch for a terrace portal. Opening centre (0, 0, 10), diameter 18.5.
#   IslandCliff1/2    big weathered rock chunks to dress the shore. Origin = ground centre.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
ROLES["Thatch"] = ((0.55, 0.4, 0.18), 0.0, 1.0)


def roughen(o, strength=1.2, size=2.5, levels=1, seed=0):
    sub = o.modifiers.new("Sub", "SUBSURF")
    sub.levels = levels
    sub.render_levels = levels
    tex = bpy.data.textures.get(f"IslNoise{seed}") or bpy.data.textures.new(f"IslNoise{seed}", "CLOUDS")
    tex.noise_scale = size
    tex.noise_depth = 2
    d = o.modifiers.new("Disp", "DISPLACE")
    d.texture = tex
    d.strength = strength
    return o


# =====================================================================================================================
lh = collection("IslandLighthouse")
# keeper's base: an octagonal stone drum with a cornice and a door
solid(lathe("StoneWarm_Base", "StoneWarm", lh, [(0, -3), (17, -3), (17, 5.0), (0, 5.0)], segments=8, smooth=False)).rotation_euler = (0, 0, math.radians(22.5))
lathe("Stone_BaseCornice", "Stone", lh, [(0, 5.0), (17.8, 5.0), (17.8, 6.0), (0, 6.0)], segments=8, smooth=False).rotation_euler = (0, 0, math.radians(22.5))
box("WoodDark_Door", "WoodDark", lh, (4.0, 0.6, 6.5), loc=(0, -16.0, 3.25))
box("Stone_DoorFrame", "Stone", lh, (5.4, 0.8, 0.8), loc=(0, -16.1, 6.8))
box("Stone_Step", "Stone", lh, (7, 3, 0.8), loc=(0, -17.6, 0.4))
for sx in (-1, 1):
    box("Blue_Shutter", "Blue", lh, (1.2, 0.4, 3.0), loc=(sx * 7.0, -15.6, 3.6))
    box("Ink_Window", "Ink", lh, (2.4, 0.4, 3.0), loc=(sx * 5.2, -15.7, 3.6))
# tower: tapered, in bands; z 6 to 66
BANDS = 8
Z0, Z1 = 6.0, 66.0
R0, R1 = 11.5, 7.4
for i in range(BANDS):
    za = Z0 + (Z1 - Z0) * i / BANDS
    zb = Z0 + (Z1 - Z0) * (i + 1) / BANDS
    ra = R0 + (R1 - R0) * i / BANDS
    rb = R0 + (R1 - R0) * (i + 1) / BANDS
    role = "Blue" if i % 2 == 0 else "White"
    o = lathe(f"{role}_Band{i}", role, lh, [(0, za), (ra, za), (rb, zb), (0, zb)], segments=48)
    if i == 0:
        solid(o)
# small windows spiralling up the tower
for i in range(5):
    z = Z0 + 9 + i * 10.5
    a = -math.pi / 2 + i * 1.2
    r = R0 + (R1 - R0) * (z - Z0) / (Z1 - Z0)
    w = box("Ink_TowerWindow", "Ink", lh, (1.6, 0.8, 2.6), loc=(math.cos(a) * (r - 0.1), math.sin(a) * (r - 0.1), z))
    w.rotation_euler = (0, 0, a + math.pi / 2)
    s = box("White_Sill", "White", lh, (2.2, 1.0, 0.35), loc=(math.cos(a) * (r + 0.1), math.sin(a) * (r + 0.1), z - 1.45))
    s.rotation_euler = (0, 0, a + math.pi / 2)
# gallery: corbels, a deck, railing
for k in range(16):
    a = k / 16 * math.tau
    o = box("Stone_Corbel", "Stone", lh, (1.0, 2.6, 2.2), loc=(math.cos(a) * (R1 + 0.6), math.sin(a) * (R1 + 0.6), Z1 - 0.8))
    o.rotation_euler = (0, 0, a + math.pi / 2)
lathe("Iron_Gallery", "Iron", lh, [(0, Z1), (10.6, Z1), (10.6, Z1 + 1.0), (0, Z1 + 1.0)], segments=48)
for k in range(24):
    a = k / 24 * math.tau
    lathe("Iron_Baluster", "Iron", lh, [(0.16, 0), (0.16, 3.6), (0, 3.6)], segments=6, loc=(math.cos(a) * 10.2, math.sin(a) * 10.2, Z1 + 1.0))
torus("Iron_Rail", "Iron", lh, 10.2, 0.2, seg=48, mseg=6, loc=(0, 0, Z1 + 4.6))
torus("Iron_RailMid", "Iron", lh, 10.2, 0.12, seg=48, mseg=4, loc=(0, 0, Z1 + 2.8))
# lantern room: a low wall, glass, glazing bars, a red domed cap with a vent ball and a rod
LZ = Z1 + 1.0
lathe("White_LanternWall", "White", lh, [(0, LZ), (6.2, LZ), (6.2, LZ + 2.0), (0, LZ + 2.0)], segments=24)
lathe("Glass_Lantern", "Glass", lh, [(5.6, LZ + 2.0), (5.6, LZ + 9.0), (0.01, LZ + 9.0)], segments=24, smooth=False)
for k in range(12):
    a = k / 12 * math.tau
    lathe("Iron_Mullion", "Iron", lh, [(0.18, 0), (0.18, 7.0), (0, 7.0)], segments=6, loc=(math.cos(a) * 5.7, math.sin(a) * 5.7, LZ + 2.0))
torus("Iron_Transom", "Iron", lh, 5.7, 0.18, seg=24, mseg=4, loc=(0, 0, LZ + 5.5))
lathe("Red_Dome", "Red", lh, [(0, LZ + 9.0), (6.6, LZ + 9.0), (6.4, LZ + 9.6), (5.6, LZ + 11.4), (3.8, LZ + 13.0), (1.2, LZ + 14.0), (0, LZ + 14.1)], segments=32)
lathe("Iron_Vent", "Iron", lh, [(0, LZ + 13.8), (1.0, LZ + 14.2), (1.3, LZ + 15.2), (1.0, LZ + 16.2), (0, LZ + 16.5)], segments=16)
lathe("Iron_Rod", "Iron", lh, [(0.12, LZ + 16.4), (0.12, LZ + 20.5), (0, LZ + 21)], segments=6)
LAMP_Z = LZ + 5.5

# =====================================================================================================================
bt = collection("IslandBoat")
# hull loft: stations from stern (+14) to bow (-22); section is a U from port gunwale round the keel to starboard
ST = 30
stations = []
for j in range(ST + 1):
    t = j / ST
    y = 14 - t * 36
    # beam: full aft, pinching to a point at the bow; a little narrower at the transom
    beam = 6.4 * (1 - max(0.0, (t - 0.45) / 0.55) ** 1.8) * (0.86 + 0.14 * min(1.0, t / 0.2))
    beam = max(beam, 0.15)
    sheer = 3.4 + 2.6 * max(0.0, (t - 0.55) / 0.45) ** 2  # rises toward the bow
    keel = -3.2 + 1.6 * max(0.0, (t - 0.7) / 0.3) ** 1.5
    pts = []
    for k in range(13):
        u = k / 12  # 0 port gunwale -> 1 starboard gunwale
        ang = math.pi * u
        x = -math.cos(ang) * beam
        z = keel + (sheer - keel) * (1 - math.sin(ang) ** 0.6)
        pts.append(Vector((x, y, z)))
    stations.append(pts)
bm = bmesh.new()
rings = [[bm.verts.new(p) for p in st] for st in stations]
for j in range(ST):
    for k in range(12):
        bm.faces.new((rings[j][k], rings[j][k + 1], rings[j + 1][k + 1], rings[j + 1][k]))
bm.faces.new(list(rings[0]))  # transom
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
hull = obj_from_bm(bm, "White_Hull", "White", bt)
s = hull.modifiers.new("Solid", "SOLIDIFY")
s.thickness = 0.45
s.offset = -1
# a blue band along the hull just under the gunwale, a dark rub rail on top, a red waterline stripe
for name, role, zoff, r in (("Blue_Band", "Blue", -1.0, 0.55), ("WoodDark_Rub", "WoodDark", 0.0, 0.32), ("Red_Waterline", "Red", None, 0.3)):
    for side in (-1, 1):
        path = []
        for j in range(ST + 1):
            st = stations[j]
            p = st[0] if side < 0 else st[12]
            if zoff is None:
                p = st[2] if side < 0 else st[10]
                path.append(p + Vector((side * 0.25, 0, 0)))
            else:
                path.append(p + Vector((side * 0.12, 0, zoff)))
        sweep(name, role, bt, path, circle(r, 6, 1.0, 1.0 if role != "Blue" else 1.4))
# deck: planks across the inside at z 0.5
for j in range(0, ST - 4):
    t = j / ST
    y = 14 - t * 36 - 0.6
    st = stations[j]
    half = abs(st[0].x) - 0.6
    if half > 0.6:
        box("Plank_Deck", "Plank", bt, (half * 2 * 0.98, 1.1, 0.3), loc=(0, y, 0.35))
# benches under the seats (seat positions x +-2.6, y -6 / 1.5 / 8 at z 1)
for y in (-6, 1.5, 8):
    box("Wood_Bench", "Wood", bt, (10.4, 3.2, 0.5), loc=(0, y, 0.55 + 0.4), bevel=0.1)
    for sx in (-1, 1):
        box("WoodDark_BenchLeg", "WoodDark", bt, (0.6, 2.6, 0.7), loc=(sx * 4.0, y, 0.6), bevel=0.05)
# mast, boom, gaff sail, a jib and a pennant
MY = -4.0
lathe("WoodDark_Mast", "WoodDark", bt, [(0.55, 0.4), (0.45, 22), (0.3, 30), (0, 30.3)], segments=10, loc=(0, MY, 0))
sweep("WoodDark_Boom", "WoodDark", bt, [Vector((0, MY + 0.4, 6.0)), Vector((0, MY + 15, 6.6))], circle(0.3, 8))
sweep("WoodDark_Gaff", "WoodDark", bt, [Vector((0, MY + 0.4, 21.0)), Vector((0, MY + 12, 25.5))], circle(0.25, 8))
# sail: a curved quad between mast, boom and gaff, billowing to starboard
SU, SV = 10, 10
bm = bmesh.new()
grid = []
for i in range(SU + 1):
    u = i / SU
    row = []
    for j in range(SV + 1):
        v = j / SV
        bottom = Vector((0, MY + 0.8 + u * 13.6, 6.8 + u * 0.55))
        top = Vector((0, MY + 0.8 + u * 10.6, 21.4 + u * 3.9))
        p = bottom.lerp(top, v)
        p.x += math.sin(u * math.pi) * math.sin(v * math.pi) * 1.8
        row.append(bm.verts.new(p))
    grid.append(row)
for i in range(SU):
    for j in range(SV):
        bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
sail = obj_from_bm(bm, "Fabric_Sail", "Fabric", bt)
sail.modifiers.new("Solid", "SOLIDIFY").thickness = 0.15
# jib: a triangle from the masthead to the bow
bm = bmesh.new()
a, b, c = Vector((0, MY - 0.6, 26.5)), Vector((0, -20.4, 5.6)), Vector((0, MY - 1.2, 6.5))
n = 8
tri = []
for i in range(n + 1):
    row = []
    for j in range(n + 1 - i):
        u, v = i / n, j / n
        p = a + (b - a) * u + (c - a) * v
        p.x += math.sin(u * math.pi) * math.sin(min(1, v * 2) * math.pi / 2) * 1.0 * (1 - u - v) * 3
        row.append(bm.verts.new(p))
    tri.append(row)
for i in range(n):
    for j in range(n - i):
        bm.faces.new((tri[i][j], tri[i + 1][j], tri[i][j + 1]))
        if j + 1 < len(tri[i + 1]):
            bm.faces.new((tri[i + 1][j], tri[i + 1][j + 1], tri[i][j + 1]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
jib = obj_from_bm(bm, "Fabric_Jib", "Fabric", bt)
jib.modifiers.new("Solid", "SOLIDIFY").thickness = 0.15
sweep("Rope_Forestay", "Rope", bt, [Vector((0, MY - 0.4, 28.5)), Vector((0, -21.6, 6.0))], circle(0.1, 5))
for sx in (-1, 1):
    sweep("Rope_Shroud", "Rope", bt, [Vector((0, MY, 27.0)), Vector((sx * 5.6, MY + 1.0, 3.2))], circle(0.08, 5))
bm = bmesh.new()
vs = [bm.verts.new((0, MY, 30.2)), bm.verts.new((0, MY, 28.6)), bm.verts.new((0, MY + 5.2, 29.6))]
bm.faces.new(vs)
pen = obj_from_bm(bm, "Red_Pennant", "Red", bt, smooth=False)
pen.modifiers.new("Solid", "SOLIDIFY").thickness = 0.12
# rudder and tiller at the stern, a lantern on a stern post
box("WoodDark_Rudder", "WoodDark", bt, (0.4, 2.2, 5.0), loc=(0, 14.9, -1.0), bevel=0.1)
sweep("Wood_Tiller", "Wood", bt, [Vector((0, 15.0, 1.8)), Vector((0, 10.5, 2.6))], circle(0.18, 6))
lathe("WoodDark_SternPost", "WoodDark", bt, [(0.2, 0), (0.2, 6), (0, 6)], segments=6, loc=(3.6, 12.6, 0.5))
lathe("Iron_Lantern", "Iron", bt, [(0, 0), (0.6, 0), (0.6, 0.2), (0.45, 0.25), (0.45, 1.3), (0.7, 1.4), (0.2, 1.9), (0, 2.0)], segments=8, loc=(3.6, 12.6, 6.4))
# a coiled rope and a little cargo
torus("Rope_Coil", "Rope", bt, 0.9, 0.22, seg=16, mseg=6, loc=(-3.3, 11.6, 0.75))
torus("Rope_Coil2", "Rope", bt, 0.65, 0.22, seg=16, mseg=6, loc=(-3.3, 11.6, 1.15))
box("Plank_Crate", "Plank", bt, (2.2, 2.2, 2.0), loc=(3.4, -13.0, 1.5), bevel=0.15)

# =====================================================================================================================
pr = collection("IslandPier")
for k in range(5):
    y = -4.8 + k * 2.4
    box("Plank_Board", "Plank" if k % 2 == 0 else "Wood", pr, (9.0, 2.2, 0.5), loc=(0, y, -0.25), rot=(0, 0, (k % 3 - 1) * 0.01), bevel=0.06)
solid(box("Plank_Walk", "Plank", pr, (9.0, 12.0, 0.2), loc=(0, 0, -0.5)))  # hidden under the boards: the walking surface
for sx in (-1, 1):
    box("WoodDark_Stringer", "WoodDark", pr, (0.8, 12.0, 1.2), loc=(sx * 4.2, 0, -1.1))
    for y in (-5.4, 5.4):
        lathe("WoodDark_Piling", "WoodDark", pr, [(0.75, -18), (0.7, 1.6), (0.55, 2.0), (0, 2.1)], segments=10, loc=(sx * 4.8, y, 0))
    torus("Rope_Lash", "Rope", pr, 0.82, 0.12, seg=12, mseg=4, loc=(sx * 4.8, -5.4, -1.4))
    # a rope rail swagging between the posts
    path = [Vector((sx * 4.8, -5.4 + 10.8 * t, 1.4 - math.sin(t * math.pi) * 0.9)) for t in [i / 10 for i in range(11)]]
    sweep("Rope_Rail", "Rope", pr, path, circle(0.12, 5))
box("WoodDark_Brace", "WoodDark", pr, (9.6, 0.5, 0.5), loc=(0, -5.4, -4.0), rot=(0, math.radians(18), 0))

# =====================================================================================================================
ht = collection("IslandHut")
solid(box("Plank_HutFloor", "Plank", ht, (14, 14, 0.6), loc=(0, 0, 2.7), bevel=0.08))
for sx in (-1, 1):
    for sy in (-1, 1):
        lathe("Wood_Stilt", "Wood", ht, [(0.5, -1), (0.45, 2.4), (0, 2.4)], segments=8, loc=(sx * 6, sy * 6, 0))
        lathe("Wood_Post", "Wood", ht, [(0.45, 3.0), (0.4, 11.6), (0, 11.6)], segments=8, loc=(sx * 6.2, sy * 6.2, 0))
# low bamboo walls on three sides, open front
for k in range(25):
    for side, (dx, dy, horiz) in enumerate([(1, 0, False), (-1, 0, False), (0, 1, True)]):
        t = -6 + k * 0.5
        x, y = (dx * 6.3, t) if not horiz else (t, 6.3)
        lathe("Bark_Bamboo", "Bark" if k % 4 == 0 else "Wood", ht, [(0.24, 3.0), (0.24, 7.6), (0, 7.6)], segments=6, loc=(x, y, 0))
# thatched roof: a steep cone in two overlapping skirts, a little cap
lathe("Thatch_Roof", "Thatch", ht, [(0, 18.5), (3.0, 16.6), (8.2, 13.0), (11.0, 11.0), (11.2, 10.6), (0, 11.0)], segments=24, smooth=False)
lathe("Thatch_Skirt", "Thatch", ht, [(7.5, 13.6), (11.6, 10.8), (11.7, 10.2), (7.3, 13.2)], segments=24, smooth=False)
lathe("Bark_RoofCap", "Bark", ht, [(0, 18.0), (1.0, 18.0), (0.8, 19.4), (0, 19.8)], segments=10)
# steps up to the open front, a bar counter, a hanging lantern
for i in range(3):
    solid(box("Wood_HutStep", "Wood", ht, (5, 1.4, 0.4), loc=(0, -7.6 - i * 1.3, 2.2 - i * 0.8), bevel=0.05))
box("Wood_Counter", "Wood", ht, (9.0, 1.4, 3.2), loc=(0, 2.0, 4.6), bevel=0.1)
box("Plank_CounterTop", "Plank", ht, (9.6, 2.0, 0.35), loc=(0, 2.0, 6.35), bevel=0.06)

# =====================================================================================================================
ar = collection("IslandArch")
AR, ACY = 9.25, 10.0
path = []
for i in range(33):
    t = i / 32
    a = math.radians(-18 + t * 216)
    rr = AR + 3.5 + math.sin(t * 7.0) * 0.4
    path.append(Vector((math.cos(a) * rr, 0, ACY + math.sin(a) * rr)))
path.insert(0, path[0] + Vector((1.0, 0, -6)))
path.append(path[-1] + Vector((-1.0, 0, -6)))


def asec(t):
    fat = 2.6 + 0.7 * (abs(t - 0.5) * 2) ** 2
    return [(math.cos(b) * fat * (1 + 0.16 * math.sin(b * 3 + t * 9)) * 1.25, math.sin(b) * fat * (1 + 0.12 * math.sin(b * 5 - t * 6)))
            for b in [k / 12 * math.tau for k in range(12)]]


solid(roughen(sweep("Rock_Arch", "Rock", ar, path, asec), strength=1.4, size=2.2, levels=2, seed=11))
for k in range(10):
    a = math.radians(-10 + k * 22)
    p = Vector((math.cos(a) * (AR + 1.0), -2.2, ACY + math.sin(a) * (AR + 1.0)))
    o = lathe("Marble_Barnacle", "Marble", ar, [(0, 0), (0.5, 0), (0.35, 0.5), (0.15, 0.45), (0, 0.3)], segments=7, loc=p, smooth=False)
    o.rotation_euler = (math.radians(90), 0, 0)
for side in (-1, 1):
    for k in range(3):
        sz = 3.2 + k * 0.8
        solid(rock(f"Rock_ArchFoot{side}{k}", "Rock", ar, (sz * 1.3, sz, sz), loc=(side * (AR + 5.2 + k * 0.6), -1.5 + k * 1.4, 1.0), seed=200 + k + side * 7))

# =====================================================================================================================
for idx, (sx, sy, sz, seed) in enumerate([(42, 30, 26, 31), (30, 24, 34, 47)]):
    cl = collection(f"IslandCliff{idx + 1}")
    o = rock("Rock_Cliff", "Rock", cl, (sx, sy, sz), loc=(0, 0, sz * 0.32), seed=seed, detail=3, rough=0.32)
    solid(roughen(o, strength=3.0, size=6.0, levels=1, seed=seed))
    # strata: a couple of darker ledges
    for k in range(2):
        r = rock(f"Stone_Ledge{k}", "Stone", cl, (sx * 0.7, sy * 0.75, 3.0), loc=(sx * 0.08 * (k - 0.5), -sy * 0.1, sz * (0.3 + k * 0.28)), seed=seed + 5 + k, detail=2, rough=0.2)

print({c.name: len(c.objects) for c in bpy.data.collections if c.name.startswith("Island")})
