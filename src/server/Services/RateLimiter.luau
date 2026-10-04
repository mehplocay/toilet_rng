local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(limits)
	return setmetatable({ Limits = limits, Players = {} }, RateLimiter)
end

function RateLimiter:Allow(player, action)
	local limit = self.Limits[action]
	if not limit then
		return false
	end
	local now = os.clock()
	local buckets = self.Players[player] or {}
	self.Players[player] = buckets
	local bucket = buckets[action] or { Tokens = limit.Capacity, Time = now }
	buckets[action] = bucket
	bucket.Tokens = math.min(limit.Capacity, bucket.Tokens + (now - bucket.Time) * limit.Refill)
	bucket.Time = now
	if bucket.Tokens < 1 then
		return false
	end
	bucket.Tokens -= 1
	return true
end

function RateLimiter:Remove(player)
	self.Players[player] = nil
end

return RateLimiter
