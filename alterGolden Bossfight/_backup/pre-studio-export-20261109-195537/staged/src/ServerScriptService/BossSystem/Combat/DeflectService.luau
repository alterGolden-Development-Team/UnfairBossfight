--[[
 DeflectService - the player's Deflect (E, StarterPlayerScripts BossClient.Presentation.DeflectClient).
 A deflectable attack calls Warn(char, kind, seconds) a moment before it lands - the white DEFLECT shield on that
 player - then TryDeflect(char, kind) when it lands: true means no damage.
  Tap  : press E any time while the shield is up (from DeflectEarlyGrace before it appears to DeflectLateGrace after
         it should have landed). A hit with no shield still takes a press within DeflectTapWindow of it.
  Hold : press E while the HOLD shield is up and keep it down for DeflectHoldTime; it is turned away while E is still
         down, or just after a full hold (DeflectReleaseGrace). Holding E from before the shield came up does nothing.
  Chain: a successful deflect keeps that kind open for DeflectChain seconds, so a flurry (Wild Hunt's claws, the
         Silent Cut follow-ups) can be turned away hit after hit once the first is timed.
  Mash : DeflectMashPresses presses with no shield up inside a second lock deflect for DeflectMashLock seconds.
 Deflects do not add TP; after godmode is stripped, a deflect cuts the boss for DeflectCounterDamage.
 Everyone sees the clash (sparks, a ring, the clang); the deflecter gets the flash and
 the camera kick too.
]]
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local B = script:FindFirstAncestor("BossSystem")
local api = {}
local state = setmetatable({}, { __mode = "k" })

local function remote(name)
	local r = game.ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = game.ReplicatedStorage
	end
	return r
end
local input = remote("DeflectInput")
local cue = remote("DeflectCue")

local function now()
	return workspace:GetServerTimeNow()
end
local function get(player)
	local s = state[player]
	if not s then
		s = { TapAt = -math.huge, HoldStart = -math.huge, ReleasedAt = -math.huge, HeldFor = 0, Holding = false, Chain = {},
			Warns = { Tap = {}, Hold = {} }, Whiffs = {}, LockedUntil = -math.huge }
		state[player] = s
	end
	return s
end

 -- the shields up for this kind right now (or that should have landed a moment ago); old ones are dropped
local function shields(s, kind, t)
	local list = s.Warns[kind] or {}
	local late = Config.DeflectLateGrace or 0.25
	for i = #list, 1, -1 do
		if t > list[i].To + late then
			table.remove(list, i)
		end
	end
	return list
end
local function anyShield(s, t)
	return #shields(s, "Tap", t) > 0 or #shields(s, "Hold", t) > 0 or t <= (s.Chain.Tap or 0) or t <= (s.Chain.Hold or 0)
end

input.OnServerEvent:Connect(function(player, kind)
	local s = get(player)
	local t = now()
	if kind == "Down" then
		if s.Holding then
			return
		end
		s.Holding = true
		if t < s.LockedUntil then
			s.HoldStart = -math.huge  -- locked out: this press counts for nothing
			return
		end
		s.TapAt = t
		s.HoldStart = t
	elseif kind == "Up" then
		if not s.Holding then
			return
		end
		s.Holding = false
		s.ReleasedAt = t
		s.HeldFor = t - s.HoldStart
	end
end)
Players.PlayerRemoving:Connect(function(player) state[player] = nil end)

function api.Active(char, kind)
	local player = char and Players:GetPlayerFromCharacter(char)
	local s = player and state[player]
	if not s then
		return false
	end
	local t = now()
	kind = kind or "Tap"
	if t <= (s.Chain[kind] or 0) then
		return true
	end
	local list = shields(s, kind, t)
	if #list == 0 then
		return false
	end
	if kind == "Hold" then
		local need = (Config.DeflectHoldTime or 0.2) - 0.05
		local window = Config.DeflectHoldWindow or 1.6
		local from = t - window  -- with no shield: a hold begun in the last DeflectHoldWindow seconds
		local earliest
		for _, w in ipairs(list) do
			earliest = math.min(earliest or math.huge, w.From - 0.3)
		end
		if earliest then from = math.max(from, earliest) end
		if s.HoldStart < from then
			return false
		end
		if s.Holding then
			return t - s.HoldStart >= need
		end
		return s.HeldFor >= need and t - s.ReleasedAt <= (Config.DeflectReleaseGrace or 0.25)
	end
	local early = Config.DeflectEarlyGrace or 0.15
	 -- overlapping kinds: E held down for a HOLD that is up right now also turns away a TAP hit landing inside it
	if s.Holding and #list > 0 and #shields(s, "Hold", t) > 0 and s.HoldStart > -math.huge then
		return true
	end
	for _, w in ipairs(list) do
		if s.TapAt >= w.From - early then
			return true
		end
	end
	return false
end

 -- when this player last pressed E (server time; a locked-out press doesn't count), for attacks beaten by mashing E
 -- rather than timing it (P5LightningDash)
function api.LastTap(char)
	local player = char and Players:GetPlayerFromCharacter(char)
	local s = player and state[player]
	return s and s.TapAt or -math.huge
end

 -- the shield cue on that player's avatar, `seconds` before a deflectable hit lands
function api.Warn(char, kind, seconds)
	local player = char and Players:GetPlayerFromCharacter(char)
	if player then
		kind = kind or "Tap"
		local t = now()
		local list = shields(get(player), kind, t)
		list[#list + 1] = { From = t, To = t + (seconds or 0.5) }
		cue:FireClient(player, "Warn", { Kind = kind, Time = seconds or 0.5 })
	end
end

 -- a deflect only damages him after his Phase 5 godmode is stripped; it never adds TP
local function reward(char, pos)
	pcall(function()
		local TP = require(B.Combat.TPService)
		local boss = TP.Boss()
		if not boss or boss:GetAttribute("Phase") ~= 5 or TP.Running(boss) then
			return
		end
		if (Config.DeflectCounterDamage or 0) > 0 then
			local ok, err = pcall(function()
				return require(B.Combat.AttackRegistry).For(boss, "BossDamageService").ApplyDamage(Config.DeflectCounterDamage, char, nil)
			end)
			if not ok then warn("[Deflect] counter damage failed: " .. tostring(err)) end
		end
	end)
	pcall(function()
		require(B.Presentation.CombatAudio).Emit(nil, "ParryContact", pos)
	end)
end

 -- call when a deflectable hit lands on `char`; true = deflected (deal no damage)
function api.TryDeflect(char, kind)
	if not api.Active(char, kind) then
		return false
	end
	local player = Players:GetPlayerFromCharacter(char)
	local chained = false
	if player then
		local s = get(player)
		chained = now() <= (s.Chain[kind or "Tap"] or 0)
		s.Chain[kind or "Tap"] = now() + (Config.DeflectChain or 0.35)
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	char:SetAttribute("DeflectCount", (char:GetAttribute("DeflectCount") or 0) + 1)
	local pos = root and root.Position
	cue:FireAllClients("Deflected", { Char = char, Kind = kind or "Tap", Pos = pos, Chained = chained })
	if pos then
		reward(char, pos)
	end
	return true
end

return api
