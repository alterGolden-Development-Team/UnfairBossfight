# The walls behind the three hub portals (and each area's way back), so a gate can only be walked into from the front.
# One per portal, in that portal's own style (lobby/map/Gates.luau, Gates.backWall picks by the portal's target):
#   WallGolden   alterGolden's golden door (and the palace's way back): white marble between gold pilasters, a gold sun medallion
#                with a crown on both faces, a red drape, a gold crest along the top.
#   WallWreck    TheFallenNoob's shipwreck (and the island's way back): a broken hull of upright planks with a jagged top, dark ribs,
#                rope lashings, a brass porthole, barnacle crusts and an anchor hung on the back.
#   WallDivided  Jeff n' Fred's crossed swords (and the forest's way back): left half white stone, right half black, a jagged slash
#                glowing down the seam, half a sun disc on each side and a broken sword hilt jammed in the crack.
# Frame: origin = front bottom centre, front = -Y (faces the way into the gate), the body runs out behind (+Y). 26 wide, ~30 tall.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"Sash": ((0.45, 0.02, 0.03), 0.0, 0.8), "Glow": ((1.0, 1.0, 1.0), 0.0, 0.5), "Shell": ((0.9, 0.85, 0.8), 0.0, 0.6)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau
EXPORT = r"D:\Project\UnfairBossfight\lobby\blender\export"
W, H, T = 26.0, 30.0, 3.0  # width, height, thickness


def rod(c, name, role, a, b, r, seg=10):
    return sweep(name, role, c, [V(a), V(b)], circle(r, seg))


def ybox(c, name, role, size, loc, rot=(0, 0, 0), bevel=0.0):
    return box(name, role, c, size, loc=loc, rot=rot, bevel=bevel)


def both_faces(fn):
    """Call fn(y, s): y = the face's plane, s = -1 for the front face, +1 for the back face."""
    for y, s in ((0.0, -1), (T, 1)):
        fn(y, s)


def disc(c, name, role, r, thick, loc, seg=32):
    o = lathe(name, role, c, [(r, 0), (r, thick), (0, thick)], segments=seg, smooth=False)
    o.rotation_euler = (math.pi / 2, 0, 0)
    o.location = loc
    return o


# ------------------------------------------------------------------------------------------------------------- WallGolden
c = collection("WallGolden")
solid(ybox(c, "Marble_Wall", "Marble", (W - 4, T, H - 2), (0, T / 2, (H - 2) / 2), bevel=0.15))
for x in (-W / 2 + 1.5, W / 2 - 1.5):  # pilasters
    solid(ybox(c, "Gold_Pilaster", "Gold", (3.0, T + 1.2, H - 2), (x, T / 2, (H - 2) / 2), bevel=0.2))
    for z in (1.0, H - 3.0):
        ybox(c, "GoldDeep_Cap", "GoldDeep", (3.8, T + 1.8, 1.2), (x, T / 2, z), bevel=0.15)
solid(ybox(c, "Gold_Plinth", "Gold", (W + 0.6, T + 1.6, 1.6), (0, T / 2, 0.8), bevel=0.2))
ybox(c, "Gold_Cornice", "Gold", (W + 1.2, T + 2.0, 1.4), (0, T / 2, H - 1.3), bevel=0.25)
# crest: a stepped gold pediment with a red gem
for i, (w, h) in enumerate(((18, 1.2), (12, 1.1), (6, 1.0))):
    ybox(c, "GoldPale_Crest", "GoldPale", (w, T + 1.0, h), (0, T / 2, H - 0.6 + 0.6 + i * 1.1 + h / 2), bevel=0.15)
ball_r = 0.8
lathe("GemRed_Crown", "GemRed", c, [(0, H + 3.0), (ball_r, H + 3.6), (0, H + 4.4)], segments=10)


