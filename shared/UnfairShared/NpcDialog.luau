--!nonstrict
--[[
 NpcDialog - talking to someone in the world, without a dialogue box. The NPC's words appear over their head, typed out; when they
 ask something, numbered answers float beside them. Press 1, 2 or 3 (or click / tap an answer). You can keep moving and walk
 round them; only going far away (LEAVE_DISTANCE) ends the conversation.

   local talk = NpcDialog.Open(npcModel, { Color = gold })
   if not talk:Say("Fair prices. No refunds.") then return end      -- false when you walked away
   local pick = talk:Choose({ "Show me the classes", "Show me the orbs", "Tell me a story" })   -- 1..n, or nil
   talk:Close()

 Client only. One conversation at a time: opening a new one closes the old one.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Dialog = {}
Dialog.__index = Dialog

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
local PAD = { Enum.KeyCode.KeypadOne, Enum.KeyCode.KeypadTwo, Enum.KeyCode.KeypadThree, Enum.KeyCode.KeypadFour }
local LEAVE_DISTANCE = 32 -- studs from the NPC's head
local current

local function make(className, props, parent)
	local i = Instance.new(className)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function headOf(model)
	return model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
end

-- How high over the head the words go: above the NPC's own name (a "Nameplate" billboard, or the humanoid's name tag) so the
-- two never overlap. Returns the height and whether the NPC already shows a name.
local function speechHeight(model, head)
	local plate = head and head:FindFirstChild("Nameplate")
	if plate and plate:IsA("BillboardGui") then
		return plate.StudsOffset.Y + plate.StudsOffsetWorldSpace.Y + 2.6, true
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
		return 3.4, true
	end
	return 1.6, false
end

function Dialog.Open(model, options)
	if current then
		current:Close()
	end
	options = options or {}
	local self = setmetatable({}, Dialog)
	self.model = model
	self.color = options.Color or Color3.fromRGB(255, 226, 150)
	self.textColor = options.TextColor or Color3.fromRGB(250, 246, 236)
	self.font = options.Font or Enum.Font.Merriweather
	self.speed = options.Speed or 45 -- characters per second
	self.closed = false
	self.closedEvent = Instance.new("BindableEvent")
	self.glitch = options.Glitch -- function(text) -> text: scrambles the typed text (the glitched man)
	-- options.Stay = true: even going far away does not end it (cutscenes); options.LeaveDistance overrides LEAVE_DISTANCE
	local head = headOf(model)
	local height, named = speechHeight(model, head)
	local gui = player:WaitForChild("PlayerGui")
	self.speech = make("BillboardGui", {
		Name = "NpcSpeech", Adornee = head, Size = UDim2.fromOffset(420, 150), StudsOffsetWorldSpace = Vector3.new(0, options.Height or height, 0),
		SizeOffset = Vector2.new(0, 0.5), -- the bottom edge (where the words sit) at that height
		AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 80, ResetOnSpawn = false,
	}, gui)
	self.line = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Font = self.font, TextSize = 21, TextColor3 = self.textColor, TextStrokeTransparency = 0.2, TextStrokeColor3 = Color3.fromRGB(14, 10, 8),
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Bottom, Text = "", RichText = false,
	}, self.speech)
	if options.Name and not named then -- (an NPC that already shows its name does not get a second one)
		self.nameTag = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = self.color, TextStrokeTransparency = 0.3, Text = options.Name,
		}, self.speech)
	end
	self.answers = make("BillboardGui", {
		Name = "NpcAnswers", Adornee = head, Size = UDim2.fromOffset(330, 130), StudsOffsetWorldSpace = Vector3.new(0, -0.6, 0),
		SizeOffset = Vector2.new(0.62, -0.25), -- beside and a little below the head, clear of the words
		AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 80, Active = true, Enabled = false, ResetOnSpawn = false,
	}, gui)
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, self.answers)
	-- only going far away ends it: moving, jumping or walking round the NPC does not
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local grace = os.clock() + 0.4
	self.conn = RunService.Heartbeat:Connect(function()
		if self.closed then
			return
		end
		if not model.Parent or not root or not root.Parent or not humanoid or humanoid.Health <= 0 then
			self:Close()
			return
		end
		if os.clock() < grace or options.Stay then
			return -- Stay: a cutscene line, nothing the player does ends it
		end
		if (root.Position - head.Position).Magnitude > (options.LeaveDistance or LEAVE_DISTANCE) then
			self:Close()
		end
	end)
	current = self
	return self
