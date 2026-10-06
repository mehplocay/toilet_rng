local Vector3 = {}
local vm = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vm)
end
vm.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
vm.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
vm.__mul = function(a, b)
	return Vector3.new(a.X * b, a.Y * b, a.Z * b)
end
vm.__index = function(a, key)
	if key == "Magnitude" then
		return math.sqrt(a.X * a.X + a.Y * a.Y + a.Z * a.Z)
	end
	if key == "Unit" then
		return a * (1 / math.max(a.Magnitude, 1e-9))
	end
end
local CFrame, cm = {}, {}
function CFrame.new(x, y, z, ...)
	return setmetatable({
		Position = if type(x) == "table" then x else Vector3.new(x, y, z),
		R = if select("#", ...) == 9 then { ... } else { 1, 0, 0, 0, 1, 0, 0, 0, 1 },
	}, cm)
end
local function rotate(a, v)
	local r = a.R
	return Vector3.new(
		r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		r[7] * v.X + r[8] * v.Y + r[9] * v.Z
	)
end
cm.__mul = function(a, b)
	local c = CFrame.new(a.Position + rotate(a, b.Position))
	for i = 0, 2 do
		for j = 1, 3 do
			c.R[i * 3 + j] = a.R[i * 3 + 1] * b.R[j] + a.R[i * 3 + 2] * b.R[3 + j] + a.R[i * 3 + 3] * b.R[6 + j]
		end
	end
	return c
end
function CFrame.Angles(x, y, z)
	local a, b, c = CFrame.new(), CFrame.new(), CFrame.new()
	a.R = { 1, 0, 0, 0, math.cos(x), -math.sin(x), 0, math.sin(x), math.cos(x) }
	b.R = { math.cos(y), 0, math.sin(y), 0, 1, 0, -math.sin(y), 0, math.cos(y) }
	c.R = { math.cos(z), -math.sin(z), 0, math.sin(z), math.cos(z), 0, 0, 0, 1 }
	return a * b * c
end
function CFrame.lookAt(position, target)
	local back = (position - target).Unit
	local right = Vector3.new(back.Z, 0, -back.X).Unit
	local up = Vector3.new(
		back.Y * right.Z - back.Z * right.Y,
		back.Z * right.X - back.X * right.Z,
		back.X * right.Y - back.Y * right.X
	)
	local c = CFrame.new(position)
	c.R = { right.X, up.X, back.X, right.Y, up.Y, back.Y, right.Z, up.Z, back.Z }
	return c
end
cm.__add = function(a, b)
	local c = CFrame.new(a.Position + b)
	c.R = a.R
	return c
end
cm.__sub = function(a, b)
	return a + b * -1
end
cm.__index = {
	VectorToWorldSpace = rotate,
	Inverse = function(a)
		local c = CFrame.new()
		c.R = { a.R[1], a.R[4], a.R[7], a.R[2], a.R[5], a.R[8], a.R[3], a.R[6], a.R[9] }
		c.Position = rotate(c, a.Position * -1)
		return c
	end,
}
local Color3 = {}
function Color3.new(r, g, b)
	return {
		R = r or 0,
		G = g or 0,
		B = b or 0,
		Lerp = function(a, other, t)
			return Color3.new(a.R + (other.R - a.R) * t, a.G + (other.G - a.G) * t, a.B + (other.B - a.B) * t)
		end,
	}
end
function Color3.fromRGB(r, g, b)
	return Color3.new(r / 255, g / 255, b / 255)
end
local Enum = setmetatable({}, {
	__index = function(self, key)
		local enum = setmetatable({}, {
			__index = function(_, name)
				return key .. "." .. name
			end,
		})
		rawset(self, key, enum)
		return enum
	end,
})
local signal = {
	Connect = function()
		return { Disconnect = function() end }
	end,
	Once = function() end,
}
local methods = {}
local function isPart(object)
	return object.ClassName == "Part"
		or object.ClassName == "WedgePart"
		or object.ClassName == "SpawnLocation"
		or object.ClassName == "MeshPart"
end
function methods:IsA(class)
	return self.ClassName == class or class == "BasePart" and isPart(self)
end
function methods:GetChildren()
	return table.clone(self._children)
