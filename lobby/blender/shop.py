# The Reliquary (the hub shop), round 2. Shop local frame: front (door) = -Y, origin = floor centre at ground level; floor top z 1.
# Pieces:
#   ShopHouse       the building: stone plinth, plank floor, stone-and-plaster timber-framed walls, bay windows, the door arch,
#                   tiled gable roof with a round gable window, chimney, striped awning, ceiling beams, the sign bracket.
#   ShopSignBoard   the hanging sign; origin = its hinge at the top centre (the builder hangs it on the bracket with physics).
#   ShopShelf       one tall shelf unit, 12 wide, 3 deep, shelves at z 1.2 / 5.9 / 10.6 / 15.3 (origin = bottom centre, front -Y).
#   ShopCounter     the counter, 26 x 5 x 5.6 (origin = bottom centre).
#   ShopKeeper      the robed keeper (origin = feet). Roles: Fabric robe (-> Torso), Body face (-> Head), Sash, Gold.
#   ShopPotion, ShopSword, ShopShield, ShopBooks, ShopScroll, ShopOrbStand, ShopSack, ShopBarrel, ShopCrate: stock.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
ROLES["Sash"] = ((0.6, 0.05, 0.05), 0.0, 0.8)
V = Vector
W, D, H = 44.0, 36.0, 24.0
HW, HD = W / 2, D / 2
T = 1.6  # wall thickness

# =====================================================================================================================
hs = collection("ShopHouse")
solid(box("Stone_Plinth", "Stone", hs, (W + 3, D + 3, 1.8), loc=(0, 0, -0.1), bevel=0.2))
solid(box("Plank_Floor", "Plank", hs, (W - 0.2, D - 0.2, 0.3), loc=(0, 0, 0.85)))
for i in range(-10, 11):
    box("WoodDark_FloorSeam", "WoodDark", hs, (0.12, D - 1, 0.32), loc=(i * 2.0, 0, 0.87))


def wall_band(name, role, x0, x1, y, z0, z1, along="x", openings=()):
    """A straight wall from x0 to x1 (or y0..y1 when along == 'y') with rectangular openings [(c0, c1, z0, z1)] cut out."""
    pts = [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]
    o = slab2d(name, role, hs, pts, -T / 2, T / 2)
    for c0, c1, oz0, oz1 in openings:
        cutter = slab2d("Cut", role, hs, [(c0, oz0), (c1, oz0), (c1, oz1), (c0, oz1)], -T, T)
        cut(o, cutter)
    if along == "x":
        o.location = (0, y, 0)
    else:
        o.rotation_euler = (0, 0, math.radians(90))
        o.location = (y, 0, 0)
    return solid(o)


# window and door openings: (along-wall start, end, bottom, top)
FRONT_OPEN = [(-7.0, 7.0, 1.0, 15.0), (-18.5, -10.5, 5.0, 13.0), (10.5, 18.5, 5.0, 13.0)]
SIDE_OPEN = [(-11.0, -5.0, 12.0, 18.0), (5.0, 11.0, 12.0, 18.0)]
BACK_OPEN = [(-18.5, -12.5, 12.0, 18.0), (12.5, 18.5, 12.0, 18.0)]
for name, y, opens in (("Front", -HD, FRONT_OPEN), ("Back", HD, BACK_OPEN)):
    wall_band(f"Stone_{name}Low", "Stone", -HW, HW, y, 1.0, 6.0, openings=[o for o in opens if o[2] < 6.0])
    wall_band(f"Plaster_{name}High", "Plaster", -HW, HW, y, 6.0, H, openings=opens)
for sx in (-1, 1):
    wall_band(f"Stone_SideLow{sx}", "Stone", -HD, HD, sx * HW, 1.0, 6.0, along="y")
    wall_band(f"Plaster_SideHigh{sx}", "Plaster", -HD, HD, sx * HW, 6.0, H, along="y", openings=SIDE_OPEN)


