 
 
 
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local identity = CFrame.identity
local JOINTS = { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }
local SHORT = { Root = "RootJoint", Neck = "Neck", RS = "Right Shoulder", LS = "Left Shoulder", RH = "Right Hip", LH = "Left Hip" }

 
local function P(t)
  local out = {}
  for k, v in pairs(t) do
    out[SHORT[k] or k] = v
  end
  return out
end
local REST = P({})

local function flipArm(a) return a and { a[1], -a[2], -a[3] } or nil end
local function mirrorDef(d)
  return { Root = flipArm(d.Root), Neck = flipArm(d.Neck), RS = flipArm(d.LS), LS = flipArm(d.RS), RH = d.LH, LH = d.RH }
end
local function TBK(frames, mirror)
  local out = table.create(#frames)
  for i, f in ipairs(frames) do
    out[i] = { f[1], f[2] == false and REST or P(mirror and mirrorDef(f[2]) or f[2]) }
  end
  return out
end

local TB_DIAG = {
  { 0, false },
  { 0.05, { Root = { 6, -34, 0 }, Neck = { 0, 20, 0 }, RS = { 128, -30, 32 }, LS = { 62, -6, 8 }, RH = { -8, 0, 0 }, LH = { 10, 0, 0 } } },
  { 0.10, { Root = { -6, 4, 0 }, Neck = { 0, 0, 0 }, RS = { 96, 8, 4 }, LS = { 62, -6, 8 }, RH = { 8, 0, 0 }, LH = { -6, 0, 0 } } },
  { 0.15, { Root = { -14, 42, 0 }, Neck = { 0, -26, 0 }, RS = { 60, 62, -26 }, LS = { 58, -8, 8 }, RH = { 26, 0, 0 }, LH = { -16, 0, 0 } } },
  { 0.24, { Root = { -12, 46, 0 }, Neck = { 0, -28, 0 }, RS = { 54, 68, -30 }, LS = { 58, -8, 8 }, RH = { 24, 0, 0 }, LH = { -14, 0, 0 } } },
  { 0.40, false },
}
local TB_SWEEP = {
  { 0, false },
  { 0.05, { Root = { 0, -54, 0 }, Neck = { 0, 32, 0 }, RS = { 92, -60, 22 }, LS = { 70, -12, 10 }, RH = { -8, 0, 0 }, LH = { 10, 0, 0 } } },
  { 0.10, { Root = { -4, 0, 0 }, Neck = { 0, 0, 0 }, RS = { 90, 0, 2 }, LS = { 68, -10, 10 }, RH = { 6, 0, 0 }, LH = { -4, 0, 0 } } },
  { 0.16, { Root = { -8, 58, 0 }, Neck = { 0, -34, 0 }, RS = { 86, 76, -16 }, LS = { 64, -6, 12 }, RH = { 24, 0, 0 }, LH = { -16, 0, 0 } } },
  { 0.25, { Root = { -8, 62, 0 }, Neck = { 0, -36, 0 }, RS = { 84, 82, -18 }, LS = { 64, -6, 12 }, RH = { 22, 0, 0 }, LH = { -14, 0, 0 } } },
  { 0.42, false },
}
local TB_RISE = {
  { 0, false },
  { 0.05, { Root = { -16, -30, 0 }, Neck = { 10, 18, 0 }, RS = { 36, -24, 34 }, LS = { 60, -6, 8 }, RH = { 12, 0, 0 }, LH = { -6, 0, 0 } } },
  { 0.10, { Root = { -4, 6, 0 }, Neck = { 0, 0, 0 }, RS = { 84, 14, 2 }, LS = { 62, -6, 8 }, RH = { 4, 0, 0 }, LH = { -2, 0, 0 } } },
  { 0.16, { Root = { 8, 38, 0 }, Neck = { -8, -22, 0 }, RS = { 152, 36, -10 }, LS = { 66, -6, 8 }, RH = { 22, 0, 0 }, LH = { -16, 0, 0 } } },
  { 0.25, { Root = { 10, 40, 0 }, Neck = { -8, -24, 0 }, RS = { 158, 38, -12 }, LS = { 66, -6, 8 }, RH = { 20, 0, 0 }, LH = { -14, 0, 0 } } },
  { 0.42, false },
}
local TB_FINISH = {
  { 0, false },
  { 0.06, { Root = { 10, 0, 0 }, Neck = { -8, 0, 0 }, RS = { 112, -38, 52 }, LS = { 112, 38, -52 }, RH = { -16, 0, 0 }, LH = { 12, 0, 0 } } },
  { 0.11, { Root = { -28, 0, 0 }, Neck = { 10, 0, 0 }, RS = { 74, 34, -34 }, LS = { 74, -34, 34 }, RH = { 36, 0, 0 }, LH = { -26, 0, 0 } } },
  { 0.16, { Root = { -32, 0, 0 }, Neck = { 12, 0, 0 }, RS = { 64, 50, -40 }, LS = { 64, -50, 40 }, RH = { 38, 0, 0 }, LH = { -28, 0, 0 } } },
  { 0.34, { Root = { -30, 0, 0 }, Neck = { 12, 0, 0 }, RS = { 62, 52, -42 }, LS = { 62, -52, 42 }, RH = { 36, 0, 0 }, LH = { -26, 0, 0 } } },
  { 0.60, false },
}
local WHIRL_POSE = { Root = { -6, 0, 0 }, Neck = { 0, 0, 0 }, RS = { 0, 0, 96 }, LS = { 0, 0, -96 }, RH = { 6, 0, 0 }, LH = { -6, 0, 0 } }
local TB_WHIRL = { { 0, false }, { 0.08, WHIRL_POSE }, { 1.42, WHIRL_POSE }, { 1.62, false } }

local SKY_TOP = { Root = { 4, 0, 0 }, Neck = { -10, 0, 0 }, RS = { 150, 36, -18 }, LS = { 150, -36, 18 }, RH = { 14, 0, 0 }, LH = { 6, 0, 0 } }
local SKY_DIVE = { Root = { -36, 0, 0 }, Neck = { 16, 0, 0 }, RS = { 28, 34, -28 }, LS = { 28, -34, 28 }, RH = { 22, 0, 0 }, LH = { -18, 0, 0 } }
local TB_SKYRISE = {
  { 0, false },
  { 0.06, { Root = { -26, 0, 0 }, Neck = { 14, 0, 0 }, RS = { 20, 0, 12 }, LS = { 20, 0, -12 }, RH = { 26, 0, 0 }, LH = { -14, 0, 0 } } },
  { 0.16, { Root = { 8, 0, 0 }, Neck = { -14, 0, 0 }, RS = { 172, 0, 44 }, LS = { 172, 0, -44 }, RH = { -18, 0, 0 }, LH = { -26, 0, 0 } } },
  { 0.34, { Root = { 6, 0, 0 }, Neck = { -10, 0, 0 }, RS = { 160, 30, -12 }, LS = { 160, -30, 12 }, RH = { -10, 0, 0 }, LH = { -22, 0, 0 } } },
  { 0.55, SKY_TOP },
  { 0.95, SKY_TOP },
}
local TB_SKYDIVE = { { 0, SKY_TOP }, { 0.06, SKY_DIVE }, { 0.60, SKY_DIVE } }
local TB_SKYLAND = {
  { 0, SKY_DIVE },
  { 0.05, { Root = { -42, 0, 0 }, Neck = { 26, 0, 0 }, RS = { 14, 42, -34 }, LS = { 14, -42, 34 }, RH = { 44, 0, 0 }, LH = { -38, 0, 0 } } },
  { 0.22, { Root = { -40, 0, 0 }, Neck = { 24, 0, 0 }, RS = { 16, 44, -34 }, LS = { 16, -44, 34 }, RH = { 44, 0, 0 }, LH = { -38, 0, 0 } } },
  { 0.44, { Root = { -10, 0, 0 }, Neck = { -6, 0, 0 }, RS = { 64, 0, 58 }, LS = { 64, 0, -58 }, RH = { 16, 0, 0 }, LH = { 6, 0, 0 } } },
  { 0.72, false },
}
local TB_SUMMON = {
  { 0, false },
  { 0.12, { Root = { -8, 0, 0 }, Neck = { 4, 0, 0 }, RS = { 82, 42, -30 }, LS = { 82, -42, 30 }, RH = { 10, 0, 0 }, LH = { -10, 0, 0 } } },
  { 0.28, { Root = { 12, 0, 0 }, Neck = { -20, 0, 0 }, RS = { 164, -10, 56 }, LS = { 164, 10, -56 }, RH = { -8, 0, 0 }, LH = { -14, 0, 0 } } },
  { 0.50, { Root = { 14, 0, 0 }, Neck = { -22, 0, 0 }, RS = { 168, -12, 60 }, LS = { 168, 12, -60 }, RH = { -8, 0, 0 }, LH = { -14, 0, 0 } } },
  { 0.66, { Root = { -4, 0, 0 }, Neck = { 0, 0, 0 }, RS = { 72, -8, 14 }, LS = { 72, 8, -14 } } },
  { 0.90, false },
}
local TB_RECOVER = { { 0, { RS = { 56, -6, 8 }, LS = { 56, 6, -8 } } }, { 0.2, false } }


 
local SKY_THROW = { Root = { 8, -24, 0 }, Neck = { -6, 18, 0 }, RS = { 104, 10, 8 }, LS = { 60, -20, 10 }, RH = { 10, 0, 0 }, LH = { -6, 0, 0 } }
local SKY_FLY = { Root = { -62, 0, 0 }, Neck = { 34, 0, 0 }, RS = { 118, 30, -20 }, LS = { 118, -30, 20 }, RH = { 18, 0, 0 }, LH = { -8, 0, 0 } }
local TB_SKYTHROW = { { 0, SKY_TOP }, { 0.07, SKY_THROW }, { 0.7, SKY_THROW } }
local TB_SKYFLY = { { 0, SKY_THROW }, { 0.08, SKY_FLY }, { 0.7, SKY_FLY } }

local ANIMS = {
  TB_Cut1 = TBK(TB_DIAG),
  TB_Cut2 = TBK(TB_DIAG, true),
  TB_Cut3 = TBK(TB_SWEEP),
  TB_Cut4 = TBK(TB_RISE, true),
  TB_Finish = TBK(TB_FINISH),
  TB_Whirl = TBK(TB_WHIRL),
  TB_SkyRise = TBK(TB_SKYRISE),
  TB_SkyDive = TBK(TB_SKYDIVE),
  TB_SkyLand = TBK(TB_SKYLAND),
  TB_Summon = TBK(TB_SUMMON),
  TB_Recover = TBK(TB_RECOVER),
  TB_SkyThrow = TBK(TB_SKYTHROW),
  TB_SkyFly = TBK(TB_SKYFLY),
  CounterStance = { Hold = P({ Root = { -4, -18, 0 }, Neck = { 4, 14, 0 }, RS = { 96, 10, -16 }, LS = { 84, 0, 40 }, RH = { 12, 0, 0 }, LH = { -10, 0, 0 } }) },
  TW_Counter = { { 0, P({ Root = { -4, -18, 0 }, RS = { 96, 10, -16 }, LS = { 84, 0, 40 } }) },
    { 0.06, P({ Root = { -12, 42, 0 }, RS = { 30, 58, -30 }, LS = { 60, 0, 20 }, RH = { 22, 0, 0 }, LH = { -16, 0, 0 } }) },
    { 0.13, P({ Root = { -16, -46, 0 }, RS = { 26, -44, 26 }, LS = { 40, 0, 20 }, RH = { -14, 0, 0 }, LH = { 26, 0, 0 } }) },
    { 0.3, P({ Root = { -12, -40, 0 }, RS = { 28, -38, 22 }, LS = { 40, 0, 20 } }) }, { 0.52, REST } },
  TruthCast = { Hold = P({ Root = { -8, -30, 0 }, Neck = { 6, 22, 0 }, LS = { 92, 26, 16 }, RS = { 22, 0, 30 }, RH = { 28, 0, 0 }, LH = { -22, 0, 0 } }), Shake = 0.7 },
  TW_Throw = { { 0, REST },
    { 0.07, P({ Root = { 6, 42, 0 }, Neck = { 0, -26, 0 }, LS = { 34, -30, -62 }, RS = { 46, 0, 18 }, RH = { -8, 0, 0 }, LH = { 12, 0, 0 } }) },
    { 0.13, P({ Root = { -20, -38, 0 }, Neck = { 6, 20, 0 }, LS = { 92, 24, 18 }, RS = { 20, 0, 34 }, RH = { 34, 0, 0 }, LH = { -26, 0, 0 } }) },
    { 0.3, P({ Root = { -16, -32, 0 }, LS = { 88, 20, 14 }, RS = { 22, 0, 30 }, RH = { 28, 0, 0 }, LH = { -22, 0, 0 } }) }, { 0.56, REST } },
  VowCharge = { Hold = P({ Root = { -14, 46, 0 }, Neck = { 6, -28, 0 }, RS = { 22, 58, -26 }, LS = { 86, 0, 30 }, RH = { 26, 0, 0 }, LH = { -20, 0, 0 } }), Shake = 0.9 },
  TW_VowRelease = { Blend = 0.02, { 0, P({ Root = { -14, 46, 0 }, RS = { 22, 58, -26 }, LS = { 86, 0, 30 }, RH = { 26, 0, 0 }, LH = { -20, 0, 0 } }) },
    { 0.05, P({ Root = { -34, -6, 0 }, RS = { 34, 0, 0 }, LS = { -30, 0, -28 }, RH = { 46, 0, 0 }, LH = { -38, 0, 0 } }) },
    { 0.11, P({ Root = { -34, -60, 0 }, Neck = { 10, 34, 0 }, RS = { 26, -44, 26 }, LS = { -36, 0, -28 }, RH = { 44, 0, 0 }, LH = { -38, 0, 0 } }) },
    { 0.5, P({ Root = { -30, -54, 0 }, Neck = { 10, 30, 0 }, RS = { 28, -40, 24 }, LS = { -30, 0, -26 }, RH = { 40, 0, 0 }, LH = { -34, 0, 0 } }) }, { 0.85, REST } },
  TW_LastCharge = { { 0, REST },
    { 0.22, P({ Root = { 4, 0, 0 }, Neck = { -10, 0, 0 }, RS = { 92, 0, -8 }, LS = { 58, 0, 38 }, RH = { 6, 0, 0 }, LH = { -4, 0, 0 } }) },
    { 0.82, P({ Root = { 7, 0, 0 }, Neck = { -18, 0, 0 }, RS = { 94, 0, -6 }, LS = { 60, 0, 40 }, RH = { 8, 0, 0 }, LH = { -6, 0, 0 } }) },
    { 1.12, P({ Root = { -24, 72, 0 }, Neck = { 10, -48, 0 }, RS = { 12, 74, -34 }, LS = { 74, 0, 34 }, RH = { 38, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 1.9, P({ Root = { -28, 78, 0 }, Neck = { 12, -52, 0 }, RS = { 10, 80, -36 }, LS = { 76, 0, 36 }, RH = { 42, 0, 0 }, LH = { -34, 0, 0 } }) } },
  TW_LastSpin = { Blend = 0.02, { 0, P({ Root = { -28, 40, 0 }, RS = { 6, 40, 40 }, LS = { 30, 0, -40 }, RH = { 42, 0, 0 }, LH = { -34, 0, 0 } }) },
    { 0.05, P({ Root = { -22, 0, 0 }, RS = { 6, 0, 96 }, LS = { 8, 0, -80 }, RH = { 40, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.34, P({ Root = { -22, 0, 0 }, RS = { 6, 0, 96 }, LS = { 8, 0, -80 }, RH = { 40, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.7, P({ Root = { -12, -18, 0 }, RS = { 24, -30, 40 }, LS = { 14, 0, -40 }, RH = { 18, 0, 0 }, LH = { -14, 0, 0 } }) }, { 1.0, REST } },
  TW_KingCharge = { { 0, REST },
    { 0.25, P({ Root = { 8, 0, 0 }, Neck = { -18, 0, 0 }, RS = { 150, 0, -22 }, LS = { 150, 0, 22 }, RH = { -6, 0, 0 }, LH = { 8, 0, 0 } }) },
    { 0.55, P({ Root = { 10, 0, 0 }, Neck = { -30, 0, 0 }, RS = { 176, 0, -18 }, LS = { 176, 0, 18 }, RH = { -8, 0, 0 }, LH = { 10, 0, 0 } }) },
    { 2.5, P({ Root = { 14, 0, 0 }, Neck = { -34, 0, 0 }, RS = { 180, 0, -18 }, LS = { 180, 0, 18 }, RH = { -10, 0, 0 }, LH = { 12, 0, 0 } }) } },
  TW_KingSwing = { Blend = 0.02, { 0, P({ Root = { 14, 0, 0 }, Neck = { -34, 0, 0 }, RS = { 180, 0, -18 }, LS = { 180, 0, 18 }, RH = { -10, 0, 0 }, LH = { 12, 0, 0 } }) },
    { 0.2, P({ Root = { 18, 0, 0 }, Neck = { -30, 0, 0 }, RS = { 186, 0, -16 }, LS = { 186, 0, 16 }, RH = { -12, 0, 0 }, LH = { 14, 0, 0 } }) },
    { 0.36, P({ Root = { -48, 0, 0 }, Neck = { 22, 0, 0 }, RS = { 52, 0, -22 }, LS = { 52, 0, 22 }, RH = { 58, 0, 0 }, LH = { -46, 0, 0 } }) },
    { 1.2, P({ Root = { -44, 0, 0 }, Neck = { 20, 0, 0 }, RS = { 48, 0, -22 }, LS = { 48, 0, 22 }, RH = { 54, 0, 0 }, LH = { -42, 0, 0 } }) }, { 1.6, REST } },
   
  Block = { Hold = P({ Root = { -6, 0, 0 }, RS = { 100, 0, -42 }, LS = { 100, 0, 42 }, Neck = { 8, 0, 0 }, RH = { 12, 0, 0 }, LH = { -10, 0, 0 } }) },
   
   
  SlashA = {
    { 0, REST },
    { 0.09, P({ Root = { -4, -46, 0 }, RS = { 34, -38, 58 }, LS = { 40, 0, 25 }, RH = { -6, 0, 0 }, LH = { 10, 0, 0 } }) },
    { 0.19, P({ Root = { -10, 44, 0 }, RS = { 34, 52, -30 }, LS = { 30, 0, 25 }, RH = { 24, 0, 0 }, LH = { -16, 0, 0 } }) },
    { 0.31, P({ Root = { -10, 48, 0 }, RS = { 34, 58, -34 }, LS = { 30, 0, 25 }, RH = { 22, 0, 0 }, LH = { -14, 0, 0 } }) },
    { 0.52, REST },
  },
  SlashB = {
    { 0, REST },
    { 0.09, P({ Root = { -4, 46, 0 }, RS = { 34, 62, -34 }, LS = { 40, 0, 25 }, RH = { 10, 0, 0 }, LH = { -6, 0, 0 } }) },
    { 0.19, P({ Root = { -10, -44, 0 }, RS = { 34, -38, 58 }, LS = { 30, 0, 25 }, RH = { -16, 0, 0 }, LH = { 24, 0, 0 } }) },
    { 0.31, P({ Root = { -10, -48, 0 }, RS = { 34, -44, 62 }, LS = { 30, 0, 25 }, RH = { -14, 0, 0 }, LH = { 22, 0, 0 } }) },
    { 0.52, REST },
  },
  XSlash = { { 0, REST }, { 0.16, P({ Root = { 12, 0, 0 }, RS = { 176, 0, 25 }, LS = { 125, 0, -30 }, Neck = { -16, 0, 0 }, RH = { -6, 0, 0 } }) },
    { 0.24, P({ Root = { -30, 0, 0 }, RS = { 22, 0, -52 }, LS = { 30, 0, -10 }, RH = { 38, 0, 0 }, LH = { -28, 0, 0 } }) },
    { 0.38, P({ Root = { -22, 0, 0 }, RS = { 12, 0, -62 }, RH = { 32, 0, 0 }, LH = { -24, 0, 0 } }) }, { 0.72, REST } },
   
  SwiftA = {
    { 0, REST },
    { 0.07, P({ Root = { 2, 34, 0 }, RS = { 32, 34, -30 }, LS = { -40, 0, -20 }, RH = { -8, 0, 0 }, LH = { 8, 0, 0 } }) },
    { 0.12, P({ Root = { -4, 0, 0 }, RS = { 30, 0, -2 } }) },
    { 0.18, P({ Root = { -8, -36, 0 }, RS = { 24, -30, 22 }, RH = { 10, 0, 0 }, LH = { -10, 0, 0 } }) },
    { 0.3, P({ Root = { -5, -30, 0 }, RS = { 26, -24, 20 } }) },
    { 0.46, REST },
  },
  SwiftB = {
    { 0, REST },
    { 0.07, P({ Root = { 2, -34, 0 }, RS = { 32, -34, 22 }, LS = { -40, 0, -20 }, RH = { 8, 0, 0 }, LH = { -8, 0, 0 } }) },
    { 0.12, P({ Root = { -4, 0, 0 }, RS = { 30, 0, 2 } }) },
    { 0.18, P({ Root = { -8, 36, 0 }, RS = { 24, 30, -22 }, RH = { -10, 0, 0 }, LH = { 10, 0, 0 } }) },
    { 0.3, P({ Root = { -5, 30, 0 }, RS = { 26, 24, -20 } }) },
    { 0.46, REST },
  },
  Flash = {
    { 0, P({ Root = { -6, 14, 0 }, RS = { 30, 20, -8 } }) },
    { 0.03, P({ Root = { -18, 34, 0 }, RS = { 34, 30, -22 }, LS = { -50, 0, -25 }, RH = { 30, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.07, P({ Root = { -36, -10, 0 }, RS = { 52, -6, 6 }, LS = { -55, 0, -28 }, RH = { 46, 0, 0 }, LH = { -40, 0, 0 } }) },
    { 0.15, P({ Root = { -26, -46, 0 }, RS = { 26, -34, 20 }, LS = { -45, 0, -25 }, RH = { 40, 0, 0 }, LH = { -34, 0, 0 } }) },
    { 0.42, P({ Root = { -22, -42, 0 }, RS = { 28, -30, 18 }, RH = { 34, 0, 0 }, LH = { -28, 0, 0 } }) },
    { 0.64, REST },
  },
  FlashB = {
    { 0, P({ Root = { -6, -14, 0 }, RS = { 30, -20, 10 } }) },
    { 0.03, P({ Root = { -18, -34, 0 }, RS = { 34, -30, 24 }, LS = { -50, 0, -25 }, RH = { -30, 0, 0 }, LH = { 30, 0, 0 } }) },
    { 0.07, P({ Root = { -36, 10, 0 }, RS = { 52, 6, 6 }, LS = { -55, 0, -28 }, RH = { -40, 0, 0 }, LH = { 46, 0, 0 } }) },
    { 0.15, P({ Root = { -26, 46, 0 }, RS = { 26, 34, -20 }, LS = { -45, 0, -25 }, RH = { -34, 0, 0 }, LH = { 40, 0, 0 } }) },
    { 0.42, P({ Root = { -22, 42, 0 }, RS = { 28, 30, -18 }, RH = { -28, 0, 0 }, LH = { 34, 0, 0 } }) },
    { 0.64, REST },
  },
  PhaseA = {
    { 0, P({ Root = { -14, 30, 0 }, RS = { 30, 34, -24 }, LS = { -45, 0, -20 }, RH = { 28, 0, 0 }, LH = { -24, 0, 0 } }) },
    { 0.08, P({ Root = { -24, -8, 0 }, RS = { 40, -6, 8 }, LS = { -50, 0, -24 }, RH = { 38, 0, 0 }, LH = { -32, 0, 0 } }) },
    { 0.15, P({ Root = { -26, -46, 0 }, RS = { 28, -44, 20 }, RH = { 40, 0, 0 }, LH = { -34, 0, 0 } }) },
    { 0.3, P({ Root = { -14, -30, 0 }, RS = { 28, -30, 18 } }) },
    { 0.5, REST },
  },
  PhaseB = {
    { 0, P({ Root = { -14, -30, 0 }, RS = { 30, -34, 24 }, LS = { -45, 0, -20 }, RH = { -24, 0, 0 }, LH = { 28, 0, 0 } }) },
    { 0.08, P({ Root = { -24, 8, 0 }, RS = { 40, 6, 8 }, LS = { -50, 0, -24 }, RH = { -32, 0, 0 }, LH = { 38, 0, 0 } }) },
    { 0.15, P({ Root = { -26, 46, 0 }, RS = { 28, 44, -20 }, RH = { -34, 0, 0 }, LH = { 40, 0, 0 } }) },
    { 0.3, P({ Root = { -14, 30, 0 }, RS = { 28, 30, -18 } }) },
    { 0.5, REST },
  },
  PhaseSlash = {
    { 0, P({ Root = { -12, 44, 0 }, RS = { 20, 56, -22 }, LS = { 70, 0, -35 }, RH = { 28, 0, 0 }, LH = { -22, 0, 0 } }) },
    { 0.07, P({ Root = { -30, 0, 0 }, RS = { 34, 0, 0 }, LS = { -45, 0, -25 }, RH = { 44, 0, 0 }, LH = { -36, 0, 0 } }) },
    { 0.15, P({ Root = { -30, -54, 0 }, RS = { 24, -36, 22 }, LS = { -40, 0, -22 }, RH = { 42, 0, 0 }, LH = { -36, 0, 0 } }) },
    { 0.4, P({ Root = { -24, -48, 0 }, RS = { 26, -32, 20 }, RH = { 36, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.75, REST },
  },
  PhaseCharge = { Hold = P({ Root = { -12, 44, 0 }, RS = { 20, 56, -22 }, LS = { 70, 0, -35 }, RH = { 28, 0, 0 }, LH = { -22, 0, 0 }, Neck = { 4, -18, 0 } }), Shake = 0.6 },
  WaltzCharge = { Hold = P({ Root = { -4, -22, 0 }, RS = { 92, 0, -8 }, LS = { -30, 0, -14 }, RH = { 20, 0, 0 }, LH = { -14, 0, 0 }, Neck = { -8, 18, 0 } }), Shake = 0.9 },
  WaltzRush = {
    { 0, REST },
    { 0.08, P({ Root = { -34, 0, 0 }, RS = { 46, 0, 4 }, LS = { -45, 0, -25 }, RH = { 50, 0, 0 }, LH = { -40, 0, 0 } }) },
    { 0.45, REST },
  },
  WaltzCutA = {
    { 0, P({ Root = { 0, 30, 0 }, RS = { 30, 30, -26 } }) },
    { 0.04, P({ Root = { -4, 0, 0 }, RS = { 28, 0, 0 } }) },
    { 0.09, P({ Root = { -8, -34, 0 }, RS = { 24, -28, 20 } }) },
    { 0.2, P({ Root = { -5, -28, 0 }, RS = { 26, -22, 18 } }) },
    { 0.3, REST },
  },
  WaltzCutB = {
    { 0, P({ Root = { 0, -30, 0 }, RS = { 30, -30, 20 } }) },
    { 0.04, P({ Root = { -4, 0, 0 }, RS = { 28, 0, 0 } }) },
    { 0.09, P({ Root = { -8, 34, 0 }, RS = { 24, 28, -20 } }) },
    { 0.2, P({ Root = { -5, 28, 0 }, RS = { 26, 22, -18 } }) },
    { 0.3, REST },
  },
  WaltzCutC = {
    { 0, P({ Root = { 10, 0, 0 }, RS = { 165, 0, 8 }, LS = { -60, 0, -20 }, Neck = { -14, 0, 0 } }) },
    { 0.05, P({ Root = { -32, 0, 0 }, RS = { 20, 0, -4 }, LS = { -50, 0, -22 }, RH = { 42, 0, 0 }, LH = { -34, 0, 0 }, Neck = { 8, 0, 0 } }) },
    { 0.2, P({ Root = { -26, 0, 0 }, RS = { 22, 0, -4 }, RH = { 36, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.32, REST },
  },
  WaltzCutD = {
    { 0, P({ Root = { -26, 0, 0 }, RS = { -28, 0, 8 }, LS = { -50, 0, -22 }, RH = { 44, 0, 0 }, LH = { -34, 0, 0 } }) },
    { 0.05, P({ Root = { 8, 0, 0 }, RS = { 150, 0, 4 }, LS = { -30, 0, -14 }, RH = { -8, 0, 0 }, LH = { 10, 0, 0 }, Neck = { -10, 0, 0 } }) },
    { 0.2, P({ Root = { 6, 0, 0 }, RS = { 142, 0, 4 } }) },
    { 0.32, REST },
  },
  WaltzFinish = {
    { 0, P({ Root = { 0, 0, 0 }, RS = { 100, 0, -6 }, LS = { -30, 0, -14 } }) },
    { 0.12, P({ Root = { 14, 0, 0 }, RS = { 172, 0, 8 }, LS = { 150, 0, -20 }, RH = { -10, 0, 0 }, LH = { 10, 0, 0 }, Neck = { -22, 0, 0 } }) },
    { 0.22, P({ Root = { 14, 0, 0 }, RS = { 175, 0, 8 }, LS = { 150, 0, -20 }, Neck = { -22, 0, 0 } }) },
    { 0.3, P({ Root = { -44, 0, 0 }, RS = { 14, 0, -2 }, LS = { 40, 0, -20 }, RH = { 56, 0, 0 }, LH = { -46, 0, 0 }, Neck = { 14, 0, 0 } }) },
    { 0.62, P({ Root = { -40, 0, 0 }, RS = { 16, 0, -2 }, LS = { 36, 0, -20 }, RH = { 52, 0, 0 }, LH = { -42, 0, 0 }, Neck = { 12, 0, 0 } }) },
    { 1.05, REST },
  },
  Lunge = { { 0, REST }, { 0.06, P({ Root = { -10, 30, 0 }, RS = { 40, 0, 40 }, RH = { -10, 0, 0 } }) }, { 0.12, P({ Root = { -34, -10, 0 }, RS = { 20, 0, -5 }, LS = { -50, 0, -25 }, RH = { 60, 0, 0 }, LH = { -45, 0, 0 } }) }, { 0.36, P({ Root = { -26, -10, 0 }, RS = { 22, 0, -5 }, RH = { 48, 0, 0 }, LH = { -38, 0, 0 } }) }, { 0.55, REST } },
  RiposteStance = { Hold = P({ Root = { -6, -20, 0 }, RS = { 120, 0, -55 }, LS = { -20, 0, -25 }, RH = { 15, 0, 0 }, LH = { -12, 0, 0 } }) },
  RiposteStrike = { { 0, P({ RS = { 120, 0, -55 } }) }, { 0.07, P({ Root = { -14, 40, 0 }, RS = { 80, 0, 80 }, RH = { 30, 0, 0 } }) }, { 0.2, P({ Root = { -10, 50, 0 }, RS = { 60, 0, 90 } }) }, { 0.5, REST } },
  Chop = {
    { 0, REST },
    { 0.16, P({ Root = { 16, 0, 0 }, RS = { 140, 0, 12 }, LS = { 75, 0, -30 }, Neck = { -14, 0, 0 }, RH = { -12, 0, 0 }, LH = { 10, 0, 0 } }) },
    { 0.23, P({ Root = { -40, 0, 0 }, RS = { 18, 0, -6 }, LS = { -25, 0, -30 }, Neck = { 22, 0, 0 }, RH = { 48, 0, 0 }, LH = { -34, 0, 0 } }) },
    { 0.42, P({ Root = { -36, 0, 0 }, RS = { 20, 0, -6 }, LS = { -20, 0, -30 }, Neck = { 18, 0, 0 }, RH = { 44, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.74, REST },
  },
  Stance = { { 0, REST }, { 0.12, P({ RS = { 150, 0, 42 }, Root = { 0, 15, 0 } }) }, { 0.26, P({ RS = { 28, 0, 10 }, LS = { 75, 0, -20 } }) }, { 0.46, REST } },
   
  Slam = { Hold = P({ Root = { -26, 0, 0 }, LS = { 92, 0, 74 }, RS = { 16, 0, 26 }, Neck = { 18, 0, 0 }, RH = { 32, 0, 0 }, LH = { -30, 0, 0 } }), Stride = 44, StrideRate = 22 },
   
  ShieldSlam = {
    { 0, REST },
    { 0.07, P({ Root = { 2, 30, 0 }, LS = { 62, 0, 62 }, RS = { 40, 0, 30 }, RH = { -6, 0, 0 }, LH = { 8, 0, 0 } }) },
    { 0.13, P({ Root = { -30, -34, 0 }, LS = { 95, 0, 78 }, RS = { 24, 0, 34 }, Neck = { 14, 0, 0 }, RH = { -34, 0, 0 }, LH = { 46, 0, 0 } }) },
    { 0.36, P({ Root = { -26, -30, 0 }, LS = { 95, 0, 78 }, RS = { 24, 0, 34 }, Neck = { 12, 0, 0 }, RH = { -30, 0, 0 }, LH = { 42, 0, 0 } }) },
    { 0.62, REST },
  },
   
  Conclusion = { Blend = 0.02,
    { 0, REST },
    { 0.03, P({ Root = { -38, -34, 0 }, RS = { 30, -38, 58 }, LS = { -40, 0, -22 }, Neck = { 22, 0, 0 }, RH = { 62, 0, 0 }, LH = { -50, 0, 0 } }) },
    { 0.12, P({ Root = { -38, -34, 0 }, RS = { 30, -38, 58 }, LS = { -40, 0, -22 }, Neck = { 22, 0, 0 }, RH = { 62, 0, 0 }, LH = { -50, 0, 0 } }) },
    { 0.18, P({ Root = { -22, 40, 0 }, RS = { 34, 52, -30 }, LS = { -30, 0, -30 }, Neck = { 10, 0, 0 }, RH = { 34, 0, 0 }, LH = { -38, 0, 0 } }) },
    { 0.36, P({ Root = { -20, 46, 0 }, RS = { 34, 58, -34 }, LS = { -30, 0, -30 }, Neck = { 10, 0, 0 }, RH = { 30, 0, 0 }, LH = { -34, 0, 0 } }) },
    { 0.6, REST },
  },
   
  Parry = { Hold = P({ Root = { -4, 22, 0 }, RS = { 86, 24, -16 }, LS = { 52, 0, 42 }, Neck = { 4, -12, 0 }, RH = { 10, 0, 0 }, LH = { -8, 0, 0 } }) },
   
  ParrySuccess = {
    { 0, P({ Root = { -4, 22, 0 }, RS = { 86, 24, -16 }, LS = { 52, 0, 42 }, Neck = { 4, -12, 0 }, RH = { 10, 0, 0 }, LH = { -8, 0, 0 } }) },
    { 0.1, P({ Root = { -10, -44, 0 }, RS = { 34, -38, 58 }, LS = { 30, 0, 25 }, RH = { -16, 0, 0 }, LH = { 24, 0, 0 } }) },
    { 0.24, P({ Root = { -10, -48, 0 }, RS = { 34, -44, 62 }, LS = { 30, 0, 25 }, RH = { -14, 0, 0 }, LH = { 22, 0, 0 } }) },
    { 0.5, REST },
  },
   
  Cast = { { 0, REST }, { 0.08, P({ Root = { 0, 22, 0 }, RS = { 118, 0, 22 }, LS = { 40, 0, -32 }, Neck = { -6, 0, 0 } }) },
    { 0.15, P({ Root = { -10, -14, 0 }, RS = { 12, 0, -4 }, LS = { 30, 0, -22 }, RH = { 18, 0, 0 }, LH = { -12, 0, 0 } }) },
    { 0.32, P({ Root = { -6, -10, 0 }, RS = { 18, 0, -4 }, LS = { 25, 0, -20 } }) }, { 0.58, REST } },
  OrbDash = { { 0, P({ Root = { -32, 0, 0 }, RS = { -40, 0, 20 }, LS = { -45, 0, -25 }, RH = { 42, 0, 0 }, LH = { -36, 0, 0 } }) }, { 0.32, P({ Root = { -22, 0, 0 }, RS = { -25, 0, 20 }, LS = { -30, 0, -25 } }) }, { 0.6, REST } },
  Bombard = { { 0, REST }, { 0.14, P({ Root = { 12, 0, 0 }, RS = { 178, 0, 10 }, LS = { 150, 0, -30 }, Neck = { -22, 0, 0 } }) },
    { 0.24, P({ Root = { -28, 0, 0 }, RS = { -12, 0, 6 }, LS = { 20, 0, -20 }, RH = { 30, 0, 0 }, LH = { -24, 0, 0 } }) }, { 0.38, P({ Root = { -24, 0, 0 }, RS = { -8, 0, 6 } }) }, { 0.72, REST } },
  Summon = { { 0, REST }, { 0.2, P({ Root = { 10, 0, 0 }, RS = { 175, 0, 12 }, LS = { 95, 0, -80 }, Neck = { -18, 0, 0 } }) }, { 0.65, P({ RS = { 170, 0, 15 }, LS = { 100, 0, -70 } }) }, { 0.95, REST } },
  CloneCharge = { Hold = P({ Root = { 6, 0, 0 }, RS = { 160, 0, 12 }, LS = { 95, 0, -70 }, Neck = { -12, 0, 0 } }), Shake = 1 },
  LaserCharge = { Hold = P({ Root = { -8, 0, 0 }, RS = { 14, 0, 0 }, LS = { 58, 0, -42 }, RH = { 16, 0, 0 }, LH = { -16, 0, 0 } }), Shake = 2.5 },
  LaserFire = { Hold = P({ Root = { -16, 0, 0 }, RS = { 10, 0, 0 }, LS = { 62, 0, -46 }, RH = { 26, 0, 0 }, LH = { -26, 0, 0 } }), Shake = 1.2 },
   

  Bash = { { 0, REST },
    { 0.07, P({ Root = { 5, 30, 0 }, Neck = { 4, 0, 0 }, LS = { 28, 0, -42 }, RS = { 72, 0, 14 }, RH = { -14, 0, 0 }, LH = { 16, 0, 0 } }) },
    { 0.13, P({ Root = { -26, -26, 0 }, Neck = { 9, 0, 0 }, LS = { 92, 0, 8 }, RS = { 6, 0, 30 }, RH = { 50, 0, 0 }, LH = { -38, 0, 0 } }) },
    { 0.20, P({ Root = { -31, -29, 0 }, Neck = { 11, 0, 0 }, LS = { 97, 0, 13 }, RS = { -4, 0, 34 }, RH = { 52, 0, 0 }, LH = { -40, 0, 0 } }) },
    { 0.32, P({ Root = { -22, -18, 0 }, Neck = { 7, 0, 0 }, LS = { 88, 0, 6 }, RS = { 14, 0, 24 }, RH = { 40, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.46, P({ Root = { -8, -6, 0 }, LS = { 66, 0, 32 }, RS = { 46, 0, 12 }, RH = { 14, 0, 0 }, LH = { -10, 0, 0 } }) },
    { 0.62, REST } },

  Defender = { Hold = P({ Root = { -18, -14, 0 }, Neck = { 8, 0, 0 }, LS = { 88, 0, 58 }, RS = { 64, 0, -14 }, RH = { 28, 0, 14 }, LH = { 28, 0, -14 } }) },

  Release = { { 0, REST },
    { 0.06, P({ Root = { 10, 0, 0 }, Neck = { -14, 0, 0 }, LS = { 138, 0, 22 }, RS = { 112, 0, 8 }, RH = { -6, 0, 0 }, LH = { 8, 0, 0 } }) },
    { 0.12, P({ Root = { -36, 0, 0 }, Neck = { 14, 0, 0 }, LS = { 42, 0, 24 }, RS = { 40, 0, 12 }, RH = { 40, 0, 0 }, LH = { -32, 0, 0 } }) },
    { 0.24, P({ Root = { -40, 0, 0 }, Neck = { 16, 0, 0 }, LS = { 38, 0, 26 }, RS = { 36, 0, 14 }, RH = { 42, 0, 0 }, LH = { -34, 0, 0 } }) },
    { 0.48, P({ Root = { -10, 0, 0 }, LS = { 62, 0, 34 }, RS = { 46, 0, 12 }, RH = { 12, 0, 0 }, LH = { -8, 0, 0 } }) },
    { 0.66, REST } },

  Rampage = { Hold = P({ Root = { -38, -14, 0 }, Neck = { 10, 0, 0 }, LS = { 92, 0, 54 }, RS = { 12, 0, 34 }, RH = { 50, 0, 0 }, LH = { -44, 0, 0 } }) },

  Almighty = { { 0, REST },
    { 0.12, P({ Root = { 14, -6, 0 }, Neck = { -6, 0, 0 }, LS = { 50, 0, 30 }, RS = { 40, 0, 22 }, RH = { -8, 0, 0 }, LH = { 10, 0, 0 } }) },
    { 0.22, P({ Root = { 12, 0, 0 }, Neck = { -26, 0, 0 }, LS = { 80, 0, 36 }, RS = { 118, 0, 6 }, RH = { -6, 0, 0 }, LH = { 10, 0, 0 } }) },
    { 0.34, P({ Root = { 14, 0, 0 }, Neck = { -30, 0, 0 }, LS = { 82, 0, 38 }, RS = { 122, 0, 8 }, RH = { -6, 0, 0 }, LH = { 10, 0, 0 } }) },
    { 0.46, P({ Root = { -26, -10, 0 }, Neck = { 10, 0, 0 }, LS = { 96, 0, 28 }, RS = { 22, 0, 8 }, RH = { 36, 0, 0 }, LH = { -28, 0, 0 } }) },
    { 0.56, P({ Root = { -30, -12, 0 }, Neck = { 12, 0, 0 }, LS = { 98, 0, 26 }, RS = { 14, 0, 12 }, RH = { 38, 0, 0 }, LH = { -30, 0, 0 } }) },
    { 0.72, P({ Root = { -12, -4, 0 }, LS = { 70, 0, 34 }, RS = { 40, 0, 12 }, RH = { 14, 0, 0 }, LH = { -10, 0, 0 } }) },
    { 1.0, REST } },
   
  Sweep = { { 0, REST }, { 0.09, P({ Root = { 0, 32, 0 }, RS = { 105, 0, 62 }, LS = { 30, 0, -25 } }) },
    { 0.19, P({ Root = { -8, -32, 0 }, RS = { 30, 0, -52 }, RH = { 18, 0, 0 } }) }, { 0.28, P({ Root = { -6, -40, 0 }, RS = { 22, 0, -62 } }) }, { 0.52, REST } },
  Heal = { { 0, REST }, { 0.12, P({ Root = { 4, 0, 0 }, RS = { 18, 0, 0 }, LS = { 80, 0, -20 }, Neck = { -6, 0, 0 } }) }, { 0.5, P({ RS = { 22, 0, 0 }, LS = { 75, 0, -22 } }) }, { 0.78, REST } },
  Chain = { { 0, REST }, { 0.15, P({ Root = { -8, 0, 0 }, RS = { 16, 0, 0 }, LS = { 92, 0, -18 } }) }, { 0.5, P({ RS = { 20, 0, 0 }, LS = { 88, 0, -22 } }) }, { 0.8, REST } },
  SecondWind = { { 0, REST }, { 0.25, P({ Root = { 12, 0, 0 }, RS = { 178, 0, 8 }, LS = { 175, 0, -28 }, Neck = { -28, 0, 0 } }) }, { 0.9, P({ RS = { 172, 0, 8 }, LS = { 168, 0, -30 } }) }, { 1.2, REST } },
   
  Shoot = { { 0, REST }, { 0.04, P({ Root = { 0, -24, 0 }, Neck = { 0, 20, 0 }, RS = { 92, 0, -24 }, LS = { 14, 0, -14 } }) },
    { 0.08, P({ Root = { 2, -24, 0 }, Neck = { -5, 20, 0 }, RS = { 112, 0, -24 } }) },
    { 0.2, P({ Root = { 0, -24, 0 }, Neck = { 0, 20, 0 }, RS = { 92, 0, -24 } }) }, { 0.5, REST } },
  Roll = { { 0, REST }, { 0.12, P({ LS = { 40, 0, -10 } }) }, { 0.25, P({ Root = { 6, 0, 0 }, LS = { 160, 0, -10 }, Neck = { -25, 0, 0 } }) }, { 1.4, P({ LS = { 120, 0, -15 }, Neck = { -20, 0, 0 } }) }, { 1.7, REST } },
  Twirl = { { 0, REST }, { 0.15, P({ RS = { 140, 30, 10 } }) }, { 0.3, P({ RS = { 140, -60, 10 } }) }, { 0.45, P({ RS = { 140, 120, 10 } }) }, { 0.6, P({ RS = { 92, 0, 0 } }) }, { 0.85, REST } },
  Jackpot = { { 0, REST }, { 0.2, P({ Root = { 12, 0, 0 }, RS = { 175, 0, 40 }, LS = { 175, 0, -40 }, Neck = { -25, 0, 0 } }) }, { 0.5, P({ RS = { 160, 0, 55 }, LS = { 160, 0, -55 } }) },
    { 0.8, P({ RS = { 175, 0, 40 }, LS = { 175, 0, -40 } }) }, { 1.2, REST } },
  Bankrupt = { { 0, REST }, { 0.3, P({ Root = { -35, 0, 0 }, RS = { -10, 0, 8 }, LS = { -10, 0, -8 }, Neck = { 35, 0, 0 } }) }, { 1.2, P({ Root = { -30, 0, 0 }, Neck = { 30, 0, 0 } }) }, { 1.6, REST } },
}
 
local IDLES = {
  Warrior = P({ Root = { -3, -12, 0 }, Neck = { 2, 10, 0 }, RS = { 56, -16, 10 }, LS = { 74, 0, 62 }, RH = { 10, 0, 0 }, LH = { -8, 0, 0 } }),  
  Mage = P({ RS = { 72, 0, 8 }, LS = { 8, 0, -10 } }),
  Tank = P({ Root = { -2, -8, 0 }, Neck = { 2, 6, 0 }, LS = { 88, 0, 58 }, RS = { 52, -10, 8 }, RH = { 8, 0, 0 }, LH = { -6, 0, 0 } }),
  Twinblade = P({ RS = { 58, -6, 8 }, LS = { 58, 6, -8 } }),  
  Supporter = P({ RS = { 70, 0, 6 }, LS = { 10, 0, -8 } }),
  -- holding: revolver at the low ready, angled ahead of the feet; aiming (after a shot, see GAMBLER_AIM) swaps in smoothly
  Gambler = P({ Root = { 0, -8, 0 }, Neck = { 0, 6, 0 }, RS = { 46, -10, 4 }, LS = { 14, 0, -10 }, RH = { 6, 0, 0 }, LH = { -4, 0, 0 } }),
  TrueWarrior = P({ Root = { -4, -10, 0 }, Neck = { 2, 8, 0 }, RS = { 70, -12, 10 }, LS = { 60, 0, 38 }, RH = { 10, 0, 0 }, LH = { -8, 0, 0 } }),
  Duelist = P({ RS = { 32, 0, 14 }, LS = { -28, 0, -12 } }),  
}
 
-- Gambler aim: bladed stance, gun arm straight at the target, head down the sights. Held for AIM_HOLD seconds after each shot.
-- (RS z -24 swings the arm back across the 24 deg body turn, so the barrel points straight down the look vector)
local GAMBLER_AIM = P({ Root = { 0, -24, 0 }, Neck = { 0, 20, 0 }, RS = { 90, 0, -24 }, LS = { 12, 0, -14 }, RH = { 8, 0, 0 }, LH = { -6, 0, 0 } })
local AIM_HOLD = 1.4
local function blendPose(a, b, k)
  if k <= 0 then return a end
  if k >= 1 then return b end
  local out = {}
  for name, v in pairs(a) do
    local w = b[name] or { 0, 0, 0 }
    out[name] = { v[1] + (w[1] - v[1]) * k, v[2] + (w[2] - v[2]) * k, v[3] + (w[3] - v[3]) * k }
  end
  for name, w in pairs(b) do
    if not out[name] then
      out[name] = { w[1] * k, w[2] * k, w[3] * k }
    end
  end
  return out
end

local HOLDS = {
  { "TankDefenderHeld", "Defender" }, { "ClassStatus_Rampage", "Rampage" }, { "ClassStatus_ShieldRaised", "Slam" },
  { "ClassStatus_ParryStance", "Parry" }, { "MageLasering", "LaserFire" }, { "ClassStatus_LaserCharge", "LaserCharge" },
  { "ClassStatus_WaltzCharge", "WaltzCharge" }, { "ClassStatus_PhaseCharge", "PhaseCharge" },
  { "ClassStatus_Riposte", "RiposteStance" },
  { "ClassStatus_CounterStance", "CounterStance" }, { "ClassStatus_HolyStance", "CounterStance" }, { "ClassStatus_VowCharge", "VowCharge" }, { "ClassStatus_TruthCast", "TruthCast" },
  { "MageCloneCharging", "CloneCharge" },
  { "ClassStatus_Blocking", "Block" },
}

local entries = {}
local function smooth(t)
  t = math.clamp(t, 0, 1)
  return t * t * (3 - 2 * t)
end
local function angles(record, a)
  if not a then
    return identity
  end
  local key=string.format("%.3f:%.3f:%.3f",a[1],a[2],a[3])
 local frame=record.poses[key]
 if not frame then
  frame=record.inverseBasis*CFrame.Angles(math.rad(a[1]),math.rad(a[2]),math.rad(a[3]))*record.basis
  if record.poseCount<128 then record.poses[key]=frame record.poseCount+=1 end
 end
 return frame
end
local function bind(char)
  local previous=entries[char]
  if previous then
   if previous.conn then previous.conn:Disconnect() end
   if previous.appearanceConnection then previous.appearanceConnection:Disconnect() end
  end
  local entry={char=char,humanoid=char:FindFirstChildOfClass("Humanoid"),joints={},holdWeight=0}
  for _, name in ipairs(JOINTS) do
    local j = char:FindFirstChild(name, true)
    if j and j:IsA("Motor6D") then
      entry.joints[name]={joint=j,basis=j.C0.Rotation,inverseBasis=j.C0.Rotation:Inverse(),poses={},poseCount=0}
    end
  end
  local function oneShot()
    local v = char:GetAttribute("ClassAnim")
    if type(v) ~= "string" then
      return
    end
    local name, at = v:match("^(.-)|(.+)$")
    if name and ANIMS[name] and not ANIMS[name].Hold then
      entry.blendFrom = {}
      for jn, rec in pairs(entry.joints) do
        entry.blendFrom[jn] = rec.joint.Transform
      end
      entry.anim = ANIMS[name]
      entry.started = math.min(workspace:GetServerTimeNow(), tonumber(at) or workspace:GetServerTimeNow())
      if name == "Shoot" then
        entry.aimUntil = entry.started + AIM_HOLD
      end
    end
  end
  entry.conn = char:GetAttributeChangedSignal("ClassAnim"):Connect(oneShot)
  entries[char] = entry
  entry.appearanceConnection=char:GetAttributeChangedSignal("R6AppearanceRevision"):Connect(function() bind(char) end)
end
local function sample(anim, t)
  local last = anim[#anim][1]
  if t >= last then
    return nil
  end
  for i = 1, #anim - 1 do
    local a, b = anim[i], anim[i + 1]
    if t >= a[1] and t <= b[1] then
      local span = math.max(0.001, b[1] - a[1])
      local x = math.clamp((t - a[1]) / span, 0, 1)
       
      local k = span <= 0.1 and 1 - (1 - x) ^ 3 or smooth(x)
      return a[2], b[2], k
    end
  end
end

 
Run.PreSimulation:Connect(function(dt)
 local tickDt=dt
  local now = workspace:GetServerTimeNow()
  for char, entry in pairs(entries) do
    if not char.Parent then
      if entry.conn then
        entry.conn:Disconnect()
      end
      if entry.appearanceConnection then entry.appearanceConnection:Disconnect() end
      entries[char] = nil
      continue
    end
    local h=entry.humanoid
  local camera=workspace.CurrentCamera
  local root=char:FindFirstChild("HumanoidRootPart")
  if workspace:GetAttribute("GoldenTimeStopped")==true or char:GetAttribute("TimeFrozen") or char:GetAttribute("ParryFrozen")
   or camera and root and (camera.CFrame.Position-root.Position).Magnitude>180 then continue end
    if not h or h.Health <= 0 or not char:GetAttribute("ClassId") then
      continue
    end
    local vanished=char:GetAttribute("TwinbladeVanished")==true
    if vanished or entry.vanished then
      for _,d in char:GetDescendants() do
        if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier=vanished and 1 or 0 end
      end
      entry.vanished=vanished
    end
    local spinT
    local spinEnd=char:GetAttribute("TwinbladeSpinEnd")
    if spinEnd and spinEnd>now then
      spinT=math.clamp(1-(spinEnd-now)/(char:GetAttribute("TwinbladeSpinDur") or 1.4),0,1)
    end
    if spinT or entry.spinning then
      local gear=char:FindFirstChild("ClassGear")
      local motorR=gear and gear:FindFirstChild("BladeSpinR",true)
      local motorL=gear and gear:FindFirstChild("BladeSpinL",true)
      local a=spinT and math.rad(2520*spinT) or 0
      if motorR then motorR.Transform=CFrame.Angles(a,0,0) end
      if motorL then motorL.Transform=CFrame.Angles(-a,0,0) end
      if spinT then
        entry.spinning=true
      else
        entry.spinning=false
        local rj=entry.joints.RootJoint
        if rj then rj.joint.Transform=identity end
      end
    end
    local hold
    for _, pair in ipairs(HOLDS) do
      if char:GetAttribute(pair[1]) then
        hold = ANIMS[pair[2]]
        break
      end
    end
    entry.holdWeight=math.clamp(entry.holdWeight+(hold and 0.25 or -0.2)*math.min(tickDt*60,3),0,1)
    if hold then
      entry.lastHold = hold
    end
    local poseA, poseB, k
    if entry.anim then
      poseA, poseB, k = sample(entry.anim, now - entry.started)
      if not poseA then
        entry.anim = nil
      end
    end
    local shake = entry.lastHold and entry.lastHold.Shake or 0
     
    local attacking = entry.anim ~= nil or hold ~= nil
    if entry.trailsOn ~= attacking then
      entry.trailsOn = attacking
      local gear = char:FindFirstChild("ClassGear")
      if gear then
        for _, d in ipairs(gear:GetDescendants()) do
          if d:IsA("Trail") and d.Name == "SwingTrail" then
            d.Enabled = attacking
          end
        end
      end
    end
    local since = entry.anim and (now - entry.started) or 1
    local classId = char:GetAttribute("ClassId")
    local idle = IDLES[classId] or REST
    if classId == "Gambler" then
      local goal = entry.aimUntil and now < entry.aimUntil and 1 or 0
      entry.aimK = entry.aimK or 0
      entry.aimK += math.clamp(goal - entry.aimK, -tickDt * 4, tickDt * 12)
      idle = blendPose(idle, GAMBLER_AIM, entry.aimK)
    end
    local isClone=char:GetAttribute("MageClone")==true
    local cloneSpeed=isClone and (char:GetAttribute("MageCloneMoveSpeed") or 0) or 0
    local walking=isClone and cloneSpeed>0.5 or not isClone and h.MoveDirection.Magnitude>0.1
    for name, record in pairs(entry.joints) do
      local target, weight
      if poseA then
         
        target = angles(record, poseA[name] or idle[name]):Lerp(angles(record, poseB[name] or idle[name]), k)
         
        if name == "Neck" and not (poseA.Neck or poseB.Neck) then
          local rootA, rootB = poseA.RootJoint, poseB.RootJoint
          local twist = ((rootA and rootA[2] or 0) * (1 - k) + (rootB and rootB[2] or 0) * k) * -0.55
          target = angles(record, { 0, twist, 0 })
        end
         
        local from = entry.blendFrom and entry.blendFrom[name]
        local blend = entry.anim and entry.anim.Blend or 0.06
        if from and since < blend then
          target = from:Lerp(target, since / blend)
        end
        weight = (poseA[name] or poseB[name] or idle[name]) and 1 or 0
      elseif entry.holdWeight > 0 and entry.lastHold then
        target = angles(record, entry.lastHold.Hold[name])
        local stride = entry.lastHold.Stride
        if stride and (name == "Right Hip" or name == "Left Hip") then
           
           
          local swing = math.floor(math.sin(now * (entry.lastHold.StrideRate or 20)) * stride + 0.5)
          target = angles(record, { name == "Right Hip" and swing or -swing, 0, 0 })
        end
        if shake > 0 and (name == "Right Shoulder" or name == "Left Shoulder") then
          target *= CFrame.Angles(math.rad(math.sin(now * 40) * shake), 0, 0)
        end
        weight = smooth(entry.holdWeight)
      elseif idle[name] then
        target = angles(record, idle[name])
        weight = 1
      end
      if isClone then
       local leg=name=="Right Hip" or name=="Left Hip"
       if leg then
        local phase=now*math.clamp(cloneSpeed*.5,0,10)
        local stride=walking and math.sin(phase)*(name=="Right Hip" and 32 or -32) or 0
        target=angles(record,{stride,0,0}) weight=1
       elseif name=="RootJoint" and not poseA then
        target=angles(record,{walking and -5 or 0,0,0}) weight=1
       elseif name=="Neck" and not poseA then target=identity weight=1 end
      end
      if name=="RootJoint" and spinT then
        local yaw=math.rad((char:GetAttribute("ClassSpinDegrees") or 1080)*smooth(spinT))
        record.joint.Transform=record.inverseBasis*CFrame.Angles(0,yaw,0)*record.basis*(target or identity)
        continue
      end
      if target and weight > 0 then
         
        local legs = name == "Right Hip" or name == "Left Hip"
        if legs and walking and not isClone then
          weight = 0
        elseif name == "RootJoint" and walking then
          weight *= 0.5
        end
        if weight > 0 then
          record.joint.Transform = record.joint.Transform:Lerp(target, legs and weight * 0.7 or weight)
        end
      end
    end
  end
end)

local function watch(player)
  local function added(char)
    task.wait(0.5)
    bind(char)
  end
  if player.Character then
    task.spawn(added, player.Character)
  end
  player.CharacterAdded:Connect(added)
end
for _, p in ipairs(Players:GetPlayers()) do
  watch(p)
end
Players.PlayerAdded:Connect(watch)
local function watchClone(object)
 local model=object:IsA("Model") and object or object:IsA("Humanoid") and object.Parent
 -- Mage clones, and class puppets (an NPC running a class kit, e.g. the lobby showroom's performer)
 if model and (model:GetAttribute("MageClone")==true or model:GetAttribute("ClassPuppet")==true) then
  task.defer(function()
   for _=1,5 do
    if not model.Parent then return end
    if model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Torso") and model:FindFirstChild("Right Shoulder",true) then bind(model) return end
    task.wait(.1)
   end
  end)
 end
end
for _,object in workspace:GetDescendants() do watchClone(object) end
workspace.DescendantAdded:Connect(watchClone)
