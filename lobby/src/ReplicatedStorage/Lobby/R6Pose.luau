--!nonstrict
-- R6 avatars for the map: the gilded statues at the Midas gate, the shop's keeper, and the brothers in the forest.
-- A standard R6 body (Head with the classic head mesh and face, Torso, Right/Left Arm, Right/Left Leg, an invisible HumanoidRootPart
-- and a Humanoid) whose parts are all anchored and placed by forward kinematics from joint angles. No Motor6Ds are needed, so a pose
-- shows in Edit mode, and the client can animate one by calling R6Pose.place every frame.
local R6Pose = {}

local function part(model, name, size, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color = name, size, color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Parent = model
	return p
end

-- colors: { skin, torso, arms, legs } (Color3s); material: optional material for every part (statues)
function R6Pose.build(parent, name, colors, material)
	colors = colors or {}
	local skin = colors.skin or Color3.fromRGB(234, 184, 146)
	local model = Instance.new("Model")
	model.Name = name
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), skin)
	root.Transparency = 1
	local torso = part(model, "Torso", Vector3.new(2, 2, 1), colors.torso or Color3.fromRGB(13, 105, 172))
	local head = part(model, "Head", Vector3.new(2, 1, 1), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Scale = Enum.MeshType.Head, Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	if not material then
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Texture = "rbxasset://textures/face.png"
		face.Parent = head
	end
	part(model, "Right Arm", Vector3.new(1, 2, 1), colors.arms or skin)
	part(model, "Left Arm", Vector3.new(1, 2, 1), colors.arms or skin)
	part(model, "Right Leg", Vector3.new(1, 2, 1), colors.legs or Color3.fromRGB(39, 70, 45))
	part(model, "Left Leg", Vector3.new(1, 2, 1), colors.legs or Color3.fromRGB(39, 70, 45))
	if material then
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") then
				p.Material = material
			end
		end
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.RequiresNeck = false
	humanoid.Parent = model
	model.PrimaryPart = root
	model.Parent = parent
	return model
end

local function ang(v)
	if not v then
		return CFrame.identity
	end
	return CFrame.Angles(math.rad(v[1] or 0), math.rad(v[2] or 0), math.rad(v[3] or 0))
end

local function put(model, name, cf, s)
	local p = model:FindFirstChild(name)
	if p then
		p.CFrame = cf
	end
end

-- home: the ground between the feet, facing -Z. Pose fields (degrees; positive pitch swings a limb forward and up):
--   move = {x, y, z} offset, turn = yaw, lean/twist via spine = {pitch, yaw, roll}, neck, shR/shL (shoulders), hipR/hipL,
--   wrR = the right hand's turn (what it holds), drop = extra lowering of the body (kneeling).
-- Returns the right hand's CFrame (for a held sword) and the head's CFrame (for a hat).
function R6Pose.place(model, home, p, scale)
	local s = scale or model:GetAttribute("Scale") or 1
	local move = p.move or { 0, 0, 0 }
	-- with straight R6 legs, swinging them lifts the feet: lower the body so they stay on the ground
	local swing = math.max(math.abs((p.hipR or { 0 })[1] or 0), math.abs((p.hipL or { 0 })[1] or 0))
	local sink = 2 * (1 - math.cos(math.rad(math.min(swing, 80)))) + (p.drop or 0)
	local root = home * CFrame.new(move[1] * s, (move[2] + 3 - sink) * s, move[3] * s) * CFrame.Angles(0, math.rad(p.turn or 0), 0)
	put(model, "HumanoidRootPart", root)
	local torso = root * ang(p.spine)
	put(model, "Torso", torso)
	local head = torso * CFrame.new(0, 1 * s, 0) * ang(p.neck) * CFrame.new(0, 0.5 * s, 0)
	put(model, "Head", head)
	local hands = {}
	for _, side in { "Right", "Left" } do
		local x = side == "Right" and 1 or -1
		local key = side == "Right" and "R" or "L"
		local shoulder = torso * CFrame.new(1.5 * x * s, 1 * s, 0) * ang(p["sh" .. key])
		put(model, side .. " Arm", shoulder * CFrame.new(0, -1 * s, 0))
		hands[key] = shoulder * CFrame.new(0, -2 * s, 0)
		local hip = torso * CFrame.new(0.5 * x * s, -1 * s, 0) * ang(p["hip" .. key])
		put(model, side .. " Leg", hip * CFrame.new(0, -1 * s, 0))
	end
	return hands.R * ang(p.wrR), head
end

-- ease between two poses (numbers and {a, b, c} tables)
local function mix(a, b, t)
	if type(a) == "number" or type(b) == "number" then
		return (a or 0) + ((b or 0) - (a or 0)) * t
	end
	a, b = a or { 0, 0, 0 }, b or { 0, 0, 0 }
	return { mix(a[1], b[1], t), mix(a[2], b[2], t), mix(a[3], b[3], t) }
end

function R6Pose.lerp(a, b, t)
	local out = {}
	for k in a do
		out[k] = mix(a[k], b[k], t)
	end
	for k in b do
		if out[k] == nil then
			out[k] = mix(a[k], b[k], t)
		end
	end
	return out
end

return R6Pose
