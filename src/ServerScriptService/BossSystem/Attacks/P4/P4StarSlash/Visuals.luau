local B=script:FindFirstAncestor("BossSystem")
local Effects=require(B.Combat.EffectService)
local Style=require(script.Parent.Style)
local TweenService=game:GetService("TweenService")
local Debris=Effects
local Golden=require(B.Attacks.Shared.P4GoldenFX)
local LT=Golden.FX  
local V={}
local UP=Vector3.yAxis
local gold,white,hot,ember=Style.Gold,Style.White,Style.Hot,Style.Ember
local violet=Style.Violet or Color3.fromRGB(145,75,255)
local ES,ED=Enum.EasingStyle,Enum.EasingDirection

local TEX_SPARK="rbxasset://textures/particles/sparkles_main.dds"
local TEX_FIRE="rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE="rbxasset://textures/particles/smoke_main.dds"
local PPU=12

local function kp(t,v) return NumberSequenceKeypoint.new(t,v) end
local function ck(t,c) return ColorSequenceKeypoint.new(t,c) end
local FIRE_COLOR=ColorSequence.new({ck(0,white),ck(.25,gold),ck(.65,hot),ck(1,ember)})
local BIG_FIRE_COLOR=ColorSequence.new({ck(0,white),ck(.2,hot),ck(.6,ember),ck(1,Color3.fromRGB(110,18,10))})
local EMBER_COLOR=ColorSequence.new({ck(0,white),ck(.3,gold),ck(1,ember)})
local SMOKE_COLOR=ColorSequence.new(Color3.fromRGB(75,48,30),Color3.fromRGB(28,22,22))
local MIST_COLOR=ColorSequence.new(violet,Color3.fromRGB(36,20,60))
local SPARK_FADE=NumberSequence.new({kp(0,0),kp(.6,.15),kp(1,1)})
local FIRE_FADE=NumberSequence.new({kp(0,.1),kp(.55,.4),kp(1,1)})
local SMOKE_FADE=NumberSequence.new({kp(0,.6),kp(.25,.55),kp(1,1)})

local FX=setmetatable({},{__mode="k"})
local function part(core,...)
 local p=core.Part(...)
 FX[p]=nil
 return p
end

local function tween(inst,time,goal,style,dir,repeats,reverses,delay)
	Effects:Create(inst,TweenInfo.new(time,style or ES.Quad,dir or ED.Out,repeats or 0,reverses or false,delay or 0),goal):Play()
end

local function tweenRaw(inst,time,goal,style,dir,repeats,reverses,delay)
	TweenService:Create(inst,TweenInfo.new(time,style or ES.Quad,dir or ED.Out,repeats or 0,reverses or false,delay or 0),goal):Play()
end

 
local function later(cast,delay,fn)
	task.delay(delay,function()
		if cast:Alive() then fn() end
	end)
end

local function neon(p)
	p.Material=Enum.Material.Neon
	p.CastShadow=false
	return p
end

local function ball(core,cast,name,pos,size,color,alpha)
	local p=part(core,name,CFrame.new(pos),Vector3.one*size,color,alpha)
	pcall(function() p.Shape=Enum.PartType.Ball end)
	neon(p)
	cast:Add(p)
	return p
end

 
local function disc(core,cast,name,pos,diameter,thickness,color,alpha)
	local p=part(core,name,CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90)),Vector3.new(thickness,diameter,diameter),color,alpha)
	pcall(function() p.Shape=Enum.PartType.Cylinder end)
	neon(p)
	cast:Add(p)
	return p
end

local function surface(part,ppu)
	local g=Instance.new("SurfaceGui")
	g.Face=Enum.NormalId.Top
	g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud=ppu or PPU
	g.LightInfluence=0
	g.Brightness=1.5
	g.AlwaysOnTop=false
	pcall(function() g.MaxDistance=500 end)
	g.Parent=part
	return g
end

local function frame(parent,props)
	local f=Instance.new("Frame")
	f.BorderSizePixel=0
	f.BackgroundColor3=white
	f.BackgroundTransparency=1
	for k,v in pairs(props) do f[k]=v end
	f.Parent=parent
	return f
end
local function round(f) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(.5,0);c.Parent=f end
local function fade(f,seq,rotation)
	local g=Instance.new("UIGradient")
	g.Transparency=seq
	if rotation then g.Rotation=rotation end
	g.Parent=f
end

