--[[
 GroundShatter (client effect) - alterGolden's shield-gate skill P1GroundShatter. A gold warning
 circle marks every player's feet and fills in over the warning; then a crown of crystal gold
 spikes bursts out of each circle, holds, and shatters back into the ground.
   Net.Send("GroundShatter","Warn",{Points={Vector3,...}, Radius=studs, Time=seconds})
   Net.Send("GroundShatter","Erupt",{Points={Vector3,...}, Radius=studs, Seed=int, Tall=x, Count=n, Hold=s})
 Tall scales the spikes' height, Count sets how many ring each point and Hold how long they stand (the P5
 Slam, Horrifying Ground and Wild Hunt use them; P5StrikeCore.Spikes).
 The server deals the damage; this only draws.
]]
local GS={}
local GOLD=Color3.fromRGB(255,192,48)
local DEEP=Color3.fromRGB(214,138,24)
local SHINE=Color3.fromRGB(255,244,196)
local WARN=Color3.fromRGB(255,96,40)  -- orange-red: reads against the gold field
local METAL,NEON=Enum.Material.Metal,Enum.Material.Neon
local UP=Vector3.yAxis
local HIDDEN=CFrame.new(0,-1e4,0)

local function newPart(g,class,size,color,material,alpha)
 local p=Instance.new(class)
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Size=size p.Color=color p.Material=material p.Transparency=alpha or 0
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 if material==METAL then p.Reflectance=.2 end
 p.CFrame=HIDDEN
 p.Parent=g.Folder
 return p
end

 -- a crystal spike standing on +Y with its base at the origin: two crossed fins, each a short
 -- body and a long triangular point, with a bright seam up the middle
