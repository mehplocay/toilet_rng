local function clientChatFixture()
	local chat = H.Services.TextChatService
	local window = H.Instance.new("ChatWindowConfiguration")
	window.Enabled, window.Parent = false, chat
	local remote = { OnClientEvent = H.Signal() }
	local controller = H.Load("src/client/Presentation/ChatAnnouncements").Start(remote)
	local messages, channels = {}, nil
	local function addChannels(systemOnly)
		channels = H.Instance.new("Folder")
		channels.Name, channels.Parent = "TextChannels", chat
		for _, name in ipairs(if systemOnly then { "RBXSystem" } else { "RBXSystem", "RBXGeneral" }) do
			local channel = H.Instance.new("TextChannel")
			channel.Name, channel.Parent = name, channels
			channel.DisplaySystemMessage = function(_, text, metadata)
				if H.FailChatDisplay then
					error("Chat starting")
				end
				table.insert(messages, { Text = text, Metadata = metadata, Channel = name })
			end
		end
	end
	return controller,
		remote,
		messages,
		addChannels,
		function()
			controller:Destroy()
			if channels then
				channels:Destroy()
			end
			window:Destroy()
		end,
		window
end

test(
	"chat integration: real solo Rare flush survives missing channels and renders one colored RBXGeneral system line",
	function()
		local controller, remote, messages, addChannels, cleanup, window = clientChatFixture()
		local e = server()
		local player, profile = e:Join(920)
		e.Players.List = { player }
		local items = e:Load("src/shared/Config/Items")
		local fish
		for _, item in ipairs(items) do
			if item.Id == "Fish" then
				fish = item
			end
		end
		e:Load("src/server/Services/RollService").Roll = function()
			return fish, 0.0125
		end
		e:Fire("Flush", player)
		local forwarded = 0
		for _, message in ipairs(e.Results) do
			local payload = message.Payload[1]
			if type(payload) == "table" and payload.Self then
				assert(message.Player == player)
				remote.OnClientEvent:Fire(payload)
				forwarded += 1
			end
		end
		assert(forwarded == 1 and profile.Inventory.Fish == 1 and profile.Stats.RarestItemId == "Fish")
		assert(#messages == 0 and #controller.Pending == 1)
		H.Advance(2.1)
		assert(#messages == 0 and #controller.Pending == 1, "Missing channel discarded early message")
		addChannels()
		H.Advance(0.3)
		assert(#messages == 1 and #controller.Pending == 0)
		assert(messages[1].Channel == "RBXGeneral" and messages[1].Metadata == "ToiletDrop")
		assert(messages[1].Text == '<font color="rgb(50,140,255)">You found Fish (Rare, 1 in 80)!</font>')
		assert(window.Enabled and H.Services.StarterGui:GetCoreGuiEnabled("CoreGuiType.Chat"))
		H.Advance(4)
		assert(#messages == 1, "Startup replay duplicated successful display")
		cleanup()
	end
)

test("chat client: RBXSystem fallback, API startup retries, bounded queue TTL and teardown", function()
	local controller, remote, messages, addChannels, cleanup = clientChatFixture()
	addChannels(true)
	H.FailChatDisplay = true
	remote.OnClientEvent:Fire({ Self = true, ItemId = "Fish" })
	H.Advance(2.1)
	assert(#controller.Pending == 1 and #messages == 0)
	H.FailChatDisplay = nil
	H.Advance(0.3)
	assert(#messages == 1 and messages[1].Channel == "RBXSystem")
	H.FailChatDisplay = true
	for _ = 1, 1000 do
		remote.OnClientEvent:Fire({ Self = true, ItemId = "Fish" })
	end
	assert(#controller.Pending == 16)
	H.Advance(16)
	assert(#controller.Pending == 0 and #messages == 1)
	H.FailChatDisplay = nil
	cleanup()
	remote.OnClientEvent:Fire({ Self = true, ItemId = "Fish" })
	H.Advance(1)
	assert(#messages == 1 and #controller.Pending == 0)
end)

test(
	"chat client: All/Rare+/Off, admin summaries, authored rich text escaping and preference backlog invalidation",
	function()
		local controller, remote, messages, addChannels, cleanup = clientChatFixture()
		addChannels()
		remote.OnClientEvent:Fire({ Self = true, ItemId = "Poop" })
		assert(#controller.Pending == 0)
		remote.OnClientEvent:Fire({ Self = true, ItemId = "Fish" })
		assert(#controller.Pending == 1)
		controller:SetMode("Off")
		H.Advance(2.1)
		assert(#messages == 0 and #controller.Pending == 0)
		controller:SetMode("All")
		remote.OnClientEvent:Fire({ Self = true, ItemId = "Poop" })
		assert(#messages == 1 and messages[1].Text:find("You found Poop (Common, 1 in 2)!", 1, true))
		local items = H.Load("src/shared/Config/Items")
		local old = items[4].Name
		items[4].Name = 'Fish <b>& "test"</b>'
		remote.OnClientEvent:Fire({ Self = true, ItemId = "Fish", Admin = true, Count = 7 })
		items[4].Name = old
		assert(#messages == 2 and messages[2].Text:find("[ADMIN TEST] You found 7 items", 1, true))
		assert(messages[2].Text:find("Fish &lt;b&gt;&amp; &quot;test&quot;&lt;/b&gt;", 1, true))
		controller:SetMode("Rare+")
		for _, payload in ipairs({
			{},
			{ Self = true, ItemId = "forged" },
			{ Self = true, ItemId = "Fish", Count = 0 },
			{ Self = true, ItemId = "Fish", Count = math.huge },
			{ ItemId = "Fish", PlayerName = "Spoof" },
			{ Self = true, ItemId = "Poop" },
		}) do
			remote.OnClientEvent:Fire(payload)
		end
		assert(#messages == 2)
		cleanup()
	end
)

test("merge chat/auto: real remote awards retain quiet batches, exact finder counts and public leaderstats", function()
	local chat, remote, messages, addChannels, cleanup = clientChatFixture()
	addChannels()
	chat:SetMode("All")
	H.Advance(2.1)
	local root = H.Root(390, 722)
	local cues = {}
	local components = H.Load("src/client/UI/Components")
	local soundHook = components.SoundHook
	components.SoundHook = function()
		error("Finder chat duplicated the compact reveal sound")
	end
	local reveal = H.Load("src/client/Presentation/RevealController").Create(root, {
		Frame = root,
		SetHintVisible = function() end,
	}, {
		Play = function(_, key, _, gain)
			table.insert(cues, { Key = key, Gain = gain })
		end,
		Duck = function()
			error("Remote award ducked music")
		end,
	})
	local e = server()
	local player, profile = e:Join(925)
	e.Players.List = { player }
	profile.Stats.Flushes, player.Distance, profile.Settings.ChatMessages = 100, 300, "All"
	profile.ToiletTier, profile.Upgrades.FlushSpeed, profile.Upgrades.AutoFlushSpeed = 7, 10, 10
	local items = {}
	for _, item in ipairs(e:Load("src/shared/Config/Items")) do
		items[item.Id] = item
	end
	local nextItem
	e:Load("src/server/Services/RollService").Roll = function()
		return nextItem, 0.1
	end
	e.World.Animate = function()
		error("Remote auto award animated the toilet")
	end
	e:Fire("AutoFlush", player, true)
	local cursor, awards = #e.Results, 0
	local function forward()
		for i = cursor + 1, #e.Results do
			local result = e.Results[i]
			local payload = result.Payload[1]
			if payload == "Flush" then
				local award = result.Payload[2]
				assert(award.Compact and result.Player == player)
				reveal:Show(items[award.ItemId], award)
				awards += 1
			elseif type(payload) == "table" and payload.Self then
				remote.OnClientEvent:Fire(payload)
			end
		end
		cursor = #e.Results
	end
	for _, id in ipairs({ "Poop", "Fish", "Poop", "Poop" }) do
		nextItem = items[id]
		e.World.Flush(player, true)
		forward()
		e.Now += 0.401
		e.Services.RunService.Heartbeat:Fire(0.25)
		forward()
		H.Advance(0.4)
	end
	e.Now += 4
	e.Services.RunService.Heartbeat:Fire(0.25)
	forward()
	H.Advance(3)
	local finds = 0
	for _, message in ipairs(messages) do
		assert(message.Channel == "RBXGeneral")
		finds += tonumber(message.Text:match("You found (%d+) items")) or 1
	end
	assert(awards == 4 and finds == 4 and profile.Inventory.Poop == 3 and profile.Inventory.Fish == 1)
	assert(#messages == 2 and messages[2].Text:find("You found 3 items (best: Rare Fish)!", 1, true))
	assert(#cues == 2 and root.RareReveal.CompactDrop.Text:find("Fish  +2 more finds", 1, true))
	for _, cue in ipairs(cues) do
		assert(cue.Gain == 0.25)
	end
	assert(not reveal.Queue.Active and #reveal.Queue.Pending == 0)
	local list = e:Load("src/server/Services/PlayerListService").Start(e.Data)
	list.Refresh()
	local stats = {}
	for _, object in ipairs(e.Objects) do
		if object.Parent and object.Parent.Name == "leaderstats" then
			stats[object.Name] = object.Value
		end
	end
	assert(stats.Coins == profile.Coins and stats.Rebirths == 0 and stats.Rarest == "Rare")
	local before = #messages
	e:Resume(e.Threads[2])
	forward()
	H.Advance(1)
	assert(#messages == before, "Worker repeated a finder summary")
	components.SoundHook = soundHook
	reveal:Destroy()
	root:Destroy()
	cleanup()
end)

test(
	"native list: no custom UI/Tab handler; CoreGui initialization retries then stays enabled after teardown",
	function()
		local root = H.Root(1280, 720)
		local starter = H.Services.StarterGui
		starter.CoreEnabled["CoreGuiType.PlayerList"] = false
		H.HoldCoreGui = true
		local service = H.Load("src/client/Presentation/PlayerList").Create(root)
		assert(#root:GetChildren() == 0 and service.Toggle == nil)
		H.Advance(0.3)
		assert(not starter:GetCoreGuiEnabled("CoreGuiType.PlayerList"))
		H.HoldCoreGui = nil
		H.Advance(0.3)
		assert(starter:GetCoreGuiEnabled("CoreGuiType.PlayerList"))
		local before = #starter.Calls
		H.Services.UserInputService.InputBegan:Fire({ KeyCode = "KeyCode.Tab" }, false)
		H.Advance(3)
		service.Destroy()
		assert(#starter.Calls == before and starter:GetCoreGuiEnabled("CoreGuiType.PlayerList"))
		root:Destroy()
	end
)
