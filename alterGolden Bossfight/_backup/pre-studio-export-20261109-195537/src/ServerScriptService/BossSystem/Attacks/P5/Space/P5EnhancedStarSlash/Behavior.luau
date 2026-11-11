local B=script:FindFirstAncestor("BossSystem")
local E=require(B.Combat.EffectService)
local P=require(B.Encounter.ArenaPlacement)
local Audio=require(B.Presentation.CombatAudio)
local Style=require(script.Parent.Style)
local V=require(script.Parent.Visuals)
local Crimson=require(B.Attacks.Shared.P4GoldenFX)
local FX=Crimson.FX
local Difficulty=require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local FALL_WAVE_GAP=.85  
local RunService=game:GetService("RunService")

local UP=Vector3.yAxis

 
local STROKES={1,3,5,2,4}

local T0=Style.WindUp+Style.ApproachTime
local PERIOD=Style.StrokeTime+Style.StrokePause
local function strokeStart(k) return T0+(k-1)*PERIOD end
local function strokeEnd(k) return strokeStart(k)+Style.StrokeTime end
local function eruptAt(k) return strokeEnd(k)+Style.Fuse end
local ECHO_ON,SEAL_ON=Style.EchoDamage>0,Style.SealDamage>0
local echoAt=eruptAt(5)+Style.EchoDelay
local sealAt=(ECHO_ON and echoAt or eruptAt(5))+Style.SealDelay
local endAt=(SEAL_ON and sealAt) or (ECHO_ON and echoAt) or eruptAt(5)
local FALL_ON=(Style.StarFallDamage or 0)>0
local fallAt=endAt+(Style.StarFallDelay or .75)
local lastAt=FALL_ON and fallAt or endAt

local POSE_A={RightShoulder={140,0,-60},Waist={8,55,0}}
local POSE_B={RightShoulder={120,0,-20},Waist={8,-55,0}}

local function lift(v,n) return v+UP*(n*.02) end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function ease(u) u=math.clamp(u,0,1) return 1-(1-u)*(1-u) end

local function near(pos,a,b,radius,below,above)
	local d=b-a
	local t=math.clamp((pos-a):Dot(d)/math.max(d:Dot(d),.001),0,1)
	local q=a+d*t
	if Vector3.new(pos.X-q.X,0,pos.Z-q.Z).Magnitude<=radius and pos.Y>=q.Y-below and pos.Y<=q.Y+above then
		return q
	end
end

local function onSegment(pos,seg)
	return near(pos,seg[1],seg[2],Style.Width*.5,3,Style.Height)
end

