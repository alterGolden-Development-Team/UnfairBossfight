# alterGolden's black clothing for the boss place (replaces the flat Shirt / Pants textures). Every piece is modelled around the CENTRE of the
# R15 body part it is welded to. Roblox local (x, y, z) = Blender (-x, z, y): Blender +Z up, -Y is the front. Left/right share one mesh
# (the pieces are symmetric), so each is attached to both limbs.
#   BossTunic       UpperTorso (2.0 wide x 1.7 tall x 1.0 deep): fitted doublet, high collar, gold buttons and hem piping, crest
#   BossSkirt       LowerTorso (2.0 x 0.4 x 1.0): hanging front/back flaps and side tassets under the belt, crimson lining
#   BossSleeveUp    UpperArm  (1.0 x 1.2 x 1.0): sleeve with a gold elbow band (the gold pauldron sits over its top)
#   BossSleeveLow   LowerArm  (1.0 x 1.1 x 1.0): sleeve, gold cuff band and a flared cuff over the wrist
#   BossTrouserUp   UpperLeg  (1.0 x 1.3 x 1.0), BossTrouserLow  LowerLeg (1.0 x 1.3 x 1.0): trousers with a gold side stripe
#   BossBoot        Foot      (1.0 x 0.3 x 1.0): boot with a shaft up over the shin, gold toe cap and buckle strap
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"Cloth": ((0.025, 0.022, 0.03), 0.0, 0.95), "ClothSheen": ((0.09, 0.08, 0.11), 0.0, 0.5),
             "Velvet": ((0.25, 0.02, 0.04), 0.0, 0.9), "Gem": ((0.9, 0.05, 0.1), 0.0, 0.1)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau


def lerp(a, b, t):
    return a + (b - a) * t


