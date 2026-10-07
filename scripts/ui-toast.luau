-- Exercise the real Result handlers and every window header, including owner admin.
do
	local C = H.Load("src/client/UI/Components")
	local Layout = H.Load("src/client/UI/Layout")
	local adminRemote = { OnClientEvent = H.Signal(), FireServer = function() end }
	local admin = H.Load("src/admin-client/Window").Create(clientRoot, adminRemote, C)
	local panels = {}
	for _, object in ipairs(clientRoot:GetDescendants()) do
		if object:IsA("Frame") and object:FindFirstChild("TitleBar") then
			table.insert(panels, object)
			object.Visible = false
		end
	end
	assert(#panels == 14, "Missing a window in the toast regression")
	local function overlap(a, b)
		local ap, as, bp, bs = a.AbsolutePosition, a.AbsoluteSize, b.AbsolutePosition, b.AbsoluteSize
		return ap.X < bp.X + bs.X and bp.X < ap.X + as.X and ap.Y < bp.Y + bs.Y and bp.Y < ap.Y + as.Y
	end
	local touchBefore = H.Services.UserInputService.TouchEnabled
	for _, touch in ipairs({ false, true }) do
		H.Services.UserInputService.TouchEnabled = touch
		for _, size in ipairs(H.Viewports) do
			clientRoot._fixed, clientRoot._abs = { X = size[1], Y = size[2] }, nil
			clientRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
			for _, panel in ipairs(panels) do
				panel.Visible = true
				bootRemotes.Result.OnClientEvent:Fire("BuyUpgrade", {
					Success = true,
					Message = "Permanent upgrade purchased!",
				})
				H.Layout(clientRoot)
				local toast = assert(clientRoot:FindFirstChild("ResultToast"))
				assert(toast.Visible and toast.Message.Text == "Permanent upgrade purchased!")
				assert(not overlap(toast, panel.TitleBar), panel.Name .. " toast covers the title bar")
				assert(not overlap(toast, panel.TitleBar.X), panel.Name .. " toast covers Close")
				assert(not overlap(toast, admin.Open), "Toast covers Admin")
				local p, s = toast.AbsolutePosition, toast.AbsoluteSize
				assert(p.X >= 24 and p.Y >= 0 and p.X + s.X <= size[1] - 24 and p.Y + s.Y <= size[2])
				assert(s.X <= 420 and s.Y == 64, "Toast is not compact")
				local action = Layout.Compute(size[1], size[2], touch).Action
				assert(p.Y + s.Y <= action.Y - 10, "Toast covers HUD action buttons")
				assert(toast.Message.TextWrapped and toast.Message.UITextSizeConstraint.MinTextSize >= 14)
				assert(toast.Message.AbsoluteSize.Y >= 58, "Mobile message has no wrapping space")
				if touch and panel.Name == "Toilet Upgrades" then
					H.Snapshot(clientRoot, "result-toast-" .. size[1] .. "x" .. size[2])
				end
				panel.Visible = false
			end
		end
	end
	H.Services.UserInputService.TouchEnabled = touchBefore
	local toast = clientRoot.ResultToast
	local count = 0
	for _, child in ipairs(clientRoot:GetChildren()) do
		if child.Name == "ResultToast" then
			count += 1
		end
	end
	assert(count == 1, "Result handlers stack overlapping toasts")
	bootRemotes.Result.OnClientEvent:Fire("Sell", { Success = false, Message = "Please move closer." })
	assert(toast.Message.Text == "Please move closer.")
	H.Advance(2.4)
	assert(toast.Visible and toast.BackgroundTransparency == 0 and toast.Message.TextTransparency == 0)
	H.Advance(0.1)
	assert(toast.Visible and toast.BackgroundTransparency == 1 and toast.Message.TextTransparency == 1)
	assert(toast.UIStroke.Transparency == 1 and toast.Message.UIStroke.Transparency == 1, "Fade leaves strokes visible")
	bootRemotes.Result.OnClientEvent:Fire("BuyUpgrade", { Success = false, Message = "Not enough coins." })
	H.Advance(0.25)
	assert(toast.Visible and toast.Message.TextTransparency == 0, "Previous fade hides a fresh Result")
	H.Advance(2.25)
	H.Advance(0.25)
	assert(not toast.Visible, "Toast did not expire")
	local lifetimeRoot = H.Root(390, 722)
	local show = C.Toast(lifetimeRoot)
	show("Pending result")
	lifetimeRoot:Destroy()
	H.Advance(3)
	show("Late result")
	assert(lifetimeRoot.ResultToast == nil, "Destroyed toast accepts late results")
	admin.Panel.Parent:Destroy()
	print(
		"Result toast passed: all 13 windows at 12 viewports, mouse/touch, compact safe bounds, headers/Close/Admin/actions, fade, replacement and cleanup"
	)
end
