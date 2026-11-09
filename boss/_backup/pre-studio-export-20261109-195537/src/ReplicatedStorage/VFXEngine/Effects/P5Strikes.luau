--[[
 P5Strikes (client effect) - the Phase 5 normal attacks (Attacks/P5/NormalAttack) and the mode switch.
 Slashes are layered slash meshes cloned from VFXEngine.Assets (ArcSlash, StreakSlash): a bright core,
 a coloured glow copy behind it and a streak swirl, swept and scaled per frame, with Library sprites on
 top (claw.lines, claw.marks, wind.dash, butterfly). The butterfly wings are the MonarchWings mesh.
   Mode           {Boss, Mode}                                    a burst in the new mode's colours
   Blink          {From, To, Dark}                                a teleport: smoke where he was, a flash where he lands
   ClawTell       {Boss, Time}                                    a glint on the blade before the claws
   Claw           {Frame, Roll, Speed, Range, Width, Spread}      three parallel claw slashes flying out
   ClawHit        {Pos}                                           claw marks flash on whoever was hit
   AssassinTell   {Boss, Time, Victim}                            a dark aura on him, a red mark over the victim
   BlackSlash     {Frame, Index, Radius, Fake}                    a black crescent cut that hangs, then bursts
   UpperTell      {Boss, Pos, Time}                               the blade glints and wind gathers at the strike point
   UpperSlash     {Frame, Pos, Height}                            a vertical slash sweeping up from the ground
   Wings          {Boss, Time}                                    monarch wings open on his back, butterflies shed
   ButterflyDash  {From, To, Time}                                the dive's streak and butterflies
   ButterflyBurst {Pos, Radius}                                   wings of light flare open on landing
   PierceBeam     {Origin, Dir, Range, Time, Width}               Golden Pierce's laser beam
   HuntSlice      {Frame, Index}                                  a Wild Hunt air slice: a crescent across his front
   Shockwave      {Pos, Speed, Range, Look}                       a ring racing out along the floor
   SlamRaise / SlamImpact                                         Slam: gold gathers in the raised left hand; the impact
   ViperSpread / ViperThrust / ViperCatch / ViperBite             Viper: the hood, the snake strike, the drag, the fangs
   StabTell / GroundStab                                          Horrifying Ground: the raised blade; the stab
   TearerReady / TearerCharge / TearerBeam                        Night Tearer: the aura, the charge and red lane, the beam
   EternityTell / FrozenBlades / BladesRelease                    Golden Eternity: the sky clock, blades in stopped time, release
   Overclock / SlowClock                                          Overclock: his spinning clock hands; the slow clock under a player
   Warn           {Victim, Kind, Time, Lives}                     over a player: red LETHAL (lives) or gold JUMP
   CageWarn / SpikeCage                                           Horrifying Ground: the ring, the cage of unique spikes
   ViperTell      {From, To, Width, Time}                         the lane Viper will strike down
 The spikes themselves are VFXEngine.Effects.GroundShatter (Tall/Count).
 The server keeps every hit volume; this only draws.
]]
local P={}
local Players=game:GetService("Players")
local ASSETS=script.Parent.Parent:WaitForChild("Assets")
local WHITE=Color3.new(1,1,1)
local GOLD=Color3.fromRGB(255,208,111)
local SHINE=Color3.fromRGB(255,246,214)
local VIOLET=Color3.fromRGB(174,114,255)
local PINK=Color3.fromRGB(255,106,199)
local BLUE=Color3.fromRGB(98,195,255)
local MINT=Color3.fromRGB(115,255,205)
local VOID=Color3.fromRGB(14,6,24)
local CRIMSON=Color3.fromRGB(255,40,86)
local AMBER=Color3.fromRGB(255,146,36)  -- reads against the gold field where plain gold would not
local NEON=Enum.Material.Neon
local UP=Vector3.yAxis
local HIDDEN=CFrame.new(0,-1e4,0)
local MODE_COLORS={Space={VIOLET,BLUE},Natural={MINT,BLUE},Time={GOLD,SHINE}}

local function newPart(g,size,color,alpha)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Size=size p.Color=color p.Material=NEON p.Transparency=alpha or 0
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.CFrame=HIDDEN p.Parent=g.Folder
 return p
end

 -- a clone of a mesh template, `width` studs along its X axis (proportions kept); untextured clones glow
local function mesh(g,name,width,color,alpha,keepTexture)
 local template=ASSETS[name]
 local p=template:Clone()
 p.Size=template.Size*(width/template.Size.X)
 p.Color=color p.Transparency=alpha or 0
 if not keepTexture then p.TextureID="" p.Material=NEON end
 p.CFrame=HIDDEN p.Parent=g.Folder
 return p
end

 -- a layered slash in its local XY plane (bulging toward +Y): a bright core, a wider glow just behind
 -- it and, optionally, a swirl of streaks
local function slash(g,width,core,glow,o)
 o=o or{}
 local layers={
  {Part=mesh(g,"ArcSlash",width,core,o.CoreAlpha or .05),Offset=CFrame.new()},
  {Part=mesh(g,"ArcSlash",width*1.14,glow,o.GlowAlpha or .45),Offset=CFrame.new(0,-width*.02,.2)},
 }
 if o.Streak then
  layers[#layers+1]={Part=mesh(g,"StreakSlash",width*(o.StreakScale or 1.25),o.StreakColor or glow,o.StreakAlpha or .35),
   Offset=CFrame.new(0,0,.4)*CFrame.Angles(math.pi/2,0,0)}
 end
 for _,l in ipairs(layers)do l.Base=l.Part.Size l.Alpha=l.Part.Transparency end
 return layers
end

 -- place a layered slash at `frame`; `scale` resizes it and `fade` (0..1) rewrites transparency when given
local function place(layers,frame,scale,fade,parts,cfs)
 for _,l in ipairs(layers)do
  if scale then l.Part.Size=l.Base*scale end
  if fade then l.Part.Transparency=l.Alpha+(1-l.Alpha)*fade end
  parts[#parts+1]=l.Part
  cfs[#cfs+1]=frame*l.Offset
 end
end

local function rootOf(model)return model and model:FindFirstChild("HumanoidRootPart")end
local function bladeOf(boss)
 local sword=boss and boss:FindFirstChild("Basic Sword")
 local blade=sword and(sword:FindFirstChild("Blade")or sword:FindFirstChild("Handle"))
 if blade and blade:IsA("BasePart")then return blade end
 return boss and(boss:FindFirstChild("Right Arm")or boss:FindFirstChild("RightHand"))or rootOf(boss)
end
local function flatLook(cf)
 local look=cf.LookVector*Vector3.new(1,0,1)
 return look.Magnitude>.1 and look.Unit or Vector3.zAxis
end

 -- butterflies: the white butterfly sprite, tinted, its width squashed back and forth so it flaps
local FLAP={{0,0},{.08,.75},{.16,0},{.24,.75},{.32,0},{.4,.75},{.48,0},{.56,.75},{.64,0},{.72,.75},{.8,0},{.88,.75},{1,0}}
local BUTTERFLY_GOLD=Color3.fromRGB(255,214,60)
local function butterflies(size,speed,life)
 return {tex="butterfly",size={{0,size},{.8,size},{1,0}},squash=FLAP,color={{0,SHINE},{.5,BUTTERFLY_GOLD},{1,AMBER}},light=.6,
  alpha={{0,0},{.75,0},{1,1}},life=life or{.9,1.5},speed=speed or{3,8},spread=180,drag=1.2,rot={0,360},spin={-60,60},
  accel=Vector3.new(0,2,0)}
end

local function handOf(boss,side)
 return boss and(boss:FindFirstChild(side.."Hand")or boss:FindFirstChild(side.." Arm"))
end
local function handCF(hand)return hand.CFrame*CFrame.new(0,-hand.Size.Y*.45,0)end

 -- glowing cracks running out from `c` along the floor
local function cracks(E,g,c,R,n,color,life)
 local floor=E.Ground(c+UP*3,{g.Folder})
 local at=(floor or c)+UP*.08
 for i=1,n do
  local a=(i-1)*math.pi*2/n+math.random()*.5
  local len=R*(.55+math.random()*.7)
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local cf=CFrame.lookAt(at+dir*len/2,at+dir*len)
  local p=newPart(g,Vector3.new(.3+math.random()*.35,.06,len),color,.05)
  local q=newPart(g,Vector3.new(1.6,.05,len),GOLD,.6)
  p.CFrame=cf q.CFrame=cf
  E.Tween(p,life*.5,{Transparency=1},nil,nil,life*.5)
  E.Tween(q,life*.4,{Transparency=1},nil,nil,life*.3)
 end
end

 -- chunks of rock flung up out of an impact, falling back on arcs
local function debris(E,g,c,n)
 local rocks={}
 for i=1,n do
  local p=newPart(g,Vector3.one*(.6+math.random()*1.4),Color3.fromRGB(150,112,48),0)
  p.Material=Enum.Material.Slate
  local a=math.random()*math.pi*2
  local out=8+math.random()*16
  rocks[i]={P=p,V=Vector3.new(math.cos(a)*out,26+math.random()*24,math.sin(a)*out),R=CFrame.Angles(math.random()*6,math.random()*6,0)}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,r in ipairs(rocks)do
   parts[#parts+1]=r.P cfs[#cfs+1]=CFrame.new(c+r.V*t+Vector3.new(0,-35*t*t,0))*r.R*CFrame.Angles(t*5,t*3,0)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>1.2 then for _,r in ipairs(rocks)do r.P.Transparency=1 end return false end
  return true
 end)
end

 -- two crescent jaws in the vertical plane of `frame`, snapping shut on its middle
local function jaws(E,g,frame,width,glowColor,gap)
 local upper=slash(g,width,WHITE,glowColor,{GlowAlpha=.3,Streak=true,StreakColor=AMBER,StreakAlpha=.6})
 local lower=slash(g,width,WHITE,glowColor,{GlowAlpha=.3})
 local snapped=false
 E.Step(g,function(_,t)
  local k=math.clamp(t/.11,0,1)
  local shut=k*k
  local fade=t<.18 and 0 or math.clamp((t-.22)/.2,0,1)
  local parts,cfs={},{}
  place(upper,frame*CFrame.new(0,gap*(1-shut)+.6,0),1,fade,parts,cfs)
  place(lower,frame*CFrame.new(0,-gap*(1-shut)-.6,0)*CFrame.Angles(0,0,math.pi),1,fade,parts,cfs)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if not snapped and k>=1 then
   snapped=true
   local a=E.Anchor(g,frame)
   E.Sprite(a,{tex="flare.burst",size={{0,3},{1,width}},alpha={{0,0},{1,1}},color=SHINE},.22)
   E.Sprite(a,{tex="ring.crisp",orient="flat",dir=Enum.NormalId.Front,size={{0,2},{1,width*1.4}},alpha={{0,.1},{1,1}},color=glowColor},.3)
   E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.25,.5},speed={24,55},spread=180,drag=2.5},30)
   E.Light(g,a,glowColor,width*1.6,8,.35)
  end
  return t<.5
 end)
end

function P.Mode(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local c=MODE_COLORS[d.Mode]or MODE_COLORS.Space
 local g=E.Group("P5Mode")
 local a=E.Anchor(g,r.CFrame)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.2,26},{1,30}},alpha={{0,0},{.5,.4},{1,1}},color=c[2]},.6)
 E.Sprite(a,{tex="glow.rays",size={{0,6},{1,34}},alpha={{0,.2},{1,1}},color=c[1],spin={-40,40}},.9)
 E.Emit(a,{tex=d.Mode=="Time"and"star.crisp"or"star.twinkle",size={{0,1.2},{1,0}},color={{0,SHINE},{1,c[1]}},
  life={.6,1.2},speed={18,40},spread=180,drag=2},40)
 E.Light(g,a,c[1],40,8,.8)
 E.After(g,1.5,function()g:Destroy()end)
end

function P.Blink(E,d)
 local g=E.Group("P5Blink")
 local tone=d.Dark and VOID or VIOLET
 local edge=d.Dark and CRIMSON or PINK
 local a=E.Anchor(g,CFrame.new(d.From))
 local b=E.Anchor(g,CFrame.new(d.To))
 E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,5}},alpha={{0,.35},{1,1}},color={{0,tone},{1,VOID}},life={.4,.7},speed={3,8},spread=180,drag=3},10)
 E.Emit(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,edge}},life={.3,.5},speed={10,22},spread=180,drag=2},12)
 E.Sprite(b,{tex="flare.burst",size={{0,2},{.3,9},{1,11}},alpha={{0,0},{1,1}},color=edge},.3)
 E.Emit(b,{tex="smoke",light=0,size={{0,1.5},{1,4}},alpha={{0,.4},{1,1}},color={{0,tone},{1,VOID}},life={.3,.6},speed={4,9},spread=180,drag=3},8)
 local len=(d.To-d.From).Magnitude
 if len>2 then  -- a streak along the jump that thins out
  local s=newPart(g,Vector3.new(.35,.35,len),edge,.25)
  s.CFrame=CFrame.lookAt((d.From+d.To)/2,d.To)
  E.Tween(s,.25,{Size=Vector3.new(.05,.05,len),Transparency=1})
 end
 E.After(g,1,function()g:Destroy()end)
end

function P.ClawTell(E,d)
 local blade=bladeOf(d.Boss)
 if not blade then return end
 local T=d.Time or .35
 local big=d.Final and 2 or 1  -- the finisher's wind-up glows bigger, with gold gathering into the hand
 local g=E.Group("P5ClawTell")
 local a=E.Anchor(g,blade.CFrame)
 E.Sprite(a,{tex="star.glare",size={{0,1},{.6,8*big},{1,2}},alpha={{0,.2},{.7,0},{1,1}},color=SHINE,rot={-20,20}},T)
 E.Stream(a,{tex="star.tiny",size={{0,.5*big},{1,0}},color={{0,SHINE},{1,GOLD}},life={.2,.35},speed={-10*big,-6*big},spread=180},40*big)
 if d.Final then E.Light(g,a,GOLD,22,5,T)end
 E.Step(g,function()if blade.Parent then a.CFrame=blade.CFrame end return true end)
 E.After(g,T+.1,function()g:Destroy()end)
end

 -- one claw blade: a curve in its local XZ plane, bulging toward -Z with the tips trailing behind,
 -- drawn with camera-facing beams (like the P4 ranged slash wave) so it reads from every side
local function clawBlade(E,g,width,depth,tone)
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 local N=E.Quality<.6 and 8 or 12
 local points,beams={},{}
 for i=0,N do
  local at=Instance.new("Attachment")
  at.Parent=carrier
  points[i+1]=at
 end
 local function shape(scale)
  for i,at in ipairs(points)do
   local t=(i-1)/N
   local s=math.sin(math.pi*t)
   at.Position=Vector3.new((t-.5)*width*scale,0,depth*scale*(1-s)^1.2)
  end
 end
 shape(1)
 local function ribbon(w,color,alpha,emission)
  for i=1,N do
   local beam=Instance.new("Beam")
   beam.Attachment0=points[i] beam.Attachment1=points[i+1]
   beam.Width0=math.max(.08,w*math.sin(math.pi*(i-1)/N)^.6)
   beam.Width1=math.max(.08,w*math.sin(math.pi*i/N)^.6)
   beam.FaceCamera=true beam.Segments=1 beam.LightEmission=emission beam.LightInfluence=0
   beam.Color=ColorSequence.new(color) beam.Transparency=NumberSequence.new(alpha)
   beam.Parent=carrier
   beams[#beams+1]=beam
  end
 end
 ribbon(width*.2,tone,.5,.85)  -- the glow
 ribbon(width*.08,SHINE:Lerp(BUTTERFLY_GOLD,.4),.1,1)
 ribbon(width*.03,WHITE,0,1)  -- the hot core line
  -- a motion-blur sheet from tip to tip
 local trail=Instance.new("Trail")
 trail.Attachment0=points[1] trail.Attachment1=points[N+1]
 trail.FaceCamera=false trail.MinLength=.05 trail.LightEmission=.9 trail.LightInfluence=0
 trail.Texture=E.Lib.Id("slash.streak")trail.TextureMode=Enum.TextureMode.Stretch
 trail.Color=ColorSequence.new(SHINE,tone)
 trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(.6,.75),NumberSequenceKeypoint.new(1,1)})
 trail.Parent=carrier
 return {Carrier=carrier,Beams=beams,Trail=trail,Shape=shape}
