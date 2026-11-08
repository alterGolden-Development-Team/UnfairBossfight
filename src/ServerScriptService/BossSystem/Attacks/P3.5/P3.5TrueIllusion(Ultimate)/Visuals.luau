local B=script:FindFirstAncestor("BossSystem")
local Effects=require(B.Combat.EffectService)
local Runtime=require(B.Combat.CombatRuntime)
local Style=require(script.Parent.Style)
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local CollectionService=game:GetService("CollectionService")
local V={}

local FX={Density=1,Lights=true,Afterimage=true,Streak=true,GroundSigils=true,CloneAura=true,CloneFade=true}
for k,v in pairs(Style.Fx or {}) do FX[k]=v end

local rng=Random.new()
local TAU=math.pi*2
local SHADOW=Style.Shadow or Color3.fromRGB(38,26,4)
local SPARK="rbxasset://textures/particles/sparkles_main.dds"
local SMOKE="rbxasset://textures/particles/smoke_main.dds"
local BLOCK,BALL,CYL=Enum.PartType.Block,Enum.PartType.Ball,Enum.PartType.Cylinder
local QUAD,BACK,LINEAR=Enum.EasingStyle.Quad,Enum.EasingStyle.Back,Enum.EasingStyle.Linear
local OUT,IN=Enum.EasingDirection.Out,Enum.EasingDirection.In
local NK,CK=NumberSequenceKeypoint.new,ColorSequenceKeypoint.new

local CARD_COLORS={Style.White,Style.Gold}
for _,name in ipairs(Style.Order) do table.insert(CARD_COLORS,Style.Suits[name].Color) end

local warned={}
local function report(name,err)
 if not warned[name] then warned[name]=true;warn("[TrueIllusion VFX] "..name.." failed: "..tostring(err)) end
end
local function guard(name,fn)
 return function(...)
  local ok,res=pcall(fn,...)
  if ok then return res end
  report(name,res)
  return nil
 end
end
local function stepGuard(name,fn)
 return function(dt)
  local ok,res=pcall(fn,dt)
  if ok then return res end
  report(name,res)
  return false
 end
end
local function info(t,style,dir) return TweenInfo.new(t,style or QUAD,dir or OUT) end
local function count(n) return math.floor(n*FX.Density+.5) end
local function aimFrame(pos,dir)
 local up=math.abs(dir.Y)>.97 and Vector3.xAxis or Vector3.yAxis
 return CFrame.lookAt(pos,pos+dir,up)
end
V.AimFrame=aimFrame
local function randomUnit()
 while true do
  local v=Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-1,1),rng:NextNumber(-1,1))
  local m=v.Magnitude
  if m>.05 and m<=1 then return v/m end
 end
end
local function cone(axis,spread)
 local ref=math.abs(axis.Y)<.95 and Vector3.yAxis or Vector3.xAxis
 local u=axis:Cross(ref).Unit
 local w=axis:Cross(u)
 local a=rng:NextNumber(0,TAU)
 local ang=spread*math.sqrt(rng:NextNumber())
 return axis*math.cos(ang)+(u*math.cos(a)+w*math.sin(a))*math.sin(ang)
end
local function part(cast,name,frame,size,color,alpha,shape)
 local p=Effects.AcquirePart()
 p.Name=name;p.Shape=shape or BLOCK
 p.CFrame=frame;p.Size=size;p.Color=color;p.Transparency=alpha or 0
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.Neon
 p.Parent=Runtime.Effects
 return cast:Add(p)
end
local function release(cast,t,p) cast:Schedule(t,function() Effects.Release(p) end) end

local function defaultParams(actor)
 local p=RaycastParams.new()
 p.FilterType=Enum.RaycastFilterType.Exclude
 p.FilterDescendantsInstances={actor,Runtime.Effects,Runtime.Summons}
 p.IgnoreWater=true
 return p
end
local function ground(pos,reach,actor,params)
 params=params or defaultParams(actor)
 local origin=pos+Vector3.new(0,1,0)
 local remaining=reach+1
 for _=1,5 do
  local hit=workspace:Raycast(origin,Vector3.new(0,-remaining,0),params)
  if not hit then return nil end
  local model=hit.Instance:FindFirstAncestorOfClass("Model")
  if not (model and model:FindFirstChildOfClass("Humanoid")) then return hit end
  remaining-=(origin.Y-hit.Position.Y)+.05
  origin=hit.Position-Vector3.new(0,.05,0)
  if remaining<=0 then return nil end
 end
 return nil
end
local function groundPoint(pos,reach,actor,params)
 local hit=ground(pos,reach,actor,params)
 if hit then return hit.Position+hit.Normal*.15,hit.Normal end
 return pos-Vector3.new(0,2.5,0),Vector3.yAxis
end
local function floorFrame(point,normal)
 local r=normal:Cross(Vector3.xAxis)
 if r.Magnitude<.1 then r=normal:Cross(Vector3.zAxis) end
 return CFrame.fromMatrix(point+normal*.07,r.Unit,normal)
end

