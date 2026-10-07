local Display = {}
local TutorialProgress =
	require(if script then game.ReplicatedStorage.Shared.TutorialProgress else "../../shared/TutorialProgress")
local Inventory = require(if script then game.ReplicatedStorage.Shared.SafeInventory else "../../shared/SafeInventory")
local Items = require(if script then game.ReplicatedStorage.Shared.Config.Items else "../../shared/Config/Items")
local known = {}
for _, item in ipairs(Items) do
	known[item.Id] = true
end
function Display.Set(profile, id, slot)
	if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > profile.DisplaySlots then
		return false
	end
	local key = tostring(slot)
	if id == nil then
		profile.Displays[key] = nil
		return true
	end
	if type(id) ~= "string" or not known[id] or profile.Displays[key] then
		return false
	end
	if Inventory.Displayable(profile, id) == 0 then
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
		if success then
			TutorialProgress.Record(profile, "Display", { Success = true, ItemId = id })
		end
		remotes.Result:FireClient(player, "Display", { Success = success, ItemId = if success then id else nil })
		if success then
			sync(player)
		end
	end)
end
return Display
