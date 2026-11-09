-- P5Strikes cues: the thorn roots and thickets, the star curtain / falling stars, and the gravity well.
-- Registers its P.<Name>(E, d) functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local P, AMBER, BUTTERFLY_GOLD, GOLD, HIDDEN, NEON, SHINE, UP, VOID = Core.P, Core.AMBER, Core.BUTTERFLY_GOLD, Core.GOLD, Core.HIDDEN, Core.NEON, Core.SHINE, Core.UP, Core.VOID
local WHITE, cracks, debris, dome, grade, newPart, rootOf, shards = Core.WHITE, Core.cracks, Core.debris, Core.dome, Core.grade, Core.newPart, Core.rootOf, Core.shards

 -- a bramble: a stem of six cylinder segments curling a little more at each joint (Curl, about its X; Twist about
 -- its Z), a wedge thorn on every other segment and an aurora bud at the tip. poseBramble lays it out at growth k
 -- (0..1, the stem grows segment by segment) and height scale, adding its parts to parts/cfs for one BulkMoveTo
local function bramble(g,base,height,width,curl,twist)
 local b={Base=base,H=height,W=width*1.4,Curl=curl,Twist=twist or 0,Segs={},Thorns={}}
 local shades={Color3.fromRGB(74,46,14),Color3.fromRGB(108,70,20),Color3.fromRGB(160,110,30),Color3.fromRGB(205,152,44),GOLD,BUTTERFLY_GOLD}  -- golden roots: bronze at the base, bright gold at the tip
 for i=1,6 do
  local p=newPart(g,Vector3.one*.1,shades[i],0)
  p.Shape=Enum.PartType.Cylinder p.Material=Enum.Material.SmoothPlastic
  b.Segs[i]=p
  if i<6 then
   local t=Instance.new("WedgePart")
   t.Anchored=true t.CanCollide=false t.CanQuery=false t.CanTouch=false t.CastShadow=false
   t.Color=i%2==0 and BUTTERFLY_GOLD or SHINE t.Material=NEON t.Size=Vector3.one*.1 t.CFrame=HIDDEN t.Parent=g.Folder
   b.Thorns[i]=t
  end
 end
 b.Bud=newPart(g,Vector3.one*.1,SHINE,0) b.Bud.Shape=Enum.PartType.Ball
 return b
end
local function poseBramble(b,k,scale,parts,cfs)
 local n=#b.Segs
 local len=b.H*(scale or 1)/n
 local cf=b.Base
 local grown=math.clamp(k,0,1)*n
 for i,p in ipairs(b.Segs)do
  local f=math.clamp(grown-(i-1),0,1)
  local w=math.max(b.W*(1-.6*(i-1)/n),.15)
  local l=math.max(len*f,.05)
  cf=cf*CFrame.Angles(b.Curl*(i/n),0,b.Twist*(i/n))
  local mid=cf*CFrame.new(0,l/2,0)
  p.Size=Vector3.new(l,w,w)
  parts[#parts+1]=p cfs[#cfs+1]=mid*CFrame.Angles(0,0,math.pi/2)  -- a cylinder runs along X: stand it up
  local th=b.Thorns[i]
  if th then  -- a long thin spike jutting out and up from the stem
   local sz=math.max(w,.4)*f
   th.Size=Vector3.new(math.max(sz*.18,.05),math.max(sz*2.4,.05),math.max(sz*.7,.05))
   parts[#parts+1]=th cfs[#cfs+1]=mid*CFrame.Angles(0,i*2.4,0)*CFrame.new(w*.45+sz*.9,0,0)*CFrame.Angles(0,0,-1.25)
  end
  cf=cf*CFrame.new(0,l,0)
 end
 b.Bud.Size=Vector3.one*math.max(b.W*1.2*math.clamp(k*2-1,0,1),.05)
 parts[#parts+1]=b.Bud cfs[#cfs+1]=cf
end
 -- the roots: they tear up along the line as the front passes, thorns breaking the surface, then sink
function P.Roots(E,d)
 local g=E.Group("P5Roots")
 local lane=d.Frame
 local speed,L=d.Speed or 130,d.Range or 100
 local T=L/speed
 local floor=E.Ground(lane.Position+UP*4,{d.Boss,g.Folder})
 local base=CFrame.new(Vector3.new(lane.X,floor and floor.Y or lane.Y,lane.Z))*lane.Rotation
  -- golden roots tear up out of the ground along the line, a big one and a smaller one beside it every few studs; the
  -- ground splits and spits dust and sparks where they break through, and a hot spark rides the front
 local list,nextAt,row=({}),3,0
 local per=E.Quality<.6 and 1 or 2
 local scar=newPart(g,Vector3.new(1.4,.08,.1),SHINE,.05)
 local glow=newPart(g,Vector3.new(6,.06,.1),AMBER,.55)
 local head=E.Anchor(g,base)
 local spray=E.Stream(head,{tex="star.crisp",size={{0,1.4},{1,0}},color={{0,WHITE},{1,GOLD}},life={.25,.45},speed={10,22},spread=60,
  dir=Enum.NormalId.Top,accel=Vector3.new(0,-30,0)},60)
 E.Sprite(head,{tex="glow.soft",size=9,alpha=.35,color=GOLD},T)
 E.Light(g,head,GOLD,22,4,T+.2)
 E.Step(g,function(_,t)
  local front=L*math.clamp(t/T,0,1)
  local l=math.max(front,.1)
  scar.Size=Vector3.new(1.4,.08,l) glow.Size=Vector3.new(6,.06,l)
  local scf=base*CFrame.new(0,.06,-l/2)
  local parts,cfs={scar,glow,head},{scf,scf,base*CFrame.new(0,1,-front)}
  while nextAt<=front do
   row+=1
   for j=1,per do
    local big=j==1
    local x=big and(math.random()-.5)*.8 or(row%2==0 and -1 or 1)*(1.8+math.random()*1.4)
    local b=bramble(g,base*CFrame.new(x,0,-nextAt)*CFrame.Angles(0,math.random()*6.28,0),
     big and 7+math.random()*4 or 4+math.random()*3,big and .8 or .55,(math.random()-.5)*.7,(math.random()-.5)*.5)
    b.Born=t
    list[#list+1]=b
   end
   local a=E.Anchor(g,base*CFrame.new(0,.3,-nextAt))
   E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,6}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(170,130,60)},{1,Color3.fromRGB(110,85,45)}},
    life={.5,.9},speed={6,12},spread=70,dir=Enum.NormalId.Top,drag=2},5)
   E.Emit(a,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={14,28},spread=45,dir=Enum.NormalId.Top,
    accel=Vector3.new(0,-40,0)},8)
   if row%3==1 then cracks(E,g,(base*CFrame.new(0,0,-nextAt)).Position,7,4,AMBER,1.3)end
   nextAt+=5
  end
  for _,b in ipairs(list)do
   local age=t-b.Born
   local k=age<.12 and age/.12 or(age<.9 and 1 or math.max(0,1-(age-.9)/.4))
   poseBramble(b,k,age<.2 and 1.15 or 1,parts,cfs)  -- a little overshoot as it bursts up
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then spray.Enabled=false end
  return t<T+1.4
 end)
 E.Tween(scar,.5,{Transparency=1},nil,nil,T+.8)
 E.Tween(glow,.4,{Transparency=1},nil,nil,T+.6)
 E.After(g,T+1.7,function()g:Destroy()end)
