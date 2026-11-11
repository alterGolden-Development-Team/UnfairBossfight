local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local S={HealthPerExtraPlayer=0.6,ShieldPerExtraPlayer=0.6,DamagePerExtraPlayer=0.5}
local countCache,cacheAt=1,-math.huge
local leaving=setmetatable({},{__mode="k"})
local connections={}
local function invalidate() cacheAt=-math.huge end
local function watch(p)
 connections[p]={
  p:GetAttributeChangedSignal("LivesRemaining"):Connect(invalidate),
  p:GetAttributeChangedSignal("PermanentlyDefeated"):Connect(invalidate),
  p:GetAttributeChangedSignal("ViewAsServer"):Connect(invalidate)}
 invalidate()
end
for _,p in Players:GetPlayers() do watch(p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
 leaving[p]=true
 for _,c in connections[p] or {} do c:Disconnect() end
 connections[p]=nil invalidate()
end)
function S.ActiveCount()
 if os.clock()-cacheAt<0.1 then return countCache end
 local count=0
 for _,p in Players:GetPlayers() do
  local lives=p:GetAttribute("LivesRemaining")
  if not leaving[p] and p:GetAttribute("ViewAsServer")~=true and p:GetAttribute("PermanentlyDefeated")~=true
   and (lives==nil or lives>0) then count+=1 end
 end
 countCache=math.max(1,count) cacheAt=os.clock()
 return countCache
end
function S.DamageMultiplier(count)
 return S.DamagePerExtraPlayer^math.max(0,math.floor(count or S.ActiveCount())-1)
end
function S.HealthMultiplier()
 return 1+S.HealthPerExtraPlayer*math.max(0,(workspace:GetAttribute("BossScalingPlayerCount") or 1)-1)
end
function S.ShieldMultiplier()
 return 1+S.ShieldPerExtraPlayer*math.max(0,(workspace:GetAttribute("BossScalingPlayerCount") or 1)-1)
end
function S.Reset()
 assert(Run:IsServer())
 workspace:SetAttribute("BossScalingPlayerCount",nil)
end
function S.Lock()
 assert(Run:IsServer())
 workspace:SetAttribute("BossScalingPlayerCount",S.ActiveCount())
end
function S.RaiseForRoster(actor)
 assert(Run:IsServer())
 if workspace:GetAttribute("EncounterStarted")~=true then return false end
 local old=workspace:GetAttribute("BossScalingPlayerCount") or 1
 local count=S.ActiveCount()
 if count<=old then return false end
 local oldHealth,oldShield=S.HealthMultiplier(),S.ShieldMultiplier()
 workspace:SetAttribute("BossScalingPlayerCount",count)
 if actor and actor.Parent and actor.Humanoid.Health>0 and not actor:GetAttribute("EncounterEnded") then
  local healthRatio,shieldRatio=S.HealthMultiplier()/oldHealth,S.ShieldMultiplier()/oldShield
  local h=actor.Humanoid
  local health=h.Health
  h.MaxHealth=math.max(1,math.floor(h.MaxHealth*healthRatio+0.5))
  h.Health=math.min(h.MaxHealth,math.max(1,math.floor(health*healthRatio+0.5)))
  actor:SetAttribute("BossHealth",h.Health)
  for _,key in {"MaxShield","Shield"} do
   local v=actor:GetAttribute(key)
   if type(v)=="number" then actor:SetAttribute(key,math.max(0,math.floor(v*shieldRatio+0.5))) end
  end
 end
 return true
end
return table.freeze(S)
