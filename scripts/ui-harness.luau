-- Small Roblox UI double: executes production constructors/callbacks, not engine rendering.
local H = {
	Objects = {},
	Delays = {},
	Spawned = {},
	Calls = {},
	Writes = 0,
	Now = 100,
	Timers = {},
	Threads = {},
	Preloads = {},
	AudioTweens = {},
	Warnings = {},
}
local function signal()
	local s = { Listeners = {} }
	function s:Connect(fn)
		local entry = { Fn = fn, Connected = true }
		function entry:Disconnect()
			self.Connected = false
		end
		table.insert(self.Listeners, entry)
		return entry
	end
	function s:Once(fn)
		local connection
		connection = self:Connect(function(...)
			connection:Disconnect()
			fn(...)
		end)
		return connection
	end
	function s:Fire(...)
		for _, entry in ipairs(table.clone(self.Listeners)) do
			if entry.Connected then
				entry.Fn(...)
			end
		end
	end
	return s
end
local function enumGroup(name)
	return setmetatable({}, {
		__index = function(t, key)
			local value = name .. "." .. key
			rawset(t, key, value)
			return value
		end,
	})
end
local Enum = setmetatable({}, {
	__index = function(t, key)
		local value = enumGroup(key)
		rawset(t, key, value)
		return value
	end,
})
local Vector2 = {
	new = function(x, y)
		return { X = x or 0, Y = y or 0 }
	end,
}
local vector3MT = {}
local Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vector3MT)
end
function vector3MT.__add(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
function vector3MT.__sub(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
function vector3MT.__mul(a, b)
	return Vector3.new(a.X * b, a.Y * b, a.Z * b)
end
function vector3MT.__index(a, key)
	if key == "Magnitude" then
		return math.sqrt(a.X * a.X + a.Y * a.Y + a.Z * a.Z)
	elseif key == "Unit" then
		return a * (1 / a.Magnitude)
	end
end
local frameMT = {}
local CFrame = {}
function CFrame.new(x, y, z)
	return setmetatable({ Position = Vector3.new(x, y, z) }, frameMT)
end
function CFrame.Angles()
	return CFrame.new()
end
function CFrame.lookAt(position)
	local cf = CFrame.new()
	cf.Position = position
	return cf
end
function frameMT.__mul(a, b)
	return CFrame.lookAt(a.Position + b.Position)
end
local UDim = {
	new = function(s, o)
		return { Scale = s or 0, Offset = o or 0 }
	end,
}
local udimMT = {}
local UDim2 = {}
function UDim2.new(sx, ox, sy, oy)
	return setmetatable({ X = UDim.new(sx, ox), Y = UDim.new(sy, oy) }, udimMT)
end
function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end
function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end
function udimMT.__sub(a, b)
	return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
end
local Color3, colorMT = {}, {}
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, colorMT)
end
function Color3.fromRGB(r, g, b)
	return Color3.new(r / 255, g / 255, b / 255)
end
function colorMT.__index(_, key)
	if key == "Lerp" then
		return function(a, b, t)
			return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
		end
	end
	return nil
end
local sequence = {
	new = function(...)
		return { ... }
	end,
}
local guiClasses = {
	Frame = true,
	CanvasGroup = true,
	TextLabel = true,
	TextButton = true,
	TextBox = true,
	ImageLabel = true,
	ScrollingFrame = true,
}
local defaults = {
	Visible = true,
	Interactable = true,
	BackgroundTransparency = 0,
	TextTransparency = 0,
	Rotation = 0,
	ZIndex = 1,
	LayoutOrder = 0,
	IsLoaded = false,
	Text = "",
	Name = "Instance",
	AutomaticSize = "AutomaticSize.None",
	AnchorPoint = Vector2.new(),
	Position = UDim2.new(),
	Size = UDim2.new(),
}
local methods, Instance = {}, {}
function methods:GetGuiObjectsAtPosition()
	return H.HitObjects or {}
end
function methods:IsA(class)
	return self.ClassName == class
		or (class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "MeshPart"))
		or (class == "GuiObject" and guiClasses[self.ClassName])
		or (class == "GuiButton" and self.ClassName == "TextButton")
