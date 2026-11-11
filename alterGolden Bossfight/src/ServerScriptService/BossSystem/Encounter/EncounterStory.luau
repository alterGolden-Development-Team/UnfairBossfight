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
 
local function story(beginning, shieldBreak, identity, phase3, phase4, phase5)
  return {
    Beginning = {beginning}, ShieldBreak = {shieldBreak},
    Phase2Identity = identity, Phase3After = {phase3},
    Phase4After = {phase4}, Phase5After = {phase5},
  }
end
api.Variants = {
  Hellaven = {
    Beginning = {"So you came for what lies beyond alterGolden. Leave your hope at the gate.", "Past this line the rules are mine, and your fate is already written."},
    Phase15Failure = {"Beyond me there is no place for the unworthy."}, Phase15Success = {"So you survived the first judgment. Do not mistake that for mercy."},
    ShieldBreak = {"The shield falls. I do not."}, ShieldGateChallenge = {"You broke through the gate. Now I test what remains of you.", "Show me whether your classes can stand beyond my limits."},
    Phase35 = {"Half my shield is gone, and the truth is still veiled.", "Look carefully. The illusion beyond me begins now."},
    Phase45 = {"You have drawn my blood this far out. The arena will answer in kind.", "Let this field bloom with the price of your defiance."},
    Phase2BeforeIdentity = {"You have earned one truth about what I am beyond my limits."}, Phase2Identity = {"I am alterGolden...", "The True Imaginator. And this is what lies beyond me."},
    Phase2Power = {"I imagine past my own limits... and make it real."}, Phase2Art = {"Imagination Art...", "BEYOND: TIME."},
    Phase2AfterTime = {"Now show me what you can do when I stop holding myself back."}, Phase25 = {"You have impressed me. The real trial is still ahead."},
    Phase3After = {"Illusion is the strongest spell there is, and I have gone beyond it.", "Let us see if your eyes can save you."},
    Phase4After = {"The masks are gone. This is the truth beyond alterGolden. Survive it."}, Phase5Before = {"...Enough.", "You have forced me past every limit I had."}, Phase5After = {"Behold. Beyond alterGolden, unbound."},
  },
  Easy = story("Easy mode? Then I will make this a lesson instead of an execution.", "Good. I will keep the next part gentle.", {"I am alterGolden...", "The True Imaginator. I will give you a fair chance."}, "Illusions can be confusing. Watch closely and you can still win.", "I will show you my true spirit, but I will leave you room to survive it.", "You made it to the end. That was no small thing."),
  TrueHardcore = story("You chose to face alterGolden. I will give you the honest fight you came for.", "My shield is gone. Now the real duel begins.", {"I am alterGolden...", "The True Imaginator. I will not hold back."}, "Illusion is the strongest spell. Keep your focus, or it will be your last mistake.", "No masks remain. Face my true spirit without hesitation.", "You endured every phase. Now face my final form."),
  Hardcore = story("Hardcore, then. Every mistake will cost you, and I will make sure you remember each one.", "You broke my shield. Do not expect the fight to get easier.", {"I am alterGolden...", "The True Imaginator. You asked for this."}, "Illusion will punish every moment you look away.", "My true spirit is revealed. There will be no reprieve.", "You have reached the final phase. Prove you belong here."),
  NerfedHardcore = story("Normal Mode, then. I will teach you the fight without giving away the victory.", "A good strike. I will give you a moment before the next test.", {"I am alterGolden...", "The True Imaginator. I will keep this fight within reach."}, "Illusion is still dangerous. Take your time and read the pattern.", "My true spirit emerges. Stay sharp and you can survive.", "You made it through. Finish the fight and claim your victory."),
  TrueHardcoreEnraged = story("Facing me was only the beginning. My rage opens now.", "You broke the shield. Now survive what was sealed behind it.", {"I am alterGolden...", "The True Imaginator. Enraged, and done holding back."}, "The illusion ends. My rage has no mercy for hesitation.", "My true spirit is unbound. There is nowhere left to hide.", "This is the end of every path. I will make it final."),
  NerfedHardcoreEnraged = story("Normal Mode is over. The Enraged Gate opens, and I stop holding back.", "You broke my shield. Now face what Normal Mode kept restrained.", {"I am alterGolden...", "The True Imaginator. The lesson is over. Now witness my rage."}, "Every illusion is dangerous now. Focus, or the lesson ends here.", "My true spirit is unbound. Even Normal Mode cannot soften this truth.", "You survived the lesson. Now survive the fury."),
  HardcoreEnraged = story("Hardcore tested you. Enraged will finish the test.", "The shield is gone. So is my restraint.", {"I am alterGolden...", "The True Imaginator. Now witness my fury."}, "Every illusion is lethal now. Choose wrong and you fall.", "No masks. No mercy. Only my enraged spirit remains.", "You forced me this far. I will end this with everything I have."),
  EasyEnraged = story("Even this easy fight has pushed me too far. The Enraged Gate is open.", "You broke the shield. I cannot keep holding back.", {"I am alterGolden...", "The True Imaginator. Forgive me, but the restraint is gone."}, "The illusions have grown wild. Stay close and watch carefully.", "My true spirit is enraged. I will try to keep you alive.", "You survived my rage. End this before it rises again."),
  HellavenEnraged = story("Beyond alterGolden, and enraged. The final seal breaks. There will be no mercy past this gate.", "The shield falls, and my wrath takes its place.", {"I am alterGolden...", "The True Imaginator. Beyond every limit, fully unbound."}, "My illusions are no longer illusions out here. They are your end.", "Behold the truth I kept chained beyond myself. Survive it.", "I have gone as far beyond as I can go. Your story ends here."),
}
setmetatable(api, {
	__index = function(_, key)

		local id = Difficulty.Id()
		local variant = Difficulty.Enraged() == true and api.Variants[id .. "Enraged"] or nil
		variant = variant or api.Variants[id]
		return variant and variant[key] or base[key]
	end,
})
 
