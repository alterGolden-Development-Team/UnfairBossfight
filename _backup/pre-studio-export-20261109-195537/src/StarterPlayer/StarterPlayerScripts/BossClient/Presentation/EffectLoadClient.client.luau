--  * no effect part casts a shadow (moving shadow casters are the most expensive thing the renderer redraws)
--  * on Low/Medium effects quality (BossShared.Presentation.VisualQuality - Auto drops a tier below ~40 fps) the
--    effects' own lights are switched off; they come back on High
-- It only touches the effect folders, never the arena or the characters.
local Quality = require(game.ReplicatedStorage:WaitForChild("BossShared"):WaitForChild("Presentation"):WaitForChild("VisualQuality"))
local FOLDERS = { GoldenCombatEffects = true, AlterGoldenBladeEffects = true, FinalityVFX = true, VFXEngineLocal = true, GoldenSummons = true,
	SonicBlasterLocal = true }
local lights = setmetatable({}, { __mode = "k" })
local function inEffects(d)
	local top = d
	while top.Parent and top.Parent ~= workspace do top = top.Parent end
	return top.Parent == workspace and FOLDERS[top.Name] == true
end
local function apply(d)
	if d:IsA("BasePart") then
		if d.CastShadow and inEffects(d) then d.CastShadow = false end
	elseif d:IsA("Light") and inEffects(d) then
		if lights[d] == nil then lights[d] = d.Enabled end
		if not Quality.Get().Lights then d.Enabled = false end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do apply(d) end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") or d:IsA("Light") then task.defer(apply, d) end
end)
Quality.Changed:Connect(function(profile)
	for light, was in pairs(lights) do
		if light.Parent then light.Enabled = profile.Lights and was or false end
	end
end)
