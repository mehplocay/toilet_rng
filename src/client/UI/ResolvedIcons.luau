local storage = game:GetService("ReplicatedStorage")
local Assets = require(game.ReplicatedStorage.Shared.Config.Assets)
local Content = require(game.ReplicatedStorage.Shared.IconContent)
local Icons = {}
local folder, started, preloading = nil, false, false
local listeners, queued, seen = {}, {}, {}
function Icons.Get(value)
	local id = Content.Id(value)
	if not id then
		return nil
	end
	return Content.Override(Assets, id) or (folder and Content.Image(folder:GetAttribute("Image_" .. id)))
end
local function preload(image)
	if seen[image] then
		return
	end
	seen[image], queued[image] = true, true
	if preloading then
		return
	end
	preloading = true
	task.spawn(function()
		while next(queued) do
			local labels = {}
			for id in pairs(queued) do
				local label = Instance.new("ImageLabel")
				label.Image = id
				table.insert(labels, label)
			end
			queued = {}
			local ok, problem = pcall(function()
				game:GetService("ContentProvider"):PreloadAsync(labels, function(id, status)
					if status ~= Enum.AssetFetchStatus.Success then
						warn("Icon preload failed: " .. id .. "; keeping fallback")
					end
				end)
			end)
			for _, label in ipairs(labels) do
				label:Destroy()
			end
			if not ok then
				warn("Icon preload unavailable: " .. tostring(problem))
			end
		end
		preloading = false
	end)
end
local function refresh()
	for _, id in ipairs(Content.Ids(Assets)) do
		local image = Icons.Get(id)
		if image then
			preload(image)
		end
	end
	for callback, value in pairs(listeners) do
		callback(Icons.Get(value))
	end
end
local function attach(candidate)
	if folder or candidate.Name ~= "ResolvedIcons" or not candidate:IsA("Folder") then
		return
	end
	folder = candidate
	folder.AttributeChanged:Connect(refresh)
	refresh()
end
function Icons.Start()
	if started then
		return
	end
	started = true
	-- Subscribe before scanning so late replication cannot be missed.
	storage.ChildAdded:Connect(attach)
	local existing = storage:FindFirstChild("ResolvedIcons")
	if existing then
		attach(existing)
	end
	task.spawn(function()
		local deadline = os.clock() + 2
		while (not folder or not folder:GetAttribute("Complete")) and os.clock() < deadline do
			task.wait(0.05)
		end
		refresh() -- Short startup wait; late resolutions still update/preload through the listener.
	end)
end
function Icons.Observe(value, callback)
	Icons.Start()
	listeners[callback] = value
	callback(Icons.Get(value))
	return function()
		listeners[callback] = nil
	end
end
return Icons
