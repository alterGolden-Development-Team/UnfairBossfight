local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Effects = require(BossSystem.Combat.EffectService)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local b = actor
	local core = Registry.For(b, "P1CombatCore")
	local melee, root, h = core.Melee, core.Root, core.Humanoid
	local Players = game:GetService("Players")
	local Run = game:GetService("RunService")
	local Debris = Effects
	local api = {}
	local rng = Random.new()
	local GOLD = Style.GOLD
	local BRIGHT = Style.BRIGHT
	local DEEP = Style.DEEP
	local guarding = false
	local deadline = 0
	local attacker
	local flare = 0
	local lastContactVfx = 0

	 
	local disc = Visuals.disc({
		core = core,
		Effects = Effects,
		Debris = Debris,
	})
	 
	local glowBall = Visuals.glowBall({
		core = core,
		BRIGHT = BRIGHT,
		Effects = Effects,
		Debris = Debris,
	})
	 
	local sparkBurst = Visuals.sparkBurst({
		core = core,
		GOLD = GOLD,
		BRIGHT = BRIGHT,
		Debris = Debris,
	})
	 
	local radial = Visuals.radial({
		rng = rng,
		core = core,
		GOLD = GOLD,
		BRIGHT = BRIGHT,
	})
	 
	local slashLine = Visuals.slashLine({
		core = core,
		DEEP = DEEP,
		GOLD = GOLD,
		BRIGHT = BRIGHT,
	})
	 
	local function parryFlash(char)
		flare = 1
		if os.clock() - lastContactVfx < 0.12 then
			return
		end
		lastContactVfx = os.clock()
		local dir = char.HumanoidRootPart.Position - root.Position
		dir = Vector3.new(dir.X, 0, dir.Z)
		dir = dir.Magnitude > 0.01 and dir.Unit or root.CFrame.LookVector
		local contact = root.Position + dir * 4 + Vector3.new(0, 1, 0)
		local axisA = dir:Cross(Vector3.yAxis)
		axisA = axisA.Magnitude > 0.01 and axisA.Unit or Vector3.xAxis
		local axisB = axisA:Cross(dir)
		glowBall(contact, 8, 0.2, BRIGHT)
		radial(contact, axisA, axisB, 14, 1, 8, 0.18, 0.25)
		sparkBurst(contact, 18, 10, 26)
		for _ = 1, 3 do
			local bounce = contact
				+ dir * rng:NextNumber(5, 10)
				+ axisA * rng:NextNumber(-5, 5)
				+ Vector3.new(0, rng:NextNumber(-2, 4), 0)
			core.MotionLine("GoldenParryDeflect", contact, bounce, 0.2, BRIGHT, 0.25)
		end
	end

	function api.CanUse(char)
		return core.Alive(char)
			and (
				b:GetAttribute("CloneMode") == "HourDebt"
				or (char.HumanoidRootPart.Position - root.Position).Magnitude
					<= (b:GetAttribute("ParryTriggerRange") or 18)
			)
	end
	function api.TryCounter(char, attackToken)
		if not guarding or Time.ActionNow(actor) > deadline or not core.Active() or not core.Alive(char) then
			return false
		end
  if type(attackToken)=="table" and (attackToken.Direct~=true or attackToken.Attacker~=char) then return false end
		Audio.Emit(actor, "ParryContact", root)
		parryFlash(char)
		 
		if
			not attacker
			and not Status.IsDebuffImmune(char)
			and not char:GetAttribute("Invulnerable")
   and not char:GetAttribute("ClassStatus_Phasing")
   and not char:GetAttribute("ClassStatus_Uninterrupted")
   and not char:GetAttribute("TankDefenderHeld")
			and not char:FindFirstChildOfClass("ForceField")
		then
			attacker = char
		end
		return true
	end
	function api.MoveBehind(char)
		local target = char.HumanoidRootPart
		local p = core.Params(char)
		for _, offset in ipairs({ Vector3.new(0, 0, 4.5), Vector3.new(3, 0, 4), Vector3.new(-3, 0, 4) }) do
			local goal = (target.CFrame * CFrame.new(offset)).Position
			local floor = core.FloorY(goal + Vector3.new(0, 2, 0), p)
			local delta = goal - target.Position
			if floor and not workspace:Blockcast(target.CFrame, Vector3.new(2.3, 2.7, 2.3), delta, p) then
				goal = Vector3.new(goal.X, floor, goal.Z)
				local old = root.CFrame
				root.CFrame = CFrame.lookAt(goal, Vector3.new(target.Position.X, floor, target.Position.Z))
				 
				do
					local arrival = root.Position
					core.Afterimage(old)
					for fraction = 0.25, 0.75, 0.25 do
						core.Afterimage(CFrame.new(old.Position:Lerp(arrival, fraction)) * old.Rotation)
					end
					core.MotionLine("GoldenParryTeleportGlow", old.Position, arrival, 3, DEEP, 0.3)
					core.MotionLine("GoldenParryTeleport", old.Position, arrival, 1.2, GOLD, 0.35)
					core.MotionLine("GoldenParryTeleportCore", old.Position, arrival, 0.3, BRIGHT, 0.3)
					glowBall(old.Position, 9, 0.25, BRIGHT)
					sparkBurst(old.Position, 16, 10, 24)
					glowBall(arrival, 9, 0.25, BRIGHT)
					sparkBurst(arrival, 16, 10, 24)
					disc(Vector3.new(goal.X, floor + 0.15, goal.Z), 3, 20, 0.35, GOLD, 0.4)
				end
				b:SetAttribute(
					"LastParryBehindDot",
					target.CFrame.LookVector:Dot((root.Position - target.Position).Unit)
				)
				return true
			end
		end
		return false
	end
	function api.Counter(char)
		if not core.Alive(char) or Status.IsDebuffImmune(char) or not api.MoveBehind(char) then
			return false
		end
		local player = Players:GetPlayerFromCharacter(char)
		local other = char:FindFirstChildOfClass("Humanoid")
		local target = char.HumanoidRootPart
		local old = {
			Anchored = target.Anchored,
			WalkSpeed = other.WalkSpeed,
			JumpPower = other.JumpPower,
			JumpHeight = other.JumpHeight,
			AutoRotate = other.AutoRotate,
		}
		char:SetAttribute("ParryFrozen", true)
		Time.SetAnchored(target, true)
		other.WalkSpeed = 0
		other.JumpPower = 0
		other.JumpHeight = 0
		other.AutoRotate = false
		 
		local sword = b:FindFirstChild("Basic Sword")
		local blade = sword and sword:FindFirstChild("Blade")
		local slashTrail = blade and blade:FindFirstChild("SlashTrail")
		local bind, mark, bladeLight
		local function victimFloor()
			return target.Position - Vector3.new(0, other.HipHeight + target.Size.Y * 0.5 - 0.15, 0)
		end
		local function restore()
			if target.Parent then
				Time.SetAnchored(target, old.Anchored)
			end
			if other.Parent then
				other.WalkSpeed = old.WalkSpeed
				other.JumpPower = old.JumpPower
				other.JumpHeight = old.JumpHeight
				other.AutoRotate = old.AutoRotate
			end
			if char.Parent then
				char:SetAttribute("ParryFrozen", false)
			end
			if player and player.Parent then
				core.ScreenEffect("ParryEnd", {}, player)
			end
			if bind then
				bind:Dispose()
			end
			if mark then
				mark:Destroy()
			end
			if bladeLight then
				bladeLight:Destroy()
			end
			if slashTrail then
				slashTrail.Enabled = false
			end
		end
		 
		local slashVfx = Visuals.slashVfx({
			root = root,
			slashLine = slashLine,
			glowBall = glowBall,
			BRIGHT = BRIGHT,
			sparkBurst = sparkBurst,
			victimFloor = victimFloor,
			disc = disc,
			GOLD = GOLD,
			radial = radial,
			core = core,
			Effects = Effects,
			Debris = Debris,
		})
		local ok, result = xpcall(function()
			local function waitCounter(seconds)
				local untilAt = Time.ActionNow(actor) + seconds
				repeat
					if Status.IsDebuffImmune(char) or not core.Alive(char) or not core.Active() then
						return false
					end
					if Time.ActionNow(actor) >= untilAt then
						return true
					end
					Run.Heartbeat:Wait()
				until false
			end
			b:SetAttribute("AttackState", "Golden Parry: Too late...")
			if player then
				core.ScreenEffect("ParryStart", { Duration = 2.8, Text = "Too late..." }, player)
			end

			 
			local windup = true
			mark = Instance.new("Highlight")
			mark.Name = "GoldenParryStasis"
			mark.Adornee = char
			mark.FillColor = GOLD
			mark.FillTransparency = 0.85
			mark.OutlineColor = BRIGHT
			mark.OutlineTransparency = 0.3
			mark.DepthMode = Enum.HighlightDepthMode.Occluded
			mark.Parent = char
			if blade then
				bladeLight = Instance.new("PointLight")
				bladeLight.Color = GOLD
				bladeLight.Brightness = 0
				bladeLight.Range = 8
				bladeLight.Parent = blade
				Effects:Create(
					bladeLight,
					TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Brightness = 5, Range = 22 }
				):Play()
			end
			bind = Effects.NewCast(actor, "GoldenParryBindVfx", 10)
			local orbs = {}
			for i = 1, 6 do
				local orb = bind:Add(
					core.Part(
						"GoldenParryBindOrb",
						CFrame.new(target.Position),
						Vector3.one * 0.9,
						i % 2 == 0 and GOLD or BRIGHT,
						0.1
					)
				)
				orb.Shape = Enum.PartType.Ball
				orb.Material = Enum.Material.Neon
				orbs[i] = orb
			end
			local elapsed, streakTimer, ringTimer = 0, 0, 0
			bind:Step(function(dt)
				if not target.Parent then
					return false
				end
				elapsed += dt
				for i, orb in ipairs(orbs) do
					local angle = elapsed * 3 + i * math.pi / 3
					orb.CFrame = CFrame.new(
						target.Position
							+ Vector3.new(math.cos(angle) * 4.5, math.sin(elapsed * 2 + i) * 2.2, math.sin(angle) * 4.5)
					)
				end
				if windup then
					streakTimer += dt
					ringTimer += dt
					if streakTimer >= 0.06 then
						streakTimer = 0
						local center = blade and blade.Position or root.Position
						for _ = 1, 2 do
							local dir =
								Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1))
							dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
							local radius = rng:NextNumber(8, 14)
							core.MotionLine(
								"GoldenParryChargeStreak",
								center + dir * radius,
								center + dir * radius * 0.25,
								0.12,
								rng:NextNumber() > 0.5 and GOLD or BRIGHT,
								0.18
							)
						end
					end
					if ringTimer >= 0.3 then
						ringTimer = 0
						disc(victimFloor(), 18, 3, 0.35, GOLD, 0.5)
					end
				end
				return true
			end)

			melee.Pose("Windup3", 0.15)
			if not waitCounter(0.9) then
				return false
			end
			windup = false
			if blade then
				glowBall(blade.Position, 9, 0.2, BRIGHT)
			end
			if slashTrail then
				slashTrail.Enabled = true
			end
			local dealt = 0
			local counterHits = Difficulty.Design("GoldenParry", "CounterHits", 3, actor)
			for index = 1, counterHits do
				if not core.Active() or not core.Alive(char) then
					return false
				end
				melee.Pose("Slash" .. index, 0.1)
				melee.Crescent(root.CFrame, index)
				Audio.Emit(actor, "CounterImpact", target, { Pitch = 0.95 + index * 0.03 })
				slashVfx(index, target.Position)
				if not char:GetAttribute("Invulnerable") and not char:FindFirstChildOfClass("ForceField") then
					local amount = (b:GetAttribute("ParryCounterDamage") or Config.ParryCounterDamage) / 3  
					dealt += core.Damage(char, amount)
				end
				if not waitCounter(0.24) then
					return false
				end
			end
			if dealt>0 then AttackDebuffs.Apply(actor,char,"Vulnerability",3) end
    
			glowBall(target.Position, 12, 0.3, BRIGHT)
			sparkBurst(target.Position, 26, 10, 28)
			b:SetAttribute("LastParryDamage", dealt)
			b:SetAttribute("GoldenParryCounters", (b:GetAttribute("GoldenParryCounters") or 0) + 1)
			return true
		end, debug.traceback)
		restore()
		if not ok then
			warn("Golden Parry counter failed: " .. tostring(result))
		end
		return ok and result
	end
	function api.Combo(char)
		if not api.CanUse(char) then
			return false
		end
		local result = core.Perform(char, "Golden Parry", function()
			attacker = nil
			guarding = true
			deadline = Time.ActionNow(actor) + (b:GetAttribute("ParryGuardTime") or 5)
			flare = 0
			b:SetAttribute("ParryActive", true)
			b:SetAttribute("AttackState", "Golden Parry: defending")
			Audio.Emit(actor, "ParryStance", root)
			core.PoseAngles(
				{
					RightShoulder = { 40, 0, 55 },
					RightElbow = { 65, 0, 0 },
					LeftShoulder = { 35, 0, -45 },
					LeftElbow = {
						60,
						0,
						0,
					},
				},
				0.15
			)
			local aura =
				core.Part("GoldenParryGuard", root.CFrame, Vector3.new(6, 6, 6), Color3.fromRGB(255, 224, 85), 0.85)
			aura.Shape = Enum.PartType.Ball
			aura.Material = Enum.Material.Neon
			 
			local extras = {}
			local function addExtra(object)
				table.insert(extras, object)
				return object
			end
			local light = Instance.new("PointLight")
			light.Color = GOLD
			light.Brightness = 1.5
			light.Range = 18
			light.Parent = aura
			local drift = Instance.new("ParticleEmitter")
			drift.Name = "GoldenParryEmbers"
			drift.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			drift.Color = ColorSequence.new(BRIGHT, GOLD)
			drift.LightEmission = 1
			drift.Rate = 10
			drift.SpreadAngle = Vector2.new(180, 180)
			drift.Lifetime = NumberRange.new(0.6, 1.2)
			drift.Speed = NumberRange.new(2, 5)
			drift.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
			drift.Parent = aura
			local orbs = {}
			for i = 1, 4 do
				local orb = addExtra(
					core.Part("GoldenParryOrbit", root.CFrame, Vector3.one * 0.9, i % 2 == 0 and GOLD or BRIGHT, 0.1)
				)
				orb.Shape = Enum.PartType.Ball
				orb.Material = Enum.Material.Neon
				orbs[i] = orb
			end
			local function feetPosition()
				return root.Position - Vector3.new(0, h.HipHeight + root.Size.Y * 0.5 - 0.15, 0)
			end
			local ring = addExtra(
				core.Part(
					"GoldenParryFloorRing",
					CFrame.new(feetPosition()) * CFrame.Angles(0, 0, math.pi / 2),
					Vector3.new(0.2, 11, 11),
					GOLD,
					0.55
				)
			)
			ring.Shape = Enum.PartType.Cylinder
			ring.Material = Enum.Material.Neon
			Effects:Create(
				ring,
				TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Size = Vector3.new(0.2, 13, 13), Transparency = 0.8 }
			):Play()
			local sword = b:FindFirstChild("Basic Sword")
			local blade = sword and sword:FindFirstChild("Blade")
			if blade then
				local bladeLight = addExtra(Instance.new("PointLight"))
				bladeLight.Color = GOLD
				bladeLight.Brightness = 2
				bladeLight.Range = 14
				bladeLight.Parent = blade
			end
			local function cleanupGuard()
				Debris:AddItem(aura, 0)
				for _, object in ipairs(extras) do
					Debris:AddItem(object, 0)
				end
			end
			local begin = Time.ActionNow(actor)
			local pulseTimer = 0
			while Time.ActionNow(actor) < deadline and not attacker do
				if not core.Active() or not core.Alive(char) then
					cleanupGuard()
					return false
				end
				core.Face(char)
				aura.CFrame = root.CFrame
				local dt = Run.Heartbeat:Wait()
				local t = Time.ActionNow(actor) - begin
				 
				flare = math.max(0, flare - dt * 4)
				aura.Transparency = math.clamp(0.85 - 0.55 * flare + 0.03 * math.sin(t * 6), 0, 1)
				aura.Size = Vector3.one * (6 + flare * 2.5 + math.sin(t * 3) * 0.25)
				light.Brightness = 1.5 + 3 * flare
				for i, orb in ipairs(orbs) do
					local angle = t * 2.5 + i * math.pi / 2
					orb.CFrame = CFrame.new(
						root.Position + Vector3.new(math.cos(angle) * 5, math.sin(t * 3 + i) * 1.5, math.sin(angle) * 5)
					)
				end
				ring.CFrame = CFrame.new(feetPosition()) * CFrame.Angles(0, 0, math.pi / 2)
				pulseTimer += dt
				if pulseTimer >= 1 then
					pulseTimer = 0
					disc(feetPosition(), 4, 22, 0.6, GOLD, 0.5)
				end
			end
			guarding = false
			b:SetAttribute("ParryActive", false)
			cleanupGuard()
			b:SetAttribute("LastParryGuardDuration", Time.ActionNow(actor) - begin)
			if attacker then
				 
				glowBall(root.Position, 14, 0.3, BRIGHT)
				disc(feetPosition(), 6, 30, 0.4, GOLD, 0.3)
				sparkBurst(root.Position, 24, 10, 26)
				return api.Counter(attacker)
			end
			 
			disc(feetPosition(), 10, 26, 0.4, GOLD, 0.5)
			glowBall(root.Position, 8, 0.25, GOLD)
			b:SetAttribute("ParryGuardsCompleted", (b:GetAttribute("ParryGuardsCompleted") or 0) + 1)
			return true
		end)
		guarding = false
		attacker = nil
		b:SetAttribute("ParryActive", false)
		return result
	end
	return api
end
