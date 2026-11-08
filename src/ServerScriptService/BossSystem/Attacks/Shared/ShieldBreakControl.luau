local BossSystem = script:FindFirstAncestor("BossSystem")
local Status = require(BossSystem.Combat.StatusEffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local api = {}
local electric=setmetatable({}, {__mode="k"})
local trips = setmetatable({}, {__mode = "k"})
function api.Apply(ctx, character, seconds, trip, direction, options)
 options=options or {}
 if not ctx.Valid() or Status.IsDebuffImmune(character) then return false end
 local h = character:FindFirstChildOfClass("Humanoid")
 if not h or h.Health <= 0 then return false end
 local cast = ctx.Cast(trip and "P1LeafTrip" or "P1LightningStun", seconds)
 if not Status.ApplyStun(character, cast, seconds, 0.5, {Family = trip and "ShieldLeaf" or "ShieldLightning", AllowDefense = true, Effect=trip and "Flung" or nil}) then
  cast:Dispose(); return false
 end
 local priorPlatform = h.PlatformStand
 if trip then
  if trips[character] then trips[character]:Dispose(); priorPlatform = h.PlatformStand end
  trips[character] = cast
  h.PlatformStand = true
  Status.TrackDebuff(character,"Flung",cast,workspace:GetServerTimeNow()+seconds)
  character:SetAttribute("ShieldLeafTripped", true)
 end
 character:SetAttribute(trip and "ShieldLeafTripUntil" or "ShieldLightningStunUntil", workspace:GetServerTimeNow() + seconds)
 local impulse = trip and Runtime.Knockback(ctx.Actor, character, direction or Vector3.new(0,0,-1),
  {Speed = options.Speed or 12, Lift = options.Lift or 58, Duration = .65, Sustain = .2, ContainsArena = true})
 cast.OnDispose = function()
  Status.ReleaseRestraint(character, cast)
  if impulse then impulse:Dispose() end
  if trip and trips[character] == cast then
   trips[character] = nil
   if h.Parent then
    h.PlatformStand = priorPlatform
    if not priorPlatform and h.Health > 0 then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
   end
   if character.Parent then
    character:SetAttribute("ShieldLeafTripped", false)
    Status.TrackDebuff(character,"Flung",cast,nil)
    character:SetAttribute("ShieldLeafTripUntil", 0)
   end
  elseif not trip and character.Parent then
   character:SetAttribute("ShieldLightningStunUntil", 0)
  end
 end
 cast:Step(function()
  if not ctx.Valid() or not character.Parent or h.Health <= 0 or Status.IsDebuffImmune(character) then
   cast:Dispose(); return false
  end
  return true
 end)
 return true
end
function api.Electricify(ctx,character)
 if not ctx.Valid() or Status.IsDebuffImmune(character) then return false end
 local h=character:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 then return false end
 if electric[character] and electric[character]:Alive() then return true end
 local cast=ctx.Cast("Electricified",10.55)
 electric[character]=cast
 Status.TrackDebuff(character,"Electricified",cast,workspace:GetServerTimeNow()+10)
 cast.OnDispose=function()
  Status.ReleaseRestraint(character,cast)
  if electric[character]==cast then
   electric[character]=nil
   Status.TrackDebuff(character,"Electricified",cast,nil)
  end
 end
 cast:Step(function()
  if not character.Parent or h.Health<=0 or Status.IsDebuffImmune(character) then cast:Dispose();return false end
  return true
 end)
 for i=1,5 do
  cast:Schedule(i*2,function()
   if not ctx.Valid() or not character.Parent or h.Health<=0 or Status.IsDebuffImmune(character) then cast:Dispose();return end
   local root=character:FindFirstChild("HumanoidRootPart")
   if not root then cast:Dispose();return end
   if ctx.Damage(character,10,"Electricified")>0 then
    Status.ApplyStun(character,cast,.5,0,{Family="Electricified",AllowDefense=true,Effect="Electricified"})
    cast:Schedule(.5,function() Status.ReleaseRestraint(character,cast) end)
    character:SetAttribute("ElectricifiedZapCount",(character:GetAttribute("ElectricifiedZapCount") or 0)+1)
    local fx=ctx.Cast("ElectricifiedZap",.22)
    local from=root.Position-Vector3.new(0,3,0)
    for j=1,6 do
     local to=root.Position+Vector3.new(math.sin(j*5)*1.8,-3+j,math.cos(j*3)*1.8)
     ctx.Line(fx,"ElectricifiedArc",from,to,.18,Color3.fromRGB(180,235,255),.05)
     from=to
    end
   end
  end)
 end
 return true
end
function api.Clear(character)
 if electric[character] then electric[character]:Dispose() end
 if trips[character] then trips[character]:Dispose() end
end
return api
