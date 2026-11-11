 
local Players = game:GetService("Players")
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D = ClassConfig.Classes.Supporter
local GREEN, PALE = D.Color, Color3.fromRGB(200, 255, 225)

local K = {}

function K.Cleanup(S,char,st)
 for _,p in Players:GetPlayers() do
  local ally=p.Character
  if ally and ally:GetAttribute("FateLinkedBy")==st.Player.Name then S.ClearFateLink(ally) end
 end
end
function K.Start(S, player, char, st)
  st.Data.AliveSince = os.clock()
  st.Data.LifeTimer = 0
end

-- removes one debuff from an ally (nothing happens when they have none)
function K.Cleanse(S, ally)
  local ok, name = pcall(function()
    return require(script:FindFirstAncestor("BossSystem").Combat.StatusEffectService).RemoveOneDebuff(ally)
  end)
  if ok and name then
    local p = ally.HumanoidRootPart.Position
    S.FX.HQ.Glint(p + Vector3.new(0, 1, 0), PALE, 4, 0.3)
    S.FX.Text(p + Vector3.new(0, 4, 0), "CLEANSED", GREEN)
    return true
  end
  return false
end

function K.Step(S, player, char, st, dt)
  st.Data.CleanseTimer = (st.Data.CleanseTimer or 0) + dt
  if st.Data.CleanseTimer >= D.AuraCleanseEvery then
    st.Data.CleanseTimer = 0
    local auraRoot = char:FindFirstChild("HumanoidRootPart")
    if auraRoot then
      for _, ally in ipairs(S.Allies(true)) do
        if (ally.HumanoidRootPart.Position - auraRoot.Position).Magnitude <= D.AuraRadius then K.Cleanse(S, ally) end
      end
    end
  end
   
  local root = char.HumanoidRootPart
  for _, ally in ipairs(S.Allies(true)) do
    if (ally.HumanoidRootPart.Position - root.Position).Magnitude <= D.AuraRadius then
      S.StatBuff(ally, "Sanctuary:"..player.UserId, 0.6, { HealthRegen = D.AuraRegen, StaminaRegen = D.AuraRegen })
    end
  end
   
  if workspace:GetAttribute("EncounterStarted") then
    local sequence=workspace:GetAttribute("BossEntranceSequence") or 0
    if player:GetAttribute("SupporterLifeSequence")~=sequence then
      player:SetAttribute("SupporterLifeSequence",sequence)
      player:SetAttribute("SupporterBonusLives",0)
    end
    local earned=player:GetAttribute("SupporterBonusLives") or 0
    if earned>=D.MaxBonusLives then
      char:SetAttribute("SupporterLifeIn",0)
      char:SetAttribute("ClassStatusText_NextLife",tostring(D.MaxBonusLives).."/"..tostring(D.MaxBonusLives).." earned")
      return
    end
    st.Data.LifeTimer += dt
    char:SetAttribute("SupporterLifeIn", math.max(0, D.LifeEvery - st.Data.LifeTimer))
    char:SetAttribute("ClassStatus_NextLife", -1)
    char:SetAttribute("ClassStatusText_NextLife", string.format("%ds", math.ceil(D.LifeEvery - st.Data.LifeTimer)))
    if st.Data.LifeTimer >= D.LifeEvery then
      st.Data.LifeTimer = 0
      local ok,granted=pcall(function()
    return require(script:FindFirstAncestor("BossSystem").Players.PlayerEncounter).GrantLife(player)
   end)
   if ok and granted then
          player:SetAttribute("SupporterBonusLives",earned+1)
        S.FX.Text(root.Position + Vector3.new(0, 3, 0), "+1 LIFE", GREEN)
        S.FX.Ring(root.Position, GREEN, 8, 0.5)
      end
    end
  end
end

local function heal(S, target, fraction)
  local h = target:FindFirstChildOfClass("Humanoid")
  if h and h.Health > 0 then
    h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * fraction)
    S.FX.Burst(target.HumanoidRootPart.Position, GREEN, 10, 8, 0.6)
  end
end

