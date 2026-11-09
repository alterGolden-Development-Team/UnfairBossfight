local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Audio = require(BossSystem.Presentation.CombatAudio)
local records = setmetatable({}, { __mode = "k" })
local api = {}
function api.Begin(actor)
	local record = records[actor]
	if not record or record.Cast.closed then
		local cast = Effects.NewCast(actor, "GoldenGuard", math.huge)
		cast.TimeStopExempt = true
		local root = actor:FindFirstChild("HumanoidRootPart")
		local bubble = Effects.AcquirePart()
		bubble.Name = "GoldenGuardBarrier"
		bubble.Shape = Enum.PartType.Ball
		bubble.Size = Vector3.one * 10
		bubble.Color = Color3.fromRGB(255, 221, 55)
		bubble.Transparency = 0.78
		bubble:SetAttribute("TimeStopExempt", true)
		bubble.Parent = Runtime.Effects
		cast:Add(bubble)
		record = { Cast = cast, Tokens = {}, Generation = actor:GetAttribute("PhaseGeneration") or 0 }
		records[actor] = record
		actor:SetAttribute("GoldenGuard", true)
		actor:SetAttribute("GoldenGuardReduction", Config.GoldenGuardReduction)
		Audio.Emit(actor, "GuardActivate", root)
		cast.OnDispose = function()
			for token in pairs(record.Tokens) do
				token.closed = true
			end
			if records[actor] == record then
				records[actor] = nil
				if actor.Parent then
					actor:SetAttribute("GoldenGuard", false)
					actor:SetAttribute("GoldenGuardReduction", 0)
				end
			end
		end
		cast:Step(function()
			if
				not root
				or not root.Parent
				or actor:GetAttribute("PhaseTransitionInProgress")
				or (actor:GetAttribute("PhaseGeneration") or 0) ~= record.Generation
			then
				cast:Dispose()
				return false
			end
			bubble.CFrame = root.CFrame
			return true
		end)
	end
	local token = { closed = false }
	record.Tokens[token] = true
	function token:Dispose()
		if self.closed then
			return
		end
		self.closed = true
		record.Tokens[self] = nil
		if next(record.Tokens) == nil then
			record.Cast:Dispose()
		end
	end
	return token
end
function api.Run(actor, callback)
	local token = api.Begin(actor)
	local result = table.pack(xpcall(callback, debug.traceback))
	token:Dispose()
	if not result[1] then
		error(result[2], 0)
	end
	return table.unpack(result, 2, result.n)
end
function api.Clear(actor)
	local record = records[actor]
	if record then
		record.Cast:Dispose()
	end
end
return api
