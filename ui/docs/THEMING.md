# Theming

Colours come from **roles**, not hex codes. A role is a name such as `Primary` or `SurfaceContainer`; the library generates all
roles from one **seed colour**, in one of three **modes**, and every themed Instance follows when the theme changes.

```lua
Library:SetTheme({ Mode = "Dark", Preset = "Teal" })          -- mode + built-in preset
Library:SetTheme({ Seed = Color3.fromRGB(255, 120, 0) })        -- any seed colour (or "#FF7800")
Library:SetTheme({ Overrides = { Primary = Color3.new(1, 0, 0) } }) -- pin individual roles
Library:SetTheme({ Mode = "Light" }, false)                     -- second argument false = no transition
```

At creation: `Library:CreateWindow({ Theme = { Mode = "Amoled", Preset = "Rose" } })`.

## Modes

| Mode | Use |
| --- | --- |
| `Dark` | Default. Surface is tone 6 (near black with a tint of the seed). |
| `Light` | Surface is tone 98. |
| `Amoled` | Dark with a pure black surface and shifted containers. |

## Presets

`Violet` `Indigo` `Blue` `Sky` `Teal` `Green` `Lime` `Amber` `Orange` `Red` `Rose` `Magenta` `Slate`
(`Library.Color.PresetNames()` returns the list at runtime; `Library.Color.Presets` has the seeds.)

## How colours are generated

`src/Color.luau` builds tonal palettes in **OKLCH** and maps tone 0 to 100 onto CIELAB lightness, reducing chroma until the colour fits
sRGB. Palettes: primary (seed hue), secondary (low chroma), tertiary (hue + 60), neutral and neutral-variant (seed hue, near grey),
error (hue 29), success (hue 145), warning (hue 85). Each role is a (palette, tone) pair, for example Dark `Primary` = primary tone 80,
`OnPrimary` = primary tone 20.

This is *not* a bit-exact port of Google's HCT algorithm, so colours differ slightly from material-color-utilities for the same seed.
The Material contrast pairings are preserved: measured over all 13 presets x 3 modes, the worst contrast of
`Primary/OnPrimary`, `Surface/OnSurface`, `SecondaryContainer/OnSecondaryContainer` and `Error/OnError` is 6.17:1 (WCAG AA needs 4.5:1).

## Roles

| Group | Roles |
| --- | --- |
| Primary | `Primary` `OnPrimary` `PrimaryContainer` `OnPrimaryContainer` |
| Secondary | `Secondary` `OnSecondary` `SecondaryContainer` `OnSecondaryContainer` |
| Tertiary | `Tertiary` `OnTertiary` `TertiaryContainer` `OnTertiaryContainer` |
| Error | `Error` `OnError` `ErrorContainer` `OnErrorContainer` |
| Success | `Success` `OnSuccess` `SuccessContainer` `OnSuccessContainer` |
| Warning | `Warning` `OnWarning` `WarningContainer` `OnWarningContainer` |
| Surfaces | `Background` `Surface` `SurfaceDim` `SurfaceBright` `SurfaceContainerLowest` `SurfaceContainerLow` `SurfaceContainer` `SurfaceContainerHigh` `SurfaceContainerHighest` `SurfaceVariant` |
| Content on surface | `OnBackground` `OnSurface` `OnSurfaceVariant` |
| Lines | `Outline` `OutlineVariant` |
| Inverse | `InverseSurface` `InverseOnSurface` `InversePrimary` |
| Misc | `SurfaceTint` `Scrim` `Shadow` |

Rules of thumb: text on a surface uses `OnSurface` (primary text) or `OnSurfaceVariant` (secondary text); anything on a filled
`X` uses `OnX`; selected states use `SecondaryContainer` / `OnSecondaryContainer`; elevated cards use higher `SurfaceContainer*` tones.

## Shape, motion, type

| Setting | API | Notes |
| --- | --- | --- |
| Corner roundness | `Library:SetCornerScale(0..2)` | Scales every corner radius. Full pills stay pills. |
| Radius scale | `Core.Radius` | `XSmall` 4, `Small` 8, `Medium` 12, `Large` 16, `XLarge` 28 (Material 3 shape scale). |
| Animation | `Library:SetAnimations(enabled, speed)` | Off = instant state changes. |
| Ripple | `Library:SetRipple(enabled)` | |
| Font | `Library:SetRoundedFont(enabled)` or `CreateWindow({ Font = Font.new(...) })` | |

Type scale (`Components.Type`): `HeadlineSmall` 24, `TitleLarge` 22, `TitleMedium` 16, `TitleSmall` 14, `LabelLarge` 14,
`LabelMedium` 12, `LabelSmall` 11, `BodyLarge` 16, `BodyMedium` 14, `BodySmall` 12. Weights are Regular, Medium or SemiBold.

## Using roles in your own Instances

Inside the library (`src/`), always bind:

```lua
Core.Bind(frame, "BackgroundColor3", "SurfaceContainer")   -- follows theme changes
Core.Set(label, "TextColor3", selected and "Primary" or "OnSurface", 0.12) -- state change with a tween
```

Outside the library, read `Library:GetColor("Primary")` and subscribe to theme changes by listening to `Library.Changed`.