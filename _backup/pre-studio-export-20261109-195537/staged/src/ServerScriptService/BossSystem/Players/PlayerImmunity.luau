 
local api = {}
local keys = { "DashInvulnerableUntil", "RespawnInvulnerableUntil" }
function api.Refresh(char)
	 
	if not char then
		return false
	end
	local now = workspace:GetServerTimeNow()
	local active = false
	for _, key in ipairs(keys) do
		if now < (char:GetAttribute(key) or 0) then
			active = true
			break
		end
	end
	if char:GetAttribute("Invulnerable") ~= active then
		char:SetAttribute("Invulnerable", active)
	end
	return active
end
function api.Grant(char, key, duration)
	local deadline = workspace:GetServerTimeNow() + duration
	char:SetAttribute(key, deadline)
	api.Refresh(char)
	task.delay(duration, function()
		if char.Parent then
			api.Refresh(char)
		end
	end)
	return deadline
end
return api
