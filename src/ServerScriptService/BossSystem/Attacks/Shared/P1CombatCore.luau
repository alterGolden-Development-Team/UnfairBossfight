local Aim=require(script:FindFirstAncestor("BossSystem").Combat.AttackTargetContinuity)
local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local BossSystem = script:FindFirstAncestor("BossSystem")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Locomotion = require(BossSystem.Boss.BossLocomotion)
	local b = actor
	local h = b:WaitForChild("Humanoid")
	local root = b:WaitForChild("HumanoidRootPart")
	local melee = Registry.For(b, "P1NormalSlash")
	local Players = game:GetService("Players")
	local Run = game:GetService("RunService")
	local Tween = Effects
	local Debris = Effects
	local runtime = require(BossSystem.Combat.CombatRuntime)
	local api = {}
	local performGeneration, lastPoseToken
	local encounter = require(BossSystem.Players.PlayerEncounter)
	local damageReference = actor:FindFirstChild("EncounterOwner")
	local damageOwner = damageReference and damageReference:IsA("ObjectValue") and damageReference.Value or actor
	local visualOnly = actor:GetAttribute("IsIllusion") == true
	function api.Damage(character,amount,skill)
  if actor:GetAttribute("ClassStunFrame") or workspace:GetServerTimeNow()<(actor:GetAttribute("ClassStunnedUntil") or 0) then return 0 end
		local dealt = not visualOnly
				and encounter.Damage(character, amount, damageOwner, nil, skill and { Skill = skill })
			or 0
		if dealt > 0 then
			Audio.Attack(b, b:GetAttribute("CurrentSkill"), "Impact", character:FindFirstChild("HumanoidRootPart"))
		end
		return dealt
	end
	 
	function api.KeepFor(instance, seconds, tweens)
		Effects.ReleaseAfter(instance, seconds, tweens)
	end
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")
	function api.ScreenEffect(kind, data, onlyPlayer)
		if visualOnly then
			return
		end
		if onlyPlayer then
			remote:FireClient(onlyPlayer, kind, data)
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local r = char and char:FindFirstChild("HumanoidRootPart")
			if (r and (not data.Origin or (r.Position - data.Origin).Magnitude <= (data.Radius or 240)))
    or (not r and data.Owner == b) then
				remote:FireClient(player, kind, data)
			end
		end
	end
	local effects = Instance.new("Folder")
	effects.Name = "AlterGoldenBladeEffects"
	effects.Parent = runtime.Effects
	Effects.TrackContainer(effects, actor)
	local gold = Color3.fromRGB(255, 210, 25)
	local function active()
		return b.Parent and h.Health>0 and b:GetAttribute("AIEnabled")~=false
   and workspace:GetServerTimeNow()>=(b:GetAttribute("ClassStunnedUntil") or 0)
   and b:GetAttribute("ClassStunFrame")==nil
	end
	local actorActive = active
	active = function()
		return actorActive()
			and (performGeneration == nil or performGeneration == (b:GetAttribute("PhaseGeneration") or 0))
			and (melee.MovementRevision == nil or melee.MovementRevision == (b:GetAttribute("MovementRevision") or 0))
	end
	local function alive(char)
		if Observer.IsCharacter(char) then
			return false
		end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		return char and char.Parent and hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart")
	end
	local characters = runtime.Characters
	local params = runtime.FilterFor(b, effects)
	local function floorY(pos, p)
		local ray = workspace:Raycast(pos, Vector3.new(0, -200, 0), p)
		if ray and ray.Normal.Y > 0.55 then
			local leg = h.RigType == Enum.HumanoidRigType.R6
				and (b:FindFirstChild("Right Leg") or b:FindFirstChild("Left Leg"))
			return ray.Position.Y + h.HipHeight + root.Size.Y * 0.5 + (leg and leg.Size.Y or 0), ray.Position.Y
		end
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
	 
	 
	function api.WaitForWindup(seconds, options)
		options = options or {}
		local remaining = math.max(0, seconds)
		local cast = Effects.NewCast(b, "RegisteredAttackWindup", math.max(2, seconds + 1))
		local minimumUntil = 0
		local done = false
		local motion = Projectiles.RegisterMotion(b, {
			Cast = cast,
			Skill = options.Skill,
			Moving = function()
				return not done and cast:Alive() and active()
			end,
			Hide = function(hidden)
				if options.Hide then
					options.Hide(hidden)
				end
			end,
			Advance = function(advance)
				remaining = math.max(0, remaining - advance)
				minimumUntil = workspace:GetServerTimeNow() + (options.MinimumRemaining or 0.22)
				return true
			end,
		})
		cast.OnDispose = function()
			motion:Dispose()
		end
		repeat
			local dt = Run.Heartbeat:Wait()
			if not cast:Alive() or not Time.WaitForActor(b) or not active() then
				cast:Dispose()
				return false
			end
			if not motion:IsHidden() then
				remaining -= dt * Time.BossRate(b)
			end
		until remaining <= 0 and not motion:IsHidden() and workspace:GetServerTimeNow() >= minimumUntil
		done = true
		cast:Dispose()
		return true
	end
	function api.BeginTelegraph(name, spec)
		return require(BossSystem.Phases.Phase25Controller).BeginFalseTelegraph(b, name, spec)
	end
	function api.WaitForTelegraph(name, seconds, spec)
		spec = spec or {}
		spec.Duration = seconds
		local handle = api.BeginTelegraph(name, spec)
		if not handle then
			return api.WaitForWindup(seconds, { Skill = name, MinimumRemaining = 0.4, Hide = spec.Hide })
		end
		repeat
			Run.Heartbeat:Wait()
			if not active() or handle.Cast.closed then
				handle.Cast:Dispose()
				return false, handle
			end
		until handle.Ready
		handle.Cast:Dispose()
		return true, handle
	end
	local function face(char)
		if b:GetAttribute("TimeFrozen") or workspace:GetServerTimeNow()<(b:GetAttribute("ClassStunnedUntil") or 0) or not alive(char) then
			return
		end
		local pos = char.HumanoidRootPart.Position
		local goal = Vector3.new(pos.X, root.Position.Y, pos.Z)
		if (goal - root.Position).Magnitude > 0.01 then
			root.CFrame = CFrame.lookAt(root.Position, goal)
		end
	end
	local function part(name, cf, size, color, alpha)
		local p = Effects.AcquirePart()
		p.CastShadow = false
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = alpha
		p.Size = size
		p.CFrame = cf
		p.Parent = effects
		return p
	end
	local function canHit(char, origin)
		return alive(char)
			and encounter.CanReceiveHit(char)
			and not workspace:Raycast(origin, char.HumanoidRootPart.Position - origin, params(char))
	end
	local function motionLine(name, start, finish, width, color, lifetime)
		local delta = finish - start
		if delta.Magnitude < 0.02 then
			return
		end
		local p = part(
			name,
			CFrame.lookAt((start + finish) * 0.5, finish),
			Vector3.new(width, width, delta.Magnitude),
			color,
			0.15
		)
		Tween:Create(p, TweenInfo.new(lifetime), { Transparency = 1 }):Play()
		Debris:AddItem(p, lifetime + 0.03)
	end
	local afterimageAt = 0
	function api.Afterimage(frame)
		local now = os.clock()
		if now < afterimageAt then
			return
		end
		afterimageAt = now + 0.09
		local original = root.CFrame
		for _, name in ipairs({
			"Head",
			"UpperTorso",
			"RightUpperArm",
			"LeftUpperArm",
			"Torso",
			"Right Arm",
			"Left Arm",
		}) do
			local body = b:FindFirstChild(name)
			if body then
				local p =
					part("GoldenDashAfterimage", frame * original:ToObjectSpace(body.CFrame), body.Size, gold, 0.7)
				Tween:Create(p, TweenInfo.new(0.27), { Transparency = 1 }):Play()
				Debris:AddItem(p, 0.3)
			end
		end
	end
	local motors = {}
	local poseTweens = {}
	for _, joint in ipairs(b:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Name ~= "RightGrip" and joint:GetAttribute("BossBaseC0") then
			motors[joint.Name] = joint
		end
	end
	function api.PoseAngles(pose, duration)
		lastPoseToken = melee.PoseAngles(pose, duration)
		return lastPoseToken
	end
	local busy = false
	function api.Perform(char, name, callback)
		if busy or not active() or not alive(char) then
			return false
		end
		 
		Aim.For(char)
		busy = true
		performGeneration = b:GetAttribute("PhaseGeneration") or 0
		lastPoseToken = nil
		melee.MovementRevision = b:GetAttribute("MovementRevision") or 0
		b:SetAttribute("CurrentSkill", name)
		Audio.Attack(b, name, "Cast", root)
		local sword = b:FindFirstChild("Basic Sword")
		local blade = sword and sword:FindFirstChild("Blade")
		local trail = blade and blade:FindFirstChild("SlashTrail")
		local light = blade and blade:FindFirstChild("WindupLight")
		if light then
			light.Brightness = 4
		end
		local ok, result = xpcall(callback, debug.traceback)
		if trail then
			trail.Enabled = false
		end
		if light then
			light.Brightness = 0
		end
		local ownsMovement = melee.MovementRevision == (b:GetAttribute("MovementRevision") or 0)
		if api.AirborneFloor and ownsMovement then
			local floor = floorY(root.Position, params()) or api.AirborneFloor
			root.CFrame = CFrame.new(root.Position.X, floor, root.Position.Z) * root.CFrame.Rotation
			api.AirborneFloor = nil
		end
		api.AirborneFloor = nil
		local ownsAnimation = performGeneration == (b:GetAttribute("PhaseGeneration") or 0)
			and actorActive()
			and not b:GetAttribute("PhaseTransitionInProgress")
		if ownsAnimation then
			melee.Pose("Idle", 0.18)
			if ownsMovement then
				melee.Settle()
			end
			b:SetAttribute("AttackState", h.Health > 0 and "Idle" or "Defeated")
		elseif lastPoseToken then
			Locomotion.ReleasePose(b, lastPoseToken, 0.18)
		end
		busy = false
		performGeneration = nil
		lastPoseToken = nil
		melee.MovementRevision = nil
		if not ok then
			warn(name .. " failed: " .. tostring(result))
		end
		return ok and result
	end

	function api.Dispose()
		for _, t in pairs(poseTweens) do
			t:Cancel()
		end
		 
	end
	api.Humanoid = h
	api.Root = root
	api.Melee = melee
	api.Effects = effects
	api.Motors = motors
	api.Active = active
	api.RetainTarget = Aim.Retain
	api.Alive = alive
	api.Characters = characters
	api.Params = params
	api.FloorY = floorY
	api.WaitFor = waitFor
	api.Face = face
	api.Part = part
	api.CanHit = canHit
	api.MotionLine = motionLine
	return api
end
