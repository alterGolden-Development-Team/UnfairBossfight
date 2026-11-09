return table.freeze({
 Name="P5DyingStar",
 Cooldown=22,
 StarHeight=24,
 StarRadius=12,
 Beams=7,
 BeamGap=.3,
 BeamDamage=8,
 BeamRange=260,
 BeamRadius=3,
 BeamHitPadding=2,
 LatchRadius=16,
 LatchRange=230,
 BeamsBlockedByWalls=true,
 BeamLife=.24,
 OrbLife=3,  -- time budget for the throw
  -- the throw: climb high above the landing point, hang, then dive straight into the ground
 DiveHeight=95, RiseTime=.5, HangTime=.15, DiveSpeed=150,
 ExplosionRadius=28,
 BurstDamage=80,
 Tail=.9,
   -- summon -> beam barrage -> the star climbs high and dives onto the ground -> on landing it
   -- and the stars it summoned during the flight all detonate together
 SummonTime=1,
 ThrowDelay=.35,
 Fuse=0,  -- no wait: it blows the instant it hits the ground
 BurnAmounts={12,9,6}, BurnInterval=1,
 ClientFX=true,
 Quality=1,
 Sounds={
  Charge="rbxasset://sounds/electronicpingshort.wav",
  Beam="rbxasset://sounds/swordlunge.wav",
  Critical="rbxasset://sounds/electronicpingshort.wav",
  Boom="rbxasset://sounds/impact_explosion_03.mp3",
 },
})
