local Chat = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.PresentationRules)
local Settings = require(Shared.PresentationSettings)
local Config = require(Shared.Config.Presentation)
local Rarities = require(Shared.Config.Rarities)
local Items = require(Shared.Config.Items)
local Rebirth = require(Shared.Config.Rebirth)
local C = require(script.Parent.Parent.UI.Components)
local Announcements = {}
function Announcements.Start(remote)
	local self, byId = { Enabled = true, Mode = "Rare+", Pending = {} }, {}
	local started, elapsed, destroyed = os.clock(), 0, false
	for _, item in ipairs(Items) do
		byId[item.Id] = item
	end
	local function readyChannel()
		if os.clock() - started < Config.ClientChatWarmup then
			return nil
		end
		local channels = Chat:FindFirstChild("TextChannels")
		-- General preserves authored rarity markup; RBXSystem has a gray decorator.
		local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChild("RBXSystem"))
		local window = Chat:FindFirstChildOfClass("ChatWindowConfiguration")
		if not channel or not channel:IsA("TextChannel") or not window then
			return nil
		end
		local ok = pcall(function()
			window.Enabled = true
			if not self.CoreReady then
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
				self.CoreReady = true
			end
		end)
		return if ok then channel else nil
	end
	local function allowed(entry)
		return self.Enabled and Settings.Allows({ ChatMessages = self.Mode }, entry.Rarity)
	end
	local function display(channel, entry)
		-- DisplaySystemMessage is client-only, unfiltered authored text, never SendAsync.
		local ok, err = pcall(function()
			channel:DisplaySystemMessage(entry.Text, entry.Metadata)
		end)
		if not ok then
			if not self.Warned then
				self.Warned = true
				warn("Rare find chat is waiting for the default chat window:", err)
			end
			return false
		end
		if entry.Sound then
			C.Sound("ChatAnnouncement")
		end
		return true
	end
	local function drain()
		if #self.Pending == 0 then
			return
		end
		local channel = readyChannel()
		while #self.Pending > 0 do
			local entry = self.Pending[1]
			if os.clock() >= entry.Expires or not allowed(entry) then
				table.remove(self.Pending, 1)
			elseif channel and display(channel, entry) then
				table.remove(self.Pending, 1)
			else
				break
			end
		end
	end
	local connection = remote.OnClientEvent:Connect(function(payload)
		if destroyed or not self.Enabled or type(payload) ~= "table" then
			return
		end
		local entry = { Expires = os.clock() + Config.ClientChatTTL, Sound = true }
		if payload.Kind == "Rebirth" then
			local level = payload.Level
			if type(level) ~= "number" or not Rebirth.Levels[level] or level < Rebirth.FriendAnnouncementLevel then
				return
			end
			entry.Rarity, entry.Metadata = "Legendary", "ToiletRebirth"
			entry.Text = string.format(
				'<font color="#FFD369">%s reached Rebirth %d: %s!</font>',
				Rules.Escape(Rules.Name(payload.PlayerName)),
				level,
				Rules.Escape(Rebirth.Levels[level].Title)
			)
		else
			local item = byId[payload.ItemId]
			if not item or (payload.Self ~= true and not Rules.Audience(item.Rarity)) then
				return
			end
			local count = payload.Count or 1
			if Rules.Integer(count) ~= count or count < 1 then
				return
			end
			local text
			if payload.Self == true then
				text = if count > 1
					then string.format(
						"You found %s items (best: %s %s)!",
						C.Commas(count),
						item.Rarity,
						Rules.Escape(item.Name)
					)
					else string.format(
						"You found %s (%s, 1 in %s)!",
						Rules.Escape(item.Name),
						item.Rarity,
						C.Commas(item.Chance)
					)
			else
				text = string.format(
					"%s found %s (%s, 1 in %s)!",
					Rules.Escape(Rules.Name(payload.PlayerName)),
					Rules.Escape(item.Name),
					item.Rarity,
					C.Commas(item.Chance)
				)
			end
			if payload.Admin == true then
				text = "[ADMIN TEST] " .. text
			end
			local color = if item.Rarity == "Secret" then C.Purple else Rarities[item.Rarity].Color
			entry.Text = string.format(
				'<font color="rgb(%d,%d,%d)">%s</font>',
				math.floor(color.R * 255),
				math.floor(color.G * 255),
				math.floor(color.B * 255),
				text
			)
			entry.Rarity, entry.Metadata, entry.Sound = item.Rarity, "ToiletDrop", not item.Event
		end
		if not allowed(entry) then
			return
		end
		drain()
		if #self.Pending >= Config.ClientChatCap then
			return
		end
		table.insert(self.Pending, entry)
		drain()
	end)
	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			drain()
		end
	end)
	function self:SetMode(mode)
		self.Mode = Settings.ChatMode({ ChatMessages = mode })
		self.Enabled = self.Mode ~= "Off"
		-- A preference change must not replay messages accepted under the old mode.
		table.clear(self.Pending)
	end
	function self:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		connection:Disconnect()
		heartbeat:Disconnect()
		table.clear(self.Pending)
	end
	return self
end
return Announcements
