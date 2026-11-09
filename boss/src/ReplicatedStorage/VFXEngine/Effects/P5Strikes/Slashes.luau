-- P5Strikes cues: the everyday strikes: mode switch, blink, claws, black/upper slashes, butterfly wings, bolts, counter stance, Wild Hunt, Golden Pierce.
-- Registers its P.<Name>(E, d) functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local P, AMBER, BLUE, BUTTERFLY_GOLD, CRIMSON, GOLD, MINT, MODE_COLORS, PINK = Core.P, Core.AMBER, Core.BLUE, Core.BUTTERFLY_GOLD, Core.CRIMSON, Core.GOLD, Core.MINT, Core.MODE_COLORS, Core.PINK
local Players, SHINE, UP, VIOLET, VOID, WHITE, arcSlash, bladeOf, butterflies = Core.Players, Core.SHINE, Core.UP, Core.VIOLET, Core.VOID, Core.WHITE, Core.arcSlash, Core.bladeOf, Core.butterflies
local flatLook, handCF, handOf, jaws, newPart, place, rootOf, slash = Core.flatLook, Core.handCF, Core.handOf, Core.jaws, Core.newPart, Core.place, Core.rootOf, Core.slash

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

return P
