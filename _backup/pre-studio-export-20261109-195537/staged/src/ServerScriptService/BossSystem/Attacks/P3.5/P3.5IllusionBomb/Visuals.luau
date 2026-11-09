 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")

local VFX={}

 
 
 

local CFG={
	Quality=1,         
	Lean=false,        
	Smoke=true,        
	ScorchSeconds=2,   
	FinaleSpread=70,   
}

 
 
local TEX={
	Soft="rbxasset://textures/particles/smoke_main.dds",      
	Spark="rbxasset://textures/particles/sparkles_main.dds",  
}

local UP=Vector3.yAxis
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
local PINK=Color3.fromRGB(255,170,230)
local SKY=Color3.fromRGB(140,210,255)
local FLAT=CFrame.Angles(0,0,math.rad(90))  
local RING_FILL=.9  
local QUAD,CUBIC,SINE,LINEAR,EXPO=Enum.EasingStyle.Quad,Enum.EasingStyle.Cubic,Enum.EasingStyle.Sine,Enum.EasingStyle.Linear,Enum.EasingStyle.Exponential
local OUT,IN,INOUT=Enum.EasingDirection.Out,Enum.EasingDirection.In,Enum.EasingDirection.InOut

 
 
 

local function N(count)
	return math.max(1,math.floor(count*CFG.Quality+.5))
