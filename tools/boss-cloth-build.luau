-- Run in the boss Studio window (Edit mode, never in a playtest) after MeshKit.Fetch("BossCloth"). Dresses the boss template in alterGolden's
-- Blender clothes (lobby/blender/boss_cloth.py): every piece is cloned from ReplicatedStorage.BlenderMeshes, centred on its R15 body part,
-- welded to it (massless, no collision) and kept in the template's BlenderLook.Clothing folder. The flat Shirt and Pants textures move to
-- ServerStorage.BossEncounter.Archive.OldBossLook (nothing is deleted) and the body parts under the clothes turn near-black so no skin
-- shows at a seam. Safe to run again: it replaces its own Clothing folder.
local kit = game.ReplicatedStorage.BlenderMeshes
local template = game.ServerStorage.BossEncounter.Templates:GetChildren()[1]
local archive = game.ServerStorage.BossEncounter.Archive:FindFirstChild("OldBossLook")
local look = template:FindFirstChild("BlenderLook")
assert(look, "the boss template has no BlenderLook folder")

local old = look:FindFirstChild("Clothing")
if old then
	old:Destroy()
end
local clothing = Instance.new("Folder")
clothing.Name = "Clothing"
clothing.Parent = look

local DRESS = {
	{ "UpperTorso", "BossTunic", "BossTunic" },
	{ "LowerTorso", "BossSkirt", "BossSkirt" },
	{ "LeftUpperArm", "BossSleeveUp", "BossSleeveUpL" },
	{ "RightUpperArm", "BossSleeveUp", "BossSleeveUpR" },
	{ "LeftLowerArm", "BossSleeveLow", "BossSleeveLowL" },
	{ "RightLowerArm", "BossSleeveLow", "BossSleeveLowR" },
	{ "LeftUpperLeg", "BossTrouserUp", "BossTrouserUpL" },
	{ "RightUpperLeg", "BossTrouserUp", "BossTrouserUpR" },
	{ "LeftLowerLeg", "BossTrouserLow", "BossTrouserLowL" },
	{ "RightLowerLeg", "BossTrouserLow", "BossTrouserLowR" },
	{ "LeftFoot", "BossBoot", "BossBootL" },
	{ "RightFoot", "BossBoot", "BossBootR" },
}
local report = {}
for _, row in DRESS do
	local partName, piece, name = row[1], row[2], row[3]
	local body = template:FindFirstChild(partName)
	local source = kit:FindFirstChild(piece)
	if body and source then
		local model = source:Clone()
		model.Name = name
		model:PivotTo(body.CFrame)
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, false, true, true
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = body, p
				weld.Parent = p
			end
		end
		model.Parent = clothing
	else
		table.insert(report, "missing " .. partName .. " / " .. piece)
	end
end

for _, name in { "Shirt", "Pants" } do
	local item = template:FindFirstChild(name)
	if item then
		item.Parent = archive or game.ServerStorage.BossEncounter.Archive
	end
end
local under = Color3.fromRGB(22, 20, 27)
for _, partName in { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot" } do
	local body = template:FindFirstChild(partName)
	if body then
		if body:GetAttribute("OldColor") == nil then
			body:SetAttribute("OldColor", body.Color)
			body:SetAttribute("OldMaterial", body.Material.Name)
		end
		body.Color = under
		body.Material = Enum.Material.Fabric
	end
end
table.insert(report, "dressed " .. #clothing:GetChildren() .. " pieces")
return table.concat(report, "\n")
