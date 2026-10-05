local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Rules = require(game.ReplicatedStorage.Shared.MonetizationRules)
local Service = { Owned = {}, Auto = {}, Loading = {}, Pending = {}, Checking = {} }

function Service:Apply(player)
	if self.Cosmetics then
		self.Cosmetics:Apply(player, self.Owned[player] or {}, self.Data:Get(player))
	end
end

function Service:Load(player)
	if self.Loading[player] or player.Parent ~= Players then
		return false
	end
	self.Loading[player] = true
	local owned = self.Owned[player] or {}
	self.Owned[player] = owned
	local complete = true
	for _, key in ipairs(Config.PassOrder) do
		local pass = Config.Gamepasses[key]
		if pass.Id > 0 then
			local ok, result =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if player.Parent ~= Players then
				return false
			end
			Rules.MergeOwnership(owned, key, ok, result)
			complete = complete and ok
		else
			owned[key] = false
		end
	end
	self.Loading[player] = nil
	self:Apply(player)
	return complete
end
function Service:Luck(player)
	return 1 -- Paid randomness is not enabled.
end
function Service:Cooldown(player, base)
	return Rules.Cooldown(base, self.Owned[player] or {}, Config)
end

function Service:Distance(player)
	local plot = self.World.Assigned[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	return if plot
			and root
			and humanoid
			and humanoid.Health > 0
		then (root.Position - plot.CFrame.Position).Magnitude
		else nil
end

function Service:CanAuto(player)
	return Rules.AutoEnabled(self.Auto[player], self.Data:Get(player), self:Distance(player), Config)
end

function Service:StopAuto(player)
	if self.Auto[player] then
		self.Auto[player] = false
		self.Sync(player)
	end
end

function Service:Start(limiter, remotes, sync, data, world)
	self.Data, self.World, self.Sync = data, world, sync
	local function trackCharacter(player)
		player.CharacterRemoving:Connect(function()
			self:StopAuto(player)
		end)
	end
	Players.PlayerAdded:Connect(trackCharacter)
	for _, player in ipairs(Players:GetPlayers()) do
		trackCharacter(player)
	end
	self.Cosmetics = require(script.Parent.CosmeticService).new(world)
	self.Cosmetics:Start(self.Owned, function(player)
		return data:Get(player)
	end)
	local function result(player, action, success, message)
		if player.Parent == Players then
			remotes.Result:FireClient(player, action, { Success = success, Message = message })
		end
	end
	remotes.AutoFlush.OnServerEvent:Connect(function(player, enabled, ...)
		if select("#", ...) ~= 0 or type(enabled) ~= "boolean" or not limiter:Allow(player, "AutoFlush") then
			return
		end
		self.Auto[player] = Rules.AutoEnabled(enabled, data:Get(player), self:Distance(player), Config)
		sync(player)
	end)
	remotes.AnimationSkip.OnServerEvent:Connect(function(player, enabled, ...)
		if select("#", ...) ~= 0 or type(enabled) ~= "boolean" or not limiter:Allow(player, "AnimationSkip") then
			return
		end
		local profile = data:Get(player)
		if profile then
			profile.Settings.SkipAnimation = enabled
			sync(player)
		end
	end)
	remotes.PlotColor.OnServerEvent:Connect(function(player, id, ...)
		if select("#", ...) ~= 0 or type(id) ~= "string" or not limiter:Allow(player, "PlotColor") then
			return
		end
		local success = Rules.SetPlotColor(data:Get(player), self.Owned[player] or {}, id, Config)
		result(player, "PlotColor", success, if success then "Plot color saved." else "Plot color is unavailable.")
		sync(player)
	end)
	remotes.RefreshPasses.OnServerEvent:Connect(function(player, ...)
		if select("#", ...) ~= 0 or not limiter:Allow(player, "RefreshPasses") or not data:Get(player) then
			return
		end
		local complete = self:Load(player)
		result(
			player,
			"RefreshPasses",
			complete,
			if complete
				then "Pass ownership refreshed."
				else "Could not finish checking passes. Please try again shortly."
		)
		sync(player)
	end)
	remotes.BuyPass.OnServerEvent:Connect(function(player, key, ...)
		if select("#", ...) ~= 0 or not limiter:Allow(player, "BuyPass") or not data:Get(player) then
			return
		end
		local pass = Rules.Pass(Config, key)
		if not pass or pass.Id <= 0 then
			result(player, "BuyPass", false, "This pass is coming soon.")
			return
		end
		if self.Checking[player] or (self.Pending[player] and self.Pending[player].Expires > os.clock()) then
			result(player, "BuyPass", false, "A purchase is already being checked or prompted.")
			return
		end
		self.Checking[player] = true
		local complete = self:Load(player)
		self.Checking[player] = nil
		if player.Parent ~= Players or not data:Get(player) then
			return
		end
		if not complete then
			result(player, "BuyPass", false, "Pass ownership is unavailable. Please try again shortly.")
		elseif (self.Owned[player] or {})[key] then
			result(player, "BuyPass", true, "You already own this pass.")
		else
			self.Pending[player] = { Id = pass.Id, Expires = os.clock() + Config.PromptTimeout }
			local ok = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, pass.Id)
			if player.Parent == Players then
				if not ok then
					self.Pending[player] = nil
				end
				result(
					player,
					"BuyPass",
					ok,
					if ok
						then "Complete or close the Roblox purchase prompt."
						else "Purchase prompt unavailable. Please try again shortly."
				)
			end
		end
		sync(player)
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
		local key = Rules.PassKey(Config, id)
		if not key or player.Parent ~= Players then
			return
		end
		if self.Pending[player] and self.Pending[player].Id == id then
			self.Pending[player] = nil
		end
		if purchased == true then
			-- This is Roblox's server event, never a client purchase-complete remote.
			self.Owned[player] = self.Owned[player] or {}
			Rules.MergeOwnership(self.Owned[player], key, true, true)
			self:Apply(player)
		end
		result(player, "BuyPass", purchased == true, if purchased then "Pass unlocked!" else "Purchase canceled.")
		sync(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.Cosmetics:Remove(player)
		self.Owned[player] = nil
		self.Auto[player] = nil
		self.Loading[player], self.Checking[player], self.Pending[player] = nil, nil, nil
	end)
	task.spawn(function()
		while not data.Stopping do
			task.wait(Config.OwnershipRefresh)
			for _, player in ipairs(Players:GetPlayers()) do
				if data:Get(player) then
					task.spawn(function()
						self:Load(player)
						sync(player)
					end)
				end
			end
		end
	end)
end
return Service
