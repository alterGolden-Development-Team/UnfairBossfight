return table.freeze({
  
 Name="P5Polaris(Ultimate)",
 Cooldown=65,
 Rise=.9,
 Charge=2,
 Hover=55,
 Shots=16,
 Duration=15,
 FinalTail=2.5,
 HitDamage=22,
 ShotGap=.6533,
 ProjectileSpeed=56,
 TurnRate=3.4,
 ProjectileLife=6,
 HitRadius=3.5,
 Burn={20,15,10},
 BurnOnce=true,
 BurnInterval=1,
 Recovery=.7,
  -- damage beats: release shockwave under the boss, and the final star explosion
 ReleaseRadius=34, ReleaseDamage=20,
 FinalRadius=400, FinalDamage=35,
 ScreenRange=260,

  
 Telegraph=.55,       
 GateHeight=85,       
 GateRadius=34,       

  
 Curtains=12,         
 CurtainRadius=70,
 CurtainHeight=30,
 Grade=true,          

  
  
  
 Sky=false,           -- night sky now comes from VFXEngine.Sky (PolarisNight)            
 SkyDim=.5,           
 Bloom=true,          
 Constellation=true,  
 DomeRadius=100,      
 DomeLift=5,          
 SeedFlight=1,        
 Pillars=true,        


  
  
  
 Sounds={
  Pulse="rbxasset://sounds/electronicpingshort.wav",  
  Chime="rbxasset://sounds/electronicpingshort.wav",  
  Boom="rbxasset://sounds/impact_explosion_03.mp3",   
  Whoosh="rbxasset://sounds/swordlunge.wav"           
 }
})