end
 -- whoever the roots catch: vines circle and grip them
function P.Rooted(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T=d.Time or 1
 local g=E.Group("P5Rooted")
 local vines={}
 for i=1,6 do vines[i]=newPart(g,Vector3.new(.35,.35,2.6),i%2==0 and GOLD or SHINE,0)end
 local a=E.Anchor(g,vr.CFrame)
 E.Sprite(a,{tex="glow.soft",size=6,alpha={{0,.5},{1,1}},color=AMBER},T)
 E.Step(g,function(_,t)
  if not vr.Parent then return false end
  a.CFrame=vr.CFrame
  local parts,cfs={},{}
  for i,v in ipairs(vines)do
   local ang=i*math.pi/3+t*2.5
   local y=-2.6+(i%3)*1.2
   local at=vr.Position+Vector3.new(math.cos(ang)*1.3,y,math.sin(ang)*1.3)
   parts[#parts+1]=v cfs[#cfs+1]=CFrame.lookAt(at,at+Vector3.new(-math.sin(ang),.3,math.cos(ang)))
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T
 end)
 E.After(g,T+.1,function()g:Destroy()end)
end
 -- the thicket: an aurora-lit field where low thorns grow in, swaying; ThicketSnap throws them up tall
local thickets={}
function P.Thicket(E,d)
 local g=E.Group("P5Thicket")
 local R,T=d.Radius or 18,d.Time or 2
 local floor=E.Ground(d.Pos+UP*3,{g.Folder})
 local c=(floor or d.Pos)
 local a=E.Anchor(g,CFrame.new(c+UP*.12))
  -- only a soft glow on the floor, no hard ring; aurora motes rising out of it
 E.Sprite(a,{tex="disc.soft",orient="flat",size={{0,R*.4},{.6,R*2.2},{1,R*2.2}},alpha={{0,.92},{.6,.76},{1,.72}},color=GOLD},T+.3)
 local motes=E.Stream(a,{tex="star.twinkle",size={{0,.7},{1,0}},color={{0,WHITE},{.5,GOLD},{1,AMBER}},life={.8,1.4},speed={3,8},spread=30,
  dir=Enum.NormalId.Top},26)
 E.Light(g,a,GOLD,R*2,2.5,T+.4)
 local list={}
  -- a ring of tall brambles on the edge arching in over the middle (a cage), smaller ones growing inside
 local edge=E.Quality<.6 and 12 or 18
 for i=1,edge do
  local ang=i/edge*math.pi*2+math.random()*.15
  local at=c+Vector3.new(math.cos(ang)*R,0,math.sin(ang)*R)
  local b=bramble(g,CFrame.lookAt(at,Vector3.new(c.X,at.Y,c.Z)),R*.75+math.random()*R*.3,.95,-.3-math.random()*.08,(math.random()-.5)*.2)
  b.Born=(i/edge)*T*.35
  list[#list+1]=b
  E.After(g,b.Born,function()
   local p=E.Anchor(g,CFrame.new(at+UP*.4))
   E.Emit(p,{tex="smoke",light=0,size={{0,2},{1,5}},alpha={{0,.5},{1,1}},color={{0,Color3.fromRGB(170,130,60)},{1,Color3.fromRGB(110,85,45)}},
    life={.4,.8},speed={5,10},spread=60,dir=Enum.NormalId.Top,drag=2},3)
   E.Emit(p,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,GOLD}},life={.25,.5},speed={10,20},spread=50,dir=Enum.NormalId.Top},5)
  end)
 end
 for i=1,(E.Quality<.6 and 5 or 9)do
  local ang,rad=math.random()*math.pi*2,math.sqrt(math.random())*R*.7
  local at=c+Vector3.new(math.cos(ang)*rad,0,math.sin(ang)*rad)
  local b=bramble(g,CFrame.new(at)*CFrame.Angles(0,math.random()*6.28,0),4+math.random()*4,.6,(math.random()-.5)*.5,(math.random()-.5)*.4)
  b.Born=T*(.2+.4*math.random())
  list[#list+1]=b
 end
 local set={G=g,List=list,Snap=nil,Motes=motes,C=c}
 thickets[#thickets+1]=set
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,b in ipairs(list)do
   local k,scale=1,1
   if set.Snap then  -- the snap: every bramble whips up to more than twice its height, then pulls back down
    local u=t-set.Snap
    scale=1+1.6*math.clamp(u/.12,0,1)
    k=math.max(0,1-math.max(0,u-.45)/.4)
   else
    k=math.clamp((t-b.Born)/.5,0,1)
    scale=1+.04*math.sin(t*4+b.Curl*20)
   end
   poseBramble(b,k,scale,parts,cfs)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return not set.Snap or t-set.Snap<1
 end)
 set.Start=os.clock()
 E.After(g,T+3,function()g:Destroy()end)
end
function P.ThicketSnap(E,d)
 local set,best
 for i=#thickets,1,-1 do
  local th=thickets[i]
  if not th.G.Alive then
   table.remove(thickets,i)
  elseif not set or(th.C-d.Pos).Magnitude<best then
   set,best=th,(th.C-d.Pos).Magnitude
  end
 end
 if set then table.remove(thickets,table.find(thickets,set))end
 if set and set.G.Alive then
  set.Snap=os.clock()-set.Start
  set.Motes.Enabled=false
 end
 local g=E.Group("P5ThicketSnap")
 local R=d.Radius or 18
 local floor=E.Ground(d.Pos+UP*3,{g.Folder})
 local c=(floor or d.Pos)
 local a=E.Anchor(g,CFrame.new(c+UP*3))
  -- the snap: a gold dome of force, a pillar of light ripping up through the middle, the ground splitting, rock and
 dome(E,g,c+UP*2,WHITE,4,R*1.2,.25,.05)
 dome(E,g,c+UP*2,GOLD,5,R*2.2,.5,.3,Enum.Material.ForceField)
 local pillar=newPart(g,Vector3.new(60,R*.6,R*.6),SHINE,.05) pillar.Shape=Enum.PartType.Cylinder
 local sheath=newPart(g,Vector3.new(62,R*1.1,R*1.1),GOLD,.45) sheath.Shape=Enum.PartType.Cylinder
 local up=CFrame.new(c+UP*30)*CFrame.Angles(0,0,math.pi/2)
 pillar.CFrame=up sheath.CFrame=up
 E.Tween(pillar,.45,{Size=Vector3.new(60,.1,.1),Transparency=1},Enum.EasingStyle.Quad,nil,.05)
 E.Tween(sheath,.5,{Size=Vector3.new(62,.1,.1),Transparency=1},Enum.EasingStyle.Quad,nil,.05)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.12,R*2.2},{1,R*2.6}},alpha={{0,0},{.5,.35},{1,1}},color=SHINE},.4)
 E.Sprite(a,{tex="burst.spiky2",size={{0,3},{1,R*2.4}},alpha={{0,0},{1,1}},color=GOLD,rot={0,360}},.35)
 E.Emit(a,{tex="butterfly",size={{0,1.3},{1,0}},color={{0,WHITE},{.5,GOLD},{1,AMBER}},life={.6,1.1},speed={22,48},spread=70,dir=Enum.NormalId.Top,drag=1.5},24)
 E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.7},speed={30,60},spread=180,drag=2},40)
 E.Emit(a,{tex="smoke",light=0,size={{0,4},{1,11}},alpha={{0,.4},{1,1}},color={{0,Color3.fromRGB(180,140,70)},{1,Color3.fromRGB(110,85,45)}},
  life={.8,1.3},speed={18,34},spread=80,dir=Enum.NormalId.Top,drag=3},16)
 shards(E,g,c+UP*3,14,38,2.4,{WHITE,GOLD,BUTTERFLY_GOLD},.8)
 debris(E,g,c+UP,10)
 cracks(E,g,c,R*1.2,10,AMBER,1.5)
 E.Light(g,a,GOLD,R*3,10,.5)
 grade(E,{Brightness=.12,Contrast=.18,TintColor=Color3.fromRGB(255,236,200)},.4)
 E.After(g,1.6,function()g:Destroy()end)