def golden_face(y, s):
    off = s * 0.25
    # framed panel lines
    for z in (4.0, H - 5.0):
        ybox(c, "GoldDeep_Rail", "GoldDeep", (W - 7, 0.4, 0.35), (0, y + off, z))
    for x in (-W / 2 + 4.5, W / 2 - 4.5):
        ybox(c, "GoldDeep_Rail", "GoldDeep", (0.35, 0.4, H - 9), (x, y + off, (H - 1) / 2))
    # the sun medallion: rays, a ring and a crowned disc
    cz = H * 0.55
    for k in range(16):
        a = k / 16 * TAU
        L = 5.6 if k % 2 == 0 else 4.4
        o = ybox(c, "Gold_Ray", "Gold", (0.55, 0.35, L), (math.cos(a) * (2.6 + L / 2), y + off, cz + math.sin(a) * (2.6 + L / 2)), rot=(0, -a + math.pi / 2, 0))
    d = disc(c, "GoldPale_Sun", "GoldPale", 3.0, 0.6, (0, y + s * 0.15 + (0 if s > 0 else -0.6), cz))
    t = torus("Gold_SunRing", "Gold", c, 3.2, 0.28, seg=32, mseg=8, loc=(0, y + off * 1.8, cz), rot=(math.pi / 2, 0, 0))
    for k in range(5):  # a little crown on the disc
        x = (k - 2) * 0.85
        ybox(c, "Gold_CrownSpike", "Gold", (0.5, 0.5, 1.2 + (0.6 if k == 2 else 0)), (x, y + off * 2.4, cz + 1.2 + (0.3 if k == 2 else 0)))
    ybox(c, "Gold_CrownBand", "Gold", (4.6, 0.6, 0.6), (0, y + off * 2.4, cz + 0.5))
    # red velvet drape swagged across the top
    pts = [V((x, y + s * 0.6, H - 6.2 + 1.6 * (abs(x) / 9) ** 2)) for x in [i * 1.5 for i in range(-6, 7)]]
    sweep("Sash_Drape", "Sash", c, pts, [(-0.9, -0.3), (0.9, -0.3), (0.9, 0.3), (-0.9, 0.3)], smooth=True, hint=(0, 1, 0))
    for x in (-9.2, 9.2):
        ybox(c, "Sash_Tail", "Sash", (1.2, 0.5, 6.5), (x, y + s * 0.6, H - 9.0))


both_faces(golden_face)

# ------------------------------------------------------------------------------------------------------------- WallWreck
c = collection("WallWreck")
rnd = random.Random(1717)
x = -W / 2
while x < W / 2 - 0.1:
    w = rnd.uniform(1.4, 2.1)
    top = H - 3 - rnd.uniform(0, 7) - (2.5 if abs(x) < 4 else 0)
    lean = rnd.uniform(-0.04, 0.04)
    role = "Plank" if rnd.random() < 0.6 else "Wood"
    solid(ybox(c, f"{role}_Hull", role, (w - 0.08, T * 0.8, top), (x + w / 2, T / 2, top / 2), rot=(0, lean, 0), bevel=0.06))
    # a splintered tip
    ybox(c, f"{role}_Splinter", role, (w * 0.4, T * 0.5, rnd.uniform(0.8, 2.2)), (x + w * rnd.uniform(0.25, 0.75), T / 2, top + 0.6), rot=(0, rnd.uniform(-0.4, 0.4), 0))
    x += w
for z in (3.0, 10.5, 18.0):  # ribs across both faces
    for y, s in ((0.0, -1), (T, 1)):
        rod(c, "WoodDark_Rib", "WoodDark", (-W / 2 - 0.4, y + s * 0.45, z), (W / 2 + 0.4, y + s * 0.45, z + rnd.uniform(-0.6, 0.6)), 0.5)
for x in (-W / 2 - 0.6, W / 2 + 0.6):  # stout posts at the ends
    solid(sweep("WoodDark_Post", "WoodDark", c, [V((x, T / 2, -0.5)), V((x, T / 2, H - 4))], circle(1.1, 10)))
    for z in (5, 12, 19):
        torus("Rope_Lash", "Rope", c, 1.2, 0.18, seg=16, mseg=6, loc=(x, T / 2, z))
for y, s in ((0.0, -1), (T, 1)):
    t = torus("Iron_Porthole", "Iron", c, 1.7, 0.35, seg=24, mseg=8, loc=(5.5, y + s * 0.4, 14), rot=(math.pi / 2, 0, 0))
    disc(c, "Glass_Port", "Glass", 1.5, 0.15, (5.5, y + s * 0.2 + (0 if s > 0 else -0.15), 14))
    for k in range(8):
        a = k / 8 * TAU
        ybox(c, "Iron_Rivet", "Iron", (0.3, 0.3, 0.3), (5.5 + math.cos(a) * 1.7, y + s * 0.75, 14 + math.sin(a) * 1.7))
    for k in range(10):  # barnacle crusts low down
        rock("Shell_Barnacle", "Shell", c, (rnd.uniform(0.5, 1.1), 0.5, rnd.uniform(0.4, 0.9)), loc=(rnd.uniform(-W / 2 + 1, W / 2 - 1), y + s * 0.35, rnd.uniform(0.6, 5)), seed=rnd.randint(0, 9999), detail=1)
# rope net slung across the front
for k in range(6):
    pts = [V((-9 + i * 3, -0.9, 8.5 - 2.2 * math.sin(i / 6 * math.pi) - k * 0.1 + (k % 2) * 1.2)) for i in range(7)]
    sweep("Rope_Net", "Rope", c, pts, circle(0.12, 5))
