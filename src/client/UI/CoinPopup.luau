local TweenService = game:GetService("TweenService")
local C = require(script.Parent.Components)
local CoinPopup = {}

function CoinPopup.Create(parent)
	return function(amount)
		if type(amount) ~= "number" or amount <= 0 or amount >= math.huge or amount % 1 ~= 0 then
			return
		end
		-- Each award owns its label/tween so fast flushes cannot cancel earlier popups.
		local label = C.Text(parent, "+" .. C.Commas(amount) .. " Coins", UDim2.fromScale(0.18, 0.05))
		label.Name = "ServiceCoinPopup"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.56, 0.67)
		label.TextColor3 = Color3.fromRGB(255, 220, 80)
		label.ZIndex = 50
		local tween = TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = label.Position - UDim2.fromOffset(0, 42),
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
