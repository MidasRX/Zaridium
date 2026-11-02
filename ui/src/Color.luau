--!nonstrict
-- Material 3 style color scheme generator.
-- Tonal palettes are built in OKLCH (perceptual) with the tone mapped to CIELAB L*, so the
-- Material contrast guarantees (tone 40 vs 100, 80 vs 20, ...) hold without a full HCT port.

local Color = {}

local function toLinear(c: number): number
	if c <= 0.04045 then
		return c / 12.92
	end
	return ((c + 0.055) / 1.055) ^ 2.4
end

local function toSrgb(c: number): number
	if c <= 0.0031308 then
		return 12.92 * c
	end
	return 1.055 * (c ^ (1 / 2.4)) - 0.055
end

-- sRGB (0..1) -> OKLab
local function rgbToOKLab(r: number, g: number, b: number): (number, number, number)
	r, g, b = toLinear(r), toLinear(g), toLinear(b)
	local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
	local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
	local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
	return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end

-- OKLab -> linear sRGB (may be out of gamut)
local function oklabToLinear(L: number, a: number, b: number): (number, number, number)
	local l = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
	local m = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
	local s = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3
	return 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
end

local function inGamut(r: number, g: number, b: number): boolean
	return r >= -0.0005 and g >= -0.0005 and b >= -0.0005 and r <= 1.0005 and g <= 1.0005 and b <= 1.0005
end

local function toneToL(tone: number): number
	if tone <= 0 then
		return 0
	elseif tone >= 100 then
		return 1
	elseif tone > 8 then
		return (tone + 16) / 116
	end
	return (tone / 903.2963) ^ (1 / 3)
end

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

-- Returns r, g, b (sRGB 0..1) for a hue (deg), chroma (OKLCH) and tone (0..100), reducing chroma to fit sRGB.
function Color.ToneRGB(hue: number, chroma: number, tone: number): (number, number, number)
	local L = toneToL(tone)
	local h = math.rad(hue)
	local ca, sb = math.cos(h), math.sin(h)
	local r, g, b = oklabToLinear(L, ca * chroma, sb * chroma)
	if not inGamut(r, g, b) then
		local lo, hi = 0, chroma
		for _ = 1, 18 do
			local mid = (lo + hi) / 2
			local mr, mg, mb = oklabToLinear(L, ca * mid, sb * mid)
			if inGamut(mr, mg, mb) then
				lo = mid
			else
				hi = mid
			end
		end
		r, g, b = oklabToLinear(L, ca * lo, sb * lo)
	end
	return clamp01(toSrgb(math.max(r, 0))), clamp01(toSrgb(math.max(g, 0))), clamp01(toSrgb(math.max(b, 0)))
end

function Color.Tone(hue, chroma, tone)
	local r, g, b = Color.ToneRGB(hue, chroma, tone)
	return Color3.new(r, g, b)
end

-- Returns hue (deg), chroma, lightness of a color in OKLCH.
function Color.Analyze(color)
	local L, a, b = rgbToOKLab(color.R, color.G, color.B)
	return math.deg(math.atan2(b, a)) % 360, math.sqrt(a * a + b * b), L
end

--// Role tables: { palette, tone } \\--
-- p primary, s secondary, t tertiary, n neutral, v neutral-variant, e error, g success, w warning

local DARK = {
	Primary = { "p", 80 },
	OnPrimary = { "p", 20 },
	PrimaryContainer = { "p", 30 },
	OnPrimaryContainer = { "p", 90 },
	Secondary = { "s", 80 },
	OnSecondary = { "s", 20 },
	SecondaryContainer = { "s", 30 },
	OnSecondaryContainer = { "s", 90 },
	Tertiary = { "t", 80 },
	OnTertiary = { "t", 20 },
	TertiaryContainer = { "t", 30 },
	OnTertiaryContainer = { "t", 90 },
	Error = { "e", 80 },
	OnError = { "e", 20 },
	ErrorContainer = { "e", 30 },
	OnErrorContainer = { "e", 90 },
	Success = { "g", 80 },
	OnSuccess = { "g", 20 },
	SuccessContainer = { "g", 30 },
	OnSuccessContainer = { "g", 90 },
	Warning = { "w", 80 },
	OnWarning = { "w", 20 },
	WarningContainer = { "w", 30 },
	OnWarningContainer = { "w", 90 },
	Background = { "n", 6 },
	OnBackground = { "n", 90 },
	Surface = { "n", 6 },
	OnSurface = { "n", 90 },
	SurfaceVariant = { "v", 30 },
	OnSurfaceVariant = { "v", 80 },
	SurfaceDim = { "n", 6 },
	SurfaceBright = { "n", 24 },
	SurfaceContainerLowest = { "n", 4 },
	SurfaceContainerLow = { "n", 10 },
	SurfaceContainer = { "n", 12 },
	SurfaceContainerHigh = { "n", 17 },
	SurfaceContainerHighest = { "n", 22 },
	Outline = { "v", 60 },
	OutlineVariant = { "v", 30 },
	InverseSurface = { "n", 90 },
	InverseOnSurface = { "n", 20 },
	InversePrimary = { "p", 40 },
	SurfaceTint = { "p", 80 },
	Scrim = { "n", 0 },
	Shadow = { "n", 0 },
}

