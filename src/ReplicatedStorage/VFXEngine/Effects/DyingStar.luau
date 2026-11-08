--[[
 DyingStar (client effect)
 Beats: Start (light gathers, the star ignites above the boss) -> Beam x7 -> Throw (the
 star climbs high and dives onto the ground along the shared path; it summons five
 stars that fall from the sky timed to strike as it lands) -> Critical (it hits the ground;
 any summoned star still falling strikes now) -> Burst, the same moment (the star itself
 blows apart: flash, fireball, fragments, shockwaves, embers, smoke column) -> End.
 Star layers are long-lived sprites whose Size/Color are rewritten live, so the star can
 grow, swell and redden without re-emitting.
]]
local D={}
local FlightPoint=require(game.ReplicatedStorage.BossShared.Presentation.DyingStarFlight)
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
local GOLD=Color3.fromRGB(255,206,110)
local ORANGE=Color3.fromRGB(255,140,40)
local RED=Color3.fromRGB(255,60,40)
local DEEP=Color3.fromRGB(20,8,6)
local casts={}

local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end

function D.Start(E,d)
 if casts[d.Token]then return end
 local g=E.Group("DyingStar")
 local R=d.Radius or 12
 local c={G=g,D=d,Root=d.Root,Grow=0,Swell=1,Heat=0,Layers={},Mode="Ride"}
 casts[d.Token]=c
 local life=math.min((d.Total or 8)+1,19)
 local star=E.Anchor(g,CFrame.new((d.Root and d.Root.Position or Vector3.zero)+Vector3.yAxis*d.Height))
 c.Star=star
 local function layer(spec,base,hot)
  local e=E.Sprite(star,spec,life)
  c.Layers[#c.Layers+1]={E=e,Base=base,Cool=spec.color,Hot=hot}
  e.Size=NumberSequence.new(.01)
 end
  -- body, inside out: hot core, shaded sphere, corona, rays, glare
 layer({tex="glow.soft",alpha=0,color=WHITE,z=.4},R*1.3,Color3.fromRGB(255,220,200))
 layer({tex="orb.shaded",alpha=.15,color=Color3.fromRGB(255,236,180),z=.3},R*1.7,Color3.fromRGB(255,120,80))
 layer({tex="burst.white",alpha=.2,color=GOLD,spin={40,40},z=.2},R*2.8,RED)
 layer({tex="flare.burst",alpha=.3,color=ORANGE,spin={-12,-12},z=.1},R*3.6,RED)
 layer({tex="star.lens",alpha=.35,color=WHITE,rot={0,0},z=.5},R*4.4,Color3.fromRGB(255,170,150))
 layer({tex="glow.soft",alpha=.6,color=ORANGE,z=-1},R*6,RED)
 c.Light=E.Light(g,star,ORANGE,60,0)
  -- summon: light pours in from a shell, a swirl tightens
 local shell=E.Anchor(g,star.CFrame)shell.Size=Vector3.one*R*5
 c.Shell=shell
 c.Inflow=E.Stream(shell,{tex="dot",orient="velocity",squash={{0,2.4},{1,.6}},size={{0,0},{.2,.6},{1,.15}},alpha={{0,1},{.2,0},{1,.2}},
  color={{0,ORANGE},{1,WHITE}},life={.55,.7},speed={45,60},shape=Enum.ParticleEmitterShape.Sphere,
  inout=Enum.ParticleEmitterShapeInOut.Inward,style=Enum.ParticleEmitterShapeStyle.Surface},140)
 E.Sprite(star,{tex="swirl.white",size={{0,R*6},{.8,R*2},{1,0}},alpha={{0,1},{.3,.35},{1,1}},color=GOLD,spin={-200,-200},z=-.5},d.Summon or 1)
 c.Trail=nil
 local born=os.clock()
 E.Step(g,function(dt)
  local t=os.clock()-born
  local root=c.Root
  if c.Mode=="Ride"and root and root.Parent then
   star.CFrame=star.CFrame:Lerp(CFrame.new(root.Position+Vector3.yAxis*d.Height),1-math.exp(-dt*18))
  elseif c.Mode=="Fly"then
   star.CFrame=CFrame.new(FlightPoint(c.Flight,E.Net.Now()-c.Flight.At))
  end
  shell.CFrame=star.CFrame
  c.Grow=smooth(t/(d.Summon or 1))
  if c.Inflow and t>=(d.Summon or 1)then c.Inflow.Enabled=false c.Inflow=nil
   -- ignition pop
   E.Sprite(star,{tex="flare.burst2",size={{0,R*2},{.25,R*7},{1,R*8}},alpha={{0,0},{.4,.3},{1,1}},color=WHITE},.35)
   E.Sprite(star,{tex="ring.crisp",size={{0,R},{1,R*9}},alpha={{0,0},{1,1}},color=GOLD},.35)
  end
  local flicker=c.Heat>0 and(1+.12*math.sin(t*42)*c.Heat)or(1+.03*math.sin(t*6))
  local k=c.Grow*c.Swell*flicker
  for _,L in ipairs(c.Layers)do
   L.E.Size=NumberSequence.new(math.max(L.Base*k,.01))
   if c.Heat>0 then L.E.Color=ColorSequence.new(L.Cool:Lerp(L.Hot,c.Heat))end
  end
  if c.Light then c.Light.Brightness=(3+6*c.Heat)*c.Grow end
 end)
end

function D.Beam(E,d)
 local c=casts[d.Token]
 local g=E.Group("DyingStarBeam")
 local dir=(d.To-d.From)
 local len=dir.Magnitude
 dir=len>.01 and dir.Unit or Vector3.yAxis
 local from=E.Anchor(g,CFrame.new(d.From))
 local to=E.Anchor(g,CFrame.new(d.To))
 local a0,a1=E.Attach(from),E.Attach(to)
  -- muzzle: the star flares and a ring snaps outward along the shot
 if c then E.Sprite(c.Star,{tex="flare.burst2",size={{0,10},{.25,34},{1,38}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE},.22)end
 E.Sprite(from,{tex="ring.crisp",size={{0,4},{1,26}},alpha={{0,0},{1,1}},color=GOLD},.25)
 E.Sprite(from,{tex="flare.streak",size={{0,40},{1,46}},alpha={{0,0},{1,1}},color=GOLD,rot={0,0}},.18)
  -- body: hot core, gold glow, scrolling star halo, and a thin white sheath that lingers
 local core=E.Beam(g,a0,a1,{tex="beam.core",width=4.5,length=1,mode=Enum.TextureMode.Stretch,color={{0,WHITE},{.6,Color3.fromRGB(255,240,200)},{1,GOLD}},brightness=5,segments=2})
 local glow=E.Beam(g,a0,a1,{width=11,color={{0,GOLD},{1,ORANGE}},alpha={{0,.45},{.8,.55},{1,1}},brightness=1.6,segments=2,z=-.05})
 local halo=E.Beam(g,a0,a1,{tex="beam.stars",width=16,length=20,scroll=-60,color={{0,GOLD},{1,ORANGE}},alpha={{0,.15},{1,.45}},brightness=2.5,segments=2,z=-.1})
 local sheath=E.Beam(g,a0,a1,{tex="beam.dots",width=2,length=6,scroll=-30,color=WHITE,alpha={{0,.2},{1,.5}},brightness=2,segments=2,z=.1})
 E.Tween(core,.3,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
 E.Tween(glow,.35,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
 E.Tween(halo,.4,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
 E.Tween(sheath,.7,{Width0=0,Width1=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
  -- sparks shed sideways all along the shot
 for k=1,5 do
  local p=E.Anchor(g,CFrame.lookAt(d.From+dir*len*(k/6),d.From+dir*len*(k/6)+dir))
  E.Emit(p,{tex="dot",orient="velocity",squash={{0,2.2},{1,0}},size={{0,.6},{1,0}},alpha={{0,0},{.7,0},{1,1}},
   color={{0,WHITE},{1,GOLD}},life={.2,.4},speed={15,35},spread=90,drag=4},6)
 end
  -- impact: flash, spiky burst, flat shock ring, fire puff, sparks, smoke
 E.Sprite(to,{tex="flare.burst2",size={{0,6},{.2,24},{1,28}},alpha={{0,0},{.4,.15},{1,1}},color=WHITE},.25)
 E.Sprite(to,{tex="burst.spiky",size={{0,6},{1,26}},alpha={{0,0},{.6,.2},{1,1}},color=ORANGE,rot={0,360}},.3)
 local gp=E.Ground(d.To)
 if gp and(d.To-gp).Magnitude<8 then
  local ga=E.Anchor(g,CFrame.new(gp+Vector3.new(0,.4,0)))
  E.Sprite(ga,{tex="ring.thick",orient="flat",size={{0,3},{1,24}},alpha={{0,0},{1,1}},color=ORANGE},.4)
  E.Sprite(ga,{tex="glow.soft",orient="flat",light=0,size=10,alpha={{0,.4},{1,1}},color=Color3.fromRGB(40,20,10)},1.2)
 end
 E.Emit(to,{tex="fire",size={{0,2},{1,7}},alpha={{0,0},{.5,.3},{1,1}},color={{0,WHITE},{.4,GOLD},{1,RED}},life={.3,.6},speed={8,20},spread=180,drag=3,light=.8},8)
 E.Emit(to,{tex="dot",orient="velocity",squash={{0,2.4},{1,0}},size={{0,.9},{1,0}},alpha={{0,0},{.7,0},{1,1}},
  color={{0,WHITE},{1,ORANGE}},life={.25,.5},speed={35,70},spread=180,drag=4},22)
 E.Emit(to,{tex="smoke",light=0,size={{0,2},{1,7}},alpha={{0,1},{.2,.6},{1,1}},color=Color3.fromRGB(70,50,40),life={.8,1.2},speed={3,8},spread=180,rot={0,360}},4)
 E.Light(g,to,ORANGE,28,7,.35)
 E.After(g,1.3,function()g:Destroy()end)
end

local Players=game:GetService("Players")

 -- local white-gold screen flash scaled by distance
local function screenFlash(at,range,strength,time)
 local plr=Players.LocalPlayer
 local pg=plr and plr:FindFirstChildOfClass("PlayerGui")
 local cam=workspace.CurrentCamera
 if not pg or not cam then return end
 local near=1-math.clamp((cam.CFrame.Position-at).Magnitude/range,0,1)
 if near<=0 then return end
 local gui=Instance.new("ScreenGui")gui.Name="DyingStarFlash"gui.IgnoreGuiInset=true gui.DisplayOrder=25
 local f=Instance.new("Frame")f.Size=UDim2.fromScale(1,1)f.BorderSizePixel=0 f.BackgroundColor3=Color3.fromRGB(255,240,210)
 f.BackgroundTransparency=1-math.min(near*strength,.92)f.Parent=gui
 gui.Parent=pg
 game:GetService("TweenService"):Create(f,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
 game:GetService("Debris"):AddItem(gui,time+.1)
end

 -- one summoned star detonating on its own, with a short energy tether into the dying star
local function miniBlast(E,c,at)
 local g2=E.Group("DyingStarMini")
 local a=E.Anchor(g2,CFrame.new(at))
 E.Sprite(a,{tex="flare.burst2",size={{0,4},{.25,22},{1,26}},alpha={{0,0},{.45,.2},{1,1}},color=WHITE},.35)
 E.Sprite(a,{tex="burst.spiky",size={{0,4},{1,28}},alpha={{0,0},{.6,.15},{1,1}},color=GOLD,rot={0,360}},.35)
 E.Sprite(a,{tex="ring.crisp",size={{0,3},{1,30}},alpha={{0,0},{1,1}},color=ORANGE},.3)
 E.Emit(a,{tex="fire",size={{0,3},{1,8}},alpha={{0,0},{.5,.3},{1,1}},color={{0,WHITE},{.4,GOLD},{1,RED}},life={.4,.7},speed={10,25},spread=180,drag=3,light=.8},10)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,2.6},{1,0}},size={{0,.9},{1,0}},alpha={{0,0},{.7,0},{1,1}},
  color={{0,WHITE},{1,GOLD}},life={.25,.5},speed={50,90},spread=180,drag=3},24)
 E.Light(g2,a,ORANGE,40,8,.35)
 local s0,s1=E.Attach(a),E.Attach(c.Star)
 local tether=E.Beam(g2,s0,s1,{tex="beam.core",width=3,length=1,mode=Enum.TextureMode.Stretch,color={{0,GOLD},{1,WHITE}},brightness=3,segments=2})
 E.Tween(tether,.35,{Width0=0,Width1=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 E.After(g2,1.2,function()s1:Destroy()g2:Destroy()end)
end

 -- Summoned stars fall from the sky toward the landing point while the dying star is in the
 -- air, timed to strike the moment it hits the ground. Critical lands any still in flight.
local function launch(E,c,rec,travel)
 if rec.M or rec.Landed then return end
 rec.From=c.Impact+rec.Dir*60
 local m=E.Anchor(c.G,CFrame.new(rec.From))
 E.Sprite(m,{tex="star.crisp",size=5,alpha=0,color=WHITE,rot={0,0},spin={300,300}},travel+.15)
 E.Sprite(m,{tex="glow.soft",size=9,alpha=.2,color=GOLD},travel+.15)
 local t0a,t1a=E.Attach(m,CFrame.new(0,.6,0)),E.Attach(m,CFrame.new(0,-.6,0))
 local tr=Instance.new("Trail")
 tr.Attachment0,tr.Attachment1=t0a,t1a tr.Lifetime=.18 tr.LightEmission=1 tr.FaceCamera=true
 tr.Color=ColorSequence.new(WHITE,GOLD)tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(1,1)})
 tr.WidthScale=NumberSequence.new(1,0)tr.Parent=m
 rec.M,rec.S0,rec.Travel=m,os.clock(),travel
end
local function summon(E,c,impact,left)
 if c.Summons then return end
 c.Impact=impact
 c.Summons={}
 local travel=math.clamp(left,.06,.8)
 for k=1,5 do
  local ang=k*1.26+math.random()*.5
  local tilt=math.rad(25+math.random()*30)
  local off=ang+2.1
  local reach=10+math.random()*6
  local rec={Dir=Vector3.new(math.cos(ang)*math.sin(tilt),math.cos(tilt),math.sin(ang)*math.sin(tilt)),
   Offset=Vector3.new(math.cos(off)*reach,math.random()*4,math.sin(off)*reach)}
  c.Summons[k]=rec
  E.After(c.G,math.max(left-travel,0),function()launch(E,c,rec,travel)end)
 end
 E.Step(c.G,function()
  local pending=false
  for _,rec in ipairs(c.Summons)do
   if not rec.Landed then
    pending=true
    if rec.M then
     local strike=c.Impact+rec.Offset
     local u=math.clamp((os.clock()-rec.S0)/rec.Travel,0,1)
     rec.M.CFrame=CFrame.new(rec.From:Lerp(strike,u*u))
     if u>=1 then
      rec.Landed=true
      miniBlast(E,c,strike)
      local mm=rec.M
      E.After(c.G,.3,function()mm:Destroy()end)
     end
    end
   end
  end
  return pending
 end)
end

function D.Throw(E,d)
 local c=casts[d.Token]
 if not c then return end
 c.Mode="Fly"c.Flight=d
 local s=c.Star
 local t0,t1=E.Attach(s,CFrame.new(0,4,0)),E.Attach(s,CFrame.new(0,-4,0))
 local tr=Instance.new("Trail")
 tr.Attachment0,tr.Attachment1=t0,t1 tr.Lifetime=.45 tr.LightEmission=1 tr.FaceCamera=true
 tr.Color=ColorSequence.new(GOLD,RED)tr.Transparency=NumberSequence.new(.1,1)tr.WidthScale=NumberSequence.new(1,0)tr.Parent=s
 c.Trail=tr
 c.Fire=E.Stream(s,{tex="fire",size={{0,6},{1,1}},alpha={{0,.2},{1,1}},color={{0,WHITE},{.4,ORANGE},{1,RED}},life={.3,.5},speed={2,6},spread=180,light=.8},80)
 if d.Impact and d.ETA then summon(E,c,d.Impact,d.ETA-(E.Net.Now()-d.At))end
end

function D.Critical(E,d)
 local c=casts[d.Token]
 if not c then return end
 c.Mode="Hold"
 c.Star.CFrame=CFrame.new(d.Pos)
 if c.Fire then c.Fire.Rate=160 end
  -- the star is down: every summoned star still in the air (or not yet launched, e.g. a
  -- late joiner or an early wall hit) strikes right now, around where it actually landed
 if not c.Summons then summon(E,c,d.Pos,.06)end
 c.Impact=d.Pos
 for _,rec in ipairs(c.Summons)do
  if not rec.Landed then
   if rec.M then rec.Travel=math.min(rec.Travel,(os.clock()-rec.S0)+.06)else launch(E,c,rec,.06)end
  end
 end
end

function D.Burst(E,d)
 local c=casts[d.Token]
 local g=E.Group("DyingStarBurst")
 local R=(c and c.D.Radius)or 12
 local r=d.Radius or 28
  -- the star is gone: clear its layers, trail and fire
 if c then
  for _,L in ipairs(c.Layers)do L.E:Clear()L.E.Size=NumberSequence.new(0)end
  if c.Trail then c.Trail.Enabled=false end
  if c.Fire then c.Fire.Enabled=false end
  if c.Light then c.Light.Brightness=0 end
  c.Mode="Gone"
 end
 local a=E.Anchor(g,CFrame.new(d.Pos))
 screenFlash(d.Pos,220,1.1,.55)
  -- implosion snap, then the blast
 E.Sprite(a,{tex="ring.inverse",light=0,color=DEEP,size={{0,r*2.5},{1,R*.5}},alpha={{0,.2},{1,.6}},z=-3},.1)
 E.Sprite(a,{tex="glow.soft",light=0,color=DEEP,size={{0,r*2},{1,r*3.5}},alpha={{0,.3},{1,1}},z=-3},.3)
 E.Sprite(a,{tex="flare.big",size={{0,R*3},{.12,r*4.5},{1,r*5}},alpha={{0,0},{.3,.15},{1,1}},color=WHITE},.5)
 E.Sprite(a,{tex="flare.burst2",size={{0,r*2},{1,r*7}},alpha={{0,0},{.4,.25},{1,1}},color=GOLD,spin={40,40}},.6)
 E.Sprite(a,{tex="burst.spiky2",size={{0,R*3},{1,r*7}},alpha={{0,0},{.5,.1},{1,1}},color=GOLD,rot={0,360}},.55)
 E.Sprite(a,{tex="flare.streak",size={{0,r*12},{1,r*13}},alpha={{0,0},{1,1}},color=GOLD,rot={0,0}},.45)
 for k=0,2 do
  E.After(g,k*.09,function()
   E.Sprite(a,{tex="ring.crisp",size={{0,R*2},{1,r*(6+2*k)}},alpha={{0,0},{.6,.3},{1,1}},color=k==1 and WHITE or ORANGE,rot={0,0}},.5+.1*k)
  end)
 end
  -- fireball: the star's body blown outward
 E.Emit(a,{tex="fire",size={{0,R},{.4,R*2.6},{1,R*3.2}},alpha={{0,0},{.5,.2},{1,1}},color={{0,WHITE},{.25,GOLD},{.6,ORANGE},{1,RED}},
  life={.7,1.3},speed={25,60},spread=180,drag=3,rot={0,360},spin={-90,90},light=.85},60)
 E.Emit(a,{tex="star.anime",size={{0,R*.45},{1,0}},alpha={{0,0},{.7,0},{1,1}},color={{0,WHITE},{1,ORANGE}},
  life={.9,1.5},speed={80,140},spread=180,drag=1.2,accel=Vector3.new(0,-40,0),spin={-400,400}},30)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,3},{.6,1.4},{1,0}},size={{0,1.8},{1,0}},alpha={{0,0},{.75,0},{1,1}},
  color={{0,WHITE},{.4,GOLD},{1,RED}},life={.6,1},speed={110,200},spread=180,drag=2.5},160)
 E.Emit(a,{tex="fire.sparks",size={{0,1.5},{1,0}},life={1.4,2.6},speed={30,70},spread=180,drag=2,accel=Vector3.new(0,6,0),color={{0,GOLD},{1,RED}}},120)
 E.Emit(a,{tex="smoke",light=0,color=Color3.fromRGB(60,40,36),size={{0,R},{1,R*3.6}},alpha={{0,1},{.2,.45},{1,1}},
  life={2.2,3.2},speed={12,28},spread=40,dir=Enum.NormalId.Top,drag=1,accel=Vector3.new(0,6,0),rot={0,360},spin={-30,30}},24)
 E.Light(g,a,Color3.fromRGB(255,220,170),150,14,.5)
 local gp=E.Ground(d.Pos)
 if gp and(d.Pos-gp).Magnitude<r*1.6 then
  local ga=E.Anchor(g,CFrame.new(gp+Vector3.new(0,.5,0)))
  E.Sprite(ga,{tex="ring.thick",orient="flat",size={{0,r*.5},{1,r*4.5}},alpha={{0,0},{1,1}},color=ORANGE},.75)
  E.Sprite(ga,{tex="ring.multi",orient="flat",size={{0,r},{1,r*3.5}},alpha={{0,0},{.5,.25},{1,1}},color=GOLD},.9)
  E.Sprite(ga,{tex="ring.inverse",orient="flat",light=0,color=DEEP,size={{0,r},{1,r*2.6}},alpha={{0,.3},{1,1}},z=-1},1)
  E.Emit(ga,{tex="smoke",light=0,color=Color3.fromRGB(70,52,44),size={{0,5},{1,16}},alpha={{0,1},{.15,.5},{1,1}},
   life={1.2,1.9},speed={50,90},spread=85,dir=Enum.NormalId.Top,drag=3,rot={0,360}},32)
   -- light pillar
  local top=E.Anchor(g,CFrame.new(gp+Vector3.new(0,260,0)))
  local p0,p1=E.Attach(ga),E.Attach(top)
  local pil=E.Beam(g,p0,p1,{tex="beam.core",width=r*.9,length=1,mode=Enum.TextureMode.Stretch,color={{0,WHITE},{1,GOLD}},alpha={{0,0},{.7,.3},{1,1}},brightness=4,segments=2})
  E.Tween(pil,.6,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
 end
 E.After(g,3.4,function()g:Destroy()end)
end

function D.End(E,d)
 local c=casts[d.Token]
 if not c then return end
 casts[d.Token]=nil
 c.G:Fade(.6)
end

return D
