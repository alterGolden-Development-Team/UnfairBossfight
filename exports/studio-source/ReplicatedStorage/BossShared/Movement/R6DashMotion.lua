local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Config = require(Shared:WaitForChild("Config"):WaitForChild("PlayerMovementConfig"))
local Classes = require(Shared.Classes.ClassConfig)
local Motion = setmetatable({
	Duration = Config.DashDuration,
	Distance = Config.DashDistance,
}, { __index = function(_, key)
	if key == "Immunity" then return Config.DashImmunityDuration end
	if key == "Cost" then return Config.DashStaminaCost end
	if key == "RegenDelay" then return Classes.StaminaRegenDelay end
	if key == "RegenRate" then return Classes.StaminaRegen end
end })
Motion.HoverHeight = Config.DashHoverHeight or 0.7
Motion.HoverLiftDuration = Config.DashHoverLiftDuration or 0.065
Motion.HoverSettleDuration = Config.DashHoverSettleDuration or 0.1
function Motion.FlatUnit(value)
	if typeof(value) ~= "Vector3" then
		return nil
	end
	if value.X ~= value.X or value.Z ~= value.Z or math.abs(value.X) > 1e5 or math.abs(value.Z) > 1e5 then
		return nil
	end
	local flat = Vector3.new(value.X, 0, value.Z)
	if flat.Magnitude < 0.01 then
		return nil
	end
	return flat.Unit
end
function Motion.Kind(root, direction)
	local relative = root.CFrame:VectorToObjectSpace(direction)
	if math.abs(relative.X) > math.abs(relative.Z) then
		return relative.X < 0 and "Left" or "Right"
	end
	return relative.Z > 0 and "Back" or "Forward"
end
function Motion.Smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * t * (t * (t * 6 - 15) + 10)
end
function Motion.Speed(elapsed, exitSpeed)
	 
	exitSpeed = math.clamp(exitSpeed or 0, 0, 40)
	local taper = 0.075
	local plateau = (Motion.Distance - exitSpeed * taper * 0.5) / (Motion.Duration - taper * 0.5)
	local alpha = Motion.Smooth((elapsed - (Motion.Duration - taper)) / taper)
	return plateau + (exitSpeed - plateau) * alpha
end
function Motion.HoverVelocity(elapsed, currentY, baseY, timeScale)
	timeScale = math.clamp(timeScale or 1, 0, 2)
	if timeScale <= 0 then
		return 0
	end
	local lift = Motion.Smooth(elapsed / Motion.HoverLiftDuration)
	local settle = Motion.Smooth((Motion.Duration - elapsed) / Motion.HoverSettleDuration)
	local targetY = baseY + Motion.HoverHeight * lift * settle
	return math.clamp((targetY - currentY) * 28, -14, 14) * timeScale
end
function Motion.NewConstraint(root)
	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DashVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	velocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	velocity.ForceLimitsEnabled = true
	velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	velocity.MaxForce = math.max(root.AssemblyMass, 1) * 2500
	velocity.PlaneVelocity = Vector2.zero
	velocity.Enabled = false
	velocity.Parent = root
	return velocity, attachment
end
return Motion
