# The training stage (the shop's class showroom). Origin = the middle of the arena floor (where the target dummy stands), floor top z 0.
# Pieces:
#   StageArena     sand floor with stone distance rings, an inner wall (radius 86), three tiers of stone seats, and an arcade of arches
#                  round the top with banners hung between; an opening on the +Y side (behind where performers stand, toward the
#                  orb dais side is -Y) is not needed: the arena is closed, people come and go by fading.
#   StageDais      the orb dais (radius 13), origin = ground centre.
#   StageBagFrame  a timber gallows for two sandbags; the bags hang from hooks at (+-3.2, 0, 11.4).
#   StageSandbag   one sandbag; origin = its hook (top), the bag hangs below it (the builder hangs it on a rope: physics).
#   StageRack      a weapon rack with swords, spears and an axe. StageTarget: an archery target on an easel.
#   StagePost      a wooden practice dummy on a post. StageBrazier: an iron fire bowl on a tripod (fire at z 6.4).
#   StageBoard     the score board on two posts, its face (role Ink) toward -Y, 12 x 7.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
V = Vector
R_WALL = 86.0

# =====================================================================================================================
ar = collection("StageArena")
solid(lathe("Sand_Floor", "Sand", ar, [(0, -2), (R_WALL + 1, -2), (R_WALL + 1, 0), (0, 0)], segments=96))
for r, w in ((20, 0.5), (40, 0.5), (60, 0.5), (78, 1.2)):
    torus("Stone_Ring", "Stone", ar, r, w, seg=96, mseg=4, loc=(0, 0, 0.0), scale_minor=(1, 0.12))
# the centre mark: a stone medallion with a gold star
lathe("Stone_Mark", "Stone", ar, [(0, 0), (5.0, 0), (5.0, 0.12), (0, 0.12)], segments=48)
for k in range(8):
    blade("Gold_StarRay", "Gold", ar, (0, 0), k / 8 * math.tau, 0.4, 4.4 if k % 2 == 0 else 2.8, 0.7, 0.02, depth=0.1, y=0.18)
for o in [o for o in ar.objects if o.name.startswith("Gold_StarRay")]:
    o.data.transform(Matrix.Rotation(math.radians(90), 4, "X"))  # lay the rays flat on the floor
# the inner wall: dressed stone with a coping, buttresses every 15 degrees
solid(lathe("Stone_Wall", "Stone", ar, [(R_WALL, 0), (R_WALL + 3, 0), (R_WALL + 3, 12), (R_WALL, 12)], segments=96, smooth=False))
lathe("StoneWarm_Coping", "StoneWarm", ar, [(R_WALL - 0.6, 12), (R_WALL + 3.4, 12), (R_WALL + 3.4, 13.2), (R_WALL - 0.6, 13.2)], segments=96, smooth=False)
lathe("StoneWarm_Skirt", "StoneWarm", ar, [(R_WALL - 0.8, 0), (R_WALL, 0), (R_WALL, 1.8), (R_WALL - 0.8, 1.8)], segments=96, smooth=False)
for k in range(24):
    a = k / 24 * math.tau
    o = box("StoneWarm_Buttress", "StoneWarm", ar, (2.4, 1.6, 12.6), loc=(math.cos(a) * (R_WALL - 0.6), math.sin(a) * (R_WALL - 0.6), 6.3), bevel=0.15)
    o.rotation_euler = (0, 0, a)
# seating: three tiers stepping up and out
for i in range(3):
    r0, r1 = R_WALL + 3 + i * 6, R_WALL + 9 + i * 6
    z = 13.2 + i * 4.5
    solid(lathe(f"Stone_Tier{i}", "Stone", ar, [(r0, 0), (r1, 0), (r1, z + 4.5), (r0, z + 4.5)], segments=72, smooth=False))
    lathe(f"Wood_Bench{i}", "Wood", ar, [(r0 + 0.6, z + 4.5), (r0 + 3.2, z + 4.5), (r0 + 3.2, z + 5.2), (r0 + 0.6, z + 5.2)], segments=72, smooth=False)
