-- Phase 5 TP bar (shared by the whole server) and the E-key godmode break.
-- Reads workspace.P5TPActive / workspace.P5TP (Combat/TPService). Once a break strips the boss's
-- godmode, TPService turns P5TPActive off and the bar goes away.
-- Layout from the top: soundtrack/timer, hearts, this bar, Health. While the bar is shown the
-- hearts and the soundtrack block are lifted by its height, and put back when it hides.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild("P5TPBreak",30)
local MAX=100
local LIFT=36  -- bar height plus spacing
local WHITE=Color3.new(1,1,1)
local CREAM=Color3.fromRGB(244,239,215)

local gui=Instance.new("ScreenGui")
gui.Name="P5TPHUD"gui.ResetOnSpawn=false gui.DisplayOrder=11 gui.IgnoreGuiInset=true gui.Enabled=false
gui.Parent=player:WaitForChild("PlayerGui")

local root=Instance.new("Frame")
root.Name="TP"root.BackgroundTransparency=1 root.Size=UDim2.fromOffset(300,30)root.Parent=gui
local function label(name,x,anchor,align,text)
 local l=Instance.new("TextLabel")
 l.Name=name l.BackgroundTransparency=1 l.AnchorPoint=Vector2.new(anchor,0)l.Position=UDim2.fromScale(x,0)
 l.Size=UDim2.new(.5,0,0,18)l.Font=Enum.Font.Garamond l.TextSize=19 l.TextColor3=CREAM
 l.TextXAlignment=align l.Text=text l.TextStrokeTransparency=.6 l.Parent=root
 return l
end
local title=label("Title",0,0,Enum.TextXAlignment.Left,"TP")
local value=label("Value",1,1,Enum.TextXAlignment.Right,"0%")
local track=Instance.new("Frame")
track.Name="Track"track.Position=UDim2.fromOffset(0,20)track.Size=UDim2.new(1,0,0,9)
track.BackgroundColor3=Color3.fromRGB(20,27,30)track.BorderSizePixel=0 track.Parent=root
Instance.new("UICorner",track).CornerRadius=UDim.new(0,3)
local fill=Instance.new("Frame")
fill.Name="Fill"fill.Size=UDim2.fromScale(0,1)fill.BackgroundColor3=WHITE fill.BorderSizePixel=0 fill.Parent=track
Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3)
local grad=Instance.new("UIGradient")grad.Color=ColorSequence.new(Color3.fromRGB(200,225,255),WHITE)grad.Parent=fill
local glow=Instance.new("UIStroke")glow.Color=WHITE glow.Thickness=0 glow.Transparency=.2 glow.Parent=track
local hint=Instance.new("TextButton")  -- clickable for touch screens
hint.Name="Break"hint.BackgroundTransparency=1 hint.AnchorPoint=Vector2.new(.5,0)hint.Position=UDim2.fromScale(.5,0)
hint.Size=UDim2.new(.7,0,0,18)hint.Font=Enum.Font.GothamBold hint.TextSize=14 hint.TextColor3=WHITE hint.TextStrokeTransparency=.4
hint.Text="Press Z - Break the godmode"hint.Visible=false hint.Parent=root

local function tp()return workspace:GetAttribute("P5TP")or 0 end
local function active()return workspace:GetAttribute("P5TPActive")==true end
local function canBreak()return active()and tp()>=MAX end

local function fire()
 if canBreak()and remote then remote:FireServer()end
end
hint.Activated:Connect(fire)
 -- Z breaks the godmode (E is Deflect); only sink it when a break is ready
CAS:BindActionAtPriority("P5TPBreak",function(_,state)
 if state~=Enum.UserInputState.Begin or not canBreak()then return Enum.ContextActionResult.Pass end
 fire()
 return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value+50,Enum.KeyCode.Z)

 -- lift/restore a HUD element, remembering its resting position
local lifted={}
local function lift(obj,on)
 if not obj then return end
 local base=lifted[obj]
 if on and not base then
  lifted[obj]=obj.Position
  obj.Position=obj.Position+UDim2.fromOffset(0,-LIFT)
 elseif not on and base then
  if obj.Parent then obj.Position=base end
  lifted[obj]=nil
 end
end
local function stack()
 local pg=player.PlayerGui
 local vit=pg:FindFirstChild("PlayerVitalsHUD")
 local panel=vit and vit:FindFirstChild("Panel")
 local hp=panel and panel:FindFirstChild("Health")
 return vit,hp,hp and hp:FindFirstChild("LivesHearts"),pg:FindFirstChild("EncounterTimerAndMusic",true)
end

 -- Narrator guide: the first time the TP bar appears in an encounter, a short walkthrough of how TP
 -- works. It is the game talking, not the boss: italic serif in its own banner, separate from dialogue.
