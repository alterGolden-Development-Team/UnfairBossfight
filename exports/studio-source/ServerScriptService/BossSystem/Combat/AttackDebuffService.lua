local B=script:FindFirstAncestor("BossSystem")
local Status=require(B.Combat.StatusEffectService)
local Cards=require(B.Combat.CardDebuffService)
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local api={}
local scopes=setmetatable({},{__mode="k"})
local function seen(key,char,name)
 if not key then return false end
 local scope=scopes[key]
 return scope and scope[char] and scope[char][name]==true
end
local function remember(key,char,name)
 if not key then return end
 local scope=scopes[key]
 if not scope then scope=setmetatable({},{__mode="k"});scopes[key]=scope end
 scope[char]=scope[char] or {}
 scope[char][name]=true
end
function api.Apply(actor,char,name,seconds,key)
 if not actor or not actor.Parent or actor:GetAttribute("IsIllusion")
  or actor:GetAttribute("EncounterEnded") or actor:GetAttribute("PhaseTransitionInProgress")
  or seen(key,char,name) then return false end
 local applied
 if name=="Bleed" then applied=Status.ApplyBleed(char,seconds,actor)
 elseif name=="Fear" then applied=Status.ApplyFear(char,seconds,actor)
 else applied=Status.ApplyAdvancedDebuff(char,name,seconds,actor) end
 if applied then remember(key,char,name) end
 return applied==true
end
function api.Random(actor,char,rng,key,skill)
 if not actor or not actor.Parent or actor:GetAttribute("IsIllusion") or actor:GetAttribute("EncounterEnded")
  or actor:GetAttribute("PhaseTransitionInProgress") or seen(key,char,"Random") then return nil end
 rng=rng or Random.new()
 local duration=rng:NextNumber(Config.P3CardsDebuffMinDuration or 5,Config.P3CardsDebuffMaxDuration or 10)
 local chosen
 if Cards.RollHalved(rng) and Status.ApplyCardDebuff(char,"Halved",duration,actor) then chosen="Halved" end
 local pool={}
 local orbit=char:GetAttribute("EtherealOrbitActive")==true
 local function eligible(name)
  return name~="Halved" and not (orbit and (name=="Flung" or name=="StolenSecond" or name=="Chained" or name=="Stunned"))
 end
 for _,name in ipairs(Cards.Names) do
  if eligible(name) and (name=="DeathMark" or name=="Hemorrhage" or not Cards.Active(char,name)) then pool[#pool+1]=name end
 end
 if #pool==0 then for _,name in ipairs(Cards.Names) do if eligible(name) then pool[#pool+1]=name end end end
 while not chosen and #pool>0 do
  local name=table.remove(pool,rng:NextInteger(1,#pool))
  if Status.ApplyCardDebuff(char,name,duration,actor) then chosen=name end
 end
 if chosen then
  remember(key,char,"Random")
  actor:SetAttribute("LastRandomDebuff",chosen)
  if skill=="P3EtherealAcumen(Ultimate)" then actor:SetAttribute("LastEtherealAcumenDebuff",chosen)
  else actor:SetAttribute("LastTrueIllusionDebuff",chosen) end
 end
 return chosen
end
return api
