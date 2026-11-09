--[[
 P5ModeAuraClient - how the boss looks in each Phase 5 mode (boss attribute P5Mode, Combat/P5ModeService):
  * Time: a gold clock hangs behind his back - ticked rings turning, Roman numerals and three hands sweeping
    (SurfaceGuis on a plate that follows his torso, readable from in front of him and from behind);
  * Natural: his hands glow in Polaris colours - an ice-white core, aurora motes, and aurora trails off every swing;
  * Space: he floats (server side, Boss/BossLocomotion); here faint violet light and star dust fall from his feet;
  * Enraged (boss attribute Enraged, the Gate of Wrath): crimson fire rises off him, his eyes burn red and the
    light turns a shade redder, in every phase and mode.
 Everything is local and rebuilt from the attribute, so late joiners see it too.
]]
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local E=require(game:GetService("ReplicatedStorage"):WaitForChild("VFXEngine"))
local BOSS_NAME="alterGolden, the Nothing"
local WHITE=Color3.new(1,1,1)
local GOLD=Color3.fromRGB(255,208,111)
local SHINE=Color3.fromRGB(255,246,214)
local DEEP=Color3.fromRGB(110,64,4)
local EMBER=Color3.fromRGB(255,120,60)
local ICE=Color3.fromRGB(176,226,255)
local MINT=Color3.fromRGB(115,255,205)
local VIOLET=Color3.fromRGB(174,114,255)
local ROMAN={"I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII"}
local POP=TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
local SHUT=TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)

local current

local function torsoOf(boss)return boss:FindFirstChild("UpperTorso")or boss:FindFirstChild("Torso")or boss:FindFirstChild("HumanoidRootPart")end
local function limb(boss,r15,r6)return boss:FindFirstChild(r15)or boss:FindFirstChild(r6)end

 -- one face of the clock: rings, numerals, hands
local function clockFace(plate,face)
 local gui=Instance.new("SurfaceGui")
 gui.Face=face gui.LightInfluence=0 gui.Brightness=1.8 gui.CanvasSize=Vector2.new(512,512)
 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize gui.ClipsDescendants=false
 local root=Instance.new("Frame")root.Size=UDim2.fromScale(1,1)root.BackgroundTransparency=1 root.Parent=gui
 local scale=Instance.new("UIScale")scale.Scale=0 scale.Parent=root
 local function img(tex,size,color,alpha,z)
  local i=Instance.new("ImageLabel")
  i.AnchorPoint=Vector2.new(.5,.5)i.Position=UDim2.fromScale(.5,.5)i.Size=UDim2.fromScale(size,size)
  i.BackgroundTransparency=1 i.Image=E.Lib.Id(tex)i.ImageColor3=color i.ImageTransparency=alpha i.ZIndex=z
  i.Parent=root
  return i
 end
 img("glow.soft",1.35,GOLD,.55,1)
 img("disc.soft",.98,Color3.fromRGB(50,28,4),.2,1)  -- a dark face so the gold reads against bright sky and sand
 local rings={{I=img("ring.ticked",1,GOLD,0,2),Speed=6},{I=img("ring.compass",.84,SHINE,.1,2),Speed=-10},
  {I=img("sigil.mandala2",.6,GOLD,.45,2),Speed=14}}
 for i,n in ipairs(ROMAN)do
  local a=math.rad(i*30)
  local t=Instance.new("TextLabel")
  t.AnchorPoint=Vector2.new(.5,.5)t.Position=UDim2.fromScale(.5+math.sin(a)*.36,.5-math.cos(a)*.36)t.Size=UDim2.fromScale(.13,.09)
  t.BackgroundTransparency=1 t.Text=n t.TextScaled=true t.Font=Enum.Font.Garamond t.TextColor3=SHINE
  t.TextStrokeColor3=DEEP t.TextStrokeTransparency=.15 t.ZIndex=3 t.Parent=root
 end
  -- a hand turns about the clock's centre: it lives in a full-size holder that is what rotates
 local function hand(len,width,color,z)
  local holder=Instance.new("Frame")
  holder.AnchorPoint=Vector2.new(.5,.5)holder.Position=UDim2.fromScale(.5,.5)holder.Size=UDim2.fromScale(1,1)
  holder.BackgroundTransparency=1 holder.ZIndex=z holder.Parent=root
  local f=Instance.new("Frame")
  f.AnchorPoint=Vector2.new(.5,1)f.Position=UDim2.fromScale(.5,.53)f.Size=UDim2.fromScale(width,len)
  f.BackgroundColor3=color f.BorderSizePixel=0 f.ZIndex=z f.Parent=holder
  local c=Instance.new("UICorner")c.CornerRadius=UDim.new(.5,0)c.Parent=f
  local s=Instance.new("UIStroke")s.Color=DEEP s.Thickness=1.5 s.Transparency=.3 s.Parent=f
  return holder
 end
 local hands={Hour=hand(.26,.045,SHINE,4),Minute=hand(.38,.028,GOLD,5),Second=hand(.44,.012,EMBER,6)}
 local cap=Instance.new("Frame")
 cap.AnchorPoint=Vector2.new(.5,.5)cap.Position=UDim2.fromScale(.5,.5)cap.Size=UDim2.fromScale(.06,.06)
 cap.BackgroundColor3=SHINE cap.ZIndex=7 cap.Parent=root
 local cc=Instance.new("UICorner")cc.CornerRadius=UDim.new(.5,0)cc.Parent=cap
 gui.Parent=plate
 return {Scale=scale,Rings=rings,Hands=hands}
