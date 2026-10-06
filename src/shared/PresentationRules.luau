local Rules = {}
local NumberFormat = require(if script then script.Parent.NumberFormat else "./NumberFormat")
local tiers = {
	Common = "Pop",
	Uncommon = "Pop",
	Rare = "Burst",
	Epic = "Sparkle",
	Legendary = "Banner",
	Mythic = "Banner",
	Godly = "Cinematic",
	Secret = "Cinematic",
}
function Rules.Tier(rarity, intensity)
	if not tiers[rarity] then
		return nil
	end
	if intensity == "Off" then
		return "Toast"
	end
	if intensity == "Reduced" then
		return "Pop"
	end
	return tiers[rarity]
end
function Rules.Big(tier)
	return tier == "Banner" or tier == "Cinematic"
end
function Rules.RevealQueue(cap)
	local self = { Pending = {}, Active = nil }
	function self:Push(entry)
		if not self.Active then
			self.Active = entry
			return "Play"
		end
		if not Rules.Big(entry.Tier) or #self.Pending >= cap then
			return "Toast"
		end
		table.insert(self.Pending, entry)
		return "Queued"
	end
	function self:Next()
		self.Active = table.remove(self.Pending, 1)
		return self.Active
	end
	function self:Clear()
		table.clear(self.Pending)
		self.Active = nil
	end
	return self
end
function Rules.Integer(value)
	return if type(value) == "number" and value == value and value >= 0 and value <= 9e15 then math.floor(value) else 0
end
function Rules.Abbreviate(value)
	return NumberFormat.Compact(value)
end
function Rules.Escape(text)
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
end
function Rules.Name(name)
	-- Account usernames are platform-controlled ASCII; no DisplayName/free text relay.
	if type(name) ~= "string" then
		return "Player"
	end
	local clean = name:sub(1, 20):gsub("[^%w_]", "")
	return if clean == "" then "Player" else clean
end
function Rules.Audience(rarity)
	return if rarity == "Legendary"
		then "Friends"
		elseif rarity == "Mythic" or rarity == "Godly" or rarity == "Secret" then "Server"
		else nil
end
function Rules.Announcements(config, clock)
	local self = { Pending = {}, Seen = {}, RebirthSeen = {}, AdminSeen = {}, Accepted = {}, Sent = {}, Busy = {} }
	function self:Push(player, item, id, payload)
		local seen = if payload.Admin
			then self.AdminSeen
			elseif payload.Kind == "Rebirth" then self.RebirthSeen
			else self.Seen
		if not Rules.Audience(item.Rarity) or Rules.Integer(id) ~= id or id <= (seen[player] or 0) then
			return false
		end
		seen[player] = id -- Even suppressed milestones cannot be replayed after the cooldown.
		local now = clock()
		if
			self.Busy[player]
			or now - (self.Accepted[player] or -math.huge) < config.AnnouncementGap
			or now - (self.Sent[player] or -math.huge) < config.AnnouncementGap
			or #self.Pending >= config.AnnouncementCap
		then
			return false
		end
		self.Accepted[player], self.Busy[player] = now, true
		table.insert(
			self.Pending,
			{ Player = player, Item = item, Payload = payload, Expires = now + config.AnnouncementTTL }
		)
		return true
	end
	function self:Take()
		return table.remove(self.Pending, 1)
	end
	function self:Finish(entry)
		-- Removal invalidates the lifetime; a yielded worker must not resurrect it.
		if self.Busy[entry.Player] then
			self.Sent[entry.Player], self.Busy[entry.Player] = clock(), nil
		end
	end
	function self:Remove(player)
		self.AdminSeen[player] = nil
		self.RebirthSeen[player] = nil
		self.Seen[player], self.Accepted[player], self.Sent[player], self.Busy[player] = nil, nil, nil, nil
		for i = #self.Pending, 1, -1 do
			if self.Pending[i].Player == player then
				table.remove(self.Pending, i)
			end
		end
	end
	return self
end
return Rules
