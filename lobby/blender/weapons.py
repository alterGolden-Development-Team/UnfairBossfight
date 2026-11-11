# Class weapons for the boss place (ClassModels). Each is modelled in the frame its class module builds it in. Roblox local (x, y, z) =
# Blender (-x, z, y). Notation below is ROBLOX local axes; the Blender axes follow from that mapping.
#   WpnWarriorSword   frame = SwordHandle * ROT_Y^-1: grip centred in the fist, blade up local +Y (Blender +Z), width X, flat Z (Blender Y).
#   WpnWarriorShield  frame = ShieldRoot: round shield, face toward local +X (Blender -X), 2.9 across.
#   WpnTankSword      frame = Right Arm * (0.02, -0.8, 0) * R(62deg, 0, 0): blade down local -Y (Blender -Z), width local Z (Blender Y).
#   WpnTankShield     frame = Left Arm * (-0.85, -0.35, -0.3): heater shield in local YZ, face toward local -X (Blender +X).
#   WpnDuelist / WpnMage / WpnSupporter / WpnTrueWarrior   frame = Right Arm * GRIP: along local -Z (Blender -Y), blade width local Y
#                     (Blender Z), flat faces local X.
#   WpnTwinblade      frame = BladeRoot (hub): blade along local -Z, width local Y (edge +Y), curving toward -Y.
# Grips are long enough to show on both sides of the R6 fist (the arm is 1 stud thick), and every guard sits clear of the hand.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"Steel": ((0.62, 0.64, 0.68), 1.0, 0.25), "SteelDark": ((0.12, 0.14, 0.18), 1.0, 0.4), "Crimson": ((0.55, 0.03, 0.03), 0.0, 0.5),
             "Leather": ((0.12, 0.06, 0.03), 0.0, 0.8), "Arcane": ((0.5, 0.15, 1.0), 0.0, 0.5), "Verdant": ((0.15, 0.9, 0.35), 0.0, 0.5),
             "Ivory": ((0.92, 0.88, 0.78), 0.0, 0.5), "Ice": ((0.55, 0.8, 1.0), 0.0, 0.3), "EdgeGlow": ((1.0, 0.6, 0.3), 0.0, 0.5),
             "Gem": ((0.9, 0.05, 0.1), 0.0, 0.1), "WoodDark": ((0.1, 0.05, 0.03), 0.0, 0.8), "MageCloth": ((0.12, 0.05, 0.25), 0.0, 1.0),
             "SupCloth": ((0.1, 0.35, 0.18), 0.0, 1.0)}.items():
    ROLES[k] = v
V = Vector
TAU = math.tau


def hexsec(w, th):
    """Blade section: a flat middle with bevelled edges (x = width, y = thickness)."""
    return [(-w, 0), (-w * 0.45, -th), (w * 0.45, -th), (w, 0), (w * 0.45, th), (-w * 0.45, th)]


def taper(t, tip):
    return 1 - max(0.0, (t - (1 - tip)) / tip) ** 1.35


def blade_z(c, name, role, z0, z1, hw, th, tip=0.2):
    """Blade along Blender Z from z0 to z1, width on Blender X, thickness on Blender Y."""
    pts = [V((0, 0, z0 + (z1 - z0) * i / 16)) for i in range(17)]
    return sweep(name, role, c, pts, lambda t: hexsec(hw * taper(t, tip) + 0.004, th * (1 - 0.5 * max(0, t - 0.7))), smooth=False, hint=(0, 1, 0))


def blade_y(c, name, role, y0, y1, hw, th, tip=0.15, curve=None, section=None):
    """Blade along Blender Y from y0 to y1, width on Blender Z (Roblox local Y), thickness on Blender X. curve(t) bends it along Z."""
    pts = [V((0, y0 + (y1 - y0) * i / 18, curve(i / 18) if curve else 0.0)) for i in range(19)]
    sec = section or hexsec
    return sweep(name, role, c, pts, lambda t: sec(hw * taper(t, tip) + 0.004, th * (1 - 0.5 * max(0, t - 0.7))), smooth=False, hint=(1, 0, 0))


def helix(axis, a0, a1, r, turns, n=80, phase=0.0):
    """A spiral wire along `axis` ('z' or 'y') from a0 to a1."""
    pts = []
    for i in range(n + 1):
        t = i / n
        a = phase + t * turns * TAU
        d = a0 + (a1 - a0) * t
        pts.append(V((math.cos(a) * r, math.sin(a) * r, d)) if axis == "z" else V((math.cos(a) * r, d, math.sin(a) * r)))
    return pts


