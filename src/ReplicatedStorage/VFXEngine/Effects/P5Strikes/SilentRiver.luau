-- P5Strikes cues: Golden Eternity's frozen blades, Overclock, the big warning fields, Silent Cut and Scarlet River.
-- Registers its P.<Name>(E, d) functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local P, AMBER, BUTTERFLY_GOLD, CRIMSON, GOLD, Players, SHINE, UP, WHITE = Core.P, Core.AMBER, Core.BUTTERFLY_GOLD, Core.CRIMSON, Core.GOLD, Core.Players, Core.SHINE, Core.UP, Core.WHITE
local handCF, handOf, newPart, place, rootOf, slash = Core.handCF, Core.handOf, Core.newPart, Core.place, Core.rootOf, Core.slash

 -- Golden Eternity: a great gold clock opens overhead, its hands racing, while light gathers in his raised hand
function P.EternityTell(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .8
 local g=E.Group("P5EternityTell")
 local sky=E.Anchor(g,CFrame.new(r.Position+UP*38))
 E.Sprite(sky,{tex="ring.ticked",orient="flat",size={{0,10},{.5,70},{1,74}},alpha={{0,.8},{.4,.1},{1,0}},color=GOLD,spin={50,50}},T+3.6)
 E.Sprite(sky,{tex="ring.compass",orient="flat",size={{0,8},{.5,56},{1,58}},alpha={{0,.8},{.4,.15},{1,.1}},color=SHINE,spin={-90,-90}},T+3.6)
 E.Sprite(sky,{tex="sigil.mandala2",orient="flat",size={{0,6},{.5,40},{1,42}},alpha={{0,.8},{.4,.3},{1,.2}},color=GOLD,spin={160,160}},T+3.6)
 E.Sprite(sky,{tex="glow.soft",size={{0,10},{.5,80},{1,70}},alpha={{0,.7},{.5,.55},{1,1}},color=BUTTERFLY_GOLD},T+3.6)
 local hand=handOf(d.Boss,"Right")or r
 local a=E.Anchor(g,handCF(hand))
 E.Sprite(a,{tex="star.lens",size={{0,1},{.9,9},{1,3}},alpha={{0,.4},{.9,0},{1,1}},color=SHINE,spin={200,200}},T)
 E.Stream(a,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.25,.35},speed={-14,-8},spread=180},60)
 E.Light(g,sky,GOLD,80,4,T+3.6)
 E.Step(g,function(_,t)
  if hand.Parent then a.CFrame=handCF(hand)end
  return t<T
 end)
 E.After(g,T+3.8,function()g:Destroy()end)
end

 -- Golden Eternity: blades hung in stopped time - a sphere of gold blades around a player, every point aimed at them,
 -- with the air cut around them; they wait for BladesRelease
