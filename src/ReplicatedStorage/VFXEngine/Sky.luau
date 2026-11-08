--[[
 VFXEngine.Sky (client)
 Named sky profiles (skybox + lighting + atmosphere + grade). Lighting and Atmosphere go
 through VFXEngine.Lighting as a layer, so they blend with every other effect and restore
 to whatever the arena's base currently is. This module only swaps the skybox (hidden under
 a short dark dip), toggles sun rays and drives its grade.
]]
local LightingService=game:GetService("Lighting")
local Tween=game:GetService("TweenService")
local Arb=require(script.Parent.Lighting)
local Sky={}

local PROFILES={
 PolarisNight={
  SkyAsset="PolarisNightSky",
  Lighting={ClockTime=0.4,Brightness=1.6,ExposureCompensation=0.15,
   Ambient=Color3.fromRGB(46,56,92),OutdoorAmbient=Color3.fromRGB(86,104,160),
   ColorShift_Top=Color3.fromRGB(120,170,255),ColorShift_Bottom=Color3.fromRGB(30,60,90)},
  Atmosphere={Density=.32,Offset=.1,Color=Color3.fromRGB(70,96,170),Decay=Color3.fromRGB(28,40,92),Glare=0,Haze=1.2},
  Grade={Brightness=.02,Contrast=.12,Saturation=.1,TintColor=Color3.fromRGB(214,228,255)},
  HideSunRays=true,
 },
}
Sky.Profiles=PROFILES

local stack={}
local savedSky,savedRays
local grade,dip
local NEUTRAL={Brightness=0,Contrast=0,Saturation=0,TintColor=Color3.new(1,1,1)}

local function effect(name)
 local e=LightingService:FindFirstChild(name)
 if not e then e=Instance.new("ColorCorrectionEffect")e.Name=name e.Parent=LightingService end
 return e
end
local function tw(inst,t,props)
 local ok,tween=pcall(Tween.Create,Tween,inst,TweenInfo.new(t,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),props)
 if ok then tween:Play()end
end
 -- dark dip used to hide the skybox swap
local function blink(t,fn)
 dip=dip or effect("VFXSkyDip")
 dip.Enabled=true
 tw(dip,t*.5,{Brightness=-.55})
 task.delay(t*.5,function()fn()tw(dip,t*.5,{Brightness=0})end)
end

local function showSky(p)
 local cur=LightingService:FindFirstChild("VFXSky")
 if p and p.SkyAsset then
  local src=script.Parent.Assets:FindFirstChild(p.SkyAsset)
  if not src then return end
  if cur then cur:Destroy()end
  if not savedSky then savedSky=LightingService:FindFirstChildOfClass("Sky")end
  if savedSky then savedSky.Parent=nil end
  local s=src:Clone()s.Name="VFXSky"s.Parent=LightingService
 else
  if cur then cur:Destroy()end
  if savedSky then savedSky.Parent=LightingService savedSky=nil end
 end
end
local function sunRays(hide)
 if hide and not savedRays then
  savedRays={}
  for _,r in ipairs(LightingService:GetChildren())do
   if r:IsA("SunRaysEffect")then savedRays[r]=r.Enabled r.Enabled=false end
  end
 elseif not hide and savedRays then
  for r,en in pairs(savedRays)do if r.Parent then r.Enabled=en end end
  savedRays=nil
 end
end

local function present(t)
 local top=stack[#stack]
 local p=top and PROFILES[top.Name]
 blink(math.min(t,.5),function()showSky(p)sunRays(p and p.HideSunRays)end)
 grade=grade or effect("VFXSkyGrade")
 grade.Enabled=true
 tw(grade,t,p and p.Grade or NEUTRAL)
end

 -- returns a handle; Pop(handle) removes that profile wherever it sits in the stack
function Sky.Push(name,t)
 local p=PROFILES[name]
 if not p then warn("[VFXEngine] unknown sky profile "..tostring(name))return nil end
 local h={Name=name,Id="Sky:"..name..":"..tostring(os.clock())}
 stack[#stack+1]=h
 Arb.Push(h.Id,{Lighting=p.Lighting,Atmosphere=p.Atmosphere},{Priority=50,Fade=t or 1})
 present(t or 1)
 return h
end

function Sky.Pop(h,t)
 local i=h and table.find(stack,h)
 if not i then return end
 table.remove(stack,i)
 Arb.Pop(h.Id,t or 1.2)
 present(t or 1.2)
end

function Sky.Clear()
 for _,h in ipairs(stack)do Arb.Pop(h.Id,.3)end
 table.clear(stack)
 present(.3)
end

return Sky
