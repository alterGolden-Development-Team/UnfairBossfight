local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Aim = require(BossSystem.Combat.AttackTargetContinuity)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Effects = require(BossSystem.Combat.EffectService)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Locomotion = require(BossSystem.Boss.BossLocomotion)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	 
	local b = actor
	local h = b:WaitForChild("Humanoid")
	local root = b:WaitForChild("HumanoidRootPart")
	local Run = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local Tween = Effects
	local Debris = Effects
	local Pathfinding = game:GetService("PathfindingService")
	local runtime = require(BossSystem.Combat.CombatRuntime)
	local api = {}
	local encounter = require(BossSystem.Players.PlayerEncounter)
	local effects = Instance.new("Folder")
	effects.Name = "AlterGoldenSlashEffects"
	effects.Parent = runtime.Effects
	Effects.TrackContainer(effects, actor)
	local sword = b["Basic Sword"]
	local blade = sword.Blade
	local trail = blade.SlashTrail
	local light = blade.WindupLight
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 190), Color3.fromRGB(255, 210, 20))
	light.Color = Color3.fromRGB(255, 220, 45)
	local GOLD = Style.GOLD
	local AMBER = Style.AMBER
	local WHITE = Style.WHITE
	local rng = Random.new()
	local poses = {
		Idle = {
			RightShoulder = { 15, 0, 0 },
			RightElbow = { 60, 0, 0 },
			RightWrist = { 0, 0, 0 },
			LeftShoulder = {
				0,
				0,
				0,
			},
		},
		Windup = {
			RightShoulder = { 65, 0, 55 },
			RightElbow = { 38, 0, 0 },
			LeftShoulder = { 20, 0, -22 },
			Waist = {
				0,
				-28,
				0,
			},
		},
		Dash = {
			RightShoulder = { -35, 0, 28 },
			RightElbow = { 18, 0, 0 },
			LeftShoulder = { -30, 0, -22 },
			Waist = { 17, 0, 0 },
			RightHip = { -25, 0, 5 },
			RightKnee = { 38, 0, 0 },
			LeftHip = { -12, 0, -5 },
			LeftKnee = { 48, 0, 0 },
		},
		Slash1 = {
			RightShoulder = { 65, -20, -62 },
			RightElbow = { 8, 0, 0 },
			LeftShoulder = { 20, 0, -30 },
			Waist = {
				0,
				32,
				0,
			},
		},
		Windup2 = { RightShoulder = { 70, -15, -58 }, RightElbow = { 30, 0, 0 }, Waist = { 0, 28, 0 } },
		Slash2 = { RightShoulder = { 68, 15, 60 }, RightElbow = { 8, 0, 0 }, Waist = { 0, -32, 0 } },
		Windup3 = { RightShoulder = { 112, 0, 12 }, RightElbow = { 32, 0, 0 }, Waist = { -6, 0, 0 } },
		Slash3 = { RightShoulder = { 42, 0, -55 }, RightElbow = { 5, 0, 0 }, Waist = { 15, 22, 0 } },
	}
	function api.PoseAngles(pose, duration)
		return Locomotion.Pose(b, pose, duration)
	end
	function api.Pose(name, duration)
		if name == "Idle" then
			Locomotion.Idle(b, duration)
		else
			api.PoseAngles(poses[name] or poses.Idle, duration)
		end
	end
	local function alive(char)
		if Observer.IsCharacter(char) then
			return false
		end
		local other = char and char:FindFirstChildOfClass("Humanoid")
		return char and char.Parent and other and char:FindFirstChild("HumanoidRootPart")
   and (other.Health > 0 or Aim.Valid(char))
	end
	local function active()
		return b.Parent
			and h.Health > 0
			and b:GetAttribute("AIEnabled") ~= false
			and (api.MovementRevision == nil or api.MovementRevision == (b:GetAttribute("MovementRevision") or 0))
	end
	local function waitFor(seconds)
		local elapsed = 0
		repeat
			local dt = Run.Heartbeat:Wait()
			if not Time.WaitForActor(b) or not active() then
				return false
			end
			elapsed += dt * Time.BossRate(b)
		until elapsed >= seconds
		return true
	end
	local characters = runtime.Characters
	local targetRandom = Random.new()
	local selectedTarget
	local function eligible(char)
		local h = char and char:FindFirstChildOfClass("Humanoid")
  if not alive(char) or not h or h.Health <= 0 then
   return false
  end
  local player = game:GetService("Players"):GetPlayerFromCharacter(char)
		return not player
			or player.Character == char
				and not player:GetAttribute("PermanentlyDefeated")
				and not player:GetAttribute("ExecutionPending")
				and not player:GetAttribute("ViewAsServer")
	end
	 
	function api.ChooseTarget(candidates)
		local available = {}
		for _, char in ipairs(candidates) do
			if eligible(char) then
				table.insert(available, char)
			end
		end
		if #available == 0 then
			return nil
		end
		return available[targetRandom:NextInteger(1, #available)]
	end
	function api.GetTarget(chooseAgain)
  local taunted=require(BossSystem.Combat.TauntService).Target(actor)
  if taunted then selectedTarget=taunted return Aim.For(taunted) end
		 
		 
		if chooseAgain or not eligible(selectedTarget) then
			selectedTarget = api.ChooseTarget(characters())
		end
		return selectedTarget and Aim.For(selectedTarget) or Aim.Fallback()
	end
	local params = runtime.FilterFor(b, effects)
	local function sight(char)
		local delta = char.HumanoidRootPart.Position - root.Position
		return not workspace:Raycast(root.Position, delta, params(char))
	end
	function api.IsInArc(frame, position, radius)
		local p = frame:PointToObjectSpace(position)
		local d = Vector3.new(p.X, 0, p.Z).Magnitude
		if math.abs(p.Y) > 7 or d > radius then
			return false
		end
		return d < 0.1 or -p.Z / d >= math.cos(math.rad(b:GetAttribute("SlashHalfAngle") or 135))
	end
	function api.DamageArc(frame, candidates, hit)
		local count = 0
		for _, char in ipairs(candidates) do
			local other = char:FindFirstChildOfClass("Humanoid")
			if
				alive(char)
				and not char:GetAttribute("Invulnerable")
				and not char:FindFirstChildOfClass("ForceField")
				and not hit[other]
				and api.IsInArc(frame, char.HumanoidRootPart.Position, b:GetAttribute("SlashRadius") or 22)
				and sight(char)
			then
				hit[other] = true
				if encounter.Damage(char, b:GetAttribute("SlashDamage") or 13, b) > 0 then
					Audio.Emit(b, "NormalImpact", char.HumanoidRootPart)
					api.HitFx(char.HumanoidRootPart.Position)
					count += 1
				end
			end
		end
		return count
	end
	 
	local newPart = Visuals.newPart({
		Effects = Effects,
		effects = effects,
	})
	local vfxPart = Visuals.vfxPart({
		newPart = newPart,
		Tween = Tween,
		Debris = Debris,
	})
	local makeSparks = Visuals.makeSparks({})

	 
	local taper = Visuals.taper({})
	local sparkBurstAt = Visuals.sparkBurstAt({
		vfxPart = vfxPart,
		GOLD = GOLD,
		makeSparks = makeSparks,
	})
	local dustPuffAt = Visuals.dustPuffAt({
		vfxPart = vfxPart,
		GOLD = GOLD,
	})
	local flashBall = Visuals.flashBall({
		vfxPart = vfxPart,
		WHITE = WHITE,
		Tween = Tween,
	})
	 
	api.HitFx = Visuals.HitFx({
		flashBall = flashBall,
		WHITE = WHITE,
		AMBER = AMBER,
		rng = rng,
		vfxPart = vfxPart,
		Tween = Tween,
		sparkBurstAt = sparkBurstAt,
	})

	 
	 
	api.Crescent = Visuals.Crescent({
		b = b,
		Debris = Debris,
		taper = taper,
		newPart = newPart,
		GOLD = GOLD,
		AMBER = AMBER,
		WHITE = WHITE,
		params = params,
		dustPuffAt = dustPuffAt,
		TweenService = TweenService,
		flashBall = flashBall,
		makeSparks = makeSparks,
		vfxPart = vfxPart,
		Run = Run,
	})
	local function groundY(position, p)
		local result = workspace:Raycast(position + Vector3.new(0, 10, 0), Vector3.new(0, -300, 0), p)
		if not result or result.Normal.Y < 0.55 then
			return nil
		end
		local leg = h.RigType == Enum.HumanoidRigType.R6
			and (b:FindFirstChild("Right Leg") or b:FindFirstChild("Left Leg"))
		return result.Position.Y + h.HipHeight + root.Size.Y * 0.5 + (leg and leg.Size.Y or 0)
	end
	local function face(char, alpha)
		if b:GetAttribute("TimeFrozen") or not alive(char) then
			return
		end
		local target = char.HumanoidRootPart.Position
		local goal = Vector3.new(target.X, root.Position.Y, target.Z)
		if (goal - root.Position).Magnitude > 0.1 then
			root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, goal), alpha or 1)
		end
	end
	function api.Settle()
		local p = params()
		local y = groundY(root.Position, p)
		if y and math.abs(root.Position.Y - y) < 12 then
			local start = root.CFrame
			local elapsed = 0
			repeat
				if
					not b.Parent
					or (
						api.MovementRevision ~= nil
						and api.MovementRevision ~= (b:GetAttribute("MovementRevision") or 0)
					)
				then
					return
				end
				local dt = Run.Heartbeat:Wait()
				if
					not Time.WaitForActor(b)
					or not b.Parent
					or (
						api.MovementRevision ~= nil
						and api.MovementRevision ~= (b:GetAttribute("MovementRevision") or 0)
					)
				then
					return
				end
				elapsed += dt * Time.BossRate(b)
				local t = math.min(1, elapsed / 0.16)
				root.CFrame = CFrame.new(start.Position:Lerp(Vector3.new(start.X, y, start.Z), t))
					* root.CFrame.Rotation
			until elapsed >= 0.16
			root.CFrame = CFrame.new(root.Position.X, y, root.Position.Z) * root.CFrame.Rotation
		end
	end
	function api.RunToTarget(char, maxSeconds)
		if not active() or not alive(char) then
			return false
		end
		local stopDistance = math.max(4, Config.NormalSlashStopDistance or 6)
		local paramsForRun = params(char)
		local speed = Config.NormalSlashApproachSpeed
		local elapsed, travelled, routeAt = 0, 0, 0
		local route, routeIndex = nil, 1
		local initialDistance = (char.HumanoidRootPart.Position - root.Position).Magnitude
		local maxTime = maxSeconds
			or math.min(20, math.max(Config.NormalSlashChaseTimeout or 8, initialDistance / speed + 2))
		b:SetAttribute("AttackState", "Normal Slash: running approach")
		b:SetAttribute("NormalApproachStartedAt", workspace:GetServerTimeNow())
		Locomotion.Run(b, speed)
		local reached = false
		while active() and alive(char) and elapsed < maxTime do
			local realDt = Run.Heartbeat:Wait()
			local dt = math.min(realDt * Time.BossRate(b), 0.075)
			if dt <= 0 then
				continue
			end
			elapsed += dt
			local target = char.HumanoidRootPart.Position
			local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
			if flat.Magnitude <= stopDistance + 0.15 then
				reached = true
				break
			end
			local waypoint = target
			if route and routeIndex <= #route then
				waypoint = route[routeIndex].Position
				local horizontal = Vector3.new(waypoint.X - root.Position.X, 0, waypoint.Z - root.Position.Z)
				if horizontal.Magnitude < 2 then
					routeIndex += 1
					continue
				end
			else
				route = nil
			end
			local offset = Vector3.new(waypoint.X - root.Position.X, 0, waypoint.Z - root.Position.Z)
			if offset.Magnitude < 0.05 then
				break
			end
			local direction = offset.Unit
			local stride = math.min(speed * dt, offset.Magnitude, math.max(0, flat.Magnitude - stopDistance))
			local nextPos = root.Position + direction * stride
			local floor = groundY(nextPos, paramsForRun)
			if not floor or math.abs(floor - root.Position.Y) > 4 then
				break
			end
			nextPos = Vector3.new(nextPos.X, floor, nextPos.Z)
			local step = nextPos - root.Position
			local wall = workspace:Blockcast(root.CFrame, Vector3.new(2.3, 2.7, 2.3), step, paramsForRun)
			if wall then
				if elapsed < routeAt then
					break
				end
				routeAt = elapsed + 1
				local path = Pathfinding:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = false,
					WaypointSpacing = 5,
				})
				local ok = pcall(function()
					path:ComputeAsync(root.Position, target)
				end)
				if not active() or not alive(char) then
					break
				end
				if not ok or path.Status ~= Enum.PathStatus.Success then
					break
				end
				route = path:GetWaypoints()
				routeIndex = 2
				continue
			end
			local currentLook = root.CFrame.LookVector
			local currentYaw = math.atan2(-currentLook.X, -currentLook.Z)
			local targetYaw = math.atan2(-direction.X, -direction.Z)
			local deltaYaw = (targetYaw - currentYaw + math.pi) % (2 * math.pi) - math.pi
			root.CFrame = CFrame.new(nextPos) * CFrame.Angles(0, currentYaw + deltaYaw * (1 - math.exp(-16 * dt)), 0)
			travelled += Vector3.new(step.X, 0, step.Z).Magnitude
			if
				route
				and elapsed >= routeAt
				and not workspace:Blockcast(
					root.CFrame,
					Vector3.new(2.3, 2.7, 2.3),
					flat.Unit * math.min(flat.Magnitude - stopDistance, 30),
					paramsForRun
				)
			then
				route = nil
			end
		end
		if active() then
			Locomotion.Idle(b, 0.12)
		end
		b:SetAttribute("LastNormalApproachDistance", travelled)
		b:SetAttribute("LastNormalApproachDuration", elapsed)
		b:SetAttribute("LastNormalApproachInitialDistance", initialDistance)
		b:SetAttribute(
			"LastNormalApproachStopDistance",
			alive(char)
					and Vector3.new(
						char.HumanoidRootPart.Position.X - root.Position.X,
						0,
						char.HumanoidRootPart.Position.Z - root.Position.Z
					).Magnitude
				or -1
		)
		b:SetAttribute("NormalApproachFinishedAt", workspace:GetServerTimeNow())
		return reached and active() and alive(char)
	end
	local busy = false
	local function finish()
		trail.Enabled = false
		light.Brightness = 0
		if active() then
			api.Settle()
			api.Pose("Idle", 0.2)
			b:SetAttribute("AttackState", h.Health > 0 and "Idle" or "Defeated")
		end
		busy = false
	end
	local function perform(char)
		local comboBegin = os.clock()
		b:SetAttribute("CurrentSkill", "Normal Slash")
		if not api.RunToTarget(char) then
			return false
		end
		face(char)
		b:SetAttribute("AttackState", "Slash wind-up")
		Audio.Emit(b, "NormalDraw", root)
		api.Pose("Windup", 0.11)
		light.Brightness = 3
		if not waitFor(b:GetAttribute("NormalWindupTime") or 0.18) then
			return false
		end
		local swings = Difficulty.Design("NormalSlash", "Swings", { 1, 2, 1, 2, 3 }, b)
		local lead = Difficulty.Design("NormalSlash", "Lead", 0, b)
		for index = 1, #swings do
			local swing = swings[index]
			if not active() or not alive(char) then
				return false
			end
			face(char)
			local targetOffset = char.HumanoidRootPart.Position - root.Position
			if
				index > 1
				and Vector3.new(targetOffset.X, 0, targetOffset.Z).Magnitude
					> (Config.NormalSlashStopDistance or 6) + 1
			then
				api.RunToTarget(char, Config.NormalSlashRepositionTimeout or 0.3)
			end
			api.Pose(swing == 1 and "Windup" or "Windup" .. swing, 0.055)
			if not waitFor(b:GetAttribute("NormalSwingWindup") or Difficulty.Design("NormalSlash", "SwingWindup", 0.07, b)) then
				return false
			end
			 
			 
			face(char)
			 
			if lead > 0 and alive(char) then
				local p = char.HumanoidRootPart.Position + char.HumanoidRootPart.AssemblyLinearVelocity * lead
				local g = Vector3.new(p.X, root.Position.Y, p.Z)
				if (g - root.Position).Magnitude > 0.1 then
					root.CFrame = CFrame.lookAt(root.Position, g)
				end
			end
			b:SetAttribute("AttackState", "Slash " .. index)
			b:SetAttribute("SlashCount", (b:GetAttribute("SlashCount") or 0) + 1)
			api.Pose("Slash" .. swing, 0.075)
			Audio.Emit(b, "NormalSwing", blade, { Pitch = 0.94 + index * 0.025 })
			trail.Enabled = true
			local frame = root.CFrame
			api.Crescent(frame, swing)
			local hit = {}
			local elapsed = 0
			repeat
				if not active() or not alive(char) then
					return false
				end
				local dt = Run.Heartbeat:Wait()
				local actionDt = dt * Time.BossRate(b)
				if actionDt > 0 then
					api.DamageArc(frame, characters(), hit)
					elapsed += actionDt
				end
			until elapsed >= (b:GetAttribute("NormalHitWindow") or 0.10)
			trail.Enabled = false
			if not waitFor(b:GetAttribute("NormalSwingPause") or 0.025) then
				return false
			end
		end
		b:SetAttribute("CompletedCombos", (b:GetAttribute("CompletedCombos") or 0) + 1)
		b:SetAttribute("LastNormalComboDuration", os.clock() - comboBegin)
		b:SetAttribute("AttackState", "Recovery")
		api.Pose("Idle", 0.2)
		light.Brightness = 0
		api.Settle()
		return true
	end
	function api.Combo(char)
		if busy or not active() or not alive(char) then
			return false
		end
		busy = true
		api.MovementRevision = b:GetAttribute("MovementRevision") or 0
		local ok, result = xpcall(function()
			return perform(char)
		end, debug.traceback)
		finish()
		api.MovementRevision = nil
		if not ok then
			warn("Slash failed: " .. tostring(result))
		end
		return ok and result
	end
	function api.Dispose()
		Locomotion.Release(b)
	end
	api.Pose("Idle", 0.01)
	return api
end
