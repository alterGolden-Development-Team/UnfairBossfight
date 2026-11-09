--[[
 BlackHoleDebris (client effect)
 Add-on to the original black hole client (P5BlackHole.Client, which still draws the hole).
   Hunt       chunks of ground tear off around the hole's shadow and spiral up into it;
              dust rises from the ground beneath
   Explosion  at the same moment the old client fires its supernova
              (CollapseAt + FadeT*BurstAt): implosion snaps every chunk inward, then a
              violet-white blast, three shockwave rings, a light pillar, chunks flung back
              out under gravity, ground shock and smoke, and a distance-scaled screen flash
]]
local Players=game:GetService("Players")
local B={}
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
local VIOLET=Color3.fromRGB(132,72,255)
local GOLD=Color3.fromRGB(255,185,62)
local PALE=Color3.fromRGB(235,220,255)

local function screenFlash(at,range)
 local plr=Players.LocalPlayer
 local pg=plr and plr:FindFirstChildOfClass("PlayerGui")
 local cam=workspace.CurrentCamera
 if not pg or not cam then return end
 local near=1-math.clamp((cam.CFrame.Position-at).Magnitude/range,0,1)
 if near<=0 then return end
 local gui=Instance.new("ScreenGui")gui.Name="BlackHoleFlash"gui.IgnoreGuiInset=true gui.DisplayOrder=25
 local f=Instance.new("Frame")f.Size=UDim2.fromScale(1,1)f.BorderSizePixel=0 f.BackgroundColor3=PALE
 f.BackgroundTransparency=1-math.min(near*1.1,.9)f.Parent=gui
 gui.Parent=pg
 game:GetService("TweenService"):Create(f,TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
 game:GetService("Debris"):AddItem(gui,.8)
end

function B.Decorate(E,root)
 local g=E.Group("BlackHoleDebris")
 local A=function(k,d)local v=root:GetAttribute(k)if v==nil then return d end return v end
 local core=A("Core",16)
 local pull=A("Pull",100)
 local foot=A("Foot",8)
 local fadeT,burstAt=A("FadeT",1.6),A("BurstAt",.62)
 local pos=root.Position
 local rocks,flung={},{}
 local nextRock=0
 local burst=false
 local rayParams=RaycastParams.new()
 rayParams.FilterType=Enum.RaycastFilterType.Exclude
 rayParams.FilterDescendantsInstances={g.Folder,root}

 local floor=E.Anchor(g,CFrame.new(pos.X,A("GroundY",pos.Y-14)+.35,pos.Z))
 floor.Size=Vector3.new(foot*4,1,foot*4)
 local dust=E.Stream(floor,{tex="smoke",light=0,color=Color3.fromRGB(40,26,70),size={{0,2},{1,6}},alpha={{0,1},{.2,.55},{1,1}},
  life={1.2,1.8},speed={4,8},dir=Enum.NormalId.Top,accel=Vector3.new(0,14,0),rot={0,360},spin={-60,60}},0)

 local function chunk(at,size)
  local hit=workspace:Raycast(at+Vector3.new(0,4,0),Vector3.new(0,-12,0),rayParams)
  local p=Instance.new("Part")
  p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
  p.Size=Vector3.new(size,size*(.5+math.random()*.6),size*(.7+math.random()*.5))
  p.Material=hit and hit.Material or Enum.Material.Slate
  if p.Material==Enum.Material.Grass then p.Material=Enum.Material.Ground end
  p.Color=hit and hit.Instance.Color or Color3.fromRGB(90,84,76)
  p.CFrame=CFrame.new(hit and hit.Position or at)*CFrame.Angles(math.random()*6,math.random()*6,math.random()*6)
  p.Parent=g.Folder
  return p
 end

 local function tear(center,gy)
  local ang=math.random()*math.pi*2
  local dist=foot+math.random()*pull*.45
  local p=chunk(Vector3.new(center.X+math.cos(ang)*dist,gy,center.Z+math.sin(ang)*dist),.8+math.random()*2.4)
  rocks[#rocks+1]={P=p,From=p.Position,Size=p.Size,Born=os.clock(),Dur=1.6+math.random()*1.2,Ang=ang,Dist=dist,
   Spin=Vector3.new(math.random()*6-3,math.random()*6-3,math.random()*6-3)}
 end

 local function explode(at)
  burst=true
  dust.Enabled=false
   -- implosion: every chunk still in flight snaps into the centre
  for _,r in ipairs(rocks)do r.Dur=math.min(r.Dur,(os.clock()-r.Born)+.08)end
  local a=E.Anchor(g,CFrame.new(at))
  E.Sprite(a,{tex="ring.inverse",light=0,color=BLACK,size={{0,core*6},{1,core*.5}},alpha={{0,.1},{1,.5}},z=-3},.1)
  screenFlash(at,pull*2)
  E.After(g,.08,function()
   E.Sprite(a,{tex="flare.big",size={{0,core*2},{.15,core*12},{1,core*14}},alpha={{0,0},{.3,.2},{1,1}},color=PALE},.6)
   E.Sprite(a,{tex="burst.spiky2",size={{0,core*2},{1,core*16}},alpha={{0,0},{.5,.1},{1,1}},color=VIOLET,rot={0,360}},.6)
   E.Sprite(a,{tex="flare.burst2",size={{0,core*3},{1,core*13}},alpha={{0,0},{.4,.25},{1,1}},color=GOLD,spin={50,50}},.7)
   E.Sprite(a,{tex="flare.streak",size={{0,core*22},{1,core*24}},alpha={{0,0},{1,1}},color=PALE,rot={0,0}},.5)
   for k=0,2 do
    E.After(g,k*.1,function()
     E.Sprite(a,{tex="ring.crisp",size={{0,core},{1,core*(10+3*k)}},alpha={{0,0},{.6,.25},{1,1}},color=k==1 and PALE or VIOLET,rot={0,0}},.55+.1*k)
    end)
   end
   E.Emit(a,{tex="dot",orient="velocity",squash={{0,3},{.6,1.3},{1,0}},size={{0,1.8},{1,0}},alpha={{0,0},{.75,0},{1,1}},
    color={{0,WHITE},{.4,PALE},{1,VIOLET}},life={.6,1.1},speed={110,200},spread=180,drag=2.5},170)
   E.Emit(a,{tex="star.twinkle",size={{0,2.4},{1,0}},life={1.2,2.2},speed={20,50},spread=180,drag=2,color={{0,WHITE},{1,VIOLET}}},70)
   E.Light(g,a,PALE,170,16,.9)
    -- light pillar through the hole
   local gy=A("GroundY",at.Y-14)
   local ga=E.Anchor(g,CFrame.new(at.X,gy+.5,at.Z))
   local top=E.Anchor(g,CFrame.new(at.X,gy+320,at.Z))
   local p0,p1=E.Attach(ga),E.Attach(top)
   local pil=E.Beam(g,p0,p1,{tex="beam.core",width=core*1.6,length=1,mode=Enum.TextureMode.Stretch,color={{0,WHITE},{1,VIOLET}},alpha={{0,0},{.7,.3},{1,1}},brightness=4,segments=2})
   E.Tween(pil,.8,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    -- ground shock and smoke
   E.Sprite(ga,{tex="ring.thick",orient="flat",size={{0,foot*2},{1,pull*2.6}},alpha={{0,0},{1,1}},color=VIOLET},1)
   E.Sprite(ga,{tex="ring.multi",orient="flat",size={{0,foot},{1,pull*2}},alpha={{0,0},{.5,.25},{1,1}},color=PALE},.9)
   E.Emit(ga,{tex="smoke",light=0,color=Color3.fromRGB(60,44,90),size={{0,5},{1,18}},alpha={{0,1},{.15,.45},{1,1}},
    life={1.4,2.2},speed={50,95},spread=85,dir=Enum.NormalId.Top,drag=3,rot={0,360}},34)
    -- chunks flung back out
   for i=1,22 do
    local p=chunk(at,1+math.random()*2.6)
    p.CFrame=CFrame.new(at)
    local dir=Vector3.new(math.random()*2-1,math.random()*.8-.2,math.random()*2-1).Unit
    flung[#flung+1]={P=p,V=dir*(60+math.random()*70),Spin=Vector3.new(math.random()*10-5,math.random()*10-5,math.random()*10-5),Born=os.clock()}
   end
  end)
  E.After(g,3.5,function()g:Destroy()end)
 end

  -- summon: the hole condenses between the boss's raised hands, then bursts open
 local born,holdT=A("Born",E.Net.Now()),A("HoldT",1.3)
 local sinceBorn=E.Net.Now()-born
 if A("Stage","")=="Summon"and sinceBorn<holdT then
  local left=holdT-sinceBorn
  local hand=E.Anchor(g,CFrame.new(root.Position))
  local shell=E.Anchor(g,CFrame.new(root.Position))shell.Size=Vector3.one*70
  local inflow=E.Stream(shell,{tex="dot",orient="velocity",squash={{0,2.8},{1,.8}},size={{0,0},{.2,.7},{1,.15}},alpha={{0,1},{.2,0},{1,.3}},
   color={{0,GOLD},{.5,VIOLET},{1,BLACK}},life={.75,.9},speed={45,60},shape=Enum.ParticleEmitterShape.Sphere,
   inout=Enum.ParticleEmitterShapeInOut.Inward,style=Enum.ParticleEmitterShapeStyle.Surface},220)
  local coreFx=E.Sprite(hand,{tex="glow.soft",light=0,color=BLACK,size={{0,0},{1,core*1.6}},alpha={{0,.3},{1,0}},z=1},left+.15)
  local rim=E.Sprite(hand,{tex="ring.crisp",size={{0,0},{1,core*2}},alpha={{0,.6},{1,.1}},color=PALE,spin={240,240},z=1.1},left+.15)
  local haze=E.Sprite(hand,{tex="vortex.soft",size={{0,10},{1,core*5}},alpha={{0,.7},{1,.35}},color=VIOLET,spin={-160,-160},z=.5},left+.15)
   -- spiral arms: motes orbit in and leave trails that wind into the hole
  local arms={}
  for k=1,6 do
   local m2=E.Anchor(g,hand.CFrame)
   local t0a,t1a=E.Attach(m2,CFrame.new(0,.5,0)),E.Attach(m2,CFrame.new(0,-.5,0))
   local tr=Instance.new("Trail")
   tr.Attachment0,tr.Attachment1=t0a,t1a tr.Lifetime=.35 tr.LightEmission=1 tr.FaceCamera=true tr.MinLength=.05
   tr.Color=ColorSequence.new(k%2==0 and GOLD or PALE,VIOLET)tr.Transparency=NumberSequence.new(0,1)tr.WidthScale=NumberSequence.new(1,0)
   tr.Parent=m2
   arms[k]={P=m2,Phase=k*math.pi/3,Tilt=(k%3)*.5}
  end
  local rings=0
  local s0=os.clock()
  E.Step(g,function()
   local u=math.clamp((os.clock()-s0)/left,0,1)
   local c=root.Parent and root.Position or hand.Position
   hand.CFrame=CFrame.new(c)shell.CFrame=hand.CFrame
   local rad=38*(1-u)^1.4+1
   for _,arm in ipairs(arms)do
    local a=arm.Phase+u*9
    arm.P.CFrame=CFrame.new(c+Vector3.new(math.cos(a)*rad,math.sin(a*.7+arm.Tilt)*rad*.35,math.sin(a)*rad))
   end
   if u*6>rings then  -- pulses collapsing inward
    rings+=1
    E.Sprite(hand,{tex="ring.inverse",size={{0,70},{1,2}},alpha={{0,.75},{1,.2}},color=VIOLET},.35)
   end
   if u>=1 then
    inflow.Enabled=false
    for _,arm in ipairs(arms)do arm.P:Destroy()end
    coreFx:Clear()rim:Clear()haze:Clear()
     -- snap, then the hole bursts open
    E.Sprite(hand,{tex="ring.inverse",light=0,color=BLACK,size={{0,core*5},{1,1}},alpha={{0,.2},{1,.6}},z=2},.12)
    E.After(g,.1,function()
     E.Sprite(hand,{tex="flare.big",size={{0,core},{.2,core*7},{1,core*8}},alpha={{0,0},{.35,.25},{1,1}},color=PALE},.45)
     E.Sprite(hand,{tex="burst.spiky2",size={{0,core},{1,core*9}},alpha={{0,0},{.5,.15},{1,1}},color=VIOLET,rot={0,360}},.45)
     E.Sprite(hand,{tex="ring.crisp",size={{0,core},{1,core*10}},alpha={{0,0},{.6,.2},{1,1}},color=GOLD,rot={0,0}},.4)
     E.Emit(hand,{tex="dot",orient="velocity",squash={{0,2.8},{1,0}},size={{0,1.3},{1,0}},alpha={{0,0},{.7,0},{1,1}},
      color={{0,WHITE},{.4,GOLD},{1,VIOLET}},life={.4,.8},speed={70,130},spread=180,drag=2.5},90)
     E.Light(g,hand,VIOLET,90,10,.6)
    end)
    return false
   end
  end)
   -- dust rises from under the boss toward its hands
  local gy=A("GroundY",root.Position.Y-14)
  local base=E.Anchor(g,CFrame.new(root.Position.X,gy+.4,root.Position.Z))base.Size=Vector3.new(30,1,30)
  local lift=E.Stream(base,{tex="smoke",light=0,color=Color3.fromRGB(60,40,90),size={{0,3},{1,8}},alpha={{0,1},{.25,.55},{1,1}},
   life={1,1.4},speed={6,12},dir=Enum.NormalId.Top,accel=Vector3.new(0,22,0),rot={0,360},spin={-80,80}},30)
  E.After(g,left,function()lift.Enabled=false end)
 end

 E.Step(g,function(dt)
  if root.Parent then pos=pos:Lerp(root.Position,1-math.exp(-dt*24))end
  local gy=A("GroundY",pos.Y-14)
  floor.CFrame=CFrame.new(pos.X,gy+.35,pos.Z)
  local hunting=root.Parent and A("Stage","")=="Hunt"and not burst
  dust.Rate=hunting and 22*E.Quality or 0
  if hunting and os.clock()>=nextRock and #rocks<28*E.Quality then
   nextRock=os.clock()+.09
   tear(pos,gy)
  end
  for i=#rocks,1,-1 do
   local r=rocks[i]
   local u=(os.clock()-r.Born)/r.Dur
   if u>=1 or not r.P.Parent then
    if r.P.Parent then r.P:Destroy()end
    table.remove(rocks,i)
   else
    local e=u*u  -- slow lift, then sucked in
    local swirl=r.Ang+u*math.pi*2.2
    local rad=r.Dist*(1-e)
    local p=Vector3.new(pos.X+math.cos(swirl)*rad,r.From.Y+(pos.Y-r.From.Y)*e,pos.Z+math.sin(swirl)*rad)
    r.P.CFrame=CFrame.new(p)*(r.P.CFrame-r.P.Position)*CFrame.Angles(r.Spin.X*dt,r.Spin.Y*dt,r.Spin.Z*dt)
    r.P.Size=r.Size*math.max(1-math.max(u-.6,0)/.4,.05)
   end
  end
  for i=#flung,1,-1 do
   local f=flung[i]
   local age=os.clock()-f.Born
   if age>2.6 or not f.P.Parent then
    if f.P.Parent then f.P:Destroy()end
    table.remove(flung,i)
   else
    f.V+=Vector3.new(0,-90,0)*dt
    f.P.CFrame=(f.P.CFrame+f.V*dt)*CFrame.Angles(f.Spin.X*dt,f.Spin.Y*dt,f.Spin.Z*dt)
    if age>1.8 then f.P.Transparency=(age-1.8)/.8 end
   end
  end
  local ca=A("CollapseAt",0)
  if not burst and ca>0 and E.Net.Now()-ca>=fadeT*burstAt then explode(pos)end
  if not root.Parent and not burst then
   for _,r in ipairs(rocks)do r.P:Destroy()end
   table.clear(rocks)
   g:Fade(.4)
   return false
  end
 end)
end

return B
