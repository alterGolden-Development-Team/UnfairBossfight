 
 
 
local G={}

function G.Clamp01(x) return math.clamp(x,0,1) end
function G.Smooth(t) t=math.clamp(t,0,1) return t*t*(3-2*t) end
function G.EaseOut(t,power) return 1-(1-math.clamp(t,0,1))^(power or 3) end
function G.EaseIn(t,power) return math.clamp(t,0,1)^(power or 2) end

 
 
function G.Contains(character,center,style,radius)
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local h=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not h or h.Health<=0 then return false end
 local d=root.Position-center
 if Vector3.new(d.X,0,d.Z).Magnitude>(radius or style.PillarRadius)+style.HitPadding then return false end
 local leg=character:FindFirstChild("Right Leg") or character:FindFirstChild("Left Leg")
 local feet=root.Position.Y-root.Size.Y*.5-h.HipHeight
 if h.RigType==Enum.HumanoidRigType.R6 then feet-=leg and leg.Size.Y or 2 end
 local head=character:FindFirstChild("Head")
 local top=head and head.Position.Y+head.Size.Y*.5 or root.Position.Y+root.Size.Y*.5
 return feet<center.Y+style.PillarHeight and top>center.Y
end

 
 
 
 
function G.BeatPhase(t,style)
 local c=style.Charge
 local p=math.clamp(t,0,c)/c
 local r0,r1=1/style.ShockwaveInterval,1/style.ShockwaveIntervalEnd
 return c*(r0*p+(r1-r0)*p*p*p/3)
end

 
 
function G.PullPulse(phase,style)
 local f=phase-math.floor(phase)
 local k=style.PulseSharpness
 local floorV=style.PulseFloor
 local norm=(1-math.exp(-k))/k
 return floorV+(1-floorV)*math.exp(-k*f)/norm
end

 
function G.PullSpeed(progress,style,phase)
 local p=math.clamp(progress,0,1)
 local a=style.PullStart+(style.PullEnd-style.PullStart)*p*p*p
 if phase then a*=G.PullPulse(phase,style) end
 return a
end

 
 
function G.PillarRadius(t,style)
 if t<0 or t>=style.PillarDuration then return 0 end
 local full=style.PillarRadius
 local grow=math.clamp(t/style.PillarGrowTime,0,1)
 local r=math.max(full*(1-(1-grow)^3),style.PillarCoreRadius)
 local taperStart=style.PillarDuration-style.PillarTaperTime
 if t>taperStart then
  local k=(t-taperStart)/style.PillarTaperTime
  r*=1-k*k
 end
 return r
end


 
function G.BeatTime(index,style)
 local lo,hi=0,style.Charge
 for _=1,20 do
  local mid=(lo+hi)*.5
  if G.BeatPhase(mid,style)<index then lo=mid else hi=mid end
 end
 return (lo+hi)*.5
end
function G.ChargeWave(index,style)
 return {Start=G.BeatTime(index,style),Speed=style.ShockwaveSpeed,MaxRadius=style.ShockwaveMaxRadius,
  Radius=12,Thickness=3.2,Damage=style.ShockwaveDamage}
end
function G.BurstWaves(style)
 local result={}
 for _,spec in ipairs(style.DetonationWaves) do
  result[#result+1]={Start=spec.Delay or 0,Speed=spec.Speed,MaxRadius=spec.MaxRadius,Radius=10,
   Thickness=spec.Thickness,Damage=style.DetonationWaveDamage}
 end
 return result
end
function G.WaveRadius(wave,elapsed)
 return math.clamp(wave.Radius+wave.Speed*math.max(0,elapsed-wave.Start),wave.Radius,wave.MaxRadius)
end
function G.FeetY(character)
 local root=character:FindFirstChild("HumanoidRootPart")
 local h=character:FindFirstChildOfClass("Humanoid")
 if not root or not h then return math.huge end
 local y=root.Position.Y-root.Size.Y*.5-h.HipHeight
 if h.RigType==Enum.HumanoidRigType.R6 then
  local leg=character:FindFirstChild("Right Leg") or character:FindFirstChild("Left Leg")
  y-=leg and leg.Size.Y or 2
 end
 return y
end
function G.WaveCrosses(character,center,style,wave,previousRadius,radius,previousDistance)
 local root=character:FindFirstChild("HumanoidRootPart")
 local h=character:FindFirstChildOfClass("Humanoid")
 if not root or not h or h.Health<=0 then return false end
 local d=root.Position-center
 local distance=Vector3.new(d.X,0,d.Z).Magnitude
 local before=(previousDistance or distance)-previousRadius
 local after=distance-radius
 local band=wave.Thickness*.5+style.HitPadding
 local feet=G.FeetY(character)
 return math.min(before,after)<=band and math.max(before,after)>=-band
  and feet<=center.Y+style.WaveHitHeight and root.Position.Y+root.Size.Y*.5>=center.Y
end

return table.freeze(G)
