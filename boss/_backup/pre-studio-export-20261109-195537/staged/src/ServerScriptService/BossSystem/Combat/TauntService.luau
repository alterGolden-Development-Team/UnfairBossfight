local B=script:FindFirstAncestor("BossSystem")
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Runtime=require(B.Combat.CombatRuntime)
local Placement=require(B.Encounter.ArenaPlacement)
local S={}
function S.Target(actor)
 if actor and actor:GetAttribute("MageClone") then return nil end
 local root=actor and actor:FindFirstChild("HumanoidRootPart")
 local best,bestDistance
 local now=workspace:GetServerTimeNow()
 for _,p in Players:GetPlayers() do
  local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid") local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r and c:GetAttribute("TankDefenderHeld")==true
   and now<(c:GetAttribute("TauntingUntil") or 0)
   and not p:GetAttribute("ViewAsServer") and not p:GetAttribute("PermanentlyDefeated")
   and not p:GetAttribute("ExecutionPending") and Placement.Contains(r.Position) then
   local distance=root and (root.Position-r.Position).Magnitude or 0
   if not best or distance<bestDistance then best,bestDistance=c,distance end
  end
 end
 return best
end
function S.Enemies()
 local list={}
 for _,actor in Runtime.Targets() do
  if not Players:GetPlayerFromCharacter(actor) and not actor:GetAttribute("MageClone")
   and not actor:GetAttribute("AttackAimOnly") then table.insert(list,actor) end
 end
 return list
end
function S.Refresh()
 local now=workspace:GetServerTimeNow()
 for _,actor in Runtime.Targets() do
  if not Players:GetPlayerFromCharacter(actor) and not actor:GetAttribute("MageClone")
   and not actor:GetAttribute("AttackAimOnly") then
   local target=S.Target(actor)
   local p=target and Players:GetPlayerFromCharacter(target)
   if p then
    local deadline=target:GetAttribute("TauntingUntil") or now
    if math.abs(deadline-(actor:GetAttribute("TauntedUntil") or 0))>=0.2 then actor:SetAttribute("TauntedUntil",deadline) end
    if actor:GetAttribute("TauntedBy")~=p.DisplayName then actor:SetAttribute("TauntedBy",p.DisplayName) end
   elseif actor:GetAttribute("TauntedUntil") then
    actor:SetAttribute("TauntedUntil",nil) actor:SetAttribute("TauntedBy",nil)
   end
  end
 end
end
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<0.1 then return end elapsed=0 S.Refresh()
end)
return S