local function emitter(core,cast,name,cf,size,cfg)
	local life=cfg.life or .5
	local part=part(core,name,cf,size,gold,1)
	cast:Add(part)
	local e=Instance.new("ParticleEmitter")
	e.Texture=cfg.tex or TEX_SPARK
	e.Rate=0
	e.Enabled=false
	e.LightEmission=cfg.glow or 1
	e.LightInfluence=0
	e.Color=cfg.color or ColorSequence.new(white,gold)
	e.Size=cfg.sizeSeq or NumberSequence.new({kp(0,cfg.size or 1.2),kp(1,0)})
	e.Transparency=cfg.fade or SPARK_FADE
	e.Lifetime=NumberRange.new(life,life*1.6)
	local sp=cfg.speed or 16
	e.Speed=NumberRange.new(sp,sp*1.8)
	e.SpreadAngle=Vector2.new(cfg.spread or 30,cfg.spread or 30)
	e.Acceleration=cfg.accel or Vector3.new(0,-28,0)
	e.Drag=cfg.drag or 1.5
	e.Rotation=NumberRange.new(0,360)
	e.RotSpeed=NumberRange.new(-120,120)
	e.EmissionDirection=cfg.dir or Enum.NormalId.Top
	e.Parent=part
	e:Emit(cfg.count or 20)
	Debris:AddItem(part,life*1.6+.6)
	return e,part
end

local function flash(part,color,brightness,range,time)
	local l=Instance.new("PointLight")
	l.Color=color
	l.Brightness=brightness
	l.Range=math.min(range,60)
	l.Shadows=false
	l.Parent=part
	tweenRaw(l,time,{Brightness=0})
end

 
local function glint(core,cast,pos,size,color,life)
 LT.Glint(Golden.Context(core),cast,pos+UP*.4,color,math.min(size*.7,9),life)
end

 
 
 
 
local function fillT(alpha) return .35+.65*alpha end
local function spineT(alpha) return alpha*.6 end
local function spineColor(color) return color:Lerp(white,.55) end

local function apply(p,time,color,alpha,style,dir,repeats,reverses)
	local e=FX[p]
	if e and e.kind=="zone" then
		local fg,sg={BackgroundTransparency=fillT(alpha)},{BackgroundTransparency=spineT(alpha)}
		if color then fg.BackgroundColor3=color;sg.BackgroundColor3=spineColor(color) end
		if time>0 then
			tweenRaw(e.fill,time,fg,style,dir,repeats,reverses)
			tweenRaw(e.spine,time,sg,style,dir,repeats,reverses)
		else
			for k,v in pairs(fg) do e.fill[k]=v end
			for k,v in pairs(sg) do e.spine[k]=v end
		end
	elseif not e then
		local goal={Transparency=alpha}
		if color then goal.Color=color end
		if time>0 then tween(p,time,goal,style,dir,repeats,reverses)
		else for k,v in pairs(goal) do p[k]=v end end
	end
end

function V.Zone(core,cast,name,a,b,width)
	local length=(b-a).Magnitude
	local p=part(core,name,CFrame.lookAt((a+b)/2,b),Vector3.new(width,.08,math.max(.01,length+width)),gold,1)
	cast:Add(p)
	local sg=surface(p)
	local fill=frame(sg,{Size=UDim2.fromScale(1,1),BackgroundColor3=white,BackgroundTransparency=1})
	round(fill)
	fade(fill,NumberSequence.new({kp(0,.55),kp(.5,0),kp(1,.55)}))
	local spine=frame(sg,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.1,1),BackgroundColor3=white,BackgroundTransparency=1})
	fade(spine,NumberSequence.new({kp(0,1),kp(.1,.15),kp(.5,0),kp(.9,.15),kp(1,1)}),90)
	FX[p]={kind="zone",gui=sg,fill=fill,spine=spine}
	return p