return function(actor)
	local core=require(B.Combat.AttackRegistry).For(actor,"P1CombatCore")
	local ctx=Crimson.Context(core)
	local active={}
	local api={Cooldown=Style.Cooldown}

	function api.CanUse(target)
		return (actor:GetAttribute("Phase") or 0)>=4 and core.Active() and core.Alive(target)
			and not actor:GetAttribute("PhaseTransitionInProgress") and not actor:GetAttribute("EncounterEnded")
	end

	local function strike(segs,damage)
		local hits=0
		for _,char in ipairs(core.Characters()) do
			if core.Alive(char) then
				local pos=char.HumanoidRootPart.Position
				for _,seg in ipairs(segs) do
					local q=onSegment(pos,seg)
					if q and core.CanHit(char,q+UP*3) then
						if core.Damage(char,damage,"P5EnhancedStarSlash")>0 then hits+=1;core.Melee.HitFx(pos) end
						break
					end
				end
			end
		end
		return hits
	end

	function api.Combo(target)
		if not api.CanUse(target) then return false end
		return core.Perform(target,"P5EnhancedStarSlash",function()
			local center=P.GroundPoint(target.HumanoidRootPart.Position,{Margin=Style.Radius+2,Clamp=true})
			if not center then return false end
			local generation=actor:GetAttribute("PhaseGeneration") or 0
			local revision=actor:GetAttribute("MovementRevision") or 0
			local root=core.Root
			 
			local cast=E.NewCast(actor,"P5EnhancedStarSlashPentagram",lastAt+FALL_WAVE_GAP+2.6)
			active[cast]=true;api.LastCast=cast

			local prevAnchored,anchored,stopTrail=root.Anchored,false,nil
			local function release()
				if stopTrail then stopTrail();stopTrail=nil end
				if anchored then
					anchored=false
					if (actor:GetAttribute("PhaseGeneration") or 0)==generation and (actor:GetAttribute("MovementRevision") or 0)==revision then
 pcall(function() root.Anchored=prevAnchored;root.AssemblyLinearVelocity=Vector3.zero end)
 end
				end
			end
			cast.OnDispose=function() release();active[cast]=nil end

			local function valid()
				return cast:Alive() and core.Active() and (actor:GetAttribute("Phase") or 0)>=4
					and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
					and (actor:GetAttribute("PhaseGeneration") or 0)==generation
 and (actor:GetAttribute("MovementRevision") or 0)==revision
			end
			cast:Step(function() if not valid() then cast:Dispose();return false end return true end)
			local function run()
			core.Face(target)
			core.PoseAngles(POSE_A,.2)
			Audio.Emit(actor,"SwordSlash",core.Root)

			local snap=function(p) return P.GroundPoint(p,{Clamp=true,Margin=2}) end
			local points,segments={},{}
			for i=1,5 do
				local angle=-math.pi/2+(i-1)*math.pi*2/5
				local point=P.GroundPoint(center+Vector3.new(math.cos(angle)*Style.Radius,0,math.sin(angle)*Style.Radius),{Clamp=true,Margin=2})
				if not point then cast:Dispose();return false end
				points[i]=point+UP*.18
			end
			for i=1,5 do table.insert(segments,{points[i],points[(i+1)%5+1]}) end
			api.Segments=segments

			local legs={}
			for k,idx in ipairs(STROKES) do legs[k]={a=segments[idx][1],b=segments[idx][2]} end

			 
			local sky={}
			local skyY=Style.SkySigilHeight or 28
			local skyHost=FX.Anchor(ctx,cast,center+UP*skyY)
			local function skyPoint(i) return points[i]+UP*skyY-skyHost.Position end
			for k,idx in ipairs(STROKES) do
				cast:Schedule(strokeStart(k),function()
					if not valid() then return end
					local a0,a1=Instance.new("Attachment"),Instance.new("Attachment")
					a0.Position,a1.Position=skyPoint(idx),skyPoint(idx)
					a0.Parent,a1.Parent=skyHost,skyHost
					local edge={From=skyPoint(idx),To=skyPoint((idx+1)%5+1),A1=a1,Beams={}}
					for _,spec in ipairs({{1.8,Style.Gold,.45},{.5,Style.White,0}}) do
						local bm=Instance.new("Beam")
						bm.Attachment0,bm.Attachment1=a0,a1
						bm.FaceCamera,bm.Segments,bm.LightEmission,bm.LightInfluence=true,2,1,0
						bm.Color=ColorSequence.new(spec[2])
						bm.Width0,bm.Width1=spec[1],spec[1]
						bm.Transparency=NumberSequence.new(spec[3])
						bm.Parent=skyHost
						table.insert(edge.Beams,bm)
					end
					table.insert(sky,edge)
					local born=cast:Now()
					cast:Step(function(_,now)
						if not a1.Parent then return false end
						local u=math.clamp((now-born)/Style.StrokeTime,0,1)
						a1.Position=edge.From:Lerp(edge.To,1-(1-u)^2)
						return u<1
					end)
					FX.Glint(ctx,cast,skyHost.Position+edge.From,Style.Gold,4,.25)
				end)
			end

			local start=root.Position
			local gp=snap(start)
			local hover=gp and math.clamp(start.Y-gp.Y,1.5,8) or 3

			 
			 
			local lines,ground={},{}
			local sealParts

			V.Gather(core,cast,(gp or start-UP*3),Style.WindUp)
			actor:SetAttribute("StarSlashMarkedAt",workspace:GetServerTimeNow())

			local t0=os.clock()

			local function landing(at,pos,dir)
				cast:Schedule(at,function()
					if valid() then V.Landing(core,cast,pos,dir) end
				end)
			end
			landing(T0,legs[1].a,legs[1].a-(gp or start))
			for k=1,5 do landing(strokeEnd(k),legs[k].b,legs[k].b-legs[k].a) end

			for k=1,5 do
				cast:Schedule(strokeStart(k),function()
					if not valid() then return end
					core.PoseAngles(k%2==1 and POSE_A or POSE_B,.08)
					Audio.Emit(actor,"SwordSlash",core.Root)
				end)
			end

			local totalHits=0
			for k,idx in ipairs(STROKES) do
				local seg=segments[idx]
				 
				cast:Schedule(strokeEnd(k),function()
					if not valid() then cast:Dispose();return end
					local zone=V.Zone(core,cast,"PentagramSlashZone",lift(seg[1],idx),lift(seg[2],idx),Style.Width)
					lines[k]={zone}
					table.insert(ground,zone)
					V.Reveal(core,cast,zone,legs[k].a,legs[k].b)
					V.Charge(lines[k],Style.Fuse-Style.WarnTime,Style.Hot,.5)
				end)
				cast:Schedule(eruptAt(k)-Style.WarnTime,function()
					if not valid() then cast:Dispose();return end
					V.Blink(lines[k] or {},Style.WarnTime,.15)
				end)
				cast:Schedule(eruptAt(k),function()
					if not valid() then cast:Dispose();return end
					local list=lines[k] or {}
					V.Relight(list,Style.White,0)
					if ECHO_ON then V.Settle(list,.35) else V.Release(list,.35) end
					V.Erupt(core,cast,seg[1],seg[2])
					Audio.Emit(actor,"ThrustBurst",(seg[1]+seg[2])/2)
					FX.Shake(ctx,(seg[1]+seg[2])/2,90,.2,.3)
					FX.Beam(ctx,cast,seg[1]+UP*.5,seg[2]+UP*.5,2.4,Style.Gold,Style.White,.3)
					totalHits+=strike({seg},Style.Damage)
					actor:SetAttribute("StarSlashEruptedAt",workspace:GetServerTimeNow())
					actor:SetAttribute("StarSlashHits",totalHits)
				end)
			end

			if ECHO_ON then
				 
				cast:Schedule(echoAt-Style.EchoWarn,function()
					if not valid() then cast:Dispose();return end
					V.Relight(ground,Style.Ember,.5)
					V.Blink(ground,Style.EchoWarn,.1)
					V.Implode(core,cast,points,center,Style.EchoWarn+(SEAL_ON and Style.SealDelay or 0))
				end)
				 
				cast:Schedule(echoAt,function()
					if not valid() then cast:Dispose();return end
					V.Relight(ground,Style.White,0)
					V.Release(ground,.35)
					for _,segment in ipairs(segments) do V.Erupt(core,cast,segment[1],segment[2],true) end
					for _,point in ipairs(points) do V.Flare(core,cast,point,Style.Height*2.2,Style.Hot,.55) end
					Audio.Emit(actor,"ThrustBurst",center)
					local hits=strike(segments,Style.EchoDamage)
					FX.Shake(ctx,center,140,.45,.7)
					FX.Tint(ctx,center,Style.Hot,.7,.3,160)
					actor:SetAttribute("StarSlashEchoedAt",workspace:GetServerTimeNow())
					actor:SetAttribute("StarSlashEchoHits",hits)
				end)
			end

			if SEAL_ON then
				 
				local fillTime=sealAt-strokeEnd(5)
				cast:Schedule(strokeEnd(5),function()
					if not valid() then cast:Dispose();return end
					sealParts=V.BlastCharge(core,cast,center,Style.SealRadius,fillTime)
				end)
				cast:Schedule(sealAt,function()
					if not valid() then cast:Dispose();return end
					if sealParts then V.Release(sealParts,.2) end
					V.Detonate(core,cast,center,Style.SealRadius,snap,points)
					 
					for _,edge in ipairs(sky) do
						for _,bm in ipairs(edge.Beams) do bm.Transparency=NumberSequence.new(1) end
					end
					FX.Flash(ctx,cast,center+UP*skyY,Style.Gold,Style.SealRadius*1.4,.3,.1)
					FX.Beam(ctx,cast,center+UP*(skyY+10),center,Style.SealRadius*.9,Style.Gold,Style.White,.55)
					FX.Spikes(ctx,cast,center,12,Style.SealRadius*.75,10,Style.Gold,Style.White,.9,30)
					for i=1,4 do
						cast:Schedule(i*.05,function()
							if cast:Alive() then FX.Ring(ctx,cast,CFrame.new(center+UP*(i*3))*CFrame.Angles(math.pi/2,0,i*.6),3,Style.SealRadius*(2.6-i*.3),.4,i%2==0 and Style.White or Style.Gold,0,.8) end
						end)
					end
					FX.Shake(ctx,center,180,.6,1)
					FX.Tint(ctx,center,Style.Gold,1,.4,180)
					Audio.Emit(actor,"ThrustBurst",center)
					local hits=0
					for _,char in ipairs(core.Characters()) do
						if core.Alive(char) then
							local pos=char.HumanoidRootPart.Position
							if Vector3.new(pos.X-center.X,0,pos.Z-center.Z).Magnitude<=Style.SealRadius
								and pos.Y>=center.Y-3 and pos.Y<=center.Y+Style.Height
								and core.CanHit(char,center+UP*3) then
								if core.Damage(char,Style.SealDamage,"P5EnhancedStarSlash")>0 then hits+=1;core.Melee.HitFx(pos) end
							end
						end
					end
					actor:SetAttribute("StarSlashSealedAt",workspace:GetServerTimeNow())
					actor:SetAttribute("StarSlashSealHits",hits)
				end)
			end

			 
			 
			local fallWaves=Difficulty.Mercy("StarFallWaves") or 1
			local onTarget=Difficulty.Mercy("StarFallOnTarget")~=false
			local baseFallAt=fallAt
			for wave=1,(FALL_ON and fallWaves or 0) do
				local fallAt=baseFallAt+(wave-1)*FALL_WAVE_GAP
				local drops={}
				cast:Schedule(fallAt-Style.StarFallWarn,function()
					if not valid() then return end
					drops={}
					if wave==1 then for _,p in ipairs(points) do table.insert(drops,p) end end
					if core.Alive(target) and (onTarget or wave>1) then
						local tp=snap(target.HumanoidRootPart.Position)
						if tp then table.insert(drops,tp+UP*.18) end
					end
					for _,p in ipairs(drops) do
						local mark=Crimson.Disc(ctx,cast,"StarFallWarning",p+UP*.05,Style.StarFallRadius*2,Style.Hot,.75,Style.StarFallWarn+.05)
						FX.Tween(mark,Style.StarFallWarn,{Transparency=.35})
						FX.Ring(ctx,cast,CFrame.new(p+UP*.2)*CFrame.Angles(math.pi/2,0,0),Style.StarFallRadius*3,Style.StarFallRadius*2,Style.StarFallWarn,Style.Gold,0,.35,14)
						FX.Glint(ctx,cast,p+UP*(skyY+6),Style.Gold,5,Style.StarFallWarn)
					end
				end)
				cast:Schedule(fallAt,function()
					if not valid() then return end
					local hits=0
					for i,p in ipairs(drops) do
						cast:Schedule(i*.03,function()
							if not cast:Alive() then return end
							FX.Beam(ctx,cast,p+UP*(skyY+12),p,3,Style.Gold,Style.White,.35)
							FX.Impact(ctx,cast,p+UP*1,Style.Gold,Style.White,.9,{Ground=CFrame.new(p+UP*.05),Direction=UP,Spread=60})
							FX.Spikes(ctx,cast,p,5,Style.StarFallRadius*.5,6,Style.Gold,Style.White,.6,20)
						end)
						for _,char in ipairs(core.Characters()) do
							if core.Alive(char) then
								local pos=char.HumanoidRootPart.Position
								if Vector3.new(pos.X-p.X,0,pos.Z-p.Z).Magnitude<=Style.StarFallRadius and pos.Y>=p.Y-3 and pos.Y<=p.Y+Style.Height
									and core.CanHit(char,p+UP*3) and core.Damage(char,Style.StarFallDamage,"P5EnhancedStarSlash")>0 then
									hits+=1;core.Melee.HitFx(pos)
								end
							end
						end
					end
					FX.Shake(ctx,center,160,.45,.8)
					actor:SetAttribute("StarSlashStarFallHits",hits)
				end)
			end

			local function sample(t)
				if t<Style.WindUp then return start end
				if t<T0 then
					local goal=legs[1].a+UP*hover
					return start:Lerp(goal,ease((t-Style.WindUp)/Style.ApproachTime)),goal-start
				end
				for k=1,5 do
					local leg=legs[k]
					if t<strokeStart(k) then return leg.a+UP*hover end
					if t<strokeEnd(k) then
						local raw=(t-strokeStart(k))/Style.StrokeTime
						local u=ease(raw)
						 
						local arc=math.sin(raw*math.pi)*Style.DashArc
						return (leg.a+UP*hover):Lerp(leg.b+UP*hover,u)+UP*arc,leg.b-leg.a,k,u
					end
				end
				return legs[5].b+UP*hover
			end

			local dashHits=0

			local function dash()
				local last=start
				local look=flat(legs[1].a-start)
				if look.Magnitude<.05 then look=flat(root.CFrame.LookVector) end
				local tick,hitOnce=0,{}
				root.Anchored=true;anchored=true
				while true do
					if not valid() then cast:Dispose();return false end
					local t=os.clock()-t0
					if t>=strokeEnd(5) then break end
					local pos,dir=sample(t)
					if dir and flat(dir).Magnitude>.05 then look=flat(dir) end
					root.CFrame=CFrame.lookAt(pos,pos+look)
					root.AssemblyLinearVelocity=Vector3.zero

					if t>=Style.WindUp and not stopTrail then stopTrail=V.Trail(core) end

					if Style.DashDamage>0 and t>=T0 and (pos-last).Magnitude>.01 then
						for _,char in ipairs(core.Characters()) do
							if not hitOnce[char] and core.Alive(char) then
								local cp=char.HumanoidRootPart.Position
								if near(cp,last,pos,Style.DashHitRadius,7,7) and core.CanHit(char,pos) then
									hitOnce[char]=true
									if core.Damage(char,Style.DashDamage,"P5EnhancedStarSlash")>0 then dashHits+=1;core.Melee.HitFx(cp) end
								end
							end
						end
					end

					if t>=Style.WindUp then
						tick+=1
						if t>=T0 and (pos-last).Magnitude>.3 then core.Afterimage(root.CFrame) end
					end
					last=pos
					RunService.Heartbeat:Wait()
				end

				local final=legs[5].b+UP*hover
				root.CFrame=CFrame.lookAt(final,final+look)
				actor:SetAttribute("StarSlashDashedAt",workspace:GetServerTimeNow())
				actor:SetAttribute("StarSlashDashHits",dashHits)
				return true
			end

			local ok,finished=pcall(dash)
			release()
			if not ok then warn("[P5EnhancedStarSlash] dash failed: "..tostring(finished));cast:Dispose();return false end
			if ok and finished==false then return false end
			core.Face(target)
			return core.WaitFor(Style.EndLag)
 end
 local ok,result=xpcall(run,debug.traceback)
 if not ok then cast:Dispose();error(result,0) end
 return result
		end)
	end

	function api.Dispose() local list={} for c in pairs(active) do table.insert(list,c) end for _,c in ipairs(list) do c:Dispose() end end
	return api
end
