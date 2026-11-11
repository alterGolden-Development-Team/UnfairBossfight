# Azusa's place, rebuilt (2026-11-11, second pass). Run through the Blender MCP: exec(open(r"...\tutorial\blender\blossom.py").read()).
# 1 Blender unit = 1 stud, Z up, front = -Y. Each collection is one piece, modelled round its origin (its pivot).
#
# Kit "Blossom" (tutorial/map: the world)
#   ShrineArena   the fighting floor: a 74-stud round of pale stone with a sakura crest, carved rings, a low balustrade open to the
#                 south, sunk lantern niches, and a long hanging rock skirt underneath (the island floats)
#   SpawnIsle     the small island you arrive on (26 round), grass on stone, its own rock skirt
#   ArchBridge    a red lacquered arched bridge, 64 long, 10 wide, between the two islands
#   GreatSakura   the old tree behind the arena: a twisted trunk, flaring roots and a 70-stud crown of blossom
#   Pagoda        a three-roofed pagoda, 46 tall, on a side rock
#   SkyRock1..3   floating rocks for the sky around the islands, some with blossom on top
# Kit "AzusaFX" (tutorial: Azusa's sword and the shapes her attacks flash with; all white "Glow", coloured in Roblox)
#   Katana        her sword: a curved blade, gold guard, black wrapped grip (5.4 long, grip end at the pivot, blade along +Z)
#   Crescent      a slash wave: a thin crescent 30 wide
#   PetalBlade    a petal-shaped blade she throws (3 long, point along -Y)
#   Sigil         the danger mark on the ground: a ring, a five-petal star and tick marks (radius 1, flat; scaled in Roblox)
#   ThornRing     a ground shockwave: a thin ring with thorns (radius 1, scaled in Roblox)
#   BloomPillar   three spiral ribbons, 30 tall: a pillar of petals erupting from the floor
#   SlashCore / SlashAura   the moonlit crescent in two layers: a thin bright core and a wide soft aura, both cupped forward, with
#                 needle tips (32 wide; flat side toward +Y, the way it flies is -Y)
#   BloomFlower   a five-petal sakura opening, cupped, 10 across: what a mine bursts into
#   Shockwave     a flat ring with a raised outer lip (radius 1): the floor wave of an impact
#   SigilOuter    a serrated outer ring with runes (radius 1.25): turns the other way round a Sigil
#   PetalKunai    a sleek petal blade with a ridge down it (3.4 long, point along -Y)
#   SpiritBlade   her finisher: a giant ghostly katana, 64 long, point down (-Z), the grip at the pivot
#   CutMark       an X of two thin tapered cuts hanging in the air (12 across)
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"Blossom": ((0.95, 0.55, 0.65), 0.0, 0.8), "Glow": ((1.0, 1.0, 1.0), 0.0, 0.5), "Plaster": ((0.85, 0.8, 0.68), 0.0, 0.9),
             "Tile": ((0.08, 0.06, 0.07), 0.0, 0.6), "Petal": ((1.0, 0.7, 0.8), 0.0, 0.6)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau
EXPORT = r"D:\Project\UnfairBossfight\lobby\blender\export"  # every kit is exported (and uploaded) from here
import os
os.makedirs(EXPORT, exist_ok=True)


def cyl(c, name, role, r, z0, z1, loc=(0, 0, 0), seg=16):
    return lathe(name, role, c, [(r, z0), (r, z1)], segments=seg, loc=loc)


