# Portal gates, round 2: every gate has its own shape. Each piece: origin = ground centre of the gate, front = -Y. The glowing face is a
# mesh of role Glow shaped like the opening (the builder tints it and adds the trigger, light and particles).
#   GateGolden          the Golden Encounter: a monumental gilded door between two deco pylons, crowned. Opening 18 x 30, arched.
#   GoldenLeafL / R     its two door leaves; origin = the hinge at the bottom of the opening's edge (x -9 / +9 in the gate).
#   GateFallen          TheFallenNoob's island: a galleon's bow rearing out of a dune, the portal is a hole torn in its side.
#   GateBrothers        Jeff n' Fred: a white and a black greatsword driven into a split floor, crossing; the portal is the space
#                       between the blades.
#   GateReturn          back to the Sanctum: a white marble arch with gold wings, on cloud. Opening 14 x 21.
#   GateParty           the palace's party gates: a baroque mirror frame on twisted columns. Opening 16 x 24, arched.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())


def arch_moulding(col, name, role, hw, z0, spring, y, prof, n=28):
    path = [Vector((-hw, y, z0)), Vector((-hw, y, spring))]
    for i in range(1, n):
        a = math.pi - i / n * math.pi
        path.append(Vector((math.cos(a) * hw, y, spring + math.sin(a) * hw)))
    path += [Vector((hw, y, spring)), Vector((hw, y, z0))]
    return sweep(name, role, col, path, prof)


def recess(col, name, role, outline, y0, depth):
    """A dark tunnel behind an opening: the outline extruded backwards, open at the front, closed at the back."""
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


def crown(col, z, scale=1.0, y=0.0):
    s = scale
    lathe("Gold_CrownBand", "Gold", col, [(9.6 * s, 0), (9.8 * s, 0.2 * s), (9.8 * s, 3.2 * s), (9.6 * s, 3.4 * s), (9.0 * s, 3.4 * s), (9.0 * s, 0)], segments=48, loc=(0, y, z))
    torus("GoldDeep_CrownBead", "GoldDeep", col, 9.85 * s, 0.35 * s, seg=48, mseg=6, loc=(0, y, z + 0.4 * s))
    for i in range(10):
        a = i / 10 * math.tau + math.pi / 2
        p = Vector((math.cos(a) * 9.4 * s, y + math.sin(a) * 9.4 * s, z + 3.2 * s))
        h = (6.5 if i % 2 == 0 else 4.2) * s
        o = lathe(f"Gold_Point{i}", "Gold", col, [(1.3 * s, 0), (1.15 * s, h * 0.4), (0.7 * s, h * 0.8), (0.0, h)], segments=8, smooth=False)
        o.location = p
        o.rotation_euler = Euler((-math.sin(a) * 0.15, math.cos(a) * 0.15, 0))
        b = lathe(f"GoldPale_Ball{i}", "GoldPale", col, [(0, -0.75 * s), (0.53 * s, -0.53 * s), (0.75 * s, 0), (0.53 * s, 0.53 * s), (0, 0.75 * s)], segments=10)
        b.location = p + Vector((math.cos(a) * 0.15 * h, math.sin(a) * 0.15 * h, h + 0.3 * s))
        if i % 2 == 0:
            g = lathe(f"Gem{i}", "GemRed" if i % 4 == 0 else "GemBlue", col, [(0, -0.9 * s), (0.9 * s, 0), (0, 0.9 * s)], segments=6, smooth=False)
            g.location = Vector((math.cos(a) * 10.0 * s, y + math.sin(a) * 10.0 * s, z + 1.7 * s))
            g.rotation_euler = (math.radians(90), 0, a + math.pi / 2)
    for k in range(2):
        a = k * math.pi / 2
        path = []
        for i in range(21):
            t = i / 20 * math.pi
            r = 9.3 * s * math.cos(t)
            path.append(Vector((math.cos(a) * r, y + math.sin(a) * r, z + 3.3 * s + math.sin(t) * 5.5 * s)))
        sweep(f"Gold_CrownArch{k}", "Gold", col, path, circle(0.45 * s, 8))
    lathe("Gold_Orb", "Gold", col, [(0, -1.4 * s), (1.0 * s, -1.0 * s), (1.4 * s, 0), (1.0 * s, 1.0 * s), (0, 1.4 * s)], segments=16, loc=(0, y, z + 10.2 * s))
    box("Gold_CrossV", "Gold", col, (0.6 * s, 0.6 * s, 3.2 * s), loc=(0, y, z + 12.8 * s), bevel=0.12 * s)
    box("Gold_CrossH", "Gold", col, (2.2 * s, 0.6 * s, 0.6 * s), loc=(0, y, z + 13.1 * s), bevel=0.12 * s)
    lathe("Ink_CrownCap", "Ink", col, [(0, 0), (9.0 * s, 0), (6 * s, 2.5 * s), (0, 4.5 * s)], segments=24, loc=(0, y, z + 0.6 * s))


