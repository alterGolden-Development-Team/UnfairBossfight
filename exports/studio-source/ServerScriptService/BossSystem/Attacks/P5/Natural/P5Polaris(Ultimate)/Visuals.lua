--[[
 Polaris visuals (server side).
 Rendering lives on the clients in ReplicatedStorage.VFXEngine.Effects.Polaris; this module
 only sends timed cues, plays the positional sounds, and makes an invisible carrier part for
 each bolt (the client dresses it). Same API Behavior already calls.
]]
local Net=require(game.ReplicatedStorage.VFXEngine.Net)
local Http=game:GetService("HttpService")
local CollectionService=game:GetService("CollectionService")
local Debris=game:GetService("Debris")

local V={}
local PENTA={1,9/8,5/4,3/2,5/3,2,9/4,5/2,3,10/3,4}

local function soundAt(parent,style,key,vol,speed,life)
 local id=style.Sounds and style.Sounds[key]
 if not id or id==""or not parent then return end
 local host=parent
 if typeof(parent)=="Vector3"then
  host=Instance.new("Attachment")
  host.WorldPosition=parent
  host.Parent=workspace.Terrain
  Debris:AddItem(host,life or 3)
 end
 local s=Instance.new("Sound")
 s.SoundId=id s.Volume=vol s.PlaybackSpeed=speed
 s.RollOffMode=Enum.RollOffMode.InverseTapered s.RollOffMinDistance=30 s.RollOffMaxDistance=style.ScreenRange or 260
 s.Parent=host
 s:Play()
 Debris:AddItem(s,life or 3)
end

local function findGround(root)
 local ok,pos=pcall(function()
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  local boss=root:FindFirstAncestorOfClass("Model")
  params.FilterDescendantsInstances=boss and{boss}or{}
  local hit=workspace:Raycast(root.Position,Vector3.new(0,-400,0),params)
  if not hit or hit.Normal.Y<.85 then return nil end
  local m=hit.Instance:FindFirstAncestorOfClass("Model")
  if m and m:FindFirstChildOfClass("Humanoid")then return nil end
  return hit.Position
 end)
 return ok and pos or nil
end

function V.Restore(fx)
 if fx and fx.Token and not fx.Ended then
  fx.Ended=true
  Net.Send("Polaris","End",{Token=fx.Token})
 end
end

