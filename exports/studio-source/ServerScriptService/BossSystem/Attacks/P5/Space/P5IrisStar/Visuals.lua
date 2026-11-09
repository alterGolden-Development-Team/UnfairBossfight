--[[
 Iris Star visuals (server side): cues for VFXEngine.Effects.IrisStar, ground raycast, sounds.
]]
local Net=require(game.ReplicatedStorage.VFXEngine.Net)
local Http=game:GetService("HttpService")
local Debris=game:GetService("Debris")
local V={}

function V.Ground(pos,ignore)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=ignore or{}
 local hit=workspace:Raycast(pos+Vector3.new(0,4,0),Vector3.new(0,-400,0),params)
 return hit and hit.Position.Y or pos.Y-3
end

function V.Sound(fx,key,at,vol,speed,life)
 local id=fx.S.Sounds and fx.S.Sounds[key]
 if not id or id==""then return end
 local host=Instance.new("Attachment")
 host.WorldPosition=at host.Parent=workspace.Terrain
 local s=Instance.new("Sound")
 s.SoundId=id s.Volume=vol s.PlaybackSpeed=speed
 s.RollOffMode=Enum.RollOffMode.InverseTapered s.RollOffMinDistance=30 s.RollOffMaxDistance=260
 s.Parent=host s:Play()
 Debris:AddItem(host,life or 3)
end

function V.Build(ctx,root,S)
 local fx={Token=Http:GenerateGUID(false),S=S}
 Net.Send("IrisStar","Start",{Token=fx.Token,Root=root,Height=S.Height,Radius=S.EyeRadius,Windup=S.Windup,T0=Net.Now(),
  BlindRange=S.BlindRange,BlindInner=S.BlindInner})
 V.Sound(fx,"Open",root.Position+Vector3.yAxis*S.Height,.5,.4,3)
 return fx
end

function V.Send(fx,stage,data)
 data.Token=fx.Token
 Net.Send("IrisStar",stage,data)
end

function V.Finish(fx)
 if fx and not fx.Ended then
  fx.Ended=true
  Net.Send("IrisStar","End",{Token=fx.Token})
 end
end

return table.freeze(V)
