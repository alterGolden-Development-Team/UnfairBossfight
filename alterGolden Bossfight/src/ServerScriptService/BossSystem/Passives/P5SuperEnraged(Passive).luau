 -- P5SuperEnraged: the same, on the Enraged Gate - the gaps shrink to FinaleSuperFrenzyGapScale (Combat/P5Finale.GapScale)
return function(actor)
	local api = { IsPassive = true }
	function api.IsActive()
		return actor.Parent ~= nil and actor:GetAttribute("Phase") == 5 and actor:GetAttribute("GodStripped") == true
			and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("IsGoldenClone")
			and require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Enraged()
	end
	function api.Tick() actor:SetAttribute("Passive_P5SuperEnraged", api.IsActive()) end
	function api.Reset() if actor.Parent then actor:SetAttribute("Passive_P5SuperEnraged", false) end end
	return api
end
