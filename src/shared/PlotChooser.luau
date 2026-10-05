-- Plots form a ring. Prefer a free neighbor of any already assigned friend.
local PlotChooser = {}

function PlotChooser.Choose(owners, friends)
	local count = #owners
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
