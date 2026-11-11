local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local VFX=game.ReplicatedStorage:WaitForChild("VFXEngine")
local ASSETS=VFX:WaitForChild("Assets")
local P={}
local UP=Vector3.yAxis
local WHITE=Color3.new(1,1,1)
local GOLD=Color3.fromRGB(255,208,111)
local SHINE=Color3.fromRGB(255,246,214)
local AMBER=Color3.fromRGB(255,146,36)
local BRIGHT=Color3.fromRGB(255,214,60)
local UMBER=Color3.fromRGB(110,60,10)
local DUSK=Color3.fromRGB(60,34,8)
local RED=Color3.fromRGB(255,54,36)
local CRIMSON=Color3.fromRGB(150,14,10)
local BLUE=Color3.fromRGB(70,150,255)
local ICE=Color3.fromRGB(205,235,255)
local DEEP=Color3.fromRGB(16,36,110)
local NEON=Enum.Material.Neon
local FF=Enum.Material.ForceField
local BALL=Enum.PartType.Ball
local CYL=Enum.PartType.Cylinder
local HIDDEN=CFrame.new(0,-1e4,0)
local FLATCYL=CFrame.Angles(0,0,math.pi/2)
local FIRE_BODY="rbxassetid://17703378809"
local live={}  -- per-boss state shared between stages: the blue star, the risen rocks

local function part(g,size,color,alpha,shape,material)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Material=material or NEON p.Color=color p.Transparency=alpha or 0 p.Size=size p.CFrame=HIDDEN
 if shape then p.Shape=shape end
 p.Parent=g.Folder
 return p
end
local function rootOf(m)return m and m.Parent and m:FindFirstChild("HumanoidRootPart")end
local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end
local function ns(...)local k,v={...},{} for i=1,#k,2 do v[#v+1]=NumberSequenceKeypoint.new(k[i],k[i+1])end return NumberSequence.new(v)end
local function state(boss)live[boss]=live[boss]or{} return live[boss]end
 -- the floor under pos, looking past every character and the effect itself
