local B=script:FindFirstAncestor("BossSystem")
local A=require(B.Attacks.Shared.P5AstralCore)
local S=require(script.Parent.Style)
local Status=require(B.Combat.StatusEffectService)
local Visuals=require(script.Parent.Visuals)
local END=S.Windup+S.Chase+S.Capture+1  

 
local function aim(record,r)return r.Position end

return function(actor)
 local current
 local api={Cooldown=S.Cooldown,ManagesCooldown=true}
 function api.CanUse(target)return A.Ready(actor,S,current,target)end
 function api.Combo(target)
  local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Agile={"Speed"},Tell={"Windup"}})  -- difficulty knobs, this cast only
  local END=S.Windup+S.Chase+S.Capture+1
  if not api.CanUse(target)then return false end
  local core=require(B.Combat.AttackRegistry).For(actor,"P1CombatCore")
  return core.Perform(target,S.Name,function()
   A.StartCooldown(actor,S)
   local beams={}
   local function release(record)
    if record.Character then Status.ReleaseRestraint(record.Character,record.Token)end
    if record.Force then record.Force:Destroy()record.Force=nil end
    if record.Attachment then record.Attachment:Destroy()record.Attachment=nil end
   end
   local ctx=A.Create(actor,S,END+.3,function()
    for _,record in ipairs(beams)do release(record)end current=nil
   end)
   current=ctx.Cast ctx.Send("Start")
   for index,char in ipairs(ctx.Targets())do
    local point=ctx.Ground(char.HumanoidRootPart.Position)
    local record={Character=char,Point=point,Token={name=S.Name},NextTick=0,Ticks=0}
    record.Anchor=Visuals.Build(ctx,char,point,index,S)
    beams[#beams+1]=record
   end
   ctx.Step(function(dt,t)
    for _,record in ipairs(beams)do
     local char=record.Character
     local r=ctx.Target(char)and char.HumanoidRootPart
     if record.CaughtAt then
      if not r or t-record.CaughtAt>=S.Capture or not Status.ExclusivelyRestrainedBy(char,record.Token)then
       local full=r and t-record.CaughtAt>=S.Capture
       release(record)Visuals.Finish(record,full)
       if r and not record.Frosted then
        record.Frosted=true
        if full then ctx.Damage(char,S.FinaleDamage,false,record.Point+Vector3.yAxis*3)end
        Status.ApplySlow(char,S.FrostSlow,S.FrostSeconds,"P5BorealisFrost")
       end
      end
      if not record.Done then
        
       if record.Force then
        record.Force.Position=record.Hold+Vector3.yAxis*(S.Lift+math.sin((t-record.CaughtAt)*3.2)*.6)
       end
       if t>=record.NextTick then
        record.NextTick=t+S.TickInterval ctx.Damage(char,S.TickDamage,true,record.Point+Vector3.yAxis*3)
        record.Ticks+=1 record.Anchor:SetAttribute("Ticks",record.Ticks)
       end
      end
     elseif not record.Done and t>=S.Windup then
      if t>=S.Windup+S.Chase then Visuals.Finish(record,false)
      elseif r then
       local delta=(aim(record,r)-record.Point)*Vector3.new(1,0,1)
       if delta.Magnitude>0.01 then record.Point+=delta.Unit*math.min(delta.Magnitude,S.Speed*dt)end
       local reach=((r.Position-record.Point)*Vector3.new(1,0,1)).Magnitude
       if reach<=S.Radius and r.Position.Y>=record.Point.Y-3 and r.Position.Y<=record.Point.Y+S.Height and not r.Anchored and not char:GetAttribute("TimeFrozen")and not char:GetAttribute("Dashing")and not char:GetAttribute("PredictedDashActive")and ctx.CanHit(char,record.Point+Vector3.yAxis*3)and Status.Restrain(char,record.Token,S.Capture,{AllowDefense=true})then
        record.CaughtAt=t record.NextTick=t+S.TickInterval
        record.Anchor:SetAttribute("CaughtAt",workspace:GetServerTimeNow())
        record.Hold=Vector3.new(record.Point.X,r.Position.Y,record.Point.Z):Lerp(r.Position,1-S.Pull)
        record.Attachment=ctx.Cast:Add(Instance.new("Attachment"))record.Attachment.Parent=r
        record.Force=ctx.Cast:Add(Instance.new("AlignPosition"))
        local f=record.Force
        f.Mode=Enum.PositionAlignmentMode.OneAttachment f.Attachment0=record.Attachment
        f.ApplyAtCenterOfMass=true f.RigidityEnabled=false f.Responsiveness=12
        f.MaxForce=math.min(r.AssemblyMass*1500,1000000)f.MaxVelocity=20
        f.Position=record.Hold+Vector3.yAxis*S.Lift f.Parent=r
       end
      end
     end
     record.Anchor.Position=record.Point
    end
    if t>=END then ctx.Cast:Dispose()return false end
    return true
   end)
   return ctx.WaitFor(S.Windup)
  end)
 end
 function api.Dispose()if current then current:Dispose()end end
 return api
end
