local Players = game:GetService("Players")
local PlotSpawn = { States = {} }

function PlotSpawn:Load(player, state)
	if self.States[player] ~= state or player.Parent ~= Players or state.Loading then
		return
	end
	state.Loading = true
	local ok, problem = pcall(function()
		player.RespawnLocation = state.Plot.Spawn
		player:LoadCharacterAsync()
		-- The engine places/scales the rig after CharacterAdded; pivot after loading returns.
		local character = player.Character
		if self.States[player] == state and character and character.Parent then
			character:PivotTo(state.Plot.SpawnCFrame)
		end
	end)
	state.Loading = false
	if not ok and self.States[player] == state and player.Parent == Players then
		warn("Plot character load failed: " .. tostring(problem))
		player:Kick("Your character could not load. Please rejoin.")
	end
end

function PlotSpawn:Register(player, plot)
	local state = { Plot = plot }
	self.States[player] = state
	player.RespawnLocation = plot.Spawn
	state.Connection = player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid or self.States[player] ~= state then
			return
		end
		if state.Death then
			state.Death:Disconnect()
		end
		state.Death = humanoid.Died:Once(function()
			task.delay(Players.RespawnTime, function()
				while state.Loading and self.States[player] == state do
					task.wait()
				end
				if player.Character == character then
					self:Load(player, state)
				end
			end)
		end)
	end)
end

function PlotSpawn:Ready(player)
	local state = self.States[player]
	if state and not state.Started then
		state.Started = true
		task.spawn(function()
			self:Load(player, state)
		end)
	end
end

function PlotSpawn:Remove(player)
	local state = self.States[player]
	self.States[player] = nil
	if state then
		state.Connection:Disconnect()
		if state.Death then
			state.Death:Disconnect()
		end
	end
end

return PlotSpawn
