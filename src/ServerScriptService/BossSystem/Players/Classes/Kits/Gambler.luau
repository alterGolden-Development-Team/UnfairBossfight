local C=require(script.Parent.Common)
local Config=require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D=Config.Classes.Gambler
local B=script:FindFirstAncestor("BossSystem")
local Effects=require(B.Combat.EffectService)
local Runtime=require(B.Combat.CombatRuntime)
local Geometry=require(game.ReplicatedStorage.BossShared.Classes.D20Geometry)
local rng=Random.new()
local GOLD=D.Color
local K={}
local function lose(S,char,st,fraction)
 local h=char:FindFirstChildOfClass("Humanoid")
 if h and h.Health>0 then h.Health=fraction and math.max(1,math.floor(h.MaxHealth*fraction)) or 1 st.LastDamaged=os.clock() char:SetAttribute("LastHealthDamageAt",S.Now())end
end
function K.Start(S,player,char,st)
 st.Data.Luck=0 char:SetAttribute("GamblerLuck",0)
 st.Data.TrustedAmmo=0 char:SetAttribute("GamblerTrustedAmmo",0)
end
function K.OnBuffEnded(S,char,st,id)
 if id=="TrustedGun"then st.Data.TrustedAmmo=0 char:SetAttribute("GamblerTrustedAmmo",0)end
end
function K.Step(S,player,char,st)
 if S.HasBuff(char,"TrustedGun")then
  local value=string.format("%d/%d · %.1fs",st.Data.TrustedAmmo or 0,D.C.Ammo,math.max(0,(char:GetAttribute("ClassStatus_TrustedGun") or 0)-S.Now()))
  char:SetAttribute("ClassStatusText_TrustedGun",value)
 else char:SetAttribute("ClassStatusText_TrustedGun",nil)end
end
function K.CancelActions(S,char,st,reason)
 if reason~="Time" and st.Data.RollCast then st.Data.RollCast:Dispose()end
end
function K.Cleanup(S,char,st)
 K.CancelActions(S,char,st,"Cleanup")
 if char.Parent then char:SetAttribute("GamblerLuck",nil) char:SetAttribute("ClassStatus_Luck",nil) char:SetAttribute("ClassStatusText_Luck",nil) end
end
-- Loaded Luck: a roll of 10 or lower (after Luck) grows the pity bonus; anything above 10 spends it
function K.SetLuck(S,char,st,n)
 st.Data.Luck=n
 char:SetAttribute("GamblerLuck",n)
 char:SetAttribute("ClassStatus_Luck",n>0 and -1 or nil)
 char:SetAttribute("ClassStatusText_Luck",n>0 and ("x"..n) or nil)
end
function K.LuckyRoll(S,char,st,raw)
 local luck=st.Data.Luck or 0
 local eff=raw
 if raw~=1 and raw~=20 then eff=math.min(19,raw+luck) end  -- a natural 1 stays a 1, a natural 20 stays a 20, luck alone never makes a "natural" 20
 if eff<=10 then K.SetLuck(S,char,st,math.min(D.F.MaxLuck,luck+1)) else K.SetLuck(S,char,st,0) end
 return eff
