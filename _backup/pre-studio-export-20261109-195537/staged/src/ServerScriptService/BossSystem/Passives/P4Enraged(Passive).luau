local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
return function(actor)
 local api = { IsPassive = true }
 local random = Random.new()
 local glow
 local function active()
  local h = actor:FindFirstChildOfClass("Humanoid")
  return actor.Parent and h and h.Health > 0 and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4
   and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("EncounterEnded")
 end
 function api.Reset()
  if glow then glow:Destroy() glow=nil end
  actor:SetAttribute("EnragedStacks", 0)
  actor:SetAttribute("EnragedCritChance", 0)
  actor:SetAttribute("EnragedCritDamage", 0)
  actor:SetAttribute("EnragedUntil", 0)
  actor:SetAttribute("EnragedHUDReadyAt", 0)
  actor:SetAttribute("EnragedHUDPulseAt", 0)
 end
 function api.Tick()
  if not active() or workspace:GetServerTimeNow() >= (actor:GetAttribute("EnragedUntil") or 0) then api.Reset() end
 end
 function api.Apply(_, actualDamage)
  if not active() or type(actualDamage) ~= "number" or actualDamage ~= actualDamage
   or actualDamage <= 0 or actualDamage == math.huge then return false end
  api.Tick()
  local cap = math.max(math.ceil(Config.Phase4EnragedMaxCritChance / Config.Phase4EnragedCritChancePerHit),
   math.ceil(Config.Phase4EnragedMaxCritDamage / Config.Phase4EnragedCritDamagePerHit))
  local stacks = math.min(cap, (actor:GetAttribute("EnragedStacks") or 0) + 1)
  actor:SetAttribute("EnragedStacks", stacks)
  actor:SetAttribute("EnragedCritChance", math.min(Config.Phase4EnragedMaxCritChance, stacks * Config.Phase4EnragedCritChancePerHit))
  actor:SetAttribute("EnragedCritDamage", math.min(Config.Phase4EnragedMaxCritDamage, stacks * Config.Phase4EnragedCritDamagePerHit))
  local now = workspace:GetServerTimeNow()
  actor:SetAttribute("EnragedUntil", now + Config.Phase4EnragedDuration)
  if not glow or not glow.Parent then
   glow=Instance.new("Highlight") glow.Name="GoldenEnragedGlow" glow.Adornee=actor
   glow.FillColor=Color3.fromRGB(255,91,38) glow.OutlineColor=Color3.fromRGB(255,206,61)
   glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.OutlineTransparency=.15 glow.Parent=actor
  end
  glow.FillTransparency=.8-.3*math.clamp(stacks/cap,0,1)
   
  if now >= (actor:GetAttribute("EnragedHUDReadyAt") or 0) then
   actor:SetAttribute("EnragedHUDReadyAt", now + Config.Phase4EnragedHUDCooldown)
   actor:SetAttribute("EnragedHUDPulseAt", now)
  end
  return true
 end
 function api.Multiplier(roll)
  api.Tick()
  if not active() then return 1 end
  local chance = actor:GetAttribute("EnragedCritChance") or 0
  if (roll or random:NextNumber()) < chance then
   return 1 + (actor:GetAttribute("EnragedCritDamage") or 0)
  end
  return 1
 end
 api.Dispose = api.Reset
 return api
end
