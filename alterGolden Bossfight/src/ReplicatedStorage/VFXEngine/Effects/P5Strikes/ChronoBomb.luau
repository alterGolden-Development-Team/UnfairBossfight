-- P5Strikes cues: Time Bomb and Chronobreak.
-- Registers its P.<Name>(E, d) functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local P, AMBER, GOLD, NEON, SHINE, UP, WHITE, dome, goldArc = Core.P, Core.AMBER, Core.GOLD, Core.NEON, Core.SHINE, Core.UP, Core.WHITE, Core.dome, Core.goldArc
local grade, newPart, rootOf, shards = Core.grade, Core.newPart, Core.rootOf, Core.shards

 -- an afterimage: a copy of every visible part of `model` as it stands right now
local function echo(g,model,color,alpha,material)
 local list={}
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("BasePart")and p.Name~="HumanoidRootPart"and p.Transparency<.9 and p.Size.Magnitude<12 and not p:IsDescendantOf(g.Folder)then
   local q=newPart(g,p.Size,color,alpha)
   q.Material=material or NEON q.CFrame=p.CFrame
   list[#list+1]=q
  end
 end
 return list
end

 -- Time Bomb: a golden clock hangs over a player - its hand ticking round faster and faster - with the blast radius
 -- drawn on the ground around them, pulsing with every tick
function P.TimeBomb(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T,R=d.Time or 3.5,d.Radius or 14
 local g=E.Group("P5TimeBomb")
 local function over()return vr.CFrame*CFrame.new(0,5.6,0)end
  -- the bomb: a hot gold core in a shimmering shell, two clock rings turning round it like a gyroscope
 local core=newPart(g,Vector3.one*1.4,GOLD,0) core.Shape=Enum.PartType.Ball
 local shell=newPart(g,Vector3.one*3.4,AMBER,.05) shell.Shape=Enum.PartType.Ball shell.Material=Enum.Material.ForceField
 local function ring(radius,width,color)
  local carrier=newPart(g,Vector3.one*.2,WHITE,1)
  local N=E.Quality<.6 and 12 or 20
  local pts={}
  for i=1,N do
   local ang=(i-1)/N*math.pi*2
   local at=Instance.new("Attachment") at.Position=Vector3.new(math.cos(ang)*radius,math.sin(ang)*radius,0) at.Parent=carrier
   pts[i]=at
  end
  for i=1,N do
   local b=Instance.new("Beam")
   b.Attachment0=pts[i] b.Attachment1=pts[i%N+1] b.FaceCamera=true b.Segments=1 b.LightEmission=1 b.LightInfluence=0
   b.Color=ColorSequence.new(color) b.Transparency=NumberSequence.new(i%5==1 and 0 or .3)
   b.Width0=i%5==1 and width*2.4 or width b.Width1=b.Width0  -- every fifth one thick: the hour marks
   b.Parent=carrier
  end
  return carrier
 end
 local ringA,ringB=ring(2.5,.32,AMBER),ring(2.95,.24,GOLD)
 local hand=newPart(g,Vector3.new(.22,2.2,.1),WHITE,0)
 local bomb=E.Anchor(g,over())
 E.Sprite(bomb,{tex="glow.soft",size={{0,3},{1,8}},alpha={{0,.6},{1,.2}},color=AMBER},T)
 E.Sprite(bomb,{tex="sigil.ring2",size=3.6,alpha=.3,color=SHINE,spin={120,120}},T)
 local function floorAt()
  local hit=E.Ground(vr.Position,{d.Victim,g.Folder})
  return CFrame.new((hit or vr.Position-UP*3)+UP*.2)
 end
 local feet=E.Anchor(g,floorAt())
  -- the blast's reach: a faint ring of clock ticks on the floor (no filled disc)
 E.Sprite(feet,{tex="ring.ticked",orient="flat",size=R*2,alpha={{0,1},{.1,.4},{1,.25}},color=Color3.fromRGB(190,50,20),light=0,spin={0,0}},T)
 local light=E.Light(g,bomb,AMBER,14,2)
 local nextTick=0
 E.Step(g,function(_,t)
  if not vr.Parent then g:Destroy()return false end
  local k=math.clamp(t/T,0,1)
  local at=over()*CFrame.new(0,math.sin(t*3)*.15,0)
  bomb.CFrame=at
  feet.CFrame=floorAt()
  local cam=workspace.CurrentCamera
  local face=cam and CFrame.lookAt(at.Position,cam.CFrame.Position)or at
  local spin=t*(2+k*k*14)
  if t>=nextTick then  -- a tick: the core flares, sparks fly and a pulse runs out across the floor to the blast's edge
   nextTick=t+math.max(.1,.55*(1-k))
   E.Emit(bomb,{tex="star.crisp",size={{0,.7},{1,0}},color={{0,WHITE},{1,GOLD}},life={.15,.3},speed={5,11},spread=180},5)
   E.Sprite(feet,{tex="ring.crisp",orient="flat",size={{0,R*.3},{1,R*2}},alpha={{0,.15},{.6,.35},{1,1}},color=Color3.fromRGB(210,64,24),light=0},.42)
   light.Brightness=6
   core.Size=Vector3.one*2
  else
   light.Brightness=math.max(1.5,light.Brightness-.4)
   core.Size=core.Size:Lerp(Vector3.one*1.4,.25)
  end
  local hot=GOLD:Lerp(Color3.fromRGB(255,110,60),k)
  shell.Color=hot
  workspace:BulkMoveTo({core,shell,hand,ringA,ringB},{at,at*CFrame.Angles(t,t*.7,0),
   face*CFrame.Angles(0,0,-t*(4+k*k*30))*CFrame.new(0,.75,-.2),at*CFrame.Angles(0,spin,0),at*CFrame.Angles(spin*.8,0,.6)},
   Enum.BulkMoveMode.FireCFrameChanged)
  return t<T
 end)
 E.After(g,T,function()g:Destroy()end)
end
function P.TimeBombBlast(E,d)
 local g=E.Group("P5TimeBombBlast")
 local R=d.Radius or 14
 local c=d.Pos+UP*1.5
 local a=E.Anchor(g,CFrame.new(c))
 dome(E,g,c,WHITE,2,R*1.1,.22,.05)
 dome(E,g,c,GOLD,3,R*2,.45,.3,Enum.Material.ForceField)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.12,R*2.4},{1,R*2.8}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.4)
 E.Sprite(a,{tex="burst.spiky2",size={{0,3},{1,R*2.2}},alpha={{0,0},{1,1}},color=GOLD,rot={0,360}},.35)
 E.Sprite(a,{tex="ring.ticked",size={{0,R*.3},{1,R*1.7}},alpha={{0,0},{.6,.3},{1,1}},color=AMBER,spin={-300,-300}},.5)
  -- the clock comes apart: gear wheels and hands flung out spinning
 local bits={}
 for i=1,14 do
  local dir=Vector3.new(math.cos(i*math.pi/7),.25+math.random()*.7,math.sin(i*math.pi/7)).Unit
  local p
  if i%2==0 then
   local w=1.6+math.random()
   p=newPart(g,Vector3.new(.25,w,w),i%4==0 and SHINE or GOLD,0) p.Shape=Enum.PartType.Cylinder
  else
   p=newPart(g,Vector3.new(.18,.18,2.6),WHITE,0)
  end
  bits[i]={P=p,D=dir,S=(math.random()-.5)*24,V=28+math.random()*18}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,b in ipairs(bits)do
   local at=c+b.D*(t*b.V)+Vector3.new(0,-34*t*t,0)
   parts[#parts+1]=b.P cfs[#cfs+1]=CFrame.lookAt(at,at+b.D)*CFrame.Angles(t*b.S,t*b.S*.5,0)
   b.P.Transparency=math.clamp((t-.45)/.3,0,1)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<.8
 end)
 shards(E,g,c,10,30,2,{WHITE,GOLD,SHINE},.7)
 E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.7},speed={25,55},spread=180,drag=2},36)
 E.Emit(a,{tex="smoke",light=0,size={{0,3},{1,9}},alpha={{0,.5},{1,1}},color={{0,Color3.fromRGB(150,120,70)},{1,Color3.fromRGB(80,70,60)}},
  life={.6,1},speed={14,26},spread=180,drag=3},14)
 E.Light(g,a,GOLD,R*2.5,9,.45)
 grade(E,{Saturation=-.6,Contrast=.2,Brightness=.08,TintColor=Color3.fromRGB(255,240,210)},.35)
 E.After(g,1.3,function()g:Destroy()end)
