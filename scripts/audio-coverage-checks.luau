-- Production mixer integration after the UI constructors and base audio tests.
do
	local config, assets = H.Load("src/shared/Config/Audio"), H.Load("src/shared/Config/Assets")
	local service = H.Load("src/client/Audio/AudioService").Start()
	service:ApplySettings(config.Defaults)
	local keys = {
		"Epic",
		"Secret",
		"RebirthSuccess",
		"Ambience",
		"RebirthHold",
		"FlushStart",
		"Flush",
		"FlushRumble",
		"DropLanding",
		"Sell",
		"SellAll",
		"SpawnArrival",
	}
	for i, key in ipairs(keys) do
		assets.Sounds[key] = tostring(800 + i)
	end -- Mock-only IDs, never persisted.
	local epic = service:Play("Epic")
	assert(epic and service.Music.Volume == 0.1 and service.Buses.Ambience.Volume == config.AmbienceDuckGain)
	local secret = service:Play("Secret")
	assert(secret and epic._dead and #service.Voices == 1)
	assert(not service:Play("Epic"), "Lesser stinger interrupted Secret")
	assert(not service:Play("Secret"), "Same stinger overlapped")
	local rebirth = service:Play("RebirthSuccess")
	assert(rebirth and secret._dead)
	rebirth.Ended:Fire()
	assert(service.Music.Volume == 0.25 and service.Buses.Ambience.Volume == 1, "Ended stinger kept ducking")
	local hold = service:Play("RebirthHold")
	assert(hold and hold.Looped and not service:Play("RebirthHold"))
	service:Stop("RebirthHold")
	assert(hold._dead)
	H.Advance(0.21)
	hold = service:Play("RebirthHold")
	H.Advance(config.HoldTimeout + 0.1)
	assert(hold._dead, "Lost hold cancellation leaked a loop")
	local ambience = service:Play("Ambience")
	assert(ambience and ambience.Looped and ambience.PlaybackSpeed == 1)
	service:Play("RebirthHold")
	service:ApplySettings({ MusicVolume = 0.5, MusicMuted = false, SFXVolume = 0.2, SFXMuted = true })
	assert(#service.Voices == 1 and service.Voices[1] == ambience and service.SFX.Volume == 0)
	assert(not service:Play("Secret"), "Muted SFX allocated a voice")
	service:ApplySettings({ MusicVolume = 0.5, MusicMuted = true, SFXVolume = 0.2, SFXMuted = false })
	assert(service.Music.Volume == 0 and service.SFX.Volume == 0.2)
	local sale = service:Play("Sell", 2)
	local bulk = service:Play("SellAll", 2000)
	assert(sale.PlaybackSpeed < bulk.PlaybackSpeed and bulk.PlaybackSpeed <= 1.24)
	H.Advance(1)
	service:Flush(false, 0.9)
	local generation = service.FlushGeneration
	service:Flush(false, 0.9)
	assert(service.FlushGeneration == generation, "Rapid flush scheduled another sound sequence")
	H.Advance(0.1)
	local swoosh
	for _, voice in ipairs(service.Voices) do
		if voice.Name == "Flush" then
			swoosh = voice
		end
	end
	assert(swoosh, "Accepted flush lost its scheduled swoosh")
	service:ApplySettings({ MusicMuted = false, MusicVolume = 0.25, SFXMuted = true, SFXVolume = 0.7 })
	service:ApplySettings(config.Defaults)
	H.Advance(1)
	for _, voice in ipairs(service.Voices) do
		assert(voice.Name ~= "DropLanding", "Unmute replayed a stale landing")
	end
	service:Flush(true, 0.9)
	service:Destroy()
	H.Advance(2)
	assert(#service.Voices == 0 and next(service.VoiceInfo) == nil and ambience._dead)
	local arrival = H.Load("src/client/Audio/AudioService").Start()
	local player, previousCharacter = H.Services.Players.LocalPlayer, H.Services.Players.LocalPlayer.Character
	local character, rootPart = H.Instance.new("Model"), H.Instance.new("Part")
	rootPart.Name, rootPart.Parent = "HumanoidRootPart", character
	player.Character = character
	arrival:_environment()
	assert(#arrival.Voices == 0, "Arrival ignored profile readiness")
	arrival:ApplySettings(config.Defaults)
	arrival:_environment()
	assert(#arrival.Voices == 2, "Arrival/optional ambience did not start once")
	arrival:_environment()
	assert(#arrival.Voices == 2, "Repeated readiness layered arrival or ambience")
	player.Character = previousCharacter
	arrival:Destroy()
	character:Destroy()
	local spatial = H.Load("src/client/Audio/AudioService").Start()
	local farPart, nearPart = H.Instance.new("Part"), H.Instance.new("Part")
	farPart.Position, nearPart.Position = Vector3.new(10000, 0, 0), H.Workspace.CurrentCamera.CFrame.Position
	farPart.Parent, nearPart.Parent = H.Workspace, H.Workspace
	local function worldSound(parent)
		local sound = H.Instance.new("Sound")
		sound.SoundId, sound.Parent = "rbxassetid://" .. assets.Sounds.Flush, parent
		H.Workspace.DescendantAdded:Fire(sound)
		return sound
	end
	local far, nearby, burst = worldSound(farPart), worldSound(nearPart), worldSound(nearPart)
	assert(far.SoundGroup == spatial.LocalFlush, "Distant flush consumed the nearby mix")
	assert(nearby.SoundGroup == spatial.WorldSFX and burst.SoundGroup == spatial.LocalFlush, "World spam gate failed")
	spatial:Destroy()
	farPart:Destroy()
	nearPart:Destroy()
	for _, key in ipairs(keys) do
		assets.Sounds[key] = ""
	end
end
do
	local C = H.Load("src/client/UI/Components")
	local previous = C.SoundHook
	local sounds = {}
	C.SoundHook = function(key)
		table.insert(sounds, key)
	end
	local root = H.Root(400, 400)
	local disabled = C.Button(root, "Slots full", UDim2.fromOffset(80, 44), nil, function()
		error("Disabled callback ran")
	end, C.Blue, { DisabledSound = "DisplayLocked" })
	disabled.Interactable = false
	C.DisabledFeedback({ disabled.Label, disabled })
	assert(#sounds == 1 and sounds[1] == "DisplayLocked")
	local blocker = C.New("TextButton", root, { Active = true })
	C.DisabledFeedback({ blocker, disabled.Label })
	assert(#sounds == 1, "Disabled feedback clicked through a modal")
	disabled.Interactable = true
	C.DisabledFeedback({ disabled.Label })
	assert(#sounds == 1)
	local tabs = C.TabBar(root, { "A", "B" }, function() end)
	tabs.Buttons.B.Activated:Fire()
	assert(sounds[#sounds] == "TabSwitch")
	local portal = H.Instance.new("Part")
	portal.Name, portal.Parent = "PortalPulse", H.Workspace
	H.Workspace.DescendantAdded:Fire(portal)
	local prompt = portal:FindFirstChild("ComingSoonAudio")
	assert(prompt and prompt.ActionText == "Coming soon")
	local calls = #H.Calls
	H.Services.ProximityPromptService.PromptTriggered:Fire(prompt)
	assert(sounds[#sounds] == "PortalLocked" and #H.Calls == calls, "Portal feedback sent a gameplay request")
	portal:Destroy()
	C.SoundHook = previous
	root:Destroy()
end
print(
	"Sound coverage runtime passed: stinger priority, ambience ducking, loop lifetime, mute, amount pitch, flush cancellation and disabled hit-testing"
)