# half-timbering on the outside of the plaster: posts, rails and braces, skipping openings
def timbers(face, length, posts, openings, out):
    """face: 'front'/'back' (along x at y = -+HD) or 'left'/'right' (along y at x = -+HW). out = outward offset sign."""
    def P(u, z):
        if face == "front":
            return V((u, -HD - 0.85, z))
        if face == "back":
            return V((u, HD + 0.85, z))
        if face == "left":
            return V((-HW - 0.85, u, z))
        return V((HW + 0.85, u, z))
    sec = [(-0.5, -0.35), (0.5, -0.35), (0.5, 0.35), (-0.5, 0.35)]
    for u in posts:
        sweep("WoodDark_Post", "WoodDark", hs, [P(u, 6.0), P(u, H)], sec, smooth=False)
    for z in (6.3, 11.0, 18.8, H - 0.3):
        run = [u * 0.5 for u in range(int(-length), int(length) + 1)]
        seg = []
        for u in run:
            inside = any(c0 - 0.2 < u < c1 + 0.2 and oz0 - 0.2 < z < oz1 + 0.2 for c0, c1, oz0, oz1 in openings)
            if inside:
                if len(seg) > 1:
                    sweep("WoodDark_Rail", "WoodDark", hs, [P(seg[0], z), P(seg[-1], z)], sec, smooth=False)
                seg = []
            else:
                seg.append(u)
        if len(seg) > 1:
            sweep("WoodDark_Rail", "WoodDark", hs, [P(seg[0], z), P(seg[-1], z)], sec, smooth=False)
    for i in range(len(posts) - 1):
        a, b = posts[i], posts[i + 1]
        if not any(c0 - 1 < (a + b) / 2 < c1 + 1 and oz0 < 15 for c0, c1, oz0, oz1 in openings):
            p0, p1 = (P(a + 0.5, 6.6), P(b - 0.5, 10.7)) if i % 2 == 0 else (P(a + 0.5, 10.7), P(b - 0.5, 6.6))
            sweep("WoodDark_Brace", "WoodDark", hs, [p0, p1], sec, smooth=False)
            p0, p1 = (P(a + 0.5, 19.1), P(b - 0.5, H - 0.6)) if i % 2 else (P(a + 0.5, H - 0.6), P(b - 0.5, 19.1))
            sweep("WoodDark_Brace", "WoodDark", hs, [p0, p1], sec, smooth=False)


timbers("front", HW, [-HW + 0.5, -19.5, -9.5, -7.6, 7.6, 9.5, 19.5, HW - 0.5], FRONT_OPEN, -1)
timbers("back", HW, [-HW + 0.5, -11, 0, 11, HW - 0.5], BACK_OPEN, 1)
timbers("left", HD, [-HD + 0.5, -12.5, -3.5, 3.5, 12.5, HD - 0.5], SIDE_OPEN, -1)
timbers("right", HD, [-HD + 0.5, -12.5, -3.5, 3.5, 12.5, HD - 0.5], SIDE_OPEN, 1)
# corner posts, full height
for sx in (-1, 1):
    for sy in (-1, 1):
        solid(box("WoodDark_Corner", "WoodDark", hs, (2.6, 2.6, H + 1.0), loc=(sx * (HW + 0.3), sy * (HD + 0.3), H / 2 + 0.6), bevel=0.2))

# windows: frames, glass, mullions and flower boxes (upper side/back windows); the front ones are bays
def window(u, along, at, z0, z1, w):
    c = V(at)
    if along == "x":
        ax, nrm = V((1, 0, 0)), V((0, -1 if c.y < 0 else 1, 0))
    else:
        ax, nrm = V((0, 1, 0)), V((-1 if c.x < 0 else 1, 0, 0))
    mid = c + ax * u + V((0, 0, (z0 + z1) / 2))
    rot = (0, 0, 0) if along == "x" else (0, 0, math.radians(90))
    box("Glass_Pane", "Glass", hs, (w, 0.2, z1 - z0), loc=mid, rot=rot)
    box("WoodDark_Mullion", "WoodDark", hs, (0.3, 0.5, z1 - z0), loc=mid + nrm * 0.15, rot=rot)
    box("WoodDark_Transom", "WoodDark", hs, (w, 0.5, 0.3), loc=mid + nrm * 0.15, rot=rot)
    box("WoodDark_Sill", "WoodDark", hs, (w + 1.2, 1.4, 0.5), loc=c + ax * u + V((0, 0, z0 - 0.2)) + nrm * 0.7, rot=rot, bevel=0.1)
    box("Wood_FlowerBox", "Wood", hs, (w, 1.6, 1.2), loc=c + ax * u + V((0, 0, z0 - 1.1)) + nrm * 1.4, rot=rot, bevel=0.1)
    for k in range(7):
        rock(f"Leaf_Bloom{k}", "Leaf" if k % 3 else "Red", hs, (1.1, 1.1, 0.9), loc=c + ax * (u - w / 2 + 0.6 + k * (w - 1.2) / 6) + V((0, 0, z0 - 0.2)) + nrm * 1.4, seed=k + int(u * 10), detail=1, rough=0.3, flat_bottom=False)


