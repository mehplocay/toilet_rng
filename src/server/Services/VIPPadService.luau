local CashMath = require(game.ReplicatedStorage.Shared.CashMath)
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Monetization)
local Paid = require(Shared.PaidBenefits)
local Copy = require(Shared.CommerceProfile).Copy
local Pad = {}
function Pad.Claim(commerce, player)
	local data, config = commerce.Data, Config.VIPPad
	local profile = data:Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
	if
		not profile
		or data.Saving[player]
		or data.NoPersistence[player]
		or not Paid.Owns(profile, "VIPPack")
		or not root
		or not humanoid
		or not (humanoid.Health > 0 and humanoid.Health < math.huge)
	then
		return false
	end
	local distance = (root.Position - Vector3.new(config.X, config.Y, config.Z)).Magnitude
	if not (distance >= 0 and distance <= config.Radius) then
		return false
	end
	local now = os.time()
	if now < profile.Monetization.VIPPadAt + config.Cooldown then
		return false
	end
	local coins = math.clamp(
		math.floor(CashMath.Product(commerce.Receipts:Rate(profile), config.IncomeSeconds)),
		config.Min,
		config.Max
	)
	if not CashMath.CanGrant(profile, coins) then
		return false
	end
	local replacement = Copy(profile)
	replacement.Monetization.VIPPadAt = now
	replacement.Coins += coins
	replacement.Stats.Earned += coins
	if not data:ReplaceAndSave(player, profile, replacement) then
		return false
	end
	if data:Get(player) ~= replacement then
		return false
	end
	commerce.Sync(player)
	return true
end
function Pad.Start(commerce, remotes)
	local config = Config.VIPPad
	local part = Instance.new("Part")
	part.Name, part.Size = "VIPBonusPad", Vector3.new(7, 0.3, 7)
	part.Position, part.Color = Vector3.new(config.X, config.Y, config.Z), Color3.fromRGB(255, 190, 45)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.Material, part.Parent = Enum.Material.Neon, workspace
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = "VIPBonus", "Claim VIP bonus", "VIP hub pad / 5 minute cooldown"
	prompt.MaxActivationDistance, prompt.RequiresLineOfSight = config.Radius, false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		if commerce.Limiter:Allow(player, "VIPPad") then
			local claimed = Pad.Claim(commerce, player)
			remotes.Result:FireClient(player, "VIPPad", {
				Success = claimed,
				Message = if claimed
					then "VIP pad bonus collected!"
					else "VIP required. Return after the 5 minute cooldown.",
			})
		end
	end)
	return part
end
return Pad
