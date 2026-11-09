local script = script.Parent
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local core = Registry.For(actor, "P1CombatCore")
	local random, api = Random.new(), {}
	local GOLD, BRIGHT = Style.GOLD, Style.BRIGHT

	local flash = Visuals.flash({
		Placement = Placement,
		Effects = Effects,
		BRIGHT = BRIGHT,
		Runtime = Runtime,
		GOLD = GOLD,
	})
	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and core.Active()
			and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		 
		 
		local goal = Placement.Random(actor, random, { Margin = 7, MinDistance = Difficulty.Design("Teleportation", "MinDistance", 18, actor) })
		if not goal then
			return false
		end
		return core.Perform(character, "P1.5Teleportation", function()
			actor:SetAttribute("AttackState", "Teleportation: gathering light")
			Audio.Emit(actor, "TeleportOut", core.Root)
			core.Melee.Pose("Windup", 0.08)
			if not core.WaitFor(Difficulty.Design("Teleportation", "Windup", 0.16, actor)) or not core.Alive(character) then
				return false
			end
			 
			if Difficulty.Design("Teleportation", "Ambush", false, actor) then
				local behind = character.HumanoidRootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, 7))
				local ambush = Placement.Validate(actor, CFrame.new(behind.X, goal.Y, behind.Z), { Margin = 7 })
				if ambush then
					goal = ambush
					actor:SetAttribute("TeleportAmbush", true)
				end
			end
			goal = Placement.Validate(actor, goal, { Margin = 7 })
			if not goal then
				return false
			end
			local old = core.Root.CFrame
			local target = character.HumanoidRootPart.Position
			local flatTarget = Vector3.new(target.X, goal.Y, target.Z)
			if (flatTarget - goal.Position).Magnitude > 0.01 then
				goal = CFrame.lookAt(goal.Position, flatTarget)
			end
			local cast = Effects.NewCast(actor, "TeleportationFlash", 0.5)
			flash(old, "TeleportDeparture", cast)
			Audio.Emit(actor, "TeleportWarp", old.Position)
			core.Root.AssemblyLinearVelocity = Vector3.zero
			core.Root.AssemblyAngularVelocity = Vector3.zero
			core.Root.CFrame = goal
			flash(goal, "TeleportArrival", cast)
			Audio.Emit(actor, "TeleportIn", goal.Position)
			actor:SetAttribute("TeleportsCompleted", (actor:GetAttribute("TeleportsCompleted") or 0) + 1)
			actor:SetAttribute("LastTeleportPosition", goal.Position)
			actor:SetAttribute("AttackState", "Teleportation: arrived")
			return true
		end)
	end
	return api
end
