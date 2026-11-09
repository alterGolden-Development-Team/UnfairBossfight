-- P5Strikes cues: Fire Ring, Shotgun Blast, Perfect Vertical Slash and the knife sets/fields.
-- Registers its P.<Name>(E, d) functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local P, AMBER, BUTTERFLY_GOLD, CRIMSON, GOLD, HIDDEN, NEON, SHINE, UP = Core.P, Core.AMBER, Core.BUTTERFLY_GOLD, Core.CRIMSON, Core.GOLD, Core.HIDDEN, Core.NEON, Core.SHINE, Core.UP
local VOID, WHITE, arcSlash, bladeOf, goldArc, newPart, rootOf = Core.VOID, Core.WHITE, Core.arcSlash, Core.bladeOf, Core.goldArc, Core.newPart, Core.rootOf

 -- a stylized golden flame (the ruined arena's recipe): a flipbook body, toon tongues and a white-gold core in a
 -- patch `size` wide, embers off the top; returns a function that puts it out
local FIRE_BODY="rbxassetid://17703378809"
local FIRE_TOON="rbxassetid://93253997872542"
local function goldFire(g,pos,size,foot)
 foot=foot or size*.9
 local a=newPart(g,Vector3.new(foot,.5,foot),GOLD,1)
 a.CFrame=CFrame.new(pos+UP*size*.32)
 local list={}
 local function add(props)
  local p=Instance.new("ParticleEmitter")
  p.LightInfluence=0 p.Shape=Enum.ParticleEmitterShape.Box p.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
  for k,v in pairs(props)do p[k]=v end
  p.Parent=a list[#list+1]=p
 end
 local function ns(...)local k,v={...},{} for i=1,#k,2 do v[#v+1]=NumberSequenceKeypoint.new(k[i],k[i+1])end return NumberSequence.new(v)end
 add({Texture=FIRE_BODY,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,214,90)),ColorSequenceKeypoint.new(.4,Color3.fromRGB(255,160,30)),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,70,10))}),
  LightEmission=.25,Brightness=1.2,Size=ns(0,size*.85,.4,size*1.05,1,size*.7),Squash=ns(0,.3,1,.4),Transparency=ns(0,.45,.2,.25,.7,.4,1,1),
  Lifetime=NumberRange.new(.8,1.1),Speed=NumberRange.new(size*.08,size*.15),Rotation=NumberRange.new(-8,8),Rate=4})
 add({Texture=FIRE_TOON,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=ColorSequence.new(Color3.fromRGB(255,240,190),Color3.fromRGB(255,200,120)),LightEmission=.15,Brightness=1.1,
  Size=ns(0,size*.32,.35,size*.64,1,size*.24),Squash=ns(0,.55,1,.8),Transparency=ns(0,.2,.2,0,.8,.15,1,1),Lifetime=NumberRange.new(.55,.85),
  Speed=NumberRange.new(size*.35,size*.6),SpreadAngle=Vector2.new(12,12),Rotation=NumberRange.new(-6,6),Rate=7,Acceleration=UP*size*.4})
 add({Texture=FIRE_TOON,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=ColorSequence.new(WHITE,Color3.fromRGB(255,236,150)),LightEmission=.8,Brightness=1.6,Size=ns(0,size*.22,.4,size*.4,1,size*.12),
  Squash=ns(0,.6,1,.8),Transparency=ns(0,.1,.6,.05,1,1),Lifetime=NumberRange.new(.45,.7),Speed=NumberRange.new(size*.15,size*.3),Rate=4,ZOffset=.6})
 add({Texture="rbxasset://textures/particles/sparkles_main.dds",Color=ColorSequence.new(Color3.fromRGB(255,250,210),Color3.fromRGB(255,170,40)),LightEmission=1,Brightness=2,
  Size=ns(0,.5,1,0),Lifetime=NumberRange.new(1,2),Speed=NumberRange.new(size*.45,size*.85),SpreadAngle=Vector2.new(28,28),Acceleration=UP*2,Drag=.8,
  Rate=math.min(size*.4,6)})
 return function()for _,p in ipairs(list)do p.Enabled=false end end
end

 -- a one-shot blast of flipbook fire out of `frame` along its look - o.Reach studs, o.Spread degrees, o.Count flames
 -- of o.Size - rolling into smoke at the end of its reach, embers thrown on through it