def ball(c, name, role, r, loc, seg=10):
    prof = [(0, -r)] + [(math.sin(math.pi * k / 6) * r, -math.cos(math.pi * k / 6) * r) for k in range(1, 6)] + [(0, r)]
    return lathe(name, role, c, prof, segments=seg, loc=loc)


def gem(c, name, role, r, h, loc, rot=(0, 0, 0), seg=6):
    o = lathe(name, role, c, [(0, -h), (r, 0), (0, h * 0.8)], segments=seg, loc=loc, smooth=False)
    o.rotation_euler = rot
    return o


def ylathe(c, name, role, profile, y, toward=-1, segments=12, smooth=True):
    """A lathe whose axis runs along Blender Y; profile z grows toward `toward` (-1 = the -Y head end)."""
    o = lathe(name, role, c, profile, segments=segments, loc=(0, y, 0), smooth=smooth)
    o.rotation_euler = (math.radians(90 if toward < 0 else -90), 0, 0)
    return o


# ===================================================================================================================== Warrior
c = collection("WpnWarriorSword")
G0, G1 = -0.55, 0.95  # grip: pommel end, guard end (the fist sits at 0)
sweep("Leather_Grip", "Leather", c, [V((0, 0, G0)), V((0, 0, G1))], lambda t: circle(0.115 + 0.016 * abs(math.sin(t * math.pi * 10)), 10))
sweep("Gold_Wire", "Gold", c, helix("z", G0 + 0.04, G1 - 0.04, 0.128, 6), circle(0.02, 5))
for z in (G0 - 0.02, G1 + 0.02):
    torus("Gold_Collar", "Gold", c, 0.135, 0.04, seg=14, mseg=5, loc=(0, 0, z))
lathe("Gold_Pommel", "Gold", c, [(0, G0 - 0.04), (0.16, G0 - 0.08), (0.23, G0 - 0.24), (0.2, G0 - 0.38), (0.1, G0 - 0.48), (0, G0 - 0.5)], segments=12)
gem(c, "Gem_Pommel", "Gem", 0.09, 0.09, (0, 0, G0 - 0.56))
GZ = G1 + 0.12
box("Gold_GuardBlock", "Gold", c, (0.46, 0.3, 0.26), loc=(0, 0, GZ), bevel=0.05)
for s in (-1, 1):
    pts = [V((s * (0.2 + t * 0.62), 0, GZ + 0.02 + 0.16 * t * t)) for t in [i / 8 for i in range(9)]]
    sweep("Gold_Quillon", "Gold", c, pts, lambda t: [(-0.065, -0.1 * (1 - 0.35 * t)), (0.065, -0.1 * (1 - 0.35 * t)), (0.065, 0.1 * (1 - 0.35 * t)), (-0.065, 0.1 * (1 - 0.35 * t))], smooth=False, hint=(0, 1, 0))
    ball(c, "GoldPale_Finial", "GoldPale", 0.1, tuple(pts[-1] + V((s * 0.05, 0, 0.02))))
    gem(c, "Gem_Guard", "Gem", 0.09, 0.05, (0, s * 0.16, GZ), rot=(math.radians(90), 0, 0))
BZ0 = GZ + 0.12
lathe("Steel_Ricasso", "Steel", c, [(0.0, BZ0 - 0.02), (0.16, BZ0 - 0.02), (0.2, BZ0 + 0.08), (0, BZ0 + 0.1)], segments=8, smooth=False)
blade_z(c, "Steel_Blade", "Steel", BZ0, BZ0 + 3.25, 0.24, 0.055, tip=0.2)
for s in (-1, 1):
    sweep("Crimson_Fuller", "Crimson", c, [V((0, s * 0.057, BZ0 + 0.25)), V((0, s * 0.057, BZ0 + 2.35))], [(-0.03, -0.008), (0.03, -0.008), (0.03, 0.008), (-0.03, 0.008)], smooth=False)

