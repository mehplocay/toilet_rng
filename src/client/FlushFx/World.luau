-- Client-only world VFX at the owner's toilet: whirlpool, gulp, burst, light pillar and a
-- comet that carries the drop out of the bowl. One pooled rig is built on first use and
-- re-positioned per flush; per-frame work is property writes only (no instance creation).
local Shared = game.ReplicatedStorage.Shared
local Assets = require(Shared.Config.Assets)
local Rules = require(Shared.FlushFxRules)
local World = {}

local function rgb(values)
	return Color3.fromRGB(values[1], values[2], values[3])
end

local function sequence(a, b)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

function World.new(config)
	local self = {}
	local white = Color3.new(1, 1, 1)
	local water, foam = rgb(config.Colors.Water), rgb(config.Colors.Foam)
	local rig, job
	local function part(parent, name, size)
		local object = Instance.new("Part")
		object.Name, object.Size = name, size
		object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
		object.CastShadow, object.Transparency = false, 1
		object.Parent = parent
		return object
	end
	local function attachment(parent, name)
		local object = Instance.new("Attachment")
		object.Name, object.Parent = name, parent
		return object
	end
	local function emitter(parent, name, texture, props)
		local object = Instance.new("ParticleEmitter")
		object.Name, object.Texture = name, texture
		object.Enabled, object.Rate = false, 0
		object.LightInfluence = 0
		for key, value in pairs(props) do
			object[key] = value
		end
		object.Parent = parent
		return object
	end
	local function beam(parent, name, a0, a1)
		local object = Instance.new("Beam")
		object.Name, object.Attachment0, object.Attachment1 = name, a0, a1
		object.FaceCamera, object.LightEmission, object.LightInfluence = true, 1, 0
		object.Segments, object.Width0, object.Width1 = 1, 0, 0
		object.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.6, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		object.Enabled = false
		object.Parent = parent
		return object
	end
	local function build()
		local folder = Instance.new("Folder")
		folder.Name = "FlushFx"
		local anchor = part(folder, "FlushFxBowl", Vector3.new(4, 0.2, 4))
		local center = attachment(anchor, "Center")
		local emitters = {
			-- Disc surface, inward: droplets converge on the drain during the wind-up.
			Drain = emitter(anchor, "Drain", Assets.Textures.Glow, {
				Shape = Enum.ParticleEmitterShape.Disc,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
				ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
				EmissionDirection = Enum.NormalId.Top,
				Lifetime = NumberRange.new(0.28, 0.35),
				Size = sequence(0.45, 0.1),
				Transparency = sequence(0.2, 0.9),
				LightEmission = 0.6,
			}),
			-- Flat spinning ring that shrinks into the drain: the whirlpool.
			Vortex = emitter(center, "Vortex", Assets.Textures.Vortex, {
				Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				EmissionDirection = Enum.NormalId.Top,
				Speed = NumberRange.new(0.05),
				Lifetime = NumberRange.new(0.5),
				RotSpeed = NumberRange.new(-540, -420),
				Rotation = NumberRange.new(0, 360),
				LightEmission = 0.8,
				Transparency = sequence(0.05, 0.7),
			}),
			-- Flat expanding rings on the water surface.
			Shockwave = emitter(center, "Shockwave", Assets.Textures.Shockwave, {
				Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				EmissionDirection = Enum.NormalId.Top,
				Speed = NumberRange.new(0.05),
				Lifetime = NumberRange.new(0.35, 0.7),
				LightEmission = 1,
				Transparency = sequence(0, 1),
			}),
			Core = emitter(center, "Core", Assets.Textures.Glow, {
				Speed = NumberRange.new(0),
				Lifetime = NumberRange.new(0.22, 0.3),
				LightEmission = 1,
				Brightness = 2,
				Transparency = sequence(0, 1),
				ZOffset = 1,
			}),
			Splash = emitter(center, "Splash", Assets.Textures.Glow, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(32, 32),
				Lifetime = NumberRange.new(0.55, 0.85),
				Drag = 0.6,
				Size = sequence(0.55, 0.25),
				Squash = sequence(0.8, 0),
				Transparency = sequence(0.05, 0.6),
				LightEmission = 0.35,
			}),
			Sparks = emitter(center, "Sparks", Assets.Textures.Sparkle, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(75, 75),
				Lifetime = NumberRange.new(0.5, 1),
				Drag = 2.5,
				RotSpeed = NumberRange.new(-180, 180),
				Transparency = sequence(0, 1),
				LightEmission = 1,
			}),
			Mist = emitter(center, "Mist", Assets.Textures.Smoke, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(40, 40),
				Lifetime = NumberRange.new(0.45, 0.65),
				Drag = 3,
				Transparency = sequence(0.55, 1),
				RotSpeed = NumberRange.new(-60, 60),
			}),
			Confetti = emitter(center, "Confetti", Assets.Textures.Square, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(38, 38),
				Lifetime = NumberRange.new(1.8, 2.6),
				Drag = 1.4,
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-320, 320),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.8, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				LightEmission = 0.2,
			}),
		}
		local light = Instance.new("PointLight")
		light.Name, light.Shadows, light.Enabled, light.Brightness = "Flash", false, false, 0
		light.Range = config.LightRange
		light.Parent = center
		local pillarTop = attachment(anchor, "PillarTop")
		local pillar = beam(anchor, "Pillar", center, pillarTop)
		local fan = {}
		for i = 1, config.Caps.FanBeams do
			local top = attachment(anchor, "FanTop")
			fan[i] = { Beam = beam(anchor, "FanRay", center, top), Top = top }
		end
		local comet = part(folder, "FlushFxComet", Vector3.new(1.6, 1.6, 1.6))
		comet.Shape, comet.Material = Enum.PartType.Ball, Enum.Material.Neon
		local tail0, tail1 = attachment(comet, "Tail0"), attachment(comet, "Tail1")
		tail0.Position, tail1.Position = Vector3.new(0, 0.7, 0), Vector3.new(0, -0.7, 0)
		local trail = Instance.new("Trail")
		trail.Name, trail.Attachment0, trail.Attachment1 = "CometTrail", tail0, tail1
		trail.Lifetime, trail.MinLength, trail.FaceCamera = 0.35, 0.05, true
		trail.LightEmission, trail.LightInfluence, trail.Enabled = 1, 0, false
		trail.Transparency = sequence(0, 1)
		trail.WidthScale = sequence(1, 0)
		trail.Parent = comet
		local cometCenter = attachment(comet, "Center")
		local land = emitter(cometCenter, "LandSparks", Assets.Textures.Sparkle, {
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.4, 0.7),
			Speed = NumberRange.new(6, 12),
			Drag = 3,
			Transparency = sequence(0, 1),
			LightEmission = 1,
		})
		folder.Parent = workspace
		rig = {
			Folder = folder,
			Anchor = anchor,
			Emitters = emitters,
			Light = light,
			PillarTop = pillarTop,
			Pillar = pillar,
			Fan = fan,
			Comet = comet,
			Trail = trail,
			Land = land,
		}
	end

	-- Bowl frame for the local player's toilet, or nil when the plot is unknown.
	function self:Locate(prompts)
		local prompt = prompts and prompts.Own and prompts.Own()
		local foot = prompt and prompt.Parent
		if not foot or not foot:IsA("BasePart") then
			return nil
		end
		local base = foot.CFrame
		local height, bowlHeight, width, forward =
			config.Fallback.Height, config.Fallback.BowlHeight, config.Fallback.BowlWidth, config.Fallback.Forward
		local toilet = foot.Parent and foot.Parent:FindFirstChild("Toilet")
		if toilet and toilet:IsA("Model") then
			local _, size = toilet:GetBoundingBox()
			height = size.Y
			bowlHeight = size.Y * config.Bowl.Height
			width = math.min(size.X, size.Z) * config.Bowl.Width
			forward = size.Z * config.Bowl.Forward
		end
		local land = config.Land
		return {
			Base = base,
			Bowl = base * CFrame.new(0, bowlHeight, forward),
			Land = base * CFrame.new(land[1], land[2], land[3]),
			Height = height,
			Width = width,
		}
	end

	local function colors(color)
		return ColorSequence.new(color:Lerp(white, 0.35), color)
	end
	local function emit(ledger, now, object, count, lifetime)
		local granted = ledger:Grant(now, count, lifetime)
		if granted > 0 then
			object:Emit(granted)
		end
		return granted
	end

	local function reset()
		if not rig then
			return
		end
		rig.Emitters.Drain.Enabled = false
		rig.Light.Enabled, rig.Light.Brightness = false, 0
		rig.Pillar.Enabled, rig.Pillar.Width0, rig.Pillar.Width1 = false, 0, 0
		for _, ray in ipairs(rig.Fan) do
			ray.Beam.Enabled, ray.Beam.Width0, ray.Beam.Width1 = false, 0, 0
		end
		rig.Comet.Transparency, rig.Trail.Enabled = 1, false
	end

	local function burst(state)
		local plan, scale, emitters, now, ledger = state.Plan, state.Scale, rig.Emitters, state.Now, state.Ledger
		emitters.Drain.Enabled = false
		emitters.Core.Size = sequence(scale * 0.4, scale * 1.6)
		emit(ledger, now, emitters.Core, plan.Core, 0.3)
		emitters.Shockwave.Size = sequence(scale * 0.5, scale * 3.4)
		emit(ledger, now, emitters.Shockwave, plan.Shockwaves, 0.7)
		emitters.Splash.Size = sequence(scale * 0.3, scale * 0.1)
		emitters.Splash.Speed = NumberRange.new(state.Height * 1.1, state.Height * 1.7)
		emitters.Splash.Acceleration = Vector3.new(0, -state.Height * 3.4, 0)
		emit(ledger, now, emitters.Splash, plan.Splash, 0.85)
		emitters.Sparks.Speed = NumberRange.new(state.Height * 0.7, state.Height * 1.5)
		emitters.Sparks.Size = sequence(scale * 0.22, 0)
		emit(ledger, now, emitters.Sparks, plan.Sparks, 1)
		emitters.Mist.Speed = NumberRange.new(state.Height * 0.25, state.Height * 0.45)
		emitters.Mist.Size = sequence(scale * 0.5, scale * 1.1)
		emit(ledger, now, emitters.Mist, plan.Mist, 0.65)
		if plan.Confetti > 0 then
			emitters.Confetti.Speed = NumberRange.new(state.Height * 1.3, state.Height * 2.1)
			emitters.Confetti.Acceleration = Vector3.new(0, -state.Height * 1.2, 0)
			emitters.Confetti.Size = NumberSequence.new(scale * 0.17)
			emit(ledger, now, emitters.Confetti, plan.Confetti, 2.6)
		end
	end

	-- Starts a flush moment. Underlay plans only add one-shots beneath a bigger moment.
	function self:Play(plan, color, target, ledger, now)
		local camera = workspace.CurrentCamera
		if
			not target or (camera and (camera.CFrame.Position - target.Bowl.Position).Magnitude > config.MaxDistance)
		then
			return false
		end
		if not rig or not rig.Folder.Parent then
			build()
		end
		local scale = target.Width / 2
		local state = {
			Plan = plan,
			Color = color,
			Target = target,
			Ledger = ledger,
			Now = now,
			Start = now,
			Scale = scale,
			Height = target.Height,
			Burst = false,
			Landed = false,
		}
		local emitters = rig.Emitters
		if plan.Underlay then
			-- A bigger moment owns colours, light, beams and comet; add only a water splash.
			-- Emitter colours are left alone because recolouring affects live particles.
			emitters.Splash.Speed = NumberRange.new(target.Height * 0.8, target.Height * 1.2)
			emitters.Splash.Acceleration = Vector3.new(0, -target.Height * 3.4, 0)
			emit(ledger, now, emitters.Splash, plan.Splash, 0.85)
			emit(ledger, now, emitters.Mist, plan.Mist, 0.65)
			return true
		end
		local tint = colors(color)
		emitters.Core.Color, emitters.Sparks.Color, emitters.Shockwave.Color = tint, tint, tint
		emitters.Splash.Color = ColorSequence.new(foam, water:Lerp(color, 0.35))
		emitters.Mist.Color = ColorSequence.new(foam)
		emitters.Drain.Color = ColorSequence.new(foam, water)
		emitters.Vortex.Color = ColorSequence.new(water:Lerp(color, 0.5), foam)
		emitters.Confetti.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, rgb(config.Colors.Gold)),
			ColorSequenceKeypoint.new(1, white),
		})
		reset()
		rig.Anchor.CFrame = target.Bowl
		rig.Anchor.Size = Vector3.new(target.Width, 0.2, target.Width)
		if plan.Vortex > 0 then
			local spin = math.max(plan.WindUp, 0.18) + 0.2
			emitters.Vortex.Lifetime = NumberRange.new(spin)
			emitters.Vortex.Size = sequence(scale * 1.1, scale * 0.15)
			emit(ledger, now, emitters.Vortex, plan.Vortex, spin)
		end
		emitters.Drain.Speed = NumberRange.new(scale / 0.35, scale / 0.28)
		emitters.Drain.Size = sequence(scale * 0.22, scale * 0.05)
		if plan.WindUp > 0 and plan.Drain > 0 then
			local granted = ledger:Grant(now, plan.Drain, plan.WindUp + 0.4)
			emitters.Drain.Rate = granted / plan.WindUp
			emitters.Drain.Enabled = granted > 0
		end
		local light = rig.Light
		light.Color, light.Range = color, config.LightRange * math.max(1, scale / 3)
		light.Enabled = plan.Light > 0
		rig.Pillar.Color = colors(color)
		rig.PillarTop.Position = Vector3.new(0, target.Height * config.PillarHeight, 0)
		rig.Pillar.Enabled = plan.Pillar
		for i, ray in ipairs(rig.Fan) do
			ray.Beam.Color = colors(color)
			ray.Beam.Enabled = i <= plan.FanBeams
		end
		rig.Comet.Color = color
		rig.Comet.Size = Vector3.new(scale * 0.55, scale * 0.55, scale * 0.55)
		rig.Comet.CFrame = target.Bowl
		rig.Trail.Color = colors(color)
		rig.Trail:Clear()
		rig.Land.Color = colors(color)
		job = state
		self:Step(now)
		return true
	end

	-- Advances the active moment; returns true while it still needs updates.
	function self:Step(now)
		local state = job
		if not state or not rig then
			return false
		end
		local plan, t = state.Plan, now - state.Start
		state.Now = now
		if t >= plan.Duration then
			job = nil
			reset()
			return false
		end
		if not state.Burst and t >= plan.Burst then
			state.Burst = true
			burst(state)
		end
		local after = t - plan.Burst
		local envelope = Rules.Pulse(after, 0.06, math.max(0.2, plan.Duration - plan.Burst - 0.06))
		if plan.Light > 0 then
			-- Small glow while it gulps, then the flash.
			rig.Light.Brightness = if after < 0
				then plan.Light * 0.25 * (t / math.max(plan.Burst, 0.01))
				else plan.Light * envelope
		end
		if plan.Pillar then
			rig.Pillar.Width0 = state.Scale * 1.2 * envelope
			rig.Pillar.Width1 = state.Scale * 2.6 * envelope
		end
		if plan.FanBeams > 0 then
			local radius, height = state.Height * config.FanRadius, state.Height * config.PillarHeight * 0.8
			for i = 1, plan.FanBeams do
				local ray = rig.Fan[i]
				local angle = i * 2 * math.pi / plan.FanBeams + t * config.FanSpin
				ray.Top.Position = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
				ray.Beam.Width0 = state.Scale * 0.35 * envelope
				ray.Beam.Width1 = state.Scale * 3 * envelope
			end
		end
		if plan.Comet then
			if after >= 0 and not state.Landed then
				local u = Rules.Hang(after / plan.CometTime, plan.Hang)
				local from, to = state.Target.Bowl.Position, state.Target.Land.Position
				local position = from
					+ (to - from) * u
					+ Vector3.new(0, Rules.ArcHeight(u, state.Height * config.CometApex), 0)
				rig.Comet.CFrame = CFrame.new(position)
				if after > 0 then
					rig.Comet.Transparency = 0
					rig.Trail.Enabled = true
				end
				if after >= plan.CometTime then
					state.Landed = true
					rig.Comet.CFrame = CFrame.new(to)
					emit(state.Ledger, now, rig.Land, plan.LandSparks, 0.7)
					rig.Comet.Transparency, rig.Trail.Enabled = 1, false
				end
			end
		end
		return true
	end

	function self:Busy()
		return job ~= nil
	end
	function self:Stop()
		job = nil
		reset()
	end
	function self:Destroy()
		job = nil
		if rig then
			rig.Folder:Destroy()
			rig = nil
		end
	end
	return self
end
return World
