--[[
 TrialMenuKit - the look shared by the trial (difficulty) and armory (class) pickers.
 Book-like and regal, in the HUD's Garamond: a letter-spaced overline and a serif title over a
 gold ornament, a row of tall plates to choose from, and a detail area built from gauges and
 short text rather than bullet walls. Long rule lists sit behind a ledger toggle.
 Used by BossClient.Presentation.DifficultyClient and BossClient.Players.ClassClient.
]]
local Tween=game:GetService("TweenService")
local K={}
K.W,K.H=1000,640
K.Colors=table.freeze({
 Gold=Color3.fromRGB(232,196,112),
 GoldDim=Color3.fromRGB(150,124,70),
 Ivory=Color3.fromRGB(240,232,212),
 Muted=Color3.fromRGB(172,162,142),
 Ink=Color3.fromRGB(12,10,8),
 Plate=Color3.fromRGB(30,26,21),
 PlateHi=Color3.fromRGB(46,39,30),
 Track=Color3.fromRGB(58,50,40),
})
local family=Font.fromEnum(Enum.Font.Garamond).Family
K.Fonts=table.freeze({
 Title=Font.new(family,Enum.FontWeight.Bold),
 Caps=Font.new(family,Enum.FontWeight.SemiBold),
 Body=Font.new(family,Enum.FontWeight.Regular),
 Italic=Font.new(family,Enum.FontWeight.Regular,Enum.FontStyle.Italic),
})
local QUICK=TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

 -- "TRIAL" -> "T R I A L": Roblox text has no letter spacing, so caps lines are spaced by hand
 -- (per UTF-8 character, so "·" and the like survive)
function K.Spaced(text)
 local out={}
 for _,code in utf8.codes(text:upper())do out[#out+1]=utf8.char(code)end
 return table.concat(out," ")
end
 -- Garamond Bold fuses repeated I's into a ligature; a zero-width non-joiner keeps "III" as three letters
function K.Numeral(text)
 return (text:gsub("I(I)","I\u{200C}%1"):gsub("I(I)","I\u{200C}%1"))
end

local function make(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props)do o[k]=v end
 o.Parent=parent
 return o
end
function K.Frame(parent,props)
 local f=make("Frame",parent,{BackgroundTransparency=1,BorderSizePixel=0})
 for k,v in pairs(props or{})do f[k]=v end
 return f
end
function K.Text(parent,props)
 local t=make("TextLabel",parent,{BackgroundTransparency=1,FontFace=K.Fonts.Body,TextColor3=K.Colors.Ivory,TextSize=16,
  TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top})
 for k,v in pairs(props)do t[k]=v end
 return t
end
local function fade(line,fromLeft)
 make("UIGradient",line,{Transparency=NumberSequence.new(fromLeft and 1 or 0,fromLeft and 0 or 1)})
end

 -- a gold hairline that fades out both ways, with a small diamond in the middle
function K.Ornament(parent,y,width)
 local holder=K.Frame(parent,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,y),Size=UDim2.fromOffset(width,12)})
 for _,side in ipairs({-1,1})do
  local line=K.Frame(holder,{AnchorPoint=Vector2.new(side<0 and 1 or 0,.5),Position=UDim2.new(.5,side*9,.5,0),
   Size=UDim2.new(.5,-12,0,1),BackgroundTransparency=0,BackgroundColor3=K.Colors.Gold})
  fade(line,side<0)
 end
 K.Frame(holder,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(7,7),Rotation=45,
  BackgroundTransparency=0,BackgroundColor3=K.Colors.Gold})
 return holder
end

 -- the full-screen sheet: a warm dark backdrop (click it to close) and a fixed-size stage that
function K.Screen(name,parent)
 local gui=make("ScreenGui",parent,{Name=name,ResetOnSpawn=false,DisplayOrder=90,IgnoreGuiInset=true,
  ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=false})
 local back=make("TextButton",gui,{Name="Backdrop",Text="",AutoButtonColor=false,Size=UDim2.fromScale(1,1),
  BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.06,BorderSizePixel=0})
 make("UIGradient",back,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(34,27,19),Color3.fromRGB(7,6,5))})
 local stage=K.Frame(back,{Name="Stage",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(K.W,K.H),Active=true})
 local scale=make("UIScale",stage,{})
  -- thin rules framing the stage top and bottom
 for _,y in ipairs({0,K.H})do
  local rule=K.Frame(stage,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,0,y),Size=UDim2.new(1,0,0,1),
   BackgroundTransparency=.55,BackgroundColor3=K.Colors.GoldDim})
  make("UIGradient",rule,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})})
 end
 local function resize()
  local cam=workspace.CurrentCamera
  if cam then scale.Scale=math.min(1.1,(cam.ViewportSize.X-32)/K.W,(cam.ViewportSize.Y-24)/K.H)end
 end
 local conn
 local function bind()
  if conn then conn:Disconnect()end
  if workspace.CurrentCamera then conn=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)end
  resize()
 end
 bind()
 workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
 return {Gui=gui,Backdrop=back,Stage=stage,Resize=resize}
