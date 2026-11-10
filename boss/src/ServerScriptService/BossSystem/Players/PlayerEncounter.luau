local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local HealthPenalty = require(BossSystem.Combat.HealthPenaltyService)
local HitRules=require(BossSystem.Combat.PlayerHitRules)
local BossDamageBalance=require(BossSystem.Combat.BossDamageBalance)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local immunity = require(BossSystem.Players.PlayerImmunity)
local Classes = require(Shared.Classes.ClassConfig)
local DamageService = require(BossSystem.Combat.DamageService)
local AbilityMetadata = require(BossSystem.Combat.AbilityMetadata)
local EncounterConfig = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local api = {}
local Aim = require(BossSystem.Combat.AttackTargetContinuity)
local DisorderWall = require(BossSystem.Combat.DisorderWall)
local respawning = setmetatable({}, { __mode = "k" })
local loadingCharacters = setmetatable({}, { __mode = "k" })
local bound = setmetatable({}, { __mode = "k" })
local damageStatuses, damagePassives
local damageGates = setmetatable({}, { __mode = "k" })
local DEATH_ROAR_SKILLS = table.freeze({ ["P4DeathRoars(Ultimate)"] = true, P5DeathRoar = true })
function api.SetDamageGate(character, token, active)
  if active then
    if damageGates[character] and damageGates[character] ~= token then
      return false
    end
    damageGates[character] = token
  elseif damageGates[character] == token then
    damageGates[character] = nil
  end
  return true
end
local function remote()
  return game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