def skirt(c, name, radius, depth, seed, top=0.0, lumps=14):
    """A floating island's underside: a rough rock cone hanging from the rim, with boulders bulging out of it."""
    rnd = random.Random(seed)
    prof = []
    steps = 9
    for i in range(steps + 1):
        t = i / steps
        r = radius * (1 - t ** 0.75) * (1 - 0.05 * t)
        prof.append((max(r, 0.0), top - depth * t))
    prof = list(reversed(prof))
    o = lathe(name, "Rock", c, prof, segments=36, smooth=False)
    me = o.data
    for v in me.vertices:
        d = Vector((v.co.x, v.co.y, 0))
        if d.length > 0.5:
            k = 1 + rnd.uniform(-0.1, 0.12) + 0.08 * math.sin(math.atan2(v.co.y, v.co.x) * 5 + v.co.z * 0.2)
            v.co.x *= k
            v.co.y *= k
        v.co.z += rnd.uniform(-1.2, 1.2) if v.co.z < top - 1 else 0
    for _ in range(lumps):
        a = rnd.uniform(0, TAU)
        t = rnd.uniform(0.1, 0.7)
        rr = radius * (1 - t ** 0.75) * 0.95
        s = radius * rnd.uniform(0.18, 0.32)
        rock("Rock_Lump", "Rock", c, (s, s, s * rnd.uniform(0.8, 1.3)), loc=(math.cos(a) * rr, math.sin(a) * rr, top - depth * t), seed=rnd.randint(0, 9999), detail=2, rough=0.35, flat_bottom=False)
    return o


def petal_outline(length, width, n=10):
    """A sakura petal (notched tip) as a 2D outline, base at the origin, pointing +v."""
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append((width * math.sin(math.pi * t) ** 0.8 * (1 - 0.3 * t), length * t))
    right = pts
    left = [(-x, y) for x, y in reversed(pts)]
    notch = [(width * 0.18, length * 0.9), (0, length * 0.8), (-width * 0.18, length * 0.9)]
    return right[:-1] + notch + left[1:]


# ================================================================================================================ Blossom kit
# -------------------------------------------------------------------------------------------------------- ShrineArena
c = collection("ShrineArena")
R = 74
solid(lathe("Stone_Floor", "Stone", c, [(R, -3), (R, 0), (0, 0)], segments=64))
# carved rings and the sakura crest in the middle
for r0, r1, role in ((R - 6, R - 4.6, "StoneWarm"), (46, 47.4, "Red"), (44.6, 45.2, "Gold"), (20, 21.2, "Red"), (0, 3.2, "Gold")):
    prof = [(r1, 0.02), (r1, 0.1), (0, 0.1)] if r0 == 0 else [(r0, 0.02), (r1, 0.02), (r1, 0.1), (r0, 0.1)]
    lathe(f"{role}_Inlay", role, c, prof, segments=64)
for k in range(5):
    a = k / 5 * TAU + math.pi / 2
    o = slab2d("Petal_Crest", "Petal", c, petal_outline(15, 7), 0.02, 0.12, plane="xy")
    o.rotation_euler = (0, 0, a - math.pi / 2)
    o.location = (math.cos(a) * 3, math.sin(a) * 3, 0)
for k in range(24):  # tick marks round the middle ring
    a = k / 24 * TAU
    box("StoneWarm_Tick", "StoneWarm", c, (3.2, 0.5, 0.08), loc=(math.cos(a) * 33, math.sin(a) * 33, 0.05), rot=(0, 0, a))
# the balustrade: posts and rails round the rim, open to the south (-Y) for the bridge
solid(lathe("Stone_Curb", "StoneWarm", c, [(R, 0), (R + 1.5, 0), (R + 1.5, 1.2), (R, 1.2)], segments=64))
for k in range(48):
    a = k / 48 * TAU
    if abs(math.atan2(math.sin(a + math.pi / 2), math.cos(a + math.pi / 2))) < 0.2:
        continue
    x, y = math.cos(a) * (R + 0.75), math.sin(a) * (R + 0.75)
    solid(box("Red_Post", "Red", c, (1.2, 1.2, 4.4), loc=(x, y, 3.4), rot=(0, 0, a), bevel=0.12))
    box("Gold_Cap", "Gold", c, (1.5, 1.5, 0.5), loc=(x, y, 5.8), rot=(0, 0, a))
    b = (k + 0.5) / 48 * TAU
    if abs(math.atan2(math.sin(b + math.pi / 2), math.cos(b + math.pi / 2))) < 0.2:
        continue
    box("Red_Rail", "Red", c, (2 * math.pi * (R + 0.75) / 48, 0.6, 0.5), loc=(math.cos(b) * (R + 0.75), math.sin(b) * (R + 0.75), 4.9), rot=(0, 0, b + math.pi / 2))
    box("Black_Rail", "Black", c, (2 * math.pi * (R + 0.75) / 48, 0.4, 0.35), loc=(math.cos(b) * (R + 0.75), math.sin(b) * (R + 0.75), 2.4), rot=(0, 0, b + math.pi / 2))
