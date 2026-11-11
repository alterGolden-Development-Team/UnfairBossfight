--!nonstrict
--[[
 AmbientService - small live touches on the map that need the server.
   * The proving ground's score board (World.Stage.Board): last hit, best hit and the number of hits on the class training dummy
     (workspace.ClassTrainingDummy, put up by TryoutService). The best resets after a quiet minute.
   * Anything tagged UnfairSway (the shop's hanging sign) gets a gust of wind now and then, so it swings on its hinge.
]]
local CollectionService = game:GetService("CollectionService")

local world = workspace:WaitForChild("World", 30)

-- the score board ----------------------------------------------------------------------------------------------------------
task.spawn(function()
	local stage = world and world:WaitForChild("Stage", 30)
	local boardModel = stage and stage:WaitForChild("Board", 30)
	local face = boardModel and boardModel:FindFirstChild("Ink")
	local gui = face and face:FindFirstChild("Score")
	if not gui then
		return
	end
	local last, best, count, lastAt = 0, 0, 0, 0
	local function show()
		gui.Last.Text = last > 0 and string.format("Last hit  %d", math.floor(last + 0.5)) or "Last hit  -"
		gui.Best.Text = best > 0 and string.format("Best hit  %d", math.floor(best + 0.5)) or "Best hit  -"
		gui.Count.Text = string.format("Hits  %d", count)
	end
	local watched
	local function watch(dummy)
		local humanoid = dummy and dummy:FindFirstChildOfClass("Humanoid")
		if not humanoid or watched == humanoid then
			return
		end
		watched = humanoid
		local previous = humanoid.Health
		humanoid.HealthChanged:Connect(function(current)
			local dealt = previous - current
			previous = current
			if dealt > 0.5 then
				last, count, lastAt = dealt, count + 1, os.clock()
				best = math.max(best, dealt)
				show()
			end
		end)
	end
	watch(workspace:FindFirstChild("ClassTrainingDummy"))
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "ClassTrainingDummy" then
			task.wait(0.2)
			watch(child)
		end
	end)
	while true do
		task.wait(5)
		if count > 0 and os.clock() - lastAt > 60 then
			last, best, count = 0, 0, 0
			show()
		end
	end
end)

-- gusts of wind ----------------------------------------------------------------------------------------------------------
task.spawn(function()
	local random = Random.new()
	while true do
		task.wait(random:NextNumber(3, 7))
		for _, model in CollectionService:GetTagged("UnfairSway") do
			local part = model:IsA("Model") and model.PrimaryPart or model
			if part and part:IsA("BasePart") and not part.Anchored then
				local mass = part.AssemblyMass
				part:ApplyAngularImpulse(part.CFrame.RightVector * random:NextNumber(-1, 1) * mass * 6)
			end
		end
	end
end)