local function symbol(parent,text,color,size)
 local gui=Instance.new("BillboardGui") gui.Name="CardSuit" gui.Size=UDim2.fromScale(size,size)
 gui.AlwaysOnTop=false;gui.LightInfluence=0;gui.MaxDistance=450;gui.ClipsDescendants=false;gui.Parent=parent
 local function label(name,scale,transparency,col)
  local l=Instance.new("TextLabel") l.Name=name
  l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5);l.Size=UDim2.fromScale(scale,scale)
  l.BackgroundTransparency=1;l.Font=Enum.Font.GothamBold;l.TextScaled=true;l.Text=text
  l.TextColor3=col;l.TextTransparency=transparency;l.TextStrokeTransparency=1;l.Parent=gui
  return l
 end
 label("Glow",1.5,.62,color)
 local main=label("TextLabel",1,0,color:Lerp(Style.White,.3))
 local stroke=Instance.new("UIStroke") stroke.Color=SHADOW;stroke.Thickness=2;stroke.Transparency=.1;stroke.Parent=main
 return gui
end
local function recolor(gui,text,color)
 local main,glow=gui:FindFirstChild("TextLabel"),gui:FindFirstChild("Glow")
 if text then main.Text=text;glow.Text=text end
 main.TextColor3=color:Lerp(Style.White,.3);glow.TextColor3=color
end
local function fadeSymbol(gui,t)
 local ti=info(t,QUAD,IN)
 for _,l in ipairs(gui:GetChildren()) do
  if l:IsA("TextLabel") then
   TweenService:Create(l,ti,{TextTransparency=1}):Play()
   local s=l:FindFirstChildOfClass("UIStroke")
   if s then TweenService:Create(s,ti,{Transparency=1}):Play() end
  end
 end
end
local function pop(cast,pos,spec,size,rise,life)
 local anchor=part(cast,"TrueIllusionSymbolPop",CFrame.new(pos),Vector3.one*.2,spec.Color,1)
 local gui=symbol(anchor,spec.Symbol,spec.Color,size*.35)
 TweenService:Create(gui,info(life*.45,BACK,OUT),{Size=UDim2.fromScale(size,size)}):Play()
 fadeSymbol(gui,life)
 Effects:Create(anchor,info(life),{CFrame=CFrame.new(pos+Vector3.new(0,rise,0))}):Play()
 release(cast,life+.05,anchor)
end

local function floorCanvas(cast,point,normal,diameter,name,spin)
 local frame=floorFrame(point,normal)*CFrame.Angles(0,spin and rng:NextNumber(0,TAU) or 0,0)
 local p=part(cast,name,frame,Vector3.new(diameter,.05,diameter),Style.Gold,1)
 local gui=Instance.new("SurfaceGui") gui.Name="Canvas";gui.Face=Enum.NormalId.Top;gui.LightInfluence=0;gui.AlwaysOnTop=false
 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=Vector2.new(512,512);gui.Parent=p
 local root=Instance.new("Frame") root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5)
 root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.Parent=gui
 return p,root
end
local function circle(parent,scale,color,thickness,fill)
 local f=Instance.new("Frame") f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5)
 f.Size=UDim2.fromScale(scale,scale);f.BackgroundTransparency=fill or 1;f.Parent=parent
 if fill then f.BackgroundColor3=color end
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(.5,0);c.Parent=f
 local s
 if thickness then s=Instance.new("UIStroke") s.Color=color;s.Thickness=thickness;s.Transparency=.1;s.Parent=f end
 return f,s
end

local function sigil(cast,point,normal,spec,diameter,life)
 local p,root=floorCanvas(cast,point,normal,diameter,"TrueIllusionSigil",true)
 root.Size=UDim2.fromScale(.6,.6)
 local fades={}
 local _,s1=circle(root,.98,spec.Color,10) table.insert(fades,s1)
 local _,s2=circle(root,.72,spec.Color,5) table.insert(fades,s2)
 local l=Instance.new("TextLabel") l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5)
 l.Size=UDim2.fromScale(.48,.48);l.BackgroundTransparency=1;l.Font=Enum.Font.GothamBold;l.TextScaled=true
 l.Text=spec.Symbol;l.TextColor3=spec.Color;l.TextTransparency=.1;l.Parent=root
 table.insert(fades,l)
 TweenService:Create(root,info(.18,BACK,OUT),{Size=UDim2.fromScale(1,1)}):Play()
 cast:Schedule(.24,function()
  for _,o in ipairs(fades) do
   TweenService:Create(o,info(life-.24,QUAD,IN),o:IsA("UIStroke") and {Transparency=1} or {TextTransparency=1}):Play()
  end
 end)
 release(cast,life+.05,p)
end

function V.Flash(cast,pos,color,size,life)
 life=life or .25
 local p=part(cast,"TrueIllusionFlash",CFrame.new(pos),Vector3.one*.5,color,.25,BALL)
 Effects:Create(p,info(life),{Size=Vector3.one*size,Transparency=1}):Play()
 release(cast,life+.03,p)
 return p
end

function V.Ring(cast,pos,color,radius,life,opts)
 opts=opts or {}
 local normal=opts.Normal or Vector3.yAxis
 local segs=opts.Segments or math.clamp(math.floor(radius*3.2),10,26)
 local start=(opts.Start or .35)*radius
 local width=opts.Width or .22
 local alpha=opts.Alpha or .15
 local u=normal:Cross(Vector3.zAxis)
 if u.Magnitude<.01 then u=normal:Cross(Vector3.xAxis) end
 u=u.Unit
 local v=normal:Cross(u)
 local k=2*math.sin(math.pi/segs)*1.15
 local tween=info(life,opts.Easing)
 for i=1,segs do
  local a=(i-1)/segs*TAU
  local radial=u*math.cos(a)+v*math.sin(a)
  local tangent=-u*math.sin(a)+v*math.cos(a)
  local p0=pos+radial*start
  local p1=pos+radial*radius
  local p=part(cast,"TrueIllusionRing",CFrame.lookAt(p0,p0+tangent,normal),Vector3.new(width,width,start*k+.05),color,alpha)
  Effects:Create(p,tween,{CFrame=CFrame.lookAt(p1,p1+tangent,normal),Size=Vector3.new(width*.3,width*.3,radius*k),Transparency=1}):Play()
  release(cast,life+.03,p)
 end
