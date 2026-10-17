-- Local toilet motion. The server owns (and wobbles) the real toilet, so during a flush the
-- client hides it with LocalTransparencyModifier and animates a pooled visual clone instead.
-- The clone is built once per toilet model (rebuilt only after an upgrade replaces it) and
-- per-frame work is property writes only. Every exit path restores the real toilet.
local Rules = require(game.ReplicatedStorage.Shared.FlushFxRules)
local ToiletRig = {}

local STRIP = { "ProximityPrompt", "ClickDetector", "Sound", "ParticleEmitter", "Beam", "Trail", "Highlight" }
local LIGHTS = { "PointLight", "SpotLight", "SurfaceLight" }

local function classIn(object, list)
	for _, class in ipairs(list) do
		if object:IsA(class) then
			return true
		end
	end
	return false
end

local function hideable(object)
	return object:IsA("BasePart") or object:IsA("Decal") or object:IsA("Texture")
end

function ToiletRig.new(config, folder)
	local self = {}
	local cache -- { Source, Model, Parts = { { Part, Rel, Size } }, Pivot, Lid, Hidden = {} }
	local job

	local function setHidden(entry, hidden)
		for _, object in ipairs(entry.Hidden) do
			if object.Parent then
				local value = if hidden then 1 else 0
				if object:IsA("BasePart") then
					object.LocalTransparencyModifier = value
				else
					-- Decals expose the same hidden local modifier; never let a miss break a flush.
					pcall(function()
						object.LocalTransparencyModifier = value
					end)
				end
			end
		end
	end
	local function park(entry)
		-- Idle clones stay out of the world; re-parenting is cheap and allocation free.
		entry.Model.Parent = nil
	end
	local function release()
		if job then
			setHidden(job.Entry, false)
			park(job.Entry)
			job = nil
		end
	end
	local function build(source)
		if typeof(source.Clone) ~= "function" then
			return nil
		end
		local ok, model = pcall(function()
			local archivable = source.Archivable
			source.Archivable = true
			local copy = source:Clone()
			source.Archivable = archivable
			return copy
		end)
		if not ok or not model then
			return nil
		end
		model.Name = "FlushFxToilet"
		for _, object in ipairs(model:GetDescendants()) do
			if
				object:IsA("BaseScript")
				or object:IsA("ModuleScript")
				or classIn(object, STRIP)
				or classIn(object, LIGHTS)
			then
				object:Destroy()
			end
		end
		local pivot = model:GetPivot()
		local entry = { Source = source, Model = model, Parts = {}, Pivot = pivot, Hidden = {} }
		for _, object in ipairs(model:GetDescendants()) do
			if object:IsA("BasePart") then
				object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
				object.CastShadow = false
				local record = { Part = object, Rel = pivot:ToObjectSpace(object.CFrame), Size = object.Size }
				-- Ball and cylinder parts force uniform cross-sections, so they only move.
				record.Rigid = object:IsA("Part")
					and (object.Shape == Enum.PartType.Ball or object.Shape == Enum.PartType.Cylinder)
				table.insert(entry.Parts, record)
				if not entry.Lid and table.find(config.Toilet.LidNames, object.Name) then
					entry.Lid = record
				end
			end
		end
		for _, object in ipairs(source:GetDescendants()) do
			if hideable(object) then
				table.insert(entry.Hidden, object)
			end
		end
		entry.Rigid = #entry.Parts > config.Toilet.MaxParts
		return entry
	end

	local function apply(entry, base, pose, height)
		local spin = CFrame.Angles(pose.TiltX, pose.Spin, pose.TiltZ)
		local pivot = base * CFrame.new(0, pose.Lift * height, 0) * spin
		if entry.Rigid then
			entry.Model:PivotTo(pivot)
			return
		end
		local sy = pose.SquashY
		local sxz = 1 / math.sqrt(sy)
		for _, record in ipairs(entry.Parts) do
			local rel, size = record.Rel, record.Size
			local offset = CFrame.new(rel.X * sxz, rel.Y * sy, rel.Z * sxz)
			local rotation = rel.Rotation
			if record == entry.Lid and pose.Lid ~= 0 then
				-- Hinge at the back edge of the lid.
				local hinge = CFrame.new(0, -size.Y * 0.5 * sy, size.Z * 0.5 * sxz)
				rotation = rotation * hinge * CFrame.Angles(-pose.Lid, 0, 0) * hinge:Inverse()
			end
			record.Part.CFrame = pivot * offset * rotation
			if not record.Rigid then
				record.Part.Size = Vector3.new(size.X * sxz, size.Y * sy, size.Z * sxz)
			end
		end
	end

	-- Starts a motion on the owned toilet; returns true when the clone is animating.
	function self:Play(plan, target, now)
		release()
		local source = target and target.Toilet
		if not plan.Motion or not source or not source.Parent then
			return false
		end
		if not cache or cache.Source ~= source then
			if cache then
				cache.Model:Destroy()
			end
			cache = build(source)
		end
		if not cache then
			return false
		end
		local duration = math.max(0.2, plan.Duration * config.Toilet.MotionFraction)
		job = {
			Entry = cache,
			Start = now,
			Duration = duration,
			Motion = plan.Motion,
			Power = plan.ToiletPower or 1,
			Base = target.Base,
			Height = target.Height,
		}
		cache.Model.Parent = folder
		setHidden(cache, true)
		apply(cache, job.Base, Rules.ToiletPose(job.Motion, 0, job.Power), job.Height)
		return true
	end

	function self:Step(now)
		if not job then
			return false
		end
		if not job.Entry.Source.Parent then
			release()
			return false
		end
		local u = (now - job.Start) / job.Duration
		if u >= 1 then
			release()
			return false
		end
		apply(job.Entry, job.Base, Rules.ToiletPose(job.Motion, u, job.Power), job.Height)
		return true
	end

	function self:Busy()
		return job ~= nil
	end
	function self:Stop()
		release()
	end
	function self:Destroy()
		release()
		if cache then
			cache.Model:Destroy()
			cache = nil
		end
	end
	return self
end
return ToiletRig
