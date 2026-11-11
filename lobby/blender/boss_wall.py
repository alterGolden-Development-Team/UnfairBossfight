# The Golden Encounter's castle wall and the boss entrance gate. Roblox (x, y, z) = Blender (-x, z, y).
#   WallBayA / WallBayB   24 long wall bay: front face at Y 0 (the side that faces the arena), body 22 deep behind it, deck at Z 14,
#                         ashlar blocks, gold cornice and pilasters, merlons. A has an arrow slit, B a gold sun.
#   WallTower             18 x 18 corner / gate-end tower, 21 tall to its machicolated top, gold spire above.
#   BossGateFrame         the gatehouse: two towers (Y 22..33 either side of the 44 wide opening), lintel Z 17..27, banners.
#   BossGateLeaf          one door leaf, hinge at the origin, 22 wide along +Y, 17 tall, a bar of swords between iron rails.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
ROLES["Sandstone"] = ((0.72, 0.58, 0.38), 0.0, 0.9)
ROLES["SandDark"] = ((0.42, 0.32, 0.2), 0.0, 0.95)
ROLES["Banner"] = ((0.5, 0.03, 0.04), 0.0, 1.0)
V = Vector


def rot2(x, y, a):
    ca, sa = math.cos(a), math.sin(a)
    return (x * ca - y * sa, x * sa + y * ca)


def bx(name, role, c, size, loc, rot=(0, 0, 0), b=0.0):
    o = box(name, role, c, size, loc=loc, rot=rot)
    if b > 0:
        bev(o, b, 1)
    return o


def ashlar(c, tag, width, z0, z1, rows, face, angle=0.0, center=(0.0, 0.0), step=6.0):
    """Courses of blocks on one face. face = distance of the face from the centre along the face normal; angle turns the face about Z."""
    h = (z1 - z0) / rows
    n = max(1, round(width / step))
    for r in range(rows):
        if r % 2 and n > 1:
            edges = [-width / 2] + [-width / 2 + width * (i + 0.5) / n for i in range(n)] + [width / 2]
        else:
            edges = [-width / 2 + width * i / n for i in range(n + 1)]
        for i in range(len(edges) - 1):
            x0, x1 = edges[i], edges[i + 1]
            w = x1 - x0 - 0.16
            if w < 0.6:
                continue
            p = (0.30, 0.12)[r % 2]
            role = "SandDark" if (r * 3 + i) % 5 == 0 else "Sandstone"
            wx, wy = rot2((x0 + x1) / 2, face + p / 2 - 0.02, angle)
            bx(f"{role}_Ash{tag}_{r}_{i}", role, c, (w, p + 0.04, h - 0.16), (center[0] + wx, center[1] + wy, z0 + h * (r + 0.5)), (0, 0, angle), 0.1)


def sun(c, loc, radius, orient, rays=12):
    """A gold sun (disc, red gem, spiked rays) at loc; orient is a 4x4 matrix that turns local +Z (the front) to the face normal."""
    base = Matrix.Translation(loc) @ orient
    parts = [lathe("Gold_SunDisc", "Gold", c, [(0, 0), (radius, 0), (radius, 0.3), (radius * 0.62, 0.5), (0, 0.8)], segments=20),
             lathe("GemRed_SunGem", "GemRed", c, [(0, 0.5), (radius * 0.36, 0.5), (radius * 0.2, 0.95), (0, 1.05)], segments=12)]
    for p in parts:
        p.matrix_world = base
    for k in range(rays):
        a = k / rays * math.tau
        o = lathe(f"GoldPale_SunRay{k}", "GoldPale", c, [(0, 0), (radius * 0.11, 0), (0, radius * 0.75)], segments=4, smooth=False)
        o.matrix_world = base @ Matrix.Rotation(a, 4, "Z") @ Matrix.Translation((radius * 0.92, 0, 0.15)) @ Matrix.Rotation(math.pi / 2, 4, "Y")


