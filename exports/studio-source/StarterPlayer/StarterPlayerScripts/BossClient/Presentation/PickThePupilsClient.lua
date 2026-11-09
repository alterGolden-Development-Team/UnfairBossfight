local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")
local active, savedCamera, cameraGoal, cameraFov, deadline, voteCount, pupilId
local gui = Instance.new("ScreenGui")
gui.Name = "PickThePupilsHUD"
gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.Enabled = true, false, 125, false
gui.Parent = player:WaitForChild("PlayerGui")
local function text(name, y, size, color)
	local t = Instance.new("TextLabel")
	t.Name, t.AnchorPoint, t.Position = name, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, y)
	t.Size = UDim2.new(0.94, 0, 0, size + 18)
	t.BackgroundTransparency, t.TextColor3, t.TextStrokeTransparency = 1, color, 0.25
	t.Font, t.TextSize, t.TextWrapped = Enum.Font.GothamBold, size, true
	t.Parent = gui
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = size
	constraint.MinTextSize = 12
	constraint.Parent = t
	t.TextScaled = true
	return t
end
local bars = {}
for _, y in ipairs({ 0, 1 }) do
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, y)
	bar.Position = UDim2.fromScale(0, y)
	bar.Size = UDim2.fromScale(1, 0.085)
	bar.BackgroundColor3 = Color3.fromRGB(9, 7, 18)
	bar.BorderSizePixel = 0
	bar.Parent = gui
	table.insert(bars, bar)
end
local gold, white = Color3.fromRGB(255, 216, 95), Color3.fromRGB(255, 248, 226)
local subtitle = text("Instructions", 0.865, 18, white)
local footer = text("Timer", 0.952, 19, white)
local flash = Instance.new("Frame")
flash.Name = "RevealFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = white
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 0
flash.Parent = gui
local bloom
local function releaseCamera()
	cameraGoal = nil
	if savedCamera then
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraType=savedCamera.Type==Enum.CameraType.Scriptable and Enum.CameraType.Custom or savedCamera.Type
			camera.FieldOfView = savedCamera.Fov
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			camera.CameraSubject = h or savedCamera.Subject
			camera.CFrame = savedCamera.Frame
		end
		savedCamera = nil
	end
end
local function holdCamera(cf, fov)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if not savedCamera then
		savedCamera = {
			Type = camera.CameraType,
			Frame = camera.CFrame,
			Subject = camera.CameraSubject,
			Fov = Fov.Base(camera),
		}
	end
	cameraGoal, cameraFov = cf, fov or 58
	camera.CameraType = Enum.CameraType.Scriptable
end
local function wide(frame, count)
	local camera = workspace.CurrentCamera
	local aspect = camera and camera.ViewportSize.X / math.max(camera.ViewportSize.Y, 1) or 1.7
	local distance = math.max(84, ((count or 5) * 25 + 18) / (2 * math.tan(math.rad(30)) * aspect))
	return CFrame.lookAt(
		frame:PointToWorldSpace(Vector3.new(0, distance * 0.42, distance)),
		frame:PointToWorldSpace(Vector3.new(0, 7, -3))
	)
end
local function reset()
	active, deadline = nil, nil
	gui.Enabled = false
	flash.BackgroundTransparency = 1
	releaseCamera()
	if bloom then
		bloom:Destroy()
		bloom = nil
	end