end
function methods:GetDescendants()
	local result = {}
	for _, child in ipairs(self._children) do
		table.insert(result, child)
		for _, nested in ipairs(child:GetDescendants()) do
			table.insert(result, nested)
		end
	end
	return result
end
function methods:SetAttribute(key, value)
	self._attributes[key] = value
end
function methods:GetAttribute(key)
	return self._attributes[key]
end
function methods:Destroy()
	self:ClearAllChildren()
	self.Parent = nil
end
function methods:ClearAllChildren()
	for _, child in ipairs(self:GetChildren()) do
		child:Destroy()
	end
end
function methods:GetPivot()
	return (self.PrimaryPart and self.PrimaryPart.CFrame * (self.PrimaryPart.PivotOffset or CFrame.new()))
		or self.WorldPivot
		or CFrame.new()
end
function methods:GetBoundingBox()
	-- Imported fixtures contain exactly one mesh. Other builder bounds are not mocked.
	local part = self.PrimaryPart
	assert(part and part:IsA("MeshPart"))
	return part.CFrame, part.Size
end
function methods:GetScale()
	return self._scale or 1
end
function methods:ScaleTo(scale)
	local ratio = scale / self:GetScale()
	local pivot = self:GetPivot()
	for _, part in ipairs(self:GetDescendants()) do
		if isPart(part) then
			local relative = pivot:Inverse() * part.CFrame
			part.CFrame = pivot * ((relative - relative.Position) + relative.Position * ratio)
			part.Size = part.Size * ratio
			local offset = part.PivotOffset or CFrame.new()
			part.PivotOffset = (offset - offset.Position) + offset.Position * ratio
		end
	end
	self._scale = scale
end
function methods:PivotTo(cf)
	local delta = cf * self:GetPivot():Inverse()
	for _, part in ipairs(self:GetDescendants()) do
		if isPart(part) then
			part.CFrame = delta * part.CFrame
		end
	end
	self.WorldPivot = cf
end
function methods:FindFirstChild(name)
	for _, child in ipairs(self._children) do
		if child.Name == name then
			return child
		end
	end
end
local Instance = {}
local templateClones = 0
function methods:Clone()
	if self.Parent and (self.Parent.Name == "ModelTemplates" or self.Parent.Name == "EnvTemplates") then
		templateClones += 1
	end
	local result = Instance.new(self.ClassName)
	for key, value in pairs(self._props) do
		if key ~= "Parent" then
			result[key] = value
		end
	end
	for key, value in pairs(self._attributes) do
		result:SetAttribute(key, value)
	end
	for _, child in ipairs(self:GetChildren()) do
		local copy = child:Clone()
		copy.Parent = result
		if self.PrimaryPart == child then
			result.PrimaryPart = copy
		end
	end
	return result
end
function Instance.new(class)
	return setmetatable({
		_props = {
			ClassName = class,
			Name = class,
			CanCollide = true,
			CanTouch = true,
			CanQuery = true,
			Transparency = 0,
		},
		_children = {},
		_attributes = {},
		_touch = { Handlers = {} },
	}, {
		__index = function(self, key)
			if key == "Touched" then
				local event = self._touch
				function event:Connect(fn)
					table.insert(self.Handlers, fn)
					return { Disconnect = function() end }
				end
				function event:Fire(hit)
					for _, fn in ipairs(self.Handlers) do
						fn(hit)
					end
				end
				return event
			end
			if methods[key] then
				return methods[key]
			end
			if self._props[key] ~= nil then
				return self._props[key]
			end
			return if key == "Triggered" or key == "Changed" then signal else nil
		end,
		__newindex = function(self, key, value)
			if
				self._props[key] ~= nil
				and self.ClassName == "MeshPart"
				and (key == "RenderFidelity" or key == "CollisionFidelity" or key == "MeshContent")
			then
				error("Protected MeshPart property write: " .. key)
			end
			if key == "Parent" then
				local old = self._props.Parent
				if old then
					local index = table.find(old._children, self)
					if index then
						table.remove(old._children, index)
					end
				end
				if value then
					table.insert(value._children, self)
				end
			end
			self._props[key] = value
		end,
	})
end
local nodes, cache, sources = {}, {}, {}
local function node(path)
	if nodes[path] then
		return nodes[path]
	end
	local object = { Path = path }
	nodes[path] = object
	local parent, name = path:match("^(.*)/([^/]+)$")
	if parent then
		object.Parent = node(parent)
		object.Parent[name] = object
	end
	return object
