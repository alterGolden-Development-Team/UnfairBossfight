local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Run = game:GetService("RunService")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Encounter = require(BossSystem.Players.PlayerEncounter)
local api = {}
 -- trimmed for pacing (full dialogue: ServerStorage.VFXBackups.EncounterStory_full)
api.Beginning = {
	"Hello. Welcome to my battlefield.",
	"You came here for the main reward, didn't you?",
	"Defeat me, and the prize is yours.",
	"Let me see whether your strength is truly worthy.",
}
api.Phase15Failure = { "You are not worthy enough." }
api.Phase15Success = { "So the rumors weren't exaggerated.", "You're quite an interesting one." }
api.ShieldBreak = { "Not yet.", "That was only the warm-up." }
api.ShieldGateChallenge = {
 "You surprised me by alot, now I'm gonna test further more to see if you can handle this",
 "Elementalist. Swordsmaster. Show me what they can handle.",
}
api.Phase35 = {
 "Half my shield, and you still trust your eyes?",
 "Then watch closely. The real illusion begins now.",
}
api.Phase45 = {
 "You've cut deeper than anyone before you.",
 "Then let this battlefield bloom crimson.",
}
api.Phase2BeforeIdentity = {
	"Perhaps I should tell you something.",
}
api.Phase2Identity = {
	"My name is alterGolden...",
	"The True Imaginator.",
}
api.Phase2Power = {
	"My power allows me to imagine things... and bring them into reality.",
}
api.Phase2Art = { "Imagination Art...", "TIME." }
api.Phase2AfterTime = {
	"I hope you'll make this interesting.",
}
api.Phase25 = { "You're putting on quite a show.", "But I've barely begun to utilize this power." }
api.Phase3Before = {}
api.Phase3After = {
	"Well... have you heard that the strongest spell right now is Illusion?",
	"Let's find out!",
}
 -- trimmed to one line so the phase 4 transition doesn't stall the fight
api.Phase4After = {
	"No masks. My true spirit. Survive the truth.",
}

api.Phase5Before = {
	"...Enough.",
	"You've cut me down to almost nothing.",
}
api.Phase5After = { "Behold. The True Imaginator, unbound." }
function api.LineDuration(text, hold)
	local count = 0
	for _ in utf8.graphemes(text) do
		count += 1
	end
	return count * Config.DialogueCharacterInterval + (hold or 0.55)
end
function api.Duration(lines, hold)
	local total = 0
	for _, text in ipairs(lines) do
		total += api.LineDuration(text, hold)
	end
	return total
end
function api.Play(actor, lines, options)
	options = options or {}
	local generation = actor and actor:GetAttribute("PhaseGeneration") or 0
	local humanoid = actor and actor:FindFirstChildOfClass("Humanoid")
	local function valid()
		if
			actor
			and (
				not actor.Parent
				or not humanoid
				or humanoid.Health <= 0
				or actor:GetAttribute("EncounterEnded")
				or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
			)
		then
			return false
		end
		return not options.Valid or options.Valid() == true
	end
	local function waitFor(seconds)
		if options.Wait then
			return options.Wait(seconds)
		end
		local ends = os.clock() + seconds
		while valid() and os.clock() < ends do
			Run.Heartbeat:Wait()
		end
		return valid()
	end
	for index, text in ipairs(lines) do
		if not valid() then
			return false
		end
		 
		text = require(BossSystem.Encounter.DialogueScripts).Translate(text, actor)
		local duration = api.LineDuration(text, options.Hold)
		if options.Prefix and actor then
			actor:SetAttribute(options.Prefix .. "DialogueIndex", index)
			actor:SetAttribute(options.Prefix .. "LastDialogue", text)
		end
		if options.OnLine then
			options.OnLine(text, index)
		end
		Encounter.Say(text, options.Player, { Duration = duration + 0.3, ScreenOnly = true })
		if not waitFor(duration) or not valid() then
			return false
		end
	end
	return true
end
 
 
 
 
 
local Difficulty = require(Shared:WaitForChild("Config"):WaitForChild("DifficultyConfig"))
local base = {}
for key, value in pairs(api) do
	if type(value) == "table" then
		base[key] = value
	end
end
for key in pairs(base) do
	api[key] = nil
end
 
api.Variants = {}
setmetatable(api, {
	__index = function(_, key)
		local variant = api.Variants[Difficulty.Id()]
		return variant and variant[key] or base[key]
	end,
})
 
function api.PickLines(id)
	local profile = Difficulty.Profiles[id]
	return profile and profile.PickLines or {}
end
return api
