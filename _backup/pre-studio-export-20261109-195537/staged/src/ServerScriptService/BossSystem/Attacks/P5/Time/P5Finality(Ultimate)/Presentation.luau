 
local P={}
function P.Publish()
 local parent=game.ReplicatedStorage.BossShared.Presentation
 local folder=parent:FindFirstChild("FinalityRuntime")
 if folder then return folder end
 folder=Instance.new("Folder") folder.Name="FinalityRuntime"
 for _,name in ipairs({"Geometry","Visuals"}) do
  local copy=script.Parent[name]:Clone() copy.Parent=folder
 end
 folder.Parent=parent
 return folder
end
return table.freeze(P)
