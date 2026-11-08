return table.freeze({
 Name="P3.5MysteriousGuy(Ultimate)", Cooldown=50,
 Palette=table.freeze({Void=Color3.fromRGB(20,8,38),Deep=Color3.fromRGB(64,26,120),Violet=Color3.fromRGB(150,84,255),Pale=Color3.fromRGB(228,210,255),Danger=Color3.fromRGB(255,64,104)}),
 FistNames=table.freeze({"RightHand","Right Hand","Right Arm","RightArm","RightLowerArm"}),
 SummonTime=.8, ChaseDuration=9, ChaseSpeed=30,
 CatchRadius=5, CatchHeight=4.5, Charge=1.15, PunchDamage=80,
  -- 2026-10-31: the punch summons swords (VFXEngine.Effects.ShadowSwords): a giant blade under the
  -- victim (SwordDamage on top of the punch, launches them) and rings of blades around it
 SwordDamage=40, LaunchSpeed=34, LaunchLift=34,
  -- reworked 2026-10-30: the shadow blinks at its prey, the punch erupts in thorns that hit everyone
  -- around it, and a shadow that catches no one erupts where it stands instead of fading away
 BlinkInterval=2.4, BlinkMin=14, BlinkMax=42, BlinkShare=.6,
 ShockRadius=24, ShockDamage=42, FearSeconds=2.5,
 EruptRadius=20, EruptDamage=45, EruptSlow=.4, EruptSlowSeconds=1.5,
 Recovery=.5, SpawnOffset=9, Margin=7,

  
 EmergeTime=.7,         
 EmergeSpeed=.55,       
 Weave=.3,              
 WarnDistance=17,       
 DissolveTime=.6,       

  
 WhiffRadius=5,         
 WhiffSlow=.4,          
 WhiffSlowTime=.75,
 WhiffCooldown=1.5,

  
 LiftHeight=1.6,        
 FistPart="",           
 FistOffset=Vector3.new(0,-1.2,0),
 ClientCinema=true,     

  
 Sounds=table.freeze({
  Summon="", Warn="", Whiff="", Seize="", Charge="", Punch="",
 }),
})