end
function methods:GetChildren()
	return table.clone(self._children)
end
function methods:GetDescendants()
	if self.ClassName == "Workspace" then
		H.WorkspaceReads = (H.WorkspaceReads or 0) + 1
	end
	local result = {}
	for _, child in ipairs(self._children) do
		table.insert(result, child)
		for _, desc in ipairs(child:GetDescendants()) do
			table.insert(result, desc)
		end
	end
	return result
end
function methods:FindFirstChild(name, recursive)
	for _, child in ipairs(self._children) do
		if child.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in ipairs(self._children) do
			local found = child:FindFirstChild(name, true)
			if found then
				return found
			end
		end
	end
	return nil
end
function methods:FindFirstChildWhichIsA(class)
	for _, child in ipairs(self._children) do
		if child:IsA(class) then
			return child
		end
	end
	return nil
end
function methods:GetPropertyChangedSignal(key)
	if not self._signals[key] then
		self._signals[key] = signal()
	end
	return self._signals[key]
end
function methods:GetAttribute(key)
	return self._attributes[key]
end
function methods:SetAttribute(key, value)
	if self._attributes[key] == value then
		return
	end
	self._attributes[key] = value
	self.AttributeChanged:Fire(key)
	self:GetAttributeChangedSignal(key):Fire()
end
function methods:GetAttributeChangedSignal(key)
	return self:GetPropertyChangedSignal("attr:" .. key)
end
function methods:Destroy()
	self.Destroying:Fire()
	for _, child in ipairs(self:GetChildren()) do
		child:Destroy()
	end
	self.Parent = nil
	self._dead = true
end
function methods:WaitForChild(name)
	return assert(self:FindFirstChild(name), name)
end
function methods:Play()
	self.IsPlaying = true
	self.Plays = (self.Plays or 0) + 1
end
function methods:Pause()
	self.IsPlaying = false
	self.Pauses = (self.Pauses or 0) + 1
end
function methods:Resume()
	self.IsPlaying = true
	self.Resumes = (self.Resumes or 0) + 1
end
local function baseSize(object)
	if object._fixed then
		return object._fixed
	end
	local parent = object.Parent
	local p = if parent then (parent._abs or baseSize(parent)) else Vector2.new(1280, 720)
	local size = object._props.Size or defaults.Size
	local w, h = p.X * size.X.Scale + size.X.Offset, p.Y * size.Y.Scale + size.Y.Offset
	return Vector2.new(w, h)
end
local mt = {
	__index = function(self, key)
		if methods[key] then
			return methods[key]
		end
		if key == "AbsoluteSize" then
			return self._abs or baseSize(self)
		end
		if key == "AbsolutePosition" then
			return self._pos or Vector2.new()
		end
		if self._props[key] ~= nil then
			return self._props[key]
		end
		local child = methods.FindFirstChild(self, key)
		if child then
			return child
		end
		if defaults[key] ~= nil then
			return defaults[key]
		end
		return nil
	end,
	__newindex = function(self, key, value)
		if key:sub(1, 1) == "_" then
			rawset(self, key, value)
			return
		end
		local old = self._props[key]
		if key == "Parent" then
			if old then
				local i = table.find(old._children, self)
				if i then
					table.remove(old._children, i)
				end
			end
			if value then
				table.insert(value._children, self)
			end
		end
		self._props[key] = value
		if key == "Parent" and value and value.ChildAdded then
			value.ChildAdded:Fire(self)
		end
		if old ~= value then
			H.Writes += 1
			if self._signals[key] then
				self._signals[key]:Fire()
			end
			if key == "Value" and self._props.Changed then
				self.Changed:Fire(value)
			end
		end
	end,
}
function Instance.new(class)
	local object = setmetatable(
		{ _props = { ClassName = class, Name = class }, _children = {}, _signals = {}, _attributes = {} },
		mt
	)
	for _, event in ipairs({
		"Activated",
		"InputBegan",
		"InputEnded",
		"MouseEnter",
		"MouseLeave",
		"SelectionLost",
		"Destroying",
		"Changed",
		"DescendantAdded",
		"ChildAdded",
		"AttributeChanged",
		"DescendantRemoving",
		"Ended",
		"Loaded",
	}) do
		object._props[event] = signal()
	end
	table.insert(H.Objects, object)
	return object
