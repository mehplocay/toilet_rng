-- Small, layered primitive illustrations. No external image is required.
local Art = {}
function Art.Draw(C, parent, kind, tint)
	local aliases = {
		StarTag = "Crown",
		VIP = "Crown",
		RainbowName = "Crown",
		ConfettiReveal = "Crown",
		GoldenName = "Crown",
		DancePack = "Crown",
		ToiletGlow = "Crown",
		Companion = "Home",
		UltimateBundle = "Crown",
		CoinPackMini = "Coins",
		CoinPackSmall = "Coins",
		CoinPackLarge = "Coins",
		CoinPackHuge = "Coins",
		LuckyFlush1 = "Gem",
		LuckyFlush5 = "Gem",
		LuckyFlush20 = "Gem",
		DoubleCash = "Coins",
		AutoCollect = "Shop",
		OfflinePlus = "Daily",
		VIPPack = "Crown",
		CoinPack = "Coins",
		PathBoost = "Upgrades",
	}
	kind = aliases[kind] or kind
	local white, ink = Color3.fromRGB(245, 251, 255), C.Ink
	local layer = parent.ZIndex
	local function shape(x, y, w, h, color, round, angle)
		layer += 1
		local f = C.New("Frame", parent, {
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(w, h),
			BackgroundColor3 = color or white,
			Rotation = angle or 0,
			ZIndex = layer,
		})
		if round then
			C.New("UICorner", f, { CornerRadius = UDim.new(round, 0) })
		end
		C.New("UIStroke", f, { Color = ink, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		C.Gradient(f, color or white)
		return f
	end
	local function eyes(x, y, separation)
		for i = 0, 1 do
			shape(x + i * separation, y, 0.16, 0.2, white, 1)
			layer += 1
			local pupil = C.New("Frame", parent, {
				Position = UDim2.fromScale(x + 0.055 + i * separation, y + 0.06),
				Size = UDim2.fromScale(0.075, 0.1),
				BackgroundColor3 = ink,
				ZIndex = layer,
			})
			C.New("UICorner", pupil, { CornerRadius = UDim.new(1, 0) })
		end
	end
	local function glyph(text, x, y, w, h, color)
		layer += 1
		local label = C.Text(parent, text, UDim2.fromScale(w, h), UDim2.fromScale(x, y), 80)
		label.ZIndex = layer
		label.TextColor3 = color or white
		return label
	end
	if kind == "Coins" or kind == "Coin" then
		shape(0.09, 0.13, 0.82, 0.82, Color3.fromRGB(205, 132, 20), 1)
		shape(0.06, 0.04, 0.82, 0.82, C.Gold, 1)
		shape(0.19, 0.17, 0.56, 0.56, Color3.fromRGB(255, 219, 82), 1)
		glyph("$", 0.27, 0.2, 0.42, 0.5, Color3.fromRGB(255, 252, 192))
	elseif kind == "Shop" then
		shape(0.18, 0.29, 0.65, 0.47, Color3.fromRGB(255, 97, 129), 0.15, -8)
		shape(0.32, 0.07, 0.37, 0.3, C.Gold, 0.2)
		shape(0.11, 0.26, 0.79, 0.16, Color3.fromRGB(255, 162, 182), 0.2, -8)
		shape(0.23, 0.79, 0.16, 0.16, white, 1)
		shape(0.67, 0.73, 0.16, 0.16, white, 1)
	elseif kind == "Collection" or kind == "Index" then
		shape(0.14, 0.2, 0.68, 0.7, C.Gold, 0.12, -8)
		shape(0.14, 0.12, 0.68, 0.68, C.Blue, 0.12, -8)
		shape(0.25, 0.17, 0.12, 0.54, Color3.fromRGB(115, 228, 255), 0.1, -8)
		glyph("+", 0.4, 0.2, 0.35, 0.44)
	elseif kind == "Upgrades" then
		shape(0.34, 0.42, 0.34, 0.49, Color3.fromRGB(130, 255, 99), 0.12)
		shape(0.28, 0.13, 0.44, 0.44, C.Green, 0.1, 45)
		shape(0.4, 0.28, 0.2, 0.42, Color3.fromRGB(156, 255, 125), 0.1)
	elseif kind == "Daily" then
		shape(0.12, 0.33, 0.76, 0.56, Color3.fromRGB(255, 82, 100), 0.1)
		shape(0.07, 0.27, 0.86, 0.2, Color3.fromRGB(255, 137, 157), 0.1)
		shape(0.39, 0.27, 0.2, 0.62, C.Gold, 0.05)
		shape(0.23, 0.05, 0.29, 0.22, C.Gold, 0.5, 25)
		shape(0.5, 0.05, 0.29, 0.22, C.Gold, 0.5, -25)
	elseif kind == "Passes" or kind == "Crown" or kind == "Hub" then
		shape(0.17, 0.45, 0.67, 0.38, C.Gold, 0.08)
		for i = 0, 2 do
			shape(0.13 + i * 0.25, 0.12 + (if i == 1 then -0.05 else 0), 0.25, 0.46, C.Gold, 0.15, (i - 1) * 18)
		end
		shape(0.42, 0.55, 0.15, 0.15, C.Purple, 0.1, 45)
	elseif kind == "Luck" or kind == "DoubleLuck" then
		local color = if kind == "DoubleLuck" then C.Gold else C.Green
		for _, xy in ipairs({ { 0.18, 0.1 }, { 0.48, 0.1 }, { 0.18, 0.4 }, { 0.48, 0.4 } }) do
			shape(xy[1], xy[2], 0.38, 0.38, color, 1)
		end
		shape(0.47, 0.6, 0.15, 0.3, color, 0.2, 25)
		if kind == "DoubleLuck" then
			shape(0.1, 0.63, 0.8, 0.29, C.Blue, 0.08)
			local label = C.Text(parent, "2x", UDim2.fromScale(0.8, 0.29), UDim2.fromScale(0.1, 0.63), 22)
			label.ZIndex = layer + 1
		end
	elseif kind == "Home" or kind == "Teleport" then
		shape(0.24, 0.35, 0.52, 0.52, C.Blue, 0.1)
		shape(0.22, 0.11, 0.56, 0.56, Color3.fromRGB(94, 214, 255), 0.05, 45)
		shape(0.25, 0.37, 0.5, 0.49, C.Blue, 0.05)
		shape(0.43, 0.59, 0.18, 0.29, C.Navy, 0.1)
	elseif kind == "Settings" then
		for i = 0, 3 do
			shape(0.37, 0.08, 0.26, 0.84, white, 0.15, i * 45)
		end
		shape(0.2, 0.2, 0.6, 0.6, white, 1)
		shape(0.37, 0.37, 0.26, 0.26, C.Navy, 1)
	elseif kind == "Pointer" then
		shape(0.34, 0.04, 0.18, 0.57, white, 0.4, -12)
		shape(0.3, 0.4, 0.53, 0.48, white, 0.2, -12)
		shape(0.15, 0.46, 0.25, 0.36, white, 0.35, -40)
	elseif kind == "Poop" or kind == "GoldenPoop" or kind == "KingPoop" then
		local brown = tint or Color3.fromRGB(161, 92, 49)
		shape(0.1, 0.59, 0.82, 0.31, brown, 0.5)
		shape(0.19, 0.37, 0.63, 0.32, brown, 0.5)
		shape(0.34, 0.15, 0.37, 0.31, brown, 0.5, -16)
		eyes(0.32, 0.48, 0.26)
		glyph("u", 0.44, 0.68, 0.2, 0.17, ink)
		if kind == "KingPoop" then
			glyph("W", 0.28, -0.08, 0.45, 0.34, C.Gold)
		end
	elseif kind == "ToiletPaper" then
		shape(0.22, 0.19, 0.57, 0.66, white, 0.2)
		shape(0.22, 0.13, 0.57, 0.26, white, 1)
		shape(0.41, 0.19, 0.19, 0.12, C.Navy, 1)
		shape(0.7, 0.39, 0.17, 0.46, white, 0.08, -5)
	elseif kind == "Rat" then
		shape(0.65, 0.65, 0.3, 0.09, Color3.fromRGB(243, 161, 174), 1, -24)
		shape(0.17, 0.34, 0.64, 0.48, Color3.fromRGB(144, 155, 185), 0.5)
		shape(0.25, 0.15, 0.24, 0.32, Color3.fromRGB(200, 159, 189), 1)
		shape(0.57, 0.16, 0.24, 0.32, Color3.fromRGB(200, 159, 189), 1)
		eyes(0.29, 0.46, 0.25)
		shape(0.42, 0.68, 0.2, 0.13, Color3.fromRGB(254, 160, 182), 1)
	elseif kind == "Fish" or kind == "SewerShark" then
		local blue = tint or C.Blue
		shape(0.1, 0.37, 0.29, 0.29, blue, 0.1, 45)
		shape(0.37, 0.17, 0.25, 0.28, blue, 0.1, 24)
		shape(0.24, 0.33, 0.66, 0.43, blue, 0.5)
		eyes(0.58, 0.39, 0.13)
	elseif kind == "Duck" then
		shape(0.13, 0.45, 0.69, 0.4, C.Gold, 0.5)
		shape(0.48, 0.15, 0.38, 0.45, C.Gold, 0.5)
		shape(0.76, 0.4, 0.2, 0.13, Color3.fromRGB(255, 135, 35), 0.25)
		eyes(0.61, 0.25, 0)
		shape(0.26, 0.56, 0.32, 0.2, Color3.fromRGB(255, 227, 97), 0.5, -12)
	elseif kind == "ToiletBaby" then
		shape(0.25, 0.49, 0.51, 0.4, white, 0.3)
		shape(0.18, 0.11, 0.64, 0.62, Color3.fromRGB(255, 197, 151), 0.5)
		eyes(0.3, 0.33, 0.24)
		shape(0.43, 0.56, 0.18, 0.14, Color3.fromRGB(108, 224, 255), 1)
	elseif kind == "Lock" then
		shape(0.28, 0.08, 0.44, 0.54, C.Gold, 0.45)
		shape(0.38, 0.2, 0.24, 0.3, C.Navy, 0.4)
		shape(0.17, 0.4, 0.66, 0.5, C.Gold, 0.16)
		glyph("!", 0.37, 0.47, 0.26, 0.33, ink)
	elseif kind == "Check" then
		shape(0.16, 0.42, 0.2, 0.42, C.Green, 0.2, -42)
		shape(0.49, 0.12, 0.2, 0.75, C.Green, 0.2, 38)
	elseif kind == "Gem" then
		shape(0.2, 0.2, 0.6, 0.6, C.Purple, 0.08, 45)
		shape(0.33, 0.25, 0.28, 0.28, Color3.fromRGB(255, 155, 240), 0.05, 45)
	elseif kind == "AutoFlush" then
		glyph("â†»", 0.03, 0, 0.94, 0.96, C.Blue)
		shape(0.4, 0.4, 0.2, 0.2, white, 1)
	elseif kind == "OfferBurst" then
		shape(0.17, 0.17, 0.66, 0.66, C.Gold, 0.06, 25)
		shape(0.17, 0.17, 0.66, 0.66, C.Gold, 0.06, -20)
		glyph("OP!", 0.08, 0.27, 0.84, 0.43, white)
	elseif kind == "Robux" then
		-- Original vector currency mark; no unrelated uploaded asset is used.
		shape(0.18, 0.18, 0.64, 0.64, white, 0.12, 22)
		shape(0.4, 0.4, 0.2, 0.2, C.Green, 0.02, 22)
	elseif kind == "Gift" then
		shape(0.17, 0.37, 0.66, 0.5, C.Purple, 0.08)
		shape(0.1, 0.29, 0.8, 0.19, white, 0.08)
		shape(0.43, 0.29, 0.14, 0.58, C.Gold, 0.05)
		shape(0.25, 0.08, 0.25, 0.22, C.Gold, 0.35, 22)
		shape(0.5, 0.08, 0.25, 0.22, C.Gold, 0.35, -22)
	elseif kind == "Mystery" or kind == "Locked" then
		shape(0.16, 0.16, 0.67, 0.68, C.Navy, 0.15, -7)
		glyph("?", 0.25, 0.18, 0.5, 0.6, C.Purple)
	else
		-- Toilet art also covers the Flush action and every upgrade tier.
		local color = tint or white
		shape(0.22, 0.06, 0.54, 0.49, color, 0.2)
		shape(0.33, 0.51, 0.37, 0.4, color, 0.15)
		shape(0.15, 0.4, 0.71, 0.39, color, 0.5)
		shape(0.24, 0.43, 0.53, 0.16, Color3.fromRGB(89, 218, 255), 1)
		shape(0.57, 0.18, 0.17, 0.07, C.Gold, 0.2)
		if kind == "AlienToilet" then
			eyes(0.3, 0.17, 0.24)
		end
	end
end
return Art
