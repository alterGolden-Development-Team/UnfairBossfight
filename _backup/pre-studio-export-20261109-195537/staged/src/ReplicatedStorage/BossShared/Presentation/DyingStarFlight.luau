--[[
 Dying Star throw path, shared by the server (when it lands) and the client (where to draw it).
 f = {From, Apex, Impact, Rise, Hang, Dive}: the star climbs to the apex high above the landing
 point (eases out), hangs there for a beat, then dives straight down, accelerating into the ground.
]]
return function(f,u)
 if u<f.Rise then
  local k=u/f.Rise
  local flat=f.From:Lerp(f.Apex,k)
  return Vector3.new(flat.X,f.From.Y+(f.Apex.Y-f.From.Y)*(1-(1-k)*(1-k)),flat.Z)
 end
 u-=f.Rise
 if u<f.Hang then return f.Apex end
 local k=math.clamp((u-f.Hang)/f.Dive,0,1)
 return f.Apex:Lerp(f.Impact,k*k)
end
