 
 
 
 
 
local CollectionService=game:GetService("CollectionService")
local V={}

 
function V.Build(cast,parent,center,S,info)
 local root=cast:Add(Instance.new("Part"))
 root.Name="P5BlackHoleRoot" root.Shape=Enum.PartType.Ball
 root.Anchored=true root.CanCollide=false root.CanTouch=false root.CanQuery=false root.CastShadow=false
 root.Color=S.Void root.Material=Enum.Material.SmoothPlastic
 root.Size=Vector3.one*S.CoreRadius*2*.2
 root.CFrame=CFrame.new(center)

 local light=Instance.new("PointLight")
 light.Color=S.Violet light.Brightness=3 light.Range=65 light.Shadows=false light.Parent=root

  
 root:SetAttribute("Born",workspace:GetServerTimeNow())
 root:SetAttribute("Core",S.CoreRadius) root:SetAttribute("Pull",S.PullRange)
 root:SetAttribute("Sky",S.SkyHeight) root:SetAttribute("Hover",S.HoverHeight)
 root:SetAttribute("SummonT",S.SummonTime) root:SetAttribute("RiftT",S.RiftTime or 0) root:SetAttribute("HoldT",S.HoldTime or 1.3) root:SetAttribute("ActiveT",S.ActiveDuration)
 root:SetAttribute("FadeT",S.FadeTime) root:SetAttribute("BurstAt",S.BurstAt)
 root:SetAttribute("ShockR",S.ShockRadius) root:SetAttribute("ArmT",S.ArmDelay)
 root:SetAttribute("Foot",info.Footprint) root:SetAttribute("GroundY",info.GroundY)
  
 root:SetAttribute("Stage","Summon") root:SetAttribute("Power",1)
 root:SetAttribute("CollapseAt",0) root:SetAttribute("Devoured",0)
 root:SetAttribute("DevourPos",center)

 -- the original client (P5BlackHoleRoot) draws the hole; VFXEngine adds the ground
 -- being pulled in and the explosion
 CollectionService:AddTag(root,"P5BlackHoleRoot")
 root:SetAttribute("VFX","BlackHoleDebris")
 CollectionService:AddTag(root,"VFXDecorate")
 root.Parent=parent

 local lastScale,lastGround,lastPower,devoured=.2,info.GroundY,1,0
 local api={}
 function api.Update(position,scale,groundY)
  scale=math.max(.02,scale)
  if math.abs(scale-lastScale)>.001 then
   lastScale=scale
   root.Size=Vector3.one*S.CoreRadius*2*scale
  end
  root.CFrame=CFrame.new(position)
  if groundY and math.abs(groundY-lastGround)>.05 then
   lastGround=groundY root:SetAttribute("GroundY",groundY)
  end
 end
 function api.Power(power)
  if math.abs(power-lastPower)>.01 then lastPower=power root:SetAttribute("Power",power) end
 end
 function api.Stage(name)
  if name=="Collapse" then root:SetAttribute("CollapseAt",workspace:GetServerTimeNow()) end
  root:SetAttribute("Stage",name)
 end
 function api.Devour(position)
  devoured+=1
  root:SetAttribute("DevourPos",position)
  root:SetAttribute("Devoured",devoured)
 end
 function api.Destroy() if root.Parent then root:Destroy() end end
 return api
end
return V
