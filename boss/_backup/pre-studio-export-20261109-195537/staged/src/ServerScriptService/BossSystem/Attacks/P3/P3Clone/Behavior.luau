local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
return function(actor)
	local system = script:FindFirstAncestor("BossSystem")
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Players = game:GetService("Players")
	local Collection = game:GetService("CollectionService")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local GOLD, WHITE = Style.GOLD, Style.WHITE
	local SPARKLE = Style.SPARKLE
	local DASH_NAME = "P3Dash"
	local random = Random.new()
	local api = { Cooldown = Config.P3CloneTrapCooldown or 6 }
	local Status = require(BossSystem.Combat.StatusEffectService)
	local current

	local function dashApi()
		local ok, dash = pcall(Registry.For, actor, DASH_NAME)
		return ok and dash or nil
	end
	local function flatDistance(a, b)
		return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
	end

	function api.CanUse(target)
		return not current
			and math.floor(actor:GetAttribute("Phase") or 1) == 3
			and not actor:GetAttribute("IsGoldenClone")
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and not actor:GetAttribute("ExecutionLocked")
			and core.Active()
			and dashApi() ~= nil
			and core.Alive(target)
			and Players:GetPlayerFromCharacter(target) ~= nil
	end

	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, "P3Clone", function()
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local lifetime = math.clamp(Config.P3CloneTrapLifetime or 35, 10, 180)
			local radius = 4  
			local stopGap = math.clamp(Config.P3CloneTrapPullStopDistance or 12, 6, 30)  
			local pullSpeed = math.clamp(Config.P3CloneTrapPullSpeed or 110, 40, 200)

			local cast = Effects.NewCast(actor, "P3CloneTrap", lifetime + 1)
			local spot, decoy, captured
			local contactParts = {}
			local function valid()
				return cast:Alive()
					and actor.Parent
					and core.Alive(actor)
					and not actor:GetAttribute("EncounterEnded")
					and math.floor(actor:GetAttribute("Phase") or 1) == 3
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
			end

			local disc = Visuals.disc({
				core = core,
				cast = cast,
			})
			local shock = Visuals.shock({
				disc = disc,
				Effects = Effects,
			})
			local burst = Visuals.burst({
				core = core,
				GOLD = GOLD,
				cast = cast,
				SPARKLE = SPARKLE,
				WHITE = WHITE,
				Effects = Effects,
			})

			local function pickSpot()
				local bounds = Placement.GetBounds()
				if not bounds then
					return nil
				end
				local margin = 14
				local others = { core.Root.Position }
				for _, character in ipairs(core.Characters()) do
					local r = character:FindFirstChild("HumanoidRootPart")
					if r then
						others[#others + 1] = r.Position
					end
				end
				local best, bestNearest
				for _ = 1, 80 do
					local offset = Vector3.new(
						random:NextNumber(-1, 1) * math.max(1, bounds.HalfX - margin),
						0,
						random:NextNumber(-1, 1) * math.max(1, bounds.HalfZ - margin)
					)
					local ground =
						Placement.GroundPoint(bounds.Frame:PointToWorldSpace(offset), { Margin = margin, Clamp = true })
					if ground then
						local nearest = math.huge
						for _, other in ipairs(others) do
							nearest = math.min(nearest, flatDistance(ground, other))
						end
						if nearest >= radius + 16 then
							return ground
						end  
						if not bestNearest or nearest > bestNearest then
							best, bestNearest = ground, nearest
						end
					end
				end
				return best  
			end

			local buildDecoy = Visuals.buildDecoy({
				actor = actor,
				Collection = Collection,
				contactParts = contactParts,
				core = core,
				Runtime = Runtime,
			})

			cast.OnDispose = function()
				if captured then
					Status.ReleaseRestraint(captured, cast)
				end
				if current == cast then
					current = nil
					api.LastCast = nil
					api.LastSpot = nil
				end
				if decoy then
					decoy:Destroy()
				end
				if spot then  
					shock(spot + Vector3.new(0, 0.3, 0), WHITE, 2, radius * 1.6, 0.5, true)
					burst(spot + Vector3.new(0, 4, 0), 60, true)
				end
				actor:SetAttribute("P3CloneTrapActive", false)
			end

			core.Face(target)
			core.PoseAngles({ RightShoulder = { 70, 0, -35 }, LeftShoulder = { 45, 0, 25 } }, 0.12)
			actor:SetAttribute("AttackState", "Clone Trap: planting a decoy")
			if not core.WaitFor(0.3) or not valid() then
				cast:Dispose()
				return false
			end
			spot = pickSpot()
			if not spot then
				cast:Dispose()
				return false
			end
			decoy = buildDecoy(spot)
			if not decoy then
				cast:Dispose()
				return false
			end
			current = cast
			api.LastCast = cast
			api.LastSpot = spot
			actor:SetAttribute("P3CloneTrapActive", true)
			actor:SetAttribute("P3CloneTrapTriggers", 0)
			burst(spot + Vector3.new(0, 4, 0), 50)
			Audio.Emit(actor, "P3Snap", spot, { VolumeScale = 0.8 })

			local function pull(character, dashCast)
				local r = character:FindFirstChild("HumanoidRootPart")
				if not r then
					return false
				end
				if not actor:GetAttribute("AttackInProgress") then
					core.PoseAngles({ RightShoulder = { -110, 0, 12 } }, 0.08)
				end
				local bossPosition = core.Root.Position
				local flat = Vector3.new(bossPosition.X - r.Position.X, 0, bossPosition.Z - r.Position.Z)
				local travel = flat.Magnitude - stopGap
				if travel <= 1 then
					return true
				end  
				local direction = flat.Unit
				local duration = math.clamp(travel / pullSpeed, 0.15, 1.8)
				local speed = math.min(travel / duration, pullSpeed)
				Status.Restrain(character, cast, duration + 0.15)
				local a0 = Instance.new("Attachment")
				a0.Position = Vector3.new(0, 0.5, 0)
				a0.Parent = core.Root
				local a1 = Instance.new("Attachment")
				a1.Parent = r
				local chain = Instance.new("Beam")
				chain.Name = "P3CloneTrapChain"
				chain.Attachment0 = a0
				chain.Attachment1 = a1
				chain.Width0 = 1.4
				chain.Width1 = 0.6
				chain.FaceCamera = true
				chain.LightEmission = 1
				chain.Segments = 1
				chain.Color = ColorSequence.new(WHITE, GOLD)
				chain.Transparency = NumberSequence.new(0.15)
				chain.Parent = core.Root
				dashCast:Add(a0)
				dashCast:Add(a1)
				dashCast:Add(chain)
				shock(r.Position - Vector3.new(0, 2.5, 0), WHITE, 2, 14, 0.3, true)
				burst(r.Position, 24, true)
				Audio.Emit(actor, "TeleportWarp", core.Root, { VolumeScale = 0.7 })
				Runtime.Knockback(
					actor,
					character,
					direction,
					{ Speed = speed, Lift = 2, Duration = duration, Sustain = duration, ContainsArena = true }
				)
				task.wait(duration + 0.05)
				Status.ReleaseRestraint(character, cast)
				local finished = valid() and core.Alive(character)
				a0:Destroy()
				a1:Destroy()
				chain:Destroy()
				return finished
			end

			local consumed = false
			local function trigger(character)
				 
				captured = character
				actor:SetAttribute("P3CloneTrapActive", false)
				actor:SetAttribute("P3CloneTrapTriggers", 1)
				if decoy then
					decoy:Destroy()
					decoy = nil
				end
				table.clear(contactParts)
				local ok, err = xpcall(function()
					if not pull(character, cast) then
						return
					end
					local deadline = os.clock() + 8
					while
						valid()
						and core.Alive(character)
						and (actor:GetAttribute("AttackInProgress") or actor:GetAttribute("ExecutionLocked"))
					do
						if os.clock() >= deadline then
							return
						end
						task.wait(0.05)
					end
					local dash = dashApi()
					if not valid() or not dash or not dash.CanUse(character) then
						return
					end
					local token = tostring({})
					actor:SetAttribute("ActiveAttackToken", token)
					actor:SetAttribute("AttackInProgress", true)
					actor:SetAttribute("CurrentAttackFile", DASH_NAME)
					local success, result = xpcall(dash.Combo, debug.traceback, character, { Instant = true })
					if
						actor.Parent
						and (actor:GetAttribute("PhaseGeneration") or 0) == generation
						and actor:GetAttribute("ActiveAttackToken") == token
					then
						actor:SetAttribute("AttackInProgress", false)
						actor:SetAttribute("ActiveAttackToken", nil)
						actor:SetAttribute(
							"NextAttackAt",
							workspace:GetServerTimeNow() + Config.Phase3NormalAttackInterval
						)
					end
					if not success then
						warn("P3Clone dash: " .. tostring(result))
					end
				end, debug.traceback)
				cast:Dispose()
				if not ok then
					warn("P3Clone contact: " .. tostring(err))
				end
			end
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Include
			local elapsed = 0
			cast:Step(function(dt)
				if not valid() then
					cast:Dispose()
					return false
				end
				if consumed then
					return true
				end
				elapsed += dt
				if elapsed < 0.05 then
					return true
				end
				elapsed = 0
				local characters = {}
				for _, character in ipairs(core.Characters()) do
					local player = Players:GetPlayerFromCharacter(character)
					if
						player
						and player.Character == character
						and core.Alive(character)
						and not character:GetAttribute("PickThePupilsCaptured")
						and not character:GetAttribute("EtherealOrbitActive")
					then
						table.insert(characters, character)
					end
				end
				overlap.FilterDescendantsInstances = characters
				for _, body in ipairs(contactParts) do
					if body.Parent then
						for _, hit in ipairs(workspace:GetPartBoundsInBox(body.CFrame, body.Size + Vector3.one * (Config.P3CloneTrapContactPadding or 3) * 2, overlap)) do
							local character = hit:FindFirstAncestorOfClass("Model")
							if character and table.find(characters, character) then
								consumed = true
								 
								if decoy then
									decoy:Destroy()
									decoy = nil
								end
								task.spawn(trigger, character)
								return true
							end
						end
					end
				end
				return true
			end)
			 
			return true
		end)
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
	end
	return api
end

