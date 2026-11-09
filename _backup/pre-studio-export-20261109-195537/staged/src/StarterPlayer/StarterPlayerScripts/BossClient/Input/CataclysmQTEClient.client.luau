 
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local event
local active
local function submitKey(key)
 if active then event:FireServer(active.Id,key) end
end
event = game:GetService("ReplicatedStorage"):WaitForChild("BossEncounterRemotes"):WaitForChild("CataclysmQTE")
local gui=Instance.new("ScreenGui")
gui.Name="ChainBreakHUD"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.DisplayOrder=150
gui.Parent=player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "CataclysmQTE"
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.42)
frame.Size = UDim2.new(0.84,0,0,160)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 10)
frame.BackgroundTransparency = 0.18
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(0, 130)
constraint.MaxSize = Vector2.new(560, 160)
constraint.Parent = frame
local border = Instance.new("UIStroke")
border.Color = Color3.fromRGB(255, 213, 40)
border.Thickness = 2
border.Parent = frame

local function label(name, position, size, text, color)
	local isKey=name:match("^Key")~=nil
	local t = Instance.new(isKey and "TextButton" or "TextLabel")
	if isKey then
		t.AutoButtonColor=true
		t.Activated:Connect(function()submitKey(t.Text)end)
	end
	t.Name = name
	t.Position = position
	t.Size = size
	t.BackgroundTransparency = 1
	t.Text = text
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
 local textLimit=Instance.new("UITextSizeConstraint")
 textLimit.MaxTextSize=name:find("^Key") and 44 or name=="Title" and 24 or 19
 textLimit.Parent=t
	t.TextColor3 = color or Color3.fromRGB(255, 230, 110)
	t.Parent = frame
	return t
end
label("Title", UDim2.fromScale(0.04, 0.05), UDim2.fromScale(0.92, 0.18), "BREAK THE CHAINS")
 
local letters, arrows = {}, {}
local function buildLetters(count)
	for _, item in ipairs(letters) do
		item:Destroy()
	end
	for _, item in ipairs(arrows) do
		item:Destroy()
	end
	table.clear(letters)
	table.clear(arrows)
	count = math.max(1, count)
 local arrowWidth=0.035
 local rowWidth=0.84
 local width=(rowWidth-arrowWidth*(count-1))/count
 for index=1,count do
  local x=0.08+(index-1)*(width+arrowWidth)
  letters[index]=label("Key"..index,UDim2.fromScale(x,0.31),UDim2.fromScale(width,0.36),"W")
  if index<count then
   arrows[index]=label("Arrow"..index,UDim2.fromScale(x+width,0.37),UDim2.fromScale(arrowWidth,0.22),"→",Color3.fromRGB(175,167,121))
  end
 end
end
buildLetters(4)
local window = 3.5
local timer = label("Countdown", UDim2.fromScale(0.04, 0.76), UDim2.fromScale(0.92, 0.14), "3.5s")
local track = Instance.new("Frame")
track.Name = "TimerTrack"
track.BackgroundColor3 = Color3.fromRGB(62, 57, 33)
track.BorderSizePixel = 0
track.Position = UDim2.fromScale(0.04, 0.94)
track.Size = UDim2.fromScale(0.92, 0.035)
track.Parent = frame
local fill = Instance.new("Frame")
fill.Name = "TimerFill"
fill.BackgroundColor3 = Color3.fromRGB(255, 220, 40)
fill.BorderSizePixel = 0
fill.Size = UDim2.fromScale(1, 1)
fill.Parent = track

local rendering
local actionName = "CataclysmSequenceInput"
local keyCodes = {}
for _, code in ipairs(Enum.KeyCode:GetEnumItems()) do
	if #code.Name == 1 and code.Name:match("^[A-Z]$") then
		table.insert(keyCodes, code)
	end
end
table.insert(keyCodes, Enum.KeyCode.Space)
local function close()
 player:SetAttribute("ChainBreakActive",false)
	active = nil
	frame.Visible = false
	ContextActionService:UnbindAction(actionName)
	if rendering then
		rendering:Disconnect()
		rendering = nil
	end
end
local function input(_, state, object)
	if not active then
		return Enum.ContextActionResult.Pass
	end
	if state == Enum.UserInputState.Begin then
		event:FireServer(active.Id, object.KeyCode.Name == "Space" and " " or object.KeyCode.Name)
	end
	return Enum.ContextActionResult.Sink
end
event.OnClientEvent:Connect(function(action, data)
	if action == "Show" then
		close()
		active = data
  active.Deadline=active.Deadline or workspace:GetServerTimeNow()+3.5
		buildLetters(#data.Sequence)
		window = math.max(0.5, (data.Deadline or workspace:GetServerTimeNow() + 3.5) - workspace:GetServerTimeNow())
		for index, letter in ipairs(letters) do
			letter.Text = data.Sequence[index]
			letter.TextColor3 = Color3.fromRGB(255, 230, 110)
		end
		frame.Visible = true
  player:SetAttribute("ChainBreakActive",true)
		ContextActionService:BindActionAtPriority(actionName, input, false, 10000, table.unpack(keyCodes))
		rendering = RunService.RenderStepped:Connect(function()
			if not active then
				return
			end
			local remaining = math.max(0, active.Deadline - workspace:GetServerTimeNow())
			timer.Text = string.format("%.1fs", remaining)
			fill.Size = UDim2.fromScale(math.clamp(remaining / window, 0, 1), 1)
		end)
	elseif active and data.Id == active.Id then
		if action == "Progress" then
			for index, letter in ipairs(letters) do
				letter.TextColor3 = index <= data.Progress and Color3.fromRGB(136, 255, 128)
					or Color3.fromRGB(255, 230, 110)
			end
		elseif action == "Close" then
			close()
		end
	end
end)
player.CharacterRemoving:Connect(close)
player.CharacterAdded:Connect(close)
script.Destroying:Connect(function() close() gui:Destroy() end)
