local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local FX=require(script.Parent.Visuals)

local Sword={}
Sword.__index=Sword

local METAL,NEON=Enum.Material.Metal,Enum.Material.Neon

local function piece(model,name,size,cf,color,material,transparency,shape)
 local p=Instance.new("Part")
 p.Name=name
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true
 p.Size=size;p.Color=color;p.Material=material;p.Transparency=transparency or 0
 if shape then p.Shape=shape end
 p.CFrame=cf
 p.Parent=model
 return p
end

 
function Sword.new(style)
 local C=style.Colors
 local self=setmetatable({},Sword)
 local model=Instance.new("Model")
 model.Name="P1Greatsword"
 local pivot=piece(model,"Pivot",Vector3.one*.3,CFrame.new(),C.Dark,METAL,1)
 model.PrimaryPart=pivot
 self.Model=model

 local L,W,T=19.5,3.6,.55
 local bladeZ=-7-L/2
 local blade=piece(model,"Blade",Vector3.new(W,T,L),CFrame.new(0,0,bladeZ),C.Steel,METAL)
 local z=-7-L
 for i,step in ipairs({{2.8,1.2},{2,1.2},{1.2,1.2},{.5,1}}) do
  piece(model,"Tip"..i,Vector3.new(step[1],T,step[2]),CFrame.new(0,0,z-step[2]/2),C.Steel,METAL)
  piece(model,"TipEdge"..i,Vector3.new(step[1]+.25,T-.1,step[2]*.9),CFrame.new(0,0,z-step[2]/2),C.Aura,NEON,.25)
  z-=step[2]
 end
 self.Edges={
  piece(model,"EdgeL",Vector3.new(.24,T+.12,L),CFrame.new(W/2-.12,0,bladeZ),C.Aura,NEON,.1),
  piece(model,"EdgeR",Vector3.new(.24,T+.12,L),CFrame.new(-W/2+.12,0,bladeZ),C.Aura,NEON,.1),
 }
 self.Fuller=piece(model,"Fuller",Vector3.new(.55,T+.14,L*.85),CFrame.new(0,0,bladeZ),C.Hot,NEON,.05)
 for i=0,3 do
  piece(model,"Rune"..i,Vector3.new(1.4,T+.2,.3),CFrame.new(0,0,-9.5-i*3.8),C.Core,NEON,.15)
 end
  
 piece(model,"Guard",Vector3.new(10.5,1.2,1.7),CFrame.new(0,0,-6.4),C.Gold,METAL)
 for _,side in ipairs({1,-1}) do
  piece(model,"Horn"..side,Vector3.new(2,1,3),CFrame.new(side*5.4,0,-7.7)*CFrame.Angles(0,math.rad(25)*side,0),C.Gold,METAL)
  piece(model,"HornGlow"..side,Vector3.new(.5,1.1,2.4),CFrame.new(side*5.5,0,-7.8)*CFrame.Angles(0,math.rad(25)*side,0),C.Hot,NEON,.2)
 end
 local gem=piece(model,"Gem",Vector3.one*1.7,CFrame.new(0,.8,-6.4),C.Hot,NEON,0,Enum.PartType.Ball)
 piece(model,"GemBottom",Vector3.one*1.7,CFrame.new(0,-.8,-6.4),C.Hot,NEON,0,Enum.PartType.Ball)
  
 piece(model,"Grip",Vector3.new(5.5,1,1),CFrame.new(0,0,-3.25)*CFrame.Angles(0,math.pi/2,0),C.Dark,Enum.Material.Fabric,0,Enum.PartType.Cylinder)
 for i,gz in ipairs({-1.4,-3.25,-5.1}) do
  piece(model,"Wrap"..i,Vector3.new(.4,1.15,1.15),CFrame.new(0,0,gz)*CFrame.Angles(0,math.pi/2,0),C.Gold,METAL,0,Enum.PartType.Cylinder)
 end
 piece(model,"Pommel",Vector3.one*2,CFrame.new(0,0,-.2),C.Gold,METAL,0,Enum.PartType.Ball)
 piece(model,"PommelCore",Vector3.one*1,CFrame.new(0,0,.4),C.Core,NEON,0,Enum.PartType.Ball)

  
 local light=Instance.new("PointLight")
 light.Color=C.Aura;light.Range=20;light.Brightness=.8;light.Shadows=false
 light.Parent=gem
 self.Light=light

  
 local carrier=piece(model,"EmberCarrier",Vector3.new(W,T,L+4.6),CFrame.new(0,0,-7-(L+4.6)/2),C.Hot,NEON,1)
 self.Embers=FX.Emitter(carrier,{Texture=FX.Tex.Spark,Color=FX.Grad(C.Core,C.Aura,C.Hot),Size=FX.Seq(1.1,.6,0),
  Lifetime=NumberRange.new(.35,.8),Speed=NumberRange.new(3,14),Accel=Vector3.new(0,12,0),Shape=Enum.ParticleEmitterShape.Box,
  ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume})
 self.Embers.Rate=18;self.Embers.Enabled=true
 local gather=piece(model,"GatherCarrier",Vector3.one*17,CFrame.new(0,0,-17),C.Hot,NEON,1,Enum.PartType.Ball)
 self.GatherEmitter=FX.Emitter(gather,{Texture=FX.Tex.Spark,Color=FX.Grad(C.Aura,C.Core),Size=FX.Seq(.2,1.5,.2),
  Transparency=FX.Seq(.2,0,.4),Lifetime=NumberRange.new(.4,.55),Speed=NumberRange.new(14,18),Shape=Enum.ParticleEmitterShape.Sphere,
  ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,InOut=Enum.ParticleEmitterShapeInOut.Inward,Enabled=true})
 self.Flames=FX.Emitter(carrier,{Texture=FX.Tex.Fire,Color=FX.Grad(C.Core,C.Hot,Color3.fromRGB(70,20,10)),Size=FX.Seq(2.2,3,0),
  Transparency=FX.Seq(.3,.6,1),Lifetime=NumberRange.new(.25,.5),Speed=NumberRange.new(1,5),Accel=Vector3.new(0,6,0),
  Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Enabled=true})

  
 local function attach(zAbs,y)
  local a=Instance.new("Attachment")
  a.Position=Vector3.new(0,y or 0,zAbs-bladeZ)
  a.Parent=blade
  return a
 end
 local function trail(a0,a1,color,transparency,life,light)
  local t=Instance.new("Trail")
  t.Attachment0=a0;t.Attachment1=a1
  t.Color=color;t.Transparency=transparency
  t.Lifetime=life;t.LightEmission=light or 1;t.LightInfluence=0
  t.FaceCamera=true;t.MinLength=.05;t.Enabled=false
  t.Parent=model
  return t
 end
 local tip,mid,low=attach(-31),attach(-19),attach(-9)
 self.Trails={
  trail(tip,low,FX.Grad(C.Hot,C.Aura,Color3.fromRGB(120,30,10)),FX.Seq(.45,.7,1),.38),
  trail(tip,mid,FX.Grad(C.Core,Color3.fromRGB(255,220,130)),FX.Seq(0,.35,1),.24),
  trail(attach(-31,.5),attach(-31,-.5),FX.Grad(C.Core,C.Core),FX.Seq(0,.4,1),.16),
 }

  
 self.Original={}
 for _,d in ipairs(model:GetChildren()) do
  if d:IsA("BasePart") and d.Name~="Pivot" then
   self.Original[d]=d.Transparency
   d.Transparency=1
  end
 end
 self.Hot=0
 model.Parent=workspace
 return self
