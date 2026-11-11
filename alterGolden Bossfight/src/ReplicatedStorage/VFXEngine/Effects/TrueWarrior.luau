local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Assets=script.Parent.Parent:WaitForChild("Assets")
local Fov=require(Shared.Presentation.CameraFov)
local Reset=require(Shared.Presentation.CinematicReset)

local T={}
local GOLD=Color3.fromRGB(255,214,120)
local SHINE=Color3.fromRGB(255,244,205)
local FLAME=Color3.fromRGB(255,130,40)
local EMBER=Color3.fromRGB(255,72,18)
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
local UP=Vector3.yAxis
local NEON=Enum.Material.Neon
local CAM_STEP="TrueWarriorCine"
local IMPACT_STEP="TrueWarriorImpact"
local REDUCE_FLASHING=false
local SFX={Sonic="rbxassetid://9120769331",Explosion="rbxassetid://9114362135"}
local player=Players.LocalPlayer

local function isLocal(char)return char==player.Character end
local function rootOf(char)return char and char:FindFirstChild("HumanoidRootPart")end
local function flat(v)
 local f=Vector3.new(v.X,0,v.Z)
 return f.Magnitude>.01 and f.Unit or Vector3.new(0,0,-1)
end
local function play(id,at,volume,speed)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Transparency=1 p.Size=Vector3.one p.CFrame=CFrame.new(at)
 local s=Instance.new("Sound")
 s.SoundId=id s.Volume=volume or 1 s.PlaybackSpeed=speed or 1
 s.RollOffMode=Enum.RollOffMode.Linear s.RollOffMinDistance=60 s.RollOffMaxDistance=900
 s.Parent=p p.Parent=workspace
 s:Play()
 Debris:AddItem(p,10)
end

local ui
local function gui()
 if ui and ui.Root.Parent then return ui end
 local root=Instance.new("ScreenGui")
 root.Name="TrueWarriorCinema" root.IgnoreGuiInset=true root.ResetOnSpawn=false root.DisplayOrder=60
 local function frame(color,z)
  local f=Instance.new("Frame") f.BorderSizePixel=0 f.BackgroundColor3=color f.ZIndex=z f.Parent=root return f
 end
 local top,bottom=frame(BLACK,3),frame(BLACK,3)
 top.Size=UDim2.fromScale(1,0) bottom.Size=UDim2.fromScale(1,0) bottom.AnchorPoint=Vector2.new(0,1) bottom.Position=UDim2.fromScale(0,1)
 local flash=frame(WHITE,4) flash.Size=UDim2.fromScale(1,1) flash.BackgroundTransparency=1
 local lines={}
 for i=1,30 do local l=frame(WHITE,2) l.AnchorPoint=Vector2.new(.5,.5) l.Visible=false lines[i]=l end
 local bars={}
 for i=1,2 do local b=frame(WHITE,2) b.AnchorPoint=Vector2.new(.5,.5) b.Visible=false bars[i]=b end
 local title=Instance.new("TextLabel")
 title.BackgroundTransparency=1 title.AnchorPoint=Vector2.new(.5,.5) title.Position=UDim2.fromScale(.5,.42) title.Size=UDim2.fromScale(.9,.16)
 title.Font=Enum.Font.Antique title.TextScaled=true title.TextColor3=GOLD title.TextStrokeColor3=BLACK title.TextStrokeTransparency=.1 title.TextTransparency=1
 title.ZIndex=5 title.Text="" title.Parent=root
 local scale=Instance.new("UIScale") scale.Parent=title
 root.Parent=player:WaitForChild("PlayerGui")
 ui={Root=root,Top=top,Bottom=bottom,Flash=flash,Lines=lines,Bars=bars,Title=title,Scale=scale}
 return ui