local function fireBlast(E,g,frame,o)
 local R,S,spread=o.Reach or 15,o.Size or 6,o.Spread or 30
 local muzzle=newPart(g,Vector3.new(o.Width or 1,o.Width or 1,.2),WHITE,1)
 muzzle.CFrame=frame
 local function ns(...)local k,v={...},{} for i=1,#k,2 do v[#v+1]=NumberSequenceKeypoint.new(k[i],k[i+1])end return NumberSequence.new(v)end
 local function emit(n,props)
  local p=Instance.new("ParticleEmitter")
  p.Rate=0 p.LightInfluence=0 p.EmissionDirection=Enum.NormalId.Front p.SpreadAngle=Vector2.new(spread,spread*.6)
  p.Shape=Enum.ParticleEmitterShape.Box
  for k,v in pairs(props)do p[k]=v end
  p.Parent=muzzle p:Emit(n)
 end
  -- with Drag 5 a flame thrown at v stops about v/5 out, so these roll to a stop right around Reach
 emit(o.Count or 30,{Texture=FIRE_BODY,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,214,120)),ColorSequenceKeypoint.new(.25,Color3.fromRGB(255,120,24)),ColorSequenceKeypoint.new(.6,Color3.fromRGB(196,52,12)),ColorSequenceKeypoint.new(1,Color3.fromRGB(70,22,10))}),
  LightEmission=.08,Brightness=1.25,Size=ns(0,S*.35,.25,S,1,S*1.4),Transparency=ns(0,0,.55,.15,1,1),Lifetime=NumberRange.new(.45,.75),
  Speed=NumberRange.new(R*4.2,R*5.8),Drag=5,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-70,70)})
 emit(math.floor((o.Count or 30)*.6),{Texture=FIRE_TOON,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=ColorSequence.new(Color3.fromRGB(255,246,200),Color3.fromRGB(255,150,40)),LightEmission=.4,Brightness=1.6,Size=ns(0,S*.25,.3,S*.6,1,S*.3),
  Transparency=ns(0,0,.7,.2,1,1),Lifetime=NumberRange.new(.3,.45),Speed=NumberRange.new(R*4.5,R*6.5),Drag=6,Rotation=NumberRange.new(0,360)})
 local a=E.Anchor(g,frame)
 if (o.Smoke or 18)>0 then
  E.Emit(a,{tex="smoke",light=0,size={{0,S*.5},{1,S*2.4}},alpha={{0,.3},{.3,.2},{1,1}},color={{0,Color3.fromRGB(70,58,50)},{1,Color3.fromRGB(32,30,30)}},
   life={1,1.6},speed={R*2.4,R*3.4},spread=spread*.8,dir=Enum.NormalId.Front,drag=3,accel=Vector3.new(0,5,0)},o.Smoke or 18)
 end
 if (o.Embers or 30)>0 then
  E.Emit(a,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,AMBER}},life={.3,.6},speed={R*3,R*6},spread=spread,dir=Enum.NormalId.Front,drag=2,
   accel=Vector3.new(0,-30,0)},o.Embers or 30)
 end
 return a
end

 -- Fire Ring: the wind-up - gold and embers gather on his blade
function P.FireRingTell(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .9
 local g=E.Group("P5FireRingTell")
 local blade=bladeOf(d.Boss)
 local h=E.Anchor(g,blade.CFrame)
 E.Sprite(h,{tex="glow.soft",size={{0,2},{.9,12},{1,14}},alpha={{0,.6},{.9,.2},{1,1}},color=GOLD},T+.05)
 E.Sprite(h,{tex="star.lens",size={{0,1},{.9,9},{1,3}},alpha={{0,.4},{.9,0},{1,1}},color=SHINE,spin={180,180}},T+.05)
 local motes=E.Stream(h,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,SHINE},{1,AMBER}},life={.25,.4},speed={-14,-8},spread=180},60)
 local embers=E.Stream(h,{tex="fire",size={{0,1.6},{1,.4}},alpha={{0,.3},{1,1}},color={{0,SHINE},{.5,GOLD},{1,AMBER}},life={.3,.5},speed={2,5},spread=40,
  dir=Enum.NormalId.Top},30)
 E.Light(g,h,GOLD,18,5,T+.1)
 E.Step(g,function(_,t)
  if blade.Parent then h.CFrame=blade.CFrame end
  if t>=T then motes.Enabled=false embers.Enabled=false end
  return t<T+.2
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end
 -- Fire Ring: the cut sweeps all the way round him in gold
function P.FireRingCut(E,d)
 local g=E.Group("P5FireRingCut")
 local R=d.Radius or 26
 local c=d.Pos
  -- the spin: one full turn of his blade around him at chest height, white and gold
 local spinR=math.clamp(R*.38,12,22)
 local sweep=arcSlash(E,g,CFrame.new(c+UP*3),spinR,0,math.pi*2,false)
 for _,b in ipairs(g.Folder:GetDescendants())do if b:IsA("Beam")then
  local col=b.Color.Keypoints[1].Value
  if col==CRIMSON then b.Color=ColorSequence.new(BUTTERFLY_GOLD,AMBER)
  elseif col==VOID then b.Color=ColorSequence.new(WHITE) b.LightEmission=1 b.Transparency=NumberSequence.new(.1)
  else b.Color=ColorSequence.new(WHITE)end
 end end
  -- the cut: a flat blade of light racing out from him across the floor to the ring's edge, where the fire catches
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=CFrame.new(c+UP*1.8)
 local N=E.Quality<.6 and 28 or 44
 local pts={}
 for i=1,N do local at=Instance.new("Attachment") at.Parent=carrier pts[i]=at end
 local bands={}
 local function band(w,color,alpha,emission,face)
  local list={}
  for i=1,N do
   local b=Instance.new("Beam")
   b.Attachment0=pts[i] b.Attachment1=pts[i%N+1]
   b.FaceCamera=face b.Segments=3 b.LightEmission=emission b.LightInfluence=0
   b.Color=ColorSequence.new(color) b.Transparency=NumberSequence.new(1)
   b.Width0=w b.Width1=w b.Parent=carrier
   list[i]=b
  end
  bands[#bands+1]={List=list,W=w,A=alpha}
 end
 band(10,AMBER,.3,1,false)  -- the glow, lying flat on the floor
 band(3.6,BUTTERFLY_GOLD,0,.8,false)
 band(1.3,WHITE,0,1,true)  -- the hot edge faces you, so it reads from any angle
 local a=E.Anchor(g,CFrame.new(c+UP*2))
 E.Emit(a,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,GOLD}},life={.4,.7},speed={R*1.2,R*2},spread=80,dir=Enum.NormalId.Top,drag=2},50)
 E.Sprite(a,{tex="flare.burst",size={{0,4},{.3,spinR*2.4},{1,spinR*2.8}},alpha={{0,0},{1,1}},color=SHINE},.3)
 E.Light(g,a,GOLD,math.min(R*2,80),8,.5)
 local flash=Instance.new("ColorCorrectionEffect")
 flash.Brightness=.12 flash.Contrast=.12 flash.TintColor=Color3.fromRGB(255,236,200) flash.Parent=game:GetService("Lighting")
 E.Tween(flash,.35,{Brightness=0,Contrast=0,TintColor=WHITE})
 task.delay(.4,function()flash:Destroy()end)
 local start,T=.08,.26
 E.After(g,start+T,function()
  for i=1,10 do  -- embers kicked up where the cut meets the ring
   local ang=i*math.pi*2/10+math.random()*.3
   local e=E.Anchor(g,CFrame.new(c+Vector3.new(math.cos(ang)*R,1.5,math.sin(ang)*R)))
   E.Emit(e,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.3,.6},speed={14,30},spread=60,dir=Enum.NormalId.Top,
    accel=Vector3.new(0,-40,0)},8)
  end
 end)
 E.Step(g,function(_,t)
  local k=math.clamp(t/.2,0,1)
  sweep(1-(1-k)^3,t<.3 and 0 or math.clamp((t-.3)/.25,0,1))
  local u=math.clamp((t-start)/T,0,1)
  local ease=1-(1-u)^2
  local r=spinR*.8+(R-spinR*.8)*ease
  local fade=t<start and 1 or math.clamp((t-start-T)/.35,0,1)
  for i,at in ipairs(pts)do
   local ang=(i-1)/N*math.pi*2
   local dir=Vector3.new(math.cos(ang),0,math.sin(ang))
   at.CFrame=CFrame.fromMatrix(dir*r,UP,dir)  -- the width lies along Y: radial, so the band lies flat
  end
  for _,b in ipairs(bands)do
   local w=b.W*(.7+.6*ease)*(1-fade*.5)
   local tr=NumberSequence.new(b.A+(1-b.A)*fade)
   for _,beam in ipairs(b.List)do beam.Width0=w beam.Width1=w beam.Transparency=tr end
  end
  return t<start+T+.4
 end)
 E.After(g,1.2,function()g:Destroy()end)