# =====================================================================================================================
# GateGolden
g = collection("GateGolden")
HW, Z0, SPR = 9.0, 3.0, 21.0  # opening half-width, floor, springing (top of the arch = 30)
# base: three broad steps with gold nosing, wider at the front
for i, (w, d, h) in enumerate([(56, 30, 1.0), (50, 25, 2.0), (44, 20, 3.0)]):
    solid(box(f"MarbleDark_Step{i}", "MarbleDark", g, (w, d, 1.0), loc=(0, 1.5 - i * 0.5, h - 0.5), bevel=0.15))
    box(f"Gold_Nose{i}", "Gold", g, (w + 0.1, 0.35, 0.25), loc=(0, 1.5 - i * 0.5 - d / 2, h - 0.12))
# pylons: tapered deco towers with gold fins and a sun disc near the top
for sx in (-1, 1):
    x = sx * 17.5
    bm = bmesh.new()
    lo = [(-5.0, -5.0), (5.0, -5.0), (5.0, 5.0), (-5.0, 5.0)]
    hi = [(-3.6, -3.8), (3.6, -3.8), (3.6, 3.8), (-3.6, 3.8)]
    vb = [bm.verts.new((x + u, v, 3.0)) for u, v in lo]
    vt = [bm.verts.new((x + u, v, 46.0)) for u, v in hi]
    bm.faces.new(list(reversed(vb)))
    bm.faces.new(vt)
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((vb[i], vb[j], vt[j], vt[i]))
    o = obj_from_bm(bm, "GoldDeep_Pylon", "GoldDeep", g, smooth=False)
    bev(o, 0.35, 2)
    solid(o)
    box("Gold_PylonCap", "Gold", g, (9.0, 9.4, 1.6), loc=(x, 0, 46.8), bevel=0.3)
    box("GoldDeep_PylonCap2", "GoldDeep", g, (6.4, 6.8, 2.2), loc=(x, 0, 48.7), bevel=0.3)
    lathe("Gold_PylonFinial", "Gold", g, [(0, 0), (2.2, 0), (1.6, 1.6), (0.6, 4.6), (0, 7.0)], segments=12, loc=(x, 0, 49.8))
    for f in (-2.4, -0.8, 0.8, 2.4):
        # fins taper with the pylon's front face
        sweep("Gold_Fin", "Gold", g, [Vector((x + f, -5.15, 4.0)), Vector((x + f * 0.72, -3.95, 34.0))], [(-0.28, -0.25), (0.28, -0.25), (0.28, 0.25), (-0.28, 0.25)], smooth=False)
    # sun disc with rays, high on the front face
    lathe("Gold_SunDisc", "Gold", g, [(0, 0), (2.6, 0), (2.6, 0.5), (2.0, 0.8), (0, 0.9)], segments=24, loc=(x, -4.2, 39.5)).rotation_euler = (math.radians(90), 0, 0)
    for k in range(16):
        a = k / 16 * math.tau
        blade("Gold_SunRay" if k % 2 == 0 else "GoldPale_SunRay", "Gold" if k % 2 == 0 else "GoldPale", g, (x, 39.5), a, 2.8, 5.2 if k % 2 == 0 else 4.0, 0.45, 0.02, depth=0.3, y=-4.1)
# the doorway surround: a thick wall between the pylons with the arch cut through, layered gold mouldings
outline = arch_outline(HW, Z0, SPR, n=28)
wall = slab2d("Gold_Wall", "Gold", g, [(-13, Z0), (13, Z0), (13, 40), (-13, 40)], -2.5, 2.5)
cutter = slab2d("Cutter", "Gold", g, outline, -4, 4)
solid(cut(wall, cutter))
for k, (dw, dy, r, role) in enumerate([(0.0, -2.8, 0.9, "GoldDeep"), (1.6, -3.0, 0.7, "Gold"), (3.0, -2.9, 0.5, "GoldPale")]):
    arch_moulding(g, f"{role}_Arch{k}", role, HW + dw, Z0, SPR, dy, circle(r, 10))
box("GoldDeep_Keystone", "GoldDeep", g, (3.0, 1.6, 4.6), loc=(0, -3.0, SPR + HW + 2.2), bevel=0.3)
lathe("GemRed_Keygem", "GemRed", g, [(0, -1.0), (1.0, 0), (0, 1.0)], segments=6, loc=(0, -3.9, SPR + HW + 2.4), smooth=False).rotation_euler = (math.radians(90), 0, 0)
# reliefs in the spandrels: fans of rays out from the arch
for sx in (-1, 1):
    for k in range(5):
        a = math.radians(90 + sx * (20 + k * 14))
        blade("GoldPale_Spandrel", "GoldPale", g, (0, SPR), a, HW + 4.2, HW + 7.6 + (k % 2) * 1.6, 0.5, 0.15, depth=0.3, y=-2.65)
