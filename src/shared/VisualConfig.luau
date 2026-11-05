--!strict
--[[
	VisualConfig.luau
	Shared configuration for the character visualization / debug tools.

	NOTES:
	- This is a developer debug tool for the game you own.
	- Nothing here tries to hide from anti-cheat or give unfair advantages.
	- Set ENABLED to false to turn the whole tool off in a release build.
]]

local VisualConfig = {
	-- Master switch for the whole debug tool.
	ENABLED = true,

	-- The key that toggles the debug overlays (local player only).
	TOGGLE_KEY = Enum.KeyCode.F3,

	-- How often (seconds) the overlay is refreshed.
	REFRESH_RATE = 0.1,

	-- Colors used by the overlays.
	BOX_COLOR = Color3.fromRGB(0, 255, 100),
	SKELETON_COLOR = Color3.fromRGB(0, 255, 255),
	LABEL_COLOR = Color3.fromRGB(255, 255, 255),
	OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),

	-- Roblox Drawing thickness and transparency settings.
	LINE_THICKNESS = 1.5,
	BOX_TRANSPARENCY = 0.55,

	-- Max distance (studs) at which overlays are drawn.
	MAX_DISTANCE = 500,
}

return VisualConfig
