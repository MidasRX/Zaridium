// Builds tests/.smoke.luau = mock + bundle + test body, then runs it with plain `luau`.
// Usage: node tests/run.mjs [path/to/luau(.exe)]
import { readFileSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync, execFileSync } from "node:child_process";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const luau = process.argv[2] || process.env.LUAU || "luau";

const bundlePath = join(root, "tests", ".bundle.lua");
execFileSync(process.execPath, [join(root, "tools", "bundle.mjs"), "--version", "test", "--out", bundlePath], { stdio: "inherit" });
const mock = readFileSync(join(root, "tests", "mock.luau"), "utf8").replace(/^--!\w+\n/, "");
const bundle = readFileSync(bundlePath, "utf8");
const body = readFileSync(join(root, "tests", "smoke.luau"), "utf8").replace(/^--!\w+\n/, "");

const globalsNames = ["Vector2", "Color3", "UDim", "UDim2", "ColorSequence", "ColorSequenceKeypoint", "NumberSequence", "TweenInfo", "Enum", "Font", "Instance", "task", "game", "typeof", "warn"];
const shadow = globalsNames.map((n) => `local ${n} = __M.globals.${n}`).join("\n");
const nilGlobals = ["gethui", "getgenv", "writefile", "readfile", "isfile", "isfolder", "makefolder", "listfiles", "delfile", "getcustomasset", "setclipboard"];
const nils = nilGlobals.map((n) => `local ${n} = nil`).join("\n");

const out = `local __M = (function()\n${mock}\nend)()\n${shadow}\n${nils}\nlocal function __bundle()\n${bundle}\nend\n${body}\n`;
const file = join(root, "tests", ".smoke.luau");
writeFileSync(file, out);
const run = spawnSync(luau, [file], { encoding: "utf8" });
process.stdout.write(run.stdout || "");
process.stderr.write(run.stderr || "");
process.exit(run.status ?? 1);