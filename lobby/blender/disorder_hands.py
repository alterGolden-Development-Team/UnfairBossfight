# Reality Disorderer's floating gauntlet hands (VFXEngine/Effects/Disorderer.luau). Exported in the Weapons kit.
# Roblox hand-local (x, y, z) = Blender (-x, z, y): fingers grow along Roblox +Y (Blender +Z), the back of the hand is Roblox +Z (Blender +Y),
# the palm face Roblox -Z (Blender -Y).
#   DisPalm     absolute size (SC = 2.05 already applied): palm plate, knuckle roll, wrist roll, back armour, glitched neon seams.
#   DisPhalanx  UNIT finger segment from its joint (origin) along +Y 1 stud, about 1 stud thick; the effect scales it per segment
#               (width, length, depth) = (thickness, segment length, thickness).
#   DisClaw     UNIT fingertip claw from its socket (origin) along +Y 1 stud, curling toward the palm (Roblox -Z).
# Roles: DisDark / DisAsh (metal), DisGlow (neon, recoloured per finger), DisMag / DisCyan (neon seams).
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())
for k, v in {"DisDark": ((0.02, 0.018, 0.035), 1.0, 0.35), "DisAsh": ((0.09, 0.07, 0.15), 1.0, 0.3), "DisGlow": ((1.0, 0.9, 1.0), 0.0, 0.5),
             "DisMag": ((1.0, 0.15, 0.8), 0.0, 0.5), "DisCyan": ((0.1, 0.9, 1.0), 0.0, 0.5)}.items():
    ROLES[k] = v
V = Vector
SC = 2.05
W, H, TH = 1.72 * SC, 1.72 * SC, 0.46 * SC


def roundbox(c, name, role, size, loc=(0, 0, 0), bevel=0.1, seg=3):
    o = box(name, role, c, size, loc=loc)
    m = o.modifiers.new("Bevel", "BEVEL")
    m.width = bevel
    m.segments = seg
    return o


def sphere(c, name, role, r, loc, seg=12):
    prof = [(0, -r)] + [(math.sin(math.pi * k / 8) * r, -math.cos(math.pi * k / 8) * r) for k in range(1, 8)] + [(0, r)]
    return lathe(name, role, c, prof, segments=seg, loc=loc)


# ------------------------------------------------------------------------------------------------------------------- palm
c = collection("DisPalm")
o = slab2d("DisDark_Plate", "DisDark", c, [(-1.72, 1.45), (-1.62, -0.45), (-1.3, -1.45), (1.3, -1.45), (1.62, -0.45), (1.72, 1.45)], -TH * 0.46, TH * 0.46)
m = o.modifiers.new("Bevel", "BEVEL")
m.width, m.segments = 0.2, 3
sweep("DisAsh_Knuckles", "DisAsh", c, [V((-W * 0.5, 0, H * 0.42)), V((W * 0.5, 0, H * 0.42))], circle(TH * 0.55, 12, 1.0, 0.92), hint=(0, 0, 1))
for fx in (1, 1 / 3, -1 / 3, -1):
    sphere(c, "DisAsh_KnuckleDome", "DisAsh", 0.4, (fx * W * 0.36, TH * 0.22, H * 0.44))
sweep("DisDark_Wrist", "DisDark", c, [V((-1.35, 0, -H * 0.42)), V((1.35, 0, -H * 0.42))], circle(TH * 0.56, 12), hint=(0, 0, 1))
for s in (-1, 1):
    sweep("DisAsh_SideRidge", "DisAsh", c, [V((s * 1.3, 0, -1.45)), V((s * 1.62, 0, -0.45)), V((s * 1.72, 0, 1.2))], circle(TH * 0.3, 10))
