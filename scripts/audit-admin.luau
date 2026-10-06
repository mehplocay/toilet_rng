local function adminFixture(options)
	local e = environment(options)
	local data = e:Load(dataPath)
	local config = e:Load("src/shared/Config/Admin")
	local runtime = { Grants = {}, Actions = {}, Logs = {}, Forced = 0 }
	function runtime:Present(player)
		return player.Parent == e.Players
	end
	function runtime:GroupOwner()
		return self.Owner
	end
	function runtime:Token()
		return "confirmation-token"
	end
	function runtime:Log(player, action, args)
		table.insert(self.Logs, { Player = player, Action = action, Args = copy(args) })
	end
	function runtime:Snapshot(_, profile)
		return { Coins = profile.Coins }
	end
	function runtime:Encode(value)
		self.Exported = value
		return "json-export"
	end
	function runtime:Decode()
		return self.Imported
	end
	function runtime:ForceDrop(_, profile)
		self.Forced += 1
		self.ForcedProfile = profile
	end
	function runtime:Execute(_, _, action)
		table.insert(self.Actions, action)
		return true, "test action"
	end
	function runtime:Remove(player)
		self.Removed = player
	end
	function runtime:Deliver(player)
		local endpoint =
			{ Remote = e:Remote(), Gui = {
				Destroy = function(self)
					self.Destroyed = true
				end,
			} }
		self.Grants[player] = endpoint
		return endpoint
	end
	function runtime:Activate() end
	local service = e:Load("src/server/Services/AdminService").new(data, function()
		e:Sync()
	end, runtime)
	e.Data, e.Admin, e.Runtime, e.Config = data, service, runtime, config
	function e:JoinAdmin(id)
		local player = self:Player(id or 1212975135)
		data:Load(player)
		service:Grant(player)
		return player, data:Get(player)
	end
	function e:Command(player, action, args, sequence)
		self.Sequence = (self.Sequence or 0) + 1
		service:Request(player, player, sequence or self.Sequence, action, args or {})
	end
	function e:Advance()
		self.Now += 8
	end
	function e:Last()
		return self.Results[#self.Results] and self.Results[#self.Results].Payload[2]
	end
	return e
end

test("admin: live allowlist only, names cannot authorize or receive modules/results", function()
	local e = adminFixture()
	for _, id in ipairs({ 0, -1, 55, 1212975134, 1212975136 }) do
		local player = e:JoinAdmin(id)
		player.Name, player.DisplayName = "mehmetcayir2", "mehmetcayir2"
		e.Admin:Grant(player)
		e:Command(player, "Give", { ItemId = "Mystery", Count = 1000 })
		assert(not e.Runtime.Grants[player] and (e.Data:Get(player).Inventory.Mystery or 0) == 0)
	end
	assert(#e.Results == 0 and #e.Runtime.Logs == 0)
	local player = e:JoinAdmin()
	player.Name = "RenamedOwner"
	e:Command(player, "Give", { ItemId = "Poop", Count = 1 })
	assert(e.Data:Get(player).Inventory.Poop == 1 and e:Last().Success)
end)

test("admin: every private request rechecks authorization and the engine sender", function()
	local e = adminFixture()
	local owner = e:JoinAdmin()
	local stranger = e:JoinAdmin(52)
	e.Admin:Request(owner, stranger, 1, "SetCoins", { Amount = 1000 })
	assert(e.Data:Get(owner).Coins == 0 and #e.Runtime.Logs == 0)
	e.Config.UserIds[owner.UserId] = nil
	e:Command(owner, "SetCoins", { Amount = 1000 })
	assert(e.Data:Get(owner).Coins == 0 and #e.Results == 0 and e.Runtime.Grants[owner].Gui.Destroyed)
end)

test("admin: argument bounds, missing/extra values, replay and mutation bucket", function()
	local e = adminFixture()
	local owner = e:JoinAdmin()
	local invalid = {
		{ Amount = 0 / 0 },
		{ Amount = math.huge },
		{ Amount = -1 },
		{ Amount = 1e12 + 1 },
		{ Amount = "1000" },
		{ Amount = 1, UserId = 52 },
		{},
	}
	for _, args in ipairs(invalid) do
		e:Advance()
		e:Command(owner, "SetCoins", args)
	end
	e:Advance()
	e.Admin:Request(owner, owner, 80, "SetCoins", { Amount = 1000 }, true)
	assert(e.Data:Get(owner).Coins == 0 and #e.Runtime.Logs == 0)
	e:Advance()
	e:Command(owner, "AddCoins", { Amount = 1000 }, 90)
	e:Advance()
	e:Command(owner, "AddCoins", { Amount = 1000 }, 90)
	assert(e.Data:Get(owner).Coins == 1000)
	e:Command(owner, "AddCoins", { Amount = 1000 }, 91)
	e:Command(owner, "AddCoins", { Amount = 1000 }, 92)
	assert(e.Data:Get(owner).Coins == 2000)
end)

test("admin: normal State has no admin metadata, backup, token or UI flags", function()
	local e = server()
	local p, profile = e:Join(799)
	profile.Admin = { Touched = true, Items = { Poop = 1 }, Backup = e.Data.DefaultProfile() }
	table.clear(e.Results)
	e:Fire("State", p)
	for _, result in ipairs(e.Results) do
		local state = result.Payload[1]
		if type(state) == "table" then
			assert(state.Admin == nil and state.Backup == nil and state.IsAdmin == nil and state.AdminTestPasses == nil)
		end
	end
	for _, object in ipairs(e.Objects) do
		assert(object.Name ~= "OwnerAdmin" and object.Name ~= "Command")
	end
end)

test("admin: mutations sanitize through the same profile schema and persist before success", function()
	local e = adminFixture()
	local owner = e:JoinAdmin()
	local actions = {
		{ "Give", { ItemId = "Poop", Count = 1000 } },
		{ "Display", { ItemId = "Poop", Slot = 1 } },
		{ "Remove", { ItemId = "Poop", Count = 1000 } },
		{ "Collection", { ItemId = "Poop", Count = 0 } },
		{ "GiveAll", {} },
		{ "SetCoins", { Amount = 1000000000000 } },
		{ "AddCoins", { Amount = 1000 } },
		{ "Pending", { Slot = 1, Amount = 100 } },
		{ "IncomeCap", {} },
		{ "Toilet", { Level = 7 } },
		{ "Upgrade", { Track = "CashBoost", Level = 10 } },
		{ "Upgrade", { Track = "DisplaySlots", Level = 7 } },
		{ "Rebirth", { Level = 15 } },
		{ "Flushes", { Amount = 1000 } },
		{ "ForceDrop", { ItemId = "Mystery" } },
	}
	for _, command in ipairs(actions) do
		e:Advance()
		local previous = e.Data:Get(owner)
		previous.Unknown = "must not survive"
		e:Command(owner, command[1], command[2])
		local p = e.Data:Get(owner)
		assert(e:Last().Success, command[1])
		assert(p ~= previous and p.Unknown == nil and p.Admin.Touched, command[1])
		local clean = e.Data.Sanitize(p)
		assert(clean.Coins == p.Coins and clean.ToiletTier == p.ToiletTier and clean.DisplaySlots == p.DisplaySlots)
		assert(e.Store.Records.Player_1212975135.Data.Admin.Touched)
	end
	assert(
		e.Runtime.Forced == 1 and e.Data:Get(owner).Stats.Flushes == 1000 and e.Data:Get(owner).Stats.RarestChance == 0
	)
end)

test("admin: full display slots, pending caps and numeric ceilings reject atomically", function()
	local e = adminFixture()
	local owner, p = e:JoinAdmin()
	p.Inventory.Poop = 1
	p.Displays["1"] = "Poop"
	e:Command(owner, "Display", { ItemId = "Poop", Slot = 1 })
	assert(not e:Last().Success and p.Inventory.Poop == 1)
	e:Advance()
	e:Command(owner, "Remove", { ItemId = "Poop", Count = 1 })
	assert(not e:Last().Success and p.Inventory.Poop == 1)
	e:Advance()
	e:Command(owner, "Pending", { Slot = 1, Amount = 1e12 })
	assert(not e:Last().Success)
	p.Inventory.Poop = 9e15
	e:Advance()
	e:Command(owner, "Give", { ItemId = "Poop", Count = 1 })
	assert(not e:Last().Success and p.Inventory.Poop == 9e15)
	p.Coins = 9e15
	e:Advance()
	e:Command(owner, "AddCoins", { Amount = 1 })
	assert(not e:Last().Success and p.Coins == 9e15)
end)

test("admin: reset requires an expiring one-use token and saves a bounded reloadable backup", function()
	local e = adminFixture()
	local owner, p = e:JoinAdmin()
	p.Coins = 77
	e:Command(owner, "Reset", { Token = "guessed" })
	assert(not e:Last().Success and e.Data:Get(owner).Coins == 77)
	e:Advance()
	e:Command(owner, "PrepareReset")
	local token = e:Last().Data.Token
	e.Now += 31
	e:Command(owner, "Reset", { Token = token })
	assert(not e:Last().Success)
	e:Advance()
	e:Command(owner, "PrepareReset")
	token = e:Last().Data.Token
	e:Advance()
	e:Command(owner, "Reset", { Token = token })
	local fresh = e.Data:Get(owner)
	assert(fresh.Coins == 0 and fresh.Admin.Backup.Coins == 77 and not fresh.Admin.Backup.Admin)
	e:Advance()
	e:Command(owner, "Reset", { Token = token })
	assert(not e:Last().Success)
	e.Data:Close(owner)
	local joined = e:JoinAdmin()
	assert(e.Data:Get(joined).Admin.Backup.Coins == 77)
end)

test("admin: import strips arbitrary keys, nested backups, spoofed rarest stats and offline timestamps", function()
	local e = adminFixture()
	local owner, p = e:JoinAdmin()
	p.Stats.RarestItemId = "Poop"
	p.Stats.RarestChance = 2
	e.Runtime.Imported = {
		Coins = 5,
		Inventory = { Poop = 3, Fake = 100 },
		Collection = { Poop = 3 },
		Displays = { ["1"] = "Fake" },
		Upgrades = { LuckBoost = 1000 },
		Stats = { RarestItemId = "Mystery" },
		Income = { UpdatedAt = 1, Pending = { ["1"] = math.huge } },
		Admin = { Backup = { Coins = 999 } },
		Arbitrary = "bad",
	}
	e:Command(owner, "Import", { Json = "fixture" })
	assert(not e:Last().Success)
	e.Runtime.Imported.Income.Pending["1"] = 1
	e:Advance()
	e:Command(owner, "Import", { Json = "fixture" })
	local fresh = e.Data:Get(owner)
	assert(e:Last().Success and fresh.Inventory.Poop == 3 and fresh.Inventory.Fake == nil and fresh.Arbitrary == nil)
	assert(fresh.Stats.RarestItemId == "Poop" and fresh.Upgrades.LuckBoost == 10 and next(fresh.Displays) == nil)
	assert(not fresh.Admin.Backup and fresh.Admin.Items.Poop == 3 and fresh.Income.UpdatedAt == e.Now)
	e:Advance()
	e:Command(owner, "Export")
	assert(e.Runtime.Exported.Admin.Touched)
end)

test("admin: held saves exclude all gameplay mutations, no second admin save queues", function()
	local e = adminFixture()
	local owner = e:JoinAdmin()
	e.Store.Before = function()
		coroutine.yield("held")
	end
	local request = e:Spawn(function()
		e:Command(owner, "SetCoins", { Amount = 999 })
	end)
	assert(e.Data:Get(owner) == nil and e.Data.Replacing[owner])
	e:Advance()
	e:Command(owner, "Give", { ItemId = "Poop", Count = 1 })
	assert((e.Data.Profiles[owner].Inventory.Poop or 0) == 0 and #e.Results == 0)
	e.Store.Before = nil
	e:Resume(request)
	assert(e.Data:Get(owner).Coins == 999 and e:Last().Success and not e.Admin.Busy[owner])
end)

test("admin: lease loss cannot acknowledge success, NoPersistence never writes", function()
	local e = adminFixture()
	local owner = e:JoinAdmin()
	e.Now += 180
	e:Command(owner, "SetCoins", { Amount = 999 })
	assert(e.Data:Get(owner) == nil and e.Store.Records.Player_1212975135.Data.Coins == 0)
	local studio = adminFixture({ Studio = true, NoStore = true })
	local p = studio:JoinAdmin()
	studio:Command(p, "Give", { ItemId = "Poop", Count = 1 })
	assert(studio.Data:Get(p).Inventory.Poop == 1 and studio.Store.Calls == 0 and studio:Last().Success)
	assert(studio:Last().Message:find("memory"))
end)

test("admin: forced presentation bypasses natural counters, rarest board and event dedupe", function()
	local e = environment()
	local item = e:Load("src/shared/Config/Items")[11]
	local events = e:Load("src/server/Services/EventService").new(e:Load("src/shared/Config/Events"), function()
		return e.Now
	end, function(payload)
		assert(payload.Admin)
		e.Broadcast = payload
	end, function()
		error("admin preview granted luck")
	end)
	local player = e:Player(1212975135)
	local profile = e:Load(dataPath).DefaultProfile()
	local natural, admin = 0, 0
	events.Observe = function()
		natural += 1
	end
	events.ObserveAdmin = function()
		admin += 1
	end
	local world = {
		Animate = function(_, _, _, _, _, preview)
			assert(preview)
		end,
	}
	e:Load("src/server/Services/FlushPresentation")
		.Publish(player, profile, item, { Admin = true, ItemId = item.Id }, world, events, { Result = e:Remote() }, 0.9)
	assert(
		natural == 0
			and admin == 1
			and events.Seen[player] == nil
			and events.Expires == 0
			and profile.Stats.Flushes == 0
			and profile.Stats.RarestChance == 0
	)
	local stats = e:Load("src/shared/LeaderboardStats").new(e:Load("src/shared/Config/Items"))
	profile.Admin = { Touched = true }
	local entries = { { Name = "Owner", UserId = player.UserId, Profile = profile } }
	assert(#stats:Rank(entries, "Coins") == 1)
	e:Load("src/shared/Config/Admin").CountAdminProfilesInRankings = false
	assert(#stats:Rank(entries, "Coins") == 0)
end)

test("admin: group cache expires, errors deny, removal cancels an in-flight authorization", function()
	local e = adminFixture()
	e.Config.AllowGroupOwner = true
	e.Runtime.Owner = 77
	local owner = e:JoinAdmin(77)
	assert(e.Runtime.Grants[owner])
	e.Runtime.Owner = 88
	e:Command(owner, "Snapshot")
	assert(e:Last().Success)
	e.Now += 61
	table.clear(e.Results)
	e:Command(owner, "SetCoins", { Amount = 10 })
	assert(e.Data:Get(owner).Coins == 0 and #e.Results == 0)
	local other = e:Player(99)
	e.Data:Load(other)
	e.Runtime.GroupOwner = function()
		coroutine.yield("group held")
		return 99
	end
	local grant = e:Spawn(function()
		e.Admin:Grant(other)
	end)
	e.Admin:Remove(other)
	other.Parent = nil
	e:Resume(grant)
	assert(not e.Runtime.Grants[other] and not e.Admin.Authorization.Cache[other])
end)

test("admin: real private delivery parents modules only to the allowed PlayerGui and removes them", function()
	local e = environment()
	local data = e:Load(dataPath)
	local clones = 0
	e.Globals.Enum.ZIndexBehavior = { Sibling = "Sibling" }
	e.Services.ServerStorage = { AdminClient = {
		Clone = function()
			clones += 1
			return {}
		end,
	} }
	local runtime = e:Load("src/server/Admin/Runtime").new(data, {}, {}, {})
	local admin = e:Load("src/server/Services/AdminService").new(data, function() end, runtime)
	local owner, stranger = e:Player(1212975135), e:Player(2323)
	local ownGui, otherGui = {}, {}
	function owner:WaitForChild(name)
		assert(name == "PlayerGui")
		return ownGui
	end
	function stranger:WaitForChild()
		error("Denied client was asked for a GUI")
	end
	data:Load(owner)
	data:Load(stranger)
	admin:Grant(stranger)
	assert(clones == 0 and not admin.Endpoints[stranger])
	admin:Grant(owner)
	admin:Grant(owner)
	assert(clones == 1 and admin.Endpoints[owner].Gui.Parent == ownGui and next(otherGui) == nil)
	local gui = admin.Endpoints[owner].Gui
	admin:Remove(owner)
	assert(gui.Destroyed and not admin.Endpoints[owner] and not admin.Limiter.Players[owner])
end)

test("admin: profile reset cannot rewind natural result/event dedupe IDs", function()
	local e = server()
	local owner, p = e:Join(911)
	e:Fire("Flush", owner)
	local first
	for _, message in ipairs(e.Results) do
		if message.Payload[1] == "Flush" then
			first = message.Payload[2].FlushId
		end
	end
	assert(first == 1)
	p.Stats.Flushes = 0
	p.RunFlushes = 0
	e.Now += 5
	table.clear(e.Results)
	e:Fire("Flush", owner)
	for _, message in ipairs(e.Results) do
		if message.Payload[1] == "Flush" then
			assert(message.Payload[2].FlushId == 2 and p.Stats.Flushes == 1)
		end
	end
end)

test("admin: movement and test unlock leases expire, restore collisions, and never change purchased passes", function()
	local e = environment()
	local data = e:Load(dataPath)
	local owner = e:Player(1212975135)
	data:Load(owner)
	local model = {}
	local humanoid =
		{ Parent = model, Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, UseJumpPower = false }
	local root = { Parent = model, CanCollide = true }
	function root:IsA(class)
		return class == "BasePart"
	end
	function model:FindFirstChild(name)
		return if name == "HumanoidRootPart" then root else nil
	end
	function model:FindFirstChildWhichIsA()
		return humanoid
	end
	function model:GetDescendants()
		return { root }
	end
	owner.Character = model
	local runtime = e:Load("src/server/Admin/Runtime").new(data, {}, {}, {})
	local mon = e:Load("src/server/Services/MonetizationService")
	mon.Owned[owner] = { VIPStar = true, FastFlush = false }
	runtime:Start({
		Remove = function(_, player)
			runtime:Remove(player)
		end,
	})
	local p = data:Get(owner)
	assert(runtime:Execute(owner, p, "Speed", { Amount = 80 }))
	assert(humanoid.WalkSpeed == 80)
	assert(runtime:Execute(owner, p, "Jump", { Amount = 120 }))
	assert(humanoid.UseJumpPower and humanoid.JumpPower == 120)
	assert(runtime:Execute(owner, p, "Noclip", { Enabled = true }))
	e.Services.RunService.Heartbeat:Fire(1 / 60)
	assert(not root.CanCollide)
	assert(runtime:Execute(owner, p, "God", { Enabled = true }))
	humanoid.Health = 50
	e.Services.RunService.Heartbeat:Fire(1 / 60)
	assert(humanoid.Health == 100)
	assert(runtime:Execute(owner, p, "TestPasses", { Enabled = true }))
	assert(mon:EffectiveOwned(owner).FastFlush and not mon.Owned[owner].FastFlush)
	assert(mon:EffectiveCosmetics(owner, {}).FoundingFlush and next(p.IndexCosmetics) == nil)
	assert(mon:Cooldown(owner, 1) == 0.8)
	-- A normal admin profile edit must not look like session revocation to Heartbeat.
	e.Store.Before = function()
		coroutine.yield("admin save held")
	end
	local replacement = data.Sanitize(p)
	local save = e:Spawn(function()
		assert(data:ReplaceAndSave(owner, p, replacement))
	end)
	assert(data.Replacing[owner] and data:Get(owner) == nil)
	e.Now += 1
	e.Services.RunService.Heartbeat:Fire(1 / 60)
	assert(runtime.Movement[owner] and humanoid.WalkSpeed == 80 and not root.CanCollide)
	assert(mon:EffectiveOwned(owner).FastFlush, "A guarded save must not revoke test passes")
	e.Store.Before = nil
	e:Resume(save)
	assert(data:Get(owner) == replacement)
	e.Now += 16
	e.Services.RunService.Heartbeat:Fire(1 / 60)
	assert(humanoid.WalkSpeed == 16 and humanoid.JumpPower == 50 and not humanoid.UseJumpPower and root.CanCollide)
	assert(not runtime.Movement[owner] and not mon:EffectiveOwned(owner).FastFlush and mon.Owned[owner].VIPStar)
	assert(not mon:EffectiveCosmetics(owner, {}).FoundingFlush and not data.Sanitize(p).Admin)
end)

test("admin: guarded saves never extend movement past the data lease", function()
	local e = environment()
	local data = e:Load(dataPath)
	local owner = e:Player(1212975135)
	data:Load(owner)
	local model = {}
	local humanoid =
		{ Parent = model, Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, UseJumpPower = false }
	function model:FindFirstChild()
		return {}
	end
	function model:FindFirstChildWhichIsA()
		return humanoid
	end
	owner.Character = model
	local runtime = e:Load("src/server/Admin/Runtime").new(data, {}, {}, {})
	runtime:Start({
		Remove = function(_, player)
			runtime:Remove(player)
		end,
	})
	local profile = data:Get(owner)
	assert(runtime:Execute(owner, profile, "Speed", { Amount = 80 }))
	e.Store.Before = function()
		coroutine.yield("save held through expiry")
	end
	local save = e:Spawn(function()
		assert(not data:ReplaceAndSave(owner, profile, data.Sanitize(profile)))
	end)
	data.LeaseExpires[owner] = e.Now
	e.Services.RunService.Heartbeat:Fire(1 / 60)
	assert(not runtime.Movement[owner] and humanoid.WalkSpeed == 16)
	e.Store.Records.Player_1212975135.Lock.Expires = e.Now
	e.Store.Before = nil
	e:Resume(save)
end)

test("admin: forced chat dedupe never suppresses the next natural flush", function()
	local e = environment()
	local config = e:Load("src/shared/Config/Presentation")
	local queue = e:Load("src/shared/PresentationRules").Announcements(config, function()
		return e.Now
	end)
	local player = e:Player(1)
	local item = { Rarity = "Secret" }
	assert(queue:Push(player, item, 500, { Admin = true, Kind = "Admin" }))
	queue:Finish(queue:Take())
	e.Now += 6
	assert(queue:Push(player, item, 1, {}))
	assert(queue.Seen[player] == 1 and queue.AdminSeen[player] == 500)
	queue:Remove(player)
	assert(not queue.AdminSeen[player] and not queue.Seen[player])
end)
