local Placement = require(script:FindFirstAncestor("BossSystem").Encounter.ArenaPlacement)
local Locomotion = {}
local UP = Vector3.yAxis
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
function Locomotion.Step(copy, goal, speed, dt, core, copies, focus)
	local start = copy.Root.Position
	local delta = flat(goal - start)
	if delta.Magnitude < 0.55 then
		if focus then
			local aim = flat(focus - start)
			if aim.Magnitude > 0.01 then
				local facing = CFrame.lookAt(start, start + aim).Rotation
				copy.Model:PivotTo(CFrame.new(start) * copy.Root.CFrame.Rotation:Lerp(facing, 1 - math.exp(-10 * dt)))
			end
		end
		copy.Speed = 0; return 0
	end
	local direction = delta.Unit
	 
	local separation = Vector3.zero
	for _, other in ipairs(copies) do
		if other ~= copy and not other.Gone and other.Model.Parent then
			local away = flat(start - other.Root.Position)
			if away.Magnitude > 0.05 and away.Magnitude < 4.5 then
				separation += away.Unit * (1 - away.Magnitude / 4.5)
			end
		end
	end
	local desired = direction + separation * 1.4
	if desired.Magnitude > 0.01 then direction = desired.Unit end
	local distance = math.min(delta.Magnitude, speed * dt)
	local best, score
	local params = core.Params()
	local body = Vector3.new(2.8, 4, 2.8)
	local blockedAhead = workspace:Blockcast(CFrame.new(start), body, delta.Unit * math.min(delta.Magnitude, 12), params)
	local angles
	if blockedAhead then
		 
		copy.AvoidSign = copy.AvoidSign or ((copy.Index or 1) % 2 == 0 and 1 or -1)
		local side = copy.AvoidSign
		angles = {35 * side, 60 * side, 90 * side, 115 * side, 145 * side}
	else
		copy.AvoidSign = nil
		angles = {0, 35, -35, 70, -70, 110, -110}
	end
	for _, degrees in ipairs(angles) do
		local dir = CFrame.fromAxisAngle(UP, math.rad(degrees)):VectorToWorldSpace(direction)
		local move = dir * distance
		local blocked = workspace:Blockcast(CFrame.new(start), body, dir * (distance + 0.2), params) ~= nil
		if not blocked then
			local ground = Placement.GroundPoint(start + move, {Margin = 8})
			if ground then
				local candidate = ground + UP * copy.Height
				local value = (flat(goal - candidate)).Magnitude + math.abs(degrees) * 0.015
				if not score or value < score then best, score = candidate, value end
			end
		end
	end
	if not best then copy.BlockedFor = (copy.BlockedFor or 0) + dt; copy.Speed = 0; return 0 end
	copy.BlockedFor = 0
	local movement = flat(best - start)
	local facing = focus and flat(focus - best) or movement
	if facing.Magnitude < 0.01 then facing = flat(copy.Root.CFrame.LookVector) end
	local desiredFrame = CFrame.lookAt(best, best + facing)
	local rotation = copy.Root.CFrame.Rotation:Lerp(desiredFrame.Rotation, 1 - math.exp(-10 * dt))
	copy.Model:PivotTo(CFrame.new(best) * rotation)
	copy.Speed = movement.Magnitude / math.max(dt, 0.001)
	return copy.Speed
end
return Locomotion
