# Helpers for building the lobby's meshes in Blender (run through the Blender MCP: exec(open(KIT).read())).
# 1 Blender unit = 1 Roblox stud (GLB imports at 1 m = 1 stud). Z is up here; the GLB exporter turns it into Roblox's Y up.
# Every exported object carries ONE material, and the object name starts with that material's "role"
# (Gold, GoldDeep, Marble, Slate, Neon...). Assets.luau reads the role from the MeshPart name and gives it a Roblox material + colour.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler

ROLES = {
    # role: (linear-ish preview colour, metallic, roughness)
    "Gold": ((1.0, 0.62, 0.16), 1.0, 0.25),
    "GoldDeep": ((0.55, 0.30, 0.06), 1.0, 0.35),
    "GoldPale": ((1.0, 0.85, 0.5), 1.0, 0.2),
    "Ink": ((0.012, 0.010, 0.012), 0.0, 0.3),
    "Marble": ((0.85, 0.85, 0.83), 0.0, 0.35),
    "MarbleDark": ((0.02, 0.018, 0.02), 0.0, 0.25),
    "Slate": ((0.02, 0.02, 0.022), 0.0, 0.8),
    "Stone": ((0.45, 0.42, 0.38), 0.0, 0.9),
    "StoneWarm": ((0.6, 0.5, 0.38), 0.0, 0.9),
    "Rock": ((0.28, 0.27, 0.26), 0.0, 0.95),
    "Sand": ((0.8, 0.66, 0.42), 0.0, 1.0),
    "Wood": ((0.25, 0.13, 0.06), 0.0, 0.8),
    "WoodDark": ((0.12, 0.06, 0.03), 0.0, 0.8),
    "Plank": ((0.42, 0.25, 0.12), 0.0, 0.8),
    "Fabric": ((0.85, 0.8, 0.7), 0.0, 1.0),
    "Rope": ((0.6, 0.5, 0.33), 0.0, 1.0),
    "White": ((0.92, 0.92, 0.92), 0.0, 0.5),
    "Black": ((0.015, 0.015, 0.017), 0.0, 0.5),
    "Blue": ((0.02, 0.12, 0.45), 0.0, 0.5),
    "Red": ((0.5, 0.03, 0.03), 0.0, 0.5),
    "Iron": ((0.08, 0.08, 0.09), 1.0, 0.6),
    "Glass": ((0.6, 0.8, 0.9), 0.0, 0.05),
    "Leaf": ((0.1, 0.3, 0.06), 0.0, 0.9),
    "Neon": ((1.0, 0.7, 0.3), 0.0, 0.5),
    "GemRed": ((0.8, 0.02, 0.05), 0.0, 0.1),
    "GemBlue": ((0.02, 0.15, 0.9), 0.0, 0.1),
    "Grass": ((0.12, 0.25, 0.06), 0.0, 0.9),
    "Bark": ((0.1, 0.07, 0.05), 0.0, 0.9),
}


def material(role):
    name = "R_" + role
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    col, metal, rough = ROLES[role]
    bsdf.inputs["Base Color"].default_value = (*col, 1)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    m.diffuse_color = (*col, 1)
    return m


