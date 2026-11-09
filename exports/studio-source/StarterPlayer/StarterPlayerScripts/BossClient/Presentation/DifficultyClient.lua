-- The trial (difficulty) picker, opened by the trial statue (DifficultyControl "Open").
-- Hover a plate to preview a trial, click to choose it for the whole server. Look: TrialMenuKit.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Shared = game.ReplicatedStorage:WaitForChild("BossShared")
local Difficulty = require(Shared.Config.DifficultyConfig)
local Kit = require(Shared.Presentation.TrialMenuKit)
local remote = Shared:WaitForChild("DifficultyControl")
local C, F = Kit.Colors, Kit.Fonts

local screen = Kit.Screen("GoldenDifficultyMenu", player:WaitForChild("PlayerGui"))
local gui, stage = screen.Gui, screen.Stage
local subtitle = Kit.Header(stage, "The Trial of Golden", "Choose Your Trial")
local close = Kit.Close(stage)

local NUMERAL = { Hellaven = "V", TrueHardcore = "IV", Hardcore = "III", NerfedHardcore = "II", Easy = "I" }

local plates, locked, pending, previewId = {}, false, false, nil
local show
local count = #Difficulty.Order
local PW, GAP = 172, 14
local x0 = (Kit.W - (count * PW + (count - 1) * GAP)) / 2
for i, id in ipairs(Difficulty.Order) do
	local p = Difficulty.Profiles[id]
	local lives = p.StartingLives == 1 and "One life" or (p.StartingLives .. " lives")
	local ends = (p.FinalPhase or 5) < 5 and ("\nends at Phase " .. p.FinalPhase) or ""
	local plate = Kit.Plate(stage, {
		Id = id, Glyph = Kit.Numeral(NUMERAL[id] or tostring(i)), Name = p.Name, Note = lives .. ends, Color = p.Color,
		Position = UDim2.fromOffset(x0 + (i - 1) * (PW + GAP), 152), Size = UDim2.fromOffset(PW, 190),
	})
	plates[id] = plate
	plate.Button.MouseEnter:Connect(function()
		previewId = id
		show(id)
	end)
	plate.Button.MouseLeave:Connect(function()
		if previewId == id then
			previewId = nil
			show(Difficulty.Id())
		end
	end)
	plate.Button.Activated:Connect(function()
		previewId = id
		show(id)
		if locked or pending then
			return
		end
		pending = true
		remote:FireServer("Select", id)
		task.delay(2, function()
			pending = false
		end)
	end)
end

 -- the preview: name, the boss's words and the description on the left, the numbers on the right
local DETAIL_Y = 372
local left = Kit.Frame(stage, { Position = UDim2.fromOffset(60, DETAIL_Y), Size = UDim2.fromOffset(430, 200) })
local flow = Instance.new("UIListLayout")
flow.Padding = UDim.new(0, 8)
flow.SortOrder = Enum.SortOrder.LayoutOrder
flow.Parent = left
local name = Kit.Text(left, { FontFace = F.Title, TextSize = 30, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 34) })
local quote = Kit.Text(left, { FontFace = F.Italic, TextSize = 17, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
local attribution = Kit.Text(left, { Text = Kit.Spaced("— alterGolden"), FontFace = F.Caps, TextSize = 11, TextColor3 = C.GoldDim, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 14) })
local blurb = Kit.Text(left, { FontFace = F.Body, TextSize = 15, TextColor3 = C.Muted, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
Kit.Frame(stage, { Position = UDim2.fromOffset(520, DETAIL_Y + 4), Size = UDim2.fromOffset(1, 180), BackgroundTransparency = 0.6, BackgroundColor3 = C.GoldDim })
local GX, GW = 556, 384
local damage = Kit.Gauge(stage, UDim2.fromOffset(GX, DETAIL_Y + 4), GW, "Boss damage")
local pace = Kit.Gauge(stage, UDim2.fromOffset(GX, DETAIL_Y + 46), GW, "Attack pace")
local density = Kit.Gauge(stage, UDim2.fromOffset(GX, DETAIL_Y + 88), GW, "Attack density")
local lives = Kit.Pips(stage, UDim2.fromOffset(GX, DETAIL_Y + 130), GW, "Lives", 5)

local status = Kit.Text(stage, { FontFace = F.Italic, TextSize = 16, TextColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Center,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 586), Size = UDim2.fromOffset(820, 20) })
Kit.Text(stage, { Text = Kit.Spaced("Hover to preview · Click to choose · One trial for the whole server"), FontFace = F.Caps, TextSize = 11,
	TextColor3 = C.GoldDim, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 612), Size = UDim2.fromOffset(900, 14) })

local function frac(v, lo, hi)
	return (v - lo) / (hi - lo)
end
show = function(id)
	local p = Difficulty.Profiles[id] or Difficulty.Get()
	name.Text = p.Name
	name.TextColor3 = p.Color
	quote.Text = "“" .. table.concat(p.PickLines, " ") .. "”"
	blurb.Text = p.Description
	local speed = 1 / (p.Recovery or 1)
	damage(frac(p.Damage, 0.3, 1.4), string.format("× %.2f", p.Damage), p.Color)
	pace(frac(speed, 0.45, 1.3), string.format("× %.2f", speed), p.Color)
	density(frac(p.Density or 1, 0.35, 1.3), string.format("× %.2f", p.Density or 1), p.Color)
	lives(p.StartingLives, p.StartingLives == 1 and "one" or tostring(p.StartingLives), p.Color)
end

local function refresh()
	locked = workspace:GetAttribute("EncounterStarted") == true
	local id = Difficulty.Id()
	for key, plate in pairs(plates) do
		plate:Set(key == id, key == id and (locked and "Sealed" or "Chosen") or nil)
	end
	subtitle.Text = locked and "The trial is under way. Its terms are sealed until the encounter resets."
		or "One trial binds everyone in the server. Choose before the fight begins."
	show(previewId or id)
end
local function hide()
	gui.Enabled = false
end
screen.Backdrop.Activated:Connect(hide)
close.Activated:Connect(hide)
Input.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape then
		hide()
	end
end)
player.CharacterAdded:Connect(hide)
workspace:GetAttributeChangedSignal("SelectedDifficulty"):Connect(refresh)
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
	refresh()
	if workspace:GetAttribute("EncounterStarted") then
		hide()
	end
end)
remote.OnClientEvent:Connect(function(action, data)
	if action == "Open" then
		pending = false
		previewId = nil
		status.Text = ""
		refresh()
		screen.Resize()
		gui.Enabled = true
	elseif action == "Result" then
		pending = false
		status.Text = data.Message or ""
		previewId = nil
		refresh()
	end
end)
refresh()
