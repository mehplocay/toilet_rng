local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Rebirth = require(game.ReplicatedStorage.Shared.Config.Rebirth)
local VIPChat = {}

function VIPChat.Start()
	-- Callback members are write-only; keep a single registration in this project.
	local configuration = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
	if not configuration then
		return
	end
	local ok = pcall(function()
		TextChatService.OnChatWindowAdded = function(message)
			local sender = message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
			local tag = ""
			local level = sender and sender:GetAttribute("RebirthChatLevel")
			for _, cosmetic in ipairs(Rebirth.Cosmetics) do
				if cosmetic.Kind == "ChatTag" and cosmetic.Level == level then
					tag = string.format(
						'<font color="#%02X%02X%02X">[%s]</font> ',
						cosmetic.RGB[1],
						cosmetic.RGB[2],
						cosmetic.RGB[3],
						Rebirth.Levels[level].Title
					)
				end
			end
			if sender and (sender:GetAttribute("VIPStar") == true or tag ~= "") then
				local properties = configuration:DeriveNewMessageProperties()
				properties.PrefixText = tag
					.. (if sender:GetAttribute("VIPStar") == true
						then '<font color="#FFE164">' .. Config.VIPLabel .. "</font> "
						else "")
					.. message.PrefixText
				return properties
			end
		end
	end)
	if not ok then
		warn("VIP chat prefixes are unavailable on this chat platform; the overhead VIP star remains available.")
	end
end

return VIPChat
