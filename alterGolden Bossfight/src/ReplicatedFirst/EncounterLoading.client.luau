local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Content = game:GetService("ContentProvider")
local Run = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "EncounterLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = player:WaitForChild("PlayerGui")
local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
backdrop.BorderSizePixel = 0
backdrop.Parent = gui
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(35, 31, 20), Color3.fromRGB(9, 11, 16))
gradient.Rotation = 70
gradient.Parent = backdrop
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.84, 0, 0, 290)
panel.BackgroundTransparency = 1
panel.Parent = backdrop
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(580, 290)
limit.Parent = panel
local gold = Color3.fromRGB(246, 211, 117)
local function label(name, text, y, height, size, color)
	local item = Instance.new("TextLabel")
	item.Name, item.Text = name, text
	item.Position = UDim2.fromOffset(0, y)
	item.Size = UDim2.new(1, 0, 0, height)
	item.BackgroundTransparency = 1
	item.TextColor3, item.TextSize = color, size
	item.Font = Enum.Font.Garamond
	item.TextWrapped = true
	item.Parent = panel
	return item
end
label("Eyebrow", "THE GOLDEN ENCOUNTER", 0, 30, 18, gold)
local title = label("Title", "alterGolden", 38, 68, 58, Color3.fromRGB(246, 243, 231))
title.TextScaled = true
local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MaxTextSize, titleLimit.MinTextSize = 58, 30
titleLimit.Parent = title
label("Subtitle", "Every attempt is another chance.", 112, 34, 23, Color3.fromRGB(184, 182, 169))
local track = Instance.new("Frame")
track.Name = "ProgressTrack"
track.Position = UDim2.new(0.08, 0, 0, 178)
track.Size = UDim2.new(0.84, 0, 0, 3)
track.BackgroundColor3 = Color3.fromRGB(64, 61, 48)
track.BorderSizePixel = 0
track.Parent = panel
local fill = Instance.new("Frame")
fill.Name = "Progress"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = gold
fill.BorderSizePixel = 0
fill.Parent = track
local status = label("Status", "Entering the arena...", 196, 40, 20, Color3.fromRGB(220, 218, 206))
local skip = Instance.new("TextButton")
skip.Name = "SkipAssets"
skip.AnchorPoint = Vector2.new(0.5, 0)
skip.Position = UDim2.new(0.5, 0, 0, 248)
skip.Size = UDim2.fromOffset(230, 40)
skip.BackgroundTransparency = 1
skip.TextColor3 = gold
skip.Text = "Continue while assets load"
skip.Font = Enum.Font.Gotham
skip.TextSize = 14
skip.Visible = false
skip.Modal = true
skip.Parent = panel
CAS:BindActionAtPriority("EncounterLoading", function() return Enum.ContextActionResult.Sink end,
	false, 10000, table.unpack(Enum.PlayerActions:GetEnumItems()))
ReplicatedFirst:RemoveDefaultLoadingScreen()

local skipped, assetsDone, closed = false, false, false
local streamingDone = false
local completed, total, failures = 0, 0, 0
local shownProgress = 0
local loadingStarted = os.clock()
skip.Activated:Connect(function() skipped = true end)

local function characterReady()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
		and char:FindFirstChildOfClass("Humanoid") and char:GetAttribute("R6AppearanceFinished") == true
end
local function essentialReady()
	return game:IsLoaded() and workspace:GetAttribute("BossStartupReady") == true
		and streamingDone
		and characterReady() and player:GetAttribute("EncounterHUDReady") == true
		and player:GetAttribute("EncounterVitalsReady") == true
end
local function close()
	if closed then return end
	closed = true
	CAS:UnbindAction("EncounterLoading")
	gui:Destroy()
end

task.spawn(function()
	if not game:IsLoaded() then game.Loaded:Wait() end
	if not workspace.StreamingEnabled then streamingDone = true; return end
	local position = workspace:GetAttribute("EncounterPreloadPosition")
	while typeof(position) ~= "Vector3" and not closed do
		task.wait(0.1)
		position = workspace:GetAttribute("EncounterPreloadPosition")
	end
	if closed then return end
	local ok = pcall(player.RequestStreamAroundAsync, player, position, 8)
	player:SetAttribute("EncounterStreamRequestSucceeded", ok)
	streamingDone = true
end)

