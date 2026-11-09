local B=script:FindFirstAncestor("BossSystem")
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Placement=require(B.Encounter.ArenaPlacement)
local Status=require(B.Combat.StatusEffectService)
local Encounter=require(B.Players.PlayerEncounter)
local Dash=require(B.Players.R6DashService)
local Cooldowns=require(B.Combat.AbilityCooldownService)
local Appearance=require(script.Appearance)
local CreateVisuals=require(script.Visuals)
local StartBehavior=require(script.Behavior)
local NAME="P3PlayerClone"
return function(actor)
	local core=Registry.For(actor,"P1CombatCore")
	local api={Cooldown=Config.P3PlayerCloneCooldown or 65,ManagesCooldown=true}
	local current
	local random=Random.new()
	local function eligible(player)
		local c=player.Character
		return c and core.Alive(c) and not c.HumanoidRootPart.Anchored
			and not Status.IsLocked(player) and not Status.IsDebuffImmune(c)
			and not Encounter.IsDefeated(player) and not player:GetAttribute("ExecutionPending")
	end
	function api.CanUse(target)
		if current or math.floor(actor:GetAttribute("Phase") or 1) ~= 3 or actor:GetAttribute("IsGoldenClone")
			or actor:GetAttribute("PhaseTransitionInProgress") or not core.Active()
			or not Cooldowns.Ready(actor,NAME) then return false end
		for _,p in ipairs(Players:GetPlayers()) do if eligible(p) then return true end end
		return false
	end
	function api.Combo(target)
		if not api.CanUse(target) then return false end
		local pool={}
		for _,p in ipairs(Players:GetPlayers()) do if eligible(p) then table.insert(pool,p) end end
		local selected=pool[random:NextInteger(1,#pool)]
		local source=selected.Character
		local owned,spawned
		local ok,result=xpcall(function()
			return core.Perform(source,NAME,function()
				local generation=actor:GetAttribute("PhaseGeneration") or 0
				local lifetime=Config.P3PlayerCloneLifetime or 50
				local cast=Effects.NewCast(actor,NAME,lifetime+10)
				current,owned=cast,cast
				api.LastCast=cast;api.LastSelectedPlayer=selected;api.Copies={}
				api.Swaps,api.Rushes,api.Explosions,api.Swings,api.Dodges=0,0,0,0,0
				Cooldowns.Start(actor,NAME,api.Cooldown)
				local root=source.HumanoidRootPart
				local original,anchored=root.CFrame,root.Anchored
				local captured=false
				local connections={}
				local token=NAME..":"..tostring(cast.realBorn)
				local fx=CreateVisuals(core,actor)
				local function valid()
					return cast:Alive() and actor.Parent and core.Alive(actor)
						and math.floor(actor:GetAttribute("Phase") or 1) == 3 and not actor:GetAttribute("EncounterEnded")
						and not actor:GetAttribute("PhaseTransitionInProgress")
						and (actor:GetAttribute("PhaseGeneration") or 0)==generation
						and selected.Parent==Players and selected.Character==source and core.Alive(source)
				end
				local function release(destination)
					if not captured then return end
					captured=false
					Encounter.SetDamageGate(source,cast,false)
					Status.SetLocked(selected,cast,false)
					if source:GetAttribute("PlayerCloneCaptureToken")==token then
						source:SetAttribute("PlayerCloneCaptured",nil);source:SetAttribute("PlayerCloneCaptureToken",nil)
						if root.Parent then
							local safe=Placement.ResolveRecorded(source,destination or original,{Margin=8})
							if safe then source:PivotTo(safe) end
							root.Anchored=anchored
							root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
						end
					end
				end
				cast.OnDispose=function()
					release()
					for _,connection in ipairs(connections) do connection:Disconnect() end
					for _,copy in ipairs(api.Copies) do if copy.Model.Parent then copy.Model:Destroy() end end
					if current==cast then
						current=nil;api.LiveCopies=0
						actor:SetAttribute("PlayerCloneActive",false)
						actor:SetAttribute("PlayerCloneEndsAt",0)
					end
				end
				captured=true
				source:SetAttribute("PlayerCloneCaptured",true);source:SetAttribute("PlayerCloneCaptureToken",token)
				Dash.Cancel(selected,NAME)
				Status.SetLocked(selected,cast,true)
				Encounter.SetDamageGate(source,cast,true)
				root.Anchored=true
				actor:SetAttribute("AttackState","Player Clone: lifting the original")
				actor:SetAttribute("PlayerCloneActive",true)
				Encounter.Say("One of you was troublesome enough. Let's make a few more.",nil,{Duration=4})
				core.Face(source);core.PoseAngles({RightShoulder={100,0,-25},LeftShoulder={100,0,25}},0.2)
				local started=cast:Now()
				repeat
					if not valid() or Status.IsDebuffImmune(source) then return false end
					local t=math.clamp((cast:Now()-started)/2,0,1)
					source:PivotTo(original+Vector3.new(0,32*(1-(1-t)^3),0))
					if t>=1 then break end
					Run.Heartbeat:Wait()
				until false
				fx.Burst(root.Position,15,"PlayerCloneSkyExplosion")
				local count=random:NextInteger(3,5)
				local ground=Placement.GroundPoint(original.Position,{Margin=8,Clamp=true})
				if not ground then return false end
				local candidates={}
				for i=1,count+1 do
					local angle=i*math.pi*2/(count+1)
					local at=ground+Vector3.new(math.cos(angle)*22,3,math.sin(angle)*22)
					local frame=Placement.Validate(source,CFrame.new(at),{Margin=8})
						or Placement.Random(source,random,{Margin=12,MinDistance=15})
					if frame then candidates[#candidates+1]=frame end
				end
				if #candidates<count+1 then return false end
				for i=1,count do
					local copy=Appearance.Create(source,candidates[i])
					if copy then
						local floor=Placement.GroundPoint(copy.Root.Position,{Clamp=true,Margin=8})
						copy.Height=floor and copy.Root.Position.Y-floor.Y or 3
						api.Copies[#api.Copies+1]=copy
						fx.Burst(copy.Root.Position,4,"PlayerCloneArrival")
					end
				end
				if #api.Copies<3 then return false end
				release(candidates[#candidates])
				api.LiveCopies=#api.Copies;api.InitialCopyCount=#api.Copies
				local expiresAt=workspace:GetServerTimeNow()+lifetime
				api.ExpiresAt=expiresAt
				actor:SetAttribute("PlayerCloneEndsAt",expiresAt)
				actor:SetAttribute("AttackState","Player Clone: find the original")
				StartBehavior({Actor=actor,Cast=cast,Core=core,Player=selected,Character=source,
					Copies=api.Copies,Visuals=fx,Api=api,Connections=connections,Valid=valid,ExpiresAt=expiresAt})
				spawned=true
				return true
			end)
		end,debug.traceback)
		if owned and not spawned and not owned.closed then owned:Dispose() end
		if not ok then warn(NAME..": "..tostring(result));return false end
		return result
	end
	function api.Dispose()
		if current then current:Dispose() end
	end
	return api
end