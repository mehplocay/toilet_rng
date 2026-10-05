-- Assignment/profile readiness gates every first load. The project also disables auto-loads.
local PlotSpawn = {}
function PlotSpawn.new(Players, scheduler, report)
	local self = { States = {} }
	local function current(player, state, character)
		return self.States[player] == state and player.Parent == Players and player.Character == character
	end
	function self:Correct(player, state, character)
		if not current(player, state, character) then
			return
		end
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root or not current(player, state, character) then
			return
		end
		-- Catch late engine placement/streaming without tethering a player who walks away.
		for attempt = 1, 5 do
			if not current(player, state, character) then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end
			if humanoid.MoveDirection.Magnitude > 0 then
				return -- Intentional movement ends the startup correction window.
			end
			if character.Parent and (root.Position - state.Plot.SpawnCFrame.Position).Magnitude > 24 then
				character:PivotTo(state.Plot.SpawnCFrame)
				root.AssemblyLinearVelocity *= 0
				root.AssemblyAngularVelocity *= 0
			end
			if attempt < 5 then
				scheduler.wait(0.5)
			end
		end
	end
	function self:Track(player, state, character)
		if state.Character == character then
			return
		end
		state.Character = character
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid or not current(player, state, character) then
			return
		end
		if state.Death then
			state.Death:Disconnect()
		end
		state.Death = humanoid.Died:Once(function()
			scheduler.delay(Players.RespawnTime, function()
				while state.Loading and self.States[player] == state do
					scheduler.wait()
				end
				if current(player, state, character) then
					self:Load(player, state)
				end
			end)
		end)
		if not state.Loading then
			scheduler.spawn(function()
				self:Correct(player, state, character)
			end)
		end
	end
	function self:Load(player, state)
		if self.States[player] ~= state or player.Parent ~= Players or state.Loading then
			return
		end
		state.Loading = true
		local ok, problem
		for attempt = 1, 3 do
			if self.States[player] ~= state or player.Parent ~= Players then
				break
			end
			ok, problem = pcall(function()
				player.RespawnLocation = state.Plot.Spawn
				player:LoadCharacterAsync()
				local character = player.Character
				if current(player, state, character) and character and character.Parent then
					character:PivotTo(state.Plot.SpawnCFrame)
					self:Track(player, state, character)
					scheduler.spawn(function()
						self:Correct(player, state, character)
					end)
				end
			end)
			if ok then
				break
			end
			if attempt < 3 then
				scheduler.wait(attempt)
			end
		end
		state.Loading = false
		if not ok and self.States[player] == state and player.Parent == Players then
			report("Plot character load failed after retries: " .. tostring(problem))
			player:Kick("Your character could not load. Please rejoin.")
		end
	end
	function self:Register(player, plot)
		if self.States[player] then
			return
		end
		local state = { Plot = plot }
		self.States[player] = state
		player.RespawnLocation = plot.Spawn
		state.Connection = player.CharacterAdded:Connect(function(character)
			self:Track(player, state, character)
		end)
		-- Solo Studio can already have a character when the server bootstrap begins.
		if player.Character then
			scheduler.spawn(function()
				self:Track(player, state, player.Character)
			end)
		end
	end
	function self:Ready(player)
		local state = self.States[player]
		if state and not state.Started then
			state.Started = true
			scheduler.spawn(function()
				self:Load(player, state)
			end)
		end
	end
	function self:Remove(player)
		local state = self.States[player]
		self.States[player] = nil
		if state then
			state.Connection:Disconnect()
			if state.Death then
				state.Death:Disconnect()
			end
		end
	end
	return self
end
-- CLI checks inject a scheduler; the game uses the same lifecycle implementation.
function PlotSpawn.Runtime()
	return PlotSpawn.new(game:GetService("Players"), task, warn)
end
return PlotSpawn
