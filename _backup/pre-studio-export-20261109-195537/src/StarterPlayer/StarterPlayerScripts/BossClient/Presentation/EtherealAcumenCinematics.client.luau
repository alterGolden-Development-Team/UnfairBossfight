local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
 
 
 
 
 
 
 
 
 
 
 
 
 
 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

 
local GRADE_ENABLED = true
local SHAKE_SCALE = 1  
local FLASH_SCALE = 1  
local LETTERBOX_HEIGHT = 0.075  

local remote = ReplicatedStorage:WaitForChild("BossCombatEffects")
local localPlayer = Players.LocalPlayer

 
local gui = Instance.new("ScreenGui")
gui.Name = "EtherealAcumenCinematics"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local function makeBar(anchorY)
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.AnchorPoint = Vector2.new(0, anchorY)
	frame.Position = UDim2.fromScale(0, anchorY)
	frame.Size = UDim2.fromScale(1, 0)
	frame.Parent = gui
	return frame
end
local topBar, bottomBar = makeBar(0), makeBar(1)
local flash = Instance.new("Frame")
flash.BorderSizePixel = 0
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.Parent = gui

local function letterbox(on)
	local size = UDim2.fromScale(1, on and LETTERBOX_HEIGHT or 0)
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Quad, on and Enum.EasingDirection.Out or Enum.EasingDirection.In)
	TweenService:Create(topBar, info, { Size = size }):Play()
	TweenService:Create(bottomBar, info, { Size = size }):Play()
end

local function doFlash(color, strength, duration)
	strength = math.clamp((strength or 0.8) * FLASH_SCALE, 0, 1)
	if strength <= 0 then
		return
	end
	flash.BackgroundColor3 = color or Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1 - strength
	TweenService:Create(
		flash,
		TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
end

 
local STATES = {
	Charge = {
		grade = { Brightness = -0.06, Contrast = 0.12, Saturation = -0.2, TintColor = Color3.fromRGB(255, 244, 214) },
		bloom = { Intensity = 0.7, Size = 28, Threshold = 0.9 },
	},
	Reveal = {
		grade = { Brightness = -0.14, Contrast = 0.22, Saturation = -0.4, TintColor = Color3.fromRGB(255, 232, 176) },
		bloom = { Intensity = 1.2, Size = 40, Threshold = 0.8 },
	},
	Finale = {
		grade = { Brightness = 0.3, Contrast = -0.1, Saturation = -0.55, TintColor = Color3.fromRGB(255, 250, 235) },
		bloom = { Intensity = 2.6, Size = 56, Threshold = 0.7 },
	},
	Rest = {
		grade = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) },
		bloom = { Intensity = 0, Size = 24, Threshold = 1 },
	},
}
local grade, bloom
local gradeGeneration = 0

local function ensureGrade()
	if grade and grade.Parent and bloom and bloom.Parent then
		return
	end
	if grade then
		grade:Destroy()
	end
	if bloom then
		bloom:Destroy()
	end
	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "EtherealAcumenGrade"
	grade.Parent = Lighting
	bloom = Instance.new("BloomEffect")
	bloom.Name = "EtherealAcumenBloom"
	bloom.Intensity = 0
	bloom.Size = 24
	bloom.Threshold = 1
	bloom.Parent = Lighting
end

