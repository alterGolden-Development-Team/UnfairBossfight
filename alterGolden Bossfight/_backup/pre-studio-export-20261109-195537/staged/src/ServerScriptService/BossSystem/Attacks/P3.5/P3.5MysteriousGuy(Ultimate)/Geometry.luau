local Tween=game:GetService("TweenService")
local G={}
function G.Lerp(a,b,t)return a+(b-a)*t end
function G.EmergeFactor(elapsed,style)
 local a=math.clamp((elapsed-style.SummonTime)/style.EmergeTime,0,1)
 return G.Lerp(style.EmergeSpeed,1,Tween:GetValue(a,Enum.EasingStyle.Quad,Enum.EasingDirection.Out))
end
function G.FlatSwept(p,a,b)
 local ab=Vector3.new(b.X-a.X,0,b.Z-a.Z)
 local ap=Vector3.new(p.X-a.X,0,p.Z-a.Z)
 local l=ab:Dot(ab)
 local t=l>1e-6 and math.clamp(ap:Dot(ab)/l,0,1)or 0
 return(ap-ab*t).Magnitude
end
return table.freeze(G)
