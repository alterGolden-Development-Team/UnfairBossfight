local Tactics = {}
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
function Tactics.Update(copy, ctx, now)
	local actor, core, api = ctx.Actor, ctx.Core, ctx.Api
	local position, boss = copy.Root.Position, core.Root.Position
	local offset = flat(position - boss)
	local distance = offset.Magnitude
	local away = distance > 0.1 and offset.Unit or Vector3.xAxis
	local attack = tostring(actor:GetAttribute("ActiveAttackToken") or actor:GetAttribute("AttackStartedAt") or "")
	local incoming = actor:GetAttribute("AttackInProgress") == true
	local skill = tostring(actor:GetAttribute("CurrentAttackFile") or "")
	local wide = skill:find("Split") or skill:find("Barrage") or skill:find("Rift") or skill:find("Tornado")
	local facing = flat(core.Root.CFrame.LookVector):Dot(away) > 0.15
	if incoming and distance < (wide and 35 or 22) and (wide or facing)
		and copy.LastDodgedAttack ~= attack and now >= copy.DodgeReady then
		copy.LastDodgedAttack = attack
		local side = copy.Index % 2 == 0 and 1 or -1
		copy.DodgeGoal = position + away * 7 + Vector3.new(-away.Z,0,away.X) * side * 10
		copy.DodgeUntil, copy.DodgeReady = now + 0.5, now + 1.6
		copy.SwingAt, copy.SwingHit = nil, nil
		api.Dodges = (api.Dodges or 0) + 1
	end
	local dodging = copy.DodgeUntil and now < copy.DodgeUntil
	if dodging then return copy.DodgeGoal, 34, true end
	 
	if copy.SwingAt then
		local elapsed = now - copy.SwingAt
		if elapsed >= 0.18 and not copy.SwingHit then
			copy.SwingHit = true
			if distance <= 8.5 and math.abs(position.Y-boss.Y) < 6
				and not actor:GetAttribute("Invulnerable") and not actor:GetAttribute("ParryActive")
				and core.CanHit(copy.Model,boss) then
				ctx.Damage.ApplyDamage(ctx.SwordDamage, copy.Model, {Kind="PlayerCopySword",Direct=false,Attacker=copy.Model})
			end
		end
		if elapsed >= 0.48 then copy.SwingAt, copy.SwingHit = nil, nil end
	end
	local guard = actor:GetAttribute("Invulnerable") or actor:GetAttribute("ParryActive")
	if distance <= 8.5 and math.abs(position.Y-boss.Y)<6 and not guard and not copy.SwingAt
		and now>=copy.NextSwing and core.CanHit(copy.Model,boss) then
		copy.SwingAt,copy.SwingHit = now,false
		copy.NextSwing = now + 1.35 + copy.Index * 0.07
		api.Swings = (api.Swings or 0)+1
	end
	local angle = copy.Angle + (copy.OrbitDirection or 1) * now * 0.17
	if (copy.BlockedFor or 0) > 0.6 then
		copy.OrbitDirection = -(copy.OrbitDirection or 1)
		copy.BlockedFor = 0
	end
	local radius = guard and 12 or copy.SwingAt and 6.8 or 7.5
	local goal = boss + Vector3.new(math.cos(angle),0,math.sin(angle))*radius
	if copy.SwingAt then return position, 0, false end
	return goal, distance > 28 and 19 or 13, false
end
return Tactics
