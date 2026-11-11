--[[
 P5Finale (client effect) - how Phase 5 ends (server: BossSystem.Combat.P5Finale).
   Frenzy      {Boss}                     a crimson-gold burst; fire and dark sparks pour off him from then on
   Final       {Boss, Until}              the final minute: a shock flash, a red grade and the SURVIVE timer
   Begin       {Boss, Center}             the cinematic: letterbox bars, the camera comes round to circle him
   Line        {Boss, Mode}               a line for each mode: the camera cuts in, his mode's colours flare
   Portal      {Boss, Frame, Size, Time}  a gold-rimmed portal of black and violet opens behind him
   Enter       {Boss, Frame}              he steps through it: the portal flares
   PortalClose {Frame, Size}              it collapses in a flash
   Sword       {Pos, Time}                a blade of light falls out of the sky and plants itself; a beacon stays on it,
                                          with HOLD E over it (workspace P5FinaleClaimBy/ClaimAt fill it)
   Claim       {Pos, Player}              the sword is taken: a column of light
   End         {}                         the camera comes back to the player
]]
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local P={}
local UP=Vector3.yAxis
local WHITE=Color3.new(1,1,1)
local GOLD=Color3.fromRGB(255,206,84)
local SHINE=Color3.fromRGB(255,244,200)
local AMBER=Color3.fromRGB(255,150,40)
local CRIMSON=Color3.fromRGB(255,150,30)
local EMBER=Color3.fromRGB(110,60,10)
local VIOLET=Color3.fromRGB(150,90,255)
local VOID=Color3.fromRGB(10,5,22)
local MODE={Time={GOLD,SHINE},Natural={Color3.fromRGB(120,255,200),Color3.fromRGB(110,170,255)},Space={VIOLET,Color3.fromRGB(255,120,220)}}

local function part(g,size,color,alpha,shape,material)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Material=material or Enum.Material.Neon p.Color=color p.Transparency=alpha or 0 p.Size=size
 if shape then p.Shape=shape end
 p.Parent=g.Folder
 return p
end
local function rootOf(boss)return boss and boss.Parent and boss:FindFirstChild("HumanoidRootPart")end
local function flash(brightness,tint,t)
 local cc=Instance.new("ColorCorrectionEffect")
 cc.Brightness=brightness cc.Contrast=.15 cc.TintColor=tint or WHITE cc.Parent=Lighting
 Tween:Create(cc,TweenInfo.new(t or .4,Enum.EasingStyle.Quad),{Brightness=0,Contrast=0,TintColor=WHITE}):Play()
 task.delay((t or .4)+.05,function()cc:Destroy()end)
end
local function backOut(x)
 local c=1.70158
 x=math.clamp(x,0,1)
 return 1+(c+1)*(x-1)^3+c*(x-1)^2
end

 -- the camera: each shot is fn(t) -> CFrame, fov; a new shot blends in from wherever the camera is
local cam={}
local function shake(power,time)
 cam.shakePower=power cam.shakeUntil=os.clock()+time cam.shakeTime=time
end
local function shoot(fn,blend)
 local c=workspace.CurrentCamera
 if not cam.shot then
  cam.savedFov=c.FieldOfView
  Run:BindToRenderStep("P5FinaleCam",Enum.RenderPriority.Camera.Value+2,function()
   local f=cam.shot
   if not f then return end
   local t=os.clock()-cam.started
   local cf,fov=f(t)
   local k=cam.blend>0 and math.clamp(t/cam.blend,0,1)or 1
   k=k*k*(3-2*k)
   local view=workspace.CurrentCamera
   view.CameraType=Enum.CameraType.Scriptable
   cf=cam.from:Lerp(cf,k)
   if cam.shakeUntil and os.clock()<cam.shakeUntil then
    local s=cam.shakePower*(cam.shakeUntil-os.clock())/cam.shakeTime
    cf*=CFrame.Angles((math.random()-.5)*s,(math.random()-.5)*s,(math.random()-.5)*s*.5)
   end
   view.CFrame=cf
   if fov then view.FieldOfView=view.FieldOfView+(fov-view.FieldOfView)*.12 end
  end)
 end
 cam.from=c.CFrame
 cam.shot=fn cam.started=os.clock() cam.blend=blend or .8
