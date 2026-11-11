 
 
 
local BASE = table.freeze({
	 
	 
	 
	Blood = Color3.fromRGB(212, 150, 18),       
	BloodDark = Color3.fromRGB(74, 46, 4),      
	BloodHot = Color3.fromRGB(255, 196, 38),    
	Edge = Color3.fromRGB(255, 244, 188),       
	Marked = Color3.fromRGB(255, 208, 64),      
	 
	Deep = Color3.fromRGB(150, 92, 6),          
	Void = Color3.fromRGB(16, 9, 0),            
	Vignette = Color3.fromRGB(72, 40, 0),       
	Flash = Color3.fromRGB(255, 240, 176),      

	 
	BladeMaterial = Enum.Material.Metal,
	ShaftMaterial = Enum.Material.Metal,

	 
	Cooldown = 80,
	 
	 
	 
	FormationDuration = 1.4,    
	JumpCueLead = 0.6,          
	HaltDuration = 2,           
	BossGripAlongShaft = 6,     
	GrowFromScale = 0.05,       
	ImpactDuration = 0.14,      
	SweepDuration = 0.34,       
	 
	WindupAngle = 0.9,          
	SwingPower = 2.2,           
	SmearCount = 3,             
	BaseSweepHeight = 1.5,
	HeightPerHead = 0.2,
	MaxPowerHeads = 5,
	LivesCost = 2,
	MaxReach = 400,  -- the scythe reaches at most this far from the boss; anyone farther is out of the sweep
	 
	 
	 
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = { FormationDuration = 1.0, JumpCueLead = 0.4, SweepDuration = 0.28, SmearCount = 5, LivesCost = 3 },
	Hardcore = { FormationDuration = 1.6, JumpCueLead = 0.7 },
	NerfedHardcore = { FormationDuration = 1.9, JumpCueLead = 0.85, HaltDuration = 2.4, LivesCost = 1 },
})
