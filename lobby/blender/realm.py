# New pieces for the 2026-11-11 pass. Run through the Blender MCP: exec(open(r"...\realm.py").read()).
# 1 Blender unit = 1 stud, Z up, front = -Y. Each collection is one piece, modelled round its origin (= its pivot).
#
# Kit "Props"  (MeshKit, ReplicatedStorage.BlenderMeshes; lobby + boss):
#   TrainingDummy  straw-and-sack training dummy on a cross base, 7.9 tall. TrainingDummy.luau welds it over invisible hitboxes.
#   OrbShrine      the cracked root-bound pedestal the Reality Orb rests on outside the Golden Encounter walls (boss).
# Kit "Realm"  (lobby map Assets, the Divided Wood):
#   ForestCabin, ForestCabinRuin, ForestWell, ForestRock1..3, ForestStump, ForestLogPile, ForestShrine, GlitchPortal, DoorWall
# Kit "Dojo"   (Azusa's training grounds, the Tutorial place):
#   DojoGate, DojoLantern, DojoPost, SakuraTree, DojoArena
# Kit "Glitch" (the glitched place):
#   GlitchBench, GlitchPillar, GlitchArch
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"Thatch": ((0.55, 0.42, 0.18), 0.0, 1.0), "Blossom": ((0.95, 0.55, 0.65), 0.0, 0.8), "Moss": ((0.12, 0.22, 0.06), 0.0, 1.0),
             "Glow": ((1.0, 1.0, 1.0), 0.0, 0.5), "Plaster": ((0.85, 0.8, 0.68), 0.0, 0.9)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau
EXPORT = r"D:\Project\UnfairBossfight\lobby\blender\export"


def cyl(c, name, role, r, z0, z1, loc=(0, 0, 0), seg=16):
    return lathe(name, role, c, [(r, z0), (r, z1)], segments=seg, loc=loc)


def rod(c, name, role, a, b, r, seg=10):
    return sweep(name, role, c, [V(a), V(b)], circle(r, seg))


def ball(c, name, role, r, loc, seg=14, squash=1.0):
    prof = [(0, -r * squash)] + [(math.sin(math.pi * k / 8) * r, -math.cos(math.pi * k / 8) * r * squash) for k in range(1, 8)] + [(0, r * squash)]
    return lathe(name, role, c, prof, segments=seg, loc=loc)


def ring(c, name, role, major, minor, z, loc=(0, 0, 0), seg=32):
    return torus(name, role, c, major, minor, seg=seg, mseg=8, loc=(loc[0], loc[1], loc[2] + z))


# ================================================================================================================ Props kit
# -------------------------------------------------------------------------------------------------------- TrainingDummy
c = collection("TrainingDummy")
for rz in (0, math.pi / 2):
    b = box("WoodDark_Base", "WoodDark", c, (5.2, 0.9, 0.55), loc=(0, 0, 0.28), rot=(0, 0, rz))
    bev(b, 0.08)
for k in range(4):
    a = k * math.pi / 2
    b = box("WoodDark_Wedge", "WoodDark", c, (0.5, 0.5, 1.3), loc=(math.cos(a) * 0.75, math.sin(a) * 0.75, 0.95), rot=(math.sin(a) * 0.5, -math.cos(a) * 0.5, a))
    bev(b, 0.05)
lathe("Wood_Post", "Wood", c, [(0.4, 0.5), (0.36, 2.0), (0.34, 3.3)], segments=14)
# straw body: a bound bundle, wider in the middle
lathe("Thatch_Body", "Thatch", c, [(0.42, 3.05), (0.98, 3.2), (1.16, 3.7), (1.22, 4.6), (1.14, 5.5), (0.95, 5.95), (0.4, 6.1)], segments=24)
for z, r in ((3.55, 1.13), (4.6, 1.23), (5.6, 1.12)):
    torus("Rope_Band", "Rope", c, r, 0.09, seg=32, mseg=6, loc=(0, 0, z))
rnd = random.Random(7)
for k in range(14):  # straw ends poking out below the bundle
    a = k / 14 * TAU + rnd.uniform(-0.1, 0.1)
    p = V((math.cos(a) * 0.85, math.sin(a) * 0.85, 3.15))
    tip = p + V((math.cos(a) * 0.35, math.sin(a) * 0.35, -0.55 - rnd.uniform(0, 0.25)))
    sweep("Thatch_Tuft", "Thatch", c, [p, tip], lambda t: circle(0.09 * (1 - t * 0.8), 5))
# arms: a cross bar through the bundle with sack fists
rod(c, "Wood_Arms", "Wood", (-2.45, 0, 5.25), (2.45, 0, 5.25), 0.24, 12)
for s in (-1, 1):
    ball(c, "Fabric_Fist", "Fabric", 0.48, (s * 2.55, 0, 5.25), seg=12)
    torus("Rope_Wrist", "Rope", c, 0.3, 0.07, seg=20, mseg=6, loc=(s * 2.15, 0, 5.25), rot=(0, math.pi / 2, 0))