for u in (-8, 8):
    for sx in (-1, 1):
        window(u, "y", (sx * HW, 0, 0), 12.0, 18.0, 6.0)
for u in (-15.5, 15.5):
    window(u, "x", (0, HD, 0), 12.0, 18.0, 6.0)
# bay windows on the front: a box out from the wall with three faces of glass and a little lead roof
for sx in (-1, 1):
    cx = sx * 14.5
    solid(box("Stone_BaySill", "Stone", hs, (10.0, 3.2, 1.0), loc=(cx, -HD - 1.4, 4.5), bevel=0.15))
    box("Glass_BayFront", "Glass", hs, (8.0, 0.2, 8.0), loc=(cx, -HD - 2.8, 9.0))
    for side in (-1, 1):
        box("Glass_BaySide", "Glass", hs, (0.2, 2.8, 8.0), loc=(cx + side * 4.0, -HD - 1.4, 9.0))
        box("WoodDark_BayPost", "WoodDark", hs, (0.6, 0.6, 8.2), loc=(cx + side * 4.0, -HD - 2.8, 9.0))
    for k in (-2, 0, 2):
        box("WoodDark_BayBar", "WoodDark", hs, (0.25, 0.3, 8.0), loc=(cx + k * 1.33, -HD - 2.95, 9.0))
    box("WoodDark_BayBarH", "WoodDark", hs, (8.0, 0.3, 0.25), loc=(cx, -HD - 2.95, 11.0))
    box("WoodDark_BayHead", "WoodDark", hs, (9.0, 3.4, 0.6), loc=(cx, -HD - 1.4, 13.2), bevel=0.1)
    o = box("Iron_BayRoof", "Iron", hs, (9.6, 3.8, 0.3), loc=(cx, -HD - 1.5, 13.8), rot=(math.radians(-14), 0, 0))
# the door: an arched oak frame and a heavy lintel with a carved keystone
arch_pts = [V((-7.0, -HD - 0.9, 1.0)), V((-7.0, -HD - 0.9, 12.5))]
for i in range(1, 12):
    a = math.pi - i / 12 * math.pi
    arch_pts.append(V((math.cos(a) * 7.0, -HD - 0.9, 12.5 + math.sin(a) * 2.5)))
arch_pts += [V((7.0, -HD - 0.9, 12.5)), V((7.0, -HD - 0.9, 1.0))]
sweep("WoodDark_DoorFrame", "WoodDark", hs, arch_pts, [(-0.9, -0.6), (0.9, -0.6), (0.9, 0.6), (-0.9, 0.6)], smooth=False)
box("Gold_Keystone", "Gold", hs, (1.6, 1.2, 2.0), loc=(0, -HD - 1.4, 15.6), bevel=0.15)
for sx in (-1, 1):
    # the door leaves stand open against the inside wall
    box("Wood_DoorLeaf", "Wood", hs, (0.5, 6.8, 13.0), loc=(sx * 7.8, -HD + 4.4, 7.5), bevel=0.08)
    for k in range(3):
        box("Iron_DoorStrap", "Iron", hs, (0.62, 6.0, 0.4), loc=(sx * 7.8, -HD + 4.4, 3.0 + k * 4.6))
# the doorstep
solid(box("Stone_Step", "Stone", hs, (18, 4, 1.0), loc=(0, -HD - 3.2, 0.5), bevel=0.15))