function K.Action(S, player, char, st, key, phase, aim)
  if phase ~= "Begin" or not S.Ready(char, key) then
    return
  end
  local root = char.HumanoidRootPart
  local dir = C.AimDir(char, aim)
  if key == "M1" then
    S.Cooldown(char, "M1", D.M1.Cooldown)
  local attack = S.NewAttack(char,"SupporterSonar")
    S.Anim(char, "Sweep")
    S.FX.Release(C.Hand(char), dir, GREEN, 0.7)
    S.Sound(char, "ThreadLaunch")
     
     
    local visual = S.FX.Part({ Size = Vector3.one * 0.2, Transparency = 1 })
    local core = S.FX.Orb(GREEN, 1.1)
    task.delay(D.M1.Range / D.M1.Speed + 0.2, function() if core.Parent then core:Destroy() end end)
    S.FX.HQ.Ring(CFrame.lookAt(C.Hand(char), C.Hand(char) + dir), 0.5, 3, 0.3, GREEN, 0.15, 0.3, 2)
    local hitBoss, healed = false, {}
    S.FX.Projectile(root.Position + dir * 2, dir, D.M1.Speed, D.M1.Range, visual, function(pos)
   if not S.AttackValid(char,attack) then return true end
      if core.Parent then
        core.CFrame = CFrame.new(pos)
      end
      st.Data.SonarStep = (st.Data.SonarStep or 0) + 1
      if st.Data.SonarStep % 4 == 0 then
        S.FX.HQ.Ring(CFrame.lookAt(pos, pos + dir), 1, 6.5, 0.35, GREEN, 0.2, 0.35, 2)
        S.FX.HQ.Sparks(pos, GREEN, PALE, 4, 4, 10, 0.25)
      end
      if not hitBoss then
        local target = S.TargetNear(pos, D.M1.Radius)
        if target then
          hitBoss = true
          attack.Origin=pos
     if S.HitBoss(char,target,D.M1.Damage,"SupporterSonar",attack) then
          S.FX.Ring(pos, GREEN, 6, 0.3)
     end
        end
      end
      for _, ally in ipairs(S.Allies(false, char)) do
        if not healed[ally] and (ally.HumanoidRootPart.Position - pos).Magnitude <= D.M1.Radius then
          healed[ally] = true
          heal(S, ally, D.M1.Heal)
          S.FX.HQ.Glint(ally.HumanoidRootPart.Position + Vector3.new(0, 1, 0), GREEN, 3, 0.3)
        end
      end
    end)
  elseif key == "F" then
    if not S.SpendStamina(char, D.F.StaminaCost) then
      S.FX.Text(root.Position + Vector3.new(0, 3, 0), "NO STAMINA", PALE)
      return
    end
    S.Cooldown(char, "F", D.F.Cooldown)
    S.Anim(char, "Heal")
    S.FX.Charge(C.Hand(char), GREEN, 0.25, 1.4)
    S.Sound(char, "QTESuccess")
    local target = S.AimedAlly(char, aim, D.F.Range) or char
    heal(S, target, D.F.Heal)
    K.Cleanse(S, target)
    S.StatBuff(target, "Healing", D.F.Buff, { StaminaRegen = D.F.BuffStamina, Attack = D.F.BuffAttack })
    S.FX.Beam(C.Hand(char), target.HumanoidRootPart.Position, GREEN, 0.5, 0.4)
    S.FX.Flash(target.HumanoidRootPart.Position, GREEN, 8, 0.4)
     
    S.FX.HQ.Spikes(target.HumanoidRootPart.Position - Vector3.new(0, 2.8, 0), 3, 2.5, 9, GREEN, Color3.new(1, 1, 1), 0.7)
    S.FX.HQ.Sparks(target.HumanoidRootPart.Position, GREEN, Color3.new(1, 1, 1), 20, 6, 14, 0.3)
    S.FX.Text(target.HumanoidRootPart.Position + Vector3.new(0, 3, 0), "+35%", GREEN)
  elseif key=="C" then
    local boss=S.Boss()
    if boss and boss:GetAttribute("PickThePupilsActive") then
      S.FX.Text(root.Position+Vector3.new(0,3,0),"LINK SEALED DURING PUZZLE",PALE)
      return
    end
    local target = S.AimedAlly(char, aim, D.C.Range)
    if not target then
      S.FX.Text(root.Position + Vector3.new(0, 3, 0), "NO ALLY IN RANGE", PALE)
      return
    end
    S.Cooldown(char, "C", D.C.Cooldown)
    S.Anim(char, "Chain")
    S.Sound(char, "ChainContact")
     
    for _, ally in ipairs(S.Allies(false, char)) do
      if ally:GetAttribute("FateLinkedBy") == player.Name then
        S.ClearFateLink(ally)
      end
    end
    target:SetAttribute("FateLinkedBy",player.Name)
    target:SetAttribute("FateLinkedLifeToken",char:GetAttribute("ClassLifeToken"))
    S.Buff(target, "FateLinked", nil)
     
    local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
    a0.Name, a1.Name = "FateLinkFrom", "FateLinkTo"
    a0.Parent, a1.Parent = root, target.HumanoidRootPart
    local beam = Instance.new("Beam")
    beam.Name = "FateLinkBeam"
    beam.Attachment0, beam.Attachment1 = a0, a1
    beam.Color = ColorSequence.new(GREEN, PALE)
    beam.LightEmission = 1
    beam.Width0, beam.Width1 = 0.25, 0.25
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(0.35)
    beam.TextureSpeed = 1
    beam.Parent = target.HumanoidRootPart
    S.FX.Flash(target.HumanoidRootPart.Position, GREEN, 8, 0.4)
    S.FX.HQ.Glint(root.Position + Vector3.new(0, 1, 0), PALE, 4, 0.5)
    S.FX.HQ.Glint(target.HumanoidRootPart.Position + Vector3.new(0, 1, 0), PALE, 4, 0.5)
     
    local a, b = root.Position + Vector3.new(0, 1, 0), target.HumanoidRootPart.Position + Vector3.new(0, 1, 0)
    local links = math.clamp(math.floor((b - a).Magnitude / 1.6), 3, 30)
    for i = 1, links do
      task.delay(i * 0.015, function()
        local p = a:Lerp(b, i / (links + 1))
        local link = S.FX.Part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.18, 0.9, 0.9), Color = i % 2 == 0 and GREEN or PALE, Material = Enum.Material.Neon, Transparency = 0.1,
          CFrame = CFrame.lookAt(p, b) * CFrame.Angles(0, (i % 2) * math.rad(90), 0) }, 0.8)
        S.FX.Fade(link, 0.7)
      end)
    end
  elseif key == "V" then
    local lives = player:GetAttribute("LivesRemaining") or 1
    if lives <= 1 then
      S.FX.Text(root.Position + Vector3.new(0, 3, 0), "NEED 2+ LIVES", PALE)
      return
    end
    S.Cooldown(char, "V", D.V.Cooldown)
    S.Anim(char, "SecondWind")
    S.Sound(char, "EntranceReveal")
    S.FX.HQ.Spikes(root.Position - Vector3.new(0, 2.5, 0), 8, 10, 18, GREEN, Color3.new(1, 1, 1), 1)
    player:SetAttribute("LivesRemaining", lives - 1)
    char:SetAttribute("LivesRemaining", lives - 1)
    S.FX.Flash(root.Position, PALE, 20, 0.8)
    S.FX.Ring(root.Position - Vector3.new(0, 2.6, 0), GREEN, 40, 0.9, 0.8)
    S.FX.HQ.Spikes(root.Position - Vector3.new(0, 2.6, 0), 1, 0.5, 28, PALE, Color3.new(1, 1, 1), 1.2)
    S.FX.HQ.Sparks(root.Position + Vector3.new(0, 2, 0), GREEN, PALE, 60, 10, 40, 0.4)
    S.FX.HQ.Tint(root.Position, GREEN, 0.25, 0.4, 120)
    S.FX.Hit(root.Position, GREEN, 2, true)
    S.FX.Text(root.Position + Vector3.new(0, 4, 0), "SECOND WIND", PALE)
    for _, ally in ipairs(S.Allies(false, char)) do
      S.Buff(ally, "SecondWind", nil)
      S.FX.Beam(root.Position, ally.HumanoidRootPart.Position, PALE, 0.4, 0.5)
    end
  end
end
return K
