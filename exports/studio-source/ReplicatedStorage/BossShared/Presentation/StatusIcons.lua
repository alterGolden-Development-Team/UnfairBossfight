 
 
local Icons = {}
local circleImage = "rbxasset://textures/whiteCircle.png"
local kinds = {
 ClassAttackSpeedBoost="sword", ClassAttackDebuff="sword", ClassSlow="slow", ClassStaminaRegenBlock="sealed",
 P5God = "divinity",
 P5Spacetrum = "star", P5Verdant = "heart", P5Pastborn = "clock", P5Enraged = "flame", P5SuperEnraged = "flame",
 BossStunned="stunStars", BossTaunted="taunt", BossSlowed="slow", BossVulnerable="brokenHeart", BossBleed="drop", BossPoison="drop", BossBurn="flame", BossHolyFlame="flame",
	Vulnerability = "brokenHeart", CooldownIncrease = "clock", CooldownFreeze = "sealed",
	ChainCurse = "chain", TemporalWound = "clock", Acid = "drop",
	DeathMark = "star", JumpLock = "sealed", Blur = "eye",
	Rupture = "drop",
	IllusionRot = "eye",
	Frostbite = "slow",
	Hemorrhage = "drop",
	Corruption = "sealed",
	Decay = "brokenHeart",
	Dash = "wind",
	HPRegen = "heart",
	HPRegenBlock = "brokenHeart",
	StaminaRegenBlock = "sealed",
	AttackDebuff = "sword",
	CardBurn = "flame",
 AstralBurn = "flame",
	ProjectileDarkness = "eye",
	Stunned = "sealed",
 Cleanse = "shield",
	CupAttackBoost = "sword",
	CupRegenBoost = "heart",
	SpeedBoost = "wind",
	StaminaRegen = "energy",
	DamageBoost = "sword",
	DebuffImmunity = "shield",
	Slow = "slow",
	Bleed = "drop",
	Chained = "chain",
	Electricified="energy",
	Flung="wind",
	StolenSecond = "clock",
	P3Thief = "sealed",
	P3Illusion = "copies",
	LinkedSwap = "swap",
	LinkedClone = "puppet",
	GoldenBurn = "flame",
 Poison="drop",
 P4TrueSpirit="spirit",
 P4Karmanation="karma",
 ClassUndying="star",
 ClassUnbroken="star", ClassLastStand="shield", ClassCounterStance="sword", ClassHiddenReady="sword", ClassHolyStance="sword", ClassTruthCast="star", ClassAegis="shield", ClassLuck="star", ClassStored="shield", ClassTwinFlow="sword", ClassWhirling="wind", ClassTwinSpirits="spirit", ClassFinalReady="sword",
 ClassDisorderLaserSlow="energy", ClassDisorderCharge="energy", ClassMisplaceReady="swap",
 ClassGlitch="copies", ClassRedacted="shield", ClassOverwrite="energy", ClassCheckpoint="clock",
 ClassDamageBoost="sword", ClassDefenseBoost="shield", ClassHPRegen="heart", ClassStaminaRegen="energy", ClassSpeedBoost="wind", ClassUninterrupted="shield",
 ClassRampage="wind",
 ClassTaunt="taunt",
 ClassBlocking="shield",
 ClassSecondWind="heart",
 ClassParryLocked="sealed",
 ClassAlmighty="shield",
 ClassTrustedGun="flame",
 ClassParryStance="sword",
 ClassShieldRaised="shield",
 ClassRolling="copies",
 ClassStunned="star",
 ClassFateLinked="chain",
 ClassLaserCharge="energy",
 ClassSkillStolen="sealed",
 ClassTempo="energy",
 ClassDuelistGuard="shield",
 ClassDefenderGuard="shield",
 ClassExposed="sealed",
 ClassRiposte="sword",
 ClassPhasing="wind",
 ClassFlashstepReady="wind",
 ClassPhasingReady="wind",
 ClassPhaseCharge="sword",
 ClassWaltzCharge="sword",
 ClassOrbs="energy",
 ClassNextLife="heart",
 DiffHellaven="flame",
 DiffTrueHardcore="star",
 DiffHardcore="swap",
 DiffNerfedHardcore="eye",
 DiffEasy="heart",
 LogoWarrior="logoWarrior", LogoMage="logoMage", LogoTank="logoTank", LogoSupporter="logoSupporter", LogoGambler="logoGambler", LogoDuelist="logoDuelist", LogoTwinblade="logoTwinblade", LogoTrueWarrior="logoTrueWarrior", LogoDisorderer="logoDisorderer",
 Fear="sealed",
	Deceleration = "clock",
	GoldenMark = "star",
	Halved = "brokenHeart",
	P1Unstoppable = "goldBulwark",
	P15Clone = "goldMimic",
	P2HourDebt = "hourDebt",
	P25FutureSight = "oracle",
	P4Regeneration = "renewal",
	P4Enraged = "rage",
	P3GoldenMark = "goldSigil",
 P3Misdirection="mirage",
 P35Debuffer="brokenHeart",
	Acceleration = "energy",
}
local function rect(parent, x, y, w, h, color, rotation)
	local item = Instance.new("Frame")
	item.Name = "VectorStroke"
	item.AnchorPoint = Vector2.new(0.5, 0.5)
	item.Position = UDim2.fromScale(x, y)
	item.Size = UDim2.fromScale(w, h)
	item.Rotation = rotation or 0
	item.BorderSizePixel = 0
	item.BackgroundColor3 = color
	item.Parent = parent
	return item