end

function V.Pillar(cast,base,color,height,radius,life)
 local frame=CFrame.new(base+Vector3.new(0,height/2,0))*CFrame.Angles(0,0,math.pi/2)
 local p=part(cast,"TrueIllusionPillar",frame,Vector3.new(height,radius*2,radius*2),color,.35,CYL)
 Effects:Create(p,info(life),{Size=Vector3.new(height*1.25,.12,.12),Transparency=1}):Play()
 release(cast,life+.03,p)
end

function V.Sparks(cast,pos,o)
 local n=count(o.Count or 10)
 if n<=0 then return end
 local colors=o.Colors or {Style.White}
 local speed=o.Speed or {20,50}
 local life=o.Life or {.4,.7}
 local gravity=o.Gravity or 0
 local drag=o.Drag or 0
 local size=o.Size or Vector3.new(.16,.16,.9)
 local card=o.Card
 local items={}
 for i=1,n do
  local dir
  if o.Dir then dir=cone(o.Dir,o.Spread or .4)
  else
   dir=randomUnit()
   local up=o.Up or 0
   dir=Vector3.new(dir.X,dir.Y*(1-up)+math.abs(dir.Y)*up,dir.Z).Unit
  end
  items[i]={
   Part=part(cast,"TrueIllusionSpark",CFrame.new(pos),size,colors[rng:NextInteger(1,#colors)],0),
   Pos=pos,Vel=dir*rng:NextNumber(speed[1],speed[2]),Age=0,Life=rng:NextNumber(life[1],life[2]),
   Rot=Vector3.new(rng:NextNumber(0,TAU),rng:NextNumber(0,TAU),rng:NextNumber(0,TAU)),
   Spin=Vector3.new(rng:NextNumber(-9,9),rng:NextNumber(-9,9),rng:NextNumber(-9,9)),
  }
 end
 local alive=n
 local function step(dt)
  if cast.closed then return false end
  dt=math.min(dt,.05)
  for _,it in ipairs(items) do
   local p=it.Part
   if p then
    it.Age+=dt
    local k=it.Age/it.Life
    if k>=1 then
     Effects.Release(p);it.Part=nil;alive-=1
    else
     local vel=it.Vel
     it.Vel=Vector3.new(vel.X,vel.Y-gravity*dt,vel.Z)*(1-math.min(drag*dt,.9))
     it.Pos+=it.Vel*dt
     if card then
      it.Rot+=it.Spin*dt
      p.CFrame=CFrame.new(it.Pos)*CFrame.Angles(it.Rot.X,it.Rot.Y,it.Rot.Z)
      p.Transparency=math.max(0,(k-.55)/.45)
     else
      local m=it.Vel.Magnitude
      p.CFrame=m>.1 and aimFrame(it.Pos,it.Vel/m) or CFrame.new(it.Pos)
      p.Size=size*Vector3.new(1-k*.5,1-k*.5,1-k*.6)
      p.Transparency=k*k
     end
    end
   end
  end
  return alive>0
 end
 cast:Step(stepGuard("Sparks.step",step))
end

function V.AimLine(cast,from,to,color,life)
 local delta=to-from
 local len=delta.Magnitude
 if len<1 then return end
 local p=part(cast,"TrueIllusionAimLine",aimFrame(from+delta/2,delta/len),Vector3.new(.08,.08,len),color,.8)
 Effects:Create(p,info(life*.85,LINEAR),{Size=Vector3.new(.26,.26,len),Transparency=.25}):Play()
 cast:Schedule(life*.85,function() Effects:Create(p,info(life*.15),{Transparency=1}):Play() end)
 release(cast,life+.05,p)
end

function V.CloneCharge(cast,pos,spec,life,targetPos)
 V.Flash(cast,pos,spec.Color,4,.3)
 local dir=targetPos-pos
 local normal=dir.Magnitude>.01 and dir.Unit or Vector3.zAxis
 V.Ring(cast,pos+normal*1.5,spec.Color,3,life,{Normal=normal,Segments=12,Start=1,Width=.2,Alpha=.2})
 V.AimLine(cast,pos,targetPos,spec.Color,life)
 pop(cast,pos+Vector3.new(0,3.5,0),spec,3,1.5,life+.2)
end

function V.Hazard(cast,pos,spec,radius,life,actor)
 local point,normal=groundPoint(pos,10,actor)
 local p,root=floorCanvas(cast,point,normal,radius*2,"TrueIllusionHazard",true)
 root.Size=UDim2.fromScale(.3,.3)
 local fill=circle(root,1,spec.Color,nil,.55)
 local _,edge=circle(root,1,Style.White,6)
 local l=Instance.new("TextLabel") l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5)
 l.Size=UDim2.fromScale(.4,.4);l.BackgroundTransparency=1;l.Font=Enum.Font.GothamBold;l.TextScaled=true
 l.Text=spec.Symbol;l.TextColor3=SHADOW;l.TextTransparency=.45;l.Parent=root
 TweenService:Create(root,info(.2,BACK,OUT),{Size=UDim2.fromScale(1,1)}):Play()
 local fade=math.min(.5,life*.3)
 cast:Schedule(life-fade,function()
  TweenService:Create(fill,info(fade),{BackgroundTransparency=1}):Play()
  TweenService:Create(edge,info(fade),{Transparency=1}):Play()
  TweenService:Create(l,info(fade),{TextTransparency=1}):Play()
 end)
 local e=Instance.new("ParticleEmitter") e.Texture=SPARK;e.Color=ColorSequence.new(Style.White,spec.Color);e.LightEmission=1
 e.Rate=math.max(0,radius*6*FX.Density);e.Lifetime=NumberRange.new(.5,1);e.Speed=NumberRange.new(3,8)
 e.Size=NumberSequence.new({NK(0,.6),NK(1,0)});e.Transparency=NumberSequence.new({NK(0,.1),NK(1,1)})
 e.EmissionDirection=Enum.NormalId.Top;e.SpreadAngle=Vector2.new(15,15)

 local spot=part(cast,"TrueIllusionHazardEmitter",floorFrame(point,normal),Vector3.new(radius*1.6,.05,radius*1.6),spec.Color,1)
 e.Parent=spot
 cast:Schedule(life-fade,function() e.Enabled=false end)
 release(cast,life+.05,p)
 release(cast,life+1.05,spot)
 return point
end

function V.PrisonRing(cast,center,radius,life,actor)
 local point,normal=groundPoint(center,14,actor)
 V.Ring(cast,point,Style.Gold,radius,life,{Normal=normal,Start=1,Width=.35,Alpha=.25,Segments=26,Easing=Enum.EasingStyle.Linear})
 V.Flash(cast,center,Style.Gold,6,.3)
end

function V.DangerZone(cast,pos,radius,life,actor)
 local point,normal=groundPoint(pos,30,actor)
 local p,root=floorCanvas(cast,point,normal,radius*2,"TrueIllusionDangerZone",false)
 local _,edge=circle(root,.98,Style.Gold,8)
 local fill=circle(root,0,Style.Gold,nil,.45)
 TweenService:Create(fill,info(life,LINEAR),{Size=UDim2.fromScale(.98,.98)}):Play()
 local l=Instance.new("TextLabel") l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5)
 l.Size=UDim2.fromScale(.42,.42);l.BackgroundTransparency=1;l.Font=Enum.Font.GothamBold;l.TextScaled=true
 l.Text="!";l.TextColor3=Style.White;l.TextTransparency=.2;l.Parent=root
 local s=Instance.new("UIStroke") s.Color=SHADOW;s.Thickness=3;s.Parent=l
 V.Pillar(cast,point,Style.Gold,60,.35,life)
 cast:Schedule(life,function()
  TweenService:Create(edge,info(.25),{Transparency=1}):Play()
  TweenService:Create(fill,info(.25),{BackgroundTransparency=1}):Play()
  TweenService:Create(l,info(.25),{TextTransparency=1}):Play()
  TweenService:Create(s,info(.25),{Transparency=1}):Play()
 end)
 release(cast,life+.3,p)
 return point
end

function V.Fizzle(cast,pos,color)
 V.Flash(cast,pos,color,2.5,.18)
 V.Sparks(cast,pos,{Count=3,Speed={10,24},Life={.2,.35},Colors={color,Style.White}})
end

local function aura(root)
 local e=Instance.new("ParticleEmitter") e.Name="IllusionAura"
 e.Texture=SPARK;e.Color=ColorSequence.new(Style.White,Style.Gold);e.LightEmission=1
 e.Rate=3*FX.Density;e.Lifetime=NumberRange.new(1,1.7);e.Speed=NumberRange.new(.4,1.4)
 e.Size=NumberSequence.new({NK(0,0),NK(.3,.5),NK(1,0)})
 e.Transparency=NumberSequence.new({NK(0,1),NK(.2,.35),NK(1,1)})
 e.Acceleration=Vector3.new(0,2.5,0);e.EmissionDirection=Enum.NormalId.Top;e.SpreadAngle=Vector2.new(30,30)
 e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-60,60)
 e.Parent=root
