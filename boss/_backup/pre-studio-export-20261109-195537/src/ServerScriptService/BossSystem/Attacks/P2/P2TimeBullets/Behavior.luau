local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Effects = require(BossSystem.Combat.EffectService)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Debris = game:GetService("Debris")
	local TIME = Style.TIME
	local WHITE = Style.WHITE
	local GOLD = Style.GOLD
	local DEEP = Style.DEEP
	local TAU = math.pi * 2
	local api = {}

	local solid = Visuals.solid({
		Effects = Effects,
		Runtime = Runtime,
	})
	local groundUnder = Visuals.groundUnder({
		core = core,
	})

	 
	local startSigil = Visuals.startSigil({
		core = core,
		groundUnder = groundUnder,
		Config = Config,
		Effects = Effects,
		actor = actor,
		solid = solid,
		TIME = TIME,
		GOLD = GOLD,
		WHITE = WHITE,
		Debris = Debris,
		TAU = TAU,
	})

	function api.CanUse(target)
		return (actor:GetAttribute("Phase") or 1) >= 2
			and core.Active()
			and core.Alive(target)
			and Projectiles.Capacity(actor, "Time") >= 6
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, "P2TimeBullets", function()
			core.Melee.MovementRevision = nil
			core.Face(target)
			core.Melee.Pose("Windup3", 0.18)
			actor:SetAttribute("AttackState", "Time Bullets: winding the clock")
			local charge = Config.TimeBulletChargeTime or 0.55
			local sigil = startSigil(charge)
			if not core.WaitFor(charge) then
				sigil.Release(false)
				return false
			end
			actor:SetAttribute("AttackState", "Time Bullets: summoning clock barrage")
			sigil.Release(true)
			local debuffHits={}
   local burst = Projectiles.Burst(actor, target, {
				Kind = "Time",
    Skill = "P2TimeBullets",
    OnHit = function(character) AttackDebuffs.Apply(actor,character,"TemporalWound",6,debuffHits) end,
				Count = Config.TimeBulletCount,
				ShotCue = "TimeBulletShot",
				SummonTime = Config.TimeBulletSummonTime or 0.35,
			})
			if not burst then
				return false
			end
			actor:SetAttribute("TimeBulletBursts", (actor:GetAttribute("TimeBulletBursts") or 0) + 1)
			core.Melee.Pose("Slash3", 0.15)
			return core.WaitFor(1.3)
		end)
	end
	function api.Dispose() end  
	return api
end
