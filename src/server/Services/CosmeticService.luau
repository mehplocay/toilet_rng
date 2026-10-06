local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Monetization)
local Rules = require(Shared.MonetizationRules)
local P = require(Shared.Visuals.Primitives)
local RebirthCosmetics = require(script.Parent.Parent.World.RebirthCosmetics)
local CosmeticService = {}
CosmeticService.__index = CosmeticService

function CosmeticService.new(world)
	return setmetatable({ World = world, Colors = {}, PlayerPlots = {} }, CosmeticService)
end

function CosmeticService:Apply(player, owned, profile)
	RebirthCosmetics.Character(player, profile)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local vip = owned.VIPStar == true or owned.VIPPack == true
	local gold = Color3.fromRGB(table.unpack(Config.VIPTrailRGB))
	local trailColor = if owned.VIPPack then gold else Color3.fromRGB(table.unpack(Config.SparkleRGB))
	if
		root
		and (owned.SparkleTrail == true or owned.VIPPack == true)
		and not root:FindFirstChild("PassSparkleTrail")
	then
		local left, right = Instance.new("Attachment"), Instance.new("Attachment")
		left.Name, right.Name = "PassTrailLeft", "PassTrailRight"
		left.Position, right.Position = Vector3.new(-0.65, -1, 0), Vector3.new(0.65, -1, 0)
		left.Parent, right.Parent = root, root
		local trail = Instance.new("Trail")
		trail.Name = "PassSparkleTrail"
		trail.Attachment0, trail.Attachment1 = left, right
		trail.Color = ColorSequence.new(trailColor)
		trail.Lifetime = Config.TrailLifetime
		trail.Transparency = NumberSequence.new(0.35, 1)
		trail.FaceCamera = true
		trail.Parent = root
		P.Particles(root, "PassSparkles", trailColor, Config.SparkleRate, {
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(180, 180),
		})
	end
	if root and (owned.SparkleTrail == true or owned.VIPPack == true) and root:FindFirstChild("PassSparkleTrail") then
		root.PassSparkleTrail.Color = ColorSequence.new(trailColor)
		local sparkles = root:FindFirstChild("PassSparkles")
		if sparkles then
			sparkles.Color = ColorSequence.new(trailColor)
		end
	end
	player:SetAttribute("VIPStar", vip)
	if head and vip and not head:FindFirstChild("PassVIPStar") then
		local tag = Instance.new("BillboardGui")
		tag.Name, tag.Adornee = "PassVIPStar", head
		tag.Size = UDim2.fromOffset(120, 32)
		tag.StudsOffset = Vector3.new(0, 3, 0)
		tag.MaxDistance = 70
		tag.Parent = head
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		label.Text, label.TextColor3 = Config.VIPLabel, gold
		label.Font, label.TextSize = Enum.Font.GothamBold, 22
		label.TextStrokeTransparency = 0.3
		label.Parent = tag
	end
	local plot = self.World.Assigned[player]
	if not plot then
		return
	end
	self.PlayerPlots[player] = plot
	if owned.VIPPack and plot.IncomePoint and not plot.Model:FindFirstChild("VIPPlotSign") then
		local tag = Instance.new("BillboardGui")
		tag.Name, tag.Adornee = "VIPPlotSign", plot.IncomePoint
		tag.Size, tag.StudsOffset = UDim2.fromOffset(110, 34), Vector3.new(0, 4, 0)
		tag.MaxDistance, tag.Parent = 60, plot.Model
		local text = Instance.new("TextLabel")
		text.Size, text.BackgroundColor3 = UDim2.fromScale(1, 1), Color3.fromRGB(37, 30, 52)
		text.Text, text.TextColor3 = Config.VIPLabel, gold
		text.Font, text.TextSize, text.Parent = Enum.Font.GothamBold, 23, tag
	end
	-- Remember builder colors so an empty plot or the next owner never inherits a tint.
	local originals = self.Colors[plot]
	if not originals then
		originals = {}
		for _, part in ipairs(plot.Model:GetDescendants()) do
			if
				part:IsA("BasePart")
				and (part:GetAttribute("PlotTint") or part.Name == "Lawn" or part.Name == "StoneBorder")
			then
				originals[part] = part.Color
			end
		end
		self.Colors[plot] = originals
	end
	local choice = profile and Rules.PlotColor(Config, profile.Settings.PlotColor)
	local color = owned.CustomPlotColor == true and choice and choice.RGB
	for part, original in pairs(originals) do
		part.Color = if color then Color3.fromRGB(table.unpack(color)) else original
	end
end

function CosmeticService:ResetPlot(plot)
	RebirthCosmetics.Plot(plot, 0)
	local sign = plot.Model:FindFirstChild("VIPPlotSign")
	if sign then
		sign:Destroy()
	end
	for part, color in pairs(self.Colors[plot] or {}) do
		part.Color = color
	end
end

function CosmeticService:Remove(player)
	local plot = self.PlayerPlots[player]
	if plot then
		self:ResetPlot(plot)
	end
	self.PlayerPlots[player] = nil
end

function CosmeticService:Start(owned, profile)
	local function connect(player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(function()
				character:WaitForChild("HumanoidRootPart", 10)
				character:WaitForChild("Head", 10)
				if player.Parent == Players and player.Character == character then
					self:Apply(player, owned[player] or {}, profile(player))
				end
			end)
		end)
		self:Apply(player, owned[player] or {}, profile(player))
	end
	Players.PlayerAdded:Connect(connect)
	for _, player in ipairs(Players:GetPlayers()) do
		connect(player)
	end
end

return CosmeticService
