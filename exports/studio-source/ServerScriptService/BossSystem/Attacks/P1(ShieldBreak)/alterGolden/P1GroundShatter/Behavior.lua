local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)

 -- every player gets a warning circle at their feet; after the warning, gold spikes burst out of
 -- each circle (VFXEngine.Effects.GroundShatter draws them) and hit whoever is still inside
return function(actor)
	return Shared.Skill(actor, "alterGolden", "P1GroundShatter", Config.P1ShieldGateBossInterval or 8, function(ctx)
		local targets = ctx.Targets()
		if #targets == 0 then
			return false
		end
		local radius = Config.P1GroundShatterRadius or 8
		local warning = Config.P1GroundShatterWarning or 0.6
		local reach = Config.P1GroundShatterHeight or 9
		local cast = ctx.Cast("P1GroundShatter", warning + 1.5)
		local points = {}
		for _, char in ipairs(targets) do
			local position = char.HumanoidRootPart.Position
			points[#points + 1] = Placement.GroundPoint(position, { Clamp = true }) or position - Vector3.new(0, 3, 0)
		end
		ctx.Core.PoseAngles({ RightShoulder = { 165, 0, -15 }, LeftShoulder = { 150, 0, 15 }, Waist = { -6, 0, 0 } }, warning * 0.7)
		Net.Send("GroundShatter", "Warn", { Points = points, Radius = radius, Time = warning })
		if not ctx.Wait(warning) then
			cast:Dispose()
			return false
		end
		ctx.Core.PoseAngles({ RightShoulder = { 40, 0, -20 }, LeftShoulder = { 30, 0, 20 }, Waist = { 10, 0, 0 } }, 0.08)
		Net.Send("GroundShatter", "Erupt", { Points = points, Radius = radius, Seed = math.random(1, 1e6) })
		ctx.Core.ScreenEffect("Shake", { Intensity = 0.35, Duration = 0.25 })
		for _, char in ipairs(ctx.Targets()) do
			local position = char.HumanoidRootPart.Position
			for _, point in ipairs(points) do
				local flat = Vector3.new(position.X - point.X, 0, position.Z - point.Z)
				local rise = position.Y - point.Y
				if flat.Magnitude <= radius and rise >= -2 and rise <= reach then
					if ctx.Damage(char, Config.P1GroundShatterDamage or 45, "P1GroundShatter") > 0 then
						Runtime.Knockback(actor, char, flat.Magnitude > 0.1 and flat or Vector3.zAxis, {
							Speed = 8, Lift = Config.P1GroundShatterLift or 38, Duration = 0.25, Sustain = 0.05,
							AllowPlayerControl = true, ContainsArena = true,
						})
					end
					break  -- one hit per player, even where circles overlap
				end
			end
		end
		actor:SetAttribute("P1GroundShatterCasts", (actor:GetAttribute("P1GroundShatterCasts") or 0) + 1)
		ctx.Wait(0.35)
		cast:Dispose()
		return true
	end)
end
