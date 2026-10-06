-- Finder delivery never waits on the yielding friendship worker.
local Rules = require(if script then script.Parent.PresentationRules else "./PresentationRules")
local Queue = {}
function Queue.new(config, clock)
	local self = { Natural = {}, Admin = {}, Pending = {}, Sent = {}, AdminSent = {} }
	function self:Observe(player, id, admin)
		local seen = if admin then self.Admin else self.Natural
		if Rules.Integer(id) ~= id or id <= (seen[player] or 0) then
			return false
		end
		seen[player] = id
		return true
	end
	function self:Push(player, item, profile, admin, mode)
		local now = clock()
		local sent = if admin then self.AdminSent else self.Sent
		local entry
		for i, pending in ipairs(self.Pending) do
			if pending.Player == player and pending.Admin == admin then
				if pending.Profile == profile and pending.Mode == mode then
					entry = pending
				else
					table.remove(self.Pending, i)
				end
				break
			end
		end
		-- Rare and lower are counted in a fixed window, never silently rate-dropped.
		if not entry and now >= (sent[player] or -math.huge) + config.SelfCoalesceGap then
			sent[player] = now
			return { Player = player, Item = item, Profile = profile, Admin = admin, Count = 1 }
		end
		if entry then
			entry.Count = math.min(9e15, entry.Count + 1)
			if item.Chance > entry.Item.Chance then
				entry.Item = item
			end
		elseif #self.Pending < config.AnnouncementCap then
			table.insert(self.Pending, {
				Player = player,
				Item = item,
				Profile = profile,
				Admin = admin,
				Count = 1,
				Mode = mode,
				Ready = (sent[player] or now) + config.SelfCoalesceGap,
				Expires = now + config.AnnouncementTTL,
			})
		end
		return nil
	end
	function self:Drain(deliver)
		local now = clock()
		for i = #self.Pending, 1, -1 do
			local entry = self.Pending[i]
			if now >= entry.Ready or now >= entry.Expires then
				table.remove(self.Pending, i)
				if now < entry.Expires then
					local sent = if entry.Admin then self.AdminSent else self.Sent
					sent[entry.Player] = now
					deliver(entry)
				end
			end
		end
	end
	function self:ClearPending(player)
		for i = #self.Pending, 1, -1 do
			if self.Pending[i].Player == player then
				table.remove(self.Pending, i)
			end
		end
	end
	function self:Remove(player)
		self.Natural[player], self.Admin[player], self.Sent[player], self.AdminSent[player] = nil, nil, nil, nil
		self:ClearPending(player)
	end
	return self
end
return Queue
