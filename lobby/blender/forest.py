# The divided wood (Jeff n' Fred). Pieces, each round the origin, front -Y:
#   ForestTree1..3   gnarled trees, ~40 tall. Roles Bark + Leaf; the builder recolours them black or white by side of the path.
#   ForestGate       a torii-like gate over the path, white pillar on the left, black on the right. 24 wide, 27 tall.
#   ForestLantern    a stone lantern (the builder lights the window box at z 4.3). Role White; recoloured per side.
#   ForestPillar     a broken fluted column for the ring round The Cut. Role White; recoloured.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())


def roughen(o, strength=1.0, size=2.0, levels=1, seed=0):
    if levels:
        sub = o.modifiers.new("Sub", "SUBSURF")
        sub.levels = levels
        sub.render_levels = levels
    tex = bpy.data.textures.get(f"ForNoise{seed}") or bpy.data.textures.new(f"ForNoise{seed}", "CLOUDS")
    tex.noise_scale = size
    d = o.modifiers.new("Disp", "DISPLACE")
    d.texture = tex
    d.strength = strength
    return o


def curve_path(start, direction, length, bend, steps, rnd, up_pull=0.0):
    pts = [Vector(start)]
    d = Vector(direction).normalized()
    seg = length / steps
    for i in range(steps):
        d = (d + Vector((rnd.uniform(-bend, bend), rnd.uniform(-bend, bend), rnd.uniform(-bend * 0.5, bend) + up_pull))).normalized()
        pts.append(pts[-1] + d * seg)
    return pts


def tree(name, seed, height=40.0, lean=0.12, branches=6, crown=True):
    col = collection(name)
    rnd = random.Random(seed)
    r0 = height * 0.045
    trunk = curve_path((0, 0, -1.0), (rnd.uniform(-lean, lean), rnd.uniform(-lean, lean), 1), height, 0.12, 12, rnd, up_pull=0.05)
    sweep("Bark_Trunk", "Bark", col, trunk, lambda t: circle(r0 * (1.25 - t * 0.85) * (1.3 if t < 0.06 else 1.0), 10))
    # root flares
    for k in range(5):
        a = k / 5 * math.tau + rnd.uniform(-0.3, 0.3)
        d = Vector((math.cos(a), math.sin(a), -0.35))
        pts = curve_path(trunk[1] + Vector((0, 0, 0.5)), d, height * 0.13, 0.15, 5, rnd)
        for p in pts:
            p.z = max(p.z, -0.6)
        sweep("Bark_Root", "Bark", col, pts, lambda t: circle(r0 * 0.55 * (1 - t * 0.85), 7))
    tips = []
    for b in range(branches):
        t = 0.42 + b / branches * 0.5 + rnd.uniform(-0.04, 0.04)
        i = int(t * (len(trunk) - 1))
        base = trunk[i]
        a = b * 2.4 + rnd.uniform(-0.3, 0.3)
        d = Vector((math.cos(a), math.sin(a), rnd.uniform(0.35, 0.9)))
        length = height * rnd.uniform(0.28, 0.42) * (1.1 - t * 0.5)
        br = curve_path(base, d, length, 0.25, 6, rnd, up_pull=0.06)
        rr = r0 * (1.2 - t * 0.85) * 0.6
        sweep("Bark_Branch", "Bark", col, br, lambda u, rr=rr: circle(rr * (1 - u * 0.8), 7))
        tips.append(br[-1])
        # a twig or two off each branch
        for k in range(2):
            j = rnd.randint(2, len(br) - 2)
            d2 = (br[j + 1] - br[j]).normalized() + Vector((rnd.uniform(-0.9, 0.9), rnd.uniform(-0.9, 0.9), 0.4))
            tw = curve_path(br[j], d2, length * 0.45, 0.3, 4, rnd, up_pull=0.05)
            sweep("Bark_Twig", "Bark", col, tw, lambda u, rr=rr: circle(rr * 0.5 * (1 - u * 0.85), 5))
            tips.append(tw[-1])
    tips.append(trunk[-1])
    if crown:
        # a stylised crown: clumps of faceted foliage at the tips, flattened a little
        for k, p in enumerate(tips):
            s = rnd.uniform(5.0, 8.5) * height / 40
            o = rock(f"Leaf_Clump{k}", "Leaf", col, (s * 1.25, s * 1.25, s * 0.85), loc=p + Vector((0, 0, s * 0.15)), seed=seed * 50 + k, detail=2, rough=0.3, flat_bottom=False)
    return col


tree("ForestTree1", 3, height=40, branches=6)
tree("ForestTree2", 17, height=40, lean=0.25, branches=5)
tree("ForestTree3", 29, height=40, branches=7, crown=False)  # bare, dead and twisted

# =====================================================================================================================
g = collection("ForestGate")
SPAN = 12.0
for sx, role in ((-1, "White"), (1, "Black")):
    x = sx * SPAN
    solid(lathe(f"{role}_GatePillar", role, g, [(0, 0), (1.6, 0), (1.45, 21), (0, 21)], segments=16, loc=(x, 0, 0)))
    solid(lathe(f"{role}_GateBase", role, g, [(0, 0), (2.4, 0), (2.4, 1.6), (1.9, 2.4), (0, 2.4)], segments=16, loc=(x, 0, 0)))
    # the lower beam (nuki) and its wedges, each brother's colour on his half
    box(f"{role}_Nuki", role, g, (SPAN + 3.2, 1.6, 1.6), loc=(sx * (SPAN + 3.2) / 2 - sx * 0.0, 0, 17.0), bevel=0.15)