end

 
function V.Reveal(core,cast,zone,a,b)
	local e=FX[zone]
	local mid=(a+b)*.5
	local length=(b-a).Magnitude
	if e then
		apply(zone,0,white,0)
		e.spine.Size=UDim2.fromScale(.8,1)
		tweenRaw(e.spine,.25,{Size=UDim2.fromScale(.1,1)},ES.Quint,ED.Out)
	end
	local plane=neon(part(core,"StarSlashCutPlane",CFrame.lookAt(mid+UP*5,b+UP*5),Vector3.new(.25,10,length),white,.05))
	cast:Add(plane)
	tween(plane,.3,{Size=Vector3.new(.03,13,length),Transparency=1},ES.Quad,ED.Out)
	Debris:AddItem(plane,.45)
	LT.Beam(Golden.Context(core),cast,a+UP*1.5,b+UP*1.5,2,gold,white,.25)
	local cf=CFrame.lookAt(mid+UP*.4,b+UP*.4)
	emitter(core,cast,"StarSlashCutSparks",cf,Vector3.new(Style.Width*.5,.4,length),{count=math.ceil(length*.9),speed=20,spread=28,life=.5,size=.9,accel=Vector3.new(0,-30,0)})
end

function V.Charge(parts,time,color,alpha)
	for _,p in ipairs(parts) do apply(p,time,color,alpha,ES.Quad,ED.In) end
end

function V.Relight(parts,color,alpha)
	for _,p in ipairs(parts) do apply(p,0,color,alpha) end
end

function V.Blink(parts,time,alpha)
	local pulses=3
	for _,p in ipairs(parts) do
		apply(p,time/(pulses*2),nil,alpha,ES.Sine,ED.InOut,pulses-1,true)
	end
end

function V.Release(parts,time)
	for _,p in ipairs(parts) do
		local e=FX[p]
		if e and e.gui then
			for _,d in ipairs(e.gui:GetDescendants()) do
				if d:IsA("GuiObject") then tweenRaw(d,time,{BackgroundTransparency=1}) end
			end
		else
			tween(p,time,{Transparency=1})
		end
	end
end

function V.Settle(parts,time)
	for _,p in ipairs(parts) do apply(p,time,ember,.78) end
end

 
 
 
function V.Line(core,cast,name,a,b,width,height,color,alpha)
	local length=(b-a).Magnitude
	local p=part(core,name,CFrame.lookAt((a+b)/2,b),Vector3.new(width,height,math.max(.01,length)),color or gold,alpha or .25)
	cast:Add(p)
	return p
end

function V.Cylinder(core,cast,name,base,radius,height,color,alpha)
	local p=part(core,name,CFrame.new(base+UP*height/2)*CFrame.Angles(0,0,math.rad(90)),Vector3.new(height,radius*2,radius*2),color or gold,alpha or .25)
	pcall(function() p.Shape=Enum.PartType.Cylinder end)
	cast:Add(p)
	return p
end

function V.Cap(core,cast,name,pos,radius,color,alpha)
	return V.Cylinder(core,cast,name,pos,radius,.1,color,alpha)
end

function V.Draw(core,cast,name,a,b,width,height,color,alpha,delay,time)
	local length=math.max(.01,(b-a).Magnitude)
	local p=part(core,name,CFrame.lookAt(a,b),Vector3.new(width,height,.01),color or white,alpha or .1)
	cast:Add(p)
	tween(p,time,{Size=Vector3.new(width,height,length),CFrame=CFrame.lookAt((a+b)/2,b)},ES.Linear,ED.Out,0,false,delay)
	return p
end

 
function V.Pulse(core,cast,center,d0,d1,time,color,alpha)
	local p=disc(core,cast,"StarSlashPulse",center+UP*.2,d0,.08,color,alpha or .3)
	tween(p,time,{Size=Vector3.new(.08,d1,d1)},ES.Quint,ED.Out)
	tween(p,time,{Transparency=1},ES.Quad,ED.In)
	Debris:AddItem(p,time+.1)
	return p
end

 
function V.Flare(core,cast,pos,height,color,time)
	local rot=CFrame.Angles(0,0,math.rad(90))
	local p=part(core,"StarSlashFlare",CFrame.new(pos+UP*height*.5)*rot,Vector3.new(height,3.2,3.2),color or white,.08)
	pcall(function() p.Shape=Enum.PartType.Cylinder end)
	neon(p)
	cast:Add(p)
	tween(p,time,{Size=Vector3.new(height*1.15,.15,.15),CFrame=CFrame.new(pos+UP*height*.575)*rot},ES.Quad,ED.Out)
	tween(p,time,{Transparency=1},ES.Quad,ED.In)
	Debris:AddItem(p,time+.1)
	return p
