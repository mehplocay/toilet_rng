-- The scheduler and all network operations are injected for deterministic audits.
local Global = {}
Global.__index = Global
local keys = { "Flushes", "Coins", "Rarest" }
function Global.Encode(value, scale)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return nil
	end
	-- log(1 + x) avoids negative scores; never multiply the unbounded game value.
	return math.floor(math.log(1 + value) * scale)
end
function Global.new(stats, config, io)
	return setmetatable(
		{ Stats = stats, Config = config, IO = io, States = {}, Cache = {}, Names = {}, Healthy = {} },
		Global
	)
end
function Global:Snapshot(id, profile)
	local snapshot = {
		Coins = profile.Coins,
		Stats = self.Stats:Sanitize(profile.Stats),
		Admin = { Touched = type(profile.Admin) == "table" and profile.Admin.Touched == true },
	}
	local values = {}
	for _, key in ipairs(keys) do
		local ranked = self.Stats:Rank({ { UserId = id, Name = "", Profile = snapshot } }, key)
		if ranked[1] then
			values[key] = ranked[1].Value
		end
	end
	-- Store the same sanitized coin balance that local ranking uses.
	snapshot.Coins = values.Coins or 0
	return { Profile = snapshot, Values = values }
end
function Global:Request(kind, callback)
	for attempt = 1, self.Config.Attempts do
		local budgetOk, budget = pcall(self.IO.Budget, kind)
		if budgetOk and budget then
			local ok, result = pcall(callback)
			if ok then
				return true, result
			end
		end
		if attempt < self.Config.Attempts then
			self.IO.Wait(2 ^ attempt)
		end
	end
	return false
end
local function same(a, b)
	return a and b and a.Flushes == b.Flushes and a.Coins == b.Coins and a.Rarest == b.Rarest
end
function Global:WriteIndexes(id, snapshot, state, force)
	local key = tostring(id)
	local complete = true
	for _, board in ipairs(keys) do
		local value = snapshot.Values[board]
		local encoded = if value ~= nil then Global.Encode(value, self.Config.EncodingScale) else nil
		if force or not state.Ack or state.Ack[board] ~= value then
			local saved = self:Request(if encoded then "OrderedWrite" else "OrderedRemove", function()
				if encoded then
					self.IO.Stores[board]:SetAsync(key, encoded)
				else
					self.IO.Stores[board]:RemoveAsync(key)
				end
			end)
			complete = complete and saved
		end
	end
	return complete
end
function Global:Write(id, snapshot, state, force)
	local key = tostring(id)
	-- Metadata first: fence old sessions and persist admin exclusion before removals.
	local ok, published = self:Request("StandardUpdate", function()
		return self.IO.Details:UpdateAsync(key, function(old)
			if
				type(old) == "table"
				and type(old.UpdatedAt) == "number"
				and old.UpdatedAt > snapshot.Profile.UpdatedAt
			then
				return old
			end
			return snapshot.Profile
		end)
	end)
	if not ok or not published or published.Token ~= snapshot.Profile.Token then
		return
	end
	local complete = self:WriteIndexes(id, snapshot, state, force)
	-- An ordered request can yield across a server handoff. Reconcile against a
	-- fresh uncached metadata read if a newer publication won in the meantime.
	local found, latest = self:Request("StandardRead", function()
		return self.IO.Latest(key)
	end)
	if not found or type(latest) ~= "table" then
		return
	end
	if latest.Token ~= snapshot.Profile.Token then
		self:WriteIndexes(id, self:Snapshot(id, latest), state, true)
		return
	end
	if complete then
		state.Ack = snapshot.Values
	end
end
function Global:Submit(id, profile, force)
	if not self.IO.Enabled() or id <= 0 then
		return
	end
	local state = self.States[id] or { Next = 0 }
	self.States[id] = state
	local snapshot = self:Snapshot(id, profile)
	if force and same(state.Final, snapshot.Values) then
		return
	end
	if not force and (self.IO.Now() < state.Next or same(state.Ack, snapshot.Values)) then
		return
	end
	state.Next = self.IO.Now() + self.Config.WriteSeconds
	state.Sequence = (state.Sequence or 0) + 1
	state.LastStamp = math.max(self.IO.Stamp(), (state.LastStamp or -1) + 0.000001)
	snapshot.Profile.UpdatedAt = state.LastStamp
	snapshot.Profile.Token = (self.IO.ServerId or "") .. ":" .. id .. ":" .. state.Sequence
	state.Final = if force then snapshot.Values else nil
	state.Pending = { Snapshot = snapshot, Force = force }
	if state.Busy then
		return
	end
	state.Busy = true
	self.IO.Spawn(function()
		while state.Pending do
			local pending = state.Pending
			state.Pending = nil
			self:Write(id, pending.Snapshot, state, pending.Force)
		end
		state.Busy = false
	end)
end
function Global:Name(id)
	local cached = self.Names[id]
	if cached and self.IO.Now() < cached.Expires then
		return cached.Name
	end
	local ok, name = pcall(self.IO.Name, id)
	local resolved = if ok and type(name) == "string" then name else (if cached then cached.Name else "User " .. id)
	self.Names[id] = {
		Name = resolved,
		Expires = self.IO.Now() + (if ok then self.Config.NameSeconds else self.Config.NameFailureSeconds),
	}
	return resolved
end
function Global:Refresh(counts)
	if not self.IO.Enabled() or self.Reading or self.IO.Now() < (self.NextRead or 0) then
		return
	end
	self.NextRead = self.IO.Now() + self.Config.ReadSeconds
	self.Reading = true
	local details, failed = {}, {}
	for _, board in ipairs(keys) do
		local count = counts[board]
		local ok, page = self:Request("OrderedList", function()
			return self.IO.Stores[board]:GetSortedAsync(false, math.clamp(count, 1, 100)):GetCurrentPage()
		end)
		local entries = {}
		if ok then
			for _, row in ipairs(page) do
				local id = tonumber(row.key)
				if not id or id <= 0 or id % 1 ~= 0 then
					continue
				end
				if details[id] == nil then
					local found, profile = self:Request("StandardRead", function()
						return self.IO.Details:GetAsync(tostring(id))
					end)
					details[id] = if found and type(profile) == "table" then profile else false
					if not found then
						failed[id] = true
					end
				end
				if failed[id] then
					ok = false
				end
				local profile = details[id]
				if profile then
					local ranked = self.Stats:Rank({ { UserId = id, Name = "", Profile = profile } }, board)
					-- Separate stores are not atomic. Hide partial/mismatched publications.
					if ranked[1] and Global.Encode(ranked[1].Value, self.Config.EncodingScale) == row.value then
						table.insert(entries, { UserId = id, Name = self:Name(id), Profile = profile })
					end
				end
			end
		end
		self.Healthy[board] = ok
		if ok then
			self.Cache[board] = entries
		end
	end
	self.Reading = false
end
function Global:Rows(entries, board)
	local merged, live = {}, {}
	-- Include excluded live IDs in this set so their old cached scores vanish too.
	for _, entry in ipairs(entries) do
		live[entry.UserId] = true
		table.insert(merged, entry)
	end
	if self.Healthy[board] then
		for _, entry in ipairs(self.Cache[board] or {}) do
			if not live[entry.UserId] then
				table.insert(merged, entry)
			end
		end
	end
	return self.Stats:Rank(merged, board), self.Healthy[board] == true
end
return Global
