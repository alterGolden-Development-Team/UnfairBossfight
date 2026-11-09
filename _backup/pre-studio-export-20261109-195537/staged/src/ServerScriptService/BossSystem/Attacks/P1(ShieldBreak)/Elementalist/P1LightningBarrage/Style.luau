local Shared = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakCombat)
return {
	Gold = Shared.Gold,
	Bright = Shared.Bright,
	TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds",
	CYAN = Color3.fromRGB(142, 220, 255),
	ICE = Color3.fromRGB(228, 246, 255),
	DEEP = Color3.fromRGB(70, 140, 255),
	VIOLET = Color3.fromRGB(150, 120, 255),
	SEGMENTS = 5,  
}
