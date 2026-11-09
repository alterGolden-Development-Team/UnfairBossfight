local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
 
 
 
 
 
local B=script:FindFirstAncestor("BossSystem")
local Audio=require(B.Presentation.CombatAudio)
local V=require(script.Parent.Visuals)
local Style=require(script.Parent.Style)
local Difficulty=require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
 
local function riftDelay() return Difficulty.Mercy("RiftDelay") or Style.RiftDelay end
local Effects=require(B.Combat.EffectService)
local Placement=require(B.Encounter.ArenaPlacement)
local Time=require(B.Mechanics.Time.TimeEffectController)
local Crimson=require(B.Attacks.Shared.P4GoldenFX)
local FX=Crimson.FX
local Run=game:GetService("RunService")
local GOLD=Color3.fromRGB(255,200,40)
local WHITE=Color3.fromRGB(255,248,220)

local function sector(range,arc,inner)
	local half=math.rad(arc*.5)
	return function(q)
		if math.abs(q.Y)>8 then return false end
		local d=math.sqrt(q.X*q.X+q.Z*q.Z)
		if d>range then return false end
		if d<=inner then return true end
		return math.acos(math.max(-1,math.min(1,-q.Z/d)))<=half
	end
end

 
local function lanes(angles,length,width)
	local tests={}
	for i,angle in ipairs(angles) do
		local a=math.rad(angle)
		local dx,dz=-math.sin(a),-math.cos(a)
		tests[i]=function(q)
			local along=q.X*dx+q.Z*dz
			return along>=-3 and along<=length and math.abs(q.X*dz-q.Z*dx)<=width*.5
		end
	end
	return function(q)
		if math.abs(q.Y)>18 then return false end
		for _,test in ipairs(tests) do
			if test(q) then return true end
		end
		return false
	end
end

