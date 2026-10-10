local function globalFixture()
	local e = environment()
	local Global = e:Load("src/server/Services/GlobalLeaderboard")
	local config = e:Load("src/shared/Config/Leaderboards")
	local stats = e:Load("src/shared/LeaderboardStats").new(e:Load("src/shared/Config/Items"))
	local f = { Now = 0, Enabled = true, Budget = true, Calls = {}, Names = 0, Jobs = {}, Waits = {} }
	local function store(board)
		local s = { Records = {} }
		function s:SetAsync(key, value)
			table.insert(f.Calls, board .. ":write:" .. key)
			if f.Fail and f.Fail > 0 then
				f.Fail -= 1
				error("injected network failure")
			end
			self.Records[key] = copy(value)
		end
		function s:RemoveAsync(key)
			table.insert(f.Calls, board .. ":remove:" .. key)
			self.Records[key] = nil
		end
		function s:UpdateAsync(key, transform)
			local value = transform(copy(self.Records[key]))
			self:SetAsync(key, value)
			return copy(value)
		end
		function s:GetAsync(key)
			table.insert(f.Calls, board .. ":read:" .. key)
			if f.ReadError then
				error("injected read failure")
			end
			return copy(self.Records[key])
		end
		function s:GetSortedAsync(ascending, count)
			assert(not ascending and count == 10)
			table.insert(f.Calls, board .. ":sorted")
			if f.ReadError then
				error("injected sorted failure")
			end
			local page = {}
			for key, value in pairs(self.Records) do
				table.insert(page, { key = key, value = value })
			end
			table.sort(page, function(a, b)
				return a.value > b.value
			end)
			while #page > count do
				table.remove(page)
			end
			return {
				GetCurrentPage = function()
					return page
				end,
			}
		end
		return s
	end
	f.Stores = { Coins = store("Coins"), Rarest = store("Rarest"), Flushes = store("Flushes") }
	f.Details = store("Details")
	local io = {
		Stores = f.Stores,
		Details = f.Details,
		Now = function()
			return f.Now
		end,
		Stamp = function()
			return f.Now
		end,
		Latest = function(key)
			return f.Details:GetAsync(key)
		end,
		Enabled = function()
			return f.Enabled
		end,
		Budget = function()
			return f.Budget
		end,
		Wait = function(seconds)
			table.insert(f.Waits, seconds)
		end,
		Spawn = function(callback)
			table.insert(f.Jobs, callback)
		end,
		Name = function(id)
			f.Names += 1
			if f.NameError then
				error("name unavailable")
			end
			return "Offline " .. id
		end,
	}
	f.Global = Global.new(stats, config, io)
	f.Module, f.Config, f.Env = Global, config, e
	function f:Run()
		while #self.Jobs > 0 do
			table.remove(self.Jobs, 1)()
		end
	end
	function f:Profile(coins, flushes)
		return { Coins = coins, Stats = { Flushes = flushes, RarestItemId = "Poop", RarestChance = 1e300 } }
	end
	function f:Refresh()
		self.Global:Refresh({ Coins = 10, Rarest = 10, Flushes = 10 })
	end
	return f