end
function K.ApplyRoll(S,char,st,roll)
 assert(roll>=1 and roll<=20 and roll%1==0,"D20 result")
 S.RemoveStatBuff(char,"GamblerDice")
 S.Unbuff(char,"Exposed")
 local mods,text
 if roll==1 then
  if (workspace:GetAttribute("Phase5HealthMultiplier") or 1)>1 then S.Buff(char,"Exposed",D.F.Duration,{Incoming=1+D.F.Phase5Exposed}) else lose(S,char,st) end
  mods={Attack=.75,Speed=.8,StaminaRegen=0}text="NATURAL 1 · CRITICAL FAILURE"
 elseif roll<=5 then mods={Attack=.9}text=roll.." · ATTACK DEBUFF"
 elseif roll<=10 then mods={Defense=.15}text=roll.." · DEFENSE BOOST"
 elseif roll<=15 then mods={Attack=1.25}text=roll.." · ATTACK BOOST"
 elseif roll<=19 then mods={Attack=1.4,AttackSpeed=1.25}text=roll.." · ATTACK + ATTACK SPEED"
 else mods={Attack=1.6,AttackSpeed=1.4,StaminaRegen=1.5}text="NATURAL 20 · CRITICAL SUCCESS"end
 S.StatBuff(char,"GamblerDice",D.F.Duration,mods)
 char:SetAttribute("GamblerLastRoll",roll)
 S.FX.Text(char.HumanoidRootPart.Position+Vector3.new(0,4,0),text,roll>10 and GOLD or Color3.fromRGB(215,160,135))
 return text
end
local function shoot(S,char,st,aim,damage)
 local attack=S.NewAttack(char,"GamblerShot")
 if not attack then return false end
 local from=C.Hand(char)attack.Origin=from
 local direction=C.AimDir3D(from,aim,char.HumanoidRootPart.CFrame.LookVector)
 local finish=from+direction*D.M1.Range
 local best,bestDistance
 for _,target in S.Targets()do
  local position=target.HumanoidRootPart.Position
  local distance=(position-from):Dot(direction)
  if distance>0 and distance<=D.M1.Range and C.SegmentDistance(position,from,finish)<=4
   and (not bestDistance or distance<bestDistance)then best,bestDistance=target,distance end
 end
 local impact=best and from+direction*bestDistance or finish
 S.FX.Beam(from,impact,GOLD,.35,.18)
 S.FX.HQ.Glint(from+direction*.8,Color3.fromRGB(255,230,160),2.5,.12)
 S.FX.Release(from,direction,GOLD,1)
 if best and S.HitBoss(char,best,damage,"GamblerShot",attack)then
  S.FX.Hit(impact,GOLD,damage>=D.C.FinalDamage and 1.8 or 1.1,damage>=D.C.FinalDamage)
  return true
 end
 return false