end

function P.Claw(E,d)
 local g=E.Group("P5Claw")
 local frame=d.Frame
 local speed,range=d.Speed or 300,d.Range or 210
 local W,spread=d.Width or 30,d.Spread or 6
 local look=frame.LookVector
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local ignore={g.Folder,d.Boss}
 for _,pl in ipairs(Players:GetPlayers())do if pl.Character then ignore[#ignore+1]=pl.Character end end
 params.FilterDescendantsInstances=ignore
 local wall=workspace:Raycast(frame.Position,look*range,params)
 local reach=wall and wall.Distance or range
 local life=reach/speed
 local floor=E.Ground(frame.Position+UP,ignore)
 local floorY=floor and floor.Y or frame.Y-3.5
  -- claw blades side by side (three, five for the finisher), rolled together into one diagonal swipe;
  -- each carves a groove
 local roll=CFrame.Angles(0,0,d.Roll or 0)
 local count=d.Count or 3
 local claws={}
 for i=1,count do
  local k=i-(count+1)/2
  local tone=k==0 and AMBER or BUTTERFLY_GOLD
  local c=clawBlade(E,g,W*(1-math.abs(k)*.08),W*.22,tone)
  c.Trail.Lifetime=math.clamp(36/speed,.08,1)  -- about 36 studs of streak at any speed
  c.Offset=roll*CFrame.new(0,k*spread,0)
  c.Lateral=c.Offset.Position.X  -- where this blade sits across the flight, for its groove
  c.GrooveWidth=d.Final and 1.1 or .45
  c.Groove=newPart(g,Vector3.new(c.GrooveWidth,.06,.1),AMBER,.15)
  c.GrooveGlow=newPart(g,Vector3.new(c.GrooveWidth*3.5,.05,.1),tone,.7)
  claws[#claws+1]=c
 end
 local base=E.Anchor(g,frame)
 local kick=E.Stream(base,{tex="star.tiny",size={{0,.8},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.55},speed={6,14},
  spread=40,dir=Enum.NormalId.Top,accel=Vector3.new(0,-20,0),drag=1.5},80)
 local wind=E.Stream(base,{tex="wind.dash",orient="velocity",size={{0,4},{1,8}},alpha={{0,.55},{1,1}},color=SHINE,
  life={.12,.2},speed={40,70},dir=Enum.NormalId.Back,spread=6},30)
 local launch=E.Anchor(g,frame)
 E.Sprite(launch,{tex="flare.burst",size={{0,3},{1,W*.6}},alpha={{0,.1},{1,1}},color=SHINE},.18)
 if d.Final then
  E.Sprite(launch,{tex="flare.big",size={{0,6},{.2,W*.5},{1,W*.6}},alpha={{0,0},{.5,.3},{1,1}},color=GOLD},.35)
  E.Light(g,launch,GOLD,40,8,.4)
 end
 E.Emit(launch,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,AMBER}},life={.2,.4},speed={20,40},spread=50,dir=Enum.NormalId.Front,drag=2},12)
 local right=frame.RightVector
 local flat=Vector3.new(look.X,0,look.Z)
 flat=flat.Magnitude>.01 and flat.Unit or Vector3.zAxis
 local ended=false
 E.Step(g,function(_,t)
  if t<.1 then  -- the blades rip out to full size
   local grow=t/.1
   for _,c in ipairs(claws)do c.Shape(.45+.55*(1-(1-grow)^2))end
  end
  local travel=math.min(t*speed,reach)
  local at=frame+look*travel
  local parts,cfs={},{}
  for _,c in ipairs(claws)do
   parts[#parts+1]=c.Carrier cfs[#cfs+1]=at*c.Offset
   if not ended then  -- the groove runs from the swing to under the blade
    local from=Vector3.new(frame.X,floorY+.05,frame.Z)+right*c.Lateral
    local len=math.max(travel-1,.1)
    local mid=from+flat*(len*.5)
    local cf=CFrame.lookAt(mid,mid+flat)
    c.Groove.Size=Vector3.new(c.GrooveWidth,.06,len) c.GrooveGlow.Size=Vector3.new(c.GrooveWidth*3.5,.05,len)
    parts[#parts+1]=c.Groove cfs[#cfs+1]=cf
    parts[#parts+1]=c.GrooveGlow cfs[#cfs+1]=cf
   end
  end
  parts[#parts+1]=base cfs[#cfs+1]=CFrame.new(Vector3.new(at.X,floorY+.3,at.Z))*frame.Rotation
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=life and not ended then
   ended=true
   kick.Enabled=false wind.Enabled=false
   for _,c in ipairs(claws)do
    for _,beam in ipairs(c.Beams)do E.Tween(beam,.12,{Width0=0,Width1=0})end
    E.Tween(c.Groove,.7,{Transparency=1},nil,nil,.2)  -- the grooves cool off after the claws are gone
    E.Tween(c.GrooveGlow,.6,{Transparency=1},nil,nil,.1)
   end
   if wall then  -- they break on the wall
    local h=E.Group("P5ClawEnd")
    local b=E.Anchor(h,CFrame.new(wall.Position))
    E.Sprite(b,{tex="claw.marks",size={{0,W*.5},{1,W*.7}},alpha={{0,0},{.6,.3},{1,1}},color=GOLD},.4)
    E.Emit(b,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.45},speed={14,30},spread=90,drag=2},14)
    E.After(h,.8,function()h:Destroy()end)
   end
  end
  return t<life+1.1
 end)
 E.After(g,life+1.3,function()g:Destroy()end)
end

function P.ClawHit(E,d)
 local g=E.Group("P5ClawHit")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 E.Sprite(a,{tex="claw.marks",size={{0,4},{.2,10},{1,11}},alpha={{0,0},{.5,.2},{1,1}},color=GOLD,rot={-30,30}},.35)
 E.Sprite(a,{tex="flare.burst",size={{0,2},{1,8}},alpha={{0,0},{1,1}},color=SHINE},.2)
 E.Emit(a,{tex="star.crisp",size={{0,.7},{1,0}},color={{0,SHINE},{1,AMBER}},life={.25,.45},speed={18,34},spread=180,drag=2},14)
 E.After(g,.8,function()g:Destroy()end)
end

function P.AssassinTell(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .3
 local tone=d.Fake and VIOLET or CRIMSON  -- a feint draws violet; the real cut is red
 local g=E.Group("P5AssassinTell")
 local a=E.Anchor(g,r.CFrame)
 local aura=E.Stream(a,{tex="smoke",light=0,size={{0,2.5},{1,5}},alpha={{0,.45},{1,1}},color={{0,VOID},{1,VOID}},
  life={.3,.5},speed={2,5},spread=180,drag=2},40)
 E.Emit(a,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,tone},{1,VOID}},life={.25,.45},speed={8,14},spread=180,drag=2},18)
 local blade=bladeOf(d.Boss)
 local h=blade and E.Anchor(g,blade.CFrame)
 if h then E.Sprite(h,{tex="star.glare",size={{0,1},{.85,6},{1,1}},alpha={{0,.3},{.8,0},{1,1}},color=tone},T)end
  -- the mark over the one he is about to cut
 local vr=rootOf(d.Victim)
 local mark=vr and E.Anchor(g,CFrame.new(vr.Position+UP*4.5))
 if mark then
  E.Sprite(mark,{tex="star.anime",size={{0,4},{.3,1.6},{1,1.4}},alpha={{0,1},{.2,0},{1,.2}},color=tone},T)
  if not d.Fake then E.Sprite(mark,{tex="glow.soft",size={{0,1},{.3,5},{1,4}},alpha={{0,1},{.3,.3},{1,1}},color=CRIMSON},T)end
 end
 E.Step(g,function(_,t)
  if r.Parent then a.CFrame=r.CFrame end
  if h and blade.Parent then h.CFrame=blade.CFrame end
  if mark and vr.Parent then mark.CFrame=CFrame.new(vr.Position+UP*4.5)end
  if t>=T then aura.Enabled=false end
  return t<T+.4
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end

 -- an arc of camera-facing beams around `center` (in its local XZ plane, radius R): a crimson glow, a black
 -- blade and a hot leading edge; Sweep(fraction, fade) redraws it as it opens
local function arcSlash(E,g,center,R,startAngle,span,fake)
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=center
 local N=E.Quality<.6 and 14 or 22
 local points,layers={},{}
 for i=0,N do
  local at=Instance.new("Attachment")at.Parent=carrier points[i+1]=at
 end
 local function ribbon(w,color,alpha,emission,head)
  local beams={}
  for i=1,N do
   local beam=Instance.new("Beam")
   beam.Attachment0=points[i] beam.Attachment1=points[i+1]
   beam.FaceCamera=true beam.Segments=2 beam.LightEmission=emission beam.LightInfluence=0
   beam.Color=ColorSequence.new(color) beam.Transparency=NumberSequence.new(alpha)
   beam.Parent=carrier
   beams[i]=beam
  end
  layers[#layers+1]={Beams=beams,W=w,Head=head}
 end
 ribbon(R*.24,fake and VIOLET or CRIMSON,fake and .65 or .45,1,false)  -- the glow
 ribbon(R*.09,fake and PINK or VOID,fake and .55 or 0,fake and 1 or 0,false)  -- the black blade
 ribbon(R*.025,fake and WHITE or Color3.fromRGB(255,190,200),fake and .4 or 0,1,true)  -- the hot edge
 local function sweep(frac,fade)
  for i,at in ipairs(points)do
   local a=startAngle+span*frac*(i-1)/N
   at.Position=Vector3.new(math.cos(a)*R,0,math.sin(a)*R)
  end
  for _,l in ipairs(layers)do
   for i,beam in ipairs(l.Beams)do
     -- thickest at the leading end, thinning to nothing at the tail
    local t0,t1=(i-1)/N,i/N
    local k0,k1=t0^1.6,t1^1.6
    if l.Head then k0,k1=t0^4,t1^4 end
    beam.Width0=math.max(.04,l.W*k0*(1-fade)) beam.Width1=math.max(.04,l.W*k1*(1-fade))
   end
  end
 end
 sweep(.01,0)
 return sweep
end

function P.BlackSlash(E,d)
 local g=E.Group("P5BlackSlash")
 local R=d.Radius or 13
 local fake=d.Fake==true
 local index=d.Index or 1
  -- each cut wraps him on its own tilt: one leaning forward, one to the side, one nearly flat; the three
  -- cross into a cage of black cuts that hangs for a beat, then bursts
 local tilt=({CFrame.Angles(.32,0,.12),CFrame.Angles(-.18,0,-.35),CFrame.Angles(.05,0,.04)})[index]or CFrame.new()
 local center=d.Frame*CFrame.new(0,.8,0)*tilt
 local spin=index%2==1 and 1 or -1
 local span=math.rad(290)*spin
 local start=math.rad(({200,40,300})[index]or 0)
 local sweep=arcSlash(E,g,center,R,start,span,fake)
 local streak=E.Anchor(g,center)
 E.Sprite(streak,{tex="slash.streak",orient="flat",size={{0,R*.8},{.3,R*2.4},{1,R*2.6}},alpha={{0,.2},{.5,.55},{1,1}},
  color=fake and VIOLET or VOID,light=0,rot={math.deg(start),math.deg(start)}},.35)
 E.Emit(streak,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,fake and VIOLET or CRIMSON}},life={.2,.4},speed={R*1.6,R*3},spread=180,drag=3},fake and 8 or 14)
 local burst=false
 E.Step(g,function(_,t)
  local k=math.clamp(t/.09,0,1)
  local fade=t<.3 and 0 or math.clamp((t-.3)/.15,0,1)
  sweep(1-(1-k)^3,fade)
  if not burst and t>=.3 then
   burst=true
   local a=E.Anchor(g,center)
   if fake then  -- the false cut shatters like glass and is gone
    E.Emit(a,{tex="star.twinkle",size={{0,.9},{1,0}},color={{0,WHITE},{1,VIOLET}},life={.4,.7},speed={10,24},spread=180,drag=2},28)
   else
    E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,CRIMSON}},life={.3,.55},speed={30,60},spread=180,drag=2.5},30)
    E.Emit(a,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.3},{1,1}},color={{0,VOID},{1,VOID}},life={.45,.8},speed={18,34},spread=180,drag=3.5},18)
    E.Sprite(a,{tex="flare.burst",size={{0,4},{1,R*1.8}},alpha={{0,0},{1,1}},color=CRIMSON},.22)
    E.Light(g,a,CRIMSON,R*2,6,.3)
   end
  end
  return t<.55
 end)
  -- the floor under him takes thin radial cuts that fade
 if not fake and index==1 then
  local base=E.Ground(d.Frame.Position+UP*2,{d.Boss,g.Folder})
  if base then
   for i=1,9 do
    local a=i/9*math.pi*2+math.random()*.3
    local len=R*(.55+math.random()*.4)
    local dir=Vector3.new(math.cos(a),0,math.sin(a))
    local mid=base+dir*(R*.35+len*.5)+UP*.05
    local cut=newPart(g,Vector3.new(.22,.05,len),Color3.fromRGB(90,8,24),.05)
    cut.Material=Enum.Material.SmoothPlastic
    cut.CFrame=CFrame.lookAt(mid,mid+dir)
    E.Tween(cut,.6,{Transparency=1},nil,nil,.5)
   end
  end
 end
 E.After(g,1.3,function()g:Destroy()end)
end

function P.UpperTell(E,d)
 local g=E.Group("P5UpperTell")
 local T=d.Time or .6
 local a=E.Anchor(g,CFrame.new(d.Pos+UP*.3))
  -- wind gathers in thin upward streaks where the blade will come up
 local s=E.Stream(a,{tex="wind.dash",orient="velocity",size={{0,1.5},{1,3.5}},alpha={{0,.55},{1,1}},color=GOLD,
  life={.18,.3},speed={18,30},spread=14,dir=Enum.NormalId.Top},26)
 local m=E.Stream(a,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,SHINE},{1,GOLD}},life={.4,.7},speed={6,12},spread=25,dir=Enum.NormalId.Top},40)
 local blade=bladeOf(d.Boss)
 local h=blade and E.Anchor(g,blade.CFrame)
 if h then E.Sprite(h,{tex="star.glare",size={{0,1},{.85,7},{1,1}},alpha={{0,.3},{.8,0},{1,1}},color=GOLD},T)end
 E.Step(g,function(_,t)
  if h and blade.Parent then h.CFrame=blade.CFrame end
  if t>=T then s.Enabled=false m.Enabled=false end
  return t<T+.5
 end)
 E.After(g,T+.8,function()g:Destroy()end)
end

