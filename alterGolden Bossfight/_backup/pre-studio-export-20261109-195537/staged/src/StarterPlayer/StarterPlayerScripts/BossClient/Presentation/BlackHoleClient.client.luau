 
local Collection=game:GetService("CollectionService")
local Shared=game.ReplicatedStorage:WaitForChild("BossShared")
local loaded,loading
local function start()
 if loaded or loading then return end
 loading=true
 local ok,result=pcall(function()
  local runtime=Shared.Presentation:WaitForChild("BlackHoleRuntime")
  return require(runtime:WaitForChild("Client"))
 end)
 loading=false
 if ok then loaded=result else warn("Black Hole client: "..tostring(result))end
end
local connection=Collection:GetInstanceAddedSignal("P5BlackHoleRoot"):Connect(function()task.spawn(start)end)
if #Collection:GetTagged("P5BlackHoleRoot")>0 then task.spawn(start)end
script.Destroying:Connect(function()connection:Disconnect()if loaded then loaded.Clear()end end)