end

 -- Aurora Curtain: where the next curtain starts - a line of aurora light on the ground and two pillars on its gap
function P.CurtainWarn(E,d)
 local g=E.Group("P5CurtainWarn")
 local f=d.Frame
 local T,span,gapAt,gap=d.Time or .9,d.Span or 300,d.GapAt or 0,d.Gap or 0
 local floor=E.Ground(f.Position+UP*4,{g.Folder})
 local base=CFrame.new(Vector3.new(f.X,floor and floor.Y or f.Y,f.Z))*f.Rotation
 local line=newPart(g,Vector3.new(span,.08,1.2),SHINE,.15)
 line.CFrame=base*CFrame.new(0,.06,0)
 local glow=newPart(g,Vector3.new(span,.07,5),AMBER,.55)
 glow.CFrame=line.CFrame
  -- gold motes already rising off the line where the curtain will come down
 local moteBox=newPart(g,Vector3.new(span,1,2),WHITE,1)
 moteBox.CFrame=base*CFrame.new(0,.6,0)
 local motes=E.Stream(moteBox,{tex="star.twinkle",size={{0,.8},{1,0}},color={{0,WHITE},{.5,GOLD},{1,AMBER}},life={.7,1.1},speed={7,14},spread=6,
  dir=Enum.NormalId.Top,shape=Enum.ParticleEmitterShape.Box},90)
 if gap>0 then
  for _,x in ipairs({gapAt-gap/2,gapAt+gap/2})do
   local p=newPart(g,Vector3.new(1.2,40,1.2),GOLD,.15)
   p.CFrame=base*CFrame.new(x,20,0)
   E.Tween(p,.3,{Transparency=1},nil,nil,T)
  end
 end
 E.Tween(line,.3,{Transparency=1},nil,nil,T)
 E.Tween(glow,.3,{Transparency=1},nil,nil,T)
 E.After(g,T,function()motes.Enabled=false end)
 E.After(g,T+1.2,function()g:Destroy()end)