# entablature and the crown
box("GoldDeep_Lintel", "GoldDeep", g, (40, 7.0, 2.4), loc=(0, 0, 41.2), bevel=0.4)
box("Gold_Cornice", "Gold", g, (42, 8.0, 1.0), loc=(0, 0, 42.9), bevel=0.3)
for x in range(-18, 19, 3):
    box("GoldPale_Dentil", "GoldPale", g, (1.2, 0.6, 1.0), loc=(x, -3.75, 40.4))
crown(g, 43.4, 0.9)
# the dark tunnel behind the opening, and the glowing face just inside it
recess(g, "Ink_Tunnel", "Ink", outline, 0.6, 6.0)
slab2d("Glow_Face", "Glow", g, arch_outline(HW - 0.1, Z0, SPR, n=28), 1.0, 1.25)

# door leaves: each half of the arched opening, a gold slab with panels and half a sunburst; hinge at the origin
def leaf(name, side):
    col = collection(name)
    # side -1: left leaf, spans x 0..9 (toward the middle); side +1: right leaf spans x -9..0
    pts = []
    pts.append((0.0, 0.0))
    for i in range(15):
        t = i / 14
        a = math.pi - t * math.pi / 2  # quarter arch from the outer edge up to the crown
        x = HW + math.cos(a) * HW  # 0 at the outer edge -> 9 at the middle
        z = (SPR - Z0) + math.sin(a) * HW
        pts.append((x, z))
    pts.append((HW - 0.05, 0.0))
    if side > 0:
        pts = [(-u, v) for u, v in reversed(pts)]
    solid(slab2d("Gold_Leaf", "Gold", col, pts, -0.6, 0.6))
    sx = 1 if side < 0 else -1
    for row, (zc, h) in enumerate([(4.0, 6.0), (11.5, 6.0), (19.0, 6.0)]):
        box("GoldDeep_Panel", "GoldDeep", col, (6.4, 0.4, h), loc=(sx * HW / 2, -0.75, zc), bevel=0.2)
        box("GoldPale_PanelIn", "GoldPale", col, (5.0, 0.3, h - 1.6), loc=(sx * HW / 2, -0.95, zc), bevel=0.2)
    # half sunburst at the top of the leaf, centred on the meeting edge
    for k in range(6):
        a = math.radians(90 + sx * (8 + k * 15))
        blade("GoldPale_LeafRay", "GoldPale", col, (sx * HW, SPR - Z0), a, 1.2, 6.5 if k % 2 == 0 else 5.0, 0.4, 0.05, depth=0.3, y=-0.75)
    torus("GoldPale_Ring", "GoldPale", col, 0.9, 0.18, seg=20, mseg=6, loc=(sx * (HW - 1.4), -1.0, 13.0), rot=(math.radians(90), 0, 0))
    return col


leaf("GoldenLeafL", -1)
leaf("GoldenLeafR", 1)

# =====================================================================================================================
# GateFallen
fl = collection("GateFallen")
rnd = random.Random(3)


def roughen(o, strength=1.0, size=2.0, levels=1, seed=0):
    if levels:
        sub = o.modifiers.new("Sub", "SUBSURF")
        sub.levels = levels
    tex = bpy.data.textures.get(f"GNoise{seed}") or bpy.data.textures.new(f"GNoise{seed}", "CLOUDS")
    tex.noise_scale = size
    d = o.modifiers.new("Disp", "DISPLACE")
    d.texture = tex
    d.strength = strength
    return o


prof = [(34 * (1 - (i / 12)) ** 0.55 + 0.01, 4.5 * math.sin(i / 12 * math.pi / 2) ** 0.7) for i in range(13)] + [(0, 4.5)]
solid(roughen(lathe("Sand_Dune", "Sand", fl, prof, segments=64), 0.7, 6, 1, 1))
# the hull: a galleon bow, lying along X with the stem rising up and to the right out of the sand; its side faces the front (-Y)
ST = 22
stations = []
for j in range(ST + 1):
    t = j / ST
    x = -26 + t * 50
    beam = 9.5 * (1 - max(0.0, (t - 0.55) / 0.45) ** 2) + 0.4
    keel = -6.0 + 9.0 * max(0.0, (t - 0.7) / 0.3) ** 2
    sheer = 22.0 + 6.0 * max(0.0, (t - 0.6) / 0.4) ** 2
    pts = []
    for k in range(15):
        u = k / 14
        ang = math.pi * u
        y = -math.cos(ang) * beam
        z = keel + (sheer - keel) * (1 - math.sin(ang) ** 0.55)
        pts.append(Vector((x, y, z)))
    stations.append(pts)
bm = bmesh.new()
rings = [[bm.verts.new(p) for p in st] for st in stations]
for j in range(ST):
    for k in range(14):
        bm.faces.new((rings[j][k], rings[j][k + 1], rings[j + 1][k + 1], rings[j + 1][k]))
