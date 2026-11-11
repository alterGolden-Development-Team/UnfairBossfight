-- Boots the VFX engine on this client: routes server cues to effect modules and
-- decorates parts the server tags with "VFXDecorate" (e.g. invisible projectile carriers).
local CollectionService=game:GetService("CollectionService")
local VFX=game:GetService("ReplicatedStorage"):WaitForChild("VFXEngine")
local E=require(VFX)
E.Preload()

 -- the HUD's Effects setting (Auto / Low / High, BossShared.Presentation.VisualQuality) scales every
 -- engine effect: particle counts and rates, and whether flash lights are made at all
local Quality=require(game:GetService("ReplicatedStorage"):WaitForChild("BossShared").Presentation.VisualQuality)
local function syncQuality()
 local profile=Quality.Get()
 E.Quality=profile.Particles
 E.Lights=profile.Lights
end
syncQuality()
Quality.Changed:Connect(syncQuality)

local effects={}
local function effect(name)
 if effects[name]==nil then
  local m=VFX.Effects:FindFirstChild(name)
  local ok,res=pcall(function()return m and require(m)end)
  if not ok then warn("[VFXEngine] effect "..name.." failed to load: "..tostring(res))end
  effects[name]=ok and res or false
 end
 return effects[name]or nil
end

 -- load every effect module now, so a first cast doesn't stall while its code loads
for _,m in ipairs(VFX.Effects:GetChildren())do if m:IsA("ModuleScript")then effect(m.Name)end end

E.Net.Listen(function(name,stage,data)
 local fx=effect(name)
 local fn=fx and fx[stage]
 if not fn then return end
 local ok,err=pcall(fn,E,data)
 if not ok then warn(("[VFXEngine] %s.%s: %s"):format(name,stage,tostring(err)))end
end)

local function decorate(part)
 local name=part:GetAttribute("VFX")
 local fx=name and effect(name)
 if fx and fx.Decorate then
  local ok,err=pcall(fx.Decorate,E,part)
  if not ok then warn("[VFXEngine] decorate "..name..": "..tostring(err))end
 end
end
for _,p in ipairs(CollectionService:GetTagged("VFXDecorate"))do task.spawn(decorate,p)end
CollectionService:GetInstanceAddedSignal("VFXDecorate"):Connect(decorate)
