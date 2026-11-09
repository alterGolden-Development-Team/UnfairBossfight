local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local MovementConfig = require(Shared:WaitForChild("Config"):WaitForChild("PlayerMovementConfig"))
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Icons = require(Shared:WaitForChild("Presentation"):WaitForChild("StatusIcons"))
local Catalog = { CreateIcon = Icons.Create, CreateCharge = Icons.Charge }
local function percent(value)
	return string.format("%g%%", value * 100)
end
local entries = {
 ClassAttackSpeedBoost={Name="Attack Speed Boost",Description="Increases basic attack speed."},
 ClassAttackDebuff={Name="Attack Debuff",Description="Reduces outgoing damage."},
 ClassSlow={Name="Slow",Description="Reduces movement speed."},
 ClassStaminaRegenBlock={Name="Stamina Regen Block",Description="Reduces stamina regeneration."},
 BossStunned={Name="Stunned",Description="Cannot move or start attacks until the stun ends."},
 BossTaunted={Name="Taunted",Description="Defender draws enemy targeting while held. Already launched attacks keep their original trajectory."},
 BossSlowed={Name="Slowed",Description="Movement is reduced while the slowing effect remains active."},
 BossVulnerable={Name="Vulnerable",Description="Takes increased damage while vulnerability remains active."},
 BossBleed={Name="Bleeding",Description="Taking bleed damage over time."},
 BossPoison={Name="Poisoned",Description="Taking poison damage over time."},
 BossBurn={Name="Burning",Description="Taking burn damage over time."},
 BossHolyFlame={Name="Holy Flame",Description="Burned by holy fire, taking damage over time."},
 P5God = { Name = "Unlimited HP", Description = "He has a 1,000,000,000 shield. Fill the TP bar and press Z to break it down to 5,000." },
 P5Spacetrum = { Name = "Spacetrum", Description = "Space mode. Each Space attack calls down 3 to 5 Falling Stars around a player (at most once every 2 seconds). Watch the sky and keep moving." },
 P5Verdant = { Name = "Verdant", Description = "Natural mode. His shield regrows 15 every second, and every Natural hit poisons you (5 damage every 0.5 seconds)." },
 P5Pastborn = { Name = "Pastborn", Description = "Time mode. A clone from his past stands beside him and casts any move from Phase 1 to Phase 4.5, ultimates included. It cannot be hurt and fades when the mode ends." },
 P5Enraged = { Name = "Enraged", Description = "Unlimited HP broken. He attacks with almost no pause, and in normal mode he also uses 2 random moves from every mode you have defeated (never their ultimates)." },
 P5SuperEnraged = { Name = "Super Enraged", Description = "Enraged Gate. Unlimited HP broken. He attacks faster than ever, and in normal mode he also uses 3 random moves from every mode you have defeated (never their ultimates)." },
	Vulnerability = { Name = "Vulnerability", Description = "The next successful attack hit deals 35% extra damage, then consumes this mark. Damage over time does not consume it." },
	CooldownIncrease = { Name = "Cooldown Increase", Description = "Ability cooldowns recover at half speed. Their active durations are unchanged." },
	CooldownFreeze = { Name = "Cooldown Freeze", Description = "Ability cooldowns stop progressing for up to 3 seconds. Active ability durations continue." },
	ChainCurse = { Name = "Chain Curse", Description = "Every 2 seconds deals 6 damage to you and 4 damage to teammates within 24 studs. Nearby teammates take damage but do not inherit the curse." },
	TemporalWound = { Name = "Temporal Wound", Description = "Records damage taken and repeats 35% of it every 3 seconds. Its repeated damage cannot record itself." },
	Acid = { Name = "Acid", Description = "Deals 3 damage each second and lowers effective defense by 15 percentage points while active." },
	DeathMark = { Name = "Death Mark", Description = "Reapplying adds a stack and refreshes duration. At 5 stacks it bursts for 40 damage and clears the mark." },
	JumpLock = { Name = "Jump Lock", Description = "Disables jumping for up to 3 seconds. Walking and dashing remain available." },
	Blur = { Name = "Blur", Description = "Blurs the world view while active. HUD text stays clear." },
	Rupture = { Name = "Rupture", Description = "Moving deals 4 damage every 0.5 seconds. Each successful dash deals 8 damage, including through dash invulnerability." },
	IllusionRot = { Name = "Illusion Rot", Description = "Deals 3 damage each second while Darkness or Control Distortion is active. Pauses its damage when both end." },
	Frostbite = { Name = "Frostbite", Description = "Deals 3 damage each second and reduces movement speed by 20%." },
	Hemorrhage = { Name = "Hemorrhage", Description = "Deals 3 damage per stack each second. Reapplying adds a stack and refreshes duration, up to 5 stacks." },
	Corruption = { Name = "Corruption", Description = "Starts at 2 damage per second and gains 1 damage for each second it remains, capped at 12. Reapplying preserves the ramp." },
	Decay = { Name = "Decay", Description = "Deals 3 damage each second while active." },
 P3Misdirection={Name="Misdirection",Description="Projectile, Cards, Illusion Gun and True Illusion shots have a 50% chance to create one harmless fake. Internal cooldown: 6 seconds. A white-gold flash reveals the real attack shortly before impact."},
 P35Debuffer={Name="Debuffer",Description="Phase 3.5: every attack that lands has a 25% chance to inflict one random card debuff (rolled once per attack)."},
 Fear={Name="Fear",Description="HP and stamina regeneration stop for 2 seconds. Further attack hits refresh the duration."},
 ClassUndying={Name="Undying",Description="Immune to attacks (except life removal)."},
 ClassUnbroken={Name="Unbroken",Description="Alone: +30% damage and +20% defense. With allies: +10% damage."},
 ClassLastStand={Name="Last Stand",Description="You cannot be killed and deal +50% damage. When it ends a finisher deals 40% of the damage you dealt."},
 ClassCounterStance={Name="Counter",Description="The next hit is negated and answered with a ranged slash."},
 ClassHiddenReady={Name="King's Vow",Description="A hidden skill is ready."},
 ClassHolyStance={Name="Holy Counter",Description="The next hit is negated and returned five times over."},
 ClassTruthCast={Name="The Truth",Description="Channeling a beam of golden light."},
 ClassAegis={Name="Aegis",Description="Aegis charges built by guarding. Shield Charge adds 60 damage per charge and Aegis Burst turns them into healing and attack. Offensive mode loses them after 12s without a hit."},
 ClassLuck={Name="Luck",Description="Added to your next D20 roll (never above 19, and a natural 1 stays a 1) and +5% to the Jackpot win chance per stack. A roll above 10 spends it."},
 ClassStored={Name="Stored Damage",Description="40% of the damage Defender absorbs is stored (max 50% of your HP). Release F to blast it back at the boss."},
 ClassTwinFlow={Name="Twin Flow",Description="Each stack: +5% attack speed, +4% damage, +3% defense. A hit you take costs 1 stack. At 5+ stacks you cannot be flinched; at 10 your reach grows and cuts heal."},
 ClassWhirling={Name="Blade Whirl",Description="Spinning: 50% less damage taken, 75% speed. Dashing cancels the spin."},
 ClassTwinSpirits={Name="Twin Spirits",Description="Two spirit swords hunt the boss and keep cutting it. Flow is held at the maximum and your normal attack is a 360-degree sphere slash."},
 ClassFinalReady={Name="Final Destination",Description="Sky Cross landed: press F to become a storm of slashes."},
 ClassGlitch={Name="Glitch",Description="Glitch stacks on the boss: +4% damage for you and +3% for your allies per stack. Lasts 8s after the last bolt."},
 ClassDisorderLaserSlow={Name="Channeling",Description="Holding Convergence. You move slower while the beam is up."},
 ClassDisorderCharge={Name="Corrupting",Description="Charging Arena Glitch."},
 ClassMisplaceReady={Name="Second Jump",Description="Press F again within 4 seconds for a second teleport."},
 ClassRedacted={Name="Diamond Ward",Description="Inside a Diamond Protocol zone: 100% defense, immune to all damage, debuffs and executions."},
 ClassOverwrite={Name="Overwrite",Description="Bolts echo, Glitch is held at the maximum and nearby allies deal +25% damage. Press V again to reload the checkpoint."},
 ClassCheckpoint={Name="Checkpoint",Description="Every player's place, HP and stamina are saved. Tap V to send everyone back; anyone who died returns instantly."},
 ClassDamageBoost={Name="Attack Boost",Description="Increases outgoing damage. Each source keeps its own duration; the current percentage is shown in this description."},
 ClassDefenseBoost={Name="Defense Boost",Description="Increases defense, subject to the class defense cap."},
 ClassHPRegen={Name="Regeneration",Description="Increases health regeneration after the normal recovery delay."},
 ClassStaminaRegen={Name="Stamina Regen Boost",Description="Increases stamina regeneration."},
 ClassSpeedBoost={Name="Speed Boost",Description="Increases movement speed."},
 ClassUninterrupted={Name="Uninterrupted",Description="Defender resists combat stuns, restraints and knockback. Time stops and encounter sequences still apply."},
 ClassRampage={Name="Rampage",Description="+50% defense while charging."},
 ClassTaunt={Name="Taunt",Description="Ring waves draw every enemy toward you and reduce movement speed by 95% while Defender is held."},
 ClassBlocking={Name="Block",Description="+75% defense, -35% speed."},
 ClassSecondWind={Name="Second Wind",Description="Revive in place once at full HP."},
 ClassParryLocked={Name="Parry Locked",Description="Failed parry: V is locked."},
 ClassAlmighty={Name="Almighty Shield",Description="Shield HP absorbs damage first."},
 ClassTrustedGun={Name="Trusted Gun",Description="Six trusted rounds for 12s: 280 damage each, 450 for the final round. Accepted hits restore 5 stamina; no misfires."},
 ClassParryStance={Name="Parry",Description="The next hit is parried."},
 ClassShieldRaised={Name="Shield Raised",Description="+35% defense, faster charge."},
 ClassRolling={Name="Rolling",Description="+35% defense while the die rolls."},
 ClassStunned={Name="Stunned",Description="The boss is stunned."},
 ClassFateLinked={Name="Chain of Fate",Description="A fatal hit is prevented once."},
 ClassLaserCharge={Name="Charging",Description="Charging the Hyper-Laser."},
 ClassSkillStolen={Name="Skill Stolen",Description="The Thief stole one of your skills (F, C or V) for a few seconds."},
 ClassTempo={Name="Relentless Tempo",Description="Duelist: successful attacks heal 10% of actual damage dealt (scaled up in Phase 5). +5% attack speed per sword hit, up to +20%. Expires after 4s without a hit."},
 ClassDefenderGuard={Name="Defender's Guard",Description="A Tank holding Defender nearby: you take 25% less damage."},
 ClassExposed={Name="Exposed",Description="Natural 1 in Phase 5: you take 50% more damage."},
 ClassDuelistGuard={Name="Duelist's Guard",Description="The next damaging hit deals 50% less damage."},
 ClassRiposte={Name="Riposte",Description="Counter stance: the next attack is countered."},
 ClassPhasing={Name="Phasing",Description="Invincible while dashing."},
 ClassFlashstepReady={Name="Second Flashstep",Description="Press F again within 3 seconds for a second blink."},
 ClassPhasingReady={Name="Second Phase",Description="Press C again within 2.5 seconds for a second phase dash."},
 ClassPhaseCharge={Name="Phase Charge",Description="Invincible while charging. Keep holding C: at 1.5 seconds a charged phase slash is released. A hit taken in the first second is riposted."},
 ClassWaltzCharge={Name="Waltz Charge",Description="Invincible while gathering power and throughout the Final Waltz cinematic combo."},
 ClassOrbs={Name="Orbs",Description="Active Mage orbs. Spend them on Orb Dash, Bombardment or Clone."},
 ClassNextLife={Name="Next Life",Description="Supporter: stay alive to earn another life every 120 seconds."},
 DiffHellaven={Name="No Mercy",Description="Hellaven. Every hit alterGolden lands grants a Bloodlust stack: +4% damage for 6 seconds, up to 10 stacks (+40%). Each new hit refreshes them."},
 DiffTrueHardcore={Name="Golden Resolve",Description="True Hardcore. Below 25% health, alterGolden takes 15% less damage."},
 DiffHardcore={Name="Duelist's Honor",Description="Hardcore. Land 4 hits in a row without being hit and alterGolden staggers: exposed for 1.2 seconds and taking extra damage."},
 DiffNerfedHardcore={Name="Mentor's Patience",Description="Normal Mode. After alterGolden hits you, his attacks for the next 4 seconds give a doubled warning tell."},
 DiffEasy={Name="Gentle Heart",Description="Easy. Every 15 seconds alterGolden heals every player for 6% of their maximum health."},
 P4Karmanation={Name="Karmanation",Description="Every successful Phase 4 attack hit inflicts Fear for 2 seconds, preventing HP and stamina regeneration."},
 Poison={Name="Poison",Description="Deals 5 damage every 0.5 seconds for up to 10 seconds."},
 P4TrueSpirit={Name="True Spirit",Description="Every successful Phase 4 attack applies Golden Burn for 4 seconds. Further attack hits refresh its duration. Burn ticks do not refresh themselves."},
 Electricified={Name="Electricified",Description="Lasts for 10 seconds. Every 2 seconds it deals 10 damage and stuns you for 0.5 seconds."},
 Flung={Name="Flung",Description="Launches you outward and upward, briefly knocking you down. Movement returns when the debuff ends."},
	ProjectileDarkness = { Name = "Darkness", Description = "Surrounds you with dark mist, leaving a small clear area nearby for " .. Config.P3ProjectileDarknessDuration .. " seconds." },
	Stunned = { Name = "Stunned", Description = "Prevents movement while the stun or grab is active." },
	HPRegenBlock = { Name = "HP Regen Block", Description = "Blocks health regeneration for 5–10 seconds." },
	StaminaRegenBlock = { Name = "Stamina Regen Block", Description = "Blocks stamina regeneration for 5–10 seconds." },
	AttackDebuff = { Name = "Attack Down", Description = "Reduces outgoing attack damage by " .. percent(1 - Config.P3CardsAttackMultiplier) .. " for 5–10 seconds." },
	CardBurn = { Name = "Burn", Description = "Deals " .. Config.P3CardsBurnDamage .. " damage each second for 5–10 seconds." },
 Cleanse = {Name="Cleanse", Description="Removes all active debuffs, including Halved and Deceleration."},
	CupAttackBoost = { Name = "ATK Boost", Description = "A correct cup grants +" .. percent(Config.PickThePupilsRewardAttackMultiplier - 1) .. " attack for " .. Config.PickThePupilsAttackBoostDuration .. " seconds." },
	CupRegenBoost = { Name = "HP Regen Boost", Description = "A correct cup restores " .. percent(Config.PickThePupilsRewardHealFraction) .. " maximum HP each second for " .. Config.PickThePupilsRegenBoostDuration .. " seconds. HP Regen Block suppresses healing while active." },
	Halved = {
		Name = "Halved",
		Description = "Cards can apply a 50% Halved penalty. A failed Pick the Pupils round reduces maximum and current HP by 50% for the solo player or trapped pupil, and 15% for outside players. Stacks multiplicatively. Persists until death or a full Cleanse. Below 1 maximum HP is fatal.",
	},
	Dash = {
		Name = "Dash",
		Description = "Costs "
			.. MovementConfig.DashStaminaCost
			.. " stamina. Travels approximately "
			.. MovementConfig.DashDistance
			.. " studs, granting "
			.. MovementConfig.DashImmunityDuration
			.. " seconds of immunity.",
	},
	Slow = { Name = "Slow", Description = "Movement speed is reduced. Area slow ends when you leave its active area." },
	Bleed = { Name = "Bleed", Description = "Repeated damage equal to 1% of maximum HP per Bleed tick." },
	Chained = {
		Name = "Chained",
		Description = "Movement and Dash are restricted by the current chain/control effect.",
	},
	StolenSecond = {
		Name = "Stolen Second",
		Description = "Stores WASD movement for "
			.. Config.StolenSecondRecordingDuration
			.. " seconds, then replays it over "
			.. Config.StolenSecondReplayDuration
			.. " seconds. One Dash may be stored for release; it costs normal stamina and gives normal i-frames. Camera and HUD remain responsive.",
	},
	P3ControlDistortion = {
		Name = "Control Distortion",
		Description = "Rotates your movement and Dash direction while active. Movement stops when you stop input, and normal directions return when the effect ends.",
	},
	P3Thief = {
		Name = "Thief",
		Description = "Seals sword attacks and abilities while active. Dash remains available unless another effect separately restrains it.",
	},
	P3Illusion = {
		Name = "Illusion",
		Description = "alterGolden dashes as golden light into a mirror. Three matching figures exit left, forward and right; only one is real. Two harmless copies mimic his movement and attacks, then vanish after a few seconds.",
	},
	LinkedSwap = {
		Name = "Linked Swap",
		Description = "alterGolden and the Puppeteer can swap validated positions when neither is in an execution or transition. Both keep their own HP.",
	},
	LinkedClone = {
		Name = "alterGolden's Puppeteer",
		Description = Config.TrueCloneMaxHealth
			.. " HP. Defeat the Puppeteer to turn it into a golden star and expose alterGolden for "
			.. Config.TrueCloneReviveDelay
			.. " seconds. It then revives. Linked swaps preserve HP.",
	},
	AstralBurn = {Name="Burn",Description="Star energy burns over time. Ignores defense and shield HP; removed by Cleanse or death."},
 GoldenBurn = {
  Name="Golden Burn",
  Description="Golden magical flame deals a fixed 2 damage every 0.5 seconds.",
 },
	Deceleration = {
		Name = "Deceleration",
		Description = "Movement, regeneration, and class skill cooldown recovery are slowed to 50%.",
	},
	GoldenMark = {
		Name = "Golden Mark",
		Description = "Each stack increases incoming damage by "
			.. percent(Config.GoldenMarkDamagePerStack)
			.. ". Maximum "
			.. Config.GoldenMarkMaxStacks
			.. " stacks; refreshed duration "
			.. Config.GoldenMarkDuration
			.. " seconds.",
	},
	P1Unstoppable = {
		Name = "Unstoppable",
		Description = "Regains " .. Config.UnstoppableShieldRestore .. " Shield at the configured passive interval.",
	},
	P15Clone = {
		Name = "Clone",
		Description = "Independently summons a golden mimic without replacing the boss's normal attack. Restricted skills cannot be copied.",
	},
	P2HourDebt = {
		Name = "Hour Debt",
		Description = "An independent proc creates a hidden delayed afterimage that repeats the recorded attack. Restricted abilities cannot be copied.",
	},
	P25FutureSight = {
		Name = "Future Sight",
		Description = "Automatically predicts and dodges valid direct attacks while active, leaving golden afterimages. Cooldown: "
			.. Config.FutureSightCooldown
			.. " seconds.",
	},
	P4Regeneration = {
		Name = "Regeneration",
		Description = "Heals "
			.. percent(Config.Phase4RegenerationFraction)
			.. " of actual HP damage dealt to players: shield in Phase 4, HP in Phase 4.5, capped at the maximum. Shield healing pauses for 30 seconds after the shield breaks.",
	},
	P4Enraged = {
		Name = "Enraged",
		Description = "Each successful hit adds 1% critical chance and 2% bonus critical damage, capped at 100% chance and +200% damage (3x total). Lasts 10 seconds; every hit refreshes the duration.",
	},
	P3GoldenMark = {
		Name = "Golden Mark",
		Description = "Each successful Phase 3 hit, including absorbed class shield damage, applies one Golden Mark stack and increases incoming damage.",
	},
	Acceleration = {
		Name = "Acceleration",
		Description = "alterGolden's personal time and attack movement accelerate while this buff is active.",
	},
}
for id, entry in pairs(entries) do
	entry.Icon = Icons.Kinds[id]
