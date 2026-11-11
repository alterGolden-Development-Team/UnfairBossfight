# Lobby round 3 pieces. Front = -Y, origin = ground centre unless noted. Glow = the portal face (the builder tints it).
#   GateReturnPalace   back to the Sanctum from the palace: a stepped gold art-deco door with gold-ray wings. Opening 14 x 21.
#   GateReturnIsland   ... from the island: two whale ribs lashed into an arch, a net, shells; an oval face 13 x 19.
#   GateReturnForest   ... from the forest: a moon gate in a wall that is half white, half black, tiled on top. Round face r 8.
#   IslandShellPortal  a giant scallop, top valve raised, the portal glowing between the valves; on a coral-rock base.
#   HubFountain        a three-tier marble fountain with water and falling sheets, a gold armillary sphere on top. Radius 13.
#   ForestMountain1/2  jagged mountain-wall segments (~150 wide, ~120 tall) to close the forest in.
#   KeeperHat          a tall wizard hat for the keeper's R6 head (origin = the head's top centre).
#   KeeperBeard        a long beard (origin = the head's centre front-bottom).
#   BroHeadband        a headband with trailing tails for an R6 head (origin = head centre).
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
ROLES["Shell"] = ((0.95, 0.78, 0.72), 0.0, 0.5)
ROLES["Water"] = ((0.5, 0.8, 0.95), 0.0, 0.05)
ROLES["Coral"] = ((0.9, 0.4, 0.35), 0.0, 0.8)
V = Vector


def roughen(o, strength=1.0, size=2.0, levels=1, seed=0):
    if levels:
        sub = o.modifiers.new("Sub", "SUBSURF")
        sub.levels = levels
    tex = bpy.data.textures.get(f"L2Noise{seed}") or bpy.data.textures.new(f"L2Noise{seed}", "CLOUDS")
    tex.noise_scale = size
    d = o.modifiers.new("Disp", "DISPLACE")
    d.texture = tex
    d.strength = strength
    return o