end
 -- Fire Ring: a ring of golden fire burning on the cut's edge
function P.FireRing(E,d)
 local g=E.Group("P5FireRing")
 local R,T,band=d.Radius or 26,d.Time or 6,d.Band or 5
 local floor=E.Ground(d.Pos+UP*3,{g.Folder})
 local c=(floor or d.Pos)
 local n=math.clamp(math.floor(2*math.pi*R/9),12,40)
 local outs={}
 for i=1,n do  -- tall flames standing on the burning band itself (Band either side of the ring), so what burns is what's lit
  local a=(i-1)*math.pi*2/n+math.random()*.06
  outs[#outs+1]=goldFire(g,c+Vector3.new(math.cos(a)*R,0,math.sin(a)*R),26+math.random()*7,band*2)
 end
 for i=1,6 do  -- a few lights around the ring, not one huge one in the middle
  local a=(i-1)*math.pi/3
  local l=E.Anchor(g,CFrame.new(c+Vector3.new(math.cos(a)*R,5,math.sin(a)*R)))
  E.Light(g,l,GOLD,36,3,T)
 end
 E.After(g,T,function()for _,f in ipairs(outs)do f()end end)
 E.After(g,T+1.5,function()g:Destroy()end)
end

 -- Shotgun Blast: a little white star glints in his eye before he fires
function P.EyeGlint(E,d)
 local head=d.Boss and d.Boss:FindFirstChild("Head")
 if not head then return end
 local T=d.Time or .55
 local g=E.Group("P5EyeGlint")
 local function at()return head.CFrame*CFrame.new(.22,.15,-head.Size.Z*.55)end
 local a=E.Anchor(g,at())
 E.Sprite(a,{tex="star.anime",size={{0,.1},{.25,1.8},{.6,1.2},{1,2.4}},alpha={{0,.2},{.8,0},{1,1}},color=WHITE,spin={0,0}},T)
 E.Sprite(a,{tex="star.glare",size={{0,.5},{.3,4},{1,1}},alpha={{0,.3},{1,1}},color=WHITE,rot={0,0}},T)
 E.Step(g,function(_,t)
  if head.Parent then a.CFrame=at()end
  return t<T
 end)
 E.After(g,T+.2,function()g:Destroy()end)
end
 -- Shotgun Blast: point blank - a flash at his palm, a cone of gold pellets streaking out to its range, shock rings
function P.ShotgunBlast(E,d)
 local g=E.Group("P5ShotgunBlast")
 local f=d.Frame
 local L=d.Range or 15
 local half=d.HalfAngle or 38
 local a=E.Anchor(g,f)
  -- the muzzle flash, then the blast itself: a cone of fire the full width of the hit, rolling into smoke at its end
 E.Sprite(a,{tex="flare.big",size={{0,4},{.12,24},{1,28}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.3)
 E.Sprite(a,{tex="flare.burst2",size={{0,3},{1,20}},alpha={{0,0},{1,1}},color=AMBER},.25)
 fireBlast(E,g,f,{Reach=L*1.1,Spread=half,Count=40,Size=L*.42,Width=1.4,Smoke=26,Embers=40})
 fireBlast(E,g,f,{Reach=L*.6,Spread=half*.5,Count=16,Size=L*.3,Width=.8,Smoke=0,Embers=0})
 for i=1,3 do  -- shock rings punched out ahead of it
  E.After(g,(i-1)*.04,function()
   local r=E.Anchor(g,f)
   E.Sprite(r,{tex="ring.crisp",orient="flat",dir=Enum.NormalId.Front,size={{0,2},{1,L*1.6}},alpha={{0,.2},{1,1}},color=SHINE,speed={L*3,L*3}},.25)
  end)
 end
 local heat=Instance.new("ColorCorrectionEffect")
 heat.Brightness=.12 heat.TintColor=Color3.fromRGB(255,225,190) heat.Parent=game:GetService("Lighting")
 E.Tween(heat,.35,{Brightness=0,TintColor=WHITE})
 task.delay(.4,function()heat:Destroy()end)
 E.Light(g,a,AMBER,34,10,.35)
 E.After(g,2.2,function()g:Destroy()end)
end

 -- Perfect Vertical Slash: perfectly still, the blade high - its glint grows and the air around him goes quiet
function P.VerticalStance(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 1.2
 local g=E.Group("P5VerticalStance")
 local blade=bladeOf(d.Boss)
 local h=E.Anchor(g,blade.CFrame)
 E.Sprite(h,{tex="star.glare",size={{0,1},{.9,12},{1,2}},alpha={{0,.4},{.9,0},{1,1}},color=WHITE,rot={90,90}},T)
 E.Sprite(h,{tex="glow.soft",size={{0,1},{.9,8},{1,10}},alpha={{0,.6},{.9,.25},{1,1}},color=GOLD},T)
 local motes=E.Stream(h,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.5},speed={-10,-6},spread=180},40)
 local floor=E.Ground(r.Position,{d.Boss,g.Folder})
 local a=E.Anchor(g,CFrame.new((floor or r.Position-UP*3)+UP*.1))
 E.Sprite(a,{tex="ring.hair",orient="flat",size={{0,20},{.5,9},{1,8}},alpha={{0,1},{.4,.3},{1,.1}},color=SHINE,spin={0,0}},T)
 E.Step(g,function(_,t)
  if blade.Parent then h.CFrame=blade.CFrame end
  if t>=T then motes.Enabled=false end
  return t<T+.2
 end)
 E.After(g,T+.4,function()g:Destroy()end)
end
 -- Perfect Vertical Slash: a towering vertical crescent races along the ground; golden flames burst up along its path
 -- behind it and burn for FlameTime
 -- Perfect Vertical Slash: the blade's own swing - a gold arc drawn in the lane's vertical plane, from over his head
 -- down to the ground in front of him
function P.VerticalSwing(E,d)
 local g=E.Group("P5VerticalSwing")
 local lane=d.Frame
 local F=lane.LookVector
 local U=Vector3.yAxis
 local pivot=CFrame.fromMatrix(lane.Position+U*5+F*1.5,F,U:Cross(F))  -- local X forward, local Z up: its XZ plane is vertical
 local sweep=goldArc(E,g,pivot,11,math.rad(150),math.rad(-215),1.2)
 local a=E.Anchor(g,lane*CFrame.new(0,1,-8))
 E.Sprite(a,{tex="flare.big",size={{0,3},{.15,26},{1,30}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.35)
 E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={20,45},spread=60,dir=Enum.NormalId.Top,drag=2},26)
 E.Step(g,function(_,t)
  local k=math.clamp(t/.1,0,1)
  sweep(1-(1-k)^3,t<.2 and 0 or math.clamp((t-.2)/.25,0,1))
  return t<.5
 end)
 E.After(g,.8,function()g:Destroy()end)
end
 -- Perfect Vertical Slash: the slash itself - a towering crescent of gold light standing upright in the lane, riding
 -- down it with a ribbon trail behind; it carves a glowing groove, and every Gap studs behind it flame bursts out in a
 -- ring and keeps burning for FlameTime
function P.VerticalSlash(E,d)
 local g=E.Group("P5VerticalSlash")
 local lane=d.Frame
 local L,speed,H=d.Range or 200,d.Speed or 560,d.Height or 60
 local T=L/speed
 local floor=E.Ground(lane.Position+UP*4,{d.Boss,g.Folder})
 local base=CFrame.new(Vector3.new(lane.X,floor and floor.Y or lane.Y,lane.Z))*lane.Rotation
  -- the crescent: points on an upright arc bulging forward, carried by one anchor that rides the lane
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=base
 local N=E.Quality<.6 and 20 or 32  -- a slash this tall needs the segments to keep its edge smooth
 local pts={}
 for i=0,N do
  local th=math.rad(-82+164*i/N)
  local at=Instance.new("Attachment")
  at.Position=Vector3.new(0,H*.5+math.sin(th)*H*.5,-math.cos(th)*H*.22)
  at.Parent=carrier
  pts[i+1]=at
 end
 local beams={}
 local function ribbon(w,color,alpha,emission)
  for i=1,N do
   local b=Instance.new("Beam")
   b.Attachment0=pts[i] b.Attachment1=pts[i+1]
   b.FaceCamera=true b.Segments=2 b.LightEmission=emission b.LightInfluence=0
   b.Color=ColorSequence.new(color) b.Transparency=NumberSequence.new(alpha)
   local m0,m1=math.sin(math.pi*(i-1)/N),math.sin(math.pi*i/N)  -- thickest in the middle, sharp at both tips
   b.Width0=math.max(.05,w*m0) b.Width1=math.max(.05,w*m1)
   b.Parent=carrier
   beams[#beams+1]={B=b,W0=b.Width0,W1=b.Width1}
  end
 end
 ribbon(H*.3,AMBER,.45,1)
 ribbon(H*.14,BUTTERFLY_GOLD,.05,.6)
 ribbon(H*.045,WHITE,0,1)
 local top,bottom=pts[N+1],pts[1]
 local trail=Instance.new("Trail")  -- at this speed the trail is the slash's afterimage, a sheet of light down the lane
 trail.Attachment0=bottom trail.Attachment1=top trail.Lifetime=.3 trail.LightEmission=1 trail.LightInfluence=0
 trail.Color=ColorSequence.new(SHINE,AMBER) trail.Transparency=NumberSequence.new(.2,1) trail.FaceCamera=false
 trail.Parent=carrier
 local foot=E.Attach(carrier,CFrame.new(0,.5,-H*.2))
 local sparks=E.Stream(foot,{tex="star.crisp",size={{0,1.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.6},speed={20,45},spread=60,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,-40,0)},120)
 local dust=E.Stream(foot,{tex="smoke",light=0,size={{0,3},{1,9}},alpha={{0,.5},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
  life={.5,.9},speed={8,16},spread=70,dir=Enum.NormalId.Top,drag=2},40)
 E.Light(g,carrier,GOLD,60,8,T+.3)
 local groove=newPart(g,Vector3.new(2.6,.08,.1),AMBER,.05)
 local grooveGlow=newPart(g,Vector3.new(10,.07,.1),GOLD,.5)
 local flash=Instance.new("ColorCorrectionEffect")
 flash.Brightness=.18 flash.Contrast=.15 flash.TintColor=Color3.fromRGB(255,240,205) flash.Parent=game:GetService("Lighting")
 E.Tween(flash,.4,{Brightness=0,Contrast=0,TintColor=WHITE})
 task.delay(.45,function()flash:Destroy()end)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local front=L*k
  local l=math.max(front,.1)
  groove.Size=Vector3.new(2.6,.08,l) grooveGlow.Size=Vector3.new(10,.07,l)
  local gcf=base*CFrame.new(0,.06,-l*.5)
  workspace:BulkMoveTo({carrier,groove,grooveGlow},{base*CFrame.new(0,0,-front),gcf,gcf},Enum.BulkMoveMode.FireCFrameChanged)
  if k>=1 then
   sparks.Enabled=false dust.Enabled=false
   local f=math.clamp((t-T)/.2,0,1)
   for _,b in ipairs(beams)do b.B.Width0=b.W0*(1-f) b.B.Width1=b.W1*(1-f) end
   if f>=1 then trail.Enabled=false return false end
  end
  return true
 end)
 E.Tween(groove,1,{Transparency=1},nil,nil,d.FlameTime or 5)
 E.Tween(grooveGlow,.8,{Transparency=1},nil,nil,d.FlameTime or 5)
 E.After(g,(d.FlameTime or 5)+2,function()g:Destroy()end)
end

 -- Perfect Vertical Slash: one of the columns of fire that erupt one after another down the slash's line (like Phase
 -- 4's Rift Column) - a flash dome, a pillar of flame shooting up and thinning, a pulse along the floor, fire thrown up
 -- - and then a circle of gold fire left burning where it stood, Radius across, for FlameTime
function P.VerticalBurst(E,d)
 local g=E.Group("P5VerticalBurst")
 local r,FT=d.Radius or 11,d.FlameTime or 5
 local floor=E.Ground(d.Pos+UP*6,{g.Folder})
 local c=floor or d.Pos
  -- the burst: a white dome of heat, a flash ring on the floor, and fire thrown up and out all round
 local dome=newPart(g,Vector3.new(r*.8,r*.4,r*.8),WHITE,.1) dome.Shape=Enum.PartType.Ball
 dome.CFrame=CFrame.new(c)
 E.Tween(dome,.3,{Size=Vector3.new(r*2.4,r*1.2,r*2.4),Transparency=1})
 local pulse=newPart(g,Vector3.new(.15,r*1.2,r*1.2),GOLD,.35) pulse.Shape=Enum.PartType.Cylinder
 pulse.CFrame=CFrame.new(c+UP*.12)*CFrame.Angles(0,0,math.pi/2)
 E.Tween(pulse,.35,{Size=Vector3.new(.15,r*2.6,r*2.6),Transparency=1})
 fireBlast(E,g,CFrame.lookAt(c+UP*.6,c+UP*10),{Reach=r*1.5,Spread=22,Count=26,Size=r*1.1,Width=r*1.2,Smoke=10,Embers=26})
 local spokes=E.Quality<.6 and 4 or 6
 for i=1,spokes do
  local ang=i*math.pi*2/spokes+math.random()*.4
  local dir=Vector3.new(math.cos(ang),.18,math.sin(ang))
  fireBlast(E,g,CFrame.lookAt(c+UP,c+UP+dir),{Reach=r*.75,Spread=24,Count=9,Size=r*.62,Width=1.5,Smoke=0,Embers=0})
 end
 local a=E.Anchor(g,CFrame.new(c+UP*3))
 E.Sprite(a,{tex="flare.burst",size={{0,3},{1,r*3.4}},alpha={{0,0},{1,1}},color=SHINE},.25)
 E.Light(g,a,GOLD,r*5,9,.5)
  -- the circle that keeps burning: a big flame in the middle and a ring of them out to the edge
 local outs={goldFire(g,c,14,r*.8)}
 local n=E.Quality<.6 and 4 or 6
 for i=1,n do
  local ang=i*math.pi*2/n+math.random()*.3
  outs[#outs+1]=goldFire(g,c+Vector3.new(math.cos(ang)*r*.68,0,math.sin(ang)*r*.68),9+math.random()*3,r*.5)
 end
 E.After(g,FT,function()for _,f in ipairs(outs)do f()end end)
 E.After(g,FT+1.6,function()g:Destroy()end)
end

 -- Golden Eternity: golden knives thrown into stopped time hang where they stopped, all pointing at the player - a
 -- ring around them, a dome overhead, or a wall - each landing with a glint; KnifeWave sends one formation in
local knifeSets={}
 -- a throwing knife pointing down -Z: a bright blade with a wedge point, a gold guard and an amber grip (`scale` x)
local function knife(g,at,target,scale)
 local s=scale or 1
 local blade=newPart(g,Vector3.new(.1,.5,2.4)*s,SHINE,0)
 local tip=Instance.new("WedgePart")
 tip.Anchored=true tip.CanCollide=false tip.CanQuery=false tip.CanTouch=false tip.CastShadow=false
 tip.Size=Vector3.new(.1,.5,.9)*s tip.Color=SHINE tip.Material=NEON tip.CFrame=HIDDEN tip.Parent=g.Folder
 local guard=newPart(g,Vector3.new(.16,1.15,.22)*s,GOLD,0)
 local grip=newPart(g,Vector3.new(.15,.24,1.1)*s,AMBER,0)
 local cf=CFrame.lookAt(at,target)
 return {Parts={blade,tip,guard,grip},Offsets={CFrame.new(0,0,-1.2*s),CFrame.new(0,0,-2.85*s),CFrame.new(),CFrame.new(0,0,.66*s)},
  From=at,Target=target,CF=cf,S=s}
end
local function placeKnife(k,cf)
 local parts,cfs={},{}
 for i,p in ipairs(k.Parts)do parts[i]=p cfs[i]=cf*k.Offsets[i]end
 workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
end
function P.KnifeSet(E,d)
 local g=E.Group("P5KnifeSet")
 local rng=Random.new(d.Seed or 1)
 local c=d.Pos+UP*.8
 local n,R=d.Count or 10,d.Radius or 9
 local spots={}
 if d.Kind=="Ring"then
  local spin=rng:NextNumber(0,math.pi*2)
  for i=1,n do local a=spin+i*math.pi*2/n spots[i]=c+Vector3.new(math.cos(a)*R,rng:NextNumber(-.5,.8),math.sin(a)*R)end
 elseif d.Kind=="Dome"then
  for i=1,n do
   local a=i*2.39996
   local el=math.rad(35+(i%3)*14)
   spots[i]=c+Vector3.new(math.cos(a)*math.cos(el)*R,math.sin(el)*R+2,math.sin(a)*math.cos(el)*R)
  end
 else  -- a wall: a 3-wide grid standing between him and them
  local from=d.From or c+Vector3.zAxis*R
  local back=Vector3.new(from.X-c.X,0,from.Z-c.Z)
  back=back.Magnitude>.1 and back.Unit or Vector3.zAxis
  local side=back:Cross(UP).Unit
  local cols=math.max(1,math.floor(math.sqrt(n)+.5))
  for i=1,n do
   local col,row=(i-1)%cols,math.floor((i-1)/cols)
   spots[i]=c+back*R+side*((col-(cols-1)/2)*3.2)+UP*(row*2.6-1.2)
  end
 end
 local set={G=g,Knives={},Target=c}
 for i,at in ipairs(spots)do
  local k=knife(g,at,c,1.3)
  placeKnife(k,k.CF)
  set.Knives[i]=k
  E.After(g,(i-1)*.01,function()
   local a=E.Anchor(g,CFrame.new(at))
   E.Emit(a,{tex="star.crisp",size={{0,.7},{1,0}},color={{0,WHITE},{1,GOLD}},life={.2,.35},speed={6,12},spread=180,drag=2},3)
  end)
 end
 knifeSets[#knifeSets+1]={Wave=d.Wave or 1,Set=set}
 E.After(g,12,function()g:Destroy()end)
end
function P.KnifeWave(E,d)
 local T=d.Time or .18
 local keep={}
 for _,entry in ipairs(knifeSets)do
  if entry.Wave~=d.Wave then
   keep[#keep+1]=entry
  else
   local set=entry.Set
   local g=set.G
   if g.Alive then
    for _,k in ipairs(set.Knives)do
     local a0=E.Attach(k.Parts[1],CFrame.new(0,0,1.2*k.S))
     local a1=E.Attach(k.Parts[1],CFrame.new(0,0,-1.2*k.S))
     local tr=Instance.new("Trail")tr.Attachment0=a0 tr.Attachment1=a1 tr.Lifetime=.15 tr.LightEmission=1 tr.LightInfluence=0
     tr.Color=ColorSequence.new(SHINE,GOLD)tr.Transparency=NumberSequence.new(.2,1)tr.FaceCamera=true tr.Parent=k.Parts[1]
    end
    E.Step(g,function(_,t)
     local k01=math.clamp(t/T,0,1)
     for _,k in ipairs(set.Knives)do placeKnife(k,k.CF+(set.Target-k.From)*(k01*k01))end
     if k01>=1 then
      for _,k in ipairs(set.Knives)do for _,p in ipairs(k.Parts)do p.Transparency=1 end end
      local a=E.Anchor(g,CFrame.new(set.Target))
      E.Sprite(a,{tex="flare.big",size={{0,3},{.15,20},{1,24}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.3)
      E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={20,45},spread=180,drag=2},26)
      E.Light(g,a,GOLD,24,8,.3)
      E.After(g,.8,function()g:Destroy()end)
      return false
     end
     return true
    end)
   end
  end
 end
 knifeSets=keep
end

 -- Golden Eternity: the map ring - while time is stopped a gold spark races once round the whole arena and knives
 -- are left hanging behind it, three tiers high, every one turned on a frozen player; they are split into Volleys
 -- sectors in the order they appeared, which KnifeVolley sends in one at a time
local fieldSets={}
function P.KnifeField(E,d)
 local g=E.Group("P5KnifeField")
 local rng=Random.new(d.Seed or 1)
 local n,V=d.Count or 190,d.Volleys or 6
 local c,hx,hz=d.Center,d.HX or 150,d.HZ or 110
 local targets=d.Targets or{}
 local sweep,start=d.Sweep or 2,d.Start or 0
 local specs,vols={},{}
 for v=1,V do vols[v]={}end
 for i=1,n do
  local u=(i-1)/n
  local a=start+u*math.pi*2+rng:NextNumber(-.02,.02)
  local s=rng:NextNumber(.9,1.03)
  local h=4+(i%3)*9+rng:NextNumber(0,7)
  local ti=(i-1)%math.max(#targets,1)+1
  specs[i]={At=c+Vector3.new(math.cos(a)*hx*s,h,math.sin(a)*hz*s),Target=(targets[ti]or c)+UP*rng:NextNumber(-1,1.5),T=ti,
   Show=u*sweep,V=math.min(V,math.floor(u*V)+1)}
 end
 local set={G=g,Vols=vols,All={}}
 fieldSets[#fieldSets+1]=set
 local front=E.Anchor(g,CFrame.new(c))
 local spark=E.Stream(front,{tex="star.crisp",size={{0,2.2},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={4,14},spread=180,drag=2},120)
 E.Sprite(front,{tex="flare.big",size=16,alpha=.25,color=SHINE},sweep)
 E.Light(g,front,GOLD,40,6,sweep)
 local shown=0
 E.Step(g,function(_,t)
  while shown<n and specs[shown+1].Show<=t do  -- made as they appear, so they never all spawn on one frame
   shown+=1
   local sp=specs[shown]
   local k=knife(g,sp.At,sp.Target,2)
   k.T=sp.T
   placeKnife(k,k.CF)
   local list=vols[sp.V]
   list[#list+1]=k
   set.All[shown]=k  -- by index, so KnifeThrow can send them off one at a time
  end
  local a=start+math.min(t/sweep,1)*math.pi*2
  front.CFrame=CFrame.new(c+Vector3.new(math.cos(a)*hx,14,math.sin(a)*hz))
  if t>=sweep then spark.Enabled=false end
  return shown<n or t<sweep+.1
 end)
 E.After(g,30,function()g:Destroy()end)  -- long enough for every knife to be thrown one by one
end
 -- Golden Eternity: one sector of the ring flies in - every knife swings onto where its player is now (Aims) and
 -- they all land together Time later, short of the mark so they stand bristling round it, then fade
function P.KnifeVolley(E,d)
 local set=fieldSets[#fieldSets]
 if not set or not set.G.Alive then return end
 local list=set.Vols[d.Volley or 1]or{}
 if #list==0 then return end
 local g=E.Group("P5KnifeVolley")
 local T=d.Time or .45
 local aims=d.Aims or{}
 local landed={}
 for _,k in ipairs(list)do
  local aim=aims[k.T]or k.Target
  local to=aim+Vector3.new(math.random()-.5,math.random()*.8-.3,math.random()-.5)*3
  local from=k.CF.Position
  local dist=(to-from).Magnitude
  k.Fly={From=from,Dir=(to-from).Unit,Len=math.max(dist-(.6+math.random()*2.2),0)}
  landed[aim]=true
  local a0=E.Attach(k.Parts[1],CFrame.new(0,0,1.2*k.S))
  local a1=E.Attach(k.Parts[1],CFrame.new(0,0,-1.2*k.S))
  local tr=Instance.new("Trail")tr.Attachment0=a0 tr.Attachment1=a1 tr.Lifetime=.14 tr.LightEmission=1 tr.LightInfluence=0
  tr.Color=ColorSequence.new(SHINE,GOLD)tr.Transparency=NumberSequence.new(.15,1)tr.FaceCamera=true tr.Parent=k.Parts[1]
  placeKnife(k,CFrame.lookAt(from,from+k.Fly.Dir))  -- the swing onto the new mark
 end
 local done=false
 E.Step(g,function(_,t)
  if not set.G.Alive then return false end
  local u=math.clamp(t/T,0,1)
  local e=u*u
  for _,k in ipairs(list)do
   local f=k.Fly
   local p=f.From+f.Dir*f.Len*e
   placeKnife(k,CFrame.lookAt(p,p+f.Dir))
  end
  if u>=1 and not done then
   done=true
   for aim in pairs(landed)do
    local a=E.Anchor(g,CFrame.new(aim))
    E.Sprite(a,{tex="flare.big",size={{0,3},{.15,18},{1,22}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.3)
    E.Sprite(a,{tex="burst.spiky",size={{0,4},{1,20}},alpha={{0,.1},{1,1}},color=GOLD,rot={0,360}},.3)
    E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={25,50},spread=180,drag=2},28)
    E.Light(g,a,GOLD,28,8,.35)
   end
   for _,k in ipairs(list)do
    for _,p in ipairs(k.Parts)do E.Tween(p,.4,{Transparency=1},nil,nil,.7)end
   end
   E.After(g,1.3,function()
    for _,k in ipairs(list)do for _,p in ipairs(k.Parts)do p.CFrame=HIDDEN end end
    g:Destroy()
   end)
   return false
  end
  return true
 end)
end

 -- Golden Eternity: ONE knife of the ring leaves on its own - it swings onto its mark (Aim) and flies in Time seconds
 -- (the server rolls a fast or a slow flight for each), then bursts and fades. One shared stepper moves them all.
function P.KnifeThrow(E,d)
 local set=fieldSets[#fieldSets]
 if not set or not set.G.Alive then return end
 local k=set.All and set.All[d.Index]
 if not k or k.Thrown then return end
 k.Thrown=true
 local T=math.max(d.Time or .6,.1)
 local aim=d.Aim or k.Target
 if not aim then return end
 local to=aim+Vector3.new(math.random()-.5,math.random()*.8-.3,math.random()-.5)*3
 local from=k.CF.Position
 local dist=(to-from).Magnitude
 if dist<1 then return end
 local dir=(to-from).Unit
 local a0=E.Attach(k.Parts[1],CFrame.new(0,0,1.2*k.S))
 local a1=E.Attach(k.Parts[1],CFrame.new(0,0,-1.2*k.S))
 local tr=Instance.new("Trail")tr.Attachment0=a0 tr.Attachment1=a1 tr.Lifetime=.14 tr.LightEmission=1 tr.LightInfluence=0
 tr.Color=ColorSequence.new(SHINE,GOLD)tr.Transparency=NumberSequence.new(.15,1)tr.FaceCamera=true tr.Parent=k.Parts[1]
 placeKnife(k,CFrame.lookAt(from,from+dir))
 set.Flying=set.Flying or{}
 set.Flying[#set.Flying+1]={K=k,From=from,Dir=dir,Len=dist,T=T,Start=os.clock(),To=to,V=math.max(2*dist/T,60)}
 if not set.Stepper then
  set.Stepper=true
  E.Step(set.G,function()
   if not set.G.Alive then return false end
   local now=os.clock()
   local list=set.Flying
   for i=#list,1,-1 do
    local f=list[i]
    local el=now-f.Start
    local u=math.clamp(el/f.T,0,1)
    local p
    local landed
    if el<f.T then
     p=f.From+f.Dir*f.Len*(u*u)
    else
     local prev=f.P or f.To
     p=f.To+f.Dir*f.V*(el-f.T)
     if not f.RP then
      f.RP=RaycastParams.new() f.RP.FilterType=Enum.RaycastFilterType.Exclude f.RP.RespectCanCollide=true
      local ex={set.G.Folder}
      for _,pl in ipairs(game:GetService("Players"):GetPlayers())do if pl.Character then ex[#ex+1]=pl.Character end end
      local boss=workspace:FindFirstChild("alterGolden, the Nothing") if boss then ex[#ex+1]=boss end
      f.RP.FilterDescendantsInstances=ex
     end
     local r=workspace:Raycast(prev,p-prev,f.RP)
     if r then p=r.Position landed=true elseif (p-f.To).Magnitude>700 then landed=true end
     f.P=p
    end
    placeKnife(f.K,CFrame.lookAt(p,p+f.Dir))
    if landed then
     table.remove(list,i)
     local a=E.Anchor(set.G,CFrame.new(p))
     E.Sprite(a,{tex="flare.big",size={{0,2},{.15,9},{1,11}},alpha={{0,.1},{.5,.4},{1,1}},color=SHINE},.22)
     E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,GOLD}},life={.25,.5},speed={14,30},spread=180,drag=2},6)
     for _,part in ipairs(f.K.Parts)do E.Tween(part,.35,{Transparency=1},nil,nil,.6)end
    end
   end
   return true
  end)
 end
end

return P