end
local function fadeIn(model)
 local list={}
 for _,v in ipairs(model:GetDescendants()) do
  if (v:IsA("BasePart") or v:IsA("Decal")) and v.Transparency<1 then table.insert(list,v) end
 end
 if #list>80 then return end
 local ti=info(.24)
 for _,v in ipairs(list) do
  local goal=v.Transparency
  v.Transparency=1
  TweenService:Create(v,ti,{Transparency=goal}):Play()
 end
end
function V.Clone(actor,frame,parent,index)
 local copy=actor:Clone()
 copy.Name="TrueIllusionDouble"
 copy:SetAttribute("IsIllusion",true);copy:SetAttribute("AIEnabled",false);copy:SetAttribute("TrueIllusionIndex",index)
 copy:SetAttribute("UltimateActive",false);copy:SetAttribute("EncounterEnded",false)
 for _,v in ipairs(copy:GetDescendants()) do
  if v:IsA("LuaSourceContainer") or v:IsA("Sound") or v:IsA("ObjectValue") then v:Destroy()
  elseif v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
  elseif v:IsA("Humanoid") then v.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;v.EvaluateStateMachine=false
  elseif v:IsA("BillboardGui") then v:Destroy() end
 end
 copy:PivotTo(frame)
 copy.Parent=parent
 local ok,err=pcall(function()
  local root=copy:FindFirstChild("HumanoidRootPart")
  if root and FX.CloneAura and FX.Density>0 then aura(root) end
  if FX.CloneFade then fadeIn(copy) end
 end)
 if not ok then report("Clone",err) end
 return copy