function V.Build(ctx,root,style)
 local s=style
 local fx={Style=s,Root=root,Token=Http:GenerateGUID(false),NextPulse=0,Chimed={}}
 fx.Total=s.Duration or (s.Charge+(s.Shots-1)*s.ShotGap+s.ProjectileLife+#s.Burn*s.BurnInterval+s.Recovery)
 fx.FinaleAt=s.Charge+(s.Shots-1)*s.ShotGap
 Net.Send("Polaris","Start",{
  Token=fx.Token,Root=root,Center=root.Position,Ground=findGround(root),T0=Net.Now(),
  Total=fx.Total,FinaleAt=fx.FinaleAt,Rise=s.Rise,Charge=s.Charge,Shots=s.Shots,ShotGap=s.ShotGap,
  Telegraph=s.Telegraph,SeedFlight=s.SeedFlight,DomeRadius=s.DomeRadius,DomeLift=s.DomeLift,
  CurtainRadius=s.CurtainRadius,CurtainHeight=s.CurtainHeight,Hover=s.Hover,Palette=table.clone(ctx.Palette),
 })
 return fx
end

 -- sound timing only; visuals run on the clients
function V.Update(fx,root,t,dt)
 local s=fx.Style
 if t<s.Charge and t>.25 and t>=fx.NextPulse then
  local k=math.clamp(t/s.Charge,0,1)
  fx.NextPulse=t+(.5+(.11-.5)*k*k)
  soundAt(root,s,"Pulse",.18+.2*k,.55+(1.6-.55)*k,1.5)
 end
 if not fx.Boomed and t>=fx.Total-1.65 then  -- the north star explodes (client draws it)
  fx.Boomed=true
  soundAt(root,s,"Boom",1,.38,5)
  soundAt(root,s,"Whoosh",.7,.45,3)
 end
 for i=1,s.Shots do
  if not fx.Chimed[i]then
   local arrive=math.max(s.Charge+(i-1)*s.ShotGap-s.Telegraph-s.SeedFlight,.25)+s.SeedFlight
   if t>=arrive then
    fx.Chimed[i]=true
    soundAt(root,s,"Chime",i==s.Shots and .6 or .4,PENTA[math.min(i,#PENTA)]*.7,2.5)
   end
  end
 end
end

function V.Release(ctx,fx,root)
 Net.Send("Polaris","Release",{Token=fx.Token})
 soundAt(root,fx.Style,"Boom",.9,.5,5)
 soundAt(root,fx.Style,"Whoosh",.6,.55,3)
end

function V.Finale(ctx,fx,root)
 Net.Send("Polaris","Finale",{Token=fx.Token})
 soundAt(root,fx.Style,"Boom",1,.42,5)
 for _,r in ipairs({.8,1.2,1.6})do soundAt(root,fx.Style,"Chime",.3,r,3)end
end

function V.Telegraph(ctx,fx,spec)
 Net.Send("Polaris","Telegraph",{
  Token=fx.Token,From=spec.From,Target=spec.Root and spec.Root.Parent,Color=spec.Color,
  Duration=spec.Duration,Start=Net.Now(),Final=spec.Final,Volley=spec.Volley,
 })
 soundAt(spec.Root,fx.Style,"Pulse",.3,2.1+.06*(spec.Volley or 1),1.2)
end

function V.Fire(ctx,fx,from,color,volley,final)
 Net.Send("Polaris","Fire",{From=from,Color=color,Final=final})
 soundAt(from,fx.Style,"Whoosh",.3,1.3,2)
 if final then soundAt(from,fx.Style,"Boom",.5,.8,4)end
end

function V.Impact(ctx,fx,pos,color,heavy)
 if not pos then return end
 Net.Send("Polaris","Impact",{Pos=pos,Color=color,Heavy=heavy})
 soundAt(pos,fx.Style,"Boom",.55,heavy and 1 or 1.4,3)
 soundAt(pos,fx.Style,"Chime",.3,2.2,2)
end

function V.Fizzle(ctx,fx,pos,color)
 if not pos then return end
 Net.Send("Polaris","Fizzle",{Pos=pos,Color=color})
 soundAt(pos,fx.Style,"Chime",.25,2.4,2)
end

 -- invisible carrier; clients attach the star, trail and light to it
function V.Projectile(ctx,origin,color,scale)
 scale=scale or 1
 local part=ctx.Part("AuroraProjectile",Vector3.one*2.2*scale,origin,color,1,Enum.PartType.Ball)
 part.Transparency=1
 part.CastShadow=false
 part:SetAttribute("VFX","Polaris")
 part:SetAttribute("Color",color)
 part:SetAttribute("Scale",scale)
 CollectionService:AddTag(part,"VFXDecorate")
 return part
end

 -- Starfall: a constellation star dives at a marked spot
function V.Starfall(ctx,fx,spec)
 Net.Send("Polaris","Starfall",{Token=fx.Token,Index=spec.Index,To=spec.To,Warn=spec.Warn,Color=spec.Color,Radius=spec.Radius})
 soundAt(spec.To,fx.Style,"Pulse",.3,1.8,1.5)
end

function V.StarfallHit(ctx,fx,pos,color,radius)
 Net.Send("Polaris","StarfallHit",{Token=fx.Token,Pos=pos,Color=color,Radius=radius})
 soundAt(pos,fx.Style,"Boom",.5,1.25,3)
 soundAt(pos,fx.Style,"Chime",.25,2.6,2)
end

 -- North Cross: four ground blades from the boss
function V.Cross(ctx,fx,spec)
 Net.Send("Polaris","Cross",{Token=fx.Token,Center=spec.Center,Angle=spec.Angle,Length=spec.Length,Width=spec.Width,Warn=spec.Warn,Index=spec.Index})
 soundAt(spec.Center,fx.Style,"Pulse",.45,1.2,2)
end

function V.CrossHit(ctx,fx,spec)
 Net.Send("Polaris","CrossHit",{Token=fx.Token,Center=spec.Center,Angle=spec.Angle,Length=spec.Length,Width=spec.Width,Index=spec.Index})
 soundAt(spec.Center,fx.Style,"Boom",.85,.7,4)
 soundAt(spec.Center,fx.Style,"Whoosh",.5,.8,3)
end

return table.freeze(V)
