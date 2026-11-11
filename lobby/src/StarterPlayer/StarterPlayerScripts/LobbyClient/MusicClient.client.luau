--!nonstrict
-- The lobby's soundtrack. One looping track per world, crossfaded when the player's Area attribute changes:
-- the Sanctum (and the stage) get the main theme, each portal world its own piece.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local TRACKS = {
	Hub = { id = 140566103832758, volume = 0.45 }, -- Dreams Above the Rain
	Stage = { id = 140566103832758, volume = 0.45 },
	Palace = { id = 140658234151287, volume = 0.5 }, -- Time (the golden portal)
	Island = { id = 131586509457092, volume = 0.55 }, -- Calming ocean sounds (the private island)
	Forest = { id = 86247184974274, volume = 0.45 }, -- DREAMCORE (the divided wood)
}

local FADE = 1.6

local group = Instance.new("SoundGroup")
group.Name = "LobbyMusic"
group.Parent = SoundService

local sounds = {} -- track id -> Sound, shared by areas that use the same piece
local current

local function soundFor(track)
	local sound = sounds[track.id]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "Track" .. track.id
		sound.SoundId = "rbxassetid://" .. track.id
		sound.Looped = true
		sound.Volume = 0
		sound.SoundGroup = group
		sound.Parent = group
		sounds[track.id] = sound
	end
	return sound
end

local function fade(sound, volume, stopAfter)
	local tween = TweenService:Create(sound, TweenInfo.new(FADE, Enum.EasingStyle.Sine), { Volume = volume })
	tween:Play()
	if stopAfter then
		tween.Completed:Connect(function()
			if sound ~= current then
				sound:Stop()
			end
		end)
	end
end

local function play(area)
	local track = TRACKS[area] or TRACKS.Hub
	local sound = soundFor(track)
	if sound == current then
		fade(sound, track.volume)
		return
	end
	local previous = current
	current = sound
	if not sound.IsPlaying then
		sound:Play()
	end
	fade(sound, track.volume)
	if previous then
		fade(previous, 0, true)
	end
end

player:GetAttributeChangedSignal("Area"):Connect(function()
	play(player:GetAttribute("Area") or "Hub")
end)
play(player:GetAttribute("Area") or "Hub")
