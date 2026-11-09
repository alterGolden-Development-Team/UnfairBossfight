--[[
 TPBreak (client effect) - a full TP bar released: a white shockwave rolls out from the
 player who pressed E, a lance of light strikes the boss and its divinity shatters.
 While GodBrokenUntil is in the future the boss carries cracked white light.
]]
local Players=game:GetService("Players")
local T={}
local WHITE=Color3.new(1,1,1)
local PALE=Color3.fromRGB(215,230,255)
local GOLD=Color3.fromRGB(255,228,136)

local function flash(strength,time)
 local pg=Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
 if not pg then return end
 local gui=Instance.new("ScreenGui")gui.Name="TPBreakFlash"gui.IgnoreGuiInset=true gui.DisplayOrder=26
 local f=Instance.new("Frame")f.Size=UDim2.fromScale(1,1)f.BorderSizePixel=0 f.BackgroundColor3=WHITE f.BackgroundTransparency=1-strength f.Parent=gui
 gui.Parent=pg
 game:GetService("TweenService"):Create(f,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
 game:GetService("Debris"):AddItem(gui,time+.1)
end

function T.Shockwave(E,d)
 local g=E.Group("TPBreak")
 local gp=E.Ground(d.Pos)or d.Pos-Vector3.new(0,3,0)
 local ga=E.Anchor(g,CFrame.new(gp+Vector3.new(0,.5,0)))
 local a=E.Anchor(g,CFrame.new(d.Pos))
 flash(.55,.6)
 E.Sprite(a,{tex="flare.big",size={{0,10},{.15,90},{1,110}},alpha={{0,0},{.35,.2},{1,1}},color=WHITE},.6)
 E.Sprite(a,{tex="ring.crisp",size={{0,6},{1,160}},alpha={{0,0},{.6,.2},{1,1}},color=WHITE,rot={0,0}},.5)
 for k=0,2 do
  E.After(g,k*.12,function()
   E.Sprite(ga,{tex="ring.thick",orient="flat",size={{0,10},{1,320+60*k}},alpha={{0,0},{1,1}},color=k==1 and PALE or WHITE},1+.2*k)
  end)
 end
 E.Emit(ga,{tex="dot",orient="velocity",squash={{0,3},{1,0}},size={{0,1.4},{1,0}},alpha={{0,0},{.7,0},{1,1}},
  color={{0,WHITE},{1,PALE}},life={.5,.9},speed={90,170},spread=85,dir=Enum.NormalId.Top,drag=2},90)
 E.Light(g,a,WHITE,120,14,.8)
  -- lance to the boss and the shatter
 local boss=d.Boss
 if boss and boss.Parent then
  local b=E.Anchor(g,boss.CFrame)
  local a0,a1=E.Attach(a),E.Attach(b)
  local lance=E.Beam(g,a0,a1,{tex="beam.core",width=6,length=1,mode=Enum.TextureMode.Stretch,color={{0,WHITE},{1,GOLD}},brightness=5,segments=2})
  local halo=E.Beam(g,a0,a1,{tex="beam.stars",width=16,length=20,scroll=-60,color=PALE,alpha={{0,.2},{1,.4}},brightness=2,segments=2,z=-.1})
  E.Tween(lance,.45,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
  E.Tween(halo,.55,{Width0=0,Width1=0},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
  E.Sprite(b,{tex="burst.spiky2",size={{0,6},{1,60}},alpha={{0,0},{.5,.1},{1,1}},color=WHITE,rot={0,360}},.5)
  E.Sprite(b,{tex="flare.burst2",size={{0,8},{.25,40},{1,46}},alpha={{0,0},{.4,.2},{1,1}},color=GOLD},.45)
  E.Emit(b,{tex="star.crisp",size={{0,2.2},{1,0}},alpha={{0,0},{.7,0},{1,1}},color={{0,WHITE},{1,GOLD}},
   life={.8,1.4},speed={40,90},spread=180,drag=1.4,accel=Vector3.new(0,-50,0),spin={-400,400}},40)
   -- cracked divinity: flickering white light on the boss while the break lasts
  local left=math.max((d.Until or 0)-E.Net.Now(),0)
  if left>0 then
   local aura=E.Stream(boss,{tex="star.twinkle",size={{0,1.4},{1,0}},life={.5,.9},speed={2,8},spread=180,color={{0,WHITE},{1,GOLD}},locked=false},26)
   local ring=E.Sprite(boss,{tex="ring.crisp",size=12,alpha=.45,color=WHITE,spin={-90,-90}},left)
   task.delay(left,function()if aura.Parent then aura:Destroy()end end)
  end
 end
 E.After(g,2,function()g:Destroy()end)
end

return T
