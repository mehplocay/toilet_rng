local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.PresentationRules)
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
					local coins, rarest = Instance.new("NumberValue"), Instance.new("StringValue")
					coins.Name, rarest.Name = "Coins", "Rarest"
					coins.Parent, rarest.Parent = folder, folder
					local rebirth = Instance.new("IntValue")
					rebirth.Name, rebirth.Parent = "Rebirth", folder
					local primary = Instance.new("BoolValue")
					primary.Name, primary.Value, primary.Parent = "IsPrimary", true, coins
					row = { Folder = folder, Coins = coins, Rarest = rarest, Rebirth = rebirth }
					stats[player] = row
				end
				local item = byId[profile.Stats.RarestItemId]
				row.Rebirth.Value = rebirth:Level(profile)
				local coins, rarest = Rules.Integer(profile.Coins), if item then item.Rarity else "None"
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
