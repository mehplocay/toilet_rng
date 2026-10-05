-- Pure validation for persisted server-awarded records. Never accept client ranking values.
local Stats = {}
function Stats.Integer(value)
	return if type(value) == "number" and value == value and value >= 0 and value <= 9e15 then math.floor(value) else 0
end
function Stats.new(items)
	local self = { Items = {} }
	for _, item in ipairs(items) do
		self.Items[item.Id] = item
	end
	return setmetatable(self, { __index = Stats })
end
function Stats:Sanitize(raw)
	raw = if type(raw) == "table" then raw else {}
	local item = if type(raw.RarestItemId) == "string" then self.Items[raw.RarestItemId] else nil
	return {
		Flushes = Stats.Integer(raw.Flushes),
		Earned = Stats.Integer(raw.Earned),
		RarestItemId = if item then item.Id else "",
		RarestChance = if item then item.Chance else 0,
	}
end
function Stats:Record(profile, item)
	if self.Items[item.Id] ~= item then
		return false
	end
	local stats = self:Sanitize(profile.Stats)
	stats.Flushes = math.min(stats.Flushes + 1, 9e15)
	if item.Chance > stats.RarestChance then
		stats.RarestItemId, stats.RarestChance = item.Id, item.Chance
	end
	profile.Stats = stats
	return true
end
function Stats:Rank(entries, key)
	local rows = {}
	for _, entry in ipairs(entries) do
		local stats = self:Sanitize(entry.Profile.Stats)
		local value = if key == "Coins"
			then Stats.Integer(entry.Profile.Coins)
			elseif key == "Rarest" then stats.RarestChance
			else stats.Flushes
		table.insert(rows, { Name = entry.Name, UserId = entry.UserId, Value = value })
	end
	table.sort(rows, function(a, b)
		return if a.Value == b.Value then a.UserId < b.UserId else a.Value > b.Value
	end)
	return rows
end
return Stats
