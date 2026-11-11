# The glitched place, rebuilt (2026-11-11, second pass). Run through the Blender MCP: exec(open(r"...\glitched\blender\void.py").read()).
# 1 Blender unit = 1 stud, Z up, front = -Y. Each collection is one piece, modelled round its origin (its pivot).
# Everything is black and white: "White" and "Black" surfaces, "Glow" for the white seams that flicker (coloured in Roblox),
# and a few "Static" faces the client scrolls noise over.
#
# Kit "Void" (glitched/map)
#   VoidSlab1..3     broken pieces of the road: jagged slabs, white on top, black beneath, a glowing crack through each, with
#                    pixel chunks drifting off the broken edges (18-26 long, 14 wide; top at z = 0)
#   VoidTower        a city tower cut into slices that have slid sideways (a frame skipped), lit windows, 70 tall
#   VoidClock        a giant clock face snapped in three, its hands bent, numerals as blocks (radius 22, standing)
#   VoidTree         a dead tree hanging upside down from nothing (roots at the top), 30 long
#   VoidStair        a spiral stair round a pillar that stops in mid-air, 34 tall
#   VoidMonolith     a tall black slab displaced in steps, a white slit down its face, 40 tall
#   VoidDoor         a lone door frame standing on a chunk of floor, its doorway white
#   VoidDais         the end: a round stepped dais (radius 26) cracked in rings, broken pieces lifted off its edge
#   VoidHalo         a broken ring of shards that turns over the dais (radius 30)
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"Glow": ((1.0, 1.0, 1.0), 0.0, 0.5), "Static": ((0.5, 0.5, 0.5), 0.0, 0.5)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau
EXPORT = r"D:\Project\UnfairBossfight\lobby\blender\export"  # every kit is exported (and uploaded) from here


def cyl(c, name, role, r, z0, z1, loc=(0, 0, 0), seg=16):
    return lathe(name, role, c, [(r, z0), (r, z1)], segments=seg, loc=loc)


def jagged(rnd, hw, hl, n=7, amp=2.5):
    """A rough rectangle outline (x half-width hw, y half-length hl) with broken, jagged ends and nicked sides."""
    pts = []
    for i in range(n + 1):  # far end, left to right
        pts.append((-hw + 2 * hw * i / n, hl + rnd.uniform(-amp, amp * 0.6)))
    for i in range(1, 4):  # right side
        pts.append((hw + rnd.uniform(-0.8, 0.3), hl - 2 * hl * i / 4))
    for i in range(n + 1):  # near end, right to left
        pts.append((hw - 2 * hw * i / n, -hl + rnd.uniform(-amp * 0.6, amp)))
    for i in range(1, 4):  # left side
        pts.append((-hw + rnd.uniform(-0.3, 0.8), -hl + 2 * hl * i / 4))
    return pts


def pixels(c, rnd, around, count, spread, size=(0.6, 1.8)):
    for _ in range(count):
        s = rnd.uniform(*size)
        role = "White" if rnd.random() < 0.55 else "Black"
        box(f"{role}_Pixel", role, c, (s, s, s), loc=tuple(V(around) + V((rnd.uniform(-spread, spread), rnd.uniform(-spread, spread), rnd.uniform(-spread * 0.6, spread)))),
            rot=(rnd.uniform(0, 1), rnd.uniform(0, 1), rnd.uniform(0, 1)))


# -------------------------------------------------------------------------------------------------------- VoidSlab1..3
for i, (hl, seed) in enumerate(((10, 1), (12, 2), (9, 3)), start=1):
    c = collection(f"VoidSlab{i}")
    rnd = random.Random(seed * 31)
    out = jagged(rnd, 7, hl)
    solid(slab2d("White_Top", "White", c, out, -1.2, 0, plane="xy"))
    inner = [(x * 0.94, y * 0.94) for x, y in out]
    slab2d("Black_Under", "Black", c, inner, -4.5, -1.2, plane="xy")
    tip = [(x * 0.55, y * 0.6) for x, y in out]
    slab2d("Black_Keel", "Black", c, tip, -9, -4.5, plane="xy")
    # the crack: a zig-zag glowing seam across the top
    pts = []
    y = -hl * 0.8
    x = rnd.uniform(-3, 3)
    while y < hl * 0.8:
        pts.append(V((x, y, 0.03)))
        y += rnd.uniform(1.5, 3)
        x = max(-5, min(5, x + rnd.uniform(-2.5, 2.5)))
    sweep("Glow_Crack", "Glow", c, pts, [(-0.18, 0), (0.18, 0), (0.12, 0.06), (-0.12, 0.06)], smooth=False)
    pixels(c, rnd, (0, hl + 2, -1), 9, 3)
    pixels(c, rnd, (0, -hl - 2, -2), 6, 3)

