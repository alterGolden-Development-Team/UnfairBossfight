local presentation=game.ReplicatedStorage:WaitForChild("BossShared"):WaitForChild("Presentation")
local runtime=presentation:WaitForChild("MysteriousGuyRuntime")
local cinematic=require(runtime:WaitForChild("Client"))
script.Destroying:Connect(cinematic.Destroy)
