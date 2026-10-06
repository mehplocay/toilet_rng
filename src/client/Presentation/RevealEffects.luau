local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local C = require(script.Parent.Parent.UI.Components)
local Sky = require(script.Parent.RevealSky)
local Effects = {}
function Effects.Start(color, config, mobile)
	local elapsed, camera, base, written = 0, nil, nil, nil
	local tint, blur
	local releaseSky = Sky.Acquire(config)
	if config.Tier == "Cinematic" then
		tint =
			C.New("ColorCorrectionEffect", Lighting, { Name = "FlushCinematicTint", TintColor = Color3.new(1, 1, 1) })
		C.Tween(tint, 0.22, {
			TintColor = Color3.new(1, 1, 1):Lerp(color, 0.22),
			Saturation = 0.12,
			Brightness = if config.Signature == "RealityGlitch"
				then -0.16
				elseif config.Signature == "DivineCracks" then -0.1
				else 0,
		})
		if not mobile then
			blur = C.New("BlurEffect", Lighting, { Name = "RevealFocus", Size = 0 })
			C.Tween(blur, 0.3, { Size = 4 })
		end
	end
	local function undo()
		if camera and camera.CFrame == written then
			camera.CFrame = base
		end
		camera, base, written = nil, nil, nil
	end
	local shake = config.Shake or 0
	if shake > 0 then
		RunService:BindToRenderStep("FlushRevealUndo", 199, undo)
		RunService:BindToRenderStep("FlushRevealShake", 201, function(dt)
			undo()
			elapsed += dt
			if elapsed >= 0.5 then
				return
			end
			camera = workspace.CurrentCamera
			if camera then
				base = camera.CFrame
				local strength = shake * (if mobile then 0.5 else 1) * (1 - elapsed / 0.5)
				written = base
					* CFrame.Angles(math.sin(elapsed * 75) * strength * 0.25, 0, math.sin(elapsed * 53) * strength)
				camera.CFrame = written
			end
		end)
	end
	local destroyed = false
	return function()
		if destroyed then
			return
		end
		destroyed = true
		RunService:UnbindFromRenderStep("FlushRevealUndo")
		RunService:UnbindFromRenderStep("FlushRevealShake")
		undo()
		releaseSky()
		if blur then
			blur:Destroy()
		end
		if tint then
			tint:Destroy()
		end
	end
end
return Effects
