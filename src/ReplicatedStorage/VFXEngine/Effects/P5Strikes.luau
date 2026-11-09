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
   BigWarn        {Points, Radii, Time}                           big Flower-Field-style warning fields (Horrifying Ground)
   SilentStart / SilentStance / SilentCuts / SilentSheathe /       Silent Cut: the gold silence, the draw stance, the lines filling
   SilentShatter / SilentHit / SilentEnd                          the space, the sheathe, the shatter, the wound, colour back
   RiverCharge / RiverLunge / RiverCatch / RiverPierce            Scarlet River: the burning arm, the screeching lunge and river,
                                                                  the thorns on whoever is dragged, the pierce
   FireRingTell / FireRingCut / FireRing                          Fire Ring: the wind-up, the full-circle cut, the ring of fire
   EyeGlint / ShotgunBlast                                        Shotgun Blast: the star in his eye, the point-blank blast
   VerticalStance / VerticalSwing / VerticalSlash                 Perfect Vertical Slash: the still stance, the blade's arc, the
                                                                  upright crescent riding the lane and its ring-bursts of flame
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
 ribbon(width*.2,tone,.5,.85)
 ribbon(width*.08,SHINE:Lerp(BUTTERFLY_GOLD,.4),.1,1)
 ribbon(width*.03,WHITE,0,1)
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
   if wall then
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
local function goldArc(E,g,center,R,startAngle,span,thick)
 thick=thick or 1
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=center
 local N=E.Quality<.6 and 16 or 26
 local points,layers={},{}
 for i=0,N do local at=Instance.new("Attachment")at.Parent=carrier points[i+1]=at end
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
 ribbon(R*.3*thick,AMBER,.45,1,false)
 ribbon(R*.13*thick,BUTTERFLY_GOLD,.05,.6,false)
 ribbon(R*.04*thick,WHITE,0,1,true)
 return function(frac,fade)
  for i,at in ipairs(points)do
   local a=startAngle+span*frac*(i-1)/N
   at.Position=Vector3.new(math.cos(a)*R,0,math.sin(a)*R)
  end
  for _,l in ipairs(layers)do
   for i,beam in ipairs(l.Beams)do
    local t0,t1=(i-1)/N,i/N
    local k0,k1=t0^1.4,t1^1.4
    if l.Head then k0,k1=t0^3,t1^3 end
    beam.Width0=math.max(.04,l.W*k0*(1-fade)) beam.Width1=math.max(.04,l.W*k1*(1-fade))
   end
  end
 end
end

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
 ribbon(R*.24,fake and VIOLET or CRIMSON,fake and .65 or .45,1,false)
 ribbon(R*.09,fake and PINK or VOID,fake and .55 or 0,fake and 1 or 0,false)
 ribbon(R*.025,fake and WHITE or Color3.fromRGB(255,190,200),fake and .4 or 0,1,true)
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
   if fake then
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
 E.Tween(scar,.4,{Transparency=1},nil,nil,T+.45)
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
 E.Sprite(floor,{tex="burst.spiky",orient="flat",size={{0,2},{.2,R*2},{1,R*2.3}},alpha={{0,0},{.6,.45},{1,1}},color=GOLD},.5)
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
  -- claws on the hand, not a sword: three rakes torn across his front, and a glint on the clawing hand
 local tilt=side*35
 local rake=E.Anchor(g,d.Frame*CFrame.new(0,.5,-5))
 E.Sprite(rake,{tex="claw.marks",size={{0,10},{.25,26},{1,30}},alpha={{0,0},{.3,.05},{1,1}},color=SHINE,rot={tilt,tilt}},.3)
 E.Sprite(rake,{tex="claw.marks",size={{0,12},{.25,30},{1,34}},alpha={{0,.4},{.3,.35},{1,1}},color=AMBER,rot={tilt,tilt}},.3)
 local hand=handOf(d.Boss,"Right")
 if hand then
  local glint=E.Anchor(g,handCF(hand))
  E.Sprite(glint,{tex="star.glare",size={{0,1},{.4,7},{1,2}},alpha={{0,.2},{.7,0},{1,1}},color=SHINE,rot={-20,20}},.25)
 end
 local a=E.Anchor(g,d.Frame*CFrame.new(0,.5,-6))
 E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,AMBER}},life={.2,.4},speed={20,40},spread=60,dir=Enum.NormalId.Front,drag=2},10)
 E.After(g,.6,function()g:Destroy()end)
