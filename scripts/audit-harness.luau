-- Appended after the source bundle by check-audit.ps1. No production code is rewritten.
local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, entry in pairs(value) do
		result[key] = copy(entry)
	end
	return result
end

local function signal()
	local self = { Handlers = {} }
	function self:Connect(callback)
		table.insert(self.Handlers, callback)
		return { Disconnect = function() end }
	end
	function self:Fire(...)
		for _, callback in ipairs(self.Handlers) do
			callback(...)
		end
	end
	return self
end

local function environment(options)
	options = options or {}
	local env = { Now = 20000 * 86400, Threads = {}, Warnings = {}, Results = {}, Syncs = 0 }
	function env:Resume(thread, ...)
		local ok, value = coroutine.resume(thread, ...)
		assert(ok, value)
		return value
	end
	function env:Spawn(callback, ...)
		local thread = coroutine.create(callback)
		table.insert(self.Threads, thread)
		self:Resume(thread, ...)
		return thread
	end
	local players = { PlayerAdded = signal(), PlayerRemoving = signal(), List = {} }
	function players:GetPlayers()
		return table.clone(self.List)
	end
	env.Players = players
	function env:Player(id)
		local player = {
			UserId = id,
			Name = "Tester",
			DisplayName = "Tester",
			Parent = players,
			CharacterAdded = signal(),
			CharacterRemoving = signal(),
			Attributes = {},
		}
		function player:SetAttribute(key, value)
			self.Attributes[key] = value
		end
		function player:Kick(reason)
			self.Kicked = reason
		end
		return player
	end
	local store = { Records = {}, Calls = 0, Writes = 0 }
	function store:UpdateAsync(key, transform)
		self.Calls += 1
		if self.Before then
			self.Before(key)
		end
		local value = transform(copy(self.Records[key]))
		if self.Replay then
			self.Replay(key)
			value = transform(copy(self.Records[key]))
		end
		if value == nil then
			return nil
		end
		self.Writes += 1
		self.Records[key] = copy(value)
		if self.After then
			self.After(key)
		end
		return copy(value)
	end
	env.Store = store
	local guid = 0
	local marketplace = { PromptGamePassPurchaseFinished = signal() }
	function marketplace:UserOwnsGamePassAsync()
		if self.Lookup then
			return self.Lookup()
		end
		return false
	end
	env.Marketplace = marketplace
	local services = {
		Players = players,
		DataStoreService = {
			GetDataStore = function()
				if options.NoStore then
					error("Mock store unavailable")
				end
				return store
			end,
		},
		HttpService = {
			GenerateGUID = function()
				guid += 1
				return "guid-" .. guid
			end,
		},
		RunService = {
			IsStudio = function()
				return options.Studio == true
			end,
		},
		MarketplaceService = marketplace,
	}
	local nodes, cache = {}, {}
	local function node(path)
		if nodes[path] then
			return nodes[path]
		end
		local object = { Path = path }
		nodes[path] = object
		local parent, name = path:match("^(.*)/([^/]+)$")
		if parent then
			object.Parent = node(parent)
			object.Parent[name] = object
		end
		return object
	end
	for path in pairs(sources) do
		node(path)
	end
	local game = { JobId = "same-server", ReplicatedStorage = { Shared = node("src/shared") } }
	services.ReplicatedStorage = game.ReplicatedStorage
	function game:GetService(name)
		return assert(services[name], name)
	end
	function game:BindToClose(callback)
		env.Shutdown = callback
	end
	local globals = {
		game = game,
		Color3 = {
			fromRGB = function(r, g, b)
				return { R = r / 255, G = g / 255, B = b / 255 }
			end,
		},
		warn = function(...)
			table.insert(env.Warnings, { ... })
		end,
		os = {
			time = function()
				return env.Now
			end,
			clock = function()
				return env.Now
			end,
		},
		task = {
			wait = function(seconds)
				return coroutine.yield(seconds)
			end,
			spawn = function(callback, ...)
				return env:Spawn(callback, ...)
			end,
		},
		workspace = {
			GetServerTimeNow = function()
				return env.Now
			end,
		},
		Random = {
			new = function()
				return {
					NextNumber = function()
						return 0.99
					end,
				}
			end,
		},
	}
	function env:Remote()
		return {
			OnServerEvent = signal(),
			FireClient = function(_, player, ...)
				table.insert(self.Results, { Player = player, Payload = copy({ ... }) })
			end,
			FireAllClients = function(_, ...)
				table.insert(self.Results, { Broadcast = true, Payload = copy({ ... }) })
			end,
		}
	end
	function env:Sync()
		self.Syncs += 1
	end
	globals.Instance = {
		new = function(class)
			local object = if class == "RemoteEvent" then env:Remote() else {}
			if class == "RemoteEvent" then
				env.CreatedRemotes = env.CreatedRemotes or {}
				table.insert(env.CreatedRemotes, object)
			end
			return object
		end,
	}
	local loadModule
	loadModule = function(object)
		local path = object.Path
		if cache[path] then
			return cache[path]
		end
		local fn, err = loadstring(assert(sources[path], path), path)
		assert(fn, err)
		setfenv(
			fn,
			setmetatable({ script = object, require = loadModule }, {
				__index = function(_, key)
					return globals[key] or getfenv()[key]
				end,
			})
		)
		local result = fn()
		cache[path] = result
		return result
	end
	function env:Load(path)
		return loadModule(node(path))
	end
	function env:Override(path, value)
		cache[path] = value
	end
	return env
end