end

 
local function nseq(...)
	local keys={}
	for _,k in ipairs({...}) do keys[#keys+1]=NumberSequenceKeypoint.new(k[1],k[2]) end
	return NumberSequence.new(keys)
end
local function cseq(...)
	local keys={}
	for _,k in ipairs({...}) do keys[#keys+1]=ColorSequenceKeypoint.new(k[1],k[2]) end
	return ColorSequence.new(keys)
end

local function holder(parent)
	return typeof(parent)=="Instance" and parent or workspace
end

 
local function bundle(parent,seconds)
	local folder=Instance.new("Folder")
	folder.Name="IllusionVFX"
	folder.Parent=holder(parent)
	Debris:AddItem(folder,seconds)
	return folder
end

local function tween(inst,time,goal,style,direction)
	local t=TweenService:Create(inst,TweenInfo.new(time,style or QUAD,direction or OUT),goal)
	t:Play()
	return t
end

local function newPart(name)
	local p=Instance.new("Part")
	p.Name=name
	p.Anchored=true
	p.CanCollide=false
	p.CanQuery=false
	p.CanTouch=false
	p.CastShadow=false
	p.Massless=true
	p.Material=Enum.Material.Neon
	return p
end

 
local function disc(parent,position,diameter,thickness,color,transparency)
	local p=newPart("IllusionDisc")
	p.Shape=Enum.PartType.Cylinder
	p.Size=Vector3.new(thickness,diameter,diameter)
	p.CFrame=CFrame.new(position)*FLAT
	p.Color=color
	p.Transparency=transparency
	p.Parent=holder(parent)
	return p
end

 
local function column(parent,position,diameter,height,color,transparency)
	local p=newPart("IllusionColumn")
	p.Shape=Enum.PartType.Cylinder
	p.Size=Vector3.new(height,diameter,diameter)
	p.CFrame=CFrame.new(position+UP*height/2)*FLAT
	p.Color=color
	p.Transparency=transparency
	p.Parent=holder(parent)
	return p
end

local function ball(parent,position,diameter,color,transparency)
	local p=newPart("IllusionBall")
	p.Shape=Enum.PartType.Ball
	p.Size=Vector3.one*diameter
	p.Position=position
	p.Color=color
	p.Transparency=transparency
	p.Parent=holder(parent)
	return p
end

 
local function host(parent,position,size)
	local p=newPart("IllusionHost")
	p.Material=Enum.Material.SmoothPlastic
	p.Transparency=1
	p.Size=size or Vector3.one
	p.CFrame=CFrame.new(position)
	p.Parent=holder(parent)
	return p
end

local function emitter(parent,props)
	local e=Instance.new("ParticleEmitter")
	e.Enabled=false
	e.Rate=0
	e.Texture=TEX.Spark
	e.LightEmission=1
	e.LightInfluence=0
	e.Lifetime=NumberRange.new(.4,.7)
	e.Speed=NumberRange.new(10,20)
	e.SpreadAngle=Vector2.new(180,180)
	e.Size=NumberSequence.new(1,0)
	e.Transparency=nseq({0,0},{.65,.2},{1,1})
	for key,value in pairs(props) do e[key]=value end
	e.Parent=parent
	return e
end

 
local function burst(parent,count,props)
	emitter(parent,props):Emit(N(count))
end

local function flashLight(parent,color,range,brightness,seconds)
	local l=Instance.new("PointLight")
	l.Color=color
	l.Range=range
	l.Brightness=brightness
	l.Shadows=false
	l.Parent=parent
	tween(l,seconds,{Brightness=0},QUAD)
	return l
end

 
 
local function ringSize(diameter)
	local s=diameter/RING_FILL
	return Vector3.new(s,.1,s)
end

local function ring(parent,position,diameter,color,thickness,transparency)
	local plate=newPart("IllusionRing")
	plate.Material=Enum.Material.SmoothPlastic
	plate.Transparency=1
	plate.Size=ringSize(diameter)
	plate.CFrame=CFrame.new(position)
	plate.Parent=holder(parent)

	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Top
	gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize=Vector2.new(512,512)
	gui.LightInfluence=0
	gui.Brightness=3
	gui.Parent=plate

	local circle=Instance.new("Frame")
	circle.BackgroundTransparency=1
	circle.AnchorPoint=Vector2.new(.5,.5)
	circle.Position=UDim2.fromScale(.5,.5)
	circle.Size=UDim2.fromScale(RING_FILL,RING_FILL)
	circle.Parent=gui

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(.5,0)
	corner.Parent=circle

	local stroke=Instance.new("UIStroke")
	stroke.Thickness=thickness
	stroke.Color=color
	stroke.Transparency=transparency or 0
	stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	stroke.Parent=circle
	return plate,stroke
end

 
local function scorch(parent,position,diameter,color,brightness)
	local plate=newPart("IllusionScorch")
	plate.Material=Enum.Material.SmoothPlastic
	plate.Transparency=1
	plate.Size=Vector3.new(diameter,.1,diameter)
	plate.CFrame=CFrame.new(position)
	plate.Parent=holder(parent)

	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Top
	gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize=Vector2.new(256,256)
	gui.LightInfluence=0
	gui.Brightness=brightness
	gui.Parent=plate

	local group=Instance.new("CanvasGroup")
	group.BackgroundTransparency=1
	group.Size=UDim2.fromScale(1,1)
	group.Parent=gui

	for i=1,5 do
		local scale=1-(i-1)*.17
		local f=Instance.new("Frame")
		f.AnchorPoint=Vector2.new(.5,.5)
		f.Position=UDim2.fromScale(.5,.5)
		f.Size=UDim2.fromScale(scale,scale)
		f.BackgroundColor3=color
		f.BackgroundTransparency=.8
		f.BorderSizePixel=0
		local corner=Instance.new("UICorner")
		corner.CornerRadius=UDim.new(.5,0)
		corner.Parent=f
		f.Parent=group
	end
	return group
end

 
local function ping(parent,position,color,from,to,seconds)
	local anchor=host(parent,position,Vector3.one*.2)

	local gui=Instance.new("BillboardGui")
	gui.Size=UDim2.fromScale(from,from)
	gui.AlwaysOnTop=true
	gui.LightInfluence=0
	gui.Adornee=anchor
	gui.Parent=anchor

	local circle=Instance.new("Frame")
	circle.BackgroundTransparency=1
	circle.AnchorPoint=Vector2.new(.5,.5)
	circle.Position=UDim2.fromScale(.5,.5)
	circle.Size=UDim2.fromScale(.92,.92)
	circle.Parent=gui

	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(.5,0)
	corner.Parent=circle

	local stroke=Instance.new("UIStroke")
	stroke.Thickness=5
	stroke.Color=color
	stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	stroke.Parent=circle

	tween(gui,seconds,{Size=UDim2.fromScale(to,to)},EXPO)
	tween(stroke,seconds,{Transparency=1,Thickness=1},QUAD,IN)
end

local function weldTo(arm,part,offset,parent)
	part.CFrame=arm.CFrame*offset
	part.Anchored=false
	part.Parent=holder(parent)
	local weld=Instance.new("Weld")
	weld.Part0=arm
	weld.Part1=part
	weld.C0=offset
	weld.Parent=part
end

 
 
 

function VFX.Ground(position,ignore)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	local list={}
	for _,item in ipairs(ignore or {}) do
		if typeof(item)=="Instance" then list[#list+1]=item end
	end
	params.FilterDescendantsInstances=list
	local hit=workspace:Raycast(position+UP*2,Vector3.new(0,-80,0),params)
	return hit and hit.Position or position-Vector3.new(0,3,0)
end

 
 
 
 

function VFX.HandOrb(parent,arm,color,accent,windup)
	if not (arm and arm.Parent) then return nil end
	local offset=CFrame.new(0,-1.1,0)

	local orb=newPart("IllusionOrb")
	orb.Shape=Enum.PartType.Ball
	orb.Size=Vector3.one*.5
	orb.Color=color:Lerp(WHITE,.45)
	weldTo(arm,orb,offset,parent)

	local shell=newPart("IllusionOrbShell")
	shell.Shape=Enum.PartType.Ball
	shell.Size=Vector3.one*.9
	shell.Color=color
	shell.Transparency=.55
	weldTo(arm,shell,offset,parent)

	local field=newPart("IllusionOrbField")
	field.Material=Enum.Material.SmoothPlastic
	field.Transparency=1
	field.Size=Vector3.one*6
	weldTo(arm,field,offset,parent)

	local light=Instance.new("PointLight")
	light.Color=color
	light.Range=16
	light.Brightness=1
	light.Parent=orb

	 
	local gather=emitter(field,{
		Shape=Enum.ParticleEmitterShape.Sphere,
		ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward,
		Rate=70,Enabled=true,
		Lifetime=NumberRange.new(.3,.45),
		Speed=NumberRange.new(9,13),
		Size=NumberSequence.new(.55,.1),
		Color=ColorSequence.new(accent,color),
	})
	local burstEmitter=emitter(orb,{
		Lifetime=NumberRange.new(.25,.5),
		Speed=NumberRange.new(14,26),
		Size=NumberSequence.new(.8,0),
		Color=ColorSequence.new(WHITE,color),
	})

	tween(orb,windup,{Size=Vector3.one*2.2})
	tween(shell,windup,{Size=Vector3.one*3.6})
	tween(light,windup,{Brightness=5})

	local object={}
	local dead=false

	task.delay(windup,function()
		if dead then return end
		gather.Enabled=false
		tween(orb,.15,{Size=Vector3.one*1.5})
		tween(shell,.15,{Size=Vector3.one*2.4})
		tween(light,.15,{Brightness=2.5})
	end)

	function object:Pulse()
		if dead then return end
		burstEmitter:Emit(N(10))
		light.Brightness=8
		tween(light,.25,{Brightness=2.5})
		orb.Size=Vector3.one*2.7
		shell.Size=Vector3.one*4.2
		tween(orb,.2,{Size=Vector3.one*1.5})
		tween(shell,.2,{Size=Vector3.one*2.4})
	end

	function object:Fade()
		if dead then return end
		gather.Enabled=false
		tween(orb,.25,{Size=Vector3.one*.1})
		tween(shell,.25,{Size=Vector3.one*.1,Transparency=1})
		tween(light,.25,{Brightness=0})
		task.delay(.35,function() object:Destroy() end)
	end

	function object:Destroy()
		dead=true
		orb:Destroy()
		shell:Destroy()
		field:Destroy()
	end

	return object
end

 
 
 

function VFX.Sigil(parent,position,diameter,duration,color,accent)
	local plate=newPart("IllusionSigil")
	plate.Material=Enum.Material.SmoothPlastic
	plate.Transparency=1
	plate.Size=Vector3.new(diameter,.2,diameter)
	plate.CFrame=CFrame.new(position+UP*.12)
	plate.Parent=holder(parent)

	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Top
	gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize=Vector2.new(512,512)
	gui.LightInfluence=0
	gui.Brightness=2
	gui.Parent=plate

	local function frame(parentGui,scale,rotation)
		local f=Instance.new("Frame")
		f.BackgroundTransparency=1
		f.AnchorPoint=Vector2.new(.5,.5)
		f.Position=UDim2.fromScale(.5,.5)
		f.Size=UDim2.fromScale(scale,scale)
		f.Rotation=rotation
		f.Parent=parentGui
		return f
	end
	local function outline(f,thickness,strokeColor,round)
		if round then
			local corner=Instance.new("UICorner")
			corner.CornerRadius=UDim.new(.5,0)
			corner.Parent=f
		end
		local stroke=Instance.new("UIStroke")
		stroke.Thickness=thickness
		stroke.Color=strokeColor
		stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
		stroke.Parent=f
	end

	local group=Instance.new("CanvasGroup")
	group.BackgroundTransparency=1
	group.AnchorPoint=Vector2.new(.5,.5)
	group.Position=UDim2.fromScale(.5,.5)
	group.Size=UDim2.fromScale(1,1)
	group.GroupTransparency=1
	group.Parent=gui

	outline(frame(group,.98,0),8,color,true)
	outline(frame(group,.9,0),3,accent,true)

	local spinA=frame(group,1,0)  
	outline(frame(spinA,.62,0),5,color,false)
	outline(frame(spinA,.62,45),5,color,false)

	local spinB=frame(group,1,0)  
	outline(frame(spinB,.42,0),4,accent,true)
	outline(frame(spinB,.26,45),4,accent,false)

	tween(group,.35,{GroupTransparency=.15})
	TweenService:Create(group,TweenInfo.new(.45,QUAD,IN,0,false,math.max(duration-.45,0)),{GroupTransparency=1}):Play()
	TweenService:Create(spinA,TweenInfo.new(duration,LINEAR),{Rotation=360*math.max(duration/7,.25)}):Play()
	TweenService:Create(spinB,TweenInfo.new(duration,LINEAR),{Rotation=-360*math.max(duration/5,.25)}):Play()

	 
	emitter(plate,{
		Rate=22,Enabled=true,
		Shape=Enum.ParticleEmitterShape.Disc,
		ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
		Lifetime=NumberRange.new(1,1.6),
		Speed=NumberRange.new(3,8),
		SpreadAngle=Vector2.new(12,12),
		Acceleration=Vector3.new(0,5,0),
		Size=NumberSequence.new(.55,0),
		Color=ColorSequence.new(accent,color),
	})

	Debris:AddItem(plate,duration+.6)
	local object={}
	function object:Destroy() plate:Destroy() end
	return object
end

 
 
 
 
 

function VFX.Telegraph(parent,point,radius,flight,isReal,strength,palette)
	local tint=palette.Neutral:Lerp(isReal and palette.Real or palette.Fake,strength)
	local root=bundle(parent,flight+3)

	 
	local _,edge=ring(root,point+UP*.18,radius*2,tint:Lerp(WHITE,.2),18,.25)

	local fill=disc(root,point+UP*.12,.8,.1,tint,.62)
	local growth=tween(fill,flight,{Size=Vector3.new(.1,radius*2,radius*2)},LINEAR)

	local core=disc(root,point+UP*.16,radius*1.1,.1,tint:Lerp(WHITE,.35),.85)
	local period=.42+(isReal and -.18 or .2)*math.min(strength*2.5,1)
	local pulse=TweenService:Create(core,TweenInfo.new(period,SINE,INOUT,-1,true),{Transparency=isReal and .45 or .93})
	pulse:Play()

	local object={}
	function object:LockIn()
		growth:Cancel()
		pulse:Cancel()
		fill.Size=Vector3.new(.1,radius*2,radius*2)
		fill.Transparency=.25
		core.Transparency=.3
		tween(fill,.2,{Transparency=1})
		tween(core,.2,{Transparency=1})
		 
		edge.Color=WHITE
		edge.Transparency=0
		edge.Thickness=34
		tween(edge,.28,{Transparency=1,Thickness=6})
		Debris:AddItem(root,.5)
	end
	function object:Destroy()
		growth:Cancel()
		pulse:Cancel()
		root:Destroy()
	end
	return object
end

 
 
 
 

function VFX.Trail(parent,startPosition,color,accent)
	local tail=host(parent,startPosition,Vector3.one*.3)
	Debris:AddItem(tail,10)  

	local function ribbon(half,life,colors,startTransparency)
		local top=Instance.new("Attachment")
		top.Position=Vector3.new(0,half,0)
		top.Parent=tail
		local bottom=Instance.new("Attachment")
		bottom.Position=Vector3.new(0,-half,0)
		bottom.Parent=tail

		local t=Instance.new("Trail")
		t.Attachment0=top
		t.Attachment1=bottom
		t.Lifetime=life
		t.FaceCamera=true
		t.LightEmission=1
		t.LightInfluence=0
		t.Color=colors
		t.Transparency=nseq({0,startTransparency},{1,1})
		t.WidthScale=nseq({0,1},{1,0})
		t.Parent=tail
	end
	ribbon(1.4,.45,ColorSequence.new(color,accent),.25)  
	ribbon(.5,.28,ColorSequence.new(WHITE,accent),0)     

	 
	emitter(tail,{
		Texture=TEX.Soft,
		Rate=26,Enabled=true,
		SpreadAngle=Vector2.new(0,0),
		Lifetime=NumberRange.new(.25,.4),
		Speed=NumberRange.new(0,1),
		Size=nseq({0,3.2},{1,.6}),
		Transparency=nseq({0,.55},{1,1}),
		Color=ColorSequence.new(color),
	})

	emitter(tail,{
		Rate=45,Enabled=true,
		Lifetime=NumberRange.new(.35,.6),
		Speed=NumberRange.new(1,4),
		Size=NumberSequence.new(.7,0),
		Color=ColorSequence.new(accent,color),
	})

	local object={Part=tail}
	function object:Destroy() tail:Destroy() end
	return object
end

 
 
 

 
 
function VFX.RealImpact(parent,point,radius,color,accent)
	local hot=color:Lerp(WHITE,.45)
	local ember=color:Lerp(accent,.5)
	local dark=color:Lerp(BLACK,.82)
	local root=bundle(parent,math.max(CFG.ScorchSeconds,2)+.8)

	 
	local flash=ball(root,point+UP*radius*.25,radius*.5,WHITE,0)
	tween(flash,.16,{Size=Vector3.one*radius*1.5,Transparency=1},EXPO)
	local fire=ball(root,point+UP*radius*.3,radius*.7,hot,.2)
	tween(fire,.4,{Size=Vector3.one*radius*1.9,Transparency=1},CUBIC)

	 
	local wave,waveStroke=ring(root,point+UP*.22,radius*.5,hot,26,0)
	tween(wave,.45,{Size=ringSize(radius*2)},EXPO)
	tween(waveStroke,.5,{Transparency=1},QUAD,IN)
	if not CFG.Lean then
		local echo,echoStroke=ring(root,point+UP*.26,radius*.3,accent,14,.15)
		tween(echo,.7,{Size=ringSize(radius*2)},CUBIC)
		tween(echoStroke,.7,{Transparency=1},QUAD,IN)
	end

	 
	local pillar=column(root,point,radius*.85,110,hot,.25)
	tween(pillar,.5,{Size=Vector3.new(110,radius*.12,radius*.12),Transparency=1},CUBIC)
	if not CFG.Lean then
		local spear=column(root,point,radius*.3,110,WHITE,0)
		tween(spear,.25,{Size=Vector3.new(110,.1,.1),Transparency=1},QUAD)
	end


	local source=host(root,point+UP*1.5,Vector3.new(radius*.8,.4,radius*.8))
	flashLight(source,hot,radius*4,12,.45)

	 
	burst(source,12,{
		Texture=TEX.Soft,
		Lifetime=NumberRange.new(.35,.6),
		Speed=NumberRange.new(4,16),
		Size=nseq({0,radius*.3},{1,radius*.8}),
		Transparency=nseq({0,.15},{.5,.4},{1,1}),
		Color=cseq({0,WHITE},{.25,hot},{1,color}),
		Rotation=NumberRange.new(0,360),
		RotSpeed=NumberRange.new(-90,90),
	})

	 
	burst(source,34,{
		SpreadAngle=Vector2.new(50,50),
		Lifetime=NumberRange.new(.45,.9),
		Speed=NumberRange.new(30,62),
		Acceleration=Vector3.new(0,-75,0),
		Size=nseq({0,1},{1,0}),
		Color=cseq({0,WHITE},{.4,hot},{1,accent}),
		Rotation=NumberRange.new(0,360),
		RotSpeed=NumberRange.new(-240,240),
	})

	 
	burst(source,8,{
		Texture=TEX.Soft,
		SpreadAngle=Vector2.new(65,65),
		Lifetime=NumberRange.new(.6,1),
		Speed=NumberRange.new(16,34),
		Acceleration=Vector3.new(0,-60,0),
		Size=nseq({0,2.4},{1,0}),
		Color=cseq({0,hot},{1,color}),
		Rotation=NumberRange.new(0,360),
		RotSpeed=NumberRange.new(-120,120),
	})

	 
	burst(source,14,{
		SpreadAngle=Vector2.new(70,70),
		Lifetime=NumberRange.new(1.1,2),
		Speed=NumberRange.new(8,22),
		Acceleration=Vector3.new(0,8,0),
		Drag=1.6,
		Size=nseq({0,.7},{1,0}),
		Transparency=nseq({0,0},{.7,.2},{1,1}),
		Color=ColorSequence.new(accent,color),
	})

	if CFG.Smoke then
		 
		burst(source,10,{
			Texture=TEX.Soft,
			LightEmission=0,
			SpreadAngle=Vector2.new(60,60),
			Lifetime=NumberRange.new(1,1.6),
			Speed=NumberRange.new(3,11),
			Acceleration=Vector3.new(0,5,0),
			Drag=2.2,
			Size=nseq({0,radius*.3},{1,radius*.95}),
			Transparency=nseq({0,1},{.12,.45},{.6,.7},{1,1}),
			Color=ColorSequence.new(dark:Lerp(color,.3),dark),
			Rotation=NumberRange.new(0,360),
			RotSpeed=NumberRange.new(-35,35),
		})

		 
		local dust=host(root,point+UP*.6,Vector3.new(radius*.7,.4,radius*.7))
		burst(dust,18,{
			Texture=TEX.Soft,
			LightEmission=0,
			Shape=Enum.ParticleEmitterShape.Disc,
			ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,
			ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,
			SpreadAngle=Vector2.new(0,0),
			Lifetime=NumberRange.new(.55,.9),
			Speed=NumberRange.new(radius*1.4,radius*2.4),
			Drag=1.5,
			Size=nseq({0,radius*.2},{1,radius*.6}),
			Transparency=nseq({0,.4},{1,1}),
			Color=ColorSequence.new(color:Lerp(BLACK,.55):Lerp(WHITE,.15)),
			Rotation=NumberRange.new(0,360),
			RotSpeed=NumberRange.new(-60,60),
		})
	end
end

 
function VFX.FakeImpact(parent,point,radius,color,accent)
	local pale=color:Lerp(WHITE,.5)
	local root=bundle(parent,2.6)

	 
	local bubble=ball(root,point+UP*radius*.3,radius*.4,pale,.45)
	tween(bubble,.32,{Size=Vector3.one*radius*1.5,Transparency=1},QUAD)

	 
	local wave,waveStroke=ring(root,point+UP*.22,radius*.4,color,12,.15)
	tween(wave,.6,{Size=ringSize(radius*2)},QUAD)
	tween(waveStroke,.6,{Transparency=1},QUAD,IN)

	local source=host(root,point+UP*.8,Vector3.new(radius*.8,.4,radius*.8))
	flashLight(source,color,radius*2,3,.4)

	 
	burst(source,6,{
		Texture=TEX.Soft,
		LightEmission=.6,
		Lifetime=NumberRange.new(.5,.8),
		Speed=NumberRange.new(4,10),
		Size=nseq({0,2},{1,radius*.7}),
		Transparency=nseq({0,.5},{1,1}),
		Color=ColorSequence.new(pale),
		Rotation=NumberRange.new(0,360),
		RotSpeed=NumberRange.new(-60,60),
	})

	 
	for _,c in ipairs({color,accent,PINK,SKY}) do
		burst(source,7,{
			SpreadAngle=Vector2.new(75,75),
			Lifetime=NumberRange.new(1,1.7),
			Speed=NumberRange.new(10,26),
			Acceleration=Vector3.new(0,-14,0),
			Drag=1.5,
			Rotation=NumberRange.new(0,360),
			RotSpeed=NumberRange.new(-200,200),
			Size=nseq({0,1.1},{1,.2}),
			Color=ColorSequence.new(c),
		})
	end

	 
	burst(source,14,{
		Lifetime=NumberRange.new(1.2,2),
		Speed=NumberRange.new(2,7),
		Acceleration=Vector3.new(0,5,0),
		Drag=1,
		Size=nseq({0,.6},{.5,.9},{1,0}),
		Color=ColorSequence.new(WHITE,pale),
	})
end

 
function VFX.Hit(parent,part,color,accent)
	if not (part and part.Parent) then return end
	local root=bundle(parent,1.6)
	local position=part.Position

	local pop=ball(root,position,2.5,WHITE,.1)
	tween(pop,.2,{Size=Vector3.one*8,Transparency=1},EXPO)
	ping(root,position,color:Lerp(WHITE,.35),2,10,.3)

	local source=host(root,position,Vector3.one)
	burst(source,22,{
		Lifetime=NumberRange.new(.3,.6),
		Speed=NumberRange.new(20,40),
		Size=nseq({0,.9},{1,0}),
		Color=ColorSequence.new(WHITE,color),
	})
	burst(source,3,{
		Texture=TEX.Soft,
		Lifetime=NumberRange.new(.25,.4),
		Speed=NumberRange.new(2,6),
		Size=nseq({0,2},{1,4.5}),
		Transparency=nseq({0,.3},{1,1}),
		Color=ColorSequence.new(color),
	})
end

 
function VFX.Finale(parent,ground,color,accent)
	local root=bundle(parent,4)

	local wave,waveStroke=ring(root,ground+UP*.2,6,color,22,.1)
	tween(wave,.9,{Size=ringSize(90)},EXPO)
	tween(waveStroke,1,{Transparency=1},QUAD,IN)
	local echo,echoStroke=ring(root,ground+UP*.24,4,accent,12,.25)
	tween(echo,1.2,{Size=ringSize(64)},CUBIC)
	tween(echoStroke,1.2,{Transparency=1},QUAD,IN)

	local pillar=column(root,ground,5,80,accent:Lerp(WHITE,.4),.35)
	tween(pillar,.7,{Size=Vector3.new(80,.2,.2),Transparency=1},CUBIC)

	local source=host(root,ground+UP*2,Vector3.new(6,.5,6))
	flashLight(source,accent,45,6,.6)

	burst(source,40,{
		SpreadAngle=Vector2.new(30,30),
		Lifetime=NumberRange.new(.8,1.4),
		Speed=NumberRange.new(40,75),
		Acceleration=Vector3.new(0,-60,0),
		Size=nseq({0,1.1},{1,0}),
		Color=cseq({0,WHITE},{.5,accent},{1,color}),
	})

	local colors={color,accent,PINK,SKY}
	for _,c in ipairs(colors) do
		burst(source,22,{
			SpreadAngle=Vector2.new(35,35),
			Lifetime=NumberRange.new(1.2,2),
			Speed=NumberRange.new(30,60),
			Acceleration=Vector3.new(0,-45,0),
			Drag=.8,
			Rotation=NumberRange.new(0,360),
			RotSpeed=NumberRange.new(-260,260),
			Size=nseq({0,1.3},{1,.2}),
			Color=ColorSequence.new(c),
		})
	end

	 
	local sky=host(root,ground+UP*45,Vector3.new(CFG.FinaleSpread,1,CFG.FinaleSpread))
	for _,c in ipairs(colors) do
		burst(sky,26,{
			EmissionDirection=Enum.NormalId.Bottom,
			SpreadAngle=Vector2.new(20,20),
			Lifetime=NumberRange.new(2.4,3.2),
			Speed=NumberRange.new(2,8),
			Acceleration=Vector3.new(0,-6,0),
			Drag=.5,
			Rotation=NumberRange.new(0,360),
			RotSpeed=NumberRange.new(-180,180),
			Size=nseq({0,1},{1,.6}),
			Transparency=nseq({0,0},{.75,.1},{1,1}),
			Color=ColorSequence.new(c),
		})
	end
end

return VFX