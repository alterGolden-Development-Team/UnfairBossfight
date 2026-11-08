--[[
 Dying Star visuals (server side): timed cues for VFXEngine.Effects.DyingStar plus sounds.
 The client follows the boss during the summon/barrage and flies the star itself from the
 Throw cue (the shared climb-and-dive path); Critical carries the exact landing position.
]]
local Net=require(game.ReplicatedStorage.VFXEngine.Net)
local Http=game:GetService("HttpService")
local Debris=game:GetService("Debris")
local V={}

local function sound(fx,key,at,vol,speed,life)
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

function V.Build(ctx,core,S,total)
 local fx={Token=Http:GenerateGUID(false),S=S,Root=core.Root}
 Net.Send("DyingStar","Start",{Token=fx.Token,Root=core.Root,Height=S.StarHeight,Radius=S.StarRadius,
  Summon=S.SummonTime,Beams=S.Beams,BeamGap=S.BeamGap,T0=Net.Now(),Total=total})
 sound(fx,"Charge",core.Root.Position+Vector3.yAxis*S.StarHeight,.5,.5,3)
 return fx
end

function V.BeamFire(fx,from,to,shot)
 Net.Send("DyingStar","Beam",{Token=fx.Token,From=from,To=to,Shot=shot})
 sound(fx,"Beam",from,.35,1.4+.05*shot,2)
end

 -- flight: {From, Apex, Impact, Rise, Hang, Dive, ETA} (BossShared.Presentation.DyingStarFlight);
 -- the client draws the same path and times the stars it summons to strike at ETA
function V.Throw(fx,flight)
 local data=table.clone(flight)
 data.Token=fx.Token data.At=Net.Now()
 Net.Send("DyingStar","Throw",data)
 sound(fx,"Beam",flight.From,.6,.6,2)
end

function V.Critical(fx,pos,fuse,radius)
 Net.Send("DyingStar","Critical",{Token=fx.Token,Pos=pos,Fuse=fuse,Radius=radius})
 sound(fx,"Critical",pos,.6,.45,2)
end

function V.Burst(fx,pos,radius)
 Net.Send("DyingStar","Burst",{Token=fx.Token,Pos=pos,Radius=radius})
 sound(fx,"Boom",pos,1,.55,5)
 sound(fx,"Boom",pos,.6,.85,4)
end

function V.Finish(fx)
 if fx and not fx.Ended then
  fx.Ended=true
  Net.Send("DyingStar","End",{Token=fx.Token})
 end
end

return table.freeze(V)