bm.faces.new(list(rings[0]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
hull = obj_from_bm(bm, "Plank_Hull", "Plank", fl)
s = hull.modifiers.new("Solid", "SOLIDIFY")
s.thickness = 0.9
s.offset = -1
# tilt the whole bow up out of the dune
tilt = Matrix.Rotation(math.radians(14), 4, "Y")
hull.data.transform(tilt)
bpy.context.view_layer.update()
# the torn hole: a ragged oval cut through the front side
HOLE = []
for i in range(28):
    a = i / 28 * math.tau
    r = 1 + 0.12 * math.sin(a * 5 + 1) + 0.08 * math.sin(a * 9)
    HOLE.append((math.cos(a) * 8.0 * r, 15.0 + math.sin(a) * 11.0 * r))
cutter = slab2d("Cutter", "Plank", fl, HOLE, -14, -4)
solid(cut(hull, cutter))
# plank seams and ribs along the outside
def in_hole(p, pad=1.0):
    return (p.x / (8.8 + pad)) ** 2 + ((p.z - 15) / (12.0 + pad)) ** 2 < 1


for k in range(7):
    z = 1 + k * 3.4
    run = []
    for x in [x * 0.5 for x in range(-48, 46, 3)]:
        t = (x + 26) / 50
        beam = 9.5 * (1 - max(0.0, (t - 0.55) / 0.45) ** 2) + 0.4
        p = tilt @ Vector((x, -beam - 0.15, z))
        if in_hole(p):
            if len(run) > 1:
                sweep("WoodDark_Wale", "WoodDark", fl, run, [(-0.3, -0.3), (0.3, -0.3), (0.3, 0.3), (-0.3, 0.3)], smooth=False)
            run = []
        else:
            run.append(p)
    if len(run) > 1:
        sweep("WoodDark_Wale", "WoodDark", fl, run, [(-0.3, -0.3), (0.3, -0.3), (0.3, 0.3), (-0.3, 0.3)], smooth=False)
# a deck inside the bulwarks, and a rail of posts along both gunwales
deck = []
for side in (-1, 1):
    xs = range(-25, 24, 2) if side < 0 else range(23, -26, -2)
    for x in xs:
        t = (x + 26) / 50
        beam = 9.5 * (1 - max(0.0, (t - 0.55) / 0.45) ** 2) + 0.4
        deck.append((x, side * max(beam - 0.8, 0.3)))
d = slab2d("Plank_Deck", "Plank", fl, deck, 18.5, 19.2, plane="xy")
d.data.transform(tilt)
for side in (-1, 1):
    rail = []
    for x in range(-24, 23, 3):
        t = (x + 26) / 50
        beam = 9.5 * (1 - max(0.0, (t - 0.55) / 0.45) ** 2) + 0.4
        sheer = 22.0 + 6.0 * max(0.0, (t - 0.6) / 0.4) ** 2
        base = tilt @ Vector((x, side * beam, sheer))
        top = tilt @ Vector((x, side * beam, sheer + 2.6))
        sweep("WoodDark_RailPost", "WoodDark", fl, [base, top], circle(0.25, 6))
        rail.append(top)
    sweep("WoodDark_Rail", "WoodDark", fl, rail, circle(0.3, 6))
# broken ribs showing round the hole
for k in range(8):
    a = k / 8 * math.tau
    p = tilt @ Vector((math.cos(a) * 9.6, -9.0, 15 + math.sin(a) * 12.5))
    rock(f"WoodDark_Splinter{k}", "WoodDark", fl, (0.7, 0.7, 3.2), loc=p, seed=60 + k, detail=1, rough=0.4).rotation_euler = (rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6), a)
# inside: a dark hold, and the glowing face set into the hole
slab2d("Glow_Face", "Glow", fl, [(u * 0.97, 15 + (v - 15) * 0.97) for u, v in HOLE], -6.0, -5.8)
# a broken mast and a tattered sail, rigging down to the sand
mast_base = tilt @ Vector((4, 0, 21))
mtop = mast_base + Vector((-9, -2, 26))
sweep("WoodDark_Mast", "WoodDark", fl, [mast_base, mtop], lambda t: circle(0.9 - t * 0.35, 10))
yard_a, yard_b = mtop + Vector((-1, -8, -4)), mtop + Vector((1, 8, -4))
sweep("WoodDark_Yard", "WoodDark", fl, [yard_a, yard_b], circle(0.35, 8))
SU, SV = 10, 8
bm = bmesh.new()
grid = []
for i in range(SU + 1):
    u = i / SU
    row = []
    for j in range(SV + 1):
        v = j / SV
        p = yard_a.lerp(yard_b, u) + Vector((-0.2, 0, -v * 13))
        p.x -= math.sin(u * math.pi) * math.sin(v * math.pi) * 2.8
        ragged = v > 0.75 and (i % 3 == 1)
        if ragged:
            p.z += 1.4
        row.append(bm.verts.new(p))
    grid.append(row)
for i in range(SU):
    for j in range(SV):
        if not (j == SV - 1 and i % 4 == 2) and not (i == 6 and j in (3, 4)):
            bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
sail = obj_from_bm(bm, "Fabric_Sail", "Fabric", fl)
sail.modifiers.new("Solid", "SOLIDIFY").thickness = 0.15
for end in (Vector((-22, -18, 2.5)), Vector((14, -22, 2.5)), Vector((-14, 20, 2.5))):
    sweep("Rope_Rig", "Rope", fl, [mtop + Vector((0, 0, -1)), end], circle(0.12, 5))
# the bowsprit and a carved scroll figurehead at the stem
stem = tilt @ Vector((24.5, 0, 26))
sweep("WoodDark_Bowsprit", "WoodDark", fl, [stem, stem + Vector((10, 0, 7))], lambda t: circle(0.8 - t * 0.4, 8))
torus("Gold_Scroll", "Gold", fl, 1.6, 0.45, seg=20, mseg=8, loc=stem + Vector((1.5, 0, -1.0)), rot=(math.radians(90), 0, 0))
# a lantern hanging at the bow, a treasure chest spilling gold at the front, an anchor, barrels
lathe("Iron_Lantern", "Iron", fl, [(0, 0), (0.9, 0), (0.9, 0.3), (0.7, 0.4), (0.7, 2.2), (1.1, 2.4), (0.3, 3.2), (0, 3.4)], segments=8, loc=stem + Vector((6, 0, 1.0)))
chest = Vector((-9, -22, 3.6))
box("WoodDark_Chest", "WoodDark", fl, (6.0, 4.0, 3.2), loc=chest, rot=(0, 0, 0.25), bevel=0.25)
lid = lathe("Plank_Lid", "Plank", fl, [(0, -3.0), (2.0, -3.0), (2.0, 3.0), (0, 3.0)], segments=12)
lid.location = chest + Vector((0.6, 2.6, 2.6))
lid.rotation_euler = (math.radians(-60), math.radians(90), 0.25)
for k in range(3):
    box("Gold_ChestBand", "Gold", fl, (0.4, 4.1, 3.3), loc=chest + Vector((-2.2 + k * 2.2, 0, 0)), rot=(0, 0, 0.25))
for k in range(36):
    a = rnd.uniform(0, math.tau)
    d = rnd.uniform(0, 6) ** 0.8
    p = chest + Vector((math.cos(a) * d - 1, math.sin(a) * d - 3, -0.9 + rnd.uniform(0, 1.6) * (1 - d / 5)))
    o = lathe(f"Gold_Coin{k}", "Gold", fl, [(0, 0), (0.6, 0), (0.6, 0.15), (0, 0.15)], segments=10)
    o.location = p
    o.rotation_euler = (rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6), 0)