end
local function release()
 if not cam.shot then return end
 cam.shot=nil
 Run:UnbindFromRenderStep("P5FinaleCam")
 local c=workspace.CurrentCamera
 c.CameraType=Enum.CameraType.Custom
 c.FieldOfView=cam.savedFov or 70
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if hum then c.CameraSubject=hum end
end
 -- circling him: angle (radians) around him, radius and height, turning at speed rad/s
local function orbit(boss,angle,radius,height,speed,fov)
 local last=Vector3.zero
 return function(t)
  local r=rootOf(boss)
  local c=(r and r.Position or last)+UP*1.6
  last=c-UP*1.6
  local a=angle+t*(speed or .1)
  return CFrame.lookAt(c+Vector3.new(math.cos(a)*radius,height,math.sin(a)*radius),c+UP*.4),fov or 52
 end
end
local function angleTo(center)
 local p=workspace.CurrentCamera.CFrame.Position-center
 return math.atan2(p.Z,p.X)
end

local bars
local function letterbox(on)
 if on and not bars then
  bars=Instance.new("ScreenGui")
  bars.Name="P5FinaleBars" bars.IgnoreGuiInset=true bars.DisplayOrder=-1 bars.ResetOnSpawn=false
  for _,y in ipairs({0,1})do
   local f=Instance.new("Frame")
   f.BackgroundColor3=Color3.new(0,0,0) f.BorderSizePixel=0 f.AnchorPoint=Vector2.new(0,y)
   f.Position=UDim2.fromScale(0,y) f.Size=UDim2.fromScale(1,0) f.Parent=bars
   Tween:Create(f,TweenInfo.new(.6,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(1,.1)}):Play()
  end
  bars.Parent=player:WaitForChild("PlayerGui")
 elseif not on and bars then
  local old=bars
  bars=nil
  for _,f in ipairs(old:GetChildren())do Tween:Create(f,TweenInfo.new(.5),{Size=UDim2.fromScale(1,0)}):Play()end
  task.delay(.55,function()old:Destroy()end)
 end
end

 -- the frenzy: fire and dark sparks pour off him for as long as it (or the final minute) lasts
local auras={}
local function aura(E,boss)
 if auras[boss]then return end
 local r=rootOf(boss)
 if not r then return end
 local g=E.Group("P5FinaleAura")
 auras[boss]=g
 local a=E.Anchor(g,r.CFrame)
 local fire=E.Stream(a,{tex="fire",size={{0,3.2},{1,.6}},alpha={{0,.35},{1,1}},color={{0,SHINE},{.35,AMBER},{1,CRIMSON}},life={.45,.75},
  speed={7,13},spread=30,dir=Enum.NormalId.Top},36)
  -- flame tongues off his whole body (the arena fire's toon flipbook, burning red) and a crimson outline
 local body=part(g,Vector3.new(3.4,5.6,2.2),WHITE,1)
 local tongues=Instance.new("ParticleEmitter")
 tongues.Texture="rbxassetid://93253997872542" tongues.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4
 tongues.FlipbookMode=Enum.ParticleFlipbookMode.OneShot tongues.LightInfluence=0 tongues.LightEmission=.5 tongues.Brightness=1.6
 tongues.Shape=Enum.ParticleEmitterShape.Box tongues.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume tongues.EmissionDirection=Enum.NormalId.Top
 tongues.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,236,180)),ColorSequenceKeypoint.new(.35,Color3.fromRGB(255,120,40)),
  ColorSequenceKeypoint.new(1,CRIMSON)})
 tongues.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.6),NumberSequenceKeypoint.new(.4,2.8),NumberSequenceKeypoint.new(1,.6)})
 tongues.Squash=NumberSequence.new(.5)
 tongues.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.7,.3),NumberSequenceKeypoint.new(1,1)})
 tongues.Lifetime=NumberRange.new(.45,.7) tongues.Speed=NumberRange.new(4,8) tongues.Acceleration=UP*10
 tongues.Rotation=NumberRange.new(-10,10) tongues.Rate=40*E.Quality tongues.Parent=body
 local outline=Instance.new("Highlight")
 outline.FillColor=CRIMSON outline.FillTransparency=.75 outline.OutlineColor=Color3.fromRGB(255,120,80) outline.OutlineTransparency=.05
 outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Adornee=boss outline.Parent=g.Folder
 local sparks=E.Stream(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,CRIMSON},{1,EMBER}},life={.5,.9},speed={8,16},spread=180,drag=1.5},18)
 local smoke=E.Stream(a,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.6},{1,1}},color={{0,EMBER},{1,Color3.fromRGB(20,8,12)}},life={.8,1.3},
  speed={3,6},spread=40,dir=Enum.NormalId.Top},8)
 local light=E.Light(g,a,CRIMSON,22,2.5)
 local grade
 E.Step(g,function(_,t)
  local root=rootOf(boss)
  local stage=boss.Parent and boss:GetAttribute("P5Stage")
  if not root or(stage~="Frenzy"and stage~="Final")then
   fire.Enabled=false sparks.Enabled=false smoke.Enabled=false light.Enabled=false tongues.Enabled=false outline:Destroy()
   if grade then grade:Destroy()grade=nil end
   auras[boss]=nil
   E.After(g,1.4,function()g:Destroy()end)
   return false
  end
  a.CFrame=root.CFrame
  body.CFrame=root.CFrame
  local final=stage=="Final"
  fire.Rate=(final and 70 or 36)*E.Quality sparks.Rate=(final and 40 or 18)*E.Quality tongues.Rate=(final and 80 or 40)*E.Quality
  outline.FillTransparency=final and .62+.1*math.sin(t*8) or .75
  light.Brightness=(final and 4 or 2.5)*(.8+.2*math.sin(t*9))
  if final and not grade then
   grade=Instance.new("ColorCorrectionEffect")
   grade.TintColor=Color3.fromRGB(255,228,222) grade.Contrast=.08 grade.Saturation=.05 grade.Parent=Lighting
  end
  return true
 end)
