local P = require(script.Parent.Primitives)
local Effects = require(script.Parent.Parent.Config.TemplateEffects)
local Accents = {}
function Accents.Apply(model)
	local effect = Effects[model:GetAttribute("MeshAsset")]
	if not effect or model:GetAttribute("TemplateAccents") then
		return
	end
	model:SetAttribute("TemplateAccents", true)
	local cf = model:GetPivot() * CFrame.new(effect.At)
	local glow = P.Ball(model, "TemplateGlow", Vector3.new(0.24, 0.14, 0.24), cf, effect.Color, Enum.Material.Neon)
	P.Light(glow, effect.Color, 7)
	if effect.Bubbles then
		-- Three tiny geometry bubbles avoid a new texture upload. Existing idle culling animates them.
		for i = 1, 3 do
			local bubble = P.Ball(
				nil,
				"RadioactiveBubble",
				Vector3.new(0.18, 0.18, 0.18),
				cf * CFrame.new((i - 2) * 0.35, i * 0.2, -0.1),
				effect.Color,
				Enum.Material.Neon
			)
			bubble.Transparency = 0.25
			bubble:SetAttribute("IdleBob", 0.35)
			bubble.Parent = model
		end
	else
		P.Particles(glow, effect.Particles, effect.Color, 2, {
			Acceleration = Vector3.new(0, 0.6, 0),
			SpreadAngle = Vector2.new(100, 100),
		})
	end
end
return Accents
