-- ServerScriptService.BossSystem.Players.Classes.Kits.Twinblade
-- Twinblade: the Hellaven reward class. Two blades, endless pressure, and a Flow meter that turns every landed hit into speed,
-- damage and defense. Deliberately overpowered (it is earned by clearing Hellaven) but every hit still goes through S.HitBoss,
-- so boss defenses, shield rules and the hit-cap pipeline apply exactly as for every other class.
--   * the M1 chain alternates hands (right diagonal / left diagonal / right sweep / left rising / crossing finisher)
--   * Flow is visible on the weapons (gem light, edge glow, halo, embers) and bursts at the 5 and 10 stack thresholds
--   * Blade Whirl really spins the swords and the body (ClassAnimator), Sky Cross leaps, chains the boss and X-slashes the ground
--   * pressing F within FinalWindow after Sky Cross triggers the hidden Final Destination; while Twin Spirits is out, M1 is a 360-degree sphere slash
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D = ClassConfig.Classes.Twinblade
local EMBER, AZURE, WHITE = D.Color, D.Color2, Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 225, 150)
local HOT = Color3.fromRGB(255, 240, 215)
local Debris = game:GetService("Debris")
local Tween = game:GetService("TweenService")
local SLASH = game.ReplicatedStorage:WaitForChild("VFXEngine"):WaitForChild("Assets"):WaitForChild("ArcSlash")
local CHAIN_TEXTURE = "rbxassetid://11669353706"
local V3 = Vector3.new
local FEET = V3(0, -2.5, 0)
local K = {}

-- one entry per link of the chain. Roll tilts the slash plane (+ lifts the right end), Rise moves the arc up/down,
-- Delay is when the blade actually connects (matches the strike frame of the animation), Trail is how long the ribbon shows.
local CUTS = {
  { Anim = "TB_Cut1", Hand = "R", Roll = 38, Rise = 0.9, Delay = 0.08, Trail = 0.22 },
  { Anim = "TB_Cut2", Hand = "L", Roll = -38, Rise = 0.9, Delay = 0.08, Trail = 0.22 },
  { Anim = "TB_Cut3", Hand = "R", Roll = 0, Rise = 0.4, Delay = 0.08, Trail = 0.24 },
  { Anim = "TB_Cut4", Hand = "L", Roll = 42, Rise = -0.2, Delay = 0.08, Trail = 0.24 },
  { Anim = "TB_Finish", Hand = "B", Roll = 0, Rise = 0.6, Delay = 0.11, Trail = 0.34 },
}

local function blades(char, st)
  local b = st.Data.Blades
  if b and ((b.R.Blade and b.R.Blade.Parent) or os.clock() - (st.Data.BladesAt or 0) < 2) then return b end
  b = { R = {}, L = {} }
  for hand, h in pairs(b) do
    local blade = char:FindFirstChild("Blade" .. hand, true)
    local fuller = char:FindFirstChild("BladeFuller" .. hand, true)
    local gem = char:FindFirstChild("BladeGem" .. hand, true)
    h.Blade = blade
    h.Trail = blade and blade:FindFirstChild("SwingTrail")
    h.Core = blade and blade:FindFirstChild("SwingTrailCore")
    h.Edges = {}
    local gear = char:FindFirstChild("ClassGear")
    if gear then
      for _, d in ipairs(gear:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:match("^BladeEdgeGlow.*" .. hand .. "$") then table.insert(h.Edges, d) end
      end
    end
    h.Aura = char:FindFirstChild("BladeAura" .. hand, true)
    h.Embers = fuller and fuller:FindFirstChild("FlowEmbers")
    h.Light = gem and gem:FindFirstChildOfClass("PointLight")
  end
  st.Data.Blades, st.Data.BladesAt = b, os.clock()
  return b
end
local function setTrail(char, st, hand, on)
  local h = blades(char, st)[hand]
  if not h then return end
  if h.Trail and h.Trail.Parent then h.Trail.Enabled = on end
  if h.Core and h.Core.Parent then h.Core.Enabled = on end
end
local function swingTrail(char, st, hand, dur)
  local stop = st.Data.TrailStop
  if not stop then stop = {} st.Data.TrailStop = stop end
  for _, h in ipairs(hand == "B" and { "R", "L" } or { hand }) do
    stop[h] = os.clock() + dur
    setTrail(char, st, h, true)
    task.delay(dur + 0.02, function()
      if os.clock() >= (stop[h] or 0) then setTrail(char, st, h, false) end
    end)
  end
end
local function aura(char, st, on)
  local e = st.Data.AuraFX
  if on then
    if not e or not e.Parent then
      local root = char:FindFirstChild("HumanoidRootPart")
      if not root then return end
      e = Instance.new("ParticleEmitter")
      e.Name = "TwinbladeAura"
      e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, EMBER), ColorSequenceKeypoint.new(0.5, HOT), ColorSequenceKeypoint.new(1, AZURE) })
      e.LightEmission = 1
      e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
      e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
      e.Lifetime = NumberRange.new(0.6, 1.1)
      e.Speed = NumberRange.new(3, 7)
      e.SpreadAngle = Vector2.new(25, 25)
      e.EmissionDirection = Enum.NormalId.Top
      e.Drag = 2
      e.Rate = 26
      e.Rotation = NumberRange.new(0, 360)
      e.Parent = root
      st.Data.AuraFX = e
    end
    e.Enabled = true
  elseif e then
    e.Enabled = false
  end
end
-- the weapons show how much Flow you carry
local function flowVisuals(char, st, n)
  if st.Data.Vanished then return end
  local t = n / D.FlowMax
  for _, h in pairs(blades(char, st)) do
    if h.Light and h.Light.Parent then h.Light.Brightness = 1.5 + 3 * t h.Light.Range = 6 + 8 * t end
    for _, e in ipairs(h.Edges or {}) do
      if e.Parent then e.Transparency = 0.45 - 0.45 * t end
    end
    if h.Aura and h.Aura.Parent then h.Aura.Transparency = 0.9 - 0.35 * t end
    if h.Embers and h.Embers.Parent then
      h.Embers.Rate = n >= 3 and (8 + n * 5) or 0
      h.Embers.Enabled = n >= 3
    end
  end
  aura(char, st, n >= D.FlowMax)