local function groundAt(E,pos,g,extra)
 local ignore={g and g.Folder,extra}
 for _,pl in ipairs(Players:GetPlayers())do if pl.Character then ignore[#ignore+1]=pl.Character end end
 return E.Ground(pos+UP*4,ignore)or pos
end
local function params(g,extra)
 local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
 local ignore={g.Folder,extra}
 for _,pl in ipairs(Players:GetPlayers())do if pl.Character then ignore[#ignore+1]=pl.Character end end
 rp.FilterDescendantsInstances=ignore
 return rp
end
local function grade(E,props,t)
 local cc=Instance.new("ColorCorrectionEffect")
 for k,v in pairs(props)do cc[k]=v end
 cc.Parent=Lighting
 E.Tween(cc,t,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE})
 task.delay(t+.1,function()cc:Destroy()end)
end
local function dome(E,g,pos,color,d0,d1,t,alpha,material)
 local p=part(g,Vector3.one*d0,color,alpha or .2,BALL,material)
 p.CFrame=CFrame.new(pos)
 E.Tween(p,t,{Size=Vector3.one*d1,Transparency=1})
 return p
end
 -- a flat dark disc on the floor (unlit, so it reads on gold)
local function disc(g,pos,R,color,alpha)
 local p=part(g,Vector3.new(.06,R*2,R*2),color,alpha,CYL,Enum.Material.SmoothPlastic)
 p.CFrame=CFrame.new(pos+UP*.06)*FLATCYL
 return p
end
 -- a ring of flat beams lying in its carrier's XZ plane; set(radius, alpha, width) reshapes it
local function ring(g,radius,width,color,alpha,n,light)
 n=n or 48
 local carrier=part(g,Vector3.one*.2,WHITE,1)
 local pts,dirs,beams={},{},{}
 for i=1,n do
  local a=(i-1)/n*math.pi*2
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local at=Instance.new("Attachment") at.CFrame=CFrame.fromMatrix(dir*radius,UP,dir) at.Parent=carrier
  pts[i]=at dirs[i]=dir
 end
 for i=1,n do
  local b=Instance.new("Beam")
  b.Attachment0=pts[i] b.Attachment1=pts[i%n+1] b.FaceCamera=false b.Segments=1 b.LightEmission=light or 1 b.LightInfluence=0
  b.Width0=width b.Width1=width b.Color=ColorSequence.new(color) b.Transparency=NumberSequence.new(alpha) b.Parent=carrier
  beams[i]=b
 end
 local r={Carrier=carrier,Beams=beams,Alpha=alpha}
 function r.set(radius2,alpha2,width2)
  if radius2 then for i,at in ipairs(pts)do at.Position=dirs[i]*radius2 end end
  if alpha2 and math.abs(alpha2-r.Alpha)>.01 then r.Alpha=alpha2 local s=NumberSequence.new(alpha2) for _,b in ipairs(beams)do b.Transparency=s end end
  if width2 then for _,b in ipairs(beams)do b.Width0=width2 b.Width1=width2 end end
 end
 return r
end
 -- slivers flung out of c on arcs, spinning, gone by `life`
local function shards(E,g,c,n,speed,size,colors,life)
 local list={}
 for i=1,n do
  local a=math.random()*math.pi*2
  list[i]={P=part(g,Vector3.new(size*.22,size*.22,size)*(.6+math.random()*.8),colors[(i-1)%#colors+1],0),
   V=Vector3.new(math.cos(a),.5+math.random()*.9,math.sin(a))*speed*(.6+math.random()*.6),R=CFrame.Angles(math.random()*6,math.random()*6,0),
   S=(math.random()-.5)*20}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,s in ipairs(list)do
   parts[#parts+1]=s.P cfs[#cfs+1]=CFrame.new(c+s.V*t+Vector3.new(0,-45*t*t,0))*s.R*CFrame.Angles(t*s.S,t*s.S*.6,0)
   s.P.Transparency=math.clamp((t-life*.6)/(life*.4),0,1)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<life
 end)
end
 -- rock thrown up out of the floor
local function debris(E,g,c,n,power)
 power=power or 1
 local rocks={}
 for i=1,n do
  local p=part(g,Vector3.one*(.6+math.random()*1.6)*power,Color3.fromRGB(150,112,48),0,nil,Enum.Material.Slate)
  local a=math.random()*math.pi*2
  local out=(8+math.random()*18)*power
  rocks[i]={P=p,V=Vector3.new(math.cos(a)*out,(26+math.random()*26)*power,math.sin(a)*out),R=CFrame.Angles(math.random()*6,math.random()*6,0)}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,r in ipairs(rocks)do
   parts[#parts+1]=r.P cfs[#cfs+1]=CFrame.new(c+r.V*t+Vector3.new(0,-38*t*t,0))*r.R*CFrame.Angles(t*5,t*3,0)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>1.4 then for _,r in ipairs(rocks)do r.P.Transparency=1 end return false end
  return true
 end)
end
 -- glowing cracks split out across the floor from c (c is already on the floor)
local function cracks(E,g,c,R,n,color,life)
 local at=c+UP*.08
 for i=1,n do
  local a=(i-1)*math.pi*2/n+math.random()*.5
  local len=R*(.55+math.random()*.7)
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local cf=CFrame.lookAt(at+dir*len/2,at+dir*len)
  local p=part(g,Vector3.new(.3+math.random()*.35,.06,len),color,.05)
  local q=part(g,Vector3.new(1.6,.05,len),UMBER,.5,nil,Enum.Material.SmoothPlastic)
  p.CFrame=cf q.CFrame=cf
  E.Tween(p,life*.5,{Transparency=1},nil,nil,life*.5)
  E.Tween(q,life*.4,{Transparency=1},nil,nil,life*.4)
 end
end
 -- the slash meshes (VFXEngine.Assets): a bright core, a coloured glow copy behind it, a streak swirl
local function mesh(g,name,width,color,alpha)
 local template=ASSETS[name]
 local p=template:Clone()
 p.Size=template.Size*(width/template.Size.X)
 p.Color=color p.Transparency=alpha or 0 p.TextureID="" p.Material=NEON
 p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Anchored=true
 p.CFrame=HIDDEN p.Parent=g.Folder
 return p
end
local function slash(g,width,core,glow,streak)
 local layers={
  {Part=mesh(g,"ArcSlash",width,core,.02),Offset=CFrame.new()},
  {Part=mesh(g,"ArcSlash",width*1.16,glow,.38),Offset=CFrame.new(0,-width*.02,.2)},
 }
 if streak then
  layers[#layers+1]={Part=mesh(g,"StreakSlash",width*1.3,streak,.4),Offset=CFrame.new(0,0,.4)*CFrame.Angles(math.pi/2,0,0)}
 end
 for _,l in ipairs(layers)do l.Base=l.Part.Size l.Alpha=l.Part.Transparency end
 return layers
end
local function place(layers,frame,scale,fade,parts,cfs)
 for _,l in ipairs(layers)do
  if scale then l.Part.Size=l.Base*scale end
  if fade then l.Part.Transparency=l.Alpha+(1-l.Alpha)*fade end
  parts[#parts+1]=l.Part cfs[#cfs+1]=frame*l.Offset
 end
end
 -- a glowing image on a thin plate, seen from both sides (vertical sigils)
local function plate(g,size,image,color,brightness)
 local p=part(g,Vector3.new(size,size,.05),WHITE,1)
 local imgs={}
 for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back})do
  local sg=Instance.new("SurfaceGui") sg.Face=face sg.LightInfluence=0 sg.Brightness=brightness or 3 sg.CanvasSize=Vector2.new(512,512)
  sg.Parent=p
  local img=Instance.new("ImageLabel") img.Size=UDim2.fromScale(1,1) img.BackgroundTransparency=1 img.Image=image img.ImageColor3=color
  img.ImageTransparency=1 img.Parent=sg
  imgs[#imgs+1]=img
 end
 return p,imgs
end
 -- lightning: midpoint displacement (each pass halves the segments and the jitter), a hot core inside a glow
local function jag(a,b,depth,disp)
 local pts={a,b}
 for _=1,depth do
  local nxt={pts[1]}
  for i=1,#pts-1 do
   local p,q=pts[i],pts[i+1]
   local dir=q-p
   local perp=dir:Cross(Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5))
   perp=perp.Magnitude>1e-3 and perp.Unit or Vector3.xAxis
   nxt[#nxt+1]=(p+q)/2+perp*(math.random()-.5)*disp
   nxt[#nxt+1]=q
  end
  pts=nxt
  disp*=.55
 end
 return pts
end
local function bolt(E,g,a,b,o)
 o=o or{}
 local w=o.Width or .35
 local pts=jag(a,b,o.Depth or 4,o.Jitter or(a-b).Magnitude*.18)
 local list={}
 for i=1,#pts-1 do
  local p,q=pts[i],pts[i+1]
  local cf=CFrame.lookAt((p+q)/2,q)
  local len=(q-p).Magnitude+.1
  local core=part(g,Vector3.new(w,w,len),o.Core or SHINE,0)
  local glow=part(g,Vector3.new(w*3,w*3,len),o.Glow or BRIGHT,.7)
  core.CFrame=cf glow.CFrame=cf
  list[#list+1]=core list[#list+1]=glow
 end
 local life=o.Life or .2
 for _,p in ipairs(list)do E.Tween(p,life,{Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In)end
 task.delay(life+.05,function()for _,p in ipairs(list)do p:Destroy()end end)
 for _=1,o.Branches or 0 do
  local i=math.random(2,math.max(2,#pts-2))
  local from=pts[i]
  local ahead=pts[math.min(i+2,#pts)]-from
  if ahead.Magnitude>.1 then
   local L=(a-b).Magnitude
   local side=ahead.Unit:Cross(Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5))
   side=side.Magnitude>1e-3 and side.Unit or Vector3.xAxis
   bolt(E,g,from,from+ahead.Unit*L*.22+side*L*.14,{Depth=3,Width=w*.55,Life=life*.8,Core=o.Core,Glow=o.Glow})
  end
 end
 return pts
end
 -- a flame/spark suck: particles drawn in from a sphere's surface to its centre
local function suck(E,g,pos,R,color,rate,life)
 local s=part(g,Vector3.one*R*2,WHITE,1)
 s.CFrame=CFrame.new(pos)
 local m=Instance.new("ParticleEmitter")
 m.Texture=E.Lib.Id("star.tiny") m.Shape=Enum.ParticleEmitterShape.Sphere m.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 m.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward m.Speed=NumberRange.new(R/(life or .35)*.9,R/(life or .35)) m.Lifetime=NumberRange.new(life or .35)
 m.Size=ns(0,1,1,0) m.Color=ColorSequence.new(SHINE,color or GOLD) m.LightEmission=1 m.LightInfluence=0 m.Rate=(rate or 80)*E.Quality
 m.Parent=s
 return s,m
end
local function sword(g,len)
 local blade=part(g,Vector3.new(.3,1.1,len),SHINE,0)
 local edge=part(g,Vector3.new(.5,1.5,len*1.04),BRIGHT,.55)
 local guard=part(g,Vector3.new(.4,3,.45),GOLD,0,nil,Enum.Material.Metal)
 local hilt=part(g,Vector3.new(.3,.3,1.4),UMBER,0,nil,Enum.Material.Metal)
 return {Parts={blade,edge,guard,hilt},Offsets={CFrame.new(0,0,-len/2),CFrame.new(0,0,-len/2),CFrame.new(),CFrame.new(0,0,.7)}}
end
local function placeSword(s,frame,parts,cfs)
 for i,p in ipairs(s.Parts)do parts[#parts+1]=p cfs[#cfs+1]=frame*s.Offsets[i]end
end
 -- an afterimage: every visible part of `model` copied as it stands, fading out over `life`
local function echo(E,g,model,color,alpha,life)
 local list={}
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("BasePart")and p.Name~="HumanoidRootPart"and p.Transparency<.9 and p.Size.Magnitude<12 then
   local q=part(g,p.Size,color,alpha) q.CFrame=p.CFrame
   list[#list+1]=q
   E.Tween(q,life,{Transparency=1})
  end
 end
 E.After(g,life+.05,function()for _,q in ipairs(list)do q:Destroy()end end)
end

-- Normal attacks: Fang-Dive, Fang-Cross, Fang-Pierce, Sword Dancer
 -- he flashes yellow: the warning that a Fang attack is coming
function P.Flash(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5Flash")
 local T=d.Time or .4
 local h=Instance.new("Highlight")
 h.FillColor=BRIGHT h.OutlineColor=SHINE h.FillTransparency=.15 h.OutlineTransparency=0 h.DepthMode=Enum.HighlightDepthMode.Occluded
 h.Adornee=boss h.Parent=g.Folder
 local a=E.Anchor(g,r.CFrame)
 E.Sprite(a,{tex="star.glare",size={{0,2},{.3,14},{1,4}},alpha={{0,.2},{.5,.3},{1,1}},color=SHINE,spin={60,60}},T)
 E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.3,.5},speed={10,22},spread=180},16)
 E.Light(g,a,BRIGHT,18,6,T)
 E.Step(g,function(_,t)
  local root=rootOf(boss)
  if root then a.CFrame=root.CFrame end
  local k=math.clamp(t/T,0,1)
  h.FillTransparency=1-(1-k)*(.55+.45*math.cos(k*math.pi*4))*.85
  h.OutlineTransparency=k
  return t<T
 end)
 E.After(g,T+.1,function()g:Destroy()end)
end
 -- Enhanced Jump Kick: a small RED mark on the floor where the kick will land, closing in on itself (the Jump Kick's mark is gold)
function P.KickMark(E,d)
 local g=E.Group("P5KickMark")
 local T,R=d.Time or .5,d.Radius or 8
 local c=d.Pos
 local mark=disc(g,c,R,CRIMSON,1)
 local edge=ring(g,R,.5,RED,1,48)
 edge.Carrier.CFrame=CFrame.new(c+UP*.14)
 local core=part(g,Vector3.one,RED,0,BALL)
 core.CFrame=CFrame.new(c+UP*.5)
 local a=E.Anchor(g,CFrame.new(c+UP*2))
 E.Light(g,a,RED,R*2,3,T+.1)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  mark.Transparency=1-.55*smooth(k*2)
  edge.set(R*(1.5-.5*k),1-.9*smooth(k*2))
  core.Size=Vector3.one*(1+4*k)
  return t<T
 end)
 E.After(g,T+.1,function()g:Destroy()end)
end
 -- a streak from the top of a leap down to where he lands
function P.Dive(E,d)
 local g=E.Group("P5Dive")
 local T=d.Time or .22
 local dir=d.To-d.From
 local A=E.Anchor(g,CFrame.lookAt(d.From,d.To))
 local B=E.Anchor(g,CFrame.lookAt(d.From,d.To))
 local a0=E.Attach(A) local a1=E.Attach(B)
 local hot=d.Tint=="Enhanced"  -- the Enhanced Jump Kick drops in red
 local core=E.Beam(g,a0,a1,{color=hot and Color3.fromRGB(255,190,170) or SHINE,width0=.3,width1=d.Kick and 2.8 or 2.2,alpha={{0,1},{.6,.2},{1,0}},segments=2})
 local glow=E.Beam(g,a0,a1,{tex="beam.streaks",color=hot and RED or GOLD,width0=1,width1=d.Kick and 8 or 6,alpha={{0,1},{.5,.5},{1,.1}},scroll=4,segments=2})
 local s=E.Stream(B,{tex="wind.dash",size={{0,2.4},{1,.5}},alpha={{0,.3},{1,1}},color=hot and RED or SHINE,life={.15,.3},speed={10,20},spread=25,orient="velocity"},60)
 E.Sprite(B,{tex="star.crisp",size=d.Kick and 7 or 5,alpha={{0,.1},{1,.6}},color=hot and RED or WHITE},T)
 E.Step(g,function(_,t)
  local k=math.min(t/T,1)
  local p=d.From:Lerp(d.To,k*k)
  B.CFrame=CFrame.lookAt(p,p+dir)
  if k>=1 then
   s.Enabled=false
   E.Tween(core,.25,{Width0=0,Width1=0}) E.Tween(glow,.3,{Width0=0,Width1=0})
   return false
  end
  return true
 end)
 E.After(g,T+.6,function()g:Destroy()end)
end
 -- the dive's barrage: cuts flashing all over the landing circle, then the floor cracks
function P.Barrage(E,d)
 local g=E.Group("P5Barrage")
 local n,every,R=d.Count or 8,d.Every or .07,d.Radius or 12
 local c=d.Pos
 local a=E.Anchor(g,CFrame.new(c+UP))
 E.Light(g,a,BRIGHT,R*2,3,n*every+.3)
 for i=1,n do
  E.After(g,(i-1)*every,function()
   local ang=math.random()*math.pi*2
   local off=Vector3.new(math.cos(ang),0,math.sin(ang))*math.random()*R*.55
   local side=i%2==1 and 1 or -1
   local base=CFrame.new(c+off+UP*(1.5+math.random()*2))*CFrame.Angles(0,math.random()*math.pi*2,0)
    *CFrame.Angles(0,0,side*(.3+math.random()*.5))*CFrame.Angles(-math.pi/2,0,0)
   local layers=slash(g,R*(.8+math.random()*.5),SHINE,GOLD,i%3==0 and BRIGHT or nil)
   local t0=os.clock()
   E.Step(g,function()
    local t=os.clock()-t0
    local k=math.clamp(t/.07,0,1)
    local parts,cfs={},{}
    place(layers,base*CFrame.Angles(0,0,side*(1-(1-k)^3)*.9),.8+.3*k,t<.06 and 0 or math.clamp((t-.06)/.12,0,1),parts,cfs)
    workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
    if t>=.2 then for _,l in ipairs(layers)do l.Part:Destroy()end return false end
    return true
   end)
   E.Emit(a,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.2,.35},speed={18,34},spread=80,dir=Enum.NormalId.Top},6)
  end)
 end
 E.After(g,n*every,function()
  cracks(E,g,c,R,7,BRIGHT,1.2)
  E.Emit(a,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.5},{1,1}},color=Color3.fromRGB(150,120,70),life={.6,1},speed={12,20},spread=80,
   dir=Enum.NormalId.Top,drag=3},10)
 end)
 E.After(g,n*every+1.6,function()g:Destroy()end)
end
 -- Sword Dancer: a ring of gold swords rises, turns to point at the middle, the lanes darken on the floor, then they fly
function P.SwordRing(E,d)
 local g=E.Group("P5SwordRing")
 local pts=d.Points
 local n=#pts
 local T,stag,speed,reach=d.Time or 1.1,d.Stagger or .03,d.Speed or 170,d.Reach or 64
 local center=d.Center
 local floorY=center.Y-2.5
 local swords={}
 for i,p in ipairs(pts)do
  local dir=(center-p).Unit
  local s=sword(g,9)
  local t0=Instance.new("Attachment") t0.Position=Vector3.new(0,.42,0) t0.Parent=s.Parts[1]
  local t1=Instance.new("Attachment") t1.Position=Vector3.new(0,-.42,0) t1.Parent=s.Parts[1]
  local trail=Instance.new("Trail") trail.Attachment0=t0 trail.Attachment1=t1 trail.Lifetime=.14 trail.LightEmission=1 trail.LightInfluence=0
  trail.Color=ColorSequence.new(SHINE,GOLD) trail.Transparency=ns(0,.2,1,1) trail.FaceCamera=true trail.Enabled=false trail.Parent=s.Parts[1]
  local flat=Vector3.new(dir.X,0,dir.Z).Unit
  local foot=Vector3.new(p.X,floorY+.07,p.Z)
  local strip=part(g,Vector3.new(.8,.05,reach),UMBER,1,nil,Enum.Material.SmoothPlastic)
  strip.CFrame=CFrame.lookAt(foot,foot+flat)*CFrame.new(0,0,-reach/2)
  local line=part(g,Vector3.new(.14,.05,reach),SHINE,1)
  line.CFrame=strip.CFrame*CFrame.new(0,.01,0)
  swords[i]={S=s,From=p,Dir=dir,Spawn=(i-1)/n*.35,Launch=T+(i-1)*stag,Trail=trail,Strip=strip,Line=line}
 end
 local mark=disc(g,Vector3.new(center.X,floorY,center.Z),4,DUSK,1)
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  local alive=false
  for _,w in ipairs(swords)do
   if not w.Done then
    alive=true
    local frame=HIDDEN
    if t>=w.Spawn and t<w.Launch then
     local k=smooth((t-w.Spawn)/.25)
     local pos=w.From-UP*4*(1-k)+UP*math.sin(t*6+w.Spawn*20)*.15
     frame=CFrame.lookAt(pos,pos+UP):Lerp(CFrame.lookAt(pos,center),smooth((t-w.Spawn)/math.max(T*.55,.2)))
     if not w.Shown then
      w.Shown=true
      E.Emit(E.Anchor(g,CFrame.new(w.From)),{tex="star.crisp",size={{0,1.6},{1,0}},color={{0,WHITE},{1,GOLD}},life={.25,.4},speed={6,14},spread=180},8)
     end
     -- (no lane warning on the floor any more)
    elseif t>=w.Launch then
     local u=t-w.Launch
     local dist=speed*u
     w.Trail.Enabled=true
     local pos=w.From+w.Dir*dist
     frame=CFrame.lookAt(pos,pos+w.Dir)

     if dist>=reach then
      w.Done=true frame=HIDDEN w.Trail.Enabled=false
      E.Emit(E.Anchor(g,CFrame.new(pos)),{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.2,.3},speed={10,20},spread=180},5)
     end
    end
    placeSword(w.S,frame,parts,cfs)
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return alive
 end)
 E.After(g,T+n*stag+reach/speed+1,function()g:Destroy()end)
end

 -- Light Jab: a glint at the rapier's point as he levels it
function P.JabReady(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5JabReady")
 local T=d.Time or .35
 local a=E.Anchor(g,r.CFrame*CFrame.new(1,.6,-4.5))
 E.Sprite(a,{tex="star.glare",size={{0,1},{.6,9},{1,2}},alpha={{0,.4},{.6,.1},{1,1}},color=SHINE,spin={90,90}},T+.1)
 E.Light(g,a,BRIGHT,10,4,T+.1)
 E.Step(g,function(_,t)local root=rootOf(boss) if root then a.CFrame=root.CFrame*CFrame.new(1,.6,-4.5)end return t<T end)
 E.After(g,T+.3,function()g:Destroy()end)
end
 -- one stab: a hot needle of light shot out to the reach, gone in a blink (the last one bigger, with a burst of air)
function P.Jab(E,d)
 local g=E.Group("P5Jab")
 local big=d.Big
  -- d.Pattern: the dashes the server hurts along ({X lateral, Z0 start depth, Len}); each is a needle of light that flicks out
  -- along its own lane, so one stab is a spray of rapiers with gaps between them
 local list=d.Pattern or {{X=0,Z0=0,Len=d.Reach or 19}}
 local w=big and .9 or .4
 local hold=big and .34 or .26
 local needles={}
 for i,r in ipairs(list)do
  local frame=d.Frame*CFrame.new(r.X,.5+(math.random()-.5)*.6,-r.Z0)
  local tip=E.Anchor(g,frame*CFrame.new(0,0,-r.Len))
  E.Sprite(tip,{tex="star.crisp",size={{0,big and 6 or 3},{1,0}},alpha={{0,0},{1,1}},color=WHITE},.14)
  needles[i]={Frame=frame,Len=r.Len,Core=part(g,Vector3.new(w,w,1),SHINE,0),Glow=part(g,Vector3.new(w*3.2,w*3.2,1),BRIGHT,.65),
   Delay=math.random()*.035,Tip=tip}
 end
 if big and #needles>0 then
  local tip=needles[math.ceil(#needles/2)].Tip
  E.Sprite(tip,{tex="ring.crisp",size={{0,1},{1,14}},alpha={{0,.1},{1,1}},color=SHINE},.25)
  E.Emit(tip,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.25,.45},speed={20,40},spread=50,dir=Enum.NormalId.Front},14)
  E.Light(g,tip,BRIGHT,16,5,.3)
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,nd in ipairs(needles)do
   local tt=math.max(t-nd.Delay,0)
   local k=math.clamp(tt/.04,0,1)
   local len=math.max(nd.Len*(1-(1-k)^2),.1)
   local f=nd.Frame*CFrame.new(0,0,-len/2)
   local fade=math.clamp((tt-hold*.4)/(hold*.6),0,1)
   nd.Core.Size=Vector3.new(w*(1-fade*.8),w,len) nd.Glow.Size=Vector3.new(w*3.2,w*3.2,len)
   nd.Core.Transparency=fade nd.Glow.Transparency=.65+.35*fade
   parts[#parts+1]=nd.Core cfs[#cfs+1]=f parts[#parts+1]=nd.Glow cfs[#cfs+1]=f
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<hold+.1
 end)
 E.After(g,hold+.6,function()g:Destroy()end)
end
 -- Disgeneration: a gold ribbon traced along the backflip's arc
function P.Backflip(E,d)
 local g=E.Group("P5Backflip")
 local T,H=d.Time or .75,d.Height or 22
 local a=E.Anchor(g,CFrame.new(d.From))
 local a0=E.Attach(a,CFrame.new(0,1.6,0)) local a1=E.Attach(a,CFrame.new(0,-1.6,0))
 local tr=Instance.new("Trail") tr.Attachment0=a0 tr.Attachment1=a1 tr.Lifetime=.35 tr.LightEmission=1 tr.LightInfluence=0
 tr.Color=ColorSequence.new(SHINE,GOLD) tr.Transparency=ns(0,.25,1,1) tr.Parent=a
 local s=E.Stream(a,{tex="star.tiny",size={{0,.8},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.5},speed={1,4},spread=180},40)
 E.Step(g,function(_,t)
  local k=math.min(t/T,1)
  a.CFrame=CFrame.new(d.From:Lerp(d.To,k)+UP*H*4*k*(1-k))*CFrame.Angles(math.pi*2*smooth(k),0,0)
  if k>=1 then s.Enabled=false tr.Enabled=false return false end
  return true
 end)
 E.After(g,T+.6,function()g:Destroy()end)
end
function P.Land(E,d)
 local g=E.Group("P5Land")
 local R=d.Radius or 12
 local c=d.Pos
 local a=E.Anchor(g,CFrame.new(c+UP*.3))
 E.Sprite(a,{tex="ring.thick",orient="flat",light=0,size={{0,2},{1,R*2.4}},alpha={{0,.35},{1,1}},color=UMBER},.35)
 E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,6}},alpha={{0,.45},{1,1}},color=Color3.fromRGB(160,130,80),life={.5,.9},speed={R*1.4,R*2},spread=90,
  dir=Enum.NormalId.Top,drag=4},12)
 cracks(E,g,c,R*.8,6,BRIGHT,.9)
 E.After(g,1.5,function()g:Destroy()end)
