# The Golden Hand (P1.5 GoldenHand, also reused by P3 PickThePupils' giant hand) for the boss place.
# Roblox local (x, y, z) = Blender (-x, z, y). The code's hand frame: palm centred on the origin, fingers rise along Roblox +Y (Blender +Z),
# the grabbing face looks along Roblox -Z (Blender -Y), the armoured back is Roblox +Z (Blender +Y), the cuff hangs below (Blender -Z).
#   HandPalm   palm shell + armoured back + knuckle caps + thumb base + wrist cuff (8 wide, 8 tall, 2.4 thick, cuff down to z = -6.6).
#   HandProx / HandMid / HandDist   one finger bone each, origin = the joint, bone along +Z, length 1 and diameter 1 (code scales to the
#                                   finger's Length and Diameter); HandDist ends in a curved claw (curls toward -Y, the palm side).
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
V = Vector


def sphere(c, name, role, r, loc, scale=(1, 1, 1)):
    prof = [(0, -r)] + [(math.sin(math.pi * k / 8) * r, -math.cos(math.pi * k / 8) * r) for k in range(1, 8)] + [(0, r)]
    o = lathe(name, role, c, prof, segments=14, loc=loc)
    o.scale = scale
    return o


# =====================================================================================================================
c = collection("HandPalm")
box("Gold_PalmShell", "Gold", c, (7.6, 2.0, 7.4), loc=(0, -0.15, 0.2), bevel=0.5)
box("GoldDeep_Back", "GoldDeep", c, (7.0, 0.7, 6.6), loc=(0, 1.3, 0.4), bevel=0.22)
for x in (-2.2, 0.0, 2.2):
    box("GoldPale_BackRidge", "GoldPale", c, (0.5, 0.35, 5.6), loc=(x, 1.78, 0.3), bevel=0.1)
box("GoldPale_BackCrest", "GoldPale", c, (6.4, 0.3, 0.45), loc=(0, 1.72, 3.3), bevel=0.08)
torus("GoldPale_GemRing", "GoldPale", c, 1.35, 0.22, seg=28, mseg=8, loc=(0, -1.18, -0.6), rot=(math.pi / 2, 0, 0))
for k in range(8):  # prongs holding the gem
    a = k / 8 * math.tau
    box("Gold_GemProng", "Gold", c, (0.22, 0.4, 0.5), loc=(math.cos(a) * 1.35, -1.3, -0.6 + math.sin(a) * 1.35), rot=(0, -a, 0), bevel=0.04)
for x in (-3.0, -1.0, 1.0, 3.0):  # a knuckle cap at each finger's root
    sphere(c, "GoldDeep_Knuckle", "GoldDeep", 0.98, (x, 0.0, 3.75), (1, 1.05, 0.85))
sphere(c, "GoldDeep_ThumbBase", "GoldDeep", 1.7, (3.8, -0.3, -1.3), (1.0, 0.95, 1.3))
# wrist cuff: a swelling ring with fins
lathe("GoldDeep_Cuff", "GoldDeep", c, [(2.7, -4.0), (3.25, -4.1), (3.35, -4.6), (3.0, -5.3), (3.35, -6.0), (3.25, -6.5), (2.7, -6.6)], segments=28)
torus("GoldPale_CuffRingTop", "GoldPale", c, 3.35, 0.16, seg=28, mseg=6, loc=(0, 0, -4.05))
torus("GoldPale_CuffRingLow", "GoldPale", c, 3.35, 0.16, seg=28, mseg=6, loc=(0, 0, -6.55))
for k in range(6):
    a = k / 6 * math.tau + 0.26
    box("Gold_CuffFin", "Gold", c, (1.1, 0.3, 2.6), loc=(math.cos(a) * 3.7, math.sin(a) * 3.7, -5.3), rot=(0, 0, a), bevel=0.06)
for k in range(3):  # studs along the cuff
    a = k / 3 * math.tau
    sphere(c, "GoldPale_CuffStud", "GoldPale", 0.28, (math.cos(a + 0.9) * 3.1, math.sin(a + 0.9) * 3.1, -5.3))


# =====================================================================================================================
def shaft(c, name, role, r0, r1, z0, z1, n=6):
    pts = [V((0, 0, z0 + (z1 - z0) * i / n)) for i in range(n + 1)]
    return sweep(name, role, c, pts, lambda t: circle(r0 + (r1 - r0) * t, 10, 1.0, 0.95), smooth=True)


def phalanx(name, plate, taper_to, claw=False):
    c = collection(name)
    sphere(c, "GoldDeep_Joint", "GoldDeep", 0.57, (0, 0, 0))
    if claw:
        shaft(c, "Gold_Shaft", "Gold", 0.49, 0.36, 0.05, 0.72)
        # a curved claw: the tip bends toward -Y (the palm), sharp at the end
        pts = [V((0, -0.34 * (t ** 2), 0.62 + 0.58 * t)) for t in [i / 8 for i in range(9)]]
        sweep("GoldPale_Claw", "GoldPale", c, pts, lambda t: circle(max(0.34 * (1 - t) ** 0.8, 0.02), 8, 1.0, 0.9))
        box("GoldDeep_Nail", "GoldDeep", c, (0.5, 0.12, 0.5), loc=(0, 0.33, 0.52), bevel=0.04)
    else:
        shaft(c, "Gold_Shaft", "Gold", 0.49, taper_to, 0.05, 0.97)
        box("GoldPale_Plate", "GoldPale", c, (0.56, 0.14, plate), loc=(0, 0.47, 0.18 + plate * 0.5), bevel=0.05)
        sphere(c, "GoldDeep_Guard", "GoldDeep", 0.42, (0, 0.0, 1.0), (1.05, 1.0, 0.6))
    return c


phalanx("HandProx", 0.7, 0.42)
phalanx("HandMid", 0.5, 0.4)
phalanx("HandDist", 0, 0, claw=True)

print({x.name: len(x.objects) for x in bpy.data.collections if x.name.startswith("Hand")})
