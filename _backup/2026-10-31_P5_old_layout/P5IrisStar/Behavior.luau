local B = script:FindFirstAncestor("BossSystem")
local A = require(B.Attacks.Shared.P5AstralCore)
local S = require(script.Parent.Style)
local Visuals = require(script.Parent.Visuals)
local Status = require(B.Combat.StatusEffectService)

local function flat(a, b)
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

return function(actor)
	local current
	local api = { Cooldown = S.Cooldown, ManagesCooldown = true }

	function api.CanUse(target)
		return A.Ready(actor, S, current, target)
	end

	function api.Combo(target)
		local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Tell={"Windup"},Rate={"TickInterval"}})  -- difficulty knobs, this cast only
		if not api.CanUse(target) then
			return false
		end
		local core = require(B.Combat.AttackRegistry).For(actor, "P1CombatCore")
		local total = S.Windup + S.RadianceTime + S.CollapseTime + S.Outro
		return core.Perform(target, S.Name, function()
			A.StartCooldown(actor, S)
			local fx
			local ctx = A.Create(actor, S, total + 0.3, function()
				current = nil
				actor:SetAttribute("IrisStarActive", false)
				if fx then Visuals.Finish(fx) end
			end)
			current = ctx.Cast
			actor:SetAttribute("IrisStarActive", true)

			local root = core.Root
			local ignore = { actor }
			for _, char in ipairs(ctx.Targets()) do table.insert(ignore, char) end
			local groundY = Visuals.Ground(root.Position, ignore)
			fx = Visuals.Build(ctx, root, S)
			pcall(core.PoseAngles, { RightShoulder = { 150, 0, -30 }, LeftShoulder = { 150, 0, 30 }, Waist = { -12, 0, 0 } }, S.Windup * .7)

			local lock -- star position frozen at collapse
			local collapsed, exploded = false, false
			local function star()
				return lock or root.Position + Vector3.yAxis * S.Height
			end
			local function groundUnderStar()
				local e = star()
				return Vector3.new(e.X, groundY, e.Z)
			end

			ctx.Send("Start", {
				Duration = S.Windup + S.RadianceTime + S.CollapseTime,
				Windup = S.Windup,
				CollapseAt = S.Windup + S.RadianceTime,
				Pupil = S.PupilRadius,
			})

			local groundTimer = 0
			local nextTick = S.Windup
			ctx.Step(function(dt, elapsed)
				if not ctx.Valid() or not root.Parent then
					ctx.Cast:Dispose()
					return false
				end
				local a = elapsed - S.Windup
				if not lock then
					groundTimer -= dt
					if groundTimer <= 0 then
						groundTimer = .25
						groundY = Visuals.Ground(root.Position, ignore)
					end
				end
				 -- proximity burn: the closer to the star, the harder each tick
				if not exploded and elapsed >= nextTick then
					nextTick = elapsed + S.TickInterval
					local st = star()
					for _, char in ipairs(ctx.Targets()) do
						local pr = char:FindFirstChild("HumanoidRootPart")
						local d = pr and (pr.Position - st).Magnitude
						if d and d < S.BlindRange then
							local k = 1 - math.clamp((d - S.BlindInner) / (S.BlindRange - S.BlindInner), 0, 1)
							local dmg = S.TickMax * k ^ S.TickCurve * (collapsed and 1.5 or 1)
							if dmg >= 0.5 then ctx.Damage(char, dmg, true, pr.Position) end
						end
					end
				end
				if not collapsed and a >= S.RadianceTime then
					collapsed = true
					lock = star()
					Visuals.Send(fx, "Collapse", { Eye = lock, Center = groundUnderStar(), Time = S.CollapseTime, Pupil = S.PupilRadius, Blast = S.BlastRadius })
				end
				if collapsed and not exploded and a >= S.RadianceTime + S.CollapseTime then
					exploded = true
					local c = groundUnderStar()
					for _, char in ipairs(ctx.Targets()) do
						local pr = char:FindFirstChild("HumanoidRootPart")
						if pr and flat(pr.Position, c) <= S.BlastRadius and flat(pr.Position, c) > S.PupilRadius then
							ctx.Damage(char, S.BlastDamage, false, c)
							Status.ApplySlow(char, S.SupernovaSlow, S.SupernovaSlowSeconds, "P5IrisStarNova")
						end
					end
					ctx.Send("Burst", { Center = c })
					Visuals.Send(fx, "Supernova", { Eye = star(), Center = c, Pupil = S.PupilRadius, Blast = S.BlastRadius })
					Visuals.Sound(fx, "Boom", star(), 1, .5, 5)
				end
				if a >= S.RadianceTime + S.CollapseTime + S.Outro then
					ctx.Cast:Dispose()
					return false
				end
				return true
			end)
			return ctx.WaitFor(S.Windup)
		end)
	end

	function api.Dispose()
		if current then
			current:Dispose()
		end
	end

	return api
end
