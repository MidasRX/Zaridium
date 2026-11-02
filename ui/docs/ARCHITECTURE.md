# Architecture

## Module graph

```
Util ─────────┐
Color         │
IconData      │
   │          ▼
   └───► Core (theme roles, Bind/Set, corners, popups)
              │
        Assets (fonts + atlas)  ──►  Icons
              │                       │
              └────────► Components ◄─┘     (Text, Frame, Interactive, IconButton, tooltip)
                              │
                          Controls                (every Add* control)
                              │
                           Window                 (shell, nav, pages, sections, profile, search)
                              │
                          Library                 (public API, notify, dialog, config, settings)
```

Modules call `require("Name")` with a **string**. The bundler (`tools/bundle.mjs`) prepends a tiny `require` shim and wraps each file
in a function, in the dependency order listed in its `ORDER` array. There is no Rojo, no Wally and no external dependency.

## Lifecycle

1. `CreateWindow` applies options, calls `Assets.Init` (download, validate, cache, fallbacks), builds the theme, creates a `ScreenGui`
   (via `gethui` / CoreGui / PlayerGui) with a `Root` frame and a `UIScale`, installs the popup blocker, tooltip, notification stack
   and dialog layer, then builds the `Window`.
2. `Window:AddTab` creates a navigation item plus a `ScrollingFrame` page. `Tab:AddSection` creates a card. `Section:Add*` builds rows.
3. `Library:Unload` closes popups, disconnects the global maid, destroys every control (which unregisters flags), destroys the window and
   the `ScreenGui`, and clears `getgenv().ZaridiumUI` if it points at this library.

## Theme binding

`Core.Bind(instance, property, role)` stores `instance -> { property -> role }` in a weak table and sets the colour now. On
`Core.ApplyTheme` the new roles are generated and every bound property is lerped to its new colour over 0.3 s (one Heartbeat loop,
not one tween per Instance). `Core.Set` is the same but animates a single property, used for state changes (selected, focused...).

## Interaction

`Components.Interactive(host, opts)` adds a clipped state layer, a transparent `TextButton` hit area (touch and mouse work through
`Activated`), hover/press overlays (8% / 12% of `OnSurface`) and a ripple that expands from the pointer. All clickable things use it.
Pointer positions go through `Util.PointerPosition`, which accounts for the touch GUI inset and the root `UIScale`.

## Popups

Dropdown menus and the colour picker are parented to the root overlay (never inside a clipped card). They register a `close` function
with `Core.RegisterPopup`, which also shows a full-screen transparent blocker; clicking it calls `Core.ClosePopups(nil, true)`.
`Core.WasJustClosed` stops the same click from re-opening the popup it just closed.

## Responsive layout

`Window:_layoutResponsive` switches between the 88 px navigation rail (wide windows) and a 72 px bottom bar (below 560 px), hides the
profile card and collapses search to an icon on narrow windows. The root `UIScale` follows the viewport (0.6 to 1.25) unless
`Scale` is set.

## Assets

`Assets.Init` needs `writefile`, `readfile`, `isfile`, `makefolder` and `getcustomasset`. It downloads 8 TTFs and one PNG from
`AssetBaseUrl`, validates magic bytes (a failed download never poisons the cache), builds two Roblox Font Family JSON files and
loads them with `getcustomasset`. Any failure drops to `rbxasset://fonts/families/GothamSSm.json` and text-only icons; the UI stays
usable. Cache path: `<CacheFolder>/assets-<library version>/`, so a new library version re-downloads.

Fonts are static instances of Google Sans Flex (opsz 16, wdth 100, wght 400/500/600/700, ROND 0 and 100) subset to Latin plus
punctuation, arrows and currency. Icons are a 1024x1024 white-on-transparent atlas of Material Symbols Rounded, 64 px cells,
outline at cell `2*i` and filled at `2*i + 1`; `IconData.luau` maps names to pixel offsets.

## Performance notes

- One `UIScale`, one theme loop, one tooltip, one blocker, one notification holder for the whole UI.
- Dropdown menus are built when opened and destroyed when closed.
- Search only toggles `Visible` on rows; it never rebuilds.
- Animations can be disabled globally; every `Util.Tween` call then becomes a direct property write.

## Testing

`tests/mock.luau` is a small fake Roblox (Instance tree, signals, Color3, UDim2, enums, services). `tests/run.mjs` bundles the
library, wraps it with the mock and a nil executor environment, and runs `tests/smoke.luau` under plain `luau`. It covers every
control, flags, config encode, theming, search, notifications, dialogs, unload and re-create. It cannot judge visual layout, so
changes to sizes, positions and animations need a manual look in a real client.

## Known limitations

- Colours follow the OKLCH approach described in [THEMING.md](THEMING.md), not Google's exact HCT output.
- Fonts cover Latin only; Cyrillic and Greek were subset out because the source font ships no usable glyphs for them in the static build.
- The icon atlas holds 128 icons; see [ICONS.md](ICONS.md). Pass an asset id or `rbxassetid://` string for anything else.
- Requires an executor with the file and asset functions for custom fonts and icons; otherwise it falls back to Gotham and no icons.
