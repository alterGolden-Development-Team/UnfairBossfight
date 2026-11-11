--!nonstrict
-- Shared by every portal: placing a Blender gate (lobby/blender/gates.py), lighting its glowing face, and the walk-in trigger.
-- Blender coordinates map to a gate's local frame as (x, y, z) -> (-x, z, y): the gate's front (Blender -Y) is its local -Z, which
-- CFrame.lookAt(pos, target) turns toward `target`. Gates.B(x, y, z) converts a Blender point for CFrame offsets.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local C = Kit.C

local Gates = {}

function Gates.B(x, y, z)
	return CFrame.new(-x, z, y)
end

function Gates.place(parent, piece, cf, name)
	local model = Assets.Get(piece)
	model:PivotTo(cf)
	model.Name = name or piece
	model.Parent = parent
	return model
end

-- The face: tinted, see-through, lit, with motes drifting off it. Returns the face part.
function Gates.glow(model, color, transparency, light)
	local face = model:FindFirstChild("Glow", true)
	if not face then
		return nil
	end
	face.Color = color
	face.Transparency = transparency or 0.3
	face.CanCollide, face.CanQuery, face.CanTouch, face.CastShadow = false, false, false, false
	local motes = Instance.new("ParticleEmitter")
	motes.Name = "Motes"
	motes.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.55), color)
	motes.LightEmission = 1
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.15), NumberSequenceKeypoint.new(1, 1) })
	motes.Lifetime = NumberRange.new(1.4, 2.4)
	motes.Rate = 26
	motes.Speed = NumberRange.new(0.6, 1.6)
	motes.SpreadAngle = Vector2.new(30, 30)
	motes.Acceleration = Vector3.new(0, 1.2, 0)
	motes.Parent = face
	if light ~= false then
		Kit.light(face, color, light or 34, 1.4)
	end
	return face
end

-- An invisible trigger in front of a face: walking into it takes you to `target` (PortalService, tag UnfairPortal).
function Gates.trigger(parent, cf, size, target)
	return Kit.trigger(parent, size, cf, target)
end

-- The way back to the Sanctum. Each area has its own gate (lobby/blender/lobby2.py): the palace a stepped gold deco door with ray
-- wings, the island an arch of whale ribs hung with a net, the forest a moon gate in a half-white, half-black wall. `cf` = ground
-- point, front toward the player.
local RETURN = {
	GateReturn = { color = Kit.rgb(150, 205, 255), center = 9.5, size = Vector3.new(12, 17, 3), label = 33 },
	GateReturnPalace = { color = Kit.rgb(255, 214, 140), center = 11.3, size = Vector3.new(12, 19, 3), label = 38 },
	GateReturnIsland = { color = Kit.rgb(110, 220, 235), center = 10.6, size = Vector3.new(11, 17, 3), label = 28 },
	GateReturnForest = { color = Kit.rgb(220, 220, 226), center = 10.2, size = Vector3.new(13, 14, 3), label = 28 },
}

function Gates.returnGate(parent, cf, piece)
	piece = piece or "GateReturn"
	local spec = RETURN[piece] or RETURN.GateReturn
	local m = Gates.place(parent, piece, cf, "WayBack")
	Gates.glow(m, spec.color, 0.25, 30)
	Gates.trigger(m, cf * CFrame.new(0, spec.center, -1.6), spec.size, "Hub")
	local label = Kit.box(m, "ExitLabel", Vector3.new(1, 1, 1), cf * CFrame.new(0, spec.label, 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	Kit.nameplate(label, "Back to the Sanctum", "", C.White, 2, 60)
	return m
end

return Gates
