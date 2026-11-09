 
 
 
 
 
 
 
 
 
 
 
 
 
 
local B=script:FindFirstAncestor("BossSystem")
local Effects=require(B.Combat.EffectService)
local Style=require(script.Parent.Style)
local Debris=Effects  

local Golden=require(B.Attacks.Shared.P4GoldenFX)
local FX=Golden.FX
local V={}
 
local function stage(core,life)
	local cast=Effects.NewCast(core.Root.Parent,"P5EnhancedRipAndTearVFX",life or 1.6)
	cast.TimeStopExempt=true
	return Golden.Context(core),cast
end

local GROUND=-1.5  
local RISE=2.6     
local WHITE=Color3.new(1,1,1)
local YELLOW=Style.Indicator or Color3.fromRGB(255,224,40)
local YELLOW_HOT=Style.IndicatorHot or Color3.fromRGB(255,247,165)
local NORMAL={
	main=Color3.fromRGB(255,178,32),hot=Color3.fromRGB(255,246,200),warn=Color3.fromRGB(255,70,45),
	deep=Color3.fromRGB(200,28,24),rock=Color3.fromRGB(58,46,42),scorch=Color3.fromRGB(22,9,8),
	tele=YELLOW,teleHot=YELLOW_HOT,
}
local ENRAGED={
	main=Color3.fromRGB(255,92,34),hot=Color3.fromRGB(255,220,165),warn=Color3.fromRGB(255,25,25),
	deep=Color3.fromRGB(140,6,14),rock=Color3.fromRGB(66,32,28),scorch=Color3.fromRGB(26,5,6),
	tele=YELLOW,teleHot=YELLOW_HOT,  
}

local function palette(angry) return angry and ENRAGED or NORMAL end
local function count(n) return math.max(3,math.floor(n*Style.Detail+.5)) end
local function rnd(a,b) return a+math.random()*(b-a) end
local function on(key) return Style[key]~=false end  
local function spin() return CFrame.Angles(rnd(0,6.28),rnd(0,6.28),rnd(0,6.28)) end

local function play(part,t,props,style,dir)
	Effects:Create(part,TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props):Play()
end

 
local function make(core,name,cf,size,color,alpha,life,neon,mat)
	local p=core.Part(name,cf,size,color,alpha)
	if p.Parent==nil then p.Parent=workspace end
	p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	if neon then p.Material=Enum.Material.Neon elseif mat then p.Material=mat end
	Debris:AddItem(p,life+.3)
	return p
end

 
local function tele(core,name,cf,size,color,alpha,t,neon)
	local p=make(core,name,cf,size,color,alpha,t,neon)
	Debris:AddItem(p,t)
	return p
end

local function later(delay,fn)
	if delay<=0 then fn() else task.delay(delay,fn) end
end

 
local function frame(core)
	local pos=core.Root.Position
	local look=core.Root.CFrame.LookVector
	local flat=Vector3.new(look.X,0,look.Z)
	if flat.Magnitude<1e-3 then flat=Vector3.new(0,0,-1) end
	return CFrame.lookAt(pos,pos+flat)
end

 
local function polar(f,deg,r,y)
	return (f*CFrame.Angles(0,math.rad(deg),0)*CFrame.new(0,y or 0,-r)).Position
end

 
local function between(a,b,lateral)
	local d=b-a
	local len=d.Magnitude
	if len<1e-3 then return CFrame.new(a),0 end
	local z=d/len
	local mid=(a+b)/2
	if lateral then
		local x=(lateral-z*lateral:Dot(z)).Unit
		return CFrame.fromMatrix(mid,x,z:Cross(x),z),len
	end
	local up=math.abs(z.Y)>.98 and Vector3.new(1,0,0) or Vector3.new(0,1,0)
	return CFrame.lookAt(mid,mid+z,up),len
