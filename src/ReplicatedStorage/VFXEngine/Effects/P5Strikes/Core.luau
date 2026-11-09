-- P5Strikes core: the colours, materials and drawing helpers that more than one cue group needs.
-- Every cue (P.<Name>) lives in a sibling module and takes what it uses from the table returned here.
local P={}
local Players=game:GetService("Players")
local ASSETS=script.Parent.Parent.Parent:WaitForChild("Assets")
local WHITE=Color3.new(1,1,1)
local GOLD=Color3.fromRGB(255,208,111)
local SHINE=Color3.fromRGB(255,246,214)
local VIOLET=Color3.fromRGB(174,114,255)
local PINK=Color3.fromRGB(255,106,199)
local BLUE=Color3.fromRGB(98,195,255)
local MINT=Color3.fromRGB(115,255,205)
local VOID=Color3.fromRGB(14,6,24)
local CRIMSON=Color3.fromRGB(255,40,86)
local AMBER=Color3.fromRGB(255,146,36)  -- reads against the gold field where plain gold would not
local NEON=Enum.Material.Neon
local UP=Vector3.yAxis
local HIDDEN=CFrame.new(0,-1e4,0)
local MODE_COLORS={Space={VIOLET,BLUE},Natural={MINT,BLUE},Time={GOLD,SHINE}}

local function newPart(g,size,color,alpha)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Size=size p.Color=color p.Material=NEON p.Transparency=alpha or 0
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.CFrame=HIDDEN p.Parent=g.Folder
 return p
end

 -- a clone of a mesh template, `width` studs along its X axis (proportions kept); untextured clones glow
local function mesh(g,name,width,color,alpha,keepTexture)
 local template=ASSETS[name]
 local p=template:Clone()
 p.Size=template.Size*(width/template.Size.X)
 p.Color=color p.Transparency=alpha or 0
 if not keepTexture then p.TextureID="" p.Material=NEON end
 p.CFrame=HIDDEN p.Parent=g.Folder
 return p
end

 -- a layered slash in its local XY plane (bulging toward +Y): a bright core, a wider glow just behind
 -- it and, optionally, a swirl of streaks
local function slash(g,width,core,glow,o)
 o=o or{}
 local layers={
  {Part=mesh(g,"ArcSlash",width,core,o.CoreAlpha or .05),Offset=CFrame.new()},
  {Part=mesh(g,"ArcSlash",width*1.14,glow,o.GlowAlpha or .45),Offset=CFrame.new(0,-width*.02,.2)},
 }
 if o.Streak then
  layers[#layers+1]={Part=mesh(g,"StreakSlash",width*(o.StreakScale or 1.25),o.StreakColor or glow,o.StreakAlpha or .35),
   Offset=CFrame.new(0,0,.4)*CFrame.Angles(math.pi/2,0,0)}
 end
 for _,l in ipairs(layers)do l.Base=l.Part.Size l.Alpha=l.Part.Transparency end
 return layers
end

 -- place a layered slash at `frame`; `scale` resizes it and `fade` (0..1) rewrites transparency when given