# sack head with a tied top and stitched X eyes
ball(c, "Fabric_Head", "Fabric", 0.9, (0, 0, 7.0), seg=16, squash=0.95)
torus("Rope_Collar", "Rope", c, 0.42, 0.1, seg=20, mseg=6, loc=(0, 0, 6.18))
lathe("Fabric_Knot", "Fabric", c, [(0.22, 7.78), (0.12, 8.05), (0.3, 8.3), (0.0, 8.42)], segments=10)
for s in (-1, 1):
    for rot in (0.785, -0.785):
        box("Black_Eye", "Black", c, (0.42, 0.06, 0.08), loc=(s * 0.33, -0.86, 7.15), rot=(0, rot, 0))
box("Black_Mouth", "Black", c, (0.55, 0.06, 0.06), loc=(0, -0.86, 6.72))
# painted target on the chest
for r, role, y in ((0.78, "Red", -1.215), (0.52, "White", -1.225), (0.26, "Red", -1.235)):
    o = cyl(c, f"{role}_Target", role, r, 0, 0.03, seg=24)
    o.rotation_euler = (math.pi / 2, 0, 0)
    o.location = (0, y + 0.015, 4.75)

# -------------------------------------------------------------------------------------------------------- OrbShrine
c = collection("OrbShrine")
solid(lathe("Stone_Step", "Stone", c, [(3.6, 0), (3.6, 0.5), (2.8, 0.5), (2.8, 1.0), (0, 1.0)], segments=8))
col = lathe("Stone_Column", "Stone", c, [(1.1, 1.0), (0.95, 1.25), (0.8, 1.4), (0.75, 3.4), (0.95, 3.6), (1.15, 3.8), (1.15, 4.1), (0, 4.1)], segments=10)
solid(col)
rnd = random.Random(11)
for k in range(6):  # roots wrapping the column
    a = k / 6 * TAU
    pts = []
    for i in range(9):
        t = i / 8
        aa = a + t * 1.6
        r = 0.85 + 0.2 * math.sin(t * 9) + (1 - t) * 1.4
        pts.append(V((math.cos(aa) * r, math.sin(aa) * r, 0.9 + t * 2.7 + (0.3 if i == 0 else 0))))
    pts[0].z = 0.4
    sweep("Bark_Root", "Bark", c, pts, lambda t: circle(0.17 * (1.2 - t * 0.8), 6))
for k in range(5):
    rock("Rock_Rubble", "Rock", c, (rnd.uniform(0.6, 1.3), rnd.uniform(0.6, 1.2), rnd.uniform(0.4, 0.8)), loc=(math.cos(k * 1.3) * rnd.uniform(3.6, 4.6), math.sin(k * 1.3) * rnd.uniform(3.6, 4.6), 0.2), seed=40 + k, detail=1)
# the cradle the orb floats in: three gold claws
for k in range(3):
    a = k / 3 * TAU
    pts = [V((math.cos(a) * 0.7, math.sin(a) * 0.7, 4.1)), V((math.cos(a) * 1.05, math.sin(a) * 1.05, 4.7)), V((math.cos(a) * 0.95, math.sin(a) * 0.95, 5.3)), V((math.cos(a) * 0.6, math.sin(a) * 0.6, 5.7))]
    sweep("Gold_Claw", "Gold", c, pts, lambda t: circle(0.11 * (1 - t * 0.6), 6))
torus("Gold_Cradle", "Gold", c, 0.7, 0.08, seg=24, mseg=6, loc=(0, 0, 4.15))

# ================================================================================================================ Realm kit
# -------------------------------------------------------------------------------------------------------- ForestCabin
def log_wall(c, x0, y0, x1, y1, z0, rows, r, gaps=()):
    """Horizontal logs from (x0,y0) to (x1,y1), `rows` high; gaps = [(t0, t1, zmax)] along the wall left open below zmax."""
    a, b = V((x0, y0, 0)), V((x1, y1, 0))
    length = (b - a).length
    d = (b - a).normalized()
    for i in range(rows):
        z = z0 + r + i * r * 1.9
        spans = [(0.0, 1.0)]
        for g0, g1, zmax in gaps:
            if z < zmax:
                new = []
                for s0, s1 in spans:
                    if g1 <= s0 or g0 >= s1:
                        new.append((s0, s1))
                    else:
                        if g0 > s0:
                            new.append((s0, g0))
                        if g1 < s1:
                            new.append((g1, s1))
                spans = new
        for s0, s1 in spans:
            ext0 = -0.6 if s0 == 0 else 0
            ext1 = 0.6 if s1 == 1 else 0
            p0 = a + d * (s0 * length + ext0) + V((0, 0, z))
            p1 = a + d * (s1 * length + ext1) + V((0, 0, z))
            solid(sweep("Wood_Log", "Wood", c, [p0, p1], circle(r, 10)))


