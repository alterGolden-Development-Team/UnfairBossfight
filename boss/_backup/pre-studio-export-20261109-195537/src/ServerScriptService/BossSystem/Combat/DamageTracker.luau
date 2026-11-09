local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local S={}
local totals=setmetatable({},{__mode="k"})
local dirty={}
local started=false
local watched=setmetatable({},{__mode="k"})
 -- the Lives column: a heart for every life left (player attribute LivesRemaining), so the player list reads as a
 -- lives bar next to Damage
local function hearts(n)
 if type(n)~="number" then return "-" end
 n=math.max(0,math.floor(n))
 if n==0 then return "0" end
 return string.rep("♥",math.min(n,10))..(n>10 and "+" or "").." "..n
end
local function showLives(player)
 local stats=player:FindFirstChild("leaderstats")
 if not stats then stats=Instance.new("Folder") stats.Name="leaderstats" stats.Parent=player end
 local lives=stats:FindFirstChild("Lives")
 if not lives then lives=Instance.new("StringValue") lives.Name="Lives" lives.Parent=stats end
 lives.Value=hearts(player:GetAttribute("LivesRemaining"))
end
local function value(player)
 local stats=player:FindFirstChild("leaderstats")
 if not stats then stats=Instance.new("Folder") stats.Name="leaderstats" stats.Parent=player end
 local damage=stats:FindFirstChild("Damage")
 if not damage then damage=Instance.new("IntValue") damage.Name="Damage" damage.Parent=stats end
 return damage
end
function S.Register(player)
 totals[player]=totals[player] or 0
 value(player).Value=math.floor(totals[player]+0.5)
 showLives(player)
 if not watched[player] then
  watched[player]=player:GetAttributeChangedSignal("LivesRemaining"):Connect(function() showLives(player) end)
 end
end
function S.Add(character,amount)
 if type(amount)~="number" or amount~=amount or amount<=0 or amount==math.huge then return end
 local player=character and Players:GetPlayerFromCharacter(character)
 if not player or player.Character~=character or player:GetAttribute("ViewAsServer")==true then return end
 totals[player]=(totals[player] or 0)+amount
 dirty[player]=true
end
function S.Flush()
 for player in dirty do
  dirty[player]=nil
  if player.Parent==Players then value(player).Value=math.floor((totals[player] or 0)+0.5) end
 end
end
function S.Reset()
 table.clear(dirty)
 for _,player in Players:GetPlayers() do totals[player]=0 value(player).Value=0 end
end
function S.Start()
 if started then return end
 started=true
 for _,player in Players:GetPlayers() do S.Register(player) end
 Players.PlayerAdded:Connect(S.Register)
 Players.PlayerRemoving:Connect(function(p) totals[p]=nil dirty[p]=nil end)
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt
  if elapsed>=0.2 then elapsed=0 S.Flush() end
 end)
end
return S
