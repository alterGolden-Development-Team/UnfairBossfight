 
local P={}
function P.Publish()
 local parent=game.ReplicatedStorage.BossShared.Presentation
 local folder=parent:FindFirstChild("BlackHoleRuntime")
 if not folder then
  folder=Instance.new("Folder")folder.Name="BlackHoleRuntime"
  local client=script.Parent.Client:Clone()client.Parent=folder
  folder.Parent=parent
 end
 return folder
end
return table.freeze(P)
