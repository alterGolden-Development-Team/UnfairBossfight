# The Golden Encounter's maps. Origin = ground centre unless noted; Roblox (x, y, z) = Blender (-x, z, y).
#   ArenaPine / ArenaOak   scenery trees (~40 tall at scale 1): a pine with golden-tipped tiers and an autumn oak in gold leaf.
#   ArenaSpire             a gilded gothic spire, 100 tall at scale 1 (the far skyline).
#   ArenaRuinArch          a ruined arch and its fallen stones (~30 wide, 32 tall).
#   ArenaColumn            a broken fluted column on a plinth (~22 tall).
#   TerraceRock            a cliff block 1 x 1 x 1 centred on the origin, for skinning the arena's terrace blocks (stretched to each).
#   NothingStage           the final attack's stage: top face at z 0, radius 100 at scale 1 (scaled to SB.Radius + 10).
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"PineLeaf": ((0.08, 0.18, 0.08), 0.0, 0.9), "Void": ((0.02, 0.01, 0.04), 0.0, 0.2), "Star": ((1.0, 0.95, 0.8), 0.0, 0.5),
             "Nebula": ((0.5, 0.3, 1.0), 0.0, 0.5)}.items():
    ROLES[k] = v
V = Vector


def roughen(o, strength=1.0, size=2.0, levels=1, seed=0):
    if levels:
        sub = o.modifiers.new("Sub", "SUBSURF")
        sub.levels = levels
    tex = bpy.data.textures.get(f"BANoise{seed}") or bpy.data.textures.new(f"BANoise{seed}", "CLOUDS")
    tex.noise_scale = size
    d = o.modifiers.new("Disp", "DISPLACE")
    d.texture = tex
    d.strength = strength
    return o


# =====================================================================================================================
c = collection("ArenaPine")
sweep("Bark_Trunk", "Bark", c, [V((0, 0, -1)), V((0.3, 0, 20)), V((0, 0.2, 40))], lambda t: circle(1.6 * (1 - t * 0.8) + 0.15, 8))
for i in range(6):
    z = 9 + i * 5.2
    r = 11 - i * 1.6
    o = lathe(f"PineLeaf_Tier{i}", "PineLeaf", c, [(0, z + 7.5), (r * 0.35, z + 4.5), (r, z), (r * 0.82, z - 0.6), (0, z + 0.4)], segments=9, smooth=False)
    o.rotation_euler = (0, 0, i * 0.5)
    lathe(f"Gold_TierTips{i}", "Gold", c, [(r * 0.98, z - 0.2), (r * 1.02, z + 0.25), (r * 0.9, z + 0.5), (r * 0.85, z)], segments=9, smooth=False).rotation_euler = (0, 0, i * 0.5)

c = collection("ArenaOak")
rr = random.Random(5)
trunk = [V((0, 0, -1)), V((0.6, 0.3, 8)), V((0.2, -0.4, 16)), V((0.8, 0, 22))]
sweep("Bark_Trunk", "Bark", c, trunk, lambda t: circle(2.2 * (1 - t * 0.6), 9))
for k in range(5):
    a = k / 5 * math.tau + rr.uniform(-0.3, 0.3)
    base = trunk[2]
    end = base + V((math.cos(a) * 11, math.sin(a) * 11, rr.uniform(6, 12)))
    sweep("Bark_Branch", "Bark", c, [base, (base + end) / 2 + V((0, 0, 2)), end], lambda t: circle(0.9 * (1 - t * 0.6), 6))
    s = rr.uniform(9, 12)
    rock(f"Leaf_Crown{k}", "Leaf", c, (s * 1.25, s * 1.25, s * 0.9), loc=end + V((0, 0, s * 0.2)), seed=40 + k, detail=2, rough=0.28, flat_bottom=False)
rock("Leaf_CrownTop", "Leaf", c, (16, 16, 12), loc=(0.8, 0, 30), seed=55, detail=2, rough=0.28, flat_bottom=False)

