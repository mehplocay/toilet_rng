local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Assets, Style, Toilets =
	require(Shared.Config.Assets), require(Shared.Config.World), require(Shared.Config.Toilets)
local Preview = {}
function Preview.Create(parent, size, position, item, tier, silhouette)
	local frame =
		C.New("Frame", parent, { Name = "Preview", Size = size, Position = position, BackgroundTransparency = 1 })
	local kind = if silhouette then "Locked" elseif item then item.Id else "Flush"
	local id = if silhouette
		then nil
		elseif item then (Assets.ItemIcons or {})[item.Id]
		else (Assets.ToiletIcons or {})[Toilets[tier].Id]
	local tint = if item then Style.ItemColors[item.Id] else Style.ToiletColors[tier or 1]
	local icon = C.Icon(frame, kind, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), id, tint)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	return frame
end
return Preview
