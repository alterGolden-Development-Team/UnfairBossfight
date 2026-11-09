local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local Locomotion = require(script.Parent.Locomotion)
local Tactics = require(script.Parent.Tactics)
local B = script:FindFirstAncestor("BossSystem")
local Players = game:GetService("Players")
local Placement = require(B.Encounter.ArenaPlacement)
local Status = require(B.Combat.StatusEffectService)
local Encounter = require(B.Players.PlayerEncounter)
local Registry = require(B.Combat.AttackRegistry)
local Taunt=require(B.Combat.TauntService)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
return function(ctx)
	local actor, cast, core, selected, source = ctx.Actor, ctx.Cast, ctx.Core, ctx.Player, ctx.Character
	local copies, fx, api = ctx.Copies, ctx.Visuals, ctx.Api
	local random = Random.new()
	local damage = Registry.For(actor, "BossDamageService")
	local nextSwap = workspace:GetServerTimeNow() + (Config.P3PlayerCloneSwapInterval or 6)
	local function alive(c)
		if Observer.IsCharacter(c) then
			return false
		end
		local h = c and c:FindFirstChildOfClass("Humanoid")
		return c and c.Parent and h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
	end
	local function players()
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if alive(p.Character) and not Encounter.IsDefeated(p) then
				table.insert(list, p)
			end
		end
		return list
	end
	local function safePlayer(p)
		local c = p.Character
		return alive(c)
			and not c.HumanoidRootPart.Anchored
			and not Status.IsLocked(p)
			and not c:GetAttribute("EtherealOrbitActive")
			and not c:GetAttribute("PickThePupilsCaptured")
			and not c:GetAttribute("PlayerCloneCaptured")
			and not p:GetAttribute("ExecutionPending")
	end
	local function permitted(p)
		if not safePlayer(p) then
			return false
		end
		return p ~= selected or #players() == 1 or Taunt.Target(actor)==p.Character
	end
	local function explode(copy)
		if copy.Gone then
			return
		end
		copy.Gone = true
		local at = copy.Root.Position
		fx.Burst(at, Config.P3PlayerCloneExplosionRadius or 12)
		for _, p in ipairs(players()) do
			if
				(p.Character.HumanoidRootPart.Position - at).Magnitude <= (Config.P3PlayerCloneExplosionRadius or 12)
			then
				core.Damage(p.Character, Config.P3PlayerCloneExplosionDamage or 25, "P3PlayerClone")
			end
		end
		copy.Model:Destroy()
		api.Explosions = (api.Explosions or 0) + 1
	end
	local function rush(copy, p)
		local now = workspace:GetServerTimeNow()
		if copy.Gone or copy.Target or now < (copy.ArmedAt or 0) or not permitted(p) then
			return
		end
		copy.Target = p
		copy.RushAt = now
		copy.Model:SetAttribute("PlayerCopyRushing", true)
		copy.Prompt.Enabled = false
		api.Rushes = (api.Rushes or 0) + 1
	end
	for i, copy in ipairs(copies) do
		copy.Index = i
		copy.ArmedAt = workspace:GetServerTimeNow() + 3
		copy.NextSwing = workspace:GetServerTimeNow() + 0.7 + i * 0.18
		copy.DodgeReady = 0
		copy.Angle = i * math.pi * 2 / #copies
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PlayerCopyInteract"
		prompt.ActionText = "Interact"
		prompt.ObjectText = selected.DisplayName
		prompt.MaxActivationDistance = Config.P3PlayerCloneTriggerRadius or 10
		prompt.RequiresLineOfSight = true
		prompt.HoldDuration = 0.2
		prompt.Parent = copy.Root
		copy.Prompt = prompt
		local connection = prompt.Triggered:Connect(function(p)
			if
				not copy.Gone
				and p.Character
				and p.Character:FindFirstChild("HumanoidRootPart")
				and (p.Character.HumanoidRootPart.Position - copy.Root.Position).Magnitude
					<= prompt.MaxActivationDistance + 1
			then
				rush(copy, p)
			end
		end)
		ctx.Connections[#ctx.Connections + 1] = connection
	end
	local function swap(now)
		if not safePlayer(selected) or Status.IsDebuffImmune(source) then
			return
		end
		local available = {}
		for _, c in ipairs(copies) do
			if not c.Gone and not c.Target then
				table.insert(available, c)
			end
		end
		if #available == 0 then
			return
		end
		local copy = available[random:NextInteger(1, #available)]
		local playerFrame = Placement.Validate(source, copy.Root.CFrame, { Margin = 8 })
		local copyFrame = Placement.Validate(copy.Model, source:GetPivot(), { Margin = 8 })
		if not playerFrame or not copyFrame then
			return
		end
		fx.Swap(source.HumanoidRootPart.Position, copy.Root.Position)
		source:PivotTo(playerFrame)
		copy.Model:PivotTo(copyFrame)
		source.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		source.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
		for _, c in ipairs(copies) do
			c.ArmedAt = now + 2
		end
		api.Swaps = (api.Swaps or 0) + 1
	end
	local accum = 0
	cast:Step(function(dt)
		if not ctx.Valid() or selected.Character ~= source or not alive(source) then
			cast:Dispose()
			return false
		end
		local now = workspace:GetServerTimeNow()
		if now >= ctx.ExpiresAt then
			cast:Dispose()
			return false
		end
		accum += dt
		if accum < 0.035 then
			return true
		end
		local step = math.min(accum, 0.1)
		accum = 0
		 
		if actor:GetAttribute("PickThePupilsActive") or actor:GetAttribute("EtherealAcumenActive") then
			nextSwap = now + Config.P3PlayerCloneSwapInterval
			for _, c in ipairs(copies) do
				c.ArmedAt = now + 2
			end
			return true
		end
		local live = players()
		for _, copy in ipairs(copies) do
			if not copy.Gone and copy.Model.Parent then
				local taunted=Taunt.Target(copy.Model)
    local defender=taunted and Players:GetPlayerFromCharacter(taunted)
    if defender and permitted(defender) and copy.Target~=defender and now>=copy.ArmedAt then
     copy.Target=nil rush(copy,defender)
    end
    if not copy.Target and now >= copy.ArmedAt then
					for _, p in ipairs(live) do
						if permitted(p) then
							local pr = p.Character.HumanoidRootPart
							local nearCopy = (pr.Position - copy.Root.Position).Magnitude
								<= (Config.P3PlayerCloneTriggerRadius or 10)
							local nearSource = p ~= selected
								and (pr.Position - source.HumanoidRootPart.Position).Magnitude
									<= (Config.P3PlayerCloneTriggerRadius or 10)
							if nearCopy or nearSource then
								rush(copy, p)
								break
							end
						end
					end
				end
				local position = copy.Root.Position
				local bossPosition = core.Root.Position
				local goal, speed, dodging
				if copy.Target then
					if not permitted(copy.Target) then
						copy.Target = nil
						copy.Prompt.Enabled = true
						copy.Model:SetAttribute("PlayerCopyRushing", false)
					else
						local targetRoot = copy.Target.Character.HumanoidRootPart
						local lead = targetRoot.AssemblyLinearVelocity * 0.18
						if lead.Magnitude > 8 then
							lead = lead.Unit * 8
						end
						goal = targetRoot.Position + Vector3.new(lead.X, 0, lead.Z)
						speed = Config.P3PlayerCloneRushSpeed or 48
						if
							now - copy.RushAt > 0.25
							and ((targetRoot.Position - position).Magnitude < 4 or now - copy.RushAt > 2.5)
						then
							explode(copy)
						end
					end
				end
				if not copy.Gone and not goal then
					goal, speed, dodging = Tactics.Update(
						copy,
						{ Actor = actor, Core = core, Api = api, Damage = damage, SwordDamage = Config.P3PlayerCloneSwordDamage
							or 4 },
						now
					)
				end
				if not copy.Gone and goal then
					local focus = copy.SwingAt and bossPosition or nil
					local actualSpeed = Locomotion.Step(copy, goal, speed, step, core, copies, focus)
					local swing = copy.SwingAt and math.clamp((now - copy.SwingAt) / 0.48, 0, 1) or nil
					copy.Pose(step, actualSpeed, swing, dodging)
				end
			end
		end
		if now >= nextSwap then
			nextSwap = now + (Config.P3PlayerCloneSwapInterval or 6)
			swap(now)
		end
		local count = 0
		for _, copy in ipairs(copies) do
			if not copy.Gone and copy.Model.Parent then
				count += 1
			end
		end
		api.LiveCopies = count
		if count == 0 then
			cast:Dispose()
			return false
		end
		return true
	end)
end