c = collection("WpnWarriorShield")
lathe("Crimson_Face", "Crimson", c, [(0, 0.2), (1.26, 0.12), (1.3, 0.0), (0, 0.0)], segments=32)
torus("Gold_Rim", "Gold", c, 1.36, 0.12, seg=40, mseg=6, scale_minor=(1, 1.3))
lathe("Gold_Boss", "Gold", c, [(0, 0.2), (0.38, 0.2), (0.3, 0.42), (0.12, 0.52), (0, 0.54)], segments=16)
lathe("Gem_Boss", "Gem", c, [(0, 0.5), (0.13, 0.55), (0, 0.66)], segments=6, smooth=False)
box("Gold_CrossV", "Gold", c, (0.18, 0.08, 2.4))
box("Gold_CrossH", "Gold", c, (2.4, 0.08, 0.18))
lathe("Wood_Back", "Wood", c, [(0, -0.02), (1.3, -0.02), (1.3, -0.14), (0, -0.14)], segments=24)
for k in range(8):
    a = k / 8 * TAU + math.pi / 8
    lathe(f"GoldPale_Rivet{k}", "GoldPale", c, [(0, 0.12), (0.09, 0.14), (0, 0.22)], segments=6, loc=(math.cos(a) * 1.1, math.sin(a) * 1.1, 0))
for o in list(c.objects):
    if o.name.startswith("Gold_Cross"):
        o.rotation_euler = (math.radians(90), 0, 0)
        o.location = (0, 0, 0.18)
for o in list(c.objects):
    o.location = Matrix.Rotation(math.radians(-90), 4, "Y") @ o.location
    o.rotation_euler = (Matrix.Rotation(math.radians(-90), 4, "Y") @ o.rotation_euler.to_matrix().to_4x4()).to_euler()

# ===================================================================================================================== Tank
c = collection("WpnTankSword")
P0, P1 = 0.72, -0.95  # pommel end, guard end of the grip (the blade runs down -Z)
sweep("Leather_Grip", "Leather", c, [V((0, 0, P0)), V((0, 0, P1))], lambda t: circle(0.125 + 0.018 * abs(math.sin(t * math.pi * 9)), 10))
for z in (0.45, 0.1, -0.25, -0.6):
    torus("Gold_GripRing", "Gold", c, 0.14, 0.032, seg=14, mseg=5, loc=(0, 0, z))
lathe("Gold_Pommel", "Gold", c, [(0, P0), (0.2, P0 + 0.04), (0.3, P0 + 0.2), (0.26, P0 + 0.36), (0.14, P0 + 0.46), (0, P0 + 0.48)], segments=12)
torus("GoldPale_PommelBand", "GoldPale", c, 0.29, 0.04, seg=16, mseg=5, loc=(0, 0, P0 + 0.2))
gem(c, "Ice_Gem", "Ice", 0.13, 0.12, (0, 0, P0 + 0.56))
GZ = P1 - 0.1
box("Gold_GuardBlock", "Gold", c, (0.28, 0.56, 0.36), loc=(0, 0, GZ), bevel=0.06)
for s in (-1, 1):
    pts = [V((0, s * (0.26 + t * 0.7), GZ - 0.02 - 0.26 * t * t)) for t in [i / 8 for i in range(9)]]
    sweep("Gold_Quillon", "Gold", c, pts, lambda t: circle(0.095 * (1 - t * 0.3), 8))
    ball(c, "GoldPale_Finial", "GoldPale", 0.15, tuple(pts[-1]))
    gem(c, "Ice_GuardGem", "Ice", 0.1, 0.06, (s * 0.15, 0, GZ), rot=(0, math.radians(90 * s), 0))
BZ = GZ - 0.18
b = blade_z(c, "Steel_Blade", "Steel", BZ, BZ - 3.2, 0.29, 0.065, tip=0.2)
b.rotation_euler = (0, 0, math.radians(90))  # width onto Blender Y (Roblox local Z)
box("SteelDark_Ricasso", "SteelDark", c, (0.16, 0.6, 0.3), loc=(0, 0, BZ + 0.05), bevel=0.03)
for s in (-1, 1):
    sweep("Ice_Rune", "Ice", c, [V((s * 0.068, 0, BZ - 0.3)), V((s * 0.068, 0, BZ - 2.2))], [(-0.008, -0.025), (0.008, -0.025), (0.008, 0.025), (-0.008, 0.025)], smooth=False, hint=(0, 1, 0))
    for k in range(3):
        box("Ice_RuneMark", "Ice", c, (0.016, 0.14, 0.05), loc=(s * 0.068, 0, BZ - 0.5 - k * 0.6))

c = collection("WpnTankShield")
TOP, SHOULDER, TIP, HALF, CY = 2.6, 1.1, -1.9, 1.55, 1.3


def hw_at(y):
    if y >= SHOULDER:
        return HALF
    t = min(1, max(0, (SHOULDER - y) / (SHOULDER - TIP)))
    return HALF * (1 - t ** 1.5)


