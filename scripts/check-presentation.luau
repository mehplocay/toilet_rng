local Rules = require("../src/shared/PresentationRules")
local Settings = require("../src/shared/PresentationSettings")
local Config = require("../src/shared/Config/Presentation")
local Items = require("../src/shared/Config/Items")
local expected = { "Pop", "Pop", "Burst", "Sparkle", "Banner", "Banner", "Cinematic", "Cinematic" }
for i, rarity in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godly", "Secret" }) do
	assert(Rules.Tier(rarity, "Full") == expected[i])
	assert(Rules.Tier(rarity, "Reduced") == "Pop" and Rules.Tier(rarity, "Off") == "Toast")
end
assert(Rules.Tier("forged", "Full") == nil)
local queue = Rules.RevealQueue(Config.BigQueueCap)
assert(queue:Push({ Tier = "Cinematic", Id = 1 }) == "Play")
for i = 1, 1000 do
	assert(queue:Push({ Tier = "Pop" }) == "Toast")
end
assert(queue:Push({ Tier = "Banner", Id = 2 }) == "Queued")
assert(queue:Push({ Tier = "Cinematic", Id = 3 }) == "Queued")
for i = 1, 1000 do
	assert(queue:Push({ Tier = "Cinematic" }) == "Toast")
end
assert(#queue.Pending == 2 and queue:Next().Id == 2 and queue:Next().Id == 3 and queue:Next() == nil)
queue:Push({ Tier = "Cinematic" })
queue:Clear()
assert(not queue.Active and #queue.Pending == 0)
for _, pair in ipairs({
	{ 0, "0" },
	{ 999, "999" },
	{ 1000, "1K" },
	{ 1999, "1.9K" },
	{ 999999, "999.9K" },
	{ 1e6, "1M" },
	{ 1e9, "1B" },
	{ 1e12, "1T" },
	{ 1e15, "1Qa" },
	{ 9e15, "9Qa" },
	{ math.huge, "0" },
	{ 0 / 0, "0" },
	{ -1, "0" },
}) do
	assert(Rules.Abbreviate(pair[1]) == pair[2])
end
assert(Rules.Escape('<&>"') == "&lt;&amp;&gt;&quot;")
assert(Rules.Name("<font>bad\n") == "fontbad" and Rules.Name(string.rep("A", 1000)) == string.rep("A", 20))
assert(Settings.Sanitize(nil).RevealIntensity == "Full")
assert(Settings.Sanitize({ SkipAnimation = true }).RevealIntensity == "Reduced")
assert(Settings.Sanitize({ RevealIntensity = {}, ChatAnnouncements = "false" }).ChatAnnouncements)
for _, patch in ipairs({
	{},
	{ Coins = 999 },
	{ RevealIntensity = "full" },
	{ ChatAnnouncements = 1 },
	{ RevealIntensity = {} },
	{ RevealIntensity = "Full", MusicMuted = true },
}) do
	assert(not Settings.ValidRequest(patch))
end
assert(Settings.ValidRequest({ RevealIntensity = "Off", ChatAnnouncements = false }))
local now = 0
local announcements = Rules.Announcements(Config, function()
	return now
end)
local player = {}
assert(announcements:Push(player, Items[9], 1, {}))
assert(not announcements:Push(player, Items[9], 1, {}))
local entry = announcements:Take()
now = 100
assert(not announcements:Push(player, Items[9], 2, {}), "In-flight sender accepted again")
announcements:Finish(entry)
now += 4.99
assert(not announcements:Push(player, Items[9], 3, {}))
now += 0.01
assert(announcements:Push(player, Items[9], 4, {}))
for _ = 1, 100 do
	announcements:Push({}, Items[9], 1, {})
end
assert(#announcements.Pending == Config.AnnouncementCap)
announcements:Remove(player)
assert(not announcements.Seen[player] and #announcements.Pending == Config.AnnouncementCap - 1)
assert(
	Rules.Audience("Legendary") == "Friends"
		and Rules.Audience("Mythic") == "Server"
		and Rules.Audience("Epic") == "Friends"
)
local Event = require("../src/server/Services/EventService").new(require("../src/shared/Config/Events"), function()
	return 0
end, function() end, function() end)
local observations = 0
Event.Observe = function()
	observations += 1
end
for i = 1, 1000 do
	Event:Trigger(player, Items[9], i)
	Event:Trigger(player, Items[9], i)
end
assert(observations == 1000 and #Event.Pending == 16)
print(
	"Presentation rules passed: tiers, bounded queues, replay/rate limits, abbreviation boundaries, sanitization and event observer"
)