end
-- Final Destination: the Twinblade is the slashes, so the body and swords vanish on every client (ClassAnimator does the hiding)
local function setVanish(char, st, on)
  st.Data.Vanished = on or nil
  char:SetAttribute("TwinbladeVanished", on and true or nil)
  setTrail(char, st, "R", false)
  setTrail(char, st, "L", false)
  for _, h in pairs(blades(char, st)) do
    if h.Light and h.Light.Parent then h.Light.Enabled = not on end
    if h.Embers and h.Embers.Parent and on then h.Embers.Enabled = false end
  end
  if on then aura(char, st, false) else flowVisuals(char, st, st.Data.Flow or 0) end
end
-- Blade Whirl: ClassAnimator reads these two attributes and really spins the swords and the body
local function setSpin(char, on)
  char:SetAttribute("TwinbladeSpinDur", on and D.F.Duration or nil)
  char:SetAttribute("TwinbladeSpinEnd", on and (workspace:GetServerTimeNow() + D.F.Duration) or nil)
end
local function removeChain(st)
  for _, x in ipairs(st.Data.ChainParts or {}) do
    if x.Parent then x:Destroy() end
  end
  st.Data.ChainParts = nil
end

-- one-shot burst when Flow climbs through a threshold (rate limited per tier)
local function tierBurst(S, char, st, old, new)
  local root = char:FindFirstChild("HumanoidRootPart")
  if not root then return end
  local now = os.clock()
  local fx = st.Data.TierFx
  if not fx then fx = {} st.Data.TierFx = fx end
  if old < D.FlowMax and new >= D.FlowMax and now - (fx.O or 0) > 2 then
    fx.O = now
    S.FX.Flash(root.Position, GOLD, 14, 0.4)
    S.FX.Ring(root.Position + FEET, WHITE, 13, 0.45)
    S.FX.HQ.Spikes(root.Position + FEET, 8, 5, 14, EMBER, AZURE, 0.6)
    S.FX.Text(root.Position + V3(0, 4, 0), "OVERFLOW", GOLD)
  elseif old < D.UninterruptedAt and new >= D.UninterruptedAt and now - (fx.U or 0) > 2 then
    fx.U = now
    S.FX.Ring(root.Position + FEET, EMBER:Lerp(AZURE, 0.5), 8, 0.35)
  end
end

local function setFlow(S, char, st, n)
  local old = st.Data.Flow or 0
  n = math.clamp(n, 0, D.FlowMax)
  st.Data.Flow = n
  char:SetAttribute("TwinbladeFlow", n)
  if n <= 0 then
    if S.HasBuff(char, "TwinFlow") then S.Unbuff(char, "TwinFlow") end
    S.RemoveStatBuff(char, "TwinFlow")
    if S.HasBuff(char, "Uninterrupted") then S.Unbuff(char, "Uninterrupted") end
    char:SetAttribute("ClassStatusText_TwinFlow", nil)
    flowVisuals(char, st, 0)
    return
  end
  S.Buff(char, "TwinFlow", D.FlowDuration)
  char:SetAttribute("ClassStatusText_TwinFlow", "x" .. n)
  S.StatBuff(char, "TwinFlow", D.FlowDuration, {
    Attack = 1 + D.DamagePerStack * n,
    Defense = D.DefensePerStack * n,
    AttackSpeed = 1 + D.AttackSpeedPerStack * n,
  })
  if n >= D.UninterruptedAt then
    S.Buff(char, "Uninterrupted", D.FlowDuration)
  elseif S.HasBuff(char, "Uninterrupted") then
    S.Unbuff(char, "Uninterrupted")
  end
  flowVisuals(char, st, n)
  if n > old then tierBurst(S, char, st, old, n) end
end

function K.Start(S, player, char, st)
  st.Data.Flow, st.Data.Combo, st.Data.LastM1 = 0, 0, 0
  st.Data.Whirling, st.Data.Air = false, false
  st.Data.SpiritsUntil = 0
  st.Data.Blades, st.Data.TrailStop, st.Data.TierFx = nil, {}, {}
  st.Data.Final, st.Data.ComboUntil, st.Data.FinalReadyAt = false, 0, 0
  char:SetAttribute("TwinbladeFlow", 0)
  flowVisuals(char, st, 0)
end
function K.Cleanup(S, char, st)
  st.Data.SpiritsUntil = 0
  for _, list in ipairs({ st.Data.SpiritParts or {}, st.Data.WhirlParts or {}, st.Data.SkyParts or {} }) do
    for _, p in ipairs(list) do if p.Parent then p:Destroy() end end
  end
  st.Data.SpiritParts, st.Data.WhirlParts, st.Data.SkyParts = nil, nil, nil
  removeChain(st)
  st.Data.Air, st.Data.Final, st.Data.ComboUntil = false, false, 0
  if char.Parent then
    setSpin(char, false)
    setVanish(char, st, false)
  end
  if st.Data.AuraFX then st.Data.AuraFX:Destroy() st.Data.AuraFX = nil end
  if char.Parent then
    setTrail(char, st, "R", false)
    setTrail(char, st, "L", false)
    flowVisuals(char, st, 0)
    char:SetAttribute("TwinbladeFlow", nil)
    char:SetAttribute("ClassStatusText_TwinFlow", nil)
  end
end
function K.CancelActions(S, char, st, reason)
  if reason == "Time" then return end
  st.Data.Whirling = false
  if S.HasBuff(char, "Whirling") then S.Unbuff(char, "Whirling") end
  S.RemoveStatBuff(char, "BladeWhirl")
  setSpin(char, false)
  removeChain(st)
  st.Data.Final = false
  setVanish(char, st, false)
end
function K.OnBuffEnded(S, char, st, id)
  if id == "TwinFlow" then
    st.Data.Flow = 0
    char:SetAttribute("TwinbladeFlow", 0)
    char:SetAttribute("ClassStatusText_TwinFlow", nil)
    S.RemoveStatBuff(char, "TwinFlow")
    if S.HasBuff(char, "Uninterrupted") then S.Unbuff(char, "Uninterrupted") end
    flowVisuals(char, st, 0)
  end
end
function K.OnDamaged(S, char, st, actual)
  if (st.Data.Flow or 0) > 0 and os.clock() - (st.Data.LastFlowLoss or 0) > 0.25 then
    st.Data.LastFlowLoss = os.clock()
    if os.clock() >= (st.Data.SpiritsUntil or 0) then setFlow(S, char, st, st.Data.Flow - 1) end
  end
