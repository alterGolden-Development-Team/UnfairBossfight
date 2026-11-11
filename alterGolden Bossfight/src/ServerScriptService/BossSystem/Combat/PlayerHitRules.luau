local S={}
local dots={P5Borealis=true,P5DyingStar=true,P5IrisStar=true,["P5Polaris(Ultimate)"]=true,Bleed=true,Hemorrhage=true,Poison=true,Acid=true,GoldenBurn=true,CardBurn=true,Rupture=true,ChainCurse=true,TemporalWound=true}
local breaks={P1FallingBlade=true,P1GoldenThrust=true,["P1.5GoldenLance"]=true,P4EnhancedThrust=true,P4SplittingSlash=true,P2DirectShot=true,P3Dash=true,["P4.5OrderBreak"]=true,["P5Hyper-lasticBeam(Ultimate)"]=true,
 ["Falling Blade"]=true,["Golden Thrust"]=true,["Golden Lance"]=true,["Enhanced Thrust"]=true,["Splitting Slash"]=true,["Direct Shot"]=true,["Golden Dash"]=true}
function S.PiercingDot(balance)
 return balance~=nil and balance.IsStatusDamage==true and dots[balance.Skill]==true
end
function S.BreaksBlock(balance,actor)
 if balance and balance.IsStatusDamage then return false end
 local skill=balance and balance.Skill or actor and actor:GetAttribute("CurrentSkill")
 return balance and balance.BreaksBlock==true or breaks[skill]==true
  or actor and (breaks[actor:GetAttribute("CurrentAttackFile")]==true or breaks[actor:GetAttribute("CloneSelectedAttack")]==true) or false
end
return table.freeze(S)
