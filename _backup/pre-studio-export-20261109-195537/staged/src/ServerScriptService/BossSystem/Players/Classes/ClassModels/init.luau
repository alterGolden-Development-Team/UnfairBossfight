local M = {}
local Builders = {
	Warrior = require(script.Warrior),
	Mage = require(script.Mage),
	Tank = require(script.Tank),
	Supporter = require(script.Supporter),
	Gambler = require(script.Gambler),
	Duelist = require(script.Duelist),
	Twinblade = require(script.Twinblade),
	TrueWarrior = require(script.TrueWarrior),
}

function M.Build(char, id)
	local old = char:FindFirstChild("ClassGear")
	if old then
		old:Destroy()
	end
 local saved=char:FindFirstChild("ClassAvatarAccessories")
 local useAvatar=true
 if saved then saved:Destroy() end
	local build = Builders[id]
	if build then
		build(char)
	end
	if useAvatar then
  local keep={
   Warrior={ShieldRim=true,ShieldFace=true,EmblemV=true,EmblemH=true,ShieldBoss=true,Rivet=true},
   Mage={Prong=true},
   Tank={CrossV=true,CrossH=true,Rivet=true},
   Supporter={RingA=true,RingB=true},
   Gambler={Die=true,Pip=true},
   Duelist={CupHilt=true,GuardRing=true,Grip=true,Pommel=true},
  }
  local gear=char:FindFirstChild("ClassGear")
  if gear then
   for _,part in gear:GetDescendants() do
    if part:IsA("BasePart") then
     local name=part.Name
     local sword=part:FindFirstAncestor("Basic Sword")
     local weapon=part:GetAttribute("ClassWeapon")==true or sword~=nil or keep[id] and keep[id][name]
      or name:find("^Sword") or name:find("^Staff") or name:find("^Shield") or name:find("^Gun") or name:find("^Blade")
     if not weapon then part:Destroy() end
    end
   end
  end
 end
 char:SetAttribute("ClassModelVersion", 4)
end
return M