task.spawn(function()
	if not game:IsLoaded() then game.Loaded:Wait() end
	local shared = Replicated:WaitForChild("BossShared")
	local assets, seen = {}, {}
	local function add(asset, kind)
		if type(asset) ~= "string" or asset == "" then return end
		local id = asset:match("[?&]id=(%d+)")
		if id then asset = "rbxassetid://" .. id end
		local key = kind .. ":" .. asset
		if not seen[key] then
			seen[key] = true
			table.insert(assets, { Id = asset, Kind = kind })
		end
	end
	for _, module in ipairs(shared:WaitForChild("Config"):GetChildren()) do
		if module:IsA("ModuleScript") then
			local ok, config = pcall(require, module)
			if ok and module.Name == "CombatAudioConfig" then
				for _, asset in pairs(config.UploadedCues) do add(asset, "Sound") end
				local function visit(value)
					if type(value) == "table" then
						for _, child in pairs(value) do visit(child) end
					elseif type(value) == "string" and value:match("^rbxasset") then add(value, "Sound") end
				end
				visit(config)
			end
		end
	end
	for _, asset in ipairs(require(shared:WaitForChild("StartupAssets"))) do add(asset.Id, asset.Kind) end
	 -- every attack's textures: the VFX library, plus everything shipped in ReplicatedStorage and the arena
	local vfx = Replicated:WaitForChild("VFXEngine")
	for _, id in ipairs(require(vfx:WaitForChild("Library")).All()) do add(id, "Image") end
	for _, container in ipairs({ player:WaitForChild("PlayerGui"), Replicated, workspace, player.Character }) do  -- Character last: it may be nil
		if container then
			for _, item in ipairs(container:GetDescendants()) do
				if item:IsA("Animation") then add(item.AnimationId, "Animation")
				elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then add(item.Image, "Image")
				elseif item:IsA("MeshPart") then add(item.MeshId, "Mesh"); add(item.TextureID, "Image")
				elseif item:IsA("SpecialMesh") then add(item.MeshId, "Mesh"); add(item.TextureId, "Image")
				elseif item:IsA("Decal") then add(item.Texture, "Image")
				elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") then add(item.Texture, "Image")
				elseif item:IsA("Sound") then add(item.SoundId, "Sound")
				elseif item:IsA("Sky") then
					for _, face in ipairs({ "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }) do add(item[face], "Image") end
				end
			end
		end
	end
	total = #assets
	local nextIndex, workers = 1, math.min(6, total)
	if workers == 0 then assetsDone = true; return end
	for _ = 1, workers do
		task.spawn(function()
			while nextIndex <= total do
				local index = nextIndex
				nextIndex += 1
				local asset = assets[index]
				local class = ({ Sound = "Sound", Animation = "Animation", Image = "Decal", Mesh = "SpecialMesh" })[asset.Kind]
				local property = ({ Sound = "SoundId", Animation = "AnimationId", Image = "Texture", Mesh = "MeshId" })[asset.Kind]
				local reference = Instance.new(class)
				reference[property] = asset.Id
				local ok = pcall(Content.PreloadAsync, Content, { reference }, function(_, result)
					if result ~= Enum.AssetFetchStatus.Success then failures += 1 end
				end)
				reference:Destroy()
				if not ok then failures += 1 end
				completed += 1
			end
			workers -= 1
			if workers == 0 then assetsDone = true end
		end)
	end
end)

local connection
connection = Run.Heartbeat:Connect(function(dt)
	local elapsed = os.clock() - loadingStarted
	local serverProgress = workspace:GetAttribute("BossStartupProgress") or 0
	local ready = essentialReady()
	 -- the attacks are worth the wait: up to a minute before giving up on slow assets
	local optionalFinished = assetsDone or skipped or elapsed >= 60
	local progress = (game:IsLoaded() and 0.15 or 0.03) + serverProgress * 0.3
		+ (characterReady() and 0.15 or 0) + (total > 0 and completed / total * 0.3 or 0)
		+ (streamingDone and 0.1 or 0)
	if ready and optionalFinished then progress = 1 end
	shownProgress = math.max(shownProgress, math.min(progress, shownProgress + dt * 1.5))
	fill.Size = UDim2.fromScale(shownProgress, 1)
	skip.Visible = ready and not optionalFinished and elapsed >= 25
	if workspace:GetAttribute("BossStartupError") then
		status.Text = "Combat setup could not finish. Please rejoin."
	elseif not game:IsLoaded() then status.Text = "Loading the arena..."
	elseif workspace:GetAttribute("BossStartupReady") ~= true then status.Text = "Preparing the encounter..."
	elseif not streamingDone then status.Text = "Loading the arena..."
	elseif not ready then status.Text = "Preparing your character..."
	elseif not optionalFinished then status.Text = string.format("Loading the boss's attacks · %d / %d", completed, total)
	else status.Text = "Ready" end
	if ready and optionalFinished and shownProgress >= 1 then
		connection:Disconnect()
		Replicated:WaitForChild("EncounterLifecycle"):FireServer("Ready")
		player:SetAttribute("EncounterLoadingComplete", true)
		player:SetAttribute("EncounterAssetFailures", failures)
		task.delay(0.2, close)
	end
end)
script.Destroying:Connect(function()
	if connection then connection:Disconnect() end
	close()
end)