# back armour (Roblox +Z = Blender +Y): a raised hexagonal plate cut by glitched neon seams
plate = [(-1.3, -1.05), (1.3, -1.05), (1.48, 0.15), (1.22, 1.12), (-1.22, 1.12), (-1.48, 0.15)]
o = slab2d("DisAsh_BackPlate", "DisAsh", c, plate, TH * 0.4, TH * 0.4 + 0.16)
for i, z in enumerate((-0.656, 0.0, 0.656)):
    role = "DisMag" if i == 1 else "DisCyan"
    xs = [(-1.2, -0.45, 0.0), (-0.38, 0.32, 0.05), (0.4, 1.2, -0.03)]  # broken into offset pieces, like corrupted footage
    for a, b, dz in xs:
        box(f"{role}_Seam", role, c, (b - a, 0.08, 0.11), loc=((a + b) / 2, TH * 0.4 + 0.18, z + dz))
for (x, y, z, s, role) in ((1.75, 0.2, 0.95, 0.22, "DisMag"), (-1.82, -0.1, -0.4, 0.18, "DisCyan"), (1.6, -0.35, -1.25, 0.16, "DisCyan"), (-1.5, 0.3, 1.32, 0.2, "DisMag")):
    box(f"{role}_Glitch", role, c, (s, s, s), loc=(x, y, z))
# palm face (Roblox -Z): a diamond socket for the error core (the core itself stays a live part so it can flicker)
d = slab2d("DisAsh_Socket", "DisAsh", c, [(0, -0.95), (0.95, 0), (0, 0.95), (-0.95, 0)], -TH * 0.46 - 0.12, -TH * 0.46 + 0.02)
for k in range(4):
    a = math.pi / 4 + k * math.pi / 2
    box("DisDark_SocketPin", "DisDark", c, (0.18, 0.12, 0.18), loc=(math.cos(a) * 0.72, -TH * 0.46 - 0.14, math.sin(a) * 0.72))

# ------------------------------------------------------------------------------------------------------------------- phalanx (unit)
c = collection("DisPhalanx")


def octo(wx, wy):
    return [(math.cos(math.pi / 8 + k * math.pi / 4) * wx, math.sin(math.pi / 8 + k * math.pi / 4) * wy) for k in range(8)]


sweep("DisDark_Body", "DisDark", c, [V((0, 0, 0.0)), V((0, 0, 0.5)), V((0, 0, 1.0))], lambda t: octo(0.5 - 0.08 * t, 0.5 - 0.08 * t), smooth=False)
sweep("DisAsh_Plate", "DisAsh", c, [V((0, 0, 0.12)), V((0, 0, 0.55)), V((0, 0, 0.95))],
      lambda t: [(-0.46 + 0.06 * t, 0.3), (-0.32, 0.56 - 0.05 * t), (0.32, 0.56 - 0.05 * t), (0.46 - 0.06 * t, 0.3), (0.3, 0.42), (-0.3, 0.42)], smooth=False)
sphere(c, "DisAsh_Knuckle", "DisAsh", 0.52, (0, 0, 0), seg=10)
box("DisGlow_Line", "DisGlow", c, (0.1, 0.06, 0.55), loc=(0, 0.585, 0.55))
for s in (-1, 1):
    box("DisDark_Rib", "DisDark", c, (0.08, 0.5, 0.12), loc=(s * 0.45, -0.05, 0.62))

# ------------------------------------------------------------------------------------------------------------------- claw (unit)
c = collection("DisClaw")
lathe("DisDark_Socket", "DisDark", c, [(0, -0.05), (0.5, -0.05), (0.52, 0.12), (0.4, 0.22), (0, 0.22)], segments=8, smooth=False)
pts = [V((0, -0.32 * t * t, 0.1 + 0.9 * t)) for t in [i / 10 for i in range(11)]]
sweep("DisGlow_Claw", "DisGlow", c, pts, lambda t: [(-0.36 * (1 - t) - 0.01, 0), (0, -0.26 * (1 - t) - 0.01), (0.36 * (1 - t) + 0.01, 0), (0, 0.3 * (1 - t) + 0.01)],
      smooth=False, hint=(0, 1, 0))

print({x: len(bpy.data.collections[x].objects) for x in ("DisPalm", "DisPhalanx", "DisClaw")})