# the edge of the floor, then the island hanging under it
lathe("StoneWarm_Edge", "StoneWarm", c, [(R + 2.2, -6), (R + 2.2, -3), (R, -3)], segments=64)
lathe("Grass_Lip", "Grass", c, [(R + 3.6, -7.5), (R + 3.2, -5.6), (R + 2.2, -5.4)], segments=64)
skirt(c, "Rock_Skirt", R + 4, 90, seed=11, top=-6)

# -------------------------------------------------------------------------------------------------------- SpawnIsle
c = collection("SpawnIsle")
solid(lathe("Grass_Top", "Grass", c, [(26, -2), (26, 0), (0, 0)], segments=40))
solid(box("StoneWarm_Path", "StoneWarm", c, (8, 26, 0.3), loc=(0, -13, 0.15)))
for k in range(9):
    a = k / 9 * TAU
    rock("Rock_Stone", "Rock", c, (3, 2.6, 1.6), loc=(math.cos(a) * 22, math.sin(a) * 22, 0.3), seed=200 + k, detail=1)
lathe("Rock_Rim", "Rock", c, [(27.5, -5), (27, -2), (26, -0.6)], segments=40)
skirt(c, "Rock_Skirt", 28, 46, seed=12, top=-4, lumps=8)

# -------------------------------------------------------------------------------------------------------- ArchBridge
c = collection("ArchBridge")
L, W = 64, 10
deck = []
for i in range(17):
    t = i / 16
    y = -L / 2 + L * t
    z = 5 * math.sin(math.pi * t)
    deck.append(V((0, y, z)))
solid(sweep("Plank_DeckS", "Plank", c, deck, [(-W / 2, -0.8), (W / 2, -0.8), (W / 2, 0), (-W / 2, 0)], smooth=False, hint=(1, 0, 0)))
for s in (-1, 1):
    rail = [p + V((s * (W / 2 - 0.4), 0, 3.6)) for p in deck]
    sweep("Red_Rail", "Red", c, rail, circle(0.35, 8), hint=(1, 0, 0))
    mid = [p + V((s * (W / 2 - 0.4), 0, 1.8)) for p in deck]
    sweep("Red_RailLow", "Red", c, mid, circle(0.22, 6), hint=(1, 0, 0))
    for i in range(0, 17, 2):
        p = deck[i]
        box("Red_Baluster", "Red", c, (0.7, 0.7, 4.4), loc=(s * (W / 2 - 0.4), p.y, p.z + 1.6))
        box("Gold_Knob", "Gold", c, (0.9, 0.9, 0.5), loc=(s * (W / 2 - 0.4), p.y, p.z + 4.0))
    # the arch underneath
    under = [V((s * (W / 2 - 1), -L / 2 + L * i / 16, 5 * math.sin(math.pi * i / 16) - 3.5)) for i in range(17)]
    sweep("Black_Beam", "Black", c, under, [(-0.6, -1.4), (0.6, -1.4), (0.6, 0), (-0.6, 0)], smooth=False, hint=(1, 0, 0))

