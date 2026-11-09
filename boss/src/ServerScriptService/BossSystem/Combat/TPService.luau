local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local B=script:FindFirstAncestor("BossSystem")
local Net=require(game.ReplicatedStorage:WaitForChild("VFXEngine"):WaitForChild("Net"))

local api={}
local CFG=table.freeze({
 Max=100,
 OrbValue=5,
 OrbLife=22,
 OrbArmTime=.7,  -- orb flight time from the boss before it can be picked up
 PickupRadius=13,  -- walking near an orb picks it up; no need to touch it
 SkillDropChance=.5,
 UltimateMin=1, UltimateMax=3,
})
api.Config=CFG

local orbs={}
local started=false
local BOSS="alterGolden, the Nothing"

local function now()return workspace:GetServerTimeNow()end
local function tp()return workspace:GetAttribute("P5TP")or 0 end
local function setTP(v)workspace:SetAttribute("P5TP",math.clamp(math.floor(v+.5),0,CFG.Max))end
function api.Boss()return workspace:FindFirstChild(BOSS)end
function api.InPhase5(boss)
 boss=boss or api.Boss()
 return boss~=nil and boss.Parent~=nil and boss:GetAttribute("Phase")==5 and not boss:GetAttribute("EncounterEnded")
end
 -- the bar exists for Phase 5 until godmode is stripped; pickups and breaks pause during a transition
function api.Running(boss)
 boss=boss or api.Boss()
 return api.InPhase5(boss)and not boss:GetAttribute("GodStripped")
end
function api.Active(boss)
 boss=boss or api.Boss()
 return api.Running(boss)and not boss:GetAttribute("PhaseTransitionInProgress")
end

local function participant(player)
 local char=player and player.Character
 local h=char and char:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 or not char:FindFirstChild("HumanoidRootPart")then return nil end
 if player:GetAttribute("ViewAsServer")then return nil end
 local ok,defeated=pcall(function()return require(B.Players.PlayerEncounter).IsDefeated(player)end)
 if ok and defeated then return nil end
 return char
end

function api.Clear()
 for orb in pairs(orbs)do if orb.Parent then orb:Destroy()end end
 table.clear(orbs)
 setTP(0)
end

function api.DropOrbs(origin,count)
 if not api.Active()or count<=0 then return end
 local boss=api.Boss()
 if boss and boss:GetAttribute("P5Mode")then return end  -- no orbs while a mode's shield is up (P5ModeService)
 local Placement=require(B.Encounter.ArenaPlacement)
 for _=1,count do
  local ang=math.random()*math.pi*2
  local dist=16+math.random()*34
  local spot=origin+Vector3.new(math.cos(ang)*dist,0,math.sin(ang)*dist)
  local ok,ground=pcall(Placement.GroundPoint,spot,{Clamp=true,Margin=10})
  ground=ok and ground or spot
  local p=Instance.new("Part")
  p.Name="P5TPOrb"p.Shape=Enum.PartType.Ball p.Size=Vector3.one*3
  p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Transparency=1
  p.Position=ground+Vector3.new(0,3.5,0)
  p:SetAttribute("VFX","TPOrb")
  p:SetAttribute("From",origin)
  p:SetAttribute("Born",now())
  p:SetAttribute("Arm",CFG.OrbArmTime)
  p.Parent=workspace
  CollectionService:AddTag(p,"VFXDecorate")
  orbs[p]={Expires=now()+CFG.OrbLife,ArmedAt=now()+CFG.OrbArmTime}
 end
end

 -- called by AttackController when a skill finishes successfully
function api.OnSkill(actor,name,metadata)
 if not api.Active(actor)or not metadata or metadata.NativePhase~=5 then return end
 local root=actor:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local count=0
 if metadata.Ultimate then
  count=math.random(CFG.UltimateMin,CFG.UltimateMax)
 elseif math.random()<CFG.SkillDropChance then
  count=1
 end
 api.DropOrbs(root.Position,count)
end

local function collect()
 local t=now()
 for orb,info in pairs(orbs)do
  if not orb.Parent or t>=info.Expires or not api.Running()then
   if orb.Parent then
    Net.Send("TPOrb","Expire",{Pos=orb.Position})
    orb:Destroy()
   end
   orbs[orb]=nil
  elseif t>=info.ArmedAt then
   for _,player in ipairs(Players:GetPlayers())do
    local char=participant(player)
    if char and(char.HumanoidRootPart.Position-orb.Position).Magnitude<=CFG.PickupRadius then
     api.Add(CFG.OrbValue)
     Net.Send("TPOrb","Collect",{Pos=orb.Position,Player=player})
     orb:Destroy()
     orbs[orb]=nil
     break
    end
   end
  end
 end
end

function api.Add(v)
 if api.Running()then setTP(tp()+v)end
end

local function tryBreak(player)
 local boss=api.Boss()
 if not api.Active(boss)or tp()<CFG.Max then return false end
 local char=participant(player)
 if not char then return false end
 setTP(0)
 boss:SetAttribute("GodStripped",true)
 boss:SetAttribute("GodStrippedBy",player.Name)
 do
  local shield=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig).Phase5BaseShield or 5000
  if boss:GetAttribute("P5Mode")then
   boss:SetAttribute("P5BaseMaxShield",shield)boss:SetAttribute("P5BaseShield",shield)
  else
   boss:SetAttribute("MaxShield",shield)boss:SetAttribute("Shield",shield)
   local glow=boss:FindFirstChild("ShieldGlow")if glow then glow.Enabled=true end
  end
 end
 Net.Send("TPBreak","Shockwave",{Pos=char.HumanoidRootPart.Position,Boss=boss:FindFirstChild("HumanoidRootPart"),Player=player})
 pcall(function()
  require(B.Players.PlayerEncounter).Say("...You tore through divinity itself? Then come and prove it.",nil,{Duration=3})
 end)
 return true
end

function api.Start()
 if started then return end
 started=true
 workspace:SetAttribute("P5TP",0)
 workspace:SetAttribute("P5TPActive",false)
 local remote=game.ReplicatedStorage:FindFirstChild("P5TPBreak")
 if not remote then
  remote=Instance.new("RemoteEvent")remote.Name="P5TPBreak"remote.Parent=game.ReplicatedStorage
 end
 local last={}
 remote.OnServerEvent:Connect(function(player)
  if last[player]and os.clock()-last[player]<.5 then return end
  last[player]=os.clock()
  tryBreak(player)
 end)
 Players.PlayerRemoving:Connect(function(p)last[p]=nil end)
 local acc=0
 Run.Heartbeat:Connect(function(dt)
  acc+=dt
  if acc<.1 then return end
  acc=0
  local boss=api.Boss()
  local active=api.Running(boss)
  if workspace:GetAttribute("P5TPActive")~=active then
   workspace:SetAttribute("P5TPActive",active)
   if not active then api.Clear()end
  end
   -- leaving Phase 5 (a new attempt) gives the boss its godmode back
  if boss and boss:GetAttribute("GodStripped")and not api.InPhase5(boss)then boss:SetAttribute("GodStripped",nil)end
  if next(orbs)then collect()end
 end)
end

return api