end

local function buildTime(boss,g)
 local torso=torsoOf(boss)
 if not torso then return function()end end
 local plate=Instance.new("Part")
 plate.Name="P5Clock" plate.Anchored=true plate.CanCollide=false plate.CanQuery=false plate.CanTouch=false plate.CastShadow=false
 plate.Transparency=1 plate.Size=Vector3.new(15,15,.05) plate.CFrame=torso.CFrame plate.Parent=g.Folder
 local faces={clockFace(plate,Enum.NormalId.Front),clockFace(plate,Enum.NormalId.Back)}
 for _,f in ipairs(faces)do Tween:Create(f.Scale,POP,{Scale=1}):Play()end
 E.Stream(plate,{tex="star.crisp",size={{0,.5},{1,0}},color={{0,SHINE},{1,GOLD}},life={.6,1.1},speed={1,3},spread=180,drag=1},10)
 E.Light(g,plate,GOLD,16,1.6)
 local born=os.clock()
 local conn=Run.RenderStepped:Connect(function()
  if not torso.Parent then return end
  plate.CFrame=torso.CFrame*CFrame.new(0,2.8,3.6)  -- high enough that the hands show over his shoulders
  local t=os.clock()-born
  local tick=math.floor(t*2)+math.clamp((t*2%1)/.25,0,1)  -- the second hand ticks twice a second
  for _,f in ipairs(faces)do
   for _,r in ipairs(f.Rings)do r.I.Rotation=r.Speed*t end
   f.Hands.Second.Rotation=tick*15
   f.Hands.Minute.Rotation=t*12
   f.Hands.Hour.Rotation=30+t
  end
 end)
 return function()
  for _,f in ipairs(faces)do Tween:Create(f.Scale,SHUT,{Scale=0}):Play()end
  task.delay(.35,function()conn:Disconnect()g:Destroy()end)
 end
end

