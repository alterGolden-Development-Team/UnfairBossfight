--[[
 Disorderer (client effect): everything you can see of the Reality Disorderer.
 Server kit: BossSystem.Players.Classes.Kits.Disorderer (Net.Send("Disorderer", stage, data)). Numbers come from ClassConfig.

 HANDS   Two large gauntlet hands float beside the shoulders. Every client builds them locally, as anchored parts moved with
         BulkMoveTo, so nothing replicates. Poses run on a stepped clock so they drop frames like corrupted footage.
 BOSS    Glitch stacks show on the boss as chromatic split copies, and Arena Glitch debuffs float above him as tags.
 FALTER  The hidden combo. The 4D sphere is real 4D maths: a hypercube rotating through the fourth axis, projected to 3D,
         inside shells whose radius follows a 3-sphere being sliced by our space.
]]
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Lighting=game:GetService("Lighting")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local T={}
if not Run:IsClient() then return T end
local E=require(script.Parent.Parent)
local Fov=require(Shared.Presentation.CameraFov)
local Reset=require(Shared.Presentation.CinematicReset)
local player=Players.LocalPlayer

local MAG=Color3.fromRGB(255,80,225)
local CYAN=Color3.fromRGB(70,235,255)
local VIOLET=Color3.fromRGB(125,70,255)
local DARK=Color3.fromRGB(19,17,28)
local ASH=Color3.fromRGB(58,50,82)
local PALE=Color3.fromRGB(255,235,255)
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
local UP=Vector3.yAxis
local NEON=Enum.Material.Neon
local METAL=Enum.Material.Metal
local FIELD=Enum.Material.ForceField
local BLOCK,BALL,CYL=Enum.PartType.Block,Enum.PartType.Ball,Enum.PartType.Cylinder
local SFX={Sonic="rbxassetid://9120769331",Boom="rbxassetid://9114362135"}
local rand=Random.new()

local function rootOf(c)return c and c:FindFirstChild("HumanoidRootPart")end
local function isLocal(c)return c==player.Character end
local function flat(v)local f=Vector3.new(v.X,0,v.Z)return f.Magnitude>.01 and f.Unit or Vector3.new(0,0,-1)end
local function P(parent,size,cf,color,mat,alpha,shape)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Massless=true
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Size=size p.CFrame=cf or CFrame.identity p.Color=color or WHITE p.Material=mat or NEON p.Transparency=alpha or 0
 if shape then p.Shape=shape end
 p.Parent=parent
 return p
end
local function play(id,at,volume,speed)
 local p=P(workspace,Vector3.one,CFrame.new(at),WHITE,NEON,1)
 local s=Instance.new("Sound")
 s.SoundId=id s.Volume=volume or 1 s.PlaybackSpeed=speed or 1
 s.RollOffMode=Enum.RollOffMode.Linear s.RollOffMinDistance=60 s.RollOffMaxDistance=900 s.Parent=p
 s:Play() Debris:AddItem(p,10)
end
local function pick2(i)return i%2==0 and MAG or CYAN end

local SC=2.05
local W,H,TH=1.72*SC,1.72*SC,.46*SC
local ROT=CFrame.Angles(0,0,math.pi/2)
local DIAMOND=CFrame.Angles(0,math.pi/4,0)
local FINGER_X={1,1/3,-1/3,-1}
local FINGER_LEN={.96,1.08,1,.82}
local SEG_LEN={.5,.42,.34}
local SEG_THK={.31,.27,.22}
local BEND={1.15,1.5,.95}
local THUMB_LEN={.46,.4,.32}
local THUMB_THK={.33,.28,.22}
local THUMB_BEND={.5,1.05,.9}

