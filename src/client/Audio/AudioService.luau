local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = game.ReplicatedStorage.Shared.Config
local Assets, Audio = require(Config.Assets), require(Config.Audio)
local Settings = require(game.ReplicatedStorage.Shared.AudioSettings)
local Mix = require(script.Parent.Mix)
local Service = {}
Service.__index = Service

local function assetId(value)
	if type(value) == "number" and value > 0 and value < math.huge and value % 1 == 0 then
		value = string.format("%.0f", value)
	end
	if type(value) ~= "string" or value:match("^%s*$") then
		return nil
	end
	local digits = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
	local number = digits and tonumber(digits)
	return if number and number > 0 and number < math.huge then "rbxassetid://" .. digits else nil
end
local function group(name, parent, volume)
	local object = Instance.new("SoundGroup")
	object.Name, object.Volume, object.Parent = name, volume, parent
	return object
end
function Service:_fade(object, duration, props, style)
	if self.Tweens[object] then
		self.Tweens[object]:Cancel()
	end
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration, style or Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
		props
	)
	self.Tweens[object] = tween
	tween:Play()
	return tween
end
function Service:_sound(id, bus, gain, looped)
	local sound = Instance.new("Sound")
	sound.SoundId, sound.SoundGroup = id, bus
	sound.Volume, sound.Looped = gain, looped or false
	sound.Parent = SoundService
	return sound
end
function Service:_mix()
	local duck = Mix.DuckGain(self.Ducks, os.clock(), Audio.DuckGain)
	local target = if self.Ready then Mix.Volume(self.Settings.MusicVolume, self.Settings.MusicMuted, duck) else 0
	if target ~= self.MusicTarget then
		self.MusicTarget = target
		self.PauseGeneration = (self.PauseGeneration or 0) + 1
		local token = self.PauseGeneration
		if target > 0 and self.MusicPaused then
			self.MusicPaused = false
			for _, sound in pairs({ self.Current, self.Outgoing }) do
				sound:Resume()
			end
		end
		local tween = self:_fade(
			self.Music,
			if target == 0 then Audio.StopFade else (if duck < 1 then Audio.DuckAttack else Audio.DuckRelease),
			{ Volume = target },
			Enum.EasingStyle.Sine
		)
		if target == 0 then
			tween.Completed:Once(function()
				if not self.Destroyed and token == self.PauseGeneration and self.MusicTarget == 0 then
					for _, sound in pairs({ self.Current, self.Outgoing }) do
						sound:Pause()
					end
					self.MusicPaused = true
				end
			end)
		end
	end
	local sfx = if self.Ready then Mix.Volume(self.Settings.SFXVolume, self.Settings.SFXMuted) else 0
	if sfx ~= self.SFXTarget then
		self.SFXTarget = sfx
		self:_fade(self.SFX, Audio.StopFade, { Volume = sfx })
	end
	local ambience = if duck < 1 then Audio.AmbienceDuckGain else 1
	if ambience ~= self.AmbienceTarget then
		self.AmbienceTarget = ambience
		self:_fade(self.Buses.Ambience, if duck < 1 then Audio.DuckAttack else Audio.DuckRelease, { Volume = ambience })
	end
	if duck ~= self.LastDuck then
		self.LastDuck = duck
		self:_fade(self.Equalizer, Audio.DuckRelease, { HighGain = if duck < 1 then -4 else 0 })
	end
end
function Service:Duck(key, duration)
	if self.Destroyed then
		return
	end
	Mix.DuckUntil(self.Ducks, key, os.clock(), duration)
	self:_mix()
end
function Service:ApplySettings(raw)
	if self.Destroyed then
		return
	end
	self.Settings, self.Ready = Settings.Sanitize(raw, Audio.Defaults), true
	if self.Settings.SFXMuted or self.Settings.SFXVolume <= 0 then
		self.FlushGeneration = (self.FlushGeneration or 0) + 1
		for _, sound in ipairs(table.clone(self.Voices)) do
			self:_forget(sound)
		end
	end
	self:_mix()
	self:_environment()
	if not self.MusicStarted then
		self.MusicStarted = true
		task.spawn(function()
			self:_playlist()
		end)
	end