end

 
 
 
function V.Gather(core,cast,pos,time)
 glint(core,cast,pos+UP*.25,15,white,time)
 local orb=ball(core,cast,"StarSlashGatherOrb",pos+UP*3,10,gold,.8)
 tween(orb,time,{Size=Vector3.one*1.4,Transparency=.05},ES.Cubic,ED.In)
 Debris:AddItem(orb,time+.08)
  
 local ctx=Golden.Context(core)
 local host=LT.Anchor(ctx,cast,pos+UP*3,time+.3)
 host.Size=Vector3.one*26
 local inhale=LT.Emitter(host,{
  Color=ColorSequence.new(white,gold),Size=LT.Keyed({0,.2},{.6,.6},{1,.15}),Transparency=LT.Keyed({0,1},{.3,.1},{1,0}),
  Lifetime=NumberRange.new(.4),Speed=NumberRange.new(-30),Shape=Enum.ParticleEmitterShape.Sphere,
  ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,Rate=120,
 })
 later(cast,time,function() inhale.Enabled=false end)
 LT.Ring(ctx,cast,CFrame.new(pos+UP*.3)*CFrame.Angles(math.pi/2,0,0),24,3,time,gold,.15,.6)
 local _,anchor=emitter(core,cast,"StarSlashGatherSparks",CFrame.new(pos+UP*2),Vector3.new(5,3,5),{count=26,speed=11,spread=180,life=.5,size=.7,accel=Vector3.new(0,8,0)})
 flash(anchor,gold,2.5,20,time)
end

function V.Trail(core)
 local root=core.Root
 local objects={}
 local specs={
  {1.9,-1.3,white,violet,.2,-.6},
  {1.2,-.8,gold,hot,.3,.6},
  {2.5,-1.9,violet,Color3.fromRGB(40,15,90),.4,0},
 }
 for _,spec in ipairs(specs) do
  local a0,a1=Instance.new("Attachment"),Instance.new("Attachment")
  a0.Name="StarSlashTrailTop";a1.Name="StarSlashTrailBottom"
  a0.Position=Vector3.new(spec[6],spec[1],0)
  a1.Position=Vector3.new(spec[6],spec[2],0)
  a0.Parent=root;a1.Parent=root
  local trail=Instance.new("Trail")
  trail.Name="StarSlashTrail";trail.Attachment0=a0;trail.Attachment1=a1
  trail.Lifetime=spec[5];trail.MinLength=.15;trail.FaceCamera=true
  trail.LightEmission=1;trail.LightInfluence=0
  trail.Color=ColorSequence.new(spec[3],spec[4])
  trail.Transparency=NumberSequence.new({kp(0,.12),kp(.35,.4),kp(1,1)})
  trail.WidthScale=NumberSequence.new({kp(0,1),kp(1,0)})
  trail.Parent=root
  table.insert(objects,{trail,a0,a1})
 end
 local sparks=Instance.new("ParticleEmitter")
 sparks.Name="StarSlashDashSparks"
 sparks.Texture=TEX_SPARK
 sparks.Rate=90
 sparks.LightEmission=1
 sparks.LightInfluence=0
 sparks.Color=ColorSequence.new(white,gold)
 sparks.Size=NumberSequence.new({kp(0,.9),kp(1,0)})
 sparks.Transparency=SPARK_FADE
 sparks.Lifetime=NumberRange.new(.3,.55)
 sparks.Speed=NumberRange.new(4,14)
 sparks.SpreadAngle=Vector2.new(180,180)
 sparks.Acceleration=Vector3.new(0,-14,0)
 sparks.Drag=2
 sparks.Rotation=NumberRange.new(0,360)
 sparks.Parent=root
 table.insert(objects,{sparks})
 local stopped=false
 return function()
  if stopped then return end stopped=true
  for _,group in ipairs(objects) do group[1].Enabled=false;for _,item in ipairs(group) do Debris:AddItem(item,.7) end end
 end
end

 
function V.Landing(core,cast,pos,dir)
 glint(core,cast,pos+UP*.28,10,white,.3)
 V.Pulse(core,cast,pos,3,15,.3,violet,.3)
 V.Flare(core,cast,pos,Style.Height*1.05,gold,.32)
	local fwd=Vector3.new(dir.X,0,dir.Z)
	fwd=fwd.Magnitude>.01 and fwd.Unit or Vector3.zAxis
	local _,anchor=emitter(core,cast,"StarSlashLandSparks",CFrame.new(pos+UP),Vector3.new(2,1,2),{count=34,speed=28,spread=65,life=.55,size=1.2,accel=Vector3.new(0,-45,0)})
	emitter(core,cast,"StarSlashLandDust",CFrame.new(pos+UP*.6),Vector3.new(3,.5,3),{tex=TEX_SMOKE,count=8,speed=7,spread=80,life=.9,glow=0,color=SMOKE_COLOR,fade=SMOKE_FADE,
		sizeSeq=NumberSequence.new({kp(0,3),kp(1,8)}),accel=Vector3.new(0,2,0),drag=2})
	flash(anchor,gold,5,26,.45)
	 
	local cutFrame=CFrame.lookAt(pos+UP*3.5,pos+UP*3.5+fwd)*CFrame.Angles(0,0,math.pi/2)
	LT.Crescent(Golden.Context(core),cast,cutFrame,8,math.rad(150),1.8,gold,white,.22,{Wipe=.05,Grow=1.15})
