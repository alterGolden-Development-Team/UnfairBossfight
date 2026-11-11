# The boss arena's floor, replacing the old ChronicleCourt (clock dial, buttresses, banners, plinths, fallen columns) and FloorPattern lines.
# Origin = the arena's centre at floor level (Roblox y = the top of Grassland). Blender (x, y) = Roblox (-x, z); the design is mirror
# symmetric, so nothing flips. Everything sits within 0.2 of the floor and is NOT solid: players still walk on Grassland.
#   ArenaTiles      the paved court: ~2,500 worn limestone flagstones (three tones) on dark grout, a gold border row, a clear disc for the medallion
#   ArenaMedallion  the central sundial: a black-marble disc, gold rings, a twelve-ray sunburst, hour plaques, a golden star at the heart,
#                   plus the gold lanes that run out to the two spawn diamonds and four edge chevrons
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"FloorA": ((0.50, 0.44, 0.33), 0.0, 0.95), "FloorB": ((0.42, 0.36, 0.26), 0.0, 0.95), "FloorC": ((0.33, 0.28, 0.20), 0.0, 0.95),
             "FloorGrout": ((0.06, 0.05, 0.04), 0.0, 1.0)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau
HALF_X, HALF_Z = 300.0, 218.0          # the paved rectangle (the arena floor is 620 x 460)
PITCH, GAP = 10.0, 0.36
MEDALLION_R = 99.0
rnd = random.Random(7)


def flat(c, name, role, pts, z0, z1):
    return slab2d(name, role, c, pts, z0, z1, plane="xy")


def ring_pts(r, n=64):
    return [(math.cos(i / n * TAU) * r, math.sin(i / n * TAU) * r) for i in range(n)]


def annulus(c, name, role, r0, r1, z0, z1, n=96):
    """A flat ring: a lathe loop (outer top, outer bottom, inner bottom, inner top)."""
    return lathe(name, role, c, [(r1, z0), (r1, z1), (r0, z1), (r0, z0)], segments=n)


def disc(c, name, role, r, z0, z1, n=96):
    return lathe(name, role, c, [(0, z0), (r, z0), (r, z1), (0, z1)], segments=n)


# =====================================================================================================================
c = collection("ArenaTiles")
box("FloorGrout_Base", "FloorGrout", c, (HALF_X * 2 + 2, HALF_Z * 2 + 2, 0.03), loc=(0, 0, 0.015))
bm = {"FloorA": bmesh.new(), "FloorB": bmesh.new(), "FloorC": bmesh.new(), "GoldDeep": bmesh.new()}
cols_n = int(HALF_X * 2 / PITCH)
rows_n = int(HALF_Z * 2 / PITCH)


