local BossSystem = script:FindFirstAncestor("BossSystem")
 
 
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Service = {}
local random = Random.new()
local cached
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include
floorParams.RespectCanCollide = true
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.RespectCanCollide = true
overlap.MaxParts = 20

local function finite(number)
	return number == number and math.abs(number) < 1e7
end
local function validPoint(point)
	return typeof(point) == "Vector3" and finite(point.X) and finite(point.Y) and finite(point.Z)
end
local function validFrame(frame)
	if typeof(frame) ~= "CFrame" then
		return false
	end
	for _, value in ipairs({ frame:GetComponents() }) do
		if not finite(value) then
			return false
		end
	end
	return true
end
local function bounds()
	local arena = cached and cached.Arena
	local floor = cached and cached.Floor
	if not arena or arena.Parent ~= workspace or not floor or not floor.Parent then
		arena = workspace:FindFirstChild("GoldenGrasslandArena")
		floor = arena and arena:FindFirstChild("Grassland")
		if not floor or not floor:IsA("BasePart") then
			return nil
		end
		cached = { Arena = arena, Floor = floor }
	end
	if cached.SourceFrame ~= floor.CFrame or cached.SourceSize ~= floor.Size then
		cached.SourceFrame, cached.SourceSize = floor.CFrame, floor.Size
		cached.Frame = floor.CFrame * CFrame.new(0, floor.Size.Y * 0.5, 0)
		cached.Width, cached.Depth = floor.Size.X, floor.Size.Z
		cached.HalfX, cached.HalfZ = floor.Size.X * 0.5, floor.Size.Z * 0.5
		floorParams.FilterDescendantsInstances = { floor }
	end
	return cached
end
function Service.GetBounds()
	return bounds()
end
function Service.Contains(point, margin)
	local b = bounds()
	if not b or not validPoint(point) then
		return false
	end
	margin = math.max(0, tonumber(margin) or 0)
	local localPoint = b.Frame:PointToObjectSpace(point)
	return math.abs(localPoint.X) <= b.HalfX - margin and math.abs(localPoint.Z) <= b.HalfZ - margin
end
function Service.GroundPoint(point, options)
	options = options or {}
	local b = bounds()
	if not b or not validPoint(point) then
		return nil
	end
	local margin = math.max(0, tonumber(options.Margin) or 0)
	local localPoint = b.Frame:PointToObjectSpace(point)
	if options.Clamp then
		localPoint = Vector3.new(
			math.clamp(localPoint.X, -b.HalfX + margin, b.HalfX - margin),
			0,
			math.clamp(localPoint.Z, -b.HalfZ + margin, b.HalfZ - margin)
		)
		point = b.Frame:PointToWorldSpace(localPoint)
	elseif not Service.Contains(point, margin) then
		return nil
	end
	local hit = workspace:Raycast(Vector3.new(point.X, b.Frame.Y + 100, point.Z), Vector3.new(0, -200, 0), floorParams)
	if not hit or hit.Normal.Y < 0.65 then
		return nil
	end
	return hit.Position
end
Service.GetGround = Service.GroundPoint

local function dimensions(model)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	local h = model and model:FindFirstChildOfClass("Humanoid")
	local rootHalf = root and root.Size.Y * 0.5 or 1
	local height = rootHalf + (h and h.HipHeight or 2)
	if h and h.RigType == Enum.HumanoidRigType.R6 then
		local leg = model:FindFirstChild("Right Leg") or model:FindFirstChild("Left Leg")
		height += leg and leg.Size.Y or 2
	end
	return math.max(height, 1), root
end
local function exclude(model)
	local list = { Runtime.Effects, Runtime.Summons }
	if model then
		table.insert(list, model)
	end
	 
	for _, target in ipairs(Runtime.AllTargets()) do
		table.insert(list, target)
	end
	overlap.FilterDescendantsInstances = list