end

function P.Frenzy(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local g=E.Group("P5FinaleFrenzy")
 local a=E.Anchor(g,r.CFrame)
 E.Sprite(a,{tex="flare.burst",size={{0,4},{.3,26},{1,30}},alpha={{0,0},{1,1}},color=CRIMSON},.45)
 E.Sprite(a,{tex="star.glare",size={{0,3},{.3,30},{1,10}},alpha={{0,0},{1,1}},color=GOLD,rot={30,30}},.4)
 E.Emit(a,{tex="fire",size={{0,4},{1,1}},alpha={{0,.2},{1,1}},color={{0,SHINE},{.4,AMBER},{1,CRIMSON}},life={.5,.8},speed={30,60},spread=180,drag=3},40)
 E.Light(g,a,CRIMSON,40,8,.6)
 E.After(g,1.2,function()g:Destroy()end)
 aura(E,d.Boss)
end

local hud
local function survive(untilAt)
 if hud then hud:Destroy()end
 local gui=Instance.new("ScreenGui")
 gui.Name="P5FinaleSurvive" gui.ResetOnSpawn=false gui.DisplayOrder=20 gui.IgnoreGuiInset=true
 hud=gui
 local title=Instance.new("TextLabel")
 title.BackgroundTransparency=1 title.AnchorPoint=Vector2.new(.5,0) title.Position=UDim2.fromScale(.5,.27) title.Size=UDim2.fromOffset(420,40)
 title.Font=Enum.Font.GothamBlack title.TextSize=34 title.TextColor3=WHITE title.TextStrokeColor3=CRIMSON title.TextStrokeTransparency=0
 title.Text="SURVIVE" title.Parent=gui
 local clock=title:Clone()
 clock.Position=UDim2.fromScale(.5,.27)+UDim2.fromOffset(0,38) clock.Size=UDim2.fromOffset(420,56) clock.TextSize=52
 clock.TextStrokeColor3=Color3.fromRGB(40,10,14) clock.Text="1:00" clock.Parent=gui
 local scale=Instance.new("UIScale") scale.Scale=1.6 scale.Parent=title
 Tween:Create(scale,TweenInfo.new(.4,Enum.EasingStyle.Back),{Scale=1}):Play()
 gui.Parent=player:WaitForChild("PlayerGui")
 local conn
 conn=Run.RenderStepped:Connect(function()
  local left=untilAt-workspace:GetServerTimeNow()
  if left<=0 or workspace:GetAttribute("P5FinaleUntil")~=untilAt or not gui.Parent then
   conn:Disconnect()
   if gui.Parent then
    Tween:Create(title,TweenInfo.new(.4),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    Tween:Create(clock,TweenInfo.new(.4),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    task.delay(.45,function()gui:Destroy()end)
   end
   return
  end
  local secs=math.ceil(left)
  clock.Text=string.format("%d:%02d",secs//60,secs%60)
  clock.TextColor3=left<10 and WHITE:Lerp(CRIMSON,.5+.5*math.sin(os.clock()*10))or WHITE
 end)
end
function P.Final(E,d)
 local r=rootOf(d.Boss)
 if r then
  local g=E.Group("P5FinaleFinal")
  local a=E.Anchor(g,r.CFrame)
  E.Sprite(a,{tex="flare.burst",size={{0,6},{.25,48},{1,56}},alpha={{0,0},{1,1}},color=WHITE},.5)
  E.Sprite(a,{tex="glow.soft",size={{0,10},{1,70}},alpha={{0,.2},{1,1}},color=CRIMSON},.7)
  local ring=part(g,Vector3.new(.2,6,6),CRIMSON,.15,Enum.PartType.Cylinder)
  ring.CFrame=CFrame.new(r.Position-UP*2.6)*CFrame.Angles(0,0,math.pi/2)
  E.Tween(ring,.7,{Size=Vector3.new(.1,180,180),Transparency=1},Enum.EasingStyle.Quint)
  E.Light(g,a,CRIMSON,70,10,.8)
  E.After(g,1.4,function()g:Destroy()end)
 end
 flash(.35,Color3.fromRGB(255,214,206),.6)
 aura(E,d.Boss)
 if d.Until then survive(d.Until)end
end

function P.Begin(E,d)
 local r=rootOf(d.Boss)
 local c=r and r.Position or d.Center or Vector3.zero
 cam.lines=0
 letterbox(true)
 shoot(orbit(d.Boss,angleTo(c),20,5,.12,55),1.2)
end

function P.Line(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 cam.lines=(cam.lines or 0)+1
 local c=MODE[d.Mode]or MODE.Time
 local g=E.Group("P5FinaleLine")
 local a=E.Anchor(g,r.CFrame)
 E.Sprite(a,{tex="glow.soft",size={{0,3},{.3,9},{1,11}},alpha={{0,.5},{1,1}},color=c[1]},.6)
 E.Emit(a,{tex="star.twinkle",size={{0,.8},{1,0}},color={{0,WHITE},{.4,c[1]},{1,c[2]}},life={.6,1.1},speed={6,16},spread=180,drag=2},28)
 E.Light(g,a,c[1],22,3,.8)
 E.After(g,1.5,function()g:Destroy()end)
  -- each line is its own close shot from a new side
 local base=angleTo(r.Position)
 local radius=({13,10,12})[cam.lines]or 12
 shoot(orbit(d.Boss,base+1.1+(cam.lines%2==0 and .5 or -.4),radius,({2.5,1.2,4})[cam.lines]or 2.5,.07,44),.45)
end

local portal
function P.Portal(E,d)
 local g=E.Group("P5FinalePortal")
 local F=d.Frame
 local R=(d.Size or 16)/2
 local T=d.Time or 1.2
 local carrier=part(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=F
 local N=E.Quality<.6 and 24 or 40
 local pts={}
 for i=1,N do local at=Instance.new("Attachment") at.Parent=carrier pts[i]=at end
 local function band(w,color,alpha,emission)
  for i=1,N do
   local b=Instance.new("Beam")
   b.Attachment0=pts[i] b.Attachment1=pts[i%N+1]
   b.FaceCamera=true b.Segments=2 b.LightEmission=emission b.LightInfluence=0
   b.Color=ColorSequence.new(color) b.Transparency=NumberSequence.new(alpha) b.Width0=w b.Width1=w b.Parent=carrier
  end
 end
 band(3.4,AMBER,.35,1)
 band(1.4,GOLD,0,.8)
 band(.45,WHITE,0,1)
  -- the inside: a black core, violet and gold shimmer turning over it
 local axis=CFrame.Angles(0,math.pi/2,0)  -- a cylinder's axis is X: turn it to face out of the portal
 local core=part(g,Vector3.new(.2,.1,.1),VOID,0,Enum.PartType.Cylinder,Enum.Material.SmoothPlastic)
 local swirl=part(g,Vector3.new(.3,.1,.1),VIOLET,.15,Enum.PartType.Cylinder,Enum.Material.ForceField)
 local swirl2=part(g,Vector3.new(.4,.1,.1),GOLD,.45,Enum.PartType.Cylinder,Enum.Material.ForceField)
 local pull=part(g,Vector3.new(R*2.4,R*2.4,1.5),WHITE,1,nil,Enum.Material.SmoothPlastic)  -- motes are drawn in from its shell
 pull.CFrame=F
 local motes=Instance.new("ParticleEmitter")
 motes.Texture=E.Lib.Id("star.tiny") motes.Shape=Enum.ParticleEmitterShape.Sphere motes.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 motes.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward motes.Speed=NumberRange.new(R*1.1,R*1.5) motes.Lifetime=NumberRange.new(.55,.75)
 motes.Size=NumberSequence.new(.6,0) motes.Color=ColorSequence.new(SHINE,VIOLET) motes.LightEmission=1 motes.LightInfluence=0
 motes.Rate=60*E.Quality motes.Parent=pull
 local a=E.Anchor(g,F)
 local glow=E.Stream(a,{tex="glow.soft",size={{0,R*2.2},{1,R*2.6}},alpha={{0,.75},{1,1}},color=VIOLET,life={.5,.7},speed={0,0}},6)
 local light=E.Light(g,a,VIOLET,R*3,2)
 local light2=E.Light(g,a,GOLD,R*2,1.2)
 E.Sprite(a,{tex="flare.burst",size={{0,2},{.3,R*3},{1,R*3.4}},alpha={{0,0},{1,1}},color=SHINE},.4)
 portal={G=g,Frame=F,R=R,Glow=glow,Motes=motes,Light=light,Flare=0}
 E.Step(g,function(_,t)
  local open=backOut(t/T)
  local shut=portal.ClosedAt and math.clamp((os.clock()-portal.ClosedAt)/.45,0,1)or 0
  local r=R*math.max(open,0)*(1-shut*shut)
  local flare=math.max(0,portal.Flare-(os.clock()-(portal.FlareAt or 0))*2)
  for i,at in ipairs(pts)do
   local ang=(i-1)/N*math.pi*2
   local wob=1+.025*math.sin(t*6+ang*3)
   at.Position=Vector3.new(math.cos(ang)*r*wob,math.sin(ang)*r*wob,0)
  end
  local dsz=math.max(r*1.94,.05)
  core.Size=Vector3.new(.12,dsz,dsz)
  swirl.Size=Vector3.new(.25,dsz*1.01,dsz*1.01) swirl2.Size=Vector3.new(.35,dsz*.9,dsz*.9)
  local spin=F*axis
  workspace:BulkMoveTo({core,swirl,swirl2},{spin,spin*CFrame.Angles(t*1.6,0,0)*CFrame.new(-.1,0,0),spin*CFrame.Angles(-t*2.4,0,0)*CFrame.new(-.18,0,0)},
   Enum.BulkMoveMode.FireCFrameChanged)
  swirl.Transparency=.15-.1*flare swirl2.Transparency=.45-.3*flare
  light.Brightness=2+5*flare
  if shut>=1 then
   motes.Enabled=false glow.Enabled=false light.Enabled=false light2.Enabled=false
   core.Transparency=1 swirl.Transparency=1 swirl2.Transparency=1
   for _,b in ipairs(carrier:GetChildren())do if b:IsA("Beam")then b.Enabled=false end end
   E.After(g,1,function()g:Destroy()end)
   return false
  end
  return true
 end)
  -- the shot: from behind him and a little to one side, the portal's face filling the frame as he walks into it
 local camPos=F.Position+F.LookVector*36+F.RightVector*12+UP*(2-R)+UP*6
 local look=F.Position-UP*R*.15
 shoot(function(t)return CFrame.lookAt(camPos+(look-camPos).Unit*math.min(t,7)*1.1,look),48 end,.8)
end

function P.Enter(E,d)
 if not portal then return end
 portal.Flare=1 portal.FlareAt=os.clock()
 local g=E.Group("P5FinaleEnter")
 local a=E.Anchor(g,d.Frame)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.25,portal.R*3},{1,portal.R*3.4}},alpha={{0,0},{1,1}},color=WHITE},.5)
 E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,VIOLET}},life={.4,.8},speed={14,34},spread=180,drag=2},40)
 E.Light(g,a,WHITE,30,8,.6)
 E.After(g,1.2,function()g:Destroy()end)