for k in range(6):
    g2 = lathe(f"GemCoin{k}", "GemRed" if k % 2 else "GemBlue", fl, [(0, -0.6), (0.6, 0), (0, 0.6)], segments=6, smooth=False)
    g2.location = chest + Vector((rnd.uniform(-3, 2), rnd.uniform(-5, -2), 0.0))
anc = Vector((20, -16, 2.0))
sweep("Iron_AnchorShank", "Iron", fl, [anc, anc + Vector((-2, 0, 11))], circle(0.6, 8))
arc = [anc + Vector((math.cos(math.radians(x)) * 4.2, 0, 3.8 + math.sin(math.radians(x)) * 3.8)) for x in range(190, 351, 10)]
sweep("Iron_AnchorArms", "Iron", fl, arc, circle(0.55, 8))
torus("Iron_AnchorRing", "Iron", fl, 1.2, 0.28, seg=20, mseg=6, loc=anc + Vector((-2.2, 0, 12.0)), rot=(math.radians(90), 0, 0))
chain = [anc + Vector((-2.2, 0, 11)) + Vector((-t * 9, -t * 4, -t * 9 + math.sin(t * math.pi) * -1.5)) for t in [i / 12 for i in range(13)]]
for k in range(len(chain) - 1):
    torus(f"Iron_Link{k}", "Iron", fl, 0.6, 0.18, seg=10, mseg=4, loc=chain[k], rot=(0, (k % 2) * math.radians(90), 0))
for k, (x, y, lie) in enumerate([(-22, -10, False), (-19, -14, True), (12, -24, False)]):
    b = lathe(f"Wood_Barrel{k}", "Wood", fl, [(0, 0), (1.6, 0), (1.85, 0.6), (2.05, 1.7), (1.85, 2.8), (1.6, 3.4), (0, 3.4)], segments=16)
    b.location = (x, y, 4.0 if not lie else 5.6)
    if lie:
        b.rotation_euler = (math.radians(90), 0, 0.7)
