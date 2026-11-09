local remote=game.ReplicatedStorage:WaitForChild("BossCombatEffects")
local VFX=require(script.Parent:WaitForChild("FinalityVFX"))
local connection=remote.OnClientEvent:Connect(function(kind,data)
 if kind~="Finality"or type(data)~="table"then return end
 if data.Stage=="End"then VFX.Handle(data)return end
 local owner=data.Owner
 if typeof(owner)=="Instance"and owner.Parent and owner:GetAttribute("Phase")==5 then VFX.Handle(data)end
end)
script.Destroying:Connect(function()connection:Disconnect()VFX.Clear()end)
