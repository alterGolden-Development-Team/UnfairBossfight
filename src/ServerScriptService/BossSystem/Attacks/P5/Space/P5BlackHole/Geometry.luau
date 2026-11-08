 
local G={}
function G.Smooth(t) t=math.clamp(t,0,1) return t*t*(3-2*t) end
function G.Direction(from,to)
 local d=(to-from)*Vector3.new(1,0,1)
 return d.Magnitude>.01 and d.Unit or Vector3.zero
end
 
function G.SweptContains(previousPlayer,player,previousHole,hole,radius)
 local a,b=previousPlayer-previousHole,player-hole
 local delta=b-a
 local t=delta:Dot(delta)>.0001 and math.clamp(-a:Dot(delta)/delta:Dot(delta),0,1) or 0
 return (a+delta*t).Magnitude<=radius
end
function G.PullSpeed(distance,style)
 local proximity=1-math.clamp(distance/style.PullRange,0,1)
 return style.PullMinSpeed+(style.PullMaxSpeed-style.PullMinSpeed)*proximity*proximity
end
 
 
function G.Footprint(coreRadius,hoverHeight,targetHeight)
 local dy=hoverHeight-targetHeight
 return math.sqrt(math.max(coreRadius*coreRadius-dy*dy,0))
end
 
function G.Power(style,ramp)
 return 1+style.Escalation*math.clamp(ramp,0,1)
end
return table.freeze(G)
