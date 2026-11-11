 
return table.freeze({
 Name="P5BlackHole", Cooldown=32,

  
 SummonTime=3.0, ActiveDuration=9, FadeTime=1.6, BurstAt=.62,
  -- summon: the hole forms between the boss's raised hands (HoldTime), then drifts out to
  -- hang over the landing point
 HoldTime=1.3, HandHeight=9,
  -- explosion when it collapses
 BurstRadius=45, BurstDamage=40, BurstSlow=.4, BurstSlowSeconds=2.5,  
 SkyHeight=130,

  
 CoreRadius=16, HoverHeight=40,  -- hangs in the sky; the kill zone is its ground shadow
 KillRadius=8, SpawnOffset=28, Margin=22,
 TargetHeight=3,  

  
 MoveSpeed=8, TrackingRate=2.0, StepRate=30,
 MoveRamp=.1,    

  
   -- a pull you can feel: ~10 studs/s at range, 17 near the shadow (walk 16), so close in you must dash;
  -- the acceleration cap must beat the humanoid's own grip or the pull barely moves anyone
 PullRange=150, PullMinSpeed=11, PullMaxSpeed=22, PullAccelerationLimit=1600, PullSpeedLimit=22, PullSwirl=.04,
 Escalation=.1,  

  
  
 ArmDelay=.55, ShockRadius=42, ShockSpeed=95, ShockAcceleration=190,

  
 Void=Color3.fromRGB(0,0,0), Violet=Color3.fromRGB(132,72,255),
 Gold=Color3.fromRGB(255,185,62), Pale=Color3.fromRGB(235,220,255),
})