end
 -- Aurora Curtain: the curtain itself - two walls of the northern lights either side of the gap, rippling, sweeping
 -- along the ground, the gap's edges marked by pillars of gold
function P.Curtain(E,d)
 local g=E.Group("P5Curtain")
 local f=d.Frame
 local T,span,gapAt,gap,H,D=d.Time or 2,d.Span or 300,d.GapAt or 0,d.Gap or 0,d.Height or 40,d.Distance or 280
 local VH=H*1.5  -- drawn half again as tall as it hits, so it towers
 local floor=E.Ground(f.Position+UP*4,{g.Folder})
 local base=CFrame.new(Vector3.new(f.X,floor and floor.Y or f.Y,f.Z))*f.Rotation
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=base
 local up=CFrame.fromMatrix(Vector3.zero,Vector3.new(0,0,-1),UP)  -- X down the sweep, Y up: the beam's width stands up
 local flat=CFrame.fromMatrix(Vector3.zero,UP,Vector3.new(0,0,-1))  -- Y down the sweep: the width lies on the floor
 local walls,rays={},{}
 local function wall(x0,x1)
  if x1-x0<1 then return end
  local a0=E.Attach(carrier,CFrame.new(x0,VH/2,0)*up)
  local a1=E.Attach(carrier,CFrame.new(x1,VH/2,0)*up)
  walls[#walls+1]=E.Beam(g,a0,a1,{tex="beam.curtain",color={{0,BUTTERFLY_GOLD},{.35,AMBER},{.7,BUTTERFLY_GOLD},{1,AMBER}},alpha={{0,.15},{.5,.05},{1,.15}},
   width=VH,face=false,mode=Enum.TextureMode.Wrap,length=40,scroll=2,brightness=1,segments=16})
  walls[#walls+1]=E.Beam(g,a0,a1,{tex="beam.wisp",color={{0,AMBER},{.5,BUTTERFLY_GOLD},{1,AMBER}},alpha=.35,width=VH*1.12,face=false,length=60,scroll=-3,segments=16})
  walls[#walls].LightEmission=.45 walls[#walls-1].LightEmission=.45  -- less glow: gold, not white, against the sky
  local b0=E.Attach(carrier,CFrame.new(x0,1.2,0)*up)
  local b1=E.Attach(carrier,CFrame.new(x1,1.2,0)*up)
  E.Beam(g,b0,b1,{tex="beam.core",color=WHITE:Lerp(GOLD,.35),alpha=0,width=2.4,face=false,brightness=3})
   -- where it meets the ground, a wide soft band of light across the floor
  local f0=E.Attach(carrier,CFrame.new(x0,.2,0)*flat)
  local f1=E.Attach(carrier,CFrame.new(x1,.2,0)*flat)
  E.Beam(g,f0,f1,{tex="beam.wisp",color={{0,GOLD},{1,AMBER}},alpha=.35,width=10,face=false,length=50,scroll=4})
   -- rays: tall streaks of light standing out of it every 14 studs
  for x=x0+7,x1-7,14 do
   local r0=E.Attach(carrier,CFrame.new(x,0,0))
   local r1=E.Attach(carrier,CFrame.new(x,VH*(.8+math.random()*.35),0))
   local w=2+math.random()*2.5
   rays[#rays+1]={B=E.Beam(g,r0,r1,{color={{0,BUTTERFLY_GOLD},{.5,GOLD},{1,AMBER}},alpha={{0,.2},{.6,.5},{1,1}},width=w,face=true,brightness=1.1}),W=w,P=math.random()*6}
   rays[#rays].B.LightEmission=.6
  end
 end
 if gap>0 then
  wall(-span/2,gapAt-gap/2)
  wall(gapAt+gap/2,span/2)
 else
  wall(-span/2,span/2)
 end
 for _,b in ipairs(g.Folder:GetDescendants())do if b:IsA("Beam")then b.LightInfluence=0 end end
 local pillars={}
 if gap>0 then
  for _,x in ipairs({gapAt-gap/2,gapAt+gap/2})do pillars[#pillars+1]={P=newPart(g,Vector3.new(1,VH+4,1),GOLD,.1),X=x}end
 end
 local moteBox=newPart(g,Vector3.new(span,VH,2),WHITE,1)
 local motes=E.Stream(moteBox,{tex="star.twinkle",size={{0,.8},{1,0}},color={{0,WHITE},{.5,GOLD},{1,AMBER}},life={.6,1},speed={2,6},spread=180,
  shape=Enum.ParticleEmitterShape.Box},50)
 E.Light(g,moteBox,GOLD,60,4,T+.2)
 grade(E,{TintColor=Color3.fromRGB(240,226,200),Brightness=-.06,Contrast=.14,Saturation=.12},T+.4)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local cf=base*CFrame.new(0,0,-D*k)
  local parts,cfs={carrier,moteBox},{cf,cf*CFrame.new(0,VH/2,0)}
  for _,pl in ipairs(pillars)do parts[#parts+1]=pl.P cfs[#cfs+1]=cf*CFrame.new(pl.X,(VH+4)/2,0)end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
   -- the folds ripple, the rays flicker
  for i,b in ipairs(walls)do
   b.CurveSize0=math.sin(t*1.8+i)*7
   b.CurveSize1=-math.sin(t*1.4+i+1.5)*7
  end
  for _,r in ipairs(rays)do
   local w=r.W*(.65+.35*math.sin(t*5+r.P))
   r.B.Width0=w r.B.Width1=w*.4
  end
  if k>=1 then
   motes.Enabled=false
   g:Fade(.4)
   return false
  end
  return true
 end)
 E.After(g,T+1.2,function()g:Destroy()end)
end

 -- Falling Star: a circle opens where it will land - a slow cosmic sigil and a ring closing in - while the star comes
 -- down out of the sky on a long trail of violet and gold
function P.StarFall(E,d)
 local g=E.Group("P5StarFall")
 local R,T,big=d.Radius or 10,d.Time or 1.3,d.Big==true
 local floor=E.Ground(d.Pos+UP*4,{g.Folder})
 local c=(floor or d.Pos)
 local size=big and 10 or 4
 local from=c+Vector3.new(big and 70 or 30,big and 220 or 120,big and 45 or 20)
  -- the star: a white core, a blue shell and a shimmering violet field, a long cosmic trail and a tail of fire and dust
 local star=newPart(g,Vector3.one*size,WHITE,0) star.Shape=Enum.PartType.Ball
 local shell=newPart(g,Vector3.one*size*1.45,SHINE,.55) shell.Shape=Enum.PartType.Ball
 local field=newPart(g,Vector3.one*size*2,AMBER,0) field.Shape=Enum.PartType.Ball field.Material=Enum.Material.ForceField
 local s0=E.Attach(star,CFrame.new(0,size*.9,0))
 local s1=E.Attach(star,CFrame.new(0,-size*.9,0))
 local tr=Instance.new("Trail")tr.Attachment0=s0 tr.Attachment1=s1 tr.Lifetime=big and .7 or .4 tr.LightEmission=1 tr.LightInfluence=0
 tr.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,WHITE),ColorSequenceKeypoint.new(.25,SHINE),ColorSequenceKeypoint.new(.6,AMBER),ColorSequenceKeypoint.new(1,BUTTERFLY_GOLD)})
 tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.6,.5),NumberSequenceKeypoint.new(1,1)})
 tr.WidthScale=NumberSequence.new(1,.1) tr.FaceCamera=true tr.Parent=star
 local tail=E.Stream(star,{tex="fire",size={{0,size*1.6},{1,size*.3}},alpha={{0,.15},{1,1}},color={{0,WHITE},{.3,SHINE},{1,AMBER}},life={.3,.5},
  speed={0,2},spread=25,locked=false},60)
 local dust=E.Stream(star,{tex="star.twinkle",size={{0,size*.25},{1,0}},color={{0,SHINE},{.5,GOLD},{1,BUTTERFLY_GOLD}},life={.6,1.1},speed={2,8},spread=180,
  locked=false},40)
 E.Sprite(star,{tex="glow.soft",size=size*6,alpha=.25,color=SHINE},T)
 E.Sprite(star,{tex="star.anime",size=size*4.5,alpha=.1,color=SHINE,spin={90,90}},T)
 E.Sprite(star,{tex="flare.streak",size=size*7,alpha=.35,color=SHINE},T)
 E.Light(g,star,SHINE,size*8,6,T)
  -- no circle on the ground: a thin shaft of starlight pins where it lands, and the ground there lights up and
  -- sheds motes as it gets close (the big one darkens the sky while it falls)
 local spot=E.Anchor(g,CFrame.new(c+UP*.3))
 local shaft=E.Beam(g,E.Attach(star),E.Attach(spot),{tex="beam.core",color={{0,SHINE},{1,AMBER}},alpha=.7,width=big and 5 or 2,brightness=2})
 local glow=E.Light(g,spot,AMBER,R*2.2,0,T+.1)
 local lift=E.Stream(spot,{tex="star.twinkle",size={{0,.8},{1,0}},color={{0,SHINE},{1,AMBER}},life={.6,1},speed={4,10},spread=70,dir=Enum.NormalId.Top},
  big and 30 or 12)
 if big then grade(E,{Brightness=-.1,Contrast=.12,TintColor=Color3.fromRGB(222,208,255)},T+.3)end
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local p=from:Lerp(c,k*k)
  workspace:BulkMoveTo({star,shell,field},{CFrame.new(p),CFrame.new(p),CFrame.new(p)*CFrame.Angles(t*2,t*3,0)},Enum.BulkMoveMode.FireCFrameChanged)
  glow.Brightness=8*k*k
  if shaft then shaft.Transparency=NumberSequence.new(.75-.45*k)end
  if k>=1 then
   tail.Enabled=false dust.Enabled=false lift.Enabled=false tr.Enabled=false
   star.Transparency=1 shell.Transparency=1 field.Transparency=1
   if shaft then shaft.Enabled=false end
   return false
  end
  return true
 end)
 E.After(g,T+.8,function()g:Destroy()end)
