-- Client-only world VFX at the owner's toilet: whirlpool, gulp, water geyser, splash rings,
-- bubbles, foam, stars, style pieces, style specials (ducks, rainbow, lightning, cannons,
-- tornado, rocket), light pillar and a comet that carries the drop out of the bowl and
-- bounces where it lands. One pooled rig is built on first use and re-positioned per flush;
-- per-frame work is property writes only (no instance creation).
local Shared = game.ReplicatedStorage.Shared
local Assets = require(Shared.Config.Assets)
local Rules = require(Shared.FlushFxRules)
local ToiletRig = require(script.Parent.ToiletRig)
local World = {}

local function rgb(values)
	return Color3.fromRGB(values[1], values[2], values[3])
end

local function sequence(a, b)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

-- Colour sequence through a palette (cycles over particle lifetime for variety).
local function paletteSequence(palette)
	if #palette == 1 then
		return ColorSequence.new(rgb(palette[1]))
	end
	local points = {}
	for i, value in ipairs(palette) do
		table.insert(points, ColorSequenceKeypoint.new((i - 1) / (#palette - 1), rgb(value)))
	end
	return ColorSequence.new(points)
end

function World.new(config)
	local self = {}
	local white = Color3.new(1, 1, 1)
	local water, foam = rgb(config.Colors.Water), rgb(config.Colors.Foam)
	local special = config.Special
	local rig, job, toilet
	local styleColors = {}
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
	local function ellipsoid(parent)
		local mesh = Instance.new("SpecialMesh")
		mesh.Name, mesh.MeshType = "Ellipsoid", Enum.MeshType.Sphere
		mesh.Parent = parent
		return mesh
	end
	local function duck(folder, index)
		local body = part(folder, "FlushFxDuck", Vector3.new(1.6, 1.3, 1.9))
		body.Material, body.Color = Enum.Material.SmoothPlastic, rgb({ 255, 214, 40 })
		ellipsoid(body)
		local head = part(body, "Head", Vector3.new(1, 1, 1))
		head.Shape, head.Material, head.Color = Enum.PartType.Ball, Enum.Material.SmoothPlastic, rgb({ 255, 225, 70 })
		local beak = part(body, "Beak", Vector3.new(0.6, 0.25, 0.5))
		beak.Material, beak.Color = Enum.Material.SmoothPlastic, rgb({ 255, 130, 30 })
		ellipsoid(beak)
		return { Body = body, Head = head, Beak = beak, Index = index }
	end
	local function build()
		local folder = Instance.new("Folder")
		folder.Name = "FlushFx"
		local anchor = part(folder, "FlushFxBowl", Vector3.new(4, 0.2, 4))
		local center = attachment(anchor, "Center")
		local textures = Assets.Textures
		local emitters = {
			-- Disc surface, inward: droplets converge on the drain during the wind-up.
			Drain = emitter(anchor, "Drain", textures.Glow, {
				Shape = Enum.ParticleEmitterShape.Disc,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
				ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
				EmissionDirection = Enum.NormalId.Top,
				Lifetime = NumberRange.new(0.28, 0.35),
				Size = sequence(0.45, 0.1),
				Transparency = sequence(0.1, 0.8),
				LightEmission = 0.6,
			}),
			-- Flat spinning ring that shrinks into the drain: the whirlpool.
			Vortex = emitter(center, "Vortex", textures.Vortex, {
				Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				EmissionDirection = Enum.NormalId.Top,
				Speed = NumberRange.new(0.05),
				Lifetime = NumberRange.new(0.5),
				RotSpeed = NumberRange.new(-720, -540),
				Rotation = NumberRange.new(0, 360),
				LightEmission = 0.8,
				Transparency = sequence(0, 0.5),
			}),
			-- Flat expanding rings on the water surface.
			Shockwave = emitter(center, "Shockwave", textures.Shockwave, {
				Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				EmissionDirection = Enum.NormalId.Top,
				Speed = NumberRange.new(0.05),
				Lifetime = NumberRange.new(0.45, 0.8),
				LightEmission = 1,
				Transparency = sequence(0, 1),
			}),
			Core = emitter(center, "Core", textures.Glow, {
				Speed = NumberRange.new(0),
				Lifetime = NumberRange.new(0.25, 0.35),
				LightEmission = 1,
				Brightness = 3,
				Transparency = sequence(0, 1),
				ZOffset = 1,
			}),
			-- The water column: fast, narrow, stretched droplets falling back under gravity.
			Geyser = emitter(center, "Geyser", textures.Glow, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(7, 7),
				Lifetime = NumberRange.new(0.9, 1.2),
				Drag = 0.2,
				Squash = sequence(-0.6, 0.4),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.7, 0.15),
					NumberSequenceKeypoint.new(1, 1),
				}),
				LightEmission = 0.45,
				Brightness = 1.4,
			}),
			Splash = emitter(center, "Splash", textures.Glow, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(55, 55),
				Lifetime = NumberRange.new(0.6, 0.95),
				Drag = 0.5,
				Squash = sequence(0.8, 0),
				Transparency = sequence(0, 0.5),
				LightEmission = 0.4,
				Brightness = 1.4,
			}),
			-- Big soft foam puffs pushed over the rim.
			Foam = emitter(center, "Foam", textures.Smoke, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(80, 80),
				Lifetime = NumberRange.new(0.8, 1.1),
				Drag = 2.5,
				RotSpeed = NumberRange.new(-90, 90),
				Rotation = NumberRange.new(0, 360),
				Transparency = sequence(0.05, 1),
				LightEmission = 0.3,
				Brightness = 1.6,
			}),
			-- Rising bubbles (ring texture reads as a bubble outline).
			Bubbles = emitter(center, "Bubbles", textures.Shockwave, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(65, 65),
				Lifetime = NumberRange.new(1, 1.6),
				Drag = 1.6,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.85, 0.1),
					NumberSequenceKeypoint.new(1, 1),
				}),
				LightEmission = 0.6,
				Brightness = 1.5,
			}),
			Stars = emitter(center, "Stars", textures.Sparkle, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(180, 180),
				Lifetime = NumberRange.new(0.7, 1.2),
				Drag = 2,
				RotSpeed = NumberRange.new(-300, 300),
				Rotation = NumberRange.new(0, 360),
				Transparency = sequence(0, 1),
				LightEmission = 1,
				Brightness = 2,
			}),
			-- Style-shaped pieces (texture, size, motion set per flush from the style).
			Pieces = emitter(center, "Pieces", textures.Sparkle, {
				EmissionDirection = Enum.NormalId.Top,
				Rotation = NumberRange.new(0, 360),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.8, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				LightEmission = 0.4,
				Brightness = 1.3,
			}),
			Sparks = emitter(center, "Sparks", textures.Sparkle, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(75, 75),
				Lifetime = NumberRange.new(0.6, 1.1),
				Drag = 2.5,
				RotSpeed = NumberRange.new(-180, 180),
				Transparency = sequence(0, 1),
				LightEmission = 1,
			}),
			Mist = emitter(center, "Mist", textures.Smoke, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(40, 40),
				Lifetime = NumberRange.new(0.5, 0.75),
				Drag = 3,
				Transparency = sequence(0.4, 1),
				RotSpeed = NumberRange.new(-60, 60),
			}),
			Confetti = emitter(center, "Confetti", textures.Sparkle, {
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(38, 38),
				Lifetime = NumberRange.new(1, 1.4),
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
			-- Tornado rings rising and widening around the spinning toilet.
			Twister = emitter(center, "Twister", textures.Vortex, {
				Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				EmissionDirection = Enum.NormalId.Top,
				Lifetime = NumberRange.new(0.9, 1.1),
				RotSpeed = NumberRange.new(-900, -700),
				Rotation = NumberRange.new(0, 360),
				LightEmission = 0.9,
				Transparency = sequence(0.05, 1),
			}),
		}
		-- Confetti cannons left and right of the bowl, tilted outward.
		local cannons = {}
		for i, side in ipairs({ -1, 1 }) do
			local mount = attachment(anchor, "Cannon")
			mount.CFrame = CFrame.Angles(0, 0, -side * special.CannonTilt)
			cannons[i] = {
				Side = side,
				Mount = mount,
				Emitter = emitter(mount, "CannonPieces", textures.Sparkle, {
					EmissionDirection = Enum.NormalId.Top,
					Rotation = NumberRange.new(0, 360),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.8, 0),
						NumberSequenceKeypoint.new(1, 1),
					}),
					LightEmission = 0.4,
				}),
				Smoke = emitter(mount, "CannonSmoke", textures.Smoke, {
					EmissionDirection = Enum.NormalId.Top,
					SpreadAngle = Vector2.new(20, 20),
					Lifetime = NumberRange.new(0.5, 0.7),
					Drag = 4,
					Transparency = sequence(0.2, 1),
					Color = ColorSequence.new(white),
				}),
			}
		end
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
		-- Rainbow: concentric curved beams whose curve handles point up (attachment X = up).
		local rainbow = {}
		for i = 1, special.RainbowBands do
			local a0, a1 = attachment(anchor, "RainbowStart"), attachment(anchor, "RainbowEnd")
			a0.CFrame, a1.CFrame = CFrame.Angles(0, 0, math.pi / 2), CFrame.Angles(0, 0, math.pi / 2)
			local band = beam(anchor, "RainbowBand", a0, a1)
			band.FaceCamera, band.Segments = false, 24
			band.Transparency = NumberSequence.new(0.05)
			rainbow[i] = { Beam = band, A0 = a0, A1 = a1 }
		end
		-- Lightning: a jagged chain of beams from the sky into the bowl.
		local bolt = {}
		for i = 1, special.LightningPoints do
			bolt[i] = { Point = attachment(anchor, "BoltPoint") }
		end
		for i = 1, special.LightningPoints - 1 do
			local segment = beam(anchor, "BoltSegment", bolt[i].Point, bolt[i + 1].Point)
			segment.Transparency = NumberSequence.new(0)
			segment.Color = ColorSequence.new(rgb({ 200, 235, 255 }), white)
			bolt[i].Beam = segment
		end
		local ducks = {}
		for i = 1, config.Caps.Props do
			ducks[i] = duck(folder, i)
		end
		local comet = part(folder, "FlushFxComet", Vector3.new(1.6, 1.6, 1.6))
		-- A sphere SpecialMesh (unlike a Ball part) can be non-uniform for the bounce squash.
		comet.Material = Enum.Material.Neon
		ellipsoid(comet)
		local tail0, tail1 = attachment(comet, "Tail0"), attachment(comet, "Tail1")
		tail0.Position, tail1.Position = Vector3.new(0, 0.7, 0), Vector3.new(0, -0.7, 0)
		local trail = Instance.new("Trail")
		trail.Name, trail.Attachment0, trail.Attachment1 = "CometTrail", tail0, tail1
		trail.Lifetime, trail.MinLength, trail.FaceCamera = 0.45, 0.05, true
		trail.LightEmission, trail.LightInfluence, trail.Enabled = 1, 0, false
		trail.Transparency = sequence(0, 1)
		trail.WidthScale = sequence(1, 0)
		trail.Parent = comet
		local cometCenter = attachment(comet, "Center")
		local land = emitter(cometCenter, "LandSparks", textures.Sparkle, {
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.5, 0.8),
			Speed = NumberRange.new(8, 16),
			Drag = 3,
			Transparency = sequence(0, 1),
			LightEmission = 1,
		})
		local firework = emitter(cometCenter, "Firework", textures.Sparkle, {
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.9, 1.3),
			Drag = 1.8,
			Acceleration = Vector3.new(0, -6, 0),
			Transparency = sequence(0, 1),
			LightEmission = 1,
			Brightness = 3,
		})
		folder.Parent = workspace
		rig = {
			Folder = folder,
			Anchor = anchor,
			Center = center,
			Emitters = emitters,
			Cannons = cannons,
			Light = light,
			PillarTop = pillarTop,
			Pillar = pillar,
			Fan = fan,
			Rainbow = rainbow,
			Bolt = bolt,
			Ducks = ducks,
			Comet = comet,
			Trail = trail,
			Land = land,
			Firework = firework,
		}
		toilet = ToiletRig.new(config, folder)
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
		local model = foot.Parent and foot.Parent:FindFirstChild("Toilet")
		if model and model:IsA("Model") then
			local _, size = model:GetBoundingBox()
			height = size.Y
			bowlHeight = size.Y * config.Bowl.Height
			width = math.min(size.X, size.Z) * config.Bowl.Width
			forward = size.Z * config.Bowl.Forward
		else
			model = nil
		end
		local land = config.Land
		return {
			Base = base,
			Bowl = base * CFrame.new(0, bowlHeight, forward),
			Land = base * CFrame.new(land[1], land[2], land[3]),
			Height = height,
			Width = width,
			Toilet = model,
		}
	end

	local function colors(color)
		return ColorSequence.new(color:Lerp(white, 0.35), color)
	end
	local function palette(styleName)
		local cached = styleColors[styleName]
		if not cached then
			local style = config.Styles[styleName]
			cached = {
				Sequence = paletteSequence(style.Palette),
				First = rgb(style.Palette[1]),
				Last = rgb(style.Palette[#style.Palette]),
			}
			styleColors[styleName] = cached
		end
		return cached
	end
	local function emit(ledger, now, object, count, lifetime)
		local granted = ledger:Grant(now, count, lifetime)
		if granted > 0 then
			object:Emit(granted)
		end
		return granted
	end
	-- Rate-based stream over a window (columns and twisters) that still reserves budget.
	local function stream(state, object, count, lifetime, window)
		local granted = state.Ledger:Grant(state.Now, count, window + lifetime)
		if granted > 0 then
			object.Rate = granted / window
			object.Enabled = true
			table.insert(state.Streams, { Emitter = object, Until = state.Now + window })
		end
		return granted
	end

	local function hideDucks()
		for _, d in ipairs(rig.Ducks) do
			d.Body.Transparency, d.Head.Transparency, d.Beak.Transparency = 1, 1, 1
		end
	end
	local function reset()
		if not rig then
			return
		end
		for _, key in ipairs({ "Drain", "Geyser", "Twister" }) do
			rig.Emitters[key].Enabled = false
		end
		rig.Light.Enabled, rig.Light.Brightness = false, 0
		rig.Pillar.Enabled, rig.Pillar.Width0, rig.Pillar.Width1 = false, 0, 0
		for _, ray in ipairs(rig.Fan) do
			ray.Beam.Enabled, ray.Beam.Width0, ray.Beam.Width1 = false, 0, 0
		end
		for _, band in ipairs(rig.Rainbow) do
			band.Beam.Enabled = false
		end
		for i = 1, #rig.Bolt - 1 do
			rig.Bolt[i].Beam.Enabled = false
		end
		hideDucks()
		rig.Comet.Transparency, rig.Trail.Enabled = 1, false
		if toilet then
			toilet:Stop()
		end
	end

	-- Style pieces (shape, speed and gravity from the style's Pieces table).
	local function shapePieces(object, state, look, sizeMul)
		local style = config.Styles[state.Plan.Style]
		local p = style.Pieces
		local scale, height = state.Scale, state.Height
		object.Texture = Assets.Textures[p.Texture] or Assets.Textures.Glow
		object.Size = sequence(scale * p.Size * sizeMul, scale * p.Size * 0.6 * sizeMul)
		object.Speed = NumberRange.new(height * p.Speed * 0.7, height * p.Speed * 1.1)
		object.SpreadAngle = Vector2.new(p.Spread, p.Spread)
		object.Acceleration = Vector3.new(0, -height * p.Gravity, 0)
		object.Lifetime = NumberRange.new(p.Lifetime * 0.8, p.Lifetime)
		object.RotSpeed = NumberRange.new(-p.Spin, p.Spin)
		object.Drag = 0.6
		object.Color = look.Sequence
		return p.Lifetime
	end

	local function burst(state)
		local plan, scale, emitters, now, ledger = state.Plan, state.Scale, rig.Emitters, state.Now, state.Ledger
		local height = state.Height
		local look = palette(plan.Style)
		emitters.Drain.Enabled = false
		emitters.Core.Size = sequence(scale * 0.6, scale * 2.4)
		emit(ledger, now, emitters.Core, plan.Core, 0.35)
		emitters.Shockwave.Size = sequence(scale * 0.5, scale * 4.5)
		emit(ledger, now, emitters.Shockwave, plan.Shockwaves, 0.8)
		-- Geyser first: it is the headline of every flush.
		local rise = height * plan.GeyserHeight
		local speed = math.sqrt(2 * rise * height * 4)
		emitters.Geyser.Speed = NumberRange.new(speed * 0.85, speed * 1.05)
		emitters.Geyser.Acceleration = Vector3.new(0, -height * 4, 0)
		emitters.Geyser.Size = sequence(scale * 0.55, scale * 0.25)
		stream(state, emitters.Geyser, plan.Geyser, 1.2, 0.35 * math.max(plan.TimeScale, 0.5))
		emitters.Splash.Size = sequence(scale * 0.4, scale * 0.12)
		emitters.Splash.Speed = NumberRange.new(height * 1.1, height * 1.8)
		emitters.Splash.Acceleration = Vector3.new(0, -height * 3.4, 0)
		emit(ledger, now, emitters.Splash, plan.Splash, 0.95)
		if plan.Special == "Cannons" then
			local each = math.floor(plan.Pieces / 2)
			for _, cannon in ipairs(rig.Cannons) do
				local life = shapePieces(cannon.Emitter, state, look, 1)
				cannon.Emitter.Speed = NumberRange.new(height * 1.6, height * 2.4)
				emit(ledger, now, cannon.Emitter, each, life)
				cannon.Smoke.Size = sequence(scale * 0.5, scale * 1.4)
				cannon.Smoke.Speed = NumberRange.new(height * 0.3, height * 0.6)
				emit(ledger, now, cannon.Smoke, 3, 0.7)
			end
		else
			local life = shapePieces(emitters.Pieces, state, look, 1)
			emit(ledger, now, emitters.Pieces, plan.Pieces, life)
		end
		emitters.Stars.Color = look.Sequence
		emitters.Stars.Size = sequence(scale * 0.45, 0)
		emitters.Stars.Speed = NumberRange.new(height * 0.6, height * 1.3)
		emit(ledger, now, emitters.Stars, plan.Stars, 1.2)
		emitters.Bubbles.Size = sequence(scale * 0.2, scale * 0.55)
		emitters.Bubbles.Speed = NumberRange.new(height * 0.5, height * 1)
		emitters.Bubbles.Acceleration = Vector3.new(0, height * 0.6, 0)
		emit(ledger, now, emitters.Bubbles, plan.Bubbles, 1.6)
		emitters.Foam.Size = sequence(scale * 0.7, scale * 1.6)
		emitters.Foam.Speed = NumberRange.new(height * 0.3, height * 0.6)
		emit(ledger, now, emitters.Foam, plan.Foam, 1.1)
		emitters.Sparks.Speed = NumberRange.new(height * 0.7, height * 1.5)
		emitters.Sparks.Size = sequence(scale * 0.3, 0)
		emit(ledger, now, emitters.Sparks, plan.Sparks, 1.1)
		emitters.Mist.Speed = NumberRange.new(height * 0.25, height * 0.45)
		emitters.Mist.Size = sequence(scale * 0.6, scale * 1.4)
		emit(ledger, now, emitters.Mist, plan.Mist, 0.75)
		if plan.Confetti > 0 then
			emitters.Confetti.Speed = NumberRange.new(height * 1.3, height * 2.1)
			emitters.Confetti.Acceleration = Vector3.new(0, -height * 1.2, 0)
			emitters.Confetti.Size = NumberSequence.new(scale * 0.2)
			emit(ledger, now, emitters.Confetti, plan.Confetti, 1.4)
		end
		if plan.Special == "Tornado" and plan.Props > 0 then
			local twister = emitters.Twister
			twister.Color = look.Sequence
			twister.Speed = NumberRange.new(height * 0.9, height * 1.2)
			twister.Size = sequence(scale * 0.9, scale * 3)
			-- Streamed over a window so the rings climb the toilet one after another.
			stream(
				state,
				twister,
				plan.Props * special.TornadoRings,
				1.1,
				special.TornadoWindow * math.max(plan.TimeScale, 0.5)
			)
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
			Exploded = false,
			Streams = {},
			NextBolt = 0,
		}
		local emitters = rig.Emitters
		if plan.Underlay then
			-- A bigger moment owns colours, light, beams and comet; add only a water splash.
			-- Emitter colours are left alone because recolouring affects live particles.
			emitters.Splash.Speed = NumberRange.new(target.Height * 0.8, target.Height * 1.2)
			emitters.Splash.Acceleration = Vector3.new(0, -target.Height * 3.4, 0)
			emit(ledger, now, emitters.Splash, plan.Splash, 0.95)
			emit(ledger, now, emitters.Mist, plan.Mist, 0.75)
			emit(ledger, now, emitters.Bubbles, plan.Bubbles, 1.6)
			return true
		end
		local tint = colors(color)
		emitters.Core.Color, emitters.Sparks.Color, emitters.Shockwave.Color = tint, tint, tint
		local look = palette(plan.Style)
		emitters.Geyser.Color = ColorSequence.new(foam, water:Lerp(look.First, 0.5))
		emitters.Splash.Color = ColorSequence.new(foam, water:Lerp(color, 0.35))
		emitters.Mist.Color = ColorSequence.new(foam)
		emitters.Foam.Color = ColorSequence.new(white, foam:Lerp(look.First, 0.25))
		emitters.Bubbles.Color = ColorSequence.new(white, water:Lerp(look.Last, 0.4))
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
		for _, cannon in ipairs(rig.Cannons) do
			cannon.Mount.Position = Vector3.new(cannon.Side * target.Width * special.CannonSpread, 0.2, 0)
		end
		if plan.Vortex > 0 then
			local spin = math.max(plan.WindUp, 0.18) + 0.25
			emitters.Vortex.Lifetime = NumberRange.new(spin)
			emitters.Vortex.Size = sequence(scale * 1.4, scale * 0.15)
			emit(ledger, now, emitters.Vortex, plan.Vortex, spin)
		end
		emitters.Drain.Speed = NumberRange.new(scale / 0.35, scale / 0.28)
		emitters.Drain.Size = sequence(scale * 0.25, scale * 0.06)
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
		if plan.Special == "Rainbow" then
			local styleData = config.Styles[plan.Style]
			local span, w = target.Height * special.RainbowSpan, scale * 0.45
			for i, band in ipairs(rig.Rainbow) do
				local offset = (i - 1) * w
				band.A0.Position = Vector3.new(-offset * 0.5, 0.3, 0)
				band.A1.Position = Vector3.new(span + offset * 0.5, -target.Height * 0.3, 0)
				local lift = target.Height * special.RainbowHeight + offset
				band.Beam.CurveSize0, band.Beam.CurveSize1 = lift, -lift
				band.Beam.Color = ColorSequence.new(rgb(styleData.Palette[(i - 1) % #styleData.Palette + 1]))
				band.Beam.Width0, band.Beam.Width1 = 0, 0
				band.Beam.Enabled = true
			end
		end
		rig.Comet.Color = color
		local cometSize = scale * config.CometSize
		rig.Comet.Size = Vector3.new(cometSize, cometSize, cometSize)
		rig.Comet.CFrame = target.Bowl
		rig.Trail.Color = colors(color)
		rig.Trail:Clear()
		rig.Land.Color = colors(color)
		rig.Firework.Color = look.Sequence
		state.CometSize = cometSize
		toilet:Play(plan, target, now)
		job = state
		self:Step(now)
		return true
	end

	local function stepDucks(state, t)
		local plan, target = state.Plan, state.Target
		local after = t - plan.Burst
		local count = math.min(plan.Props, #rig.Ducks)
		local s = target.Height * special.DuckSize
		local radius = target.Width * special.DuckRadius
		local launch = special.DuckLaunch * math.max(plan.TimeScale, 0.5)
		local stop = (plan.Duration - plan.Burst) * special.DuckParade
		local bowl = target.Bowl.Position
		for i = 1, count do
			local d = rig.Ducks[i]
			local start = (i - 1) * 0.07 * math.max(plan.TimeScale, 0.5)
			local local_t = after - start
			if local_t < 0 or after >= stop then
				d.Body.Transparency, d.Head.Transparency, d.Beak.Transparency = 1, 1, 1
			else
				local angle = (i / count) * 2 * math.pi + local_t * 1.6
				local ring = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				local position
				if local_t < launch then
					local u = local_t / launch
					position = bowl
						+ ring * u
						+ Vector3.new(0, Rules.ArcHeight(u, target.Height * 0.7) - target.Height * 0.25 * u, 0)
				else
					local hop = math.abs(math.sin((local_t - launch) * 9 + i))
					position = bowl + ring + Vector3.new(0, -target.Height * 0.25 + hop * s * 1.2, 0)
				end
				local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
				local frame = CFrame.lookAt(position, position + tangent)
				d.Body.Size = Vector3.new(s * 1.6, s * 1.3, s * 1.9)
				d.Head.Size = Vector3.new(s, s, s)
				d.Beak.Size = Vector3.new(s * 0.6, s * 0.25, s * 0.5)
				d.Body.CFrame = frame
				d.Head.CFrame = frame * CFrame.new(0, s * 0.9, -s * 0.7)
				d.Beak.CFrame = frame * CFrame.new(0, s * 0.8, -s * 1.3)
				d.Body.Transparency, d.Head.Transparency, d.Beak.Transparency = 0, 0, 0
			end
		end
	end

	local function stepBolt(state, t, now)
		local plan, target = state.Plan, state.Target
		local after = t - plan.Burst
		local window = special.LightningTime * math.max(plan.TimeScale, 0.5)
		local live = after >= -0.05 and after < window
		local points = rig.Bolt
		if live and now >= state.NextBolt then
			state.NextBolt = now + 1 / special.LightningHz
			state.BoltSeed = (state.BoltSeed or 0) + 1
			local n, top = #points, target.Height * special.LightningHeight
			for i, point in ipairs(points) do
				local u = (i - 1) / (n - 1)
				local jitter = if i == 1 or i == n then 0 else target.Height * special.LightningJitter
				local seed = state.BoltSeed * 13.37 + i * 7.1
				point.Point.Position =
					Vector3.new(math.sin(seed) * jitter, top * (1 - u), math.cos(seed * 1.7) * jitter)
			end
		end
		local flicker = live and (math.floor(after * 30) % 3 ~= 2)
		for i = 1, #points - 1 do
			local segment = points[i].Beam
			segment.Enabled = flicker
			if flicker then
				segment.Width0, segment.Width1 = state.Scale * 0.5, state.Scale * 0.5
			end
		end
	end

	-- Advances the active moment; returns true while it still needs updates.
	function self:Step(now)
		local state = job
		if not state or not rig then
			return false
		end
		local plan, t = state.Plan, now - state.Start
		state.Now = now
		toilet:Step(now)
		for i = #state.Streams, 1, -1 do
			local entry = state.Streams[i]
			if now >= entry.Until then
				entry.Emitter.Enabled = false
				table.remove(state.Streams, i)
			end
		end
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
			-- Small glow while it gulps, then the flash (lightning flickers it).
			local boost = if plan.Special == "Lightning"
					and after >= 0
					and after < special.LightningTime
				then 1 + (math.floor(after * 30) % 2) * 1.5
				else 1
			rig.Light.Brightness = if after < 0
				then plan.Light * 0.25 * (t / math.max(plan.Burst, 0.01))
				else plan.Light * envelope * boost
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
		if plan.Special == "Rainbow" then
			local u = math.clamp(after / (special.RainbowTime * math.max(plan.TimeScale, 0.5)), 0, 1)
			local width = state.Scale * 0.5 * Rules.Pulse(u, 0.2, 0.8) ^ 0.5
			for _, band in ipairs(rig.Rainbow) do
				band.Beam.Width0, band.Beam.Width1 = width, width
			end
		elseif plan.Special == "Lightning" then
			stepBolt(state, t, now)
		elseif plan.Special == "Ducks" then
			stepDucks(state, t)
		end
		if plan.Comet then
			local target = state.Target
			if after >= 0 and not state.Landed then
				local u = Rules.Hang(after / plan.CometTime, plan.Hang)
				local from, to = target.Bowl.Position, target.Land.Position
				local position = from
					+ (to - from) * u
					+ Vector3.new(0, Rules.ArcHeight(u, state.Height * plan.CometApex), 0)
				rig.Comet.CFrame = CFrame.new(position)
				if after > 0 then
					rig.Comet.Transparency = 0
					rig.Trail.Enabled = true
				end
				if plan.Special == "Rocket" and not state.Exploded and u >= 0.5 then
					state.Exploded = true
					rig.Firework.Speed = NumberRange.new(state.Height * 0.8, state.Height * 1.4)
					rig.Firework.Size = sequence(state.Scale * 0.5, 0)
					emit(state.Ledger, now, rig.Firework, plan.Stars, 1.3)
				end
				if after >= plan.CometTime then
					state.Landed, state.LandedAt = true, now
					rig.Comet.CFrame = CFrame.new(to)
					emit(state.Ledger, now, rig.Land, plan.LandSparks, 0.8)
					rig.Trail.Enabled = false
					rig.Comet.Transparency = if plan.BounceTime > 0 then 0 else 1
				end
			elseif state.Landed and rig.Comet.Transparency < 1 then
				-- Bouncing landing with squash-and-stretch.
				local u = (now - state.LandedAt) / math.max(plan.BounceTime, 0.01)
				if u >= 1 then
					rig.Comet.Transparency = 1
				else
					local h, squash = Rules.Bounce(u)
					local size, xz = state.CometSize, 1 / math.sqrt(squash)
					rig.Comet.Size = Vector3.new(size * xz, size * squash, size * xz)
					rig.Comet.CFrame = CFrame.new(
						target.Land.Position
							+ Vector3.new(0, h * state.Height * config.BounceHeight - size * (1 - squash) * 0.5, 0)
					)
				end
			end
		end
		return true
	end

	function self:Busy()
		return job ~= nil
	end
	function self:Stop()
		if job then
			for _, entry in ipairs(job.Streams) do
				entry.Emitter.Enabled = false
			end
		end
		job = nil
		reset()
	end
	function self:Destroy()
		job = nil
		if toilet then
			toilet:Destroy()
			toilet = nil
		end
		if rig then
			rig.Folder:Destroy()
			rig = nil
		end
	end
	return self
end
return World
