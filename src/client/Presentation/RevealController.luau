local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Presentation)
local Rules = require(Shared.PresentationRules)
local Rarities = require(Shared.Config.Rarities)
local C = require(script.Parent.Parent.UI.Components)
local Preview = require(script.Parent.Parent.UI.Preview)
local HUDLayout = require(script.Parent.Parent.UI.Layout)
local Layout = require(script.Parent.Layout)
local Effects = require(script.Parent.RevealEffects)
local Controller = {}
function Controller.Create(root, hud, audio)
	local self = { Intensity = "Full", Queue = Rules.RevealQueue(Config.BigQueueCap), Connections = {}, LastId = 0 }
	local card = C.Card(hud.Frame, C.Gold, true)
	card.Name, card.Visible, card.ZIndex = "FlushReveal", false, 22
	local layer = C.New(
		"Frame",
		root,
		{ Name = "RareReveal", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 80 }
	)
	local toast = C.Text(layer, "", UDim2.new(), nil, 18)
	toast.Name, toast.Visible, toast.ZIndex = "CompactDrop", false, 110
	local content, cleanup, tick, elapsed, toastUntil = nil, nil, nil, 0, 0
	local function colorFor(item)
		return if item.Rarity == "Secret" then Color3.fromRGB(189, 127, 255) else Rarities[item.Rarity].Color
	end
	local function resize()
		local layout = Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y)
		C.Place(card, HUDLayout.Compute(hud.Frame.AbsoluteSize.X, hud.Frame.AbsoluteSize.Y, false).Reveal)
		C.Place(toast, layout.Toast)
		if self.Queue.Active and Rules.Big(self.Queue.Active.Tier) then
			-- Keep overflow readable above the large moment, outside its model/name.
			toast.Position, toast.Size = UDim2.new(0, 12, 0, 0), UDim2.new(1, -24, 0, 26)
		end
		if content then
			local entry = self.Queue.Active
			if entry and entry.Tier == "Cinematic" then
				C.Place(content.ItemViewport, layout.Model)
				C.Place(content.ItemName, layout.Name)
				C.Place(content.Odds, layout.Odds)
				C.Place(content.Skip, layout.Skip)
			elseif entry and entry.Tier == "Banner" then
				C.Place(content, layout.Banner)
			end
		end
	end
	local function compact(entry)
		audio:Play(entry.Item.Rarity)
		toast.Text = entry.Item.Name .. "  •  1 in " .. C.Commas(entry.Item.Chance)
		toast.TextColor3 = colorFor(entry.Item)
		toast.Visible, layer.Visible, toastUntil = true, true, os.clock() + Config.Duration.Toast
		hud.SetHintVisible(false)
		resize()
	end
	local function clear()
		if cleanup then
			cleanup()
			cleanup = nil
		end
		if content then
			content:Destroy()
			content = nil
		end
		card.Visible, tick = false, nil
		hud.SetHintVisible(not toast.Visible)
	end
	local play
	function self:Skip()
		clear()
		local nextEntry = self.Queue:Next()
		if nextEntry then
			play(nextEntry)
		else
			layer.Visible = toast.Visible
			resize()
		end
	end
	local function decoration(parent, color, tier)
		local particles, rays = {}, {}
		if tier == "Banner" or tier == "Cinematic" then
			local wheel = C.New("Frame", parent, {
				Name = "Rays",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = if tier == "Cinematic" then UDim2.fromScale(0.5, 0.38) else UDim2.fromScale(0.15, 0.5),
				Size = UDim2.fromOffset(360, 360),
				BackgroundTransparency = 1,
			})
			for i = 1, 12 do
				local ray = C.New("Frame", wheel, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 0.065),
					Rotation = i * 15,
					BackgroundColor3 = color,
					BackgroundTransparency = 0.86,
				})
				C.New("UIGradient", ray, {
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.5, 0.3),
						NumberSequenceKeypoint.new(1, 1),
					}),
				})
			end
			table.insert(rays, wheel)
		end
		local count = if tier == "Burst" then 10 elseif tier == "Sparkle" then 16 else 28
		for i = 1, count do
			local particle = C.New("Frame", parent, {
				Name = "Spark",
				Size = UDim2.fromOffset(if tier == "Sparkle" then 5 else 8, if tier == "Sparkle" then 5 else 13),
				BackgroundColor3 = if i % 3 == 0 then Color3.new(1, 1, 1) else color,
				Rotation = i * 31,
			})
			table.insert(particles, particle)
		end
		return function(t)
			for _, wheel in ipairs(rays) do
				wheel.Rotation = t * 25
			end
			for i, particle in ipairs(particles) do
				if tier == "Burst" or tier == "Sparkle" then
					local angle = i * math.pi * 2 / count
					local radius = if tier == "Burst" then math.min(t * 0.8, 0.65) else 0.3 + math.sin(t * 5 + i) * 0.12
					particle.Position = UDim2.fromScale(0.5 + math.cos(angle) * radius, 0.5 + math.sin(angle) * radius)
					particle.BackgroundTransparency = if tier == "Burst"
						then math.min(t, 1)
						else (math.sin(t * 9 + i) + 1) * 0.4
				else
					particle.Position = UDim2.fromScale((i * 0.618) % 1, ((i * 0.13 + t * 0.38) % 1.25) - 0.15)
					particle.Rotation = i * 31 + t * 120
				end
			end
		end
	end
	play = function(entry)
		elapsed = 0
		local item, tier = entry.Item, entry.Tier
		local color = colorFor(item)
		card.Background.UIStroke.Color, card.Glow.UIStroke.Color = color, color
		local big = Rules.Big(tier)
		local cinematic = tier == "Cinematic"
		local parent = if big then layer else card
		content = C.New("Frame", parent, {
			Name = "RevealContent",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = if cinematic then 0.18 elseif tier == "Banner" then 0.1 else 1,
			BackgroundColor3 = if cinematic then C.Ink else color,
			ClipsDescendants = not cinematic,
		})
		layer.Visible, card.Visible = big or toast.Visible, not big
		hud.SetHintVisible(false)
		local animate = if self.Intensity == "Full"
				and tier ~= "Toast"
				and tier ~= "Pop"
			then decoration(content, color, tier)
			else nil
		local heading =
			C.Text(content, item.Name, UDim2.fromScale(0.68, 0.42), UDim2.fromScale(0.3, 0.06), if big then 38 else 28)
		heading.Name = "ItemName"
		local oddsText = "Base check • 1 in " .. C.Commas(item.Chance)
		if cinematic and entry.Probability then
			oddsText ..= string.format("\nYour outcome: %.6g%%", entry.Probability * 100)
		end
		local odds = C.Text(content, oddsText, UDim2.fromScale(0.68, 0.3), UDim2.fromScale(0.3, 0.57), 18)
		odds.Name = "Odds"
		local model, pivot
		if cinematic then
			local rarity = C.Text(
				content,
				string.upper(item.Rarity) .. " DISCOVERY",
				UDim2.new(1, -24, 0.07, 0),
				UDim2.new(0, 12, 0.04, 0),
				24
			)
			rarity.Name, rarity.TextColor3 = "Rarity", color
			local viewport = C.New("ViewportFrame", content, {
				Name = "ItemViewport",
				BackgroundTransparency = 1,
				Ambient = Color3.fromRGB(210, 210, 230),
				LightColor = Color3.new(1, 1, 1),
				LightDirection = Vector3.new(-1, -1, -1),
			})
			local camera = C.New("Camera", viewport, { FieldOfView = 35 })
			viewport.CurrentCamera = camera
			model = require(Shared.Visuals.Items).Build(viewport, CFrame.new(), item, true)
			local cf, size = model:GetBoundingBox()
			pivot = model:GetPivot()
			local radius = math.max(size.X, size.Y, size.Z) * 0.5
			local distance = radius / math.tan(math.rad(35 / 2)) + radius
			camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, radius * 0.12, distance), cf.Position)
			local skip = C.Button(content, "Tap anywhere to skip", UDim2.new(), nil, function()
				if self.Queue.Active == entry then
					self:Skip()
				end
			end, C.Purple, { TextSize = 18 })
			skip.Name = "Skip"
		else
			Preview.Create(content, UDim2.fromScale(0.25, 0.84), UDim2.fromScale(0.025, 0.08), item)
		end
		if self.Intensity == "Full" then
			C.Pop(content)
			if tier == "Banner" then
				C.Shine(content)
			end
			if big then
				cleanup = Effects.Start(color, cinematic)
			end
		end
		audio:Play(item.Rarity)
		tick = function(t)
			if animate then
				animate(t)
			end
			if model then
				model:PivotTo(pivot * CFrame.Angles(0, t * 0.65, 0))
			end
		end
		resize()
		if tick then
			tick(0)
		end
	end
	function self:Show(item, payload)
		if self.Destroyed then
			return
		end
		if payload and payload.FlushId then
			if Rules.Integer(payload.FlushId) ~= payload.FlushId or payload.FlushId <= self.LastId then
				return
			end
			self.LastId = payload.FlushId
		end
		local tier = Rules.Tier(item.Rarity, self.Intensity)
		if not tier then
			return
		end
		local cooldown = payload and payload.Cooldown
		-- Fast flushes stay readable without accumulating ordinary reveal animations.
		-- Rare moments retain their full duration and the bounded big-reveal queue.
		if
			not Rules.Big(tier)
			and type(cooldown) == "number"
			and cooldown > 0
			and cooldown < math.huge
			and Config.Duration[tier] >= cooldown
		then
			tier = "Toast"
		end
		local probability = payload and payload.Probability
		local entry = {
			Item = item,
			Tier = tier,
			Probability = if type(probability) == "number"
					and probability >= 0
					and probability <= 1
				then probability
				else nil,
		}
		if tier == "Toast" then
			compact(entry)
			return
		end
		local action = self.Queue:Push(entry)
		if action == "Play" then
			play(entry)
		elseif action == "Toast" then
			compact(entry)
		end
	end
	function self:SetIntensity(intensity)
		if self.Intensity == intensity then
			return
		end
		self.Intensity = intensity
		self.Queue:Clear()
		clear()
		layer.Visible = toast.Visible
		resize()
	end
	table.insert(
		self.Connections,
		RunService.Heartbeat:Connect(function(dt)
			if toast.Visible and os.clock() >= toastUntil then
				toast.Visible = false
				layer.Visible = self.Queue.Active ~= nil and Rules.Big(self.Queue.Active.Tier)
				if not self.Queue.Active then
					hud.SetHintVisible(true)
				end
			end
			if self.Queue.Active then
				elapsed += dt
				if elapsed >= Config.Duration[self.Queue.Active.Tier] then
					self:Skip()
				elseif tick then
					tick(elapsed)
				end
			end
		end)
	)
	table.insert(
		self.Connections,
		Input.InputBegan:Connect(function(input)
			if
				self.Queue.Active
				and (
					input.UserInputType == Enum.UserInputType.Touch
					or input.UserInputType == Enum.UserInputType.MouseButton1
					or input.KeyCode == Enum.KeyCode.ButtonB
					or input.KeyCode == Enum.KeyCode.Escape
				)
			then
				self:Skip()
			end
		end)
	)
	table.insert(self.Connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	table.insert(self.Connections, hud.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	function self:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		for _, connection in ipairs(self.Connections) do
			connection:Disconnect()
		end
		self.Queue:Clear()
		clear()
		card:Destroy()
		layer:Destroy()
	end
	resize()
	return self
end
return Controller
