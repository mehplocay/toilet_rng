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
			if
				sender
				and (
					sender:GetAttribute("VIPStar") == true
					or tag ~= ""
					or sender:GetAttribute("RainbowName") == true
					or sender:GetAttribute("GoldenName") == true
				)
			then
				local properties = configuration:DeriveNewMessageProperties()
				local star = if sender:GetAttribute("VIPPack") then Config.VIPLabel else "\u{2605}"
				local namePrefix = message.PrefixText
				if sender:GetAttribute("RainbowName") or sender:GetAttribute("GoldenName") then
					-- Keep Roblox-filtered content and role markup; remove native font colors that override the pass color.
					namePrefix = namePrefix:gsub("<font[^>]*>", ""):gsub("</font>", "")
				end
				-- Order: rebirth tag, one VIP/Star tag, filtered name. Tag colors survive name coloring.
				properties.PrefixText = tag
					.. (if sender:GetAttribute("VIPStar") then '<font color="#FFE164">' .. star .. "</font> " else "")
					.. namePrefix
				if sender:GetAttribute("RainbowName") or sender:GetAttribute("GoldenName") then
					local prefix = configuration:DeriveNewMessageProperties()
					prefix.TextColor3 = if sender:GetAttribute("RainbowName")
						then Color3.fromHSV((os.clock() / 6) % 1, 0.75, 1)
						else Color3.fromRGB(255, 210, 65)
					properties.PrefixTextProperties = prefix
				end
				return properties
			end
		end
	end)
	if not ok then
		warn("VIP chat prefixes are unavailable on this chat platform; the overhead VIP star remains available.")
	end
end

return VIPChat
