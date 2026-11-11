local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local Shared = game.ReplicatedStorage.BossShared
local Config = require(Shared.Config.VictoryRewardConfig)
local Difficulty = require(Shared.Config.DifficultyConfig)
local completed = setmetatable({}, { __mode = "k" })
local pending, owned = {}, {}
local Rewards = {}

function Rewards.Eligible(player)
  return player.Parent == Players and player.UserId > 0
    and player:GetAttribute("ViewAsServer") ~= true
    and player:GetAttribute("PermanentlyDefeated") ~= true
    and (player:GetAttribute("LivesRemaining") or 0) > 0
end

function Rewards.BadgeFor(actor)
  local mode = Difficulty.Id(actor)
  return Config.BadgeIds[mode], mode
end

local function award(player, id, mode)
  local userId = player.UserId
  owned[id] = owned[id] or {}
  pending[id] = pending[id] or {}
  local badges, active = owned[id], pending[id]
  if player.Parent ~= Players or active[userId] then return end
  if badges[userId] then
    player:SetAttribute("VictoryBadgeId", id)
    player:SetAttribute("VictoryBadgeDifficulty", mode)
    return
  end
  active[userId] = true
  local failure
  for attempt = 1, Config.AwardAttempts do
    if player.Parent ~= Players then break end
    local ok, result = pcall(function()
      local info = BadgeService:GetBadgeInfoAsync(id)
      if not info.IsEnabled then error("Victory badge is disabled") end
      if BadgeService:UserHasBadgeAsync(userId, id) then return true end
      if player.Parent ~= Players then return false end
      return BadgeService:AwardBadgeAsync(userId, id)
    end)
    if ok and result then
      if player.Parent == Players then
        badges[userId] = true
        player:SetAttribute("VictoryBadgeId", id)
        player:SetAttribute("VictoryBadgeDifficulty", mode)
      end
      failure = nil
      break
    end
    failure = ok and "Badge was not awarded" or tostring(result)
    if attempt < Config.AwardAttempts and player.Parent == Players then task.wait(Config.RetryDelay * attempt) end
  end
  active[userId] = nil
  if failure and player.Parent == Players then warn("Victory badge for " .. player.Name .. ": " .. failure) end
end

function Rewards.AwardEncounter(actor)
  local h = actor and actor:FindFirstChildOfClass("Humanoid")
  if not actor or not actor.Parent or not h or h.Health > 0 or completed[actor]
    or actor:GetAttribute("IsGoldenClone") or not actor:GetAttribute("EncounterEnded") then return false end
  local id, mode = Rewards.BadgeFor(actor)
  if type(id) ~= "number" or id <= 0 then warn("No victory badge configured for " .. mode) return false end
  completed[actor] = true
  local winners = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if Rewards.Eligible(player) then table.insert(winners, player) end
  end
  for _, player in ipairs(winners) do task.spawn(award, player, id, mode) end
  return true
end

Players.PlayerRemoving:Connect(function(player)
  for _, badges in pairs(owned) do badges[player.UserId] = nil end
end)
return Rewards