end
test("global boards: monotonic integer encoding, fractions, huge values and invalid input", function()
	local f = globalFixture()
	local last = -1
	for _, value in ipairs({ 0, 0.001, 0.5, 1, 2, 100, 1e6, 2 ^ 63, 1e100, 1e300, 1.7976931348623157e308 }) do
		local score = f.Module.Encode(value, f.Config.EncodingScale)
		assert(score > last and score % 1 == 0 and score < 2 ^ 53)
		last = score
	end
	for _, value in ipairs({ -1, math.huge, -math.huge, 0 / 0, "5", false }) do
		assert(f.Module.Encode(value, f.Config.EncodingScale) == nil)
	end
	-- Quantization is monotonic, though adjacent values can share a bucket.
	for i = 1, 10000 do
		assert(f.Module.Encode(i, 1e6) <= f.Module.Encode(i + 0.01, 1e6))
	end
end)
test("global boards: changed-only 90s writes, nonblocking snapshots and final deduplication", function()
	local f = globalFixture()
	local p = f:Profile(1e100, 1)
	f.Global:Submit(1, p, false)
	assert(#f.Calls == 0 and #f.Jobs == 1, "Submit must not perform network requests")
	p.Coins = 2e100
	f:Run()
	assert(f.Details.Records["1"].Coins == 1e100, "Snapshot mutated after queuing")
	assert(#f.Calls == 5)
	f.Now = 89
	f.Global:Submit(1, p, false)
	f:Run()
	assert(#f.Calls == 5)
	f.Now = 90
	f.Global:Submit(1, p, false)
	f:Run()
	assert(#f.Calls == 8, "Only coins plus exact metadata and reconciliation changed")
	f.Now = 180
	f.Global:Submit(1, p, false)
	f:Run()
	assert(#f.Calls == 8, "Unchanged profiles must not write")
	f.Global:Submit(1, p, true)
	f.Global:Submit(1, p, true)
	f:Run()
	assert(#f.Calls == 13, "Leave/shutdown must publish once, even within the interval")
end)
test("global boards: offline cache, exact huge values, live overrides, cached names and read fallback", function()
	local f = globalFixture()
	f.Global:Submit(1, f:Profile(1e100, 50), false)
	f.Global:Submit(2, f:Profile(50, 100), false)
	f:Run()
	f:Refresh()
	local rows, healthy = f.Global:Rows({}, "Coins")
	assert(healthy and #rows == 2 and rows[1].Value == 1e100 and rows[1].Name == "Offline 1")
	assert(f.Names == 2, "Names must be shared across all three boards")
	local live = { { UserId = 1, Name = "Live", Profile = f:Profile(1, 500) } }
	rows = f.Global:Rows(live, "Coins")
	assert(#rows == 2 and rows[1].UserId == 2 and rows[2].Name == "Live" and rows[2].Value == 1)
	local calls = #f.Calls
	f:Refresh()
	assert(#f.Calls == calls, "Top reads must be throttled")
	f.Now = 90
	f:Refresh()
	assert(f.Names == 2)
	f.ReadError = true
	f.Now = 180
	f:Refresh()
	rows, healthy = f.Global:Rows(live, "Coins")
	assert(not healthy and #rows == 1 and rows[1].Name == "Live")
	f.ReadError = false
	f.Now = 270
	f:Refresh()
	assert(select(2, f.Global:Rows({}, "Coins")))
end)
test("global boards: admin policy, removal tombstones and cached exclusion", function()
	local f = globalFixture()
	f.Env:Load("src/shared/Config/Admin").CountAdminProfilesInRankings = false
	local p = f:Profile(100, 10)
	f.Global:Submit(1, p, false)
	f:Run()
	f:Refresh()
	p.Admin = { Touched = true }
	assert(#f.Global:Rows({ { UserId = 1, Name = "Admin", Profile = p } }, "Coins") == 0)
	f.Global:Submit(1, p, true)
	f:Run()
	for _, store in pairs(f.Stores) do
		assert(store.Records["1"] == nil)
	end
	assert(f.Details.Records["1"].Admin.Touched)
	-- Even an old index surviving a failed removal is hidden by metadata.
	f.Stores.Coins.Records["1"] = f.Module.Encode(100, 1e6)
	f.Now = 90
	f:Refresh()
	assert(#f.Global:Rows({}, "Coins") == 0)
	f.Env:Load("src/shared/Config/Admin").CountAdminProfilesInRankings = true
	f.Now = 180
	f.Global:Submit(1, p, false)
	f:Run()
	assert(f.Stores.Coins.Records["1"] ~= nil, "Honor the existing configurable admin policy")
end)
test("global boards: budgets, backoff, failed writes stay dirty, API-disabled safety and failed names", function()
	local f = globalFixture()
	local p = f:Profile(50, 1)
	f.Enabled = false
	f.Global:Submit(1, p, true)
	f:Refresh()
	assert(#f.Jobs == 0 and #f.Calls == 0)
	f.Enabled, f.Budget = true, false
	f.Global:Submit(1, p, false)
	f:Run()
	assert(#f.Calls == 0 and #f.Waits == 2 and f.Waits[1] == 2 and f.Waits[2] == 4)
	f.Budget, f.Fail, f.Now = true, 2, 90
	f.Global:Submit(1, p, false)
	f:Run()
	assert(#f.Calls == 7 and f.Global.States[1].Ack.Coins == 50)
	f.NameError = true
	f:Refresh()
	assert(f.Global:Rows({}, "Coins")[1].Name == "User 1")
	f.Now = 180
	f:Refresh()
	assert(f.Names == 1, "Failed lookups must also be cached")
end)
test("global boards: close hook snapshots before save and profile persistence never waits", function()
	local e = environment()
	local data = e:Load("src/server/Services/DataService")
	local player = e:Player(999)
	data:Load(player)
	data:Get(player).Coins = 123
	local captured
	data.BeforeClose = function(who, profile)
		assert(who == player and not data.Saving[player])
		captured = profile.Coins
	end
	data:Close(player)
	assert(captured == 123 and e.Store.Records.Player_999.Data.Coins == 123)
	local second = e:Player(998)
	data:Load(second)
	data:Get(second).Coins = 456
	data.BeforeClose = function()
		error("leaderboard unavailable")
	end
	data:Close(second)
	assert(e.Store.Records.Player_998.Data.Coins == 456, "Leaderboard failures must never prevent profile saving")
end)
test("global boards: late old-server publication cannot replace newer metadata", function()
	local f = globalFixture()
	f.Global.IO.ServerId = "old"
	f.Global:Submit(1, f:Profile(1000, 1), false)
	local newer = f.Module.new(f.Global.Stats, f.Config, f.Global.IO)
	f.Global.IO.ServerId = "new"
	f.Now = 1
	newer:Submit(1, f:Profile(10, 2), false)
	-- Commit the new server first, then resume the old server's delayed job.
	table.remove(f.Jobs, 2)()
	f:Run()
	assert(f.Details.Records["1"].Coins == 10)
	assert(f.Stores.Coins.Records["1"] == f.Module.Encode(10, 1e6))
end)
test("global boards: yielding ordered write across a server handoff is reconciled", function()
	local f = globalFixture()
	f.Global.IO.ServerId = "old"
	f.Global:Submit(1, f:Profile(1000, 1), false)
	local newer = f.Module.new(f.Global.Stats, f.Config, f.Global.IO)
	f.Global.IO.ServerId = "new"
	local original = f.Stores.Coins.SetAsync
	local once = false
	f.Stores.Coins.SetAsync = function(store, key, value)
		if not once then
			once = true
			f.Now = 1
			newer:Submit(1, f:Profile(10, 2), false)
			table.remove(f.Jobs, 1)()
		end
		original(store, key, value)
	end
	f:Run()
	assert(f.Details.Records["1"].Coins == 10)
	assert(f.Stores.Coins.Records["1"] == f.Module.Encode(10, 1e6))
	assert(f.Stores.Flushes.Records["1"] == f.Module.Encode(2, 1e6))
end)
test("global boards: details read failure falls back on all boards sharing that user", function()
	local f = globalFixture()
	f.Global:Submit(1, f:Profile(1000, 1), false)
	f:Run()
	f.Details.GetAsync = function()
		error("details throttled")
	end
	f:Refresh()
	for _, key in ipairs({ "Coins", "Flushes", "Rarest" }) do
		assert(not select(2, f.Global:Rows({}, key)))
	end
end)
test("global boards: partial publication stays dirty and retries without exposing wrong exact values", function()
	local f = globalFixture()
	local original = f.Stores.Coins.SetAsync
	f.Stores.Coins.SetAsync = function()
		error("coins throttled")
	end
	f.Global:Submit(1, f:Profile(1000, 1), false)
	f:Run()
	assert(not f.Global.States[1].Ack)
	f:Refresh()
	assert(#f.Global:Rows({}, "Coins") == 0)
	f.Stores.Coins.SetAsync = original
	f.Now = 90
	f.Global:Submit(1, f:Profile(1000, 1), false)
	f:Run()
	f:Refresh()
	assert(f.Global:Rows({}, "Coins")[1].Value == 1000)
end)
test("global boards: real adapter gates Studio writes on API probe, isolates stores and queues shutdown", function()
	for _, apiEnabled in ipairs({ false, true }) do
		local f = globalFixture()
		local e = environment({ Studio = true })
		local storeNames = {}
		e.Globals.Enum.DataStoreRequestType =
			{ StandardRead = "read", StandardWrite = "write", OrderedWrite = "ordered", OrderedRemove = "remove" }
		e.Services.DataStoreService = {
			GetDataStore = function(_, name)
				table.insert(storeNames, name)
				return f.Details
			end,
			GetOrderedDataStore = function(_, name)
				table.insert(storeNames, name)
				return f.Stores[name:match("_([^_]+)$")]
			end,
			GetRequestBudgetForRequestType = function()
				return 100
			end,
		}
		f.ReadError = not apiEnabled
		e.Services.Players.GetNameFromUserIdAsync = function()
			return "Offline"
		end
		local player = e:Player(1)
		e.Services.Players.List = { player }
		local profile = f:Profile(100, 1)
		local data = {
			Profiles = { [player] = profile },
			NoPersistence = {},
			Get = function()
				return profile
			end,
		}
		local rows = table.create(10, {})
		local stats = e:Load("src/shared/LeaderboardStats").new(e:Load("src/shared/Config/Items"))
		local global = e:Load("src/server/Services/GlobalLeaderboardService")
			.Start(data, { Coins = rows, Flushes = rows, Rarest = rows }, stats)
		if not apiEnabled then
			-- Exhaust the probe's bounded retries without enabling writes.
			e:Resume(e.Threads[1])
			e:Resume(e.Threads[1])
		end
		data.BeforeClose(player, profile)
		e.Shutdown()
		for _, name in ipairs(storeNames) do
			assert(name:find("ToiletRNG_Studio_Leaderboards_v1_", 1, true) == 1)
		end
		if apiEnabled then
			assert(f.Details.Records["1"].Coins == 100 and global.States[1].Ack.Coins == 100)
		else
			assert(not f.Details.Records["1"] and not global.States[1], "Disabled Studio API access must never write")
		end
	end
end)
