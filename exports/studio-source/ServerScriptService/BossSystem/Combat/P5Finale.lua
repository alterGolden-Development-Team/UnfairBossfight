local Run = game:GetService("RunService")
local B = script:FindFirstAncestor("BossSystem")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local api = {}

function api.Stage(actor)
	return actor and actor:GetAttribute("P5Stage")
end
 -- he takes no damage once he is down to his last point of health
function api.Untouchable(actor)
	return api.Stage(actor) == "Claim"
end
 -- the end: no attacks, no chasing, no passives
function api.Busy(actor)
	return api.Stage(actor) == "Claim"
end
 -- the pace between his attacks: enraged once godmode is stripped, super enraged on the Enraged Gate
function api.GapScale(actor)
	if api.Stage(actor) == "Frenzy" then
		if require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Enraged() then
			return Config.FinaleSuperFrenzyGapScale or 0.3
		end
		return Config.FinaleFrenzyGapScale or 0.45
	end
	return 1
end
function api.IsSuper()
	return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Enraged()
end

function api.BeginFrenzy(actor)
	if api.Stage(actor) then
		return
	end
	actor:SetAttribute("P5Stage", "Frenzy")
	pcall(function()
		require(game.ReplicatedStorage.VFXEngine.Net).Send("P5Finale", "Frenzy", { Boss = actor })
	end)
end

 -- (Combat/P5SonicBlaster: his last words, then a bullet hell on the beat of its own soundtrack for exactly as long as the
 -- song plays). He takes no damage the whole time. Survive to the last note and the fight is won.
function api.BeginFinal(actor)
	if api.Untouchable(actor) or not actor.Parent or actor:GetAttribute("EncounterEnded") then
		return
	end
	local h = actor:FindFirstChildOfClass("Humanoid")
	if h and h.Health > 0 then
		h.Health = 1
		actor:SetAttribute("BossHealth", 1)
	end
	actor:SetAttribute("P5Stage", "Claim")
	pcall(function() require(B.Combat.P5ModeService).Clear(actor) end)
	task.spawn(function()
		local ok, won = pcall(require(B.Combat.P5SonicBlaster).Run, actor)
		if not ok then
			warn("[P5Finale] Sonic Blaster: " .. tostring(won))
			won = true  -- never leave the fight stuck on a boss nobody can hurt
		end
		if not won or not actor.Parent or actor:GetAttribute("EncounterEnded") then
			return
		end
		 -- he has flown into the black hole (2:54): the win screen comes up now; a few seconds later everyone is
		 -- brought back from the other dimension (his goodbye was said at the black hole, DialogueScripts FB1-FB6)
		if actor.Parent and not actor:GetAttribute("EncounterEnded") then
			require(B.Phases.PhaseController).Defeat(actor, true)
		end
		task.wait(3.5)
		if workspace:FindFirstChild("NothingDimension") then
			pcall(require(B.Combat.P5SonicBlaster).ReturnHome, actor)
		end
	end)
end

function api.HoldHealth(actor, hp)
	if actor:GetAttribute("Phase") ~= 5 or not actor:GetAttribute("GodStripped") or actor:GetAttribute("IsGoldenClone") then
		return hp
	end
	if hp <= 1 then
		hp = 1
		if not api.Untouchable(actor) then
			task.defer(api.BeginFinal, actor)
		end
	end
	return hp
end

function api.Update(actor)
	if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("EncounterEnded") then
		return
	end
	if not api.Stage(actor) and actor:GetAttribute("GodStripped") then
		api.BeginFrenzy(actor)
	end
end

 -- the stage keeps its own time
local BOSS = "alterGolden, the Nothing"
local tick = 0
Run.Heartbeat:Connect(function(dt)
	tick += dt
	if tick < 0.1 then
		return
	end
	tick = 0
	local actor = workspace:FindFirstChild(BOSS)
	if actor then
		api.Update(actor)
	end
end)

return api
