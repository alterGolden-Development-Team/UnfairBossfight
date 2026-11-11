local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "BossEntranceColor"
cc.Parent = Lighting

local trauma, floorTrauma = 0, 0
local seed = math.random() * 100

local function tween(inst, time, props, style, direction)
	TweenService
		:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
		:Play()
end
local function settle(time)
	floorTrauma = 0
	tween(cc, time, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) })
end

RunService:BindToRenderStep("BossEntranceShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	trauma = math.max(floorTrauma, trauma - dt * 1.4)
	if trauma <= 0.001 then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local power = trauma * trauma * 0.05
	local t = os.clock() * 28
	camera.CFrame = camera.CFrame
		* CFrame.Angles(
			math.noise(t, seed) * 2 * power,
			math.noise(t, seed + 10) * 2 * power,
			math.noise(t, seed + 20) * power
		)
end)

remote.OnClientEvent:Connect(function(kind, data)
	if type(data) ~= "table" then
		data = {}
	end
	if kind == "EntranceBuildUp" then
		local p = data.Progress or 0
		floorTrauma = 0.08 + p * 0.22
		tween(cc, 1, { Brightness = -0.06 * p, Contrast = 0.12 * p, Saturation = -0.15 * p })
	elseif kind == "ArrivalImpact" then
		local camera = workspace.CurrentCamera
		local intensity = 1
		if camera and data.Position then
			intensity = math.clamp(1 - (camera.CFrame.Position - data.Position).Magnitude / 200, 0.4, 1)
		end
		floorTrauma = 0
		trauma = math.max(trauma, intensity)
		cc.Brightness = 0.55 * intensity
		cc.Contrast = 0.3 * intensity
		cc.Saturation = 0.2
		cc.TintColor = Color3.fromRGB(255, 240, 190)
		tween(cc, 0.9, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) })
		if camera then
			local base = Fov.Base(camera)
			camera.FieldOfView = base + 10 * intensity
			tween(camera, 0.7, { FieldOfView = base })
		end
	end
end)

workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
	if workspace:GetAttribute("EncounterStarted") ~= true then
		settle(0.4)
	end
end)
