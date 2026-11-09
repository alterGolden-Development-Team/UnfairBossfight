local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local FX=require(script.Parent.FX)

local Weapons={}
local W={}
W.__index=W

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

local function attach(part,pos)
 local a=Instance.new("Attachment")
 a.Position=pos
 a.Parent=part
 return a
end

local function trail(model,a0,a1,color,transparency,life)
 local t=Instance.new("Trail")
 t.Attachment0=a0;t.Attachment1=a1
 t.Color=color;t.Transparency=transparency
 t.Lifetime=life;t.LightEmission=1;t.LightInfluence=0
 t.FaceCamera=true;t.MinLength=.05;t.Enabled=false
 t.Parent=model
 return t
end

local function light(part,color,range,brightness)
 local l=Instance.new("PointLight")
 l.Color=color;l.Range=range;l.Brightness=brightness;l.Shadows=false
 l.Parent=part
end

local ROT_Z=CFrame.Angles(0,math.pi/2,0)  

 
local BUILD={}

function BUILD.Sword(model,S,P)
 local C=S.Colors
 local L,W0,T=10.6,2.2,.42
 local bz=-4.4-L/2
 local blade=piece(model,"Blade",Vector3.new(W0,T,L),CFrame.new(0,0,bz),C.Steel,METAL)
 local z=-4.4-L
 for i,st in ipairs({{1.7,.9},{1.1,.9},{.6,.8}}) do
  piece(model,"Tip"..i,Vector3.new(st[1],T,st[2]),CFrame.new(0,0,z-st[2]/2),C.Steel,METAL)
  z-=st[2]
 end
 piece(model,"EdgeL",Vector3.new(.2,T+.1,L),CFrame.new(W0/2-.1,0,bz),P.Color,NEON,.1)
 piece(model,"EdgeR",Vector3.new(.2,T+.1,L),CFrame.new(-W0/2+.1,0,bz),P.Color,NEON,.1)
 piece(model,"Fuller",Vector3.new(.4,T+.12,L*.85),CFrame.new(0,0,bz),P.Core,NEON,.05)
 piece(model,"Guard",Vector3.new(6.2,.9,1.2),CFrame.new(0,0,-4),C.Gold,METAL)
 for _,side in ipairs({1,-1}) do
  piece(model,"Horn"..side,Vector3.new(1.2,.8,1.8),CFrame.new(side*3.2,0,-4.9)*CFrame.Angles(0,math.rad(25)*side,0),C.Gold,METAL)
 end
 local gem=piece(model,"Gem",Vector3.one*1.1,CFrame.new(0,.55,-4),P.Color,NEON,0,Enum.PartType.Ball)
 piece(model,"Grip",Vector3.new(3.4,.75,.75),CFrame.new(0,0,-2.1)*ROT_Z,C.Dark,Enum.Material.Fabric,0,Enum.PartType.Cylinder)
 piece(model,"Pommel",Vector3.one*1.3,CFrame.new(0,0,-.2),C.Gold,METAL,0,Enum.PartType.Ball)
 light(gem,P.Color,16,1.5)
 return {
  trail(model,attach(blade,Vector3.new(0,0,-4.4-L-2.6-bz)),attach(blade,Vector3.new(0,0,-8-bz)),FX.Grad(P.Core,P.Color),FX.Seq(0,.4,1),.26),
  trail(model,attach(blade,Vector3.new(0,0,-4.4-L-2.6-bz)),attach(blade,Vector3.new(0,0,-13-bz)),FX.Grad(P.Color,P.Color),FX.Seq(.4,.7,1),.38),
 }
end

