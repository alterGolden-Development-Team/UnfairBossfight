local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Replicated = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Marketplace = game:GetService("MarketplaceService")
local Content = game:GetService("ContentProvider")
local Run = game:GetService("RunService")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
local EncounterConfig = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local remote = Replicated:WaitForChild("BossCombatEffects")
if SoundService:GetAttribute("BossMusicMuted") == nil then
	SoundService:SetAttribute("BossMusicMuted", false)
end
local musicMuted = SoundService:GetAttribute("BossMusicMuted") == true
local folder = Instance.new("Folder")
folder.Name = "BossAudioEmitters"
folder.Parent = workspace
 
 
local combat = Instance.new("SoundGroup")
combat.Name = "BossCombatMix"
combat.Volume = 1
combat.Parent = SoundService
local priorityGroup = Instance.new("SoundGroup")
priorityGroup.Name = "BossPriorityMix"
priorityGroup.Volume = 1
priorityGroup.Parent = SoundService
local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "BossMusicMix"
musicGroup.Volume = musicMuted and 0 or 1
musicGroup.Parent = SoundService
local limiter = Instance.new("CompressorSoundEffect")
limiter.Threshold = -10
limiter.Ratio = 4
limiter.Attack = 0.02
limiter.Release = 0.15
limiter.Parent = combat
local music = Instance.new("Sound")
music.Name = "BossPhaseSoundtrack"
music.Looped = true
music.Volume = Config.MusicVolume
music.SoundGroup = musicGroup
music.Parent = SoundService
local dialogueVoice = Instance.new("Sound")
dialogueVoice.Name = "BossDialogueVoice"
dialogueVoice.SoundId = Config.Assets.DialogueVoice
dialogueVoice.Volume = Config.DialogueVoiceVolume
dialogueVoice.Looped = true
dialogueVoice.SoundGroup = priorityGroup
dialogueVoice.Parent = SoundService
local dialogueVoiceEnds = 0
local dialogueVoiceOwner, dialogueVoiceToken
local dialogueVoiceReplayAt = 0
local voices = {}
local random = Random.new()
local cueCounts = {}
local loopCount = 0
local duckUntil = 0
local duckVolume = 1
local connections = {}
local elapsed = 0
local illusionToken
local illusionStartedAt
local illusionEnded = false
local sonicStartedAt  -- Phase 5's final attack: its song starts at this server time and plays once (boss SonicBlasterMusicStartedAt)
local currentTrack
local currentAsset
local Difficulty=require(Shared.Config.DifficultyConfig)
local failedAssets = {}
local trackSetAt = 0
local function trackAsset(key)
	if not key then return nil end
	local asset = Config.MusicAsset(key, Difficulty.Id())
	if asset and failedAssets[asset] then
		asset = Config.Assets[key == "Phase15" and "Hero" or key] or asset
	end
	return asset
end
local trackPositions = {}
local trackNames = {}
local requestedNames = {}
local destroyed = false
table.insert(
	connections,
	SoundService:GetAttributeChangedSignal("BossMusicMuted"):Connect(function()
		musicMuted = SoundService:GetAttribute("BossMusicMuted") == true
		musicGroup.Volume = musicMuted and 0 or (os.clock() < duckUntil and duckVolume or 1)
	end)
)
local musicBlockedOwner, musicBlockedPhase, musicBlockedGeneration
local preloaded = {}
local function preloadAssets(assets)
	local pending = {}
	for _, asset in ipairs(assets) do
		if not preloaded[asset] then
			preloaded[asset] = true
			table.insert(pending, asset)
		end
	end
	if #pending > 0 then
		task.spawn(function()
			-- preload as Sound instances: raw id strings get fetched as images and fail with "Asset type does not match"
			local refs = {}
			for _, asset in ipairs(pending) do
				local sound = Instance.new("Sound")
				sound.SoundId = asset
				table.insert(refs, sound)
			end
			pcall(Content.PreloadAsync, Content, refs)
			for _, sound in ipairs(refs) do
				sound:Destroy()
			end
		end)
	end