end
Catalog.Entries = table.freeze(entries)
local gui, panel, title, description, detail, owner, resolve
local function position()
	if not panel then
		return
	end
	local mouse = Input:GetMouseLocation()
	local size = gui.AbsoluteSize
	panel.Position = UDim2.fromOffset(
		math.clamp(mouse.X + 14, 8, math.max(8, size.X - 298)),
		math.clamp(mouse.Y + 16, 8, math.max(8, size.Y - 186))
	)
end
local function ensureTooltip()
	if gui and gui.Parent then
		return
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "EncounterEffectTooltip"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 120
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	panel = Instance.new("Frame")
	panel.Name = "Tooltip"
	panel.Size = UDim2.fromOffset(290, 178)
	panel.BackgroundColor3 = Color3.fromRGB(12, 11, 9)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(162, 135, 66)
	stroke.Transparency = 0.3
	stroke.Parent = panel
	local function text(name, y, height, color)
		local item = Instance.new("TextLabel")
		item.Name = name
		item.BackgroundTransparency = 1
		item.Position = UDim2.fromOffset(12, y)
		item.Size = UDim2.new(1, -24, 0, height)
		item.Font = Enum.Font.Garamond
		item.TextColor3 = color
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.TextYAlignment = Enum.TextYAlignment.Top
		item.TextWrapped = true
		item.Parent = panel
		return item
	end
	title = text("Name", 9, 24, Color3.fromRGB(255, 228, 136))
	title.TextSize = 23
	description = text("Description", 37, 102, Color3.fromRGB(240, 237, 223))
	description.TextSize = 18
	detail = text("Detail", 149, 22, Color3.fromRGB(205, 199, 177))
	detail.TextSize = 17
