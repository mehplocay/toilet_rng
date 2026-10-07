-- Selection is confirmed by replicated state, with a persistent visible swatch.
do
	H.StartTasks()
	H.UseCommerceIds(true)
	local marketplace = H.Services.MarketplaceService
	local original = marketplace.GetProductInfoAsync
	marketplace.GetProductInfoAsync = function()
		return { IsForSale = true, PriceInRobux = 25 }
	end
	local root, remotes = H.Root(390, 722), H.Remotes()
	local config = H.Load("src/shared/Config/Monetization")
	local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
	local state =
		{ Settings = { PlotColor = "Mint" }, OwnedPasses = { CustomPlotColor = true }, Commerce = { Quotes = {} } }
	ui.Update(state)
	ui.Panel.Visible = true
	H.StartTasks()
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
	-- Color confirmation and purchase recovery must remain independent in one window.
	local body = ui.Panel.ContentScroll.Body
	local purchase = body.PurchaseMessage
	local boost = ui.Panel:FindFirstChild("BoostGrid", true).Coins10Minutes.OfferCard.Buy
	boost.Activated:Fire()
	assert(body.PurchaseStatus.Text == "Preparing your purchase...")
	sky.Activated:Fire()
	remotes.Result.OnClientEvent:Fire("PlotColor", { Success = true, Message = "Plot color saved." })
	assert(body.PurchaseStatus.Text == "Preparing your purchase...")
	H.Advance(9)
	ui.Update(state)
	assert(body.PurchaseStatus.Text == "Preparing your purchase...")
	H.Advance(1)
	assert(purchase.Text:find("timed out", 1, true) and feedback.Text == "Plot color saved.")
	remotes.Result.OnClientEvent:Fire("BuyProduct", { Success = false, Message = "Purchase unavailable." })
	assert(purchase.Text == "Purchase unavailable." and feedback.Text == "Plot color saved.")
	body.BoostsTab.Activated:Fire()
	assert(not feedback.Visible and not current.Parent.Visible and not sky.Parent.Visible)
	body.PassesTab.Activated:Fire()
	assert(feedback.Visible and current.Parent.Visible and sky.Parent.Visible)
	state.Commerce.Lucky = { Allowed = true, PolicyRemaining = 120, Count = 1, Odds = { Items = {}, Rarities = {} } }
	ui.Update(state)
	body.LuckyTab.Activated:Fire()
	assert(ui.Panel:FindFirstChild("LuckyGrid", true).Visible and not feedback.Visible)
	H.Advance(120)
	assert(not body.LuckyTab.Visible and feedback.Visible and current.Parent.Visible and sky.Parent.Visible)
	state.OwnedPasses = {}
	ui.Update(state)
	before = #H.Calls
	sky.Activated:Fire()
	assert(not sky.Interactable and #H.Calls == before)
	remotes.Result.OnClientEvent:Fire("PlotColor", { Success = false, Message = "Plot color is unavailable." })
	assert(feedback.Text == "Plot color is unavailable.")
	ui.Panel:Destroy()
	root:Destroy()
	marketplace.GetProductInfoAsync = original
	H.UseCommerceIds(false)
	print("Plot color UI: swatches, confirmation, ownership gate, purchase timeout isolation and Lucky tab transitions")
end
