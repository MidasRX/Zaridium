# API reference

All names are case-sensitive. Optional values are marked `?`. Defaults are in parentheses.

## Library

```lua
local Library = loadstring(game:HttpGet(".../ui/dist/ZaridiumUI.lua"))()
```

| Member | Description |
| --- | --- |
| `Library:CreateWindow(config) -> Window` | Creates the UI. Destroys a previous window if one exists. |
| `Library:Notify(opts \| string) -> { Close }?` | Toast. Returns `nil` before a window exists. |
| `Library:Dialog(opts)` | Modal dialog with action buttons. |
| `Library:BuildSettings(tab, opts?)` | Adds Appearance and Configuration sections to `tab`. `opts.Configs = false` skips configs. |
| `Library:SetTheme({ Mode?, Preset?, Seed?, Overrides? }, animate?)` | See [THEMING.md](THEMING.md). |
| `Library:GetTheme() -> { Mode, Preset, Seed, Overrides }` | Current theme. |
| `Library:GetColor(role) -> Color3` | Current colour of a role. |
| `Library:SetAnimations(enabled, speed?)` | Global animation switch and speed multiplier (0.25 to 4). |
| `Library:SetRipple(enabled)` | Ripple effect on or off. |
| `Library:SetCornerScale(scale)` | 0 (square) to 2 (very round). 1 is Material default. |
| `Library:SetRoundedFont(enabled)` | Google Sans Flex Rounded vs standard. |
| `Library:SetScale(scale)` | Fixed UI scale (0.5 to 2). |
| `Library:SetToggleKey(key: Enum.KeyCode)` | Key that shows or hides the window. |
| `Library:Toggle(visible?)` | Show, hide or toggle. |
| `Library:Unload()` | Destroys everything, disconnects all events. Safe to call twice. |
| `Library:GetAssetStatus() -> string` | e.g. `"fonts=Google Sans Flex icons=atlas"`. Useful for debugging. |
| `Library.Flags` | `{ [flag]: value }`, live. |
| `Library.Options` | `{ [flag]: control }`, live. |
| `Library.Config` | Save/load manager, see below. |
| `Library.Changed` | Signal `(kind, ...)`; fires `("Theme", mode)` on theme changes from the UI. |
| `Library.Unloading` | Signal fired at the start of `Unload`. |
| `Library.Icons` | `.Has(name)`, `.List()`, `.Resolve(name)`. |
| `Library.Version` | Library version string. |

### `CreateWindow` config

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `Title` | string | `"Window"` | |
| `Subtitle` | string? | none | Small text under the title. |
| `Icon` | string \| number? | none | Icon name or asset id, shown in the top bar. |
| `Theme` | table? | Dark / Violet | `{ Mode, Preset, Seed, Overrides }`. |
| `Size` | Vector2 | `780x560` | Base size before UI scale. |
| `MinSize` | Vector2 | `420x360` | Resize limit. |
| `Scale` | number? | auto | Fixed UI scale. Auto scales with viewport (0.6 to 1.25). |
| `ToggleKey` | Enum.KeyCode | `RightControl` | |
| `AutoShow` | boolean | `true` | |
| `Profile` | table \| false? | local player | `{ DisplayName, Username, UserId, Image, OnClick }`. `false` hides the card. |
| `Resizable` | boolean | `true` | |
| `Search` | boolean | `true` | Search box in the top bar. |
| `ThemeButton` | boolean | `true` | Light/dark button in the top bar. |
| `ConfirmClose` | boolean | `false` | Ask before the close button unloads the UI. |
| `Animations` | boolean | `true` | |
| `AnimationSpeed` | number | `1` | |
| `Ripple` | boolean | `true` | |
| `CornerScale` | number | `1` | |
| `RoundedFont` | boolean | `true` | |
| `Font` | Font? | none | Overrides the bundled font. `Font.new(...)` or `Font.fromEnum(...)`. |
| `Offline` | boolean | `false` | Never touch the network. Uses Gotham and no icons. |
| `AssetBaseUrl` | string | this repo's `ui/assets/` | Where fonts and the icon atlas are fetched. Point to a fork or a pinned commit. |
| `CacheFolder` | string | `"ZaridiumUI"` | Folder in the executor workspace. |
| `AtlasImage` | string? | none | Pre-uploaded atlas (`rbxassetid://...`); skips the download. |
| `Name` | string? | random | Name of the ScreenGui. |