# the arcade round the top: piers and round arches, a cornice
R_ARC = R_WALL + 27
TOPZ = 31.0
N = 28
for k in range(N):
    a = k / N * math.tau
    c, s = math.cos(a), math.sin(a)
    o = box("StoneWarm_Pier", "StoneWarm", ar, (3.0, 4.0, 18.0), loc=(c * R_ARC, s * R_ARC, TOPZ + 9.0), bevel=0.2)
    o.rotation_euler = (0, 0, a)
    # the arch between this pier and the next
    a2 = (k + 0.5) / N * math.tau
    span = 2 * math.pi * R_ARC / N - 3.0
    pts = []
    for i in range(13):
        t = i / 12
        ang = math.pi - t * math.pi
        u = math.cos(ang) * span / 2
        z = TOPZ + 13.0 + math.sin(ang) * span / 2 * 0.55
        p = V((math.cos(a2), math.sin(a2), 0)) * R_ARC + V((-math.sin(a2), math.cos(a2), 0)) * u
        pts.append(V((p.x, p.y, z)))
    sweep("StoneWarm_Arch", "StoneWarm", ar, pts, [(-1.2, -0.8), (1.2, -0.8), (1.2, 0.8), (-1.2, 0.8)], smooth=False)
lathe("Stone_Cornice", "Stone", ar, [(R_ARC - 2.2, TOPZ + 18.0), (R_ARC + 2.2, TOPZ + 18.0), (R_ARC + 2.8, TOPZ + 19.4), (R_ARC - 2.8, TOPZ + 19.4)], segments=N * 2, smooth=False)
lathe("StoneWarm_ArcadeFloor", "StoneWarm", ar, [(R_WALL + 21, TOPZ - 0.6), (R_ARC + 3, TOPZ - 0.6), (R_ARC + 3, TOPZ), (R_WALL + 21, TOPZ)], segments=72, smooth=False)
# the outer wall behind the arcade (closes the view)
lathe("Stone_OuterWall", "Stone", ar, [(R_ARC + 3, -2), (R_ARC + 6, -2), (R_ARC + 6, TOPZ + 19.4), (R_ARC + 3, TOPZ + 19.4)], segments=72, smooth=False)
# banners hanging inside the arches, red with a gold border and a crossed-swords device
for k in range(0, N, 2):
    a2 = (k + 0.5) / N * math.tau
    c, s = math.cos(a2), math.sin(a2)
    cen = V((c, s, 0)) * (R_ARC - 1.0) + V((0, 0, TOPZ + 6.5))
    for role, w, h, d in (("Red", 6.0, 11.0, 0.0), ("Gold", 6.6, 0.6, -0.05)):
        o = box(f"{role}_Banner", role, ar, (w, 0.2, h), loc=cen + V((0, 0, (5.5 if role == "Gold" else 0))), rot=(0, 0, a2 + math.pi / 2))
    tip = cen + V((0, 0, -6.4))
    o = lathe("Red_BannerTail", "Red", ar, [(0, 0), (3.0, 0), (0, -1.6)], segments=3, smooth=False, loc=tip)
    o.scale = (1, 0.07, 1)
    o.rotation_euler = (0, 0, a2 + math.pi / 2 + math.radians(90))

# =====================================================================================================================
da = collection("StageDais")
for i, (r, z) in enumerate([(13.0, 0.6), (11.0, 1.2), (9.0, 1.8)]):
    solid(lathe(f"StoneWarm_DaisStep{i}", "StoneWarm", da, [(0, 0), (r, 0), (r, z), (0, z)], segments=48))
    torus(f"Gold_DaisTrim{i}", "Gold", da, r, 0.12, seg=48, mseg=4, loc=(0, 0, z))
