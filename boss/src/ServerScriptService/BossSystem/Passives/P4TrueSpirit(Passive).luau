local B=script:FindFirstAncestor("BossSystem")
local S=require(B.Combat.StatusEffectService)
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
return function(actor)
 local api={IsPassive=true}
 function api.Apply(character,actual)
  if actual<=0 or math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4 or actor:GetAttribute("IsGoldenClone")
   or actor:GetAttribute("EncounterEnded") or actor:GetAttribute("PhaseTransitionInProgress") then return false end
  local applied=S.ApplyGoldenBurn(character,Config.TrueSpiritBurnDuration or 4,actor)
  if applied then actor:SetAttribute("TrueSpiritProcs",(actor:GetAttribute("TrueSpiritProcs") or 0)+1) end
  return applied
 end
 function api.Reset() S.ClearGoldenBurnFor(actor) end
 api.Dispose=api.Reset
 return api
end