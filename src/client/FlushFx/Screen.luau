-- Screen-space flush overlays: flash, colour grade, edge glow, light rays, shockwave rings,
-- floating rarity text, confetti rain and coins flying into the wallet. Every element is
-- built once and reused; idle layers stay hidden. Per-frame work is property writes only.
local Lighting = game:GetService("Lighting")
local Rules = require(game.ReplicatedStorage.Shared.FlushFxRules)
local C = require(script.Parent.Parent.UI.Components)
local Screen = {}
local white = Color3.new(1, 1, 1)
local GOLDEN = 0.6180339887

function Screen.new(root, hud, config)
	local S = config.Screen
	local self = {}
	local back, front, flash, grade, wheel, text, textScale, textStroke, wallet, walletScale
	local edges, rays, rings, confetti, coins, emojis = {}, {}, {}, {}, {}, {}
	local comic, comicScale, comicText, comicStroke, comicStars
	local job, lastStep = nil, -math.huge
	local function frame(parent, name, props)
		local object = C.New("Frame", parent, { Name = name, BackgroundTransparency = 1, BorderSizePixel = 0 })
		for key, value in pairs(props or {}) do
			object[key] = value
		end
		return object
	end
	local function fade(sequenceFrom, sequenceTo)
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, sequenceFrom),
			NumberSequenceKeypoint.new(1, sequenceTo),
		})
	end
	local function build()
		back = frame(root, "FlushFxBack", {
			Size = UDim2.fromScale(1, 1),
			ZIndex = S.BackZIndex,
			Visible = false,
			ClipsDescendants = true,
			Active = false,
		})
		front = frame(root, "FlushFxFront", {
			Size = UDim2.fromScale(1, 1),
			ZIndex = S.FrontZIndex,
			Visible = false,
			ClipsDescendants = true,
			Active = false,
		})
		flash = frame(front, "Flash", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = white, Visible = false })
		-- Soft flash: strongest across the middle band, never a hard full-screen tile.
		C.New("UIGradient", flash, {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.45),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 0.45),
			}),
		})
		-- Edge glow: four gradients fading toward the centre (top, bottom, left, right).
		for i, spec in ipairs({
			{ UDim2.new(1, 0, S.EdgeFraction, 0), UDim2.fromScale(0, 0), 90 },
			{ UDim2.new(1, 0, S.EdgeFraction, 0), UDim2.fromScale(0, 1 - S.EdgeFraction), -90 },
			{ UDim2.new(S.EdgeFraction, 0, 1, 0), UDim2.fromScale(0, 0), 0 },
			{ UDim2.new(S.EdgeFraction, 0, 1, 0), UDim2.fromScale(1 - S.EdgeFraction, 0), 180 },
		}) do
			local edge = frame(front, "EdgeGlow", { Size = spec[1], Position = spec[2], Visible = false })
			C.New("UIGradient", edge, { Rotation = spec[3], Transparency = fade(0, 1) })
			edges[i] = edge
		end
		wheel = frame(back, "LightRays", { AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
		for i = 1, config.Caps.Rays do
			local ray = frame(wheel, "LightRay", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, if i % 2 == 0 then 0.014 else 0.024),
				Rotation = i * 180 / config.Caps.Rays,
				BackgroundColor3 = white,
			})
			C.New("UIGradient", ray, {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.42, 0.25),
					NumberSequenceKeypoint.new(0.5, 0.6),
					NumberSequenceKeypoint.new(0.58, 0.25),
					NumberSequenceKeypoint.new(1, 1),
				}),
			})
			rays[i] = ray
		end
		for i = 1, config.Caps.ScreenRings do
			local ring = frame(back, "Shockwave", { AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
			C.New("UICorner", ring, { CornerRadius = UDim.new(1, 0) })
			rings[i] = { Frame = ring, Stroke = C.New("UIStroke", ring, { Thickness = 6, Transparency = 1 }) }
		end
		text = C.Text(back, "", UDim2.new(0.8, 0, 0, 56), UDim2.fromScale(0.5, S.TextY), 52)
		text.Name, text.AnchorPoint, text.Visible = "RarityStinger", Vector2.new(0.5, 0.5), false
		textScale = C.New("UIScale", text, { Scale = 1 })
		textStroke = text:FindFirstChildOfClass("UIStroke")
		for i = 1, config.Caps.ScreenConfetti do
			-- Deterministic spread; no per-frame or per-flush allocation.
			local piece = frame(front, "ConfettiPiece", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(if i % 3 == 0 then 9 else 12, if i % 2 == 0 then 16 else 12),
				Visible = false,
			})
			-- Rounded streamers, never square tiles.
			C.New("UICorner", piece, { CornerRadius = UDim.new(1, 0) })
			-- Keep the centre band (item card, comic word, world labels) mostly clear.
			local x = (i * GOLDEN) % 1
			local band = S.ConfettiClear
			if math.abs(x - 0.5) < band then
				x = if x < 0.5 then x - band else x + band
				x = math.clamp(x, 0.02, 0.98)
			end
			confetti[i] = {
				Frame = piece,
				X = x,
				Delay = ((i * 0.37) % 1) * 0.6,
				Speed = 0.38 + ((i * 0.53) % 1) * 0.35,
				Sway = 0.015 + ((i * 0.29) % 1) * 0.03,
				Phase = i * 1.7,
				Spin = (if i % 2 == 0 then 1 else -1) * (180 + (i * 37) % 260),
			}
		end
		for i = 1, config.Caps.Coins do
			local coin = C.Icon(front, "Coin", UDim2.fromOffset(30, 30))
			coin.Name, coin.AnchorPoint, coin.Visible = "FlyingCoin", Vector2.new(0.5, 0.5), false
			coins[i] = { Frame = coin, Bend = ((i * GOLDEN) % 1 - 0.5) * 2 }
		end
		-- Comic burst: soft translucent round halos behind a huge outlined word ("SPLASH!").
		-- Drawn above every other overlay so emoji pops and coins never cover the word.
		comic = frame(front, "ComicBurst", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(S.ComicSize * 4, S.ComicSize * 1.6),
			ZIndex = front.ZIndex + S.ComicZOffset,
			Visible = false,
		})
		comicScale = C.New("UIScale", comic, { Scale = 1 })
		comicStars = {}
		for i, halo in ipairs(S.ComicHalos) do
			local star = frame(comic, "ComicHalo", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(S.ComicSize * 4 * halo.Width, S.ComicSize * 1.6 * halo.Height),
				BackgroundTransparency = halo.Transparency,
			})
			C.New("UICorner", star, { CornerRadius = UDim.new(1, 0) })
			-- Fades toward the rim, so the halo reads as a glow rather than a tile.
			C.New("UIGradient", star, {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			})
			comicStars[i] = { Frame = star, Base = halo.Transparency }
		end
		comicText = C.Text(comic, "", UDim2.fromScale(1, 1), UDim2.new(), S.ComicSize)
		comicText.ZIndex = comic.ZIndex + 4
		comicText.Name = "ComicWord"
		comicText.UITextSizeConstraint.MinTextSize = 24
		comicText.Rotation = 0
		comicStroke = comicText:FindFirstChildOfClass("UIStroke")
		if comicStroke then
			comicStroke.Thickness = 5
		end
		for i = 1, config.Caps.EmojiPops do
			local label = C.New("TextLabel", front, {
				Name = "EmojiPop",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(S.EmojiSize, S.EmojiSize),
				BackgroundTransparency = 1,
				TextScaled = true,
				Font = C.Font,
				Text = "",
				Visible = false,
			})
			-- Background-less glyph with a soft outline (no filled tile behind it).
			C.New("UIStroke", label, { Color = C.Ink, Thickness = 1.5, Transparency = 0.35 })
			emojis[i] = {
				Label = label,
				-- Deterministic fountain spread: angle, speed and spin per slot.
				-- Fan out to both sides, never straight up over the card and comic word.
				Angle = -math.pi / 2
					+ (if i % 2 == 0 then 1 else -1) * (S.EmojiClear + ((i * GOLDEN) % 1) * S.EmojiFan),
				Speed = 0.55 + ((i * 0.61) % 1) * 0.45,
				Spin = (if i % 2 == 0 then 1 else -1) * (90 + (i * 53) % 200),
				Delay = ((i * 0.43) % 1) * 0.18,
			}
		end
	end
	local function hideAll()
		if not back then
			return
		end
		back.Visible, front.Visible = false, false
		flash.Visible, wheel.Visible, text.Visible = false, false, false
		for _, edge in ipairs(edges) do
			edge.Visible = false
		end
		for _, ring in ipairs(rings) do
			ring.Frame.Visible = false
		end
		for _, piece in ipairs(confetti) do
			piece.Frame.Visible = false
		end
		for _, coin in ipairs(coins) do
			coin.Frame.Visible = false
		end
		comic.Visible = false
		for _, pop in ipairs(emojis) do
			pop.Label.Visible = false
		end
		if grade then
			grade.Enabled = false
		end
	end
	local function pulseWallet()
		wallet = wallet or hud.Frame:FindFirstChild("Wallet")
		if not wallet then
			return
		end
		walletScale = walletScale or C.New("UIScale", wallet, { Name = "FlushFxPulse", Scale = 1 })
		walletScale.Scale = 1.14
		C.Tween(walletScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	local function walletPoint()
		wallet = wallet or hud.Frame:FindFirstChild("Wallet")
		if not wallet then
			return nil
		end
		local position, size, origin = wallet.AbsolutePosition, wallet.AbsoluteSize, root.AbsolutePosition
		return position.X - origin.X + size.X * 0.15, position.Y - origin.Y + size.Y * 0.5
	end

	-- origin: { X, Y } in root pixels where the toilet appears (or screen centre).
	function self:Play(plan, color, item, origin, coinAmount)
		if not back then
			build()
		end
		hideAll()
		local size = root.AbsoluteSize
		local state = { Plan = plan, Color = color, Start = os.clock(), Origin = origin, Size = size }
		local hasCoins = type(coinAmount) == "number" and coinAmount > 0 and plan.Coins > 0
		local target = if hasCoins then { walletPoint() } else {}
		state.Coins = if hasCoins and target[1] then plan.Coins else 0
		state.Wallet = target
		state.Arrived = 0
		local any = plan.Flash > 0
			or plan.Vignette > 0
			or plan.Rays > 0
			or plan.ScreenRings > 0
			or plan.ScreenConfetti > 0
			or plan.RarityText
			or state.Coins > 0
			or plan.Grade > 0
			or plan.Comic
			or (plan.EmojiPops or 0) > 0
		if not any then
			return false
		end
		local style = config.Styles[plan.Style] or config.Styles[config.DefaultStyle]
		local seed = plan.Seed or 0.5
		if plan.Comic then
			local first = style.Palette[1]
			local last = style.Palette[#style.Palette]
			comicText.Text = plan.Word or style.Words[1]
			-- Gold for small drops, the rarity colour for rarer ones; a thick dark outline keeps
			-- the word readable on any sky.
			local gold = config.Colors.Gold
			comicText.TextColor3 = if plan.Rank >= 2
				then color:Lerp(white, 0.35)
				else Color3.fromRGB(gold[1], gold[2], gold[3]):Lerp(white, 0.25)
			comicText.UITextSizeConstraint.MaxTextSize = math.floor(S.ComicSize * (plan.ComicScale or 1))
			for i, halo in ipairs(comicStars) do
				local tone = if i % 2 == 1 then first else last
				halo.Frame.BackgroundColor3 = Color3.fromRGB(tone[1], tone[2], tone[3])
			end
			if comicStroke then
				comicStroke.Color = C.Ink
			end
			-- Lean left or right, above the toilet, clamped on screen.
			state.ComicTilt = (seed - 0.5) * 24
			state.ComicFit = math.min(1, size.X * 0.9 / (S.ComicSize * 4 * (plan.ComicScale or 1) * 1.2))
			-- Beside and above the toilet, never over the Flush prompt below the bowl; below the
			-- result block band and the rarity stinger; fully on screen.
			local half = S.ComicSize * 2 * (plan.ComicScale or 1) * 1.2 * state.ComicFit
			local side = if seed < 0.5 then -1 else 1
			local x =
				math.clamp(origin[1] + side * S.ComicSide * size.X, half + 8, math.max(half + 8, size.X - half - 8))
			local top = if plan.RarityText then S.TextY + 0.08 else 0.2
			local y = math.clamp(origin[2] - size.Y * S.ComicRise, size.Y * top, size.Y * 0.6)
			comic.Position = UDim2.fromOffset(x, y)
			comic.Visible = false
		end
		for i, pop in ipairs(emojis) do
			pop.Label.Visible = false
			local glyph = style.Emojis[(i - 1) % #style.Emojis + 1]
			-- Only glyphs known to render without a square picture tile.
			pop.Label.Text = if table.find(config.SafeEmojis, glyph) then glyph else config.SafeEmojis[3]
		end
		flash.BackgroundColor3 = white:Lerp(color, 0.45)
		flash.BackgroundTransparency, flash.Visible = 1, plan.Flash > 0
		for _, edge in ipairs(edges) do
			edge.BackgroundColor3, edge.BackgroundTransparency, edge.Visible = color, 1, plan.Vignette > 0
		end
		local span = math.max(size.X, size.Y) * 1.6
		wheel.Size = UDim2.fromOffset(span, span)
		wheel.Position = UDim2.fromScale(0.5, 0.42)
		wheel.Visible = plan.Rays > 0
		for i, ray in ipairs(rays) do
			ray.Visible = i <= plan.Rays
			ray.BackgroundColor3 = if i % 2 == 0 then white:Lerp(color, 0.25) else color
			ray.BackgroundTransparency = 1
		end
		for i, ring in ipairs(rings) do
			ring.Frame.Visible = false
			ring.Frame.Position = UDim2.fromOffset(origin[1], origin[2])
			ring.Stroke.Color = if i % 2 == 0 then white else color
		end
		if plan.RarityText then
			text.Text = string.upper(item.Rarity) .. "!"
			text.TextColor3 = color:Lerp(white, 0.15)
			text.TextTransparency, text.Visible = 1, false
		end
		for i, piece in ipairs(confetti) do
			piece.Frame.Visible = false
			piece.Frame.BackgroundColor3 = if i % 3 == 0
				then white
				elseif i % 3 == 1 then color
				else Color3.fromRGB(config.Colors.Gold[1], config.Colors.Gold[2], config.Colors.Gold[3])
		end
		if plan.Grade > 0 then
			grade = grade or C.New("ColorCorrectionEffect", Lighting, { Name = "FlushFxGrade", Enabled = false })
			grade.Enabled = true
		end
		back.Visible = plan.Rays > 0 or plan.ScreenRings > 0 or plan.RarityText
		front.Visible = true
		job = state
		lastStep = -math.huge
		self:Step(state.Start, true)
		return true
	end

	function self:Step(now, force)
		local state = job
		if not state then
			return false
		end
		local plan, t = state.Plan, now - state.Start
		local life = math.max(plan.Duration, S.CoinTime + S.CoinStagger * state.Coins + plan.Land)
		if plan.ScreenConfetti > 0 then
			life = math.max(life, plan.Burst + S.ConfettiTime)
		end
		local pace = math.max(plan.TimeScale or 1, 0.6)
		if plan.Comic then
			life = math.max(life, plan.Burst + S.ComicTime * pace)
		end
		if (plan.EmojiPops or 0) > 0 then
			life = math.max(life, plan.Burst + S.EmojiTime * pace + 0.2)
		end
		if t >= life then
			job = nil
			hideAll()
			return false
		end
		if not force and now - lastStep < 1 / config.ScreenHz then
			return true
		end
		lastStep = now
		local after = t - plan.Burst
		local size = state.Size
		if plan.Flash > 0 then
			flash.BackgroundTransparency = 1 - plan.Flash * Rules.Pulse(after, S.FlashAttack, S.FlashRelease)
		end
		if plan.Grade > 0 and grade then
			local amount = plan.Grade * Rules.Pulse(after, 0.06, math.max(0.3, plan.Duration - plan.Burst))
			grade.Brightness, grade.Contrast, grade.Saturation = amount * 0.5, amount, amount * 1.5
			grade.TintColor = white:Lerp(state.Color, amount)
		end
		if plan.Vignette > 0 then
			local release = if plan.Big
				then math.max(S.VignetteRelease, plan.Duration - plan.Burst)
				else S.VignetteRelease
			local alpha = 1 - plan.Vignette * Rules.Pulse(after, 0.1, release)
			for _, edge in ipairs(edges) do
				edge.BackgroundTransparency = alpha
			end
		end
		if plan.Rays > 0 then
			local alpha = Rules.Pulse(after, 0.15, math.max(0.3, S.RayTime - 0.15))
			wheel.Rotation = t * 14
			for i = 1, plan.Rays do
				rays[i].BackgroundTransparency = 1 - 0.55 * alpha
			end
		end
		for i = 1, plan.ScreenRings do
			local u = (after - (i - 1) * S.RingGap) / S.RingTime
			local ring = rings[i]
			ring.Frame.Visible = u >= 0 and u < 1
			if ring.Frame.Visible then
				local eased = 1 - (1 - u) ^ 3
				local diameter = math.max(size.X, size.Y) * (0.12 + 0.9 * eased)
				ring.Frame.Size = UDim2.fromOffset(diameter, diameter)
				ring.Stroke.Transparency = 0.15 + 0.85 * u
				ring.Stroke.Thickness = 10 * (1 - u) + 2
			end
		end
		if plan.RarityText then
			local u = after / S.TextTime
			text.Visible = u >= 0 and u < 1
			if text.Visible then
				-- Slam in with overshoot, hold, then float up and fade.
				textScale.Scale = if u < 0.15 then 1.9 - 0.9 * (u / 0.15) + math.sin(u / 0.15 * math.pi) * 0.12 else 1
				text.Position = UDim2.fromScale(0.5, S.TextY - math.max(0, u - 0.55) * 0.1)
				local alpha = math.clamp((u - 0.7) / 0.3, 0, 1)
				text.TextTransparency = alpha
				if textStroke then
					textStroke.Transparency = alpha
				end
			end
		end
		if plan.Comic then
			local u = after / (S.ComicTime * pace)
			comic.Visible = u >= 0 and u < 1
			if comic.Visible then
				-- Slam in big with overshoot, wobble, then pop out.
				local scale
				if u < 0.14 then
					local x = u / 0.14
					scale = 0.2 + 1.3 * x - 0.3 * x * x
				elseif u < 0.8 then
					scale = 1.2 - 0.2 * math.min(1, (u - 0.14) / 0.1) + 0.05 * math.sin(u * 40)
				else
					scale = 1 + 0.5 * (u - 0.8) / 0.2
				end
				comicScale.Scale = scale * (plan.ComicScale or 1) * (state.ComicFit or 1)
				comic.Rotation = state.ComicTilt + math.sin(u * 18) * 4 * (1 - u)
				local alpha = math.clamp((u - 0.82) / 0.18, 0, 1)
				comicText.TextTransparency = alpha
				if comicStroke then
					comicStroke.Transparency = alpha
				end
				for i, halo in ipairs(comicStars) do
					-- Halos stay translucent (never below their configured transparency).
					halo.Frame.BackgroundTransparency = halo.Base + (1 - halo.Base) * alpha
					halo.Frame.Rotation = (if i % 2 == 0 then -1 else 1) * u * 30
				end
			end
		end
		for i = 1, plan.EmojiPops or 0 do
			local pop = emojis[i]
			local u = (after - pop.Delay) / (S.EmojiTime * pace)
			pop.Label.Visible = u >= 0 and u < 1
			if pop.Label.Visible then
				-- Fountain arc out of the toilet under screen "gravity".
				local reach = math.max(size.X, size.Y) * 0.32 * pop.Speed
				local x = state.Origin[1] + math.cos(pop.Angle) * reach * u
				local y = state.Origin[2] + math.sin(pop.Angle) * reach * u * 1.6 + size.Y * 0.55 * u * u
				pop.Label.Position = UDim2.fromOffset(x, y)
				pop.Label.Rotation = pop.Spin * u
				local grow = if u < 0.15 then u / 0.15 else 1
				pop.Label.Size = UDim2.fromOffset(S.EmojiSize * (0.4 + 0.8 * grow), S.EmojiSize * (0.4 + 0.8 * grow))
				pop.Label.TextTransparency = math.clamp((u - 0.75) / 0.25, 0, 1)
			end
		end
		for i = 1, plan.ScreenConfetti do
			local piece = confetti[i]
			local u = after - piece.Delay
			local y = -0.05 + u * piece.Speed
			piece.Frame.Visible = u >= 0 and y < 1.05 and u < S.ConfettiTime
			if piece.Frame.Visible then
				piece.Frame.Position = UDim2.fromScale(piece.X + math.sin(u * 3 + piece.Phase) * piece.Sway, y)
				piece.Frame.Rotation = piece.Spin * u
				piece.Frame.BackgroundTransparency =
					math.max(S.ConfettiAlpha, math.clamp((u - S.ConfettiTime + 0.5) / 0.5, 0, 1))
			end
		end
		if state.Coins > 0 then
			local tx, ty = state.Wallet[1], state.Wallet[2]
			local ox, oy = state.Origin[1], state.Origin[2]
			for i = 1, state.Coins do
				local coin = coins[i]
				local u = (t - plan.Land - (i - 1) * S.CoinStagger) / S.CoinTime
				local flying = u >= 0 and u < 1
				if coin.Frame.Visible and not flying and u >= 1 then
					state.Arrived += 1
					pulseWallet()
				end
				coin.Frame.Visible = flying
				if flying then
					-- Quadratic curve that first bursts sideways, then accelerates into the wallet.
					local e = u * u
					local cx = (ox + tx) * 0.5 + coin.Bend * size.X * 0.18
					local cy = math.min(oy, ty) - size.Y * 0.12
					local a, b, c = (1 - e) * (1 - e), 2 * (1 - e) * e, e * e
					coin.Frame.Position = UDim2.fromOffset(a * ox + b * cx + c * tx, a * oy + b * cy + c * ty)
					local scale = 1.15 - 0.6 * e
					coin.Frame.Size = UDim2.fromOffset(30 * scale, 30 * scale)
				end
			end
		end
		return true
	end

	function self:Busy()
		return job ~= nil
	end
	function self:GradeEffect()
		return grade
	end
	function self:Stop()
		job = nil
		hideAll()
	end
	function self:Destroy()
		job = nil
		if back then
			back:Destroy()
			front:Destroy()
		end
		if grade then
			grade:Destroy()
		end
		if walletScale then
			walletScale:Destroy()
		end
		back, front, grade, walletScale = nil, nil, nil, nil
	end
	return self
end
return Screen
