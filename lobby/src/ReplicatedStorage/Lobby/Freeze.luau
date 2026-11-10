--!nonstrict
-- Stops the local character from walking while a menu or cutscene is open. Client only.
-- Uses the humanoid rather than PlayerModule, which is not guaranteed to exist under PlayerScripts.
local Players = game:GetService("Players")

local Freeze = {}
local saved = nil

function Freeze.On()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and not saved then
		saved = { humanoid = humanoid, walk = humanoid.WalkSpeed, jump = humanoid.JumpHeight, power = humanoid.JumpPower }
		humanoid.WalkSpeed, humanoid.JumpHeight, humanoid.JumpPower = 0, 0, 0
	end
end

function Freeze.Off()
	if saved then
		if saved.humanoid.Parent then
			saved.humanoid.WalkSpeed, saved.humanoid.JumpHeight, saved.humanoid.JumpPower = saved.walk, saved.jump, saved.power
		end
		saved = nil
	end
end

return Freeze
