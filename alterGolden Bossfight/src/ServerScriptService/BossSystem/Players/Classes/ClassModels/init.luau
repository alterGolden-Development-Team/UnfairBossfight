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
 M.Skin(char, id)
 char:SetAttribute("ClassModelVersion", 5)
end

-- Blender weapons (lobby/blender/weapons.py, MeshKit "Weapons"): each class's primitive weapon is hidden (its parts stay, so trails,
-- attachments and anything a kit looks up by name still work) and the mesh is welded on in the frame the class module built it in.
-- Gambler keeps its revolver: its hammer, trigger and cylinder are moving parts. Without the meshes nothing changes.
local GRIP = CFrame.new(0, -1.05, 0)
local SKINS = {
	Warrior = {
		{ anchor = "SwordHandle", mesh = "WpnWarriorSword", offset = CFrame.Angles(0, 0, -math.pi / 2), hide = { "^Sword" } },
		{ anchor = "ShieldRoot", mesh = "WpnWarriorShield", offset = CFrame.identity, hide = { "^Shield", "^Emblem", "^Rivet" } },
	},
	Tank = {
		{ limb = "Right Arm", mesh = "WpnTankSword", offset = CFrame.new(0.02, -0.8, 0) * CFrame.Angles(math.rad(62), 0, 0), hide = { "^Sword" } },
		{ limb = "Left Arm", mesh = "WpnTankShield", offset = CFrame.new(-0.85, -0.35, -0.3), hide = { "^Shield", "^Cross", "^Rivet" } },
	},
	Duelist = {
		{
			limb = "Right Arm",
			mesh = "WpnDuelist",
			offset = GRIP,
			hide = { "^Blade", "^CupHilt", "^CupRim", "^GuardRing", "^GuardBlock", "^Grip", "^Pommel", "^Quillon", "^HiltArm", "^TipGlint" },
		},
	},
	Mage = { { limb = "Right Arm", mesh = "WpnMage", offset = GRIP, hide = { "^Staff", "^Prong" } } },
	Supporter = { { limb = "Right Arm", mesh = "WpnSupporter", offset = GRIP, hide = { "^Staff", "^Ring" } } },
	TrueWarrior = { { limb = "Right Arm", mesh = "WpnTrueWarrior", offset = GRIP, hide = { "^Blade" } } },
	Twinblade = {
		{ anchor = "BladeRootR", mesh = "WpnTwinblade", offset = CFrame.identity, hide = { "^Blade" }, edge = Color3.fromRGB(255, 150, 60) },
		{ anchor = "BladeRootL", mesh = "WpnTwinblade", offset = CFrame.identity, hide = { "^Blade" }, edge = Color3.fromRGB(120, 190, 255) },
	},
}

function M.Skin(char, id)
	local skins = SKINS[id]
	local gear = char:FindFirstChild("ClassGear")
	if not skins or not gear then
		return
	end
	local ok, MeshKit = pcall(function()
		return require(game:GetService("ReplicatedStorage").BossShared.Presentation.MeshKit)
	end)
	if not ok or not MeshKit.Get(skins[1].mesh) then
		return
	end
	local anchors = {}
	for _, skin in skins do
		local anchor = skin.limb and char:FindFirstChild(skin.limb) or gear:FindFirstChild(skin.anchor, true)
		if anchor then
			anchors[anchor] = true
			for _, part in gear:GetDescendants() do
				if part:IsA("BasePart") then
					for _, pattern in skin.hide do
						if part.Name:find(pattern) and not part.Name:find("^BladeRoot") then
							part.Transparency = 1
							break
						end
					end
				end
			end
			local model = MeshKit.Attach(skin.mesh, anchor, skin.offset, gear)
			if model then
				model.Name = skin.mesh
				for _, p in model:GetDescendants() do
					if p:IsA("BasePart") then
						p:SetAttribute("ClassWeapon", true)
						p.CastShadow = false
						if skin.edge and p.Name == "EdgeGlow" then
							p.Color = skin.edge
						end
					end
				end
			end
		end
	end
end
return M