end

 -- a shockwave racing out along the floor: a crisp ring and its glow (flat sprites that grow at the wave's speed),
 -- a low wall of light standing on the front, and dust and sparks thrown off it. Look "Dark" is amber and smoke.
function P.Shockwave(E,d)
  -- Look "Dark" keeps it amber, Inward runs it in from the edge
 local g=E.Group("P5Shockwave")
 local speed,range=d.Speed or 120,d.Range or 60
 local T=range/speed
 local dark=d.Look=="Dark"
 local inward=d.Inward==true
 local color=dark and AMBER or Color3.new(1,1,1)
 local floor=E.Ground(d.Pos+UP*3,{d.Boss,g.Folder})
 local c=(floor or d.Pos)+UP*.1
 local N=math.clamp(math.floor(range/2),24,96)
 local segs={}
 for i=1,N do segs[i]=newPart(g,Vector3.new(1.4,.7,1),color,.05) end
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local r=math.max(inward and range*(1-k)or range*k,.5)
  local len=2*math.pi*r/N*1.06
  local alpha=inward and .05+.95*math.clamp((k-.85)/.15,0,1) or .05+.95*math.clamp((k-.7)/.3,0,1)^2
  local parts,cfs={},{}
  for i,p in ipairs(segs)do
   local ang=(i-1)*math.pi*2/N
   local pos=c+Vector3.new(math.cos(ang)*r,.35,math.sin(ang)*r)
   p.Size=Vector3.new(1.4,.7,len)
   p.Transparency=alpha
   parts[#parts+1]=p cfs[#cfs+1]=CFrame.lookAt(pos,pos+Vector3.new(-math.sin(ang),0,math.cos(ang)))
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if k>=1 then for _,p in ipairs(segs)do p.Transparency=1 end return false end
  return true
 end)
 E.After(g,T+.5,function()g:Destroy()end)
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
 local T=d.Time or 3
 local lane=d.Frame
 local V=math.min(d.HalfWidth or 26,32)  -- how big the sphere gets (the beam itself can be far wider)
 local o=d.Origin or (lane*CFrame.new(0,4,-4)).Position
 local orb=E.Anchor(g,CFrame.lookAt(o,o+lane.LookVector))
 local core=newPart(g,Vector3.one,WHITE,0) core.Shape=Enum.PartType.Ball
 local shell=newPart(g,Vector3.one,BUTTERFLY_GOLD,.45) shell.Shape=Enum.PartType.Ball
 local halo=newPart(g,Vector3.one,AMBER,.8) halo.Shape=Enum.PartType.Ball
 E.Sprite(orb,{tex="glow.soft",size={{0,2},{.9,V*2.6},{1,V*3}},alpha={{0,.6},{.9,.2},{1,1}},color=GOLD},T+.05)
 E.Sprite(orb,{tex="star.lens",size={{0,2},{.9,V*2.2},{1,V}},alpha={{0,.4},{.9,0},{1,1}},color=SHINE,spin={140,140}},T+.05)
 E.Sprite(orb,{tex="glow.rays",size={{0,4},{.9,V*3.4},{1,V*3.6}},alpha={{0,.6},{.9,.35},{1,1}},color=AMBER,spin={-60,-60}},T+.05)
 local rings=E.Stream(orb,{tex="ring.thin",orient="flat",dir=Enum.NormalId.Front,size={{0,V*2.6},{1,3}},alpha={{0,.8},{.6,.2},{1,1}},color=SHINE,
  life={.45,.45},speed={.001,.001}},5)
 local pull=E.Stream(orb,{tex="wind.dash",orient="velocity",size={{0,8},{1,2}},alpha={{0,.45},{1,1}},color=GOLD,life={.4,.5},speed={-110,-70},spread=180},80)
 local motes=E.Stream(orb,{tex="star.tiny",size={{0,.9},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.45},speed={-34,-22},spread=180},90)
 local floor=E.Ground(lane.Position+UP*4,{d.Boss,g.Folder})
 local dust=E.Anchor(g,CFrame.new(Vector3.new(lane.X,(floor and floor.Y or lane.Y)+.07,lane.Z)))
 local lift=E.Stream(dust,{tex="smoke",light=0,size={{0,3},{1,6}},alpha={{0,.55},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
  life={.8,1.3},speed={3,7},spread=80,dir=Enum.NormalId.Top,accel=Vector3.new(0,6,0)},18)
 local stones=E.Stream(dust,{tex="star.crisp",size={{0,.6},{1,.3}},color={{0,AMBER},{1,GOLD}},life={.8,1.2},speed={2,5},spread=90,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,10,0)},20)
 E.Sprite(dust,{tex="sigil.mandala",orient="flat",size={{0,4},{.3,V*1.6},{1,V*1.8}},alpha={{0,.8},{.3,.4},{1,.6}},color=AMBER,spin={-70,-70}},T)
 local light=E.Light(g,orb,GOLD,60,1)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local throb=1+.08*math.sin(t*30)
  core.Size=Vector3.one*(.5+V*.45*k)*throb
  shell.Size=Vector3.one*(1+V*.8*k)*throb
  halo.Size=Vector3.one*(1.5+V*1.2*k)
  local at=CFrame.new(o)
  workspace:BulkMoveTo({core,shell,halo},{at,at,at},Enum.BulkMoveMode.FireCFrameChanged)
  light.Brightness=1+9*k
  if t>=T then
   rings.Enabled=false pull.Enabled=false motes.Enabled=false lift.Enabled=false stones.Enabled=false
   for _,p in ipairs({core,shell,halo})do p.Transparency=1 end
   return false
  end
  return true
 end)
 E.After(g,T+1.5,function()g:Destroy()end)
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
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.12,0,0),2.6,r:NextNumber(20,26),t)end,
 function(l,g,r,t)crystal(l,g,CFrame.new(-1.2,0,0)*CFrame.Angles(-.1,0,.25),2.4,r:NextNumber(16,20),t) crystal(l,g,CFrame.new(1.3,0,0)*CFrame.Angles(-.05,0,-.3),2,r:NextNumber(9,12),t)end,
 function(l,g,r,t)for i=-1,1 do crystal(l,g,CFrame.new(i*1.6,0,0)*CFrame.Angles(-.15,0,-i*.38),2.1,i==0 and 17 or 12,t)end end,
 function(l,g,r,t)crystal(l,g,CFrame.new(),2.8,14,t) for i=1,4 do local a=i*math.pi/2+.4 crystal(l,g,CFrame.new(math.cos(a)*2.2,0,math.sin(a)*2.2)*CFrame.Angles(math.sin(a)*.4,0,-math.cos(a)*.4),1.4,r:NextNumber(5,8),t)end end,
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.45,0,.1),4.6,13,t) crystal(l,g,CFrame.new(2.4,0,1)*CFrame.Angles(0,0,-.5),1.4,5,t)end,
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.08,0,0),1.9,13,t) crystal(l,g,CFrame.new(0,12.4,-.6)*CFrame.Angles(-.5,0,0),1.5,10,t)end,
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.75,0,0),2.5,21,t)end,
 function(l,g,r,t)crystal(l,g,CFrame.Angles(-.1,0,.42),2.2,18,t) crystal(l,g,CFrame.Angles(-.1,0,-.42),2.2,18,t)end,
 function(l,g,r,t)for i=1,5 do crystal(l,g,CFrame.new(r:NextNumber(-2,2),0,r:NextNumber(-2,2))*CFrame.Angles(r:NextNumber(-.4,.1),0,r:NextNumber(-.4,.4)),1.2,r:NextNumber(5,10),t)end end,
 function(l,g,r,t)crystal(l,g,CFrame.new(),3.4,10,t) crystal(l,g,CFrame.new(0,0,0)*CFrame.Angles(0,.8,0)*CFrame.new(0,9.6,0)*CFrame.Angles(-.2,0,0),2.2,10,t)end,
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
 local fill=newPart(g,Vector3.new(W*2,.05,len),BUTTERFLY_GOLD,.5)
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
 local V=math.min(R,60)  -- sprites (flares, blasts) stop growing past this; the beam's body is real 3D and keeps its true size
 local o=d.Origin
  -- the body is a real tube, so its true size reads from any angle: a white-hot core, gold and amber sheaths, and a
  -- shimmering rim lying exactly on the edge of what it hits (Radius). Soft camera-facing light glows around it.
 local shells={{D=R*.9,C=WHITE,A=0},{D=R*1.25,C=SHINE,A=.3},{D=R*1.6,C=BUTTERFLY_GOLD,A=.55},{D=R*2,C=AMBER,A=.74}}
 for _,s in ipairs(shells)do s.P=newPart(g,Vector3.one,s.C,s.A) s.P.Shape=Enum.PartType.Cylinder end
 local rim=newPart(g,Vector3.one,GOLD,0) rim.Shape=Enum.PartType.Cylinder rim.Material=Enum.Material.ForceField
 shells[#shells+1]={D=R*2.03,P=rim}
 local a0=E.Anchor(g,CFrame.lookAt(o,o+dir))
 local a1=E.Anchor(g,CFrame.lookAt(o,o+dir))
 local at0,at1=E.Attach(a0),E.Attach(a1)
 local layers={
  {B=E.Beam(g,at0,at1,{tex="beam.streaks",color=SHINE,alpha=.35,width=R*2.1,brightness=1.4,light=.7,length=80,scroll=-40}),W=R*2.1},
  {B=E.Beam(g,at0,at1,{tex="beam.wisp",color=AMBER,alpha=.45,width=R*2.5,light=.4,length=120,scroll=14}),W=R*2.5},
  {B=E.Beam(g,at0,at1,{tex="beam.curtain",color=CRIMSON:Lerp(AMBER,.55),alpha=.55,width=R*2.9,light=.3,length=160,scroll=-9}),W=R*2.9},
 }
  -- the muzzle: a blazing orb as wide as the core, a flare and shock rings bursting off it
 local orb=newPart(g,Vector3.one,WHITE,0) orb.Shape=Enum.PartType.Ball
 local orbShell=newPart(g,Vector3.one,BUTTERFLY_GOLD,.45) orbShell.Shape=Enum.PartType.Ball
 orb.CFrame=CFrame.new(o) orbShell.CFrame=CFrame.new(o)
 E.Sprite(a0,{tex="flare.big",size={{0,V*2},{.08,V*9},{1,V*6}},alpha={{0,0},{.8,.2},{1,1}},color=SHINE},T)
 E.Sprite(a0,{tex="glow.rays",size=V*7,alpha={{0,.3},{.85,.45},{1,1}},color=GOLD,spin={-80,-80}},T)
 local shocks=E.Stream(a0,{tex="ring.crisp",orient="flat",dir=Enum.NormalId.Front,size={{0,R*2.1},{1,R*3}},alpha={{0,.1},{1,1}},color=SHINE,
  life={.4,.4},speed={40,40}},6)
  -- rings and swirls racing down its length, as wide as the beam
 local rings=E.Stream(a0,{tex="ring.thin",orient="flat",dir=Enum.NormalId.Front,size={{0,R*2.05},{1,R*2.3}},alpha={{0,.3},{1,1}},color=AMBER,light=.5,
  life={L/480,L/480},speed={480,480}},12)
 local swirls=E.Stream(a0,{tex="swirl.lines",orient="flat",dir=Enum.NormalId.Front,size={{0,R*1.9},{1,R*2.1}},alpha={{0,.35},{1,1}},
  color=SHINE,life={L/380,L/380},speed={380,380},spin={500,500}},8)
  -- the tip: an explosion rolling along where it lands
 local tip=E.Anchor(g,CFrame.new(o))
 local boom=E.Stream(tip,{tex="flare.burst2",size={{0,V*1.8},{1,V*4.5}},alpha={{0,.15},{1,1}},color=GOLD,life={.2,.3}},20)
 local smoke=E.Stream(tip,{tex="smoke",light=0,size={{0,V},{1,V*3}},alpha={{0,.35},{1,1}},color={{0,Color3.fromRGB(150,110,40)},{1,Color3.fromRGB(60,45,25)}},
  life={.7,1.1},speed={14,32},spread=90,drag=2},22)
 local sparks=E.Stream(tip,{tex="star.crisp",size={{0,2.4},{1,0}},color={{0,SHINE},{1,AMBER}},life={.4,.8},speed={60,130},spread=80,dir=Enum.NormalId.Back,drag=1.5},90)
  -- the floor where the beam cuts into it: rubble and dust thrown up along both edges of the cut
 local floor=E.Ground(o,{d.Boss,g.Folder})
 local fy=floor and floor.Y+.06 or o.Y-R
 local flat=Vector3.new(dir.X,0,dir.Z)
 flat=flat.Magnitude>.01 and flat.Unit or Vector3.zAxis
 local side=flat:Cross(UP)
 local start=Vector3.new(o.X,fy,o.Z)
 local depth=o.Y-fy
 local halfCut=depth<R and math.sqrt(R*R-depth*depth)or 0  -- how wide the beam is where it meets the floor
 local rubble={}
 for i=1,10 do
  local an=E.Anchor(g,CFrame.new(start))
  rubble[i]={A=an,F=(math.ceil(i/2)-.5)/5,S=i%2==0 and 1 or -1}
  E.Stream(an,{tex="smoke",light=0,size={{0,V*.4},{1,V}},alpha={{0,.4},{1,1}},color={{0,Color3.fromRGB(150,115,50)},{1,Color3.fromRGB(70,55,30)}},
   life={.8,1.3},speed={18,40},spread=50,dir=Enum.NormalId.Top,drag=2},16)
  E.Stream(an,{tex="star.crisp",size={{0,2},{1,0}},color={{0,SHINE},{1,GOLD}},life={.5,.9},speed={35,70},spread=45,dir=Enum.NormalId.Top,
   accel=Vector3.new(0,-50,0)},24)
 end
 E.Light(g,a0,GOLD,math.min(R*1.2,120),12,T+.2)
 E.Light(g,tip,AMBER,math.min(R,100),10,T+.2)
  -- the release lights the whole screen for a moment
 local Lighting=game:GetService("Lighting")
 local flash=Instance.new("ColorCorrectionEffect")
 flash.Brightness=.4 flash.Contrast=.25 flash.TintColor=Color3.fromRGB(255,238,200) flash.Parent=Lighting
 E.Tween(flash,.7,{Brightness=0,Contrast=0,TintColor=WHITE})
 task.delay(.8,function()flash:Destroy()end)
 E.Step(g,function(_,t)
  local reach=math.max(L*(1-(1-math.min(t/G,1))^2),.5)
  local fade=math.clamp((t-(T-.4))/.4,0,1)
  local k=math.min(t/.06,1)*(1-fade)
  local throb=1+.035*math.sin(t*46)+.02*math.sin(t*17)
  local mid=o+dir*reach*.5
  local tipPos=o+dir*reach
  local bcf=CFrame.lookAt(mid,tipPos)*CFrame.Angles(0,math.pi/2,0)
  local parts,cfs={a1,tip},{CFrame.lookAt(tipPos,tipPos+dir),CFrame.lookAt(tipPos,tipPos+dir)}
  for i,s in ipairs(shells)do
   local w=s.D*k*(i==1 and throb or 1)+.01
   s.P.Size=Vector3.new(reach,w,w)
   parts[#parts+1]=s.P cfs[#cfs+1]=bcf
  end
  local ground=reach*math.max(flat:Dot(dir),.2)
  for _,r in ipairs(rubble)do parts[#parts+1]=r.A cfs[#cfs+1]=CFrame.new(start+flat*ground*r.F+side*r.S*halfCut*k)end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  for _,l in ipairs(layers)do l.B.Width0=l.W*k*throb l.B.Width1=l.B.Width0 end
  orb.Size=Vector3.one*R*k*throb+Vector3.one*.01 orbShell.Size=Vector3.one*R*1.5*k*throb+Vector3.one*.01
  if t>=T then
   for _,e in ipairs(g.Folder:GetDescendants())do if e:IsA("ParticleEmitter")then e.Enabled=false end end
   for _,s in ipairs(shells)do s.P.Transparency=1 end
   orb.Transparency=1 orbShell.Transparency=1
   local h=E.Group("P5TearerBeamEnd")
   local b=E.Anchor(h,CFrame.new(tipPos))
   E.Sprite(b,{tex="flare.big",size={{0,V*2},{.2,V*8},{1,V*9}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.5)
   E.Light(h,b,GOLD,60,10,.5)
   E.After(h,1,function()h:Destroy()end)
   return false
  end
  return true
 end)
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

 -- big warning fields, the way the Flower Field marks its ground: a gold field and a crimson ring closing on its edge
function P.BigWarn(E,d)
 local g=E.Group("P5BigWarn")
 local T=d.Time or .8
 for i,p in ipairs(d.Points or{})do
  local R=(d.Radii and d.Radii[i])or 10
  local a=E.Anchor(g,CFrame.new(p+UP*.12))
  E.Sprite(a,{tex="disc.soft",orient="flat",size={{0,R*.5},{.2,R*2.1},{1,R*2.1}},alpha={{0,.9},{.2,.72},{1,.55}},color=BUTTERFLY_GOLD},T)
  E.Sprite(a,{tex="ring.crisp",orient="flat",size={{0,R*2.8},{1,R*2}},alpha={{0,.6},{.15,.05},{1,0}},color=CRIMSON},T+.05)
  E.Sprite(a,{tex="ring.thin",orient="flat",size=R*2,alpha={{0,.5},{.2,.15},{1,.1}},color=SHINE},T)
 end
 E.After(g,T+.4,function()g:Destroy()end)
end

 -- Silent Cut (after Devil May Cry 5's Judgment Cut End). He drops into a low draw stance and the world goes still -
 -- gold and drained, black bars closing in. He vanishes; slash lines fill the space around everyone, one after
 -- another, and across your own screen. He is back, sheathing slowly - HOLD E - a flash at the scabbard, and every
 -- line detonates at once while the screen shatters like glass.
local Tw=game:GetService("TweenService")
local silent={Item=nil,Lines={},Hidden={}}
local function hideBoss(boss,on)
 if on and boss then
  for _,p in ipairs(boss:GetDescendants())do
   if p:IsA("BasePart")or p:IsA("Decal")then silent.Hidden[p]=true p.LocalTransparencyModifier=1 end
  end
 else
  for p in pairs(silent.Hidden)do if p.Parent then p.LocalTransparencyModifier=0 end end
  table.clear(silent.Hidden)
 end
end
local function silentClear()
 local item=silent.Item
 silent.Item=nil
 if item then
  Tw:Create(item.Tint,TweenInfo.new(.4),{Saturation=0,TintColor=WHITE,Contrast=0}):Play()
  for _,bar in ipairs(item.Bars)do Tw:Create(bar,TweenInfo.new(.4),{Size=UDim2.fromScale(1,0)}):Play()end
  Tw:Create(item.Wash,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()
  task.delay(.5,function()item.Gui:Destroy()item.Tint:Destroy()end)
 end
 for _,l in ipairs(silent.Lines)do if l.Core.Parent then l.Core:Destroy()l.Glow:Destroy()end end
 table.clear(silent.Lines)
 hideBoss(nil,false)
end
local function restoreColour(item)
 Tw:Create(item.Tint,TweenInfo.new(.5),{Saturation=0,TintColor=WHITE,Contrast=0}):Play()
 for _,bar in ipairs(item.Bars)do Tw:Create(bar,TweenInfo.new(.45),{Size=UDim2.fromScale(1,0)}):Play()end
end
 -- the silence, on the screens of the players it targets
function P.SilentStart(E,d)
 local me=Players.LocalPlayer.Character
 local mine=false
 for _,v in ipairs(d.Victims or{})do if v==me then mine=true end end
 if not mine then return end
 local item=silent.Item
 if not item then
  local gui=Instance.new("ScreenGui")gui.Name="P5Silence" gui.IgnoreGuiInset=true gui.DisplayOrder=70
  local wash=Instance.new("Frame")wash.Size=UDim2.fromScale(1,1)wash.BackgroundColor3=Color3.fromRGB(255,206,70)wash.BackgroundTransparency=1
  wash.BorderSizePixel=0 wash.Parent=gui
  local bars={}
  for i,pos in ipairs({0,1})do
   local bar=Instance.new("Frame")bar.AnchorPoint=Vector2.new(0,pos)bar.Position=UDim2.fromScale(0,pos)bar.Size=UDim2.fromScale(1,0)
   bar.BackgroundColor3=Color3.new(0,0,0)bar.BorderSizePixel=0 bar.ZIndex=5 bar.Parent=gui bars[i]=bar
  end
  gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
  local tint=Instance.new("ColorCorrectionEffect")tint.Name="P5SilenceTint" tint.Parent=game:GetService("Lighting")
  item={Gui=gui,Wash=wash,Bars=bars,Tint=tint,Lines={}}
  silent.Item=item
 end
 local quick=d.Short and .08 or .35
 item.Wash.BackgroundColor3=Color3.fromRGB(255,206,70)
 Tw:Create(item.Wash,TweenInfo.new(quick),{BackgroundTransparency=d.Short and .84 or .74}):Play()
 Tw:Create(item.Tint,TweenInfo.new(quick),{Saturation=-.85,TintColor=Color3.fromRGB(255,226,150),Contrast=.15}):Play()
 for _,bar in ipairs(item.Bars)do Tw:Create(bar,TweenInfo.new(quick*1.5),{Size=UDim2.fromScale(1,d.Short and .06 or .11)}):Play()end
end
 -- the draw stance: gold dust drawn in to him, hairline cracks creeping out under him, a glint at the hilt
function P.SilentStance(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 1
 local g=E.Group("P5SilentStance")
 local a=E.Anchor(g,r.CFrame)
 local pull=E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.4,.6},speed={-16,-10},spread=180},70)
 local floor=E.Ground(r.Position,{d.Boss,g.Folder})
 -- (no hairline cracks on the ground any more)
 local hilt=E.Anchor(g,r.CFrame*CFrame.new(-.9,-.4,-.8))
 E.Sprite(hilt,{tex="star.glare",size={{0,.5},{.9,5},{1,1}},alpha={{0,.4},{.9,0},{1,1}},color=WHITE,rot={0,0}},T)
 E.Step(g,function(_,t)
  if r.Parent then a.CFrame=r.CFrame hilt.CFrame=r.CFrame*CFrame.new(-.9,-.4,-.8)end
  if t>=T then pull.Enabled=false end
  return t<T+.2
 end)
 E.After(g,T+1.4,function()g:Destroy()end)
end
function P.SilentCuts(E,d)
 local T=d.Time or .9
 local rng=Random.new(d.Seed or 1)
 local count=d.Count or 24
 local R=d.Radius or 22
 local small=d.Small==true
 local g=E.Group("P5SilentCuts")
 if d.Boss and not small then hideBoss(d.Boss,true) end
 for _,v in ipairs({})do
  local vr=rootOf(v)
  if vr then
   local c=vr.Position+UP*2
   local lowGround=E.Ground(vr.Position,{g.Folder,v})
   local floorY=lowGround and lowGround.Y or vr.Position.Y-3
   for i=1,count do
    E.After(g,(i-1)/count*T*.85,function()
     local dir=Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-.7,.7),rng:NextNumber(-1,1))
     dir=dir.Magnitude>.1 and dir.Unit or Vector3.xAxis
     local mid=c+Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-.3,.7),rng:NextNumber(-1,1))*R*.45
     local len=rng:NextNumber(14,32)*(small and .6 or 1)
      -- the lines hang in the air round them: none reaches down to the floor and cuts into it
     local lowest=mid.Y-math.abs(dir.Y)*len*.5
     if lowest<floorY+2 then mid=mid+Vector3.new(0,floorY+2-lowest,0) end
     local core=newPart(g,Vector3.new(.07,.07,.1),WHITE,0)
     local glow=newPart(g,Vector3.new(.45,.45,.1),BUTTERFLY_GOLD,.55)
     local cf=CFrame.lookAt(mid,mid+dir)
     core.CFrame=cf glow.CFrame=cf
     E.Tween(core,.06,{Size=Vector3.new(.07,.07,len)})
     E.Tween(glow,.08,{Size=Vector3.new(.45,.45,len)})
     local s0=E.Anchor(g,cf)
     E.Emit(s0,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,WHITE},{1,GOLD}},life={.2,.4},speed={4,10},spread=180},3)
     silent.Lines[#silent.Lines+1]={Core=core,Glow=glow,Mid=mid,Len=len}
    end)
   end
  end
 end
 local item=silent.Item
 if item then
  for i=1,0 do
   E.After(g,(i-1)/count*T*.85,function()
    if not item.Gui.Parent then return end
    local f=Instance.new("Frame")f.AnchorPoint=Vector2.new(.5,.5)
    f.Position=UDim2.fromScale(rng:NextNumber(.12,.88),rng:NextNumber(.15,.85))
    f.Size=UDim2.new(0,0,0,2)f.Rotation=rng:NextNumber(0,180)f.BackgroundColor3=WHITE f.BorderSizePixel=0 f.ZIndex=3 f.Parent=item.Gui
    Tw:Create(f,TweenInfo.new(.07),{Size=UDim2.new(rng:NextNumber(.25,.7),0,0,2)}):Play()
    item.Lines[#item.Lines+1]=f
   end)
  end
 end
 E.After(g,T,function()hideBoss(nil,false)end)
 E.After(g,14,function()g:Destroy()end)
end
 -- the sheathe: a glow at the scabbard that grows as the blade slides home, and a white flash at the end
function P.SilentSheathe(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .75
 local g=E.Group("P5SilentSheathe")
 local function hip()return r.CFrame*CFrame.new(-.9,-.5,-.7)end
 local a=E.Anchor(g,hip())
 E.Sprite(a,{tex="glow.soft",size={{0,.5},{.9,3.5},{1,1}},alpha={{0,.6},{.9,.15},{1,1}},color=SHINE},T)
 E.After(g,math.max(T-.06,0),function()
  E.Sprite(a,{tex="star.glare2",size={{0,1},{.3,14},{1,2}},alpha={{0,0},{1,1}},color=WHITE,rot={0,0}},.25)
  E.Light(g,a,WHITE,16,9,.2)
 end)
 E.Step(g,function(_,t)
  if r.Parent then a.CFrame=hip()end
  return t<T+.3
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end
 -- the shatter: every hanging line flares and bursts, each target is cut in a blinding flash, and on your screen the
 -- lines blaze, the screen whites out and breaks into glass that flies apart
function P.SilentShatter(E,d)
 local small=d.Small==true
 local lines=silent.Lines
 silent.Lines={}
 local h=E.Group("P5SilentShatter")
 for i,l in ipairs(lines)do
  if l.Core.Parent then
   local w=small and .3 or .55
   l.Core.Size=Vector3.new(w,w,l.Len) l.Glow.Size=Vector3.new(w*3.5,w*3.5,l.Len) l.Glow.Transparency=.2
   E.Tween(l.Core,.3,{Size=Vector3.new(0,0,l.Len*1.25),Transparency=1},nil,nil,.06)
   E.Tween(l.Glow,.35,{Size=Vector3.new(0,0,l.Len*1.25),Transparency=1},nil,nil,.06)
   if i%2==0 then
    local s0=E.Anchor(h,CFrame.new(l.Mid))
    E.Emit(s0,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={10,26},spread=180,drag=2},5)
   end
   task.delay(.5,function()l.Core:Destroy()l.Glow:Destroy()end)
  end
 end
 for _,v in ipairs(d.Victims or{})do
  local vr=rootOf(v)
  if vr then
   local a=E.Anchor(h,CFrame.new(vr.Position+UP*1.5))
   E.Sprite(a,{tex="flare.big",size={{0,4},{.12,small and 22 or 40},{1,small and 26 or 46}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.4)
   local spin=math.random(0,180)
   E.Sprite(a,{tex="star.glare2",size={{0,4},{.2,small and 24 or 44},{1,6}},alpha={{0,0},{1,1}},color=WHITE,rot={spin,spin}},.3)
   E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.35,.7},speed={25,60},spread=180,drag=2},small and 16 or 40)
   if not small then
    local floor=E.Ground(vr.Position,{g,h.Folder})
    local f=E.Anchor(h,CFrame.new((floor or vr.Position-UP*3)+UP*.15))
    -- (no ring on the ground any more)
   end
   E.Light(h,a,WHITE,30,10,.3)
  end
 end
 local item=silent.Item
 if item then
  for _,f in ipairs(item.Lines)do
   f.Size=UDim2.new(f.Size.X.Scale,0,0,small and 8 or 14)
   Tw:Create(f,TweenInfo.new(.35),{BackgroundTransparency=1,Size=UDim2.new(f.Size.X.Scale*1.2,0,0,0)}):Play()
   task.delay(.4,function()f:Destroy()end)
  end
  item.Lines={}
  item.Wash.BackgroundColor3=WHITE
  item.Wash.BackgroundTransparency=small and .45 or .02
  Tw:Create(item.Wash,TweenInfo.new(small and .3 or .5),{BackgroundTransparency=1}):Play()
  if not small then
   for _=1,18 do
    local f=Instance.new("Frame")f.AnchorPoint=Vector2.new(.5,.5)
    local px,py=math.random(),math.random()
    f.Position=UDim2.fromScale(px,py)f.Size=UDim2.fromOffset(math.random(60,190),math.random(40,150))f.Rotation=math.random(0,180)
    f.BackgroundColor3=Color3.fromRGB(255,242,205)f.BackgroundTransparency=.55 f.BorderSizePixel=0 f.ZIndex=4
    local st=Instance.new("UIStroke")st.Color=WHITE st.Thickness=2 st.Transparency=.1 st.Parent=f
    local gr=Instance.new("UIGradient")gr.Rotation=math.random(0,180)gr.Transparency=NumberSequence.new(.15,.9)gr.Parent=f
    f.Parent=item.Gui
    local dx,dy=(px-.5)*1.5,(py-.5)*1.5+.35
    Tw:Create(f,TweenInfo.new(.75,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromScale(px+dx,py+dy),
     Rotation=f.Rotation+math.random(-140,140),BackgroundTransparency=1}):Play()
    Tw:Create(st,TweenInfo.new(.75),{Transparency=1}):Play()
    task.delay(.8,function()f:Destroy()end)
   end
  end
  restoreColour(item)
 end
 E.After(h,1.2,function()h:Destroy()end)
end
 -- the wound: gold bleeding out of whoever lost half their health while it seeps back
function P.SilentHit(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T=d.Time or 10
 local g=E.Group("P5SilentHit")
 local a=E.Anchor(g,vr.CFrame)
 E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,SHINE},{1,AMBER}},life={.5,.9},speed={10,24},spread=180,accel=Vector3.new(0,-30,0)},30)
 local seep=E.Stream(a,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,SHINE},{1,BUTTERFLY_GOLD}},life={.6,1},speed={-4,-2},spread=180},10)
 E.Step(g,function(_,t)
  if vr.Parent then a.CFrame=vr.CFrame end
  if t>=T then seep.Enabled=false end
  return t<T
 end)
 E.After(g,T+1,function()g:Destroy()end)
