local B=script:FindFirstAncestor("BossSystem")
return function(actor)
 local api={IsPassive=true}
 function api.IsActive()
  return actor.Parent~=nil and actor:GetAttribute("Phase")==5
   and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("IsGoldenClone")
   and not actor:GetAttribute("IsClone")
    -- a full-TP break (Combat/TPService) strips godmode for the rest of Phase 5
   and not actor:GetAttribute("GodStripped")
 end
 function api.Tick() actor:SetAttribute("Passive_P5God",api.IsActive()) end
 function api.Reset() if actor.Parent then actor:SetAttribute("Passive_P5God",false) end end
 return api
end
