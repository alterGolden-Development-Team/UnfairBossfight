 -- Phase 5 "close in": the melee-only skills (Light Jab, Slam, Fire Ring, Shotgun Blast, the Fangs...) need his target within
 -- ~30 studs, but his attack gap is so short that he almost never walks over, so they hardly ever came up. When the target
 -- is farther than EncounterConfig.Phase5CloseInRange he now blinks in beside them (the P1.5 Teleportation flash), at most once
 -- per Phase5CloseInGap (x the difficulty's Recovery) and only Phase5CloseInChance of the time. AttackController calls Try
 -- just before it picks the next attack; AttackSelector then weights the close skills up (Phase5CloseWeight).
local B = script:FindFirstAncestor("BossSystem")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local FLAT = Vector3.new(1, 0, 1)
local contexts = setmetatable({}, { __mode = "k" })
local api = {}

function api.Try(actor, target)
	if (actor:GetAttribute("Phase") or 0) < 5 or not target or not target.Parent then
		return false
	end
	if actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("IsIllusion") or actor:GetAttribute("PhaseTransitionInProgress")
		or actor:GetAttribute("BlackHoleActive") == true or actor:GetAttribute("PolarisActive") == true
		or (actor:GetAttribute("HeavyCasts") or 0) > 0 then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if now < (actor:GetAttribute("P5CloseInAt") or 0) then
		return false
	end
	local root = actor:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not root or not targetRoot or root.Anchored then
		return false
	end
	if ((targetRoot.Position - root.Position) * FLAT).Magnitude <= (Config.Phase5CloseInRange or 38) then
		return false
	end
	actor:SetAttribute("P5CloseInAt", now + (Config.Phase5CloseInGap or 2.5) * Difficulty.Get(actor).Recovery)
	if math.random() > (Config.Phase5CloseInChance or 0.75) then
		return false
	end
	local ok, moved = pcall(function()
		local ctx = contexts[actor]
		if not ctx then
			ctx = require(B.Attacks.Shared.P5StrikeCore).Context(actor, "P5CloseIn")
			contexts[actor] = ctx
		end
		if not ctx.Valid() then
			return false
		end
		return ctx.Blink(ctx.Beside(target, Config.Phase5CloseInDistance or 14, math.random() * math.pi * 2))
	end)
	if not ok then
		warn("[P5CloseIn] " .. tostring(moved))
		return false
	end
	return moved == true
end

return api
