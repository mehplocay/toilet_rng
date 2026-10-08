local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Presentation)
local RevealConfig = require(Shared.Config.Reveals)
local AutoConfig = require(Shared.Config.AutoFlush)
local Rules = require(Shared.PresentationRules)
local Rarities = require(Shared.Config.Rarities)
local C = require(script.Parent.Parent.UI.Components)
local Preview = require(script.Parent.Parent.UI.Preview)
local HUDLayout = require(script.Parent.Parent.UI.Layout)
local Layout = require(script.Parent.Layout)
local Effects = require(script.Parent.RevealEffects)
local Signature = require(script.Parent.RevealSignature)
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
	toast.RichText = true
	local content, cleanup, tick, elapsed, toastUntil = nil, nil, nil, 0, 0
	local lastCompact, compactCount = -math.huge, 0
	local pendingCompact
	local discovered, discoveryReady = {}, false
	local visualElapsed = 0
	function self:UpdateDiscovery(collection)
		if type(collection) ~= "table" then
			return
		end
		discoveryReady = true
		for id, count in pairs(collection) do
			if type(count) == "number" and count > 0 then
				discovered[id] = true
			end
		end
	end
	local function sound(item, gain)
		local config = RevealConfig.Tiers[item.Rarity]
		audio:Play(config.Sound, nil, (gain or 1) * (config.SoundGain or 1))
	end
	local function colorFor(item)
		local rgb = RevealConfig.Tiers[item.Rarity].Color
		return if rgb then Color3.fromRGB(rgb[1], rgb[2], rgb[3]) else Rarities[item.Rarity].Color
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
				if content:FindFirstChild("GlitchRed") then
					C.Place(content.GlitchRed, layout.Name)
					C.Place(content.GlitchBlue, layout.Name)
				end
			elseif entry and entry.Tier == "Banner" then
				C.Place(content, layout.Banner)
			end
		end
	end
	local function compact(entry)
		if not self.Queue.Active then
			sound(entry.Item)
		end
		toast.Text = (if entry.New then '<font color="#FFD369">NEW!</font>  ' else "")
			.. Rules.Escape(entry.Item.Name)
			.. "  •  1 in "
			.. C.Commas(entry.Item.Chance)
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
	local function flushCompact()
		if not pendingCompact or os.clock() - lastCompact < AutoConfig.ToastInterval then
			return
		end
		local item = pendingCompact.Item
		if self.Queue.Active and not Rules.Big(self.Queue.Active.Tier) then
			clear()
			local nextEntry = self.Queue:Next()
			if nextEntry then
				play(nextEntry)
			end
		end
		if not self.Queue.Active then
			sound(item, AutoConfig.ToastGain)
		end
		toast.Text = (if pendingCompact.New then '<font color="#FFD369">NEW!</font>  ' else "")
			.. Rules.Escape(item.Name)
			.. (if compactCount > 1 then "  +" .. (compactCount - 1) .. " more finds" else "")
		toast.TextColor3 = colorFor(item)
		toast.Visible, layer.Visible, toastUntil = true, true, os.clock() + AutoConfig.ToastInterval
		lastCompact, compactCount, pendingCompact = os.clock(), 0, nil
		hud.SetHintVisible(false)
		resize()
	end
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
	play = function(entry)
		elapsed, visualElapsed = 0, 0
		local item, tier = entry.Item, entry.Tier
		local signature = RevealConfig.Tiers[item.Rarity]
		local color = colorFor(item)
		card.Background.UIStroke.Color, card.Glow.UIStroke.Color = color, color
		local big = Rules.Big(tier)
		local cinematic = tier == "Cinematic"
		local parent = if big then layer else card
		content = C.New("Frame", parent, {
			Name = "RevealContent",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = if cinematic
				then (if item.Rarity == "Secret" then 0.12 else 0.32)
				elseif tier == "Banner" then 0.1
				else 1,
			BackgroundColor3 = if cinematic then C.Ink else color,
			ClipsDescendants = not cinematic,
		})
		layer.Visible, card.Visible = big or toast.Visible, not big
		hud.SetHintVisible(false)
		local animate = if self.Intensity == "Full"
				and tier ~= "Toast"
				and tier ~= "Pop"
			then Signature.Create(content, signature, color, Input.TouchEnabled, cinematic)
			else nil
		local heading =
			C.Text(content, item.Name, UDim2.fromScale(0.68, 0.42), UDim2.fromScale(0.3, 0.06), if big then 38 else 28)
		heading.Name = "ItemName"
		heading.ZIndex = 100
		local oddsText = if item.Id == "Poop" then "Fallback drop" else "Base check • 1 in " .. C.Commas(item.Chance)
		if cinematic and entry.Probability then
			oddsText ..= string.format("\nYour outcome: %.6g%%", entry.Probability * 100)
		end
		local odds = C.Text(content, oddsText, UDim2.fromScale(0.68, 0.3), UDim2.fromScale(0.3, 0.57), 18)
		odds.Name = "Odds"
		odds.ZIndex = 100
		if entry.New then
			local stamp = C.Text(
				content,
				"NEW!",
				if cinematic then UDim2.new(0, 88, 0.04, 0) else UDim2.fromScale(0.2, 0.23),
				if cinematic then UDim2.fromScale(0.5, 0.115) else UDim2.fromScale(0.04, 0.02),
				25
			)
			stamp.Name, stamp.TextColor3, stamp.Rotation, stamp.ZIndex = "NewDiscovery", C.Gold, -8, 102
			if cinematic then
				stamp.AnchorPoint = Vector2.new(0.5, 0)
			end
		end
		local model, pivot
		if cinematic then
			local rarity = C.Text(
				content,
				string.upper(item.Rarity),
				UDim2.new(1, -24, 0.07, 0),
				UDim2.new(0, 12, 0.04, 0),
				if item.Rarity == "Mythic" then 48 else 36
			)
			rarity.Name, rarity.TextColor3 = "Rarity", color
			rarity.ZIndex = 100
			if item.Rarity == "Mythic" then
				rarity.BackgroundColor3, rarity.BackgroundTransparency = color, 0.78
				rarity.Size, rarity.Position = UDim2.new(1, -24, 0.09, 0), UDim2.new(0, 12, 0.02, 0)
			end
			local viewport = C.New("ViewportFrame", content, {
				Name = "ItemViewport",
				BackgroundTransparency = 1,
				Ambient = Color3.fromRGB(210, 210, 230),
				LightColor = Color3.new(1, 1, 1),
				LightDirection = Vector3.new(-1, -1, -1),
				ZIndex = 95,
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
			skip.ZIndex = 103
		else
			Preview.Create(content, UDim2.fromScale(0.25, 0.84), UDim2.fromScale(0.025, 0.08), item)
		end
		if self.Intensity == "Full" then
			C.Pop(content)
			if tier == "Banner" then
				C.Shine(content)
			end
			if big then
				cleanup = Effects.Start(color, signature, Input.TouchEnabled)
			end
		end
		local shimmer, red, blue
		if cinematic and item.Rarity == "Celestial" then
			local stroke = heading:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke:Destroy()
			end
			shimmer = C.New("UIGradient", heading, {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, color),
					ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, color),
				}),
			})
		elseif cinematic and signature.ConcealUntil then
			red = C.Text(content, "???", UDim2.new(), nil, 38)
			blue = C.Text(content, "???", UDim2.new(), nil, 38)
			red.Name, blue.Name = "GlitchRed", "GlitchBlue"
			red.TextColor3, blue.TextColor3 = Color3.fromRGB(255, 65, 110), Color3.fromRGB(60, 230, 255)
			red.ZIndex, blue.ZIndex = 98, 99
		end
		sound(item)
		tick = function(t)
			if animate then
				animate(t)
			end
			if model then
				local rotation = if item.Rarity == "Mythic" and t < 1.1
					then math.min(t, 0.22) * 2 + math.max(0, t - 0.22) * 0.06
					else t * 0.65
				model:PivotTo(pivot * CFrame.Angles(0, rotation, 0))
			end
			if shimmer then
				shimmer.Offset = Vector2.new(math.sin(t * 1.8) * 0.75, 0)
			end
			if red then
				local hidden = t < signature.ConcealUntil
				heading.Text = if hidden then "???" else item.Name
				content.ItemViewport.Visible = not hidden
				odds.Visible = not hidden
				red.Text, blue.Text = heading.Text, heading.Text
				-- Two short RGB displacements, no full-screen white flashes or rapid strobe.
				local flicker = (t >= 1.45 and t < 1.6) or (t >= 1.85 and t < 2)
				red.Visible, blue.Visible = flicker, flicker
				local basePosition = heading.Position
				red.Position = UDim2.new(
					basePosition.X.Scale,
					basePosition.X.Offset - 5,
					basePosition.Y.Scale,
					basePosition.Y.Offset + 2
				)
				blue.Position = UDim2.new(
					basePosition.X.Scale,
					basePosition.X.Offset + 5,
					basePosition.Y.Scale,
					basePosition.Y.Offset - 2
				)
			end
		end
		resize()
		if tick then
			tick(0)
		end
	end
	function self:Show(item, payload)
		if self.Destroyed or not item or not Rarities[item.Rarity] or not RevealConfig.Tiers[item.Rarity] then
			return
		end
		if payload and payload.FlushId and not payload.Admin then
			if Rules.Integer(payload.FlushId) ~= payload.FlushId or payload.FlushId <= self.LastId then
				return
			end
			self.LastId = payload.FlushId
		end
		local tier = Rules.Tier(item.Rarity, self.Intensity)
		local isNew = discoveryReady and not discovered[item.Id] and not (payload and payload.Admin)
		if not (payload and payload.Admin) then
			discovered[item.Id] = true
		end
		if payload and payload.Compact then
			-- One reused toast, at most one visual/audio change per interval. Every
			-- award remains in inventory; chat announcements stay server controlled.
			compactCount += 1
			if not pendingCompact or Rarities[item.Rarity].Order >= Rarities[pendingCompact.Item.Rarity].Order then
				pendingCompact = {
					Item = item,
					New = isNew or (pendingCompact and pendingCompact.Item.Id == item.Id and pendingCompact.New),
				}
			end
			flushCompact()
			return
		end
		pendingCompact, compactCount = nil, 0
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
		local presented = item
		if payload and payload.Admin then
			presented = table.clone(item)
			presented.Name = "[ADMIN] " .. item.Name
		end
		local entry = {
			Item = presented,
			Tier = tier,
			New = isNew,
			Duration = if self.Intensity == "Full"
				then RevealConfig.Tiers[item.Rarity].Duration or Config.Duration[tier]
				else Config.Duration[tier],
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
			flushCompact()
			if toast.Visible and os.clock() >= toastUntil then
				toast.Visible = false
				layer.Visible = self.Queue.Active ~= nil and Rules.Big(self.Queue.Active.Tier)
				if not self.Queue.Active then
					hud.SetHintVisible(true)
				end
			end
			if self.Queue.Active then
				elapsed += dt
				visualElapsed += dt
				if elapsed >= self.Queue.Active.Duration then
					self:Skip()
				elseif tick and visualElapsed >= 1 / RevealConfig.UpdateHz then
					visualElapsed = 0
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