def collection(name, clear=True):
    col = bpy.data.collections.get(name)
    if col and clear:
        for o in list(col.objects):
            bpy.data.objects.remove(o, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0:
            bpy.data.meshes.remove(me)
    if not col:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    col.hide_viewport = False  # hidden collections are not evaluated (modifiers, metaballs)
    return col


def obj_from_bm(bm, name, role, col, smooth=True):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    col.objects.link(o)
    me.materials.append(material(role))
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    o["role"] = role
    return o


def lathe(name, role, col, profile, segments=32, loc=(0, 0, 0), smooth=True):
    """profile: list of (radius, z) from bottom to top. Closed at both ends when radius reaches 0, capped otherwise."""
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        ring = []
        for i in range(segments):
            a = i / segments * math.tau
            ring.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, z)))
        rings.append(ring)
    for k in range(len(rings) - 1):
        for i in range(segments):
            j = (i + 1) % segments
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    if profile[0][0] > 0 and profile[-1][0] > 0 and len(profile) > 2:
        # a ring-shaped profile (both ends off the axis): close it into a loop instead of capping it with discs
        for i in range(segments):
            j = (i + 1) % segments
            bm.faces.new((rings[-1][i], rings[-1][j], rings[0][j], rings[0][i]))
    else:
        if profile[0][0] > 0:
            bm.faces.new(list(reversed(rings[0])))
        if profile[-1][0] > 0:
            bm.faces.new(rings[-1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = obj_from_bm(bm, name, role, col, smooth)
    o.location = loc  # kept on the object, so a later rotation_euler turns it in place
    return o


def box(name, role, col, size, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    o = obj_from_bm(bm, name, role, col, smooth=False)
    o.location = loc
    o.rotation_euler = rot
    if bevel > 0:
        bev(o, bevel, 2)
    return o


def bev(o, width, segments=2, angle=35):
    m = o.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle)
    m.harden_normals = False
    for p in o.data.polygons:
        p.use_smooth = True
    return m


def torus(name, role, col, major, minor, seg=48, mseg=12, loc=(0, 0, 0), rot=(0, 0, 0), scale_minor=(1, 1)):
    """A ring; scale_minor squashes the tube section (radial, axial)."""
    bm = bmesh.new()
    rings = []
    for i in range(seg):
        a = i / seg * math.tau
        c, s = math.cos(a), math.sin(a)
        ring = []
        for k in range(mseg):
            b = k / mseg * math.tau
            r = major + math.cos(b) * minor * scale_minor[0]
            ring.append(bm.verts.new((c * r, s * r, math.sin(b) * minor * scale_minor[1])))
        rings.append(ring)
    for i in range(seg):
        j = (i + 1) % seg
        for k in range(mseg):
            l = (k + 1) % mseg
            bm.faces.new((rings[i][k], rings[j][k], rings[j][l], rings[i][l]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = obj_from_bm(bm, name, role, col)
    o.location = loc
    o.rotation_euler = rot
    return o


def sweep(name, role, col, path, section, closed_path=False, smooth=True, twist=None, hint=None):
    """Sweep a 2D section [(x, y)] (closed loop) along a 3D path [Vector]. section x = side, y = up (relative to path frame).
    section may also be a function t -> list of (x, y) to vary along the path."""
    bm = bmesh.new()
    n = len(path)
    rings = []
    up_hint = Vector(hint) if hint else Vector((0, 0, 1))
    for i, p in enumerate(path):
        p = Vector(p)
        a = Vector(path[max(i - 1, 0)]) if not closed_path else Vector(path[(i - 1) % n])
        b = Vector(path[min(i + 1, n - 1)]) if not closed_path else Vector(path[(i + 1) % n])
        t = (b - a).normalized()
        hv = up_hint if (hint or abs(t.dot(up_hint)) < 0.95) else Vector((0, 1, 0))
        side = t.cross(hv).normalized()
        up = side.cross(t).normalized()
        if twist:
            ang = twist(i / max(n - 1, 1))
            side, up = side * math.cos(ang) + up * math.sin(ang), up * math.cos(ang) - side * math.sin(ang)
        sec = section(i / max(n - 1, 1)) if callable(section) else section
        rings.append([bm.verts.new(p + side * x + up * y) for x, y in sec])
    m = len(rings[0])
    last = n if closed_path else n - 1
    for i in range(last):
        j = (i + 1) % n
        for k in range(m):
            l = (k + 1) % m
            bm.faces.new((rings[i][k], rings[i][l], rings[j][l], rings[j][k]))
    if not closed_path:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, role, col, smooth)


def circle(r, n=10, sx=1.0, sy=1.0):
    return [(math.cos(i / n * math.tau) * r * sx, math.sin(i / n * math.tau) * r * sy) for i in range(n)]


def rock(name, role, col, size, loc=(0, 0, 0), seed=0, detail=2, rough=0.22, flat_bottom=True):
    """An icosphere pushed about with noise, then scaled to `size` (x, y, z)."""
    rnd = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=detail, radius=0.5)
    offs = [Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))) for _ in range(6)]
    for v in bm.verts:
        d = v.co.normalized()
        k = 1.0
        for o in offs:
            k += rough * max(0.0, d.dot(o.normalized())) ** 3 * (0.5 - rnd.random() * 0.05)
        k += rnd.uniform(-rough, rough) * 0.25
        v.co = d * 0.5 * k
        if flat_bottom and v.co.z < -0.32:
            v.co.z = -0.32
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    o = obj_from_bm(bm, name, role, col, smooth=False)
    o.location = loc
    o.rotation_euler = (0, 0, rnd.uniform(0, math.tau))
    return o


