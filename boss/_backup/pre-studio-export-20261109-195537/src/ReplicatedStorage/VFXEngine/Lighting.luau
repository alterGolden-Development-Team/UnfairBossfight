--[[
 VFXEngine.Lighting (client) - the single owner of Lighting and Atmosphere properties.

 Effects never write Lighting directly. They push a named layer:
   Arb.Push("GoldenFog", {Lighting={FogEnd=45}, Atmosphere={Density=.6}}, {Priority=80, Fade=.25})
   Arb.Pop("GoldenFog", .4)
 Layers blend over a base value in priority order (higher wins), each fading by its own
 weight. Any write the arbiter did not make (the server's PhaseController, EncounterTheme
 setting the phase look) is learned as the new base, so the base can change underneath
 active layers and the final restore always returns to the current base, never a stale
 snapshot. ClockTime blends the short way round the clock.
]]
local LightingService=game:GetService("Lighting")
local Run=game:GetService("RunService")
local Arb={}

local layers={}
local order=0
local state={Lighting={},Atmosphere={}}
local createdAtmosphere
local loop

local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end

local function target(kind)
 if kind=="Lighting"then return LightingService end
 local a=LightingService:FindFirstChildOfClass("Atmosphere")
 if not a then
  a=Instance.new("Atmosphere")a.Name="VFXAtmosphere"a.Parent=LightingService
  createdAtmosphere=a
 end
 return a
end

 -- the engine rounds what it stores (colours to 8 bits), so compare loosely
local function same(a,b)
 if typeof(a)~=typeof(b)then return false end
 if typeof(a)=="number"then return math.abs(a-b)<=1e-3*math.max(1,math.abs(a))end
 if typeof(a)=="Color3"then return math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B)<.02 end
 return a==b
end

local function blend(prop,a,b,t)
 if typeof(a)=="number"then
  if prop=="ClockTime"then
   local d=((b-a+12)%24)-12
   return(a+d*t)%24
  end
  return a+(b-a)*t
 end
 if typeof(a)=="Color3"then return a:Lerp(b,t)end
 return t>=.5 and b or a
end

local function track(kind,prop)
 local s=state[kind][prop]
 if s and s.Target.Parent then return s end
 if s then s.Conn:Disconnect()end
 local inst=target(kind)
 s={Target=inst,Base=inst[prop]}
 s.Conn=inst:GetPropertyChangedSignal(prop):Connect(function()
  local v=inst[prop]
  if s.Last==nil or not same(v,s.Last)then s.Base=v end  -- written by someone else: new base
 end)
 state[kind][prop]=s
 return s
end

local function release()
 for _,props in pairs(state)do
  for prop,s in pairs(props)do
   if s.Target.Parent and s.Last~=nil and same(s.Target[prop],s.Last)then s.Target[prop]=s.Base end
   s.Conn:Disconnect()
  end
  table.clear(props)
 end
 if createdAtmosphere then createdAtmosphere:Destroy()createdAtmosphere=nil end
end

local function step(dt)
 local list={}
 for id,l in pairs(layers)do
  if l.W~=l.Goal then
   local r=dt/math.max(l.Fade,1e-3)
   l.W=l.Goal>l.W and math.min(l.W+r,l.Goal)or math.max(l.W-r,l.Goal)
  end
  if l.Goal==0 and l.W<=0 then layers[id]=nil else list[#list+1]=l end
 end
 if #list==0 then
  loop:Disconnect()loop=nil
  release()
  return
 end
 table.sort(list,function(a,b)if a.Priority~=b.Priority then return a.Priority<b.Priority end return a.Order<b.Order end)
 for kind,props in pairs(state)do
  for prop,s in pairs(props)do
   if s.Target.Parent then
    local v=s.Base
    for _,l in ipairs(list)do
     local lv=l.Props[kind]and l.Props[kind][prop]
     if lv~=nil and l.W>0 then v=blend(prop,v,lv,smooth(l.W))end
    end
    if not same(s.Target[prop],v)then
     s.Last=v
     s.Target[prop]=v
     s.Last=s.Target[prop]
    end
   end
  end
 end
end

local function ensureLoop()
 if loop then return end
 local signal=Run:IsRunning()and Run.RenderStepped or Run.Heartbeat
 loop=signal:Connect(step)
end

 -- props = {Lighting={prop=value}, Atmosphere={prop=value}}
function Arb.Push(id,props,opt)
 local l=layers[id]
 if not l then order+=1 l={Id=id,W=0,Order=order}layers[id]=l end
 l.Props=props
 l.Priority=opt and opt.Priority or 50
 l.Fade=opt and opt.Fade or .6
 l.Goal=1
 for kind,ps in pairs(props)do for prop in pairs(ps)do track(kind,prop)end end
 ensureLoop()
end

function Arb.Pop(id,fade)
 local l=layers[id]
 if not l then return end
 l.Goal=0
 if fade then l.Fade=fade end
 ensureLoop()
end

function Arb.Active(id)return layers[id]~=nil and layers[id].Goal>0 end

function Arb.Clear(fade)
 for _,l in pairs(layers)do l.Goal=0 l.Fade=fade or .2 end
 ensureLoop()
end

return Arb
