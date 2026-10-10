test("leave: sender validation, empty payload, per-player rate limit and normal close", function()
	local e = server()
	local player, profile = e:Join(6601)
	local other = e:Join(6602)
	profile.Coins = 12345
	e:Fire("LeaveRequest", player, other)
	assert(not player.Kicked and not other.Kicked, "Payload selected a kick target")
	e:Fire("LeaveRequest", player)
	assert(not player.Kicked, "Invalid payload bypassed rate budget")
	e.Now += 5
	local calls = 0
	player.Kick = function(self, reason)
		calls += 1
		self.Kicked = reason
	end
	e:Fire("LeaveRequest", player)
	assert(calls == 1 and player.Kicked == "See you soon! Your displays keep earning.")
	e:Fire("LeaveRequest", player)
	assert(calls == 1 and not other.Kicked, "Repeated request bypassed rate limit")
	e:Fire("LeaveRequest", other)
	assert(other.Kicked, "Rate budget leaked between players")
	local outsider = e:Player(6603)
	outsider.Parent = nil
	e:Fire("LeaveRequest", outsider)
	assert(not outsider.Kicked, "Disconnected caller accepted")
	local impostor = {
		UserId = player.UserId,
		Parent = e.Players,
		Kick = function()
			error("Impostor accepted")
		end,
	}
	e:Fire("LeaveRequest", impostor)
	-- The mock Kick records the call; emulate the engine's departure event.
	e.Players.PlayerRemoving:Fire(player)
	assert(e.Data:Get(player) == nil and e.Store.Records.Player_6601.Data.Coins == 12345)
	assert(e.Store.Records.Player_6601.Lock == nil, "Departure did not release the session")
end)