end
 -- Plasma Ball: chevrons flowing out along each ball's line, dark on the floor with a bright thread
function P.PlasmaArrows(E,d)
 local g=E.Group("P5PlasmaArrows")
 local T,L=d.Time or .8,d.Length or 34
 local o=d.Origin
 local arrows={}
 for i,dir in ipairs(d.Dirs)do
  local base=CFrame.lookAt(o+UP*.08,o+UP*.08+dir)
  local shaft=part(g,Vector3.new(1.2,.05,L),DUSK,1,nil,Enum.Material.SmoothPlastic)
  shaft.CFrame=base*CFrame.new(0,0,-L/2-4)
  local core=part(g,Vector3.new(.2,.05,L),SHINE,1)
  core.CFrame=shaft.CFrame*CFrame.new(0,.01,0)
  local chev={}
  for k=1,3 do chev[k]={L=part(g,Vector3.new(.4,.06,3.4),BRIGHT,1),R=part(g,Vector3.new(.4,.06,3.4),BRIGHT,1)}end
  arrows[i]={Base=base,Shaft=shaft,Core=core,Chev=chev}
 end
 E.Step(g,function(_,t)
  local show=smooth(t/T*3)
  local parts,cfs={},{}
  for _,a in ipairs(arrows)do
   a.Shaft.Transparency=1-.6*show a.Core.Transparency=1-.7*show
   for j,c in ipairs(a.Chev)do
    local u=(t*1.6+j/3)%1
    local at=a.Base*CFrame.new(0,.02,-(4+u*L))
    parts[#parts+1]=c.L cfs[#cfs+1]=at*CFrame.Angles(0,math.rad(40),0)*CFrame.new(0,0,1.7)
    parts[#parts+1]=c.R cfs[#cfs+1]=at*CFrame.Angles(0,math.rad(-40),0)*CFrame.new(0,0,1.7)
    c.L.Transparency=1-.9*math.sin(u*math.pi)*show c.R.Transparency=c.L.Transparency
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T
 end)
 E.After(g,T,function()g:Destroy()end)
end
 -- the balls: a white-gold core in a turning gold shell, a swirl and a glow round it, all swelling as it rolls
function P.PlasmaBalls(E,d)
 local g=E.Group("P5PlasmaBalls")
 local speed,R,s0,s1=d.Speed or 52,d.Range or 220,d.Size0 or 3,d.Size1 or 18
 local o=d.Origin
 local rp=params(g,d.Boss)
 local balls={}
 for i,dir in ipairs(d.Dirs)do
  local hit=workspace:Raycast(o,dir*R,rp)
  local a=E.Anchor(g,CFrame.new(o))
  balls[i]={Dir=dir,Stop=hit and hit.Distance or R,A=a,
   Core=part(g,Vector3.one*s0*.55,SHINE,0,BALL),Shell=part(g,Vector3.one*s0,GOLD,.25,BALL,FF),
   Glow=E.Stream(a,{tex="glow.soft",size=s0*2.2,alpha={{0,.55},{1,1}},color=BRIGHT,life={.12,.16},locked=true},30),
   Swirl=E.Stream(a,{tex="swirl.white",size=s0*1.2,alpha={{0,.4},{1,1}},color=SHINE,life={.2,.3},spin={-300,300},locked=true},12),
   Sparks=E.Stream(a,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,WHITE},{1,AMBER}},life={.3,.6},speed={2,6},spread=180,drag=2},20),
   L=E.Light(g,a,BRIGHT,s0*3,2)}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  local any=false
  local dist=math.min(speed*t,R)
  local size=s0+(s1-s0)*dist/R
  for _,b in ipairs(balls)do
   if not b.Done then
    any=true
    local pos=o+b.Dir*dist
    b.Core.Size=Vector3.one*size*.55 b.Shell.Size=Vector3.one*size
    parts[#parts+1]=b.Core cfs[#cfs+1]=CFrame.new(pos)
    parts[#parts+1]=b.Shell cfs[#cfs+1]=CFrame.new(pos)*CFrame.Angles(t*3,t*2,0)
    parts[#parts+1]=b.A cfs[#cfs+1]=CFrame.new(pos)
    b.Glow.Size=NumberSequence.new(size*2.2) b.Swirl.Size=NumberSequence.new(size*1.2) b.L.Range=size*3
    if dist>=b.Stop then
     b.Done=true
     b.Glow.Enabled=false b.Swirl.Enabled=false b.Sparks.Enabled=false b.Core.Transparency=1 b.Shell.Transparency=1 b.L.Brightness=0
     E.Emit(b.A,{tex="star.crisp",size={{0,1.4},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.5},speed={size*2,size*4},spread=180},14)
     E.Sprite(b.A,{tex="glow.soft",size={{0,size*2},{1,size*3.5}},alpha={{0,.3},{1,1}},color=BRIGHT},.3)
    end
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return any
 end)
 E.After(g,R/speed+1,function()g:Destroy()end)
end
 -- a stamp: dust, a dark ring thrown out over the floor, a flash at the foot (Charge: the gold gathering first)
function P.Stomp(E,d)
 local g=E.Group("P5Stomp")
 local c=d.Pos
 local a=E.Anchor(g,CFrame.new(c+UP*.4))
 if d.Charge then
  local T=d.Time or .5
  local r=ring(g,14,.5,SHINE,.3,40)
  r.Carrier.CFrame=CFrame.new(c+UP*.12)
  local _,m=suck(E,g,c+UP*2,8,GOLD,90,.3)
  E.Light(g,a,BRIGHT,16,3,T)
  E.Step(g,function(_,t)local k=math.clamp(t/T,0,1) r.set(14*(1-k)+1.5,.3+.6*k) return t<T end)
  E.After(g,T,function()m.Enabled=false end)
  E.After(g,T+.6,function()g:Destroy()end)
  return
 end
 E.Sprite(a,{tex="ring.thick",orient="flat",light=0,size={{0,3},{1,28}},alpha={{0,.35},{1,1}},color=UMBER},.3)
 E.Sprite(a,{tex="flare.burst",size={{0,4},{1,10}},alpha={{0,.2},{1,1}},color=SHINE},.15)
 E.Emit(a,{tex="smoke",light=0,size={{0,2.5},{1,7}},alpha={{0,.5},{1,1}},color=Color3.fromRGB(170,140,90),life={.5,.8},speed={30,45},spread=88,
  dir=Enum.NormalId.Top,drag=5},10)
 E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.25,.4},speed={20,40},spread=70,dir=Enum.NormalId.Top,
  accel=Vector3.new(0,-40,0)},10)
 E.Light(g,a,BRIGHT,20,4,.25)
 E.After(g,1.2,function()g:Destroy()end)
end
 -- Ultra Red. Server clock: the tiles start at d.At and turn at d.Spin rad/s, so every client draws them where the
 -- server hurts. The star (red core, crimson shell, gold flecks orbiting like loose tiles), its first circle, the
 -- arms of floor tiles (beams on one turning carrier - one CFrame a frame moves them all), then the stop and the
 -- wider circle. The two blasts are the server's JudgementBoom.
