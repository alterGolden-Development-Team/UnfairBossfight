--[[
 DisorderWall - the Reality Disorderer's Diamond Protocol zones.
 A zone is an octahedron: a diamond footprint at Center (|dx| + |dz| <= Radius) that narrows to a point Upper studs above
 and Lower studs below. While a character's root is inside one they are immune to everything:
   PlayerEncounter.CanReceiveHit / ExecuteHit   -> no damage, no execution, including scripted finishers
   ClassService.S.Incoming                      -> no status damage
   HealthPenaltyService.Apply                   -> no max HP loss
   StatusEffectService.IsDebuffImmune           -> no debuff, stun or knockback
]]
local api = {}
local zones = {}

local function inside(zone, point)
  local d = point - zone.Center
  local h = d.Y >= 0 and zone.Upper or zone.Lower
  return math.abs(d.X) / zone.Radius + math.abs(d.Z) / zone.Radius + math.abs(d.Y) / h <= 1
end

function api.Add(center, radius, upper, lower, duration)
  local zone = { Center = center, Radius = radius, Upper = upper, Lower = lower, Ends = os.clock() + duration }
  table.insert(zones, zone)
  return zone
end

function api.Remove(zone)
  local i = table.find(zones, zone)
  if i then table.remove(zones, i) end
end

function api.Contains(point)
  local now = os.clock()
  for i = #zones, 1, -1 do
    local zone = zones[i]
    if now >= zone.Ends then
      table.remove(zones, i)
    elseif inside(zone, point) then
      return true, zone
    end
  end
  return false
end

function api.Protects(character)
  if #zones == 0 or typeof(character) ~= "Instance" then return false end
  local root = character:FindFirstChild("HumanoidRootPart")
  return root ~= nil and api.Contains(root.Position)
end

return api