local LIGHT = {
	Primary = { "p", 40 },
	OnPrimary = { "p", 100 },
	PrimaryContainer = { "p", 90 },
	OnPrimaryContainer = { "p", 10 },
	Secondary = { "s", 40 },
	OnSecondary = { "s", 100 },
	SecondaryContainer = { "s", 90 },
	OnSecondaryContainer = { "s", 10 },
	Tertiary = { "t", 40 },
	OnTertiary = { "t", 100 },
	TertiaryContainer = { "t", 90 },
	OnTertiaryContainer = { "t", 10 },
	Error = { "e", 40 },
	OnError = { "e", 100 },
	ErrorContainer = { "e", 90 },
	OnErrorContainer = { "e", 10 },
	Success = { "g", 40 },
	OnSuccess = { "g", 100 },
	SuccessContainer = { "g", 90 },
	OnSuccessContainer = { "g", 10 },
	Warning = { "w", 40 },
	OnWarning = { "w", 100 },
	WarningContainer = { "w", 90 },
	OnWarningContainer = { "w", 10 },
	Background = { "n", 98 },
	OnBackground = { "n", 10 },
	Surface = { "n", 98 },
	OnSurface = { "n", 10 },
	SurfaceVariant = { "v", 90 },
	OnSurfaceVariant = { "v", 30 },
	SurfaceDim = { "n", 87 },
	SurfaceBright = { "n", 98 },
	SurfaceContainerLowest = { "n", 100 },
	SurfaceContainerLow = { "n", 96 },
	SurfaceContainer = { "n", 94 },
	SurfaceContainerHigh = { "n", 92 },
	SurfaceContainerHighest = { "n", 90 },
	Outline = { "v", 50 },
	OutlineVariant = { "v", 80 },
	InverseSurface = { "n", 20 },
	InverseOnSurface = { "n", 95 },
	InversePrimary = { "p", 80 },
	SurfaceTint = { "p", 40 },
	Scrim = { "n", 0 },
	Shadow = { "n", 0 },
}

local AMOLED = table.clone(DARK)
AMOLED.Background = { "n", 0 }
AMOLED.Surface = { "n", 0 }
AMOLED.SurfaceDim = { "n", 0 }
AMOLED.SurfaceContainerLowest = { "n", 0 }
AMOLED.SurfaceContainerLow = { "n", 4 }
AMOLED.SurfaceContainer = { "n", 7 }
AMOLED.SurfaceContainerHigh = { "n", 11 }
AMOLED.SurfaceContainerHighest = { "n", 15 }

Color.Schemes = { Dark = DARK, Light = LIGHT, Amoled = AMOLED }
Color.Modes = { "Dark", "Light", "Amoled" }

Color.Presets = {
	{ Name = "Violet", Seed = "#6750A4" },
	{ Name = "Indigo", Seed = "#4355B9" },
	{ Name = "Blue", Seed = "#0B57D0" },
	{ Name = "Sky", Seed = "#00668B" },
	{ Name = "Teal", Seed = "#006A6A" },
	{ Name = "Green", Seed = "#386A20" },
	{ Name = "Lime", Seed = "#5B6300" },
	{ Name = "Amber", Seed = "#7D5700" },
	{ Name = "Orange", Seed = "#A33F00" },
	{ Name = "Red", Seed = "#B3261E" },
	{ Name = "Rose", Seed = "#B4004E" },
	{ Name = "Magenta", Seed = "#9C27B0" },
	{ Name = "Slate", Seed = "#5E6577" },
}

function Color.PresetNames()
	local names = {}
	for _, preset in Color.Presets do
		table.insert(names, preset.Name)
	end
	return names
end

function Color.FindPreset(name)
	for _, preset in Color.Presets do
		if preset.Name == name then
			return preset
		end
	end
	return nil
end

-- Generates every color role for a seed color. mode: "Dark" | "Light" | "Amoled".
function Color.Generate(seed, mode)
	local hue, chroma = Color.Analyze(seed)
	local neutralSeed = chroma < 0.02
	local pc = neutralSeed and 0.012 or math.clamp(chroma, 0.07, 0.15)

	local palettes = {
		p = { hue, pc },
		s = { hue, pc * 0.38 },
		t = { hue + 60, pc * 0.6 },
		n = { hue, neutralSeed and 0.004 or 0.012 },
		v = { hue, neutralSeed and 0.006 or 0.02 },
		e = { 29, 0.2 },
		g = { 145, 0.15 },
		w = { 85, 0.14 },
	}

	local scheme = Color.Schemes[mode] or DARK
	local roles = {}
	for role, spec in scheme do
		local palette = palettes[spec[1]]
		roles[role] = Color.Tone(palette[1], palette[2], spec[2])
	end
	return roles
end

return Color