function P.RedOrb(E,d)
 local g=E.Group("P5UltraRed")
 local c,orbAt=d.Pos,d.Orb
 local tell,warm,spinT,stop=d.Tell or 1.2,d.Warm or .9,d.SpinTime or 6,d.Stop or 2
 local arms,start,spin=d.Arms or 4,d.Start or 0,d.Spin or .85
 local big=d.OrbSize or 34
 local inner,outer,width=d.Inner or 16,d.Outer or 150,math.rad(d.Width or 26)
 local R,final=d.Radius or 40,d.Final or 50
 local at=d.At or workspace:GetServerTimeNow()+tell
 local core=part(g,Vector3.one,Color3.fromRGB(255,200,160),0,BALL)
 local shell=part(g,Vector3.one*2,RED,.2,BALL,FF)
 local halo=E.Anchor(g,CFrame.new(orbAt))
 local glow=E.Stream(halo,{tex="glow.soft",size=12,alpha={{0,.5},{1,1}},color=RED,life={.15,.2},locked=true},24)
 E.Sprite(halo,{tex="star.lens",size={{0,4},{1,16}},alpha={{0,.5},{.9,.3},{1,1}},color=Color3.fromRGB(255,170,120),spin={60,60}},tell+warm+spinT+stop)
 local light=E.Light(g,halo,RED,40,2)
 local flecks={}
 for i=1,14 do flecks[i]={P=part(g,Vector3.new(1.4,1.4,.25),i%3==0 and SHINE or BRIGHT,0),A=i/14*math.pi*2,S=(i%2==0 and 1 or -1)*1.2,Y=.05+math.random()*.55}end
 -- the centre is a HALF CIRCLE covering the ground: a dome exactly as wide as the blast that hurts, its lower half in the floor
 local blastDisc=part(g,Vector3.one*R*2,CRIMSON,1,BALL,FF)
 blastDisc.CFrame=CFrame.new(c)
 local blastRing=ring(g,R,.8,RED,1,64,0)
 blastRing.Carrier.CFrame=CFrame.new(c+UP*.14)
 local carrier=part(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=CFrame.new(c+UP*.1)
 local tiles,edges,flames={},{},{}
 local function beam(p0,p1,axis,w0,w1,lit)
  local i0=Instance.new("Attachment") i0.CFrame=CFrame.fromMatrix(p0,UP,axis) i0.Parent=carrier
  local i1=Instance.new("Attachment") i1.CFrame=CFrame.fromMatrix(p1,UP,axis) i1.Parent=carrier
  local b=Instance.new("Beam")
  b.Attachment0=i0 b.Attachment1=i1 b.FaceCamera=false b.Segments=1 b.LightEmission=lit and 1 or 0 b.LightInfluence=0
  b.Width0=w0 b.Width1=w1 b.Color=ColorSequence.new(lit and BRIGHT or CRIMSON) b.Transparency=NumberSequence.new(1) b.Parent=carrier
  return b
 end
  -- each line runs right across the arena through the star, two tiles wide, broken by the gap under it
 local lines,hw=d.Lines or 2,d.HalfWidth or 7
 for k=0,lines-1 do
  local a0=k*math.pi/lines
  local dir=Vector3.new(math.cos(a0),0,math.sin(a0))
  local perp=Vector3.new(-dir.Z,0,dir.X)
  for _,sgn in ipairs({-1,1})do
   local dd=dir*sgn
   tiles[#tiles+1]=beam(dd*inner,dd*outer,perp,hw*2,hw*2)  -- one unbroken strip per half line (no pile of tiles)
   for _,side in ipairs({-1,1})do edges[#edges+1]=beam(dd*inner+perp*hw*side,dd*outer+perp*hw*side,perp,.6,.9,true)end
   edges[#edges+1]=beam(dd*inner-perp*hw,dd*inner+perp*hw,dd,.7,.7,true)  -- the bright end of the gap
  end
 end
 local finalDisc=part(g,Vector3.one*final*2,CRIMSON,1,BALL,FF)
 finalDisc.CFrame=CFrame.new(c)
 local finalRing=ring(g,final,1,RED,1,72,0)
 finalRing.Carrier.CFrame=CFrame.new(c+UP*.16)
 local phase="charge"
 local tileAlpha=1
 local function tileFade(alpha)
  if math.abs(alpha-tileAlpha)<.02 then return end
  tileAlpha=alpha
  local s=NumberSequence.new(alpha)
  for _,b in ipairs(tiles)do b.Transparency=s end
 end
 E.Step(g,function(dt,t)
  local s=workspace:GetServerTimeNow()-at
  local orb
  local turn=start+spin*math.max(s,0)
  local tilesEnd=warm+spinT
  local spinning=s>=0 and s<tilesEnd
  if s<0 then
   local k=math.clamp(1+s/tell,0,1)
   orb=big*(1+.03*math.sin(t*9))
  elseif s<tilesEnd then
   if phase=="charge" then phase="warm" blastDisc.Size=Vector3.one*R*2 blastDisc.Transparency=.1 E.Tween(blastDisc,.6,{Transparency=1}) blastRing.set(R,1)end
   orb=big*(1+.02*math.sin(s*5))
   carrier.CFrame=CFrame.new(c+UP*.1)*CFrame.Angles(0,-turn,0)
   if s<warm then
    tileFade(1-.55*smooth(s/warm))
    local e=NumberSequence.new(1-.5*smooth(s/warm)) for _,b in ipairs(edges)do b.Transparency=e end
   elseif phase~="hot" then
    phase="hot"
    local hot=ColorSequence.new(Color3.fromRGB(255,84,34))
    for _,b in ipairs(tiles)do b.Color=hot b.LightEmission=.25 end
    tileAlpha=-1 tileFade(.28)
    local e=NumberSequence.new(.08) for _,b in ipairs(edges)do b.Transparency=e end
    for _,f in ipairs(flames)do f.Rate=16*E.Quality f.Enabled=true end
   end
  elseif s<tilesEnd+stop then
   if phase~="stop" then
    phase="stop"
    for _,f in ipairs(flames)do f.Enabled=false end
    local e=NumberSequence.new(1) for _,b in ipairs(edges)do b.Transparency=e end
   end
   local u=(s-tilesEnd)/stop
   tileFade(math.min(1,.28+u*2.5))
   orb=big*(1+.04*math.sin(s*14))
  else
   finalDisc.Size=Vector3.one*final*2 finalDisc.Transparency=.1 E.Tween(finalDisc,.7,{Transparency=1}) finalRing.set(final,1) tileFade(1)
   core.Transparency=1 shell.Transparency=1 glow.Enabled=false light.Brightness=0
   for _,f in ipairs(flecks)do f.P.Transparency=1 end
   return false
  end
  core.Size=Vector3.one*orb*.6 shell.Size=Vector3.one*orb
  local parts,cfs={core,shell,halo},{CFrame.new(orbAt),CFrame.new(orbAt)*CFrame.Angles(t,t*1.3,0),CFrame.new(orbAt)}
  for _,f in ipairs(flecks)do
   f.A+=dt*f.S*(spinning and 1 or .1)
   parts[#parts+1]=f.P cfs[#cfs+1]=CFrame.new(orbAt+Vector3.new(math.cos(f.A),f.Y,math.sin(f.A))*orb*.78)*CFrame.Angles(0,-f.A,0)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  glow.Size=NumberSequence.new(orb*2) light.Brightness=2+orb*.3
  return true
 end)
 E.After(g,math.max(at-workspace:GetServerTimeNow(),0)+warm+spinT+stop+2,function()g:Destroy()end)
end
 -- Ultra Blue: the stolen star over his head - an ice-white core in a blue shell, a gold band turning round it
function P.BlueOrb(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r and not d.Pos then return end
 local g=E.Group("P5UltraBlue")  -- d.Pos: the star hangs fixed in the sky instead of following him
 local T,H,S,rise=d.Time or 6,d.Height or 16,d.Size or 14,d.Rise or 1
 local st=state(boss)
 if st.Blue then st.Blue:Destroy()end
 st.Blue=g st.BlueHeight=H
 local core=part(g,Vector3.one,ICE,0,BALL)
 local shell=part(g,Vector3.one,BLUE,.15,BALL,FF)
 local rim=part(g,Vector3.one,DEEP,.55,BALL,FF)
 local a=E.Anchor(g,r and r.CFrame or CFrame.new(d.Pos))
 local glow=E.Stream(a,{tex="glow.soft",size=S*2,alpha={{0,.5},{1,1}},color=BLUE,life={.15,.2},locked=true},24)
 local sw=E.Stream(a,{tex="swirl.blue",size=S*1.3,alpha={{0,.35},{1,1}},color=ICE,life={.4,.6},spin={-120,120},locked=true},6)
 E.Stream(a,{tex="star.tiny",size={{0,.8},{1,0}},color={{0,WHITE},{1,BLUE}},life={.4,.8},speed={2,8},spread=180,drag=1},25)
 local light=E.Light(g,a,BLUE,S*3,3)
 local band=ring(g,S*.75,.35,BRIGHT,.1,48)
 local band2=ring(g,S*.85,.2,SHINE,.3,48)
 E.Step(g,function(_,t)
  local root=rootOf(boss)
  if not root and not d.Pos then return false end
  local k=smooth(t/rise)
  local s=S*(.15+.85*k)+math.sin(t*4)*.3
  local p=d.Pos and(d.Pos-UP*18*(1-k))or root.Position+UP*H*(.4+.6*k)  -- fixed in the sky, rising the last stretch as it swells
  core.Size=Vector3.one*s*.6 shell.Size=Vector3.one*s rim.Size=Vector3.one*s*1.12
  band.set(s*.7) band2.set(s*.8)
  workspace:BulkMoveTo({core,shell,rim,a,band.Carrier,band2.Carrier},{CFrame.new(p),CFrame.new(p)*CFrame.Angles(t*.7,t,0),
   CFrame.new(p)*CFrame.Angles(-t*.5,t*.3,0),CFrame.new(p),CFrame.new(p)*CFrame.Angles(math.rad(70),t*1.4,0),
   CFrame.new(p)*CFrame.Angles(math.rad(-60),-t*1.1,math.rad(20))},Enum.BulkMoveMode.FireCFrameChanged)
  glow.Size=NumberSequence.new(s*2) sw.Size=NumberSequence.new(s*1.3) light.Range=s*3
  st.BlueAt=p st.BlueSize=s
  return t<T
 end)
 E.After(g,T,function()g:Destroy() if st.Blue==g then st.Blue=nil end end)
end
 -- the beam's tell: rings closing in on the star, the last one landing as it fires, and a faint line to its mark
function P.BluePulse(E,d)
 local boss=d.Boss
 local st=state(boss)
 local g=E.Group("P5BluePulse")
 local T=d.Time or .75
 local function orb()local r=rootOf(boss) return st.BlueAt or(r and r.Position+UP*16)or Vector3.zero end
 local a=E.Anchor(g,CFrame.new(orb()))
 local size=st.BlueSize or 14
 for i=0,2 do
  E.After(g,T*i/3,function()
   E.Sprite(a,{tex="ring.crisp",size={{0,size*4},{1,size*.9}},alpha={{0,1},{.3,.2},{1,0}},color=ICE},T/3+.02)
  end)
 end
 local mark=E.Anchor(g,CFrame.new(orb()))
 local line=E.Beam(g,E.Attach(a),E.Attach(mark),{color=BLUE,width=.2,alpha=.9,segments=1})
 E.Step(g,function(_,t)
  local vr=rootOf(d.Victim)
  a.CFrame=CFrame.new(orb())
  if vr then mark.CFrame=CFrame.new(vr.Position)end
  local k=math.clamp(t/T,0,1)
  line.Transparency=NumberSequence.new(.9-.6*k) line.Width0=.15+.5*k line.Width1=.15+.5*k
  return t<T
 end)
 E.After(g,T+.05,function()g:Destroy()end)
end
function P.BlueBeam(E,d)
 local g=E.Group("P5BlueBeam")
 local from,to,w=d.From,d.To,d.Width or 3
 local len=(to-from).Magnitude
 local cf=CFrame.lookAt((from+to)/2,to)
 for _,l in ipairs({{w*.45,WHITE,0},{w*1.1,ICE,.35},{w*2.2,BLUE,.7}})do
  local p=part(g,Vector3.new(l[1],l[1],len),l[2],l[3])
  p.CFrame=cf
  E.Tween(p,.3,{Transparency=1,Size=Vector3.new(0,0,len)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 end
 local thread=part(g,Vector3.new(.18,.18,len),BRIGHT,0)
 thread.CFrame=cf*CFrame.new(w*.55,0,0)
 E.Tween(thread,.25,{Transparency=1})
 local hit=E.Anchor(g,CFrame.new(to))
 E.Sprite(hit,{tex="flare.burst",size={{0,w*2},{1,w*6}},alpha={{0,0},{1,1}},color=ICE},.2)
 E.Sprite(hit,{tex="ring.crisp",size={{0,w},{1,w*8}},alpha={{0,.2},{1,1}},color=BRIGHT},.3)
 E.Emit(hit,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,BLUE}},life={.2,.4},speed={20,40},spread=180},14)
 E.Light(g,hit,BLUE,20,5,.3)
 local mouth=E.Anchor(g,CFrame.new(from))
 E.Sprite(mouth,{tex="star.lens",size={{0,w*3},{1,w*7}},alpha={{0,.1},{1,1}},color=ICE},.25)
 E.After(g,.6,function()g:Destroy()end)
end
 -- the throw: the blast circle and the shell's reach on the floor, the star's flight, the blast, then the tall shell
function P.BlueThrow(E,d)
 local boss=d.Boss
 local st=state(boss)
 local g=E.Group("P5BlueThrow")
 local tell,T=d.Tell or .8,d.Time or .55
 local coreR=d.Core or 14  -- the throw is one plain explosion of this radius (no growing shell)
 local to=d.To
 local mark=disc(g,to,coreR,DEEP,1)
 local edge=ring(g,coreR,.6,ICE,1,48)
 edge.Carrier.CFrame=CFrame.new(to+UP*.14)
 local orb
 E.Step(g,function(_,t)
  local k=math.clamp(t/(tell+T),0,1)
  if not(orb and orb.Landed)then
   mark.Transparency=1-.5*smooth(k*2)
   edge.set(coreR*(1.4-.4*k),1-.8*smooth(k*2))
  end
  if t>=tell and not orb then
   if st.Blue then st.Blue:Destroy() st.Blue=nil end
   local from=st.BlueAt or d.From
   local size=st.BlueSize or 14
   local a=E.Anchor(g,CFrame.new(from))
   orb={From=from,Size=size,A=a,Core=part(g,Vector3.one*size*.6,ICE,0,BALL),Shell=part(g,Vector3.one*size,BLUE,.15,BALL,FF),
    Glow=E.Stream(a,{tex="glow.soft",size=size*2,alpha={{0,.5},{1,1}},color=BLUE,life={.12,.16},locked=true},30)}
   local tr=Instance.new("Trail") tr.Attachment0=E.Attach(a,CFrame.new(0,size*.3,0)) tr.Attachment1=E.Attach(a,CFrame.new(0,-size*.3,0))
   tr.Lifetime=.25 tr.LightEmission=1 tr.LightInfluence=0 tr.FaceCamera=true tr.Color=ColorSequence.new(ICE,BLUE) tr.Transparency=ns(0,.3,1,1)
   tr.Parent=a
  end
  if orb and not orb.Landed then
   local u=math.clamp((t-tell)/T,0,1)
   local p=orb.From:Lerp(to+UP*2,u*u)+UP*8*math.sin(u*math.pi)
   workspace:BulkMoveTo({orb.Core,orb.Shell,orb.A},{CFrame.new(p),CFrame.new(p)*CFrame.Angles(t*3,t*2,0),CFrame.new(p)},Enum.BulkMoveMode.FireCFrameChanged)
   if u>=1 then
    orb.Landed=t
    orb.Core.Transparency=1 orb.Shell.Transparency=1 orb.Glow.Enabled=false
    mark.Transparency=1 edge.set(coreR,1)
    local a=E.Anchor(g,CFrame.new(to+UP*2))
     -- the flash, then three domes: a white-hot core, the ice-blue body, a deep-blue shell that hangs a moment
    dome(E,g,to+UP*2,WHITE,4,coreR*1.6,.15,.1)
    dome(E,g,to+UP*2,ICE,coreR*.8,coreR*2.8,.45,.1)
    dome(E,g,to+UP*2,BLUE,coreR,coreR*3.4,.8,.35,FF)
    dome(E,g,to+UP*2,DEEP,coreR*1.6,coreR*2.2,1.4,.45,FF)
     -- a pillar of light straight up out of it, collapsing
     -- a hard ring racing out over the floor
    local burst=ring(g,coreR,2.2,ICE,0,72)
    burst.Carrier.CFrame=CFrame.new(to+UP*.25)
    local t0=os.clock()
    E.Step(g,function()
     local u=math.clamp((os.clock()-t0)/.45,0,1)
     burst.set(coreR+coreR*2.6*smooth(u),u,2.2*(1-u*.7))
     return u<1
    end)
    E.Sprite(a,{tex="flare.big",size={{0,coreR*2},{1,coreR*5}},alpha={{0,.3},{1,1}},color=BLUE},.35)
    E.Sprite(a,{tex="star.lens",size={{0,coreR*2},{1,coreR*5}},alpha={{0,.45},{1,1}},color=ICE,spin={60,60}},.4)
    E.Emit(a,{tex="star.crisp",size={{0,1.8},{1,0}},color={{0,WHITE},{1,BLUE}},life={.4,.9},speed={50,100},spread=180,drag=2},40)
    E.Emit(a,{tex="star.tiny",size={{0,1},{1,0}},color={{0,ICE},{1,BRIGHT}},life={1,1.8},speed={20,50},spread=80,dir=Enum.NormalId.Top,
     accel=Vector3.new(0,-25,0),drag=1},30)
     -- the smoke: a column climbing out of it and a skirt thrown along the ground
    E.Emit(a,{tex="smoke",light=0,size={{0,coreR*.6},{.5,coreR*1.6},{1,coreR*2}},alpha={{0,.4},{.5,.55},{1,1}},
     color={{0,Color3.fromRGB(70,95,150)},{1,Color3.fromRGB(30,36,60)}},life={1.4,2.2},speed={18,34},spread=55,dir=Enum.NormalId.Top,drag=1.5,
     accel=Vector3.new(0,6,0)},18)
    E.Emit(a,{tex="smoke",light=0,size={{0,4},{1,12}},alpha={{0,.5},{1,1}},color=Color3.fromRGB(80,90,120),life={.8,1.2},speed={coreR*3,coreR*4.5},
     spread=88,dir=Enum.NormalId.Top,drag=5},20)
    for i=1,7 do
     local ang=i/7*math.pi*2+math.random()*.4
     local tip=to+Vector3.new(math.cos(ang),0,math.sin(ang))*coreR*(1.6+math.random())+UP*(2+math.random()*6)
     bolt(E,g,to+UP*3,tip,{Depth=3,Width=.3,Life=.28,Core=WHITE,Glow=BLUE,Jitter=coreR*.25})
    end
    E.Light(g,a,BLUE,coreR*5,6,.8)
    shards(E,g,to,18,45,3.2,{ICE,BLUE,BRIGHT},1.1)  -- (no dirt, cracks or scorch left on the floor)
    grade(E,{Brightness=.1,Contrast=.3,Saturation=.1,TintColor=Color3.fromRGB(185,205,255)},.7)
   end
  end
  if orb and orb.Landed then return t<orb.Landed+.1 end
  return true
 end)
 E.After(g,tell+T+3,function()g:Destroy()end)
end
 -- Blast Breath: the great sigil burning in front of him (both faces), its twin on the floor, light drawn into it
function P.Sigil(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5Sigil")
 local T=d.Time or 2.4
 local big,imgs=plate(g,22,E.Lib.Id("sigil.mandala"),BRIGHT,4)
 local small,imgs2=plate(g,12,E.Lib.Id("sigil.ring"),SHINE,5)
 local a=E.Anchor(g,r.CFrame)
 local floor=E.Anchor(g,CFrame.new((d.Pos or r.Position)+UP*.2))
 E.Sprite(floor,{tex="sigil.mandala2",orient="flat",light=0,size={{0,10},{.3,44},{1,46}},alpha={{0,1},{.3,.35},{.9,.35},{1,1}},color=UMBER,spin={20,20}},T+.4)
 local sk,m=suck(E,g,r.Position,15,AMBER,120,.4)
 local light=E.Light(g,a,AMBER,30,1)
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  local k=math.clamp(t/T,0,1)
  local front=root.CFrame*CFrame.new(0,1.5,-7)
  local s=14+10*smooth(k)
  big.Size=Vector3.new(s,s,.05)
  workspace:BulkMoveTo({big,small,a,sk},{front*CFrame.Angles(0,0,t*.6),front*CFrame.new(0,0,-.3)*CFrame.Angles(0,0,-t*1.4),front,front},
   Enum.BulkMoveMode.FireCFrameChanged)
  for _,i in ipairs(imgs)do i.ImageTransparency=1-.9*smooth(k*2.5)end
  for _,i in ipairs(imgs2)do i.ImageTransparency=1-.95*smooth((k-.3)*2.5)end
  light.Brightness=1+6*k light.Range=30+20*k
  if k>=1 then
   m.Enabled=false
   for _,i in ipairs(imgs)do E.Tween(i,.3,{ImageTransparency=1})end
   for _,i in ipairs(imgs2)do E.Tween(i,.3,{ImageTransparency=1})end
   return false
  end
  return true
 end)
 E.After(g,T+.6,function()g:Destroy()end)
end
 -- the breath: a white-hot core, the gold flame body and an amber outer lick as camera-facing beams (a cone from any
 -- side), flipbook flame and smoke thrown from his mouth, fire licking up off the floor along its path, embers
function P.Breath(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5Breath")
 local T,R,base=d.Time or 8,d.Range or 320,d.Base or 5
 local deg=d.Spread or 9
 local tan=math.tan(math.rad(deg))
 local rp=params(g,boss)
 local floorY=groundAt(E,r.Position,g,boss).Y
 local mouth=E.Anchor(g,r.CFrame)
 local far=E.Anchor(g,r.CFrame)
 local m0=E.Attach(mouth) local f0=E.Attach(far)
 local flame=Instance.new("ParticleEmitter")
 flame.Texture=FIRE_BODY flame.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4 flame.FlipbookMode=Enum.ParticleFlipbookMode.OneShot
 flame.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,250,220)),ColorSequenceKeypoint.new(.2,BRIGHT),
  ColorSequenceKeypoint.new(.55,AMBER),ColorSequenceKeypoint.new(1,Color3.fromRGB(90,40,10))})
 flame.LightEmission=.35 flame.LightInfluence=0 flame.Brightness=1.6
 flame.Size=ns(0,base*.8,.3,base*3,1,base*6) flame.Transparency=ns(0,.1,.6,.3,1,1)
 flame.Lifetime=NumberRange.new(1.2,1.6) flame.Speed=NumberRange.new(170,230) flame.Drag=.5
 flame.SpreadAngle=Vector2.new(deg,deg) flame.EmissionDirection=Enum.NormalId.Front
 flame.Rotation=NumberRange.new(0,360) flame.RotSpeed=NumberRange.new(-60,60) flame.Rate=70*E.Quality flame.Parent=mouth
 local smoke=E.Stream(mouth,{tex="smoke",light=0,size={{0,base},{1,base*7}},alpha={{0,.6},{.4,.4},{1,1}},
  color={{0,Color3.fromRGB(70,48,30)},{1,Color3.fromRGB(30,26,26)}},life={1.6,2.4},speed={120,170},spread=deg,dir=Enum.NormalId.Front,drag=.5,
  accel=Vector3.new(0,6,0)},18)
 local embers=E.Stream(mouth,{tex="star.tiny",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={1,1.8},speed={150,220},spread=deg*1.6,
  dir=Enum.NormalId.Front,drag=.3},40)
 local spots={}
 for _,dist in ipairs({40,100,170,250,340,440,540})do
  if dist<R then
   local w=base+dist*tan
   local a=E.Anchor(g,CFrame.new(r.Position))
   a.Size=Vector3.new(w*1.6,.2,w*1.2)
   local e=E.Stream(a,{tex="fire",size={{0,math.min(w*.5,26)},{1,3}},alpha={{0,.35},{1,1}},color={{0,SHINE},{.4,BRIGHT},{1,AMBER}},life={.35,.6},
    speed={6,14},spread=25,dir=Enum.NormalId.Top},12)
   e.Shape=Enum.ParticleEmitterShape.Box
   spots[#spots+1]={A=a,D=dist,E=e}
  end
 end
 E.Sprite(mouth,{tex="star.lens",size={{0,base*2},{.5,base*3},{1,base*2}},alpha={{0,.2},{1,.4}},color=SHINE,spin={40,40}},T)
 local light=E.Light(g,mouth,AMBER,40,6)
 local farLight=E.Light(g,far,AMBER,50,4)
 grade(E,{TintColor=Color3.fromRGB(255,235,205),Contrast=.08},T+.5)
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  local lookv=root.CFrame.LookVector
  local o=root.Position+UP*1.6+lookv*2.5
  local m=CFrame.lookAt(o,o+lookv)
  local hit=workspace:Raycast(o,lookv*R,rp)
  local len=hit and hit.Distance or R
  local parts,cfs={mouth,far},{m,m*CFrame.new(0,0,-len)}
  for _,s in ipairs(spots)do
   local p=o+lookv*s.D
   local q=Vector3.new(p.X,floorY+.3,p.Z)
   parts[#parts+1]=s.A cfs[#cfs+1]=CFrame.lookAt(q,q+lookv)
   s.E.Enabled=s.D<len and t<T
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=T then flame.Enabled=false smoke.Enabled=false embers.Enabled=false light.Brightness=0 farLight.Brightness=0 return false end
  return true
 end)
 E.After(g,T+2.5,function()g:Destroy()end)
end
 -- Lightning Dash's cue: gold arcs crackling over him, a hard glint, the light flickering
function P.DashCue(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5DashCue")
 local T=d.Time or .9
 local a=E.Anchor(g,r.CFrame)
 E.Sprite(a,{tex="star.glare2",size={{0,1},{.7,12},{1,0}},alpha={{0,.3},{1,.2}},color=SHINE,spin={200,200}},T)
 local light=E.Light(g,a,BRIGHT,16,2)
 local nextArc=0
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  a.CFrame=root.CFrame*CFrame.new(0,1.5,-1)
  if t>=nextArc and t<T then
   nextArc=t+.06
   local p1=root.Position+Vector3.new(math.random()-.5,math.random()-.3,math.random()-.5)*5
   bolt(E,g,p1,p1+Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*6,{Depth=3,Width=.15,Life=.08,Jitter=1.2})
   light.Brightness=1+math.random()*5
  end
  return t<T
 end)
 E.After(g,T+.3,function()g:Destroy()end)
end
 -- the flurry: fists of light snapping out in front of him, little shock rings where they land, arcs on his arms
function P.Punches(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5Punches")
 local T=d.Time or 5
 local fists={}
 for i=1,10 do fists[i]={P=part(g,Vector3.new(1.2,1.2,2.2),SHINE,1),G=part(g,Vector3.new(2,2,4.5),BRIGHT,1),T=-1,At=CFrame.new()}end
 local a=E.Anchor(g,r.CFrame)
 local air=E.Stream(a,{tex="wind.dash",size={{0,3},{1,1}},alpha={{0,.4},{1,1}},color=SHINE,life={.12,.2},speed={50,80},spread=30,dir=Enum.NormalId.Front,
  orient="velocity"},40)
 local light=E.Light(g,a,BRIGHT,14,3)
 local k,nextFist,nextRing,nextArc=1,0,0,0
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  local cf=root.CFrame
  a.CFrame=cf*CFrame.new(0,.8,-3)
  if t<T and t>=nextFist then
   nextFist=t+.035
   local f=fists[k] k=k%#fists+1
   f.T=t f.At=CFrame.new((math.random()-.5)*5,.5+(math.random()-.5)*3,0)
  end
  local parts,cfs={},{}
  for _,f in ipairs(fists)do
   local u=(t-f.T)/.12
   if f.T>=0 and u<=1 then
    local fc=cf*f.At*CFrame.new(0,0,-(2+u*5))
    parts[#parts+1]=f.P cfs[#cfs+1]=fc parts[#parts+1]=f.G cfs[#cfs+1]=fc*CFrame.new(0,0,1)
    f.P.Transparency=.1+.9*u f.G.Transparency=.6+.4*u
   else
    f.P.Transparency=1 f.G.Transparency=1
   end
  end
  if #parts>0 then workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)end
  if t<T and t>=nextRing then
   nextRing=t+.12
   local ra=E.Anchor(g,cf*CFrame.new((math.random()-.5)*4,.5+(math.random()-.5)*2,-6.5))
   E.Sprite(ra,{tex="ring.crisp",size={{0,1},{1,6}},alpha={{0,.2},{1,1}},color=SHINE},.15)
   E.Emit(ra,{tex="star.crisp",size={{0,.7},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.12,.2},speed={15,30},spread=60,dir=Enum.NormalId.Front},4)
   task.delay(.4,function()ra:Destroy()end)
  end
  if t<T and t>=nextArc then
   nextArc=t+.1
   local arm=cf*CFrame.new((math.random()-.5)*3,.6,-1.5)
   bolt(E,g,arm.Position,(arm*CFrame.new((math.random()-.5)*2,(math.random()-.5)*2,-4)).Position,{Depth=2,Width=.12,Life=.07,Jitter=1})
  end
  light.Brightness=t<T and 2+math.random()*2 or 0
  if t>=T then air.Enabled=false end
  return t<T+.15
 end)
 E.After(g,T+.6,function()g:Destroy()end)
end
function P.PunchFinish(E,d)
 local g=E.Group("P5PunchFinish")
 local f=d.Frame*CFrame.new(0,.8,-5)
 local a=E.Anchor(g,f)
 E.Sprite(a,{tex="flare.burst2",size={{0,4},{1,16}},alpha={{0,0},{1,1}},color=SHINE},.2)
 E.Sprite(a,{tex="ring.thick",size={{0,2},{1,20}},alpha={{0,.1},{1,1}},color=BRIGHT},.3)
 E.Emit(a,{tex="wind.dash",size={{0,4},{1,1}},alpha={{0,.2},{1,1}},color=SHINE,life={.2,.35},speed={60,110},spread=25,dir=Enum.NormalId.Front,
  orient="velocity"},20)
 E.Emit(a,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.3,.5},speed={30,60},spread=50,dir=Enum.NormalId.Front},20)
 E.Light(g,a,BRIGHT,24,8,.3)
 for _=1,3 do
  bolt(E,g,f.Position,(f*CFrame.new((math.random()-.5)*8,(math.random()-.5)*6,-8-math.random()*6)).Position,{Depth=3,Width=.2,Life=.15})
 end
 grade(E,{Brightness=.15,Contrast=.15},.3)
 E.After(g,1,function()g:Destroy()end)
end
 -- wind drawn in from all round across the floor: streaks and dust sliding inward (a disc emitter, inward)
local function windField(E,g,R,rate)
 local field=part(g,Vector3.new(R*2,1,R*2),WHITE,1)
 local streaks=Instance.new("ParticleEmitter")
 streaks.Texture=E.Lib.Id("wind.dash") streaks.Shape=Enum.ParticleEmitterShape.Disc streaks.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 streaks.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward streaks.Orientation=Enum.ParticleOrientation.VelocityParallel
 streaks.Speed=NumberRange.new(R*.8,R*1.1) streaks.Lifetime=NumberRange.new(.8,1) streaks.Size=ns(0,2.4,1,.8)
 streaks.Color=ColorSequence.new(WHITE,SHINE) streaks.Transparency=ns(0,1,.2,.4,1,1) streaks.LightEmission=.6 streaks.LightInfluence=0
 streaks.Rate=rate*E.Quality streaks.Parent=field
 local dust=Instance.new("ParticleEmitter")
 dust.Texture=E.Lib.Id("smoke") dust.Shape=Enum.ParticleEmitterShape.Disc dust.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 dust.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward dust.Speed=NumberRange.new(R*.45,R*.6) dust.Lifetime=NumberRange.new(1.2,1.6)
 dust.Size=ns(0,3,1,8) dust.Color=ColorSequence.new(Color3.fromRGB(190,160,105),Color3.fromRGB(120,100,60)) dust.Transparency=ns(0,1,.3,.7,1,1)
 dust.LightEmission=0 dust.LightInfluence=0 dust.Rate=rate*.3*E.Quality dust.Parent=field
 return field,{streaks,dust}
end
function P.WindPull(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5WindPull")
 local T,R=d.Time or 1.6,d.Range or 90
 local field,emitters=windField(E,g,R,60)
 local a=E.Anchor(g,r.CFrame)
 E.Sprite(a,{tex="swirl.white",orient="flat",size={{0,6},{1,22}},alpha={{0,.6},{.8,.5},{1,1}},color=SHINE,spin={-300,-300}},T)
 E.Stream(a,{tex="swirl.lines",size=10,alpha={{0,.6},{1,1}},color=SHINE,life={.3,.4},spin={-400,-200},locked=true},8)
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  local fl=groundAt(E,root.Position,g,boss)
  workspace:BulkMoveTo({field,a},{CFrame.new(fl+UP*.6),CFrame.new(fl+UP*.3)},Enum.BulkMoveMode.FireCFrameChanged)
  return t<T
 end)
 E.After(g,T,function()for _,e in ipairs(emitters)do e.Enabled=false end end)
 E.After(g,T+1.2,function()g:Destroy()end)
end
 -- a straight lane lit on the floor ahead of him: dark strip, bright edges, a fill running out to its end
function P.Lane(E,d)
 local g=E.Group("P5Lane")
 local L,W,T=d.Length or 170,d.Width or 7,d.Time or .35
 local f=d.Frame
 local strip=part(g,Vector3.new(W*2,.05,L),DUSK,1,nil,Enum.Material.SmoothPlastic)
 strip.CFrame=f*CFrame.new(0,.07,-L/2)
 local e1=part(g,Vector3.new(.25,.06,L),SHINE,1) e1.CFrame=f*CFrame.new(-W,.09,-L/2)
 local e2=part(g,Vector3.new(.25,.06,L),SHINE,1) e2.CFrame=f*CFrame.new(W,.09,-L/2)
 local fill=part(g,Vector3.new(W*1.6,.05,1),BRIGHT,1)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  strip.Transparency=1-.5*smooth(k*3) e1.Transparency=1-.85*smooth(k*3) e2.Transparency=e1.Transparency
  local len=math.max(L*smooth(k),.1)
  fill.Size=Vector3.new(W*1.6,.05,len) fill.CFrame=f*CFrame.new(0,.08,-len/2) fill.Transparency=.75
  return t<T
 end)
 E.After(g,T,function()for _,p in ipairs({strip,e1,e2,fill})do E.Tween(p,.25,{Transparency=1})end end)
 E.After(g,T+.4,function()g:Destroy()end)
end
 -- The Wind's cut: an upright crescent of wind running down the lane, dust thrown off its foot, a scar left behind
function P.WindSlash(E,d)
 local g=E.Group("P5WindSlash")
 local L,S,W=d.Length or 170,d.Speed or 320,d.Width or 7
 local f=d.Frame
 local layers=slash(g,W*3.2,SHINE,GOLD,WHITE)
 local a=E.Anchor(g,f)
 local dust=E.Stream(a,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.5},{1,1}},color=Color3.fromRGB(180,150,95),life={.5,.8},speed={10,20},spread=70,
  dir=Enum.NormalId.Top,drag=3},50)
 local wind=E.Stream(a,{tex="wind.dash",size={{0,3},{1,1}},alpha={{0,.3},{1,1}},color=WHITE,life={.15,.25},speed={30,60},spread=50,dir=Enum.NormalId.Back,
  orient="velocity"},50)
 local light=E.Light(g,a,BRIGHT,18,4)
 local T=L/S
 local scar=part(g,Vector3.new(.5,.06,1),BRIGHT,.1)
 local burn=part(g,Vector3.new(2.2,.05,1),UMBER,.45,nil,Enum.Material.SmoothPlastic)
 E.Step(g,function(_,t)
  local k=math.min(t/T,1)
  local z=L*k
  local parts,cfs={a},{f*CFrame.new(0,.5,-z)}
  place(layers,f*CFrame.new(0,W*1.1,-z)*CFrame.Angles(0,0,math.pi/2)*CFrame.Angles(-math.pi/2,0,0),1,k>.85 and(k-.85)/.15 or 0,parts,cfs)
  local len=math.max(z,.1)
  scar.Size=Vector3.new(.5,.06,len) burn.Size=Vector3.new(2.2,.05,len)
  parts[#parts+1]=scar cfs[#cfs+1]=f*CFrame.new(0,.09,-len/2)
  parts[#parts+1]=burn cfs[#cfs+1]=f*CFrame.new(0,.07,-len/2)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if k>=1 then
   dust.Enabled=false wind.Enabled=false light.Brightness=0
   for _,l in ipairs(layers)do l.Part.Transparency=1 end
   E.Tween(scar,.8,{Transparency=1}) E.Tween(burn,1,{Transparency=1})
   return false
  end
  return true
 end)
 E.After(g,T+1.5,function()g:Destroy()end)
end
 -- Great Wind: the gale over the whole floor, a vortex turning under him, the air packed into a ball at his chest
function P.GreatWind(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5GreatWind")
 local T,C=d.Time or 3.6,d.Charge or 3
 local field,emitters=windField(E,g,140,90)
 local orb=part(g,Vector3.one,SHINE,.1,BALL,FF)
 local core=part(g,Vector3.one,WHITE,0,BALL)
 local a=E.Anchor(g,r.CFrame)
 E.Stream(a,{tex="swirl.white",size=14,alpha={{0,.5},{1,1}},color=SHINE,life={.3,.45},spin={-500,-250},locked=true},10)
 local floorA=E.Anchor(g,r.CFrame)
 for i=1,3 do
  E.Sprite(floorA,{tex="swirl.lines",orient="flat",light=0,size={{0,10*i},{1,26*i}},alpha={{0,.7},{.8,.55},{1,1}},color=UMBER,spin={-150*i,-150*i}},T)
 end
 local light=E.Light(g,a,BRIGHT,24,2)
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  local fl=groundAt(E,root.Position,g,boss)
  local k=math.clamp(t/C,0,1)
  local s=1+6*smooth(k)+math.sin(t*20)*.2*k
  orb.Size=Vector3.one*s core.Size=Vector3.one*s*.45
  local at=root.Position+UP*1.5+root.CFrame.LookVector*2
  workspace:BulkMoveTo({field,floorA,a,orb,core},{CFrame.new(fl+UP*.6),CFrame.new(fl+UP*.25),CFrame.new(at),CFrame.new(at)*CFrame.Angles(t*4,t*5,0),
   CFrame.new(at)},Enum.BulkMoveMode.FireCFrameChanged)
  light.Brightness=2+6*k light.Range=24+20*k
  if t>=C then for _,e in ipairs(emitters)do e.Enabled=false end end
  if t>=T then orb.Transparency=1 core.Transparency=1 return false end
  return true
 end)
 E.After(g,T+1.2,function()g:Destroy()end)
end
 -- Gilded Cataclysm's rocks: slate split by veins of gold
local function rock(g,size)
 local body=part(g,Vector3.new(size,size*.85,size*1.1),Color3.fromRGB(96,78,52),0,nil,Enum.Material.Slate)
 local vein=part(g,Vector3.new(size*.25,size*.9,size*.2),BRIGHT,0)
 local vein2=part(g,Vector3.new(size*.9,size*.2,size*.22),GOLD,.1)
 return {Parts={body,vein,vein2},Offsets={CFrame.new(),CFrame.new(size*.1,0,-size*.48)*CFrame.Angles(0,0,.4),
  CFrame.new(-size*.1,size*.1,size*.5)*CFrame.Angles(0,.3,.2)}}
end
local function placeRock(rk,frame,parts,cfs)for i,p in ipairs(rk.Parts)do parts[#parts+1]=p cfs[#cfs+1]=frame*rk.Offsets[i]end end
function P.RockRise(E,d)
 local boss=d.Boss
 local g=E.Group("P5RockRise")
 local T=d.Time or .6
 local st=state(boss)
 if st.Rocks then st.Rocks.G:Destroy()end
 local list={}
 local baseY=d.Base and d.Base.Y or d.Seats[1].Y-8
 for i,seat in ipairs(d.Seats)do
  local rk=rock(g,2.2+math.random()*1.4)
  rk.Seat=seat rk.Spin=CFrame.Angles(math.random()*6,math.random()*6,math.random()*6) rk.Rot=(math.random()-.5)*3
  list[i]=rk
  local a=E.Anchor(g,CFrame.new(seat.X,baseY+.3,seat.Z))
  E.Emit(a,{tex="smoke",light=0,size={{0,1.5},{1,4}},alpha={{0,.5},{1,1}},color=Color3.fromRGB(150,120,80),life={.4,.7},speed={6,12},spread=80,
   dir=Enum.NormalId.Top,drag=3},4)
 end
 if d.Base then cracks(E,g,d.Base,12,8,BRIGHT,T+1)end
 st.Rocks={G=g,List=list}
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  local k=smooth(t/T)
  for _,rk in ipairs(list)do
   if not rk.Thrown then
    local pos=Vector3.new(rk.Seat.X,baseY-2,rk.Seat.Z):Lerp(rk.Seat,k)+UP*math.sin(t*3+rk.Rot)*.3
    placeRock(rk,CFrame.new(pos)*rk.Spin*CFrame.Angles(0,t*rk.Rot,0),parts,cfs)
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T+6
 end)
 E.After(g,T+6.5,function()g:Destroy() if st.Rocks and st.Rocks.G==g then st.Rocks=nil end end)
end
 -- one rock hurled: its landing circle (dark, a bright ring closing on it), the arc with a gold trail, the impact
function P.RockThrow(E,d)
 local boss=d.Boss
 local g=E.Group("P5RockThrow")
 local T,R=d.Time or .4,d.Radius or 9
 local st=state(boss)
 local rk=st.Rocks and st.Rocks.List[d.Index]
 if rk then rk.Thrown=true else rk=rock(g,2.8)end
 local to=d.To
 local mark=disc(g,to,R,DUSK,.55)
 local edge=ring(g,R*1.5,.5,SHINE,.2,40)
 edge.Carrier.CFrame=CFrame.new(to+UP*.14)
 local a=E.Anchor(g,CFrame.new(d.From))
 local tr=Instance.new("Trail") tr.Attachment0=E.Attach(a,CFrame.new(0,1,0)) tr.Attachment1=E.Attach(a,CFrame.new(0,-1,0))
 tr.Lifetime=.18 tr.LightEmission=1 tr.LightInfluence=0 tr.FaceCamera=true tr.Color=ColorSequence.new(SHINE,AMBER) tr.Transparency=ns(0,.3,1,1) tr.Parent=a
 local spin=CFrame.Angles(math.random()*6,math.random()*6,0)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local p=d.From:Lerp(to+UP,k)+UP*(d.Arc or 10)*4*k*(1-k)
  local parts,cfs={a},{CFrame.new(p)}
  placeRock(rk,CFrame.new(p)*spin*CFrame.Angles(t*14,t*9,0),parts,cfs)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  edge.set(R*(1.5-.5*k))
  if k>=1 then
   for _,q in ipairs(rk.Parts)do q.Transparency=1 end
   mark.Transparency=1 edge.set(R,1) tr.Enabled=false
   local b=E.Anchor(g,CFrame.new(to+UP*.5))
   E.Sprite(b,{tex="flare.burst",size={{0,R},{1,R*2.6}},alpha={{0,.1},{1,1}},color=SHINE},.18)
   E.Sprite(b,{tex="ring.thick",orient="flat",light=0,size={{0,2},{1,R*2.6}},alpha={{0,.3},{1,1}},color=UMBER},.35)
   E.Emit(b,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.45},{1,1}},color=Color3.fromRGB(150,120,80),life={.6,1},speed={R*1.5,R*2.5},spread=80,
    dir=Enum.NormalId.Top,drag=4},10)
   E.Light(g,b,BRIGHT,R*3,5,.3)
   debris(E,g,to,6,.8)
   shards(E,g,to,6,30,1.6,{BRIGHT,SHINE},.8)
   cracks(E,g,to,R,6,BRIGHT,1)
   return false
  end
  return true
 end)
 E.After(g,T+1.8,function()g:Destroy()end)