side = [(hw_at(TOP - (TOP - TIP) * i / 24), TOP - (TOP - TIP) * i / 24) for i in range(25)]
outline = [(-x, y) for x, y in side[:-1]] + [(0.0, TIP)] + [(x, y) for x, y in reversed(side[:-1])]


def heater(name, role, pts, x0, x1):
    o = slab2d(name, role, c, pts, x0, x1)
    o.data.transform(Matrix.Rotation(math.radians(-90), 4, "Z"))  # XZ plane -> YZ plane, depth y0..y1 -> Blender X
    return o


def clip(poly, axis, val, keep_greater):
    out = []
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        ina = a[axis] >= val if keep_greater else a[axis] <= val
        inb = b[axis] >= val if keep_greater else b[axis] <= val
        if ina:
            out.append(a)
        if ina != inb:
            t = (val - a[axis]) / (b[axis] - a[axis])
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return out


heater("SteelDark_Back", "SteelDark", outline, -0.2, -0.03)
inner = [(x * 0.9, (y - 0.35) * 0.93 + 0.35) for x, y in outline]
for qx, qy, role in ((False, True, "Blue"), (True, True, "Crimson"), (False, False, "Crimson"), (True, False, "Blue")):
    heater(f"{role}_Field", role, clip(clip(inner, 0, 0.0, qx), 1, CY, qy), -0.04, 0.12)
sweep("Gold_Rim", "Gold", c, [V((0, x, y)) for x, y in outline], [(-0.17, -0.23), (0.17, -0.23), (0.18, 0.18), (0.1, 0.3), (-0.1, 0.3), (-0.18, 0.18)],
      closed_path=True, smooth=False, hint=(1, 0, 0))


def cross(w, f, fl, up, dn, r):
    return [(-w, CY + w), (-w, up - fl), (-f, up), (f, up), (w, up - fl), (w, CY + w), (r - fl, CY + w), (r, CY + f), (r, CY - f), (r - fl, CY - w),
            (w, CY - w), (w, dn + fl), (f, dn), (-f, dn), (-w, dn + fl), (-w, CY - w), (-r + fl, CY - w), (-r, CY - f), (-r, CY + f), (-r + fl, CY + w)]


UP, DN, ARM = TOP - 0.32, -0.75, 1.18
heater("Steel_CrossBorder", "Steel", cross(0.33, 0.43, 0.26, UP + 0.02, DN - 0.04, ARM + 0.04), 0.1, 0.24)
heater("Gold_Cross", "Gold", cross(0.21, 0.32, 0.24, UP - 0.04, DN + 0.02, ARM - 0.02), 0.22, 0.37)
box("Ice_InlayV", "Ice", c, (0.03, 0.08, UP - DN - 0.7), loc=(0.375, 0, (UP + DN) / 2))
box("Ice_InlayH", "Ice", c, (0.03, 2 * ARM - 0.7, 0.08), loc=(0.375, 0, CY))
for a in (45, -45):
    box("Ice_Diagonal", "Ice", c, (0.04, 0.09, 2.5), loc=(0.15, 0, CY), rot=(math.radians(a), 0, 0))
torus("Gold_GemRing", "Gold", c, 0.42, 0.09, seg=24, mseg=6, loc=(0.42, 0, CY), rot=(0, math.radians(90), 0))
lathe("SteelDark_Socket", "SteelDark", c, [(0, 0.0), (0.36, 0.0), (0.34, 0.1), (0, 0.12)], segments=16, loc=(0.36, 0, CY)).rotation_euler = (0, math.radians(90), 0)
gem(c, "Ice_Gem", "Ice", 0.28, 0.3, (0.5, 0, CY), rot=(0, math.radians(90), 0), seg=8)
for s in (-1, 1):
    ball(c, "GoldPale_Corner", "GoldPale", 0.2, (0.18, s * (HALF - 0.05), TOP - 0.05))
    for y in (2.15, 1.6):
        lathe("GoldPale_Rivet", "GoldPale", c, [(0, 0), (0.08, 0.02), (0, 0.09)], segments=6, loc=(0.29, s * (HALF - 0.02), y)).rotation_euler = (0, math.radians(90), 0)
for i in range(3, 22, 3):
    x, y = side[i]
    if y < SHOULDER - 0.05:
        for s in (-1, 1):
            lathe("GoldPale_Rivet", "GoldPale", c, [(0, 0), (0.08, 0.02), (0, 0.09)], segments=6, loc=(0.29, s * x, y)).rotation_euler = (0, math.radians(90), 0)
