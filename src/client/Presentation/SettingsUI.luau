local C = require(script.Parent.Parent.UI.Components)
local Settings = require(game.ReplicatedStorage.Shared.PresentationSettings)
local SettingsUI = {}
function SettingsUI.Create(parent, remote)
	local current = Settings.Sanitize(nil)
	local function row(name, description, order, callback)
		local card = C.Card(parent, C.Purple)
		card.Name, card.Size, card.LayoutOrder = name, UDim2.new(1, -18, 0, 116), order
		C.BodyText(card, description, UDim2.new(1, -24, 0, 48), UDim2.fromOffset(12, 6))
		return C.Button(
			card,
			"",
			UDim2.new(1, -24, 0, 44),
			UDim2.fromOffset(12, 62),
			callback,
			C.Purple,
			{ TextSize = 20 }
		)
	end
	local modes = { Full = "Reduced", Reduced = "Off", Off = "Full" }
	local intensity = row("RevealSettings", "Full effects, reduced motion, or compact results only.", 6, function()
		remote:FireServer({ RevealIntensity = modes[current.RevealIntensity] })
	end)
	local chatModes = { All = "Rare+", ["Rare+"] = "Off", Off = "All" }
	local chat = row(
		"ChatSettings",
		"Your finds in chat: all items, rare finds, or off. Rapid finds are grouped.",
		7,
		function()
			remote:FireServer({ ChatMessages = chatModes[current.ChatMessages] })
		end
	)
	local players = C.Card(parent, C.Blue)
	players.Name, players.Size, players.LayoutOrder = "PlayerListSettings", UDim2.new(1, -18, 0, 70), 8
	C.BodyText(
		players,
		"Roblox player list: Coins, Rebirths and Rarest. Press Tab or use the Roblox leaderboard icon.",
		UDim2.new(1, -24, 0, 58),
		UDim2.fromOffset(12, 6)
	)
	local function update(raw)
		current = Settings.Sanitize(raw)
		intensity.Text = "Reveal intensity: " .. current.RevealIntensity
		chat.Text = "Chat messages: " .. current.ChatMessages
	end
	update(nil)
	return { Update = update }
end
return SettingsUI