end
 -- The Great Storm: a roof of dark cloud over the whole map lit amber from under, rain over this player, the light
 -- going grey, sheet lightning flickering inside the cloud
function P.Storm(E,d)
 local g=E.Group("P5Storm")
 local T=d.Time or 20
 local c=d.Pos
 local roof=part(g,Vector3.new(520,4,520),WHITE,1)
 roof.CFrame=CFrame.new(c+UP*110)
 local clouds=E.Stream(roof,{tex="smoke",light=0,size={{0,40},{.5,70},{1,60}},alpha={{0,1},{.2,.25},{.8,.3},{1,1}},
  color={{0,Color3.fromRGB(46,40,52)},{1,Color3.fromRGB(26,24,34)}},life={6,9},speed={0,2},spread=180,spin={-6,6}},18)
 clouds.Shape=Enum.ParticleEmitterShape.Box
 local under=E.Stream(roof,{tex="glow.soft",size={{0,60},{1,80}},alpha={{0,1},{.4,.8},{1,1}},color=AMBER,life={2,3},spread=180},5)
 under.Shape=Enum.ParticleEmitterShape.Box
 local rainBox=part(g,Vector3.new(120,1,120),WHITE,1)
 local rain=E.Stream(rainBox,{tex="wind.dash",size=.7,alpha={{0,.6},{1,.75}},color=Color3.fromRGB(200,205,220),light=0,life={.5,.6},speed={120,140},
  dir=Enum.NormalId.Bottom,orient="velocity"},260)
 rain.Shape=Enum.ParticleEmitterShape.Box
 local cc=Instance.new("ColorCorrectionEffect") cc.Parent=Lighting
 E.Tween(cc,math.max(d.Rise or 1.2,1),{Brightness=-.18,Contrast=.2,Saturation=-.35,TintColor=Color3.fromRGB(215,210,235)})
 local nextFlash=1
 E.Step(g,function(_,t)
  local cam=workspace.CurrentCamera
  if cam then local p=cam.CFrame.Position rainBox.CFrame=CFrame.new(p.X,p.Y+45,p.Z)end
  if t>=nextFlash and t<T-1 then
   nextFlash=t+.8+math.random()*1.6
   local fl=Instance.new("ColorCorrectionEffect") fl.Brightness=.12+math.random()*.12 fl.TintColor=Color3.fromRGB(255,240,200) fl.Parent=Lighting
   E.Tween(fl,.25,{Brightness=0,TintColor=WHITE})
   task.delay(.3,function()fl:Destroy()end)
   local a=math.random()*math.pi*2
   local p=c+UP*108+Vector3.new(math.cos(a),0,math.sin(a))*math.random()*200
   bolt(E,g,p,p+Vector3.new((math.random()-.5)*80,-math.random()*10,(math.random()-.5)*80),{Depth=4,Width=.6,Life=.2,Branches=2,Jitter=12})
  end
  if t>=T then
   clouds.Enabled=false under.Enabled=false rain.Enabled=false
   E.Tween(cc,1.5,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE})
   return false
  end
  return true
 end)
 task.delay(T+10,function()cc:Destroy()end)
 E.After(g,T+9,function()g:Destroy()end)
