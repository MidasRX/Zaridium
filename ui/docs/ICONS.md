# Icons

Material Symbols (Rounded, weight 400) packed into a single white-on-transparent atlas
(`assets/icons/atlas.png`, 1024x1024, 64px cells). Cell layout and lookups live in `src/IconData.luau`.

## Usage

```lua
icon = "home"       -- canonical name
icon = "gear"       -- alias, resolves to "settings"
```

Each icon has an outline variant (default) and a filled variant, used for the selected / active state.
Icons are white so they can be tinted with `ImageColor3`. Names are case-sensitive, snake_case.

Total: 128 icons, 53 aliases.

## Navigation & actions

| Name | Aliases |
| --- | --- |
| `home` |  |
| `menu` | `hamburger` |
| `more_vert` | `dots_vertical` |
| `more_horiz` | `dots_horizontal` |
| `chevron_right` | `next` |
| `chevron_left` | `prev` |
| `expand_more` | `down` |
| `expand_less` | `up` |
| `arrow_back` | `back` |
| `arrow_forward` | `forward` |
| `arrow_upward` |  |
| `arrow_downward` |  |
| `close` | `x`, `cross` |
| `check` | `check_mark`, `tick` |
| `add` | `plus` |
| `remove` | `minus` |
| `open_in_new` | `external` |
| `open_in_full` |  |
| `close_fullscreen` |  |
| `minimize` |  |
| `swap_horiz` |  |
| `swap_vert` |  |
| `login` |  |
| `logout` |  |
| `drag_handle` |  |
| `drag_indicator` |  |
| `refresh` | `reload` |
| `sync` |  |

## Controls & forms

| Name | Aliases |
| --- | --- |
| `toggle_on` |  |
| `toggle_off` |  |
| `radio_button_checked` |  |
| `radio_button_unchecked` |  |
| `check_box` |  |
| `check_box_outline_blank` |  |
| `search` | `search_icon`, `magnify` |
| `filter_list` |  |
| `sort` |  |
| `tune` | `sliders` |
| `text_fields` |  |
| `settings` | `gear`, `cog` |
| `widgets` |  |
| `apps` |  |
| `dashboard` |  |
| `list` |  |
| `tab` |  |
| `layers` |  |

## People & security

| Name | Aliases |
| --- | --- |
| `person` | `user` |
| `group` | `users` |
| `groups` |  |
| `person_add` |  |
| `visibility` | `eye`, `esp` |
| `visibility_off` | `eye_off` |
| `lock` |  |
| `lock_open` |  |
| `key` |  |
| `shield` |  |
| `security` |  |
| `verified` |  |
| `verified_user` |  |
| `admin_panel_settings` |  |

## Status & feedback

| Name | Aliases |
| --- | --- |
| `info` |  |
| `warning` | `warn` |
| `error` |  |
| `check_circle` |  |
| `cancel` |  |
| `help` |  |
| `notifications` | `bell` |
| `notifications_off` |  |
| `flag` |  |
| `label` |  |

## Files & data

| Name | Aliases |
| --- | --- |
| `folder` |  |
| `folder_open` |  |
| `description` | `file` |
| `save` | `save_icon` |
| `download` |  |
| `upload` |  |
| `content_copy` | `copy` |
| `content_paste` | `paste` |
| `delete` | `trash` |
| `edit` | `pencil` |
| `cloud` |  |
| `storage` |  |
| `memory` |  |
| `history` |  |
| `schedule` |  |
| `timer` |  |
| `bar_chart` |  |
| `trending_up` |  |

## Developer

| Name | Aliases |
| --- | --- |
| `code` |  |
| `terminal` |  |
| `bug_report` | `bug` |
| `build` | `tools`, `wrench` |
| `extension` |  |
| `smart_toy` |  |

## Appearance

| Name | Aliases |
| --- | --- |
| `palette` | `theme` |
| `dark_mode` | `moon` |
| `light_mode` | `sun` |
| `brush` |  |
| `format_paint` |  |
| `colorize` |  |
| `opacity` |  |
| `animation` |  |

## Game & targeting

| Name | Aliases |
| --- | --- |
| `sports_esports` | `game`, `gamepad` |
| `my_location` | `crosshair` |
| `gps_fixed` | `crosshairs` |
| `crop_free` |  |
| `explore` |  |
| `map` |  |
| `flight` | `plane`, `fly` |
| `speed` |  |
| `bolt` |  |
| `rocket_launch` | `rocket` |
| `emoji_events` | `trophy` |
| `star` |  |
| `favorite` | `heart` |
| `bookmark` |  |

## Media & communication

| Name | Aliases |
| --- | --- |
| `play_arrow` | `play` |
| `pause` |  |
| `stop` |  |
| `link` |  |
| `public` | `globe` |
| `language` |  |
| `wifi` |  |
| `keyboard` |  |
| `mouse` |  |
| `touch_app` |  |
| `backspace` |  |
| `power_settings_new` | `power` |

---

Icons: Material Symbols by Google, Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0).
