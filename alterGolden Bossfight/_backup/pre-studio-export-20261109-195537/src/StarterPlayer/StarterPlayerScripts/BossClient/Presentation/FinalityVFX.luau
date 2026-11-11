 
local Shared=game.ReplicatedStorage.BossShared.Presentation
local loaded
local function presentation()
 if not loaded then loaded=require(Shared:WaitForChild("FinalityRuntime"):WaitForChild("Visuals")) end
 return loaded
end
local Reset=require(Shared:WaitForChild("CinematicReset"))
local Visuals={}
local blocked={}
local currentToken
function Visuals.Handle(data)
 if type(data)~="table" or type(data.Token)~="string" then return end
 local now=os.clock()
 for token,untilAt in pairs(blocked) do if untilAt<=now then blocked[token]=nil end end
 if data.Stage=="End" then
  blocked[data.Token]=now+30
  presentation().Handle(data)
  if currentToken==data.Token then currentToken=nil end
  return
 end
 if blocked[data.Token] then return end
 if data.Stage=="Charge" then
  local owner=data.Owner
  local h=typeof(owner)=="Instance" and owner:FindFirstChildOfClass("Humanoid")
  if not h or h.Health<=0 or not owner.Parent or owner:GetAttribute("Phase")~=5 or owner:GetAttribute("EncounterEnded") then return end
  if type(data.Params)~="table" or typeof(data.Center)~="Vector3" then return end
  currentToken=data.Token
 end
 presentation().Handle(data)
end
function Visuals.Clear()
 if currentToken then blocked[currentToken]=os.clock()+30 currentToken=nil end
 if loaded then loaded.Clear() end
end
function Visuals.ResetView()
 if loaded then loaded.ResetView() end
end
Visuals.Cleanup=Visuals.Clear
Reset.Register(script,Visuals.Clear,Visuals.ResetView)
return Visuals
