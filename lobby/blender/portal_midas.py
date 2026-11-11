# The Golden Encounter portal: a gilded ring gate on fluted columns, a crown on top, sun rays fanning out behind,
# on a round stepped dais. Opening centre at (0, 0, 18), diameter 30, facing -Y (the builder turns it to face the plaza).
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())

col = collection("PortalMidas")
CY = 18.0  # opening centre height
R = 15.0  # opening radius


def fluted(name, role, x, height, radius, flutes=12, base_z=3.0):
    seg = flutes * 4
    bm = bmesh.new()
    rings = []
    levels = 14
    for k in range(levels + 1):
        z = base_z + height * k / levels
        ring = []
        for i in range(seg):
            a = i / seg * math.tau
            r = radius * (1 - 0.09 * max(0.0, math.cos(a * flutes)) ** 2)
            ring.append(bm.verts.new((x + math.cos(a) * r, math.sin(a) * r, z)))
        rings.append(ring)
    for k in range(levels):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, role, col)


# --- dais: three round steps, and a front apron that the plaza steps up onto
for i, (r, h) in enumerate([(27, 1.0), (24, 2.0), (21, 3.0)]):
    solid(lathe(f"MarbleDark_Step{i}", "MarbleDark", col, [(0, h - 1.0), (r, h - 1.0), (r, h - 0.15), (r - 0.15, h), (0, h)], segments=64))
    torus(f"Gold_StepTrim{i}", "Gold", col, r - 0.05, 0.16, seg=96, mseg=6, loc=(0, 0, h - 0.18))

# --- columns: plinth, fluted shaft, capital with volutes, either side of the ring
for side in (-1, 1):
    x = side * 18.5
    solid(lathe(f"GoldDeep_Plinth{side}", "GoldDeep", col, [(0, 0), (3.9, 0), (3.9, 1.2), (3.5, 1.5), (3.2, 2.0), (2.9, 2.3), (0, 2.3)], segments=32, loc=(x, 0, 3)))
    solid(fluted(f"Gold_Shaft{side}", "Gold", x, 27.5, 2.5, base_z=5.3))
    lathe(f"GoldDeep_Capital{side}", "GoldDeep", col,
          [(0, 0), (2.6, 0), (2.9, 0.4), (2.7, 0.8), (3.2, 1.4), (3.8, 2.2), (3.9, 2.8), (0, 2.8)], segments=32, loc=(x, 0, 32.8))
    box(f"Gold_Abacus{side}", "Gold", col, (8.2, 8.2, 1.2), loc=(x, 0, 36.2), bevel=0.25)
    # volutes: scroll rings at the capital's corners
    for sy in (-1, 1):
        torus(f"Gold_Volute{side}{sy}", "Gold", col, 0.9, 0.3, seg=20, mseg=8, loc=(x + side * 0, sy * 3.0, 34.4), rot=(0, math.radians(90), 0))
    # a gold urn with a flame-shaped finial on top of each column
    lathe(f"Gold_Urn{side}", "Gold", col,
          [(0, 0), (1.6, 0), (1.2, 0.5), (1.4, 1.0), (2.4, 2.2), (2.2, 3.3), (1.2, 3.8), (1.4, 4.2), (0.6, 4.6), (0.5, 5.6), (0, 6.6)],
          segments=24, loc=(x, 0, 36.8))

# --- the ring: a fat rolled moulding, a thin inner bead and an outer bead, with jewels round the face
torus("Gold_Ring", "Gold", col, R + 1.7, 1.7, seg=96, mseg=16, loc=(0, 0, CY), rot=(math.radians(90), 0, 0), scale_minor=(1.0, 1.35))
torus("GoldDeep_RingInner", "GoldDeep", col, R + 0.05, 0.5, seg=96, mseg=10, loc=(0, 0, CY), rot=(math.radians(90), 0, 0))
torus("GoldDeep_RingOuter", "GoldDeep", col, R + 3.6, 0.55, seg=96, mseg=10, loc=(0, 0, CY), rot=(math.radians(90), 0, 0))
for i in range(16):
    a = i / 16 * math.tau
    p = (math.cos(a) * (R + 1.7), -2.2, CY + math.sin(a) * (R + 1.7))
    gem = "GemRed" if i % 2 == 0 else "GemBlue"
    o = lathe(f"{gem}_Jewel{i}", gem, col, [(0, -0.5), (0.6, -0.3), (0.85, 0.2), (0.55, 0.55), (0, 0.6)], segments=8, smooth=False)
    o.location = p
    o.rotation_euler = (math.radians(90), 0, 0)
    bz = lathe(f"GoldDeep_Bezel{i}", "GoldDeep", col, [(0, 0), (1.05, 0), (1.05, 0.3), (0, 0.3)], segments=12)
    bz.rotation_euler = (math.radians(90), 0, 0)
    bz.location = (p[0], -1.65, p[2])

