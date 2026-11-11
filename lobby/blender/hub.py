# The Sanctum (hub island) dressing. Pieces, each round its origin on the ground, front -Y:
#   HubPlaza       the round plaza (radius 38): paving in rings, gold rays and rings, a raised fountain step at the middle (radius 14).
#   HubColumn      a whole marble column, 26 tall, on a base, with a capital. HubColumnBroken: a stump and its fallen drum.
#   HubBench       a park bench (wood slats on iron sides), 8 long; sit with a Seat the builder adds at (0, 0, 2.2).
#   HubLamp        an iron lamp post with a glass lantern; the builder lights it at (0, 0, 11.6).
#   HubGazebo      a domed pavilion on eight columns, radius 11, for beside the pond.
#   HubBridge      an arched stone footbridge, 16 long along Y, 7 wide.
#   HubTree1/2     round-crowned trees (1 leafy, 2 in blossom: roles Leaf / Blossom), ~30 tall.
#   HubSwingTree   a broad tree with a long low branch; the swing hangs from (0, -9, 15.2) and (0, -9 +- 1.6 ...) see builder.
#   HubSwingSeat   the swing's plank; origin = its middle.
#   HubPlanter     a stone planter of flowers, 6 x 3.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
ROLES["Blossom"] = ((0.95, 0.55, 0.65), 0.0, 0.8)
V = Vector

# =====================================================================================================================
pz = collection("HubPlaza")
solid(lathe("StoneWarm_Base", "StoneWarm", pz, [(0, -1.0), (38.5, -1.0), (38.5, 0.4), (38.0, 0.6), (0, 0.6)], segments=96))
rnd = random.Random(4)
for ring, (r0, r1, n) in enumerate([(15.5, 19.5, 28), (19.5, 23.5, 34), (23.5, 27.5, 40), (27.5, 31.5, 46), (31.5, 35.5, 52)]):
    for k in range(n):
        a0 = (k + 0.04) / n * math.tau
        a1 = (k + 0.96) / n * math.tau
        if (k + ring) % 7 == 0:
            continue  # a gap where grass would push through
        pts = [(math.cos(a0) * (r0 + 0.15), math.sin(a0) * (r0 + 0.15)), (math.cos(a1) * (r0 + 0.15), math.sin(a1) * (r0 + 0.15)),
               (math.cos(a1) * (r1 - 0.15), math.sin(a1) * (r1 - 0.15)), (math.cos(a0) * (r1 - 0.15), math.sin(a0) * (r1 - 0.15))]
        role = "Stone" if rnd.random() < 0.55 else "StoneWarm"
        slab2d(f"{role}_Paver", role, pz, pts, 0.55, 0.85 + rnd.uniform(-0.04, 0.04), plane="xy")
torus("Gold_RingOuter", "Gold", pz, 35.8, 0.35, seg=96, mseg=4, loc=(0, 0, 0.82), scale_minor=(1, 0.3))
torus("Gold_RingInner", "Gold", pz, 15.3, 0.3, seg=72, mseg=4, loc=(0, 0, 0.82), scale_minor=(1, 0.3))
for k in range(8):
    a = k / 8 * math.tau + math.pi / 8
    p0, p1 = V((math.cos(a), math.sin(a), 0)) * 15.6, V((math.cos(a), math.sin(a), 0)) * 35.6
    sweep("GoldDeep_Ray", "GoldDeep", pz, [p0 + V((0, 0, 0.86)), p1 + V((0, 0, 0.86))], [(-0.45, -0.05), (0.45, -0.05), (0.45, 0.05), (-0.45, 0.05)], smooth=False)
# the fountain step: two rounded marble tiers
solid(lathe("Marble_Step1", "Marble", pz, [(0, 0.5), (15.0, 0.5), (15.0, 1.2), (14.6, 1.5), (0, 1.5)], segments=72))
torus("Gold_StepLip", "Gold", pz, 14.8, 0.18, seg=72, mseg=4, loc=(0, 0, 1.4))

