local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Shared=game.ReplicatedStorage.BossShared
local Reset=require(Shared.Presentation.CinematicReset)
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild("BossCombatEffects")
local active={}
local gui=Instance.new("ScreenGui")
gui.Name="AstralScreenEffects"gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=35
gui.Parent=player:WaitForChild("PlayerGui")
local shade=Instance.new("Frame")shade.Size=UDim2.fromScale(1,1)shade.BackgroundColor3=Color3.new(0,0,0)
shade.BackgroundTransparency=1 shade.BorderSizePixel=0 shade.Parent=gui
local red=Instance.new("Frame")red.Size=UDim2.fromScale(1,1)red.BackgroundColor3=Color3.fromRGB(180,0,35)
red.BackgroundTransparency=1 red.BorderSizePixel=0 red.Parent=gui
local edges={}
for i=1,4 do
 local f=Instance.new("Frame")f.BackgroundColor3=Color3.fromRGB(255,25,75)f.BackgroundTransparency=1 f.BorderSizePixel=0 f.Parent=gui
 local g=Instance.new("UIGradient")g.Rotation=({0,180,90,270})[i]
 g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.7,.35),NumberSequenceKeypoint.new(1,1)})g.Parent=f
 edges[i]=f
end
local grade=Instance.new("ColorCorrectionEffect")grade.Name="AstralDarkening"grade.Enabled=false grade.Parent=Lighting
local flash=0
local function resetView()
 shade.BackgroundTransparency=1 red.BackgroundTransparency=1
 for _,edge in ipairs(edges)do edge.BackgroundTransparency=1 end
 grade.Enabled=false flash=0
end
local function clear()table.clear(active)resetView()end
local events=remote.OnClientEvent:Connect(function(kind,data)
 if kind~="P5Astral"or type(data)~="table"or type(data.Token)~="string"then return end
 if data.Stage=="End"then active[data.Token]=nil
 elseif data.Stage=="Start"and typeof(data.Owner)=="Instance"and type(data.Params)=="table"then
  active[data.Token]={Owner=data.Owner,Attack=data.Attack,Params=data.Params,Generation=data.Generation,StartedAt=data.StartedAt,Duration=data.Duration or 25}
 elseif(data.Stage=="Impact"or data.Stage=="Burst")and typeof(data.Center)=="Vector3"then
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root then flash=math.max(flash,math.clamp(1-(root.Position-data.Center).Magnitude/100,0,1)*.4)end
 end
end)
local render=Run.RenderStepped:Connect(function(dt)
 local now=workspace:GetServerTimeNow()
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local darkness,heat=0,0
 for token,effect in pairs(active)do
  local owner=effect.Owner
  local h=owner and owner:FindFirstChildOfClass("Humanoid")
  local bossRoot=owner and owner:FindFirstChild("HumanoidRootPart")
  if not owner or not owner.Parent or not h or h.Health<=0 or owner:GetAttribute("Phase")~=5
   or owner:GetAttribute("EncounterEnded")or(owner:GetAttribute("PhaseGeneration")or 0)~=(effect.Generation or 0)or now-effect.StartedAt>effect.Duration+2 then active[token]=nil
  elseif root and Reset.ViewAllowed()and bossRoot then
   local distance=((root.Position-bossRoot.Position)*Vector3.new(1,0,1)).Magnitude
   if effect.Attack=="P5Polaris(Ultimate)"then
    -- Polaris darkens through VFXEngine.Sky (real night sky) instead of a black overlay
   elseif effect.Attack=="P5IrisStar"then
    local starPosition=bossRoot.Position+Vector3.yAxis*effect.Params.Height
    local proximity=(root.Position-starPosition).Magnitude
    -- Iris Star now blinds with white light (VFXEngine.Effects.IrisStar); no red heat
   end
  end
 end
 if not Reset.ViewAllowed()or not root then resetView()return end
 flash=math.max(0,flash-dt*1.6)
 grade.Enabled=darkness>.005 grade.Brightness=-darkness*.3 grade.Contrast=darkness*.22
 shade.BackgroundTransparency=1-darkness
 red.BackgroundTransparency=1-math.min(.45,heat*.32+flash)
 local width=.08+.38*heat
 edges[1].Position=UDim2.fromScale(0,0)edges[1].Size=UDim2.fromScale(width,1)
 edges[2].Position=UDim2.fromScale(1-width,0)edges[2].Size=UDim2.fromScale(width,1)
 edges[3].Position=UDim2.fromScale(0,0)edges[3].Size=UDim2.fromScale(1,width)
 edges[4].Position=UDim2.fromScale(0,1-width)edges[4].Size=UDim2.fromScale(1,width)
 for _,edge in ipairs(edges)do edge.BackgroundTransparency=1-heat*.78 end
end)
Reset.Register(script,clear,resetView)
script.Destroying:Connect(function()events:Disconnect()render:Disconnect()clear()grade:Destroy()gui:Destroy()end)
