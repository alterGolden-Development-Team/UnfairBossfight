 
 
 
return table.freeze({
 Name="P5Finality(Ultimate)", Charge=8, Cooldown=55,

  
 Breath=1.5,     
 Recovery=1.4,   

  
 PillarDuration=2.5, PillarRadius=50, PillarHeight=220, HitPadding=2,
 PillarGrowTime=0.22,    
 PillarTaperTime=0.55,   
 PillarCoreRadius=12,    

  
  
  -- pull: the acceleration cap must beat the humanoid's grip or nobody moves
 PullRange=300, PullStart=12, PullEnd=26, PullAccelerationLimit=4200, PullSpeedLimit=40,
 SettleRadius=4,
 PullSwirl=0.04,          
 PulseFloor=0.8,         
 PulseSharpness=3.2,     

  
  
 ShockwaveInterval=0.45, ShockwaveIntervalEnd=0.12, ShockwaveSpeed=110, ShockwaveMaxRadius=400,
 ShockwaveDamage=12, WaveHitHeight=3, WaveKnockSpeed=28, WaveKnockLift=8,
 DetonationWaveDamage=25,
 MaxRings=40,
 DetonationWaves={
  {Speed=340,MaxRadius=495,Thickness=7,Delay=0},
  {Speed=320,MaxRadius=528,Thickness=6,Delay=.08},
  {Speed=300,MaxRadius=561,Thickness=8,Delay=.16},
  {Speed=280,MaxRadius=594,Thickness=5,Delay=.24},
  {Speed=260,MaxRadius=627,Thickness=9,Delay=.32},
  {Speed=250,MaxRadius=660,Thickness=6,Delay=.40},
  {Speed=240,MaxRadius=660,Thickness=8,Delay=.48},
  {Speed=225,MaxRadius=660,Thickness=11,Delay=.56},
 },

  
 Hover=5, HoverRise=1.8,

  
 SigilRadius=85,         
 OrbHeight=13, OrbRadiusEnd=8, StreamRadius=400,
 ShakeRange=700, ShakeDeg=2.4, ShakeStuds=0.45,
 FlashPeak=0.9,          

  
 Yellow=Color3.fromRGB(255,222,32), Gold=Color3.fromRGB(255,171,38), White=Color3.fromRGB(255,250,184),
 Void=Color3.fromRGB(10,7,2),

  
 SoundVolume=1,
 Sounds={
  Ignite="",       
  ChargeLoop="",   
  Beat="",         
  Inhale="",       
  Detonate="",     
  SubBoom="",      
  PillarLoop="",   
  Aftershock="",   
 },
})
