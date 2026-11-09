local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
return function(actor)
	return Shared.Skill(actor, "alterGolden", "P1Sniping", Config.P1ShieldGateBossInterval or Config.P1SnipingCooldown, function(ctx)
		local targets = ctx.Targets()
		local target = targets[math.random(1, #targets)]
		local aimDuration = Config.P1SnipingAimDuration
		local cast = ctx.Cast("P1Sniping", aimDuration + 1.6)
		local view = Visuals.Create(ctx, cast)
		local aim = target.HumanoidRootPart.Position
		local muzzle
		local firing = false
		local started = os.clock()
		local function aimRifle()
			if not ctx.Core.Alive(target) then
				return false
			end
			aim = target.HumanoidRootPart.Position
			local charge = math.clamp((os.clock() - started) / aimDuration, 0, 1)
			muzzle = Visuals.Aim(ctx, cast, view, aim, charge, target)
			return muzzle ~= false and muzzle ~= nil
		end
		ctx.Core.PoseAngles({ RightShoulder = { 85, 0, -20 }, LeftShoulder = { 80, 0, 30 } }, 0.15)
		if not aimRifle() then
			cast:Dispose()
			return false
		end
		cast:Step(function()
			if firing then
				return false
			end
			if not aimRifle() then
				cast:Dispose()
				return false
			end
			return true
		end)
		if not ctx.Wait(aimDuration) or not cast:Alive() or not aimRifle() then
			cast:Dispose()
			return false
		end
		firing = true
		local direction = (aim - muzzle).Unit
		local finish, hit = ctx.Sweep(muzzle, direction * Config.P1SnipingRange, 2)
		 
		local shot = ctx.Cast("P1SnipingShot", 2)
		Visuals.Fire(ctx, cast, shot, view, muzzle, finish, direction, hit)
		ctx.Core.PoseAngles({ RightShoulder = { 105, 0, -15 }, LeftShoulder = { 95, 0, 30 } }, 0.05)
		if hit then
			if ctx.Damage(hit, Config.P1SnipingDamage, "P1Sniping")>0 then AttackDebuffs.Apply(actor,hit,"Vulnerability",3,cast) end
		end
		actor:SetAttribute("P1SnipingShots", (actor:GetAttribute("P1SnipingShots") or 0) + 1)
		cast:Schedule(0.45, function()
			Visuals.Dissolve(ctx, cast, view, 0.35)
		end)
		cast:Schedule(0.9, function()
			cast:Dispose()
		end)
		ctx.Wait(0.35)
		return true
	end)
end
