-- Deflect (E). Presses and releases go to the server (Combat/DeflectService), which judges each deflectable
-- hit. When one is coming, a white shield reading DEFLECT appears on your avatar with how under it: TAP E (press E
-- while it is up) or HOLD E (keep E down for EncounterConfig.DeflectHoldTime, 0.2s; the shield fills while you hold).
-- A ring closes on the shield as the hit comes in. Every press flicks the shield up so you can see it went in.
-- Pulling one off flashes a gold shield on that player with a clang, sparks and a ring; your own screen flashes
-- and the camera kicks. Mashing E with nothing coming locks deflect for a moment (a grey TOO EARLY shield).
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local input=game.ReplicatedStorage:WaitForChild("DeflectInput",60)
local cue=game.ReplicatedStorage:WaitForChild("DeflectCue",60)
local Icons=require(game.ReplicatedStorage:WaitForChild("BossShared").Presentation.StatusIcons)
local E=require(game.ReplicatedStorage:WaitForChild("VFXEngine"))
local WHITE=Color3.new(1,1,1)
local INK=Color3.fromRGB(30,30,38)
local GOLD=Color3.fromRGB(255,206,84)
local GREY=Color3.fromRGB(120,124,132)
local HOLD_TIME=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig).DeflectHoldTime or .2
local holding,downAt=false,0

local function inFight()return workspace:GetAttribute("EncounterStarted")==true end

local gui=Instance.new("BillboardGui")
gui.Name="DeflectCue" gui.Size=UDim2.fromOffset(130,140) gui.StudsOffset=Vector3.new(0,.6,0)
gui.AlwaysOnTop=true gui.LightInfluence=0 gui.Enabled=false gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local holder=Instance.new("Frame")
holder.BackgroundTransparency=1 holder.Size=UDim2.fromOffset(130,140) holder.Parent=gui
local scale=Instance.new("UIScale") scale.Parent=holder
 -- a white shield on the avatar's chest reading DEFLECT; for a hold, it fills from the bottom while E is down
local rim=Icons.Create(holder,"ClassBlocking",UDim2.fromOffset(100,100),UDim2.fromOffset(15,2),Color3.fromRGB(70,80,96))
local icon=Icons.Create(holder,"ClassBlocking",UDim2.fromOffset(86,86),UDim2.fromOffset(22,9),WHITE)
local track=Instance.new("Frame")
track.BackgroundTransparency=1 track.ClipsDescendants=true track.AnchorPoint=Vector2.new(0,1)
track.Position=UDim2.fromOffset(22,95) track.Size=UDim2.fromOffset(86,0) track.Visible=false track.ZIndex=2 track.Parent=holder
local fill=Icons.Create(track,"ClassBlocking",UDim2.fromOffset(86,86),UDim2.new(0,0,1,-86),Color3.fromRGB(150,225,255))
fill.ZIndex=2
 -- the ring that closes on the shield as the hit comes in
local ring=Instance.new("Frame")
ring.AnchorPoint=Vector2.new(.5,.5) ring.Position=UDim2.fromOffset(65,52) ring.BackgroundTransparency=1 ring.ZIndex=1 ring.Parent=holder
Instance.new("UICorner",ring).CornerRadius=UDim.new(.5,0)
local ringStroke=Instance.new("UIStroke") ringStroke.Color=WHITE ringStroke.Thickness=3 ringStroke.Parent=ring
local label=Instance.new("TextLabel")
label.BackgroundTransparency=1 label.Position=UDim2.fromOffset(26,38) label.Size=UDim2.fromOffset(78,24) label.ZIndex=3
label.Font=Enum.Font.GothamBlack label.TextScaled=true label.TextColor3=INK label.TextStrokeTransparency=1
label.Text="DEFLECT" label.Parent=holder
local tag=Instance.new("TextLabel")
tag.BackgroundTransparency=1 tag.Position=UDim2.fromOffset(0,100) tag.Size=UDim2.fromOffset(130,24) tag.ZIndex=3
tag.Font=Enum.Font.GothamBlack tag.TextSize=19 tag.TextColor3=WHITE tag.TextStrokeColor3=INK tag.TextStrokeTransparency=.15
tag.Text="" tag.Parent=holder
local showUntil,kind,warnFrom,warnTo,mode=0,"Tap",0,0,"Warn"
 -- the icons are drawn from frames and strokes: recolour and fade them piece by piece
