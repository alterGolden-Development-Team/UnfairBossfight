local Config=require(game.ReplicatedStorage.BossShared.Config.BossDamageBalanceConfig)
local S={}
function S.Profile(actor,balance)
 local skill=balance and balance.Skill
 local profile=skill and Config.Profiles[skill]
 if not profile and actor then
  profile=Config.Profiles[actor:GetAttribute("CurrentAttackFile")]or Config.Profiles[actor:GetAttribute("CurrentSkill")]
 end
 return profile
end
function S.Resolve(amount,actor,balance)
 if type(amount)~="number"or amount~=amount or amount<=0 or amount==math.huge then return 0 end
 if balance and(balance.HealthDrain or(balance.IsStatusDamage and balance.Skill=="TemporalWound"))then return amount end
 local profile=S.Profile(actor,balance)
 if not profile then return amount end
 local status=balance and balance.IsStatusDamage==true
 if not status and profile.Hits and profile.Hits[amount]then return profile.Hits[amount]end
 return amount*(status and profile.Dot or profile.Direct)
end
return table.freeze(S)