end
local function circle(parent, x, y, w, h, color)
	local item = Instance.new("ImageLabel")
	item.Name = "VectorCurve"
	item.BackgroundTransparency = 1
	item.AnchorPoint = Vector2.new(0.5, 0.5)
	item.Position = UDim2.fromScale(x, y)
	item.Size = UDim2.fromScale(w, h or w)
	item.Image = circleImage
	item.ImageColor3 = color
	item.Parent = parent
	return item
end
local function line(parent, ax, ay, bx, by, color, width)
	local dx, dy = bx - ax, by - ay
	return rect(
		parent,
		(ax + bx) * 0.5,
		(ay + by) * 0.5,
		math.sqrt(dx * dx + dy * dy),
		width or 0.065,
		color,
		math.deg(math.atan2(dy, dx))
	)
end
local function outline(parent, points, color, closed, width)
	for index = 1, #points - (closed and 0 or 1) do
		local a, b = points[index], points[index % #points + 1]
		line(parent, a[1], a[2], b[1], b[2], color, width)
	end
end
local function ring(parent, x, y, size, color)
	local item = Instance.new("Frame")
	item.Name = "VectorRing"
	item.BackgroundTransparency = 1
	item.AnchorPoint = Vector2.new(0.5, 0.5)
	item.Position = UDim2.fromScale(x, y)
	item.Size = UDim2.fromScale(size, size)
	item.Parent = parent
	local corners = Instance.new("UICorner")
	corners.CornerRadius = UDim.new(0.5, 0)
	corners.Parent = item
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.6
	stroke.Parent = item
	return item
end
local function heart(root, color)
	circle(root, 0.34, 0.38, 0.4, 0.4, color)
	circle(root, 0.66, 0.38, 0.4, 0.4, color)
	rect(root, 0.5, 0.55, 0.44, 0.44, color, 45)
end
local function person(root, color, x, y, scale)
	circle(root, x, y - 0.18 * scale, 0.21 * scale, 0.21 * scale, color)
	local body = rect(root, x, y + 0.04 * scale, 0.34 * scale, 0.34 * scale, color)
	local rounded = Instance.new("UICorner")
	rounded.CornerRadius = UDim.new(0.28, 0)
	rounded.Parent = body
end
local function draw(root, kind, color)
	if kind=="goldBulwark" then
  outline(root,{{.18,.15},{.5,.07},{.82,.15},{.78,.56},{.5,.87},{.22,.56}},color,true,.075)
  outline(root,{{.34,.64},{.34,.36},{.5,.53},{.66,.36},{.66,.64}},color,false,.08)
  line(root,.12,.72,.06,.5,color,.06) line(root,.88,.72,.94,.5,color,.06)
 elseif kind=="logoWarrior" then
  outline(root,{{.2,.22},{.5,.12},{.8,.22},{.76,.6},{.5,.92},{.24,.6}},color,true,.075)
  line(root,.5,.06,.5,.66,color,.11)
  outline(root,{{.43,.12},{.5,.0},{.57,.12}},color,true,.06)
  line(root,.3,.44,.7,.44,color,.09)
  circle(root,.5,.74,.12,.12,color)
 elseif kind=="logoMage" then
  local halo=ring(root,.5,.52,.72,color) halo:FindFirstChildOfClass("UIStroke").Thickness=3
  circle(root,.5,.52,.34,.34,color)
  circle(root,.5,.16,.12,.12,color) circle(root,.85,.7,.12,.12,color) circle(root,.15,.7,.12,.12,color)
  line(root,.84,.08,.84,.26,color,.055) line(root,.75,.17,.93,.17,color,.055)
 elseif kind=="logoTank" then
  outline(root,{{.1,.14},{.5,.03},{.9,.14},{.85,.6},{.5,.97},{.15,.6}},color,true,.1)
  outline(root,{{.28,.3},{.5,.23},{.72,.3},{.69,.56},{.5,.77},{.31,.56}},color,true,.06)
  line(root,.5,.23,.5,.77,color,.07)
  line(root,.28,.42,.72,.42,color,.06)
 elseif kind=="logoSupporter" then
  local halo=ring(root,.5,.5,.86,color) halo:FindFirstChildOfClass("UIStroke").Thickness=3
  line(root,.5,.24,.5,.76,color,.14) line(root,.24,.5,.76,.5,color,.14)
  circle(root,.5,.05,.08,.08,color) circle(root,.5,.95,.08,.08,color) circle(root,.05,.5,.08,.08,color) circle(root,.95,.5,.08,.08,color)
 elseif kind=="logoGambler" then
  outline(root,{{.5,.04},{.88,.27},{.88,.73},{.5,.96},{.12,.73},{.12,.27}},color,true,.07)
  outline(root,{{.5,.27},{.74,.66},{.26,.66}},color,true,.06)
  line(root,.5,.27,.5,.04,color,.05) line(root,.5,.27,.12,.27,color,.05) line(root,.5,.27,.88,.27,color,.05)
  line(root,.74,.66,.88,.73,color,.05) line(root,.74,.66,.5,.96,color,.05)
  line(root,.26,.66,.12,.73,color,.05) line(root,.26,.66,.5,.96,color,.05)
 elseif kind=="logoDuelist" then
  line(root,.12,.88,.86,.14,color,.065) line(root,.88,.88,.14,.14,color,.065)
  line(root,.17,.61,.39,.83,color,.075) line(root,.61,.83,.83,.61,color,.075)
  circle(root,.1,.9,.1,.1,color) circle(root,.9,.9,.1,.1,color)
 elseif kind=="logoTrueWarrior" then
  outline(root,{{.2,.26},{.5,.16},{.8,.26},{.76,.62},{.5,.94},{.24,.62}},color,true,.07)
  line(root,.5,.0,.5,.7,color,.12)
  line(root,.3,.4,.7,.4,color,.09)
  outline(root,{{.3,.12},{.36,.02},{.43,.1},{.5,.0},{.57,.1},{.64,.02},{.7,.12}},color,false,.05)
  circle(root,.5,.78,.1,.1,color)
 elseif kind=="logoTwinblade" then
  line(root,.3,.92,.3,.12,color,.09) line(root,.7,.92,.7,.12,color,.09)
  outline(root,{{.24,.14},{.3,.04},{.36,.14}},color,true,.05) outline(root,{{.64,.14},{.7,.04},{.76,.14}},color,true,.05)
  line(root,.12,.68,.48,.68,color,.07) line(root,.52,.68,.88,.68,color,.07)
  outline(root,{{.5,.2},{.58,.4},{.5,.58},{.42,.4}},color,true,.05)
 elseif kind=="logoDisorderer" then
  outline(root,{{.5,.06},{.84,.25},{.84,.66},{.5,.85},{.16,.66},{.16,.25}},color,true,.07)
  line(root,.5,.46,.5,.85,color,.06) line(root,.5,.46,.16,.25,color,.06) line(root,.5,.46,.84,.25,color,.06)
  line(root,.06,.5,.36,.5,color,.05) line(root,.64,.62,.96,.62,color,.05)
  rect(root,.82,.12,.1,.1,color,45) rect(root,.14,.86,.08,.08,color,45)
 elseif kind=="goldMimic" then
  person(root,color,.28,.64,.75) person(root,color,.73,.64,.75)
  outline(root,{{.29,.23},{.25,.07},{.4,.18},{.5,.04},{.6,.18},{.75,.07},{.71,.23}},color,false,.065)
  line(root,.38,.42,.62,.42,color,.055)
 elseif kind=="hourDebt" then
  line(root,.25,.12,.75,.12,color,.08) line(root,.25,.88,.75,.88,color,.08)
  outline(root,{{.29,.17},{.32,.34},{.63,.68},{.7,.82}},color,false,.065)
  outline(root,{{.7,.17},{.66,.34},{.34,.68},{.29,.82}},color,false,.065)
  rect(root,.5,.72,.22,.11,color)
  line(root,.82,.4,.94,.4,color,.055) line(root,.84,.55,.96,.55,color,.055)
 elseif kind=="oracle" then
  outline(root,{{.1,.53},{.3,.35},{.5,.28},{.7,.35},{.9,.53},{.7,.7},{.5,.77},{.3,.7}},color,true,.065)
  outline(root,{{.5,.39},{.6,.53},{.5,.67},{.4,.53}},color,true,.07)
  line(root,.5,.05,.5,.18,color,.06) line(root,.2,.13,.29,.23,color,.06) line(root,.8,.13,.71,.23,color,.06)
 elseif kind=="renewal" then
  ring(root,.5,.5,.78,color)
  line(root,.18,.51,.3,.51,color,.065)line(root,.3,.51,.39,.34,color,.065)
  line(root,.39,.34,.51,.7,color,.065)line(root,.51,.7,.63,.44,color,.065)line(root,.63,.44,.83,.44,color,.065)
  line(root,.5,.15,.5,.28,color,.05)
 elseif kind=="rage" then
  outline(root,{{.2,.15},{.3,.35},{.14,.52},{.29,.86},{.5,.72},{.71,.86},{.86,.52},{.7,.35},{.8,.15}},color,true,.065)
  line(root,.25,.43,.43,.53,color,.09)line(root,.75,.43,.57,.53,color,.09)
  outline(root,{{.34,.67},{.42,.62},{.5,.68},{.58,.62},{.66,.67}},color,false,.055)
 elseif kind=="spirit" then
  ring(root,.5,.16,.23,color)
  outline(root,{{.5,.33},{.69,.44},{.73,.66},{.66,.87},{.49,.76},{.29,.88},{.36,.58},{.5,.33}},color,true,.07)
  circle(root,.48,.52,.13,.16,color)
  line(root,.17,.4,.12,.62,color,.05)line(root,.82,.34,.89,.55,color,.05)
 elseif kind=="divinity" then
  ring(root,.5,.47,.46,color)
  outline(root,{{.23,.38},{.15,.18},{.36,.29},{.5,.1},{.64,.29},{.85,.18},{.77,.38}},color,false,.07)
  for i=0,5 do local angle=i*math.pi/3 local x,y=math.cos(angle),math.sin(angle)
   line(root,.5+x*.31,.5+y*.31,.5+x*.45,.5+y*.45,color,.055)
  end
  line(root,.5,.37,.5,.59,color,.07)line(root,.39,.48,.61,.48,color,.07)
 elseif kind=="karma" then
  ring(root,.5,.52,.66,color)
  line(root,.5,.15,.5,.78,color,.06)line(root,.24,.32,.76,.32,color,.07)
  outline(root,{{.24,.36},{.12,.62},{.36,.62},{.24,.36}},color,true,.055)
  outline(root,{{.76,.36},{.64,.62},{.88,.62},{.76,.36}},color,true,.055)
  line(root,.37,.82,.63,.82,color,.065)
 elseif kind=="goldSigil" then
  outline(root,{{.5,.07},{.86,.5},{.5,.93},{.14,.5}},color,true,.065)
  outline(root,{{.5,.27},{.67,.5},{.5,.73},{.33,.5}},color,true,.055)
  circle(root,.5,.5,.12,.12,color)
  line(root,.04,.5,.11,.5,color,.055)line(root,.89,.5,.96,.5,color,.055)
 elseif kind=="mirage" then
  outline(root,{{.24,.28},{.78,.28},{.76,.6},{.61,.76},{.43,.7},{.27,.53}},color,true,.065)
  line(root,.34,.43,.45,.43,color,.08)line(root,.58,.43,.69,.43,color,.08)
  outline(root,{{.46,.58},{.55,.63},{.65,.57}},color,false,.055)
  outline(root,{{.15,.18},{.09,.5},{.27,.78}},color,false,.05)
  line(root,.86,.17,.95,.28,color,.045)line(root,.94,.16,.86,.28,color,.045)
 elseif kind=="puppet" then
  rect(root,.5,.14,.72,.08,color)
  line(root,.27,.2,.27,.51,color,.04)line(root,.73,.2,.73,.51,color,.04)
  person(root,color,.5,.64,1)
  line(root,.27,.51,.36,.64,color,.05)line(root,.73,.51,.64,.64,color,.05)
 elseif kind=="stunStars" then
  ring(root,.5,.56,.53,color)
  for _,p in ipairs({{.2,.25},{.76,.2},{.68,.79}}) do
   line(root,p[1]-.1,p[2],p[1]+.1,p[2],color,.055)
   line(root,p[1],p[2]-.1,p[1],p[2]+.1,color,.055)
  end
  circle(root,.4,.54,.07,.07,color)circle(root,.6,.54,.07,.07,color)
 elseif kind=="taunt" then
  outline(root,{{.16,.16},{.84,.16},{.84,.65},{.55,.65},{.32,.88},{.32,.65},{.16,.65}},color,true,.065)
  line(root,.5,.28,.5,.46,color,.09)circle(root,.5,.56,.09,.09,color)
 elseif kind == "heart" then
		heart(root, color)
	elseif kind == "brokenHeart" then
		heart(root, color)
		outline(
			root,
			{ { 0.56, 0.15 }, { 0.43, 0.42 }, { 0.59, 0.53 }, { 0.42, 0.87 } },
			Color3.fromRGB(9, 9, 9),
			false,
			0.12
		)
	elseif kind == "shield" then
		outline(
			root,
			{ { 0.18, 0.19 }, { 0.5, 0.08 }, { 0.82, 0.19 }, { 0.76, 0.61 }, { 0.5, 0.9 }, { 0.24, 0.61 } },
			color,
			true,
			0.075
		)
		line(root, 0.5, 0.25, 0.5, 0.67, color, 0.07)
	elseif kind == "energy" then
		outline(
			root,
			{ { 0.58, 0.08 }, { 0.28, 0.48 }, { 0.52, 0.48 }, { 0.41, 0.9 }, { 0.76, 0.4 }, { 0.51, 0.4 } },
			color,
			false,
			0.11
		)
	elseif kind == "sword" then
		line(root, 0.34, 0.65, 0.77, 0.18, color, 0.14)
		line(root, 0.73, 0.17, 0.81, 0.13, color, 0.14)
		line(root, 0.18, 0.52, 0.49, 0.83, color, 0.08)
		line(root, 0.3, 0.69, 0.17, 0.82, color, 0.085)
		circle(root, 0.14, 0.85, 0.1, 0.1, color)
	elseif kind == "drop" or kind == "flame" then
		rect(root, 0.5, 0.39, 0.34, 0.34, color, 45)
		circle(root, 0.5, 0.58, 0.53, 0.53, color)
		if kind == "flame" then
			line(root, 0.28, 0.32, 0.38, 0.58, color, 0.1)
			line(root, 0.67, 0.27, 0.71, 0.53, color, 0.1)
			local cut = Color3.fromRGB(20, 16, 8)
			circle(root, 0.5, 0.66, 0.2, 0.27, cut)
		end
	elseif kind == "eye" then
		outline(root, {
			{ 0.09, 0.5 },
			{ 0.28, 0.3 },
			{ 0.5, 0.23 },
			{ 0.72, 0.3 },
			{ 0.91, 0.5 },
			{ 0.72, 0.7 },
			{ 0.5, 0.77 },
			{
				0.28,
				0.7,
			},
		}, color, true, 0.065)
		ring(root, 0.5, 0.5, 0.27, color)
		circle(root, 0.5, 0.5, 0.11, 0.11, color)
	elseif kind == "clock" then
		ring(root, 0.5, 0.5, 0.72, color)
		line(root, 0.5, 0.24, 0.5, 0.5, color, 0.07)
		line(root, 0.5, 0.5, 0.7, 0.59, color, 0.07)
		rect(root, 0.5, 0.08, 0.13, 0.07, color)
		rect(root, 0.89, 0.5, 0.07, 0.13, color)
	elseif kind == "chain" then
		local a = ring(root, 0.35, 0.63, 0.34, color)
		a.Rotation = -35
		local b = ring(root, 0.65, 0.35, 0.34, color)
		b.Rotation = -35
		line(root, 0.4, 0.59, 0.61, 0.39, color, 0.09)
	elseif kind == "star" then
		local points = {}
		for index = 0, 9 do
			local angle = -math.pi * 0.5 + index * math.pi / 5
			local radius = index % 2 == 0 and 0.42 or 0.19
			table.insert(points, { 0.5 + math.cos(angle) * radius, 0.5 + math.sin(angle) * radius })
		end
		outline(root, points, color, true, 0.075)
		circle(root, 0.5, 0.5, 0.2, 0.2, color)
	elseif kind == "copies" then
		person(root, color, 0.65, 0.45, 0.83)
		person(root, color, 0.32, 0.65, 0.83)
	elseif kind == "swap" then
		line(root, 0.17, 0.34, 0.8, 0.34, color, 0.08)
		line(root, 0.8, 0.34, 0.65, 0.19, color, 0.08)
		line(root, 0.17, 0.65, 0.8, 0.65, color, 0.08)
		line(root, 0.17, 0.65, 0.32, 0.8, color, 0.08)
	elseif kind == "sealed" then
		ring(root, 0.5, 0.49, 0.66, color)
		line(root, 0.23, 0.76, 0.76, 0.23, color, 0.1)
	elseif kind == "slow" then
		outline(
			root,
			{ { 0.23, 0.18 }, { 0.32, 0.32 }, { 0.48, 0.34 }, { 0.46, 0.61 }, { 0.72, 0.69 } },
			color,
			false,
			0.11
		)
		line(root, 0.25, 0.82, 0.74, 0.82, color, 0.08)
		line(root, 0.63, 0.73, 0.74, 0.82, color, 0.08)
	else  
		line(root, 0.12, 0.31, 0.69, 0.31, color, 0.07)
		line(root, 0.22, 0.5, 0.87, 0.5, color, 0.08)
		line(root, 0.12, 0.69, 0.69, 0.69, color, 0.07)
		line(root, 0.72, 0.35, 0.87, 0.5, color, 0.07)
		line(root, 0.72, 0.65, 0.87, 0.5, color, 0.07)
	end
end
function Icons.Create(parent, id, size, position, color)
	local root = Instance.new("Frame")
	root.Name = "Icon"
	root.BackgroundTransparency = 1
	root.Size = size or UDim2.fromOffset(24, 24)
	root.Position = position or UDim2.fromOffset(0, 0)
	root:SetAttribute("StatusIcon", id)
	root.Parent = parent
	draw(root, kinds[id] or "star", color or Color3.fromRGB(255, 221, 95))
	return root
end
function Icons.Charge(parent, size, position, color)
	local item = circle(parent, 0.5, 0.5, 1, 1, color or Color3.fromRGB(255, 221, 95))
	item.Name = "PredictionCharge"
	item.AnchorPoint = Vector2.zero
	item.Size = size
	item.Position = position
	return item
end
Icons.Kinds = table.freeze(kinds)
return table.freeze(Icons)
