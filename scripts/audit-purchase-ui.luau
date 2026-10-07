local function purchaseState(e)
	for i = #e.Results, 1, -1 do
		local payload = e.Results[i].Payload
		if payload[1].Commerce then
			return payload[1]
		end
	end
	error("Missing state sync")
end
local function purchaseResult(e)
	for i = #e.Results, 1, -1 do
		local payload = e.Results[i].Payload
		if payload[1] == "BuyProduct" then
			return payload[2]
		end
	end
	error("Missing purchase result")
end

test("purchase policy: valid cache survives yielded lookup; expiry and lookup failures hide Lucky", function()
	local e = server()
	local player, p = e:Join(4100)
	local lucky = e:Load("src/server/Services/LuckyService")
	for _, mode in ipairs({ "allowed", "restricted", "missing", "failed" }) do
		e.PolicyError, e.PolicyLookup = nil, nil
		lucky:Refresh(player)
		e.PolicyLookup = function()
			coroutine.yield("policy held")
			if mode == "failed" then
				error("policy failed")
			end
			return if mode == "missing" then {} else { ArePaidRandomItemsRestricted = mode == "restricted" }
		end
		local lookup = e:Spawn(function()
			lucky:Refresh(player)
		end)
		e:Fire("State", player)
		assert(purchaseState(e).Commerce.Lucky.Allowed, "In-flight lookup erased valid eligibility")
		e.Now += 121
		assert(not lucky:Snapshot(player, p).Allowed, "Expired cache stayed eligible during lookup")
		e:Resume(lookup)
		e:Fire("State", player)
		assert(purchaseState(e).Commerce.Lucky.Allowed == (mode == "allowed"))
		assert(e.Data:Save(player, false))
	end
end)

