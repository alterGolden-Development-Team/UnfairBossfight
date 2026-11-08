--[[
 DeflectService - the player's Deflect (E, StarterPlayerScripts BossClient.Presentation.DeflectClient).
  Tap  : pressing E opens a short window (DeflectTapWindow); a tap hit landing inside it is turned away.
  Hold : E held for DeflectHoldTime (0.5s) or longer turns away hold hits (and tap hits) while it stays down.
 A deflectable attack calls Warn(char, kind, seconds) a moment before it lands (the shield cue over that
 player's avatar), then TryDeflect(char, kind) when it lands: true means no damage. A press can't open a
 new tap window right after the last (DeflectTapCooldown), so mashing E doesn't work.
]]
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
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

input.OnServerEvent:Connect(function(player, kind)
	local s = state[player]
	if not s then
		s = { DownAt = -math.huge, Holding = false }
		state[player] = s
	end
	if kind == "Down" then
		if now() - s.DownAt >= (Config.DeflectTapCooldown or 0.45) then
			s.DownAt = now()
		end
		s.Holding = true
	elseif kind == "Up" then
		s.Holding = false
	end
end)
Players.PlayerRemoving:Connect(function(player) state[player] = nil end)

function api.Active(char, kind)
	local player = char and Players:GetPlayerFromCharacter(char)
	local s = player and state[player]
	if not s then
		return false
	end
	local held = s.Holding and now() - s.DownAt >= (Config.DeflectHoldTime or 0.5) - 0.08
	if kind == "Hold" then
		return held
	end
	return held or now() - s.DownAt <= (Config.DeflectTapWindow or 0.35)
end

 -- the shield cue on that player's avatar, `seconds` before a deflectable hit lands
function api.Warn(char, kind, seconds)
	local player = char and Players:GetPlayerFromCharacter(char)
	if player then
		cue:FireClient(player, "Warn", { Kind = kind or "Tap", Time = seconds or 0.5 })
	end
end

 -- call when a deflectable hit lands on `char`; true = deflected (deal no damage)
function api.TryDeflect(char, kind)
	if not api.Active(char, kind) then
		return false
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	char:SetAttribute("DeflectCount", (char:GetAttribute("DeflectCount") or 0) + 1)
	cue:FireAllClients("Deflected", { Char = char, Kind = kind or "Tap", Pos = root and root.Position })
	return true
end

return api
