local P = require(script.Parent.Primitives)
local Effects = require(script.Parent.Parent.Config.TemplateEffects)
local Accents = {}
function Accents.Apply(model, scale)
	local effect = Effects[model:GetAttribute("MeshAsset")]
	if not effect or model:GetAttribute("TemplateAccents") then
		return
	end
	model:SetAttribute("TemplateAccents", true)
	local cf = model:GetPivot() * CFrame.new(effect.At * (scale or 1))
	local glow = P.Ball(model, "TemplateGlow", Vector3.new(0.24, 0.14, 0.24), cf, effect.Color, Enum.Material.Neon)
	glow.Transparency = 1
	P.Light(glow, effect.Color, 7)
	P.Particles(glow, effect.Particles, effect.Color, 2, {
		Acceleration = Vector3.new(0, 0.6, 0),
		SpreadAngle = Vector2.new(100, 100),
	})
end
return Accents
