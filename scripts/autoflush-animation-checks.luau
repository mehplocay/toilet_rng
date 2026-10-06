-- Actual production world animation against the engine-boundary doubles, in every template mode.
do
	local owner = { UserId = 901, DisplayName = "Away owner" }
	local model = Instance.new("Model")
	model.Parent = workspace
	local plot = { Model = model, CFrame = CFrame.new(10000, 0, 0), Owner = owner }
	plot.Toilet = Models.Toilet(model, plot.CFrame, 1, 1, owner)
	local toilet = plot.Toilet
	assert(toilet.ModelStreamingMode == Enum.ModelStreamingMode.PersistentPerPlayer)
	assert(toilet._persistentPlayer == owner, "Only the owner must retain the toilet outside streaming range")
	World.Assigned[owner] = plot
	local pivot = toilet:GetPivot()
	for cycle = 1, 4 do
		World:Animate(owner, Items[1], true, 0.32, false, true, true)
		assert(toilet:GetAttribute("Flushing") and plot.StopAnimation)
		local effect = toilet.PrimaryPart:FindFirstChild("FlushBurst")
		assert(effect and effect.Emitted == V.Budget.Burst)
		local burstCount = 0
		for _, child in ipairs(toilet:GetDescendants()) do
			assert(child.ClassName ~= "Sound", "Automatic cycle added spatial audio")
			if child.Name == "FlushBurst" then
				burstCount += 1
			end
		end
		assert(burstCount == 1 and #model:GetChildren() == 1, "Compact cycle duplicated effects or built a drop")
		local tween = tweens[#tweens]
		assert(tween.Played and tween.Info[1] * 12 == 0.32)
		assert(tween.Goal.Value ~= pivot, "Cycle did not schedule toilet movement")
		if cycle == 1 then
			-- Leave one cycle active to exercise replacement/cancellation on the next award.
		elseif cycle == 2 then
			tween.Completed:Fire()
		else
			World:StopAnimation(owner)
			World:StopAnimation(owner)
		end
		if cycle > 1 then
			assert(not plot.StopAnimation and not toilet:GetAttribute("Flushing"))
			assert(tween.Destroyed and effect.Cleared and not effect.Parent)
			assert((toilet:GetPivot().Position - pivot.Position).Magnitude < 0.001)
			tween.Completed:Fire() -- Stale completion must be inert.
		end
	end
	World.Assigned[owner] = nil
	model:Destroy()
	print("Auto animation world checks passed: owner persistence, far cycles, budgets, replacement and cleanup")
end