for k in range(6):
    a = k / 6 * math.tau
    lathe("Stone_DaisPost", "Stone", da, [(0, 0), (0.6, 0), (0.5, 4.0), (0.8, 4.4), (0, 4.6)], segments=10, loc=(math.cos(a) * 12.0, math.sin(a) * 12.0, 0.6))

# =====================================================================================================================
bf = collection("StageBagFrame")
for sx in (-1, 1):
    for sy in (-1, 1):
        solid(sweep("Wood_Leg", "Wood", bf, [V((sx * 6.0, sy * 2.6, 0)), V((sx * 5.4, 0, 12.0))], [(-0.4, -0.4), (0.4, -0.4), (0.4, 0.4), (-0.4, 0.4)], smooth=False))
sweep("WoodDark_TopBeam", "WoodDark", bf, [V((-6.6, 0, 12.0)), V((6.6, 0, 12.0))], [(-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)], smooth=False)
for sx in (-1, 1):
    sweep("WoodDark_Brace", "WoodDark", bf, [V((sx * 5.9, 0, 6.0)), V((sx * 5.6, 0, 9.0))], circle(0.25, 6))
    torus("Iron_Hook", "Iron", bf, 0.35, 0.1, seg=12, mseg=4, loc=(sx * 3.2, 0, 11.3), rot=(math.radians(90), 0, 0))

sb = collection("StageSandbag")
bag = sculpt("Fabric_Bag", "Fabric", sb, [capsule((0, 0, -2.2), (0, 0, -6.6), 1.9 * 1.4), ("BALL", (0, 0, -1.6), 1.3 * 1.4, None)], resolution=0.15, threshold=0.25)
decimate(bag, 0.5)
for z in (-2.6, -6.2):
    torus("Rope_BagBand", "Rope", sb, 1.75, 0.16, seg=20, mseg=4, loc=(0, 0, z))
sweep("Rope_BagRope", "Rope", sb, [V((0, 0, 0)), V((0, 0, -1.4))], circle(0.12, 5))

# =====================================================================================================================
rk = collection("StageRack")
for sx in (-1, 1):
    solid(box("Wood_RackPost", "Wood", rk, (0.7, 0.7, 7.0), loc=(sx * 5.0, 0, 3.5), bevel=0.08))
    box("WoodDark_RackFoot", "WoodDark", rk, (0.9, 3.0, 0.5), loc=(sx * 5.0, 0, 0.25))
for z in (2.0, 6.2):
    box("WoodDark_RackBar", "WoodDark", rk, (10.6, 0.5, 0.5), loc=(0, 0, z), bevel=0.08)
for k in range(6):
    x = -3.9 + k * 1.55
    if k % 3 == 2:
        sweep("Wood_Spear", "Wood", rk, [V((x, -0.4, 0.4)), V((x, -0.4, 10.4))], circle(0.12, 6))
        slab2d("Blade_SpearHead", "Blade", rk, [(x - 0.3, 10.3), (x + 0.3, 10.3), (x, 11.8)], -0.45, -0.35)
    else:
        slab2d("Blade_Sword", "Blade", rk, [(x - 0.2, 0.6), (x + 0.2, 0.6), (x + 0.2, 6.0), (x, 6.6), (x - 0.2, 6.0)], -0.45, -0.38)
        box("Gold_Guard", "Gold", rk, (1.1, 0.3, 0.2), loc=(x, -0.42, 6.75))
        sweep("Sash_Grip", "Sash", rk, [V((x, -0.42, 6.85)), V((x, -0.42, 7.9))], circle(0.12, 6))
sweep("Wood_AxeHaft", "Wood", rk, [V((4.2, -0.5, 0.4)), V((4.2, -0.5, 6.0))], circle(0.14, 6))
slab2d("Blade_AxeBit", "Blade", rk, [(4.3, 4.6), (5.6, 4.0), (5.8, 6.4), (4.3, 5.8)], -0.55, -0.45)

