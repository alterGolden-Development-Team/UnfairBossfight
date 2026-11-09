local BossSystem = script:FindFirstAncestor("BossSystem")
local Registry = require(BossSystem.Combat.AttackRegistry)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Run = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local api = {}
function api.AttackInterval(role)
 if role == "Elementalist" then return (Config.ShieldGateElementalistAttackInterval or 2.5) * Difficulty.Get().Cooldown end
 if role == "Swordsmaster" then return (Config.ShieldGateSwordsmasterAttackInterval or .75) * Difficulty.Get().Cooldown end
 return (Config.ShieldGateCloneAttackInterval or 1) * Difficulty.Get().Cooldown
end
local actorReady = setmetatable({}, {__mode = "k"})
api.Gold = Color3.fromRGB(255, 202, 35)
api.Bright = Color3.fromRGB(255, 244, 170)
function api.Owner(actor)
 local ref = actor:FindFirstChild("EncounterOwner")
 return ref and ref.Value or actor
end
function api.Allowed(actor, role)
 if not actor or not actor.Parent then return false end
 local owner = api.Owner(actor)
 local h = actor:FindFirstChildOfClass("Humanoid")
 local oh = owner and owner:FindFirstChildOfClass("Humanoid")
 local phase = owner and owner:GetAttribute("Phase")
 if not h or h.Health <= 0 or not oh or oh.Health <= 0 or not owner.Parent
  or owner:GetAttribute("EncounterEnded") or not owner:GetAttribute("ShieldCloneGateActive")
  or (phase ~= 1 and phase ~= 1.5) then return false end
 if role == "alterGolden" then return actor == owner and not actor:GetAttribute("IsGoldenClone") end
 return actor:GetAttribute("IsShieldGateClone") == true
  and actor:GetAttribute("CloneRoleTitle") == role and actor:GetAttribute("AIEnabled") ~= false
end
function api.Context(actor, role)
 local core = Registry.For(actor, "P1CombatCore")
 local owner = api.Owner(actor)
 local generation = owner:GetAttribute("PhaseGeneration") or 0
 local ctx = { Actor = actor, Owner = owner, Core = core, Root = core.Root, Filter = Runtime.FilterFor(actor) }
 function ctx.HandPosition(side)
  local hand=actor:FindFirstChild(side.."Hand") or actor:FindFirstChild(side.." Arm")
  local grip=hand and hand:FindFirstChild(side.."GripAttachment")
  if grip and grip:IsA("Attachment") then return grip.WorldPosition end
  if hand then return (hand.CFrame*CFrame.new(0,-hand.Size.Y*.5,0)).Position end
  return ctx.Root.Position+ctx.Root.CFrame.LookVector*2+Vector3.new(0,1,0)
 end
 function ctx.Valid()
  return api.Allowed(actor, role) and (owner:GetAttribute("PhaseGeneration") or 0) == generation
 end
 function ctx.Cast(name, lifetime)
  local cast = Effects.NewCast(actor, name, lifetime)
  cast.TimeStopExempt = true
  cast:Step(function()
   if not ctx.Valid() then cast:Dispose(); return false end
   return true
  end)
  return cast
 end
 function ctx.Wait(seconds)
  local untilTime = os.clock() + seconds
  repeat
   Run.Heartbeat:Wait()
   if not ctx.Valid() then return false end
  until os.clock() >= untilTime
  return true
 end
 function ctx.Damage(character, amount, skill)
  if ctx.Valid() then return core.Damage(character, amount, skill) end
  return 0
 end
 function ctx.Targets()
  local result = {}
  for _, char in ipairs(core.Characters()) do
   if core.Alive(char) and Encounter.CanReceiveHit(char) then table.insert(result, char) end
  end
  return result
 end
 function ctx.Part(cast, name, frame, size, color, transparency)
  local part = Effects.AcquirePart()
  part.Name, part.CFrame, part.Size = name, frame, size
  part.Color, part.Transparency = color or api.Gold, transparency or 0
  part.Parent = Runtime.Effects
  part:SetAttribute("ShieldBreakAttack", cast.name)
  part:SetAttribute("TimeStopExempt", true)
  return cast:Add(part)
 end
 function ctx.Line(cast, name, from, to, width, color, alpha)
  local delta = to - from
  return ctx.Part(cast, name, CFrame.lookAt((from + to) / 2, to),
   Vector3.new(width, width, math.max(0.01, delta.Magnitude)), color, alpha)
 end
  
 function ctx.Sweep(from, delta, radius)
  local wall = workspace:Raycast(from, delta, ctx.Filter())
  local segment = wall and wall.Position - from or delta
  local hitCharacter, hitAlpha
  for _, char in ipairs(ctx.Targets()) do
   local alpha = math.clamp((char.HumanoidRootPart.Position - from):Dot(segment)
    / math.max(segment:Dot(segment), 0.0001), 0, 1)
   if (char.HumanoidRootPart.Position - (from + segment * alpha)).Magnitude <= radius
    and (not hitAlpha or alpha < hitAlpha) then
    hitCharacter, hitAlpha = char, alpha
   end
  end
  if hitCharacter then return from + segment * hitAlpha, hitCharacter, true end
  return from + segment, nil, wall ~= nil
 end
 return ctx
end
function api.Skill(actor, role, name, cooldown, execute)
 if role == "Elementalist" or role == "Swordsmaster" then cooldown = api.AttackInterval(role)
 else cooldown *= Difficulty.Get(actor).Cooldown end
 local nextAt, busy = 0, false
 local apiSkill = { Cooldown = cooldown }
 function apiSkill.CanUse()
  return not busy and os.clock() >= math.max(nextAt, actorReady[actor] or 0) and api.Allowed(actor, role)
 end
 function apiSkill.Combo(target)
  if not apiSkill.CanUse() then return false end
  local ctx = api.Context(actor, role)
  if #ctx.Targets() == 0 then return false end
  busy = true
  nextAt = os.clock() + cooldown
  actorReady[actor] = nextAt
  actor:SetAttribute("ShieldBreakNextSkillAt", workspace:GetServerTimeNow() + cooldown)
  actor:SetAttribute("CurrentSkill", name)
  actor:SetAttribute("CurrentAttackFile", name)
  actor:SetAttribute("LastAttackName", name)
  actor:SetAttribute(name .. "StartedAt", workspace:GetServerTimeNow())
  local ok, result = xpcall(execute, debug.traceback, ctx, target)
  busy = false
  if ctx.Valid() then ctx.Core.Melee.Pose("Idle", 0.1) end
  if not ok then warn(name .. ": " .. tostring(result)); return false end
  return result ~= false
 end
 return apiSkill
end
return api
