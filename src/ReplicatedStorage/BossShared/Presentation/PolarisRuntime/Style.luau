return table.freeze({
  
 Name="P5Polaris(Ultimate)",
 Cooldown=65,
 Rise=.9,
 Charge=2,
 Hover=55,
 Shots=16,
  -- the cast lasts Duration seconds; the star volleys are spread across all of it (the last leaves FinalTail seconds before
  -- the end) so stars keep attacking until the timer runs out
 Duration=15,
 FinalTail=2.5,
 ShotGap=.6533,  -- (nominal: the Behavior works out the real gap from Duration and the tuned Shots for each cast)
  -- Borealis summoned alongside the stars: Roaming beams wander the arena and follow no one, Hunting beams follow a player
 Aurora={Roaming=10,Hunting=2,Windup=1.2,Tail=1.5,RoamSpeed=22,HuntSpeed=17,Roam=95,TickDamage=7},
 HitDamage=22,
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
 FinalRadius=400, FinalDamage=35,  -- the north star's explosion covers the whole map: 400 reaches every corner of the 620 x 460 arena from its middle
 ScreenRange=420,

  
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
