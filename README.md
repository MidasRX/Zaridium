<div align="center">

# 🐋 Zaridium

### *A modern, free & open-source Roblox script hub — forged from [Orca](https://github.com/richie0866/orca).*

<br/>

[![Stars](https://img.shields.io/github/stars/MidasRX/Zaridium?style=for-the-badge&color=6cc3ff&labelColor=08080d&logo=github)](https://github.com/MidasRX/Zaridium/stargazers)
[![Issues](https://img.shields.io/github/issues/MidasRX/Zaridium?style=for-the-badge&color=e664b4&labelColor=08080d&logo=github)](https://github.com/MidasRX/Zaridium/issues)
[![License](https://img.shields.io/github/license/MidasRX/Zaridium?style=for-the-badge&color=ffd86b&labelColor=08080d)](./LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/MidasRX/Zaridium?style=for-the-badge&color=8be9fd&labelColor=08080d&logo=git&logoColor=white)](https://github.com/MidasRX/Zaridium/commits/main)

[![TypeScript](https://img.shields.io/badge/TypeScript-roblox--ts-3178c6?style=for-the-badge&logo=typescript&logoColor=white&labelColor=08080d)](https://roblox-ts.com)
[![Roact](https://img.shields.io/badge/UI-Roact-ff4757?style=for-the-badge&logo=react&logoColor=white&labelColor=08080d)](https://roblox.github.io/roact/)
[![Rojo](https://img.shields.io/badge/Build-Rojo-d35400?style=for-the-badge&labelColor=08080d)](https://rojo.space)

<br/>

```
╔═════════════════════════════════════════════════════════════╗
║   press  K  →  open · close · feel the flow                 ║
╚═════════════════════════════════════════════════════════════╝
```

</div>

<br/>

## 🌌 What is Zaridium?

**Zaridium** is a slick, fast, fluid **Roblox script hub** built on top of the legendary **[Orca](https://github.com/richie0866/orca)** UI engine. It hands you a tidy panel of **action cards** for everything you'd want during a session — from movement tweaks to player utilities to a curated launcher for community scripts.

> 🎯 **Mission** — keep convenience tasks *one tap away*, look good doing it, and never get in the way.

<br/>

## 🚀 Quick Start

Paste one of these into your executor. When auto-execute is on, Zaridium boots minimized so it won't blast your screen on join.

### 📦 Latest stable

```lua
loadstring(
  game:HttpGetAsync("https://raw.githubusercontent.com/MidasRX/Zaridium/main/roblox-script/public/latest.lua")
)()
```

### 🧪 Nightly snapshot

> ⚠️ Bleeding-edge. New stuff lands here first; expect occasional rough edges.

```lua
loadstring(
  game:HttpGetAsync("https://raw.githubusercontent.com/MidasRX/Zaridium/main/roblox-script/public/snapshot.lua")
)()
```

<br/>

## 🧭 Navigation

<table>
<tr>
<td valign="top" width="33%">

### 🏠 Home
Quick-access info & character tweaks.

- 😊 **Profile**
  - 🎚️ Sliders — flight, walk speed, jump height
  - 🔘 Buttons — refresh, ghost, godmode, freecam
- 🖥️ **Server** — rejoin / hop / cancel
- 🎮 **Friend Activity** — see what your homies are playing

</td>
<td valign="top" width="33%">

### 📱 Apps
Hub for general-purpose tools.

- 🤗 **Players**
  - 🚀 Goto — teleport to them
  - 👻 Hide — local-only, persistent
  - ☠️ Kill — handle-tool void bind
  - 👁️ Spectate — third-person follow

</td>
<td valign="top" width="33%">

### 📰 Scripts
Curated launcher of community gems.

- 📚 [Solaris](https://solarishub.dev)
- 📚 [V.G Hub](https://github.com/1201for)
- 📚 [EvoV2](https://projectevo.xyz)
- 🛡️ [CMD-X](https://github.com/CMD-X)
- 🛡️ [Infinite Yield](https://github.com/EdgeIY)
- 🔍 [Dex Explorer](https://github.com/LorekeeperZinnia)
- 🔍 [Unnamed ESP](https://github.com/ic3w0lf22)

</td>
</tr>
</table>

### ⚙️ Options

|         |                              |
| :-----: | ---------------------------- |
|   ✅   | Set theme                     |
|   ⬜   | Toggle acrylic effect         |
|   ⬜   | Keybinds                      |
|   ⬜   | Save settings                 |

<br/>

## 🛠️ Compatibility

| Executor              | Status |
| --------------------- | :----: |
| ScriptWare            |   ✅   |
| Synapse X             |   ✅   |
| Krnl                  |   ✅   |
| Most modern executors |   ⚡   |

> 💡 If your executor supports `HttpGetAsync` + `loadstring`, you're 99% good.

<br/>

## 📁 Project Layout

```
Zaridium/
├── README.md              ← you are here
├── LICENSE
└── roblox-script/         ← the actual roblox-ts project
    ├── src/               ← TypeScript source (App, views, components, store…)
    ├── public/            ← bundled loaders (latest.lua, snapshot.lua)
    ├── ci/                ← bundle + minify scripts
    ├── default.project.json
    ├── place.project.json
    └── package.json
```

<br/>

## 💻 Build it yourself

> Requires **Node 16+**, **[Foreman](https://github.com/Roblox/foreman)** (or Aftman), and an executor for testing.

```bash
git clone https://github.com/MidasRX/Zaridium.git
cd Zaridium/roblox-script

# install toolchain (rojo, remodel, selene, etc.)
foreman install

# install deps
npm install

# compile + bundle into a single loader
npm run bundle
```

| Script             | What it does                                  |
| ------------------ | --------------------------------------------- |
| `npm run watch`    | live recompile on save                        |
| `npm run serve`    | Rojo serve for Studio sync                    |
| `npm run build`    | build `Orca.rbxm` model                       |
| `npm run bundle`   | compile + bundle to `public/dev.lua`          |
| `npm run bundle:min` | bundle minified                             |

<br/>

## 🤝 Credits

- 🐋 **[richie0866](https://github.com/richie0866)** — original creator of **Orca**, the UI engine and architecture this fork stands on. All respect.
- 💜 The **roblox-ts**, **Roact**, **Rodux** and **Rojo** teams.
- 🌟 Everyone who tests, reports bugs, or yells at me in DMs.

<br/>

## 📜 License

Released under the **MIT License** — see [LICENSE](./LICENSE). Do whatever you want, just keep the credit line.

<br/>

<div align="center">

### 💌 Hit me up

<a href="https://github.com/MidasRX"><img src="https://img.shields.io/badge/GitHub-MidasRX-181717?style=for-the-badge&logo=github&logoColor=white&labelColor=08080d" /></a>
<a href="https://discord.com/users/maximepolice"><img src="https://img.shields.io/badge/Discord-maximepolice-5865F2?style=for-the-badge&logo=discord&logoColor=white&labelColor=08080d" /></a>
<a href="https://t.me/NagiOnTop"><img src="https://img.shields.io/badge/Telegram-NagiOnTop-26A5E4?style=for-the-badge&logo=telegram&logoColor=white&labelColor=08080d" /></a>

<br/><br/>

*Built with 🩵 by [@MidasRX](https://github.com/MidasRX) · forked with respect from [Orca](https://github.com/richie0866/orca)*

</div>