local function place(layers,frame,scale,fade,parts,cfs)
 for _,l in ipairs(layers)do
  if scale then l.Part.Size=l.Base*scale end
  if fade then l.Part.Transparency=l.Alpha+(1-l.Alpha)*fade end
  parts[#parts+1]=l.Part
  cfs[#cfs+1]=frame*l.Offset
 end
end

local function rootOf(model)return model and model:FindFirstChild("HumanoidRootPart")end
local function bladeOf(boss)
 local sword=boss and boss:FindFirstChild("Basic Sword")
 local blade=sword and(sword:FindFirstChild("Blade")or sword:FindFirstChild("Handle"))
 if blade and blade:IsA("BasePart")then return blade end
 return boss and(boss:FindFirstChild("Right Arm")or boss:FindFirstChild("RightHand"))or rootOf(boss)
end
local function flatLook(cf)
 local look=cf.LookVector*Vector3.new(1,0,1)
 return look.Magnitude>.1 and look.Unit or Vector3.zAxis
end

 -- butterflies: the white butterfly sprite, tinted, its width squashed back and forth so it flaps
local FLAP={{0,0},{.08,.75},{.16,0},{.24,.75},{.32,0},{.4,.75},{.48,0},{.56,.75},{.64,0},{.72,.75},{.8,0},{.88,.75},{1,0}}
local BUTTERFLY_GOLD=Color3.fromRGB(255,214,60)
local function butterflies(size,speed,life)
 return {tex="butterfly",size={{0,size},{.8,size},{1,0}},squash=FLAP,color={{0,SHINE},{.5,BUTTERFLY_GOLD},{1,AMBER}},light=.6,
  alpha={{0,0},{.75,0},{1,1}},life=life or{.9,1.5},speed=speed or{3,8},spread=180,drag=1.2,rot={0,360},spin={-60,60},
  accel=Vector3.new(0,2,0)}
end

local function handOf(boss,side)
 return boss and(boss:FindFirstChild(side.."Hand")or boss:FindFirstChild(side.." Arm"))
end
local function handCF(hand)return hand.CFrame*CFrame.new(0,-hand.Size.Y*.45,0)end

 -- glowing cracks running out from `c` along the floor
local function cracks(E,g,c,R,n,color,life)
 local floor=E.Ground(c+UP*3,{g.Folder})
 local at=(floor or c)+UP*.08
 for i=1,n do
  local a=(i-1)*math.pi*2/n+math.random()*.5
  local len=R*(.55+math.random()*.7)
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local cf=CFrame.lookAt(at+dir*len/2,at+dir*len)
  local p=newPart(g,Vector3.new(.3+math.random()*.35,.06,len),color,.05)
  local q=newPart(g,Vector3.new(1.6,.05,len),GOLD,.6)
  p.CFrame=cf q.CFrame=cf
  E.Tween(p,life*.5,{Transparency=1},nil,nil,life*.5)
  E.Tween(q,life*.4,{Transparency=1},nil,nil,life*.3)
 end
end

 -- chunks of rock flung up out of an impact, falling back on arcs
local function debris(E,g,c,n)
 local rocks={}
 for i=1,n do
  local p=newPart(g,Vector3.one*(.6+math.random()*1.4),Color3.fromRGB(150,112,48),0)
  p.Material=Enum.Material.Slate
  local a=math.random()*math.pi*2
  local out=8+math.random()*16
  rocks[i]={P=p,V=Vector3.new(math.cos(a)*out,26+math.random()*24,math.sin(a)*out),R=CFrame.Angles(math.random()*6,math.random()*6,0)}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,r in ipairs(rocks)do
   parts[#parts+1]=r.P cfs[#cfs+1]=CFrame.new(c+r.V*t+Vector3.new(0,-35*t*t,0))*r.R*CFrame.Angles(t*5,t*3,0)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>1.2 then for _,r in ipairs(rocks)do r.P.Transparency=1 end return false end
  return true
 end)
end

 -- two crescent jaws in the vertical plane of `frame`, snapping shut on its middle
local function jaws(E,g,frame,width,glowColor,gap)
 local upper=slash(g,width,WHITE,glowColor,{GlowAlpha=.3,Streak=true,StreakColor=AMBER,StreakAlpha=.6})
 local lower=slash(g,width,WHITE,glowColor,{GlowAlpha=.3})
 local snapped=false
 E.Step(g,function(_,t)
  local k=math.clamp(t/.11,0,1)
  local shut=k*k
  local fade=t<.18 and 0 or math.clamp((t-.22)/.2,0,1)
  local parts,cfs={},{}
  place(upper,frame*CFrame.new(0,gap*(1-shut)+.6,0),1,fade,parts,cfs)
  place(lower,frame*CFrame.new(0,-gap*(1-shut)-.6,0)*CFrame.Angles(0,0,math.pi),1,fade,parts,cfs)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if not snapped and k>=1 then
   snapped=true
   local a=E.Anchor(g,frame)
   E.Sprite(a,{tex="flare.burst",size={{0,3},{1,width}},alpha={{0,0},{1,1}},color=SHINE},.22)
   E.Sprite(a,{tex="ring.crisp",orient="flat",dir=Enum.NormalId.Front,size={{0,2},{1,width*1.4}},alpha={{0,.1},{1,1}},color=glowColor},.3)
   E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.25,.5},speed={24,55},spread=180,drag=2.5},30)
   E.Light(g,a,glowColor,width*1.6,8,.35)
  end
  return t<.5
 end)
end

 -- an arc of camera-facing beams around `center` (in its local XZ plane, radius R): a crimson glow, a black
 -- blade and a hot leading edge; Sweep(fraction, fade) redraws it as it opens
