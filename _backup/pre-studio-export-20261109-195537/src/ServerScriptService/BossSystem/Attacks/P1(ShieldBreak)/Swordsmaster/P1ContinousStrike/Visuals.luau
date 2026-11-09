local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local Run=game:GetService("RunService")

local FX={}
local TEX={
 Spark="rbxasset://textures/particles/sparkles_main.dds",
 Smoke="rbxasset://textures/particles/smoke_main.dds",
 Fire="rbxasset://textures/particles/fire_main.dds",
}
FX.Tex=TEX

function FX.Grad(...)
 local list={...}
 local keys={}
 for i,color in ipairs(list) do keys[i]=ColorSequenceKeypoint.new((i-1)/(#list-1),color) end
 return ColorSequence.new(keys)
end
function FX.Seq(...)
 local list={...}
 local keys={}
 for i,v in ipairs(list) do keys[i]=NumberSequenceKeypoint.new((i-1)/(#list-1),v) end
 return NumberSequence.new(keys)
end
local Grad,Seq=FX.Grad,FX.Seq

local function rand() return math.random()-.5 end

function FX.Part(size,color,cf,shape,transparency)
 local p=Instance.new("Part")
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Material=Enum.Material.Neon
 if shape then p.Shape=shape end
 p.Size=size;p.Color=color;p.CFrame=cf;p.Transparency=transparency or 0
 p.Parent=workspace
 return p
end

function FX.Fade(inst,time,goal,style,dir)
 goal.Transparency=1
 Tween:Create(inst,TweenInfo.new(time,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),goal):Play()
 Debris:AddItem(inst,time+.15)
end

function FX.Ground(pos,ignore)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local list={}
 if ignore then table.insert(list,ignore) end
 for _,pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(list,pl.Character) end end
 params.FilterDescendantsInstances=list
 local hit=workspace:Raycast(pos+Vector3.new(0,6,0),Vector3.new(0,-80,0),params)
 if hit then return hit.Position+Vector3.new(0,.2,0) end
 return pos-Vector3.new(0,3,0)
end

 
local function ringPart(cf,diameter,color,stroke)
 local p=Instance.new("Part")
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Transparency=1
 p.Size=Vector3.new(diameter,.1,diameter)
 p.CFrame=cf
 local gui=Instance.new("SurfaceGui")
 gui.Face=Enum.NormalId.Top
 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
 gui.CanvasSize=Vector2.new(512,512)
 gui.LightInfluence=0
 gui.Brightness=3
 gui.Parent=p
 local frame=Instance.new("Frame")
 frame.AnchorPoint=Vector2.new(.5,.5)
 frame.Position=UDim2.fromScale(.5,.5)
 frame.Size=UDim2.fromScale(.94,.94)
 frame.BackgroundTransparency=1
 frame.Parent=gui
 local corner=Instance.new("UICorner")
 corner.CornerRadius=UDim.new(.5,0)
 corner.Parent=frame
 local line=Instance.new("UIStroke")
 line.Color=color;line.Thickness=stroke;line.Transparency=0
 line.Parent=frame
 p.Parent=workspace
 return p,line
end

 
function FX.GroundRing(pos,from,to,color,stroke,time,endStroke,style)
 local p,line=ringPart(CFrame.new(pos),from,color,stroke)
 local info=TweenInfo.new(time,style or Enum.EasingStyle.Cubic,Enum.EasingDirection.Out)
 Tween:Create(p,info,{Size=Vector3.new(to,.1,to)}):Play()
 Tween:Create(line,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1,Thickness=endStroke or stroke*.4}):Play()
 Debris:AddItem(p,time+.2)
 return p
end

 
function FX.FacingRing(pos,dir,from,to,color,stroke,time)
 local cf=CFrame.lookAt(pos,pos+dir)*CFrame.Angles(-math.pi/2,0,0)
 local p,line=ringPart(cf,from,color,stroke)
 Tween:Create(p,TweenInfo.new(time,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Size=Vector3.new(to,.1,to)}):Play()
 Tween:Create(line,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1,Thickness=stroke*.3}):Play()
 Debris:AddItem(p,time+.2)
end

local function emitterPart(cf,life)
 local p=Instance.new("Part")
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Transparency=1;p.Size=Vector3.one;p.CFrame=cf
 p.Parent=workspace
 Debris:AddItem(p,life or 2.5)
 return p
end
FX.EmitterPart=emitterPart

function FX.Emitter(parent,spec)
 local e=Instance.new("ParticleEmitter")
 e.Texture=spec.Texture or TEX.Spark
 e.Color=spec.Color
 e.Size=spec.Size
 e.Transparency=spec.Transparency or Seq(0,.3,1)
 e.Lifetime=spec.Lifetime or NumberRange.new(.3,.6)
 e.Speed=spec.Speed or NumberRange.new(10,20)
 e.SpreadAngle=spec.Spread or Vector2.new(180,180)
 e.Rate=spec.Rate or 0
 e.LightEmission=spec.Light or 1
 e.LightInfluence=0
 e.Drag=spec.Drag or 0
 e.Acceleration=spec.Accel or Vector3.zero
 e.Rotation=NumberRange.new(0,360)
 e.RotSpeed=spec.RotSpeed or NumberRange.new(-120,120)
 if spec.Direction then e.EmissionDirection=spec.Direction end
 if spec.Shape then e.Shape=spec.Shape end
 if spec.ShapeStyle then e.ShapeStyle=spec.ShapeStyle end
 if spec.InOut then e.ShapeInOut=spec.InOut end
 e.Enabled=spec.Enabled or false
 e.Parent=parent
 return e
end

 
function FX.Impact(pos,dir,heavy,color,core)
 if dir.Magnitude<.01 then dir=Vector3.yAxis end
 dir=dir.Unit
 local s=heavy and 1.7 or 1
 local orb=FX.Part(Vector3.one*3*s,core,CFrame.new(pos),Enum.PartType.Ball,0)
 FX.Fade(orb,.14,{Size=Vector3.one*15*s})
 local glow=FX.Part(Vector3.one*2*s,color,CFrame.new(pos),Enum.PartType.Ball,.4)
 FX.Fade(glow,.3,{Size=Vector3.one*26*s})
 FX.FacingRing(pos,dir,5*s,30*s,core,22,.28)
 FX.FacingRing(pos,dir,3*s,20*s,color,30,.2)
 for i=1,heavy and 12 or 7 do
  local d=(dir*.5+Vector3.new(rand(),rand()+.1,rand())*2).Unit
  local len=(5+math.random()*7)*s
  local streak=FX.Part(Vector3.new(.2*s,.2*s,len),i%2==0 and core or color,CFrame.lookAt(pos+d*2,pos+d*6),nil,0)
  local far=pos+d*(12+math.random()*16)*s
  Tween:Create(streak,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.lookAt(far,far+d),Size=Vector3.new(.04,.04,len*.2)}):Play()
  FX.Fade(streak,.22,{})
 end
 local ep=emitterPart(CFrame.new(pos),2.5)
 local sparks=FX.Emitter(ep,{Texture=TEX.Spark,Color=Grad(core,color,Color3.fromRGB(110,35,10)),Size=Seq(1.8*s,1*s,0),
  Lifetime=NumberRange.new(.3,.7),Speed=NumberRange.new(25*s,75*s),Drag=3,Accel=Vector3.new(0,-50,0)})
 local fire=FX.Emitter(ep,{Texture=TEX.Fire,Color=Grad(core,color,Color3.fromRGB(60,20,10)),Size=Seq(3*s,7*s,0),
  Transparency=Seq(0,.5,1),Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(4,12)})
 local smoke=FX.Emitter(ep,{Texture=TEX.Smoke,Color=Grad(Color3.fromRGB(95,85,75),Color3.fromRGB(35,32,30)),Size=Seq(3*s,10*s),
  Transparency=Seq(.45,.8,1),Lifetime=NumberRange.new(.6,1.1),Speed=NumberRange.new(3,12),Light=0,Accel=Vector3.new(0,4,0)})
 sparks:Emit(heavy and 45 or 22)
 fire:Emit(heavy and 8 or 4)
 smoke:Emit(heavy and 10 or 5)
end

function FX.Telegraph(pos,radius,time,color)
 local fill=FX.Part(Vector3.new(.1,2,2),color,CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder,.92)
 Tween:Create(fill,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=Vector3.new(.1,radius*2,radius*2),Transparency=.72}):Play()
 Debris:AddItem(fill,time+.1)
 local edge=ringPart(CFrame.new(pos+Vector3.new(0,.05,0)),radius*2,color,14)
 Debris:AddItem(edge,time+.1)
 for i=0,2 do
  task.delay(time*i*.28,function()
   FX.GroundRing(pos+Vector3.new(0,.1,0),radius*2,radius*.25,color,10,time*.45,4,Enum.EasingStyle.Quad)
  end)
 end