end
local services = {
	ProximityPromptService = { PromptTriggered = signal(), PromptShown = signal(), PromptHidden = signal() },
	RunService = { Heartbeat = signal(), RenderStepped = signal(), PreSimulation = signal() },
	UserInputService = {
		TouchEnabled = false,
		InputBegan = signal(),
		InputChanged = signal(),
		InputEnded = signal(),
		WindowFocusReleased = signal(),
	},
	GuiService = {},
	TweenService = {},
	ContentProvider = {},
	Players = {},
	ContextActionService = {},
}
function services.RunService:IsStudio()
	return true
end
H.RenderBindings = {}
function services.RunService:BindToRenderStep(name, _, fn)
	H.RenderBindings[name] = fn
end
function services.RunService:UnbindFromRenderStep(name)
	H.RenderBindings[name] = nil
end
function services.Players:GetPlayers()
	return H.PlayerList or { self.LocalPlayer }
end
function services.ContentProvider:PreloadAsync(values, callback)
	table.insert(H.Preloads, values)
	if H.HoldPreload then
		coroutine.yield()
	end
	for _, value in ipairs(values) do
		if type(value) ~= "string" then
			value.IsLoaded, value.TimeLength, value.TimePosition = not H.FailPreload, 120, 0
		end
		if callback then
			callback("test", if H.FailPreload then Enum.AssetFetchStatus.Failure else Enum.AssetFetchStatus.Success)
		end
	end
end
function services.TweenService:Create(object, info, props)
	local audioTween = object:IsA("Sound") or object:IsA("SoundGroup")
	if audioTween then
		table.insert(H.AudioTweens, { Object = object, Info = info, Props = props })
	end
	local completed, cancelled = signal(), false
	return {
		Completed = completed,
		Play = function()
			for key, value in pairs(props) do
				object[key] = value
			end
			if audioTween then
				table.insert(H.Timers, {
					At = H.Now + info[1],
					Fn = function()
						if not cancelled then
							completed:Fire()
						end
					end,
				})
			end
		end,
		Cancel = function()
			cancelled = true
		end,
		Pause = function() end,
		Destroy = function() end,
	}
end
function services.ContextActionService:BindAction() end
services.Players.LocalPlayer = Instance.new("Player")
services.Players.LocalPlayer.UserId = 7
services.Players.LocalPlayer.DisplayName = "TestPlayer"
local playerGui = Instance.new("PlayerGui")
playerGui.Parent = services.Players.LocalPlayer
local nodes, cache = {}, {}
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
for path in pairs(sources) do
	node(path)
end
local game = { ReplicatedStorage = { Shared = node("src/shared") }, Players = services.Players }
services.ReplicatedStorage = Instance.new("ReplicatedStorage")
function game:IsLoaded()
	return true
end
function game:GetService(name)
	if not services[name] then
		services[name] = Instance.new(name)
	end
	return services[name]
end
local workspace = Instance.new("Workspace")
workspace.CurrentCamera = Instance.new("Camera")
workspace.CurrentCamera.CFrame = CFrame.new()
workspace.CurrentCamera.FieldOfView = 70
services.Workspace = workspace
function workspace:GetServerTimeNow()
	return 1800000000
