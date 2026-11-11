local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local api = {}
local defaults = setmetatable({}, { __mode = "k" })
local echoes = setmetatable({}, { __mode = "k" })
local function reset(label)
 local base = defaults[label]
 if not base then
  base = { Color = label.TextColor3, Rich = label.RichText, Wrapped = label.TextWrapped,
   Scaled = label.TextScaled, Z = label.ZIndex }
  defaults[label] = base
 end
 label.TextColor3, label.RichText = base.Color, base.Rich
 label.TextWrapped, label.TextScaled, label.ZIndex = base.Wrapped, base.Scaled, base.Z
 for _, echo in ipairs(echoes[label] or {}) do echo.Visible = false end
end
local function escape(text)
 return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end
local function format(text, shimmer)
 local styled = escape(text):gsub("%[%[(.-)%]%]", function(word)
  local tagged = "<b><i>[[" .. word .. "]]</i></b>"
  return shimmer and "<u>" .. tagged .. "</u>" or tagged
 end)
 return (styled:gsub("FANTASY", "<b><i>FANTASY</i></b>"):gsub("EYE", "<b><i>EYE</i></b>"))
end
local function getEchoes(label)
 local pair = echoes[label]
 if not pair then
  pair = {}
  for i = 1, 2 do
   local echo = label:Clone()
   echo.Name = "TrueIllusionLyricEcho" .. i
   echo.TextColor3 = Color3.new(1, 1, 1)
   echo.TextTransparency = 0.82
   echo.TextStrokeTransparency = 0.85
   echo.ZIndex = label.ZIndex - 1
   echo.Parent = label.Parent
   table.insert(pair, echo)
  end
  echoes[label] = pair
 end
 return pair
end
function api.Begin(label, text, duration, options)
 options = options or {}
 reset(label)
 if options.LyricSoundtrack and options.IllusionLyrics then
  local started = options.StartedAt or workspace:GetServerTimeNow()
  local age = math.max(0, workspace:GetServerTimeNow() - started)
  label.TextColor3 = Color3.new(1, 1, 1)
  label.RichText, label.TextWrapped, label.TextScaled = true, true, true
  label.ZIndex = defaults[label].Z + 2
  label.Text, label.MaxVisibleGraphemes, label.Visible = format(text, false), -1, age < (duration or 4)
  return { Label = label, Text = text, Lyric = true, Illusion = options.IllusionLyrics == true,
   Owner = options.Owner, Token = options.Token, ServerStart = started,
   Echoes = options.IllusionLyrics and getEchoes(label) or nil,
   Ends = os.clock() + math.max(0, (duration or 4) - age) }
 end
 local count = 0
 for _ in utf8.graphemes(text) do count += 1 end
 label.Text, label.MaxVisibleGraphemes, label.Visible = text, 0, true
 local began = os.clock()
 if options.LyricSoundtrack then
  local started = options.StartedAt or workspace:GetServerTimeNow()
  local age = math.max(0, workspace:GetServerTimeNow() - started)
  return { Label = label, Started = began - age, Count = count,
   Interval = math.min(Config.DialogueCharacterInterval, math.max(0.001, (duration or 4) * 0.8 / math.max(1, count))),
   Owner = options.Owner, Token = options.Token, TimedDialogue = true,
   Ends = began + math.max(0, (duration or 4) - age) }
 end
 return { Label = label, Started = began, Count = count, Interval = Config.DialogueCharacterInterval,
  Ends = began + math.max(duration or 4, count * Config.DialogueCharacterInterval + 0.8) }
end
function api.Step(record, now)
 if not record or not record.Label.Parent then return false end
 now = now or os.clock()
 if record.Lyric then
  local owner = record.Owner
  if now >= record.Ends or owner and (not owner.Parent or owner:GetAttribute("TrueIllusionToken") ~= record.Token or not owner:GetAttribute("TrueIllusionActive")) then
   record.Label.Visible = false
   for _, echo in ipairs(record.Echoes or {}) do echo.Visible = false end
   return false
  end
  if record.Illusion then
   local age = workspace:GetServerTimeNow() - record.ServerStart
   local beat = math.floor(age * 8)
   if record.EditBeat ~= beat then
    record.EditBeat = beat
    record.Label.Text = format(record.Text, beat % 8 == 0)
   end
   for i, echo in ipairs(record.Echoes) do
    echo.Text, echo.Visible = record.Label.Text, true
    local side = i == 1 and -1 or 1
    echo.Position = record.Label.Position + UDim2.fromOffset(side * (1.5 + math.sin(age * 7) * 0.8), math.sin(age * 5 + i) * 0.8)
   end
  end
  return true
 end
 if record.TimedDialogue and record.Owner and (not record.Owner.Parent
  or record.Owner:GetAttribute("TrueIllusionToken") ~= record.Token
  or not record.Owner:GetAttribute("TrueIllusionActive")) then
  record.Label.Visible = false
  return false
 end
 record.Label.MaxVisibleGraphemes = math.min(record.Count, math.floor((now - record.Started) / record.Interval))
 if now >= record.Ends then record.Label.Visible = false return false end
 return true
end
return api