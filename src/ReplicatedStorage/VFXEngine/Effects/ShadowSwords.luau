--[[
 ShadowSwords (client effect) - P3.5 Mysterious Guy. When the shadow's punch lands, a giant
 obsidian sword tears up out of the ground under the impact (hilt and all) and two staggered
 rings of blades burst up around it, tilted outward, each with a crack of gold light at its
 base. A shadow that caught no one erupts the same way without the giant sword.
   Net.Send("ShadowSwords","Erupt",{Pos=ground point, Radius=studs, Giant=bool, Seed=int})
 The server deals the damage; this only draws.
]]
local SW={}
local OBSIDIAN=Color3.fromRGB(30,18,52)
local VOID=Color3.fromRGB(12,7,22)
local VIOLET=Color3.fromRGB(150,84,255)
local GOLD=Color3.fromRGB(255,206,84)
local SHINE=Color3.fromRGB(255,240,190)
local METAL,NEON=Enum.Material.Metal,Enum.Material.Neon
local UP=Vector3.yAxis
local HIDDEN=CFrame.new(0,-1e4,0)

local function newPart(g,class,size,color,material,alpha,shape)
 local p=Instance.new(class)
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Size=size p.Color=color p.Material=material p.Transparency=alpha or 0
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end
 if material==METAL then p.Reflectance=.12 end
 p.CFrame=HIDDEN
 p.Parent=g.Folder
 return p
end

 -- one sword standing on +Y with the blade's base at the origin; the giant one gets a hilt below it
