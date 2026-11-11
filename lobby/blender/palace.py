# alterGolden's palace (the Golden Encounter hall). Pieces:
#   PalaceHall        the shell: floor and inlays, walls, pilasters, niches, vaulted coffered ceiling, great door end, exit frame.
#                     Origin = floor centre. Blender -Y is the great-door end (Roblox -Z), +Y the entry end.
#   PalaceGate        a party portal's frame (x4). Origin = ground centre of the opening plane, front -Y.
#   PalaceChandelier  (x3) Origin = the ceiling hook at the top.
#   PalaceUrn         gold urn on a pedestal (x8), the builder puts fire in the bowl. Origin = ground centre.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())

W, L, H = 96, 240, 70
HW, HL = W / 2, L / 2
SPRING = 52.0  # where the vault springs from the walls
RISE = H - SPRING


def vault_z(x):
    t = max(0.0, 1 - (x / HW) ** 2)
    return SPRING + RISE * math.sqrt(t)


def fluted_column(col, name, role, center, radius, z0, z1, flutes=10):
    seg = flutes * 4
    bm = bmesh.new()
    rings = []
    levels = 8
    for k in range(levels + 1):
        z = z0 + (z1 - z0) * k / levels
        ring = []
        for i in range(seg):
            a = i / seg * math.tau
            r = radius * (1 - 0.1 * max(0.0, math.cos(a * flutes)) ** 2)
            ring.append(bm.verts.new((center[0] + math.cos(a) * r, center[1] + math.sin(a) * r, z)))
        rings.append(ring)
    for k in range(levels):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, role, col)


def flat_ring(col, name, role, r_in, r_out, loc, thick=0.08, seg=64):
    mid = (r_in + r_out) / 2
    half = (r_out - r_in) / 2
    return torus(col=col, name=name, role=role, major=mid, minor=half, seg=seg, mseg=4, loc=loc, scale_minor=(1.0, thick / half))


