--!strict
--[[
 What the class showroom can show, per class: every skill, its hold version, and the hidden ones.
 A move is a short script of key presses the server plays on the showroom performer (TryoutService), exactly as a player's input
 would arrive. Each run starts from a fresh copy of the class with every cooldown cleared, so a combo always has what it needs.
 The client lists the buttons from this table; the server only accepts move ids found here.

 Step forms:
   { key = "M1" }                 a tap (Begin, End right after)
   { key = "C", hold = 1.2 }      press, hold for that long, release
   { key = "F", aim = "Cube" }    aim somewhere other than the target dummy ("Cube": Disorderer's thrown cube, "Watcher": you,
                                  "Sky": high above and behind the performer, so a thrown cube stays in the air)
   { wait = 0.5 }                 pause
   { untilStatus = "FinalReady", timeout = 4 }   wait for a class status to show up on the performer
]]
export type Step = { key: string?, hold: number?, aim: string?, wait: number?, untilStatus: string?, timeout: number? }
export type Move = { Id: string, Label: string, Name: string, Text: string, Hidden: boolean?, Steps: { Step } }

local function taps(key: string, count: number, gap: number): { Step }
	local out: { Step } = {}
	for i = 1, count do
		table.insert(out, { key = key })
		if i < count then
			table.insert(out, { wait = gap })
		end
	end
	return out
end

local function join(...: { Step }): { Step }
	local out: { Step } = {}
	for _, list in { ... } do
		for _, step in list do
			table.insert(out, step)
		end
	end
	return out
end

