# Figures sculpted from metaballs. Front = -Y.
#   Kneeler        a person turned to gold, on their knees with their arms thrown up before their face. Origin = ground centre. ~6 tall.
#   Bro*           the brothers' jointed body, one piece per segment, each with its origin at the joint it turns about:
#     BroPelvis    origin = waist. Hips at (+-0.65, 0, -0.5).
#     BroTorso     origin = waist; chest, neck, head. Shoulders at (+-1.05, 0, 2.6).
#     BroUpperArm  origin = shoulder, hangs down -Z to the elbow at z -1.9.
#     BroForearm   origin = elbow, down to the fist centred at z -2.05.
#     BroThigh     origin = hip, down to the knee at z -2.4.
#     BroShin      origin = knee, down to the ankle at z -2.3; the foot points -Y.
#     BroSword     origin = the fist (grip centre); the blade points -Y.
# Roles: Body (recoloured per brother), Sash, Blade.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
ROLES["Sash"] = ((0.6, 0.05, 0.05), 0.0, 0.8)
ROLES["Blade"] = ((0.85, 0.85, 0.88), 1.0, 0.2)
V = Vector
FAT = 1.45


def fat(elements):
    return [(k, co, r * FAT, extra) for k, co, r, extra in elements]


def ball(co, r):
    return ("BALL", tuple(co), r, None)


def ell(co, r, sx, sy, sz, rot=(0, 0, 0)):
    return ("ELLIPSOID", tuple(co), r, (sx, sy, sz, rot))


# =====================================================================================================================
kn = collection("Kneeler")
J = {
    "pelvis": V((0, 0.2, 2.3)), "chest": V((0, -0.35, 3.9)), "neck": V((0, -0.65, 4.6)), "head": V((0, -0.95, 5.15)),
}
els = [
    ell(J["pelvis"], 0.95, 1.0, 0.75, 0.6),
    capsule(J["pelvis"], J["chest"], 0.75),
    ell(J["chest"], 1.0, 1.05, 0.7, 0.75, (0.35, 0, 0)),
    capsule(J["chest"], J["neck"], 0.32),
    ell(J["head"], 0.62, 0.85, 0.95, 1.05, (0.3, 0, 0)),
]
for sx in (-1, 1):
    hip = V((sx * 0.55, 0.2, 2.2))
    knee = V((sx * 0.62, -1.1, 0.45))
    ankle = V((sx * 0.55, 1.0, 0.35))
    toe = V((sx * 0.5, 1.7, 0.18))
    els += [capsule(hip, knee, 0.45), capsule(knee, ankle, 0.36), capsule(ankle, toe, 0.22)]
    sh = V((sx * 0.95, -0.45, 4.25))
    el = V((sx * 1.25, -1.45, 4.65))
    hand = V((sx * 0.45, -1.55, 5.55))
    els += [ball(sh, 0.5), capsule(sh, el, 0.3), capsule(el, hand, 0.26), ell(hand + V((0, -0.05, 0.15)), 0.3, 0.7, 0.5, 1.0)]
fig = sculpt("Gold_Kneeler", "Gold", kn, fat(els), resolution=0.12, threshold=0.25)
decimate(fig, 0.5)
solid(lathe("MarbleDark_Plinth", "MarbleDark", kn, [(0, -0.01), (2.6, -0.01), (2.6, 0.2), (0, 0.2)], segments=24)).location.z = -0.2

# =====================================================================================================================
def piece(name, elements, role="Body", res=0.1, extra=None):
    col = collection(name)
    o = sculpt(f"{role}_{name}", role, col, fat(elements), resolution=res, threshold=0.25)
    decimate(o, 0.45)
    if extra:
        extra(col)
    return col


piece("BroPelvis", [ell((0, 0, -0.25), 0.95, 1.05, 0.72, 0.62), ball((0.65, 0, -0.55), 0.55), ball((-0.65, 0, -0.55), 0.55)],
      extra=lambda c: torus("Sash_Belt", "Sash", c, 0.98, 0.16, seg=32, mseg=6, loc=(0, 0, 0.05), scale_minor=(1, 1.6)))


def torso_extra(c):
    # a sash across the chest, and a topknot
    path = [V((-0.95, -0.05, 0.4)).lerp(V((0.95, -0.05, 2.5)), t) + V((0, -0.62 - 0.12 * math.sin(t * math.pi), 0)) for t in [i / 10 for i in range(11)]]
    sweep("Sash_Strap", "Sash", c, path, [(-0.22, -0.06), (0.22, -0.06), (0.22, 0.06), (-0.22, 0.06)], smooth=False)
    lathe("Body_Topknot", "Body", c, [(0, 0), (0.28, 0.05), (0.32, 0.4), (0.18, 0.7), (0, 0.78)], segments=10, loc=(0, 0.2, 4.25))


piece("BroTorso", [
    ell((0, 0, 0.35), 0.9, 0.95, 0.7, 0.55),
    capsule((0, 0, 0.3), (0, 0, 2.0), 0.85),
    ell((0, 0, 2.05), 1.05, 1.15, 0.72, 0.7),
    ball((1.05, 0, 2.55), 0.52), ball((-1.05, 0, 2.55), 0.52),
    capsule((0, 0, 2.6), (0, -0.05, 3.3), 0.36),
    ell((0, -0.08, 3.9), 0.66, 0.85, 0.95, 1.05),
], extra=torso_extra)
piece("BroUpperArm", [ball((0, 0, 0), 0.46), capsule((0, 0, -0.1), (0, 0, -1.85), 0.36)])
piece("BroForearm", [capsule((0, 0, 0), (0, 0, -1.75), 0.31), ell((0, -0.05, -2.05), 0.38, 0.85, 0.9, 1.0)])
piece("BroThigh", [ball((0, 0, 0), 0.5), capsule((0, 0, -0.1), (0, 0, -2.35), 0.44)])
piece("BroShin", [capsule((0, 0, 0), (0, 0, -2.2), 0.38), capsule((0, 0.15, -2.35), (0, -0.85, -2.55), 0.3)])

sw = collection("BroSword")
# grip along Y through the fist, a disc guard, a long slightly curved blade
sweep("Sash_Grip", "Sash", sw, [V((0, 1.1, 0)), V((0, -0.55, 0))], lambda t: circle(0.17 + 0.03 * math.sin(t * math.pi * 10), 8))
lathe("Gold_Tsuba", "Gold", sw, [(0, -0.07), (0.62, -0.07), (0.62, 0.07), (0, 0.07)], segments=16, loc=(0, -0.65, 0)).rotation_euler = (math.radians(90), 0, 0)
lathe("Gold_Kashira", "Gold", sw, [(0, -0.15), (0.2, -0.1), (0.2, 0.1), (0, 0.15)], segments=10, loc=(0, 1.2, 0)).rotation_euler = (math.radians(90), 0, 0)
bl = [V((0, -0.72 - 5.6 * t, 0.35 * t * t)) for t in [i / 14 for i in range(15)]]


def bsec(t):
    w = 0.26 * (1 - t ** 3 * 0.9)
    return [(-0.05, -w * 0.2), (0.05, -w * 0.2), (0.02, w), (-0.02, w)]


sweep("Blade_Edge", "Blade", sw, bl, bsec, smooth=False, hint=(1, 0, 0))

print({c.name: len(c.objects) for c in bpy.data.collections if c.name.startswith(("Bro", "Kneeler"))})
