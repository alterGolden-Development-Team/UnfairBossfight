# The boss arena's gate-court props: a statue of alterGolden, the Nothing (replaces the broken stone R6 statue) and the rocks around it.
# Roblox local (x, y, z) = Blender (-x, z, y): Blender +Z up, -Y is the front (the statue faces -Y = Roblox -Z).
#   AlterStatue       origin = the middle of the pedestal's underside at ground level; 17 x 15 base, ~34 tall with horns.
#                     Black-marble clothes, gold skin and trim, crimson belt and cape, gold crown with gems, black horns, his shades,
#                     both hands on a planted greatsword. Solid (precise collision) pieces are the pedestal and the legs.
#   CourtBoulderA/B   big solid boulders (A: 9 wide with two satellites, B: tall)
#   CourtRockCluster  five solid rocks in a heap
#   CourtColumnStump  a broken fluted column on a block, with a fallen drum (solid)
#   CourtSlab         a tilted fallen flagstone (not solid), CourtRubble six small stones (not solid)
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"Velvet": ((0.25, 0.02, 0.04), 0.0, 0.9), "Gem": ((0.9, 0.05, 0.1), 0.0, 0.1), "GemBlue": ((0.02, 0.15, 0.9), 0.0, 0.1),
             "Steel": ((0.62, 0.64, 0.68), 1.0, 0.25), "Cloth": ((0.025, 0.022, 0.03), 0.0, 0.95)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau
S = 4.6          # one boss stud = 4.6 statue studs
Z0 = 3.2         # the statue's soles stand on the pedestal top


def lerp(a, b, t):
    return a + (b - a) * t


def P(x, y, z):
    return V((x * S, y * S, z * S + Z0))


