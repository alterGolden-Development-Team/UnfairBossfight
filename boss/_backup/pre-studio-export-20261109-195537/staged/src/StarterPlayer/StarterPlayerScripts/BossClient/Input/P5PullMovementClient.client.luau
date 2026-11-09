local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local FLAT=Vector3.new(1,0,1)
local character,humanoid,root
local forces={}
local active={}
local connections={}
local function clear()
 for _,connection in ipairs(connections)do connection:Disconnect()end
 table.clear(connections) table.clear(forces) table.clear(active)
 character,humanoid,root=nil,nil,nil
end
local function track(force)
 if force:IsA("LinearVelocity") and (force.Name=="FinalityPull" or force.Name=="BlackHolePull")then
  forces[force]=true
 end
end
local function bind(char)
 clear()
 character=char
 local h=char:WaitForChild("Humanoid",10)
 local r=char:WaitForChild("HumanoidRootPart",10)
 if character~=char or player.Character~=char or not h or not r then return end
 humanoid,root=h,r
 for _,force in ipairs(r:GetChildren())do track(force)end
 connections[#connections+1]=r.ChildAdded:Connect(track)
 connections[#connections+1]=r.ChildRemoved:Connect(function(force)forces[force]=nil end)
end
local step=Run.PreSimulation:Connect(function()
 if not root or not root.Parent or not humanoid or humanoid.Health<=0 then return end
 local movement=humanoid.MoveDirection*humanoid.WalkSpeed*FLAT
 if character:GetAttribute("MovementLocked") or character:GetAttribute("TimeFrozen")then movement=Vector3.zero end
 local velocity=root.AssemblyLinearVelocity*FLAT
 local mass=root.AssemblyMass
 table.clear(active)
 local drift=Vector3.zero
 local speedLimit,acceleration=0,0
 for force in pairs(forces)do
  if force.Parent~=root then forces[force]=nil continue end
  local pull=force:GetAttribute("PullDrift")
  local rate=force:GetAttribute("PullAcceleration")
  if force.Enabled and typeof(pull)=="Vector3" and type(rate)=="number"then
   active[#active+1]=force
   drift+=pull
   speedLimit=math.max(speedLimit,pull.Magnitude)
   acceleration=math.max(acceleration,rate)
  end
 end
 if #active==0 or mass<=0 or mass==math.huge then return end
 if drift.Magnitude>speedLimit then drift=drift.Unit*speedLimit end
 local target=movement+drift
 local free=character:GetAttribute("Dashing") or character:GetAttribute("PredictedDashActive")
  or velocity.Magnitude>humanoid.WalkSpeed*1.75+speedLimit
 local forceLimit=free and Vector2.zero or Vector2.one*(mass*acceleration/#active)
 for _,force in ipairs(active)do
  force.PlaneVelocity=Vector2.new(target.X,target.Z)
  force.MaxPlanarAxesForce=forceLimit
 end
end)
local added=player.CharacterAdded:Connect(bind)
local removing=player.CharacterRemoving:Connect(function(char)if character==char then clear()end end)
if player.Character then task.spawn(bind,player.Character)end
script.Destroying:Connect(function()
 clear()step:Disconnect()added:Disconnect()removing:Disconnect()
end)
