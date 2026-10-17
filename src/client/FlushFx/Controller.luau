-- Orchestrates the local flush moment from an authoritative "Flush" result: world VFX at the
-- owned toilet, screen overlays and a bounded camera punch. Presentation only; it never
-- sends remotes or changes any game value.
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.FlushFx)
local RevealConfig = require(Shared.Config.Reveals)
local Rarities = require(Shared.Config.Rarities)
local Rules = require(Shared.FlushFxRules)
local C = require(script.Parent.Parent.UI.Components)
local World = require(script.Parent.World)
local Screen = require(script.Parent.Screen)
local Camera = require(script.Parent.Camera)
local Controller = {}

function Controller.Start(root, hud, prompts)
	local self = { Intensity = "Full", Destroyed = false }
	local mobile = Input.TouchEnabled
	local world, screen, camera = World.new(Config), Screen.new(root, hud, Config), Camera.new(Config)
	local ledger = Rules.Ledger(if mobile then Config.MobileParticleBudget else Config.ParticleBudget)
	local active, lastStart, heartbeat = nil, -math.huge, nil
	local connections = {}
	self.Ledger, self.Screen = ledger, screen
	local function colorFor(item)
		local rgb = RevealConfig.Tiers[item.Rarity] and RevealConfig.Tiers[item.Rarity].Color
		return if rgb then Color3.fromRGB(rgb[1], rgb[2], rgb[3]) else Rarities[item.Rarity].Color
	end
	local function step()
		local now = os.clock()
		local worldBusy = world:Step(now)
		local screenBusy = screen:Step(now)
		if active and now - active.Start >= active.Plan.Duration then
			active = nil
		end
		if not worldBusy and not screenBusy and not active and not camera:Busy() and heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
	end
	-- Screen point of the toilet bowl in root pixels, or a centred fallback.
	local function origin(target)
		local size = root.AbsoluteSize
		local x, y = size.X * 0.5, size.Y * 0.42
		local view = workspace.CurrentCamera
		if target and view and view.WorldToViewportPoint then
			local point, visible = view:WorldToViewportPoint(target.Bowl.Position)
			if visible then
				local offset = root.AbsolutePosition
				x = math.clamp(point.X - offset.X, 0, size.X)
				y = math.clamp(point.Y - offset.Y, 0, size.Y)
			end
		end
		return { x, y }
	end
	function self:Flush(item, payload)
		if self.Destroyed or type(item) ~= "table" or type(payload) ~= "table" then
			return nil
		end
		if not Config.Rarities[item.Rarity] or not Rarities[item.Rarity] then
			return nil
		end
		local now = os.clock()
		local plan = Rules.Plan(Config, item.Rarity, {
			Intensity = self.Intensity,
			Compact = payload.Compact == true,
			Cooldown = if payload.Automatic then payload.AutoInterval else payload.Cooldown,
			Gap = now - lastStart,
			Mobile = mobile,
			ActiveRank = if active then active.Plan.Rank else 0,
			ActiveRemaining = if active then active.Start + active.Plan.Duration - now else 0,
		})
		if not plan then
			return nil
		end
		lastStart = now
		local color = colorFor(item)
		local target = world:Locate(prompts)
		world:Play(plan, color, target, ledger, now)
		if not plan.Underlay then
			active = { Plan = plan, Start = now }
			screen:Play(plan, color, item, origin(target), payload.ServiceCoins)
			camera:Play(plan)
		end
		if not heartbeat then
			heartbeat = RunService.Heartbeat:Connect(step)
		end
		return plan
	end
	function self:SetIntensity(intensity)
		if intensity == self.Intensity then
			return
		end
		self.Intensity = intensity
		if intensity ~= "Full" then
			-- Settings changes stop overlays and camera at once; live particles simply expire.
			active = nil
			screen:Stop()
			camera:Stop()
			world:Stop()
		end
	end

	-- Button feel: a deeper squash with an elastic return and a ripple, on every press.
	local button = hud and hud.FlushButton
	if button then
		local ripple = C.New("Frame", button, {
			Name = "PressRipple",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
		})
		C.New("UICorner", ripple, { CornerRadius = UDim.new(0, 16) })
		local stroke = C.New("UIStroke", ripple, { Color = Color3.new(1, 1, 1), Thickness = 4, Transparency = 1 })
		table.insert(
			connections,
			button.Activated:Connect(function()
				if self.Destroyed or not button.Interactable or self.Intensity == "Off" then
					return
				end
				local scale = button:FindFirstChild("PressScale")
				if scale then
					scale.Scale = Config.Press.Squash
					C.Tween(scale, Config.Press.Release, { Scale = 1 }, Enum.EasingStyle.Back)
				end
				if self.Intensity == "Full" then
					ripple.Size, ripple.Visible, stroke.Transparency = UDim2.fromScale(1, 1), true, 0.1
					C.Tween(stroke, Config.Press.RippleTime, { Transparency = 1 })
					C.Tween(ripple, Config.Press.RippleTime, { Size = UDim2.new(1, 24, 1, 24) }).Completed
						:Once(function()
							ripple.Visible = false
						end)
				end
			end)
		)
	end

	function self:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		if heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
		active = nil
		camera:Stop()
		screen:Destroy()
		world:Destroy()
		ledger:Clear()
	end
	self.Busy = function()
		return heartbeat ~= nil
	end
	return self
end
return Controller
