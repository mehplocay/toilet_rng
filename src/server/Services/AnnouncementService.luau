local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.PresentationRules)
local Config = require(Shared.Config.Presentation)
local Items = require(Shared.Config.Items)
local Rebirth = require(Shared.Config.Rebirth)
local Service = {}
function Service.Start(data, remotes, events)
	local queue = Rules.Announcements(Config, os.clock)
	local known = {}
	for _, item in ipairs(Items) do
		known[item.Id] = item
	end
	-- Trigger is the only ingestion path, shared with the existing world event.
	-- The Event remote remains VFX-only; it never sends another chat message.
	events.Observe = function(player, item, flushId)
		local profile = data:Get(player)
		if known[item.Id] == item and profile and player.Parent == Players then
			queue:Push(player, item, flushId, { ItemId = item.Id, PlayerName = Rules.Name(player.Name) })
		end
	end
	local function deliver(entry)
		local player, payload = entry.Player, entry.Payload
		local profile = data:Get(player)
		if not profile then
			return
		end
		for _, recipient in ipairs(Players:GetPlayers()) do
			local eligible = Rules.Audience(entry.Item.Rarity) == "Server"
			if not eligible and recipient ~= player then
				local ok, friend = pcall(player.IsFriendsWithAsync, player, recipient.UserId)
				eligible = ok and friend == true -- Yield/failure never widens the audience.
			end
			if
				data.Stopping
				or player.Parent ~= Players
				or data:Get(player) ~= profile
				or os.clock() >= entry.Expires
			then
				return
			end
			local target = data:Get(recipient)
			if eligible and recipient.Parent == Players and target and target.Settings.ChatAnnouncements ~= false then
				remotes.DropAnnouncement:FireClient(recipient, payload)
			end
		end
	end
	events.Rebirth = function(player, level)
		local profile = data:Get(player)
		if
			not profile
			or profile.RebirthLevel ~= level
			or not Rebirth.Levels[level]
			or level < Rebirth.FriendAnnouncementLevel
		then
			return
		end
		queue:Push(
			player,
			{ Rarity = if level >= Rebirth.ServerAnnouncementLevel then "Mythic" else "Legendary" },
			level,
			{ Kind = "Rebirth", Level = level, PlayerName = Rules.Name(player.Name) }
		)
	end
	Players.PlayerRemoving:Connect(function(player)
		queue:Remove(player)
	end)
	-- Exactly one worker, including friendship lookups: hung platform calls cannot
	-- accumulate spawned workers. Pending data and its lifetime are both bounded.
	task.spawn(function()
		while not data.Stopping do
			task.wait(0.25)
			local entry = queue:Take()
			if entry then
				if os.clock() < entry.Expires then
					local ok, err = pcall(deliver, entry)
					if not ok then
						warn("Drop announcement delivery failed", err)
					end
				end
				queue:Finish(entry)
			end
		end
	end)
	return queue
end
return Service