end

 
 
 
local function blades(core,cast,a,b,big)
  
 local ctx=Golden.Context(core)
 local color=big and hot or gold
 local length=(b-a).Magnitude
 local steps=math.clamp(math.floor(length/9),3,6)
 for i=0,steps do
  local pos=a:Lerp(b,i/steps)
  later(cast,i*.03,function()
   LT.Spikes(ctx,cast,pos,4,big and 2.6 or 2,Style.Height*(big and .9 or .7),color,white,.55)
  end)
 end
 LT.Beam(ctx,cast,a+UP*.4,b+UP*.4,big and 2.6 or 1.8,color,white,.4)
 local host=LT.Anchor(ctx,cast,CFrame.lookAt((a+b)*.5+UP*.5,b+UP*.5),1.6)
 host.Size=Vector3.new(1.5,.2,length)
 LT.Emitter(host,{
  Color=ColorSequence.new(white,color),Size=LT.Keyed({0,.5},{1,0}),Transparency=LT.Keyed({0,0},{.7,.2},{1,1}),
  Lifetime=NumberRange.new(.7,1.2),Speed=NumberRange.new(Style.Height*.6,Style.Height*1.1),SpreadAngle=Vector2.new(10,10),
  EmissionDirection=Enum.NormalId.Top,Drag=2,Acceleration=Vector3.new(0,-4,0),
 }):Emit(math.ceil(length*(big and 2 or 1.3)))
end

function V.Erupt(core,cast,a,b,big)
 local length=(b-a).Magnitude
 local mid=(a+b)*.5
 local tint=big and hot or gold
 local H=Style.Height*(big and 1.2 or 1)
 local cf=CFrame.lookAt(mid+UP*.5,b+UP*.5)
 local sheet=neon(part(core,"StarSlashCore",cf,Vector3.new(.35,.5,length),white,.05))
 cast:Add(sheet)
 tween(sheet,.1,{Size=Vector3.new(.2,H,length),CFrame=CFrame.lookAt(mid+UP*H*.5,b+UP*H*.5)})
 tween(sheet,.25,{Transparency=1},nil,nil,0,false,.1)
 Debris:AddItem(sheet,.45)
 local strip=neon(part(core,"StarSlashFlash",CFrame.lookAt(mid+UP*.25,b+UP*.25),Vector3.new(Style.Width,.1,length+Style.Width),white,.1))
 cast:Add(strip)
 tween(strip,.32,{Size=Vector3.new(Style.Width*1.7,.1,length+Style.Width*1.7),Transparency=1},ES.Quad,ED.Out)
 Debris:AddItem(strip,.45)
 blades(core,cast,a,b,big)
 glint(core,cast,a+UP*.25,11,white,.3)
 glint(core,cast,b+UP*.25,11,white,.3)
 local box=Vector3.new(Style.Width*.65,.4,length)
 local _,anchor=emitter(core,cast,"StarSlashAstralSparks",cf,box,{count=math.ceil(length*(big and 1.5 or 1)),speed=big and 38 or 28,spread=12,life=.7,size=.9,accel=Vector3.new(0,-18,0),color=ColorSequence.new(white,tint)})
 flash(anchor,tint,big and 5 or 3.5,26,.4)
 emitter(core,cast,"StarSlashAstralFire",cf,box,{tex=TEX_FIRE,count=math.ceil(length*(big and .9 or .45)),speed=big and 30 or 20,spread=10,life=.6,
  color=FIRE_COLOR,fade=FIRE_FADE,sizeSeq=NumberSequence.new({kp(0,2.2),kp(.4,5),kp(1,1)}),accel=Vector3.new(0,16,0),drag=1.5})
 emitter(core,cast,"StarSlashAstralMist",cf,box,{tex=TEX_SMOKE,count=math.ceil(length*.18),speed=7,spread=12,life=.8,glow=.3,color=MIST_COLOR,fade=SMOKE_FADE,sizeSeq=NumberSequence.new({kp(0,2),kp(1,6)}),accel=Vector3.new(0,5,0),drag=2})
