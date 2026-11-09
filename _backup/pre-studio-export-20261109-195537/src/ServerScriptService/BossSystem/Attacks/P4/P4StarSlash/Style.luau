local WindUp,ApproachTime,StrokeTime,Fuse=.4,.25,.18,.7

return table.freeze({
	Cooldown=10,
	Radius=42,
	Damage=110,
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

	DashDamage=45,
	DashHitRadius=7.5,
	EchoDamage=60,
	EchoDelay=.75,
	EchoWarn=.4,
	SealDamage=90,
	SealRadius=22,
	SealDelay=.45,

	 
	StarFallDamage=55,
	StarFallRadius=11,
	StarFallDelay=.75,  
	StarFallWarn=.55,
	SkySigilHeight=28,  
})