function BUILD.Sickle(model,S,P)
 local C=S.Colors
 piece(model,"Shaft",Vector3.new(9,.9,.9),CFrame.new(0,0,-5)*ROT_Z,C.Dark,Enum.Material.Fabric,0,Enum.PartType.Cylinder)
 for i,gz in ipairs({-1.5,-5,-8.2}) do
  piece(model,"Wrap"..i,Vector3.new(.4,1.1,1.1),CFrame.new(0,0,gz)*ROT_Z,C.Gold,METAL,0,Enum.PartType.Cylinder)
 end
 piece(model,"Pommel",Vector3.one*1.3,CFrame.new(0,0,-.3),C.Gold,METAL,0,Enum.PartType.Ball)
 local collar=piece(model,"Collar",Vector3.one*1.6,CFrame.new(0,0,-10.2),P.Color,NEON,0,Enum.PartType.Ball)
  
 local R,segs,total=7,6,math.rad(115)
 local center=Vector3.new(R,0,-10.5)
 local segParts={}
 for i=1,segs do
  local th=total*(i-.5)/segs
  local pos=center+Vector3.new(-math.cos(th),0,-math.sin(th))*R
  local tangent=Vector3.new(math.sin(th),0,-math.cos(th))
  local w=1.7-1.35*(i-1)/(segs-1)
  local len=R*total/segs*1.25
  local cf=CFrame.lookAt(pos,pos+tangent)
  local seg=piece(model,"Seg"..i,Vector3.new(w,.38,len),cf,C.Steel,METAL)
  piece(model,"SegEdge"..i,Vector3.new(.2,.5,len),cf*CFrame.new(w/2-.1,0,0),P.Color,NEON,.1)
  piece(model,"SegCore"..i,Vector3.new(w*.35,.44,len*.9),cf,P.Core,NEON,.15)
  segParts[i]=seg
 end
 light(collar,P.Color,16,1.5)
 local last=segParts[segs]
 return {
  trail(model,attach(last,Vector3.new(0,0,-last.Size.Z/2)),attach(segParts[3],Vector3.new(segParts[3].Size.X/2,0,0)),FX.Grad(P.Core,P.Color),FX.Seq(0,.4,1),.28),
  trail(model,attach(last,Vector3.new(0,0,-last.Size.Z/2)),attach(segParts[1],Vector3.new(segParts[1].Size.X/2,0,0)),FX.Grad(P.Color,P.Color),FX.Seq(.4,.75,1),.4),
 }
end

function BUILD.Rapier(model,S,P)
 local C=S.Colors
 local L,W0,T=15,.95,.34
 local bz=-4.6-L/2
 local blade=piece(model,"Blade",Vector3.new(W0,T,L),CFrame.new(0,0,bz),C.Steel,METAL)
 local z=-4.6-L
 for i,st in ipairs({{.6,1.2},{.25,1.2}}) do
  piece(model,"Tip"..i,Vector3.new(st[1],T,st[2]),CFrame.new(0,0,z-st[2]/2),C.Steel,METAL)
  z-=st[2]
 end
 piece(model,"Edge",Vector3.new(.14,T+.1,L),CFrame.new(0,0,bz),P.Color,NEON,.1)
 piece(model,"Fuller",Vector3.new(.22,T+.14,L*.9),CFrame.new(0,0,bz),P.Core,NEON,.05)
 piece(model,"Cup",Vector3.new(.4,4.4,4.4),CFrame.new(0,0,-4.2)*ROT_Z,C.Gold,METAL,0,Enum.PartType.Cylinder)
 piece(model,"CupGlow",Vector3.new(.2,3.6,3.6),CFrame.new(0,0,-4.5)*ROT_Z,P.Color,NEON,.2,Enum.PartType.Cylinder)
 piece(model,"Quillon",Vector3.new(6.4,.45,.45),CFrame.new(0,0,-4.5),C.Gold,METAL)
 local gem=piece(model,"Gem",Vector3.one*1,CFrame.new(0,0,-4.6),P.Core,NEON,0,Enum.PartType.Ball)
 piece(model,"Grip",Vector3.new(3.4,.6,.6),CFrame.new(0,0,-2.4)*ROT_Z,C.Dark,Enum.Material.Fabric,0,Enum.PartType.Cylinder)
 piece(model,"Pommel",Vector3.one*1.2,CFrame.new(0,0,-.5),C.Gold,METAL,0,Enum.PartType.Ball)
 light(gem,P.Color,14,1.5)
 local tipZ=-4.6-L-2.4-bz
 return {
  trail(model,attach(blade,Vector3.new(0,0,tipZ)),attach(blade,Vector3.new(0,0,-10-bz)),FX.Grad(P.Core,P.Color),FX.Seq(0,.5,1),.2),
 }
end

