local BossSystem = script:FindFirstAncestor("BossSystem")
 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local EffectService = require(BossSystem.Combat.EffectService)

local remotes = ReplicatedStorage:FindFirstChild("BossEncounterRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "BossEncounterRemotes"
	remotes.Parent = ReplicatedStorage
end
local event = remotes:FindFirstChild("CataclysmQTE")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "CataclysmQTE"
	event.Parent = remotes
end

local api = {}
local sessions = {}
local random = Random.new()
local keys = { "W", "A", "S", "D" }
local Session = {}
Session.__index = Session

local function send(session, action, data)
	if session.Player.Parent == Players then
		event:FireClient(session.Player, action, data)
	end
end

local function finish(session, outcome, reason)
	if session.Result then
		return
	end
	session.Result = outcome
	session.Reason = reason
	if sessions[session.Player] == session then
		sessions[session.Player] = nil
	end
	if session.DeadlineCast then
		session.DeadlineCast:Dispose()
		session.DeadlineCast = nil
	end
	 
	if session.OnResolved then
		local ok, err = xpcall(function()
			session.OnResolved(outcome, reason)
		end, debug.traceback)
		if not ok then
			warn("Cataclysm QTE release failed: " .. tostring(err))
		end
	end
	send(session, "Close", { Id = session.Id, Outcome = outcome, Reason = reason })
end

function Session:IsFinished()
	return self.Result ~= nil
end
function Session:Outcome()
	return self.Result
end
function Session:Close(reason)
	finish(self, "Cancelled", reason or "interrupted")
end

function api.Begin(player, actor, options)
	options = options or {}
	if sessions[player] or not player or player.Parent ~= Players then
		return nil
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local bossHum = actor and actor:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or not bossHum or bossHum.Health <= 0 then
		return nil
	end
	local sequence = {}
	 
	 
	local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
	local keyCount = Difficulty.Mercy("QTEKeys", actor) or 4
	local window = Difficulty.Mercy("QTETime", actor) or 3.5
	for index = 1, keyCount do
		sequence[index] = keys[random:NextInteger(1, #keys)]
	end
	local now = workspace:GetServerTimeNow()
	local session = setmetatable({
		Id = HttpService:GenerateGUID(false),
		Player = player,
		Actor = actor,
		Character = char,
		Humanoid = hum,
		BossHumanoid = bossHum,
		Sequence = sequence,
		Progress = 0,
		StartedAt = now,
		Deadline = now + window,
		OnResolved = options.OnResolved,
	}, Session)
	sessions[player] = session
	 
	 
	session.DeadlineCast = EffectService.NewCast(actor, "CataclysmQTEDeadline", window)
	session.DeadlineCast.OnExpire = function()
		finish(session, "Failure", "timeout")
	end
	session.DeadlineCast:Step(function()
		if
			session.Player.Parent ~= Players
			or session.Player.Character ~= session.Character
			or not session.Character.Parent
			or session.Humanoid.Health <= 0
			or not session.Actor.Parent
			or session.BossHumanoid.Health <= 0
			or session.Actor:GetAttribute("AIEnabled") == false
		then
			session:Close("interrupted")
			return false
		elseif workspace:GetServerTimeNow() >= session.Deadline then
			finish(session, "Failure", "timeout")
			return false
		end
		return not session.Result
	end)
	send(session, "Show", { Id = session.Id, Sequence = sequence, Deadline = session.Deadline, Duration = 3.5 })
	return session
end

function api.CancelForActor(actor, reason)
	local pending = {}
	for _, session in pairs(sessions) do
		if session.Actor == actor then
			table.insert(pending, session)
		end
	end
	for _, session in ipairs(pending) do
		session:Close(reason)
	end
end

event.OnServerEvent:Connect(function(player, id, key)
	local session = sessions[player]
	if not session or type(id) ~= "string" or id ~= session.Id then
		return
	end
	if session.Character ~= player.Character or not session.Character.Parent or session.Humanoid.Health <= 0 then
		session:Close("character unavailable")
		return
	end
	if workspace:GetServerTimeNow() >= session.Deadline then
		finish(session, "Failure", "timeout")
		return
	end
	if type(key) ~= "string" or #key ~= 1 or key ~= session.Sequence[session.Progress + 1] then
		finish(session, "Failure", "incorrect input")
		return
	end
	session.Progress += 1
	if session.Progress == #session.Sequence then
		finish(session, "Success", "sequence completed")
	else
		send(session, "Progress", { Id = session.Id, Progress = session.Progress })
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then
		session:Close("player left")
	end
end)

return api
