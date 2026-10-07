local CashMath = require(game.ReplicatedStorage.Shared.CashMath)
-- One atomic profile write includes both benefit and PurchaseId. Only acknowledged
-- old entries may move to permanent tombstones before bounded-history eviction.
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Monetization)
local Profile = require(Shared.CommerceProfile)
local Paid = require(Shared.PaidBenefits)
local Players = game:GetService("Players")
local Lucky = require(script.Parent.LuckyService)
local Receipt = {}
function Receipt:Deferred(player)
	if self.Notify then
		pcall(
			self.Notify,
			player,
			"Paid coins are saved for delivery. Make room in your wallet, then rejoin to receive them."
		)
	end
end
Receipt.__index = Receipt
function Receipt.new(data, income, archive, sync)
	return setmetatable({ Data = data, Income = income, Archive = archive, Sync = sync, Busy = {} }, Receipt)
end
function Receipt:Rate(profile)
	local total = 0
	for _, units in pairs(self.Income:Rates(profile)) do
		total += units
	end
	return total / self.Income.Config.UnitsPerCoin
end
function Receipt:Quote(profile, key)
	local product = Config.DeveloperProducts[key]
	return if product and product.IncomeSeconds then Paid.CoinGrant(self:Rate(profile), product.IncomeSeconds) else 0
end
function Receipt:Process(info)
	local pending, granted = Enum.ProductPurchaseDecision.NotProcessedYet, Enum.ProductPurchaseDecision.PurchaseGranted
	if
		type(info) ~= "table"
		or type(info.PurchaseId) ~= "string"
		or #info.PurchaseId == 0
		or #info.PurchaseId > 50
		or type(info.PlayerId) ~= "number"
		or info.PlayerId < 1
		or info.PlayerId > 9e15
		or info.PlayerId % 1 ~= 0
	then
		return pending
	end
	local key
	for _, candidate in ipairs(Config.ProductOrder) do
		if Config.DeveloperProducts[candidate].Id > 0 and Config.DeveloperProducts[candidate].Id == info.ProductId then
			key = candidate
			break
		end
	end
	if not key then
		return pending
	end
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if
		not player
		or player.Parent ~= Players
		or self.Busy[player]
		or self.Data.NoPersistence[player]
		or not self.Archive
	then
		return pending
	end
	self.Busy[player] = true
	local ok, result = pcall(function()
		local data = self.Data
		-- Roblox may deliver rejoin receipts before PlayerAdded finishes loading data.
		local deadline = os.clock() + Config.ReceiptReadySeconds
		while
			player.Parent == Players
			and not data.Stopping
			and not data.Closing[player]
			and (not data.Profiles[player] or data.Saving[player] or data.Replacing[player] or (Config.DeveloperProducts[key].LuckyCharges and (Lucky.Loading[player] or not Lucky.Policies[player])))
			and os.clock() < deadline
		do
			task.wait(0.1)
		end
		local profile = data:Get(player)
		if not profile or data.Saving[player] or data.NoPersistence[player] or player.Parent ~= Players then
			return pending
		end
		local existing = Profile.Receipt(profile, info.PurchaseId)
		if existing then
			return if existing.ProductId == info.ProductId then granted else pending
		end
		-- UpdateAsync avoids stale GetAsync caches during cross-server receipt delivery.
		local marker = self.Archive:UpdateAsync(info.PurchaseId, function(old)
			return old
		end)
		if marker then
			return if marker.PlayerId == info.PlayerId and marker.ProductId == info.ProductId then granted else pending
		end
		if data:Get(player) ~= profile or player.Parent ~= Players or data.Saving[player] then
			return pending
		end
		local history = profile.Monetization.Receipts
		if #history >= Config.ReceiptHistoryLimit then
			local oldest = history[1]
			local archived = self.Archive:UpdateAsync(oldest.Id, function(old)
				if old and (old.PlayerId ~= player.UserId or old.ProductId ~= oldest.ProductId) then
					return nil
				end
				return { PlayerId = player.UserId, ProductId = oldest.ProductId }
			end)
			if not archived then
				return pending
			end
		end
		if data:Get(player) ~= profile or player.Parent ~= Players or data.Saving[player] then
			return pending
		end
		local replacement = Profile.Copy(profile)
		local commerce, product = replacement.Monetization, Config.DeveloperProducts[key]
		if product.IncomeSeconds then
			local quote = commerce.Quote
			local coins = if quote and quote.Key == key then quote.Coins else self:Quote(profile, key)
			if not coins or coins < Config.CoinGrantMin or not CashMath.CanGrant(profile, coins) then
				self:Deferred(player)
				return pending
			end
			replacement.Coins = CashMath.Credit(replacement.Coins, coins)
			replacement.Stats.Earned += coins
		elseif product.LuckyCharges then
			if not Lucky:Allowed(player) or commerce.LuckyFlushes > Config.LuckyFlushCap - product.LuckyCharges then
				return pending
			end
			commerce.LuckyFlushes += product.LuckyCharges
		else
			if commerce.PathExpires > 9e15 - product.Duration then
				return pending
			end
			commerce.PathExpires = math.max(os.time(), commerce.PathExpires) + product.Duration
		end
		if commerce.Quote and commerce.Quote.Key == key then
			commerce.Quote = nil
		end
		if #commerce.Receipts >= Config.ReceiptHistoryLimit then
			table.remove(commerce.Receipts, 1)
		end
		table.insert(commerce.Receipts, { Id = info.PurchaseId, ProductId = info.ProductId })
		if not data:ReplaceAndSave(player, profile, replacement) then
			return pending
		end
		if player.Parent ~= Players or data:Get(player) ~= replacement then
			return pending
		end
		-- UI failures cannot undo an acknowledged durable grant.
		pcall(self.Sync, player)
		return granted
	end)
	self.Busy[player] = nil
	if not ok then
		warn("Receipt deferred; persistent grant could not be confirmed.")
	end
	return if ok then result else pending
end
return Receipt
