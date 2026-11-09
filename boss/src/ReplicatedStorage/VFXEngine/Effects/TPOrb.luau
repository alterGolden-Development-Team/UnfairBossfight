--[[
 TPOrb (client effect) - the white orbs Phase 5 skills drop (Combat/TPService).
 Decorate: the orb arcs out of the boss to its landing spot, then hovers and bobs.
 Collect: a small white pop.  Expire: it fades with a soft puff.
 Kept deliberately quiet (a soft ball, a faint trail, a few motes) so it reads as a pickup
 and not as one of the boss's attacks.
]]
local O={}
local WHITE=Color3.new(1,1,1)
local PALE=Color3.fromRGB(215,230,255)

function O.Decorate(E,part)
 local g=E.Group("TPOrb")
 local from=part:GetAttribute("From")or part.Position
 local arm=part:GetAttribute("Arm")or .7
 local to=part.Position
 local a=E.Anchor(g,CFrame.new(from))
 local body={
  E.Sprite(a,{tex="glow.soft",size=4.5,alpha=.55,color=PALE,z=-.5},30),
  E.Sprite(a,{tex="orb.shaded",size=2.2,alpha=.05,color=WHITE,z=.3},30),
 }
 local motes=E.Stream(a,{tex="star.twinkle",size={{0,.6},{1,0}},life={.5,.8},speed={1,2},spread=180,color={{0,WHITE},{1,PALE}}},3)
 local t0a,t1a=E.Attach(a,CFrame.new(0,.6,0)),E.Attach(a,CFrame.new(0,-.6,0))
 local tr=Instance.new("Trail")
 tr.Attachment0,tr.Attachment1=t0a,t1a tr.Lifetime=.2 tr.LightEmission=1 tr.FaceCamera=true
 tr.Color=ColorSequence.new(WHITE,PALE)tr.Transparency=NumberSequence.new(.5,1)tr.WidthScale=NumberSequence.new(.6,0)tr.Parent=a
 E.Light(g,a,PALE,8,.7)
 local s0=os.clock()
 E.Step(g,function()
  local t=os.clock()-s0
  if not part.Parent then
   for _,b in ipairs(body)do b:Clear()end
   motes.Enabled=false tr.Enabled=false
   E.After(g,.8,function()g:Destroy()end)
   return false
  end
  if t<arm then
   local u=t/arm
   a.CFrame=CFrame.new(from:Lerp(to,u)+Vector3.yAxis*math.sin(math.pi*u)*14)
  else
   a.CFrame=CFrame.new(to+Vector3.yAxis*math.sin(t*2.6)*.6)
  end
 end)
end

function O.Collect(E,d)
 local g=E.Group("TPOrbCollect")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 E.Sprite(a,{tex="glow.soft",size={{0,3},{.3,8},{1,9}},alpha={{0,.2},{1,1}},color=WHITE},.25)
 E.Emit(a,{tex="star.twinkle",size={{0,.8},{1,0}},life={.4,.7},speed={6,12},spread=40,dir=Enum.NormalId.Top,drag=2,color={{0,WHITE},{1,PALE}}},6)
 E.Light(g,a,WHITE,10,1.5,.25)
 E.After(g,1.2,function()g:Destroy()end)
end

function O.Expire(E,d)
 local g=E.Group("TPOrbExpire")
 local a=E.Anchor(g,CFrame.new(d.Pos))
 E.Sprite(a,{tex="glow.soft",size={{0,6},{1,0}},alpha={{0,.3},{1,1}},color=PALE},.4)
 E.Emit(a,{tex="star.twinkle",size={{0,1},{1,0}},life={.4,.8},speed={2,6},spread=180,color={{0,WHITE},{1,PALE}}},8)
 E.After(g,1,function()g:Destroy()end)
end

return O