def merlons(c, tag, xs, y, z, w, d, h, cap=True, rot=(0, 0, 0)):
    for i, x in enumerate(xs):
        bx(f"Sandstone_Mer{tag}{i}", "Sandstone", c, (w, d, h), (x, y, z + h / 2), rot, 0.12)
        if cap:
            bx(f"Gold_MerCap{tag}{i}", "Gold", c, (w + 0.35, d + 0.35, 0.35), (x, y, z + h + 0.17), rot)


# =====================================================================================================================
for variant in ("A", "B"):
    c = collection("WallBay" + variant)
    L, D = 24.0, 22.0
    bx("Sandstone_Body", "Sandstone", c, (L, D, 14.0), (0, -D / 2, 7.0))
    bx("SandDark_Plinth", "SandDark", c, (L, 1.0, 2.6), (0, 0.5, 1.3), b=0.15)
    ashlar(c, variant, L, 2.6, 11.6, 6, 0.0)
    for s in (-1, 1):
        bx(f"Sandstone_Pilaster{s}", "Sandstone", c, (1.6, 1.0, 13.4), (s * 11.2, 0.5, 6.7), b=0.12)
        bx(f"Gold_PilasterBase{s}", "Gold", c, (2.0, 1.4, 0.5), (s * 11.2, 0.7, 2.6))
        bx(f"Gold_PilasterCap{s}", "Gold", c, (2.0, 1.4, 0.5), (s * 11.2, 0.7, 13.0))
    # cornice: dentils, gold band, top slab
    for i in range(12):
        bx(f"GoldDeep_Dentil{i}", "GoldDeep", c, (1.0, 1.1, 0.7), (-L / 2 + 1.0 + i * 2.0, 0.55, 11.9))
    bx("Gold_CorniceBand", "Gold", c, (L, 1.5, 0.5), (0, 0.75, 12.55))
    bx("SandDark_CorniceTop", "SandDark", c, (L, 1.9, 0.7), (0, 0.95, 13.3), b=0.1)
    merlons(c, variant, (-9, -3, 3, 9), -0.4, 14.0, 4.6, 2.4, 2.6)
    if variant == "A":
        bx("Ink_Slit", "Ink", c, (0.9, 0.2, 3.8), (0, 0.45, 8.0))
        for z in (5.9, 10.1):
            bx(f"Gold_SlitBar{z}", "Gold", c, (1.7, 0.3, 0.3), (0, 0.45, z))
        for s in (-1, 1):
            bx(f"Gold_SlitSide{s}", "Gold", c, (0.28, 0.3, 4.5), (s * 0.82, 0.45, 8.0))
        for s in (-1, 1):  # a slim pair of small slits to the sides
            bx(f"Ink_SlitSmall{s}", "Ink", c, (0.5, 0.2, 2.0), (s * 7.5, 0.45, 8.0))
    else:
        sun(c, (0, 0.34, 8.0), 1.9, Matrix.Rotation(-math.pi / 2, 4, "X"))
        for s in (-1, 1):  # banner hooks
            bx(f"GoldDeep_Hook{s}", "GoldDeep", c, (0.3, 0.9, 0.3), (s * 7.5, 0.6, 11.0))
            torus(f"GoldDeep_HookRing{s}", "GoldDeep", c, 0.35, 0.09, seg=12, mseg=6, loc=(s * 7.5, 1.05, 10.7), rot=(math.pi / 2, 0, 0))

# =====================================================================================================================
c = collection("WallTower")
W, H = 18.0, 21.0
bx("Sandstone_Body", "Sandstone", c, (W, W, H), (0, 0, H / 2))
bx("SandDark_Plinth", "SandDark", c, (W + 2.0, W + 2.0, 2.6), (0, 0, 1.3), b=0.2)
for k in range(4):
    ashlar(c, f"T{k}", W - 2.6, 2.6, 17.6, 8, W / 2, angle=k * math.pi / 2, step=5.5)
    a = k * math.pi / 2
    for z, name in ((6.5, "Low"), (12.0, "Mid")):
        x, y = rot2(0, W / 2 + 0.35, a)
        bx(f"Gold_Band{name}{k}", "Gold", c, (W + 0.7, 0.55, 0.5), (x, y, z), (0, 0, a))
    x, y = rot2(0, W / 2 + 0.3, a)
    bx(f"Ink_Slit{k}", "Ink", c, (1.0, 0.2, 4.6), (x, y, 10.0), (0, 0, a))
    for z in (7.5, 12.5):
        bx(f"Gold_SlitBar{k}_{z}", "Gold", c, (1.8, 0.3, 0.3), (x, y, z), (0, 0, a))
    for s in (-1, 1):
        px, py = rot2(s * 0.92, W / 2 + 0.3, a)
        bx(f"Gold_SlitSide{k}_{s}", "Gold", c, (0.28, 0.3, 5.1), (px, py, 10.0), (0, 0, a))