end

function Dialog:IsOpen()
	return not self.closed
end

-- Types the line over the NPC's head and leaves it up long enough to read. Returns false if the conversation ended meanwhile.
function Dialog:Say(text, hold)
	if self.closed then
		return false
	end
	self.answers.Enabled = false
	local shown = 0
	local length = utf8.len(text) or #text
	local started = os.clock()
	while shown < length do
		if self.closed then
			return false
		end
		shown = math.min(length, math.floor((os.clock() - started) * self.speed) + 1)
		local cut = utf8.offset(text, shown + 1)
		local part = cut and text:sub(1, cut - 1) or text
		self.line.Text = self.glitch and self.glitch(part) or part
		task.wait(1 / 30)
	end
	self.line.Text = self.glitch and self.glitch(text) or text
	local readFor = hold or math.clamp(length / 22, 1.2, 5)
	local untilAt = os.clock() + readFor
	while os.clock() < untilAt do
		if self.closed then
			return false
		end
		if self.glitch then
			self.line.Text = self.glitch(text)
		end
		task.wait(0.08)
	end
	return not self.closed
end

-- Shows numbered answers beside the NPC and waits for one. Returns its number, or nil when you walked away.
function Dialog:Choose(list)
	if self.closed then
		return nil
	end
	for _, child in self.answers:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	local picked
	local event = Instance.new("BindableEvent")
	for i, answer in list do
		local b = make("TextButton", {
			Name = "Answer" .. i, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, AutoButtonColor = false,
			Font = Enum.Font.GothamBold, TextSize = 19, TextColor3 = self.color, TextStrokeTransparency = 0.15,
			TextStrokeColor3 = Color3.fromRGB(14, 10, 8), TextXAlignment = Enum.TextXAlignment.Left, Text = i .. ".  " .. answer,
		}, self.answers)
		b.MouseEnter:Connect(function()
			b.TextColor3 = Color3.new(1, 1, 1)
		end)
		b.MouseLeave:Connect(function()
			b.TextColor3 = self.color
		end)
		b.Activated:Connect(function()
			if not picked then
				picked = i
				event:Fire()
			end
		end)
	end
	self.answers.Enabled = true
	local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or picked then
			return
		end
		for i = 1, #list do
			if input.KeyCode == KEYS[i] or input.KeyCode == PAD[i] then
				picked = i
				event:Fire()
				return
			end
		end
	end)
	local closeConn = self.closedEvent.Event:Connect(function()
		event:Fire()
	end)
	event.Event:Wait()
	keyConn:Disconnect()
	closeConn:Disconnect()
	event:Destroy()
	self.answers.Enabled = false
	if self.closed then
		return nil
	end
	return picked
end

-- Clears the words but keeps the conversation (for a pause between lines).
function Dialog:Clear()
	if not self.closed then
		self.line.Text = ""
		self.answers.Enabled = false
	end
end

function Dialog:Close()
	if self.closed then
		return
	end
	self.closed = true
	if self.conn then
		self.conn:Disconnect()
	end
	self.closedEvent:Fire()
	task.delay(0.05, function()
		self.speech:Destroy()
		self.answers:Destroy()
		self.closedEvent:Destroy()
	end)
	if current == self then
		current = nil
	end
end

-- The conversation that is open right now, if any.
function Dialog.Current()
	return current
end

return Dialog