end

 -- Chronobreak: a golden afterimage of him stays where he was - every part of him in still, flickering light
function P.ChronoGhost(E,d)
 local boss=d.Boss
 if not boss then return end
 local T=d.Time or 2.5
 local g=E.Group("P5ChronoGhost")
  -- his afterimage, held still: a shimmering gold copy with a bright echo flickering inside it
 local shimmer=echo(g,boss,GOLD,.3,Enum.Material.ForceField)
 local glow=echo(g,boss,Color3.fromRGB(255,222,140),.7)
 local r=rootOf(boss)
 local at=d.Frame or(r and r.CFrame)or CFrame.new()
  -- he has often blinked away already by the time this arrives: move the copy back to where he stood
 if r and d.Frame then
  local back=d.Frame*r.CFrame:Inverse()
  for _,q in ipairs(shimmer)do q.CFrame=back*q.CFrame end
  for _,q in ipairs(glow)do q.CFrame=back*q.CFrame end
 end
  -- a clock face behind it, its hands frozen, and motes drifting off it
 local back=E.Anchor(g,at*CFrame.new(0,1.2,1.4))
 E.Sprite(back,{tex="ring.ticked",size=9,alpha={{0,1},{.1,.3},{.9,.35},{1,1}},color=GOLD,spin={0,0}},T)
 E.Sprite(back,{tex="sigil.ring2",size=7,alpha={{0,1},{.1,.5},{.9,.55},{1,1}},color=SHINE,spin={-20,-20}},T)
 local motes=E.Stream(back,{tex="star.twinkle",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.8,1.3},speed={1,3},spread=180,
  accel=Vector3.new(0,2,0)},14)
 E.Light(g,back,GOLD,14,2,T)
 E.Step(g,function(_,t)
  local flick=.62+.12*math.sin(t*31)+.08*math.sin(t*7.3)
  for _,q in ipairs(glow)do q.Transparency=flick end
  return t<T
 end)
 E.After(g,T,function()
  motes.Enabled=false
  for _,q in ipairs(shimmer)do E.Tween(q,.25,{Transparency=1})end
  for _,q in ipairs(glow)do E.Tween(q,.2,{Transparency=1})end
  E.After(g,.35,function()g:Destroy()end)
 end)