for sx in (-1, 1):
    for sy in (-1, 1):
        bx(f"Sandstone_Corner{sx}{sy}", "Sandstone", c, (2.4, 2.4, 17.6), (sx * (W / 2 - 0.2), sy * (W / 2 - 0.2), 9.4), b=0.15)
        bx(f"Gold_CornerBase{sx}{sy}", "Gold", c, (2.9, 2.9, 0.5), (sx * (W / 2 - 0.2), sy * (W / 2 - 0.2), 2.8))
        bx(f"Gold_CornerCap{sx}{sy}", "Gold", c, (2.9, 2.9, 0.5), (sx * (W / 2 - 0.2), sy * (W / 2 - 0.2), 18.1))
# machicolated top
bx("SandDark_Mach", "SandDark", c, (W + 2.2, W + 2.2, 1.3), (0, 0, 18.85), b=0.15)
bx("Gold_MachBand", "Gold", c, (W + 2.5, W + 2.5, 0.4), (0, 0, 19.7))
for k in range(4):
    a = k * math.pi / 2
    for i in range(8):
        x, y = rot2(-W / 2 + 1.2 + i * 2.2, W / 2 + 1.15, a)
        bx(f"GoldDeep_Corbel{k}_{i}", "GoldDeep", c, (0.9, 0.9, 1.0), (x, y, 17.6), (0, 0, a))
bx("Sandstone_Deck", "Sandstone", c, (W, W, 0.6), (0, 0, 20.4))
for k in range(4):
    a = k * math.pi / 2
    for i, off in enumerate((-6.2, -2.0, 2.0, 6.2)):
        x, y = rot2(off, W / 2 + 0.6, a)
        bx(f"Sandstone_Mer{k}{i}", "Sandstone", c, (3.0, 2.0, 2.6), (x, y, 20.7 + 1.3), (0, 0, a), 0.12)
        bx(f"Gold_MerCap{k}{i}", "Gold", c, (3.35, 2.35, 0.35), (x, y, 23.5), (0, 0, a))
# spire
sp = lathe("GoldDeep_Spire", "GoldDeep", c, [(0, 20.7), (6.8, 20.7), (6.4, 21.4), (0.0, 33.0)], segments=4, smooth=False)
sp.rotation_euler = (0, 0, math.pi / 4)
lathe("Gold_Finial", "Gold", c, [(0, 32.4), (0.9, 32.4), (0.45, 33.6), (0, 34.6)], segments=8)
lathe("GemRed_Orb", "GemRed", c, [(0, 33.4), (0.6, 33.7), (0, 34.3)], segments=8)

