<div align="center">

# Zaridium

### A Roblox script hub and a Material 3 UI library for executors.

<br/>

[![Stars](https://img.shields.io/github/stars/MidasRX/Zaridium?style=for-the-badge&color=6cc3ff&labelColor=08080d&logo=github)](https://github.com/MidasRX/Zaridium/stargazers)
[![Issues](https://img.shields.io/github/issues/MidasRX/Zaridium?style=for-the-badge&color=e664b4&labelColor=08080d&logo=github)](https://github.com/MidasRX/Zaridium/issues)
[![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-ffd86b?style=for-the-badge&labelColor=08080d)](./LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/MidasRX/Zaridium?style=for-the-badge&color=8be9fd&labelColor=08080d&logo=git&logoColor=white)](https://github.com/MidasRX/Zaridium/commits/main)

[![Luau](https://img.shields.io/badge/UI%20library-Luau-00a2ff?style=for-the-badge&labelColor=08080d)](./ui)
[![Material 3](https://img.shields.io/badge/Design-Material%203-6750a4?style=for-the-badge&logo=materialdesign&logoColor=white&labelColor=08080d)](https://m3.material.io)
[![TypeScript](https://img.shields.io/badge/Hub-roblox--ts-3178c6?style=for-the-badge&logo=typescript&logoColor=white&labelColor=08080d)](https://roblox-ts.com)

</div>

<br/>

## What is in this repository

| | **[Zaridium UI](./ui)** | **[Zaridium Hub](./roblox-script)** |
| --- | --- | --- |
| **What** | A multi-use UI library you build your own scripts on | A ready-made script hub with a dashboard and tools |
| **Look** | Material 3: rounded shapes, tonal surfaces, ripples, Google Sans Flex, Material Symbols | Glassy card dashboard with themes and acrylic blur |
| **Language** | Luau, a single bundled file, no dependencies | TypeScript (roblox-ts) with React and Reflex |
| **Use it for** | Your own hub, tools and settings menus | Running it as is |
| **Docs** | [ui/AGENTS.md](./ui/AGENTS.md), [ui/docs](./ui/docs) | This page |

<br/>

## Zaridium UI

A Material 3 interface library for Roblox executors. One `loadstring`, one window, a dozen controls, and a theme generated from a
single seed colour.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/MidasRX/Zaridium/main/ui/dist/ZaridiumUI.lua"))()

local Window  = Library:CreateWindow({ Title = "My Hub", Icon = "bolt", Theme = { Mode = "Dark", Preset = "Violet" } })
local Tab     = Window:AddTab({ Name = "Main", Icon = "home" })
local Section = Tab:AddSection({ Title = "Movement", Icon = "speed" })

Section:AddToggle({ Text = "Fly", Flag = "fly", Default = false, Callback = function(on) print("fly", on) end })
Section:AddSlider({ Text = "Speed", Flag = "speed", Min = 16, Max = 200, Default = 16, Suffix = " st/s" })

Library:BuildSettings(Window:AddTab({ Name = "Settings", Icon = "settings" })) -- theme + configs, ready made
```

### Features

- **Material 3 look:** pill buttons, 28 px window corners, tonal surface containers, state layers and ripples.
- **Generated theme:** pick a seed colour or one of 13 presets and get all roles in Dark, Light or Amoled, with live transitions.
- **Google Sans Flex** (standard and rounded) and **128 Material Symbols** icons, downloaded once and cached. If the executor cannot
  cache files, it falls back to Gotham and text-only icons instead of failing.
- **Controls:** toggle, slider, button (6 styles), text and numeric input, dropdown (single and multi), segmented buttons, chips,
  keybind (press, toggle, hold), colour picker, progress, label, paragraph, divider.
- **Window:** navigation rail that becomes a bottom bar on narrow windows, search across settings, profile card with the player's
  avatar, drag, resize, tab badges, animated open and close.
- **Notifications and dialogs** with success, warning and error styles.
- **Configs:** every control with a `Flag` saves and loads as JSON, with autoload and share-as-text.
- **Many options:** corner roundness, interface scale, animation speed, ripple, font style, toggle key, all also exposed in the
  built-in settings page.
- **Written for AI agents too:** [`ui/AGENTS.md`](./ui/AGENTS.md) is a short, rule-based guide, backed by a full
  [API reference](./ui/docs/API.md), [theming guide](./ui/docs/THEMING.md) and [architecture notes](./ui/docs/ARCHITECTURE.md).

### Executor requirements

Only a Roblox client environment is required. Everything else degrades gracefully.

| Function | Used for | Without it |
| --- | --- | --- |
| `gethui`, `protectgui` | Hiding the GUI | CoreGui, then PlayerGui |
| `writefile`, `readfile`, `isfile`, `isfolder`, `makefolder`, `getcustomasset` | Font and icon cache | Gotham font, text-only icons |
| `game:HttpGet` | Downloading fonts and icons | Same fallback, or use `Offline = true` |
| `listfiles`, `delfile` | Config list and delete | Those buttons do nothing |
| `setclipboard` | Copy config | A warning toast |

### Run the examples

- [`ui/examples/minimal.lua`](./ui/examples/minimal.lua): a window with a toggle and a button.
- [`ui/examples/full.lua`](./ui/examples/full.lua): every control, notifications, dialogs, theming and configs.

<br/>

## Zaridium Hub

A fast, fluid script hub with a dashboard of action cards. When auto-execute is on it boots minimised.

### Latest stable

```lua
loadstring(
  game:HttpGetAsync("https://raw.githubusercontent.com/MidasRX/Zaridium/main/roblox-script/public/latest.lua")
)()
```

### Nightly snapshot

> Bleeding edge. New work lands here first, so expect rough edges.

```lua
loadstring(
  game:HttpGetAsync("https://raw.githubusercontent.com/MidasRX/Zaridium/main/roblox-script/public/snapshot.lua")
)()
```

### Navigation

<table>
<tr>
<td valign="top" width="33%">

**Home**
Quick access to your character and the server.

- Profile: flight, walk speed and jump sliders; refresh, ghost, godmode and freecam buttons
- Server: rejoin, hop, cancel
- Friend activity

</td>
<td valign="top" width="33%">

**Apps**
General-purpose tools.

- Players: go to, hide, kill, spectate

</td>
<td valign="top" width="33%">

**Scripts**
Launcher for community scripts.

- ~~[Solaris](https://solarishub.dev)~~ (disabled: domain is parked for sale)
- [V.G Hub](https://github.com/1201for)
- ~~[EvoV2](https://projectevo.xyz)~~ (disabled: loader unreachable)
- [CMD-X](https://github.com/CMD-X)
- [Infinite Yield](https://github.com/EdgeIY)
- [Dex Explorer](https://github.com/LorekeeperZinnia)
- [Unnamed ESP](https://github.com/ic3w0lf22)

Third-party scripts are fetched from their own repositories and run with your executor's permissions. Read what you run. Where
possible they are pinned to a specific commit.

</td>
</tr>
</table>

**Options:** theme selection, acrylic toggle, shortcuts and saved settings.

### Compatibility

The hub needs `loadstring` and `game:HttpGetAsync`. Executors that follow the sUNC standard should work; Synapse X is no longer
supported. I do not publish a per-executor version table because I cannot test every executor on every Roblox update.

<br/>

## Project layout

```
Zaridium/
├── README.md
├── LICENSE
├── ui/                      Zaridium UI (Luau, Material 3)
│   ├── AGENTS.md            start here if you are an AI agent
│   ├── src/                 library source, one module per concern
│   ├── dist/ZaridiumUI.lua  the bundled file you load
│   ├── assets/              fonts (Google Sans Flex) and the icon atlas
│   ├── docs/                API, theming, architecture, icons
│   ├── examples/
│   ├── tests/               smoke test with a mocked Roblox
│   └── tools/               bundler, font and icon builders
└── roblox-script/           Zaridium Hub (roblox-ts)
    ├── src/
    ├── public/              bundled loaders (latest.lua, snapshot.lua)
    └── ci/                  bundle scripts
```

<br/>

## Build it yourself

### Zaridium UI

Needs Node 20+. To run the tests you also need a [`luau`](https://github.com/luau-lang/luau/releases) binary.

```bash
cd ui
node tools/bundle.mjs --version 1.0.0     # writes dist/ZaridiumUI.lua
node tests/run.mjs /path/to/luau          # smoke test (mocked Roblox)
```

Rebuild the assets with `python tools/build-fonts.py` (needs `fonttools`) and `node tools/build-icons.mjs` (after `npm install` in
`ui/tools`).

### Zaridium Hub

Needs Node 20.19+ and [Foreman](https://github.com/Roblox/foreman) (or Rokit/Aftman).

```bash
cd roblox-script
foreman install      # rojo, remodel
npm install
npm run bundle       # compile + bundle to public/dev.lua
```

| Script | What it does |
| --- | --- |
| `npm run watch` | recompile on save |
| `npm run serve` | Rojo serve for Studio sync |
| `npm run build` | build `Zaridium.rbxm` |
| `npm run bundle` | compile and bundle to `public/dev.lua` |
| `npm run bundle:min` | the same, minified |
| `npm run lint` | ESLint |

<br/>

## Credits

- **[richie0866](https://github.com/richie0866)** created [Orca](https://github.com/richie0866/orca) (MIT), the UI and architecture
  that Zaridium Hub is based on. The original licence notice is preserved in [LICENSE](./LICENSE).
- **[Material Symbols](https://github.com/google/material-design-icons)** by Google (Apache 2.0) provide the icons.
- **[Google Sans Flex](https://github.com/googlefonts/googlesans-flex)** (SIL Open Font License 1.1) provides the fonts. "Google" and
  "Google Sans" are trademarks of Google LLC; this project is not affiliated with Google. See
  [ui/assets/NOTICE.md](./ui/assets/NOTICE.md).
- The **roblox-ts**, **React-Lua**, **Reflex** and **Rojo** teams.

<br/>

## License

Released under **[CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/)**: free to share and adapt for **non-commercial**
use, with attribution. The original Orca code stays under its MIT licence, and the bundled icons and fonts keep their own licences.
Full text in [LICENSE](./LICENSE).

<br/>

<div align="center">

### Contact

<a href="https://github.com/MidasRX"><img src="https://img.shields.io/badge/GitHub-MidasRX-181717?style=for-the-badge&logo=github&logoColor=white&labelColor=08080d" /></a>
<a href="https://discord.com/users/maximepolice"><img src="https://img.shields.io/badge/Discord-maximepolice-5865F2?style=for-the-badge&logo=discord&logoColor=white&labelColor=08080d" /></a>
<a href="https://t.me/NagiOnTop"><img src="https://img.shields.io/badge/Telegram-NagiOnTop-26A5E4?style=for-the-badge&logo=telegram&logoColor=white&labelColor=08080d" /></a>

<br/><br/>

*Built by [@MidasRX](https://github.com/MidasRX)*

</div>
