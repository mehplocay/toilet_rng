local Settings = require(game.ReplicatedStorage.Shared.PresentationSettings)
local Presentation = {}
function Presentation.Start(root, hud, remotes, audio, settingsList)
	local reveal = require(script.Parent.RevealController).Create(root, hud, audio)
	local chat = require(script.Parent.ChatAnnouncements).Start(remotes.DropAnnouncement)
	local list = require(script.Parent.PlayerList).Create(root)
	local settings = require(script.Parent.SettingsUI).Create(settingsList, remotes.PresentationSettings, list.Toggle)
	local self = {}
	function self.Update(raw)
		local values = Settings.Sanitize(raw)
		-- Retain the older free quick-reveal toggle as a reduced-motion override.
		reveal:SetIntensity(
			if raw.SkipAnimation and values.RevealIntensity == "Full" then "Reduced" else values.RevealIntensity
		)
		chat.Enabled = values.ChatAnnouncements
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