end
function Service:Preview(bus)
	if bus == "SFX" then
		return self:Play("PurchaseSuccess") ~= nil
	end
	if bus ~= "Music" or not self.Ready or self.Settings.MusicMuted or self.Settings.MusicVolume <= 0 then
		return false
	end
	-- Preview the actual playlist at the saved mix; never bypass mute or ducking.
	-- A separate music sample would double the bed and misrepresent its level.
	self:_mix()
	if self.Current and self.Current.IsLoaded and self.Current.IsPlaying then
		return true
	end
	return false
end
function Service:Play(key, amount, volumeScale)
	if self.Destroyed or not self.Ready or self.Settings.SFXMuted or self.Settings.SFXVolume <= 0 then
		return
	end
	local cue, id = Audio.Cues[key], assetId(Assets.Sounds[key])
	if not cue or not id then
		return -- Empty/invalid IDs never allocate, request content or call Play.
	end
	if key == "Ambience" and (self.Settings.MusicMuted or self.Settings.MusicVolume <= 0) then
		return
	end
	local now = os.clock()
	local allowed, victim = Mix.Admit(Audio, key, now, self.LastCue, self.VoiceInfo)
	if not allowed then
		return
	end
	if victim then
		self:_forget(victim)
	end
	self.LastCue[key] = now
	local combo = 0
	local variation = (math.random() * 2 - 1) * cue.Variation
	if key == "CoinCollect" then
		self.Combo = if now - self.LastCoin <= Audio.ComboWindow then math.min(self.Combo + 1, 8) else 0
		if self.Combo == 0 then
			self.CoinVariation = variation
		end
		-- Keep jitter stable within a combo so each step actually rises in pitch.
		variation = self.CoinVariation
		self.LastCoin, combo = now, self.Combo
	end
	local gain = cue.Gain * Audio.ClassGains[cue.Class] * math.clamp(volumeScale or 1, 0, 1)
	local sound = self:_sound(id, self.Buses[cue.Bus], if cue.Looped then 0 else gain, cue.Looped)
	sound.Name = key
	sound.PlaybackSpeed = if cue.AmountPitch then Mix.AmountPitch(amount) else Mix.Pitch(combo, variation)
	table.insert(self.Voices, sound)
	self.VoiceInfo[sound] = { Key = key, Started = now }
	local function release()
		self:_forget(sound)
	end
	sound.Ended:Once(function()
		self:_forget(sound, true)
	end)
	if not cue.Looped then
		task.delay(cue.Length / sound.PlaybackSpeed + 0.15, release)
	elseif key == "RebirthHold" then
		task.delay(Audio.HoldTimeout, release)
	else
		task.delay(Audio.LoadTimeout, function()
			if self.VoiceInfo[sound] and not sound.IsLoaded then
				release()
			end
		end)
	end
	if cue.Duck and (volumeScale == nil or volumeScale >= 1) then
		self:Duck(sound, cue.Length / sound.PlaybackSpeed)
	end
	pcall(function()
		sound:Play()
	end)
	if cue.Looped then
		local function attack()
			if self.VoiceInfo[sound] then
				self:_fade(sound, Audio.LoopAttack, { Volume = gain }, Enum.EasingStyle.Sine)
			end
		end
		if sound.IsLoaded then
			attack()
		else
			sound.Loaded:Once(attack)
		end
	end
	return sound
end
function Service:_forget(sound, ended)
	if not self.VoiceInfo[sound] then
		return
	end
	self.VoiceInfo[sound], self.Ducks[sound] = nil, nil
	local index = table.find(self.Voices, sound)
	if index then
		table.remove(self.Voices, index)
	end
	self:_release(sound, if ended then 0 else Audio.StopFade)
	if not self.Destroyed then
		self:_mix()
	end
end
function Service:Stop(key)
	for _, sound in ipairs(table.clone(self.Voices)) do
		if self.VoiceInfo[sound].Key == key then
			self:_forget(sound)
		end
	end
