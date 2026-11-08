local Lighting=game:GetService("Lighting")
local S={}
local fields={"ClockTime","Brightness","Ambient","OutdoorAmbient","ColorShift_Top","ColorShift_Bottom","ExposureCompensation","FogColor","FogStart","FogEnd"}
local base={}
for _,key in fields do base[key]=Lighting[key]end
local sky=Lighting:FindFirstChildOfClass("Sky")
local skyBase=sky and {MoonAngularSize=sky.MoonAngularSize,StarCount=sky.StarCount,CelestialBodiesShown=sky.CelestialBodiesShown}
local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
local airBase=atmosphere and {Color=atmosphere.Color,Decay=atmosphere.Decay,Density=atmosphere.Density,Haze=atmosphere.Haze,Glare=atmosphere.Glare}
local grade
function S.IsHellaven()
 return (workspace:GetAttribute("ActiveDifficulty") or workspace:GetAttribute("SelectedDifficulty"))=="Hellaven"
end
function S.Restore()
 for key,value in base do Lighting[key]=value end
 if sky and sky.Parent then for key,value in skyBase do sky[key]=value end end
 if atmosphere and atmosphere.Parent then for key,value in airBase do atmosphere[key]=value end end
 if grade then grade:Destroy()grade=nil end
 if S.IsHellaven()then
  Lighting.ClockTime=22.5 Lighting.Brightness=1.4
  Lighting.Ambient=Color3.fromRGB(105,24,35)Lighting.OutdoorAmbient=Color3.fromRGB(140,30,42)
  Lighting.FogColor=Color3.fromRGB(100,12,25)
  if sky and sky.Parent then sky.CelestialBodiesShown=true sky.MoonAngularSize=22 sky.StarCount=1500 end
  if atmosphere and atmosphere.Parent then
   atmosphere.Color=Color3.fromRGB(195,55,65)atmosphere.Decay=Color3.fromRGB(90,5,20)
   atmosphere.Density=.38 atmosphere.Haze=2 atmosphere.Glare=.4
  end
  grade=Instance.new("ColorCorrectionEffect")grade.Name="HellavenTheme"
  grade.TintColor=Color3.fromRGB(255,115,130)grade.Contrast=.12 grade.Saturation=.15 grade.Parent=Lighting
 end
end
return S