end

 
 
 

 
 
 
local function ring(core,f,o)
	if not o.force and not on("ShockRings") then return end
	local a0,a1=o.from or 0,o.to or 360
	local n=count(o.segments or 14)
	local h=o.h or .3
	for i=0,n-1 do
		local d0,d1=a0+(a1-a0)*i/n,a0+(a1-a0)*(i+1)/n
		local cf0,len0=between(polar(f,d0,o.r0,o.y),polar(f,d1,o.r0,o.y))
		local cf1,len1=between(polar(f,d0,o.r1,o.y),polar(f,d1,o.r1,o.y))
		later(o.delay or 0,function()
			local spawn=o.tele and tele or make
			local p=spawn(core,o.name or "RipAndTearRing",cf0,Vector3.new(o.thick,h,len0*1.15+.05),o.color,o.alpha or .3,o.life,true)
			play(p,o.life,{CFrame=cf1,Size=Vector3.new(o.thick*.4,h*.5,len1*1.15+.05),Transparency=o.fade or 1},o.style,o.dir)
		end)
	end
end

 
 
 

 
function V.Charge(core,range,t,angry)
	local pal=palette(angry)
	local ctx,cast=stage(core,t+.6)
	local f=frame(core)
	local center=f.Position+Vector3.new(0,GROUND+3,0)
	local host=FX.Anchor(ctx,cast,center,t+.2)
	host.Size=Vector3.one*range*.9
	local inhale=FX.Emitter(host,{
		Color=ColorSequence.new(pal.hot,pal.main),Size=FX.Keyed({0,.15},{.6,.55},{1,.2}),
		Transparency=FX.Keyed({0,1},{.3,.1},{1,0}),Lifetime=NumberRange.new(.45),Speed=NumberRange.new(-range*.9),
		Shape=Enum.ParticleEmitterShape.Sphere,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,Rate=angry and 130 or 95,
	})
	cast:Schedule(t,function() inhale.Enabled=false end)
	local ground=CFrame.new(f.Position+Vector3.new(0,GROUND+.25,0))*CFrame.Angles(math.pi/2,0,0)
	FX.Ring(ctx,cast,ground,range*1.1,4,t,pal.tele,.1,.9)
	cast:Schedule(t*.35,function() FX.Ring(ctx,cast,ground,range*.8,3,t*.65,pal.teleHot,.1,.6) end)
	FX.GlowSprite(ctx,cast,center,pal.main,angry and 9 or 7,t+.2,.35)
end

 
 
function V.TelegraphSector(core,range,arc,t,angry)
	local pal=palette(angry)
	local f=frame(core)
	local y=GROUND+.12
	local strips=count(11)
	local width=math.rad(arc)*range/strips
	for i=0,strips-1 do
		local ang=-arc*.5+(i+.5)*arc/strips
		local yy=y+i*.004
		local cf,len=between(polar(f,ang,0,yy),polar(f,ang,range,yy))
		local p=tele(core,"RipAndTearTelegraph",cf,Vector3.new(width,.1,len),pal.tele,.92,t,false)
		play(p,t,{Transparency=.78},Enum.EasingStyle.Linear)
		 
		local a,b=polar(f,ang,0,yy+.06),polar(f,ang,range,yy+.06)
		local cfF,lenF=between(a,b)
		local seed=between(a,a+(b-a)*.04)
		local fill=tele(core,"RipAndTearTelegraphFill",seed,Vector3.new(width,.1,lenF*.04),pal.tele,.8,t,false)
		play(fill,t,{CFrame=cfF,Size=Vector3.new(width,.1,lenF),Transparency=.5},Enum.EasingStyle.Linear)
	end
	local rim=count(30)
	local last
	for i=0,rim do
		local p=polar(f,-arc*.5+i*arc/rim,range,y+.02)
		if last then
			local cf,len=between(last,p)
			local s=tele(core,"RipAndTearTelegraphRim",cf,Vector3.new(1.3,.12,len+.1),pal.teleHot,.3,t,true)
			play(s,t,{Transparency=0},Enum.EasingStyle.Linear)
		end
		last=p
	end
	for _,ang in ipairs({-arc*.5,arc*.5}) do
		local cf,len=between(polar(f,ang,0,y+.02),polar(f,ang,range,y+.02))
		local s=tele(core,"RipAndTearTelegraphEdge",cf,Vector3.new(1,.12,len),pal.teleHot,.35,t,true)
		play(s,t,{Transparency=0},Enum.EasingStyle.Linear)
	end
	 
	ring(core,f,{force=true,tele=true,from=-arc*.5,to=arc*.5,r0=range*.08,r1=range,y=y+.1,thick=.9,h=.15,
		life=t,alpha=.15,fade=.5,color=pal.teleHot,segments=26,style=Enum.EasingStyle.Linear,name="RipAndTearTelegraphFront"})
