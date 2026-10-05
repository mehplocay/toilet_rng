local Chat = game:GetService("TextChatService")
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.PresentationRules)
local Rarities = require(Shared.Config.Rarities)
local Items = require(Shared.Config.Items)
local C = require(script.Parent.Parent.UI.Components)
local Announcements = {}
function Announcements.Start(remote)
	local self, byId = { Enabled = true }, {}
	for _, item in ipairs(Items) do
		byId[item.Id] = item
	end
	local connection = remote.OnClientEvent:Connect(function(payload)
		if not self.Enabled or type(payload) ~= "table" then
			return
		end
		local item = byId[payload.ItemId]
		if not item or not Rules.Audience(item.Rarity) then
			return
		end
		local channels = Chat:FindFirstChild("TextChannels")
		local channel = channels and channels:FindFirstChild("RBXGeneral")
		if not channel then
			return
		end -- No unbounded startup wait or replay backlog.
		local color = if item.Rarity == "Secret" then C.Purple else Rarities[item.Rarity].Color
		local text = string.format(
			'<font color="rgb(%d,%d,%d)">%s flushed a %s (1 in %s)!</font> <font color="#B9C4D5">[base check]</font>',
			math.floor(color.R * 255),
			math.floor(color.G * 255),
			math.floor(color.B * 255),
			Rules.Escape(Rules.Name(payload.PlayerName)),
			Rules.Escape(item.Name),
			C.Commas(item.Chance)
		)
		pcall(function()
			channel:DisplaySystemMessage(text, "ToiletDrop")
		end)
	end)
	function self:Destroy()
		connection:Disconnect()
	end
	return self
end
return Announcements
