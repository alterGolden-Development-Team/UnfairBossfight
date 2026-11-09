local Effects=require(script:FindFirstAncestor("BossSystem").Combat.EffectService)
local V={}
local gold=Color3.fromRGB(255,195,25)
local white=Color3.fromRGB(255,245,180)
function V.Weapon(ctx,cast,kind,scale)
 scale=scale or 1
 local parts={}
 local function piece(name,offset,size,color,alpha)
  local p=ctx.Part(cast,"Swordmaster"..kind..name,ctx.Root.CFrame,size*scale,color,alpha or 0)
  table.insert(parts,{part=p,offset=offset+Vector3.zero})
  return p
 end
 local length=kind=="Greatsword" and 30 or kind=="Rapier" and 11 or 9
 local width=kind=="Greatsword" and 6 or kind=="Rapier" and .35 or 1.8
 piece("Grip",Vector3.new(0,0,1),Vector3.new(.65,.65,3),Color3.fromRGB(55,40,25))
 piece("Guard",Vector3.new(0,0,-1),Vector3.new(width+3,.7,.7),gold)
 if kind=="Hammer" then
  piece("Handle",Vector3.new(0,0,-5),Vector3.new(.7,.7,10),gold)
  piece("Head",Vector3.new(0,0,-10),Vector3.new(9,5,4),gold)
  piece("HeadCore",Vector3.new(0,0,-10),Vector3.new(9.2,.8,4.2),white)
 elseif kind=="Sickle" then
  piece("Shaft",Vector3.new(0,0,-4),Vector3.new(.7,.7,7),gold)
  for i=1,7 do
   local angle=i/7*math.pi*.75
   piece("Hook",Vector3.new(math.sin(angle)*4,0,-7-math.cos(angle)*4),Vector3.new(1.5,.6,2),white)
  end
 else
  piece("Blade",Vector3.new(0,0,-1-length*.5),Vector3.new(width,.9,length),gold,.1)
  piece("Edge",Vector3.new(0,0,-1-length*.5),Vector3.new(width+.15,.2,length+.2),white,.08)
  local tip=piece("Tip",Vector3.new(0,0,-1-length),Vector3.new(width,.9,3),white,.1)
  tip.Shape=Enum.PartType.Ball
 end
 local weapon={}
 function weapon.Update(frame)
  for _,v in ipairs(parts) do if v.part.Parent then v.part.CFrame=frame*CFrame.new(v.offset*scale) end end
 end
 function weapon.Remove()
  for _,v in ipairs(parts) do
   if cast.objects[v.part] then Effects.Release(v.part);cast.objects[v.part]=nil end
  end
 end
 weapon.Update(ctx.Root.CFrame)
 return weapon
end
function V.Burst(ctx,cast,position,radius)
 local p=ctx.Part(cast,"SwordmasterImpact",CFrame.new(position),Vector3.one*2,white,.2)
 p.Shape=Enum.PartType.Ball
 Effects:Create(p,TweenInfo.new(.3),{Size=Vector3.one*radius,Transparency=1}):Play()
 cast:Schedule(.35,function() if cast.objects[p] then Effects.Release(p);cast.objects[p]=nil end end)
end
function V.Chain(ctx,cast,character)
 local root=character.HumanoidRootPart
 local links={}
 for i=1,28 do
  local p=ctx.Part(cast,"SwordmasterTrapLink",root.CFrame,Vector3.new(.6,.3,1.2),gold,.05)
  p.Material=Enum.Material.Metal
  table.insert(links,p)
 end
 local tether=ctx.Line(cast,"SwordmasterChainTether",ctx.Root.Position,root.Position,.35,gold,.15)
 cast:Step(function()
  if not root.Parent or not character:GetAttribute("SwordmasterChained") then
   for _,p in ipairs(links) do p.Transparency=1 end
   tether.Transparency=1
   return false
  end
  for i,p in ipairs(links) do
   local a=i/14*math.pi*2
   local y=i<=14 and -.5 or 1
   local pos=root.Position+Vector3.new(math.cos(a)*2.4,y,math.sin(a)*2.4)
   p.CFrame=CFrame.lookAt(pos,pos+Vector3.new(-math.sin(a),0,math.cos(a)))*CFrame.Angles(0,0,i%2*math.pi/2)
  end
  local from,to=ctx.Root.Position,root.Position
  tether.CFrame=CFrame.lookAt((from+to)*.5,to)
  tether.Size=Vector3.new(.35,.35,math.max(.01,(to-from).Magnitude))
  return true
 end)
end
return V
