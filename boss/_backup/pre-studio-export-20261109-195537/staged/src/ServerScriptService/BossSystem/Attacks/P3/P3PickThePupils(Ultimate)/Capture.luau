 
return function(ctx)
	local hands, frame = ctx.Hands, ctx.Frame
	local function handFrame(pivot, side, gap)
		return CFrame.new(pivot.Position) * frame.Rotation * CFrame.new(side * gap, 1.5, 1) * CFrame.Angles(0, math.pi, side * math.pi / 2)
	end
	local function carry(pivot, gap)
		for i, side in ipairs({-1, 1}) do hands[i]:PivotTo(handFrame(pivot, side, gap)) end
	end
	local api = {}
	function api.Grab(pupil)
		local start = pupil.Character:GetPivot()
		local h1, h2 = hands[1]:GetPivot(), hands[2]:GetPivot()
		if not ctx.Animate(0.65, function(t)
			hands[1]:PivotTo(h1:Lerp(handFrame(start, -1, 9), t))
			hands[2]:PivotTo(h2:Lerp(handFrame(start, 1, 9), t))
		end) then return false end
		if not ctx.Animate(0.3, function(t) carry(start, 9 - 3 * t) end) then return false end
		local held = frame * CFrame.new(0, 23, 15)
		return ctx.Animate(1, function(t)
			local a = t * t * (3 - 2 * t)
			local pivot = start:Lerp(held, a)
			pupil.Character:PivotTo(pivot)
			carry(pivot, 6)
		end)
	end
	function api.Snap(pupil, onSummon)
  local hand = hands[2]
  local start = hand:GetPivot()
  local pose = frame * CFrame.new(10, 28, 12) * CFrame.Angles(0, math.pi, -math.pi / 4)
  local finger = {}
  for _, part in ipairs(hand:GetDescendants()) do
   if part:IsA("BasePart") and (part.Name:match("^Finger2_") or part.Name:match("^Joint2_")
    or part.Name == "Fingertip2" or part.Name == "Nail2") then
    finger[part] = start:ToObjectSpace(part.CFrame)
   end
  end
  local joint = CFrame.new(1.1, -0.1, -3.9)
  local function curl(amount)
   for part, original in pairs(finger) do
    part.CFrame = hand:GetPivot() * joint * CFrame.Angles(-amount, 0, 0) * joint:Inverse() * original
   end
  end
  if not ctx.Animate(0.55, function(t) hand:PivotTo(start:Lerp(pose,t)); curl(t * 1.05) end) then return false end
  if not ctx.Animate(0.12, function(t) curl((1-t) * 1.05) end) then return false end
  pupil.Character:PivotTo(frame * CFrame.new(0, 23, 15))
  onSummon()
  return ctx.Animate(0.45, function() end)
 end
	function api.Deposit(pupil, cupFrame)
		local start, finish = pupil.Character:GetPivot(), cupFrame * CFrame.new(0, 3.2, 0)
		return ctx.Animate(1.1, function(t)
			local a = t * t * (3 - 2 * t)
			local pivot = start:Lerp(finish, a) + Vector3.new(0, math.sin(t * math.pi) * 6, 0)
			pupil.Character:PivotTo(pivot)
			carry(pivot, 6 + math.max(0, t - 0.75) * 24)
		end)
	end
	return api
end