local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
if not game:GetService("RunService"):IsRunning() or not game:GetService("RunService"):IsClient() then return {} end
if not game:GetService("RunService"):IsClient() then return {} end
 
 
 
 
 
 

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")

local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)
local S=require(script.Parent.Style)
local Lighting=game:GetService("Lighting")
local grade=Instance.new("ColorCorrectionEffect")
grade.Name="PolarisGrade"grade.Enabled=false grade.Parent=Lighting
local TAG="PolarisCaster"
local RANGE=S.ScreenRange  
local CHARGE_TIME=S.Charge  
local player=Players.LocalPlayer

local trauma,punch,squeeze=0,0,0
local chargeStart,chargeFalloff,chargeActor=nil,0,nil
local seed=math.random()*100
local baseFov,lastFov
local fovCamera,lastShake,lastCameraFrame
local connections={}
local closed=false
local gradeStart,gradeActor

local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end
local function motion()return player:GetAttribute("ReduceMotion")==true and .25 or 1 end

local function falloff(actor)
 local cam=workspace.CurrentCamera
 if not cam then return 0 end
 local pos
 if actor:IsA("Model")then pos=actor:GetPivot().Position
 elseif actor:IsA("BasePart")then pos=actor.Position end
 if not pos then return 1 end
 return math.clamp(1-(cam.CFrame.Position-pos).Magnitude/RANGE,0,1)
end

 
 
 
 
local TweenService=game:GetService("TweenService")
local TITLE="P O L A R I S"
local SUBTITLE="A S T R A L    J U D G M E N T"
local LETTERBOX=.055    
local FLASHES=true

local ui
local overlayOn=false