end
function Service:Flush(auto, duration)
	local now = os.clock()
	if self.Destroyed or now - (self.LastFlush or -math.huge) < Audio.FlushGap then
		return
	end
	self.LastFlush = now
	self.FlushGeneration = (self.FlushGeneration or 0) + 1
	local token = self.FlushGeneration
	self:Play("FlushStart")
	self:Play("FlushRumble")
	if auto then
		self:Play("AutoFlushTick")
	end
	local function later(delay, key)
		task.delay(delay, function()
			if not self.Destroyed and token == self.FlushGeneration then
				self:Play(key)
			end
		end)
	end
	later(Audio.FlushSwooshDelay, "Flush")
	later(math.max(Audio.FlushSwooshDelay, duration or 0.32), "DropLanding")
end
function Service:_environment()
	if not self.Ready then
		return
	end
	local ambienceEnabled = not self.Settings.MusicMuted
		and self.Settings.MusicVolume > 0
		and not self.Settings.SFXMuted
		and self.Settings.SFXVolume > 0
	if not ambienceEnabled then
		self:Stop("Ambience")
		self.AmbienceAttempted = false
	end
	local character = Players.LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	if character ~= self.LastCharacter then
		self.LastCharacter = character
		self:Play("SpawnArrival")
	end
	if not self.AmbienceAttempted and ambienceEnabled then
		self.AmbienceAttempted = self:Play("Ambience") ~= nil or not assetId(Assets.Sounds.Ambience)
	end
end
function Service:_release(sound, duration)
	if not sound or self.Released[sound] or self.Releasing[sound] then
		return
	end
	local function finish()
		if self.Tweens[sound] then
			self.Tweens[sound]:Cancel()
			self.Tweens[sound] = nil
		end
		self.Releasing[sound], self.Released[sound] = nil, true
		sound:Destroy()
		if self.OnReleased and next(self.Releasing) == nil then
			self.OnReleased()
		end
	end
	if duration and duration > 0 and sound.IsPlaying then
		self.Releasing[sound] = true
		local tween = self:_fade(sound, duration, { Volume = 0 }, Enum.EasingStyle.Sine)
		tween.Completed:Once(finish)
		return
	end
	finish()
end
function Service:_loadMusic(id)
	if self.Destroyed or self.MusicPreloadBusy then
		return nil -- At most one fetch worker is alive.
	end
	local sound = self:_sound(id, self.Music, 0, true)
	self.Loading = sound
	self.MusicPreloadBusy = true
	local finished, failed = false, false
	local worker = task.spawn(function()
		local ok = pcall(function()
			ContentProvider:PreloadAsync({ sound }, function(_, status)
				failed = status ~= Enum.AssetFetchStatus.Success
			end)
		end)
		failed, finished = failed or not ok, true
	end)
	self.MusicPreloadThread = worker
	local deadline = os.clock() + Audio.LoadTimeout
	-- Successful preload can finish before IsLoaded/TimeLength become visible.
	while
		not self.Destroyed
		and not failed
		and not (sound.IsLoaded and sound.TimeLength > 0)
		and os.clock() < deadline
	do
		task.wait(0.1)
	end
	if not finished then
		pcall(task.cancel, worker)
	end
	self.MusicPreloadThread, self.MusicPreloadBusy = nil, false
	self.Loading = nil
	if self.Destroyed or failed or not sound.IsLoaded or sound.TimeLength <= 0 then
		if not self.Destroyed then
			warn("Music could not load; retrying playlist: " .. id)
		end
		self:_release(sound)
		return nil
	end
	return sound