# the roof: tiled slopes (rows of overlapping tiles), ridge, eaves; gable ends of plaster with a round window
RIDGE = H + 14.0
OVER = 3.0
SLOPE_W = math.hypot(HW + OVER, RIDGE - (H - 1.2))
ang = math.atan2(RIDGE - (H - 1.2), HW + OVER)
ROWS = 12
for sx in (-1, 1):
    for r in range(ROWS):
        t0 = r / ROWS
        # rows from the eave up to the ridge, each a little proud of the one above
        u = (1 - t0 - 0.5 / ROWS)
        cx = sx * (HW + OVER) * u
        cz = (H - 1.2) + (RIDGE - (H - 1.2)) * (1 - u) + 0.35
        o = box("Tile_Row", "Tile", hs, (SLOPE_W / ROWS + 0.5, D + 2 * OVER, 0.55), loc=(cx, 0, cz), rot=(0, sx * ang, 0), bevel=0.1)
        if r % 2 == 1:
            o.location.z += 0.06
    # the underside (so the roof is solid from inside)
    box("WoodDark_Soffit", "WoodDark", hs, (SLOPE_W, D + 2 * OVER, 0.3), loc=(sx * (HW + OVER) / 2, 0, (H - 1.2 + RIDGE) / 2 - 0.4), rot=(0, sx * ang, 0))
sweep("Tile_Ridge", "Tile", hs, [V((0, -HD - OVER - 0.3, RIDGE + 0.3)), V((0, HD + OVER + 0.3, RIDGE + 0.3))], circle(0.9, 10))
for sy in (-1, 1):
    gable = slab2d("Plaster_Gable", "Plaster", hs, [(-HW, H), (HW, H), (0, RIDGE)], -T / 2, T / 2)
    if sy < 0:
        cut(gable, slab2d("Cut", "Plaster", hs, [(math.cos(a) * 2.6, 30.5 + math.sin(a) * 2.6) for a in [i / 20 * math.tau for i in range(20)]], -T, T))
    gable.location.y = sy * HD
    solid(gable)
    # barge boards following the roof line
    for sx in (-1, 1):
        sweep("WoodDark_Barge", "WoodDark", hs, [V((sx * (HW + OVER), sy * (HD + OVER - 0.2), H - 1.6)), V((0, sy * (HD + OVER - 0.2), RIDGE + 0.6))],
              [(-0.4, -0.8), (0.4, -0.8), (0.4, 0.8), (-0.4, 0.8)], smooth=False, hint=(0, 1, 0))
    sweep("WoodDark_KingPost", "WoodDark", hs, [V((0, sy * (HD + 0.85), H)), V((0, sy * (HD + 0.85), RIDGE - 0.6))], [(-0.5, -0.35), (0.5, -0.35), (0.5, 0.35), (-0.5, 0.35)], smooth=False)
torus("WoodDark_RoundWindow", "WoodDark", hs, 2.7, 0.4, seg=24, mseg=6, loc=(0, -HD - 0.85, 30.5), rot=(math.radians(90), 0, 0))
lathe("Glass_RoundPane", "Glass", hs, [(0, -0.1), (2.6, -0.1), (2.6, 0.1), (0, 0.1)], segments=24, loc=(0, -HD, 30.5)).rotation_euler = (math.radians(90), 0, 0)
# chimney (stack on the right-hand slope, back half)
CX, CY = 12.0, 9.0
solid(box("Brick_Chimney", "Brick", hs, (4.6, 4.6, 16.0), loc=(CX, CY, 32.5), bevel=0.1))
box("Stone_ChimneyCap", "Stone", hs, (5.8, 5.8, 1.0), loc=(CX, CY, 40.5), bevel=0.15)
for dx in (-1, 1):
    lathe("Brick_Pot", "Brick", hs, [(0, 0), (0.8, 0), (0.7, 1.8), (0.85, 2.2), (0, 2.2)], segments=10, loc=(CX + dx * 1.2, CY, 41.0))
# ceiling beams inside, the loft floor under the roof
for y in (-14, -7, 0, 7, 14):
    box("WoodDark_Beam", "WoodDark", hs, (W - T, 1.4, 1.4), loc=(0, y, H - 0.8), bevel=0.1)
