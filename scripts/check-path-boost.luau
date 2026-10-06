local R = require("../src/shared/PathBoostRules")
local C = require("../src/shared/Config/PathBoost")
local rectangle = { X = 10, Z = -20, Y = 0, Width = 24, Depth = 48, Cos = 1, Sin = 0 }
assert(R.InRectangle(22, 3, 4, rectangle, 7))
assert(not R.InRectangle(22.001, 3, 4, rectangle, 7))
for _, coordinate in ipairs({ 0 / 0, math.huge, -math.huge }) do
	assert(not R.InRectangle(coordinate, 3, 0, rectangle, 7))
	assert(not R.InRectangle(10, coordinate, -20, rectangle, 7))
end
assert(not R.InRectangle(10, 8, -20, rectangle, 7))
assert(not R.InRectangle(10, -2, -20, rectangle, 7))
rectangle.Cos, rectangle.Sin = 0, 1
assert(R.InRectangle(34, 3, -8, rectangle, 7))
assert(not R.InRectangle(35, 3, -8, rectangle, 7))
local state = {}
local target, changed = R.Plan(state, 16, R.Multiplier(true, 0, 1, 1, C), nil, true, C)
assert(target == 48 and changed)
for _ = 1, 1000 do
	target, changed = R.Plan(state, 16, R.Multiplier(true, 0, 1, 1, C), nil, true, C)
	assert(target == 48 and not changed, "Repeated polls accumulated speed or restarted easing")
end
assert(R.Multiplier(true, 1, 1, 1, C) == 4)
assert(R.Multiplier(true, 0, 4, 1, C) == 4)
assert(R.Multiplier(true, 1, 4, 1, C) == 5)
assert(R.Multiplier(true, 1, 4, 1e300, C) == 5)
assert(R.Multiplier(false, 1, 4, 1, C) == 1)
assert(R.Multiplier(true, 0, 1, 0 / 0, C) == 3)
assert(R.Plan(state, 16, 1, nil, true, C) == 16)
assert(R.Plan(state, 16, 5, 120, true, C) == 120)
assert(R.Plan(state, 16, 5, 0, true, C) == 0)
assert(R.Plan(state, 16, 5, nil, false, C) == 16)
assert(R.Plan({}, 20, 1, nil, true, C) == 20)
assert(R.Plan({}, 0, 1, nil, true, C) == 0)
assert(R.Multiplier(false, 1, 4, 2, C) == 2)
local vector = function(x, y, z)
	return { X = x, Y = y, Z = z }
end
local layout = {
	FloorY = 0,
	PlotRise = 0.35,
	Pieces = { { Asset = "HubPathStrip", Position = vector(0, -1, 0), Size = vector(24, 1, 48) } },
	Plots = { { X = 100, Z = 50, Yaw = 90 } },
	PlotPieces = { { Asset = "PlotPathStraight", Position = vector(0, -1, -30), Size = vector(12, 1, 6) } },
}
local zones = R.Zones(layout, {}, C)
assert(#zones == 2 and math.abs(zones[2].X - 70) < 1e-9 and zones[2].Z == 50)
assert(R.Find(zones, 70, 3, 50, 7) == zones[2])
assert(not R.Find(zones, 76, 3, 50, 7))
print(
	"Path boost math passed: boundaries, rotated plots, height/NaN rejection, idempotence, VIP/product stacking, cap, admin, death and base restoration"
)
