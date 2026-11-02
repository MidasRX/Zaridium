// Builds the Material Symbols (Rounded) icon atlas, src/IconData.luau and docs/ICONS.md.
// Usage (from UI): node tools/build-icons.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { Resvg } from "@resvg/resvg-js";
import { PNG } from "pngjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const ui = path.resolve(here, "..");
const require = createRequire(import.meta.url);
const svgDir = path.join(path.dirname(require.resolve("@material-symbols/svg-400/package.json")), "rounded");

const CELL = 64, COLS = 16, MAX_ROWS = 16;
const MAX_ICONS = Math.floor((COLS * MAX_ROWS) / 2);

// Priority order. Anything beyond MAX_ICONS is dropped.
const NAMES = `home settings search close check add remove menu more_vert more_horiz chevron_right chevron_left expand_more expand_less arrow_back arrow_forward arrow_upward arrow_downward person group groups person_add visibility visibility_off lock lock_open key bolt flight speed shield security code terminal bug_report build tune palette dark_mode light_mode brush format_paint colorize notifications notifications_off info warning error check_circle cancel help star favorite bookmark folder folder_open description save download upload content_copy content_paste delete edit refresh sync play_arrow pause stop power_settings_new public language wifi cloud storage memory extension apps dashboard list sports_esports my_location explore map gps_fixed crop_free swap_horiz swap_vert keyboard mouse touch_app backspace logout login open_in_new link filter_list sort tab layers animation text_fields opacity schedule timer history bar_chart trending_up emoji_events rocket_launch admin_panel_settings verified verified_user flag label widgets toggle_on toggle_off radio_button_checked radio_button_unchecked check_box check_box_outline_blank smart_toy drag_handle drag_indicator open_in_full close_fullscreen minimize fullscreen fullscreen_exit side_navigation left_panel_open left_panel_close view_sidebar home_repair_service sports_martial_arts swords target ads_click radar directions_run accessibility_new visibility_lock zoom_in zoom_out camera videocam mic volume_up volume_off music_note image brightness_6 contrast water_drop auto_awesome science casino tips_and_updates support_agent forum chat mail send share qr_code fingerprint password vpn_key copyright gavel policy privacy_tip sync_lock cloud_download cloud_upload restart_alt undo redo done_all priority_high new_releases campaign whatshot local_fire_department pets`.split(/\s+/);

// Requested name -> closest existing source glyph (name kept as the public icon key).
const SUBSTITUTE = {
  expand_more: "keyboard_arrow_down",
  expand_less: "keyboard_arrow_up",
  gps_fixed: "location_searching",
  emoji_events: "trophy",
  auto_awesome: "star_shine",
  tips_and_updates: "lightbulb",
  new_releases: "release_alert",
};

const ALIASES = {
  x: "close", cross: "close", gear: "settings", cog: "settings", user: "person", users: "group",
  eye: "visibility", eye_off: "visibility_off", trash: "delete", copy: "content_copy",
  paste: "content_paste", power: "power_settings_new", play: "play_arrow", plus: "add", minus: "remove",
  check_mark: "check", tick: "check", search_icon: "search", magnify: "search", sliders: "tune",
  crosshair: "my_location", plane: "flight", sword: "swords", theme: "palette", moon: "dark_mode",
  sun: "light_mode", hamburger: "menu", dots_vertical: "more_vert", dots_horizontal: "more_horiz",
  down: "expand_more", up: "expand_less", back: "arrow_back", forward: "arrow_forward",
  next: "chevron_right", prev: "chevron_left", warn: "warning", fire: "whatshot", flame: "local_fire_department",
  game: "sports_esports", gamepad: "sports_esports", fly: "flight", run: "directions_run",
  walk: "directions_run", bell: "notifications", mute: "volume_off", sound: "volume_up", bug: "bug_report",
  tools: "build", wrench: "build", pencil: "edit", reload: "refresh", rocket: "rocket_launch",
  trophy: "emoji_events", sparkle: "auto_awesome", bulb: "tips_and_updates", globe: "public",
  external: "open_in_new", save_icon: "save", file: "description", heart: "favorite", crosshairs: "gps_fixed",
  aim: "ads_click", esp: "visibility", aimbot: "ads_click", fullscreen_icon: "fullscreen",
};

const CATEGORIES = {
  "Navigation & actions": "home menu more_vert more_horiz chevron_right chevron_left expand_more expand_less arrow_back arrow_forward arrow_upward arrow_downward close check add remove open_in_new open_in_full close_fullscreen fullscreen fullscreen_exit minimize swap_horiz swap_vert login logout drag_handle drag_indicator side_navigation left_panel_open left_panel_close view_sidebar undo redo done_all restart_alt refresh sync",
  "Controls & forms": "toggle_on toggle_off radio_button_checked radio_button_unchecked check_box check_box_outline_blank search filter_list sort tune text_fields settings widgets apps dashboard list tab layers",
  "People & security": "person group groups person_add visibility visibility_off visibility_lock lock lock_open key vpn_key password fingerprint shield security verified verified_user admin_panel_settings policy privacy_tip gavel sync_lock accessibility_new support_agent",
  "Status & feedback": "info warning error check_circle cancel help priority_high new_releases notifications notifications_off campaign flag label",
  "Files & data": "folder folder_open description save download upload content_copy content_paste delete edit cloud cloud_download cloud_upload storage memory history schedule timer bar_chart trending_up qr_code copyright",
  "Developer": "code terminal bug_report build extension home_repair_service smart_toy science",
  "Appearance": "palette dark_mode light_mode brush format_paint colorize opacity brightness_6 contrast water_drop animation auto_awesome",
  "Game & targeting": "sports_esports sports_martial_arts swords target ads_click radar my_location gps_fixed crop_free explore map flight speed bolt directions_run rocket_launch emoji_events casino whatshot local_fire_department pets star favorite bookmark tips_and_updates",
  "Media & communication": "play_arrow pause stop camera videocam mic volume_up volume_off music_note image zoom_in zoom_out forum chat mail send share link public language wifi keyboard mouse touch_app backspace power_settings_new",
};

