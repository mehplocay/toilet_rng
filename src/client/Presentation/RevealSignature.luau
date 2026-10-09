local C = require(script.Parent.Parent.UI.Components)
local Budget = require(game.ReplicatedStorage.Shared.Config.Reveals)
local Signature = {}
local white = Color3.new(1, 1, 1)

local function ring(parent, name, size, color, thickness)
	local frame = C.New("Frame", parent, {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(size, size),
		BackgroundTransparency = 1,
	})
	C.New("UICorner", frame, { CornerRadius = UDim.new(1, 0) })
	C.New("UIStroke", frame, { Color = color, Thickness = thickness, Transparency = 0.2 })
	return frame
end

function Signature.Create(parent, config, color, mobile, cinematic)
	local kind = config.Signature
	local stage = C.New("Frame", parent, {
		Name = kind,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = if cinematic then UDim2.fromScale(0.5, 0.38) else UDim2.fromScale(0.15, 0.5),
		Size = UDim2.fromOffset(300, 300),
	})
	-- Square stage keeps halos circular and constellations undistorted on phones.
	local cracks = {}
	local function resize()
		local size = if cinematic
			then math.min(parent.AbsoluteSize.X * 0.88, parent.AbsoluteSize.Y * 0.43, 420)
			else math.min(parent.AbsoluteSize.X * 0.8, 260)
		if cinematic and parent.AbsoluteSize.Y < 360 then
			local bounds =
				require(script.Parent.Layout).Compute(parent.AbsoluteSize.X, parent.AbsoluteSize.Y, mobile).Model
			size = math.max(24, bounds.H - 12)
			stage.Position = UDim2.fromOffset(bounds.X + bounds.W / 2, bounds.Y + bounds.H / 2)
		elseif cinematic then
			stage.Position = UDim2.fromScale(0.5, 0.38)
		end
		stage.Size = UDim2.fromOffset(size, size)
		for _, crack in ipairs(cracks) do
			local a, b, line = crack[1], crack[2], crack[3]
			local dx, dy = (b[1] - a[1]) * parent.AbsoluteSize.X, (b[2] - a[2]) * parent.AbsoluteSize.Y
			line.Position = UDim2.fromScale((a[1] + b[1]) / 2, (a[2] + b[2]) / 2)
			line.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 2)
			line.Rotation = math.deg(math.atan2(dy, dx))
		end
	end
	local connection = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	stage.Destroying:Connect(function()
		connection:Disconnect()
	end)
	resize()
	local wheel, halo, core
	local swirls = {}
	local crystalScale, phase = nil, 0
	if kind == "CrystalExplosion" then
		crystalScale = C.New("UIScale", stage, { Scale = 0.12 })
		C.Tween(crystalScale, 0.18, { Scale = 1 })
	end
	if kind == "GoldenRays" or kind == "DivineCracks" then
		wheel = C.New("Frame", stage, { Name = "Rays", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
		for i = 1, 10 do
			local ray = C.New("Frame", wheel, {
				Name = "Ray",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1.7, if kind == "DivineCracks" then 0.1 else 0.065),
				Rotation = i * 18,
				BackgroundColor3 = if i % 2 == 0 then C.Gold else color,
				BackgroundTransparency = 0.5,
			})
			C.New("UIGradient", ray, {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0.2),
					NumberSequenceKeypoint.new(1, 1),
				}),
			})
		end
	end
	if kind == "Starlight" then
		halo = ring(stage, "Halo", 0.91, color, 3)
		ring(stage, "HaloInner", 0.83, white, 1)
		local points = {
			{ 0.08, 0.2 },
			{ 0.29, 0.05 },
			{ 0.7, 0.12 },
			{ 0.92, 0.32 },
			{ 0.85, 0.76 },
			{ 0.58, 0.93 },
			{
				0.13,
				0.8,
			},
		}
		for i, point in ipairs(points) do
			local nextPoint = points[i % #points + 1]
			local dx, dy = nextPoint[1] - point[1], nextPoint[2] - point[2]
			C.New("Frame", stage, {
				Name = "ConstellationLine",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale((point[1] + nextPoint[1]) / 2, (point[2] + nextPoint[2]) / 2),
				Size = UDim2.new(math.sqrt(dx * dx + dy * dy), 0, 0, 1),
				Rotation = math.deg(math.atan2(dy, dx)),
				BackgroundColor3 = color,
				BackgroundTransparency = 0.45,
			})
			local star = C.Text(stage, "+", UDim2.fromOffset(18, 18), UDim2.fromScale(point[1], point[2]), 18)
			star.Name, star.AnchorPoint, star.TextColor3 = "ConstellationStar", Vector2.new(0.5, 0.5), white
		end
	elseif kind == "RealityGlitch" then
		core = C.New("Frame", stage, {
			Name = "BlackHole",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.72, 0.72),
			BackgroundColor3 = Color3.new(0, 0, 0),
		})
		C.New("UICorner", core, { CornerRadius = UDim.new(1, 0) })
		for i = 1, 3 do
			local swirl =
				ring(stage, "AccretionRing", 0.7 + i * 0.11, if i == 2 then Color3.fromRGB(90, 230, 255) else color, 3)
			C.New("UIGradient", swirl.UIStroke, { Transparency = NumberSequence.new(0, 1), Rotation = i * 95 })
			table.insert(swirls, swirl)
		end
	elseif kind == "DivineCracks" then
		-- Connected fracture paths leave the central model/name readable.
		local points = { { 0.02, 0.16 }, { 0.1, 0.25 }, { 0.065, 0.32 }, { 0.16, 0.43 }, { 0.12, 0.54 } }
		for side = 1, 2 do
			for i = 1, #points - 1 do
				local a, b = points[i], points[i + 1]
				local line = C.New("Frame", parent, {
					Name = "ScreenCrack",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = if i % 2 == 0 then C.Gold else white,
					BackgroundTransparency = 0.2,
				})
				table.insert(cracks, {
					{ if side == 1 then a[1] else 1 - a[1], a[2] },
					{ if side == 1 then b[1] else 1 - b[1], b[2] },
					line,
				})
			end
		end
		resize()
	end
	local particles = {}
	local count = math.min(config.Particles or 0, if mobile then Budget.MobileParticleCap else Budget.ParticleCap)
	for i = 1, count do
		local crystal = kind == "CrystalExplosion"
		local star = kind == "Starlight" or kind == "RealityGlitch"
		local particle = C.New("Frame", stage, {
			Name = if crystal then "CrystalShard" elseif star then "Star" else "Confetti",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(if crystal then 10 else 4, if crystal then 27 elseif star then 4 else 11),
			Rotation = i * 31,
			BackgroundColor3 = if i % 3 == 0 then white else color,
		})
		if crystal then
			C.New("UIGradient", particle, { Color = ColorSequence.new(white, color), Rotation = 65 })
		end
		table.insert(particles, particle)
	end
	return function(t)
		if crystalScale then
			if t >= 1.1 and phase < 2 then
				phase = 2
				C.Tween(crystalScale, 0.3, { Scale = 1.25 })
			elseif t >= 0.22 and phase == 0 then
				phase = 1
				C.Tween(crystalScale, 0.88, { Scale = 1.08 })
			end
		end
		-- Fast fracture, suspended shards, then release: visual time only.
		local motion = if kind == "CrystalExplosion"
			then (if t < 0.22 then t * 3.6 elseif t < 1.1 then 0.792 + (t - 0.22) * 0.1 else 0.88 + (t - 1.1) * 0.75)
			else t
		if wheel then
			wheel.Rotation = motion * (if kind == "DivineCracks" then -12 else 25)
		end
		if halo then
			halo.Rotation = t * 10
		end
		if core then
			for _, swirl in ipairs(swirls) do
				swirl.Rotation = t * 80
			end
		end
		for i, particle in ipairs(particles) do
			local angle = i * math.pi * 2 / math.max(1, count)
			if kind == "CrystalExplosion" or kind == "Burst" then
				local radius = math.min(motion * 0.55, if kind == "CrystalExplosion" then 0.4 else 0.5)
				particle.Position = UDim2.fromScale(0.5 + math.cos(angle) * radius, 0.5 + math.sin(angle) * radius)
				particle.Rotation = i * 31 + motion * 45
				particle.BackgroundTransparency = math.clamp((motion - 1) * 0.7, 0, 1)
			elseif kind == "RealityGlitch" then
				local radius = 0.16 + ((i * 0.071 - t * 0.18) % 0.52)
				particle.Position =
					UDim2.fromScale(0.5 + math.cos(angle + t * 1.8) * radius, 0.5 + math.sin(angle + t * 1.8) * radius)
			elseif kind == "Sparkle" then
				particle.Position = UDim2.fromScale(0.5 + math.cos(angle) * 0.4, 0.5 + math.sin(angle) * 0.4)
				particle.BackgroundTransparency = (math.sin(t * 5 + i) + 1) * 0.4
			else
				particle.Position = UDim2.fromScale(
					(i * 0.618 + (if kind == "Starlight" then t * 0.13 else 0)) % 1,
					(i * 0.13 + t * 0.3) % 1
				)
				particle.Rotation = if kind == "Starlight" then 35 else i * 31 + t * 90
				if kind == "Starlight" then
					particle.Size = UDim2.fromOffset(2, 14)
				end
			end
		end
	end
end
return Signature
