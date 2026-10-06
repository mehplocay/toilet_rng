local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Monetization)
local Layout = require(Shared.Config.MapLayout)
local Profile = require(Shared.CommerceProfile)
local Paid = require(Shared.PaidBenefits)
local Rebirth = require(Shared.RebirthRules).new(require(Shared.Config.Rebirth))
local PathRules = require(Shared.PathBoostRules)
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local Lucky = require(script.Parent.LuckyService)
local Commerce = {}
Commerce.__index = Commerce
function Commerce.new(data, world, sync)
	local income = require(Shared.IncomeAccrual).new(
		require(Shared.Config.Income),
		require(Shared.Config.Items),
		require(Shared.UpgradeRules).new(require(Shared.Config.Upgrades))
	)
	local ok, archive = pcall(function()
		local suffix = if game:GetService("RunService"):IsStudio() then "Studio_v1" else "v1"
		return game:GetService("DataStoreService"):GetDataStore("ToiletRNG_Receipts_" .. suffix)
	end)
	return setmetatable({
		Data = data,
		World = world,
		Sync = sync,
		Income = income,
		Prompting = {},
		Receipts = require(script.Parent.ReceiptService).new(data, income, if ok then archive else nil, sync),
	}, Commerce)
end
function Commerce:Apply(player, owned)
	local profile = self.Data:Get(player)
	if not profile or not owned then
		return
	end
	-- Get settled the old rate before entitlements change; no retroactive multiplication.
	for _, key in ipairs(Config.PassOrder) do
		if Config.Gamepasses[key].Id <= 0 then
			profile.Monetization.Passes[key] = false
		elseif owned[key] == true then
			profile.Monetization.Passes[key] = true
		end
	end
end
function Commerce:Snapshot(profile, player)
	local quotes = {}
	for _, key in ipairs(Config.ProductOrder) do
		local pending = profile.Monetization.Quote
		quotes[key] = if pending and pending.Key == key then pending.Coins else self.Receipts:Quote(profile, key)
	end
	return {
		Quotes = quotes,
		Lucky = Lucky:Snapshot(player, profile),
		PathExpires = profile.Monetization.PathExpires,
		VIPDay = profile.Monetization.VIPDay,
		PendingProduct = profile.Monetization.Quote and profile.Monetization.Quote.Key,
		CanResume = player ~= nil and not self.Prompting[player],
	}