# =====================================================================================================================
c = collection("ArenaSpire")
lathe("Marble_Base", "Marble", c, [(0, 0), (9, 0), (9, 4), (7.5, 5), (7.5, 9), (0, 9)], segments=8, smooth=False)
lathe("Marble_Shaft", "Marble", c, [(0, 9), (6.5, 9), (5.8, 52), (6.6, 54), (6.6, 56), (0, 56)], segments=8, smooth=False)
for k in range(8):
    a = k / 8 * math.tau + math.pi / 8
    box(f"Gold_Rib{k}", "Gold", c, (1.0, 1.0, 46), loc=(math.cos(a) * 6.4, math.sin(a) * 6.4, 32), rot=(0, 0, a), bevel=0.2)
    lathe(f"Gold_Pinnacle{k}", "Gold", c, [(0, 0), (1.3, 0), (0.8, 4), (0, 9)], segments=6, smooth=False, loc=(math.cos(a) * 6.8, math.sin(a) * 6.8, 56))
lathe("Gold_Cone", "Gold", c, [(0, 56), (6.2, 56), (3.6, 72), (1.4, 90), (0, 100)], segments=8, smooth=False)
torus("GoldPale_Band", "GoldPale", c, 6.0, 0.5, seg=24, mseg=6, loc=(0, 0, 30))
lathe("Neon_Orb", "Neon", c, [(0, -1.6), (1.6, 0), (0, 1.6)], segments=10, loc=(0, 0, 101.5))
for k in range(4):
    a = k / 4 * math.tau
    box(f"Ink_Window{k}", "Ink", c, (2.2, 0.6, 7), loc=(math.cos(a) * 6.0, math.sin(a) * 6.0, 42), rot=(0, 0, a + math.pi / 2))

# =====================================================================================================================
c = collection("ArenaRuinArch")
for s in (-1, 1):
    solid(box(f"StoneWarm_Pier{s}", "StoneWarm", c, (5, 5, 22 if s < 0 else 15), loc=(s * 11, 0, (22 if s < 0 else 15) / 2), bevel=0.4))
    box(f"Gold_Cap{s}", "Gold", c, (6, 6, 0.8), loc=(s * 11, 0, (22 if s < 0 else 15) + 0.4), bevel=0.15)
pts = [V((math.cos(a) * 11, 0, 22 + math.sin(a) * 9)) for a in [math.radians(x) for x in range(180, 70, -10)]]
sweep("StoneWarm_ArchStub", "StoneWarm", c, pts, [(-2.2, -2.4), (2.2, -2.4), (2.2, 2.4), (-2.2, 2.4)], smooth=False)
for k in range(6):
    o = box(f"StoneWarm_Fallen{k}", "StoneWarm", c, (4.4, 4.6, 3.6), loc=(rr.uniform(-6, 16), rr.uniform(-8, 8), 1.6), rot=(rr.uniform(-0.3, 0.3), rr.uniform(-0.3, 0.3), rr.uniform(0, 6)), bevel=0.4)
for k in range(10):
    rock(f"Rock_Rubble{k}", "Rock", c, (rr.uniform(1, 3), rr.uniform(1, 3), rr.uniform(0.6, 1.6)), loc=(rr.uniform(-14, 18), rr.uniform(-10, 10), 0.4), seed=80 + k, detail=1)

c = collection("ArenaColumn")
solid(box("StoneWarm_Plinth", "StoneWarm", c, (7, 7, 2), loc=(0, 0, 1), bevel=0.25))
seg, lv = 32, 8
bm = bmesh.new()
rings = []
for k in range(lv + 1):
    z = 2 + 18 * k / lv
    ring = []
    for i in range(seg):
        a = i / seg * math.tau
        r = 2.6 * (1 - 0.1 * max(0.0, math.cos(a * 8)) ** 2)
        zz = z - (3.5 * (0.5 + 0.5 * math.sin(a * 2 + 1)) if k == lv else 0)
        ring.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, zz)))
    rings.append(ring)
for k in range(lv):
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
bm.faces.new(list(reversed(rings[0])))
top = bm.verts.new((0, 0, 18.5))
for i in range(seg):
    bm.faces.new((rings[-1][i], rings[-1][(i + 1) % seg], top))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
