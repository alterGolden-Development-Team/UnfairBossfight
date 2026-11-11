# The Golden Encounter boss's gear, for the boss place. Roblox local (x, y, z) = Blender (-x, z, y): Blender +Z is up, -Y is the front.
#   BossSword     the boss's sword, in its Tool Handle's frame: grip centred on the origin, blade up (+Z), width along X, flat along Y.
#   BossCrown     on the Head (origin = head centre; head is ~1.18 across). BossHorns: the same frame.
#   BossPauldronL / BossPauldronR   on LeftUpperArm / RightUpperArm (origin = arm centre; arm ~1.01 x 1.23). Left arm is Roblox -X
#                 (Blender +X) so the left pauldron flares toward Blender +X.
#   BossCape      on UpperTorso (origin = its centre; it is 1.99 x 1.68 x 1.02), hanging down its back (Blender +Y).
#   BossBelt      on LowerTorso (2.0 x 0.41 x 1.02).
#   DeathScythe   the P4 Death Scythe, in ScytheModel's frame: the blade's maths ported from ScytheGeometry; split into groups along
#                 its length so ScytheModel's grow-in animation still sweeps along it.
#   RainSword     one of the golden swords that rain from the sky (P1.5 Raining): point down (-Z), pommel up, ~24 tall.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"ScytheBlade": ((0.65, 0.3, 0.01), 1.0, 0.3), "ScytheDark": ((0.07, 0.03, 0.0), 1.0, 0.5), "ScytheHot": ((1.0, 0.55, 0.02), 0.0, 0.5),
             "ScytheEdge": ((1.0, 0.9, 0.5), 0.0, 0.5), "Velvet": ((0.25, 0.02, 0.04), 0.0, 0.9), "Gem": ((0.9, 0.05, 0.1), 0.0, 0.1)}.items():
    ROLES[k] = v
V = Vector


def grp(o, g):
    o["group"] = g
    return o


# =====================================================================================================================
c = collection("BossSword")
# grip: leather wrap with gold bands, a faceted ruby pommel in a gold claw
sweep("Velvet_Grip", "Velvet", c, [V((0, 0, -0.5)), V((0, 0, 0.5))], lambda t: circle(0.12 + 0.012 * math.sin(t * math.pi * 14), 8))
for z in (-0.5, 0.0, 0.5):
    torus("Gold_GripBand", "Gold", c, 0.13, 0.03, seg=12, mseg=4, loc=(0, 0, z))
lathe("Gold_PommelCup", "Gold", c, [(0, -0.56), (0.18, -0.56), (0.22, -0.66), (0.14, -0.78), (0, -0.8)], segments=12)
lathe("Gem_Pommel", "Gem", c, [(0, -0.72), (0.14, -0.82), (0.16, -0.92), (0.08, -1.02), (0, -1.06)], segments=6, smooth=False)
# guard: swept wings curling up into sun-ray finials, a gem at the crossing
for s in (-1, 1):
    pts = [V((s * (0.12 + t * 0.85), 0, 0.6 + 0.05 * t + 0.28 * t ** 3)) for t in [i / 8 for i in range(9)]]
    sweep("Gold_GuardWing", "Gold", c, pts, lambda t: [(-0.09 * (1 - t * 0.4), -0.1), (0.09 * (1 - t * 0.4), -0.1), (0.09 * (1 - t * 0.4), 0.1), (-0.09 * (1 - t * 0.4), 0.1)], smooth=False, hint=(0, 1, 0))
    lathe("GoldPale_WingTip", "GoldPale", c, [(0, -0.08), (0.08, 0), (0, 0.16)], segments=6, loc=pts[-1] + V((0, 0, 0.06)), smooth=False)
box("Gold_GuardBlock", "Gold", c, (0.34, 0.24, 0.22), loc=(0, 0, 0.62), bevel=0.04)
lathe("Gem_GuardGem", "Gem", c, [(0, -0.07), (0.11, 0), (0, 0.07)], segments=6, loc=(0, -0.13, 0.62), smooth=False).rotation_euler = (math.radians(90), 0, 0)
# blade: a long tapering golden blade with a ridge, a dark fuller and bright edges
BL0, BL1 = 0.72, 3.55


def bsec(t):
    w = 0.21 * (1 - max(0, (t - 0.82) / 0.18) ** 1.2) + 0.005
    return [(-w, 0), (0, -0.045), (w, 0), (0, 0.045)]


