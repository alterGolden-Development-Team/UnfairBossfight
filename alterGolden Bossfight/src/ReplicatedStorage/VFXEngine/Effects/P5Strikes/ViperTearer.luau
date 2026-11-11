-- P5Strikes cues: Slam, Viper, Horrifying Ground (stab + cage) and Night Tearer, plus the lethal/jump warning over a player.
-- Registers its P.<Name>(E, d) functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local P, AMBER, BUTTERFLY_GOLD, CRIMSON, GOLD, HIDDEN, Players, SHINE, UP = Core.P, Core.AMBER, Core.BUTTERFLY_GOLD, Core.CRIMSON, Core.GOLD, Core.HIDDEN, Core.Players, Core.SHINE, Core.UP
local VOID, WHITE, bladeOf, cracks, debris, handCF, handOf, jaws, newPart = Core.VOID, Core.WHITE, Core.bladeOf, Core.cracks, Core.debris, Core.handCF, Core.handOf, Core.jaws, Core.newPart
local place, rootOf, slash = Core.place, Core.rootOf, Core.slash

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

return P
