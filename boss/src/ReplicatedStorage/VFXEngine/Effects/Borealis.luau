--[[
 Borealis (client effect) - a beam of northern light poured onto each target.
 The server moves an invisible beacon on the ground under its target (tag VFXDecorate,
 VFX="Borealis") with timing attributes (StartT, Windup, CaughtAt, Ticks, Finale, DoneAt).

 Layers (all fade by their own alpha; nothing snaps to zero width)
   sky      aurora vortex the light pours out of
   beam     white core, cyan->violet body, soft glow, outer sheath
   helix    two strands spiralling up the beam
   pour     light streaks falling down the beam
   foot     splash glow, frost motes rising, mist rolling out
 Beats: Windup (sky opens, thin guide) -> Chase (beam lands and follows) -> Caught (beam
 tightens and brightens, rings climb the target, ticks flash) -> End (white flash, the beam
 thins and withdraws up into the sky, the helix unwinds upward, frost shards burst).
]]
local Bo={}
local WHITE=Color3.new(1,1,1)
local CYAN=Color3.fromRGB(115,255,205)
local SKY=Color3.fromRGB(98,195,255)
local VIOLET=Color3.fromRGB(174,114,255)
local TAU=math.pi*2
local NODES=26

local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end
local function alphaSeq(base,k)  -- base keys {{t,a}}, faded toward 1 by (1-k)
 local out={}
 for _,p in ipairs(base)do out[#out+1]=NumberSequenceKeypoint.new(p[1],1-(1-p[2])*k)end
 return NumberSequence.new(out)
end

function Bo.Decorate(E,beacon)
 local g=E.Group("Borealis")
 local A=function(k,d)local v=beacon:GetAttribute(k)if v==nil then return d end return v end
 local R=A("Radius",16)
 local H=A("Sky",260)
 local windup=A("Windup",1)
 local startT=A("StartT",E.Net.Now())
 local life=19
 local pos=beacon.Position
 local helixH=math.min(H*.45,110)

 local ground=E.Anchor(g,CFrame.new(pos+Vector3.new(0,.35,0)))
 local axis=E.Anchor(g,CFrame.new(pos))
 local top=E.Anchor(g,CFrame.new(pos+Vector3.yAxis*H))
 local pourBox=E.Anchor(g,CFrame.new(pos+Vector3.yAxis*helixH))pourBox.Size=Vector3.new(R*.8,1,R*.8)
 local mistBox=E.Anchor(g,ground.CFrame)mistBox.Size=Vector3.new(R*1.4,1,R*1.4)

 local vortex=E.Sprite(top,{tex="vortex.soft",orient="flat",size={{0,0},{windup/life,R*7},{1,R*6}},alpha={{0,1},{.05,.3},{1,.4}},color=SKY,spin={-60,-60}},life)
 local a0,a1=E.Attach(ground),E.Attach(top)
 local guide=E.Beam(g,a0,a1,{tex="beam.dots",width=.6,length=10,scroll=-30,color={{0,WHITE},{1,SKY}},alpha={{0,.3},{1,.8}},brightness=2,segments=2})

 local L={
  core={B=E.Beam(g,a0,a1,{tex="beam.core",width=0,length=1,mode=Enum.TextureMode.Stretch,color={{0,WHITE},{.5,Color3.fromRGB(220,255,245)},{1,CYAN}},brightness=5,segments=2,z=.3}),A={{0,0},{.6,.1},{1,1}},W0=.5,W1=.65},
  body={B=E.Beam(g,a0,a1,{tex="beam.streaks",width=0,length=40,scroll=-30,color={{0,CYAN},{.3,SKY},{1,VIOLET}},brightness=2.8,segments=2,z=.2}),A={{0,0},{.35,.15},{1,1}},W0=1.7,W1=2.3},
  glow={B=E.Beam(g,a0,a1,{tex="beam.core",width=0,length=1,mode=Enum.TextureMode.Stretch,color={{0,CYAN},{.5,SKY},{1,VIOLET}},brightness=1.8,segments=2,z=.1}),A={{0,.2},{.4,.4},{1,1}},W0=2.8,W1=3.4},
  sheath={B=E.Beam(g,a0,a1,{tex="beam.stars",width=0,length=30,scroll=-50,color={{0,WHITE},{1,SKY}},brightness=2,segments=2,z=0}),A={{0,.35},{.5,.55},{1,1}},W0=3.6,W1=4.2},
 }
 local strands={}
 for s=1,2 do
  local nodes,segs={},{}
  for i=1,NODES do nodes[i]=E.Attach(axis)end
  for i=1,NODES-1 do
   local k=(i-1)/(NODES-2)
   segs[i]={B=E.Beam(g,nodes[i],nodes[i+1],{width=0,segments=1,color=WHITE:Lerp(CYAN,math.min(k*2,1)):Lerp(VIOLET,math.max(k*2-1,0)),brightness=3,z=.4}),K=k}
  end
  strands[s]={Nodes=nodes,Segs=segs,Phase=(s-1)*math.pi}
 end
 local pour=E.Stream(pourBox,{tex="dot",orient="velocity",squash={{0,3},{1,2}},size={{0,.55},{1,.3}},alpha={{0,.2},{.8,.2},{1,1}},
  color={{0,WHITE},{1,CYAN}},life={.55,.7},speed={140,170},dir=Enum.NormalId.Bottom},0)
 local rise=E.Stream(ground,{tex="star.twinkle",size={{0,1.5},{1,0}},alpha={{0,0},{.8,0},{1,1}},color={{0,WHITE},{1,CYAN}},
  life={1,1.6},speed={30,60},spread=12,dir=Enum.NormalId.Top},0)
 local mist=E.Stream(mistBox,{tex="smoke",light=.35,color=Color3.fromRGB(150,230,255),size={{0,3},{1,11}},alpha={{0,1},{.25,.6},{1,1}},
  life={1.2,1.8},speed={10,18},spread=80,dir=Enum.NormalId.Top,drag=2.5,accel=Vector3.new(0,-3,0),rot={0,360},spin={-30,30}},0)
 local splash=E.Sprite(ground,{tex="glow.soft",orient="flat",size=R*2.6,alpha=1,color=CYAN},life)
 local light=E.Light(g,ground,CYAN,48,0)

 local function ringsUp(n,color)
  E.Emit(ground,{tex="ring.crisp",orient="flat",size={{0,R*1.5},{1,R*.9}},alpha={{0,0},{.7,.3},{1,1}},color=color,life={.9,1.2},speed={30,45},dir=Enum.NormalId.Top},n)
 end

 local width,show,helixA,retract=0,0,0,0
 local opened,caught,finaled,ended=false,false,false,false
 local lastTicks=A("Ticks",0)

 E.Step(g,function(dt)
  if not beacon.Parent and not ended then ended=true end
  local now=E.Net.Now()
  local t=now-startT
  if beacon.Parent then pos=pos:Lerp(beacon.Position,1-math.exp(-dt*20))end
  ground.CFrame=CFrame.new(pos+Vector3.new(0,.35,0))
  axis.CFrame=CFrame.new(pos)
  top.CFrame=CFrame.new(pos+Vector3.yAxis*H)
  pourBox.CFrame=CFrame.new(pos+Vector3.yAxis*helixH)
  mistBox.CFrame=ground.CFrame
  local caughtAt=beacon.Parent and A("CaughtAt",0)or 0
  if beacon.Parent and A("DoneAt",0)>0 then ended=true end

  if t>=windup and not opened then
   opened=true
   guide.Width0,guide.Width1=0,0
   E.Sprite(ground,{tex="flare.burst",size={{0,R},{.3,R*4.5},{1,R*5}},alpha={{0,0},{1,1}},color=WHITE},.35)
   E.Sprite(ground,{tex="ring.thick",orient="flat",size={{0,R},{1,R*6}},alpha={{0,0},{1,1}},color=CYAN},.55)
   E.Emit(ground,{tex="star.anime",size={{0,1.6},{1,0}},alpha={{0,0},{.8,0},{1,1}},color={{0,WHITE},{1,CYAN}},
    life={.6,1},speed={30,60},spread=55,dir=Enum.NormalId.Top,accel=Vector3.new(0,-60,0),spin={-300,300}},18)
   ringsUp(3,CYAN)
  end
  if caughtAt>0 and not caught then
   caught=true
   E.Sprite(ground,{tex="flare.burst2",size={{0,R},{.3,R*4},{1,R*4.5}},alpha={{0,0},{1,1}},color=WHITE},.35)
   ringsUp(4,WHITE)
  end
  if beacon.Parent and A("Finale",false)and not finaled then
   finaled=true
   E.Sprite(ground,{tex="flare.big",size={{0,R*2},{.2,R*7},{1,R*8}},alpha={{0,0},{.4,.3},{1,1}},color=WHITE},.5)
   E.Sprite(ground,{tex="ring.crisp",size={{0,R},{1,R*9}},alpha={{0,0},{1,1}},color=SKY},.5)
   E.Emit(ground,{tex="dot",orient="velocity",squash={{0,2.8},{1,0}},size={{0,1.3},{1,0}},alpha={{0,0},{.7,0},{1,1}},
    color={{0,WHITE},{1,CYAN}},life={.4,.8},speed={70,140},spread=50,dir=Enum.NormalId.Top,drag=2},70)
  end
  local ticks=beacon.Parent and A("Ticks",0)or lastTicks
  if ticks~=lastTicks then
   lastTicks=ticks
   ringsUp(2,E.Tint(CYAN,.4))
   E.Sprite(ground,{tex="glow.soft",size={{0,R*1.5},{1,R*3}},alpha={{0,.2},{1,1}},color=CYAN},.25)
  end

   -- end sequence (every beam): flash, the foot rises into the sky, all layers fade
  if ended and retract==0 then
   E.Sprite(ground,{tex="flare.burst2",size={{0,R},{.25,R*5},{1,R*5.5}},alpha={{0,0},{.4,.2},{1,1}},color=WHITE},.4)
   E.Sprite(ground,{tex="ring.crisp",orient="flat",size={{0,R},{1,R*5}},alpha={{0,0},{1,1}},color=CYAN},.5)
   E.Emit(ground,{tex="star.crisp",size={{0,1.6},{1,0}},alpha={{0,0},{.7,0},{1,1}},color={{0,WHITE},{1,CYAN}},
    life={.6,1.1},speed={30,70},spread=70,dir=Enum.NormalId.Top,accel=Vector3.new(0,-50,0),spin={-300,300}},24)
   E.Emit(ground,{tex="dot",orient="velocity",squash={{0,3},{1,1}},size={{0,1},{1,.2}},alpha={{0,0},{.7,0},{1,1}},
    color={{0,WHITE},{1,CYAN}},life={.6,1},speed={120,180},spread=12,dir=Enum.NormalId.Top},40)
   E.Sprite(top,{tex="flare.big",orient="flat",size={{0,R*3},{.3,R*9},{1,R*10}},alpha={{0,0},{.5,.3},{1,1}},color=SKY},.9)
   retract=1e-3
  end
  if ended then retract=math.min(retract+dt/.9,1)end
  local r=smooth(retract)

   -- widths ease; strength goes to 0 only through alpha, never a width snap
  local target=(opened and not ended)and R*(caughtAt>0 and .8 or 1)or(ended and R*.5 or 0)
  width+=(target-width)*(1-math.exp(-dt*(target>width and 10 or 4)))
  show+=(((opened and not ended)and 1 or 0)-show)*(1-math.exp(-dt*(ended and 3.5 or 8)))
  local boost=caughtAt>0 and not ended and 1.25 or 1
  local w=math.max(width,.05)
  a0.Position=Vector3.yAxis*H*.95*r*r
  for _,l in pairs(L)do
   l.B.Width0,l.B.Width1=w*l.W0*boost,w*l.W1*boost
   l.B.Transparency=alphaSeq(l.A,show)
  end
  helixA+=(((opened and not ended)and 1 or 0)-helixA)*(1-math.exp(-dt*(ended and 2.5 or 6)))
  local spin=caughtAt>0 and not ended and 4.2 or 2
  local hr=w*(caughtAt>0 and .75 or .95)
  for _,st in ipairs(strands)do
   for i,node in ipairs(st.Nodes)do
    local k=(i-1)/(NODES-1)
    local a=st.Phase+k*TAU*1.6-t*spin-r*4
    node.Position=Vector3.new(math.cos(a)*hr*(1+r),k*helixH+r*r*H*.7,math.sin(a)*hr*(1+r))
   end
   for _,sg in ipairs(st.Segs)do
    local sw=1.2-.8*sg.K
    sg.B.Width0,sg.B.Width1=sw,sw
    sg.B.Transparency=NumberSequence.new(1-(1-(.1+.8*sg.K))*helixA)
   end
  end
  local on=show>.2
  pour.Rate=on and 70*E.Quality or 0
  rise.Rate=on and 26*E.Quality or 0
  mist.Rate=on and 10*E.Quality or 0
  splash.Transparency=alphaSeq({{0,.55},{1,.55}},show)
  light.Brightness=show*(caughtAt>0 and 7 or 4)
  if ended and retract>=1 and show<.03 then
   vortex:Clear()
   g:Fade(.3)
   return false
  end
 end)
end

return Bo
