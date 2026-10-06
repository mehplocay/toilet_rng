-- Shared by the UI runner and the security audit before unrelated UI suites.
function H.CheckRebirthClick()
	local C = H.Load("src/client/UI/Components")
	local soundHook = C.SoundHook
	local sounds = {}
	C.SoundHook = function(key)
		table.insert(sounds, key)
	end
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local config = H.Load("src/shared/Config/Rebirth")
	local ui = H.Load("src/client/UI/Rebirth").Create(root, remotes)
	local button = ui.Panel.ContentScroll.Body.Confirm
	local state =
		{ Coins = config.Levels[1].RequiredCoins, RunFlushes = config.RequiredFlushes, RebirthLevel = 0, Settings = {} }
	local requests, refreshes = 0, 0
	remotes.Rebirth.FireServer = function(_, expected, ...)
		assert(expected == state.RebirthLevel and select("#", ...) == 0)
		assert(not button.Interactable and button.Text == "SAVING...", "Button must lock before the remote call")
		requests += 1
	end
	remotes.State.FireServer = function()
		refreshes += 1
	end
	ui.Panel.Visible = true
	ui.Update(state)
	state.Coins -= 1
	ui.Update(state)
	button.Activated:Fire()
	assert(requests == 0 and not button.Interactable and button.Text:find("MORE COINS", 1, true))
	state.Coins += 1
	state.RunFlushes -= 1
	ui.Update(state)
	button.Activated:Fire()
	assert(requests == 0 and not button.Interactable and button.Text == "NEED 1 MORE FLUSH")
	state.Coins -= 1
	ui.Update(state)
	assert(button.Text == "NEED COINS + FLUSHES")
	state.Coins += 1
	state.RunFlushes += 1
	ui.Update(state)
	assert(button.Text == "REBIRTH!" and button.Interactable)
	for _, input in ipairs({
		{ UserInputType = Enum.UserInputType.MouseButton1 },
		{ UserInputType = Enum.UserInputType.Touch },
		{ KeyCode = Enum.KeyCode.ButtonA },
	}) do
		local before = requests
		button.Activated:Fire(input)
		assert(requests == before + 1, "One activation must send immediately")
		for _ = 1, 100 do
			button.Activated:Fire(input)
		end
		assert(requests == before + 1 and not button.Interactable, "Repeated activations submitted twice")
		ui.Panel.Visible = false
		ui.Panel.Visible = true
		ui.Update(state)
		assert(not button.Interactable, "Reopening or a state refresh unlocked the pending request")
		remotes.Result.OnClientEvent:Fire("BuyUpgrade", { Success = true })
		assert(not button.Interactable, "Unrelated result unlocked rebirth")
		H.Advance(config.ResponseTimeout + 0.1)
		H.Advance(config.ResponseTimeout + 0.1)
		button.Activated:Fire(input)
		assert(requests == before + 1 and not button.Interactable and button.Text == "SAVING...")
		remotes.Result.OnClientEvent:Fire("Rebirth", { Success = false, Message = "Please wait." })
		assert(button.Interactable and button.Text == "REBIRTH!", "Server rejection did not release the button")
	end
	assert(refreshes == 3, "Timeout must refresh once per request without resubmission")
	button.Activated:Fire()
	remotes.Result.OnClientEvent:Fire("Rebirth", { Success = false, Message = "Requirements changed." })
	assert(not button.Interactable and button.Text == "PLEASE WAIT", "Immediate rejection bypassed retry pacing")
	local beforeRetry = requests
	button.Activated:Fire()
	H.Advance(1 / H.Load("src/shared/Config/Remotes").Limits.Rebirth.Refill + 0.1)
	assert(requests == beforeRetry and button.Interactable, "Retry pacing resubmitted or trapped the button")
	button.Activated:Fire()
	local nextState = table.clone(state)
	nextState.RebirthLevel = 1
	nextState.Coins = config.Levels[2].RequiredCoins
	nextState.RunFlushes = config.RequiredFlushes
	ui.Update(nextState)
	assert(not button.Interactable, "Changed generation unlocked before the result")
	ui.Update(state)
	remotes.Result.OnClientEvent:Fire("Rebirth", { Success = true, Level = 1 })
	ui.Panel.Visible = true
	assert(not button.Interactable and button.Text == "UPDATING...", "Success exposed a stale generation")
	ui.Update(nextState)
	assert(button.Interactable and button.Text == "REBIRTH!")
	for _, key in ipairs(sounds) do
		assert(key ~= "RebirthHold", "Click started the retired charge cue")
	end
	ui.Panel:Destroy()
	local after = refreshes
	H.Advance(config.ResponseTimeout + 1)
	assert(refreshes == after, "Destroyed panel retained timeout listener")
	C.SoundHook = soundHook
	root:Destroy()
	print(
		"Rebirth click UI passed: immediate mouse/touch/gamepad activation, unmet gates, repeated taps, pending lock through refresh/timeout/reopen, result ordering and cleanup"
	)
end
