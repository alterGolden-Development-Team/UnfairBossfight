local BossSystem = script:FindFirstAncestor("BossSystem")
 
 
local Run = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Rules=require(game.ReplicatedStorage.BossShared.Config.AttackLifecycleRules)
local api = {}
local pool, leases, timers, casts, containers = {}, {}, {}, {}, {}
local MAX_POOL = 256
local serial = 0
local Time
local managedTweens = setmetatable({}, { __mode = "k" })
local lastStopped = false
local function clock(owner)
	Time = Time or require(BossSystem.Mechanics.Time.TimeEffectController)
	return Time.EncounterNow(owner)
end
function api.AcquirePart()
	local p = table.remove(pool) or Instance.new("Part")
	serial += 1
	leases[p] = { id = serial, tweens = {} }
	p.Shape = Enum.PartType.Block
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end
function api.LeaseId(object)
	local lease = leases[object]
	return lease and lease.id
end
function api.Tween(_, object, info, properties)
	local tween = TweenService:Create(object, info, properties)
	if object:IsA("BasePart") and object:GetAttribute("TimeStopExempt") ~= true then
		managedTweens[tween] = { Object = object, Lease = leases[object], Paused = false }
	end
	local lease = leases[object]
	if lease then
		table.insert(lease.tweens, tween)
	end
	tween.Completed:Once(function()
		managedTweens[tween] = nil
		if lease and leases[object] == lease then
			local index = table.find(lease.tweens, tween)
			if index then
				table.remove(lease.tweens, index)
			end
		end
	end)
	return tween
end
api.Create = api.Tween
function api.Release(object)
	if not object then
		return
	end
	local lease = leases[object]
	if lease then
		leases[object] = nil
		for _, t in ipairs(lease.tweens) do
			managedTweens[t] = nil
			t:Cancel()
		end
		object.Parent = nil
		for _, child in ipairs(object:GetChildren()) do
			child:Destroy()
		end
		for name in pairs(object:GetAttributes()) do
			object:SetAttribute(name, nil)
		end
		if #pool < MAX_POOL then
			table.insert(pool, object)
		else
			object:Destroy()
		end
	else
		for _, child in ipairs(object:GetChildren()) do
			api.Release(child)
		end
		object:Destroy()
	end
end
function api.ReleaseAfter(object, seconds, tweens)
	table.insert(
		timers,
		{ object = object, at = clock(nil) + math.max(0, seconds), lease = leases[object], tweens = tweens }
	)
end
function api.AddItem(_, object, seconds)
	api.ReleaseAfter(object, seconds)
end
function api.TrackContainer(folder, actor)
	containers[folder] = actor
end
function api.NewCast(actor, name, lifetime)
	local reference = actor and actor:FindFirstChild("EncounterOwner")
	local owner = reference and reference:IsA("ObjectValue") and reference.Value or actor
	local born = clock(owner)
	local cast = {
		actor = actor,
		owner = owner,
		PersistsAfterTargetDeath = not Rules.PlayerDeathCancelsAttack,
		ownerHumanoid = owner and owner:FindFirstChildOfClass("Humanoid"),
		name = name,
		expires = born + (lifetime or 60),
		objects = {},
		steps = {},
		scheduled = {},
		closed = false,
		born = born,
		realBorn = os.clock(),
	}
	function cast:Now()
		return self.TimeStopExempt and self.born + os.clock() - self.realBorn or clock(self.owner)
	end
	function cast:Alive()
		return not self.closed and self:Now() < self.expires
	end
	function cast:Add(object)
		self.objects[object] = leases[object] or true
		return object
	end
	function cast:Schedule(seconds, fn)
		local job = { at = self:Now() + seconds, fn = fn }
		local index = #self.scheduled + 1
		while index > 1 and self.scheduled[index - 1].at > job.at do
			index -= 1
		end
		table.insert(self.scheduled, index, job)
		return job
	end
	function cast:Reschedule(job, seconds)
		if self.closed or not job then
			return false
		end
		local index = table.find(self.scheduled, job)
		if not index then
			return false
		end
		table.remove(self.scheduled, index)
		job.at = self:Now() + math.max(0, seconds)
		index = #self.scheduled + 1
		while index > 1 and self.scheduled[index - 1].at > job.at do
			index -= 1
		end
		table.insert(self.scheduled, index, job)
		return true
	end
	function cast:Step(fn)
		table.insert(self.steps, fn)
	end
	function cast:Dispose()
		if self.closed then
			return
		end
		self.closed = true
		casts[self] = nil
		if self.OnDispose then
			local ok, err = xpcall(self.OnDispose, debug.traceback)
			if not ok then
				warn(self.name .. " cleanup: " .. tostring(err))
			end
		end
		for object, lease in pairs(self.objects) do
			if lease == true or leases[object] == lease then
				api.Release(object)
			end
		end
		table.clear(self.objects)
		table.clear(self.steps)
		table.clear(self.scheduled)
		self.actor = nil
		self.owner = nil
		self.ownerHumanoid = nil
	end
	casts[cast] = true
	return cast