end

 -- overline, title, ornament and an italic subtitle; returns the subtitle label
function K.Header(stage,overline,title)
 K.Text(stage,{Name="Overline",Text=K.Spaced(overline),FontFace=K.Fonts.Caps,TextSize=13,TextColor3=K.Colors.GoldDim,
  TextXAlignment=Enum.TextXAlignment.Center,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,22),Size=UDim2.fromOffset(700,16)})
 K.Text(stage,{Name="Title",Text=title,FontFace=K.Fonts.Title,TextSize=46,TextColor3=K.Colors.Ivory,
  TextXAlignment=Enum.TextXAlignment.Center,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,40),Size=UDim2.fromOffset(800,50)})
 K.Ornament(stage,94,440)
 return K.Text(stage,{Name="Subtitle",Text="",FontFace=K.Fonts.Italic,TextSize=16,TextColor3=K.Colors.Muted,
  TextXAlignment=Enum.TextXAlignment.Center,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,110),Size=UDim2.fromOffset(820,20)})
end

function K.Close(stage)
 local b=make("TextButton",stage,{Name="Close",Text="×",FontFace=K.Fonts.Body,TextSize=34,TextColor3=K.Colors.Muted,
  BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,14),Size=UDim2.fromOffset(40,40)})
 b.MouseEnter:Connect(function()b.TextColor3=K.Colors.Gold end)
 b.MouseLeave:Connect(function()b.TextColor3=K.Colors.Muted end)
 return b
end

 -- a tall plate to choose: an illuminated glyph, the name in caps, a short italic note and an
 -- accent bar; it lifts on hover and rises with a coloured frame when chosen
function K.Plate(parent,spec)
 local b=make("TextButton",parent,{Name=spec.Id,Text="",AutoButtonColor=false,Size=spec.Size,Position=spec.Position,
  BackgroundColor3=K.Colors.Plate,BorderSizePixel=0})
 make("UIGradient",b,{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(150,150,150))})
 local frame=make("UIStroke",b,{Color=K.Colors.GoldDim,Transparency=.6,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
 local inset=K.Frame(b,{Position=UDim2.fromOffset(5,5),Size=UDim2.new(1,-10,1,-10)})
 make("UIStroke",inset,{Color=spec.Color,Transparency=.82,Thickness=1})
 local badge=K.Text(b,{Text="",FontFace=K.Fonts.Caps,TextSize=11,TextColor3=spec.Color,TextXAlignment=Enum.TextXAlignment.Center,
  Position=UDim2.fromOffset(6,12),Size=UDim2.new(1,-12,0,14)})
 local glyph=K.Text(b,{Text=spec.Glyph,FontFace=K.Fonts.Title,TextSize=spec.GlyphSize or 52,TextColor3=spec.Color,
  TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,Position=UDim2.fromOffset(0,28),Size=UDim2.new(1,0,0,62)})
 local name=K.Text(b,{Text=spec.Name:upper(),FontFace=K.Fonts.Caps,TextSize=spec.NameSize or 17,TextColor3=K.Colors.Ivory,
  TextXAlignment=Enum.TextXAlignment.Center,Position=UDim2.fromOffset(6,98),Size=UDim2.new(1,-12,0,22)})
 K.Text(b,{Text=spec.Note or "",FontFace=K.Fonts.Italic,TextSize=14,TextColor3=K.Colors.Muted,TextXAlignment=Enum.TextXAlignment.Center,
  Position=UDim2.fromOffset(10,124),Size=UDim2.new(1,-20,0,40)})
 local bar=K.Frame(b,{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-12),Size=UDim2.new(.16,0,0,2),
  BackgroundTransparency=0,BackgroundColor3=spec.Color})
 local plate={Button=b,Glyph=glyph}
 local hover,active=false,false
 local function refresh()
  local lift=(active and -12 or 0)+(hover and -4 or 0)
  Tween:Create(b,QUICK,{Position=spec.Position+UDim2.fromOffset(0,lift),BackgroundColor3=(active or hover)and K.Colors.PlateHi or K.Colors.Plate}):Play()
  Tween:Create(bar,QUICK,{Size=UDim2.new(active and .72 or(hover and .32 or .16),0,0,active and 3 or 2)}):Play()
  frame.Color=active and spec.Color or K.Colors.GoldDim
  frame.Thickness=active and 2 or 1
  frame.Transparency=active and 0 or(hover and .25 or .6)
  name.TextColor3=active and spec.Color:Lerp(K.Colors.Ivory,.35)or K.Colors.Ivory
 end
 function plate:Set(isActive,badgeText)
  active=isActive
  badge.Text=badgeText and K.Spaced(badgeText)or""
  refresh()
 end
 b.MouseEnter:Connect(function()hover=true refresh()end)
 b.MouseLeave:Connect(function()hover=false refresh()end)
 refresh()
 return plate
end

 -- a labelled gauge: caps label, value on the right, a thin track with quarter ticks
function K.Gauge(parent,position,width,label)
 local holder=K.Frame(parent,{Position=position,Size=UDim2.fromOffset(width,32)})
 K.Text(holder,{Text=K.Spaced(label),FontFace=K.Fonts.Caps,TextSize=11,TextColor3=K.Colors.GoldDim,Size=UDim2.new(.7,0,0,14)})
 local value=K.Text(holder,{Text="",FontFace=K.Fonts.Title,TextSize=17,TextXAlignment=Enum.TextXAlignment.Right,
  AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,-2),Size=UDim2.new(.5,0,0,18)})
 local track=K.Frame(holder,{Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,0,4),BackgroundTransparency=0,BackgroundColor3=K.Colors.Track})
 local fill=K.Frame(track,{Size=UDim2.fromScale(0,1),BackgroundTransparency=0,BackgroundColor3=K.Colors.Gold})
 for i=1,3 do K.Frame(track,{Position=UDim2.new(i/4,0,0,-2),Size=UDim2.fromOffset(1,8),BackgroundTransparency=.3,BackgroundColor3=K.Colors.Ink})end
 return function(fraction,text,color)
  value.Text=text
  fill.BackgroundColor3=color or K.Colors.Gold
  Tween:Create(fill,QUICK,{Size=UDim2.fromScale(math.clamp(fraction,.03,1),1)}):Play()
 end