# --- sun rays fanning behind the ring's upper half (the Midas sun)
for i in range(23):
    t = i / 22
    a = math.radians(-12 + t * 204)
    length = 12 + (7 if i % 2 == 0 else 0)
    inner = R + 3.0
    mid = Vector((math.cos(a) * (inner + length / 2), 1.8, CY + math.sin(a) * (inner + length / 2)))
    half_w = 1.25 if i % 2 == 0 else 0.9
    # a flat blade that tapers to a point, slightly ridged down the middle
    bm = bmesh.new()
    d = Vector((math.cos(a), 0, math.sin(a)))
    s = Vector((-math.sin(a), 0, math.cos(a)))
    base = Vector((0, 1.8, CY)) + d * inner
    tip = Vector((0, 1.8, CY)) + d * (inner + length)
    th = Vector((0, 0.45, 0))
    vs = [bm.verts.new(base + s * half_w + th), bm.verts.new(base - s * half_w + th), bm.verts.new(tip + th),
          bm.verts.new(base + s * half_w - th), bm.verts.new(base - s * half_w - th), bm.verts.new(tip - th),
          bm.verts.new(base + d * (length * 0.5) - th * 2.2)]
    bm.faces.new((vs[0], vs[1], vs[2]))
    bm.faces.new((vs[3], vs[5], vs[4]))
    bm.faces.new((vs[0], vs[3], vs[4], vs[1]))
    bm.faces.new((vs[1], vs[4], vs[5], vs[2]))
    bm.faces.new((vs[2], vs[5], vs[3], vs[0]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj_from_bm(bm, f"{'Gold' if i % 2 == 0 else 'GoldPale'}_Ray{i}", "Gold" if i % 2 == 0 else "GoldPale", col, smooth=False)

# --- entablature across the columns, and the crown on top
box("GoldDeep_Lintel", "GoldDeep", col, (46, 7.5, 2.4), loc=(0, 0, 38.0), bevel=0.4)
box("Gold_Cornice", "Gold", col, (48, 8.5, 1.0), loc=(0, 0, 39.7), bevel=0.3)
box("Gold_Frieze", "Gold", col, (44, 7.0, 0.8), loc=(0, 0, 36.6), bevel=0.2)
# crown: a band of arches with points, jewels and a cross-orb
crown_z = 40.2
lathe("Gold_CrownBand", "Gold", col, [(9.6, 0), (9.8, 0.2), (9.8, 3.2), (9.6, 3.4), (9.0, 3.4), (9.0, 0)], segments=64, loc=(0, 0, crown_z), smooth=True)
torus("GoldDeep_CrownBead", "GoldDeep", col, 9.85, 0.35, seg=64, mseg=8, loc=(0, 0, crown_z + 0.4))
torus("GoldDeep_CrownBead2", "GoldDeep", col, 9.85, 0.35, seg=64, mseg=8, loc=(0, 0, crown_z + 3.0))
for i in range(10):
    a = i / 10 * math.tau + math.pi / 2
    # a fleur point: a tapered spike leaning slightly out with a ball tip
    p = Vector((math.cos(a) * 9.4, math.sin(a) * 9.4, crown_z + 3.2))
    h = 6.5 if i % 2 == 0 else 4.2
    o = lathe(f"Gold_Point{i}", "Gold", col, [(1.3, 0), (1.15, h * 0.4), (0.7, h * 0.8), (0.0, h)], segments=8, smooth=False)
    o.location = p
    o.rotation_euler = (math.cos(a + math.pi / 2) * 0.18 * -1, math.sin(a + math.pi / 2) * 0.18 * -1, 0)
    o.rotation_euler = Euler((-math.sin(a) * 0.15, math.cos(a) * 0.15, 0))
    ball = lathe(f"GoldPale_PointBall{i}", "GoldPale", col, [(0, -0.75), (0.53, -0.53), (0.75, 0), (0.53, 0.53), (0, 0.75)], segments=10)
    tip = p + Vector((math.cos(a) * 0.15 * h, math.sin(a) * 0.15 * h, h + 0.3))
    ball.location = tip
    if i % 2 == 0:
        g = lathe(f"CrownGem{i}", "GemRed" if i % 4 == 0 else "GemBlue", col,
                  [(0, -0.9), (0.9, 0), (0, 0.9)], segments=6, smooth=False)
        g.location = Vector((math.cos(a) * 10.0, math.sin(a) * 10.0, crown_z + 1.7))
        g.rotation_euler = (math.radians(90), 0, a + math.pi / 2)
# arches over the crown, meeting at an orb with a cross
for k in range(2):
    a = k * math.pi / 2
    path = []
    for i in range(25):
        t = i / 24 * math.pi
        r = 9.3 * math.cos(t)
        path.append(Vector((math.cos(a) * r, math.sin(a) * r, crown_z + 3.3 + math.sin(t) * 5.5)))
    sweep(f"Gold_CrownArch{k}", "Gold", col, path, circle(0.45, 8))
lathe("Gold_Orb", "Gold", col, [(0, -1.4), (1.0, -1.0), (1.4, 0), (1.0, 1.0), (0, 1.4)], segments=16, loc=(0, 0, crown_z + 10.2))
box("Gold_CrossV", "Gold", col, (0.6, 0.6, 3.2), loc=(0, 0, crown_z + 12.8), bevel=0.12)
box("Gold_CrossH", "Gold", col, (2.2, 0.6, 0.6), loc=(0, 0, crown_z + 13.1), bevel=0.12)
lathe("Ink_CrownCap", "Ink", col, [(0, 0), (9.0, 0), (6, 2.5), (0, 4.5)], segments=32, loc=(0, 0, crown_z + 0.6))

print(len(col.objects), "objects")
