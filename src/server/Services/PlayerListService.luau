local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local CashMath = require(Shared.CashMath)
local Items = require(Shared.Config.Items)
local Config = require(Shared.Config.Presentation)
local rebirth = require(Shared.RebirthRules).new(require(Shared.Config.Rebirth))
local Service = {}
function Service.Start(data)
	local stats, byId = {}, {}
	for _, item in ipairs(Items) do
		byId[item.Id] = item
	end
	local function refresh()
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = data:Get(player)
			local row = stats[player]
			if profile then
				if not row then
					local folder = Instance.new("Folder")
					folder.Name = "leaderstats"
					-- NumberValue is a double: huge wallets intentionally use approximate units above 2^53.
					local coins, rebirths, rarest =
						Instance.new("NumberValue"), Instance.new("IntValue"), Instance.new("StringValue")
					coins.Name, rebirths.Name, rarest.Name = "Coins", "Rebirths", "Rarest"
					coins.Parent, rebirths.Parent, rarest.Parent = folder, folder, folder
					for priority, stat in ipairs({ coins, rebirths, rarest }) do
						local order = Instance.new("NumberValue")
						order.Name, order.Value, order.Parent = "Priority", 4 - priority, stat
					end
					local primary = Instance.new("BoolValue")
					primary.Name, primary.Value, primary.Parent = "IsPrimary", true, coins
					row = { Folder = folder, Coins = coins, Rarest = rarest, Rebirths = rebirths }
					stats[player] = row
				end
				local item = byId[profile.Stats.RarestItemId]
				local level = rebirth:Level(profile)
				if row.Rebirths.Value ~= level then
					row.Rebirths.Value = level
				end
				local coins, rarest = CashMath.Sanitize(profile.Coins), if item then item.Rarity else "None"
				if row.Coins.Value ~= coins then
					row.Coins.Value = coins
				end
				if row.Rarest.Value ~= rarest then
					row.Rarest.Value = rarest
				end
				row.Folder.Parent = player
			elseif row then
				row.Folder:Destroy()
				stats[player] = nil
			end
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		if stats[player] then
			stats[player].Folder:Destroy()
			stats[player] = nil
		end
	end)
	task.spawn(function()
		while not data.Stopping do
			refresh()
			task.wait(Config.PlayerListInterval)
		end
	end)
	return { Refresh = refresh }
end
return Service