end
function api.Stats()
	local n = 0
	for _ in pairs(casts) do
		n += 1
	end
	return { PooledParts = #pool, ActiveCasts = n, Timers = #timers }
end
function api.CancelOwner(owner, reason, except)
	local selected = {}
	for cast in pairs(casts) do
		if cast.owner == owner and cast ~= except then
			table.insert(selected, cast)
		end
	end
	for _, cast in ipairs(selected) do
		cast.CancelReason = reason or "Owner cancelled"
		cast:Dispose()
	end
	return #selected
end
 
 
 
 -- the casts an actor has running right now (CloneController waits for a Past clone's own casts before its next move)
function api.CastsOf(actor)
	local list = {}
	for cast in pairs(casts) do
		if cast.actor == actor and not cast.closed then
			list[cast] = true
		end
	end
	return list
end
function api.CancelEmitter(actor,reason,predicate)
	local selected = {}
	for cast in pairs(casts) do
		if cast.actor==actor and (not predicate or predicate(cast)) then
			table.insert(selected, cast)
		end
	end
	for _, cast in ipairs(selected) do
		cast.CancelReason = reason or "Emitter cancelled"
		cast:Dispose()
	end
	return #selected
end
Run.Heartbeat:Connect(function(dt)
	local now = clock(nil)
	local stopped = Time.IsStopped(nil)
	if stopped ~= lastStopped then
		lastStopped = stopped
		for tween, record in pairs(managedTweens) do
			if stopped and tween.PlaybackState == Enum.PlaybackState.Playing then
				tween:Pause()
				record.Paused = true
			elseif not stopped and record.Paused then
				record.Paused = false
				if
					tween.PlaybackState == Enum.PlaybackState.Paused
					and record.Object.Parent
					and (record.Lease == nil or leases[record.Object] == record.Lease)
				then
					tween:Play()
				else
					managedTweens[tween] = nil
				end
			end
		end
	elseif stopped then
		for tween, record in pairs(managedTweens) do
			if tween.PlaybackState == Enum.PlaybackState.Playing then
				tween:Pause()
				record.Paused = true
			end
		end
	end
	for i = #timers, 1, -1 do
		local t = timers[i]
		if now >= t.at then
			timers[i] = timers[#timers]
			timers[#timers] = nil
			if t.lease == nil or leases[t.object] == t.lease then
				if t.tweens then
					for _, tween in ipairs(t.tweens) do tween:Cancel() end
				end
				api.Release(t.object)
			end
		end
	end
	for cast in pairs(casts) do
		local castNow = cast:Now()
		local owner = cast.owner
		local ownerHumanoid = cast.ownerHumanoid
		if
			owner
			and (
				not owner.Parent
				or owner:GetAttribute("EncounterEnded")
				or (ownerHumanoid and ownerHumanoid.Health <= 0)
			)
		then
			cast:Dispose()
		elseif castNow >= cast.expires then
			if cast.OnExpire then
				local ok, err = xpcall(cast.OnExpire, debug.traceback)
				if not ok then
					warn(cast.name .. ": " .. tostring(err))
				end
			end
			cast:Dispose()
		else
			local effectiveDt = cast.TimeStopExempt and dt or Time.EncounterDelta(cast.owner, dt)
			while cast.scheduled[1] and castNow >= cast.scheduled[1].at do
				local job = table.remove(cast.scheduled, 1)
				local ok, err = xpcall(job.fn, debug.traceback)
				if not ok then
					warn(cast.name .. ": " .. tostring(err))
					cast:Dispose()
					break
				end
				if cast.closed then
					break
				end
			end
			if not cast.closed and (effectiveDt > 0 or cast.TimeStopExempt) then
				for i = #cast.steps, 1, -1 do
					local ok, result = xpcall(cast.steps[i], debug.traceback, effectiveDt, castNow)
					if not ok then
						warn(cast.name .. ": " .. tostring(result))
						cast:Dispose()
						break
					end
					if cast.closed then
						break
					end
					if result == false then
						table.remove(cast.steps, i)
					end
				end
			end
		end
	end
	for folder, actor in pairs(containers) do
		if not folder.Parent then
			containers[folder] = nil
		elseif not actor.Parent and not folder:FindFirstChildWhichIsA("Instance") then
			containers[folder] = nil
			folder:Destroy()
		end
	end
end)
return api
