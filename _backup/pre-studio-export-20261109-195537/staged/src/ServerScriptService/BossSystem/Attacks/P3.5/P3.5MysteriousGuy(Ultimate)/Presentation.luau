local P={}
function P.Publish()
 local replicated=game.ReplicatedStorage
 if not replicated:FindFirstChild("P35MysteriousGuyFX")then
  local remote=Instance.new("RemoteEvent")remote.Name="P35MysteriousGuyFX"remote.Parent=replicated
 end
 local parent=replicated.BossShared.Presentation
 local folder=parent:FindFirstChild("MysteriousGuyRuntime")
 if folder then return folder end
 folder=Instance.new("Folder")folder.Name="MysteriousGuyRuntime"
 local client=script.Parent.Client:Clone()client.Parent=folder
 folder.Parent=parent
 return folder
end
return table.freeze(P)
