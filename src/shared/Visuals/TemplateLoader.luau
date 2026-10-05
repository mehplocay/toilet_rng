-- Imported content is cloned unchanged; no asset requests or protected property writes.
local Storage = game:GetService("ReplicatedStorage")
local Catalog = require(script.Parent.Parent.Config.MeshCatalog)
local Loader = {}
local templates, states, sources, descendantCounts = {}, {}, {}, {}

local function largest(size)
	return math.max(size.X, size.Y, size.Z)
end

local function warm(name)
	local folder = Storage:FindFirstChild(Catalog[name].Folder or "ModelTemplates")
	local source = folder and folder:FindFirstChild(name)
	local count = if source then #source:GetDescendants() else 0
	-- Missing replicas are retried on the next build, never waited for on a flush.
	if source == sources[name] and states[name] and count == descendantCounts[name] then
		return
	end
	sources[name] = source
	descendantCounts[name] = count
	if templates[name] then
		templates[name]:Destroy()
		templates[name] = nil
	end
	if not source then
		states[name] = "Missing"
		return
	end
	local model
	local ok, problem = pcall(function()
		assert(source:IsA("Model"), "Template must be a Model")
		model = source:Clone()
		local part
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("BasePart") then
				assert(not part and child:IsA("MeshPart"), "Expected exactly one MeshPart")
				part = child
			else
				assert(child:IsA("SurfaceAppearance"), "Unexpected template child: " .. child.ClassName)
			end
		end
		assert(part, "Empty template")
		-- Studio authored Y-up/front correction lives in the mesh pivot, not its staging CFrame.
		local importedPivot = part.PivotOffset
		local rotation = (importedPivot - importedPivot.Position):Inverse()
		assert(
			(rotation:VectorToWorldSpace(Vector3.new(0, 1, 0)) - Vector3.new(0, 1, 0)).Magnitude < 0.001,
			"Template pivot must preserve Y-up"
		)
		part.CFrame, part.PivotOffset = rotation, CFrame.new()
		model.PrimaryPart = part
		local _, size = model:GetBoundingBox()
		assert(size.X > 0 and size.Y > 0 and size.Z > 0 and largest(size) < math.huge, "Invalid bounds")
		local factor = largest(Catalog[name].Size) / largest(size)
		local normalizedSize = size * factor
		assert((normalizedSize - Catalog[name].Size).Magnitude < 0.01, "Bounds disagree with manifest axes/aspect")
		part.Size = part.Size * factor
		local center = Vector3.new(0, normalizedSize.Y / 2, 0)
		if Catalog[name].Center then
			-- Decorations shift toilet bounds. Keep the imported foot datum and shared 2.08-stud seat.
			local foot = rotation:VectorToWorldSpace(importedPivot.Position * factor)
			center = Vector3.new(-foot.X, normalizedSize.Y / 2, -foot.Z)
			model:SetAttribute("SeatHeight", 2.08)
		end
		part.CFrame = CFrame.new(center) * rotation
		part.PivotOffset = part.CFrame:Inverse()
		part.Name = name
		part.Anchored = true
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		part.CastShadow = not Catalog[name].NoShadow and name ~= "CloudPuffs"
		part.Color, part.Material = Color3.new(1, 1, 1), Enum.Material.SmoothPlastic
		-- RenderFidelity is authored Automatic in the rbxm (PluginSecurity at runtime).
		-- Mesh collision fidelity is imported; walking collision uses separate Box Parts.
		model.Name = name
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model:SetAttribute("MeshAsset", name)
		model:SetAttribute("MeshFallback", false)
		model:SetAttribute("MeshStatus", "Ready")
		model:SetAttribute("NormalizationScale", factor)
	end)
	if ok then
		templates[name], states[name] = model, "Ready"
	else
		if model then
			model:Destroy()
		end
		states[name] = "Invalid"
		warn("TemplateLoader: " .. name .. " uses primitives: " .. tostring(problem))
	end
end

function Loader.Preload()
	for name in pairs(Catalog) do
		warm(name)
	end
end

function Loader.Status(name)
	warm(name)
	return states[name]
end

function Loader.Clone(name, parent, cf, scale)
	assert(Catalog[name], "Unknown template: " .. name)
	warm(name)
	local template = templates[name]
	if not template then
		return nil
	end
	local model = template:Clone()
	if scale and scale ~= 1 then
		model:ScaleTo(model:GetScale() * scale)
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

function Loader.Build(name, parent, cf, fallback, scale)
	local model = Loader.Clone(name, parent, cf, scale)
	if model then
		return model
	end
	model = fallback()
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("MeshAsset", name)
	model:SetAttribute("MeshFallback", true)
	model:SetAttribute("MeshStatus", Loader.Status(name))
	return model
end

return Loader
