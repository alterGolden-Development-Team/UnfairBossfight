local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
 
local TweenService = game:GetService("TweenService")

return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
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
	local api = { Cooldown = Style.Cooldown }
	local activeDrops = {}
	local rainCast

	 
	local TIP_RIGHT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0))
	local TIP_LEFT = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0))
	local SWORD_REACH = 13  

	local function encounterAlive()
		return owner.Parent and ownerHumanoid and ownerHumanoid.Health > 0 and not owner:GetAttribute("EncounterEnded")
			and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4 and not actor:GetAttribute("PhaseTransitionInProgress")
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

	 
	function api.Drop(position, delay)
		local radius = Style.ImpactRadius
		local warning = delay or Style.WarningTime
		local height = Style.SwordHeight
		local cast = Effects.NewCast(actor, "P4EnhancedRainDrop", warning + 0.3 + 0.85)
		local generation = actor:GetAttribute("PhaseGeneration") or 0
		activeDrops[cast] = true

		 
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
			activeDrops[cast] = nil
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
						core.Damage(char, Style.Damage, "P4EnhancedRaining")
					end
				end
			end
			impactFx()
			actor:SetAttribute("RainingSwordImpacts", (actor:GetAttribute("RainingSwordImpacts") or 0) + 1)
		end

		cast:Step(function(_, now)
			if not encounterAlive() or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
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
  return math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4 and core.Active() and core.Alive(character)
   and encounterAlive() and (not rainCast or rainCast.closed)
 end
 local function releaseRain(character)
  local generation=actor:GetAttribute("PhaseGeneration") or 0
  local cast=Effects.NewCast(actor,"P4EnhancedRainDirector",Style.Count*Style.Interval+.1)
  rainCast=cast
  api.LastDrops={}
  actor:SetAttribute("EnhancedRainingActive",true)
  actor:SetAttribute("EnhancedRainingTargetedDrops",0)
  actor:SetAttribute("EnhancedRainingNearbyDrops",0)
  cast.OnDispose=function()
   if rainCast==cast then
    rainCast=nil
    if actor.Parent then actor:SetAttribute("EnhancedRainingActive",false) end
   end
  end
  local function valid()
   return encounterAlive() and (actor:GetAttribute("PhaseGeneration") or 0)==generation
  end
  cast:Step(function()
   if not valid() then cast:Dispose();return false end
   return true
  end)
  local function release(index)
   if not valid() then cast:Dispose();return end
   local players=game:GetService("Players")
   local targets={}
   for _,c in ipairs(core.Characters()) do
    local player=players:GetPlayerFromCharacter(c)
    if player and player.Character==c and core.Alive(c)
     and not player:GetAttribute("PermanentlyDefeated")
     and not player:GetAttribute("ViewAsServer")
     and Placement.Contains(c.HumanoidRootPart.Position,8) then
     targets[#targets+1]=c
    end
   end
   if #targets==0 and core.Alive(character) then targets={character} end
   if #targets==0 then cast:Dispose();return end
   local victim=targets[(index-1)%#targets+1]
   local center=victim.HumanoidRootPart.Position
    
    
   local targeted=(math.floor((index-1)/#targets)+1)%Style.TargetEvery==0
   local candidate
   if targeted then
    candidate=Placement.GroundPoint(center,{Margin=8,Clamp=true})
   else
    for attempt=1,8 do
     local angle=random:NextNumber(0,math.pi*2)
     local radius=random:NextNumber(Style.NearMinRadius,Style.NearMaxRadius)
     local offset=Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
     candidate=Placement.GroundPoint(center+offset,{Margin=8})
     if candidate then break end
    end
    candidate=candidate or Placement.GroundPoint(center,{Margin=8,Clamp=true})
   end
   if not candidate then return end
   local drop=api.Drop(candidate,Style.WarningTime)
   drop.Targeted=targeted
   drop.Target= victim
   drop.TargetPosition=center
   api.LastDrops[#api.LastDrops+1]=drop
   local key=targeted and "EnhancedRainingTargetedDrops" or "EnhancedRainingNearbyDrops"
   actor:SetAttribute(key,(actor:GetAttribute(key) or 0)+1)
  end
  for index=1,Style.Count do
   cast:Schedule((index-1)*Style.Interval,function() release(index) end)
  end
  actor:SetAttribute("LastEnhancedRainingSwordCount",Style.Count)
  return cast
 end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return require(BossSystem.Boss.GoldenGuardService).Run(actor, function()
			return core.Perform(character, "P4EnhancedRaining", function()
				core.Melee.MovementRevision = nil  
				core.Face(character)
				core.Melee.Pose("Windup3", 0.18)
				actor:SetAttribute("AttackState", "Enhanced Raining: summoning player-focused blades")
				Audio.Emit(actor, "RainSummon", core.Root)
				actor:SetAttribute("RainingSummonStartedAt", workspace:GetServerTimeNow())
				local summonDuration = Style.SummonDuration
				local aura = api.SummonAura(summonDuration)
				local finished = core.WaitFor(summonDuration)
				aura:Dispose()
				if not finished or not encounterAlive() then
					return false
				end
				releaseRain(character)
				return true
			end)
		end)
	end
	function api.Dispose()
  if rainCast then rainCast:Dispose() end
  local pending={}
  for cast in pairs(activeDrops) do pending[#pending+1]=cast end
  for _,cast in ipairs(pending) do cast:Dispose() end
 end
	return api
end