sweep("GoldPale_Blade", "GoldPale", c, [V((0, 0, BL0 + (BL1 - BL0) * i / 12)) for i in range(13)], bsec, smooth=False, hint=(0, 1, 0))
for s in (-1, 1):
    sweep("Neon_Edge", "Neon", c, [V((s * 0.2 * (1 - max(0, (t - 0.82) / 0.18)), 0, BL0 + (BL1 - BL0) * t)) for t in [i / 10 for i in range(11)]], circle(0.012, 4))
for s in (-1, 1):
    sweep("GoldDeep_Fuller", "GoldDeep", c, [V((0, s * 0.03, BL0 + 0.15)), V((0, s * 0.03, BL1 - 0.8))], [(-0.035, -0.01), (0.035, -0.01), (0.035, 0.01), (-0.035, 0.01)], smooth=False)

# =====================================================================================================================
c = collection("BossCrown")
CR = 0.66
lathe("Gold_CrownBand", "Gold", c, [(CR, 0.40), (CR + 0.04, 0.42), (CR + 0.04, 0.70), (CR, 0.72), (CR - 0.05, 0.72), (CR - 0.05, 0.40)], segments=40)
torus("GoldDeep_CrownBead", "GoldDeep", c, CR + 0.04, 0.025, seg=40, mseg=4, loc=(0, 0, 0.44))
for k in range(8):
    a = k / 8 * math.tau + math.pi / 2
    h = 0.62 if k % 2 == 0 else 0.4
    o = lathe(f"Gold_Spire{k}", "Gold", c, [(0.09, 0), (0.07, h * 0.5), (0.04, h * 0.85), (0, h)], segments=6, smooth=False)
    o.location = (math.cos(a) * CR, math.sin(a) * CR, 0.70)
    o.rotation_euler = Euler((-math.sin(a) * 0.12, math.cos(a) * 0.12, 0))
    if k % 2 == 0:
        lathe(f"Gem_Tip{k}", "Gem", c, [(0, -0.05), (0.05, 0), (0, 0.05)], segments=6, smooth=False, loc=(math.cos(a) * (CR + 0.08), math.sin(a) * (CR + 0.08), 0.70 + h + 0.03))
    g = lathe(f"Gem_Band{k}", "Gem" if k % 2 == 0 else "GemBlue", c, [(0, -0.06), (0.07, 0), (0, 0.06)], segments=6, smooth=False)
    g.location = (math.cos(a) * (CR + 0.05), math.sin(a) * (CR + 0.05), 0.56)
    g.rotation_euler = (math.radians(90), 0, a + math.pi / 2)

c = collection("BossHorns")
for s in (-1, 1):
    pts = []
    for i in range(16):
        t = i / 15
        ang = t * 2.6
        r = 0.55 * (1 - t * 0.35)
        pts.append(V((s * (0.42 + t * 1.0 + math.sin(ang) * r * 0.8), 0.15 + t * 0.7 - math.sin(ang) * 0.35, 0.32 + math.sin(t * math.pi * 0.8) * 1.3 - t * 0.2)))
    sweep("Ink_Horn", "Ink", c, pts, lambda t: circle(0.24 * (1 - t * 0.9) + 0.015, 10))
    for t in (0.2, 0.45):
        i = int(t * 15)
        torus("Gold_HornRing", "Gold", c, 0.25 * (1 - t * 0.9) + 0.03, 0.03, seg=12, mseg=4, loc=pts[i], rot=(0, math.radians(90), 0))

# =====================================================================================================================
for side, name in ((1, "BossPauldronL"), (-1, "BossPauldronR")):
    c = collection(name)
    # Blender +X is Roblox -X; the left arm is at Roblox -X, so it flares to Blender +X (side +1)
    for k in range(3):
        r = 0.8 - k * 0.12
        o = lathe(f"Gold_Plate{k}", "Gold" if k % 2 == 0 else "GoldDeep", c, [(0, 0.85), (r * 0.5, 0.82), (r * 0.85, 0.65), (r, 0.42), (r * 1.02, 0.30), (r * 0.9, 0.30), (r * 0.82, 0.55), (r * 0.45, 0.72), (0, 0.75)], segments=24)
        o.location = (side * (0.15 + k * 0.05), 0, -k * 0.2)
        o.scale = (1.1, 1.0, 0.9)
    for k in range(5):
        a = math.radians(-60 + k * 30)
        o = lathe(f"GoldPale_Ray{k}", "GoldPale", c, [(0.06, 0), (0.04, 0.3), (0, 0.5)], segments=5, smooth=False)
        o.location = (side * (0.2 + math.cos(a) * 0.05), math.sin(a) * 0.55, 0.9)
        o.rotation_euler = (math.sin(a) * -0.6, side * 0.5, 0)
    lathe("Gem_Shoulder", "Gem", c, [(0, -0.09), (0.11, 0), (0, 0.09)], segments=6, smooth=False, loc=(side * 0.55, -0.62, 0.55)).rotation_euler = (math.radians(90), 0, 0)

