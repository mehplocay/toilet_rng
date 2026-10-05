-- Upload IDs identify Decals. Only resolved Image content reaches ImageLabels.
local Content = {}
function Content.Id(value)
	local id = if type(value) == "number"
		then value
		elseif type(value) == "string" then tonumber(
			value:match("^rbxassetid://(%d+)$") or value:match("[?&]id=(%d+)") or value
		)
		else nil
	return if id and id > 0 and id < math.huge and id % 1 == 0 then string.format("%.0f", id) else nil
end
function Content.Image(value)
	local id = Content.Id(value)
	return if id then "rbxassetid://" .. id else nil
end
function Content.Override(assets, id)
	return Content.Image((assets.IconImages or {})[id] or (assets.IconImages or {})[tonumber(id)])
end
function Content.Ids(assets)
	local ids, seen = {}, {}
	for _, group in ipairs({ assets.Icons, assets.ItemIcons, assets.ToiletIcons }) do
		for _, value in pairs(group or {}) do
			local id = Content.Id(value)
			if id and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	table.sort(ids)
	return ids
end
return Content