def rrect(w, d, r, n=4):
    """A rounded rectangle section [(x, y)], counter-clockwise: w wide (x), d deep (y), corner radius r."""
    pts = []
    for cx, cy, a0 in ((w / 2 - r, d / 2 - r, 0), (-(w / 2 - r), d / 2 - r, 90), (-(w / 2 - r), -(d / 2 - r), 180), (w / 2 - r, -(d / 2 - r), 270)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def vpath(z0, z1, n=10, x=0.0, y=0.0):
    return [V((x, y, lerp(z0, z1, i / n))) for i in range(n + 1)]


def stud(c, role, name, r, loc):
    prof = [(0, -r)] + [(math.sin(math.pi * k / 4) * r, -math.cos(math.pi * k / 4) * r) for k in range(1, 4)] + [(0, r)]
    return lathe(name, role, c, prof, segments=8, loc=loc)


# =====================================================================================================================
c = collection("BossTunic")
# the body: shoulders a little wider than the waist, a hair deeper than the torso
sweep("Cloth_Body", "Cloth", c, vpath(-0.9, 0.88, 12),
      lambda t: rrect(lerp(1.99, 2.2, math.sin(min(t, 0.75) / 0.75 * math.pi / 2)) * (1 - 0.04 * max(0, t - 0.8) / 0.2), 1.14, 0.3), smooth=True, hint=(0, 1, 0))
# the satin front placket with a gold seam and two columns of buttons
box("ClothSheen_Placket", "ClothSheen", c, (0.95, 0.06, 1.72), loc=(0, -0.585, -0.02), bevel=0.02)
box("Gold_Seam", "Gold", c, (0.05, 0.05, 1.78), loc=(0, -0.62, -0.02))
for sx in (-1, 1):
    for k in range(6):
        stud(c, "Gold", "Gold_Button", 0.05, (sx * 0.27, -0.63, 0.66 - k * 0.27))
    box("Gold_PlacketEdge", "Gold", c, (0.035, 0.05, 1.72), loc=(sx * 0.48, -0.62, -0.02))
# gold piping: hem, side seams, shoulder yoke
box("Gold_Hem", "Gold", c, (2.02, 1.18, 0.06), loc=(0, 0, -0.89), bevel=0.02)
for sx in (-1, 1):
    box("GoldDeep_SideSeam", "GoldDeep", c, (0.04, 0.06, 1.5), loc=(sx * 0.99, 0.0, -0.1))
# the high stand collar with a gold rim and a small clasp
lathe("Cloth_Collar", "Cloth", c, [(0.4, 0.78), (0.5, 0.95), (0.56, 1.16), (0.5, 1.2), (0.42, 1.0)], segments=24)
torus("Gold_CollarRim", "Gold", c, 0.53, 0.035, seg=24, mseg=6, loc=(0, 0, 1.19))
box("Gold_Clasp", "Gold", c, (0.16, 0.08, 0.18), loc=(0, -0.55, 0.98), rot=(0, 0, 0), bevel=0.02)
stud(c, "Gem", "Gem_Clasp", 0.055, (0, -0.6, 0.98))
# a gold crest on the chest: a diamond with a red heart
slab2d("Gold_Crest", "Gold", c, [(0, 0.3), (0.2, 0.0), (0, -0.3), (-0.2, 0.0)], -0.64, -0.6)
stud(c, "Gem", "Gem_Crest", 0.06, (0, -0.665, 0.2 - 0.2))

# =====================================================================================================================
c = collection("BossSkirt")
# below the belt: a front flap and a back flap (black outside, crimson lining peeking at the hem), two side tassets
def flap(name_prefix, y, flare, lining_sign):
    outline = [(-0.72, -0.18), (0.72, -0.18), (0.72 + flare, -1.12), (0.36, -1.2), (0.0, -1.3), (-0.36, -1.2), (-0.72 - flare, -1.12)]
    slab2d(name_prefix + "Cloth_Flap", "Cloth", c, outline, y - 0.035, y + 0.035)
    lin = [(-0.7 - flare * 0.5, -1.0), (0.7 + flare * 0.5, -1.0), (0.72 + flare, -1.2), (0.0, -1.4), (-0.72 - flare, -1.2)]
    slab2d(name_prefix + "Velvet_Lining", "Velvet", c, lin, y - 0.02 + lining_sign * 0.045, y + 0.02 + lining_sign * 0.045)
    box(name_prefix + "Gold_FlapEdge", "Gold", c, (1.56 + flare * 2, 0.08, 0.05), loc=(0, y, -1.1), bevel=0.01)
    stud(c, "Gold", name_prefix + "Gold_FlapStud", 0.06, (0, y - lining_sign * 0.05, -0.55))


flap("Front", -0.6, 0.12, -1)
flap("Back", 0.6, 0.14, 1)
for sx in (-1, 1):
    side = [(-0.32, -0.18), (0.32, -0.18), (0.4, -1.0), (0.0, -1.08), (-0.4, -1.0)]
    o = slab2d("Cloth_Tasset", "Cloth", c, side, -0.03, 0.03)
    o.rotation_euler = (0, 0, math.pi / 2)
    o.location = (sx * 1.04, 0, 0)
    t = slab2d("Gold_TassetEdge", "Gold", c, [(-0.4, -0.98), (0.4, -0.98), (0.4, -1.04), (0.0, -1.12), (-0.4, -1.04)], -0.04, 0.04)
    t.rotation_euler = (0, 0, math.pi / 2)
    t.location = (sx * 1.045, 0, 0)

# =====================================================================================================================
c = collection("BossSleeveUp")
sweep("Cloth_Sleeve", "Cloth", c, vpath(-0.62, 0.64, 8),
      lambda t: circle(lerp(0.54, 0.6, t) + 0.015 * math.sin(t * math.pi * 6), 16, 1.0, 0.97), smooth=True)
torus("Gold_ElbowBand", "Gold", c, 0.55, 0.035, seg=20, mseg=6, loc=(0, 0, -0.55))
torus("GoldDeep_ElbowSeam", "GoldDeep", c, 0.54, 0.02, seg=20, mseg=4, loc=(0, 0, -0.38))
box("ClothSheen_Gusset", "ClothSheen", c, (0.2, 0.08, 0.5), loc=(0, 0.52, -0.1), bevel=0.02)

c = collection("BossSleeveLow")
sweep("Cloth_Sleeve", "Cloth", c, vpath(-0.6, 0.58, 8),
      lambda t: circle(lerp(0.5, 0.52, t) - 0.03 * math.sin(t * math.pi), 16, 1.0, 0.97), smooth=True)
# a flared cuff over the wrist, with a gold band and a crimson turn-back
lathe("Cloth_Cuff", "Cloth", c, [(0.5, -0.3), (0.57, -0.42), (0.62, -0.58), (0.56, -0.62), (0.5, -0.5)], segments=20)
torus("Gold_CuffBand", "Gold", c, 0.52, 0.04, seg=20, mseg=6, loc=(0, 0, -0.3))
torus("Velvet_CuffTurn", "Velvet", c, 0.6, 0.03, seg=20, mseg=6, loc=(0, 0, -0.56))
for k in range(3):
    a = k / 3 * TAU + 0.5
    stud(c, "Gold", "Gold_CuffStud", 0.045, (math.cos(a) * 0.55, math.sin(a) * 0.55, -0.3))

# =====================================================================================================================
c = collection("BossTrouserUp")
sweep("Cloth_Leg", "Cloth", c, vpath(-0.68, 0.68, 8),
      lambda t: circle(lerp(0.52, 0.6, t), 16, 1.0, 1.0), smooth=True)
torus("GoldDeep_KneeSeam", "GoldDeep", c, 0.52, 0.02, seg=20, mseg=4, loc=(0, 0, -0.55))
for sx in (-1, 1):
    box("Gold_Stripe", "Gold", c, (0.04, 0.12, 1.3), loc=(sx * 0.58, 0.0, 0.0), bevel=0.01)

c = collection("BossTrouserLow")
sweep("Cloth_Leg", "Cloth", c, vpath(-0.68, 0.68, 8),
      lambda t: circle(lerp(0.44, 0.52, t), 16, 1.0, 1.0), smooth=True)
for sx in (-1, 1):
    box("Gold_Stripe", "Gold", c, (0.04, 0.12, 1.3), loc=(sx * 0.5, 0.0, 0.0), bevel=0.01)
torus("Gold_KneePad", "Gold", c, 0.55, 0.04, seg=20, mseg=6, loc=(0, 0, 0.6))

# =====================================================================================================================
c = collection("BossBoot")
# origin = the foot part's centre (1.0 x 0.3 x 1.0); the toe points to Blender -Y. A shaft rises up over the shin.
sweep("Ink_Shaft", "Ink", c, vpath(-0.02, 0.8, 8),
      lambda t: circle(lerp(0.54, 0.5, t), 16, 1.0, 1.05), smooth=True)
sweep("Ink_Foot", "Ink", c, [V((0, -0.52 + 1.08 * i / 8, -0.07)) for i in range(9)],
      lambda t: rrect(lerp(0.72, 0.98, min(t * 2, 1)) if t < 0.5 else 0.98, 0.34 + 0.08 * math.sin(t * math.pi), 0.12), smooth=True, hint=(0, 0, 1))
box("Gold_ToeCap", "Gold", c, (0.82, 0.3, 0.34), loc=(0, -0.42, -0.04), bevel=0.1)
box("GoldDeep_Sole", "GoldDeep", c, (1.0, 1.2, 0.08), loc=(0, -0.02, -0.19), bevel=0.03)
box("Gold_Heel", "Gold", c, (0.72, 0.26, 0.12), loc=(0, 0.56, -0.17), bevel=0.03)
torus("Gold_BootRim", "Gold", c, 0.52, 0.04, seg=20, mseg=6, loc=(0, 0, 0.78))
# the buckle strap across the ankle
torus("Gold_Strap", "Gold", c, 0.55, 0.05, seg=20, mseg=6, loc=(0, 0, 0.35))
box("GoldPale_Buckle", "GoldPale", c, (0.2, 0.08, 0.2), loc=(0, -0.57, 0.35), bevel=0.02)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith("Boss") and x.name in
       ("BossTunic", "BossSkirt", "BossSleeveUp", "BossSleeveLow", "BossTrouserUp", "BossTrouserLow", "BossBoot")})