# =====================================================================================================================
c = collection("BossGateFrame")
TX, TW, TH = 18.0, 11.0, 27.0
for s in (-1, 1):
    yc = s * 27.5
    bx(f"Sandstone_Tower{s}", "Sandstone", c, (TX, TW, TH), (0, yc, TH / 2))
    bx(f"SandDark_TowerPlinth{s}", "SandDark", c, (TX + 1.6, TW + 1.6, 2.4), (0, yc, 1.2), b=0.2)
    for fx, ang in ((TX / 2, -math.pi / 2), (-TX / 2, math.pi / 2)):
        # ashlar on the two long faces (facing +X / -X); the face normal is rotated to the world axis
        ashlar(c, f"G{s}{int(fx)}", TW - 1.8, 2.4, 22.0, 9, TX / 2, angle=ang, center=(0, yc), step=5.0)
    ashlar(c, f"G{s}o", TX - 2.6, 2.4, 22.0, 9, TW / 2, angle=0.0 if s > 0 else math.pi, center=(0, yc), step=5.0)
    for fx in (-1, 1):
        for z in (7.0, 14.0, 21.0):
            bx(f"Gold_TowerBand{s}{fx}{z}", "Gold", c, (0.5, TW + 0.7, 0.5), (fx * (TX / 2 + 0.35), yc, z))
        bx(f"Ink_TowerSlit{s}{fx}", "Ink", c, (0.2, 1.0, 5.0), (fx * (TX / 2 + 0.32), yc, 15.0))
        for z in (12.2, 17.8):
            bx(f"Gold_TowerSlitBar{s}{fx}{z}", "Gold", c, (0.3, 1.8, 0.3), (fx * (TX / 2 + 0.34), yc, z))
    # machicolated top, merlons, spire
    bx(f"SandDark_TowerMach{s}", "SandDark", c, (TX + 2.2, TW + 2.2, 1.3), (0, yc, 23.65), b=0.15)
    bx(f"Gold_TowerMachBand{s}", "Gold", c, (TX + 2.5, TW + 2.5, 0.4), (0, yc, 24.5))
    for i in range(7):
        for sd in (-1, 1):
            bx(f"GoldDeep_TowerCorbel{s}{i}{sd}", "GoldDeep", c, (0.9, 0.9, 1.0), (sd * (TX / 2 + 1.15), yc - TW / 2 + 1.2 + i * 1.4, 22.4))
    bx(f"Sandstone_TowerDeck{s}", "Sandstone", c, (TX, TW, 0.6), (0, yc, 25.2))
    for sd in (-1, 1):
        for i, off in enumerate((-3.3, 0.0, 3.3)):
            bx(f"Sandstone_TowerMer{s}{sd}{i}", "Sandstone", c, (2.0, 2.6, 2.6), (sd * (TX / 2 + 0.6), yc + off, 27.2), b=0.12)
            bx(f"Gold_TowerMerCap{s}{sd}{i}", "Gold", c, (2.35, 2.95, 0.35), (sd * (TX / 2 + 0.6), yc + off, 28.67))
    spire = lathe(f"GoldDeep_TowerSpire{s}", "GoldDeep", c, [(0, 25.5), (5.6, 25.5), (5.3, 26.1), (0, 40.0)], segments=4, smooth=False)
    spire.location = (0, yc, 0)
    spire.rotation_euler = (0, 0, math.pi / 4)
    lathe(f"Gold_TowerFinial{s}", "Gold", c, [(0, 39.4), (0.9, 39.4), (0.45, 40.6), (0, 41.8)], segments=8, loc=(0, yc, 0))
    # banner hanging on each long face
    for sd in (-1, 1):
        pts = [(-2.1, 0.0), (0.0, 2.6), (2.1, 0.0), (2.1, 11.0), (-2.1, 11.0)]
        o = slab2d(f"Banner_Cloth{s}{sd}", "Banner", c, pts, -0.16, 0.0)
        o.rotation_euler = (0, 0, sd * math.pi / 2)
        o.location = (sd * (TX / 2 + 0.55), yc, 9.5)
        bx(f"Gold_BannerRod{s}{sd}", "Gold", c, (0.35, 5.0, 0.35), (sd * (TX / 2 + 0.7), yc, 20.8))
        bx(f"Gold_BannerTrim{s}{sd}", "Gold", c, (0.18, 3.6, 0.5), (sd * (TX / 2 + 0.55), yc, 19.9))
# the lintel over the opening
LZ0, LZ1 = 17.0, 27.0
bx("Sandstone_Lintel", "Sandstone", c, (16.0, 44.0, LZ1 - LZ0), (0, 0, (LZ0 + LZ1) / 2))
for fx in (-1, 1):
    ashlar(c, f"L{fx}", 44.0, LZ0 + 0.4, LZ1 - 1.2, 4, 8.0, angle=-fx * math.pi / 2, step=7.0)