end
function Service:_playlist()
	local tracks, gains = {}, {}
	for index, value in ipairs(Assets.Music or {}) do
		local id = assetId(value)
		if id and not table.find(tracks, id) then
			table.insert(tracks, id)
			gains[id] = Audio.MusicTrackGains[index] or 1
		end
	end
	if #tracks == 0 then
		return
	end
	while not self.Destroyed and (not game:IsLoaded() or not Players.LocalPlayer.Character) do
		task.wait(0.2)
	end
	while not self.Destroyed and self.FirstMusicPending do
		task.wait(0.1)
	end
	local bag, previous = {}, nil
	while not self.Destroyed do
		if #bag == 0 then
			bag = Mix.Shuffle(tracks, previous, math.random)
		end
		local id = if self.FirstMusic then self.FirstMusic.SoundId else bag[1]
		local firstIndex = table.find(bag, id)
		if firstIndex then
			table.remove(bag, firstIndex)
		end
		local current = self.Current
		-- Fetch only the next deck near the transition, leaving the current deck audible.
		if current then
			local fetchAt = math.max(0, current.TimeLength - Audio.Crossfade - Audio.LoadTimeout)
			while not self.Destroyed and (self.MusicTarget == 0 or current.TimePosition < fetchAt) do
				task.wait(0.2)
			end
		end
		if self.Destroyed then
			return
		end
		local nextSound = self.FirstMusic or self:_loadMusic(id)
		self.FirstMusic = nil
		if nextSound then
			self.Next = nextSound
			if current then
				local _, duration = Mix.Crossfade(math.min(current.TimeLength, nextSound.TimeLength), Audio.Crossfade)
				local start = current.TimeLength - duration
				-- Current track keeps looping if the next asset is slow/unavailable.
				while not self.Destroyed and (self.MusicTarget == 0 or current.TimePosition < start) do
					task.wait(0.2)
				end
			end
			if self.Destroyed then
				self.Next = nil
				self:_release(nextSound)
				return
			end
			self.Current, previous = nextSound, id
			self.Next = nil
			pcall(function()
				nextSound:Play()
				if self.MusicTarget == 0 then
					nextSound:Pause()
					self.MusicPaused = true
				end
			end)
			local _, fade = Mix.Crossfade(
				math.min(nextSound.TimeLength, if current then current.TimeLength else nextSound.TimeLength),
				Audio.Crossfade
			)
			self:_fade(
				nextSound,
				if current then fade else math.min(Audio.FadeIn, nextSound.TimeLength / 2),
				{ Volume = gains[id] }
			)
			if current then
				self:_fade(current, fade, { Volume = 0 })
				self.Outgoing = current
				task.wait(fade)
				self.Outgoing = nil
				self:_release(current)
			end
			if #tracks == 1 then
				return -- One configured track loops without reloading/crossfading itself.
			end
		else
			task.wait(Audio.MusicRetryDelay) -- Failed playlists cannot spin or flood fetch requests.
		end
	end
end
function Service:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	if self.MusicPreloadThread then
		pcall(task.cancel, self.MusicPreloadThread)
		self.MusicPreloadThread, self.MusicPreloadBusy = nil, false
	end
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	for object, tween in pairs(self.Tweens) do
		if not self.Releasing[object] then
			tween:Cancel()
		end
	end
	for _, sound in ipairs(table.clone(self.Voices)) do
		self:_forget(sound)
	end
	table.clear(self.Voices)
	table.clear(self.VoiceInfo)
	table.clear(self.WorldVoices)
	table.clear(self.Ducks)
	for _, sound in pairs({ self.Current, self.Loading, self.Outgoing, self.Next, self.FirstMusic }) do
		self:_release(sound, Audio.StopFade)
	end
	for _, sound in pairs(self.Preloaded) do
		self:_release(sound)
	end
	for sound, original in pairs(self.WorldSounds) do
		if sound.Parent then
			sound.SoundGroup = original or nil
		end
	end
	self.OnReleased = function()
		self.OnReleased = nil
		self.Music:Destroy()
		self.SFX:Destroy()
	end
	if next(self.Releasing) == nil then
		self.OnReleased()
	end
