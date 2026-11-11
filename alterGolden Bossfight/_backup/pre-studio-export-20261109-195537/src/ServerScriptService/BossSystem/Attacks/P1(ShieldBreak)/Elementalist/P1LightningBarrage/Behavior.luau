local script = script.Parent
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Control = require(BossSystem.Attacks.Shared.ShieldBreakControl)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local function opt(name, default)
	local value = Config[name]
	if value == nil then
		return default
	end
	return value
end

 
 
 
 
local RANGE_SCALE = opt("P1LightningRangeScale", 1.6)  
local COVER_BLOCKS = opt("P1LightningCoverBlocks", true)  
local DAMAGE_SCALE = opt("P1LightningDamageScale", 1.4)  
local FINISHER_SCALE = opt("P1LightningFinisherScale", 2.5)  

local function rootOf(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

 
 
local function damageFor(initial, final)
	local amount = (initial and Config.P1LightningInitialDamage or Config.P1LightningTickDamage) * DAMAGE_SCALE
	if final then
		amount *= FINISHER_SCALE
	end
	return math.floor(amount + 0.5)
end

return function(actor)
	return Shared.Skill(actor, "Elementalist", "P1LightningBarrage", Config.ShieldGateCloneAttackInterval, function(ctx)
		local duration = Config.P1LightningDuration
		local radius = Config.P1LightningRadius * RANGE_SCALE
		local windup = opt("P1LightningWindup", 0.45)
		local shell = opt("P1LightningShell", false)
		local ticks = Config.P1LightningTicks
		local total = windup + duration
		local cast = ctx.Cast("P1LightningBarrage", total + 0.15)

		local view = Visuals.Create(ctx, cast, radius, windup, total, shell)
		ctx.Core.PoseAngles({ RightShoulder = { 95, 0, -70 }, LeftShoulder = { 95, 0, 70 } }, 0.1)

		 
		local function pulse(initial, final)
			if not ctx.Valid() then
				return
			end
			local origin = ctx.Root.Position
			view.Pulse(initial, origin, final)

			local slot = 0  
			local amount = damageFor(initial, final)
			for _, char in ipairs(ctx.Targets()) do
				local root = rootOf(char)
				if root then
					local delta = root.Position - origin
					 
					if delta.Magnitude <= radius and (not COVER_BLOCKS or not workspace:Raycast(origin, delta, ctx.Filter())) then
						if ctx.Damage(char, amount, "P1LightningBarrage") > 0 then
							slot += 1
							Control.Electricify(ctx,char)
							view.Hit(char, root, origin, slot, initial, final)
						end
					end
				end
			end
		end

		if windup > 0 then
			cast:Schedule(windup, function()
				pulse(true, false)
			end)
		else
			pulse(true, false)
		end
		for tick = 1, ticks do
			local final = tick == ticks
			cast:Schedule(windup + tick * duration / ticks, function()
				pulse(false, final)
			end)
		end

		local expected = damageFor(true, false)
		for tick = 1, ticks do
			expected += damageFor(false, tick == ticks)
		end
		actor:SetAttribute("P1LightningExpectedDamage", expected)
		return ctx.Wait(total + 0.05)
	end)
end
