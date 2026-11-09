local api = {
	AttackStart = 18.2,
	CloneWaveAt = 13.4,
	PauseAt = 98,
	ResumeAt = 116,
	FinaleAt = 126,
	EndAt = 138,
	CloneCount = 100,
	BeforeBreak = 70,
	Cues = {
		{ At = 18.18, Until = 21.35, Text = [====[[[tell me,]] do you think that your whole life could be a sham?]====], Illusion = true },
		{ At = 21.38, Until = 23.85, Text = [====[Like the ads in the [[spam.]] OF YOUR MAILBOX [[man?]]]====], Illusion = true },
		{ At = 23.88, Until = 26.29, Text = [====[Well, just take my advice, and [[wing it on the mic]]]====], Illusion = true },
		{ At = 26.32, Until = 29.11, Text = [====[Cuz to keep your mind concise, ya gotta know to [[roll or die]]]====], Illusion = true },
		{ At = 29.14, Until = 31.37, Text = [====[So how’s things? [[ENJOY THE SINGING?]]]====], Illusion = true },
		{ At = 31.4, Until = 34.01, Text = [====[Does it sting? the siren’s spinning!]====], Illusion = true },
		{ At = 34.04, Until = 35.79, Text = [====[Grab a string, and feel the ring-]====], Illusion = true },
		{ At = 35.82, Until = 38.41, Text = [====[Embellish every meaning of the bringers of the light-]====], Illusion = true },
		{ At = 38.44, Until = 40.63, Text = [====[In the darkness and the cold, and in stories dating old]====], Illusion = true },
		{ At = 40.66, Until = 42.33, Text = [====[Every person that you know, is just FANTASY]====], Illusion = true },
		{ At = 42.36, Until = 45.31, Text = [====[As the prophecies foretold, there’s a light inside your soul]====], Illusion = true },
		{ At = 45.34, Until = 47.75, Text = [====[With the truth, the promise in your starving heart]====], Illusion = true },
		{ At = 47.78, Until = 50.31, Text = [====[And the swords are swinging, ring-a-dinging,]====], Illusion = true },
		{ At = 50.34, Until = 52.53, Text = [====[While you cling to your dying wish.]====], Illusion = true },
		{ At = 52.56, Until = 55.03, Text = [====[When the [[shadow??]] starts to grow, and your light is running low]====], Illusion = true },
		{ At = 55.06, Until = 57.37, Text = [====[[[Don’t forget]] You’ll never be the playing part.]====], Illusion = true },
		{ At = 57.4, Until = 59.47, Text = [====[But a part of wicked whim is giving everything a twist]====], Illusion = true },
		{ At = 59.5, Until = 61.77, Text = [====[And letting all your fascination find [[a peck of pickled]] [[pipis]]]====], Illusion = true },
		{ At = 61.8, Until = 63.55, Text = [====[If you know [[new york]], you need [[new yoke]]]====], Illusion = true },
		{ At = 63.58, Until = 64.81, Text = [====[You know you need unique [[you woke]]]====], Illusion = true },
		{ At = 64.84, Until = 67.25, Text = [====[So tell me a unique new joke packed neatly as the fleeting folk that]====], Illusion = true },
		{ At = 67.28, Until = 69.27, Text = [====[Fight through thick and thin and let the stars take on their wish]====], Illusion = true },
		{ At = 69.3, Until = 71.89, Text = [====[Of finding joy and whimsy in the very world we’re sitting in]====], Illusion = true },
		{ At = 71.92, Until = 74.09, Text = [====[But if the worst of worry “some” is to worry just a little]====], Illusion = true },
		{ At = 74.12, Until = 76.95, Text = [====[Then the worst to word the sum of worries is to warn the middle of the-]====], Illusion = true },
		{ At = 76.98, Until = 78.21, Text = [====[World]====], Illusion = true },
		{ At = 78.24, Until = 80.53, Text = [====[Where fact and fiction align]====], Illusion = true },
		{ At = 80.56, Until = 81.33, Text = [====[No [[rules to play by]]]====], Illusion = true },
		{ At = 81.36, Until = 83.81, Text = [====[Psychotic minds live incredible lives]====], Illusion = true },
		{ At = 83.84, Until = 87.03, Text = [====[As long as their world stays within their EYE]====], Illusion = true },
		{ At = 87.06, Until = 89.31, Text = [====[No longer will I cry]====], Illusion = true },
		{ At = 89.34, Until = 91.79, Text = [====[I’ll never question why]====], Illusion = true },
		{ At = 91.82, Until = 93.97, Text = [====[My rhythm turned the tides]====], Illusion = true },
		{ At = 94, Until = 97.25, Text = [====[And now your fate has gone awry]====], Illusion = true },
		{ At = 115.8, Until = 117.49, Text = [====[Rising above our heaven’s hell]====], Illusion = true },
		{ At = 117.52, Until = 119.85, Text = [====[Just like a spinning [[Carousel]]]====], Illusion = true },
		{ At = 119.88, Until = 122.33, Text = [====[When there are no more stories left]====], Illusion = true },
		{ At = 122.36, Until = 125.13, Text = [====[What will the storyteller tell?]====], Illusion = true },
		{ At = 125.16, Until = 127.31, Text = [====[Once was a time our legends told]====], Illusion = true },
		{ At = 127.34, Until = 129.33, Text = [====[Too many years had gone and sold]====], Illusion = true },
		{ At = 129.36, Until = 131.77, Text = [====[Three titled heroes would uphold]====], Illusion = true },
		{ At = 131.8, Until = 134.47, Text = [====[For only they could save their world from-]====], Illusion = true },
		{ At = 0.86, Until = 2.75, Text = "YOU CALL YOURSELF HEROES?" },
		{ At = 3.0, Until = 4.45, Text = "YOU'RE JUST A BUNCH OF CLOWNS" },
		{ At = 4.58, Until = 5.27, Text = "[[big]] CLOWNS" },
		{ At = 5.28, Until = 6.45, Text = "WITH [[big]] HATS" },
		{ At = 6.56, Until = 7.65, Text = "THE WHOLE SHABANG!" },
		{ At = 7.78, Until = 9.4, Text = "clowns that need to be caged" },
		{ At = 9.52, Until = 11.1, Text = "jailed, discarded" },
		{ At = 11.22, Until = 12.03, Text = "YOU MIGHT [[see]]" },
		{ At = 12.04, Until = 13.38, Text = "WHERE THIS IS GOING" },
		{ At = 13.44, Until = 14.65, Text = "BUT HAVE NOT YET SEEN" },
		{ At = 14.66, Until = 16.2, Text = "FOR WHAT IS COMING" },
		{ At = 98, Until = 98.5, Text = "ENOUGH." },
		{ At = 98.56, Until = 100.4, Text = "YOU KIDS ARE STEPPING OUT OF LINES!" },
		{ At = 100.94, Until = 102.48, Text = "BEHOLD THE POWER OF [[CLANG]]" },
		{ At = 102.92, Until = 104.84, Text = "now only for 3.99!" },
		{ At = 105.84, Until = 106.83, Text = "LIGHTBRINGER COME ONE AND ALL." },
		{ At = 106.84, Until = 108.13, Text = "If ya want to join the show then just call [[now!]]." },
		{ At = 108.24, Until = 109.23, Text = "Didja hit a wall, Or are ya all dumb?" },
		{ At = 109.24, Until = 110.57, Text = "Cause seem to me You're [[just in luck]]" },
		{ At = 110.72, Until = 111.62, Text = "You unlocked the world and ya saw your toys" },
		{ At = 111.63, Until = 112.92, Text = "Why not sell your SOUL for [[half the price]]" },
		{ At = 112.98, Until = 114.03, Text = "Dont act as if you got your voice," },
		{ At = 114.04, Until = 115.65, Text = "'cause in this world YOU HAVE NO CHOICE" },
	},
}
function api.Attacking(time)
	return time >= api.AttackStart and time < api.EndAt
		and (time < api.PauseAt or time >= api.ResumeAt)
end
 
 
function api.BreakFor(count)
	count = count or api.CloneCount
	return math.clamp(math.floor(count * api.BeforeBreak / api.CloneCount + 0.5), 2, math.max(2, count - 2))
end
function api.VolleyAt(index, count)
	count = count or api.CloneCount
	assert(index >= 1 and index <= count and index % 1 == 0, "Invalid clone index")
	local beforeBreak = api.BreakFor(count)
	if index <= beforeBreak then
		local x = (index - 1) / math.max(1, beforeBreak - 1)
		return api.AttackStart + (95.4 - api.AttackStart) * (3 * x - x * x) / 2
	end
	local x = (index - beforeBreak - 1) / math.max(1, count - beforeBreak - 1)
	return api.ResumeAt + 9.28 * (1.15 * x - 0.15 * x * x)
end
table.sort(api.Cues, function(a, b) return a.At < b.At end)
for _, cue in ipairs(api.Cues) do table.freeze(cue) end
table.freeze(api.Cues)
return table.freeze(api)
