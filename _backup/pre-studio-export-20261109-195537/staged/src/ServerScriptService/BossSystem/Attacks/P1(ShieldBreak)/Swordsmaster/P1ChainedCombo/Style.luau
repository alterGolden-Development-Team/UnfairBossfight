return table.freeze({
 Cooldown=12,Range=14,Windup=.5,TrapDuration=4.6,Resistance=.8,
 Stages={{"Sword",8},{"Sickle",8},{"Chain",8},{"Rapier",8},{"Laser",10},{"Hammer",18}},
  
 Timing={Default={.16,.22,.22},Laser={.26,.1,.26},Hammer={.42,.16,.3}},
 CustomWeapons=true,CustomChains=true,ScreenFlash=true,
 Colors={
  Steel=Color3.fromRGB(165,172,190),Dark=Color3.fromRGB(28,30,40),Gold=Color3.fromRGB(235,185,70),
  Core=Color3.fromRGB(255,246,222),Danger=Color3.fromRGB(255,70,50),
 },
 Palette={
  Sword={Color=Color3.fromRGB(255,205,90),Core=Color3.fromRGB(255,248,225)},
  Sickle={Color=Color3.fromRGB(170,95,255),Core=Color3.fromRGB(242,225,255)},
  Chain={Color=Color3.fromRGB(235,185,70),Core=Color3.fromRGB(255,246,222)},
  Rapier={Color=Color3.fromRGB(90,225,255),Core=Color3.fromRGB(235,252,255)},
  Laser={Color=Color3.fromRGB(255,60,60),Core=Color3.fromRGB(255,238,230)},
  Hammer={Color=Color3.fromRGB(255,120,35),Core=Color3.fromRGB(255,242,210)},
 },
})