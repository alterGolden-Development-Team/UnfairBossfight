local Shared=game.ReplicatedStorage:WaitForChild("BossShared")
local Theme=require(Shared.Presentation.EncounterTheme)
require(Shared.Presentation.CinematicReset)
workspace:GetAttributeChangedSignal("SelectedDifficulty"):Connect(Theme.Restore)
workspace:GetAttributeChangedSignal("ActiveDifficulty"):Connect(Theme.Restore)
Theme.Restore()

 -- Hellaven stays night all fight: the theme lives on this client only, so when the server writes its
 -- own daytime lighting back (a phase's sky, an ultimate restoring what it saved) the night returns
local Lighting=game:GetService("Lighting")
local pending=false
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
 local t=Lighting.ClockTime
 if pending or not Theme.IsHellaven() or t<6.5 or t>17.5 then return end
 pending=true
 task.delay(.1,function()  -- let the rest of the server's lighting arrive first
  pending=false
  local now=Lighting.ClockTime
  if Theme.IsHellaven() and now>=6.5 and now<=17.5 then Theme.Restore() end
 end)
end)