end
preloadAssets({ Config.Assets.TrueIllusion, Config.Assets.DialogueVoice, Config.Assets.DeathScytheGoodbye })
for _, asset in pairs(Config.UploadedCues) do
	preloaded[asset] = true
end
local function release(voice)
	if not voice.Busy then
		return
	end
	cueCounts[voice.Cue] = math.max(0, (cueCounts[voice.Cue] or 1) - 1)
	if voice.IsLoop then
		loopCount = math.max(0, loopCount - 1)
	end
	voice.Sound:Stop()
	voice.Sound.Looped = false
	voice.Busy = false
	voice.Token = nil
	voice.Emitter = nil
	voice.Owner = nil
	voice.Waiting = false
	voice.IsLoop = false
	voice.Sound:SetAttribute("CombatVoiceBusy", false)
end
local function startVoice(voice)
	if not voice.Busy then
		return
	end
	local sound = voice.Sound
	if voice.FullLength and (not sound.IsLoaded or sound.TimeLength <= 0) then
		voice.Waiting = true
		return
	end
	local offset = not voice.PreserveStart and voice.ServerStartedAt and math.max(0, workspace:GetServerTimeNow() - voice.ServerStartedAt) or 0
	local duration = voice.Duration
		or (voice.FullLength and sound.TimeLength / sound.PlaybackSpeed or voice.DefaultDuration)
	if not voice.IsLoop and offset >= duration then
		release(voice)
		return
	end
	voice.Waiting = false
	voice.Expires = voice.IsLoop and math.huge or os.clock() + duration - offset + 0.15
	sound.TimePosition = offset * sound.PlaybackSpeed
	sound:SetAttribute("CombatExpectedDuration", duration)
	sound:SetAttribute("CombatPlaybackStartedAt", os.clock())
	sound:Play()
end
local function newVoice()
	local emitter = Instance.new("Part")
	emitter.Name = "PooledCombatAudioEmitter"
	emitter.Size = Vector3.one * 0.1
	emitter.Transparency = 1
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanTouch = false
	emitter.CanQuery = false
	emitter.Parent = folder
	local attachment = Instance.new("Attachment")
	attachment.Parent = emitter
	local sound = Instance.new("Sound")
	sound.SoundGroup = combat
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = Config.MinDistance
	sound.Parent = attachment
	local equalizer = Instance.new("EqualizerSoundEffect")
	equalizer.Parent = sound
	local voice = { Part = emitter, Sound = sound, EQ = equalizer, Busy = false }
	voice.Ended = sound.Ended:Connect(function()
		if not sound.Looped then
			release(voice)
		end
	end)
	voice.Loaded = sound.Loaded:Connect(function()
		if voice.Waiting then
			startVoice(voice)
		end
	end)
	table.insert(voices, voice)
	return voice
end
local function acquire(priority)
	for _, voice in ipairs(voices) do
		if not voice.Busy then
			return voice
		end
	end
	if #voices < Config.MaxVoices then
		return newVoice()
	end
	local chosen
	for _, voice in ipairs(voices) do
		if
			voice.Priority < priority
			and (
				not chosen
				or voice.Priority < chosen.Priority
				or voice.Priority == chosen.Priority and voice.Started < chosen.Started
			)
		then
			chosen = voice
		end
	end
	if chosen then
		release(chosen)
	end
	return chosen
end
local function duck(duration, volume)
	local now = os.clock()
	if now >= duckUntil then
		duckVolume = 1
	end
	duckUntil = math.max(duckUntil, now + duration)
	duckVolume = math.min(duckVolume, volume)
