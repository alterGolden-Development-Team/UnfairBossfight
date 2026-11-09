local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local Capture = game:GetService("CaptureService")
local Run = game:GetService("RunService")
local BINDING = "GoldenHourFrozenView"
local HIDDEN_PARTICLES = NumberSequence.new(1)
local api = {}

function api.new(player)
	local view = {}
	local active
	local pendingCharacter
	local destroyed = false
	local gui = Instance.new("ScreenGui")
	gui.Name = "GoldenHourFrozenView"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 79
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local still = Instance.new("ImageLabel")
	still.Name = "FrozenFrame"
	still.Size = UDim2.fromScale(1, 1)
	still.BackgroundColor3 = Color3.fromRGB(24, 23, 18)
	still.BackgroundTransparency = 1
	still.BorderSizePixel = 0
	still.ScaleType = Enum.ScaleType.Stretch
	still.Parent = gui

	local function releaseMask(record)
		for _, connection in ipairs(record.Connections) do connection:Disconnect() end
		table.clear(record.Connections)
		for item, state in pairs(record.Hidden) do
			pcall(function() item[state.Property] = state.Value end)
		end
		table.clear(record.Hidden)
	end

	function view.Stop()
		pendingCharacter = nil
		local record = active
		if not record then return end
		active = nil
		Run:UnbindFromRenderStep(BINDING)
		releaseMask(record)
		gui.Enabled = false
		gui:SetAttribute("FrameReady", false)
		still.ImageContent = Content.none
		local camera = record.Camera
		if camera.Parent and camera.CameraType == Enum.CameraType.Scriptable then
			camera.CameraType = record.Type
			if record.Subject and record.Subject.Parent then camera.CameraSubject = record.Subject end
			camera.CFrame = record.Frame
			camera.Focus = record.Focus
			camera.FieldOfView = record.FieldOfView
		end
	end

	function view.Start()
		if active or destroyed or workspace:GetAttribute("GoldenTimeStopped") ~= true then return end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if character and not humanoid then
			if pendingCharacter == character then return end
			pendingCharacter = character
			task.spawn(function()
				local ready = character:WaitForChild("Humanoid", 10)
				if pendingCharacter ~= character then return end
				pendingCharacter = nil
				if ready and player.Character == character then view.Start() end
			end)
			return
		end
		local camera = workspace.CurrentCamera
		if not camera or not humanoid or humanoid.Health <= 0 then return end
		local record = {
			Character = character, Humanoid = humanoid, Camera = camera,
			Type = camera.CameraType, Subject = camera.CameraSubject,
			Frame = camera.CFrame, Focus = camera.Focus, FieldOfView = Fov.Base(camera),
			Hidden = {}, Connections = {}, Containers = {}, Captured = false,
		}
		active = record
		gui.Enabled = false
		gui:SetAttribute("FrameReady", false)
		camera.CameraType = Enum.CameraType.Scriptable

		 
		 
		local function conceal(item)
			if active ~= record or record.Captured or record.Hidden[item] then return end
			local ancestor = item
			while ancestor and ancestor ~= workspace do
				if ancestor:GetAttribute("TimeStopExempt") == true then return end
				ancestor = ancestor.Parent
			end
			local property, hidden
			if item:IsA("BasePart") then
				property, hidden = "LocalTransparencyModifier", 1
			elseif item:IsA("ParticleEmitter") then
				property, hidden = "Transparency", HIDDEN_PARTICLES
			elseif item:IsA("Beam") or item:IsA("Trail") or item:IsA("Light")
				or item:IsA("Highlight") or item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
				property, hidden = "Enabled", false
			else
				return
			end
			local state = { Property = property, Value = item[property], Writing = false }
			record.Hidden[item] = state
			local function hide()
				state.Writing = true
				item[property] = hidden
				state.Writing = false
			end
			table.insert(record.Connections, item:GetPropertyChangedSignal(property):Connect(function()
				if state.Writing or active ~= record or record.Captured then return end
				if item[property] ~= hidden then state.Value = item[property]; hide() end
			end))
			hide()
		end
		local function watch(container)
			if record.Containers[container] or (container.Name ~= "GoldenCombatEffects" and container.Name ~= "GoldenSummons") then return end
			record.Containers[container] = true
			table.insert(record.Connections, container.DescendantAdded:Connect(conceal))
			for _, item in ipairs(container:GetDescendants()) do conceal(item) end
		end
		table.insert(record.Connections, workspace.ChildAdded:Connect(watch))
		for _, name in ipairs({ "GoldenCombatEffects", "GoldenSummons" }) do
			local container = workspace:FindFirstChild(name)
			if container then watch(container) end
		end
		Run:BindToRenderStep(BINDING, Enum.RenderPriority.Last.Value, function()
			if active ~= record then return end
			if workspace:GetAttribute("GoldenTimeStopped") ~= true
				or player.Character ~= character or humanoid.Health <= 0
				or workspace.CurrentCamera ~= camera then
				view.Stop()
				if workspace.CurrentCamera ~= camera and workspace:GetAttribute("GoldenTimeStopped") == true then
					task.defer(view.Start)
				end
				return
			end
			camera.CFrame = record.Frame
			camera.Focus = record.Focus
			camera.FieldOfView = record.FieldOfView
		end)

		 
		task.spawn(function()
			if active ~= record then return end
			local ok = pcall(function()
				Capture:TakeScreenshotCaptureAsync(function(result, snapshot)
					if active ~= record or result ~= Enum.ScreenshotCaptureResult.Success or not snapshot then return end
					still.ImageContent = Content.fromObject(snapshot)
					 
					local deadline = os.clock() + 2
					while active == record and not still.IsLoaded and os.clock() < deadline do Run.RenderStepped:Wait() end
					if active ~= record or not still.IsLoaded then return end
					gui.Enabled = true
					record.Captured = true
					releaseMask(record)
					gui:SetAttribute("FrameReady", true)
				end, { UICaptureMode = Enum.UICaptureMode.None })
			end)
			if not ok and active == record then gui:SetAttribute("FrameReady", false) end
		end)
	end

	function view.Destroy()
		destroyed = true
		view.Stop()
		gui:Destroy()
	end
	return view
end

return api