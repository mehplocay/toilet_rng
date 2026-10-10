local Service = {}
function Service.Start(data, boards, stats)
	local Players = game:GetService("Players")
	local DataStores = game:GetService("DataStoreService")
	local studio = game:GetService("RunService"):IsStudio()
	local config = require(game.ReplicatedStorage.Shared.Config.Leaderboards)
	local Global = require(script.Parent.GlobalLeaderboard)
	local stores, details
	local ready = false
	local stopping = false
	local listTokens, listTime = 3, os.clock()
	local fresh = Instance.new("DataStoreGetOptions")
	fresh.UseCache = false
	local io = {
		Now = os.clock,
		ServerId = game.JobId,
		Stamp = function()
			return workspace:GetServerTimeNow()
		end,
		Latest = function(key)
			return details:GetAsync(key, fresh)
		end,
		Wait = task.wait,
		Spawn = task.spawn,
		Enabled = function()
			return ready
		end,
		Name = function(id)
			return Players:GetNameFromUserIdAsync(id)
		end,
		Budget = function(kind)
			if kind == "StandardUpdate" then
				return DataStores:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.StandardRead)
						> config.SaveBudgetReserve
					and DataStores:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.StandardWrite)
						> config.SaveBudgetReserve
			end
			-- Roblox documents OrderedList budget introspection as always zero.
			-- Three calls per 90s stay below even the empty-server default (5/min).
			if kind == "OrderedList" then
				local now = os.clock()
				listTokens = math.min(3, listTokens + (now - listTime) / 20)
				listTime = now
				if listTokens < 1 then
					return false
				end
				listTokens -= 1
				return true
			end
			local reserve = if kind == "StandardRead" or kind == "StandardWrite" then config.SaveBudgetReserve else 0
			return DataStores:GetRequestBudgetForRequestType(Enum.DataStoreRequestType[kind]) > reserve
		end,
	}
	local global = Global.new(stats, config, io)
	local counts = {}
	for key, board in pairs(boards) do
		counts[key] = #board
	end
	-- Close takes an immutable score snapshot before its own save starts yielding.
	-- The independent leaderboard worker never delays or joins the profile save.
	data.BeforeClose = function(player, profile)
		if not data.NoPersistence[player] then
			global:Submit(player.UserId, profile, true)
		end
	end
	task.spawn(function()
		local prefix = if studio then config.StudioPrefix else config.StorePrefix
		local ok = pcall(function()
			details = DataStores:GetDataStore(prefix .. "Details")
			stores = {}
			for key in pairs(counts) do
				stores[key] = DataStores:GetOrderedDataStore(prefix .. key)
			end
		end)
		if not ok then
			warn("Global leaderboards unavailable; using local rankings.")
			return
		end
		io.Details, io.Stores = details, stores
		while not stopping do
			if not ready then
				-- No script-readable Studio API-access toggle: a read-only probe must
				-- succeed before enabling any leaderboard writes (including on exit).
				ready = global:Request("StandardRead", function()
					details:GetAsync("ApiAccessProbe")
				end)
				if not ready then
					task.wait(config.ReadSeconds)
					continue
				end
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = data:Get(player)
				if profile and not data.NoPersistence[player] then
					global:Submit(player.UserId, profile, false)
				end
			end
			global:Refresh(counts)
			task.wait(config.PollSeconds)
		end
	end)
	game:BindToClose(function()
		stopping = true
		for player, profile in pairs(data.Profiles) do
			if not data.NoPersistence[player] then
				global:Submit(player.UserId, profile, true)
			end
		end
		local deadline = os.clock() + 25
		repeat
			local busy = false
			for _, state in pairs(global.States) do
				busy = busy or state.Busy
			end
			if not busy then
				break
			end
			task.wait(0.1)
		until os.clock() >= deadline
	end)
	return global
end
return Service