end
function P.SilentEnd(E,d)silentClear()end

 -- Scarlet River: his arm burns red and gold - the arm itself turns to light, crimson flame pours off the hand, rings of
 -- force spin round the forearm and red ripples spread under him
local RED=Color3.fromRGB(230,24,48)
local DEEP_RED=Color3.fromRGB(120,0,20)
function P.RiverCharge(E,d)
 local boss=d.Boss
 local r=rootOf(boss)
 if not r then return end
 local T=d.Time or .8
 local hold=d.Hold or T+.8
 local hand=handOf(boss,"Right")or r
 local g=E.Group("P5RiverCharge")
 local arm={}
 for _,name in ipairs({"RightUpperArm","RightLowerArm","RightHand","Right Arm"})do
  local p=boss:FindFirstChild(name)
  if p and p:IsA("BasePart")then arm[#arm+1]={P=p,Color=p.Color,Material=p.Material}end
 end
 local a=E.Anchor(g,handCF(hand))
 E.Sprite(a,{tex="glow.soft",size={{0,1},{.85,9},{1,10}},alpha={{0,.5},{.85,.15},{1,1}},color=AMBER},T+.05)
 E.Sprite(a,{tex="star.lens",size={{0,1},{.85,7},{1,2}},alpha={{0,.4},{.85,0},{1,1}},color=SHINE,spin={200,200}},T+.05)
 local flame=E.Stream(a,{tex="fire",size={{0,2.4},{1,.5}},alpha={{0,.2},{1,1}},color={{0,SHINE},{.35,AMBER},{1,Color3.fromRGB(120,70,10)}},life={.3,.5},speed={3,7},spread=30,
  dir=Enum.NormalId.Top,light=.6},45)
 local spin=E.Stream(a,{tex="swirl.lines",size={{0,3.5},{1,5}},alpha={{0,.35},{1,1}},color=AMBER:Lerp(SHINE,.3),life={.25,.35},spin={600,600},locked=true},10)
 local drip=E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,AMBER}},life={.4,.7},speed={1,3},spread=40,dir=Enum.NormalId.Bottom,
  accel=Vector3.new(0,-25,0)},40)
 local pull=E.Stream(a,{tex="wind.dash",orient="velocity",size={{0,3},{1,.8}},alpha={{0,.5},{1,1}},color=AMBER:Lerp(GOLD,.4),life={.2,.3},speed={-30,-18},spread=180},34)
 local floor=E.Ground(r.Position,{boss,g.Folder})
 local feet=E.Anchor(g,CFrame.new((floor or r.Position-UP*3)+UP*.1))
 local ripples=E.Stream(feet,{tex="ring.thin",orient="flat",size={{0,2},{1,16}},alpha={{0,.3},{1,1}},color=AMBER,life={.6,.6}},4)
 local light=E.Light(g,a,AMBER,18,2)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  for _,p in ipairs(arm)do
   if p.P.Parent then
    p.P.Material=Enum.Material.Neon
    p.P.Color=p.Color:Lerp(p.P.Name:find("Hand")and SHINE:Lerp(GOLD,.4)or AMBER,k)
   end
  end
  if hand.Parent then a.CFrame=handCF(hand)end
  light.Brightness=2+6*k
  if t>=T then flame.Enabled=false spin.Enabled=false drip.Enabled=false pull.Enabled=false ripples.Enabled=false end
  return t<hold
 end)
 E.After(g,hold,function()
  for _,p in ipairs(arm)do if p.P.Parent then p.P.Color=p.Color p.P.Material=p.Material end end
  g:Destroy()
 end)