for x in (-0.8, 0.0, 0.8):
    lathe("GoldPale_Rivet", "GoldPale", c, [(0, 0), (0.08, 0.02), (0, 0.09)], segments=6, loc=(0.29, x, TOP - 0.02)).rotation_euler = (0, math.radians(90), 0)
lathe("Gold_TipBoss", "Gold", c, [(0, -0.3), (0.2, -0.2), (0.24, 0.05), (0.14, 0.26), (0, 0.3)], segments=10, loc=(0.12, 0, TIP + 0.2))
for z in (0.0, 1.0):
    box("Leather_Strap", "Leather", c, (0.1, 1.25, 0.26), loc=(-0.27, 0.3, z), bevel=0.02)
    box("Gold_Buckle", "Gold", c, (0.06, 0.2, 0.3), loc=(-0.33, 0.3 - 0.66, z))

# ===================================================================================================================== Duelist
c = collection("WpnDuelist")
sweep("Leather_Grip", "Leather", c, [V((0, 0.32, 0)), V((0, -0.42, 0))], lambda t: circle(0.085 + 0.012 * abs(math.sin(t * math.pi * 7)), 10))
sweep("Gold_Wire", "Gold", c, helix("y", 0.28, -0.38, 0.095, 5), circle(0.016, 4))
ylathe(c, "Steel_Pommel", "Steel", [(0, 0), (0.12, 0.02), (0.17, 0.12), (0.12, 0.22), (0, 0.25)], 0.32, toward=1, segments=12)
gem(c, "Crimson_PommelGem", "Crimson", 0.06, 0.06, (0, 0.62, 0), rot=(math.radians(-90), 0, 0))
cup = ylathe(c, "Steel_Cup", "Steel", [(0.07, 0.0), (0.3, 0.02), (0.44, 0.12), (0.47, 0.24), (0.43, 0.27), (0.39, 0.16), (0.27, 0.08), (0.06, 0.05)], -0.5, toward=1, segments=24)
torus("Gold_CupRim", "Gold", c, 0.455, 0.035, seg=28, mseg=5, loc=(0, -0.24, 0), rot=(math.radians(90), 0, 0))
QY = -0.62
box("SteelDark_GuardBlock", "SteelDark", c, (0.26, 0.2, 0.24), loc=(0, QY, 0), bevel=0.04)
for s in (-1, 1):
    pts = [V((s * (0.12 + t * 0.6), QY - s * 0.28 * t ** 2.4, 0)) for t in [i / 10 for i in range(11)]]
    sweep("Gold_Quillon", "Gold", c, pts, lambda t: circle(0.045 * (1 - 0.3 * t), 6))
    ball(c, "Gold_QuillonEnd", "Gold", 0.075, tuple(pts[-1]))
    torus("Gold_SideRing", "Gold", c, 0.16, 0.026, seg=14, mseg=4, loc=(s * 0.17, QY - 0.18, 0), rot=(0, 0, 0))
bow = [V((0, QY + 0.02, -0.12)), V((0, QY - 0.06, -0.38)), V((0, QY + 0.08, -0.6)), V((0, -0.3, -0.66)), V((0, 0.0, -0.62)), V((0, 0.22, -0.5)),
       V((0, 0.33, -0.3)), V((0, 0.36, -0.14))]
sweep("Gold_KnuckleBow", "Gold", c, bow, lambda t: circle(0.038, 6))
blade_y(c, "Steel_Blade", "Steel", QY - 0.08, -5.45, 0.09, 0.034, tip=0.1)
box("SteelDark_Ricasso", "SteelDark", c, (0.09, 0.32, 0.2), loc=(0, QY - 0.24, 0), bevel=0.02)
for s in (-1, 1):
    sweep("Ice_Edge", "Ice", c, [V((s * 0.036, -0.95, 0)), V((s * 0.03, -4.6, 0))], [(-0.005, -0.015), (0.005, -0.015), (0.005, 0.015), (-0.005, 0.015)], smooth=False, hint=(0, 0, 1))
ball(c, "Glow_TipGlint", "Glow", 0.05, (0, -5.47, 0), seg=6)

# ===================================================================================================================== staffs