local function tweenGrade(stateName, time, cleanup)
	if not GRADE_ENABLED then
		return
	end
	local state = STATES[stateName]
	if not state then
		return
	end
	ensureGrade()
	gradeGeneration += 1
	local generation = gradeGeneration
	local info = TweenInfo.new(math.max(time or 0.5, 0.01), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(grade, info, state.grade):Play()
	TweenService:Create(bloom, info, state.bloom):Play()
	if cleanup then
		task.delay(info.Time + 0.1, function()
			if generation ~= gradeGeneration then
				return
			end
			if grade then
				grade:Destroy()
				grade = nil
			end
			if bloom then
				bloom:Destroy()
				bloom = nil
			end
		end)
	end
end

 
 
 
local shakes, punches = {}, {}
local applied = false
local lastOffset, lastFov = CFrame.identity, 0
local seed = math.random() * 100

local function envelope(effect, now)
	local t = (now - effect.Start) / effect.Duration
	if t >= 1 then
		return nil
	end
	if effect.Ramp then
		local e = t * t
		if t > 0.94 then
			e *= (1 - t) / 0.06
		end
		return e
	end
	return math.min(t * 20, 1) * (1 - t) ^ 2
end

local function falloff(effect, cameraPosition)
	if not effect.Origin then
		return 1
	end
	return 1 - math.clamp((cameraPosition - effect.Origin).Magnitude / (effect.Radius or 400), 0, 1) * 0.75
end

RunService:BindToRenderStep("EtherealCinematicsUndo", Enum.RenderPriority.Camera.Value - 1, function()
	if not applied then
		return
	end
	applied = false
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CFrame = camera.CFrame * lastOffset:Inverse()
	Fov.Clear(script)
end)

RunService:BindToRenderStep("EtherealCinematicsApply", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if #shakes == 0 and #punches == 0 then
		return
	end
	local now = os.clock()
	local amplitude, fov = 0, 0
	for index = #shakes, 1, -1 do
		local shake = shakes[index]
		local e = envelope(shake, now)
		if e then
			amplitude += shake.Intensity * e * falloff(shake, camera.CFrame.Position)
		else
			table.remove(shakes, index)
		end
	end
	for index = #punches, 1, -1 do
		local punch = punches[index]
		local e = envelope(punch, now)
		if e then
			fov += punch.Amount * e
		else
			table.remove(punches, index)
		end
	end
	amplitude = math.min(amplitude, 2.5) * SHAKE_SCALE
	fov *= SHAKE_SCALE
	if amplitude <= 0 and fov == 0 then
		return
	end
	local nx = math.noise(now * 23, seed, 0) * 2
	local ny = math.noise(seed, now * 21, 3.1) * 2
	local nz = math.noise(now * 17, seed, 7.7) * 2
	local offset = CFrame.new(nx * amplitude * 0.9, ny * amplitude * 0.9, 0)
		* CFrame.Angles(ny * amplitude * 0.02, nx * amplitude * 0.02, nz * amplitude * 0.03)
	camera.CFrame = camera.CFrame * offset
	Fov.Set(script,fov)
	lastOffset = offset
	lastFov = fov
	applied = true
end)

 
local activeToken

local function resetAll(time)
	activeToken = nil
	table.clear(shakes)
	table.clear(punches)
	letterbox(false)
	tweenGrade("Rest", time or 0.5, true)
end

require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset).Register(script,function()resetAll(0)end)
remote.OnClientEvent:Connect(function(eventName, data)
	if eventName ~= "EtherealFX" or type(data) ~= "table" then
		return
	end
	local kind = data.Kind
	if kind == "Reset" then
		if data.Token == activeToken then
			resetAll(data.Time)
		end
		return
	end
	activeToken = data.Token
	if kind == "Grade" then
		tweenGrade(data.State, data.Time, false)
		 
		local watched = data.Token
		task.delay(45, function()
			if activeToken == watched then
				resetAll(0.5)
			end
		end)
	elseif kind == "Letterbox" then
		letterbox(false) -- boss battle: no letterbox bars; grade and shake still play
	elseif kind == "Shake" then
		table.insert(shakes, {
			Intensity = data.Intensity or 0.5,
			Duration = math.max(data.Duration or 0.4, 0.05),
			Start = os.clock(),
			Origin = data.Origin,
			Radius = data.Radius,
			Ramp = data.Ramp,
		})
	elseif kind == "Punch" then
		table.insert(
			punches,
			{
				Amount = data.Amount or 0,
				Duration = math.max(data.Duration or 0.3, 0.05),
				Start = os.clock(),
				Ramp = data.Ramp,
			}
		)
	elseif kind == "Flash" then
		doFlash(data.Color, data.Strength, data.Duration)
	end
end)
