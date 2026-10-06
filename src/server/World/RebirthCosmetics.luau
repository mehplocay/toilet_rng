-- Server-derived cosmetics only. No ownership, income, luck or tier mutations.
local Config = require(game.ReplicatedStorage.Shared.Config.Rebirth)
local Cosmetics = {}
local function latest(level, kind)
	local found
	for _, entry in ipairs(Config.Cosmetics) do
		if entry.Level <= level and entry.Kind == kind then
			found = entry
		end
	end
	return found
end
local function remove(parent, name)
	local child = parent and parent:FindFirstChild(name)
	if child then
		child:Destroy()
	end
end
local function glow(parent, name, entry)
	if not parent then
		return
	end
	if not entry then
		remove(parent, name)
		return
	end
	local effect = parent:FindFirstChild(name) or Instance.new("Highlight")
	effect.Name, effect.Adornee = name, parent
	effect.FillColor = Color3.fromRGB(table.unpack(entry.RGB))
	effect.OutlineColor = effect.FillColor
	effect.FillTransparency, effect.OutlineTransparency = 0.75, 0.2
	effect.DepthMode = Enum.HighlightDepthMode.Occluded
	effect.Parent = parent
end
function Cosmetics.Character(player, profile)
	if not profile then
		return
	end
	local level = profile.RebirthLevel or 0
	local legend, trail = latest(level, "Legend"), latest(level, "Trail")
	local tag = latest(level, "ChatTag")
	player:SetAttribute("RebirthChatLevel", if tag then tag.Level else 0)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	glow(character, "RebirthAura", legend)
	if root and trail then
		local effect = root:FindFirstChild("RebirthTrail")
		if not effect then
			local left, right = Instance.new("Attachment"), Instance.new("Attachment")
			left.Name, right.Name = "RebirthTrailLeft", "RebirthTrailRight"
			left.Position, right.Position = Vector3.new(-0.6, -1, 0), Vector3.new(0.6, -1, 0)
			left.Parent, right.Parent = root, root
			effect = Instance.new("Trail")
			effect.Name, effect.Attachment0, effect.Attachment1 = "RebirthTrail", left, right
			effect.Lifetime, effect.FaceCamera = 0.6, true
			effect.Transparency = NumberSequence.new(0.4, 1)
			effect.Parent = root
		end
		effect.Color = ColorSequence.new(Color3.fromRGB(table.unpack((legend or trail).RGB)))
	elseif root then
		for _, name in ipairs({ "RebirthTrail", "RebirthTrailLeft", "RebirthTrailRight" }) do
			remove(root, name)
		end
	end
	if head and (latest(level, "Title") or legend) then
		local title = head:FindFirstChild("RebirthTitle")
		if not title then
			title = Instance.new("BillboardGui")
			title.Name, title.Adornee = "RebirthTitle", head
			title.Size, title.StudsOffset = UDim2.fromOffset(180, 28), Vector3.new(0, 3.8, 0)
			title.MaxDistance, title.Parent = 60, head
			local text = Instance.new("TextLabel")
			text.Name, text.Size, text.BackgroundTransparency = "Label", UDim2.fromScale(1, 1), 1
			text.Font, text.TextSize, text.TextStrokeTransparency = Enum.Font.GothamBold, 18, 0.3
			text.Parent = title
		end
		local label = title:FindFirstChild("Label")
		label.Text = Config.Levels[math.min(level, #Config.Levels)].Title
		label.TextColor3 = Color3.fromRGB(table.unpack((legend or Config.Cosmetics[1]).RGB))
	else
		remove(head, "RebirthTitle")
	end
end
function Cosmetics.Plot(plot, level)
	local trim = latest(level, "Trim")
	local stroke = plot.Sign:FindFirstChild("RebirthTrim")
	if trim then
		stroke = stroke or Instance.new("UIStroke")
		stroke.Name, stroke.Thickness = "RebirthTrim", 3
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color, stroke.Parent = Color3.fromRGB(table.unpack(trim.RGB)), plot.Sign
	else
		remove(plot.Sign, "RebirthTrim")
	end
	glow(plot.Toilet, "LegendSkin", latest(level, "Legend"))
end
return Cosmetics