end
local function play(data)
	local definition = Config.Cues[data.Cue]
	if not definition or typeof(data.Position) ~= "Vector3" then
		return
	end
	local now = os.clock()
	if data.Token and definition.Loop and loopCount >= Config.MaxLoopVoices then
		return
	end
	for _, layer in ipairs(definition.Layers) do
		if (cueCounts[data.Cue] or 0) >= definition.MaxVoices then
			break
		end
		local voice = acquire(definition.Priority)
		if not voice then
			break
		end
		local sound = voice.Sound
		voice.Busy = true
		voice.Cue = data.Cue
		voice.Token = data.Token
		voice.Emitter = data.Emitter
		voice.Owner = data.Owner
		voice.Priority = definition.Priority
		voice.Started = now
		voice.Expires = now + Config.AssetLoadTimeout
		voice.IsLoop = data.Token ~= nil and definition.Loop
		voice.FullLength = definition.FullLength
		voice.PreserveStart = definition.PreserveStart
		voice.Duration = data.Duration
		voice.DefaultDuration = definition.Duration
		voice.ServerStartedAt = data.StartedAt
		voice.Waiting = false
		cueCounts[data.Cue] = (cueCounts[data.Cue] or 0) + 1
		if voice.IsLoop then
			loopCount += 1
		end
		voice.Part.CFrame = CFrame.new(data.Position)
		voice.EQ.LowGain = layer.Low
		voice.EQ.MidGain = layer.Mid
		voice.EQ.HighGain = layer.High
		sound.SoundId = layer.ToolSound and data.Overrides and data.Overrides[layer.ToolSound] or layer.Asset
		sound.SoundGroup = definition.Priority >= 4 and priorityGroup or combat
		sound.PlaybackSpeed = definition.FixedPitch and layer.Pitch
			or math.clamp((data.Pitch or layer.Pitch) * random:NextNumber(0.96, 1.04), 0.25, 3)
		sound.Volume = math.clamp(layer.Volume * (data.VolumeScale or 1), 0, definition.VolumeCap or 1.2)
		sound.RollOffMaxDistance = definition.Range
		sound:SetAttribute("CombatCue", data.Cue)
		sound:SetAttribute("CombatUploadedClip", definition.FullLength == true)
		sound:SetAttribute("CombatVoiceBusy", true)
		sound:SetAttribute("CombatLoadFailed", false)
		sound:SetAttribute("CombatServerStartedAt", data.StartedAt)
		sound:SetAttribute("CombatFiniteToken", data.Duration and data.Token or nil)
		sound.Looped = voice.IsLoop
		sound.TimePosition = 0
		startVoice(voice)
	end
end
local function stopToken(token)
	for _, voice in ipairs(voices) do
		if voice.Busy and voice.Token == token then
			release(voice)
		end
	end
