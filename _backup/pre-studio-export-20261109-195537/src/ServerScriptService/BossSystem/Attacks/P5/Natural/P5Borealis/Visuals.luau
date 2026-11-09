local CollectionService=game:GetService("CollectionService")
local V={}
 
 
function V.Build(ctx,char,point,index,S)
 local p=ctx.Cast:Add(Instance.new("Part"))
 p.Name="P5BorealisBeacon" p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
 p.Transparency=1 p.Size=Vector3.one p.Position=point
 p:SetAttribute("Radius",S.Radius)p:SetAttribute("Sky",S.Sky)
 p:SetAttribute("Windup",S.Windup)p:SetAttribute("Chase",S.Chase)p:SetAttribute("Capture",S.Capture)p:SetAttribute("Fade",S.Fade)
 p:SetAttribute("Seed",index)p:SetAttribute("StartT",workspace:GetServerTimeNow())
 local tv=Instance.new("ObjectValue")tv.Name="Target"tv.Value=char tv.Parent=p
 local owner=Instance.new("ObjectValue")owner.Name="Owner"owner.Value=ctx.Actor owner.Parent=p
 p:SetAttribute("PhaseGeneration",ctx.Actor:GetAttribute("PhaseGeneration")or 0)
 p:SetAttribute("TimeStopExempt",true)
 p.Parent=ctx.Core.Effects
 -- rendered by VFXEngine.Effects.Borealis on each client
 p:SetAttribute("VFX","Borealis")
 CollectionService:AddTag(p,"VFXDecorate")
 return p
end
function V.Finish(record,full)
 if record.Done then return end
 record.Done=true
 if record.Anchor then
  record.Anchor:SetAttribute("Finale",full and true or false)
  record.Anchor:SetAttribute("DoneAt",workspace:GetServerTimeNow())
 end
end


return table.freeze(V)