end
local function letterbox(on,time)
 local u=gui()
 local goal={Size=UDim2.fromScale(1,on and .115 or 0)}
 local info=TweenInfo.new(time or .3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
 Tween:Create(u.Top,info,goal):Play()
 Tween:Create(u.Bottom,info,goal):Play()
end
local function screenFlash(color,alpha,time)
 local u=gui()
 u.Flash.BackgroundColor3=color u.Flash.BackgroundTransparency=alpha
 Tween:Create(u.Flash,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
end
local titleToken=0
local function slamTitle(text,color,hold)
 local u=gui()
 titleToken+=1
 local token=titleToken
 u.Title.Text=text u.Title.TextColor3=color or GOLD u.Title.TextTransparency=0 u.Title.TextStrokeTransparency=.1
 u.Scale.Scale=1.7
 Tween:Create(u.Scale,TweenInfo.new(.14,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()
 task.delay(hold or 1,function()
  if titleToken~=token then return end
  Tween:Create(u.Title,TweenInfo.new(.3),{TextTransparency=1,TextStrokeTransparency=1}):Play()
 end)
end

local Cine={Token=0,Active=false}
local function stopCine()
 Cine.Token+=1
 if not Cine.Active then return end
 Cine.Active=false
 Run:UnbindFromRenderStep(CAM_STEP)
 local cam=workspace.CurrentCamera
 if cam then
  cam.CameraType=Enum.CameraType.Custom
  cam.FieldOfView=Fov.Base(cam)
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h then cam.CameraSubject=h end
 end
 letterbox(false,.3)
end
local function ease(k,style)
 if style=="in" then return k*k*k elseif style=="linear" then return k end
 return 1-(1-k)^3
end
local function runShots(char,dir,shots)
 local root=rootOf(char)
 local cam=workspace.CurrentCamera
 if not root or not cam or not Reset.ViewAllowed() or player:GetAttribute("DisableSkillCutscenes")==true then return end
 stopCine()
 local token=Cine.Token
 local forward=flat(dir or root.CFrame.LookVector)
 local base=CFrame.lookAt(root.Position,root.Position+forward)
 local total=0
 for _,s in ipairs(shots)do total+=s.D end
 Cine.Active=true
 cam.CameraType=Enum.CameraType.Scriptable
 letterbox(true,.22)
 local start=os.clock()
 Run:BindToRenderStep(CAM_STEP,Enum.RenderPriority.Camera.Value+1,function()
  if Cine.Token~=token then return end
  local t=os.clock()-start
  local shot,k=shots[#shots],1
  local at=0
  for _,s in ipairs(shots)do
   if t<at+s.D then shot,k=s,(t-at)/s.D break end
   at+=s.D
  end
  local e=ease(k,shot.Ease)
  local p=base*shot.P0:Lerp(shot.P1 or shot.P0,e)
  local l=base*shot.L0:Lerp(shot.L1 or shot.L0,e)
  local roll=(shot.Roll0 or 0)+((shot.Roll1 or shot.Roll0 or 0)-(shot.Roll0 or 0))*e
  cam.CFrame=CFrame.lookAt(p,l)*CFrame.Angles(0,0,math.rad(roll))
  cam.FieldOfView=shot.F0+((shot.F1 or shot.F0)-shot.F0)*e
 end)
 task.delay(total+3,function()if Cine.Token==token then stopCine()end end)
end

local impactToken=0
local function clearImpact(state)
 Run:UnbindFromRenderStep(IMPACT_STEP)
 if not state then return end
 state.Plate:Destroy()
 for _,h in ipairs(state.Lights)do h:Destroy()end
 for _,l in ipairs(ui.Lines)do l.Visible=false end
 for _,b in ipairs(ui.Bars)do b.Visible=false end
end
local activeImpact
local function impactFrames(char,other,frames,tilt)
 if REDUCE_FLASHING or not Reset.ViewAllowed() or player:GetAttribute("DisableSkillCutscenes")==true then return end
 local cam=workspace.CurrentCamera
 if not cam then return end
 local u=gui()
 Run:UnbindFromRenderStep(IMPACT_STEP)
 if activeImpact then clearImpact(activeImpact) end
 impactToken+=1
 local token=impactToken
 local plate=Instance.new("Part")
 plate.Name="TWImpactPlate" plate.Anchored=true plate.CanCollide=false plate.CanQuery=false plate.CanTouch=false plate.CastShadow=false
 plate.Material=NEON plate.Size=Vector3.new(160,160,.05) plate.Parent=cam
 local lights={}
 for _,model in ipairs({char,other})do
  if typeof(model)=="Instance" and model.Parent then
   local h=Instance.new("Highlight")
   h.Name="TWImpactInk" h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.FillTransparency=0 h.OutlineTransparency=0
   h.Adornee=model h.Parent=model
   lights[#lights+1]=h
  end
 end
 local state={Plate=plate,Lights=lights}
 activeImpact=state
 Run:BindToRenderStep(IMPACT_STEP,Enum.RenderPriority.Camera.Value+4,function()
  if plate.Parent then plate.CFrame=cam.CFrame*CFrame.new(0,0,-1.2) end
 end)
 local screen=cam.ViewportSize
 local focal=Vector2.new(screen.X*.5,screen.Y*.45)
 local root=rootOf(char)
 if root then
  local point,visible=cam:WorldToViewportPoint(root.Position)
  if visible then focal=Vector2.new(point.X,point.Y)end
 end
 local diag=screen.Magnitude
 for i,l in ipairs(u.Lines)do
  local angle=(i/#u.Lines)*math.pi*2+math.random()*.12
  local length=diag*(.2+math.random()*.4)
  local middle=diag*(.1+math.random()*.15)+length*.5
  l.Size=UDim2.fromOffset(length,math.max(2,screen.Y*(.003+math.random()*.01)))
  l.Position=UDim2.fromOffset(focal.X+math.cos(angle)*middle,focal.Y+math.sin(angle)*middle)
  l.Rotation=math.deg(angle)
  l.Visible=true
 end
 local angle=tilt or -18
 u.Bars[1].Size=UDim2.fromOffset(diag*1.4,screen.Y*.05)
 u.Bars[1].Position=UDim2.fromOffset(focal.X,focal.Y) u.Bars[1].Rotation=angle
 u.Bars[2].Size=UDim2.fromOffset(diag*1.4,screen.Y*.012)
 u.Bars[2].Position=UDim2.fromOffset(focal.X,focal.Y+screen.Y*.07) u.Bars[2].Rotation=angle
 for _,b in ipairs(u.Bars)do b.Visible=true end
 task.spawn(function()
  for _,f in ipairs(frames or {{BLACK,WHITE,.055},{WHITE,BLACK,.05},{GOLD,BLACK,.045}})do
   if impactToken~=token then return end
   plate.Color=f[1]
   for _,h in ipairs(lights)do h.FillColor=f[2] h.OutlineColor=f[1]end
   for _,l in ipairs(u.Lines)do l.BackgroundColor3=f[2]end
   for _,b in ipairs(u.Bars)do b.BackgroundColor3=f[2]end
   task.wait(f[3])
  end
  if impactToken==token then clearImpact(state) activeImpact=nil end
 end)
end

local casts=setmetatable({},{__mode="k"})
local function finishCast(char,fade)
 local c=casts[char]
 if not c then return end
 casts[char]=nil
 for _,fn in ipairs(c.Restore)do pcall(fn)end
 if fade then c.G:Fade(fade) else c.G:Destroy() end
end
local function newCast(E,char,name,life)
 finishCast(char)
 local c={G=E.Group(name),Restore={}}
 casts[char]=c
 task.delay(life,function()if casts[char]==c then finishCast(char,.2)end end)
 return c,c.G
end
local function resetAll()
 impactToken+=1
 Run:UnbindFromRenderStep(IMPACT_STEP)
 if activeImpact then clearImpact(activeImpact) activeImpact=nil end
 stopCine()
 for char in pairs(casts)do finishCast(char)end
end
if Run:IsClient()then Reset.Register(script,resetAll,resetAll) end

function T.Cancel(E,d)
 finishCast(d.Char)
 if isLocal(d.Char)then stopCine() end
end
function T.CastEnd(E,d)
 finishCast(d.Char,.25)
 if isLocal(d.Char)then stopCine() end
end

local function handCF(char,side)
 local arm=char:FindFirstChild((side or "Right").." Arm")
 return arm and arm.CFrame*CFrame.new(0,-1.05,0) or (rootOf(char) and rootOf(char).CFrame or CFrame.new())
end
local function groundY(E,pos,char)
 local hit=E.Ground(pos+UP*6,{char})
 return hit and hit.Y or pos.Y-3
end
local function newPart(g,size,cf,color,alpha)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Material=NEON p.Size=size p.CFrame=cf p.Color=color p.Transparency=alpha or 0
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=g.Folder
 return p
end
local function mesh(g,name,width,color,alpha)
 local t=Assets[name]
 local p=t:Clone()
 p.Size=t.Size*(width/t.Size.X)
 p.TextureID="" p.Material=NEON p.Color=color p.Transparency=alpha or 0
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Parent=g.Folder
 return p
end
local function crescentFrame(pos,dir,roll)
 local right=dir:Cross(UP)
 right=right.Magnitude>.01 and right.Unit or Vector3.xAxis
 local normal=right:Cross(dir).Unit
 return CFrame.fromMatrix(pos,right,dir,normal)*CFrame.Angles(0,math.rad(roll or 0),0)
end
local function ringAnchor(E,g,pos,axis)
 return E.Anchor(g,CFrame.lookAt(pos,pos+axis)*CFrame.Angles(-math.pi/2,0,0))
end
local function aura(E,g,char,color,scale,duration)
 local anchor=E.Anchor(g,rootOf(char).CFrame)
 local gy=groundY(E,rootOf(char).Position,char)
 local ground=E.Anchor(g,CFrame.new(rootOf(char).Position.X,gy+.4,rootOf(char).Position.Z))
 E.Stream(anchor,{tex="star.twinkle",shape=Enum.ParticleEmitterShape.Sphere,style=Enum.ParticleEmitterShapeStyle.Surface,inout=Enum.ParticleEmitterShapeInOut.Inward,
  size={{0,.5*scale},{1,0}},alpha={{0,.2},{.7,0},{1,1}},color={{0,WHITE},{1,color}},life={.3,.55},speed={10*scale,22*scale}},70)
 E.Stream(ground,{tex="fire.sparks",size={{0,.5*scale},{1,0}},color={{0,SHINE},{1,color}},life={.5,1},speed={8,22},spread=25,dir=Enum.NormalId.Top,accel=UP*10},40)
 E.Sprite(ground,{tex="sigil.ring",orient="flat",size={{0,2*scale},{.4,14*scale},{1,16*scale}},alpha={{0,1},{.2,.55},{.85,.6},{1,1}},color=color,spin={80,80}},duration)
 E.Sprite(ground,{tex="ring.crisp",orient="flat",size={{0,18*scale},{1,3}},alpha={{0,.95},{.8,.5},{1,1}},color=WHITE},duration)
 E.Light(g,anchor,color,18*scale,2.5)
 E.Step(g,function()
  local root=rootOf(char)
  if not root then return false end
  anchor.CFrame=handCF(char)
 end)
end
local function scar(E,origin,dir,range,speed,width,life,color)
 local g=E.Group("TW_Scar")
 local y=groundY(E,origin,nil)+.12
 local flatDir=flat(dir)
 local start=Vector3.new(origin.X,y,origin.Z)
 local right=flatDir:Cross(UP)
 local function frame(length)
  return CFrame.fromMatrix(start+flatDir*length*.5,right,UP,-flatDir)
 end
 local core=newPart(g,Vector3.new(width,.08,.1),frame(.05),WHITE,0)
 local glow=newPart(g,Vector3.new(width*3.2,.05,.1),frame(.05),color,.45)
 local embers=E.Stream(core,{tex="fire.sparks",size={{0,.7},{1,0}},color={{0,SHINE},{.5,color},{1,EMBER}},life={.5,1.1},speed={6,20},spread=30,dir=Enum.NormalId.Top,accel=UP*8},0)
 local air=E.Anchor(g,CFrame.new(origin))
 local airEnd=E.Anchor(g,CFrame.new(origin))
 local a0,a1=E.Attach(air),E.Attach(airEnd)
 local streak=E.Beam(g,a0,a1,{tex="beam.core",mode=Enum.TextureMode.Stretch,width=width*2.4,color={{0,WHITE},{1,color}},brightness=4,segments=2})
 E.Step(g,function(dt,t)
  local length=math.min(range,speed*t)
  core.Size=Vector3.new(width,.08,length) core.CFrame=frame(length)
  glow.Size=Vector3.new(width*3.2,.05,length) glow.CFrame=frame(length)
  airEnd.CFrame=CFrame.new(origin+dir*length)
  if length>=range then return false end
 end)
 embers.Rate=math.min(260,range*1.5)*E.Quality
 local burn=range/speed
 E.After(g,burn+.05,function()E.Tween(streak,.3,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)end)
 E.After(g,burn+life*.55,function()
  embers.Enabled=false
  E.Tween(core,life*.45,{Transparency=1})
  E.Tween(glow,life*.45,{Transparency=1})
 end)
 E.After(g,burn+life+.4,function()g:Destroy()end)
end

function T.VowCharge(E,d)
 local root=rootOf(d.Char)
 if not root then return end
 local c,g=newCast(E,d.Char,"TW_VowCharge",d.Duration+1.2)
 local color=d.Boosted and WHITE or GOLD
 aura(E,g,d.Char,color,d.Boosted and 1.3 or 1,d.Duration)
 local blade=E.Anchor(g,handCF(d.Char))
 E.Sprite(blade,{tex="star.glare",size={{0,1},{.85,7},{1,3}},alpha={{0,.4},{.85,.15},{1,1}},color=color},d.Duration)
 E.Step(g,function()blade.CFrame=handCF(d.Char)end)
 E.After(g,d.Duration*.72,function()
  if root.Parent then
   E.Sprite(blade,{tex="flare.burst2",size={{0,3},{1,11}},alpha={{0,.35},{1,1}},color=WHITE},.32)
  end
 end)
 if isLocal(d.Char)then
  local D=d.Duration
  runShots(d.Char,d.Dir,{
   {D=D*.5,P0=Vector3.new(3,-.2,-5.2),P1=Vector3.new(2.2,.6,-4),L0=Vector3.new(.6,-.2,0),L1=Vector3.new(.5,.5,0),F0=54,F1=38,Roll0=-7,Roll1=-3},
   {D=D*.5,P0=Vector3.new(2.6,1.4,7.5),P1=Vector3.new(1.7,1,5),L0=Vector3.new(0,1.2,-30),F0=64,F1=46,Roll0=3,Roll1=0},
   {D=.5,P0=Vector3.new(4,2.4,9),P1=Vector3.new(4,4,19),L0=Vector3.new(0,1,-60),L1=Vector3.new(0,1,-120),F0=78,F1=98},
  })
 end
end

function T.VowRelease(E,d)
 local g=E.Group("TW_VowSlash")
 local time=d.Range/d.Speed
 local width=d.Boosted and 74 or 58
 local core=mesh(g,"ArcSlash",width,WHITE,.02)
 local glow=mesh(g,"ArcSlash",width*1.18,GOLD,.35)
 local outer=mesh(g,"ArcSlash",width*1.4,FLAME,.68)
 local streak=mesh(g,"StreakSlash",width*1.4,GOLD,.5)
 local start=os.clock()
 local carrier=E.Anchor(g,CFrame.new(d.Origin))
 E.Stream(carrier,{tex="wind.dash",orient="velocity",size={{0,8},{1,24}},alpha={{0,.45},{1,1}},color=SHINE,life={.12,.22},speed={300,520},spread=6,dir=Enum.NormalId.Back},60)
 E.Step(g,function()
  local t=os.clock()-start
  local k=math.clamp(t/time,0,1)
  local pos=d.Origin+d.Dir*(d.Speed*math.min(t,time))
  local f=crescentFrame(pos,d.Dir,14)
  core.CFrame=f glow.CFrame=f*CFrame.new(0,-width*.03,.2) outer.CFrame=f*CFrame.new(0,-width*.07,.4)
  streak.CFrame=f*CFrame.new(0,0,.5)*CFrame.Angles(math.pi/2,0,0)
  carrier.CFrame=CFrame.lookAt(pos,pos+d.Dir)
  if k>=1 then
   for _,p in ipairs({core,glow,outer,streak})do E.Tween(p,.14,{Transparency=1})end
   E.After(g,.25,function()g:Destroy()end)
   return false
  end
 end)
 local axis=d.Dir
 local rings=E.Group("TW_VowRings")
 for i=0,3 do
  local a=ringAnchor(E,rings,d.Origin+axis*(i*7),axis)
  E.Sprite(a,{tex=i==0 and "ring.thick" or "ring.crisp",orient="flat",size={{0,4+i*4},{1,44+i*10}},alpha={{0,.05},{.5,.3},{1,1}},color=i%2==0 and WHITE or GOLD},.32+i*.05)
 end
 local burst=E.Anchor(rings,CFrame.lookAt(d.Origin,d.Origin+axis)*CFrame.Angles(-math.pi/2,0,0))
 E.Sprite(burst,{tex="flare.big",size={{0,10},{.15,60},{1,30}},alpha={{0,0},{.5,.25},{1,1}},color=WHITE},.32)
 E.Emit(burst,{tex="dot",orient="velocity",squash={{0,4},{1,0}},size={{0,1.2},{1,0}},color={{0,WHITE},{1,GOLD}},life={.2,.45},speed={180,420},spread=26,dir=Enum.NormalId.Top},70)
 E.Light(rings,burst,GOLD,70,10,.35)
 E.After(rings,1,function()rings:Destroy()end)
 scar(E,d.Origin,d.Dir,d.Range,d.Speed,1.4,d.LineLife or 4,GOLD)
 play(SFX.Sonic,d.Origin,1.1,1.05)
 if isLocal(d.Char)then
  impactFrames(d.Char,nil,nil,-14)
  task.delay(.16,function()screenFlash(SHINE,.45,.28)end)
 end
end

function T.VowHit(E,d)
 local g=E.Group("TW_VowHit")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 E.Sprite(a,{tex="burst.spiky2",size={{0,6},{1,d.Boosted and 58 or 42}},alpha={{0,0},{.5,.15},{1,1}},color=WHITE,rot={0,360}},.4)
 E.Sprite(a,{tex="flare.burst2",size={{0,8},{.25,44},{1,50}},alpha={{0,0},{.4,.2},{1,1}},color=GOLD},.45)
 E.Light(g,a,GOLD,60,10,.4)
 E.After(g,1,function()g:Destroy()end)
end

function T.CounterSlash(E,d)
 local g=E.Group("TW_Counter")
 local core=mesh(g,"ArcSlash",24,WHITE,.02)
 local glow=mesh(g,"ArcSlash",29,GOLD,.38)
 local time=d.Range/d.Speed
 local start=os.clock()
 E.Step(g,function()
  local t=os.clock()-start
  local pos=d.Origin+d.Dir*(d.Speed*math.min(t,time))
  local f=crescentFrame(pos,d.Dir,-24)
  core.CFrame=f glow.CFrame=f*CFrame.new(0,-1,.2)
  if t>=time then
   E.Tween(core,.1,{Transparency=1}) E.Tween(glow,.1,{Transparency=1})
   E.After(g,.2,function()g:Destroy()end)
   return false
  end
 end)
 local a=E.Anchor(g,CFrame.new(d.Origin))
 E.Sprite(a,{tex="star.anime",size={{0,3},{.2,22},{1,0}},alpha={{0,0},{.7,0},{1,1}},color=WHITE,rot={45,45}},.24)
 if isLocal(d.Char)then screenFlash(SHINE,.72,.16) end
end

local shields={}
local function buildShield(g,char)
 local gear=char:FindFirstChild("ClassGear")
 local rim=gear and gear:FindFirstChild("ShieldRim",true)
 local parts={}
 if not rim then return parts end
 for _,p in ipairs(gear:GetDescendants())do
  if p:IsA("BasePart") and p.Name:find("^Shield") then
   local c=p:Clone()
   c:ClearAllChildren()
   c.Anchored=true c.CanCollide=false c.CanQuery=false c.CanTouch=false
   c.Transparency=p:GetAttribute("TWBaseAlpha") or (p.Transparency<1 and p.Transparency or 0)
   c.Parent=g.Folder
   parts[#parts+1]={Part=c,Rel=rim.CFrame:ToObjectSpace(p.CFrame)}
  end
 end
 return parts
end
function T.ShieldThrow(E,d)
 local g=E.Group("TW_Shield")
 local parts=buildShield(g,d.Char)
 local state={G=g,Pos=d.Origin,Mode="Out",Char=d.Char}
 shields[d.Id]=state
 local anchor=E.Anchor(g,CFrame.new(d.Origin))
 local a0,a1=E.Attach(anchor,CFrame.new(-1.6,0,0)),E.Attach(anchor,CFrame.new(1.6,0,0))
 local trail=Instance.new("Trail")
 trail.Attachment0,trail.Attachment1=a0,a1
 trail.Lifetime=.22 trail.LightEmission=1 trail.FaceCamera=true trail.MinLength=.05
 trail.Color=ColorSequence.new(WHITE,GOLD)
 trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(1,1)})
 trail.Parent=anchor
 E.Stream(anchor,{tex="star.twinkle",size={{0,.7},{1,0}},color={{0,WHITE},{1,GOLD}},life={.2,.4},speed={2,7},spread=180},36)
 E.Light(g,anchor,GOLD,18,4)
 local travelled,spin=0,0
 E.Step(g,function(dt)
  spin+=dt*26
  if state.Mode=="Out" then
   travelled=math.min(d.Range,travelled+d.Speed*dt)
   state.Pos=d.Origin+d.Dir*travelled
  elseif state.Mode=="Back" then
   local arm=state.Char:FindFirstChild("Left Arm")
   local to=(arm and arm.Position or state.Pos)-state.Pos
   if to.Magnitude<=3 then state.Mode="Done"
   else state.Pos+=to.Unit*math.min(d.ReturnSpeed*dt,to.Magnitude)end
  end
  local frame=CFrame.new(state.Pos)*CFrame.Angles(0,spin,0)*CFrame.Angles(0,0,math.pi/2)
  anchor.CFrame=CFrame.new(state.Pos)*CFrame.Angles(0,spin,0)
  for _,p in ipairs(parts)do p.Part.CFrame=frame*p.Rel end
 end)
 E.After(g,8,function()shields[d.Id]=nil g:Destroy()end)
end
function T.ShieldHit(E,d)
 local s=shields[d.Id]
 if s then s.Pos=d.Pos s.Mode="Back" end
 local g=E.Group("TW_ShieldHit")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 E.Sprite(a,{tex="burst.spiky",size={{0,4},{1,28}},alpha={{0,0},{.5,.15},{1,1}},color=WHITE,rot={0,360}},.3)
 E.After(g,.6,function()g:Destroy()end)
end
function T.ShieldTurn(E,d)
 local s=shields[d.Id]
 if s then s.Pos=d.Pos s.Mode="Back" end
end
function T.ShieldCaught(E,d)
 local s=shields[d.Id]
 if s then shields[d.Id]=nil s.G:Fade(.08) end
end

function T.LastStandCharge(E,d)
 local root=rootOf(d.Char)
 if not root then return end
 local c,g=newCast(E,d.Char,"TW_LastCharge",d.Duration+2)
 aura(E,g,d.Char,GOLD,1.5,d.Duration)
 local pillarBase=E.Anchor(g,CFrame.new(root.Position-UP*3))
 local pillarTop=E.Anchor(g,CFrame.new(root.Position+UP*70))
 local a0,a1=E.Attach(pillarBase),E.Attach(pillarTop)
 local beam=E.Beam(g,a0,a1,{tex="beam.curtain",width=0,length=30,scroll=40,color={{0,GOLD},{1,WHITE}},brightness=3,alpha={{0,.1},{1,1}},segments=2})
 E.Tween(beam,d.Duration,{Width0=20,Width1=6})
 if isLocal(d.Char)then
  local D=d.Duration
  runShots(d.Char,d.Dir,{
   {D=D*.36,P0=Vector3.new(3.4,-.6,-3.6),P1=Vector3.new(1.8,.4,-4.6),L0=Vector3.new(.8,-.8,-.6),L1=Vector3.new(.7,.4,0),F0=50,F1=36,Roll0=10,Roll1=4},
   {D=D*.34,P0=Vector3.new(-2.6,-2.5,-7.4),P1=Vector3.new(-1.1,-2,-6),L0=Vector3.new(0,1.2,0),F0=56,F1=42,Roll0=-5,Roll1=-1},
   {D=D*.30,P0=Vector3.new(6,7,9),P1=Vector3.new(10,13,15),L0=Vector3.new(0,0,0),F0=68,F1=80,Ease="in"},
   {D=.62,P0=Vector3.new(0,40,20),P1=Vector3.new(0,52,27),L0=Vector3.new(0,0,-2),F0=74,F1=86},
  })
 end
end

function T.LastStandSlash(E,d)
 local g=E.Group("TW_LastSlash")
 local width=d.Radius*2.05
 local core=mesh(g,"ArcSlash",width,WHITE,.02)
 local glow=mesh(g,"ArcSlash",width*1.12,GOLD,.34)
 local turns=1.5
 local time=.3
 local start=os.clock()
 local y=d.Origin.Y+.2
 E.Step(g,function()
  local t=os.clock()-start
  local k=math.clamp(t/time,0,1)
  local yaw=-math.pi*2*turns*(1-(1-k)^2)
  local look=Vector3.new(math.sin(yaw),0,-math.cos(yaw))
  local pos=Vector3.new(d.Origin.X,y,d.Origin.Z)+look*(d.Radius*.35)
  local f=crescentFrame(pos,look,0)
  core.CFrame=f glow.CFrame=f*CFrame.new(0,-1.4,.2)
  if k>=1 then
   E.Tween(core,.18,{Transparency=1}) E.Tween(glow,.18,{Transparency=1})
   E.After(g,.3,function()g:Destroy()end)
   return false
  end
 end)
 local gy=groundY(E,d.Origin,d.Char)
 local ground=E.Group("TW_LastRing")
 local a=E.Anchor(ground,CFrame.new(d.Origin.X,gy+.5,d.Origin.Z))
 local diameter=d.Radius*2
 E.Sprite(a,{tex="ring.crisp",orient="flat",size={{0,diameter*.2},{.25,diameter*1.25},{1,diameter*1.3}},alpha={{0,0},{.5,.15},{1,1}},color=WHITE},.48)
 E.Sprite(a,{tex="ring.thick",orient="flat",size={{0,diameter*.15},{1,diameter*1.34}},alpha={{0,.1},{.7,.35},{1,1}},color=GOLD},.6)
 E.Sprite(a,{tex="fb.ringburst",orient="flat",size={{0,diameter*.3},{1,diameter*1.3}},alpha={{0,0},{1,.8}},color=SHINE},.5)
 E.Emit(a,{tex="fb.smoke",size={{0,8},{1,22}},alpha={{0,.45},{1,1}},color=Color3.fromRGB(235,214,170),life={.6,1.1},speed={70,130},spread=88,dir=Enum.NormalId.Top,drag=3},30)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,3},{1,0}},size={{0,1.4},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={150,300},spread=86,dir=Enum.NormalId.Top},80)
 E.Light(ground,a,GOLD,90,12,.5)
 E.After(ground,1.4,function()ground:Destroy()end)
 if isLocal(d.Char)then
  impactFrames(d.Char,nil,{{WHITE,BLACK,.055},{BLACK,WHITE,.055},{WHITE,BLACK,.04},{GOLD,BLACK,.045}},-8)
 end
end

function T.LastStandResult(E,d)
 local root=rootOf(d.Char)
 if not root then return end
 if d.Hit then
  local g=E.Group("TW_LastStand")
  local a=E.Anchor(g,root.CFrame)
  E.Sprite(a,{tex="flare.big",size={{0,10},{.2,70},{1,40}},alpha={{0,0},{.5,.2},{1,1}},color=GOLD},.55)
  local crown=E.Sprite(a,{tex="sigil.mandala",size={{0,4},{.3,24},{1,26}},alpha={{0,0},{.7,.25},{1,1}},color=GOLD,spin={90,90}},.9)
  E.After(g,1.2,function()g:Destroy()end)
  if isLocal(d.Char)then
   if typeof(d.Target)=="Instance" then
    task.delay(.2,function()impactFrames(d.Char,d.Target,{{BLACK,GOLD,.05},{WHITE,BLACK,.05}},22)end)
   end
   slamTitle(({"LAST STAND","LAST STAND II","LAST STAND III"})[d.Stage or 1],GOLD,1.1)
  end
 elseif isLocal(d.Char)then
  slamTitle("MISSED",Color3.fromRGB(205,205,215),.6)
 end
end

local GROWN={Blade=true,BladeFuller=true,BladeEdge=true,BladeTipA=true,BladeTipB=true}
local function setReal(gear,alpha,c)
 for _,p in ipairs(gear:GetDescendants())do
  if p:IsA("BasePart") and p.Name:find("^Blade") then p.LocalTransparencyModifier=alpha end
 end
end
local function buildGiant(g,c,char)
 local gear=char:FindFirstChild("ClassGear")
 local arm=char:FindFirstChild("Right Arm")
 if not gear or not arm then return nil end
 local grip=arm.CFrame*CFrame.new(0,-1.05,0)
 local list,zGuard={},-1.0
 for _,p in ipairs(gear:GetDescendants())do
  if p:IsA("BasePart") and p.Name:find("^Blade") then
   local copy=p:Clone()
   copy:ClearAllChildren()
   copy.Anchored=true copy.CanCollide=false copy.CanQuery=false copy.CanTouch=false copy.CastShadow=false
   copy.LocalTransparencyModifier=0
   copy.Parent=g.Folder
   list[#list+1]={Part=copy,Rel=grip:ToObjectSpace(p.CFrame),Size=p.Size,Grown=GROWN[p.Name]==true,Name=p.Name}
  end
 end
 setReal(gear,1)
 c.Restore[#c.Restore+1]=function()setReal(gear,0)end
 return {List=list,Guard=zGuard}
end
local function placeGiant(giant,pivot,lengthScale,widthScale)
 for _,e in ipairs(giant.List)do
  if e.Grown then
   local rel=e.Rel
   local z=giant.Guard+(rel.Z-giant.Guard)*lengthScale
   e.Part.Size=Vector3.new(e.Size.X*widthScale,e.Size.Y*widthScale,e.Size.Z*lengthScale)
   e.Part.CFrame=pivot*CFrame.new(rel.X*widthScale,rel.Y*widthScale,z)*rel.Rotation
  else
   e.Part.CFrame=pivot*e.Rel
  end
 end
end
local function backOut(k)
 local c=1.4
 return 1+(c+1)*(k-1)^3+c*(k-1)^2
end
function T.SupremeCharge(E,d)
 local root=rootOf(d.Char)
 if not root then return end
 local c,g=newCast(E,d.Char,"TW_Supreme",d.Duration+d.Swing+3)
 local forward=flat(d.Dir)
 local right=forward:Cross(UP).Unit
 local giant=buildGiant(g,c,d.Char)
 aura(E,g,d.Char,FLAME,1.7,d.Duration)
 local bladeLen=6.2
 local targetScale=d.Length/bladeLen
 local grow=d.Duration*.82
 local growStart=.22
 c.Angle=0
 c.SwingAt=nil
 c.Swing=d.Swing
 local start=os.clock()
 local mainBlade
 if giant then
  for _,e in ipairs(giant.List)do
   if e.Name=="Blade" then mainBlade=e.Part e.Part.Material=NEON end
   if e.Grown and e.Name~="Blade" then e.Part.Material=NEON e.Part.Color=e.Name=="BladeFuller" and FLAME or WHITE end
  end
  if mainBlade then
   E.Tween(mainBlade,grow,{Color=Color3.fromRGB(255,176,72)})
   local box=Enum.ParticleEmitterShape.Box
   E.Stream(mainBlade,{tex="fire",shape=box,light=.35,size={{0,18},{.35,38},{1,0}},alpha={{0,.1},{.6,.15},{1,1}},color={{0,GOLD},{.3,FLAME},{.7,EMBER},{1,Color3.fromRGB(120,24,8)}},life={.4,.9},speed={25,70},spread=45,rot={0,360},spin={-120,120}},260)
   E.Stream(mainBlade,{tex="fire",shape=box,size={{0,8},{1,0}},alpha={{0,.1},{1,1}},color={{0,SHINE},{1,FLAME}},life={.2,.4},speed={6,18},spread=180},120)
   E.Stream(mainBlade,{tex="fire.sparks",shape=box,size={{0,2.2},{1,0}},color={{0,SHINE},{1,EMBER}},life={.6,1.3},speed={30,80},spread=70,accel=UP*18},160)
   c.Flame=true
  end
 end
 local function hands()
  local a,b=d.Char:FindFirstChild("Right Arm"),d.Char:FindFirstChild("Left Arm")
  local p=a and (a.CFrame*CFrame.new(0,-1.05,0)).Position or root.Position
  local q=b and (b.CFrame*CFrame.new(0,-1.05,0)).Position or p
  return (p+q)*.5
 end
 local burstAnchor=E.Anchor(g,CFrame.new(root.Position))
 local swingEase=function(k)return k*k*k*k end
 E.Step(g,function()
  if not root.Parent then return false end
  local t=os.clock()-start
  local g0=math.clamp((t-growStart)/grow,0,1)
  local s=1+(targetScale-1)*backOut(g0)
  local w=1+11*backOut(g0)
  local theta=0
  if c.SwingAt then
   local k=math.clamp((os.clock()-c.SwingAt)/c.Swing,0,1)
   theta=math.rad(101)*swingEase(k)
  end
  local dir3=UP*math.cos(theta)+forward*math.sin(theta)
  local neg=-dir3
  local pivot=CFrame.fromMatrix(hands(),-right,neg:Cross(-right),neg)
  if giant then placeGiant(giant,pivot,s,w) end
  burstAnchor.CFrame=CFrame.new(hands())
 end)
 for _,at in ipairs({.25,.85,1.45})do
  E.After(g,at,function()
   if not root.Parent then return end
   E.Sprite(burstAnchor,{tex="burst.spiky2",size={{0,8},{1,70}},alpha={{0,0},{.5,.2},{1,1}},color=FLAME,rot={0,360}},.4)
   E.Sprite(burstAnchor,{tex="flare.big",size={{0,12},{.2,60},{1,30}},alpha={{0,.1},{1,1}},color=GOLD},.35)
   E.Light(g,burstAnchor,FLAME,120,10,.5)
  end)
 end
 if isLocal(d.Char)then
  local D=d.Duration
  runShots(d.Char,d.Dir,{
   {D=D*.36,P0=Vector3.new(5,-2.4,13),P1=Vector3.new(6,-2,18),L0=Vector3.new(0,16,-4),L1=Vector3.new(0,84,-6),F0=72,F1=84,Roll0=-6,Roll1=0},
   {D=D*.64,P0=Vector3.new(74,22,-22),P1=Vector3.new(104,36,-34),L0=Vector3.new(0,68,-6),L1=Vector3.new(0,108,-8),F0=62,F1=68},
   {D=d.Swing,P0=Vector3.new(40,32,32),P1=Vector3.new(52,36,38),L0=Vector3.new(0,70,-30),L1=Vector3.new(0,6,-100),F0=78,F1=92,Ease="in"},
   {D=1.2,P0=Vector3.new(66,58,-16),P1=Vector3.new(92,78,-30),L0=Vector3.new(0,0,-90),L1=Vector3.new(0,10,-110),F0=82,F1=90},
  })
  task.delay(.25,function()slamTitle("SUPREME KING SLASH",FLAME,D*.72)end)
 end
end
function T.SupremeSwing(E,d)
 local c=casts[d.Char]
 if c then c.SwingAt=os.clock() c.Swing=d.Duration end
end
function T.SupremeImpact(E,d)
 local g=E.Group("TW_SupremeImpact")
 local dir=flat(d.Dir)
 local y=groundY(E,d.Origin,d.Char)+.6
 local steps=8
 for i=1,steps do
  E.After(g,(i-1)*.035,function()
   local p=d.Origin+dir*(d.Length*i/steps)
   local a=E.Anchor(g,CFrame.new(p.X,y,p.Z))
   local big=i==steps
   local r=big and d.Blast*.55 or d.Radius*1.4
   E.Sprite(a,{tex="burst.spiky2",size={{0,r},{1,r*3.6}},alpha={{0,0},{.5,.15},{1,1}},color=SHINE,rot={0,360}},.5)
   E.Sprite(a,{tex="flare.big",size={{0,r},{.2,r*4},{1,r*2}},alpha={{0,0},{.5,.25},{1,1}},color=FLAME},.7)
   E.Sprite(a,{tex="ring.thick",orient="flat",size={{0,r*.5},{1,r*4.2}},alpha={{0,.05},{.7,.4},{1,1}},color=GOLD},.7)
   E.Emit(a,{tex="fire",size={{0,16},{.4,38},{1,0}},alpha={{0,.1},{.7,.3},{1,1}},color={{0,SHINE},{.3,GOLD},{.65,FLAME},{1,EMBER}},life={.5,1.1},speed={45,120},spread=75,dir=Enum.NormalId.Top,accel=UP*25,drag=1.5,rot={0,360}},30)
   E.Emit(a,{tex="fb.smoke2",size={{0,18},{1,46}},alpha={{0,.35},{1,1}},color=Color3.fromRGB(60,44,34),life={1,2},speed={25,70},spread=70,dir=Enum.NormalId.Top,drag=1.4,rot={0,360}},12)
   E.Emit(a,{tex="fire.sparks",size={{0,2.6},{1,0}},color={{0,SHINE},{1,EMBER}},life={.8,1.8},speed={70,190},spread=75,dir=Enum.NormalId.Top,accel=UP*-40,drag=.6},40)
   if big then E.Light(g,a,FLAME,240,14,1.4) end
  end)
 end
 local tip=d.Origin+dir*d.Length
 local dome=newPart(g,Vector3.one*10,CFrame.new(tip.X,y,tip.Z),SHINE,0)
 dome.Shape=Enum.PartType.Ball
 local shell=newPart(g,Vector3.one*14,CFrame.new(tip.X,y,tip.Z),FLAME,.35)
 shell.Shape=Enum.PartType.Ball
 local size=d.Blast*2
 E.Tween(dome,.45,{Size=Vector3.one*size,Transparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
 E.Tween(shell,.8,{Size=Vector3.one*size*1.25,Transparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
 scar(E,d.Origin,dir,d.Length,d.Length/.28,d.Radius*.35,5,FLAME)
 play(SFX.Explosion,tip,1.6,1)
 play(SFX.Sonic,d.Origin+dir*40,1.1,.8)
 E.After(g,4,function()g:Destroy()end)
 local c=casts[d.Char]
 if c and c.Flame then
  for _,x in ipairs(c.G.Folder:GetDescendants())do
   if x:IsA("ParticleEmitter") and x.Parent:IsA("BasePart") and x.Parent.Name=="Blade" then x.Enabled=false end
  end
 end
 if isLocal(d.Char)then
  impactFrames(d.Char,nil,{{WHITE,BLACK,.06},{BLACK,FLAME,.06},{WHITE,BLACK,.05},{BLACK,WHITE,.05},{FLAME,BLACK,.05}},-32)
  task.delay(.28,function()screenFlash(Color3.fromRGB(255,190,110),.2,.8)end)
 end
end

function T.TruthCharge(E,d)
 local root=rootOf(d.Char)
 if not root then return end
 local c,g=newCast(E,d.Char,"TW_Truth",d.Duration+d.Beam+1.5)
 aura(E,g,d.Char,GOLD,1.2,d.Duration)
 local hand=E.Anchor(g,handCF(d.Char,"Left"))
 E.Sprite(hand,{tex="star.glare",size={{0,1},{.85,14},{1,7}},alpha={{0,.4},{.85,.1},{1,1}},color=WHITE},d.Duration)
 E.Stream(hand,{tex="star.twinkle",shape=Enum.ParticleEmitterShape.Sphere,style=Enum.ParticleEmitterShapeStyle.Surface,inout=Enum.ParticleEmitterShapeInOut.Inward,size={{0,.8},{1,0}},alpha={{0,.1},{1,1}},color={{0,WHITE},{1,GOLD}},life={.25,.45},speed={14,30}},90)
 E.Light(g,hand,GOLD,26,4)
 E.Step(g,function()hand.CFrame=handCF(d.Char,"Left")end)
 if isLocal(d.Char)then
  local D=d.Duration
  runShots(d.Char,d.Dir,{
   {D=D,P0=Vector3.new(-6,.2,-9),P1=Vector3.new(-3.6,.9,-7),L0=Vector3.new(-1,.8,-2),L1=Vector3.new(-1,1,-3),F0=52,F1=36,Roll0=6,Roll1=2},
   {D=d.Beam*.55,P0=Vector3.new(6,4,11),P1=Vector3.new(8,5,15),L0=Vector3.new(0,2,-60),L1=Vector3.new(0,2,-120),F0=70,F1=94},
   {D=d.Beam*.45+.4,P0=Vector3.new(34,12,-40),P1=Vector3.new(46,18,-72),L0=Vector3.new(0,2,-60),L1=Vector3.new(0,2,-92),F0=76,F1=86},
  })
  task.delay(D*.3,function()slamTitle("THE TRUTH",GOLD,D*.6+.5)end)
 end
end
function T.TruthFire(E,d)
 local g=E.Group("TW_TruthBeam")
 local dir=d.Dir
 local center=d.Origin+dir*d.Range*.5
 local frame=CFrame.lookAt(center,center+dir)*CFrame.Angles(0,math.pi/2,0)
 local layers={}
 for _,spec in ipairs({{.5,WHITE,0},{1,SHINE,.2},{1.5,GOLD,.45},{2.2,FLAME,.72}})do
  local p=newPart(g,Vector3.new(d.Range,.1,.1),frame,spec[2],spec[3])
  p.Shape=Enum.PartType.Cylinder
  layers[#layers+1]={Part=p,Scale=spec[1]*d.Radius*2,Alpha=spec[3]}
 end
 local muzzle=E.Anchor(g,CFrame.lookAt(d.Origin,d.Origin+dir)*CFrame.Angles(-math.pi/2,0,0))
 E.Sprite(muzzle,{tex="flare.big",size={{0,12},{.1,d.Radius*6},{1,d.Radius*3}},alpha={{0,0},{.8,.2},{1,1}},color=WHITE},d.Duration)
 E.Stream(muzzle,{tex="dot",orient="velocity",squash={{0,4},{1,0}},size={{0,1.4},{1,0}},color={{0,WHITE},{1,GOLD}},life={.25,.5},speed={160,380},spread=22,dir=Enum.NormalId.Top},160)
 E.Light(g,muzzle,GOLD,120,10)
 for i=0,5 do
  E.After(g,i*d.Duration/6,function()
   local a=ringAnchor(E,g,d.Origin+dir*(14+i*24),dir)
   E.Sprite(a,{tex="ring.thick",orient="flat",size={{0,d.Radius*2},{1,d.Radius*7}},alpha={{0,.15},{.6,.45},{1,1}},color=i%2==0 and WHITE or GOLD},.4)
  end)
 end
 local start=os.clock()
 E.Step(g,function()
  local t=os.clock()-start
  local open=math.clamp(t/.1,0,1)
  local close=math.clamp((d.Duration-t)/.25,0,1)
  local pulse=1+math.sin(t*38)*.06
  for _,l in ipairs(layers)do
   local w=math.max(.05,l.Scale*open*close*pulse)
   l.Part.Size=Vector3.new(d.Range,w,w)
   l.Part.CFrame=frame
  end
  if t>=d.Duration then return false end
 end)
 scar(E,d.Origin,dir,d.Range,d.Range/.14,d.Radius*.55,3,GOLD)
 play(SFX.Sonic,d.Origin,1.2,.75)
 E.After(g,d.Duration+.4,function()g:Destroy()end)
 if isLocal(d.Char)then
  impactFrames(d.Char,nil,{{WHITE,BLACK,.055},{BLACK,GOLD,.055},{WHITE,BLACK,.045}},-10)
  task.delay(.16,function()screenFlash(SHINE,.5,.35)end)
 end
end

function T.HolyStance(E,d)
 local root=rootOf(d.Char)
 if not root then return end
 local c,g=newCast(E,d.Char,"TW_HolyStance",d.Duration+.2)
 local a=E.Anchor(g,root.CFrame)
 E.Sprite(a,{tex="sigil.mandala",size={{0,4},{.15,17},{1,20}},alpha={{0,.4},{.2,.3},{.85,.45},{1,1}},color=SHINE,spin={100,100}},d.Duration)
 E.Stream(a,{tex="star.twinkle",shape=Enum.ParticleEmitterShape.Sphere,style=Enum.ParticleEmitterShapeStyle.Surface,size={{0,.7},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={2,7}},50)
 E.Light(g,a,SHINE,22,3)
 E.Step(g,function()
  if not root.Parent then return false end
  a.CFrame=root.CFrame
 end)
end
function T.HolyCounter(E,d)
 finishCast(d.Char,.08)
 local g=E.Group("TW_HolyCounter")
 local width=120
 local core=mesh(g,"ArcSlash",width,WHITE,.02)
 local glow=mesh(g,"ArcSlash",width*1.14,GOLD,.32)
 local outer=mesh(g,"ArcSlash",width*1.3,SHINE,.66)
 local speed=1400
 local time=math.max(.06,d.Length/speed)
 local start=os.clock()
 E.Step(g,function()
  local t=os.clock()-start
  local pos=d.Origin+d.Dir*(speed*math.min(t,time))
  local f=crescentFrame(pos,d.Dir,0)
  core.CFrame=f glow.CFrame=f*CFrame.new(0,-width*.03,.2) outer.CFrame=f*CFrame.new(0,-width*.06,.4)
  if t>=time then
   for _,p in ipairs({core,glow,outer})do E.Tween(p,.14,{Transparency=1})end
   E.After(g,.3,function()g:Destroy()end)
   return false
  end
 end)
 local burst=ringAnchor(E,g,d.Origin,d.Dir)
 E.Sprite(burst,{tex="ring.crisp",orient="flat",size={{0,6},{1,64}},alpha={{0,0},{.5,.25},{1,1}},color=WHITE},.32)
 E.Sprite(burst,{tex="flare.big",size={{0,10},{.15,58},{1,28}},alpha={{0,0},{.5,.25},{1,1}},color=SHINE},.3)
 if isLocal(d.Char)then
  impactFrames(d.Char,d.Target,{{WHITE,BLACK,.06},{BLACK,WHITE,.05},{GOLD,BLACK,.05}},0)
  task.delay(.17,function()screenFlash(WHITE,.5,.25)end)
  slamTitle("HOLY COUNTER",WHITE,.9)
 end
end
function T.HolyFlame(E,d)
 local root=rootOf(d.Target)
 if not root then return end
 local g=E.Group("TW_HolyFlame")
 local a=E.Anchor(g,root.CFrame)
 E.Stream(a,{tex="fire",shape=Enum.ParticleEmitterShape.Box,light=.5,size={{0,6},{.4,11},{1,0}},alpha={{0,.15},{.7,.3},{1,1}},color={{0,WHITE},{.4,SHINE},{1,GOLD}},life={.4,.8},speed={10,26},spread=30,dir=Enum.NormalId.Top,accel=UP*18,rot={0,360}},70)
 E.Stream(a,{tex="fire.sparks",size={{0,1.2},{1,0}},color={{0,WHITE},{1,GOLD}},life={.6,1.2},speed={12,34},spread=60,dir=Enum.NormalId.Top,accel=UP*14},40)
 E.Light(g,a,SHINE,34,4)
 E.Step(g,function()
  if not root.Parent then return false end
  a.CFrame=root.CFrame
 end)
 E.After(g,d.Duration,function()g:Fade(.3)end)
end

return T
