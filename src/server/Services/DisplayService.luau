local Display = {}
function Display.Set(profile, id, slot)
	if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > profile.DisplaySlots then
		return false
	end
	local key = tostring(slot)
	if id == nil then
		profile.Displays[key] = nil
		return true
	end
	if type(id) ~= "string" or profile.Displays[key] then
		return false
	end
	local reserved = 0
	for _, value in pairs(profile.Displays) do
		if value == id then
			reserved += 1
		end
	end
	if (profile.Inventory[id] or 0) <= reserved then
		return false
	end
	profile.Displays[key] = id
	return true
end
function Display.Start(data, limiter, remotes, sync)
	remotes.Display.OnServerEvent:Connect(function(player, id, slot, ...)
		if not limiter:Allow(player, "Display") or select("#", ...) ~= 0 then
			return
		end
		local profile = data:Get(player)
		if not profile then
			return
		end
		local success = Display.Set(profile, id, slot)
		remotes.Result:FireClient(player, "Display", { Success = success })
		if success then
			sync(player)
		end
	end)
end
return Display
