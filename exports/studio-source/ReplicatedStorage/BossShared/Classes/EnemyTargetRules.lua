local Rules = {}
function Rules.IsOrdinaryClone(target)
 return target:GetAttribute("IsGoldenClone")==true
  and target:GetAttribute("IsLinkedClone")~=true and target:GetAttribute("IsShieldGateClone")~=true
end
function Rules.IsEnemy(target)
 if not target or not target:IsA("Model") or target:GetAttribute("MageClone")
  or target:GetAttribute("AttackAimOnly") or Rules.IsOrdinaryClone(target) then return false end
 return target.Name=="alterGolden, the Nothing" or target:GetAttribute("IsLinkedClone")==true
  or target:GetAttribute("IsShieldGateClone")==true or target:GetAttribute("DamageableClone")==true
end
function Rules.Available(target)
 if not Rules.IsEnemy(target) or not target.Parent or target:GetAttribute("EncounterEnded")
  or target:GetAttribute("Invulnerable") or target:GetAttribute("ShieldDamageLocked")
  or target:GetAttribute("LinkedProtection") or target:GetAttribute("PhaseTransitionInProgress") then return false end
 local humanoid=target:FindFirstChildOfClass("Humanoid")
 return humanoid~=nil and humanoid.Health>0 and target:FindFirstChild("HumanoidRootPart")~=nil
end
return table.freeze(Rules)
