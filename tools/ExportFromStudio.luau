--[[
 Exports every script in the place to Rojo-style files under src/ (see README).
 Run it in Studio's command bar while tools/export-receiver.ps1 is running and
 Game Settings > Security > Allow HTTP Requests is ON (switch it back off afterwards).

 Layout (Rojo 7 conventions):
   ModuleScript -> Name.luau, Script -> Name.server.luau, LocalScript/client Script -> Name.client.luau
   a script with scripts under it -> Name/init.<ext> plus its children
   any other container on the way to a script -> Name/ (init.meta.json keeps its class)
 Every folder and script gets ignoreUnknownInstances, so a Rojo sync never deletes the place's
 models, GUIs, values and other non-script content. Backup folders are skipped.
]]
local Http = game:GetService("HttpService")
local URL = "http://localhost:34999"
local SERVICES = { "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui", "StarterPlayer" }
local SKIP = { VFXBackups = true, MapBackups = true, VFXQuarantine = true }
local INVALID = '[<>:"/\\|%?%*]'

local files, notes = {}, {}
local function add(path, content)
	files[#files + 1] = { path = path, content = content }
end
local function extension(script)
	if script:IsA("ModuleScript") then
		return ".luau"
	end
	if script:IsA("LocalScript") or script.RunContext == Enum.RunContext.Client then
		return ".client.luau"
	end
	return ".server.luau"
end
local function hasScripts(instance)
	for _, d in ipairs(instance:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			return true
		end
	end
	return false
end
local function metaFor(instance)
	local meta = { ignoreUnknownInstances = true }
	if instance:IsA("BaseScript") then
		local properties = {}
		if not instance.Enabled then
			properties.Disabled = true
		end
		if instance:IsA("Script") and not instance:IsA("LocalScript") and instance.RunContext ~= Enum.RunContext.Legacy then
			properties.RunContext = instance.RunContext.Name
		end
		if next(properties) then
			meta.properties = properties
		end
	elseif not instance:IsA("LuaSourceContainer") and not instance:IsA("Folder") then
		meta.className = instance.ClassName
	end
	return meta
end

local function walk(parent, dir)
	local taken = {}
	for _, child in ipairs(parent:GetChildren()) do
		local isScript = child:IsA("LuaSourceContainer")
		local nested = not SKIP[child.Name] and hasScripts(child)
		if SKIP[child.Name] or not (isScript or nested) then
			continue
		end
		local name = child.Name:gsub(INVALID, "_")
		if name ~= child.Name then
			notes[#notes + 1] = "renamed on disk (fix before syncing): " .. child:GetFullName() .. " -> " .. name
		end
		local key = name:lower()
		if taken[key] then
			notes[#notes + 1] = "duplicate sibling name (fix before syncing): " .. child:GetFullName()
			name ..= "__dup" .. tostring(#notes)
		end
		taken[key] = true
		if isScript and not nested then
			add(dir .. name .. extension(child), child.Source)
			if #child:GetChildren() > 0 or metaFor(child).properties then
				add(dir .. name .. ".meta.json", Http:JSONEncode(metaFor(child)))
			end
		else
			local sub = dir .. name .. "/"
			if isScript then
				add(sub .. "init" .. extension(child), child.Source)
			end
			add(sub .. "init.meta.json", Http:JSONEncode(metaFor(child)))
			walk(child, sub)
		end
	end
end

for _, serviceName in ipairs(SERVICES) do
	walk(game:GetService(serviceName), "src/" .. serviceName .. "/")
end
add("export-report.txt", ("Exported %d files from %s at %s\n\n%s\n"):format(
	#files, game.Name, DateTime.now():ToIsoDate(), #notes > 0 and table.concat(notes, "\n") or "No naming problems."))

local batch, size, sent = {}, 0, 0
local function flush()
	if #batch == 0 then
		return
	end
	Http:PostAsync(URL .. "/files", Http:JSONEncode(batch), Enum.HttpContentType.ApplicationJson)
	sent += #batch
	batch, size = {}, 0
end
for _, file in ipairs(files) do
	batch[#batch + 1] = file
	size += #file.content
	if size > 400000 then
		flush()
	end
end
flush()
Http:PostAsync(URL .. "/done", "")
print(("Exported %d files (%d naming notes)"):format(sent, #notes))
