--[[
 Polaris (client effect)  -  "the north star judges the sky"

 Beats (seconds from cast start, T = total):
   0 .. Charge      night falls (sky stack), magic circle opens under the boss, aurora
                    curtains unfurl, the star gathers light; seeds orbit the star
   Charge-.35       star pinches inward (anticipation)
   Charge           RELEASE  pop + pillar + ground shock; seeds fly to their dome slots
   per volley       gate star above each target, ground reticle tracks the target,
                    starlight thread; bolt fires, impact or fizzle
   FinaleAt         FINALE  white pop, constellation lights up
   T-1.5 .. T       everything fades, sky returns
 Long-lived layers are single particles whose size/alpha curves are keyed to these beats,
 so they animate on the GPU with no per-frame Lua.
]]
local P={}
local WHITE=Color3.new(1,1,1)
local ICE=Color3.fromRGB(176,226,255)
local DEEP=Color3.fromRGB(10,14,40)
local TAU=math.pi*2
local GOLDEN=2.39996

local casts={}
local latest

local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end
local function pal(d,i)local p=d.Palette return p[(i-1)%#p+1]end

 -- absolute-second keys -> NumberSequence over a particle that lives `life` seconds
local function timeline(keys,life)
 local out,last={},-1
 for _,k in ipairs(keys)do
  local t=math.clamp(k[1]/life,0,1)
  if t<=last then t=last+1e-3 end
  if t<=1 then out[#out+1]={t,k[2]}last=t end
 end
 out[1][1]=0
 if out[#out][1]<1 then out[#out+1]={1,out[#out][2]}else out[#out][1]=1 end
 return out
end

local function domePos(d,center,i,n)
 local el=(i==n)and math.rad(64)or math.rad(6+(42-6)*((i-1)/math.max(n-2,1)))
 local az=i*GOLDEN+.6
 return center+Vector3.new(math.cos(el)*math.cos(az),math.sin(el),math.cos(el)*math.sin(az))*d.DomeRadius
end

local function bossPos(c)
 local r=c.D.Root
 if r and r.Parent then c.LastPos=r.Position end
 return c.LastPos
end

function P.Start(E,d)
 if casts[d.Token]then return end
 local g=E.Group("Polaris")
 local c={D=d,G=g,Subs={},Pulse=0,LastPos=d.Center,Seeds={},Chain={}}
 casts[d.Token]=c latest=c
 local T=d.Total
 local el=math.max(E.Net.Now()-d.T0,0)
 local life=math.max(T-el,.5)
 local function k(keys)  -- shift beat keys by what already elapsed
  local s={}
  for _,p in ipairs(keys)do s[#s+1]={p[1]-el,p[2]}end
  return timeline(s,life)
 end
 local C,F=d.Charge,d.FinaleAt
 local c1,c2,c3=pal(d,1),pal(d,2),pal(d,3)

 c.SkyH=E.Sky.Push("PolarisNight",1.1)

 local center=d.Center
 local boss=d.Root and d.Root:FindFirstAncestorOfClass("Model")
 local ground=d.Ground or E.Ground(center,{boss})or center-Vector3.new(0,6,0)
 c.Ground=ground

  -- opening: a pillar of light tears up from the boss into the sky, a shockwave rolls
  -- out across the ground and stars scatter upward; then the north star ignites
 if el<.4 then
  local ga=E.Anchor(g,CFrame.new(ground+Vector3.new(0,.6,0)))
  local top=E.Anchor(g,CFrame.new(ground+Vector3.new(0,340,0)))
  local p0,p1=E.Attach(ga),E.Attach(top)
  local pc=E.Beam(g,p0,p1,{tex="beam.core",width=2,length=1,mode=Enum.TextureMode.Stretch,color={{0,WHITE},{1,ICE}},alpha={{0,0},{.8,.2},{1,1}},brightness=4,segments=2})
  local ph=E.Beam(g,p0,p1,{tex="beam.stars",width=4,length=40,scroll=-40,color=ICE,alpha={{0,.2},{1,.8}},brightness=2,segments=2,z=-.1})
  E.Tween(pc,.25,{Width0=16,Width1=10},Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
  E.Tween(ph,.25,{Width0=40,Width1=28},Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
  E.After(g,.3,function()
   E.Tween(pc,.9,{Width0=0,Width1=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
   E.Tween(ph,1.1,{Width0=0,Width1=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
  end)
  E.Sprite(ga,{tex="ring.thick",orient="flat",size={{0,10},{1,280}},alpha={{0,0},{1,1}},color=ICE},1.1)
  E.Sprite(ga,{tex="ring.crisp",orient="flat",size={{0,6},{1,200}},alpha={{0,0},{1,1}},color=WHITE},.8)
  E.Sprite(ga,{tex="flare.burst2",size={{0,10},{.2,60},{1,70}},alpha={{0,0},{.4,.3},{1,1}},color=WHITE},.5)
  E.Emit(ga,{tex="star.twinkle",size={{0,2},{1,0}},life={1.2,2},speed={60,130},spread=25,dir=Enum.NormalId.Top,drag=1.2,color={{0,WHITE},{1,ICE}}},60)
  E.Emit(ga,{tex="dot",orient="velocity",squash={{0,2.8},{1,0}},size={{0,1.1},{1,0}},alpha={{0,0},{.7,0},{1,1}},
   color={{0,WHITE},{1,ICE}},life={.4,.8},speed={80,140},spread=85,dir=Enum.NormalId.Top,drag=2},60)
  E.Light(g,ga,ICE,120,12,1)
 end

  -- magic circle: four flat layers counter-rotating, opening over the rise
 local sig=E.Anchor(g,CFrame.new(ground+Vector3.new(0,.35,0)))
 local open={{0,0},{d.Rise+.4,1},{T-1.4,1},{T,0}}
 local function circle(tex,size,alpha,color,spin,z)
  local sz,al={},{}
  for _,p in ipairs(open)do sz[#sz+1]={p[1],size*(.25+.75*p[2])}al[#al+1]={p[1],1-(1-alpha)*p[2]}end
  E.Sprite(sig,{tex=tex,orient="flat",size=k(sz),alpha=k(al),color=color,spin={spin,spin},rot={0,360},z=z},life)
 end
  -- one faint compass ring under the boss; the ground stays mostly clear
 circle("ring.compass",46,.7,WHITE,0,.3)

 local star=E.Anchor(g,CFrame.new(center+Vector3.new(0,13,0)))
 c.Star=star
 local pin,pop=C-.35,C
 c.StarLayers={}
 c.StarLayers[1]=E.Sprite(star,{tex="star.lens",size=k({{0,0},{d.Rise,14},{pin,40},{pop-.02,9},{pop+.12,72},{pop+.7,36},{F-.02,40},{F+.12,96},{F+.8,42},{T-1.4,38},{T,0}}),
  alpha=k({{0,1},{.3,.1},{T-1.4,.1},{T,1}}),color=WHITE,rot={0,0},spin={0,0}},life)
 c.StarLayers[2]=E.Sprite(star,{tex="star.glare",size=k({{0,0},{C,60},{pop+.15,130},{pop+1,70},{F+.15,150},{F+1,80},{T-1.4,70},{T,0}}),
  alpha=k({{0,1},{C,.55},{T-1.4,.6},{T,1}}),color=ICE,spin={-4,-4}},life)
 c.StarLayers[3]=E.Sprite(star,{tex="glow.soft",size=k({{0,0},{C,26},{pin+.2,14},{pop+.1,40},{pop+.6,24},{T-1.4,24},{T,0}}),
  alpha=k({{0,1},{.5,.2},{T-1.4,.2},{T,1}}),color=ICE,z=-.5},life)
 c.StarLayers[4]=E.Sprite(star,{tex="ring.compass",size=k({{0,0},{C,34},{pop+.1,58},{pop+.6,38},{T-1.4,38},{T,0}}),
  alpha=k({{0,1},{C,.6},{T-1.4,.65},{T,1}}),color=c1,spin={-14,-14}},life)
 c.StarLight=E.Light(g,star,ICE,50,3)
  -- ignition: the north star lights at the top of the rise
 if el<d.Rise then
  E.After(g,d.Rise-el,function()
   E.Sprite(star,{tex="flare.big",size={{0,10},{.2,70},{1,80}},alpha={{0,0},{.35,.3},{1,1}},color=WHITE},.5)
   E.Sprite(star,{tex="burst.spiky2",size={{0,8},{1,90}},alpha={{0,0},{.5,.15},{1,1}},color=ICE,rot={0,360}},.45)
   E.Sprite(star,{tex="flare.streak",size={{0,120},{1,150}},alpha={{0,0},{1,1}},color=ICE,rot={0,0}},.4)
   E.Emit(star,{tex="star.twinkle",size={{0,2},{1,0}},life={.8,1.4},speed={20,50},spread=180,drag=2,color={{0,WHITE},{1,ICE}}},30)
   E.Light(g,star,ICE,80,12,.6)
  end)
 end

  -- gather: swirl + inward streaks during the charge
 local gather=E.Anchor(g,star.CFrame)gather.Size=Vector3.one*44
 c.Gather=gather
 if el<C then
  E.Sprite(star,{tex="swirl.blue",size=k({{0,0},{C*.5,46},{pin,30},{C,0}}),alpha=k({{0,1},{C*.4,.25},{C,1}}),spin={-120,-120},z=-1},math.max(C-el,.1))
  c.Inflow=E.Stream(gather,{tex="dot",orient="velocity",squash={{0,2.2},{1,.5}},size={{0,0},{.15,.45},{1,.1}},
   alpha={{0,1},{.2,0},{1,0}},color={{0,c2},{1,WHITE}},life={.8,1},speed={36,46},shape=Enum.ParticleEmitterShape.Sphere,
   inout=Enum.ParticleEmitterShapeInOut.Inward,style=Enum.ParticleEmitterShapeStyle.Surface},160)
  E.After(g,C-el,function()c.Inflow.Enabled=false end)
 end

  -- star dust falling through the whole arena
 local sky=E.Anchor(g,CFrame.new(center+Vector3.new(0,40,0)))sky.Size=Vector3.new(320,90,320)
 c.Dust=E.Stream(sky,{tex="star.twinkle",size={{0,0},{.4,1.8},{1,0}},alpha={{0,1},{.3,.1},{1,1}},
  color={{0,WHITE},{1,c2}},life={2.5,4},speed={0,1},accel=Vector3.new(0,-1.5,0),spin={-40,40}},55)

  -- aurora: a ring of vertical light columns, slowly turning
 local n=20
 local R=d.CurtainRadius*1.6  -- frame the arena, not the star
  -- curtains hang at the boss's hover height, not down near the ground
 local base=ground+Vector3.new(0,math.max((d.Hover or 55)-10,20),0)
 local ring=E.Anchor(g,CFrame.new(base))
 c.Ring,c.RingBase=ring,base
 local step=TAU/n
  -- Each column is a beam running bottom->top. A beam's width follows its attachments'
  -- Y axis (tangent here) and texture streaks run along its length, so the streaks
  -- hang vertically; the length-wise transparency gives a crisp lit hem that fades up.
  -- Columns are 30% wider than their chord so neighbours overlap into one curtain.
 local chord=2*R*math.sin(step/2)*1.3
 local H0=d.CurtainHeight*1.4
 local LAYERS={
  {h=1.7,bright=.45,scroll=0,tint=.15,alpha={{0,.55},{.08,.45},{.4,.78},{1,1}}},
  {tex="beam.streaks",h=1.45,bright=1,scroll=.35,tint=.3,alpha={{0,.4},{.1,.3},{.5,.65},{1,1}}},
  {tex="beam.curtain",h=.85,bright=1.4,scroll=-.5,tint=.55,alpha={{0,.3},{.25,.45},{1,1}}},
 }
 c.Curtain={}
 for i=1,n do
  local a=(i-.5)*step
  local low,high=pal(d,i),pal(d,i+2)
  -- uneven heights give the top a ragged silhouette instead of a flat rim
  local cu={Ang=a,Layers={},Delay=.15+.04*i,HK=.65+.55*(math.noise(i*.37,4.2)+.5)}
  for li,L in ipairs(LAYERS)do
   local a0,a1=E.Attach(ring),E.Attach(ring)
   local b=E.Beam(g,a0,a1,{tex=L.tex,face=false,width=chord,segments=6,length=1,mode=Enum.TextureMode.Stretch,scroll=L.scroll,
    color={{0,E.Tint(low,L.tint)},{.35,low},{1,high}},alpha=L.alpha,brightness=L.bright,z=li*.05})
   cu.Layers[li]={A0=a0,A1=a1,Beam=b,Bright=L.bright,H=H0*L.h}
  end
  c.Curtain[i]=cu
 end

 local shots=d.Shots
 local domeC=center+Vector3.new(0,d.DomeLift,0)
 for i=1,shots do
  local final=i==shots
  local col=pal(d,i)
  local a=E.Anchor(g,star.CFrame)
  local launch=math.max(C+(i-1)*d.ShotGap-d.Telegraph-d.SeedFlight,.25)
  local sd={Part=a,Color=col,Final=final,Launch=launch,Arrive=launch+d.SeedFlight,Target=domePos(d,domeC,i,shots),Att=E.Attach(a)}
  sd.Sprite=E.Sprite(a,{tex=final and"star.lens"or"star.crisp",size=k({{0,0},{.6,final and 5 or 3},{sd.Arrive,final and 9 or 5},{sd.Arrive+.12,final and 22 or 11},{sd.Arrive+.5,final and 12 or 6},
   {F,final and 12 or 6},{F+.15,final and 30 or 14},{F+.8,final and 13 or 7},{T-1.4,final and 12 or 6},{T,0}}),
   alpha=k({{0,1},{.6,0},{T-1.4,0},{T,1}}),color=E.Tint(col,.45),spin={20,20}},life)
  local t0,t1=E.Attach(a,CFrame.new(0,.5,0)),E.Attach(a,CFrame.new(0,-.5,0))
  local tr=Instance.new("Trail")
  tr.Attachment0,tr.Attachment1=t0,t1 tr.Lifetime=.4 tr.LightEmission=1 tr.FaceCamera=true tr.MinLength=.05
  tr.Color=ColorSequence.new(WHITE,col)tr.Transparency=NumberSequence.new(.2,1)tr.WidthScale=NumberSequence.new(1,0)tr.Parent=a
  sd.Trail=tr
  c.Seeds[i]=sd
 end

  -- ending: the north star itself explodes just before the cast ends
 E.After(g,math.max(T-2.2-el,.1),function()P.Explode(E,c)end)

 E.Step(g,function(dt)
  local t=E.Net.Now()-d.T0
  local pos=bossPos(c)
  c.Pulse=c.Pulse*math.exp(-dt*3)
  local sp=pos+Vector3.new(0,13,0)
  star.CFrame=CFrame.new(sp)
  gather.CFrame=star.CFrame
  if c.StarLight then c.StarLight.Brightness=(2+3*smooth(t/C)+8*c.Pulse)*math.clamp((T-t)/1.4,0,1)end
   -- aurora breathes and turns; pulse pushes it outward
  ring.CFrame=CFrame.new(base)*CFrame.Angles(0,t*.035,0)
  local r=R*(1+.12*c.Pulse)
  local fade=math.clamp((T-1.2-t)/1.2,0,1)
  for i,cu in ipairs(c.Curtain)do
   local ang=cu.Ang
   local tangent=Vector3.new(-math.sin(ang),0,math.cos(ang))
   local rr=r+math.sin(i*.9+t*.4)*10+math.sin(t*.7+i*2.1)*3
   local bottom=Vector3.new(math.cos(ang)*rr,math.sin(t*.9+i*.6)*3+math.sin(t*.37+i*1.4)*2,math.sin(ang)*rr)
   local sway=tangent*(math.sin(t*.8+i*.5)*5)
   local u=smooth((t-cu.Delay)/1.4)*fade  -- unfurl upward, roll back down at the end
   for _,L in ipairs(cu.Layers)do
    L.A0.CFrame=CFrame.fromMatrix(bottom,Vector3.yAxis,tangent)
    L.A1.CFrame=CFrame.fromMatrix(bottom+Vector3.yAxis*math.max(L.H*cu.HK*u,.05)+sway*u,Vector3.yAxis,tangent)
    L.Beam.Brightness=L.Bright*(1+2*c.Pulse)
   end
  end
   -- seeds: orbit the star, then arc to their dome slot
  for i,sd in ipairs(c.Seeds)do
   local p
   if t<sd.Launch then
    local th=t*(1+5*smooth(t/C)^2)+i*TAU/#c.Seeds
    p=sp+Vector3.new(math.cos(th)*14,math.sin(th)*6,math.sin(th)*12)
    sd.From=p
   elseif t<sd.Arrive then
    local u=smooth((t-sd.Launch)/d.SeedFlight)
    p=(sd.From or sp):Lerp(sd.Target,u)+Vector3.new(0,math.sin(math.pi*u)*14,0)
   else
    if not sd.Arrived then sd.Arrived=true P.SeedArrive(E,c,i)end
    p=sd.Target+Vector3.new(0,math.sin(t*1.3+i)*1.2,0)
   end
   if not sd.Falling then sd.Part.CFrame=CFrame.new(p)end
  end
  if t>T+3 then P.End(E,{Token=d.Token})return false end
 end)
end

function P.SeedArrive(E,c,i)
 local g,sd=c.G,c.Seeds[i]
 E.Emit(sd.Part,{tex="star.twinkle",size={{0,1.6},{1,0}},life={.5,1},speed={6,16},spread=180,drag=3,color={{0,WHITE},{1,sd.Color}}},sd.Final and 30 or 12)
 E.Sprite(sd.Part,{tex="flare.burst",size={{0,4},{.2,sd.Final and 30 or 16},{1,0}},alpha={{0,0},{1,1}},color=E.Tint(sd.Color,.5)},.45)
  -- starlight thread to the previous star: scrolling dots, faded ends, never a hard line
 local prev=c.Seeds[i-1]
 if prev then
  local b=E.Beam(g,prev.Att,sd.Att,{tex="beam.dots",width=0,length=6,scroll=2.5,segments=12,
   color={{0,prev.Color},{1,sd.Color}},alpha={{0,1},{.15,.25},{.85,.25},{1,1}},brightness=2})
  E.Tween(b,.4,{Width0=1.4,Width1=1.4})
  c.Chain[i]=b
 end
end

local function shock(E,g,pos,c,scale,white)
 local col=white and WHITE or ICE
 local a=E.Anchor(g,CFrame.new(pos))
  -- dark contrast under the flash, then the pop
 E.Sprite(a,{tex="ring.inverse",light=0,color=DEEP,size={{0,20*scale},{1,190*scale}},alpha={{0,.45},{1,1}},z=-2},.4)
 E.Sprite(a,{tex="flare.big",size={{0,30*scale},{.2,70*scale},{1,80*scale}},alpha={{0,0},{.3,.45},{1,1}},color=WHITE},.4)
 E.Sprite(a,{tex="ring.crisp",size={{0,10*scale},{1,170*scale}},alpha={{0,0},{.6,.3},{1,1}},color=col,rot={0,0}},.35)
 E.Sprite(a,{tex="burst.spiky2",size={{0,20*scale},{1,210*scale}},alpha={{0,0},{.5,.15},{1,1}},color=col,rot={0,360}},.5)
 E.Sprite(a,{tex="flare.streak",size={{0,300*scale},{1,340*scale}},alpha={{0,0},{1,1}},color=col,rot={0,0}},.45)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,2.8},{.6,1.2},{1,0}},size={{0,1.6*scale},{1,0}},alpha={{0,0},{.75,0},{1,1}},
  color={{0,WHITE},{.4,col},{1,c and pal(c.D,2)or col}},life={.4,.8},speed={90,150},spread=180,drag=3},90*scale)
 E.Emit(a,{tex="star.twinkle",size={{0,2.2},{1,0}},life={1,2},speed={14,34},spread=180,drag=2,accel=Vector3.new(0,-3,0),color={{0,WHITE},{1,col}}},50*scale)
 E.Light(g,a,col,90,14,.7)
  -- ground: flipbook shock, wide soft ring, ticked ring
 local gp=c and c.Ground
 if gp then
  local ga=E.Anchor(g,CFrame.new(gp+Vector3.new(0,.5,0)))
  E.Sprite(ga,{tex="ring.thick",orient="flat",size={{0,20},{1,280*scale}},alpha={{0,.05},{1,1}},color=col},1.1)
  E.Emit(ga,{tex="smoke",light=0,size={{0,8},{1,26*scale}},alpha={{0,1},{.15,.5},{1,1}},color=Color3.fromRGB(150,170,215),
   life={1.4,2.2},speed={30,60},spread=80,drag=3,dir=Enum.NormalId.Top,rot={0,360},spin={-20,20}},22*scale)
  -- light pillar from the ground through the star
  local top=E.Anchor(g,CFrame.new(gp+Vector3.new(0,320,0)))
  local a0,a1=E.Attach(ga),E.Attach(top)
  local core=E.Beam(g,a0,a1,{tex="beam.core",width=22*scale,length=1,mode=Enum.TextureMode.Stretch,color=WHITE,alpha={{0,.1},{.8,.2},{1,1}},brightness=3})
  local halo=E.Beam(g,a0,a1,{tex="beam.stars",width=60*scale,length=40,scroll=-8,color=col,alpha={{0,.3},{.7,.45},{1,1}},brightness=2,z=-.1})
  E.Tween(core,.9,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
  E.Tween(halo,1.1,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
 end
end

function P.Release(E,d)
 local c=casts[d.Token]if not c then return end
 c.Pulse=1
 shock(E,c.G,c.Star.Position,c,1,false)
end

function P.Finale(E,d)
 local c=casts[d.Token]if not c then return end
 c.Pulse=1
 shock(E,c.G,c.Star.Position,c,1.25,true)
 for i,b in pairs(c.Chain)do
  b.Width0,b.Width1=3.5,3.5
  E.Tween(b,.8,{Width0=1.4,Width1=1.4})
 end
end

function P.Telegraph(E,d)
 local c=casts[d.Token]or latest
 local g=E.Group("PolarisTelegraph")
 if c then c.Subs[#c.Subs+1]=g end
 local col,big=d.Color,d.Final
 local s=big and 1.5 or 1
 local dur=math.max(d.Duration-(E.Net.Now()-d.Start),.05)
 local gate=E.Anchor(g,CFrame.new(d.From))
 E.Sprite(gate,{tex="star.anime",size={{0,0},{.7,8*s},{1,13*s}},alpha={{0,1},{.25,0},{1,0}},color=E.Tint(col,.4),spin={90,90}},dur)
 E.Sprite(gate,{tex="glow.soft",size={{0,0},{1,12*s}},alpha={{0,1},{1,.2}},color=col,z=-.5},dur)
  -- no ground reticle or thread: the gate star in the sky is the only tell
 E.After(g,dur+.05,function()g:Destroy()end)
end

function P.Fire(E,d)
 local g=E.Group("PolarisFire")
 local s=d.Final and 1.6 or 1
 local a=E.Anchor(g,CFrame.new(d.From))
 E.Sprite(a,{tex="flare.burst",size={{0,6*s},{.15,26*s},{1,30*s}},alpha={{0,0},{.55,.2},{1,1}},color=WHITE},.35)
 E.Sprite(a,{tex="flare.streak",size={{0,48*s},{1,56*s}},alpha={{0,0},{1,1}},color=E.Tint(d.Color,.4),rot={0,0}},.3)
 E.Sprite(a,{tex="burst.ice",size={{0,4*s},{1,24*s}},alpha={{0,0},{.6,.2},{1,1}},color=d.Color},.3)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,2.4},{1,0}},size={{0,.7*s},{1,0}},alpha={{0,0},{.7,0},{1,1}},
  color={{0,WHITE},{1,d.Color}},life={.25,.45},speed={30,60},spread=180,drag=4},14*s)
 E.Light(g,a,d.Color,34,7*s,.4)
 E.After(g,1,function()g:Destroy()end)
end

 -- the server's bolt is an invisible carrier; this dresses it on each client
function P.Decorate(E,part)
 local g=E.Group("PolarisBolt")
 local col=part:GetAttribute("Color")or ICE
 local s=part:GetAttribute("Scale")or 1
 local a=E.Anchor(g,part.CFrame)
 local body={}
 body[1]=E.Sprite(a,{tex="star.lens",size=7*s,alpha=0,color=E.Tint(col,.5),spin={200,200}},19)
 body[2]=E.Sprite(a,{tex="glow.soft",size=6*s,alpha=.15,color=col,z=-.5},19)
 local motes=E.Stream(a,{tex="star.twinkle",size={{0,1.3*s},{1,0}},life={.4,.7},speed={0,3},spread=180,color={{0,WHITE},{1,col}}},40)
 local t0,t1=E.Attach(a,CFrame.new(0,.9*s,0)),E.Attach(a,CFrame.new(0,-.9*s,0))
 local tr=Instance.new("Trail")
 tr.Attachment0,tr.Attachment1=t0,t1 tr.Lifetime=.45 tr.LightEmission=1 tr.FaceCamera=true tr.MinLength=.05
 tr.Texture=E.Lib.Id("beam.stars")tr.TextureMode=Enum.TextureMode.Stretch
 tr.Color=ColorSequence.new(WHITE,col)tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
 tr.WidthScale=NumberSequence.new(1,0)tr.Parent=a
 E.Light(g,a,col,16*s,2.4)
 E.Step(g,function(dt)
   -- the carrier replicates at server rate; ease toward it so the star glides
  if part.Parent then a.CFrame=a.CFrame:Lerp(part.CFrame,1-math.exp(-dt*28))return true end
   -- hanging in place and blinking out
  for _,b in ipairs(body)do b:Clear()end
  motes.Enabled=false
  tr.Enabled=false
  E.Sprite(a,{tex="flare.burst",size={{0,4*s},{.3,16*s},{1,18*s}},alpha={{0,0},{.5,.25},{1,1}},color=E.Tint(col,.4)},.3)
  E.Emit(a,{tex="star.crisp",size={{0,1.6*s},{1,0}},alpha={{0,0},{.7,0},{1,1}},color={{0,WHITE},{1,col}},life={.5,.9},speed={18,40},spread=180,drag=2,accel=Vector3.new(0,-30,0),spin={-300,300}},8)
  E.After(g,1,function()g:Destroy()end)
  return false
 end)
end

function P.Impact(E,d)
 local g=E.Group("PolarisImpact")
 local k=d.Heavy and 1.45 or 1
 local col=d.Color
 local a=E.Anchor(g,CFrame.new(d.Pos))
 E.Sprite(a,{tex="glow.soft",light=0,color=DEEP,size={{0,14*k},{1,22*k}},alpha={{0,.35},{1,1}},z=-2},.25)
 E.Sprite(a,{tex="flare.burst2",size={{0,8*k},{.3,16*k},{1,18*k}},alpha={{0,0},{.4,.1},{1,1}},color=WHITE},.2)
 E.Sprite(a,{tex="burst.spiky",size={{0,6*k},{1,32*k}},alpha={{0,0},{.6,.1},{1,1}},color=col,rot={0,360}},.3)
 E.Sprite(a,{tex="flare.streak",size={{0,50*k},{1,60*k}},alpha={{0,0},{1,1}},color=E.Tint(col,.5),rot={0,0}},.25)
 E.Sprite(a,{tex="ring.soft",orient="flat",size={{0,4},{1,36*k}},alpha={{0,.1},{1,1}},color=col},.5)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,2.6},{.6,1.2},{1,0}},size={{0,.9*k},{1,0}},alpha={{0,0},{.75,0},{1,1}},
  color={{0,WHITE},{.35,E.Tint(col,.4)},{1,col}},life={.25,.55},speed={36,72},spread=180,drag=4},30*k)
 E.Emit(a,{tex="star.twinkle",size={{0,1.6},{1,0}},life={.6,1.2},speed={6,16},spread=180,drag=2,accel=Vector3.new(0,4,0),color={{0,WHITE},{1,col}}},10*k)
 E.Emit(a,{tex="smoke",light=0,size={{0,3},{1,10*k}},alpha={{0,1},{.15,.55},{1,1}},color=E.Tint(col,.55),life={1.2,1.8},speed={2,6},spread=180,rot={0,360},spin={-20,20}},6*k)
 local gp=E.Ground(d.Pos)
 if gp and(d.Pos-gp).Magnitude<14 then
  local ga=E.Anchor(g,CFrame.new(gp+Vector3.new(0,.4,0)))
  E.Sprite(ga,{tex="ring.crisp",orient="flat",size={{0,4},{1,30*k}},alpha={{0,0},{1,1}},color=col},.45)
 end
 E.Light(g,a,col,26*k,7,.5)
 E.After(g,2.4,function()g:Destroy()end)
end

function P.Fizzle(E,d)
 local g=E.Group("PolarisFizzle")
 local a=E.Anchor(g,CFrame.new(d.Pos))
  -- a missed bolt bursts and rains star shards
 E.Sprite(a,{tex="flare.burst2",size={{0,6},{.3,22},{1,26}},alpha={{0,0},{.5,.25},{1,1}},color=WHITE},.3)
 E.Sprite(a,{tex="ring.crisp",size={{0,4},{1,26}},alpha={{0,0},{1,1}},color=d.Color},.35)
 E.Emit(a,{tex="star.crisp",size={{0,1.6},{1,0}},alpha={{0,0},{.7,0},{1,1}},color={{0,WHITE},{1,d.Color}},life={.6,1.1},speed={20,45},spread=180,drag=1.5,accel=Vector3.new(0,-40,0),spin={-300,300}},12)
 E.Emit(a,{tex="star.twinkle",size={{0,1.4},{1,0}},life={.6,1.2},speed={6,16},spread=180,drag=2,color={{0,WHITE},{1,d.Color}}},16)
 E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,7}},alpha={{0,1},{.2,.65},{1,1}},color=E.Tint(d.Color,.6),life={.8,1.2},speed={1,3},spread=180},3)
 E.Light(g,a,d.Color,22,5,.35)
 E.After(g,1.6,function()g:Destroy()end)
