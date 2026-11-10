--!nonstrict
-- The showroom dummy: an R6 body built on the client, wearing the real gear from the boss place's ClassModels, posed by moving its joints.
-- Procedural on purpose: animation assets only load for their owner, and this one has to work for everyone.
local TweenService = game:GetService("TweenService")

local Rig = {}
Rig.__index = Rig

local LOOK = CFrame.fromMatrix(Vector3.zero, Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0))
local RIGHT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, -1), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0))
local LEFT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, 1), Vector3.new(0, 1, 0), Vector3.new(-1, 0, 0))

local function part(model, name, size, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color = name, size, color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.Parent = model
	return p
end

local function motor(name, part0, part1, c0, c1)
	local m = Instance.new("Motor6D")
	m.Name, m.Part0, m.Part1, m.C0, m.C1 = name, part0, part1, c0, c1
	m.Parent = part0
	return m
end

function Rig.new(parent, position, facing, target)
	local self = setmetatable({}, Rig)
	local model = Instance.new("Model")
	model.Name = "ShowcaseDummy"
	self.model = model
	self.home = CFrame.lookAt(position, position + (facing or Vector3.new(0.9, 0, 1)))
	self.position, self.target = position, target
	local skin = Color3.fromRGB(214, 176, 130)
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), skin)
	root.Transparency, root.Anchored = 1, true
	root.CFrame = self.home
	model.PrimaryPart = root
	self.root = root
	local torso = part(model, "Torso", Vector3.new(2, 2, 1), Color3.fromRGB(80, 74, 70))
	local head = part(model, "Head", Vector3.new(2, 1, 1), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Scale = Enum.MeshType.Head, Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head
	local ra = part(model, "Right Arm", Vector3.new(1, 2, 1), skin)
	local la = part(model, "Left Arm", Vector3.new(1, 2, 1), skin)
	local rl = part(model, "Right Leg", Vector3.new(1, 2, 1), Color3.fromRGB(50, 46, 44))
	local ll = part(model, "Left Leg", Vector3.new(1, 2, 1), Color3.fromRGB(50, 46, 44))
	for _, p in { torso, head, ra, la, rl, ll } do
		p.CFrame = self.home
	end
	self.motors = {
		Root = motor("RootJoint", root, torso, LOOK, LOOK),
		Neck = motor("Neck", torso, head, CFrame.new(0, 1, 0) * LOOK, CFrame.new(0, -0.5, 0) * LOOK),
		RA = motor("Right Shoulder", torso, ra, CFrame.new(1, 0.5, 0) * RIGHT, CFrame.new(-0.5, 0.5, 0) * RIGHT),
		LA = motor("Left Shoulder", torso, la, CFrame.new(-1, 0.5, 0) * LEFT, CFrame.new(0.5, 0.5, 0) * LEFT),
		RL = motor("Right Hip", torso, rl, CFrame.new(1, -1, 0) * RIGHT, CFrame.new(0.5, 1, 0) * RIGHT),
		LL = motor("Left Hip", torso, ll, CFrame.new(-1, -1, 0) * LEFT, CFrame.new(-0.5, 1, 0) * LEFT),
	}
	self.base = {}
	for key, m in self.motors do
		self.base[key] = m.C0
	end
	model.Parent = parent
	self.torso = torso
	return self
end

function Rig:setClass(ClassModels, id, color)
	self.torso.Color = color or Color3.fromRGB(80, 74, 70)
	local ok, err = pcall(ClassModels.Build, self.model, id)
	if not ok then
		warn("[Showcase] gear for " .. id .. ": " .. tostring(err))
	end
end

function Rig:clearGear()
	local gear = self.model:FindFirstChild("ClassGear")
	if gear then
		gear:Destroy()
	end
end

-- spec: RA, LA, RL, LL = swing forward in radians; RAo, LAo = out to the side; T = twist at the waist; Lean = bend at the waist; N = head turn
function Rig:pose(spec, duration, style)
	local info = TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goals = {
		RA = CFrame.Angles(spec.RAo or 0, 0, spec.RA or 0),
		LA = CFrame.Angles(spec.LAo or 0, 0, -(spec.LA or 0)),
		RL = CFrame.Angles(0, 0, spec.RL or 0),
		LL = CFrame.Angles(0, 0, -(spec.LL or 0)),
		Root = CFrame.Angles(spec.Lean or 0, 0, spec.T or 0),
		Neck = CFrame.Angles(0, 0, spec.N or 0),
	}
	for key, offset in goals do
		TweenService:Create(self.motors[key], info, { C0 = self.base[key] * offset }):Play()
	end
end

function Rig:rest(duration)
	self:pose({ RA = 0.08, LA = 0.08 }, duration or 0.25)
end

-- Moves the whole body. `to` is world space.
function Rig:move(to, duration, style)
	local tween = TweenService:Create(self.root, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = to })
	tween:Play()
	return tween
end

function Rig:faceTarget(duration)
	self:move(CFrame.lookAt(self.position, Vector3.new(self.target.X, self.position.Y, self.target.Z)), duration or 0.12)
end

function Rig:reset(duration)
	self:move(self.home, duration or 0.25)
	self:rest(duration)
end

function Rig:destroy()
	self.model:Destroy()
end

return Rig
