local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Quality=require(game.ReplicatedStorage.BossShared.Presentation.VisualQuality)
local player=Players.LocalPlayer
-- Low effects quality: decorative map groups (paths under GoldenGrasslandArena) are hidden locally and
-- ambient lights / particles switched off. The scenery stands outside the knockback barriers, so
-- hiding it never hides anything a player can reach.
local optional={
 ["Scenery.Trees"]=true, ["Scenery.Spires"]=true, ["Scenery.Ruins"]=true,
}
-- gameplay cues that stay lit on Low
local keep={ ["RuinedApproach.PolyStar"]=true }
-- Keep original properties until a streamed instance leaves; weak keys can lose them during GC.
local records={}
local queue,head={},1
local upgrade,added,removed
local hidden=0
local stopped=false
local function inGroup(object,groups)
 local item=object
 while item and item~=upgrade do
  local parent=item.Parent
  if parent==upgrade and groups[item.Name] then return true end
  if parent and parent.Parent==upgrade and groups[parent.Name.."."..item.Name] then return true end
  item=parent
 end
 return false
end
local function isOptional(object)return inGroup(object,optional)end
local function restore(object,record)
 pcall(function()object[record.Property]=record.Value end)
 if record.Hidden then hidden-=1 end
 records[object]=nil
end
local function apply(object)
 if not upgrade or not object:IsDescendantOf(upgrade) then return end
 local low=Quality.Get().Name=="Low"
 local property,value
 if object:IsA("BasePart") and isOptional(object) then
  property,value="LocalTransparencyModifier",1
 elseif (object:IsA("Light") or object:IsA("Fire") or object:IsA("ParticleEmitter")) and not inGroup(object,keep) then
  property,value="Enabled",false
 else return end
 local record=records[object]
 if low then
  if not record then
   record={Property=property,Value=object[property],Hidden=property=="LocalTransparencyModifier"}
   records[object]=record
   if record.Hidden then hidden+=1 end
  end
  object[property]=value
 elseif record then restore(object,record) end
end
local function enqueueAll()
 table.clear(queue); head=1
 if upgrade then for _,object in ipairs(upgrade:GetDescendants()) do queue[#queue+1]=object end end
end
local function watch(object)
 if object.Name~="GoldenGrasslandArena" or object.Parent~=workspace then return end
 if object==upgrade then return end
 if added then added:Disconnect() end
 if removed then removed:Disconnect() end
 for instance,record in pairs(records) do restore(instance,record) end
 upgrade=object
 added=object.DescendantAdded:Connect(function(descendant)queue[#queue+1]=descendant end)
 removed=object.DescendantRemoving:Connect(function(descendant)
  local record=records[descendant]
  if record then restore(descendant,record) end
 end)
 enqueueAll()
end
local worldAdded=workspace.DescendantAdded:Connect(watch)
local arena=workspace:FindFirstChild("GoldenGrasslandArena")
if arena then watch(arena) end
local qualityChanged=Quality.Changed:Connect(enqueueAll)
local heartbeat=Run.Heartbeat:Connect(function()
 if stopped then return end
 local last=math.min(#queue,head+159)
 while head<=last do
  local object=queue[head]
  if object and object.Parent then apply(object) end
  head+=1
 end
 if head>#queue then table.clear(queue); head=1 end
 if player:GetAttribute("SceneryPartsHidden")~=hidden then player:SetAttribute("SceneryPartsHidden",hidden) end
end)
script.Destroying:Connect(function()
 stopped=true
 worldAdded:Disconnect(); qualityChanged:Disconnect(); heartbeat:Disconnect()
 if added then added:Disconnect() end
 if removed then removed:Disconnect() end
 for object,record in pairs(records) do restore(object,record) end
 table.clear(queue)
end)
