local CashMath = require(game.ReplicatedStorage.Shared.CashMath)
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Admin)
local Items = require(Shared.Config.Items)
local IncomeConfig = require(Shared.Config.Income)
local upgrades = require(Shared.UpgradeRules).new(require(Shared.Config.Upgrades))
local income = require(Shared.IncomeAccrual).new(IncomeConfig, Items, upgrades)
local Display = require(script.Parent.Parent.Services.DisplayService)
local Inventory = require(Shared.SafeInventory)
local Metadata = require(script.Parent.Profile)
local Mutations = {}
function Mutations.Build(data, profile, action, args, now, imported)
	local candidate = data.Sanitize(profile)
	local metadata = Metadata.Touch(candidate)
	local function grant(id, count)
		if (candidate.Inventory[id] or 0) > 9e15 - count or (candidate.Collection[id] or 0) > 9e15 - count then
			return false
		end
		candidate.Inventory[id] = (candidate.Inventory[id] or 0) + count
		candidate.Collection[id] = (candidate.Collection[id] or 0) + count
		metadata.Items[id] = (metadata.Items[id] or 0) + count
		return true
	end
	if action == "Give" or action == "ForceDrop" or action == "Display" then
		if not grant(args.ItemId, if action == "Give" then args.Count else 1) then
			return nil
		end
		if action == "Display" and not Display.Set(candidate, args.ItemId, args.Slot) then
			return nil
		end
	elseif action == "GiveAll" then
		for _, item in ipairs(Items) do
			if not grant(item.Id, 1) then
				return nil
			end
		end
	elseif action == "Remove" then
		-- An explicit admin removal may delete first/protected copies, but never display reservations.
		if Inventory.Displayable(candidate, args.ItemId) < args.Count then
			return nil
		end
		candidate.Inventory[args.ItemId] -= args.Count
	elseif action == "Collection" then
		candidate.Collection[args.ItemId] = args.Count
	elseif action == "AddCoins" then
		if not CashMath.CanCredit(candidate.Coins, args.Amount) then
			return nil
		end
		candidate.Coins += args.Amount
	elseif action == "SetCoins" then
		candidate.Coins = args.Amount
	elseif action == "Pending" then
		if args.Slot > candidate.DisplaySlots then
			return nil
		end
		local cap = income:StorageUnits(candidate, true)
		if args.Amount > cap / IncomeConfig.UnitsPerCoin then
			return nil
		end
		local units = CashMath.Product(args.Amount, IncomeConfig.UnitsPerCoin)
		local key = tostring(args.Slot)
		if
			units > cap
			or units
				> income:StorageUnits(candidate, false) - income:TotalUnits(candidate) + (candidate.Income.Pending[key] or 0)
		then
			return nil
		end
		candidate.Income.Pending[key] = units
	elseif action == "IncomeCap" then
		local remaining = income:StorageUnits(candidate, false)
		for slot = 1, math.min(candidate.DisplaySlots, IncomeConfig.MaxSlots) do
			local units = math.min(remaining, income:StorageUnits(candidate, true))
			candidate.Income.Pending[tostring(slot)] = units
			remaining -= units
		end
	elseif action == "Toilet" then
		candidate.ToiletTier = args.Level
	elseif action == "Upgrade" then
		if args.Track == "DisplaySlots" then
			candidate.DisplaySlots = math.clamp(
				candidate.DisplaySlots - candidate.Upgrades.DisplaySlots + args.Level,
				1,
				math.max(upgrades.Config.DisplayCapacity, candidate.DisplaySlots)
			)
		end
		candidate.Upgrades[args.Track] = args.Level
	elseif action == "Rebirth" then
		candidate.RebirthLevel = args.Level
	elseif action == "Flushes" then
		candidate.Stats.Flushes, candidate.RunFlushes = args.Amount, args.Amount
	elseif action == "Reset" then
		candidate = data.DefaultProfile()
		candidate.Admin = { Touched = true, Items = {}, Backup = data.Sanitize(profile, true), BackupAt = now }
	elseif action == "Import" then
		candidate = data.Sanitize(imported, true)
		-- An import is a test profile, never evidence of a natural rarest find.
		candidate.Stats.RarestItemId, candidate.Stats.RarestChance =
			profile.Stats.RarestItemId, profile.Stats.RarestChance
		candidate.Admin = metadata
		metadata.Items = table.clone(candidate.Inventory)
	else
		return nil
	end
	if action == "Reset" or action == "Import" then
		-- Commerce is account history, not editable test progression. Never rewind
		-- receipt dedupe, paid timers, saved quotes or daily VIP claim identity.
		candidate.Monetization = require(Shared.CommerceProfile).Copy(profile.Monetization)
	end
	-- A timestamp import/reset must not mint offline time during this live session.
	candidate.Income.UpdatedAt = math.max(now, profile.Income.UpdatedAt)
	return data.Sanitize(candidate)
end
return Mutations