# -------------------------------------------------------------------------------------------------------- GreatSakura
c = collection("GreatSakura")
rnd = random.Random(77)
trunk = [V((0, 0, -2)), V((1.5, 0.5, 8)), V((-1.5, 1.2, 16)), V((1, -0.5, 24)), V((3, 0.5, 31)), V((2, 1.5, 38))]
sweep("Bark_Trunk", "Bark", c, trunk, lambda t: circle(5.2 * (1 - t * 0.62), 14), twist=lambda t: t * 1.2)
for k in range(7):  # roots
    a = k / 7 * TAU + rnd.uniform(-0.2, 0.2)
    root = [V((math.cos(a) * 2, math.sin(a) * 2, 3)), V((math.cos(a) * 6, math.sin(a) * 6, 0.5)), V((math.cos(a) * rnd.uniform(10, 14), math.sin(a) * rnd.uniform(10, 14), -0.8))]
    sweep("Bark_Root", "Bark", c, root, lambda t: circle(1.8 * (1 - t * 0.75), 8))
tips = []
for k in range(11):
    base = trunk[2 + k % 4]
    a = k * 2.4 + rnd.uniform(-0.3, 0.3)
    reach = rnd.uniform(12, 22)
    end = base + V((math.cos(a) * reach, math.sin(a) * reach, rnd.uniform(4, 12)))
    mid = (base + end) / 2 + V((0, 0, rnd.uniform(1, 4)))
    sweep("Bark_Branch", "Bark", c, [base, mid, end], lambda t: circle(1.5 * (1 - t * 0.7), 8))
    tips.append(end)
    for j in range(2):
        twig_end = end + V((rnd.uniform(-6, 6), rnd.uniform(-6, 6), rnd.uniform(1, 5)))
        sweep("Bark_Twig", "Bark", c, [end, twig_end], lambda t: circle(0.6 * (1 - t * 0.7), 6))
        tips.append(twig_end)
tips.append(trunk[-1] + V((0, 0, 4)))
for p in tips:
    for j in range(3):
        s = rnd.uniform(7, 12)
        rock("Blossom_Cloud", "Blossom", c, (s, s, s * 0.7), loc=tuple(p + V((rnd.uniform(-4, 4), rnd.uniform(-4, 4), rnd.uniform(-1, 3)))), seed=rnd.randint(0, 99999), detail=2, rough=0.35, flat_bottom=False)
for _ in range(16):  # lighter clumps on top
    p = tips[rnd.randrange(len(tips))]
    s = rnd.uniform(4, 7)
    rock("Petal_Cloud", "Petal", c, (s, s, s * 0.7), loc=tuple(p + V((rnd.uniform(-5, 5), rnd.uniform(-5, 5), rnd.uniform(2, 6)))), seed=rnd.randint(0, 99999), detail=1, rough=0.3, flat_bottom=False)

# -------------------------------------------------------------------------------------------------------- Pagoda
c = collection("Pagoda")
solid(box("StoneWarm_Base", "StoneWarm", c, (22, 22, 3), loc=(0, 0, 1.5), bevel=0.3))
solid(box("Stone_Step", "Stone", c, (8, 4, 1.5), loc=(0, -12.5, 0.75)))
z = 3
for tier, (w, h) in enumerate(((16, 9), (13, 7.5), (10, 6.5))):
    solid(box("Plaster_Body", "Plaster", c, (w, w, h), loc=(0, 0, z + h / 2)))
    for sx in (-1, 1):
        for sy in (-1, 1):
            box("Red_Pillar", "Red", c, (1.1, 1.1, h), loc=(sx * (w / 2 - 0.2), sy * (w / 2 - 0.2), z + h / 2))
    for sy in (-1, 1):
        box("Red_Beam", "Red", c, (w + 0.6, 1.1, 0.9), loc=(0, sy * (w / 2 - 0.1), z + h - 0.5))
        box("Red_Beam", "Red", c, (1.1, w + 0.6, 0.9), loc=(sy * (w / 2 - 0.1), 0, z + h - 0.5))
    box("Black_Door", "Black", c, (w * 0.32, 0.4, h * 0.62), loc=(0, -w / 2 - 0.1, z + h * 0.31))
    # the roof: a square lathe with up-turned eaves
    rw = w * 0.92 + 5
    lathe("Tile_Roof", "Tile", c, [(rw * 0.75, z + h + 0.6), (rw * 0.72, z + h + 1.2), (w * 0.55, z + h + 2.6), (w * 0.3, z + h + 3.4), (0, z + h + 3.6)], segments=4, smooth=False).rotation_euler = (0, 0, math.pi / 4)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tip = V((sx * rw * 0.53, sy * rw * 0.53, z + h + 1.4))
            sweep("Gold_Eave", "Gold", c, [tip * 0.8 + V((0, 0, (z + h + 1.0) * 0.2)), tip + V((0, 0, 0.9))], circle(0.3, 6))
    z += h + 3.2