function P.UpperSlash(E,d)
 local g=E.Group("P5UpperSlash")
 local H=d.Height or 14
 local look=flatLook(d.Frame)
  -- a vertical slash in the plane of his swing (X forward, Y up), swept up from the ground
 local pivot=CFrame.fromMatrix(d.Pos+UP*(H*.38),look,UP)
 local layers=slash(g,H*1.5,WHITE,AMBER,{CoreAlpha=0,GlowAlpha=.3,Streak=true,StreakColor=SHINE,StreakAlpha=.72,StreakScale=1.05})
 local trail=slash(g,H*1.35,AMBER,AMBER,{CoreAlpha=.62,GlowAlpha=.88})  -- a fainter copy a beat behind
 E.Step(g,function(_,t)
  local k=math.clamp(t/.15,0,1)
  local ease=1-(1-k)^3
  local lag=math.clamp((t-.04)/.15,0,1)
  local lagEase=1-(1-lag)^3
  local rise=t>.15 and(t-.15)*14 or 0
  local fade=t<.15 and 0 or math.clamp((t-.2)/.22,0,1)
  local parts,cfs={},{}
  place(layers,CFrame.new(0,rise,0)*pivot*CFrame.Angles(0,0,-1.5+1.9*ease),.6+.5*ease,fade,parts,cfs)
  place(trail,CFrame.new(0,rise,0)*pivot*CFrame.Angles(0,0,-1.5+1.7*lagEase),.55+.45*lagEase,math.max(fade,1-lag),parts,cfs)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<.5
 end)
 local base=E.Anchor(g,CFrame.new(d.Pos+UP*.4))
 local hit=E.Anchor(g,CFrame.new(d.Pos+UP*4))
 E.Emit(base,{tex="wind.dash",orient="velocity",size={{0,3},{1,8}},alpha={{0,.3},{1,1}},color=SHINE,life={.2,.35},speed={70,110},spread=10,dir=Enum.NormalId.Top},14)
 E.Emit(base,{tex="star.crisp",size={{0,1},{1,0}},color={{0,SHINE},{1,GOLD}},life={.4,.8},speed={30,65},spread=18,dir=Enum.NormalId.Top,drag=1.5},22)
 E.Sprite(base,{tex="burst.spiky",orient="flat",size={{0,2},{1,10}},alpha={{0,0},{1,1}},color=GOLD},.3)
 E.Sprite(hit,{tex="flare.big",size={{0,3},{.2,16},{1,18}},alpha={{0,0},{.5,.4},{1,1}},color=SHINE},.3)
 E.Light(g,hit,GOLD,28,7,.4)
 E.After(g,1.2,function()g:Destroy()end)
end

 -- his own Phase 5 wings carry the Butterfly (the server spreads and beats them, Phase5Transition.BeatWings);
 -- this only makes them shed gold light and butterflies while they do
function P.Wings(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 1.5
 local g=E.Group("P5Wings")
 local dust=E.Anchor(g,r.CFrame)
 local shed=E.Stream(dust,butterflies(1.1,{3,8},{.45,.75}),22)
 local motes=E.Stream(dust,{tex="star.twinkle",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.4,.8},speed={2,6},spread=180,drag=1},50)
 local glow=E.Anchor(g,r.CFrame)
 E.Sprite(glow,{tex="glow.soft",size={{0,4},{.2,16},{1,14}},alpha={{0,.4},{.8,.55},{1,1}},color=GOLD},T)
 E.Light(g,dust,GOLD,22,3,T)
 E.Step(g,function(_,t)
  if not r.Parent then g:Destroy()return false end
  local back=r.CFrame*CFrame.new(0,1.6,1.4)
  workspace:BulkMoveTo({dust,glow},{back,back},Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then shed.Enabled=false motes.Enabled=false end
  return t<T+.4
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end

function P.ButterflyDash(E,d)
 local g=E.Group("P5ButterflyDash")
 local len=(d.To-d.From).Magnitude
 if len<1 then g:Destroy()return end
 local T=d.Time or .2
 local dir=(d.To-d.From).Unit
  -- the thrust: a piercing cone of wind leads the sword point along the line
 local tip=E.Anchor(g,CFrame.lookAt(d.From,d.To))
 E.Stream(tip,{tex="wind.dash",orient="velocity",size={{0,6},{1,12}},alpha={{0,.3},{1,1}},color=SHINE,life={.1,.16},speed={60,90},dir=Enum.NormalId.Back,spread=4},60)
 E.Stream(tip,butterflies(.9,{2,6},{.35,.6}),40)
 E.Sprite(tip,{tex="flare.streak",size={{0,8},{1,14}},alpha={{0,0},{1,.4}},color=BUTTERFLY_GOLD,rot={0,0}},T+.05)
  -- the mark it leaves: a gold line hanging in the air along the thrust, and a scar on the floor under it
 local core=newPart(g,Vector3.new(.35,.35,.1),SHINE,0)
 local glow=newPart(g,Vector3.new(1.6,1.6,.1),BUTTERFLY_GOLD,.45)
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={g.Folder,d.Boss}
 local hitA=workspace:Raycast(d.From,Vector3.new(0,-40,0),params)
 local hitB=workspace:Raycast(d.To+UP*2,Vector3.new(0,-40,0),params)
 local fa=Vector3.new(d.From.X,hitA and hitA.Position.Y or d.To.Y-3,d.From.Z)
 local fb=Vector3.new(d.To.X,hitB and hitB.Position.Y or d.To.Y-3,d.To.Z)
 local scarLen=math.max((fb-fa).Magnitude,.1)
 local scar=newPart(g,Vector3.new(.7,.07,scarLen),AMBER,.15)
 local scarGlow=newPart(g,Vector3.new(2.6,.06,scarLen),BUTTERFLY_GOLD,.6)
 scar.CFrame=CFrame.lookAt((fa+fb)/2+UP*.06,fb+UP*.06) scarGlow.CFrame=scar.CFrame
 local broken=false
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local reach=len*k
  local head=d.From+dir*reach
  local parts,cfs={tip},{CFrame.lookAt(head,head+dir)}
  if not broken then
   local m2=d.From+dir*(reach*.5)
   core.Size=Vector3.new(.35,.35,math.max(reach,.1)) glow.Size=Vector3.new(1.6,1.6,math.max(reach,.1))
   local cf=CFrame.lookAt(m2,m2+dir)
   parts[#parts+1]=core cfs[#cfs+1]=cf
   parts[#parts+1]=glow cfs[#cfs+1]=cf
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if not broken and t>=T+.3 then
   broken=true  -- the hanging line breaks up into butterflies
   local n=math.clamp(math.floor(len/3),4,14)
   for i=1,n do
    local a=E.Anchor(g,CFrame.new(d.From:Lerp(d.To,(i-.5)/n)))
    E.Emit(a,butterflies(1,{3,9},{.4,.7}),3)
    E.Emit(a,{tex="star.twinkle",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.45},speed={2,6},spread=180,drag=2},4)
   end
   E.Tween(core,.25,{Size=Vector3.new(0,0,len),Transparency=1})
   E.Tween(glow,.3,{Size=Vector3.new(0,0,len),Transparency=1})
  end
  return t<T+1
 end)
 E.Tween(scar,.4,{Transparency=1},nil,nil,T+.45)  -- the floor scar cools last
 E.Tween(scarGlow,.35,{Transparency=1},nil,nil,T+.3)
 E.After(g,T+1.2,function()g:Destroy()end)
end

function P.ButterflyBurst(E,d)
 local g=E.Group("P5ButterflyBurst")
 local R=d.Radius or 8
 local center=d.Pos+UP*2.5
 local a=E.Anchor(g,CFrame.new(center))
 local floor=E.Anchor(g,CFrame.new(d.Pos+UP*.15))
 E.Sprite(a,{tex="flare.big",size={{0,3},{.2,R*2.2},{1,R*2.6}},alpha={{0,0},{.5,.35},{1,1}},color=BUTTERFLY_GOLD},.4)
 E.Sprite(floor,{tex="burst.spiky",orient="flat",size={{0,2},{.2,R*2},{1,R*2.3}},alpha={{0,0},{.6,.45},{1,1}},color=GOLD},.5)  -- the thrust's impact mark
 E.Emit(a,butterflies(1.4,{14,30},{.45,.8}),30)
 E.Emit(a,{tex="star.twinkle",size={{0,1.1},{1,0}},color={{0,SHINE},{.5,GOLD},{1,AMBER}},life={.3,.55},speed={16,34},spread=180,drag=2},24)
 E.Light(g,a,GOLD,R*3,6,.5)
 E.After(g,1,function()g:Destroy()end)
end

 -- a straight shot: Pierce (a gold spear of light), Gold (a thinner gold needle) or Star (a spinning star)
function P.Bolt(E,d)
 local g=E.Group("P5Bolt")
 local dir=d.Dir
 local speed,range=d.Speed or 200,d.Range or 60
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude
 local ignore={g.Folder,d.Boss}
 for _,pl in ipairs(Players:GetPlayers())do if pl.Character then ignore[#ignore+1]=pl.Character end end
 params.FilterDescendantsInstances=ignore
 local wall=workspace:Raycast(d.Origin,dir*range,params)
 local reach=wall and wall.Distance or range
 local life=reach/speed
 local look=d.Look or "Pierce"
 local tip=E.Anchor(g,CFrame.lookAt(d.Origin,d.Origin+dir))
 local parts={}
 if look=="Star" then
  E.Sprite(tip,{tex="star.anime",size=2.2,color=SHINE,spin={360,540}},life+.05)
  E.Sprite(tip,{tex="glow.soft",size=4,alpha=.5,color=VIOLET},life+.05)
  E.Stream(tip,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,VIOLET}},life={.2,.35},speed={1,3},spread=180},50)
 else
  local w=look=="Gold" and .35 or .7
  local len=look=="Gold" and 5 or 8
  local core=newPart(g,Vector3.new(w,w,len),SHINE,0)
  local glow=newPart(g,Vector3.new(w*3.2,w*3.2,len*1.15),look=="Gold" and BUTTERFLY_GOLD or GOLD,.55)
  parts={core,glow}
  E.Sprite(tip,{tex="flare.streak",size=look=="Gold" and 5 or 9,alpha=.2,color=BUTTERFLY_GOLD,rot={0,0}},life+.05)
  E.Stream(tip,{tex="wind.dash",orient="velocity",size={{0,2},{1,4}},alpha={{0,.4},{1,1}},color=SHINE,life={.1,.18},speed={30,50},dir=Enum.NormalId.Back,spread=4},look=="Gold" and 30 or 45)
 end
 local muzzle=E.Anchor(g,CFrame.lookAt(d.Origin,d.Origin+dir))
 E.Sprite(muzzle,{tex="flare.burst",size={{0,1},{1,look=="Pierce" and 9 or 5}},alpha={{0,0},{1,1}},color=SHINE},.18)
 local ended=false
 E.Step(g,function(_,t)
  local at=d.Origin+dir*math.min(t*speed,reach)
  local cf=CFrame.lookAt(at,at+dir)
  local list,cfs={tip},{cf}
  for i,p in ipairs(parts)do list[#list+1]=p cfs[#cfs+1]=cf*CFrame.new(0,0,p.Size.Z*.5)end
  workspace:BulkMoveTo(list,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=life and not ended then
   ended=true
   for _,p in ipairs(parts)do p.Transparency=1 end
   local h=E.Group("P5BoltEnd")
   local b=E.Anchor(h,CFrame.new(at))
   E.Emit(b,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,GOLD}},life={.2,.4},speed={14,30},spread=180,drag=2},look=="Pierce" and 16 or 6)
   E.After(h,.7,function()h:Destroy()end)
  end
  return t<life+.3
 end)
 E.After(g,life+.5,function()g:Destroy()end)
end

 -- the mode weapon's swing: Space Slash (a dark saber crescent), Natural Sweep (an aurora ring around him),
 -- Time Chop (a gold arc down the line, and its echo a beat later)
function P.WeaponSlash(E,d)
 local g=E.Group("P5WeaponSlash")
 local frame=d.Frame
 local c=MODE_COLORS[d.Mode]or MODE_COLORS.Space
 local layers,place3
 if d.Kind=="Sweep" then
  local R=d.Radius or 19
  local sweep=arcSlash(E,g,frame*CFrame.new(0,.4,0),R,math.rad(-60),math.rad(300),false)
  local tintBeams=g.Folder:GetDescendants()
  for _,b in ipairs(tintBeams)do if b:IsA("Beam")then
   local col=b.Color.Keypoints[1].Value
   if col==CRIMSON then b.Color=ColorSequence.new(MINT,BLUE)elseif col==VOID then b.Color=ColorSequence.new(BLUE) b.LightEmission=1 b.Transparency=NumberSequence.new(.2)
   else b.Color=ColorSequence.new(WHITE)end
  end end
  local a=E.Anchor(g,frame)
  E.Emit(a,{tex="star.twinkle",size={{0,.9},{1,0}},color={{0,WHITE},{.5,MINT},{1,BLUE}},life={.5,.9},speed={R*.8,R*1.6},spread=180,drag=2},30)
  E.Step(g,function(_,t)
   local k=math.clamp(t/.14,0,1)
   sweep(1-(1-k)^3,t<.3 and 0 or math.clamp((t-.3)/.2,0,1))
   return t<.55
  end)
 else
  local look=frame.LookVector*Vector3.new(1,0,1)
  look=look.Magnitude>.1 and look.Unit or Vector3.zAxis
  local echo=d.Echo==true
  if d.Kind=="Chop" then  -- a vertical arc down the line ahead
   local L=d.Length or 26
   local pivot=CFrame.fromMatrix(frame.Position+look*(L*.45),look,UP)
   layers=slash(g,L*1.05,echo and SHINE or WHITE,GOLD,{CoreAlpha=echo and .55 or 0,GlowAlpha=echo and .75 or .35,Streak=not echo,StreakColor=SHINE,StreakAlpha=.75})
   local line=newPart(g,Vector3.new(.5,.06,L),GOLD,echo and .5 or .1)
   local floor=E.Ground(frame.Position+UP,{d.Boss,g.Folder})
   local fy=floor and floor.Y or frame.Y-3
   line.CFrame=CFrame.lookAt(Vector3.new(frame.X,fy+.05,frame.Z)+look*(L*.5),Vector3.new(frame.X,fy+.05,frame.Z)+look*L)
   E.Tween(line,.6,{Transparency=1},nil,nil,.15)
   place3=function(t)
    local k=math.clamp(t/.12,0,1)
    return pivot*CFrame.Angles(0,0,.9-1.6*(1-(1-k)^3)),.8+.3*k
   end
  else  -- Space: a dark saber crescent across his front
   local R=d.Radius or 15
   layers=slash(g,R*1.6,Color3.fromRGB(30,12,60),c[1],{CoreAlpha=0,GlowAlpha=.3})
   local roll=(d.Index or 1)%2==1 and .3 or -.3
   local base=frame*CFrame.new(0,.8,-R*.35)*CFrame.Angles(0,0,roll)*CFrame.Angles(-math.pi/2,0,0)
   local side=(d.Index or 1)%2==1 and 1 or -1
   place3=function(t)
    local k=math.clamp(t/.09,0,1)
    return base*CFrame.Angles(0,0,side*(1-(1-(1-k)^3))*.8),.8+.25*k
   end
   local a=E.Anchor(g,frame*CFrame.new(0,1,-R*.5))
   E.Emit(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,WHITE},{1,c[1]}},life={.3,.6},speed={8,18},spread=70,dir=Enum.NormalId.Front,drag=2},18)
  end
  E.Step(g,function(_,t)
   local cf,scale=place3(t)
   local parts,cfs={},{}
   place(layers,cf,scale,t<.15 and 0 or math.clamp((t-.2)/.2,0,1),parts,cfs)
   workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
   return t<.45
  end)
 end
 E.After(g,1.2,function()g:Destroy()end)
end

 -- Distorted Counter: a small gold spell circle in front of him (and one under his feet) while he waits
