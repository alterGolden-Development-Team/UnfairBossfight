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
	local GOLD = Style.GOLD
	local WHITE = Style.WHITE
	local ORANGE = Style.ORANGE
	local TAU = math.pi * 2
	local CHARGE = 0.35  
	local api = {}

	local solid = Visuals.solid({
		Effects = Effects,
		Runtime = Runtime,
	})
	local muzzlePoint = Visuals.muzzlePoint({
		actor = actor,
		core = core,
	})

	 
	local startCharge = Visuals.startCharge({
		Effects = Effects,
		actor = actor,
		CHARGE = CHARGE,
		solid = solid,
		WHITE = WHITE,
		GOLD = GOLD,
		Debris = Debris,
		muzzlePoint = muzzlePoint,
		core = core,
		TAU = TAU,
		ORANGE = ORANGE,
	})

	function api.CanUse(target)
		return (actor:GetAttribute("Phase") or 1) >= 2
			and core.Active()
			and core.Alive(target)
			and Projectiles.Capacity(actor, "Golden") >= 8
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, "P2GoldenBullets", function()
			core.Melee.MovementRevision = nil
			core.Face(target)
			core.PoseAngles(
				{
					LeftShoulder = { 90, -15, -25 },
					LeftElbow = { 12, 0, 0 },
					RightShoulder = { 15, 0, 0 },
					RightElbow = {
						60,
						0,
						0,
					},
				},
				0.12
			)
			actor:SetAttribute("AttackState", "Golden Bullets: raised hand")
			local charge = startCharge()
			local lockedDirection, lockedOrigin
			local warned, corrupted = core.WaitForTelegraph("P2GoldenBullets", CHARGE, {
				Shape = "Cone",
				Valid = function()
					return core.Active() and core.Alive(target)
				end,
				Geometry = function()
					local hand = actor:FindFirstChild("Left Arm")
					local origin = lockedOrigin
						or (hand and hand.Position or core.Root.Position + Vector3.new(0, 1, 0))
							+ core.Root.CFrame.LookVector * 2
					local direction = lockedDirection or target.HumanoidRootPart.Position - origin
					if direction.Magnitude < 0.01 then
						direction = core.Root.CFrame.LookVector
					end
					return { Origin = origin, Direction = direction.Unit, Length = 80, Spread = 0.17, Width = 0.22 }
				end,
				Reveal = function(geometry)
					lockedOrigin = geometry.Origin
					lockedDirection = geometry.Direction
				end,
			})
			if not warned or not core.Alive(target) then
				charge.Release(false)
				return false
			end
			charge.Release(true)
			for index = 1, Config.GoldenBulletBurstCount do
				if not core.Active() or not core.Alive(target) then
					return false
				end
				 
				core.Face(target)
				local hand = actor:FindFirstChild("Left Arm")
				local origin = (hand and hand.Position or core.Root.Position + Vector3.new(0, 1, 0))
					+ core.Root.CFrame.LookVector * 2
				local burst = Projectiles.Burst(actor, target, {
					Kind = "Golden",
					Count = Config.GoldenBulletCount,
					VolleyCue = "GoldenBulletWave",
					Origin = index == 1 and corrupted and lockedOrigin or origin,
					PreparedAim = index == 1 and corrupted and lockedOrigin + lockedDirection * 80 or nil,
				})
				if not burst then
					return false
				end
				actor:SetAttribute("GoldenBulletBursts", (actor:GetAttribute("GoldenBulletBursts") or 0) + 1)
				actor:SetAttribute("AttackState", "Golden Bullets: burst " .. index)
				if index < Config.GoldenBulletBurstCount and not core.WaitFor(Config.GoldenBulletBurstInterval) then
					return false
				end
			end
			return core.WaitFor(0.18)
		end)
	end
	function api.Dispose() end  
	return api
end