local function build(g,L,W,T,hilt)
 local parts,offsets,alphas={},{},{}
 local function add(class,size,cf,color,material,alpha,shape)
  parts[#parts+1]=newPart(g,class,size,color,material,alpha,shape)
  offsets[#offsets+1]=cf
  alphas[#alphas+1]=alpha or 0
 end
 local H=W*1.5
 add("Part",Vector3.new(W,L,T),CFrame.new(0,L/2,0),OBSIDIAN,METAL)
 add("Part",Vector3.new(W*.16,L*.82,T+.06),CFrame.new(0,L*.46,0),VIOLET,NEON,.1)
 for _,s in ipairs({-1,1})do
  add("Part",Vector3.new(math.max(.1,W*.1),L,T+.04),CFrame.new(s*(W/2-W*.05),L/2,0),GOLD,NEON)
  add("WedgePart",Vector3.new(T,H,W/2),CFrame.new(s*W/4,L+H/2,0)*CFrame.Angles(0,-s*math.pi/2,0),OBSIDIAN,METAL)
  add("Part",Vector3.new(math.max(.1,W*.1),math.sqrt(W*W/4+H*H),T+.04),CFrame.new(s*W/4,L+H/2,0)*CFrame.Angles(0,0,s*math.atan2(W/2,H)),GOLD,NEON)
 end
 local depth=0
 if hilt then
  add("Part",Vector3.new(W*2.8,W*.32,T*2.4),CFrame.new(0,-W*.16,0),GOLD,METAL)
  add("Part",Vector3.new(W*.5,W*.5,T*2.6),CFrame.new(0,-W*.16,0)*CFrame.Angles(0,0,math.pi/4),SHINE,NEON)
  for _,s in ipairs({-1,1})do
   add("Part",Vector3.new(W*.55,W*.5,T*2.2),CFrame.new(s*W*1.55,-W*.05,0)*CFrame.Angles(0,0,s*.5),GOLD,METAL)
  end
  add("Part",Vector3.new(W*.38,W*1.9,W*.38),CFrame.new(0,-W*1.27,0),VOID,Enum.Material.Fabric)
  add("Part",Vector3.new(W*.66,W*.66,W*.66),CFrame.new(0,-W*2.5,0),GOLD,METAL,0,Enum.PartType.Ball)
  depth=W*2.85
 end
 return {Parts=parts,Offsets=offsets,Alphas=alphas,Length=L+H,Depth=depth,Width=W}
end

local function backOut(t)
 local c1=1.4 local c3=c1+1
 return 1+c3*(t-1)^3+c1*(t-1)^2
end

local function groundAt(E,pos,fallback)
 local hit=E.Ground(pos+UP*8)
 if hit and math.abs(hit.Y-fallback)<10 then return hit end
 return Vector3.new(pos.X,fallback,pos.Z)
end

 -- the crack of light, dust and sparks where a blade breaks the surface
local function breach(E,g,pos,w)
 local a=E.Anchor(g,CFrame.new(pos+UP*.2))
 E.Sprite(a,{tex="burst.spiky",orient="flat",size={{0,w},{.15,w*5},{1,w*6}},alpha={{0,0},{.5,.35},{1,1}},color=GOLD},.55)
 E.Emit(a,{tex="star.crisp",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.3,.65},speed={14,30},
  spread=45,dir=Enum.NormalId.Top,accel=Vector3.new(0,-50,0),drag=1},9)
 E.Emit(a,{tex="smoke",light=0,size={{0,w*1.2},{1,w*3.4}},alpha={{0,.45},{1,1}},color={{0,OBSIDIAN},{1,VOID}},
  life={.5,.9},speed={4,11},spread=70,dir=Enum.NormalId.Top,drag=2.5},5)
end

function SW.Erupt(E,d)
 local g=E.Group("ShadowSwords")
 local rng=Random.new(d.Seed or 1)
 local R=d.Radius or 20
 local center=d.Pos
 local swords={}

 local function plant(sword,base,yaw,tilt,show,delay,rise,hold,sink)
  sword.Base=CFrame.new(base)*CFrame.Angles(0,yaw,0)*CFrame.Angles(tilt,0,0)
  sword.Ground=base
  sword.Show,sword.Delay,sword.Rise,sword.Hold,sword.Sink=show,delay,rise,hold,sink
  swords[#swords+1]=sword
 end

  -- rings of blades, tilted away from the centre
 local rings={
  {Count=7,R=.42,L={6,8.5},W=1.1,T=.28,Tilt={.18,.32},Delay=.05},
  {Count=11,R=.82,L={8,12},W=1.4,T=.32,Tilt={.28,.48},Delay=.15},
 }
 for _,ring in ipairs(rings)do
  local spin=rng:NextNumber(0,math.pi*2)
  for i=1,ring.Count do
   local a=spin+(i-1)*math.pi*2/ring.Count+rng:NextNumber(-.12,.12)
   local out=Vector3.new(math.cos(a),0,math.sin(a))
   local pos=groundAt(E,center+out*(R*ring.R*rng:NextNumber(.9,1.08)),center.Y)
   local L=rng:NextNumber(ring.L[1],ring.L[2])
   local sword=build(g,L,ring.W,ring.T,false)
    -- face outward: yaw so the blade's tilt (about its X axis) leans along `out`
   local yaw=math.atan2(-out.X,-out.Z)
   plant(sword,pos,yaw,-rng:NextNumber(ring.Tilt[1],ring.Tilt[2]),sword.Length*.82,
    ring.Delay+rng:NextNumber(0,.05),.13,.42+rng:NextNumber(0,.12),.32)
  end
 end
 if d.Giant then
  local sword=build(g,15,2.6,.6,true)
  plant(sword,center,rng:NextNumber(0,math.pi*2),0,sword.Length+sword.Depth+1.2,0,.17,.6,.38)
  sword.Giant=true
 end

  -- the centre: a flash, smoke and sparks (no ground circles)
 local ga=E.Anchor(g,CFrame.new(center+UP*.25))
 local fa=E.Anchor(g,CFrame.new(center+UP*3))
 E.Sprite(fa,{tex="flare.big",size={{0,6},{.15,R*1.8},{1,R*2.1}},alpha={{0,0},{.4,.3},{1,1}},color=SHINE},.4)
 E.Sprite(fa,{tex="burst.spiky2",size={{0,4},{1,R*1.6}},alpha={{0,0},{.5,.2},{1,1}},color=VIOLET,rot={0,360}},.45)
 E.Emit(ga,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.35},{1,1}},color={{0,OBSIDIAN},{1,VOID}},
  life={.8,1.4},speed={R*.8,R*1.6},spread=88,dir=Enum.NormalId.Top,drag=2.2},14)
 E.Emit(fa,{tex="star.anime",size={{0,1.6},{1,0}},color={{0,SHINE},{1,VIOLET}},life={.5,.9},speed={30,70},
  spread=180,accel=Vector3.new(0,-40,0),drag=1.2,spin={-300,300}},22)
 E.Light(g,fa,VIOLET,R*2.4,10,.8)
 E.Light(g,ga,GOLD,R*1.4,6,.5)

 local breached={}
 local finished=0
 for _,s in ipairs(swords)do finished=math.max(finished,s.Delay+s.Rise+s.Hold+s.Sink)end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for index,s in ipairs(swords)do
   local u=t-s.Delay
   local y,fade=-(s.Length+1),0
   if u>=0 then
    if not breached[index]then
     breached[index]=true
     breach(E,g,s.Ground,s.Giant and 3 or s.Width)
    end
    local hidden=-s.Length
    if u<s.Rise then
     y=hidden+s.Show*backOut(u/s.Rise)
    elseif u<s.Rise+s.Hold then
     y=hidden+s.Show+math.sin(u*40)*.04
    else
     local k=math.clamp((u-s.Rise-s.Hold)/s.Sink,0,1)
     y=hidden+s.Show*(1-k*k)
     fade=k
    end
   end
   local frame=s.Base*CFrame.new(0,y,0)
   for i,p in ipairs(s.Parts)do
    parts[#parts+1]=p
    cfs[#cfs+1]=frame*s.Offsets[i]
    if fade>0 then p.Transparency=s.Alphas[i]+(1-s.Alphas[i])*fade end
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=finished then g:Destroy()return false end
  return true
 end)
 E.After(g,finished+1,function()g:Destroy()end)
end

return SW