end
 -- Scarlet River: the lunge. A screech pours out ahead of him - rings of sound and torn air in a widening cone - and a
 -- river of red light floods along the floor behind him, flowing the way he went, splashing as he passes
function P.RiverLunge(E,d)
 local g=E.Group("P5RiverLunge")
 local T=d.Time or .42
 local v=d.To-d.From
 local len=v.Magnitude
 if len<1 then g:Destroy()return end
 local dir=v.Unit
 local side=dir:Cross(UP)
 side=side.Magnitude>.01 and side.Unit or Vector3.xAxis
 local tip=E.Anchor(g,CFrame.lookAt(d.From,d.To))
 local screech=E.Stream(tip,{tex="ring.thin",orient="flat",dir=Enum.NormalId.Front,size={{0,3},{1,28}},alpha={{0,.1},{1,1}},
  color=AMBER,light=.25,life={.28,.36},speed={60,80}},45)
 local cone=E.Stream(tip,{tex="wind.dash",orient="velocity",size={{0,5},{1,12}},alpha={{0,.35},{1,1}},color=AMBER:Lerp(GOLD,.5),life={.15,.25},
  speed={70,100},spread=28,dir=Enum.NormalId.Front},70)
 local trail=E.Stream(tip,{tex="star.crisp",size={{0,1},{1,0}},color={{0,SHINE},{1,AMBER}},life={.3,.6},speed={6,16},spread=60,dir=Enum.NormalId.Back,
  accel=Vector3.new(0,-30,0)},90)
 E.Sprite(tip,{tex="glow.soft",size={{0,10},{1,14}},alpha={{0,.3},{1,1}},color=AMBER},T+.1)
 E.Sprite(tip,{tex="flare.streak",size={{0,10},{1,20}},alpha={{0,0},{1,.4}},color=AMBER:Lerp(SHINE,.3),rot={0,0}},T+.05)
 local floor=E.Ground(d.From+UP*2,{d.Boss,g.Folder})
 local fy=(floor and floor.Y or d.From.Y-3)+.15
 local start=Vector3.new(d.From.X,fy,d.From.Z)
  -- the river: two flat ribbons on the floor (a beam's width runs along its attachments' Y axis, laid sideways here)
 local a0=E.Anchor(g,CFrame.new(start))
 local a1=E.Anchor(g,CFrame.new(start))
 local lay=CFrame.fromMatrix(Vector3.zero,dir,side)
 local at0,at1=E.Attach(a0,lay),E.Attach(a1,lay)
 local water=E.Beam(g,at0,at1,{tex="beam.streaks",color={{0,AMBER},{.5,Color3.fromRGB(120,70,10)},{1,AMBER}},alpha=0,width=8,face=false,scroll=-14,length=18,light=.1,brightness=1.5})
 local glow=E.Beam(g,at0,at1,{tex="beam.wisp",color=AMBER,alpha=.3,width=16,face=false,scroll=-6,length=30,light=.2})
 local splashAt=0
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local head=len*(1-(1-k)^2)
  local p=d.From+dir*head
  workspace:BulkMoveTo({tip,a1},{CFrame.lookAt(p,p+dir),CFrame.new(start+dir*head)},Enum.BulkMoveMode.FireCFrameChanged)
  while splashAt<=head do
   local s=E.Anchor(g,CFrame.new(start+dir*splashAt))
   E.Emit(s,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,SHINE},{1,AMBER}},life={.4,.7},speed={10,22},spread=35,dir=Enum.NormalId.Top,
    accel=Vector3.new(0,-50,0)},8)
   splashAt+=9
  end
  if t>=T then screech.Enabled=false cone.Enabled=false trail.Enabled=false end
  if t>=T+.5 then
   local f=math.clamp((t-T-.5)/.6,0,1)
   water.Width0=8*(1-f) water.Width1=water.Width0 glow.Width0=16*(1-f) glow.Width1=glow.Width0
   if f>=1 then return false end
  end
  return true
 end)
 E.After(g,T+1.6,function()g:Destroy()end)