def recess(col, name, role, outline, y0, depth):
    bm = bmesh.new()
    a = [bm.verts.new((u, y0, v)) for u, v in outline]
    b = [bm.verts.new((u, y0 + depth, v)) for u, v in outline]
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[j], a[i], b[i], b[j]))
    for i0, i1, i2 in tessellate_polygon([[Vector((u, v, 0)) for u, v in outline]]):
        bm.faces.new((b[i2], b[i1], b[i0]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = obj_from_bm(bm, name, role, col, smooth=False)
    o.data.flip_normals()
    return o


def ellipse(cx, cz, rx, rz, n=32):
    return [(cx + math.cos(i / n * math.tau) * rx, cz + math.sin(i / n * math.tau) * rz) for i in range(n)]


# =====================================================================================================================
c = collection("GateReturnPalace")
solid(box("MarbleDark_Step", "MarbleDark", c, (26, 9, 1.2), loc=(0, 0, 0.6), bevel=0.15))
box("Gold_StepNose", "Gold", c, (26.2, 0.3, 0.2), loc=(0, -4.5, 1.1))
OPEN = [(-7, 1.2), (7, 1.2), (7, 18.5), (4.5, 21.5), (-4.5, 21.5), (-7, 18.5)]
for k, (grow, d0, d1, role) in enumerate([(4.6, -1.0, 1.0, "GoldDeep"), (3.0, -1.6, 0.6, "Gold"), (1.4, -2.2, 0.2, "GoldPale")]):
    outer = [(x * (1 + grow / 7), 1.2 + (z - 1.2) * (1 + grow / 20.3)) for x, z in OPEN]
    slabk = slab2d(f"{role}_Frame{k}", role, c, outer, d0, d1)
    cut(slabk, slab2d("Cut", role, c, [(x * 1.0 + (0.0), z) for x, z in OPEN], d0 - 1, d1 + 1))
    solid(slabk)
# sun crest and gold-ray wings
lathe("Gold_Sun", "Gold", c, [(0, -0.4), (2.6, -0.4), (2.6, 0.4), (0, 0.6)], segments=24, loc=(0, -2.0, 29.0)).rotation_euler = (math.radians(90), 0, 0)
for k in range(13):
    a = math.radians(k * 15)
    blade("GoldPale_SunRay" if k % 2 else "Gold_SunRay", "GoldPale" if k % 2 else "Gold", c, (0, 29.0), a, 2.9, 6.4 if k % 2 == 0 else 4.8, 0.45, 0.05, depth=0.3, y=-1.9)
for sx in (-1, 1):
    for k in range(8):
        t = k / 7
        ang = math.radians(sx > 0 and (8 + t * 64) or (172 - t * 64))
        blade(f"Gold_Wing{k}", "Gold" if k % 2 == 0 else "GoldDeep", c, (sx * 10.5, 15.0), ang, 0.5, 8 + 6 * math.sin(t * math.pi), 0.75, 0.05, depth=0.4, y=0.0 + k * 0.05)
recess(c, "Ink_Tunnel", "Ink", OPEN, -1.0, 3.0)
slab2d("Glow_Face", "Glow", c, [(x * 0.98, z) for x, z in OPEN], -0.6, -0.45)

# =====================================================================================================================
c = collection("GateReturnIsland")
prof = [(17 * (1 - (i / 10)) ** 0.6 + 0.01, 2.0 * math.sin(i / 10 * math.pi / 2) ** 0.8) for i in range(11)] + [(0, 2.0)]
solid(roughen(lathe("Sand_Mound", "Sand", c, prof, segments=48), 0.35, 5, 1, 3))
for sx in (-1, 1):
    pts = []
    for i in range(21):
        t = i / 20
        x = sx * (8.5 - 7.6 * t ** 2.2)
        z = 1.0 + 22.0 * math.sin(t * math.pi / 2)
        pts.append(V((x, 0.0, z)))
    solid(sweep("Marble_Rib", "Marble", c, pts, lambda t: circle(1.25 - 0.7 * t, 10, 1.0, 1.35)))
    # knuckles of bone along each rib
    for t in (0.2, 0.45, 0.7):
        i = int(t * 20)
        lathe("Marble_Knuckle", "Marble", c, [(0, -0.9), (1.4, -0.4), (1.4, 0.4), (0, 0.9)], segments=10, loc=pts[i])
# the lashing where the ribs meet, a net hung across the top, shells and a starfish
for k in range(5):
    torus("Rope_Lash", "Rope", c, 1.2, 0.2, seg=14, mseg=4, loc=(0, 0, 21.2 + k * 0.45), rot=(0, math.radians(90), 0))
for i in range(7):
    t = i / 6
    x0 = -6.5 + t * 13
    pts = [V((x0 + math.sin(u * math.pi) * 0.4, -0.9, 21.5 - u * 6.5 - math.sin(t * math.pi) * 1.2 * u)) for u in [j / 6 for j in range(7)]]
    sweep("Rope_Net", "Rope", c, pts, circle(0.07, 4))
for j in range(4):
    z = 21.0 - j * 1.8
    pts = [V((-6.0 + u * 12.0, -0.9, z - math.sin(u * math.pi) * 1.3)) for u in [i / 10 for i in range(11)]]
    sweep("Rope_NetH", "Rope", c, pts, circle(0.07, 4))
for k, (x, z, role) in enumerate([(-7.3, 6, "Shell"), (7.5, 9, "Shell"), (-5.2, 15, "Coral"), (6.0, 16, "Shell")]):
    o = lathe(f"{role}_Hang{k}", role, c, [(0, 0), (1.0, 0.1), (0.8, 0.6), (0, 0.9)], segments=10, smooth=False, loc=(x, -1.3, z))
    o.rotation_euler = (math.radians(80), 0, 0)
OVAL = ellipse(0, 10.6, 6.5, 9.6, 36)
slab2d("Glow_Face", "Glow", c, OVAL, -0.2, 0.0)

# =====================================================================================================================
c = collection("GateReturnForest")
MR, MZ = 8.0, 10.2
circle_pts = ellipse(0, MZ, MR, MR, 40)
for sx, role in ((-1, "White"), (1, "Black")):
    half = slab2d(f"{role}_Wall", role, c, [(0, 0), (sx * 13, 0), (sx * 13, 21), (0, 21)][::(-1 if sx < 0 else 1)], -1.2, 1.2)
    cut(half, slab2d("Cut", role, c, circle_pts, -3, 3))
    solid(half)
    # the other colour's coping and roof tiles on each half
    other = "Black" if role == "White" else "White"
    box(f"{other}_Coping", other, c, (13.6, 3.4, 0.8), loc=(sx * 6.6, 0, 21.4), bevel=0.15)
    for k in range(7):
        o = box(f"{other}_Tile{k}", other, c, (1.6, 4.2, 0.5), loc=(sx * (1.2 + k * 1.85), 0, 22.2), rot=(0, 0, 0), bevel=0.12)
    lathe(f"{role}_Finial", role, c, [(0, 0), (0.9, 0), (0.5, 1.2), (0, 2.4)], segments=8, loc=(sx * 13.0, 0, 21.8))
torus("Stone_MoonRim", "Stone", c, MR + 0.3, 0.45, seg=48, mseg=8, loc=(0, -1.25, MZ), rot=(math.radians(90), 0, 0))
torus("Stone_MoonRimBack", "Stone", c, MR + 0.3, 0.45, seg=48, mseg=8, loc=(0, 1.25, MZ), rot=(math.radians(90), 0, 0))
solid(box("Stone_Sill", "Stone", c, (28, 4.4, 0.8), loc=(0, 0, 0.4), bevel=0.15))
slab2d("Glow_Face", "Glow", c, [(x * 0.99, MZ + (z - MZ) * 0.99) for x, z in circle_pts], -0.15, 0.15)

# =====================================================================================================================
c = collection("IslandShellPortal")


def scallop(name, role, col, radius, ribs=13, lift=0.0, hinge=V((0, 6.0, 1.2)), flip=False):
    """A ribbed scallop valve as a solidified sheet: fan from the hinge (+Y) toward -Y, cupped."""
    bm = bmesh.new()
    NA, NR = 40, 12
    grid = []
    for i in range(NA + 1):
        th = math.radians(-78 + i / NA * 156)
        row = []
        for j in range(NR + 1):
            r = 0.6 + (radius - 0.6) * j / NR
            edge = 1 + 0.035 * math.cos(th * ribs * 2) if j == NR else 1
            rib = 0.35 * (j / NR) * max(0.0, math.cos(th * ribs)) ** 0.6
            cup = 2.6 * (j / NR) ** 1.4 * (1 - (th / math.radians(80)) ** 2) ** 0.5
            x = math.sin(th) * r * edge
            y = -math.cos(th) * r * edge
            z = cup + rib
            row.append(bm.verts.new((x, y, z if not flip else -z)))
        grid.append(row)
    for i in range(NA):
        for j in range(NR):
            bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = obj_from_bm(bm, name, role, col)
    s = o.modifiers.new("Solid", "SOLIDIFY")
    s.thickness = 0.5
    o.rotation_euler = (lift, 0, 0)
    o.location = hinge
    return o


lower = scallop("Shell_Lower", "Shell", c, 11.0, flip=True)
lower.location = (0, 6.0, 3.0)
solid(lower)
upper = scallop("Shell_Upper", "Shell", c, 11.0)
upper.rotation_euler = (math.radians(-62), 0, 0)
upper.location = (0, 6.0, 3.6)
# the hinge knob and the coral-rock base it rests on
lathe("Shell_Hinge", "Shell", c, [(0, -1.4), (1.6, -1.0), (1.8, 0), (1.6, 1.0), (0, 1.4)], segments=12, loc=(0, 6.4, 3.4)).rotation_euler = (0, math.radians(90), 0)
base = rock("Rock_Base", "Rock", c, (20, 16, 5.0), loc=(0, 0.5, 0.8), seed=12, detail=2, rough=0.25)
solid(base)
rr = random.Random(5)
for k in range(9):
    a = rr.uniform(0, math.tau)
    p = V((math.cos(a) * rr.uniform(7, 10), math.sin(a) * rr.uniform(5, 8), 2.6))
    sweep(f"Coral_Branch{k}", "Coral", c, [p, p + V((rr.uniform(-1, 1), rr.uniform(-1, 1), 2.2)), p + V((rr.uniform(-1.5, 1.5), rr.uniform(-1.5, 1.5), 3.6))], lambda t: circle(0.35 * (1 - t * 0.6), 6))
# the pearl glow between the valves (an oval face standing in the gape)
slab2d("Glow_Face", "Glow", c, ellipse(0, 9.2, 7.6, 5.8, 32), -0.6, -0.4)

# =====================================================================================================================
c = collection("HubFountain")
# outer basin: a moulded rim round a shallow pool
solid(lathe("Marble_Basin", "Marble", c, [(0, 0), (13.0, 0), (13.4, 0.6), (13.2, 2.4), (13.6, 2.8), (13.6, 3.2), (12.4, 3.2), (12.2, 1.0), (0, 1.0)], segments=64))
torus("Gold_BasinTrim", "Gold", c, 13.45, 0.15, seg=64, mseg=4, loc=(0, 0, 2.6))
lathe("Water_Pool", "Water", c, [(0, 2.4), (12.3, 2.4), (12.3, 2.6), (0, 2.6)], segments=48)
# the stem: a baluster with leaf mouldings, carrying a middle bowl
lathe("Marble_Stem", "Marble", c, [(0, 1.0), (3.0, 1.0), (3.0, 2.0), (2.0, 2.6), (1.4, 4.0), (2.0, 5.4), (1.3, 6.6), (1.5, 7.2), (0, 7.2)], segments=32)
lathe("Marble_Bowl2", "Marble", c, [(0, 7.0), (1.6, 7.0), (4.6, 8.0), (6.6, 9.0), (7.0, 9.6), (6.6, 9.8), (6.2, 9.4), (0, 9.4)], segments=48)
lathe("Water_Pool2", "Water", c, [(0, 9.3), (6.25, 9.3), (6.25, 9.5), (0, 9.5)], segments=40)
lathe("Marble_Stem2", "Marble", c, [(0, 9.4), (1.4, 9.4), (0.9, 11.0), (1.2, 12.2), (0.8, 13.4), (0, 13.4)], segments=24)
lathe("Marble_Bowl3", "Marble", c, [(0, 13.2), (1.0, 13.2), (2.6, 14.0), (3.6, 14.8), (3.8, 15.2), (3.4, 15.3), (0, 15.0)], segments=32)
lathe("Water_Pool3", "Water", c, [(0, 14.9), (3.4, 14.9), (3.4, 15.1), (0, 15.1)], segments=28)
# falling sheets of water from each bowl's lip (thin open shells; see-through)
for r0, z0, z1 in ((6.9, 9.6, 2.6), (3.75, 15.1, 9.5)):
    lathe(f"Water_Curtain{r0}", "Water", c, [(r0, z0), (r0 + 0.5, (z0 + z1) / 2), (r0 + 0.9, z1), (r0 + 0.85, z1), (r0 + 0.45, (z0 + z1) / 2), (r0 - 0.05, z0)], segments=48)
# a gold armillary sphere on a short spire at the top
lathe("Gold_Spire", "Gold", c, [(0, 15.0), (0.7, 15.0), (0.4, 16.6), (0, 17.0)], segments=12)
for k, rot in enumerate([(0, 0, 0), (math.radians(90), 0, 0), (math.radians(90), 0, math.radians(90)), (math.radians(66), 0, math.radians(30))]):
    torus(f"Gold_Ring{k}", "Gold" if k < 3 else "GoldPale", c, 2.2, 0.16, seg=40, mseg=6, loc=(0, 0, 19.2), rot=rot)
lathe("GoldPale_Core", "GoldPale", c, [(0, -0.9), (0.7, -0.6), (0.9, 0), (0.7, 0.6), (0, 0.9)], segments=16, loc=(0, 0, 19.2))
lathe("Gold_Axis", "Gold", c, [(0.08, -2.8), (0.08, 2.8), (0, 2.9)], segments=6, loc=(0, 0, 19.2)).rotation_euler = (math.radians(23), 0, 0)
# four lion-head spouts round the stem pouring into the pool
for k in range(4):
    a = k / 4 * math.tau + math.pi / 4
    p = V((math.cos(a) * 2.7, math.sin(a) * 2.7, 3.6))
    lathe("Gold_Spout", "Gold", c, [(0, -0.6), (0.7, -0.4), (0.8, 0.2), (0.4, 0.6), (0, 0.7)], segments=10, loc=p)
    sweep("Water_Jet", "Water", c, [p + V((math.cos(a) * 0.5, math.sin(a) * 0.5, 0)), p + V((math.cos(a) * 2.6, math.sin(a) * 2.6, -0.2)), p + V((math.cos(a) * 3.8, math.sin(a) * 3.8, -1.2))], circle(0.18, 6))

# =====================================================================================================================
for idx, (w, d, h, seed) in enumerate([(150, 60, 120, 81), (130, 70, 140, 97)]):
    c = collection(f"ForestMountain{idx + 1}")
    m = rock("Rock_Mass", "Rock", c, (w, d, h), loc=(0, 0, h * 0.3), seed=seed, detail=3, rough=0.4)
    solid(roughen(m, strength=8.0, size=14.0, levels=1, seed=seed))
    rr = random.Random(seed)
    for k in range(4):
        sw, sh = rr.uniform(18, 30), rr.uniform(40, 70)
        rock(f"Rock_Spire{k}", "Rock", c, (sw, sw * 0.8, sh), loc=(rr.uniform(-w * 0.35, w * 0.35), rr.uniform(-d * 0.2, d * 0.2), h * 0.55 + sh * 0.25), seed=seed + k, detail=2, rough=0.35)
    for k in range(3):
        rock(f"Stone_Scree{k}", "Stone", c, (rr.uniform(20, 34), rr.uniform(14, 22), rr.uniform(8, 14)), loc=(rr.uniform(-w * 0.4, w * 0.4), -d * 0.45, 3), seed=seed + 10 + k, detail=2, rough=0.3)

# =====================================================================================================================
c = collection("KeeperHat")
lathe("Blue_Hat", "Blue", c, [(0, -0.1), (1.9, -0.1), (2.0, 0.05), (1.0, 0.25), (0.85, 1.0), (0.6, 2.0), (0.35, 2.8), (0.12, 3.3), (0, 3.4)], segments=24)
torus("Gold_HatBand", "Gold", c, 0.93, 0.1, seg=24, mseg=4, loc=(0, 0, 0.35))
for k in range(5):
    a = k / 5 * math.tau
    lathe(f"GoldPale_Star{k}", "GoldPale", c, [(0, -0.12), (0.18, 0), (0, 0.12)], segments=5, smooth=False, loc=(math.cos(a) * 0.72, math.sin(a) * 0.72, 1.2 + k * 0.35))
c = collection("KeeperBeard")
b = sculpt("White_Beard", "White", c, [("ELLIPSOID", (0, 0, -0.3), 0.75, (1.0, 0.55, 0.9)), capsule((0, -0.1, -0.5), (0, -0.25, -2.0), 0.5), ("BALL", (0, -0.3, -2.1), 0.3, None)], resolution=0.08, threshold=0.25)
decimate(b, 0.5)
c = collection("BroHeadband")
torus("Sash_Band", "Sash", c, 0.68, 0.12, seg=24, mseg=6, loc=(0, 0, 0.25), scale_minor=(1, 1.6))
for sx in (-1, 1):
    pts = [V((sx * 0.15, 0.7, 0.25)), V((sx * 0.35, 1.3, 0.05)), V((sx * 0.5, 2.0, -0.35))]
    sweep("Sash_Tail", "Sash", c, pts, lambda t: [(-0.06, -0.18), (0.06, -0.18), (0.06, 0.18), (-0.06, 0.18)], smooth=False)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name in ("GateReturnPalace", "GateReturnIsland", "GateReturnForest", "IslandShellPortal", "HubFountain", "ForestMountain1", "ForestMountain2", "KeeperHat", "KeeperBeard", "BroHeadband")})
