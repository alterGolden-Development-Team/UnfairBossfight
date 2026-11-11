local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local api = {}
local profiles = {
 table.freeze({Name="Low", Density=.3, Particles=.3, Interval=1/30, Post=false, Lights=false}),
 table.freeze({Name="Medium", Density=.6, Particles=.6, Interval=1/45, Post=true, Lights=false}),
 table.freeze({Name="High", Density=1, Particles=1, Interval=0, Post=true, Lights=true}),
}
local changed=Instance.new("BindableEvent")
api.Changed=changed.Event
local player=Run:IsClient() and Players.LocalPlayer
local settings
if player then
 local ok,value=pcall(function()return UserSettings():GetService("UserGameSettings")end)
 if ok then settings=value end
end
local tier,autoTier=3,3
local sampled,frames,lastChange=0,0,os.clock()
local function baseTier()
 if Input.TouchEnabled then return 1 end
 local level=settings and settings.SavedQualityLevel.Value or 0
 if level>0 and level<=3 then return 1 end
 if level>0 and level<=6 then return 2 end
 return 3
end
function api.Mode()
 local mode=player and player:GetAttribute("EffectsQuality")
 return (mode=="Low" or mode=="High") and mode or "Auto"
end
local function refresh(reset)
 if reset then autoTier=baseTier(); sampled=0; frames=0 end
 local mode=api.Mode()
 local nextTier=mode=="Low" and 1 or mode=="High" and 3 or math.min(autoTier,baseTier())
 if nextTier~=tier then tier=nextTier; lastChange=os.clock(); changed:Fire(profiles[tier]) end
end
function api.Get()return profiles[tier]end
function api.Count(count,minimum)
 return math.clamp(math.floor(count*profiles[tier].Density+.5),math.min(minimum or 1,count),count)
end
function api.Rate(rate)return rate*profiles[tier].Particles end
function api.Cycle()
 if not player then return end
 local mode=api.Mode()
 player:SetAttribute("EffectsQuality",mode=="Auto" and "Low" or mode=="Low" and "High" or "Auto")
end
if player then
 refresh(true)
 player:GetAttributeChangedSignal("EffectsQuality"):Connect(function()refresh(true)end)
 Input:GetPropertyChangedSignal("TouchEnabled"):Connect(function()refresh(true)end)
 if settings then settings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()refresh(true)end) end
 Run.Heartbeat:Connect(function(dt)
  if api.Mode()~="Auto" or dt>1 then return end
  sampled+=dt; frames+=1
  if sampled<2 then return end
  local average=sampled/math.max(frames,1)
  sampled=0; frames=0
  if average>1/28 and autoTier>1 then autoTier-=1; refresh(false)
  elseif average<1/55 and os.clock()-lastChange>20 and autoTier<baseTier() then autoTier+=1; refresh(false) end
 end)
end
return api
