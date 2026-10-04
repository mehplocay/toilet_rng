local EventService = {}

function EventService.new(config, clock, broadcast, luckChanged)
	local self = { Expires = 0, NextBroadcast = 0, Seen = {}, Pending = {} }

	function self:Multiplier()
		return if clock() < self.Expires then config.LuckMultiplier else 1
	end

	function self:Drain()
		if #self.Pending > 0 and clock() >= self.NextBroadcast then
			self.NextBroadcast = clock() + config.BroadcastCooldown
			broadcast(table.remove(self.Pending, 1))
		end
	end

	function self:Trigger(player, item, flushId)
		if not item.Event or item.Chance < 100000 or flushId <= (self.Seen[player] or 0) then
			return false
		end
		self.Seen[player] = flushId
		self.Expires = math.max(self.Expires, clock() + config.Duration)
		luckChanged(self.Expires)
		-- Luck refreshes immediately; each announcement waits for the global cooldown.
		table.insert(self.Pending, { ItemId = item.Id, PlayerName = player.DisplayName })
		self:Drain()
		return true
	end

	function self:Remove(player)
		self.Seen[player] = nil
	end

	return self
end

return EventService