end
 -- one strike: its circle on the floor (dark, a bright ring closing), then the bolt - a jagged core with two
 -- branches and a second flicker - the flash, the sparks and a scorch
function P.Bolt(E,d)
 local g=E.Group("P5Bolt")
 local T,R=d.Tell or .55,d.Radius or 7
 local c=d.Pos
 local mark=disc(g,c,R,DUSK,1)
 local edge=ring(g,R*1.6,.45,SHINE,1,32)
 edge.Carrier.CFrame=CFrame.new(c+UP*.14)
 local a=E.Anchor(g,CFrame.new(c+UP*.5))
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  mark.Transparency=1-.5*smooth(k*2.5)
  edge.set(R*(1.6-.6*k),1-.85*smooth(k*2.5))
  if k<1 then return true end
  mark.Transparency=1 edge.set(R,1)
  local top=Vector3.new(c.X+(math.random()-.5)*20,d.Sky or c.Y+120,c.Z+(math.random()-.5)*20)
  local jit=(top-c).Magnitude*.12
  bolt(E,g,top,c,{Depth=4,Width=.42,Life=.22,Branches=2,Jitter=jit})
  E.After(g,.06,function()bolt(E,g,top,c,{Depth=4,Width=.28,Life=.14,Jitter=jit*.8})end)
  E.Sprite(a,{tex="flare.burst",size={{0,R*1.5},{1,R*3.5}},alpha={{0,0},{1,1}},color=SHINE},.18)
  E.Emit(a,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.25,.45},speed={25,50},spread=70,dir=Enum.NormalId.Top,
   accel=Vector3.new(0,-60,0)},14)
  E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,6}},alpha={{0,.5},{1,1}},color=Color3.fromRGB(70,60,60),life={.6,1},speed={8,16},spread=80,
   dir=Enum.NormalId.Top,drag=3},6)
  E.Light(g,a,BRIGHT,R*5,10,.3)
   -- (no dirt ring or scorch circle left on the ground any more)
  return false
 end)
 E.After(g,T+2.4,function()g:Destroy()end)
