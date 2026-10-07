-- Pure request validation. The command vocabulary is intentionally closed.
local Rules = {}
function Rules.Integer(value, low, high)
	return type(value) == "number" and value == value and value >= low and value <= high and value % 1 == 0
end
function Rules.JsonTree(value, config)
	local nodes, seen = 0, {}
	local function visit(entry, depth)
		nodes += 1
		if nodes > config.MaxImportNodes or depth > config.MaxImportDepth then
			return false
		end
		local kind = type(entry)
		if kind == "table" then
			if seen[entry] or getmetatable(entry) ~= nil then
				return false
			end
			seen[entry] = true
			for key, child in pairs(entry) do
				if type(key) ~= "string" or #key > 80 or not visit(child, depth + 1) then
					return false
				end
			end
			return true
		end
		return kind == "boolean"
			or (kind == "string" and #entry <= 256)
			or (kind == "number" and entry == entry and math.abs(entry) <= 9e15)
	end
	return type(value) == "table" and visit(value, 0)
end
function Rules.new(config, items, toilets, upgrades, rebirth)
	local ids, tracks = {}, {}
	for _, item in ipairs(items) do
		ids[item.Id] = true
	end
	for _, track in ipairs(upgrades.Tracks) do
		tracks[track.Id] = track.MaxLevel
	end
	local integer = Rules.Integer
	local function number(low, high)
		return function(v)
			return integer(v, low, high)
		end
	end
	local function enum(values)
		return function(v)
			return type(v) == "string" and values[v] ~= nil
		end
	end
	local boolean = function(v)
		return type(v) == "boolean"
	end
	local item, count = enum(ids), number(1, config.MaxItemGrant)
	local specs = {
		Hello = {},
		Snapshot = {},
		Export = {},
		PrepareReset = {},
		ResetTutorial = {},
		Reset = {
			Token = function(v)
				return type(v) == "string" and #v <= 80
			end,
		},
		Import = {
			Json = function(v)
				return type(v) == "string" and #v > 0 and #v <= config.MaxImportBytes
			end,
		},
		Give = { ItemId = item, Count = count },
		Display = { ItemId = item, Slot = number(1, 100) },
		Remove = { ItemId = item, Count = count },
		Collection = { ItemId = item, Count = number(0, config.MaxCounter) },
		GiveAll = {},
		AddCoins = { Amount = number(0, config.MaxCoins) },
		SetCoins = { Amount = number(0, config.MaxCoins) },
		Pending = { Slot = number(1, 100), Amount = number(0, config.MaxCoins) },
		IncomeCap = {},
		ClearCooldown = {},
		Toilet = { Level = number(1, #toilets) },
		Upgrade = { Track = enum(tracks), Level = number(0, 100) },
		Rebirth = { Level = number(0, #rebirth.Levels) },
		Flushes = { Amount = number(0, config.MaxCounter) },
		Teleport = {
			Destination = enum({ Hub = true, Home = true, Plot = true, Player = true }),
			Target = number(0, 9e15),
		},
		Speed = { Amount = number(0, config.MaxWalkSpeed) },
		Jump = { Amount = number(0, config.MaxJumpPower) },
		Fly = { Enabled = boolean },
		Noclip = { Enabled = boolean },
		God = { Enabled = boolean },
		TestPasses = { Enabled = boolean },
		RenewMovement = {},
		ForceDrop = { ItemId = item },
		Luck = {},
		Announcement = { ItemId = item },
		Lighting = { Preset = enum(config.LightingPresets) },
		Time = { Hour = number(0, 24) },
		RestoreLighting = {},
		Stats = {},
		Debug = { Kind = enum({ Hitboxes = true, Wayfinding = true }), Enabled = boolean },
		ReloadLabels = {},
		Dummy = { ItemId = item },
	}
	local mutations = {
		Give = true,
		Display = true,
		Remove = true,
		Collection = true,
		GiveAll = true,
		AddCoins = true,
		SetCoins = true,
		Pending = true,
		IncomeCap = true,
		Toilet = true,
		Upgrade = true,
		Rebirth = true,
		Flushes = true,
		ForceDrop = true,
		Import = true,
		Reset = true,
		ResetTutorial = true,
	}
	local world =
		{ ForceDrop = true, Luck = true, Announcement = true, ReloadLabels = true, Dummy = true, Stats = true }
	return {
		Mutation = mutations,
		World = world,
		Valid = function(_, action, args)
			local spec = type(action) == "string" and specs[action]
			if not spec or type(args) ~= "table" or getmetatable(args) ~= nil then
				return false
			end
			local n = 0
			for key, value in pairs(args) do
				n += 1
				if n > 3 or not spec[key] or not spec[key](value) then
					return false
				end
			end
			for key in pairs(spec) do
				if args[key] == nil then
					return false
				end
			end
			return action ~= "Upgrade" or args.Level <= tracks[args.Track]
		end,
	}
end
return Rules
