local Resolver = require("../src/server/Services/IconResolver")
local Content = require("../src/shared/IconContent")
local assets = require("../src/shared/Config/Assets")
assert(#Content.Ids(assets) == 81)
assert(Content.Id("https://www.roblox.com/asset/?id=123") == "123")
for _, value in ipairs({ 0, -1, math.huge, 0 / 0, "", "rbxassetid://0", "https://example.com/image.png" }) do
	assert(Content.Image(value) == nil)
end
local config = { Icons = {}, ItemIcons = {}, ToiletIcons = {}, IconImages = { ["1"] = 101 } }
for i = 1, 12 do
	config.Icons[tostring(i)] = i
end
config.ItemIcons.Alias = 1
local threads, published, destroyed, warnings, requested = {}, {}, {}, {}, {}
local active, peak, complete = 0, 0, false
local function load(id)
	assert(id ~= 1, "Override performed a network lookup")
	assert(not requested[id], "Duplicate wrapper request")
	requested[id] = true
	active += 1
	peak = math.max(peak, active)
	coroutine.yield()
	active -= 1
	if id == 4 then
		error("Permission denied")
	end
	return {
		FindFirstChildWhichIsA = function(_, class, recursive)
			assert(class == "Decal" and recursive)
			return if id == 5
				then nil
				else { Texture = if id == 6 then "" else "https://www.roblox.com/asset/?id=" .. (id + 100) }
		end,
		Destroy = function()
			destroyed[id] = true
		end,
	}
end
Resolver.Run(config, Content, load, function(id, image)
	published[id] = image
end, function(fn)
	local thread = coroutine.create(fn)
	table.insert(threads, thread)
	assert(coroutine.resume(thread))
end, function(message)
	table.insert(warnings, message)
end, function()
	complete = true
end)
assert(peak == 4 and not complete and published["1"] == "rbxassetid://101")
-- Simulate a stuck worker: other workers still drain the queue.
for _ = 1, 12 do
	for index, thread in ipairs(threads) do
		if index ~= 1 and coroutine.status(thread) ~= "dead" then
			assert(coroutine.resume(thread))
		end
	end
end
assert(not complete and active == 1)
while coroutine.status(threads[1]) ~= "dead" do
	assert(coroutine.resume(threads[1]))
end
assert(complete and active == 0 and #warnings == 3)
for id = 2, 12 do
	assert(requested[id])
	assert(id == 4 or destroyed[id], "Loaded container leaked")
	assert((published[tostring(id)] ~= nil) == (id ~= 4 and id ~= 5 and id ~= 6))
end
print(
	"Icon resolver checks passed: 81 uploads, override precedence, alias deduplication, four-worker limit, stalled worker, permissions, invalid Decals, cleanup"
)
