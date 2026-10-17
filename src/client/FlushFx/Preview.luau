-- Studio-only flush FX previews on the Developer Tools panel. Each button calls the local
-- flush moment with a catalog item and a fake presentation payload: no remotes, no rolls,
-- no coins, no inventory change.
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.FlushFx)
local Rarities = require(Shared.Config.Rarities)
local C = require(script.Parent.Parent.UI.Components)
local Preview = {}

Preview.Spacing = 2 -- seconds between previews in the x10 run
Preview.Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godly", "Celestial", "Secret" }

function Preview.Attach(list, flushFx, items, close)
	if not RunService:IsStudio() or not list or not flushFx then
		return nil
	end
	local byRarity = {}
	for _, item in ipairs(items) do
		byRarity[item.Rarity] = byRarity[item.Rarity] or item
	end
	local order, run = 100, 0
	local function payload()
		return { ServiceCoins = 25, Preview = true }
	end
	local function add(text, callback, color)
		order += 1
		local button = C.Button(list, text, UDim2.new(1, -18, 0, 52), nil, callback, color or C.Blue, { TextSize = 20 })
		button.Name, button.LayoutOrder = "FxPreview", order
		return button
	end
	local note = C.BodyText(list, "Flush FX preview • local only, no server calls", UDim2.new(1, -18, 0, 40))
	note.LayoutOrder = order
	local api = { Buttons = {} }
	function api.Play(rarity, style)
		local item = byRarity[rarity]
		if not item then
			return nil
		end
		run += 1 -- cancels a running x10 sequence
		if close then
			close()
		end
		return flushFx:Flush(item, payload(), { Style = style })
	end
	for _, rarity in ipairs(Preview.Rarities) do
		if byRarity[rarity] and Rarities[rarity] then
			api.Buttons[rarity] = add("FX preview: " .. rarity, function()
				api.Play(rarity)
			end, Rarities[rarity].Color)
		end
	end
	-- Ten random styles back to back (the picker never repeats a style).
	function api.RandomRun(count)
		run += 1
		local token = run
		if close then
			close()
		end
		local pool = { "Common", "Common", "Uncommon", "Rare", "Epic" }
		local function step(left)
			if token ~= run or left <= 0 then
				return
			end
			local rarity = pool[math.random(1, #pool)]
			flushFx:Flush(byRarity[rarity] or byRarity.Common, payload())
			task.delay(Preview.Spacing, function()
				step(left - 1)
			end)
		end
		step(count or 10)
	end
	api.Buttons.Random = add("FX preview: random style x10", function()
		api.RandomRun(10)
	end, C.Purple)
	local selected = 1
	local cycle
	cycle = add("FX style: " .. Config.StyleOrder[selected], function()
		selected = selected % #Config.StyleOrder + 1
		cycle.Text = "FX style: " .. Config.StyleOrder[selected]
	end, C.Navy)
	api.Buttons.Style = cycle
	api.Buttons.PlayStyle = add("FX preview: play selected style", function()
		api.Play("Common", Config.StyleOrder[selected])
	end, C.Green)
	function api.Selected()
		return Config.StyleOrder[selected]
	end
	return api
end
return Preview
