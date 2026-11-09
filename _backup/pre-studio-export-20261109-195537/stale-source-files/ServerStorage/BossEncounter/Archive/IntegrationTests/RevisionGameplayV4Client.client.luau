local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
print("REVISION_V6_CLIENT_DRIVER_BOOT")
-- Temporary integration client; removed from the edit place after testing.
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local remote = Replicated:WaitForChild("RevisionGameplayV4Test")
local resultGUI = Instance.new("ScreenGui")
resultGUI.Name = "RevisionTemporaryTestUI"
resultGUI.ResetOnSpawn = false
resultGUI.DisplayOrder = 500
resultGUI.Parent = player:WaitForChild("PlayerGui")
local resultText = Instance.new("TextLabel")
resultText.Name = "Progress"
resultText.Position = UDim2.new(0.52, 0, 0.37, 0)
resultText.Size = UDim2.new(0.47, 0, 0.43, 0)
resultText.BackgroundColor3 = Color3.fromRGB(9, 16, 24)
resultText.BackgroundTransparency = 0.1
resultText.TextColor3 = Color3.new(1, 1, 1)
resultText.TextSize = 14
resultText.Font = Enum.Font.Code
resultText.TextXAlignment = Enum.TextXAlignment.Left
resultText.TextYAlignment = Enum.TextYAlignment.Top
resultText.TextWrapped = true
resultText.Parent = resultGUI
local progress = {}
local function waitFor(fn, seconds, message)
	local ends = os.clock() + seconds
	repeat
		local result = fn()
		if result then
			return result
		end
		assert(os.clock() < ends, message or "Client test state timed out")
		Run.Heartbeat:Wait()
	until false