local function spike(g,W,L,H)
 local parts,offsets,alphas={},{},{}
 local function add(class,size,cf,color,material,alpha)
  parts[#parts+1]=newPart(g,class,size,color,material,alpha)
  offsets[#offsets+1]=cf
  alphas[#alphas+1]=alpha or 0
 end
 local T=W*.22
 for _,yaw in ipairs({0,math.pi/2})do
  local turn=CFrame.Angles(0,yaw,0)
  add("Part",Vector3.new(W,L,T),turn*CFrame.new(0,L/2,0),DEEP,METAL)
  for _,s in ipairs({-1,1})do
   add("WedgePart",Vector3.new(T,H,W/2),turn*CFrame.new(s*W/4,L+H/2,0)*CFrame.Angles(0,-s*math.pi/2,0),GOLD,METAL)
  end
  add("Part",Vector3.new(W*.12,L+H*.78,T+.06),turn*CFrame.new(0,(L+H*.78)/2,0),SHINE,NEON,.15)
 end
 return {Parts=parts,Offsets=offsets,Alphas=alphas,Height=L+H,Width=W}
end

local function backOut(t)
 local c1=1.6 local c3=c1+1
 return 1+c3*(t-1)^3+c1*(t-1)^2
end

local function groundAt(E,pos,fallback)
 local hit=E.Ground(pos+UP*8)
 if hit and math.abs(hit.Y-fallback)<8 then return hit end
 return Vector3.new(pos.X,fallback,pos.Z)
end

function GS.Warn(E,d)
 local g=E.Group("GroundShatterWarn")
 local R,T=d.Radius or 8,d.Time or .6
 for _,p in ipairs(d.Points or{})do
  local a=E.Anchor(g,CFrame.new(p+UP*.15))
   -- the edge snaps in; the fill grows to it as the spikes come
  E.Sprite(a,{tex="ring.crisp",orient="flat",size={{0,R*2.5},{.2,R*2},{1,R*2}},alpha={{0,1},{.2,.05},{.85,0},{1,.5}},color=WARN},T+.05)
  E.Sprite(a,{tex="disc.soft",orient="flat",size={{0,.5},{1,R*2}},alpha={{0,.8},{1,.3}},color=WARN},T)
  E.Sprite(a,{tex="star.crisp",size={{0,1},{.8,3},{1,5}},alpha={{0,.4},{.8,0},{1,1}},color=SHINE},T)
 end
 E.After(g,T+.4,function()g:Destroy()end)
end

function GS.Erupt(E,d)
 local g=E.Group("GroundShatter")
 local rng=Random.new(d.Seed or 1)
 local R=d.Radius or 8
 local low=(E.Quality or 1)<.6
 local tall=d.Tall or 1
 local spikes={}
 local function plant(pos,W,L,H,yaw,tilt,delay)
  local s=spike(g,W,L,H)
  s.Base=CFrame.new(pos)*CFrame.Angles(0,yaw,0)*CFrame.Angles(tilt,0,0)
  s.Ground=pos s.Delay=delay
  s.Rise=.12 s.Hold=(d.Hold or .42)+rng:NextNumber(0,.1) s.Sink=.28
  spikes[#spikes+1]=s
 end
 for _,center in ipairs(d.Points or{})do
  local k=math.max(R/8,1)  -- spikes grow with the circle
   -- Style (P5 Horrifying Ground gives every circle its own): crown (a heart and a ring around it), needle (one
   -- very tall heart and a few stubs), ring (no heart, spikes on the edge leaning out), scatter (spikes anywhere in
   -- the circle, leaning every way), fan (a heart and a half ring all leaning one way), twin (two hearts)
  local style=d.Style or"crown"
  local spin=rng:NextNumber(0,math.pi*2)
  if style=="crown"or style=="fan"then
   plant(center,3.4*k,2*k,10*k*tall,rng:NextNumber(0,math.pi),0,0)
  elseif style=="needle"then
   plant(center,2.4*k,2*k,16*k*tall,rng:NextNumber(0,math.pi),0,0)
  elseif style=="twin"then
   for _,sgn in ipairs({-1,1})do
    local off=Vector3.new(math.cos(spin),0,math.sin(spin))*R*.3*sgn
    plant(groundAt(E,center+off,center.Y),2.8*k,2*k,rng:NextNumber(8,11)*k*tall,math.atan2(-off.X,-off.Z),-.18,0)
   end
  end
  local n=d.Count and math.floor(d.Count*(low and .6 or 1)+.5) or math.floor((low and 4 or 7)*k+.5)
  if style=="needle"then n=math.max(2,math.floor(n*.5))end
  for i=1,n do
   local a
   if style=="fan"then a=spin+(i-1)/math.max(n-1,1)*math.pi-math.pi/2
   else a=spin+(i-1)*math.pi*2/n+rng:NextNumber(-.2,.2)end
   local out=Vector3.new(math.cos(a),0,math.sin(a))
   local dist=style=="ring"and rng:NextNumber(.8,.95)or style=="scatter"and rng:NextNumber(.1,.85)
    or style=="needle"and rng:NextNumber(.25,.45)or rng:NextNumber(.45,.82)
   local pos=groundAt(E,center+out*R*dist,center.Y)
   local tilt=style=="ring"and -rng:NextNumber(.5,.75)or style=="scatter"and rng:NextNumber(-.5,.5)
    or style=="fan"and -.55 or -rng:NextNumber(.25,.45)
   local scale=style=="needle"and .6 or style=="scatter"and rng:NextNumber(.6,1.3)or 1
   local yaw=style=="fan"and spin+math.pi or math.atan2(-out.X,-out.Z)
   plant(pos,rng:NextNumber(1.8,2.5)*k^.5*scale,rng:NextNumber(1,1.6)*k^.5*scale,rng:NextNumber(5,7.5)*k^.6*tall*scale,
    yaw,tilt,.03+rng:NextNumber(0,.06))
  end
   -- where the ground breaks: a spiky gold flare, a flash and sparks (no dirt: the field is gold)
  local a=E.Anchor(g,CFrame.new(center+UP*.2))
  local f=E.Anchor(g,CFrame.new(center+UP*2.5))
  E.Sprite(a,{tex="burst.spiky",orient="flat",size={{0,R*.6},{.15,R*2.2},{1,R*2.5}},alpha={{0,0},{.5,.4},{1,1}},color=GOLD},.5)
  E.Sprite(f,{tex="flare.big",size={{0,4},{.15,R*1.6},{1,R*1.8}},alpha={{0,0},{.4,.35},{1,1}},color=SHINE},.35)
  E.Emit(f,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,SHINE},{1,GOLD}},life={.4,.8},speed={20,42},
   spread=55,dir=Enum.NormalId.Top,accel=Vector3.new(0,-60,0),drag=1},20)
  E.Light(g,f,GOLD,R*2.2,6,.5)
 end

 local shattered={}
 local finished=0
 for _,s in ipairs(spikes)do finished=math.max(finished,s.Delay+s.Rise+s.Hold+s.Sink)end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for index,s in ipairs(spikes)do
   local u=t-s.Delay
   local y,fade=-(s.Height+.5),0
   if u>=0 then
    if u<s.Rise then
     y=-s.Height*(1-backOut(u/s.Rise))
    elseif u<s.Rise+s.Hold then
     y=math.sin(u*45)*.03
    else
     local k=math.clamp((u-s.Rise-s.Hold)/s.Sink,0,1)
     y=-s.Height*.6*k*k
     fade=k
     if not shattered[index]then
      shattered[index]=true  -- it breaks apart as it sinks
      local at=E.Anchor(g,CFrame.new(s.Ground+UP*s.Height*.45))
      E.Emit(at,{tex="star.tiny",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.35,.7},speed={8,18},
       spread=180,accel=Vector3.new(0,-40,0),drag=1.5},6)
     end
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

return GS