end
 -- Falling Star: the crash - a flash, a spiked burst, a scorched crater with cracks, rock thrown up and star shards
function P.StarImpact(E,d)
 local g=E.Group("P5StarImpact")
 local R,big=d.Radius or 10,d.Big==true
 local floor=E.Ground(d.Pos+UP*4,{g.Folder})
 local c=(floor or d.Pos)
 local a=E.Anchor(g,CFrame.new(c+UP*3))
 local f=E.Anchor(g,CFrame.new(c+UP*.15))
  -- the blast's volume: a white core, a blue shell and a shimmering violet field swelling past the hit radius
 dome(E,g,c,WHITE,R*.3,R*1.5,.25,0)
 dome(E,g,c,SHINE,R*.5,R*2.1,.4,.35)
 dome(E,g,c,AMBER,R*.6,R*2.6,.6,0,Enum.Material.ForceField)
  -- a pillar of starlight shooting up out of the crater, thinning away
 local pillar=newPart(g,Vector3.one,SHINE,.1) pillar.Shape=Enum.PartType.Cylinder
 local Hp=big and 170 or 70
 E.Step(g,function(_,t)
  local w=R*(big and .9 or .7)*math.max(0,1-t/.5)+.05
  local h=Hp*math.min(t/.08,1)
  pillar.Size=Vector3.new(h,w,w) pillar.CFrame=CFrame.new(c+UP*h/2)*CFrame.Angles(0,0,math.pi/2)
  if t>=.5 then pillar.Transparency=1 return false end
  return true
 end)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.1,R*2.8},{1,R*3.2}},alpha={{0,0},{.5,.25},{1,1}},color=WHITE},big and .6 or .4)
 E.Sprite(a,{tex="burst.spiky2",size={{0,3},{1,R*2.6}},alpha={{0,0},{1,1}},color=AMBER,rot={0,360}},.4)
 E.Sprite(f,{tex="ring.crisp",orient="flat",size={{0,2},{1,R*3}},alpha={{0,.05},{1,1}},color=SHINE},.4)
 cracks(E,g,c,R*1.3,big and 14 or 7,AMBER,big and 2.4 or 1.4)
 debris(E,g,c,big and 16 or 6)
 shards(E,g,c+UP*2,big and 22 or 9,big and 70 or 45,big and 3.4 or 2,{SHINE,AMBER,SHINE,BUTTERFLY_GOLD},big and 1.4 or 1)
 E.Emit(a,{tex="star.anime",size={{0,1.8},{1,0}},color={{0,WHITE},{.5,GOLD},{1,AMBER}},life={.5,1},speed={R*1.5,R*3},spread=70,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,-40,0),drag=1},big and 46 or 18)
 E.Emit(f,{tex="smoke",light=0,size={{0,R*.3},{1,R*.9}},alpha={{0,.4},{1,1}},color={{0,Color3.fromRGB(70,50,90)},{1,VOID}},life={.7,1.2},speed={R,R*2},
  spread=80,dir=Enum.NormalId.Top,drag=3},big and 22 or 8)
 local dust=E.Stream(f,{tex="star.twinkle",size={{0,.7},{1,0}},color={{0,SHINE},{1,AMBER}},life={.8,1.4},speed={1,3},spread=60,dir=Enum.NormalId.Top},12)
 E.Light(g,a,big and GOLD or SHINE,R*3,10,.5)
 grade(E,big and{Brightness=.35,Contrast=.25,TintColor=Color3.fromRGB(232,218,255)}or{Brightness=.1,Contrast=.08},big and .7 or .3)
 E.After(g,big and 2.5 or 1.2,function()dust.Enabled=false end)
 E.After(g,big and 3.5 or 2,function()g:Destroy()end)