def staff_base(name, shaft_role, cloth, foot, top, knotty):
    c = collection(name)
    if knotty:
        sec = lambda t: circle(0.105 + 0.014 * math.sin(t * 41) + 0.03 * math.exp(-((t - 0.58) * 26) ** 2) + 0.025 * math.exp(-((t - 0.82) * 30) ** 2), 9)
    else:
        sec = lambda t: circle(0.1 - 0.012 * t, 12)
    sweep(f"{shaft_role}_Shaft", shaft_role, c, [V((0, foot - 0.1 - (foot - top) * i / 24, 0)) for i in range(25)], sec)
    sweep(f"{cloth}_Grip", cloth, c, [V((0, 0.56, 0)), V((0, -0.56, 0))], lambda t: circle(0.14 + 0.014 * abs(math.sin(t * math.pi * 8)), 10))
    for y in (0.6, -0.6):
        torus("Gold_GripCap", "Gold", c, 0.15, 0.04, seg=14, mseg=5, loc=(0, y, 0), rot=(math.radians(90), 0, 0))
    ylathe(c, "Gold_Foot", "Gold", [(0, 0.0), (0.13, 0.0), (0.15, 0.18), (0.1, 0.3), (0, 0.42)], foot - 0.16, toward=1, segments=10)
    return c


# Mage: a gnarled dark staff ending in a gold crescent of horns that cradles the arcane crystal, with a gold wire twisting up to it.
FOOT, TOP, ZC = 1.62, -3.95, -4.8
c = staff_base("WpnMage", "WoodDark", "MageCloth", FOOT, TOP, True)
sweep("Gold_Wire", "Gold", c, helix("y", -1.0, TOP + 0.05, 0.12, 3.2), circle(0.022, 5))
torus("Gold_Band", "Gold", c, 0.14, 0.04, seg=14, mseg=5, loc=(0, -1.6, 0), rot=(math.radians(90), 0, 0))
ylathe(c, "Gold_Collar", "Gold", [(0, -0.05), (0.15, 0.0), (0.2, 0.12), (0.15, 0.22), (0.24, 0.36), (0.3, 0.5), (0.2, 0.6), (0, 0.6)], TOP, toward=-1, segments=14)
for s in (-1, 1):
    horn = [V((s * (0.2 * (1 - t) + 0.07 * t + 0.62 * math.sin(math.pi * t ** 0.9)), TOP - 0.5 - 1.15 * t, 0)) for t in [i / 16 for i in range(17)]]
    sweep("Gold_Horn", "Gold", c, horn, lambda t: circle(0.09 * (1 - 0.65 * t) + 0.01, 8))
    barb = [horn[6] + V((s * 0.32 * t, 0.12 * t - 0.05 * t * t, 0)) for t in [i / 6 for i in range(7)]]
    sweep("Gold_Barb", "Gold", c, barb, lambda t: circle(0.05 * (1 - 0.7 * t) + 0.008, 6))
    gem(c, "Arcane_HornTip", "Arcane", 0.06, 0.07, tuple(horn[-1] + V((0, -0.04, 0))), rot=(math.radians(90), 0, 0))
    small = [V((0, TOP - 0.5 - 0.85 * t, s * (0.15 * (1 - t) + 0.05 * t + 0.4 * math.sin(math.pi * t ** 0.9)))) for t in [i / 12 for i in range(13)]]
    sweep("GoldDeep_Prong", "GoldDeep", c, small, lambda t: circle(0.06 * (1 - 0.6 * t) + 0.008, 6))
crys = lathe("Arcane_Crystal", "Arcane", c, [(0, -0.62), (0.22, -0.38), (0.32, -0.05), (0.27, 0.2), (0, 0.5)], segments=6, loc=(0, ZC, 0), smooth=False)
crys.rotation_euler = (math.radians(90), 0, 0)
torus("GoldPale_Orbit", "GoldPale", c, 0.6, 0.03, seg=28, mseg=4, loc=(0, ZC, 0), rot=(math.radians(68), math.radians(24), 0))
for k in range(6):
    a = k * 1.7
    gem(c, "Arcane_Rune", "Arcane", 0.035, 0.07, (math.cos(a) * 0.115, -1.9 - k * 0.3, math.sin(a) * 0.115), rot=(math.radians(90), 0, a))

# Supporter: an ivory staff with a gold vine, crowned by a sun halo with rays and small wings, a healing crystal held in its centre.
FOOT, TOP, HC = 1.62, -3.75, -4.55
c = staff_base("WpnSupporter", "Ivory", "SupCloth", FOOT, TOP, False)
sweep("Verdant_Vine", "Verdant", c, helix("y", -0.75, TOP + 0.1, 0.108, 2.6, phase=1.0), circle(0.018, 4))
for k in range(9):
    t = k / 8
    a = 1.0 + t * 2.6 * TAU
    y = -0.75 + (TOP + 0.1 + 0.75) * t
    leaf = blade("Gold_Leaf", "GoldPale", c, (0, 0), 0, 0.0, 0.2, 0.05, 0.0, depth=0.02)
    leaf.location = (math.cos(a) * 0.11, y, math.sin(a) * 0.11)
    leaf.rotation_euler = (0, -a + math.radians(90), math.radians(35))