solid(obj_from_bm(bm, "Marble_Shaft", "Marble", c))
torus("Gold_Necking", "Gold", c, 2.65, 0.2, seg=32, mseg=4, loc=(0, 0, 3.2))

# =====================================================================================================================
c = collection("TerraceRock")
o = rock("Rock_Block", "Rock", c, (1.0, 1.0, 1.0), loc=(0, 0, 0), seed=7, detail=2, rough=0.12, flat_bottom=False)  # ~80 tris: there are ~750
# flatten the top a little so the block still reads as a terrace you can stand on
o.data.transform(Matrix.Scale(1.0, 4))
tops = rock("Grass_Cap", "Grass", c, (0.98, 0.98, 0.12), loc=(0, 0, 0.47), seed=8, detail=1, rough=0.1, flat_bottom=True)

# =====================================================================================================================
c = collection("NothingStage")
R = 100.0
lathe("Void_Top", "Void", c, [(0, -0.4), (R - 2, -0.4), (R, -1.2), (R - 1, -4), (R * 0.6, -14), (0, -16)], segments=96)
for r in (30, 60, 88, 97):
    torus(f"Star_Ring{r}", "Star", c, r, 0.35 if r < 90 else 0.6, seg=128, mseg=4, loc=(0, 0, 0.0), scale_minor=(1, 0.3))
for k in range(24):
    a = k / 24 * math.tau
    long = k % 2 == 0
    o = box(f"Gold_Tick{k}", "Gold", c, (0.6, 7 if long else 4, 0.1), loc=(math.cos(a) * (84 if long else 85.5), math.sin(a) * (84 if long else 85.5), 0.05))
    o.rotation_euler = (0, 0, a + math.pi / 2)
for k in range(12):
    a = k / 12 * math.tau
    p0 = V((math.cos(a) * 30, math.sin(a) * 30, 0.06))
    p1 = V((math.cos(a + math.tau * 5 / 12) * 30, math.sin(a + math.tau * 5 / 12) * 30, 0.06))
    sweep(f"Gold_Sigil{k}", "Gold", c, [p0, p1], [(-0.35, -0.04), (0.35, -0.04), (0.35, 0.04), (-0.35, 0.04)], smooth=False)
# the underside: an inverted mountain of dark rock with glowing cracks, hanging into the void
under = rock("Rock_Under", "Rock", c, (R * 1.7, R * 1.7, 70), loc=(0, 0, -45), seed=31, detail=3, rough=0.35, flat_bottom=False)
roughen(under, strength=6, size=12, levels=1, seed=31)
for k in range(10):
    a = k / 10 * math.tau
    pts = [V((math.cos(a) * (R * 0.85 - t * 50), math.sin(a) * (R * 0.85 - t * 50), -6 - t * 55)) for t in [i / 6 for i in range(7)]]
    sweep(f"Nebula_Crack{k}", "Nebula", c, pts, circle(1.0, 5))
# crystal shards round the rim, leaning out
for k in range(18):
    a = k / 18 * math.tau
    h = 14 + (k % 3) * 6
    o = lathe(f"Nebula_Shard{k}", "Nebula", c, [(0, 0), (2.4, h * 0.3), (0, h)], segments=5, smooth=False)
    o.location = (math.cos(a) * (R + 4), math.sin(a) * (R + 4), -3)
    o.rotation_euler = (math.sin(a) * -0.35, math.cos(a) * 0.35, 0)
# a tilted gold orbit ring far out, and floating stones
torus("Gold_Orbit", "Gold", c, R * 1.45, 1.6, seg=128, mseg=6, loc=(0, 0, 20), rot=(math.radians(14), math.radians(6), 0))
for k in range(14):
    a = rr.uniform(0, math.tau)
    d = rr.uniform(R * 1.15, R * 1.6)
    s = rr.uniform(6, 16)
    rock(f"Rock_Float{k}", "Rock", c, (s * 1.3, s, s * 0.8), loc=(math.cos(a) * d, math.sin(a) * d, rr.uniform(-40, 30)), seed=300 + k, detail=2, rough=0.3, flat_bottom=False)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith(("Arena", "Terrace", "Nothing"))})