# top beam (kasagi): a swept beam curving up at both ends, half white and half black
for sx, role in ((-1, "White"), (1, "Black")):
    pts = []
    for i in range(13):
        t = i / 12
        x = sx * t * (SPAN + 6.5)
        z = 22.6 + (t ** 3) * 2.2
        pts.append(Vector((x, 0, z)))
    sweep(f"{role}_Kasagi", role, g, pts, [(-1.8, -1.0), (1.8, -1.0), (2.1, 1.0), (-2.1, 1.0)], smooth=False)
    box(f"{role}_Shimaki", role, g, (SPAN + 6.0, 2.6, 1.2), loc=(sx * (SPAN + 6.0) / 2, 0, 21.0), bevel=0.12)
# the plaque between the beams: a yin-yang roundel
lathe("Stone_Plaque", "Stone", g, [(0, -0.4), (3.0, -0.4), (3.0, 0.4), (0, 0.4)], segments=32, loc=(0, -0.9, 19.3)).rotation_euler = (math.radians(90), 0, 0)
for role, rot in (("White", 0.0), ("Black", math.pi)):
    # half discs: the yin-yang drawn simply as two half rounds with dots
    bm = bmesh.new()
    pts = [(math.cos(a) * 2.6, math.sin(a) * 2.6) for a in [math.pi / 2 + i / 24 * math.pi for i in range(25)]]
    h = 1.3
    pts += [(math.cos(a) * h, -h + math.sin(a) * h) for a in [-math.pi / 2 - i / 12 * math.pi for i in range(1, 12)]]
    pts += [(math.cos(a) * h, h + math.sin(a) * h) for a in [-math.pi / 2 + i / 12 * math.pi for i in range(1, 12)]]
    c, s = math.cos(rot), math.sin(rot)
    pts = [(x * c - y * s, x * s + y * c) for x, y in pts]
    from mathutils.geometry import tessellate_polygon
    front = [bm.verts.new((x, -1.35, 19.3 + y)) for x, y in pts]
    back = [bm.verts.new((x, -1.15, 19.3 + y)) for x, y in pts]
    for i0, i1, i2 in tessellate_polygon([[Vector((x, y, 0)) for x, y in pts]]):
        bm.faces.new((front[i0], front[i1], front[i2]))
        bm.faces.new((back[i2], back[i1], back[i0]))
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        bm.faces.new((front[i], front[j], back[j], back[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj_from_bm(bm, f"{role}_Yin", role, g, smooth=False)

# =====================================================================================================================
ln = collection("ForestLantern")
solid(lathe("White_LanBase", "White", ln, [(0, 0), (1.5, 0), (1.5, 0.5), (1.1, 0.8), (0, 0.8)], segments=6, smooth=False))
lathe("White_LanPost", "White", ln, [(0, 0.8), (0.55, 0.8), (0.45, 3.0), (0, 3.0)], segments=8)
lathe("White_LanSaddle", "White", ln, [(0, 3.0), (0.6, 3.0), (1.5, 3.4), (1.5, 3.7), (0, 3.7)], segments=6, smooth=False)
# the light box: four posts round a hollow (the builder puts a glowing cube inside)
for k in range(4):
    a = k / 4 * math.tau + math.pi / 4
    box("White_LanCorner", "White", ln, (0.4, 0.4, 1.4), loc=(math.cos(a) * 0.95, math.sin(a) * 0.95, 4.4))
# the roof: a wide six-sided cap with flicked-up corners and a bud finial
lathe("White_LanRoof", "White", ln, [(0, 5.0), (2.3, 5.0), (2.5, 5.25), (1.6, 5.8), (0.5, 6.4), (0, 6.5)], segments=6, smooth=False)
for k in range(6):
    a = k / 6 * math.tau
    lathe("White_LanCurl", "White", ln, [(0.18, 0), (0.12, 0.5), (0, 0.6)], segments=5, loc=(math.cos(a) * 2.45, math.sin(a) * 2.45, 5.15))
lathe("White_LanBud", "White", ln, [(0, 6.4), (0.35, 6.5), (0.45, 6.9), (0.2, 7.3), (0, 7.5)], segments=8)

# =====================================================================================================================
pl = collection("ForestPillar")
rnd = random.Random(5)
solid(lathe("White_PilBase", "White", pl, [(0, 0), (3.2, 0), (3.2, 1.0), (2.6, 1.4), (0, 1.4)], segments=24))
# fluted shaft with a broken, jagged top
seg = 32
bm = bmesh.new()
rings = []
levels = 10
for k in range(levels + 1):
    z = 1.4 + 16.0 * k / levels
    ring = []
    for i in range(seg):
        a = i / seg * math.tau
        r = 2.2 * (1 - 0.1 * max(0.0, math.cos(a * 8)) ** 2)
        zz = z
        if k == levels:
            zz = z - 3.0 * (0.5 + 0.5 * math.sin(a * 3 + 1)) - rnd.uniform(0, 1.2)
        ring.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, zz)))
    rings.append(ring)
for k in range(levels):
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
bm.faces.new(list(reversed(rings[0])))
top = bm.verts.new((0, 0, 1.4 + 16.0 - 2.0))
for i in range(seg):
    bm.faces.new((rings[-1][i], rings[-1][(i + 1) % seg], top))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
solid(obj_from_bm(bm, "White_PilShaft", "White", pl))
# a fallen chunk at its foot
o = lathe("White_PilChunk", "White", pl, [(0, 0), (2.2, 0), (2.2, 3.4), (0, 3.4)], segments=16, loc=(4.2, -1.5, 2.2))
o.rotation_euler = (math.radians(84), 0, math.radians(30))

print({c.name: len(c.objects) for c in bpy.data.collections if c.name.startswith("Forest")})
