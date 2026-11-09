local BossSystem=script:FindFirstAncestor("BossSystem")
local Registry=require(BossSystem.Combat.AttackRegistry)
local Shared=require(BossSystem.Attacks.Shared.ShieldBreakCombat)
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local pools=table.freeze({
 alterGolden=table.freeze({"P1Sniping","P1GroundShatter"}),
 Elementalist=table.freeze({"P1FireBullet","P1TornadoLeaf","P1LightningBarrage"}),
 Swordsmaster=table.freeze({"P1KnifeBarrage","P1ContinousStrike","P1ChainedCombo"}),
})
local cursors=setmetatable({}, {__mode="k"})
local api={}
function api.NameFor(role) return pools[role] and pools[role][1] end
function api.Allows(role,name) return pools[role]~=nil and table.find(pools[role],name)~=nil end
function api.Select(actor,role,target)
 if not Shared.Allowed(actor,role) then return nil end
 local pool=pools[role]
 for offset=1,#pool do
  local index=((cursors[actor] or 0)+offset-1)%#pool+1
  local name=pool[index]
  local inRange=name~="P1LightningBarrage" or target and target:FindFirstChild("HumanoidRootPart")
   and (target.HumanoidRootPart.Position-actor.HumanoidRootPart.Position).Magnitude<=Config.P1LightningRadius
  if inRange and Registry.For(actor,name).CanUse(target) then
   cursors[actor]=index
   return name
  end
 end
 return nil
end
function api.Cast(actor,role,target,name)
 if not Shared.Allowed(actor,role) then return false end
 name=name or api.Select(actor,role,target)
 if not api.Allows(role,name) then return false end
 return Registry.For(actor,name).Combo(target)
end
return api
