-- Reuse the UI engine boundary to execute production client modules in the audit runner.
local function connected(event)
	local count = 0
	for _, entry in ipairs(event.Listeners) do
		if entry.Connected then
			count += 1
		end
	end
	return count
end

test("audit2: completed UI tweens release their targets and cancellation cannot clear a replacement", function()
	local C = H.Load("src/client/UI/Components")
	local object = H.Instance.new("Frame")
	local first = C.Tween(object, 1, { Rotation = 1 })
	first.Completed:Fire()
	assert(connected(object.Destroying) == 0, "Completed tween kept a destruction listener")
	local canceled = 0
	first.Cancel = function()
		canceled += 1
	end
	local second = C.Tween(object, 1, { Rotation = 2 })
	assert(canceled == 0, "Completed tween retained in the target registry")
	second.Cancel = function()
		canceled += 1
	end
	local third = C.Tween(object, 1, { Rotation = 3 })
	assert(canceled == 1)
	second.Completed:Fire() -- Deferred cancellation of the previous tween.
	third.Cancel = function()
		canceled += 1
	end
	object:Destroy()
	assert(canceled == 2, "Destroyed target kept its replacement tween")
	third.Completed:Fire()
	assert(connected(object.Destroying) == 0)
end)

test("audit2: repeated stream-out releases idle effects without Destroying and stream-in registers once", function()
	local idle = H.Load("src/client/VisualIdle")
	local world = H.Services.Workspace
	idle.Start()
	local loop = coroutine.create(H.Spawned[#H.Spawned])
	local object = H.Instance.new("Highlight")
	object.FindFirstAncestor = function()
		return nil
	end
	object:SetAttribute("VisualIdle", true)
	for _ = 1, 100 do
		object.Parent = world
		world.DescendantAdded:Fire(object)
		world.DescendantAdded:Fire(object)
		assert(connected(object.Destroying) == 1)
		world.DescendantRemoving:Fire(object)
		object.Parent = nil -- Streaming does not call Destroy.
		assert(connected(object.Destroying) == 0, "Streamed replica still retained by idle registry")
		local ok, err = coroutine.resume(loop)
		assert(ok, err)
	end
	object:Destroy()
	local tweenService = H.Services.TweenService
	local create, canceled, destroyed = tweenService.Create, 0, 0
	tweenService.Create = function(...)
		local tween = create(...)
		tween.Cancel = function()
			canceled += 1
		end
		tween.Destroy = function()
			destroyed += 1
		end
		return tween
	end
	local part = H.Instance.new("Part")
	part.CFrame = CFrame.new()
	part:SetAttribute("IdleBob", 1)
	part.Parent = world
	world.DescendantAdded:Fire(part)
	world.DescendantRemoving:Fire(part)
	part.Parent = nil
	assert(canceled == 1 and destroyed == 1 and connected(part.Destroying) == 0)
	tweenService.Create = create
end)

test("audit2: far map billboards skip projection while nearby labels retain HUD overlap checks", function()
	local world = H.Services.Workspace
	local root = H.Root(1280, 720)
	local anchor = H.Instance.new("Part")
	local distance = 200
	anchor.Position = setmetatable({}, {
		__sub = function()
			return { Magnitude = distance }
		end,
		__add = function(a)
			return a
		end,
	})
	local gui = H.Instance.new("BillboardGui")
	gui.Size, gui.MaxDistance, gui.Parent = H.UDim2.fromOffset(50, 20), 65, anchor
	gui:SetAttribute("AvoidHUD", true)
	local projections = 0
	world.CurrentCamera.WorldToScreenPoint = function()
		projections += 1
		return { X = 500, Y = 400, Z = 10 }
	end
	H.Load("src/client/WorldLabels").Start(root)
	world.DescendantAdded:Fire(gui)
	H.Services.RunService.RenderStepped:Fire(1 / 60)
	assert(projections == 0 and not gui.Enabled, "Far billboard still projects every frame")
	distance = 10
	H.Services.RunService.RenderStepped:Fire(1 / 60)
	assert(projections == 2 and gui.Enabled)
	root:Destroy()
	anchor:Destroy()
end)

test("audit2: chat escapes catalog markup, strips identity control characters and respects opt-out", function()
	local remote = { OnClientEvent = H.Signal() }
	local service = H.Load("src/client/Presentation/ChatAnnouncements").Start(remote)
	local chat = H.Services.TextChatService
	local window = H.Instance.new("ChatWindowConfiguration")
	window.Parent = chat
	local channels = H.Instance.new("Folder")
	channels.Name, channels.Parent = "TextChannels", chat
	local channel = H.Instance.new("TextChannel")
	channel.Name, channel.Parent = "RBXGeneral", channels
	local messages = {}
	channel.DisplaySystemMessage = function(_, text)
		table.insert(messages, text)
	end
	local items = H.Load("src/shared/Config/Items")
	local old = items[6].Name
	items[6].Name = '<b>Gold & "Poop"</b>'
	remote.OnClientEvent:Fire({ ItemId = items[6].Id, PlayerName = "<i>Admin</i>\n&\255" })
	items[6].Name = old
	H.Advance(2.1)
	assert(#messages == 1 and not messages[1]:find("<b>", 1, true) and not messages[1]:find("<i>", 1, true))
	assert(messages[1]:find("&lt;b&gt;Gold &amp; &quot;Poop&quot;&lt;/b&gt;", 1, true))
	assert(not messages[1]:find("\n", 1, true))
	service.Enabled = false
	remote.OnClientEvent:Fire({ ItemId = items[6].Id, PlayerName = "Tester" })
	assert(#messages == 1)
	service:Destroy()
	channels:Destroy()
	window:Destroy()
end)