end

function P.Starfall(E,d)
 local c=casts[d.Token]
 local g=E.Group("PolarisStarfall")
 if c then c.Subs[#c.Subs+1]=g end
 local col,rad,warn=d.Color,d.Radius or 9,d.Warn
 local mark=E.Anchor(g,CFrame.new(d.To+Vector3.new(0,.4,0)))
 E.Sprite(mark,{tex="ring.crisp",orient="flat",size={{0,rad*2.8},{1,rad*2}},alpha={{0,1},{.2,.1},{1,0}},color=col},warn)
 E.Sprite(mark,{tex="ring.dots",orient="flat",size=rad*2.3,alpha={{0,1},{.3,.4},{1,.2}},color=E.Tint(col,.4),spin={90,90}},warn)
 E.Sprite(mark,{tex="disc.soft",orient="flat",size={{0,0},{1,rad*2}},alpha={{0,1},{1,.6}},color=col},warn)
 E.After(g,warn*.8,function()
  E.Sprite(mark,{tex="ring.crisp",orient="flat",size={{0,rad*2.2},{1,rad*2}},alpha={{0,0},{1,.5}},color=WHITE},warn*.2+.1)
 end)
 local sd=c and c.Seeds[d.Index]
 local from=sd and sd.Part.Position or d.To+Vector3.new(0,120,0)
 local diver=sd and sd.Part or E.Anchor(g,CFrame.new(from))
 if sd then sd.Falling=true end
 local a0,a1=E.Attach(diver),E.Attach(mark)
 E.Beam(g,a0,a1,{tex="beam.dots",width=.6,length=6,scroll=-10,segments=2,color={{0,col},{1,WHITE}},alpha={{0,.6},{1,.2}},brightness=1.5})
 local t0=os.clock()
 E.Step(g,function()
  local u=math.clamp((os.clock()-t0)/warn,0,1)
  if diver.Parent then diver.CFrame=CFrame.new(from:Lerp(d.To,u*u*u))end
  if u>=1 then return false end
 end)
 E.After(g,warn+.5,function()a0:Destroy()g:Destroy()end)
end

function P.StarfallHit(E,d)
 local c=casts[d.Token]
 local r=d.Radius or 9
 P.Impact(E,{Pos=d.Pos+Vector3.new(0,1.5,0),Color=d.Color,Heavy=true})
 local g=E.Group("PolarisStarfallHit")
 local a=E.Anchor(g,CFrame.new(d.Pos+Vector3.new(0,.5,0)))
 E.Sprite(a,{tex="ring.inverse",orient="flat",size={{0,r},{1,r*3.4}},alpha={{0,.1},{1,1}},color=d.Color},.5)
 E.Sprite(a,{tex="burst.white",orient="flat",size={{0,r*1.5},{1,r*3}},alpha={{0,0},{1,1}},color=E.Tint(d.Color,.5)},.35)
  -- the star is spent: hide it and let its constellation threads collapse
 if c then
  for i,sd in ipairs(c.Seeds)do
   if sd.Falling and not sd.Spent and(sd.Part.Position-d.Pos).Magnitude<6 then
    sd.Spent=true
    if sd.Sprite then sd.Sprite:Clear()end
    if sd.Trail then sd.Trail.Enabled=false end
    for _,b in ipairs({c.Chain[i],c.Chain[i+1]})do
     if b then E.Tween(b,.25,{Width0=0,Width1=0})end
    end
    break
   end
  end
 end
 E.After(g,1,function()g:Destroy()end)
end

local function blades(E,g,center,ang,len,fn)
 for k=0,3 do
  local a=ang+k*math.pi/2
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local perp=Vector3.new(-dir.Z,0,dir.X)
  local p0=E.Anchor(g,CFrame.new(center+Vector3.new(0,.6,0)))
   -- Y = perp lays the beam flat on the ground
  fn(E.Attach(p0,CFrame.fromMatrix(Vector3.zero,dir,perp)),E.Attach(p0,CFrame.fromMatrix(dir*len,dir,perp)),dir,p0)
 end
end

local function crossColor(d)return d.Index==2 and Color3.fromRGB(255,214,120)or ICE end

function P.Cross(E,d)
 local c=casts[d.Token]
 local g=E.Group("PolarisCross")
 if c then c.Subs[#c.Subs+1]=g end
 local warn,len,w=d.Warn,d.Length,d.Width
 local col=crossColor(d)
 local hub=E.Anchor(g,CFrame.new(d.Center+Vector3.new(0,.5,0)))
 E.Sprite(hub,{tex="ring.compass",orient="flat",size={{0,0},{.3,len*.35},{1,len*.3}},alpha={{0,1},{.3,.35},{1,.2}},color=col},warn)
 blades(E,g,d.Center,d.Angle,len,function(a0,a1)
  local fill=E.Beam(g,a0,a1,{face=false,width=.5,segments=2,color=col,alpha={{0,.55},{.85,.7},{1,1}},brightness=.6})
  local dots=E.Beam(g,a0,a1,{tex="beam.dots",face=false,width=.5,length=8,scroll=14,segments=2,color=WHITE,alpha={{0,.25},{1,.8}},brightness=1.6,z=.1})
  E.Tween(fill,.3,{Width0=w,Width1=w*.75})
  E.Tween(dots,.3,{Width0=w*.55,Width1=w*.35})
  E.Tween(fill,warn-.35,{Brightness=1.6},Enum.EasingStyle.Quad,Enum.EasingDirection.In,.3)
 end)
 E.After(g,warn+.05,function()g:Destroy()end)
end

function P.CrossHit(E,d)
 local c=casts[d.Token]
 local g=E.Group("PolarisCrossHit")
 local len,w=d.Length,d.Width
 local col=crossColor(d)
 blades(E,g,d.Center,d.Angle,len,function(a0,a1,dir,p0)
  local core=E.Beam(g,a0,a1,{tex="beam.core",face=false,width=w*1.3,length=1,mode=Enum.TextureMode.Stretch,segments=2,color=WHITE,alpha={{0,0},{.85,.1},{1,1}},brightness=4})
  local halo=E.Beam(g,a0,a1,{tex="beam.stars",face=false,width=w*2.4,length=30,scroll=-30,segments=2,color=col,alpha={{0,.2},{1,1}},brightness=2,z=-.1})
   -- upright light wall so the strike reads from any camera height
  local h=w*1.8
  local v0=E.Attach(p0,CFrame.fromMatrix(Vector3.new(0,h/2,0),dir,Vector3.yAxis))
  local v1=E.Attach(p0,CFrame.fromMatrix(dir*len+Vector3.new(0,h/2,0),dir,Vector3.yAxis))
  local wall=E.Beam(g,v0,v1,{tex="beam.streaks",face=false,width=h,length=1,mode=Enum.TextureMode.Stretch,segments=2,color={{0,WHITE},{1,col}},alpha={{0,.15},{.8,.4},{1,1}},brightness=2.5})
  for _,b in ipairs({core,halo,wall})do E.Tween(b,.5,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)end
  for s=1,5 do
   local sp=E.Anchor(g,CFrame.new(d.Center+dir*(len*s/5.5)+Vector3.new(0,1,0)))
   E.Emit(sp,{tex="dot",orient="velocity",squash={{0,2.6},{1,0}},size={{0,1.2},{1,0}},alpha={{0,0},{.7,0},{1,1}},
    color={{0,WHITE},{1,col}},life={.3,.6},speed={30,60},spread=60,dir=Enum.NormalId.Top,drag=3},10)
  end
 end)
 local hub=E.Anchor(g,CFrame.new(d.Center+Vector3.new(0,1,0)))
 E.Sprite(hub,{tex="flare.burst",size={{0,20},{.2,60},{1,70}},alpha={{0,0},{.4,.3},{1,1}},color=WHITE},.4)
 E.Sprite(hub,{tex="ring.thick",orient="flat",size={{0,10},{1,len*1.2}},alpha={{0,.1},{1,1}},color=col},.6)
 E.Light(g,hub,col,120,10,.6)
 if c then c.Pulse=math.max(c.Pulse,.6)end
 E.After(g,1.2,function()g:Destroy()end)
end

function P.Explode(E,c)
 if c.Exploded then return end
 c.Exploded=true
 local g=c.G
 local a=E.Anchor(g,c.Star.CFrame)
  -- swell: the star brightens and cracks before it goes
 E.Sprite(a,{tex="glow.soft",size={{0,20},{1,60}},alpha={{0,.6},{1,0}},color=ICE},.55)
 E.Sprite(a,{tex="star.glare2",size={{0,40},{1,110}},alpha={{0,.7},{1,0}},color=WHITE,rot={45,45},spin={60,60}},.55)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,2.4},{1,0}},size={{0,.7},{1,0}},alpha={{0,0},{.7,0},{1,1}},
  color={{0,WHITE},{1,ICE}},life={.2,.35},speed={30,60},spread=180,drag=3},30)
 E.After(g,.55,function()
  for _,l in ipairs(c.StarLayers or{})do l:Clear()l.Size=NumberSequence.new(0)end
  if c.StarLight then c.StarLight.Brightness=0 end
  c.Pulse=.8
   -- burst: sized to read as a star dying at a distance, not a screen whiteout
  E.Sprite(a,{tex="flare.burst2",size={{0,30},{.2,85},{1,95}},alpha={{0,0},{.35,.2},{1,1}},color=WHITE},.45)
  E.Sprite(a,{tex="burst.spiky2",size={{0,20},{1,150}},alpha={{0,0},{.5,.15},{1,1}},color=ICE,rot={0,360}},.5)
  E.Sprite(a,{tex="ring.crisp",size={{0,10},{1,170}},alpha={{0,0},{.6,.3},{1,1}},color=WHITE,rot={0,0}},.45)
  E.Sprite(a,{tex="flare.streak",size={{0,180},{1,220}},alpha={{0,0},{1,1}},color=ICE,rot={0,0}},.4)
  E.Emit(a,{tex="star.crisp",size={{0,3.5},{1,0}},alpha={{0,0},{.7,0},{1,1}},color={{0,WHITE},{1,ICE}},
   life={.9,1.5},speed={60,120},spread=180,drag=1.5,spin={-300,300}},40)
  E.Emit(a,{tex="dot",orient="velocity",squash={{0,2.8},{.6,1.2},{1,0}},size={{0,1.4},{1,0}},alpha={{0,0},{.75,0},{1,1}},
   color={{0,WHITE},{.4,ICE},{1,pal(c.D,2)}},life={.4,.8},speed={90,150},spread=180,drag=3},90)
  E.Emit(a,{tex="star.twinkle",size={{0,2},{1,0}},life={1.4,2.2},speed={8,22},spread=180,drag=1.2,accel=Vector3.new(0,-4,0),color={{0,WHITE},{1,ICE}}},45)
  E.Light(g,a,ICE,90,8,.5)
   -- the blast reaches across the whole map: a ring of light races out over the ground to the far corners
  local fr=c.D.FinalRadius or 400
  local ga=E.Anchor(g,CFrame.new((c.Ground or a.Position)+Vector3.new(0,.5,0)))
  E.Sprite(ga,{tex="ring.thick",orient="flat",size={{0,20},{1,fr*2}},alpha={{0,.05},{.8,.3},{1,1}},color=WHITE},1.3)
  E.Sprite(ga,{tex="ring.crisp",orient="flat",size={{0,10},{1,fr*2}},alpha={{0,0},{.6,.3},{1,1}},color=ICE},1.0)
  E.Emit(ga,{tex="star.twinkle",size={{0,2.5},{1,0}},life={1,2},speed={60,140},spread=80,dir=Enum.NormalId.Top,drag=1.5,color={{0,WHITE},{1,ICE}}},60)
   -- the constellation stars pop in turn and their threads snap
  for i,sd in ipairs(c.Seeds)do
   E.After(g,.04*i,function()
    if sd.Sprite then sd.Sprite:Clear()end
    if sd.Trail then sd.Trail.Enabled=false end
    E.Sprite(sd.Part,{tex="flare.burst",size={{0,5},{.3,20},{1,24}},alpha={{0,0},{.5,.2},{1,1}},color=E.Tint(sd.Color,.5)},.35)
    E.Emit(sd.Part,{tex="star.twinkle",size={{0,1.6},{1,0}},life={.5,1},speed={10,22},spread=180,drag=2,color={{0,WHITE},{1,sd.Color}}},12)
    for _,b in ipairs({c.Chain[i],c.Chain[i+1]})do if b then E.Tween(b,.2,{Width0=0,Width1=0})end end
   end)
  end
 end)
end

function P.End(E,d)
 local c=casts[d.Token]
 if not c then return end
 casts[d.Token]=nil
 if latest==c then latest=nil end
 if c.Inflow then c.Inflow.Enabled=false end
 if c.Dust then c.Dust.Enabled=false end
 c.G:Fade(1.4)
 for _,s in ipairs(c.Subs)do s:Destroy()end
 E.Sky.Pop(c.SkyH,1.6)
end

return P