cyl(c, "Gold_Spire", "Gold", 0.5, z, z + 7, seg=10)
for k in range(5):
    torus("Gold_Ring", "Gold", c, 1.1 - k * 0.12, 0.18, seg=16, mseg=6, loc=(0, 0, z + 1.2 + k * 1.1))
skirt(c, "Rock_Skirt", 18, 36, seed=13, top=0, lumps=6)

# -------------------------------------------------------------------------------------------------------- SkyRocks
for i in range(1, 4):
    c = collection(f"SkyRock{i}")
    rnd = random.Random(300 + i)
    size = 10 + i * 5
    lathe("Grass_Top", "Grass", c, [(size, -1), (size, 0), (0, 0)], segments=20)
    skirt(c, "Rock_Skirt", size + 1, size * 2.2, seed=400 + i, top=-1, lumps=4)
    if i != 2:
        for _ in range(3):
            s = rnd.uniform(4, 7)
            rock("Blossom_Bush", "Blossom", c, (s, s, s * 0.7), loc=(rnd.uniform(-size / 2, size / 2), rnd.uniform(-size / 2, size / 2), s * 0.3), seed=rnd.randint(0, 9999), detail=1, rough=0.3)

# ================================================================================================================ AzusaFX kit
# -------------------------------------------------------------------------------------------------------- Katana
c = collection("Katana")
blade_pts = [V((0, 0.08 * (t / 8) ** 2 * 8, 1.4 + t * 0.5)) for t in range(9)]
sweep("Glow_Blade", "Glow", c, blade_pts, lambda t: [(-0.05, -0.22 * (1 - t * 0.6)), (0.05, -0.22 * (1 - t * 0.6)), (0.0, 0.2 * (1 - t * 0.85))], smooth=False, hint=(1, 0, 0))
cyl(c, "Gold_Tsuba", "Gold", 0.42, 1.25, 1.4, seg=12)
cyl(c, "Black_Grip", "Black", 0.16, 0, 1.25, seg=8)
for k in range(5):
    torus("Fabric_Wrap", "Fabric", c, 0.17, 0.05, seg=10, mseg=5, loc=(0, 0, 0.15 + k * 0.23))

# -------------------------------------------------------------------------------------------------------- Crescent
c = collection("Crescent")
arc = []
for i in range(25):
    t = i / 24
    a = math.pi * (0.1 + 0.8 * t)
    arc.append(V((math.cos(a) * 15, -math.sin(a) * 6, 0)))
sweep("Glow_Crescent", "Glow", c, arc, lambda t: [(-0.25, -2.2 * math.sin(math.pi * t) ** 0.7), (0.25, -2.2 * math.sin(math.pi * t) ** 0.7),
                                                   (0.25, 2.2 * math.sin(math.pi * t) ** 0.7), (-0.25, 2.2 * math.sin(math.pi * t) ** 0.7)], hint=(0, 0, 1))

# -------------------------------------------------------------------------------------------------------- PetalBlade
c = collection("PetalBlade")
o = slab2d("Glow_Petal", "Glow", c, petal_outline(3, 0.9), -0.08, 0.08, plane="xy")
o.rotation_euler = (0, 0, math.pi)
o.location = (0, 1.5, 0)