bx("Gold_LintelSoffit", "Gold", c, (16.4, 44.2, 0.55), (0, 0, LZ0 + 0.28))
bx("GoldDeep_LintelSoffitLine", "GoldDeep", c, (16.8, 44.4, 0.3), (0, 0, LZ0 + 0.85))
bx("Gold_LintelCornice", "Gold", c, (17.4, 45.0, 0.7), (0, 0, LZ1 - 0.15))
for fx in (-1, 1):
    for i in range(14):
        bx(f"GoldDeep_LintelDentil{fx}{i}", "GoldDeep", c, (0.9, 1.1, 0.7), (fx * 8.2, -20.5 + i * 3.15, LZ1 - 0.9))
bx("Sandstone_LintelDeck", "Sandstone", c, (16.0, 44.0, 0.5), (0, 0, LZ1 + 0.25))
for fx in (-1, 1):
    for i in range(9):
        y = -20.0 + i * 5.0
        bx(f"Sandstone_LintelMer{fx}{i}", "Sandstone", c, (2.0, 3.6, 2.4), (fx * 7.0, y, LZ1 + 1.7), b=0.12)
        bx(f"Gold_LintelMerCap{fx}{i}", "Gold", c, (2.35, 3.95, 0.35), (fx * 7.0, y, LZ1 + 3.07))
    # a great sun with crossed swords either side, on both faces
    sun(c, (fx * 8.05, 0.0, 22.2), 3.2, Matrix.Rotation(fx * math.pi / 2, 4, "Y"), rays=16)


print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith(("Wall", "BossGate"))})

# =====================================================================================================================
c = collection("BossGateLeaf")
LW, LH, LT = 22.0, 17.0, 1.8
for y in (0.8, LW - 0.8):
    bx(f"Iron_Stile{y}", "Iron", c, (LT, 1.6, LH), (0, y, LH / 2), b=0.1)
for z, h, t in ((0.75, 1.5, LT), (LH - 0.75, 1.5, LT), (6.2, 0.9, 1.4), (11.4, 0.9, 1.4)):
    bx(f"Iron_Rail{z}", "Iron", c, (t, LW, h), (0, LW / 2, z), b=0.1)
for z in (2.8, 8.5, 14.2):  # hinge straps
    bx(f"Iron_Strap{z}", "Iron", c, (LT + 0.4, 5.4, 0.8), (0, 2.7, z), b=0.1)
    for y in (1.0, 2.8, 4.6):
        bx(f"Gold_Rivet{z}{y}", "Gold", c, (LT + 0.7, 0.45, 0.45), (0, y, z))
pts = [(-0.55, 1.5), (0.55, 1.5), (0.55, 16.3), (0.0, 18.5), (-0.55, 16.3)]
for i in range(7):
    y = 3.4 + i * 2.55
    o = slab2d(f"GoldDeep_Blade{i}", "GoldDeep", c, pts, -0.3, 0.3)
    o.rotation_euler = (0, 0, math.pi / 2)
    o.location = (0, y, 0)
    bx(f"Gold_Guard{i}", "Gold", c, (0.8, 2.1, 0.38), (0, y, 3.4), b=0.08)
torus("Gold_Knocker", "Gold", c, 1.5, 0.2, seg=24, mseg=8, loc=(0, 19.2, 8.5), rot=(0, math.pi / 2, 0))
lathe("Gold_KnockerBoss", "Gold", c, [(0, 0), (0.9, 0), (0.9, 0.3), (0.5, 0.7), (0, 0.8)], segments=14).location = (0, 19.2, 8.5)
for y in (3.0, 7.0, 11.0, 15.0, 19.0):
    for fx in (-1, 1):
        bx(f"Gold_Stud{fx}{y}", "Gold", c, (0.5, 0.5, 0.5), (fx * (LT / 2 + 0.15), y, 0.75))
        bx(f"Gold_StudTop{fx}{y}", "Gold", c, (0.5, 0.5, 0.5), (fx * (LT / 2 + 0.15), y, LH - 0.75))

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith(("Wall", "BossGate"))})