end
function api.Say(text, player, options)
  options = options or {}
   
  if not options.IllusionLyrics and not options.LyricSoundtrack then
    local original = text
    text = require(BossSystem.Encounter.DialogueScripts).Translate(text)
    if text ~= original and options.Duration and #original > 0 then
       
      options = table.clone(options)
      options.Duration = math.max(options.Duration * (#text / #original), 1.2)
    end
  end
  local boss = workspace:FindFirstChild("alterGolden, the Nothing")
  if boss then
    boss:SetAttribute("LastDialogue", text)
    boss:SetAttribute("DialogueSequence", (boss:GetAttribute("DialogueSequence") or 0) + 1)
  end
  local event = remote()
  if event then
    local data = {
      Text = text, Duration = options.Duration or 4, LyricSoundtrack = options.LyricSoundtrack,
      StartedAt = options.StartedAt, Owner = options.Owner, Token = options.Token,
      IllusionLyrics = options.IllusionLyrics,
    }
    if player then
      event:FireClient(player, "BossDialogue", data)
    else
      event:FireAllClients("BossDialogue", data)
    end
  end
end
function api.SayAndWait(text, actor, options)
  local h = actor and actor:FindFirstChildOfClass("Humanoid")
  if not actor or not actor.Parent or not h or h.Health <= 0 then
    return false
  end
  local generation = actor:GetAttribute("PhaseGeneration") or 0
   
  text = require(BossSystem.Encounter.DialogueScripts).Translate(text, actor)
  local count = 0
  for _ in utf8.graphemes(text) do
    count += 1
  end
  local duration = count * EncounterConfig.DialogueCharacterInterval + 0.15
  api.Say(text, nil, { Duration = duration + 0.65 })
  local untilAt = os.clock() + duration
  repeat
    if
      not actor.Parent
      or h.Health <= 0
      or actor:GetAttribute("EncounterEnded")
      or actor:GetAttribute("AIEnabled") == false
      or actor:GetAttribute("PhaseTransitionInProgress")
      or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
    then
      return false
    end
    Run.Heartbeat:Wait()
  until os.clock() >= untilAt
  return true
end
function api.IsDefeated(player)
  return player:GetAttribute("PermanentlyDefeated") == true
end
 
function api.GrantLife(player)
  if api.IsDefeated(player) or player:GetAttribute("ExecutionPending") then
    return false
  end
  local current = player:GetAttribute("LivesRemaining")
  if type(current) ~= "number" or current <= 0 then
    return false
  end
  local remaining = math.floor(current) + 1
  player:SetAttribute("LivesRemaining", remaining)
  if player.Character then
    player.Character:SetAttribute("LivesRemaining", remaining)
  end
  return true
end
function api.OutgoingDamageMultiplier(character)
   
  local classAttack = character and character:GetAttribute("ClassAttack") or 1
  return classAttack * api.BaseOutgoingDamageMultiplier(character)
end
function api.BaseOutgoingDamageMultiplier(character)
  return require(BossSystem.Combat.StatusEffectService).P3DamageMultiplier(character)
end
local function classPhasing(char)
  local deadline = char and char:GetAttribute("ClassStatus_Phasing")
  local classId = char and char:GetAttribute("ClassId")
  return (classId == "Duelist" or classId == "Twinblade" or classId == "TrueWarrior" or classId == "Disorderer") and type(deadline) == "number"
    and (deadline == -1 or workspace:GetServerTimeNow() < deadline)
end
function api.CanReceiveHit(char, ignoreDashProtection, piercing)
 char = Aim.Character(char)
  local h = char and char:FindFirstChildOfClass("Humanoid")
  if
    not h
    or h.Health <= 0
    or classPhasing(char)
    or DisorderWall.Protects(char)
    or char:GetAttribute("Invulnerable") and not ((ignoreDashProtection or piercing)
      and workspace:GetServerTimeNow() < (char:GetAttribute("DashInvulnerableUntil") or 0))
    or char:FindFirstChildOfClass("ForceField")
    or char:GetAttribute("TimeFrozen") and EncounterConfig.TimeStopDamageProtection
    or workspace:GetServerTimeNow() < (char:GetAttribute("TimeThawProtectedUntil") or 0)
    or not ignoreDashProtection and not piercing and workspace:GetServerTimeNow() < (char:GetAttribute("DashInvulnerableUntil") or 0)
    or workspace:GetServerTimeNow() < (char:GetAttribute("RespawnInvulnerableUntil") or 0)
    or workspace:GetAttribute("P5FinaleSafe") == true
  then
    return false
  end
  local player = Players:GetPlayerFromCharacter(char)
  return not player
    or not (
      api.IsDefeated(player)
      or player:GetAttribute("ExecutionPending")
      or player:GetAttribute("ViewAsServer")
    )
end
local function canBeExecutedThroughIFrames(char)
  char = Aim.Character(char)
  local h = char and char:FindFirstChildOfClass("Humanoid")
  if not h or h.Health <= 0 then return false end
  local now = workspace:GetServerTimeNow()
  return not (char:GetAttribute("TimeFrozen") and EncounterConfig.TimeStopDamageProtection)
    and not DisorderWall.Protects(char)
    and now >= (char:GetAttribute("TimeThawProtectedUntil") or 0)
    and now >= (char:GetAttribute("RespawnInvulnerableUntil") or 0)
    and workspace:GetAttribute("P5FinaleSafe") ~= true
end
function api.ExecuteHit(char, livesCost, reason, damageToken, options)
  if typeof(char)~="Instance" or not char:IsA("Model") then return false end
  local source=options and options.UnavoidableFrom
  local expectedSkill=reason=="P5Finality" and "P5Finality(Ultimate)" or reason=="P5BlackHole" and "P5BlackHole"
  local finality=expectedSkill and typeof(source)=="Instance" and source:IsA("Model")
   and source:GetAttribute("Phase")==5 and source:GetAttribute("CurrentSkill")==expectedSkill
   and not source:GetAttribute("IsGoldenClone") and not source:GetAttribute("EncounterEnded")
  if not finality and (char:GetAttribute("ClassStatus_LastStand") ~= nil or char:GetAttribute("TrueWarriorCinematic") == true) then
    return false
  end
  local ignoreIFrames = options and options.IgnoreIFrames == true
  local open = not DisorderWall.Protects(char) and (finality or (ignoreIFrames and canBeExecutedThroughIFrames(char)) or (not ignoreIFrames and api.CanReceiveHit(char)))
  if damageGates[char] and damageGates[char] ~= damageToken or not open then
    return false
  end
  local player = Players:GetPlayerFromCharacter(char)
  local h = char:FindFirstChildOfClass("Humanoid")
  if not player or player.Character ~= char or not h or h.Health<=0 or char:GetAttribute("LifeConsumed")
    or api.IsDefeated(player) or player:GetAttribute("ExecutionPending") or player:GetAttribute("ViewAsServer") then
    return false
  end
  char:SetAttribute("PendingDeathLifeCost", math.clamp(math.floor(livesCost or 1), 1, math.max(api.StartingLives, 999)))
  char:SetAttribute("ExecutionHitReason", reason or "Execution hit")
  local before = h.Health
  h.Health = 0
   
  if h.Health <= 0 then api.ConsumeLife(player, char) end
  local event = remote()
  local root = char:FindFirstChild("HumanoidRootPart")
  if event and root and before > 0 then
    event:FireClient(player, "PlayerDamage", { Position = root.Position + Vector3.new(0, 3, 0), Damage = before })
  end
  return h.Health <= 0
end
 
function api.DamageOwner(sourceActor)
  local actor, seen = sourceActor, {}
  for _ = 1, 8 do
    if typeof(actor) ~= "Instance" or not actor:IsA("Model") or seen[actor] then
      return nil
    end
    seen[actor] = true
    local reference = actor:FindFirstChild("EncounterOwner")
    if reference and reference:IsA("ObjectValue") and reference.Value then
      actor = reference.Value
    else
      return not actor:GetAttribute("IsGoldenClone") and actor or nil
    end
  end
  return nil
end
function api.Damage(char, amount, sourceActor, damageToken, balance)
 char = Aim.Character(char)
  if
    sourceActor
    and (
      sourceActor:GetAttribute("IsIllusion")
      or workspace:GetServerTimeNow() < (sourceActor:GetAttribute("MissingFrameDamageGraceUntil") or 0)
    )
  then
    return 0
  end
  if damageGates[char] and damageGates[char] ~= damageToken then
    return 0
  end
  if
    type(amount) ~= "number"
    or amount ~= amount
    or amount <= 0
    or amount == math.huge
    or not api.CanReceiveHit(char, balance and balance.IsStatusDamage == true and balance.Skill == "Rupture",
      balance and balance.IgnoreIFrames == true
        and (DEATH_ROAR_SKILLS[balance.Skill] == true or balance.Skill == "P5EnhancedJumpKick")
        and (char:GetAttribute("ClassId") ~= nil or Difficulty.Mercy("AllowPierce", api.DamageOwner(sourceActor)) ~= false))
  then
    if classPhasing(char) and type(amount) == "number" and amount == amount and amount > 0 and amount < math.huge
      and not (balance and balance.IsStatusDamage) then
      local riposte = char:GetAttribute("ClassStatus_Riposte")
      local player = Players:GetPlayerFromCharacter(char)
      local humanoid = char:FindFirstChildOfClass("Humanoid")
      if player and humanoid and humanoid.Health > 0 and type(riposte) == "number"
        and (riposte == -1 or workspace:GetServerTimeNow() < riposte) then
        require(BossSystem.Players.Classes.ClassService).Incoming(player, char, humanoid, amount, balance)
      end
    end
    if char and char:GetAttribute("ClassId") and workspace:GetServerTimeNow() < (char:GetAttribute("DashInvulnerableUntil") or 0) then
      pcall(require(BossSystem.Players.Classes.ClassService).OnDodged, char)
    end
    return 0
  end
  local h = char:FindFirstChildOfClass("Humanoid")
  local player = Players:GetPlayerFromCharacter(char)
  if player and player.Character ~= char then
    return 0
  end
  local owner=api.DamageOwner(sourceActor)
 local piercingDot=HitRules.PiercingDot(balance)
  if balance and balance.Skill == "P4DeathRoars(Ultimate)" and balance.HealthDrain == true
    and owner == sourceActor and owner and math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) == 4 then
    local before = h.Health
    if before <= 1 then return 0 end
    h.Health = math.max(1, before - amount)
    local actual=math.max(0,before-h.Health)
  if actual>0 and char:GetAttribute("ClassId") then
   require(BossSystem.Players.Classes.ClassService).OnDamaged(char,actual)
  end
    local event = remote()
    local root = char:FindFirstChild("HumanoidRootPart")
    if actual > 0 and player and event and root then
      event:FireClient(player, "PlayerDamage", { Position = root.Position + Vector3.new(0, 3, 0), Damage = actual })
    end
    return actual
  end
  amount=BossDamageBalance.Resolve(amount,sourceActor,balance)
  if owner and workspace:GetServerTimeNow()<(owner:GetAttribute("DisorderWeakUntil") or 0) then amount*=owner:GetAttribute("DisorderWeakMult") or 1 end
  damageStatuses = damageStatuses or require(BossSystem.Combat.StatusEffectService)
 local tuning = balance and AbilityMetadata.Get(balance.Skill)
 local isStatus = balance and balance.IsStatusDamage == true
 local postGrace = 0
 if tuning and tuning.UnscaledDifficulty then
   
  local defense = 0
  amount = DamageService.Resolve(amount, defense)
 else
 local flatBurn=balance and balance.Skill=="GoldenBurn" and balance.IsStatusDamage==true
 local resolvedEcho=balance and balance.Skill=="TemporalWound" and balance.IsStatusDamage==true
 if flatBurn then amount=2 end
   
  local exact = balance and balance.ExactDamage == true
    and (balance.Skill == "P4.5HeavenlyDisciple(Ultimate)" or balance.Skill == "P5DeathRoar")
  local flatPercent = exact and balance.Skill == "P5DeathRoar"
  if owner and math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) == 4 and not flatBurn and not resolvedEcho and not exact then
    damagePassives = damagePassives or require(BossSystem.Combat.PassiveController)
    amount *= damagePassives.DamageMultiplier(owner)
  end
  local ignoresDefense = balance and balance.IgnoreDefense == true and balance.Skill == "P5EnhancedJumpKick" and owner and sourceActor
    and not sourceActor:GetAttribute("IsGoldenClone") and (char:GetAttribute("ClassId") ~= nil or Difficulty.Mercy("AllowPierce", owner) ~= false)
    or balance
    and balance.IgnoreDefense == true
    and (balance.Skill == "P4EnhancedNormalSlashes" or DEATH_ROAR_SKILLS[balance.Skill] == true)
    and owner
    and math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) == 4
    and sourceActor
    and not sourceActor:GetAttribute("IsGoldenClone")
    and (char:GetAttribute("ClassId") ~= nil or Difficulty.Mercy("AllowPierce", owner) ~= false)
   
  local skillName = tostring((balance and balance.Skill) or (owner and owner:GetAttribute("CurrentSkill")) or "")
  local isUltimate = string.find(skillName, "(Ultimate)", 1, true) ~= nil
  if not flatBurn and not resolvedEcho then
 amount = DamageService.Resolve(
    amount * damageStatuses.IncomingDamageMultiplier(char, balance),
    not piercingDot and not ignoresDefense and (0
      - damageStatuses.DefenseReduction(char)) or 0
  ) * damageStatuses.GoldenMarkDamageMultiplier(char)
 end
  if amount ~= amount or amount <= 0 or amount == math.huge then
    return 0
  end
 
 if not resolvedEcho and not flatPercent then amount = Difficulty.Damage(amount, owner) end
  
 if not resolvedEcho and not flatPercent then amount *= require(BossSystem.Combat.DifficultyPassive).OutgoingMultiplier(owner) end
 if isUltimate and not resolvedEcho then amount *= Difficulty.Mercy("UltimateDamage", owner) or 1 end
  

 postGrace = Difficulty.Mercy("PostHitGrace", owner) or 0
 if postGrace > 0 and not isStatus and workspace:GetServerTimeNow() < (char:GetAttribute("MercyGraceUntil") or 0) then return 0 end
  
 local hitCap = Difficulty.Mercy("HitCap", owner)
 if hitCap then amount = math.min(amount, h.MaxHealth * hitCap) end

 end
  local shieldBefore=char:GetAttribute("ClassShieldHP") or 0
   
  if char:GetAttribute("ClassId") then
    local classBalance=balance
    if HitRules.BreaksBlock(balance,sourceActor) then classBalance=table.clone(balance or {}) classBalance.BreaksBlock=true end
    amount=require(BossSystem.Players.Classes.ClassService).Incoming(player,char,h,amount,classBalance)
    if amount <= 0 then
      local absorbed=math.max(0,shieldBefore-(char:GetAttribute("ClassShieldHP") or 0))
      if absorbed>0 and owner and owner.Parent then
       damagePassives=damagePassives or require(BossSystem.Combat.PassiveController)
       damagePassives.OnSuccessfulHit(owner,char,absorbed)
      end
      return 0
    end
  end
  local before = h.Health
  h:TakeDamage(amount)
  local actual = math.max(0, before - h.Health)
  if actual > 0 and postGrace > 0 and not isStatus then char:SetAttribute("MercyGraceUntil", workspace:GetServerTimeNow() + postGrace) end
  if actual > 0 then pcall(require(BossSystem.Combat.DifficultyPassive).OnPlayerHit, owner, char, isStatus) end
  damageStatuses.OnDamageReceived(char, actual, balance)
  if actual > 0 and char:GetAttribute("ClassId") then
    pcall(require(BossSystem.Players.Classes.ClassService).OnDamaged, char, actual)
  end
  if actual ~= actual or actual == math.huge then
    return 0
  end
  if actual > 0 and player then
    local event = remote()
    local root = char:FindFirstChild("HumanoidRootPart")
    if event and root then
      event:FireClient(
        player,
        "PlayerDamage",
        { Position = root.Position + Vector3.new(0, 3, 0), Damage = actual }
      )
    end
  end
  local absorbed=math.max(0,shieldBefore-(char:GetAttribute("ClassShieldHP") or 0))
  if actual+absorbed>0 and owner and owner.Parent then
   damagePassives=damagePassives or require(BossSystem.Combat.PassiveController)
   damagePassives.OnSuccessfulHit(owner,char,actual+absorbed)
  end
  owner = actual > 0 and owner
  if
    owner
    and owner.Parent
    and not owner:GetAttribute("EncounterEnded")
    and (tonumber(owner:GetAttribute("Phase")) or 1) >= 3
  then
    damagePassives = damagePassives or require(BossSystem.Combat.PassiveController)
    if damagePassives.OnDamageDealt then
      damagePassives.OnDamageDealt(owner, char, actual, balance)
    end
    -- (Round Y) Phase 5 attacks leave a debuff from the game's debuff list (Combat/P5Debuffs); status ticks never do
    if not isStatus and balance and balance.Skill and (tonumber(owner:GetAttribute("Phase")) or 1) == 5 then
      pcall(function()
        require(BossSystem.Combat.P5Debuffs).OnHit(owner, char, balance.Skill)
      end)
    end
  end
  return actual
