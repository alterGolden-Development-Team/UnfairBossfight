--!nonstrict
-- The glitched portal in the Divided Wood (Forest builder, tag UnfairGlitchPortal): its face stutters between black and white, jumps
-- a little, and sheds square black and white bits. Client only and cheap: about 12 updates a second, only while you are in the forest.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local faces = {}
local rng = Random.new()

local function bits(face)
	if face:FindFirstChild("GlitchBits") then
		return
	end
	for i, color in { Color3.new(1, 1, 1), Color3.new(0, 0, 0) } do
		local e = Instance.new("ParticleEmitter")
		e.Name = i == 1 and "GlitchBits" or "GlitchBitsDark"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(color)
		e.LightEmission = i == 1 and 0.6 or 0
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.2) })
		e.Lifetime = NumberRange.new(0.6, 1.6)
		e.Rate = 18
		e.Speed = NumberRange.new(4, 11)
		e.SpreadAngle = Vector2.new(70, 70)
		e.Rotation = NumberRange.new(0, 90)
		e.Parent = face
	end
end

local function add(face)
	if face:IsA("BasePart") then
		faces[face] = { home = face.CFrame }
		bits(face)
	end
end
for _, face in CollectionService:GetTagged("UnfairGlitchPortal") do
	add(face)
end
CollectionService:GetInstanceAddedSignal("UnfairGlitchPortal"):Connect(add)
CollectionService:GetInstanceRemovedSignal("UnfairGlitchPortal"):Connect(function(face)
	faces[face] = nil
end)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 12 or player:GetAttribute("Area") ~= "Forest" then
		return
	end
	acc = 0
	for face, state in faces do
		if face.Parent then
			local dark = rng:NextNumber() < 0.35
			face.Color = dark and Color3.fromRGB(8, 8, 10) or Color3.fromRGB(250, 250, 250)
			face.Transparency = rng:NextNumber(0.02, 0.35)
			if rng:NextNumber() < 0.25 then
				face.CFrame = state.home * CFrame.new(rng:NextNumber(-0.6, 0.6), rng:NextNumber(-0.4, 0.4), 0)
			else
				face.CFrame = state.home
			end
		end
	end
end)
