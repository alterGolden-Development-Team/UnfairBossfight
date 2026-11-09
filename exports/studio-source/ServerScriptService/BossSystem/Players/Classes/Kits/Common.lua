 
local C = {}

function C.Flat(v)
  local f = Vector3.new(v.X, 0, v.Z)
  return f.Magnitude > 0.01 and f.Unit or nil
end
function C.AimDir(char, aim)
  local root = char.HumanoidRootPart
  local d = aim and C.Flat(aim - root.Position)
  return d or C.Flat(root.CFrame.LookVector) or Vector3.zAxis
end
function C.AimDir3D(from, aim, fallback)
  if aim and (aim - from).Magnitude > 0.1 then
    return (aim - from).Unit
  end
  return fallback
end
function C.Hand(char, side)
  if side ~= "Left" then
    local gear = char:FindFirstChild("ClassGear")
    local tip = gear and gear:FindFirstChild("Tip", true)
    if tip and tip:IsA("Attachment") then
      return tip.WorldPosition
    end
  end
  local arm = char:FindFirstChild(side == "Left" and "Left Arm" or "Right Arm")
  return arm and (arm.CFrame * CFrame.new(0, -1.1, 0)).Position or char.HumanoidRootPart.Position
end
function C.InFront(char, target, range, minDot)
  local root = char.HumanoidRootPart
  local delta = target.HumanoidRootPart.Position - root.Position
  if delta.Magnitude > range then
    return false
  end
  local flat = C.Flat(delta)
  return not flat or flat:Dot(C.Flat(root.CFrame.LookVector) or flat) >= (minDot or 0)
end
 
function C.SegmentDistance(p, a, b)
  local ab = b - a
  local t = ab.Magnitude > 0 and math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1) or 0
  return (p - (a + ab * t)).Magnitude
end

 
 
function C.Move(S, player, char, direction, speed, duration, opts)
 opts = opts or {}
 if not S.CanAct(char) then return end
 local revision = char:GetAttribute("ClassActionRevision") or 0
  S.Remote():FireClient(player, "Move", { Direction = direction, Speed = speed, Duration = duration, Homing = player:GetAttribute("ClassAutoAim")~=false and opts.Homing or nil })
  local hit = false
  local started = os.clock()
  task.spawn(function()
     
    while os.clock() - started < duration + 0.45 and S.Alive(char) do
   if not S.CanAct(char) or player.Character ~= char
    or (char:GetAttribute("ClassActionRevision") or 0) ~= revision then
    S.Remote():FireClient(player,"MoveStop")
    break
   end
      if opts.OnContact and not hit then
        local target = S.TargetNear(char.HumanoidRootPart.Position, opts.ContactRadius or 6)
        if target then
          hit = true
          opts.OnContact(target)
          if opts.StopOnContact then
            S.Remote():FireClient(player, "MoveStop")
            break
          end
        end
      end
      task.wait()
    end
  if opts.OnEnd then
   opts.OnEnd(hit, not S.CanAct(char) or (char:GetAttribute("ClassActionRevision") or 0) ~= revision)
  end
  end)
end

 
 
function C.Path(S, char, dir, distance)
  local root = char.HumanoidRootPart
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.RespectCanCollide = true
  local ignore = { char }
  local fx = workspace:FindFirstChild("ClassEffects")
  if fx then
    table.insert(ignore, fx)
  end
  for _, target in ipairs(S.Targets()) do
    table.insert(ignore, target)
  end
  for _, other in ipairs(game:GetService("Players"):GetPlayers()) do
    if other.Character then
      table.insert(ignore, other.Character)
    end
  end
  params.FilterDescendantsInstances = ignore
  local hit = workspace:Raycast(root.Position, dir * (distance + 3), params)
  local free = hit and math.max(0, hit.Distance - 2.5) or distance
  return root.Position + dir * free, free
end

 
function C.SegmentTarget(S, a, b, radius)
  local best, bestD
  for _, m in ipairs(S.Targets()) do
    local p = m.HumanoidRootPart.Position
    local d = C.SegmentDistance(Vector3.new(p.X, 0, p.Z), Vector3.new(a.X, 0, a.Z), Vector3.new(b.X, 0, b.Z))
    if d <= radius + 2.5 and math.abs(p.Y - a.Y) <= 9 and (not bestD or d < bestD) then
      best, bestD = m, d
    end
  end
  return best
end

return C
