-- A shared client-only lease prevents a local reveal restoring an active server sky.
local Lighting = game:GetService("Lighting")
local C = require(script.Parent.Parent.UI.Components)
local Sky = {}
local leases, original, sky, ownedSky, tween = {}, nil, nil, false, nil
local function refresh()
	if tween then
		tween:Cancel()
		tween = nil
	end
	local active = leases[#leases]
	if active then
		tween = C.Tween(Lighting, 0.45, { ClockTime = active.ClockTime })
		sky.StarCount = active.Stars
	elseif original then
		-- Synchronous restoration also covers skip, settings changes and teardown.
		Lighting.ClockTime = original.ClockTime
		if ownedSky then
			sky:Destroy()
		else
			sky.StarCount = original.Stars
		end
		original, sky, ownedSky = nil, nil, false
	end
end
function Sky.Acquire(config)
	if config.ClockTime == nil then
		return function() end
	end
	if not original then
		sky = Lighting:FindFirstChildOfClass("Sky")
		ownedSky = sky == nil
		sky = sky or C.New("Sky", Lighting, { Name = "RevealNightSky" })
		original = { ClockTime = Lighting.ClockTime, Stars = sky.StarCount }
	end
	local lease = { ClockTime = config.ClockTime, Stars = config.Stars or 0 }
	table.insert(leases, lease)
	refresh()
	return function()
		local index = table.find(leases, lease)
		if index then
			table.remove(leases, index)
			refresh()
		end
	end
end
return Sky
