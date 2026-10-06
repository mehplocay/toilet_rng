local EventService = {}
local Rules =
	require(if script then game.ReplicatedStorage.Shared.PresentationRules else "../../shared/PresentationRules")

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
		if
			type(flushId) ~= "number"
			or flushId ~= flushId
			or flushId % 1 ~= 0
			or flushId > 9e15
			or flushId <= (self.Seen[player] or 0)
		then
			return false
		end
		self.Seen[player] = flushId
		if self.Observe then
			self.Observe(player, item, flushId)
		end
		if not item.Event or item.Chance < 100000 then
			return false
		end
		self.Expires = math.max(self.Expires, clock() + config.Duration)
		luckChanged(self.Expires)
		-- Luck refreshes immediately; each announcement waits for the global cooldown.
		if #self.Pending < config.QueueCap then
			table.insert(self.Pending, { ItemId = item.Id, PlayerName = Rules.Name(player.Name) })
		end
		self:Drain()
		return true
	end

	function self:Remove(player)
		self.Seen[player] = nil
	end

	function self:Boost()
		self.Expires = math.max(self.Expires, clock() + config.Duration)
		luckChanged(self.Expires)
	end

	function self:Preview(player, item)
		-- Does not touch Seen, natural roll counters or automatic luck grants.
		if self.ObserveAdmin then
			self.ObserveAdmin(player, item)
		end
		if item.Event and #self.Pending < config.QueueCap then
			table.insert(self.Pending, { ItemId = item.Id, PlayerName = Rules.Name(player.Name), Admin = true })
			self:Drain()
		end
	end

	return self
end

return EventService