end
function K.Action(S,player,char,st,key,phase,aim)
 if phase~="Begin"then return end
 local root=char.HumanoidRootPart local h=char:FindFirstChildOfClass("Humanoid")
 if key=="M1"then
  if not S.Ready(char,"M1")then return end
  local trusted=S.HasBuff(char,"TrustedGun") and (st.Data.TrustedAmmo or 0)>0
  local final=trusted and st.Data.TrustedAmmo==1
  S.Cooldown(char,"M1",trusted and D.C.FireInterval or D.M1.Cooldown)
  S.Anim(char,"Shoot")S.Sound(char,"LanceLaunch")
  local damage=trusted and (final and D.C.FinalDamage or D.C.Damage) or D.M1.Damage
  if trusted then
   st.Data.TrustedAmmo-=1 char:SetAttribute("GamblerTrustedAmmo",st.Data.TrustedAmmo)
   if st.Data.TrustedAmmo<=0 then S.Unbuff(char,"TrustedGun")end
  end
  if shoot(S,char,st,aim,damage) and trusted then
   char:SetAttribute("Stamina",math.min(char:GetAttribute("MaxStamina") or D.Stamina,(char:GetAttribute("Stamina") or 0)+D.C.StaminaOnHit))
  end
 elseif key=="F"then
  if not S.Ready(char,"F") or st.Data.RollCast then return end
  S.Cooldown(char,"F",D.F.Cooldown)S.Anim(char,"Roll")S.Sound(char,"ThreadBounce")
  S.Buff(char,"Rolling")
  S.StatBuff(char,"GamblerRolling",nil,{Defense=D.F.RollDefense})
  local raw=rng:NextInteger(1,20)
  local roll=K.LuckyRoll(S,char,st,raw)
  local start=C.Hand(char,"Left")
  local aimLanding=root.Position+C.AimDir(char,aim)*9
  local ground=require(B.Encounter.ArenaPlacement).GroundPoint(aimLanding)
  local landing=ground and ground+Vector3.new(0,.92,0) or aimLanding-Vector3.new(0,2.05,0)
  local cast=Effects.NewCast(char,"GamblerD20Roll",D.F.Roll+.8)st.Data.RollCast=cast
  cast.OnDispose=function()
   if st.Data.RollCast==cast then st.Data.RollCast=nil end
   S.Unbuff(char,"Rolling")S.RemoveStatBuff(char,"GamblerRolling")
  end
  local ok,die=pcall(Geometry.Build,Runtime.Effects,CFrame.new(start),1.8,true)
  if not ok then cast:Dispose()error(die)end
  cast:Add(die)
  local began=cast:Now()local resolved=false
  cast:Step(function(_,at)
   if not S.Alive(char) or S.State(char)~=st then cast:Dispose()return false end
   if not S.CanAct(char)then return true end
   local progress=math.clamp((at-began)/D.F.Roll,0,1)
   local flight=math.clamp(progress/.8,0,1)
   local position=start:Lerp(landing,flight)+Vector3.new(0,math.sin(flight*math.pi)*6,0)
   local goal=Geometry.FaceUp(roll)
   local spin=CFrame.Angles(progress*math.pi*8,progress*math.pi*6,progress*math.pi*3)
   local rotation=progress<.8 and spin or spin:Lerp(goal,(progress-.8)/.2)
   die:PivotTo(CFrame.new(position)*rotation)
   if progress>=1 and not resolved then
    resolved=true K.ApplyRoll(S,char,st,roll)
    S.FX.Ring(landing,GOLD,6,.4)S.Sound(char,"ThreadBounce")
    cast:Schedule(.6,function()cast:Dispose()end)
   end
   return true
  end)
 elseif key=="C"then
  if not S.Ready(char,"C") or S.HasBuff(char,"TrustedGun")then return end
  S.Cooldown(char,"C",D.C.Cooldown)
  st.Data.TrustedAmmo=D.C.Ammo char:SetAttribute("GamblerTrustedAmmo",D.C.Ammo)
  S.Buff(char,"TrustedGun",D.C.Duration)
  S.Anim(char,"Twirl")S.Sound(char,"GuardActivate")
  S.FX.Flash(C.Hand(char),GOLD,5,.4)
 elseif key=="V"then
  if not S.Ready(char,"V")then return end
  S.Cooldown(char,"V",D.V.Cooldown)
  local winChance=.5+D.F.JackpotLuck*(st.Data.Luck or 0)
  if rng:NextNumber()<winChance then
   K.SetLuck(S,char,st,0)
   h.Health=h.MaxHealth char:SetAttribute("Stamina",char:GetAttribute("MaxStamina") or D.Stamina)
   S.StatBuff(char,"GamblerJackpot",D.V.Duration,{Attack=3,Defense=.95,Speed=1.25,StaminaRegen=2})
   S.Anim(char,"Jackpot")S.Sound(char,"QTESuccess")
   S.FX.Flash(root.Position,GOLD,22,.8)S.FX.Text(root.Position+Vector3.new(0,4,0),"JACKPOT!",GOLD)
   char:SetAttribute("GamblerLastGamble","Jackpot")
  else
   K.SetLuck(S,char,st,math.min(D.F.MaxLuck,(st.Data.Luck or 0)+1))
   local p5=(workspace:GetAttribute("Phase5HealthMultiplier") or 1)>1
   lose(S,char,st,p5 and .15 or nil)S.Anim(char,"Bankrupt")S.Sound(char,"QTEFailure")
   S.Cooldown(char,"V",D.V.Cooldown*.5)
   S.FX.Text(root.Position+Vector3.new(0,4,0),p5 and "HP: 15%" or "HP: 1",Color3.fromRGB(220,80,75))
   char:SetAttribute("GamblerLastGamble","Bankrupt")
  end
 end
end
return K
