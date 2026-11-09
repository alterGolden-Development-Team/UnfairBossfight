local BossSystem = script:FindFirstAncestor("BossSystem")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Config = require(Shared.Config.EncounterConfig)
local NAME = "P3PickThePupils(Ultimate)"
local TOTAL_ROUNDS = 1
local Style = require(script.Style)
local CreateVisuals = require(script.Visuals)
local CreateStage = require(script.Stage)
local CreateHands = require(script.Hands)
local CreateCups = require(script.Cups)
local Dialogue = require(script.Dialogue)
local CreateCapture = require(script.Capture)
local PICK_SECONDS = 5
local FLASH_SCALE = Style.FLASH_SCALE
local GOLD = Style.GOLD
local PALE = Style.PALE
local WHITE = Style.WHITE
local DARK = Style.DARK
local GREEN = Style.GREEN
local RED = Style.RED
local VIOLET = Style.VIOLET
local CONFETTI = Style.CONFETTI
local SPARKLE = Style.SPARKLE
local HAND_L = Style.HAND_L
local HAND_R = Style.HAND_R
local BASE_GRADE = Style.BASE_GRADE
local kp = NumberSequenceKeypoint.new

local function ease(t)
	return t * t * (3 - 2 * t)
end
local function outCubic(t)
	return 1 - (1 - t) ^ 3
end
local function outBack(t)
	return 1 + 2.70158 * (t - 1) ^ 3 + 1.70158 * (t - 1) ^ 2
end

local MODES = {
	Easy = { Count = 3, Swaps = 4, Speed = 1.1 },
	Medium = { Count = 3, Swaps = 7, Speed = 0.65 },
	AfterImage = { Count = 3, Swaps = 10, Speed = 0.28, Trails = true },
	Illusion = { Count = 3, Swaps = 7, Speed = 0.55, Fake = true },
	Insane = { Count = 5, Swaps = 12, Speed = 0.32 },
	DoubleCross = { Count = 5, Swaps = 14, Speed = 0.38, Double = true, Trails = true },
	FalseMemory = { Count = 5, Swaps = 16, Speed = 0.36, Mixed = true, Trails = true },
	Carousel = { Count = 5, Swaps = 15, Speed = 0.34, Rotate = true, Trails = true },
}
local MODE_NAMES = { "Easy", "Medium", "AfterImage", "Illusion", "Insane", "DoubleCross", "FalseMemory", "Carousel" }

