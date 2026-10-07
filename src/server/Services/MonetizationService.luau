local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Rules = require(game.ReplicatedStorage.Shared.MonetizationRules)
local AutoConfig = require(game.ReplicatedStorage.Shared.Config.AutoFlush)
local Service = { Owned = {}, Auto = {}, Loading = {}, Pending = {}, Checking = {} }
Service.Activity = {}

function Service:Living(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	return player.Parent == Players
		and root ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and humanoid.Health < math.huge
end

function Service:AutoStatus(player)
	local activity = self.Activity[player]
	local now = os.clock()
	local collectEnabled = self.Commerce ~= nil and self.Commerce:CanCollect(player)
	return {
		CollectEnabled = collectEnabled,
		CollectRunning = collectEnabled
			and activity ~= nil
			and not activity.Paused
			and now - activity.Last < AutoConfig.IdleSeconds
			and not self.Data.Saving[player],
		Paused = activity ~= nil and activity.Paused == true,
		IdleRemaining = if activity then math.max(0, AutoConfig.IdleSeconds - (now - activity.Last)) else 0,
		Uptime = if activity then activity.Uptime + (if activity.Since then now - activity.Since else 0) else 0,
	}
end

function Service:IdlePaused(player)
	local activity = self.Activity[player]
	if not activity then
		return true
	end -- Missing activity state fails closed.
	if not activity.Paused and os.clock() - activity.Last >= AutoConfig.IdleSeconds then
		activity.Uptime += math.max(0, activity.Last + AutoConfig.IdleSeconds - (activity.Since or os.clock()))
		activity.Since, activity.Paused = nil, true
		self.World:StopAnimation(player)
		self.Sync(player)
	end
	return activity.Paused
end

function Service:EffectiveOwned(player)
	local owned = Rules.Entitlements(self.Owned[player], Config)
	return if self.AdminTestOwnership then self.AdminTestOwnership(player, owned) else owned
end
function Service:EffectiveCosmetics(player, original)
	return if self.AdminTestCosmetics then self.AdminTestCosmetics(player, original) else original
end

function Service:Apply(player)
	if self.Commerce then
		self.Commerce:Apply(player, self.Owned[player])
	end
	if self.Cosmetics then
		self.Cosmetics:Apply(player, self:EffectiveOwned(player), self.Data:Get(player))
	end
end

function Service:Load(player)
	if self.Loading[player] or player.Parent ~= Players then
		return false
	end
	self.Loading[player] = true
	if self.Lucky then
		self.Lucky:Refresh(player)
	end
	if player.Parent ~= Players then
		self.Loading[player] = nil
		return false
	end
	local profile = self.Data:Get(player)
	local owned = self.Owned[player] or (profile and table.clone(profile.Monetization.Passes)) or {}
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
	return 1 -- Passes never grant luck; LuckyService handles explicitly reviewed single-use charges.
end
function Service:Cooldown(player, base)
	return Rules.Cooldown(base, self:EffectiveOwned(player), Config)
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
	local plot = self.World.Assigned[player]
	local profile = self.Data:Get(player)
	-- A guarded save pauses awards through Get; it does not revoke an enabled mode.
	-- Inspect only unlock eligibility here, never mutate the hidden replacement.
	if
		not profile
		and self.Data.Replacing[player]
		and not self.Data.Stopping
		and not self.Data.Closing[player]
		and (self.Data.NoPersistence[player] or os.time() < (self.Data.LeaseExpires[player] or 0))
	then
		profile = self.Data.Profiles[player]
	end
	return plot ~= nil
		and plot.Owner == player
		and Rules.AutoEnabled(self.Auto[player], profile, self:Living(player), Config)
end

function Service:StopAuto(player)
	if self.Auto[player] then
		self.World:StopAnimation(player)
		self.Auto[player] = false
		local activity = self.Activity[player]
		if activity and activity.Since then
			activity.Uptime += math.max(0, os.clock() - activity.Since)
			activity.Since = nil
		end
		self.Sync(player)
	end
end

function Service:Start(limiter, remotes, sync, data, world)
	self.Data, self.World, self.Sync = data, world, sync
	self.Commerce = require(script.Parent.CommerceService).new(data, world, sync, self)
	self.Commerce:Start(limiter, remotes)
	local function trackCharacter(player)
		-- One idle clock for both automations; toggles, rebirth and respawn never renew it.
		self.Activity[player] = { Last = os.clock(), Uptime = 0, Paused = false }
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
		local wasEnabled = self.Auto[player]
		self.Auto[player] = Rules.AutoEnabled(enabled, data:Get(player), self:Living(player), Config)
		if self.Auto[player] and not wasEnabled then
			local activity = self.Activity[player]
			if activity then
				if not self.Commerce:HasAutoCollect(data:Get(player)) then
					activity.Last, activity.Paused = os.clock(), false
				end
				activity.Since = if activity.Paused then nil else os.clock()
			end
		elseif not self.Auto[player] then
			-- StopAuto accounts uptime while preserving the shared idle clock.
			self.Auto[player] = wasEnabled
			self:StopAuto(player)
		end
		sync(player)
	end)
	remotes.PlayerActivity.OnServerEvent:Connect(function(player, ...)
		if select("#", ...) ~= 0 or not limiter:Allow(player, "PlayerActivity") then
			return
		end
		local plot = world.Assigned[player]
		if not plot or plot.Owner ~= player or not self:Living(player) or not data:Get(player) then
			return
		end
		local activity = self.Activity[player]
		if not activity then
			return
		end
		self:IdlePaused(player)
		activity.Last = os.clock() -- Never accept a client clock, duration or reward.
		if activity.Paused then
			activity.Paused = false
			activity.Since = if self.Auto[player] then os.clock() else nil
		end
		if self.Auto[player] or self.Commerce:CanCollect(player) then
			sync(player)
		end
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
		local success = Rules.SetPlotColor(data:Get(player), self:EffectiveOwned(player), id, Config)
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
		elseif self:EffectiveOwned(player)[key] then
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
		local pending = self.Pending[player] and self.Pending[player].Id == id
		if pending then
			self.Pending[player] = nil
		end
		-- Roblox can repeat completion for an already-owned pass. Entitlements
		-- are idempotent; replays must not repeatedly sync the world or toast.
		if (self.Owned[player] or {})[key] == true or (purchased ~= true and not pending) then
			return
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
		self.World:StopAnimation(player)
		self.Cosmetics:Remove(player)
		self.Owned[player] = nil
		self.Auto[player] = nil
		self.Activity[player] = nil
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
