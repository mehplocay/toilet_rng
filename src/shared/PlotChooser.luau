-- Prefer the physically nearest free plot to a friend; retain legacy ring callers.
local PlotChooser = {}

function PlotChooser.Choose(owners, friends, positions)
	local count = #owners
	if positions then
		local best, distance = nil, math.huge
		for index, owner in ipairs(owners) do
			if owner == false then
				for friendIndex, friendOwner in ipairs(owners) do
					if friendOwner ~= false and friends[friendOwner] then
						local a, b = positions[index], positions[friendIndex]
						local squared = (a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2
						if squared < distance then
							best, distance = index, squared
						end
					end
				end
			end
		end
		if best then
			return best
		end
	end
	for index, owner in ipairs(owners) do
		if owner ~= false and friends[owner] then
			for _, neighbor in ipairs({ index % count + 1, (index - 2) % count + 1 }) do
				if owners[neighbor] == false then
					return neighbor
				end
			end
		end
	end
	for index, owner in ipairs(owners) do
		if owner == false then
			return index
		end
	end
	return nil
end

function PlotChooser.ShowGuide(distanceToPlot, distanceToHub, nearDistance, hubRadius)
	return distanceToPlot > nearDistance and distanceToHub <= hubRadius
end

return PlotChooser
