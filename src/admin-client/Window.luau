local Window = {}
function Window.Create(gui, remote, C, reloadLabels)
	local Shared = game.ReplicatedStorage.Shared
	local Config = require(Shared.Config.Admin)
	local Items = require(Shared.Config.Items)
	local Toilets = require(Shared.Config.Toilets)
	local Tracks = require(Shared.Config.Upgrades).Tracks
	local root = C.New("Frame", gui, { Name = "AdminRoot", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	local panel = C.Panel(root, "OWNER ADMIN", C.Purple, 600)
	-- Replace the modal's nested content with one vertically scrolling tab body.
	panel.ContentScroll:Destroy()
	local status = C.BodyText(panel, "Connecting to the server...", UDim2.new(1, -32, 0, 54), UDim2.fromOffset(16, 126))
	status.Name, status.TextXAlignment = "Status", Enum.TextXAlignment.Left
	local content = C.Scroll(panel, UDim2.new(1, -24, 1, -196), UDim2.fromOffset(12, 184))
	local summary = C.BodyText(panel, "Your profile only", UDim2.new(1, -100, 0, 22), UDim2.fromOffset(20, 60))
	summary.Name, summary.TextXAlignment = "Summary", Enum.TextXAlignment.Left
	local pending, sequence, alive, resetToken, jsonBox = nil, 0, true, nil, nil
	local pages, buttons, links = {}, {}, {}
	local socialSummary, socialState
	local pageCache = C.New("Folder", gui, { Name = "CachedAdminTabs" })
	local orders = {}
	local function ordered(parent, object)
		orders[parent] = (orders[parent] or 0) + 1
		object.LayoutOrder = orders[parent]
		return object
	end
	local movement = require(script.Parent.Movement).Start(gui, C)
	local previews = require(script.Parent.Previews).Start(gui, C)
	local keepMovement = false
	local ranges = {
		Give = { Count = { 1, Config.MaxItemGrant } },
		Remove = { Count = { 1, Config.MaxItemGrant } },
		Collection = { Count = { 0, Config.MaxCounter } },
		Display = { Slot = { 1, 100 } },
		Pending = { Slot = { 1, 100 }, Amount = { 0, Config.MaxCoins } },
		AddCoins = { Amount = { 0, Config.MaxCoins } },
		SetCoins = { Amount = { 0, Config.MaxCoins } },
		Toilet = { Level = { 1, #Toilets } },
		Rebirth = { Level = { 0, #require(Shared.Config.Rebirth).Levels } },
		Flushes = { Amount = { 0, Config.MaxCounter } },
		Teleport = { Target = { 0, 9e15 } },
		Speed = { Amount = { 0, Config.MaxWalkSpeed } },
		Jump = { Amount = { 0, Config.MaxJumpPower } },
		Time = { Hour = { 0, 24 } },
	}
	local trackLimits = {}
	for _, track in ipairs(Tracks) do
		trackLimits[track.Id] = track.MaxLevel
	end
	local function send(action, args)
		args = args or {}
		local fields = if action == "Upgrade" then { Level = { 0, trackLimits[args.Track] or -1 } } else ranges[action]
		for key, bounds in pairs(fields or {}) do
			local value = args[key]
			if
				type(value) ~= "number"
				or value ~= value
				or value < bounds[1]
				or value > bounds[2]
				or value % 1 ~= 0
			then
				status.Text = string.format(
					"%s must be a whole number from %s to %s.",
					key,
					tostring(bounds[1]),
					tostring(bounds[2])
				)
				return
			end
		end
		if args.ItemId then
			local known = false
			for _, item in ipairs(Items) do
				if item.Id == args.ItemId then
					known = true
					break
				end
			end
			if not known then
				status.Text = "Choose an exact item ID from the catalog."
				return
			end
		end
		if action == "Import" and (#args.Json == 0 or #args.Json > Config.MaxImportBytes) then
			status.Text = "JSON must contain 1-100,000 bytes."
			return
		end
		if pending then
			status.Text = "Wait for the current request to finish."
			return
		end
		sequence += 1
		pending = { Sequence = sequence, Action = action, At = os.clock() }
		if action ~= "RenewMovement" then
			status.Text, status.TextColor3 = "Waiting for server: " .. action, C.Muted
		end
		remote:FireServer(sequence, action, args)
	end
	local function toggle()
		panel.Visible = not panel.Visible
		if panel.Visible then
			send("Snapshot")
		end
	end
	local open = C.Button(
		root,
		"Admin",
		UDim2.fromOffset(88, 44),
		UDim2.new(1, -100, 0, 80),
		toggle,
		C.Purple,
		{ TextSize = 20 }
	)
	open.Name = "AdminButton"
	local PhoneLayout = C.Layout
	local function resizeButton()
		local layout = PhoneLayout.Compute(
			root.AbsoluteSize.X,
			root.AbsoluteSize.Y,
			game:GetService("UserInputService").TouchEnabled
		)
		if layout.Phone then
			C.Place(open, layout.Admin)
			open.Label.UITextSizeConstraint.MinTextSize = 12
			open.Label.UITextSizeConstraint.MaxTextSize = 12
			open.Label.Text = "ADM"
		else
			open.Size, open.Position = UDim2.fromOffset(88, 44), UDim2.new(1, -100, 0, 80)
			open.Label.UITextSizeConstraint.MinTextSize, open.Label.UITextSizeConstraint.MaxTextSize = 10, 20
			open.Label.Text = "Admin"
		end
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeButton)
	resizeButton()
	local function page(name)
		local frame = C.New("Frame", content, {
			Name = name,
			Size = UDim2.new(1, -22, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
		})
		C.New("UIListLayout", frame, { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
		pages[name] = frame
		return frame
	end
	local function text(parent, value)
		return ordered(parent, C.BodyText(parent, value, UDim2.new(1, 0, 0, 48)))
	end
	local function field(parent, label, value, multiline)
		local row = C.New(
			"Frame",
			parent,
			{ Size = UDim2.new(1, 0, 0, if multiline then 260 else 82), BackgroundTransparency = 1 }
		)
		ordered(parent, row)
		C.BodyText(row, label, UDim2.new(1, 0, 0, 28)).TextXAlignment = Enum.TextXAlignment.Left
		local box = C.New("TextBox", row, {
			Name = label,
			Text = tostring(value),
			ClearTextOnFocus = false,
			MultiLine = multiline == true,
			Size = UDim2.new(1, -8, 1, -34),
			Position = UDim2.fromOffset(4, 30),
			BackgroundColor3 = C.Ink,
			Font = Enum.Font.BuilderSans,
			TextSize = 18,
			TextColor3 = Color3.new(1, 1, 1),
			TextWrapped = multiline == true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = if multiline then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,
		})
		C.Round(box, C.Muted, 8, 1)
		C.New("UIPadding", box, {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		})
		return box
	end
	local function button(parent, label, callback, color)
		local control =
			C.Button(parent, label, UDim2.new(1, -8, 0, 48), nil, callback, color or C.Blue, { TextSize = 18 })
		table.insert(buttons, control)
		ordered(parent, control)
		return control
	end
	local function choices(parent, label, options)
		local index = 1
		local control
		control = button(parent, label .. ": " .. options[index], function()
			index = index % #options + 1
			control.Text = label .. ": " .. options[index]
		end, C.Navy)
		return function()
			return options[index]
		end
	end
	local function presets(parent, box, values)
		local row = C.Scroll(parent, UDim2.new(1, 0, 0, 64), nil, true)
		ordered(parent, row)
		C.New("UIListLayout", row, {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		for index, value in ipairs(values) do
			local label = C.Commas(value)
			local preset = C.Button(row, label, UDim2.fromOffset(68, 44), nil, function()
				box.Text = tostring(value)
			end, C.Navy, { TextSize = 17 })
			preset.LayoutOrder = index
		end
	end
	local function itemPicker(parent)
		local ids = {}
		for _, item in ipairs(Items) do
			table.insert(ids, item.Id)
		end
		text(parent, "All " .. #ids .. " items drop from every toilet. Cycle catalog IDs or enter an ID below.")
		local input = field(parent, "Item ID", ids[1])
		local index = 1
		button(parent, "Next catalog item", function()
			index = index % #ids + 1
			input.Text = ids[index]
		end, C.Navy)
		return input
	end
	local function switches(parent, action, label, extra)
		button(parent, label .. " ON", function()
			local args = table.clone(extra or {})
			args.Enabled = true
			send(action, args)
		end, C.Green)
		button(parent, label .. " OFF", function()
			local args = table.clone(extra or {})
			args.Enabled = false
			send(action, args)
		end, C.Navy)
	end
	local builders = {}
	function builders.Items()
		local body = page("Items")
		local id = itemPicker(body)
		local count = field(body, "Count (grant 1-10,000; collection may be 0)", 1)
		presets(body, count, { 1, 10, 100, 1000 })
		button(body, "Spawn into inventory", function()
			send("Give", { ItemId = id.Text, Count = tonumber(count.Text) })
		end, C.Green)
		local slot = field(body, "Empty display slot", 1)
		button(body, "Spawn one onto display", function()
			send("Display", { ItemId = id.Text, Slot = tonumber(slot.Text) })
		end)
		button(body, "Remove unreserved copies", function()
			send("Remove", { ItemId = id.Text, Count = tonumber(count.Text) })
		end, C.Purple)
		button(body, "Set collection count / discovery", function()
			send("Collection", { ItemId = id.Text, Count = tonumber(count.Text) })
		end)
		button(body, "Give every item x1 / fill index", function()
			send("GiveAll")
		end, C.Gold)
		text(
			body,
			"Grants are tagged. Removal keeps displayed copies; discovery is a separate lifetime counter. Index rewards remain claimable normally."
		)
	end
	function builders.Economy()
		local body = page("Economy")
		local amount = field(body, "Coins / counter (whole number; e.g. 1e100)", 1000)
		presets(body, amount, Config.CoinPresets)
		button(body, "Add coins", function()
			send("AddCoins", { Amount = tonumber(amount.Text) })
		end, C.Green)
		button(body, "Set coins", function()
			send("SetCoins", { Amount = tonumber(amount.Text) })
		end)
		local slot = field(body, "Pending income slot", 1)
		button(body, "Set pending coins on slot", function()
			send("Pending", { Amount = tonumber(amount.Text), Slot = tonumber(slot.Text) })
		end)
		button(body, "Fill passive income capacity", function()
			send("IncomeCap")
		end, C.Gold)
		button(body, "Clear flush cooldown", function()
			send("ClearCooldown")
		end)
		local tier = field(body, "Toilet tier (1-" .. #Toilets .. ")", 1)
		button(body, "Next catalog toilet", function()
			local current = tonumber(tier.Text) or 1
			local nextTier = math.floor(current) % #Toilets + 1
			tier.Text = tostring(nextTier)
		end, C.Navy)
		local toiletName = text(body, Toilets[1].Name)
		if toiletName then
			tier:GetPropertyChangedSignal("Text"):Connect(function()
				local selected = Toilets[tonumber(tier.Text)]
				toiletName.Text = if selected then selected.Name else "Enter a valid toilet tier."
			end)
		end
		button(body, "Set toilet tier", function()
			send("Toilet", { Level = tonumber(tier.Text) })
		end)
		local ids = {}
		for _, track in ipairs(Tracks) do
			table.insert(ids, track.Id)
		end
		local track = choices(body, "Upgrade track", ids)
		local level = field(body, "Track / rebirth level", 0)
		button(body, "Set selected upgrade level", function()
			send("Upgrade", { Track = track(), Level = tonumber(level.Text) })
		end)
		button(body, "Set rebirth level (no rebirth reset)", function()
			send("Rebirth", { Level = tonumber(level.Text) })
		end)
		button(body, "Set run + lifetime flush count", function()
			send("Flushes", { Amount = tonumber(amount.Text) })
		end)
		text(
			body,
			"Income and level caps come from the current gameplay configuration. Values outside those caps are rejected or sanitized."
		)
	end
	function builders.Player()
		local body = page("Player")
		button(body, "Teleport to hub", function()
			send("Teleport", { Destination = "Hub", Target = 0 })
		end)
		button(body, "Teleport home", function()
			send("Teleport", { Destination = "Home", Target = 0 })
		end)
		local target = field(body, "Plot number / online player UserId", 1)
		button(body, "Teleport to plot number", function()
			send("Teleport", { Destination = "Plot", Target = tonumber(target.Text) })
		end)
		button(body, "Teleport to player UserId", function()
			send("Teleport", { Destination = "Player", Target = tonumber(target.Text) })
		end)
		local speed = field(body, "Walk speed (0-100)", 50)
		button(body, "Set walk speed", function()
			send("Speed", { Amount = tonumber(speed.Text) })
		end)
		local jump = field(body, "Jump power (0-150)", 100)
		button(body, "Set jump power", function()
			send("Jump", { Amount = tonumber(jump.Text) })
		end)
		switches(body, "Fly", "Fly")
		switches(body, "Noclip", "Noclip")
		switches(body, "God", "God mode")
		text(
			body,
			"Fly: move normally; Space / Ctrl or UP / DOWN controls altitude. Respawn clears movement. God mode protects damage, not destruction of your character."
		)
		switches(body, "TestPasses", "Test all passes / cosmetics")
		text(body, "Admin test unlocks are local previews, never Marketplace purchases or permanent entitlements.")
		button(body, "Reset my tutorial", function()
			send("ResetTutorial")
		end)
		button(body, "1. Prepare profile reset", function()
			resetToken = nil
			send("PrepareReset")
		end, C.Purple)
		local confirmation = field(body, "2. Type RESET after preparing", "")
		button(body, "Confirm reset + create backup", function()
			if confirmation.Text ~= "RESET" or not resetToken then
				status.Text = "Prepare reset, then type RESET."
				return
			end
			send("Reset", { Token = resetToken })
			resetToken = nil
			confirmation.Text = ""
		end, C.Purple)
	end
	function builders.Events()
		local body = page("Events")
		local id = itemPicker(body)
		button(body, "Force drop + real reveal", function()
			send("ForceDrop", { ItemId = id.Text })
		end, C.Gold)
		text(
			body,
			"Grants one tagged item and shows the normal reveal/announcement. No natural flush, best-flush or rarest-find credit. Luck is a separate action."
		)
		button(body, "Trigger configured server luck boost", function()
			send("Luck")
		end, C.Green)
		button(body, "Test drop announcement", function()
			send("Announcement", { ItemId = id.Text })
		end)
		local preset = choices(body, "Lighting preview", { "Day", "Sunset", "Night" })
		button(body, "Apply lighting preview", function()
			send("Lighting", { Preset = preset() })
		end)
		local hour = field(body, "Time of day (0-24)", 14)
		button(body, "Preview time", function()
			send("Time", { Hour = tonumber(hour.Text) })
		end)
		button(body, "Restore original lighting", function()
			send("RestoreLighting")
		end, C.Navy)
	end
	builders["Map / Debug"] = function()
		local body = page("Map / Debug")
		button(body, "Read server stats + instance counts", function()
			send("Stats")
		end)
		switches(body, "Debug", "Hitbox overlay", { Kind = "Hitboxes" })
		switches(body, "Debug", "Wayfinding overlay", { Kind = "Wayfinding" })
		text(
			body,
			"Local overlays inspect streamed parts only and cap at 300 boxes. Toggle again after moving to inspect a new area."
		)
		button(body, "Reload world labels", function()
			send("ReloadLabels")
		end)
		local id = itemPicker(body)
		button(body, "Spawn temporary dummy reward", function()
			send("Dummy", { ItemId = id.Text })
		end)
	end
	function builders.Tools()
		local body = page("Tools")
		socialSummary = text(body, socialState or "Social boosts: refresh profile summary to inspect (read only).")
		socialSummary.Name, socialSummary.Size = "SocialBoostSummary", UDim2.new(1, 0, 0, 130)
		button(body, "Export current profile JSON", function()
			send("Export")
		end, C.Green)
		jsonBox = field(body, "Profile JSON (select / copy / paste)", "", true)
		button(body, "Import and sanitize JSON", function()
			send("Import", { Json = jsonBox.Text })
		end, C.Purple)
		text(
			body,
			"Import replaces your profile. Unknown fields are discarded and known fields use the save sanitizer. Natural rarest-find records and the latest reset backup are preserved. Export before testing."
		)
		button(body, "Refresh profile summary", function()
			send("Snapshot")
		end)
	end
	local function selectTab(name)
		if not pages[name] then
			builders[name]()
		end
		for key, frame in pairs(pages) do
			frame.Visible = key == name
			frame.Parent = if key == name then content else pageCache
		end
		content.CanvasPosition = Vector2.zero
	end
	local tabs = C.TabBar(panel, { "Items", "Economy", "Player", "Events", "Map / Debug", "Tools" }, selectTab)
	tabs.Frame.Position, tabs.Frame.Size = UDim2.fromOffset(12, 78), UDim2.new(1, -24, 0, 52)
	selectTab("Items")
	table.insert(
		links,
		remote.OnClientEvent:Connect(function(id, response)
			if not alive or not pending or id ~= pending.Sequence then
				return
			end
			local action = pending.Action
			pending = nil
			if action == "ResetTutorial" and response.Success then
				panel.Visible = false
			end
			if action ~= "RenewMovement" or not response.Success then
				status.Text, status.TextColor3 =
					response.Message or "", if response.Success then C.Green else Color3.fromRGB(255, 140, 140)
			end
			local extra = response.Data
			if not extra then
				return
			end
			if extra.Token then
				resetToken = extra.Token
			end
			if extra.Json and jsonBox then
				jsonBox.Text = extra.Json
			end
			if extra.Coins then
				if extra.Social then
					local social = extra.Social
					socialState = string.format(
						"Social boosts (read only)\nGroup: %s | Friends: %d\nInvite: %ds remaining | Today: %d | Lifetime: %d\nCombined social coin factor: %.3fx",
						social.GroupStatus,
						social.FriendCount,
						social.InviteRemaining,
						social.DailyCount,
						social.RewardedCount,
						social.Multiplier
					)
					if socialSummary then
						socialSummary.Text = socialState
					end
				end
				summary.Text = string.format(
					"Coins %s | Tier %d | Rebirth %d | %s | Lucky Flushes %d",
					C.Commas(extra.Coins),
					extra.ToiletTier,
					extra.RebirthLevel,
					if extra.NoPersistence then "MEMORY ONLY" else "Persistent",
					extra.LuckyFlushes or 0
				)
			end
			if extra.Instances then
				status.Text = string.format(
					"%d players | %d instances / %d parts | %.1f MB | %.1f ms heartbeat",
					extra.Players,
					extra.Instances,
					extra.Parts,
					extra.MemoryMB,
					extra.HeartbeatMs
				)
			end
			if extra.Preview == "TestPasses" and extra.Args.Enabled then
				keepMovement = true
			end
			if extra.Preview then
				previews:Apply(extra.Preview, extra.Args)
			end
			if extra.Movement then
				movement.Set(extra.Movement)
				keepMovement = true
			end
			if extra.ReloadLabels then
				if reloadLabels then
					reloadLabels()
				end
			end
			if action == "ForceDrop" and response.Success then
				panel.Visible = false
			end
		end)
	)
	table.insert(
		links,
		game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.F2 then
				toggle()
			end
		end)
	)
	local elapsed = 0
	table.insert(
		links,
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			if pending and os.clock() - pending.At > 20 then
				pending = nil
				status.Text = "No response. Refresh before retrying; a save may still be running."
			end
			elapsed += dt
			if elapsed >= 5 then
				elapsed = 0
				if keepMovement and not pending then
					send("RenewMovement")
				end
			end
		end)
	)
	gui.Destroying:Connect(function()
		alive = false
		for _, link in ipairs(links) do
			link:Disconnect()
		end
		movement.Destroy()
		previews:Destroy()
	end)
	send("Hello")
	return { Panel = panel, Open = open, Pages = pages, Select = selectTab, Send = send }
end
return Window
