-- Fixed allowlist, four yielding workers. Loaded containers are never parented.
local Resolver = {}
function Resolver.Run(assets, content, load, publish, spawn, report, complete)
	local queue = {}
	for _, id in ipairs(content.Ids(assets)) do
		local override = content.Override(assets, id)
		if override then
			publish(id, override)
		else
			table.insert(queue, id)
		end
	end
	local cursor, workers = 0, math.min(4, #queue)
	if workers == 0 then
		complete()
	end
	for _ = 1, workers do
		spawn(function()
			while true do
				cursor += 1
				local id = queue[cursor]
				if not id then
					break
				end
				local container
				local ok, image = pcall(function()
					container = load(tonumber(id))
					local decal = container:FindFirstChildWhichIsA("Decal", true)
					assert(decal, "Asset contains no Decal")
					local result = content.Image(decal.Texture)
					assert(result and content.Id(result) ~= id, "Decal has no resolved Image content")
					return result
				end)
				if container then
					container:Destroy()
				end
				if ok then
					publish(id, image)
				else
					report(
						"Icon resolution failed for " .. id .. ": " .. tostring(image) .. "; see docs/icons-resolve.md"
					)
				end
			end
			workers -= 1
			if workers == 0 then
				complete()
			end
		end)
	end
end
function Resolver.Start()
	local storage = game:GetService("ReplicatedStorage")
	local assets = require(storage.Shared.Config.Assets)
	local content = require(storage.Shared.IconContent)
	local folder = Instance.new("Folder")
	folder.Name = "ResolvedIcons"
	folder.Parent = storage
	task.spawn(function()
		Resolver.Run(
			assets,
			content,
			function(id)
				-- Modern loader supports shared assets and public third-party assets when enabled.
				local ok, model = pcall(function()
					return game:GetService("AssetService"):LoadAssetAsync(id)
				end)
				if ok then
					return model
				end
				-- Some older OpenUse decals still resolve through InsertService.
				return game:GetService("InsertService"):LoadAsset(id)
			end,
			function(id, image)
				folder:SetAttribute("Image_" .. id, image)
			end,
			task.spawn,
			warn,
			function()
				folder:SetAttribute("Complete", true)
			end
		)
	end)
end
return Resolver