def join(objs, name):
    """Join objects (same material) into one, applying modifiers first."""
    objs = [o for o in objs if o]
    if not objs:
        return None
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    bm = bmesh.new()
    role = objs[0].get("role")
    col = objs[0].users_collection[0]
    for o in objs:
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        me.transform(o.matrix_world)
        tmp = bmesh.new()
        tmp.from_mesh(me)
        ev.to_mesh_clear()
        offset = len(bm.verts)
        vmap = [bm.verts.new(v.co) for v in tmp.verts]
        bm.verts.ensure_lookup_table()
        for f in tmp.faces:
            try:
                nf = bm.faces.new([vmap[v.index] for v in f.verts])
                nf.smooth = f.smooth
            except ValueError:
                pass
        tmp.free()
    for o in objs:
        old = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if old.users == 0:
            bpy.data.meshes.remove(old)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    out = bpy.data.objects.new(name, me)
    col.objects.link(out)
    me.materials.append(material(role))
    out["role"] = role
    return out


def solid(o):
    """Mark an object as something players stand on or bump into (Roblox gets collision for its merged mesh)."""
    o["solid"] = True
    return o


def merge_by_role(col, prefix=""):
    """Join everything in a collection into one object per role and collision flag (split again past the triangle budget).
    Names come out as <prefix><Role>_<S?><n>; S = solid."""
    groups = {}
    for o in list(col.objects):
        if o.type == "MESH" and o.get("role"):
            groups.setdefault((o["role"], bool(o.get("solid")), int(o.get("group", 0))), []).append(o)
    out = []
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    for (role, is_solid, grp), objs in groups.items():
        batches, cur, tris = [], [], 0
        for o in objs:
            ev = o.evaluated_get(deps)
            me = ev.to_mesh()
            t = sum(len(p.vertices) - 2 for p in me.polygons)
            ev.to_mesh_clear()
            if cur and tris + t > 18000:
                batches.append(cur)
                cur, tris = [], 0
            cur.append(o)
            tris += t
        if cur:
            batches.append(cur)
        for i, b in enumerate(batches):
            out.append(join(b, f"{prefix}{role}_{'S' if is_solid else ''}{grp * 10 + i + 1 if grp else i + 1}"))
    return out


def pivot_marker(col, piece):
    """A tiny box at the piece's origin; Roblox reads its position as the piece's pivot, then deletes it."""
    return box(f"{piece}__Pivot", "Ink", col, (0.2, 0.2, 0.2), loc=(0, 0, 0))


def export_kit(cols, path):
    """Merge each collection into role meshes named <Piece>__<Role>_<n>, add its pivot marker, and write one GLB of them all.
    Each collection's name is the piece name; its contents are modelled around the world origin (the pivot)."""
    report = {}
    for c in cols:
        c.hide_viewport = False  # hidden collections are not evaluated, so their modifiers would be lost in the merge
        for o in c.objects:
            o.hide_set(False)
    for c in cols:
        merge_by_role(c, prefix=c.name + "__")
        pivot_marker(c, c.name)
        report[c.name] = tri_report(c)
    bpy.ops.object.select_all(action="DESELECT")
    for c in cols:
        c.hide_viewport = False
        for o in c.objects:
            o.hide_set(False)
            o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_cameras=False, export_lights=False, export_materials="EXPORT")
    over = [(n, t) for rows in report.values() for n, t in rows if t > 20000]
    assert not over, f"over the triangle limit: {over}"
    return report


def tri_report(col):
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    rows = []
    for o in col.objects:
        if o.type != "MESH":
            continue
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        rows.append((o.name, sum(len(p.vertices) - 2 for p in me.polygons)))
        ev.to_mesh_clear()
    return rows


def export(col, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in col.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_cameras=False, export_lights=False, export_materials="EXPORT")
    return path


# ---- shapes shared by the later kits ------------------------------------------------------------------------------
from mathutils.geometry import tessellate_polygon


def arch_outline(hw, z0, spring, n=24, pointed=0.0):
    """A round (pointed > 0: gothic) arch opening as a 2D outline [(x, z)], counter-clockwise from bottom-left."""
    pts = [(-hw, z0)]
    for i in range(n + 1):
        t = i / n
        a = math.pi - t * math.pi
        x = math.cos(a) * hw
        z = spring + math.sin(a) * hw * (1 + pointed * math.sin(a) ** 0.5 * 0) + pointed * hw * (1 - abs(math.cos(a))) ** 1.5
        pts.append((x, z))
    pts.append((hw, z0))
    return pts