end

 -- he flashes round to a fresh angle: a burst where he left, one where he lands, lightning between
function P.ThrustBlink(E,d)
 local g=E.Group("P5ThrustBlink")
 for _,p in ipairs({d.From,d.To})do
  local a=E.Anchor(g,CFrame.new(p))
  E.Sprite(a,{tex="flare.burst",size={{0,3},{1,9}},alpha={{0,0},{1,1}},color=SHINE},.15)
  E.Emit(a,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.15,.3},speed={15,30},spread=180},10)
  E.Light(g,a,BRIGHT,14,5,.2)
 end
 bolt(E,g,d.From,d.To,{Depth=4,Width=.25,Life=.12,Jitter=(d.To-d.From).Magnitude*.12})
 E.After(g,.6,function()g:Destroy()end)
end
 -- the thrust's lane: dark on the floor, a white thread racing down it, sparks crackling along it
function P.ThrustTell(E,d)
 local g=E.Group("P5ThrustTell")
 local T,W=d.Time or .3,d.Width or 5
 local from,to=d.From,d.To
 local len=math.max((to-from).Magnitude,1)
 local y=groundAt(E,from,g,d.Boss).Y+.08
 local f=CFrame.lookAt(Vector3.new(from.X,y,from.Z),Vector3.new(to.X,y,to.Z))
 local strip=part(g,Vector3.new(W*2,.05,len),DUSK,1,nil,Enum.Material.SmoothPlastic)
 strip.CFrame=f*CFrame.new(0,0,-len/2)
 local line=part(g,Vector3.new(.3,.06,1),SHINE,.1)
 local nextArc=0
 E.Step(g,function(_,t)
  local k=math.clamp(t/(T*.5),0,1)
  local l=math.max(len*k,.1)
  line.Size=Vector3.new(.3,.06,l) line.CFrame=f*CFrame.new(0,.02,-l/2)
  strip.Transparency=1-.5*smooth(t/T*2)
  if t>=nextArc then
   nextArc=t+.05
   local p=(f*CFrame.new(0,.3,-len*math.random()*k)).Position
   bolt(E,g,p,p+f.LookVector*(2+math.random()*3)+Vector3.new(0,math.random()*1.5,0),{Depth=2,Width=.1,Life=.06,Jitter=.8})
  end
  if t>=T then strip.Transparency=1 line.Transparency=1 return false end
  return true
 end)
 E.After(g,T+.3,function()g:Destroy()end)
end
 -- the thrust: a gold afterimage where he started, a white-hot streak to where he stops, lightning down the lane,
 -- a burst at the far end and a scorched line left on the floor (the last thrust bigger)
function P.ThrustDash(E,d)
 local boss=d.Boss
 local g=E.Group("P5ThrustDash")
 local T=d.Time or .08
 local from,to=d.From,d.To
 local big=d.Final
 if rootOf(boss)and not d.Quick then echo(E,g,boss,GOLD,.45,.35)end  -- the hundred quick ones skip it
 local A=E.Anchor(g,CFrame.lookAt(from,to)) local B=E.Anchor(g,CFrame.lookAt(from,to))
 local core=E.Beam(g,E.Attach(A),E.Attach(B),{color=SHINE,width=big and 2.4 or 1.4,alpha={{0,.6},{.8,.05},{1,0}},segments=2})
 local glow=E.Beam(g,E.Attach(A),E.Attach(B),{tex="beam.streaks",color=BRIGHT,width=big and 7 or 4.5,alpha={{0,.85},{.8,.3},{1,.1}},scroll=6,segments=2})
 local s=E.Anchor(g,CFrame.new(from))
 E.Sprite(s,{tex="flare.burst",size={{0,3},{1,8}},alpha={{0,0},{1,1}},color=SHINE},.14)
 E.Emit(s,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.15,.3},speed={15,30},spread=180},8)
 local arrived=false
 E.Step(g,function(_,t)
  local k=math.min(t/T,1)
  B.CFrame=CFrame.new(from:Lerp(to,k))
  if k<1 or arrived then return not arrived end
  arrived=true
  local L=(to-from).Magnitude
  bolt(E,g,from,to,{Depth=4,Width=big and .4 or .28,Life=.18,Branches=big and 3 or 1,Jitter=L*.08})
  if not d.Quick then bolt(E,g,from,to,{Depth=4,Width=.18,Life=.12,Jitter=L*.1})end
  local e=E.Anchor(g,CFrame.lookAt(to,to+(to-from)))
  E.Sprite(e,{tex="flare.burst",size={{0,big and 6 or 3},{1,big and 16 or 9}},alpha={{0,0},{1,1}},color=SHINE},.18)
  E.Emit(e,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.2,.35},speed={20,40},spread=60,dir=Enum.NormalId.Front},big and 20 or 10)
  E.Light(g,e,BRIGHT,big and 26 or 16,6,.25)
  E.Tween(core,.2,{Width0=0,Width1=0}) E.Tween(glow,.25,{Width0=0,Width1=0})
  if d.Quick then return false end
  local y=groundAt(E,from,g,boss).Y+.07
  local sc=part(g,Vector3.new(big and 1.6 or 1,.05,L),UMBER,.35,nil,Enum.Material.SmoothPlastic)
  sc.CFrame=CFrame.lookAt(Vector3.new(from.X,y,from.Z),Vector3.new(to.X,y,to.Z))*CFrame.new(0,0,-L/2)
  local sl=part(g,Vector3.new(.25,.06,L),BRIGHT,.1)
  sl.CFrame=sc.CFrame*CFrame.new(0,.01,0)
  E.Tween(sc,.9,{Transparency=1},nil,nil,.3) E.Tween(sl,.5,{Transparency=1},nil,nil,.1)
  return false
 end)
 E.After(g,1.4,function()g:Destroy()end)
end
 -- the inward Cataclysm: the blocks burst up out of the floor far round the arena and hang there, ready to fly in
function P.RockErupt(E,d)
 local boss=d.Boss
 local g=E.Group("P5RockErupt")
 local T=d.Time or .7
 local st=state(boss)
 if st.Rocks then st.Rocks.G:Destroy()end
 local list={}
 for i,seat in ipairs(d.Seats)do
  local size=d.Sizes and d.Sizes[i] or 6
  local floor=d.Floors and d.Floors[i] or seat-UP*8
  local rk=rock(g,size)
  rk.Seat=seat rk.Floor=floor rk.Spin=CFrame.Angles(math.random()*6,math.random()*6,math.random()*6) rk.Rot=(math.random()-.5)*2
  list[i]=rk
  local a=E.Anchor(g,CFrame.new(floor+UP*.4))
  E.Emit(a,{tex="smoke",light=0,size={{0,size*.6},{1,size*1.6}},alpha={{0,.45},{1,1}},color=Color3.fromRGB(150,120,80),life={.6,1},speed={size*1.5,size*3},
   spread=80,dir=Enum.NormalId.Top,drag=4},8)
  E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.25,.45},speed={15,30},spread=70,dir=Enum.NormalId.Top,
   accel=Vector3.new(0,-50,0)},8)
  cracks(E,g,floor,size*1.4,5,BRIGHT,T+1.5)
  debris(E,g,floor,4,.6)
 end
 st.Rocks={G=g,List=list}
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  local e=1-(1-math.clamp(t/T,0,1))^3
  for _,rk in ipairs(list)do
   if not rk.Thrown then
    local pos=(rk.Floor-UP*3):Lerp(rk.Seat,e)+UP*math.sin(t*3+rk.Rot*3)*.4
    placeRock(rk,CFrame.new(pos)*rk.Spin*CFrame.Angles(0,t*rk.Rot,0),parts,cfs)
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<T+8
 end)
 E.After(g,T+8.5,function()g:Destroy() if st.Rocks and st.Rocks.G==g then st.Rocks=nil end end)
end
 -- The Great Storm's end: HE becomes the star. He goes gold, the star swells round him and swallows him (his model
 -- hidden on this client), then it falls with him - a streak down the sky - onto the marked middle of the arena
