-- Client-local UI effects only. No tracks, sounds, camera changes or character emitters are started here.
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Rules = require(game.ReplicatedStorage.Shared.MonetizationRules)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local C = require(script.Parent.UI.Components)
local Layout = require(script.Parent.UI.Layout)
local Input = game:GetService("UserInputService")
local Effects = {}

function Effects.Start(root, player, remotes)
	local limits = Config.CelebrationEffects
	local channels, buttons, connections = {}, {}, {}
	local reveal = { Pieces = {}, Age = limits.Lifetime }
	local owned, mode, rebirthLevel = {}, "Full", nil
	local alive, active, elapsed, clock = true, false, 0, 0
	local character, deathConnection, childConnection
	local menu = C.Panel(root, "Celebration effects", C.Gold)
	local content = menu.ContentScroll.Body
	C.New("UIListLayout", content, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	local toggle
	local function connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(connections, connection)
		return connection
	end
	local function clear(channel)
		for _, piece in ipairs(channel.Pieces) do
			piece:Destroy()
		end
		table.clear(channel.Pieces)
	end
	local function living()
		local current = player.Character
		local humanoid = current and current:FindFirstChildWhichIsA("Humanoid")
		return current == character and humanoid and humanoid.Health > 0
	end
	local function allowed()
		return alive and owned.DancePack == true and player:GetAttribute("DancePack") ~= false and mode ~= "Off"
	end
	local function updateVisibility()
		local hud = root:FindFirstChild("HUD")
		local blocked = root:GetAttribute("TutorialActive") or (hud and not hud.Visible)
		local hint = hud and hud:FindFirstChild("CenterHint")
		blocked = blocked or (hint and hint.Visible)
		local breakdown = hud and hud:FindFirstChild("LuckBreakdown")
		blocked = blocked or (breakdown and breakdown.Visible)
		for _, child in ipairs(root:GetChildren()) do
			if child ~= menu and child:IsA("GuiObject") and child.Visible and child:FindFirstChild("ContentScroll") then
				blocked = true
			end
		end
		local revealLayer = root:FindFirstChild("RareReveal")
		local toast = root:FindFirstChild("ResultToast")
		local flushReveal = hud and hud:FindFirstChild("FlushReveal")
		blocked = blocked
			or (toast and toast.Visible)
			or (flushReveal and flushReveal.Visible)
			or (revealLayer and revealLayer:FindFirstChild("RevealContent") ~= nil)
		toggle.Visible = owned.DancePack == true and not blocked
	end
	local function refresh()
		active = false
		local interactable = allowed() and living() == true
		for i, channel in ipairs(channels) do
			active = active or channel.Enabled
			buttons[i].Text = Config.Celebrations[i] .. (if channel.Enabled then ": ON" else ": OFF")
			buttons[i].Interactable = interactable
		end
		local phone = Layout.IsPhone(root.AbsoluteSize.X, root.AbsoluteSize.Y, Input.TouchEnabled)
		toggle.Text = if active then "Stop" else "Celebrate"
		toggle.Label.Text = if phone and not active then "Dance" else toggle.Text
		if phone then
			C.Place(toggle, Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y, Input.TouchEnabled).Celebrate)
		else
			toggle.Size, toggle.Position = UDim2.fromOffset(112, 44), UDim2.new(1, -124, 0, 152)
		end
		updateVisibility()
		toggle.Interactable = interactable
	end
	local function stop()
		for _, channel in ipairs(channels) do
			channel.Enabled = false
			clear(channel)
		end
		menu.Visible = false
		refresh()
	end
	local function reset()
		stop()
		clear(reveal)
	end
	local function burst(channel, style, count, name)
		clear(channel)
		channel.Age = 0
		for i = 1, count do
			local piece = C.New("Frame", root, {
				Name = name,
				Size = UDim2.fromOffset(7, 12),
				Position = UDim2.fromScale(0.5, 0.45),
				BackgroundColor3 = if style == 2 then C.Gold else Color3.fromHSV(i / count, 0.8, 1),
				BorderSizePixel = 0,
				ZIndex = 75,
			})
			if style == 1 then
				piece.Size = UDim2.fromOffset(4, 4)
			elseif style == 3 or style == 4 then
				piece.Size = UDim2.fromOffset(9, 9)
				C.New("UICorner", piece, { CornerRadius = UDim.new(1, 0) })
				if style == 4 then
					piece.BackgroundTransparency = 1
					C.New("UIStroke", piece, { Color = piece.BackgroundColor3, Thickness = 2 })
				end
			end
			table.insert(channel.Pieces, piece)
		end
	end
	local function startChannel(channel, i)
		-- Four independent channels share a fixed budget, even when all are enabled.
		burst(
			channel,
			i,
			if mode == "Reduced" then limits.ReducedPerEffect else limits.FullPerEffect,
			"Celebration" .. i .. "Piece"
		)
	end
	toggle = C.Button(root, "Celebrate", UDim2.fromOffset(112, 44), UDim2.new(1, -124, 0, 152), function()
		if active then
			reset()
		elseif allowed() and living() then
			channels[1].Enabled = true
			startChannel(channels[1], 1)
			menu.Visible = true
			refresh()
		end
	end, C.Purple, { Name = "CelebrationMenu", TextSize = 16 })
	local danceIcon = C.Icon(toggle, "Crown", UDim2.fromOffset(22, 22), UDim2.fromOffset(11, 2))
	local function resizeToggle()
		local phone = Layout.IsPhone(root.AbsoluteSize.X, root.AbsoluteSize.Y, Input.TouchEnabled)
		danceIcon.Visible = phone
		toggle.Label.Position = if phone then UDim2.fromScale(0.02, 0.58) else UDim2.fromScale(0.06, 0.12)
		toggle.Label.Size = if phone then UDim2.fromScale(0.96, 0.4) else UDim2.fromScale(0.88, 0.76)
		toggle.Label.UITextSizeConstraint.MinTextSize = if phone then 12 else 10
		toggle.Label.UITextSizeConstraint.MaxTextSize = if phone then 12 else 16
		local layout = Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y, Input.TouchEnabled)
		C.Place(toggle, if layout.Phone then layout.Celebrate else layout.Celebration)
		refresh()
	end
	connect(root:GetPropertyChangedSignal("AbsoluteSize"), resizeToggle)
	resizeToggle()
	for i, name in ipairs(Config.Celebrations) do
		local channel = { Enabled = false, Pieces = {}, Age = limits.Lifetime }
		channels[i] = channel
		buttons[i] = C.Button(content, name, UDim2.new(1, -12, 0, 46), nil, function()
			if not allowed() or not living() then
				return
			end
			channel.Enabled = not channel.Enabled
			if channel.Enabled then
				startChannel(channel, i)
			else
				clear(channel)
			end
			refresh()
		end, C.Purple, { Name = "Celebration" .. i })
		buttons[i].LayoutOrder = i
	end
	resizeToggle()
	C.Button(content, "Stop celebration", UDim2.new(1, -12, 0, 46), nil, reset, C.Blue).LayoutOrder = 5
	-- A separate finite channel. Stop clears the visible burst; a later flush can trigger a new reveal.
	local function bindCharacter(current)
		if deathConnection then
			deathConnection:Disconnect()
			deathConnection = nil
		end
		if childConnection then
			childConnection:Disconnect()
			childConnection = nil
		end
		character = current
		reset()
		if not current then
			return
		end
		local function bindHumanoid(child)
			if child:IsA("Humanoid") then
				if deathConnection then
					deathConnection:Disconnect()
				end
				deathConnection = child.Died:Connect(reset)
				refresh()
			end
		end
		childConnection = current.ChildAdded:Connect(bindHumanoid)
		local humanoid = current:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			bindHumanoid(humanoid)
		end
	end
	bindCharacter(player.Character)
	connect(player.CharacterAdded, bindCharacter)
	connect(player.CharacterRemoving, function()
		bindCharacter(nil)
	end)
	connect(player:GetAttributeChangedSignal("PlotCFrame"), reset)
	connect(player:GetAttributeChangedSignal("DancePack"), function()
		-- Any entitlement transition ends the old session. A grant never auto-starts effects.
		stop()
	end)
	connect(player:GetAttributeChangedSignal("ConfettiReveal"), function()
		if player:GetAttribute("ConfettiReveal") == false then
			clear(reveal)
		end
	end)
	connect(remotes.State.OnClientEvent, function(state)
		local previousOwned, previousMode = owned, mode
		owned = Rules.Entitlements(state.OwnedPasses, Config)
		mode = (state.Settings or {}).RevealIntensity or "Full"
		if rebirthLevel ~= nil and state.RebirthLevel ~= nil and rebirthLevel ~= state.RebirthLevel then
			reset()
		end
		if state.RebirthLevel ~= nil then
			rebirthLevel = state.RebirthLevel
		end
		if previousOwned.DancePack ~= owned.DancePack or not allowed() then
			stop()
		elseif previousMode ~= mode then
			for i, channel in ipairs(channels) do
				if channel.Enabled then
					startChannel(channel, i)
				end
			end
		end
		if not owned.ConfettiReveal or mode == "Off" or previousMode ~= mode then
			clear(reveal)
		end
		refresh()
	end)
	connect(remotes.Result.OnClientEvent, function(action, payload)
		if action == "Rebirth" and payload and payload.Success then
			reset()
		elseif
			action == "Flush"
			and (not payload or payload.Success ~= false)
			and owned.ConfettiReveal
			and player:GetAttribute("ConfettiReveal") ~= false
			and mode ~= "Off"
			and living()
		then
			burst(reveal, 0, if mode == "Reduced" then limits.ReducedReveal else limits.FullReveal, "RevealConfetti")
		end
	end)
	local function update(channel, style, step)
		channel.Age += step
		local age = channel.Age
		if age >= limits.Lifetime then
			clear(channel)
			return
		end
		for i, piece in ipairs(channel.Pieces) do
			local a = i * 2.399
			piece.Position =
				UDim2.fromScale(0.5 + math.cos(a) * age * 0.3, 0.45 - math.sin(a) * age * 0.18 + age * age * 0.17)
			if style == 3 then
				piece.Position = UDim2.fromScale(0.5 + math.cos(a + clock) * 0.16, 0.35 + math.sin(a + clock) * 0.06)
			elseif style == 4 then
				local diameter = 30 + age * 90 + i * 8
				piece.Size = UDim2.fromOffset(diameter, diameter)
				piece.Position = UDim2.new(0.5, -diameter / 2, 0.4, -diameter / 2)
				piece.UIStroke.Transparency = math.clamp(age / limits.Lifetime, 0, 1)
			end
			piece.Rotation = i * 23 + age * 130
			piece.BackgroundTransparency = if style == 4 then 1 else math.clamp(age / limits.Lifetime, 0, 1)
		end
	end
	connect(RunService.Heartbeat, function(dt)
		updateVisibility()
		if player.Character ~= character then
			bindCharacter(player.Character)
		elseif (active or #reveal.Pieces > 0) and not living() then
			reset()
		end
		elapsed += dt
		if elapsed < limits.UpdateSeconds then
			return
		end
		local step = elapsed
		elapsed = 0
		clock += step
		if #reveal.Pieces > 0 then
			update(reveal, 0, step)
		end
		for i, channel in ipairs(channels) do
			if channel.Enabled then
				update(channel, i, step)
				-- At most one burst per interval, with no catch-up loop after a stalled mobile frame.
				if allowed() and living() and channel.Age >= limits.Interval then
					startChannel(channel, i)
				end
			end
		end
	end)
	local function destroy()
		if not alive then
			return
		end
		alive = false
		reset()
		if deathConnection then
			deathConnection:Disconnect()
		end
		if childConnection then
			childConnection:Disconnect()
		end
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		table.clear(connections)
		menu:Destroy()
		toggle:Destroy()
	end
	connect(Players.PlayerRemoving, function(owner)
		if owner == player then
			destroy()
		end
	end)
	connect(root.Destroying, destroy)
	return { Menu = menu, Destroy = destroy }
end

return Effects