def slab2d(name, role, col, pts, y0, y1, plane="xz"):
    """Extrude a 2D outline [(u, v)] between depths y0 and y1. plane xz: u = x, v = z, depth along y (front face at y0)."""
    bm = bmesh.new()
    if plane == "xz":
        mk = lambda u, v, d: (u, d, v)
    else:  # xy: flat on the ground, thickness along z
        mk = lambda u, v, d: (u, v, d)
    a = [bm.verts.new(mk(u, v, y0)) for u, v in pts]
    b = [bm.verts.new(mk(u, v, y1)) for u, v in pts]
    for i0, i1, i2 in tessellate_polygon([[Vector((u, v, 0)) for u, v in pts]]):
        bm.faces.new((a[i0], a[i1], a[i2]))
        bm.faces.new((b[i2], b[i1], b[i0]))
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, role, col, smooth=False)


def blade(name, role, col, center, angle, r0, r1, w0, w1, depth=0.3, y=0.0):
    """A flat tapered ray in the XZ plane (facing -Y) from radius r0 to r1 at `angle` around `center` (x, z)."""
    d = Vector((math.cos(angle), math.sin(angle)))
    s = Vector((-math.sin(angle), math.cos(angle)))
    c = Vector(center)
    a, b = c + d * r0, c + d * r1
    pts = [tuple(a + s * w0), tuple(b + s * w1), tuple(b - s * w1), tuple(a - s * w0)]
    if w1 < 0.02:
        pts = [tuple(a + s * w0), tuple(b), tuple(a - s * w0)]
    return slab2d(name, role, col, pts, y - depth / 2, y + depth / 2)


def cut(target, cutter):
    """Boolean difference, applied; the cutter is deleted."""
    m = target.modifiers.new("Cut", "BOOLEAN")
    m.operation = "DIFFERENCE"
    m.object = cutter
    m.solver = "EXACT"
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    ev = target.evaluated_get(deps)
    me = bpy.data.meshes.new_from_object(ev)
    old = target.data
    target.modifiers.clear()
    target.data = me
    me.materials.clear()
    me.materials.append(material(target["role"]))
    if old.users == 0:
        bpy.data.meshes.remove(old)
    bpy.data.objects.remove(cutter, do_unlink=True)
    return target


def sculpt(name, role, col, elements, resolution=0.35, threshold=0.6, smooth=True):
    """An organic shape from metaball elements, converted to a mesh.
    elements: list of (kind, (x, y, z), radius, extra) where kind is BALL, CAPSULE (extra = (length, rotation quaternion or euler))
    or ELLIPSOID (extra = (sx, sy, sz) radii factors)."""
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = resolution
    mb.render_resolution = resolution
    mb.threshold = threshold
    for kind, co, radius, extra in elements:
        e = mb.elements.new(type=kind)
        e.co = co
        e.radius = radius
        if kind == "CAPSULE":
            length, rot = extra
            e.size_x = length / 2
            e.rotation = rot if hasattr(rot, "w") else Euler(rot).to_quaternion()
        elif kind == "ELLIPSOID":
            e.size_x, e.size_y, e.size_z = extra[0], extra[1], extra[2]
            if len(extra) > 3:
                e.rotation = Euler(extra[3]).to_quaternion()
    tmp = bpy.data.objects.new(name + "_mbobj", mb)
    col.objects.link(tmp)
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(tmp.evaluated_get(deps))
    bpy.data.objects.remove(tmp, do_unlink=True)
    bpy.data.metaballs.remove(mb)
    o = bpy.data.objects.new(name, me)
    col.objects.link(o)
    me.materials.append(material(role))
    for p in me.polygons:
        p.use_smooth = smooth
    o["role"] = role
    return o


def capsule(a, b, r):
    """A metaball capsule element from point a to point b."""
    a, b = Vector(a), Vector(b)
    d = b - a
    q = Vector((1, 0, 0)).rotation_difference(d.normalized())
    return ("CAPSULE", tuple((a + b) / 2), r, (d.length, q))


def decimate(o, ratio):
    m = o.modifiers.new("Dec", "DECIMATE")
    m.ratio = ratio
    return o


ROLES.setdefault("Glow", ((1.0, 1.0, 1.0), 0.0, 0.5))
ROLES.setdefault("Thatch", ((0.55, 0.4, 0.18), 0.0, 1.0))
ROLES.setdefault("Body", ((0.9, 0.9, 0.9), 0.0, 0.5))
ROLES.setdefault("Tile", ((0.35, 0.1, 0.07), 0.0, 0.8))
ROLES.setdefault("Plaster", ((0.85, 0.8, 0.68), 0.0, 0.9))
ROLES.setdefault("Brick", ((0.4, 0.2, 0.15), 0.0, 0.9))