local Kit=require(game.ReplicatedStorage.BossShared.Presentation.TrialMenuKit)
local GUIDE={
 "Phase 5: his godmode is up. Nothing you land will hurt him yet.",
 "His skills sometimes drop white pearls, and ultimates always drop one to three. Walk near a pearl to take it.",
 "Every pearl fills the TP bar for the whole server. At 100%, anyone can press Z to shatter his godmode for good.",
 "One more thing: Deflect. When a gold shield appears on you, press E as the hit comes to turn it away.",
 "If the shield says HOLD, keep E held down for half a second instead. Mistimed presses do nothing.",
}
local LINE_TIME=4.6
local banner=Instance.new("Frame")
banner.Name="Guide"banner.AnchorPoint=Vector2.new(.5,0)banner.Position=UDim2.new(.5,0,.24,0)
banner.Size=UDim2.fromOffset(640,74)banner.BackgroundColor3=Color3.fromRGB(14,12,9)banner.BackgroundTransparency=1
banner.BorderSizePixel=0 banner.Visible=false banner.Parent=gui
local bannerGrad=Instance.new("UIGradient")
bannerGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.25),NumberSequenceKeypoint.new(.8,.25),NumberSequenceKeypoint.new(1,1)})
bannerGrad.Parent=banner
local rules={}
for _,y in ipairs({0,1})do
 local rule=Instance.new("Frame")
 rule.AnchorPoint=Vector2.new(.5,y)rule.Position=UDim2.fromScale(.5,y)rule.Size=UDim2.new(.8,0,0,1)
 rule.BackgroundColor3=Kit.Colors.Gold rule.BorderSizePixel=0 rule.BackgroundTransparency=1 rule.Parent=banner
 local g=Instance.new("UIGradient")
 g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})
 g.Parent=rule
 rules[#rules+1]=rule
end
local tag=Kit.Text(banner,{Text=Kit.Spaced("Guide"),FontFace=Kit.Fonts.Caps,TextSize=11,TextColor3=Kit.Colors.GoldDim,
 TextXAlignment=Enum.TextXAlignment.Center,Position=UDim2.fromOffset(0,8),Size=UDim2.new(1,0,0,14),TextTransparency=1})
local line=Kit.Text(banner,{Text="",FontFace=Kit.Fonts.Italic,TextSize=19,TextColor3=Kit.Colors.Ivory,TextStrokeTransparency=.7,
 TextXAlignment=Enum.TextXAlignment.Center,Position=UDim2.fromOffset(20,26),Size=UDim2.new(1,-40,0,44),TextTransparency=1})
local Tween=game:GetService("TweenService")
local function fadeGuide(alpha,time)
 local info=TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 Tween:Create(banner,info,{BackgroundTransparency=alpha<1 and .05 or 1}):Play()
 Tween:Create(tag,info,{TextTransparency=alpha}):Play()
 Tween:Create(line,info,{TextTransparency=alpha}):Play()
 for _,r in ipairs(rules)do Tween:Create(r,info,{BackgroundTransparency=alpha<1 and .35 or 1}):Play()end
end
local guided,guideRun=false,0
local function playGuide()
 guideRun+=1
 local run=guideRun
 banner.Visible=true
 for index,text in ipairs(GUIDE)do
  if run~=guideRun or not active()then break end
  line.Text=text
  fadeGuide(0,.35)
  task.wait(LINE_TIME)
  if run~=guideRun then return end
  fadeGuide(1,.3)
  task.wait(index<#GUIDE and .35 or .3)
 end
 if run==guideRun then banner.Visible=false end
end
 -- once per encounter: a new attempt shows it again
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
 if workspace:GetAttribute("EncounterStarted")~=true then guided=false guideRun+=1 banner.Visible=false end
end)
 -- the guide waits for the boss's entrance and any phase transition to finish, then a beat more
local function settled()
 local boss=workspace:FindFirstChild("alterGolden, the Nothing")
 return workspace:GetServerTimeNow()>=(workspace:GetAttribute("BossEntranceEndsAt")or 0)
  and not(boss and boss:GetAttribute("PhaseTransitionInProgress"))
end
workspace:GetAttributeChangedSignal("P5TPActive"):Connect(function()
 if active()and not guided then
  guided=true
  local run=guideRun
  task.spawn(function()
   local calm=0
   while run==guideRun and active()and calm<1.2 do
    calm=settled()and calm+.2 or 0
    task.wait(.2)
   end
   if run==guideRun and active()then playGuide()end
  end)
 end
end)

local shown=0
Run.RenderStepped:Connect(function(dt)
 local on=active()
 local vit,hp,hearts,music=stack()
 for obj in pairs(lifted)do if obj~=hearts and obj~=music then lifted[obj]=nil end end  -- respawned HUD
 lift(hearts,on)
 lift(music,on)
 gui.Enabled=on and hp~=nil
 if not gui.Enabled then return end
  -- the two ScreenGuis can use different insets, so measure this gui's own origin instead
  -- of guessing it, then place the bar just above the Health frame
 local origin=root.AbsolutePosition-Vector2.new(root.Position.X.Offset,root.Position.Y.Offset)
 root.Position=UDim2.fromOffset(hp.AbsolutePosition.X-origin.X,hp.AbsolutePosition.Y-LIFT+2-origin.Y)
 root.Size=UDim2.fromOffset(hp.AbsoluteSize.X,30)
 local v=tp()
 shown+=(v-shown)*(1-math.exp(-dt*8))
 fill.Size=UDim2.fromScale(math.clamp(shown/MAX,0,1),1)
 value.Text=string.format("%d%%",math.floor(v+.5))
 local ready=canBreak()
 hint.Visible=ready
 local pulse=.5+.5*math.sin(os.clock()*6)
 glow.Thickness=ready and 1+2*pulse or 0
 hint.TextTransparency=ready and .15*pulse or 1
 title.TextColor3=ready and WHITE or CREAM
end)
