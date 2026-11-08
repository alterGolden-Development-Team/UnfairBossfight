 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = game.ReplicatedStorage:WaitForChild("TemporalInput")
local session, connection
local function stop()
	session = nil
	if connection then
		connection:Disconnect()
		connection = nil
	end
end
local function direction(character)
	if Input:GetFocusedTextBox() then
		return Vector3.zero
	end
	local x = (Input:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
	local z = (Input:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
	local camera = workspace.CurrentCamera
	if not camera or x == 0 and z == 0 then
		return Vector3.zero
	end
	local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if forward.Magnitude < 0.001 then
		forward = Vector3.new(0, 0, -1)
	end
	local right = forward.Unit:Cross(Vector3.yAxis)
	local intent = right * x + forward.Unit * z
	return intent.Magnitude > 0.001 and intent.Unit or Vector3.zero
end
local remoteConnection = remote.OnClientEvent:Connect(function(kind, id, character, duration)
	if kind == "Begin" then
		stop()
		if typeof(character) ~= "Instance" or character ~= player.Character then
			return
		end
		session = {
			id = id,
			character = character,
			sequence = 0,
			expires = os.clock() + math.clamp(duration or 2.5, 0.5, 4) + 0.1,
		}
		local elapsed = 0.05
		connection = Run.Heartbeat:Connect(function(dt)
			local current = session
			local h = current and current.character:FindFirstChildOfClass("Humanoid")
			if
				not current
				or player.Character ~= current.character
				or not h
				or h.Health <= 0
				or os.clock() > current.expires
			then
				stop()
				return
			end
			elapsed += dt
			if elapsed < 0.05 then
				return
			end
			elapsed = 0
			current.sequence += 1
			remote:FireServer("Input", current.id, current.sequence, direction(current.character))
		end)
	elseif (kind == "Replay" or kind == "End") and session and session.id == id then
		stop()
	end
end)
local removingConnection = player.CharacterRemoving:Connect(stop)
script.Destroying:Connect(function()
	stop()
	remoteConnection:Disconnect()
	removingConnection:Disconnect()
end)