local function buildNatural(boss,g)
 local made={}
 for _,side in ipairs({"Left","Right"})do
  local hand=limb(boss,side.."Hand",side.." Arm")
  if hand then
   local down=hand.Size.Y*.42
    -- the hand itself burns ice-white, so it reads against the gold field
   local was={Color=hand.Color,Material=hand.Material}
   hand.Color=ICE hand.Material=Enum.Material.Neon
   local a=Instance.new("Attachment")a.Name="P5ModeGlow"a.CFrame=CFrame.new(0,-down,0)a.Parent=hand
   E.Stream(a,{tex="glow.soft",size={{0,3.6},{1,2}},alpha={{0,.15},{1,1}},color={{0,ICE},{1,MINT}},life={.2,.35},locked=true,light=.5},16)
   E.Stream(a,{tex="star.lens",size={{0,1.8},{1,1.2}},alpha={{0,.3},{1,1}},color={{0,WHITE},{1,ICE}},life={.3,.3},spin={90,90},locked=true},4)
   E.Stream(a,{tex="star.twinkle",size={{0,.5},{1,0}},color={{0,ICE},{.5,MINT},{1,VIOLET}},life={.5,.9},speed={1,3},spread=180,
    accel=Vector3.new(0,2,0),drag=1},12)
   local light=Instance.new("PointLight")light.Color=ICE light.Range=10 light.Brightness=2 light.Shadows=false light.Parent=a
   local a0=Instance.new("Attachment")a0.CFrame=CFrame.new(0,-down,.6)a0.Parent=hand
   local a1=Instance.new("Attachment")a1.CFrame=CFrame.new(0,-down,-.6)a1.Parent=hand
   local trail=Instance.new("Trail")
   trail.Attachment0=a0 trail.Attachment1=a1 trail.Lifetime=.3 trail.LightEmission=1 trail.LightInfluence=0 trail.FaceCamera=true
   trail.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,ICE),ColorSequenceKeypoint.new(.5,MINT),ColorSequenceKeypoint.new(1,VIOLET)})
   trail.Transparency=NumberSequence.new(.2,1)trail.WidthScale=NumberSequence.new(1,0)trail.MinLength=.05 trail.Parent=hand
   made[#made+1]={a,a0,a1,trail,Hand=hand,Was=was}
  end
 end
 return function()
  for _,set in ipairs(made)do
   for _,e in ipairs(set[1]:GetChildren())do if e:IsA("ParticleEmitter")then e.Enabled=false end end
   set[4].Enabled=false
   if set.Hand.Parent then set.Hand.Color=set.Was.Color set.Hand.Material=set.Was.Material end
  end
  task.delay(.5,function()
   for _,set in ipairs(made)do for _,i in ipairs(set)do i:Destroy()end end
   g:Destroy()
  end)
 end
end

local function buildSpace(boss,g)
 local made={}
 for _,side in ipairs({"Left","Right"})do
  local foot=limb(boss,side.."Foot",side.." Leg")
  if foot then
   local a=Instance.new("Attachment")a.Name="P5ModeDust"a.CFrame=CFrame.new(0,-foot.Size.Y*.5,0)a.Parent=foot
   E.Stream(a,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,WHITE},{1,VIOLET}},life={.6,1},speed={1,3},spread=25,
    dir=Enum.NormalId.Bottom,accel=Vector3.new(0,-3,0)},14)
   E.Stream(a,{tex="glow.soft",size={{0,2.2},{1,1}},alpha={{0,.55},{1,1}},color=VIOLET,life={.25,.4},locked=true},8)
   made[#made+1]=a
  end
 end
 return function()
  for _,a in ipairs(made)do for _,e in ipairs(a:GetChildren())do if e:IsA("ParticleEmitter")then e.Enabled=false end end end
  task.delay(1,function()for _,a in ipairs(made)do a:Destroy()end g:Destroy()end)
 end
end

local BUILD={Time=buildTime,Natural=buildNatural,Space=buildSpace}

local function clear()
 if current then
  local c=current
  current=nil
  pcall(c.Cleanup)
 end
end

local function show(boss,mode)
 if current and current.Boss==boss and current.Mode==mode then return end
 clear()
 local build=mode and BUILD[mode]
 if not build then return end
 local g=E.Group("P5ModeAura")
 current={Boss=boss,Mode=mode,Cleanup=build(boss,g)}
end

 -- the Enraged Gate's boss: crimson fire off his body, red eyes, a redder light; kept apart from the modes
local enraged
local function enrage(boss,on)
 if enraged and(not on or enraged.Boss~=boss)then
  local e=enraged enraged=nil
  for _,x in ipairs(e.Made)do if x:IsA("Attachment")then for _,p in ipairs(x:GetChildren())do if p:IsA("ParticleEmitter")then p.Enabled=false end end end end
  if e.Tint then game:GetService("TweenService"):Create(e.Tint,TweenInfo.new(1),{TintColor=WHITE,Contrast=0,Saturation=0}):Play()end
  task.delay(1.2,function()for _,x in ipairs(e.Made)do x:Destroy()end if e.Tint then e.Tint:Destroy()end end)
 end
 if not on or enraged then return end
 local made={}
 local torso=torsoOf(boss)
 if torso then
  local a=Instance.new("Attachment")a.Name="EnragedFire"a.Parent=torso
  E.Stream(a,{tex="fire",size={{0,6.5},{1,1.5}},alpha={{0,.35},{1,1}},color={{0,Color3.fromRGB(255,200,90)},{.5,Color3.fromRGB(230,40,50)},{1,Color3.fromRGB(60,0,10)}},
   life={.5,.9},speed={3,7},spread=50,dir=Enum.NormalId.Top,accel=Vector3.new(0,8,0),light=.35,shape=Enum.ParticleEmitterShape.Box},45)
  E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,Color3.fromRGB(255,200,120)},{1,Color3.fromRGB(230,40,50)}},life={.6,1.1},speed={4,9},
   spread=60,dir=Enum.NormalId.Top,accel=Vector3.new(0,6,0)},20)
  made[#made+1]=a
 end
 local head=boss:FindFirstChild("Head")
 if head then
  for _,x in ipairs({-.22,.22})do
   local a=Instance.new("Attachment")a.Name="EnragedEye"a.CFrame=CFrame.new(x,.15,-head.Size.Z*.5)a.Parent=head
   E.Stream(a,{tex="star.glare",size={{0,1.4},{1,.8}},alpha={{0,.1},{1,1}},color=Color3.fromRGB(255,40,50),life={.15,.2},locked=true,rot={0,0}},14)
   made[#made+1]=a
  end
 end
 local tint=Instance.new("ColorCorrectionEffect")
 tint.Name="EnragedTint" tint.Parent=game:GetService("Lighting")
 game:GetService("TweenService"):Create(tint,TweenInfo.new(1.5),{TintColor=Color3.fromRGB(255,222,214),Contrast=.08,Saturation=.08}):Play()
 enraged={Boss=boss,Made=made,Tint=tint}
end

local watching
local watchingEnraged
task.spawn(function()
 local boss
 while true do
  local b=workspace:FindFirstChild(BOSS_NAME)
  if b~=boss then
   boss=b
   clear()
   enrage(nil,false)
   if watching then watching:Disconnect()watching=nil end
   if watchingEnraged then watchingEnraged:Disconnect()watchingEnraged=nil end
   if b then
    watchingEnraged=b:GetAttributeChangedSignal("Enraged"):Connect(function()enrage(b,b:GetAttribute("Enraged")==true)end)
    enrage(b,b:GetAttribute("Enraged")==true)
    watching=b:GetAttributeChangedSignal("P5Mode"):Connect(function()show(b,b:GetAttribute("P5Mode"))end)
    show(b,b:GetAttribute("P5Mode"))
   end
  end
  task.wait(1)
 end
end)
