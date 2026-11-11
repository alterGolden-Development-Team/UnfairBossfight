local Physics = game:GetService("PhysicsService")
local api = {}
local group = "GoldenBossGhost"
if not Physics:IsCollisionGroupRegistered(group) then
	Physics:RegisterCollisionGroup(group)
end
function api.Configure(actor)
	for _, v in ipairs(Physics:GetRegisteredCollisionGroups()) do
		Physics:CollisionGroupSetCollidable(group, v.name, false)
	end
	local h = actor:FindFirstChildOfClass("Humanoid")
	if h then
		h.EvaluateStateMachine = false
	end
	for _, v in ipairs(actor:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = group
			v.CanCollide = false
			v.CanTouch = false
		end
	end
	actor.HumanoidRootPart.Anchored = true
	actor:SetAttribute("PassThroughEnabled", true)
end
return api
