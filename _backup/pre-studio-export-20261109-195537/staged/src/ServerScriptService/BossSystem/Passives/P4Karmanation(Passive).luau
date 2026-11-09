local B=script:FindFirstAncestor("BossSystem")
local S=require(B.Combat.StatusEffectService)
return function(actor)
 local api={IsPassive=true}
 function api.Apply(character,actual)
  if actual<=0 or math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4 or actor:GetAttribute("IsGoldenClone")
   or actor:GetAttribute("EncounterEnded") or actor:GetAttribute("PhaseTransitionInProgress") then return false end
  local applied=S.ApplyFear(character,2,actor)
  if applied then actor:SetAttribute("KarmanationProcs",(actor:GetAttribute("KarmanationProcs") or 0)+1) end
  return applied
 end
 function api.Reset() S.ClearFearFor(actor) end
 api.Dispose=api.Reset
 return api
end