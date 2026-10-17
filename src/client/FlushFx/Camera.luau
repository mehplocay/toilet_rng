-- Bounded flush camera punch. Mirrors RevealEffects: undo our last write before the camera
-- scripts (199), apply a fresh offset after them (201), unbind on every exit.
local RunService = game:GetService("RunService")
local Rules = require(game.ReplicatedStorage.Shared.FlushFxRules)
local Camera = {}
local UNDO, APPLY = "FlushFxCameraUndo", "FlushFxCameraApply"
function Camera.new(config)
	local self = {}
	local plan, started, bound = nil, 0, false
	local camera, baseFov, writtenFov, baseCFrame, writtenCFrame
	local function undo()
		if camera then
			-- Restore only what we wrote; any other writer (zoom, other scripts) wins.
			if writtenFov and camera.FieldOfView == writtenFov then
				camera.FieldOfView = baseFov
			end
			if writtenCFrame and camera.CFrame == writtenCFrame then
				camera.CFrame = baseCFrame
			end
		end
		camera, baseFov, writtenFov, baseCFrame, writtenCFrame = nil, nil, nil, nil, nil
	end
	local function unbind()
		if bound then
			bound = false
			RunService:UnbindFromRenderStep(UNDO)
			RunService:UnbindFromRenderStep(APPLY)
		end
		undo()
	end
	local function apply()
		undo()
		if not plan then
			return
		end
		local t = os.clock() - started
		if t >= plan.Duration then
			plan = nil
			unbind()
			return
		end
		camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local offset = Rules.FovOffset(plan, t, config.Camera)
		if offset ~= 0 then
			baseFov = camera.FieldOfView
			camera.FieldOfView = math.clamp(baseFov + offset, 1, 120)
			-- Read back: the engine stores FieldOfView at reduced precision.
			writtenFov = camera.FieldOfView
		end
		local after = t - plan.Burst
		if plan.Shake > 0 and after >= 0 and after < config.Camera.ShakeTime then
			local strength = plan.Shake * (1 - after / config.Camera.ShakeTime)
			baseCFrame = camera.CFrame
			camera.CFrame = baseCFrame
				* CFrame.Angles(math.sin(after * 71) * strength * 0.4, 0, math.sin(after * 57) * strength)
			writtenCFrame = camera.CFrame
		end
	end
	function self:Play(newPlan)
		if newPlan.Fov <= 0 and newPlan.Shake <= 0 then
			return
		end
		plan, started = newPlan, os.clock()
		if not bound then
			bound = true
			RunService:BindToRenderStep(UNDO, 199, undo)
			RunService:BindToRenderStep(APPLY, 201, apply)
		end
	end
	function self:Busy()
		return plan ~= nil
	end
	function self:Stop()
		plan = nil
		unbind()
	end
	return self
end
return Camera
