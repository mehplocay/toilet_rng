local Chooser = require("../src/shared/PlotChooser")

assert(Chooser.Choose({}, {}) == nil)
assert(Chooser.Choose({ false, false, false }, {}) == 1)
assert(Chooser.Choose({ 10, false, false, false, false }, { [10] = true }) == 2)
assert(Chooser.Choose({ 10, 20, false, false, false }, { [10] = true }) == 5)
assert(Chooser.Choose({ false, false, false, false, 10 }, { [10] = true }) == 1)
assert(Chooser.Choose({ 10, 20, false, 30, 40 }, { [10] = true, [30] = true }) == 3)
assert(Chooser.Choose({ 10, 20, false, 30, 40 }, { [10] = true }) == 3)
assert(Chooser.Choose({ 10, 20, 30 }, { [20] = true }) == nil)
assert(Chooser.Choose({ false }, {}) == 1)
assert(Chooser.Choose({ 10 }, { [10] = true }) == nil)
-- Exhaust all ten-plot occupancy patterns: never pick an occupied plot, and
-- always prefer adjacency whenever a friend's neighbor is free.
for mask = 0, 1023 do
	local owners, friends = {}, {}
	for index = 1, 10 do
		owners[index] = if bit32.band(mask, bit32.lshift(1, index - 1)) ~= 0 then index else false
	end
	for friend = 1, 10 do
		friends = { [friend] = true }
		local chosen = Chooser.Choose(owners, friends)
		if chosen then
			assert(owners[chosen] == false)
		else
			assert(mask == 1023)
		end
		local nextIndex, previousIndex = friend % 10 + 1, (friend - 2) % 10 + 1
		if owners[friend] and (owners[nextIndex] == false or owners[previousIndex] == false) then
			assert(chosen == nextIndex or chosen == previousIndex)
		end
	end
end
assert(Chooser.ShowGuide(21, 72, 20, 72))
assert(not Chooser.ShowGuide(20, 72, 20, 72))
assert(not Chooser.ShowGuide(80, 73, 20, 72))
assert(not Chooser.ShowGuide(0, 0, 20, 72))
print("Spawn checks passed: ring adjacency, fallback, full server, 10,240 occupancy/friend cases, guide boundaries")