end
Run:BindToRenderStep("PickThePupilsCamera", Enum.RenderPriority.Camera.Value + 5, function(dt)
	local camera = workspace.CurrentCamera
	if cameraGoal and camera then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = camera.CFrame:Lerp(cameraGoal, 1 - math.exp(-dt * 7))
		camera.FieldOfView += (cameraFov - camera.FieldOfView) * (1 - math.exp(-dt * 7))
	end
	if deadline then
		local seconds = math.max(0, math.ceil(deadline - workspace:GetServerTimeNow()))
		footer.Text = pupilId == player.UserId and (seconds .. "s  •  Your classmates are choosing")
			or (seconds .. "s  •  Stand on pad 1–" .. voteCount .. "  •  Most votes wins; ties or no votes fail")
	end
end)
remote.OnClientEvent:Connect(function(event, data)
	if event ~= "PickThePupilsFX" or type(data) ~= "table" then
		return
	end
	if data.Kind == "End" then
		if active and active.Token == data.Token then
			reset()
		end
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		reset()
		return
	end
	if not active or active.Token ~= data.Token then
		reset()
		active = { Token = data.Token, Owner = data.Owner, Started = os.clock(), Character = character }
		bloom = Instance.new("BloomEffect")
		bloom.Name = "PickThePupilsBloom"
		bloom.Intensity = 0.45
		bloom.Size = 24
		bloom.Threshold = 1
		bloom.Parent = Lighting
	end
	gui.Enabled = true
	active.LastEvent = os.clock()
	pupilId = data.PupilUserId
	local kind = data.Kind
	 
	if kind == "Entrance" or kind == "Remember" or kind == "Shuffle" or kind == "Pick"
		or kind == "Suspense" or kind == "Reveal" or kind == "Result" or kind == "Replacement" or kind == "Escape" then
		deadline = nil
		footer.Text = ""
	end
	if kind == "Entrance" then
		subtitle.Text = ""
		holdCamera(wide(data.Frame, 5), 60)
	elseif kind == "Remember" then
		active.Count = data.Count
		subtitle.Text = "Remember the cup hiding " .. data.PupilName .. "."
		holdCamera(wide(data.Frame, data.Count), 60)
	elseif kind == "Shuffle" then
		local instructions = {
			Illusion = "Violet swaps move only shells. Remember where the pupil began.",
			DoubleCross = "Two pairs move together. Follow the pupil's cup.",
			FalseMemory = "Gold swaps are real. Violet swaps leave the pupil in place.",
			Carousel = "Every third move rotates all five cups.",
		}
		subtitle.Text = instructions[data.Mode] or "Follow the pupil's cup."
		holdCamera(wide(data.Frame, data.Count), 60)
	elseif kind == "Pick" then
		subtitle.Text = pupilId == player.UserId and "Your classmates must choose your cup."
			or "Stand on a numbered golden pad to choose."
		deadline, voteCount = data.EndsAt, data.Count
		if pupilId ~= player.UserId then
			releaseCamera()
		else
			holdCamera(wide(data.Frame, data.Count), 60)
		end
	elseif kind == "Suspense" then
		subtitle.Text = data.Choice and ("Cup " .. data.Choice .. "...") or "No cup chosen."
		footer.Text = "VOTES LOCKED"
		local at = data.Position
		holdCamera(CFrame.lookAt(at + data.Frame:VectorToWorldSpace(Vector3.new(18, 16, 32)),
			at + Vector3.new(0, 7, 0)), 50)
	elseif kind == "Reveal" then
		subtitle.Text = ""
		flash.BackgroundTransparency = 0.72
		TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	elseif kind == "Result" then
		subtitle.Text = data.Correct and "" or ("The pupil was in cup " .. data.CorrectSlot .. ".")
		holdCamera(wide(data.Frame, active.Count), 60)
	elseif kind == "Replacement" then
		subtitle.Text = data.PupilName .. " takes their place."
	elseif kind == "Escape" then
		subtitle.Text = ""
		holdCamera(wide(data.Frame, active.Count), 60)
	end
end)
Run.Heartbeat:Connect(function()
	if
		active
		and (
			os.clock() - active.Started > 310
			or player.Character ~= active.Character
			or not active.Character:FindFirstChildOfClass("Humanoid")
			or active.Character.Humanoid.Health <= 0
			or not active.Owner
			or not active.Owner.Parent
			or active.Owner:GetAttribute("PickThePupilsActive") == false
			or active.Owner:GetAttribute("EncounterEnded")
			or math.floor(active.Owner:GetAttribute("Phase") or 1) ~= 3
		)
	then
		reset()
	end
end)
player.CharacterAdded:Connect(reset)
player.CharacterRemoving:Connect(reset)
require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset).Register(script,reset)
script.Destroying:Connect(function()
	Run:UnbindFromRenderStep("PickThePupilsCamera")
	reset()
	gui:Destroy()
end)