local function goldArc(E,g,center,R,startAngle,span,thick)
 thick=thick or 1
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=center
 local N=E.Quality<.6 and 16 or 26
 local points,layers={},{}
 for i=0,N do local at=Instance.new("Attachment")at.Parent=carrier points[i+1]=at end
 local function ribbon(w,color,alpha,emission,head)
  local beams={}
  for i=1,N do
   local beam=Instance.new("Beam")
   beam.Attachment0=points[i] beam.Attachment1=points[i+1]
   beam.FaceCamera=true beam.Segments=2 beam.LightEmission=emission beam.LightInfluence=0
   beam.Color=ColorSequence.new(color) beam.Transparency=NumberSequence.new(alpha)
   beam.Parent=carrier
   beams[i]=beam
  end
  layers[#layers+1]={Beams=beams,W=w,Head=head}
 end
 ribbon(R*.3*thick,AMBER,.45,1,false)
 ribbon(R*.13*thick,BUTTERFLY_GOLD,.05,.6,false)
 ribbon(R*.04*thick,WHITE,0,1,true)
 return function(frac,fade)
  for i,at in ipairs(points)do
   local a=startAngle+span*frac*(i-1)/N
   at.Position=Vector3.new(math.cos(a)*R,0,math.sin(a)*R)
  end
  for _,l in ipairs(layers)do
   for i,beam in ipairs(l.Beams)do
    local t0,t1=(i-1)/N,i/N
    local k0,k1=t0^1.4,t1^1.4
    if l.Head then k0,k1=t0^3,t1^3 end
    beam.Width0=math.max(.04,l.W*k0*(1-fade)) beam.Width1=math.max(.04,l.W*k1*(1-fade))
   end
  end
 end
end

local function arcSlash(E,g,center,R,startAngle,span,fake)
 local carrier=newPart(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=center
 local N=E.Quality<.6 and 14 or 22
 local points,layers={},{}
 for i=0,N do
  local at=Instance.new("Attachment")at.Parent=carrier points[i+1]=at
 end
 local function ribbon(w,color,alpha,emission,head)
  local beams={}
  for i=1,N do
   local beam=Instance.new("Beam")
   beam.Attachment0=points[i] beam.Attachment1=points[i+1]
   beam.FaceCamera=true beam.Segments=2 beam.LightEmission=emission beam.LightInfluence=0
   beam.Color=ColorSequence.new(color) beam.Transparency=NumberSequence.new(alpha)
   beam.Parent=carrier
   beams[i]=beam
  end
  layers[#layers+1]={Beams=beams,W=w,Head=head}
 end
 ribbon(R*.24,fake and VIOLET or CRIMSON,fake and .65 or .45,1,false)
 ribbon(R*.09,fake and PINK or VOID,fake and .55 or 0,fake and 1 or 0,false)
 ribbon(R*.025,fake and WHITE or Color3.fromRGB(255,190,200),fake and .4 or 0,1,true)
 local function sweep(frac,fade)
  for i,at in ipairs(points)do
   local a=startAngle+span*frac*(i-1)/N
   at.Position=Vector3.new(math.cos(a)*R,0,math.sin(a)*R)
  end
  for _,l in ipairs(layers)do
   for i,beam in ipairs(l.Beams)do
     -- thickest at the leading end, thinning to nothing at the tail
    local t0,t1=(i-1)/N,i/N
    local k0,k1=t0^1.6,t1^1.6
    if l.Head then k0,k1=t0^4,t1^4 end
    beam.Width0=math.max(.04,l.W*k0*(1-fade)) beam.Width1=math.max(.04,l.W*k1*(1-fade))
   end
  end
 end
 sweep(.01,0)
 return sweep
end

 -- shared by the Time / Natural / Space mode skills ------------------------------------------------------------
 -- a sphere swelling from d0 to d1 studs across over t, fading out: a blast's real volume
local function dome(E,g,pos,color,d0,d1,t,alpha,material)
 local p=newPart(g,Vector3.one*d0,color,alpha or .2)
 p.Shape=Enum.PartType.Ball
 if material then p.Material=material end
 p.CFrame=CFrame.new(pos)
 E.Tween(p,t,{Size=Vector3.one*d1,Transparency=1})
 return p
end
 -- the whole screen graded for a moment (a ColorCorrectionEffect), eased back to nothing over t
local function grade(E,props,t)
 local cc=Instance.new("ColorCorrectionEffect")
 for k,v in pairs(props)do cc[k]=v end
 cc.Parent=game:GetService("Lighting")
 E.Tween(cc,t,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE})
 task.delay(t+.1,function()cc:Destroy()end)
end
 -- n slivers of light flung out of `c` on arcs, spinning, gone by `life`
local function shards(E,g,c,n,speed,size,colors,life)
 local list={}
 for i=1,n do
  local a=math.random()*math.pi*2
  local p=newPart(g,Vector3.new(size*.22,size*.22,size)*(.6+math.random()*.8),colors[(i-1)%#colors+1],0)
  list[i]={P=p,V=Vector3.new(math.cos(a),.5+math.random()*.9,math.sin(a))*speed*(.6+math.random()*.6),
   R=CFrame.Angles(math.random()*6,math.random()*6,0),S=(math.random()-.5)*20}
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

return {
 AMBER=AMBER,
 BLUE=BLUE,
 BUTTERFLY_GOLD=BUTTERFLY_GOLD,
 CRIMSON=CRIMSON,
 GOLD=GOLD,
 HIDDEN=HIDDEN,
 MINT=MINT,
 MODE_COLORS=MODE_COLORS,
 NEON=NEON,
 P=P,
 PINK=PINK,
 Players=Players,
 SHINE=SHINE,
 UP=UP,
 VIOLET=VIOLET,
 VOID=VOID,
 WHITE=WHITE,
 arcSlash=arcSlash,
 bladeOf=bladeOf,
 butterflies=butterflies,
 cracks=cracks,
 debris=debris,
 dome=dome,
 flatLook=flatLook,
 goldArc=goldArc,
 grade=grade,
 handCF=handCF,
 handOf=handOf,
 jaws=jaws,
 newPart=newPart,
 place=place,
 rootOf=rootOf,
 shards=shards,
 slash=slash,
}
