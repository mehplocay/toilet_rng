local Spawn = require("../src/server/World/PlotSpawn")
local function signal()
	local handlers = {}
	local s = {}
	function s:Connect(fn)
		local link = { Active = true }
		function link:Disconnect()
			self.Active = false
		end
		table.insert(handlers, { Link = link, Fn = fn })
		return link
	end
	function s:Once(fn)
		local link
		link = self:Connect(function(...)
			link:Disconnect()
			fn(...)
		end)
		return link
	end
	function s:Fire(...)
		for _, h in ipairs(handlers) do
			if h.Link.Active then
				h.Fn(...)
			end
		end
	end
	return s
end
local function scenario(failures, existing)
	local queue, delayed = {}, {}
	local players = { RespawnTime = 5 }
	local scheduler = {
		spawn = function(fn)
			table.insert(queue, coroutine.create(fn))
		end,
		delay = function(_, fn)
			table.insert(delayed, function()
				table.insert(queue, coroutine.create(fn))
			end)
		end,
		wait = function()
			coroutine.yield()
		end,
	}
	local warnings = {}
	local service = Spawn.new(players, scheduler, function(message)
		table.insert(warnings, message)
	end)
	local destination = { Position = 100 }
	local plot = { Spawn = {}, SpawnCFrame = destination }
	local player = { Parent = players, CharacterAdded = signal(), Loads = 0 }
	local function character()
		local root = { AssemblyLinearVelocity = 15, AssemblyAngularVelocity = 2 }
		root.Position = setmetatable({}, {
			__sub = function()
				return { Magnitude = root.Distance or 100 }
			end,
		})
		local humanoid = { Health = 100, Died = signal(), MoveDirection = { Magnitude = 0 } }
		local char = { Parent = true, Root = root, Humanoid = humanoid, Pivots = 0 }
		function char:WaitForChild(name)
			return if name == "Humanoid" then humanoid else root
		end
		function char:FindFirstChildOfClass()
			return humanoid
		end
		function char:PivotTo(cf)
			assert(cf == destination)
			self.Pivots += 1
			root.Distance = 0
		end
		return char
	end
	function player:LoadCharacterAsync()
		assert(self.RespawnLocation == plot.Spawn, "Character loaded before plot spawn assignment")
		self.Loads += 1
		if self.Loads <= failures then
			error("Temporary avatar failure")
		end
		self.Character = character()
		self.CharacterAdded:Fire(self.Character)
		coroutine.yield() -- Engine placement happens AFTER CharacterAdded.
		self.Character.Root.Distance = 500
	end
	function player:Kick()
		self.Kicked = true
	end
	if existing then
		player.Character = character()
	end
	local function tick()
		for _, thread in ipairs(table.clone(queue)) do
			if coroutine.status(thread) ~= "dead" then
				local ok, problem = coroutine.resume(thread)
				assert(ok, problem)
			end
		end
	end
	service:Ready(player)
	assert(player.Loads == 0, "Missing assignment loaded a character")
	service:Register(player, plot)
	service:Register(player, plot)
	assert(player.RespawnLocation == plot.Spawn and player.Loads == 0)
	service:Ready(player)
	service:Ready(player)
	return service, player, plot, tick, delayed, warnings
end
for _, existing in ipairs({ false, true }) do
	local service, player, _, tick, delayed = scenario(1, existing)
	for _ = 1, 12 do
		tick()
	end
	assert(player.Loads == 2 and not player.Kicked and player.Character.Root.Distance == 0)
	local first = player.Character
	first.Humanoid.Health = 0
	first.Humanoid.Died:Fire()
	assert(#delayed == 1)
	delayed[1]()
	for _ = 1, 12 do
		tick()
	end
	assert(player.Loads == 3 and player.Character ~= first and player.Character.Root.Distance == 0)
	-- A finished recovery window must never drag a walking player back home.
	player.Character.Root.Distance = 70
	for _ = 1, 5 do
		tick()
	end
	assert(player.Character.Root.Distance == 70)
	service:Remove(player)
	player.Character.Humanoid.Died:Fire()
	assert(#delayed == 1 and service.States[player] == nil)
end
do
	local service, player, _, tick = scenario(0, false)
	tick() -- in-flight engine load
	service:Remove(player)
	player.Parent = nil
	for _ = 1, 8 do
		tick()
	end
	assert(not player.Kicked and player.Character.Pivots == 0, "Departure mutated an obsolete character")
end
do
	local _, player, _, tick, _, warnings = scenario(10, false)
	for _ = 1, 8 do
		tick()
	end
	assert(player.Loads == 3 and player.Kicked and #warnings == 1)
end
do
	local _, player, _, tick = scenario(0, false)
	tick()
	tick()
	tick()
	player.Character.Root.Distance = 500 -- Late engine/streaming relocation after load returned.
	for _ = 1, 6 do
		tick()
	end
	assert(player.Character.Root.Distance == 0 and player.Character.Root.AssemblyLinearVelocity == 0)
end
print(
	"Spawn lifecycle checks passed: early/existing player, assignment before load, idempotent readiness, retry, late placement, respawn, departure, bounded recovery"
)
