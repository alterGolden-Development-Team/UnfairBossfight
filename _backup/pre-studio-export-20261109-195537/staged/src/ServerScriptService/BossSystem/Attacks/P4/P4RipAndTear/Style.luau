 
 
local Sounds=table.freeze({
	Rip="SwordSlash",    
	Tear="SwordSlash",
	Rend="SwordSlash",
})

return table.freeze({
	Cooldown=6,
	Recover=.35,           
	Interval=.12,          
	Detail=1,              
	Sounds=Sounds,

	 
	ShockRings=true,       
	Debris=true,           
	Embers=true,           
	HitImpacts=true,       
	Afterimages=true,      

	 
	Indicator=Color3.fromRGB(255,224,40),      
	IndicatorHot=Color3.fromRGB(255,247,165),  

	 
	Windup=.3,             

	 
	SweepRange=30,
	SweepArc=200,
	SweepInner=5,          
	SweepDamage=45,
	SweepSwing=.1,         

	 
	CrossRange=42,
	CrossWidth=8,
	CrossAngle=24,         
	CrossDamage=20,        
	CrossSwing=.06,

	 
	VerticalRange=55,
	VerticalWidth=9,
	VerticalDamage=75,
	VerticalGap=.26,       
	VerticalSwing=.06,     

	 
	LungeTrigger=21,
	LungeStop=12,
	LungeTime=.16,

	 
	RiftDelay=.45,
	RiftDamage=35,
	RiftWidth=7,

	 
	EnrageHealth=.4,
	EnrageSpeed=.85,       
	EnrageSpread=18,       
	EnragedCooldown=5,
})