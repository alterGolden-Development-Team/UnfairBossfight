local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local B=script:FindFirstAncestor("BossSystem")
local Shared=require(B.Attacks.Shared.ShieldBreakCombat)
local V=require(B.Attacks.Shared.SwordmasterVFX)
local Status=require(B.Combat.StatusEffectService)
local Runtime=require(B.Combat.CombatRuntime)
local Audio=require(B.Presentation.CombatAudio)
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Style=require(script.Parent.Style)
local FX=require(script.Parent.Visuals)
local Sword=require(script.Parent.Sword)
local SBFX=require(B.Attacks.Shared.ShieldBreakVFX)

local C=Style.Colors

 
local PATTERN={
 {A0=-85,A1=85,P0=45,P1=-4,R0=0,R1=10},     
 {A0=85,A1=-85,P0=-4,P1=8,R0=10,R1=-20},    
 {A0=-85,A1=85,P0=8,P1=30,R0=-20,R1=35},    
 {A0=150,A1=-150,P0=75,P1=-12,R0=0,R1=0},   
}

local function lerp(a,b,t) return a+(b-a)*t end

return function(actor)
 local api=Shared.Skill(actor,"Swordsmaster","P1ContinousStrike",Style.Cooldown,function(ctx,target)
  if not ctx.Core.Alive(target) then target=ctx.Targets()[1] end
  if not target then return false end
  local cast=ctx.Cast("P1ContinousStrike",6)
   
  local fxCast=ctx.Cast("P1ContinousStrikeFX",8)
  local sword=Style.CustomSword and Sword.new(Style) or nil
  local weapon=V.Weapon and not sword and V.Weapon(ctx,cast,"Greatsword") or nil
   -- the normal sword is put away while the greatsword is out
  local Weapon=require(B.Boss.WeaponController)
  local armed=actor:GetAttribute("UnarmedCombat")~=true
  if armed then Weapon.SetUnarmed(actor,true) end
  local function place(cf)
   if sword then sword:Update(cf) elseif weapon then weapon.Update(cf) end
  end
  local aura=Instance.new("Highlight")
  aura.Adornee=actor;aura.FillColor=C.Aura;aura.OutlineColor=C.Core
  aura.FillTransparency=1;aura.OutlineTransparency=1
  aura.DepthMode=Enum.HighlightDepthMode.Occluded
  aura.Parent=actor
  local function glow(fill,outline,time)
   Tween:Create(aura,TweenInfo.new(time,Enum.EasingStyle.Quad),{FillTransparency=fill,OutlineTransparency=outline}):Play()
  end

  cast.OnDispose=function()
   if sword then sword:Destroy();sword=nil end
   aura:Destroy()
   if armed and actor.Parent then Weapon.SetUnarmed(actor,false) end
  end
  local function finish(result)
   cast:Dispose()
   return result
  end

  local function run()
   local root=ctx.Root
   ctx.Core.Face(target)
   local look=root.CFrame.Rotation
   local function poseCF(angle,pitch,roll)
    return CFrame.new(root.Position+Vector3.new(0,1,0))*look*CFrame.Angles(0,math.rad(angle),0)*CFrame.Angles(math.rad(pitch),0,math.rad(roll))
   end
   local function hold(duration,step)
    local t=0
    while t<duration do
     if not ctx.Valid() then return false end
     local dt=Run.Heartbeat:Wait()
     t+=dt
     step(math.clamp(t/duration,0,1),dt)
    end
    return true
   end

    
   local pose={A=-85,P=0,R=0}
   place(poseCF(pose.A,pose.P,pose.R))
   if sword then sword:Appear(.2);sword:SetCharge(120);sword:Heat(1,Style.Windup) end
   glow(.7,.2,Style.Windup)
   ctx.Core.PoseAngles({RightShoulder={150,0,-35},LeftShoulder={120,0,30},Waist={-8,0,0}},.2)
   Audio.Emit(actor,"NormalDraw",root)
   local ground=FX.Ground(root.Position,actor)
   FX.Telegraph(ground,Style.Range,Style.Windup,C.Aura)
   FX.Shake(root.Position,.3,Style.Windup,70)
   if not hold(Style.Windup,function(a)
    local jitter=Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*.5*a
    place(poseCF(-85,lerp(0,50,a),0)*CFrame.new(jitter))
   end) then return false end
   pose.A,pose.P,pose.R=-85,50,0
   if sword then sword:SetCharge(0) end

   local counts={}
   local total=#Style.Damage
   for strike,amount in ipairs(Style.Damage) do
    if not ctx.Valid() then return false end
    local finisher=strike==total
    local pat=finisher and PATTERN[4] or PATTERN[math.min(strike,3)]
    if ctx.Core.Alive(target) then ctx.Core.Face(target) end
    look=root.CFrame.Rotation

    if finisher then
      
     glow(.45,0,Style.FinisherWindup)
     ctx.Core.PoseAngles({RightShoulder={170,0,-20},LeftShoulder={150,0,20},Waist={-12,0,0}},Style.FinisherWindup)
     Audio.Emit(actor,"NormalDraw",root)
     local g=FX.Ground(root.Position,actor)
     FX.Telegraph(g,Style.Range+6,Style.FinisherWindup,C.Danger)
     FX.Shake(root.Position,.6,Style.FinisherWindup,80)
     if sword then sword:SetCharge(260) end
     local fromA,fromP,fromR=pose.A,pose.P,pose.R
     if not hold(Style.FinisherWindup,function(a)
      local jitter=Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*1.2*a
      place(poseCF(lerp(fromA,pat.A0,a),lerp(fromP,pat.P0,a),lerp(fromR,pat.R0,a))*CFrame.new(jitter))
     end) then return false end
     if sword then sword:SetCharge(0) end
     if ctx.Core.Alive(target) then ctx.Core.Face(target) end
     look=root.CFrame.Rotation
    end

    local swingTime=finisher and Style.FinisherSwing or Style.Swing
    local direction=pat.A1>pat.A0 and 1 or -1
    local hit={}
    local elapsed,freeze,ghostClock=0,0,0
    local previous=math.rad(pat.A0)
    local lastCF=poseCF(pat.A0,pat.P0,pat.R0)
    Audio.Emit(actor,"SwordSlash",root)
    if finisher then Audio.Emit(actor,"SwordSlash",root) end
    glow(finisher and .45 or .75,finisher and 0 or .3,.15)
    ctx.Core.PoseAngles({RightShoulder={40,0,-65*direction},Waist={10,(finisher and 80 or 45)*direction,0}},swingTime)
    if sword then
     place(lastCF)
     sword:SetTrails(true)
     sword:SetSwing(true)
    end
     
    do
     local roll=math.rad((pat.R0+pat.R1)*.5)
     local pitch=math.rad((pat.P0+pat.P1)*.25)
     local yawMid=math.rad((pat.A0+pat.A1)*.5)
     local arcFrame=CFrame.new(root.Position+Vector3.new(0,1.5,0))*look*CFrame.Angles(0,yawMid,0)*CFrame.Angles(pitch,0,roll)
     local span=math.rad(math.min(330,math.abs(pat.A1-pat.A0)))
     local reach=finisher and 21 or 16
     SBFX.Crescent(ctx,fxCast,arcFrame,reach,span,finisher and 5 or 3.2,finisher and C.Danger or C.Hot,C.Core,swingTime+.18,
      {Reverse=direction==1,Wipe=swingTime*.65,Grow=1.22,Segments=finisher and 24 or 16})
     fxCast:Schedule(.05,function()
      SBFX.Crescent(ctx,fxCast,arcFrame*CFrame.new(0,finisher and 1 or .6,0),reach*1.15,span*.9,finisher and 2 or 1.2,C.Gold,C.Core,swingTime+.12,
       {Reverse=direction==1,Wipe=swingTime*.6,Grow=1.35,Segments=14})
     end)
     SBFX.Streaks(ctx,fxCast,root.Position+Vector3.new(0,1.5,0),root.CFrame.LookVector,C.Hot,C.Core,finisher and 26 or 12,55,40,90,3)
    end
     
    local tr=target:FindFirstChild("HumanoidRootPart")
    if tr then
     local flat=Vector3.new(tr.Position.X-root.Position.X,0,tr.Position.Z-root.Position.Z)
     if flat.Magnitude>10 then
      local speed=Style.Lunge*(finisher and 1.3 or 1)
      root.AssemblyLinearVelocity=flat.Unit*math.min(speed,flat.Magnitude*3)+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
     end
    end
    counts[strike]=0
    while elapsed<swingTime and ctx.Valid() do
     local dt=Run.Heartbeat:Wait()
     if freeze>0 then
       
      freeze-=dt
      local shudder=Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*.8
      place(lastCF*CFrame.new(shudder))
      continue
     end
     elapsed+=dt
     local t=math.clamp(elapsed/swingTime,0,1)
     local a=1-(1-t)^2
     local angle=math.rad(lerp(pat.A0,pat.A1,a))
     lastCF=poseCF(math.deg(angle),lerp(pat.P0,pat.P1,a),lerp(pat.R0,pat.R1,a))
     place(lastCF)
     if sword then
      ghostClock+=dt
      if ghostClock>=(finisher and .05 or .07) then
       ghostClock=0
       sword:Ghost(finisher and C.Danger or C.Hot,finisher and .4 or .28)
      end
     end
     local frame=CFrame.new(root.Position+Vector3.new(0,1,0))*look
     for _,char in ipairs(ctx.Targets()) do
      if not hit[char] then
       local p=char.HumanoidRootPart.Position
       local caught=false
       for sample=0,6 do
        local ray=frame*CFrame.Angles(0,previous+(angle-previous)*sample/6,0)
        local q=ray:PointToObjectSpace(p)
        if math.abs(q.X)<=4.5 and math.abs(q.Y)<=7 and q.Z<=2 and q.Z>=-Style.Range then caught=true;break end
       end
       if caught and ctx.Core.CanHit(char,root.Position) then
        hit[char]=true
        local damage=ctx.Damage(char,amount,"P1ContinousStrike")
        if damage>0 then
         if finisher then AttackDebuffs.Apply(actor,char,"Hemorrhage",3,cast) end
         counts[strike]+=1
         local stun=ctx.Cast("GreatswordStun",Style.Stun+.05)
         Status.ApplyStun(char,stun,Style.Stun,0,{Family="SwordmasterStrike",AllowDefense=true})
         stun.OnDispose=function() Status.ReleaseRestraint(char,stun) end
         V.Burst(ctx,cast,p,finisher and 12 or 7)
         local away=Vector3.new(p.X-root.Position.X,0,p.Z-root.Position.Z)
         FX.Impact(p+Vector3.new(0,2,0),away+Vector3.new(0,.3,0),finisher,C.Hot,C.Core)
         FX.Shake(p,finisher and 1.8 or .6,finisher and .5 or .2,90)
         SBFX.Tint(ctx,p,finisher and C.Danger or C.Hot,finisher and .9 or .4,finisher and .3 or .15)
         SBFX.Crescent(ctx,fxCast,CFrame.new(p+Vector3.new(0,2,0))*CFrame.Angles(0,math.random()*6.28,math.rad(math.random(-50,50)))*CFrame.new(0,0,3),
          5,math.rad(120),1,C.Core,Color3.new(1,1,1),.2)
         freeze=Style.HitStop*(finisher and 1.8 or 1)
         if finisher then
          if Style.ScreenFlash then FX.Flash(C.Aura,.8,.5) end
          Runtime.Knockback(actor,char,p-root.Position,{Speed=90,Lift=38,Duration=.6,Sustain=.2,ContainsArena=true})
         end
        end
       end
      end
     end
     previous=angle
    end
    if sword then
     sword:SetSwing(false)
     sword:Ghost(finisher and C.Danger or C.Core,.35)
     task.delay(.08,function() if sword and sword.Model.Parent then sword:SetTrails(false) end end)
    end
    pose.A,pose.P,pose.R=pat.A1,pat.P1,pat.R1
    if finisher then
      
     local g=FX.Ground(root.Position,actor)
     FX.Shockwave(g,Style.Range+6,C.Hot,C.Core)
     FX.Shake(root.Position,2.4,.7,110)
      
     SBFX.Spikes(ctx,fxCast,g,14,Style.Range*.32,12,C.Gold,C.Core,1.1,30)
     SBFX.Spikes(ctx,fxCast,g,20,Style.Range*.6,8,C.Hot,C.Core,.95,18)
     for i=1,8 do
      local ang=i/8*math.pi*2+math.random()*.3
      local out=Vector3.new(math.cos(ang),0,math.sin(ang))
      local len=Style.Range*(.5+math.random()*.4)
      local at=g+out*len*.5+Vector3.new(0,.06,0)
      local scar=SBFX.Temp(ctx,fxCast,"StrikeGroundScar",CFrame.lookAt(at,at+out),Vector3.new(1.4,.08,len),C.Core,0,1.3)
      SBFX.Tween(scar,1.2,{Size=Vector3.new(.08,.08,len*1.1),Transparency=1})
     end
     SBFX.Tint(ctx,root.Position,C.Danger,1,.4,140)
     if Style.ScreenFlash then FX.Flash(C.Core,.6,.45) end
     glow(1,1,.5)
    end
    actor:SetAttribute("ContinuousStrike"..strike.."Hits",counts[strike])
    actor:SetAttribute("ContinuousStrike"..strike.."Damage",amount)
    if not ctx.Wait(finisher and Style.FinisherRecovery or Style.Recovery) then return false end
   end
   actor:SetAttribute("ContinuousStrikeCompleted",true)
   return true
  end

  local ok,result=pcall(run)
  if not ok then
   warn("[P1ContinousStrike] "..tostring(result))
   result=false
  end
  return finish(result)
 end)
 local ready=api.CanUse
 function api.CanUse(target)
  return ready() and (not target or target:FindFirstChild("HumanoidRootPart")
   and (target.HumanoidRootPart.Position-actor.HumanoidRootPart.Position).Magnitude<=Style.Range+4)
 end
 return api
end