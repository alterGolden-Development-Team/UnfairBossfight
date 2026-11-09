local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Effects = require(B.Combat.EffectService)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local AIM = { LeftShoulder = { 90, -15, -25 }, LeftElbow = { 12, 0, 0 }, RightShoulder = { 15, 0, 0 }, RightElbow = { 60, 0, 0 } }
local KICK_BACK = { LeftShoulder = { 105, -15, -25 }, LeftElbow = { 0, 0, 0 }, RightShoulder = { 15, 0, 0 }, RightElbow = { 60, 0, 0 } }
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	 -- his root's height over the floor, so a move to a floor point keeps his feet on it
	function api.CanUse(target)
		return c.CanStart(target)
	end
	local function hand()
		return (c.Root.CFrame * CFrame.new(-1.5, 1, -2.5)).Position
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Golden Bullets")
			core.Face(target)
			core.PoseAngles(AIM, 0.12)
			local n = c.Count(S.Shots)
			local sigil = c.Tell(S.Sigil)
			c.Fx("P5Ascend", "GoldenSigil", { Time = sigil + n * S.Every + 0.1 })
			sound("CircularBarrageAim")
			if not c.Wait(sigil) then return false end
			local bullets = {}
			local cast = Effects.NewCast(actor, "P5GoldenBullets", n * S.Every + S.Range / S.Speed + 1)
			cast.PersistsThroughEmitterStun = true
			cast:Step(function()
				if actor:GetAttribute("Phase") ~= 5 then
					cast:Dispose()
					return false
				end
				local now = os.clock()
				local live = false
				for _, b in ipairs(bullets) do
					if not b.Done then
						local dist = S.Speed * (now - b.At)
						if dist >= b.Stop then
							b.Done = true
						else
							live = true
							local p = b.From + b.Dir * dist
							for _, char in ipairs(c.Targets()) do
								if (char.HumanoidRootPart.Position - p).Magnitude <= S.HitRadius + 1.5 then
									b.Done = true
									c.Hit(char, S.Damage, p)
									break
								end
							end
						end
					end
				end
				if not live and #bullets >= n then
					cast:Dispose()
					return false
				end
				return true
			end)
			for k = 1, n do
				if not core.Alive(target) then target = c.RandomTarget() end
				if not target then break end
				core.Face(target)
				local from = hand()
				local r = target.HumanoidRootPart
				local flight = (r.Position - from).Magnitude / S.Speed
				local aim = r.Position + r.AssemblyLinearVelocity * FLAT * flight * S.Lead
				local dir = (aim - from)
				dir = dir.Magnitude > 0.1 and dir.Unit or c.Root.CFrame.LookVector
				local stop = S.Range
				local wall = workspace:Raycast(from, dir * S.Range, core.Params())
				if wall and not wall.Instance:FindFirstAncestorOfClass("Model") then stop = wall.Distance end
				c.Fx("P5Ascend", "GoldenShot", { Origin = from, Dir = dir, Speed = S.Speed, Range = stop, Size = S.Size })
				if k % 2 == 1 then sound("RangedLaunch") end
				bullets[#bullets + 1] = { From = from, Dir = dir, At = os.clock(), Stop = stop }
				core.PoseAngles(k % 2 == 0 and AIM or KICK_BACK, 0.03)
				if not c.Wait(S.Every) then return false end
			end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
