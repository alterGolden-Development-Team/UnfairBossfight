--[[
 IrisStar (client effect) - a radiant star with an iris inside it, whose light blinds.
 Star layers (camera-facing, back to front): dark backing, rays, pink aura, chromatic
 glare, lens star, gold iris ring, ticked ring, iris fibres, dark pupil, pupil rim.
 Blind: the closer the local player is to the star, the stronger a glare centred on the
 star's screen position, then a white wash, grade and bloom. Collapse makes it stronger;
 the supernova flashes white. Only the pupil's shadow under the star survives the blast.
 Beats: Start -> Collapse -> Supernova -> End.
]]
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local I={}
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
local IRIS=Color3.fromRGB(255,120,200)
local GOLD=Color3.fromRGB(255,208,111)
local VIOLET=Color3.fromRGB(174,114,255)
local casts={}

local okReset,Reset=pcall(function()return require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)end)
local function viewAllowed()
 if not okReset or type(Reset)~="table"or not Reset.ViewAllowed then return true end
 local ok,res=pcall(Reset.ViewAllowed)
 return not ok or res
end

local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end

local function makeBlind(E)
 local plr=Players.LocalPlayer
 local pg=plr and plr:FindFirstChildOfClass("PlayerGui")
 if not pg then return nil end
 local gui=Instance.new("ScreenGui")
 gui.Name="IrisBlind"gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=20
 local function image(id,color)
  local l=Instance.new("ImageLabel")
  l.AnchorPoint=Vector2.new(.5,.5)l.BackgroundTransparency=1 l.Image=E.Lib.Id(id)l.ImageColor3=color l.ImageTransparency=1
  l.Parent=gui
  return l
 end
 local b={Gui=gui}
 b.Rays=image("star.glare2",Color3.fromRGB(255,225,245))
 b.Glare=image("glow.soft",Color3.fromRGB(255,240,250))
 b.Wash=Instance.new("Frame")
 b.Wash.Size=UDim2.fromScale(1,1)b.Wash.BackgroundColor3=Color3.fromRGB(255,246,252)b.Wash.BackgroundTransparency=1 b.Wash.BorderSizePixel=0
 b.Wash.Parent=gui
 gui.Parent=pg
 b.CC=Instance.new("ColorCorrectionEffect")b.CC.Name="IrisBlindGrade"b.CC.Parent=Lighting
 b.Bloom=Instance.new("BloomEffect")b.Bloom.Name="IrisBlindBloom"b.Bloom.Intensity=0 b.Bloom.Size=40 b.Bloom.Threshold=.8 b.Bloom.Parent=Lighting
 return b
end

local function dropBlind(c)
 local b=c.Blind
 if not b then return end
 c.Blind=nil
 b.Gui:Destroy()b.CC:Destroy()b.Bloom:Destroy()
end