# the anchor on the back
ax, ay = -5.0, T + 0.9
sweep("Iron_Shank", "Iron", c, [V((ax, ay, 6)), V((ax, ay, 17))], circle(0.38, 8))
torus("Iron_AnchorRing", "Iron", c, 0.9, 0.2, seg=16, mseg=6, loc=(ax, ay, 17.9), rot=(math.pi / 2, 0, 0))
ybox(c, "Iron_Stock", "Iron", (5.0, 0.5, 0.5), (ax, ay, 15.6))
arm = [V((ax - 3.0 + i * 0.75, ay, 6.8 + 0.28 * (i - 4) ** 2 * 0.5)) for i in range(9)]
sweep("Iron_Arm", "Iron", c, arm, circle(0.35, 8))
for s in (-1, 1):
    ybox(c, "Iron_Fluke", "Iron", (1.4, 0.4, 1.2), (ax + s * 3.1, ay, 9.5), rot=(0, s * 0.6, 0))

# ------------------------------------------------------------------------------------------------------------- WallDivided
c = collection("WallDivided")
rnd = random.Random(2020)
# the jagged seam the two halves meet along
seam = [(0.0, 0.0)]
z = 0.0
while z < H:
    z = min(H, z + rnd.uniform(1.6, 3.2))
    seam.append((rnd.uniform(-1.2, 1.2) if z < H else 0.0, z))


def half(role, side):
    # a slab from the outer edge to the seam, built as a 2D outline in the XZ plane and given thickness along Y
    outline = [(side * W / 2, 0.0)] + [(sx, sz) for sx, sz in seam] + [(side * W / 2, H)]
    if side < 0:
        outline = [(side * W / 2, 0.0)] + [(sx, sz) for sx, sz in seam] + [(side * W / 2, H)]
    bm = bmesh.new()
    pts = outline if side > 0 else list(reversed(outline))
    front = [bm.verts.new((p[0], 0.0, p[1])) for p in pts]
    back = [bm.verts.new((p[0], T, p[1])) for p in pts]
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[i], front[j], back[j], back[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return solid(obj_from_bm(bm, f"{role}_Half", role, c, smooth=False))


half("White", -1)
half("Black", 1)
# the slash: a glowing strip along the seam on both faces
for y, s in ((0.0, -1), (T, 1)):
    path = [V((sx, y + s * 0.12, sz)) for sx, sz in seam]
    sweep("Glow_Slash", "Glow", c, path, [(-0.35, -0.08), (0.35, -0.08), (0.35, 0.08), (-0.35, 0.08)], smooth=False, hint=(0, 1, 0))
    # half a sun disc on each side, each in the other half's colour
    for side, role in ((-1, "Black"), (1, "White")):
        o = lathe(f"{role}_HalfSun", role, c, [(4.2, 0), (4.2, 0.35), (0, 0.35)], segments=24, smooth=False)
        o.rotation_euler = (math.pi / 2, 0, 0)
        o.location = (side * 6.2, y + (0 if s > 0 else -0.35), 16)
        torus(f"{role}_SunRim", role, c, 4.6, 0.22, seg=28, mseg=6, loc=(side * 6.2, y + s * 0.25, 16), rot=(math.pi / 2, 0, 0))
    # coursing lines
    for z in range(4, int(H), 4):
        for side, role in ((-1, "Black"), (1, "White")):
            ybox(c, f"{role}_Course", role, (W / 2 - 2.0, 0.2, 0.18), (side * (W / 4 + 0.6), y + s * 0.1, z))
# caps and plinth, each half its own colour
for side, role in ((-1, "White"), (1, "Black")):
    solid(ybox(c, f"{role}_Plinth", role, (W / 2 + 0.6, T + 1.4, 1.4), (side * (W / 4 + 0.15), T / 2, 0.7), bevel=0.15))
    ybox(c, f"{role}_Cap", role, (W / 2 + 0.8, T + 1.6, 1.2), (side * (W / 4 + 0.2), T / 2, H + 0.4), bevel=0.15)
# a broken sword hilt jammed in the crack, high up, sticking out of the back
mid = seam[len(seam) // 2]
sweep("Black_Grip", "Black", c, [V((mid[0], T + 0.2, mid[1] + 6)), V((mid[0] + 0.4, T + 3.4, mid[1] + 7.2))], circle(0.28, 8))
ybox(c, "White_Guard", "White", (2.6, 0.5, 0.45), (mid[0] + 0.1, T + 0.9, mid[1] + 6.2), rot=(0.35, 0, 0.2))
sweep("White_Blade", "White", c, [V((mid[0], T + 0.6, mid[1] + 6.1)), V((mid[0] - 0.2, -0.3, mid[1] + 5.4))], [(-0.5, -0.06), (0.5, -0.06), (0.5, 0.06), (-0.5, 0.06)], smooth=False, hint=(0, 0, 1))

bpy.context.view_layer.update()
print("walls built")
