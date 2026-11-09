-- The burnt world (Encounter/ArenaRuin, after the first Wild Hunt's Death Scythe). While workspace ArenaRuinedAt is
-- set, every castle wall, tree, spire and ruin outside the arena barriers is destroyed - a wave rolling outward from
-- golden fires burning across it and all around the arena's edge. The arena itself is untouched. When the attribute
-- clears (the encounter ended) everything is put back exactly as it was. All of it is local: every client builds the
-- same ruin from the same attribute, so nothing has to replicate.
local Tween=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local Fires=require(game:GetService("ReplicatedStorage"):WaitForChild("BossShared"):WaitForChild("Config"):WaitForChild("ArenaRuinFires"))
local arena=workspace:WaitForChild("GoldenGrasslandArena",30)
local GROUPS={"SurroundingWalls","Scenery","RuinedApproach","ChronicleCourt"}
local CHAR=Color3.fromRGB(40,32,26)
local EMBER=Color3.fromRGB(255,150,40)

 -- the arena rectangle: inside the knockback barriers
local function bounds()
 local bx,bz=318,238
 local barriers=arena and arena:FindFirstChild("CastleKnockbackBarriers")
 if barriers then
  local xs,zs={},{}
  for _,b in ipairs(barriers:GetChildren())do
   if b:IsA("BasePart")then
    if b.Size.X<b.Size.Z then xs[#xs+1]=math.abs(b.Position.X)-b.Size.X/2 else zs[#zs+1]=math.abs(b.Position.Z)-b.Size.Z/2 end
   end
  end
  if #xs>0 then bx=math.min(table.unpack(xs))end
  if #zs>0 then bz=math.min(table.unpack(zs))end
 end
 return bx,bz
end

local saved,tweens,fx,tint={}, {},nil,nil

 -- Stylized golden flame, layered the way anime fire is: a soft gold glow behind, a flipbook flame body tinted
 -- amber-gold, toon flame tongues licking up through it, a white-gold toon core at the heart, and embers drifting
 -- off the tips. The flipbooks play once over each particle's life so every tongue rises, flickers and dies.
 -- Few, big fires: each one is a patch of tongues as wide as the fire, not a crowd of small ones.
local FLAME_BODY="rbxassetid://17703378809"  -- "Recolorable Big Fire Flipbook" 4x4, greyscale
local FLAME_TOON="rbxassetid://93253997872542"  -- stylized toon flame tongues 4x4, gold to orange
local FLAME_GLOW="rbxassetid://15267968986"
local function nseq(...)
 local k,v={...},{}
 for i=1,#k,2 do v[#v+1]=NumberSequenceKeypoint.new(k[i],k[i+1]) end
 return NumberSequence.new(v)
end
local function nenv(...)  -- time, value, envelope triples: each particle picks its own size within the envelope
 local k,v={...},{}
 for i=1,#k,3 do v[#v+1]=NumberSequenceKeypoint.new(k[i],k[i+1],k[i+2]) end
 return NumberSequence.new(v)
end
local function cseq(...)
 local k,v={...},{}
 for i=1,#k,2 do v[#v+1]=ColorSequenceKeypoint.new(k[i],k[i+1]) end
 return ColorSequence.new(v)
end
local function emitter(a,props)
 local p=Instance.new("ParticleEmitter")
 p.LightInfluence=0 p.Orientation=Enum.ParticleOrientation.FacingCamera
 for k,v in pairs(props) do p[k]=v end
 p.Parent=a
 return p
end
local function fire(at,size)
 local a=Instance.new("Part")
 a.Anchored=true a.CanCollide=false a.CanQuery=false a.CanTouch=false a.Transparency=1
  -- the flames rise from anywhere on a patch as wide as the fire; flipbook frames stand on their bottom edge, so
  -- the emitter sits a little above the ground to put each tongue's base on it
 a.Size=Vector3.new(size*.9,.5,size*.9)
 a.CFrame=CFrame.new(at+Vector3.new(0,size*.32,0)) a.Parent=fx
 local up=Vector3.new(0,1,0)
 local function patch(props)
  props.Shape=Enum.ParticleEmitterShape.Box props.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
  return emitter(a,props)
 end
 emitter(a,{Name="Glow",Texture=FLAME_GLOW,Color=ColorSequence.new(Color3.fromRGB(255,184,54)),LightEmission=1,
  Size=nseq(0,size*1.4,1,size*1.7),Transparency=nseq(0,1,.3,.8,1,1),Lifetime=NumberRange.new(1,1.4),
  Speed=NumberRange.new(0),Rate=2,ZOffset=-2})
 patch({Name="Body",Texture=FLAME_BODY,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,
  FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=cseq(0,Color3.fromRGB(255,214,90),.4,Color3.fromRGB(255,160,30),1,Color3.fromRGB(200,70,10)),
  LightEmission=.25,Brightness=1.2,Size=nseq(0,size*.85,.4,size*1.05,1,size*.7),Squash=nseq(0,.3,1,.4),
  Transparency=nseq(0,.45,.2,.25,.7,.4,1,1),Lifetime=NumberRange.new(.8,1.1),Speed=NumberRange.new(size*.08,size*.15),
  SpreadAngle=Vector2.new(6,6),Rotation=NumberRange.new(-8,8),Rate=3,ZOffset=-.5})
 patch({Name="Tongues",Texture=FLAME_TOON,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,
  FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=cseq(0,Color3.fromRGB(255,240,190),1,Color3.fromRGB(255,200,120)),
  LightEmission=.15,Brightness=1.1,Size=nenv(0,size*.32,size*.1,.35,size*.64,size*.16,1,size*.24,size*.06),
  Squash=nseq(0,.55,1,.8),Transparency=nseq(0,.2,.2,0,.8,.15,1,1),Lifetime=NumberRange.new(.55,.85),
  Speed=NumberRange.new(size*.35,size*.6),SpreadAngle=Vector2.new(12,12),Rotation=NumberRange.new(-6,6),Rate=6,
  Acceleration=up*size*.4})
 patch({Name="Core",Texture=FLAME_TOON,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,
  FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=cseq(0,Color3.fromRGB(255,255,240),1,Color3.fromRGB(255,236,150)),
  LightEmission=.8,Brightness=1.6,Size=nenv(0,size*.22,size*.05,.4,size*.4,size*.08,1,size*.12,size*.02),
  Squash=nseq(0,.6,1,.8),Transparency=nseq(0,.1,.6,.05,1,1),Lifetime=NumberRange.new(.45,.7),
  Speed=NumberRange.new(size*.15,size*.3),SpreadAngle=Vector2.new(5,5),Rotation=NumberRange.new(-4,4),Rate=4,ZOffset=.6})
 patch({Name="Embers",Texture="rbxasset://textures/particles/sparkles_main.dds",
  Color=cseq(0,Color3.fromRGB(255,250,210),1,Color3.fromRGB(255,170,40)),LightEmission=1,Brightness=2,
  Size=nseq(0,.5,1,0),Transparency=nseq(0,0,.8,.2,1,1),Lifetime=NumberRange.new(1.4,2.8),
  Speed=NumberRange.new(size*.45,size*.85),SpreadAngle=Vector2.new(28,28),Acceleration=up*2,Drag=.8,
  Rate=size*.3,ZOffset=.8})
 emitter(a,{Name="Smoke",Texture="rbxasset://textures/particles/smoke_main.dds",
  Color=ColorSequence.new(Color3.fromRGB(60,46,34),Color3.fromRGB(30,26,24)),LightEmission=0,LightInfluence=1,
  Size=nseq(0,size*.5,1,size*1.6),Transparency=nseq(0,1,.25,.62,1,1),Lifetime=NumberRange.new(2,3.2),
  Speed=NumberRange.new(size*.7,size*1),SpreadAngle=Vector2.new(12,12),Rate=1.2,ZOffset=-3})
 local light=Instance.new("PointLight")
 light.Color=Color3.fromRGB(255,190,70) light.Range=size*1.6 light.Brightness=1.8 light.Shadows=false light.Parent=a
 return a
end

local function rubble(at,rng)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=true
 p.Material=Enum.Material.Basalt p.Color=CHAR:Lerp(Color3.fromRGB(80,60,40),rng:NextNumber(0,.5))
 p.Size=Vector3.new(rng:NextNumber(2,7),rng:NextNumber(1,3.5),rng:NextNumber(2,7))
 p.CFrame=CFrame.new(at+Vector3.new(0,p.Size.Y*.3,0))*CFrame.Angles(rng:NextNumber(-.4,.4),rng:NextNumber(0,6.3),rng:NextNumber(-.4,.4))
 p.Parent=fx
 return p
end

local function ruin(instant)
 if fx or not arena then return end
 fx=Instance.new("Folder") fx.Name="ArenaRuinFX" fx.Parent=workspace
 local bx,bz=bounds()
 local rng=Random.new(7)
  -- what goes: every castle wall (the arena's own border wall too); scenery beyond the arena; and the
  -- buttresses, columns and banners standing near its edge - never the floor's inlays or anything nearer the middle
 local floor=arena:FindFirstChild("Grassland")
 local fx0,fz0=floor and floor.Size.X/2 or 310,floor and floor.Size.Z/2 or 230
 local function doomed(name,p)
  if p.Transparency>=1 then return false end
  local x,z=math.abs(p.Position.X),math.abs(p.Position.Z)
  if name=="SurroundingWalls"then return true end
  if x>fx0 or z>fz0 then return true end
  return(x>fx0-22 or z>fz0-22)and p.Position.Y+p.Size.Y/2>0.7
 end
 local list,groups={},{}
 for _,name in ipairs(GROUPS)do
  local m=arena:FindFirstChild(name)
  if m then
   groups[#groups+1]=m
   for _,p in ipairs(m:GetDescendants())do
    if p:IsA("BasePart")and doomed(name,p)and not p:FindFirstAncestor("PolyStar")then
     list[#list+1]=p
    end
   end
  end
 end
  -- the bare ground the walls stood on, found before they go (they're left out of the ray)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local skip={fx}
 for _,m in ipairs(groups)do skip[#skip+1]=m end
 for _,pl in ipairs(game:GetService("Players"):GetPlayers())do if pl.Character then skip[#skip+1]=pl.Character end end
 params.FilterDescendantsInstances=skip
 local function groundUnder(pos)
  local hit=workspace:Raycast(Vector3.new(pos.X,pos.Y+80,pos.Z),Vector3.new(0,-400,0),params)
  return hit and hit.Position or Vector3.new(pos.X,0,pos.Z)
 end
 for _,p in ipairs(list)do
  saved[p]={CFrame=p.CFrame,Color=p.Color,Material=p.Material,Transparency=p.Transparency,CanCollide=p.CanCollide,CanQuery=p.CanQuery}
  local beyond=math.max(math.abs(p.Position.X)-bx,math.abs(p.Position.Z)-bz,0)
  local delay=instant and 0 or math.clamp(beyond/80,0,2.6)+rng:NextNumber(0,.3)
  local fall=CFrame.Angles(rng:NextNumber(-.6,.6),rng:NextNumber(-.3,.3),rng:NextNumber(-.6,.6))
  local goal={Transparency=1,Color=CHAR,CFrame=(p.CFrame-Vector3.new(0,math.max(p.Size.Y,4),0))*fall}
  local function go()
   if not saved[p]then return end
   p.CanCollide=false p.CanQuery=false
   if instant then
    p.Transparency=1
    return
   end
   p.Color=EMBER
   p.Material=Enum.Material.Basalt
   local t=Tween:Create(p,TweenInfo.new(rng:NextNumber(.8,1.3),Enum.EasingStyle.Quad,Enum.EasingDirection.In),goal)
   tweens[#tweens+1]=t
   t:Play()
  end
  if delay>0 then task.delay(delay,go)else go()end
 end
  -- what's left: charred rubble and golden fires where the big pieces stood, and a ring of fire around the arena
 local big={}
 for _,p in ipairs(list)do if p.Size.Magnitude>8 then big[#big+1]=p end end
 local spots={}
 for i=1,math.min(#big,70)do
  local p=big[rng:NextInteger(1,#big)]
  spots[#spots+1]={At=groundUnder(p.Position),Delay=math.clamp(math.max(math.abs(p.Position.X)-bx,math.abs(p.Position.Z)-bz,0)/80,0,2.6)}
 end
 for i,spot in ipairs(spots)do
  task.delay(instant and 0 or spot.Delay+.6,function()
   if not(fx and fx.Parent)then return end
   for _=1,rng:NextInteger(1,3)do rubble(spot.At+Vector3.new(rng:NextNumber(-6,6),0,rng:NextNumber(-6,6)),rng)end
   if i<=18 then fire(spot.At+Vector3.new(0,1,0),rng:NextNumber(28,36))end  -- tall: they stand in the sand far below the arena floor
  end)
 end
  -- the ring of gold: big fires along the arena's rim, where the border wall stood. Fires lays them out, and the
  -- server burns anyone touching one (Encounter/ArenaRuin), so they light exactly where and when it says
 for _,f in ipairs(Fires.Rim(floor))do
  task.delay(instant and 0 or f.LitAt,function()
   if fx and fx.Parent then fire(f.Position+Vector3.new(0,.5,0),f.Size)end
  end)
 end
 tint=Instance.new("ColorCorrectionEffect")
 tint.Name="ArenaRuinTint" tint.TintColor=Color3.new(1,1,1) tint.Parent=Lighting
 Tween:Create(tint,TweenInfo.new(instant and 0 or 3),{TintColor=Color3.fromRGB(255,236,214),Brightness=-.06,Contrast=.2,Saturation=.05}):Play()
end

local function restore()
 for _,t in ipairs(tweens)do t:Cancel()end
 table.clear(tweens)
 for p,s in pairs(saved)do
  if p.Parent then
   p.CFrame=s.CFrame p.Color=s.Color p.Material=s.Material p.Transparency=s.Transparency
   p.CanCollide=s.CanCollide p.CanQuery=s.CanQuery
  end
 end
 table.clear(saved)
 if fx then fx:Destroy() fx=nil end
 if tint then tint:Destroy() tint=nil end
end

local function sync(first)
 local at=workspace:GetAttribute("ArenaRuinedAt")
 if at then
  ruin(first or workspace:GetServerTimeNow()-at>4)
 else
  restore()
 end
end
workspace:GetAttributeChangedSignal("ArenaRuinedAt"):Connect(function()sync(false)end)
sync(true)