end
function K.Step(S, player, char, st, dt)
  -- Twin Spirits holds Flow at the maximum
  if os.clock() < (st.Data.SpiritsUntil or 0) then
    st.Data.SpiritTick = (st.Data.SpiritTick or 0) + dt
    if st.Data.SpiritTick >= 1 or (st.Data.Flow or 0) < D.FlowMax then
      st.Data.SpiritTick = 0
      setFlow(S, char, st, D.FlowMax)
      -- a soft alternating pulse at your feet while the spirits are out
      local root = char:FindFirstChild("HumanoidRootPart")
      if root then
        st.Data.SpiritPulse = not st.Data.SpiritPulse
        S.FX.Ring(root.Position + FEET, st.Data.SpiritPulse and EMBER or AZURE, 7, 0.5)
      end
    end
  end
end
-- landed hits build Flow; at Overflow the cuts also heal
function K.OnHitBoss(S, char, st, target, tag, dealt)
  if tag == "TwinbladeM1" then
    local gain = st.Data.LastCombo == D.M1.Combo and 2 or 1
    setFlow(S, char, st, (st.Data.Flow or 0) + gain)
  elseif tag == "TwinbladeWhirl" and not st.Data.WhirlGain then
    st.Data.WhirlGain = true
    setFlow(S, char, st, (st.Data.Flow or 0) + 1)
  end
  if (tag == "TwinbladeM1" or tag == "TwinbladeWhirl" or tag == "TwinbladeSpin") and (st.Data.Flow or 0) >= D.FlowMax then
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 then h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * D.OverflowHeal) end
  end
end

local function inRange(root, target, radius)
  local delta = target.HumanoidRootPart.Position - root.Position
  return Vector3.new(delta.X, 0, delta.Z).Magnitude <= radius + 4 and math.abs(delta.Y) <= 14
end
local function cross(S, origin, dir, scale, c1, c2)
  local f = CFrame.lookAt(origin, origin + dir)
  S.FX.HQ.Crescent(f * CFrame.Angles(0, 0, math.rad(45)), 6 * scale, math.rad(170), 1.4 * scale, c1, WHITE, 0.25)
  S.FX.HQ.Crescent(f * CFrame.Angles(0, 0, math.rad(-45)), 6 * scale, math.rad(170), 1.4 * scale, c2, WHITE, 0.25)
end
-- Twin Spirits: a 360-degree slash in every direction, a ball of crossing blade rings around you (each normal attack while active, big = the cast burst)
local SPHERE_RINGS = { { 0, 0, 0 }, { 90, 0, 0 }, { 0, 0, 90 }, { 45, 0, 45 }, { -45, 0, 45 }, { 45, 0, -45 } }
local function sphereSlash(S, char, st, big)
  local root = char:FindFirstChild("HumanoidRootPart")
  if not root then return end
  local attack = S.NewAttack(char, "TwinbladeSpin")
  if not attack then return end
  local radius = D.V.SpinRadius
  local at = root.Position + V3(0, 0.4, 0)
  local turn = math.pi * 2
  local base = CFrame.new(at) * CFrame.Angles(math.random() * turn, math.random() * turn, math.random() * turn)
  for i = 1, big and #SPHERE_RINGS or 4 do
    local r = SPHERE_RINGS[i]
    local ring = base * CFrame.Angles(math.rad(r[1]), math.rad(r[2]), math.rad(r[3]))
    S.FX.HQ.Crescent(ring, radius * 0.92, turn, big and 2.4 or 1.4, i % 2 == 1 and EMBER or AZURE, WHITE, big and 0.3 or 0.22, { Reverse = i % 2 == 0 })
  end
  local ball = S.FX.Part({ Size = Vector3.one * radius * 2, CFrame = CFrame.new(at), Color = GOLD, Material = Enum.Material.Neon, Transparency = 0.84 }, 0.35)
  ball.Shape = Enum.PartType.Ball
  S.FX.Fade(ball, 0.25)
  if big then
    S.FX.HQ.Shockwave(CFrame.new(root.Position + FEET), 2, radius * 1.2, 0.4, EMBER, 0.15, 1.0)
    S.FX.HQ.Shake(root.Position, 70, 0.25, 0.5)
  end
  for _, target in ipairs(S.Targets()) do
    if (target.HumanoidRootPart.Position - at).Magnitude <= radius + 4 then
      attack.Origin = at
      if S.HitBoss(char, target, big and D.V.BurstDamage or D.V.SpinDamage, "TwinbladeSpin", attack) then
        S.FX.Hit(target.HumanoidRootPart.Position, EMBER:Lerp(AZURE, math.random()), big and 1.8 or 1.0, big)
      end
    end
  end
end

