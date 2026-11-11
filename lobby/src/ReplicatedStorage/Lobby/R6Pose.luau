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

-- Dresses a figure from R6Pose.build as a real Roblox user's avatar: body colours, shirt, pants, t-shirt, face, head shape and every
-- rigid accessory (hats, hair, glasses...), scaled with the figure. Server or Studio edit mode only (it loads the avatar).
-- Accessories are welded to the part they sit on, so they follow the pose. Returns true when the avatar was applied.
-- user: a user name or user id.
function R6Pose.dress(model, user, scale)
	local Players = game:GetService("Players")
	local s = scale or model:GetAttribute("Scale") or 1
	local userId = tonumber(user)
	if not userId then
		local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, user)
		if not ok then
			warn("[R6Pose] no user " .. tostring(user) .. ": " .. tostring(id))
			return false
		end
		userId = id
	end
	local okDesc, description = pcall(Players.GetHumanoidDescriptionFromUserIdAsync, Players, userId)
	if not okDesc then
		warn("[R6Pose] no avatar for " .. tostring(user) .. ": " .. tostring(description))
		return false
	end
	local okModel, avatar = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, description, Enum.HumanoidRigType.R6)
	if not okModel then
		warn("[R6Pose] could not build " .. tostring(user) .. ": " .. tostring(avatar))
		return false
	end
	if s ~= 1 then
		avatar:ScaleTo(s)
	end
	-- the look of each body part
	local colors = avatar:FindFirstChildOfClass("BodyColors")
	for _, name in { "Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg" } do
		local mine, theirs = model:FindFirstChild(name), avatar:FindFirstChild(name)
		if mine and theirs then
			mine.Color = theirs.Color
			mine.Material = Enum.Material.SmoothPlastic
		end
	end
	if colors then
		colors:Destroy()
	end
	for _, old in model:GetChildren() do
		if old:IsA("Clothing") or old:IsA("ShirtGraphic") or old:IsA("Accessory") or old:IsA("BodyColors") then
			old:Destroy()
		end
	end
	for _, item in avatar:GetChildren() do
		if item:IsA("Clothing") or item:IsA("ShirtGraphic") then
			item.Parent = model
		end
	end
	-- the head: its shape and its face
	local head, avatarHead = model:FindFirstChild("Head"), avatar:FindFirstChild("Head")
	if head and avatarHead then
		local mesh, theirMesh = head:FindFirstChildOfClass("SpecialMesh"), avatarHead:FindFirstChildOfClass("SpecialMesh")
		if mesh and theirMesh then
			mesh.MeshType, mesh.MeshId, mesh.TextureId = theirMesh.MeshType, theirMesh.MeshId, theirMesh.TextureId
			mesh.Scale, mesh.Offset = theirMesh.Scale, theirMesh.Offset
		end
		local face = head:FindFirstChild("face")
		local theirFace = avatarHead:FindFirstChild("face")
		if theirFace and theirFace:IsA("Decal") then
			if not face then
				face = Instance.new("Decal")
				face.Name = "face"
				face.Parent = head
			end
			face.Texture = theirFace.Texture
		end
	end
	-- accessories: kept where they sit on the avatar, relative to the part they are welded to
	for _, accessory in avatar:GetChildren() do
		local handle = accessory:IsA("Accessory") and accessory:FindFirstChild("Handle")
		if handle then
			local onName = "Head"
			for _, weld in handle:GetChildren() do
				if weld:IsA("JointInstance") then
					local other = weld.Part0 == handle and weld.Part1 or weld.Part0
					onName = other and other.Name or onName
				end
			end
			local theirs, mine = avatar:FindFirstChild(onName), model:FindFirstChild(onName)
			if theirs and mine then
				local offset = theirs.CFrame:ToObjectSpace(handle.CFrame)
				for _, weld in handle:GetChildren() do
					if weld:IsA("JointInstance") or weld:IsA("WeldConstraint") then
						weld:Destroy()
					end
				end
				for _, d in accessory:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, false, true
					end
				end
				accessory.Parent = model
				handle.CFrame = mine.CFrame * offset
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = mine, handle
				weld.Parent = handle
			end
		end
	end
	avatar:Destroy()
	model:SetAttribute("AvatarUserId", userId)
	return true
end

return R6Pose
