

local Finale = {}

local TAU = math.pi * 2
local function smooth(a) return a * a * (3 - 2 * a) end
local function easeIn(a) return a * a * a end
local function easeOut(a) return 1 - (1 - a) ^ 3 end

function Finale.New(ctx)
	local Style, V, Cards, Effects, cast, actor = ctx.Style, ctx.V, ctx.Cards, ctx.Effects, ctx.Cast, ctx.Actor
	local F = Style.Finale
	local suit = Style.Suits[F.Suit] or Style.Suits.Spade
	local GOLD, WHITE = Style.Gold, Style.White
	local self = { Cards = {}, Slots = {} }
	local motions = {}  

	local function part(name, frame, size, color, alpha, shape)
		local p = Effects.AcquirePart()
		p.Name, p.Shape = name, shape or Enum.PartType.Block
		p.CFrame, p.Size, p.Color, p.Transparency = frame, size, color, alpha or 0
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.Neon
		p.Parent = ctx.Parent
		return cast:Add(p)
	end
	local function release(t, p) cast:Schedule(t, function() Effects.Release(p) end) end

	local function move(index, to, length, ease, spin)
		local card = self.Cards[index]
		if not card then return end
		motions[index] = { From = card.Root.CFrame, To = to, Start = os.clock(), Length = math.max(length, 0.01), Ease = ease or smooth, Spin = spin or 0 }
	end

	 
	cast:Step(function()
		if cast.closed then return false end
		local now = os.clock()
		for index, card in pairs(self.Cards) do
			local m = motions[index]
			if m and card.Root.Parent then
				local frame
				if m.Follow then
					frame = m.Follow(now)
				else
					local a = math.clamp((now - m.Start) / m.Length, 0, 1)
					local e = m.Ease(a)
					frame = m.From:Lerp(m.To, e)
					if m.Spin ~= 0 then frame = frame * CFrame.Angles(0, m.Spin * (1 - e), 0) end
					if a >= 1 and m.Then then
						local nextMotion = m.Then
						m.Then = nil
						motions[index] = nextMotion(now)
					end
				end
				if frame then card.Root.CFrame = frame end
			end
		end
		return true
	end)

	local function bobbing(index, slot)
		local phase = index * 1.3
		return { Follow = function(now)
			return slot * CFrame.new(0, math.sin(now * 1.6 + phase) * 0.6, 0) * CFrame.Angles(0, math.sin(now * 0.9 + phase) * 0.06, 0)
		end }
	end

	 
	function self:Deal(center, facing, fromFrames)
		local D = F.Deal
		facing = Vector3.new(facing.X, 0, facing.Z)
		facing = facing.Magnitude > 0.01 and facing.Unit or Vector3.new(0, 0, -1)
		local base = math.atan2(-facing.X, -facing.Z)
		local count = #F.Ranks
		for index, rank in ipairs(F.Ranks) do
			 
			local spreadAngle = (index - (count + 1) / 2) * math.rad(30)
			local yaw = base + spreadAngle
			local outward = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
			local position = center + outward * D.Radius + Vector3.new(0, D.Height + math.cos(spreadAngle * 1.6) * 3, 0)
			local slot = CFrame.lookAt(position, position + outward) * CFrame.Angles(math.rad(-18), 0, 0)
			 
			self.Slots[index] = slot
			local card = Cards.Build({ Rank = rank, Symbol = suit.Symbol, Color = suit.Color, Height = D.CardHeight, Style = Style,
				Cast = cast, Parent = ctx.Parent, Light = true, Name = "RoyalFlush" .. rank })
			card:SetFade(1)
			card.Root.CFrame = slot
			self.Cards[index] = card
			local from = fromFrames and fromFrames[index] or CFrame.new(center + Vector3.new(0, 4, 0))
			local delay = (index - 1) * D.Interval
			cast:Schedule(delay, function()
				 
				local flyer = Cards.Build({ Rank = rank, Symbol = suit.Symbol, Color = suit.Color, Height = 1.6, Style = Style, Cast = cast,
					Parent = ctx.Parent, Name = "RoyalFlushFlyer" })
				flyer:SetGlow(1)
				flyer.Root.CFrame = from
				local streak = Instance.new("Trail")
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Position, a1.Position = Vector3.new(0, 0.6, 0), Vector3.new(0, -0.6, 0)
				a0.Parent, a1.Parent = flyer.Root, flyer.Root
				streak.Attachment0, streak.Attachment1 = a0, a1
				streak.Color = ColorSequence.new(WHITE, suit.Color)
				streak.Transparency = NumberSequence.new(0.1, 1)
				streak.LightEmission, streak.Lifetime, streak.FaceCamera = 1, 0.35, true
				streak.Parent = flyer.Root
				local began = os.clock()
				local mid = (from.Position + slot.Position) / 2 + Vector3.new(0, 6, 0)
				local flight = Effects.NewCast(actor, "RoyalFlushDealFlight", D.Flight + 0.3)
				flight:Step(function()
					if flight.closed or cast.closed then return false end
					local a = math.clamp((os.clock() - began) / D.Flight, 0, 1)
					local e = easeOut(a)
					local p = (1 - e) ^ 2 * from.Position + 2 * (1 - e) * e * mid + e * e * slot.Position
					flyer.Root.CFrame = CFrame.new(p) * CFrame.Angles(0, a * TAU * 2, a * 0.6)
					if a >= 1 then
						flyer.Model:Destroy()
						flight:Dispose()
						V.Flash(cast, slot.Position, WHITE, D.CardHeight * 0.8, 0.22)
						V.Flash(cast, slot.Position, suit.Color, D.CardHeight * 1.3, 0.4)
						V.Sparks(cast, slot.Position, { Count = 14, Card = true, Speed = { 14, 34 }, Life = { 0.5, 0.9 }, Gravity = 14,
							Colors = { WHITE, GOLD, suit.Color }, Size = Vector3.new(0.7, 1, 0.04) })
						V.Ring(cast, slot.Position, suit.Color, D.CardHeight * 0.7, 0.4, { Normal = slot.LookVector, Start = 0.3 })
						card.Root.CFrame = slot * CFrame.new(0, 0, 2) * CFrame.Angles(0, math.pi, 0)
						move(index, slot, D.Settle, easeOut, math.pi)
						motions[index].Then = function() return bobbing(index, slot) end
						 
						local fadeBegan = os.clock()
						local fader = Effects.NewCast(actor, "RoyalFlushDealFade", D.Settle + 0.2)
						fader:Step(function()
							if fader.closed or cast.closed then return false end
							local f = math.clamp((os.clock() - fadeBegan) / (D.Settle * 0.6), 0, 1)
							card:SetFade(1 - f)
							card:SetGlow(1 - f * 0.5)
							if f >= 1 then fader:Dispose() return false end
							return true
						end)
						return false
					end
					return true
				end)
			end)
		end
		return (count - 1) * D.Interval + D.Flight + D.Settle
	end

	 
	function self:Dive(index, point, seconds)
		local card = self.Cards[index]
		if not card then return end
		card:SetGlow(1)
		local goal = CFrame.lookAt(point + Vector3.new(0, 11, 0), point + Vector3.new(0, 11, 0) + Vector3.new(0, -1, 0.001))
		move(index, goal, seconds, easeIn, TAU)
	end

	function self:Shatter(index)
		local card = self.Cards[index]
		if not card then return end
		local position = card.Root.Position
		V.Flash(cast, position, WHITE, card.Height * 0.9, 0.18)
		V.Flash(cast, position, suit.Color, card.Height * 1.4, 0.4)
		V.Sparks(cast, position, { Count = 26, Card = true, Speed = { 25, 60 }, Life = { 0.5, 0.9 }, Gravity = 30,
			Colors = { WHITE, GOLD, suit.Color }, Size = Vector3.new(0.9, 1.3, 0.05) })
		V.Ring(cast, position, suit.Color, card.Height * 0.9, 0.45, { Normal = Vector3.yAxis, Start = 0.2 })
		motions[index] = nil
		card.Model:Destroy()
		self.Cards[index] = nil
	end

	 
	 
	local function edgeFrame(point, height, toward)
		local flat = Vector3.new(toward.X, 0, toward.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
		local position = point + Vector3.new(0, height, 0)
		return CFrame.lookAt(position, position + flat)
	end
	function self:Hover(index, point, height, seconds, toward)
		local card = self.Cards[index]
		if not card then return end
		card:SetGlow(0.7)
		move(index, edgeFrame(point, height + card.Height * 0.5, toward or Vector3.new(0, 0, -1)), seconds, smooth, math.pi)
	end
	function self:Slam(index, point, seconds, toward)
		local card = self.Cards[index]
		if not card then return end
		card:SetGlow(1)
		 
		move(index, edgeFrame(point, card.Height * 0.32, toward or Vector3.new(0, 0, -1)), seconds, easeIn)
	end
	function self:Lift(index, seconds)
		local card = self.Cards[index]
		if not card then return end
		move(index, card.Root.CFrame * CFrame.new(0, card.Height * 0.9, 0), seconds, easeOut)
		card:SetGlow(0.5)
	end

	 
	function self:Lens(index, getFrom, getTo)
		local card = self.Cards[index]
		if not card then return end
		card:SetGlow(1)
		local began = os.clock()
		local start = card.Root.CFrame
		motions[index] = { Follow = function(now)
			local from, to = getFrom(), getTo()
			local direction = to - from
			if direction.Magnitude < 0.1 then return nil end
			direction = direction.Unit
			 
			local goal = CFrame.lookAt(from + direction * 7, from + direction * 7 + direction) * CFrame.Angles(0, 0, math.sin((now - began) * 2) * 0.12)
			local a = math.clamp((now - began) / 0.5, 0, 1)
			return start:Lerp(goal, easeOut(a))
		end }
	end

	function self:Telegraph(from, to, life, width)
		local delta = to - from
		local length = delta.Magnitude
		if length < 1 then return end
		local line = part("RoyalFlushAimLine", CFrame.lookAt(from + delta / 2, to), Vector3.new(0.12, 0.12, length), suit.Color, 0.7)
		Effects:Create(line, TweenInfo.new(life, Enum.EasingStyle.Linear), { Size = Vector3.new(width or 0.6, width or 0.6, length), Transparency = 0.25 }):Play()
		release(life + 0.02, line)
		return line
	end

	 
	function self:TrackLine(getFrom, getTo, life)
		local line = part("RoyalFlushTrackLine", CFrame.identity, Vector3.new(0.15, 0.15, 1), suit.Color, 0.6)
		local began, locked = os.clock(), nil
		local tracker = Effects.NewCast(actor, "RoyalFlushTrackLine", life + 0.3)
		tracker:Step(function()
			if tracker.closed or cast.closed then return false end
			local now = os.clock()
			local from, to = getFrom(), getTo()
			local delta = to - from
			local length = delta.Magnitude
			if length > 0.5 then
				local a = math.clamp((now - began) / life, 0, 1)
				local width = locked and 0.9 or (0.15 + 0.35 * a)
				line.CFrame = CFrame.lookAt(from + delta / 2, to)
				line.Size = Vector3.new(width, width, length)
				line.Transparency = locked and 0.05 or (0.6 - 0.3 * a)
			end
			if now - began >= life then
				Effects.Release(line)
				tracker:Dispose()
				return false
			end
			return true
		end)
		return {
			Lock = function()
				locked = true
				line.Color = WHITE
			end,
		}
	end

	function self:Beam(from, to, width)
		local delta = to - from
		local length = delta.Magnitude
		if length < 1 then return end
		local frame = CFrame.lookAt(from + delta / 2, to) * CFrame.Angles(0, math.pi / 2, 0)
		local core = part("RoyalFlushBeam", frame, Vector3.new(length, width * 0.55, width * 0.55), WHITE, 0, Enum.PartType.Cylinder)
		local shell = part("RoyalFlushBeamShell", frame, Vector3.new(length, width * 1.25, width * 1.25), suit.Color, 0.35, Enum.PartType.Cylinder)
		Effects:Create(core, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(length, 0.05, 0.05), Transparency = 1 }):Play()
		Effects:Create(shell, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(length, width * 2.2, width * 2.2), Transparency = 1 }):Play()
		release(0.6, core)
		release(0.6, shell)
		 
		local direction = delta.Unit
		for i = 1, math.clamp(math.floor(length / 14), 3, 12) do
			local at = from + direction * (i * length / (math.clamp(math.floor(length / 14), 3, 12) + 1))
			cast:Schedule(i * 0.015, function()
				V.Ring(cast, at, i % 2 == 0 and WHITE or suit.Color, width * 1.4, 0.35, { Normal = direction, Segments = 12, Start = 0.4, Width = 0.25 })
			end)
		end
		V.Sparks(cast, from, { Count = 18, Dir = direction, Spread = 0.25, Speed = { 80, 160 }, Life = { 0.2, 0.4 }, Colors = { WHITE, suit.Color } })
	end

	function self:Clear(seconds)
		for index, card in pairs(self.Cards) do
			local position = card.Root.Position
			V.Sparks(cast, position, { Count = 10, Card = true, Speed = { 10, 26 }, Life = { 0.5, 0.8 }, Gravity = 12,
				Colors = { WHITE, GOLD, suit.Color }, Size = Vector3.new(0.8, 1.1, 0.05) })
			local began = os.clock()
			local fader = Effects.NewCast(actor, "RoyalFlushClear", (seconds or 0.4) + 0.2)
			fader:Step(function()
				if fader.closed then return false end
				local a = math.clamp((os.clock() - began) / (seconds or 0.4), 0, 1)
				if card.Model.Parent then card:SetFade(a) end
				if a >= 1 then fader:Dispose() return false end
				return true
			end)
			self.Cards[index] = nil
			motions[index] = nil
		end
	end

	return self
end

return table.freeze(Finale)
