local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Run = game:GetService("RunService")
local active = setmetatable({}, { __mode = "k" })
local api = {}

local function release(handle, reason)
 local actor = handle.Actor
 if active[actor] ~= handle then return end
 active[actor] = nil
 if actor.Parent then
  local now = workspace:GetServerTimeNow()
  actor:SetAttribute("UltimateActive", false)
  actor:SetAttribute("LastUltimateEndedAt", now)
  actor:SetAttribute("NextUltimateAt", now + Config.UltimateGlobalCooldown)
  if reason then
   actor:SetAttribute("LastUltimateRecoveryReason", reason)
   actor:SetAttribute("LastUltimateRecoveredAt", now)
  end
 end
end

local function staleReason(handle)
 local actor = handle.Actor
 local humanoid = actor:FindFirstChildOfClass("Humanoid")
 if not actor.Parent or not humanoid or humanoid.Health <= 0 or actor:GetAttribute("EncounterEnded") then
  return "Encounter ended"
 end
 if (actor:GetAttribute("PhaseGeneration") or 0) ~= handle.Generation
  or not Metadata.Available(handle.Name, actor:GetAttribute("Phase") or 1) then
  return "Phase changed"
 end
  
  
 local thread = handle.WaitThread or handle.Thread
 if thread and coroutine.status(thread) == "dead" then
  return "Ultimate task ended without releasing its lock"
 end
end

function api.Recover(actor)
 local handle = active[actor]
 if not handle then return false end
 local reason = staleReason(handle)
 if not reason then return false end
 release(handle, reason)
 return true
end

function api.IsTrueIllusionGate(actor, name)
 return name == "P3.5TrueIllusion(Ultimate)"
  and actor:GetAttribute("Phase") == 3.5 and actor:GetAttribute("Shield") == 1
  and not actor:GetAttribute("TrueIllusionCompleted")
  and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("IsIllusion")
end

function api.Ready(actor, checkingName)
 if not Difficulty.Get(actor).Ultimates then return false end
 api.Recover(actor)
 local handle = active[actor]
  
 if handle then return checkingName == handle.Name and coroutine.running() == handle.Thread end
 return api.IsTrueIllusionGate(actor, checkingName)
  or workspace:GetServerTimeNow() >= (actor:GetAttribute("NextUltimateAt") or 0)
end

function api.Begin(actor, name)
 if not api.Ready(actor, name) then return nil end
 local meta = Metadata.Get(name)
 if not meta or not meta.Ultimate or not Metadata.Available(name, actor:GetAttribute("Phase") or 1) then
  return nil
 end
  
 if meta.NativePhase == 3 or meta.NativePhase == 3.5 then
  require(BossSystem.Combat.StatusEffectService).ClearProjectileDarknessFor(actor)
 end
 local handle = {
  Actor = actor, Name = name, Thread = coroutine.running(),
  Generation = actor:GetAttribute("PhaseGeneration") or 0,
 }
 active[actor] = handle
 actor:SetAttribute("UltimateActive", true)
 actor:SetAttribute("LastUltimateName", name)
 actor:SetAttribute("LastUltimateStartedAt", workspace:GetServerTimeNow())
 return handle
end

function api.Finish(handle)
 if not handle or active[handle.Actor] ~= handle or handle.WaitThread then return end
 local actor = handle.Actor
 local function ongoing()
  if handle.Name == "P2GoldenClock(Ultimate)" then
   return require(BossSystem.Mechanics.Time.TimeEffectController).IsGoldenHour(actor)
  elseif handle.Name == "P2.5LastMinute(Ultimate)" then
   return actor:GetAttribute("LastMinutePreparing") or actor:GetAttribute("LastMinuteActive")
  end
  return false
 end
 if not ongoing() then release(handle); return end
 handle.WaitThread = task.spawn(function()
  while active[actor] == handle and actor.Parent and not actor:GetAttribute("EncounterEnded") and ongoing() do
   Run.Heartbeat:Wait()
  end
  release(handle)
 end)
end

function api.Cancel(actor, reason)
 local handle = active[actor]
 if handle then release(handle, reason or "Encounter cancelled") end
end

 
Run.Heartbeat:Connect(function()
 for actor in pairs(active) do api.Recover(actor) end
end)
return api
