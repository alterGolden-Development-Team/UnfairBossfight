local WindUp,ApproachTime,StrokeTime,Fuse=.25,.16,.12,.48  -- Phase 5: quicker

return table.freeze({
	Cooldown=9,
	Radius=54,
	Damage=145,
	Width=13,
	Height=20,
	Gold=Color3.fromRGB(255,190,30),
	White=Color3.fromRGB(255,245,190),
	Hot=Color3.fromRGB(255,110,40),
	Ember=Color3.fromRGB(255,60,25),
	Violet=Color3.fromRGB(145,75,255),

	WindUp=WindUp,
	ApproachTime=ApproachTime,
	StrokeTime=StrokeTime,
	StrokePause=.08,
	Fuse=Fuse,
	WarnTime=.35,
	Delay=WindUp+ApproachTime+StrokeTime+Fuse,
	EndLag=.5,
	DashArc=2.5,

	DashDamage=60,
	DashHitRadius=7.5,
	EchoDamage=80,
	EchoDelay=.5,
	EchoWarn=.4,
	SealDamage=120,
	SealRadius=28,
	SealDelay=.45,

	 
	StarFallDamage=75,
	StarFallRadius=11,
	StarFallDelay=.5,  
	StarFallWarn=.55,
	SkySigilHeight=28,  
})