end
local function publishTrack(key)
	local asset = trackAsset(key)
	SoundService:SetAttribute("BossSoundtrackName", key and (Config.TrackNames[asset] or trackNames[asset] or Config.MusicNames[key]) or "")
	SoundService:SetAttribute("BossSoundtrackAssetId", asset or "")
	SoundService:SetAttribute("BossSoundtrackPlaying", key ~= nil)
	if not key or key == "SonicBlaster" or Config.TrackNames[asset] or requestedNames[asset] then  -- (the final attack's song keeps its own name)
		return
	end
	requestedNames[asset] = true
	task.spawn(function()
		local id = tonumber(asset:match("%d+"))
		if not id then
			return
		end
		local ok, info = pcall(Marketplace.GetProductInfo, Marketplace, id, Enum.InfoType.Asset)
		if destroyed then
			return
		end
		if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" and not info.Name:match("^[#%s]+$") then
			trackNames[asset] = info.Name
			if currentTrack == key and currentAsset==asset then
				SoundService:SetAttribute("BossSoundtrackName", info.Name)
			end
		end
	end)
end
local function setTrack(key)
	local asset=trackAsset(key)
 if currentTrack==key and currentAsset==asset then return end
	if currentTrack then
		trackPositions[currentAsset] = music.TimePosition
	end
	music:Stop()
	currentTrack = key
 currentAsset=asset
	trackSetAt = os.clock()
	if key and asset then
		music.SoundId = asset
		music.Looped = key ~= "TrueIllusion" and key ~= "SonicBlaster"
		music.PlaybackSpeed = 1
		music.TimePosition = key == "SonicBlaster" and math.max(0, workspace:GetServerTimeNow() - (sonicStartedAt or workspace:GetServerTimeNow()))
			or key == "TrueIllusion" and math.max(0, workspace:GetServerTimeNow() - (illusionStartedAt or workspace:GetServerTimeNow())) or (trackPositions[asset] or 0)
		music:Play()
	end
	publishTrack(key)
end
publishTrack(nil)
local function stopDialogueVoice()
 dialogueVoiceEnds = 0
 dialogueVoiceOwner, dialogueVoiceToken = nil, nil
 dialogueVoice:Stop()
 dialogueVoice:SetAttribute("DialogueVoiceActive", false)
end
local function beginDialogueVoice(data)
 stopDialogueVoice()
 if data.IllusionLyrics or type(data.Text) ~= "string" then return end
 local count = 0
 for _ in utf8.graphemes(data.Text) do count += 1 end
 local interval = EncounterConfig.DialogueCharacterInterval
 local age = math.max(0, workspace:GetServerTimeNow() - (data.StartedAt or workspace:GetServerTimeNow()))
 if data.LyricSoundtrack then
  interval = math.min(interval, math.max(0.001, (data.Duration or 4) * 0.8 / math.max(1, count)))
 end
 local duration = count * interval - age
 if duration <= 0 then return end
 dialogueVoiceEnds = os.clock() + duration
 dialogueVoiceOwner = data.Owner
 dialogueVoiceToken = data.Token
 dialogueVoiceReplayAt = os.clock() + Config.DialogueVoiceReplayInterval
 dialogueVoice.TimePosition = 0
 dialogueVoice:SetAttribute("DialogueVoiceActive", true)
 dialogueVoice:SetAttribute("DialogueVoiceStarts", (dialogueVoice:GetAttribute("DialogueVoiceStarts") or 0) + 1)
 dialogueVoice:Play()
end
local function updateDialogueVoice(now)
 if dialogueVoiceEnds == 0 then return end
 if now >= dialogueVoiceEnds or dialogueVoiceOwner and (not dialogueVoiceOwner.Parent
  or dialogueVoiceOwner:GetAttribute("EncounterEnded")
  or dialogueVoiceToken and (dialogueVoiceOwner:GetAttribute("TrueIllusionToken") ~= dialogueVoiceToken
   or not dialogueVoiceOwner:GetAttribute("TrueIllusionActive"))) then
  stopDialogueVoice()
 elseif now >= dialogueVoiceReplayAt then
  dialogueVoiceReplayAt = now + Config.DialogueVoiceReplayInterval
  if not dialogueVoice.IsPlaying or dialogueVoice.IsLoaded and dialogueVoice.TimeLength <= 0 then
   dialogueVoice.TimePosition = 0
   dialogueVoice:Play()
   dialogueVoice:SetAttribute("DialogueVoiceRetries", (dialogueVoice:GetAttribute("DialogueVoiceRetries") or 0) + 1)
  end
 end
end
local function dialogueDuration(data)
	local count = 0
	if type(data.Text) == "string" then
		for _ in utf8.graphemes(data.Text) do
			count += 1
		end
	end
	return math.clamp(math.max(data.Duration or 4, count * EncounterConfig.DialogueCharacterInterval + 0.8), 0.1, 30)
end
table.insert(
	connections,
	remote.OnClientEvent:Connect(function(kind, data)
		if kind == "CombatAudio" then
			play(data)
		elseif kind == "CombatAudioPreload" then
			local definition = Config.Cues[data.Cue]
			if definition then
				local assets = {}
				for _, layer in ipairs(definition.Layers) do
					table.insert(assets, layer.Asset)
				end
				preloadAssets(assets)
			end
		elseif kind == "CombatAudioStop" then
			stopToken(data.Token)
		elseif kind == "BossDialogue" then
			beginDialogueVoice(data)
			if not data.LyricSoundtrack then duck(dialogueDuration(data), Config.DialogueMusicScale) end
		elseif kind == "BossMusicStop" then
			local boss = workspace:FindFirstChild("alterGolden, the Nothing")
			if not data.Owner or data.Owner == boss then
				musicBlockedOwner = boss
				musicBlockedPhase = data.Phase or boss and boss:GetAttribute("Phase") or 0
				musicBlockedGeneration = boss and boss:GetAttribute("PhaseGeneration")
				setTrack(nil)
			end
		elseif kind == "CombatAudioDuck" and data.Reason == "Dialogue" and currentTrack ~= "TrueIllusion" then
			duck(math.clamp(data.Duration or 4, 0.1, 30), math.clamp(data.Volume or Config.DialogueMusicScale, 0, 1))
		end
	end)
)
local function reset()
	stopDialogueVoice()
	for _, voice in ipairs(voices) do
		release(voice)
	end
	setTrack(nil)
	table.clear(trackPositions)
	duckUntil = 0
	duckVolume = 1
	musicGroup.Volume = musicMuted and 0 or 1
	musicBlockedOwner = nil
	musicBlockedPhase = nil
	musicBlockedGeneration = nil
	illusionToken = nil
	illusionStartedAt = nil
	illusionEnded = false
end
local function updateTrack()
 if musicBlockedOwner and (not musicBlockedOwner.Parent
  or musicBlockedOwner:GetAttribute("PhaseGeneration") ~= musicBlockedGeneration) then
  musicBlockedOwner, musicBlockedPhase, musicBlockedGeneration = nil, nil, nil
 end
	local boss = workspace:FindFirstChild("alterGolden, the Nothing")
	local active = boss
		and boss.Parent
		and not boss:GetAttribute("EncounterEnded")
		and workspace:GetAttribute("EncounterStarted") == true
		and not workspace:GetAttribute("BossEncounterWon")
	local phase = active and (boss:GetAttribute("Phase") or 1) or 0
	if active and phase == 3.5 and illusionStartedAt and not boss:GetAttribute("TrueIllusionActive")
		and not boss:GetAttribute("TrueIllusionCompleted") and not boss:GetAttribute("Phase4TransitionInProgress")
		and workspace:GetServerTimeNow() < illusionStartedAt + 138 then
		illusionStartedAt, illusionToken = nil, nil
		illusionEnded = false
	end
	if active and phase == 3.5 and illusionStartedAt
		and workspace:GetServerTimeNow() >= illusionStartedAt + 138 then illusionEnded = true end
	local key = active
			and workspace:GetAttribute("BossEncounterReady")
			and (phase>=5 and "Phase5" or phase>=4 and "Phase4" or phase>=3 and "Phase3" or phase>=2 and "Phase2" or "Hero")
		or nil
	 
	if key == "Hero" and (boss:GetAttribute("ShieldBreakInProgress") or boss:GetAttribute("ShieldCloneGateActive") or boss:GetAttribute("ShieldBroken")) then
		key = "ShieldBreak"
	end
	 
	 
	if
		key == "Phase2"
		and (
			boss:GetAttribute("Phase3IntroActive")
			or boss:GetAttribute("Phase2ShieldBreakSequenceActive")
			or musicBlockedOwner == boss and (musicBlockedPhase or 0) >= 2
		)
	then
		key = nil
	end
	if
		key == "Phase3"
		and (
			boss:GetAttribute("Phase3IntroActive")
			or boss:GetAttribute("Phase4TransitionInProgress")
			or phase == 3.5 and (illusionEnded or boss:GetAttribute("TrueIllusionCompleted"))
			or boss:GetAttribute("PhaseTransitionInProgress") and phase ~= 3.5
			or currentTrack ~= "Phase3" and os.clock() < duckUntil
		)
	then
		key = nil
	end
	 
	 
	if active and boss:GetAttribute("PickThePupilsActive") then
		if currentTrack ~= "PickThePupils" then trackPositions[trackAsset("PickThePupils")] = nil end
		key = "PickThePupils"
	end
	if active and phase == 3.5 and boss:GetAttribute("TrueIllusionActive") then
		local started = boss:GetAttribute("TrueIllusionMusicStartedAt")
		local token = boss:GetAttribute("TrueIllusionToken")
		if type(started) == "number" and token
			and workspace:GetServerTimeNow() < (boss:GetAttribute("TrueIllusionMusicEndsAt") or started + 138) then
			if illusionToken ~= token then
				illusionToken = token
				illusionEnded = false
				illusionStartedAt = started
				if currentTrack == "TrueIllusion" then setTrack(nil) end
			end
			illusionStartedAt = started
			key = "TrueIllusion"
			duckUntil, duckVolume = 0, 1
		else
			key = nil
		end
	end
	if active and (boss:GetAttribute("MainPhaseIntroActive")
  or boss:GetAttribute("Phase3IntroActive") or boss:GetAttribute("Phase4TransitionInProgress")) then
  key = nil
 end
	 -- Phase 5's final attack: silence for his last words, then its own song from the top, once, in sync with the server
	if boss and boss.Parent and boss:GetAttribute("SonicBlasterActive") then  -- (it plays on to its end after the win)
		local started = boss:GetAttribute("SonicBlasterMusicStartedAt")
		local length = boss:GetAttribute("SonicBlasterLength") or 175.5
		local position = type(started) == "number" and workspace:GetServerTimeNow() - started
		if position and position >= 0 and position < length then
			if sonicStartedAt ~= started then
				sonicStartedAt = started
				if currentTrack == "SonicBlaster" then setTrack(nil) end
			end
			key = "SonicBlaster"
			duckUntil, duckVolume = 0, 1
		else
			key = nil
		end
	end
	setTrack(key)
	if currentTrack and currentAsset and not music.IsLoaded and os.clock() - trackSetAt > 6 and not failedAssets[currentAsset] then
		failedAssets[currentAsset] = true
		warn("[BossAudio] soundtrack " .. currentAsset .. " did not load; using the normal-mode track for " .. currentTrack)
		local k = currentTrack
		currentTrack = nil
		setTrack(k)
	end
	if key == "SonicBlaster" and music.IsLoaded then
		local position = math.max(0, workspace:GetServerTimeNow() - sonicStartedAt)
		if math.abs(music.TimePosition - position) > 0.3 then music.TimePosition = position end
		if not music.IsPlaying then music:Play() end
	end
	if key == "TrueIllusion" and music.IsLoaded then
		local position = math.max(0, workspace:GetServerTimeNow() - illusionStartedAt)
		if math.abs(music.TimePosition - position) > 0.35 then music.TimePosition = position end
		if not music.IsPlaying and position < 138 then music:Play() end
	end
end
table.insert(
	connections,
	workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
		if workspace:GetAttribute("EncounterStarted") ~= true then
			reset()
		else
			updateTrack()
		end
	end)
)
table.insert(connections, workspace:GetAttributeChangedSignal("BossEncounterWon"):Connect(updateTrack))
table.insert(
	connections,
	Run.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.05 then
			return
		end
		local step = elapsed
		elapsed = 0
		local now = os.clock()
		updateTrack()
		updateDialogueVoice(now)
		local target = musicMuted and 0 or (now < duckUntil and duckVolume or 1)
		musicGroup.Volume += (target - musicGroup.Volume) * (1 - math.exp(-step * 5))
		 
		for _, voice in ipairs(voices) do
			if voice.Busy then
				if
					now >= voice.Expires
					or voice.Token and voice.Emitter and not voice.Emitter.Parent
					or voice.Owner and (not voice.Owner.Parent or voice.Owner:GetAttribute("EncounterEnded"))
				then
					if voice.Waiting then
						voice.Sound:SetAttribute("CombatLoadFailed", true)
					end
					release(voice)
				else
					if voice.Waiting then
						startVoice(voice)
					end
					if voice.Busy and voice.Emitter and voice.Emitter.Parent then
						voice.Part.CFrame = CFrame.new(voice.Emitter.Position)
					end
				end
			end
		end
	end)
)
script.Destroying:Connect(function()
	destroyed = true
	reset()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	for _, voice in ipairs(voices) do
		voice.Ended:Disconnect()
		voice.Loaded:Disconnect()
	end
	folder:Destroy()
	combat:Destroy()
	priorityGroup:Destroy()
	musicGroup:Destroy()
	music:Destroy()
	dialogueVoice:Destroy()
end)
