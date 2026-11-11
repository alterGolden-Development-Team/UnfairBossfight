local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage:WaitForChild("BossShared")
local Difficulty = require(Shared.Config.DifficultyConfig)
local api = {}
local started = false
local remote
-- The difficulty statue is gone for good: the party picks the trial in the lobby (Intake sets SelectedDifficulty from the payload).
-- This service only keeps the attributes, the locks and the starting lives; Select is refused.
local function control()
 if not remote then
  remote = Shared:FindFirstChild("DifficultyControl")
  if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "DifficultyControl"; remote.Parent = Shared end
 end
 return remote
end
local function resetLives(player)
 local lives = Difficulty.GetStartingLives()
 player:SetAttribute("LivesRemaining", lives)
 player:SetAttribute("StartingLives",lives)
 local char = player.Character
 if char then char:SetAttribute("LivesRemaining", lives) end
end
local function refresh()
 workspace:SetAttribute("DifficultyDisplayName", Difficulty.Get().Name)
end
function api.Select(_player, id)
 if type(id) ~= "string" or not Difficulty.Profiles[id] then return false, "Unknown difficulty." end
 return false, "Return to the lobby to change difficulty."
end
function api.Lock()
 local id = Difficulty.Id()
 workspace:SetAttribute("ActiveDifficulty", id)
 workspace:SetAttribute("DifficultyLocked", true)
 for _,player in ipairs(Players:GetPlayers()) do resetLives(player) end
 refresh()
 return id
end
function api.Unlock()
 workspace:SetAttribute("ActiveDifficulty", nil)
 workspace:SetAttribute("DifficultyLocked", workspace:GetAttribute("LobbyMode") == true)  -- stays locked for a lobby party (Retry keeps the settings)
 refresh()
end
function api.Start()
 if started then return end
 started = true
 if not Difficulty.Profiles[workspace:GetAttribute("SelectedDifficulty")] then workspace:SetAttribute("SelectedDifficulty", Difficulty.Default) end
 control().OnServerEvent:Connect(function(player, action, id)
  if action ~= "Select" then return end
  local ok, message = api.Select(player, id)
  control():FireClient(player, "Result", { Success = ok, Message = message, Selected = Difficulty.Id() })
 end)
 workspace:GetAttributeChangedSignal("SelectedDifficulty"):Connect(refresh)
 workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(refresh)
 workspace:GetAttributeChangedSignal("LobbyMode"):Connect(refresh)
 refresh()
end
return api
