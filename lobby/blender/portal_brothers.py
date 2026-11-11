# Jeff n' Fred's portal: a yin-yang in three dimensions. The floor is a split disc (white and black halves with the opposite dots),
# the ring is two commas chasing each other round the opening (white head at the top, black head at the bottom), and a twisted
# spire stands either side, each crowned with an orb of the other colour. Opening centre (0, 0, 15), diameter 28, facing -Y.
exec(open(r"D:\Project\UnfairBossfight\lobby\blender\kit.py").read())

col = collection("PortalBrothers")
CY = 15.0
R = 14.0
FR = 25.0  # floor radius


def yin_outline(radius, n=48):
    """The white half's outline in the XY plane: big left arc, lower small arc (around the black head), upper small arc."""
    pts = []
    for i in range(n + 1):  # (0, R) -> (-R, 0) -> (0, -R)
        a = math.pi / 2 + i / n * math.pi
        pts.append((math.cos(a) * radius, math.sin(a) * radius))
    h = radius / 2
    for i in range(1, n // 2 + 1):  # lower small circle, from its bottom round its left side to its top
        a = -math.pi / 2 - i / (n // 2) * math.pi
        pts.append((math.cos(a) * h, -h + math.sin(a) * h))
    for i in range(1, n // 2):  # upper small circle, from its bottom round its right side to its top
        a = -math.pi / 2 + i / (n // 2) * math.pi
        pts.append((math.cos(a) * h, h + math.sin(a) * h))
    return pts


def slab(name, role, outline, z0, z1, rot=0.0):
    bm = bmesh.new()
    c, s = math.cos(rot), math.sin(rot)
    pts = [(x * c - y * s, x * s + y * c) for x, y in outline]
    bottom = [bm.verts.new((x, y, z0)) for x, y in pts]
    top = [bm.verts.new((x, y, z1)) for x, y in pts]
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((bottom[i], bottom[j], top[j], top[i]))
    from mathutils.geometry import tessellate_polygon
    for a, b, c3 in tessellate_polygon([[Vector((x, y, 0)) for x, y in pts]]):
        bm.faces.new((top[a], top[b], top[c3]))
        bm.faces.new((bottom[c3], bottom[b], bottom[a]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, role, col, smooth=False)


# --- the floor: a low plinth ring of grey stone, the yin-yang inlaid on top, and its two dots
solid(lathe("Stone_FloorRim", "Stone", col, [(0, 0), (FR + 1.6, 0), (FR + 1.6, 0.9), (FR + 1.2, 1.3), (0, 1.3)], segments=96))
solid(slab("White_FloorYin", "White", yin_outline(FR), 1.3, 1.6))
solid(slab("Black_FloorYang", "Black", yin_outline(FR), 1.3, 1.6, rot=math.pi))
lathe("Black_DotTop", "Black", col, [(0, 1.3), (FR / 7, 1.3), (FR / 7, 1.75), (0, 1.75)], segments=32, loc=(0, FR / 2, 0))
lathe("White_DotBottom", "White", col, [(0, 1.3), (FR / 7, 1.3), (FR / 7, 1.75), (0, 1.75)], segments=32, loc=(0, -FR / 2, 0))
# steps up onto the floor at the front
for i in range(2):
    solid(box(f"Stone_Step{i}", "Stone", col, (18 - i * 3, 3.5, 0.65), loc=(0, -(FR + 2.6) + i * 1.6, 0.33 + i * 0.65 * 0 + (0.0 if i == 0 else 0.3)), bevel=0.1))

# --- the ring: two commas chasing each other round the opening
def comma(name, role, head_angle, y):
    path = []
    n = 60
    span = math.radians(205)
    for i in range(n + 1):
        t = i / n
        a = head_angle + t * span  # from the head, sweeping on round to the tail
        path.append(Vector((math.cos(a) * (R + 2.3), y, CY + math.sin(a) * (R + 2.3))))

    def sec(t):
        r = 0.55 + 2.4 * (1 - t) ** 1.4  # fat head, thin tail
        return circle(r, 16, 1.0, 1.0)

    o = sweep(name, role, col, path, sec)
    # round off the head with a ball
    h = lathe(name + "Head", role, col, [(0, -2.95), (1.5, -2.55), (2.6, -1.4), (2.95, 0), (2.6, 1.4), (1.5, 2.55), (0, 2.95)], segments=20)
    h.location = path[0]
    return o


comma("White_CommaW", "White", math.radians(90 - 10), -0.9)  # head near the top, tail running down the left... and round
comma("Black_CommaB", "Black", math.radians(270 - 10), 0.9)
# a thin silver bead between the commas and the opening, so the edge of the portal reads cleanly
torus("Stone_InnerBead", "Stone", col, R + 0.1, 0.35, seg=96, mseg=8, loc=(0, 0, CY), rot=(math.radians(90), 0, 0))

# feet: two blocks the ring sits in, one white, one black
for side, role in ((-1, "White"), (1, "Black")):
    solid(box(f"{role}_Cradle", role, col, (8, 6, 3.4), loc=(side * 5.5, 0, 2.9), bevel=0.4))

# --- twisted spires, each crowned with an orb of the other colour
for side, role, other in ((-1, "White", "Black"), (1, "Black", "White")):
    x = side * 21.5
    base_z = 1.3
    solid(box(f"{role}_SpireFoot", role, col, (6.4, 6.4, 3.0), loc=(x, 2, base_z + 1.5), bevel=0.35))
    path = [Vector((x, 2, base_z + 3 + i * 0.75)) for i in range(41)]

    def sec(t):
        w = 2.4 * (1 - t * 0.55)
        return [(-w, -w), (w, -w), (w, w), (-w, w)]

    solid(sweep(f"{role}_Spire", role, col, path, sec, smooth=False, twist=lambda t: t * math.pi * 1.5 * side))
    top = base_z + 3 + 40 * 0.75
    lathe(f"{role}_SpireCap", role, col, [(0, 0), (1.6, 0), (1.9, 0.5), (1.2, 1.0), (0, 1.0)], segments=16, loc=(x, 2, top))
    lathe(f"{other}_Orb", other, col, [(0, 0), (1.3, 0.4), (2.0, 1.7), (2.1, 2.6), (1.6, 3.7), (0, 4.4)], segments=20, loc=(x, 2, top + 0.8))
    # a crescent hugging the orb (the opposite colour's mark)
    arc = [Vector((x + math.cos(a) * 2.9, 2, top + 3.0 + math.sin(a) * 2.9)) for a in [math.radians(d) for d in range(200, 341, 10)]]
    sweep(f"{role}_Crescent", role, col, arc, lambda t: circle(0.15 + 0.5 * math.sin(t * math.pi), 8))

print(len(col.objects), "objects")
