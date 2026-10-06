local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Admin)
local Items = require(Shared.Config.Items)
local Passes = require(Shared.Config.Monetization)
local Presentation = require(script.Parent.Parent.Services.FlushPresentation)
local Runtime = {}
function Runtime.new(data, world, events, remotes)
	local self = { Movement = {}, Links = {}, HeartbeatSeconds = 0 }
	local monetization = require(script.Parent.Parent.Services.MonetizationService)
	local testUnlocks = require(script.Parent.TestUnlocks).new(Config, Passes, os.clock)
	monetization.AdminTestOwnership = function(player, real)
		return testUnlocks:Owned(player, real)
	end
	monetization.AdminTestCosmetics = function(player, real)
		return testUnlocks:Cosmetics(player, real, require(Shared.Config.IndexRewards))
	end
	local known = {}
	for _, item in ipairs(Items) do
		known[item.Id] = item
	end
	function self:Present(player)
		return player.Parent == Players
	end
	function self:GroupOwner(id)
		-- Current GroupService avoids deprecated single-role rank selection with multi-role groups.
		local info = game:GetService("GroupService"):GetGroupInfoAsync(id)
		return if type(info.Owner) == "table" then info.Owner.Id else nil
	end
	function self:Token()
		return Http:GenerateGUID(false)
	end
	function self:Encode(value)
		return Http:JSONEncode(value)
	end
	function self:Decode(value)
		return Http:JSONDecode(value)
	end
	function self:Log(player, action, args)
		local logged = if action == "Import" then { JsonBytes = #args.Json } else args
		print(string.format("[ADMIN] %s (%d) %s %s", player.Name, player.UserId, action, self:Encode(logged)))
	end
	function self:Deliver(player)
		local playerGui = player:WaitForChild("PlayerGui", 10)
		if not playerGui then
			return nil
		end
		local gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "OwnerAdmin", false, 60
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local remote = Instance.new("RemoteEvent")
		remote.Name, remote.Parent = "Command", gui
		game:GetService("ServerStorage").AdminClient:Clone().Parent = gui
		return { Gui = gui, Remote = remote, PlayerGui = playerGui }
	end
	function self:Activate(player, endpoint)
		if self:Present(player) then
			endpoint.Gui.Parent = endpoint.PlayerGui
		end
	end
	function self:Snapshot(player, profile)
		local income = require(Shared.IncomeAccrual).new(
			require(Shared.Config.Income),
			Items,
			require(Shared.UpgradeRules).new(require(Shared.Config.Upgrades))
		)
		return {
			Coins = profile.Coins,
			ToiletTier = profile.ToiletTier,
			RebirthLevel = profile.RebirthLevel,
			Flushes = profile.Stats.Flushes,
			PendingCoins = income:PendingCoins(profile),
			NoPersistence = data.NoPersistence[player] == true,
			HasBackup = profile.Admin and profile.Admin.Backup ~= nil,
			Upgrades = profile.Upgrades,
			Inventory = profile.Inventory,
			Collection = profile.Collection,
			DisplaySlots = profile.DisplaySlots,
		}
	end
	function self:ForceDrop(player, profile, id)
		local item = known[id]
		Presentation.Publish(player, profile, item, {
			ItemId = id,
			Rarity = item.Rarity,
			Chance = item.Chance,
			Admin = true,
			Cooldown = 1.5,
			ServiceCoins = 0,
			LuckMultiplier = 1,
			LuckCapped = false,
		}, world, events, remotes, 0.9)
	end
	local function character(player)
		local model = player.Character
		local humanoid = model and model:FindFirstChildWhichIsA("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health <= 0 then
			return nil
		end
		return model, humanoid, root
	end
	function self:ResetMovement(player)
		local state = self.Movement[player]
		if not state then
			return
		end
		self.Movement[player] = nil
		if state.Humanoid.Parent then
			state.Humanoid.WalkSpeed, state.Humanoid.JumpPower, state.Humanoid.UseJumpPower =
				state.Speed, state.Jump, state.UseJumpPower
			state.Humanoid.MaxHealth = state.MaxHealth
			state.Humanoid.Health = math.min(state.Humanoid.Health, state.MaxHealth)
		end
		if state.ForceField then
			state.ForceField:Destroy()
		end
		for part, collision in pairs(state.Collisions) do
			if part.Parent then
				part.CanCollide = collision
			end
		end
	end
	function self:Execute(player, profile, action, args)
		if action == "TestPasses" then
			testUnlocks:Set(player, args.Enabled)
			if not args.Enabled then
				self:ClearTestCosmetics(player)
			end
			monetization:Apply(player)
			return true,
				"Session test passes applied. Marketplace ownership is unchanged.",
				{ Preview = action, Args = args }
		elseif action == "ClearCooldown" then
			world.ClearFlushCooldown(player)
		elseif action == "Luck" then
			events:Boost()
		elseif action == "Announcement" then
			events:Preview(player, known[args.ItemId])
		elseif action == "Stats" then
			local parts, instances = 0, 0
			for _, object in ipairs(workspace:GetDescendants()) do
				instances += 1
				if object:IsA("BasePart") then
					parts += 1
				end
			end
			return true,
				"Workspace counts; memory covers the whole server. Heartbeat is an interval, not CPU time.",
				{
					Instances = instances,
					Parts = parts,
					Players = #Players:GetPlayers(),
					MemoryMB = game:GetService("Stats"):GetTotalMemoryUsageMb(),
					HeartbeatMs = self.HeartbeatSeconds * 1000,
				}
		elseif action == "ReloadLabels" then
			world:RefreshLeaderboards()
			for _, plot in ipairs(world.Plots) do
				if plot.Owner and plot.Profile then
					world:Refresh(plot.Owner, plot.Profile)
					world:RenderDisplays(plot)
				end
			end
			return true, "Server labels refreshed; local label registry rescanned.", { ReloadLabels = true }
		elseif action == "Dummy" then
			local plot = world.Assigned[player]
			if not plot then
				return false, "Home plot unavailable."
			end
			local model = require(script.Parent.Parent.World.Models).Item(
				workspace,
				plot.CFrame * CFrame.new(0, 7, 0),
				known[args.ItemId]
			)
			model.Name = "AdminDummyReward"
			game:GetService("Debris"):AddItem(model, 8)
			return true, "Visual dummy only; no inventory, income or board award."
		elseif action == "Lighting" or action == "Time" or action == "RestoreLighting" or action == "Debug" then
			-- Preview instructions travel only on the authorized private channel.
			return true,
				"Local admin preview applied; purchases and real entitlements are unchanged.",
				{ Preview = action, Args = args }
		elseif action == "Teleport" then
			local model, _, root = character(player)
			if not model then
				return false, "Spawn a living character first."
			end
			local destination
			if args.Destination == "Hub" and args.Target == 0 then
				destination = CFrame.new(require(Shared.Config.MapLayout).HubArrival)
			elseif args.Destination == "Home" and args.Target == 0 then
				local plot = world.Assigned[player]
				destination = plot and plot.SpawnCFrame
			elseif args.Destination == "Plot" then
				local plot = world.Plots[args.Target]
				destination = plot and plot.SpawnCFrame
			elseif args.Destination == "Player" then
				local target = Players:GetPlayerByUserId(args.Target)
				local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					destination = targetRoot.CFrame * CFrame.new(4, 0, 0)
				end
			end
			if not destination then
				return false, "Destination unavailable. Player targets use UserIds."
			end
			local p = destination.Position
			if
				p.X ~= p.X
				or p.Y ~= p.Y
				or p.Z ~= p.Z
				or math.max(math.abs(p.X), math.abs(p.Y), math.abs(p.Z)) > 100000
			then
				return false, "Invalid destination."
			end
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			model:PivotTo(destination)
		else
			if action == "RenewMovement" then
				testUnlocks:Renew(player)
			end
			local model, humanoid = character(player)
			if not model then
				return false, "Spawn a living character first."
			end
			local state = self.Movement[player]
			if state and state.Humanoid ~= humanoid then
				self:ResetMovement(player)
				state = nil
			end
			if not state then
				state = {
					Humanoid = humanoid,
					Speed = humanoid.WalkSpeed,
					Jump = humanoid.JumpPower,
					UseJumpPower = humanoid.UseJumpPower,
					MaxHealth = humanoid.MaxHealth,
					Collisions = {},
					Fly = false,
					Noclip = false,
					God = false,
				}
				self.Movement[player] = state
			end
			state.Expires = os.clock() + Config.MovementLeaseSeconds
			if action == "Speed" then
				humanoid.WalkSpeed = args.Amount
			elseif action == "Jump" then
				humanoid.UseJumpPower, humanoid.JumpPower = true, args.Amount
			elseif action == "God" then
				state.God = args.Enabled
				if args.Enabled and not state.ForceField then
					state.ForceField = Instance.new("ForceField")
					state.ForceField.Name = "AdminGodMode"
					state.ForceField.Parent = model
				elseif not args.Enabled and state.ForceField then
					state.ForceField:Destroy()
					state.ForceField = nil
				end
			elseif action == "Fly" then
				state.Fly = args.Enabled
			elseif action == "Noclip" then
				state.Noclip = args.Enabled
			elseif action ~= "RenewMovement" then
				return false, "Unknown action."
			end
			return true,
				"Movement tools authorized for 15 seconds; renewed while the panel client is connected.",
				{ Movement = { Fly = state.Fly, Noclip = state.Noclip, LeaseSeconds = Config.MovementLeaseSeconds } }
		end
		return true, "Admin action applied."
	end
	function self:ClearTestCosmetics(player)
		local character = player.Character
		if not character then
			return
		end
		for _, name in ipairs({ "PassSparkleTrail", "PassTrailLeft", "PassTrailRight", "PassSparkles", "PassVIPStar" }) do
			local object = character:FindFirstChild(name, true)
			if object then
				object:Destroy()
			end
		end
	end
	function self:Remove(player)
		local hadTest = testUnlocks.Players[player] ~= nil
		testUnlocks:Set(player, false)
		if hadTest then
			self:ClearTestCosmetics(player)
		end
		if hadTest and player.Parent == Players and data:Get(player) then
			monetization:Apply(player)
		end
		self:ResetMovement(player)
		for _, link in ipairs(self.Links[player] or {}) do
			link:Disconnect()
		end
		self.Links[player] = nil
	end
	function self:Start(service)
		local function sessionActive(player)
			-- Get intentionally hides a profile while ReplaceAndSave holds its mutation guard.
			-- That short transaction is not a revoked session; both leases still apply.
			if data.Replacing[player] then
				return not data.Stopping
					and not data.Closing[player]
					and data.Profiles[player] ~= nil
					and (data.NoPersistence[player] == true or os.time() < (data.LeaseExpires[player] or 0))
			end
			return data:Get(player) ~= nil
		end
		Players.PlayerRemoving:Connect(function(player)
			service:Remove(player)
		end)
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			self.HeartbeatSeconds = self.HeartbeatSeconds * 0.9 + dt * 0.1
			for player, expires in pairs(testUnlocks.Players) do
				if os.clock() >= expires or not self:Present(player) or not sessionActive(player) then
					testUnlocks:Set(player, false)
					self:ClearTestCosmetics(player)
					if self:Present(player) and data:Get(player) then
						monetization:Apply(player)
					end
				end
			end
			for player, state in pairs(self.Movement) do
				if
					not self:Present(player)
					or not sessionActive(player)
					or os.clock() >= state.Expires
					or not state.Humanoid.Parent
					or state.Humanoid.Parent ~= player.Character
				then
					self:ResetMovement(player)
					continue
				end
				if state.God then
					state.Humanoid.Health = state.Humanoid.MaxHealth
				end
				if state.Noclip then
					for _, part in ipairs(player.Character:GetDescendants()) do
						if part:IsA("BasePart") then
							if state.Collisions[part] == nil then
								state.Collisions[part] = part.CanCollide
							end
							part.CanCollide = false
						end
					end
				else
					for part, collision in pairs(state.Collisions) do
						if part.Parent then
							part.CanCollide = collision
						end
					end
					table.clear(state.Collisions)
				end
			end
		end)
	end
	return self
end
return Runtime