end
 -- Chronobreak: a slash - a gold arc swept around him
function P.ChronoSlash(E,d)
 local g=E.Group("P5ChronoSlash")
 local side=(d.Index or 1)%2==1 and 1 or -1
 local sweep=goldArc(E,g,d.Frame*CFrame.new(0,.8,0),12,-math.pi/2-side*2.1,side*4.2,1)
 local a=E.Anchor(g,d.Frame*CFrame.new(0,1,-5))
 E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,GOLD}},life={.2,.4},speed={18,36},spread=90,dir=Enum.NormalId.Front,drag=2},12)
 E.Step(g,function(_,t)
  local k=math.clamp(t/.11,0,1)
  sweep(1-(1-k)^3,t<.18 and 0 or math.clamp((t-.18)/.2,0,1))
  return t<.42
 end)
 E.After(g,.7,function()g:Destroy()end)
end
 -- Chronobreak: the rewind - a streak of gold running back along his path, clock rings left at every turn
function P.ChronoRewind(E,d)
 local g=E.Group("P5ChronoRewind")
 local path=d.Path or{}
 local T=d.Time or .45
 if #path<2 then g:Destroy()return end
 for i=1,#path-1 do
  local a0,b0=path[i],path[i+1]
  local len=(b0-a0).Magnitude
  if len>.5 then
   local core=newPart(g,Vector3.new(.35,.35,.1),WHITE,0)
   local glow=newPart(g,Vector3.new(2.4,2.4,.1),GOLD,.5)
   E.After(g,T*(i-1)/(#path-1),function()
    local cf=CFrame.lookAt((a0+b0)/2,b0)
    core.Size=Vector3.new(.35,.35,len) glow.Size=Vector3.new(2.4,2.4,len)
    core.CFrame=cf glow.CFrame=cf
    E.Tween(core,.5,{Transparency=1,Size=Vector3.new(0,0,len)},nil,nil,.15)
    E.Tween(glow,.45,{Transparency=1,Size=Vector3.new(0,0,len)},nil,nil,.1)
    local r=E.Anchor(g,CFrame.lookAt(a0,b0))
    E.Sprite(r,{tex="ring.ticked",orient="flat",dir=Enum.NormalId.Front,size={{0,2},{1,8}},alpha={{0,.2},{1,1}},color=SHINE,spin={-300,-300}},.4)
    E.Emit(r,{tex="wind.dash",orient="velocity",size={{0,2},{1,4}},alpha={{0,.4},{1,1}},color=SHINE,life={.15,.25},speed={30,50},spread=10,dir=Enum.NormalId.Front},8)
   end)
  end
 end
  -- time running backwards: the colour drains out of the world, and afterimages trail him back along the path
 grade(E,{Saturation=-1,Contrast=.15,TintColor=Color3.fromRGB(232,238,255)},T+.4)
 local boss=d.Boss
 if boss then
  local made,nextAt=0,0
  local count=E.Quality<.6 and 1 or 2  -- each one copies his whole body (~135 parts)
  E.Step(g,function(_,t)
   if t>=nextAt and made<count then
    made+=1
    nextAt=t+T/count
    for _,q in ipairs(echo(g,boss,SHINE,.4))do E.Tween(q,.45,{Transparency=1})end
   end
   return made<count
  end)
 end
 E.After(g,T+1,function()g:Destroy()end)
end
function P.ChronoBurst(E,d)
 local g=E.Group("P5ChronoBurst")
 local R=d.Radius or 20
 local c=d.Pos+UP*2
 local a=E.Anchor(g,CFrame.new(c))
 local f=E.Anchor(g,CFrame.new(d.Pos+UP*.15))
 dome(E,g,c,WHITE,3,R*1.2,.25,.05)
 dome(E,g,c,GOLD,4,R*2.1,.5,.3,Enum.Material.ForceField)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.12,R*2.4},{1,R*2.8}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.45)
  -- the moment breaks: a clock face standing over the spot bursts outward and shatters
 E.Sprite(a,{tex="ring.ticked",size={{0,R*.4},{1,R*1.8}},alpha={{0,0},{1,1}},color=GOLD,spin={-260,-260}},.5)
 E.Sprite(a,{tex="sigil.mandala2",size={{0,R*.3},{.3,R*1.6},{1,R*1.8}},alpha={{0,.2},{.5,.4},{1,1}},color=AMBER,spin={180,180}},.6)
 E.Sprite(f,{tex="ring.crisp",orient="flat",size={{0,2},{1,R*2.2}},alpha={{0,.05},{1,1}},color=SHINE},.35)
 shards(E,g,c,16,40,2.6,{WHITE,GOLD,SHINE},.8)
 E.Emit(a,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,GOLD}},life={.4,.8},speed={30,65},spread=180,drag=2},44)
 E.Light(g,a,GOLD,R*2.5,10,.5)
 grade(E,{Saturation=-.5,Brightness=.12,Contrast=.2,TintColor=Color3.fromRGB(255,240,210)},.4)
 E.After(g,1.3,function()g:Destroy()end)
end

return P
