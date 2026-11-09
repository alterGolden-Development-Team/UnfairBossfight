local BossSystem=script:FindFirstAncestor("BossSystem")
local Shared=require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Locomotion=require(BossSystem.Boss.BossLocomotion)
local Placement=require(BossSystem.Encounter.ArenaPlacement)
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local api={}
function api.Start(actor,role,getTarget)
 local ctx=Shared.Context(actor,role)
 local cast=ctx.Cast("ShieldGateMovement",math.huge)
 local elemental=role=="Elementalist"
 local walkSpeed=elemental and Config.ShieldGateElementalistWalkSpeed or Config.ShieldGateSwordsmasterWalkSpeed
 local dodgeSpeed=elemental and Config.ShieldGateElementalistDodgeSpeed or Config.ShieldGateSwordsmasterDodgeSpeed
 ctx.Core.Humanoid.WalkSpeed=walkSpeed
 actor:SetAttribute("ShieldGateRoleWalkSpeed",walkSpeed)
 local side=elemental and -1 or 1
 local nextDodge,dodgeUntil,dodgeDirection=0,0,nil
 local accum=0
 local function idle()
  actor:SetAttribute("ShieldGateDodging",false)
  if actor:GetAttribute("ShieldGateMovementState")~="Idle" then
   actor:SetAttribute("ShieldGateMovementState","Idle")
   if not actor:GetAttribute("AttackInProgress") then Locomotion.Idle(actor,0.12) end
  end
 end
 local leg=actor:FindFirstChild("Right Leg") or actor:FindFirstChild("Left Leg")
 local standing=ctx.Core.Humanoid.HipHeight+ctx.Root.Size.Y/2
  +(ctx.Core.Humanoid.RigType==Enum.HumanoidRigType.R6 and (leg and leg.Size.Y or 2) or 0)
 local function tryStep(direction,distance,face)
  if distance<0.001 then return false end
  local from=ctx.Root.Position
  local move=direction*distance
  if workspace:Blockcast(CFrame.new(from),Vector3.new(3,4,3),move,ctx.Filter()) then return false end
  local ground=Placement.GroundPoint(from+move,{Margin=6})
  if not ground or math.abs(ground.Y+standing-from.Y)>3 then return false end
  local position=Vector3.new(from.X+move.X,ground.Y+standing,from.Z+move.Z)
  ctx.Root.CFrame=CFrame.lookAt(position,position+face)
  ctx.Root.AssemblyLinearVelocity=Vector3.zero
  return true
 end
 cast.OnDispose=function()
  if actor.Parent then idle() end
 end
 cast:Step(function(dt)
  if not ctx.Valid() then cast:Dispose(); return false end
  if actor:GetAttribute("ClassStunFrame") or workspace:GetServerTimeNow()<(actor:GetAttribute("ClassStunnedUntil") or 0) then idle();return true end
  accum+=dt
  if accum<1/30 then return true end
  local step=math.min(accum,0.1);accum=0
  local mobileStrike=role=="Swordsmaster" and actor:GetAttribute("CurrentSkill")=="P1ContinousStrike" and actor:GetAttribute("AttackInProgress")==true
  if (actor:GetAttribute("CloneState")~="Waiting" or actor:GetAttribute("AttackInProgress")) and not mobileStrike
   or actor:GetAttribute("TimeFrozen") then
   idle();return true
  end
  local target=getTarget()
  if not ctx.Core.Alive(target) then idle();return true end
  local delta=target.HumanoidRootPart.Position-ctx.Root.Position
  local flat=Vector3.new(delta.X,0,delta.Z)
  if flat.Magnitude<0.01 then idle();return true end
  local toward=flat.Unit
  local right=Vector3.new(-toward.Z,0,toward.X)
  local now=workspace:GetServerTimeNow()
  local character=require(BossSystem.Combat.AttackTargetContinuity).Character(target) or target
  local swing=math.max(character:GetAttribute("SwordSwingStartedAt") or 0,character:GetAttribute("ClassAttackStartedAt") or 0)
  local threat=flat.Magnitude<Config.ShieldGateDodgeThreatRadius
   and (now-swing<0.65 or character:GetAttribute("Dashing")==true)
  if threat and now>=nextDodge then
   side=-side
   dodgeDirection=(right*side+toward*0.25).Unit
   dodgeUntil=now+Config.ShieldGateDodgeDuration
   nextDodge=now+Config.ShieldGateDodgeCooldown
   actor:SetAttribute("ShieldGateDodgeCount",(actor:GetAttribute("ShieldGateDodgeCount") or 0)+1)
  end
  local dodging=now<dodgeUntil
  actor:SetAttribute("ShieldGateDodging",dodging)
  local stop=role=="Elementalist" and 10 or 9
  local direction,speed,distance
  if dodging then
   direction,speed=dodgeDirection,dodgeSpeed
   distance=speed*step
  elseif flat.Magnitude>stop then
   direction,speed=toward,walkSpeed
   distance=math.min(speed*step,flat.Magnitude-stop)
  elseif flat.Magnitude<5 then
   direction,speed=-toward,walkSpeed
   distance=speed*step
  else
   direction,speed=right*side,walkSpeed*0.5
   distance=speed*step
  end
  local moved=tryStep(direction,distance,toward)
  if not moved then
   for _,angle in ipairs({side*45,side*90,-side*45,-side*90}) do
    local alternate=CFrame.Angles(0,math.rad(angle),0):VectorToWorldSpace(direction)
    if tryStep(alternate,distance,toward) then moved=true;break end
   end
  end
  if moved then
   if not mobileStrike then Locomotion.Run(actor,speed) end
   actor:SetAttribute("ShieldGateMovementState",dodging and "Dodge" or "Walk")
  else idle() end
  return true
 end)
 return cast
end
return api
