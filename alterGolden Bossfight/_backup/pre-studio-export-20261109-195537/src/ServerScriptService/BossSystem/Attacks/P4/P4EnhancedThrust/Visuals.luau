local BossSystem=script:FindFirstAncestor("BossSystem")
local Effects=require(BossSystem.Combat.EffectService)
local Style=require(script.Parent.Style)
local TweenService=game:GetService("TweenService")
local Visuals={}
local UP=Vector3.yAxis
local TAU=math.pi*2
local QUAD,LINEAR=Enum.EasingStyle.Quad,Enum.EasingStyle.Linear
local OUT,IN=Enum.EasingDirection.Out,Enum.EasingDirection.In
local BLOCK,BALL,CYLINDER=Enum.PartType.Block,Enum.PartType.Ball,Enum.PartType.Cylinder

local function Kit(core,fx)
	local k={rng=Random.new()}
	local rng=k.rng

	function k.part(name,frame,size,color,transparency,shape)
		local p=fx:Add(core.Part(name,frame,size,color,transparency))
		p.Shape=shape or BLOCK
		return p
	end
	function k.tween(object,seconds,goal,style,direction)
		Effects:Create(object,TweenInfo.new(seconds,style or QUAD,direction or OUT),goal):Play()
	end
	function k.retire(object,seconds)
		local lease=Effects.LeaseId(object)
		fx:Schedule(seconds,function()
			if Effects.LeaseId(object)==lease then fx.objects[object]=nil;Effects.Release(object) end
		end)
	end

	function k.fleeting(name,frame,size,color,transparency,seconds,goal,shape,style,direction)
		local p=k.part(name,frame,size,color,transparency,shape)
		k.tween(p,seconds,goal,style,direction)
		k.retire(p,seconds+.05)
		return p
	end

	function k.light(color,peak,range,seconds)
		local l=Instance.new("PointLight")
		l.Name="EnhancedDashLight";l.Color=color;l.Brightness=peak;l.Range=range;l.Shadows=false
		l.Parent=core.Root;fx:Add(l)
		TweenService:Create(l,TweenInfo.new(seconds,QUAD,OUT),{Brightness=0}):Play()
		return l
	end

	function k.pulse(point,radius,color,seconds)
		k.fleeting("EnhancedDashFlash",CFrame.new(point),Vector3.one*radius,color,.12,seconds,
			{Size=Vector3.one*radius*2.5,Transparency=1},BALL)
	end

	function k.disc(point,diameter,color,seconds,grow,transparency)
		k.fleeting("EnhancedDashGroundFlash",CFrame.new(point)*CFrame.Angles(0,0,math.pi/2),
			Vector3.new(.12,diameter,diameter),color,transparency or .3,seconds,
			{Size=Vector3.new(.06,diameter*grow,diameter*grow),Transparency=1},CYLINDER)
	end

	function k.ring(point,direction,radius,color,seconds,segments,inward)
		local frame=CFrame.lookAt(point,point+direction,math.abs(direction.Y)>.9 and Vector3.zAxis or UP)
		local count=segments or 20
		local r0,r1=radius,radius*2.3
		if inward then r0,r1=r1,radius*.8 end
		for i=1,count do
			local angle=i*TAU/count
			local function at(r) return frame*CFrame.new(math.cos(angle)*r,math.sin(angle)*r,0)*CFrame.Angles(0,0,angle+math.pi*.5) end
			k.fleeting("EnhancedDashShockRing",at(r0),Vector3.new(TAU*r0/count*1.05,.24,.24),color,.2,seconds,
				{CFrame=at(r1),Size=Vector3.new(TAU*r1/count*1.05,.05,.05),Transparency=1})
		end
	end

	function k.streak(name,a,b,width,color,transparency,seconds,height)
		local length=(b-a).Magnitude
		if length<.05 then return end
		return k.fleeting(name,CFrame.lookAt((a+b)*.5,b),Vector3.new(width,height or width,length),color,transparency,seconds,
			{Size=Vector3.new(.04,.04,length),Transparency=1})
	end

	function k.gather(point,radius,count,color,seconds)
		for _=1,count do
			local d=Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-.5,1),rng:NextNumber(-1,1))
			if d.Magnitude<.2 then d=Vector3.new(1,.3,0) end
			d=d.Unit
			local from=point+d*radius*rng:NextNumber(.75,1.15)
			k.fleeting("EnhancedDashGather",CFrame.lookAt(from,point),Vector3.new(.2,.2,rng:NextNumber(2,4.5)),color,.1,
				seconds*rng:NextNumber(.75,1),
				{CFrame=CFrame.lookAt(point+d*1.5,point),Size=Vector3.new(.05,.05,.5),Transparency=.6},nil,QUAD,IN)
		end
	end

	function k.flare(frame,length,color,seconds)
		for i=0,3 do
			k.fleeting("EnhancedDashFlare",frame*CFrame.Angles(0,0,i*math.pi/4),Vector3.new(length,.14,.14),color,.05,seconds,
				{Size=Vector3.new(length*.15,.05,.05),Transparency=1})
		end
	end

	function k.impact(point,direction,color,count)
		k.pulse(point,3.5,Style.White,.22)
		k.ring(point,direction,2.6,color,.26,12)
		for i=1,count or 8 do
			local d=Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-.2,1),rng:NextNumber(-1,1))
			if d.Magnitude<.2 then d=UP end
			d=d.Unit
			k.streak("EnhancedDashHitSpark",point+d*1.2,point+d*rng:NextNumber(5,10),.25,i%2==0 and Style.White or color,.05,.25)
		end
	end
	return k
