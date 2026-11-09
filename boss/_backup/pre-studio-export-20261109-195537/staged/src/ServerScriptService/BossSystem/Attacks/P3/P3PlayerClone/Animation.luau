 
local Animation = {}
function Animation.Attach(record)
	local phase = math.random() * math.pi * 2
	local speed = 0
	local function rotate(base, pitch, yaw, roll)
		return CFrame.new(base.Position) * CFrame.Angles(pitch, yaw, roll) * base.Rotation
	end
	function record.Pose(dt, actualSpeed, swing, dodge)
		dt = math.clamp(dt, 0, 0.1)
		local alpha = 1 - math.exp(-14 * dt)
		speed += (actualSpeed - speed) * alpha
		local amount = math.clamp(speed / 16, 0, 1)
		phase += math.min(speed / 8, 2.8) * math.pi * 2 * dt
		local stride = math.sin(phase) * math.rad(23) * amount
		for joint, data in pairs(record.Joints) do
			if joint.Parent then
				local pitch, yaw, roll = 0, 0, 0
				if data.Name == "Right Hip" or data.Name == "RightHip" then pitch = stride
				elseif data.Name == "Left Hip" or data.Name == "LeftHip" then pitch = -stride
				elseif data.Name == "Left Shoulder" or data.Name == "LeftShoulder" then pitch = stride * 0.65
				elseif data.Name == "Right Shoulder" or data.Name == "RightShoulder" then
					pitch, roll = math.rad(-18), math.rad(6)
					if swing then
						local p = math.clamp(swing, 0, 1)
						local strike = p < 0.4 and p / 0.4 or 1 - (p - 0.4) / 0.6
						pitch = math.rad(-18 - 85 * strike)
						roll = math.rad(6 - 20 * strike)
					end
				elseif data.Name == "RootJoint" or data.Name == "Waist" then
					pitch = dodge and math.rad(8) or math.rad(3) * amount
				end
				joint.C0 = joint.C0:Lerp(rotate(data.Base, pitch, yaw, roll), alpha)
			end
		end
	end
end
return Animation
