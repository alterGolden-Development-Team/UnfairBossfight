return table.freeze({
 Name="P3.5IllusionBomb",  Cooldown=14,

  
  -- buffed 2026-10-30: more and bigger bombs, more of them real, more aimed at players, and a real
  -- hit staggers (slow) so the next wave is harder to step out of
 Bombs=28, RealChance=.7, Damage=30, Radius=14, HitHeight=7,
 HitSlow=.35, HitSlowSeconds=1.5,
 Windup=.5, LaunchGap=.08, FlightTime=1.5, ArcHeight=65, Margin=14,

  
  
  
  
  
  
 Volleys=table.freeze({
  table.freeze({Kind="Scatter",Share=.40}),
  table.freeze({Kind="Spiral",Share=.35}),
  table.freeze({Kind="Ring",Share=.25}),
 }),
 VolleyPause=.3,    
 MinSpacing=12,     
 HuntShare=.5,     
 HuntLead=.3,       
 HuntSpread=9,      

 StepRate=30,       

  
  
  
  -- all gold: real and illusion bombs look and burst the same, and nothing marks the ground
 TellStrength=0,
 NeutralColor=Color3.fromRGB(255,212,70),
 RealColor=Color3.fromRGB(255,196,40),
 FakeColor=Color3.fromRGB(255,196,40),
 AccentColor=Color3.fromRGB(255,240,170),
 SigilDiameter=24,
})
