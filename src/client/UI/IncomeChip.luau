local C = require(script.Parent.Components)
local Layout = require(script.Parent.Layout)
local UserInputService = game:GetService("UserInputService")
local IncomeChip = {}
function IncomeChip.Create(root)
	local chip, label = C.Chip(root, "Pending: 0", C.Navy, UDim2.fromOffset(160, 26))
	chip.Name = "PendingIncome"
	label.TextColor3 = C.Gold
	label.Size, label.Position = UDim2.new(1, -8, 1, -2), UDim2.fromOffset(4, 1)
	local function resize()
		local layout = Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y, UserInputService.TouchEnabled)
		C.Place(chip, layout.PendingIncome)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	return {
		Update = function(pending)
			label.Text = "Pending: " .. C.Commas(pending)
		end,
	}
end
return IncomeChip