# =====================================================================================================================
def fluted(col, name, role, z0, z1, radius, flutes=12, top_cut=None, seed=0):
    seg = flutes * 4
    bm = bmesh.new()
    rings = []
    levels = 10
    r2 = random.Random(seed)
    for k in range(levels + 1):
        z = z0 + (z1 - z0) * k / levels
        ring = []
        for i in range(seg):
            a = i / seg * math.tau
            r = radius * (1 - 0.1 * max(0.0, math.cos(a * flutes)) ** 2) * (1 - 0.06 * (k / levels))
            zz = z
            if top_cut and k == levels:
                zz = z - top_cut * (0.5 + 0.5 * math.sin(a * 2 + seed)) - r2.uniform(0, 0.8)
            ring.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, zz)))
        rings.append(ring)
    for k in range(levels):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, role, col)


c = collection("HubColumn")
solid(box("Marble_Plinth", "Marble", c, (6.4, 6.4, 1.4), loc=(0, 0, 0.7), bevel=0.15))
lathe("Marble_Base", "Marble", c, [(0, 1.4), (3.0, 1.4), (3.0, 2.0), (2.7, 2.4), (2.9, 2.8), (2.5, 3.1), (0, 3.1)], segments=32)
solid(fluted(c, "Marble_Shaft", "Marble", 3.0, 24.0, 2.3))
lathe("Marble_Capital", "Marble", c, [(0, 24.0), (2.3, 24.0), (2.6, 24.6), (3.3, 25.6), (0, 25.6)], segments=32)
box("Marble_Abacus", "Marble", c, (7.0, 7.0, 1.0), loc=(0, 0, 26.1), bevel=0.15)
torus("Gold_Necking", "Gold", c, 2.35, 0.16, seg=32, mseg=4, loc=(0, 0, 23.8))
for sy in (-1, 1):
    torus("Marble_Volute", "Marble", c, 0.7, 0.28, seg=16, mseg=6, loc=(0, sy * 2.9, 25.0), rot=(0, math.radians(90), 0))

c = collection("HubColumnBroken")
solid(box("Marble_Plinth", "Marble", c, (6.4, 6.4, 1.4), loc=(0, 0, 0.7), bevel=0.15))
lathe("Marble_Base", "Marble", c, [(0, 1.4), (3.0, 1.4), (3.0, 2.0), (2.7, 2.4), (2.9, 2.8), (2.5, 3.1), (0, 3.1)], segments=32)
solid(fluted(c, "Marble_Stump", "Marble", 3.0, 11.0, 2.3, top_cut=2.4, seed=3))
drum = fluted(c, "Marble_Drum", "Marble", 0.0, 6.0, 2.2, top_cut=1.5, seed=7)
drum.rotation_euler = (math.radians(88), 0, math.radians(20))
drum.location = (5.6, -1.0, 2.2)
for k in range(4):
    rock(f"Marble_Chip{k}", "Marble", c, (1.2, 0.9, 0.6), loc=(-3.0 + k * 0.9, 3.0 - k * 0.5, 0.25), seed=40 + k, detail=1)

# =====================================================================================================================
c = collection("HubBench")
for sx in (-1, 1):
    pts = [V((sx * 3.6, 1.1, 0)), V((sx * 3.6, 0.6, 2.0)), V((sx * 3.6, -0.9, 2.1)), V((sx * 3.6, -1.1, 0))]
    sweep("Iron_Side", "Iron", c, pts, [(-0.2, -0.2), (0.2, -0.2), (0.2, 0.2), (-0.2, 0.2)], smooth=False)
    sweep("Iron_Back", "Iron", c, [V((sx * 3.6, 0.6, 2.0)), V((sx * 3.6, 1.3, 4.6))], [(-0.2, -0.2), (0.2, -0.2), (0.2, 0.2), (-0.2, 0.2)], smooth=False)
    torus("Iron_Arm", "Iron", c, 0.6, 0.12, seg=12, mseg=4, loc=(sx * 3.7, -0.2, 2.9), rot=(0, math.radians(90), 0))