box("Plank_Ceiling", "Plank", hs, (W - T, D - T, 0.3), loc=(0, 0, H + 0.2))
# the awning over the door and bay windows: striped canvas with a scalloped edge, on iron brackets
AW0, AW1 = -20.0, 20.0
for k in range(10):
    x0 = AW0 + k * 4.0
    role = "Red" if k % 2 == 0 else "Fabric"
    pts = [(x0, 0), (x0 + 4.0, 0), (x0 + 4.0, -5.4), (x0 + 3.0, -6.0), (x0 + 2.0, -5.5), (x0 + 1.0, -6.0), (x0, -5.4)]
    o = slab2d(f"{role}_Awning", role, hs, pts, -0.08, 0.08, plane="xy")
    o.data.transform(Matrix.Rotation(math.radians(22), 4, "X"))
    o.location = (0, -HD - 1.0, 16.6)
for x in (-19, 0, 19):
    sweep("Iron_AwningArm", "Iron", hs, [V((x, -HD - 0.9, 13.6)), V((x, -HD - 4.6, 15.0))], circle(0.14, 6))
box("WoodDark_AwningBar", "WoodDark", hs, (41.0, 0.6, 0.6), loc=(0, -HD - 1.1, 16.6))
# the sign bracket (scrolled iron arm) over the left bay; the board hangs at its tip (hinge at (-19, -HD - 6.4, 20.6))
SIGN_HINGE = V((-19.0, -HD - 6.4, 20.6))
sweep("Iron_SignArm", "Iron", hs, [V((-19.0, -HD - 0.9, 21.2)), V((-19.0, -HD - 6.9, 21.2))], [(-0.18, -0.25), (0.18, -0.25), (0.18, 0.25), (-0.18, 0.25)], smooth=False)
arc = [V((-19.0, -HD - 0.9 - 4.0 * (1 - math.cos(t * math.pi / 2)), 21.0 - 3.0 * math.sin(t * math.pi / 2) * 0 - 3.0 + 3.0 * t)) for t in [i / 8 for i in range(9)]]
sweep("Iron_SignBrace", "Iron", hs, [V((-19.0, -HD - 0.9, 18.0)), V((-19.0, -HD - 4.8, 21.0))], circle(0.13, 6))
torus("Iron_SignCurl", "Iron", hs, 0.8, 0.12, seg=16, mseg=4, loc=(-19.0, -HD - 3.0, 19.9), rot=(0, math.radians(90), 0))
print("house", len(hs.objects))

# =====================================================================================================================
sb = collection("ShopSignBoard")
for k in (-1, 1):
    sweep("Iron_SignChain", "Iron", sb, [V((k * 3.6, 0, 0)), V((k * 3.6, 0, -1.4))], circle(0.08, 5))
board = [(-4.6, -1.4), (4.6, -1.4), (4.6, -5.6), (3.8, -6.6), (0, -7.2), (-3.8, -6.6), (-4.6, -5.6)]
slab2d("WoodDark_Board", "WoodDark", sb, board, -0.3, 0.3)
slab2d("Gold_BoardTrim", "Gold", sb, [(x * 0.92, -1.4 + (z + 1.4) * 0.92) for x, z in board], -0.36, -0.3)
slab2d("WoodDark_BoardIn", "WoodDark", sb, [(x * 0.82, -1.5 + (z + 1.4) * 0.82) for x, z in board], -0.42, -0.36)
# a little gold sword emblem
slab2d("Gold_Emblem", "Gold", sb, [(-0.25, -2.4), (0.25, -2.4), (0.25, -5.0), (0, -5.8), (-0.25, -5.0)], -0.5, -0.42)
slab2d("Gold_EmblemGuard", "Gold", sb, [(-1.4, -2.9), (1.4, -2.9), (1.4, -3.3), (-1.4, -3.3)], -0.52, -0.42)

# =====================================================================================================================
sh = collection("ShopShelf")
SW, SDp, SH = 12.0, 3.0, 19.0
solid(box("WoodDark_ShelfBack", "WoodDark", sh, (SW, 0.4, SH), loc=(0, SDp / 2 - 0.2, SH / 2)))
for sx in (-1, 1):
    solid(box("Wood_ShelfSide", "Wood", sh, (0.6, SDp, SH + 0.6), loc=(sx * (SW / 2 - 0.3), 0, (SH + 0.6) / 2), bevel=0.08))
for z in (1.0, 5.7, 10.4, 15.1, SH):
    box("Plank_Shelf", "Plank", sh, (SW - 0.6, SDp, 0.4), loc=(0, 0, z), bevel=0.06)
    box("Wood_ShelfLip", "Wood", sh, (SW - 0.6, 0.25, 0.6), loc=(0, -SDp / 2 + 0.1, z + 0.1))
