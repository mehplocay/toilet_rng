-- Server-only shared cache. Build never yields or performs an asset request.
local InsertService = game:GetService("InsertService")
local ContentProvider = game:GetService("ContentProvider")
local ServerStorage = game:GetService("ServerStorage")
local Config = game.ReplicatedStorage.Shared.Config
local Assets = require(Config.Assets)
local Catalog = require(Config.MeshCatalog)
local Loader = {}
local templates, states = {}, {}
local started = false
local cacheFolder

local function contentId(value)
	if type(value) ~= "string" then
		return nil
	end
	local digits = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
	return if digits and tonumber(digits) > 0 then "rbxassetid://" .. digits else nil
end

local function warm(name)
	local ids = Assets.Meshes[name]
	local meshId = ids and contentId(ids.MeshId)
	local textureId = ids and contentId(ids.TextureId)
	if not meshId or not textureId then
		states[name] = "Unconfigured"
		return
	end
	states[name] = "Loading"
	local template
	local ok, problem = pcall(function()
		template = InsertService:CreateMeshPartAsync(meshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
		assert(template and template:IsA("MeshPart"), "No MeshPart returned")
		template.Name = name
		template.TextureID = textureId
		template.Color = Color3.new(1, 1, 1)
		template.Material = Enum.Material.SmoothPlastic
		template.Size = Catalog[name].Size
		template.Anchored = true
		template.CanCollide, template.CanTouch, template.CanQuery = false, false, false
		template.CastShadow = name ~= "CloudPuffs"
		local failed = false
		ContentProvider:PreloadAsync({ template }, function(_, status)
			if status ~= Enum.AssetFetchStatus.Success then
				failed = true
			end
		end)
		assert(not failed, "Mesh or palette download failed")
		template.Parent = cacheFolder
	end)
	if ok then
		templates[name], states[name] = template, "Ready"
	else
		if template then
			template:Destroy()
		end
		states[name] = "Unavailable"
		warn("MeshLoader: " .. name .. " uses primitives: " .. tostring(problem))
	end
end

function Loader.Preload()
	if started then
		return
	end
	started = true
	cacheFolder = Instance.new("Folder")
	cacheFolder.Name, cacheFolder.Parent = "WorldMeshTemplates", ServerStorage
	local names = {}
	for name in pairs(Catalog) do
		states[name] = "Queued"
		table.insert(names, name)
	end
	table.sort(names)
	local cursor, remaining = 0, #names
	for _ = 1, 4 do
		task.spawn(function()
			while cursor < #names do
				cursor += 1
				local name = names[cursor]
				warm(name)
				remaining -= 1
			end
		end)
	end
	local deadline = os.clock() + 8
	while remaining > 0 and os.clock() < deadline do
		task.wait()
	end
	-- Slow requests may finish later; startup and gameplay never wait indefinitely.
end

function Loader.Status(name)
	return states[name] or "Unconfigured"
end

function Loader.Build(name, parent, cf, fallback, scale)
	assert(Catalog[name], "Unknown mesh asset: " .. name)
	local template = templates[name]
	if not template then
		local model = fallback()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model:SetAttribute("MeshAsset", name)
		model:SetAttribute("MeshFallback", true)
		model:SetAttribute("MeshStatus", Loader.Status(name))
		return model
	end
	local model = Instance.new("Model")
	model.Name = name
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local part = template:Clone()
	local factor = scale or 1
	part.Size = Catalog[name].Size * factor
	local center = Catalog[name].Center or Vector3.new(0, Catalog[name].Size.Y / 2, 0)
	part.CFrame = cf * CFrame.new(center * factor)
	part.PivotOffset = CFrame.new(center * -factor)
	part.Parent, model.PrimaryPart = model, part
	model:SetAttribute("MeshAsset", name)
	model:SetAttribute("MeshFallback", false)
	model:SetAttribute("MeshStatus", "Ready")
	model.Parent = parent
	return model
end

return Loader
