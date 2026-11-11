local Collection = game:GetService("CollectionService")
local Runtime = require(script:FindFirstAncestor("BossSystem").Combat.CombatRuntime)
local Appearance = {}
function Appearance.Create(character, position)
	local old = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = old
	if not copy then return nil end
	local swordSource
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") and item:FindFirstChild("Handle") then swordSource = item; break end
	end
	swordSource = swordSource or game.ServerStorage.BossEncounter.Assets.ClassicSwordTemplate
	for _, item in ipairs(copy:GetDescendants()) do
		if item:IsA("BaseScript") or item:IsA("Tool") or item:IsA("ForceField") or item:IsA("Sound")
			or item:IsA("Highlight") or item:IsA("BillboardGui") or item:IsA("BodyMover")
			or item:IsA("AlignPosition") or item:IsA("AlignOrientation") or item:IsA("LinearVelocity") then
			item:Destroy()
		end
	end
	for _, item in ipairs({copy, table.unpack(copy:GetDescendants())}) do
		for name in pairs(item:GetAttributes()) do if name:sub(1,3) ~= "RBX" then item:SetAttribute(name,nil) end end
		for _, tag in ipairs(Collection:GetTags(item)) do Collection:RemoveTag(item,tag) end
		if item:IsA("BasePart") then
			item.Anchored=false;item.CanCollide=false;item.CanTouch=false;item.CanQuery=false
			item.AssemblyLinearVelocity=Vector3.zero;item.AssemblyAngularVelocity=Vector3.zero
		elseif item:IsA("Motor6D") then item.Transform=CFrame.identity end
	end
	local root, hum = copy:FindFirstChild("HumanoidRootPart"), copy:FindFirstChildOfClass("Humanoid")
	if not root or not hum then copy:Destroy();return nil end
	copy.Name = character.Name
	copy:SetAttribute("IsPlayerCopy",true)
	copy:SetAttribute("IsIllusion",true)
	hum.DisplayName = character.Humanoid.DisplayName
	hum.BreakJointsOnDeath=false;hum.RequiresNeck=false;hum.EvaluateStateMachine=false
	hum.MaxHealth=character.Humanoid.MaxHealth;hum.Health=hum.MaxHealth
	root.Anchored=true;copy.PrimaryPart=root
	copy.Parent=Runtime.Effects;copy:PivotTo(position)
	local tool = swordSource:Clone()
	for _,s in ipairs(tool:GetDescendants()) do if s:IsA("BaseScript") then s:Destroy() end end
	tool.CanBeDropped=false
	tool.Parent=copy
	local hand=copy:FindFirstChild("RightHand") or copy:FindFirstChild("Right Arm")
	local handle=tool:FindFirstChild("Handle")
	if hand and handle then
		local oldGrip=hand:FindFirstChild("RightGrip");if oldGrip then oldGrip:Destroy() end
		handle.Anchored=false;handle.CanCollide=false;handle.CanQuery=false;handle.CanTouch=false;handle.Massless=true
		local grip=Instance.new("Motor6D")
		grip.Name="RightGrip";grip.Part0=hand;grip.Part1=handle
		grip.C0=CFrame.new(0,-hand.Size.Y*0.5,0)*CFrame.Angles(-math.pi/2,0,0)
		grip.C1=tool.Grip;grip.Parent=hand
	end
	local joints={}
	for _,joint in ipairs(copy:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Name~="RightGrip" then
			joints[joint]={Base=joint.C0,Name=joint.Name}
		end
	end
	local record={Model=copy,Root=root,Humanoid=hum,Joints=joints}
	require(script.Parent.Animation).Attach(record)
	return record
end
return Appearance