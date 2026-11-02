# Zaridium UI: guide for AI coding agents

Read this file first. It is the shortest correct description of the library. Details live in [docs/API.md](docs/API.md),
[docs/THEMING.md](docs/THEMING.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/ICONS.md](docs/ICONS.md).

**What it is:** a Material 3 UI library for Roblox executors (Luau). One bundled file, no dependencies, Google Sans Flex font,
Material Symbols icons, ripples, tonal surfaces, a generated colour theme, notifications, dialogs, search, configs.

**What it is not:** a Roblox Studio plugin, a roblox-ts package, or a place for exploit logic. It only draws UI and stores values.

## 30-second usage

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/MidasRX/Zaridium/main/ui/dist/ZaridiumUI.lua"))()

local Window  = Library:CreateWindow({ Title = "My Hub", Icon = "bolt", Theme = { Mode = "Dark", Preset = "Violet" } })
local Tab     = Window:AddTab({ Name = "Main", Icon = "home" })
local Section = Tab:AddSection({ Title = "Movement", Icon = "speed" })

Section:AddToggle({ Text = "Fly", Flag = "fly", Default = false, Callback = function(on) print(on) end })
Section:AddSlider({ Text = "Speed", Flag = "speed", Min = 16, Max = 200, Default = 16, Suffix = " st/s" })
Library:BuildSettings(Window:AddTab({ Name = "Settings", Icon = "settings" })) -- theme + config UI for free
```

Hierarchy: `Library` -> `Window` -> `Tab` -> `Section` -> controls. Controls can only be added to a **Section**.
Never call `AddToggle` on a `Tab` or `Window`; that is the most common mistake.

## Rules an agent must follow

1. **Options are tables, not positional arguments.** `Section:AddToggle({ Text = "..." })`. A bare string is accepted only as `Text`.
2. **`Flag` makes a control persistent and addressable.** Flags must be unique. `Library.Flags.<flag>` holds the current value and
   `Library.Options.<flag>` holds the control object. Controls without a `Flag` are not saved in configs.
3. **`Callback(value)` fires on user changes and on `:Set(value)`.** `:Set(value, true)` is silent (no callback, no signal).
   `Default` does not fire the callback, except for `AddToggle` with `Default = true`, which calls the callback once.
4. **Keybind values:** for `Mode = "Press"` the callback has no argument; `"Toggle"` and `"Hold"` pass a boolean.
5. **Colours are theme roles, not Color3s.** Never hardcode colours inside the library. Use role names such as `Primary`, `OnSurface`
   (full list in docs/THEMING.md). Only `AddColorPicker` and `Theme.Seed` accept raw colours.
6. **Icons are names** from [docs/ICONS.md](docs/ICONS.md) (`"home"`, `"settings"`, aliases like `"gear"`), or an `rbxassetid` number.
   Unknown names render nothing and do not error. Do not invent names; check the list.
7. **Never use `getgenv`, `writefile`, `loadstring` etc. directly inside `src/`** without the capture-as-`any` pattern used in
   `Assets.luau` and `Library.luau`; the executor globals are optional and typed `?`.
8. **Every Instance that gets a theme colour must go through `Core.Bind` / `Core.Set`.** Setting `BackgroundColor3 = something` directly
   will not follow theme changes.
9. **Do not yield on the render path.** Network work happens once, in `Assets.Init`, with `pcall` fallbacks. Keep it that way.
10. The library must keep working when `Offline = true` or when the executor has no file API (falls back to Gotham + text only).

## Build, check, test (all commands run from `ui/`)

| Task | Command |
| --- | --- |
| Bundle to `dist/ZaridiumUI.lua` | `node tools/bundle.mjs --version 1.0.0` |
| Smoke test (45 assertions, mocked Roblox; does not touch `dist/`) | `node tests/run.mjs <path-to-luau>` |
| Type check | `luau-lsp analyze --defs=<globalTypes.d.luau> --defs=types/executor.d.luau src/*.luau` |
| Rebuild fonts | `python tools/build-fonts.py` |
| Rebuild icon atlas | `cd tools && npm install && cd .. && node tools/build-icons.mjs` |

`luau` and `luau-lsp` come from <https://github.com/luau-lang/luau/releases> and <https://github.com/JohnnyMorganz/luau-lsp/releases>.
`globalTypes.d.luau` is in the luau-lsp repo at `scripts/globalTypes.d.luau`.

**When you add or rename a module in `src/`, add it to `ORDER` in `tools/bundle.mjs`** (dependency order). The bundler throws if the
list and the folder disagree.

**Files must use LF line endings** (see `.editorconfig`). Scripts that patch sources by string match break on CRLF.

## Adding a new control (checklist)

1. Add `function Controls.AddThing(container, opts)` in `src/Controls.luau`. Start with `local self = newControl("Thing", opts, container)`.
2. Build the row with `makeRow(container, opts, minHeight)` (title, description, icon, right slot) or a bespoke `Frame`.
3. Implement `self:Set(value, silent)`, `self:Serialize()` (and `Deserialize` if the format differs), `self._applyDisabled`.
4. Call `register(self)` at the end so `Flag` works.
5. Use `Components.Interactive(host, {...})` for hover, press and ripple. Do not hand-roll input handling for plain clicks.
6. Register it: add `wrap("AddThing", Controls.AddThing)` at the bottom of `Controls.Attach`.
7. Add assertions to `tests/smoke.luau` and a section to docs/API.md.

## File map

| File | Responsibility |
| --- | --- |
| `src/Library.luau` | Public API: `CreateWindow`, `Notify`, `Dialog`, theme, `Config`, `BuildSettings`, `Unload` |
| `src/Window.luau` | Window frame, top bar, navigation rail / bottom bar, pages, sections, profile card, search, drag/resize |
| `src/Controls.luau` | Every `Add*` control + shared `newControl` contract |
| `src/Components.luau` | Typography, `Frame`, `Text`, `Interactive` (state layer + ripple), `IconButton`, tooltip |
| `src/Core.luau` | Theme roles, `Bind`/`Set` live colour binding, corner scale, popup registry |
| `src/Color.luau` | Seed -> Material 3 role generator (OKLCH tonal palettes, Dark/Light/Amoled) |
| `src/Assets.luau` | Font + atlas download, validation, caching, fallbacks |
| `src/Icons.luau`, `src/IconData.luau` | Atlas lookup (IconData is generated) |
| `src/Util.luau` | Signal, Maid, Tween, input helpers, table helpers |
| `tools/` | Bundler, font and icon build scripts |
| `tests/` | Roblox mock + smoke test |

## Common mistakes

- Calling `Tab:AddToggle(...)`. Controls belong to sections.
- Passing a `Color3` where a role name is expected, or a role name where `AddColorPicker.Default` expects a colour.
- Forgetting `Flag`, then wondering why a config does not restore the value.
- Reusing a `Flag`. The second control replaces the first and a warning is printed.
- Using an icon name that is not in the atlas (it silently renders nothing).
- Editing `dist/ZaridiumUI.lua` or `src/IconData.luau` by hand. Both are generated.
- Assuming `Library:Notify` works before `CreateWindow`; it returns `nil` until a window exists.
- Expecting `Section:AddDropdown` values to be mutated in place; use `dropdown:SetValues(newList)`.

## Licensing (keep when copying code)

Zaridium UI is CC BY-NC 4.0 (non-commercial, attribution required). Icons are Material Symbols (Apache-2.0) and the fonts are
Google Sans Flex (SIL OFL 1.1); see [assets/NOTICE.md](assets/NOTICE.md). "Google Sans" is a Google trademark; this project is not
affiliated with Google.
