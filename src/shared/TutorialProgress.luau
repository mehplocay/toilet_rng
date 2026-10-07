-- Onboarding is a preference; it never grants or changes gameplay rewards.
local Progress = {}
function Progress.Step(profile)
	local step = profile.TutorialStep
	return if type(step) == "number" and step == step and step % 1 == 0 and step >= 1 and step <= 5 then step else 1
end
function Progress.Restore(profile, raw)
	profile.TutorialDone = type(raw) == "table" and raw.TutorialDone == true
	profile.TutorialStep = if profile.TutorialDone then 5 else Progress.Step(if type(raw) == "table" then raw else {})
	if profile.TutorialStep == 5 then
		profile.TutorialDone = true
	end
	local run = type(raw) == "table" and raw.TutorialRun
	profile.TutorialRun = if type(run) == "number"
			and run == run
			and run >= 0
			and run <= 9e15
		then math.floor(run)
		else 0
end
function Progress.Reset(profile)
	profile.TutorialDone, profile.TutorialStep = false, 1
	profile.TutorialRun = math.min(9e15, (profile.TutorialRun or 0) + 1)
end
function Progress.Dismiss(profile)
	profile.TutorialDone, profile.TutorialStep = true, 5
end
function Progress.NextStep(step, action, payload)
	if type(payload) ~= "table" or payload.Admin == true or payload.Success == false then
		return step
	end
	if step <= 2 and action == "Flush" and type(payload.ItemId) == "string" then
		return 3
	elseif
		step == 3
		and payload.Success == true
		and (action == "Sell" or (action == "Display" and type(payload.ItemId) == "string"))
	then
		return 4
	elseif step == 4 and payload.Success == true and (action == "BuyToilet" or action == "BuyUpgrade") then
		return 5
	end
	return step
end
function Progress.Record(profile, action, payload)
	if profile.TutorialDone then
		return
	end
	profile.TutorialStep = Progress.NextStep(Progress.Step(profile), action, payload)
	-- Existing permanent upgrades satisfy this goal for returning/replaying players.
	if profile.TutorialStep == 4 then
		local upgraded = (profile.ToiletTier or 1) > 1
		for _, level in pairs(profile.Upgrades or {}) do
			upgraded = upgraded or level > 0
		end
		if upgraded then
			profile.TutorialStep = 5
		end
	end
	if profile.TutorialStep == 5 then
		profile.TutorialDone = true
	end
end
return Progress
