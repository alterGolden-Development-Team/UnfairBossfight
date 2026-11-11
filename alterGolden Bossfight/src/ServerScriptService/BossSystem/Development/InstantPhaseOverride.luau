local BossSystem = script:FindFirstAncestor("BossSystem")
local Config = require(game.ReplicatedStorage:WaitForChild("BossShared"):WaitForChild("Config"):WaitForChild("EncounterConfig"))
local api = {}
local choices = {
	{ Name = "ForcePhase5", Phase = 5 },
	{ Name = "ForcePhase45", Phase = 4.5 },
	{ Name = "ForcePhase35", Phase = 3.5 },
	{ Name = "ForcePhase4Test", Phase = 4 },
	{ Name = "ForcePhase3Test", Phase = 3 },
	{ Name = "ForcePhase25", Phase = 2.5 },
	{ Name = "ForcePhase2", Phase = 2 },
}
function api.Selected()
	if workspace:GetAttribute("EncounterEnraged") == true then
		return 5  -- the Enraged trial chosen in the lobby: straight into Phase 5
	end
	for _, choice in ipairs(choices) do
		local override = script.Parent:FindFirstChild(choice.Name)
		if override and override:IsA("Script") and override.Enabled then
			return choice.Phase
		end
	end
end
function api.Apply(actor, phase)
	local h = actor:FindFirstChildOfClass("Humanoid")
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not h or not root or h.Health <= 0 or not actor.Parent
		or actor:GetAttribute("EncounterEnded") or actor:GetAttribute("IsClone")
		or actor:GetAttribute("IsGoldenClone") then return false end
	if actor:GetAttribute("DevelopmentForcedPhase") == phase then return true end
	assert(phase == 2 or phase == 2.5 or phase == 3 or phase == 3.5 or phase == 4 or phase == 4.5 or phase == 5, "Unsupported forced phase")
	local p4 = math.floor(phase) == 4 or phase == 5
	local reason = "Force phase " .. tostring(phase)
	actor:SetAttribute("AIEnabled", false)
	actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
	actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
	require(BossSystem.Combat.PassiveController).Stop(actor)
	require(BossSystem.Combat.UltimateService).Cancel(actor, reason)
	require(BossSystem.Mechanics.Reality.RealityController).Cancel(actor)
	require(BossSystem.Phases.Phase25Controller).Cancel(actor, reason)
	require(BossSystem.Phases.Phase3Intro).Cancel(actor, reason)
	require(BossSystem.Mechanics.Clones.CloneController).CancelAll(actor, reason)
	require(BossSystem.Combat.CataclysmQTEService).CancelForActor(actor, reason)
	require(BossSystem.Mechanics.Time.TimeEffectController).ClearOwner(actor)
	require(BossSystem.Combat.EffectService).CancelOwner(actor, reason)
	require(BossSystem.Combat.StatusEffectService).ClearProjectileDarknessFor(actor)
	require(BossSystem.Phases.Phase3Intro).ClearVisual(actor)
	require(BossSystem.Combat.AbilityCooldownService).Clear(actor)
	for _, name in ipairs({
		"PhaseTransitionInProgress", "Phase15TransitionActive", "Phase25TransitionInProgress",
		"Phase3IntroActive", "Phase4TransitionInProgress", "MainPhaseIntroActive", "Phase2ShieldBreakSequenceActive",
		"Phase3GravityActive", "Phase3RecallActive", "ShieldBreakInProgress", "ShieldCloneGateActive",
		"Phase4ComboActive", "ExecutionLocked", "Invulnerable", "AttackInProgress", "ParryActive",
		"ShieldBroken", "LastMinuteUsed", "LastMinutePreparing", "LastMinuteActive", "ShieldDamageLocked",
		"LinkedProtection", "Phase3LinkedActive", "Phase4LinkedActive", "EtherealAcumenActive",
		"FutureSightActive", "CircularBarrageGunHeld", "TransitionKeepsTemporal",
	}) do actor:SetAttribute(name, false) end
	for _, name in ipairs({ "Phase15Triggered", "Phase2Triggered" }) do
		actor:SetAttribute(name, true)
	end
	actor:SetAttribute("Phase25Triggered", phase >= 2.5)
	actor:SetAttribute("Phase3Triggered", phase >= 3)
	actor:SetAttribute("Phase35Triggered", phase >= 3.5)
	actor:SetAttribute("Phase4Triggered", p4)
	actor:SetAttribute("Phase45Triggered", phase >= 4.5)
	actor:SetAttribute("Phase5Triggered", phase >= 5)
	actor:SetAttribute("Phase", phase)
	actor:SetAttribute("DevelopmentForcedPhase", phase)
	local title = phase == 5 and (Config.Phase5Title or Config.Phase45Title) or phase == 4.5 and (Config.Phase45Title or Config.Phase4Title) or p4 and Config.Phase4Title or phase == 3.5 and Config.Phase35Title or phase < 3 and Config.Phase2Title or Config.Phase3Title
	actor:SetAttribute("PhaseTitleOverride", title)
	actor:SetAttribute("IdentityRevealed", true)
	h.DisplayName = title
	h.MaxHealth = phase < 3 and Config.BossMaxHealth or p4 and Config.BossMaxHealth or Config.Phase3MaxHealth
	h.Health = phase < 3 and Config.Phase2HealthThreshold
		or phase == 5 and math.min(h.MaxHealth, Config.Phase5HealthThreshold or h.MaxHealth * 0.2)
		or phase == 4.5 and math.min(h.MaxHealth, Config.Phase45HealthThreshold or h.MaxHealth * 0.5)
		or h.MaxHealth
	actor:SetAttribute("BossHealth", h.Health)
	local maxShield = phase < 3 and Config.Phase2ShieldMaxHealth
		or p4 and Config.Phase4ShieldMaxHealth or Config.Phase3ShieldMaxHealth
	local shield = phase == 2.5 and Config.Phase25ShieldThreshold
		or phase == 3.5 and Config.Phase35ShieldThreshold or maxShield
	actor:SetAttribute("MaxShield", maxShield)
	actor:SetAttribute("Shield", shield)
	actor:SetAttribute("Defense", 0)
	actor:SetAttribute("UnstoppableDisabled", p4)
	actor:SetAttribute("FutureSightCharges", 0)
	actor:SetAttribute("FutureSightReadyAt", 0)
	actor:SetAttribute("ActiveAttackToken", nil)
	actor:SetAttribute("CurrentSkill", nil)
	actor:SetAttribute("CurrentAttackFile", "Idle")
	actor:SetAttribute("AttackState", "Idle")
	if phase < 3 then actor:SetAttribute("Phase2StartedAt", workspace:GetServerTimeNow()) end
	if phase == 2.5 then actor:SetAttribute("Phase25StartedAt", workspace:GetServerTimeNow()) end
	if phase >= 3 then actor:SetAttribute("Phase3StartedAt", workspace:GetServerTimeNow()) end
	if phase >= 3.5 then actor:SetAttribute("Phase35StartedAt", workspace:GetServerTimeNow()) end
	if p4 then actor:SetAttribute("Phase4StartedAt", workspace:GetServerTimeNow()) end
	if phase >= 4.5 then actor:SetAttribute("Phase45StartedAt", workspace:GetServerTimeNow()) end
	if phase == 5 then actor:SetAttribute("Phase5StartedAt", workspace:GetServerTimeNow()) end
	local glow = actor:FindFirstChild("ShieldGlow")
	if glow then glow.Enabled = true end
	require(BossSystem.Boss.WeaponController).SetUnarmed(actor, phase >= 3 and phase < 4)
	require(BossSystem.Boss.WeaponController).RefreshPhaseVisuals(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	core.Melee.Pose("Idle", 0)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow())
	actor:SetAttribute("AIEnabled", true)
	require(BossSystem.Combat.PassiveController).Start(actor, core.Melee.GetTarget)
	if phase < 3 then require(BossSystem.Phases.Phase25Controller).Start(actor) end
	if phase == 2.5 then require(BossSystem.Phases.Phase25Controller).ActivateFutureSight(actor) end
	require(BossSystem.Presentation.CombatAudio).Phase(actor, phase < 3 and phase or p4 and 4 or 3)
	if phase == 5 then pcall(require(BossSystem.Phases.Phase5Transition).ApplyForm, actor) end
	actor:SetAttribute("Enraged", workspace:GetAttribute("EncounterEnraged") == true or nil)
	return true
end
function api.ApplySelected(actor)
	local phase = api.Selected()
	return phase ~= nil and api.Apply(actor, phase) or false
end
function api.Bind(override)
	local function apply(actor)
		if actor:IsA("Model") and actor.Name == "alterGolden, the Nothing" then
			task.defer(function()
				if override.Parent and override.Enabled and actor.Parent then api.ApplySelected(actor) end
			end)
		end
	end
	local connection = workspace.ChildAdded:Connect(apply)
	for _, actor in ipairs(workspace:GetChildren()) do apply(actor) end
	override.Destroying:Connect(function() connection:Disconnect() end)
end
return api