end
local task = {
	delay = function(seconds, fn)
		table.insert(H.Delays, fn)
		table.insert(H.Timers, { At = H.Now + seconds, Fn = fn })
	end,
	spawn = function(fn)
		table.insert(H.Spawned, fn)
	end,
	wait = function()
		coroutine.yield()
	end,
}
local globals = {
	warn = function(message)
		table.insert(H.Warnings, message)
	end,
	game = game,
	workspace = workspace,
	Enum = Enum,
	Instance = Instance,
	Color3 = Color3,
	Vector2 = Vector2,
	Vector3 = Vector3,
	CFrame = CFrame,
	UDim = UDim,
	UDim2 = UDim2,
	ColorSequence = sequence,
	ColorSequenceKeypoint = sequence,
	NumberSequence = sequence,
	NumberSequenceKeypoint = sequence,
	TweenInfo = sequence,
	os = {
		clock = function()
			return H.Now
		end,
		time = os.time,
	},
	task = task,
}
local loadModule
loadModule = function(module)
	local path = if type(module) == "string" then module else module.Path
	if cache[path] then
		return cache[path]
	end
	local fn = assert(loadstring(assert(sources[path], path), path))
	setfenv(
		fn,
		setmetatable(
			{ script = node(if path == "src/client/init.client" then "src/client" else path), require = loadModule },
			{
				__index = function(_, key)
					return globals[key] or getfenv()[key]
				end,
			}
		)
	)
	local result = fn()
	cache[path] = result
	return result
end
function H.Root(w, h)
	local root = Instance.new("Frame")
	root._fixed = Vector2.new(w, h)
	root.BackgroundTransparency = 1
	return root
end
function H.Remotes()
	local remotes = {}
	for _, name in ipairs({
		"Flush",
		"PresentationSettings",
		"DropAnnouncement",
		"State",
		"Result",
		"Sell",
		"BuyToilet",
		"BuyUpgrade",
		"Rebirth",
		"Display",
		"CollectIncome",
		"IncomePending",
		"Event",
		"ServerLuck",
		"Settings",
		"AutoFlush",
		"AnimationSkip",
		"PlotColor",
		"BuyPass",
		"BuyProduct",
		"ClaimVIP",
		"RefreshPasses",
		"DevGrant",
		"TutorialDone",
		"ClaimReward",
		"ClaimIndexReward",
	}) do
		remotes[name] = {
			OnClientEvent = signal(),
			FireServer = function(_, ...)
				table.insert(H.Calls, { Name = name, Args = { ... }, Count = select("#", ...) })
			end,
		}
	end
	return remotes
