local Tutorial = {}

-- Progress follows server outcomes, never button clicks or local inventory edits.
function Tutorial.NextStep(step, action, payload)
	if type(payload) ~= "table" then
		return step
	end
	if step <= 2 and action == "Flush" and type(payload.ItemId) == "string" then
		return 3
	elseif step == 3 and action == "Sell" and payload.Success == true then
		return 4
	elseif step == 4 and action == "BuyToilet" and payload.Success == true then
		return 5
	end
	return step
end

function Tutorial.Create(player, remotes, navigation)
	local RunService = game:GetService("RunService")
	local C = require(script.Parent.Components)
	local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
	local accent = Color3.fromRGB(255, 225, 90)
	local gui = C.New("ScreenGui", player:WaitForChild("PlayerGui"), {
		Name = "ToiletTutorial",
		ResetOnSpawn = false,
		DisplayOrder = 10,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local card = C.New("Frame", gui, {
		Visible = false,
		Active = false,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.48, 0, 0, 6),
		Size = UDim2.new(0.5, 0, 0, 112),
		BackgroundColor3 = C.Navy,
	})
	C.Round(card, accent)
	C.New("UISizeConstraint", card, { MinSize = Vector2.new(180, 112), MaxSize = Vector2.new(460, 112) })
	local counter = C.Text(card, "", UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 6))
	counter.TextColor3 = accent
	local text = C.Text(card, "", UDim2.new(1, -16, 0, 36), UDim2.fromOffset(8, 27))
	text.TextWrapped = true
	C.New("UITextSizeConstraint", text, { MaxTextSize = 18 })
	local finish
	local skip = C.Button(card, "Skip", UDim2.fromOffset(64, 44), UDim2.new(1, -72, 1, -46), function()
		finish(true)
	end)
	skip.Modal = false
	local detail = C.Text(card, "", UDim2.new(1, -88, 0, 40), UDim2.new(0, 8, 1, -44))
	detail.TextWrapped = true
	C.New("UITextSizeConstraint", detail, { MaxTextSize = 14 })

	local step, snapshot, stopped, finishing = 1, nil, false, false
	local connections = {}
	local marker, source, destination, beam, prompt
	local highlight
	local function clearHint()
		for _, object in pairs({ beam, source, destination, marker }) do
			object:Destroy()
		end
		beam, source, destination, marker = nil, nil, nil, nil
	end
	local function clearHighlight()
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
	end
	local function stop()
		if stopped then
			return
		end
		stopped = true
		clearHint()
		clearHighlight()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		gui:Destroy()
	end
	finish = function(skipped)
		if finishing or stopped then
			return
		end
		finishing = true
		clearHint()
		clearHighlight()
		remotes.TutorialDone:FireServer()
		if skipped then
			stop()
		else
			skip.Visible = false
			task.delay(4, stop)
		end
	end

	local function render()
		if stopped or not snapshot then
			return
		end
		-- Older profiles can already own an upgrade; do not require another one.
		if step == 4 and snapshot.ToiletTier > 1 then
			step = 5
		end
		local messages = {
			"Walk to your toilet",
			"Hold E to FLUSH!",
			"Open Collection and sell an item",
			"Buy your first upgrade in Upgrades",
			"You're ready - chase the rare drops!",
		}
		card.Visible = true
		counter.Text = "Getting started - " .. step .. "/5"
		text.Text = messages[step]
		detail.Text = if step == 1
			then "Follow the yellow beam!"
			elseif step == 2 then "On mobile, hold the FLUSH prompt."
			else ""
		if step == 4 then
			local nextToilet = Toilets[snapshot.ToiletTier + 1]
			if nextToilet and snapshot.Coins < nextToilet.Price then
				detail.Text = "Keep flushing to earn coins!"
			end
		end
		clearHighlight()
		local button = if step == 3 then navigation.Collection elseif step == 4 then navigation.Upgrades else nil
		if button then
			highlight = C.New("Frame", button, {
				Name = "TutorialHighlight",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Active = false,
			})
			C.Round(highlight, accent)
			highlight.UIStroke.Thickness = 4
		end
		if step >= 3 then
			clearHint()
		end
		if step == 5 then
			finish(false)
		end
	end
	table.insert(
		connections,
		remotes.State.OnClientEvent:Connect(function(state)
			if state.TutorialDone == true then
				if not finishing then
					stop()
				end
				return
			end
			snapshot = state
			render()
		end)
	)
	table.insert(
		connections,
		remotes.Result.OnClientEvent:Connect(function(action, payload)
			if stopped or finishing or not snapshot then
				return
			end
			step = Tutorial.NextStep(step, action, payload)
			render()
		end)
	)

	local elapsed = 0
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if stopped or not snapshot or step > 2 or elapsed < 0.25 then
				return
			end
			elapsed = 0
			if not prompt or not prompt:IsDescendantOf(workspace) then
				prompt = nil
				for _, object in ipairs(workspace:GetDescendants()) do
					if object:IsA("ProximityPrompt") and object:GetAttribute("OwnerUserId") == player.UserId then
						prompt = object
						break
					end
				end
			end
			local target = prompt and prompt.Parent
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not target or not target:IsA("BasePart") or not root then
				clearHint()
				return
			end
			-- Recreate local attachments after respawn, streaming or toilet replacement.
			if not source or source.Parent ~= root or not destination or destination.Parent ~= target then
				clearHint()
				source = C.New("Attachment", root, { Name = "TutorialOrigin" })
				destination = C.New("Attachment", target, { Name = "TutorialTarget", Position = Vector3.new(0, 2, 0) })
				beam = C.New("Beam", source, {
					Attachment0 = source,
					Attachment1 = destination,
					FaceCamera = true,
					Width0 = 0.3,
					Width1 = 0.6,
					Color = ColorSequence.new(accent),
					LightEmission = 1,
					Transparency = NumberSequence.new(0.15),
				})
				marker = C.New("BillboardGui", gui, {
					Adornee = target,
					AlwaysOnTop = true,
					Size = UDim2.fromOffset(130, 48),
					StudsOffset = Vector3.new(0, 5, 0),
				})
				C.Text(marker, "YOUR TOILET\nv", UDim2.fromScale(1, 1)).TextColor3 = accent
			end
			if step == 1 and (root.Position - target.Position).Magnitude <= prompt.MaxActivationDistance then
				step = 2
				render()
			end
		end)
	)
	return { Destroy = stop }
end

return Tutorial