end

local KEEP={Model=true,Folder=true,Attachment=true,Motor6D=true,Accessory=true,SpecialMesh=true,Weld=true,WeldConstraint=true,Bone=true}
function V.Afterimage(actor,color)
 local copy=actor:Clone()
 if not copy then return end
 copy.Name="TrueIllusionAfterimage"
 for name in pairs(copy:GetAttributes()) do copy:SetAttribute(name,nil) end
 for _,tag in ipairs(CollectionService:GetTags(copy)) do CollectionService:RemoveTag(copy,tag) end
 local parts={}
 for _,v in ipairs(copy:GetDescendants()) do
  if v:IsA("BasePart") then
   v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=false
   v.Material=Enum.Material.Neon;v.Color=color
   if v:IsA("MeshPart") then v.TextureID="" end
   if v.Transparency<1 then v.Transparency=.35;table.insert(parts,v) end
  elseif v:IsA("SpecialMesh") then v.TextureId=""
  elseif not KEEP[v.ClassName] then v:Destroy() end
 end
 if #parts>90 then copy:Destroy() return end
 copy.Parent=Runtime.Effects
 local ti=info(.45)
 for _,v in ipairs(parts) do TweenService:Create(v,ti,{Transparency=1}):Play() end
 Debris:AddItem(copy,.65)
end

function V.Summon(cast,pos,actor)
 local point,normal=groundPoint(pos,14,actor)
 V.Flash(cast,pos,Style.Gold,4.2,.28)
 V.Pillar(cast,point,Style.Gold,15,1.1,.4)
 V.Ring(cast,point,Style.Gold,5,.42,{Normal=normal,Segments=12,Start=.2,Width=.2})
 V.Sparks(cast,point+normal*.4,{Count=4,Dir=normal,Spread=.5,Speed={6,16},Life={.5,.9},Gravity=-8,
  Colors={Style.Gold,Style.White},Size=Vector3.new(.14,.14,.55)})
end

function V.Teleport(cast,actor,fromPos,toPos)
 local gold=Style.Gold
 V.Flash(cast,fromPos,Style.White,4.5,.16)
 V.Flash(cast,fromPos,gold,9,.34)
 V.Sparks(cast,fromPos,{Count=9,Card=true,Speed={12,34},Life={.5,.9},Gravity=20,Colors=CARD_COLORS,Size=Vector3.new(.62,.9,.04)})
 if FX.Afterimage then V.Afterimage(actor,gold) end
 local delta=toPos-fromPos
 local len=delta.Magnitude
 if FX.Streak and len>6 then
  local line=part(cast,"TrueIllusionStreak",aimFrame(fromPos+delta/2,delta/len),Vector3.new(.55,.55,len),gold,.25)
  Effects:Create(line,info(.26),{Size=Vector3.new(.04,.04,len),Transparency=1}):Play()
  release(cast,.3,line)
 end
 local point,normal=groundPoint(toPos,14,actor)
 V.Flash(cast,toPos,gold,7,.3)
 V.Ring(cast,point,gold,6,.4,{Normal=normal,Segments=16,Start=.25})
 V.Sparks(cast,toPos,{Count=5,Speed={8,22},Life={.35,.6},Gravity=-4,Up=1,Colors={Style.White,gold}})
end

function V.FinaleStart(actor,pos)
 local cast=Effects.NewCast(actor,"TrueIllusionFinaleStart",1.6)
 local point,normal=groundPoint(pos,14,actor)
 V.Flash(cast,pos,Style.White,6,.2)
 V.Flash(cast,pos,Style.Gold,13,.5)
 V.Pillar(cast,point,Style.Gold,55,2.4,.8)
 V.Ring(cast,point,Style.Gold,22,.8,{Normal=normal,Width=.35})
 V.Ring(cast,point,Style.White,12,.55,{Normal=normal})
 V.Sparks(cast,pos,{Count=26,Card=true,Up=1,Speed={20,50},Life={.8,1.3},Gravity=14,Colors=CARD_COLORS,Size=Vector3.new(.75,1.05,.04)})
end

function V.Finale(actor,pos)
 local cast=Effects.NewCast(actor,"TrueIllusionFinale",1.5)
 local point,normal=groundPoint(pos,14,actor)
 V.Flash(cast,pos,Style.White,7,.2)
 V.Flash(cast,pos,Style.Gold,16,.45)
 V.Ring(cast,point,Style.Gold,16,.6,{Normal=normal,Width=.3})
 V.Ring(cast,point,Style.White,9,.45,{Normal=normal})
 V.Pillar(cast,point,Style.Gold,40,2,.55)
 V.Sparks(cast,pos,{Count=22,Card=true,Speed={16,46},Life={.7,1.1},Gravity=18,Colors=CARD_COLORS,Size=Vector3.new(.7,1,.04)})
end