local stances=setmetatable({},{__mode="k"})
function P.CounterStance(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 1.4
 local g=E.Group("P5CounterStance")
 local front=E.Anchor(g,r.CFrame*CFrame.new(0,.6,-2.2))
 local floor=E.Anchor(g,r.CFrame*CFrame.new(0,-2.9,0))
 E.Sprite(front,{tex="sigil.ring",orient="flat",dir=Enum.NormalId.Front,size={{0,1},{.12,6},{1,6}},alpha={{0,.6},{.1,.05},{.9,.15},{1,1}},color=BUTTERFLY_GOLD,spin={60,60}},T)
 E.Sprite(front,{tex="sigil.ring2",orient="flat",dir=Enum.NormalId.Front,size={{0,1},{.12,4.2},{1,4.2}},alpha={{0,.6},{.1,.1},{.9,.2},{1,1}},color=SHINE,spin={-90,-90}},T)
 E.Sprite(floor,{tex="sigil.ring",orient="flat",size={{0,1},{.12,8},{1,8}},alpha={{0,.7},{.1,.3},{.9,.4},{1,1}},color=GOLD,spin={30,30}},T)
 E.Light(g,front,GOLD,12,3,T)
 g.Front=front
 if stances[d.Boss]then stances[d.Boss]:Destroy()end
 stances[d.Boss]=g
 E.Step(g,function(_,t)
  if r.Parent then workspace:BulkMoveTo({front,floor},{r.CFrame*CFrame.new(0,.6,-2.2),r.CFrame*CFrame.new(0,-2.9,0)},Enum.BulkMoveMode.FireCFrameChanged)end
  return t<T+.2
 end)
 E.After(g,T+.3,function()g:Destroy()end)
end
function P.CounterFade(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 if stances[d.Boss]then stances[d.Boss]:Fade(.15) stances[d.Boss]=nil end
 local g=E.Group("P5CounterFade")
 local a=E.Anchor(g,r.CFrame*CFrame.new(0,.6,-2.2))
 E.Emit(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.5},speed={2,6},spread=180,drag=2},16)
 E.After(g,.8,function()g:Destroy()end)
end
function P.CounterCatch(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 if stances[d.Boss]then stances[d.Boss]:Fade(.1) stances[d.Boss]=nil end
 local g=E.Group("P5CounterCatch")
 local a=E.Anchor(g,r.CFrame*CFrame.new(0,.6,-2.2))
 E.Sprite(a,{tex="star.glare",size={{0,2},{.3,16},{1,6}},alpha={{0,0},{1,1}},color=SHINE,rot={0,0}},.3)
 E.Sprite(a,{tex="flare.burst",size={{0,2},{1,12}},alpha={{0,0},{1,1}},color=BUTTERFLY_GOLD},.25)
 E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.45},speed={20,40},spread=180,drag=2},18)
 E.Light(g,a,GOLD,20,7,.3)
 E.After(g,.8,function()g:Destroy()end)
end

 -- Golden Pierce: a gold spell circle standing in front of him, facing the player, until the volley is done
function P.PierceCircle(E,d)
 local T=d.Time or 1
 local k=d.Small and .45 or 1
 local g=E.Group("P5PierceCircle")
 local a=E.Anchor(g,d.Frame)
 E.Sprite(a,{tex="sigil.mandala",orient="flat",dir=Enum.NormalId.Front,size={{0,1},{.15,8*k},{1,8*k}},alpha={{0,.6},{.12,.05},{.85,.1},{1,1}},color=BUTTERFLY_GOLD,spin={120,120}},T)
 E.Sprite(a,{tex="sigil.ring",orient="flat",dir=Enum.NormalId.Front,size={{0,1},{.15,10.5*k},{1,10.5*k}},alpha={{0,.6},{.12,.2},{.85,.3},{1,1}},color=SHINE,spin={-60,-60}},T)
 E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.5},speed={-8,-4},spread=180},40*k)
 if not d.Small then E.Light(g,a,GOLD,18,5,T)end
 E.After(g,T+.3,function()g:Destroy()end)
end

 -- Wild Hunt: a lunge leaves gold claw gashes hanging along its path and a groove under it
function P.HuntLunge(E,d)
 local g=E.Group("P5HuntLunge")
 local T=d.Time or .22
 local dir=(d.To-d.From)
 local len=dir.Magnitude
 if len<1 then g:Destroy()return end
 dir=dir.Unit
 local n=5
 for i=1,n do
  E.After(g,T*(i-1)/n,function()
   local at=d.From:Lerp(d.To,(i-.5)/n)
   local frame=CFrame.lookAt(at,at+dir)*CFrame.Angles(0,0,(i%2==1 and 1 or -1)*.7)
   local layers=slash(g,16,WHITE,AMBER,{GlowAlpha=.3,Streak=true,StreakColor=GOLD,StreakAlpha=.5})
   local born=os.clock()
   E.Step(g,function()
    local t=os.clock()-born
    local parts,cfs={},{}
    place(layers,frame*CFrame.Angles(math.pi/2,0,0),.8+.4*math.min(t/.08,1),t<.12 and 0 or math.clamp((t-.12)/.25,0,1),parts,cfs)
    workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
    return t<.4
   end)
  end)
 end
 local tip=E.Anchor(g,CFrame.lookAt(d.From,d.To))
 E.Stream(tip,{tex="wind.dash",orient="velocity",size={{0,6},{1,12}},alpha={{0,.3},{1,1}},color=SHINE,life={.12,.2},speed={50,80},dir=Enum.NormalId.Back,spread=8},80)
 E.Stream(tip,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,SHINE},{1,AMBER}},life={.2,.4},speed={10,24},spread=60,dir=Enum.NormalId.Back,drag=2},60)
 local s0,s1=E.Anchor(g,CFrame.new(d.From)),E.Anchor(g,CFrame.new(d.To))
 E.Sprite(s0,{tex="flare.burst",size={{0,2},{1,16}},alpha={{0,0},{1,1}},color=AMBER},.25)
 E.Sprite(s0,{tex="ring.crisp",orient="flat",size={{0,2},{1,22}},alpha={{0,.1},{1,1}},color=GOLD},.35)
 E.After(g,T,function()
  E.Sprite(s1,{tex="flare.big",size={{0,3},{.2,20},{1,24}},alpha={{0,0},{.5,.4},{1,1}},color=SHINE},.35)
  E.Emit(s1,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.25,.5},speed={20,45},spread=180,drag=2},22)
  E.Light(g,s1,AMBER,30,7,.35)
 end)
 E.Step(g,function(_,t)
  local p=d.From:Lerp(d.To,math.clamp(t/T,0,1))
  tip.CFrame=CFrame.lookAt(p,p+dir)
  return t<T
 end)
 local floor=E.Ground(d.From+UP*2,{d.Boss,g.Folder})
 if floor then
  local fy=floor.Y+.05
  local a0,b0=Vector3.new(d.From.X,fy,d.From.Z),Vector3.new(d.To.X,fy,d.To.Z)
  local groove=newPart(g,Vector3.new(.8,.06,(b0-a0).Magnitude),AMBER,.1)
  groove.CFrame=CFrame.lookAt((a0+b0)/2,b0)
  E.Tween(groove,.7,{Transparency=1},nil,nil,.4)
 end
 E.After(g,1.4,function()g:Destroy()end)
end

 -- Wild Hunt: he drags himself low along the ground - sparks spray off behind him and the floor is scored
function P.HuntDrag(E,d)
 local g=E.Group("P5HuntDrag")
 local T=d.Time or .6
 local dir=d.To-d.From
 if dir.Magnitude<.5 then g:Destroy()return end
 dir=dir.Unit
 local floor=E.Ground(d.From+UP*2,{d.Boss,g.Folder})
 local fy=floor and floor.Y or d.From.Y-3
 local base=E.Anchor(g,CFrame.lookAt(Vector3.new(d.From.X,fy+.3,d.From.Z),Vector3.new(d.To.X,fy+.3,d.To.Z)))
 local sparks=E.Stream(base,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,AMBER}},life={.25,.5},speed={14,30},
  spread=35,dir=Enum.NormalId.Back,accel=Vector3.new(0,-40,0),drag=1},140)
 local dust=E.Stream(base,{tex="smoke",light=0,size={{0,1.5},{1,4}},alpha={{0,.55},{1,1}},color={{0,Color3.fromRGB(120,90,40)},{1,Color3.fromRGB(70,55,30)}},
  life={.4,.7},speed={3,8},spread=50,dir=Enum.NormalId.Back,drag=2},30)
 local scar=newPart(g,Vector3.new(2.2,.07,.1),AMBER,.15)
 local scarGlow=newPart(g,Vector3.new(4.5,.06,.1),GOLD,.6)
 local from=Vector3.new(d.From.X,fy+.06,d.From.Z)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local p=Vector3.new(d.From.X,fy+.3,d.From.Z):Lerp(Vector3.new(d.To.X,fy+.3,d.To.Z),k)
  local len=math.max((Vector3.new(p.X,from.Y,p.Z)-from).Magnitude,.1)
  local mid=from+dir*(len*.5)
  local cf=CFrame.lookAt(mid,mid+dir)
  scar.Size=Vector3.new(2.2,.07,len) scarGlow.Size=Vector3.new(4.5,.06,len)
  workspace:BulkMoveTo({base,scar,scarGlow},{CFrame.lookAt(p,p+dir),cf,cf},Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then sparks.Enabled=false dust.Enabled=false end
  return t<T
 end)
 E.Tween(scar,1,{Transparency=1},nil,nil,T+.8)
 E.Tween(scarGlow,.8,{Transparency=1},nil,nil,T+.5)
 E.After(g,T+2,function()g:Destroy()end)
end

 -- Wild Hunt: the bite - two huge crescent jaws snap shut in front of him
function P.HuntBite(E,d)
 local g=E.Group("P5HuntBite")
 jaws(E,g,d.Frame*CFrame.new(0,1.5,-7),26,CRIMSON:Lerp(AMBER,.5),8)
 local a=E.Anchor(g,d.Frame*CFrame.new(0,1.5,-7))
 E.Sprite(a,{tex="star.glare2",size={{0,4},{.25,26},{1,10}},alpha={{0,0},{1,1}},color=AMBER,rot={0,0}},.3)
 E.After(g,1,function()g:Destroy()end)
end

 -- Wild Hunt: he stops dead and the ground around him goes up in gold
function P.HuntBurst(E,d)
 local g=E.Group("P5HuntBurst")
 local R=d.Radius or 22
 local floor=E.Anchor(g,CFrame.new(d.Pos+UP*.2))
 local mid=E.Anchor(g,CFrame.new(d.Pos+UP*4))
 E.Sprite(mid,{tex="flare.big",size={{0,6},{.15,R*2.6},{1,R*3}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.5)
 E.Sprite(mid,{tex="burst.spiky2",size={{0,4},{1,R*2.4}},alpha={{0,0},{1,1}},color=GOLD,rot={0,360}},.4)
 E.Sprite(floor,{tex="burst.spiky",orient="flat",size={{0,4},{.2,R*2.2},{1,R*2.5}},alpha={{0,0},{.6,.4},{1,1}},color=AMBER},1)
 E.Emit(mid,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,GOLD}},life={.4,.9},speed={R*1.5,R*3},spread=180,drag=2,accel=Vector3.new(0,-30,0)},50)
 E.Emit(floor,{tex="fire",size={{0,4},{1,9}},alpha={{0,.2},{1,1}},color={{0,SHINE},{.4,GOLD},{1,AMBER}},life={.5,.9},speed={R*.8,R*1.6},spread=80,dir=Enum.NormalId.Top,drag=2.5},36)
 E.Emit(floor,{tex="smoke",light=0,size={{0,4},{1,10}},alpha={{0,.4},{1,1}},color={{0,Color3.fromRGB(110,80,30)},{1,Color3.fromRGB(50,40,25)}},life={.7,1.2},speed={R*.5,R},spread=85,dir=Enum.NormalId.Top,drag=3},20)
 E.Light(g,mid,GOLD,R*3,9,.6)
  -- a pillar of gold light where he stands
 local pillar=newPart(g,Vector3.new(70,R*.45,R*.45),GOLD,.35)
 local core=newPart(g,Vector3.new(70,R*.16,R*.16),WHITE,0)
 pillar.Shape=Enum.PartType.Cylinder core.Shape=Enum.PartType.Cylinder
 local up=CFrame.new(d.Pos+UP*35)*CFrame.Angles(0,0,math.pi/2)
 pillar.CFrame=up core.CFrame=up
 E.Tween(pillar,.6,{Size=Vector3.new(80,.1,.1),Transparency=1})
 E.Tween(core,.45,{Size=Vector3.new(80,.05,.05),Transparency=1})
 E.Sprite(mid,{tex="glow.rays",size={{0,6},{1,R*3.2}},alpha={{0,.2},{1,1}},color=AMBER,spin={-40,40}},.7)
 E.After(g,1.8,function()g:Destroy()end)
end

 -- Golden Pierce: the laser. A white-hot core inside gold and amber sheaths, energy streaming down it, rings
 -- running along it, a flare at the muzzle and sparks where it ends; it swells in, throbs, and thins out
function P.PierceBeam(E,d)
 local g=E.Group("P5PierceBeam")
 local dir=d.Dir
 local L,T,W=d.Range or 90,d.Time or .9,d.Width or 3
 local o=d.Origin
 local tipPos=o+dir*L
 local function tube(diam,color,alpha)
  local p=newPart(g,Vector3.new(L,diam,diam),color,alpha)
  p.Shape=Enum.PartType.Cylinder
  return p
 end
 local core,mid,outer=tube(W*.45,WHITE,0),tube(W*1.1,BUTTERFLY_GOLD,.35),tube(W*2.3,AMBER,.8)
 local frame=CFrame.lookAt(o+dir*L*.5,tipPos)*CFrame.Angles(0,math.pi/2,0)  -- the cylinders' X axis down the beam
 local a0=E.Anchor(g,CFrame.lookAt(o,tipPos))
 local a1=E.Anchor(g,CFrame.lookAt(tipPos,tipPos+dir))
 local at0,at1=E.Attach(a0),E.Attach(a1)
 local streaks=E.Beam(g,at0,at1,{tex="beam.streaks",color=SHINE,alpha=.25,width=W*1.6,scroll=-6,length=14})
 local swirl=E.Beam(g,at0,at1,{tex="beam.core",color=GOLD,alpha=.4,width=W*2.6,scroll=4,length=24})
 E.Sprite(a0,{tex="flare.big",size={{0,2},{.1,W*7},{1,W*5}},alpha={{0,0},{.8,.3},{1,1}},color=SHINE},T)
 E.Sprite(a0,{tex="star.lens",size=W*4,alpha=.2,color=BUTTERFLY_GOLD,spin={200,200}},T)
 local rings=E.Stream(a0,{tex="ring.thin",orient="flat",dir=Enum.NormalId.Front,size={{0,W*1.4},{1,W*3.2}},alpha={{0,.2},{1,1}},
  color=SHINE,life={L/160,L/160},speed={160,160}},14)
 E.Sprite(a1,{tex="flare.burst2",size={{0,3},{.2,W*6},{1,W*5}},alpha={{0,0},{.85,.3},{1,1}},color=GOLD},T)
 local sparks=E.Stream(a1,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,AMBER}},life={.2,.45},speed={20,45},spread=70,
  dir=Enum.NormalId.Back,drag=2},50)
 E.Light(g,a0,GOLD,30,6,T+.1)
 E.Light(g,a1,AMBER,20,5,T+.1)
 E.Step(g,function(_,t)
  local grow=math.clamp(t/.07,0,1)
  local fade=math.clamp((t-(T-.18))/.18,0,1)
  local k=grow*(1-fade)*(1+.12*math.sin(t*45))
  core.Size=Vector3.new(L,W*.45*k+.01,W*.45*k+.01)
  mid.Size=Vector3.new(L,W*1.1*k+.01,W*1.1*k+.01)
  outer.Size=Vector3.new(L,W*2.3*k+.01,W*2.3*k+.01)
  streaks.Width0=W*1.6*k streaks.Width1=streaks.Width0
  swirl.Width0=W*2.6*k swirl.Width1=swirl.Width0
  workspace:BulkMoveTo({core,mid,outer},{frame,frame,frame},Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then
   rings.Enabled=false sparks.Enabled=false
   for _,p in ipairs({core,mid,outer})do p.Transparency=1 end
   return false
  end
  return true
 end)
 E.After(g,T+.6,function()g:Destroy()end)
end

 -- Wild Hunt: every air slice is a crescent ripping across his front before the claw flies
function P.HuntSlice(E,d)
 local g=E.Group("P5HuntSlice")
 local side=(d.Index or 1)%2==1 and 1 or -1
 local base=d.Frame*CFrame.new(0,.5,-3)*CFrame.Angles(0,0,side*.45)*CFrame.Angles(-math.pi/2,0,0)
 local layers=slash(g,22,WHITE,AMBER,{GlowAlpha=.3,Streak=true,StreakColor=GOLD,StreakAlpha=.55})
 E.Step(g,function(_,t)
  local k=math.clamp(t/.08,0,1)
  local parts,cfs={},{}
  place(layers,base*CFrame.Angles(0,0,side*((1-(1-k)^3)*.9-.45)),.8+.35*k,t<.1 and 0 or math.clamp((t-.12)/.18,0,1),parts,cfs)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<.32
 end)
 local a=E.Anchor(g,d.Frame*CFrame.new(0,.5,-6))
 E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,AMBER}},life={.2,.4},speed={20,40},spread=60,dir=Enum.NormalId.Front,drag=2},10)
 E.After(g,.6,function()g:Destroy()end)