# -------------------------------------------------------------------------------------------------------- Sigil
c = collection("Sigil")
lathe("Glow_Ring", "Glow", c, [(0.93, 0), (1.0, 0), (1.0, 0.04), (0.93, 0.04)], segments=48)
lathe("Glow_Ring", "Glow", c, [(0.72, 0), (0.75, 0), (0.75, 0.04), (0.72, 0.04)], segments=48)
for k in range(5):
    a = k / 5 * TAU
    o = slab2d("Glow_Star", "Glow", c, petal_outline(0.68, 0.24), 0, 0.04, plane="xy")
    o.rotation_euler = (0, 0, a - math.pi / 2)
for k in range(20):
    a = k / 20 * TAU
    box("Glow_Tick", "Glow", c, (0.12, 0.03, 0.04), loc=(math.cos(a) * 0.84, math.sin(a) * 0.84, 0.02), rot=(0, 0, a))

# -------------------------------------------------------------------------------------------------------- ThornRing
c = collection("ThornRing")
torus("Glow_Ring", "Glow", c, 1.0, 0.035, seg=64, mseg=6, scale_minor=(1, 2.2))
for k in range(16):
    a = k / 16 * TAU
    base = V((math.cos(a), math.sin(a), 0))
    sweep("Glow_Thorn", "Glow", c, [base, base * 1.04 + V((0, 0, 0.22))], lambda t: circle(0.035 * (1 - t), 5))

# -------------------------------------------------------------------------------------------------------- BloomPillar
c = collection("BloomPillar")
for strand in range(3):
    pts = []
    for i in range(41):
        t = i / 40
        a = strand / 3 * TAU + t * TAU * 1.6
        r = 3.2 * (1 - 0.45 * t)
        pts.append(V((math.cos(a) * r, math.sin(a) * r, t * 30)))
    sweep("Glow_Ribbon", "Glow", c, pts, lambda t: [(-0.06, -0.9 * (1 - t * 0.7)), (0.06, -0.9 * (1 - t * 0.7)), (0.06, 0.9 * (1 - t * 0.7)), (-0.06, 0.9 * (1 - t * 0.7))])

# -------------------------------------------------------------------------------------------------------- SlashCore / SlashAura
for name, width, thick in (("SlashCore", 0.9, 0.12), ("SlashAura", 2.6, 0.05)):
    c = collection(name)
    pts = []
    for i in range(41):
        t = i / 40
        a = math.pi * (0.06 + 0.88 * t)
        pts.append(V((math.cos(a) * 16, -math.sin(a) * 7, math.sin(math.pi * t) * 1.4)))  # cupped: the middle lifts a little
    sweep("Glow_" + name, "Glow", c, pts, lambda t, w=width, th=thick: [(-th, -w * math.sin(math.pi * t) ** 0.9 * (1 + 0.5 * t)), (th, -w * math.sin(math.pi * t) ** 0.9 * (1 + 0.5 * t)),
                                                                         (th, w * 0.35 * math.sin(math.pi * t) ** 0.9), (-th, w * 0.35 * math.sin(math.pi * t) ** 0.9)], hint=(0, 0, 1))

# -------------------------------------------------------------------------------------------------------- BloomFlower
c = collection("BloomFlower")
for k in range(5):
    a = k / 5 * TAU
    o = slab2d("Glow_Petal", "Glow", c, petal_outline(5, 2.6, n=14), -0.08, 0.08, plane="xy")
    for v in o.data.vertices:  # cup each petal upward toward its tip
        v.co.z += (v.co.y / 5) ** 2 * 1.6
    o.rotation_euler = (0, 0, a - math.pi / 2)
lathe("Glow_Heart", "Glow", c, [(0, 0.1), (0.9, 0.2), (0.6, 0.6), (0, 0.7)], segments=10)