local function m1(S, player, char, st, dir)
  local root = char.HumanoidRootPart
  if not S.Ready(char, "M1") then return end
  local spiritCut = os.clock() < (st.Data.SpiritsUntil or 0) -- Twin Spirits replaces the normal attack with the sphere slash
  S.Cooldown(char, "M1", spiritCut and D.V.SpinInterval or D.M1.Cooldown)
  local t = os.clock()
  st.Data.Combo = (t - (st.Data.LastM1 or 0) < 1.0) and (st.Data.Combo % D.M1.Combo) + 1 or 1
  st.Data.LastM1 = t
  local hit = st.Data.Combo
  local cut = CUTS[hit]
  local attack = S.NewAttack(char, "TwinbladeM1")
  if not attack then return end
  local finisher = hit == D.M1.Combo
  local flow = st.Data.Flow or 0
  local c1 = cut.Hand == "L" and AZURE or EMBER
  local c2 = c1 == EMBER and AZURE or EMBER
  local heat = c1:Lerp(HOT, flow / D.FlowMax * 0.45) -- the more Flow, the whiter-hot the cuts
  local scale = 1 + 0.03 * flow
  S.Anim(char, cut.Anim)
  S.Sound(char, finisher and "FallingImpact" or "NormalSwing")
  swingTrail(char, st, cut.Hand, cut.Trail)
  if spiritCut then
    task.delay(cut.Delay, function()
      if S.AttackValid(char, attack) then sphereSlash(S, char, st, false) end
    end)
    return
  end
  local range = flow >= D.FlowMax and D.OverflowRange or D.M1.Range
  if finisher and (D.M1.Lunge or 0) > 0 then -- the finisher steps into the target (set M1.Lunge = 0 to disable)
    local flat = V3(dir.X, 0, dir.Z)
    if flat.Magnitude > 0.01 then S.Remote():FireClient(player, "Leap", { Velocity = flat.Unit * D.M1.Lunge }) end
  end
  task.delay(cut.Delay, function()
    if not S.AttackValid(char, attack) then return end
    dir = C.AimDir(char, st.Aim)
    local eye = root.Position + V3(0, 0.8 + cut.Rise, 0)
    if finisher then
      cross(S, eye + dir * 3.5, dir, 1.3 * scale, EMBER, AZURE)
      S.FX.Release(eye + dir * 3.5, dir, GOLD, 0.8)
      S.FX.Ring(root.Position + FEET, GOLD, 7, 0.25)
    else
      local frame = CFrame.lookAt(eye, eye + dir) * CFrame.Angles(0, 0, math.rad(cut.Roll)) * CFrame.Angles(math.rad(10), 0, 0)
      local rev = cut.Hand == "L"
      S.FX.HQ.Crescent(frame, range * 0.7, math.rad(150), 1.2 * scale, heat, WHITE, 0.2, { Reverse = rev })
      S.FX.HQ.Crescent(frame, range * 0.55, math.rad(130), 0.5, WHITE, WHITE, 0.15, { Reverse = rev })
      -- a thin echo in the other blade's colour trails the cut: this is what makes the pair read as "twin"
      S.FX.HQ.Crescent(frame * CFrame.Angles(math.rad(6), 0, 0), range * 0.85, math.rad(120), 0.35, c2, c2, 0.28, { Reverse = rev })
    end
    local target = S.TargetNear(root.Position + dir * (range * 0.5), range * 0.75)
    if target and C.InFront(char, target, range + 5, -0.2) then
      st.Data.LastCombo = hit
      S.HitBoss(char, target, finisher and D.M1.FinisherDamage or D.M1.Damage, "TwinbladeM1", attack)
      local p = target.HumanoidRootPart.Position
      S.FX.Hit(p, heat, finisher and 1.8 or 1.0, finisher)
      cross(S, p, dir, finisher and 1.1 or 0.4, c1, c2) -- a small crossed mark where the cut lands
      S.FX.HQ.Shake(p, 45, finisher and 0.2 or 0.15, finisher and 0.6 or 0.25)
      S.Sound(char, finisher and "CounterImpact" or "NormalImpact")
      if finisher then
        S.FX.Flash(p, GOLD, 10, 0.25)
        S.FX.HQ.Spikes(p, 6, 3, 8, EMBER, AZURE, 0.4)
      end
    end
  end)
end

-- a layered mesh slash from the VFXEngine ArcSlash template: white core with a coloured glow behind it
local function meshSlash(S, frame, width, glow, life)
  for layer = 1, 2 do
    local p = SLASH:Clone()
    local w = layer == 1 and width or width * 1.14
    p.Size = SLASH.Size * (w / SLASH.Size.X)
    p.Color = layer == 1 and WHITE or glow
    p.Material = Enum.Material.Neon
    p.TextureID = ""
    p.Transparency = layer == 1 and 0.05 or 0.42
    p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
    p.CFrame = layer == 1 and frame or frame * CFrame.new(0, -w * 0.02, 0.2)
    p.Parent = S.FX.Folder()
    Tween:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
    Debris:AddItem(p, life + 0.1)
  end
end
local function wedge(S, cf, size, color, alpha, life)
  local p = Instance.new("WedgePart")
  p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
  p.Material = Enum.Material.Neon
  p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
  p.Size, p.Color, p.Transparency, p.CFrame = size, color, alpha, cf
  p.Parent = S.FX.Folder()
  task.delay(life * 0.7, function()
    if p.Parent then Tween:Create(p, TweenInfo.new(life * 0.3), { Transparency = 1 }):Play() end
  end)
  Debris:AddItem(p, life + 0.1)
  return p
end
-- a flat tapered gash in the frame's XZ plane: a long thin diamond built from four wedges
local function gash(S, frame, width, length, color, alpha, life)
  local thin = 0.14
  for _, sx in ipairs({ -1, 1 }) do
    for _, sz in ipairs({ -1, 1 }) do
      local theta = (sz == -1 and -sx or sx) * math.pi / 2
      local cf = frame * CFrame.new(sx * width / 2, 0, sz * length / 2)
      if sz == 1 then cf = cf * CFrame.Angles(0, math.pi, 0) end
      wedge(S, cf * CFrame.Angles(0, 0, theta), V3(thin, width, length), color, alpha, life)
    end
  end
end
-- the burned X: two crossing gashes, colour underneath with a white-hot core
local function groundX(S, center, flat, size, life)
  local frame = CFrame.lookAt(center + V3(0, 0.15, 0), center + V3(0, 0.15, 0) + flat)
  for i, ang in ipairs({ 45, -45 }) do
    local stroke = frame * CFrame.Angles(0, math.rad(ang), 0)
    gash(S, stroke, size * 0.14, size * 0.5, i == 1 and EMBER or AZURE, 0.15, life)
    gash(S, stroke * CFrame.new(0, 0.08, 0), size * 0.05, size * 0.46, WHITE, 0, life)
  end
end
-- flat ground under a point, ignoring characters and effects
local function groundUnder(S, char, pos)
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.RespectCanCollide = true
  local ignore = { char, S.FX.Folder() }
  for _, target in ipairs(S.Targets()) do table.insert(ignore, target) end
  params.FilterDescendantsInstances = ignore
  local hit = workspace:Raycast(pos + V3(0, 20, 0), V3(0, -400, 0), params)
  return hit and hit.Position or (pos - V3(0, 3, 0))
end