end
 -- Scarlet River: whoever the screech catches is bound in red - a ring of thorns closing round them as he drags them
function P.RiverCatch(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T=d.Time or .6
 local g=E.Group("P5RiverCatch")
 local a=E.Anchor(g,vr.CFrame)
 E.Sprite(a,{tex="ring.dots",orient="flat",size={{0,9},{.25,5},{1,5}},alpha={{0,.5},{.25,.05},{1,.5}},color=AMBER,spin={300,300}},T)
 E.Sprite(a,{tex="glow.soft",size=7,alpha={{0,.45},{1,1}},color=AMBER},T)
 local thorns={}
 for i=1,6 do thorns[i]=newPart(g,Vector3.new(.25,.25,3),AMBER,0)end
 E.Step(g,function(_,t)
  if not vr.Parent then return false end
  a.CFrame=vr.CFrame
  local parts,cfs={},{}
  for i,p in ipairs(thorns)do
   local ang=i*math.pi/3+t*4
   local from=vr.Position+Vector3.new(math.cos(ang),0,math.sin(ang))*3.2+UP*(i%2==0 and .8 or -.6)
   parts[#parts+1]=p cfs[#cfs+1]=CFrame.lookAt(from,vr.Position)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T
 end)
 E.After(g,T+.1,function()g:Destroy()end)
end
 -- Scarlet River: the pierce - a long spear of red-gold light bursts through the one he caught, thorns fan out of
 -- their back, red light sprays and a shock ring rolls off the wound
function P.RiverPierce(E,d)
 local g=E.Group("P5RiverPierce")
 local dir=d.Dir or Vector3.zAxis
 local at=d.Pos
 local spear=newPart(g,Vector3.new(.8,.8,.1),WHITE,0)
 local sheath=newPart(g,Vector3.new(2.4,2.4,.1),AMBER,.35)
 local thorns={}
 for i=1,7 do
  local yaw,pitch=(math.random()-.5)*1.1,(math.random()-.5)*.9
  thorns[i]={P=newPart(g,Vector3.new(.3,.3,.1),i%2==0 and AMBER or SHINE,0),Dir=(CFrame.lookAt(Vector3.zero,dir)*CFrame.Angles(pitch,yaw,0)).LookVector,
   Len=6+math.random()*6}
 end
 local a=E.Anchor(g,CFrame.lookAt(at,at+dir))
 E.Sprite(a,{tex="flare.big",size={{0,4},{.15,22},{1,26}},alpha={{0,0},{.5,.35},{1,1}},color=AMBER:Lerp(SHINE,.35)},.4)
 E.Sprite(a,{tex="ring.crisp",orient="flat",dir=Enum.NormalId.Front,size={{0,3},{1,26}},alpha={{0,.1},{1,1}},color=SHINE},.35)
 E.Emit(a,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,AMBER}},life={.35,.7},speed={35,70},spread=35,dir=Enum.NormalId.Front,drag=2},40)
 E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,6}},alpha={{0,.5},{1,1}},color={{0,AMBER},{1,Color3.fromRGB(120,70,10)}},life={.4,.8},speed={14,28},spread=45,dir=Enum.NormalId.Front,drag=3},16)
 E.Light(g,a,AMBER,30,9,.45)
 E.Step(g,function(_,t)
  local k=math.clamp(t/.08,0,1)
  local fade=math.clamp((t-.3)/.3,0,1)
  local len=math.max(24*k,.1)
  spear.Size=Vector3.new(.8*(1-fade),.8*(1-fade),len) sheath.Size=Vector3.new(2.4*(1-fade),2.4*(1-fade),len)
  local cf=CFrame.lookAt(at-dir*3+dir*len*.5,at+dir*len)
  local parts,cfs={spear,sheath},{cf,cf}
  for _,th in ipairs(thorns)do
   local l=math.max(th.Len*k,.1)
   th.P.Size=Vector3.new(.3*(1-fade),.3*(1-fade),l)
   parts[#parts+1]=th.P cfs[#cfs+1]=CFrame.lookAt(at+th.Dir*l*.5,at+th.Dir*l)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<.65
 end)
 E.After(g,1,function()g:Destroy()end)
end

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

 -- shared by the Time / Natural / Space mode skills ------------------------------------------------------------
 -- a sphere swelling from d0 to d1 studs across over t, fading out: a blast's real volume
local function dome(E,g,pos,color,d0,d1,t,alpha,material)
 local p=newPart(g,Vector3.one*d0,color,alpha or .2)
 p.Shape=Enum.PartType.Ball
 if material then p.Material=material end
 p.CFrame=CFrame.new(pos)
 E.Tween(p,t,{Size=Vector3.one*d1,Transparency=1})
 return p
end
 -- the whole screen graded for a moment (a ColorCorrectionEffect), eased back to nothing over t
local function grade(E,props,t)
 local cc=Instance.new("ColorCorrectionEffect")
 for k,v in pairs(props)do cc[k]=v end
 cc.Parent=game:GetService("Lighting")
 E.Tween(cc,t,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE})
 task.delay(t+.1,function()cc:Destroy()end)
