-- Geometry and speed plans are pure math, shared with local path feedback.
local Rules = {}
local function finite(x)
	return type(x) == "number" and x == x and math.abs(x) < math.huge
end
function Rules.InRectangle(x, y, z, rectangle, height)
	if not finite(x) or not finite(y) or not finite(z) then
		return false
	end
	local dx, dz = x - rectangle.X, z - rectangle.Z
	local lx = rectangle.Cos * dx - rectangle.Sin * dz
	local lz = rectangle.Sin * dx + rectangle.Cos * dz
	return math.abs(lx) <= rectangle.Width / 2
		and math.abs(lz) <= rectangle.Depth / 2
		and y >= rectangle.Y - 1
		and y <= rectangle.Y + height
end
function Rules.Zones(layout, meshes, config)
	local zones = {}
	local function add(entry, origin)
		if not config.Assets[entry.Asset] then
			return
		end
		local size = entry.Size or meshes[entry.Asset].Size
		local scale = if entry.Size then 1 else entry.Scale or 1
		local yaw = math.rad(origin.Yaw or 0)
		local c, s = math.cos(yaw), math.sin(yaw)
		local pos = entry.Position
		local rotation = yaw + math.rad(entry.Yaw or 0)
		table.insert(zones, {
			X = origin.X + c * pos.X + s * pos.Z,
			Z = origin.Z - s * pos.X + c * pos.Z,
			Y = origin.Y + pos.Y + size.Y * scale,
			Width = size.X * scale,
			Depth = size.Z * scale,
			Cos = math.cos(rotation),
			Sin = math.sin(rotation),
		})
	end
	for _, entry in ipairs(layout.Pieces) do
		add(entry, { X = 0, Y = layout.FloorY, Z = 0 })
	end
	for _, plot in ipairs(layout.Plots) do
		for _, entry in ipairs(layout.PlotPieces) do
			add(entry, { X = plot.X, Z = plot.Z, Y = layout.FloorY + layout.PlotRise, Yaw = plot.Yaw })
		end
	end
	return zones
end
function Rules.Find(zones, x, y, z, height)
	for _, zone in ipairs(zones) do
		if Rules.InRectangle(x, y, z, zone, height) then
			return zone
		end
	end
	return nil
end
function Rules.Multiplier(onPath, vipStep, paidPath, other, config)
	local path = if onPath then math.max(config.Multiplier, paidPath or 1) + (vipStep or 0) else 1
	local factor = if finite(other) and other >= 1 then math.min(other, config.TotalMultiplierCap) else 1
	return math.min(config.TotalMultiplierCap, path * factor)
end
function Rules.Plan(state, base, multiplier, override, alive, config)
	if not finite(base) or base < 0 then
		base = 16
	end
	local admin = finite(override) and override >= 0 and override <= 1000
	local target = if not alive then base elseif admin then override else base * multiplier
	local changed = state.Target ~= target
	state.Target, state.Multiplier = target, if alive and not admin then multiplier else 1
	return target, changed
end
return Rules
