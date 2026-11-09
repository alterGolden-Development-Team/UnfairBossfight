 
 
local Sounds=table.freeze({
	Rip="SwordSlash",    
	Tear="SwordSlash",
	Rend="SwordSlash",
})

return table.freeze({
	Cooldown=7,
	Recover=.35,           
	Interval=.08,          
	Detail=1,              
	Sounds=Sounds,

	 
	ShockRings=true,       
	Debris=true,           
	Embers=true,           
	HitImpacts=true,       
	Afterimages=true,      

	 
	Indicator=Color3.fromRGB(255,224,40),      
	IndicatorHot=Color3.fromRGB(255,247,165),  

	 
	Windup=.2,             

	 
	SweepRange=38,
	SweepArc=200,
	SweepInner=5,          
	SweepDamage=60,
	SweepSwing=.1,         

	 
	CrossRange=55,
	CrossWidth=8,
	CrossAngle=24,         
	CrossDamage=28,        
	CrossSwing=.06,

	 
	VerticalRange=75,
	VerticalWidth=9,
	VerticalDamage=100,
	VerticalGap=.18,       
	VerticalSwing=.06,     

	 
	LungeTrigger=21,
	LungeStop=12,
	LungeTime=.16,

	 
	RiftDelay=.45,
	RiftDamage=50,
	RiftWidth=7,

	 
	EnrageHealth=1.01,  -- Phase 5: always at its worst
	EnrageSpeed=.85,       
	EnrageSpread=18,       
	EnragedCooldown=5,
})