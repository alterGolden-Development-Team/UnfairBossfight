local script = script.Parent
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Control = require(BossSystem.Attacks.Shared.ShieldBreakControl)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local function opt(name, default)
	local value = Config[name]
	if value == nil then
		return default
	end
	return value
end

 
 
 
 
local RANGE_SCALE = opt("P1TornadoLeafRangeScale", 1.6)  
local WIDTH_SCALE = opt("P1TornadoLeafWidthScale", 2.5)  
local SHOW_LANE = opt("P1TornadoLeafLane", true)  

return function(actor)
	return Shared.Skill(
		actor,
		"Elementalist",
		"P1TornadoLeaf",
		Config.ShieldGateCloneAttackInterval,
		function(ctx, target)
			if not ctx.Core.Alive(target) then
				target = ctx.Targets()[1]
			end
			if not target then
				return false
			end
			ctx.Core.Face(target)
			ctx.Core.PoseAngles({ RightShoulder = { 110, 0, -55 }, LeftShoulder = { 110, 0, 55 } }, 0.15)
			local windup = Config.P1TornadoLeafWindup
			local lifetime = Config.P1TornadoLeafLifetime * RANGE_SCALE
			local radius = math.max(12, Config.P1TornadoLeafRadius * WIDTH_SCALE)
			actor:SetAttribute("P1TornadoLeafHitRadius",radius)
			actor:SetAttribute("P1TornadoLeafHeight",26)
			local speed = Config.P1TornadoLeafSpeed
			local cast = ctx.Cast("P1TornadoLeaf", windup + lifetime)
			local view = Visuals.Create(ctx, cast, {
				Radius = radius,
				Windup = windup,
				Lifetime = lifetime,
				Range = speed * lifetime,
				Lane = SHOW_LANE,
			})
			local function palms()
				return (ctx.HandPosition("Right") + ctx.HandPosition("Left")) * 0.5 + ctx.Root.CFrame.LookVector * 1.5
			end
			 
			local function aimHeading(from)
				local rootPart = ctx.Core.Alive(target) and target:FindFirstChild("HumanoidRootPart")
				local aim = rootPart and rootPart.Position or from + ctx.Root.CFrame.LookVector * 60
				local flat = Vector3.new(aim.X - from.X, 0, aim.Z - from.Z)
				return flat.Magnitude > 0.01 and flat.Unit or ctx.Root.CFrame.LookVector
			end
			local center = palms()
			local heading, age = nil, 0
			local hit = {}
			cast:Step(function(dt)
				if not ctx.Valid() then
					cast:Dispose()
					return false
				end
				age += dt
				local previous = center
				if age < windup then
					center = palms()
				else
					if not heading then
						heading = aimHeading(center)
						actor:SetAttribute("P1TornadoLeafLaunchedAt", workspace:GetServerTimeNow())
						view.Launch(center, heading)
					end
					center += heading * speed * math.min(dt, 0.1)
					 
					local segment = center - previous
					for _, char in ipairs(ctx.Targets()) do
						local rootPart = char:FindFirstChild("HumanoidRootPart")
						if rootPart and not hit[char] then
							local point = rootPart.Position
							local a = math.clamp(
								(point - previous):Dot(segment) / math.max(segment:Dot(segment), 0.001),
								0,
								1
							)
							local delta = point - (previous + segment * a)
							if Vector3.new(delta.X, 0, delta.Z).Magnitude <= radius and delta.Y >= -4 and delta.Y <= 22 then
								hit[char] = true
								if ctx.Damage(char, Config.P1TornadoLeafDamage, "P1TornadoLeaf") > 0 then
									view.Hit(char)
									Control.Apply(ctx,char,math.max(1.2,Config.P1TornadoLeafTripDuration),true,heading,{Speed=65,Lift=75})
								end
							end
						end
					end
				end
				view.Update(center, age, heading or aimHeading(center))
				return true
			end)
			return ctx.Wait(windup + 0.1)
		end
	)
end