# -------------------------------------------------------------------------------------------------------- VoidTower
c = collection("VoidTower")
rnd = random.Random(77)
z, w = 0, 16
for k in range(7):
    h = rnd.uniform(7, 12)
    dx = 0 if k == 0 else rnd.uniform(-3.5, 3.5)
    dy = 0 if k == 0 else rnd.uniform(-1.5, 1.5)
    solid(box("Black_Slice", "Black", c, (w, w, h - 0.3), loc=(dx, dy, z + h / 2)))
    for row in range(int(h // 3)):
        for col_ in range(4):
            if rnd.random() < 0.6:
                for face in (-1, 1):
                    box("Glow_Window", "Glow", c, (2.2, 0.2, 1.6), loc=(dx - w / 2 + 2.4 + col_ * 3.7, dy + face * (w / 2 + 0.05), z + 1.6 + row * 3))
    if rnd.random() < 0.5:
        box("Static_Band", "Static", c, (w + 0.4, w + 0.4, 0.8), loc=(dx, dy, z + h - 0.4))
    z += h
pixels(c, rnd, (0, 0, z + 2), 16, 7, (0.8, 2.6))

# -------------------------------------------------------------------------------------------------------- VoidClock
c = collection("VoidClock")
rnd = random.Random(12)
Rr = 22
parts = ((0.0, 2.2, (0, 0, 0)), (2.25, 4.1, (2.5, 0, -1.5)), (4.15, TAU - 0.05, (-1.5, 0, 2.5)))
for a0, a1, off in parts:  # the face, in three shards, standing up (in the XZ plane)
    pts = [(0, 0)] + [(math.cos(a0 + (a1 - a0) * t / 12) * Rr, math.sin(a0 + (a1 - a0) * t / 12) * Rr) for t in range(13)]
    o = slab2d("White_Face", "White", c, pts, -0.6, 0.6)
    o.location = off
    rim = [V((math.cos(a0 + (a1 - a0) * t / 16) * Rr, 0, math.sin(a0 + (a1 - a0) * t / 16) * Rr)) + V(off) for t in range(17)]
    sweep("Black_Rim", "Black", c, rim, circle(1.0, 8), hint=(0, 1, 0))
for k in range(12):
    a = k / 12 * TAU
    box("Black_Numeral", "Black", c, (1.2 if k % 3 else 2.2, 0.6, 3.2 if k % 3 else 4.2), loc=(math.cos(a) * (Rr - 3.5), -0.9, math.sin(a) * (Rr - 3.5)), rot=(0, -a + math.pi / 2, 0))
sweep("Black_Hand", "Black", c, [V((0, -1.2, 0)), V((6, -1.4, 7)), V((7.5, -1.6, 13.5))], [(-0.6, -0.3), (0.6, -0.3), (0.6, 0.3), (-0.6, 0.3)], smooth=False)
sweep("Black_Hand", "Black", c, [V((0, -1.2, 0)), V((-8, -1.4, -3)), V((-15, -2.5, -2))], [(-0.4, -0.3), (0.4, -0.3), (0.4, 0.3), (-0.4, 0.3)], smooth=False)
cyl(c, "Glow_Pin", "Glow", 1.2, -1.8, 0.6, seg=12).rotation_euler = (math.pi / 2, 0, 0)
pixels(c, rnd, (12, 0, -10), 14, 5)

# -------------------------------------------------------------------------------------------------------- VoidTree (hanging upside down)
c = collection("VoidTree")
rnd = random.Random(5)
trunk = [V((0, 0, 0)), V((0.8, 0.3, -8)), V((-0.6, 0.5, -16)), V((0.5, -0.4, -24))]
sweep("Black_Trunk", "Black", c, trunk, lambda t: circle(2.0 * (1 - t * 0.6), 9))
for k in range(6):  # roots, splayed up at the top
    a = k / 6 * TAU
    sweep("Black_Root", "Black", c, [V((0, 0, -1)), V((math.cos(a) * 4, math.sin(a) * 4, 1.5)), V((math.cos(a) * 8, math.sin(a) * 8, 4 + rnd.uniform(0, 3)))], lambda t: circle(0.8 * (1 - t * 0.8), 6))
for k in range(9):  # branches, drooping down
    base = trunk[1 + k % 3]
    a = rnd.uniform(0, TAU)
    end = base + V((math.cos(a) * rnd.uniform(6, 11), math.sin(a) * rnd.uniform(6, 11), -rnd.uniform(3, 8)))
    sweep("Black_Branch", "Black", c, [base, (base + end) / 2 + V((0, 0, 1.5)), end], lambda t: circle(0.6 * (1 - t * 0.8), 6))
    box("Glow_Leaf", "Glow", c, (0.8, 0.8, 0.8), loc=tuple(end), rot=(0.6, 0.3, 0.1))

# -------------------------------------------------------------------------------------------------------- VoidStair
c = collection("VoidStair")
rnd = random.Random(9)
solid(cyl(c, "Black_Column", "Black", 2.2, -6, 30, seg=12))
for k in range(36):
    a = k * 0.42
    zz = k * 0.9
    if k > 30 and rnd.random() < 0.5:
        continue
    jitter = 0 if k < 26 else rnd.uniform(-1.5, 1.5)
    solid(box("White_Step", "White", c, (7, 2.6, 0.7), loc=(math.cos(a) * 5.5 + jitter, math.sin(a) * 5.5, zz), rot=(0, 0, a)))
pixels(c, rnd, (0, 0, 34), 12, 4)

# -------------------------------------------------------------------------------------------------------- VoidMonolith
c = collection("VoidMonolith")
rnd = random.Random(21)
z = 0
for k in range(6):
    h = rnd.uniform(5, 9)
    dx = 0 if k == 0 else rnd.uniform(-1.4, 1.4)
    solid(box("Black_Block", "Black", c, (8, 3, h), loc=(dx, 0, z + h / 2)))
    box("Glow_Slit", "Glow", c, (0.5, 0.2, h * 0.9), loc=(dx + rnd.uniform(-0.3, 0.3), -1.55, z + h / 2))
    z += h
pixels(c, rnd, (0, 0, z + 1), 8, 3)

# -------------------------------------------------------------------------------------------------------- VoidDoor
c = collection("VoidDoor")
rnd = random.Random(33)
solid(slab2d("White_Floor", "White", c, jagged(rnd, 8, 7, 5, 1.5), -1, 0, plane="xy"))
slab2d("Black_Under", "Black", c, [(x * 0.8, y * 0.8) for x, y in jagged(rnd, 8, 7, 5, 1.5)], -6, -1, plane="xy")
for s in (-1, 1):
    solid(box("Black_Jamb", "Black", c, (1.2, 1.4, 12), loc=(s * 3.6, 0, 6)))
solid(box("Black_Lintel", "Black", c, (8.4, 1.4, 1.2), loc=(0, 0, 12.6)))
box("Glow_Doorway", "Glow", c, (6, 0.3, 11.8), loc=(0, 0, 5.9))

# -------------------------------------------------------------------------------------------------------- VoidDais
c = collection("VoidDais")
rnd = random.Random(44)
for k, (r, h) in enumerate(((26, 0), (19, 1.2), (12, 2.4))):
    role = "White" if k % 2 == 0 else "Black"
    solid(lathe(f"{role}_Step", role, c, [(r, h - 1.2 if k else -3), (r, h), (0, h)], segments=40))
    lathe("Glow_Seam", "Glow", c, [(r + 0.05, h - 0.02), (r + 0.25, h - 0.02), (r + 0.25, h + 0.04), (r + 0.05, h + 0.04)], segments=40)
skirt_pts = [(26, -3), (22, -10), (12, -18), (0, -22)]
lathe("Black_Skirt", "Black", c, skirt_pts, segments=24, smooth=False)
for k in range(8):  # cracks running out from the middle
    a = k / 8 * TAU + rnd.uniform(-0.2, 0.2)
    pts = [V((math.cos(a) * r, math.sin(a) * r, 2.45 if r < 12 else (1.25 if r < 19 else 0.05))) + V((rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6), 0)) for r in (3, 8, 11.5, 14, 18.5, 22, 25)]
    sweep("Glow_Crack", "Glow", c, pts, [(-0.16, 0), (0.16, 0), (0.1, 0.05), (-0.1, 0.05)], smooth=False)
for k in range(10):  # pieces lifted off the edge
    a = k / 10 * TAU + rnd.uniform(-0.15, 0.15)
    r = rnd.uniform(28, 34)
    s = rnd.uniform(2, 4.5)
    box("White_Chunk" if k % 2 else "Black_Chunk", "White" if k % 2 else "Black", c, (s * 1.5, s, s * 0.6), loc=(math.cos(a) * r, math.sin(a) * r, rnd.uniform(2, 14)), rot=(rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6), a))

# -------------------------------------------------------------------------------------------------------- VoidHalo
c = collection("VoidHalo")
rnd = random.Random(55)
for k in range(28):
    a = k / 28 * TAU
    if k in (5, 6, 17):
        continue  # the gaps
    blade(f"{'White' if k % 2 else 'Black'}_Shard", "White" if k % 2 else "Black", c, (0, 0), a, 28, 32 + rnd.uniform(-1, 2), 1.4, 0.3, depth=0.6)

bpy.context.view_layer.update()
print("built void")