test("purchase policy: periodic refresh renews and syncs before expiry without refreshing passes", function()
	local e = environment()
	local lucky = e:Load("src/server/Services/LuckyService")
	local player = e:Player(4101)
	e.Players.List = { player }
	local data = { Stopping = false }
	lucky:Start(data, {}, { LuckyFlush = e:Remote() }, function()
		e:Sync()
	end, {}, {})
	lucky:StartRefresh(data)
	lucky:Refresh(player)
	e.Syncs = 0
	local first = lucky.Policies[player].Expires
	local loop = e.Threads[#e.Threads]
	e.Now += 60
	e:Resume(loop)
	assert(lucky.Policies[player].Expires > first and lucky:Allowed(player) and e.Syncs == 1)
	e.PolicyError = true
	e.Now += 60
	e:Resume(loop)
	assert(not lucky:Allowed(player) and e.Syncs == 2)
end)

for _, mode in ipairs({
	"profile",
	"persistence",
	"archive",
	"saving",
	"prompting",
	"save",
	"policy-after-save",
	"policy",
	"capacity",
	"token",
	"extra-token",
	"stale",
	"saved-offer",
	"prompt-error",
	"rate",
	"product",
}) do
	test("purchase refusal responds without prompting or granting: " .. mode, function()
		local e = server()
		local player, p = e:Join(4110)
		local service = e:Load("src/server/Services/MonetizationService")
		local commerce = service.Commerce
		local lucky = e:Load("src/server/Services/LuckyService")
		local key, coins, token = "LuckyFlush1", 0, lucky:Odds(p).Token
		if mode == "profile" then
			e.Data.Replacing[player] = true
		elseif mode == "persistence" then
			e.Data.NoPersistence[player] = true
		elseif mode == "archive" then
			commerce.Receipts.Archive = nil
		elseif mode == "saving" then
			e.Data.Saving[player] = true
		elseif mode == "prompting" then
			commerce.Prompting[player] = 1
		elseif mode == "save" then
			e.Data.ReplaceAndSave = function()
				return false
			end
		elseif mode == "policy-after-save" then
			local save = e.Data.ReplaceAndSave
			e.Data.ReplaceAndSave = function(self, ...)
				local ok = save(self, ...)
				lucky.Policies[player].Allowed = false
				return ok
			end
		elseif mode == "policy" then
			lucky.Policies[player].Allowed = false
		elseif mode == "capacity" then
			p.Monetization.LuckyFlushes = 1000
		elseif mode == "token" then
			token = "stale"
		elseif mode == "extra-token" then
			key = "Coins10Minutes"
		elseif mode == "stale" then
			key, coins, token = "Coins10Minutes", -1, nil
		elseif mode == "saved-offer" then
			p.Monetization.Quote = { Key = "LuckyFlush5", Coins = 0 }
		elseif mode == "prompt-error" then
			e.Marketplace.PromptProductPurchase = function()
				error("prompt failed")
			end
		elseif mode == "rate" then
			commerce.Limiter.Allow = function()
				return false
			end
		elseif mode == "product" then
			key = "unknown"
		end
		local count = p.Monetization.LuckyFlushes
		e.Results = {}
		e:Fire("BuyProduct", player, key, coins, token)
		local result = purchaseResult(e)
		assert(result.Success == false and type(result.Message) == "string" and #result.Message > 10)
		assert(not e.Marketplace.LastProduct and e.Data.Profiles[player].Coins == 0)
		assert(e.Data.Profiles[player].Monetization.LuckyFlushes == count)
	end)
end

test("purchase sync: every pack publishes charges, balances, quotes and prompt state without Refresh", function()
	local e = server()
	local player, p = e:Join(4120)
	local service = e:Load("src/server/Services/MonetizationService")
	local config = e:Load("src/shared/Config/Monetization")
	local lucky = e:Load("src/server/Services/LuckyService")
	for _, key in ipairs(config.ProductOrder) do
		local product = config.DeveloperProducts[key]
		if product.Id > 0 then
			e.Now += 10
			local coins = service.Commerce.Receipts:Quote(p, key)
			e:Fire("BuyProduct", player, key, coins, if product.LuckyCharges then lucky:Odds(p).Token else nil)
			assert(purchaseResult(e).Success and not purchaseState(e).Commerce.CanResume)
			e.Marketplace.PromptProductPurchaseFinished:Fire(player.UserId, product.Id, true)
			assert(purchaseState(e).Commerce.CanResume, "Prompt close did not sync")
			assert(e.Marketplace.ProcessReceipt(receipt(player, "ui-sync-" .. key, product.Id)) == "PurchaseGranted")
			p = e.Data:Get(player)
			local state = purchaseState(e)
			assert(state.Commerce.Lucky.Allowed and not state.Commerce.PendingProduct)
			assert(state.Coins == p.Coins and state.Commerce.PathExpires == p.Monetization.PathExpires)
			assert(state.Commerce.Lucky.Count == p.Monetization.LuckyFlushes and state.Commerce.Lucky.Odds)
			assert(state.Commerce.Quotes.Coins10Minutes == service.Commerce.Receipts:Quote(p, "Coins10Minutes"))
		end
	end
	e:Fire("LuckyFlush", player, lucky:Odds(p).Token)
	assert(purchaseState(e).Commerce.Lucky.Armed)
	e:Fire("Flush", player)
	local state = purchaseState(e)
	assert(state.Commerce.Lucky.Allowed and not state.Commerce.Lucky.Armed)
	assert(state.Commerce.Lucky.Count == e.Data:Get(player).Monetization.LuckyFlushes)
end)

test("creator passes: verified ownership stays true throughout yielded refresh", function()
	local e = server()
	e.Marketplace.Lookup = function()
		return true
	end
	local player = e:Join(4130)
	local service = e:Load("src/server/Services/MonetizationService")
	service.Cosmetics = nil
	e.Marketplace.Lookup = function()
		coroutine.yield("ownership held")
		return false
	end
	local refresh = e:Spawn(function()
		e:Fire("RefreshPasses", player)
	end)
	while coroutine.status(refresh) ~= "dead" do
		e.Now += 1
		e:Fire("State", player)
		for _, key in ipairs(e:Load("src/shared/Config/Monetization").PassOrder) do
			assert(purchaseState(e).OwnedPasses[key], "Refresh flickered ownership: " .. key)
		end
		e:Resume(refresh)
	end
end)