end

function P.PortalClose(E,d)
 if portal then portal.ClosedAt=os.clock() end
 local g=E.Group("P5FinaleClose")
 local a=E.Anchor(g,d.Frame)
 local R=(d.Size or 16)/2
 E.After(g,.4,function()
  E.Sprite(a,{tex="flare.burst",size={{0,2},{.2,R*4},{1,R*4.6}},alpha={{0,0},{1,1}},color=SHINE},.45)
  E.Sprite(a,{tex="star.glare",size={{0,2},{.2,R*5},{1,R*1.5}},alpha={{0,0},{1,1}},color=GOLD,rot={15,15}},.4)
  E.Emit(a,{tex="star.twinkle",size={{0,1.2},{1,0}},color={{0,WHITE},{.5,GOLD},{1,VIOLET}},life={.6,1.1},speed={20,44},spread=180,drag=2.5},50)
  E.Light(g,a,GOLD,50,10,.7)
  flash(.25,Color3.fromRGB(255,240,220),.5)
  shake(.025,.35)
 end)
 E.After(g,2,function()g:Destroy()end)
end

 -- HOLD E over the planted sword; it fills while someone holds it (workspace P5FinaleClaimBy / P5FinaleClaimAt)
local CLAIM=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local function claimCue(E,bg,land)
 local anchor=part(bg,Vector3.one*.2,WHITE,1)
 anchor.CFrame=CFrame.new(land+UP*7)
 local gui=Instance.new("BillboardGui")
 gui.Name="P5FinaleClaim" gui.Size=UDim2.fromOffset(240,96) gui.AlwaysOnTop=true gui.LightInfluence=0 gui.MaxDistance=120
 gui.Adornee=anchor gui.ResetOnSpawn=false
 local key=Instance.new("TextLabel")
 key.BackgroundTransparency=1 key.Size=UDim2.new(1,0,0,44) key.Font=Enum.Font.GothamBlack key.TextSize=38 key.Text="HOLD E"
 key.TextColor3=WHITE key.TextStrokeColor3=Color3.fromRGB(90,60,10) key.TextStrokeTransparency=0 key.Parent=gui
 local what=key:Clone()
 what.Position=UDim2.fromOffset(0,42) what.Size=UDim2.new(1,0,0,24) what.TextSize=20 what.Text="Claim Victory" what.TextColor3=GOLD what.Parent=gui
 local bar=Instance.new("Frame")
 bar.AnchorPoint=Vector2.new(.5,0) bar.Position=UDim2.new(.5,0,0,72) bar.Size=UDim2.fromOffset(170,10) bar.BackgroundColor3=Color3.fromRGB(30,24,10)
 bar.BackgroundTransparency=.2 bar.BorderSizePixel=0 bar.Parent=gui
 Instance.new("UICorner",bar).CornerRadius=UDim.new(.5,0)
 local fill=Instance.new("Frame")
 fill.Size=UDim2.fromScale(0,1) fill.BackgroundColor3=GOLD fill.BorderSizePixel=0 fill.Parent=bar
 Instance.new("UICorner",fill).CornerRadius=UDim.new(.5,0)
 gui.Parent=player:WaitForChild("PlayerGui")
 local range,holdTime=CLAIM.FinaleClaimRange or 14,CLAIM.FinaleClaimHold or 1.5
 E.Step(bg,function(_,t)
  if not gui.Parent then return false end
  local me=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local near=me and((me.Position-land)*Vector3.new(1,0,1)).Magnitude<=range
  key.Text=near and"HOLD E"or"CLAIM"
  what.Text=near and"Claim Victory"or"Walk to the sword"
  key.TextTransparency=near and 0 or .25
  local at=workspace:GetAttribute("P5FinaleClaimAt")
  local k=at and math.clamp((workspace:GetServerTimeNow()-at)/holdTime,0,1)or 0
  fill.Size=UDim2.fromScale(k,1)
  gui.Size=UDim2.fromOffset(240,96):Lerp(UDim2.fromOffset(270,108),.5+.5*math.sin(t*4))
  return true
 end)
 bg.Gui=gui
