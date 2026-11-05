# Roblox Character Visualization / Debug Tools

A set of legitimate developer tools for Roblox games you own or are developing. These scripts render **invisible debug overlays** including box outlines, distance labels, and character "skeleton" line highlights to help you test hitboxes, character scale, animation rigs, and line-of-sight in Studio or a live test build. These are **developer/debug tools, not cheats** — they are visible by design and fully compliant with Roblox's Terms of Service. Do not ship them to live players or use them against other developers' games.

## Install

1. Create a **ModuleScript** in `ReplicatedStorage`, name it `VisualConfig`, and paste the contents of `src/shared/VisualConfig.luau` into it.
2. Create a **Script** in `ServerScriptService`, paste `src/server/DebugVisuals.server.lua`.
3. Create a **LocalScript** in `StarterPlayer > StarterCharacterScripts` (or `StarterGui`), paste `src/client/Overlay.client.lua`.
4. In `ReplicatedStorage.VisualConfig`, set `ENABLED = true` and adjust `TOGGLE_KEY` (defaults to `Enum.KeyCode.F3`).

## Use

- Press **F3** to toggle the debug visuals on/off for yourself.
- Each other player character gets:
  - a **bounding-box outline** around their torso,
  - a **distance + name readout** floating above them,
  - a **skeleton** of lines joining head / torso / arms / legs.
- Colors come from the config (`BOX_COLOR`, `SKELETON_COLOR`, `LABEL_COLOR`, etc.).
- Overlays automatically hide beyond `MAX_DISTANCE` (default 500 studs).

Everything is intentionally **visible** — there is no attempt to be "undetectable" — that is the point of a legitimate debug tool.

---

More Roblox script projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/76f1fa2f-6735-4199-a4da-06b13ecba61e?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=76f1fa2f-6735-4199-a4da-06b13ecba61e
