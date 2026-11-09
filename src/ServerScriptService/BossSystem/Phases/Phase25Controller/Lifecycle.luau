-- Phase25Controller: starting, cancelling and querying the phase, and reacting to shield changes.
-- Registers its api.<Name> functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local api, Audio, Config, Effects, Locomotion, Placement, Story, alive, recordFor = Core.api, Core.Audio, Core.Config, Core.Effects, Core.Locomotion, Core.Placement, Core.Story, Core.alive, Core.recordFor
local records = Core.records

function api.Start(actor)
	return recordFor(actor)
end
function api.BeginPhase25(actor)
	if not alive(actor) or actor:GetAttribute("Phase") ~= 2 or actor:GetAttribute("Phase25Triggered") then
		return false
	end
	local record = recordFor(actor)
	actor:SetAttribute("Phase25Triggered", true)
	actor:SetAttribute("Phase25TransitionInProgress", true)
	actor:SetAttribute("PhaseTransitionInProgress", true)
	actor:SetAttribute("TransitionKeepsTemporal", true)
	actor:SetAttribute("Invulnerable", true)
	actor:SetAttribute("ActiveAttackToken", nil)
	actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
	actor:SetAttribute("Phase", 2.5)
	Audio.Phase(actor, 2.5)
	local root = actor.HumanoidRootPart
	local frame = Placement.Validate(actor, root.CFrame) or root.CFrame
	local cast = Effects.NewCast(actor, "Phase25Story", Story.Duration(Story.Phase25) + 1)
	cast.TimeStopExempt = true
	record.Transition = cast
	local token = Locomotion.Pose(actor, { RightShoulder = { 15, 0, -10 }, LeftShoulder = { 0, 0, -5 } }, 0.2, true)
	cast:Step(function()
		root.CFrame = frame
		root.AssemblyLinearVelocity = Vector3.zero
		return true
	end)
	cast.OnDispose = function()
		if record.Transition ~= cast then
			return
		end
		record.Transition = nil
		actor:SetAttribute("Phase25TransitionInProgress", false)
		actor:SetAttribute("TransitionKeepsTemporal", false)
		Locomotion.ReleasePose(actor, token, 0.2)
		if alive(actor) and actor:GetAttribute("Phase") == 2.5 and not actor:GetAttribute("Phase3IntroActive") then
			actor:SetAttribute("PhaseTransitionInProgress", false)
			actor:SetAttribute("Invulnerable", false)
			actor:SetAttribute("AttackInProgress", false)
			actor:SetAttribute("AIEnabled", true)
			actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.25)
			api.ActivateFutureSight(actor)
		end
	end
	task.spawn(function()
		local ok, err = xpcall(function()
			Story.Play(actor, Story.Phase25, {
				Valid = function()
					return cast:Alive() and alive(actor) and actor:GetAttribute("Phase") == 2.5
				end,
			})
		end, debug.traceback)
		if not ok then
			warn("Phase25 story: " .. tostring(err))
		end
		cast:Dispose()
	end)
	return true
end

function api.OnShieldChanged(actor)
	if not alive(actor) then
		return
	end
	local shield = actor:GetAttribute("Shield") or 0
	if actor:GetAttribute("Phase") == 2 and shield > 0 and shield <= Config.Phase25ShieldThreshold then
		api.BeginPhase25(actor)
	end
	if
		actor:GetAttribute("Phase") == 2.5
		and shield > 0
		and shield <= Config.LastMinuteShieldGate
		and not actor:GetAttribute("LastMinuteUsed")
	then
		api.BeginLastMinute(actor)
	end
end
function api.Cancel(actor, reason)
	local record = records[actor]
	if not record then
		return
	end
	if record.Transition then
		record.Transition.CancelReason = reason
		record.Transition:Dispose()
	end
	if record.Prediction then
		record.Prediction:Dispose()
	end
	if record.FalseFuture then
		record.FalseFuture:Dispose()
	end
	local previews = {}
	for cast in pairs(record.Previews) do
		table.insert(previews, cast)
	end
	for _, cast in ipairs(previews) do
		cast:Dispose()
	end
	if record.Dodge then
		record.Dodge:Dispose()
	end
	if record.LastMinute then
		record.LastMinute.CancelReason = reason
		record.LastMinute:Dispose()
	end
	actor:SetAttribute("FutureSightCharges", 0)
	actor:SetAttribute("FutureSightDodging", false)
	actor:SetAttribute("FutureSightUntil", 0)
	actor:SetAttribute("FalseFutureCharges", 0)
	actor:SetAttribute("FalseFutureUntil", 0)
	actor:SetAttribute("ShieldDamageLocked", false)
	actor:SetAttribute("LastMinuteAttackMultiplier", 1)
	actor:SetAttribute("LastMinutePhase25Weight", 1)
	actor:SetAttribute("LastMinuteStage", 0)
	records[actor] = nil
end
function api.IsActive(actor)
	local record = records[actor]
	return record
			and ((record.Transition and record.Transition:Alive()) or (record.LastMinute and record.LastMinute:Alive()))
		or false
end

return api
