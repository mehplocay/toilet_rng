local TweenService = game:GetService("TweenService")
local C = require(script.Parent.Components)
local Layout = require(script.Parent.Layout)
local UserInputService = game:GetService("UserInputService")
local CoinPopup = {}

function CoinPopup.Create(parent)
	return function(amount, collected)
		if type(amount) ~= "number" or amount <= 0 or amount >= math.huge or amount % 1 ~= 0 then
			return
		end
		if C.SoundHook then
			C.SoundHook("CoinPopup")
		end
		-- Each award owns its group/tween so overlapping awards fade independently.
		local layout = Layout.Compute(parent.AbsoluteSize.X, parent.AbsoluteSize.Y, UserInputService.TouchEnabled)
		if collected then
			-- Bounded burst; each coin releases its tween/instance after arriving at the wallet.
			for index = 1, 5 do
				local coin = C.New("Frame", parent, {
					Name = "IncomeCoinFlight",
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(24, 24),
					ZIndex = 51,
					Position = UDim2.fromOffset(layout.CoinPopup.X + index * 25, layout.CoinPopup.Y + 12),
				})
				C.Icon(coin, "Coin", UDim2.fromScale(1, 1))
				local flight = TweenService:Create(
					coin,
					TweenInfo.new(0.4 + index * 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						Position = UDim2.fromOffset(
							layout.Coins.X + layout.Coins.W / 2,
							layout.Coins.Y + layout.Coins.H / 2
						),
						Size = UDim2.fromOffset(8, 8),
					}
				)
				flight.Completed:Once(function()
					coin:Destroy()
					flight:Destroy()
				end)
				flight:Play()
			end
		end
		local group = C.New(
			"CanvasGroup",
			parent,
			{ Name = "ServiceCoinPopup", BackgroundTransparency = 1, ZIndex = 50, AnchorPoint = Vector2.new(0.5, 0.5) }
		)
		C.Place(group, layout.CoinPopup)
		C.Icon(group, "Coin", UDim2.fromOffset(32, 32), UDim2.fromOffset(2, 2))
		local label = C.Text(group, "+" .. C.Commas(amount), UDim2.new(1, -40, 1, -4), UDim2.fromOffset(38, 2), 27)
		label.TextColor3 = Color3.fromRGB(255, 220, 80)
		local tween = TweenService:Create(group, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = group.Position - UDim2.fromOffset(0, layout.CoinRise),
			GroupTransparency = 1,
		})
		tween.Completed:Once(function()
			group:Destroy()
			tween:Destroy()
		end)
		tween:Play()
	end
end

return CoinPopup
