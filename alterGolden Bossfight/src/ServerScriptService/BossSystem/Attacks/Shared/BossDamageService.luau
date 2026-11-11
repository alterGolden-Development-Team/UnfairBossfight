local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
  local Registry = require(BossSystem.Combat.AttackRegistry)
  local Damage = require(BossSystem.Combat.DamageService)
  local Phases = require(BossSystem.Phases.PhaseController)
  local TemporalPhases = require(BossSystem.Phases.Phase25Controller)
  local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
  local h = actor:WaitForChild("Humanoid")
 local DamageTracker=require(BossSystem.Combat.DamageTracker)
  local combatEffects = game.ReplicatedStorage:WaitForChild("BossCombatEffects")
  local api = {}
   -- a phase change reached while he is using a skill or ultimate waits for it to finish (at most
   -- EncounterConfig.PhaseTransitionWait seconds); he takes no damage while it waits
  local queued
  local function later(fn)
    if not actor:GetAttribute("AttackInProgress") then fn() return end
    if not queued then
      queued = {}
      actor:SetAttribute("PhaseTransitionQueued", true)
      task.spawn(function()
        local deadline = os.clock() + (Config.PhaseTransitionWait or 12)
        while actor.Parent and actor:GetAttribute("AttackInProgress") and os.clock() < deadline
          and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress") do
          task.wait(0.05)
        end
        local list = queued
        queued = nil
        actor:SetAttribute("PhaseTransitionQueued", nil)
        for _, f in ipairs(list) do
          local ok, err = pcall(f)
          if not ok then warn("[BossDamage] queued phase change: " .. tostring(err)) end
        end
      end)
    end
    table.insert(queued, fn)
  end
  function api.SplitDamage(shield, health, amount, defense)
    local absorbed = math.min(shield, amount)
    return shield - absorbed, math.max(0, health - Damage.Resolve(amount - absorbed, defense))
  end
  function api.ApplyDamage(amount, attacker, attackToken)
    local isStatus = type(attackToken) == "table" and attackToken.IsStatusDamage == true
    if actor:GetAttribute("EncounterEnded") or actor:GetAttribute("PhaseTransitionInProgress")
     or actor:GetAttribute("PhaseTransitionQueued")
     or require(Shared.Classes.EnemyTargetRules).IsOrdinaryClone(actor) then return false end
    if attacker and not isStatus and actor:GetAttribute("ParryActive") and Registry.For(actor,"P1GoldenParry").TryCounter(attacker,attackToken) then return false end
     -- P5 Distorted Counter: a hit while his counter circle is up is caught (no damage) and answered
    if attacker and not isStatus and typeof(attacker) == "Instance" and workspace:GetServerTimeNow() < (actor:GetAttribute("CounterStanceUntil") or 0) then
      actor:SetAttribute("CounterStanceUntil", 0)
      actor:SetAttribute("CounterCaughtBy", attacker.Name)
      return false
    end
    if TemporalPhases.TryEvade(actor,attacker,attackToken) then return false end
    local Finale = require(BossSystem.Combat.P5Finale)
    if Finale.Untouchable(actor) then return false end  -- down to his last point of health: the final minute
     
    local DiffPassive = require(BossSystem.Combat.DifficultyPassive)
    amount *= DiffPassive.IncomingMultiplier(actor)
    if workspace:GetServerTimeNow() < (actor:GetAttribute("DisorderVulnUntil") or 0) then amount *= actor:GetAttribute("DisorderVulnMult") or 1 end
    DiffPassive.OnBossHit(actor, attacker, function(seconds)
      local glow = Instance.new("Highlight")
      glow.Name = "DuelistStagger"
      glow.FillColor = Color3.fromRGB(239, 151, 84)
      glow.OutlineColor = Color3.new(1, 1, 1)
      glow.FillTransparency = 0.6
      glow.Parent = actor
      task.delay(seconds, function() if glow.Parent then glow:Destroy() end end)
    end)
     
    if workspace:GetServerTimeNow() < (actor:GetAttribute("ExposedUntil") or 0) then
      amount *= Difficulty.Mercy("OpeningBonus", actor) or 1
    end
    amount = Damage.Resolve(
      amount * require(BossSystem.Players.PlayerEncounter).OutgoingDamageMultiplier(attacker),
      actor:GetAttribute("GoldenGuard") and Config.GoldenGuardReduction or 0
    )
    if
      amount <= 0
      or h.Health <= 0
      or actor:GetAttribute("Invulnerable")
      or actor:GetAttribute("ShieldDamageLocked")
      or actor:GetAttribute("LinkedProtection")
      or actor:GetAttribute("IsGoldenClone") and not (actor:GetAttribute("IsLinkedClone") or actor:GetAttribute(
        "DamageableClone"
      ) or actor:GetAttribute("IsShieldGateClone"))
      or actor:GetAttribute("PhaseTransitionInProgress")
    then
      return false
    end
    if
      actor:GetAttribute("IsLinkedClone")
      or actor:GetAttribute("DamageableClone")
      or actor:GetAttribute("IsShieldGateClone")
    then
      local resolved = Damage.Resolve(amount, actor:GetAttribute("Defense") or 0)
    * (1-math.clamp(actor:GetAttribute("ShieldChainResistance") or 0,0,1))
      -- a BossKit boss (another bossfight map, UnfairShared/BossKit) can carry a shield: it takes the hit first
      local absorbed = 0
      if actor:GetAttribute("BossKit") and (actor:GetAttribute("Shield") or 0) > 0 and resolved > 0 then
        absorbed = math.min(actor:GetAttribute("Shield"), resolved)
        actor:SetAttribute("Shield", actor:GetAttribute("Shield") - absorbed)
        resolved -= absorbed
      end
      local actual = math.min(h.Health, resolved)
      if actual <= 0 then
        if absorbed > 0 then
          local root = actor:FindFirstChild("HumanoidRootPart")
          if root then
            combatEffects:FireAllClients("BossDamage", { Position = root.Position + Vector3.new(0, 4.5, 0), Damage = absorbed, HealthDamage = 0, ShieldDamage = absorbed })
          end
          DamageTracker.Add(attacker, absorbed)
          return true, absorbed, h.Health, 0
        end
        return false
      end
      h.Health -= actual
      actor:SetAttribute("BossHealth", h.Health)
      local root = actor:FindFirstChild("HumanoidRootPart")
      if root then
        combatEffects:FireAllClients(
          "BossDamage",
          {
            Position = root.Position + Vector3.new(0, 4.5, 0),
            Damage = actual,
            HealthDamage = actual,
            ShieldDamage = 0,
          }
        )
      end
   DamageTracker.Add(attacker,actual)
      return true, 0, h.Health, actual
    end
    local shield = actor:GetAttribute("Shield") or 0
    local phase = tonumber(actor:GetAttribute("Phase")) or 1
    local beforeHealth = h.Health
    local remaining = math.max(0, shield - amount)
    if phase == 5 and actor:GetAttribute("P5Mode") and shield > 0 then
      remaining = math.max(remaining, math.min(shield, Config.Phase5ShieldHold or 1))  -- a mode's shield is held at 1 until its last stand has gone off (Combat/P5ModeService)
    end
    local hp = h.Health
    if
      not actor:GetAttribute("Phase15Triggered")
      and shield > Config.Phase15ShieldThreshold
      and remaining <= Config.Phase15ShieldThreshold
    then
      remaining = Config.Phase15ShieldThreshold
    elseif
      phase == 2
      and not actor:GetAttribute("Phase25Triggered")
      and shield > Config.Phase25ShieldThreshold
      and remaining <= Config.Phase25ShieldThreshold
    then
      remaining = Config.Phase25ShieldThreshold
    elseif phase == 3 and not actor:GetAttribute("Phase35Triggered")
   and shield > Config.Phase35ShieldThreshold and remaining <= Config.Phase35ShieldThreshold then
   remaining = Config.Phase35ShieldThreshold
    elseif
      phase == 2.5
      and not actor:GetAttribute("LastMinuteUsed")
      and remaining <= Config.LastMinuteShieldGate
    then
      remaining = Config.LastMinuteShieldGate
    elseif phase == 2.5 and actor:GetAttribute("LastMinuteActive") then
       -- Borrowed Time: the shield is the countdown; it stops at 1 and Phase25Controller ends the minute
      remaining = math.max(1, remaining)
    else
      local defense = actor:GetAttribute("Defense") or 0
      hp = math.max(0, h.Health - Damage.Resolve(math.max(0, amount - shield), defense))
    end
    if math.floor(phase) == 3 and Difficulty.Get(actor).Ultimates and not actor:GetAttribute("TrueIllusionCompleted") then
      remaining = math.max(1, remaining)
      hp = beforeHealth
    end
     
     
    if math.floor(phase) == 3 and not Difficulty.Get(actor).Ultimates and shield <= 0 then
      hp = beforeHealth
    end
     
     
    if phase >= 2 and phase < 4 and shield > 0 and remaining == 0 then
      hp = beforeHealth
    end
     
    local enterPhase45 = false
    if phase == 4 and not actor:GetAttribute("Phase45Triggered") and hp <= (Config.Phase45HealthThreshold or 0) then
      if beforeHealth > Config.Phase45HealthThreshold then
        hp = math.max(hp, Config.Phase45HealthThreshold)
      end
      enterPhase45 = hp > 0
    end
     
    local enterPhase5 = false
    local phase5At = Config.Phase5HealthThreshold
    if math.floor(phase) == 4 and phase5At and not enterPhase45 and not actor:GetAttribute("Phase5Triggered") and hp <= phase5At then
      if beforeHealth > phase5At then
        hp = math.max(hp, phase5At)
      end
      enterPhase5 = hp > 0
    end
    if remaining == 0 and phase < 2 then
      hp = math.max(Config.Phase2HealthThreshold, hp)
      if hp <= Config.Phase2HealthThreshold then
        actor:SetAttribute("Invulnerable", true)
      end
    end
    actor:SetAttribute("Shield", remaining)
    if phase == 3 and remaining > 0 and remaining <= Config.Phase35ShieldThreshold then
      if actor:GetAttribute("Phase35Triggered") then Phases.BeginPhase35(actor)
      else later(function() Phases.BeginPhase35(actor) end) end
    end
    if math.floor(phase) == 3 and remaining == 0 then
      if actor:GetAttribute("Phase4Triggered") then Phases.BeginPhase4(actor, attacker)
      else later(function() Phases.BeginPhase4(actor, attacker) end) end
    end
     
     
     
     
    if
      phase < 2
      and remaining <= Config.Phase15ShieldThreshold
      and hp > 0
      and not actor:GetAttribute("Phase15Triggered")
    then
      later(function() Registry.For(actor, "P15Transition").Begin(attacker and game.Players:GetPlayerFromCharacter(attacker)) end)
    end
    if (phase == 2 and remaining > 0 and remaining <= Config.Phase25ShieldThreshold and not actor:GetAttribute("Phase25Triggered"))
      or (phase == 2.5 and remaining > 0 and remaining <= Config.LastMinuteShieldGate and not actor:GetAttribute("LastMinuteUsed")) then
      later(function() TemporalPhases.OnShieldChanged(actor) end)
    else
      TemporalPhases.OnShieldChanged(actor)
    end
    if shield > 0 and remaining == 0 then
      require(BossSystem.Presentation.CharacterEffects).ShieldBreak(actor)
    end
    if remaining == 0 then
      if shield > 0 and (phase < 2 or math.floor(phase) == 3) then
        later(function() Phases.ShieldBroken(actor, attacker) end)
      else
        Phases.ShieldBroken(actor, attacker)
      end
    end
    if phase == 5 then hp = Finale.HoldHealth(actor, hp) end  -- he can't be cut past 1; 1 starts the final minute
    if phase == 5 and actor:GetAttribute("P5Mode") then hp = beforeHealth end  -- a mode's shield takes it all (P5ModeService)
    h.Health = hp
    actor:SetAttribute("BossHealth", hp)
    actor:SetAttribute("Defeated", hp <= 0)
    if enterPhase45 then
      later(function() Phases.BeginPhase45(actor) end)
    end
    if enterPhase5 then
      later(function() Phases.BeginPhase5(actor) end)
    end
    local protection = actor:FindFirstChild("ShieldProtection")
    if protection and remaining == 0 then
      protection:Destroy()
    end
    local glow = actor:FindFirstChild("ShieldGlow")
    if glow then
      glow.Enabled = remaining > 0
    end
    if remaining == 0 and hp <= Config.Phase2HealthThreshold and (actor:GetAttribute("Phase") or 1) < 2 then
      if not actor:GetAttribute("Phase2Triggered") and (actor:GetAttribute("ShieldCloneGateCompletedAt") or 0) > 0 then
        later(function() Phases.BeginPhase2(actor) end)
      else
        Phases.BeginPhase2(actor)
      end
    end
    local shieldDamage = math.max(0, shield - (actor:GetAttribute("Shield") or 0))
    local healthDamage = math.max(0, beforeHealth - h.Health)
    local dealt = shieldDamage + healthDamage
    if dealt > 0 then
   DamageTracker.Add(attacker,dealt)
      local root = actor:FindFirstChild("HumanoidRootPart")
      if root then
        combatEffects:FireAllClients("BossDamage", {
          Position = root.Position + Vector3.new(0, 4.5, 0),
          Damage = dealt,
          ShieldDamage = shieldDamage,
          HealthDamage = healthDamage,
        })
      end
    end
    return true, remaining, hp
  end
  return api
end
