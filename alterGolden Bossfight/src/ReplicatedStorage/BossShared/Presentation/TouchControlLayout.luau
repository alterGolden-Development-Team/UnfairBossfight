-- Shared reservation for Roblox's native touch Jump button.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
local changed=Instance.new("BindableEvent")
local Layout={Changed=changed.Event}
local watched={}
local queued=false
local jumpButton

local function notify()
 changed:Fire()
end

local function bind()
 for _,connection in watched do connection:Disconnect() end
 table.clear(watched)
 local touchGui=playerGui:FindFirstChild("TouchGui")
 local controls=touchGui and touchGui:FindFirstChild("TouchControlFrame")
 jumpButton=controls and controls:FindFirstChild("JumpButton")
 if touchGui then
  watched[#watched+1]=touchGui:GetPropertyChangedSignal("Enabled"):Connect(notify)
 end
 if controls then
  watched[#watched+1]=controls:GetPropertyChangedSignal("Visible"):Connect(notify)
 end
 if jumpButton then
  for _,property in {"AbsolutePosition","AbsoluteSize","Visible"} do
   watched[#watched+1]=jumpButton:GetPropertyChangedSignal(property):Connect(notify)
  end
 end
 notify()
end

local function scheduleBind(object)
 if object.Name~="TouchGui" and object.Name~="TouchControlFrame" and object.Name~="JumpButton" then return end
 if queued then return end
 queued=true
 task.defer(function()
  queued=false
  bind()
 end)
end
playerGui.DescendantAdded:Connect(scheduleBind)
playerGui.DescendantRemoving:Connect(scheduleBind)
UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(notify)
bind()

function Layout.GetJumpBounds()
 if not UIS.TouchEnabled or not jumpButton or not jumpButton.Parent then return nil end
 local controls=jumpButton.Parent
 local touchGui=controls.Parent
 if not jumpButton.Visible or not controls.Visible or not touchGui.Enabled then return nil end
 local size=jumpButton.AbsoluteSize
 if size.X<=0 or size.Y<=0 then return nil end
 local position=jumpButton.AbsolutePosition
 return position,position+size
end

return Layout
