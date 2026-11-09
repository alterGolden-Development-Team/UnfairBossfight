local script = script.Parent
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local function opt(name, default)
	local value = Config[name]
	if value == nil then
		return default
	end
	return value
end

local function rootOf(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function steer(direction, desired, maxAngle)
	local angle = math.acos(math.clamp(direction:Dot(desired), -1, 1))
	if angle <= maxAngle then
		return desired
	end
	local blended = direction:Lerp(desired, maxAngle / angle)
	if blended.Magnitude < 1e-3 then
		return direction
	end
	return blended.Unit
end

return function(actor)
	 
	local burnAt = setmetatable({}, { __mode = "k" })

	local function spawnPool(ctx, center)
		local duration = Config.P1FireBurnDuration
		local fullRadius = Config.P1FireBurnRadius
		local fireCast = ctx.Cast("P1FireBulletFlames", duration)

		local updatePool = Visuals.Pool(ctx, fireCast, center, fullRadius)
		local GROW, FADE = 0.25, 0.7
		local age, scan, flare = 0, 0, 0
		fireCast:Step(function(dt)
			if not ctx.Valid() then
				fireCast:Dispose()
				return false
			end
			age += dt
			scan += dt
			flare = math.max(0, flare - dt * 3)

			 
			local grown = math.min(age / GROW, 1)
			local fade = math.clamp((duration - age) / FADE, 0, 1)
			local scale = (0.3 + 0.7 * (1 - (1 - grown) ^ 2)) * (0.45 + 0.55 * fade)
			local radius = fullRadius * scale
			local pulse = 0.5 + 0.5 * math.sin(age * 9)

			updatePool(radius, fade, flare, pulse)

			if scan < 0.1 then
				return true
			end
			scan = 0
			local now = os.clock()
			for _, char in ipairs(ctx.Targets()) do
				local root = rootOf(char)
				if root then
					local delta = root.Position - center
					if
						Vector3.new(delta.X, 0, delta.Z).Magnitude <= radius
						and math.abs(delta.Y) <= 6
						and now >= (burnAt[char] or 0)
					then
						burnAt[char] = now + Config.P1FireBurnInterval
						ctx.Damage(char, Config.P1FireBurnDamage, "P1FireBulletBurn")
						flare = 1  
					end
				end
			end
			return true
		end)
	end

	local function explode(ctx, cast, position, direction)
		local radius = Config.P1FireExplosionRadius
		Visuals.Explosion(ctx, cast, position, radius)

		 
		local probe = position - direction * 0.75 + Vector3.new(0, 0.2, 0)
		for _, char in ipairs(ctx.Targets()) do
			local root = rootOf(char)
			if root then
				local point = root.Position
				if
					(point - position).Magnitude <= radius
					and not workspace:Raycast(probe, point - probe, ctx.Filter())
				then
					ctx.Damage(char, Config.P1FireBulletDamage, "P1FireBullet")
				end
			end
		end

		local floor = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), ctx.Filter())
		if floor and floor.Normal.Y >= 0.5 then
			spawnPool(ctx, floor.Position + Vector3.new(0, 0.12, 0))
		end
	end

	return Shared.Skill(actor, "Elementalist", "P1FireBullet", Config.P1FireBulletCooldown, function(ctx, target)
		if not ctx.Core.Alive(target) then
			target = ctx.Targets()[1]
		end
		if not target then
			return false
		end
		ctx.Core.Face(target)
		ctx.Core.PoseAngles({ RightShoulder = { 85, 0, -25 }, LeftShoulder = { 65, 0, 25 } }, 0.1)

		local count = Config.P1FireBulletCount
		local spacing = Config.P1FireBulletSpacing
		local lifetime = Config.P1FireBulletLifetime
		local speed = Config.P1FireBulletSpeed
		local windup = opt("P1FireBulletWindup", 0.35)
		local spreadRad = math.rad(opt("P1FireBulletSpreadDeg", 8))
		local leadFactor = opt("P1FireBulletLead", 0.5)
		local turnRate = opt("P1FireBulletTurnRate", 1.0)
		local sweepSign = math.random(2) == 1 and 1 or -1

		local volleyEnd = windup + (count - 1) * spacing
		local cast = ctx.Cast("P1FireBullet", volleyEnd + lifetime + Config.P1FireBurnDuration + 1)

		 
		local function muzzle()
			return ctx.HandPosition("Right") + ctx.Root.CFrame.LookVector * 0.6
		end

		 
		 
		 
		local orb, kickMuzzle = Visuals.Charge(ctx, cast, muzzle, windup, volleyEnd)

		 
		 
		 
		local function fireBullet(index)
			if not ctx.Valid() or not ctx.Core.Alive(target) then
				return
			end
			local targetRoot = rootOf(target)
			if not targetRoot then
				return
			end

			kickMuzzle()

			local origin = orb.Position
			local aim = targetRoot.Position
			local velocity = targetRoot.AssemblyLinearVelocity
			local travelTime = (aim - origin).Magnitude / speed
			local lead = Vector3.new(velocity.X, 0, velocity.Z) * travelTime * leadFactor
			if lead.Magnitude > 10 then
				lead = lead.Unit * 10
			end

			local delta = aim + lead - origin
			if delta.Magnitude < 0.01 then
				return
			end

			 
			local t = count > 1 and (index - 1) / (count - 1) or 0.5
			local yaw = (t - 0.5) * 2 * spreadRad * sweepSign
			local direction = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(delta.Unit)

			local bullet, retire = Visuals.Bullet(ctx, cast, origin)

			local position, age, heading = origin, 0, direction
			cast:Step(function(dt)
				if not ctx.Valid() then
					cast:Dispose()
					return false
				end
				age += dt

				 
				local turn = turnRate * math.max(0, 1 - age / (lifetime * 0.6))
				if turn > 0 and ctx.Core.Alive(target) then
					local root = rootOf(target)
					if root then
						local want = root.Position - position
						if want.Magnitude > 0.5 then
							heading = steer(heading, want.Unit, turn * dt)
						end
					end
				end

				local nextPosition, _, hit = ctx.Sweep(position, heading * speed * dt, 2.4)
				bullet.CFrame = CFrame.new(nextPosition)
				bullet.Size = Vector3.one * (1.1 + 0.18 * math.sin(age * 32))
				position = nextPosition

				if hit then
					retire()
					explode(ctx, cast, position, heading)
					return false
				end
				if age >= lifetime then
					retire()
					Visuals.Fizzle(ctx, cast, position)
					return false
				end
				return true
			end)
		end

		for index = 1, count do
			cast:Schedule(windup + (index - 1) * spacing, function()
				fireBullet(index)
			end)
		end

		actor:SetAttribute("P1FireBulletVolleyCount", count)
		return ctx.Wait(windup + 0.7)
	end)
end
