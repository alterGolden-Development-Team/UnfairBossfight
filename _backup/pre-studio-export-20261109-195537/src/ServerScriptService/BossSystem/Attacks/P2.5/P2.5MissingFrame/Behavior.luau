local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Players = game:GetService("Players")
	local core = Registry.For(actor, "P1CombatCore")
	local random = Random.new()
	local api = { Cooldown = Config.MissingFrameCooldown or 20 }
	local current, currentFx
	local GOLD = Style.GOLD
	local CYAN = Style.CYAN
	local HOT = Style.HOT

	local addPart = Visuals.addPart({
		Effects = Effects,
		Runtime = Runtime,
	})
	local drop = Visuals.drop({
		Effects = Effects,
	})
	local play = Visuals.play({})
	local floorY = Visuals.floorY({
		Placement = Placement,
	})

	 
	local gate = Visuals.gate({
		play = play,
		addPart = addPart,
		GOLD = GOLD,
		drop = drop,
	})
	local pulse = Visuals.pulse({
		play = play,
		addPart = addPart,
		drop = drop,
	})
	local burst = Visuals.burst({
		addPart = addPart,
		GOLD = GOLD,
		HOT = HOT,
	})
	local streak = Visuals.streak({
		play = play,
		addPart = addPart,
		HOT = HOT,
		CYAN = CYAN,
		drop = drop,
	})
	local flash = Visuals.flash({
		play = play,
		actor = actor,
		HOT = HOT,
		GOLD = GOLD,
		Runtime = Runtime,
	})
	local departure = Visuals.departure({
		gate = gate,
		HOT = HOT,
		GOLD = GOLD,
		floorY = floorY,
		pulse = pulse,
		CYAN = CYAN,
		burst = burst,
	})
	local arrival = Visuals.arrival({
		streak = streak,
		flash = flash,
		CYAN = CYAN,
		GOLD = GOLD,
		gate = gate,
		HOT = HOT,
		pulse = pulse,
		floorY = floorY,
		burst = burst,
	})

	local function phaseValid()
		local phase = tonumber(actor:GetAttribute("Phase")) or 1
		return phase >= 2.5 and phase < 3 and not actor:GetAttribute("PhaseTransitionInProgress")
	end
	function api.CanUse(character)
		local limited = actor:GetAttribute("LastMinuteActive")
			and (
				(actor:GetAttribute("LastMinuteMissingFrameCount") or 0) >= Config.MissingFrameLastMinuteMaxCasts
				or workspace:GetServerTimeNow() < (actor:GetAttribute("LastMinuteMissingFrameReadyAt") or 0)
			)
		return not limited and phaseValid() and core.Active() and core.Alive(character) and not Time.IsStopped(actor)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P2.5MissingFrame", function()
			if actor:GetAttribute("LastMinuteActive") then
				actor:SetAttribute(
					"LastMinuteMissingFrameCount",
					(actor:GetAttribute("LastMinuteMissingFrameCount") or 0) + 1
				)
				actor:SetAttribute(
					"LastMinuteMissingFrameReadyAt",
					workspace:GetServerTimeNow() + Config.MissingFrameLastMinuteSpacing
				)
			end
			local hidden = math.clamp(Config.MissingFrameHiddenDuration or 0.14, 0.08, 0.22)
			local seconds = Config.MissingFrameSkipSeconds or 3
			local cast = Effects.NewCast(actor, "MissingFramePresentation", hidden + 0.5)
			current = cast
			local fx = Effects.NewCast(actor, "MissingFrameVFX", hidden + 1.2)
			fx.TimeStopExempt = true
			currentFx = fx
			fx.OnDispose = function()
				if currentFx == fx then
					currentFx = nil
				end
			end
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local originalFrame = core.Root.CFrame
			local delta = character.HumanoidRootPart.Position - core.Root.Position
			delta = Vector3.new(delta.X, 0, delta.Z)
			if delta.Magnitude < 0.01 then
				delta = Vector3.new(originalFrame.LookVector.X, 0, originalFrame.LookVector.Z)
			end
			local direction = delta.Magnitude > 0.01 and delta.Unit or Vector3.new(0, 0, -1)
			 
			local Locomotion = require(BossSystem.Boss.BossLocomotion)
			local predicted = Locomotion.PredictMovement(actor, character, seconds)
			local movement = predicted.Position - originalFrame.Position
			local obstacle = workspace:Blockcast(
				originalFrame + Vector3.new(0, -0.2, 0),
				Vector3.new(2.4, 5.4, 2.4),
				movement,
				core.Params()
			)
			if obstacle then
				movement = direction * math.max(0, obstacle.Distance - 0.15)
			end
			local function safeGoal(candidate)
				local valid = Placement.Validate(actor, candidate, { Margin = 5 })
				if not valid then
					return nil
				end
				for _, player in ipairs(Players:GetPlayers()) do
					local target = player.Character
					local r = target and target:FindFirstChild("HumanoidRootPart")
					local h = target and target:FindFirstChildOfClass("Humanoid")
					if r and h and h.Health > 0 then
						local separation = r.Position - valid.Position
						if math.abs(separation.Y) < 7 and Vector3.new(separation.X, 0, separation.Z).Magnitude < 6 then
							return nil
						end
					end
				end
				return valid
			end
			local function resolveGoal(candidate)
				local goal = safeGoal(candidate)
				if goal then
					return goal
				end
				for fraction = 0.75, 0.0, -0.25 do
					goal = safeGoal(originalFrame + movement * fraction)
					if goal then
						return goal
					end
				end
				for _, side in ipairs({ originalFrame.RightVector * 8, -originalFrame.RightVector * 8 }) do
					if
						not workspace:Blockcast(
							originalFrame + Vector3.new(0, -0.2, 0),
							Vector3.new(2.4, 5.4, 2.4),
							side,
							core.Params()
						)
					then
						goal = safeGoal(originalFrame + side)
						if goal then
							return goal
						end
					end
				end
				return Placement.Validate(actor, originalFrame, { Margin = 5 }) or originalFrame
			end
			local goal = resolveGoal(originalFrame + movement)
			local visuals = {}
			local function restore()
				for object, prior in pairs(visuals) do
					if object.Parent then
						if object:IsA("BasePart") or object:IsA("Decal") then
							object.Transparency = prior
						elseif
							object:IsA("ParticleEmitter")
							or object:IsA("Trail")
							or object:IsA("Beam")
							or object:IsA("Light")
							or object:IsA("BillboardGui")
							or object:IsA("SurfaceGui")
						then
							object.Enabled = prior
						end
					end
				end
				table.clear(visuals)
				if actor.Parent then
					actor:SetAttribute("MissingFrameHidden", false)
				end
			end
			cast.OnDispose = function()
				restore()
				if current == cast then
					current = nil
				end
			end
			for _, object in ipairs(actor:GetDescendants()) do
				if object:IsA("BasePart") or object:IsA("Decal") then
					visuals[object] = object.Transparency
					object.Transparency = 1
				elseif
					object:IsA("ParticleEmitter")
					or object:IsA("Trail")
					or object:IsA("Beam")
					or object:IsA("Light")
					or object:IsA("BillboardGui")
					or object:IsA("SurfaceGui")
				then
					visuals[object] = object.Enabled
					object.Enabled = false
				end
			end
			actor:SetAttribute("MissingFrameHidden", true)
			local ownerReference = actor:FindFirstChild("EncounterOwner")
			local owner = ownerReference and ownerReference:IsA("ObjectValue") and ownerReference.Value or actor
			owner:SetAttribute(
				"MissingFrameDamageGraceUntil",
				math.max(
					owner:GetAttribute("MissingFrameDamageGraceUntil") or 0,
					workspace:GetServerTimeNow() + hidden + (Config.MissingFrameDamageGrace or 0.22)
				)
			)
			actor:SetAttribute("AttackState", "Missing Frame: timeline skips")
			departure(fx, originalFrame, direction, hidden)
			api.LastSkippedSeconds = seconds
			api.LastAdvancedProjectiles = Projectiles.SkipAhead(actor, seconds, hidden)
			Locomotion.AdvancePose(actor, seconds)
			local viewers = {}
			for _, player in ipairs(Players:GetPlayers()) do
				local target = player.Character
				if core.Alive(target) and not player:GetAttribute("PermanentlyDefeated") and not player:GetAttribute("ViewAsServer") then
					table.insert(viewers, player)
					core.ScreenEffect(
						"MissingFrame",
						{
							Duration = hidden,
							SkippedSeconds = seconds,
							Origin = originalFrame.Position,
							Radius = math.huge,
						},
						player
					)
				end
			end
			actor:SetAttribute("MissingFrameAffectedPlayerCount", #viewers)
			if
				not core.WaitFor(hidden)
				or not cast:Alive()
				or not phaseValid()
				or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
				or (actor:GetAttribute("MovementRevision") or 0) ~= revision
			then
				cast:Dispose()
				return false
			end
			goal = resolveGoal(goal)
			if goal then
				core.Root.CFrame = CFrame.lookAt(goal.Position, goal.Position + direction)
				core.Root.AssemblyLinearVelocity = Vector3.zero
				core.Root.AssemblyAngularVelocity = Vector3.zero
			end
			restore()
			for _, player in ipairs(viewers) do
				if player.Parent == Players then
					core.ScreenEffect("MissingFrameResume", { Origin = core.Root.Position, Radius = math.huge }, player)
				end
			end
			core.Afterimage(originalFrame)
			core.Afterimage(core.Root.CFrame)
			arrival(fx, originalFrame, core.Root.CFrame, direction)
			actor:SetAttribute("MissingFrameCasts", (actor:GetAttribute("MissingFrameCasts") or 0) + 1)
			actor:SetAttribute("LastMissingFrameSkip", seconds)
			if not core.WaitFor(0.24) then
				cast:Dispose()
				return false
			end
			cast:Dispose()
			return true
		end)
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
		if currentFx then
			currentFx:Dispose()
		end
	end
	return api
end