end

function FX.Pillar(pos,radius,height,color,time)
 local p=FX.Part(Vector3.new(height,radius*2,radius*2),color,CFrame.new(pos+Vector3.new(0,height/2,0))*CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder,.3)
 FX.Fade(p,time,{Size=Vector3.new(height*1.3,.5,.5)},Enum.EasingStyle.Quint)
end

function FX.Shockwave(pos,radius,color,core)
 FX.GroundRing(pos,8,radius*2,color,30,.6,6)
 FX.GroundRing(pos+Vector3.new(0,.05,0),4,radius*1.3,core,24,.45,4)
 FX.GroundRing(pos+Vector3.new(0,.1,0),2,radius*.7,color,20,.35,4)
 FX.Pillar(pos,5,48,color,.5)
 FX.Pillar(pos,2.5,70,core,.35)
 local orb=FX.Part(Vector3.one*6,core,CFrame.new(pos+Vector3.new(0,3,0)),Enum.PartType.Ball,0)
 FX.Fade(orb,.3,{Size=Vector3.one*34})
  
 for i=1,16 do
  local ang=i/16*math.pi*2
  local out=Vector3.new(math.cos(ang),0,math.sin(ang))
  local ep=emitterPart(CFrame.lookAt(pos+out*3,pos+out*10),2.5)
  local dust=FX.Emitter(ep,{Texture=TEX.Smoke,Color=Grad(Color3.fromRGB(165,148,125),Color3.fromRGB(95,85,75)),
   Size=Seq(5,16),Transparency=Seq(.4,.75,1),Lifetime=NumberRange.new(.8,1.4),Speed=NumberRange.new(30,55),
   Drag=3,Light=0,Spread=Vector2.new(18,10),Direction=Enum.NormalId.Front,Accel=Vector3.new(0,3,0)})
  dust:Emit(4)
  local fire=FX.Emitter(ep,{Texture=TEX.Fire,Color=Grad(core,color,Color3.fromRGB(60,20,10)),Size=Seq(4,0),
   Lifetime=NumberRange.new(.25,.45),Speed=NumberRange.new(25,50),Drag=2,Spread=Vector2.new(15,8),Direction=Enum.NormalId.Front})
  fire:Emit(2)
 end
  
 local rocks={}
 for i=1,16 do
  local ang=i/16*math.pi*2+math.random()*.3
  local out=Vector3.new(math.cos(ang),0,math.sin(ang))
  local r=Instance.new("Part")
  r.Anchored=true;r.CanCollide=false;r.CanQuery=false;r.CanTouch=false
  r.Size=Vector3.new(1.2+math.random()*2,1+math.random()*2,1.2+math.random()*2)
  r.Material=Enum.Material.Slate;r.Color=Color3.fromRGB(80,72,68)
  local start=pos+out*(radius*(.2+math.random()*.5))
  r.CFrame=CFrame.new(start)
  r.Parent=workspace
  Debris:AddItem(r,1.5)
  rocks[i]={part=r,start=start,vel=out*(10+math.random()*14)+Vector3.new(0,28+math.random()*22,0),spin=Vector3.new(rand(),rand(),rand())*8}
 end
 local t0=os.clock()
 local conn
 conn=Run.Heartbeat:Connect(function()
  local t=os.clock()-t0
  for _,rk in ipairs(rocks) do
   if rk.part.Parent then
    rk.part.CFrame=CFrame.new(rk.start+rk.vel*t-Vector3.new(0,.5*85*t*t,0))*CFrame.Angles(rk.spin.X*t,rk.spin.Y*t,rk.spin.Z*t)
   end
  end
  if t>.9 then
   conn:Disconnect()
   for _,rk in ipairs(rocks) do rk.part:Destroy() end
  end
 end)
