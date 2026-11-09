 
local Run = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Style = require(script.Parent.Style)
local DARK = Style.DARK
local GOLD = Style.GOLD
local PALE = Style.PALE
local WHITE = Style.WHITE
local GREEN = Style.GREEN
local RED = Style.RED
local BULB_OFF = Style.BULB_OFF
local BULB_COUNT = Style.BULB_COUNT
local STAGE_RADIUS = Style.STAGE_RADIUS
return function(context)
	local folder, frame, cast, state = context.Folder, context.Frame, context.Cast, context.State
	local timeScale = context.TimeScale
	local part, cylinder = context.Visuals.Part, context.Visuals.Cylinder
	 
	local stage = cylinder(
		folder,
		"GameshowStage",
		2,
		0.18,
		frame * CFrame.new(0, 0.1, 0),
		DARK,
		Enum.Material.SmoothPlastic
	)
	local edge =
		cylinder(folder, "StageGoldEdge", 2, 0.12, frame * CFrame.new(0, 0.04, 0), GOLD, Enum.Material.Neon)
	local grow = TweenInfo.new(1.1 * timeScale, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(stage, grow, { Size = Vector3.new(0.18, 132, 132) }):Play()
	TweenService:Create(edge, grow, { Size = Vector3.new(0.12, 134, 134) }):Play()

	 
	local ambience = { Bulbs = {}, Beams = {}, Show = 0, Aim = 0, Spin = 0 }
	do
		local sun = Instance.new("Model")
		sun.Name = "Sunburst"
		sun.Parent = folder
		local hub = part(sun, "Hub", Vector3.one, frame * CFrame.new(0, 0.22, 0), GOLD, nil, 1)
		sun.PrimaryPart = hub
		for i = 1, 12 do
			part(
				sun,
				"Ray" .. i,
				Vector3.new(3.4, 0.05, 58),
				frame
					* CFrame.new(0, 0.22, 0)
					* CFrame.Angles(0, i * math.pi / 6, 0)
					* CFrame.new(0, 0, -34),
				PALE,
				Enum.Material.Neon,
				0.82
			)
		end
		ambience.Sun = sun
		for i = 1, BULB_COUNT do
			local a = i / BULB_COUNT * math.pi * 2
			ambience.Bulbs[i] = part(
				folder,
				"MarqueeBulb" .. i,
				Vector3.one * 2,
				frame
					* CFrame.new(
						math.cos(a) * (STAGE_RADIUS + 1.5),
						1.4,
						math.sin(a) * (STAGE_RADIUS + 1.5)
					),
				GOLD,
				Enum.Material.Neon,
				1,
				Enum.PartType.Ball
			)
		end
		for i = 1, 4 do
			local sx = i % 2 == 1 and -1 or 1
			local sz = i <= 2 and -1 or 1
			ambience.Beams[i] = {
				Part = cylinder(
					folder,
					"Searchlight" .. i,
					3,
					120,
					CFrame.new(frame.Position),
					WHITE,
					Enum.Material.Neon,
					1
				),
				Base = Vector3.new(sx * 58, 0, sz * 34),
				Phase = i * 1.7,
			}
		end
	end
	local function bulbColor(i, n, t)
		if state.Mood == "Win" then
			return (math.floor(t * 3) + i) % 2 == 0 and GREEN or WHITE
		elseif state.Mood == "Lose" then
			return math.floor(t * 2) % 2 == 0 and RED or BULB_OFF
		elseif state.Stage == "Pick" and state.Deadline then
			local frac = math.clamp(
				(state.Deadline - workspace:GetServerTimeNow()) / math.max(state.PickTotal, 0.001),
				0,
				1
			)
			if i / n > frac then
				return BULB_OFF
			end
			return (frac < 0.3 and math.floor(t * 3) % 2 == 0) and RED or WHITE
		end
		local tempo = state.Stage == "Suspense" and 5 or state.Stage == "Shuffle" and 3 or 1.5
		return (math.floor(t * tempo) + i) % 3 == 0 and PALE or GOLD
	end
	task.spawn(function()
		local t = 0
		while folder.Parent and cast:Alive() do
			local dt = Run.Heartbeat:Wait()
			t += dt
			ambience.Show = math.min(1, ambience.Show + dt * 0.7)
			local want = state.Stage == "Suspense" and 1 or 0
			ambience.Aim += (want - ambience.Aim) * math.min(1, dt * 3)
			ambience.Spin += dt * (state.Stage == "Suspense" and 0.5 or 0.15)
			ambience.Sun:PivotTo(frame * CFrame.new(0, 0.22, 0) * CFrame.Angles(0, ambience.Spin, 0))
			local n = #ambience.Bulbs
			for i, bulb in ipairs(ambience.Bulbs) do
				bulb.Transparency = i / n <= ambience.Show * 1.15 and 0.25 or 1
				bulb.Color = bulbColor(i, n, t)
			end
			for _, info in ipairs(ambience.Beams) do
				local origin = frame:PointToWorldSpace(info.Base)
				local wander = Vector3.new(
					math.sin(t * 0.9 + info.Phase) * 46,
					85,
					math.cos(t * 0.7 + info.Phase * 1.3) * 46
				)
				local aim = frame:PointToWorldSpace(info.Base + wander)
				if state.Focus then
					aim = aim:Lerp(state.Focus, ambience.Aim)
				end
				info.Part.CFrame = CFrame.lookAt(origin, aim)
					* CFrame.new(0, 0, -60)
					* CFrame.Angles(0, math.pi / 2, 0)
				info.Part.Transparency = 1 - 0.04 * ambience.Show
			end
		end
	end)
end
