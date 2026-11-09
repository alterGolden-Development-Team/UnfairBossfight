--[[
 VFXEngine.Net
 Server code never builds visuals: it sends small cues (effect, stage, data) and every
 client renders them locally, so motion is smooth and the server ships no parts or tweens.
]]
local Run=game:GetService("RunService")
local event=script.Parent:WaitForChild("Event")
local Net={}

function Net.Send(effect,stage,data)
 assert(Run:IsServer(),"Net.Send is server-only")
 event:FireAllClients(effect,stage,data)
end

function Net.Listen(fn)
 assert(Run:IsClient(),"Net.Listen is client-only")
 return event.OnClientEvent:Connect(fn)
end

function Net.Now()return workspace:GetServerTimeNow()end

return table.freeze(Net)