box("WoodDark_ShelfCrown", "WoodDark", sh, (SW + 0.8, SDp + 0.6, 0.8), loc=(0, 0, SH + 0.8), bevel=0.15)

# =====================================================================================================================
ct = collection("ShopCounter")
solid(box("Wood_CounterBody", "Wood", ct, (26.0, 5.0, 4.8), loc=(0, 0, 2.4), bevel=0.15))
solid(box("Plank_CounterTop", "Plank", ct, (27.0, 6.0, 0.6), loc=(0, 0, 5.1), bevel=0.15))
for k in range(-5, 6):
    box("WoodDark_CounterPanel", "WoodDark", ct, (1.8, 0.3, 3.4), loc=(k * 2.3, -2.55, 2.4), bevel=0.08)
box("Gold_CounterTrim", "Gold", ct, (26.2, 0.2, 0.3), loc=(0, -2.6, 4.5))

# =====================================================================================================================
kp = collection("ShopKeeper")
robe = [
    ("ELLIPSOID", (0, 0, 2.2), 2.3, (1.0, 0.85, 1.4)),
    capsule((0, 0, 1.0), (0, 0, 5.2), 1.7),
    ("ELLIPSOID", (0, 0, 5.4), 1.8, (1.25, 0.9, 0.8)),
    capsule((1.6, -0.2, 5.4), (1.5, -1.6, 3.9), 0.75), capsule((-1.6, -0.2, 5.4), (-1.5, -1.6, 3.9), 0.75),
    capsule((1.5, -1.6, 3.9), (0.5, -2.3, 4.2), 0.65), capsule((-1.5, -1.6, 3.9), (-0.5, -2.3, 4.2), 0.65),
    ("ELLIPSOID", (0, 0.15, 7.3), 1.35, (1.0, 1.05, 1.2)),  # hood
]
o = sculpt("Fabric_Robe", "Fabric", kp, [(k, c, r * 1.4, e) for k, c, r, e in robe], resolution=0.15, threshold=0.25)
decimate(o, 0.45)
face = sculpt("Body_Face", "Body", kp, [("ELLIPSOID", (0, -0.55, 7.05), 0.85 * 1.4, (0.85, 0.7, 0.95)), ("ELLIPSOID", (0, -0.95, 6.3), 0.6 * 1.4, (0.9, 0.6, 1.4))], resolution=0.12, threshold=0.25)
decimate(face, 0.5)
torus("Sash_Belt", "Sash", kp, 1.95, 0.28, seg=24, mseg=6, loc=(0, 0, 3.9), scale_minor=(1, 1.5))
lathe("Gold_Buckle", "Gold", kp, [(0, -0.2), (0.5, -0.2), (0.5, 0.2), (0, 0.2)], segments=12, loc=(0, -2.1, 3.9)).rotation_euler = (math.radians(90), 0, 0)
lathe("Gold_Amulet", "Gold", kp, [(0, -0.15), (0.45, -0.15), (0.45, 0.15), (0, 0.15)], segments=12, loc=(0, -1.85, 5.4)).rotation_euler = (math.radians(80), 0, 0)
for k in (-1, 1):
    lathe("Ink_Eye", "Ink", kp, [(0, -0.1), (0.14, 0), (0, 0.1)], segments=8, loc=(k * 0.32, -1.48, 7.15))

# =====================================================================================================================
def item(name):
    return collection(name)


