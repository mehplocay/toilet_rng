test("display: protected copies and duplicates reserve one physical copy per slot", function()
	local e = server()
	local player, p = e:Join(701)
	p.Inventory.Poop, p.DisplaySlots = 4, 4
	p.ProtectedInventory.Poop = 2
	for slot = 1, 4 do
		e:Fire("Display", player, "Poop", slot)
		assert(p.Displays[tostring(slot)] == "Poop", "Owned copy could not be displayed")
	end
	e:Fire("Sell", player, "Poop", 1)
	assert(p.Inventory.Poop == 4, "Sold a reserved copy")
	e.Now += 5
	e:Fire("Display", player, nil, 4)
	e:Fire("Sell", player, "Poop", 1)
	assert(p.Inventory.Poop == 3 and p.Displays["3"] == "Poop")
	e.Data:Close(player)
	local _, restored = e:Join(701)
	assert(restored.Inventory.Poop == 3 and restored.Displays["1"] == "Poop" and restored.Displays["3"] == "Poop")
end)

test("collect: ten-pad sweep stays responsive while sustained durable writes remain bounded", function()
	local e = server()
	local player, p = e:Join(707)
	local plot = e.World.Assigned[player]
	p.DisplaySlots, plot.CollectSlots = 10, {}
	for slot = 1, 10 do
		plot.CollectSlots[slot] = { Parent = plot, Position = plot.IncomePoint.Position }
		p.Income.Pending[tostring(slot)] = 6000
	end
	for slot = 1, 10 do
		e.World.CollectIncome(player, slot, true)
		assert(p.Coins == slot, "Fast pad sweep dropped a valid collection")
		e.Now += 0.5
	end
	local writes = e.Store.Writes
	for _ = 1, 120 do
		p.Income.Pending["1"] = 6000
		e.World.CollectIncome(player, 1, true)
		e.Now += 0.5
	end
	assert(e.Store.Writes - writes <= 13, "Collection spam exceeded the sustained save budget")
	assert(p.Coins <= 23)
end)

test("collect: exact pad authorization rejects forged slots, geometry, dead owners and obsolete pages", function()
	local e = server()
	local player, p = e:Join(703)
	local plot = e.World.Assigned[player]
	local padPosition, otherPosition = {}, {}
	local position = setmetatable({}, {
		__sub = function(_, target)
			return { Magnitude = if target == padPosition then (player.Distance or 3) else 100 }
		end,
	})
	player.Character.FindFirstChild = function(_, name)
		return if name == "HumanoidRootPart" then { Position = position } else nil
	end
	plot.CollectSlots =
		{ [1] = { Position = padPosition, Parent = plot }, [2] = { Position = otherPosition, Parent = plot } }
	p.Income.Pending = { ["1"] = 60000, ["2"] = 120000 }
	local writes = e.Store.Writes
	for _, slot in ipairs({ false, {}, "1", 0, -1, 1.5, 0 / 0, math.huge, 4, 101 }) do
		e:Fire("CollectIncome", player, slot)
	end
	e:Fire("CollectIncome", player, nil)
	e:Fire("CollectIncome", player, 1, 2)
	e:Fire("CollectIncome", player, 2)
	e:Fire("CollectIncome", player) -- A pad is not permission to collect the jar.
	for _, distance in ipairs({ -1, 0 / 0, math.huge, 7 }) do
		player.Distance = distance
		e.World.CollectIncome(player, 1, true)
	end
	player.Distance, player.Health = 3, 0
	e.World.CollectIncome(player, 1, true)
	player.Health = 100
	plot.CollectSlots[1].Parent = nil
	e.World.CollectIncome(player, 1, true)
	assert(p.Coins == 0 and e.Store.Writes == writes)
	plot.CollectSlots[1].Parent = plot
	local foreign = e:Join(704)
	e.World.CollectIncome(foreign, 1, true)
	assert(p.Coins == 0)
	e.World.CollectIncome(player, 1, true)
	assert(p.Coins == 10 and p.Income.Pending["2"] == 120000 and e.Store.Writes == writes + 2) -- Foreign load plus collection.
	for _ = 1, 1000 do
		e.World.CollectIncome(player, 1, true)
	end
	assert(p.Coins == 10 and e.Store.Writes == writes + 2, "Empty limb touches create save traffic")
end)

test("collect: touch/prompt race, departure and rejoin preserve the uncollected slot", function()
	local e = server()
	local player, p = e:Join(705)
	local plot = e.World.Assigned[player]
	plot.CollectSlots = { [1] = { Position = plot.IncomePoint.Position, Parent = plot } }
	p.Income.Pending = { ["1"] = 60001, ["2"] = 120002 }
	e.Store.Before = function()
		coroutine.yield("pad save held")
	end
	local collecting = e:Spawn(function()
		e.World.CollectIncome(player, 1, true)
	end)
	assert(p.Coins == 10 and p.Income.Pending["1"] == 1)
	e.Now += 1
	for _ = 1, 100 do
		e:Fire("CollectIncome", player)
		e.World.CollectIncome(player, 1, true)
	end
	assert(p.Coins == 10 and p.Income.Pending["2"] == 120002)
	local closing = e:Spawn(function()
		e.Data:Close(player)
	end)
	e.Store.Before = nil
	e:Resume(collecting)
	e:Resume(closing)
	local joined, restored = e:Join(705)
	assert(restored.Coins == 10 and restored.Income.Pending["1"] == 1 and restored.Income.Pending["2"] == 120002)
	e:Fire("CollectIncome", joined)
	assert(restored.Coins == 30 and restored.Income.Pending["2"] == 3)
	for _, result in ipairs(e.Results) do
		assert(
			not (result.Player == player and result.Payload[1] == "CollectIncome" and result.Payload[2].Success),
			"Late success after departure"
		)
	end
end)

test("display: unknown items and oversubscribed copies cannot reach the live remote", function()
	local e = server()
	local player, p = e:Join(706)
	p.Inventory.Poop = 1
	p.Inventory.Unknown = 100 -- Even a malformed in-memory profile cannot publish an unknown ID.
	e:Fire("Display", player, "Unknown", 1)
	assert(next(p.Displays) == nil)
	e:Fire("Display", player, "Poop", 1)
	e:Fire("Display", player, "Poop", 2)
	assert(p.Displays["1"] == "Poop" and p.Displays["2"] == nil)
	e:Fire("Sell", player, "Poop", 1)
	assert(p.Inventory.Poop == 1)
end)

test("collect: pad collects only its own ledger and central jar collects the remainder", function()
	local e = server()
	local player, p = e:Join(702)
	local plot = e.World.Assigned[player]
	local point = { Parent = plot, Position = plot.IncomePoint.Position }
	plot.CollectSlots = { [1] = point }
	plot.CollectPoints = { point }
	p.Income.Pending = { ["1"] = 12001, ["2"] = 24002 }
	e:Fire("CollectIncome", player, 1)
	assert(
		p.Coins == 2 and p.Income.Pending["1"] == 1 and p.Income.Pending["2"] == 24002,
		"Pad cannot collect its own income"
	)
	e.Now += 5
	e:Fire("CollectIncome", player)
	assert(p.Coins == 6 and p.Income.Pending["2"] == 3)
	e.Now += 5
	e:Fire("CollectIncome", player)
	assert(p.Coins == 6, "Repeated collection minted coins")
end)