function P.StarForm(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5StarForm")
 local B,T,R=d.Become or .9,d.Time or 1.3,d.Radius or 30
 local h=Instance.new("Highlight")
 h.FillColor=BRIGHT h.OutlineColor=SHINE h.FillTransparency=1 h.OutlineTransparency=1 h.DepthMode=Enum.HighlightDepthMode.Occluded
 h.Adornee=boss h.Parent=g.Folder
 local core=part(g,Vector3.one,SHINE,0,BALL)
 local shell=part(g,Vector3.one,GOLD,.25,BALL,FF)
 local a=E.Anchor(g,r.CFrame)
 E.Sprite(a,{tex="star.anime",size={{0,2},{.4,26},{1,30}},alpha={{0,.4},{.4,.05},{1,.1}},color=BRIGHT,spin={90,90}},B+T)
 E.Sprite(a,{tex="star.lens",size={{0,4},{.4,44},{1,50}},alpha={{0,.6},{.4,.2},{1,.3}},color=SHINE,spin={-40,-40}},B+T)
 E.Sprite(a,{tex="star.glare",size={{0,6},{.4,70},{1,80}},alpha={{0,.7},{.4,.35},{1,.4}},color=GOLD,spin={20,20}},B+T)
 local sk,m=suck(E,g,r.Position,22,GOLD,140,.35)
 local trail=E.Stream(a,{tex="star.crisp",size={{0,1.6},{1,0}},color={{0,WHITE},{1,AMBER}},life={.3,.6},speed={4,12},spread=180,drag=2},1)
 trail.Enabled=false
 local light=E.Light(g,a,BRIGHT,40,2)
 local mark=disc(g,d.Pos,R,DUSK,1)
 local edge=ring(g,R*1.5,1,SHINE,1,64)
 edge.Carrier.CFrame=CFrame.new(d.Pos+UP*.14)
 local hidden={}
 local function hide(on)
  for _,p in ipairs(boss:GetDescendants())do
   if p:IsA("BasePart")or p:IsA("Decal")then
    if on then hidden[p]=true p.LocalTransparencyModifier=1 elseif hidden[p]then p.LocalTransparencyModifier=0 end
   end
  end
 end
 local tail,top
 E.Step(g,function(_,t)
  local root=rootOf(boss)
  if not root then return false end
  local p=root.Position
  local k=math.clamp(t/B,0,1)
  h.FillTransparency=1-k h.OutlineTransparency=1-k
  local s=2+10*smooth(k)
  core.Size=Vector3.one*s*.6 shell.Size=Vector3.one*s
  workspace:BulkMoveTo({core,shell,a,sk},{CFrame.new(p),CFrame.new(p)*CFrame.Angles(t*2,t*3,0),CFrame.new(p),CFrame.new(p)},Enum.BulkMoveMode.FireCFrameChanged)
  light.Brightness=2+8*k light.Range=40+40*k
  if t>=B and not top then
   hide(true) m.Enabled=false trail.Enabled=true
   top=E.Anchor(g,CFrame.new(p))
   tail=E.Beam(g,E.Attach(top),E.Attach(a),{tex="beam.streaks",color={{0,AMBER},{1,SHINE}},width0=2,width1=12,alpha={{0,1},{.6,.4},{1,.1}},scroll=8,segments=2})
  end
  if t>=B then
   local u=math.clamp((t-B)/T,0,1)
   mark.Transparency=1-.55*smooth(u*1.5)
   edge.set(R*(1.5-.5*u),1-.85*smooth(u*1.5))
  end
  if t>=B+T then
   hide(false)
   core.Transparency=1 shell.Transparency=1 trail.Enabled=false light.Brightness=0
   if tail then tail.Enabled=false end
   mark.Transparency=1 edge.set(R,1)
   h.FillTransparency=1 h.OutlineTransparency=1
   return false
  end
  return true
 end)
 E.After(g,B+T+.6,function()hide(false) g:Destroy()end)
end
 -- Enhanced Glided Thread: the threads gather - a gold glint opens at each point round him, one after another, and
 -- swells until its thread launches. d: Points, Time (until the first launch), Stagger
function P.ThreadRing(E,d)
 local g=E.Group("P5ThreadRing")
 local T=d.Time or .8
 local stag=d.Stagger or .1
 local pts=d.Points or{}
  -- the circle itself: a gold band round him, swelling out to the ring's radius while the orbs open one after another
  -- round it; each orb pops (its thread launches) in the same order, one stagger apart
 local band
 if d.Center and d.Radius then
  band=ring(g,d.Radius,.4,GOLD,.5,64)
  band.Carrier.CFrame=CFrame.new(d.Center)
 end
 local orbs={}
 for i,p in ipairs(pts)do
  local a=E.Anchor(g,CFrame.new(p))
  local o={A=a,Pos=p,On=(i-1)*.06,Off=T+(i-1)*stag,Shell=part(g,Vector3.one*.1,GOLD,1,BALL,FF),Core=part(g,Vector3.one*.1,WHITE,1,BALL)}
  o.Shell.CFrame=CFrame.new(p) o.Core.CFrame=CFrame.new(p)
  orbs[i]=o
  E.After(g,o.On,function()
   E.Sprite(a,{tex="star.glare",size={{0,0},{.5,9},{1,12}},alpha={{0,.4},{.5,.1},{1,1}},color=BRIGHT,spin={90,90}},math.max(o.Off-o.On,.25))
   E.Sprite(a,{tex="ring.crisp",size={{0,16},{1,2}},alpha={{0,1},{1,0}},color=GOLD},.3)
   E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,GOLD}},life={.3,.6},speed={4,12},spread=180,drag=2},8)
   E.Light(g,a,GOLD,12,3,math.max(o.Off-o.On,.25))
  end)
 end
 E.Step(g,function(_,t)
  if band then
   local k=smooth(t/math.max(T*.6,.2))
   band.set(d.Radius*k,1-.5*k)
  end
  for _,o in ipairs(orbs)do
   if t>=o.On and not o.Done then
    local k=smooth((t-o.On)/.25)
    local s=2.8*k*(1+.06*math.sin(t*12))
    o.Shell.Size=Vector3.one*s o.Core.Size=Vector3.one*s*.5
    o.Shell.Transparency=.3 o.Core.Transparency=0
    if t>=o.Off then
     o.Done=true o.Shell.Transparency=1 o.Core.Transparency=1
     E.Emit(o.A,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.2,.4},speed={10,24},spread=180},8)
    end
   end
  end
  return t<T+#orbs*stag+.3
 end)
 E.After(g,T+#orbs*stag+1,function()g:Destroy()end)
end
 -- Star Shooter: stars round him. Each is a 5-pointed star (a pentagram of five glowing beams, a core and a bead on every
 -- point) lying flat, turning on its own axis while it circles him; the server fires out of the very same points
 -- (d: Stars, Points, Radius, Height, Reach, Orbit, Spin, Orbit0, Spin0, Born, Time, Tell)
function P.StarRing(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5StarRing")
 local n,pts=d.Stars or 4,d.Points or 5
 local reach=d.Reach or 3.4
 local K=reach/3.4  -- everything drawn scales with the star's size
 local stars={}
 for k=1,n do
  local anchor=E.Anchor(g,CFrame.new(r.Position))
  local atts={}
  for j=1,pts do
   local ang=(j-1)/pts*math.pi*2
   local at=Instance.new("Attachment") at.Position=Vector3.new(math.cos(ang),0,math.sin(ang))*reach at.Parent=anchor
   atts[j]=at
  end
  for j=1,pts do  -- point j to point j+2: the pentagram
   local b=Instance.new("Beam")
   b.Attachment0=atts[j] b.Attachment1=atts[(j+1)%pts+1] b.FaceCamera=true b.Segments=1 b.LightEmission=1 b.LightInfluence=0
   b.Width0=.45*K b.Width1=.45*K b.Color=ColorSequence.new(SHINE,BRIGHT) b.Transparency=NumberSequence.new(.05) b.Parent=anchor
  end
  local core=part(g,Vector3.one*1.8*K,SHINE,0,BALL)
  local beads={}
  for j=1,pts do beads[j]=part(g,Vector3.one*.9*K,BRIGHT,0,BALL) end
  E.Stream(anchor,{tex="glow.soft",size=6*K,alpha={{0,.55},{1,1}},color=BRIGHT,life={.15,.2},locked=true},20)
  E.Light(g,anchor,BRIGHT,18*K,2)
  stars[k]={A=anchor,Core=core,Beads=beads}
 end
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  local s=workspace:GetServerTimeNow()-(d.Born or workspace:GetServerTimeNow())
  local grow=smooth(s/math.max((d.Tell or .9),.2))
  local parts,cfs={},{}
  for k,st in ipairs(stars)do
   local oa=(d.Orbit0 or 0)+(d.Orbit or .9)*s+(k-1)/n*math.pi*2
   local center=root.Position+Vector3.new(math.cos(oa),0,math.sin(oa))*(d.Radius or 11)*grow+UP*(d.Height or 3.5)
   local spin=(d.Spin0 or 0)+(d.Spin or -1.5)*s+(k-1)*.7
   parts[#parts+1]=st.A cfs[#cfs+1]=CFrame.new(center)*CFrame.Angles(0,-spin,0)
   local sz=1.8*K*grow+math.sin(t*5+k)*.1*K
   st.Core.Size=Vector3.one*math.max(sz,.1)
   parts[#parts+1]=st.Core cfs[#cfs+1]=CFrame.new(center)
   for j,bead in ipairs(st.Beads)do
    local pa=spin+(j-1)/pts*math.pi*2
    parts[#parts+1]=bead cfs[#cfs+1]=CFrame.new(center+Vector3.new(math.cos(pa),0,math.sin(pa))*reach)
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return s<(d.Time or 22)
 end)
 E.After(g,(d.Time or 22)+.8,function()g:Destroy()end)
end
 -- the small stars of one volley: d.List {Origin, Dir}, flying straight at Speed for Range (the server hurts along the same lines)
function P.StarShots(E,d)
 local g=E.Group("P5StarShots")
 local speed,range=d.Speed or 62,d.Range or 150
 local shots={}
 for i,sh in ipairs(d.List or{})do
  shots[i]={O=sh.Origin,D=sh.Dir,L=sh.Len or range,Core=part(g,Vector3.one*.9,WHITE,0,BALL),Shell=part(g,Vector3.one*1.8,BRIGHT,.35,BALL)}
 end
 local longest=0
 for _,s in ipairs(shots)do longest=math.max(longest,s.L) end
 E.Step(g,function(_,t)
  local dist=speed*t
  local parts,cfs={},{}
  for _,s in ipairs(shots)do
   if not s.Gone then
    if dist>=s.L then
     s.Gone=true
     s.Core:Destroy() s.Shell:Destroy()
    else
     local p=s.O+s.D*dist
     parts[#parts+1]=s.Core cfs[#cfs+1]=CFrame.new(p)
     parts[#parts+1]=s.Shell cfs[#cfs+1]=CFrame.new(p)*CFrame.Angles(t*6,t*4,0)
    end
   end
  end
  if #parts>0 then workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged) end
  return dist<longest
 end)
 E.After(g,longest/speed+.3,function()g:Destroy()end)
end
 -- Golden Bullets: the red sigil turning at his raised hand while he fires
function P.GoldenSigil(E,d)
 local boss=d.Boss local r=rootOf(boss) if not r then return end
 local g=E.Group("P5GoldenSigil")
 local T=d.Time or 2
 local big,imgs=plate(g,6,E.Lib.Id("sigil.ring2"),RED,4)
 local small,imgs2=plate(g,3.4,E.Lib.Id("sigil.lace"),Color3.fromRGB(255,120,90),5)
 local a=E.Anchor(g,r.CFrame)
 local light=E.Light(g,a,RED,12,3)
 local motes=E.Stream(a,{tex="star.tiny",size={{0,.6},{1,0}},color={{0,Color3.fromRGB(255,200,180)},{1,RED}},life={.3,.5},speed={2,5},spread=180},20)
 E.Step(g,function(_,t)
  local root=rootOf(boss) if not root then return false end
  local f=root.CFrame*CFrame.new(-1.5,1,-3.2)
  local k=smooth(t/.25)
  big.Size=Vector3.new(6*k+.1,6*k+.1,.05)
  workspace:BulkMoveTo({big,small,a},{f*CFrame.Angles(0,0,t*2),f*CFrame.new(0,0,-.2)*CFrame.Angles(0,0,-t*3.5),f},Enum.BulkMoveMode.FireCFrameChanged)
  for _,i in ipairs(imgs)do i.ImageTransparency=1-.95*k end
  for _,i in ipairs(imgs2)do i.ImageTransparency=1-.9*k end
  if t>=T then
   for _,i in ipairs(imgs)do i.ImageTransparency=1 end
   for _,i in ipairs(imgs2)do i.ImageTransparency=1 end
   light.Brightness=0 motes.Enabled=false
   return false
  end
  return true
 end)
 E.After(g,T+.4,function()g:Destroy()end)
end
 -- one medium golden orb: a white core in a gold shell, a glow and a short trail, a flash at his hand as it goes
function P.GoldenShot(E,d)
 local g=E.Group("P5GoldenShot")
 local o,dir,speed,R,S=d.Origin,d.Dir,d.Speed or 130,d.Range or 260,d.Size or 3.2
 local core=part(g,Vector3.one*S*.55,SHINE,0,BALL)
 local shell=part(g,Vector3.one*S,BRIGHT,.3,BALL)
 local a=E.Anchor(g,CFrame.new(o))
 E.Stream(a,{tex="glow.soft",size=S*2.4,alpha={{0,.55},{1,1}},color=GOLD,life={.1,.14},locked=true},20)
 local tr=Instance.new("Trail") tr.Attachment0=E.Attach(a,CFrame.new(0,S*.35,0)) tr.Attachment1=E.Attach(a,CFrame.new(0,-S*.35,0))
 tr.Lifetime=.12 tr.LightEmission=1 tr.LightInfluence=0 tr.FaceCamera=true tr.Color=ColorSequence.new(SHINE,AMBER) tr.Transparency=ns(0,.3,1,1) tr.Parent=a
 local muzzle=E.Anchor(g,CFrame.lookAt(o,o+dir))
 E.Sprite(muzzle,{tex="flare.burst",size={{0,S},{1,S*3}},alpha={{0,0},{1,1}},color=SHINE},.1)
 E.Emit(muzzle,{tex="star.crisp",size={{0,.6},{1,0}},color={{0,WHITE},{1,GOLD}},life={.1,.2},speed={10,20},spread=30,dir=Enum.NormalId.Front},5)
 E.Step(g,function(_,t)
  local dist=math.min(speed*t,R)
  local p=o+dir*dist
  workspace:BulkMoveTo({core,shell,a},{CFrame.new(p),CFrame.new(p),CFrame.new(p)},Enum.BulkMoveMode.FireCFrameChanged)
  if dist>=R then
   core.Transparency=1 shell.Transparency=1 tr.Enabled=false
   E.Emit(a,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,BRIGHT}},life={.15,.3},speed={10,20},spread=180},6)
   return false
  end
  return true
 end)
 E.After(g,R/speed+.6,function()g:Destroy()end)
end
return P
