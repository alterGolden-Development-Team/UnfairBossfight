local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
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

return function(actor)
	return Shared.Skill(actor, "Swordsmaster", "P1KnifeBarrage", Config.P1KnifeBarrageCooldown, function(ctx, target)
		if not ctx.Core.Alive(target) then
			target = ctx.Targets()[1]
		end
		if not target then
			return false
		end
		ctx.Core.Face(target)

		local count = Config.P1KnifeCount
		local lifetime = Config.P1KnifeLifetime
		local speed = Config.P1KnifeSpeed
		local flipTime = Config.P1KnifeBackflipDuration
		local hang = opt("P1KnifeHang", 0.22)
		local stagger = opt("P1KnifeStagger", 0.012)
		local pierce = opt("P1KnifePierce", false)
		local flipHeight = opt("P1KnifeFlipHeight", 4)
		local throwAlpha = opt("P1KnifeThrowAlpha", 0.45)

		local cast = ctx.Cast("P1KnifeBarrage", flipTime + hang + stagger * count + lifetime + 1)
		local from = ctx.Root.CFrame
		local landing = Placement.Validate(
			actor,
			from * CFrame.new(0, 0, Config.P1KnifeBackflipDistance),
			{ Margin = 6 }
		) or from
		local elapsed, thrown, landed = 0, false, false

		 
		 
		 
		local trailAnchor, flipTrail = Visuals.Ribbon(ctx, cast, from)

		Visuals.GroundBurst(ctx, cast, from.Position)

		 
		 
		 
		local function conjure()
			local targetRoot = rootOf(target)
			if not targetRoot or not ctx.Core.Alive(target) then
				return
			end
			local origin = ctx.Root.Position + Vector3.new(0, 1, 0)
			local delta = targetRoot.Position - origin
			if delta.Magnitude < 0.01 then
				return
			end
			local aimDirection = delta.Unit
			local aim = CFrame.lookAt(Vector3.zero, aimDirection)

			local knives = {}
			for index = 1, count do
				 
				local radius = math.sqrt((index - 1) / math.max(1, count - 1))
					* math.tan(math.rad(Config.P1KnifeSpreadDegrees))
				local angle = index * 2.399963
				local direction =
					aim:VectorToWorldSpace(Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, -1)).Unit

				 
				local hover = origin + direction * 1.6
				local frame = CFrame.lookAt(hover, hover + direction)
				local blade, grip, trail, sparks = Visuals.Knife(ctx, cast, frame)

				knives[index] = {
					Position = hover,
					Direction = direction,
					Blade = blade,
					Grip = grip,
					Trail = trail,
					Sparks = sparks,
					Delay = hang + (index - 1) * stagger,
					Roll = 0,
					Spin = (math.random(2) == 1 and 1 or -1) * (10 + math.random() * 6),
					State = "hang",  
					Hits = {},
				}
			end
			actor:SetAttribute("P1KnifeBarrageVolleyCount", #knives)
			local frames = table.create(#knives)
			for i, knife in ipairs(knives) do
				frames[i] = knife.Blade.CFrame
			end
			Visuals.Summon(ctx, cast, origin, aimDirection, frames, hang)

			local age, released = 0, false

			 
			local function settle(knife, hold, burst)
				knife.State = "settled"
				knife.SettledAt = age + hold
				knife.Trail.Enabled = false
				if burst > 0 then
					knife.Sparks:Emit(burst)
				end
			end

			cast:Step(function(dt)
				if not ctx.Valid() then
					cast:Dispose()
					return false
				end
				age += dt

				if not released and age >= hang then
					released = true
					Visuals.Release(ctx, cast, origin, aimDirection)
				end

				local remaining = 0
				for _, knife in ipairs(knives) do
					local state = knife.State

					if state == "hang" then
						remaining += 1
						local appear = 1 - math.clamp(age / math.max(hang * 0.8, 0.01), 0, 1)
						knife.Blade.Transparency, knife.Grip.Transparency = appear, appear
						if age >= knife.Delay then
							knife.State = "fly"
							knife.Trail.Enabled = true
						end
					elseif state == "fly" then
						remaining += 1
						knife.Roll += knife.Spin * dt
						local position, hit, blocked = ctx.Sweep(knife.Position, knife.Direction * speed * dt, 1.5)
						knife.Position = position
						local frame = CFrame.lookAt(position, position + knife.Direction)
							* CFrame.Angles(0, 0, knife.Roll)
						knife.Blade.CFrame, knife.Grip.CFrame = frame, frame * CFrame.new(0, 0, 1.3)

						 
						if hit and not knife.Hits[hit] then
							knife.Hits[hit] = true
							if ctx.Damage(hit, Config.P1KnifeDamage, "P1KnifeBarrage") > 0 then
        AttackDebuffs.Apply(actor,hit,"Bleed",3,cast)
								Visuals.Hit(ctx, cast, position, knife.Direction)
							end
							if not pierce then
								settle(knife, 0, 14)
							end
						end
						if knife.State == "fly" then
							if blocked then
								settle(knife, 0.35, 10)  
								Visuals.Clink(ctx, cast, position, knife.Direction)
							elseif age - knife.Delay >= lifetime then
								settle(knife, 0, 0)
							end
						end
					elseif state == "settled" then
						local fade = (age - knife.SettledAt) / 0.15
						if fade >= 1 then
							knife.State = "done"
							knife.Blade.Transparency, knife.Grip.Transparency = 1, 1
						else
							remaining += 1
							local alpha = math.max(fade, 0)
							knife.Blade.Transparency, knife.Grip.Transparency = alpha, alpha
						end
					end
				end
				return remaining > 0
			end)
		end

		cast.OnDispose = function()
			if not landed and ctx.Root.Parent and ctx.Valid() then
				ctx.Root.CFrame = landing
			end
		end

		 
		 
		 
		ctx.Core.PoseAngles({ RightShoulder = { 135, 0, -25 }, LeftShoulder = { 135, 0, 25 } }, 0.1)
		cast:Step(function(dt)
			if not ctx.Valid() then
				cast:Dispose()
				return false
			end
			elapsed += dt
			local alpha = math.clamp(elapsed / flipTime, 0, 1)
			local desired = from:Lerp(landing, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * flipHeight, 0)
			local travel = desired.Position - ctx.Root.Position
			if
				travel.Magnitude > 0.001
				and workspace:Blockcast(CFrame.new(ctx.Root.Position), Vector3.new(3, 3, 3), travel, ctx.Filter())
			then
				landing = Placement.Validate(actor, ctx.Root.CFrame, { Margin = 6 }) or from
				alpha = 1
				desired = landing
			end
			ctx.Root.CFrame = desired * CFrame.Angles(2 * math.pi * alpha, 0, 0)
			ctx.Root.AssemblyLinearVelocity = Vector3.zero
			trailAnchor.CFrame = ctx.Root.CFrame
			if ctx.Core.Afterimage then
				ctx.Core.Afterimage(ctx.Root.CFrame)
			end

			if not thrown and alpha >= throwAlpha then
				thrown = true
				conjure()
			end
			if alpha >= 1 then
				landed = true
				ctx.Root.CFrame = landing
				flipTrail.Enabled = false
				Visuals.GroundBurst(ctx, cast, landing.Position)
				return false
			end
			return true
		end)
		return ctx.Wait(flipTime + 0.05)
	end)
end
