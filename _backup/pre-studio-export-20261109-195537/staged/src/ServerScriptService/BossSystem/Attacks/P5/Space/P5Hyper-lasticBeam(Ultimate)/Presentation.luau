local P={}
function P.Publish()
 local parent=game.ReplicatedStorage.BossShared.Presentation
 local folder=parent:FindFirstChild("HyperElasticRuntime")
 if folder then return folder end
 folder=Instance.new("Folder")folder.Name="HyperElasticRuntime"
 for _,name in ipairs({"Style","Geometry","Visuals"})do
  local copy=script.Parent[name]:Clone()copy.Parent=folder
 end
 folder.Parent=parent
 return folder
end
return table.freeze(P)