local frozen={}
function P.FrozenBlades(E,d)
 local g=E.Group("P5FrozenBlades")
 local rng=Random.new(d.Seed or 1)
 local n=d.Count or 10
 local R=d.Radius or 9
 local c=d.Pos
 local blades={}
 for i=1,n do
  local y=1-2*(i-.5)/n
  local rad=math.sqrt(math.max(1-y*y,0))
  local th=i*2.39996+rng:NextNumber(0,.3)
  local dirOut=Vector3.new(math.cos(th)*rad,y*.55+.25,math.sin(th)*rad).Unit
  local at=c+dirOut*R
  local blade=newPart(g,Vector3.new(.25,.9,5.5),SHINE,0)
  local glow=newPart(g,Vector3.new(.9,2.2,6.5),BUTTERFLY_GOLD,.55)
  local cf=CFrame.lookAt(at,c)
  blade.CFrame=cf glow.CFrame=cf
  blades[i]={Blade=blade,Glow=glow,From=at}
 end
 local a=E.Anchor(g,CFrame.new(c))
 E.Sprite(a,{tex="ring.ticked",orient="flat",size={{0,2},{.1,R*2.2},{1,R*2.2}},alpha={{0,.5},{.1,.2},{1,.3}},color=GOLD,spin={0,0}},6)
 local cut=slash(g,R*1.6,WHITE,GOLD,{GlowAlpha=.35})
 local parts,cfs={},{}
 place(cut,CFrame.new(c+UP*1.5)*CFrame.Angles(0,rng:NextNumber(0,6.28),0)*CFrame.Angles(-math.pi/2,0,rng:NextNumber(-.5,.5)),1,0,parts,cfs)
 workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
 frozen[#frozen+1]={G=g,Blades=blades,Center=c}
 E.After(g,8,function()g:Destroy()end)
end

 -- Golden Eternity: time resumes - every hung blade drives into its centre at once, and each centre bursts
function P.BladesRelease(E,d)
 local list=frozen
 frozen={}
 for _,set in ipairs(list)do
  local g=set.G
  if g.Alive then
   E.Step(g,function(_,t)
    local k=math.clamp(t/.14,0,1)
    local parts,cfs={},{}
    for _,b in ipairs(set.Blades)do
     local p=b.From:Lerp(set.Center,k*k)
     local cf=CFrame.lookAt(p,set.Center+(set.Center-b.From).Unit)
     parts[#parts+1]=b.Blade cfs[#cfs+1]=cf
     parts[#parts+1]=b.Glow cfs[#cfs+1]=cf
    end
    workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
    if k>=1 then
     for _,b in ipairs(set.Blades)do b.Blade.Transparency=1 b.Glow.Transparency=1 end
     local a=E.Anchor(g,CFrame.new(set.Center))
     E.Sprite(a,{tex="flare.big",size={{0,4},{.15,26},{1,30}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.4)
     E.Sprite(a,{tex="burst.spiky2",size={{0,3},{1,24}},alpha={{0,0},{1,1}},color=GOLD,rot={0,360}},.35)
     E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={30,60},spread=180,drag=2},34)
     E.Light(g,a,GOLD,40,9,.4)
     E.After(g,.8,function()g:Destroy()end)
     return false
    end
    return true
   end)
  end
 end
end

 -- Overclock: clock rings spin fast under him and around him, and speed lines stream off him while it lasts
function P.Overclock(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 8
 local g=E.Group("P5Overclock")
 local floor=E.Ground(r.Position,{d.Boss,g.Folder})
 local drop=floor and r.Position.Y-floor.Y-.1 or 3
 local feet=E.Anchor(g,r.CFrame*CFrame.new(0,-drop,0))
 local body=E.Anchor(g,r.CFrame)
 E.Sprite(feet,{tex="ring.ticked",orient="flat",size={{0,2},{.05,14},{1,14}},alpha={{0,.6},{.05,.15},{.95,.3},{1,1}},color=GOLD,spin={540,540}},T)
 E.Sprite(feet,{tex="ring.compass",orient="flat",size={{0,2},{.05,10},{1,10}},alpha={{0,.6},{.05,.2},{.95,.35},{1,1}},color=SHINE,spin={-720,-720}},T)
 local lines=E.Stream(body,{tex="wind.dash",orient="velocity",size={{0,2},{1,4}},alpha={{0,.45},{1,1}},color=SHINE,life={.15,.25},speed={20,35},spread=180},24)
 local motes=E.Stream(body,{tex="star.crisp",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.5},speed={4,10},spread=180},16)
 E.Light(g,body,GOLD,16,2,T)
 E.Step(g,function(_,t)
  if not r.Parent then g:Destroy()return false end
  workspace:BulkMoveTo({feet,body},{r.CFrame*CFrame.new(0,-drop,0),r.CFrame},Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then lines.Enabled=false motes.Enabled=false end
  return t<T+.3
 end)
 E.After(g,T+.6,function()g:Destroy()end)
end

 -- Overclock: a slow, pale clock turning under a player whose time he has slowed
function P.SlowClock(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T=d.Time or 5
 local g=E.Group("P5SlowClock")
 local pale=Color3.fromRGB(190,205,230)
 local feet=E.Anchor(g,CFrame.new(vr.Position-UP*2.9))
 E.Sprite(feet,{tex="ring.ticked",orient="flat",size={{0,12},{.06,7},{1,7}},alpha={{0,.7},{.06,.25},{.9,.35},{1,1}},color=pale,spin={-20,-20}},T)
 E.Sprite(feet,{tex="sigil.ring2",orient="flat",size={{0,9},{.06,5},{1,5}},alpha={{0,.7},{.06,.35},{.9,.45},{1,1}},color=GOLD,spin={12,12}},T)
 local drip=E.Stream(feet,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,pale},{1,GOLD}},life={.8,1.4},speed={1,2},spread=30,dir=Enum.NormalId.Top},8)
 E.Step(g,function(_,t)
  if vr.Parent then feet.CFrame=CFrame.new(vr.Position-UP*2.9)end
  if t>=T then drip.Enabled=false end
  return t<T+.2
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end

 -- big warning fields, the way the Flower Field marks its ground: a gold field and a crimson ring closing on its edge
function P.BigWarn(E,d)
 local g=E.Group("P5BigWarn")
 local T=d.Time or .8
 for i,p in ipairs(d.Points or{})do
  local R=(d.Radii and d.Radii[i])or 10
  local a=E.Anchor(g,CFrame.new(p+UP*.12))
  E.Sprite(a,{tex="disc.soft",orient="flat",size={{0,R*.5},{.2,R*2.1},{1,R*2.1}},alpha={{0,.9},{.2,.72},{1,.55}},color=BUTTERFLY_GOLD},T)
  E.Sprite(a,{tex="ring.crisp",orient="flat",size={{0,R*2.8},{1,R*2}},alpha={{0,.6},{.15,.05},{1,0}},color=CRIMSON},T+.05)
  E.Sprite(a,{tex="ring.thin",orient="flat",size=R*2,alpha={{0,.5},{.2,.15},{1,.1}},color=SHINE},T)
 end
 E.After(g,T+.4,function()g:Destroy()end)
end

 -- Silent Cut (after Devil May Cry 5's Judgment Cut End). He drops into a low draw stance and the world goes still -
 -- gold and drained, black bars closing in. He vanishes; slash lines fill the space around everyone, one after
 -- another, and across your own screen. He is back, sheathing slowly - HOLD E - a flash at the scabbard, and every
 -- line detonates at once while the screen shatters like glass.
local Tw=game:GetService("TweenService")
local silent={Item=nil,Lines={},Hidden={}}
local function hideBoss(boss,on)
 if on and boss then
  for _,p in ipairs(boss:GetDescendants())do
   if p:IsA("BasePart")or p:IsA("Decal")then silent.Hidden[p]=true p.LocalTransparencyModifier=1 end
  end
 else
  for p in pairs(silent.Hidden)do if p.Parent then p.LocalTransparencyModifier=0 end end
  table.clear(silent.Hidden)
 end
end
local function silentClear()
 local item=silent.Item
 silent.Item=nil
 if item then
  Tw:Create(item.Tint,TweenInfo.new(.4),{Saturation=0,TintColor=WHITE,Contrast=0}):Play()
  for _,bar in ipairs(item.Bars)do Tw:Create(bar,TweenInfo.new(.4),{Size=UDim2.fromScale(1,0)}):Play()end
  Tw:Create(item.Wash,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()
  task.delay(.5,function()item.Gui:Destroy()item.Tint:Destroy()end)
 end
 for _,l in ipairs(silent.Lines)do if l.Core.Parent then l.Core:Destroy()l.Glow:Destroy()end end
 table.clear(silent.Lines)
 hideBoss(nil,false)
end
local function restoreColour(item)
 Tw:Create(item.Tint,TweenInfo.new(.5),{Saturation=0,TintColor=WHITE,Contrast=0}):Play()
 for _,bar in ipairs(item.Bars)do Tw:Create(bar,TweenInfo.new(.45),{Size=UDim2.fromScale(1,0)}):Play()end
end
 -- the silence, on the screens of the players it targets
function P.SilentStart(E,d)
 local me=Players.LocalPlayer.Character
 local mine=false
 for _,v in ipairs(d.Victims or{})do if v==me then mine=true end end
 if not mine then return end
 local item=silent.Item
 if not item then
  local gui=Instance.new("ScreenGui")gui.Name="P5Silence" gui.IgnoreGuiInset=true gui.DisplayOrder=70
  local wash=Instance.new("Frame")wash.Size=UDim2.fromScale(1,1)wash.BackgroundColor3=Color3.fromRGB(255,206,70)wash.BackgroundTransparency=1
  wash.BorderSizePixel=0 wash.Parent=gui
  local bars={}
  for i,pos in ipairs({0,1})do
   local bar=Instance.new("Frame")bar.AnchorPoint=Vector2.new(0,pos)bar.Position=UDim2.fromScale(0,pos)bar.Size=UDim2.fromScale(1,0)
   bar.BackgroundColor3=Color3.new(0,0,0)bar.BorderSizePixel=0 bar.ZIndex=5 bar.Parent=gui bars[i]=bar
  end
  gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
  local tint=Instance.new("ColorCorrectionEffect")tint.Name="P5SilenceTint" tint.Parent=game:GetService("Lighting")
  item={Gui=gui,Wash=wash,Bars=bars,Tint=tint,Lines={}}
  silent.Item=item
 end
 local quick=d.Short and .08 or .35
 item.Wash.BackgroundColor3=Color3.fromRGB(255,206,70)
 Tw:Create(item.Wash,TweenInfo.new(quick),{BackgroundTransparency=d.Short and .84 or .74}):Play()
 Tw:Create(item.Tint,TweenInfo.new(quick),{Saturation=-.85,TintColor=Color3.fromRGB(255,226,150),Contrast=.15}):Play()
 for _,bar in ipairs(item.Bars)do Tw:Create(bar,TweenInfo.new(quick*1.5),{Size=UDim2.fromScale(1,d.Short and .06 or .11)}):Play()end
end
 -- the draw stance: gold dust drawn in to him, hairline cracks creeping out under him, a glint at the hilt
function P.SilentStance(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or 1
 local g=E.Group("P5SilentStance")
 local a=E.Anchor(g,r.CFrame)
 local pull=E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,GOLD}},life={.4,.6},speed={-16,-10},spread=180},70)
 local floor=E.Ground(r.Position,{d.Boss,g.Folder})
 -- (no hairline cracks on the ground any more)
 local hilt=E.Anchor(g,r.CFrame*CFrame.new(-.9,-.4,-.8))
 E.Sprite(hilt,{tex="star.glare",size={{0,.5},{.9,5},{1,1}},alpha={{0,.4},{.9,0},{1,1}},color=WHITE,rot={0,0}},T)
 E.Step(g,function(_,t)
  if r.Parent then a.CFrame=r.CFrame hilt.CFrame=r.CFrame*CFrame.new(-.9,-.4,-.8)end
  if t>=T then pull.Enabled=false end
  return t<T+.2
 end)
 E.After(g,T+1.4,function()g:Destroy()end)
end
function P.SilentCuts(E,d)
 local T=d.Time or .9
 local rng=Random.new(d.Seed or 1)
 local count=d.Count or 24
 local R=d.Radius or 22
 local small=d.Small==true
 local g=E.Group("P5SilentCuts")
 if d.Boss and not small then hideBoss(d.Boss,true) end
 for _,v in ipairs({})do
  local vr=rootOf(v)
  if vr then
   local c=vr.Position+UP*2
   local lowGround=E.Ground(vr.Position,{g.Folder,v})
   local floorY=lowGround and lowGround.Y or vr.Position.Y-3
   for i=1,count do
    E.After(g,(i-1)/count*T*.85,function()
     local dir=Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-.7,.7),rng:NextNumber(-1,1))
     dir=dir.Magnitude>.1 and dir.Unit or Vector3.xAxis
     local mid=c+Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-.3,.7),rng:NextNumber(-1,1))*R*.45
     local len=rng:NextNumber(14,32)*(small and .6 or 1)
      -- the lines hang in the air round them: none reaches down to the floor and cuts into it
     local lowest=mid.Y-math.abs(dir.Y)*len*.5
     if lowest<floorY+2 then mid=mid+Vector3.new(0,floorY+2-lowest,0) end
     local core=newPart(g,Vector3.new(.07,.07,.1),WHITE,0)
     local glow=newPart(g,Vector3.new(.45,.45,.1),BUTTERFLY_GOLD,.55)
     local cf=CFrame.lookAt(mid,mid+dir)
     core.CFrame=cf glow.CFrame=cf
     E.Tween(core,.06,{Size=Vector3.new(.07,.07,len)})
     E.Tween(glow,.08,{Size=Vector3.new(.45,.45,len)})
     local s0=E.Anchor(g,cf)
     E.Emit(s0,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,WHITE},{1,GOLD}},life={.2,.4},speed={4,10},spread=180},3)
     silent.Lines[#silent.Lines+1]={Core=core,Glow=glow,Mid=mid,Len=len}
    end)
   end
  end
 end
 local item=silent.Item
 if item then
  for i=1,0 do
   E.After(g,(i-1)/count*T*.85,function()
    if not item.Gui.Parent then return end
    local f=Instance.new("Frame")f.AnchorPoint=Vector2.new(.5,.5)
    f.Position=UDim2.fromScale(rng:NextNumber(.12,.88),rng:NextNumber(.15,.85))
    f.Size=UDim2.new(0,0,0,2)f.Rotation=rng:NextNumber(0,180)f.BackgroundColor3=WHITE f.BorderSizePixel=0 f.ZIndex=3 f.Parent=item.Gui
    Tw:Create(f,TweenInfo.new(.07),{Size=UDim2.new(rng:NextNumber(.25,.7),0,0,2)}):Play()
    item.Lines[#item.Lines+1]=f
   end)
  end
 end
 E.After(g,T,function()hideBoss(nil,false)end)
 E.After(g,14,function()g:Destroy()end)
end
 -- the sheathe: a glow at the scabbard that grows as the blade slides home, and a white flash at the end
function P.SilentSheathe(E,d)
 local r=rootOf(d.Boss)
 if not r then return end
 local T=d.Time or .75
 local g=E.Group("P5SilentSheathe")
 local function hip()return r.CFrame*CFrame.new(-.9,-.5,-.7)end
 local a=E.Anchor(g,hip())
 E.Sprite(a,{tex="glow.soft",size={{0,.5},{.9,3.5},{1,1}},alpha={{0,.6},{.9,.15},{1,1}},color=SHINE},T)
 E.After(g,math.max(T-.06,0),function()
  E.Sprite(a,{tex="star.glare2",size={{0,1},{.3,14},{1,2}},alpha={{0,0},{1,1}},color=WHITE,rot={0,0}},.25)
  E.Light(g,a,WHITE,16,9,.2)
 end)
 E.Step(g,function(_,t)
  if r.Parent then a.CFrame=hip()end
  return t<T+.3
 end)
 E.After(g,T+.5,function()g:Destroy()end)
end
 -- the shatter: every hanging line flares and bursts, each target is cut in a blinding flash, and on your screen the
 -- lines blaze, the screen whites out and breaks into glass that flies apart
function P.SilentShatter(E,d)
 local small=d.Small==true
 local lines=silent.Lines
 silent.Lines={}
 local h=E.Group("P5SilentShatter")
 for i,l in ipairs(lines)do
  if l.Core.Parent then
   local w=small and .3 or .55
   l.Core.Size=Vector3.new(w,w,l.Len) l.Glow.Size=Vector3.new(w*3.5,w*3.5,l.Len) l.Glow.Transparency=.2
   E.Tween(l.Core,.3,{Size=Vector3.new(0,0,l.Len*1.25),Transparency=1},nil,nil,.06)
   E.Tween(l.Glow,.35,{Size=Vector3.new(0,0,l.Len*1.25),Transparency=1},nil,nil,.06)
   if i%2==0 then
    local s0=E.Anchor(h,CFrame.new(l.Mid))
    E.Emit(s0,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={10,26},spread=180,drag=2},5)
   end
   task.delay(.5,function()l.Core:Destroy()l.Glow:Destroy()end)
  end
 end
 for _,v in ipairs(d.Victims or{})do
  local vr=rootOf(v)
  if vr then
   local a=E.Anchor(h,CFrame.new(vr.Position+UP*1.5))
   E.Sprite(a,{tex="flare.big",size={{0,4},{.12,small and 22 or 40},{1,small and 26 or 46}},alpha={{0,0},{.5,.3},{1,1}},color=SHINE},.4)
   local spin=math.random(0,180)
   E.Sprite(a,{tex="star.glare2",size={{0,4},{.2,small and 24 or 44},{1,6}},alpha={{0,0},{1,1}},color=WHITE,rot={spin,spin}},.3)
   E.Emit(a,{tex="star.crisp",size={{0,1.1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.35,.7},speed={25,60},spread=180,drag=2},small and 16 or 40)
   if not small then
    local floor=E.Ground(vr.Position,{h.Folder})
    local f=E.Anchor(h,CFrame.new((floor or vr.Position-UP*3)+UP*.15))
    -- (no ring on the ground any more)
   end
   E.Light(h,a,WHITE,30,10,.3)
  end
 end
 local item=silent.Item
 if item then
  for _,f in ipairs(item.Lines)do
   f.Size=UDim2.new(f.Size.X.Scale,0,0,small and 8 or 14)
   Tw:Create(f,TweenInfo.new(.35),{BackgroundTransparency=1,Size=UDim2.new(f.Size.X.Scale*1.2,0,0,0)}):Play()
   task.delay(.4,function()f:Destroy()end)
  end
  item.Lines={}
  item.Wash.BackgroundColor3=WHITE
  item.Wash.BackgroundTransparency=small and .45 or .02
  Tw:Create(item.Wash,TweenInfo.new(small and .3 or .5),{BackgroundTransparency=1}):Play()
  if not small then
   for _=1,18 do
    local f=Instance.new("Frame")f.AnchorPoint=Vector2.new(.5,.5)
    local px,py=math.random(),math.random()
    f.Position=UDim2.fromScale(px,py)f.Size=UDim2.fromOffset(math.random(60,190),math.random(40,150))f.Rotation=math.random(0,180)
    f.BackgroundColor3=Color3.fromRGB(255,242,205)f.BackgroundTransparency=.55 f.BorderSizePixel=0 f.ZIndex=4
    local st=Instance.new("UIStroke")st.Color=WHITE st.Thickness=2 st.Transparency=.1 st.Parent=f
    local gr=Instance.new("UIGradient")gr.Rotation=math.random(0,180)gr.Transparency=NumberSequence.new(.15,.9)gr.Parent=f
    f.Parent=item.Gui
    local dx,dy=(px-.5)*1.5,(py-.5)*1.5+.35
    Tw:Create(f,TweenInfo.new(.75,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromScale(px+dx,py+dy),
     Rotation=f.Rotation+math.random(-140,140),BackgroundTransparency=1}):Play()
    Tw:Create(st,TweenInfo.new(.75),{Transparency=1}):Play()
    task.delay(.8,function()f:Destroy()end)
   end
  end
  restoreColour(item)
 end
 E.After(h,1.2,function()h:Destroy()end)
end
 -- the wound: gold bleeding out of whoever lost half their health while it seeps back
function P.SilentHit(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T=d.Time or 10
 local g=E.Group("P5SilentHit")
 local a=E.Anchor(g,vr.CFrame)
 E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,SHINE},{1,AMBER}},life={.5,.9},speed={10,24},spread=180,accel=Vector3.new(0,-30,0)},30)
 local seep=E.Stream(a,{tex="star.tiny",size={{0,.5},{1,0}},color={{0,SHINE},{1,BUTTERFLY_GOLD}},life={.6,1},speed={-4,-2},spread=180},10)
 E.Step(g,function(_,t)
  if vr.Parent then a.CFrame=vr.CFrame end
  if t>=T then seep.Enabled=false end
  return t<T
 end)
 E.After(g,T+1,function()g:Destroy()end)