# =====================================================================================================================
c = collection("BossCape")
NU, NV = 10, 14
bm = bmesh.new()
grid = []
for i in range(NU + 1):
    u = i / NU
    row = []
    for j in range(NV + 1):
        v = j / NV
        w = 1.0 + 0.7 * v  # widens toward the hem
        x = (u - 0.5) * 2 * w
        z = 0.75 - v * 4.4
        y = 0.56 + 0.12 * math.sin(u * math.pi) + v * v * 0.55 + 0.08 * math.sin(u * 9 + v * 4) * v
        if j == NV:
            z += 0.25 * abs(math.sin(u * math.pi * 3.5))  # a ragged hem
        row.append(bm.verts.new((x, y, z)))
    grid.append(row)
for i in range(NU):
    for j in range(NV):
        bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
cape = obj_from_bm(bm, "Velvet_Cape", "Velvet", c)
cape.modifiers.new("Solid", "SOLIDIFY").thickness = 0.06
for s in (-1, 1):
    sweep("Gold_CapeTrim", "Gold", c, [V((s * (1.0 + 0.7 * v) * 1.0, 0.57 + v * v * 0.55, 0.75 - v * 4.4)) for v in [j / 14 for j in range(15)]], circle(0.04, 5))
    lathe("Gold_Clasp", "Gold", c, [(0, -0.06), (0.17, -0.04), (0.17, 0.04), (0, 0.06)], segments=12, loc=(s * 0.85, 0.5, 0.72)).rotation_euler = (math.radians(90), 0, 0)
    lathe("Gem_Clasp", "Gem", c, [(0, -0.05), (0.08, 0), (0, 0.05)], segments=6, smooth=False, loc=(s * 0.85, 0.42, 0.72)).rotation_euler = (math.radians(90), 0, 0)
sweep("Gold_ClaspChain", "Gold", c, [V((-0.85, 0.48, 0.72)), V((0, 0.62, 0.62)), V((0.85, 0.48, 0.72))], circle(0.025, 4))

c = collection("BossBelt")
lathe("Velvet_Belt", "Velvet", c, [(1.06, -0.18), (1.08, 0.0), (1.06, 0.18), (1.0, 0.18), (1.0, -0.18)], segments=32).scale = (1.0, 0.56, 1.0)
lathe("Gold_Buckle", "Gold", c, [(0, -0.05), (0.26, -0.05), (0.26, 0.05), (0, 0.07)], segments=16, loc=(0, -0.6, 0)).rotation_euler = (math.radians(90), 0, 0)
for k in range(12):
    a = k / 12 * math.tau
    blade("GoldPale_BuckleRay", "GoldPale", c, (0, 0), a, 0.26, 0.4, 0.05, 0.01, depth=0.04, y=-0.64)
for o in [o for o in c.objects if o.name.startswith("GoldPale_BuckleRay")]:
    o.data.transform(Matrix.Translation((0, 0, 0)))

# =====================================================================================================================
c = collection("DeathScythe")
ARC_A, ARC_B, BASE_V, PHI_MAX, BASE_WIDTH, SPINE, EDGE = 32, 21, 27, 1.22, 13, 0.56, 0.44
HOLE_A, HOLE_B = 0.14, 0.52


def width(t):
    return BASE_WIDTH * (1 - t) ** 0.75


def sample(t, offset):
    phi = t * PHI_MAX
    px, py = ARC_A * math.sin(phi), BASE_V - ARC_B * (1 - math.cos(phi))
    tx, ty = ARC_A * math.cos(phi), -ARC_B * math.sin(phi)
    ln = math.hypot(tx, ty)
    tx, ty = tx / ln, ty / ln
    nx, ny = -ty, tx
    return (px + nx * offset, py + ny * offset)


def spine(t):
    return sample(t, width(t) * SPINE)


def edge(t):
    return sample(t, -width(t) * EDGE)


def P(pt, y=0.0):
    # ScytheModel maps a 2D point to Roblox (-x, y, z); Roblox (-x, ., .) is Blender (+x, ., .)
    return V((pt[0], y, pt[1]))