end
function Commerce:InPlot(player)
	local plot = self.World.Assigned[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
	if not plot or plot.Owner ~= player or not root or not humanoid or not (humanoid.Health > 0) then
		return false
	end
	local p = plot.LayoutCFrame:PointToObjectSpace(root.Position)
	return PathRules.InRectangle(
		p.X,
		p.Y,
		p.Z,
		{ X = 0, Z = 0, Y = 0, Width = Layout.PlotWidth, Depth = Layout.PlotDepth, Cos = 1, Sin = 0 },
		7
	)
end
function Commerce:Collect(player)
	if not self:InPlot(player) or self.Data.Saving[player] then
		return
	end
	local profile = self.Data:Get(player)
	if not profile or not (Paid.Owns(profile, "AutoCollect") or Rebirth:Bonus(profile).AutoCollect) then
		return
	end
	if self.Income:Collect(profile) > 0 then
		-- Ordinary autosave persists both debit and credit; no extra DataStore write every tick.
		self.Sync(player)
	end
end
function Commerce:Start(limiter, remotes)
	self.Limiter = limiter
	self.VIPPad = require(script.Parent.VIPPadService).Start(self, remotes)
	local function result(player, success, message)
		if player.Parent == Players then
			remotes.Result:FireClient(player, "BuyProduct", { Success = success, Message = message })
		end
	end
	Marketplace.ProcessReceipt = function(info)
		return self.Receipts:Process(info)
	end
	remotes.BuyProduct.OnServerEvent:Connect(function(player, key, expectedCoins, oddsToken, ...)
		if select("#", ...) ~= 0 or not limiter:Allow(player, "BuyProduct") then
			return
		end
		local product = type(key) == "string" and Config.DeveloperProducts[key]
		local profile = self.Data:Get(player)
		if not profile or not product or product.Id <= 0 then
			result(player, false, "This boost is coming soon.")
			return
		end
		if
			self.Data.NoPersistence[player]
			or not self.Receipts.Archive
			or self.Data.Saving[player]
			or self.Prompting[player]
		then
			return
		end
		if product.LuckyCharges then
			if
				type(oddsToken) ~= "string"
				or #oddsToken > 100
				or not Lucky:Allowed(player)
				or oddsToken ~= Lucky:Odds(profile).Token
				or profile.Monetization.LuckyFlushes > Config.LuckyFlushCap - product.LuckyCharges
			then
				return
			end
		elseif oddsToken ~= nil then
			return
		end
		local quote = profile.Monetization.Quote
		if quote and quote.Key ~= key then
			result(player, false, "Finish or cancel the saved offer first. If you already paid, rejoin for delivery.")
			return
		end
		local coins = if quote then quote.Coins else self.Receipts:Quote(profile, key)
		-- Client amount is only a stale-quote check; it is never a grant source.
		if expectedCoins ~= coins then
			self.Sync(player)
			result(player, false, "Income changed. Review the updated coin amount and try again.")
			return
		end
		self.Prompting[player] = product.Id
		if not quote then
			local replacement = Profile.Copy(profile)
			replacement.Monetization.Quote = { Key = key, Coins = coins }
			if not self.Data:ReplaceAndSave(player, profile, replacement) or player.Parent ~= Players then
				self.Prompting[player] = nil
				return
			end
		end
		if product.LuckyCharges then
			local current = self.Data:Get(player)
			if not current or not Lucky:Allowed(player) or oddsToken ~= Lucky:Odds(current).Token then
				self:CancelQuote(player, key)
				self.Sync(player)
				return
			end
		end
		local ok = pcall(Marketplace.PromptProductPurchase, Marketplace, player, product.Id)
		if not ok then
			self:CancelQuote(player, key)
			result(player, false, "Purchase prompt unavailable. Please try again.")
		end
		self.Sync(player)
	end)
	Marketplace.PromptProductPurchaseFinished:Connect(function(userId, id, purchased)
		local player = Players:GetPlayerByUserId(userId)
		if not player or self.Prompting[player] ~= id then
			return
		end
		self.Prompting[player] = nil
		local profile = self.Data:Get(player)
		local quote = profile and profile.Monetization.Quote
		if quote and Config.DeveloperProducts[quote.Key].Id == id and purchased == false then
			self:CancelQuote(player, quote.Key)
		end
	end)
	remotes.ClaimVIP.OnServerEvent:Connect(function(player, ...)
		if select("#", ...) ~= 0 or not limiter:Allow(player, "ClaimVIP") or self.Data.Saving[player] then
			return
		end
		local profile = self.Data:Get(player)
		local day = math.floor(os.time() / 86400)
		if not profile or not Paid.Owns(profile, "VIPPack") or profile.Monetization.VIPDay >= day then
			return
		end
		local coins = Paid.CoinGrant(self.Receipts:Rate(profile), Config.VIPChestSeconds)
		if profile.Coins > 9e15 - coins or profile.Stats.Earned > 9e15 - coins then
			return
		end
		local replacement = Profile.Copy(profile)
		replacement.Monetization.VIPDay = day
		replacement.Coins += coins
		replacement.Stats.Earned += coins
		if self.Data:ReplaceAndSave(player, profile, replacement) and self.Data:Get(player) == replacement then
			self.Sync(player)
			remotes.Result:FireClient(
				player,
				"ClaimVIP",
				{ Success = true, Coins = coins, Message = "+" .. coins .. " VIP daily Coins!" }
			)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.Prompting[player] = nil
	end)
	task.spawn(function()
		while not self.Data.Stopping do
			task.wait(Config.AutoCollectSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				self:Collect(player)
			end
		end
	end)
end
function Commerce:CancelQuote(player, key)
	self.Prompting[player] = nil
	local profile = self.Data:Get(player)
	if
		not profile
		or self.Data.Saving[player]
		or not profile.Monetization.Quote
		or profile.Monetization.Quote.Key ~= key
	then
		return
	end
	local replacement = Profile.Copy(profile)
	replacement.Monetization.Quote = nil
	if self.Data:ReplaceAndSave(player, profile, replacement) then
		self.Sync(player)
	end
end
return Commerce