end
function Service.Validate(model, desired, options)
	options = options or {}
	if not validFrame(desired) then
		return nil, "invalid frame"
	end
	local margin = math.max(0, tonumber(options.Margin) or 4)
	if not Service.Contains(desired.Position, margin) then
		return nil, "outside arena"
	end
	local ground = Service.GroundPoint(desired.Position, { Margin = margin })
	if not ground then
		return nil, "no arena floor"
	end
	local standingHeight = dimensions(model)
	local position = desired.Position
	if options.PreserveHeight then
		if position.Y < ground.Y + standingHeight - 0.15 then
			return nil, "below safe floor"
		end
		if position.Y > ground.Y + (options.MaxHeight or 100) then
			return nil, "above arena"
		end
	else
		position = Vector3.new(position.X, ground.Y + standingHeight, position.Z)
	end
	local frame = CFrame.new(position) * desired.Rotation
	local bodyHeight = standingHeight + 2.7
	local center = position + Vector3.new(0, bodyHeight * 0.5 - standingHeight + 0.08, 0)
	local look = Vector3.new(frame.LookVector.X, 0, frame.LookVector.Z)
	if look.Magnitude < 0.01 then
		look = Vector3.new(0, 0, -1)
	end
	local box = CFrame.lookAt(center, center + look)
	exclude(model)
	local size = options.ClearanceSize or Vector3.new(3.4, bodyHeight, 3.4)
	for _, part in ipairs(workspace:GetPartBoundsInBox(box, size, overlap)) do
		if part.CanCollide then
			return nil, "blocked by " .. part.Name
		end
	end
	return frame
end
function Service.ResolveRecorded(model, saved, options)
	options = options or {}
	local settings = table.clone(options)
	settings.PreserveHeight = true
	local frame, reason = Service.Validate(model, saved, settings)
	if frame then
		return frame
	end
	if not validFrame(saved) then
		return nil, reason
	end
	local ground = Service.GroundPoint(saved.Position, { Margin = settings.Margin or 4 })
	local standingHeight = dimensions(model)
	local gap = ground and ground.Y + standingHeight - saved.Y or math.huge
	 
	 
	if gap > 0 and gap <= 1.5 then
		local grounded = CFrame.new(saved.X, ground.Y + standingHeight, saved.Z) * saved.Rotation
		frame = Service.Validate(model, grounded, settings)
		if frame then
			return frame, "ground corrected"
		end
		saved = grounded
	end
	 
	local search = math.clamp(tonumber(options.SearchRadius) or 12, 0, 24)
	for radius = 3, search, 3 do
		for index = 0, 7 do
			local angle = index * math.pi / 4
			local delta = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			frame = Service.Validate(model, saved + delta, settings)
			if frame then
				return frame, "nearby safe point"
			end
		end
	end
	return nil, reason
end
function Service.Random(model, rng, options)
	options = options or {}
	rng = rng or random
	local b = bounds()
	if not b then
		return nil, "arena missing"
	end
	local margin = math.max(4, tonumber(options.Margin) or 6)
	local maxX, maxZ = b.HalfX - margin, b.HalfZ - margin
	if maxX <= 0 or maxZ <= 0 then
		return nil, "arena too small"
	end
	local _, root = dimensions(model)
	local rotation = options.Rotation or (root and root.CFrame.Rotation) or CFrame.identity
	for _ = 1, math.clamp(tonumber(options.Attempts) or 24, 1, 40) do
		local point =
			b.Frame:PointToWorldSpace(Vector3.new(rng:NextNumber(-maxX, maxX), 0, rng:NextNumber(-maxZ, maxZ)))
		if not root or (point - root.Position).Magnitude >= (options.MinDistance or 0) then
			local frame = Service.Validate(model, CFrame.new(point) * rotation, options)
			if frame then
				return frame
			end
		end
	end
	return nil, "no clear random point"
end
function Service.RandomPosition(model, margin, rng)
	local frame = Service.Random(model, rng, { Margin = margin or 6 })
	return frame and frame.Position or nil
end
return Service