local overlayTweens={}
local function tw(inst,time,props,style,dir)
 pcall(function()
  local tween=TweenService:Create(inst,TweenInfo.new(time,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props)
  overlayTweens[tween]=true
  tween.Completed:Connect(function()overlayTweens[tween]=nil end)
  tween:Play()
 end)
end

local function ensureUi()
 if ui then return ui end
 local ok,res=pcall(function()
  local pg=player:FindFirstChildOfClass("PlayerGui")or player:WaitForChild("PlayerGui",2)
  if not pg then return nil end
  local gui=Instance.new("ScreenGui")
  gui.Name="PolarisCinematic"
  gui.ResetOnSpawn=false
  gui.IgnoreGuiInset=true
  gui.DisplayOrder=50
  gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
  local function box(name,anchor,pos,size,color,alpha,z)
   local f=Instance.new("Frame")
   f.Name=name f.AnchorPoint=anchor f.Position=pos f.Size=size
   f.BackgroundColor3=color f.BackgroundTransparency=alpha f.BorderSizePixel=0 f.ZIndex=z
   f.Parent=gui
   return f
  end
  local function label(name,pos,size,text,font,color,maxSize)
   local l=Instance.new("TextLabel")
   l.Name=name l.AnchorPoint=Vector2.new(.5,.5) l.Position=pos l.Size=size
   l.BackgroundTransparency=1 l.Text=text l.Font=font l.TextColor3=color
   l.TextScaled=true l.TextTransparency=1 l.TextStrokeTransparency=1
   l.TextStrokeColor3=Color3.fromRGB(80,140,255) l.ZIndex=4
   local c=Instance.new("UITextSizeConstraint")
   c.MaxTextSize=maxSize
   c.Parent=l
   l.Parent=gui
   return l
  end
  local r={
   Gui=gui,
   Top=box("BarTop",Vector2.new(0,0),UDim2.fromScale(0,0),UDim2.fromScale(1,0),Color3.new(0,0,0),0,2),
   Bottom=box("BarBottom",Vector2.new(0,1),UDim2.fromScale(0,1),UDim2.fromScale(1,0),Color3.new(0,0,0),0,2),
   Flash=box("Flash",Vector2.new(0,0),UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.new(1,1,1),1,3),
   Title=label("Title",UDim2.fromScale(.5,.215),UDim2.fromScale(.8,.09),TITLE,Enum.Font.GothamBlack,Color3.fromRGB(205,228,255),60),
   Sub=label("Sub",UDim2.fromScale(.5,.285),UDim2.fromScale(.6,.035),SUBTITLE,Enum.Font.GothamMedium,Color3.fromRGB(160,190,240),22),
  }
  gui.Parent=pg
  return r
 end)
 if ok then ui=res end
 return ui
end

local function showOverlay(f)
 if f<=0 then return end
 local u=ensureUi()
 if not u then return end
 u.Gui.Enabled=true
 overlayOn=true
 tw(u.Title,.7,{TextTransparency=0,TextStrokeTransparency=.55,Position=UDim2.fromScale(.5,.2)})
 tw(u.Sub,.9,{TextTransparency=.1,Position=UDim2.fromScale(.5,.27)})
 if LETTERBOX>0 and motion()>=1 then
  tw(u.Top,.5,{Size=UDim2.fromScale(1,LETTERBOX)})
  tw(u.Bottom,.5,{Size=UDim2.fromScale(1,LETTERBOX)})
 end
end

local function hideOverlay()
 if not overlayOn or not ui then return end
 overlayOn=false
 tw(ui.Title,.5,{TextTransparency=1,TextStrokeTransparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 tw(ui.Sub,.5,{TextTransparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 tw(ui.Top,.6,{Size=UDim2.fromScale(1,0)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 tw(ui.Bottom,.6,{Size=UDim2.fromScale(1,0)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
end

local function flash(strength,time)
 if not FLASHES or motion()<1 or strength<=.02 then return end
 local u=ensureUi()
 if not u then return end
 u.Gui.Enabled=true
 u.Flash.BackgroundTransparency=1-math.min(strength,.45)
 tw(u.Flash,time,{BackgroundTransparency=1})
end

local bloom=Instance.new("BloomEffect")
bloom.Name="PolarisBloom"bloom.Enabled=false bloom.Intensity=0 bloom.Size=24 bloom.Threshold=.85 bloom.Parent=Lighting
local skyOrig,skyLast
local function restoreSky(keepBloom)
 if skyOrig then
  for key,value in pairs(skyOrig)do if Lighting[key]==skyLast[key]then Lighting[key]=value end end
 end
 skyOrig,skyLast=nil,nil
 if not keepBloom then bloom.Enabled=false end
end
local function updateSky(g,pulse)
 bloom.Enabled=S.Bloom==true and g>.001
 bloom.Intensity=.3*g+1.4*pulse bloom.Size=22+14*pulse
 if S.Sky and g>.001 then
  skyOrig=skyOrig or{}skyLast=skyLast or{}
  for _,key in ipairs({"Brightness","ExposureCompensation","OutdoorAmbient"})do
   if skyOrig[key]==nil or(skyLast[key]~=nil and Lighting[key]~=skyLast[key])then skyOrig[key]=Lighting[key]end
  end
  skyLast.Brightness=skyOrig.Brightness*(1-(1-S.SkyDim)*g)*(1+.9*pulse)
  skyLast.ExposureCompensation=skyOrig.ExposureCompensation-.6*g+.8*pulse
  skyLast.OutdoorAmbient=skyOrig.OutdoorAmbient:Lerp(Color3.fromRGB(60,78,140),.55*g)
  for key,value in pairs(skyLast)do
   Lighting[key]=value
   skyLast[key]=Lighting[key]
  end
 else restoreSky(true)end
end
local function reset()
 restoreSky()
 for tween in pairs(overlayTweens)do tween:Cancel()end table.clear(overlayTweens)
 if ui then
  ui.Top.Size=UDim2.fromScale(1,0)ui.Bottom.Size=UDim2.fromScale(1,0)
  ui.Flash.BackgroundTransparency=1
  ui.Title.TextTransparency=1 ui.Title.TextStrokeTransparency=1 ui.Sub.TextTransparency=1
  ui.Gui.Enabled=false
 end
 overlayOn=false
 trauma,punch,squeeze=0,0,0
 chargeStart,chargeActor=nil,nil
 gradeStart,gradeActor=nil,nil
 grade.Enabled=false
 local cam=fovCamera or workspace.CurrentCamera
 if cam then
  Fov.Clear(script)
  if lastShake and cam.CFrame==lastCameraFrame then cam.CFrame=cam.CFrame*lastShake:Inverse()end
 end
 baseFov,lastFov,fovCamera,lastShake,lastCameraFrame=nil,nil,nil,nil,nil
end
local function onBeat(actor,value)
 if closed or not Reset.ViewAllowed()or not actor:GetAttribute("PolarisActive")or not CollectionService:HasTag(actor,TAG)then return end
 local kind,_,uid=string.match(value,"^(%a+):(%d+):(%d+)$")
 if not kind then return end
 local f=falloff(actor)
 if kind=="charge"then
  chargeStart=os.clock()
  gradeStart=chargeStart gradeActor=actor
  showOverlay(f)
  chargeFalloff=f
  chargeActor=actor
 elseif kind=="release"then
  chargeStart=nil
  hideOverlay()flash(.45*f,.5)
  trauma=math.max(trauma,.55*f)
  punch=punch+9*f
 elseif kind=="finale"then
  flash(.45*f,.9)
  trauma=math.max(trauma,.7*f)
  punch=punch+12*f
 elseif kind=="hit"then
  if tonumber(uid)==player.UserId then
   trauma=math.max(trauma,.5)
   punch=punch-5  
  else
   trauma=math.max(trauma,.12*f)
  end
 end
end

 
 
local watched=setmetatable({},{__mode="k"})
local function watch(actor)
 if watched[actor]then return end
 watched[actor]=true
 connections[#connections+1]=actor:GetAttributeChangedSignal("PolarisBeat"):Connect(function()
  local v=actor:GetAttribute("PolarisBeat")
  if type(v)=="string"then onBeat(actor,v)end
 end)
  
 local v=actor:GetAttribute("PolarisBeat")
 if type(v)=="string"and string.sub(v,1,7)=="charge:"then onBeat(actor,v)end
end

for _,a in ipairs(CollectionService:GetTagged(TAG))do watch(a)end
connections[#connections+1]=CollectionService:GetInstanceAddedSignal(TAG):Connect(watch)

RunService:BindToRenderStep("PolarisCameraRestore",Enum.RenderPriority.Camera.Value-1,function()
 local cam=fovCamera
 if cam and lastShake and cam.CFrame==lastCameraFrame then cam.CFrame=cam.CFrame*lastShake:Inverse()end
 lastShake,lastCameraFrame=nil,nil
end)
RunService:BindToRenderStep("PolarisCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
 local cam=workspace.CurrentCamera
 if not cam then reset()return end
 if not Reset.ViewAllowed()then reset()return end
 if fovCamera and fovCamera~=cam then reset()end
 fovCamera=cam
 local scale=motion()
 if gradeStart and gradeActor and gradeActor.Parent and CollectionService:HasTag(gradeActor,TAG)then
  local elapsed=os.clock()-gradeStart
  local total=S.Charge+(S.Shots-1)*S.ShotGap+S.ProjectileLife+#S.Burn*S.BurnInterval+S.Recovery
  local g=smooth(elapsed/(S.Rise+S.Charge))*math.clamp((total-elapsed)/1.6,0,1)*falloff(gradeActor)
  local pulse=math.clamp(math.abs(punch)/12,0,1)
  updateSky(g,pulse*scale)
  grade.Enabled=S.Grade==true and g>.001
  grade.Brightness=-.045*g+.14*pulse*scale
  grade.Contrast=.1*g+.18*pulse*scale
  grade.Saturation=.12*g
  grade.TintColor=Color3.new(1,1,1):Lerp(Color3.fromRGB(176,206,255),.38*g)
 else grade.Enabled=false restoreSky()end

  
  
  
 if chargeStart and(os.clock()-chargeStart>CHARGE_TIME+.75
  or not chargeActor or not chargeActor.Parent or not CollectionService:HasTag(chargeActor,TAG))then
  chargeStart=nil
  chargeActor=nil
  hideOverlay()
 end
 local target=0
 if chargeStart then target=-4*smooth((os.clock()-chargeStart)/CHARGE_TIME)*chargeFalloff end
 squeeze=squeeze+(target-squeeze)*(1-math.exp(-dt*6))
 punch=punch*math.exp(-dt*5.5)
 trauma=math.max(0,trauma-dt*1.5)

 if trauma>.001 then
  local amp=trauma*trauma*scale
  local n=os.clock()*26
  local ox=math.noise(n,seed,0)*amp*.45
  local oy=math.noise(n,seed,10)*amp*.45
  local rx=math.noise(n,seed,20)*amp*.035
  local ry=math.noise(n,seed,30)*amp*.035
  local rz=math.noise(n,seed,40)*amp*.05
  lastShake=CFrame.new(ox,oy,0)*CFrame.Angles(rx,ry,rz)
  cam.CFrame=cam.CFrame*lastShake
  lastCameraFrame=cam.CFrame
 end

  
 local add=(squeeze+punch)*scale
 Fov.Set(script,add)

end)

Reset.Register(script,reset,reset)
script.Destroying:Connect(function()
 closed=true
 RunService:UnbindFromRenderStep("PolarisCamera")
 RunService:UnbindFromRenderStep("PolarisCameraRestore")
 for _,connection in ipairs(connections)do connection:Disconnect()end
 reset()grade:Destroy()bloom:Destroy()
 if ui then ui.Gui:Destroy()end
end)
return true
