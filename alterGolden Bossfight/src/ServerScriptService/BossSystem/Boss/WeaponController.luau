local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local api = {}
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local records = setmetatable({}, { __mode = "k" })
local serial = 0
local phaseVisuals = setmetatable({}, { __mode = "k" })
function api.RefreshPhaseVisuals(actor)
	local hidden = math.floor(actor:GetAttribute("Phase") or 1) == 3
	for _, value in ipairs(actor:GetDescendants()) do
		if value:IsA("BasePart") and value.Name == "GoldenBackHalo" then
			local alpha = value:GetAttribute("Phase3HaloBaseAlpha")
			if alpha == nil then
				alpha = value.Transparency
				value:SetAttribute("Phase3HaloBaseAlpha", alpha)
			end
			value.Transparency = hidden and 1 or alpha
		end
	end
	actor:SetAttribute("Phase3BackHaloHidden", hidden)
end
local function watchPhaseVisuals(actor)
	if phaseVisuals[actor] then
		return
	end
	phaseVisuals[actor] = {
		actor:GetAttributeChangedSignal("Phase"):Connect(function()
			api.RefreshPhaseVisuals(actor)
		end),
		actor.DescendantAdded:Connect(function(value)
			if value:IsA("BasePart") and value.Name == "GoldenBackHalo" and math.floor(actor:GetAttribute("Phase") or 1) == 3 then
				api.RefreshPhaseVisuals(actor)
			end
		end),
	}
end
function api.SwordGrip()
	return CFrame.new(0, 0, -Config.BossSwordGripOffset) * CFrame.Angles(0, math.rad(Config.BossSwordGripRoll), 0)
end
function api.ConfigureGrip(actor)
	local sword = actor:FindFirstChild("Basic Sword")
	if not sword or not sword:IsA("Tool") then
		return false
	end
	 
	 
	 
	 
	local desired = api.SwordGrip()
	sword.Grip = desired
	local grip = actor:FindFirstChild("RightGrip", true) or actor:FindFirstChild("BossSwordGrip", true)
	if grip and grip:IsA("JointInstance") and grip.Part1 == sword:FindFirstChild("Handle") then
		grip.C1 = desired
	end
	return true
end
local function capture(actor)
	watchPhaseVisuals(actor)
	local record = records[actor]
	if record then
		return record
	end
	local sword = actor:FindFirstChild("Basic Sword")
	if not sword then
		return nil
	end
	api.ConfigureGrip(actor)
	local handle = sword:FindFirstChild("Handle")
	local grip = actor:FindFirstChild("RightGrip", true) or actor:FindFirstChild("BossSwordGrip", true)
	record = { Sword = sword, Handle = handle, Grip = grip, Endpoint = grip and grip.Part1, Leases = {} }
	records[actor] = record
	return record
end
local function park(actor, record)
	if actor:GetAttribute("UnarmedCombat") ~= true or next(record.Leases) then
		return
	end
	if record.Grip and record.Grip.Parent then
		record.Grip.Part1 = nil
	end
	record.Sword.Parent = nil
	actor:SetAttribute("TemporarySwordActive", false)
end
function api.Get(actor)
	local record = capture(actor)
	return record and record.Sword
end
function api.Acquire(actor)
	local record = capture(actor)
	if not record then
		return nil
	end
	serial += 1
	local lease = serial
	record.Leases[lease] = true
	if record.Sword.Parent ~= actor then
		record.Sword.Parent = actor
		local grip = record.Grip
		if grip and grip.Parent and grip.Part0 and record.Handle then
			record.Handle.CFrame = grip.Part0.CFrame * grip.C0 * grip.C1:Inverse()
			grip.Part1 = record.Endpoint or record.Handle
		end
	end
	actor:SetAttribute("TemporarySwordActive", actor:GetAttribute("UnarmedCombat") == true)
	return lease
end
function api.Release(actor, lease)
	local record = records[actor]
	if not record then
		return
	end
	if lease then
		record.Leases[lease] = nil
	end
	park(actor, record)
end
function api.SetUnarmed(actor, enabled)
	local record = capture(actor)
	actor:SetAttribute("UnarmedCombat", enabled == true)
	api.RefreshPhaseVisuals(actor)
	if record then
		if enabled then
			park(actor, record)
		else
			local lease = api.Acquire(actor)
			api.Release(actor, lease)
		end
	end
end
function api.CopyTo(owner, clone)
	local original = capture(owner)
	if not original then
		return false
	end
	 
	 
	local existing = clone:FindFirstChild("Basic Sword")
	if existing then
		return true
	end
	for _, name in ipairs({ "RightGrip", "BossSwordGrip" }) do
		local stale = clone:FindFirstChild(name, true)
		if stale then
			stale:Destroy()
		end
	end
	local sword = original.Sword:Clone()
	sword.Parent = clone
	for _, joint in ipairs(sword:GetDescendants()) do
		if joint:IsA("JointInstance") and (joint.Name == "RightGrip" or joint.Name == "BossSwordGrip") then
			joint:Destroy()
		end
	end
	local handle = sword:FindFirstChild("Handle")
	local source = original.Grip
	if source and handle then
		local grip = source:Clone()
		grip.Part0 = source.Part0 and clone:FindFirstChild(source.Part0.Name, true)
		grip.Part1 = handle
		grip.Parent = grip.Part0 or handle
		if grip.Part0 then
			handle.CFrame = grip.Part0.CFrame * grip.C0 * grip.C1:Inverse()
		end
	end
	capture(clone)
	return true
end
 
 
function api.Mirror(owner, clone)
	local original = capture(owner)
	local copy = capture(clone)
	if not original or not copy then
		return
	end
	api.SetUnarmed(clone, true)
	if original.Sword.Parent == owner then
		if not copy.MirrorLease then
			copy.MirrorLease = api.Acquire(clone)
		end
	elseif copy.MirrorLease then
		local lease = copy.MirrorLease
		copy.MirrorLease = nil
		api.Release(clone, lease)
	end
end
function api.Clear(actor)
	local visualConnections = phaseVisuals[actor]
	if visualConnections then
		for _, connection in ipairs(visualConnections) do
			connection:Disconnect()
		end
		phaseVisuals[actor] = nil
	end
	local record = records[actor]
	if record then
		table.clear(record.Leases)
		if actor.Parent then
			 
			 
			actor:SetAttribute("UnarmedCombat", false)
			local lease = api.Acquire(actor)
			api.Release(actor, lease)
		elseif record.Sword.Parent ~= actor then
			record.Sword:Destroy()
		end
	end
	records[actor] = nil
end
return api