end

 -- Gravity Crush: a singularity opens - a black core with a violet rim, accretion rings turning round it, light and
 -- dust streaming into it, its pull marked on the ground
local singularities={}
function P.GravityWell(E,d)
 local g=E.Group("P5GravityWell")
 local R,T,delay=d.Radius or 22,d.Time or 2.7,d.Delay or .8
 local floor=E.Ground(d.Pos+UP*4,{g.Folder})
 local c=(floor or d.Pos)
 local top=c+UP*19
  -- the singularity: a black core inside two counter-turning shimmering fields and a violet halo
 local core=newPart(g,Vector3.one*.5,Color3.new(0,0,0),0) core.Shape=Enum.PartType.Ball core.Material=Enum.Material.SmoothPlastic
 local inner=newPart(g,Vector3.one,AMBER,0) inner.Shape=Enum.PartType.Ball inner.Material=Enum.Material.ForceField
 local outer=newPart(g,Vector3.one,BUTTERFLY_GOLD,0) outer.Shape=Enum.PartType.Ball outer.Material=Enum.Material.ForceField
 local halo=newPart(g,Vector3.one,AMBER,.84) halo.Shape=Enum.PartType.Ball
 core.CFrame=CFrame.new(top)
 local a=E.Anchor(g,CFrame.new(top))
 E.Sprite(a,{tex="glow.soft",size={{0,2},{.3,22},{1,24}},alpha={{0,.4},{1,.25}},color=AMBER},T)
 E.Sprite(a,{tex="vortex.soft",size={{0,2},{.3,26},{1,28}},alpha={{0,.35},{1,.25}},color=SHINE,spin={-260,-260}},T)
 local ring=E.Anchor(g,CFrame.new(top)*CFrame.Angles(.5,0,.3))
 E.Sprite(ring,{tex="ring.thin",orient="flat",size={{0,2},{.3,22},{1,20}},alpha={{0,.3},{1,.15}},color=SHINE,spin={160,160}},T)
  -- the accretion disc: chips of light whirling round it on a tilted plane
 local tilt=CFrame.new(top)*CFrame.Angles(.45,0,.25)
 local disc={}
 for i=1,30 do
  local p=newPart(g,Vector3.new(.35,.35,1.6+math.random()*1.6),i%3==0 and SHINE or(i%3==1 and AMBER or BUTTERFLY_GOLD),.1)
  disc[i]={P=p,R=7+math.random()*6,A=math.random()*math.pi*2,W=2.5+math.random()*2.5,Y=(math.random()-.5)*1.2}
 end
 local pull=E.Stream(a,{tex="wind.dash",orient="velocity",size={{0,6},{1,1}},alpha={{0,.4},{1,1}},color=AMBER:Lerp(SHINE,.3),life={.4,.6},
  speed={-70,-45},spread=180},70)
 local dust=E.Stream(a,{tex="star.tiny",size={{0,.9},{1,0}},color={{0,SHINE},{1,AMBER}},life={.5,.7},speed={-45,-28},spread=180},80)
  -- the floor (no circle): dust dragged in from all round toward the spot under it, and rocks torn up spiralling
  -- into the core, crushed as they reach it
 local drags={}
 for i=1,8 do
  local ang=i*math.pi/4
  local edge=c+Vector3.new(math.cos(ang)*R,.6,math.sin(ang)*R)
  local an=E.Anchor(g,CFrame.lookAt(edge,c+UP*.6))
  drags[i]=E.Stream(an,{tex="smoke",light=0,size={{0,2.5},{1,5}},alpha={{0,.55},{1,1}},color={{0,Color3.fromRGB(120,100,140)},{1,Color3.fromRGB(60,45,80)}},
   life={.7,1},speed={18,26},spread=15,dir=Enum.NormalId.Front},6)
 end
 local rocks={}
 for i=1,14 do
  local ang,rad=math.random()*math.pi*2,R*(.35+math.random()*.65)
  local p=newPart(g,Vector3.one*(.8+math.random()*1.6),Color3.fromRGB(120,96,60),0) p.Material=Enum.Material.Slate
  rocks[i]={P=p,A=ang,Rad=rad,Start=math.random()*.5,Spin=CFrame.Angles(math.random()*6,math.random()*6,0),S0=p.Size}
 end
 E.Light(g,a,AMBER,48,7,T)
 local well={G=g,Core=core,Top=top,Fields={inner,outer,halo}}
 singularities[#singularities+1]=well
 E.Step(g,function(_,t)
  if well.Slammed then return false end
  local k=math.clamp(t/delay,0,1)
  local beat=1+.06*math.sin(t*20)
  core.Size=Vector3.one*(1+5*k*beat)
  inner.Size=Vector3.one*(1+9*k) outer.Size=Vector3.one*(1+13*k*beat) halo.Size=Vector3.one*(2+20*k)
  local parts={inner,outer,halo}
  local cfs={CFrame.new(top)*CFrame.Angles(t*1.5,t*2.3,0),CFrame.new(top)*CFrame.Angles(-t*1.1,-t*1.7,t),CFrame.new(top)}
  for _,ch in ipairs(disc)do
   local ang=ch.A+t*ch.W
   local pos=(tilt*CFrame.new(math.cos(ang)*ch.R*k,ch.Y,math.sin(ang)*ch.R*k)).Position
   local ahead=(tilt*CFrame.new(math.cos(ang+.1)*ch.R*k,ch.Y,math.sin(ang+.1)*ch.R*k)).Position
   parts[#parts+1]=ch.P cfs[#cfs+1]=CFrame.lookAt(pos,ahead)
  end
  for _,r in ipairs(rocks)do
   local u=math.clamp((t-r.Start)/(T*.8),0,1)
   local e=u*u
   local ang=r.A+e*5
   local rad=r.Rad*(1-e)
   r.P.Size=r.S0*math.max(1-e*e,.05)
   parts[#parts+1]=r.P
   cfs[#cfs+1]=CFrame.new(c.X+math.cos(ang)*rad,c.Y+.5+(top.Y-c.Y)*e,c.Z+math.sin(ang)*rad)*r.Spin*CFrame.Angles(t*3,t*2,0)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then
   pull.Enabled=false dust.Enabled=false
   for _,s in ipairs(drags)do s.Enabled=false end
   return false
  end
  return true
 end)
 E.After(g,T+1,function()g:Destroy()end)
end
 -- Gravity Crush: the slam - the singularity collapses into a flash and the ground breaks where they hit
function P.GravitySlam(E,d)
 local well=table.remove(singularities,1)
 local g=E.Group("P5GravitySlam")
 local R=d.Radius or 22
 local floor=E.Ground(d.Pos+UP*4,{g.Folder})
 local c=(floor or d.Pos)
 if well and well.G.Alive then
  well.Slammed=true
  E.Tween(well.Core,.15,{Size=Vector3.one*.1})
  for _,p in ipairs(well.Fields)do E.Tween(p,.15,{Size=Vector3.one*.1,Transparency=1})end
  for _,p in ipairs(well.G.Folder:GetChildren())do if p:IsA("BasePart")and p.Material==Enum.Material.Slate then p.Transparency=1 end end
  local h=E.Anchor(well.G,CFrame.new(well.Top))
  E.Sprite(h,{tex="flare.burst2",size={{0,4},{1,30}},alpha={{0,0},{1,1}},color=AMBER},.3)
   -- the collapse drops: a column of violet light from where it hung down onto the floor
  local col=newPart(g,Vector3.one,AMBER,.15) col.Shape=Enum.PartType.Cylinder
  local beam=newPart(g,Vector3.one,SHINE,0) beam.Shape=Enum.PartType.Cylinder
  local len=math.max((well.Top-c).Magnitude,1)
  local cf=CFrame.new((well.Top+c)/2)*CFrame.Angles(0,0,math.pi/2)
  E.Step(g,function(_,t)
   local w=math.max(0,1-t/.35)
   col.Size=Vector3.new(len,9*w+.05,9*w+.05) beam.Size=Vector3.new(len,3.4*w+.05,3.4*w+.05)
   workspace:BulkMoveTo({col,beam},{cf,cf},Enum.BulkMoveMode.FireCFrameChanged)
   if t>=.35 then col.Transparency=1 beam.Transparency=1 return false end
   return true
  end)
 end
 local a=E.Anchor(g,CFrame.new(c+UP*2))
 local f=E.Anchor(g,CFrame.new(c+UP*.15))
 dome(E,g,c,WHITE,R*.2,R*1.2,.22,0)
 dome(E,g,c,BUTTERFLY_GOLD,R*.3,R*1.8,.4,.4)
 dome(E,g,c,AMBER,R*.4,R*2.3,.55,0,Enum.Material.ForceField)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.12,R*2},{1,R*2.4}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.4)
 E.Sprite(f,{tex="burst.spiky",orient="flat",size={{0,3},{.2,R*2},{1,R*2.3}},alpha={{0,0},{.6,.35},{1,1}},color=AMBER},.8)
 cracks(E,g,c,R,12,AMBER,2)
 debris(E,g,c,14)
 shards(E,g,c+UP*1.5,14,50,2.2,{AMBER,BUTTERFLY_GOLD,SHINE},1.1)
 E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.4,.8},speed={30,60},spread=70,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,-60,0)},36)
 E.Emit(f,{tex="smoke",light=0,size={{0,R*.3},{1,R*.9}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(110,90,130)},{1,Color3.fromRGB(50,40,70)}},
  life={.7,1.2},speed={R*1.2,R*2},spread=85,dir=Enum.NormalId.Top,drag=3},16)
 E.Light(g,a,AMBER,R*2.5,9,.45)
 grade(E,{Brightness=.25,Contrast=.3,Saturation=-.35,TintColor=Color3.fromRGB(220,200,255)},.6)
 E.After(g,2.2,function()g:Destroy()end)
end

return P
