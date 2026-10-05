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
		-- Each award owns its label/tween so fast flushes cannot cancel earlier popups.
		local layout = Layout.Compute(parent.AbsoluteSize.X, parent.AbsoluteSize.Y, UserInputService.TouchEnabled)
		local label = C.Text(parent, "+" .. C.Commas(amount) .. " Coins", UDim2.fromOffset(180, 36), nil, 27)
		label.Name = "ServiceCoinPopup"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		C.Place(label, layout.CoinPopup)
		label.TextColor3 = Color3.fromRGB(255, 220, 80)
		label.ZIndex = 50
		local tween = TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = label.Position - UDim2.fromOffset(0, layout.CoinRise),
			TextTransparency = 1,
		})
		local outline = label:FindFirstChildWhichIsA("UIStroke")
		if outline then
			TweenService:Create(outline, TweenInfo.new(0.9), { Transparency = 1 }):Play()
		end
		tween.Completed:Once(function()
			label:Destroy()
			tween:Destroy()
		end)
		tween:Play()
	end
end

return CoinPopup