for k in range(10):
    a = rnd.uniform(0, math.tau)
    d = rnd.uniform(12, 30)
    p = Vector((math.cos(a) * d, math.sin(a) * d - 4, 4.0 - d / 10))
    if k % 2 == 0:
        bm = bmesh.new()
        c = bm.verts.new(p + Vector((0, 0, 0.35)))
        outer = [bm.verts.new(p + Vector((math.cos(j / 10 * math.tau) * (1.4 if j % 2 == 0 else 0.5), math.sin(j / 10 * math.tau) * (1.4 if j % 2 == 0 else 0.5), 0))) for j in range(10)]
        for j in range(10):
            bm.faces.new((c, outer[j], outer[(j + 1) % 10]))
        bm.faces.new(list(reversed(outer)))
        obj_from_bm(bm, f"Star{k}", "Red", fl, smooth=False)
    else:
        lathe(f"Marble_Shell{k}", "Marble", fl, [(0, 0), (1.0, 0.1), (0.8, 0.6), (0, 0.9)], segments=10, smooth=False).location = p

# =====================================================================================================================
# GateBrothers
br = collection("GateBrothers")
FR = 24.0


def yin_outline(radius, n=40):
    pts = [(math.cos(math.pi / 2 + i / n * math.pi) * radius, math.sin(math.pi / 2 + i / n * math.pi) * radius) for i in range(n + 1)]
    h = radius / 2
    pts += [(math.cos(-math.pi / 2 - i / (n // 2) * math.pi) * h, -h + math.sin(-math.pi / 2 - i / (n // 2) * math.pi) * h) for i in range(1, n // 2 + 1)]
    pts += [(math.cos(-math.pi / 2 + i / (n // 2) * math.pi) * h, h + math.sin(-math.pi / 2 + i / (n // 2) * math.pi) * h) for i in range(1, n // 2)]
    return pts


def rot2(pts, a):
    c, s = math.cos(a), math.sin(a)
    return [(x * c - y * s, x * s + y * c) for x, y in pts]


solid(lathe("Stone_Rim", "Stone", br, [(0, 0), (FR + 1.8, 0), (FR + 1.8, 0.9), (FR + 1.3, 1.4), (0, 1.4)], segments=96))
solid(slab2d("White_Yin", "White", br, yin_outline(FR), 1.4, 1.75, plane="xy"))
solid(slab2d("Black_Yang", "Black", br, rot2(yin_outline(FR), math.pi), 1.4, 1.75, plane="xy"))
lathe("Black_Dot", "Black", br, [(0, 1.4), (FR / 7, 1.4), (FR / 7, 1.85), (0, 1.85)], segments=32, loc=(0, FR / 2, 0))
lathe("White_Dot", "White", br, [(0, 1.4), (FR / 7, 1.4), (FR / 7, 1.85), (0, 1.85)], segments=32, loc=(0, -FR / 2, 0))
for i in range(2):
    solid(box(f"Stone_Step{i}", "Stone", br, (16 - i * 3, 3.2, 0.7), loc=(0, -(FR + 2.8) + i * 1.5, 0.35 + i * 0.7), bevel=0.1))
# two greatswords, point down in the floor at x = -+13, leaning in so they cross at (0, 40)
CROSS = Vector((0, 0, 30.0))
for sx, role, grip in ((-1, "White", "Black"), (1, "Black", "White")):
    foot = Vector((sx * 13.0, 0, 0.5))
    axis = (CROSS - foot).normalized()
    up_len = 58.0
    tip = foot - axis * 2.0
    hilt = foot + axis * 44.0
    side = axis.cross(Vector((0, 1, 0))).normalized()
    yoff = Vector((0, sx * 0.9, 0))  # the blades pass each other, one in front of the other

    def bsec(t):
        w = 0.4 + 3.2 * min(1.0, t * 8) * (1 - 0.15 * t)  # point flaring to full width, narrowing a touch to the guard
        return [(-0.15, -w), (0.15, -w), (0.55, 0), (0.15, w), (-0.15, w), (-0.55, 0)]

    BL = 54.0
    pts = [tip + yoff + axis * (BL * i / 20) for i in range(21)]
    # sweep's frame: side x = across the blade's thickness (Y), up y = across its width
    # hint +Y: the sweep's side axis lies in the front plane (across the blade's width), its up axis along Y (thickness)
    o = sweep(f"{role}_Blade", role, br, pts, lambda t: [(y, x) for x, y in bsec(t)], smooth=False, hint=(0, 1, 0))
    solid(o)
    # fuller: a dark groove line down the middle of each face
    for fy in (-0.6, 0.6):
        sweep(f"{grip}_Fuller", grip, br, [tip + yoff + axis * 8 + Vector((0, fy, 0)), tip + yoff + axis * (BL - 5) + Vector((0, fy, 0))], circle(0.18, 5), smooth=False)
    g0 = tip + yoff + axis * BL
    # guard: a broad swept crossguard with curled tips
    gpts = [g0 + side * (u * 6.5) + axis * (abs(u) ** 2 * 1.4) for u in [i / 10 * 2 - 1 for i in range(11)]]
    sweep("Gold_Guard", "Gold", br, gpts, lambda t: circle(0.55 + 0.35 * abs(t - 0.5) * 2, 8))
    for e in (gpts[0], gpts[-1]):
        lathe("Gold_GuardTip", "Gold", br, [(0, -0.9), (0.9, 0), (0, 0.9)], segments=8, loc=e)
    # grip: wrapped, with a gold pommel
    sweep(f"{grip}_Grip", grip, br, [g0 + axis * 0.6, g0 + axis * 9.0], lambda t: circle(0.85 + 0.12 * math.sin(t * math.pi * 12), 10))
    pm = lathe("Gold_Pommel", "Gold", br, [(0, -1.4), (1.2, -0.8), (1.5, 0), (1.2, 0.8), (0, 1.4)], segments=12)
    pm.location = g0 + axis * 10.4
    # a cracked hole where each blade went into the floor
    rock(f"Stone_Rubble{sx}", "Stone", br, (5, 4, 1.2), loc=foot + Vector((0, 0, 1.6)), seed=70 + sx, detail=2, rough=0.35)
# the medallion where the blades cross, bound with a chain
med = CROSS + Vector((0, -1.8, 0))
lathe("Stone_Medal", "Stone", br, [(0, -0.5), (5.0, -0.5), (5.0, 0.5), (0, 0.5)], segments=48, loc=med).rotation_euler = (math.radians(90), 0, 0)
slab2d("White_MedYin", "White", br, [(x, CROSS.z + y) for x, y in yin_outline(4.4, 32)], -2.6, -2.35)
slab2d("Black_MedYang", "Black", br, [(x, CROSS.z + y) for x, y in rot2(yin_outline(4.4, 32), math.pi)], -2.6, -2.35)
# the portal: the space under the crossing, between the blades (a lancet), a little behind the blades
lance = []
for i in range(21):
    t = i / 20
    lance.append((-11.0 + t * 11.0 + math.sin(t * math.pi) * -1.0, 1.8 + t * 23.6))
for i in range(1, 21):
    t = i / 20
    lance.append((t * 11.0 - math.sin((1 - t) * math.pi) * -1.0, 25.4 - t * 23.6))
slab2d("Glow_Face", "Glow", br, lance, -0.15, 0.15)

# =====================================================================================================================
# GateReturn
rt = collection("GateReturn")
RW, RZ0, RSP = 7.0, 1.6, 14.0
for k in range(9):
    a = k / 9 * math.tau
    d = 6 + (k % 3) * 2.2
    s = 4.5 + (k % 2) * 2
    o = rock(f"White_Cloud{k}", "White", rt, (s * 1.6, s * 1.3, s * 0.8), loc=(math.cos(a) * d, math.sin(a) * d * 0.6, 0.6), seed=90 + k, detail=2, rough=0.15, flat_bottom=True)
solid(lathe("Marble_Base", "Marble", rt, [(0, 0), (11, 0), (11, 1.0), (10, RZ0), (0, RZ0)], segments=48))
torus("Gold_BaseTrim", "Gold", rt, 10.2, 0.22, seg=48, mseg=6, loc=(0, 0, RZ0 - 0.1))
# the arch: two marble piers and a pointed head
outline = arch_outline(RW, RZ0, RSP, n=24, pointed=0.35)
wall = slab2d("Marble_Arch", "Marble", rt, [(-11, RZ0), (11, RZ0), (11, 21), (0, 31), (-11, 21)], -1.6, 1.6)
solid(cut(wall, slab2d("Cutter", "Marble", rt, outline, -3, 3)))
outer = [(x * 1.0, z) for x, z in arch_outline(11, 26, 26, n=2)]  # (flat top kept; the crest sits on it)
arch_moulding(rt, "Gold_ArchTrim", "Gold", RW + 0.4, RZ0, RSP, -1.8, circle(0.4, 8))
lathe("Gold_Star", "Gold", rt, [(0, -0.6), (2.2, 0), (0, 0.6)], segments=8, smooth=False, loc=(0, -1.9, 23.0)).rotation_euler = (math.radians(90), 0, math.radians(22.5))
lathe("GoldPale_StarCore", "GoldPale", rt, [(0, -0.8), (0.9, 0), (0, 0.8)], segments=8, smooth=False, loc=(0, -2.1, 23.0)).rotation_euler = (math.radians(90), 0, 0)
for sx in (-1, 1):
    sweep("Gold_Coping", "Gold", rt, [Vector((sx * 11.8, 0, 20.4)), Vector((0, 0, 31.8))], [(-0.45, -1.9), (0.45, -1.9), (0.45, 1.9), (-0.45, 1.9)], smooth=False, hint=(0, 1, 0))
lathe("Gold_Apex", "Gold", rt, [(0, 0), (1.0, 0), (0.6, 1.4), (0, 3.2)], segments=10, loc=(0, 0, 31.6))
# wings: fans of feathers sweeping up from each pier
for sx in (-1, 1):
    base = Vector((sx * 11.2, 0.4, 17.0))
    for k in range(9):
        t = k / 8
        ang = math.radians(sx > 0 and (10 + t * 70) or (170 - t * 70))
        length = 9 + 7 * math.sin(t * math.pi) + (3 if k == 4 else 0)
        blade(f"White_Feather{k}", "White" if k % 2 == 0 else "Marble", rt, (base.x, base.z), ang, 0.5, length, 0.9, 0.05, depth=0.5, y=0.4 + k * 0.08)
        blade(f"Gold_Quill{k}", "Gold", rt, (base.x, base.z), ang, 0.5, length * 0.85, 0.12, 0.04, depth=0.62, y=0.4 + k * 0.08)
recess(rt, "Ink_Tunnel", "Ink", outline, 0.3, 3.0)
slab2d("Glow_Face", "Glow", rt, arch_outline(RW - 0.1, RZ0, RSP, n=24, pointed=0.35), 0.5, 0.7)

# =====================================================================================================================
# GateParty
pt = collection("GateParty")
PW, PZ0, PSP = 8.0, 0.0, 16.0
for sx in (-1, 1):
    x = sx * 10.6
    solid(box("GoldDeep_Plinth", "GoldDeep", pt, (4.6, 4.6, 2.6), loc=(x, 0, 1.3), bevel=0.3))
    # a twisted (solomonic) column: a lathe whose radius spirals
    seg, lv = 20, 40
    bm = bmesh.new()
    rings = []
    for k in range(lv + 1):
        z = 2.6 + 21.4 * k / lv
        ring = []
        for i in range(seg):
            a = i / seg * math.tau
            off = 0.55 * math.cos(a - k / lv * math.tau * 3 * sx)
            ring.append(bm.verts.new((x + math.cos(a) * (1.45 + off * 0.5), math.sin(a) * (1.45 + off * 0.5), z)))
        rings.append(ring)
    for k in range(lv):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj_from_bm(bm, "Gold_Twist", "Gold", pt)
    lathe("GoldDeep_Capital", "GoldDeep", pt, [(0, 0), (1.6, 0), (2.4, 1.0), (2.7, 1.8), (0, 1.8)], segments=20, loc=(x, 0, 24.0))
outline = arch_outline(PW, PZ0, PSP, n=24)
frame = slab2d("Gold_Frame", "Gold", pt, [(-9.6, 0), (9.6, 0), (9.6, 27.0), (-9.6, 27.0)], -0.8, 0.8)
solid(cut(frame, slab2d("Cutter", "Gold", pt, outline, -2, 2)))
arch_moulding(pt, "GoldDeep_Mould", "GoldDeep", PW + 0.5, PZ0, PSP, -1.0, circle(0.55, 8))
arch_moulding(pt, "GoldPale_Bead", "GoldPale", PW + 1.4, PZ0, PSP, -0.95, circle(0.25, 6))
box("GoldDeep_Entab", "GoldDeep", pt, (26.0, 4.2, 2.0), loc=(0, 0, 26.8), bevel=0.3)
box("Gold_Entab2", "Gold", pt, (27.0, 4.8, 0.8), loc=(0, 0, 28.2), bevel=0.2)
# crest: a shell-fan and a small crown
for k in range(13):
    a = math.radians(k * 15)
    blade("GoldPale_Crest" if k % 2 else "Gold_Crest", "GoldPale" if k % 2 else "Gold", pt, (0, 28.6), a, 1.0, 6.6 if k % 2 == 0 else 5.0, 0.55, 0.12, depth=0.4, y=-0.2)
crown(pt, 33.6, 0.35, y=0.0)
# swags: gold garlands hanging between the columns' capitals and the crest
for sx in (-1, 1):
    pts = [Vector((sx * (10.6 - t * 7.6), -1.6, 25.4 - math.sin(t * math.pi) * 2.6)) for t in [i / 12 for i in range(13)]]
    sweep("Gold_Swag", "Gold", pt, pts, lambda t: circle(0.35 + 0.25 * math.sin(t * math.pi), 8))
recess(pt, "Ink_Tunnel", "Ink", outline, 0.4, 4.0)
slab2d("Glow_Face", "Glow", pt, arch_outline(PW - 0.1, PZ0, PSP, n=24), 0.6, 0.8)

print({c.name: len(c.objects) for c in bpy.data.collections if c.name.startswith(("Gate", "Golden"))})