end

 
 
function V.TelegraphLanes(core,angles,length,width,t,angry)
	local pal=palette(angry)
	local f=frame(core)
	local y=GROUND+.14
	for _,ang in ipairs(angles) do
		local a,b=polar(f,ang,0,y),polar(f,ang,length,y)
		local cf,len=between(a,b)
		local seed=between(a,a+(b-a)*.05)
		local base=tele(core,"RipAndTearLaneBase",cf,Vector3.new(width,.1,len),pal.tele,.9,t,false)
		play(base,t,{Transparency=.8},Enum.EasingStyle.Linear)
		local p=tele(core,"RipAndTearLane",seed,Vector3.new(width,.11,length*.05),pal.tele,.7,t,false)
		play(p,t,{CFrame=cf,Size=Vector3.new(width,.11,len),Transparency=.45},Enum.EasingStyle.Linear)
		local c=tele(core,"RipAndTearLaneCore",seed,Vector3.new(width*.12,.12,length*.05),pal.teleHot,.4,t,true)
		play(c,t,{CFrame=cf,Size=Vector3.new(width*.12,.12,len),Transparency=.2},Enum.EasingStyle.Linear)
		for _,side in ipairs({-1,1}) do
			local e=tele(core,"RipAndTearLaneEdge",cf*CFrame.new(side*width*.5,.02,0),Vector3.new(.55,.12,len),pal.teleHot,.4,t,true)
			play(e,t,{Transparency=.05},Enum.EasingStyle.Linear)
		end
		local aim=CFrame.lookAt(a,b)
		local front=tele(core,"RipAndTearLaneFront",aim,Vector3.new(width,.14,.9),pal.teleHot,.15,t,true)
		play(front,t,{CFrame=CFrame.lookAt(b,b+(b-a)),Transparency=.35},Enum.EasingStyle.Linear)
	end
end

 
 
function V.Sweep(core,range,arc,swing,angry)
	local pal=palette(angry)
	local ctx,cast=stage(core,1.4)
	local f=frame(core)
	local base=f*CFrame.new(0,GROUND+2.2,0)*CFrame.Angles(0,0,math.rad(-7))
	FX.Crescent(ctx,cast,base,range*.78,math.rad(arc),range*.11,pal.main,pal.hot,.34,{Reverse=true,Wipe=swing,Grow=1.18})
	cast:Schedule(.04,function()
		FX.Crescent(ctx,cast,base*CFrame.new(0,.9,0),range*.9,math.rad(arc*.92),range*.05,pal.deep,pal.main,.3,{Reverse=true,Wipe=swing,Grow=1.22})
	end)
	FX.Shockwave(ctx,cast,CFrame.new(f.Position+Vector3.new(0,GROUND+.15,0)),4,range*2.1,.4,pal.main,.2)
	FX.Sparks(ctx,cast,polar(f,arc*.5,range*.7,GROUND+3),pal.main,pal.hot,14,10,26,.5)
end

 
function V.Cross(core,angles,length,angry)
	local pal=palette(angry)
	local ctx,cast=stage(core,1.4)
	local f=frame(core)
	local spread=0
	for _,a in ipairs(angles) do spread=math.max(spread,math.abs(a)) end
	local dist=length*.42
	local mid=f.Position+f.LookVector*dist+Vector3.new(0,GROUND+7,0)
	local strokeR=18
	for i,roll in ipairs({40,-40}) do
		cast:Schedule((i-1)*.035,function()
			local plane=CFrame.fromMatrix(mid,f.RightVector,f.LookVector)*CFrame.Angles(0,math.rad(roll),0)
			FX.Crescent(ctx,cast,plane*CFrame.new(0,0,strokeR),strokeR,math.rad(68),3.2,pal.main,pal.hot,.32,{Wipe=.05,Grow=1.1,Reverse=i==2})
		end)
	end
	cast:Schedule(.06,function()
		FX.Flash(ctx,cast,mid,pal.hot,9,.18,.1)
		FX.Streaks(ctx,cast,mid,f.LookVector,pal.main,pal.hot,18,80,30,60,2.4)
	end)
	for _,ang in ipairs(angles) do
		local a,b=polar(f,ang,2,GROUND+.4),polar(f,ang,length,GROUND+.4)
		FX.Beam(ctx,cast,a,b,2.2,pal.main,pal.hot,.38)
		cast:Schedule(.07,function() FX.Spikes(ctx,cast,b-Vector3.new(0,.3,0),5,2.6,9,pal.main,pal.hot,.55) end)
	end
