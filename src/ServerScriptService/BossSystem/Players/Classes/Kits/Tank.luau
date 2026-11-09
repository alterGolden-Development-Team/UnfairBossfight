-- ServerScriptService.BossSystem.Players.Classes.Kits.Tank
-- Gameplay numbers (damage, cooldowns, ranges, defense, shields, stun) still come from ClassConfig and are untouched.
-- What changed is timing, feel and feedback:
--   * M1 / Release / Almighty are timed against the keyframes in Animations.lua (anticipation -> hit frame -> follow-through)
--   * every impact is staged in beats instead of dumped on one frame, and scales with how "full" the shield was where that applies
--   * the shield + sword are alive: the shield inlay/gem brightens with Bulwark (missing HP) and with stored Defender damage,
--     the sword inlay brightens during Rampage / Almighty
--   * Defender now shows the ally-guard radius on every pulse, and sparks when it absorbs a hit
--   * fixed: Step() could error on a nil Humanoid inside the Defender pulse

local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local D = ClassConfig.Classes.Tank
local STEEL, BLUE = Color3.fromRGB(150, 160, 175), D.Color
local ICE, WHITE = Color3.fromRGB(140, 200, 255), Color3.new(1, 1, 1)
local GOLD, DUST = Color3.fromRGB(255, 240, 120), Color3.fromRGB(140, 120, 95)

-- Timing (seconds). These line up with Animations.lua. Set any of them to 0 to make that part instant again.
local M1_WINDUP = 0.06 -- Shield Slam: anticipation before the lunge starts (strike pose is at 0.13s)
local V_CAST = 0.22 -- Almighty: sword reaches its apex; shields are granted here
local V_SLAM = 0.46 -- Almighty: sword comes down -> ground burst
local RELEASE_DELAY = 0.11 -- Defender release: shield meets the ground -> shockwave

local K = {}

local function BossSystem()
	return script:FindFirstAncestor("BossSystem")
end

local function Ground(char) -- ground point under the character (arena raycast, with the old fallback)
	local r = char:FindFirstChild("HumanoidRootPart")
	if not r then
		return nil
	end
	local h = char:FindFirstChildOfClass("Humanoid")
	return require(BossSystem().Encounter.ArenaPlacement).GroundPoint(r.Position)
		or r.Position - Vector3.new(0, ((h and h.HipHeight) or 2) + r.Size.Y * 0.5 + 2, 0)
end

local function Find(char, name)
	return char:FindFirstChild(name, true)
end

local function GemPos(char)
	local gem = Find(char, "ShieldGem")
	if gem then
		return gem.Position
	end
	local r = char:FindFirstChild("HumanoidRootPart")
	return r and r.Position or Vector3.zero
end

local function TipPos(char)
	local blade = Find(char, "SwordBlade")
	if blade then
		return blade.CFrame:PointToWorldSpace(Vector3.new(0, -blade.Size.Y * 0.5 - 0.75, 0))
	end
	return C.Hand(char, "Right") + Vector3.new(0, 2, 0)
end

local function Play(S, char, name, fallback) -- an animation key that is missing must never break a skill
	local ok = pcall(S.Anim, char, name)
	if not ok and fallback then
		pcall(S.Anim, char, fallback)
	end
end

local function Pillar(pos, color, height, radius, life, startTransparency) -- beam of light that shrinks away
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material, p.Color, p.Shape = Enum.Material.Neon, color, Enum.PartType.Cylinder
	p.Transparency = startTransparency or 0.35
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(height, 0.25, 0.25),
		Transparency = 1,
	}):Play()
	Debris:AddItem(p, life + 0.15)
end