end

local function guard(core,actor,fx)
	local generation=actor:GetAttribute("PhaseGeneration") or 0
	fx:Step(function()
		if not core.Active() or math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4
			or (actor:GetAttribute("PhaseGeneration") or 0)~=generation then fx:Dispose();return false end
		return true
	end)
end

function Visuals.New(core,actor,index)
	local hot=(index or 1)>=2
	local accent=hot and Style.Hot or Style.Gold
	local power=hot and 1.35 or 1
	local fx=Effects.NewCast(actor,"P4EnhancedDashVFX",3.5)
	local view={Cast=fx}
	guard(core,actor,fx)
	local k=Kit(core,fx)
	local rng=k.rng
	local root=core.Root
	local origin,halo,glow
	local aura,emitters,trails={},{},{}

	local function comet(parent)
		local p=Instance.new("ParticleEmitter")
		p.Name="EnhancedDashCometSparks";p.Texture="rbxasset://textures/particles/sparkles_main.dds"
		p.Color=ColorSequence.new(Style.White,accent);p.LightEmission=1
		p.Rate=120*power;p.Lifetime=NumberRange.new(.15,.35);p.Speed=NumberRange.new(6,15)
		p.SpreadAngle=Vector2.new(80,80);p.EmissionDirection=Enum.NormalId.Back
		p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,0)})
		p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,1)})
		p.Parent=parent;fx:Add(p);emitters[#emitters+1]=p;return p
	end

	local function embers(parent)
		local p=Instance.new("ParticleEmitter")
		p.Name="EnhancedDashEmbers";p.Texture="rbxasset://textures/particles/sparkles_main.dds"
		p.Color=ColorSequence.new(Style.White,accent);p.LightEmission=1
		p.Rate=90*power;p.Lifetime=NumberRange.new(.5,1.1);p.Speed=NumberRange.new(4,12)
		p.SpreadAngle=Vector2.new(35,35);p.EmissionDirection=Enum.NormalId.Top
		p.Acceleration=Vector3.new(0,14,0);p.Drag=1.5
		p.Rotation=NumberRange.new(0,360);p.RotSpeed=NumberRange.new(-180,180)
		p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,0)})
		p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(1,1)})
		p.Enabled=false
		p.Parent=parent;fx:Add(p);emitters[#emitters+1]=p;return p
	end

	local function ribbon(x,y0,y1,life,startTransparency)
		local a=Instance.new("Attachment");a.Position=Vector3.new(x,y0,0);a.Parent=root;fx:Add(a)
		local b=Instance.new("Attachment");b.Position=Vector3.new(x,y1,0);b.Parent=root;fx:Add(b)
		local trail=Instance.new("Trail");trail.Name="EnhancedDashRibbon";trail.Attachment0=a;trail.Attachment1=b
		trail.Color=ColorSequence.new(Style.White,accent);trail.LightEmission=1
		trail.Lifetime=life;trail.MinLength=.02;trail.FaceCamera=true
		trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,startTransparency),NumberSequenceKeypoint.new(1,1)})
		trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
		trail.Parent=root;fx:Add(trail);trails[#trails+1]=trail
	end
	for _,x in ipairs({-2.7,2.7}) do ribbon(x,1.4,-1.4,.45*power,.05) end
	for _,x in ipairs({-4.6,4.6}) do ribbon(x,3.2,-3.2,.3*power,.45) end
	local cometEmitter,emberEmitter

	local function build(point)
		local outer,inner=hot and 22 or 16,hot and 12 or 8
		for i=1,outer do
			aura[#aura+1]={part=k.part("EnhancedDashSpiral",CFrame.new(point),Vector3.new(1.5,.2,.45),i%2==0 and accent or Style.White,.12),
				phase=(i-1)*TAU/outer,radius=4,depth=1.2,dir=1}
		end
		for i=1,inner do
			aura[#aura+1]={part=k.part("EnhancedDashSpiral",CFrame.new(point),Vector3.new(1,.16,.32),i%2==0 and Style.White or accent,.2),
				phase=(i-1)*TAU/inner,radius=2.3,depth=-.6,dir=-1.7}
		end
		halo=k.part("EnhancedDashHalo",CFrame.new(point),Vector3.one*9*power,accent,.85,BALL)
	end
	local function draw(position,direction,spin)
		local frame=CFrame.lookAt(position,position+direction)
		for _,a in ipairs(aura) do
			local angle=a.phase+spin*a.dir
			local radius=a.radius+math.sin(angle*2+spin)*.55
			a.part.CFrame=frame*CFrame.new(math.cos(angle)*radius,math.sin(angle)*radius,a.depth+math.sin(angle*3+spin)*1.1)*CFrame.Angles(0,0,angle+math.pi*.5)
		end
		if halo then
			halo.CFrame=CFrame.new(position)
			halo.Size=Vector3.one*(9*power+math.sin(spin*6)*.8)
		end
	end

	function view.Charge(point,direction)
		origin=point
		k.pulse(point,6,Style.White,.28)
		k.ring(point,direction,4,accent,.4)
		k.ring(point-Vector3.new(0,2.8,0),UP,6,Style.White,.4)
		k.gather(point,11,hot and 18 or 12,accent,Style.Windup)
		build(point)
		draw(point,direction,0)
		cometEmitter=comet(root)
		local feet=Instance.new("Attachment");feet.Position=Vector3.new(0,-2.8,0);feet.Parent=root;fx:Add(feet)
		emberEmitter=embers(feet)
		glow=Instance.new("PointLight");glow.Name="EnhancedDashGlow";glow.Color=accent;glow.Range=34
		glow.Brightness=0;glow.Shadows=false;glow.Parent=root;fx:Add(glow)
		TweenService:Create(glow,TweenInfo.new(Style.Windup,QUAD,OUT),{Brightness=3}):Play()
		core.ScreenEffect("Shake",{Origin=point,Radius=100,Duration=.2,Intensity=.3})
	end

	function view.Telegraph(point,direction,range,radius,groundY,windup)
		if fx.closed then return end
		local base=Vector3.new(point.X,groundY+.16,point.Z)
		local center,tip=base+direction*range*.5,base+direction*range
		local side=direction:Cross(UP).Unit
		for _,sign in ipairs({-1,1}) do
			local edge=k.part("EnhancedDashLaneEdge",CFrame.lookAt(center+side*sign*radius,tip+side*sign*radius),Vector3.new(.35,.1,range),Style.White,.55)
			k.tween(edge,windup,{Transparency=.2},LINEAR)
			k.retire(edge,windup+.04)
		end
		local fill=k.part("EnhancedDashLaneFill",CFrame.lookAt(base+direction*.5,base+direction),Vector3.new(radius*2,.14,1),accent,.8)
		k.tween(fill,windup,{CFrame=CFrame.lookAt(center,tip),Size=Vector3.new(radius*2,.14,range),Transparency=.5},LINEAR)
		k.retire(fill,windup+.04)
		local mark=k.part("EnhancedDashLaneTarget",CFrame.new(tip)*CFrame.Angles(0,0,math.pi/2),Vector3.new(.1,radius*4,radius*4),accent,.75,CYLINDER)
		k.tween(mark,windup,{Size=Vector3.new(.1,radius*2,radius*2),Transparency=.35},QUAD,IN)
		k.retire(mark,windup+.04)
		local count=math.clamp(math.floor(range/10),3,9)
		local wing=radius*.55
		for i=1,count do
			local frame=CFrame.lookAt(base+direction*(range*(i-.5)/count),base+direction*(range*(i-.5)/count+1))
			local function spawn()
				if fx.closed then return end
				for _,sign in ipairs({-1,1}) do
					k.fleeting("EnhancedDashChevron",frame*CFrame.new(sign*wing/2,0,wing/2)*CFrame.Angles(0,sign*math.rad(45),0),
						Vector3.new(.5,.12,wing*1.42),Style.White,.15,.28,{Transparency=1})
				end
			end
			if i==1 then spawn() else fx:Schedule(windup*.85*(i-1)/count,spawn) end
		end
	end

	function view.Launch(point,direction,groundY)
		if fx.closed then return end
		local floor=Vector3.new(point.X,groundY+.15,point.Z)
		local side=direction:Cross(UP).Unit
		k.pulse(point,7*power,Style.White,.24)
		k.disc(floor,10,accent,.35,4,.25)
		k.ring(point,direction,5,accent,.35,14)
		for _=1,8 do
			local a=rng:NextNumber(0,TAU)
			local from=point+(side*math.cos(a)+UP*math.sin(a))*rng:NextNumber(.8,2.4)
			k.streak("EnhancedDashJet",from,from-direction*rng:NextNumber(9,18),.45,rng:NextInteger(0,1)==0 and Style.White or accent,.1,.28)
		end
		if emberEmitter then emberEmitter.Enabled=true;emberEmitter:Emit(20) end
		k.light(accent,8*power,36,.25)
		core.ScreenEffect("Shake",{Origin=point,Radius=100,Duration=.2,Intensity=.5*power})
	end

	local nextWake,nextCrack=0,0
	function view.Step(from,to,direction,distance,floorY)
		if fx.closed then return end
		draw(to,direction,distance*.11)
		local side=direction:Cross(UP).Unit
		for _,sign in ipairs({-1,1}) do
			local a=from+side*sign*2.7
			local b=to+side*sign*2.7
			local length=(b-a).Magnitude
			if length>.02 then
				k.fleeting("EnhancedDashSpeedBlade",CFrame.lookAt((a+b)*.5,b),Vector3.new(.45,2,length),Style.White,.12,.28,
					{Transparency=1,Size=Vector3.new(.08,.2,length)})
			end
		end

		for _=1,3 do
			local at=from:Lerp(to,rng:NextNumber())+side*(rng:NextNumber(4,11)*(rng:NextInteger(0,1)*2-1))+Vector3.new(0,rng:NextNumber(-1.5,5),0)
			k.streak("EnhancedDashAirSlice",at,at-direction*rng:NextNumber(14,28),.14,Style.White,.2,.22)
		end
		if floorY then
			local a=Vector3.new(from.X,floorY+.12,from.Z)
			local b=Vector3.new(to.X,floorY+.12,to.Z)
			local length=(b-a).Magnitude
			if length>.05 then

				k.fleeting("EnhancedDashScorch",CFrame.lookAt((a+b)*.5,b),Vector3.new(2.6*power,.1,length),accent,.25,1.1,
					{Transparency=1,Size=Vector3.new(.4,.1,length)})
				k.fleeting("EnhancedDashScorchCore",CFrame.lookAt((a+b)*.5+UP*.04,b+UP*.04),Vector3.new(.7,.12,length),Style.White,.05,.45,
					{Transparency=1,Size=Vector3.new(.1,.12,length)})
				if distance>=nextCrack then
					nextCrack=distance+12
					for i=1,4 do
						local dir=CFrame.Angles(0,math.rad(rng:NextNumber(55,125))*(i%2==0 and 1 or -1),0)*direction
						local reach=rng:NextNumber(5,11)
						k.streak("EnhancedDashCrack",b+dir*1.5,b+dir*reach,.35,accent,.1,.9,.08)
					end
				end
			end
		end
		if distance>=nextWake then
			nextWake=distance+18
			k.ring(to,direction,3,accent,.25)
		end
	end

	function view.Finish(point,direction,groundY)
		if fx.closed then return end
		for _,e in ipairs(emitters) do e.Enabled=false end
		if emberEmitter then emberEmitter:Emit(hot and 40 or 28) end
		for _,t in ipairs(trails) do t.Enabled=false end
		for _,a in ipairs(aura) do k.tween(a.part,.2,{Transparency=1}) end
		if halo then k.tween(halo,.3,{Size=Vector3.one*22*power,Transparency=1}) end
		if glow then TweenService:Create(glow,TweenInfo.new(.3,QUAD,OUT),{Brightness=0}):Play() end
		k.pulse(point,8*power,Style.White,.32)
		k.ring(point,direction,6,accent,.42)
		k.ring(point-Vector3.new(0,2.8,0),UP,8,accent,.45)
		local floor=Vector3.new(point.X,(groundY or point.Y-2.8)+.15,point.Z)
		k.disc(floor,12,accent,.4,3.6,.3)
		k.disc(floor+UP*.02,6,Style.White,.3,3,.15)
		k.fleeting("EnhancedDashPillar",CFrame.new(point+Vector3.new(0,12,0)),Vector3.new(3.6*power,28,3.6*power),accent,.25,.4,
			{Size=Vector3.new(.3,40,.3),Transparency=1,CFrame=CFrame.new(point+Vector3.new(0,18,0))})
		if origin then
			local length=(point-origin).Magnitude
			if length>1 then
				local frame=CFrame.lookAt((origin+point)*.5,point)

				k.fleeting("EnhancedDashCut",frame,Vector3.new(.5,7*power,length),accent,.5,.4,{Size=Vector3.new(.08,.5,length),Transparency=1})
				k.fleeting("EnhancedDashCutCore",frame,Vector3.new(1.2,1.2,length),Style.White,.05,.5,{Size=Vector3.new(.08,.08,length),Transparency=1})

				for i=1,5 do
					local at=origin:Lerp(point,i/5)
					local function spawn()
						if fx.closed then return end
						k.ring(at,direction,3.5,i%2==0 and Style.White or accent,.3,10)
					end
					if i==1 then spawn() else fx:Schedule((i-1)*.035,spawn) end
				end
			end
		end
		k.light(accent,14,48,.4)
		core.ScreenEffect("Shake",{Origin=point,Radius=100,Duration=.3,Intensity=.75*(hot and 1.25 or 1)})
		fx:Schedule(1.3,function() fx:Dispose() end)
	end

	function view.Impact(point,direction)
		if fx.closed then return end
		k.impact(point,direction,accent,hot and 12 or 8)
		core.ScreenEffect("Shake",{Origin=point,Radius=60,Duration=.12,Intensity=.35})
	end
	function view.Dispose() fx:Dispose() end
	return view
end

function Visuals.Finisher(core,actor)
	local fx=Effects.NewCast(actor,"P4EnhancedDashFinisherVFX",3)
	local fin={Cast=fx}
	guard(core,actor,fx)
	local k=Kit(core,fx)
	local rng=k.rng
	local ARC=math.rad(200)

	local function crescent(base,o)
		local from,span=math.rad(-100)*o.dir,ARC*o.dir
		local function arcLength(r) return r*ARC/o.steps*1.3 end
		for i=0,o.steps do
			local t=i/o.steps
			local a=from+t*span
			local profile=math.max(math.sin(t*math.pi),.1)^.7
			local lift=o.height+math.sin(a)*o.rise
			local tilt=-math.atan(o.rise*math.cos(a)/o.radius)
			local at=base*CFrame.Angles(0,a,0)
			local function place(r,y) return at*CFrame.new(0,y,-r)*CFrame.Angles(0,0,tilt) end
			local function spawn()
				if fx.closed then return end
				local r=o.radius

				k.fleeting("EnhancedDashSlashEdge",place(r,lift),Vector3.new(arcLength(r),1.6*profile+.25,3*profile+.2),o.edge,.08,.38,
					{CFrame=place(r*1.16,lift),Size=Vector3.new(arcLength(r*1.16),.05,.1),Transparency=1})

				k.fleeting("EnhancedDashSlashCore",place(r*.97,lift),Vector3.new(arcLength(r*.97),.7*profile+.1,1.3*profile+.1),Style.White,0,.3,
					{CFrame=place(r*1.1,lift),Size=Vector3.new(arcLength(r*1.1),.05,.06),Transparency=1})

				k.fleeting("EnhancedDashSlashTrace",place(r,lift),Vector3.new(arcLength(r),.22,.22),o.trace,.2,.85,{Transparency=1})

				if i%2==0 then
					k.fleeting("EnhancedDashSlashHead",CFrame.new(place(r*1.02,lift).Position),Vector3.one*2.4*(.5+profile),Style.White,.05,.22,
						{Size=Vector3.one*.4,Transparency=1},BALL)
				end
				if o.heavy then

					k.fleeting("EnhancedDashSlashWall",place(r*.62,lift-.5),Vector3.new(arcLength(r*.62),9*profile+.5,.3),Style.White,.55,.3,
						{CFrame=place(r*1.05,lift-.5),Size=Vector3.new(arcLength(r*1.05),.4,.1),Transparency=1})

					k.fleeting("EnhancedDashSlashScorch",at*CFrame.new(0,o.floorOffset,-r*.85),Vector3.new(arcLength(r*.85),.1,4.5*profile+.3),Style.Hot,.3,1.2,
						{Transparency=1})
				end
			end
			local delay=o.delay+t*o.sweep
			if delay<=0 then spawn() else fx:Schedule(delay,spawn) end
		end
	end

	function fin.Gather(frame,groundY)
		if fx.closed then return end
		local origin=frame.Position
		local seconds=math.max(Style.SlashWindup,.05)
		local radius=Style.SlashRadius
		local floor=Vector3.new(origin.X,(groundY or origin.Y-3)+.14,origin.Z)
		local grounded=CFrame.new(floor)*frame.Rotation

		local steps=14
		for i=0,steps do
			local at=grounded*CFrame.Angles(0,math.rad(-100)+i/steps*ARC,0)
			local p=k.part("EnhancedDashSlashWarn",at*CFrame.new(0,0,-radius),Vector3.new(radius*ARC/steps*1.3,.1,.6),Style.Hot,.8)
			k.tween(p,seconds,{Transparency=.35},LINEAR);k.retire(p,seconds+.03)
		end
		for _,a in ipairs({math.rad(-100),math.rad(100)}) do
			local p=k.part("EnhancedDashSlashWarn",grounded*CFrame.Angles(0,a,0)*CFrame.new(0,0,-radius/2),Vector3.new(.5,.1,radius),Style.Hot,.8)
			k.tween(p,seconds,{Transparency=.35},LINEAR);k.retire(p,seconds+.03)
		end
		k.gather(origin,17,24,Style.Hot,seconds)
		k.ring(origin-Vector3.new(0,2.8,0),UP,9,Style.Hot,seconds,18,true)
		k.pulse(origin,4,Style.White,seconds)
		k.flare(CFrame.new(origin+frame.RightVector*2.5+Vector3.new(0,2.5,0))*frame.Rotation,9,Style.White,seconds+.06)
		k.light(Style.Hot,6,30,seconds*2)
	end

	function fin.Slash(frame,groundY)
		if fx.closed then return end
		local origin=frame.Position
		local base=CFrame.new(origin)*frame.Rotation
		local radius=Style.SlashRadius
		local rise=Style.SlashRise
		local height=3
		local floorOffset=(groundY or origin.Y-3)+.14-origin.Y
		crescent(base,{radius=radius,steps=18,dir=1,rise=rise,height=height,delay=0,sweep=.07,
			edge=Style.Hot,trace=Style.Gold,heavy=true,floorOffset=floorOffset})
		if Style.SlashEcho then

			crescent(base,{radius=radius*.9,steps=12,dir=-1,rise=-rise*.85,height=height,delay=.1,sweep=.06,
				edge=Style.Gold,trace=Style.White})
			fx:Schedule(.1,function()
				if fx.closed then return end
				k.pulse(origin+Vector3.new(0,height,0),6,Style.White,.22)
				k.light(Style.Gold,8,36,.25)
				core.ScreenEffect("Shake",{Origin=origin,Radius=100,Duration=.2,Intensity=.6})
			end)
		end
		local floor=Vector3.new(origin.X,origin.Y+floorOffset,origin.Z)
		k.disc(floor,14,Style.Hot,.4,2.6,.25)
		k.disc(floor+UP*.02,8,Style.White,.3,3,.15)
		k.ring(floor,UP,8,Style.Hot,.42,20)
		k.pulse(origin+UP,9,Style.White,.3)
		k.flare(CFrame.new(origin+Vector3.new(0,height,0))*frame.Rotation,16,Style.White,.2)

		for i=1,24 do
			local a=rng:NextNumber(-1.74,1.74)
			local at=(base*CFrame.Angles(0,a,0)*CFrame.new(0,height+math.sin(a)*rise,-rng:NextNumber(radius*.4,radius))).Position
			local out=Vector3.new(at.X-origin.X,0,at.Z-origin.Z)
			if out.Magnitude>.1 then
				k.streak("EnhancedDashSlashSpark",at,at+out.Unit*rng:NextNumber(2,6)+UP*rng:NextNumber(3,9),.22,i%2==0 and Style.White or Style.Hot,.05,.3)
			end
		end
		k.light(Style.Hot,14,48,.4)
		core.ScreenEffect("Shake",{Origin=origin,Radius=100,Duration=.35,Intensity=.95})
		fx:Schedule(1.4,function() fx:Dispose() end)
	end

	function fin.Impact(point,direction)
		if fx.closed then return end
		k.impact(point,direction,Style.Hot,10)
	end
	function fin.Dispose() fx:Dispose() end
	return fin
end


function Visuals.OffhandSword(core,actor)
 local hand=actor:FindFirstChild("LeftHand") or actor:FindFirstChild("Left Arm")
 if not hand then return {Dispose=function() end} end
 local generation=actor:GetAttribute("PhaseGeneration") or 0
 local cast=Effects.NewCast(actor,"EnhancedDashOffhandSword",Style.SlashWindup+.65)
 local model=Instance.new("Model")
 model.Name="P4EnhancedDashLightSword";model.Parent=actor;cast:Add(model)
 local grip=CFrame.new(0,-hand.Size.Y*.5,0)*CFrame.Angles(-math.pi/2,0,0)
 local handle
 local function piece(name,size,offset,color,alpha)
  local p=Instance.new("Part")
  p.Name=name;p.Size=size;p.Color=color;p.Transparency=alpha or 0;p.Material=Enum.Material.Neon
  p.Anchored=false;p.Massless=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  p.CFrame=hand.CFrame*grip*offset;p.Parent=model
  if handle then
   local weld=Instance.new("Weld");weld.Part0=handle;weld.Part1=p;weld.C0=offset;weld.Parent=p
  end
  return p
 end
 handle=piece("LightSwordHandle",Vector3.new(.45,1.6,.45),CFrame.identity,Style.Gold)
 local joint=Instance.new("Weld")
 joint.Name="OffhandLightSwordGrip";joint.Part0=hand;joint.Part1=handle;joint.C0=grip;joint.Parent=handle
 piece("LightSwordGuard",Vector3.new(2.3,.3,.55),CFrame.new(0,.9,0),Style.Gold)
 local blade=piece("LightSwordBlade",Vector3.new(.7,6.8,.2),CFrame.new(0,4.4,0),Style.White,.08)
 piece("LightSwordAura",Vector3.new(1,7,.16),CFrame.new(0,4.4,0),Style.Gold,.55)
 piece("LightSwordTip",Vector3.new(.42,.8,.2),CFrame.new(0,8.15,0),Style.White,.08)
 local a0,a1=Instance.new("Attachment"),Instance.new("Attachment")
 a0.Position=Vector3.new(0,3.7,0);a1.Position=Vector3.new(0,-2.7,0);a0.Parent=blade;a1.Parent=blade
 local trail=Instance.new("Trail")
 trail.Name="OffhandLightBladeTrail";trail.Attachment0=a0;trail.Attachment1=a1
 trail.Lifetime=.18;trail.MinLength=.05;trail.FaceCamera=true;trail.LightEmission=1
 trail.Color=ColorSequence.new(Style.White,Style.Gold)
 trail.Transparency=NumberSequence.new(.15,1);trail.Parent=blade
 local light=Instance.new("PointLight")
 light.Color=Style.Gold;light.Brightness=1.5;light.Range=12;light.Parent=blade
 actor:SetAttribute("EnhancedDashOffhandSwordActive",true)
 cast.OnDispose=function()
  if actor.Parent then actor:SetAttribute("EnhancedDashOffhandSwordActive",false) end
 end
 cast:Step(function()
  if not core.Active() or math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4 or actor:GetAttribute("PhaseTransitionInProgress")
   or (actor:GetAttribute("PhaseGeneration") or 0)~=generation then cast:Dispose();return false end
  return true
 end)
 return {Dispose=function() cast:Dispose() end}
end

return Visuals