end

 
 
function V.Vertical(core,angles,length,width,angry)
	local pal=palette(angry)
	local ctx,cast=stage(core,2)
	local f=frame(core)
	local origin=f.Position
	local arcFrame=f*CFrame.new(0,GROUND+6,0)*CFrame.Angles(0,0,math.pi/2)*CFrame.new(0,0,2)
	FX.Crescent(ctx,cast,arcFrame,length*.22,math.rad(165),3.6,pal.main,pal.hot,.34,{Wipe=.07,Grow=1.3})
	FX.Shockwave(ctx,cast,CFrame.new(origin+Vector3.new(0,GROUND+.15,0)),3,26,.45,pal.main,.2)
	for _,ang in ipairs(angles) do
		local a,b=polar(f,ang,3,GROUND+.3),polar(f,ang,length,GROUND+.3)
		FX.Beam(ctx,cast,a,b,width*.5,pal.main,pal.hot,.42)
		local seam=FX.Temp(ctx,cast,"RipAndTearSeam",CFrame.lookAt((a+b)/2,b)-Vector3.new(0,.22,0),Vector3.new(.9,.06,(b-a).Magnitude),pal.main,.15,1.3)
		FX.Tween(seam,1.2,{Size=Vector3.new(.2,.06,(b-a).Magnitude),Transparency=1})
		local steps=math.max(3,math.floor(length/14))
		for i=1,steps do
			local at=a:Lerp(b,i/steps)-Vector3.new(0,.3,0)
			cast:Schedule(.12*i/steps+.03,function()
				FX.Spikes(ctx,cast,at,4,width*.22,8,pal.main,pal.hot,.5)
			end)
		end
		cast:Schedule(.13,function()
			FX.Flash(ctx,cast,b+Vector3.new(0,2,0),pal.hot,8,.2,.1)
			FX.Debris(ctx,cast,b+Vector3.new(0,1,0),8,pal.main,.7,30)
		end)
	end
end

 
 
function V.Impact(core,pos,angry,heavy)
	if not on("HitImpacts") then return end
	local pal=palette(angry)
	local ctx,cast=stage(core,1)
	local at=pos+Vector3.new(0,1.5,0)
	FX.Flash(ctx,cast,at,pal.hot,heavy and 7 or 4.5,.16,.1)
	local from=core.Root.Position
	local face=Vector3.new(from.X,at.Y,from.Z)
	local base=(face-at).Magnitude>.5 and CFrame.lookAt(at,face) or CFrame.new(at)
	for k=0,(heavy and 1 or 0) do
		local roll=math.rad(rnd(-35,35)+k*80)
		FX.Crescent(ctx,cast,base*CFrame.Angles(0,0,roll)*CFrame.Angles(math.pi/2,0,0)*CFrame.new(0,0,4),4.5,math.rad(110),1.1,pal.main,pal.hot,.2,{Wipe=.04})
	end
	FX.Streaks(ctx,cast,at,(at-from).Magnitude>.1 and (at-from).Unit or Vector3.yAxis,pal.main,pal.hot,heavy and 16 or 10,70,30,60,2)
end

 
function V.Recover(core,t,angry)
	local pal=palette(angry)
	local ctx,cast=stage(core,t+.8)
	local f=frame(core)
	FX.Ring(ctx,cast,CFrame.new(f.Position+Vector3.new(0,GROUND+.2,0))*CFrame.Angles(math.pi/2,0,0),18,6,t+.3,pal.deep,.4,.5)
	FX.Sparks(ctx,cast,f.Position+Vector3.new(0,GROUND+1,0),pal.main,pal.hot,8,2,6,.4)
end
return V
