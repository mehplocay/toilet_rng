-- Production bootstrap, Home/GO TO TOILET, FlushPrompt.Near and tutorial on touch.
-- Insets are removed before sizing the CoreUISafeInsets root. Font metrics are
-- conservative harness estimates; native rendering still needs device QA.
do
	local player = H.Services.Players.LocalPlayer
	local screen = player.PlayerGui:FindFirstChild("ToiletUI")
	if screen then
		screen:Destroy()
	end
	H.Services.UserInputService.TouchEnabled = true
	local anchor = H.Instance.new("Part")
	anchor.Position, anchor.Parent = H.Vector3.new(100, 0, 100), H.Workspace
	local prompt = H.Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.MaxActivationDistance, prompt.Enabled = "FLUSH", 10, true
	prompt:SetAttribute("OwnerUserId", player.UserId)
	prompt.Parent = anchor
	local function character(position)
		local model = H.Instance.new("Model")
		local part, humanoid = H.Instance.new("Part"), H.Instance.new("Humanoid")
		part.Name, part.Position, part.Parent = "HumanoidRootPart", position, model
		humanoid.Health, humanoid.Parent = 100, model
		model._onPivot = function(cf)
			part.Position = cf.Position
		end
		player.Character = model
		return model, part, humanoid
	end
	local model, part, humanoid = character(H.Vector3.new())
	player:SetAttribute("PlotCFrame", nil)
	local remotes = H.Remotes()
	local root = H.BootClient(remotes, true)
	local spatial = H.Load("src/client/UI/FlushPrompt").Start()
	local near = spatial.Near
	local Progress = H.Load("src/shared/TutorialProgress")
	local state = {
		TutorialDone = false,
		TutorialStep = 1,
		TutorialRun = 0,
		Coins = 0,
		ToiletTier = 1,
		Inventory = {},
		Collection = {},
		Displays = {},
		DisplaySlots = 3,
		Upgrades = {},
		LifetimeFlushes = 0,
		AutoFlush = false,
		Settings = {},
		IndexClaims = {},
		IndexCosmetics = {},
		Stamps = 0,
		LastClaimDay = 0,
		Streak = 0,
	}
	local function update()
		remotes.State.OnClientEvent:Fire(table.clone(state))
		H.Advance(0.3)
		H.StartTasks()
		H.Layout(root)
	end
	assert(not root.Tutorial.Visible, "Guide appeared before the first State")
	root.HUD.Visible = false
	update()
	assert(not root.HUD.Travel.Home:FindFirstChild("TutorialHighlight"), "Hidden startup HUD was highlighted")
	root.HUD.Visible = true
	local function overlaps(a, b)
		local p, q, s, t = a.AbsolutePosition, b.AbsolutePosition, a.AbsoluteSize, b.AbsoluteSize
		return p.X < q.X + t.X and q.X < p.X + s.X and p.Y < q.Y + t.Y and q.Y < p.Y + s.Y
	end
	local function visible(object)
		while object and object ~= root do
			assert(
				object.Visible,
				"Tutorial target has a hidden ancestor: "
					.. object.Name
					.. " HUD="
					.. tostring(root.HUD.Visible)
					.. " toast="
					.. tostring(root.ResultToast.Visible)
					.. " reveal="
					.. tostring(root.HUD.FlushReveal.Visible)
			)
			object = object.Parent
		end
	end
	local function card(step)
		local guide = root.Tutorial
		visible(guide.Title)
		assert(guide.Title.Text:match("^" .. step .. "/5 "), "Missing phone n/5 prefix")
		assert(guide.Title.TextSize >= 14 and not guide.Title.TextScaled, "Phone text can shrink")
		for _, label in ipairs({ guide.Title, guide.Detail }) do
			local measured =
				H.Services.TextService:GetTextSize(label.Text, label.TextSize, label.Font, label.AbsoluteSize)
			assert(measured.Y <= label.AbsoluteSize.Y, "Phone tutorial text is truncated: " .. label.Text)
			assert(
				label.AbsolutePosition.X >= guide.AbsolutePosition.X
					and label.AbsolutePosition.X + label.AbsoluteSize.X <= guide.AbsolutePosition.X + guide.AbsoluteSize.X
					and label.AbsolutePosition.Y + label.AbsoluteSize.Y
						<= guide.AbsolutePosition.Y + guide.AbsoluteSize.Y,
				"Phone tutorial text is clipped"
			)
		end
		assert(guide.StepProgress.Visible and guide.StepProgress.Fill.Size.X.Scale == step / 5)
		assert(guide.SkipTutorial.AbsoluteSize.X >= 44 and guide.SkipTutorial.AbsoluteSize.Y >= 44)
		assert(not overlaps(guide.Title, guide.SkipTutorial) and not overlaps(guide.Detail, guide.SkipTutorial))
		for _, control in ipairs({ root.HUD.Travel, root.HUD.Wallet, root.HUD.PhoneStatus, root.HUD.FlushActions }) do
			assert(not overlaps(guide, control), "Tutorial covers mobile controls")
		end
		for _, name in ipairs({ "Shop", "Rebirth", "Index", "Upgrades", "Passes", "Daily", "Settings" }) do
			local control = root.HUD:FindFirstChild(name)
			assert(not control or not overlaps(guide, control), "Tutorial covers " .. name)
		end
		assert(
			guide.AbsolutePosition.Y + guide.AbsoluteSize.Y <= root.AbsoluteSize.Y * 0.4,
			"Tutorial covers the central character region"
		)
		assert(
			guide.AbsolutePosition.X >= 0
				and guide.AbsolutePosition.Y >= 0
				and guide.AbsolutePosition.X + guide.AbsoluteSize.X <= root.AbsoluteSize.X
				and guide.AbsolutePosition.Y + guide.AbsoluteSize.Y <= root.AbsoluteSize.Y
		)
		H.Snapshot(root, "tutorial-touch-" .. step .. "-" .. root.AbsoluteSize.X .. "x" .. root.AbsoluteSize.Y)
	end
	for _, viewport in ipairs({
		{ 320, 568, 0, 36, 0, 21 },
		{ 375, 667, 0, 36, 0, 21 },
		{ 375, 812, 0, 88, 0, 34 },
		{ 390, 844, 0, 88, 0, 34 },
		{ 360, 740, 0, 88, 0, 34 },
		{ 430, 932, 0, 88, 0, 34 },
		{ 812, 375, 44, 36, 44, 21 },
		{ 844, 390, 44, 36, 44, 21 },
		{ 932, 430, 44, 36, 44, 21 },
		{ 667, 375, 0, 36, 0, 21 },
		{ 568, 320, 0, 36, 0, 21 },
		{ 740, 360, 44, 36, 44, 21 },
		{ 640, 360, 0, 36, 0, 21 },
		{ 1170, 540, 54, 36, 0, 21 },
	}) do
		local w, h, left, top, right, bottom = table.unpack(viewport)
		root._fixed = H.Vector2.new(w - left - right, h - top - bottom)
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		model, part, humanoid = character(H.Vector3.new())
		player:SetAttribute("PlotCFrame", nil)
		Progress.Reset(state)
		state.Inventory, state.Collection = {}, {}
		update()
		assert(not near())
		card(1)
		local home = root.HUD.Travel:FindFirstChild("Home")
		assert(home and home:FindFirstChild("TutorialHighlight"))
		visible(home)
		assert(home.AbsolutePosition.X > 0 and home.AbsoluteSize.X >= 44)
		local hand = home.TutorialHighlight:FindFirstChild("PointerIcon")
		assert(hand, "Home pointer is missing")
		visible(hand)
		assert(
			hand.AbsolutePosition.X > 0
				and hand.AbsolutePosition.Y > 0
				and hand.AbsolutePosition.X + hand.AbsoluteSize.X <= home.AbsolutePosition.X + home.AbsoluteSize.X
				and hand.AbsolutePosition.Y + hand.AbsoluteSize.Y <= home.AbsolutePosition.Y + home.AbsoluteSize.Y,
			"Home pointer is outside its visible target"
		)
		-- An early tap is retained through missing plot assignment and character.
		prompt:SetAttribute("OwnerUserId", nil)
		home.Activated:Fire({ UserInputType = "Touch" })
		player.Character = nil
		player:SetAttribute("PlotCFrame", H.CFrame.new(100, 2.65, 91))
		H.Advance(0.3)
		assert(not near() and not model.LastPivot)
		player.Character = model
		H.Advance(0.3)
		H.StartTasks()
		update()
		assert(model.LastPivot and not near(), "Unassigned toilet advanced the tutorial")
		prompt:SetAttribute("OwnerUserId", player.UserId)
		update()
		assert(
			model.LastPivot and near(),
			"Early Home tap did not reach the plot: own="
				.. tostring(spatial.Own() == prompt)
				.. " near="
				.. tostring(near())
				.. " distance="
				.. tostring((part.Position - anchor.Position).Magnitude)
				.. " health="
				.. tostring(humanoid.Health)
		)
		card(2)
		local flush = root.HUD.FlushActions:FindFirstChild("FLUSH")
		-- C.Button retains the initial name while its text changes.
		assert(flush and flush:FindFirstChild("TutorialHighlight") and flush.Interactable)
		flush.Activated:Fire({ UserInputType = "Touch" })
		assert(H.Calls[#H.Calls].Name == "Flush")
		assert(Progress.Step(state) == 1, "Client advanced the persisted checkpoint")
		Progress.Record(state, "Flush", { ItemId = "Poop" })
		state.Inventory, state.Collection = { Poop = 1 }, { Poop = 1 }
		update()
		card(3)
		-- Rebirth/empty inventory and respawn must preserve the saved checkpoint.
		state.Inventory = {}
		humanoid.Health = 0
		update()
		assert(not near() and Progress.Step(state) == 3)
		card(3)
		Progress.Reset(state)
		model, part, humanoid = character(H.Vector3.new())
		update()
		assert(flush.Text == "GO TO\nTOILET")
		flush.Activated:Fire({ UserInputType = "Touch" })
		H.StartTasks()
		update()
		assert(near(), "GO TO TOILET did not reach the plot")
		card(2)
		flush.Activated:Fire({ UserInputType = "Touch" })
		assert(H.Calls[#H.Calls].Name == "Flush")
		Progress.Record(state, "Flush", { ItemId = "Poop" })
		update()
		card(3)
		state.TutorialStep = 4
		update()
		card(4)
		root.HUD.Visible = false
		H.Advance(0.3)
		assert(not home:FindFirstChild("TutorialHighlight") and not flush:FindFirstChild("TutorialHighlight"))
		root.HUD.Visible = true
		update()
		root.Tutorial.SkipTutorial.Activated:Fire({ UserInputType = "Touch" })
		assert(not root.Tutorial.Visible and H.Calls[#H.Calls].Name == "TutorialDone")
		Progress.Dismiss(state)
		update()
		assert(not root.Tutorial.Visible, "Dismissed guide restarted")
		root.HUD.Settings.Activated:Fire({ UserInputType = "Touch" })
		local replay = root:FindFirstChild("ReplayTutorial", true)
		replay.Activated:Fire({ UserInputType = "Touch" })
		assert(H.Calls[#H.Calls].Name == "TutorialReplay")
		Progress.Reset(state)
		part.Position = H.Vector3.new()
		update()
		assert(root.HUD.Visible and home:FindFirstChild("TutorialHighlight"), "Settings replay did not restore Home")
		card(1)
		Progress.Dismiss(state)
		update()
		card(5)
		H.Advance(7)
		assert(not root.Tutorial.Visible, "Completed tutorial did not expire")
		state.Coins, state.Inventory, state.RebirthLevel = 0, {}, 1
		update()
		assert(not root.Tutorial.Visible and Progress.Step(state) == 5, "Rebirth restarted the tutorial")
		print(string.format("PASS touch tutorial Home/GO TO TOILET 1->2->3 and n/5: %dx%d", w, h))
	end
	root:Destroy()
	H.Workspace.DescendantRemoving:Fire(prompt)
	anchor:Destroy()
	player.Character = nil
	player:SetAttribute("PlotCFrame", nil)
	H.Services.UserInputService.TouchEnabled = false
end
