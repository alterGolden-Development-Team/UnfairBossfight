 -- P5Enraged: his godmode is stripped (TPService), so he is ENRAGED - every gap between his attacks shrinks to FinaleFrenzyGapScale
 -- (Combat/P5Finale.GapScale) until he is down to 1 health. Not shown on the Enraged Gate: there it is P5SuperEnraged.
return function(actor)
	local api = { IsPassive = true }
	function api.IsActive()
		return actor.Parent ~= nil and actor:GetAttribute("Phase") == 5 and actor:GetAttribute("GodStripped") == true
			and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("IsGoldenClone")
			and not require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Enraged()
	end
	function api.Tick() actor:SetAttribute("Passive_P5Enraged", api.IsActive()) end
	function api.Reset() if actor.Parent then actor:SetAttribute("Passive_P5Enraged", false) end end
	return api
end