## Window

| Member | Description |
| --- | --- |
| `Window:AddTab({ Name, Icon?, Badge?, Default?, Tooltip? }) -> Tab` | `Name` also accepted as a bare string. |
| `Window:SelectTab(tab \| name)` | |
| `Window:GetTab(name) -> Tab?` | |
| `Window:SetVisible(bool)`, `Window:Toggle()` | |
| `Window:SetTitle(title, subtitle?)` | |
| `Window:ClearSearch()` | |
| `Window.Opened`, `Window.Closed`, `Window.TabChanged` | Signals; `TabChanged` passes the tab name. |
| `Window.Visible`, `Window.Selected`, `Window.Tabs` | State. |

## Tab and Section

| Member | Description |
| --- | --- |
| `Tab:AddSection({ Title?, Icon?, Elevated? }) -> Section` | A rounded card. `Title` also accepted as a bare string. |
| `Tab:SetBadge(number \| string \| nil)` | Badge on the navigation item (hidden for `nil`, `0`, `""`). |
| `Tab:Select()`, `Tab:Destroy()` | |
| `Section:SetTitle(text)`, `Section:SetVisible(bool)`, `Section:Destroy()` | |

## Control contract

Every control returned by an `Add*` method has:

| Member | Description |
| --- | --- |
| `.Value` | Current value (shape depends on the control). |
| `.Type` | `"Toggle"`, `"Slider"`, ... |
| `:Set(value, silent?)` | Updates the UI and value. `silent = true` skips callback and signal. |
| `:Get()` | Same as `.Value`. |
| `:OnChanged(fn) -> connection` | `fn(value)`; call `:Disconnect()` to remove. |
| `.Changed` | Underlying Signal. |
| `:SetVisible(bool)` | Show or hide the row (search can also hide rows; both are respected). |
| `:SetDisabled(bool)` | Dim and block interaction. |
| `:Serialize()` / `:Deserialize(value, silent?)` | Used by configs. |
| `:Destroy()` | Removes the row and unregisters the flag. |

Shared options (all controls): `Text`, `Description?`, `Icon?`, `Flag?`, `Default?`, `Callback?`, `Tooltip?`, `Disabled?`, `Visible?`, `LayoutOrder?`.

## Controls

### `Section:AddToggle`
Material 3 switch. `Value: boolean`.

### `Section:AddSlider`
`Min` (0), `Max` (100), `Step` (1), `Decimals?` (derived from `Step`), `Suffix?`, `Format?: (number) -> string`. `Value: number`. Drag on mouse or touch.

### `Section:AddButton`
`Style`: `"Tonal"` (default), `"Filled"`, `"Outlined"`, `"Text"`, `"Elevated"`, `"Danger"`. `Callback()` fires on click. `:SetText(text)`. `:Set()` triggers a click.

### `Section:AddInput`
Outlined text field with floating label. `Placeholder?`, `Numeric?` (digits, `.`, `-` only), `Min?`/`Max?` (numeric clamp), `MaxLength?`,
`Finished = true` commits only on Enter (default: commit on Enter or when focus is lost). `Value: string`.

### `Section:AddDropdown`
`Values: { any }`, `Multi?`, `Default`, `AllowNull?`, `Placeholder?`, `MaxVisible?` (6). Single: `Value` is the item. Multi: `Value` is `{ [item]: true }`.
`:SetValues(list, keepSelection?)` replaces the options. Menu renders in the overlay layer so it never clips.