local function pieces(root)
 local list={}
 for _,o in ipairs(root:GetDescendants())do
  if o:IsA("ImageLabel")then list[#list+1]={o,"Image",o.ImageTransparency}
  elseif o:IsA("UIStroke")then list[#list+1]={o,"Stroke",o.Transparency}
  elseif o:IsA("GuiObject")and o.BackgroundTransparency<1 then list[#list+1]={o,"Back",o.BackgroundTransparency}end
 end
 return list
end
local iconParts,rimParts=pieces(icon),pieces(rim)
local function tint(list,color)
 for _,p in ipairs(list)do
  if p[2]=="Image"then p[1].ImageColor3=color elseif p[2]=="Stroke"then p[1].Color=color else p[1].BackgroundColor3=color end
 end
end
local function fade(list,a)
 for _,p in ipairs(list)do
  local v=p[3]+(1-p[3])*a
  if p[2]=="Image"then p[1].ImageTransparency=v elseif p[2]=="Stroke"then p[1].Transparency=v else p[1].BackgroundTransparency=v end
 end
end

local function avatar()
 local char=player.Character
 return char and(char:FindFirstChild("UpperTorso")or char:FindFirstChild("Torso")or char:FindFirstChild("HumanoidRootPart"))
end
local function paint(color,text,word)
 tint(iconParts,color)
 label.Text=word or "DEFLECT"
 tag.Text=text
end
local function pop(size,time)
 scale.Scale=size
 Tween:Create(scale,TweenInfo.new(time or .15,Enum.EasingStyle.Back),{Scale=1}):Play()
end
 -- every warning still coming: with two deflects overlapping, the shield shows the one that lands first
local pending={}
local function showKind(k)
 kind=k
 paint(WHITE,k=="Hold"and"HOLD E"or"TAP E")
 track.Visible=k=="Hold"
end
local function show(k,seconds)
 local at=avatar()
 if not at then return end
 pending[#pending+1]={Kind=k,To=os.clock()+math.max(seconds or .5,.2)}
 mode="Warn"
 gui.Adornee=at
 paint(WHITE,k=="Hold"and"HOLD E"or"TAP E")
 track.Visible=k=="Hold"
 warnFrom=os.clock() warnTo=warnFrom+math.max(seconds or .5,.2)
 ring.Visible=false
 showUntil=math.max(showUntil,warnTo+.12)
 if not gui.Enabled then
  gui.Enabled=true
  pop(1.5)
 end
end
 -- a press with nothing coming: the shield flicks up, faint, so you can see the press went in
local function flick()
 if gui.Enabled and mode~="Flick" then return end
 local at=avatar()
 if not at then return end
 mode="Flick"
 gui.Adornee=at
 paint(WHITE,"")
 track.Visible=false ring.Visible=false
 showUntil=os.clock()+.22
 gui.Enabled=true
 pop(1.2,.12)
end

Run.RenderStepped:Connect(function()
 if not gui.Enabled then return end
 local t=os.clock()
 if t>showUntil then gui.Enabled=false mode="Warn" return end
 if mode=="Flick" then
  local k=1-(showUntil-t)/.22
  fade(iconParts,.35+.6*k) fade(rimParts,.5+.5*k) label.TextTransparency=.4+.6*k
  return
 end
 fade(iconParts,0) fade(rimParts,0)
 if mode=="Warn" then
  local soonest
  for i=#pending,1,-1 do
   local w=pending[i]
   if t>w.To+.1 then table.remove(pending,i)
   elseif not soonest or w.To<soonest.To then soonest=w end
  end
  if soonest and soonest.Kind~=kind then showKind(soonest.Kind) end
 end
 local pulse=.5+.5*math.sin(t*18)
 label.TextTransparency=mode=="Warn"and .15*pulse or 0
 if ring.Visible then
  local k=math.clamp((t-warnFrom)/math.max(warnTo-warnFrom,.05),0,1)
  local d=86+120*(1-k)
  ring.Size=UDim2.fromOffset(d,d)
  ringStroke.Transparency=.75-.6*k
  ringStroke.Color=k>.7 and GOLD or WHITE
  if t>warnTo then ring.Visible=false end
 end
 track.Size=UDim2.fromOffset(86,86*(holding and mode=="Warn" and math.clamp((t-downAt)/HOLD_TIME,0,1)or 0))
end)

 -- E: down and up go to the server while a fight is on; otherwise E is left to prompts and the rest
local function onAction(_,state)
 if not inFight()then return Enum.ContextActionResult.Pass end
 if state==Enum.UserInputState.Begin then
  holding=true downAt=os.clock()
  input:FireServer("Down")  -- (holding E at the Phase 5 finale's sword claims it: Combat/P5Finale listens too)
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

 -- your own deflect: the screen flashes gold-white and the camera kicks in
local function kick(strong)
 local cc=Instance.new("ColorCorrectionEffect")
 cc.Brightness=strong and .32 or .18 cc.Contrast=.25 cc.Saturation=-.2 cc.TintColor=Color3.fromRGB(255,244,214) cc.Parent=Lighting
 Tween:Create(cc,TweenInfo.new(.28,Enum.EasingStyle.Quad),{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE}):Play()
 task.delay(.3,function()cc:Destroy()end)
 local cam=workspace.CurrentCamera
 if cam and cam.CameraType~=Enum.CameraType.Scriptable then
  local fov=cam.FieldOfView
  cam.FieldOfView=fov-(strong and 7 or 4)
  Tween:Create(cam,TweenInfo.new(.3,Enum.EasingStyle.Back),{FieldOfView=fov}):Play()
 end
end

 -- a deflect: a gold shield flares on that player, a ring of light bursts out of it and sparks fly off
local function deflected(d)
 local char=d.Char
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local pos=root and root.Position or d.Pos
 if not pos then return end
 local strong=not d.Chained
 local g=E.Group("Deflect")
 local a=E.Anchor(g,CFrame.new(pos+Vector3.new(0,.8,0)))
 E.Sprite(a,{tex="flare.burst",size={{0,4},{.25,18},{1,22}},alpha={{0,0},{1,1}},color=WHITE},.32)
 E.Sprite(a,{tex="star.glare",size={{0,3},{.25,24},{1,8}},alpha={{0,0},{1,1}},color=GOLD,rot={20,20}},.3)
 E.Sprite(a,{tex="glow.soft",size={{0,6},{1,16}},alpha={{0,.2},{1,1}},color=GOLD},.4)
 E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{.5,GOLD},{1,Color3.fromRGB(255,150,60)}},life={.3,.6},speed={34,70},spread=180,drag=3},strong and 40 or 18)
 E.Emit(a,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,WHITE},{1,GOLD}},life={.4,.8},speed={10,26},spread=180,drag=2,accel=Vector3.new(0,-30,0)},strong and 30 or 12)
  -- the ring: a flat disc of light racing out at chest height
 local ringPart=Instance.new("Part")
 ringPart.Anchored=true ringPart.CanCollide=false ringPart.CanQuery=false ringPart.CanTouch=false ringPart.CastShadow=false
 ringPart.Shape=Enum.PartType.Cylinder ringPart.Material=Enum.Material.Neon ringPart.Color=GOLD ringPart.Transparency=.2
 ringPart.Size=Vector3.new(.15,3,3) ringPart.CFrame=CFrame.new(pos+Vector3.new(0,.8,0))*CFrame.Angles(0,0,math.pi/2)
 ringPart.Parent=g.Folder
 Tween:Create(ringPart,TweenInfo.new(.35,Enum.EasingStyle.Quint),{Size=Vector3.new(.08,strong and 26 or 16,strong and 26 or 16),Transparency=1}):Play()
 E.Light(g,a,GOLD,26,9,.35)
 E.After(g,1.1,function()g:Destroy()end)
 if char==player.Character then
  mode="Hit"
  gui.Adornee=avatar()
  paint(GOLD,"DEFLECTED!")
  track.Visible=false ring.Visible=false
  showUntil=os.clock()+.55
  gui.Enabled=true
  pop(strong and 1.8 or 1.4,.22)
  kick(strong)
 end
end

 -- mashed: deflect is locked for a moment
local function locked(d)
 local at=avatar()
 if not at then return end
 mode="Locked"
 gui.Adornee=at
 paint(GREY,"TOO EARLY","LOCKED")
 track.Visible=false ring.Visible=false
 showUntil=os.clock()+(d.Time or .6)
 gui.Enabled=true
 pop(1.25,.12)
end

cue.OnClientEvent:Connect(function(kind,d)
 if kind=="Warn"then show(d.Kind,d.Time)
 elseif kind=="Deflected"then deflected(d)
 elseif kind=="Locked"then locked(d)end
end)