local Moves: { [string]: { Move } } = {
	Warrior = {
		{ Id = "M1", Label = "Click", Name = "Sword Attack", Text = "A sword swing for 140 damage.", Steps = taps("M1", 3, 0.6) },
		{ Id = "F", Label = "F", Name = "Switch", Text = "Swap between Offensive and Defensive mode. Offensive mode deals +10% damage while the boss has a shield.", Steps = { { key = "F" } } },
		{ Id = "C", Label = "C", Name = "X-Slash", Text = "Offensive mode: launch an X-shaped slash for 325 damage.", Steps = { { key = "C" } } },
		{ Id = "FC", Label = "F + C", Name = "Shield Charge", Text = "Defensive mode: raise the shield (+35% defense, faster) and charge along your aim, shield-slamming the boss for 80 damage plus 60 per Aegis charge.", Steps = { { key = "F" }, { wait = 0.35 }, { key = "C" } } },
		{ Id = "V", Label = "V", Name = "Conclusion", Text = "Offensive mode: a quick dash that deals 100 damage.", Steps = { { key = "V" } } },
		{ Id = "FV", Label = "F + V", Name = "Aegis Burst", Text = "Defensive mode: spend every Aegis charge. Heals you 3% max HP per charge and nearby allies 1.5%, and gives everyone in range +10% attack per charge for 6s.", Steps = { { key = "F" }, { wait = 0.35 }, { key = "R", hold = 0.8 }, { wait = 0.2 }, { key = "V" } } },
		{ Id = "R", Label = "R", Name = "Guard", Text = "Hold to guard: +75% defense. Every blocked hit becomes an Aegis charge (max 5); a perfect guard just before a hit negates it and gives 2.", Steps = { { key = "R", hold = 1.2 } } },
	},
	Mage = {
		{ Id = "M1", Label = "Click", Name = "Orb Shot", Text = "Fire an orb that explodes for 85 damage. Each hit summons 2-4 more orbs near the target.", Steps = taps("M1", 3, 0.55) },
		{ Id = "F", Label = "F", Name = "Orb Dash", Text = "Consume 8 nearby orbs to dash and stack +35% defense for 4s. Dash again while 8 orbs remain.", Steps = join(taps("M1", 5, 0.55), { { wait = 0.4 }, { key = "F" } }) },
		{ Id = "C", Label = "C", Name = "Bombardment", Text = "Tap: detonate up to 35 orbs, nearest the boss first, for 100 damage each.", Steps = join(taps("M1", 5, 0.55), { { wait = 0.4 }, { key = "C", hold = 0.1 } }) },
		{ Id = "HoldC", Label = "Hold C", Name = "Orb Clone", Text = "Hold: pull every orb into the wand and summon a fighting copy that shoots the boss.", Steps = join(taps("M1", 5, 0.55), { { wait = 0.4 }, { key = "C", hold = 0.9 } }) },
		{ Id = "V", Label = "V", Name = "Hyper-Laser", Text = "Charge 2.5s, then a laser that deals 28 damage per tick for up to 80 ticks and spawns orbs.", Steps = { { key = "V" }, { wait = 6.5 } } },
	},
	Tank = {
		{ Id = "M1", Label = "Click", Name = "Shield Slam", Text = "Lunge and slam the shield for 175 damage.", Steps = taps("M1", 2, 1.6) },
		{ Id = "F", Label = "Hold F", Name = "Defender", Text = "Hold: taunt, +70% defense, allies nearby take 25% less damage. 40% of the damage absorbed is stored; release F to blast it back in a 14-stud shockwave.", Steps = { { key = "F", hold = 1.8 } } },
		{ Id = "C", Label = "C", Name = "Rampage", Text = "Charge with +50% defense until you hit the boss: 150 damage and a 3s stun.", Steps = { { key = "C" } } },
		{ Id = "V", Label = "V", Name = "Almighty", Text = "Give nearby players a shield worth 200% of their max HP.", Steps = { { key = "V" } } },
	},
	Supporter = {
		{ Id = "M1", Label = "Click", Name = "Sonar Wave", Text = "A wave that lightly damages the boss and heals allies it passes.", Steps = taps("M1", 3, 0.85) },
		{ Id = "F", Label = "F", Name = "Healing", Text = "Heal an aimed ally for 35% max HP, remove a debuff, and boost their stamina regen and attack for 5s. (Shown on you.)", Steps = { { key = "F", aim = "Watcher" } } },
		{ Id = "C", Label = "C", Name = "Chain of Fate", Text = "Link to an ally. A fatal hit leaves them at 1 HP, swaps you, and grants 5s of Undying. (Shown on you.)", Steps = { { key = "C", aim = "Watcher" } } },
		{ Id = "V", Label = "V", Name = "Second Wind", Text = "Sacrifice a life: everyone revives in place once at full HP with skills restored.", Steps = { { key = "V" } } },
	},
	Gambler = {
		{ Id = "M1", Label = "Click", Name = "Gunshot", Text = "An aimed shot for 200 damage.", Steps = taps("M1", 2, 1.05) },
		{ Id = "F", Label = "F", Name = "Roll the Dice", Text = "Throw a D20 (+35% defense while it rolls). A natural 1 leaves you at 1 HP; a natural 20 gives the strongest boosts. Lasts 8s.", Steps = { { key = "F" }, { wait = 2 } } },
		{ Id = "C", Label = "C", Name = "Trusted Gun Companion", Text = "Load six trusted rounds for 12s: 280 damage each, 450 on the final round.", Steps = join({ { key = "C" }, { wait = 0.5 } }, taps("M1", 6, 0.65)) },
		{ Id = "V", Label = "V", Name = "JACKPOT?!?!", Text = "50%: full HP, +200% attack, +95% defense and more for 15s. 50%: HP becomes 1 and the cooldown is halved.", Steps = { { key = "V" } } },
	},
	Duelist = {
		{ Id = "M1", Label = "Click", Name = "Swift Cuts", Text = "Quick sword strikes, 75 damage each.", Steps = taps("M1", 5, 0.38) },
		{ Id = "F", Label = "F", Name = "Flashstep", Text = "Blink through enemies for 150. A hit unlocks a second blink within 3s for 100.", Steps = { { key = "F" }, { wait = 0.7 }, { key = "F" } } },
		{ Id = "C", Label = "C", Name = "Phasing", Text = "Tap: a short invincible phase dash for 150. Tap again within 2.5s for a second dash.", Steps = { { key = "C", hold = 0.05 }, { wait = 0.6 }, { key = "C", hold = 0.05 } } },
		{ Id = "HoldC", Label = "Hold C", Name = "Phase Slash", Text = "Hold 1.5s: a charged phase slash for 450. A hit taken in the first second is riposted for 400.", Steps = { { key = "C", hold = 1.6 } } },
		{ Id = "V", Label = "V", Name = "Final Waltz", Text = "Blink to the boss, five cuts from every direction (100 each), then a 250 finishing slash with a shockwave.", Steps = { { key = "V" }, { wait = 4 } } },
	},
	Twinblade = {
		{ Id = "M1", Label = "Click", Name = "Crossing Cuts", Text = "A five-cut chain: 110 per cut and 260 on the crossing finisher that lunges into the target.", Steps = taps("M1", 5, 0.26) },
		{ Id = "F", Label = "F", Name = "Blade Whirl", Text = "Spin into a whirlwind for 1.4s: six hits of 90, 50% less damage taken.", Steps = { { key = "F" } } },
		{ Id = "C", Label = "C", Name = "Sky Cross", Text = "Leap high, chain the boss, reel in along the chain and crash down in an X slash: 350 damage, up to 3x with Flow.", Steps = { { key = "C" } } },
		{ Id = "V", Label = "V", Name = "Twin Spirits", Text = "Two spirit swords hunt the boss for 12s; your normal attack becomes a 360-degree sphere slash for 220.", Steps = join({ { key = "V" }, { wait = 0.9 } }, taps("M1", 4, 0.3)) },
		{ Id = "Final", Label = "C then F", Name = "Final Destination", Hidden = true, Text = "HIDDEN. Press F within 3s of landing Sky Cross: vanish into a 150-stud storm of slashes (18 hits of 120, then a 600 finisher), invincible throughout.", Steps = { { key = "C" }, { untilStatus = "FinalReady", timeout = 4 }, { wait = 0.1 }, { key = "F" }, { wait = 3.2 } } },
	},
	Disorderer = {
		{ Id = "M1", Label = "Click", Name = "Static Orbs", Text = "Each hand fires an orb for 70 damage. Orbs stack Glitch on the boss.", Steps = taps("M1", 3, 0.5) },
		{ Id = "HoldM1", Label = "Hold Click", Name = "Convergence", Text = "Hold: both hands fire a laser that fuses into a core, burning the boss for 52 damage every 0.15s.", Steps = { { key = "M1", hold = 2.4 } } },
		{ Id = "F", Label = "F", Name = "Misplace", Text = "Teleport to your aim within 40 studs. Use it twice within 4s. Each jump leaves a glitched copy that hunts the boss and explodes for 420.", Steps = { { key = "F" }, { wait = 0.8 }, { key = "F" } } },
		{ Id = "C", Label = "C", Name = "Diamond Protocol", Text = "Tap: raise a 30s diamond. Everyone inside is immune to all damage, debuffs and executions.", Steps = { { key = "C", hold = 0.1 } } },
		{ Id = "HoldC", Label = "Hold C", Name = "Diamond Cube", Text = "Hold 0.7s: forge a diamond cube and throw it for a 900 damage glitch explosion.", Steps = { { key = "C", hold = 0.9 } } },
		{ Id = "V", Label = "V", Name = "Checkpoint", Text = "Tap: save everyone's place, HP and stamina. Tap again to send everyone back and restore them.", Steps = { { key = "V", hold = 0.1 }, { wait = 1.5 }, { key = "V", hold = 0.1 } } },
		{ Id = "HoldV", Label = "Hold V", Name = "Arena Glitch", Text = "Hold: corrupt yourself, then release a shockwave that glitches the arena: random buffs for allies, random damage and debuffs for the boss.", Steps = { { key = "V", hold = 0.7 }, { wait = 3 } } },
		{ Id = "Falter", Label = "Hold C, then F", Name = "Falter", Hidden = true, Text = "HIDDEN. Throw the diamond cube, then Misplace onto it while it flies: rise into the sky and fall on the boss for 4,040,404 damage.", Steps = { { key = "C", hold = 0.9, aim = "Sky" }, { wait = 0.3 }, { key = "F", aim = "Cube" }, { wait = 9 } } },
	},
	TrueWarrior = {
		{ Id = "M1", Label = "Click", Name = "Judgement Cuts", Text = "A three-hit chain: 150, 150 and a 320 finisher.", Steps = taps("M1", 3, 0.45) },
		{ Id = "F", Label = "F", Name = "Victorious Throw", Text = "Hurl the shield: 200 damage and a 1.5s stun, then it flies back.", Steps = { { key = "F" }, { wait = 1.5 } } },
		{ Id = "C", Label = "C", Name = "Vow Slash", Text = "Charge 1.1s with i-frames, then a supersonic golden slash with unlimited range for 600.", Steps = { { key = "C" }, { wait = 1.8 } } },
		{ Id = "V", Label = "V", Name = "Last Stand", Text = "A charging cutscene, then a 360-degree slash for 400 that grows each time. A hit gives Last Stand: you cannot be killed and deal +50% damage.", Steps = { { key = "V" }, { wait = 2.6 } } },
		{ Id = "R", Label = "R", Name = "Counter", Text = "A 0.7s counter stance. A hit taken during it is negated and answered with a ranged slash for 350.", Steps = { { key = "R", hold = 0.2 }, { wait = 0.8 } } },
		{ Id = "Holy", Label = "V then R", Name = "Holy Counter", Hidden = true, Text = "HIDDEN. After the first Last Stand slash lands, R becomes a holy counter: the next hit is negated and returned five times over, and the boss burns.", Steps = { { key = "V" }, { wait = 2.6 }, { untilStatus = "HiddenReady", timeout = 3 }, { key = "R", hold = 0.2 }, { wait = 2 } } },
		{ Id = "Truth", Label = "V, V then F", Name = "The Truth", Hidden = true, Text = "HIDDEN. After the second Last Stand slash, F channels a beam of golden light for 8 hits of 300 that heals you half your HP.", Steps = { { key = "V" }, { wait = 2.8 }, { key = "V" }, { wait = 2.8 }, { untilStatus = "HiddenReady", timeout = 3 }, { key = "F" }, { wait = 2.6 } } },
		{ Id = "Supreme", Label = "V, V, V then C", Name = "Supreme King Slash", Hidden = true, Text = "HIDDEN. The third Last Stand slash turns Vow Slash into Supreme King Slash: a 170-stud blade for 3000.", Steps = { { key = "V" }, { wait = 2.8 }, { key = "V" }, { wait = 2.8 }, { key = "V" }, { wait = 2.8 }, { untilStatus = "HiddenReady", timeout = 3 }, { key = "C" }, { wait = 3 } } },
	},
}

local api = {}

function api.For(classId: string): { Move }
	return Moves[classId] or {}
end

function api.Find(classId: string, moveId: string): Move?
	for _, move in api.For(classId) do
		if move.Id == moveId then
			return move
		end
	end
	return nil
end

return table.freeze(api)
