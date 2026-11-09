 -- P3.5 Debuffer: in Phase 3.5 every attack that lands has a P35DebufferChance (EncounterConfig) chance to
 -- apply one random card debuff (AttackDebuffService.Random). Each player is rolled at most once per
 -- P35DebufferRollWindow seconds, so a multi-hit attack rolls once rather than once per hit.
local B=script:FindFirstAncestor("BossSystem")
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Debuffs=require(B.Combat.AttackDebuffService)
return function(actor)
 local api={IsPassive=true}
 local rng=Random.new()
 local rolledAt=setmetatable({},{__mode="k"})
 function api.Apply(character)
  if actor:GetAttribute("Phase")~=3.5 or actor:GetAttribute("IsIllusion") then return nil end
  local now=workspace:GetServerTimeNow()
  if now<(rolledAt[character] or 0) then return nil end
  rolledAt[character]=now+(Config.P35DebufferRollWindow or 1)
  if rng:NextNumber()>=math.clamp(Config.P35DebufferChance or .25,0,1) then return nil end
  local chosen=Debuffs.Random(actor,character,rng,nil,"P3.5Debuffer(Passive)")
  if chosen then
   actor:SetAttribute("DebufferProcs",(actor:GetAttribute("DebufferProcs") or 0)+1)
   actor:SetAttribute("LastDebufferDebuff",chosen)
  end
  return chosen
 end
 function api.Reset() table.clear(rolledAt) end
 return api
end