end

 -- the sword of light out of the sky
local beacon
function P.Sword(E,d)
 local g=E.Group("P5FinaleSword")
 local T=d.Time or 1.2
 local land=d.Pos
 local top=land+UP*300
 local blade=part(g,Vector3.new(1,18,.4),SHINE,0)
 local glow=part(g,Vector3.new(3.2,21,1.6),GOLD,.55)
 local tip=Instance.new("Attachment") tip.Position=Vector3.new(0,9,0) tip.Parent=blade
 local tail=Instance.new("Attachment") tail.Position=Vector3.new(0,-9,0) tail.Parent=blade
 local trail=Instance.new("Trail")
 trail.Attachment0=tip trail.Attachment1=tail trail.Lifetime=.45 trail.LightEmission=1 trail.LightInfluence=0 trail.FaceCamera=true
 trail.Color=ColorSequence.new(SHINE,AMBER) trail.Transparency=NumberSequence.new(.1,1) trail.WidthScale=NumberSequence.new(1,.3) trail.Parent=blade
 local streak=E.Stream(tail,{tex="star.crisp",size={{0,1.4},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={4,10},spread=180},50)
 local mark=E.Anchor(g,CFrame.new(land+UP*.4))
 E.Sprite(mark,{tex="glow.soft",orient="flat",size={{0,4},{1,26}},alpha={{0,.9},{.8,.35},{1,1}},color=GOLD},T+.1)
 local hit=false
 local camPos
 do
  local me=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local from=me and me.Position or land+Vector3.new(0,0,40)
  local flat=(from-land)*Vector3.new(1,0,1)
  flat=flat.Magnitude>1 and flat.Unit or Vector3.zAxis
  camPos=land+flat*30+UP*7
 end
 local function at(t)
  local k=math.clamp(t/T,0,1)
  return top:Lerp(land+UP*6,k*k)
 end
 shoot(function(t)return CFrame.lookAt(camPos,hit and land+UP*7 or at(t)),55 end,.5)
 E.Step(g,function(_,t)
  if not hit then
   local p=at(t)
   workspace:BulkMoveTo({blade,glow},{CFrame.new(p),CFrame.new(p)},Enum.BulkMoveMode.FireCFrameChanged)
   if t>=T then
    hit=true
    blade.Transparency=1 glow.Transparency=1 streak.Enabled=false trail.Enabled=false
     -- the landing: a white dome, a ring along the floor, dust, sparks and a flash
    local dome=part(g,Vector3.new(4,2,4),WHITE,.1,Enum.PartType.Ball)
    dome.CFrame=CFrame.new(land)
    E.Tween(dome,.4,{Size=Vector3.new(30,15,30),Transparency=1})
    local ring=part(g,Vector3.new(.2,6,6),GOLD,.2,Enum.PartType.Cylinder)
    ring.CFrame=CFrame.new(land+UP*.2)*CFrame.Angles(0,0,math.pi/2)
    E.Tween(ring,.6,{Size=Vector3.new(.1,90,90),Transparency=1},Enum.EasingStyle.Quint)
    local a=E.Anchor(g,CFrame.new(land+UP*2))
    E.Sprite(a,{tex="flare.burst",size={{0,6},{.2,40},{1,46}},alpha={{0,0},{1,1}},color=SHINE},.45)
    E.Emit(a,{tex="smoke",light=0,size={{0,4},{1,12}},alpha={{0,.4},{1,1}},color={{0,Color3.fromRGB(200,170,110)},{1,Color3.fromRGB(110,90,60)}},
     life={.9,1.5},speed={20,40},spread=80,dir=Enum.NormalId.Top,drag=3},24)
    E.Emit(a,{tex="star.crisp",size={{0,1.3},{1,0}},color={{0,WHITE},{1,GOLD}},life={.4,.9},speed={30,70},spread=70,dir=Enum.NormalId.Top,
     accel=Vector3.new(0,-60,0)},50)
    E.Light(g,a,GOLD,60,12,.8)
    flash(.3,Color3.fromRGB(255,240,210),.5)
    shake(.04,.5)
     -- the beacon: a tall column of soft gold over the sword until someone takes it
    if beacon then beacon:Destroy()end
    local bg=E.Group("P5FinaleBeacon")
    beacon=bg
    local base=part(bg,Vector3.one*.2,WHITE,1)
    base.CFrame=CFrame.new(land)
    local a0=E.Attach(base,CFrame.new(0,0,0))
    local a1=E.Attach(base,CFrame.new(0,140,0))
    E.Beam(bg,a0,a1,{color=GOLD,alpha={{0,.45},{.6,.8},{1,1}},width=5,face=true})
    local inner=E.Beam(bg,a0,a1,{color=SHINE,alpha={{0,.2},{.5,.7},{1,1}},width=1.6,face=true})
    for _,b in ipairs(bg.Folder:GetDescendants())do if b:IsA("Beam")then b.FaceCamera=true b.LightEmission=1 b.LightInfluence=0 end end
    local sparkle=E.Anchor(bg,CFrame.new(land+UP*4))
    E.Stream(sparkle,{tex="star.twinkle",size={{0,.8},{1,0}},color={{0,WHITE},{1,GOLD}},life={1,1.6},speed={2,5},spread=180,accel=Vector3.new(0,3,0)},10)
    E.Light(bg,sparkle,GOLD,26,2.5)
    claimCue(E,bg,land)
    E.Step(bg,function()
     if not workspace:GetAttribute("P5FinaleSword")and(os.clock()-(bg.Born or os.clock()))>2 then
      if bg.Gui then bg.Gui:Destroy()end
      E.After(bg,.1,function()bg:Destroy()end)
      if beacon==bg then beacon=nil end
      return false
     end
     return true
    end)
    bg.Born=os.clock()
    E.After(g,2,function()g:Destroy()end)
   end
  end
  return not hit or t<T+2
 end)
end

function P.Claim(E,d)
 if beacon then
  if beacon.Gui then beacon.Gui:Destroy()end
  beacon:Destroy() beacon=nil
 end
 if not d.Pos then return end
 local g=E.Group("P5FinaleClaim")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 local col=part(g,Vector3.new(300,6,6),SHINE,.1,Enum.PartType.Cylinder)
 col.CFrame=CFrame.new(d.Pos+UP*150)*CFrame.Angles(0,0,math.pi/2)
 E.Tween(col,1,{Size=Vector3.new(300,26,26),Transparency=1},Enum.EasingStyle.Quad)
 E.Sprite(a,{tex="flare.burst",size={{0,6},{.2,50},{1,60}},alpha={{0,0},{1,1}},color=WHITE},.6)
 E.Emit(a,{tex="star.twinkle",size={{0,1.4},{1,0}},color={{0,WHITE},{1,GOLD}},life={.8,1.4},speed={10,40},spread=180,drag=1.5},60)
 E.Light(g,a,GOLD,80,12,1)
 flash(.45,Color3.fromRGB(255,246,226),.9)
 E.After(g,2,function()g:Destroy()end)
 release()
 letterbox(false)
end

function P.End(E,d)
 release()
 letterbox(false)
end

 -- a fight that ends some other way (a wipe, a reset) mid-cinematic gives the camera back
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
 if workspace:GetAttribute("EncounterStarted")~=true then
  release()
  letterbox(false)
  if hud then hud:Destroy() hud=nil end
  if beacon then
   if beacon.Gui then beacon.Gui:Destroy()end
   beacon:Destroy() beacon=nil
  end
  if portal and portal.G then portal.G:Destroy() portal=nil end
 end
end)

return P