local difficultyLines = {
  Hellaven = { "Beyond alterGolden? Then you chose to face me past every limit, without mercy. Good. I will show you what that means." },
  TrueHardcore = { "alterGolden. Me, as I am. No safety net, no second chances. Let us see if your courage survives your skill." },
  Hardcore = { "Hardcore. You asked for a real fight. I will make every mistake count." },
  NerfedHardcore = { "Normal Mode... a little room to breathe. Do not mistake patience for weakness." },
  Easy = { "Easy mode? Then I will hold back. Try to enjoy the spectacle while it lasts." },
}
function api.PickLines(id)
  return difficultyLines[id] or (Difficulty.Profiles[id] and Difficulty.Profiles[id].PickLines) or {}
end
local ultimateLines = {
  ["P1GildedCataclysm(Ultimate)"] = {"Kneel beneath the weight of everything I have built!", "The crown cracks, and the world comes down with it!"},
  ["P1.5RoyalBow(Ultimate)"] = {"A royal decree needs no warning. Run.", "I have marked every path you could take. None lead out."},
  ["P2GoldenClock(Ultimate)"] = {"Time itself will hold still while I decide your fate.", "Your final second has arrived. It will last forever."},
  ["P2.5LastMinute(Ultimate)"] = {"One minute remains. Spend it wisely.", "I have taken your last minute. Now I take the rest."},
  ["P3EtherealAcumen(Ultimate)"] = {"I can see every answer. You have none.", "All your futures end at my hand."},
  ["P3PickThePupils(Ultimate)"] = {"Choose your pupil. Choose who falls first.", "The lesson is over. Now face the examiner."},
  ["P3.5TrueIllusion(Ultimate)"] = {"Your eyes betrayed you long ago. Your body is next.", "There is no true world left to return to."},
  ["P3.5MysteriousGuy(Ultimate)"] = {"You thought the mystery was the mask? Look closer.", "The stranger steps forward. Your escape disappears."},
  ["P4.5HeavenlyDisciple(Ultimate)"] = {"The heavens have chosen their disciple. They chose me.", "Look up. Even the sky has turned against you."},
  ["P4DeathScythe(Ultimate)"] = {"One clean cut. That is all the ending needs.", "I have harvested enough. Your turn."},
  ["P4DeathRoars(Ultimate)"] = {"Hear the roar of everything you failed to stop!", "Let the final roar bury your defiance."},
  ["P5Hyper-lasticBeam(Ultimate)"] = {"Space bends. Your last safe step is gone.", "I will fold the distance between us into nothing."},
  ["P5Polaris(Ultimate)"] = {"Find the north star. It is already aimed at you.", "The stars have aligned around your grave."},
  ["P5Finality(Ultimate)"] = {"This is the moment all moments were leading to.", "No next time. No next moment. Finality."},
  ["P5WildHunt(Ultimate)"] = {"Run, little prey. I want to hear the chase begin.", "The hunt ends when I say it ends."},
  ["P5NightTearer(Ultimate)"] = {"I will tear the night open and pull you through.", "Let the darkness remember what I did to you."},
  ["P5SilentCut(Ultimate)"] = {"You will hear nothing until it is over.", "No warning. No sound. Only the cut."},
  ["P5BlastBreath(Ultimate)"] = {"Breathe in. There will be no air left after this.", "The whole horizon is about to exhale."},
  ["P5TheGreatStorm(Ultimate)"] = {"The storm has waited long enough.", "Every living thing will bow to this weather."},
}
local ultimateLines = {
  ["P1GildedCataclysm(Ultimate)"] = {"Kneel beneath the weight of everything I have built!", "The crown cracks, and the world comes down with it!"},
  ["P1.5RoyalBow(Ultimate)"] = {"A royal decree needs no warning. Run.", "I have marked every path you could take. None lead out."},
  ["P2GoldenClock(Ultimate)"] = {"Time itself will hold still while I decide your fate.", "Your final second has arrived. It will last forever."},
  ["P2.5LastMinute(Ultimate)"] = {"One minute remains. Spend it wisely.", "I have taken your last minute. Now I take the rest."},
  ["P3EtherealAcumen(Ultimate)"] = {"I can see every answer. You have none.", "All your futures end at my hand."},
  ["P3PickThePupils(Ultimate)"] = {"Choose your pupil. Choose who falls first.", "The lesson is over. Now face the examiner."},
  ["P3.5TrueIllusion(Ultimate)"] = {"Your eyes betrayed you long ago. Your body is next.", "There is no true world left to return to."},
  ["P3.5MysteriousGuy(Ultimate)"] = {"You thought the mystery was the mask? Look closer.", "The stranger steps forward. Your escape disappears."},
  ["P4.5HeavenlyDisciple(Ultimate)"] = {"The heavens have chosen their disciple. They chose me.", "Look up. Even the sky has turned against you."},
  ["P4DeathScythe(Ultimate)"] = {"One clean cut. That is all the ending needs.", "I have harvested enough. Your turn."},
  ["P4DeathRoars(Ultimate)"] = {"Hear the roar of everything you failed to stop!", "Let the final roar bury your defiance."},
  ["P5Hyper-lasticBeam(Ultimate)"] = {"Space bends. Your last safe step is gone.", "I will fold the distance between us into nothing."},
  ["P5Polaris(Ultimate)"] = {"Find the north star. It is already aimed at you.", "The stars have aligned around your grave."},
  ["P5Finality(Ultimate)"] = {"This is the moment all moments were leading to.", "No next time. No next moment. Finality."},
  ["P5WildHunt(Ultimate)"] = {"Run, little prey. I want to hear the chase begin.", "The hunt ends when I say it ends."},
  ["P5NightTearer(Ultimate)"] = {"I will tear the night open and pull you through.", "Let the darkness remember what I did to you."},
  ["P5SilentCut(Ultimate)"] = {"You will hear nothing until it is over.", "No warning. No sound. Only the cut."},
  ["P5BlastBreath(Ultimate)"] = {"Breathe in. There will be no air left after this.", "The whole horizon is about to exhale."},
  ["P5TheGreatStorm(Ultimate)"] = {"The storm has waited long enough.", "Every living thing will bow to this weather."},
}
-- the Beyond alterGolden difficulty (id "Hellaven") has its own ultimate lines
local hellavenUltimateLines = {
  ["P1GildedCataclysm(Ultimate)"] = {"My throne will outlast your world.", "Beyond me there is no mercy left. Be crushed beneath my crown!"},
  ["P1.5RoyalBow(Ultimate)"] = {"Past my limits, there is nowhere left to run.", "The final arrow carries my sentence. Do not look away."},
  ["P2GoldenClock(Ultimate)"] = {"Out here I have all the time in the world. You have none.", "I stop the clock, and claim what remains."},
  ["P2.5LastMinute(Ultimate)"] = {"Your last minute belongs to me now.", "I will remember you for exactly one more minute."},
  ["P3EtherealAcumen(Ultimate)"] = {"I have seen every future beyond this one. You lose in all of them.", "The future is sealed. I have chosen your ending."},
  ["P3PickThePupils(Ultimate)"] = {"The lesson beyond me begins. Choose who learns it first.", "No more lessons. Only the final exam."},
  ["P3.5TrueIllusion(Ultimate)"] = {"Beyond every illusion, there is only me.", "I will leave you with one final vision: your defeat."},
  ["P3.5MysteriousGuy(Ultimate)"] = {"Out here I have no need for masks. Remember that face.", "The mystery ends here. I stand before you, beyond it."},
  ["P4.5HeavenlyDisciple(Ultimate)"] = {"Even the heavens answer to what lies beyond me.", "I bring judgment down from beyond the sky."},
  ["P4DeathScythe(Ultimate)"] = {"I have gathered enough souls. Yours will complete the harvest.", "One final harvest, past every limit. No soul escapes the blade."},
  ["P4DeathRoars(Ultimate)"] = {"Let me hear your courage break.", "This roar is my answer to your defiance."},
  ["P5Hyper-lasticBeam(Ultimate)"] = {"Beyond my limits, space folds until every road leads to me.", "No distance can shelter you from me now."},
  ["P5Polaris(Ultimate)"] = {"I set that star in the sky to mark your end.", "The north star falls under my command."},
  ["P5Finality(Ultimate)"] = {"This is the last page. This is where your story stops.", "There is no after this. I have gone beyond and made certain of it."},
  ["P5WildHunt(Ultimate)"] = {"The hunt is released. I will enjoy the chase.", "No refuge, no finish line. I own this hunt."},
  ["P5NightTearer(Ultimate)"] = {"I will split the night and drag you into its heart.", "The dark beyond me is mine. You belong to it."},
  ["P5SilentCut(Ultimate)"] = {"Beyond me there is no warning. Only silence.", "You will not hear me coming."},
  ["P5BlastBreath(Ultimate)"] = {"I take one breath. The whole sky answers.", "This is the last air I will allow you."},
  ["P5TheGreatStorm(Ultimate)"] = {"I call the storm, and the world obeys.", "Let the storm carry my final word."},
}
function api.UltimateLine(actor, attackName)
  local hellaven = Difficulty.Id(actor) == "Hellaven"
  local pair = hellaven and hellavenUltimateLines[attackName] or ultimateLines[attackName]
  if not pair then return nil end
  return pair[Difficulty.Enraged() == true and 2 or 1]
end
return api