for k in range(4):
    solid(box("Wood_Slat", "Wood", c, (8.0, 0.55, 0.3), loc=(0, -0.8 + k * 0.6, 2.15), bevel=0.06))
for k in range(3):
    box("Wood_BackSlat", "Wood", c, (8.0, 0.25, 0.55), loc=(0, 0.85 + k * 0.2, 2.7 + k * 0.7), rot=(math.radians(-16), 0, 0), bevel=0.05)

# =====================================================================================================================
c = collection("HubLamp")
lathe("Iron_Foot", "Iron", c, [(0, 0), (1.1, 0), (1.1, 0.4), (0.8, 0.7), (0.5, 1.4), (0.35, 1.8), (0, 1.8)], segments=8, smooth=False)
lathe("Iron_Pole", "Iron", c, [(0.28, 1.8), (0.22, 9.6), (0, 9.6)], segments=10)
for k in range(4):
    a = k / 4 * math.tau
    pts = [V((math.cos(a) * (0.2 + t * 0.9), math.sin(a) * (0.2 + t * 0.9), 8.6 + math.sin(t * math.pi) * 1.2 + t * 0.6)) for t in [i / 8 for i in range(9)]]
    sweep("Iron_Scroll", "Iron", c, pts, circle(0.09, 5))
lathe("Iron_LanternBase", "Iron", c, [(0, 9.6), (0.9, 9.8), (0.9, 10.1), (0, 10.1)], segments=6, smooth=False)
lathe("Glass_Lantern", "Glass", c, [(0.75, 10.1), (0.95, 11.8), (0.0, 11.8)], segments=6, smooth=False)
for k in range(6):
    a = k / 6 * math.tau
    sweep("Iron_LanternBar", "Iron", c, [V((math.cos(a) * 0.8, math.sin(a) * 0.8, 10.1)), V((math.cos(a) * 1.0, math.sin(a) * 1.0, 11.8))], circle(0.06, 4))
lathe("Iron_LanternRoof", "Iron", c, [(0, 11.8), (1.3, 11.8), (0.4, 12.9), (0.2, 13.5), (0, 13.8)], segments=6, smooth=False)
lathe("Gold_Finial", "Gold", c, [(0, 13.7), (0.25, 13.9), (0, 14.4)], segments=6, smooth=False)

# =====================================================================================================================
c = collection("HubGazebo")
GR = 11.0
solid(lathe("Marble_Floor", "Marble", c, [(0, 0), (GR + 1.5, 0), (GR + 1.5, 1.4), (0, 1.4)], segments=8, smooth=False)).rotation_euler = (0, 0, math.radians(22.5))
for i in range(2):
    solid(box(f"Marble_Step{i}", "Marble", c, (7.0, 2.0, 0.7), loc=(0, -(GR + 2.4) - i * 1.4, 0.7 - i * 0.7 + 0.35 - 0.35 * 0), bevel=0.1))
for k in range(8):
    a = k / 8 * math.tau + math.pi / 8
    x, y = math.cos(a) * GR, math.sin(a) * GR
    o = fluted(c, "Marble_Col", "Marble", 1.4, 13.4, 0.75, flutes=8)
    o.location = (x, y, 0)
    lathe("Gold_ColCap", "Gold", c, [(0, 13.4), (0.85, 13.4), (1.2, 14.0), (0, 14.0)], segments=12, loc=(x, y, 0))
