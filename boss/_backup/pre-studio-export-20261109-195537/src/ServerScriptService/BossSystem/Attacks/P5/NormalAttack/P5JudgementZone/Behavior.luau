local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Effects = require(B.Combat.EffectService)
local Audio = require(B.Presentation.CombatAudio)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local CollectionService = game:GetService("CollectionService")
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local POINT = { RightShoulder = { 100, 0, -10 }, RightElbow = { 0, 0, 0 }, RightWrist = { -10, 0, 0 }, LeftShoulder = { 15, 0, -25 },
	Waist = { 0, -20, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local active
	function api.CanUse(target)
		return c.CanStart(target) and not (active and active:Alive())
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(POINT, 0.12)
			actor:SetAttribute("AttackState", "Judgement Zone")
			if not c.Wait(c.Tell(S.Tell)) then
				return false
			end
			 -- a zone under each of them: a replicated marker part the clients draw (VFXEngine.Effects.P5Arsenal Decorate)
			local zones = {}
			local endsAt = workspace:GetServerTimeNow() + S.Timer
			local cast = Effects.NewCast(actor, S.Name, S.Timer + S.Flash + 1)
			cast.PersistsThroughEmitterStun = true
			for _, char in ipairs(c.Targets()) do
			for k = 1, S.PerPlayer do
				local at = c.Ground(char.HumanoidRootPart.Position)
				local part = Instance.new("Part")
				part.Name = "P5JudgementZone"
				part.Anchored = true part.CanCollide = false part.CanQuery = false part.CanTouch = false part.CastShadow = false
				part.Transparency = 1 part.Size = Vector3.one part.CFrame = CFrame.new(at)
				part:SetAttribute("VFX", "P5Arsenal")
				part:SetAttribute("Kind", "Judgement")
				part:SetAttribute("Radius", S.Radius)
				part:SetAttribute("EndsAt", endsAt)
				part:SetAttribute("State", "Hunt")
				part.Parent = workspace
				CollectionService:AddTag(part, "VFXDecorate")
				cast:Add(part)
				zones[#zones + 1] = { Part = part, Char = char, Pos = at, Phase = (k - 1) * math.pi * 2 / S.PerPlayer }
			end
			end
			pcall(Audio.Emit, actor, "TeleportWarp", c.Root)
			active = cast
			local t = 0
			cast:Step(function(dt)
				t += dt
				if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then
					cast:Dispose()
					return false
				end
				local live = false
				for _, z in ipairs(zones) do
					if not z.Done then
						live = true
						if t < S.Timer then
							 -- the hunt: it slides after its player
							local r = z.Char.Parent and z.Char:FindFirstChild("HumanoidRootPart")
							if r and core.Alive(z.Char) then
								 -- where they will be, plus this zone's place on a circle round them
								local v = r.AssemblyLinearVelocity * FLAT
								local spin = z.Phase + t * S.OrbitSpeed
								local goal = c.Ground(r.Position + v * S.Lead + Vector3.new(math.cos(spin), 0, math.sin(spin)) * S.Orbit)
								local d = (goal - z.Pos) * FLAT
								if d.Magnitude > 0.05 then
									z.Pos += d.Unit * math.min(d.Magnitude, S.Speed * dt)
								end
								z.Pos = Vector3.new(z.Pos.X, goal.Y, z.Pos.Z)
								z.Part.CFrame = CFrame.new(z.Pos)
							end
						elseif not z.Red then
							z.Red = true  -- it stops dead and goes red
							z.Part:SetAttribute("State", "Red")
						elseif t >= S.Timer + S.Flash then
							z.Done = true
							Net.Send("P5Arsenal", "JudgementBoom", { Boss = actor, Pos = z.Pos, Radius = S.Radius })
							core.ScreenEffect("Shake", { Origin = z.Pos, Radius = 240, Intensity = 1.6, Duration = 0.45 })
							for _, char in ipairs(c.Targets()) do
								local rel = char.HumanoidRootPart.Position - z.Pos
								local flat = rel * FLAT
								if flat.Magnitude <= S.Radius and rel.Y <= 18 then
									c.Hit(char, S.Damage, z.Pos + Vector3.new(0, 2, 0), { Knock = { Direction = flat.Magnitude > 0.1 and flat or Vector3.zAxis,
										Speed = 40, Lift = 26, Duration = 0.3, Sustain = 0.1, AllowPlayerControl = false, ContainsArena = true } })
								end
							end
							z.Part:Destroy()
						end
					end
				end
				if not live then
					cast:Dispose()
					return false
				end
				return true
			end)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose()
		if active then
			active:Dispose()
		end
	end
	return api
end
