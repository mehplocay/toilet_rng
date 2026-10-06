local Config = require(if script then script.Parent.Config.Monetization else "./Config/Monetization")
local Profile = {}
local function integer(value, max)
	return type(value) == "number" and value == value and value >= 0 and value <= max and value % 1 == 0
end
function Profile.Copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = Profile.Copy(child)
	end
	return result
end
function Profile.Sanitize(raw)
	local result =
		{ Passes = {}, Receipts = {}, AppliedSlots = 0, PathExpires = 0, VIPDay = 0, VIPPadAt = 0, LuckyFlushes = 0 }
	if type(raw) ~= "table" then
		return result
	end
	for _, key in ipairs(Config.PassOrder) do
		result.Passes[key] = Config.Gamepasses[key].Id > 0 and type(raw.Passes) == "table" and raw.Passes[key] == true
	end
	result.AppliedSlots = if integer(
			raw.AppliedSlots,
			Config.Gamepasses.ExtraSlots.Slots + Config.Gamepasses.VIPPack.Slots
		)
		then raw.AppliedSlots
		else 0
	result.LuckyFlushes = if integer(raw.LuckyFlushes, Config.LuckyFlushCap) then raw.LuckyFlushes else 0
	result.VIPPadAt = if integer(raw.VIPPadAt, 9e15) then raw.VIPPadAt else 0
	result.PathExpires = if integer(raw.PathExpires, 9e15) then raw.PathExpires else 0
	result.VIPDay = if integer(raw.VIPDay, 9e15) then raw.VIPDay else 0
	local seen = {}
	for _, receipt in ipairs(if type(raw.Receipts) == "table" then raw.Receipts else {}) do
		if #result.Receipts >= Config.ReceiptHistoryLimit then
			break
		end
		if
			type(receipt) == "table"
			and type(receipt.Id) == "string"
			and #receipt.Id > 0
			and #receipt.Id <= 50
			and integer(receipt.ProductId, 9e15)
			and not seen[receipt.Id]
		then
			seen[receipt.Id] = true
			table.insert(result.Receipts, { Id = receipt.Id, ProductId = receipt.ProductId })
		end
	end
	local quote = raw.Quote
	if
		type(quote) == "table"
		and type(quote.Key) == "string"
		and Config.DeveloperProducts[quote.Key]
		and integer(quote.Coins, Config.CoinGrantMax)
	then
		result.Quote = { Key = quote.Key, Coins = quote.Coins }
	end
	return result
end
function Profile.Receipt(profile, id)
	for _, entry in ipairs(profile.Monetization.Receipts) do
		if entry.Id == id then
			return entry
		end
	end
	return nil
end
return Profile
