local BossSystem = script:FindFirstAncestor("BossSystem")
local Players = game:GetService("Players")
local api = {}
local dummy
local MAX_HEALTH = 1000000000
local WINDOW = 5
local function makePart(model, name, size, cf, color, shape)
 local p = Instance.new("Part")
 p.Name, p.Size, p.CFrame = name, size, cf
 p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, true
 p.Material, p.Color, p.TopSurface, p.BottomSurface = Enum.Material.SmoothPlastic, color, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
 if shape then p.Shape = shape end
 p.Parent = model
 return p
end
local function create()
 local arena = workspace:FindFirstChild("GoldenGrasslandArena")
 local floor = arena and arena:FindFirstChild("Grassland")
 if not floor then return nil end
 local model = Instance.new("Model")
 model.Name = "ClassTrainingDummy"
 model:SetAttribute("DamageableClone", true)
 model:SetAttribute("TrainingDummy", true)
 local base = floor.Position + Vector3.new(0, floor.Size.Y * 0.5, 0)
 local torsoCF = CFrame.new(base + Vector3.new(0, 4, 0))
 local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), torsoCF, Color3.fromRGB(40, 40, 48), Enum.PartType.Block)
 root.Transparency = 1
 model.PrimaryPart = root
 makePart(model, "Torso", Vector3.new(2, 2, 1), torsoCF, Color3.fromRGB(80, 95, 125))
 makePart(model, "Head", Vector3.new(1.4, 1.4, 1.4), torsoCF * CFrame.new(0, 1.7, 0), Color3.fromRGB(225, 190, 145), Enum.PartType.Ball)
 makePart(model, "Left Arm", Vector3.new(1, 2, 1), torsoCF * CFrame.new(-1.5, 0, 0), Color3.fromRGB(80, 95, 125))
 makePart(model, "Right Arm", Vector3.new(1, 2, 1), torsoCF * CFrame.new(1.5, 0, 0), Color3.fromRGB(80, 95, 125))
 makePart(model, "Left Leg", Vector3.new(1, 2, 1), torsoCF * CFrame.new(-0.5, -2, 0), Color3.fromRGB(45, 50, 65))
 makePart(model, "Right Leg", Vector3.new(1, 2, 1), torsoCF * CFrame.new(0.5, -2, 0), Color3.fromRGB(45, 50, 65))
 local humanoid = Instance.new("Humanoid")
 humanoid.Name, humanoid.MaxHealth, humanoid.Health = "Humanoid", MAX_HEALTH, MAX_HEALTH
 humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
 humanoid.BreakJointsOnDeath = false
 humanoid.Parent = model
 local gui = Instance.new("BillboardGui")
 gui.Name, gui.Size, gui.StudsOffset, gui.AlwaysOnTop = "DPSDisplay", UDim2.fromOffset(190, 54), Vector3.new(0, 2.8, 0), true
 gui.Adornee, gui.Parent = model.Head, model.Head
 local label = Instance.new("TextLabel")
 label.Name, label.Size, label.BackgroundColor3, label.BackgroundTransparency = "Readout", UDim2.fromScale(1, 1), Color3.fromRGB(12, 14, 20), 0.2
 label.TextColor3, label.TextStrokeTransparency, label.Font, label.TextSize = Color3.fromRGB(255, 230, 150), 0.35, Enum.Font.GothamBold, 18
 label.Text = "DPS  0"
 label.Parent = gui
 local hits, previous = {}, humanoid.Health
 humanoid.HealthChanged:Connect(function(current)
  local dealt = previous - current
  previous = current
  if dealt > 0 then hits[#hits + 1] = { os.clock(), dealt } end
  local now, sum, first = os.clock(), 0, 1
  for i, hit in ipairs(hits) do
   if now - hit[1] <= WINDOW then sum += hit[2] else first = i + 1 end
  end
  if first > 1 then for _ = 1, first - 1 do table.remove(hits, 1) end end
  label.Text = string.format("DPS  %s", string.format("%.0f", sum / WINDOW))
 end)
 humanoid.Died:Connect(function()
  task.delay(0.15, function() if humanoid.Parent and model.Parent then humanoid.Health = MAX_HEALTH end end)
 end)
 model.Parent = workspace
 return model
end
function api.Start()
 if workspace:GetAttribute("EncounterStarted") == true then return end
 if dummy and dummy.Parent then dummy:Destroy() end
 dummy = workspace:FindFirstChild("ClassTrainingDummy") or create()
 workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
  if workspace:GetAttribute("EncounterStarted") == true and dummy then dummy:Destroy(); dummy = nil end
 end)
 Players.PlayerRemoving:Connect(function() end)
end
return api