def ray_blade(col, name, role, center, angle, r0, r1, w0, w1, axis="xz", depth=0.3, normal_offset=0.0):
    """A flat tapered blade from radius r0 to r1 at `angle`, lying in the given plane."""
    bm = bmesh.new()
    if axis == "xz":  # upright fan on a wall facing -Y
        d = Vector((math.cos(angle), 0, math.sin(angle)))
        s = Vector((-math.sin(angle), 0, math.cos(angle)))
        n = Vector((0, -1, 0))
    else:  # flat on the floor
        d = Vector((math.cos(angle), math.sin(angle), 0))
        s = Vector((-math.sin(angle), math.cos(angle), 0))
        n = Vector((0, 0, 1))
    c = Vector(center) + n * normal_offset
    a, b = c + d * r0, c + d * r1
    quad = [a + s * w0, a - s * w0, b - s * w1, b + s * w1]
    top = [bm.verts.new(p + n * depth) for p in quad]
    bot = [bm.verts.new(p) for p in quad]
    bm.faces.new(top)
    bm.faces.new(list(reversed(bot)))
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((bot[i], bot[j], top[j], top[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, role, col, smooth=False)


def arch_path(cx, y, z0, half_w, spring, n=16):
    """An upright round-headed arch outline (in the XZ plane at depth y): up the left side, over, down the right."""
    pts = [Vector((cx - half_w, y, z0)), Vector((cx - half_w, y, spring))]
    for i in range(1, n):
        a = math.pi - i / n * math.pi
        pts.append(Vector((cx + math.cos(a) * half_w, y, spring + math.sin(a) * half_w)))
    pts += [Vector((cx + half_w, y, spring)), Vector((cx + half_w, y, z0))]
    return pts


# =====================================================================================================================
hall = collection("PalaceHall")
C = hall

# --- floor: black marble, gold border, two runners, three sunburst medallions and diamonds down the middle
solid(box("MarbleDark_Floor", "MarbleDark", C, (W, L, 2), loc=(0, 0, -1)))
for x in (-13, 13):
    box("Gold_Runner", "Gold", C, (0.9, L - 24, 0.1), loc=(x, 0, 0.05))
for sx in (-1, 1):
    box("Gold_Border", "Gold", C, (0.7, L - 8, 0.1), loc=(sx * (HW - 4), 0, 0.05))
for sy in (-1, 1):
    box("Gold_BorderEnd", "Gold", C, (W - 8, 0.7, 0.1), loc=(0, sy * (HL - 4), 0.05))
for my in (-60, 0, 60):
    flat_ring(C, "Gold_MedalOuter", "Gold", 10.4, 11.0, (0, my, 0.0), thick=0.1)
    flat_ring(C, "GoldDeep_MedalInner", "GoldDeep", 6.6, 7.2, (0, my, 0.0), thick=0.1)
    lathe("Gold_MedalHub", "Gold", C, [(0, 0), (2.4, 0), (2.4, 0.12), (0, 0.12)], segments=24, loc=(0, my, 0))
    for k in range(24):
        a = k / 24 * math.tau
        long = k % 2 == 0
        ray_blade(C, "Gold_MedalRay", "Gold" if long else "GoldDeep", (0, my, 0.0), a, 2.6, 10.2 if long else 7.0,
                  0.55 if long else 0.4, 0.05, axis="xy", depth=0.1)
for dy in range(-100, 101, 20):
    if dy in (-60, 0, 60):
        continue
    box("Gold_Diamond", "Gold", C, (4.4, 4.4, 0.1), loc=(0, dy, 0.05), rot=(0, 0, math.radians(45)))
    box("MarbleDark_DiamondIn", "MarbleDark", C, (2.8, 2.8, 0.12), loc=(0, dy, 0.06), rot=(0, 0, math.radians(45)))
    box("GoldDeep_Cross", "GoldDeep", C, (24, 0.4, 0.08), loc=(0, dy, 0.04))

# --- walls: black marble with a gold dado rail, a frieze band and a cornice where the vault springs
for sx in (-1, 1):
    solid(box("MarbleDark_Wall", "MarbleDark", C, (2, L + 4, SPRING + 2), loc=(sx * (HW + 1), 0, (SPRING + 2) / 2)))
    box("Gold_Dado", "Gold", C, (0.8, L, 0.6), loc=(sx * (HW - 0.3), 0, 4.0), bevel=0.15)
    box("GoldDeep_Skirting", "GoldDeep", C, (0.6, L, 1.2), loc=(sx * (HW - 0.2), 0, 0.6))
    box("GoldDeep_Frieze", "GoldDeep", C, (0.6, L, 3.0), loc=(sx * (HW - 0.2), 0, SPRING - 5))
    box("Gold_Cornice", "Gold", C, (2.4, L, 1.2), loc=(sx * (HW - 1.0), 0, SPRING - 2.6), bevel=0.3)
    box("Gold_Cornice2", "Gold", C, (3.4, L, 1.0), loc=(sx * (HW - 1.5), 0, SPRING - 0.5), bevel=0.3)
    # frieze: a run of small gold rosettes
    for y in range(-114, 115, 6):
        lathe("Gold_Rosette", "Gold", C, [(0, 0), (0.9, 0), (0.7, 0.35), (0, 0.5)], segments=10, loc=(sx * (HW - 0.5), y, SPRING - 5)).rotation_euler = (0, sx * -math.radians(90), 0)

# --- pilasters (half-columns) between the bays, each with a torch bracket
PIL = list(range(-105, 106, 30))
for sx in (-1, 1):
    x = sx * (HW - 0.6)
    for y in PIL:
        solid(box("MarbleDark_PilBase", "MarbleDark", C, (5, 7, 3), loc=(sx * (HW - 2.5), y, 1.5), bevel=0.2))
        box("Gold_PilBaseTrim", "Gold", C, (5.4, 7.4, 0.5), loc=(sx * (HW - 2.5), y, 3.1), bevel=0.15)
        fluted_column(C, "Gold_Pilaster", "Gold", (x, y), 2.7, 3.3, SPRING - 6.5)
        lathe("GoldDeep_PilCap", "GoldDeep", C, [(0, 0), (2.9, 0), (3.4, 0.6), (3.9, 1.6), (0, 1.6)], segments=24, loc=(x, y, SPRING - 6.5))
        box("Gold_PilAbacus", "Gold", C, (5.6, 8.2, 0.9), loc=(sx * (HW - 2.6), y, SPRING - 4.5), bevel=0.15)
        # torch bracket: an arm out from the column holding a gold cup at 28 high (the builder adds the flame and light)
        bx = sx * (HW - 4.6)
        sweep("Gold_TorchArm", "Gold", C, [Vector((x, y, 25.0)), Vector((sx * (HW - 3.6), y, 25.3)), Vector((bx, y, 26.6)), Vector((bx, y, 27.4))], circle(0.25, 6))
        lathe("Gold_TorchCup", "Gold", C, [(0, 0), (0.4, 0), (0.5, 0.4), (1.1, 1.2), (1.2, 1.6), (0, 1.4)], segments=14, loc=(bx, y, 27.2))

# --- arched niches in every bay: a recessed dark panel, a gold arch moulding, an art-deco fan in the head
BAYS = [y + 15 for y in PIL[:-1]]
for sx in (-1, 1):
    for y in BAYS:
        hw = 9.0
        spring = 30.0
        xw = sx * (HW - 0.15)
        # recess panel (the arch shape as a slab against the wall)
        outline = [(p.x, p.z) for p in arch_path(0, 0, 5.0, hw - 0.6, spring, n=20)]
        bm = bmesh.new()
        pts = [Vector((xw - sx * 0.1, y + (-u if sx > 0 else u), v)) for u, v in outline]
        a = [bm.verts.new(p) for p in pts]
        b = [bm.verts.new(p + Vector((-sx * 0.25, 0, 0))) for p in pts]
        from mathutils.geometry import tessellate_polygon
        for i0, i1, i2 in tessellate_polygon([[Vector((u, v, 0)) for u, v in outline]]):
            bm.faces.new((b[i0], b[i1], b[i2]))
            bm.faces.new((a[i2], a[i1], a[i0]))
        n = len(pts)
        for i in range(n - 1):
            bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
        bm.faces.new((a[-1], a[0], b[0], b[-1]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        obj_from_bm(bm, "Ink_Niche", "Ink", C, smooth=False)
        # arch moulding
        path = [Vector((xw - sx * 0.6, y + p.x, p.z)) for p in arch_path(0, 0, 4.4, hw, spring, n=24)]
        sweep("Gold_NicheArch", "Gold", C, path, [(-0.7, -0.6), (0.7, -0.6), (0.7, 0.6), (-0.7, 0.6)])
        # keystone
        box("GoldDeep_Keystone", "GoldDeep", C, (1.4, 2.4, 3.2), loc=(sx * (HW - 1.0), y, spring + hw + 0.4), bevel=0.2)
        # fan in the arch head: rays from the springing centre
        for k in range(11):
            ang = math.radians(10 + k * 16)
            rb = ray_blade(C, "GoldDeep_Fan", "GoldDeep" if k % 2 else "Gold", (0, 0, 0), ang, 1.6, hw - 1.6 if k % 2 == 0 else hw - 3.2, 0.5, 0.18, axis="xz", depth=0.25)
            # place it on the wall: the fan is drawn in XZ facing -Y; turn it to face into the hall
            # the fan is drawn facing -Y; turn it to face into the hall (+X on the left wall, -X on the right)
            rb.rotation_euler = (0, 0, math.radians(90) if sx < 0 else -math.radians(90))
            rb.location = (sx * (HW - 0.45), y, spring)
        lathe("Gold_FanHub", "Gold", C, [(0, 0), (1.8, 0), (1.8, 0.4), (0, 0.6)], segments=16, loc=(sx * (HW - 0.4), y, spring)).rotation_euler = (0, sx * -math.radians(90), 0)

# --- the vault: an elliptical barrel, coffered by gold ribs, a rosette in each coffer
VX = 32
VY = 24
bm = bmesh.new()
grid = []
for j in range(VY + 1):
    y = -HL - 2 + (L + 4) * j / VY
    row = []
    for i in range(VX + 1):
        x = -HW - 2 + (W + 4) * i / VX
        row.append(bm.verts.new((x, y, vault_z(max(-HW, min(HW, x))) + 0.3)))
    grid.append(row)
for j in range(VY):
    for i in range(VX):
        bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
vault = obj_from_bm(bm, "Ink_Vault", "Ink", C)
for f in vault.data.polygons:
    f.use_smooth = True
# the vault's skin faces down into the hall: flip so normals point inward/down
vault.data.flip_normals()
sol = vault.modifiers.new("Solid", "SOLIDIFY")
sol.thickness = 1.0
RIB_Y = list(range(-108, 109, 12))
for y in RIB_Y:
    path = [Vector((x, y, vault_z(x) - 0.2)) for x in [(-HW + 0.5) + (W - 1) * i / 36 for i in range(37)]]
    sweep("Gold_Rib", "Gold", C, path, [(-0.6, -0.7), (0.6, -0.7), (0.6, 0.3), (-0.6, 0.3)])
RIB_X = [-36, -24, -12, 0, 12, 24, 36]
for x in RIB_X:
    z = vault_z(x) - 0.2
    sweep("GoldDeep_RibLong", "GoldDeep", C, [Vector((x, -HL + 2, z)), Vector((x, HL - 2, z))], [(-0.45, -0.55), (0.45, -0.55), (0.45, 0.25), (-0.45, 0.25)])
for y in [(a + b) / 2 for a, b in zip(RIB_Y, RIB_Y[1:])]:
    for x in [(a + b) / 2 for a, b in zip(RIB_X, RIB_X[1:])]:
        z = vault_z(x)
        lathe("Gold_Coffer", "Gold", C, [(0, 0), (1.4, 0), (1.0, -0.5), (0.4, -0.9), (0, -1.0)], segments=10, loc=(x, y, z - 0.2), smooth=False)
# lunette walls closing the vault at both ends
for sy in (-1, 1):
    outline = [(-HW - 2, SPRING - 1)] + [(x, vault_z(x) + 1.5) for x in [(-HW) + W * i / 24 for i in range(25)]] + [(HW + 2, SPRING - 1)]
    bm = bmesh.new()
    vs = [bm.verts.new((u, sy * (HL + 1), v)) for u, v in outline]
    vs2 = [bm.verts.new((u, sy * (HL + 1) + sy * 2, v)) for u, v in outline]
    from mathutils.geometry import tessellate_polygon
    for i0, i1, i2 in tessellate_polygon([[Vector((u, v, 0)) for u, v in outline]]):
        bm.faces.new((vs[i0], vs[i1], vs[i2]))
        bm.faces.new((vs2[i2], vs2[i1], vs2[i0]))
    for i in range(len(vs)):
        j = (i + 1) % len(vs)
        bm.faces.new((vs[i], vs[j], vs2[j], vs2[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj_from_bm(bm, "MarbleDark_Lunette", "MarbleDark", C, smooth=False)

# --- the entry wall, with a round gold frame for the way back (exit at height 11, radius 11.5)
solid(box("MarbleDark_EntryWall", "MarbleDark", C, (W + 4, 2, SPRING), loc=(0, HL + 1, SPRING / 2)))
torus("Gold_ExitFrame", "Gold", C, 12.6, 1.1, seg=64, mseg=10, loc=(0, HL - 0.6, 11), rot=(math.radians(90), 0, 0), scale_minor=(1, 0.8))
torus("GoldDeep_ExitFrame2", "GoldDeep", C, 14.2, 0.5, seg=64, mseg=8, loc=(0, HL - 0.3, 11), rot=(math.radians(90), 0, 0))
for k in range(13):
    ang = math.radians(15 * k)
    rb = ray_blade(C, "Gold_ExitRay", "Gold" if k % 2 == 0 else "GoldDeep", (0, HL - 0.2, 11), ang, 15.0, 19.5 if k % 2 == 0 else 17.5, 0.7, 0.1, axis="xz", depth=0.3)
    rb.rotation_euler = (0, 0, math.pi)
    rb.location = (0, 2 * (HL - 0.2), 0)

# --- the great door end: stairs, a stepped art-deco portal, door leaves, flanking towers and organ pipes
DZ = -HL + 8  # stairs centre (Roblox z -112)
solid(box("MarbleDark_BackWall", "MarbleDark", C, (W + 4, 2, SPRING), loc=(0, -HL - 1, SPRING / 2)))
for i in range(6):
    w, d, top = 50 - i * 4, 22 - i * 3, 1.5 * (i + 1)
    cy = DZ + 8 - i * 1.5 - 8
    solid(box("MarbleDark_Stair", "MarbleDark", C, (w, d, 1.5), loc=(0, DZ - i * 1.5 + 0.0, top - 0.75)))
    box("Gold_StairNose", "Gold", C, (w + 0.2, 0.4, 0.3), loc=(0, DZ - i * 1.5 + d / 2, top - 0.1))
BASE = 9.0
DOOR_Y = -HL + 0.2
# stepped frame: three receding layers, each a rectangle with a stepped (ziggurat) head
for k, (hw, top, depth, role) in enumerate([(23, 46, 3.0, "GoldDeep"), (20.5, 43.5, 2.2, "Gold"), (18.5, 41, 1.4, "GoldDeep")]):
    yy = DOOR_Y + depth / 2 + k * 0.6
    for sx in (-1, 1):
        solid(box(f"{role}_Jamb", role, C, (2.6, depth, top - BASE), loc=(sx * (hw - 1.3), yy, BASE + (top - BASE) / 2), bevel=0.2))
    box(f"{role}_Head", role, C, (hw * 2, depth, 2.6), loc=(0, yy, top - 1.3), bevel=0.2)
    box(f"{role}_Step1", role, C, (hw * 1.4, depth, 2.4), loc=(0, yy, top + 1.2), bevel=0.2)
    box(f"{role}_Step2", role, C, (hw * 0.8, depth, 2.4), loc=(0, yy, top + 3.6), bevel=0.2)
# door leaves with panels and the king's sun
for sx in (-1, 1):
    solid(box("Gold_Leaf", "Gold", C, (17.0, 1.6, 31.5), loc=(sx * 8.6, DOOR_Y + 4.0, BASE + 15.75), bevel=0.15))
    for row in range(3):
        box("GoldDeep_Panel", "GoldDeep", C, (12.0, 0.5, 7.4), loc=(sx * 8.6, DOOR_Y + 4.95, BASE + 4.5 + row * 9.4), bevel=0.25)
        box("Gold_PanelIn", "Gold", C, (9.6, 0.5, 5.2), loc=(sx * 8.6, DOOR_Y + 5.15, BASE + 4.5 + row * 9.4), bevel=0.25)
    lathe("GoldPale_Knocker", "GoldPale", C, [(0, 0), (1.2, 0), (1.2, 0.4), (0, 0.5)], segments=16, loc=(sx * 2.4, DOOR_Y + 4.8, BASE + 16)).rotation_euler = (math.radians(90), 0, 0)
    torus("GoldPale_KnockRing", "GoldPale", C, 1.4, 0.22, seg=20, mseg=6, loc=(sx * 2.4, DOOR_Y + 5.3, BASE + 14.6), rot=(math.radians(90), 0, 0))
box("Ink_DoorSeam", "Ink", C, (0.4, 1.8, 31.5), loc=(0, DOOR_Y + 4.0, BASE + 15.75))
# the sun over the door: a half disc of rays above the head, a crown in the middle
SUN = Vector((0, DOOR_Y + 3.3, 49.6))
lathe("Gold_SunDisc", "Gold", C, [(0, 0), (4.2, 0), (4.2, 0.8), (3.6, 1.2), (0, 1.4)], segments=32, loc=SUN).rotation_euler = (math.radians(90), 0, 0)
for k in range(15):
    ang = math.radians(k * (180 / 14))
    rb = ray_blade(C, "Gold_SunRay", "Gold" if k % 2 == 0 else "GoldPale", (0, 0, 0), ang, 4.6, 14.0 if k % 2 == 0 else 10.5, 1.0, 0.1, axis="xz", depth=0.5)
    rb.location = SUN + Vector((0, 0.8, 0))
# flanking stepped towers with gold fins, and organ pipes in the corners
for sx in (-1, 1):
    # tower body in tiers that step back as they rise
    tiers = [(16, 9, 0, 30), (13, 8, 30, 44), (10, 7, 44, 54), (7, 6, 54, 62)]
    for i, (w, d, z0, z1) in enumerate(tiers):
        role = "GoldDeep" if i % 2 == 0 else "Gold"
        o = box(f"{role}_Tier", role, C, (w, d, z1 - z0), loc=(sx * 33, -HL + d / 2, (z0 + z1) / 2), bevel=0.25)
        if i == 0:
            solid(o)
        # vertical fins down each tier's face
        for f in range(-2, 3):
            box("Gold_Fin", "Gold", C, (0.5, 0.8, (z1 - z0) - 1.0), loc=(sx * 33 + f * (w / 6), -HL + d + 0.3, (z0 + z1) / 2), bevel=0.1)
    lathe("Gold_TowerSpire", "Gold", C, [(0, 0), (2.6, 0), (2.0, 2), (0.6, 6), (0, 9)], segments=12, loc=(sx * 33, -HL + 3, 62))
    for i in range(7):
        x = sx * (24.5 + i * 2.9)
        h = 26 + (6 - i) * 3.4 if sx > 0 else 26 + (6 - i) * 3.4
        lathe("Gold_Pipe", "Gold", C, [(0, 0), (1.25, 0), (1.25, h - 3), (1.25, h - 3), (0.9, h - 2), (1.25, h - 1.2), (0, h)], segments=14, loc=(x, -HL + 14, 0))
        box("Ink_PipeMouth", "Ink", C, (1.0, 0.3, 1.6), loc=(x, -HL + 12.8, 4.0))

# =====================================================================================================================
gate = collection("PalaceGate")
GW, GH = 16.6, 24.0  # opening (the console face in the builder)
for sx in (-1, 1):
    solid(box("GoldDeep_GatePlinth", "GoldDeep", gate, (4.6, 4.6, 2.0), loc=(sx * 10.4, 0, 1.0), bevel=0.2))
    fluted_column(gate, "Gold_GateCol", "Gold", (sx * 10.4, 0), 1.7, 2.0, 25.0, flutes=8)
    lathe("GoldDeep_GateCap", "GoldDeep", gate, [(0, 0), (1.8, 0), (2.4, 0.8), (2.6, 1.4), (0, 1.4)], segments=20, loc=(sx * 10.4, 0, 25.0))
box("Gold_GateLintel", "Gold", gate, (26, 4.4, 2.4), loc=(0, 0, 27.6), bevel=0.3)
box("GoldDeep_GateLintel2", "GoldDeep", gate, (22, 3.8, 1.6), loc=(0, 0, 29.6), bevel=0.25)
box("Gold_GateLintel3", "Gold", gate, (16, 3.2, 1.4), loc=(0, 0, 31.1), bevel=0.25)
# a fan over the lintel (behind the roster sign)
for k in range(11):
    ang = math.radians(k * 18)
    rb = ray_blade(gate, "Gold_GateRay", "Gold" if k % 2 == 0 else "GoldPale", (0, 0, 0), ang, 3.0, 9.0 if k % 2 == 0 else 7.0, 0.7, 0.1, axis="xz", depth=0.3)
    rb.location = (0, 1.2, 31.8)
# the inner frame round the opening
for sx in (-1, 1):
    box("GoldDeep_GateJamb", "GoldDeep", gate, (0.9, 1.6, GH), loc=(sx * (GW / 2 + 0.45), 0, GH / 2 + 1.0), bevel=0.15)
box("GoldDeep_GateSill", "GoldDeep", gate, (GW + 1.8, 1.6, 0.9), loc=(0, 0, 0.95 + 0.0), bevel=0.15)
box("GoldDeep_GateHead", "GoldDeep", gate, (GW + 1.8, 1.6, 0.9), loc=(0, 0, GH + 1.45), bevel=0.15)

# =====================================================================================================================
ch = collection("PalaceChandelier")
# chain from the hook down to the crown (z 0 at the ceiling, everything hangs below)
for i in range(14):
    z = -0.6 - i * 0.75
    o = torus("GoldDeep_Link", "GoldDeep", ch, 0.38, 0.1, seg=12, mseg=4, loc=(0, 0, z), rot=(math.radians(90), 0, math.radians(90) * (i % 2)))
lathe("Gold_Canopy", "Gold", ch, [(0, 0), (2.2, 0), (2.0, -0.6), (0.6, -1.0), (0, -1.0)], segments=20)
TOP = -11.0
# the stem: a turned baluster with bulbs
lathe("Gold_Stem", "Gold", ch, [(0, TOP), (0.5, TOP), (0.9, TOP - 1.2), (0.5, TOP - 2.2), (1.4, TOP - 3.6), (1.8, TOP - 4.8), (1.2, TOP - 6.2),
                                 (0.6, TOP - 7.0), (1.0, TOP - 8.0), (0.5, TOP - 9.0), (0.7, TOP - 9.6), (0, TOP - 10.4)], segments=24)
# two tiers of S-curved arms with candle cups, crystal drops hanging between
for tier, (n, reach, zc, rise) in enumerate([(12, 8.5, TOP - 6.2, 2.4), (8, 5.0, TOP - 2.6, 1.8)]):
    torus("GoldDeep_Hoop", "GoldDeep", ch, reach * 0.62, 0.22, seg=48, mseg=6, loc=(0, 0, zc - 0.2))
    for k in range(n):
        a = k / n * math.tau
        d = Vector((math.cos(a), math.sin(a), 0))
        pts = []
        for i in range(13):
            t = i / 12
            r = 0.8 + t * (reach - 0.8)
            z = zc - math.sin(t * math.pi) * 1.1 + t * t * rise
            pts.append(d * r + Vector((0, 0, z)))
        sweep("Gold_Arm", "Gold", ch, pts, circle(0.2, 6))
        tip = pts[-1]
        lathe("Gold_Bobeche", "Gold", ch, [(0, 0), (0.7, 0.05), (0.8, 0.25), (0.35, 0.3), (0.35, 0.6), (0, 0.6)], segments=12, loc=tip)
        lathe("Marble_Candle", "Marble", ch, [(0, 0), (0.28, 0), (0.28, 1.8), (0, 1.9)], segments=10, loc=tip + Vector((0, 0, 0.55)))
        # a crystal drop under each arm's elbow
        e = pts[6]
        lathe("Glass_Drop", "Glass", ch, [(0, 0), (0.25, -0.3), (0.38, -0.9), (0.2, -1.5), (0, -1.8)], segments=6, loc=e + Vector((0, 0, -0.25)), smooth=False)
# swags of crystal beads between the lower arms
for k in range(12):
    a0, a1 = k / 12 * math.tau, (k + 1) / 12 * math.tau
    for i in range(1, 6):
        t = i / 6
        a = a0 + (a1 - a0) * t
        r = 7.3
        z = TOP - 6.2 - 1.3 - math.sin(t * math.pi) * 1.6
        lathe("Glass_Bead", "Glass", ch, [(0, -0.3), (0.3, 0), (0, 0.3)], segments=6, loc=(math.cos(a) * r, math.sin(a) * r, z), smooth=False)
lathe("Gold_Finial", "Gold", ch, [(0, 0), (0.9, -0.4), (0.6, -1.4), (0.2, -2.6), (0.4, -3.0), (0, -3.6)], segments=14, loc=(0, 0, TOP - 10.3))

# =====================================================================================================================
urn = collection("PalaceUrn")
solid(lathe("MarbleDark_Pedestal", "MarbleDark", urn, [(0, 0), (3.4, 0), (3.4, 1.0), (2.8, 1.4), (2.4, 2.0), (2.2, 6.4), (2.6, 6.8), (3.2, 7.4), (3.2, 8.0), (0, 8.0)], segments=8, smooth=False))
for z in (1.05, 7.45):
    torus("Gold_PedBand", "Gold", urn, 3.32 if z < 2 else 3.2, 0.14, seg=8, mseg=4, loc=(0, 0, z)).rotation_euler = (0, 0, math.radians(22.5))
lathe("Gold_Urn", "Gold", urn, [(0, 8.0), (1.4, 8.0), (1.6, 8.4), (1.0, 8.9), (1.0, 9.6), (1.8, 10.2), (2.9, 11.4), (3.2, 12.6), (3.0, 13.6),
                                 (2.4, 14.2), (2.7, 14.6), (3.3, 14.9), (3.0, 15.1), (2.5, 14.6), (0, 14.2)], segments=28)
for sx in (-1, 1):
    pts = [Vector((sx * (2.8 + math.sin(t * math.pi) * 1.4), 0, 11.4 + t * 3.4)) for t in [i / 10 for i in range(11)]]
    sweep("Gold_Handle", "Gold", urn, pts, circle(0.22, 6))
torus("GoldDeep_UrnBand", "GoldDeep", urn, 3.15, 0.18, seg=32, mseg=6, loc=(0, 0, 12.6))

print({c.name: len(c.objects) for c in (hall, gate, ch, urn)})
