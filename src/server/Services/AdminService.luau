local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Admin)
local Items = require(Shared.Config.Items)
local Rules = require(script.Parent.Parent.Admin.Rules)
local Mutations = require(script.Parent.Parent.Admin.Mutations)
local Authorization = require(script.Parent.Parent.Admin.Authorization)
local RateLimiter = require(script.Parent.RateLimiter)
local Service = {}
function Service.new(data, sync, runtime)
	local self = { Endpoints = {}, Busy = {}, Confirmations = {}, Granting = {} }
	local rules = Rules.new(
		Config,
		Items,
		require(Shared.Config.Toilets),
		require(Shared.Config.Upgrades),
		require(Shared.Config.Rebirth)
	)
	local limiter = RateLimiter.new(Config.Limits)
	local auth = Authorization.new(Config, os.clock, function(player)
		return runtime:Present(player)
	end, function(id)
		return runtime:GroupOwner(id)
	end)
	self.Authorization, self.Limiter = auth, limiter
	local function reply(player, sequence, success, message, extra)
		local endpoint = self.Endpoints[player]
		if endpoint and auth:Allowed(player) and data:Get(player) then
			endpoint.Remote:FireClient(player, sequence, { Success = success, Message = message, Data = extra })
		end
	end
	function self:Request(owner, sender, sequence, action, args, ...)
		-- The remote lives in one PlayerGui; even a leaked reference cannot target its owner.
		if sender ~= owner or not self.Endpoints[owner] or self.Busy[owner] or not limiter:Allow(sender, "Request") then
			return
		end
		if select("#", ...) ~= 0 or not Rules.Integer(sequence, 1, 9e15) or not rules:Valid(action, args) then
			return
		end
		local endpoint = self.Endpoints[owner]
		if sequence <= endpoint.LastSequence then
			return
		end
		endpoint.LastSequence = sequence
		self.Busy[owner] = true
		local ok, err = pcall(function()
			if not auth:Allowed(sender) then
				self:Remove(sender)
				return
			end
			local profile = data:Get(sender)
			if not profile or data.Saving[sender] then
				reply(sender, sequence, false, "Profile unavailable or saving. Retry when ready.")
				return
			end
			if
				(rules.Mutation[action] and not limiter:Allow(sender, "Mutation"))
				or (rules.World[action] and not limiter:Allow(sender, "World"))
			then
				reply(sender, sequence, false, "Cooling down. Profile edits: 5 seconds; world tests: 8 seconds.")
				return
			end
			runtime:Log(sender, action, args)
			if action == "PrepareReset" then
				local token = runtime:Token()
				self.Confirmations[sender] =
					{ Token = token, Expires = os.clock() + Config.ResetConfirmationSeconds, Profile = profile }
				reply(
					sender,
					sequence,
					true,
					"Confirm RESET within 30 seconds. Your current profile will be backed up.",
					{ Token = token }
				)
			elseif rules.Mutation[action] then
				local imported
				if action == "Reset" then
					local confirmation = self.Confirmations[sender]
					self.Confirmations[sender] = nil
					if
						not confirmation
						or confirmation.Token ~= args.Token
						or os.clock() >= confirmation.Expires
						or confirmation.Profile ~= profile
					then
						reply(sender, sequence, false, "Reset confirmation expired or profile changed. Start again.")
						return
					end
				elseif action == "Import" then
					local decoded, result = pcall(runtime.Decode, runtime, args.Json)
					if not decoded or not Rules.JsonTree(result, Config) then
						reply(sender, sequence, false, "Invalid or oversized profile JSON.")
						return
					end
					imported = result
				end
				local replacement = Mutations.Build(data, profile, action, args, os.time(), imported)
				if not replacement then
					reply(sender, sequence, false, "Rejected: capacity, balance, or display reservation limit.")
					return
				end
				if not data:ReplaceAndSave(sender, profile, replacement) then
					return
				end
				if not auth:Allowed(sender) or data:Get(sender) ~= replacement then
					return
				end
				sync(sender)
				if action == "ForceDrop" then
					runtime:ForceDrop(sender, replacement, args.ItemId)
				end
				reply(
					sender,
					sequence,
					true,
					if data.NoPersistence[sender] then "Applied in memory (NoPersistence)." else "Applied and saved.",
					runtime:Snapshot(sender, replacement)
				)
			elseif action == "Export" then
				reply(
					sender,
					sequence,
					true,
					"Select the text and copy it. Backup, if present, is under Admin.Backup.",
					{ Json = runtime:Encode(data.Sanitize(profile)) }
				)
			elseif action == "Hello" or action == "Snapshot" then
				reply(
					sender,
					sequence,
					true,
					"Owner tools ready. Changes affect your own profile.",
					runtime:Snapshot(sender, profile)
				)
			else
				local success, message, result = runtime:Execute(sender, profile, action, args)
				if action == "TestPasses" and success then
					sync(sender)
				end
				reply(sender, sequence, success, message, result)
			end
		end)
		self.Busy[owner] = nil
		if not ok then
			warn("Admin action failed", owner.UserId, action, tostring(err))
			reply(owner, sequence, false, "Action failed. Check server output; do not assume it was rolled back.")
		end
	end
	function self:Grant(player)
		if self.Endpoints[player] or self.Granting[player] then
			return
		end
		local lifetime = {}
		self.Granting[player] = lifetime
		local ok, allowed = pcall(function()
			return auth:Allowed(player)
		end)
		if self.Granting[player] ~= lifetime then
			return
		end
		if not ok or not allowed or not data:Get(player) then
			self.Granting[player] = nil
			return
		end
		local delivered, endpoint = pcall(runtime.Deliver, runtime, player)
		if not delivered then
			self.Granting[player] = nil
			warn("Admin UI delivery failed", player.UserId, endpoint)
			return
		end
		if self.Granting[player] ~= lifetime or not auth:Allowed(player) or not data:Get(player) then
			if endpoint then
				endpoint.Gui:Destroy()
			end
			if self.Granting[player] == lifetime then
				self.Granting[player] = nil
			end
			return
		end
		self.Granting[player] = nil
		if not endpoint then
			return
		end
		endpoint.LastSequence = 0
		self.Endpoints[player] = endpoint
		endpoint.Connection = endpoint.Remote.OnServerEvent:Connect(function(sender, ...)
			self:Request(player, sender, ...)
		end)
		-- Parent last: the LocalScript cannot send Hello before its listener exists.
		runtime:Activate(player, endpoint)
	end
	function self:Remove(player)
		local endpoint = self.Endpoints[player]
		self.Endpoints[player], self.Confirmations[player], self.Granting[player] = nil, nil, nil
		if endpoint then
			endpoint.Connection:Disconnect()
			endpoint.Gui:Destroy()
		end
		runtime:Remove(player)
		auth:Remove(player)
		limiter:Remove(player)
		-- A pending request owns Busy until its yielding transaction returns.
	end
	return self
end
function Service.Start(data, sync, world, events, remotes)
	local runtime = require(script.Parent.Parent.Admin.Runtime).new(data, world, events, remotes)
	local service = Service.new(data, sync, runtime)
	runtime:Start(service)
	return service
end
return Service
