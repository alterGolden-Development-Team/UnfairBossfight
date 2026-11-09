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

-- (Round AA) solo detection: everybody who was in the server (and not just spectating) when the encounter started, plus anyone who
-- joined while it ran. A player who leaves mid-fight still counts, so a "solo" win really is one player from the first attack to the last.
local participants = {}
local function trackParticipants()
  participants = {}
  for _, p in ipairs(Players:GetPlayers()) do
    if p:GetAttribute("ViewAsServer") ~= true then participants[p.UserId] = true end
  end
end
local function participantCount()
  local n = 0
  for _ in pairs(participants) do n += 1 end
  return n
end
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
  if workspace:GetAttribute("EncounterStarted") == true then trackParticipants() end
end)
Players.PlayerAdded:Connect(function(p)
  if workspace:GetAttribute("EncounterStarted") ~= true then return end
  task.delay(2, function()
    if workspace:GetAttribute("EncounterStarted") == true and p.Parent == Players and p:GetAttribute("ViewAsServer") ~= true then
      participants[p.UserId] = true
    end
  end)
end)
if workspace:GetAttribute("EncounterStarted") == true then trackParticipants() end

-- quiet = true: award the badge but leave the victory screen's VictoryBadge* attributes alone (they describe the normal badge)
local function award(player, id, mode, quiet)
  local userId = player.UserId
  owned[id] = owned[id] or {}
  pending[id] = pending[id] or {}
  local badges, active = owned[id], pending[id]
  if player.Parent ~= Players or active[userId] then return end
  if badges[userId] then
    if not quiet then
      player:SetAttribute("VictoryBadgeId", id)
      player:SetAttribute("VictoryBadgeDifficulty", mode)
    end
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
        if not quiet then
          player:SetAttribute("VictoryBadgeId", id)
          player:SetAttribute("VictoryBadgeDifficulty", mode)
        end
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

 -- claimed: the Phase 5 finale's sword was taken (Combat/P5Finale) - he left through his portal instead of dying
function Rewards.AwardEncounter(actor, claimed)
  local h = actor and actor:FindFirstChildOfClass("Humanoid")
  if not actor or not actor.Parent or not h or h.Health > 0 and not claimed or completed[actor]
    or actor:GetAttribute("IsGoldenClone") or not actor:GetAttribute("EncounterEnded") then return false end
  local id, mode = Rewards.BadgeFor(actor)
  if type(id) ~= "number" or id <= 0 then warn("No victory badge configured for " .. mode) return false end
  completed[actor] = true
  local winners = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if Rewards.Eligible(player) then table.insert(winners, player) end
  end
  for _, player in ipairs(winners) do task.spawn(award, player, id, mode) end
  -- a solo win also earns the solo badge of that difficulty (True Hardcore solo / Hellaven solo)
  local soloId = Config.SoloBadgeIds and Config.SoloBadgeIds[mode]
  if type(soloId) == "number" and soloId > 0 and participantCount() == 1 then
    for _, player in ipairs(winners) do
      if participants[player.UserId] then task.spawn(award, player, soloId, mode, true) end
    end
  end
  return true
end

Players.PlayerRemoving:Connect(function(player)
  for _, badges in pairs(owned) do badges[player.UserId] = nil end
end)
return Rewards