def tile(b, cx, cy, size, top, inset=0.2):
    h = size / 2
    bot = [b.verts.new((cx + sx * h, cy + sy * h, 0.02)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    t = [b.verts.new((cx + sx * (h - inset), cy + sy * (h - inset), top)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    b.faces.new(t)
    for i in range(4):
        j = (i + 1) % 4
        b.faces.new((bot[i], bot[j], t[j], t[i]))


for i in range(cols_n):
    for j in range(rows_n):
        cx = -cols_n * PITCH / 2 + PITCH * (i + 0.5)  # centred on the arena (43 rows of 10 do not fill 436)
        cy = -rows_n * PITCH / 2 + PITCH * (j + 0.5)
        # only skip tiles that lie wholly under the medallion; the ones it clips stay (the disc is higher), so no grout shows in a ragged ring
        if math.hypot(abs(cx) + PITCH / 2, abs(cy) + PITCH / 2) < MEDALLION_R - 0.5:
            continue
        border = i == 0 or j == 0 or i == cols_n - 1 or j == rows_n - 1
        pick = rnd.random()
        role = "GoldDeep" if border else ("FloorC" if pick < 0.14 else ("FloorB" if pick < 0.56 else "FloorA"))
        tile(bm[role], cx, cy, PITCH - GAP, 0.05 + rnd.uniform(-0.012, 0.012), inset=0.16 if not border else 0.1)
for role, b in bm.items():
    bmesh.ops.recalc_face_normals(b, faces=b.faces)
    obj_from_bm(b, "Tiles_" + role, role, c, smooth=False)

# =====================================================================================================================
c = collection("ArenaMedallion")
T = 0.05  # the tile top; inlays rise from here
disc(c, "MarbleDark_Disc", "MarbleDark", MEDALLION_R, 0.0, T + 0.1)
for r0, r1, role in ((95.0, 97.8, "Gold"), (91.6, 92.4, "GoldDeep"), (88.0, 90.4, "Gold"), (85.2, 86.0, "GoldDeep"), (73.0, 75.0, "Gold"), (47.0, 48.6, "Gold"), (23.0, 25.0, "Gold"), (60.0, 60.7, "GoldDeep")):
    annulus(c, f"{role}_Ring", role, r0, r1, T + 0.1, T + 0.2)
# twelve rays: long ones on the hours, short ones between
for k in range(12):
    a = k / 12 * TAU
    long = k % 3 == 0
    r0, r1 = 26.0, (71.0 if long else 56.0)
    w0, w1 = (3.6 if long else 2.2), 0.0
    d = V((math.cos(a), math.sin(a), 0))
    s = V((-math.sin(a), math.cos(a), 0))
    pts = [tuple((d * r0 + s * w0)[:2]), tuple((d * r1)[:2]), tuple((d * r0 - s * w0)[:2])]
    flat(c, "GoldPale_Ray" if long else "Gold_Ray", "GoldPale" if long else "Gold", pts, T + 0.1, T + 0.19)
    if long:
        pts2 = [tuple((d * (r0 + 6) + s * 1.1)[:2]), tuple((d * (r1 - 6))[:2]), tuple((d * (r0 + 6) - s * 1.1)[:2])]
        flat(c, "GoldDeep_RayCore", "GoldDeep", pts2, T + 0.19, T + 0.24)
# hour plaques between the two outer rings
for k in range(12):
    a = k / 12 * TAU
    d = V((math.cos(a), math.sin(a), 0))
    s = V((-math.sin(a), math.cos(a), 0))
    cen = d * 80.0
    L, W = (4.6 if k % 3 == 0 else 3.2), (2.0 if k % 3 == 0 else 1.3)
    pts = [tuple((cen + d * L)[:2]), tuple((cen + s * W)[:2]), tuple((cen - d * L)[:2]), tuple((cen - s * W)[:2])]
    flat(c, "GoldPale_Plaque", "GoldPale", pts, T + 0.1, T + 0.2)
    flat(c, "Gem_PlaqueHeart", "GemRed", [tuple((cen + d * L * 0.45)[:2]), tuple((cen + s * W * 0.4)[:2]), tuple((cen - d * L * 0.45)[:2]), tuple((cen - s * W * 0.4)[:2])], T + 0.2, T + 0.27) if k % 3 == 0 else None
# small tick marks on the outer band
for k in range(60):
    a = k / 60 * TAU
    d = V((math.cos(a), math.sin(a), 0))
    s = V((-math.sin(a), math.cos(a), 0))
    L = 1.6 if k % 5 == 0 else 0.9
    cen = d * 87.0
    flat(c, "GoldDeep_Tick", "GoldDeep", [tuple((cen + d * L + s * 0.25)[:2]), tuple((cen - d * L + s * 0.25)[:2]), tuple((cen - d * L - s * 0.25)[:2]), tuple((cen + d * L - s * 0.25)[:2])], T + 0.1, T + 0.16)
# the heart: a 24-point golden star on a gold disc
disc(c, "Gold_HeartDisc", "Gold", 22.0, T + 0.1, T + 0.16)
star = []
for i in range(48):
    a = i / 48 * TAU
    r = 19.5 if i % 2 == 0 else 9.0
    star.append((math.cos(a) * r, math.sin(a) * r))
flat(c, "GoldPale_Star", "GoldPale", star, T + 0.16, T + 0.26)
disc(c, "Gold_StarCore", "Gold", 6.5, T + 0.26, T + 0.4, n=32)
disc(c, "Gem_StarGem", "GemRed", 3.0, T + 0.4, T + 0.62, n=24)
annulus(c, "GoldDeep_StarRing", "GoldDeep", 7.0, 8.0, T + 0.26, T + 0.34, n=48)

# lanes from the medallion out along the long axis to the spawn diamonds (66 wide, centred 210 out), with dashes
for sx in (-1, 1):
    x0, x1 = sx * (MEDALLION_R + 2), sx * 176.0
    lo, hi = min(x0, x1), max(x0, x1)
    flat(c, "GoldDeep_Lane", "GoldDeep", [(lo, -1.1), (hi, -1.1), (hi, 1.1), (lo, 1.1)], T, T + 0.09)
    n = int((hi - lo) / 10.0)
    for k in range(n):
        xc = lo + 5.0 + k * 10.0
        flat(c, "Gold_LaneDash", "Gold", [(xc - 2.6, -0.5), (xc + 2.6, -0.5), (xc + 2.6, 0.5), (xc - 2.6, 0.5)], T + 0.09, T + 0.14)
# chevrons at the four edge midpoints pointing at the centre
for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1)):
    dist = (HALF_X if ax else HALF_Z) - 14.0
    d = V((ax, ay, 0))
    s = V((-ay, ax, 0))
    base = d * dist
    for off in (0.0, 5.0):
        tip = base - d * (6 + off)
        pts = [tuple((tip + d * 0 + s * 0)[:2]), tuple((base - d * off + s * 8)[:2]), tuple((base - d * off + s * 5.5 + d * 2)[:2]), tuple((tip + d * 3)[:2]), tuple((base - d * off - s * 5.5 + d * 2)[:2]), tuple((base - d * off - s * 8)[:2])]
        flat(c, "Gold_Chevron", "Gold", pts, T, T + 0.1)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name in ("ArenaTiles", "ArenaMedallion")})