end

 
local shakes={}
local shaking=false
local function shakeLoop()
 shaking=true
 local bases={}
 while #shakes>0 do
  Run.Heartbeat:Wait()
  local now=os.clock()
  for i=#shakes,1,-1 do
   if now-shakes[i].t0>=shakes[i].dur then table.remove(shakes,i) end
  end
  for _,pl in ipairs(Players:GetPlayers()) do
   local ch=pl.Character
   local hum=ch and ch:FindFirstChildOfClass("Humanoid")
   local root=ch and ch:FindFirstChild("HumanoidRootPart")
   if hum and root then
    local power=0
    for _,s in ipairs(shakes) do
     local dist=(root.Position-s.origin).Magnitude
     if dist<=s.radius then
      local fall=(1-(now-s.t0)/s.dur)^2
      power+=s.mag*fall*(1-.7*dist/s.radius)
     end
    end
    if power>0 then
     if bases[hum]==nil then bases[hum]=hum.CameraOffset end
     hum.CameraOffset=bases[hum]+Vector3.new(rand(),rand(),rand())*2*power
    end
   end
  end
 end
 for hum,base in pairs(bases) do
  if hum.Parent then hum.CameraOffset=base end
 end
 shaking=false
end
function FX.Shake(origin,magnitude,duration,radius)
 table.insert(shakes,{origin=origin,mag=magnitude,dur=duration,radius=radius or 90,t0=os.clock()})
 if not shaking then task.spawn(shakeLoop) end
end

 
function FX.Flash(color,strength,time)
 local cc=Instance.new("ColorCorrectionEffect")
 cc.Brightness=strength*.2;cc.Contrast=strength*.4;cc.Saturation=-strength*.25;cc.TintColor=color
 cc.Parent=Lighting
 local bloom=Instance.new("BloomEffect")
 bloom.Intensity=strength*1.4;bloom.Size=40;bloom.Threshold=.75
 bloom.Parent=Lighting
 local info=TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 Tween:Create(cc,info,{Brightness=0,Contrast=0,Saturation=0,TintColor=Color3.new(1,1,1)}):Play()
 Tween:Create(bloom,info,{Intensity=0}):Play()
 Debris:AddItem(cc,time+.3)
 Debris:AddItem(bloom,time+.3)
end

return FX