function V.Launcher(cast)
 local handle={Energy=0}
 local parts={}
 local gold,white=Style.Gold,Style.White
 local AXIS=CFrame.Angles(0,math.pi/2,0)
 local function add(name,size,offset,color,shape,material,alpha,role)
  local p=part(cast,"TrueIllusionLauncher"..name,CFrame.identity,size,color,alpha or 0,shape)
  p.Material=material or Enum.Material.Neon
  local e={Part=p,Offset=offset,Role=role}
  table.insert(parts,e)
  return e
 end
 add("Barrel",Vector3.new(7,2.4,2.4),CFrame.new(0,0,-2)*AXIS,Color3.fromRGB(48,36,12),CYL,Enum.Material.Metal)
 add("Muzzle",Vector3.new(.45,2.7,2.7),CFrame.new(0,0,-5.7)*AXIS,gold,CYL,nil,0,"muzzle")
 add("Flare",Vector3.new(.14,3.5,3.5),CFrame.new(0,0,-5.95)*AXIS,white,CYL,nil,.45,"suit")
 add("Rear",Vector3.new(.45,2.7,2.7),CFrame.new(0,0,1.7)*AXIS,gold,CYL)
 add("Grip",Vector3.new(.65,1.8,.9),CFrame.new(0,-1.5,-.4),Color3.fromRGB(32,24,8))
 add("Sight",Vector3.new(.5,.5,1.7),CFrame.new(0,1.4,-1.4),white)
 for i,z in ipairs({-4.5,-3.3,-2.1}) do
  add("Band"..i,Vector3.new(.2,2.62,2.62),CFrame.new(0,0,z)*AXIS,white,CYL,nil,.3,"suit")
 end
 local orb=add("Orb",Vector3.one*.2,CFrame.new(0,0,-6.2),white,BALL,nil,1,"orb").Part
 for i=1,6 do
  local e=add("Card"..i,Vector3.new(.9,1.3,.05),CFrame.identity,i%2==0 and white or gold,BLOCK,nil,.1,"card")
  e.Phase=(i-1)/6*TAU;e.Alt=i%2==0
 end
 local ember=Instance.new("ParticleEmitter") ember.Texture=SPARK;ember.Color=ColorSequence.new(white,gold);ember.LightEmission=1
 ember.Rate=7*FX.Density;ember.Lifetime=NumberRange.new(.4,.8);ember.Speed=NumberRange.new(2,6)
 ember.Size=NumberSequence.new({NK(0,.5),NK(1,0)});ember.Transparency=NumberSequence.new({NK(0,.2),NK(1,1)})
 ember.EmissionDirection=Enum.NormalId.Front;ember.SpreadAngle=Vector2.new(35,35);ember.Parent=orb
 local badge=part(cast,"TrueIllusionSuitBadge",CFrame.identity,Vector3.one*.2,gold,1)
 local gui=symbol(badge,"♠",white,4)

 local last=os.clock()
 local angle=0
 function handle:Update(frame)
  self.Frame=frame
  local now=os.clock()
  local dt=math.min(now-last,.1);last=now
  self.Energy=math.max(0,self.Energy-dt*2.2)
  angle=(angle+dt*(1.4+self.Energy*10))%TAU
  local glow=math.clamp(.42-.3*self.Energy-.06*math.sin(now*7),.04,.5)
  local orbit=frame*CFrame.new(0,0,-3.7)
  for _,e in ipairs(parts) do
   if e.Role=="card" then
    e.Part.CFrame=orbit*CFrame.Angles(0,0,angle+e.Phase)*CFrame.new(2.7,0,0)*CFrame.Angles(0,math.pi/2,0)
   else
    e.Part.CFrame=frame*e.Offset
    if e.Role=="suit" then e.Part.Transparency=glow end
   end
  end
  badge.CFrame=frame*CFrame.new(0,3.1+math.sin(now*2.2)*.18,-1.4)
 end
 function handle:SetSuit(spec)
  recolor(gui,spec.Symbol,spec.Color)
  for _,e in ipairs(parts) do
   if e.Role=="muzzle" or e.Role=="suit" or (e.Role=="card" and e.Alt) then e.Part.Color=spec.Color end
  end
 end
 function handle:Muzzle() return (self.Frame*CFrame.new(0,0,-6)).Position end

 function handle:Charge(spec,windup)
  self.Energy=1
  local muzzle=(self.Frame*CFrame.new(0,0,-6.2)).Position
  V.Flash(cast,muzzle,spec.Color,3,.2)
  orb.Color=spec.Color:Lerp(white,.35);orb.Size=Vector3.one*.2;orb.Transparency=.2
  Effects:Create(orb,info(windup),{Size=Vector3.one*(1.1+spec.Radius*.12),Transparency=.05}):Play()
  cast:Schedule(windup,function() Effects:Create(orb,info(.1),{Size=Vector3.one*.2,Transparency=1}):Play() end)
  for i=1,count(7) do
   local from=muzzle+randomUnit()*rng:NextNumber(3.5,5.8)
   local p=part(cast,"TrueIllusionCharge",aimFrame(from,(muzzle-from).Unit),Vector3.new(.14,.14,1.2),i%2==0 and white or spec.Color,.1)
   Effects:Create(p,info(windup*.95,QUAD,IN),{CFrame=CFrame.new(muzzle)*p.CFrame.Rotation,Size=Vector3.new(.05,.05,.2),Transparency=.6}):Play()
   release(cast,windup+.05,p)
  end
 end
 handle.Update=guard("Launcher.Update",handle.Update)
 handle.SetSuit=guard("Launcher.SetSuit",handle.SetSuit)
 handle.Charge=guard("Launcher.Charge",handle.Charge)
 return handle