end

 -- a row of pips (lives and the like)
function K.Pips(parent,position,width,label,max)
 local holder=K.Frame(parent,{Position=position,Size=UDim2.fromOffset(width,32)})
 K.Text(holder,{Text=K.Spaced(label),FontFace=K.Fonts.Caps,TextSize=11,TextColor3=K.Colors.GoldDim,Size=UDim2.new(.7,0,0,14)})
 local value=K.Text(holder,{Text="",FontFace=K.Fonts.Title,TextSize=17,TextXAlignment=Enum.TextXAlignment.Right,
  AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,-2),Size=UDim2.new(.5,0,0,18)})
 local pips={}
 for i=1,max do pips[i]=K.Frame(holder,{Position=UDim2.fromOffset((i-1)*20,20),Size=UDim2.fromOffset(9,9),Rotation=45,BackgroundTransparency=0,BackgroundColor3=K.Colors.Track})end
 return function(count,text,color)
  value.Text=text
  for i,p in ipairs(pips)do p.BackgroundColor3=i<=count and(color or K.Colors.Gold)or K.Colors.Track end
 end
end

 -- a toggleable overlay sheet listing sections of lines (full rules): api.Fill(sections,color,title)
function K.Ledger(stage,title)
 local sheet=K.Frame(stage,{Name="Ledger",Visible=false,ZIndex=20,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,136),
  Size=UDim2.fromOffset(860,452),BackgroundTransparency=.02,BackgroundColor3=Color3.fromRGB(20,17,13)})
 make("UIStroke",sheet,{Color=K.Colors.GoldDim,Transparency=.3})
 local heading=K.Text(sheet,{Text=title,FontFace=K.Fonts.Title,TextSize=24,ZIndex=21,Position=UDim2.fromOffset(28,16),Size=UDim2.fromOffset(600,28)})
 local back=make("TextButton",sheet,{Text="Return  ›",FontFace=K.Fonts.Caps,TextSize=15,TextColor3=K.Colors.Gold,BackgroundTransparency=1,ZIndex=21,
  AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-24,0,18),Size=UDim2.fromOffset(120,24),TextXAlignment=Enum.TextXAlignment.Right})
 local scroll=make("ScrollingFrame",sheet,{ZIndex=21,Position=UDim2.fromOffset(28,56),Size=UDim2.new(1,-46,1,-72),BackgroundTransparency=1,BorderSizePixel=0,
  ScrollBarThickness=3,ScrollBarImageColor3=K.Colors.GoldDim,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
 make("UIListLayout",scroll,{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
 local api={Sheet=sheet,Back=back}
 function api.Fill(sections,color,titleText)
  heading.Text=titleText or title
  heading.TextColor3=color or K.Colors.Ivory
  for _,c in ipairs(scroll:GetChildren())do if c:IsA("TextLabel")then c:Destroy()end end
  local order=0
  local function line(text,font,size,col,top)
   order+=1
   local t=K.Text(scroll,{Text=text,FontFace=font,TextSize=size,TextColor3=col,ZIndex=22,LayoutOrder=order,
    Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y})
   if top then make("UIPadding",t,{PaddingTop=UDim.new(0,top)})end
  end
  for _,section in ipairs(sections)do
   if #section[2]>0 then
    line(K.Spaced(section[1]),K.Fonts.Caps,12,color or K.Colors.Gold,order>0 and 12 or 0)
    for _,text in ipairs(section[2])do line("—  "..text,K.Fonts.Body,15,K.Colors.Ivory)end
   end
  end
  scroll.CanvasPosition=Vector2.zero
 end
 back.Activated:Connect(function()sheet.Visible=false end)
 return api
end

return table.freeze(K)
