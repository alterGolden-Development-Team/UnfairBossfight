local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
	local NAME = "P3EtherealAcumen(Ultimate)"
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Dash = require(BossSystem.Players.R6DashService)
	local Cards = require(BossSystem.Mechanics.Clones.CloneController)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Players = game:GetService("Players")
	local Run = game:GetService("RunService")
	local Locomotion = require(BossSystem.Boss.BossLocomotion)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local remote = game.ReplicatedStorage.BossCombatEffects
	local core = Registry.For(actor, "P1CombatCore")
	local api = { Cooldown = Config.EtherealAcumenCooldown or 75, ManagesCooldown = true }
	local current
	local random = Random.new()
	local GOLD, WHITE = Style.GOLD, Style.WHITE
	local AMBER, PALE = Style.AMBER, Style.PALE
	local SPARKLE = Style.SPARKLE
	local NSK = NumberSequenceKeypoint.new
	 
	local CUE = {
		Launch = "EtherealLaunch",
		Charge = "EtherealCharge",
		Reveal = "EtherealReveal",
		Capture = "EtherealCapture",
		Finale = "EtherealFinale",
		Firework = "EtherealFirework",
	}
	 
	local FIREWORK_COLORS = {
		{ GOLD, WHITE },
		{ AMBER, PALE },
		{ Color3.fromRGB(255, 90, 150), WHITE },
		{ Color3.fromRGB(90, 220, 255), WHITE },
		{ Color3.fromRGB(170, 120, 255), PALE },
		{ Color3.fromRGB(120, 255, 160), WHITE },
	}
	local DETAIL = math.clamp(Config.EtherealAcumenVfxDetail or 1, 0.5, 1.5)  
	local LETTERBOX = Config.EtherealAcumenLetterbox ~= false
	local GIMBAL_RATES = { { 0.5, 0.3, 0.1 }, { 0.15, 0.6, 0.35 }, { 0.4, 0.1, 0.7 } }
	local seg = Visuals.seg({
		DETAIL = DETAIL,
	})

	function api.CanUse(target)
		return math.floor(actor:GetAttribute("Phase") or 1) == 3 and core.Active() and core.Alive(target) and not current
			and Cooldowns.Ready(actor, NAME)
	end
	function api.Contains(point)
		local bounds = Placement.GetBounds()
		if not bounds or not Placement.Contains(point, 3) then
			return false
		end
		local p = bounds.Frame:PointToObjectSpace(point)
		local fraction = math.clamp(Config.EtherealAcumenRadiusFraction or 1.05, 0.95, 1.1)
		return (p.X / (bounds.HalfX * fraction)) ^ 2 + (p.Z / (bounds.HalfZ * fraction)) ^ 2 <= 1
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local ownedCast
		local ok, result = xpcall(core.Perform, debug.traceback, target, "P3EtherealAcumen(Ultimate)", function()
			local root = core.Root
			local base = root.CFrame
			local lastOwnedFrame = base
			local bounds = Placement.GetBounds()
			if not bounds then
				return false
			end
			local center = Placement.GroundPoint(bounds.Frame.Position, { Margin = 8, Clamp = true })
			if not center then
				return false
			end
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local riseTime = math.clamp(Config.EtherealAcumenRiseDuration or 0.9, 0.5, 1.5)
			local charge = math.clamp(Config.EtherealAcumenWindup or 3.5, 3.5, 5)
			local duration = math.clamp(Config.EtherealAcumenDuration or 15, 15, 20)
			local rise = math.clamp(Config.EtherealAcumenRiseHeight or 52, 40, 80)
			local dimension = math.clamp(Config.EtherealAcumenTesseractSize or 64, 48, 90)
			local orbitHeight = math.clamp(Config.EtherealAcumenOrbitHeight or 28, 18, rise - 8)
			 
			local arenaOrbitLimit = math.min(bounds.HalfX - 10, bounds.HalfZ - 10)
			local outsideRadius = dimension * 0.5 * math.sqrt(2) + 3
			local orbitRadius =
				math.min(arenaOrbitLimit, math.max(Config.EtherealAcumenOrbitRadius or 46, outsideRadius))
			if orbitRadius < outsideRadius then
				return false
			end
			local pullSpeed = math.clamp(Config.EtherealAcumenPullMaxSpeed or 140, 24, 200)
			local bobHeight = math.clamp(Config.EtherealAcumenOrbitBobHeight or 10, 0, 12)
			local bobSpeed = math.clamp(Config.EtherealAcumenOrbitBobSpeed or 3.2, 0.5, 5)
			 
			local bobVelocity = bobHeight * bobSpeed
			local orbitSpeed = math.min(
				math.clamp(Config.EtherealAcumenOrbitSpeed or 2.2, 0.35, 3.5),
				math.sqrt(math.max((pullSpeed * 0.8) ^ 2 - bobVelocity ^ 2, 0)) / orbitRadius
			)
			local rotationSpeed = math.clamp(Config.EtherealAcumenRotationSpeed or 1.2, 0.4, 3)
			local viewDistance = math.clamp(Config.EtherealAcumenViewDistance or 2.7, 2.4, 5)  
			local interval = math.clamp(Config.EtherealAcumenCardInterval or 1, 1, 2)
			local flight = math.clamp(Config.EtherealAcumenCardFlightDuration or 0.8, 0.6, 0.85)
			local fallTime = 0.7  
			local outro = Config.EtherealAcumenOutroLine  
			if outro == nil then
				outro = "Class is dismissed."
			end
			local sky = CFrame.new(center + Vector3.new(0, rise, 0)) * base.Rotation
			local cubeAt = riseTime + charge
			local cast = Effects.NewCast(actor, "EtherealAcumenSkyCube", cubeAt + duration + 0.5)
			current = cast
			Cooldowns.Start(actor, NAME, api.Cooldown)
			ownedCast = cast
			api.LastCast = cast
			local token = "Ethereal:" .. tostring(generation) .. ":" .. tostring(cast.realBorn)
			local endsAt = workspace:GetServerTimeNow() + cubeAt + duration
			local captures, order = {}, {}
			api.Captures = captures
			local started = cast:Now()
			local natural = false
			local cube, cubeLease
			local chargeSaid = false
			local scan = 0
			local cubePoints, hypercubeVertices, depthW = {}, {}, {}

			 
			local heart, heartAttachment, heartLight
			local chargeAura, chargePull, column, halo
			local beams, gimbals, bossFx = {}, {}, {}
			local kick = 0
			local AXIS = { GOLD, WHITE, PALE, AMBER }

			 
			local screen = Visuals.screen({
				token = token,
				remote = remote,
			})
			local screenTo = Visuals.screenTo({
				Players = Players,
				token = token,
				remote = remote,
			})
			local sfx = Visuals.sfx({
				Audio = Audio,
				actor = actor,
			})

			 
			local ring = Visuals.ring({
				core = core,
				cast = cast,
				Effects = Effects,
			})
			 
			local dome = Visuals.dome({
				core = core,
				cast = cast,
				Effects = Effects,
			})
			 
			local pillar = Visuals.pillar({
				core = core,
				cast = cast,
				Effects = Effects,
			})
			local sparkle = Visuals.sparkle({
				SPARKLE = SPARKLE,
				GOLD = GOLD,
				WHITE = WHITE,
				NSK = NSK,
			})
			 
			 
			local burst = Visuals.burst({
				core = core,
				GOLD = GOLD,
				cast = cast,
				sparkle = sparkle,
				Effects = Effects,
			})
			local solid = Visuals.solid({
				cast = cast,
				core = core,
			})
			 
			local loop = Visuals.loop({})
			 
			local star = Visuals.star({})
			 
			local ticks = Visuals.ticks({})

			local projectCube = Visuals.projectCube({
				rotationSpeed = rotationSpeed,
				hypercubeVertices = hypercubeVertices,
				depthW = depthW,
				viewDistance = viewDistance,
				dimension = dimension,
				cubePoints = cubePoints,
			})
			local function hasLivingPlayers()
				for _, player in ipairs(Players:GetPlayers()) do
					if core.Alive(player.Character) and not Encounter.IsDefeated(player) then return true end
				end
				return false
			end
			local function valid()
				return cast:Alive()
					and not actor:GetAttribute("EncounterEnded")
					and not actor:GetAttribute("PhaseTransitionInProgress")
					and hasLivingPlayers()
					and math.floor(actor:GetAttribute("Phase") or 1) == 3
					and core.Active()
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
			end
			local function release(character, finished)
				local state = captures[character]
				if not state then
					return
				end
				captures[character] = nil
				Status.ReleaseRestraint(character, cast)
				if character.Parent and character:GetAttribute("EtherealOrbitToken") == token then
					character:SetAttribute("EtherealOrbitActive", false)
					character:SetAttribute("EtherealOrbitToken", nil)
				end
				if state.Player.Parent == Players then
					remote:FireClient(state.Player, "EtherealOrbitEnd", { Token = token })
				end
				state.Constraint:Destroy()
				state.Attachment:Destroy()  
				 
				for _, item in ipairs(state.Extras) do
					item:Destroy()
				end
				local sameCharacter = state.Player.Character == character and character.Parent and core.Alive(character)
				if sameCharacter and state.Root.Parent and not state.Root.Anchored then
					local goal
					if finished then
						goal = Placement.Random(
							character,
							random,
							{ Margin = Config.EtherealAcumenReturnMargin or 12, MinDistance = 8, Attempts = 40 }
						)
					end
					goal = goal
						or Placement.Validate(character, state.Origin, { Margin = 8 })
						or Placement.Random(character, random, { Margin = 12, Attempts = 40 })
					if goal then
						state.Root.CFrame = finished and goal + Vector3.new(0, 6, 0) or goal
						state.Root.AssemblyLinearVelocity = finished and Vector3.new(0, -8, 0) or Vector3.zero
						state.Root.AssemblyAngularVelocity = Vector3.zero
						state.ReturnFrame = goal
						state.ReleaseKind = finished and "RandomDrop" or "Cancelled"
						if finished then  
							ring(goal.Position, GOLD, 2, 18, 0.45, 0.3, true)
							burst(goal.Position, 36, ColorSequence.new(GOLD, WHITE), 26, 0.7, 1.4, true)
							pillar(goal.Position - Vector3.new(0, 3, 0), 30, 4, 0.5, WHITE, true)
						end
					end
				end

				if sameCharacter and state.Root.Parent and not state.Root.Anchored and state.TookOwnership then
					pcall(function()
						if state.Player.Character == character and state.Player.Parent == Players then
       state.Root:SetNetworkOwner(state.Player)
      elseif state.Automatic or state.PriorOwner and state.PriorOwner.Parent ~= Players then
							state.Root:SetNetworkOwnershipAuto()
						else
							state.Root:SetNetworkOwner(state.PriorOwner)
						end
					end)
				end

			end
			cast.OnDispose = function()
				local ownsCast = current == cast
				if ownsCast then
					Cooldowns.Start(actor, NAME, api.Cooldown)
					actor:SetAttribute("EtherealAcumenReadyAt", workspace:GetServerTimeNow() + api.Cooldown)
					current = nil
					core.AirborneFloor = nil
				end
				 
				local samePhase = (actor:GetAttribute("PhaseGeneration") or 0) == generation
				local sameMovement = (actor:GetAttribute("MovementRevision") or 0) == revision
				local stillAtCastPosition = root.Parent and (root.Position - lastOwnedFrame.Position).Magnitude < 0.1
				if ownsCast and samePhase and not actor:GetAttribute("PhaseTransitionInProgress") then
					if root.Parent and (sameMovement or stillAtCastPosition) then
						root.CFrame = base
						root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
					end
					Locomotion.Idle(actor, 0.18)
				end
				if actor:GetAttribute("EtherealAcumenToken") == token then
					actor:SetAttribute("EtherealAcumenActive", false)
					actor:SetAttribute("EtherealAcumenChargeActive", false)
					actor:SetAttribute("EtherealAcumenEndsAt", 0)
					actor:SetAttribute("EtherealAcumenToken", nil)
				end
				remote:FireAllClients("EtherealAcumenEnd", { Token = token, Owner = actor, EndsAt = 0 })
				screen("Reset", { Time = natural and 1.2 or 0.4 })
				local pending = {}
				for character in pairs(captures) do table.insert(pending, character) end
				for _, character in ipairs(pending) do
					local released, err = xpcall(release, debug.traceback, character, natural)
					if not released then warn("Ethereal Acumen player release: " .. tostring(err)) end
				end
				for _, item in ipairs(bossFx) do item:Destroy() end
				if natural then
					ring(sky.Position, WHITE, 6, 260, 0.7, 1.2, true)
					dome(sky.Position, WHITE, dimension * 0.8, dimension * 3.2, 0.6, true)
					burst(sky.Position, 160, ColorSequence.new(GOLD, WHITE), 70, 1.2, 2.2, true)
					screen("Shake", { Intensity = 1.2, Duration = 0.9, Origin = sky.Position, Radius = 500 })
				end
			end
			actor:SetAttribute("EtherealAcumenActive", true)
			actor:SetAttribute("EtherealAcumenChargeActive", true)
			actor:SetAttribute("EtherealAcumenEndsAt", endsAt)
			actor:SetAttribute("EtherealAcumenToken", token)
			actor:SetAttribute("EtherealAcumenCardCount", 0)
			actor:SetAttribute("EtherealAcumenCardBaseDamage", Config.EtherealAcumenDamage or 8)
			actor:SetAttribute("EtherealAcumenOrbitRadius", orbitRadius)
			actor:SetAttribute("EtherealAcumenOrbitBobHeight", bobHeight)
			actor:SetAttribute("AttackState", "Ethereal Acumen: sky ascent")
			core.AirborneFloor = base.Y
			core.PoseAngles(
				{ RightShoulder = { 135, 0, -35 }, LeftShoulder = { 135, 0, 35 }, Waist = { -8, 0, 0 } },
				0.2
			)

			 
			local groundCF = CFrame.new(center + Vector3.new(0, 0.3, 0))
			local sigilOuter = solid("EtherealSigilOuter", groundCF, Vector3.one * 0.2, GOLD, 1)
			local sigilInner = solid("EtherealSigilInner", groundCF, Vector3.one * 0.2, WHITE, 1)
			local sigilAngle = 0
			local embers = solid(
				"EtherealEmbers",
				CFrame.new(center + Vector3.new(0, 0.6, 0)),
				Vector3.new(orbitRadius * 1.9, 0.2, orbitRadius * 1.9),
				GOLD,
				1
			)
			local emberEmitter = sparkle(embers, 30, NumberRange.new(1.4, 2.2), NumberRange.new(5, 10), 1.3)
			emberEmitter.Shape = Enum.ParticleEmitterShape.Disc
			emberEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			emberEmitter.EmissionDirection = Enum.NormalId.Top
			emberEmitter.Acceleration = Vector3.new(0, 6, 0)
			emberEmitter.Drag = 1
			emberEmitter.Rotation = NumberRange.new(0, 360)
			emberEmitter.RotSpeed = NumberRange.new(-90, 90)
			do  
				local function own(item)
					table.insert(bossFx, item)
					return item
				end
				local top = own(Instance.new("Attachment"))
				top.Name = "EtherealTrailTop"
				top.Position = Vector3.new(0, 2.6, 0)
				top.Parent = root
				local low = own(Instance.new("Attachment"))
				low.Name = "EtherealTrailLow"
				low.Position = Vector3.new(0, -2.6, 0)
				low.Parent = root
				local ascent = own(Instance.new("Trail"))
				ascent.Name = "EtherealAscentTrail"
				ascent.Attachment0 = top
				ascent.Attachment1 = low
				ascent.Lifetime = 0.7
				ascent.LightEmission = 1
				ascent.FaceCamera = true
				ascent.Color = ColorSequence.new(GOLD, WHITE)
				ascent.Transparency = NumberSequence.new({ NSK(0, 0.15), NSK(1, 1) })
				ascent.WidthScale = NumberSequence.new({ NSK(0, 1.6), NSK(1, 0) })
				ascent.Parent = root
				local shed = own(
					sparkle(
						root,
						45,
						NumberRange.new(0.6, 1),
						NumberRange.new(2, 8),
						1.8,
						ColorSequence.new(GOLD, WHITE)
					)
				)
				shed.SpreadAngle = Vector2.new(180, 180)
				shed.Acceleration = Vector3.new(0, -4, 0)
				local model = actor:IsA("Model") and actor or root.Parent
				if model and model:IsA("Model") then
					local aura = own(Instance.new("Highlight"))
					aura.Name = "EtherealAura"
					aura.Adornee = model
					aura.FillColor = GOLD
					aura.OutlineColor = WHITE
					aura.FillTransparency = 1
					aura.OutlineTransparency = 1
					aura.DepthMode = Enum.HighlightDepthMode.Occluded
					aura.Parent = model
					Effects:Create(
						aura,
						TweenInfo.new(riseTime + charge, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ FillTransparency = 0.55, OutlineTransparency = 0 }
					):Play()
				end
			end
			screen("Grade", { State = "Charge", Time = riseTime + charge })
			if LETTERBOX then
				screen("Letterbox", { On = true })
			end
			screen("Shake", { Intensity = 0.55, Duration = 0.5, Origin = base.Position, Radius = 260 })
			screen("Punch", { Amount = 7, Duration = 0.4 })
			sfx(CUE.Launch, base.Position)
			ring(base.Position - Vector3.new(0, 3, 0), GOLD, 4, 40, 0.6, 0.6)  
			ring(base.Position - Vector3.new(0, 3, 0), WHITE, 2, 26, 0.45, 0.4)
			pillar(base.Position - Vector3.new(0, 3, 0), rise + 10, 7, riseTime + 0.4, WHITE)
			burst(base.Position - Vector3.new(0, 2.5, 0), 50, ColorSequence.new(GOLD, WHITE), 34, 0.9, 1.6)
			 
			cast:Schedule(0.12, function()
				if not valid() then
					return
				end
				star(sigilInner, orbitRadius * 0.5, 6, 2, WHITE, 0.5)
				loop(sigilInner, orbitRadius * 0.5, seg(40), WHITE, 0.4, "Y")
				ring(center + Vector3.new(0, 0.3, 0), WHITE, 2, orbitRadius * 1.1, 0.5, 0.4)
			end)
			cast:Schedule(0.4, function()
				if not valid() then
					return
				end
				star(sigilOuter, orbitRadius * 0.85, 8, 3, GOLD, 0.45)
				loop(sigilOuter, orbitRadius * 0.85, seg(48), GOLD, 0.4, "Y")
				ring(center + Vector3.new(0, 0.3, 0), GOLD, 2, orbitRadius * 1.5, 0.5, 0.4)
			end)
			cast:Schedule(0.7, function()
				if not valid() then
					return
				end
				loop(sigilOuter, orbitRadius * 1.1, seg(60), GOLD, 0.7, "Y")
				ticks(sigilOuter, orbitRadius * 1.1, orbitRadius * 1.17, 24, GOLD, 0.5)
				ring(center + Vector3.new(0, 0.3, 0), WHITE, 2, orbitRadius * 2.2, 0.6, 0.5)
			end)

			local function makeCube()
				cube, cubeLease, heart, heartAttachment, heartLight, halo = require(script.Cube).Create({
					cast = cast,
					core = core,
					sky = sky,
					GOLD = GOLD,
					Effects = Effects,
					chargePull = chargePull,
					chargeAura = chargeAura,
					cubePoints = cubePoints,
					hypercubeVertices = hypercubeVertices,
					SPARKLE = SPARKLE,
					WHITE = WHITE,
					NSK = NSK,
					projectCube = projectCube,
					AXIS = AXIS,
					beams = beams,
					ring = ring,
					dimension = dimension,
					center = center,
					orbitRadius = orbitRadius,
					dome = dome,
					burst = burst,
					actor = actor,
					remote = remote,
					token = token,
					endsAt = endsAt,
					duration = duration,
					solid = solid,
					loop = loop,
					seg = seg,
					gimbals = gimbals,
					orbitHeight = orbitHeight,
					sparkle = sparkle,
					rise = rise,
					PALE = PALE,
					emberEmitter = emberEmitter,
					screen = screen,
					LETTERBOX = LETTERBOX,
					sfx = sfx,
					CUE = CUE,
				})
			end

			local cardIndex = 0
			 
			local fireworkBurst = Visuals.fireworkBurst({
				core = core,
				sparkle = sparkle,
				NSK = NSK,
				WHITE = WHITE,
				Effects = Effects,
			})
			 
			local fireworkShell = Visuals.fireworkShell({
				cast = cast,
				core = core,
				NSK = NSK,
				sparkle = sparkle,
				WHITE = WHITE,
				Effects = Effects,
				ring = ring,
				dome = dome,
				fireworkBurst = fireworkBurst,
				sfx = sfx,
				CUE = CUE,
			})
			local firework = Visuals.firework({
				FIREWORK_COLORS = FIREWORK_COLORS,
				fireworkBurst = fireworkBurst,
				ring = ring,
				random = random,
				fireworkShell = fireworkShell,
			})
			local cardImpact = Visuals.cardImpact({
				WHITE = WHITE,
				GOLD = GOLD,
				cast = cast,
				core = core,
				Effects = Effects,
				burst = burst,
				Audio = Audio,
				actor = actor,
				firework = firework,
			})
			local function fireCard(recipient)
				if not valid() or not cube then
					return
				end
				cardIndex += 1
				actor:SetAttribute("EtherealAcumenCardCount", cardIndex)
				local card = Cards.Card(cast, cardIndex)
				card.Name = "EtherealCenterShotCard"
				card.Size = Config.EtherealAcumenCardSize or Vector3.new(5, 7, 0.12)
				local shotIndex = cardIndex
    local debuffKey={}
				card.Color = shotIndex % 2 == 0 and WHITE or GOLD
				 
				card.Material = Enum.Material.Neon
				local fx = {}
				local cl = Instance.new("PointLight")
				cl.Color = card.Color
				cl.Range = 14
				cl.Brightness = 2
				cl.Parent = card
				table.insert(fx, cl)
				local t0, t1 = Instance.new("Attachment"), Instance.new("Attachment")
				t0.Position = Vector3.new(0, 3.5, 0)
				t1.Position = Vector3.new(0, -3.5, 0)
				t0.Parent = card
				t1.Parent = card
				table.insert(fx, t0)
				table.insert(fx, t1)
				local ribbon = Instance.new("Trail")
				ribbon.Attachment0 = t0
				ribbon.Attachment1 = t1
				ribbon.Lifetime = 0.45
				ribbon.LightEmission = 1
				ribbon.FaceCamera = true
				ribbon.Color = ColorSequence.new(card.Color, WHITE)
				ribbon.Transparency = NumberSequence.new({ NSK(0, 0.2), NSK(1, 1) })
				ribbon.Parent = card
				table.insert(fx, ribbon)
				local head = sparkle(
					card,
					50,
					NumberRange.new(0.25, 0.4),
					NumberRange.new(0, 3),
					1.6,
					ColorSequence.new(card.Color, WHITE)
				)
				table.insert(fx, head)
				local function strip()
					for _, i in ipairs(fx) do
						i:Destroy()
					end
				end
				card:SetAttribute("HomingPath", shotIndex % 3 == 0 and "Orbit" or "Curve")
				local origin = sky.Position
				card.CFrame = CFrame.new(origin)
				 
				kick = 1
				burst(origin, 22, ColorSequence.new(card.Color, WHITE), 32, 0.5, 1.4)
				ring(origin, card.Color, 3, 20, 0.3, 0.4)
				local locked = recipient and captures[recipient]
				if locked and heartAttachment and locked.Attachment.Parent then
					local lock = Instance.new("Beam")
					lock.Name = "EtherealLockOn"
					lock.Attachment0 = heartAttachment
					lock.Attachment1 = locked.Attachment
					lock.Width0 = 2.2
					lock.Width1 = 0.15
					lock.Segments = 1
					lock.FaceCamera = true
					lock.LightEmission = 1
					lock.Color = ColorSequence.new(card.Color, WHITE)
					lock.Transparency = NumberSequence.new(0.2)
					lock.Parent = heart
					Effects:Create(
						lock,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Width0 = 0, Width1 = 0 }
					):Play()
					task.delay(0.3, function()
						lock:Destroy()
					end)
				end
				local lease = Effects.LeaseId(card)
				local at = cast:Now()
				local previous = origin
				cast:Step(function(_, now)
					if not valid() or not card.Parent or Effects.LeaseId(card) ~= lease then
						strip()
						return false
					end
					local alpha = math.clamp((now - at) / flight, 0, 1)
					local state = recipient and captures[recipient]
					local goal = state and state.Root.Position or origin + Vector3.new(0, -18, 0)
					local delta = goal - origin
					local direction = delta.Magnitude > 0.01 and delta.Unit or Vector3.new(0, -1, 0)
					local side = Vector3.new(-direction.Z, 0, direction.X)
					side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
					local arc = math.sin(alpha * math.pi)
					local position
					if shotIndex % 3 == 0 then
						local turn = alpha * math.pi * 2 + shotIndex
						local offset = side * math.cos(turn) * 16 + Vector3.yAxis * math.sin(turn) * 12
						position = origin:Lerp(goal, alpha) + offset * arc
					else
						local bend = (shotIndex % 2 == 0 and 1 or -1) * (12 + shotIndex % 4 * 3)
						local control = origin:Lerp(goal, 0.45) + side * bend + Vector3.yAxis * (8 + shotIndex % 3 * 4)
						position = origin * (1 - alpha) ^ 2 + control * (2 * (1 - alpha) * alpha) + goal * alpha ^ 2
					end
					local motion = position - previous
					card.CFrame = CFrame.lookAt(
						position,
						position + (motion.Magnitude > 0.01 and motion.Unit or direction)
					) * CFrame.Angles(0, 0, alpha * math.pi * 3)
					previous = position
					if alpha >= 1 then
						if state and state.Player.Character == recipient and core.Alive(recipient) then
							state.LastCardDamage =
								core.Damage(recipient, Config.EtherealAcumenDamage or 8, "P3EtherealAcumen(Ultimate)")
							cardImpact(goal, shotIndex)
							ring(goal, card.Color, 2, 16, 0.35, 0.3)
							remote:FireClient(state.Player, "EtherealCardHit", { Intensity = 1 })
							screenTo(state.Player, "Shake", { Intensity = 0.5, Duration = 0.3 })
						end
						strip()
						Effects.Release(card)
						return false
					end
					return true
				end)
			end

			local count = math.floor((duration - 0.001) / interval) + 1
			 
			 
			cast:Schedule(cubeAt, function()
				if valid() then
					makeCube()
				end
			end)
			for index = 1, count do
				cast:Schedule(cubeAt + (index - 1) * interval + 0.06, function()
					 
					local recipients = 0
					for _, character in ipairs(order) do
						if captures[character] and core.Alive(character) then
							recipients += 1
							fireCard(character)
						end
					end
					actor:SetAttribute("EtherealAcumenVolleyTargets", recipients)
				end)
			end

			 
			cast:Schedule(cubeAt, function()
				if valid() and column and column.Parent then
					Effects:Create(
						column,
						TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Size = Vector3.new(rise, 14, 14), Transparency = 0.05 }
					):Play()
				end
			end)
			cast:Schedule(cubeAt + 0.14, function()
				if valid() and column and column.Parent then
					Effects:Create(
						column,
						TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{ Size = Vector3.new(rise, 1.6, 1.6), Transparency = 0.5 }
					):Play()
				end
			end)

			 
			cast:Schedule(cubeAt + duration - 1.2, function()
				if not valid() then
					return
				end
				screen("Grade", { State = "Finale", Time = 1 })
				screen("Shake", { Intensity = 1, Duration = 1.1, Origin = sky.Position, Radius = 500, Ramp = true })
				if outro then
					Encounter.Say(outro, nil, { Duration = 1.1 })
				end
			end)
			 
			cast:Schedule(cubeAt + duration - 0.4, function()
				if not valid() then
					return
				end
				ring(sky.Position, WHITE, dimension * 1.4, 2, 0.4, 0.8)
				dome(sky.Position, WHITE, dimension * 1.6, 3, 0.4)
				if column and column.Parent then
					Effects:Create(
						column,
						TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Size = Vector3.new(rise, 22, 22), Transparency = 1 }
					):Play()
				end
				sfx(CUE.Finale, sky.Position)
				screen("Flash", { Strength = 0.85, Duration = 1.1 })
			end)
			 
			local scale = charge / 3.5
			local beats = { { 0, 1.1 }, { 1.1, 0.9 }, { 2, 0.7 }, { 2.7, 0.5 }, { 3.1, 0.4 } }
			for index, beat in ipairs(beats) do
				local at, length = beat[1] * scale, beat[2] * scale
				cast:Schedule(riseTime + at, function()
					if valid() then
						ring(
							center + Vector3.new(0, 0.3, 0),
							index % 2 == 0 and WHITE or GOLD,
							orbitRadius * 2.4,
							4,
							length,
							0.4
						)
					end
				end)
				if index < #beats then
					cast:Schedule(riseTime + at + length, function()
						if valid() then
							screen("Punch", { Amount = 2.2, Duration = 0.18 })
						end
					end)
				end
			end

			cast:Step(function(dt, now)
				if not valid() then
					cast:Dispose()
					return false
				end
				local elapsed = now - started
				local alpha = math.clamp(elapsed / riseTime, 0, 1)
				local cubeTime = elapsed - cubeAt
				local pivot = base:Lerp(sky, alpha * alpha * (3 - 2 * alpha))
				if cubeTime >= 0 then
					 
					local drop = math.clamp((cubeTime - (duration - fallTime)) / fallTime, 0, 1)
					local hover = sky * CFrame.new(0, math.sin(cubeTime * 1.7) * 0.9 * (1 - drop), 0)
					pivot = hover:Lerp(base, drop * drop * (3 - 2 * drop))
				elseif elapsed >= riseTime then
					 
					local k = math.clamp((elapsed - riseTime) / charge, 0, 1) * 0.7
					pivot = sky
						* CFrame.new(
							math.noise(elapsed * 31, 0.5, 0) * 2 * k,
							math.noise(0.5, elapsed * 27, 0) * 2 * k,
							math.noise(elapsed * 23, elapsed * 19, 0.5) * 2 * k
						)
				end
				root.CFrame = pivot
				lastOwnedFrame = pivot
				 
				local spin = 0.25 + math.clamp((elapsed - riseTime) / charge, 0, 1) * 1.2
				if cubeTime >= 0 then
					spin = 0.5
				end
				sigilAngle += dt * spin
				sigilOuter.CFrame = groundCF * CFrame.Angles(0, sigilAngle, 0)
				sigilInner.CFrame = groundCF * CFrame.Angles(0, -sigilAngle * 1.35, 0)
				if elapsed >= riseTime and not chargeSaid then
					chargeSaid = true
					actor:SetAttribute("AttackState", "Ethereal Acumen: 3.5 second charge")
					actor:SetAttribute("EtherealChargeStartedAt", workspace:GetServerTimeNow())
					Encounter.Say("Welcome to my [][][][][]'s perfect ILLUSIONARY world.", nil, { Duration = charge })
					 
					ring(sky.Position, WHITE, 3, 30, 0.5, 0.5)
					screen(
						"Shake",
						{ Intensity = 1, Duration = charge, Origin = sky.Position, Radius = 500, Ramp = true }
					)
					screen("Punch", { Amount = -6, Duration = charge, Ramp = true })
					sfx(CUE.Charge, sky.Position)
					core.PoseAngles(
						{ RightShoulder = { 150, 0, -55 }, LeftShoulder = { 150, 0, 55 }, Waist = { -14, 0, 0 } },
						0.5
					)
					 
					chargeAura =
						cast:Add(core.Part("EtherealChargeAura", CFrame.new(sky.Position), Vector3.one * 34, GOLD, 1))
					chargeAura.Shape = Enum.PartType.Ball
					chargePull = Instance.new("ParticleEmitter")
					chargePull.Texture = SPARKLE
					chargePull.Shape = Enum.ParticleEmitterShape.Sphere
					chargePull.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
					chargePull.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
					chargePull.Rate = 140
					chargePull.Lifetime = NumberRange.new(0.7, 1)
					chargePull.Speed = NumberRange.new(14, 22)
					chargePull.LightEmission = 0.6
					chargePull.Color = ColorSequence.new(GOLD, WHITE)
					chargePull.Size = NumberSequence.new({ NSK(0, 0.9), NSK(1, 0.1) })
					chargePull.Parent = chargeAura
					local chargeLight = Instance.new("PointLight")
					chargeLight.Color = GOLD
					chargeLight.Range = 0
					chargeLight.Brightness = 0
					chargeLight.Parent = chargeAura
					Effects:Create(
						chargeLight,
						TweenInfo.new(charge, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Range = 70, Brightness = 6 }
					):Play()
					 
					column = solid(
						"EtherealColumn",
						CFrame.new(center + Vector3.new(0, rise * 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
						Vector3.new(rise, 0.2, 0.2),
						GOLD,
						0.45,
						Enum.PartType.Cylinder,
						Enum.Material.Neon
					)
					Effects:Create(
						column,
						TweenInfo.new(charge, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Size = Vector3.new(rise, 5, 5) }
					):Play()
					Effects:Create(
						emberEmitter,
						TweenInfo.new(charge, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Rate = 140 }
					):Play()
				end
				if elapsed < cubeAt then
					return true
				end
				if not cube or not cube.Parent or Effects.LeaseId(cube) ~= cubeLease then
					cast:Dispose()
					return false
				end
				cube.CFrame = sky * CFrame.Angles(math.sin(cubeTime * 0.5) * 0.15, cubeTime * 0.18, cubeTime * 0.06)
				projectCube(cubeTime)
				 
				local pop = math.clamp(cubeTime / 0.5, 0, 1)
				pop = 1 - (1 - pop) ^ 3
				local life = math.min(pop, math.clamp((duration - cubeTime) / 0.5, 0, 1))
				for _, e in ipairs(beams) do
					local depth = ((depthW[e.A] + depthW[e.B]) * 0.5 + 2) * 0.25  
					local w = e.Base * life * (0.45 + depth * 1.1) * (1 + 0.3 * math.sin(cubeTime * 7 + e.Phase))
					e.Beam.Width0 = w
					e.Beam.Width1 = w
				end
				kick = math.max(0, kick - dt * 5)
				if heart and heart.Parent then
					heart.Size = Vector3.one * ((4 + math.sin(cubeTime * 5) + kick * 2.5) * life + 0.01)
				end
				if heartLight then
					heartLight.Brightness = 5 + kick * 7
				end
				 
				if halo then
					halo.CFrame = CFrame.new(center + Vector3.new(0, orbitHeight, 0))
						* CFrame.Angles(0, -cubeTime * orbitSpeed, 0)
				end
				for index, g in ipairs(gimbals) do
					local rate = GIMBAL_RATES[index]
					g.CFrame = sky * CFrame.Angles(cubeTime * rate[1], cubeTime * rate[2], cubeTime * rate[3])
				end

				 
				scan += dt
				if scan >= 0.05 then
					scan = 0
					for _, character in ipairs(core.Characters()) do
						local r = character:FindFirstChild("HumanoidRootPart")
						local player = Players:GetPlayerFromCharacter(character)
						if
							core.Alive(character)
							and player
							and player.Character == character
							and not captures[character]
							and r
							and not r.Anchored
							and api.Contains(r.Position)
							and Encounter.CanReceiveHit(character)
							and not Status.IsDebuffImmune(character)
							and not character:GetAttribute("ParryFrozen")
							and Status.Restrain(character, cast, duration + 0.5)
						then
							Dash.Cancel(player, "Ethereal Acumen sky orbit")
							local okAuto, automatic = pcall(function()
								return r:GetNetworkOwnershipAuto()
							end)
							local okOwner, priorOwner = pcall(function()
								return r:GetNetworkOwner()
							end)
							if not okOwner then
								priorOwner = player
							end
							local took = pcall(function()
								r:SetNetworkOwner(nil)
							end)
							local a = Instance.new("Attachment")
							a.Name = "EtherealOrbitAttachment"
							a.Parent = r
							local constraint = Instance.new("AlignPosition")
							constraint.Name = "EtherealPhysicalOrbit"
							constraint.Mode = Enum.PositionAlignmentMode.OneAttachment
							constraint.Attachment0 = a
							constraint.Position = r.Position
							constraint.ApplyAtCenterOfMass = true
							constraint.RigidityEnabled = false
							constraint.MaxVelocity = pullSpeed
							constraint.Responsiveness = 30
							constraint.MaxForce = math.max(r.AssemblyMass, 1) * 2200
							constraint.Parent = r
							 
							if heartAttachment then
								local tether = Instance.new("Beam")
								tether.Name = "EtherealTether"
								tether.Attachment0 = heartAttachment
								tether.Attachment1 = a
								tether.Width0 = 1.4
								tether.Width1 = 0.3
								tether.CurveSize0 = 8
								tether.CurveSize1 = -8
								tether.Segments = 24
								tether.FaceCamera = true
								tether.LightEmission = 1
								tether.Transparency = NumberSequence.new(0.35)
								tether.Color = ColorSequence.new(WHITE, GOLD)
								tether.Parent = a
							end
							local trail = Instance.new("ParticleEmitter")
							trail.Texture = SPARKLE
							trail.Rate = 25
							trail.Lifetime = NumberRange.new(0.6)
							trail.Speed = NumberRange.new(0, 2)
							trail.LightEmission = 1
							trail.Color = ColorSequence.new(GOLD, WHITE)
							trail.Size = NumberSequence.new({ NSK(0, 1.4), NSK(1, 0) })
							trail.Parent = a
							 
							local high = Instance.new("Attachment")
							high.Name = "EtherealStreakHigh"
							high.Position = Vector3.new(0, 2.4, 0)
							high.Parent = r
							local low = Instance.new("Attachment")
							low.Name = "EtherealStreakLow"
							low.Position = Vector3.new(0, -2.4, 0)
							low.Parent = r
							local streak = Instance.new("Trail")
							streak.Name = "EtherealOrbitStreak"
							streak.Attachment0 = high
							streak.Attachment1 = low
							streak.Lifetime = 0.55
							streak.LightEmission = 1
							streak.FaceCamera = true
							streak.Color = ColorSequence.new(WHITE, GOLD)
							streak.Transparency = NumberSequence.new({ NSK(0, 0.25), NSK(1, 1) })
							streak.WidthScale = NumberSequence.new({ NSK(0, 1), NSK(1, 0) })
							streak.Parent = r
							ring(r.Position, WHITE, 2, 14, 0.35, 0.3)  
							pillar(r.Position - Vector3.new(0, 2.5, 0), 34, 4, 0.5, WHITE)
							burst(r.Position, 40, ColorSequence.new(GOLD, WHITE), 30, 0.7, 1.6)
							sfx(CUE.Capture, r.Position)
							screenTo(player, "Flash", { Strength = 0.5, Duration = 0.4 })
							screenTo(player, "Shake", { Intensity = 0.7, Duration = 0.5 })
							local delta = r.Position - center
							captures[character] = {
								Root = r,
								Player = player,
								Constraint = constraint,
								Attachment = a,
								Origin = r.CFrame,
								At = elapsed,
								Angle = math.atan2(delta.Z, delta.X),
								Automatic = not okAuto or automatic,
								PriorOwner = priorOwner,
								TookOwnership = took,
								Extras = { high, low, streak },
							}
							if not table.find(order, character) then
								table.insert(order, character)
							end
							character:SetAttribute("EtherealOrbitActive", true)
							character:SetAttribute("EtherealOrbitToken", token)
							remote:FireClient(player, "EtherealOrbitStart", {
								Token = token,
								Owner = actor,
								EndsAt = endsAt,
								Center = center,
								Height = orbitHeight,
								Radius = orbitRadius,
								Speed = orbitSpeed,
								BobHeight = bobHeight,
								BobSpeed = bobSpeed,
							})
						end
					end
				end
				 
				for character, state in pairs(captures) do
					if
						not core.Alive(character)
						or state.Player.Parent ~= Players
						or state.Player.Character ~= character
						or state.Root.Anchored
						or Status.IsDebuffImmune(character)
						or character:GetAttribute("TimeFrozen")
						or character:GetAttribute("ParryFrozen")
					then
						release(character, false)
					else
						local since = elapsed - state.At
						local theta = state.Angle + since * orbitSpeed
						local height = orbitHeight + math.sin(since * bobSpeed + state.Angle) * bobHeight
						local desired = center
							+ Vector3.new(math.cos(theta) * orbitRadius, height, math.sin(theta) * orbitRadius)
						state.Constraint.Position = state.Origin.Position:Lerp(desired, math.clamp(since / 1.3, 0, 1))
					end
				end
				return true
			end)
			 
			while valid() and cast:Now() - started < cubeAt + duration do
				Run.Heartbeat:Wait()
			end
			if not valid() then
				cast:Dispose()
				return false
			end
			natural = true
			cast:Dispose()
			return true
		end)
		 
		if ownedCast and not ownedCast.closed then ownedCast:Dispose() end
		if not ok then
			warn("Ethereal Acumen failed: " .. tostring(result))
			return false
		end
		return result
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
	end
	return api
end
