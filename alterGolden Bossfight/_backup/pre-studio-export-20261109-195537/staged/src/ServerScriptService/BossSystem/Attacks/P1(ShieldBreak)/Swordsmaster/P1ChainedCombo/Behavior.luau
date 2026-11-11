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
local FX=require(script.Parent.FX)
local Weapons=require(script.Parent.Weapons)
local SBFX=require(B.Attacks.Shared.ShieldBreakVFX)

local C=Style.Colors
local UP=Vector3.new(0,1,0)

local function lerp(a,b,t) return a+(b-a)*t end
local function jitter(m) return Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*m end

 
local MOTION={
 Sword={A={-70,55,25,0},B={70,-8,-20,0},Ease="out"},
 Sickle={A={70,-15,-50,0},B={-70,18,45,0},Ease="out"},
 Rapier={A={0,2,0,-3},B={0,2,0,-3},Ease="out"},
 Hammer={A={0,95,0,0},B={0,-6,0,3},Ease="in"},
}
local NEUTRAL={0,10,0,-2}
local SHAKE={Sword=.45,Sickle=.45,Chain=.5,Rapier=.35,Laser=.5,Hammer=2.4}

return function(actor)
 local api=Shared.Skill(actor,"Swordsmaster","P1ChainedCombo",Style.Cooldown,function(ctx,target)
  if not ctx.Core.Alive(target) then return false end
  if (target.HumanoidRootPart.Position-ctx.Root.Position).Magnitude>Style.Range then return false end
  local cast=ctx.Cast("P1ChainedCombo",7)
  local fxCast=ctx.Cast("P1ChainedComboFX",9)
  local victims,binds={}, {}
  local weapon,aura
  local function unbind(char,shatter)
   local bind=binds[char]
   if bind then
    binds[char]=nil
    if shatter then bind:Shatter() else bind:Destroy() end
   end
  end
  actor:SetAttribute("ShieldChainResistance",Style.Resistance)
  actor:SetAttribute("ChainedComboResistanceUntil",workspace:GetServerTimeNow()+6.5)
  cast.OnDispose=function()
   if actor.Parent then actor:SetAttribute("ShieldChainResistance",0);actor:SetAttribute("ChainedComboResistanceUntil",0) end
   for char in pairs(victims) do
    Status.ReleaseRestraint(char,cast)
    if char.Parent then char:SetAttribute("SwordmasterChained",false) end
   end
   for char in pairs(binds) do unbind(char,true) end
   if weapon then pcall(function() weapon:Destroy() end) end
   if aura then pcall(function() aura:Destroy() end) end
  end

  local function run()
   local root=ctx.Root
   local function fail() cast:Dispose();return false end
   local function hand()
    local ok,pos=pcall(ctx.HandPosition,"Right")
    if ok and typeof(pos)=="Vector3" then return pos end
    return root.Position+Vector3.new(0,1.5,0)
   end
   local function primary()
    if victims[target] and ctx.Core.Alive(target) then return target end
    for char in pairs(victims) do
     if ctx.Core.Alive(char) then return char end
    end
    return target
   end
   local function hold(duration,step)
    local t=0
    while t<duration do
     if not ctx.Valid() or not cast:Alive() then return false end
     local dt=Run.Heartbeat:Wait()
     t+=dt
     step(math.clamp(t/duration,0,1),dt)
    end
    return true
   end
   local function glow(color,fill,outline,time)
    if not aura then return end
    Tween:Create(aura,TweenInfo.new(time,Enum.EasingStyle.Quad),{FillColor=color,FillTransparency=fill,OutlineTransparency=outline}):Play()
   end

   ctx.Core.Face(target)
   aura=Instance.new("Highlight")
   aura.Adornee=actor;aura.FillColor=C.Gold;aura.OutlineColor=C.Core
   aura.FillTransparency=1;aura.OutlineTransparency=1
   aura.DepthMode=Enum.HighlightDepthMode.Occluded
   aura.Parent=actor

    
   local ground=FX.Ground(root.Position,actor)
   FX.Telegraph(ground,Style.Range,Style.Windup,C.Gold)
   FX.Shake(root.Position,.25,Style.Windup,60)
   ctx.Core.PoseAngles({RightShoulder={120,0,-20},LeftShoulder={110,0,20}},.2)
   Audio.Emit(actor,"NormalDraw",root)
   glow(C.Gold,.7,.2,Style.Windup)
   local orb=FX.Part(Vector3.one*.5,C.Core,CFrame.new(hand()),Enum.PartType.Ball,.1)
   local halo=FX.Part(Vector3.one*.5,C.Gold,CFrame.new(hand()),Enum.PartType.Ball,.5)
   local gathered=hold(Style.Windup,function(a)
    local p=hand()
    orb.Size=Vector3.one*lerp(.5,3.2,a);orb.Position=p
    halo.Size=Vector3.one*lerp(.8,7,a);halo.Position=p
    if math.random()<.5 then FX.Spark(p+jitter(8),C.Gold,C.Core,1,10) end
   end)
   FX.Fade(orb,.15,{Size=Vector3.one*8})
   FX.Fade(halo,.2,{Size=Vector3.one*14})
   if not gathered then return fail() end

    
   local count=0
   for _,char in ipairs(ctx.Targets()) do
    if (char.HumanoidRootPart.Position-root.Position).Magnitude<=Style.Range
     and ctx.Core.CanHit(char,root.Position)
     and Status.Restrain(char,cast,Style.TrapDuration,{AllowDefense=true}) then
     victims[char]=true;count+=1
     char:SetAttribute("SwordmasterChained",true)
     if Style.CustomChains then
      binds[char]=FX.ChainBind(root.Position,char,C.Gold,C.Core)
      FX.Impact(char.HumanoidRootPart.Position,UP,false,C.Gold,C.Core)
     else
      V.Chain(ctx,cast,char)
     end
    end
   end
   actor:SetAttribute("ChainedComboCaptured",count)
   if count==0 then return fail() end
   FX.GroundRing(ground+Vector3.new(0,.1,0),6,Style.Range*2.6,C.Gold,26,.5,5)
   FX.Shake(root.Position,.9,.35,80)
   cast:Step(function()
    for char in pairs(victims) do
     if not ctx.Core.Alive(char) or Status.IsDebuffImmune(char) then
      Status.ReleaseRestraint(char,cast);victims[char]=nil
      unbind(char,true)
      if char.Parent then char:SetAttribute("SwordmasterChained",false) end
     end
    end
    if not next(victims) then cast:Dispose();return false end
    return true
   end)

   local total=0
   for index,stage in ipairs(Style.Stages) do
    if not ctx.Valid() or not cast:Alive() then return fail() end
    local kind,amount=stage[1],stage[2]
    local P=Style.Palette[kind] or Style.Palette.Sword
    local T=Style.Timing[kind] or Style.Timing.Default
    local wind,strikeTime,rec=T[1],T[2],T[3]
    actor:SetAttribute("ChainedComboStage",kind)
    local focus=primary()
    if ctx.Core.Alive(focus) then ctx.Core.Face(focus) end
    glow(P.Color,.6,.1,.1)
    ctx.Core.PoseAngles({RightShoulder={70,0,-30},Waist={15,index%2==0 and 30 or -30,0}},.12)

    if Style.CustomWeapons then
     weapon=Weapons.new(kind,Style)
     if weapon then weapon:Appear(.1) end
    elseif kind~="Chain" and kind~="Laser" then
     weapon=V.Weapon(ctx,cast,kind)
    end
    local function place(cf)
     if not weapon then return end
     if Style.CustomWeapons then weapon:Update(cf) else weapon.Update(cf) end
    end
    local motion=MOTION[kind]
    local aim=0
    if kind=="Rapier" and ctx.Core.Alive(focus) then
     local rel=root.CFrame:PointToObjectSpace(focus.HumanoidRootPart.Position)
     aim=math.deg(math.atan2(-rel.X,-rel.Z))
    end
    local function pose(m,fwdPulse)
     return CFrame.new(root.Position+UP)*root.CFrame.Rotation*CFrame.Angles(0,math.rad(m[1]+aim),0)
      *CFrame.Angles(math.rad(m[2]),0,math.rad(m[3]))*CFrame.new(0,0,-(m[4]+(fwdPulse or 0)))
    end
    local function blend(a,b,t)
     return {lerp(a[1],b[1],t),lerp(a[2],b[2],t),lerp(a[3],b[3],t),lerp(a[4],b[4],t)}
    end
    if weapon then
     place(pose(NEUTRAL))
     FX.Summon(hand(),P.Color,P.Core)
    end
     
    SBFX.Glint(ctx,fxCast,hand(),P.Color,4,.25)
    SBFX.Ring(ctx,fxCast,CFrame.lookAt(hand(),hand()+root.CFrame.LookVector),1,7,.25,P.Color,0,.3,12)
    if kind=="Hammer" then Audio.Emit(actor,"NormalDraw",root) end

     
    local beams={}
    local chargeOrb
    if kind=="Laser" then
     for char in pairs(victims) do beams[char]=FX.Laser(P.Color,P.Core) end
     chargeOrb=FX.Part(Vector3.one*.5,P.Core,CFrame.new(hand()),Enum.PartType.Ball,.1)
     ctx.Core.PoseAngles({RightShoulder={95,0,-5},Waist={5,0,0}},.12)
    elseif kind=="Hammer" then
     for char in pairs(victims) do
      FX.Telegraph(FX.Ground(char.HumanoidRootPart.Position,char),9,wind+strikeTime,C.Danger)
     end
    end
    local aimingOK=hold(wind,function(a)
     if motion and weapon then
      local m=blend(NEUTRAL,motion.A,a)
      place(pose(m)*CFrame.new(jitter(kind=="Hammer" and .9*a or .2*a)))
     end
     if kind=="Laser" then
      if chargeOrb then
       chargeOrb.Size=Vector3.one*lerp(.5,4.5,a)
       chargeOrb.Position=hand()
      end
      for char,beam in pairs(beams) do
       if char.Parent and victims[char] then beam:Set(hand(),char.HumanoidRootPart.Position) end
      end
     end
    end)
    if chargeOrb then FX.Fade(chargeOrb,.2,{Size=Vector3.one*10}) end
    if not aimingOK then return fail() end

     
    local ghostClock=0
    if weapon then weapon:SetTrails(true) end
    if kind=="Hammer" then
     for char in pairs(victims) do
      FX.HammerDrop(FX.Ground(char.HumanoidRootPart.Position,char),P.Color,P.Core,strikeTime)
     end
    elseif kind=="Chain" then
     for char in pairs(victims) do
      local vp=char.HumanoidRootPart.Position
      for i=1,4 do
       local ang=math.rad(i*90+math.random(-25,25))
       FX.ChainSpear(vp+Vector3.new(math.cos(ang)*11,-3,math.sin(ang)*11),vp,strikeTime,P.Color,P.Core)
      end
     end
    end
    Audio.Emit(actor,"SwordSlash",root)
    local elapsed=0
    while elapsed<strikeTime and ctx.Valid() and cast:Alive() do
     local dt=Run.Heartbeat:Wait()
     elapsed+=dt
     local t=math.clamp(elapsed/strikeTime,0,1)
     if motion and weapon then
      local e=motion.Ease=="in" and t*t*t or 1-(1-t)^2
      local pulse=0
      if kind=="Rapier" then pulse=7*math.abs(math.sin(t*5*math.pi)) end
      place(pose(blend(motion.A,motion.B,e),pulse))
      ghostClock+=dt
      if ghostClock>=.06 then ghostClock=0;weapon:Ghost(P.Color,.25) end
     end
     if kind=="Laser" then
      for char,beam in pairs(beams) do
       if char.Parent and victims[char] then beam:Set(hand(),char.HumanoidRootPart.Position) end
      end
     end
    end
    if not ctx.Valid() or not cast:Alive() then return fail() end

     
    if kind=="Laser" then
     for _,beam in pairs(beams) do beam:Fire() end
    end
    local origin=root.Position
     
    do
     local base=CFrame.new(origin+Vector3.new(0,1.5,0))*root.CFrame.Rotation
     if kind=="Sword" then
      SBFX.Crescent(ctx,fxCast,base*CFrame.Angles(0,0,math.rad(-25)),12,math.rad(160),2.6,P.Color,P.Core,.3,{Reverse=true,Wipe=.06,Grow=1.3})
     elseif kind=="Sickle" then
      SBFX.Crescent(ctx,fxCast,base*CFrame.Angles(0,0,math.rad(40)),11,math.rad(170),2.2,P.Color,P.Core,.32,{Wipe=.06,Grow=1.35})
      fxCast:Schedule(.05,function()
       SBFX.Crescent(ctx,fxCast,base*CFrame.Angles(0,0,math.rad(-40)),9,math.rad(150),1.6,P.Core,Color3.new(1,1,1),.28,{Reverse=true,Wipe=.05,Grow=1.4})
      end)
     elseif kind=="Chain" then
      SBFX.Ring(ctx,fxCast,CFrame.new(origin)*CFrame.Angles(math.pi/2,0,0),4,Style.Range*2,.4,P.Color,0,.8)
     elseif kind=="Rapier" then
      for i=1,6 do
       local off=Vector3.new((math.random()-.5)*3,(math.random()-.5)*2.5,0)
       local from=base*CFrame.new(off)
       SBFX.Beam(ctx,fxCast,from.Position,(from*CFrame.new(0,0,-Style.Range)).Position,.45,P.Color,P.Core,.22+i*.02)
      end
      SBFX.Streaks(ctx,fxCast,origin+Vector3.new(0,1.5,0),root.CFrame.LookVector,P.Color,P.Core,24,8,90,150,3.5)
     elseif kind=="Laser" then
      SBFX.Tint(ctx,origin,P.Color,.7,.25)
     elseif kind=="Hammer" then
      SBFX.Tint(ctx,origin,P.Color,1,.45,160)
     end
    end
    for char in pairs(victims) do
     if ctx.Core.Alive(char) and not Status.IsDebuffImmune(char) then
      local p=char.HumanoidRootPart.Position
      local facing=Vector3.new(p.X-origin.X,0,p.Z-origin.Z)
      facing=facing.Magnitude>.1 and facing.Unit or root.CFrame.LookVector
      local dealt=ctx.Damage(char,amount,"P1ChainedCombo")
      total+=dealt
      V.Burst(ctx,cast,p,kind=="Hammer" and 15 or 6)
      if kind=="Sword" then
       FX.SlashMark(p,facing,P.Color,P.Core,3,22)
      elseif kind=="Sickle" then
       FX.ArcSlash(p,facing,9,-25,P.Color,P.Core)
       FX.ArcSlash(p,facing,7,35,P.Color,P.Core)
      elseif kind=="Rapier" then
       FX.Needles(p,facing,P.Color,P.Core,8)
      elseif kind=="Hammer" then
       local g=FX.Ground(p,char)
       FX.Shockwave(g,15,P.Color,P.Core,.5)
      end
      if dealt>0 then FX.Impact(p,facing+Vector3.new(0,.4,0),kind=="Hammer",P.Color,P.Core) end
      if dealt>0 then
       if kind=="Laser" then
        SBFX.Beam(ctx,fxCast,hand(),p,3.2,P.Color,P.Core,.4)
        SBFX.Beam(ctx,fxCast,p+Vector3.new(0,50,0),FX.Ground(p,char),5,P.Color,P.Core,.45)
        SBFX.Impact(ctx,fxCast,p,P.Color,P.Core,1.1)
       elseif kind=="Hammer" then
        local g=FX.Ground(p,char)
        SBFX.Spikes(ctx,fxCast,g,12,5,8,P.Color,P.Core,1,30)
        SBFX.Debris(ctx,fxCast,g+Vector3.new(0,1,0),12,Color3.fromRGB(85,76,70),1,46,Enum.Material.Slate,1.1)
        SBFX.Shockwave(ctx,fxCast,CFrame.new(g),4,40,.5,P.Core,.1,.25)
       elseif kind=="Chain" then
        SBFX.Glint(ctx,fxCast,p,P.Color,5,.3)
       else
        SBFX.Glint(ctx,fxCast,p+facing,P.Core,3.5,.2)
       end
      end
      if kind=="Laser" then
       local g=FX.Ground(p,char)
       FX.GroundRing(g,2,10,P.Color,30,.4,5)
       FX.Pillar(g,2.5,22,P.Core,.35)
      end
      local bind=binds[char]
      if bind and kind~="Hammer" then bind:Pulse() end
      if kind=="Hammer" then
       Status.ReleaseRestraint(char,cast)
       if dealt>0 then AttackDebuffs.Apply(actor,char,"ChainCurse",4,cast) end
       char:SetAttribute("SwordmasterChained",false)
       unbind(char,true)
       Runtime.Knockback(actor,char,p-root.Position,{Speed=110,Lift=45,Duration=.7,Sustain=.25,ContainsArena=true})
      end
     end
    end
    FX.Shake(origin,SHAKE[kind] or .4,kind=="Hammer" and .7 or .2,100)
    if kind=="Hammer" and Style.ScreenFlash then FX.Flash(P.Core,.7,.5) end
    if kind=="Laser" then
     task.spawn(function()
      for _,beam in pairs(beams) do beam:Fade(.35) end
      while true do
       local alive=false
       for char,beam in pairs(beams) do
        if beam:Alive() then
         alive=true
         if char.Parent then beam:Set(hand(),char.HumanoidRootPart.Position) end
        end
       end
       if not alive then break end
       Run.Heartbeat:Wait()
      end
     end)
    end
    if weapon then weapon:SetTrails(false) end
    if kind=="Hammer" then glow(P.Color,1,1,.5) end
    if not ctx.Wait(rec) then return fail() end
    if weapon then
     if Style.CustomWeapons then weapon:Remove() else weapon.Remove() end
     weapon=nil
    end
   end
   actor:SetAttribute("ChainedComboDamage",total)
   actor:SetAttribute("ChainedComboBaseDamage",60)
   cast:Dispose()
   return true
  end

  local ok,result=pcall(run)
  if not ok then
   warn("[P1ChainedCombo] "..tostring(result))
   cast:Dispose()
   return false
  end
  return result
 end)
 local ready=api.CanUse
 function api.CanUse(target)
  return ready() and (not target or target:FindFirstChild("HumanoidRootPart")
   and (target.HumanoidRootPart.Position-actor.HumanoidRootPart.Position).Magnitude<=Style.Range)
 end
 return api
end