end
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
 -- n slivers of light flung out of `c` on arcs, spinning, gone by `life`
local function shards(E,g,c,n,speed,size,colors,life)
 local list={}
 for i=1,n do
  local a=math.random()*math.pi*2
  local p=newPart(g,Vector3.new(size*.22,size*.22,size)*(.6+math.random()*.8),colors[(i-1)%#colors+1],0)
  list[i]={P=p,V=Vector3.new(math.cos(a),.5+math.random()*.9,math.sin(a))*speed*(.6+math.random()*.6),
   R=CFrame.Angles(math.random()*6,math.random()*6,0),S=(math.random()-.5)*20}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,s in ipairs(list)do
   parts[#parts+1]=s.P cfs[#cfs+1]=CFrame.new(c+s.V*t+Vector3.new(0,-45*t*t,0))*s.R*CFrame.Angles(t*s.S,t*s.S*.6,0)
   s.P.Transparency=math.clamp((t-life*.6)/(life*.4),0,1)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<life
 end)
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

 -- Stranglethorns: thorny vines of the northern lights - a living green-gold, tipped with aurora light
local VINE=Color3.fromRGB(96,150,70)
local VINE_TIP=Color3.fromRGB(150,255,190)
local function thorn(g,base,height,width,lean)
 local p=Instance.new("WedgePart")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Size=Vector3.new(width*.6,height,width) p.Color=VINE p.Material=Enum.Material.SmoothPlastic
 p.CFrame=HIDDEN p.Parent=g.Folder
 local tip=newPart(g,Vector3.new(width*.25,height*.35,width*.25),VINE_TIP,.1)
 return {P=p,Tip=tip,Base=base,H=height,Lean=lean or 0}
end
local function placeThorn(th,k)
 local h=th.H*math.max(k,.01)
 th.P.Size=Vector3.new(th.P.Size.X,h,th.P.Size.Z)
 local cf=th.Base*CFrame.Angles(th.Lean,0,0)*CFrame.new(0,h/2,0)
 th.Tip.Size=Vector3.new(th.Tip.Size.X,h*.35,th.Tip.Size.Z)
 return cf,cf*CFrame.new(0,h*.3,0)
end

local VINE_DARK=Color3.fromRGB(44,88,54)
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
local AURORA={{0,MINT},{.5,BLUE},{1,VIOLET}}
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