end

function V.Muzzle(cast,origin,direction,spec)
 local rapid=spec.Interval~=nil
 V.Flash(cast,origin,Style.White,rapid and 2 or 3.2,.14)
 V.Ring(cast,origin+direction*.6,spec.Color,rapid and 2.4 or 3.6,.2,{Normal=direction,Segments=rapid and 10 or 14,Start=.4,Width=.2})
 V.Sparks(cast,origin,{Count=rapid and 2 or 6,Dir=direction,Spread=.38,Speed={50,110},Life={.12,.26},
  Colors={Style.White,spec.Color},Size=Vector3.new(.1,.1,1.1)})
end

local ROCKETS={
 ["♠"]={Core=Vector3.new(.34,.34,3.2),Ball=false,Tint=.5,Glow=3.4,Width=.42,Life=.34,Tail=24,Sym=3.2},
 ["♥"]={Core=Vector3.one*1.1,Ball=true,Tint=.45,Glow=4.8,Width=.7,Life=.4,Tail=30,Sym=3.8},
 ["♦"]={Core=Vector3.new(.22,.22,3.6),Ball=false,Tint=.65,Glow=2.6,Width=.3,Life=.26,Tail=18,Sym=2.6},
 ["♣"]={Core=Vector3.one*2.4,Ball=true,Tint=.4,Glow=9,Width=1.3,Life=.55,Tail=40,Sym=5.2,Light=true,Smoke=true},
}
local function decorateRocket(p,spec,s,scale)
 local D=FX.Density
 local color=spec.Color
 local function attach(x,y,z) local a=Instance.new("Attachment") a.Position=Vector3.new(x,y,z) a.Parent=p return a end
 local center,tail=attach(0,0,0),attach(0,0,s.Core.Z*scale/2)
 local w=s.Width*scale
 local a0,a1=attach(0,w/2,s.Core.Z*scale/2),attach(0,-w/2,s.Core.Z*scale/2)

 local trail=Instance.new("Trail") trail.Attachment0=a0;trail.Attachment1=a1
 trail.Color=ColorSequence.new({CK(0,Style.White),CK(.18,color:Lerp(Style.White,.25)),CK(1,color)})
 trail.Transparency=NumberSequence.new({NK(0,.05),NK(.6,.55),NK(1,1)})
 trail.WidthScale=NumberSequence.new({NK(0,1),NK(1,0)})
 trail.Lifetime=s.Life;trail.LightEmission=1;trail.FaceCamera=true;trail.MinLength=.04;trail.Parent=p

 local g=s.Glow*scale
 local glow=Instance.new("ParticleEmitter") glow.Texture=SPARK;glow.Color=ColorSequence.new(color:Lerp(Style.White,.2))
 glow.LightEmission=1;glow.LockedToPart=true;glow.Speed=NumberRange.new(0)
 glow.Lifetime=NumberRange.new(.09,.13);glow.Rate=48*D
 glow.Size=NumberSequence.new({NK(0,g*.8),NK(.5,g),NK(1,g*.6)})
 glow.Transparency=NumberSequence.new({NK(0,.7),NK(.4,.45),NK(1,1)})
 glow.Rotation=NumberRange.new(0,360);glow.RotSpeed=NumberRange.new(-180,180);glow.Parent=center

 local fire=Instance.new("ParticleEmitter") fire.Texture=SPARK;fire.Color=ColorSequence.new(Style.White,color);fire.LightEmission=1
 fire.Size=NumberSequence.new({NK(0,g*.22),NK(1,0)});fire.Transparency=NumberSequence.new(0,1)
 fire.Lifetime=NumberRange.new(.16,.32);fire.Speed=NumberRange.new(3,10);fire.SpreadAngle=Vector2.new(22,22)
 fire.Rate=s.Tail*D;fire.EmissionDirection=Enum.NormalId.Back;fire.Parent=tail

 if s.Smoke then
  local smoke=Instance.new("ParticleEmitter") smoke.Texture=SMOKE;smoke.Color=ColorSequence.new(color:Lerp(SHADOW,.55))
  smoke.LightEmission=.25;smoke.Lifetime=NumberRange.new(.5,.8);smoke.Rate=18*D;smoke.Speed=NumberRange.new(2,5)
  smoke.Size=NumberSequence.new({NK(0,1.6*scale),NK(1,4.5*scale)});smoke.Transparency=NumberSequence.new({NK(0,.6),NK(1,1)})
  smoke.Rotation=NumberRange.new(0,360);smoke.RotSpeed=NumberRange.new(-40,40);smoke.EmissionDirection=Enum.NormalId.Back
  smoke.Parent=tail
 end
 if s.Light and FX.Lights then
  local l=Instance.new("PointLight") l.Color=color;l.Brightness=2.2;l.Range=16*scale;l.Shadows=false;l.Parent=p
 end
 symbol(p,spec.Symbol,color,s.Sym*scale)
end