solid(lathe("Marble_Entab", "Marble", c, [(GR - 1.6, 14.0), (GR + 1.4, 14.0), (GR + 1.4, 15.6), (GR - 1.6, 15.6)], segments=8, smooth=False)).rotation_euler = (0, 0, math.radians(22.5))
lathe("Gold_EntabTrim", "Gold", c, [(GR + 1.4, 15.3), (GR + 1.6, 15.3), (GR + 1.6, 15.6), (GR + 1.4, 15.6)], segments=8, smooth=False).rotation_euler = (0, 0, math.radians(22.5))
dome = [(GR + 1.2, 15.6)] + [(math.cos(t * math.pi / 2) * (GR + 1.2), 15.6 + math.sin(t * math.pi / 2) * 8.5) for t in [i / 10 for i in range(1, 11)]]
lathe("Leaf_Dome", "Leaf", c, dome + [(0, 24.1)], segments=32)
lathe("Gold_Lantern", "Gold", c, [(0, 24.0), (1.2, 24.0), (1.0, 25.4), (0.4, 26.4), (0, 27.4)], segments=12)
for k in range(16):
    a = k / 16 * math.tau
    sweep("Gold_DomeRib", "Gold", c, [V((math.cos(a) * math.cos(t * math.pi / 2) * (GR + 1.3), math.sin(a) * math.cos(t * math.pi / 2) * (GR + 1.3), 15.6 + math.sin(t * math.pi / 2) * 8.6)) for t in [i / 8 for i in range(9)]], circle(0.14, 4))
# a low balustrade between the columns, open at the steps (front, -Y)
for k in range(8):
    a0 = k / 8 * math.tau + math.pi / 8
    a1 = (k + 1) / 8 * math.tau + math.pi / 8
    mid = (a0 + a1) / 2
    if abs(math.cos(mid) - 0) < 0.4 and math.sin(mid) < 0:
        continue
    p0 = V((math.cos(a0) * GR, math.sin(a0) * GR, 4.4))
    p1 = V((math.cos(a1) * GR, math.sin(a1) * GR, 4.4))
    sweep("Marble_Rail", "Marble", c, [p0, p1], [(-0.4, -0.3), (0.4, -0.3), (0.4, 0.3), (-0.4, 0.3)], smooth=False)
    for t in [i / 6 for i in range(1, 6)]:
        p = p0.lerp(p1, t)
        lathe("Marble_Baluster", "Marble", c, [(0, 1.4), (0.35, 1.4), (0.5, 2.2), (0.25, 3.3), (0.4, 4.1), (0, 4.1)], segments=8, loc=(p.x, p.y, 0))

# =====================================================================================================================
c = collection("HubBridge")
BL, BW = 16.0, 7.0
deck = []
for i in range(17):
    t = i / 16
    y = -BL / 2 + t * BL
    z = 1.0 + math.sin(t * math.pi) * 2.4
    deck.append((y, z))
under = [(y, z - 1.4 - (1.2 if abs(y) < 5 else 0) * math.cos(y / 5 * math.pi / 2)) for y, z in reversed(deck)]
prof = deck + [(BL / 2, -0.8), ] + under[1:-1] + [(-BL / 2, -0.8)]
o = slab2d("Stone_BridgeBody", "Stone", c, [(-u, v) for u, v in prof], -BW / 2, BW / 2)
o.rotation_euler = (0, 0, math.radians(90))
solid(o)
for sx in (-1, 1):
    pts = [V((sx * (BW / 2 - 0.4), y, z + 1.5)) for y, z in deck]
    sweep("StoneWarm_Parapet", "StoneWarm", c, pts, [(-0.4, -1.1), (0.4, -1.1), (0.4, 0.4), (-0.4, 0.4)], smooth=False)
    for y, z in deck[::4]:
        lathe("StoneWarm_Newel", "StoneWarm", c, [(0, 0), (0.6, 0), (0.6, 0.6), (0.3, 1.0), (0, 1.0)], segments=6, loc=(sx * (BW / 2 - 0.4), y, z + 1.9), smooth=False)

