 
local Visuals = {}
function Visuals.Create(ctx)
	local count = ctx.count
	local points = ctx.points
	local windup = ctx.windup
	local cast = ctx.cast
	local valid = ctx.valid
	local core = ctx.core
	local PANEL = ctx.PANEL
	local Effects = ctx.Effects
	local OUT = ctx.OUT
	local ACCENT = ctx.ACCENT
	local ringAlong = ctx.ringAlong
	local DEEP = ctx.DEEP
	local HOT = ctx.HOT
	local SPARKLE = ctx.SPARKLE
	local WHITE = ctx.WHITE
	local normals, panels, frames = {}, {}, {}
	for index = 1, count do
		local p = points[index + 1]
		local incoming = (p - points[index]).Unit
		local outgoing = (points[index + 2] - p).Unit
		local deltaNormal = incoming - outgoing
		normals[index] = deltaNormal.Magnitude > 0.01 and deltaNormal.Unit or -incoming
	end
	local popGap = math.min(0.04, (windup - 0.12) / math.max(count, 1))
	local PW, PH = 6, 8  
	for index = 1, count do
		cast:Schedule((index - 1) * popGap, function()
			if not valid() then
				return
			end
			local p = points[index + 1]
			local normal = normals[index]
			local facing = CFrame.lookAt(p, p + normal)
			local panel =
				cast:Add(core.Part("ProjectileAirMirror", facing, Vector3.new(0.5, 0.5, 0.2), PANEL, 0.25))
			panel.Material = Enum.Material.Glass
			panel:SetAttribute("ReflectionIndex", index)
			panels[index] = panel
			Effects
				:Create(
					panel,
					TweenInfo.new(0.12, Enum.EasingStyle.Back, OUT),
					{ Size = Vector3.new(PW, PH, 0.2) }
				)
				:Play()
			 
			local frame =
				cast:Add(core.Part("ProjectileMirrorFrame", facing, Vector3.new(0.5, 0.5, 0.12), ACCENT, 0.2))
			frame.Material = Enum.Material.Neon
			frames[index] = frame
			Effects:Create(
				frame,
				TweenInfo.new(0.12, Enum.EasingStyle.Back, OUT),
				{ Size = Vector3.new(PW + 1, PH + 1, 0.12) }
			):Play()
			local glow = cast:Add(
				core.Part("ProjectileMirrorGlow", facing, Vector3.new(PW + 2, PH + 2, 0.05), ACCENT, 0.8)
			)
			Effects:Create(
				glow,
				TweenInfo.new(0.4),
				{ Transparency = 1, Size = Vector3.new(PW * 1.5, PH * 1.5, 0.05) }
			):Play()
			Effects.ReleaseAfter(glow, 0.5)
			ringAlong(p, normal, ACCENT, 1, 9, 0.4)  
			local rim = Instance.new("SurfaceGui")
			rim.Face = Enum.NormalId.Front
			rim.LightInfluence = 0.4
			rim.Parent = panel
			local field = Instance.new("Frame")
			field.Size = UDim2.fromScale(1, 1)
			field.BackgroundColor3 = DEEP
			field.BackgroundTransparency = 0.7
			field.BorderSizePixel = 0
			field.Parent = rim
			local border = Instance.new("UIStroke")
			border.Color = HOT
			border.Thickness = 5
			border.Parent = field
			local light = Instance.new("PointLight")
			light.Color = ACCENT
			light.Brightness = 3
			light.Range = 14
			light.Parent = panel
			local shimmer = Instance.new("ParticleEmitter")
			shimmer.Name = "MirrorShimmer"
			shimmer.Texture = SPARKLE
			shimmer.Rate = 0
			shimmer.Color = ColorSequence.new(ACCENT, WHITE)
			shimmer.Lifetime = NumberRange.new(0.4, 0.8)
			shimmer.Speed = NumberRange.new(1, 4)
			shimmer.SpreadAngle = Vector2.new(90, 90)
			shimmer.LightEmission = 0.6
			shimmer.Size = NumberSequence.new(0.35)
			shimmer.Parent = panel
			shimmer:Emit(10)
		end)
	end
	return normals, panels, frames, PW, PH
end
return table.freeze(Visuals)