end

 
 
 

 
 
function V.BlastCharge(core,cast,center,radius,time)
	local list={}
	local zone=disc(core,cast,"StarSlashBlastZone",center+UP*.14,radius*2,.05,ember,.93)
	tween(zone,time,{Transparency=.78},ES.Linear)
	table.insert(list,zone)
	local fill=disc(core,cast,"StarSlashBlastFill",center+UP*.18,1,.06,gold,.8)
	tween(fill,time,{Size=Vector3.new(.06,radius*2,radius*2)},ES.Linear)
	tween(fill,time,{Color=ember,Transparency=.45},ES.Quad,ED.In)
	table.insert(list,fill)
	local orb=ball(core,cast,"StarSlashBlastOrb",center+UP*3,1.5,white,.4)
	tween(orb,time,{Size=Vector3.one*radius*.5,Transparency=.05},ES.Quint,ED.In)
	table.insert(list,orb)
	return list
end

 
function V.Implode(core,cast,points,center,time)
	local waves=3
	for w=0,waves-1 do
		later(cast,w*time/waves,function()
			local ctx=Golden.Context(core)
			for i,p in ipairs(points) do
				LT.Beam(ctx,cast,p+UP*(1+w*.8),center+UP*3,1.1,i%2==0 and white or gold,white,.28)
			end
			emitter(core,cast,"StarSlashImplodeSparks",CFrame.new(center+UP*3),Vector3.new(4,4,4),{count=14,speed=10,spread=180,life=.35,size=.8,accel=Vector3.zero,drag=3})
		end)
	end
end

