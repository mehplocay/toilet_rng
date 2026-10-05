local function runPresentationAudit(test, environment, server)
	test(
		"real flush grants once, snapshots actual odds and routes one chat independently of the existing event banner",
		function()
			local e = server()
			local player, profile = e:Join(80)
			e.Players.List = { player }
			local item = e:Load("src/shared/Config/Items")[9]
			e:Load("src/server/Services/RollService").Roll = function()
				return item, 0.00002
			end
			e:Fire("Flush", player)
			assert(profile.Inventory[item.Id] == 1 and profile.Collection[item.Id] == 1)
			local result, banners = nil, 0
			for _, message in ipairs(e.Results) do
				if message.Payload[1] == "Flush" then
					result = message.Payload[2]
				elseif type(message.Payload[1]) == "table" and message.Payload[1].ItemId == item.Id then
					banners += 1
				end
			end
			assert(
				result
					and result.Rarity == item.Rarity
					and result.Chance == item.Chance
					and result.Probability == 0.00002
					and result.FlushId == 1
			)
			assert(banners == 1)
			local before = #e.Results
			e:Resume(e.Threads[2]) -- Single announcement worker, after the autoflush loop.
			assert(#e.Results == before + 1 and e.Results[#e.Results].Payload[1].ItemId == item.Id)
			e:Resume(e.Threads[2])
			assert(#e.Results == before + 1 and profile.Inventory[item.Id] == 1)
		end
	)
	test("presentation patches reject extra/unknown/oversized input; rate limit and persist independently", function()
		local e = server()
		local player, profile = e:Join(81)
		for _, patch in ipairs({
			{},
			{ RevealIntensity = string.rep("A", 10000) },
			{ ChatAnnouncements = 1 },
			{ RevealIntensity = "Off", Coins = 100 },
			{ MusicMuted = true },
		}) do
			e.Now += 1
			e:Fire("PresentationSettings", player, patch)
		end
		assert(profile.Settings.RevealIntensity == "Full" and profile.Settings.ChatAnnouncements)
		e.Now += 3
		e:Fire("PresentationSettings", player, { RevealIntensity = "Reduced" }, "extra")
		assert(profile.Settings.RevealIntensity == "Full")
		e.Now += 3
		e:Fire("PresentationSettings", player, { RevealIntensity = "Off", ChatAnnouncements = false })
		assert(profile.Settings.RevealIntensity == "Off" and not profile.Settings.ChatAnnouncements)
		local results = #e.Results
		for _ = 1, 50 do
			e:Fire("PresentationSettings", player, { RevealIntensity = "Reduced" })
		end
		assert(#e.Results == results + 2)
		assert(profile.Settings.MusicVolume == 0.25 and profile.Coins == 0)
		e.Data:Close(player)
		local replacement = e:Join(81)
		local saved = e.Data:Get(replacement).Settings
		assert(saved.RevealIntensity == "Reduced" and not saved.ChatAnnouncements)
		e.Now += 180
		e:Fire("PresentationSettings", replacement, { RevealIntensity = "Full" })
		assert(saved.RevealIntensity == "Reduced", "Expired lease allowed preference mutation")
	end)
	test("flush ceiling rejection cannot partially grant Coins, items or reveal results", function()
		for _, field in ipairs({ "Inventory", "Collection", "Flushes" }) do
			local e = server()
			local player, profile = e:Join(82)
			if field == "Flushes" then
				profile.Stats.Flushes = 9e15
			else
				profile[field].Poop = 9e15
			end
			local count = #e.Results
			e:Fire("Flush", player)
			assert(profile.Coins == 0 and profile.Stats.Earned == 0 and #e.Results == count)
		end
	end)
	local function announcements()
		local e = environment()
		local data = { Stopping = false, Profiles = {} }
		function data:Get(player)
			return self.Profiles[player]
		end
		local players = { e:Player(91), e:Player(92), e:Player(93), e:Player(94) }
		e.Players.List = players
		for _, player in ipairs(players) do
			data.Profiles[player] = { Settings = { ChatAnnouncements = true } }
		end
		data.Profiles[players[4]].Settings.ChatAnnouncements = false
		players[1].Name = "<b>Tester\n"
		players[1].IsFriendsWithAsync = function(_, id)
			return id == 92
		end
		local events, remote = {}, e:Remote()
		local queue = e:Load("src/server/Services/AnnouncementService")
			.Start(data, { DropAnnouncement = remote }, events)
		return e, data, players, events, queue, e.Threads[#e.Threads], e:Load("src/shared/Config/Items")
	end
	test(
		"announcements have one event source, exact friend/server audiences, catalog allowlist and five-second dedupe",
		function()
			local e, _, players, events, queue, worker, items = announcements()
			events.Observe(players[1], table.clone(items[6]), 1)
			assert(#queue.Pending == 0)
			events.Observe(players[1], items[6], 1)
			e:Resume(worker)
			assert(#e.Results == 1 and e.Results[1].Player == players[2])
			assert(e.Results[1].Payload[1].PlayerName == "bTester")
			assert(e.Results[1].Payload[1].Coins == nil)
			events.Observe(players[1], items[9], 2)
			e.Now += 5
			events.Observe(players[1], items[9], 2)
			assert(#queue.Pending == 0, "Suppressed ID replayed")
			events.Observe(players[1], items[9], 3)
			e:Resume(worker)
			assert(#e.Results == 4)
			for i = 2, 4 do
				assert(e.Results[i].Player ~= players[4])
			end
		end
	)
	test("yielding friendship rechecks departure, profile identity, opt-out and expiry; no stale delivery", function()
		for _, mutation in ipairs({ "Leave", "Profile", "Preference", "Timeout", "Failure" }) do
			local e, data, players, events, queue, worker, items = announcements()
			players[1].IsFriendsWithAsync = function(_, id)
				if id == 92 then
					coroutine.yield("friend held")
					if mutation == "Failure" then
						error("backend")
					end
					return true
				end
				return false
			end
			events.Observe(players[1], items[6], 1)
			e:Resume(worker)
			assert(#e.Results == 0)
			if mutation == "Leave" then
				players[1].Parent = nil
				e.Players.PlayerRemoving:Fire(players[1])
			elseif mutation == "Profile" then
				data.Profiles[players[1]] = {}
			elseif mutation == "Preference" then
				data.Profiles[players[2]].Settings.ChatAnnouncements = false
			elseif mutation == "Timeout" then
				e.Now += 20
			end
			e:Resume(worker)
			assert(#e.Results == 0, mutation)
			if mutation == "Leave" then
				assert(queue.Seen[players[1]] == nil and queue.Sent[players[1]] == nil)
			end
		end
	end)
	test(
		"leaderstats expose only bounded numeric Coins and catalog Rarest, throttle and remove stale profiles",
		function()
			local e = environment()
			local player = e:Player(99)
			e.Players.List = { player }
			local profile =
				{ Coins = 1234, Stats = { RarestItemId = "KingPoop" }, Inventory = { Mystery = 9 }, Settings = {} }
			local data = {
				Get = function()
					return profile
				end,
			}
			local service = e:Load("src/server/Services/PlayerListService").Start(data)
			local folder, coins, rarest
			for _, object in ipairs(e.Objects) do
				if object.Name == "leaderstats" then
					folder = object
				elseif object.Name == "Coins" then
					coins = object
				elseif object.Name == "Rarest" then
					rarest = object
				end
			end
			assert(folder.Parent == player and coins.Value == 1234 and rarest.Value == "Mythic")
			assert(#e.Objects == 4)
			profile.Coins = 1e6
			assert(coins.Value == 1234)
			service.Refresh()
			assert(coins.Value == 1e6 and #e.Objects == 4)
			profile.Coins, profile.Stats.RarestItemId = math.huge, "forged"
			service.Refresh()
			assert(coins.Value == 0 and rarest.Value == "None")
			profile = nil
			service.Refresh()
			assert(folder.Destroyed)
		end
	)
end