end
function Service.Start()
	local self = setmetatable({
		Settings = Settings.Sanitize(nil, Audio.Defaults),
		Ducks = {},
		Voices = {},
		VoiceInfo = {},
		Releasing = {},
		Released = setmetatable({}, { __mode = "k" }),
		Preloaded = {},
		LastCue = {},
		Connections = {},
		Tweens = setmetatable({}, { __mode = "k" }),
		WorldSounds = setmetatable({}, { __mode = "k" }),
		WorldVoices = {},
		Combo = 0,
		LastCoin = -math.huge,
	}, Service)
	self.Music = group("Music", SoundService, 0)
	self.SFX = group("ToiletSounds", SoundService, 0)
	self.Buses = {}
	for _, name in ipairs({ "UI", "Rewards", "Gameplay", "Ambience" }) do
		self.Buses[name] = group(name, self.SFX, 1)
	end
	self.LocalFlush = group("LocalFlush", self.SFX, 0)
	self.WorldSFX = group("NearbyFlushes", self.SFX, Audio.WorldFlushGain)
	self.Equalizer = Instance.new("EqualizerSoundEffect")
	self.Equalizer.Name, self.Equalizer.HighGain, self.Equalizer.Parent = "RevealMix", 0, self.Music
	local function register(object)
		if object:IsA("Sound") and self.WorldSounds[object] == nil then
			self.WorldSounds[object] = object.SoundGroup or false
			object.SoundGroup = self.SFX
			-- The owner's result cue replaces the existing replicated world flush.
			-- Other players still hear its positional audio through the SFX bus.
			if assetId(object.SoundId) and assetId(object.SoundId) == assetId(Assets.Sounds.Flush) then
				local ancestor = object.Parent
				local own = false
				while ancestor and ancestor ~= workspace do
					if ancestor:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
						own = true
						break
					end
					ancestor = ancestor.Parent
				end
				local now, count = os.clock(), 0
				local emitter, camera = object.Parent, workspace.CurrentCamera
				local far = emitter
					and emitter:IsA("BasePart")
					and (not camera or (emitter.Position - camera.CFrame.Position).Magnitude > Audio.WorldFlushDistance)
				for sound, deadline in pairs(self.WorldVoices) do
					if deadline <= now or not sound.Parent then
						self.WorldVoices[sound] = nil
					else
						count += 1
					end
				end
				if
					own
					or far
					or count >= Audio.WorldMaxVoices
					or now - (self.LastWorldFlush or -math.huge) < Audio.WorldFlushGap
				then
					object.SoundGroup = self.LocalFlush
				else
					self.LastWorldFlush = now
					self.WorldVoices[object] = now + Audio.Cues.Flush.Length + 0.15
					object.SoundGroup = self.WorldSFX
					task.delay(Audio.Cues.Flush.Length + 0.15, function()
						self.WorldVoices[object] = nil
						if not self.Destroyed and object.Parent then
							object.SoundGroup = self.LocalFlush
						end
					end)
				end
			end
		end
	end
	table.insert(self.Connections, workspace.DescendantAdded:Connect(register))
	for _, object in ipairs(workspace:GetDescendants()) do
		register(object)
	end
	local elapsed = 0
	table.insert(
		self.Connections,
		RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed >= 0.1 then
				elapsed = 0
				self:_mix()
				self:_environment()
			end
		end)
	)
	local firstId = assetId((Assets.Music or {})[1])
	self.FirstMusicPending = firstId ~= nil
	if firstId then
		task.spawn(function()
			local sound = self:_loadMusic(firstId)
			if self.Destroyed then
				self:_release(sound)
			else
				self.FirstMusic = sound
			end
			self.FirstMusicPending = false
		end)
	end
	-- Keep silent preload holders alive so short cues stay warm. Long beds load on demand.
	task.spawn(function()
		local ids = {}
		for key, value in pairs(Assets.Sounds) do
			local id = assetId(value)
			local cue = Audio.Cues[key]
			if id and cue and cue.Length <= Audio.PreloadMaxLength and not table.find(ids, id) then
				table.insert(ids, id)
			end
		end
		-- Warm tactile/UI feedback before less frequent rewards.
		local urgent = { "Click", "Hover", "Open", "Close", "Error", "TabSwitch", "FlushStart", "Flush" }
		local order = {}
		for index, key in ipairs(urgent) do
			local id = assetId(Assets.Sounds[key])
			if id then
				order[id] = index
			end
		end
		table.sort(ids, function(a, b)
			local left, right = order[a] or math.huge, order[b] or math.huge
			return if left == right then a < b else left < right
		end)
		for i = 1, #ids, 4 do
			if self.Destroyed then
				return
			end
			local batch = {}
			for j = i, math.min(i + 3, #ids) do
				local sound = self:_sound(ids[j], self.SFX, 0, false)
				self.Preloaded[ids[j]] = sound
				table.insert(batch, sound)
			end
			pcall(function()
				ContentProvider:PreloadAsync(batch)
			end)
		end
	end)
	return self
end
return Service