local function GlowRig(char, st)
	local g = st.Data.Glow
	if g and g.gem and g.gem.Parent then
		return g
	end
	local now = os.clock()
	if g and now < g.retryAt then
		return nil
	end
	g = { shield = {}, sword = {}, retryAt = now + 1 }
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			local n = d.Name
			if n == "ShieldInlay" then
				table.insert(g.shield, d)
			elseif n == "SwordInlay" then
				table.insert(g.sword, d)
			elseif n == "ShieldGem" then
				g.gem, g.light = d, d:FindFirstChildOfClass("PointLight")
			elseif n == "SwordGem" then
				g.swordLight = d:FindFirstChildOfClass("PointLight")
			end
		end
	end
	st.Data.Glow = g
	if g.gem then
		return g
	end
	return nil
end

local function SetShieldGlow(g, level)
	level = math.clamp(level, 0, 1)
	if math.abs(level - (g.shieldLevel or -1)) < 0.03 then
		return
	end
	g.shieldLevel = level
	local tr = 0.7 - 0.7 * level
	for _, p in ipairs(g.shield) do
		p.Transparency = tr
	end
	if g.light then
		g.light.Brightness = 1 + 3 * level
		g.light.Range = 7 + 7 * level
	end
end

local function SetSwordGlow(g, level)
	level = math.clamp(level, 0, 1)
	if math.abs(level - (g.swordLevel or -1)) < 0.03 then
		return
	end
	g.swordLevel = level
	local tr = 0.65 - 0.65 * level
	for _, p in ipairs(g.sword) do
		p.Transparency = tr
	end
	if g.swordLight then
		g.swordLight.Brightness = 1 + 3 * level
		g.swordLight.Range = 5 + 8 * level
	end
end

function K.StopDefender(S, char, st)
	S.StopDefender(char)
	require(BossSystem().Combat.TauntService).Refresh()
end

function K.Start(S, player, char, st)
	st.Def = table.clone(st.Def)
	st.Def.BaseDefense = D.BaseDefense
	S.StatBuff(char, "Bulwark", nil, { Defense = D.PassiveMin })
	st.Data.Stored = 0
end

function K.Step(S, player, char, st, dt)
	local h = char:FindFirstChildOfClass("Humanoid")
	local b = st.StatSources.Bulwark
	local missing = 0
	if h and b then
		missing = 1 - math.clamp(h.Health / math.max(1, h.MaxHealth), 0, 1)
		b.Mods.Defense = D.PassiveMin + (D.PassiveMax - D.PassiveMin) * missing
		char:SetAttribute("TankBulwark", b.Mods.Defense)
		st.Def.HealthRegenFraction = D.HealthRegenFraction + D.RegenPerMissing * missing
		S.RefreshStatBuffs(char)
	end

	local defending = S.IsDefending(char)
	if defending and S.Now() >= (st.Data.DefenderLeaseUntil or 0) then
		K.StopDefender(S, char, st)
		defending = S.IsDefending(char)
	end

	if defending then
		char:SetAttribute("TauntingUntil", S.Now() + D.F.HoldLease)
		local guardRoot = char:FindFirstChild("HumanoidRootPart")
		if guardRoot then
			for _, ally in ipairs(S.Allies(false, char)) do
				local allyRoot = ally:FindFirstChild("HumanoidRootPart")
				if allyRoot and (allyRoot.Position - guardRoot.Position).Magnitude <= D.F.AllyRadius then
					S.Buff(ally, "DefenderGuard", 0.6, { Incoming = 1 - D.F.AllyReduction })
				end
			end
		end
		st.Data.DefenderPulse = (st.Data.DefenderPulse or 0) + dt
		if st.Data.DefenderPulse > 0.8 then
			st.Data.DefenderPulse = 0
			local ground = guardRoot and Ground(char)
			if ground then
				S.FX.HQ.Shockwave(CFrame.new(ground + Vector3.new(0, 0.08, 0)), 3, 200, 1.1, BLUE, 0.72, 0.35)
				-- ... plus a bright ring that stops exactly at the ally-guard radius so teammates can see where to stand
				S.FX.HQ.Shockwave(CFrame.new(ground + Vector3.new(0, 0.12, 0)), 2, D.F.AllyRadius, 0.8, ICE, 0.5, 0.2)
				S.FX.HQ.Debris(ground, 2, DUST, 0.35, 8)
			end
		end
	end

	-- living weapon: shield glow follows Bulwark and stored damage, sword glow follows Rampage / Almighty (10 Hz, only on change)
	st.Data.GlowClock = (st.Data.GlowClock or 0) + dt
	if st.Data.GlowClock >= 0.1 then
		st.Data.GlowClock = 0
		local g = GlowRig(char, st)
		if g then
			local level = missing * 0.55
			if defending and h then
				local storedFrac = (st.Data.Stored or 0) / math.max(1, h.MaxHealth * D.F.StoreCap)
				level = math.max(level, 0.3 + 0.7 * math.clamp(storedFrac, 0, 1))
			end
			SetShieldGlow(g, level)
			local boost = (st.Data.SwordBoostUntil or 0) - S.Now()
			SetSwordGlow(g, 0.3 + 0.7 * math.clamp(boost / 1.2, 0, 1))
		end
	end