end
function Catalog.RefreshTooltip()
	if not owner then
		return
	end
	local ancestor = owner
	while ancestor and not ancestor:IsA("ScreenGui") do
		if ancestor:IsA("GuiObject") and not ancestor.Visible then
			panel.Visible = false
			owner = nil
			resolve = nil
			return
		end
		ancestor = ancestor.Parent
	end
	if not owner.Parent or (ancestor and not ancestor.Enabled) then
		panel.Visible = false
		owner = nil
		resolve = nil
		return
	end
	local id, extra = resolve()
	local entry = Catalog.Entries[id]
	title.Text = entry and entry.Name or tostring(id)
	description.Text = type(extra)=="table" and extra.Description or entry and entry.Description or ""
	detail.Text = type(extra)=="table" and (extra.Detail or "") or extra or ""
end
function Catalog.AttachTooltip(item, id, extra)
	local function resolveItem()
  local resolvedId = id
  local resolvedExtra = extra
  if type(id) == "function" then resolvedId = id() end
  if type(extra) == "function" then resolvedExtra = extra() end
  return resolvedId, resolvedExtra
	end
	local connections = {}
	connections[1] = item.MouseEnter:Connect(function()
		ensureTooltip()
		owner = item
		resolve = resolveItem
		Catalog.RefreshTooltip()
		position()
		panel.Visible = true
	end)
	connections[2] = item.MouseMoved:Connect(function()
		if owner == item then
			position()
		end
	end)
	connections[3] = item.MouseLeave:Connect(function()
		if owner == item then
			panel.Visible = false
			owner = nil
			resolve = nil
		end
	end)
	connections[4] = item.Destroying:Connect(function()
		if owner == item then
			panel.Visible = false
			owner = nil
			resolve = nil
		end
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end)
end
return table.freeze(Catalog)