### `Section:AddSegmented`
Segmented button row. `Values`, `Multi?`. Same value shapes as `AddDropdown`.

### `Section:AddChips`
Filter chips (multi-select). `Values`, `Default: { item }`. `Value` is `{ [item]: true }`.

### `Section:AddKeybind`
`Default: Enum.KeyCode | string` (e.g. `"F"`), `Mode`: `"Press"` (default), `"Toggle"`, `"Hold"`. Click the chip, press a key; **Esc clears**; right/middle mouse is accepted.
`Value` is `nil` for `Press`, a boolean for the others. `:GetKey() -> EnumItem?`. `.Pressed` signal for `Press`. Serializes as the key name.

### `Section:AddColorPicker`
`Default: Color3 | "#RRGGBB"`. Popup with saturation/value square, hue bar and hex field. `Value: Color3`. Serializes as `"#RRGGBB"`.

### `Section:AddProgress`
`Default` 0 to 1. Display only; set with `:Set(0.5)`. Not serialized.

### `Section:AddLabel`
`Text`, `Style?` (type-scale name), `Role?` (colour role), `RichText?`, `Center?`. `:SetText(text)`.

### `Section:AddParagraph({ Title?, Content })`
Bold title plus body text (rich text).

### `Section:AddDivider({ Inset? })`

## Notify

```lua
Library:Notify({
	Title = "Saved", Content = "Config written.", Type = "Success", -- Info | Success | Warning | Error
	Duration = 5,            -- seconds; 0 = stays until dismissed
	Icon = "check_circle",   -- optional override
	Action = { Text = "Undo", Callback = function() end },
})
```
At most 6 toasts are visible; the oldest is removed first.

## Dialog

```lua
Library:Dialog({
	Title = "Delete?", Content = "This cannot be undone.", Icon = "delete",
	Buttons = { { Text = "Cancel", Style = "Text" }, { Text = "Delete", Style = "Danger", Callback = function() end } },
})
```
Button styles: `Filled`, `Tonal`, `Text` (default), `Danger`. Any button closes the dialog.

## Config manager (`Library.Config`)

Stores every control that has a `Flag` as JSON in `<exec workspace>/<Folder>/configs/<name>.json`.

| Member | Description |
| --- | --- |
| `:SetFolder(name)` | Default `"ZaridiumUI"`. Set per script hub to avoid collisions. |
| `:Ignore({ flags })` | Flags excluded from save/load (internal theme flags are ignored automatically). |
| `:Save(name) -> ok, err?` / `:Load(name) -> ok, err?` / `:Delete(name)` | |
| `:List() -> { names }` | Needs `listfiles`. |
| `:SetAutoload(name?)`, `:GetAutoload()`, `:LoadAutoload()` | Call `LoadAutoload()` after building all controls. |
| `:Encode() -> json`, `:Decode(json) -> ok, err?` | For sharing configs or storing elsewhere. |

If the executor has no file API, `Save`/`Load` return `false, "executor has no file API"`; the UI keeps working.

## Signals (`Util.Signal`)

`signal:Connect(fn) -> { Disconnect }`, `signal:Once(fn)`, `signal:Fire(...)`, `signal:Destroy()`.

## Executor requirements

Required: a Roblox client environment. Everything else is optional and degrades gracefully:

| Function | Used for | Without it |
| --- | --- | --- |
| `gethui` / CoreGui | Hiding the GUI | Falls back to CoreGui, then PlayerGui. |
| `protectgui` / `protect_gui` | Protecting the ScreenGui | Skipped. |
| `writefile` `readfile` `isfile` `isfolder` `makefolder` `getcustomasset` | Font + icon cache | Gotham font, text-only icons. |
| `game:HttpGet` | Downloading assets | Same fallback; or use `Offline = true`. |
| `listfiles` `delfile` | Config list and delete | Those buttons do nothing useful. |
| `setclipboard` | "Copy config" | A warning toast is shown. |
