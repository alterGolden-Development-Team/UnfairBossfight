--!nonstrict
--[[
 Azusa in the hub (SidePlaceService builds her). Hold E and she asks what you are looking for:
   1. Please teach me how to fight  -> she takes you to her training grounds (the Tutorial place)
   2. What is this place all about? -> she tells you about the game
   3. Nothing                       -> she lets you go
 Her words float over her head (NpcDialog); walking away ends the talk.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local NpcDialog = require(ReplicatedStorage.UnfairShared.NpcDialog)

local player = Players.LocalPlayer
local remote = LobbyRemotes.get("SidePlace")
local PINK = Color3.fromRGB(255, 176, 214)

local ABOUT = {
	"This is the Sanctum. The last piece of the old world that didn't fall.",
	"See those doors? Each one leads to someone who made the world unfair. alterGolden is the one everyone talks about.",
	"Talk to the Keeper in the shop to pick a class. Then go down to the palace, gather a party on a portal ring, and pick your trial.",
	"Win, and you get cash. Spend it on classes and orbs. Lose... and you learn something. That's where I come in.",
	"Oh, and the Divided Wood? Something in there is broken. If you find a door that flickers black and white... well. Be careful.",
}

local talking = false
local function talk(azusa, prompt)
	if talking then
		return
	end
	talking = true
	prompt.Enabled = false
	local d = NpcDialog.Open(azusa, { Name = "Azusa", Color = PINK, Font = Enum.Font.GothamMedium })
	local line = "Hi! What are you looking for?"
	while d:IsOpen() do
		if not d:Say(line, 0.4) then
			break
		end
		local pick = d:Choose({ "Please teach me how to fight", "What is this place all about?", "Nothing" })
		if pick == 1 then
			if d:Say("Sure! Stay close. I'll show you how to survive him.", 1.2) then
				remote:FireServer("Go", "Tutorial")
				d:Say("Here we go!", 2)
			end
			break
		elseif pick == 2 then
			local finished = true
			for _, about in ABOUT do
				if not d:Say(about) then
					finished = false
					break
				end
			end
			if not finished then
				break
			end
			line = "Anything else?"
		else
			d:Say("Okay! I'll be right here if you need me.", 1.6)
			break
		end
	end
	d:Close()
	prompt.Enabled = true
	talking = false
end

remote.OnClientEvent:Connect(function(action, data)
	if action == "Result" and type(data) == "table" and data.Message then
		local current = NpcDialog.Current()
		if current then
			current:Say(data.Message, 3)
		else
			warn("[Azusa] " .. data.Message)
		end
	end
end)

task.spawn(function()
	local world = workspace:WaitForChild("World", 30)
	local hub = world and world:WaitForChild("Hub", 30)
	local azusa = hub and hub:WaitForChild("Azusa", 60)
	local root = azusa and azusa:WaitForChild("HumanoidRootPart", 10)
	local prompt = root and root:WaitForChild("TalkPrompt", 10)
	if prompt then
		prompt.Triggered:Connect(function(who)
			if who == player then
				task.spawn(talk, azusa, prompt)
			end
		end)
	end
end)
