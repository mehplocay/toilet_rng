-- Selection is confirmed by replicated state, with a persistent visible swatch.
do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local config = H.Load("src/shared/Config/Monetization")
	local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
	local state =
		{ Settings = { PlotColor = "Mint" }, OwnedPasses = { CustomPlotColor = true }, Commerce = { Quotes = {} } }
	ui.Update(state)
	local current = ui.Panel:FindFirstChild("CurrentColorSwatch", true)
	local feedback = ui.Panel:FindFirstChild("StyleFeedback", true)
	for _, choice in ipairs(config.PlotColors) do
		local button = ui.Panel:FindFirstChild("PlotColor_" .. choice.Id, true)
		assert(button and button.ColorSwatch and button.Interactable)
		assert(button.ColorSwatch.Selection.Enabled == (choice.Id == "Mint"))
		if choice.RGB then
			assert(button.ColorSwatch.BackgroundColor3.R == choice.RGB[1] / 255)
		end
	end
	assert(current.BackgroundColor3.G == 210 / 255)
	local sky = ui.Panel:FindFirstChild("PlotColor_Sky", true)
	local before = #H.Calls
	sky.Activated:Fire()
	assert(#H.Calls == before + 1 and H.Calls[#H.Calls].Name == "PlotColor" and H.Calls[#H.Calls].Args[1] == "Sky")
	assert(feedback.Text == "Applying Sky..." and not sky.ColorSwatch.Selection.Enabled)
	remotes.Result.OnClientEvent:Fire("PlotColor", { Success = true, Message = "Plot color saved." })
	state.Settings.PlotColor = "Sky"
	ui.Update(state)
	assert(
		feedback.Text == "Plot color saved."
			and sky.ColorSwatch.Selection.Enabled
			and current.BackgroundColor3.R == 85 / 255
	)
	state.OwnedPasses = {}
	ui.Update(state)
	before = #H.Calls
	sky.Activated:Fire()
	assert(not sky.Interactable and #H.Calls == before)
	remotes.Result.OnClientEvent:Fire("PlotColor", { Success = false, Message = "Plot color is unavailable." })
	assert(feedback.Text == "Plot color is unavailable.")
	ui.Panel:Destroy()
	root:Destroy()
	print("Plot color UI: swatches, current selection, feedback, server confirmation and ownership gate")
end
