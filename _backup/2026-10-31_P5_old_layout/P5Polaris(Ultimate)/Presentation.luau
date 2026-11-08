local P={}
function P.Publish()
 local parent=game.ReplicatedStorage.BossShared.Presentation
 local folder=parent:FindFirstChild("PolarisRuntime")
 if folder then return folder end
 folder=Instance.new("Folder")folder.Name="PolarisRuntime"
 for _,name in ipairs({"Camera","Style"})do script.Parent[name]:Clone().Parent=folder end
 folder.Parent=parent
 return folder
end
return table.freeze(P)
