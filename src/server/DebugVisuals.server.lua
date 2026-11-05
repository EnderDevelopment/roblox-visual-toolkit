--!strict
--[[
	DebugVisuals.server.lua
	Place in: ServerScriptService

	Owns the character-visualization debug session. It forwards the shared
	config to clients and listens for toggle requests from the local player,
	replicating the enabled/disabled state to all clients.

	This is a legitimate developer debug tool for the game you own.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualConfig = require(ReplicatedStorage:WaitForChild("VisualConfig"))

-- Build the RemoteEvents that carry the on/off state.
local toggleEvent: RemoteEvent = ReplicatedStorage:FindFirstChild("DebugVisualToggleEvent")
if not toggleEvent then
	toggleEvent = Instance.new("RemoteEvent")
	toggleEvent.Name = "DebugVisualToggleEvent"
	toggleEvent.Parent = ReplicatedStorage
end

local stateEvent: RemoteEvent = ReplicatedStorage:FindFirstChild("DebugVisualStateEvent")
if not stateEvent then
	stateEvent = Instance.new("RemoteEvent")
	stateEvent.Name = "DebugVisualStateEvent"
	stateEvent.Parent = ReplicatedStorage
end

-- A tiny map of player -> current enabled state, so a rejoining player
-- automatically gets the correct on/off state.
local playerStates: { [Player]: boolean } = {}

local function setState(player: Player, enabled: boolean)
	playerStates[player] = enabled
	stateEvent:FireClient(player, enabled)
end

-- Client asks to toggle their own debug visuals.
toggleEvent.OnServerEvent:Connect(function(player: Player, enabledOverride: boolean?)
	if not VisualConfig.ENABLED then
		return
	end

	local current = playerStates[player] or false
	local next = enabledOverride
	if next == nil then
		next = not current
	end

	setState(player, next)
end)

-- When a player spawns, push them the shared config and their current state.
Players.PlayerAdded:Connect(function(player: Player)
	player:SetAttribute("DebugVisualsEnabled", false)
	stateEvent:FireClient(player, false)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerStates[player] = nil
end)

-- Announce the config to every newly-added player.
Players.PlayerAdded:Connect(function(player: Player)
	player:WaitForChild("PlayerGui")
	stateEvent:FireClient(player, playerStates[player] or false)
end)

-- Push initial state to players already in the game when the script starts.
for _, player: Player in ipairs(Players:GetPlayers()) do
	stateEvent:FireClient(player, playerStates[player] or false)
end