local function finalDestination(S, player, char, st)
  local root = char.HumanoidRootPart
  local attack = S.NewAttack(char, "TwinbladeFinal")
  if not attack then return end
  st.Data.Final, st.Data.ComboUntil = true, 0
  st.Data.FinalReadyAt = os.clock() + D.F.FinalCooldown
  if S.HasBuff(char, "FinalReady") then S.Unbuff(char, "FinalReady") end
  S.Cooldown(char, "F", D.F.Cooldown)
  local duration, ticks, half = D.F.FinalDuration, D.F.FinalTicks, D.F.FinalSize / 2
  S.Buff(char, "Phasing", duration + 0.6)
  S.Remote():FireClient(player, "TwinPath", { Steps = { { T = duration + 0.15, To = root.Position } }, Face = root.CFrame.LookVector })
  local look = C.Flat(root.CFrame.LookVector) or Vector3.zAxis
  local ground = groundUnder(S, char, root.Position)
  local frame = CFrame.lookAt(ground, ground + look)
  S.Sound(char, "RoyalFinalCharge")
  S.FX.Flash(root.Position, GOLD, 30, 0.35)
  S.FX.Text(root.Position + V3(0, 4, 0), "FINAL DESTINATION", GOLD)
  S.FX.HQ.Shake(root.Position, 220, 0.3, 0.7)
  setVanish(char, st, true)
  S.Remote():FireAllClients("TwinStorm", { Char = char, Frame = frame, Half = half, Duration = duration, Ticks = ticks, Slashes = D.F.FinalSlashes, Seed = math.random(1, 1000000) })
  -- the arena of the storm: a thin burning square
  for i = 0, 3 do
    local side = frame * CFrame.Angles(0, math.rad(i * 90), 0) * CFrame.new(0, 0.2, -half)
    local bar = S.FX.Part({ Size = V3(half * 2, 0.2, 0.9), CFrame = side, Color = i % 2 == 0 and EMBER or AZURE, Transparency = 0.15 }, duration + 0.4)
    task.delay(duration, function() if bar.Parent then S.FX.Fade(bar, 0.3) end end)
  end
  local function inside(target)
    local p = frame:PointToObjectSpace(target.HumanoidRootPart.Position)
    return math.abs(p.X) <= half + 3 and math.abs(p.Z) <= half + 3 and math.abs(p.Y) <= D.F.FinalHeight
  end
  -- S.Targets() is the boss plus every clone that has health and can be damaged, so the storm cuts all of them
  local function strike(damage, scale)
    for _, target in ipairs(S.Targets()) do
      if inside(target) then
        local p = target.HumanoidRootPart.Position
        attack.Origin = p + V3(0, 2, 0)
        if S.HitBoss(char, target, damage, "TwinbladeFinal", attack) then
          S.FX.Hit(p, EMBER:Lerp(AZURE, math.random()), scale, false)
          local turn = math.pi * 2
          meshSlash(S, CFrame.new(p) * CFrame.Angles(math.random() * turn, math.random() * turn, math.random() * turn), 16, math.random() < 0.5 and EMBER or AZURE, 0.2)
        end
      end
    end
  end
  task.spawn(function()
    local interval = duration / ticks
    local valid = true
    for i = 1, ticks do
      if not S.AttackValid(char, attack) then valid = false break end
      if i % 2 == 0 then S.Sound(char, "NormalSwing") end
      strike(D.F.FinalDamage, 0.8)
      task.wait(interval)
    end
    if valid and S.AttackValid(char, attack) then
      -- the storm closes on one giant cross
      local center = CFrame.lookAt(ground + V3(0, 10, 0), ground + V3(0, 10, 0) + look)
      meshSlash(S, center * CFrame.Angles(0, 0, math.rad(45)), half * 2.2, EMBER, 0.5)
      meshSlash(S, center * CFrame.Angles(0, 0, math.rad(-45)), half * 2.2, AZURE, 0.5)
      groundX(S, ground, look, D.F.FinalSize, 2.4)
      S.Sound(char, "CataclysmSlam")
      S.FX.Flash(ground + V3(0, 5, 0), GOLD, 60, 0.5)
      S.FX.HQ.Shockwave(CFrame.new(ground), 4, half * 1.5, 0.55, EMBER, 0.1, 1.4)
      task.delay(0.08, function() S.FX.HQ.Shockwave(CFrame.new(ground), 3, half * 1.2, 0.5, AZURE, 0.2, 1.0) end)
      S.FX.HQ.Spikes(ground, 16, half * 0.6, 24, EMBER, WHITE, 0.7)
      S.FX.HQ.Shake(ground, 240, 0.5, 1.2)
      strike(D.F.FinalBurst, 2.4)
    end
    st.Data.Final = false
    setVanish(char, st, false)
    if S.Alive(char) then
      S.Anim(char, "TB_Recover")
      S.FX.Flash(root.Position, GOLD, 8, 0.25)
    end
  end)
end

local function whirl(S, player, char, st)
  local root = char.HumanoidRootPart
  if st.Data.Whirling then return end
  if os.clock() < (st.Data.ComboUntil or 0) and os.clock() >= (st.Data.FinalReadyAt or 0) then
    finalDestination(S, player, char, st)
    return
  end
  if not S.Ready(char, "F") then return end
  S.Cooldown(char, "F", D.F.Cooldown)
  local attack = S.NewAttack(char, "TwinbladeWhirl")
  if not attack then return end
  st.Data.Whirling, st.Data.WhirlGain = true, false
  S.Buff(char, "Whirling", D.F.Duration, { Speed = D.F.Speed })
  S.StatBuff(char, "BladeWhirl", D.F.Duration, { Defense = D.F.Defense })
  S.Anim(char, "TB_Whirl")
  S.Sound(char, "ThrustBurst")
  S.FX.Flash(root.Position, GOLD, 8, 0.25)
  S.FX.HQ.Spikes(root.Position + FEET, 6, 4, 8, EMBER, AZURE, 0.4)
  setSpin(char, true)
  swingTrail(char, st, "B", D.F.Duration + 0.1)
  -- a longer ribbon while spinning, so each blade draws a full disc of light
  local b = blades(char, st)
  for _, h in pairs(b) do
    if h.Trail and h.Trail.Parent then h.Trail.Lifetime = 0.4 end
    if h.Core and h.Core.Parent then h.Core.Lifetime = 0.25 end
  end
  task.spawn(function()
    local interval = D.F.Duration / D.F.Ticks
    local cancelled = false
    for i = 1, D.F.Ticks do
      if not S.AttackValid(char, attack) or not st.Data.Whirling then cancelled = true break end
      if S.Now() < (char:GetAttribute("DashInvulnerableUntil") or 0) then cancelled = true break end
      local hot = i % 2 == 1 and EMBER or AZURE
      local cold = i % 2 == 1 and AZURE or EMBER
      local at = root.Position + V3(0, 0.6, 0)
      local spin = CFrame.new(at) * CFrame.Angles(0, math.rad(i * 62), 0)
      S.FX.HQ.Crescent(spin, D.F.Radius * 0.75, math.rad(160), 1.4, hot, WHITE, 0.2)
      S.FX.HQ.Crescent(spin * CFrame.Angles(0, math.rad(180), 0), D.F.Radius * 0.75, math.rad(160), 1.4, cold, WHITE, 0.2)
      S.FX.Ring(root.Position + FEET, hot, D.F.Radius, 0.25)
      S.Sound(char, "NormalSwing")
      if i == D.F.Ticks then
        S.FX.HQ.Shockwave(CFrame.new(root.Position + FEET), 2, D.F.Radius * 1.1, 0.35, AZURE, 0.2, 0.9)
        S.FX.HQ.Spikes(root.Position + FEET, 8, D.F.Radius * 0.5, 10, EMBER, WHITE, 0.4)
      end
      for _, target in ipairs(S.Targets()) do
        if inRange(root, target, D.F.Radius) then
          if S.HitBoss(char, target, D.F.Damage, "TwinbladeWhirl", attack) then
            S.FX.Hit(target.HumanoidRootPart.Position, hot, 0.9, false)
          end
        end
      end
      task.wait(interval)
    end
    st.Data.Whirling = false
    setSpin(char, false)
    for _, h in pairs(b) do
      if h.Trail and h.Trail.Parent then h.Trail.Lifetime = 0.22 end
      if h.Core and h.Core.Parent then h.Core.Lifetime = 0.13 end
    end
    if S.HasBuff(char, "Whirling") then S.Unbuff(char, "Whirling") end
    S.RemoveStatBuff(char, "BladeWhirl")
    if cancelled and S.Alive(char) then S.Anim(char, "TB_Recover") end
  end)
