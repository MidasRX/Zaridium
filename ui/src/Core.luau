--!nonstrict
-- Shared runtime state: theme roles + live binding, shape scale, flags and popups.

local Util = require("Util")
local Color = require("Color")

local RunService = game:GetService("RunService")

local Core = {
	Roles = {},
	Mode = "Dark",
	Seed = Color3.fromHex("#6750A4"),
	Preset = "Violet",
	Overrides = {},
	CornerScale = 1,
	Radius = { None = 0, XSmall = 4, Small = 8, Medium = 12, Large = 16, XLarge = 28 },

	Flags = {},
	Options = {},
	Listening = false,
	Keybinds = {},
	Popups = {},

	ThemeChanged = Util.Signal.new(),
	Maid = Util.Maid.new(),

	ScreenGui = nil,
	Overlay = nil,
	Window = nil,
}

-- instance -> { property -> role }
local bound = setmetatable({}, { __mode = "k" })
-- UICorner -> base radius in px
local corners = setmetatable({}, { __mode = "k" })
local themeConnection = nil

local function resolve(role)
	local kind = typeof(role)
	if kind == "string" then
		local color = Core.Roles[role]
		if color == nil then
			warn("[ZaridiumUI] unknown color role '" .. role .. "'")
			return Color3.new(1, 0, 1)
		end
		return color
	elseif kind == "function" then
		return role(Core.Roles)
	end
	return role
end

Core.Resolve = resolve

-- Sets a color property now and keeps it in sync with the theme. `role` is a role name, a Color3 or fn(roles) -> Color3.
function Core.Bind(instance, property, role)
	local props = bound[instance]
	if not props then
		props = {}
		bound[instance] = props
	end
	props[property] = role
	instance[property] = resolve(role)
end

-- Like Bind, but tweens to the new role (used for state changes such as selected/unselected).
function Core.Set(instance, property, role, duration)
	local props = bound[instance]
	if not props then
		props = {}
		bound[instance] = props
	end
	props[property] = role
	local color = resolve(role)
	if duration and duration > 0 then
		Util.Tween(instance, duration, { [property] = color }, Enum.EasingStyle.Quad)
	else
		instance[property] = color
	end
end

function Core.Unbind(instance)
	bound[instance] = nil
end

function Core.Corner(parent, radius)
	local corner = Instance.new("UICorner")
	if radius == "Full" then
		corner.CornerRadius = UDim.new(1, 0)
	else
		local base = Core.Radius[radius] or radius or 0
		corners[corner] = base
		corner.CornerRadius = UDim.new(0, math.floor(base * Core.CornerScale + 0.5))
	end
	corner.Parent = parent
	return corner
end

function Core.SetCornerScale(scale)
	Core.CornerScale = math.clamp(scale, 0, 2)
	for corner, base in corners do
		corner.CornerRadius = UDim.new(0, math.floor(base * Core.CornerScale + 0.5))
	end
end

--// Theme \\--
function Core.BuildRoles()
	local roles = Color.Generate(Core.Seed, Core.Mode)
	for role, color in Core.Overrides do
		if roles[role] ~= nil then
			roles[role] = color
		end
	end
	return roles
end

function Core.ApplyTheme(animate)
	Core.Roles = Core.BuildRoles()

	if themeConnection then
		themeConnection:Disconnect()
		themeConnection = nil
	end

	local entries = {}
	for instance, props in bound do
		for property, role in props do
			local ok, from = pcall(function()
				return instance[property]
			end)
			if ok and typeof(from) == "Color3" then
				table.insert(entries, { instance, property, from, resolve(role) })
			end
		end
	end

	if animate and Util.AnimationsEnabled and #entries <= 3000 then
		local started = os.clock()
		local duration = 0.3 / math.max(Util.Speed, 0.01)
		themeConnection = RunService.Heartbeat:Connect(function()
			local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
			local eased = 1 - (1 - alpha) ^ 3
			for _, entry in entries do
				entry[1][entry[2]] = entry[3]:Lerp(entry[4], eased)
			end
			if alpha >= 1 and themeConnection then
				themeConnection:Disconnect()
				themeConnection = nil
			end
		end)
	else
		for _, entry in entries do
			entry[1][entry[2]] = entry[4]
		end
	end

	Core.ThemeChanged:Fire(Core.Roles)
end

-- options: Mode, Preset (name), Seed (Color3 or "#hex"), Overrides (role -> Color3)
function Core.SetTheme(options, animate)
	if options.Mode and Color.Schemes[options.Mode] then
		Core.Mode = options.Mode
	end
	if options.Preset then
		local preset = Color.FindPreset(options.Preset)
		if preset then
			Core.Preset = preset.Name
			Core.Seed = Color3.fromHex(preset.Seed)
		end
	end
	if options.Seed then
		local seed = options.Seed
		if typeof(seed) == "string" then
			seed = Util.FromHex(seed)
		end
		if typeof(seed) == "Color3" then
			Core.Seed = seed
			if not options.Preset then
				Core.Preset = "Custom"
			end
		end
	end
	if options.Overrides then
		Core.Overrides = options.Overrides
	end
	Core.ApplyTheme(animate ~= false)
end

--// Popups (dropdown menus, pickers) \\--
function Core.RegisterPopup(close)
	table.insert(Core.Popups, close)
end

function Core.UnregisterPopup(close)
	local index = table.find(Core.Popups, close)
	if index then
		table.remove(Core.Popups, index)
	end
end

local justClosed = {}

function Core.ClosePopups(except, byOutsideClick)
	for _, close in table.clone(Core.Popups) do
		if close ~= except then
			if byOutsideClick then
				justClosed[close] = os.clock()
			end
			close()
		end
	end
end

-- True when `close` was closed by an outside click in the last 0.35s (stops the same click from reopening it).
function Core.WasJustClosed(close)
	local at = justClosed[close]
	return at ~= nil and os.clock() - at < 0.35
end

-- Replaced by the Library once the overlay exists.
function Core.ShowTooltip(_text: string, _host: GuiObject) end
function Core.HideTooltip(_host: GuiObject?) end

Core.Roles = Core.BuildRoles()

return Core