for y in (-0.95, -2.1, TOP + 0.25):
    torus("Gold_Band", "Gold", c, 0.12, 0.035, seg=14, mseg=5, loc=(0, y, 0), rot=(math.radians(90), 0, 0))
ylathe(c, "Gold_Collar", "Gold", [(0, -0.05), (0.13, 0.0), (0.2, 0.1), (0.14, 0.2), (0.12, 0.3), (0, 0.32)], TOP, toward=-1, segments=12)
R = 0.62
torus("Gold_Halo", "Gold", c, R, 0.075, seg=40, mseg=8, loc=(0, HC, 0))
torus("GoldPale_HaloInner", "GoldPale", c, R - 0.13, 0.025, seg=36, mseg=4, loc=(0, HC, 0))
rays = []
for k in range(12):
    a = k / 12 * TAU + math.pi / 12
    long = k % 2 == 0
    rays.append(blade("Gold_Ray" if long else "GoldPale_Ray", "Gold" if long else "GoldPale", c, (0, -HC), a, R + 0.05, R + (0.42 if long else 0.24), 0.07, 0.0, depth=0.06))
for s in (-1, 1):
    for k, (ang, ln) in enumerate(((8, 0.85), (28, 0.78), (48, 0.62), (66, 0.44))):
        a = math.radians(ang if s > 0 else 180 - ang)
        rays.append(blade("Ivory_Feather" if k % 2 else "GoldPale_Feather", "Ivory" if k % 2 else "GoldPale", c, (s * (R + 0.04), -HC + 0.05), a, 0.0, ln, 0.1, 0.02, depth=0.05))
for o in rays:
    o.rotation_euler = (math.radians(90), 0, 0)  # XZ outline -> the halo's XY plane (z -> -y)
cry = lathe("Verdant_Crystal", "Verdant", c, [(0, -0.4), (0.19, -0.1), (0.17, 0.14), (0, 0.42)], segments=8, loc=(0, HC, 0), smooth=False)
cry.rotation_euler = (math.radians(90), 0, 0)
for s in (-1, 1):
    sweep("GoldPale_Spoke", "GoldPale", c, [V((s * 0.17, HC, 0)), V((s * (R - 0.06), HC, 0))], circle(0.022, 5))

# ===================================================================================================================== True Warrior
c = collection("WpnTrueWarrior")
sweep("Leather_Grip", "Leather", c, [V((0, 0.66, 0)), V((0, -0.6, 0))], lambda t: circle(0.12 + 0.016 * abs(math.sin(t * math.pi * 10)), 10))
for k in range(6):
    o = box("Gold_Wrap" if k % 2 == 0 else "GoldDeep_Wrap", "Gold" if k % 2 == 0 else "GoldDeep", c, (0.2, 0.06, 0.2), loc=(0, -0.45 + k * 0.2, 0))
    o.rotation_euler = (0, math.radians(45), 0)
for y in (-0.62, 0.68):
    torus("Gold_Ferrule", "Gold", c, 0.15, 0.045, seg=14, mseg=5, loc=(0, y, 0), rot=(math.radians(90), 0, 0))
ylathe(c, "Gold_Pommel", "Gold", [(0, 0), (0.18, 0.03), (0.25, 0.18), (0.18, 0.34), (0, 0.38)], 0.72, toward=1, segments=12)
gem(c, "Neon_PommelGem", "Neon", 0.1, 0.1, (0, 1.16, 0), rot=(math.radians(-90), 0, 0))
GY = -0.84
box("Gold_GuardBlock", "Gold", c, (0.36, 0.34, 0.66), loc=(0, GY, 0), bevel=0.07)
for s in (-1, 1):
    gem(c, "Neon_GuardGem", "Neon", 0.13, 0.08, (s * 0.2, GY, 0), rot=(0, math.radians(90 * s), 0))
    wing = [V((0, GY - 0.02 - 0.42 * t ** 2.2, s * (0.3 + 0.95 * math.sin(t * math.pi / 2)))) for t in [i / 12 for i in range(13)]]
    sweep("Gold_Wing", "Gold", c, wing, lambda t: [(-0.11 * (1 - 0.4 * t), -0.16 * (1 - 0.3 * t)), (0.11 * (1 - 0.4 * t), -0.16 * (1 - 0.3 * t)),
                                                      (0.11 * (1 - 0.4 * t), 0.16 * (1 - 0.3 * t)), (-0.11 * (1 - 0.4 * t), 0.16 * (1 - 0.3 * t))], smooth=False, hint=(1, 0, 0))
    gem(c, "Neon_WingGem", "Neon", 0.1, 0.1, tuple(wing[-1] + V((0, -0.06, s * 0.04))), rot=(math.radians(90), 0, 0))
    for k in range(3):
        f = blade("GoldPale_Plume", "GoldPale", c, (0, 0), 0, 0.0, 0.5 - k * 0.1, 0.07, 0.0, depth=0.05)
        p = wing[4 + k * 3]
        f.location = (0, p.y + 0.02, p.z)
        f.rotation_mode = "ZYX"  # Z first: the plume (+X) turns onto +Y, then X swings it outward in the wing's plane
        f.rotation_euler = (s * math.radians(25 + k * 22), 0, math.radians(90))
