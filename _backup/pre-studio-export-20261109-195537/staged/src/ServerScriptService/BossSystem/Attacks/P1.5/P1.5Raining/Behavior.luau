local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
 
 
 
 
local TweenService = game:GetService("TweenService")

return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local ownerReference = actor:FindFirstChild("EncounterOwner")
	local owner = ownerReference and ownerReference:IsA("ObjectValue") and ownerReference.Value or actor
	local ownerHumanoid = owner:FindFirstChildOfClass("Humanoid")
	local random = Random.new()
	local gold = Style.gold
	local bright = Style.bright
	local deep = Style.deep
	local white = Style.white
	local TAU, HALF_PI = math.pi * 2, math.pi * 0.5
	local OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local api = {}
	local rainCast

	 
	local TIP_RIGHT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0))
	local TIP_LEFT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0))
	local SWORD_REACH = 13  

	local function encounterAlive()
		return owner.Parent and ownerHumanoid and ownerHumanoid.Health > 0 and not owner:GetAttribute("EncounterEnded")
	end
	local part = Visuals.part({
		core = core,
	})
	 
	local disk = Visuals.disk({
		part = part,
		HALF_PI = HALF_PI,
	})

	 
	api.CreateSword = Visuals.CreateSword({
		part = part,
		gold = gold,
		TIP_RIGHT = TIP_RIGHT,
		TIP_LEFT = TIP_LEFT,
		white = white,
		bright = bright,
		deep = deep,
		HALF_PI = HALF_PI,
		Effects = Effects,
	})

	 
	function api.Drop(position, delay, debuffKey)
		local radius = actor:GetAttribute("RainingImpactRadius") or 9
		local warning = delay or actor:GetAttribute("RainingWarningTime") or 0.9
		local height = actor:GetAttribute("RainingSwordHeight") or 85
		local cast = Effects.NewCast(actor, "GoldenSwordRainDrop", warning + 0.3 + 0.85)

		 
		local marker = disk(cast, "GoldenRainWarning", position, 0.12, radius * 2, 0.16, gold, 0.55)
		local rim = disk(cast, "GoldenRainWarningRim", position, 0.08, radius * 2 + 1.4, 0.14, bright, 0.35)
		local fill = disk(cast, "GoldenRainWarningFill", position, 0.16, radius * 0.2, 0.18, bright, 0.5)
		 
		local beamHeight = height + 20
		local beam = part(
			cast,
			"GoldenRainWarningBeam",
			CFrame.new(position + Vector3.new(0, beamHeight * 0.5, 0)),
			Vector3.new(0.28, beamHeight, 0.28),
			bright,
			0.55
		)
		Audio.Emit(actor, "RainWarn", position)

		local sword = api.CreateSword(cast, 1, false)
		cast.OnDispose = function()
			sword:Cleanup()
		end
		local function swordCenter(drop)
			return position + Vector3.new(0, SWORD_REACH + drop, 0)
		end
		sword:Draw(CFrame.new(swordCenter(height)), 0)

		local falling = false
		local began = cast:Now()

		local impactFx = Visuals.impactFx({
			part = part,
			cast = cast,
			position = position,
			bright = bright,
			Effects = Effects,
			OUT = OUT,
			radius = radius,
			disk = disk,
			gold = gold,
			HALF_PI = HALF_PI,
			TAU = TAU,
			random = random,
			TweenService = TweenService,
		})

		local function impact()
			Audio.Emit(actor, "RainImpact", position)
			for _, char in ipairs(core.Characters()) do
				if core.Alive(char) then
					local offset = char.HumanoidRootPart.Position - position
					if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius and offset.Y >= -2 and offset.Y <= 10 then
						if core.Damage(char, actor:GetAttribute("RainingSwordDamage") or 12,"P1.5Raining")>0 and debuffKey then AttackDebuffs.Apply(actor,char,"Bleed",3,debuffKey) end
					end
				end
			end
			impactFx()
			actor:SetAttribute("RainingSwordImpacts", (actor:GetAttribute("RainingSwordImpacts") or 0) + 1)
		end

		cast:Step(function(_, now)
			if not encounterAlive() then
				cast:Dispose()
				return false
			end
			local elapsed = now - began
			if not falling then
				local p = math.clamp(elapsed / warning, 0, 1)
				marker.Transparency = 0.5 + 0.12 * math.sin(elapsed * 13)
				rim.Transparency = 0.3 + 0.15 * math.sin(elapsed * 13 + 1.5)
				local d = math.max(0.4, radius * 2 * p)
				fill.Size = Vector3.new(0.18, d, d)
				fill.Transparency = 0.5 - 0.38 * p
				beam.Transparency = 0.5 + 0.2 * math.sin(elapsed * 18)
				 
				local spin = TAU * 2 * (1 - (1 - p) ^ 3)
				local hover = math.sin(elapsed * 3.4) * 1.1 * (1 - p)
				sword:Draw(CFrame.new(swordCenter(height + hover)) * CFrame.Angles(0, spin, 0), 0)
				if elapsed < warning then
					return true
				end
				falling = true
				Audio.Emit(actor, "RainFall", position)
			end
			local t = math.clamp((elapsed - warning) / 0.3, 0, 1)
			sword:Draw(CFrame.new(swordCenter(height * (1 - t * t))), t * 40)
			beam.Transparency = 0.75 + 0.25 * t
			if t >= 1 then
				Effects.Release(marker)
				Effects.Release(rim)
				Effects.Release(fill)
				Effects.Release(beam)
				 
				local embedded = CFrame.new(swordCenter(-1.4))
				sword:Draw(embedded, 0)
				sword:Sink(embedded * CFrame.new(0, -3.5, 0), 0.6)
				impact()
				return false
			end
			return true
		end)
		actor:SetAttribute("RainingSwordsReleased", (actor:GetAttribute("RainingSwordsReleased") or 0) + 1)
		return { Cast = cast, Position = position, Radius = radius, WarningTime = warning }
	end

	 
	api.SummonAura = Visuals.SummonAura({
		core = core,
		Effects = Effects,
		actor = actor,
		disk = disk,
		gold = gold,
		bright = bright,
		part = part,
		HALF_PI = HALF_PI,
		api = api,
		encounterAlive = encounterAlive,
		TAU = TAU,
	})

	 
	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5
			and core.Active()
			and core.Alive(character)
			and (not rainCast or rainCast.closed)
	end
	local function releaseRain(character)
		local count = math.clamp(actor:GetAttribute("RainingSwordCount") or Config.RainingSwordCount, 24, 80)
		local interval = math.max(0.04, Config.RainingSwordInterval)
		local generation = owner:GetAttribute("PhaseGeneration") or 0
		local recent = {}
		local cast = Effects.NewCast(actor, "GoldenSwordRainDirector", count * interval + 0.1)
		rainCast = cast
		actor:SetAttribute("LastRainingSwordCount", count)
		actor:SetAttribute("RainingActive", true)
		cast.OnDispose = function()
			if rainCast == cast then
				rainCast = nil
				if actor.Parent then
					actor:SetAttribute("RainingActive", false)
				end
			end
		end
		local function release(index)
			if
				not encounterAlive()
				or (owner:GetAttribute("PhaseGeneration") or 0) ~= generation
				or owner:GetAttribute("PhaseTransitionInProgress")
			then
				cast:Dispose()
				return
			end
			local position
			for attempt = 1, 10 do
				local candidate
				if attempt == 1 and index % 5 == 1 and core.Alive(character) then
					local angle = random:NextNumber(0, math.pi * 2)
					local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * random:NextNumber(10, 40)
					candidate = Placement.GroundPoint(character.HumanoidRootPart.Position + offset, { Margin = 12 })
				else
					local point = Placement.RandomPosition(owner, 12, random)
					candidate = point and Placement.GroundPoint(point, { Margin = 12 })
				end
				if candidate then
					local clear = true
					for _, previous in ipairs(recent) do
						if (candidate - previous).Magnitude < 19 then
							clear = false
							break
						end
					end
					if clear then
						position = candidate
						break
					end
				end
			end
			if position then
				api.Drop(position,nil,cast)
				table.insert(recent, position)
				if #recent > 18 then
					table.remove(recent, 1)
				end
			end
		end
		 
		 
		for index = 1, count do
			cast:Schedule((index - 1) * interval, function()
				release(index)
			end)
		end
		actor:SetAttribute("RainingReleasedAt", workspace:GetServerTimeNow())
		return cast
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return require(BossSystem.Boss.GoldenGuardService).Run(actor, function()
			return core.Perform(character, "P1.5Raining", function()
				core.Melee.MovementRevision = nil  
				core.Face(character)
				core.Melee.Pose("Windup3", 0.18)
				actor:SetAttribute("AttackState", "Raining: summoning sky blades")
				Audio.Emit(actor, "RainSummon", core.Root)
				actor:SetAttribute("RainingSummonStartedAt", workspace:GetServerTimeNow())
				local summonDuration = Config.RainingSummonDuration or 1.5
				local aura = api.SummonAura(summonDuration)
				local finished = core.WaitFor(summonDuration)
				aura:Dispose()
				if not finished then
					return false
				end
				releaseRain(character)
				return true
			end)
		end)
	end
	function api.Dispose()
		 
	end
	return api
end
