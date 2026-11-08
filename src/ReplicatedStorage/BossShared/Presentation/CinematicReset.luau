local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local Theme=require(script.Parent.EncounterTheme)
local Rules=require(game.ReplicatedStorage.BossShared.Config.AttackLifecycleRules)
local S={}
local callbacks=setmetatable({},{__mode="k"})
local resetting=false

function S.ViewAllowed()
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 return h~=nil and h.Health>0 and not player:GetAttribute("ViewAsServer")
end
function S.Register(owner,callback,characterReset)
  
 callbacks[owner]={Full=callback,Character=characterReset or (Rules.PlayerDeathClearsWorldEffects and callback or nil)}
end
local function reset(characterOnly)
 if resetting then return end resetting=true
 for owner,record in pairs(callbacks)do
  local callback=characterOnly and record.Character or nil
  if not characterOnly then callback=record.Full end
  if callback then
   local ok,err=pcall(callback)
   if not ok then warn("Cinematic cleanup "..tostring(owner)..": "..tostring(err))end
  end
 end
 if not characterOnly then Theme.Restore() end
 local camera=workspace.CurrentCamera
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if camera then
  camera.CameraType=Enum.CameraType.Custom Fov.Reset()
  if h then camera.CameraSubject=h end
 end
 resetting=false
end
function S.Reset()reset(false)end
function S.ResetCharacter()reset(true)end
local deathConnection
local function character(char)
 if deathConnection then deathConnection:Disconnect()deathConnection=nil end
 S.ResetCharacter()
 task.spawn(function()
  local h=char:WaitForChild("Humanoid",10)
  if h and player.Character==char then deathConnection=h.Died:Connect(S.ResetCharacter)end
 end)
end
player.CharacterRemoving:Connect(S.ResetCharacter)
player.CharacterAdded:Connect(character)
if player.Character then character(player.Character)end
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
 if workspace:GetAttribute("EncounterStarted")~=true then S.Reset()end
end)
workspace:GetAttributeChangedSignal("BossEncounterWon"):Connect(function()
 if workspace:GetAttribute("BossEncounterWon")then S.Reset()end
end)
player:GetAttributeChangedSignal("ViewAsServer"):Connect(S.ResetCharacter)
return S