end
function P.SilentEnd(E,d)silentClear()end

 -- Scarlet River: his arm burns red and gold - the arm itself turns to light, crimson flame pours off the hand, rings of
 -- force spin round the forearm and red ripples spread under him
function P.RiverCharge(E,d)
 local boss=d.Boss
 local r=rootOf(boss)
 if not r then return end
 local T=d.Time or .8
 local hold=d.Hold or T+.8
 local hand=handOf(boss,"Right")or r
 local g=E.Group("P5RiverCharge")
 local arm={}
 for _,name in ipairs({"RightUpperArm","RightLowerArm","RightHand","Right Arm"})do
  local p=boss:FindFirstChild(name)
  if p and p:IsA("BasePart")then arm[#arm+1]={P=p,Color=p.Color,Material=p.Material}end
 end
 local a=E.Anchor(g,handCF(hand))
 E.Sprite(a,{tex="glow.soft",size={{0,1},{.85,9},{1,10}},alpha={{0,.5},{.85,.15},{1,1}},color=AMBER},T+.05)
 E.Sprite(a,{tex="star.lens",size={{0,1},{.85,7},{1,2}},alpha={{0,.4},{.85,0},{1,1}},color=SHINE,spin={200,200}},T+.05)
 local flame=E.Stream(a,{tex="fire",size={{0,2.4},{1,.5}},alpha={{0,.2},{1,1}},color={{0,SHINE},{.35,AMBER},{1,Color3.fromRGB(120,70,10)}},life={.3,.5},speed={3,7},spread=30,
  dir=Enum.NormalId.Top,light=.6},45)
 local spin=E.Stream(a,{tex="swirl.lines",size={{0,3.5},{1,5}},alpha={{0,.35},{1,1}},color=AMBER:Lerp(SHINE,.3),life={.25,.35},spin={600,600},locked=true},10)
 local drip=E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,SHINE},{1,AMBER}},life={.4,.7},speed={1,3},spread=40,dir=Enum.NormalId.Bottom,
  accel=Vector3.new(0,-25,0)},40)
 local pull=E.Stream(a,{tex="wind.dash",orient="velocity",size={{0,3},{1,.8}},alpha={{0,.5},{1,1}},color=AMBER:Lerp(GOLD,.4),life={.2,.3},speed={-30,-18},spread=180},34)
 local floor=E.Ground(r.Position,{boss,g.Folder})
 local feet=E.Anchor(g,CFrame.new((floor or r.Position-UP*3)+UP*.1))
 local ripples=E.Stream(feet,{tex="ring.thin",orient="flat",size={{0,2},{1,16}},alpha={{0,.3},{1,1}},color=AMBER,life={.6,.6}},4)
 local light=E.Light(g,a,AMBER,18,2)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  for _,p in ipairs(arm)do
   if p.P.Parent then
    p.P.Material=Enum.Material.Neon
    p.P.Color=p.Color:Lerp(p.P.Name:find("Hand")and SHINE:Lerp(GOLD,.4)or AMBER,k)
   end
  end
  if hand.Parent then a.CFrame=handCF(hand)end
  light.Brightness=2+6*k
  if t>=T then flame.Enabled=false spin.Enabled=false drip.Enabled=false pull.Enabled=false ripples.Enabled=false end
  return t<hold
 end)
 E.After(g,hold,function()
  for _,p in ipairs(arm)do if p.P.Parent then p.P.Color=p.Color p.P.Material=p.Material end end
  g:Destroy()
 end)
