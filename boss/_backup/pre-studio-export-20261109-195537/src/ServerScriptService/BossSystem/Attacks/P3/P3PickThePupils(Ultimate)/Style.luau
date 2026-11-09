local NEON_SOFTEN = 0.5  
local PULSE_SLOW = 2  
local FLASH_SCALE = 0.5  
local GOLD = Color3.fromRGB(239, 184, 42)
local PALE = Color3.fromRGB(255, 239, 175)
local WHITE = Color3.fromRGB(255, 255, 244)
local DARK = Color3.fromRGB(22, 17, 38)
local GREEN = Color3.fromRGB(127, 255, 170)
local RED = Color3.fromRGB(255, 75, 85)
local VIOLET = Color3.fromRGB(166, 110, 255)
local BULB_OFF = Color3.fromRGB(70, 60, 40)
local CONFETTI = { GOLD, PALE, WHITE, Color3.fromRGB(255, 120, 150), Color3.fromRGB(130, 220, 255), GREEN }
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local HAND_L = CFrame.new(-40, 24, -9) * CFrame.Angles(0, math.pi, -0.2)
local HAND_R = CFrame.new(40, 24, -9) * CFrame.Angles(0, math.pi, 0.2)
local BULB_COUNT = 24
local STAGE_RADIUS = 66
local BASE_GRADE = {
	Brightness = 0,
	Contrast = 0.12,
	Saturation = 0.12,
	TintColor = Color3.fromRGB(255, 243, 222),
}

return table.freeze({
	NEON_SOFTEN = NEON_SOFTEN,
	PULSE_SLOW = PULSE_SLOW,
	FLASH_SCALE = FLASH_SCALE,
	GOLD = GOLD,
	PALE = PALE,
	WHITE = WHITE,
	DARK = DARK,
	GREEN = GREEN,
	RED = RED,
	VIOLET = VIOLET,
	BULB_OFF = BULB_OFF,
	CONFETTI = CONFETTI,
	SPARKLE = SPARKLE,
	HAND_L = HAND_L,
	HAND_R = HAND_R,
	BULB_COUNT = BULB_COUNT,
	STAGE_RADIUS = STAGE_RADIUS,
	BASE_GRADE = BASE_GRADE,
})