end

-- throw a chain from the right hand; a hook flies to the boss, then the chain stays pinned between you until removeChain
local function throwChain(S, char, st, boss, throwTime)
  local arm = char:FindFirstChild("Right Arm")
  local bossRoot = boss:FindFirstChild("HumanoidRootPart")
  if not arm or not bossRoot then return end
  local a0 = Instance.new("Attachment")
  a0.Position = V3(0, -1, 0)
  a0.Parent = arm
  local start = (arm.CFrame * CFrame.new(0, -1, 0)).Position
  local hook = S.FX.Part({ Size = V3(0.5, 0.5, 1.3), Color = GOLD, CFrame = CFrame.lookAt(start, bossRoot.Position), Transparency = 0 })
  local a1 = Instance.new("Attachment")
  a1.Parent = hook
  local links = Instance.new("Beam")
  links.Attachment0, links.Attachment1 = a0, a1
  links.Texture = CHAIN_TEXTURE
  links.TextureMode = Enum.TextureMode.Wrap
  links.TextureLength = 5
  links.Width0, links.Width1 = 2.6, 2.6
  links.FaceCamera = true
  links.Segments = 2
  links.LightEmission = 0.3
  links.LightInfluence = 0
  links.Color = ColorSequence.new(Color3.fromRGB(255, 235, 190))
  links.Parent = a0
  local glow = Instance.new("Beam")
  glow.Attachment0, glow.Attachment1 = a0, a1
  glow.Width0, glow.Width1 = 0.5, 0.5
  glow.FaceCamera = true
  glow.Segments = 2
  glow.LightEmission = 1
  glow.LightInfluence = 0
  glow.Color = ColorSequence.new(GOLD, EMBER)
  glow.Transparency = NumberSequence.new(0.55)
  glow.Parent = a0
  st.Data.ChainParts = { a0, hook }
  S.Sound(char, "FallingCharge")
  task.spawn(function()
    local t0 = os.clock()
    while hook.Parent and bossRoot.Parent do
      local k = (os.clock() - t0) / throwTime
      local target = bossRoot.Position
      local pos = start:Lerp(target, math.min(k, 1))
      if (target - pos).Magnitude > 0.1 then hook.CFrame = CFrame.lookAt(pos, target) end
      if k >= 1 then break end
      task.wait()
    end
    if hook.Parent and bossRoot.Parent then
      -- bite: pin the chain to the boss
      local pin = Instance.new("Attachment")
      pin.Parent = bossRoot
      links.Attachment1, glow.Attachment1 = pin, pin
      table.insert(st.Data.ChainParts, pin)
      S.FX.Flash(bossRoot.Position, GOLD, 7, 0.25)
      S.FX.HQ.Sparks(bossRoot.Position, GOLD, WHITE, 18, 20, 45, 0.3)
      S.Sound(char, "NormalImpact")
      hook:Destroy()
    end
  end)
end