SEGS = 10
for g in range(SEGS):
    t0, t1 = g / SEGS, (g + 1) / SEGS
    n = 5
    ts = [t0 + (t1 - t0) * i / n for i in range(n + 1)]
    # outline of this slice: along the spine, then back along the edge
    outline = [spine(t) for t in ts] + [edge(t) for t in reversed(ts)]
    th = 1.25 - 0.9 * (t0 + t1) / 2
    bm = bmesh.new()
    top = [bm.verts.new((x, th / 2, y)) for x, y in outline]
    bot = [bm.verts.new((x, -th / 2, y)) for x, y in outline]
    # sharpen toward the cutting edge: pull the edge verts' thickness in
    for i in range(n + 1, len(outline)):
        top[i].co.y = th * 0.08
        bot[i].co.y = -th * 0.08
    for i0, i1, i2 in tessellate_polygon([[V((x, y, 0)) for x, y in outline]]):
        bm.faces.new((top[i0], top[i1], top[i2]))
        bm.faces.new((bot[i2], bot[i1], bot[i0]))
    m = len(outline)
    for i in range(m):
        j = (i + 1) % m
        bm.faces.new((top[i], top[j], bot[j], bot[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = obj_from_bm(bm, f"ScytheBlade_Seg{g}", "ScytheBlade", c, smooth=False)
    grp(o, g + 1)
    # the hole through the blade (between HOLE_A and HOLE_B)
    if ts[0] < HOLE_B and ts[-1] > HOLE_A:
        def holeHalf(t):
            s = (t - HOLE_A) / (HOLE_B - HOLE_A)
            if s < 0.32:
                k = (0.32 - s) / 0.32
                shape = math.sqrt(max(0, 1 - k * k))
            else:
                shape = 1 - ((s - 0.32) / 0.68) ** 1.3
            return 0.27 * width(t) * max(shape, 0)
        hts = [HOLE_A + (HOLE_B - HOLE_A) * i / 24 for i in range(25)]
        hole = [sample(t, width(t) * 0.05 + holeHalf(t)) for t in hts] + [sample(t, width(t) * 0.05 - holeHalf(t)) for t in reversed(hts)]
        cutter = slab2d("Cut", "ScytheBlade", c, hole, -3, 3)
        cut(o, cutter)
    # the glowing cutting edge of this slice
    pts = [P(edge(min(t, 0.99)), 0) for t in ts]
    grp(sweep(f"ScytheEdge_E{g}", "ScytheEdge", c, pts, circle(0.28, 5, 1.0, 0.6)), g + 1)
    # a ridge along the spine
    pts = [P(spine(t), 0) for t in ts]
    grp(sweep(f"ScytheDark_Spine{g}", "ScytheDark", c, pts, circle(0.45 * (1 - (t0 + t1) / 2 * 0.7), 6)), g + 1)
# glowing rim round the hole
hts = [HOLE_A + (HOLE_B - HOLE_A) * i / 24 for i in range(25)]


def holeHalf2(t):
    s = (t - HOLE_A) / (HOLE_B - HOLE_A)
    if s < 0.32:
        k = (0.32 - s) / 0.32
        shape = math.sqrt(max(0, 1 - k * k))
    else:
        shape = 1 - ((s - 0.32) / 0.68) ** 1.3
    return 0.27 * width(t) * max(shape, 0)


rim = [P(sample(t, width(t) * 0.05 + holeHalf2(t))) for t in hts] + [P(sample(t, width(t) * 0.05 - holeHalf2(t))) for t in reversed(hts)]
grp(sweep("ScytheHot_Rim", "ScytheHot", c, rim + [rim[0]], circle(0.3, 5)), 3)
# barbs along the spine
for k, t in enumerate((0.56, 0.65, 0.73, 0.81, 0.89)):
    phi = t * PHI_MAX
    p = spine(t)
    tx, ty = ARC_A * math.cos(phi), -ARC_B * math.sin(phi)
    ln = math.hypot(tx, ty)
    tx, ty = tx / ln, ty / ln
    nx, ny = -ty, tx
    L = 6.2 * (1 - t) ** 0.45 + 1
    a, b = spine(t - 0.04), spine(t + 0.035)
    tip = (p[0] + nx * L * 0.75 - tx * L * 1.15, p[1] + ny * L * 0.75 - ty * L * 1.15)
    o = slab2d(f"ScytheHot_Barb{k}", "ScytheHot", c, [a, b, tip], -0.35, 0.35)
    grp(o, int(t * SEGS) + 1)
# horns at the blade's root
for k, tri in enumerate(([(0, BASE_V + 7.2), (0, BASE_V + 0.5), (-11, BASE_V + 13)], [(0, BASE_V - 2), (0, BASE_V - 5.5), (-8, BASE_V - 10)])):
    o = slab2d(f"ScytheDark_Horn{k}", "ScytheDark", c, tri, -0.5, 0.5)
    grp(o, 1)
# the shaft, ringed and veined, with grips, collar, pommel and spikes (grow group by height)
sweep("ScytheDark_Shaft", "ScytheDark", c, [V((0, 0, -8.5)), V((0, 0, 27.5))], lambda t: circle(0.65, 12))
for z in (-6, -3.4, -0.8):
    lathe("ScytheBlade_Grip", "ScytheBlade", c, [(0.95, -0.35), (1.0, 0), (0.95, 0.35), (0.62, 0.35), (0.62, -0.35)], segments=16, loc=(0, 0, z))
spiral = [V((math.cos(i * 0.5) * 0.66, math.sin(i * 0.5) * 0.66, -8 + i * 0.5)) for i in range(71)]
sweep("ScytheHot_Vein", "ScytheHot", c, spiral, circle(0.09, 4))
lathe("ScytheBlade_Collar", "ScytheBlade", c, [(0.7, 25.6), (1.9, 25.9), (2.1, 26.6), (1.4, 27.2), (1.8, 27.8), (1.9, 28.6), (1.2, 29.4), (0.7, 29.6)], segments=24)
for k in range(4):
    a = math.pi * 0.25 + k * math.pi * 0.5
    o = slab2d(f"ScytheDark_Fin{k}", "ScytheDark", c, [(1.6, 26), (1.6, 23.6), (5, 19.5)], -0.2, 0.2)
    o.rotation_euler = (0, 0, a)
lathe("ScytheHot_Pommel", "ScytheHot", c, [(0, -10.1), (0.7, -9.6), (0.95, -9.2), (0.7, -8.8), (0, -8.6)], segments=12)
lathe("ScytheBlade_SpikeLow", "ScytheBlade", c, [(0.9, -9.6), (0.5, -12.5), (0, -16.5)], segments=6, smooth=False)
lathe("ScytheBlade_SpikeTop", "ScytheBlade", c, [(1.0, 29.4), (0.6, 34), (0, 41)], segments=6, smooth=False)

# =====================================================================================================================
c = collection("RainSword")
# point down: tip at -12.2, guard at +5.6, pommel at +11.2 (matches the old pieces' layout)


def rsec(t):
    w = 1.15 * (1 - max(0, (0.25 - t) / 0.25) ** 1.4) + 0.02  # t 0 = tip
    return [(-w, 0), (0, -0.3), (w, 0), (0, 0.3)]


sweep("GoldPale_RainBlade", "GoldPale", c, [V((0, 0, -12.2 + 17.0 * i / 16)) for i in range(17)], rsec, smooth=False, hint=(0, 1, 0))
for s in (-1, 1):
    sweep("Gold_RainEdge", "Gold", c, [V((s * 1.12 * (1 - max(0, (0.25 - t) / 0.25) ** 1.4), 0, -12.2 + 17.0 * t)) for t in [i / 12 for i in range(13)]], circle(0.12, 4))
for s in (-1, 1):
    pts = [V((s * (0.6 + u * 3.6), 0, 5.4 - 0.9 * u ** 2)) for u in [i / 8 for i in range(9)]]
    sweep("Gold_RainGuard", "Gold", c, pts, lambda t: circle(0.45 * (1 - t * 0.5), 8))
    lathe("GoldPale_RainFinial", "GoldPale", c, [(0, -0.5), (0.5, 0), (0, 0.6)], segments=8, loc=pts[-1])
lathe("Gem_RainGem", "Gem", c, [(0, -0.8), (0.8, 0), (0, 0.8)], segments=8, smooth=False, loc=(0, -0.5, 5.6)).rotation_euler = (math.radians(90), 0, 0)
sweep("GoldDeep_RainGrip", "GoldDeep", c, [V((0, 0, 6.0)), V((0, 0, 10.6))], lambda t: circle(0.36 + 0.05 * math.sin(t * math.pi * 10), 10))
lathe("Gold_RainPommel", "Gold", c, [(0, 10.5), (0.7, 10.7), (0.85, 11.3), (0.5, 11.9), (0, 12.2)], segments=12)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name in ("BossSword", "BossCrown", "BossHorns", "BossPauldronL", "BossPauldronR", "BossCape", "BossBelt", "DeathScythe", "RainSword")})
