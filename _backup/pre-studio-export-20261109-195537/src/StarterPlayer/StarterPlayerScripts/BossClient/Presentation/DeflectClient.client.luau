-- Deflect (E). Presses and releases go to the server (Combat/DeflectService), which judges each deflectable
-- hit. When one is coming, a gold shield cue appears over your avatar: "E" means tap, "HOLD E" means keep E
-- down for half a second (the bar fills while you hold). Pulling one off flashes a gold shield on that player.
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer
local input=game.ReplicatedStorage:WaitForChild("DeflectInput",60)
local cue=game.ReplicatedStorage:WaitForChild("DeflectCue",60)
local Icons=require(game.ReplicatedStorage:WaitForChild("BossShared").Presentation.StatusIcons)
local E=require(game.ReplicatedStorage:WaitForChild("VFXEngine"))
local GOLD=Color3.fromRGB(255,214,80)
local SHINE=Color3.fromRGB(255,246,214)
local HOLD_TIME=.5
local holding,downAt=false,0

local function inFight()return workspace:GetAttribute("EncounterStarted")==true end

 -- the cue over your avatar
local gui=Instance.new("BillboardGui")
gui.Name="DeflectCue" gui.Size=UDim2.fromOffset(90,100) gui.StudsOffset=Vector3.new(0,3.8,0)
gui.AlwaysOnTop=true gui.LightInfluence=0 gui.Enabled=false gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local holder=Instance.new("Frame")
holder.BackgroundTransparency=1 holder.Size=UDim2.fromScale(1,1) holder.Parent=gui
local scale=Instance.new("UIScale") scale.Parent=holder
local icon=Icons.Create(holder,"ClassBlocking",UDim2.fromOffset(64,64),UDim2.fromOffset(13,0),GOLD)
local label=Instance.new("TextLabel")
label.BackgroundTransparency=1 label.Position=UDim2.fromOffset(0,62) label.Size=UDim2.new(1,0,0,22)
label.Font=Enum.Font.GothamBlack label.TextSize=18 label.TextColor3=SHINE label.TextStrokeTransparency=.3
label.Text="E" label.Parent=holder
local track=Instance.new("Frame")
track.BackgroundColor3=Color3.fromRGB(30,24,10) track.BorderSizePixel=0 track.Position=UDim2.fromOffset(15,86)
track.Size=UDim2.fromOffset(60,6) track.Visible=false track.Parent=holder
local fill=Instance.new("Frame")
fill.BackgroundColor3=GOLD fill.BorderSizePixel=0 fill.Size=UDim2.fromScale(0,1) fill.Parent=track
local showUntil,kind=0,"Tap"

local function avatar()
 local char=player.Character
 return char and(char:FindFirstChild("Head")or char:FindFirstChild("HumanoidRootPart"))
end
local function show(k,seconds)
 local at=avatar()
 if not at then return end
 kind=k
 gui.Adornee=at
 label.Text=k=="Hold"and"HOLD E"or"E"
 track.Visible=k=="Hold"
 showUntil=os.clock()+math.max(seconds or .5,.25)
 if not gui.Enabled then
  gui.Enabled=true
  scale.Scale=1.5
  Tween:Create(scale,TweenInfo.new(.15,Enum.EasingStyle.Back),{Scale=1}):Play()
 end
end

Run.RenderStepped:Connect(function()
 if not gui.Enabled then return end
 if os.clock()>showUntil then gui.Enabled=false return end
 local pulse=.5+.5*math.sin(os.clock()*18)
 label.TextTransparency=.2*pulse
 fill.Size=UDim2.fromScale(holding and math.clamp((os.clock()-downAt)/HOLD_TIME,0,1)or 0,1)
end)

 -- E: down and up go to the server while a fight is on; otherwise E is left to prompts and the rest
local function onAction(_,state)
 if not inFight()then return Enum.ContextActionResult.Pass end
 if state==Enum.UserInputState.Begin then
  holding=true downAt=os.clock()
  input:FireServer("Down")
  return Enum.ContextActionResult.Sink
 elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then
  if holding then holding=false input:FireServer("Up")end
  return Enum.ContextActionResult.Sink
 end
 return Enum.ContextActionResult.Pass
end
local bound=false
local function sync()
 if inFight()and not bound then
  bound=true
  CAS:BindActionAtPriority("BossDeflect",onAction,true,Enum.ContextActionPriority.High.Value+40,Enum.KeyCode.E,Enum.KeyCode.ButtonL1)
  CAS:SetTitle("BossDeflect","Deflect")
 elseif not inFight()and bound then
  bound=false
  CAS:UnbindAction("BossDeflect")
  if holding then holding=false input:FireServer("Up")end
 end
end
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(sync)
sync()

 -- a deflect: a gold shield flares on that player, sparks fly off it
local function deflected(d)
 local char=d.Char
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local pos=root and root.Position or d.Pos
 if not pos then return end
 local g=E.Group("Deflect")
 local a=E.Anchor(g,CFrame.new(pos))
 E.Sprite(a,{tex="flare.burst",size={{0,3},{.3,11},{1,13}},alpha={{0,0},{1,1}},color=GOLD},.3)
 E.Sprite(a,{tex="star.glare",size={{0,2},{.3,14},{1,6}},alpha={{0,0},{1,1}},color=SHINE,rot={20,20}},.25)
 E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.5},speed={24,46},spread=180,drag=2.5},22)
 E.Light(g,a,GOLD,18,6,.3)
 E.After(g,1,function()g:Destroy()end)
 if char==player.Character then
  show(d.Kind,.45)
  label.Text="DEFLECT!"
  track.Visible=false
  scale.Scale=1.6
  Tween:Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Back),{Scale=1}):Play()
 end
end

cue.OnClientEvent:Connect(function(kind,d)
 if kind=="Warn"then show(d.Kind,d.Time)
 elseif kind=="Deflected"then deflected(d)end
end)