end
function api.LoadCharacter(player, force)
  if not player or player.Parent ~= Players then
    return false
  end
  if player.Character and not force then
    return true
  end
  if loadingCharacters[player] then
    return false
  end

  loadingCharacters[player] = true
  local loaded = false
  for attempt = 1, 3 do
    if player.Parent ~= Players then
      break
    end
    if player.Character and not force then
      loaded = true
      break
    end

    local ok, err = pcall(function()
      player:LoadCharacterAsync()
    end)
    if ok then
      loaded = true
      break
    end

    warn("Character load attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(err))
    if attempt < 3 then
      task.wait(1)
    end
  end
  loadingCharacters[player] = nil
  return loaded
end

function api.ExhaustLives(player, reason)
  if api.IsDefeated(player) or player:GetAttribute("ViewAsServer") == true then
    return false
  end
  player:SetAttribute("LivesRemaining", 0)
  player:SetAttribute("PermanentlyDefeated", true)
  player:SetAttribute("DefeatReason", reason or "Lives exhausted")
  player:SetAttribute("ExecutionPending", false)
  local char = player.Character
  if char then
    char:SetAttribute("LivesRemaining", 0)
    char:SetAttribute("PermanentlyDefeated", true)
    char:SetAttribute("ExecutionPending", false)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
      h.Health = 0
    end
  end
  api.Say("You were too weak.", player)
  return true
end
function api.ConsumeLife(player, char)
  if player.Character ~= char or char:GetAttribute("LifeConsumed") or api.IsDefeated(player) then
    return false
  end
  if workspace:GetAttribute("EncounterStarted") ~= true or player:GetAttribute("ViewAsServer") == true then
    char:SetAttribute("LifeConsumed", true)
    task.delay(Players.RespawnTime, function()
      if player.Parent == Players and player.Character == char then
        api.LoadCharacter(player, true)
      end
    end)
    return true
  end
  char:SetAttribute("LifeConsumed", true)
  local cost = math.clamp(math.floor(char:GetAttribute("PendingDeathLifeCost") or 1), 1, math.max(api.StartingLives, 999))
  char:SetAttribute("PendingDeathLifeCost", nil)
  local remaining = math.max(0, (player:GetAttribute("LivesRemaining") or api.StartingLives) - cost)
  player:SetAttribute("LivesRemaining", remaining)
  char:SetAttribute("LivesRemaining", remaining)
  if remaining == 0 then
    api.ExhaustLives(player, "All lives lost")
    return true
  end
  respawning[player] = true
  task.delay(Players.RespawnTime, function()
    if
      player.Parent == Players
      and player.Character == char
      and not api.IsDefeated(player)
      and not player:GetAttribute("ExecutionPending")
    then
      api.LoadCharacter(player, true)
    end
  end)
  return true
end
function api.BindCharacter(player, char)
  if bound[char] then
    return
  end
  bound[char] = true
 Aim.Register(player, char)
  HealthPenalty.Reset(player, char)
  local h = char:WaitForChild("Humanoid")
  char:SetAttribute("LivesRemaining", player:GetAttribute("LivesRemaining") or api.StartingLives)
  char:SetAttribute("PermanentlyDefeated", api.IsDefeated(player))
  char:SetAttribute("LifeConsumed", false)
  char:SetAttribute("GoldenMarkStacks", 0)
  char:SetAttribute("GoldenMarkUntil", 0)
  char:SetAttribute("JumpDisabled", false)
  player:SetAttribute("GoldenMarkStacks", 0)
  player:SetAttribute("GoldenMarkUntil", 0)
  if api.IsDefeated(player) then
    h.Health = 0
    return
  end
  assert(h.RigType == Enum.HumanoidRigType.R6, "Boss encounter requires an R6 player rig")
  h.BreakJointsOnDeath = false
  h.RequiresNeck = false
  local id = player:GetAttribute("PlayerClass")
  local def = Classes.Classes[id] or Classes.Classes[Classes.Default]
  local maxHealth = Classes.GetMaxHealth(id)
  h.MaxHealth = maxHealth
  h.Health = maxHealth
  char:SetAttribute("BaseWalkSpeed", def.Speed)
  h.WalkSpeed = def.Speed
  pcall(require(script:FindFirstAncestor("BossSystem").Encounter.Orbs).Apply, player, char, h, def)  -- lobby orb, if any
  if respawning[player] then
    respawning[player] = nil
    immunity.Grant(char, "RespawnInvulnerableUntil", 5)
    local shield = Instance.new("ForceField")
    shield.Name = "RespawnIFrames"
    shield.Visible = false
    shield.Parent = char
    task.delay(5, function()
      if shield.Parent then
        shield:Destroy()
      end
    end)
  end
  h.Died:Connect(function()
    HealthPenalty.Reset(player, char)
    api.ConsumeLife(player, char)
     
    task.defer(function()
      require(BossSystem.Presentation.CharacterEffects).Death(char)
    end)
  end)
  task.spawn(function()
    require(BossSystem.Players.PlayerR6Appearance).Apply(player, char)
    pcall(require(BossSystem.Players.Classes.ClassService).Apply, player, char)
  end)
end
function api.CheckpointRestore(player, snap)
  if player.Parent ~= Players or player:GetAttribute("ViewAsServer") or player:GetAttribute("ExecutionPending") then
    return nil
  end
  if api.IsDefeated(player) then
    player:SetAttribute("PermanentlyDefeated", false)
    player:SetAttribute("DefeatReason", nil)
  end
  if type(snap.Lives) == "number" and (player:GetAttribute("LivesRemaining") or 0) < snap.Lives then
    player:SetAttribute("LivesRemaining", snap.Lives)
  end
  respawning[player] = true
  if not api.LoadCharacter(player, true) then
    return nil
  end
  local char = player.Character
  local deadline = os.clock() + 6
  while char and os.clock() < deadline and player.Character == char and not char:GetAttribute("ClassLifeToken") do
    task.wait(0.05)
  end
  return player.Character == char and char or nil
end
function api.Start()
  if api.started then
    return
  end
  api.started = true
  Players.CharacterAutoLoads = false
  local function joined(player)
    player:SetAttribute("LivesRemaining", api.StartingLives)
  player:SetAttribute("StartingLives",api.StartingLives)
    player:SetAttribute("PermanentlyDefeated", false)
    player:SetAttribute("ExecutionPending", false)
    player.CharacterAdded:Connect(function(char)
      task.spawn(api.BindCharacter, player, char)
    end)
    if player.Character then
      task.spawn(api.BindCharacter, player, player.Character)
    else
      task.spawn(function()
        if player.Parent == Players then
          api.LoadCharacter(player)
        end
      end)
    end
  end
  Players.PlayerAdded:Connect(joined)
  for _, player in ipairs(Players:GetPlayers()) do
    joined(player)
  end

end
function api.ApplyPhase5Buff()
  if workspace:GetAttribute("Phase5HealthMultiplier") then
    return false
  end
  local multiplier = EncounterConfig.Phase5HealthMultiplier or 10
  workspace:SetAttribute("Phase5HealthMultiplier", multiplier)
  for _, player in ipairs(Players:GetPlayers()) do
    local lives = player:GetAttribute("LivesRemaining")
    if type(lives) == "number" and lives > 0 and not api.IsDefeated(player) then
      lives = math.floor(lives) + (EncounterConfig.Phase5BonusLives or 10)
      player:SetAttribute("LivesRemaining", lives)
      local char = player.Character
      if char then
        char:SetAttribute("LivesRemaining", lives)
        local h = char:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
          local halved = char:GetAttribute("HalvedBaseMaxHealth")
          if halved then
            char:SetAttribute("HalvedBaseMaxHealth", halved * multiplier)
          end
          h.MaxHealth = h.MaxHealth * multiplier
          h.Health = h.MaxHealth
        end
      end
    end
  end
  return true
end
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
  if not workspace:GetAttribute("EncounterStarted") then
    workspace:SetAttribute("Phase5HealthMultiplier", nil)
  end
end)
return setmetatable(api, { __index = function(_, key)
 if key == "StartingLives" then return Difficulty.GetStartingLives() end
end })