return function(actor)
	local core=require(B.Combat.AttackRegistry).For(actor,"P1CombatCore")
	local ctx=Crimson.Context(core)
	local api={Cooldown=Style.Cooldown}

	local function enraged()
		if actor:GetAttribute("Enraged") then return true end
		local humanoid=actor:FindFirstChildOfClass("Humanoid")
		return humanoid~=nil and humanoid.MaxHealth>0 and humanoid.Health/humanoid.MaxHealth<=Style.EnrageHealth
	end

	function api.CanUse(target)
		return (actor:GetAttribute("Phase") or 0) >= 4 and core.Active() and core.Alive(target)
			and (target.HumanoidRootPart.Position - core.Root.Position).Magnitude <= 32
			and (target.HumanoidRootPart.Position-core.Root.Position).Magnitude<=Style.VerticalRange
			and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
	end

	function api.Combo(target)
		if not api.CanUse(target) then return false end
		return core.Perform(target,"P5EnhancedRipAndTear",function()
			local debuffKey={}
   local generation=actor:GetAttribute("PhaseGeneration") or 0
			local function valid()return core.Active() and (actor:GetAttribute("Phase") or 0) >= 4 and not actor:GetAttribute("PhaseTransitionInProgress")
				and not actor:GetAttribute("EncounterEnded") and (actor:GetAttribute("PhaseGeneration") or 0)==generation end
			local function wait(t)return core.WaitFor(t) and valid() end

			local angry=enraged()
			api.Cooldown=angry and Style.EnragedCooldown or Style.Cooldown

			 
			local function fx(fn,...)
				local ok,err=pcall(fn,...)
				if not ok then warn("[P5EnhancedRipAndTear] vfx: "..tostring(err)) end
			end
			local function sfx(key)
				local sound=Style.Sounds[key]
				if sound then pcall(Audio.Emit,actor,sound,core.Root) end
			end
			local function beat(name)actor:SetAttribute("RipAndTearBeat",name) end  
			local function face()if core.Alive(target) then core.Face(target) end end
			local function anyWithin(range)
				for _,char in ipairs(core.Characters()) do
					if core.Alive(char) and (char.HumanoidRootPart.Position-core.Root.Position).Magnitude<=range then return true end
				end
				return false
			end
			local function strike(test,amount,heavy)
				local hits=0
				for _,char in ipairs(core.Characters()) do
					if core.Alive(char) then
						local q=core.Root.CFrame:PointToObjectSpace(char.HumanoidRootPart.Position)
						if test(q) and core.CanHit(char,core.Root.Position) and core.Damage(char,amount,"P5EnhancedRipAndTear")>0 then
							if heavy then AttackDebuffs.Apply(actor,char,"Hemorrhage",4,debuffKey) end
       hits=hits+1;core.Melee.HitFx(char.HumanoidRootPart.Position);fx(V.Impact,core,char.HumanoidRootPart.Position,angry,heavy)
						end
					end
				end
				return hits
			end

			local speed=angry and Style.EnrageSpeed or 1
			local windup=Style.Windup*speed
			local rendGap=Style.VerticalGap*speed
			local crossAngles={-Style.CrossAngle,Style.CrossAngle}
			local rendAngles=angry and {-Style.EnrageSpread,0,Style.EnrageSpread} or {0}
			local sweepHit=sector(Style.SweepRange,Style.SweepArc,Style.SweepInner)
			local crossHit=lanes(crossAngles,Style.CrossRange,Style.CrossWidth)
			local rendHit=lanes(rendAngles,Style.VerticalRange,Style.VerticalWidth)

			local tint=angry and Crimson.CRIMSON or GOLD
			 
			local function lunge()
				if not core.Alive(target) then return true end
				local root=core.Root
				local tp=target.HumanoidRootPart.Position
				local flat=Vector3.new(tp.X-root.Position.X,0,tp.Z-root.Position.Z)
				if flat.Magnitude<=Style.LungeTrigger then return true end
				local dir=flat.Unit
				local travel=flat.Magnitude-Style.LungeStop
				local wall=workspace:Blockcast(CFrame.new(root.Position),Vector3.new(3,4,3),dir*travel,core.Params())
				if wall then travel=math.max(0,wall.Distance-.5) end
				local from=root.Position
				local goal=from+dir*travel
				local g=Placement.GroundPoint(goal,{Clamp=true,Margin=4})
				if g then goal=Vector3.new(goal.X,g.Y+(from.Y-(Placement.GroundPoint(from,{Clamp=true}) or from-Vector3.new(0,3,0)).Y),goal.Z) end
				if travel<2 then return true end
				beat("Lunge")
				local anchored=root.Anchored
				Time.SetAnchored(root,true)
				local lc=Effects.NewCast(actor,"P5EnhancedRipAndTearLunge",1.2)
				FX.Flash(ctx,lc,from,WHITE,4,.1,0)
				FX.Streaks(ctx,lc,from,-dir,tint,WHITE,10,30,30,60,2.2)
				core.PoseAngles({RightShoulder={80,0,60},Waist={15,-40,0}},Style.LungeTime)
				local t=0
				local last=from
				while t<Style.LungeTime do
					local dt=Run.Heartbeat:Wait()
					if not valid() or not Time.WaitForActor(actor) then Time.SetAnchored(root,anchored);return false end
					t+=dt*Time.BossRate(actor)
					local u=1-(1-math.clamp(t/Style.LungeTime,0,1))^3
					local pos=from:Lerp(goal,u)
					root.CFrame=CFrame.lookAt(pos,pos+dir)
					core.Afterimage(root.CFrame)
					last=pos
				end
				root.AssemblyLinearVelocity=Vector3.zero
				Time.SetAnchored(root,anchored)
				FX.Shockwave(ctx,lc,CFrame.new(goal-Vector3.new(0,2.8,0)),2,12,.3,tint,.3)
				return valid()
			end

			 
			local function rift(angles)
				local frame=core.Root.CFrame
				local floor=Placement.GroundPoint(frame.Position,{Clamp=true})
				local fy=floor and floor.Y or frame.Position.Y-3
				local rc=Effects.NewCast(actor,"P5EnhancedRipAndTearRift",riftDelay()+1.6)
				local test=lanes(angles,Style.VerticalRange,Style.RiftWidth)
				local gen=generation
				local ends={}
				for _,angle in ipairs(angles) do
					local dir=(frame*CFrame.Angles(0,math.rad(angle),0)).LookVector
					dir=Vector3.new(dir.X,0,dir.Z).Unit
					local a=Vector3.new(frame.Position.X,fy+.12,frame.Position.Z)
					local b=a+dir*Style.VerticalRange
					table.insert(ends,{a,b})
					local crack=FX.Temp(ctx,rc,"RipAndTearRiftCrack",CFrame.lookAt((a+b)/2,b),Vector3.new(.4,.1,Style.VerticalRange),tint,.2,riftDelay()+.05)
					FX.Tween(crack,riftDelay(),{Size=Vector3.new(Style.RiftWidth*.5,.12,Style.VerticalRange),Transparency=.05})
					local core2=FX.Temp(ctx,rc,"RipAndTearRiftCore",CFrame.lookAt((a+b)/2,b),Vector3.new(.15,.14,Style.VerticalRange),WHITE,.1,riftDelay()+.05)
					FX.Tween(core2,riftDelay(),{Size=Vector3.new(.6,.14,Style.VerticalRange)})
				end
				rc:Schedule(riftDelay(),function()
					if not actor.Parent or (actor:GetAttribute("PhaseGeneration") or 0)~=gen or actor:GetAttribute("EncounterEnded") then rc:Dispose() return end
					for _,seg in ipairs(ends) do
						local a,b=seg[1],seg[2]
						FX.Beam(ctx,rc,a+Vector3.new(0,.5,0),b+Vector3.new(0,.5,0),Style.RiftWidth*.7,tint,WHITE,.4)
						local steps=8
						for i=1,steps do
							local at=a:Lerp(b,i/steps)
							rc:Schedule(i*.025,function()
								if rc:Alive() then FX.Spikes(ctx,rc,at,3,Style.RiftWidth*.25,5.5,tint,WHITE,.55,15) end
							end)
						end
					end
					FX.Shake(ctx,frame.Position,120,.35,.55)
					local hits=0
					for _,char in ipairs(core.Characters()) do
						if core.Alive(char) then
							local pos=char.HumanoidRootPart.Position
							if test(frame:PointToObjectSpace(pos)) and core.CanHit(char,frame.Position) and core.Damage(char,Style.RiftDamage,"P5EnhancedRipAndTear")>0 then
								hits+=1;core.Melee.HitFx(pos)
							end
						end
					end
					actor:SetAttribute("RipAndTearRiftHits",hits)
				end)
			end

			local function chain()
				actor:SetAttribute("RipAndTearSweepHits",0)
				actor:SetAttribute("RipAndTearCrossHits",0)
				actor:SetAttribute("RipAndTearVerticalHits",0)

				if not lunge() then return false end

				 
				beat("Windup");face()
				fx(V.Charge,core,Style.SweepRange,windup,angry)
				fx(V.TelegraphSector,core,Style.SweepRange,Style.SweepArc,windup,angry)
				core.PoseAngles({RightShoulder={95,0,70},Waist={0,-70,0}},windup)
				if not wait(windup) then return false end

				 
				beat("Rip");sfx("Rip")
				local follow=anyWithin(Style.CrossRange)
				fx(V.Sweep,core,Style.SweepRange,Style.SweepArc,Style.SweepSwing,angry)
				if follow then
					fx(V.TelegraphLanes,core,crossAngles,Style.CrossRange,Style.CrossWidth,Style.SweepSwing+Style.Interval+Style.CrossSwing,angry)
				end
				core.PoseAngles({RightShoulder={35,0,-85},Waist={10,70,0}},Style.SweepSwing)
				if not wait(Style.SweepSwing) then return false end
				FX.Shake(ctx,core.Root.Position,80,.15,.3)
				actor:SetAttribute("RipAndTearSweepHits",strike(sweepHit,Style.SweepDamage))

				 
				if follow then
					beat("Tear")
					core.PoseAngles({RightShoulder={60,0,-110},Waist={0,80,0}},Style.Interval)
					if not wait(Style.Interval) then return false end
					sfx("Tear")
					fx(V.Cross,core,crossAngles,Style.CrossRange,angry)
					core.PoseAngles({RightShoulder={50,0,95},Waist={0,-60,0}},Style.CrossSwing)
					if not wait(Style.CrossSwing) then return false end
					FX.Shake(ctx,core.Root.Position,80,.15,.35)
					actor:SetAttribute("RipAndTearCrossHits",strike(crossHit,Style.CrossDamage))
				end

				 
				beat("Rend");face()
				fx(V.TelegraphLanes,core,rendAngles,Style.VerticalRange,Style.VerticalWidth,rendGap,angry)
				core.PoseAngles({RightShoulder={165,0,-10},Waist={-20,0,0}},rendGap)
				if not wait(rendGap) then return false end
				sfx("Rend")
				fx(V.Vertical,core,rendAngles,Style.VerticalRange,Style.VerticalWidth,angry)
				core.PoseAngles({RightShoulder={25,0,-15},Waist={20,0,0}},Style.VerticalSwing)
				if not wait(Style.VerticalSwing) then return false end
				FX.Shake(ctx,core.Root.Position,140,.4,.75)
				FX.Tint(ctx,core.Root.Position,tint,.8,.3,150)
				actor:SetAttribute("RipAndTearVerticalHits",strike(rendHit,Style.VerticalDamage,true))
				if (Style.RiftDamage or 0)>0 and Difficulty.Mercy("Rift")~=false then fx(rift,rendAngles) end
				fx(V.Recover,core,Style.Recover,angry)  
				return core.WaitFor(Style.Recover)
			end

			local finished=chain()
			beat(nil)
			return finished
		end)
	end
	return api
end
