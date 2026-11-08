local BossSystem = script:FindFirstAncestor("BossSystem")
local Run = game:GetService("RunService")
local api = {}

local function serverModule(item)
 local node=item
 while node and node~=BossSystem do
  if node:GetAttribute("RuntimeSide")=="Client"then return false end
  node=node.Parent
 end
 return true
end

function api.Run()
	workspace:SetAttribute("BossStartupReady", false)
	workspace:SetAttribute("BossStartupError", nil)
	workspace:SetAttribute("BossStartupProgress", 0)
	local modules = {}
	for _, item in ipairs(BossSystem:GetDescendants()) do
		if item:IsA("ModuleScript") and item ~= script and item.Name ~= "ProjectGuide" and serverModule(item) then
			table.insert(modules, item)
		end
	end
	table.sort(modules, function(a, b) return a:GetFullName() < b:GetFullName() end)
	local sliceStarted = os.clock()
	for index, module in ipairs(modules) do
		local ok, result = pcall(require, module)
		if not ok then
			workspace:SetAttribute("BossStartupError", "Combat setup could not finish.")
			warn("Combat startup: " .. module:GetFullName() .. ": " .. tostring(result))
			return false
		end
		workspace:SetAttribute("BossStartupProgress", index / #modules)
		if os.clock() - sliceStarted >= 0.003 then
			Run.Heartbeat:Wait()
			sliceStarted = os.clock()
		end
	end
	workspace:SetAttribute("BossStartupReady", true)
	return true
end

return api
