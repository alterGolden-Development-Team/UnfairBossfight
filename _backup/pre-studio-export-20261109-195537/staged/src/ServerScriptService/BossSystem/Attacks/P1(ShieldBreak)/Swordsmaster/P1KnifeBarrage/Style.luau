local Shared = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakCombat)
return {
	Gold = Shared.Gold,
	Bright = Shared.Bright,
	TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds",
	TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds",
	EMBER = Shared.Gold:Lerp(Color3.fromRGB(255, 70, 0), 0.55),
	DUST = Color3.fromRGB(205, 192, 168),
}
