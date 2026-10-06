local Previews = {}
function Previews.Start(gui, C)
	local lighting = game:GetService("Lighting")
	local config = require(game.ReplicatedStorage.Shared.Config.Admin)
	local originals, debugFolders, cosmetics = nil, {}, nil
	local function restoreLighting()
		if originals then
			for key, value in pairs(originals) do
				lighting[key] = value
			end
			originals = nil
		end
	end
	local function destroyFolder(kind)
		if debugFolders[kind] then
			debugFolders[kind]:Destroy()
			debugFolders[kind] = nil
		end
	end
	local function previewPasses(enabled)
		if cosmetics then
			cosmetics:Destroy()
			cosmetics = nil
		end
		gui:SetAttribute("AdminTestPasses", enabled)
		if not enabled then
			return
		end
		local character = game.Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		cosmetics = Instance.new("Folder")
		cosmetics.Name = "AdminCosmeticPreview"
		cosmetics.Parent = gui
		local tag = Instance.new("BillboardGui")
		tag.Name = "TestUnlocks"
		tag.Adornee = root
		tag.Size = UDim2.fromOffset(270, 95)
		tag.StudsOffset = Vector3.new(0, 4, 0)
		tag.Parent = cosmetics
		C.Text(
			tag,
			"[ADMIN TEST]\nAll passes + index cosmetics\nVIP / Trail / Color / Fast Flush",
			UDim2.fromScale(1, 1),
			nil,
			18
		)
	end
	local self = {}
	function self:Apply(action, args)
		if action == "RestoreLighting" then
			restoreLighting()
		elseif action == "Lighting" or action == "Time" then
			originals = originals or { ClockTime = lighting.ClockTime, Brightness = lighting.Brightness }
			local values = if action == "Lighting"
				then config.LightingPresets[args.Preset]
				else { ClockTime = args.Hour }
			for key, value in pairs(values) do
				lighting[key] = value
			end
		elseif action == "TestPasses" then
			previewPasses(args.Enabled)
		elseif action == "Debug" then
			destroyFolder(args.Kind)
			if not args.Enabled then
				return
			end
			local folder = Instance.new("Folder")
			folder.Name = "Admin" .. args.Kind
			folder.Parent = gui
			debugFolders[args.Kind] = folder
			local count = 0
			for _, object in ipairs(workspace:GetDescendants()) do
				if count >= config.MaxDebugAdornments then
					break
				end
				if
					object:IsA("BasePart")
					and (
						(args.Kind == "Hitboxes" and object.CanCollide)
						or (
							args.Kind == "Wayfinding"
							and (
								object.Name:find("Spawn")
								or object.Name:find("Collect")
								or object.Name:find("Arrow")
								or object.Name:find("Arrival")
							)
						)
					)
				then
					local box = Instance.new("SelectionBox")
					box.Adornee = object
					box.LineThickness = 0.03
					box.Color3 = C.Gold
					box.Parent = folder
					count += 1
				end
			end
		end
	end
	function self:Destroy()
		restoreLighting()
		destroyFolder("Hitboxes")
		destroyFolder("Wayfinding")
		previewPasses(false)
	end
	return self
end
return Previews
