local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.PathBoost)
local Monetization = require(Shared.Config.Monetization)
local Paid = require(Shared.PaidBenefits)
local Rules = require(Shared.PathBoostRules)
local zones = Rules.Zones(require(Shared.Config.MapLayout), require(Shared.Config.MeshCatalog), Config)
local Service = {}
function Service.Start(data)
	local states, connections = {}, {}
	local function clear(player)
		local state = states[player]
		if state then
			if state.Tween then
				state.Tween:Cancel()
			end
			if state.Humanoid.Parent then
				state.Humanoid.WalkSpeed = state.Base
			end
		end
		states[player] = nil
		player:SetAttribute("PathSpeedMultiplier", 1)
	end
	local function connect(player)
		connections[player] = player.CharacterRemoving:Connect(function()
			clear(player)
		end)
	end
	Players.PlayerAdded:Connect(connect)
	for _, player in ipairs(Players:GetPlayers()) do
		connect(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		clear(player)
		if connections[player] then
			connections[player]:Disconnect()
			connections[player] = nil
		end
	end)
	task.spawn(function()
		while not data.Stopping do
			task.wait(Config.CheckSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not humanoid or not root or not (humanoid.Health > 0) then
					clear(player)
					continue
				end
				local state = states[player]
				if not state or state.Humanoid ~= humanoid then
					clear(player)
					state = { Humanoid = humanoid, Base = humanoid.WalkSpeed, LastLog = -math.huge }
					states[player] = state
				end
				local profile = data:Get(player)
				local pos, now = root.Position, os.clock()
				local onPath = Rules.Find(zones, pos.X, pos.Y, pos.Z, Config.RootHeight) ~= nil
				-- An exclusive receipt/rebirth save temporarily hides the profile. Keep the
				-- last verified movement benefits through that guard, including their expiry.
				if profile then
					state.VIP = Paid.Owns(profile, "VIPPack")
					state.PathExpires = profile.Monetization.PathExpires
				elseif not data.Replacing[player] then
					state.VIP, state.PathExpires = false, 0
				end
				local vip = if state.VIP then Monetization.Gamepasses.VIPPack.PathSpeedStep else 0
				local paidPath = if (state.PathExpires or 0) > os.time()
					then Monetization.DeveloperProducts.PathBoost10Minutes.PathMultiplier
					else 1
				local multiplier =
					Rules.Multiplier(onPath, vip, paidPath, player:GetAttribute("ServerSpeedMultiplier"), Config)
				-- Admin tools set this server attribute; it is intentionally outside the boost cap.
				local override = player:GetAttribute("AdminWalkSpeed")
				local target, changed = Rules.Plan(state, state.Base, multiplier, override, true, Config)
				if changed then
					if state.Tween then
						state.Tween:Cancel()
					end
					state.Tween = TweenService:Create(
						humanoid,
						TweenInfo.new(Config.EaseSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{ WalkSpeed = target }
					)
					state.Tween:Play()
					state.ChangedAt = now
				elseif now - state.ChangedAt > Config.EaseSeconds and humanoid.WalkSpeed ~= target then
					humanoid.WalkSpeed = target
				end
				player:SetAttribute("PathSpeedMultiplier", if onPath and override == nil then state.Multiplier else 1)
				if state.Position and override == nil and now - state.Time < 1 then
					local delta = Vector3.new(pos.X - state.Position.X, 0, pos.Z - state.Position.Z).Magnitude
					local allowed = math.max(target, state.PreviousTarget or target)
							* (now - state.Time)
							* Config.SanityMultiplier
						+ Config.SanitySlack
					if
						delta > allowed
						and delta < Config.TeleportDistance
						and now - state.LastLog >= Config.SanityLogSeconds
					then
						state.LastLog = now
						warn("Movement sanity observation", player.UserId, math.floor(delta))
					end
				end
				state.Position, state.Time, state.PreviousTarget = pos, now, target
			end
		end
		for player in pairs(states) do
			clear(player)
		end
	end)
end
return Service