end

 -- a shockwave racing out along the floor: a crisp ring and its glow (flat sprites that grow at the wave's speed),
 -- a low wall of light standing on the front, and dust and sparks thrown off it. Look "Dark" is amber and smoke.
function P.Shockwave(E,d)
 local g=E.Group("P5Shockwave")
 local speed,range=d.Speed or 120,d.Range or 60
 local T=range/speed
 local dark=d.Look=="Dark"
 local inward=d.Inward==true
 local edge,glow=dark and AMBER or SHINE,dark and Color3.fromRGB(120,60,10) or GOLD
 local floor=E.Ground(d.Pos+UP*3,{d.Boss,g.Folder})
 local c=(floor or d.Pos)+UP*.12
 local a=E.Anchor(g,CFrame.new(c))
 local grow=inward and{{0,range*2},{1,1}}or{{0,1},{1,range*2}}
 E.Sprite(a,{tex="ring.crisp",orient="flat",size=grow,alpha={{0,.05},{.75,.25},{1,1}},color=edge},T)
 E.Sprite(a,{tex="ring.soft",orient="flat",size=inward and{{0,range*2.15},{1,2}}or{{0,2},{1,range*2.15}},alpha={{0,.25},{.7,.45},{1,1}},color=glow},T)
 if not inward then E.Sprite(a,{tex="disc.soft",orient="flat",size={{0,2},{.3,range*.8},{1,range*1.2}},alpha={{0,.55},{1,1}},color=glow},T*.6)end
 local N=math.clamp(math.floor(range/2.5),18,40)
 local segs={}
 for i=1,N do segs[i]=newPart(g,Vector3.new(.35,1,1),edge,.15) end
 local dust={}
 for i=1,6 do
  local an=E.Anchor(g,CFrame.new(c))
  dust[i]={A=an,Ang=(i-1)*math.pi/3+math.random()*.5}
  E.Stream(an,{tex=dark and"smoke"or"star.crisp",light=dark and 0 or 1,size=dark and{{0,2},{1,4}}or{{0,.7},{1,0}},alpha={{0,.4},{1,1}},
   color=dark and{{0,Color3.fromRGB(90,65,30)},{1,VOID}}or{{0,SHINE},{1,GOLD}},life={.25,.5},speed={4,10},spread=40,dir=Enum.NormalId.Top,drag=2},40)
 end
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local r=math.max(inward and range*(1-k)or range*k,.5)
  local h=inward and 2.4 or 2.6*(1-k)+.3
  local len=2*math.pi*r/N*1.08
  local parts,cfs={},{}
  for i,p in ipairs(segs)do
   local ang=(i-1)*math.pi*2/N
   local pos=c+Vector3.new(math.cos(ang)*r,h/2,math.sin(ang)*r)
   p.Size=Vector3.new(.35,h,len)
   p.Transparency=inward and .15+.85*math.clamp((k-.8)/.2,0,1)or .15+.85*k^2
   parts[#parts+1]=p cfs[#cfs+1]=CFrame.lookAt(pos,pos+Vector3.new(-math.sin(ang),0,math.cos(ang)))
  end
  for _,dd in ipairs(dust)do
   parts[#parts+1]=dd.A cfs[#cfs+1]=CFrame.new(c+Vector3.new(math.cos(dd.Ang)*r,.3,math.sin(dd.Ang)*r))
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if k>=1 then
   for _,dd in ipairs(dust)do for _,e in ipairs(dd.A:GetChildren())do if e:IsA("ParticleEmitter")then e.Enabled=false end end end
   for _,p in ipairs(segs)do p.Transparency=1 end
   return false
  end
  return true
 end)
 E.After(g,T+.8,function()g:Destroy()end)
end

 -- Slam: gold gathers into his raised left hand
function P.SlamRaise(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local hand=handOf(d.Boss,"Left")or r
 local T=d.Time or .5
 local g=E.Group("P5SlamRaise")
 local a=E.Anchor(g,handCF(hand))
 E.Sprite(a,{tex="glow.soft",size={{0,1},{.8,8},{1,10}},alpha={{0,.6},{.8,.15},{1,1}},color=GOLD},T+.05)
 E.Sprite(a,{tex="star.lens",size={{0,1},{.85,7},{1,2}},alpha={{0,.4},{.8,0},{1,1}},color=SHINE,spin={90,90}},T+.05)
 local pull=E.Stream(a,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.35},speed={-18,-10},spread=180},70)
 local gather=E.Stream(a,{tex="wind.dash",orient="velocity",size={{0,2.5},{1,1}},alpha={{0,.5},{1,1}},color=GOLD,life={.2,.3},speed={-30,-20},spread=180},24)
 E.Light(g,a,GOLD,18,5,T+.1)
 E.Step(g,function(_,t)
  if not hand.Parent then g:Destroy()return false end
  workspace:BulkMoveTo({a},{handCF(hand)},Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then pull.Enabled=false gather.Enabled=false end
  return t<T+.3
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end

 -- Slam: the impact - a flash, a spiked burst on the floor, glowing cracks, rock thrown up and dust
function P.SlamImpact(E,d)
 local g=E.Group("P5SlamImpact")
 local R=d.Radius or 16
 local c=d.Pos+UP*.15
 local a=E.Anchor(g,CFrame.new(c))
 local m=E.Anchor(g,CFrame.new(c+UP*3))
 E.Sprite(m,{tex="flare.big",size={{0,6},{.12,R*2.4},{1,R*2.8}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.45)
 E.Sprite(a,{tex="burst.spiky",orient="flat",size={{0,3},{.15,R*2.6},{1,R*3}},alpha={{0,0},{.6,.35},{1,1}},color=GOLD},.8)
 E.Emit(m,{tex="smoke",light=0,size={{0,4},{1,10}},alpha={{0,.35},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
  life={.7,1.2},speed={R*.8,R*1.5},spread=75,dir=Enum.NormalId.Top,drag=3},22)
 E.Emit(m,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.4,.9},speed={30,70},spread=60,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,-70,0),drag=1},40)
 debris(E,g,c,10)
 cracks(E,g,c,R*1.4,12,AMBER,1.4)
 E.Light(g,m,GOLD,R*3,10,.6)
 E.After(g,2,function()g:Destroy()end)
end

 -- Viper: the hood - his hands glow, a fanged sigil opens behind him and two eyes light over his head
function P.ViperSpread(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .45
 local g=E.Group("P5ViperSpread")
 local follow={}
 for _,side in ipairs({"Left","Right"})do
  local hand=handOf(d.Boss,side)
  if hand then
   local a=E.Anchor(g,handCF(hand))
   follow[#follow+1]={A=a,H=hand}
   E.Sprite(a,{tex="glow.soft",size={{0,1},{.8,5},{1,6}},alpha={{0,.5},{.8,.2},{1,1}},color=GOLD},T+.05)
   E.Stream(a,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,SHINE},{1,GOLD}},life={.2,.4},speed={2,6},spread=180,drag=1},40)
  end
 end
 local hood=E.Anchor(g,r.CFrame*CFrame.new(0,1.6,1.5))
 E.Sprite(hood,{tex="sigil.lace",orient="flat",dir=Enum.NormalId.Front,size={{0,2},{.3,13},{1,14}},alpha={{0,.7},{.3,.2},{1,1}},color=GOLD,spin={40,40}},T+.1)
 E.Sprite(hood,{tex="glow.soft",size={{0,2},{.3,12},{1,10}},alpha={{0,.7},{.3,.5},{1,1}},color=AMBER},T+.1)
 local eyes={}
 for _,x in ipairs({-.35,.35})do
  local e=E.Anchor(g,r.CFrame*CFrame.new(x,2.6,-.8))
  eyes[#eyes+1]={A=e,X=x}
  E.Sprite(e,{tex="star.glare",size={{0,.5},{.4,3},{1,1}},alpha={{0,0},{1,1}},color=SHINE,rot={0,0}},T)
 end
 E.Step(g,function(_,t)
  if not r.Parent then g:Destroy()return false end
  local parts,cfs={hood},{r.CFrame*CFrame.new(0,1.6,1.5)}
  for _,f in ipairs(follow)do if f.H.Parent then parts[#parts+1]=f.A cfs[#cfs+1]=handCF(f.H)end end
  for _,e in ipairs(eyes)do parts[#parts+1]=e.A cfs[#cfs+1]=r.CFrame*CFrame.new(e.X,2.6,-.8)end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T+.2
 end)
 E.After(g,T+.4,function()g:Destroy()end)
end

 -- Viper: the strike - a golden snake whips out along the lunge, swaying, lit scale by scale as the head passes
function P.ViperThrust(E,d)
 local g=E.Group("P5ViperThrust")
 local T=d.Time or .2
 local v=d.To-d.From
 local len=v.Magnitude
 if len<1 then g:Destroy()return end
 local dir=v.Unit
 local side=dir:Cross(UP)
 side=side.Magnitude>.01 and side.Unit or Vector3.xAxis
 local tip=E.Anchor(g,CFrame.lookAt(d.From,d.To))
 E.Stream(tip,{tex="wind.dash",orient="velocity",size={{0,5},{1,10}},alpha={{0,.3},{1,1}},color=SHINE,life={.1,.16},speed={60,90},
  dir=Enum.NormalId.Back,spread=5},70)
 E.Sprite(tip,{tex="star.glare",size={{0,6},{1,14}},alpha={{0,0},{1,.5}},color=GOLD,rot={0,0}},T+.05)
 E.Sprite(tip,{tex="glow.soft",size={{0,6},{1,8}},alpha={{0,.3},{1,1}},color=AMBER},T+.1)
 local N=math.clamp(math.floor(len/1.1),12,60)
 local scales={}
 for i=1,N do
  local p=newPart(g,Vector3.one,i%2==0 and GOLD or AMBER,.1)
  p.Shape=Enum.PartType.Ball
  scales[i]=p
 end
 local sheen=newPart(g,Vector3.new(2.6,2.6,.1),BUTTERFLY_GOLD,.65)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local head=len*(1-(1-k)^2)
  local parts,cfs={tip},{CFrame.lookAt(d.From+dir*head,d.From+dir*(head+1))}
  for i,p in ipairs(scales)do
   local f=(i-1)/(N-1)
   local along=len*f
   local born=along<=head+.5
   local fade=math.clamp((t-T-.05-f*.15)/.35,0,1)
   local size=(1.1+f*1.1)*(1-fade*.6)
   p.Size=Vector3.one*(born and size or .01)
   p.Transparency=born and(.1+.9*fade)or 1
   local sway=math.sin(f*math.pi*5-t*12)*2.6*(.4+.6*f)
   parts[#parts+1]=p cfs[#cfs+1]=CFrame.new(d.From+dir*along+side*sway+UP*(.3*math.sin(f*9)))
  end
  sheen.Size=Vector3.new(2.6,2.6,math.max(head,.1))
  sheen.Transparency=.65+.35*math.clamp((t-T)/.4,0,1)
  local mid=d.From+dir*head*.5
  parts[#parts+1]=sheen cfs[#cfs+1]=CFrame.lookAt(mid,mid+dir)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T+.65
 end)
 local floor=E.Ground(d.From+UP*2,{d.Boss,g.Folder})
 if floor then
  local a0=Vector3.new(d.From.X,floor.Y+.05,d.From.Z)
  local b0=Vector3.new(d.To.X,floor.Y+.05,d.To.Z)
  local groove=newPart(g,Vector3.new(1,.06,(b0-a0).Magnitude),AMBER,.1)
  groove.CFrame=CFrame.lookAt((a0+b0)/2,b0)
  E.Tween(groove,.5,{Transparency=1},nil,nil,.3)
 end
 E.After(g,T+.9,function()g:Destroy()end)
end

 -- Viper: whoever is caught is wrapped in a ring of gold while he drags them
function P.ViperCatch(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local g=E.Group("P5ViperCatch")
 local a=E.Anchor(g,vr.CFrame)
 E.Sprite(a,{tex="ring.dots",orient="flat",size={{0,8},{.2,5},{1,5}},alpha={{0,.6},{.2,.1},{1,1}},color=GOLD,spin={240,240}},.5)
 E.Sprite(a,{tex="glow.soft",size=6,alpha={{0,.5},{1,1}},color=AMBER},.5)
 E.Step(g,function(_,t)
  if vr.Parent then a.CFrame=vr.CFrame end
  return t<.5
 end)
 E.After(g,.7,function()g:Destroy()end)
end

 -- Viper: the fangs close on the end of the drag
function P.ViperBite(E,d)
 local g=E.Group("P5ViperBite")
 local cam=workspace.CurrentCamera
 local to=cam and Vector3.new(cam.CFrame.X,d.Pos.Y,cam.CFrame.Z)or d.Pos+Vector3.zAxis
 if (to-d.Pos).Magnitude<.1 then to=d.Pos+Vector3.zAxis end
 jaws(E,g,CFrame.lookAt(d.Pos,to),12,GOLD,4)
 E.After(g,.9,function()g:Destroy()end)
end

 -- Horrifying Ground: the blade raised over him glints and a sigil opens at his feet
function P.StabTell(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .4
 local g=E.Group("P5StabTell")
 local blade=bladeOf(d.Boss)
 local h=E.Anchor(g,blade.CFrame)
 E.Sprite(h,{tex="star.glare",size={{0,1},{.8,9},{1,1}},alpha={{0,.3},{.8,0},{1,1}},color=AMBER},T)
 local motes=E.Stream(h,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,AMBER}},life={.25,.4},speed={-10,-5},spread=180},40)
 local floor=E.Ground(r.Position,{d.Boss,g.Folder})
 local feet=E.Anchor(g,CFrame.new((floor or r.Position-UP*3)+UP*.1))
 E.Sprite(feet,{tex="sigil.mandala2",orient="flat",size={{0,1},{.4,10},{1,11}},alpha={{0,.8},{.4,.3},{1,1}},color=AMBER,spin={-90,-90}},T+.3)
 E.Step(g,function(_,t)
  if blade.Parent then h.CFrame=blade.CFrame end
  if t>=T then motes.Enabled=false end
  return t<T+.2
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end

 -- Horrifying Ground: the stab - a pillar of light where the blade goes in, a dark-gold burst and cracks
function P.GroundStab(E,d)
 local g=E.Group("P5GroundStab")
 local c=d.Pos+UP*.12
 local a=E.Anchor(g,CFrame.new(c))
 local m=E.Anchor(g,CFrame.new(c+UP*2))
 local pillar=newPart(g,Vector3.new(40,3,3),AMBER,.3)
 local core=newPart(g,Vector3.new(40,1,1),WHITE,0)
 pillar.Shape=Enum.PartType.Cylinder core.Shape=Enum.PartType.Cylinder
 local up=CFrame.new(c+UP*20)*CFrame.Angles(0,0,math.pi/2)
 pillar.CFrame=up core.CFrame=up
 E.Tween(pillar,.45,{Size=Vector3.new(46,.1,.1),Transparency=1})
 E.Tween(core,.35,{Size=Vector3.new(46,.05,.05),Transparency=1})
 E.Sprite(m,{tex="flare.burst2",size={{0,3},{.2,20},{1,24}},alpha={{0,0},{.5,.35},{1,1}},color=AMBER},.4)
 E.Sprite(a,{tex="burst.spiky2",orient="flat",size={{0,2},{.2,22},{1,26}},alpha={{0,0},{.6,.3},{1,1}},color=Color3.fromRGB(200,110,20)},.7)
 E.Emit(m,{tex="star.crisp",size={{0,1},{1,0}},color={{0,SHINE},{1,AMBER}},life={.3,.7},speed={20,50},spread=50,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,-60,0)},26)
 E.Emit(a,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.4},{1,1}},color={{0,Color3.fromRGB(90,65,30)},{1,VOID}},life={.6,1},speed={14,26},
  spread=85,dir=Enum.NormalId.Top,drag=3},18)
 cracks(E,g,c,18,9,Color3.fromRGB(200,110,20),1.3)
 E.Light(g,m,AMBER,30,8,.5)
 E.After(g,1.8,function()g:Destroy()end)
end

 -- Night Tearer: he readies himself in a dark aura, embers rising and the wind pulled in, sigils under him
function P.TearerReady(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 2.3
 local g=E.Group("P5TearerReady")
 local a=E.Anchor(g,r.CFrame)
 local floor=E.Ground(r.Position,{d.Boss,g.Folder})
 local feet=E.Anchor(g,CFrame.new((floor or r.Position-UP*3)+UP*.1))
 local aura=E.Stream(a,{tex="smoke",light=0,size={{0,3},{1,7}},alpha={{0,.5},{1,1}},color={{0,VOID},{1,Color3.fromRGB(40,25,5)}},
  life={.5,.9},speed={2,5},spread=180,drag=1.5,accel=Vector3.new(0,4,0)},40)
 local embers=E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,AMBER}},life={.6,1},speed={3,8},spread=180,
  accel=Vector3.new(0,6,0)},35)
 local gather=E.Stream(a,{tex="wind.dash",orient="velocity",size={{0,3},{1,1}},alpha={{0,.6},{1,1}},color=GOLD,life={.25,.35},
  speed={-40,-25},spread=180},30)
 E.Sprite(feet,{tex="sigil.mandala2",orient="flat",size={{0,2},{.25,22},{1,24}},alpha={{0,.8},{.25,.35},{.9,.4},{1,1}},color=AMBER,spin={-45,-45}},T)
 E.Sprite(feet,{tex="ring.ticked",orient="flat",size={{0,2},{.25,30},{1,31}},alpha={{0,.8},{.25,.5},{.9,.55},{1,1}},color=GOLD,spin={25,25}},T)
 E.Light(g,a,AMBER,24,3,T)
 E.Step(g,function(_,t)
  if r.Parent then a.CFrame=r.CFrame end
  if t>=T then aura.Enabled=false embers.Enabled=false gather.Enabled=false end
  return t<T+.5
 end)
 E.After(g,T+1,function()g:Destroy()end)
