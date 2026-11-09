local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Effects = require(B.Combat.EffectService)
local Audio = require(B.Presentation.CombatAudio)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local CollectionService = game:GetService("CollectionService")
local S = require(script.Parent.Style)
local PALM = { RightShoulder = { 60, 0, -10 }, RightElbow = { 10, 0, 0 }, RightWrist = { -80, 0, 0 }, LeftShoulder = { 20, 0, -30 },
	Waist = { 30, 0, 0 }, RightHip = { -40, 0, 0 }, RightKnee = { 60, 0, 0 }, LeftHip = { -20, 0, 0 }, LeftKnee = { 40, 0, 0 } }

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
			core.PoseAngles(PALM, 0.12)
			actor:SetAttribute("AttackState", "Nullified Zone")
			if not c.Wait(c.Tell(S.Tell)) then
				return false
			end
			local center = c.Ground(target.HumanoidRootPart.Position)
			local part = Instance.new("Part")
			part.Name = "P5NullifiedZone"
			part.Anchored = true part.CanCollide = false part.CanQuery = false part.CanTouch = false part.CastShadow = false
			part.Transparency = 1 part.Size = Vector3.one part.CFrame = CFrame.new(center)
			part:SetAttribute("VFX", "P5Arsenal")
			part:SetAttribute("Kind", "Nullified")
			part:SetAttribute("Radius", S.Radius)
			part:SetAttribute("Height", S.WallHeight)
			part:SetAttribute("EndsAt", workspace:GetServerTimeNow() + S.Duration)
			part.Parent = workspace
			CollectionService:AddTag(part, "VFXDecorate")
			core.ScreenEffect("Shake", { Origin = center, Radius = 160, Intensity = 0.8, Duration = 0.3 })
			pcall(Audio.Emit, actor, "GroundErupt", center)
			local cast = Effects.NewCast(actor, S.Name, S.Duration + 1)
			cast.PersistsThroughEmitterStun = true
			cast:Add(part)
			active = cast
			 -- the wall itself: panels all the way round, far taller than anyone can jump. On the server they don't collide,
			 -- so he, his body and everything he throws pass straight through; each client makes them solid for its own
			 -- character (VFXEngine.Effects.P5Arsenal watches for P5NullifiedWall), which is what keeps players in or out
			local wall = Instance.new("Folder")
			wall.Name = "P5NullifiedWall"
			local chord = 2 * S.Radius * math.sin(math.pi / S.Panels) * 1.08
			for i = 1, S.Panels do
				local a = (i - 1) / S.Panels * math.pi * 2
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local p = Instance.new("Part")
				p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
				p.Transparency = 1 p.Size = Vector3.new(chord, S.WallHeight + 30, 2)
				p.CFrame = CFrame.lookAt(center + dir * S.Radius + Vector3.new(0, (S.WallHeight + 30) / 2 - 2, 0), center + dir * (S.Radius + 1) + Vector3.new(0, (S.WallHeight + 30) / 2 - 2, 0))
				p.Parent = wall
			end
			wall.Parent = workspace
			cast:Add(wall)
			local t = 0
			cast:Step(function(dt)
				t += dt
				if t >= S.Duration or actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then
					Net.Send("P5Arsenal", "NullifiedEnd", { Boss = actor, Pos = center, Radius = S.Radius, Height = S.WallHeight })
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
