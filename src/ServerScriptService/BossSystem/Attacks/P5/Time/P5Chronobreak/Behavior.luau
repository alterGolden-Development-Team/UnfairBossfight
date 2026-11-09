local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local S = require(script.Parent.Style)
local function holdLead() return (Config.DeflectHoldTime or 0.2) + 0.45 end
local CAST = { RightShoulder = { 120, 0, 20 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 120, 0, -20 }, LeftElbow = { 10, 0, 0 }, Waist = { -10, 0, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local ok, result = pcall(core.Perform, target, S.Name, function()
			local root = c.Root
			local ghost = root.CFrame
			actor:SetAttribute("AttackState", "Chronobreak")
			c.Send("ChronoGhost", { Frame = ghost, Time = S.Slashes * S.SlashGap + S.RewindTime + 1.2 })
			pcall(Audio.Emit, actor, "TeleportWarp", root)
			local path = { root.Position }
			local function record() path[#path + 1] = root.Position end
			for index = 1, S.Slashes do
				local victim = c.RandomTarget()
				if not victim then break end
				if c.Blink(c.Behind(victim, 5)) then record() end
				core.Face(victim)
				core.Melee.Pose(index % 2 == 1 and "Slash1" or "Slash2", 0.05)
				local frame = root.CFrame
				c.Send("ChronoSlash", { Frame = frame, Index = index })
				for _, char in ipairs(c.Targets()) do
					if c.InArc(frame, char.HumanoidRootPart.Position, S.SlashRadius, S.SlashHalfAngle) then
						c.Hit(char, S.SlashDamage, frame.Position)
					end
				end
				if not c.Wait(S.SlashGap) then return false end
				record()
			end
			 -- the break: back through everything, into the afterimage
			actor:SetAttribute("AttackState", "Chronobreak: rewind")
			for _, char in ipairs(c.Targets()) do
				c.Warn(char, "Hold", holdLead() + S.RewindTime)
			end
			core.PoseAngles(CAST, 0.08)
			if not c.Wait(holdLead()) then return false end
			path[#path + 1] = ghost.Position
			local back = {}
			for i = #path, 1, -1 do back[#back + 1] = path[i] end
			c.Send("ChronoRewind", { Path = back, Time = S.RewindTime })
			local hit = {}
			local legs = #back - 1
			if not c.Over(S.RewindTime, function(alpha)
				local f = alpha * legs
				local i = math.clamp(math.floor(f) + 1, 1, legs)
				local p = back[i]:Lerp(back[i + 1], f - (i - 1))
				root.CFrame = CFrame.new(p) * ghost.Rotation
				root.AssemblyLinearVelocity = Vector3.zero
				for _, char in ipairs(c.Targets()) do
					if not hit[char] and (char.HumanoidRootPart.Position - p).Magnitude <= S.PathRadius then
						hit[char] = true
						if not c.Deflected(char, "Hold") then c.Hit(char, S.PathDamage, p) end
					end
				end
			end) then return false end
			root.CFrame = ghost
			local ground = c.Ground(ghost.Position)
			c.Send("ChronoBurst", { Pos = ground, Radius = S.BurstRadius })
			core.ScreenEffect("Shake", { Origin = ground, Radius = 300, Intensity = 1, Duration = 0.4 })
			for _, char in ipairs(c.Targets()) do
				local rel = char.HumanoidRootPart.Position - ground
				if Vector3.new(rel.X, 0, rel.Z).Magnitude <= S.BurstRadius and rel.Y <= 14 and not c.Deflected(char, "Hold") then
					c.Hit(char, S.BurstDamage, ground + Vector3.new(0, 2, 0), { Knock = { Direction = rel, Speed = 40, Lift = 18,
						Duration = 0.3, Sustain = 0.06, AllowPlayerControl = true, ContainsArena = true } })
				end
			end
			actor:SetAttribute("P5Chronobreaks", (actor:GetAttribute("P5Chronobreaks") or 0) + 1)
			return c.Wait(0.1)
		end)
		c.ReleaseAll()
		if not ok then
			warn("[" .. S.Name .. "] " .. tostring(result))
			return false
		end
		return result
	end
	function api.Dispose()
		c.ReleaseAll()
	end
	return api
end
