local C = require(script.Parent.Components)
local Layout = require(script.Parent.Layout)
local UserInputService = game:GetService("UserInputService")
local IncomeChip = {}
function IncomeChip.Create(root)
	local chip, label = C.Chip(root, "Pending: 0", C.Navy, UDim2.fromOffset(160, 26))
	local normalMaximum = label.UITextSizeConstraint.MaxTextSize
	chip.Name = "PendingIncome"
	-- Informational only: let touches reach movement controls beneath the chip.
	chip.Active, chip.Selectable = false, false
	label.Active, label.Selectable = false, false
	label.TextColor3 = C.Gold
	label.Size, label.Position = UDim2.new(1, -8, 1, -2), UDim2.fromOffset(4, 1)
	local function resize()
		local layout = Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y, UserInputService.TouchEnabled)
		chip.Visible = not layout.Phone
		C.Place(chip, layout.PendingIncome)
		label.UITextSizeConstraint.MinTextSize = if layout.Phone then 12 else 10
		label.UITextSizeConstraint.MaxTextSize = if layout.Phone then 14 else normalMaximum
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	return {
		Update = function(pending)
			label.Text = "Pending: " .. C.Commas(pending)
			label.TextColor3 = if pending >= 1 then C.Green else C.Gold
		end,
	}
end
return IncomeChip