function I.Start(E,d)
 if casts[d.Token]then return end
 local g=E.Group("IrisStar")
 local R=d.Radius or 10.5
 local c={G=g,D=d,Root=d.Root,Open=0,Lid=0,Layers={},BlindK=0}
 casts[d.Token]=c
 local eye=E.Anchor(g,CFrame.new((d.Root and d.Root.Position or Vector3.zero)+Vector3.yAxis*d.Height))
 c.Eye=eye
 local function layer(spec,base)
  local e=E.Sprite(eye,spec,19)
  e.Size=NumberSequence.new(.01)
  c.Layers[#c.Layers+1]={E=e,Base=base}
 end
  -- dark backing keeps the iris colours from washing out against a bright sky; fills
  -- stay faint so the gold ring and chromatic fibres carry the read
 layer({tex="glow.soft",light=0,alpha=.45,color=Color3.fromRGB(20,6,30),z=-2},R*3.2)
 layer({tex="flare.burst",alpha=.7,color=VIOLET,spin={-6,-6},z=-1},R*5.5)
 layer({tex="glow.soft",alpha=.7,color=Color3.fromRGB(255,70,170),z=-.8},R*3)
 layer({tex="star.glare2",alpha=.55,color=WHITE,rot={45,45},z=-.6},R*6.5)
 layer({tex="star.lens",alpha=.5,color=Color3.fromRGB(255,200,235),rot={0,0},z=-.4},R*4.2)
 layer({tex="sigil.ring",alpha=.1,color=Color3.fromRGB(255,170,60),spin={18,18},z=.1},R*2.4)
 layer({tex="ring.ticked",alpha=.25,color=Color3.fromRGB(255,150,60),spin={-10,-10},z=.15},R*2)
 layer({tex="burst.fringe",alpha=.25,color=Color3.fromRGB(255,80,190),spin={-35,-35},z=.2},R*1.65)
 layer({tex="glow.soft",light=0,alpha=0,color=BLACK,z=.4},R*.9)
 layer({tex="ring.crisp",alpha=.1,color=IRIS,z=.5,spin={60,60}},R*.95)
 c.Pupil={9,10}
 c.Light=E.Light(g,eye,IRIS,70,0)
 c.Blind=makeBlind(E)
 g.Folder.Destroying:Connect(function()dropBlind(c)end)
 local inner,range=d.BlindInner or 12,d.BlindRange or 95
 local born=os.clock()
 E.Step(g,function(dt)
  local t=os.clock()-born
  if not c.Locked and c.Root and c.Root.Parent then
   eye.CFrame=eye.CFrame:Lerp(CFrame.new(c.Root.Position+Vector3.yAxis*d.Height),1-math.exp(-dt*10))
  end
  c.Open=c.Gone and 0 or smooth(t/(d.Windup or 1.2))
  local pulse=1+.04*math.sin(t*2.2)
  local dil=1+1.4*c.Lid
  local shrink=1-.8*c.Lid  -- the collapse condenses the star toward a point
  for i,L in ipairs(c.Layers)do
   local k=(i==c.Pupil[1]or i==c.Pupil[2])and dil or 1
   L.E.Size=NumberSequence.new(math.max(L.Base*k*pulse*c.Open*shrink,.01))
  end
  c.Light.Brightness=(4+8*c.Lid)*c.Open
  local b=c.Blind
  if b then
   local cam=workspace.CurrentCamera
   local char=Players.LocalPlayer.Character
   local ref=char and char:FindFirstChild("HumanoidRootPart")
   local dist=((ref and ref.Position or cam.CFrame.Position)-eye.Position).Magnitude
   local near=1-math.clamp((dist-inner)/math.max(range-inner,1),0,1)
   local target=(near^1.6)*c.Open*(1+.8*c.Lid)
   if c.Ending or not viewAllowed()then target=0 end
   c.BlindK+=(target-c.BlindK)*(1-math.exp(-dt*5))
   local k=math.min(c.BlindK,1.4)
   local sp,onScreen=cam:WorldToViewportPoint(eye.Position)
   local vy=cam.ViewportSize.Y
   local gs=vy*(.5+2.6*k)
   b.Glare.Position=UDim2.fromOffset(sp.X,sp.Y)b.Glare.Size=UDim2.fromOffset(gs,gs)
   b.Glare.ImageTransparency=(onScreen and sp.Z>0)and 1-math.min(k*1.1,1)*.95 or 1
   b.Rays.Position=b.Glare.Position b.Rays.Size=UDim2.fromOffset(gs*1.7,gs*1.7)b.Rays.Rotation=t*8
   b.Rays.ImageTransparency=(onScreen and sp.Z>0)and 1-math.min(k,1)*.8 or 1
   local wash=math.clamp((k-.35)/.65,0,1)*.88
   if c.FlashAt then wash=math.max(wash,1-math.clamp((os.clock()-c.FlashAt)/1.4,0,1))end
   b.Wash.BackgroundTransparency=1-wash
   b.CC.Brightness=.3*k b.CC.Contrast=-.2*k b.CC.Saturation=-.35*k
   b.Bloom.Intensity=1.6*k
   if c.Ending and c.BlindK<.01 and(not c.FlashAt or os.clock()-c.FlashAt>1.4)then dropBlind(c)end
  end
 end)
end

function I.Collapse(E,d)
 local c=casts[d.Token]if not c then return end
 c.Locked=true
 c.Eye.CFrame=CFrame.new(d.Eye)
 local g=c.G
 local t0=os.clock()
 E.Step(g,function()
  local u=math.clamp((os.clock()-t0)/d.Time,0,1)
  c.Lid=u*u
  return u<1
 end)
 local shell=E.Anchor(g,CFrame.new(d.Eye))shell.Size=Vector3.one*90
 local inflow=E.Stream(shell,{tex="dot",orient="velocity",squash={{0,2.6},{1,.6}},size={{0,0},{.2,.8},{1,.2}},alpha={{0,1},{.2,0},{1,.2}},
  color={{0,IRIS},{1,WHITE}},life={1.2,1.4},speed={60,75},shape=Enum.ParticleEmitterShape.Sphere,
  inout=Enum.ParticleEmitterShapeInOut.Inward,style=Enum.ParticleEmitterShapeStyle.Surface},200)
 E.After(g,d.Time,function()inflow.Enabled=false end)
end

function I.Supernova(E,d)
 local c=casts[d.Token]
 local g=E.Group("IrisSupernova")
 if c then
  for _,L in ipairs(c.Layers)do L.E:Clear()end
  c.Light.Brightness=0
  c.Gone=true
  c.FlashAt=os.clock()
 end
 local a=E.Anchor(g,CFrame.new(d.Eye))
 E.Sprite(a,{tex="flare.big",size={{0,30},{.2,140},{1,170}},alpha={{0,0},{.35,.35},{1,1}},color=WHITE},.55)
 E.Sprite(a,{tex="burst.fringe",size={{0,30},{1,300}},alpha={{0,0},{.5,.15},{1,1}},color=IRIS,rot={0,360}},.6)
 E.Sprite(a,{tex="ring.crisp",size={{0,20},{1,280}},alpha={{0,0},{.6,.25},{1,1}},color=GOLD,rot={0,0}},.5)
 E.Sprite(a,{tex="flare.streak",size={{0,400},{1,440}},alpha={{0,0},{1,1}},color=IRIS,rot={0,0}},.5)
 E.Emit(a,{tex="dot",orient="velocity",squash={{0,2.8},{.6,1.2},{1,0}},size={{0,1.8},{1,0}},alpha={{0,0},{.75,0},{1,1}},
  color={{0,WHITE},{.4,GOLD},{1,IRIS}},life={.6,1},speed={100,180},spread=180,drag=2.5},130)
 E.Emit(a,{tex="star.twinkle",size={{0,2.4},{1,0}},life={1.2,2.2},speed={20,50},spread=180,drag=2,color={{0,WHITE},{1,IRIS}}},70)
 local ga=E.Anchor(g,CFrame.new(d.Center+Vector3.new(0,.5,0)))
 E.Light(g,a,IRIS,180,18,.9)
 E.After(g,2.4,function()g:Destroy()end)
end

function I.End(E,d)
 local c=casts[d.Token]
 if not c then return end
 casts[d.Token]=nil
 c.Ending=true
 E.After(c.G,1.6,function()dropBlind(c)c.G:Fade(.4)end)
end

return I
