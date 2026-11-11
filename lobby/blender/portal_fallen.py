# TheFallenNoob's portal: a beach torn up into the sky. A sea-worn rock arch holds a giant ship's wheel (the ring), on a sand mound
# with a half-buried rowboat, an anchor, barrels and shells. Opening centre at (0, 0, 16), diameter 28, facing -Y.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())

col = collection("PortalFallen")
CY = 16.0
R = 14.0
rnd = random.Random(7)


def roughen(o, strength=1.2, size=2.5, levels=1, seed=0):
    sub = o.modifiers.new("Sub", "SUBSURF")
    sub.levels = levels
    sub.render_levels = levels
    tex = bpy.data.textures.get(f"RockNoise{seed}") or bpy.data.textures.new(f"RockNoise{seed}", "CLOUDS")
    tex.noise_scale = size
    tex.noise_depth = 2
    d = o.modifiers.new("Disp", "DISPLACE")
    d.texture = tex
    d.strength = strength
    d.mid_level = 0.5
    return o


# --- sand mound with a lip, wet darker band near the bottom is skipped: Roblox sand reads well alone
prof = []
for i in range(13):
    t = i / 12
    prof.append((31 * (1 - t) ** 0.6 + 0.01, 3.2 * math.sin(t * math.pi / 2) ** 0.7))
prof.append((0, 3.2))
mound = solid(lathe("Sand_Mound", "Sand", col, prof, segments=72))
roughen(mound, strength=0.6, size=6, levels=1, seed=1)

# --- the rock arch: a lumpy section swept over the opening, thick feet buried in the sand
path = []
for i in range(41):
    t = i / 40
    a = math.radians(-20 + t * 220)
    rr = R + 4.6 + math.sin(t * 9.0) * 0.6
    path.append(Vector((math.cos(a) * rr, 0, CY + math.sin(a) * rr)))
# feet go down to the sand
path.insert(0, path[0] + Vector((1.5, 0, -8)))
path.append(path[-1] + Vector((-1.5, 0, -8)))


def section(t):
    fat = 4.4 + 1.8 * (abs(t - 0.5) * 2) ** 2  # thicker at the feet
    pts = []
    for k in range(14):
        b = k / 14 * math.tau
        wob = 1 + 0.18 * math.sin(b * 3 + t * 11) + 0.1 * math.sin(b * 5 - t * 7)
        pts.append((math.cos(b) * fat * wob * 1.15, math.sin(b) * fat * wob))
    return pts


arch = solid(sweep("Rock_Arch", "Rock", col, path, section))
roughen(arch, strength=2.2, size=3.0, levels=2, seed=2)
# boulders heaped at the feet, and a few barnacled stones
for side in (-1, 1):
    for k in range(5):
        s = rnd.uniform(4, 8)
        solid(rock(f"Rock_Foot{side}{k}", "Rock", col, (s * 1.2, s, s * 0.9),
             loc=(side * (R + 6 + rnd.uniform(-1, 4)), rnd.uniform(-4, 4), 2.5 + rnd.uniform(0, 3)), seed=side * 10 + k))
for k in range(8):
    a = rnd.uniform(0, math.tau)
    d = rnd.uniform(14, 26)
    s = rnd.uniform(1.6, 3.4)
    rock(f"Stone_Pebble{k}", "Stone", col, (s * 1.3, s, s * 0.7), loc=(math.cos(a) * d, math.sin(a) * d, 2.4), seed=100 + k)

# --- the ship's wheel: a wooden rim with a brass band and hub ring; turned handles stick out past the rim between the rocks
torus("Wood_WheelRim", "Wood", col, R + 1.2, 1.2, seg=96, mseg=12, loc=(0, -4.5, CY), rot=(math.radians(90), 0, 0), scale_minor=(1.0, 1.3))
torus("Gold_WheelBand", "Gold", col, R + 1.2, 0.5, seg=96, mseg=8, loc=(0, -5.75, CY), rot=(math.radians(90), 0, 0))
torus("Gold_WheelBandBack", "Gold", col, R + 1.2, 0.5, seg=96, mseg=8, loc=(0, -3.25, CY), rot=(math.radians(90), 0, 0))
for i in range(10):
    a = i / 10 * math.tau + math.pi / 10
    d = Vector((math.cos(a), 0, math.sin(a)))
    # turned handle: bead, neck, knob
    prof = [(0.95, 0), (0.95, 0.6), (0.7, 1.0), (0.9, 1.6), (0.6, 2.4), (1.1, 3.4), (1.25, 4.2), (0.9, 5.0), (0.0, 5.3)]
    h = lathe(f"Wood_Handle{i}", "Wood", col, prof, segments=12)
    h.location = Vector((0, -4.5, CY)) + d * (R + 2.2)
    h.rotation_euler = Vector((0, 0, 1)).rotation_difference(d).to_euler()
    lathe(f"Gold_HandleCap{i}", "Gold", col, [(1.0, 0), (1.0, 0.5), (0, 0.5)], segments=12).location = h.location
    col.objects[f"Gold_HandleCap{i}"].rotation_euler = h.rotation_euler