return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local HealthPenalty = require(BossSystem.Combat.HealthPenaltyService)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Dash = require(BossSystem.Players.R6DashService)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local core = Registry.For(actor, "P1CombatCore")
	local remote = game.ReplicatedStorage:WaitForChild("BossCombatEffects")
	local random = Random.new()
	local api = { Cooldown = Config.PickThePupilsCooldown or 60, ManagesCooldown = true }
	local current
	function api.CanUse(target)
		return not current
			and Cooldowns.Ready(actor, NAME)
			and math.floor(actor:GetAttribute("Phase") or 1) == 3
			and core.Active()
			and core.Alive(target)
			and not actor:GetAttribute("IsGoldenClone")
			and not actor:GetAttribute("PhaseTransitionInProgress")
	end
	function api.Combo(target, options)
		if not api.CanUse(target) then
			return false
		end
		options = Run:IsStudio() and options or nil
		local timeScale = math.clamp(options and options.TimeScale or 1, 0.05, 1)
		return core.Perform(target, NAME, function()
			local bounds = Placement.GetBounds()
			if not bounds then
				return false
			end
			local center = Placement.GroundPoint(bounds.Frame.Position, { Clamp = true, Margin = 20 })
			if not center then
				return false
			end
			local frame = CFrame.new(center) * bounds.Frame.Rotation
			local root, base = core.Root, core.Root.CFrame
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local cast = Effects.NewCast(actor, NAME, Config.PickThePupilsMaxDuration or 300)
			current = cast
			Cooldowns.Start(actor, NAME, api.Cooldown)
			local token = NAME .. ":" .. tostring(cast.realBorn)
			local folder = Instance.new("Folder")
			folder.Name = NAME .. "Show"
			folder.Parent = Runtime.Effects
			cast:Add(folder)
			local state = {
				Stage = "Entrance",
				Wins = 0,
				Attempt = 0,
				RoundsCompleted = 0,
				Results = {},
				Cups = {},
				Pads = {},
				Token = token,
			}
			api.State = state
			local pupil, roundFolder, hands = nil, nil, {}
			local audience, origins, visibility = {}, {}, {}
			local lights = {}
			local savedLight = {}
			for _, property in ipairs({ "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation" }) do
				savedLight[property] = Lighting[property]
			end
			Lighting:SetAttribute("PickThePupilsToken", token)
			local nightTween = TweenService:Create(Lighting, TweenInfo.new(0.9 * timeScale), {
				ClockTime = 0,
				Brightness = 0.6,
				Ambient = Color3.fromRGB(60, 48, 78),
				OutdoorAmbient = Color3.fromRGB(30, 26, 49),
				ExposureCompensation = -0.25,
			})
			nightTween:Play()

			 
			local post = {}
			local function addPost(className, props, goal)
				local fx = Instance.new(className)
				fx.Name = "PickThePupils" .. className
				for key, value in pairs(props) do
					fx[key] = value
				end
				fx:SetAttribute("PickThePupilsToken", token)
				fx.Parent = Lighting
				table.insert(post, fx)
				TweenService:Create(fx, TweenInfo.new(0.9 * timeScale), goal):Play()
				return fx
			end
			addPost(
				"BloomEffect",
				{ Intensity = 0, Size = 24, Threshold = 2 },
				{ Intensity = 0.3, Size = 28, Threshold = 1.1 }
			)
			local grade = addPost("ColorCorrectionEffect", {}, BASE_GRADE)
			local function regrade(goal, seconds)
				TweenService:Create(grade, TweenInfo.new((seconds or 0.3) * timeScale), goal):Play()
			end

			 
			local aura = Instance.new("ParticleEmitter")
			aura.Name = "PickThePupilsAura"
			aura.Texture = SPARKLE
			aura.Color = ColorSequence.new(GOLD, WHITE)
			aura.LightEmission = 1
			aura.Rate = 0
			aura.Lifetime = NumberRange.new(0.8, 1.6)
			aura.Speed = NumberRange.new(2, 8)
			aura.SpreadAngle = Vector2.new(180, 180)
			aura.Size = NumberSequence.new({ kp(0, 1.4), kp(1, 0) })
			aura.Parent = root
			local auraLight = Instance.new("PointLight")
			auraLight.Name = "PickThePupilsAuraLight"
			auraLight.Color, auraLight.Range, auraLight.Brightness = PALE, 0, 0
			auraLight.Parent = root

			local function valid()
				return cast:Alive()
					and actor.Parent
					and core.Active()
					and math.floor(actor:GetAttribute("Phase") or 1) == 3
					and not actor:GetAttribute("EncounterEnded")
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
			end
			local function send(kind, data)
				data = data or {}
				data.Kind, data.Token, data.Owner, data.Frame = kind, token, actor, frame
				data.Round, data.Wins, data.Total = math.max(1, state.Attempt), state.Wins, TOTAL_ROUNDS
				data.Mode = state.Mode
				data.PupilUserId = pupil and pupil.Player and pupil.Player.UserId or 0
				data.PupilName = pupil and (pupil.Player and pupil.Player.DisplayName or "Golden pupil") or "Pupil"
				for _, player in ipairs(audience) do
					if player.Parent == Players then
						remote:FireClient(player, "PickThePupilsFX", data)
					end
				end
			end

			 
			 
			local function lp(worldPos)
				return frame:PointToObjectSpace(worldPos)
			end
			local function shot(pos, look, fov, seconds, style)
				send(
					"Camera",
					{ Pos = pos, Look = look, FOV = fov, Duration = seconds * timeScale, Style = style or "Sine" }
				)
			end
			local function shake(power, seconds)
				send("Shake", { Power = power, Duration = seconds * timeScale })
			end
			local function flash(color, seconds, alpha)
				send("Flash", { Color = color, Duration = seconds * timeScale, Alpha = (alpha or 0.35) * FLASH_SCALE })
			end
			local function letterbox(on)
				send("Letterbox", { On = on })
			end
			local function releaseCamera()
				send("CameraRelease", {})
			end

			local function cue(name, at, volume)
				Audio.Emit(actor, name, at or root, { VolumeScale = volume or 0.8 })
			end
			local visuals = CreateVisuals({
				Folder = folder, Cast = cast, TimeScale = timeScale, Valid = valid, Cue = cue,
			})
			local part, cylinder, label = visuals.Part, visuals.Cylinder, visuals.Label
			local burst, ring, pillar = visuals.Burst, visuals.Ring, visuals.Pillar
			local fireworks, confetti = visuals.Fireworks, visuals.Confetti

			local function setVisible(character, show)
				if show then
					for object, props in pairs(visibility[character] or {}) do
						if object.Parent then
							for key, value in pairs(props) do
								object[key] = value
							end
						end
					end
					visibility[character] = nil
					return
				end
				if visibility[character] then
					return
				end
				local saved = {}
				visibility[character] = saved
				for _, object in ipairs(character:GetDescendants()) do
					if object:IsA("BasePart") or object:IsA("Decal") then
						saved[object] = { Transparency = object.Transparency }
						object.Transparency = 1
					elseif
						object:IsA("BillboardGui")
						or object:IsA("ParticleEmitter")
						or object:IsA("Beam")
						or object:IsA("Trail")
						or object:IsA("Light")
						or object:IsA("Highlight")
					then
						saved[object] = { Enabled = object.Enabled }
						object.Enabled = false
					elseif object:IsA("ForceField") then
						saved[object] = { Visible = object.Visible }
						object.Visible = false
					end
				end
			end
			local function releasePupil()
				if not pupil then
					return
				end
				local old = pupil
				pupil, state.Pupil = nil, nil
				setVisible(old.Character, true)
				if old.Player then
					Encounter.SetDamageGate(old.Character, cast, false)
					Status.SetLocked(old.Player, cast, false)
					if old.Character.Parent and old.Character:GetAttribute("PickThePupilsToken") == token then
						old.Character:SetAttribute("PickThePupilsCaptured", nil)
						old.Character:SetAttribute("PickThePupilsToken", nil)
					end
					if old.Root.Parent then
						if old.Player.Character == old.Character and core.Alive(old.Character) then
							old.Root.CFrame = Placement.ResolveRecorded(old.Character, old.Origin, { Margin = 8 })
								or old.Origin
						end
						old.Root.Anchored = old.Anchored
						old.Root.AssemblyLinearVelocity, old.Root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
					end
					if old.Humanoid.Parent then
						old.Humanoid.DisplayDistanceType = old.Display
					end
				else
					old.Character:Destroy()
				end
			end
			local function livePlayers()
				local alive = {}
				for _, p in ipairs(audience) do
					local c = p.Character
					if
						p.Parent == Players
						and c
						and core.Alive(c)
						and not Encounter.IsDefeated(p)
						and not p:GetAttribute("ExecutionPending")
					then
						table.insert(alive, p)
					end
				end
				return alive
			end
			local function makeNPC()
				local model = Instance.new("Model")
				model.Name = "GoldenPupil"
				local r = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.identity, GOLD, nil, 1)
				part(model, "Torso", Vector3.new(2, 2, 1), CFrame.identity, DARK, Enum.Material.SmoothPlastic)
				local head =
					part(model, "Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0), PALE, Enum.Material.SmoothPlastic)
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Head
				mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
				mesh.Parent = head
				for _, x in ipairs({ -1.5, 1.5 }) do
					part(
						model,
						x < 0 and "Left Arm" or "Right Arm",
						Vector3.new(1, 2, 1),
						CFrame.new(x, 0, 0),
						PALE,
						Enum.Material.SmoothPlastic
					)
				end
				for _, x in ipairs({ -0.5, 0.5 }) do
					part(
						model,
						x < 0 and "Left Leg" or "Right Leg",
						Vector3.new(1, 2, 1),
						CFrame.new(x, -2, 0),
						DARK,
						Enum.Material.SmoothPlastic
					)
				end
				local h = Instance.new("Humanoid")
				h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				h.MaxHealth = 100
				h.Health = 100
				h.BreakJointsOnDeath = false
				h.RequiresNeck = false
				h.EvaluateStateMachine = false
				h.Parent = model
				label(head, "PUPIL", PALE, 2.4)
				model.PrimaryPart = r
				model.Parent = folder
				return model
			end
			local function selectPupil(forceNPC)
				releasePupil()
				local alive, eligible = livePlayers(), {}
				for _, p in ipairs(alive) do
					if not p.Character.HumanoidRootPart.Anchored and not Status.IsDebuffImmune(p.Character) then
						table.insert(eligible, p)
					end
				end
				local chosen = not forceNPC and #alive > 1 and #eligible > 0 and eligible[random:NextInteger(1, #eligible)] or nil
				local character = chosen and chosen.Character or makeNPC()
				local r, h = character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
				pupil = {
					Player = chosen,
					Character = character,
					Root = r,
					Humanoid = h,
					Origin = r.CFrame,
					Anchored = r.Anchored,
					Display = h.DisplayDistanceType,
				}
				state.Pupil = pupil
				if chosen then
					Dash.Cancel(chosen, NAME)
					Status.SetLocked(chosen, cast, true)
					Encounter.SetDamageGate(character, cast, true)
					character:SetAttribute("PickThePupilsCaptured", true)
					character:SetAttribute("PickThePupilsToken", token)
				end
				h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				r.Anchored = true
				return #alive > 0
			end
			local function pupilAlive()
				return pupil
					and core.Alive(pupil.Character)
					and (
						not pupil.Player
						or pupil.Player.Parent == Players and pupil.Player.Character == pupil.Character
					)
			end
			local function placePupil(cf)
				if pupilAlive() then
					pupil.Character:PivotTo(cf * CFrame.new(0, 3.2, 0))
				end
			end
			local function pupilHighlight(color)
				if not (pupil and roundFolder) then
					return nil
				end
				local h = Instance.new("Highlight")
				h.Adornee = pupil.Character
				h.FillColor, h.OutlineColor = color, color
				h.FillTransparency, h.OutlineTransparency = 0.7, 0
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = roundFolder
				return h
			end
			local function animate(seconds, fn)
				local duration, elapsed = seconds * timeScale, 0
				repeat
					if not valid() then
						return false
					end
					local alpha = math.clamp(elapsed / math.max(duration, 0.001), 0, 1)
					if fn then
						fn(alpha, elapsed / timeScale)
					end
					if alpha >= 1 then
						break
					end
					elapsed += Run.Heartbeat:Wait()
				until false
				return true
			end

			cast.OnDispose = function()
				 
				Cooldowns.Start(actor, NAME, api.Cooldown)
				actor:SetAttribute("PickThePupilsReadyAt", workspace:GetServerTimeNow() + api.Cooldown)
				releasePupil()
				for character in pairs(visibility) do
					setVisible(character, true)
				end
				for character, original in pairs(origins) do
					local p = Players:GetPlayerFromCharacter(character)
					if
						p
						and p.Character == character
						and core.Alive(character)
						and not character.HumanoidRootPart.Anchored
					then
						character:PivotTo(Placement.ResolveRecorded(character, original, { Margin = 8 }) or original)
						character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
					end
				end
				nightTween:Cancel()
				if Lighting:GetAttribute("PickThePupilsToken") == token then
					for key, value in pairs(savedLight) do
						Lighting[key] = value
					end
					Lighting:SetAttribute("PickThePupilsToken", nil)
				end
				for _, fx in ipairs(post) do
					if fx.Parent then
						TweenService:Create(
							fx,
							TweenInfo.new(0.5),
							fx:IsA("BloomEffect") and { Intensity = 0 }
								or { Contrast = 0, Saturation = 0, Brightness = 0, TintColor = WHITE }
						):Play()
						task.delay(0.6, function()
							fx:Destroy()
						end)
					end
				end
				aura:Destroy()
				auraLight:Destroy()
				if
					root.Parent
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
				then
					root.CFrame = base
				end
				if actor.Parent and actor:GetAttribute("PickThePupilsToken") == token then
					actor:SetAttribute("PickThePupilsActive", false)
					actor:SetAttribute("PickThePupilsToken", nil)
				end
				releaseCamera()
				letterbox(false)
				send("End", { Success = state.RoundsCompleted >= TOTAL_ROUNDS })
				if current == cast then
					current = nil
					api.State = nil
				end
				core.AirborneFloor = nil
			end
			actor:SetAttribute("PickThePupilsActive",true)
   local classes=require(BossSystem.Players.Classes.ClassService)
   for _,p in Players:GetPlayers() do if p.Character then classes.ClearFateLink(p.Character) end end
			actor:SetAttribute("PickThePupilsToken", token)
			core.AirborneFloor = base.Y
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				if
					character
					and core.Alive(character)
					and Placement.Contains(character.HumanoidRootPart.Position, 0)
					and not Encounter.IsDefeated(player)
				then
					table.insert(audience, player)
					origins[character] = character:GetPivot()
				end
			end
			local success, result = xpcall(function()
				if #audience == 0 then
					return false
				end
				 
				local clone = Registry.For(actor, "P3Clone")
				if clone.Dispose then
					clone.Dispose()
				end
				for i, p in ipairs(audience) do
					local c = p.Character
					if c and core.Alive(c) and not c.HumanoidRootPart.Anchored then
						Dash.Cancel(p, NAME)
						c:PivotTo(frame * CFrame.new((i - (#audience + 1) / 2) * 6, 3.2, 42))
					end
				end

				CreateStage({ Folder = folder, Frame = frame, Cast = cast, State = state,
					TimeScale = timeScale, Visuals = visuals })
				hands = CreateHands({ Folder = folder, Frame = frame, Visuals = visuals })
				local h0 = { hands[1]:GetPivot(), hands[2]:GetPivot() }

				 
				send("Entrance", { Duration = 2.4 * timeScale })
				Encounter.Say("This will be really fun.", nil, { Duration = 3 })
				letterbox(true)
				flash(WHITE, 0.7, 0.6)
				shake(0.5, 0.8)
				shot(Vector3.new(0, 10, 98), Vector3.new(0, 24, -26), 62, 0, "Cut")
				shot(Vector3.new(0, 34, 84), Vector3.new(0, 22, -20), 58, 2.4, "Quad")
				ring(frame * CFrame.new(0, 0.3, 0), 140, GOLD, 1.2, 0.5, 4)
				ring(frame * CFrame.new(0, 0.3, 0), 100, WHITE, 0.9, 0.25, 4)
				pillar(center, PALE, 90, 1.4)
				confetti(center + Vector3.new(0, 12, 0), 90, 70, 60)
				cue("EtherealCharge")
				core.PoseAngles({ RightShoulder = { 110, 0, -55 }, LeftShoulder = { 110, 0, 55 } }, 0.4)
				local sky = frame * CFrame.new(0, 30, -26) * CFrame.Angles(0, math.pi, 0)
				if
					not animate(2.4, function(a)
						root.CFrame = base:Lerp(sky, outCubic(a))
						local e = ease(a)
						hands[1]:PivotTo(h0[1]:Lerp(frame * HAND_L, e))
						hands[2]:PivotTo(h0[2]:Lerp(frame * HAND_R, e))
						aura.Rate = 20 + 140 * a
						auraLight.Range, auraLight.Brightness = 40 * a, 3 * a
					end)
				then
					return false
				end
				ring(frame * CFrame.new(0, 0.3, -10), 60, PALE, 0.7, 0.3, 6)
				shake(0.3, 0.3)

				local function homeHands(from1, from2, alpha)
					hands[1]:PivotTo(from1:Lerp(frame * HAND_L, alpha))
					hands[2]:PivotTo(from2:Lerp(frame * HAND_R, alpha))
				end

				if not selectPupil() then return false end
				local capture = CreateCapture({ Hands = hands, Frame = frame, Animate = animate })
				state.Stage = "Grab"
				shot(Vector3.new(0, 17, 74), lp(pupil.Root.Position), 60, 0.4, "Quad")
				if pupil.Player then
     if not capture.Grab(pupil) then return false end
    else
     state.Stage = "Summon"
     setVisible(pupil.Character, false)
     if not capture.Snap(pupil, function()
      setVisible(pupil.Character, true)
      burst(pupil.Root.Position, PALE, 1.6)
      cue("MagicCast", pupil.Root.Position, 1)
     end) then return false end
    end
				Encounter.Say(Dialogue.Entrance, nil, { Duration = 3 })
				local cups = CreateCups({ TimeScale = timeScale, Visuals = visuals })

				local function syncLamps()
					for i, cup in ipairs(state.Cups) do
						local piv = cup.Model:GetPivot()
						lights[i].Lamp:PivotTo(piv * CFrame.new(0, 43, 0))
						lights[i].Pool:PivotTo(
							CFrame.new(piv.Position.X, cup.Frame.Position.Y + 0.06, piv.Position.Z)
								* frame.Rotation
								* CFrame.Angles(0, 0, math.pi / 2)
						)
					end
				end


				while valid() and state.Attempt < TOTAL_ROUNDS do
					if #livePlayers() == 0 then
						return false
					end
					if not pupilAlive() then
						if not selectPupil() then
							return false
						end
					end
					state.Attempt += 1
					local sequence = options and options.DifficultySequence
					local forced = sequence and #sequence > 0 and sequence[(state.Attempt - 1) % #sequence + 1]
					state.Mode = forced and MODES[forced] and forced or MODE_NAMES[random:NextInteger(1, #MODE_NAMES)]
					local mode = MODES[state.Mode]
					if roundFolder then
						roundFolder:Destroy()
					end
					roundFolder = Instance.new("Folder")
					roundFolder.Name = "Round" .. state.Attempt
					roundFolder.Parent = folder
					state.Cups, state.Pads, lights = {}, {}, {}
					state.Mood, state.Deadline, state.Focus, state.Penalties = nil, nil, nil, nil
					local slots = {}
					for i = 1, mode.Count do
						slots[i] = frame * CFrame.new((i - (mode.Count + 1) / 2) * 25, 0.25, 0)
						local cup = cups.Cup(roundFolder, i, slots[i])
						state.Cups[i] = cup
						lights[i] = cups.Spotlight(roundFolder, cup)
					end
					state.Holder = state.Cups[random:NextInteger(1, mode.Count)]
					state.Stage = "Remember"
					setVisible(pupil.Character, true)
					local holderLocal = lp(state.Holder.Frame.Position)
					send("Remember", { Count = mode.Count, Duration = 2.6 * timeScale })
					actor:SetAttribute("AttackState", "Pick the Pupils: " .. state.Mode .. " / round " .. state.Attempt)
					regrade(BASE_GRADE, 0.6)
					letterbox(true)
					shot(Vector3.new(holderLocal.X * 0.4, 24, 66), Vector3.new(holderLocal.X, 8, 0), 56, 0.9, "Quad")

					local stagger = 0.35 / math.max(mode.Count - 1, 1)
					for _, cup in ipairs(state.Cups) do
						cup.Trail.Enabled = true
						cup.Model:PivotTo(cup.Frame * CFrame.new(0, 70, 0))
					end
					cue("P3Snap", center, 0.6)
					if
						not animate(0.8, function(a)
							for i, cup in ipairs(state.Cups) do
								local k = math.clamp((a - (i - 1) * stagger) / 0.65, 0, 1)
								cup.Model:PivotTo(cup.Frame * CFrame.new(0, 14 + 56 * (1 - outCubic(k)), 0))
							end
							syncLamps()
						end)
					then
						return false
					end
					for _, cup in ipairs(state.Cups) do
						cup.Trail.Enabled = false
						burst(cup.Frame.Position + Vector3.new(0, 14, 0), PALE, 0.3)
					end

					for i, cup in ipairs(state.Cups) do
						lights[i].Light.Brightness = cup == state.Holder and 10 or 1.5
					end
					state.Stage = "Deposit"
					if not capture.Deposit(pupil, state.Holder.Frame) then return false end
					local releasedHand1, releasedHand2 = hands[1]:GetPivot(), hands[2]:GetPivot()
					if not animate(0.35, function(a) homeHands(releasedHand1, releasedHand2, ease(a)) end) then return false end
					Encounter.Say(Dialogue.Modes[state.Mode], nil, { Duration = 4 })
					state.Stage = "Remember"
					local remembered = pupilHighlight(PALE)
					ring(state.Holder.Frame * CFrame.new(0, 0.1, 0), 34, PALE, 1.1, 0.25, 6)
					shot(Vector3.new(holderLocal.X * 0.55, 18, 52), Vector3.new(holderLocal.X, 10, 0), 44, 2.6, "Sine")
					if
						not animate(2.6, function(_, el)
							placePupil(
								state.Holder.Frame
									* CFrame.new(0, math.sin(el * 3) * 0.4, 0)
									* CFrame.Angles(0, el * 1.2, 0)
							)
						end)
					then
						return false
					end
					if remembered then
						remembered:Destroy()
					end

					shot(Vector3.new(0, 36, 74), Vector3.new(0, 8, 0), 56, 0.65, "Quad")
					for i, cup in ipairs(state.Cups) do
						cup.Model:PivotTo(cup.Frame * CFrame.new(0, 14, 0))
						lights[i].Light.Brightness = 6
					end
					if
						not animate(0.65, function(a)
							for _, cup in ipairs(state.Cups) do
								cup.Model:PivotTo(cup.Frame * CFrame.new(0, 14 * (1 - a ^ 2.2), 0))
							end
						end)
					then
						return false
					end
					for _, cup in ipairs(state.Cups) do
						ring(cup.Frame * CFrame.new(0, 0.1, 0), 30, PALE, 0.55, 0.25, 8)
						burst(cup.Frame.Position + Vector3.new(0, 1, 0), PALE, 0.25)
					end
					cue("P3Snap", center, 0.9)
					shake(0.5, 0.35)
					 
					if pupil.Player and #livePlayers() == 1 then
						if not selectPupil(true) then return false end
						placePupil(state.Holder.Frame)
					end
					setVisible(pupil.Character, false)
					syncLamps()

					state.Stage = "Shuffle"
					send("Shuffle", { Count = mode.Count })
					local shuffleTime = 0
					for n = 1, mode.Swaps do
						shuffleTime += mode.Speed * (1.2 - 0.5 * (n - 1) / math.max(mode.Swaps - 1, 1))
					end
					shot(Vector3.new(0, 46, 60), Vector3.new(0, 6, 0), 52, shuffleTime, "Sine")
					for n = 1, mode.Swaps do
						local fake = mode.Fake or (mode.Mixed and n % 3 == 0)
						local moves = {}
						local function move(cup, destination, slot, side)
							table.insert(
								moves,
								{ Cup = cup, Start = cup.Frame, Finish = destination, Slot = slot, Side = side }
							)
						end
						if mode.Rotate and n % 3 == 0 then
							local direction = random:NextInteger(0, 1) == 0 and -1 or 1
							for _, cup in ipairs(state.Cups) do
								local slot = (cup.Slot - 1 + direction) % mode.Count + 1
								local wraps = math.abs(slot - cup.Slot) > 1
								move(cup, slots[slot], slot, wraps and -2 or 1)
							end
						else
							local order = table.clone(state.Cups)
							for i = #order, 2, -1 do
								local j = random:NextInteger(1, i)
								order[i], order[j] = order[j], order[i]
							end
							for pair = 1, mode.Double and 2 or 1 do
								local a, b = order[pair * 2 - 1], order[pair * 2]
								move(a, b.Frame, b.Slot, pair)
								move(b, a.Frame, a.Slot, -pair)
							end
						end
						local tint = fake and VIOLET or GOLD
						for _, movement in ipairs(moves) do
							movement.Cup.Trail.Color = ColorSequence.new(tint, PALE)
							movement.Cup.Trail.Enabled = true
							ring(movement.Start * CFrame.new(0, 0.1, 0), 22, tint, 0.35, 0.18, 8)
						end
						local lastGhost = -1
						local speed = mode.Speed * (1.2 - 0.5 * (n - 1) / math.max(mode.Swaps - 1, 1))
						cue("P3Snap", moves[1].Start.Position, 0.25)
						if
							not animate(speed, function(t, elapsed)
								local echoes = (mode.Trails or fake) and elapsed - lastGhost > 0.16
								if echoes then
									lastGhost = elapsed
								end
								for index, movement in ipairs(moves) do
									local arc = frame.LookVector * math.sin(t * math.pi) * 10 * movement.Side
									local cf = movement.Start:Lerp(movement.Finish, ease(t)) + arc
									movement.Cup.Model:PivotTo(cf * CFrame.Angles(0, 0, math.sin(t * math.pi) * 0.12))
									if not fake and movement.Cup == state.Holder then
										placePupil(cf)
									end
									if index <= 2 then
										hands[index]:PivotTo(
											cf
												* CFrame.new(index == 1 and -4 or 4, 18, -3)
												* CFrame.Angles(0, math.pi, 0)
										)
									end
									if echoes then
										cups.Ghost(roundFolder, cf, tint)
									end
								end
								syncLamps()
							end)
						then
							return false
						end
						for _, movement in ipairs(moves) do
							local cup = movement.Cup
							cup.Trail.Enabled = false
							 
							if not fake then
								cup.Frame, cup.Slot = movement.Finish, movement.Slot
							end
							cup.Model:PivotTo(cup.Frame)
						end
						placePupil(state.Holder.Frame)
						if fake then
							flash(VIOLET, 0.25, 0.12)
						end
						if mode.Swaps >= 10 and n % 3 == 0 then
							shake(0.15, 0.2)
						end
					end
					placePupil(state.Holder.Frame)
					syncLamps()
					local s1, s2 = hands[1]:GetPivot(), hands[2]:GetPivot()
					if not animate(0.4, function(t)
							homeHands(s1, s2, ease(t))
						end) then
						return false
					end

					releaseCamera()
					letterbox(false)
					for i, cf in ipairs(slots) do
						local padFrame = cf * CFrame.new(0, 0, 26)
						local pad =
							cylinder(roundFolder, "ChoicePad" .. i, 2, 0.3, padFrame, GOLD, Enum.Material.Neon, 0.22)
						TweenService:Create(
							pad,
							TweenInfo.new(0.45 * timeScale, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
							{ Size = Vector3.new(0.3, 13, 13) }
						):Play()
						local column = cylinder(
							roundFolder,
							"VoteColumn" .. i,
							8,
							0.1,
							padFrame * CFrame.new(0, 0.2, 0),
							WHITE,
							Enum.Material.Neon,
							0.9
						)
						ring(padFrame * CFrame.new(0, 0.3, 0), 20, GOLD, 0.6, 0.2, 4)
						state.Pads[i] = {
							Part = pad,
							Column = column,
							H = 0,
							Frame = padFrame,
							Label = label(pad, tostring(i) .. "  /  0", WHITE, 2.5),
						}
					end
					state.Stage, state.Votes = "Pick", {}
					local deadline = workspace:GetServerTimeNow() + PICK_SECONDS * timeScale
					state.Deadline, state.PickTotal = deadline, PICK_SECONDS * timeScale
					send("Pick", { Count = mode.Count, EndsAt = deadline })
					Encounter.Say(Dialogue.Pick, nil, { Duration = PICK_SECONDS * timeScale })
					local function countVotes()
						local counts, voters = table.create(mode.Count, 0), {}
						for _, p in ipairs(livePlayers()) do
							if p ~= pupil.Player then
								local r = p.Character.HumanoidRootPart
								for i, pad in ipairs(state.Pads) do
									local pos = pad.Frame:PointToObjectSpace(r.Position)
									if Vector2.new(pos.X, pos.Z).Magnitude <= 6.5 and pos.Y >= -1 and pos.Y <= 7 then
										counts[i] += 1
										voters[p] = i
										break
									end
								end
							end
						end
						state.Votes = voters
						local pulse = 0.5 + 0.06 * math.sin(os.clock() * 3)
						for i, pad in ipairs(state.Pads) do
							pad.Label.Text = i .. "  /  " .. counts[i]
							pad.Part.Color = counts[i] > 0 and WHITE or GOLD
							pad.Part.Transparency = pulse
							pad.H += (counts[i] * 5 - pad.H) * 0.25
							local h = math.max(pad.H, 0.1)
							pad.Column.Size = Vector3.new(h, 8, 8)
							pad.Column.CFrame = pad.Frame
								* CFrame.new(0, h / 2 + 0.2, 0)
								* CFrame.Angles(0, 0, math.pi / 2)
							pad.Column.Transparency = counts[i] > 0 and 0.65 or 0.95
						end
						return counts
					end
					local lastTick = math.huge
					if
						not animate(PICK_SECONDS, function(_, elapsed)
							countVotes()
							local secondsLeft = math.ceil(PICK_SECONDS - elapsed)
							if secondsLeft <= 3 and secondsLeft > 0 and secondsLeft ~= lastTick then
								lastTick = secondsLeft
								cue("P3Snap", center, 0.5)
								for _, pad in ipairs(state.Pads) do
									ring(pad.Frame * CFrame.new(0, 0.3, 0), 18, RED, 0.5, 0.15, 8)
								end
							end
						end)
					then
						return false
					end
					local counts = countVotes()
					local chosen, most, tied = nil, 0, false
					for i, votes in ipairs(counts) do
						if votes > most then
							chosen, most, tied = i, votes, false
						elseif votes > 0 and votes == most then
							tied = true
						end
					end
					if tied then
						chosen = nil
					end
					state.SelectedSlot, state.Stage = chosen, "Suspense"
					state.Deadline = nil
					local chosenCup
					for _, cup in ipairs(state.Cups) do
						if cup.Slot == chosen then
							chosenCup = cup
						end
					end
					local revealFrame = chosenCup and chosenCup.Frame or state.Holder.Frame
					state.Focus = revealFrame.Position + Vector3.new(0, 8, 0)
					local rl = lp(revealFrame.Position)
					if chosen then
					cue("PupilSuspense", revealFrame.Position, 1)
					send("Suspense", {
						Position = revealFrame.Position,
						Choice = chosen,
						Reason = tied and "TIE" or not chosen and "NO VOTE" or nil,
						Duration = 1.8 * timeScale,
					})

					for i, cup in ipairs(state.Cups) do
						lights[i].Light.Brightness = cup == chosenCup and 9 or 0.2
					end
					regrade({ Brightness = -0.12, Contrast = 0.22, Saturation = -0.1 }, 0.6)
					letterbox(true)
					shot(Vector3.new(rl.X * 0.5, 20, 52), Vector3.new(rl.X, 8, 0), 48, 0, "Cut")
					shot(Vector3.new(rl.X * 0.75, 14, 30), Vector3.new(rl.X, 9, 0), 30, 1.8, "Quad")
					local shaker = chosenCup or state.Holder
					local hv1 = revealFrame * CFrame.new(-9, 22, -4) * CFrame.Angles(0, math.pi, -0.35)
					local hv2 = revealFrame * CFrame.new(9, 22, -4) * CFrame.Angles(0, math.pi, 0.35)
					local p1, p2 = hands[1]:GetPivot(), hands[2]:GetPivot()
					for beat = 1, 3 do
						cue("P3Snap", revealFrame.Position, 0.5 + beat * 0.15)
						ring(revealFrame * CFrame.new(0, 0.1, 0), 14 + beat * 10, WHITE, 0.55, 0.2, 6)
						shake(0.15 * beat, 0.3)
						if
							not animate(0.6, function(a)
								local e = beat == 1 and ease(math.min(a * 1.6, 1)) or 1
								local jitter = math.sin(a * 40) * 0.15 * beat
								hands[1]:PivotTo(p1:Lerp(hv1, e) * CFrame.new(0, jitter, 0))
								hands[2]:PivotTo(p2:Lerp(hv2, e) * CFrame.new(0, -jitter, 0))
								shaker.Model:PivotTo(
									shaker.Frame * CFrame.new(math.sin(a * 60) * 0.25 * beat * (1 - a), 0, 0)
								)
							end)
						then
							return false
						end
					end
					shaker.Model:PivotTo(shaker.Frame)

					end

					state.Stage = "Reveal"
					local correct = chosen ~= nil and chosen == state.Holder.Slot
					send(
						"Reveal",
						{
							Position = revealFrame.Position,
							Choice = chosen,
							Correct = correct,
							Duration = 2.8 * timeScale,
						}
					)
					cue("EtherealReveal", revealFrame.Position, 1)
					if chosen then
					shot(Vector3.new(rl.X * 0.8, 10, 26), Vector3.new(rl.X, 10, 0), 42, 1.4, "Back")
					local r1, r2 = hands[1]:GetPivot(), hands[2]:GetPivot()
					local revealed
					if
						not animate(1.4, function(t)
							for _, cup in ipairs(state.Cups) do
								local a = cup == chosenCup and t or math.clamp((t - 0.35) / 0.65, 0, 1)
								cup.Model:PivotTo(cup.Frame * CFrame.new(0, 16 * outBack(a), 0))
								if cup == state.Holder and a > 0.18 and pupil then
									setVisible(pupil.Character, true)
									if not revealed then
										revealed = pupilHighlight(correct and GREEN or RED)
									end
								end
							end
							homeHands(r1, r2, ease(t))
							syncLamps()
						end)
					then
						return false
					end
					else
						 
						shot(Vector3.new(0, 25, 65), Vector3.new(0, 10, 0), 58, 0, "Cut")
						for _, cup in ipairs(state.Cups) do
							cup.Model:PivotTo(cup.Frame * CFrame.new(0, 16, 0))
						end
						if pupil then setVisible(pupil.Character, true) end
						pupilHighlight(RED)
						syncLamps()
					end
					for _, lamp in ipairs(lights) do
						lamp.Light.Brightness = 6
					end
					local holderPos = state.Holder.Frame.Position
					if correct and pupilAlive() then
						state.Wins += 1
						state.Mood = "Win"
						cue("PupilCorrect", revealFrame.Position, 1)
						cue("PupilFirework", holderPos, 1)
						fireworks(holderPos)
						for _, player in ipairs(Players:GetPlayers()) do
							if player.Character then
         Status.CleanseDebuffs(player.Character, actor)
         Status.GrantCupReward(player.Character)
        end
						end
						Encounter.Say(Dialogue.Correct, nil, { Duration = 3 })
						burst(holderPos + Vector3.new(0, 4, 0), GREEN, 1.4)
						confetti(holderPos + Vector3.new(0, 6, 0), 120, 40, 70)
						ring(state.Holder.Frame * CFrame.new(0, 0.3, 0), 60, GREEN, 0.9, 0.35, 6)
						ring(state.Holder.Frame * CFrame.new(0, 0.3, 0), 95, PALE, 1.2, 0.2, 6)
						pillar(holderPos, GREEN, 70, 1.2)
						flash(GREEN, 0.5, 0.25)
						shake(0.35, 0.4)
						regrade({ Brightness = 0.08, Saturation = 0.3, TintColor = Color3.fromRGB(235, 255, 235) }, 0.2)
					else
						correct = false
						state.Mood = "Lose"
						cue("PupilIncorrect", revealFrame.Position, 1)
						Encounter.Say(chosen and Dialogue.Wrong or (tied and Dialogue.Tie or Dialogue.Timeout), nil, { Duration = 3 })
						state.Penalties = HealthPenalty.ApplyRound(livePlayers(), pupil and pupil.Player)
						state.LastPenalty = state.Penalties
      state.DebuffPenalties = {}
      for _, player in ipairs(livePlayers()) do
       if player.Character then
        state.DebuffPenalties[player.UserId] = Status.ApplyCupPenalty(player.Character, actor, random)
       end
      end
						for _, penalty in ipairs(state.Penalties) do
							local player = Players:GetPlayerByUserId(penalty.UserId)
							local r = player
								and player.Character
								and player.Character:FindFirstChild("HumanoidRootPart")
							if r then
								remote:FireClient(
									player,
									"PlayerDamage",
									{ Position = r.Position, Damage = penalty.HealthLost }
								)
							end
						end
						burst(holderPos + Vector3.new(0, 4, 0), RED, 1.4)
						ring(state.Holder.Frame * CFrame.new(0, 0.3, 0), 70, RED, 0.8, 0.4, 6)
						ring(state.Holder.Frame * CFrame.new(0, 0.3, 0), 110, DARK, 1.1, 0.2, 6)
						pillar(holderPos, RED, 70, 1.2)
						flash(RED, 0.5, 0.4)
						shake(0.9, 0.6)
						regrade(
							{ Brightness = -0.05, Saturation = -0.35, TintColor = Color3.fromRGB(255, 190, 190) },
							0.2
						)
						for _, lamp in ipairs(lights) do
							lamp.Light.Color = RED
						end
						task.delay(0.8 * timeScale, function()
							for _, lamp in ipairs(lights) do
								if lamp.Light.Parent then
									lamp.Light.Color = WHITE
								end
							end
						end)
					end
					state.LastCorrect = correct
					state.RoundsCompleted += 1
					table.insert(
						state.Results,
						{ Round = state.Attempt, Mode = state.Mode, Correct = correct, Penalties = state.Penalties }
					)
					actor:SetAttribute("PickThePupilsRoundsCompleted", state.RoundsCompleted)
					actor:SetAttribute("PickThePupilsRoundsWon", state.Wins)
					send(
						"Result",
						{
							Correct = correct,
							Choice = chosen,
							CorrectSlot = state.Holder.Slot,
							Penalties = state.Penalties,
							Duration = 2.3 * timeScale,
						}
					)
					if not animate(2.3) then
						return false
					end
					state.Mood, state.Focus = nil, nil
					regrade(BASE_GRADE, 0.8)
					if #livePlayers() == 0 then
						return false
					end
					if state.Attempt < TOTAL_ROUNDS and not pupilAlive() then
						if not selectPupil() then
							return false
						end
						send("Replacement", { Duration = 1.5 * timeScale })
						if not animate(1.5) then
							return false
						end
					end
				end
				if state.RoundsCompleted >= TOTAL_ROUNDS then
					state.Stage = "Escape"
					state.Mood = "Win"
					send("Escape", { Duration = 2 * timeScale })
					letterbox(true)
					flash(WHITE, 0.7, 0.5)
					shake(0.6, 0.7)
					shot(Vector3.new(0, 46, 100), Vector3.new(0, 16, -6), 70, 2, "Sine")
					cue("EtherealFinale", center, 0.8)
					if pupilAlive() then
						burst(pupil.Root.Position, PALE, 1.6)
						pillar(pupil.Root.Position - Vector3.new(0, 3, 0), PALE, 100, 1.6)
					end
					releasePupil()
					local e1, e2 = hands[1]:GetPivot(), hands[2]:GetPivot()
					local bow1 = frame * CFrame.new(-30, 14, -12) * CFrame.Angles(0, math.pi, -0.5)
					local bow2 = frame * CFrame.new(30, 14, -12) * CFrame.Angles(0, math.pi, 0.5)
					local fired = 0
					animate(2, function(a)
						root.CFrame = sky:Lerp(base, ease(a))
						hands[1]:PivotTo(e1:Lerp(bow1, ease(a)))
						hands[2]:PivotTo(e2:Lerp(bow2, ease(a)))
						aura.Rate = 160 * (1 - a)
						auraLight.Range, auraLight.Brightness = 40 * (1 - a), 3 * (1 - a)
						if fired <= 4 and a >= fired * 0.25 then
							fired += 1
							local x, z = random:NextNumber(-45, 45), random:NextNumber(-35, 25)
							confetti((frame * CFrame.new(x, 6, z)).Position, 80, 55, 55)
							ring(
								frame * CFrame.new(x, 0.3, z),
								36,
								CONFETTI[random:NextInteger(1, #CONFETTI)],
								0.8,
								0.2,
								4
							)
						end
					end)
					return true
				end
				return false
			end, debug.traceback)
			api.LastResult = {
				Wins = state.Wins,
				Attempts = state.Attempt,
				Rounds = state.RoundsCompleted,
				Results = state.Results,
				Completed = success and result == true,
				LastPenalty = state.LastPenalty,
			}
			cast:Dispose()
			if not success then
				error(result)
			end
			return result
		end)
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
	end
	return api
end