end

 -- Night Tearer: the charge - the lane ahead is marked on the floor (it runs out to the wall's full range) while
 -- the blade drinks in the light
function P.TearerCharge(E,d)
 local g=E.Group("P5TearerCharge")
 local T,L,H=d.Time or 1.4,d.Range or 300,d.HalfWidth or 38
 local lane=d.Frame
 local floor=E.Ground(lane.Position+UP*4,{d.Boss,g.Folder})
 local base=CFrame.new(Vector3.new(lane.X,(floor and floor.Y or lane.Y)+.07,lane.Z))*lane.Rotation
 local fill=newPart(g,Vector3.new(H*2,.05,.1),CRIMSON:Lerp(AMBER,.5),.85)
 local edges={newPart(g,Vector3.new(.7,.07,.1),AMBER,.05),newPart(g,Vector3.new(.7,.07,.1),AMBER,.05)}
 local glows={newPart(g,Vector3.new(3,.06,.1),GOLD,.55),newPart(g,Vector3.new(3,.06,.1),GOLD,.55)}
 local blade=bladeOf(d.Boss)
 local b=blade and E.Anchor(g,blade.CFrame)
 local pull
 if b then
  E.Sprite(b,{tex="glow.soft",size={{0,2},{.9,14},{1,18}},alpha={{0,.6},{.9,.15},{1,1}},color=GOLD},T+.05)
  E.Sprite(b,{tex="star.lens",size={{0,2},{.9,12},{1,4}},alpha={{0,.4},{.9,0},{1,1}},color=SHINE,spin={120,120}},T+.05)
  pull=E.Stream(b,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.35},speed={-28,-16},spread=180},90)
  E.Light(g,b,GOLD,26,4,T+.2)
 end
 E.Step(g,function(_,t)
  local k=math.clamp(t/(T*.45),0,1)
  local len=math.max(L*(1-(1-k)^3),.1)
  fill.Size=Vector3.new(H*2,.05,len)
  fill.Transparency=.86-.1*(.5+.5*math.sin(t*14))
  local parts,cfs={fill},{base*CFrame.new(0,0,-len/2)}
  for i,sgn in ipairs({-1,1})do
   edges[i].Size=Vector3.new(.7,.07,len) glows[i].Size=Vector3.new(3,.06,len)
   local cf=base*CFrame.new(sgn*H,.01,-len/2)
   parts[#parts+1]=edges[i] cfs[#cfs+1]=cf
   parts[#parts+1]=glows[i] cfs[#cfs+1]=cf
  end
  if b and blade.Parent then parts[#parts+1]=b cfs[#cfs+1]=blade.CFrame end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then
   if pull then pull.Enabled=false end
   return false
  end
  return true
 end)
 E.Tween(fill,.5,{Transparency=1},nil,nil,T+.3)
 for i=1,2 do
  E.Tween(edges[i],.6,{Transparency=1},nil,nil,T+1.6)
  E.Tween(glows[i],.5,{Transparency=1},nil,nil,T+1.4)
 end
 E.After(g,T+2.6,function()g:Destroy()end)
end

 -- Night Tearer: the swipe - a huge crescent across his front, then a towering wall of gold light bowed forward
 -- rides down the lane, dust and sparks thrown off its foot, and shrinks away at the end of its range
function P.TearerSwipe(E,d)
 local g=E.Group("P5TearerSwipe")
 local lane=d.Frame
 local L,H,Ht,speed=d.Range or 300,d.HalfWidth or 38,d.Height or 34,d.Speed or 170
 local T=L/speed
 local floor=E.Ground(lane.Position+UP*4,{d.Boss,g.Folder})
 local base=CFrame.new(Vector3.new(lane.X,floor and floor.Y or lane.Y,lane.Z))*lane.Rotation
 local layers=slash(g,H*1.6,WHITE,GOLD,{GlowAlpha=.25,Streak=true,StreakColor=SHINE,StreakAlpha=.5})
 local sw=base*CFrame.new(0,4,-6)*CFrame.Angles(-math.pi/2,0,0)
 local wall=E.Anchor(g,base)
 local bow=H*.5
 local function ends(y)  -- each end's X axis points down the lane (the bow), its Y axis up (the wall's height)
  return E.Attach(wall,CFrame.fromMatrix(Vector3.new(-H,y,0),Vector3.new(0,0,-1),UP)),
   E.Attach(wall,CFrame.fromMatrix(Vector3.new(H,y,0),Vector3.new(0,0,-1),UP))
 end
 local l1,r1=ends(Ht/2)
 local body=E.Beam(g,l1,r1,{tex="beam.curtain",color={{0,SHINE},{.5,GOLD},{1,SHINE}},alpha=.1,width=Ht,curve0=bow,curve1=-bow,
  segments=30,face=false,mode=Enum.TextureMode.Stretch,scroll=1.2,brightness=2})
 local haze=E.Beam(g,l1,r1,{tex="beam.wisp",color=AMBER,alpha=.35,width=Ht*1.25,curve0=bow,curve1=-bow,segments=30,face=false,
  scroll=-2,length=30})
 local l2,r2=ends(1.5)
 local foot=E.Beam(g,l2,r2,{tex="beam.core",color=WHITE,alpha=0,width=3.5,curve0=bow,curve1=-bow,segments=30,face=false,brightness=3})
 local feet={}
 for i=1,7 do
  local x=((i-1)/6*2-1)*H
  local an=E.Anchor(g,base)
  feet[i]={A=an,X=x}
  E.Stream(an,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
   life={.5,.9},speed={8,16},spread=50,dir=Enum.NormalId.Top,drag=2},20)
  E.Stream(an,{tex="star.crisp",size={{0,1},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.6},speed={20,40},spread=40,dir=Enum.NormalId.Top,
   accel=Vector3.new(0,-50,0)},25)
 end
 E.Light(g,wall,GOLD,60,8,nil)
 local m=E.Anchor(g,base*CFrame.new(0,6,-6))
 E.Sprite(m,{tex="flare.big",size={{0,10},{.12,H*2.4},{1,H*2.8}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.5)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local wf=base*CFrame.new(0,0,-L*k)
  local parts,cfs={wall},{wf}
  for _,f in ipairs(feet)do
   parts[#parts+1]=f.A cfs[#cfs+1]=wf*CFrame.new(f.X,.5,-(1-(f.X/H)^2)*bow*.75)
  end
  if t<.4 then
   local kk=math.clamp(t/.1,0,1)
   place(layers,sw*CFrame.Angles(0,0,(1-(1-kk)^3)*1.4-.7),.8+.3*kk,t<.12 and 0 or math.clamp((t-.14)/.22,0,1),parts,cfs)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  local fade=math.clamp((k-.85)/.15,0,1)
  if fade>0 then
   body.Width0=Ht*(1-fade) body.Width1=body.Width0
   haze.Width0=Ht*1.25*(1-fade) haze.Width1=haze.Width0
   foot.Width0=3.5*(1-fade) foot.Width1=foot.Width0
  end
  if k>=1 then
   for _,f in ipairs(feet)do for _,e in ipairs(f.A:GetChildren())do if e:IsA("ParticleEmitter")then e.Enabled=false end end end
   g:Fade(.4)
   return false
  end
  return true
 end)
 E.After(g,T+2,function()g:Destroy()end)
end

 -- a warning floating over a player: Kind "Lethal" is red - this takes lives (Lives says how many) - with a red ring
 -- at their feet and, for that player, red at the edges of the screen; Kind "Jump" is a gold JUMP
local LETHAL=Color3.fromRGB(255,36,52)
function P.Warn(E,d)
 local vr=rootOf(d.Victim)
 local head=d.Victim and d.Victim:FindFirstChild("Head")
 if not vr then return end
 local T=d.Time or 1
 local lethal=d.Kind~="Jump"
 local tone=lethal and LETHAL or BUTTERFLY_GOLD
 local g=E.Group("P5Warn")
 local bill=Instance.new("BillboardGui")
 bill.Adornee=head or vr bill.AlwaysOnTop=true bill.LightInfluence=0 bill.Size=UDim2.fromScale(7,2.6)
 bill.StudsOffsetWorldSpace=Vector3.new(0,3.6,0) bill.MaxDistance=400
 local scale=Instance.new("UIScale")scale.Scale=.4 scale.Parent=bill
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1)label.BackgroundTransparency=1 label.Font=Enum.Font.GothamBlack label.TextScaled=true
 label.TextColor3=tone label.TextStrokeColor3=lethal and Color3.fromRGB(40,0,4)or Color3.fromRGB(60,35,0)label.TextStrokeTransparency=0
 local lives=tonumber(d.Lives)
 label.Text=lethal and("! LETHAL"..(lives and("  -"..lives.." \u{2665}")or"").." !")or"\u{25B2} JUMP! \u{25B2}"
 label.Parent=bill
 bill.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")  -- a BillboardGui draws from a GUI container
 E.Tween(scale,.18,{Scale=1},Enum.EasingStyle.Back)
 local feet=E.Anchor(g,CFrame.new(vr.Position-UP*2.9))
 E.Sprite(feet,{tex="ring.crisp",orient="flat",size={{0,9},{.2,6},{1,6}},alpha={{0,.6},{.2,.05},{.85,.15},{1,1}},color=tone,spin={90,90}},T)
 E.Sprite(feet,{tex="glow.soft",orient="flat",size=7,alpha={{0,.5},{.8,.6},{1,1}},color=tone},T)
 local edges
 if lethal and d.Victim==Players.LocalPlayer.Character then
  local gui=Instance.new("ScreenGui")gui.Name="P5LethalEdge" gui.IgnoreGuiInset=true gui.DisplayOrder=60
  for i,spec in ipairs({{UDim2.fromScale(1,.22),UDim2.fromScale(0,0),90},{UDim2.fromScale(1,.22),UDim2.fromScale(0,.78),-90},
   {UDim2.fromScale(.16,1),UDim2.fromScale(0,0),0},{UDim2.fromScale(.16,1),UDim2.fromScale(.84,0),180}})do
   local f=Instance.new("Frame")f.Size=spec[1]f.Position=spec[2]f.BackgroundColor3=LETHAL f.BorderSizePixel=0
   local grad=Instance.new("UIGradient")grad.Rotation=spec[3]grad.Transparency=NumberSequence.new(.35,1)grad.Parent=f
   f.Parent=gui
  end
  gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
  edges=gui
  g.Conns[#g.Conns+1]=gui.Destroying:Connect(function()end)
 end
 E.Step(g,function(_,t)
  if vr.Parent then feet.CFrame=CFrame.new(vr.Position-UP*2.9)end
  local pulse=.5+.5*math.sin(t*(lethal and 18 or 24))
  label.TextTransparency=.15*pulse
  if edges then for _,f in ipairs(edges:GetChildren())do f.BackgroundTransparency=.1+.35*pulse end end
  return t<T
 end)
 E.After(g,T,function()if edges then edges:Destroy()end bill:Destroy() g:Destroy()end)
end

 -- Horrifying Ground: the ring the cage will rise from, marked on the floor
function P.CageWarn(E,d)
 local g=E.Group("P5CageWarn")
 local R,T=d.Radius or 13,d.Time or .7
 local floor=E.Ground(d.Pos+UP*3,{g.Folder})
 local a=E.Anchor(g,CFrame.new((floor or d.Pos)+UP*.12))
 local warnColor=Color3.fromRGB(255,96,40)
 E.Sprite(a,{tex="ring.thick",orient="flat",size={{0,R*2.8},{.25,R*2.1},{1,R*2.1}},alpha={{0,1},{.25,.1},{.85,0},{1,.4}},color=warnColor,spin={30,30}},T+.05)
 E.Sprite(a,{tex="ring.ticked",orient="flat",size={{0,R*1.4},{.25,R*2.3},{1,R*2.3}},alpha={{0,1},{.25,.3},{1,.5}},color=GOLD,spin={-60,-60}},T+.05)
 E.Sprite(a,{tex="disc.soft",orient="flat",size={{0,1},{1,R*2}},alpha={{0,.85},{1,.55}},color=warnColor},T)
 E.After(g,T+.4,function()g:Destroy()end)
end

 -- one crystal spike standing on +Y from its base: a pair of crossed fins, each a body and a pointed top
local SPIKE_TONES={GOLD,Color3.fromRGB(214,138,24),Color3.fromRGB(255,224,140),Color3.fromRGB(240,170,50)}
local function crystal(list,g,base,W,H,tone)
 local L=H*.32
 local T=W*.24
 for _,yaw in ipairs({0,math.pi/2})do
  local turn=base*CFrame.Angles(0,yaw,0)
  local body=newPart(g,Vector3.new(W,L,T),tone,0)body.Material=Enum.Material.Metal body.Reflectance=.2
  list[#list+1]={P=body,O=turn*CFrame.new(0,L/2,0)}
  for _,s in ipairs({-1,1})do
   local w=Instance.new("WedgePart")
   w.Anchored=true w.CanCollide=false w.CanQuery=false w.CanTouch=false w.CastShadow=false
   w.Size=Vector3.new(T,H-L,W/2)w.Color=tone w.Material=Enum.Material.Metal w.Reflectance=.2 w.CFrame=HIDDEN w.Parent=g.Folder
   list[#list+1]={P=w,O=turn*CFrame.new(s*W/4,L+(H-L)/2,0)*CFrame.Angles(0,-s*math.pi/2,0)}
  end
 end
 local seam=newPart(g,Vector3.new(W*.12,H*.8,W*.12),SHINE,.15)
 list[#list+1]={P=seam,O=base*CFrame.new(0,H*.4,0)}
end
 -- the shapes the cage is made of: every spike in a cage gets a different one
local SHAPES={
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.12,0,0),2.6,r:NextNumber(20,26),t)end,  -- lance: one tall spear
 function(l,g,r,t)crystal(l,g,CFrame.new(-1.2,0,0)*CFrame.Angles(-.1,0,.25),2.4,r:NextNumber(16,20),t) crystal(l,g,CFrame.new(1.3,0,0)*CFrame.Angles(-.05,0,-.3),2,r:NextNumber(9,12),t)end,  -- twin
 function(l,g,r,t)for i=-1,1 do crystal(l,g,CFrame.new(i*1.6,0,0)*CFrame.Angles(-.15,0,-i*.38),2.1,i==0 and 17 or 12,t)end end,  -- fan
 function(l,g,r,t)crystal(l,g,CFrame.new(),2.8,14,t) for i=1,4 do local a=i*math.pi/2+.4 crystal(l,g,CFrame.new(math.cos(a)*2.2,0,math.sin(a)*2.2)*CFrame.Angles(math.sin(a)*.4,0,-math.cos(a)*.4),1.4,r:NextNumber(5,8),t)end end,  -- crown
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.45,0,.1),4.6,13,t) crystal(l,g,CFrame.new(2.4,0,1)*CFrame.Angles(0,0,-.5),1.4,5,t)end,  -- shard: thick and leaning
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.08,0,0),1.9,13,t) crystal(l,g,CFrame.new(0,12.4,-.6)*CFrame.Angles(-.5,0,0),1.5,10,t)end,  -- thorn: kinked
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.75,0,0),2.5,21,t)end,  -- hook: arches over the cage
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.1,0,.42),2.2,18,t) crystal(l,g,CFrame.Angles(-.1,0,-.42),2.2,18,t)end,  -- cross
 function(l,g,r,t)for i=1,5 do crystal(l,g,CFrame.new(r:NextNumber(-2,2),0,r:NextNumber(-2,2))*CFrame.Angles(r:NextNumber(-.4,.1),0,r:NextNumber(-.4,.4)),1.2,r:NextNumber(5,10),t)end end,  -- cluster
 function(l,g,r,t)crystal(l,g,CFrame.new(),3.4,10,t) crystal(l,g,CFrame.new(0,0,0)*CFrame.Angles(0,.8,0)*CFrame.new(0,9.6,0)*CFrame.Angles(-.2,0,0),2.2,10,t)end,  -- tower: stacked
}
local function backOut(t)local c1=1.6 local c3=c1+1 return 1+c3*(t-1)^3+c1*(t-1)^2 end

 -- Horrifying Ground: the cage - a spike out of every point, each of them a different shape and tone, leaning in
 -- over the one inside; they rise in turn, stand, then sink and shatter
