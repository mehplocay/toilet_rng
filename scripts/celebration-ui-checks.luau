-- Execute the production controller in both check-ui.ps1 and check-audit.ps1.
do
	local check = test or function(name, callback)
		callback()
		print("PASS " .. name)
	end
	local beat = H.Services.RunService.Heartbeat
	local config = H.Load("src/shared/Config/Monetization")
	local limits = config.CelebrationEffects
	local function listeners(signal)
		local count = 0
		for _, entry in ipairs(signal.Listeners) do
			count += if entry.Connected then 1 else 0
		end
		return count
	end
	local function fixture()
		local root, remotes = H.Root(390, 722), H.Remotes()
		local player = H.Instance.new("Player")
		player.UserId, player.DisplayName = 790, "Celebration Tester"
		local function character()
			local model = H.Instance.new("Model")
			for _, name in ipairs({ "HumanoidRootPart", "Head" }) do
				local part = H.Instance.new("Part")
				part.Name, part.Position, part.CFrame, part.Parent = name, Vector3.new(), CFrame.new(), model
			end
			local humanoid = H.Instance.new("Humanoid")
			humanoid.Health, humanoid.NameDisplayDistance, humanoid.Parent = 100, 100, model
			return model
		end
		player.Character = character()
		player:SetAttribute("DancePack", true)
		local previous = H.PlayerList
		H.PlayerList = { player }
		local ui = H.Load("src/client/CatalogEffects").Start(root, player, remotes)
		local state = { OwnedPasses = { DancePack = true }, RebirthLevel = 0, Settings = { RevealIntensity = "Full" } }
		local function sync()
			remotes.State.OnClientEvent:Fire(state)
		end
		sync()
		local function pieces(name)
			local result = {}
			for _, child in ipairs(root:GetChildren()) do
				if (name and child.Name == name) or (not name and string.match(child.Name, "^Celebration%dPiece$")) then
					table.insert(result, child)
				end
			end
			return result
		end
		local function click(i)
			ui.Menu:FindFirstChild("Celebration" .. i, true).Activated:Fire()
		end
		local function stop()
			ui.Menu:FindFirstChild("Stop celebration", true).Activated:Fire()
		end
		local function destroy()
			root:Destroy()
			player.Character:Destroy()
			player:Destroy()
			H.PlayerList = previous
		end
		return root, player, remotes, ui, state, sync, pieces, click, stop, character, destroy
	end
	check("celebration: HUD starts immediately, visible Stop label and both stop actions clear immediately", function()
		local root, _, _, ui, _, _, pieces, _, stop, _, destroy = fixture()
		assert(
			root.CelebrationMenu.Text == "Celebrate"
				and root.CelebrationMenu.Label.Text
					== (if H.Load("src/client/UI/Layout")
							.IsPhone(root.AbsoluteSize.X, root.AbsoluteSize.Y, H.Services.UserInputService.TouchEnabled)
						then "Dance"
						else "Celebrate")
		)
		root.CelebrationMenu.Activated:Fire()
		assert(root.CelebrationMenu.Text == "Stop" and root.CelebrationMenu.Label.Text == "Stop")
		assert(#pieces() > 0 and ui.Menu.Visible)
		local prior = pieces()
		root.CelebrationMenu.Activated:Fire()
		assert(#pieces() == 0 and root.CelebrationMenu.Text == "Celebrate" and not ui.Menu.Visible)
		for _, piece in ipairs(prior) do
			assert(piece._dead)
		end
		beat:Fire(5)
		assert(#pieces() == 0, "Stopped effect restarted on heartbeat")
		root.CelebrationMenu.Activated:Fire()
		stop()
		assert(
			#pieces() == 0
				and root.CelebrationMenu.Label.Text
					== (if H.Load("src/client/UI/Layout")
							.IsPhone(root.AbsoluteSize.X, root.AbsoluteSize.Y, H.Services.UserInputService.TouchEnabled)
						then "Dance"
						else "Celebrate")
		)
		beat:Fire(5)
		assert(#pieces() == 0)
		destroy()
	end)
	check("celebration: four independent toggles, menu access and capped repeated presses", function()
		local root, _, _, ui, _, _, pieces, click, stop, _, destroy = fixture()
		root.CelebrationMenu.Activated:Fire()
		click(1)
		for i = 1, 4 do
			click(i)
			assert(ui.Menu:FindFirstChild("Celebration" .. i, true).Label.Text == config.Celebrations[i] .. ": ON")
			assert(#pieces("Celebration" .. i .. "Piece") == limits.FullPerEffect)
		end
		assert(#pieces() == 4 * limits.FullPerEffect)
		click(2)
		assert(#pieces("Celebration2Piece") == 0 and #pieces("Celebration3Piece") > 0)
		for _ = 1, 50 do
			for i = 1, 4 do
				click(i)
			end
			beat:Fire(2.1)
			assert(#pieces() <= 4 * limits.FullPerEffect)
		end
		stop()
		root.CelebrationMenu.Activated:Fire()
		ui.Menu.TitleBar.X.Activated:Fire()
		root.CelebrationMenu.Activated:Fire()
		assert(#pieces() == 0, "Closing the menu made HUD Stop ineffective")
		root.CelebrationMenu.Activated:Fire()
		assert(ui.Menu.Visible and root.CelebrationMenu.Label.Text == "Stop")
		stop()
		for _ = 1, 50 do
			root.CelebrationMenu.Activated:Fire()
			assert(#pieces() == limits.FullPerEffect)
			root.CelebrationMenu.Activated:Fire()
			assert(#pieces() == 0)
		end
		beat:Fire(20)
		assert(#pieces() == 0)
		destroy()
	end)
	check("celebration: death, removing and added reset without auto-restart or stale death listeners", function()
		local root, player, remotes, _, state, sync, pieces, _, _, character, destroy = fixture()
		state.OwnedPasses.ConfettiReveal = true
		sync()
		root.CelebrationMenu.Activated:Fire()
		remotes.Result.OnClientEvent:Fire("Flush", { Success = true })
		local old = player.Character
		old.Humanoid.Health = 0
		old.Humanoid.Died:Fire()
		assert(
			#pieces() == 0
				and #pieces("RevealConfetti") == 0
				and root.CelebrationMenu.Label.Text
					== (if H.Load("src/client/UI/Layout")
							.IsPhone(root.AbsoluteSize.X, root.AbsoluteSize.Y, H.Services.UserInputService.TouchEnabled)
						then "Dance"
						else "Celebrate")
		)
		root.CelebrationMenu.Activated:Fire()
		assert(#pieces() == 0, "Dead character started celebration")
		player.CharacterRemoving:Fire(old)
		player.Character = character()
		player.CharacterAdded:Fire(player.Character)
		beat:Fire(3)
		assert(#pieces() == 0, "Respawn restarted celebration")
		root.CelebrationMenu.Activated:Fire()
		assert(#pieces() > 0)
		old.Humanoid.Died:Fire()
		assert(#pieces() > 0, "Previous character retained a death callback")
		player.CharacterRemoving:Fire(player.Character)
		assert(#pieces() == 0)
		old:Destroy()
		destroy()
	end)
	check("celebration: plot change, rebirth state/success, ownership changes and grants reset the session", function()
		local root, player, remotes, _, state, sync, pieces, _, _, _, destroy = fixture()
		local function start()
			root.CelebrationMenu.Activated:Fire()
			assert(#pieces() > 0)
		end
		start()
		player:SetAttribute("PlotCFrame", CFrame.new(10, 0, 0))
		assert(#pieces() == 0)
		start()
		state.RebirthLevel = 1
		sync()
		assert(#pieces() == 0)
		start()
		sync()
		remotes.Result.OnClientEvent:Fire("Rebirth", { Success = false })
		assert(#pieces() > 0, "Ordinary sync or failed rebirth interrupted celebration")
		remotes.Result.OnClientEvent:Fire("Rebirth", { Success = true })
		assert(#pieces() == 0)
		start()
		player:SetAttribute("DancePack", false)
		assert(#pieces() == 0 and not root.CelebrationMenu.Interactable)
		root.CelebrationMenu.Activated:Fire()
		beat:Fire(5)
		assert(#pieces() == 0)
		player:SetAttribute("DancePack", true)
		assert(#pieces() == 0)
		start()
		state.OwnedPasses = {}
		sync()
		assert(#pieces() == 0 and not root.CelebrationMenu.Visible)
		state.OwnedPasses = { UltimateBundle = true }
		sync()
		assert(#pieces() == 0 and root.CelebrationMenu.Visible)
		start()
		destroy()
	end)
	check("celebration: Reduced applies immediately, Off clears both channels and never restarts", function()
		local root, _, remotes, _, state, sync, pieces, click, _, _, destroy = fixture()
		state.OwnedPasses.ConfettiReveal = true
		sync()
		for i = 1, 4 do
			click(i)
		end
		remotes.Result.OnClientEvent:Fire("Flush", { Success = true })
		assert(#pieces() == 4 * limits.FullPerEffect and #pieces("RevealConfetti") == limits.FullReveal)
		state.Settings.RevealIntensity = "Reduced"
		sync()
		assert(#pieces() == 4 * limits.ReducedPerEffect and #pieces("RevealConfetti") == 0)
		for _ = 1, 20 do
			beat:Fire(2.1)
			remotes.Result.OnClientEvent:Fire("Flush", { Success = true })
			assert(#pieces() <= 4 * limits.ReducedPerEffect and #pieces("RevealConfetti") <= limits.ReducedReveal)
		end
		state.Settings.RevealIntensity = "Off"
		sync()
		assert(#pieces() == 0 and #pieces("RevealConfetti") == 0 and not root.CelebrationMenu.Interactable)
		root.CelebrationMenu.Activated:Fire()
		click(1)
		beat:Fire(5)
		remotes.Result.OnClientEvent:Fire("Flush", {})
		assert(#pieces() == 0 and #pieces("RevealConfetti") == 0)
		state.Settings.RevealIntensity = "Full"
		sync()
		beat:Fire(5)
		assert(
			#pieces() == 0
				and root.CelebrationMenu.Label.Text
					== (if H.Load("src/client/UI/Layout")
							.IsPhone(root.AbsoluteSize.X, root.AbsoluteSize.Y, H.Services.UserInputService.TouchEnabled)
						then "Dance"
						else "Celebrate")
		)
		destroy()
	end)
	check("celebration: all-pass names/trails remain independent and reveal confetti always expires", function()
		local root, player, remotes, _, state, sync, pieces, click, stop, _, destroy = fixture()
		H.Reload("src/shared/Visuals/Primitives")
		local service = H.Load("src/server/Services/CosmeticService").new({ Assigned = {} })
		service:Apply(player, { UltimateBundle = true }, { Settings = {}, RebirthLevel = 0 })
		state.OwnedPasses = { UltimateBundle = true }
		sync()
		root.CelebrationMenu.Activated:Fire()
		remotes.Result.OnClientEvent:Fire("Flush", { Success = true })
		local reveal = pieces("RevealConfetti")
		click(2)
		click(2)
		assert(#pieces("RevealConfetti") == #reveal, "Dance Pack switch consumed the independent reveal")
		stop()
		assert(#pieces() == 0 and #reveal == limits.FullReveal and #pieces("RevealConfetti") == 0)
		for _, piece in ipairs(reveal) do
			assert(piece._dead)
		end
		remotes.Result.OnClientEvent:Fire("Flush", { Success = true })
		assert(#pieces("RevealConfetti") == limits.FullReveal)
		beat:Fire(limits.Lifetime + 0.1)
		assert(#pieces() == 0 and #pieces("RevealConfetti") == 0)
		assert(player.Character.HumanoidRootPart.PassSparkleTrail and player.Character.Head.PassName)
		assert(player:GetAttribute("DancePack") == true and player:GetAttribute("Celebrating") == nil)
		remotes.Result.OnClientEvent:Fire("Flush", { Success = false })
		assert(#pieces("RevealConfetti") == 0)
		remotes.Result.OnClientEvent:Fire("Flush", {})
		assert(#pieces("RevealConfetti") > 0)
		player:SetAttribute("ConfettiReveal", false)
		assert(#pieces("RevealConfetti") == 0)
		player:SetAttribute("ConfettiReveal", true)
		root.CelebrationMenu.Activated:Fire()
		service:Apply(player, {}, { Settings = {}, RebirthLevel = 0 })
		assert(#pieces() == 0, "Server ownership revocation did not stop client effects")
		service:Remove(player)
		destroy()
	end)
	check(
		"celebration: root teardown disconnects every callback and releases UI, companions and death listeners",
		function()
			local before = listeners(beat)
			local root, player, remotes, _, state, sync, pieces, _, _, _, destroy = fixture()
			state.OwnedPasses.ConfettiReveal = true
			sync()
			player:SetAttribute("Companion", true)
			beat:Fire(0.11)
			root.CelebrationMenu.Activated:Fire()
			remotes.Result.OnClientEvent:Fire("Flush", {})
			local prior = pieces()
			local calls = #H.Calls
			local humanoid = player.Character.Humanoid
			destroy()
			assert(listeners(beat) == before and listeners(remotes.State.OnClientEvent) == 0)
			assert(listeners(remotes.Result.OnClientEvent) == 0 and listeners(humanoid.Died) == 0)
			beat:Fire(5)
			remotes.Result.OnClientEvent:Fire("Flush", {})
			remotes.State.OnClientEvent:Fire(state)
			for _, piece in ipairs(prior) do
				assert(piece._dead)
			end
			assert(
				#pieces() == 0 and #pieces("RevealConfetti") == 0 and #H.Calls == calls,
				"Cosmetic toggles sent a remote"
			)
		end
	)
	check("celebration: Confetti Reveal without Dance Pack survives ordinary sync and expires once", function()
		local root, player, remotes, _, state, sync, pieces, _, _, _, destroy = fixture()
		player:SetAttribute("DancePack", false)
		state.OwnedPasses = { ConfettiReveal = true, RainbowName = true }
		sync()
		assert(not root.CelebrationMenu.Visible)
		remotes.Result.OnClientEvent:Fire("Flush", { Success = true })
		local prior = pieces("RevealConfetti")
		assert(#prior == limits.FullReveal and #pieces() == 0)
		sync()
		assert(#pieces("RevealConfetti") == #prior)
		for _, piece in ipairs(prior) do
			assert(not piece._dead, "Ordinary state sync consumed the independent reveal")
		end
		beat:Fire(limits.Lifetime + 0.1)
		beat:Fire(5)
		assert(#pieces("RevealConfetti") == 0 and #pieces() == 0)
		destroy()
	end)
	check("celebration: local player leave stops and disconnects the controller immediately", function()
		local root, player, remotes, _, _, _, pieces, _, _, _, destroy = fixture()
		root.CelebrationMenu.Activated:Fire()
		H.Services.Players.PlayerRemoving:Fire(player)
		assert(#pieces() == 0 and not root:FindFirstChild("CelebrationMenu"))
		assert(listeners(remotes.State.OnClientEvent) == 0 and listeners(player.Character.Humanoid.Died) == 0)
		beat:Fire(5)
		assert(#pieces() == 0)
		destroy()
	end)
end
