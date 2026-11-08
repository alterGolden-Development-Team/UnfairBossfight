


local BeamMath = {}

local TAU = math.pi * 2

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function smooth(x)
	x = clamp01(x)
	return x * x * (3 - 2 * x)
end

BeamMath.Smooth = smooth

 
function BeamMath.Wrap(angle)
	return (angle + math.pi) % TAU - math.pi
end

function BeamMath.Heading(vector)
	return math.atan2(vector.Z, vector.X)
end

function BeamMath.Dir(heading)
	return Vector3.new(math.cos(heading), 0, math.sin(heading))
end

 
function BeamMath.AcquireStep(heading, desired, dt, S)
	local maxStep = math.rad(S.AcquireTurnRate) * dt
	return heading + math.clamp(BeamMath.Wrap(desired - heading), -maxStep, maxStep)
end

 
function BeamMath.HuntAuthority(t, S)
	local ramp = smooth((t - S.HoldTime) / S.HuntRamp)
	local relax = 1 - 0.6 * smooth((t - (S.FireDuration - S.CloseTime)) / S.CloseTime)
	return ramp * relax
end

 
function BeamMath.HuntStep(state, desired, dt, t, S)
	local vmax = math.rad(S.HuntMaxSpeed) * BeamMath.HuntAuthority(t, S)
	local err = BeamMath.Wrap(desired - state.Heading)
	local accel = S.HuntStiffness * err - S.HuntDamping * state.Speed
	local speed = math.clamp(state.Speed + accel * dt, -vmax, vmax)
	state.Speed = speed
	state.Heading = state.Heading + speed * dt
	return state
end

 
function BeamMath.Extrapolate(sampleHeading, sampleSpeed, age)
	return sampleHeading + sampleSpeed * math.clamp(age, 0, 0.25)
end

 
function BeamMath.Length(t, S)
	local x = clamp01(t / S.GrowTime) - 1
	local c1 = 1.1
	local c3 = c1 + 1
	return S.BeamRange * (1 + c3 * x * x * x + c1 * x * x)
end

 
function BeamMath.Width(t, S)
	local open = 1 - (1 - clamp01(t / S.OpenTime)) ^ 3
	local close = smooth((S.FireDuration - t) / S.CloseTime)
	local pulse = 1 + 0.06 * math.sin(t * 22)
	return S.BeamWidth * open * close * pulse
end

 
function BeamMath.Muzzle(pivot, heading, S)
	return pivot + BeamMath.Dir(heading) * S.MuzzleOffset
end

 
function BeamMath.Segment(pivot, heading, t, S)
	local dir = BeamMath.Dir(heading)
	local a = pivot + dir * S.MuzzleOffset
	return a, a + dir * BeamMath.Length(t, S), dir
end

function BeamMath.Feet(char,root)
 local foot=char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
 if foot and foot:IsA("BasePart") then return foot.Position.Y-foot.Size.Y*.5 end
 local h=char:FindFirstChildOfClass("Humanoid")
 return root.Position.Y-root.Size.Y*.5-(h and h.HipHeight or 2)
end

return BeamMath