const read = (n, fill) => {
  const f = path.join(svgDir, `${SUBSTITUTE[n] ?? n}${fill ? "-fill" : ""}.svg`);
  return fs.existsSync(f) ? fs.readFileSync(f, "utf8") : null;
};

function render(svg) {
  const white = svg.replace(/<svg\b/, '<svg fill="#fff"');
  const png = new Resvg(white, { fitTo: { mode: "width", value: CELL } }).render().asPng();
  const img = PNG.sync.read(png);
  if (img.width !== CELL || img.height !== CELL) throw new Error(`bad size ${img.width}x${img.height}`);
  for (let i = 0; i < img.data.length; i += 4) {
    const a = img.data[i + 3];
    img.data[i] = img.data[i + 1] = img.data[i + 2] = a > 0 ? 255 : 0;
  }
  return img;
}

const icons = [], dropped = [], missing = [];
for (const n of NAMES) {
  const o = read(n, false), f = read(n, true);
  if (!o || !f) { missing.push(n); continue; }
  if (icons.length >= MAX_ICONS) { dropped.push(n); continue; }
  icons.push({ name: n, o, f });
}

const rows = Math.ceil((icons.length * 2) / COLS);
const atlas = new PNG({ width: COLS * CELL, height: rows * CELL });
atlas.data.fill(0);
const place = (img, idx) => {
  const x0 = (idx % COLS) * CELL, y0 = Math.floor(idx / COLS) * CELL;
  PNG.bitblt(img, atlas, 0, 0, CELL, CELL, x0, y0);
};
const pos = (idx) => `{ ${(idx % COLS) * CELL}, ${Math.floor(idx / COLS) * CELL} }`;

const lines = [];
icons.forEach((ic, i) => {
  place(render(ic.o), 2 * i);
  place(render(ic.f), 2 * i + 1);
  lines.push(`\t\t${ic.name} = { o = ${pos(2 * i)}, f = ${pos(2 * i + 1)} },`);
});

const have = new Set(icons.map((i) => i.name));
const aliasLines = Object.entries(ALIASES)
  .filter(([a, t]) => have.has(t) && !have.has(a))
  .map(([a, t]) => `\t\t${a} = "${t}",`);

fs.mkdirSync(path.join(ui, "assets", "icons"), { recursive: true });
fs.mkdirSync(path.join(ui, "src"), { recursive: true });
fs.mkdirSync(path.join(ui, "docs"), { recursive: true });
fs.writeFileSync(path.join(ui, "assets", "icons", "atlas.png"), PNG.sync.write(atlas));

fs.writeFileSync(
  path.join(ui, "src", "IconData.luau"),
  `--!strict
-- AUTO-GENERATED by tools/build-icons.mjs. Do not edit.
return {
\tCell = ${CELL},
\tWidth = ${COLS * CELL},
\tHeight = ${rows * CELL},
\tIcons = {
${lines.join("\n")}
\t},
\tAliases = {
${aliasLines.join("\n")}
\t},
}
`
);

// docs
const aliasOf = {};
for (const [a, t] of Object.entries(ALIASES)) if (have.has(t) && !have.has(a)) (aliasOf[t] ??= []).push(a);
const used = new Set();
let md = `# Icons

Material Symbols (Rounded, weight 400) packed into a single white-on-transparent atlas
(\`assets/icons/atlas.png\`, ${COLS * CELL}x${rows * CELL}, ${CELL}px cells). Cell layout and lookups live in \`src/IconData.luau\`.

## Usage

\`\`\`lua
icon = "home"       -- canonical name
icon = "gear"       -- alias, resolves to "settings"
\`\`\`

Each icon has an outline variant (default) and a filled variant, used for the selected / active state.
Icons are white so they can be tinted with \`ImageColor3\`. Names are case-sensitive, snake_case.

Total: ${icons.length} icons, ${Object.values(aliasOf).flat().length} aliases.
`;
const row = (n) => `| \`${n}\` | ${(aliasOf[n] ?? []).map((a) => `\`${a}\``).join(", ")} |`;
for (const [cat, list] of Object.entries(CATEGORIES)) {
  const ns = list.split(" ").filter((n) => have.has(n) && !used.has(n));
  ns.forEach((n) => used.add(n));
  if (ns.length) md += `\n## ${cat}\n\n| Name | Aliases |\n| --- | --- |\n${ns.map(row).join("\n")}\n`;
}
const rest = icons.map((i) => i.name).filter((n) => !used.has(n));
if (rest.length) md += `\n## Other\n\n| Name | Aliases |\n| --- | --- |\n${rest.map(row).join("\n")}\n`;
md += `\n---\n\nIcons: Material Symbols by Google, Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0).\n`;
fs.writeFileSync(path.join(ui, "docs", "ICONS.md"), md);

console.log(`icons=${icons.length} atlas=${COLS * CELL}x${rows * CELL} aliases=${aliasLines.length}`);
console.log("substituted:", Object.entries(SUBSTITUTE).filter(([k]) => have.has(k)).map(([k, v]) => `${k}->${v}`).join(", "));
console.log("dropped (atlas full):", dropped.join(" "));
if (missing.length) console.log("missing:", missing.join(" "));