end
local workspace = Instance.new("Workspace")
local terrain = Instance.new("Terrain")
workspace.Terrain = terrain
terrain.Parent = workspace
local terrainWrites, terrainCells, terrainMaterials = 0, 0, {}
function methods:SetMaterialColor() end
function methods:FillBlock(cf, size, material)
	assert(material == Enum.Material.Water, "Terrain must be water only")
	assert(cf.Position.Y + size.Y / 2 < -13, "Ocean must stay below beaches")
	terrainWrites += 1
	terrainMaterials[material] = true
end
function methods:WriteVoxels(region, resolution, materials, occupancy)
	assert(resolution == 4)
	local size = (region.Max - region.Min) * (1 / resolution)
	assert(region.Min.X % 4 == 0 and region.Min.Y % 4 == 0 and region.Min.Z % 4 == 0)
	assert(#materials == size.X and #occupancy == size.X)
	for x = 1, size.X do
		assert(#materials[x] == size.Y and #occupancy[x] == size.Y)
		for y = 1, size.Y do
			assert(#materials[x][y] == size.Z and #occupancy[x][y] == size.Z)
			for z = 1, size.Z do
				local fill = occupancy[x][y][z]
				assert(fill >= 0 and fill <= 1 and fill == fill)
				terrainMaterials[materials[x][y][z]] = true
				terrainCells += 1
			end
		end
	end
	terrainWrites += 1
end
local calls, preloads, warnings = 0, 0, 0
local services = { Lighting = Instance.new("Lighting"), ServerStorage = Instance.new("ServerStorage") }
local tweens = {}
services.TweenService = {
	Create = function(_, target, info, goal)
		local tween = { Target = target, Info = info, Goal = goal }
		function tween:Play()
			self.Played = true
		end
		function tween:Cancel()
			self.Cancelled = true
		end
		table.insert(tweens, tween)
		return tween
	end,
}
services.Players = {
	GetPlayers = function()
		return {}
	end,
}
services.InsertService = {
	CreateMeshPartAsync = function()
		calls += 1
		error("Template builders must not request mesh assets")
	end,
}
services.ContentProvider = {
	PreloadAsync = function()
		preloads += 1
		error("Template builders must not preload over the network")
	end,
}
local storage = Instance.new("ReplicatedStorage")
storage.Shared = node("src/shared")
services.ReplicatedStorage = storage
local game = { ReplicatedStorage = storage }
function game:GetService(name)
	return services[name] or { Name = name }
end
local clock = 0
local tasks = {}
local task = {
	spawn = function(fn)
		local co = coroutine.create(fn)
		table.insert(tasks, co)
		assert(coroutine.resume(co))
	end,
	wait = function()
		clock += 0.1
	end,
}
local Random = {
	new = function(seed)
		return {
			NextNumber = function(_, minimum, maximum)
				seed = seed * 16807 % 2147483647
				return (minimum or 0) + seed / 2147483647 * ((maximum or 1) - (minimum or 0))
			end,
		}
	end,
}
local function sequence(...)
	return { ... }
end
local globals = {
	Vector3 = Vector3,
	Vector2 = { new = sequence },
	CFrame = CFrame,
	Color3 = Color3,
	Enum = Enum,
	Instance = Instance,
	game = game,
	workspace = workspace,
	task = task,
	Random = Random,
	os = {
		clock = function()
			return clock
		end,
	},
	warn = function()
		warnings += 1
	end,
	Region3 = {
		new = function(a, b)
			return { Min = a, Max = b }
		end,
	},
	UDim2 = { fromScale = sequence, fromOffset = sequence },
	TweenInfo = { new = sequence },
	ColorSequence = { new = sequence },
	NumberSequence = { new = sequence },
	NumberSequenceKeypoint = { new = sequence },
	NumberRange = { new = sequence },
}
local loadModule
loadModule = function(object)
	local path = object.Path
	if cache[path] then
		return cache[path]
	end
	local fn, err = loadstring(assert(sources[path], path), path)
	assert(fn, err)
	local env = setmetatable({ script = object, require = loadModule }, {
		__index = function(_, key)
			return globals[key] or getfenv()[key]
		end,
	})
	setfenv(fn, env)
	local value = fn()
	cache[path] = value
	return value
end
