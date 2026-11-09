if not game:GetService("RunService"):IsRunning() or not game:GetService("RunService"):IsClient() then return {} end
if not game:GetService("RunService"):IsClient() then return {} end
 
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")

local remote=ReplicatedStorage:WaitForChild("P35MysteriousGuyFX")
local player=Players.LocalPlayer

local gui=Instance.new("ScreenGui")
gui.Name="MysteriousGuyCinema" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=40
gui.Parent=player:WaitForChild("PlayerGui")

local function makeBar(anchorY)
 local f=Instance.new("Frame")
 f.AnchorPoint=Vector2.new(0,anchorY) f.Position=UDim2.fromScale(0,anchorY) f.Size=UDim2.fromScale(1,0)
 f.BackgroundColor3=Color3.new(0,0,0) f.BorderSizePixel=0 f.Parent=gui
 return f
end
local top,bottom=makeBar(0),makeBar(1)
local BAR=.075

local QUAD,QUINT,SINE=Enum.EasingStyle.Quad,Enum.EasingStyle.Quint,Enum.EasingStyle.Sine
local OUT,IN=Enum.EasingDirection.Out,Enum.EasingDirection.In
local tweens={}
local function tw(obj,time,props,style,dir)
 local tween=TweenService:Create(obj,TweenInfo.new(time,style or QUAD,dir or OUT),props)
 tweens[tween]=true
 tween.Completed:Connect(function()tweens[tween]=nil end)
 tween:Play()
end

local token=0
local destroyed=false
local baseFov,grade,blur

local function bars(open)
 local size=UDim2.fromScale(1,open and BAR or 0)
 tw(top,.3,{Size=size},QUINT)
 tw(bottom,.3,{Size=size},QUINT)
end

local function finish(my)
 if my~=token then return end
 bars(false)
 local cam=workspace.CurrentCamera
 if cam and baseFov then tw(cam,.45,{FieldOfView=baseFov})end
 if grade then tw(grade,.45,{Saturation=0,Contrast=0,Brightness=0,TintColor=Color3.new(1,1,1)})end
 if blur then tw(blur,.45,{Size=0})end
 task.delay(.6,function()
  if my~=token then return end
  if grade then grade:Destroy() grade=nil end
  if blur then blur:Destroy() blur=nil end
  baseFov=nil
 end)
end

local connection=remote.OnClientEvent:Connect(function(kind,arg)
 local cam=workspace.CurrentCamera
 if kind=="Seize" then
  if not cam then return end
  token+=1
  local my=token
  local charge=tonumber(arg) or 1.2
  baseFov=baseFov or cam.FieldOfView
  if not grade then
   grade=Instance.new("ColorCorrectionEffect")
   grade.Name="MysteriousGuyGrade"
   grade.Parent=Lighting
  end
  if not blur then
   blur=Instance.new("BlurEffect")
   blur.Name="MysteriousGuyBlur"
   blur.Size=0
   blur.Parent=Lighting
  end
  bars(true)
  tw(cam,.22,{FieldOfView=baseFov-12},QUINT)                     
  tw(grade,.35,{Saturation=-.55,Contrast=.18,TintColor=Color3.fromRGB(205,185,255)})
  task.delay(.25,function()                                       
   if my==token and cam then tw(cam,math.max(charge-.25,.2),{FieldOfView=baseFov-22},SINE,IN)end
  end)
  task.delay(charge+1.5,function()finish(my)end)                  
 elseif kind=="Punch" then
  if not cam or not baseFov then return end
  local my=token
  tw(cam,.06,{FieldOfView=baseFov+9},QUAD,OUT)                    
  if blur then blur.Size=16 tw(blur,.4,{Size=0})end
  if grade then grade.Brightness=.2 tw(grade,.3,{Brightness=0})end
  task.delay(.1,function()finish(my)end)
 elseif kind=="Release" then
  finish(token)
 end
end)

local function clear()
 if destroyed then return end
 token+=1
 for tween in pairs(tweens)do tween:Cancel()end table.clear(tweens)
 local cam=workspace.CurrentCamera
 if cam and baseFov then cam.FieldOfView=baseFov end
 baseFov=nil
 if grade then grade:Destroy()grade=nil end
 if blur then blur:Destroy()blur=nil end
 top.Size=UDim2.fromScale(1,0)bottom.Size=UDim2.fromScale(1,0)
end
local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)
Reset.Register(script,clear)
local C={}
function C.Clear()clear()end
function C.Destroy()if destroyed then return end connection:Disconnect()clear()destroyed=true gui:Destroy()end
script.Destroying:Connect(C.Destroy)
return table.freeze(C)
