--!strict
--[[
	Overlay.client.lua
	Place in: StarterPlayer > StarterCharacterScripts (or StarterGui)

	Renders the debug overlays for the local player only:
	  - a bounding-box outline around each character's torso,
	  - a distance + name label floating above them,
	  - a "skeleton" of lines joining the main joints.

	Uses the Roblox Drawing API (studio/local client only). Everything is
	visible by design — this is a developer debug tool, not a cheat.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local VisualConfig = require(ReplicatedStorage:WaitForChild("VisualConfig"))
local toggleEvent = ReplicatedStorage:WaitForChild("DebugVisualToggleEvent")
local stateEvent = ReplicatedStorage:WaitForChild("DebugVisualStateEvent")

local localPlayer = Players.LocalPlayer
local enabled = false
local initialized = false

-- The skeleton joint pairs (Bone -> Bone) we want to draw lines between.
local SKELETON_LINKS = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}

-- Per character, we cache the Drawing objects we created. If a character
-- leaves, we clean them up.
local characterDrawings: { [Model]: { box: any, label: any, lines: { any } } } = {}

local function makeDrawing(kind: string, color: Color3, thickness: number)
	local d = Drawing.new(kind)
	d.Color = color
	d.Thickness = thickness
	d.Visible = false
	d.ZIndex = 5
	return d
end

-- Get the primary part (or root part) of a character model.
local function getPrimaryPart(model: Model): BasePart?
	local p = model.PrimaryPart
	if p then
		return p
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then
		return root
	end
	return model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
end

-- Ensure we have Drawing objects for a character.
local function getOrCreateDrawings(character: Model)
	local existing = characterDrawings[character]
	if existing then
		return existing
	end

	local box = makeDrawing("Square", VisualConfig.BOX_COLOR, VisualConfig.LINE_THICKNESS)
	local label = makeDrawing("Text", VisualConfig.LABEL_COLOR, VisualConfig.LINE_THICKNESS)
	label.Size = 16
	label.Center = true
	label.Outline = true
	label.OutlineColor = VisualConfig.OUTLINE_COLOR

	local lines: { any } = {}
	for _index, _link in ipairs(SKELETON_LINKS) do
		table.insert(lines, makeDrawing("Line", VisualConfig.SKELETON_COLOR, VisualConfig.LINE_THICKNESS))
	end

	local entry = { box = box, label = label, lines = lines }
	characterDrawings[character] = entry
	return entry
end

-- Hide every drawing for a character.
local function hideCharacter(character: Model)
	local entry = characterDrawings[character]
	if not entry then
		return
	end
	entry.box.Visible = false
	entry.label.Visible = false
	for _, line in ipairs(entry.lines) do
		line.Visible = false
	end
end

-- Clean up a character's drawings entirely.
local function destroyCharacter(character: Model)
	local entry = characterDrawings[character]
	if not entry then
		return
	end
	for _, line in ipairs(entry.lines) do
		line:Remove()
	end
	entry.box:Remove()
	entry.label:Remove()
	characterDrawings[character] = nil
end

local camera = workspace.CurrentCamera

-- Update the overlays for one character on this frame.
local function updateCharacter(character: Model, cameraPosition: Vector3)
	local entry = getOrCreateDrawings(character)
	local primary = getPrimaryPart(character)
	if not primary then
		hideCharacter(character)
		return
	end

	local distance = (primary.Position - cameraPosition).Magnitude
	if distance > VisualConfig.MAX_DISTANCE then
		hideCharacter(character)
		return
	end

	-- Bounding box: project the primary part's size onto the screen.
	local size = primary.Size
	local cframe = primary.CFrame

	local corners = {
		cframe * CFrame.new(-size.X / 2, size.Y / 2, -size.Z / 2),
		cframe * CFrame.new(size.X / 2, size.Y / 2, -size.Z / 2),
		cframe * CFrame.new(size.X / 2, -size.Y / 2, -size.Z / 2),
		cframe * CFrame.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
	}

	local screen: { Vector2 } = {}
	local allVisible = true
	for _, corner in ipairs(corners) do
		local p = camera:WorldToViewportPoint(corner.Position)
		if p.Z < 0 then
			allVisible = false
		end
		table.insert(screen, Vector2.new(p.X, p.Y))
	end

	if allVisible then
		entry.box.Visible = true
		entry.box.Transparency = VisualConfig.BOX_TRANSPARENCY
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		for _, pt in ipairs(screen) do
			minX = math.min(minX, pt.X)
			minY = math.min(minY, pt.Y)
			maxX = math.max(maxX, pt.X)
			maxY = math.max(maxY, pt.Y)
		end
		entry.box.Position = Vector2.new(minX, minY)
		entry.box.Size = Vector2.new(maxX - minX, maxY - minY)
	else
		entry.box.Visible = false
	end

	-- Skeleton lines between joints.
	local name = character.Name
	local charState = nil
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character == character then
			charState = player
			break
		end
	end
	local displayName = charState and charState.DisplayName or name

	for i, link in ipairs(SKELETON_LINKS) do
		local line = entry.lines[i]
		local a = character:FindFirstChild(link[1])
		local b = character:FindFirstChild(link[2])
		if a and b then
			local pa = camera:WorldToViewportPoint(a.Position)
			local pb = camera:WorldToViewportPoint(b.Position)
			if pa.Z > 0 and pb.Z > 0 then
				line.Visible = true
				line.From = Vector2.new(pa.X, pa.Y)
				line.To = Vector2.new(pb.X, pb.Y)
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end

	-- Distance label above the character.
	local head = character:FindFirstChild("Head")
	local anchor = head and head.Position or (primary.Position + Vector3.new(0, 3, 0))
	local p = camera:WorldToViewportPoint(anchor)
	if p.Z > 0 then
		entry.label.Visible = true
		entry.label.Position = Vector2.new(p.X, p.Y - 24)
		entry.label.Text = string.format("%s  (%.1f studs)", displayName, distance)
	else
		entry.label.Visible = false
	end
end

-- Track characters entering/leaving the workspace.
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and descendant:FindFirstChildOfClass("Humanoid") then
		getOrCreateDrawings(descendant)
	end
end)