c = item("ShopPotion")
lathe("Glass_Flask", "Glass", c, [(0, 0), (0.55, 0.05), (0.7, 0.4), (0.62, 0.95), (0.25, 1.2), (0.22, 1.6), (0.3, 1.7), (0, 1.7)], segments=12)
lathe("Neon_Brew", "Neon", c, [(0, 0.06), (0.5, 0.1), (0.62, 0.4), (0.55, 0.8), (0, 0.8)], segments=12)
lathe("Wood_Cork", "Wood", c, [(0, 1.65), (0.2, 1.65), (0.24, 2.0), (0, 2.0)], segments=8)
c = item("ShopSword")
slab2d("Blade_Blade", "Blade", c, [(-0.17, 0.75), (0.17, 0.75), (0.17, 3.6), (0, 4.0), (-0.17, 3.6)], -0.05, 0.05)
box("Gold_Guard", "Gold", c, (1.4, 0.3, 0.22), loc=(0, 0, 0.62), bevel=0.06)
sweep("Sash_Grip", "Sash", c, [V((0, 0, 0.5)), V((0, 0, -0.5))], circle(0.12, 6))
lathe("Gold_Pommel", "Gold", c, [(0, -0.85), (0.2, -0.7), (0.2, -0.55), (0, -0.5)], segments=8)
c = item("ShopShield")
lathe("Red_ShieldFace", "Red", c, [(0, 0.1), (1.5, 0.0), (1.6, -0.2), (0, -0.25)], segments=20).rotation_euler = (math.radians(90), 0, 0)
torus("Gold_ShieldRim", "Gold", c, 1.55, 0.12, seg=24, mseg=4, rot=(math.radians(90), 0, 0))
lathe("Gold_Boss", "Gold", c, [(0, 0), (0.45, 0), (0.3, 0.3), (0, 0.4)], segments=10, loc=(0, -0.1, 0)).rotation_euler = (math.radians(90), 0, 0)
c = item("ShopBooks")
for k, (h, role) in enumerate([(2.2, "Red"), (2.6, "Blue"), (2.0, "Plank"), (2.4, "Leaf"), (1.9, "Red")]):
    box(f"{role}_Book{k}", role, c, (0.42, 1.6, h), loc=(-0.9 + k * 0.45, 0, h / 2), rot=(0, (0.15 if k == 4 else 0), 0), bevel=0.05)
c = item("ShopScroll")
for k in range(3):
    o = lathe(f"Fabric_Scroll{k}", "Fabric", c, [(0, -1.0), (0.22, -1.0), (0.22, 1.0), (0, 1.0)], segments=8)
    o.rotation_euler = (0, math.radians(90), 0.2 * k)
    o.location = (0, k * 0.4 - 0.4, 0.22 + (0.4 if k == 2 else 0))
    if k == 2:
        o.location = (0, 0, 0.6)
c = item("ShopOrbStand")
lathe("GoldDeep_Stand", "GoldDeep", c, [(0, 0), (0.6, 0), (0.4, 0.2), (0.2, 0.5), (0.45, 0.75), (0, 0.75)], segments=10)
lathe("Neon_Orb", "Neon", c, [(0, 0.7), (0.45, 0.85), (0.62, 1.3), (0.45, 1.75), (0, 1.9)], segments=12)
c = item("ShopSack")
s = sculpt("Fabric_Sack", "Fabric", c, [("ELLIPSOID", (0, 0, 1.1), 1.5, (1.1, 1.0, 1.0)), ("BALL", (0, 0, 2.2), 0.9, None), ("BALL", (0, 0, 2.7), 0.5, None)], resolution=0.15, threshold=0.25)
decimate(s, 0.5)
torus("Rope_Tie", "Rope", c, 0.42, 0.1, seg=12, mseg=4, loc=(0, 0, 2.45))
c = item("ShopBarrel")
solid(lathe("Wood_Barrel", "Wood", c, [(0, 0), (1.6, 0), (1.85, 0.6), (2.05, 1.8), (1.85, 3.0), (1.6, 3.6), (0, 3.6)], segments=16))
for z in (0.45, 3.15):
    torus("Iron_Hoop", "Iron", c, 1.82, 0.12, seg=20, mseg=4, loc=(0, 0, z))
for z in (1.4, 2.2):
    torus("Iron_Hoop", "Iron", c, 2.04, 0.12, seg=20, mseg=4, loc=(0, 0, z))
c = item("ShopCrate")
solid(box("Plank_Crate", "Plank", c, (3.4, 3.4, 3.4), loc=(0, 0, 1.7), bevel=0.15))
for sy in (-1, 1):
    for sx in (-1, 1):
        box("WoodDark_Edge", "WoodDark", c, (0.4, 3.5, 3.5), loc=(sx * 1.55, 0, 1.7))
    box("WoodDark_Diag", "WoodDark", c, (0.35, 0.3, 4.2), loc=(0, sy * 1.72, 1.7), rot=(0, math.radians(45), 0))

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith("Shop")})