function P.SpikeCage(E,d)
 local g=E.Group("P5SpikeCage")
 local rng=Random.new(d.Seed or 1)
 local hold=d.Hold or 2
 local order={}
 for i=1,#SHAPES do order[i]=i end
 for i=#order,2,-1 do local j=rng:NextInteger(1,i) order[i],order[j]=order[j],order[i]end
 local spikes={}
 for i,point in ipairs(d.Points or{})do
  local inward=Vector3.new(d.Pos.X-point.X,0,d.Pos.Z-point.Z)
  inward=inward.Magnitude>.1 and inward.Unit or Vector3.zAxis
  local base=CFrame.lookAt(point,point+inward)*CFrame.Angles(0,rng:NextNumber(-.3,.3),0)
  local list={}
  SHAPES[order[(i-1)%#order+1]](list,g,rng,SPIKE_TONES[rng:NextInteger(1,#SPIKE_TONES)])
  local height=0
  for _,p in ipairs(list)do height=math.max(height,p.O.Y+p.P.Size.Y)end
  spikes[i]={List=list,Base=base,Delay=(i-1)*.035,Height=height+2,Point=point}
  local a=E.Anchor(g,CFrame.new(point+UP*.2))
  E.After(g,(i-1)*.035,function()
   E.Sprite(a,{tex="burst.spiky",orient="flat",size={{0,2},{.2,9},{1,10}},alpha={{0,0},{.6,.4},{1,1}},color=GOLD},.5)
   E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.6},speed={18,36},spread=40,dir=Enum.NormalId.Top,
    accel=Vector3.new(0,-60,0)},10)
   E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,5}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
    life={.5,.8},speed={6,12},spread=70,dir=Enum.NormalId.Top,drag=2},6)
  end)
 end
 local center=E.Anchor(g,CFrame.new(d.Pos+UP*3))
 E.Light(g,center,GOLD,40,4,hold+.6)
 local finish=#spikes*.035+.14+hold+.35
 local shattered={}
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for i,s in ipairs(spikes)do
   local u=t-s.Delay
   local y,fade=-s.Height,0
   if u>=0 then
    if u<.14 then y=-s.Height*(1-backOut(u/.14))
    elseif u<.14+hold then y=math.sin(u*40)*.03
    else
     local k=math.clamp((u-.14-hold)/.35,0,1)
     y=-s.Height*.6*k*k fade=k
     if not shattered[i]then
      shattered[i]=true
      local at=E.Anchor(g,CFrame.new(s.Point+UP*6))
      E.Emit(at,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.35,.7},speed={8,18},spread=180,accel=Vector3.new(0,-40,0),drag=1.5},8)
     end
    end
   end
   local frame=s.Base*CFrame.new(0,y,0)
   for _,p in ipairs(s.List)do
    parts[#parts+1]=p.P cfs[#cfs+1]=frame*p.O
    if fade>0 then p.P.Transparency=fade end
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=finish then g:Destroy()return false end
  return true
 end)
 E.After(g,finish+1,function()g:Destroy()end)
end

 -- Viper: the lane he is about to strike down, lit yellow on the floor with chevrons running along it
function P.ViperTell(E,d)
 local g=E.Group("P5ViperTell")
 local T=d.Time or .6
 local v=d.To-d.From
 local len=v.Magnitude
 if len<1 then g:Destroy()return end
 local dir=v.Unit
 local W=d.Width or 10
 local floor=E.Ground(d.From+UP*2,{d.Boss,g.Folder})
 local y=(floor and floor.Y or d.From.Y-3)+.07
 local a0=Vector3.new(d.From.X,y,d.From.Z)
 local base=CFrame.lookAt(a0,a0+dir)
 local warnColor=Color3.fromRGB(255,96,40)
 local fill=newPart(g,Vector3.new(W*2,.05,len),BUTTERFLY_GOLD,.5)  -- a yellow lane
 fill.CFrame=base*CFrame.new(0,0,-len/2)
 for _,sgn in ipairs({-1,1})do
  local e=newPart(g,Vector3.new(.8,.07,len),SHINE,0)
  e.CFrame=base*CFrame.new(sgn*W,.01,-len/2)
  E.Tween(e,.25,{Transparency=1},nil,nil,T)
 end
 local chevrons={}
 for i=1,5 do
  local c=E.Anchor(g,base)
  E.Sprite(c,{tex="reticle",orient="flat",size=W*.9,alpha={{0,.2},{1,.6}},color=SHINE,rot={0,0}},T)
  chevrons[i]=c
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for i,c in ipairs(chevrons)do
   local f=((i-1)/5+t*1.6)%1
   parts[#parts+1]=c cfs[#cfs+1]=base*CFrame.new(0,.05,-len*f)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  fill.Transparency=.55-.15*(.5+.5*math.sin(t*16))
  return t<T
 end)
 E.Tween(fill,.25,{Transparency=1},nil,nil,T)
 E.After(g,T+.4,function()g:Destroy()end)
end

 -- Night Tearer: the charge. The lane ahead is marked red to its full reach; a sphere of gold gathers in front of
 -- him - rings closing on it, light streaming in, the ground's dust lifting toward it - growing until he lets go