-- Character removed: destroy its drawings.
local function onCharacterRemoving(character: Model)
	destroyCharacter(character)
end

-- Watch the local player and all other players for character changes.
local function watchPlayer(player: Player)
	if player.Character then
		player.Character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				onCharacterRemoving(player.Character)
			end
		end)
	end
	player.CharacterAdded:Connect(function(character)
		character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				onCharacterRemoving(character)
			end
		end)
	end)
end

watchPlayer(localPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		watchPlayer(player)
	end
end
Players.PlayerAdded:Connect(watchPlayer)

-- Toggle input.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if not initialized then
		return
	end
	if gameProcessed then
		return
	end
	if input.KeyCode == VisualConfig.TOGGLE_KEY then
		toggleEvent:FireServer()
	end
end)

-- Server tells us our on/off state.
stateEvent.OnClientEvent:Connect(function(state: boolean)
	enabled = state and VisualConfig.ENABLED
	if not enabled then
		for character in pairs(characterDrawings) do
			hideCharacter(character)
		end
	end
end)

-- The frame loop that updates all overlays.
RunService.RenderStepped:Connect(function()
	if not VisualConfig.ENABLED or not enabled then
		return
	end

	local cameraPosition = camera.CFrame.Position
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local character = player.Character
			if character then
				updateCharacter(character, cameraPosition)
			end
		end
	end
end)

-- Clean up all drawings when the client shuts down.
game:BindToClose(function()
	for character in pairs(characterDrawings) do
		destroyCharacter(character)
	end
end)

initialized = true