# --- the wreck: a rowboat's bow sticking up out of the sand, left of the arch
hull_pts = []
for i in range(17):
    t = i / 16
    hull_pts.append(Vector((-24 + t * 2.0, -9 + t * 12.0, 2.0 + t * t * 7.0)))


def hull_section(t):
    w = 3.4 * (1 - t ** 3) + 0.25
    return [(-w, 1.6), (-w * 0.92, 0.4), (-w * 0.6, -0.9), (0, -1.5), (w * 0.6, -0.9), (w * 0.92, 0.4), (w, 1.6),
            (w - 0.35, 1.6), (w * 0.82 - 0.35, 0.3), (0, -1.0), (-w * 0.82 + 0.35, 0.3), (-w + 0.35, 1.6)]


sweep("Plank_Wreck", "Plank", col, hull_pts, hull_section, smooth=False)
for k in range(4):
    t = 0.15 + k * 0.2
    p = hull_pts[int(t * 16)]
    box(f"WoodDark_Rib{k}", "WoodDark", col, (6.6 * (1 - t ** 3) + 0.4, 0.5, 0.45), loc=p + Vector((0, 0, 1.4)), rot=(math.atan2(7, 12) * -0.0, 0, 0))

# --- an anchor leaning on the arch's right foot
anc = Vector((22, -8, 3.0))
sweep("Iron_AnchorShank", "Iron", col, [anc + Vector((0, 0, 0)), anc + Vector((-1.5, 0, 6)), anc + Vector((-3.0, 0, 12))], circle(0.55, 8))
arc = [anc + Vector((math.cos(a) * 4.2, 0, 4.2 - math.sin(a) * 4.2 * 0.9)) for a in [math.radians(x) for x in range(-170, -9, 10)]]
arc = [anc + Vector((math.cos(math.radians(x)) * 4.0, 0, 3.6 + math.sin(math.radians(x)) * 3.6)) for x in range(190, 351, 10)]
sweep("Iron_AnchorArms", "Iron", col, arc, circle(0.5, 8))
for p in (arc[0], arc[-1]):
    o = lathe("Iron_Fluke", "Iron", col, [(1.3, 0), (0.0, 2.2)], segments=4, smooth=False)
    o.location = p
torus("Iron_AnchorRing", "Iron", col, 1.1, 0.25, seg=20, mseg=6, loc=anc + Vector((-3.2, 0, 13.0)), rot=(math.radians(90), 0, 0))
box("WoodDark_Stock", "WoodDark", col, (0.8, 6.0, 0.8), loc=anc + Vector((-2.7, 0, 11.0)), bevel=0.15)

# --- barrels and a crate washed up
for k, (x, y, lie) in enumerate([(14, -16, False), (18, -13, True), (-12, -17, False)]):
    prof = [(0, 0), (1.5, 0), (1.75, 0.6), (1.95, 1.6), (1.75, 2.6), (1.5, 3.2), (0, 3.2)]
    b = lathe(f"Wood_Barrel{k}", "Wood", col, prof, segments=18)
    b.location = (x, y, 2.6 if not lie else 4.4)
    if lie:
        b.rotation_euler = (math.radians(90), 0, 0.6)
    for z in (0.5, 2.7):
        hoop = torus(f"Iron_Hoop{k}{z}", "Iron", col, 1.82, 0.14, seg=24, mseg=4)
        hoop.parent = b
        hoop.location = (0, 0, z)
box("Plank_Crate", "Plank", col, (4, 4, 4), loc=(-17, -12, 4.0), rot=(0.1, 0.05, 0.4), bevel=0.25)

# --- starfish and shells
for k in range(9):
    a = rnd.uniform(0, math.tau)
    d = rnd.uniform(8, 22)
    p = Vector((math.cos(a) * d, math.sin(a) * d - 4, 3.1))
    if k % 2 == 0:
        bm = bmesh.new()
        c = bm.verts.new(p + Vector((0, 0, 0.35)))
        outer = []
        for j in range(10):
            ang = j / 10 * math.tau
            r = 1.4 if j % 2 == 0 else 0.5
            outer.append(bm.verts.new(p + Vector((math.cos(ang) * r, math.sin(ang) * r, 0))))
        for j in range(10):
            bm.faces.new((c, outer[j], outer[(j + 1) % 10]))
        bm.faces.new(list(reversed(outer)))
        obj_from_bm(bm, f"Star{k}", "Red", col, smooth=False)
    else:
        o = lathe(f"Marble_Shell{k}", "Marble", col, [(0, 0), (1.0, 0.1), (0.8, 0.6), (0, 0.9)], segments=10, smooth=False)
        o.location = p

print(len(col.objects), "objects")
