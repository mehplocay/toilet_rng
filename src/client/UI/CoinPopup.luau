local TweenService = game:GetService("TweenService")
local C = require(script.Parent.Components)
local Layout = require(script.Parent.Layout)
local UserInputService = game:GetService("UserInputService")
local CoinPopup = {}

function CoinPopup.Create(parent)
	return function(amount)
		if type(amount) ~= "number" or amount <= 0 or amount >= math.huge or amount % 1 ~= 0 then
			return
		end
		if C.SoundHook then
			C.SoundHook("CoinCollect")
		end
		-- Each award owns its group/tween so overlapping awards fade independently.
		local layout = Layout.Compute(parent.AbsoluteSize.X, parent.AbsoluteSize.Y, UserInputService.TouchEnabled)
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