function V.Rocket(cast,spec,origin,direction,opts)
 opts=opts or {}
 local s=ROCKETS[spec.Symbol] or ROCKETS["♠"]
 if opts.Lite then s=table.clone(s);s.Light=false;s.Smoke=false;s.Tail=s.Tail*.5 end
 local scale=opts.Scale or 1
 local p=part(cast,"TrueIllusion"..spec.Symbol.."Rocket",aimFrame(origin,direction),s.Core*scale,
  spec.Color:Lerp(Style.White,s.Tint),0,s.Ball and BALL or BLOCK)
 local ok,err=pcall(decorateRocket,p,spec,s,scale)
 if not ok then report("Rocket",err) end
 return p
end

function V.Burst(actor,pos,spec,params,direction)
 local radius,color=spec.Radius,spec.Color
 local cast=Effects.NewCast(actor,"TrueIllusionCardBurst",1.7)
 local hit=ground(pos,6,actor,params)
 local flat=hit~=nil and hit.Normal.Y>.5
 local ringPos=flat and hit.Position+hit.Normal*.2 or pos
 local ringNormal=flat and hit.Normal or direction or Vector3.yAxis

 V.Flash(cast,pos,Style.White,radius*1.5,.16)
 local shell=V.Flash(cast,pos,color,radius*2.1,.34)
 V.Ring(cast,ringPos,color,radius+1,.46,{Normal=ringNormal})
 if radius>=3 then V.Ring(cast,ringPos,Style.White,(radius+1)*.62,.34,{Normal=ringNormal,Width=.14}) end
 V.Sparks(cast,flat and hit.Position+hit.Normal*.3 or pos,{
  Count=math.clamp(radius*2.4,5,22),Up=flat and 1 or .2,Speed={radius*5,radius*13},Life={.3,.62},Gravity=60,
  Colors={color,Style.White,color:Lerp(Style.White,.55)},Size=Vector3.new(.14,.14,.8+radius*.06)})
 if radius>=3 then pop(cast,pos+Vector3.new(0,radius*.45,0),spec,math.clamp(radius*.9,3,8),radius*.5+2,.6) end
 if radius>=8 then V.Pillar(cast,flat and hit.Position or pos,color,36,radius*.28,.5) end
 if flat and FX.GroundSigils and radius>=3 then sigil(cast,hit.Position,hit.Normal,spec,(radius+1)*2,1.1) end
 if shell and FX.Lights and radius>=3 then
  local l=Instance.new("PointLight") l.Color=color;l.Brightness=3;l.Range=radius*3+6;l.Shadows=false;l.Parent=shell
  TweenService:Create(l,info(.34),{Brightness=0}):Play()
 end
end

for _,name in ipairs({"Flash","Ring","Pillar","Sparks","Summon","Teleport","Afterimage","FinaleStart","Finale","Muzzle","Burst",
 "AimLine","CloneCharge","Hazard","PrisonRing","DangerZone","Fizzle"}) do
 V[name]=guard(name,V[name])
end
 
function V.GunCharge(cast,muzzle,spec,windup)
 V.Flash(cast,muzzle,spec.Color,3,.2)
 for i=1,count(7) do
  local from=muzzle+randomUnit()*rng:NextNumber(3.5,5.8)
  local p=part(cast,"TrueIllusionCharge",aimFrame(from,(muzzle-from).Unit),Vector3.new(.14,.14,1.2),i%2==0 and Style.White or spec.Color,.1)
  Effects:Create(p,info(windup*.95,QUAD,IN),{CFrame=CFrame.new(muzzle)*p.CFrame.Rotation,Size=Vector3.new(.05,.05,.2),Transparency=.6}):Play()
  release(cast,windup+.05,p)
 end
end
function V.CardConverge(cast,point,colors,amount,radius,life)
 life=life or .4
 for i=1,count(amount or 12) do
  local from=point+randomUnit()*(radius or 6)
  local p=part(cast,"TrueIllusionCardBit",CFrame.new(from)*CFrame.Angles(rng:NextNumber(0,TAU),rng:NextNumber(0,TAU),0),Vector3.new(.5,.72,.04),colors[(i-1)%#colors+1],.15)
  Effects:Create(p,info(life,QUAD,IN),{CFrame=CFrame.new(point)*CFrame.Angles(rng:NextNumber(0,TAU),rng:NextNumber(0,TAU),0),Size=Vector3.new(.1,.15,.02),Transparency=.85}):Play()
  release(cast,life+.03,p)
 end
end
function V.Shockwave(cast,pos,color,radius,actor)
 local point,normal=groundPoint(pos,12,actor)
 V.Flash(cast,point+normal*1.5,Style.White,radius*.8,.18)
 V.Ring(cast,point,color,radius+1,.55,{Normal=normal,Width=.45,Start=.15})
 V.Ring(cast,point,Style.White,(radius+1)*.6,.4,{Normal=normal,Width=.25,Start=.15})
 V.Sparks(cast,point+normal*.4,{Count=16,Up=1,Speed={20,46},Life={.4,.8},Gravity=55,Colors={color,Style.White},Size=Vector3.new(.2,.2,1.1)})
 V.Sparks(cast,point+normal*.6,{Count=8,Card=true,Up=1,Speed={10,24},Life={.6,1},Gravity=20,Colors={color,Style.White,Style.Gold},Size=Vector3.new(.6,.85,.04)})
end
function V.GroundPoint(pos,reach,actor) return groundPoint(pos,reach or 14,actor) end
for _,name in ipairs({"GunCharge","CardConverge","Shockwave"}) do V[name]=guard(name,V[name]) end

return V
