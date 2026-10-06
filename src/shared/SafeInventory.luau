local SafeInventory = {}
local Rebirth = require(if script then script.Parent.Config.Rebirth else "./Config/Rebirth")

function SafeInventory.Displayed(profile, id)
	local displayed = 0
	for _, displayId in pairs(profile.Displays or {}) do
		if displayId == id then
			displayed += 1
		end
	end
	return displayed
end

function SafeInventory.Displayable(profile, id)
	-- Display is a reservation, not a sale: protected copies remain eligible.
	return math.max(0, (profile.Inventory[id] or 0) - SafeInventory.Displayed(profile, id))
end

function SafeInventory.Sellable(profile, id)
	local displayed = SafeInventory.Displayed(profile, id)
	-- A displayed copy may also be the protected first copy; never double-reserve it.
	return math.max(
		0,
		(profile.Inventory[id] or 0) - math.max(1, displayed, (profile.ProtectedInventory or {})[id] or 0)
	)
end

function SafeInventory.Sell(profile, items, id, count, cashMultiplier)
	if
		type(id) ~= "string"
		or type(count) ~= "number"
		or count ~= count
		or count < 1
		or count > 1000000
		or count % 1 ~= 0
	then
		return false
	end
	local item
	for _, candidate in ipairs(items) do
		if candidate.Id == id then
			item = candidate
			break
		end
	end
	if not item or SafeInventory.Sellable(profile, id) < count then
		return false
	end
	local multiplier = cashMultiplier or 1
	if
		type(multiplier) ~= "number"
		or multiplier ~= multiplier
		or multiplier < 1
		or multiplier > 2 + Rebirth.CashCap
	then
		return false
	end
	-- Round per copy, so batching or splitting sales cannot change their value.
	local value = math.floor(item.Value * multiplier + 1e-9) * count
	if value > 9e15 - profile.Coins or value > 9e15 - profile.Stats.Earned then
		return false
	end
	profile.Inventory[id] -= count
	profile.Coins += value
	profile.Stats.Earned += value
	return true
end

return SafeInventory