end

function K.Cleanup(S, char, st)
	if char.Parent then
		char:SetAttribute("TankStored", nil)
		char:SetAttribute("ClassStatus_Stored", nil)
		char:SetAttribute("ClassStatusText_Stored", nil)
	end
end

-- Defender stores part of the damage it absorbs...
function K.Incoming(S, char, st, amount, balance)
	if S.IsDefending(char) and amount > 0 and not (balance and balance.IsStatusDamage) then
		local h = char:FindFirstChildOfClass("Humanoid")
		if h then
			local stored = math.min(h.MaxHealth * D.F.StoreCap, (st.Data.Stored or 0) + amount * S.Defense(char) * D.F.StoreFraction)
			st.Data.Stored = stored
			char:SetAttribute("TankStored", math.floor(stored))
			char:SetAttribute("ClassStatus_Stored", -1)
			char:SetAttribute("ClassStatusText_Stored", tostring(math.floor(stored)))
			-- the shield visibly takes the hit (throttled so multi-hit attacks don't spam)
			local t = S.Now()
			if t - (st.Data.LastBlockFx or 0) > 0.2 then
				st.Data.LastBlockFx = t
				S.FX.HQ.Glint(GemPos(char), WHITE, 3.5, 0.2)
				if t - (st.Data.LastBlockSnd or 0) > 0.45 then
					st.Data.LastBlockSnd = t
					S.Sound(char, "BlockImpact")
				end
			end
		end
	end
	return amount
end

-- ...and releasing it (F up, lease expiry or being knocked out of the hold) blasts it back.
-- with how full the shield was (power 0.15 .. 1).
function K.OnDefenderEnd(S, char, st)
	local stored = st.Data.Stored or 0
	st.Data.Stored = 0
	char:SetAttribute("TankStored", nil)
	char:SetAttribute("ClassStatus_Stored", nil)
	char:SetAttribute("ClassStatusText_Stored", nil)
	if stored < 5 then
		return
	end
	local attack = S.NewAttack(char, "TankShockwave")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not attack or not root then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local power = math.clamp(stored / math.max(1, (hum and hum.MaxHealth or 100) * D.F.StoreCap), 0.15, 1)
	local R = D.F.ShockwaveRadius
	local delay = S.Alive(char) and RELEASE_DELAY or 0

	Play(S, char, "Release", "Bash")
	-- anticipation beat: the shield flares as it rises
	S.FX.HQ.Glint(GemPos(char), ICE, 4 + 3 * power, delay + 0.1)
	S.FX.Charge(root.Position + Vector3.new(0, 2, 0), ICE, math.max(delay, 0.05), 1.5 + power)

	task.delay(delay, function()
		root = char:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local p = root.Position
		local ground = p - Vector3.new(0, 2.6, 0)
		S.Sound(char, "CataclysmSlam")
		S.FX.Flash(p, BLUE, 10 + 6 * power, 0.4)
		S.FX.HQ.Shockwave(CFrame.new(ground), 2, R * 1.3, 0.5, BLUE, 0.15, 1.2)
		S.FX.HQ.Shockwave(CFrame.new(ground + Vector3.new(0, 0.05, 0)), 1, R * 0.8, 0.32, WHITE, 0.3, 0.6)
		S.FX.HQ.Spikes(ground, 4 + math.floor(power * 4), R * 0.6, 8 + 6 * power, BLUE, WHITE, 0.5)
		S.FX.HQ.Debris(ground, 6 + math.floor(power * 6), DUST, 0.6, 30)
		S.FX.HQ.Shake(p, 60 + 30 * power, 0.3 + 0.1 * power, 0.5 + 0.35 * power)
		S.FX.Text(p + Vector3.new(0, 4, 0), "RELEASED " .. math.floor(stored), BLUE)
		for _, target in ipairs(S.Targets()) do
			local delta = target.HumanoidRootPart.Position - p
			if Vector3.new(delta.X, 0, delta.Z).Magnitude <= R + 4 and math.abs(delta.Y) <= 12 then
				S.HitBoss(char, target, stored, "TankShockwave", attack)
			end
		end
	end)
end

function K.Action(S, player, char, st, key, phase, aim)
	local root = char.HumanoidRootPart
	local dir = C.AimDir(char, aim)

	local near = S.AimTarget(char, aim, 18)
	if key == "M1" and player:GetAttribute("ClassAutoAim") ~= false and near and (near.HumanoidRootPart.Position - root.Position).Magnitude < 18 then
		dir = C.AimDir(char, near.HumanoidRootPart.Position)
	end

	if key == "F" then
		if phase == "End" then
			K.StopDefender(S, char, st)
			return
		end
		if phase == "Hold" and S.IsDefending(char) then
			st.Data.DefenderLeaseUntil = S.Now() + D.F.HoldLease
			return
		end
		if phase == "Begin" and S.Ready(char, "F") and not S.IsDefending(char) then
			st.Data.DefenderHeld = true
			st.Data.DefenderPulse = 0.8
			char:SetAttribute("TankDefenderHeld", true)
			S.StatBuff(char, "Defender", nil, { Defense = D.F.Defense })
			S.Buff(char, "Taunt", nil, { Speed = D.F.SpeedMultiplier })
			st.Data.DefenderLeaseUntil = S.Now() + D.F.HoldLease
			char:SetAttribute("TauntingUntil", S.Now() + D.F.HoldLease)
			S.Cooldown(char, "F", D.F.Cooldown)
			S.Sound(char, "GuardActivate")
			-- plant: shield flares forward, the ground bites, ring halo on the shield face
			local planted = root.Position - Vector3.new(0, 2.6, 0)
			S.FX.Release(root.Position + dir * 2, dir, BLUE, 0.8)
			S.FX.HQ.Shockwave(CFrame.lookAt(root.Position, root.Position + dir) * CFrame.Angles(math.rad(90), 0, 0), 1, 6, 0.35, BLUE, 0.2, 0.5)
			S.FX.HQ.Glint(GemPos(char), Color3.fromRGB(140, 200, 255), 4, 0.35)
			S.FX.HQ.Spikes(planted, 5, 5, 8, BLUE, WHITE, 0.45)
			S.FX.HQ.Debris(planted, 5, DUST, 0.45, 18)
			S.FX.HQ.Shake(root.Position, 40, 0.2, 0.35)
		end
		return
	end

	if phase ~= "Begin" or not S.Ready(char, key) then
		return
	end

	if key == "M1" then
		S.Cooldown(char, "M1", D.M1.Cooldown)
		local attack = S.NewAttack(char, "TankSlam")
		S.Anim(char, "Bash")
		S.Sound(char, "BlockLaunch")
		task.delay(M1_WINDUP, function() -- anticipation: shield draws back, sword arm lifts, THEN the lunge
			if not S.Alive(char) or not root.Parent then
				return
			end
			local hit = false
			C.Move(S, player, char, dir, D.M1.Lunge / 0.18, 0.18, {
				ContactRadius = D.M1.Range * 0.7,
				OnContact = function(target)
					if hit then
						return
					end
					hit = true
					S.HitBoss(char, target, D.M1.Damage, "TankSlam", attack)
					local p = root.Position
					local face = p + dir * 2.5
					local feet = face - Vector3.new(0, 2.5, 0)
					S.Sound(char, "BlockImpact")
					S.FX.Hit(face, BLUE, 1.5, false)
					S.FX.HQ.Glint(GemPos(char), WHITE, 5, 0.3)
					S.FX.HQ.Shockwave(CFrame.lookAt(face, face + dir) * CFrame.Angles(math.rad(90), 0, 0), 1, 9, 0.28, ICE, 0.15, 0.35)
					S.FX.HQ.Shake(p, 50, 0.2, 0.45)
					S.FX.HQ.Debris(feet, 6, DUST, 0.5, 26)
					S.FX.HQ.Spikes(feet, 4, 4, 7, BLUE, WHITE, 0.4)
					S.FX.Ring(p + dir * 2 - Vector3.new(0, 2.5, 0), STEEL, 8, 0.3)
				end,
				OnEnd = function(didHit, interrupted)
					if not didHit and not interrupted then
						local target = S.TargetNear(root.Position + dir * 3, D.M1.Range * 0.6)
						if target then
							S.HitBoss(char, target, D.M1.Damage, "TankSlam", attack)
							S.FX.Flash(root.Position + dir * 2, BLUE, 8, 0.25)
						end
					end
				end,
			})
		end)

	elseif key == "C" then
		S.Cooldown(char, "C", D.C.Cooldown)
		local attack = S.NewAttack(char, "TankRampage")
		S.Buff(char, "Rampage", D.C.MaxTime, { Defense = D.C.Defense })
		S.Sound(char, "FallingCharge")
		st.Data.SwordBoostUntil = S.Now() + D.C.MaxTime + 0.5
		-- launch: the ground blows out behind the first step
		local feet0 = root.Position - Vector3.new(0, 2.7, 0)
		S.FX.HQ.Streaks(root.Position, dir, BLUE, WHITE, 12, 10, 40, 80, 4)
		S.FX.HQ.Shockwave(CFrame.new(feet0 + Vector3.new(0, 0.1, 0)), 1, 9, 0.4, ICE, 0.3, 0.4)
		S.FX.HQ.Debris(feet0, 8, DUST, 0.5, 30)
		S.FX.HQ.Shake(root.Position, 45, 0.25, 0.4)

		task.spawn(function() -- footfalls + a glint that rides the shield edge
			local t0 = os.clock()
			while os.clock() - t0 < D.C.MaxTime and S.HasBuff(char, "Rampage") and S.Alive(char) do
				local feet = root.Position - Vector3.new(0, 2.7, 0)
				S.FX.HQ.Debris(feet, 3, DUST, 0.4, 14)
				S.FX.HQ.Shockwave(CFrame.new(feet), 1, 5, 0.3, Color3.fromRGB(160, 200, 255), 0.4, 0.35)
				S.FX.HQ.Glint(GemPos(char), WHITE, 4.5, 0.22)
				task.wait(0.14)
			end
		end)
		C.Move(S, player, char, dir, D.C.Speed, D.C.MaxTime, {
			ContactRadius = 6.5,
			StopOnContact = true,
			OnContact = function(target)
				S.Unbuff(char, "Rampage")
				if not S.HitBoss(char, target, D.C.Damage, "TankRampage", attack) then
					return
				end
				S.Stun(target, D.C.Stun, char, attack)
				local tp = target.HumanoidRootPart.Position
				S.Sound(char, "CataclysmSlam")
				S.FX.Hit(tp, BLUE, 2.2, true)
				S.FX.HQ.Shake(tp, 80, 0.35, 0.7)
				S.FX.HQ.Spikes(tp - Vector3.new(0, 3, 0), 5, 6, 12, GOLD, WHITE, 0.6)
				S.FX.HQ.Tint(tp, Color3.fromRGB(140, 190, 255), 0.25, 0.3, 100)
				S.FX.Flash(tp, GOLD, 14, 0.4)
				S.FX.Ring(tp, STEEL, 16, 0.5)
				S.FX.Text(tp + Vector3.new(0, 5, 0), "STUNNED", GOLD)
				-- beat 2: the aftershock rolls out along the ground
				task.delay(0.12, function()
					S.FX.HQ.Shockwave(CFrame.new(tp - Vector3.new(0, 2.5, 0)), 2, 22, 0.55, ICE, 0.2, 0.9)
					S.FX.HQ.Debris(tp - Vector3.new(0, 3, 0), 8, DUST, 0.6, 34)
				end)
			end,
			OnEnd = function()
				S.Unbuff(char, "Rampage")
			end,
		})

	elseif key == "V" then
		S.Cooldown(char, "V", D.V.Cooldown)
		S.Anim(char, "Almighty")
		st.Data.SwordBoostUntil = S.Now() + V_SLAM + 1.0
		-- gather: light is drawn up into the raised blade while the arm lifts
		S.FX.Charge(C.Hand(char, "Right") + Vector3.new(0, 2.5, 0), ICE, math.max(V_CAST, 0.05), 2.2)
		S.FX.HQ.Glint(GemPos(char), ICE, 4, math.max(V_CAST, 0.05))

		-- apex: the sword is up -> pillar of light, shields granted, beams to every ally in range
		task.delay(V_CAST, function()
			local rp = char:FindFirstChild("HumanoidRootPart")
			if not S.Alive(char) or not rp then
				return
			end
			local tip = TipPos(char)
			S.Sound(char, "RoyalFinalImpact")
			Pillar(tip, ICE, 90, 1.6, 0.9, 0.55)
			Pillar(tip, WHITE, 90, 0.55, 0.7, 0.1)
			S.FX.HQ.Streaks(tip, Vector3.new(0, 1, 0), ICE, WHITE, 10, 10, 40, 80, 4)
			S.FX.Flash(tip, WHITE, 16, 0.5)
			S.FX.HQ.Tint(rp.Position, ICE, 0.15, 0.4, D.V.Radius * 2)
			for _, ally in ipairs(S.Allies(true)) do
				local ar = ally:FindFirstChild("HumanoidRootPart")
				if ar and (ar.Position - rp.Position).Magnitude <= D.V.Radius then
					local ah = ally:FindFirstChildOfClass("Humanoid")
					ally:SetAttribute("ClassShieldHP", math.max(ally:GetAttribute("ClassShieldHP") or 0, (ah and ah.MaxHealth or 0) * D.V.ShieldFraction))
					S.Buff(ally, "Almighty", nil)
					S.FX.Beam(tip, ar.Position, Color3.fromRGB(120, 210, 255), 0.4, 0.4)
				end
			end
		end)

		-- slam: the sword comes down and the ground answers
		task.delay(V_SLAM, function()
			local rp = char:FindFirstChild("HumanoidRootPart")
			if not S.Alive(char) or not rp then
				return
			end
			local p = rp.Position
			local gp = p - Vector3.new(0, 2.5, 0)
			S.Sound(char, "BlockImpact")
			S.FX.Hit(p + dir * 2, Color3.fromRGB(140, 200, 255), 2, true)
			S.FX.HQ.Spikes(gp, 6, 8, 14, Color3.fromRGB(120, 210, 255), WHITE, 0.9)
			S.FX.Ring(gp, Color3.fromRGB(120, 210, 255), D.V.Radius, 0.7, 0.6)
			S.FX.HQ.Shockwave(CFrame.new(gp + Vector3.new(0, 0.1, 0)), 2, D.V.Radius, 0.8, ICE, 0.25, 0.8)
			S.FX.HQ.Shake(p, 70, 0.4, 0.5)
			S.FX.Flash(p, Color3.fromRGB(120, 210, 255), 12, 0.5)
		end)
	end
end

return K
