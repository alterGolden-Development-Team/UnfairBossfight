 
local B=script:FindFirstAncestor("BossSystem")
local G=require(script.Parent.Geometry)
local Encounter=require(B.Players.PlayerEncounter)
local Runtime=require(B.Combat.CombatRuntime)
local W={}
function W.New(actor,core,center,style)
 local live={}
 local api={}
 function api.Add(spec,startedAt)
  live[#live+1]={Spec=spec,At=startedAt+spec.Start,Previous=spec.Radius,
   Seen=setmetatable({},{__mode="k"}),Distances=setmetatable({},{__mode="k"})}
 end
 function api.Clear() table.clear(live) end
 api.Dispose=api.Clear
 function api.Step(now)
  local chars=core.Characters()
  for i=#live,1,-1 do
   local wave=live[i]
   local spec=wave.Spec
   if now>=wave.At then
    local radius=G.WaveRadius(spec,now-wave.At+spec.Start)
    for _,char in ipairs(chars) do
     local root=char:FindFirstChild("HumanoidRootPart")
     if root and core.Alive(char) then
      local delta=(root.Position-center)*Vector3.new(1,0,1)
      local distance=delta.Magnitude
      if not wave.Seen[char] and G.WaveCrosses(char,center,style,spec,wave.Previous,radius,wave.Distances[char]) then
       wave.Seen[char]=true
       local damage=Encounter.Damage(char,spec.Damage,actor,nil,{Skill=style.Name,FinalityWave=true})
       if damage>0 then
        actor:SetAttribute("FinalityWaveHits",(actor:GetAttribute("FinalityWaveHits") or 0)+1)
        Runtime.Knockback(actor,char,delta.Magnitude>.1 and delta.Unit or Vector3.xAxis,
         {Speed=style.WaveKnockSpeed,Lift=style.WaveKnockLift,Duration=.18,Sustain=.05,AllowPlayerControl=true,ContainsArena=true,UnscaledDifficulty=true})
       end
      end
      wave.Distances[char]=distance
     end
    end
    wave.Previous=radius
    if radius>=spec.MaxRadius then table.remove(live,i) end
   end
  end
 end
 return api
end
return table.freeze(W)
