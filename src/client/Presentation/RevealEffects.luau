local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local C = require(script.Parent.Parent.UI.Components)
local Effects = {}
function Effects.Start(color, cinematic)
	local elapsed, camera, base, written = 0, nil, nil, nil
	local tint
	if cinematic then
		tint =
			C.New("ColorCorrectionEffect", Lighting, { Name = "FlushCinematicTint", TintColor = Color3.new(1, 1, 1) })
		C.Tween(tint, 0.22, { TintColor = Color3.new(1, 1, 1):Lerp(color, 0.28), Saturation = 0.12 })
	end
	local function undo()
		if camera and camera == workspace.CurrentCamera and camera.CFrame == written then
			camera.CFrame = base
		end
		camera, base, written = nil, nil, nil
	end
	RunService:BindToRenderStep("FlushRevealUndo", 199, undo)
	RunService:BindToRenderStep("FlushRevealShake", 201, function(dt)
		elapsed += dt
		if elapsed >= 0.5 then
			return
		end
		camera = workspace.CurrentCamera
		if camera then
			base = camera.CFrame
			local strength = 0.055 * (1 - elapsed / 0.5)
			written = base
				* CFrame.Angles(math.sin(elapsed * 75) * strength * 0.25, 0, math.sin(elapsed * 53) * strength)
			camera.CFrame = written
		end
	end)
	local destroyed = false
	return function()
		if destroyed then
			return
		end
		destroyed = true
		RunService:UnbindFromRenderStep("FlushRevealUndo")
		RunService:UnbindFromRenderStep("FlushRevealShake")
		undo()
		if tint then
			C.Tween(tint, 0.2, { TintColor = Color3.new(1, 1, 1), Saturation = 0 })
			task.delay(0.2, function()
				tint:Destroy()
			end)
		end
	end
end
return Effects