end
remote.OnClientEvent:Connect(function(kind, data)
	if kind == "TestMarker" then
		table.insert(progress, data.Name)
		local maximum = data.Name == "FAIL" and 3 or 12
		while #progress > maximum do
			table.remove(progress, 1)
		end
		resultText.Text = "TEMPORARY GAMEPLAY CHECK\n"
			.. table.concat(progress, "\n")
			.. (data.Name == "FAIL" and "\n" .. tostring(data.Error) or "")
		return
	end
	task.spawn(function()
		local ok, result = xpcall(function()
			if kind == "NativePrompt" then
				local prompt = waitFor(function()
					for _, value in ipairs(workspace:GetDescendants()) do
						if value:IsA("ProximityPrompt") and value.Enabled and value.Parent.Name == "Core" then
							return value
						end
					end
				end, 6, "Actual entry prompt missing")
				waitFor(function()
					local c = player.Character
					local r = c and c:FindFirstChild("HumanoidRootPart")
					return r and (r.Position - prompt.Parent.Position).Magnitude <= prompt.MaxActivationDistance
				end, 3, "Entry placement did not replicate to actual player")
				task.wait(0.6)
				prompt:InputHoldBegin()
				task.wait(data.Duration)
				prompt:InputHoldEnd()
				return { Prompt = prompt.Name, Duration = data.Duration }
			elseif kind == "TimerStarted" then
				local hud = waitFor(function()
					return player.PlayerGui:FindFirstChild("PlayerEncounterHUD")
				end, 5)
				local info = waitFor(function()
					return hud:FindFirstChild("EncounterTimerAndMusic")
				end, 3)
				waitFor(function()
					return info.Visible and info.EncounterTimer.Text:match("^%d%d:%d%d$")
				end, 3, "Timer not visible from encounter beginning")
				return { Timer = info.EncounterTimer.Text, Song = info.SoundtrackName.Text }
			elseif kind == "StolenInput" then
				local input = Replicated:WaitForChild("TemporalInput")
				for sequence = 21, 40 do
					input:FireServer("Input", data.IdValue, sequence, Vector3.new(1, 0, 0))
					task.wait(0.05)
				end
				return true
			elseif kind == "AudioNoAttackDuck" then
				-- Client branch body for kind == "AudioNoAttackDuck".
				-- Schedule real slash/priority audio or attack-effect events from the server
				-- during this sampling window; set RequireCue=true to verify actual delivery.
				local soundService = game:GetService("SoundService")
				local music = waitFor(function()
					return soundService:FindFirstChild("BossPhaseSoundtrack")
				end, 3, "soundtrack missing")
				local musicMix = waitFor(function()
					return soundService:FindFirstChild("BossMusicMix")
				end, 3, "music mix missing")
				local combatMix = waitFor(function()
					return soundService:FindFirstChild("BossCombatMix")
				end, 3, "combat mix missing")
				local priorityMix = waitFor(function()
					return soundService:FindFirstChild("BossPriorityMix")
				end, 3, "priority mix missing")
				waitFor(function()
					return musicMix.Volume >= 0.99
				end, 5, "dialogue music did not recover before attack check")
				local baseline = music.Volume
				local minimum = musicMix.Volume
				local cueCount = 0
				local dialogueCount = 0
				local combatBaseline = combatMix.Volume
				local priorityBaseline = priorityMix.Volume
				assert(
					combatBaseline >= 0.999 and priorityBaseline >= 0.999,
					string.format(
						"SFX groups start below neutral gain: music=%.6f, musicMix=%.6f, combat=%.6f, priority=%.6f",
						baseline,
						minimum,
						combatBaseline,
						priorityBaseline
					)
				)
				local observer = Replicated.BossCombatEffects.OnClientEvent:Connect(function(kind)
					if kind == "CombatAudio" then
						cueCount += 1
					elseif kind == "BossDialogue" then
						dialogueCount += 1
					end
				end)
				local ends = os.clock() + (data.Window or 1.5)
				local failure
				repeat
					task.wait(0.03)
					minimum = math.min(minimum, musicMix.Volume)
					if
						math.abs(music.Volume - baseline) > 0.0001
						or combatMix.Volume < 0.999
						or priorityMix.Volume < 0.999
					then
						failure = string.format(
							"attack mix changed: sound %.6f -> %.6f, musicMix=%.6f, combat %.6f -> %.6f, priority %.6f -> %.6f, cues=%d, dialogues=%d",
							baseline,
							music.Volume,
							musicMix.Volume,
							combatBaseline,
							combatMix.Volume,
							priorityBaseline,
							priorityMix.Volume,
							cueCount,
							dialogueCount
						)
						break
					end
				until os.clock() >= ends
				observer:Disconnect()
				assert(not failure, failure)
				assert(dialogueCount == 0, "dialogue occurred during attack-only test; repeat outside dialogue")
				assert(
					minimum >= 0.99,
					string.format(
						"attack musicMix %.6f below .99; sound=%.6f, combat=%.6f, priority=%.6f, cues=%d",
						minimum,
						music.Volume,
						combatMix.Volume,
						priorityMix.Volume,
						cueCount
					)
				)
				if data.RequireCue then
					assert(cueCount > 0, "no actual combat audio arrived during the test")
				end
				return {
					BaselineSoundVolume = baseline,
					MusicMixMinimum = minimum,
					CombatBaseline = combatBaseline,
					PriorityBaseline = priorityBaseline,
					CombatMix = combatMix.Volume,
					PriorityMix = priorityMix.Volume,
					CombatAudioEvents = cueCount,
					SongId = music.SoundId,
					SongName = soundService:GetAttribute("BossSoundtrackName"),
					Loaded = music.IsLoaded,
					Playing = music.IsPlaying,
					TimePosition = music.TimePosition,
					TimeLength = music.TimeLength,
					Loudness = music.PlaybackLoudness,
				}
			elseif kind == "DialogueMusic" then
				-- Client branch body for kind == "DialogueMusic".
				-- After dispatch, schedule Encounter.Say(ExpectedText,nil,{Duration=1,
				-- ScreenOnly=true}) from the server. This observes the real dialogue event.
				local soundService = game:GetService("SoundService")
				local music = waitFor(function()
					return soundService:FindFirstChild("BossPhaseSoundtrack")
				end, 3, "soundtrack missing")
				local mix = waitFor(function()
					return soundService:FindFirstChild("BossMusicMix")
				end, 3, "music mix missing")
				local combat = waitFor(function()
					return soundService:FindFirstChild("BossCombatMix")
				end, 3, "combat mix missing")
				local priority = waitFor(function()
					return soundService:FindFirstChild("BossPriorityMix")
				end, 3, "priority mix missing")
				local dialogue
				local minimum = 1
				local combatMinimum = 1
				local priorityMinimum = 1
				local alteredSound = false
				local observer = Replicated.BossCombatEffects.OnClientEvent:Connect(function(kind, payload)
					if kind == "BossDialogue" and (not data.ExpectedText or payload.Text == data.ExpectedText) then
						dialogue = {
							Text = payload.Text,
							Duration = payload.Duration or 4,
							EndsAt = os.clock() + (payload.Duration or 4),
						}
					end
				end)
				local ok, result = pcall(function()
					waitFor(function()
						return dialogue
					end, 4, "scheduled actual BossDialogue was not received")
					assert(dialogue.Duration <= 6, "use a short dialogue for the bounded client test")
					local deadline = dialogue.EndsAt + 1.5
					repeat
						task.wait(0.03)
						if os.clock() <= dialogue.EndsAt then
							minimum = math.min(minimum, mix.Volume)
						end
						combatMinimum = math.min(combatMinimum, combat.Volume)
						priorityMinimum = math.min(priorityMinimum, priority.Volume)
						if math.abs(music.Volume - 0.22) > 0.0001 then
							alteredSound = true
						end
					until os.clock() >= deadline
					assert(not alteredSound, "dialogue changed the base soundtrack volume")
					assert(
						minimum <= 0.62 and minimum >= 0.44,
						"actual dialogue did not apply the configured quiet music mix"
					)
					assert(mix.Volume >= 0.99, "music did not recover after the real dialogue")
					assert(combatMinimum >= 0.999 and priorityMinimum >= 0.999, "dialogue lowered attack SFX volume")
					return {
						ActualDialogue = dialogue.Text,
						Duration = dialogue.Duration,
						MusicVolume = music.Volume,
						MinMix = minimum,
						RecoverMix = mix.Volume,
						MinimumEffectiveMusicVolume = music.Volume * minimum,
						CombatMixMinimum = combatMinimum,
						PriorityMixMinimum = priorityMinimum,
						SongId = music.SoundId,
						SongName = soundService:GetAttribute("BossSoundtrackName"),
						Loaded = music.IsLoaded,
						Playing = music.IsPlaying,
						TimePosition = music.TimePosition,
					}
				end)
				observer:Disconnect()
				assert(ok, tostring(result))
				return result
			elseif kind == "UIV2" then
				-- Client branch body for kind == "UIV2"; run in desktop and narrow viewport.
				local hud = waitFor(function()
					return player.PlayerGui:FindFirstChild("AlterGoldenBossHUD")
				end, 4, "boss HUD missing")
				local p = waitFor(function()
					return hud:FindFirstChild("BossPanel", true)
				end, 4, "boss panel missing")
				waitFor(function()
					return p.Parent == hud and p.AbsoluteSize.X > 0
				end, 3, "direct safe-area HUD layout not ready")
				local center = p.AbsolutePosition.X + p.AbsoluteSize.X * 0.5
				local expected = hud.AbsoluteSize.X * 0.5
				assert(
					math.abs(center - expected) <= 2,
					string.format(
						"boss HUD off-center %.2f vs %.2f; viewport=%.2f width=%.2f",
						center,
						expected,
						hud.AbsoluteSize.X,
						p.AbsoluteSize.X
					)
				)
				assert(
					p.AbsoluteSize.X <= hud.AbsoluteSize.X * 0.92 + 2 and p.AbsoluteSize.X <= 852,
					"boss panel overflows viewport"
				)
				assert(p.AbsoluteSize.X >= math.min(160, hud.AbsoluteSize.X * 0.9), "boss panel too narrow")
				assert(not hud.IgnoreGuiInset, "boss HUD ignores Roblox safe inset")
				local boss = workspace:FindFirstChild("alterGolden, the Nothing")
				assert(boss, "boss missing")
				if (boss:GetAttribute("Shield") or 0) <= 0 or (boss:GetAttribute("MaxShield") or 0) <= 0 then
					waitFor(function()
						return not p.ShieldBar.Visible and not p.ShieldValue.Visible
					end, 2, "empty boss shield remains drawn")
				end
				local clone = p:FindFirstChild("TrueCloneHealth")
				assert(clone, "Puppeteer panel missing")
				if data.RequireClone then
					waitFor(function()
						return clone.Visible and clone.Title.Text == "alterGolden's Puppeteer"
					end, 3, "Puppeteer title/HP not visible")
					assert(clone.Value.Text:find("/"), "Puppeteer HP value missing")
				end
				if
					(boss:GetAttribute("LinkedCloneShield") or 0) <= 0
					or (boss:GetAttribute("LinkedCloneMaxShield") or 0) <= 0
				then
					assert(not clone.Track.ShieldBar.Visible, "empty Puppeteer shield remains drawn")
				end
				local audio = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
				local count = 0
				for _, name in ipairs(data.AbilityNames or {}) do
					local entry = audio.Attacks[name]
					assert(entry, "ability missing from soundboard: " .. name)
					assert(
						audio.Cues[entry.Cast] and audio.Cues[entry.Impact],
						"ability cast/impact sound missing: " .. name
					)
					count += 1
				end
				assert(count > 0, "pass Metadata.ActiveNames + Metadata.TimeStopNames for soundboard coverage")
				return {
					Center = center,
					ExpectedCenter = expected,
					CenterError = math.abs(center - expected),
					Width = p.AbsoluteSize.X,
					ViewportWidth = hud.AbsoluteSize.X,
					ShieldVisible = p.ShieldBar.Visible,
					PuppeteerTitle = clone.Title.Text,
					PuppeteerShieldVisible = clone.Track.ShieldBar.Visible,
					SoundboardAbilities = count,
				}
			elseif kind == "MusicGateV2" then
				-- Client branch body for kind == "MusicGateV2".
				-- data.Stage: Stop or Intro or Complete; root dispatches real StopMusic/intro.
				local ss = game:GetService("SoundService")
				local sound = waitFor(function()
					return ss:FindFirstChild("BossPhaseSoundtrack")
				end, 3, "phase soundtrack missing")
				local boss = workspace:FindFirstChild("alterGolden, the Nothing")
				assert(boss, "boss missing")
				if data.Stage == "Stop" or data.Stage == "Intro" then
					waitFor(function()
						return not sound.IsPlaying and ss:GetAttribute("BossSoundtrackPlaying") == false
					end, 3, "phase2 song continues during shield-break/intro")
					local endAt = os.clock() + (data.Window or 0.8)
					repeat
						task.wait(0.03)
						assert(not sound.IsPlaying, "soundtrack restarted before intro/dialogue completed")
					until os.clock() >= endAt
				else
					waitFor(function()
						return sound.SoundId == "rbxassetid://132058286351091"
							and ss:GetAttribute("BossSoundtrackPlaying") == true
					end, 5, "phase3 song did not start after final dialogue")
					assert(
						not boss:GetAttribute("Phase3IntroActive")
							and not boss:GetAttribute("PhaseTransitionInProgress"),
						"phase3 song started while intro still owns combat"
					)
				end
				return {
					Stage = data.Stage,
					Playing = sound.IsPlaying,
					LogicalPlaying = ss:GetAttribute("BossSoundtrackPlaying"),
					SongId = sound.SoundId,
					SongName = ss:GetAttribute("BossSoundtrackName"),
					IntroActive = boss:GetAttribute("Phase3IntroActive"),
					Loaded = sound.IsLoaded,
					TimePosition = sound.TimePosition,
				}
			elseif kind == "Camera" then
				local camera = workspace.CurrentCamera
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = data.Frame
				return true
			elseif kind == "ControlDistortionInput" then
				-- Inject as the body of elseif kind=="ControlDistortionInput" then.
				-- Every render binding and event listener here belongs to this temporary test.
				local c = assert(player.Character)
				local h = assert(c:FindFirstChildOfClass("Humanoid"))
				if data.Arm then
					script:SetAttribute("RevisionDistortionEventSeen", false)
					local event = Replicated:WaitForChild("BossCombatEffects")
					local listener
					listener = event.OnClientEvent:Connect(function(eventKind, payload)
						if eventKind ~= "P3ControlDistortion" then
							return
						end
						script:SetAttribute("RevisionDistortionEventUntil", payload.EndsAt)
						script:SetAttribute("RevisionDistortionEventRotation", payload.MaxRotation)
						script:SetAttribute("RevisionDistortionEventSeen", true)
						listener:Disconnect()
					end)
					task.delay(8, function()
						if listener.Connected then
							listener:Disconnect()
						end
					end)
					return { Armed = true }
				end
				if data.Cleanup then
					waitFor(function()
						return not c:GetAttribute("ControlDistortionRuntimeActive")
							and (c:GetAttribute("ControlDistortionUntil") or 0) <= workspace:GetServerTimeNow()
					end, 2, "Control Distortion client runtime remained after server cleanup")
					return { RuntimeActive = c:GetAttribute("ControlDistortionRuntimeActive") == true }
				end
				waitFor(function()
					return script:GetAttribute("RevisionDistortionEventSeen")
				end, 2, "Control Distortion player event missing")
				waitFor(function()
					return c:GetAttribute("ControlDistortionRuntimeActive")
				end, 2, "Control Distortion native input interceptor not active")
				assert(
					(script:GetAttribute("RevisionDistortionEventUntil") or 0) > workspace:GetServerTimeNow(),
					"Control Distortion event deadline invalid"
				)
				assert(
					(script:GetAttribute("RevisionDistortionEventRotation") or 100) <= 55,
					"Control Distortion event exceeded input rotation bound"
				)
				local inject = "RevisionDistortionRequestedInput"
				local sample = "RevisionDistortionObservedInput"
				local intended = Vector3.new(0, 0, -1)
				local maxRotation, maxIdle, samples = 0, 0, 0
				local samplingMovement = true
				local passed, failure = xpcall(function()
					Run:BindToRenderStep(inject, Enum.RenderPriority.Input.Value + 1, function()
						h:Move(intended, false)
					end)
					Run:BindToRenderStep(sample, Enum.RenderPriority.Input.Value + 3, function()
						local observed = h.MoveDirection
						if samplingMovement and observed.Magnitude > 0.01 then
							maxRotation = math.max(
								maxRotation,
								math.deg(math.acos(math.clamp(intended:Dot(observed.Unit), -1, 1)))
							)
							samples += 1
						elseif not samplingMovement then
							maxIdle = math.max(maxIdle, observed.Magnitude)
						end
					end)
					task.wait(1.2)
					Run:UnbindFromRenderStep(inject)
					h:Move(Vector3.zero, false)
					samplingMovement = false
					task.wait(0.2)
					assert(samples > 3 and maxRotation > 3, "Control Distortion did not change requested movement")
					assert(
						maxRotation <= (c:GetAttribute("ControlDistortionMaxRotation") or 55) + 1,
						"Control Distortion rotated beyond its configured bound"
					)
					assert(maxIdle < 0.01, "Control Distortion supplied movement without player input")
				end, debug.traceback)
				Run:UnbindFromRenderStep(inject)
				Run:UnbindFromRenderStep(sample)
				h:Move(Vector3.zero, false)
				assert(passed, failure)
				return { MaxRotation = maxRotation, MaxIdle = maxIdle, Samples = samples, Event = true }
			elseif kind == "CinematicLockV3" then
				-- Optional client branch body: elseif kind=="CinematicLockV3" then.
				local c = assert(player.Character)
				local h = assert(c:FindFirstChildOfClass("Humanoid"))
				if data.Stage == "Cleanup" then
					waitFor(function()
						return not c:GetAttribute("ShieldBreakCinematicLocked")
							and not player:GetAttribute("ShieldBreakCinematicLocked")
							and not player:GetAttribute("MovementLocked")
					end, 3, "Network cinematic control remained after cleanup")
					return { Stage = "Cleanup", Locked = false }
				end
				waitFor(function()
					return c:GetAttribute("ShieldBreakCinematicLocked")
						and player:GetAttribute("ShieldBreakCinematicLocked")
						and player:GetAttribute("MovementLocked")
						and h.WalkSpeed == 0
				end, 2, "Cinematic movement control did not replicate")
				local hud = waitFor(function()
					return player.PlayerGui:FindFirstChild("PlayerEncounterHUD")
				end, 2, "Player HUD missing")
				local chains = waitFor(function()
					return hud:FindFirstChild("ChainDebuff", true)
				end, 2, "Chain status row missing")
				waitFor(function()
					return not chains.Visible
				end, 1, "Cinematic is incorrectly displayed as a chained debuff")
				assert(
					not c:GetAttribute("Chained") and not c.HumanoidRootPart.Anchored,
					"Cinematic shows a restraint or prevents physical knockback"
				)
				assert(h.JumpPower == 0 and h.JumpHeight == 0, "Network player can still jump during the scream")
				local SoundService = game:GetService("SoundService")
				local voice = waitFor(function()
					local folder = workspace:FindFirstChild("BossAudioEmitters")
					if folder then
						for _, item in ipairs(folder:GetDescendants()) do
							if
								item:IsA("Sound")
								and item:GetAttribute("CombatCue") == "P1ShieldBreakScream"
								and item:GetAttribute("CombatFiniteToken")
								and item.IsLoaded
							then
								return item
							end
						end
					end
				end, 3, "Authoritative scream did not load in the client pool")
				assert(
					voice.SoundId == "rbxassetid://111870313797501"
						and voice.PlaybackSpeed == 1
						and not voice.Looped
						and voice.Volume <= 0.22,
					"Finite scream asset/gain/pitch differs on client"
				)
				assert(
					math.abs(voice.TimeLength - data.Duration) < 0.05
						and math.abs(voice:GetAttribute("CombatExpectedDuration") - data.Duration) < 0.001,
					"Server scream duration differs from real client clip"
				)
				return {
					Duration = voice.TimeLength,
					Volume = voice.Volume,
					Stage = "Active",
					WalkSpeed = h.WalkSpeed,
					Locked = player:GetAttribute("MovementLocked"),
					ChainDebuffVisible = chains.Visible,
				}
			elseif kind == "UploadedAudioV3" then
				-- Client branch body: kind == "UploadedAudioV3". Run outside dialogue.
				-- Server may emit requested cues during Window; set RequireCues to expected names.
				local SoundService = game:GetService("SoundService")
				local Content = game:GetService("ContentProvider")
				local Run = game:GetService("RunService")
				local Config = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
				waitFor(function()
					local mix = SoundService:FindFirstChild("BossMusicMix")
					return mix and mix.Volume >= 0.99
				end, 6, "prior dialogue did not recover before uploaded audio audit")
				local expected = {
					SplitActivate = "138687206526097",
					RangedLaunch = "130036764141803",
					CrescentRelease = "138556725992332",
					TornadoBuild = "139345755518677",
					CataclysmChainSuccess = "124444290902740",
					CataclysmChainFailure = "86561148418857",
					CataclysmRockThrow = "120212342534790",
					ChainSummon = "94262331099819",
					ChainSpin = "94262331099819",
					ChainDrag = "94262331099819",
					HandSummon = "137231920197356",
					LanceSummon = "106040916467911",
					GroundWarning = "72443891537288",
					RainFall = "106836237516030",
					TeleportOut = "120804026547578",
					AccelerationCast = "83613815751583",
					DecelerationCast = "9120061271",
					GoldenBulletWave = "123444285617739",
					TimeBulletShot = "126809328894734",
					TimeConstructCast = "139571940014575",
					MissingFrameCast = "125628438711815",
					P3Snap = "131727399246401",
					SplittingSlashRelease = "117016486915242",
					P1ShieldBreakScream = "111870313797501",
				}
				-- The retired ability's old cast cue also retains the exact construct clip;
				-- current Save/Load use that same clip through their own canonical cue names.
				expected.TimeSave = "139571940014575"
				expected.TimeLoad = "139571940014575"
				local folder = Instance.new("Folder")
				folder.Name = "RevisionUploadedAudioProbes"
				folder.Parent = SoundService
				local probes, seenAssets = {}, {}
				local events, started = {}, {}
				local peakVoices, peakLoops, peakVolume, dialogues = 0, 0, 0, 0
				local failure
				local preloadDone = false
				local minimumMusicMix = 1
				local observer = Replicated.BossCombatEffects.OnClientEvent:Connect(function(kind, payload)
					if kind == "CombatAudio" and Config.UploadedCues[payload.Cue] then
						events[payload.Cue] = (events[payload.Cue] or 0) + 1
					elseif kind == "BossDialogue" then
						dialogues += 1
					end
				end)
				local sampler = Run.Heartbeat:Connect(function()
					local emitters = workspace:FindFirstChild("BossAudioEmitters")
					local voices, loops = 0, 0
					if emitters then
						for _, item in ipairs(emitters:GetDescendants()) do
							if item:IsA("Sound") then
								voices += 1
								if item:GetAttribute("CombatVoiceBusy") and item.Looped then
									loops += 1
								end
								local cue = item:GetAttribute("CombatCue")
								if item:GetAttribute("CombatVoiceBusy") and Config.UploadedCues[cue] then
									peakVolume = math.max(peakVolume, item.Volume)
									if
										item.Volume > Config.UploadedVolumeCap + 0.00001
										or math.abs(item.PlaybackSpeed - 1) > 0.00001
									then
										failure = string.format(
											"uploaded clip gain/pitch: %s volume %.5f speed %.5f",
											cue,
											item.Volume,
											item.PlaybackSpeed
										)
									end
									if item.SoundId ~= Config.UploadedCues[cue] then
										failure = "wrong loaded voice asset: " .. tostring(cue)
									end
									if item.IsLoaded and item.IsPlaying then
										started[cue] = true
									end
									if item:GetAttribute("CombatLoadFailed") then
										failure = "pooled clip failed loading: " .. tostring(cue)
									end
								end
							end
						end
					end
					peakVoices = math.max(peakVoices, voices)
					peakLoops = math.max(peakLoops, loops)
					local group = SoundService:FindFirstChild("BossMusicMix")
					if group then
						minimumMusicMix = math.min(minimumMusicMix, group.Volume)
					end
				end)
				local result
				local ok, reason = xpcall(function()
					for cue, id in pairs(expected) do
						local definition = assert(Config.Cues[cue], "missing exact cue " .. cue)
						assert(
							#definition.Layers == 1 and definition.Layers[1].Asset == "rbxassetid://" .. id,
							"wrong exact clip " .. cue
						)
						assert(
							definition.FixedPitch and definition.FullLength and definition.VolumeCap <= 0.22,
							"clip timing/gain policy missing " .. cue
						)
					end
					assert(
						Config.Cues.TimeBulletShot.Interval <= 0.01,
						"time bullet audio throttle misses staggered shots"
					)
					for _, name in ipairs({
						"P3Illusion",
						"P3TargetedKnife",
						"P3Thief",
						"P3ControlDistortion",
						"P4TargetingKnives",
					}) do
						assert(Config.Attacks[name].Cast == "P3Snap", name .. " missing snap")
					end
					for cue, asset in pairs(Config.UploadedCues) do
						if not seenAssets[asset] then
							seenAssets[asset] = true
							local probe = Instance.new("Sound")
							probe.Name = cue
							probe.Volume = 0
							probe.SoundId = asset
							probe.Parent = folder
							table.insert(probes, probe)
						end
					end
					task.spawn(function()
						pcall(Content.PreloadAsync, Content, probes)
						preloadDone = true
					end)
					local ends = os.clock() + (data.Window or 10)
					repeat
						task.wait(0.03)
					until os.clock() >= ends or failure
					assert(not failure, failure)
					local loaded, lengths, unavailable = 0, {}, {}
					for _, probe in ipairs(probes) do
						if probe.IsLoaded and probe.TimeLength > 0 then
							loaded += 1
							lengths[probe.SoundId] = probe.TimeLength
						else
							table.insert(unavailable, probe.SoundId)
						end
					end
					table.sort(unavailable)
					assert(
						data.RequireLoaded == false or #unavailable == 0,
						"uploaded audio unavailable in this experience: " .. table.concat(unavailable, ", ")
					)
					for _, cue in ipairs(data.RequireCues or {}) do
						assert((events[cue] or 0) > 0, "server event not delivered: " .. cue)
						assert(started[cue], "clip never played from actual pool: " .. cue)
					end
					if data.RequirePlayback ~= false then
						assert(next(started), "no actual uploaded clip playback observed")
					end
					assert(
						peakVoices <= Config.MaxVoices and peakLoops <= Config.MaxLoopVoices,
						"audio pool exceeded bounds"
					)
					assert(
						SoundService.BossCombatMix.Volume == 1 and SoundService.BossPriorityMix.Volume == 1,
						"SFX group gain changed"
					)
					assert(
						math.abs(SoundService.BossPhaseSoundtrack.Volume - 0.22) < 0.00001,
						"soundtrack base gain changed"
					)
					if not data.AllowDialogue then
						assert(
							dialogues == 0 and minimumMusicMix >= 0.99,
							"audio audit included dialogue/ducking; repeat outside dialogue"
						)
					end
					result = {
						UniqueAssets = #probes,
						Loaded = loaded,
						Unavailable = unavailable,
						Lengths = lengths,
						Events = events,
						Played = started,
						PeakVoices = peakVoices,
						PeakLoops = peakLoops,
						PeakVolume = peakVolume,
						MusicMixMinimum = minimumMusicMix,
						PreloadDone = preloadDone,
					}
				end, debug.traceback)
				observer:Disconnect()
				sampler:Disconnect()
				folder:Destroy()
				if not ok then
					error(reason, 0)
				end
				return result
			elseif kind == "FiniteAudioV3" then
				-- Client branch body: kind == "FiniteAudioV3". Schedule StartFinite after .4s.
				local SoundService = game:GetService("SoundService")
				local payload
				local observer = Replicated.BossCombatEffects.OnClientEvent:Connect(function(kind, record)
					if kind == "CombatAudio" and record.Cue == "P1ShieldBreakScream" then
						payload = record
					end
				end)
				local result
				local ok, reason = xpcall(function()
					local event = waitFor(function()
						return payload
					end, 10, "actual finite scream event missing")
					assert(
						type(event.Duration) == "number" and event.Duration > 0 and type(event.StartedAt) == "number",
						"scream missing server duration/start"
					)
					local voice = waitFor(function()
						local folder = workspace:FindFirstChild("BossAudioEmitters")
						if folder then
							for _, item in ipairs(folder:GetDescendants()) do
								if
									item:IsA("Sound")
									and item:GetAttribute("CombatFiniteToken") == event.Token
									and item.IsLoaded
									and item:GetAttribute("CombatExpectedDuration")
								then
									return item
								end
							end
						end
					end, 8, "finite scream never became a loaded pooled voice")
					assert(
						voice.SoundId == "rbxassetid://111870313797501"
							and voice.PlaybackSpeed == 1
							and not voice.Looped,
						"scream ID/pitch/loop mismatch"
					)
					assert(
						voice.Volume <= 0.22 and math.abs(voice.TimeLength - event.Duration) < 0.05,
						"server finite duration differs from loaded clip"
					)
					assert(
						math.abs(voice:GetAttribute("CombatExpectedDuration") - event.Duration) < 0.001,
						"finite voice has default shortened lifetime"
					)
					local clientLength = voice.TimeLength
					local volume = voice.Volume
					local pitch = voice.PlaybackSpeed
					local expectedEnd = event.StartedAt + event.Duration
					local function playing()
						return voice:GetAttribute("CombatFiniteToken") == event.Token and voice.IsPlaying
					end
					local played = playing()
					local endedAt
					if data.RequireComplete then
						while workspace:GetServerTimeNow() < expectedEnd + 0.5 do
							if playing() then
								played = true
							elseif played and not endedAt then
								endedAt = workspace:GetServerTimeNow()
							end
							task.wait(0.02)
						end
						assert(played, "finite scream never played")
						assert(
							not endedAt or endedAt >= expectedEnd - 0.15,
							"scream ended before authoritative clip duration"
						)
						assert(not playing(), "finite scream remained playing after its clip duration")
					end
					result = {
						Duration = event.Duration,
						ClientLength = clientLength,
						Volume = volume,
						Pitch = pitch,
						ServerStartedAt = event.StartedAt,
						ExpectedEnd = expectedEnd,
						EndedAt = endedAt,
						Played = played,
					}
				end, debug.traceback)
				observer:Disconnect()
				if not ok then
					error(reason, 0)
				end
				return result
			elseif kind == "EtherealDim" then
				-- Inject as elseif kind=="EtherealDim" then.
				local lighting = game:GetService("Lighting")
				local effect = waitFor(function()
					return lighting:FindFirstChild("EtherealAcumenDarkness")
				end, 3, "Owned Ethereal darkness effect missing")
				waitFor(function()
					return effect.Enabled == data.Active
				end, 3, "Ethereal darkness activation/cleanup did not reach the real client")
				if data.Active then
					assert(
						effect.Brightness >= -0.151 and effect.Brightness < 0,
						"Ethereal darkness exceeds the dim brightness bound"
					)
				end
				return { Enabled = effect.Enabled, Brightness = effect.Brightness }
			elseif kind == "UIV4" then
				-- Client branch body for kind == "UIV2"; run in desktop and narrow viewport.
				local hud = waitFor(function()
					return player.PlayerGui:FindFirstChild("AlterGoldenBossHUD")
				end, 4, "boss HUD missing")
				local p = waitFor(function()
					return hud:FindFirstChild("BossPanel", true)
				end, 4, "boss panel missing")
				waitFor(function()
					return p.Parent == hud and p.AbsoluteSize.X > 0
				end, 3, "direct safe-area HUD layout not ready")
				local center = p.AbsolutePosition.X + p.AbsoluteSize.X * 0.5
				local expected = hud.AbsoluteSize.X * 0.5
				assert(
					math.abs(center - expected) <= 2,
					string.format(
						"boss HUD off-center %.2f vs %.2f; viewport=%.2f width=%.2f",
						center,
						expected,
						hud.AbsoluteSize.X,
						p.AbsoluteSize.X
					)
				)
				assert(
					p.AbsoluteSize.X <= hud.AbsoluteSize.X * 0.92 + 2 and p.AbsoluteSize.X <= 852,
					"boss panel overflows viewport"
				)
				assert(p.AbsoluteSize.X >= math.min(160, hud.AbsoluteSize.X * 0.9), "boss panel too narrow")
				assert(not hud.IgnoreGuiInset, "boss HUD ignores Roblox safe inset")
				local boss = workspace:FindFirstChild("alterGolden, the Nothing")
				assert(boss, "boss missing")
				if (boss:GetAttribute("Shield") or 0) <= 0 or (boss:GetAttribute("MaxShield") or 0) <= 0 then
					waitFor(function()
						return not p.ShieldBar.Visible and not p.ShieldValue.Visible
					end, 2, "empty boss shield remains drawn")
				end
				local clone = p:FindFirstChild("TrueCloneHealth")
				assert(clone, "Puppeteer panel missing")
				if data.RequireClone then
					waitFor(function()
						return clone.Visible and clone.Title.Text == "alterGolden's Puppeteer"
					end, 3, "Puppeteer title/HP not visible")
					assert(clone.Value.Text:find("/"), "Puppeteer HP value missing")
				end
				if
					(boss:GetAttribute("LinkedCloneShield") or 0) <= 0
					or (boss:GetAttribute("LinkedCloneMaxShield") or 0) <= 0
				then
					assert(not clone.Track.ShieldBar.Visible, "empty Puppeteer shield remains drawn")
				end
				local audio = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
				local count = 0
				for _, name in ipairs(data.AbilityNames or {}) do
					local entry = audio.Attacks[name]
					assert(entry, "ability missing from soundboard: " .. name)
					assert(
						audio.Cues[entry.Cast] and audio.Cues[entry.Impact],
						"ability cast/impact sound missing: " .. name
					)
					count += 1
				end
				assert(count > 0, "pass Metadata.ActiveNames + Metadata.TimeStopNames for soundboard coverage")
				waitFor(function()
					return boss:GetAttribute("Phase") == 4 and p.Title.Text == "alterGolden, the Nothing"
				end, 3, "Phase 4 boss title not shown")
				local vitals = waitFor(function()
					return player.PlayerGui:FindFirstChild("PlayerVitalsHUD")
				end, 3, "Player vitals missing")
				local hearts = waitFor(function()
					return vitals:FindFirstChild("LivesHearts", true)
				end, 3, "Lives hearts missing")
				local count = 0
				for _, item in ipairs(hearts:GetChildren()) do
					if item:IsA("TextLabel") and item.Name:find("LifeHeart") then
						count += 1
						assert(item.Text == "♥", "Life glyph is not a heart")
					end
				end
				assert(count == 5, "Expected five life hearts")
				assert(
					hearts.AbsolutePosition.Y + hearts.AbsoluteSize.Y <= hearts.Parent.AbsolutePosition.Y + 1,
					"Hearts are not above the HP bar"
				)
				local encounterHUD = assert(player.PlayerGui:FindFirstChild("PlayerEncounterHUD"))
				assert(not encounterHUD:FindFirstChild("Lives"), "Numeric lives row remains")
				return {
					Hearts = count,
					BossTitle = p.Title.Text,
					Center = center,
					ExpectedCenter = expected,
					CenterError = math.abs(center - expected),
					Width = p.AbsoluteSize.X,
					ViewportWidth = hud.AbsoluteSize.X,
					ShieldVisible = p.ShieldBar.Visible,
					PuppeteerTitle = clone.Title.Text,
					PuppeteerShieldVisible = clone.Track.ShieldBar.Visible,
					SoundboardAbilities = count,
				}
			elseif kind == "UI" then
				-- Client-side UI assertions; insert as the body of kind == "UI".
				local soundService = game:GetService("SoundService")
				local hud = waitFor(function()
					return player.PlayerGui:FindFirstChild("AlterGoldenBossHUD")
				end, 5, "boss HUD missing")
				local panel = waitFor(function()
					return hud:FindFirstChild("BossPanel", true)
				end, 5, "boss panel missing")
				local vitals = waitFor(function()
					return player.PlayerGui:FindFirstChild("PlayerVitalsHUD")
				end, 5, "player vitals missing")
				local playerHUD = waitFor(function()
					return player.PlayerGui:FindFirstChild("PlayerEncounterHUD")
				end, 5, "encounter HUD missing")
				local music = waitFor(function()
					return soundService:FindFirstChild("BossPhaseSoundtrack")
				end, 5, "soundtrack sound missing")
				local phase = data.Phase or 2.5
				local expectedAsset = phase >= 3 and "rbxassetid://132058286351091"
					or phase >= 2 and "rbxassetid://138324961225014"
					or "rbxassetid://96167216374376"
				waitFor(function()
					return hud.Enabled and panel.Title.Text ~= "" and panel.HealthBar.Value.Text:find("/")
				end, 5, "live boss title/HP not visible")
				assert(panel.Size.X.Scale < 0.8 and panel.AnchorPoint.X == 0.5, "boss HUD is not compact/centered")
				waitFor(function()
					return panel.HealthBar.AbsoluteSize.Y > 0 and panel.ShieldBar.AbsoluteSize.Y > 0
				end, 3, "boss bar layout has not resolved")
				assert(
					panel.HealthBar.AbsoluteSize.Y > panel.ShieldBar.AbsoluteSize.Y,
					"shield is not a thin secondary bar"
				)
				assert(panel.ShieldValue.Text ~= "", "shield value missing")
				local passive = waitFor(function()
					return panel:FindFirstChild("BossPassiveDock")
				end, 3, "passive dock missing")
				local buffs = waitFor(function()
					return panel:FindFirstChild("BossBuffDock")
				end, 3, "buff dock missing")
				assert(
					passive.AnchorPoint.X == 1 and passive.AbsolutePosition.Y < panel.HealthBar.AbsolutePosition.Y,
					"passives are not above the HP/right aligned"
				)
				assert(
					buffs.AnchorPoint.X == 1 and buffs.AbsolutePosition.Y > panel.ShieldBar.AbsolutePosition.Y,
					"buffs are not below the shield/right aligned"
				)
				local future = buffs:FindFirstChild("P25FutureSight")
				assert(future and future.Size.X.Offset <= 32, "FutureSight is not a compact icon")
				assert(
					future.Detail.Text == "" and not future.Detail.Visible,
					"FutureSight still exposes a charge counter"
				)
				for _, item in ipairs(future:GetDescendants()) do
					assert(not item.Name:find("PredictionCharge"), "FutureSight charge dots still exist")
				end
				local heartDock = waitFor(function()
					return vitals:FindFirstChild("LivesHearts", true)
				end, 3, "lives hearts missing")
				local heartCount = 0
				for _, item in ipairs(heartDock:GetChildren()) do
					if item:IsA("TextLabel") and item.Name:find("LifeHeart") then
						heartCount += 1
						assert(item.Text == "♥", "life is not a heart")
					end
				end
				assert(heartCount == 5, "expected five lives hearts")
				waitFor(function()
					return heartDock.AbsoluteSize.Y > 0
				end, 3, "heart layout has not resolved")
				assert(
					heartDock.AbsolutePosition.Y + heartDock.AbsoluteSize.Y <= heartDock.Parent.AbsolutePosition.Y + 1,
					"hearts do not sit above HP"
				)
				assert(not playerHUD:FindFirstChild("Lives"), "old numeric lives display remains")
				local info = waitFor(function()
					return playerHUD:FindFirstChild("EncounterTimerAndMusic")
				end, 3, "timer/music panel missing")
				waitFor(function()
					return info.Visible and info.EncounterTimer.Text:match("^%d%d:%d%d$")
				end, 3, "encounter timer is not displayed")
				assert(info.Position.X.Scale < 0.1 and info.AnchorPoint.Y == 1, "timer is not bottom-left")
				assert(
					info.SoundtrackName.Position.Y.Offset < info.EncounterTimer.Position.Y.Offset,
					"soundtrack name is not above timer"
				)
				waitFor(function()
					return music.SoundId == expectedAsset and info.SoundtrackName.Text ~= ""
				end, 5, "phase song or name not updated")
				assert(music.Volume <= 0.25, "boss music is too loud")
				local config = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
				for _, name in ipairs({
					"SwordSlash",
					"NormalSwing",
					"RangedLaunch",
					"TornadoCut",
					"SplitActivate",
					"CrescentRelease",
				}) do
					local cue = config.Cues[name]
					assert(cue, "slash audio cue missing: " .. name)
					local blade = false
					for _, layer in ipairs(cue.Layers) do
						if layer.ToolSound == "Slash" then
							blade = true
						end
					end
					assert(blade, "proper blade layer missing: " .. name)
				end
				local musicMix = waitFor(function()
					return soundService:FindFirstChild("BossMusicMix")
				end, 3, "music mix missing")
				local minMix = musicMix.Volume
				if data.CheckNoAttackDuck then
					waitFor(function()
						return musicMix.Volume >= 0.99
					end, 5, "dialogue music reduction did not recover before attack check")
					minMix = musicMix.Volume
					local untilTime = os.clock() + 1.2
					repeat
						task.wait(0.03)
						minMix = math.min(minMix, musicMix.Volume)
					until os.clock() >= untilTime
					assert(minMix >= 0.99, "an attack reduced music volume")
					assert(
						soundService.BossCombatMix.Volume == 1 and soundService.BossPriorityMix.Volume == 1,
						"an attack reduced SFX mix volume"
					)
				end
				local linked = panel:FindFirstChild("TrueCloneHealth")
				assert(
					linked and linked.Track:FindFirstChild("ShieldBar") and linked:FindFirstChild("BuffDock"),
					"miniboss HP/shield/buff area missing"
				)
				if data.RequireClone then
					waitFor(function()
						return linked.Visible and linked.Value.Text:find("/")
					end, 3, "linked clone HP/title is not visible")
				end
				return {
					BossTitle = panel.Title.Text,
					Health = panel.HealthBar.Value.Text,
					Shield = panel.ShieldValue.Text,
					BossWidth = panel.AbsoluteSize.X,
					ViewportWidth = hud.AbsoluteSize.X,
					Hearts = heartCount,
					Timer = info.EncounterTimer.Text,
					SongName = info.SoundtrackName.Text,
					SongId = music.SoundId,
					SongVolume = music.Volume,
					MusicMixMinimum = minMix,
					AudioLoaded = music.IsLoaded,
					AudioPlaying = music.IsPlaying,
					AudioTimePosition = music.TimePosition,
					AudioTimeLength = music.TimeLength,
					AudioLoudness = music.PlaybackLoudness,
					MusicMixVolume = musicMix.Volume,
					MusicEffectiveVolume = music.Volume * musicMix.Volume,
					CloneVisible = linked.Visible,
				}
			elseif kind == "UIV5" then
				local hud = waitFor(function()
					return player.PlayerGui:FindFirstChild("AlterGoldenBossHUD")
				end, 5, "Boss HUD missing")
				local panel = assert(hud:FindFirstChild("BossPanel", true))
				waitFor(function()
					return panel.AbsoluteSize.X > 0
				end, 3, "Boss HUD layout unresolved")
				local center = panel.AbsolutePosition.X + panel.AbsoluteSize.X * 0.5
				assert(math.abs(center - hud.AbsoluteSize.X * 0.5) < 3, "Boss HUD incorrectly positioned")
				if data.Gate then
					for index = 1, 2 do
						local row = assert(panel:FindFirstChild("ShieldGateClone" .. index), "Clone HP panel missing")
						waitFor(function()
							return row.Visible and row.Value.Text:find("1,000")
						end, 4, "1000HP clone panel failed to replicate")
						assert(not row:FindFirstChild("ShieldBar", true), "Shield-free gate clone drew a shield bar")
					end
				else
					assert(not panel.TrueCloneHealth.Visible, "Retired Puppeteer panel became visible")
					waitFor(function()
						return panel.ShieldBar.Visible and panel.ShieldValue.Text:find("2,500")
					end, 3, "Phase4 shield display incorrect")
					for _, id in ipairs({ "P1Unstoppable", "P2HourDebt", "P25FutureSight", "LinkedClone" }) do
						local icon = panel.BossPassiveDock:FindFirstChild(id)
						assert(not icon or not icon.Visible, "Unavailable passive shown in Phase4")
					end
				end
				return {
					CenterError = math.abs(center - hud.AbsoluteSize.X * 0.5),
					Gate = data.Gate == true,
					Shield = panel.ShieldValue.Text,
				}
			elseif kind == "EtherealV6" then
				-- Inject under kind=="EtherealV6"; inspect real local camera and spatial fog.
				local lighting = game:GetService("Lighting")
				local camera = workspace.CurrentCamera
				local stage = data.Stage
				local function checkNoScreenDarkness()
					assert(
						not lighting:FindFirstChild("MirrorProjectileLimitedSight")
							and not lighting:FindFirstChild("MirrorProjectileFarDarkness")
							and not lighting:FindFirstChild("EtherealAcumenDarkness"),
						"Old fullscreen brightness/focus effects remain"
					)
					local gui = assert(player.PlayerGui:FindFirstChild("BossCinematicFX"))
					assert(
						not gui:FindFirstChild("MirrorProjectileSightVignette"),
						"Removed fullscreen sight vignette remains"
					)
				end
				local function checkFog()
					local atmosphere =
						assert(lighting:FindFirstChildOfClass("Atmosphere"), "No real spatial Atmosphere")
					assert(
						atmosphere:GetAttribute("GoldenFogLease")
							and atmosphere.Density >= 0.49
							and lighting:GetAttribute("GoldenFogLease")
							and lighting.FogEnd <= 80
							and lighting.FogStart <= 10,
						"Spatial world visibility/atmosphere lease incorrect"
					)
					checkNoScreenDarkness()
					return atmosphere
				end
				local function checkRestored()
					waitFor(function()
						return not player:GetAttribute("SpatialWorldFogActive")
							and not lighting:GetAttribute("GoldenFogLease")
					end, 3, "World fog lease remained")
					assert(
						lighting.FogStart == player:GetAttribute("V6TestFogStart")
							and lighting.FogEnd == player:GetAttribute("V6TestFogEnd")
							and lighting.FogColor == player:GetAttribute("V6TestFogColor"),
						"Owned spatial fog failed to restore prior Lighting"
					)
					local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
					if player:GetAttribute("V6TestHadAtmosphere") then
						assert(
							atmosphere
								and not atmosphere:GetAttribute("GoldenFogLease")
								and atmosphere.Density == player:GetAttribute("V6TestAtmosphereDensity"),
							"Original Atmosphere did not restore"
						)
					else
						assert(not atmosphere, "Created local fog Atmosphere leaked")
					end
					checkNoScreenDarkness()
				end
				if stage == "Baseline" then
					player:SetAttribute("V6TestFogStart", lighting.FogStart)
					player:SetAttribute("V6TestFogEnd", lighting.FogEnd)
					player:SetAttribute("V6TestFogColor", lighting.FogColor)
					player:SetAttribute("V6TestCameraType", camera.CameraType.Name)
					local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
					player:SetAttribute("V6TestHadAtmosphere", atmosphere ~= nil)
					player:SetAttribute("V6TestAtmosphereDensity", atmosphere and atmosphere.Density)
					checkNoScreenDarkness()
					return {
						FogEnd = lighting.FogEnd,
						CameraType = camera.CameraType.Name,
						HadAtmosphere = atmosphere ~= nil,
					}
				elseif stage == "Charge" then
					local hud = waitFor(function()
						return player.PlayerGui:FindFirstChild("PlayerEncounterHUD")
					end, 3, "Charge dialogue HUD missing")
					local quote = waitFor(function()
						local value = hud:FindFirstChild("BossDialogue")
						return value and value.Visible and value.Text == "Welcome to my world." and value
					end, 3, "Exact short Ultimate dialogue did not reach client")
					local first = quote.MaxVisibleGraphemes
					task.wait(0.15)
					assert(
						first >= 0 and quote.MaxVisibleGraphemes >= first and quote.MaxVisibleGraphemes <= #quote.Text,
						"Ultimate bypassed bounded typewriter"
					)
					return { Text = quote.Text, First = first, After = quote.MaxVisibleGraphemes }
				elseif stage == "Orbit" then
					waitFor(function()
						return player:GetAttribute("EtherealCinematicActive") == true
							and camera.CameraType == Enum.CameraType.Scriptable
							and camera:GetAttribute("EtherealCameraToken")
					end, 3, "Captured camera did not become owned cinematic")
					local before = camera.CFrame
					task.wait(0.3)
					assert(
						(camera.CFrame.Position - before.Position).Magnitude > 0.1,
						"Captured camera does not rotate around outside-cube orbit"
					)
					waitFor(function()
						return player:GetAttribute("EtherealWorldActive")
							and player:GetAttribute("SpatialWorldFogActive")
					end, 2, "Ultimate spatial fog missing")
					local atmosphere = checkFog()
					return {
						RotatedDistance = (camera.CFrame.Position - before.Position).Magnitude,
						FogEnd = lighting.FogEnd,
						Density = atmosphere.Density,
					}
				elseif stage == "Cleanup" then
					waitFor(function()
						return not player:GetAttribute("EtherealCinematicActive")
							and not camera:GetAttribute("EtherealCameraToken")
					end, 3, "Ultimate camera token remained")
					checkRestored()
					assert(
						camera.CameraType.Name == player:GetAttribute("V6TestCameraType"),
						"Ultimate failed to restore prior actual-client camera ownership"
					)
					return { Type = camera.CameraType.Name, FogEnd = lighting.FogEnd }
				elseif stage == "ProjectileSight" then
					waitFor(function()
						return player:GetAttribute("ProjectileLimitedSightActive") == data.Active
					end, 3, "Projectile spatial fog state differs on actual client")
					if data.Active then
						waitFor(function()
							return player:GetAttribute("SpatialWorldFogActive")
						end, 2, "Projectile Atmosphere/fog missing")
						local atmosphere = checkFog()
						assert(lighting.FogEnd <= 60, "Projectile does not limit distant world view")
						return { Active = true, FogEnd = lighting.FogEnd, Density = atmosphere.Density }
					else
						checkRestored()
						return { Active = false, FogEnd = lighting.FogEnd }
					end
				else
					error("Unknown EtherealV6 stage: " .. tostring(stage))
				end
			elseif kind == "UIV6" then
				-- Body of the existing three-client driver's branch: kind == "UIV6".
				-- No production test hook or simulated button handler is required.
				local SoundService = game:GetService("SoundService")
				local hud = waitFor(function()
					return player.PlayerGui:FindFirstChild("AlterGoldenBossHUD")
				end, 5, "Boss HUD missing")
				local panel = waitFor(function()
					return hud:FindFirstChild("BossPanel")
				end, 3, "Centered boss panel missing")
				local settings = waitFor(function()
					return player.PlayerGui:FindFirstChild("BossSettingsHUD")
				end, 3, "Independent settings HUD missing")
				local button = settings:WaitForChild("SettingsButton")
				local settingsPanel = settings:WaitForChild("SettingsPanel")
				local toggle = settingsPanel:WaitForChild("MusicMuteButton")
				local encounterHUD = waitFor(function()
					return player.PlayerGui:FindFirstChild("PlayerEncounterHUD")
				end, 3)
				assert(
					not encounterHUD:FindFirstChild("DistortedControls", true),
					"Swapped-key information panel is still present"
				)
				assert(
					not settings:FindFirstChild("ActivateSetting", true),
					"Production contains a test-only settings hook"
				)
				assert(
					settings.Enabled and settings.ResetOnSpawn == false and not settings.IgnoreGuiInset,
					"Settings unavailable across encounter/respawn or outside safe inset"
				)
				waitFor(function()
					return settings.AbsoluteSize.X > 0 and button.AbsoluteSize.X > 0 and panel.AbsoluteSize.X > 0
				end, 3)
				local center = panel.AbsolutePosition.X + panel.AbsoluteSize.X * 0.5
				local centerError = math.abs(center - (hud.AbsolutePosition.X + hud.AbsoluteSize.X * 0.5))
				assert(centerError < 3, "Boss HUD is not horizontally centered: " .. tostring(centerError))
				local expectedWidth = math.max(
					160,
					math.min(850, math.floor(hud.AbsoluteSize.X * (hud.AbsoluteSize.X < 700 and 0.9 or 0.58)))
				)
				assert(
					math.abs(panel.AbsoluteSize.X - expectedWidth) < 3,
					"Boss HUD responsive width differs from safe viewport"
				)
				local right = settings.AbsolutePosition.X + settings.AbsoluteSize.X
				local bottom = settings.AbsolutePosition.Y + settings.AbsoluteSize.Y
				assert(
					button.AbsolutePosition.X >= settings.AbsolutePosition.X
						and button.AbsolutePosition.Y >= settings.AbsolutePosition.Y
						and button.AbsolutePosition.X + button.AbsoluteSize.X <= right
						and button.AbsolutePosition.Y + button.AbsoluteSize.Y <= bottom,
					"Settings hitbox outside safe screen"
				)
				assert(
					math.abs(right - button.AbsolutePosition.X - button.AbsoluteSize.X - 20) < 3
						and math.abs(bottom - button.AbsolutePosition.Y - button.AbsoluteSize.Y - 20) < 3,
					"Settings button is not in the bottom-right corner"
				)
				assert(
					button:IsA("TextButton")
						and toggle:IsA("TextButton")
						and settingsPanel.CloseButton:IsA("TextButton"),
					"Settings controls are not native clickable buttons"
				)
				local result = {
					Player = player.Name,
					CenterError = centerError,
					Width = panel.AbsoluteSize.X,
					Viewport = hud.AbsoluteSize.X,
					SettingsSize = { button.AbsoluteSize.X, button.AbsoluteSize.Y },
					MappingPanelAbsent = true,
				}
				if data.Stage == "Gate" then
					for index = 1, 2 do
						local row = waitFor(function()
							local value = panel:FindFirstChild("ShieldGateClone" .. index)
							return value and value.Visible and value
						end, 3, "Missing gate clone HP panel")
						waitFor(function()
							return row.Value.Text == "1,000 / 1,000"
						end, 3, "Gate HP is not 1000/1000: " .. row.Value.Text)
						assert(row.HealthBar.Fill.Size.X.Scale > 0.999, "Full-health clone fill incorrect")
						assert(not row:FindFirstChild("ShieldBar", true), "Zero-shield gate clone has a shield bar")
					end
					assert(not panel.TrueCloneHealth.Visible, "Retired linked clone panel appears during the gate")
					result.GateHealth = "1,000 / 1,000"
					result.GatePanels = 2
				elseif data.Stage == "Music" then
					local mix = waitFor(function()
						return SoundService:FindFirstChild("BossMusicMix")
					end, 3)
					local music = waitFor(function()
						return SoundService:FindFirstChild("BossPhaseSoundtrack")
					end, 3)
					local combat = SoundService:WaitForChild("BossCombatMix")
					local priority = SoundService:WaitForChild("BossPriorityMix")
					local original = SoundService:GetAttribute("BossMusicMuted") == true
					local originallyEnabled = hud.Enabled
					local ok, failure = xpcall(function()
						waitFor(function()
							return original or mix.Volume >= 0.99
						end, 6, "Prior dialogue has not recovered")
						assert(
							math.abs(music.Volume - 0.22) < 0.00001 and combat.Volume == 1 and priority.Volume == 1,
							"Initial audio mix changed"
						)
						hud.Enabled = false
						assert(
							settings.Enabled and settings.Parent == player.PlayerGui,
							"Settings disappears when boss HUD is hidden"
						)
						SoundService:SetAttribute("BossMusicMuted", true)
						waitFor(function()
							return mix.Volume == 0 and toggle.Text == "Music: Muted"
						end, 2, "Mute preference did not update mix/caption")
						task.wait(0.2)
						assert(
							mix.Volume == 0
								and combat.Volume == 1
								and priority.Volume == 1
								and math.abs(music.Volume - 0.22) < 0.00001,
							"Muting music changed SFX/base gain or did not persist"
						)
						result.MutedMix = mix.Volume
						SoundService:SetAttribute("BossMusicMuted", false)
						waitFor(function()
							return mix.Volume >= 0.99 and toggle.Text == "Music: On"
						end, 3, "Unmuting music did not restore neutral mix")
						assert(
							combat.Volume == 1 and priority.Volume == 1 and math.abs(music.Volume - 0.22) < 0.00001,
							"Unmuting changed attack mix"
						)
						result.UnmutedMix = mix.Volume
						result.SoundVolume = music.Volume
						result.CombatMix = combat.Volume
						result.PriorityMix = priority.Volume
					end, debug.traceback)
					SoundService:SetAttribute("BossMusicMuted", original)
					hud.Enabled = originallyEnabled
					if not ok then
						error(failure, 0)
					end
					result.PreferenceRestored = SoundService:GetAttribute("BossMusicMuted") == original
				elseif data.Stage == "QuietCues" then
					local catalog = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
					local required = {
						CardSummon = true,
						CardThrow = true,
						CardBurst = true,
						EnhancedNormalDraw = true,
						EnhancedNormalSwing = true,
						EnhancedNormalImpact = true,
					}
					local events, played = {}, {}
					local peak = 0
					local failure
					local observer = Replicated.BossCombatEffects.OnClientEvent:Connect(function(kind, payload)
						if kind == "CombatAudio" and required[payload.Cue] then
							events[payload.Cue] = true
						end
					end)
					local sampler = Run.Heartbeat:Connect(function()
						local emitters = workspace:FindFirstChild("BossAudioEmitters")
						if emitters then
							for _, sound in ipairs(emitters:GetDescendants()) do
								if
									sound:IsA("Sound")
									and sound:GetAttribute("CombatVoiceBusy")
									and required[sound:GetAttribute("CombatCue")]
								then
									peak = math.max(peak, sound.Volume)
									if sound.Volume > 0.22001 then
										failure = "New pooled cue exceeded quiet gain: "
											.. sound:GetAttribute("CombatCue")
									end
									if sound.IsLoaded and sound.IsPlaying then
										played[sound:GetAttribute("CombatCue")] = true
									end
								end
							end
						end
						if
							SoundService.BossMusicMix.Volume < 0.99
							or SoundService.BossCombatMix.Volume ~= 1
							or SoundService.BossPriorityMix.Volume ~= 1
						then
							failure = "New attack cue changed the encounter mix"
						end
					end)
					local ok, reason = xpcall(function()
						assert(
							catalog.Attacks.P3Cards.Cast == "CardSummon"
								and catalog.Attacks.P4EnhancedNormalSlashes.Cast == "EnhancedNormalDraw",
							"New attack soundboard entries missing"
						)
						for _, name in ipairs({ "AscensionCry", "AscensionDeclare", "AscensionBell", "AscensionImpact" }) do
							assert(
								not catalog.Cues[name] and not catalog.UploadedCues[name],
								"Retired Ultimate cue remains: " .. name
							)
						end
						assert(
							not catalog.Attacks["P4AscensionToHell(Ultimate)"],
							"Retired Ultimate remains in soundboard"
						)
						for name in pairs(required) do
							local cue = assert(catalog.Cues[name])
							assert(cue.VolumeCap and cue.VolumeCap <= 0.22, "New cue gain cap absent: " .. name)
							for _, layer in ipairs(cue.Layers) do
								assert(layer.Volume <= 0.22, "New cue layer too loud: " .. name)
							end
						end
						waitFor(function()
							if failure then
								error(failure)
							end
							for name in pairs(required) do
								if not events[name] or not played[name] then
									return false
								end
							end
							return true
						end, 6, "A new quiet cue was not delivered and played from the actual pool")
						result.CueEvents = events
						result.CuesPlayed = played
						result.PeakVolume = peak
					end, debug.traceback)
					observer:Disconnect()
					sampler:Disconnect()
					if not ok then
						error(reason, 0)
					end
				elseif data.Stage == "DashMapping" then
					local char = assert(player.Character)
					local root = char:WaitForChild("HumanoidRootPart")
					waitFor(function()
						return (char:GetAttribute("ControlDistortionUntil") or 0) > workspace:GetServerTimeNow()
							and char:GetAttribute("ControlDistortionRuntimeActive")
					end, 3, "Finite distorted movement did not activate")
					local Controls = require(Shared:WaitForChild("Movement"):WaitForChild("R6DashClient"))
					local Motion = require(Shared:WaitForChild("Movement"):WaitForChild("R6DashMotion"))
					local tick = workspace:GetServerTimeNow()
					local camera = workspace.CurrentCamera
					local face = camera and camera.CFrame.LookVector or root.CFrame.LookVector
					face = Vector3.new(face.X, 0, face.Z)
					face = face.Magnitude > 0.01 and face.Unit or Vector3.new(0, 0, -1)
					local raw = Vector3.new(0, 0, -1)
					local walking = Controls.TransformControlDirection(char, Vector3.zero, raw, face, tick, false)
					local direction = Controls.ResolveDashDirection(char, raw, Vector3.zero, face, tick)
					assert(
						walking.Magnitude > 0.9 and walking.Unit:Dot(direction) > 0.99999,
						"Held W resolves differently for walking and Dash"
					)
					local expected = face
					local elapsed = math.max(0, tick - char:GetAttribute("ControlDistortionStartedAt"))
					local ease = math.min(
						1,
						elapsed / 0.3,
						math.max(0, char:GetAttribute("ControlDistortionUntil") - tick) / 0.3
					)
					local rotation = math.sin(
						elapsed * math.pi * 2 / 1.8
							+ math.clamp(char:GetAttribute("ControlDistortionSeed"), 0, math.pi * 2)
					) * math.rad(math.clamp(char:GetAttribute("ControlDistortionMaxRotation"), 0, 55)) * ease
					expected = CFrame.Angles(0, rotation, 0):VectorToWorldSpace(expected)
					assert(
						expected.Unit:Dot(direction) > 0.99999,
						"Dash did not apply the actual permutation and bounded yaw exactly once"
					)
					assert(
						Controls.TransformControlDirection(char, Vector3.zero, Vector3.zero, face, tick, false).Magnitude
							== 0,
						"Distortion generated movement without input"
					)
					Controls.RememberControlMovement(char, walking * 0.5, tick)
					local analog = Controls.ResolveDashDirection(char, Vector3.zero, walking * 0.5, face, tick)
					assert(
						analog:Dot(direction) > 0.99999,
						"Already distorted touch/gamepad direction was rotated twice"
					)
					local dashRemote = Replicated:WaitForChild("PlayerDash")
					local request, approval, sequence, serverStamina, reason
					local observer = dashRemote.OnClientEvent:Connect(function(id, accepted, why, serial, stamina)
						if id == request then
							approval = accepted
							reason = why
							sequence = serial
							serverStamina = stamina
						end
					end)
					local origin = root.Position
					local kind = Motion.Kind(root, direction)
					local ok, failure = xpcall(function()
						request = assert(Controls.Start(char, direction), "Real mapped Dash prediction was unavailable")
						dashRemote:FireServer(direction, face, request)
						waitFor(function()
							return approval ~= nil
						end, 3, "Actual server Dash response did not arrive")
						assert(approval, "Actual server rejected mapped Dash: " .. tostring(reason))
						waitFor(function()
							return char:GetAttribute("DashSequence") == sequence
						end, 2, "Server did not publish mapped Dash approval")
						assert(
							char:GetAttribute("DashDirection") == kind,
							"Authority approved a different mapped Dash direction"
						)
						task.wait(0.16)
						local delta = root.Position - origin
						delta = Vector3.new(delta.X, 0, delta.Z)
						assert(
							delta:Dot(direction) > 0.5,
							"Approved mapped Dash did not move along its requested direction"
						)
						result.Approved = true
						result.Sequence = sequence
						result.ServerStamina = serverStamina
						result.RequestedAt = request
						result.Direction = { direction.X, direction.Z }
						result.Kind = kind
						result.WalkDashDot = walking.Unit:Dot(direction)
						result.AnalogDot = analog:Dot(direction)
						result.Displacement = delta.Magnitude
						result.ForwardDisplacement = delta:Dot(direction)
					end, debug.traceback)
					observer:Disconnect()
					Controls.Cancel()
					if not ok then
						error(failure, 0)
					end
				end
				return result
			else
				error("Unknown client integration command: " .. tostring(kind))
			end
		end, debug.traceback)
		remote:FireServer(ok and "Done" or "Failure", data.Id, result)
	end)
end)
remote:FireServer("Ready")
