local Effects=require(script:FindFirstAncestor("BossSystem").Combat.EffectService)
local Audio=require(script:FindFirstAncestor("BossSystem").Presentation.CombatAudio)
local Crimson=require(script:FindFirstAncestor("BossSystem").Attacks.Shared.P4GoldenFX)
local FX=Crimson.FX
local Visuals={}

 
function Visuals.ChargeFlourish(core,cast,style,windup)
 local ctx=Crimson.Context(core)
 local sword=core.Root.Parent:FindFirstChild("Basic Sword")
 local blade=sword and sword:FindFirstChild("Blade")
 local function tip() return blade and blade.Position or core.Root.Position+Vector3.new(0,5,0) end
 for i=1,3 do
  cast:Schedule((i-1)*windup/4,function()
   if cast:Alive() then FX.Ring(ctx,cast,CFrame.new(tip())*CFrame.Angles(math.pi/2,0,i),9,1.2,windup*.5,i==2 and style.White or style.Gold,0,.35,14) end
  end)
 end
 local spark=FX.Anchor(ctx,cast,tip(),windup+.3)
 FX.Emitter(spark,{Color=FX.Grad(style.White,style.Gold),Size=FX.Seq(.15,.45),Transparency=FX.Seq(1,.1,0),
  Lifetime=NumberRange.new(.3),Speed=NumberRange.new(-16),Shape=Enum.ParticleEmitterShape.Sphere,
  ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,Rate=60})
 spark.Size=Vector3.one*10
 cast:Step(function() if not spark.Parent then return false end spark.CFrame=CFrame.new(tip()) return true end)
 cast:Schedule(math.max(0,windup-.12),function()
  if cast:Alive() then FX.Glint(ctx,cast,tip(),style.Gold,6,.3) end
 end)
end

 
 
function Visuals.Cleave(core,lane,groundY,cast,style,scale)
 scale=scale or 1
 local ctx=Crimson.Context(core)
 local dir=lane.frame.LookVector
 dir=Vector3.new(dir.X,0,dir.Z).Unit
 local start=Vector3.new(lane.frame.Position.X,groundY,lane.frame.Position.Z)
 local finish=start+dir*lane.length
 local origin=Vector3.new(core.Root.Position.X,groundY,core.Root.Position.Z)
  
 local arcFrame=CFrame.lookAt(origin+Vector3.new(0,6,0),origin+Vector3.new(0,6,0)+dir)*CFrame.Angles(0,0,math.pi/2)*CFrame.new(0,0,4)
 FX.Crescent(ctx,cast,arcFrame,14*scale,math.rad(170),3.4*scale,style.Gold,style.White,.32,{Wipe=.05,Grow=1.3,Segments=18})
 FX.Beam(ctx,cast,start+Vector3.new(0,.6,0),finish+Vector3.new(0,.6,0),lane.width*.55,style.Gold,style.White,.45)
 FX.Beam(ctx,cast,start+Vector3.new(0,.6,0),finish+Vector3.new(0,.6,0),1.2,style.White,style.White,.8)
 FX.Streaks(ctx,cast,origin+Vector3.new(0,3,0),dir,style.Gold,style.White,30,12,90,170,4)
 local steps=math.clamp(math.floor(lane.length/16),4,14)
 for i=1,steps do
  local t=i/steps
  local at=start:Lerp(finish,t)
  cast:Schedule(t*.25,function()
   if not cast:Alive() then return end
   FX.Spikes(ctx,cast,at,4,lane.width*.22,7*scale,style.Gold,style.White,.7,15)
   FX.Sparks(ctx,cast,at+Vector3.new(0,.5,0),style.Gold,style.White,8,10,26,.45)
   if i%3==0 then FX.Smoke(ctx,cast,at,Color3.fromRGB(170,150,120),5,3,12,2) end
  end)
 end
 FX.Impact(ctx,cast,origin+Vector3.new(0,1,0),style.Gold,style.White,1.4*scale,{Ground=CFrame.new(origin+Vector3.new(0,.1,0)),Shake=.8,Tint=.7})
end

local function fade(cast,part,seconds,properties)
 Effects:Create(part,TweenInfo.new(seconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties):Play()
 cast:Schedule(seconds+.05,function()
  if cast.objects[part] then Effects.Release(part);cast.objects[part]=nil end
 end)
end
function Visuals.Charge(core,lane,groundY,cast,style)
 local center=Vector3.new(core.Root.Position.X,groundY+.2,core.Root.Position.Z)
 local ctx=Crimson.Context(core)
 for i=1,2 do
  FX.Ring(ctx,cast,CFrame.new(center)*CFrame.Angles(math.pi/2,0,0),28+i*8,3,style.Windup,i==1 and style.Gold or style.White,.2,.8)
 end
 local sword=core.Root.Parent:FindFirstChild("Basic Sword")
 local blade=sword and sword:FindFirstChild("Blade")
 if blade then
  local light=cast:Add(Instance.new("PointLight"))
  light.Color=style.Gold;light.Brightness=0;light.Range=22;light.Parent=blade
  Effects:Create(light,TweenInfo.new(style.Windup),{Brightness=5}):Play()
 end
end
function Visuals.Hazard(core,split,actor,lane,groundY,cast,style)
 local center=lane.frame.Position+lane.frame.LookVector*lane.length*.5
 local frame=CFrame.new(center.X,groundY+.14,center.Z)*lane.frame.Rotation
 local scar=cast:Add(core.Part("EnhancedSplitDamageHazard",frame,
  Vector3.new(lane.width,.18,lane.length),style.Gold,.3))
 scar:SetAttribute("Damage",style.HazardDamage)
 scar:SetAttribute("TickInterval",style.HazardInterval)
 scar:SetAttribute("Lifetime",style.HazardDuration)
 scar:SetAttribute("ExpiresAt",workspace:GetServerTimeNow()+style.HazardDuration)
 Effects:Create(scar,TweenInfo.new(.5),{Transparency=.65}):Play()
 local trail,pulses=split.TrailEffects(lane,lane.frame.Position.Y-groundY,style.HazardDuration)
 trail.Name="EnhancedSplitBurningRift"
 cast:Add(trail)
 Audio.Emit(actor,"SplitActivate",core.Root)
 Audio.Loop(cast,actor,"SplitHum",scar)
  
 local ctx=Crimson.Context(core)
 local origin=Vector3.new(core.Root.Position.X,groundY+.15,core.Root.Position.Z)
 FX.Shockwave(ctx,cast,CFrame.new(origin),4,60,.55,style.White,.1)
 FX.Shockwave(ctx,cast,CFrame.new(origin+Vector3.new(0,.02,0)),3,82,.7,style.Gold,.25)
 core.ScreenEffect("Shake",{Origin=core.Root.Position,Radius=220,Duration=.4,Intensity=.65})
 cast:Schedule(style.HazardDuration,function()
  for _,t in ipairs(pulses) do t:Cancel() end
  for _,v in ipairs(trail:GetDescendants()) do
   if v:IsA("ParticleEmitter") or v:IsA("PointLight") then v.Enabled=false end
   if v:IsA("BasePart") then Effects:Create(v,TweenInfo.new(.35),{Transparency=1}):Play() end
  end
  Effects:Create(scar,TweenInfo.new(.35),{Transparency=1}):Play()
 end)
end
return table.freeze(Visuals)
