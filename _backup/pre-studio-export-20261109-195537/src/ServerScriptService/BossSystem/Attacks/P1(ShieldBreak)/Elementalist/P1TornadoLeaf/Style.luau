local Shared = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakCombat)
return {
	Gold = Shared.Gold,
	Bright = Shared.Bright,
	Receiver = Color3.fromRGB(50, 43, 25),
	Aim = Color3.fromRGB(255, 65, 40),
	Leaf = Color3.fromRGB(113, 184, 53),
	Light = Color3.fromRGB(176, 232, 96),  
	Dark = Color3.fromRGB(62, 128, 38),  
	Wind = Color3.fromRGB(226, 255, 214),  
	Dust = Color3.fromRGB(170, 160, 120),  
	TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds",
}