function V.Detonate(core,cast,center,radius,snap,points)
	local H=Style.Height
	local ground=center+UP*.15
	local mid=center+UP*3

	 
	local lamp=part(core,"StarSlashBlastLight",CFrame.new(mid),Vector3.one,white,1)
	cast:Add(lamp)
	flash(lamp,white,16,60,.9)
	Debris:AddItem(lamp,1.1)

	 
	for _,l in ipairs({{white,0,radius*1.8,.28,.4},{hot,.2,radius*2.4,.4,.55},{ember,.45,radius*3,.55,.7}}) do
		local b=ball(core,cast,"StarSlashBlastFireball",mid,3,l[1],l[2])
		tween(b,l[4],{Size=Vector3.one*l[3]},ES.Quint,ED.Out)
		tween(b,l[5],{Transparency=1},ES.Quad,ED.In)
		Debris:AddItem(b,l[5]+.1)
	end

	 
	V.Pulse(core,cast,ground,radius*.8,radius*4.2,.6,white,.25)
	V.Pulse(core,cast,ground+UP*.02,radius*.6,radius*5,.9,hot,.55)

	 
	local rot=CFrame.Angles(0,0,math.rad(90))
	for _,l in ipairs({{radius*1.5,radius*.2,H*4,.7,white,.1},{radius*.7,radius*.1,H*4.5,.55,Color3.new(1,1,1),0}}) do
		local p=part(core,"StarSlashBlastPillar",CFrame.new(center+UP*l[3]*.5)*rot,Vector3.new(l[3],l[1],l[1]),l[5],l[6])
		pcall(function() p.Shape=Enum.PartType.Cylinder end)
		neon(p)
		cast:Add(p)
		tween(p,l[4],{Size=Vector3.new(l[3]*1.1,l[2],l[2]),CFrame=CFrame.new(center+UP*l[3]*.55)*rot},ES.Quint,ED.Out)
		tween(p,l[4],{Transparency=1},ES.Quad,ED.In)
		Debris:AddItem(p,l[4]+.1)
	end

	 
	 
	local ctx=Golden.Context(core)
	LT.Shockwave(ctx,cast,CFrame.new(ground+UP*.1),radius,radius*5.5,.7,gold,.05)
	LT.Shockwave(ctx,cast,CFrame.new(ground+UP*.12),radius*.5,radius*3.2,.5,white,.1)
	for i=1,4 do
		later(cast,i*.05,function()
			LT.Ring(ctx,cast,CFrame.new(ground+UP*(i*H*.35))*CFrame.Angles(math.pi/2,0,i*.7),radius*.8,radius*(2.6-i*.3),.45,i%2==0 and white or gold,0,1.2-i*.15)
		end)
	end
	for arm=0,2 do
		later(cast,arm*.04,function()
			local spinFrame=CFrame.new(ground+UP*(1.5+arm*1.6))*CFrame.Angles(0,arm*math.pi*2/3,0)*CFrame.Angles(0,0,math.rad(arm*8-8))
			LT.Crescent(ctx,cast,spinFrame,radius*(1.1+arm*.35),math.rad(150),2.6,arm==1 and hot or gold,white,.45,{Wipe=.1,Grow=1.6})
		end)
	end

	 
	local _,fireAnchor=emitter(core,cast,"StarSlashBlastFire",CFrame.new(center+UP*.6),Vector3.new(radius*1.1,.5,radius*1.1),{tex=TEX_FIRE,count=140,speed=56,spread=10,life=.95,
		accel=Vector3.new(0,22,0),drag=1,color=BIG_FIRE_COLOR,fade=FIRE_FADE,sizeSeq=NumberSequence.new({kp(0,5),kp(.4,14),kp(1,3)})})
	flash(fireAnchor,ember,10,60,.8)
	emitter(core,cast,"StarSlashBlastSparks",CFrame.new(center+UP),Vector3.new(radius,1,radius),{count=120,speed=40,spread=45,life=1,size=1.5,accel=Vector3.new(0,-34,0)})
	emitter(core,cast,"StarSlashBlastDebris",CFrame.new(center+UP),Vector3.new(radius,1,radius),{count=50,speed=30,spread=70,life=1.4,size=.9,accel=Vector3.new(0,-12,0),color=EMBER_COLOR})
	emitter(core,cast,"StarSlashBlastSmoke",CFrame.new(center+UP),Vector3.new(radius,1,radius),{tex=TEX_SMOKE,count=26,speed=12,spread=30,life=1.7,glow=0,color=SMOKE_COLOR,fade=SMOKE_FADE,
		sizeSeq=NumberSequence.new({kp(0,5),kp(1,16)}),accel=Vector3.new(0,6,0),drag=1.5})
	emitter(core,cast,"StarSlashBlastMist",CFrame.new(center+UP),Vector3.new(radius*1.4,1,radius*1.4),{tex=TEX_SMOKE,count=20,speed=14,spread=60,life=1.2,glow=.4,color=MIST_COLOR,fade=SMOKE_FADE,
		sizeSeq=NumberSequence.new({kp(0,4),kp(1,12)}),accel=Vector3.new(0,4,0),drag=2})
	for i=1,16 do
		local ang=i/16*math.pi*2
		local dir=Vector3.new(math.cos(ang),0,math.sin(ang))
		local pos=center+dir*radius*.8+UP*.6
		emitter(core,cast,"StarSlashBlastBurst",CFrame.lookAt(pos,pos+dir),Vector3.new(1.5,1,1.5),{tex=TEX_FIRE,count=8,speed=38,spread=16,life=.55,
			dir=Enum.NormalId.Front,accel=Vector3.new(0,6,0),drag=2,color=FIRE_COLOR,fade=FIRE_FADE,sizeSeq=NumberSequence.new({kp(0,2.5),kp(.4,5),kp(1,1)})})
	end

	 
	local rising=emitter(core,cast,"StarSlashBlastEmbers",CFrame.new(center+UP*.8),Vector3.new(radius*1.6,.5,radius*1.6),{count=0,speed=5,spread=25,life=1,size=.7,
		accel=Vector3.new(0,8,0),drag=1,color=EMBER_COLOR})
	rising.Rate=36
	rising.Enabled=true
	 
	task.delay(.6,function() if rising.Parent then rising.Enabled=false end end)
	local scorch=disc(core,cast,"StarSlashScorch",ground+UP*.02,radius*1.7,.04,Color3.fromRGB(14,9,8),.3)
	scorch.Material=Enum.Material.SmoothPlastic
	tween(scorch,2.2,{Transparency=1},ES.Linear)
	Debris:AddItem(scorch,2.4)

	 
	glint(core,cast,ground+UP*.3,radius*2.6,white,.5)
	if points then
		for _,p in ipairs(points) do V.Flare(core,cast,p,H*1.4,hot,.45) end
	end
end

return V
