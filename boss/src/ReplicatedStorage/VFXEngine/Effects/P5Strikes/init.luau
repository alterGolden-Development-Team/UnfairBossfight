--[[
 P5Strikes (client effect, a folder module: Core + the cue groups in this folder) - the Phase 5 normal attacks (Attacks/P5/NormalAttack) and the mode switch.
 Slashes are layered slash meshes cloned from VFXEngine.Assets (ArcSlash, StreakSlash): a bright core,
 a coloured glow copy behind it and a streak swirl, swept and scaled per frame, with Library sprites on
 top (claw.lines, claw.marks, wind.dash, butterfly). The butterfly wings are the MonarchWings mesh.
   Mode           {Boss, Mode}                                    a burst in the new mode's colours
   Blink          {From, To, Dark}                                a teleport: smoke where he was, a flash where he lands
   ClawTell       {Boss, Time}                                    a glint on the blade before the claws
   Claw           {Frame, Roll, Speed, Range, Width, Spread}      three parallel claw slashes flying out
   ClawHit        {Pos}                                           claw marks flash on whoever was hit
   AssassinTell   {Boss, Time, Victim}                            a dark aura on him, a red mark over the victim
   BlackSlash     {Frame, Index, Radius, Fake}                    a black crescent cut that hangs, then bursts
   UpperTell      {Boss, Pos, Time}                               the blade glints and wind gathers at the strike point
   UpperSlash     {Frame, Pos, Height}                            a vertical slash sweeping up from the ground
   Wings          {Boss, Time}                                    monarch wings open on his back, butterflies shed
   ButterflyDash  {From, To, Time}                                the dive's streak and butterflies
   ButterflyBurst {Pos, Radius}                                   wings of light flare open on landing
   PierceBeam     {Origin, Dir, Range, Time, Width}               Golden Pierce's laser beam
   HuntSlice      {Frame, Index}                                  a Wild Hunt air slice: a crescent across his front
   Shockwave      {Pos, Speed, Range, Look}                       a ring racing out along the floor
   SlamRaise / SlamImpact                                         Slam: gold gathers in the raised left hand; the impact
   ViperSpread / ViperThrust / ViperCatch / ViperBite             Viper: the hood, the snake strike, the drag, the fangs
   StabTell / GroundStab                                          Horrifying Ground: the raised blade; the stab
   TearerReady / TearerCharge / TearerBeam                        Night Tearer: the aura, the charge and red lane, the beam
   EternityTell / FrozenBlades / BladesRelease                    Golden Eternity: the sky clock, blades in stopped time, release
   Overclock / SlowClock                                          Overclock: his spinning clock hands; the slow clock under a player
   BigWarn        {Points, Radii, Time}                           big Flower-Field-style warning fields (Horrifying Ground)
   SilentStart / SilentStance / SilentCuts / SilentSheathe /       Silent Cut: the gold silence, the draw stance, the lines filling
   SilentShatter / SilentHit / SilentEnd                          the space, the sheathe, the shatter, the wound, colour back
   RiverCharge / RiverLunge / RiverCatch / RiverPierce            Scarlet River: the burning arm, the screeching lunge and river,
                                                                  the thorns on whoever is dragged, the pierce
   FireRingTell / FireRingCut / FireRing                          Fire Ring: the wind-up, the full-circle cut, the ring of fire
   EyeGlint / ShotgunBlast                                        Shotgun Blast: the star in his eye, the point-blank blast
   VerticalStance / VerticalSwing / VerticalSlash                 Perfect Vertical Slash: the still stance, the blade's arc, the
                                                                  upright crescent riding the lane and its ring-bursts of flame
   Warn           {Victim, Kind, Time, Lives}                     over a player: red LETHAL (lives) or gold JUMP
   CageWarn / SpikeCage                                           Horrifying Ground: the ring, the cage of unique spikes
   ViperTell      {From, To, Width, Time}                         the lane Viper will strike down
 The spikes themselves are VFXEngine.Effects.GroundShatter (Tall/Count).
 The server keeps every hit volume; this only draws.
]]
local Core=require(script.Core)
require(script.Slashes)
require(script.ViperTearer)
require(script.SilentRiver)
require(script.FireKnives)
require(script.ChronoBomb)
require(script.RootsStars)

return Core.P
