--!nonstrict
-- Downloads, validates and caches the bundled fonts + icon atlas, with safe fallbacks.
-- Nothing here ever throws: if the executor cannot cache files, the library falls back to
-- Roblox's built-in Gotham family and text-only icons.

local HttpService = game:GetService("HttpService")

-- Executor globals are optional; capture them once as `any` and guard with canCache().
local writefile: any, readfile: any, isfile: any, isfolder: any, makefolder: any, getcustomasset: any =
	writefile, readfile, isfile, isfolder, makefolder, getcustomasset

local Assets = {
	Ready = false,
	Cached = false, -- true when the Google Sans Flex fonts were loaded
	Rounded = true,
	Atlas = "",
	Status = "not initialised",
	Registry = setmetatable({}, { __mode = "k" }),
}

local WEIGHTS = {
	Regular = Enum.FontWeight.Regular,
	Medium = Enum.FontWeight.Medium,
	SemiBold = Enum.FontWeight.SemiBold,
	Bold = Enum.FontWeight.Bold,
}
local FACE_ORDER = { "Regular", "Medium", "SemiBold", "Bold" }
local FACE_WEIGHT = { Regular = 400, Medium = 500, SemiBold = 600, Bold = 700 }
local FALLBACK_FAMILY = "rbxasset://fonts/families/GothamSSm.json"

local families = { Standard = nil, Rounded = nil } -- uri strings
local customFont = nil
local fontCache = {}

local function isTtf(data)
	return #data > 1000 and (data:sub(1, 4) == "\0\1\0\0" or data:sub(1, 4) == "true" or data:sub(1, 4) == "OTTO")
end

local function isPng(data)
	return #data > 100 and data:sub(1, 4) == "\137PNG"
end

local function canCache()
	return writefile ~= nil and readfile ~= nil and isfile ~= nil and makefolder ~= nil and getcustomasset ~= nil
end

local function ensureFolder(path)
	if not isfolder(path) then
		makefolder(path)
	end
end

local function fetch(folder, baseUrl, remote, localName, validate)
	local path = folder .. "/" .. localName
	if isfile(path) then
		local ok, data = pcall(readfile, path)
		if ok and typeof(data) == "string" and validate(data) then
			return path
		end
	end
	local ok, data = pcall(function()
		return (game :: any):HttpGet(baseUrl .. remote, true)
	end)
	if ok and typeof(data) == "string" and validate(data) then
		local wrote = pcall(writefile, path, data)
		if wrote then
			return path
		end
	end
	return nil
end

local function buildFamily(folder, baseUrl, prefix, jsonName)
	local faces = {}
	for _, name in FACE_ORDER do
		local file = prefix .. "-" .. name .. ".ttf"
		local path = fetch(folder, baseUrl, "fonts/" .. file, file, isTtf)
		if not path then
			return nil
		end
		local ok, asset = pcall(getcustomasset, path)
		if not ok or typeof(asset) ~= "string" or asset == "" then
			return nil
		end
		table.insert(faces, { name = name, weight = FACE_WEIGHT[name], style = "normal", assetId = asset })
	end
	local jsonPath = folder .. "/" .. jsonName
	local wrote = pcall(writefile, jsonPath, HttpService:JSONEncode({ name = prefix, faces = faces }))
	if not wrote then
		return nil
	end
	local ok, uri = pcall(getcustomasset, jsonPath)
	if ok and typeof(uri) == "string" and uri ~= "" then
		return uri
	end
	return nil
end

-- config: AssetBaseUrl, CacheFolder, Version, RoundedFont, Font (Font), AtlasImage (string), Offline (bool)
function Assets.Init(config)
	config = config or {}
	Assets.Rounded = config.RoundedFont ~= false
	table.clear(fontCache)
	families.Standard, families.Rounded, customFont = nil, nil, nil

	if typeof(config.Font) == "Font" then
		customFont = config.Font
	end
	if typeof(config.AtlasImage) == "string" and config.AtlasImage ~= "" then
		Assets.Atlas = config.AtlasImage
	end

	if config.Offline or not canCache() then
		Assets.Status = config.Offline and "offline mode" or "executor has no file/asset API"
		Assets.Ready = true
		return
	end

	local baseUrl = config.AssetBaseUrl or "https://raw.githubusercontent.com/MidasRX/Zaridium/main/ui/assets/"
	if baseUrl:sub(-1) ~= "/" then
		baseUrl ..= "/"
	end
	local root = config.CacheFolder or "ZaridiumUI"
	local folder = root .. "/assets-" .. tostring(config.Version or "1")

	local prepared = pcall(function()
		ensureFolder(root)
		ensureFolder(folder)
	end)
	if not prepared then
		Assets.Status = "could not create cache folder"
		Assets.Ready = true
		return
	end

	if not customFont then
		local okStd, std = pcall(buildFamily, folder, baseUrl, "GoogleSansFlex", "family-standard.json")
		local okRnd, rnd = pcall(buildFamily, folder, baseUrl, "GoogleSansFlexRounded", "family-rounded.json")
		families.Standard = okStd and std or nil
		families.Rounded = okRnd and rnd or nil
		Assets.Cached = families.Standard ~= nil or families.Rounded ~= nil
	end

	if Assets.Atlas == "" then
		local path = fetch(folder, baseUrl, "icons/atlas.png", "atlas.png", isPng)
		if path then
			local ok, asset = pcall(getcustomasset, path)
			if ok and typeof(asset) == "string" then
				Assets.Atlas = asset
			end
		end
	end

	Assets.Status = string.format(
		"fonts=%s icons=%s",
		customFont and "custom" or (Assets.Cached and "Google Sans Flex" or "fallback"),
		Assets.Atlas ~= "" and "atlas" or "none"
	)
	Assets.Ready = true
end

function Assets.Font(weight)
	weight = weight or "Regular"
	local key = weight .. (Assets.Rounded and "R" or "S")
	local cached = fontCache[key]
	if cached then
		return cached
	end
	local enumWeight = WEIGHTS[weight] or Enum.FontWeight.Regular
	local font
	if customFont then
		font = Font.new(customFont.Family, enumWeight, Enum.FontStyle.Normal)
	else
		local uri = (Assets.Rounded and families.Rounded) or families.Standard or families.Rounded or FALLBACK_FAMILY
		font = Font.new(uri, enumWeight, Enum.FontStyle.Normal)
	end
	fontCache[key] = font
	return font
end

-- Applies the font to a text object and keeps it updated when the font style changes.
function Assets.Apply(textObject, weight)
	Assets.Registry[textObject] = weight
	textObject.FontFace = Assets.Font(weight)
end

function Assets.SetRounded(enabled)
	Assets.Rounded = enabled and true or false
	for object, weight in pairs(Assets.Registry) do
		object.FontFace = Assets.Font(weight)
	end
end

return Assets