tg = collection("StageTarget")
for sx in (-1, 1):
    sweep("Wood_EaselLeg", "Wood", tg, [V((sx * 1.8, 0.6, 0)), V((sx * 0.6, -0.2, 7.0))], circle(0.2, 6))
sweep("Wood_EaselBack", "Wood", tg, [V((0, 3.0, 0)), V((0, 0.2, 6.6))], circle(0.2, 6))
for i, (r, role) in enumerate([(2.6, "White"), (2.1, "Red"), (1.6, "White"), (1.1, "Red"), (0.55, "Gold")]):
    o = lathe(f"{role}_Ring{i}", role, tg, [(0, 0), (r, 0), (r, 0.4 + i * 0.03), (0, 0.4 + i * 0.03)], segments=28)
    o.rotation_euler = (math.radians(90), 0, 0)
    o.location = (0, -0.3 - i * 0.01, 4.6)
for k in range(3):
    sweep("Wood_Arrow", "Wood", tg, [V((-0.5 + k * 0.6, -0.4, 4.4 + k * 0.5)), V((-0.7 + k * 0.6, -3.6, 4.9 + k * 0.4))], circle(0.06, 4))

ps = collection("StagePost")
solid(lathe("Wood_PostBase", "Wood", ps, [(0, 0), (1.8, 0), (1.8, 0.6), (0, 0.6)], segments=12))
lathe("Wood_Post", "Wood", ps, [(0.45, 0.6), (0.45, 3.6), (0, 3.6)], segments=10)
d = sculpt("Fabric_Dummy", "Fabric", ps, [("ELLIPSOID", (0, 0, 5.2), 1.6 * 1.4, (1.0, 0.7, 1.2)), ("BALL", (0, 0, 7.5), 0.9 * 1.4, None)], resolution=0.15, threshold=0.25)
decimate(d, 0.5)
for sx in (-1, 1):
    sweep("Wood_Arm", "Wood", ps, [V((sx * 1.2, -0.2, 5.6)), V((sx * 3.2, -1.2, 5.9))], circle(0.25, 6))
torus("Rope_Waist", "Rope", ps, 1.5, 0.14, seg=16, mseg=4, loc=(0, 0, 4.4))

br = collection("StageBrazier")
for k in range(3):
    a = k / 3 * math.tau
    sweep("Iron_Leg", "Iron", br, [V((math.cos(a) * 1.8, math.sin(a) * 1.8, 0)), V((math.cos(a) * 0.9, math.sin(a) * 0.9, 4.6))], circle(0.15, 6))
lathe("Iron_Bowl", "Iron", br, [(0, 4.4), (0.8, 4.4), (1.9, 5.4), (2.2, 6.2), (1.9, 6.2), (0.8, 5.0), (0, 5.0)], segments=16)
for k in range(5):
    rock(f"WoodDark_Log{k}", "WoodDark", br, (0.5, 0.5, 2.4), loc=(math.cos(k) * 0.6, math.sin(k) * 0.6, 5.8), seed=200 + k, detail=1).rotation_euler = (1.2, 0, k * 1.2)

bd = collection("StageBoard")
for sx in (-1, 1):
    solid(lathe("WoodDark_BoardPost", "WoodDark", bd, [(0.5, 0), (0.45, 12.0), (0.7, 12.4), (0, 12.6)], segments=8, loc=(sx * 6.8, 0.4, 0)))
box("Wood_BoardFrame", "Wood", bd, (13.4, 0.8, 8.0), loc=(0, 0.3, 8.0), bevel=0.15)
box("Ink_BoardFace", "Ink", bd, (12.0, 0.3, 6.8), loc=(0, -0.2, 8.0))
box("Red_BoardRoof", "Red", bd, (14.4, 2.4, 0.4), loc=(0, 0.1, 12.4), rot=(math.radians(8), 0, 0), bevel=0.1)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith("Stage")})
