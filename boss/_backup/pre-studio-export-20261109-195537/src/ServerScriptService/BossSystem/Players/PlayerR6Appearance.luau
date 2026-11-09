local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local descriptions={}
local loading=setmetatable({},{__mode="k"})
local api={}
local function originalDescription(player,h)
 local cached=descriptions[player.UserId]
 if cached then return cached end
 local description
 local avatarId=player.UserId
 if avatarId<=0 then
  avatarId=player.CharacterAppearanceId
  if avatarId<=0 and Run:IsStudio() then
   avatarId=script:GetAttribute("StudioAvatarUserId") or (game.CreatorType==Enum.CreatorType.User and game.CreatorId or 0)
  end
 end
 if avatarId>0 then
  local lastError
  for attempt=1,2 do
   local ok,result=pcall(function()return Players:GetHumanoidDescriptionFromUserIdAsync(avatarId)end)
   if ok then description=result break end
   lastError=result if attempt<2 then task.wait(.3)end
  end
  if not description then error("Could not load player avatar: "..tostring(lastError))end
 else
  description=h:GetAppliedDescription()
 end
 descriptions[player.UserId]=description
 return description
end
function api.Apply(player,char)
 if loading[char] then
  repeat task.wait(.05) until not loading[char] or player.Character~=char
  return player.Character==char and char:GetAttribute("R6AppearanceReady")==true
 end
 loading[char]=true
 char:SetAttribute("R6AppearanceBusy",true)
 char:SetAttribute("R6AppearanceFinished",false)
 char:SetAttribute("R6AppearanceReady",false)
 local h=char:WaitForChild("Humanoid")
 local ok,result=xpcall(function()
  local original=originalDescription(player,h)
  repeat
   if player.Character~=char or not char.Parent or h.Health<=0 then return false end
   local avatar=player:GetAttribute("UseAvatarAppearance")==true
   local description=original:Clone()
   if not avatar then
    description.Head=0 description.Torso=0
    description.LeftArm=0 description.RightArm=0 description.LeftLeg=0 description.RightLeg=0
   end
   local saved=char:FindFirstChild("ClassAvatarAccessories")if saved then saved:Destroy()end
   local gear=char:FindFirstChild("ClassGear")if gear then gear:Destroy()end
   local sword=char:FindFirstChild("Classic Sword")
   local backpack=player:FindFirstChildOfClass("Backpack")
   if sword and sword:IsA("Tool") and backpack then sword.Parent=backpack end
   h:ApplyDescriptionResetAsync(description)
   description:Destroy()
   if player.Character~=char or not char.Parent or h.Health<=0 then return false end
   char:SetAttribute("UseAvatarAppearance",avatar)
   local classId=char:GetAttribute("ClassId")
   if classId then require(script.Parent.Classes.ClassModels).Build(char,classId) end
   if avatar==(player:GetAttribute("UseAvatarAppearance")==true) then return true end
  until player.Character~=char
  return false
 end,debug.traceback)
 loading[char]=nil
 if char.Parent then char:SetAttribute("R6AppearanceBusy",nil) end
 local success=ok and result==true
 if player.Character==char and char.Parent then
  char:SetAttribute("R6AppearanceReady",success)
  char:SetAttribute("R6AppearanceFinished",true)
  char:SetAttribute("R6AppearanceRevision",(char:GetAttribute("R6AppearanceRevision") or 0)+1)
 end
 if not ok then warn("Avatar appearance: "..tostring(result))end
 return success
end
function api.Request(player,char)
 if loading[char] then return end
 task.spawn(function()
  local success=api.Apply(player,char)
  if success and player.Character==char and char.Parent then
   require(script:FindFirstAncestor("BossSystem").Combat.StatusEffectService).RefreshMovement(char)
  end
 end)
end
Players.PlayerRemoving:Connect(function(player)
 local description=descriptions[player.UserId]if description then description:Destroy()end
 descriptions[player.UserId]=nil
end)
return api
