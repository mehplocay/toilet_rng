local Settings = require(game.ReplicatedStorage.Shared.PresentationSettings)
local Presentation = {}
function Presentation.Start(root, hud, remotes, audio, settingsList, chat)
	local reveal = require(script.Parent.RevealController).Create(root, hud, audio)
	chat = chat or require(script.Parent.ChatAnnouncements).Start(remotes.DropAnnouncement)
	local list = require(script.Parent.PlayerList).Create(root)
	local settings = require(script.Parent.SettingsUI).Create(settingsList, remotes.PresentationSettings)
	local self = {}
	function self.Update(raw, collection)
		reveal:UpdateDiscovery(collection)
		local values = Settings.Sanitize(raw)
		-- Retain the older free quick-reveal toggle as a reduced-motion override.
		reveal:SetIntensity(
			if raw.SkipAnimation and values.RevealIntensity == "Full" then "Reduced" else values.RevealIntensity
		)
		if chat.Mode ~= values.ChatMessages then
			chat:SetMode(values.ChatMessages)
		end
		settings.Update(raw)
	end
	function self.Reveal(item, payload)
		reveal:Show(item, payload)
	end
	function self.Destroy()
		reveal:Destroy()
		chat:Destroy()
		list.Destroy()
	end
	root.Destroying:Connect(self.Destroy)
	return self
end
return Presentation
