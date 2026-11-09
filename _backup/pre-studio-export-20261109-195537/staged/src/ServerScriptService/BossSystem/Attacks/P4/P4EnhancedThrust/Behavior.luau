local BossSystem = script:FindFirstAncestor("BossSystem")
local Style = require(script.Parent.Style)
local Effects = require(BossSystem.Combat.EffectService)
local Visuals = require(script.Parent.Visuals)
local ThrustVisuals = require(BossSystem.Attacks.P1.P1GoldenThrust.Visuals)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Run = game:GetService("RunService")
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor,"P1CombatCore")
	local api = {Cooldown=Style.Cooldown}
	local stabPose=ThrustVisuals.stabPose({core=core})
	local rng=Random.new()
	local bolt=ThrustVisuals.bolt({rng=rng,motionLine=core.MotionLine,bright=Style.White})

	local function palette(color)
		return ThrustVisuals.radial({rng=rng,motionLine=core.MotionLine,gold=color,bright=Style.White}),
			ThrustVisuals.groundSparks({rng=rng,motionLine=core.MotionLine,gold=color,bright=Style.White})
	end
	local radialGold,sparksGold=palette(Style.Gold)
	local radialHot,sparksHot=palette(Style.Hot)
	local current
	function api.CanUse(target)
		return not current and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4 and core.Active() and core.Alive(target)
			and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
			and not Time.IsStopped(actor) and Placement.Contains(target.HumanoidRootPart.Position)
	end
	function api.Combo(target)
		if not api.CanUse(target) then return false end
		local result=core.Perform(target,"P4EnhancedThrust",function()
			for dashIndex=1,2 do
				local hot=dashIndex==2
				local accent=hot and Style.Hot or Style.Gold
				local radial=hot and radialHot or radialGold
				local sparks=hot and sparksHot or sparksGold
				local power=hot and 1.3 or 1
				local hitRadius=Style.HitRadius*(hot and Style.Dash2HitRadius or 1)
				local speed=Style.Range/Style.DashDuration*(hot and Style.Dash2Speed or 1)
				core.Face(target)
				local direction=core.Root.CFrame.LookVector
				direction=Vector3.new(direction.X,0,direction.Z).Unit
				local start=core.Root.Position
				local ground=Placement.GroundPoint(start)
				if not ground then return false end
				local standingHeight=start.Y-ground.Y
				local generation=actor:GetAttribute("PhaseGeneration") or 0
				local revision=actor:GetAttribute("MovementRevision") or 0
				local cast=Effects.NewCast(actor,"P4EnhancedThrust",2)
				current=cast
				local anchored=core.Root.Anchored
				local tookAnchor=false
				local view,visualsFinished
				cast.OnDispose=function()
					if view and not visualsFinished then view.Dispose() end
					if tookAnchor and core.Root.Parent and (actor:GetAttribute("MovementRevision") or 0)==revision then
						Time.SetAnchored(core.Root,anchored)
						core.Root.AssemblyLinearVelocity=Vector3.zero
					end
					if current==cast then current=nil end
				end
				local function valid()
					return cast:Alive() and core.Active() and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4
						and (actor:GetAttribute("PhaseGeneration") or 0)==generation
						and (actor:GetAttribute("MovementRevision") or 0)==revision
						and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
				end
				local range=Style.Range
				local obstacle=workspace:Blockcast(core.Root.CFrame,Vector3.new(3,4,3),direction*range,core.Params())
				if obstacle then range=math.max(0,obstacle.Distance-.3) end

				while range>0 and not Placement.Contains(start+direction*range,5) do range-=1 end
				if range<1 then cast:Dispose(); return false end
				local warn=cast:Add(core.Part("EnhancedDashWarning",
					CFrame.lookAt(start+direction*range*.5,start+direction*range),
					Vector3.new(hitRadius*2,.12,range),accent,.8))
				warn.CFrame=warn.CFrame+Vector3.new(0,ground.Y+.12-start.Y,0)
				actor:SetAttribute("AttackState","Enhanced Thrust: charge warning")
				stabPose(false,.08)
				view=Visuals.New(core,actor,dashIndex)
				view.Charge(start,direction)
				view.Telegraph(start,direction,range,hitRadius,ground.Y,Style.Windup)
				Audio.Emit(actor,"ThrustCharge",core.Root)
				if not core.WaitFor(Style.Windup) or not valid() then return false end
				Effects.Release(warn); cast.objects[warn]=nil
				Time.SetAnchored(core.Root,true); tookAnchor=true
				actor:SetAttribute("AttackState","Enhanced Thrust: golden thrust")
				stabPose(true,.035)
				Audio.Emit(actor,"ThrustBurst",core.Root)
				view.Launch(start,direction,ground.Y)
				local side=direction:Cross(Vector3.yAxis).Unit
				radial(start,direction,side,20,2,16,.2,.25)
				sparks(ground+Vector3.yAxis*.2,18)
				local distance,hit,damage=0,{},0
				local lastFloorY=ground.Y
				local function scan(from,to)
					local delta=to-from
					local flat=Vector3.new(delta.X,0,delta.Z)
					for _,character in ipairs(core.Characters()) do
						if not hit[character] and core.Alive(character) then
							local p=character.HumanoidRootPart.Position
							local offset=Vector3.new(p.X-from.X,0,p.Z-from.Z)
							local t=flat:Dot(flat)>0 and math.clamp(offset:Dot(flat)/flat:Dot(flat),0,1) or 0
							local closest=from+delta*t
							if Vector3.new(p.X-closest.X,0,p.Z-closest.Z).Magnitude<=hitRadius
								and math.abs(p.Y-closest.Y)<=Style.HitHeight and core.CanHit(character,closest) then
								local dealt=core.Damage(character,Style.Damage,"P4EnhancedThrust")
								if dealt>0 then hit[character]=true; damage+=dealt; core.Melee.HitFx(p); view.Impact(p,direction) end
							end
						end
					end
				end
				local elapsed=0
				while distance<range and valid() do
					local dt=Run.Heartbeat:Wait()
					if not valid() then break end
					if not Time.WaitForActor(actor) or not valid() then break end
					local step=math.min(range-distance,speed*math.min(dt,.075)*Time.BossRate(actor))
					if step<=0 then continue end
					local from=core.Root.Position
					local nextPosition=start+direction*(distance+step)
					local floor=Placement.GroundPoint(nextPosition,{Margin=5})
					if not floor or math.abs(floor.Y-ground.Y)>4 then break end
					nextPosition=Vector3.new(nextPosition.X,floor.Y+standingHeight,nextPosition.Z)
					local wall=workspace:Blockcast(core.Root.CFrame,Vector3.new(3,4,3),nextPosition-from,core.Params())
					if wall then break end
					lastFloorY=floor.Y
					core.Afterimage(core.Root.CFrame)
					core.Root.CFrame=CFrame.lookAt(nextPosition,nextPosition+direction)
					view.Step(from,nextPosition,direction,distance+step,floor.Y)
					core.MotionLine("EnhancedThrustGlow",from,nextPosition+direction*8,3.2*power,accent,.22)
					core.MotionLine("EnhancedThrustCore",from,nextPosition+direction*12,.6,Style.White,.19)
					bolt(from+side*3,nextPosition+side*3,2,.18)
					bolt(from-side*3,nextPosition-side*3,2,.18)
					sparks(Vector3.new(nextPosition.X,floor.Y+.2,nextPosition.Z),4)
					scan(from,nextPosition)
					distance+=step; elapsed+=dt*Time.BossRate(actor)
				end
				actor:SetAttribute("EnhancedDashCount",dashIndex)
				actor:SetAttribute("LastEnhancedDashDistance",distance)
				actor:SetAttribute("LastEnhancedDashDuration",elapsed)
				actor:SetAttribute("LastEnhancedDashDamage",damage)
				actor:SetAttribute("LastEnhancedDashBaseDamage",Style.Damage)
				local complete=valid()
				if complete then
					view.Finish(core.Root.Position,direction,lastFloorY)
					Audio.Emit(actor,"ThrustStab",core.Root)
					radial(core.Root.Position,direction,side,24,1,20,.24,.3)
					bolt(start,core.Root.Position+direction*12,2,.28)
					sparks(Vector3.new(core.Root.Position.X,lastFloorY+.2,core.Root.Position.Z),20)
					visualsFinished=true
				end
				cast:Dispose()
				if not complete or not core.WaitFor(Style.Recovery) then return false end
			end

			core.Face(target)
			local finisher=Visuals.Finisher(core,actor)
			local lightSword=Visuals.OffhandSword(core,actor)
			local floor=Placement.GroundPoint(core.Root.Position)
			local floorY=floor and floor.Y or core.Root.Position.Y-3
			if Style.SlashWindup>0 then

				core.PoseAngles({RightShoulder={50,0,-85},LeftShoulder={50,0,85},Waist={8,-55,0}},Style.SlashWindup)
				finisher.Gather(core.Root.CFrame,floorY)
				if not core.WaitFor(Style.SlashWindup) then lightSword.Dispose();finisher.Dispose(); return false end
			end
			core.PoseAngles({RightShoulder={50,0,75},LeftShoulder={50,0,-75},Waist={8,70,0}},.18)
			Audio.Emit(actor,"SwordSlash",core.Root)
			Audio.Emit(actor,"ThrustBurst",core.Root)
			local origin=core.Root.Position
			core.Afterimage(core.Root.CFrame)
			finisher.Slash(core.Root.CFrame,floorY)
			for i=0,18 do
				local angle=math.rad(-100+i*200/18)
				local ray=core.Root.CFrame*CFrame.Angles(0,angle,0)
				core.MotionLine("EnhancedDashFinishingSlash",origin,origin+ray.LookVector*Style.SlashRadius,1.7,Style.Hot,.25)
			end
			for _,char in ipairs(core.Characters()) do
				if core.Alive(char) then
					local q=core.Root.CFrame:PointToObjectSpace(char.HumanoidRootPart.Position)
					if Vector3.new(q.X,0,q.Z).Magnitude<=Style.SlashRadius and math.abs(q.Y)<=8 and q.Z<=5 and core.CanHit(char,origin) then
						core.Damage(char,Style.SlashDamage,"P4EnhancedThrust")
						core.Melee.HitFx(char.HumanoidRootPart.Position)
						finisher.Impact(char.HumanoidRootPart.Position,core.Root.CFrame.LookVector)
					end
				end
			end
			actor:SetAttribute("EnhancedDashFinishingSlash",true)
			local finished=core.WaitFor(.18)
			lightSword.Dispose()
			return finished
		end)
		if current then current:Dispose() end
		return result
	end
	function api.Dispose() if current then current:Dispose() end end
	return api
end
