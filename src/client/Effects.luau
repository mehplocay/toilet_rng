local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local Config = game.ReplicatedStorage.Shared.Config
local Items, Rarities, Events = require(Config.Items), require(Config.Rarities), require(Config.Events)
local C = require(script.Parent.UI.Components)
local Layout = require(script.Parent.UI.Layout)
local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local Visuals = require(Config.Visuals)
local upgrades = require(game.ReplicatedStorage.Shared.UpgradeRules).new(require(Config.Upgrades))
local Effects = {}
function Effects.Create(gui, _soundGroup, hud)
	local generation, skipAnimation = 0, false
	local banner = C.Card(gui, C.Gold, true)
	banner.Name, banner.Visible = "ServerEventBanner", false
	local text = C.Text(banner, "", UDim2.new(1, -16, 1, -8), UDim2.fromOffset(8, 4), 25)
	local function resize()
		C.Place(banner, Layout.Compute(gui.AbsoluteSize.X, gui.AbsoluteSize.Y, false).Event)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	local tint = C.New("ColorCorrectionEffect", Lighting, { Name = "RareDropTint" })
	local function drop(item, cooldown)
		if skipAnimation then
			return
		end
		local rarity = Rarities[item.Rarity]
		if rarity.Order < 5 then
			return
		end
		local character = game.Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local attachment = C.New("Attachment", root)
			local particles = P.Particles(attachment, "RareDropBurst", rarity.Color, 0, {
				Speed = NumberRange.new(6, 10),
				SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -10, 0),
			})
			particles:Emit(Visuals.Budget.Burst)
			Debris:AddItem(attachment, upgrades:Animation(cooldown or upgrades.Config.CooldownFloor))
		end
	end
	return {
		SetSkip = function(enabled)
			skipAnimation = enabled
			if enabled then
				C.Tween(tint, 0.1, { TintColor = Color3.new(1, 1, 1), Brightness = 0 })
			end
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
			text.Text = (if payload.Admin then "[ADMIN TEST] " else "")
				.. payload.PlayerName
				.. " found "
				.. item.Name
				.. "!\n1 in "
				.. C.Commas(item.Chance)
				.. (if payload.Admin then " • Preview" else " • Server Luck x2!")
			text.TextColor3 = if item.Rarity == "Secret"
				then Color3.fromRGB(228, 172, 255)
				else Rarities[item.Rarity].Color:Lerp(Color3.new(1, 1, 1), 0.3)
			banner.Visible = true
			hud.EventActive(true)
			if C.SoundHook then
				C.SoundHook("ServerEvent")
			end
			if C.AudioHook then
				C.AudioHook("Event", 5)
			end
			if not skipAnimation then
				C.Pop(banner)
				C.Shine(banner)
				local rgb = Events.Tints[item.Id] or Events.Tints.KingPoop
				C.Tween(tint, 0.2, {
					TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(rgb[1], rgb[2], rgb[3]), 0.3),
					Brightness = 0.025,
				})
			end
			task.delay(5, function()
				if token ~= generation then
					return
				end
				banner.Visible = false
				hud.EventActive(false)
				C.Tween(tint, 1.2, { TintColor = Color3.new(1, 1, 1), Brightness = 0 })
			end)
		end,
	}
end
return Effects