blade_y(c, "Steel_Blade", "Steel", GY - 0.1, -5.35, 0.3, 0.075, tip=0.16)
box("GoldDeep_Ricasso", "GoldDeep", c, (0.17, 0.4, 0.5), loc=(0, GY - 0.3, 0), bevel=0.03)
for s in (-1, 1):
    sweep("Neon_Fuller", "Neon", c, [V((s * 0.077, -1.25, 0)), V((s * 0.075, -4.3, 0))], [(-0.008, -0.035), (0.008, -0.035), (0.008, 0.035), (-0.008, 0.035)], smooth=False, hint=(0, 0, 1))
    sweep("GoldPale_Edge", "GoldPale", c, [V((0, -1.1, s * 0.29)), V((0, -4.55, s * 0.27))], circle(0.02, 4))

# ===================================================================================================================== Twinblade
c = collection("WpnTwinblade")
sweep("Leather_Grip", "Leather", c, [V((0, 0.5, 0)), V((0, -0.5, 0))], lambda t: circle(0.095 + 0.014 * abs(math.sin(t * math.pi * 8)), 10))
for k in range(4):
    o = box("SteelDark_Wrap", "SteelDark", c, (0.18, 0.05, 0.18), loc=(0, -0.33 + k * 0.24, 0))
    o.rotation_euler = (0, math.radians(45), 0)
ylathe(c, "Gold_Pommel", "Gold", [(0, 0), (0.12, 0.03), (0.15, 0.12), (0.1, 0.2), (0, 0.22)], 0.52, toward=1, segments=10)
torus("Gold_Guard", "Gold", c, 0.32, 0.06, seg=22, mseg=6, loc=(0, -0.56, 0), rot=(math.radians(90), 0, 0))
lathe("SteelDark_GuardPlate", "SteelDark", c, [(0, 0), (0.3, 0), (0.3, 0.06), (0, 0.06)], segments=16, loc=(0, -0.53, 0)).rotation_euler = (math.radians(90), 0, 0)
gem(c, "EdgeGlow_Gem", "EdgeGlow", 0.08, 0.06, (0.07, -0.6, 0), rot=(0, math.radians(90), 0))
box("Gold_Collar", "Gold", c, (0.13, 0.12, 0.36), loc=(0, -0.66, 0.02), bevel=0.02)
BEND = math.radians(1.7)


def bend(t):
    return -((t * 6) ** 2) * 0.62 * math.sin(BEND) * 0.6


def katana(w, th):
    """Single-edged: thick spine on -x (Roblox -Y), sharp edge on +x."""
    return [(-w, -th), (w * 0.25, -th * 0.75), (w, 0), (w * 0.25, th * 0.75), (-w, th)]


blade_y(c, "Steel_Blade", "Steel", -0.7, -4.95, 0.17, 0.04, tip=0.13, curve=bend, section=katana)
pts = [V((0, -0.8 - 3.85 * t, bend((0.1 + 3.85 * t) / 4.25) + 0.17 * (1 - max(0, (t - 0.87) / 0.13) ** 1.35))) for t in [i / 14 for i in range(15)]]
sweep("EdgeGlow_Edge", "EdgeGlow", c, pts, circle(0.024, 4))
pts = [V((0, -0.8 - 3.6 * t, bend((0.1 + 3.6 * t) / 4.25) - 0.17)) for t in [i / 12 for i in range(13)]]
sweep("SteelDark_Spine", "SteelDark", c, pts, circle(0.03, 4))

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith("Wpn")})
