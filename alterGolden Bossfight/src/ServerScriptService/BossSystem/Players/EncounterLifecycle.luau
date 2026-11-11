local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local api = {}

function api.Start(resetEncounter)
	local remote = Replicated:WaitForChild("EncounterLifecycle")
	local connections, lastRequest = {}, {}
	local retrying = false
	local function refresh()
		local players = Players:GetPlayers()
		local available = #players > 0 and workspace:GetAttribute("EncounterStarted") == true
			and workspace:GetAttribute("BossEncounterWon") ~= true and not retrying
		local participants = 0
		for _, player in ipairs(players) do
			if player:GetAttribute("ViewAsServer") ~= true then
				participants += 1
				if player:GetAttribute("PermanentlyDefeated") ~= true then available = false end
			end
		end
		available = available and participants > 0
		workspace:SetAttribute("EncounterRetryAvailable", available)
		return available
	end
	local function joined(player)
		player:SetAttribute("EncounterClientReady", false)
		player:SetAttribute("EncounterRetrying", false)
		connections[player] = {
			player:GetAttributeChangedSignal("PermanentlyDefeated"):Connect(refresh),
			player:GetAttributeChangedSignal("ViewAsServer"):Connect(refresh),
		}
		refresh()
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(function(player)
		if connections[player] then
			for _, connection in ipairs(connections[player]) do connection:Disconnect() end
		end
		connections[player], lastRequest[player] = nil, nil
		task.defer(refresh)
	end)
	for _, player in ipairs(Players:GetPlayers()) do joined(player) end
	workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(refresh)
	workspace:GetAttributeChangedSignal("BossEncounterWon"):Connect(refresh)
	remote.OnServerEvent:Connect(function(player, action)
		if action == "Ready" then
			if workspace:GetAttribute("BossStartupReady") == true then
				player:SetAttribute("EncounterClientReady", true)
			end
			return
		end
		if action == "ReturnToLobby" then
			-- one player leaves for the lobby; the rules and the teleport live in Encounter/LobbyReturn
			local BossSystem = script:FindFirstAncestor("BossSystem")
			require(BossSystem.Encounter.LobbyReturn).Request(player, function(text)
				remote:FireClient(player, "ReturnRejected", text)
			end)
			return
		end
		if action ~= "Retry" or player:GetAttribute("PermanentlyDefeated") ~= true then return end
		local now = os.clock()
		if now - (lastRequest[player] or -math.huge) < 2 then return end
		lastRequest[player] = now
		if not refresh() then
			remote:FireClient(player, "RetryRejected", "The other players are still fighting.")
			return
		end
		retrying = true
		refresh()
		local participants = Players:GetPlayers()
		for _, participant in ipairs(participants) do participant:SetAttribute("EncounterRetrying", true) end
		task.spawn(function()
			local ok, err = xpcall(function()
				resetEncounter()
				local sequence = workspace:GetAttribute("BossEntranceSequence")
				local deadline = os.clock() + 15
				repeat
					local allReady = true
					for _, participant in ipairs(participants) do
						if participant.Parent == Players then
							local char = participant.Character
							local h = char and char:FindFirstChildOfClass("Humanoid")
							if not h or h.Health <= 0 or char:GetAttribute("R6AppearanceFinished") ~= true then
								allReady = false
							end
						end
					end
					if allReady then break end
					task.wait(0.1)
				until os.clock() >= deadline or workspace:GetAttribute("BossEntranceSequence") ~= sequence
				 
				 
			end, debug.traceback)
			if not ok then warn("Encounter retry: " .. tostring(err)) end
			for _, participant in ipairs(participants) do
				if participant.Parent == Players then participant:SetAttribute("EncounterRetrying", false) end
			end
			retrying = false
			refresh()
		end)
	end)
end

return api