function P.TearerCharge(E,d)
 local g=E.Group("P5TearerCharge")
 local T,L,H=d.Time or 1.7,d.Range or 300,d.HalfWidth or 11
 local lane=d.Frame
 local floor=E.Ground(lane.Position+UP*4,{d.Boss,g.Folder})
 local base=CFrame.new(Vector3.new(lane.X,(floor and floor.Y or lane.Y)+.07,lane.Z))*lane.Rotation
 local fill=newPart(g,Vector3.new(H*2,.05,.1),LETHAL,.8)
 local edges={newPart(g,Vector3.new(.8,.07,.1),LETHAL,.05),newPart(g,Vector3.new(.8,.07,.1),LETHAL,.05)}
 local glows={newPart(g,Vector3.new(3.4,.06,.1),CRIMSON,.55),newPart(g,Vector3.new(3.4,.06,.1),CRIMSON,.55)}
  -- the sphere
 local o=d.Origin or (lane*CFrame.new(0,4,-4)).Position
 local orb=E.Anchor(g,CFrame.lookAt(o,o+lane.LookVector))
 local core=newPart(g,Vector3.one,WHITE,0) core.Shape=Enum.PartType.Ball
 local shell=newPart(g,Vector3.one,BUTTERFLY_GOLD,.45) shell.Shape=Enum.PartType.Ball
 local halo=newPart(g,Vector3.one,AMBER,.8) halo.Shape=Enum.PartType.Ball
 E.Sprite(orb,{tex="glow.soft",size={{0,2},{.9,H*2.6},{1,H*3}},alpha={{0,.6},{.9,.2},{1,1}},color=GOLD},T+.05)
 E.Sprite(orb,{tex="star.lens",size={{0,2},{.9,H*2.2},{1,H}},alpha={{0,.4},{.9,0},{1,1}},color=SHINE,spin={140,140}},T+.05)
 E.Sprite(orb,{tex="glow.rays",size={{0,4},{.9,H*3.4},{1,H*3.6}},alpha={{0,.6},{.9,.35},{1,1}},color=AMBER,spin={-60,-60}},T+.05)
 local rings=E.Stream(orb,{tex="ring.thin",orient="flat",dir=Enum.NormalId.Front,size={{0,H*2.6},{1,3}},alpha={{0,.8},{.6,.2},{1,1}},color=SHINE,
  life={.45,.45},speed={.001,.001}},5)
 local pull=E.Stream(orb,{tex="wind.dash",orient="velocity",size={{0,8},{1,2}},alpha={{0,.45},{1,1}},color=GOLD,life={.4,.5},speed={-110,-70},spread=180},80)
 local motes=E.Stream(orb,{tex="star.tiny",size={{0,.9},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.45},speed={-34,-22},spread=180},90)
 local dust=E.Anchor(g,base)
 local lift=E.Stream(dust,{tex="smoke",light=0,size={{0,3},{1,6}},alpha={{0,.55},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
  life={.8,1.3},speed={3,7},spread=80,dir=Enum.NormalId.Top,accel=Vector3.new(0,6,0)},18)
 local stones=E.Stream(dust,{tex="star.crisp",size={{0,.6},{1,.3}},color={{0,AMBER},{1,GOLD}},life={.8,1.2},speed={2,5},spread=90,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,10,0)},20)
 E.Sprite(dust,{tex="sigil.mandala",orient="flat",size={{0,4},{.3,26},{1,30}},alpha={{0,.8},{.3,.4},{1,.6}},color=AMBER,spin={-70,-70}},T)
 local light=E.Light(g,orb,GOLD,40,1)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local len=math.max(L*(1-(1-math.clamp(t/(T*.4),0,1))^3),.1)
  fill.Size=Vector3.new(H*2,.05,len)
  fill.Transparency=.84-.12*(.5+.5*math.sin(t*16))
  local parts,cfs={fill},{base*CFrame.new(0,0,-len/2)}
  for i,sgn in ipairs({-1,1})do
   edges[i].Size=Vector3.new(.8,.07,len) glows[i].Size=Vector3.new(3.4,.06,len)
   local cf=base*CFrame.new(sgn*H,.01,-len/2)
   parts[#parts+1]=edges[i] cfs[#cfs+1]=cf
   parts[#parts+1]=glows[i] cfs[#cfs+1]=cf
  end
  local throb=1+.08*math.sin(t*30)
  core.Size=Vector3.one*(.5+H*.45*k)*throb
  shell.Size=Vector3.one*(1+H*.8*k)*throb
  halo.Size=Vector3.one*(1.5+H*1.2*k)
  local at=CFrame.new(o)
  parts[#parts+1]=core cfs[#cfs+1]=at
  parts[#parts+1]=shell cfs[#cfs+1]=at
  parts[#parts+1]=halo cfs[#cfs+1]=at
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  light.Brightness=1+8*k
  if t>=T then
   rings.Enabled=false pull.Enabled=false motes.Enabled=false lift.Enabled=false stones.Enabled=false
   for _,p in ipairs({core,shell,halo})do p.Transparency=1 end
   return false
  end
  return true
 end)
 E.Tween(fill,.4,{Transparency=1},nil,nil,T+.8)
 for i=1,2 do
  E.Tween(edges[i],.5,{Transparency=1},nil,nil,T+1.6)
  E.Tween(glows[i],.4,{Transparency=1},nil,nil,T+1.4)
 end
 E.After(g,T+2.4,function()g:Destroy()end)
end

 -- Night Tearer: the beam. A white-hot core in gold and amber sheaths and a crimson haze, energy streaming down it,
 -- rings racing along it, shock rings bursting off the muzzle, a glowing trench and rubble along the floor under it
 -- and an explosion rolling at its tip; it shoots out to full reach in Grow seconds, roars, then thins away
function P.TearerBeam(E,d)
 local g=E.Group("P5TearerBeam")
 local dir=d.Dir
 local L,T,R,G=d.Range or 400,d.Time or 2.2,d.Radius or 26,d.Grow or .22
 local o=d.Origin
  -- the hot core is solid; everything around it is soft layered light (camera-facing beams), so the edges glow
  -- instead of ending in a hard tube
 local core=newPart(g,Vector3.new(.1,R*.45,R*.45),WHITE,0)
 core.Shape=Enum.PartType.Cylinder
 local a0=E.Anchor(g,CFrame.lookAt(o,o+dir))
 local a1=E.Anchor(g,CFrame.lookAt(o,o+dir))
 local at0,at1=E.Attach(a0),E.Attach(a1)
 local layers={
  {B=E.Beam(g,at0,at1,{tex="beam.core",color=WHITE,alpha=0,width=R*.95,brightness=4,length=60,scroll=4}),W=R*.95},
  {B=E.Beam(g,at0,at1,{tex="beam.core",color=BUTTERFLY_GOLD,alpha=.1,width=R*1.6,brightness=2,length=90,scroll=7}),W=R*1.6},
  {B=E.Beam(g,at0,at1,{tex="beam.streaks",color=SHINE,alpha=.2,width=R*1.9,brightness=2,length=40,scroll=-34}),W=R*1.9},
  {B=E.Beam(g,at0,at1,{tex="beam.wisp",color=AMBER,alpha=.3,width=R*2.3,length=70,scroll=14}),W=R*2.3},
  {B=E.Beam(g,at0,at1,{tex="beam.curtain",color=CRIMSON:Lerp(AMBER,.4),alpha=.55,width=R*2.8,length=120,scroll=-9}),W=R*2.8},
 }
  -- the muzzle: a blazing orb, a flare and shock rings bursting off it
 local orb=newPart(g,Vector3.one*R*.9,WHITE,0) orb.Shape=Enum.PartType.Ball
 local orbShell=newPart(g,Vector3.one*R*1.5,BUTTERFLY_GOLD,.45) orbShell.Shape=Enum.PartType.Ball
 orb.CFrame=CFrame.new(o) orbShell.CFrame=CFrame.new(o)
 E.Sprite(a0,{tex="flare.big",size={{0,R*2},{.08,R*9},{1,R*6}},alpha={{0,0},{.8,.2},{1,1}},color=SHINE},T)
 E.Sprite(a0,{tex="glow.rays",size=R*7,alpha={{0,.3},{.85,.45},{1,1}},color=GOLD,spin={-80,-80}},T)
 E.Sprite(a0,{tex="star.lens",size=R*4,alpha=.2,color=BUTTERFLY_GOLD,spin={240,240}},T)
 local shocks=E.Stream(a0,{tex="ring.crisp",orient="flat",dir=Enum.NormalId.Front,size={{0,R*1.8},{1,R*6}},alpha={{0,.1},{1,1}},color=SHINE,
  life={.4,.4},speed={30,30}},6)
  -- rings and swirls racing down its length
 local rings=E.Stream(a0,{tex="ring.thin",orient="flat",dir=Enum.NormalId.Front,size={{0,R*2.2},{1,R*3.2}},alpha={{0,.25},{1,1}},color=GOLD,
  life={L/420,L/420},speed={420,420}},14)
 local swirls=E.Stream(a0,{tex="swirl.lines",orient="flat",dir=Enum.NormalId.Front,size={{0,R*2.4},{1,R*2.8}},alpha={{0,.35},{1,1}},
  color=SHINE,life={L/360,L/360},speed={360,360},spin={500,500}},10)
  -- the tip: an explosion rolling along the ground where it lands
 local tip=E.Anchor(g,CFrame.new(o))
 local boom=E.Stream(tip,{tex="flare.burst2",size={{0,R*1.8},{1,R*4.5}},alpha={{0,.15},{1,1}},color=GOLD,life={.2,.3}},20)
 local smoke=E.Stream(tip,{tex="smoke",light=0,size={{0,R},{1,R*3}},alpha={{0,.35},{1,1}},color={{0,Color3.fromRGB(150,110,40)},{1,Color3.fromRGB(60,45,25)}},
  life={.7,1.1},speed={14,32},spread=90,drag=2},22)
 local sparks=E.Stream(tip,{tex="star.crisp",size={{0,1.8},{1,0}},color={{0,SHINE},{1,AMBER}},life={.4,.8},speed={40,90},spread=80,dir=Enum.NormalId.Back,drag=1.5},90)
  -- the floor under it: a glowing trench and rubble thrown up along it
 local floor=E.Ground(o,{d.Boss,g.Folder})
 local fy=floor and floor.Y+.06 or o.Y-R
 local flat=Vector3.new(dir.X,0,dir.Z)
 flat=flat.Magnitude>.01 and flat.Unit or Vector3.zAxis
 local start=Vector3.new(o.X,fy,o.Z)
 local trench=newPart(g,Vector3.new(R*.9,.08,.1),AMBER,.05)
 local trenchGlow=newPart(g,Vector3.new(R*2.2,.07,.1),GOLD,.5)
 local rubble={}
 for i=1,8 do
  local an=E.Anchor(g,CFrame.new(start))
  rubble[i]={A=an,F=(i-.5)/8}
  E.Stream(an,{tex="smoke",light=0,size={{0,R*.3},{1,R*.8}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
   life={.7,1.2},speed={14,30},spread=60,dir=Enum.NormalId.Top,drag=2},16)
  E.Stream(an,{tex="star.crisp",size={{0,1.4},{1,0}},color={{0,SHINE},{1,GOLD}},life={.5,.9},speed={25,55},spread=50,dir=Enum.NormalId.Top,
   accel=Vector3.new(0,-50,0)},24)
 end
 E.Light(g,a0,GOLD,80,12,T+.2)
 E.Light(g,tip,AMBER,70,10,T+.2)
  -- the release lights the whole screen for a moment
 local Lighting=game:GetService("Lighting")
 local flash=Instance.new("ColorCorrectionEffect")
 flash.Brightness=.35 flash.Contrast=.2 flash.TintColor=Color3.fromRGB(255,240,210) flash.Parent=Lighting
 E.Tween(flash,.6,{Brightness=0,Contrast=0,TintColor=WHITE})
 task.delay(.7,function()flash:Destroy()end)
 E.Step(g,function(_,t)
  local reach=math.max(L*(1-(1-math.min(t/G,1))^2),.5)
  local fade=math.clamp((t-(T-.35))/.35,0,1)
  local k=math.min(t/.05,1)*(1-fade)
  local throb=1+.07*math.sin(t*46)+.04*math.sin(t*17)
  local mid=o+dir*reach*.5
  core.Size=Vector3.new(reach,R*.45*k*throb+.01,R*.45*k*throb+.01)
  local tipPos=o+dir*reach
  local ground=reach*math.max(flat:Dot(dir),.2)
  trench.Size=Vector3.new(R*.9,.08,ground) trenchGlow.Size=Vector3.new(R*2.2,.07,ground)
  local tcf=CFrame.lookAt(start+flat*ground*.5,start+flat*ground)
  local parts={core,a1,tip,trench,trenchGlow}
  local cfs={CFrame.lookAt(mid,tipPos)*CFrame.Angles(0,math.pi/2,0),CFrame.lookAt(tipPos,tipPos+dir),CFrame.lookAt(tipPos,tipPos+dir),tcf,tcf}
  for _,r in ipairs(rubble)do parts[#parts+1]=r.A cfs[#cfs+1]=CFrame.new(start+flat*ground*r.F)end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  for _,l in ipairs(layers)do l.B.Width0=l.W*k*throb l.B.Width1=l.B.Width0 end
  orb.Size=Vector3.one*R*.9*k*throb+Vector3.one*.01 orbShell.Size=Vector3.one*R*1.5*k*throb+Vector3.one*.01
  if t>=T then
   for _,e in ipairs(g.Folder:GetDescendants())do if e:IsA("ParticleEmitter")then e.Enabled=false end end
   core.Transparency=1 orb.Transparency=1 orbShell.Transparency=1
   local h=E.Group("P5TearerBeamEnd")
   local b=E.Anchor(h,CFrame.new(tipPos))
   E.Sprite(b,{tex="flare.big",size={{0,R*2},{.2,R*8},{1,R*9}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.5)
   E.Light(h,b,GOLD,R*8,10,.5)
   E.After(h,1,function()h:Destroy()end)
   return false
  end
  return true
 end)
 E.Tween(trench,1.2,{Transparency=1},nil,nil,T+.4)
 E.Tween(trenchGlow,.9,{Transparency=1},nil,nil,T+.2)
 E.After(g,T+2,function()g:Destroy()end)
end

 -- Golden Eternity: a great gold clock opens overhead, its hands racing, while light gathers in his raised hand
function P.EternityTell(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .8
 local g=E.Group("P5EternityTell")
 local sky=E.Anchor(g,CFrame.new(r.Position+UP*38))
 E.Sprite(sky,{tex="ring.ticked",orient="flat",size={{0,10},{.5,70},{1,74}},alpha={{0,.8},{.4,.1},{1,0}},color=GOLD,spin={50,50}},T+3.6)
 E.Sprite(sky,{tex="ring.compass",orient="flat",size={{0,8},{.5,56},{1,58}},alpha={{0,.8},{.4,.15},{1,.1}},color=SHINE,spin={-90,-90}},T+3.6)
 E.Sprite(sky,{tex="sigil.mandala2",orient="flat",size={{0,6},{.5,40},{1,42}},alpha={{0,.8},{.4,.3},{1,.2}},color=GOLD,spin={160,160}},T+3.6)
 E.Sprite(sky,{tex="glow.soft",size={{0,10},{.5,80},{1,70}},alpha={{0,.7},{.5,.55},{1,1}},color=BUTTERFLY_GOLD},T+3.6)
 local hand=handOf(d.Boss,"Right")or r
 local a=E.Anchor(g,handCF(hand))
 E.Sprite(a,{tex="star.lens",size={{0,1},{.9,9},{1,3}},alpha={{0,.4},{.9,0},{1,1}},color=SHINE,spin={200,200}},T)
 E.Stream(a,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.35},speed={-14,-8},spread=180},60)
 E.Light(g,sky,GOLD,80,4,T+3.6)
 E.Step(g,function(_,t)
  if hand.Parent then a.CFrame=handCF(hand)end
  return t<T
 end)
 E.After(g,T+3.8,function()g:Destroy()end)
end

 -- Golden Eternity: blades hung in stopped time - a sphere of gold blades around a player, every point aimed at them,
 -- with the air cut around them; they wait for BladesRelease
local frozen={}
function P.FrozenBlades(E,d)
 local g=E.Group("P5FrozenBlades")
 local rng=Random.new(d.Seed or 1)
 local n=d.Count or 10
 local R=d.Radius or 9
 local c=d.Pos
 local blades={}
 for i=1,n do
  local y=1-2*(i-.5)/n
  local rad=math.sqrt(math.max(1-y*y,0))
  local th=i*2.39996+rng:NextNumber(0,.3)
  local dirOut=Vector3.new(math.cos(th)*rad,y*.55+.25,math.sin(th)*rad).Unit
  local at=c+dirOut*R
  local blade=newPart(g,Vector3.new(.25,.9,5.5),SHINE,0)
  local glow=newPart(g,Vector3.new(.9,2.2,6.5),BUTTERFLY_GOLD,.55)
  local cf=CFrame.lookAt(at,c)
  blade.CFrame=cf glow.CFrame=cf
  blades[i]={Blade=blade,Glow=glow,From=at}
 end
 local a=E.Anchor(g,CFrame.new(c))
 E.Sprite(a,{tex="ring.ticked",orient="flat",size={{0,2},{.1,R*2.2},{1,R*2.2}},alpha={{0,.5},{.1,.2},{1,.3}},color=GOLD,spin={0,0}},6)
 local cut=slash(g,R*1.6,WHITE,GOLD,{GlowAlpha=.35})
 local parts,cfs={},{}
 place(cut,CFrame.new(c+UP*1.5)*CFrame.Angles(0,rng:NextNumber(0,6.28),0)*CFrame.Angles(-math.pi/2,0,rng:NextNumber(-.5,.5)),1,0,parts,cfs)
 workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
 frozen[#frozen+1]={G=g,Blades=blades,Center=c}
 E.After(g,8,function()g:Destroy()end)
end

 -- Golden Eternity: time resumes - every hung blade drives into its centre at once, and each centre bursts
function P.BladesRelease(E,d)
 local list=frozen
 frozen={}
 for _,set in ipairs(list)do
  local g=set.G
  if g.Alive then
   E.Step(g,function(_,t)
    local k=math.clamp(t/.14,0,1)
    local parts,cfs={},{}
    for _,b in ipairs(set.Blades)do
     local p=b.From:Lerp(set.Center,k*k)
     local cf=CFrame.lookAt(p,set.Center+(set.Center-b.From).Unit)
     parts[#parts+1]=b.Blade cfs[#cfs+1]=cf
     parts[#parts+1]=b.Glow cfs[#cfs+1]=cf
    end
    workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
    if k>=1 then
     for _,b in ipairs(set.Blades)do b.Blade.Transparency=1 b.Glow.Transparency=1 end
     local a=E.Anchor(g,CFrame.new(set.Center))
     E.Sprite(a,{tex="flare.big",size={{0,4},{.15,26},{1,30}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.4)
     E.Sprite(a,{tex="burst.spiky2",size={{0,3},{1,24}},alpha={{0,0},{1,1}},color=GOLD,rot={0,360}},.35)
     E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={30,60},spread=180,drag=2},34)
     E.Light(g,a,GOLD,40,9,.4)
     E.After(g,.8,function()g:Destroy()end)
     return false
    end
    return true
   end)
  end
 end
end

 -- Overclock: clock rings spin fast under him and around him, and speed lines stream off him while it lasts
function P.Overclock(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 8
 local g=E.Group("P5Overclock")
 local floor=E.Ground(r.Position,{d.Boss,g.Folder})
 local drop=floor and r.Position.Y-floor.Y-.1 or 3
 local feet=E.Anchor(g,r.CFrame*CFrame.new(0,-drop,0))
 local body=E.Anchor(g,r.CFrame)
 E.Sprite(feet,{tex="ring.ticked",orient="flat",size={{0,2},{.05,14},{1,14}},alpha={{0,.6},{.05,.15},{.95,.3},{1,1}},color=GOLD,spin={540,540}},T)
 E.Sprite(feet,{tex="ring.compass",orient="flat",size={{0,2},{.05,10},{1,10}},alpha={{0,.6},{.05,.2},{.95,.35},{1,1}},color=SHINE,spin={-720,-720}},T)
 local lines=E.Stream(body,{tex="wind.dash",orient="velocity",size={{0,2},{1,4}},alpha={{0,.45},{1,1}},color=SHINE,life={.15,.25},speed={20,35},spread=180},24)
 local motes=E.Stream(body,{tex="star.crisp",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.5},speed={4,10},spread=180},16)
 E.Light(g,body,GOLD,16,2,T)
 E.Step(g,function(_,t)
  if not r.Parent then g:Destroy()return false end
  workspace:BulkMoveTo({feet,body},{r.CFrame*CFrame.new(0,-drop,0),r.CFrame},Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then lines.Enabled=false motes.Enabled=false end
  return t<T+.3
 end)
 E.After(g,T+.6,function()g:Destroy()end)
end

 -- Overclock: a slow, pale clock turning under a player whose time he has slowed
function P.SlowClock(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T=d.Time or 5
 local g=E.Group("P5SlowClock")
 local pale=Color3.fromRGB(190,205,230)
 local feet=E.Anchor(g,CFrame.new(vr.Position-UP*2.9))
 E.Sprite(feet,{tex="ring.ticked",orient="flat",size={{0,12},{.06,7},{1,7}},alpha={{0,.7},{.06,.25},{.9,.35},{1,1}},color=pale,spin={-20,-20}},T)
 E.Sprite(feet,{tex="sigil.ring2",orient="flat",size={{0,9},{.06,5},{1,5}},alpha={{0,.7},{.06,.35},{.9,.45},{1,1}},color=GOLD,spin={12,12}},T)
 local drip=E.Stream(feet,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,pale},{1,GOLD}},life={.8,1.4},speed={1,2},spread=30,dir=Enum.NormalId.Top},8)
 E.Step(g,function(_,t)
  if vr.Parent then feet.CFrame=CFrame.new(vr.Position-UP*2.9)end
  if t>=T then drip.Enabled=false end
  return t<T+.2
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end

return P