end
 -- Scarlet River: the lunge. A screech pours out ahead of him - rings of sound and torn air in a widening cone - and a
 -- river of red light floods along the floor behind him, flowing the way he went, splashing as he passes
function P.RiverLunge(E,d)
 local g=E.Group("P5RiverLunge")
 local T=d.Time or .42
 local v=d.To-d.From
 local len=v.Magnitude
 if len<1 then g:Destroy()return end
 local dir=v.Unit
 local side=dir:Cross(UP)
 side=side.Magnitude>.01 and side.Unit or Vector3.xAxis
 local tip=E.Anchor(g,CFrame.lookAt(d.From,d.To))
 local screech=E.Stream(tip,{tex="ring.thin",orient="flat",dir=Enum.NormalId.Front,size={{0,3},{1,28}},alpha={{0,.1},{1,1}},
  color=AMBER,light=.25,life={.28,.36},speed={60,80}},45)
 local cone=E.Stream(tip,{tex="wind.dash",orient="velocity",size={{0,5},{1,12}},alpha={{0,.35},{1,1}},color=AMBER:Lerp(GOLD,.5),life={.15,.25},
  speed={70,100},spread=28,dir=Enum.NormalId.Front},70)
 local trail=E.Stream(tip,{tex="star.crisp",size={{0,1},{1,0}},color={{0,SHINE},{1,AMBER}},life={.3,.6},speed={6,16},spread=60,dir=Enum.NormalId.Back,
  accel=Vector3.new(0,-30,0)},90)
 E.Sprite(tip,{tex="glow.soft",size={{0,10},{1,14}},alpha={{0,.3},{1,1}},color=AMBER},T+.1)
 E.Sprite(tip,{tex="flare.streak",size={{0,10},{1,20}},alpha={{0,0},{1,.4}},color=AMBER:Lerp(SHINE,.3),rot={0,0}},T+.05)
 local floor=E.Ground(d.From+UP*2,{d.Boss,g.Folder})
 local fy=(floor and floor.Y or d.From.Y-3)+.15
 local start=Vector3.new(d.From.X,fy,d.From.Z)
  -- the river: two flat ribbons on the floor (a beam's width runs along its attachments' Y axis, laid sideways here)
 local a0=E.Anchor(g,CFrame.new(start))
 local a1=E.Anchor(g,CFrame.new(start))
 local lay=CFrame.fromMatrix(Vector3.zero,dir,side)
 local at0,at1=E.Attach(a0,lay),E.Attach(a1,lay)
 local water=E.Beam(g,at0,at1,{tex="beam.streaks",color={{0,AMBER},{.5,Color3.fromRGB(120,70,10)},{1,AMBER}},alpha=0,width=8,face=false,scroll=-14,length=18,light=.1,brightness=1.5})
 local glow=E.Beam(g,at0,at1,{tex="beam.wisp",color=AMBER,alpha=.3,width=16,face=false,scroll=-6,length=30,light=.2})
 local splashAt=0
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local head=len*(1-(1-k)^2)
  local p=d.From+dir*head
  workspace:BulkMoveTo({tip,a1},{CFrame.lookAt(p,p+dir),CFrame.new(start+dir*head)},Enum.BulkMoveMode.FireCFrameChanged)
  while splashAt<=head do
   local s=E.Anchor(g,CFrame.new(start+dir*splashAt))
   E.Emit(s,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,SHINE},{1,AMBER}},life={.4,.7},speed={10,22},spread=35,dir=Enum.NormalId.Top,
    accel=Vector3.new(0,-50,0)},8)
   splashAt+=9
  end
  if t>=T then screech.Enabled=false cone.Enabled=false trail.Enabled=false end
  if t>=T+.5 then
   local f=math.clamp((t-T-.5)/.6,0,1)
   water.Width0=8*(1-f) water.Width1=water.Width0 glow.Width0=16*(1-f) glow.Width1=glow.Width0
   if f>=1 then return false end
  end
  return true
 end)
 E.After(g,T+1.6,function()g:Destroy()end)
