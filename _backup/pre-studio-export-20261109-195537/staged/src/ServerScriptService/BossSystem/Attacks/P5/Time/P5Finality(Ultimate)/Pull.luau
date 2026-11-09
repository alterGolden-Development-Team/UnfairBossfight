local G=require(script.Parent.Geometry)
local P={}

local FLAT=Vector3.new(1,0,1)
local function steer(record,drift,acceleration)
 local root=record.Root
 local mass=root.AssemblyMass
 local h=root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
 if mass<=0 or mass==math.huge or not h or h.Health<=0 then
  record.Force.Enabled=false
  return false
 end
 local horizontal=root.AssemblyLinearVelocity*FLAT
 if horizontal.Magnitude>h.WalkSpeed*3.5+drift.Magnitude then  -- only a real dash slips it, for a moment
  record.Force.Enabled=false
  return false
 end
 record.Force:SetAttribute("PullDrift",drift)
 record.Force:SetAttribute("PullAcceleration",acceleration)
 local target=drift
 record.Force.MaxPlanarAxesForce=Vector2.one*(mass*acceleration)
 record.Force.PlaneVelocity=Vector2.new(target.X,target.Z)
 record.Force.Enabled=true
 return true
end

function P.Attach(cast,root)
 local a=cast:Add(Instance.new("Attachment")) a.Name="FinalityPullAttachment" a.Parent=root
 local force=cast:Add(Instance.new("LinearVelocity"))
 force.Name="FinalityPull" force.Attachment0=a force.RelativeTo=Enum.ActuatorRelativeTo.World
 force.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
 force.PrimaryTangentAxis=Vector3.xAxis force.SecondaryTangentAxis=Vector3.zAxis
 force.ForceLimitsEnabled=true force.ForceLimitMode=Enum.ForceLimitMode.PerAxis
 force.MaxPlanarAxesForce=Vector2.zero force.PlaneVelocity=Vector2.zero force.Parent=root
 return {Root=root,Force=force,Attachment=a}
end

function P.Update(record,center,progress,style,beats)
 local d=(center-record.Root.Position)*FLAT
 if d.Magnitude<=style.SettleRadius or d.Magnitude>=style.PullRange then
  record.Force.Enabled=false
  return 0
 end
 local dir=d.Unit
 local falloff=.4+.6*(1-math.clamp(d.Magnitude/style.PullRange,0,1))
 local speed=math.min(style.PullSpeedLimit,G.PullSpeed(progress,style,beats)*falloff)
 local swirl=speed*style.PullSwirl*math.clamp((d.Magnitude-style.SettleRadius)/(style.SettleRadius*6),0,1)
 local drift=dir*speed+Vector3.yAxis:Cross(dir)*swirl
 if drift.Magnitude>style.PullSpeedLimit then drift=drift.Unit*style.PullSpeedLimit end
 steer(record,drift,style.PullAccelerationLimit)
 return speed
end
function P.Release(record)record.Force:Destroy()record.Attachment:Destroy()end
return table.freeze(P)