def rrect(w, d, r, n=4):
    pts = []
    for cx, cy, a0 in ((w / 2 - r, d / 2 - r, 0), (-(w / 2 - r), d / 2 - r, 90), (-(w / 2 - r), -(d / 2 - r), 180), (w / 2 - r, -(d / 2 - r), 270)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def tube(c, name, role, a, b, r0, r1, seg=14, sy=1.0):
    """A tapered round limb from statue-space boss-unit point a to b (radii in boss units)."""
    n = 8
    path = [P(*[lerp(a[i], b[i], k / n) for i in range(3)]) for k in range(n + 1)]
    return sweep(name, role, c, path, lambda t: circle(lerp(r0, r1, t) * S, seg, 1.0, sy), smooth=True)


def sphere(c, name, role, r, loc, scale=(1, 1, 1), seg=14):
    prof = [(0, -r)] + [(math.sin(math.pi * k / 8) * r, -math.cos(math.pi * k / 8) * r) for k in range(1, 8)] + [(0, r)]
    o = lathe(name, role, c, prof, segments=seg, loc=loc)
    o.scale = scale
    return o


def bx(c, name, role, size, loc, rot=(0, 0, 0), bevel=0.0):
    return box(name, role, c, tuple(s * S for s in size), tuple(l * S for l in loc[:2]) + (loc[2] * S + Z0,), rot, bevel * S)


# =====================================================================================================================
c = collection("AlterStatue")
# --- pedestal (studs) -------------------------------------------------------------------------------------------------
solid(box("Stone_PedBase", "Stone", c, (17, 15, 1.2), loc=(0, 0, 0.6), bevel=0.25))
solid(box("StoneWarm_PedMid", "StoneWarm", c, (14, 12, 1.0), loc=(0, 0, 1.7), bevel=0.2))
solid(box("Stone_PedTop", "Stone", c, (11, 9, 1.0), loc=(0, 0, 2.7), bevel=0.2))
box("Gold_PedBand", "Gold", c, (11.3, 9.3, 0.2), loc=(0, 0, 2.2))
box("Gold_PedBandLow", "Gold", c, (14.2, 12.2, 0.14), loc=(0, 0, 1.16))
slab2d("GoldPale_Plaque", "GoldPale", c, [(-3.2, 0.5), (3.2, 0.5), (3.2, 2.9), (-3.2, 2.9)], -4.58, -4.46)  # front plate on the mid tier
slab2d("Gold_PlaqueCrest", "Gold", c, [(0, 0.9), (0.9, 1.7), (0, 2.5), (-0.9, 1.7)], -4.62, -4.58)
for sx in (-1, 1):
    slab2d("Gold_PlaqueHorn", "Gold", c, [(sx * 1.2, 1.4), (sx * 2.4, 2.2), (sx * 2.7, 2.5), (sx * 2.0, 1.2)], -4.62, -4.58)
for k in range(4):  # gold studs on the plaque corners
    sphere(c, "Gold_PlaqueStud", "Gold", 0.18, ((-3.0 if k % 2 == 0 else 3.0), -4.62, (0.7 if k < 2 else 2.7)))

# --- legs and boots ---------------------------------------------------------------------------------------------------
for sx in (-1, 1):
    x = sx * 0.55
    solid(sweep("Cloth_Boot", "Cloth", c, [P(x, -0.12, 0.2 + i * 0.1) for i in range(9)], lambda t: rrect(1.08 * S, 1.35 * S, 0.3 * S), smooth=True, hint=(0, 1, 0)))
    bx(c, "Gold_ToeCap", "Gold", (0.86, 0.34, 0.32), (x, -0.62, 0.17), bevel=0.1)
    bx(c, "GoldDeep_Sole", "GoldDeep", (1.1, 1.45, 0.08), (x, -0.12, 0.04), bevel=0.03)
    solid(tube(c, "Cloth_Shin", "Cloth", (x, 0, 0.9), (x, 0, 1.65), 0.52, 0.48))
    solid(tube(c, "Cloth_Thigh", "Cloth", (x, 0, 1.6), (x, 0, 2.95), 0.5, 0.58))
    o = torus("Gold_BootRim", "Gold", c, 0.53 * S, 0.05 * S, seg=24, mseg=6, loc=(x * S, 0, 0.95 * S + Z0))
    o = torus("Gold_KneeBand", "Gold", c, 0.52 * S, 0.045 * S, seg=24, mseg=6, loc=(x * S, 0, 1.62 * S + Z0))
    bx(c, "Gold_LegStripe", "Gold", (0.05, 0.12, 1.9), (x + sx * 0.52, 0, 1.9), bevel=0.01)

# --- skirt flaps under the belt ---------------------------------------------------------------------------------------
for side, y in (("Front", -0.62), ("Back", 0.62)):
    outline = [(-0.72, 3.0), (0.72, 3.0), (0.95, 2.0), (0.4, 1.86), (0.0, 1.78), (-0.4, 1.86), (-0.95, 2.0)]
    pts = [(px * S, pz * S + Z0) for px, pz in outline]
    slab2d("Cloth_Flap" + side, "Cloth", c, pts, y * S - 0.18, y * S + 0.18)
    lin = [(-0.8, 2.25), (0.8, 2.25), (0.96, 1.98), (0.0, 1.74), (-0.96, 1.98)]
    slab2d("Velvet_Lining" + side, "Velvet", c, [(px * S, pz * S + Z0) for px, pz in lin], y * S + (0.14 if y < 0 else -0.14) - 0.1, y * S + (0.14 if y < 0 else -0.14) + 0.1)
    bx(c, "Gold_FlapEdge" + side, "Gold", (1.9, 0.07, 0.05), (0, y, 1.9), bevel=0.01)
for sx in (-1, 1):
    side = [(-0.4, 3.0), (0.4, 3.0), (0.5, 2.1), (0.0, 1.98), (-0.5, 2.1)]
    o = slab2d("Cloth_Tasset", "Cloth", c, [(px * S, pz * S + Z0) for px, pz in side], -0.18, 0.18)
    o.rotation_euler = (0, 0, math.pi / 2)
    o.location = (sx * 1.05 * S, 0, 0)

# --- torso ------------------------------------------------------------------------------------------------------------
sweep("Cloth_Tunic", "Cloth", c, [P(0, 0, lerp(3.0, 5.0, i / 12)) for i in range(13)],
      lambda t: rrect(lerp(1.99, 2.24, math.sin(min(t, 0.75) / 0.75 * math.pi / 2)) * S, 1.18 * S, 0.3 * S), smooth=True, hint=(0, 1, 0))
bx(c, "GoldPale_Placket", "GoldPale", (0.95, 0.07, 1.65), (0, -0.605, 4.0), bevel=0.02)
bx(c, "Gold_Seam", "Gold", (0.05, 0.06, 1.75), (0, -0.64, 4.0))
for sx in (-1, 1):
    for k in range(6):
        sphere(c, "Gold_Button", "Gold", 0.06 * S, (sx * 0.27 * S, -0.66 * S, (4.65 - k * 0.27) * S + Z0), seg=8)
    bx(c, "Gold_PlacketEdge", "Gold", (0.04, 0.06, 1.7), (sx * 0.48, -0.64, 4.0))
bx(c, "Gold_TunicHem", "Gold", (2.1, 1.22, 0.07), (0, 0, 3.02), bevel=0.02)
slab2d("Gold_Crest", "Gold", c, [((0) * S, (4.3 + 0.35) * S + Z0), (0.22 * S, 4.3 * S + Z0), (0, (4.3 - 0.35) * S + Z0), (-0.22 * S, 4.3 * S + Z0)], -0.7 * S, -0.64 * S)
sphere(c, "Gem_Crest", "Gem", 0.075 * S, (0, -0.72 * S, 4.3 * S + Z0), seg=8)
# belt (crimson, with a golden sun buckle)
lathe("Velvet_Belt", "Velvet", c, [(1.1 * S, 3.0 * S + Z0), (1.14 * S, 3.0 * S + Z0), (1.14 * S, 3.3 * S + Z0), (1.1 * S, 3.3 * S + Z0)], segments=28).scale = (1.0, 0.56, 1.0)
lathe("Gold_BeltSun", "Gold", c, [(0, -0.12 * S), (0.3 * S, -0.12 * S), (0.34 * S, 0), (0.3 * S, 0.12 * S), (0, 0.12 * S)], segments=16, loc=(0, -0.66 * S, 3.15 * S + Z0)).rotation_euler = (math.pi / 2, 0, 0)
# collar
lathe("Cloth_Collar", "Cloth", c, [(0.42 * S, 4.95 * S + Z0), (0.52 * S, 5.1 * S + Z0), (0.58 * S, 5.28 * S + Z0), (0.52 * S, 5.32 * S + Z0), (0.44 * S, 5.15 * S + Z0)], segments=24)
torus("Gold_CollarRim", "Gold", c, 0.55 * S, 0.04 * S, seg=24, mseg=6, loc=(0, 0, 5.31 * S + Z0))

# --- cape (behind): a folded sheet that flares as it falls ------------------------------------------------------------
def cape_section(t):
    w = lerp(3.1, 4.5, t ** 1.1) * S
    left, right = [], []
    k = 12
    for i in range(k + 1):
        x = -w / 2 + w * i / k
        y = 0.18 * S * math.sin(x / S * 3.3 + t * 3.0) * (0.3 + 0.7 * t)
        left.append((x, y))
    th = 0.14 * S
    return left + [(x, y + th) for x, y in reversed(left)]


cape_path = [V((0, (0.72 + 0.55 * (i / 14) ** 1.4) * S, lerp(4.95, 0.45, i / 14) * S + Z0)) for i in range(15)]
sweep("Velvet_Cape", "Velvet", c, cape_path, cape_section, smooth=True, hint=(0, 1, 0))
bx(c, "Gold_CapeTop", "Gold", (3.2, 0.12, 0.1), (0, 0.78, 4.95), bevel=0.02)

# --- arms: pauldrons, sleeves, gauntlets on the pommel ------------------------------------------------------------------
for sx in (-1, 1):
    sh = (sx * 1.5, 0.0, 4.6)
    el = (sx * 1.2, -0.55, 3.6)
    wr = (sx * 0.3, -1.0, 3.9)
    tube(c, "Cloth_UpperArm", "Cloth", sh, el, 0.56, 0.5)
    tube(c, "Cloth_Forearm", "Cloth", el, wr, 0.5, 0.42)
    torus("Gold_ElbowBand", "Gold", c, 0.5 * S, 0.05 * S, seg=18, mseg=6, loc=P(*el), rot=(0.5, 0, 0))
    # pauldron: a gold dome with a deep underside, a crimson gem and a crest of spikes
    sphere(c, "Gold_Pauldron", "Gold", 1.0 * S, (sx * 1.55 * S, 0.0, 4.9 * S + Z0), (1.0, 1.0, 0.7))
    lathe("GoldDeep_PauldronRim", "GoldDeep", c, [(0.98 * S, 4.55 * S + Z0), (1.1 * S, 4.6 * S + Z0), (1.12 * S, 4.72 * S + Z0), (0.98 * S, 4.7 * S + Z0)], segments=24, loc=(sx * 1.55 * S, 0, 0))
    sphere(c, "Gem_Pauldron", "Gem", 0.17 * S, (sx * 1.55 * S, -0.3 * S, 5.5 * S + Z0), seg=8)
    for k in range(3):
        a = (k - 1) * 0.5
        lathe("GoldPale_Spike", "GoldPale", c, [(0.12 * S, 0), (0.05 * S, 0.5 * S), (0, 0.95 * S)], segments=6, loc=(sx * (1.55 + (k - 1) * 0.35) * S, 0.25 * S, 5.35 * S + Z0)).rotation_euler = (0, a * 0.6, 0)
    # wrist cuff + gold gauntlet hand
    torus("Gold_Cuff", "Gold", c, 0.45 * S, 0.05 * S, seg=18, mseg=6, loc=P(*wr), rot=(0, 0, 0))
    sphere(c, "Gold_Hand", "Gold", 0.42 * S, tuple(P(sx * 0.2, -1.0, 4.0)), (1.0, 1.0, 0.9), seg=12)

# --- head -------------------------------------------------------------------------------------------------------------
tube(c, "Gold_Neck", "Gold", (0, 0, 4.9), (0, 0, 5.25), 0.32, 0.3)
sweep("Gold_Head", "Gold", c, [P(0, 0, lerp(5.15, 6.35, i / 8)) for i in range(9)],
      lambda t: rrect((1.2 - 0.12 * max(0, t - 0.75) / 0.25) * S, (1.12 - 0.08 * max(0, t - 0.8) / 0.2) * S, 0.28 * S), smooth=True, hint=(0, 1, 0))
bx(c, "Cloth_Shades", "Cloth", (1.22, 0.14, 0.3), (0, -0.54, 5.9), bevel=0.06)   # his sunglasses
for sx in (-1, 1):
    bx(c, "Cloth_ShadeArm", "Cloth", (0.06, 0.6, 0.08), (sx * 0.62, -0.28, 5.92))
bx(c, "Cloth_Mouth", "Cloth", (0.42, 0.05, 0.07), (0, -0.57, 5.45), bevel=0.01)
bx(c, "GoldDeep_Brow", "GoldDeep", (0.9, 0.06, 0.06), (0, -0.56, 6.12))
# crown: a band, five spikes, a red heart and blue flanks
lathe("GoldPale_CrownBand", "GoldPale", c, [(0.64 * S, 6.28 * S + Z0), (0.68 * S, 6.3 * S + Z0), (0.68 * S, 6.58 * S + Z0), (0.64 * S, 6.6 * S + Z0)], segments=24)
torus("GoldDeep_CrownBase", "GoldDeep", c, 0.67 * S, 0.035 * S, seg=24, mseg=6, loc=(0, 0, 6.3 * S + Z0))
for k in range(5):
    a = math.radians(-90 + (k - 2) * 38)
    h = (0.95 if k == 2 else 0.7) * S
    o = lathe("GoldPale_CrownSpike", "GoldPale", c, [(0.17 * S, 0), (0.08 * S, h * 0.6), (0, h)], segments=6, loc=(math.cos(a) * 0.66 * S, math.sin(a) * 0.66 * S, 6.58 * S + Z0))
    sphere(c, "Gem_CrownTip", "Gem", 0.06 * S, (math.cos(a) * 0.66 * S, math.sin(a) * 0.66 * S, 6.58 * S + Z0 + h), seg=6)
sphere(c, "Gem_CrownHeart", "Gem", 0.13 * S, (0, -0.7 * S, 6.44 * S + Z0), seg=8)
for sx in (-1, 1):
    sphere(c, "GemBlue_Crown", "GemBlue", 0.09 * S, (sx * 0.42 * S, -0.56 * S, 6.44 * S + Z0), seg=8)
# horns: black, sweeping out and up, with gold rings at the root
for sx in (-1, 1):
    pts = []
    for i in range(13):
        a = i / 12 * math.radians(125)
        pts.append(V((sx * (0.55 + 1.55 * math.sin(a)) * S, 0.05 * S, (6.35 + 1.15 * (1 - math.cos(a)) + 0.25 * i / 12) * S + Z0)))
    sweep("Cloth_Horn", "Cloth", c, pts, lambda t: circle(lerp(0.17, 0.02, t ** 0.8) * S, 8), smooth=True)
    for t in (0.0, 0.1):
        k = int(t * 12)
        torus("Gold_HornRing", "Gold", c, 0.19 * S, 0.035 * S, seg=14, mseg=5, loc=tuple(pts[k] + V((0, 0, 0))), rot=(0, math.radians(90 - 20) * sx * -1, 0))

# --- the greatsword planted between his hands -------------------------------------------------------------------------
def blade_section(t):
    w = lerp(0.36, 0.07, t ** 1.3) * S
    th = 0.05 * S
    return [(-w, 0), (-w * 0.5, -th), (w * 0.5, -th), (w, 0), (w * 0.5, th), (-w * 0.5, th)]


sweep("Steel_Blade", "Steel", c, [P(0, -1.0, lerp(3.45, 0.04, i / 16)) for i in range(17)], blade_section, smooth=False, hint=(0, 1, 0))
bx(c, "Gold_Guard", "Gold", (2.3, 0.24, 0.24), (0, -1.0, 3.5), bevel=0.05)
for sx in (-1, 1):
    pts = [P(sx * (1.1 + 0.55 * u), -1.0, 3.5 + 0.35 * u * u) for u in (i / 6 for i in range(7))]
    sweep("Gold_Quillon", "Gold", c, pts, lambda t: circle(lerp(0.13, 0.04, t) * S, 6))
sphere(c, "Gem_Guard", "Gem", 0.13 * S, (0, -1.0 * S - 0.15 * S, 3.5 * S + Z0), seg=8)
sweep("Velvet_Grip", "Velvet", c, [P(0, -1.0, lerp(3.62, 4.28, i / 6)) for i in range(7)], lambda t: circle(0.1 * S, 8))
sphere(c, "Gold_Pommel", "Gold", 0.22 * S, tuple(P(0, -1.0, 4.42)), seg=12)
for z in (3.7, 4.2):
    torus("Gold_GripBand", "Gold", c, 0.115 * S, 0.022 * S, seg=12, mseg=4, loc=tuple(P(0, -1.0, z)))


# =====================================================================================================================
def finish(o):
    return solid(o)


c = collection("CourtBoulderA")
finish(rock("Rock_Main", "Rock", c, (9.0, 7.5, 6.0), loc=(0, 0, 3.0), seed=3, detail=3, rough=0.26))
finish(rock("Rock_SatA", "Rock", c, (4.6, 4.0, 3.4), loc=(5.4, 2.0, 1.6), seed=11, detail=2, rough=0.28))
finish(rock("Rock_SatB", "Rock", c, (3.4, 3.2, 2.6), loc=(-4.4, -3.0, 1.2), seed=17, detail=2, rough=0.3))
rock("Grass_Moss", "Grass", c, (5.0, 4.0, 0.8), loc=(0.4, 0.3, 5.6), seed=5, detail=1, rough=0.2, flat_bottom=False)

c = collection("CourtBoulderB")
finish(rock("Rock_Tall", "Rock", c, (6.2, 5.6, 10.0), loc=(0, 0, 5.0), seed=7, detail=3, rough=0.3))
finish(rock("Rock_Foot", "Rock", c, (4.0, 3.6, 2.4), loc=(3.2, -2.4, 1.1), seed=19, detail=2, rough=0.3))
rock("Grass_Moss", "Grass", c, (3.6, 3.0, 0.7), loc=(0, 0.2, 9.5), seed=9, detail=1, rough=0.2, flat_bottom=False)

c = collection("CourtRockCluster")
for k, (sz, loc, seed) in enumerate((((5.5, 4.6, 3.6), (0, 0, 1.7), 21), ((3.6, 3.2, 2.6), (3.6, -1.8, 1.2), 23), ((3.0, 2.6, 2.2), (-3.2, 2.2, 1.0), 25),
                                     ((2.2, 2.0, 1.6), (1.4, 3.6, 0.8), 27), ((2.0, 1.8, 1.4), (-1.6, -3.0, 0.7), 29))):
    finish(rock(f"Rock_{k}", "Rock", c, sz, loc=loc, seed=seed, detail=2, rough=0.3))

c = collection("CourtColumnStump")
# base block, a fluted drum column broken off at a slant, a gold band, and a fallen drum beside it
finish(box("StoneWarm_Block", "StoneWarm", c, (6.4, 6.4, 1.3), loc=(0, 0, 0.65), bevel=0.22))
finish(box("Stone_BlockTop", "Stone", c, (5.4, 5.4, 0.4), loc=(0, 0, 1.5), bevel=0.12))


def fluted(r, n=18, depth=0.14):
    pts = []
    for i in range(n * 2):
        a = i / (n * 2) * TAU
        rr = r if i % 2 == 0 else r - depth
        pts.append((math.cos(a) * rr, math.sin(a) * rr))
    return pts


shaft = sweep("StoneWarm_Shaft", "StoneWarm", c, [V((0, 0, 1.7 + i * 0.7)) for i in range(11)], lambda t: fluted(1.9 - 0.2 * t), smooth=False)
cutter = box("Cutter", "Stone", c, (9, 9, 3), loc=(0, 0, 9.6), rot=(math.radians(24), math.radians(10), 0))
cut(shaft, cutter)
finish(shaft)
torus("Gold_ColumnBand", "Gold", c, 1.85, 0.12, seg=24, mseg=6, loc=(0, 0, 4.4))
drum = sweep("StoneWarm_Drum", "StoneWarm", c, [V((6.5 + i * 0.7, -2.5, 1.2)) for i in range(7)], lambda t: fluted(1.75), smooth=False, hint=(0, 0, 1))
finish(drum)

c = collection("CourtSlab")
box("StoneWarm_Slab", "StoneWarm", c, (7.2, 5.2, 1.1), loc=(0, 0, 0.55), rot=(0.06, 0.08, 0.2), bevel=0.3)
box("Stone_SlabChip", "Stone", c, (2.4, 2.0, 0.7), loc=(4.4, 1.8, 0.35), rot=(0.1, -0.1, 0.9), bevel=0.2)

c = collection("CourtRubble")
for k, (sz, loc, seed) in enumerate((((1.8, 1.5, 1.1), (0, 0, 0.5), 31), ((1.2, 1.1, 0.9), (2.1, 0.8, 0.4), 33), ((1.0, 0.9, 0.7), (-1.8, 1.1, 0.35), 35),
                                     ((0.9, 0.8, 0.6), (0.9, -1.8, 0.3), 37), ((1.4, 1.2, 0.9), (-1.0, -1.6, 0.45), 39), ((0.7, 0.6, 0.5), (2.6, -1.4, 0.25), 41))):
    rock(f"Rock_{k}", "Rock", c, sz, loc=loc, seed=seed, detail=1, rough=0.3)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name in ("AlterStatue", "CourtBoulderA", "CourtBoulderB", "CourtRockCluster", "CourtColumnStump", "CourtSlab", "CourtRubble")})
