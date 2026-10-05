local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
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
			if sender and sender:GetAttribute("VIPStar") == true then
				local properties = configuration:DeriveNewMessageProperties()
				properties.PrefixText = '<font color="#FFE164">' .. Config.VIPLabel .. "</font> " .. message.PrefixText
				return properties
			end
		end
	end)
	if not ok then
		warn("VIP chat prefixes are unavailable on this chat platform; the overhead VIP star remains available.")
	end
end

return VIPChat
