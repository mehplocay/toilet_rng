-- No client identity, display name, Studio bypass or cached UI flag is trusted.
local Authorization = {}
function Authorization.new(config, clock, present, groupOwner)
	local self = { Cache = {}, Pending = {} }
	function self:Allowed(player)
		if not present(player) then
			return false
		end
		if config.UserIds[player.UserId] == true then
			return true
		end
		if not config.AllowGroupOwner then
			return false
		end
		local cached = self.Cache[player]
		if cached and cached.GroupId == config.GroupId and clock() < cached.Expires then
			return cached.Allowed
		end
		if self.Pending[player] then
			return false
		end
		local token = {}
		self.Pending[player] = token
		local groupId = config.GroupId
		local ok, ownerId = pcall(groupOwner, groupId)
		if self.Pending[player] ~= token or not present(player) then
			return false
		end
		self.Pending[player] = nil
		local allowed = ok
			and config.AllowGroupOwner
			and config.GroupId == groupId
			and type(ownerId) == "number"
			and ownerId == player.UserId
		self.Cache[player] =
			{ Allowed = allowed, GroupId = groupId, Expires = clock() + config.AuthorizationCacheSeconds }
		return allowed
	end
	function self:Remove(player)
		self.Cache[player], self.Pending[player] = nil, nil
	end
	return self
end
return Authorization