end

function Sword:Update(cf)
 self.Model:PivotTo(cf)
end

function Sword:Appear(time)
 for part,orig in pairs(self.Original) do
  Tween:Create(part,TweenInfo.new(time,Enum.EasingStyle.Quad),{Transparency=orig}):Play()
 end
end

function Sword:SetTrails(on)
 for _,t in ipairs(self.Trails) do
  if on then t:Clear() end
  t.Enabled=on
 end
end

function Sword:SetSwing(on)
 self.Embers.Rate=on and 160 or 18
 self.Flames.Rate=on and 45 or 0
end

function Sword:SetCharge(rate)
 self.GatherEmitter.Rate=rate
end

 
function Sword:Heat(amount,time)
 local info=TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 local hot=amount>0
 for _,edge in ipairs(self.Edges) do
  Tween:Create(edge,info,{Color=hot and Color3.fromRGB(255,235,190) or Color3.fromRGB(255,160,60)}):Play()
 end
 Tween:Create(self.Fuller,info,{Color=hot and Color3.fromRGB(255,244,215) or Color3.fromRGB(255,110,30)}):Play()
 Tween:Create(self.Light,info,{Brightness=hot and 6 or .8,Range=hot and 34 or 20}):Play()
end

 
function Sword:Ghost(color,time)
 local group=Instance.new("Folder")
 group.Parent=workspace
 for _,name in ipairs({"Blade","Tip1","Tip2","Tip3","Tip4","EdgeL","EdgeR","Guard"}) do
  local src=self.Model:FindFirstChild(name)
  if src then
   local g=Instance.new("Part")
   g.Anchored=true;g.CanCollide=false;g.CanQuery=false;g.CanTouch=false;g.CastShadow=false
   g.Size=src.Size;g.CFrame=src.CFrame;g.Color=color;g.Material=NEON;g.Transparency=.5
   g.Parent=group
   Tween:Create(g,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=1}):Play()
  end
 end
 Debris:AddItem(group,time+.15)
end

function Sword:Destroy()
 self.Model:Destroy()
end

return Sword