local function skyCross(S, player, char, st, dir)
  local root = char.HumanoidRootPart
  if st.Data.Air or st.Data.Final or not S.Ready(char, "C") then return end
  local attack = S.NewAttack(char, "TwinbladeSky")
  if not attack then return end
  S.Cooldown(char, "C", D.C.Cooldown)
  local flat = C.Flat(dir) or C.Flat(root.CFrame.LookVector) or Vector3.zAxis
  local boss = S.AimTarget(char, st.Aim, D.C.ChainRange) or S.Boss()
  if boss and (boss.HumanoidRootPart.Position - root.Position).Magnitude > D.C.ChainRange then boss = nil end
  local rise, hang, fly, dive = D.C.RiseTime, D.C.HangTime, D.C.FlyTime, D.C.DiveTime
  local total = rise + hang + fly + dive
  local apex = (C.Path(S, char, Vector3.yAxis, D.C.Height))
  local steps = { { T = rise, To = apex, Ease = "out" }, { T = rise + hang, To = apex } }
  local landing
  if boss then
    steps[3] = { T = rise + hang + fly, Boss = boss, Back = 5, Up = 12, Ease = "in" }
    steps[4] = { T = total, Boss = boss, Back = 5, Ground = true, Ease = "in" }
  else
    landing = groundUnder(S, char, (C.Path(S, char, flat, 34))) + V3(0, 3, 0)
    steps[3] = { T = total, To = landing, Ease = "in" }
  end
  st.Data.Air = true
  S.Buff(char, "Phasing", total + 0.7)  -- untouchable for the whole flight and the landing
  S.Anim(char, "TB_SkyRise")
  S.Sound(char, "ThrustBurst")
  S.Remote():FireClient(player, "TwinPath", { Steps = steps, Face = flat })
  local launch = root.Position - V3(0, 2.6, 0)
  S.FX.Ring(launch, EMBER, 10, 0.4)
  S.FX.Ring(launch, AZURE, 6, 0.3)
  S.FX.HQ.Streaks(root.Position, Vector3.yAxis, EMBER, AZURE, 14, 8, 40, 90, 3)
  local function sleep(seconds)
    local t = os.clock() + seconds
    while os.clock() < t do
      if not S.AttackValid(char, attack) then return false end
      task.wait()
    end
    return true
  end
  local function abort()
    removeChain(st)
    st.Data.Air = false
    if S.Alive(char) then S.Anim(char, "TB_Recover") end
  end
  task.spawn(function()
    if not sleep(rise) then return abort() end
    if boss then
      S.Anim(char, "TB_SkyThrow")
      throwChain(S, char, st, boss, hang * 0.65)
    end
    if not sleep(hang) then return abort() end
    if boss then
      S.Anim(char, "TB_SkyFly")
      S.Sound(char, "FallingImpact")
      if not sleep(fly) then return abort() end
    else
      if not sleep(fly) then return abort() end
    end
    -- the X, cut in the air on the way down
    S.Anim(char, "TB_SkyDive")
    local bossNow = boss and boss:FindFirstChild("HumanoidRootPart")
    local mark = bossNow and bossNow.Position or (landing - V3(0, 3, 0))
    local crossAt = CFrame.lookAt(mark + V3(0, 6, 0), mark + V3(0, 6, 0) + flat)
    meshSlash(S, crossAt * CFrame.Angles(0, 0, math.rad(45)), 26, EMBER, 0.3)
    meshSlash(S, crossAt * CFrame.Angles(0, 0, math.rad(-45)), 26, AZURE, 0.3)
    if not sleep(dive) then return abort() end
    removeChain(st)
    if not S.Alive(char) then st.Data.Air = false return end

    local approach = C.Flat(mark - apex) or flat
    local ground = groundUnder(S, char, boss and bossNow and bossNow.Parent and bossNow.Position or mark)
    local flow = st.Data.Flow or 0
    local damage = D.C.Damage * (1 + D.C.FlowScale * flow)
    S.Anim(char, "TB_SkyLand")
    S.Sound(char, "CataclysmSlam")
    groundX(S, ground, approach, D.C.MarkSize, D.C.MarkLife)
    S.FX.HQ.Shockwave(CFrame.new(ground), 3, D.C.Radius * 1.3, 0.5, EMBER, 0.1, 1.2)
    task.delay(0.08, function() S.FX.HQ.Shockwave(CFrame.new(ground), 2, D.C.Radius, 0.45, AZURE, 0.2, 0.9) end)
    S.FX.HQ.Spikes(ground, 8, D.C.Radius * 0.5, 12 + flow, EMBER, WHITE, 0.6)
    S.FX.HQ.Debris(ground, 10, Color3.fromRGB(150, 130, 110), 0.7, 34)
    S.FX.Beam(ground, ground + V3(0, 38, 0), EMBER, 3.2, 0.4)
    S.FX.Beam(ground + V3(0.01, 0, 0), ground + V3(0, 30, 0), AZURE, 2.0, 0.5)
    S.FX.HQ.Shake(ground, 100, 0.4, 0.9)
    if flow >= D.FlowMax then
      task.delay(0.18, function() S.FX.HQ.Shockwave(CFrame.new(ground), 2, D.C.Radius * 1.6, 0.5, WHITE, 0.25, 1.0) end)
      S.FX.Flash(ground + V3(0, 3, 0), GOLD, 20, 0.45)
    end
    S.FX.Text(ground + V3(0, 6, 0), flow > 0 and ("SKY CROSS x" .. string.format("%.1f", 1 + D.C.FlowScale * flow)) or "SKY CROSS", GOLD)
    local center = { Position = ground + V3(0, 3, 0) }
    for _, target in ipairs(S.Targets()) do
      if inRange(center, target, D.C.Radius) then
        attack.Origin = center.Position
        if S.HitBoss(char, target, damage, "TwinbladeSky", attack) then
          S.FX.Hit(target.HumanoidRootPart.Position, EMBER, 2.4, true)
        end
      end
    end
    st.Data.Air = false
    -- the combo window for the hidden follow-up
    st.Data.ComboUntil = os.clock() + D.F.FinalWindow
    if os.clock() >= (st.Data.FinalReadyAt or 0) then S.Buff(char, "FinalReady", D.F.FinalWindow) end
  end)
end

