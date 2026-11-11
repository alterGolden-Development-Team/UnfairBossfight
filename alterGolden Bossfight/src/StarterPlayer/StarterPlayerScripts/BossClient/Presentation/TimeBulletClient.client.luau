 
 
 
 
 
 
 
 
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Quality=require(game.ReplicatedStorage.BossShared.Presentation.VisualQuality)

local TAG = "TimeBulletVisual"
local TIME = Color3.fromRGB(255, 224, 70)
local WHITE = Color3.fromRGB(255, 253, 188)
local FROZEN = Color3.fromRGB(214, 190, 110)
local BASE_SIZE = 3.6  

local TARGET_SPEED = { Summon = 0.6, Flying = 1, Cue = -3.2, Frozen = 0 }

local tracked = {}
local renderConnection
local step

local function bind(body)
	if tracked[body] then
		return
	end
	tracked[body] = {
		Phase = body:GetAttribute("TimePhase") or 0,
		Speed = 0.6,
		Scale = 1,
		Minute = 0,
		Hour = 0,
		Second = 0,
		Gear = 0,
	}
	if not renderConnection then
		renderConnection = RunService.RenderStepped:Connect(step)
	end
end
local function unbind(body)
	tracked[body] = nil
	if not next(tracked) and renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end



local function resolve(body, data)
	 
	local gui = body:FindFirstChild("TimeBulletClock")
	if not gui then
		return false
	end
	local face = gui:FindFirstChild("ClockFace")
	if not face then
		return false
	end
	data.Gui = gui
	data.Halo = gui:FindFirstChild("Halo")
	data.GearRing = face:FindFirstChild("GearRing")
	data.HourHand = face:FindFirstChild("HourHand")
	data.MinuteHand = face:FindFirstChild("MinuteHand")
	data.SecondHand = face:FindFirstChild("SecondHand")
	return data.Halo ~= nil
		and data.GearRing ~= nil
		and data.HourHand ~= nil
		and data.MinuteHand ~= nil
		and data.SecondHand ~= nil
end

local visualElapsed=0
step = function(dt)
 visualElapsed+=dt
 if visualElapsed<math.max(Quality.Get().Interval,1/30) then return end
 local camPos=workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
 dt=visualElapsed
 visualElapsed=0
	local now = os.clock()
	for body, data in pairs(tracked) do
		if not body.Parent then
			unbind(body)
		else
			local gui = data.Gui
			if camPos and body:IsA("BasePart") and (body.Position-camPos).Magnitude>260 then
				-- (too far to read: leave it as it is)
			elseif (not gui or not gui.Parent) and not resolve(body, data) then
				data.Gui = nil
			else
				local state = body:GetAttribute("TimeState") or "Summon"
				local target = TARGET_SPEED[state] or 1
				data.Speed += (target - data.Speed) * math.min(1, dt * (state == "Frozen" and 7 or 12))
				local speed = data.Speed
				data.Minute = (data.Minute + speed * 420 * dt) % 360
				data.Hour = (data.Hour + speed * 35 * dt) % 360
				data.Second = (data.Second + speed * 900 * dt) % 360
				data.Gear = (data.Gear - speed * 70 * dt) % 360

				 
				local twitch = 0
				if state == "Frozen" then
					twitch = math.sin((now + data.Phase) * 34) * 2.4
				end
				data.MinuteHand.Rotation = data.Minute + twitch
				data.HourHand.Rotation = data.Hour
				data.SecondHand.Rotation = data.Second + twitch * 2
				data.GearRing.Rotation = data.Gear

				local pulse = math.sin((now + data.Phase) * (state == "Frozen" and 2 or 9))
				local halo = data.Halo
				local haloScale = 1 + 0.07 * pulse + (state == "Cue" and 0.12 or 0)
				halo.Size = UDim2.fromScale(haloScale, haloScale)
				if state == "Cue" then
					halo.BackgroundColor3 = WHITE
					halo.BackgroundTransparency = 0.5
				elseif state == "Frozen" then
					halo.BackgroundColor3 = FROZEN
					halo.BackgroundTransparency = 0.9
				else
					halo.BackgroundColor3 = TIME
					halo.BackgroundTransparency = 0.8 + 0.06 * pulse
				end

				local wantScale = state == "Cue" and 1.25 or state == "Frozen" and 0.92 or 1
				data.Scale += (wantScale - data.Scale) * math.min(1, dt * 14)
				local size = BASE_SIZE * data.Scale
				data.Gui.Size = UDim2.fromScale(size, size)
			end
		end
	end
end
local addedConnection = CollectionService:GetInstanceAddedSignal(TAG):Connect(bind)
local removedConnection = CollectionService:GetInstanceRemovedSignal(TAG):Connect(unbind)
for _, body in ipairs(CollectionService:GetTagged(TAG)) do
	bind(body)
end
script.Destroying:Connect(function()
	addedConnection:Disconnect()
	removedConnection:Disconnect()
	if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
	table.clear(tracked)
end)