# =====================================================================================================================
def tree(name, seed, height, leaf_role, crown_scale=1.0, branches=5, low_branch=False):
    col = collection(name)
    r = random.Random(seed)
    r0 = height * 0.05
    trunk = [V((0, 0, -1))]
    d = V((r.uniform(-0.1, 0.1), r.uniform(-0.1, 0.1), 1)).normalized()
    for i in range(10):
        d = (d + V((r.uniform(-0.08, 0.08), r.uniform(-0.08, 0.08), 0.05))).normalized()
        trunk.append(trunk[-1] + d * height * 0.06)
    sweep("Bark_Trunk", "Bark", col, trunk, lambda t: circle(r0 * (1.3 - t * 0.6) * (1.25 if t < 0.08 else 1.0), 10))
    for k in range(5):
        a = k / 5 * math.tau
        sweep("Bark_Root", "Bark", col, [trunk[1], trunk[1] + V((math.cos(a) * height * 0.09, math.sin(a) * height * 0.09, -0.9))], lambda t: circle(r0 * 0.6 * (1 - t * 0.8), 6))
    top = trunk[-1]
    tips = [top]
    for b in range(branches):
        a = b / branches * math.tau + r.uniform(-0.3, 0.3)
        base = trunk[r.randint(6, 9)]
        end = base + V((math.cos(a), math.sin(a), r.uniform(0.6, 1.0))) * height * 0.28
        sweep("Bark_Branch", "Bark", col, [base, (base + end) / 2 + V((0, 0, 1.0)), end], lambda t: circle(r0 * 0.5 * (1 - t * 0.6), 7))
        tips.append(end)
    if low_branch:
        base = trunk[5]
        end = base + V((0, -height * 0.42, height * 0.06))
        sweep("Bark_Bough", "Bark", col, [base, base + V((0, -height * 0.2, height * 0.06)), end], lambda t: circle(r0 * 0.75 * (1 - t * 0.4), 9))
        tips.append(end + V((0, 0, 1.5)))
    for k, p in enumerate(tips):
        s = height * 0.26 * crown_scale * r.uniform(0.85, 1.15)
        rock(f"{leaf_role}_Crown{k}", leaf_role, col, (s * 1.2, s * 1.2, s * 0.95), loc=p + V((0, 0, s * 0.25)), seed=seed * 10 + k, detail=2, rough=0.28, flat_bottom=False)
    return col


tree("HubTree1", 11, 30, "Leaf")
tree("HubTree2", 23, 26, "Blossom", crown_scale=0.95, branches=6)
tree("HubSwingTree", 37, 36, "Leaf", crown_scale=1.05, branches=5, low_branch=True)

c = collection("HubSwingSeat")
box("Wood_Seat", "Wood", c, (4.4, 1.8, 0.4), bevel=0.08)
for sx in (-1, 1):
    torus("Iron_Eye", "Iron", c, 0.25, 0.08, seg=10, mseg=4, loc=(sx * 1.9, 0, 0.3), rot=(math.radians(90), 0, 0))

c = collection("HubPlanter")
solid(box("StoneWarm_Box", "StoneWarm", c, (6.0, 3.0, 2.2), loc=(0, 0, 1.1), bevel=0.25))
box("Stone_Lip", "Stone", c, (6.4, 3.4, 0.4), loc=(0, 0, 2.3), bevel=0.12)
box("Grass_Soil", "Grass", c, (5.4, 2.4, 0.3), loc=(0, 0, 2.2))
rp = random.Random(9)
for k in range(14):
    role = ["Red", "Blossom", "Gold", "Leaf"][k % 4]
    rock(f"{role}_Flower{k}", role, c, (0.9, 0.9, 0.8), loc=(rp.uniform(-2.4, 2.4), rp.uniform(-0.9, 0.9), 2.7 + rp.uniform(0, 0.4)), seed=500 + k, detail=1, rough=0.3, flat_bottom=False)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith("Hub")})