-- a spirit is a small cluster of neon parts (blade, white edge, guard, gem) moved together every frame
local function makeSpirit(S, color, startCF)
  local sp = { parts = {}, pos = startCF.Position, color = color }
  local function add(size, c, offset, transp, isWedge)
    local p
    if isWedge then
      p = Instance.new("WedgePart")
      p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
      p.Material = Enum.Material.Neon
      p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
      p.Size, p.Color, p.Transparency, p.CFrame = size, c, transp, startCF
      p.Parent = S.FX.Folder()
    else
      p = S.FX.Part({ Size = size, Color = c, Material = Enum.Material.Neon, Transparency = transp, CFrame = startCF })
    end
    sp.parts[#sp.parts + 1] = { part = p, offset = offset }
    return p
  end
  -- the same curved sabre as the real swords, in ghost-light: two curved blade segments, wedge tip, white edge, square guard, hilt
  local joint = CFrame.new(0, 0, -1.85) * CFrame.Angles(-math.rad(7), 0, 0)
  local blade = add(V3(0.11, 0.36, 1.7), color, CFrame.new(0, 0, -1.0), 0.2)
  add(V3(0.11, 0.3, 1.45), color, joint * CFrame.new(0, 0, -0.72), 0.2)
  add(V3(0.1, 0.06, 1.7), WHITE, CFrame.new(0, 0.17, -1.0), 0)
  add(V3(0.1, 0.06, 1.45), WHITE, joint * CFrame.new(0, 0.14, -0.72), 0)
  add(V3(0.11, 0.3, 0.6), color, joint * CFrame.new(0, 0, -1.45 - 0.3), 0.2, true)
  add(V3(0.9, 0.9, 0.08), color, CFrame.new(0, 0, -0.15) * CFrame.Angles(0, 0, math.rad(45)), 0.1)
  add(V3(0.2, 0.2, 0.2), WHITE, CFrame.new(0, 0, -0.2) * CFrame.Angles(math.rad(45), 0, math.rad(45)), 0)
  add(V3(0.13, 0.13, 0.8), color, CFrame.new(0, 0, 0.38), 0.3)
  S.FX.Trail(blade, color, 3.4)
  return sp
end

-- the boss when it can be hit, otherwise the nearest clone with health, otherwise nothing
local function spiritTarget(S, root)
  local list = S.Targets()
  local boss = S.Boss()
  if boss and table.find(list, boss) then return boss end
  local best, bestD
  for _, m in ipairs(list) do
    local d = (m.HumanoidRootPart.Position - root.Position).Magnitude
    if not bestD or d < bestD then best, bestD = m, d end
  end
  return best
end
local function randomUnit()
  local v = V3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
  return v.Magnitude > 0.05 and v.Unit or Vector3.yAxis
end

local function spirits(S, player, char, st)
  local root = char.HumanoidRootPart
  if S.HasBuff(char, "TwinSpirits") or not S.Ready(char, "V") then return end
  S.Cooldown(char, "V", D.V.Cooldown)
  local finish = os.clock() + D.V.Duration
  st.Data.SpiritsUntil = finish
  S.Buff(char, "TwinSpirits", D.V.Duration)
  setFlow(S, char, st, D.FlowMax)
  S.Anim(char, "TB_Summon")
  S.Sound(char, "RoyalFinalCharge")
  S.FX.Flash(root.Position, GOLD, 18, 0.5)
  S.FX.Ring(root.Position + FEET, EMBER, 14, 0.5)
  task.delay(0.1, function() S.FX.Ring(root.Position + FEET, AZURE, 10, 0.5) end)
  S.FX.HQ.Spikes(root.Position + FEET, 8, 6, 16, EMBER, AZURE, 0.8)
  S.FX.Text(root.Position + V3(0, 4, 0), "TWIN SPIRITS", GOLD)
  -- the cast itself tears out a heavy sphere slash
  task.delay(0.25, function() if S.Alive(char) then sphereSlash(S, char, st, true) end end)
  local reach, passTime, speed = D.V.Reach, D.V.Interval, D.V.Speed
  local spirit, all = {}, {}
  for i, color in ipairs({ EMBER, AZURE }) do
    spirit[i] = makeSpirit(S, color, root.CFrame)
    spirit[i].index = i
    for _, e in ipairs(spirit[i].parts) do all[#all + 1] = e.part end
  end
  st.Data.SpiritParts = all
  local function place(sp, base)
    for _, e in ipairs(sp.parts) do
      if e.part.Parent then e.part.CFrame = base * e.offset end
    end
  end
  -- one cut straight through the target: in from where the sword is, out the far side at a random angle
  local function startPass(sp, center, k)
    local from = sp.pos - center
    from = from.Magnitude > 0.5 and from or randomUnit() * reach
    sp.from = from
    sp.to = (-from.Unit + randomUnit() * 0.9).Unit * reach
    sp.k, sp.struck, sp.roll = k, false, math.random() * math.pi * 2
  end
  local function strike(sp, target, center)
    local attack = S.NewAttack(char, "TwinbladeSpirit")
    if not attack then return end
    local turn = math.pi * 2
    S.FX.HQ.Crescent(CFrame.new(center) * CFrame.Angles(math.random() * turn, math.random() * turn, math.random() * turn), 7, math.rad(160), 1.1, sp.color, WHITE, 0.16)
    attack.Origin = center
    if S.HitBoss(char, target, D.V.Damage, "TwinbladeSpirit", attack) then
      S.FX.Hit(target.HumanoidRootPart.Position, sp.color, 0.8, false)
    end
  end
  task.spawn(function()
    local started, last = os.clock(), os.clock()
    while os.clock() < finish and S.Alive(char) and S.State(char) == st and S.HasBuff(char, "TwinSpirits") do
      local now = os.clock()
      local dt = now - last
      last = now
      for i, sp in ipairs(spirit) do
        if not sp.target or not S.Alive(sp.target) or now >= (sp.retargetAt or 0) then
          local nextTarget = spiritTarget(S, root)
          if nextTarget ~= sp.target then sp.k = nil end
          sp.target, sp.retargetAt = nextTarget, now + 0.25
        end
        local targetRoot = sp.target and sp.target:FindFirstChild("HumanoidRootPart")
        if not targetRoot then
          -- nothing can be cut right now: wait beside the Twinblade
          sp.k = nil
          local a = (now - started) * 4 + (i - 1) * math.pi
          local want = root.Position + V3(math.cos(a) * 4, 3, math.sin(a) * 4)
          sp.pos = sp.pos:Lerp(want, 1 - math.exp(-12 * dt))
          place(sp, CFrame.lookAt(sp.pos, sp.pos + root.CFrame.LookVector))
        else
          local center = targetRoot.Position + V3(0, 1, 0)
          if not sp.k then
            local delta = center - sp.pos
            local dist = delta.Magnitude
            if dist <= reach then
              startPass(sp, center, (i - 1) * -0.5) -- the second sword is half a cut behind, so the attack never stops
            else
              sp.pos += delta.Unit * math.min(dist, speed * dt)
              place(sp, CFrame.lookAt(sp.pos, center))
            end
          end
          if sp.k then
            sp.k += dt / passTime
            local k = math.clamp(sp.k, 0, 1)
            sp.pos = center + sp.from:Lerp(sp.to, k)
            local path = sp.to - sp.from
            local swing = -1.1 + 2.2 * k -- the blade sweeps through the cut, edge first
            place(sp, CFrame.lookAt(sp.pos, sp.pos + path) * CFrame.Angles(0, 0, sp.roll) * CFrame.Angles(swing, 0, 0))
            if k >= 0.5 and not sp.struck then
              sp.struck = true
              strike(sp, sp.target, center)
            end
            if sp.k >= 1 then startPass(sp, center, sp.k - 1) end
          end
        end
      end
      task.wait()
    end
    st.Data.SpiritsUntil = 0
    if S.HasBuff(char, "TwinSpirits") then S.Unbuff(char, "TwinSpirits") end
    if char.Parent then S.FX.Ring(root.Position + FEET, GOLD, 9, 0.4) end
    for _, p in ipairs(all) do if p.Parent then S.FX.Fade(p, 0.3) Debris:AddItem(p, 0.4) end end
    if st.Data.SpiritParts == all then st.Data.SpiritParts = nil end
  end)
end

function K.Action(S, player, char, st, key, phase, aim)
  if key == "Aim" or phase ~= "Begin" then return end
  if st.Data.Air or st.Data.Final then return end -- locked in for the flight and the storm
  local dir = C.AimDir(char, aim)
  if key == "M1" then m1(S, player, char, st, dir)
  elseif key == "F" then whirl(S, player, char, st)
  elseif key == "C" then skyCross(S, player, char, st, dir)
  elseif key == "V" then spirits(S, player, char, st) end
end
return K