function BUILD.Hammer(model,S,P)
 local C=S.Colors
 piece(model,"Handle",Vector3.new(14,1.1,1.1),CFrame.new(0,0,-8)*ROT_Z,C.Dark,Enum.Material.Fabric,0,Enum.PartType.Cylinder)
 for i,gz in ipairs({-2,-5,-8,-11}) do
  piece(model,"Wrap"..i,Vector3.new(.45,1.35,1.35),CFrame.new(0,0,gz)*ROT_Z,C.Gold,METAL,0,Enum.PartType.Cylinder)
 end
 piece(model,"Pommel",Vector3.one*1.8,CFrame.new(0,0,-.4),C.Gold,METAL,0,Enum.PartType.Ball)
 local hz=-15.8
 local head=piece(model,"Head",Vector3.new(10,6,6),CFrame.new(0,0,hz),Color3.fromRGB(70,74,92),METAL)
 for _,side in ipairs({1,-1}) do
  piece(model,"Band"..side,Vector3.new(1.2,6.4,6.4),CFrame.new(side*3.3,0,hz),C.Gold,METAL)
  piece(model,"Cap"..side,Vector3.new(.7,5,5),CFrame.new(side*5.2,0,hz)*CFrame.Angles(0,0,0),P.Color,NEON,.05,Enum.PartType.Cylinder)
  piece(model,"Spike"..side,Vector3.new(.9,.9,.9),CFrame.new(side*5.9,0,hz)*CFrame.Angles(0,math.rad(45),math.rad(45)),P.Core,NEON,0)
 end
 piece(model,"RuneTop",Vector3.new(4.6,.3,5.2),CFrame.new(0,3.05,hz),P.Color,NEON,.1)
 piece(model,"RuneBottom",Vector3.new(4.6,.3,5.2),CFrame.new(0,-3.05,hz),P.Color,NEON,.1)
 piece(model,"RuneFront",Vector3.new(4.6,5.2,.3),CFrame.new(0,0,hz-3.05),P.Core,NEON,.1)
 light(head,P.Color,26,2)
 return {
  trail(model,attach(head,Vector3.new(5,0,0)),attach(head,Vector3.new(-5,0,0)),FX.Grad(P.Core,P.Color),FX.Seq(.2,.5,1),.3),
  trail(model,attach(head,Vector3.new(0,3.2,0)),attach(head,Vector3.new(0,-3.2,0)),FX.Grad(P.Color,P.Color),FX.Seq(.35,.65,1),.38),
 }
end

function Weapons.new(kind,style)
 local build=BUILD[kind]
 if not build then return nil end
 local P=style.Palette[kind]
 local self=setmetatable({},W)
 local model=Instance.new("Model")
 model.Name="P1Weapon"..kind
 local pivot=piece(model,"Pivot",Vector3.one*.3,CFrame.new(),style.Colors.Dark,METAL,1)
 model.PrimaryPart=pivot
 self.Model=model
 self.Palette=P
 self.Trails=build(model,style,P)
 self.Original={}
 for _,d in ipairs(model:GetChildren()) do
  if d:IsA("BasePart") and d.Name~="Pivot" then
   self.Original[d]=d.Transparency
   d.Transparency=1
  end
 end
 model.Parent=workspace
 return self
end

function W:Update(cf) self.Model:PivotTo(cf) end

function W:Appear(time)
 for part,orig in pairs(self.Original) do
  Tween:Create(part,TweenInfo.new(time,Enum.EasingStyle.Quad),{Transparency=orig}):Play()
 end
end

function W:SetTrails(on)
 for _,t in ipairs(self.Trails) do
  if on then t:Clear() end
  t.Enabled=on
 end
end

function W:Ghost(color,time)
 local group=Instance.new("Folder")
 group.Parent=workspace
 for part,orig in pairs(self.Original) do
  if orig<.9 and part.Name~="Pivot" then
   local g=Instance.new("Part")
   g.Anchored=true;g.CanCollide=false;g.CanQuery=false;g.CanTouch=false;g.CastShadow=false
   g.Size=part.Size;g.CFrame=part.CFrame;g.Color=color;g.Material=NEON;g.Transparency=.55
   g.Parent=group
   Tween:Create(g,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=1}):Play()
  end
 end
 Debris:AddItem(group,time+.15)
end

 
function W:Remove()
 self:SetTrails(false)
 for part in pairs(self.Original) do
  Tween:Create(part,TweenInfo.new(.15),{Transparency=1}):Play()
 end
 Debris:AddItem(self.Model,.25)
end

function W:Destroy() self.Model:Destroy() end

return Weapons