local function buildHand(folder,side)
 local tside=-side  -- the thumb sits on the inner edge
 local h={Side=side,Parts={},Cfs={},Static={},Chains={},Ghost={},Cur=CFrame.new(side*6.4,3.4,3.8),Curl={.3,.2,.16,.2,.28},Pulse=0,World=CFrame.identity}
 local function add(p)h.Parts[#h.Parts+1]=p h.Cfs[#h.Parts]=CFrame.identity return #h.Parts end
 local function fixed(size,off,color,mat,shape,alpha)
  local p=P(folder,size,off,color,mat,alpha,shape)
  local i=add(p)
  h.Static[#h.Static+1]={i,off}
  return p,i
 end
 local ghostSrc={}
 -- palm: a thick plate with rolled edges, so it reads as a solid hand rather than a flat card
 local _,palmI=fixed(Vector3.new(W,H*.84,TH),CFrame.identity,DARK,METAL)
 ghostSrc[#ghostSrc+1]=palmI
 for _,s in ipairs({1,-1})do
  fixed(Vector3.new(H*.84,TH,TH),CFrame.new(s*W/2,0,0)*ROT,DARK,METAL,CYL)
 end
 fixed(Vector3.new(W,TH*1.06,TH*1.06),CFrame.new(0,H*.42,0),ASH,METAL,CYL)
 fixed(Vector3.new(W*.86,TH*1.1,TH*1.1),CFrame.new(0,-H*.42,0),DARK,METAL,CYL)
 -- back of the hand: raised plate cut by corrupted seams
 fixed(Vector3.new(W*.74,H*.6,.09*SC),CFrame.new(0,-.02*SC,TH*.5+.03),ASH,METAL)
 for i=1,3 do
  fixed(Vector3.new(W*.68,.05*SC,.05*SC),CFrame.new(0,(i-2)*.32*SC,TH*.5+.09),pick2(i),NEON)
 end
 -- palm face: a diamond-cut error core
 fixed(Vector3.new(.9*SC,.9*SC,.07*SC),CFrame.new(0,-.02*SC,-TH*.5-.02)*CFrame.Angles(0,0,math.pi/4),ASH,METAL)
 local _,coreI=fixed(Vector3.new(.58*SC,.58*SC,.1*SC),CFrame.new(0,-.02*SC,-TH*.5-.05)*CFrame.Angles(0,0,math.pi/4),PALE,NEON)
 h.Core=h.Parts[coreI]
 -- floating wrist: broken ring of neon dashes
 for i=1,6 do
  local a=(i-1)*math.pi/3
  fixed(Vector3.new(.5*SC,.07*SC,.1*SC),CFrame.new(math.cos(a)*.68*SC,-H*.74,math.sin(a)*.3*SC)*CFrame.Angles(0,-a,0),pick2(i),NEON)
 end
 local function chain(base,lens,thicks,bends,splay,neonTip)
  local c={Base=base,Segs={},Bends=bends,Splay=splay}
  for k=1,#lens do
   local len,th=lens[k]*SC,thicks[k]*SC
   local cyl=add(P(folder,Vector3.new(len,th,th),nil,k==1 and ASH or DARK,METAL,0,CYL))
   local joint=add(P(folder,Vector3.one*th*1.06,nil,k==1 and DARK or ASH,METAL,0,BALL))
   c.Segs[k]={Cyl=cyl,Joint=joint,Len=len}
   ghostSrc[#ghostSrc+1]=cyl
  end
  local tipLen=.42*SC
  c.Tip=add(P(folder,Vector3.new(.17*SC,tipLen,.17*SC),nil,neonTip,NEON))
  c.TipLen=tipLen
  h.Chains[#h.Chains+1]=c
 end
 for i=1,4 do
  local lens={SEG_LEN[1]*FINGER_LEN[i],SEG_LEN[2]*FINGER_LEN[i],SEG_LEN[3]*FINGER_LEN[i]}
  chain(CFrame.new(tside*FINGER_X[i]*W*.36,H*.44,0),lens,SEG_THK,BEND,FINGER_X[i]*tside*.2,pick2(i))
 end
 chain(CFrame.new(tside*W*.46,-H*.14,-.05)*CFrame.Angles(0,0,-tside*.95),THUMB_LEN,THUMB_THK,THUMB_BEND,0,PALE)
 -- chromatic echoes: a cyan and a magenta copy of the palm and finger bones
 for e,color in ipairs({CYAN,MAG})do
  local list={}
  for _,src in ipairs(ghostSrc)do
   local p=P(folder,h.Parts[src].Size*1.05,nil,color,NEON,.9,h.Parts[src].Shape)
   list[#list+1]={add(p),src}
  end
  h.Ghost[e]={List=list,Dir=e==1 and -1 or 1}
 end
 local att=Instance.new("Attachment") att.Position=Vector3.new(0,0,-.1) att.Parent=h.Core
 h.Dust=E.Stream(att,{tex="star.twinkle",size={{0,.34},{1,0}},alpha={{0,.15},{1,1}},color={{0,PALE},{1,MAG}},life={.3,.7},speed={1,4},spread=180,drag=2},9)
 return h
end

local function poseHand(h,palm,curls,spread,g)
 local cfs=h.Cfs
 for _,s in ipairs(h.Static)do cfs[s[1]]=palm*s[2] end
 for c,chain in ipairs(h.Chains)do
  local curl=curls[c==5 and 1 or c+1]
  local cf=palm*chain.Base*CFrame.Angles(0,0,-spread*chain.Splay)
  for k,seg in ipairs(chain.Segs)do
   cf=cf*CFrame.Angles(-curl*chain.Bends[k],0,0)
   cfs[seg.Joint]=cf
   cfs[seg.Cyl]=cf*CFrame.new(0,seg.Len/2,0)*ROT
   cf=cf*CFrame.new(0,seg.Len,0)
  end
  cfs[chain.Tip]=cf*CFrame.Angles(-curl*.7,0,0)*CFrame.new(0,chain.TipLen/2,0)*DIAMOND
 end
 local split=(.05+.42*g)*SC
 for _,ghost in ipairs(h.Ghost)do
  local off=palm:VectorToWorldSpace(Vector3.new(ghost.Dir*split,ghost.Dir*split*.35,0))
  for _,item in ipairs(ghost.List)do cfs[item[1]]=cfs[item[2]]+off end
 end
 workspace:BulkMoveTo(h.Parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
end

local recs=setmetatable({},{__mode="k"})
local POSES={
 -- behind the shoulders and well clear of the body; they only come forward to act
 Idle={function(s,t)return CFrame.new(s*6.4,3.4+math.sin(t*1.5+s)*.3,3.8)*CFrame.Angles(math.rad(6),math.rad(-18*s),math.rad(-20*s))end,{.34,.22,.18,.22,.3}},
 Laser={function(s,t)return CFrame.new(s*5.4,4.2,.8)*CFrame.Angles(math.rad(-4),math.rad(-20*s),math.rad(-10*s))end,{.05,.04,.04,.04,.05}},
 Forge={function(s,t)return CFrame.new(s*3.6,3,-5)*CFrame.Angles(math.rad(14),math.rad(s*66),0)end,{.5,.5,.5,.5,.5}},
 Spread={function(s,t)return CFrame.new(s*9.5,8,2.5)*CFrame.Angles(math.rad(-30),math.pi,math.rad(-34*s))end,{.04,.03,.03,.03,.04}},
 Grab={function(s,t)return CFrame.new(s*3,3.2,-5.2)*CFrame.Angles(0,math.rad(s*52),0)end,{.95,.95,.95,.95,.95}},
}
local function removeRec(char)
 local rec=recs[char]
 if not rec then return end
 recs[char]=nil
 rec.Folder:Destroy()
end
local function addRec(char)
 if recs[char] then return end
 local folder=Instance.new("Folder")
 folder.Name="DisorderHands"
 folder.Parent=workspace.CurrentCamera and workspace or workspace
 recs[char]={Char=char,Folder=folder,Mode="Idle",Hands={buildHand(folder,1),buildHand(folder,-1)},G=.04,Tick=0,Seen=0}
end
local function setMode(char,mode)
 local rec=recs[char]
 if rec then rec.Mode=mode or "Idle" end
end
local function pulse(char,side,amount)
 local rec=recs[char]
 if rec then for _,h in ipairs(rec.Hands)do if h.Side==side then h.Pulse=amount or 1 end end end
end
local function palmPoint(char,side)
 local rec=recs[char]
 if rec then
  for _,h in ipairs(rec.Hands)do if h.Side==side then return (h.World*CFrame.new(0,0,-TH*.9)).Position end end
 end
 local root=rootOf(char)
 return root and (root.CFrame*CFrame.new(side*6.4,3.4,3.2)).Position or Vector3.zero
end
local function updateRecs(dt)
 local cam=workspace.CurrentCamera
 local camPos=cam and cam.CFrame.Position or Vector3.zero
 local t=os.clock()
 for char,rec in pairs(recs)do
  local root=rootOf(char)
  local hum=char:FindFirstChildOfClass("Humanoid")
  if not root or not char.Parent or not hum or hum.Health<=0 or char:GetAttribute("ClassId")~="Disorderer" then
   removeRec(char)
  else
   local dist=(root.Position-camPos).Magnitude
   local interval=dist>200 and .25 or dist>90 and 1/15 or 0
   rec.Tick+=dt
   if rec.Tick>=interval then
    local step=rec.Tick
    rec.Tick=0
    local stepped=math.floor(t*14)
    if rec.StepSeen~=stepped then
     rec.StepSeen=stepped
     local base=rec.Mode=="Idle" and .05 or .32
     rec.G=rand:NextNumber()<.06 and rand:NextNumber(.4,.9) or base
    end
    local pose=POSES[rec.Mode] or POSES.Idle
    local k=1-math.exp(-step*15)
    for _,h in ipairs(rec.Hands)do
     local s=h.Side
     h.Pulse=math.max(0,h.Pulse-step*5)
     h.Cur=h.Cur:Lerp(pose[1](s,t),k)
     for i=1,5 do h.Curl[i]+=(pose[2][i]+.06*math.sin(t*2.1+i+s)-h.Curl[i])*k end
     local g=rec.G
     local jit=CFrame.new((rand:NextNumber()-.5)*g*.5,(rand:NextNumber()-.5)*g*.35,(rand:NextNumber()-.5)*g*.3)*CFrame.Angles(0,0,(rand:NextNumber()-.5)*g*.3)
     if g<.1 then jit=CFrame.identity end
     local kick=CFrame.new(0,0,-h.Pulse*3.2)
     local curls=table.clone(h.Curl)
     if h.Pulse>0 then for i=1,5 do curls[i]*=1-h.Pulse end end
     h.World=root.CFrame*h.Cur*kick*jit
     poseHand(h,h.World,curls,.5+h.Pulse*.5,g)
     h.Core.Color=g>.3 and (stepped%2==0 and CYAN or MAG) or PALE
     h.Dust.Rate=(8+60*g)*E.Quality
    end
   end
  end
 end
end
local function watchChar(char)
 local function check()
  if char:GetAttribute("ClassId")=="Disorderer" and char.Parent then
   task.spawn(function()
    char:WaitForChild("HumanoidRootPart",5)
    if char:GetAttribute("ClassId")=="Disorderer" and char.Parent then addRec(char) end
   end)
  else
   removeRec(char)
  end
 end
 char:GetAttributeChangedSignal("ClassId"):Connect(check)
 check()
end
local function watchPlayer(p)
 p.CharacterAdded:Connect(watchChar)
 if p.Character then watchChar(p.Character) end
end
for _,p in ipairs(Players:GetPlayers())do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
Run.RenderStepped:Connect(updateRecs)

local ui
local function gui()
 if ui and ui.Root.Parent then return ui end
 local root=Instance.new("ScreenGui")
 root.Name="DisordererCinema" root.IgnoreGuiInset=true root.ResetOnSpawn=false root.DisplayOrder=62
 local function frame(color,z)
  local f=Instance.new("Frame") f.BorderSizePixel=0 f.BackgroundColor3=color f.ZIndex=z f.Parent=root return f
 end
 local top,bottom=frame(BLACK,3),frame(BLACK,3)
 top.Size=UDim2.fromScale(1,0) bottom.Size=UDim2.fromScale(1,0) bottom.AnchorPoint=Vector2.new(0,1) bottom.Position=UDim2.fromScale(0,1)
 local flash=frame(WHITE,5) flash.Size=UDim2.fromScale(1,1) flash.BackgroundTransparency=1
 local tears={}
 for i=1,9 do local f=frame(pick2(i),2) f.Visible=false f.BackgroundTransparency=.82 tears[i]=f end
 local scan={}
 for i=1,26 do local f=frame(BLACK,2) f.Visible=false f.BackgroundTransparency=.9 f.Size=UDim2.new(1,0,0,2) f.Position=UDim2.fromScale(0,(i-.5)/26) scan[i]=f end
 local function text(z,scale)
  local t=Instance.new("TextLabel")
  t.BackgroundTransparency=1 t.AnchorPoint=Vector2.new(.5,.5) t.Position=UDim2.fromScale(.5,scale) t.Size=UDim2.fromScale(.9,.15)
  t.Font=Enum.Font.Arcade t.TextScaled=true t.TextColor3=WHITE t.TextStrokeColor3=BLACK t.TextStrokeTransparency=.2 t.TextTransparency=1 t.ZIndex=z t.Text="" t.Parent=root
  return t
 end
 local title,ghostA,ghostB=text(7,.42),text(6,.42),text(6,.42)
 ghostA.TextColor3=CYAN ghostB.TextColor3=MAG
 local scale=Instance.new("UIScale") scale.Parent=title
 root.Parent=player:WaitForChild("PlayerGui")
 ui={Root=root,Top=top,Bottom=bottom,Flash=flash,Tears=tears,Scan=scan,Title=title,GhostA=ghostA,GhostB=ghostB,Scale=scale}
 return ui
end
local function letterbox(on,time)
 local u=gui()
 local info=TweenInfo.new(time or .3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
 local goal={Size=UDim2.fromScale(1,on and .12 or 0)}
 Tween:Create(u.Top,info,goal):Play()
 Tween:Create(u.Bottom,info,goal):Play()
end
local function screenFlash(color,alpha,time)
 local u=gui()
 u.Flash.BackgroundColor3=color u.Flash.BackgroundTransparency=alpha
 Tween:Create(u.Flash,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
end
local titleToken=0
local function slam(text,color,hold)
 local u=gui()
 titleToken+=1
 local token=titleToken
 for _,l in ipairs({u.Title,u.GhostA,u.GhostB})do l.Text=text l.TextTransparency=0 l.TextStrokeTransparency=l==u.Title and .2 or 1 end
 u.Title.TextColor3=color or WHITE
 u.Scale.Scale=1.6
 Tween:Create(u.Scale,TweenInfo.new(.14,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()
 task.spawn(function()
  local ends=os.clock()+(hold or 1)
  while os.clock()<ends and titleToken==token do
   local dx=rand:NextNumber(-.012,.012)
   u.GhostA.Position=UDim2.fromScale(.5+dx-.006,.42) u.GhostB.Position=UDim2.fromScale(.5-dx+.006,.42)
   task.wait(.05)
  end
  if titleToken~=token then return end
  for _,l in ipairs({u.Title,u.GhostA,u.GhostB})do Tween:Create(l,TweenInfo.new(.22),{TextTransparency=1,TextStrokeTransparency=1}):Play() end
 end)
end
local screenCount=0
local screenConn
local function screenGlitch(on)
 screenCount=math.max(0,screenCount+(on and 1 or -1))
 local u=gui()
 if screenCount==0 then
  if screenConn then screenConn:Disconnect() screenConn=nil end
  for _,f in ipairs(u.Tears)do f.Visible=false end
  for _,f in ipairs(u.Scan)do f.Visible=false end
  return
 end
 if screenConn then return end
 for _,f in ipairs(u.Scan)do f.Visible=true end
 local nextAt=0
 screenConn=Run.RenderStepped:Connect(function()
  local t=os.clock()
  if t<nextAt then return end
  nextAt=t+1/12
  for _,f in ipairs(u.Tears)do
   f.Visible=rand:NextNumber()<.55
   f.Size=UDim2.new(rand:NextNumber(.2,1),0,0,rand:NextInteger(4,26))
   f.Position=UDim2.fromScale(rand:NextNumber(-.1,.6),rand:NextNumber())
  end
 end)
end
local cc
local function colorShift(tint,sat,contrast,time,bright)
 if not cc or not cc.Parent then
  cc=Instance.new("ColorCorrectionEffect") cc.Name="DisordererCC" cc.Parent=Lighting
 end
 Tween:Create(cc,TweenInfo.new(time or .25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TintColor=tint,Saturation=sat,Contrast=contrast,Brightness=bright or 0}):Play()
end
local function colorReset(time)colorShift(WHITE,0,0,time or .4)end

local CAM_STEP="DisordererCine"
local Cine={Token=0,Active=false}
local function stopCine()
 Cine.Token+=1
 if not Cine.Active then return end
 Cine.Active=false
 Run:UnbindFromRenderStep(CAM_STEP)
 local cam=workspace.CurrentCamera
 if cam then
  cam.CameraType=Enum.CameraType.Custom
  cam.FieldOfView=Fov.Base(cam)
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h then cam.CameraSubject=h end
 end
 letterbox(false,.3)
end
local function ease(k,s)
 if s=="in" then return k*k*k elseif s=="linear" then return k end
 return 1-(1-k)^3
end
local function runShots(base,shots,shake)
 local cam=workspace.CurrentCamera
 if not cam or not Reset.ViewAllowed() or player:GetAttribute("DisableSkillCutscenes")==true then return end
 stopCine()
 local token=Cine.Token
 local total=0
 for _,s in ipairs(shots)do total+=s.D end
 Cine.Active=true
 cam.CameraType=Enum.CameraType.Scriptable
 letterbox(true,.22)
 local start=os.clock()
 Run:BindToRenderStep(CAM_STEP,Enum.RenderPriority.Camera.Value+1,function()
  if Cine.Token~=token then return end
  local t=os.clock()-start
  local shot,k=shots[#shots],1
  local at=0
  for _,s in ipairs(shots)do
   if t<at+s.D then shot,k=s,(t-at)/s.D break end
   at+=s.D
  end
  local e=ease(k,shot.Ease)
  local p=base*shot.P0:Lerp(shot.P1 or shot.P0,e)
  local l=base*shot.L0:Lerp(shot.L1 or shot.L0,e)
  local roll=(shot.R0 or 0)+((shot.R1 or shot.R0 or 0)-(shot.R0 or 0))*e
  local amount=shake and shake() or 0
  local j=CFrame.new((rand:NextNumber()-.5)*amount,(rand:NextNumber()-.5)*amount,0)
  cam.CFrame=CFrame.lookAt(p,l)*CFrame.Angles(0,0,math.rad(roll))*j
  cam.FieldOfView=shot.F0+((shot.F1 or shot.F0)-shot.F0)*e
 end)
 task.delay(total+3,function()if Cine.Token==token then stopCine()end end)
end
local IMPACT_STEP="DisordererImpact"
local impactToken=0
local function impactFrames(models,frames)
 if not Reset.ViewAllowed() or player:GetAttribute("DisableSkillCutscenes")==true then return end
 local cam=workspace.CurrentCamera
 if not cam then return end
 impactToken+=1
 local token=impactToken
 Run:UnbindFromRenderStep(IMPACT_STEP)
 local plate=P(cam,Vector3.new(160,160,.05),cam.CFrame*CFrame.new(0,0,-1.2),BLACK,NEON)
 plate.Name="DisorderImpactPlate"
 local lights={}
 for _,m in ipairs(models)do
  if typeof(m)=="Instance" and m.Parent then
   local h=Instance.new("Highlight")
   h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.FillTransparency=0 h.OutlineTransparency=0 h.Adornee=m h.Parent=m
   lights[#lights+1]=h
  end
 end
 Run:BindToRenderStep(IMPACT_STEP,Enum.RenderPriority.Camera.Value+4,function()
  if plate.Parent then plate.CFrame=cam.CFrame*CFrame.new(0,0,-1.2) end
 end)
 task.spawn(function()
  for _,f in ipairs(frames)do
   if impactToken~=token then break end
   plate.Color=f[1]
   for _,h in ipairs(lights)do h.FillColor=f[2] h.OutlineColor=f[1] end
   task.wait(f[3])
  end
  if impactToken==token then Run:UnbindFromRenderStep(IMPACT_STEP) end
  plate:Destroy()
  for _,h in ipairs(lights)do h:Destroy() end
 end)
end

local casts=setmetatable({},{__mode="k"})
local function finishCast(char,fade)
 local c=casts[char]
 if not c then return end
 casts[char]=nil
 for _,fn in ipairs(c.Restore)do pcall(fn)end
 if fade then c.G:Fade(fade) else c.G:Destroy() end
end
local function newCast(char,name,life)
 finishCast(char)
 local c={G=E.Group("Disorder_"..name),Restore={}}
 casts[char]=c
 task.delay(life,function()if casts[char]==c then finishCast(char,.2)end end)
 return c,c.G
end
function T.Cancel(_,d)
 finishCast(d.Char)
 setMode(d.Char,"Idle")
 if isLocal(d.Char)then stopCine() colorReset() end
end
function T.CastEnd(_,d)
 finishCast(d.Char,.25)
 setMode(d.Char,"Idle")
 if isLocal(d.Char)then stopCine() end
end

 --   1. Value first. The arena is bright sand and additive glow washes out on it, so every effect sits on a dark plate.
 --   2. One primary element (white hot, hard silhouette); colour stays secondary and lower opacity.
 --   3. Anticipation, then a flash on the exact impact frame, then a short dissipation that clears.
 --   4. Glitch means block displacement: stepped at 14fps, offset slabs with RGB edges, never smooth motion.
local VOID=Color3.fromRGB(16,9,30)
local SLATE=Color3.fromRGB(48,26,84)
local PLASTIC=Enum.Material.SmoothPlastic
local function darkPlate(a,size,life)
 E.Sprite(a,{tex="disc.soft",light=0,size={{0,size*.45},{.15,size},{1,size*1.15}},alpha={{0,.2},{.55,.42},{1,1}},color=VOID},life)
end
local function datamosh(g,pos,width,height,life,n)
 local cam=workspace.CurrentCamera
 local look=cam and flat(cam.CFrame.LookVector) or Vector3.new(0,0,-1)
 local right=look:Cross(UP).Unit
 n=math.max(3,math.floor(n*E.Quality))
 local slabs={}
 for i=1,n do
  local h=height/n*rand:NextNumber(.5,1.1)
  local base=pos+UP*(((i-.5)/n-.5)*height)
  local w=width*rand:NextNumber(.3,1)
  local col=i%4==0 and WHITE or pick2(i)
  slabs[i]={
   Base=base,
   Back=P(g.Folder,Vector3.new(w+.6,h+.3,.06),nil,VOID,PLASTIC,.12),
   Front=P(g.Folder,Vector3.new(w,h,.06),nil,col,NEON,.08),
  }
 end
 local stepNo,steps=-1,math.max(2,math.floor(life*14))
 E.Step(g,function(_,t)
  local s2=math.floor(t*14)
  if s2==stepNo then return end
  stepNo=s2
  local k=s2/steps
  for _,x in ipairs(slabs)do
   if k>=1 or rand:NextNumber()<k*.55 then
    x.Front.Transparency=1 x.Back.Transparency=1
   else
    local off=right*rand:NextNumber(-width*.55,width*.55)
    local f=CFrame.lookAt(x.Base+off,x.Base+off+look)
    x.Front.CFrame=f x.Back.CFrame=f*CFrame.new(rand:NextNumber(-.5,.5),0,-.1)
   end
  end
  if k>=1 then return false end
 end)
end

 -- a real wireframe half sphere that expands from `center`
local function wireDome(g,center,maxRadius,life,color)
 local bars,parts,cfs={},{},{}
 local function add(a,b,col)
  bars[#bars+1]={A=a,B=b,F=P(g.Folder,Vector3.new(.4,.4,1),nil,col,NEON,.05)}
 end
 local function point(lat,lon)
  return Vector3.new(math.cos(lat)*math.cos(lon),math.sin(lat),math.cos(lat)*math.sin(lon))
 end
 local meridians,segs=E.Quality<.6 and 6 or 10,6
 for m=1,meridians do
  local lon=(m-1)/meridians*math.pi*2
  for k=1,segs do
   add(point((k-1)/segs*math.pi/2,lon),point(k/segs*math.pi/2,lon),m%2==0 and color or WHITE)
  end
 end
 for _,lat in ipairs({0,.38,.8,1.2})do
  local n=20
  for k=1,n do
   add(point(lat,(k-1)/n*math.pi*2),point(lat,k/n*math.pi*2),pick2(k))
  end
 end
 for i,b in ipairs(bars)do parts[i]=b.F cfs[i]=CFrame.identity end
 local start=os.clock()
 E.Step(g,function()
  local k=math.clamp((os.clock()-start)/life,0,1)
  local r=maxRadius*(1-(1-k)^4)
  local thick=math.clamp(r*.012,.25,1.8)
  local alpha=k>.55 and (k-.55)/.45 or .05
  for i,b in ipairs(bars)do
   local p,q=center+b.A*r,center+b.B*r
   b.F.Size=Vector3.new(thick,thick,math.max(.1,(q-p).Magnitude))
   b.F.Transparency=alpha
   cfs[i]=CFrame.lookAt((p+q)/2,q)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if k>=1 then
   for _,x in ipairs(parts)do x.Transparency=1 end
   return false
  end
 end)
end
 -- columns of displaced colour standing up out of the ground (a pixel sort, in world space)
local function pixelPillars(g,points,count,duration,maxHeight)
 local list={}
 for i=1,math.floor(count*E.Quality)do
  list[i]={B=P(g.Folder,Vector3.new(1,1,.2),nil,VOID,PLASTIC,1),F=P(g.Folder,Vector3.new(1,1,.2),nil,pick2(i),NEON,1),Until=0}
 end
 local stepNo=-1
 E.Step(g,function(_,t)
  local s2=math.floor(t*14)
  if s2==stepNo then return end
  stepNo=s2
  if t>=duration then
   for _,x in ipairs(list)do x.B.Transparency=1 x.F.Transparency=1 end
   return false
  end
  local cam=workspace.CurrentCamera
  local look=cam and flat(cam.CFrame.LookVector) or Vector3.new(0,0,-1)
  local now=os.clock()
  for i,x in ipairs(list)do
   if now>=x.Until and #points>0 then
    x.Until=now+rand:NextNumber(.14,.5)
    local p=points[rand:NextInteger(1,#points)]
    local h,w=rand:NextNumber(14,maxHeight),rand:NextNumber(1.2,5)
    local at=p+UP*(h/2)
    x.F.Size=Vector3.new(w,h,.1) x.B.Size=Vector3.new(w+1,h+1,.1)
    x.F.CFrame=CFrame.lookAt(at,at+look)
    x.B.CFrame=x.F.CFrame*CFrame.new(rand:NextNumber(-1,1),0,-.14)
    x.F.Color=rand:NextNumber()<.2 and WHITE or pick2(i)
    x.F.Transparency=.08 x.B.Transparency=.15
   elseif rand:NextNumber()<.12 then
    x.F.Transparency=1 x.B.Transparency=1 x.Until=now+rand:NextNumber(.05,.3)
   end
  end
 end)
end
 -- rectangles of the sky knocked out of place: black, with an RGB edge
local function skyTears(g,points,count,duration)
 local list={}
 for i=1,math.floor(count*E.Quality)do
  list[i]={V=P(g.Folder,Vector3.new(1,1,.3),nil,VOID,PLASTIC,1),A=P(g.Folder,Vector3.new(1,1,.2),nil,CYAN,NEON,1),C=P(g.Folder,Vector3.new(1,1,.2),nil,MAG,NEON,1),Until=0}
 end
 local stepNo=-1
 E.Step(g,function(_,t)
  local s2=math.floor(t*14)
  if s2==stepNo then return end
  stepNo=s2
  if t>=duration then
   for _,x in ipairs(list)do x.V.Transparency=1 x.A.Transparency=1 x.C.Transparency=1 end
   return false
  end
  local cam=workspace.CurrentCamera
  local look=cam and flat(cam.CFrame.LookVector) or Vector3.new(0,0,-1)
  local now=os.clock()
  for _,x in ipairs(list)do
   if now>=x.Until and #points>0 then
    x.Until=now+rand:NextNumber(.2,.7)
    local w,h=rand:NextNumber(14,70),rand:NextNumber(2,22)
    local p=points[rand:NextInteger(1,#points)]+UP*rand:NextNumber(30,120)
    local f=CFrame.lookAt(p,p+look)
    x.V.Size=Vector3.new(w,h,.3) x.V.CFrame=f x.V.Transparency=.05
    x.A.Size=Vector3.new(w,h,.2) x.A.CFrame=f*CFrame.new(-1.4,.5,-.2) x.A.Transparency=.35
    x.C.Size=Vector3.new(w,h,.2) x.C.CFrame=f*CFrame.new(1.4,-.5,-.25) x.C.Transparency=.35
   elseif rand:NextNumber()<.1 then
    x.V.Transparency=1 x.A.Transparency=1 x.C.Transparency=1 x.Until=now+rand:NextNumber(.1,.4)
   end
  end
 end)
end

local orbs={}
local function orbEnd(id,pos)
 local o=orbs[id]
 if not o then return end
 orbs[id]=nil
 if pos then
  local a=E.Anchor(o.G,CFrame.new(pos))
  darkPlate(a,11,.22)
  E.Sprite(a,{tex="burst.white",size={{0,2},{1,13}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE,rot={0,360}},.2)
  E.Sprite(a,{tex="burst.fringe",size={{0,3},{1,16}},alpha={{0,.15},{1,1}},color=WHITE,rot={0,360}},.26)
  datamosh(o.G,pos,9,8,.3,6)
  E.Emit(a,{tex="glitch.block",size={{0,1.1},{1,0}},color={{0,WHITE},{1,CYAN}},life={.15,.35},speed={30,80},spread=180},14)
  E.Light(o.G,a,MAG,16,4,.2)
  E.After(o.G,.5,function()o.G:Destroy()end)
 else
  o.G:Fade(.08)
 end
end
function T.Orb(_,d)
 pulse(d.Char,d.Side,1)
 local g=E.Group("Disorder_Orb")
 local origin=palmPoint(d.Char,d.Side)
 local aimPoint=d.Origin+d.Dir*d.Range
 local dir=(aimPoint-origin).Unit
 local tint=d.Side>0 and MAG or CYAN
 local halo=P(g.Folder,Vector3.one*3,CFrame.new(origin),VOID,PLASTIC,.45,BALL)
 local shell=P(g.Folder,Vector3.one*2.1,CFrame.new(origin),tint,NEON,.2,BALL)
 local core=P(g.Folder,Vector3.one*1.3,CFrame.new(origin),WHITE,NEON,0,BALL)
 local anchor=E.Anchor(g,CFrame.new(origin))
 E.Sprite(anchor,{tex="ring.crisp",size=4.2,alpha=.2,color=WHITE,spin={260,260}},3)
 E.Stream(anchor,{tex="glitch.block",size={{0,.9},{1,0}},color={{0,WHITE},{1,tint}},life={.1,.24},speed={1,6},spread=180},44)
 E.Light(g,core,tint,16,3)
 local muzzle=E.Anchor(g,CFrame.new(origin))
 E.Sprite(muzzle,{tex="star.anime",size={{0,9},{1,0}},alpha={{0,0},{1,1}},color=WHITE,rot={45,45}},.12)
 darkPlate(muzzle,7,.12)
 orbs[d.Id]={G=g}
 local start=os.clock()
 local lastGhost=-1
 E.Step(g,function()
  local t=os.clock()-start
  local p=origin+dir*(d.Speed*t)
  local f=CFrame.new(p)
  core.CFrame=f shell.CFrame=f halo.CFrame=f anchor.CFrame=f
  local s2=math.floor(t*14)
  if s2~=lastGhost then
   lastGhost=s2
   -- stepped after-images instead of a smooth trail
   local size=rand:NextNumber(.9,1.8)
   local ghost=P(g.Folder,Vector3.one*size,f*CFrame.Angles(rand:NextNumber(0,3),rand:NextNumber(0,3),0),s2%2==0 and MAG or CYAN,NEON,.15)
   local dark=P(g.Folder,Vector3.one*(size+.5),ghost.CFrame,VOID,PLASTIC,.35)
   task.delay(.16,function()ghost:Destroy()dark:Destroy()end)
  end
  if t*d.Speed>d.Range+6 then orbEnd(d.Id) return false end
 end)
end
function T.OrbHit(_,d)orbEnd(d.Id,d.Pos)end
function T.OrbEnd(_,d)orbEnd(d.Id)end

local lasers={}
function T.LaserStart(_,d)
 setMode(d.Char,"Laser")
 local g=E.Group("Disorder_Laser")
 local state={G=g,Char=d.Char,Target=d.Target,Point=d.Point}
 lasers[d.Id]=state
 local handR,handL=E.Anchor(g),E.Anchor(g)
 local focus,tip=E.Anchor(g),E.Anchor(g)
 local function feed(from,color,curve)
  local a0,a1=E.Attach(from),E.Attach(focus)
  E.Beam(g,a0,a1,{tex="beam.core",mode=Enum.TextureMode.Stretch,width0=1.3,width1=.45,color={{0,WHITE},{1,color}},brightness=5,segments=18,curve0=curve,curve1=-curve*.4})
  E.Beam(g,a0,a1,{tex="beam.core",mode=Enum.TextureMode.Stretch,light=0,width0=2.5,width1=.9,color=VOID,alpha=.4,brightness=1,segments=18,curve0=curve,curve1=-curve*.4,z=-1})
 end
 feed(handR,MAG,7) feed(handL,CYAN,-7)
 local a0,a1=E.Attach(focus),E.Attach(tip)
 local dark=E.Beam(g,a0,a1,{tex="beam.core",mode=Enum.TextureMode.Stretch,light=0,width=0,color=VOID,alpha=.25,brightness=1,segments=4,z=-2})
 local glowM=E.Beam(g,a0,a1,{tex="beam.streaks",length=22,scroll=-90,width=0,color=MAG,brightness=2,segments=4})
 local glowC=E.Beam(g,a0,a1,{tex="beam.dots",length=12,scroll=-150,width=0,color=CYAN,brightness=2,segments=4})
 local core=E.Beam(g,a0,a1,{tex="beam.core",mode=Enum.TextureMode.Stretch,width=0,color=WHITE,brightness=2.5,segments=4,z=2})
 -- the focus: a white point inside a black well inside a turning ring
 local well=P(g.Folder,Vector3.one*.1,nil,VOID,PLASTIC,.08,BALL)
 local orb=P(g.Folder,Vector3.one*.1,nil,WHITE,NEON,0,BALL)
 E.Sprite(focus,{tex="ring.ticked",size={{0,1},{.08,15},{1,15}},alpha=.15,color=MAG,spin={220,220}},7)
 E.Sprite(focus,{tex="star.lens",size={{0,1},{.08,17},{1,17}},alpha=.1,color=WHITE,spin={-120,-120}},7)
 E.Stream(focus,{tex="glitch.block",shape=Enum.ParticleEmitterShape.Sphere,style=Enum.ParticleEmitterShapeStyle.Surface,inout=Enum.ParticleEmitterShapeInOut.Inward,size={{0,1},{1,0}},color={{0,WHITE},{1,CYAN}},life={.15,.3},speed={10,22}},60)
 E.Light(g,orb,MAG,30,6)
 -- slabs of the beam knocked sideways
 local slabs={}
 for i=1,6 do
  slabs[i]={F=P(g.Folder,Vector3.new(1,1,1),nil,pick2(i),NEON,1),B=P(g.Folder,Vector3.new(1,1,1),nil,VOID,PLASTIC,1)}
 end
 E.Sprite(tip,{tex="disc.soft",light=0,size=20,alpha=.42,color=VOID},7)
 E.Stream(tip,{tex="burst.white",size={{0,4},{1,13}},alpha={{0,.1},{1,1}},color=WHITE,life={.07,.14},rot={0,360}},18)
 E.Stream(tip,{tex="glitch.block",size={{0,1.3},{1,0}},color={{0,WHITE},{1,MAG}},life={.15,.35},speed={35,95},spread=170},70)
 E.Light(g,tip,CYAN,28,6)
 local start=os.clock()
 local stepNo=-1
 E.Step(g,function()
  local c=d.Char
  local root=rootOf(c)
  if not root then return false end
  local t=os.clock()-start
  local k=math.clamp(t/d.Converge,0,1)
  local focusPos=(root.CFrame*CFrame.new(0,4.6,-8)).Position
  handR.CFrame=CFrame.new(palmPoint(c,1)) handL.CFrame=CFrame.new(palmPoint(c,-1))
  focus.CFrame=CFrame.new(focusPos)
  well.Size=Vector3.one*math.max(.1,4.4*k) orb.Size=Vector3.one*math.max(.1,2.4*k)
  well.CFrame=focus.CFrame orb.CFrame=focus.CFrame
  local aim=state.Point
  if state.Target and rootOf(state.Target) then aim=rootOf(state.Target).Position end
  aim=aim or focusPos+root.CFrame.LookVector*200
  tip.CFrame=CFrame.new(aim)
  local on=k>=1 and 1 or 0
  local s2=math.floor(t*14)
  if s2~=stepNo then
   stepNo=s2
   local f=s2%2==0
   core.Width0=(f and 1.3 or 1)*on core.Width1=core.Width0
   glowM.Width0=(f and 3.6 or 4.4)*on glowM.Width1=glowM.Width0
   glowC.Width0=(f and 5.4 or 4.2)*on glowC.Width1=glowC.Width0
   dark.Width0=7.5*on dark.Width1=7.5*on
   local axis=(aim-focusPos)
   local len=axis.Magnitude
   local dirL=len>.1 and axis.Unit or root.CFrame.LookVector
   local side=dirL:Cross(UP)
   side=side.Magnitude>.01 and side.Unit or Vector3.xAxis
   for _,x in ipairs(slabs)do
    if on==1 and rand:NextNumber()<.7 then
     local along=rand:NextNumber(.08,.95)*len
     local seg=rand:NextNumber(5,16)
     local off=side*rand:NextNumber(-5,5)+UP*rand:NextNumber(-3,3)
     local at=focusPos+dirL*along+off
     local w=rand:NextNumber(.8,2.4)
     x.F.Size=Vector3.new(w,w*.6,seg) x.F.CFrame=CFrame.lookAt(at,at+dirL) x.F.Transparency=.1
     x.B.Size=Vector3.new(w+.8,w*.6+.5,seg+.8) x.B.CFrame=x.F.CFrame x.B.Transparency=.3
    else x.F.Transparency=1 x.B.Transparency=1 end
   end
  end
 end)
 if isLocal(d.Char)then screenFlash(MAG,.9,.12) end
end
function T.LaserAim(_,d)
 local s=lasers[d.Id]
 if s then s.Target=d.Target s.Point=d.Point end
end
function T.LaserEnd(_,d)
 local s=lasers[d.Id]
 if not s then return end
 lasers[d.Id]=nil
 setMode(s.Char,"Idle")
 s.G:Fade(.14)
end

function T.Teleport(_,d)
 local g=E.Group("Disorder_Blink")
 local a,b=E.Anchor(g,CFrame.new(d.From)),E.Anchor(g,CFrame.new(d.To))
 local a0,a1=E.Attach(a),E.Attach(b)
 local beam=E.Beam(g,a0,a1,{tex="beam.dots",length=8,scroll=70,width=3.4,color={{0,CYAN},{1,MAG}},brightness=3,segments=4})
 E.Tween(beam,.28,{Width0=0,Width1=0})
 for _,x in ipairs({a,b})do
  E.Sprite(x,{tex="burst.fringe",size={{0,3},{1,18}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE,rot={0,360}},.3)
  E.Emit(x,{tex="star.tiny",size={{0,.8},{1,0}},color={{0,WHITE},{1,MAG}},life={.25,.5},speed={15,45},spread=180},26)
 end
 E.After(g,.6,function()g:Destroy()end)
end
local KEEP={Humanoid=true,BodyColors=true,Shirt=true,Pants=true,ShirtGraphic=true,Accessory=true,Hat=true,SpecialMesh=true,Decal=true,Attachment=true,Weld=true,Motor6D=true,WeldConstraint=true,BlockMesh=true,CylinderMesh=true}
local function cloneAvatar(char)
 local was=char.Archivable
 char.Archivable=true
 local ok,model=pcall(function()return char:Clone()end)
 char.Archivable=was
 if not ok or not model then return nil end
 for _,c in ipairs(model:GetChildren())do
  if c.Name=="ClassGear" or c.Name:find("^ClassStatusFX") or c:IsA("Tool") or c:IsA("ForceField") or c:IsA("Folder") then c:Destroy() end
 end
 for _,d in ipairs(model:GetDescendants())do
  if d.Parent and not (d:IsA("BasePart") or KEEP[d.ClassName]) then d:Destroy() end
 end
 for _,d in ipairs(model:GetDescendants())do
  if d:IsA("BasePart") then d.CanCollide=false d.CanQuery=false d.CanTouch=false d.CastShadow=false d.Massless=true d.Anchored=false end
 end
 local hum=model:FindFirstChildOfClass("Humanoid")
 if hum then
  hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
  hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
  hum.EvaluateStateMachine=false
  hum.PlatformStand=true
 end
 model:SetAttribute("AttackAimOnly",true)
 model.Name="DisorderDecoy"
 return model
end
local decoys={}
function T.DecoySpawn(_,d)
 local g=E.Group("Disorder_Decoy")
 local model=d.Char and d.Char.Parent and cloneAvatar(d.Char)
 local state={G=g,Pos=d.CFrame.Position,Target=d.CFrame.Position,Model=model}
 decoys[d.Id]=state
 local groundOffset=0
 if model then
  local root=model:FindFirstChild("HumanoidRootPart")
  model.Parent=g.Folder
  root.Anchored=true
  root.CFrame=d.CFrame
  local torso=model:FindFirstChild("Torso")
  local motors={}
  if torso then
   for _,n in ipairs({"Right Hip","Left Hip","Right Shoulder","Left Shoulder"})do motors[n]=torso:FindFirstChild(n) end
  end
  local h=Instance.new("Highlight")
  h.DepthMode=Enum.HighlightDepthMode.Occluded h.FillTransparency=.45 h.OutlineTransparency=0 h.FillColor=MAG h.OutlineColor=CYAN h.Adornee=model h.Parent=model
  local ghosts={}
  for _,name in ipairs({"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"})do
   local src=model:FindFirstChild(name)
   if src then
    for e,col in ipairs({CYAN,MAG})do
     local p=P(g.Folder,src.Size*1.03,src.CFrame,col,NEON,.68,src:IsA("Part") and src.Shape or nil)
     ghosts[#ghosts+1]={P=p,Src=src,Dir=e==1 and -1 or 1}
    end
   end
  end
  state.Root=root
  local anchor=E.Anchor(g,d.CFrame)
  E.Stream(anchor,{tex="star.tiny",shape=Enum.ParticleEmitterShape.Box,size={{0,.45},{1,0}},color={{0,WHITE},{1,pick2(d.Id)}},life={.2,.5},speed={2,7},spread=180},40)
  E.Light(g,anchor,MAG,14,1.6)
  local stepNo,tearAt=-1,0
  local parts={}
  for _,x in ipairs(model:GetDescendants())do if x:IsA("BasePart") then parts[#parts+1]=x end end
  E.Step(g,function(dt,t)
   state.Pos=state.Pos:Lerp(state.Target,math.min(1,dt*9))
   local delta=state.Target-state.Pos
   local look=delta.Magnitude>.2 and flat(delta) or root.CFrame.LookVector
   local s=math.floor(t*14)
   local jit=Vector3.zero
   if s~=stepNo then
    stepNo=s
    h.FillColor=s%2==0 and MAG or CYAN
    h.OutlineColor=s%2==0 and CYAN or MAG
    h.FillTransparency=rand:NextNumber(.2,.7)
    if rand:NextNumber()<.3 then
     jit=Vector3.new(rand:NextNumber(-.7,.7),0,rand:NextNumber(-.7,.7))
     tearAt=t+.05
    end
    for _,x in ipairs(parts)do x.LocalTransparencyModifier=rand:NextNumber()<.08 and 1 or 0 end
   end
   root.CFrame=CFrame.lookAt(state.Pos+jit,state.Pos+jit+Vector3.new(look.X,0,look.Z))
   local swing=math.sin(t*11)*.85
   if motors["Right Hip"] then motors["Right Hip"].Transform=CFrame.Angles(0,0,swing) end
   if motors["Left Hip"] then motors["Left Hip"].Transform=CFrame.Angles(0,0,-swing) end
   if motors["Right Shoulder"] then motors["Right Shoulder"].Transform=CFrame.Angles(0,0,-swing*.7) end
   if motors["Left Shoulder"] then motors["Left Shoulder"].Transform=CFrame.Angles(0,0,swing*.7) end
   anchor.CFrame=root.CFrame
   local split=.25+(t<tearAt and .8 or math.abs(math.sin(t*7))*.2)
   for _,x in ipairs(ghosts)do x.P.CFrame=x.Src.CFrame+root.CFrame.RightVector*(x.Dir*split) end
  end)
 end
 E.After(g,(d.Life or 8)+1.5,function()if decoys[d.Id]==state then decoys[d.Id]=nil g:Destroy()end end)
end
function T.DecoyMove(_,d)
 local s=decoys[d.Id]
 if s then s.Target=d.Pos end
end
function T.DecoyFuse(_,d)
 local s=decoys[d.Id]
 if not s or not s.Root then return end
 local a=E.Anchor(s.G,s.Root.CFrame)
 E.Sprite(a,{tex="vortex.soft",size={{0,20},{1,1}},alpha={{0,.1},{1,.1}},color=MAG,spin={-700,-700}},.24)
 darkPlate(a,18,.24)
 local h=s.Model and s.Model:FindFirstChildOfClass("Highlight")
 if h then h.FillColor=WHITE h.OutlineColor=WHITE h.FillTransparency=0 end
end
function T.DecoyExplode(_,d)
 local s=decoys[d.Id]
 if s then decoys[d.Id]=nil s.G:Destroy() end
 local g=E.Group("Disorder_DecoyBlast")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 local r=d.Radius*2.1
 E.Sprite(a,{tex="burst.fringe",size={{0,6},{1,r*1.3}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE,rot={0,360}},.34)
 E.Sprite(a,{tex="flare.big",size={{0,6},{.2,r},{1,r*.6}},alpha={{0,0},{.5,.3},{1,1}},color=MAG},.42)
 E.Sprite(a,{tex="ring.thick",orient="flat",size={{0,r*.2},{1,r*1.1}},alpha={{0,.1},{.7,.4},{1,1}},color=CYAN},.5)
 for i=1,math.floor(24*E.Quality)do
  local s=rand:NextNumber(.5,1.9)
  local p=P(g.Folder,Vector3.one*s,CFrame.new(d.Pos),pick2(i),NEON,.05)
  local to=d.Pos+Vector3.new(rand:NextNumber(-1,1),rand:NextNumber(.2,1),rand:NextNumber(-1,1)).Unit*rand:NextNumber(6,d.Radius*1.1)
  E.Tween(p,.5,{CFrame=CFrame.new(to)*CFrame.Angles(rand:NextNumber(0,6),rand:NextNumber(0,6),0),Size=Vector3.one*.1,Transparency=1},Enum.EasingStyle.Quint)
 end
 E.Light(g,a,MAG,50,8,.4)
 E.After(g,1,function()g:Destroy()end)
end

local function triangle(folder,a,b,c,color,alpha,list,mat)
 local ab,ac,bc=b-a,c-a,c-b
 local abd,acd,bcd=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
 if abd>acd and abd>bcd then c,a=a,c elseif acd>bcd and acd>abd then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit
 local up=bc:Cross(right).Unit
 local back=bc.Unit
 local h=math.abs(ab:Dot(up))
 local function wedge(size,cf)
  local p=Instance.new("WedgePart")
  p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
  p.Material=mat or FIELD p.Color=color p.Transparency=alpha p.Size=size p.CFrame=cf p.Parent=folder
  if list then list[#list+1]=p end
 end
 wedge(Vector3.new(.05,h,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back))
 wedge(Vector3.new(.05,h,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back))
end
local zones={}
local function inZone(z,p)
 local d=p-z.Center
 local h=d.Y>=0 and z.Upper or z.Lower
 return math.abs(d.X)/z.Radius+math.abs(d.Z)/z.Radius+math.abs(d.Y)/h<=1
end
local function bar(folder,a,b,color,width)
 local len=(b-a).Magnitude
 return P(folder,Vector3.new(width,width,len),CFrame.lookAt((a+b)/2,b),color,NEON)
end
function T.ZoneOn(_,d)
 local g=E.Group("Disorder_Zone")
 local c,r=d.Center,d.Radius
 local X,Z=Vector3.new(r,0,0),Vector3.new(0,0,r)
 local ring={c+X,c+Z,c-X,c-Z}
 local top,bot=c+Vector3.new(0,d.Upper,0),c-Vector3.new(0,d.Lower,0)
 -- dark tinted glass reads against the bright sand; the old force field faces vanished on it
 local faces={}
 for i=1,4 do
  local a,b=ring[i],ring[i%4+1]
  triangle(g.Folder,top,a,b,i%2==0 and SLATE or Color3.fromRGB(70,28,110),.8,faces,PLASTIC)
 end
 for _,f in ipairs(faces)do f.Transparency=1 end
 -- edges: bright core on a dark outline, drawn out from the caster
 local bars={}
 local function edge(a,b,color,w)
  bars[#bars+1]={U=P(g.Folder,Vector3.new(w*1.9,w*1.9,1),nil,VOID,PLASTIC,.15),C=P(g.Folder,Vector3.new(w,w,1),nil,color,NEON),A=a,B=b}
 end
 for i=1,4 do
  edge(ring[i],ring[i%4+1],WHITE,1.1)
  edge(top,ring[i],pick2(i),.8)
 end
 local function place(k)
  for _,b in ipairs(bars)do
   local a2,b2=c+(b.A-c)*k,c+(b.B-c)*k
   local len=math.max(.2,(b2-a2).Magnitude)
   local f=CFrame.lookAt((a2+b2)/2,b2)
   b.C.Size=Vector3.new(b.C.Size.X,b.C.Size.Y,len) b.C.CFrame=f
   b.U.Size=Vector3.new(b.U.Size.X,b.U.Size.Y,len) b.U.CFrame=f
  end
 end
 place(.02)
 -- floor: the true radius, drawn on the ground so the edge is never a guess
 local fl=Vector3.new(0,-2.8,0)
 local floorParts={}
 for i=1,4 do triangle(g.Folder,c+fl,ring[i]+fl,ring[i%4+1]+fl,SLATE,.72,floorParts,PLASTIC) end
 for _,band in ipairs({1,.68,.36})do
  for i=1,4 do
   local a,b=c+fl+(ring[i]-c)*band,c+fl+(ring[i%4+1]-c)*band
   local p=bar(g.Folder,a+Vector3.new(0,.08,0),b+Vector3.new(0,.08,0),band==1 and WHITE or pick2(i),band==1 and .7 or .28)
   floorParts[#floorParts+1]=p
  end
 end
 local gems={}
 for i,p in ipairs({ring[1],ring[2],ring[3],ring[4],top})do
  gems[i]={Dark=P(g.Folder,Vector3.one*6,CFrame.new(p),VOID,PLASTIC,.1),Core=P(g.Folder,Vector3.one*3.6,CFrame.new(p),i==5 and WHITE or pick2(i),NEON),At=p}
 end
 local topA=E.Anchor(g,CFrame.new(top))
 E.Sprite(topA,{tex="star.lens",size={{0,1},{.03,34},{1,34}},alpha=.2,color=WHITE,spin={30,30}},d.Duration)
 E.Light(g,topA,MAG,90,4)
 local rain=E.Anchor(g,CFrame.new(c+Vector3.new(0,d.Upper*.55,0)))
 rain.Size=Vector3.new(r*1.1,d.Upper*.7,r*1.1)
 E.Stream(rain,{tex="glitch.block",shape=Enum.ParticleEmitterShape.Box,size={{0,.7},{1,.25}},alpha={{0,.25},{.8,.4},{1,1}},color={{0,CYAN},{1,MAG}},life={1,2},speed={18,40},dir=Enum.NormalId.Bottom,spread=4,rot={0,0}},46)
 local scan={}
 for i=1,4 do scan[i]=P(g.Folder,Vector3.new(.5,.5,1),nil,WHITE,NEON,.05) end
 local z={Id=d.Id,G=g,Center=c,Radius=r,Upper=d.Upper,Lower=d.Lower,Hidden={},NextScan=0,Faces=faces,Hit=0}
 zones[d.Id]=z
 local a=E.Anchor(g,CFrame.new(c+Vector3.new(0,8,0)))
 darkPlate(a,r*2.2,.5)
 E.Sprite(a,{tex="burst.white",size={{0,12},{1,r*3.4}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE,rot={0,360}},.42)
 E.Sprite(a,{tex="ring.thick",orient="flat",size={{0,10},{1,r*3.6}},alpha={{0,.1},{.7,.35},{1,1}},color=MAG},.55)
 local stepNo,formed=-1,false
 E.Step(g,function(_,t)
  if not formed then
   local k=math.clamp(t/.5,0,1)
   place(.02+.98*(1-(1-k)^3))
   if k>=1 then
    formed=true
    for _,f in ipairs(faces)do f.Transparency=.8 end
   end
  end
  local h=(math.sin(t*1.1)+1)/2*d.Upper*.9
  local rad=r*(1-h/d.Upper)
  local pts={c+Vector3.new(rad,h,0),c+Vector3.new(0,h,rad),c+Vector3.new(-rad,h,0),c+Vector3.new(0,h,-rad)}
  for i=1,4 do
   local p,q=pts[i],pts[i%4+1]
   scan[i].Size=Vector3.new(.5,.5,math.max(.2,(q-p).Magnitude))
   scan[i].CFrame=CFrame.lookAt((p+q)/2,q)
  end
  for i,gem in ipairs(gems)do
   local f=CFrame.new(gem.At)*CFrame.Angles(t*.9+i,t*1.3,0)*CFrame.Angles(math.rad(45),0,math.atan(1/math.sqrt(2)))
   gem.Dark.CFrame=f gem.Core.CFrame=f
  end
  local s2=math.floor(t*14)
  if s2~=stepNo then
   stepNo=s2
   local struck=os.clock()-z.Hit<.2
   if formed then for _,f in ipairs(faces)do f.Transparency=struck and .45 or (rand:NextNumber()<.05 and .55 or .8) end end
   for _,b in ipairs(bars)do b.C.Transparency=rand:NextNumber()<.03 and .7 or 0 end
  end
 end)
end
function T.ZonePulse(_,d)
 local z=zones[d.Id]
 if not z then return end
 local a=E.Anchor(z.G,CFrame.new(z.Center+Vector3.new(0,5,0)))
 E.Sprite(a,{tex="ring.crisp",orient="flat",size={{0,6},{1,z.Radius*2.6}},alpha={{0,.05},{.7,.35},{1,1}},color=WHITE},.5)
 local bb=Instance.new("BillboardGui")
 bb.Size=UDim2.fromOffset(280,44) bb.AlwaysOnTop=true bb.StudsOffset=Vector3.new(0,5,0) bb.Parent=a
 local t=Instance.new("TextLabel")
 t.BackgroundTransparency=1 t.Size=UDim2.fromScale(1,1) t.Font=Enum.Font.Arcade t.TextScaled=true t.Text=d.Name t.TextColor3=CYAN t.TextStrokeTransparency=.2 t.Parent=bb
 Tween:Create(bb,TweenInfo.new(1.4),{StudsOffset=Vector3.new(0,12,0)}):Play()
 Tween:Create(t,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{TextTransparency=1,TextStrokeTransparency=1}):Play()
 Debris:AddItem(a,1.6)
end
function T.ZoneOff(_,d)
 local z=zones[d.Id]
 if not z then return end
 zones[d.Id]=nil
 for inst in pairs(z.Hidden)do pcall(function()inst.LocalTransparencyModifier=0 end) end
 local a=E.Anchor(z.G,CFrame.new(z.Center+Vector3.new(0,8,0)))
 E.Sprite(a,{tex="burst.fringe",size={{0,8},{1,z.Radius*3.4}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE,rot={0,360}},.4)
 z.G:Fade(.3)
end
 -- anything the boss put inside a zone stops being drawn, locally, without touching his attack code
local CLASS_PREFIX={"Disorder","TW_","Twin","Class"}
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
local function bossFx(p)
 local root=workspace:FindFirstChild("VFXEngineLocal")
 if root and p:IsDescendantOf(root) then
  local a=p
  while a.Parent~=root do a=a.Parent end
  for _,pre in ipairs(CLASS_PREFIX)do if a.Name:sub(1,#pre)==pre then return false end end
 end
 return true
end
local function eraseStep()
 local now=os.clock()
 for _,z in pairs(zones)do
  if now>=z.NextScan then
   z.NextScan=now+.1
   local list={}
   for _,n in ipairs({"GoldenCombatEffects","VFXEngineLocal"})do
    local f=workspace:FindFirstChild(n)
    if f then list[#list+1]=f end
   end
   overlap.FilterDescendantsInstances=list
   local box=CFrame.new(z.Center+Vector3.new(0,(z.Upper-z.Lower)/2,0))
   local ok,parts=pcall(function()return workspace:GetPartBoundsInBox(box,Vector3.new(z.Radius*2,z.Upper+z.Lower,z.Radius*2),overlap)end)
   if ok then
    for _,p in ipairs(parts)do
     if bossFx(p) and p.Transparency<1 and not z.Hidden[p] then
      local longest=math.max(p.Size.X,p.Size.Y,p.Size.Z)
      if longest<=36 and inZone(z,p.Position) then
       z.Hidden[p]=true
       z.Hit=os.clock()
       p.LocalTransparencyModifier=1
       for _,c in ipairs(p:GetChildren())do
        if c:IsA("ParticleEmitter") or c:IsA("Trail") or c:IsA("Beam") or c:IsA("PointLight") then c.Enabled=false end
       end
       local a=E.Anchor(z.G,CFrame.new(p.Position))
       E.Sprite(a,{tex="burst.fringe",size={{0,1},{1,7}},alpha={{0,0},{1,1}},color=WHITE,rot={0,360}},.18)
       Debris:AddItem(a,.3)
      elseif longest>36 then
       -- a beam passing through: spark where it meets the shell
       local cf=p.CFrame
       local axis=p.Size.Z>=p.Size.X and p.Size.Z>=p.Size.Y and cf.LookVector or (p.Size.X>=p.Size.Y and cf.RightVector or cf.UpVector)
       for i=-1,1,.1 do
        local q=p.Position+axis*(longest/2)*i
        if inZone(z,q) then
         local a=E.Anchor(z.G,CFrame.new(q))
         E.Emit(a,{tex="dot",orient="velocity",squash={{0,3},{1,0}},size={{0,.5},{1,0}},color={{0,WHITE},{1,CYAN}},life={.12,.3},speed={25,60},spread=180},3)
         Debris:AddItem(a,.4)
         break
        end
       end
      end
     end
    end
   end
  end
 end
end
Run.Heartbeat:Connect(eraseStep)

local cubes={}
local function diamondCube(folder,size)
 local outer=P(folder,Vector3.one*size,nil,MAG,NEON,.55)
 local mid=P(folder,Vector3.one*size*.8,nil,CYAN,NEON,.55)
 local core=P(folder,Vector3.one*size*.46,nil,WHITE,NEON,0)
 local edges={}
 local half=size*.52
 local signs={{1,1},{1,-1},{-1,1},{-1,-1}}
 for axis=1,3 do
  for _,s in ipairs(signs)do
   local dim=axis==1 and Vector3.new(size,.1,.1) or axis==2 and Vector3.new(.1,size,.1) or Vector3.new(.1,.1,size)
   local off=axis==1 and Vector3.new(0,s[1]*half,s[2]*half) or axis==2 and Vector3.new(s[1]*half,0,s[2]*half) or Vector3.new(s[1]*half,s[2]*half,0)
   edges[#edges+1]={P(folder,dim,nil,WHITE,NEON,0),off}
  end
 end
 return function(cf,scale)
  local spun=cf
  local s=scale or 1
  outer.Size=Vector3.one*size*s mid.Size=Vector3.one*size*.8*s core.Size=Vector3.one*size*.46*s
  outer.CFrame=spun mid.CFrame=spun*CFrame.Angles(.7,.4,.2) core.CFrame=spun
  for _,e in ipairs(edges)do e[1].CFrame=spun*CFrame.new(e[2]*s) end
 end
end
 -- a block standing on one corner reads as a diamond
local CORNER=CFrame.Angles(math.rad(45),0,math.atan(1/math.sqrt(2)))
function T.CubeCharge(_,d)
 setMode(d.Char,"Forge")
 local c,g=newCast(d.Char,"CubeForge",12)
 local draw=diamondCube(g.Folder,3)
 local a=E.Anchor(g)
 E.Stream(a,{tex="star.tiny",shape=Enum.ParticleEmitterShape.Sphere,style=Enum.ParticleEmitterShapeStyle.Surface,inout=Enum.ParticleEmitterShapeInOut.Inward,size={{0,.7},{1,0}},color={{0,WHITE},{1,MAG}},life={.2,.4},speed={12,24}},110)
 E.Light(g,a,MAG,22,4)
 c.Scale=0
 E.Step(g,function(dt,t)
  local root=rootOf(d.Char)
  if not root then return false end
  c.Scale=math.min(1,c.Scale+dt*2.4)
  local pos=(root.CFrame*CFrame.new(0,3,-6)).Position
  c.Pos=pos
  a.CFrame=CFrame.new(pos)
  draw(CFrame.new(pos)*CFrame.Angles(0,t*3,0)*CORNER,c.Scale)
 end)
end
function T.CubeCancel(_,d)
 finishCast(d.Char)
 setMode(d.Char,"Idle")
end
function T.CubeThrow(_,d)
 finishCast(d.Char)
 setMode(d.Char,"Idle")
 pulse(d.Char,1,1) pulse(d.Char,-1,1)
 local g=E.Group("Disorder_Cube")
 local draw=diamondCube(g.Folder,3)
 local a=E.Anchor(g,CFrame.new(d.Origin))
 local a0,a1=E.Attach(a,CFrame.new(0,1.5,0)),E.Attach(a,CFrame.new(0,-1.5,0))
 local trail=Instance.new("Trail")
 trail.Attachment0,trail.Attachment1=a0,a1 trail.Lifetime=.35 trail.LightEmission=1 trail.FaceCamera=true
 trail.Color=ColorSequence.new(MAG,CYAN)
 trail.Transparency=NumberSequence.new(.2,1) trail.Parent=a
 E.Light(g,a,CYAN,24,4)
 E.Stream(a,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,WHITE},{1,CYAN}},life={.2,.45},speed={1,5},spread=180},50)
 local state={G=g,Pos=d.Origin}
 cubes[d.Id]=state
 local start=os.clock()
 E.Step(g,function(dt,t)
  local el=os.clock()-start
  local travelled=math.min(d.Range,d.Speed*el)
  local p=d.Origin+d.Dir*travelled
  state.Pos=p
  a.CFrame=CFrame.new(p)
  draw(CFrame.new(p)*CFrame.Angles(t*8,t*11,t*5)*CORNER,1)
  if el>d.Range/d.Speed+1 then return false end
 end)
end
local function glitchBlast(pos,radius,heavy)
 local g=E.Group("Disorder_Blast")
 local a=E.Anchor(g,CFrame.new(pos))
 local d=radius*2
 -- frame one: a black well with a white rim, so the flash lands on the impact frame and reads on bright ground
 local well=P(g.Folder,Vector3.one*d*.34,CFrame.new(pos),VOID,PLASTIC,.02,BALL)
 local rim=P(g.Folder,Vector3.one*d*.4,CFrame.new(pos),WHITE,NEON,.15,BALL)
 E.Tween(well,.42,{Size=Vector3.one*d*.08,Transparency=1},Enum.EasingStyle.Quint)
 E.Tween(rim,.34,{Size=Vector3.one*d*1.05,Transparency=1},Enum.EasingStyle.Quint)
 darkPlate(a,d*1.5,.5)
 E.Sprite(a,{tex="burst.white",size={{0,d*.25},{1,d*1.3}},alpha={{0,0},{.45,.15},{1,1}},color=WHITE,rot={0,360}},.4)
 E.Sprite(a,{tex="burst.fringe",size={{0,d*.3},{1,d*1.6}},alpha={{0,.1},{.6,.25},{1,1}},color=WHITE,rot={0,360}},.5)
 local groundY=E.Ground(pos+UP*6)
 local floor=E.Anchor(g,CFrame.new(pos.X,(groundY and groundY.Y or pos.Y-3)+.4,pos.Z))
 E.Sprite(floor,{tex="ring.thick",orient="flat",size={{0,d*.2},{1,d*1.4}},alpha={{0,0},{.6,.25},{1,1}},color=WHITE},.5)
 E.Sprite(floor,{tex="ring.thick",orient="flat",light=0,size={{0,d*.24},{1,d*1.5}},alpha={{0,.15},{.7,.4},{1,1}},color=VOID},.56)
 datamosh(g,pos+UP*radius*.25,d*.9,radius*1.5,.55,heavy and 22 or 14)
 -- voxels thrown out and falling, dark ones among the bright so the cloud has shape
 for i=1,math.floor((heavy and 80 or 46)*E.Quality)do
  local s=rand:NextNumber(.7,3.4)
  local dark=i%3==0
  local p=P(g.Folder,Vector3.one*s,CFrame.new(pos),dark and VOID or pick2(i),dark and PLASTIC or NEON,.03)
  local to=pos+Vector3.new(rand:NextNumber(-1,1),rand:NextNumber(.1,1),rand:NextNumber(-1,1)).Unit*rand:NextNumber(radius*.35,radius*1.2)
  E.Tween(p,.7,{CFrame=CFrame.new(to-UP*rand:NextNumber(0,6))*CFrame.Angles(rand:NextNumber(0,6),rand:NextNumber(0,6),0),Size=Vector3.one*.1},Enum.EasingStyle.Quint)
 end
 E.Light(g,a,MAG,radius*3,10,.5)
 play(SFX.Boom,pos,1.2,1.25)
 E.After(g,1.5,function()g:Destroy()end)
end
function T.CubeExplode(_,d)
 local s=cubes[d.Id]
 if s then cubes[d.Id]=nil s.G:Destroy() end
 glitchBlast(d.Pos,d.Radius,false)
end

local marks={}
local function clearMarks(owner)
 local g=marks[owner]
 if g then marks[owner]=nil g:Fade(.25) end
end
function T.CheckpointSet(_,d)
 clearMarks(d.Owner)
 local g=E.Group("Disorder_Checkpoint")
 marks[d.Owner]=g
 for i,m in ipairs(d.Marks or {})do
  local ground=E.Ground(m.Pos+Vector3.new(0,5,0)) or m.Pos-Vector3.new(0,3,0)
  local base=E.Anchor(g,CFrame.new(ground+Vector3.new(0,.2,0)))
  E.Sprite(base,{tex="sigil.ring",orient="flat",size={{0,3},{.03,11},{1,11}},alpha={{0,1},{.03,.25},{1,.25}},color=CYAN,spin={40,40}},3600)
  local top=E.Anchor(g,CFrame.new(ground+Vector3.new(0,24,0)))
  local beam=E.Beam(g,E.Attach(base),E.Attach(top),{tex="beam.dots",length=8,scroll=8,width=1.4,color={{0,CYAN},{1,MAG}},alpha={{0,.15},{1,1}},brightness=2,segments=2})
  local gem=P(g.Folder,Vector3.one*1.8,CFrame.new(ground+Vector3.new(0,6.5,0))*CORNER,MAG,NEON,.1)
  local gem2=P(g.Folder,Vector3.one*1.1,gem.CFrame,WHITE,NEON)
  local bb=Instance.new("BillboardGui")
  bb.Size=UDim2.fromOffset(200,26) bb.AlwaysOnTop=true bb.StudsOffset=Vector3.new(0,3,0) bb.MaxDistance=260 bb.Parent=gem
  local t=Instance.new("TextLabel")
  t.BackgroundTransparency=1 t.Size=UDim2.fromScale(1,1) t.Font=Enum.Font.Arcade t.TextScaled=true t.Text="CHECKPOINT // "..m.Name t.TextColor3=CYAN t.TextStrokeTransparency=.3 t.Parent=bb
  E.Step(g,function(_,clock)
   local cf=CFrame.new(ground+Vector3.new(0,6.5+math.sin(clock*2+i)*.5,0))*CFrame.Angles(0,clock*1.4,0)*CORNER
   gem.CFrame=cf gem2.CFrame=cf*CFrame.Angles(0,.8,0)
  end)
  E.Sprite(base,{tex="burst.fringe",size={{0,3},{1,18}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE,rot={0,360}},.35)
 end
end
function T.CheckpointClear(_,d)clearMarks(d.Owner)end
function T.CheckpointReload(_,d)
 clearMarks(d.Owner)
 local g=E.Group("Disorder_Reload")
 for _,m in ipairs(d.Marks or {})do
  local a=E.Anchor(g,CFrame.new(m.Pos))
  E.Sprite(a,{tex="vortex.soft",size={{0,18},{1,0}},alpha={{0,.1},{1,1}},color=CYAN,spin={-520,-520}},.45)
  E.Sprite(a,{tex="burst.fringe",size={{0,3},{1,24}},alpha={{0,.1},{.6,.2},{1,1}},color=WHITE,rot={0,360}},.4)
  E.Emit(a,{tex="star.tiny",size={{0,.9},{1,0}},color={{0,WHITE},{1,MAG}},life={.3,.55},speed={25,60},spread=180},30)
  E.Light(g,a,CYAN,28,6,.4)
 end
 screenFlash(CYAN,.72,.25)
 E.After(g,1,function()g:Destroy()end)
end

function T.ArenaCharge(_,d)
 setMode(d.Char,"Spread")
 local root=rootOf(d.Char)
 if not root then return end
 local c,g=newCast(d.Char,"ArenaCharge",d.Duration+1)
 local h=Instance.new("Highlight")
 h.FillColor=MAG h.OutlineColor=CYAN h.FillTransparency=.3 h.OutlineTransparency=0 h.Adornee=d.Char h.Parent=g.Folder
 local a=E.Anchor(g,root.CFrame)
 E.Stream(a,{tex="star.tiny",shape=Enum.ParticleEmitterShape.Sphere,style=Enum.ParticleEmitterShapeStyle.Surface,inout=Enum.ParticleEmitterShapeInOut.Inward,size={{0,.8},{1,0}},color={{0,WHITE},{1,CYAN}},life={.25,.45},speed={18,30}},120)
 E.Light(g,a,MAG,30,5)
 -- anticipation: the air is sucked in toward the caster, and the floor goes dark around them
 local gy=E.Ground(root.Position+UP*5)
 local floor=E.Anchor(g,CFrame.new(root.Position.X,(gy and gy.Y or root.Position.Y-3)+.3,root.Position.Z))
 E.Sprite(floor,{tex="disc.soft",orient="flat",light=0,size={{0,70},{1,18}},alpha={{0,.75},{.8,.3},{1,1}},color=VOID},d.Duration)
 E.Sprite(floor,{tex="ring.ticked",orient="flat",size={{0,90},{1,8}},alpha={{0,.5},{.9,.1},{1,1}},color=WHITE,spin={260,260}},d.Duration)
 E.Sprite(floor,{tex="ring.crisp",orient="flat",size={{0,120},{1,6}},alpha={{0,.6},{.9,.15},{1,1}},color=MAG,spin={-180,-180}},d.Duration)
 local stepNo=-1
 local parts={}
 for _,x in ipairs(d.Char:GetChildren())do if x:IsA("BasePart") and x.Name~="HumanoidRootPart" then parts[#parts+1]=x end end
 c.Restore[#c.Restore+1]=function()for _,x in ipairs(parts)do if x.Parent then x.LocalTransparencyModifier=0 end end end
 E.Step(g,function(_,t)
  if not root.Parent then return false end
  a.CFrame=root.CFrame
  local s=math.floor(t*16)
  if s~=stepNo then
   stepNo=s
   h.FillColor=s%2==0 and MAG or CYAN
   h.OutlineColor=s%2==0 and WHITE or MAG
   h.FillTransparency=rand:NextNumber(.05,.6)
   for _,x in ipairs(parts)do x.LocalTransparencyModifier=rand:NextNumber()<.14 and 1 or 0 end
  end
 end)
 if isLocal(d.Char)then screenGlitch(true) task.delay(d.Duration,function()screenGlitch(false)end) end
end
function T.ArenaGlitch(_,d)
 finishCast(d.Char)
 setMode(d.Char,"Idle")
 local g=E.Group("Disorder_Arena")
 local c=d.Center
 local R=235
 -- frame one: a black well and a white flash on the release frame
 local a=E.Anchor(g,CFrame.new(c+UP*.5))
 local well=P(g.Folder,Vector3.one*40,CFrame.new(c),VOID,PLASTIC,.02,BALL)
 E.Tween(well,.5,{Size=Vector3.one*R*2,Transparency=1},Enum.EasingStyle.Quint)
 E.Sprite(a,{tex="burst.white",size={{0,30},{1,R*1.4}},alpha={{0,0},{.45,.2},{1,1}},color=WHITE,rot={0,360}},.42)
 E.Sprite(a,{tex="ring.thick",orient="flat",size={{0,20},{1,R*2.2}},alpha={{0,.05},{.8,.3},{1,1}},color=WHITE},.9)
 E.Sprite(a,{tex="ring.thick",orient="flat",light=0,size={{0,24},{1,R*2.3}},alpha={{0,.15},{.85,.4},{1,1}},color=VOID},.95)
 E.Light(g,a,MAG,140,12,.7)
 wireDome(g,c,R,1.15,MAG)
 task.delay(.12,function()if g.Alive then wireDome(g,c,R*.72,1,CYAN) end end)
 -- the arena itself: sampled once, then reused by every layer
 local points={}
 for i=1,110 do
  local p=c+Vector3.new(rand:NextNumber(-200,200),8,rand:NextNumber(-200,200))
  local ground=E.Ground(p)
  if ground then points[#points+1]=ground end
 end
 pixelPillars(g,points,26,d.Duration,70)
 skyTears(g,points,14,d.Duration)
 -- floor: dark panels with lit ones among them, so the corruption has pattern instead of glow
 local tiles={}
 for i=1,math.floor(64*E.Quality)do
  local sz=rand:NextNumber(5,20)
  local dark=i%2==0
  tiles[i]={P=P(g.Folder,Vector3.new(sz,.14,sz),nil,dark and VOID or pick2(i),dark and PLASTIC or NEON,1),Dark=dark}
 end
 local nextTile=0
 E.Step(g,function()
  local now=os.clock()
  if now<nextTile or #points==0 then return end
  nextTile=now+1/14
  for _,x in ipairs(tiles)do
   if rand:NextNumber()<.26 then
    x.P.CFrame=CFrame.new(points[rand:NextInteger(1,#points)]+UP*.14)
    x.P.Transparency=x.Dark and rand:NextNumber(.05,.3) or rand:NextNumber(.1,.45)
   elseif rand:NextNumber()<.22 then x.P.Transparency=1 end
  end
 end)
 screenFlash(WHITE,.55,.22)
 screenGlitch(true)
 colorShift(Color3.fromRGB(206,200,255),-.62,.28,.15,-.08)
 local cold=true
 task.spawn(function()
  local ends=os.clock()+d.Duration
  while os.clock()<ends and g.Alive do
   cold=not cold
   colorShift(cold and Color3.fromRGB(206,200,255) or Color3.fromRGB(244,190,235),-.62,.28,.12,-.08)
   task.wait(.42)
  end
 end)
 E.After(g,d.Duration,function()
  screenGlitch(false)
  colorReset(.5)
  g:Fade(.3)
 end)
end
 -- each random-damage tick lands on the boss as a visible hit, with a corrupted readout
local HEX="0123456789ABCDEF"
local function errorCode()
 local t={}
 for i=1,4 do local n=rand:NextInteger(1,16) t[i]=HEX:sub(n,n) end
 return "0x"..table.concat(t)
end
function T.ArenaStrike(_,d)
 local g=E.Group("Disorder_Strike")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 darkPlate(a,16,.2)
 E.Sprite(a,{tex="burst.fringe",size={{0,5},{1,22}},alpha={{0,0},{.5,.2},{1,1}},color=WHITE,rot={0,360}},.22)
 datamosh(g,d.Pos,12,18,.32,8)
 local top=E.Anchor(g,CFrame.new(d.Pos+UP*90))
 local beam=E.Beam(g,E.Attach(top),E.Attach(a),{tex="beam.core",mode=Enum.TextureMode.Stretch,width=2,color={{0,CYAN},{1,WHITE}},brightness=3,segments=2})
 E.Tween(beam,.16,{Width0=0,Width1=0})
 local bb=Instance.new("BillboardGui")
 bb.Size=UDim2.fromOffset(170,30) bb.AlwaysOnTop=true bb.StudsOffset=Vector3.new(rand:NextNumber(-4,4),rand:NextNumber(3,8),0) bb.Parent=a
 local t=Instance.new("TextLabel")
 t.BackgroundTransparency=1 t.Size=UDim2.fromScale(1,1) t.Font=Enum.Font.Arcade t.TextScaled=true t.Text=errorCode() t.TextColor3=rand:NextNumber()<.5 and CYAN or MAG t.TextStrokeTransparency=.2 t.Parent=bb
 E.After(g,.55,function()g:Destroy()end)
end

local BODY={"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
local bossRig
local function dropBossRig()
 if bossRig then bossRig.Group:Destroy() bossRig=nil end
end
local function bossModel()return workspace:FindFirstChild("alterGolden, the Nothing")end
local function buildBossRig(boss)
 local g=E.Group("Disorder_BossGlitch")
 local list={}
 for _,name in ipairs(BODY)do
  local src=boss:FindFirstChild(name)
  if src and src:IsA("BasePart") then
   for e,col in ipairs({CYAN,MAG})do
    list[#list+1]={P=P(g.Folder,src.Size*1.05,src.CFrame,col,NEON,1),Src=src,Dir=e==1 and -1 or 1}
   end
  end
 end
 local slices={}
 for i=1,4 do slices[i]=P(g.Folder,Vector3.new(4.6,.09,3),nil,pick2(i),NEON,1) end
 local a=E.Attach(boss:FindFirstChild("HumanoidRootPart"))
 local dust=E.Stream(a,{tex="star.tiny",shape=Enum.ParticleEmitterShape.Box,size={{0,.5},{1,0}},color={{0,WHITE},{1,MAG}},life={.25,.5},speed={3,9},spread=180},0)
 local bb=Instance.new("BillboardGui")
 bb.Name="DisorderTags" bb.Size=UDim2.fromOffset(220,88) bb.StudsOffset=Vector3.new(0,6.5,0) bb.AlwaysOnTop=true bb.Adornee=boss:FindFirstChild("Head") or boss.PrimaryPart bb.Parent=g.Folder
 local tags=Instance.new("TextLabel")
 tags.BackgroundTransparency=1 tags.Size=UDim2.fromScale(1,1) tags.Font=Enum.Font.Arcade tags.TextSize=15 tags.TextColor3=MAG tags.TextStrokeTransparency=.3 tags.TextYAlignment=Enum.TextYAlignment.Bottom tags.Text="" tags.Parent=bb
 bossRig={Group=g,Boss=boss,List=list,Slices=slices,Dust=dust,Tags=tags,Att=a}
 g.Conns[#g.Conns+1]=g.Folder.Destroying:Connect(function()if a.Parent then a:Destroy() end end)
end
local nextBossScan,bossSteps=0,-1
Run.RenderStepped:Connect(function()
 local now=os.clock()
 local boss=bossRig and bossRig.Boss
 if now>=nextBossScan then
  nextBossScan=now+.15
  local model=bossModel()
  local server=workspace:GetServerTimeNow()
  local on=model and server<(model:GetAttribute("DisorderGlitchUntil") or 0)
  local listed={}
  if model then
   for name,deadline in pairs(model:GetAttributes())do
    if name:sub(1,15)=="DisorderDebuff_" and type(deadline)=="number" and server<deadline then
     listed[#listed+1]=name:sub(16)
     on=true
    end
   end
  end
  if on and (not bossRig or bossRig.Boss~=model) then dropBossRig() if rootOf(model) then buildBossRig(model) end end
  if not on and bossRig then dropBossRig() end
  if bossRig then
   table.sort(listed)
   bossRig.Tags.Text=table.concat(listed,"\n")
   local stacks=model:GetAttribute("DisorderGlitchStacks") or 1
   bossRig.Intensity=math.clamp(stacks/8,.25,1)
   bossRig.Dust.Rate=(14+70*bossRig.Intensity)*E.Quality
   bossRig.Dust.Enabled=true
  end
  boss=bossRig and bossRig.Boss
 end
 if bossRig and boss and boss.Parent then
  local s=math.floor(now*14)
  local fresh=s~=bossSteps
  bossSteps=s
  local g=bossRig.Intensity or .4
  local root=boss:FindFirstChild("HumanoidRootPart")
  if root then
   for _,x in ipairs(bossRig.List)do
    if x.Src.Parent then
     if fresh then
      x.Off=(rand:NextNumber()<.25 and rand:NextNumber(.8,2.4) or rand:NextNumber(.15,.5))*g
      x.P.Transparency=rand:NextNumber()<.12 and 1 or rand:NextNumber(.45,.75)
     end
     x.P.CFrame=x.Src.CFrame+root.CFrame.RightVector*(x.Dir*(x.Off or .3))
    end
   end
   if fresh then
    for _,p in ipairs(bossRig.Slices)do
     if rand:NextNumber()<.5*g then
      p.CFrame=root.CFrame*CFrame.new(rand:NextNumber(-1,1),rand:NextNumber(-3,3.4),rand:NextNumber(-.5,.5))
      p.Transparency=rand:NextNumber(.1,.5)
     else p.Transparency=1 end
    end
   end
  end
 end
end)
function T.BossDebuff(_,d)
 local target=d.Target
 local root=rootOf(target)
 if not root then return end
 local g=E.Group("Disorder_Debuff")
 local a=E.Anchor(g,root.CFrame)
 E.Sprite(a,{tex="burst.fringe",size={{0,3},{1,14}},alpha={{0,0},{.5,.25},{1,1}},color=WHITE,rot={0,360}},.25)
 E.After(g,.6,function()g:Destroy()end)
end

local TESS,TESS_E={},{}
for i=0,15 do
 TESS[i+1]={bit32.band(i,1)==0 and -1 or 1,bit32.band(i,2)==0 and -1 or 1,bit32.band(i,4)==0 and -1 or 1,bit32.band(i,8)==0 and -1 or 1}
end
for i=0,15 do
 for b=0,3 do
  local j=bit32.bxor(i,bit32.lshift(1,b))
  if i<j then TESS_E[#TESS_E+1]={i+1,j+1} end
 end
end
local function rot4(v,a,b,angle)
 local c,s=math.cos(angle),math.sin(angle)
 local x,y=v[a],v[b]
 v[a]=x*c-y*s
 v[b]=x*s+y*c
end
local function buildFourD(folder)
 local layers={}
 local specs=E.Quality<.6 and {{WHITE,1,0,0}} or {{CYAN,1.25,.3,-1},{MAG,1.25,.3,1},{WHITE,1,0,0}}
 for l,spec in ipairs(specs)do
  local bars={}
  for i=1,#TESS_E do bars[i]=P(folder,Vector3.new(.3,.3,1),nil,spec[1],spec[1]==VOID and PLASTIC or NEON,spec[3]) end
  layers[l]={Bars=bars,Offset=spec[4],Thick=spec[2]}
 end
 local void=P(folder,Vector3.one,nil,BLACK,PLASTIC,0,BALL)
 local shell1=P(folder,Vector3.one,nil,MAG,NEON,.84,BALL)
 local shell2=P(folder,Vector3.one,nil,CYAN,NEON,.9,BALL)
 return function(center,radius,t,chroma)
  local stepped=math.floor(t*16)/16  -- runs at 16fps: reality is dropping frames
  local pts={}
  for i,v in ipairs(TESS)do
   local q={v[1],v[2],v[3],v[4]}
   rot4(q,1,4,stepped*1.15)
   rot4(q,2,4,stepped*.82)
   rot4(q,3,4,stepped*.55)
   rot4(q,1,2,stepped*.3)
   local k=1/(2.6-q[4])
   pts[i]=Vector3.new(q[1]*k,q[2]*k,q[3]*k)*radius*1.3
  end
  for _,layer in ipairs(layers)do
   local off=Vector3.new(layer.Offset*chroma,layer.Offset*chroma*.4,0)
   local thick=math.clamp(radius*.03,.14,1.7)*layer.Thick
   for i,e in ipairs(TESS_E)do
    local a,b=center+pts[e[1]]+off,center+pts[e[2]]+off
    local bar=layer.Bars[i]
    bar.Size=Vector3.new(thick,thick,math.max(.1,(b-a).Magnitude))
    bar.CFrame=CFrame.lookAt((a+b)/2,b)
   end
  end
  -- the core is a slice of a 3-sphere passing through our space: it swells and thins as it moves along the fourth axis
  local w=math.sin(stepped*1.9)
  local slice=math.sqrt(math.max(.05,1-w*w*.75))
  void.Size=Vector3.one*radius*1.05*slice void.CFrame=CFrame.new(center)
  shell1.Size=Vector3.one*radius*1.2*slice shell1.CFrame=CFrame.new(center+Vector3.new(chroma,0,0))
  shell2.Size=Vector3.one*radius*1.28*slice shell2.CFrame=CFrame.new(center-Vector3.new(chroma,0,0))
 end
end
local GOLDT=Color3.fromRGB(255,214,110)
local LEAF=Color3.fromRGB(120,235,140)
local STAR=Color3.fromRGB(125,150,255)
 -- throw something from `from` into the sphere; it dies on arrival
local function consume(g,part,sky,life)
 E.Tween(part,life,{CFrame=CFrame.new(sky)*CFrame.Angles(rand:NextNumber(0,6),rand:NextNumber(0,6),0),Size=part.Size*.15},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 task.delay(life,function()if part.Parent then part:Destroy() end end)
end
local function sourceSpace(g,sky,ground,duration)
 -- comets from the edge of the sky, and three moons torn in
 local n=math.floor(44*E.Quality)
 for i=1,n do
  E.After(g,duration*(i/n)*.8,function()
   local a=rand:NextNumber(0,math.pi*2)
   local from=sky+Vector3.new(math.cos(a)*rand:NextNumber(200,340),rand:NextNumber(-20,130),math.sin(a)*rand:NextNumber(200,340))
   local dir=(sky-from).Unit
   local p=P(g.Folder,Vector3.new(.5,.5,rand:NextNumber(14,34)),CFrame.lookAt(from,from+dir),i%3==0 and WHITE or STAR,NEON,.05)
   E.Tween(p,.65,{CFrame=CFrame.lookAt(sky,sky+dir),Size=Vector3.new(.2,.2,3)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
   task.delay(.65,function()p:Destroy()end)
  end)
 end
 for i=1,3 do
  E.After(g,duration*(i-1)*.28,function()
   local a=i*2.1
   local from=sky+Vector3.new(math.cos(a)*190,70-i*18,math.sin(a)*190)
   local moon=P(g.Folder,Vector3.one*rand:NextNumber(22,34),CFrame.new(from),SLATE,PLASTIC,0,BALL)
   local rim=P(moon,moon.Size*1.08,CFrame.new(from),STAR,NEON,.72,BALL)
   local t2=duration*.55
   E.Tween(moon,t2,{CFrame=CFrame.new(sky),Size=Vector3.one*2},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
   E.Tween(rim,t2,{CFrame=CFrame.new(sky),Size=Vector3.one*2.4},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
   task.delay(t2,function()moon:Destroy()end)
  end)
 end
end
local function sourceNature(g,sky,ground,duration)
 -- the ground itself comes up in chunks, with the trees' colour and the leaves off them
 local colors={Color3.fromRGB(214,180,110),Color3.fromRGB(176,142,86),Color3.fromRGB(235,190,70),Color3.fromRGB(96,70,48),LEAF}
 local n=math.floor(46*E.Quality)
 for i=1,n do
  E.After(g,duration*(i/n)*.8,function()
   local a=rand:NextNumber(0,math.pi*2)
   local r=rand:NextNumber(30,185)
   local from=ground+Vector3.new(math.cos(a)*r,1,math.sin(a)*r)
   local sz=Vector3.new(rand:NextNumber(2,9),rand:NextNumber(2,7),rand:NextNumber(2,9))
   local p=P(g.Folder,sz,CFrame.new(from)*CFrame.Angles(rand:NextNumber(0,6),rand:NextNumber(0,6),0),colors[rand:NextInteger(1,#colors)],PLASTIC,0)
   consume(g,p,sky,rand:NextNumber(.75,1.15))
  end)
 end
 local a=E.Anchor(g,CFrame.new(ground+UP*3))
 a.Size=Vector3.new(300,2,300)
 local e=E.Stream(a,{tex="butterfly",shape=Enum.ParticleEmitterShape.Box,size={{0,2.4},{1,.5}},color=LEAF,alpha={{0,.2},{.7,.3},{1,1}},life={1.2,2},speed={90,150},dir=Enum.NormalId.Top,spread=8,spin={-200,200}},70)
 E.After(g,duration,function()e.Enabled=false end)
end
local function sourceTime(g,sky,duration)
 -- two clock faces of tick marks, spinning backwards around the sphere until they collapse into it
 local rings={}
 local function build(radius,count,thick)
  local list={}
  for i=1,count do list[i]={P=P(g.Folder,Vector3.new(thick,thick*.5,i%5==0 and 12 or 6),nil,i%5==0 and WHITE or GOLDT,NEON,.05),A=(i-1)/count*math.pi*2} end
  rings[#rings+1]={List=list,R=radius}
 end
 build(78,40,1.2)
 build(104,60,.9)
 local start=os.clock()
 E.Step(g,function()
  local k=math.clamp((os.clock()-start)/duration,0,1)
  local spin=(os.clock()-start)*(1+k*9)
  local collapse=k>.72 and 1-((k-.72)/.28)^2 or 1
  for j,ring in ipairs(rings)do
   local dirSign=j==1 and -1 or 1
   local base=CFrame.new(sky)*CFrame.Angles(j==1 and .5 or -.42,0,j==1 and -.3 or .36)
   local r=ring.R*collapse
   for _,x in ipairs(ring.List)do
    local a=x.A+spin*dirSign
    x.P.CFrame=base*CFrame.Angles(0,a,0)*CFrame.new(0,0,-r)
    if k>=1 then x.P.Transparency=1 end
   end
  end
  if k>=1 then return false end
 end)
end
local function sourceAll(g,sky,ground,duration)
 local n=math.floor(60*E.Quality)
 for i=1,n do
  E.After(g,duration*(i/n)*.75,function()
   local a=rand:NextNumber(0,math.pi*2)
   local r=rand:NextNumber(120,320)
   local from=sky+Vector3.new(math.cos(a)*r,rand:NextNumber(-110,110),math.sin(a)*r)
   local s=rand:NextNumber(3,14)
   local dark=i%3==0
   local p=P(g.Folder,Vector3.new(s,s,.3),CFrame.lookAt(from,sky),dark and VOID or pick2(i),dark and PLASTIC or NEON,.05)
   consume(g,p,sky,.5)
  end)
 end
end
function T.FalterStart(_,d)
 local root=rootOf(d.Char)
 if not root then return end
 setMode(d.Char,"Grab")
 local s=cubes[d.Id]
 if s then cubes[d.Id]=nil s.G:Destroy() end
 local total=d.Ascend+d.Charge+d.Fall+d.After
 local c,g=newCast(d.Char,"Falter",total+3)
 local me=isLocal(d.Char)
 local draw=buildFourD(g.Folder)
 local cube=diamondCube(g.Folder,3)
 local anchor=E.Anchor(g,CFrame.new(d.From))
 c.Anchor=anchor
 E.Light(g,anchor,MAG,180,7)
 local sky=d.Sky+Vector3.new(0,10,0)
 c.Stage,c.Radius,c.Target,c.Sky="grab",0,sky,sky
 local shake=0
 local start=os.clock()
 local base=CFrame.lookAt(d.Ground,d.Ground+d.Dir)
 -- an accretion disc and lens that grow with the charge
 local disc=E.Anchor(g,CFrame.new(sky)*CFrame.Angles(.4,0,-.25))
 E.After(g,d.Ascend,function()
  E.Sprite(disc,{tex="ring.ticked",orient="flat",size={{0,18},{.9,190},{1,190}},alpha={{0,.5},{.15,.2},{.95,.3},{1,1}},color=MAG,spin={160,160}},d.Charge+d.Fall)
  E.Sprite(disc,{tex="ring.thick",orient="flat",size={{0,12},{.9,150},{1,150}},alpha={{0,.5},{.15,.25},{.95,.35},{1,1}},color=WHITE,spin={-90,-90}},d.Charge+d.Fall)
  E.Sprite(anchor,{tex="star.lens",size={{0,20},{.9,260},{1,260}},alpha={{0,.4},{.2,.3},{1,.25}},color=WHITE,spin={40,40}},d.Charge)
 end)
 local nextShard,falterAt,falterOff,falterScale=0,0,Vector3.zero,1
 E.Step(g,function(dt)
  local t=os.clock()-start
  local stage=c.Stage
  local pos
  if stage=="grab" then
   local arm=rootOf(d.Char) and (rootOf(d.Char).CFrame*CFrame.new(0,3,-6)).Position or d.From
   local k=math.clamp(t/.25,0,1)
   pos=d.From:Lerp(arm,k)
   if t>=.25 then c.Stage="rise" end
   cube(CFrame.new(pos)*CFrame.Angles(t*6,t*9,0)*CORNER,1.4)
  elseif stage=="rise" then
   local arm=rootOf(d.Char) and (rootOf(d.Char).CFrame*CFrame.new(0,3,-6)).Position or sky
   pos=arm
   cube(CFrame.new(pos)*CFrame.Angles(t*6,t*9,0)*CORNER,1.4+math.clamp((t-.25)/1,0,1)*.8)
   if t>=d.Ascend then
    c.Stage="charge"
    c.ChargeAt=os.clock()
    screenFlash(WHITE,.55,.2)
   end
  elseif stage=="charge" then
   local k=math.clamp((os.clock()-c.ChargeAt)/d.Charge,0,1)
   c.Radius=7+k*k*44
   pos=sky
   -- it falters: every so often the whole object drops out of place for a frame or two
   local now=os.clock()
   if now>=falterAt then
    falterAt=now+rand:NextNumber(.12,.55)
    if rand:NextNumber()<.5 then
     falterOff=Vector3.new(rand:NextNumber(-1,1),rand:NextNumber(-1,1),rand:NextNumber(-1,1))*(2+k*11)
     falterScale=rand:NextNumber(.86,1.2)
     task.delay(.07,function()falterOff,falterScale=Vector3.zero,1 end)
    end
   end
   draw(pos+falterOff,c.Radius*falterScale,t,.18+k*1.3)
   shake=.2+k*.95
   if now>=nextShard then
    nextShard=now+.09
    local dirS=Vector3.new(rand:NextNumber(-1,1),rand:NextNumber(-1,1),rand:NextNumber(-1,1)).Unit
    datamosh(g,pos+dirS*c.Radius*rand:NextNumber(1.2,1.9),rand:NextNumber(10,24),rand:NextNumber(6,16),.22,4)
   end
  elseif stage=="fall" then
   local k=math.clamp((os.clock()-c.FallAt)/d.Fall,0,1)
   local e=k*k*k
   local goal=c.Point
   if c.Target and rootOf(c.Target) then goal=rootOf(c.Target).Position end
   pos=sky:Lerp(goal,e)
   draw(pos,c.Radius*(1+e*.3),t,1.6)
   shake=1.4
  else
   pos=anchor.Position
  end
  anchor.CFrame=CFrame.new(pos)
 end)
 c.Shake=function()return shake end
 if me then
  screenFlash(WHITE,.25,.2)
  impactFrames({d.Char,d.Boss},{{BLACK,WHITE,.05},{WHITE,BLACK,.05},{MAG,BLACK,.05},{BLACK,CYAN,.05}})
  slam("// HIDDEN //",MAG,.9)
  screenGlitch(true)
  local hidden={}
  for _,name in ipairs({"ClassHUD","PlayerVitalsHUD","AlterGoldenBossHUD"})do
   local hud=player.PlayerGui:FindFirstChild(name)
   if hud and hud:IsA("ScreenGui") and hud.Enabled then hud.Enabled=false hidden[#hidden+1]=hud end
  end
  c.Restore[#c.Restore+1]=function()
   screenGlitch(false) colorReset(.4)
   for _,hud in ipairs(hidden)do if hud.Parent then hud.Enabled=true end end
  end
  -- drain the world so the only colour left on screen belongs to the sphere
  colorShift(Color3.fromRGB(176,168,226),-.82,.34,1.2,-.2)
  local h=d.Sky.Y-d.Ground.Y
  local D=d.Charge
  local bossRel=d.Boss and rootOf(d.Boss) and base:PointToObjectSpace(rootOf(d.Boss).Position) or Vector3.new(0,3,-90)
  runShots(base,{
   {D=d.Ascend,P0=Vector3.new(7,2.5,11),P1=Vector3.new(9,h*.82,24),L0=Vector3.new(0,3,0),L1=Vector3.new(0,h+4,0),F0=68,F1=92,R0=-5,R1=5},
   {D=D*.27,P0=Vector3.new(72,h+30,-110),P1=Vector3.new(60,h+22,-90),L0=Vector3.new(0,h+10,0),F0=66,F1=56,R0=7,R1=2},
   {D=D*.27,P0=Vector3.new(-120,14,60),P1=Vector3.new(-96,20,50),L0=Vector3.new(0,h*.6,0),L1=Vector3.new(0,h+6,0),F0=58,F1=70,R0=-6,R1=-1},
   {D=D*.24,P0=Vector3.new(70,h-40,120),P1=Vector3.new(40,h-20,86),L0=Vector3.new(0,h+10,0),F0=60,F1=50,R0=-3,R1=4},
   {D=D*.22,P0=Vector3.new(0,8,-96),P1=Vector3.new(0,14,-82),L0=Vector3.new(0,h,0),L1=Vector3.new(0,h+12,0),F0=60,F1=30,Ease="in"},
   {D=d.Fall,P0=Vector3.new(0,h+42,44),P1=Vector3.new(bossRel.X*.4,h*.45,bossRel.Z*.3+60),L0=Vector3.new(0,h,0),L1=bossRel,F0=70,F1=98,Ease="in",R0=0,R1=10},
   {D=d.After,P0=bossRel+Vector3.new(120,70,110),P1=bossRel+Vector3.new(160,104,146),L0=bossRel+Vector3.new(0,6,0),L1=bossRel+Vector3.new(0,20,0),F0=70,F1=86},
  },function()return shake end)
  local words={{"SPACE",STAR,0},{"NATURE",LEAF,.27},{"TIME",GOLDT,.54},{"EVERYTHING",WHITE,.78}}
  for _,w in ipairs(words)do
   task.delay(d.Ascend+D*w[3],function()if casts[d.Char]==c then slam(w[1],w[2],D*.17) screenFlash(w[2],.82,.18) end end)
  end
  task.delay(d.Ascend+D*.93,function()if casts[d.Char]==c then slam("F  A  L  T  E  R",MAG,1) end end)
 end
 -- every source on the map, one set piece at a time
 local at=d.Ascend
 E.After(g,at,function()sourceSpace(g,sky,d.Ground,d.Charge*.27)end)
 E.After(g,at+d.Charge*.27,function()sourceNature(g,sky,d.Ground,d.Charge*.27)end)
 E.After(g,at+d.Charge*.54,function()sourceTime(g,sky,d.Charge*.26)end)
 E.After(g,at+d.Charge*.78,function()sourceAll(g,sky,d.Ground,d.Charge*.22)end)
 -- thin feed lines climbing from the arena to the sphere
 local ring={}
 for i=1,8 do
  local a=(i-1)*math.pi/4
  local foot=d.Ground+Vector3.new(math.cos(a)*170,2,math.sin(a)*170)
  local p0=E.Anchor(g,CFrame.new(foot))
  local p1=E.Anchor(g,CFrame.new(sky))
  local b=E.Beam(g,E.Attach(p0),E.Attach(p1),{tex="beam.dots",length=30,scroll=120,width=0,color={{0,pick2(i)},{1,WHITE}},brightness=2,segments=8,curve0=30,curve1=-30})
  E.After(g,d.Ascend,function()E.Tween(b,d.Charge*.7,{Width0=1.1,Width1=.45})end)
  ring[i]=b
 end
 E.After(g,d.Ascend+d.Charge-.1,function()for _,b in ipairs(ring)do E.Tween(b,.12,{Width0=0,Width1=0})end end)
 for i=0,5 do
  E.After(g,d.Ascend+d.Charge*i/6,function()play(SFX.Sonic,sky,.9,.5+i*.11)end)
 end
end
function T.FalterRelease(_,d)
 local c=casts[d.Char]
 if not c then return end
 c.Target,c.Point=d.Target,d.Point
 c.FallAt=os.clock()
 c.Stage="fall"
 setMode(d.Char,"Spread")
 -- the landing spot is shown at its real size while the sphere comes down
 local ground=E.Ground(d.Point+UP*8)
 local g=E.Group("Disorder_FalterMark")
 local a=E.Anchor(g,CFrame.new(d.Point.X,(ground and ground.Y or d.Point.Y-3)+.5,d.Point.Z))
 local dia=160
 E.Sprite(a,{tex="disc.soft",orient="flat",light=0,size={{0,dia*.3},{1,dia}},alpha={{0,.5},{1,.15}},color=VOID},1.1)
 E.Sprite(a,{tex="ring.ticked",orient="flat",size={{0,dia*1.4},{1,dia*.9}},alpha={{0,.4},{1,.1}},color=MAG,spin={300,300}},1.1)
 E.After(g,1.2,function()g:Destroy()end)
 if isLocal(d.Char)then
  impactFrames({d.Char},{{WHITE,BLACK,.06},{BLACK,MAG,.06}})
 end
end
function T.FalterImpact(_,d)
 local c=casts[d.Char]
 if c then c.Stage="done" end
 for _,x in ipairs(c and c.G.Folder:GetChildren() or {})do
  if x:IsA("BasePart") and x.Name~="Anchor" then x.Transparency=1 end
 end
 glitchBlast(d.Pos,d.Radius,true)
 local g=E.Group("Disorder_FalterBlast")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 local R=d.Radius*2
 darkPlate(a,R*2.6,.9)
 E.Sprite(a,{tex="burst.white",size={{0,R*.3},{1,R*3}},alpha={{0,0},{.5,.15},{1,1}},color=WHITE,rot={0,360}},.75)
 E.Sprite(a,{tex="flare.big",size={{0,R*.4},{.15,R*2.4},{1,R*1.6}},alpha={{0,0},{.5,.3},{1,1}},color=MAG},1.3)
 local gy=E.Ground(d.Pos+UP*8)
 local ground=gy or d.Pos-UP*3
 local fl=E.Anchor(g,CFrame.new(ground+UP*.5))
 E.Sprite(fl,{tex="ring.thick",orient="flat",size={{0,R*.2},{1,R*4.2}},alpha={{0,.05},{.8,.25},{1,1}},color=WHITE},1.3)
 E.Sprite(fl,{tex="ring.thick",orient="flat",light=0,size={{0,R*.24},{1,R*4.4}},alpha={{0,.15},{.85,.4},{1,1}},color=VOID},1.4)
 wireDome(g,ground,R*2,1.3,MAG)
 task.delay(.14,function()if g.Alive then wireDome(g,ground,R*1.4,1.1,CYAN) end end)
 local dome=P(g.Folder,Vector3.one*R*.3,CFrame.new(ground),WHITE,NEON,0,BALL)
 E.Tween(dome,.8,{Size=Vector3.one*R*2,Transparency=1},Enum.EasingStyle.Quint)
 -- what it leaves behind: pillars and sky tears over the crater, then quiet
 local points={}
 for i=1,70 do
  local p=d.Pos+Vector3.new(rand:NextNumber(-R,R),10,rand:NextNumber(-R,R))
  local hit=E.Ground(p)
  if hit then points[#points+1]=hit end
 end
 pixelPillars(g,points,30,1.9,110)
 skyTears(g,points,12,1.9)
 E.Light(g,a,WHITE,R*4,14,1.4)
 play(SFX.Boom,d.Pos,2,.7)
 play(SFX.Boom,d.Pos,1.4,1.3)
 E.After(g,4,function()g:Destroy()end)
 if isLocal(d.Char)then
  impactFrames({d.Char},{{WHITE,BLACK,.07},{BLACK,WHITE,.07},{MAG,BLACK,.06},{WHITE,BLACK,.06},{CYAN,BLACK,.06},{BLACK,WHITE,.06}})
  task.delay(.4,function()screenFlash(WHITE,.2,1.1)end)
  task.delay(.35,function()slam("REALITY NOT FOUND",MAG,1.4)end)
 end
end

local function resetAll()
 impactToken+=1
 Run:UnbindFromRenderStep(IMPACT_STEP)
 stopCine()
 for char in pairs(casts)do finishCast(char) end
 while screenCount>0 do screenGlitch(false) end
 colorReset(.2)
end
Reset.Register(script,resetAll,resetAll)

return T