def gable_roof(c, w, d, h, z, over=1.2, role="Thatch", thick=0.7):
    hw, hd = w / 2 + over, d / 2 + over
    for s in (-1, 1):
        # one slope: from the eave (y = s*hd, z) to the ridge (y = 0, z + h)
        pts = [(-hw, s * hd, z), (hw, s * hd, z), (hw, 0, z + h), (-hw, 0, z + h)]
        bm = bmesh.new()
        vs = [bm.verts.new(p) for p in pts] + [bm.verts.new((p[0], p[1], p[2] + thick)) for p in pts]
        bm.faces.new(vs[0:4])
        bm.faces.new(vs[4:8])
        for i in range(4):
            j = (i + 1) % 4
            bm.faces.new((vs[i], vs[j], vs[j + 4], vs[i + 4]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        solid(obj_from_bm(bm, f"{role}_Roof", role, c, smooth=False))
    # gable ends
    for s in (-1, 1):
        bm = bmesh.new()
        x = s * w / 2
        tri = [(x, -d / 2, z), (x, d / 2, z), (x, 0, z + h * (d / 2) / hd)]
        vs = [bm.verts.new(p) for p in tri] + [bm.verts.new((p[0] - s * 0.3, p[1], p[2])) for p in tri]
        bm.faces.new(vs[0:3])
        bm.faces.new(vs[3:6])
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((vs[i], vs[j], vs[j + 3], vs[i + 3]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        obj_from_bm(bm, "Plank_Gable", "Plank", c, smooth=False)
    rod(c, "WoodDark_Ridge", "WoodDark", (-hw, 0, z + h + thick * 0.6), (hw, 0, z + h + thick * 0.6), 0.35)


c = collection("ForestCabin")
W, D, R = 18, 13, 0.42
solid(box("Plank_Floor", "Plank", c, (W + 1, D + 1, 0.8), loc=(0, 0, 0.4)))
for x in range(-8, 9, 2):
    box("WoodDark_FloorSeam", "WoodDark", c, (0.08, D + 1, 0.05), loc=(x, 0, 0.82))
for x, y in ((-W / 2, -D / 2), (W / 2, -D / 2), (W / 2, D / 2), (-W / 2, D / 2)):
    box("Stone_Footing", "Stone", c, (1.6, 1.6, 1.2), loc=(x, y, 0.2))
rows = 11
log_wall(c, -W / 2, -D / 2, W / 2, -D / 2, 0.8, rows, R, gaps=[(0.42, 0.58, 0.8 + 7.4), (0.1, 0.27, 99), (0.73, 0.9, 99)])  # front: door + two windows
log_wall(c, -W / 2, D / 2, W / 2, D / 2, 0.8, rows, R, gaps=[(0.4, 0.6, 99)])
log_wall(c, -W / 2, -D / 2, -W / 2, D / 2, 0.8, rows, R, gaps=[(0.35, 0.65, 99)])
log_wall(c, W / 2, -D / 2, W / 2, D / 2, 0.8, rows, R)
# fill the window gaps below and above the openings with short logs
for (x0, x1) in ((-W / 2 + W * 0.1, -W / 2 + W * 0.27), (-W / 2 + W * 0.73, -W / 2 + W * 0.9)):
    for i in list(range(0, 4)) + list(range(8, rows)):
        z = 0.8 + R + i * R * 1.9
        solid(sweep("Wood_Log", "Wood", c, [V((x0, -D / 2, z)), V((x1, -D / 2, z))], circle(R, 10)))
    frame = box("WoodDark_WindowFrame", "WoodDark", c, (x1 - x0 + 0.4, 0.5, 0.35), loc=((x0 + x1) / 2, -D / 2 - 0.1, 0.8 + R * 1.9 * 4))
    box("WoodDark_WindowFrame", "WoodDark", c, (x1 - x0 + 0.4, 0.5, 0.35), loc=((x0 + x1) / 2, -D / 2 - 0.1, 0.8 + R * 1.9 * 8 - 0.2))
    box("Glass_Window", "Glass", c, (x1 - x0, 0.1, R * 1.9 * 4), loc=((x0 + x1) / 2, -D / 2, 0.8 + R * 1.9 * 6))
    box("WoodDark_Mullion", "WoodDark", c, (0.16, 0.2, R * 1.9 * 4), loc=((x0 + x1) / 2, -D / 2 - 0.08, 0.8 + R * 1.9 * 6))
    for s in (-1, 1):
        sh = box("WoodDark_Shutter", "WoodDark", c, (1.4, 0.18, R * 1.9 * 4), loc=((x0 + x1) / 2 + s * ((x1 - x0) / 2 + 0.75), -D / 2 - 0.45, 0.8 + R * 1.9 * 6), rot=(0, 0, s * 0.35))
for i in list(range(0, 4)) + list(range(8, rows)):  # side and back windows
    z = 0.8 + R + i * R * 1.9
    solid(sweep("Wood_Log", "Wood", c, [V((-W / 2 + W * 0.4, D / 2, z)), V((-W / 2 + W * 0.6, D / 2, z))], circle(R, 10)))
    solid(sweep("Wood_Log", "Wood", c, [V((-W / 2, -D / 2 + D * 0.35, z)), V((-W / 2, -D / 2 + D * 0.65, z))], circle(R, 10)))
box("Glass_Window", "Glass", c, (W * 0.2, 0.1, R * 1.9 * 4), loc=(0, D / 2, 0.8 + R * 1.9 * 6))
box("Glass_Window", "Glass", c, (0.1, D * 0.3, R * 1.9 * 4), loc=(-W / 2, 0, 0.8 + R * 1.9 * 6))
# door
dx0, dx1 = -W / 2 + W * 0.42, -W / 2 + W * 0.58
door = box("WoodDark_Door", "WoodDark", c, (dx1 - dx0 - 0.1, 0.35, 7.3), loc=((dx0 + dx1) / 2, -D / 2 + 0.2, 0.8 + 3.65))
for z in (2.2, 4.6, 6.8):
    box("Iron_Hinge", "Iron", c, (dx1 - dx0 - 0.4, 0.42, 0.22), loc=((dx0 + dx1) / 2, -D / 2 + 0.02, 0.8 + z))
torus("Iron_Ring", "Iron", c, 0.25, 0.05, seg=16, mseg=6, loc=(dx1 - 0.6, -D / 2 - 0.05, 4.5), rot=(math.pi / 2, 0, 0))
box("WoodDark_Lintel", "WoodDark", c, (dx1 - dx0 + 1.2, 0.9, 0.7), loc=((dx0 + dx1) / 2, -D / 2, 0.8 + 7.75))
# top plate and roof
top = 0.8 + rows * R * 1.9
gable_roof(c, W + 1.2, D + 1.2, 5.2, top, over=1.4, role="Thatch", thick=0.8)
# chimney
for i in range(12):
    rnd = random.Random(i)
    rock("Stone_Chimney", "Stone", c, (2.6 + rnd.uniform(-0.2, 0.3), 2.6 + rnd.uniform(-0.2, 0.3), 1.4), loc=(W / 2 - 2.2, D / 2 - 2, 1.0 + i * 1.25), seed=60 + i, detail=1, rough=0.12)
cyl(c, "Black_Flue", "Black", 0.7, top + 3.8, top + 6.6, loc=(W / 2 - 2.2, D / 2 - 2, 0))
# porch: steps, posts, a lantern
for i, z in enumerate((0.3, 0.6)):
    solid(box("Plank_Step", "Plank", c, (6, 1.6 - i * 0.7, 0.6), loc=((dx0 + dx1) / 2, -D / 2 - 1.6 + i * 0.6, z - 0.3 + 0.3 * i)))
for s in (-1, 1):
    cyl(c, "Wood_PorchPost", "Wood", 0.3, 0.8, top + 1.0, loc=((dx0 + dx1) / 2 + s * 3.2, -D / 2 - 2.2, 0), seg=10)
box("Plank_Awning", "Plank", c, (8, 3.0, 0.3), loc=((dx0 + dx1) / 2, -D / 2 - 1.2, top + 1.15), rot=(-0.25, 0, 0))
rod(c, "Iron_LanternHook", "Iron", (dx1 + 0.6, -D / 2 - 0.2, 7.6), (dx1 + 0.6, -D / 2 - 1.1, 7.6), 0.06)
box("Neon_Lantern", "Neon", c, (0.5, 0.5, 0.7), loc=(dx1 + 0.6, -D / 2 - 1.1, 7.0))
box("Iron_LanternCap", "Iron", c, (0.7, 0.7, 0.15), loc=(dx1 + 0.6, -D / 2 - 1.1, 7.42))
# firewood stack against the right wall
for i in range(3):
    for j in range(5 - i):
        rod(c, "Bark_Firewood", "Bark", (W / 2 + 0.9, -3 + j * 0.85 + i * 0.42, 0.45 + i * 0.75), (W / 2 + 3.2, -3 + j * 0.85 + i * 0.42, 0.45 + i * 0.75), 0.4, 8)

# -------------------------------------------------------------------------------------------------------- ForestCabinRuin
c = collection("ForestCabinRuin")
W, D = 16, 12
rnd = random.Random(21)
solid(box("Plank_Floor", "Plank", c, (W + 1, D + 1, 0.7), loc=(0, 0, 0.35)))
for (x0, y0, x1, y1, rows) in ((-W / 2, -D / 2, W / 2, -D / 2, 4), (-W / 2, D / 2, W / 2, D / 2, 9), (-W / 2, -D / 2, -W / 2, D / 2, 7), (W / 2, -D / 2, W / 2, D / 2, 3)):
    a, b = V((x0, y0, 0)), V((x1, y1, 0))
    d = (b - a).normalized()
    L = (b - a).length
    for i in range(rows):
        cut = rnd.uniform(0.0, 0.35) if i > rows - 3 else 0
        cut2 = rnd.uniform(0.0, 0.3) if i > rows - 4 else 0
        p0 = a + d * (L * cut - 0.5) + V((0, 0, 0.7 + 0.4 + i * 0.76))
        p1 = a + d * (L * (1 - cut2) + 0.5) + V((0, 0, 0.7 + 0.4 + i * 0.76))
        solid(sweep("Wood_Log", "Wood", c, [p0, p1], circle(0.4, 9)))
for k in range(5):  # fallen roof beams leaning in
    x = -W / 2 + 2 + k * 3
    rod(c, "WoodDark_Beam", "WoodDark", (x, -D / 2 + 1, 0.9), (x + rnd.uniform(-1, 1), D / 2 - 0.5, 6.5 + rnd.uniform(0, 1.5)), 0.3)
for k in range(6):  # thatch heaps
    rock("Thatch_Heap", "Thatch", c, (rnd.uniform(2.5, 4), rnd.uniform(2, 3.5), rnd.uniform(0.8, 1.4)), loc=(rnd.uniform(-W / 2 + 2, W / 2 - 2), rnd.uniform(-D / 2 + 2, D / 2 - 2), 0.9), seed=80 + k, detail=1)
for k in range(4):
    rod(c, "Wood_LooseLog", "Wood", (rnd.uniform(-12, -9), rnd.uniform(-9, 9), 0.4), (rnd.uniform(-9, -5), rnd.uniform(-9, 9), 0.4), 0.4, 9)
for i in range(6):
    rock("Stone_Chimney", "Stone", c, (2.4, 2.4, 1.3), loc=(-W / 2 + 2, D / 2 - 2, 0.9 + i * 1.2), seed=90 + i, detail=1, rough=0.15)

# -------------------------------------------------------------------------------------------------------- ForestWell
c = collection("ForestWell")
solid(lathe("Stone_Ring", "Stone", c, [(2.0, 0), (3.0, 0), (3.1, 2.6), (3.25, 2.8), (3.25, 3.1), (2.0, 3.1), (2.0, 0.2)], segments=20))
cyl(c, "Black_Water", "Black", 2.0, 1.2, 1.3, seg=20)
for s in (-1, 1):
    cyl(c, "Wood_Post", "Wood", 0.3, 3.0, 8.6, loc=(s * 2.7, 0, 0), seg=10)
rod(c, "Wood_Crank", "Wood", (-3.2, 0, 6.2), (3.2, 0, 6.2), 0.32)
rod(c, "WoodDark_Handle", "WoodDark", (3.2, 0, 6.2), (3.6, 0, 5.4), 0.14)
rod(c, "Rope_Line", "Rope", (0, 0, 6.0), (0, 0, 3.6), 0.07)
lathe("WoodDark_Bucket", "WoodDark", c, [(0.0, 2.6), (0.55, 2.6), (0.7, 3.5), (0.62, 3.5), (0.5, 2.75), (0.0, 2.75)], segments=12)
torus("Iron_BucketBand", "Iron", c, 0.66, 0.05, seg=16, mseg=6, loc=(0, 0, 3.2))
gable_roof(c, 7.2, 4.2, 2.3, 8.4, over=0.5, role="Plank", thick=0.35)

# -------------------------------------------------------------------------------------------------------- ForestRock1..3
for n, (size, seed) in enumerate((((14, 11, 8), 301), ((9, 8, 6.5), 302), ((20, 15, 11), 303)), start=1):
    c = collection(f"ForestRock{n}")
    o = rock("Rock_Main", "Rock", c, size, loc=(0, 0, size[2] * 0.3), seed=seed, detail=3, rough=0.28)
    solid(o)
    rnd = random.Random(seed)
    for k in range(3):
        rock("Moss_Cap", "Moss", c, (size[0] * rnd.uniform(0.3, 0.5), size[1] * rnd.uniform(0.3, 0.5), 0.6), loc=(rnd.uniform(-size[0] * 0.2, size[0] * 0.2), rnd.uniform(-size[1] * 0.2, size[1] * 0.2), size[2] * 0.72 + rnd.uniform(-0.6, 0.2)), seed=seed + 10 + k, detail=1)
    for k in range(4):
        a = rnd.uniform(0, TAU)
        rock("Rock_Pebble", "Rock", c, (rnd.uniform(1.2, 2.4), rnd.uniform(1.2, 2.2), rnd.uniform(0.8, 1.4)), loc=(math.cos(a) * size[0] * 0.55, math.sin(a) * size[1] * 0.55, 0.3), seed=seed + 20 + k, detail=1)

# -------------------------------------------------------------------------------------------------------- ForestStump, ForestLogPile
c = collection("ForestStump")
lathe("Bark_Stump", "Bark", c, [(1.9, 0), (1.5, 0.6), (1.35, 2.0), (1.25, 2.6), (0, 2.65)], segments=14)
cyl(c, "Plank_Rings", "Plank", 1.18, 2.62, 2.7, seg=14)
rnd = random.Random(5)
for k in range(5):
    a = k / 5 * TAU + rnd.uniform(-0.2, 0.2)
    sweep("Bark_Root", "Bark", c, [V((math.cos(a) * 1.2, math.sin(a) * 1.2, 1.2)), V((math.cos(a) * 2.4, math.sin(a) * 2.4, 0.4)), V((math.cos(a) * 3.3, math.sin(a) * 3.3, 0.0))], lambda t: circle(0.4 * (1 - t * 0.7), 7))
c = collection("ForestLogPile")
for i, (n, z) in enumerate(((4, 0.7), (3, 1.9), (2, 3.1))):
    for j in range(n):
        y = (j - (n - 1) / 2) * 1.45
        solid(rod(c, "Bark_Log", "Bark", (-4.5, y, z), (4.5, y, z), 0.72, 12))
        for s in (-1, 1):
            o = cyl(c, "Plank_End", "Plank", 0.62, 0, 0.06, seg=12)
            o.rotation_euler = (0, math.pi / 2, 0)
            o.location = (s * 4.53, y, z)

# -------------------------------------------------------------------------------------------------------- ForestShrine
c = collection("ForestShrine")
solid(box("Stone_Base", "Stone", c, (6, 5, 1.0), loc=(0, 0, 0.5), bevel=0.15))
solid(box("Stone_Base2", "Stone", c, (4.6, 3.8, 0.8), loc=(0, 0, 1.4), bevel=0.1))
box("Wood_Body", "Wood", c, (3.4, 2.6, 3.0), loc=(0, 0.2, 3.3), bevel=0.06)
box("Black_Doorway", "Black", c, (1.6, 0.12, 2.0), loc=(0, -1.12, 3.1))
for s in (-1, 1):
    cyl(c, "WoodDark_Pillar", "WoodDark", 0.22, 1.8, 4.9, loc=(s * 1.85, -1.2, 0), seg=8)
gable_roof(c, 4.4, 3.6, 1.6, 4.8, over=0.6, role="Thatch", thick=0.45)
for k, x in enumerate((-2.4, -1.6, 1.6, 2.4)):
    cyl(c, "White_Candle", "White", 0.13, 1.0, 1.4 + (k % 2) * 0.35, loc=(x, -2.0, 0), seg=8)
    ball(c, "Neon_Flame", "Neon", 0.12, (x, -2.0, 1.55 + (k % 2) * 0.35), seg=6, squash=1.5)
for k in range(3):
    rock("Stone_Offering", "Stone", c, (0.5, 0.5, 0.35), loc=(-0.6 + k * 0.6, -1.9, 1.95), seed=120 + k, detail=1)
rod(c, "Rope_Shimenawa", "Rope", (-2.1, -1.32, 4.6), (2.1, -1.32, 4.6), 0.14, 8)
for x in (-1.2, 0, 1.2):
    box("White_Paper", "White", c, (0.3, 0.04, 0.7), loc=(x, -1.36, 4.15), rot=(0, 0.15, 0))

# -------------------------------------------------------------------------------------------------------- GlitchPortal
c = collection("GlitchPortal")
rnd = random.Random(404)
# a broken checker floor
for i in range(-4, 5):
    for j in range(-2, 3):
        if rnd.random() < 0.88:
            role = "White" if (i + j) % 2 == 0 else "Black"
            solid(box(f"{role}_Tile", role, c, (2.9, 2.9, 0.6 + rnd.uniform(0, 0.4)), loc=(i * 3, j * 3, 0.3 + rnd.uniform(-0.15, 0.25)), rot=(rnd.uniform(-0.04, 0.04), rnd.uniform(-0.04, 0.04), rnd.uniform(-0.03, 0.03))))
# the frame: jagged shards round a 10-stud ring, standing in the XZ plane (the face looks along -Y)
RAD, CZ = 10.5, 12.5
for k in range(44):
    a = k / 44 * TAU
    r = RAD + rnd.uniform(-0.4, 1.6)
    role = "White" if k % 2 == 0 else "Black"
    size = (rnd.uniform(1.2, 2.6), rnd.uniform(1.0, 2.0), rnd.uniform(2.0, 4.2))
    o = box(f"{role}_Shard", role, c, size, loc=(math.cos(a) * r, rnd.uniform(-0.5, 0.5), CZ + math.sin(a) * r), rot=(rnd.uniform(-0.4, 0.4), -a + rnd.uniform(-0.5, 0.5), rnd.uniform(-0.3, 0.3)))
    if math.sin(a) * r + CZ < 3:
        solid(o)
for k in range(26):  # loose shards drifting off the frame
    a = rnd.uniform(0, TAU)
    r = RAD + rnd.uniform(3, 7)
    role = "White" if rnd.random() < 0.5 else "Black"
    box(f"{role}_Drift", role, c, (rnd.uniform(0.4, 1.1), rnd.uniform(0.3, 0.9), rnd.uniform(0.5, 1.6)), loc=(math.cos(a) * r, rnd.uniform(-2.5, 2.5), CZ + math.sin(a) * r), rot=(rnd.uniform(0, TAU), rnd.uniform(0, TAU), rnd.uniform(0, TAU)))
# two broken pillars holding it up
for s in (-1, 1):
    solid(box("Black_Pillar", "Black", c, (2.2, 2.2, 9 + s), loc=(s * 13.5, 0, (9 + s) / 2), rot=(0, s * 0.06, 0)))
    box("White_PillarCap", "White", c, (2.8, 2.8, 0.8), loc=(s * 13.5 + s * 0.3, 0, 9 + s + 0.3), rot=(0.1, s * 0.15, 0.2))

# -------------------------------------------------------------------------------------------------------- DoorWall
c = collection("DoorWall")
# a plain backing wall for a gate: dressed stone, 26 wide, 30 tall, 3 thick, with a buttress each side
solid(box("Stone_Wall", "Stone", c, (26, 3, 30), loc=(0, 1.5, 15), bevel=0.2))
for z in range(3, 30, 3):
    box("StoneWarm_Course", "StoneWarm", c, (26.2, 3.2, 0.25), loc=(0, 1.5, z))
for s in (-1, 1):
    solid(box("Stone_Buttress", "Stone", c, (3, 5, 30), loc=(s * 13.5, 2.5, 15), bevel=0.25))
solid(box("StoneWarm_Cap", "StoneWarm", c, (30, 6, 1.2), loc=(0, 2.5, 30.6), bevel=0.2))

# ================================================================================================================ Dojo kit
# -------------------------------------------------------------------------------------------------------- DojoGate
c = collection("DojoGate")
for s in (-1, 1):
    solid(lathe("Red_Pillar", "Red", c, [(1.05, 0), (0.95, 0.5), (0.9, 17.5), (0, 17.5)], segments=14, loc=(s * 9, 0, 0)))
    solid(lathe("Black_Foot", "Black", c, [(1.4, 0), (1.4, 1.6), (0, 1.6)], segments=14, loc=(s * 9, 0, 0)))
box("Red_Nuki", "Red", c, (22, 1.0, 1.3), loc=(0, 0, 13.6))
box("Black_Kasagi", "Black", c, (26.5, 2.0, 1.1), loc=(0, 0, 17.9))
pts = [V((x, 0, 18.7 + 0.012 * x * x)) for x in range(-15, 16, 3)]
sweep("Black_Curve", "Black", c, pts, [(-1.2, -0.5), (1.2, -0.5), (1.2, 0.5), (-1.2, 0.5)], smooth=False, hint=(0, 1, 0))
box("Red_Shimaki", "Red", c, (24.5, 1.8, 1.0), loc=(0, 0, 16.8))
box("Wood_Plaque", "Wood", c, (2.6, 0.5, 3.6), loc=(0, -0.3, 15.2))
box("Gold_PlaqueEdge", "Gold", c, (2.9, 0.4, 3.9), loc=(0, -0.2, 15.2))

# -------------------------------------------------------------------------------------------------------- DojoLantern
c = collection("DojoLantern")
solid(lathe("Stone_Foot", "Stone", c, [(1.7, 0), (1.6, 0.8), (1.0, 1.2), (0.55, 1.4), (0, 1.4)], segments=8))
cyl(c, "Stone_Shaft", "Stone", 0.5, 1.4, 4.6, seg=8)
box("Stone_Shelf", "Stone", c, (2.6, 2.6, 0.6), loc=(0, 0, 4.9), bevel=0.08)
box("Stone_Box", "Stone", c, (1.8, 1.8, 1.8), loc=(0, 0, 6.1), bevel=0.06)
box("Neon_Window", "Neon", c, (1.85, 1.0, 1.0), loc=(0, 0, 6.1))
box("Neon_Window", "Neon", c, (1.0, 1.85, 1.0), loc=(0, 0, 6.1))
lathe("Stone_Roof", "Stone", c, [(2.3, 7.0), (2.0, 7.4), (0.8, 8.2), (0.4, 8.4), (0.5, 8.7), (0, 9.0)], segments=4)

# -------------------------------------------------------------------------------------------------------- DojoPost
c = collection("DojoPost")
solid(cyl(c, "Wood_Post", "Wood", 0.55, 0, 7.5, seg=12))
for z in (3.0, 3.6, 4.2, 4.8, 5.4):
    torus("Rope_Wrap", "Rope", c, 0.62, 0.13, seg=16, mseg=6, loc=(0, 0, z))
box("WoodDark_Pad", "WoodDark", c, (1.2, 0.5, 2.6), loc=(0, -0.6, 4.2), bevel=0.1)
lathe("Stone_Socket", "Stone", c, [(1.3, 0), (1.1, 0.7), (0.6, 0.8), (0, 0.8)], segments=10)

# -------------------------------------------------------------------------------------------------------- SakuraTree
c = collection("SakuraTree")
rnd = random.Random(88)
trunk = [V((0, 0, -0.5)), V((0.4, 0.2, 3)), V((1.2, -0.3, 6.5)), V((0.8, -0.8, 9.5)), V((1.6, -0.2, 12))]
sweep("Bark_Trunk", "Bark", c, trunk, lambda t: circle(1.1 * (1 - t * 0.6), 10))
tips = []
for k in range(7):
    base = trunk[2 + k % 3]
    a = k * 0.9 + rnd.uniform(-0.3, 0.3)
    end = base + V((math.cos(a) * rnd.uniform(5, 8), math.sin(a) * rnd.uniform(5, 8), rnd.uniform(2, 5)))
    mid = (base + end) / 2 + V((0, 0, 1.2))
    sweep("Bark_Branch", "Bark", c, [base, mid, end], lambda t: circle(0.45 * (1 - t * 0.7), 7))
    tips.append(end)
for p in tips + [trunk[-1] + V((0, 0, 1.5))]:
    for j in range(3):
        rock("Blossom_Cloud", "Blossom", c, (rnd.uniform(4, 6.5), rnd.uniform(4, 6.5), rnd.uniform(3, 4.5)), loc=tuple(p + V((rnd.uniform(-1.8, 1.8), rnd.uniform(-1.8, 1.8), rnd.uniform(-0.6, 1.4)))), seed=rnd.randint(0, 9999), detail=1, rough=0.3, flat_bottom=False)

# -------------------------------------------------------------------------------------------------------- DojoArena
c = collection("DojoArena")
solid(lathe("Stone_Floor", "Stone", c, [(70, -2), (70, 0), (0, 0)], segments=48))
for r0, r1, role in ((66, 68, "StoneWarm"), (40, 41.2, "Red"), (14, 15, "Red"), (0, 4, "StoneWarm")):
    lathe(f"{role}_Inlay", role, c, [(r1, 0.02), (r1, 0.08), (max(r0, 0.0), 0.08)] if r0 == 0 else [(r0, 0.02), (r1, 0.02), (r1, 0.08), (r0, 0.08)], segments=48)
for k in range(8):  # spokes
    a = k / 8 * TAU
    box("StoneWarm_Spoke", "StoneWarm", c, (24, 0.8, 0.06), loc=(math.cos(a) * 27.5, math.sin(a) * 27.5, 0.05), rot=(0, 0, a))
solid(lathe("Stone_Rim", "Stone", c, [(70, 0), (72, 0), (72, 2.5), (70.6, 2.5), (70.6, 1.0), (70, 1.0)], segments=48))

# ================================================================================================================ Glitch kit
c = collection("GlitchBench")
solid(box("Black_Seat", "Black", c, (6, 2, 0.5), loc=(0, 0, 2.0), rot=(0, 0.05, 0)))
box("White_Back", "White", c, (6, 0.4, 2.2), loc=(0, 0.95, 3.4), rot=(0.12, -0.04, 0))
for x in (-2.6, 2.6):
    for y in (-0.8, 0.8):
        box("Black_Leg", "Black", c, (0.35, 0.35, 2.0), loc=(x, y, 1.0), rot=(rnd.uniform(-0.1, 0.1), 0, 0))
rnd = random.Random(9)
for k in range(10):
    box("White_Bit", "White" if k % 2 else "Black", c, (rnd.uniform(0.2, 0.5),) * 3, loc=(rnd.uniform(-3.5, 3.5), rnd.uniform(-1.5, 1.5), rnd.uniform(2.5, 5.5)), rot=(rnd.uniform(0, TAU), rnd.uniform(0, TAU), 0))
c = collection("GlitchPillar")
for k in range(9):
    role = "White" if k % 2 == 0 else "Black"
    o = box(f"{role}_Block", role, c, (3.2, 3.2, 3.0), loc=(rnd.uniform(-0.6, 0.6) * (k / 9), rnd.uniform(-0.6, 0.6) * (k / 9), 1.5 + k * 3.05), rot=(0, 0, rnd.uniform(-0.25, 0.25) * k / 9))
    if k < 3:
        solid(o)
c = collection("GlitchArch")
for s in (-1, 1):
    for k in range(7):
        role = "White" if (k + (s > 0)) % 2 == 0 else "Black"
        solid(box(f"{role}_Stone", role, c, (2.6, 2.6, 2.6), loc=(s * 8, 0, 1.3 + k * 2.65), rot=(0, 0, rnd.uniform(-0.08, 0.08))))
for k in range(9):
    t = k / 8
    a = math.pi * t
    role = "White" if k % 2 == 0 else "Black"
    box(f"{role}_Arc", role, c, (2.4, 2.6, 2.4), loc=(math.cos(a) * -8, 0, 18.6 + math.sin(a) * 6.5), rot=(0, a, 0))

bpy.context.view_layer.update()
print("built")