# -------------------------------------------------------------------------------------------------------- Shockwave
c = collection("Shockwave")
lathe("Glow_Wave", "Glow", c, [(0.82, 0), (1.0, 0), (1.02, 0.12), (0.97, 0.16), (0.9, 0.04)], segments=64)

# -------------------------------------------------------------------------------------------------------- SigilOuter
c = collection("SigilOuter")
lathe("Glow_Ring", "Glow", c, [(1.16, 0), (1.2, 0), (1.2, 0.04), (1.16, 0.04)], segments=64)
for k in range(36):
    a = k / 36 * TAU
    o = slab2d("Glow_Tooth", "Glow", c, [(-0.035, 0), (0.035, 0), (0, 0.09 if k % 3 else 0.16)], 0, 0.04, plane="xy")
    o.rotation_euler = (0, 0, a - math.pi / 2)
    o.location = (math.cos(a) * 1.2, math.sin(a) * 1.2, 0)
for k in range(8):  # runes between the rings
    a = (k + 0.5) / 8 * TAU
    for j in range(3):
        box("Glow_Rune", "Glow", c, (0.05, 0.12 - j * 0.03, 0.04), loc=(math.cos(a + j * 0.05) * 1.08, math.sin(a + j * 0.05) * 1.08, 0.02), rot=(0, 0, a + j * 0.6))

# -------------------------------------------------------------------------------------------------------- PetalKunai
c = collection("PetalKunai")
o = slab2d("Glow_Kunai", "Glow", c, [(0, 0), (0.5, 0.9), (0.42, 2.2), (0, 3.4), (-0.42, 2.2), (-0.5, 0.9)], -0.06, 0.06, plane="xy")
o.rotation_euler = (0, 0, math.pi)
o.location = (0, 1.7, 0)
sweep("Glow_Ridge", "Glow", c, [V((0, 1.4, 0.06)), V((0, -1.6, 0.06))], [(-0.06, 0), (0.06, 0), (0, 0.08)], smooth=False)

# -------------------------------------------------------------------------------------------------------- SpiritBlade
c = collection("SpiritBlade")
bl = [V((0, 0.9 * (t / 12) ** 2 * 12 * 0.18, -10 - t * 4.5)) for t in range(13)]
sweep("Glow_Blade", "Glow", c, bl, lambda t: [(-0.5, -2.6 * (1 - t * 0.7)), (0.5, -2.6 * (1 - t * 0.7)), (0.0, 2.2 * (1 - t * 0.95))], smooth=False, hint=(1, 0, 0))
cyl(c, "Gold_Tsuba", "Gold", 4, -10, -9, seg=16)
torus("Gold_TsubaRing", "Gold", c, 3.6, 0.35, seg=24, mseg=6, loc=(0, 0, -9.5))
cyl(c, "Black_Grip", "Black", 1.2, -9, 4, seg=10)
for k in range(8):
    torus("Petal_Wrap", "Petal", c, 1.3, 0.3, seg=12, mseg=5, loc=(0, 0, -8 + k * 1.5))
lathe("Gold_Pommel", "Gold", c, [(1.4, 4), (1.2, 5), (0, 5.4)], segments=12)

# -------------------------------------------------------------------------------------------------------- CutMark
c = collection("CutMark")
for sgn in (-1, 1):
    pts = [V((-6, 0, -6 * sgn)), V((0, 0, 0)), V((6, 0, 6 * sgn))]
    sweep("Glow_Cut", "Glow", c, [V((x * 1, 0, z)) for x, _, z in [(p.x, 0, p.z) for p in pts]], lambda t: [(-0.04, -0.35 * math.sin(math.pi * t)), (0.04, -0.35 * math.sin(math.pi * t)), (0.04, 0.35 * math.sin(math.pi * t) + 0.001), (-0.04, 0.35 * math.sin(math.pi * t) + 0.001)], hint=(0, 1, 0))

bpy.context.view_layer.update()
print("built", [c.name for c in bpy.data.collections])
