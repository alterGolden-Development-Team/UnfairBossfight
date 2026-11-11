--!nonstrict
--[[
 BossKit - the shared fight layer for every bossfight map (docs/boss-kit.md).

 One boss fight (the Golden Encounter) grew the game's combat: R6 bodies, lives, HP and stamina, dash (Q, i-frames), deflect (E),
 block (R), the classes and every class skill, the boss's HP and shield, damage numbers. That engine lives in
 "alterGolden Bossfight/src" (ServerScriptService.BossSystem, ReplicatedStorage.BossShared, the BossClient scripts); another boss
 place mounts those folders unchanged (see tutorial/default.project.json) and talks to them only through this module:

   -- server
   local BossKit = require(ReplicatedStorage.UnfairShared.BossKit)
   BossKit.Start({ Lives = 3, Class = "Warrior" })          -- before anyone spawns
   BossKit.Register(bossModel, { Title = "Azusa", Subtitle = "...", MaxHealth = 9000, Shield = 0, Color = pink })
   BossKit.Begin()                                         -- lives start counting
   BossKit.Hit(character, 30, bossModel, { Skill = "PetalStorm", Deflect = "Tap", BreaksBlock = false })
   BossKit.Warn(character, "Tap", 0.5)                     -- the deflect shield cue before a deflectable hit
   BossKit.Say("Dash through it!")                         -- the boss speaks, at the bottom of the screen like alterGolden
   BossKit.Fighters()                                      -- the characters still in the fight
   BossKit.Revive(player)                                  -- out of lives: back in with full lives
   BossKit.End()

   -- client
   require(ReplicatedStorage.UnfairShared.BossKit.BossBar).Mount()   -- the boss's HP / shield bar

 The boss model needs a Humanoid and a HumanoidRootPart. Players hit it with their class kits (it is registered as the class
 target); its HP and its shield (attribute "Shield") are taken by BossSystem's BossDamageService like any boss.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BossKit = {}
BossKit.BossBar = script:WaitForChild("BossBar")

local started = false
local options: { Lives: number?, Class: string? } = {}

local function bossSystem()
	local system = game:GetService("ServerScriptService"):FindFirstChild("BossSystem")
	assert(system, "BossKit needs ServerScriptService.BossSystem (mount it from alterGolden Bossfight, see tutorial/default.project.json)")
	return system
end

local function event(parent, name)
	local found = parent:FindFirstChild(name)
	if not found then
		found = Instance.new("RemoteEvent")
		found.Name = name
		found.Parent = parent
	end
	return found
end

-- The Golden Encounter keeps its slash meshes in VFXEngine.Assets (in its place file); the class kits wait for them. Another map
-- builds the same folder from their mesh ids.
local VFX_MESHES = {
	ArcSlash = { "rbxassetid://106616485006425", "", Vector3.new(14.3315, 8.626, 0.0961) },
	AnimeSlash = { "rbxassetid://114638860826912", "", Vector3.new(3, 0.001, 8.6603) },
	StreakSlash = { "rbxassetid://16269005425", "", Vector3.new(2048, 39.8048, 1755.7937) },
	MonarchWings = { "rbxassetid://14283900894", "rbxassetid://14283901021", Vector3.new(5.211, 4.1203, 2.5889) },
}
local function ensureVfxAssets(vfx)
	if not vfx or vfx:FindFirstChild("Assets") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Assets"
	local AssetService = game:GetService("AssetService")
	for name, spec in VFX_MESHES do
		local ok, part = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromUri(spec[1]))
		if ok and part then
			part.Name = name
			part.TextureID = spec[2]
			part.Size = spec[3]
			part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
			pcall(function()
				part.DoubleSided = true
			end)
			part.Parent = folder
		else
			warn("[BossKit] could not load the " .. name .. " mesh: " .. tostring(part))
		end
	end
	folder.Parent = vfx
end

-- The Golden Encounter keeps an R6 rig as StarterPlayer.StarterCharacter (everyone fights as R6; their look is put on it by
-- PlayerR6Appearance). A place without one gets a plain R6 rig.
local function ensureR6()
	local StarterPlayer = game:GetService("StarterPlayer")
	if StarterPlayer:FindFirstChild("StarterCharacter") then
		return
	end
	local ok, rig = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	if not ok then
		warn("[BossKit] could not make the R6 rig: " .. tostring(rig))
		return
	end
	rig.Name = "StarterCharacter" -- (it keeps Roblox's own R6 Animate script)
	rig.Parent = StarterPlayer
end

function BossKit.Start(opts)
	assert(RunService:IsServer(), "BossKit.Start is server only")
	if started then
		return
	end
	started = true
	options = opts or {}
	Players.CharacterAutoLoads = false -- PlayerEncounter loads characters itself (R6, with lives)
	-- remotes the Golden Encounter keeps in its place file
	local vfx = ReplicatedStorage:FindFirstChild("VFXEngine")
	if vfx then
		event(vfx, "Event")
	end
	for _, name in { "BossCombatEffects", "PlayerDash", "ViewAsServerToggle", "TemporalInput", "EncounterLifecycle" } do
		event(ReplicatedStorage, name)
	end
	ensureVfxAssets(vfx)
	ensureR6()
	local system = bossSystem()
	local encounter = require(system.Players.PlayerEncounter)
	require(system.Combat.StatusEffectService).Start(encounter.Damage)
	require(system.Players.R6DashService).Start(ReplicatedStorage.PlayerDash)
	require(system.Combat.DeflectService)
	local function joined(player)
		if options.Class then
			player:SetAttribute("PlayerClass", options.Class)
		end
	end
	for _, player in Players:GetPlayers() do
		joined(player)
	end
	Players.PlayerAdded:Connect(joined)
	encounter.Start()
	require(system.Players.Classes.ClassService).Start()
	-- anyone who spawned before this ran (as R15) comes back as R6
	for _, player in Players:GetPlayers() do
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h and h.RigType ~= Enum.HumanoidRigType.R6 then
			task.spawn(encounter.LoadCharacter, player, true)
		end
	end
	-- lives: the Golden Encounter takes them from its difficulty; a BossKit map says how many
	if options.Lives then
		local function setLives(player)
			player:SetAttribute("StartingLives", options.Lives)
			player:SetAttribute("LivesRemaining", options.Lives)
			if player.Character then
				player.Character:SetAttribute("LivesRemaining", options.Lives)
			end
		end
		for _, player in Players:GetPlayers() do
			setLives(player)
		end
		Players.PlayerAdded:Connect(function(player)
			task.defer(setLives, player)
		end)
	end
end

-- The boss: a model with a Humanoid and a HumanoidRootPart, parented to Workspace.
function BossKit.Register(model, info)
	info = info or {}
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	assert(humanoid and model:FindFirstChild("HumanoidRootPart"), "a BossKit boss needs a Humanoid and a HumanoidRootPart")
	model:SetAttribute("BossKit", true)
	model:SetAttribute("DamageableClone", true) -- the class kits' "enemy" rule (EnemyTargetRules) and BossDamageService's direct path
	humanoid.MaxHealth = info.MaxHealth or 5000
	humanoid.Health = humanoid.MaxHealth
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	model:SetAttribute("Shield", info.Shield or 0)
	model:SetAttribute("MaxShield", info.Shield or 0)
	model:SetAttribute("BossTitle", info.Title or model.Name)
	model:SetAttribute("BossSubtitle", info.Subtitle or "")
	model:SetAttribute("BossColor", info.Color or Color3.fromRGB(255, 206, 90))
	workspace:SetAttribute("ClassBossName", model.Name)
	local pointer = workspace:FindFirstChild("BossKitBoss") or Instance.new("ObjectValue")
	pointer.Name = "BossKitBoss"
	pointer.Value = model
	pointer.Parent = workspace
	return model
end

-- Gives the boss a (new) shield; the bar shows it over the HP.
function BossKit.SetShield(model, amount)
	model:SetAttribute("MaxShield", math.max(amount, model:GetAttribute("MaxShield") or 0))
	model:SetAttribute("Shield", amount)
end

-- The fight is on: deaths now cost lives.
function BossKit.Begin()
	workspace:SetAttribute("EncounterStarted", true)
end

function BossKit.End()
	workspace:SetAttribute("EncounterStarted", false)
end

function BossKit.Encounter()
	return require(bossSystem().Players.PlayerEncounter)
end

-- Characters of the players still fighting.
function BossKit.Fighters()
	local list = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local h = char and char:FindFirstChildOfClass("Humanoid")
		if h and h.Health > 0 and char:FindFirstChild("HumanoidRootPart") and not player:GetAttribute("PermanentlyDefeated") then
			table.insert(list, char)
		end
	end
	return list
end

-- True while the character's dash i-frames are on (a dash goes through anything).
function BossKit.Dashing(char)
	return workspace:GetServerTimeNow() < (char:GetAttribute("DashInvulnerableUntil") or 0)
end

-- The deflect shield cue (E), `seconds` before a deflectable hit lands. kind: "Tap" or "Hold".
function BossKit.Warn(char, kind, seconds)
	require(bossSystem().Combat.DeflectService).Warn(char, kind or "Tap", seconds)
end

-- Hurts a player the way the Golden Encounter does: dash i-frames, class block (R) and perfect guard, defence, the class
-- passives, damage numbers. opts.Deflect = "Tap"/"Hold": the hit can be deflected (call Warn first). Returns the damage dealt,
-- or "Deflected".
function BossKit.Hit(char, amount, source, opts)
	opts = opts or {}
	local system = bossSystem()
	if opts.Deflect and require(system.Combat.DeflectService).TryDeflect(char, opts.Deflect) then
		return "Deflected"
	end
	local balance = { Skill = opts.Skill or (source and source.Name) or "BossKit", BreaksBlock = opts.BreaksBlock == true,
		IgnoreDefense = false, IsStatusDamage = false }
	return require(system.Players.PlayerEncounter).Damage(char, amount, source, nil, balance)
end

-- The boss speaks: the line is typed out at the bottom of every screen, the way alterGolden talks (PlayerEncounterClient).
function BossKit.Say(text, seconds, player)
	local duration = seconds or math.clamp(#text * 0.055 + 1.4, 2, 9)
	BossKit.Encounter().Say(text, player, { Duration = duration })
	return duration
end

-- Back into the fight with full lives (after losing them all).
function BossKit.Revive(player, lives)
	local encounter = BossKit.Encounter()
	lives = lives or options.Lives or 3
	player:SetAttribute("PermanentlyDefeated", false)
	player:SetAttribute("DefeatReason", nil)
	player:SetAttribute("ExecutionPending", false)
	player:SetAttribute("LivesRemaining", lives)
	return encounter.LoadCharacter(player, true)
end

return BossKit
