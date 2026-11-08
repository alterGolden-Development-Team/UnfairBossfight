local Visuals = {}
function Visuals.disc(ctx)
	local core = ctx.core
	local cast = ctx.cast
	local function disc(position, diameter, color, alpha, detached)
		local p = core.Part(
			"P3CloneTrapRing",
			CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.2, diameter, diameter),
			color,
			alpha
		)
		if not detached then
			cast:Add(p)
		end
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		return p
	end
	return disc
end
function Visuals.shock(ctx)
	local disc = ctx.disc
	local Effects = ctx.Effects
	local function shock(position, color, from, to, time, detached)
		local p = disc(position, from, color, 0.2, detached)
		Effects:Create(
			p,
			TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, to, to), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.1)
	end
	return shock
end
function Visuals.burst(ctx)
	local core = ctx.core
	local GOLD = ctx.GOLD
	local cast = ctx.cast
	local SPARKLE = ctx.SPARKLE
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local function burst(position, count, detached)
		local p = core.Part("P3CloneTrapBurst", CFrame.new(position), Vector3.one * 0.2, GOLD, 1)
		if not detached then
			cast:Add(p)
		end
		local e = Instance.new("ParticleEmitter")
		e.Texture = SPARKLE
		e.Rate = 0
		e.Color = ColorSequence.new(GOLD, WHITE)
		e.Lifetime = NumberRange.new(0.4, 0.9)
		e.Speed = NumberRange.new(10, 26)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Drag = 3
		e.LightEmission = 0.8
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = p
		e:Emit(count)
		Effects.ReleaseAfter(p, 1.1)
	end
	return burst
end
function Visuals.buildDecoy(ctx)
	local actor = ctx.actor
	local Collection = ctx.Collection
	local contactParts = ctx.contactParts
	local core = ctx.core
	local Runtime = ctx.Runtime
	local function buildDecoy(ground)
		local wasArchivable = actor.Archivable
		actor.Archivable = true
		local copy = actor:Clone()
		actor.Archivable = wasArchivable
		if not copy then
			return nil
		end
		copy.Name = "P3CloneTrapDecoy"
		for _, item in ipairs(copy:GetDescendants()) do
			if item:IsA("BaseScript") or item:IsA("Sound") or item:IsA("ForceField") then
				item:Destroy()
			elseif item:IsA("Humanoid") then
				item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				item.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				item.EvaluateStateMachine = false
				item.BreakJointsOnDeath = false
			end
		end
		 
		local function scrub(item)
			for name in pairs(item:GetAttributes()) do
				 
				if name:sub(1, 3) ~= "RBX" then
					item:SetAttribute(name, nil)
				end
			end
			for _, tag in ipairs(Collection:GetTags(item)) do
				Collection:RemoveTag(item, tag)
			end
		end
		scrub(copy)
		for _, item in ipairs(copy:GetDescendants()) do
			scrub(item)
			if item:IsA("BasePart") then
				item.Anchored = true
				item.CanCollide = false
				item.CanQuery = false
				item.CanTouch = false
				 
				if item.Transparency < 0.99 then
					table.insert(contactParts, item)
				end
			end
		end
		 
		local rootOffset = 3
		local below = workspace:Raycast(core.Root.Position, Vector3.new(0, -40, 0), core.Params(actor))
		if below then
			rootOffset = math.clamp(core.Root.Position.Y - below.Position.Y, 2, 8)
		end
		local rootPosition = ground + Vector3.new(0, rootOffset, 0)
		local bossFlat = Vector3.new(core.Root.Position.X, rootPosition.Y, core.Root.Position.Z)
		copy.PrimaryPart = copy:FindFirstChild(core.Root.Name, true)
		copy:PivotTo(CFrame.lookAt(rootPosition, bossFlat))
		copy:SetAttribute("IsIllusion", true)
		copy:SetAttribute("IsGoldenClone", true)
		copy.Parent = Runtime.Effects
		return copy
	end
	return buildDecoy
end
return table.freeze(Visuals)
