local C = require(script.Parent.Parent.UI.Components)
local Settings = require(game.ReplicatedStorage.Shared.PresentationSettings)
local SettingsUI = {}
function SettingsUI.Create(parent, remote, toggleList)
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
	local chat = row("ChatSettings", "Show rare drop announcements in server chat.", 7, function()
		remote:FireServer({ ChatAnnouncements = not current.ChatAnnouncements })
	end)
	local players = row("PlayerListSettings", "Coins and rarest finds. Sorted by Coins. Keyboard: Tab.", 8, toggleList)
	players.Text = "Open player list"
	local function update(raw)
		current = Settings.Sanitize(raw)
		intensity.Text = "Reveal intensity: " .. current.RevealIntensity
		chat.Text = "Chat announcements: " .. (if current.ChatAnnouncements then "ON" else "OFF")
	end
	update(nil)
	return { Update = update }
end
return SettingsUI
