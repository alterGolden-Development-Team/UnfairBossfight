local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage:WaitForChild("BossShared")
local Difficulty = require(Shared.Config.DifficultyConfig)
local api = {}
local started = false
local sessions = setmetatable({}, { __mode = "k" })
local requests = setmetatable({}, { __mode = "k" })
local remote, statue, prompt
local pickToken = 0
 
local function speakPick(id)
 pickToken += 1
 local token = pickToken
 task.spawn(function()
  local ok, err = pcall(function()
   local Story = require(script.Parent.EncounterStory)
   Story.Play(nil, Story.PickLines(id), { Valid = function() return token == pickToken and not workspace:GetAttribute("EncounterStarted") end })
  end)
  if not ok then warn("Difficulty pick dialogue: " .. tostring(err)) end
 end)
end
local function control()
 if not remote then
  remote = Shared:FindFirstChild("DifficultyControl")
  if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "DifficultyControl"; remote.Parent = Shared end
 end
 return remote
end
local function closeEnough(player)
 local char = player.Character
 local root = char and char:FindFirstChild("HumanoidRootPart")
 local h = char and char:FindFirstChildOfClass("Humanoid")
 local host = statue and statue:FindFirstChild("Interaction")
 return root and h and h.Health > 0 and host and (root.Position - host.Position).Magnitude <= 20
end
local function resetLives(player)
 local lives = Difficulty.GetStartingLives()
 player:SetAttribute("LivesRemaining", lives)
 player:SetAttribute("StartingLives",lives)
 local char = player.Character
 if char then char:SetAttribute("LivesRemaining", lives) end
end
local function refresh()
 local id = Difficulty.Id()
 local profile = Difficulty.Get()
 local lobby = workspace:GetAttribute("LobbyMode") == true  -- the party chose the difficulty in the lobby
 local locked = workspace:GetAttribute("EncounterStarted") == true or lobby
 workspace:SetAttribute("DifficultyDisplayName", profile.Name)
 if prompt then
  prompt.ObjectText = "Trial of Golden · " .. profile.Name
  prompt.ActionText = locked and "View Difficulty" or "Choose Difficulty"
  prompt.Enabled = not lobby
 end
 if statue then
  statue:SetAttribute("SelectedDifficulty", id)
  local label = statue:FindFirstChild("DifficultyLabel", true)
  if label then label.Text = profile.Name .. (locked and "  ·  LOCKED" or "  ·  [E] INTERACT"); label.TextColor3 = profile.Color end
  for _,p in ipairs(statue:GetDescendants()) do
   if p:IsA("BasePart") and p:GetAttribute("DifficultyGlow") then p.Color = profile.Color end
  end
 end
end
function api.Select(player, id)
 if type(id) ~= "string" or not Difficulty.Profiles[id] then return false, "Unknown difficulty." end
 if workspace:GetAttribute("LobbyMode") == true then return false, "Return to the lobby to change difficulty." end
 if workspace:GetAttribute("EncounterStarted") then return false, "Difficulty is locked during the encounter." end
 if not sessions[player] or sessions[player] < os.clock() or not closeEnough(player) then
  return false, "Interact with the statue to choose a difficulty."
 end
 workspace:SetAttribute("SelectedDifficulty", id)
 workspace:SetAttribute("ActiveDifficulty", nil)
 for _,p in ipairs(Players:GetPlayers()) do resetLives(p) end
 refresh()
 speakPick(id)
 return true, "Selected " .. Difficulty.Profiles[id].Name .. " for everyone."
end
function api.Lock()
 local id = Difficulty.Id()
 workspace:SetAttribute("ActiveDifficulty", id)
 workspace:SetAttribute("DifficultyLocked", true)
 for _,player in ipairs(Players:GetPlayers()) do resetLives(player) end
 table.clear(sessions)
 refresh()
 return id
end
function api.Unlock()
 workspace:SetAttribute("ActiveDifficulty", nil)
 workspace:SetAttribute("DifficultyLocked", workspace:GetAttribute("LobbyMode") == true)  -- stays locked for a lobby party (Retry keeps the settings)
 table.clear(sessions)
 refresh()
end
function api.Start()
 if started then return end
 started = true
 if not Difficulty.Profiles[workspace:GetAttribute("SelectedDifficulty")] then workspace:SetAttribute("SelectedDifficulty", Difficulty.Default) end
 control()
 local arena = workspace:WaitForChild("GoldenGrasslandArena")
 statue = arena:WaitForChild("DifficultyStatue")
 prompt = statue:WaitForChild("Interaction"):WaitForChild("DifficultyPrompt")
 prompt.Triggered:Connect(function(player)
  if not closeEnough(player) then return end
  sessions[player] = os.clock() + 60
  control():FireClient(player, "Open", { Selected = Difficulty.Id(), Locked = workspace:GetAttribute("EncounterStarted") == true })
 end)
 control().OnServerEvent:Connect(function(player, action, id)
  if action ~= "Select" then return end
  local now = os.clock()
  if now - (requests[player] or -math.huge) < .5 then return end
  requests[player] = now
  local ok, message = api.Select(player, id)
  control():FireClient(player, "Result", { Success = ok, Message = message, Selected = Difficulty.Id() })
 end)
 Players.PlayerRemoving:Connect(function(player) sessions[player] = nil; requests[player] = nil end)
 workspace:GetAttributeChangedSignal("SelectedDifficulty"):Connect(refresh)
 workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(refresh)
 workspace:GetAttributeChangedSignal("LobbyMode"):Connect(refresh)
 refresh()
end
return api