end
local function childrenForLayout(object)
	local result = {}
	for _, child in ipairs(object._children) do
		if child:IsA("GuiObject") and child.Visible then
			table.insert(result, child)
		end
	end
	table.sort(result, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return result
end
function H.Layout(root)
	local function visit(object, px, py, pw, ph, forced)
		if not object:IsA("GuiObject") then
			return
		end
		local size, position, anchor = object.Size, object.Position, object.AnchorPoint
		local w, h = pw * size.X.Scale + size.X.Offset, ph * size.Y.Scale + size.Y.Offset
		if object._fixed then
			w, h = object._fixed.X, object._fixed.Y
		end
		if forced then
			w, h = forced.W, forced.H
		end
		local aspect = object:FindFirstChildWhichIsA("UIAspectRatioConstraint")
		if aspect then
			w = math.min(w, h * aspect.AspectRatio)
			h = w / aspect.AspectRatio
		end
		local layout = object:FindFirstChildWhichIsA("UIGridLayout") or object:FindFirstChildWhichIsA("UIListLayout")
		local list, padX, padY = childrenForLayout(object), 0, 0
		local padding = object:FindFirstChildWhichIsA("UIPadding")
		if padding then
			padX, padY = padding.PaddingLeft.Offset, padding.PaddingTop.Offset
		end
		local placements, autoH = {}, 0
		if layout and layout.ClassName == "UIGridLayout" then
			local cw, ch = layout.CellSize.X.Offset, layout.CellSize.Y.Offset
			local gapX, gapY = layout.CellPadding.X.Offset, layout.CellPadding.Y.Offset
			local cols = math.max(1, math.floor((w - padX - 10 + gapX) / (cw + gapX)))
			for i, child in ipairs(list) do
				placements[child] = {
					X = padX + (i - 1) % cols * (cw + gapX),
					Y = padY + math.floor((i - 1) / cols) * (ch + gapY),
					W = cw,
					H = ch,
				}
			end
			autoH = math.ceil(#list / cols) * (ch + gapY) - gapY + padY + 10
		elseif layout then
			local offset = 0
			for _, child in ipairs(list) do
				local cw, ch =
					w * child.Size.X.Scale + child.Size.X.Offset, h * child.Size.Y.Scale + child.Size.Y.Offset
				if child.AutomaticSize == Enum.AutomaticSize.Y and child._abs then
					ch = child._abs.Y
				end
				local horizontal = layout.FillDirection == Enum.FillDirection.Horizontal
				placements[child] = {
					X = padX + (if horizontal then offset else 0),
					Y = padY + (if horizontal then 0 else offset),
					W = cw,
					H = ch,
				}
				offset += (if horizontal then cw else ch) + (layout.Padding and layout.Padding.Offset or 0)
			end
			autoH = offset + padY + 10
		end
		if object.AutomaticSize == Enum.AutomaticSize.Y and layout then
			h = math.max(0, autoH)
		end
		local x, y =
			px + pw * position.X.Scale + position.X.Offset - w * anchor.X,
			py + ph * position.Y.Scale + position.Y.Offset - h * anchor.Y
		if forced then
			x, y = px + forced.X, py + forced.Y
		end
		local changed = not object._abs or object._abs.X ~= w or object._abs.Y ~= h
		object._abs, object._pos = Vector2.new(w, h), Vector2.new(x, y)
		if changed and object._signals.AbsoluteSize then
			object._signals.AbsoluteSize:Fire()
		end
		for _, child in ipairs(object._children) do
			local scroll = if object.ClassName == "ScrollingFrame" then object.CanvasPosition else nil
			visit(
				child,
				x - (if scroll then scroll.X else 0),
				y - (if scroll then scroll.Y else 0),
				w,
				h,
				placements[child]
			)
		end
	end
	for _ = 1, 5 do
		visit(root, 0, 0, root._fixed.X, root._fixed.Y)
	end
end
local function json(value)
	if type(value) == "string" then
		return '"'
			.. value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", ""):gsub("\t", "\\t")
			.. '"'
	end
	if type(value) == "number" or type(value) == "boolean" then
		return tostring(value)
	end
	if type(value) ~= "table" then
		return "null"
	end
	local parts = {}
	if #value > 0 then
		for _, item in ipairs(value) do
			table.insert(parts, json(item))
		end
		return "[" .. table.concat(parts, ",") .. "]"
	end
	for key, item in pairs(value) do
		table.insert(parts, json(key) .. ":" .. json(item))
	end
	return "{" .. table.concat(parts, ",") .. "}"
end
function H.Snapshot(root, name)
	-- Offline previews use supplied local PNGs, never evidence of Roblox permission/loading.
	if previewIcons then
		for _, object in ipairs(root:GetDescendants()) do
			if object.ClassName == "ImageLabel" then
				for _, icon in ipairs(expectedIcons) do
					if object.Image == icon.Image then
						object.IsLoaded = true
						break
					end
				end
			end
		end
	end
	H.Layout(root)
	local function serialize(object)
		if not object:IsA("GuiObject") or not object.Visible then
			return nil
		end
		local p, a = object.AbsolutePosition, object.AbsoluteSize
		local children = {}
		local ordered = object:GetChildren()
		table.sort(ordered, function(x, y)
			return x.ZIndex < y.ZIndex
		end)
		for _, child in ipairs(ordered) do
			local data = serialize(child)
			if data then
				table.insert(children, data)
			end
		end
		local stroke = object:FindFirstChildWhichIsA("UIStroke")
		local corner = object:FindFirstChildWhichIsA("UICorner")
		local gradient = object:FindFirstChildWhichIsA("UIGradient")
		local constraint = object:FindFirstChildWhichIsA("UITextSizeConstraint")
		local previewImage = object.Image
		for _, icon in ipairs(expectedIcons) do
			if previewImage and previewImage == icon.Image then
				previewImage = icon.Id
				break
			end
		end
		return {
			name = object.Name,
			class = object.ClassName,
			x = p.X,
			y = p.Y,
			w = a.X,
			h = a.Y,
			color = object.BackgroundColor3,
			alpha = 1 - object.BackgroundTransparency,
			rotation = object.Rotation,
			text = object.Text,
			image = previewImage,
			textAlpha = 1 - object.TextTransparency,
			textColor = object.TextColor3,
			font = object.Font,
			maxFont = if constraint then constraint.MaxTextSize else object.TextSize,
			left = object.TextXAlignment == Enum.TextXAlignment.Left,
			stroke = if stroke
				then {
					color = stroke.Color,
					width = stroke.Thickness,
					alpha = 1 - (stroke.Transparency or 0),
					mode = stroke.ApplyStrokeMode,
				}
				else nil,
			corner = if corner then corner.CornerRadius.Offset + math.min(a.X, a.Y) * corner.CornerRadius.Scale else 0,
			gradient = if gradient then gradient.Color else nil,
			gradientRotation = if gradient then gradient.Rotation else nil,
			clip = object.ClassName == "ScrollingFrame" or object.ClipsDescendants == true,
			children = children,
		}
	end
	print("UI_SNAPSHOT " .. name .. " " .. json(serialize(root)))
end
H.Load, H.Services, H.Signal, H.Instance, H.UDim2, H.Color3 = loadModule, services, signal, Instance, UDim2, Color3
function H.StartTasks()
	local pending = H.Spawned
	H.Spawned = {}
	for _, fn in ipairs(pending) do
		local thread = coroutine.create(fn)
		local ok, err = coroutine.resume(thread)
		assert(ok, err)
		if coroutine.status(thread) ~= "dead" then
			table.insert(H.Threads, thread)
		end
	end
end
function H.Advance(seconds)
	H.Now += seconds
	local pending = H.Timers
	H.Timers = {}
	for _, timer in ipairs(pending) do
		if timer.At <= H.Now then
			timer.Fn()
		else
			table.insert(H.Timers, timer)
		end
	end
	services.RunService.Heartbeat:Fire(seconds)
end
function H.ResumeTasks()
	local pending = H.Threads
	H.Threads = {}
	for _, thread in ipairs(pending) do
		local ok, err = coroutine.resume(thread)
		assert(ok, err)
		if coroutine.status(thread) ~= "dead" then
			table.insert(H.Threads, thread)
		end
	end
end
function H.BootClient(remotes)
	node("src/client").Destroying = signal()
	-- World animation/guidance and spatial input are outside this UI-only double.
	for _, name in ipairs({ "VisualIdle", "PlotGuidance", "VIPChat" }) do
		cache["src/client/" .. name] = { Start = function() end }
	end
	cache["src/client/UI/FlushPrompt"] = {
		Start = function()
			return {
				Near = function()
					return true
				end,
			}
		end,
	}
	cache["src/shared/Visuals/Primitives"] = {
		Particles = function()
			return { Emit = function() end }
		end,
	}
	cache["src/shared/Visuals/Items"] = {
		Build = function(parent, _, item)
			H.PreviewBuilds = (H.PreviewBuilds or 0) + 1
			local model = Instance.new("Model")
			model.Name, model.Parent = item.Id, parent
			function model:GetBoundingBox()
				return CFrame.new(), Vector3.new(4, 5, 3)
			end
			function model:GetPivot()
				return CFrame.new()
			end
			function model:PivotTo(cf)
				self.Pivot = cf
			end
			return model
		end,
	}
	game.ReplicatedStorage.WaitForChild = function(_, name)
		assert(name == "Remotes")
		return {
			WaitForChild = function(_, key)
				return assert(remotes[key], key)
			end,
		}
	end
	loadModule("src/client/init.client")
	local root = services.Players.LocalPlayer.PlayerGui.ToiletUI.SafeArea
	root._fixed = Vector2.new(1280, 684)
	root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	return root
end
H.Workspace = workspace
