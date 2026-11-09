local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Rules=require(game.ReplicatedStorage.BossShared.Config.AttackLifecycleRules)
local api = {}
local records, byModel = {}, setmetatable({}, { __mode = "k" })
local byCharacter=setmetatable({}, {__mode="k"})
local folder = Instance.new("Folder")
folder.Name = "BossAttackAimTargets"
folder.Parent = workspace
local function acquire(player)
 local record = records[player]
 if record then return record end
 local model = Instance.new("Model")
 model.Name = "Aim_" .. player.UserId
 model:SetAttribute("AttackAimOnly", true)
 local root = Instance.new("Part")
 root.Name = "HumanoidRootPart"
 root.Size = Vector3.new(2,2,1)
 root.Anchored, root.CanCollide, root.CanTouch, root.CanQuery = true, false, false, false
 root.Transparency = 1
 root.Parent = model
 local h = Instance.new("Humanoid")
 h.MaxHealth, h.Health = 100, 100
 h.RequiresNeck = false
 h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
 h.Parent = model
 model.PrimaryPart = root
 model.Parent = folder
 record = { Player = player, Model = model, Root = root, Seen = false, LastSeen = 0 }
 records[player], byModel[model] = record, record
 return record
end
local function update(record)
 local player = record.Player
 local character = player.Character
 if character then byCharacter[character]=record end
 local h = character and character:FindFirstChildOfClass("Humanoid")
 local root = character and character:FindFirstChild("HumanoidRootPart")
 if root and h and h.Health > 0 and not player:GetAttribute("ViewAsServer") then
  record.Root.CFrame = root.CFrame
  record.Velocity = root.AssemblyLinearVelocity
  record.Seen, record.LastSeen = true, workspace:GetServerTimeNow()
 else record.Velocity = Vector3.zero end
 record.Root.AssemblyLinearVelocity = record.Velocity
end
function api.Register(player)
 update(acquire(player))
end
function api.Player(model)
 local record = model and (byModel[model] or byCharacter[model])
 return record and record.Player or model and Players:GetPlayerFromCharacter(model)
end
function api.Character(model)
 local record = model and (byModel[model] or byCharacter[model])
 if record then return record.Player.Character end
 return model
end
function api.For(character)
 if not character then return nil end
 local record = byModel[character] or byCharacter[character]
 local player = record and record.Player or Players:GetPlayerFromCharacter(character)
 if not player then return character end
 record = acquire(player)
 update(record)
 return record.Model
end
 
function api.Retain(model)
 local character=api.Character(model)
 local h=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if character and character.Parent and h and h.Health>0 and root then return character end
 if not Rules.TargetLossKeepsLastPosition then return nil end
 local proxy=api.For(model)
 if proxy and api.Valid(proxy) then return proxy end
 return nil
end
function api.Valid(model)
 local record = model and (byModel[model] or byCharacter[model])
 return record and record.Seen and record.Player.Parent == Players
  and not record.Player:GetAttribute("ViewAsServer") and model.Parent and record.Root.Parent
end
function api.Fallback()
 if workspace:GetAttribute("EncounterStarted") ~= true or workspace:GetAttribute("BossEncounterWon") then return nil end
 local last
 for _,record in pairs(records) do
  if api.Valid(record.Model) and (not last or record.LastSeen > last.LastSeen) then last=record end
 end
 return last and last.Model
end
Players.PlayerRemoving:Connect(function(player)
 local record=records[player]
 if record then byModel[record.Model]=nil;records[player]=nil;record.Model:Destroy() end
end)
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
 if workspace:GetAttribute("EncounterStarted") ~= true then
  for _,record in pairs(records) do record.Seen=false end
 end
end)
Run.Heartbeat:Connect(function()
 for _,record in pairs(records) do update(record) end
end)
return api
