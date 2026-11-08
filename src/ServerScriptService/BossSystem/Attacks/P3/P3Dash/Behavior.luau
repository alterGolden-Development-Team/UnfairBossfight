local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Dash = require(BossSystem.Players.R6DashService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Players = game:GetService("Players")
	local Run = game:GetService("RunService")
	local Tween = game:GetService("TweenService")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local api = { Cooldown = Config.P3DashCooldown }
	local current
	local serial = 0

	local GOLD = Style.GOLD
	local WHITE = Style.WHITE
	local STEEL = Style.STEEL
	local DEEP = Style.DEEP
	local GRIP = Style.GRIP
	local GEM = Style.GEM
	local DUST = Style.DUST
	local PANEL = Style.PANEL

	 
	local FX = {
		TrackFraction = Config.P3DashTrackFraction or 0.6,  
		HitStop = Config.P3DashHitStop or 0.07,
		LiftTime = Config.P3DashLiftTime or 0.16,  
		WallStagger = Config.P3DashWallStagger or 0.5,
		PunishWindow = Config.P3DashPunishWindow or 0.6,  
		MultiTargetGrab = Config.P3DashMultiTargetGrab ~= false,  
		SwordDetail = Config.P3DashSwordDetail or 2,  
		BoxWidth = Config.P3DashBoxWidth or 7,  
		BoxHeight = Config.P3DashBoxHeight or 10,
		BoxPush = Config.P3DashBoxPush or 3,  
		BoxCloseTime = Config.P3DashBoxCloseTime or 0.4,
		SwordHover = Config.P3DashSwordHover or 15,  
		SwordGraze = Config.P3DashSwordGraze or 1.5,  
	}
	 
	local SWORD = { Taper = { 0.86, 0.68, 0.5, 0.32, 0.16 }, TaperStep = 0.8, Top = 13.2 }
	SWORD.BladeStart = #SWORD.Taper * SWORD.TaperStep
	local BOX_AWAY = 10  

	local function distance(point, first, last)
		local delta = last - first
		local length = delta:Dot(delta)
		local t = length > 0.001 and math.clamp((point - first):Dot(delta) / length, 0, 1) or 0
		return (point - first - delta * t).Magnitude
	end
	local function canGrab(character)
		if not core.Alive(character) then
			return false
		end
		local player = Players:GetPlayerFromCharacter(character)
		local r = character:FindFirstChild("HumanoidRootPart")
		return player
			and player.Character == character
			and r
			and not r.Anchored
			and not Status.IsMovementLocked(player)
			and not Status.IsStunProtected(character)
			and not character:GetAttribute("ParryFrozen")
			and not character:GetAttribute("CataclysmChained")
			and not character:GetAttribute("P3DashChained")
			and Encounter.CanReceiveHit(character)
	end
	function api.CanUse(character)
		return not current
			and math.floor(actor:GetAttribute("Phase") or 1) == 3
			and not actor:GetAttribute("ExecutionLocked")
			and core.Active()
			and canGrab(character)
	end
	function api.Combo(character, options)
		if not api.CanUse(character) then
			return false
		end
		options = options or {}
		return core.Perform(character, "P3Dash", function()
			local cast = Effects.NewCast(actor, "P3DashExecution", 20)
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local record = { Cast = cast, Target = character }
			local victim = character  
			current = record
			serial += 1
			record.Token = serial
			local function valid(target)
				return not cast.closed
					and core.Active()
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
					and (
						not target
						or core.Alive(target)
							and Players:GetPlayerFromCharacter(target)
							and Players:GetPlayerFromCharacter(target).Character == target
					)
			end

			 
			 
			local function releaseHeld()
				local held = record.Held
				if not held then
					return
				end
				record.Held = nil
				record.DownedFrame = nil
				record.NextPinnedTick = nil
				Encounter.SetDamageGate(held, cast, false)
				Status.ReleaseRestraint(held, cast)
				local player = record.Player
				if player then
					Status.SetLocked(player, cast, false)
				end
				if held.Parent then
					held:SetAttribute("P3DashChained", false)
					if held:GetAttribute("P3DashDownedOwner") == record.Token then
						held:SetAttribute("P3DashDowned", false)
						held:SetAttribute("P3DashDownedOwner", nil)
					end
				end
				local r = record.HeldRoot
				if r and r.Parent then
					local safe = record.SafeReleaseFrame
						and core.Alive(held)
						and Placement.Validate(held, record.SafeReleaseFrame)
					if safe then
						r.CFrame = safe
					end
					Time.SetAnchored(r, record.WasAnchored == true)
					r.AssemblyLinearVelocity = Vector3.zero
					r.AssemblyAngularVelocity = Vector3.zero
				end
				local h = record.HeldHumanoid
				if h and h.Parent and record.DownedSnapshot then
					h.PlatformStand = record.DownedSnapshot.PlatformStand
					h.Sit = record.DownedSnapshot.Sit
					if h.Health > 0 and not h.PlatformStand then
						h:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end
				local animateScript = record.AnimateScript
				if animateScript and animateScript.Parent then
					animateScript.Disabled = record.AnimateDisabled
				end
				if r and r.Parent and not r.Anchored then
					 
					 
					pcall(function()
						if record.AutomaticOwnership then
							r:SetNetworkOwnershipAuto()
						else
							r:SetNetworkOwner(record.NetworkOwner)
						end
					end)
				end
			end
			local function cleanup()
				releaseHeld()
				if actor.Parent and actor:GetAttribute("ExecutionLockToken") == record.Token then
					actor:SetAttribute("ExecutionLocked", false)
					actor:SetAttribute("ExecutionLockToken", nil)
					actor:SetAttribute("P3DashState", "Complete")
				end
				if current == record then
					current = nil
				end
			end
			cast.OnDispose = cleanup

			local part = Visuals.part({
				cast = cast,
				core = core,
				GOLD = GOLD,
			})
			local drop = Visuals.drop({
				Effects = Effects,
			})
			local release = Visuals.release({
				drop = drop,
				cast = cast,
			})
			local function animate(seconds, callback, target)
				local began = cast:Now()
				while valid(target) do
					local t = math.clamp((cast:Now() - began) / math.max(0.001, seconds), 0, 1)
					if callback and callback(t) == false then
						return true
					end
					if t >= 1 then
						return true
					end
					Run.Heartbeat:Wait()
				end
				return false
			end

			 
			 
			local disc = Visuals.disc({
				core = core,
			})
			 
			local pulse = Visuals.pulse({
				disc = disc,
				Effects = Effects,
				drop = drop,
			})
			 
			local fling = Visuals.fling({
				core = core,
				Run = Run,
				drop = drop,
			})
			 
			local sigil = Visuals.sigil({
				core = core,
			})

			 
			 
			 
			local buildBox = Visuals.buildBox({
				part = part,
				BOX_AWAY = BOX_AWAY,
				PANEL = PANEL,
				GOLD = GOLD,
				FX = FX,
				DEEP = DEEP,
				GEM = GEM,
			})
			 
			local placeBox = Visuals.placeBox({})
			local flashEdges = Visuals.flashEdges({
				WHITE = WHITE,
				Effects = Effects,
				GOLD = GOLD,
			})
			 
			local boxExit = Visuals.boxExit({})

			 
			 
			cast:Step(function()
				if not valid(record.Held) then
					cast:Dispose()
					return false
				end
				if record.DownedFrame and record.HeldRoot and record.HeldRoot.Parent then
					 
					 
					record.HeldRoot.CFrame = record.DownedFrame
					record.HeldRoot.AssemblyLinearVelocity = Vector3.zero
					record.HeldRoot.AssemblyAngularVelocity = Vector3.zero
					if record.NextPinnedTick and cast:Now() >= record.NextPinnedTick then
						record.NextPinnedTick = cast:Now() + Config.P3DashPinnedTickInterval
						local amount = Encounter.Damage(record.Held, Config.P3DashPinnedDamage, actor, cast)
						actor:SetAttribute("P3DashPinnedTicks", (actor:GetAttribute("P3DashPinnedTicks") or 0) + 1)
						actor:SetAttribute(
							"P3DashPinnedActualDamage",
							(actor:GetAttribute("P3DashPinnedActualDamage") or 0) + amount
						)
						local box = record.Box
						if box then
							flashEdges(box, 0.25)
							pulse(cast, box.Floor + Vector3.new(0, 0.2, 0), 2, 9, 0.3, GOLD, 0.45)
						end
					end
				end
				return true
			end)

			 
			 
			local buildSword = Visuals.buildSword({
				part = part,
				SWORD = SWORD,
				STEEL = STEEL,
				GOLD = GOLD,
				DEEP = DEEP,
				GEM = GEM,
				GRIP = GRIP,
				FX = FX,
				WHITE = WHITE,
			})
			local placeSwords = Visuals.placeSwords({})
			 
			 
			local function strikeDistance(entry, t)
				local windup = 0.14
				if t < windup then
					return entry.Hover + 2.4 * math.sin(t / windup * math.pi * 0.5)
				end
				local k = ((t - windup) / (1 - windup)) ^ 2.4
				return (entry.Hover + 2.4) * (1 - k)
			end
			 
			 
			local swordDirection = Visuals.swordDirection({})

			 
			 
			local function plan(origin, aim)
				local delta = aim - origin
				local direction = Vector3.new(delta.X, 0, delta.Z)
				if direction.Magnitude < 0.05 then
					direction = Vector3.new(core.Root.CFrame.LookVector.X, 0, core.Root.CFrame.LookVector.Z)
				end
				if direction.Magnitude < 0.001 then
					direction = Vector3.new(0, 0, -1)
				end
				direction = direction.Unit
				local ground =
					Placement.GroundPoint(origin + direction * Config.P3DashDistance, { Clamp = true, Margin = 6 })
				if not ground then
					return nil
				end
				local travel = math.max(0, (Vector3.new(ground.X, origin.Y, ground.Z) - origin):Dot(direction))
				if travel > 0.5 then
					local wall = workspace:Blockcast(
						CFrame.lookAt(origin, origin + direction),
						Vector3.new(3, 4, 3),
						direction * travel,
						core.Params(character)
					)
					if wall then
						travel = math.max(0, wall.Distance - 2)
					end
				end
				local goal = origin + direction * travel
				return direction, goal, ground.Y, travel < Config.P3DashDistance - 1
			end
			 
			local function findGrab(first, last, heading)
				local best, bestAlong
				for _, player in ipairs(Players:GetPlayers()) do
					local candidate = player.Character
					local root = candidate and candidate:FindFirstChild("HumanoidRootPart")
					if
						root
						and (FX.MultiTargetGrab or candidate == character)
						and canGrab(candidate)
						and distance(root.Position, first, last) <= Config.P3DashGrabRadius
					then
						local along = (root.Position - first):Dot(heading)
						if not best or along < bestAlong then
							best, bestAlong = candidate, along
						end
					end
				end
				return best
			end

			local function sequence()
				if options.Pull and (not options.Pull(cast) or not valid(character)) then
					return false
				end
				local startup = options.Instant and 0 or Config.P3DashStartup
				actor:SetAttribute("P3DashSwordsHit", 0)
				actor:SetAttribute("P3DashSwordsSummoned", 0)
				actor:SetAttribute("P3DashActualDamage", 0)
				actor:SetAttribute("P3DashPinnedTicks", 0)
				actor:SetAttribute("P3DashPinnedActualDamage", 0)
				actor:SetAttribute("P3DashState", "Startup")
				core.Face(character)
				core.PoseAngles({
					RightShoulder = { -70, 0, 8 },
					RightElbow = { 8, 0, 0 },
					LeftShoulder = { 35, 0, -20 },
					Waist = { 32, 0, 0 },
					RightHip = { -18, 0, 0 },
				}, 0.1)

				 
				local a0 = Instance.new("Attachment")
				a0.Position = Vector3.new(0, 2.2, 0)
				a0.Parent = core.Root
				local a1 = Instance.new("Attachment")
				a1.Position = Vector3.new(0, -2.2, 0)
				a1.Parent = core.Root
				local trail = Instance.new("Trail")
				trail.Attachment0 = a0
				trail.Attachment1 = a1
				trail.Lifetime = 0.35
				trail.LightEmission = 1
				trail.FaceCamera = true
				trail.Color = ColorSequence.new(WHITE, GOLD)
				trail.Transparency = NumberSequence.new(0.1, 1)
				trail.WidthScale = NumberSequence.new(1, 0.2)
				trail.Enabled = false
				trail.Parent = core.Root
				cast:Add(a0)
				cast:Add(a1)
				cast:Add(trail)

				 
				local hand = actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm")
				local cue = part(
					"P3DashOpenHandCue",
					hand and hand.CFrame or core.Root.CFrame * CFrame.new(1, 1, -2),
					Vector3.one * 1.4,
					WHITE,
					0.18
				)
				cue.Shape = Enum.PartType.Ball
				Effects:Create(cue, TweenInfo.new(startup), { Size = Vector3.one * 2.8, Transparency = 0.04 }):Play()

				 
				local lane = part("P3DashLane", CFrame.new(core.Root.Position), Vector3.new(1, 0.2, 1), GOLD, 1)
				lane.Material = Enum.Material.Neon
				local mark = disc(cast, core.Root.Position, Config.P3DashGrabRadius * 2.6, GOLD, 1)
				local direction, goal, laneY, crashed
				local locked = false
				local function aim()
					local root = character:FindFirstChild("HumanoidRootPart")
					if not root then
						return
					end
					core.Face(character)
					local origin = core.Root.Position
					local d, g, y, c = plan(origin, root.Position)
					if not d then
						return
					end
					direction, goal, laneY, crashed = d, g, y, c
					local from = Vector3.new(origin.X, y + 0.15, origin.Z)
					local to = Vector3.new(g.X, y + 0.15, g.Z)
					local length = (to - from).Magnitude
					if length > 0.5 then
						lane.Size = Vector3.new(Config.P3DashGrabRadius * 2, 0.2, length)
						lane.CFrame = CFrame.lookAt((from + to) / 2, to)
					end
					mark.CFrame = CFrame.new(to) * CFrame.Angles(0, 0, math.pi / 2)
				end
				local aimed = animate(startup, function(t)
					if locked then
						return
					end
					aim()
					if t < FX.TrackFraction then
						lane.Transparency = 0.88 - 0.2 * (t / FX.TrackFraction)
						mark.Transparency = lane.Transparency + 0.05
					else
						locked = true
						lane.Color = WHITE
						lane.Transparency = 0.3
						mark.Transparency = 0.3
						Effects:Create(lane, TweenInfo.new(0.18), { Color = GOLD, Transparency = 0.5 }):Play()
					end
				end, character)
				if not aimed or not direction then
					return false
				end
				release(cue)

				 
				local origin = core.Root.Position
				local previous = origin
				actor:SetAttribute("P3DashState", "Committed dash")
				actor:SetAttribute("P3DashLockedDirection", direction)
				actor:SetAttribute("P3DashStartedAt", workspace:GetServerTimeNow())
				trail.Enabled = true
				core.ScreenEffect("Shake", { Origin = origin, Radius = 80, Duration = 0.25, Intensity = 0.7 })
				local launch = Vector3.new(origin.X, laneY + 0.25, origin.Z)
				pulse(cast, launch, 4, 22, 0.35, WHITE, 0.15)
				fling(cast, launch, 10, DUST, Vector3.new(0.8, 0.8, 0.8), 16, 0.55, 70, 10)

				local caught = false
				local completed = animate(Config.P3DashDuration, function(t)
					if caught then
						return
					end
					local position = origin:Lerp(goal, t)
					core.Root.CFrame = CFrame.lookAt(position, position + direction)
					core.Afterimage(core.Root.CFrame)
					local found = findGrab(previous, position, direction)
					if found and Encounter.SetDamageGate(found, cast, true) then
						local r = found.HumanoidRootPart
						caught = true
						victim = found
						record.Target = found
						record.Held = found
						record.Player = Players:GetPlayerFromCharacter(found)
						record.HeldRoot = r
						record.HeldHumanoid = found:FindFirstChildOfClass("Humanoid")
						record.WasAnchored = r.Anchored
						pcall(function()
							record.NetworkOwner = r:GetNetworkOwner()
							record.AutomaticOwnership = r:GetNetworkOwnershipAuto()
						end)
						actor:SetAttribute("ExecutionLocked", true)
						actor:SetAttribute("ExecutionLockToken", record.Token)
						actor:SetAttribute("P3DashState", "Box closing")
						found:SetAttribute("P3DashChained", true)
						Status.SetLocked(record.Player, cast, true)
						Status.Restrain(found, cast, 15, { AllowDefense = false })
						Dash.Cancel(record.Player, "P3Dash box trap")
						Time.SetAnchored(r, true)
						r.AssemblyLinearVelocity = Vector3.zero
						actor:SetAttribute("P3DashGrabs", (actor:GetAttribute("P3DashGrabs") or 0) + 1)
						 
						local contact = r.Position
						local flash = part("P3DashGrabFlash", CFrame.new(contact), Vector3.one * 2, WHITE, 0.05)
						flash.Shape = Enum.PartType.Ball
						Effects:Create(
							flash,
							TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Size = Vector3.one * 11, Transparency = 1 }
						):Play()
						cast:Schedule(0.35, function()
							release(flash)
						end)
						fling(cast, contact, 8, WHITE, Vector3.new(0.3, 0.3, 0.9), 18, 0.4, 30, 6)
						core.ScreenEffect("Shake", { Origin = contact, Radius = 90, Duration = 0.3, Intensity = 0.9 })
					end
					previous = position
					if caught then
						return false
					end
				end, character)
				trail.Enabled = false
				Effects:Create(lane, TweenInfo.new(0.2), { Transparency = 1 }):Play()
				Effects:Create(mark, TweenInfo.new(0.2), { Transparency = 1 }):Play()
				cast:Schedule(0.25, function()
					release(lane)
					release(mark)
				end)
				if not completed or not valid(victim) then
					return false
				end

				if not caught then
					actor:SetAttribute("P3DashState", "Miss recovery")
					actor:SetAttribute("P3DashMisses", (actor:GetAttribute("P3DashMisses") or 0) + 1)
					local extra = 0
					if crashed then
						 
						extra = FX.WallStagger
						actor:SetAttribute("P3DashState", "Wall crash")
						local impact = Vector3.new(goal.X, laneY + 0.3, goal.Z)
						pulse(cast, impact, 3, 20, 0.4, WHITE, 0.2)
						fling(cast, impact, 12, DUST, Vector3.one, 20, 0.7, 80, 14)
						core.ScreenEffect("Shake", { Origin = impact, Radius = 100, Duration = 0.45, Intensity = 1.1 })
						core.PoseAngles(
							{ Waist = { 25, 0, 0 }, RightShoulder = { 25, 0, 6 }, LeftShoulder = { 25, 0, -6 } },
							0.1
						)
					end
					return animate(Config.P3DashRecovery + extra, nil, character)
				end

				local r = record.HeldRoot
				actor:SetAttribute("P3DashState", "Grab")
				if not animate(FX.HitStop, nil, victim) then
					return false
				end  
				 
				local floor = Placement.GroundPoint(r.Position + direction * FX.BoxPush, { Clamp = true, Margin = 6 })
				if not floor then
					return false
				end
				local toBoss = Vector3.new(-direction.X, 0, -direction.Z)
				local standing = Placement.Validate(victim, CFrame.lookAt(floor, floor + toBoss))
				if not standing then
					return false
				end
				record.SafeReleaseFrame = standing
				local heldStart = r.CFrame
				local h = record.HeldHumanoid
				record.DownedSnapshot = { PlatformStand = h.PlatformStand, Sit = h.Sit }
				record.AnimateScript = victim:FindFirstChild("Animate")
				if record.AnimateScript and record.AnimateScript:IsA("LocalScript") then
					record.AnimateDisabled = record.AnimateScript.Disabled
					record.AnimateScript.Disabled = true
				else
					record.AnimateScript = nil
				end
				local animator = h:FindFirstChildOfClass("Animator")
				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						track:Stop(0.05)
					end
				end
				h.Sit = false
				h.PlatformStand = true
				h:ChangeState(Enum.HumanoidStateType.Physics)
				victim:SetAttribute("P3DashDownedOwner", record.Token)
				victim:SetAttribute("P3DashDowned", true)
				 
				local heldFrame = standing

				actor:SetAttribute("P3DashState", "Lift")
				core.PoseAngles(
					{ RightShoulder = { -150, 0, 8 }, LeftShoulder = { -40, 0, -20 }, Waist = { -12, 0, 0 } },
					0.1
				)
				if
					not animate(FX.LiftTime, function(t)
						local e = 1 - (1 - t) ^ 3
						r.CFrame = heldStart:Lerp(heldFrame, e) + Vector3.new(0, math.sin(e * math.pi) * 1.5, 0)
					end, victim)
				then
					return false
				end
				r.CFrame = heldFrame
				record.DownedFrame = heldFrame

				actor:SetAttribute("P3DashState", "Box closing")
				core.PoseAngles(
					{ RightShoulder = { 65, 0, 10 }, LeftShoulder = { 20, 0, -20 }, Waist = { 30, 0, 0 } },
					0.08
				)
				local center =
					Vector3.new(heldFrame.Position.X, floor.Y + FX.BoxHeight / 2 + 0.25, heldFrame.Position.Z)
				local floorPoint = Vector3.new(center.X, floor.Y, center.Z)
				local box = buildBox(center, toBoss, FX.BoxWidth, FX.BoxHeight)
				record.Box = box
				placeBox(box, 0)
				for _, bit in ipairs(box.Bits) do
					Effects:Create(bit.Part, TweenInfo.new(0.2), { Transparency = bit.Alpha }):Play()
				end
				local sigilBars = sigil(cast, floorPoint, FX.BoxWidth * 0.9, GOLD)
				for _, bar in ipairs(sigilBars) do
					Effects:Create(bar, TweenInfo.new(0.45), { Transparency = 0.35 }):Play()
				end

				local bossFrom = core.Root.CFrame
				local retreat = Placement.GroundPoint(
					bossFrom.Position - direction * Config.P3DashStepBackDistance,
					{ Clamp = true, Margin = 6 }
				)
				local bossGoal = retreat
					and Placement.Validate(
						actor,
						CFrame.lookAt(
							Vector3.new(retreat.X, bossFrom.Y, retreat.Z),
							Vector3.new(r.Position.X, bossFrom.Y, r.Position.Z)
						)
					)
				local stepTime = bossGoal and 0.5 or 0
				local closeTime = math.max(0.05, FX.BoxCloseTime)
				local total = math.max(stepTime, closeTime)
				if
					not animate(total, function(t)
						local elapsed = t * total
						if bossGoal then
							core.Root.CFrame = bossFrom:Lerp(bossGoal, math.clamp(elapsed / stepTime, 0, 1))
						end
						placeBox(box, 1 - (1 - math.clamp(elapsed / closeTime, 0, 1)) ^ 3)
					end, victim)
				then
					return false
				end
				placeBox(box, 1)

				 
				flashEdges(box, 0.35)
				record.NextPinnedTick = cast:Now() + Config.P3DashPinnedTickInterval
				actor:SetAttribute("P3DashPinnedTicks", 0)
				actor:SetAttribute("P3DashPinnedActualDamage", 0)
				pulse(cast, floorPoint + Vector3.new(0, 0.2, 0), 3, 28, 0.45, WHITE, 0.15)
				fling(cast, floorPoint + Vector3.new(0, 0.5, 0), 12, DUST, Vector3.new(0.9, 0.9, 0.9), 16, 0.7, 80, 12)
				fling(cast, center, 8, WHITE, Vector3.one * 0.8, 3, 0.9, -4, 2)
				core.ScreenEffect("Shake", { Origin = floorPoint, Radius = 100, Duration = 0.45, Intensity = 1.1 })

				actor:SetAttribute("P3DashState", "Summoning swords")
				local swords = {}
				 
				local function hoverDistance(entry)
					local age = math.clamp((cast:Now() - entry.Born) / 0.25, 0, 1)
					return entry.Hover + (1 - age) ^ 3 * 10 + math.sin(cast:Now() * 4 + entry.Index * 1.3) * 0.5
				end
				 
				local function aimPoint(dir, index)
					local side = dir:Cross(Vector3.yAxis)
					side = side.Magnitude > 0.2 and side.Unit or Vector3.xAxis
					local y = math.clamp(
						floor.Y + FX.BoxHeight * 0.5 - (dir.Y - 0.5) * FX.BoxHeight * 0.35,
						floor.Y + 1.4,
						floor.Y + FX.BoxHeight - 1.4
					)
					return Vector3.new(center.X, y, center.Z)
						+ side * (index % 2 == 0 and FX.SwordGraze or -FX.SwordGraze)
				end
				local count = Config.P3DashSwordCount
				for index = 1, count do
					if not valid(victim) then
						return false
					end
					local dir = swordDirection(index, count, toBoss)
					local tip = aimPoint(dir, index)
					local up = dir
					 
					local right = Vector3.yAxis:Cross(up)
					right = right.Magnitude > 0.1 and right.Unit or Vector3.xAxis
					local rotation = CFrame.fromMatrix(Vector3.zero, right, up, right:Cross(up))
						* CFrame.Angles(0, index % 2 == 0 and 0.5 or -0.5, 0)
					local entry = buildSword(index, tip, up, rotation, FX.SwordHover)
					entry.Born = cast:Now()
					entry.Dir = dir
					entry.Entry = boxExit(box, tip, dir)
					 
					entry.Mark = disc(cast, entry.Entry + dir * 0.2, 1, GOLD, 1, dir)
					entry.Ray = part(
						"P3DashSwordRay",
						CFrame.new(tip + up * (entry.Hover / 2 + 2)) * rotation,
						Vector3.new(0.12, entry.Hover + 4, 0.12),
						GOLD,
						1
					)
					entry.Ray.Material = Enum.Material.Neon
					table.insert(swords, entry)
					Effects:Create(
						entry.Mark,
						TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Size = Vector3.new(0.2, 3, 3), Transparency = 0.4 }
					):Play()
					Effects:Create(entry.Ray, TweenInfo.new(0.2), { Transparency = 0.78 }):Play()
					for _, bit in ipairs(entry.Bits) do
						Effects:Create(bit.Part, TweenInfo.new(0.16), { Transparency = bit.Alpha }):Play()
					end
					pulse(cast, tip + up * entry.Hover, 1.5, 7, 0.3, WHITE, 0.3, up)  
					actor:SetAttribute("P3DashSwordsSummoned", index)
					if
						not animate(Config.P3DashSwordInterval, function()
							placeSwords(swords, hoverDistance)
						end, victim)
					then
						return false
					end
				end

				actor:SetAttribute("P3DashState", "Simultaneous sword strike")
				actor:SetAttribute("P3DashSwordStrikeAt", workspace:GetServerTimeNow())
				if
					not animate(Config.P3DashSwordStrikeDuration, function(t)
						placeSwords(swords, function(entry)
							return strikeDistance(entry, t)
						end)
					end, victim)
				then
					return false
				end

				 
				core.ScreenEffect("Shake", { Origin = center, Radius = 100, Duration = 0.7, Intensity = 1.8 })
				local flash = part("P3DashStrikeFlash", CFrame.new(center), Vector3.one * 4, WHITE, 0.1)
				flash.Shape = Enum.PartType.Ball
				Effects:Create(
					flash,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.one * (FX.BoxWidth * 2.4), Transparency = 1 }
				):Play()
				local light = Instance.new("PointLight")
				light.Color = GOLD
				light.Range = 45
				light.Brightness = 5
				light.Parent = flash
				Tween:Create(light, TweenInfo.new(0.4), { Brightness = 0 }):Play()
				cast:Schedule(0.4, function()
					release(flash)
				end)
				flashEdges(box, 0.5)
				pulse(cast, floorPoint + Vector3.new(0, 0.2, 0), 4, 38, 0.5, WHITE, 0.1)
				for _, entry in ipairs(swords) do
					Effects:Create(entry.Ray, TweenInfo.new(0.2), { Transparency = 1 }):Play()
					Effects:Create(entry.Mark, TweenInfo.new(0.35), { Transparency = 1 }):Play()
					pulse(cast, entry.Entry, 1.5, 7, 0.3, WHITE, 0.2, entry.Dir)
					fling(cast, entry.Entry, 4, GOLD, Vector3.new(0.3, 0.3, 0.9), 9, 0.5, 40, 6)
				end

				 
				 
				local swordVisuals =
					Effects.NewCast(actor, "P3DashPinnedSwordVisuals", Config.P3DashSwordVisualHold + 1)
				for _, entry in ipairs(swords) do
					for _, bit in ipairs(entry.Bits) do
						cast.objects[bit.Part] = nil
						swordVisuals:Add(bit.Part)
					end
				end
				 
				 
				local shattered = false
				local function shatterSwords()
					if shattered or swordVisuals.closed then
						return
					end
					shattered = true
					for _, entry in ipairs(swords) do
						for _, bit in ipairs(entry.Bits) do
							Effects:Create(bit.Part, TweenInfo.new(0.2), { Transparency = 1 }):Play()
						end
						fling(
							swordVisuals,
							entry.Tip + entry.Up * 7,
							5,
							entry.Index % 2 == 0 and GOLD or WHITE,
							Vector3.new(0.35, 0.9, 0.2),
							10,
							0.7,
							60,
							8
						)
					end
				end
				swordVisuals:Schedule(Config.P3DashSwordVisualHold, shatterSwords)

				 
				 
				for index = 1, #swords do
					if not valid(victim) then
						break
					end
					local amount = Encounter.Damage(victim, Config.P3DashSwordDamage, actor, cast)
					actor:SetAttribute("P3DashSwordsHit", index)
					actor:SetAttribute("P3DashActualDamage", (actor:GetAttribute("P3DashActualDamage") or 0) + amount)
				end

				actor:SetAttribute("P3DashState", "Pinned swords")
				 
				local pinLength = Config.P3DashSwordPinDuration
				if
					not animate(pinLength, function(t)
						local elapsed = t * pinLength
						if elapsed < 0.45 then
							local settle = elapsed / 0.45
							local decay = (1 - settle) ^ 2
							local wobble = math.sin(settle * math.pi * 3) * decay * 0.9
							placeSwords(swords, function()
								return wobble
							end)
							placeBox(
								box,
								1,
								Vector3.new(
									math.sin(elapsed * 80) * 0.22 * decay,
									0,
									math.cos(elapsed * 70) * 0.22 * decay
								)
							)
						end
					end, victim)
				then
					return false
				end
				placeSwords(swords, function()
					return 0
				end)
				placeBox(box, 1)

				actor:SetAttribute("P3DashState", "Box shatter")
				record.NextPinnedTick = nil
				for _, bar in ipairs(sigilBars) do
					Effects:Create(bar, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				end
				pulse(cast, floorPoint + Vector3.new(0, 0.3, 0), 2, 22, 0.35, WHITE, 0.2)
				fling(cast, center, 16, GOLD, Vector3.one * 0.5, 16, 0.7, 50, 8)
				shatterSwords()
				for _, bit in ipairs(box.Bits) do
					Effects:Create(bit.Part, TweenInfo.new(0.2), { Transparency = 1 }):Play()
				end
				 
				if not animate(0.14, function(t)
					placeBox(box, 1 - t * 1.2)
				end, victim) then
					return false
				end
				for _, bit in ipairs(box.Bits) do
					if bit.Part.Parent then
						release(bit.Part)
					end
				end
				record.Box = nil

				 
				releaseHeld()
				if FX.PunishWindow > 0 then
					actor:SetAttribute("P3DashState", "Recovery")
					core.PoseAngles(
						{
							Waist = { 34, 0, 0 },
							RightShoulder = { 22, 0, 6 },
							LeftShoulder = { 22, 0, -6 },
							RightElbow = {
								12,
								0,
								0,
							},
						},
						0.2
					)
					fling(cast, core.Root.Position + Vector3.new(0, 2, 0), 8, WHITE, Vector3.one * 0.9, 3, 0.9, -4, 2)
					return animate(FX.PunishWindow, nil, nil)
				end
				return true
			end

			local ok, result = xpcall(sequence, debug.traceback)
			cast:Dispose()
			if not ok then
				error(result, 0)
			end
			return result
		end)
	end
	function api.Dispose()
		if current then
			current.Cast:Dispose()
		end
	end
	return api
end