end
 -- Scarlet River: whoever the screech catches is bound in red - a ring of thorns closing round them as he drags them
function P.RiverCatch(E,d)
 local vr=rootOf(d.Victim)
 if not vr then return end
 local T=d.Time or .6
 local g=E.Group("P5RiverCatch")
 local a=E.Anchor(g,vr.CFrame)
 E.Sprite(a,{tex="ring.dots",orient="flat",size={{0,9},{.25,5},{1,5}},alpha={{0,.5},{.25,.05},{1,.5}},color=AMBER,spin={300,300}},T)
 E.Sprite(a,{tex="glow.soft",size=7,alpha={{0,.45},{1,1}},color=AMBER},T)
 local thorns={}
 for i=1,6 do thorns[i]=newPart(g,Vector3.new(.25,.25,3),AMBER,0)end
 E.Step(g,function(_,t)
  if not vr.Parent then return false end
  a.CFrame=vr.CFrame
  local parts,cfs={},{}
  for i,p in ipairs(thorns)do
   local ang=i*math.pi/3+t*4
   local from=vr.Position+Vector3.new(math.cos(ang),0,math.sin(ang))*3.2+UP*(i%2==0 and .8 or -.6)
   parts[#parts+1]=p cfs[#cfs+1]=CFrame.lookAt(from,vr.Position)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T
 end)
 E.After(g,T+.1,function()g:Destroy()end)
end
 -- Scarlet River: the pierce - a long spear of red-gold light bursts through the one he caught, thorns fan out of
 -- their back, red light sprays and a shock ring rolls off the wound
function P.RiverPierce(E,d)
 local g=E.Group("P5RiverPierce")
 local dir=d.Dir or Vector3.zAxis
 local at=d.Pos
 local spear=newPart(g,Vector3.new(.8,.8,.1),WHITE,0)
 local sheath=newPart(g,Vector3.new(2.4,2.4,.1),AMBER,.35)
 local thorns={}
 for i=1,7 do
  local yaw,pitch=(math.random()-.5)*1.1,(math.random()-.5)*.9
  thorns[i]={P=newPart(g,Vector3.new(.3,.3,.1),i%2==0 and AMBER or SHINE,0),Dir=(CFrame.lookAt(Vector3.zero,dir)*CFrame.Angles(pitch,yaw,0)).LookVector,
   Len=6+math.random()*6}
 end
 local a=E.Anchor(g,CFrame.lookAt(at,at+dir))
 E.Sprite(a,{tex="flare.big",size={{0,4},{.15,22},{1,26}},alpha={{0,0},{.5,.35},{1,1}},color=AMBER:Lerp(SHINE,.35)},.4)
 E.Sprite(a,{tex="ring.crisp",orient="flat",dir=Enum.NormalId.Front,size={{0,3},{1,26}},alpha={{0,.1},{1,1}},color=SHINE},.35)
 E.Emit(a,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,AMBER}},life={.35,.7},speed={35,70},spread=35,dir=Enum.NormalId.Front,drag=2},40)
 E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,6}},alpha={{0,.5},{1,1}},color={{0,AMBER},{1,Color3.fromRGB(120,70,10)}},life={.4,.8},speed={14,28},spread=45,dir=Enum.NormalId.Front,drag=3},16)
 E.Light(g,a,AMBER,30,9,.45)
 E.Step(g,function(_,t)
  local k=math.clamp(t/.08,0,1)
  local fade=math.clamp((t-.3)/.3,0,1)
  local len=math.max(24*k,.1)
  spear.Size=Vector3.new(.8*(1-fade),.8*(1-fade),len) sheath.Size=Vector3.new(2.4*(1-fade),2.4*(1-fade),len)
  local cf=CFrame.lookAt(at-dir*3+dir*len*.5,at+dir*len)
  local parts,cfs={spear,sheath},{cf,cf}
  for _,th in ipairs(thorns)do
   local l=math.max(th.Len*k,.1)
   th.P.Size=Vector3.new(.3*(1-fade),.3*(1-fade),l)
   parts[#parts+1]=th.P cfs[#cfs+1]=CFrame.lookAt(at+th.Dir*l*.5,at+th.Dir*l)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<.65
 end)
 E.After(g,1,function()g:Destroy()end)
end

return P
