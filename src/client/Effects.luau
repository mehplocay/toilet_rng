local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Config = game.ReplicatedStorage.Shared.Config
local Items, Rarities, Events, Assets =
	require(Config.Items), require(Config.Rarities), require(Config.Events), require(Config.Assets)
local C = require(script.Parent.UI.Components)
local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local Visuals = require(Config.Visuals)
local Effects = {}
local function commas(value)
	local text = tostring(value)
	return text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
function Effects.Create(gui, soundGroup)
	local expires, generation = 0, 0
	local luck = C.Text(gui, "", UDim2.fromScale(0.26, 0.05), UDim2.fromScale(0.71, 0.18))
	luck.TextColor3 = Color3.fromRGB(255, 225, 80)
	local banner = C.Text(gui, "", UDim2.fromScale(0.65, 0.12), UDim2.fromScale(0.02, 0.02))
	banner.Visible = false
	banner.BackgroundColor3 = C.Navy
	banner.BackgroundTransparency = 0.15
	C.Round(banner, Visuals.Palette.Gold)
	local popup = C.New("Frame", gui, {
		Visible = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 195, 35),
		BackgroundTransparency = 0.65,
		ZIndex = 20,
	})
	local title = C.Text(popup, "", UDim2.fromScale(0.65, 0.5), UDim2.fromScale(0.2, 0.22))
	title.ZIndex = 21
	title.TextColor3 = Color3.fromRGB(255, 235, 90)
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "RareDropTint"
	tint.Parent = Lighting
	local function sound(key)
		local id = Assets.Sounds[key]
		if type(id) ~= "string" or id == "" then
			return
		end
		local cue = Instance.new("Sound")
		cue.SoundId, cue.SoundGroup, cue.Parent = id, soundGroup, SoundService
		cue:Play()
		Debris:AddItem(cue, 15)
	end
	local pulseTween
	local function drop(item)
		local rarity = Rarities[item.Rarity]
		if rarity.Order >= 4 then
			sound(if rarity.Order >= 5 then "Legendary" else "Epic")
		end
		if rarity.Order < 5 then
			return
		end
		if pulseTween then
			pulseTween:Cancel()
		end
		local titleScale = title:FindFirstChildWhichIsA("UIScale") or C.New("UIScale", title, { Scale = 1 })
		titleScale.Scale = 1
		pulseTween = TweenService:Create(
			titleScale,
			TweenInfo.new(0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true),
			{ Scale = 1.05 }
		)
		pulseTween:Play()
		local character = game.Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local attachment = Instance.new("Attachment")
			attachment.Parent = root
			local particles = P.Particles(attachment, "RareDropBurst", rarity.Color, 0, {
				Speed = NumberRange.new(6, 10),
				SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -10, 0),
			})
			particles:Emit(Visuals.Budget.Burst)
			Debris:AddItem(attachment, 3)
		end
	end
	task.spawn(function()
		while gui.Parent do
			local remaining = math.max(0, math.ceil(expires - workspace:GetServerTimeNow()))
			luck.Visible = remaining > 0
			luck.Text = string.format("Server Luck x2 - %02d:%02d", math.floor(remaining / 60), remaining % 60)
			task.wait(0.25)
		end
	end)
	local activeTween
	return {
		Luck = function(value)
			expires = value
		end,
		Drop = drop,
		Event = function(payload)
			local item
			for _, candidate in ipairs(Items) do
				if candidate.Id == payload.ItemId then
					item = candidate
					break
				end
			end
			if not item then
				return
			end
			generation += 1
			local token = generation
			banner.Text = payload.PlayerName
				.. " just flushed a 1 in "
				.. commas(item.Chance)
				.. " "
				.. string.upper(item.Name)
				.. "!\nServer Luck increased for 5 minutes!"
			banner.TextColor3 = Rarities[item.Rarity].Color
			banner.Visible, popup.Visible = true, true
			title.Text = string.upper(item.Name) .. "\n1/" .. commas(item.Chance) .. "\n" .. string.upper(item.Rarity)
			if activeTween then
				activeTween:Cancel()
			end
			local rgb = Events.Tints[item.Id] or Events.Tints.KingPoop
			tint.TintColor = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
			tint.Brightness = if item.Id == "Mystery" then -0.2 else 0.05
			sound("ServerEvent")
			task.delay(3, function()
				if generation == token then
					popup.Visible = false
				end
			end)
			task.delay(Events.EffectDuration - 2, function()
				if generation ~= token then
					return
				end
				activeTween =
					TweenService:Create(tint, TweenInfo.new(2), { TintColor = Color3.new(1, 1, 1), Brightness = 0 })
				activeTween:Play()
			end)
			task.delay(Events.EffectDuration, function()
				if generation == token then
					banner.Visible = false
				end
			end)
		end,
	}
end
return Effects
