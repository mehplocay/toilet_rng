local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.PresentationRules)
local Config = require(Shared.Config.Presentation)
local Items = require(Shared.Config.Items)
local Rebirth = require(Shared.Config.Rebirth)
local Settings = require(Shared.PresentationSettings)
local SelfQueue = require(Shared.SelfAnnouncementQueue)
local Service = {}
function Service.Start(data, remotes, events)
	local queue = Rules.Announcements(Config, os.clock)
	local finder = SelfQueue.new(Config, os.clock)
	queue.Finder = finder
	local known = {}
	for _, item in ipairs(Items) do
		known[item.Id] = item
	end
	-- Trigger is the only ingestion path, shared with the existing world event.
	-- The Event remote remains VFX-only; it never sends another chat message.
	local function deliverSelf(entry)
		local player, profile = entry.Player, entry.Profile
		if
			not data.Stopping
			and player.Parent == Players
			and data:Get(player) == profile
			and Settings.Allows(profile.Settings, entry.Item.Rarity)
			and (not entry.Mode or Settings.ChatMode(profile.Settings) == entry.Mode)
		then
			remotes.DropAnnouncement:FireClient(player, {
				Self = true,
				ItemId = entry.Item.Id,
				Count = entry.Count,
				Admin = entry.Admin,
			})
		end
	end
	local function observe(player, item, id, admin)
		local profile = data:Get(player)
		if known[item.Id] ~= item or not profile or player.Parent ~= Players then
			return
		end
		if finder:Observe(player, id, admin) and Settings.Allows(profile.Settings, item.Rarity) then
			if item.Rarity == "Common" or item.Rarity == "Uncommon" or item.Rarity == "Rare" then
				local entry = finder:Push(player, item, profile, admin, Settings.ChatMode(profile.Settings))
				if entry then
					deliverSelf(entry)
				end
			else
				deliverSelf({ Player = player, Profile = profile, Item = item, Count = 1, Admin = admin })
			end
		end
		if queue:Push(player, item, id, { ItemId = item.Id, PlayerName = Rules.Name(player.Name), Admin = admin }) then
			queue.Pending[#queue.Pending].Profile = profile
		end
	end
	events.Observe = function(player, item, flushId)
		observe(player, item, flushId, false)
	end
	events.ChatSettingsChanged = function(player)
		finder:ClearPending(player)
	end
	local adminSequence = 0
	events.ObserveAdmin = function(player, item)
		if known[item.Id] == item and data:Get(player) and player.Parent == Players then
			adminSequence += 1
			observe(player, item, adminSequence, true)
		end
	end
	local function deliver(entry)
		local player, payload = entry.Player, entry.Payload
		local profile = data:Get(player)
		if not profile or (entry.Profile and entry.Profile ~= profile) then
			return
		end
		for _, recipient in ipairs(Players:GetPlayers()) do
			-- The finder already received its private line. Rebirth retains its audience.
			local eligible = Rules.Audience(entry.Item.Rarity) == "Server"
			if recipient == player and payload.Kind ~= "Rebirth" then
				continue
			end
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
			if
				eligible
				and recipient.Parent == Players
				and target
				and Settings.Allows(target.Settings, entry.Item.Rarity)
			then
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
		finder:Remove(player)
	end)
	local elapsed = 0
	local heartbeat
	heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
		if data.Stopping then
			heartbeat:Disconnect()
			table.clear(finder.Pending)
			return
		end
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			finder:Drain(deliverSelf)
		end
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
