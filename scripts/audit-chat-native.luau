-- Task regressions: actual announcement/settings/leaderstats modules.
local function chatFixture()
	local e = environment()
	local players = { e:Player(901), e:Player(902), e:Player(903), e:Player(904) }
	e.Players.List = players
	local data = { Profiles = {}, Stopping = false }
	function data:Get(player)
		return self.Profiles[player]
	end
	for _, player in ipairs(players) do
		data.Profiles[player] = { Settings = { ChatMessages = "Rare+" }, Stats = {}, Coins = 0 }
	end
	data.Profiles[players[4]].Settings.ChatMessages = "Off"
	players[1].Name = "<b>Finder\n"
	players[1].IsFriendsWithAsync = function(_, id)
		return id == players[2].UserId
	end
	local events = {}
	local queue = e:Load("src/server/Services/AnnouncementService")
		.Start(data, { DropAnnouncement = e:Remote() }, events)
	local items = {}
	for _, item in ipairs(e:Load("src/shared/Config/Items")) do
		items[item.Id] = item
	end
	return e, data, players, events, queue, e.Threads[#e.Threads], items
end

test("chat: every Rare+ tier reaches finder once; Epic/Legendary friends and Mythic+ server only", function()
	for _, pair in ipairs({
		{ "Poop", 0 },
		{ "ToiletPaper", 0 },
		{ "Fish", 1 },
		{ "Duck", 2 },
		{ "GoldenPoop", 2 },
		{ "ToiletBaby", 3 },
		{ "SewerShark", 3 },
		{ "Mystery", 3 },
	}) do
		local e, _, players, events, _, worker, items = chatFixture()
		events.Observe(players[1], items[pair[1]], 1)
		e:Resume(worker)
		assert(#e.Results == pair[2], pair[1])
		if pair[2] > 0 then
			assert(e.Results[1].Player == players[1] and e.Results[1].Payload[1].Self)
			assert(e.Results[1].Payload[1].Count == 1)
		end
		for i = 2, #e.Results do
			local message = e.Results[i]
			assert(message.Player == players[i] and not message.Payload[1].Self)
			assert(message.Payload[1].PlayerName == "bFinder" and message.Payload[1].Coins == nil)
		end
		local count = #e.Results
		events.Observe(players[1], items[pair[1]], 1)
		e.Now += 6
		events.Observe(players[1], items[pair[1]], 1)
		e:Resume(worker)
		assert(#e.Results == count, "Replay delivered")
	end
end)

test("chat: rapid low finds coalesce with exact count/best; All includes common; Off excludes all", function()
	local e, data, players, events, queue, _, items = chatFixture()
	local player = players[1]
	data.Profiles[player].Settings.ChatMessages = "All"
	events.Observe(player, items.Poop, 1)
	for i = 2, 8 do
		e.Now += 0.4
		events.Observe(player, if i == 5 then items.Fish else items.Poop, i)
	end
	assert(#e.Results == 1 and #queue.Finder.Pending == 1)
	e.Now += 1.2
	e.Services.RunService.Heartbeat:Fire(0.25)
	assert(#e.Results == 2 and #queue.Finder.Pending == 0)
	assert(e.Results[2].Payload[1].Count == 7 and e.Results[2].Payload[1].ItemId == "Fish")
	data.Profiles[player].Settings.ChatMessages = "Off"
	events.Observe(player, items.Mystery, 9)
	assert(#e.Results == 2)
	data.Profiles[player].Settings.ChatMessages = "Rare+"
	events.Observe(player, items.Mystery, 9)
	assert(#e.Results == 2, "Off ID replayed after opting in")
end)

test("chat: blocked friendship cannot delay self summaries; session/TTL/settings/removal invalidate pending", function()
	for _, mutation in ipairs({ "Profile", "Off", "TTL", "Leave", "Changed" }) do
		local e, data, players, events, queue, worker, items = chatFixture()
		local player = players[1]
		player.IsFriendsWithAsync = function()
			coroutine.yield("friend held")
			return false
		end
		events.Observe(player, items.Duck, 1)
		e:Resume(worker)
		events.Observe(player, items.Fish, 2)
		events.Observe(player, items.Fish, 3)
		assert(#queue.Finder.Pending == 1 and #e.Results == 2)
		if mutation == "Profile" then
			data.Profiles[player] = { Settings = {} }
		elseif mutation == "Off" then
			data.Profiles[player].Settings.ChatMessages = "Off"
		elseif mutation == "TTL" then
			e.Now += 20
		elseif mutation == "Leave" then
			player.Parent = nil
			e.Players.PlayerRemoving:Fire(player)
		else
			events.ChatSettingsChanged(player)
		end
		e.Now += 4
		e.Services.RunService.Heartbeat:Fire(0.25)
		assert(#e.Results == 2 and #queue.Finder.Pending == 0, mutation)
		if mutation == "Leave" then
			assert(queue.Finder.Natural[player] == nil)
		end
	end
	local e, _, players, events, _, worker, items = chatFixture()
	players[1].IsFriendsWithAsync = function()
		coroutine.yield("friend held")
		return false
	end
	events.Observe(players[1], items.Duck, 1)
	e:Resume(worker)
	events.Observe(players[1], items.Fish, 2)
	events.Observe(players[1], items.Fish, 3)
	e.Now += 4
	e.Services.RunService.Heartbeat:Fire(0.25)
	assert(#e.Results == 3 and e.Results[3].Payload[1].ItemId == "Fish")
end)

test("chat: independent admin/natural dedupe, tagged summaries and bounded pending storage", function()
	local e, data, players, events, queue, _, items = chatFixture()
	events.ObserveAdmin(players[1], items.Fish)
	events.ObserveAdmin(players[1], items.Fish)
	events.Observe(players[1], items.Fish, 1)
	events.Observe(players[1], items.Fish, 2)
	assert(#e.Results == 2 and e.Results[1].Payload[1].Admin and not e.Results[2].Payload[1].Admin)
	assert(#queue.Finder.Pending == 2 and data.Profiles[players[1]].Stats.RarestItemId == nil)
	e.Now += 4
	e.Services.RunService.Heartbeat:Fire(0.25)
	assert(#e.Results == 4 and e.Results[3].Payload[1].Admin ~= e.Results[4].Payload[1].Admin)
	local q = e:Load("src/shared/SelfAnnouncementQueue").new(e:Load("src/shared/Config/Presentation"), function()
		return e.Now
	end)
	for _ = 1, 1000 do
		local p = {}
		q:Push(p, items.Fish, {}, false, "Rare+")
		q:Push(p, items.Fish, {}, false, "Rare+")
	end
	assert(#q.Pending == 16)
	e.Now += 20
	q:Drain(function()
		error("Expired summary delivered")
	end)
	assert(#q.Pending == 0)
end)

test("chat: mode fuzz/migration, rate limit, independent settings persistence and rebirth retention", function()
	local e = server()
	local player, profile = e:Join(909)
	for _, value in ipairs({ true, 4, {}, "rare+", "", string.rep("A", 10000) }) do
		e.Now += 1
		e:Fire("PresentationSettings", player, { ChatMessages = value })
		assert(profile.Settings.ChatMessages == "Rare+")
	end
	e.Now += 3
	e:Fire("PresentationSettings", player, { ChatMessages = "Off", ChatAnnouncements = true })
	e:Fire("PresentationSettings", player, { ChatMessages = "Off" }, "extra")
	assert(profile.Settings.ChatMessages == "Rare+")
	e.Now += 3
	e:Fire("PresentationSettings", player, { ChatMessages = "All" })
	local results = #e.Results
	for _ = 1, 1000 do
		e:Fire("PresentationSettings", player, { ChatMessages = "All" })
	end
	assert(#e.Results == results + 2 and profile.Settings.MusicVolume == 0.25 and profile.Coins == 0)
	e.Data:Close(player)
	local _, saved = e:Join(909)
	assert(saved.Settings.ChatMessages == "All" and saved.Settings.ChatAnnouncements)
	local rebirthPlayer, rebirthProfile = rebirthReady(e, 911)
	rebirthProfile.Settings.ChatMessages = "All"
	e:Fire("Rebirth", rebirthPlayer, 0)
	assert(e.Data:Get(rebirthPlayer).RebirthLevel == 1 and e.Data:Get(rebirthPlayer).Settings.ChatMessages == "All")
	local settings = e:Load("src/shared/PresentationSettings")
	assert(settings.Sanitize({ ChatAnnouncements = false }).ChatMessages == "Off")
	assert(settings.Sanitize({ ChatAnnouncements = true }).ChatMessages == "Rare+")
	assert(settings.Sanitize({ ChatMessages = "All", ChatAnnouncements = false }).ChatMessages == "All")
end)

test(
	"native list: exactly three public stats in priority order, exact large Coins, changed-only values and cleanup",
	function()
		local e = environment()
		local new = e.Globals.Instance.new
		local writes = 0
		e.Globals.Instance.new = function(class)
			local object, values = new(class), {}
			return setmetatable(object, {
				__index = values,
				__newindex = function(t, key, value)
					if key == "Value" then
						writes += 1
						values[key] = value
					else
						rawset(t, key, value)
					end
				end,
			})
		end
		local player = e:Player(910)
		e.Players.List = { player }
		local profile =
			{ Coins = 9e15, RebirthLevel = 3, Stats = { RarestItemId = "Fish" }, Settings = {}, Secret = "private" }
		local data = {
			Get = function()
				return profile
			end,
		}
		local service = e:Load("src/server/Services/PlayerListService").Start(data)
		local folder, stats = e.Objects[1], {}
		for _, object in ipairs(e.Objects) do
			if object.Parent == folder then
				stats[object.Name] = object
			end
		end
		assert(folder.Parent == player and #e.Objects == 8)
		assert(stats.Coins.ClassName == "NumberValue" and stats.Coins.Value == 9e15)
		assert(stats.Rebirths.ClassName == "IntValue" and stats.Rebirths.Value == 3)
		assert(stats.Rarest.ClassName == "StringValue" and stats.Rarest.Value == "Rare")
		local priorities, primary = {}, nil
		for _, object in ipairs(e.Objects) do
			if object.Name == "Priority" then
				priorities[object.Parent.Name] = object.Value
			end
			if object.Name == "IsPrimary" then
				primary = object
			end
		end
		assert(primary.Parent == stats.Coins and primary.Value == true)
		assert(priorities.Coins == 3 and priorities.Rebirths == 2 and priorities.Rarest == 1)
		local before = writes
		service.Refresh()
		service.Refresh()
		assert(writes == before, "Unchanged stats were assigned")
		profile.Coins = 3400000000
		assert(stats.Coins.Value == 9e15)
		assert(e:Resume(e.Threads[1]) == 1)
		assert(stats.Coins.Value == 3400000000 and writes == before + 1)
		profile.Coins = 1200000
		service.Refresh()
		assert(stats.Coins.Value == 1200000 and #e.Objects == 8)
		profile = nil
		service.Refresh()
		assert(folder.Destroyed)
	end
)
