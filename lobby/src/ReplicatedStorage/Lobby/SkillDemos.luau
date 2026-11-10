--!nonstrict
-- The shimmer the orb showroom plays when you pick an orb. (Class skills are not previewed here: the showroom runs the real ones,
-- see TryoutService.)
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Demos = {}

local NEON = Enum.Material.Neon
local token = 0
local fxFolder = nil

local function fxPart(size, cf, color, shape, material)
	local p = Instance.new("Part")
	if shape then p.Shape = shape end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = material or NEON
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = fxFolder
	return p
end

local function fade(p, time, goals)
	local g = goals or {}
	g.Transparency = 1
	TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), g):Play()
	Debris:AddItem(p, time + 0.1)
end

local function ring(position, color, radius, time, thickness)
	local p = fxPart(Vector3.new(thickness or 0.2, 1, 1), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
	p.Transparency = 0.15
	fade(p, time or 0.5, { Size = Vector3.new(thickness or 0.2, radius * 2, radius * 2) })
end

local function pillar(position, color, height, width, time)
	local p = fxPart(Vector3.new(0.4, width or 2, width or 2), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
	p.Transparency = 0.3
	local goal = position + Vector3.new(0, height / 2, 0)
	fade(p, time or 0.7, { Size = Vector3.new(height, width or 2, width or 2), CFrame = CFrame.new(goal) * CFrame.Angles(0, 0, math.rad(90)) })
end

-- A short shimmer for an orb's passive.
function Demos.PlayOrb(rig, orb)
	if not fxFolder then return end
	ring(rig.position, orb.Color, 8, 0.7, 0.4)
	pillar(rig.position - Vector3.new(0, 2.5, 0), orb.Color, 12, 5, 0.8)
end

function Demos.Setup(folder)
	fxFolder = folder
end

function Demos.Stop()
	token += 1
end

return Demos
