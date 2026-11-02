--!nonstrict
-- Public entry point of Zaridium UI (Material 3 edition).

local Util = require("Util")
local Color = require("Color")
local Core = require("Core")
local Assets = require("Assets")
local Icons = require("Icons")
local Components = require("Components")
local Controls = require("Controls")
local Window = require("Window")

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local Frame, Text, List, Padding = Components.Frame, Components.Text, Components.List, Components.Padding

local VERSION = "1.0.0"

local Library = {
	Version = VERSION,
	Flags = Core.Flags,
	Options = Core.Options,
	Util = Util,
	Color = Color,
	Icons = Icons,
	Controls = Controls,
	Changed = Util.Signal.new(),
	Unloading = Util.Signal.new(),
	ToggleKey = Enum.KeyCode.RightControl,
	Unloaded = false,
	Window = nil,
	Root = nil,
	UIScale = nil :: UIScale?,
}

-- Executor globals are optional: capture them as `any` and check with typeof() before calling.
local writefile: any, readfile: any, isfile: any, isfolder: any, makefolder: any, listfiles: any, delfile: any =
	writefile, readfile, isfile, isfolder, makefolder, listfiles, delfile
local gethui: any, getgenv: any = gethui, getgenv

local initialised = false
local notifications = {}
local notificationHolder = nil
local maid = Util.Maid.new()
local dialogLayer = nil

local function protectedParent()
	local ok, parent = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and parent then
		return parent
	end
	local okCore = pcall(function()
		return CoreGui.Name
	end)
	if okCore then
		return CoreGui
	end
	local player = Players.LocalPlayer
	return player and player:FindFirstChildOfClass("PlayerGui") or nil
end

-- Reads executor globals defensively (they may be nil).
local function executorFn(name)
	local env = typeof(getgenv) == "function" and getgenv() or nil
	local value = env and env[name] or nil
	return typeof(value) == "function" and value or nil
end

--// Setup \\--
-- config: Title, Subtitle, Icon, Theme{Mode,Preset,Seed,Overrides}, Size (Vector2), Scale (number), ToggleKey, AutoShow,
--         Profile (false | {DisplayName,Username,UserId,Image,OnClick}), Offline, AssetBaseUrl, CacheFolder, Font (Font),
--         RoundedFont, Animations, Ripple, AnimationSpeed, Resizable, Search, ThemeButton, ConfirmClose, Name, MinSize
function Library:CreateWindow(config)
	config = config or {}
	if Library.Window then
		warn("[ZaridiumUI] a window already exists; destroying the previous one")
		Library:Unload()
	end
	Library.Unloaded = false

	Util.AnimationsEnabled = config.Animations ~= false
	Util.RippleEnabled = config.Ripple ~= false
	Util.Speed = config.AnimationSpeed or 1

	Assets.Init({
		AssetBaseUrl = config.AssetBaseUrl,
		CacheFolder = config.CacheFolder,
		Version = VERSION,
		RoundedFont = config.RoundedFont,
		Font = config.Font,
		AtlasImage = config.AtlasImage,
		Offline = config.Offline,
	})

	local theme = config.Theme or {}
	Core.Mode = Color.Schemes[theme.Mode] and theme.Mode or "Dark"
	Core.Overrides = theme.Overrides or {}
	local preset = theme.Preset and Color.FindPreset(theme.Preset)
	if preset then
		Core.Preset = preset.Name
		Core.Seed = Color3.fromHex(preset.Seed)
	end
	if theme.Seed then
		local seed = typeof(theme.Seed) == "string" and Util.FromHex(theme.Seed) or theme.Seed
		if typeof(seed) == "Color3" then
			Core.Seed = seed
			Core.Preset = "Custom"
		end
	end
	if config.CornerScale then
		Core.CornerScale = math.clamp(config.CornerScale, 0, 2)
	end
	Core.Roles = Core.BuildRoles()

	Library.ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl

	local gui = Instance.new("ScreenGui")
	gui.Name = config.Name or ("ZaridiumUI_" .. string.sub(HttpService:GenerateGUID(false), 1, 8))
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10000
	gui.ScreenInsets = Enum.ScreenInsets.None
	local protect = executorFn("protectgui") or executorFn("protect_gui")
	if protect then
		pcall(protect, gui)
	end
	gui.Parent = protectedParent()
	Core.ScreenGui = gui

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = 1
	root.Parent = gui
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = root
	Library.Root = root
	Library.UIScale = uiScale
	Core.Overlay = root

	local function updateScale()
		if config.Scale then
			uiScale.Scale = config.Scale
		else
			local viewport = gui.AbsoluteSize
			local base = math.min(viewport.X / 1280, viewport.Y / 720)
			uiScale.Scale = math.clamp(base, 0.6, 1.25)
		end
		Util.Scale = uiScale.Scale
	end
	updateScale()
	maid:Give(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale))

	-- Click-away layer that closes popups
	local blocker = Instance.new("TextButton")
	blocker.Name = "PopupBlocker"
	blocker.BackgroundTransparency = 1
	blocker.Text = ""
	blocker.AutoButtonColor = false
	blocker.Size = UDim2.fromScale(1, 1)
	blocker.ZIndex = 250
	blocker.Visible = false
	blocker.Parent = root
	maid:Give(blocker.Activated:Connect(function()
		Core.ClosePopups(nil, true)
	end))
	local registerPopup, unregisterPopup = Core.RegisterPopup, Core.UnregisterPopup
	function Core.RegisterPopup(close)
		registerPopup(close)
		blocker.Visible = true
	end
	function Core.UnregisterPopup(close)
		unregisterPopup(close)
		blocker.Visible = #Core.Popups > 0
	end

	Components.InstallTooltips(root)

	-- Notification stack (top right)
	notificationHolder = Frame({
		Name = "Notifications",
		Size = UDim2.new(0, 360, 1, -32),
		Position = UDim2.new(1, -16, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		ZIndex = 500,
		Parent = root,
	})
	List(notificationHolder, 8, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top)

	dialogLayer = Frame({ Name = "Dialogs", Size = UDim2.fromScale(1, 1), ZIndex = 600, Parent = root })
	dialogLayer.Visible = false

	local profile = config.Profile
	local window = Window.new(Library, {
		Title = config.Title,
		Subtitle = config.Subtitle,
		Icon = config.Icon,
		Size = config.Size,
		MinSize = config.MinSize,
		Profile = profile,
		Resizable = config.Resizable,
		Search = config.Search,
		ThemeButton = config.ThemeButton,
		ConfirmClose = config.ConfirmClose,
	})
	Library.Window = window
	Core.Window = window

	local env = typeof(getgenv) == "function" and getgenv() or nil
	if env then
		env.ZaridiumUI = Library
	end

	-- Global toggle key + Escape closes popups
	maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if Library.Unloaded or Core.Listening then
			return
		end
		if input.KeyCode == Library.ToggleKey and not UserInputService:GetFocusedTextBox() then
			window:Toggle()
		elseif input.KeyCode == Enum.KeyCode.Escape and #Core.Popups > 0 and not processed then
			Core.ClosePopups()
		end
	end))

	initialised = true
	if config.AutoShow ~= false then
		task.defer(function()
			if not Library.Unloaded then
				window:SetVisible(true)
			end
		end)
	end
	return window
end

--// Notifications \\--
-- opts: Title, Content, Duration (seconds, 0 = sticky), Type ("Info"|"Success"|"Warning"|"Error"), Icon, Action = { Text, Callback }
function Library:Notify(opts)
	if not initialised or Library.Unloaded then
		return nil
	end
	if typeof(opts) == "string" then
		opts = { Content = opts }
	end
	local kind = opts.Type or "Info"
	local palette = {
		Info = { bg = "SecondaryContainer", fg = "OnSecondaryContainer", icon = "info" },
		Success = { bg = "SuccessContainer", fg = "OnSuccessContainer", icon = "check_circle" },
		Warning = { bg = "WarningContainer", fg = "OnWarningContainer", icon = "warning" },
		Error = { bg = "ErrorContainer", fg = "OnErrorContainer", icon = "error" },
	}
	local style = palette[kind] or palette.Info

	local slot = Frame({
		Name = "Slot",
		Size = UDim2.new(1, 0, 0, 0),
		AutoSize = "Y",
		Parent = notificationHolder,
	})
	slot.LayoutOrder = os.clock() * 1000
	local card = Frame({
		Name = "Notification",
		Canvas = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutoSize = "Y",
		Position = UDim2.fromOffset(380, 0),
		Role = style.bg,
		Radius = "Large",
		ZIndex = 501,
		Parent = slot,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	Core.Bind(stroke, "Color", "OutlineVariant")
	stroke.Parent = card
	local inner = Frame({ Size = UDim2.new(1, 0, 0, 0), AutoSize = "Y", ZIndex = 502, Parent = card })
	Padding(inner, 14, 14, 14, 14)
	local icon = Icons.Create(opts.Icon or style.icon, {
		Size = 24,
		Color = style.fg,
		Position = UDim2.fromOffset(0, 0),
		Parent = inner,
		ZIndex = 503,
	})
	local textBlock = Frame({
		Size = UDim2.new(1, -66, 0, 0),
		AutoSize = "Y",
		Position = UDim2.fromOffset(36, 0),
		ZIndex = 503,
		Parent = inner,
	})
	List(textBlock, 2)
	if opts.Title then
		Text({
			Parent = textBlock,
			Text = opts.Title,
			Style = "TitleSmall",
			Role = style.fg,
			Size = UDim2.new(1, 0, 0, 20),
			Wrap = true,
			AutoSize = "Y",
			ZIndex = 504,
		})
	end
	if opts.Content then
		local body = Text({
			Parent = textBlock,
			Text = opts.Content,
			Style = "BodyMedium",
			Role = style.fg,
			Size = UDim2.new(1, 0, 0, 0),
			Wrap = true,
			AutoSize = "Y",
			ZIndex = 504,
			LayoutOrder = 1,
		})
		body.TextTransparency = 0.12
	end
	if opts.Action then
		local actionButton = Frame({
			Name = "Action",
			Size = UDim2.fromOffset(0, 32),
			AutoSize = "X",
			Radius = "Full",
			ZIndex = 504,
			Parent = textBlock,
		})
		actionButton.LayoutOrder = 2
		Padding(actionButton, 0, 8, 0, 8)
		Text({
			Parent = actionButton,
			Text = opts.Action.Text or "Action",
			Style = "LabelLarge",
			Role = style.fg,
			Size = UDim2.fromOffset(0, 32),
			AutoSize = "X",
			ZIndex = 505,
		})
		Components.Interactive(actionButton, {
			Radius = "Full",
			StateRole = style.fg,
			ZIndex = 504,
			OnClick = function()
				if opts.Action.Callback then
					task.spawn(opts.Action.Callback)
				end
			end,
		})
	end
	local close
	Components.IconButton({
		Parent = inner,
		Icon = "close",
		Size = 28,
		Role = style.fg,
		Position = UDim2.new(1, 0, 0, -2),
		AnchorPoint = Vector2.new(1, 0),
		ZIndex = 504,
		OnClick = function()
			close()
		end,
	})
	local _ = icon

	local duration = opts.Duration
	if duration == nil then
		duration = 5
	end
	local progress
	if duration > 0 then
		local bar = Frame({
			Name = "Timer",
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.fromScale(0, 1),
			AnchorPoint = Vector2.new(0, 1),
			ZIndex = 506,
			Parent = card,
		})
		progress = Frame({ Size = UDim2.fromScale(1, 1), Role = style.fg, Transparency = 0.5, ZIndex = 507, Parent = bar })
	end

	local closed = false
	function close()
		if closed then
			return
		end
		closed = true
		local tween = Util.Tween(card, Util.Motion.Medium, { Position = UDim2.fromOffset(380, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(tween and Util.Motion.Medium or 0, function()
			local index = table.find(notifications, slot)
			if index then
				table.remove(notifications, index)
			end
			slot:Destroy()
		end)
	end

	table.insert(notifications, slot)
	while #notifications > 6 do
		local oldest = table.remove(notifications, 1)
		if oldest then
			oldest:Destroy()
		end
	end

	task.defer(function()
		Util.Tween(card, Util.Motion.Medium, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
	end)
	if progress then
		local tween = TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) })
		tween:Play()
		task.delay(duration, close)
	end
	return { Close = close }
end

--// Dialogs \\--
-- opts: Title, Content, Icon, Buttons = { { Text, Style ("Filled"|"Tonal"|"Text"|"Danger"), Callback }, ... }
function Library:Dialog(opts)
	if not initialised or Library.Unloaded then
		return nil
	end
	opts = opts or {}
	Core.ClosePopups()
	local scrim = Frame({
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		Role = Color3.new(0, 0, 0),
		Transparency = 1,
		ZIndex = 601,
		Parent = dialogLayer,
	})
	dialogLayer.Visible = true
	Util.Tween(scrim, Util.Motion.Medium, { BackgroundTransparency = 0.5 }, Enum.EasingStyle.Quad)

	local sink = Instance.new("TextButton")
	sink.BackgroundTransparency = 1
	sink.Text = ""
	sink.AutoButtonColor = false
	sink.Size = UDim2.fromScale(1, 1)
	sink.ZIndex = 601
	sink.Parent = scrim

	local card = Frame({
		Name = "Dialog",
		Canvas = true,
		Size = UDim2.fromOffset(360, 0),
		AutoSize = "Y",
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "SurfaceContainerHigh",
		Radius = "XLarge",
		ZIndex = 602,
		Parent = scrim,
	})
	local cardScale = Instance.new("UIScale")
	cardScale.Scale = 0.9
	cardScale.Parent = card
	card.GroupTransparency = 1
	Util.Tween(cardScale, Util.Motion.Medium, { Scale = 1 }, Enum.EasingStyle.Quint)
	Util.Tween(card, Util.Motion.Medium, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)

	local body = Frame({ Size = UDim2.new(1, 0, 0, 0), AutoSize = "Y", ZIndex = 603, Parent = card })
	Padding(body, 24, 24, 24, 24)
	List(body, 16, nil, Enum.HorizontalAlignment.Left)
	if opts.Icon then
		local icon = Icons.Create(opts.Icon, { Size = 28, Color = "Secondary", Parent = body, ZIndex = 604 })
		icon.LayoutOrder = 0
	end
	local title = Text({
		Parent = body,
		Text = opts.Title or "Dialog",
		Style = "HeadlineSmall",
		Size = UDim2.new(1, 0, 0, 0),
		Wrap = true,
		AutoSize = "Y",
		ZIndex = 604,
		LayoutOrder = 1,
	})
	title.TextSize = 22
	if opts.Content then
		Text({
			Parent = body,
			Text = opts.Content,
			Style = "BodyMedium",
			Role = "OnSurfaceVariant",
			Size = UDim2.new(1, 0, 0, 0),
			Wrap = true,
			AutoSize = "Y",
			ZIndex = 604,
			LayoutOrder = 2,
		})
	end

	local function close()
		local tween = Util.Tween(card, Util.Motion.Short, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
		Util.Tween(cardScale, Util.Motion.Short, { Scale = 0.94 }, Enum.EasingStyle.Quad)
		Util.Tween(scrim, Util.Motion.Short, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
		task.delay(tween and Util.Motion.Short or 0, function()
			scrim:Destroy()
			if #dialogLayer:GetChildren() == 0 then
				dialogLayer.Visible = false
			end
		end)
	end

	local buttons = opts.Buttons or { { Text = "OK", Style = "Text" } }
	local row = Frame({ Size = UDim2.new(1, 0, 0, 40), ZIndex = 604, Parent = body })
	row.LayoutOrder = 3
	List(row, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
	for index, definition in buttons do
		local style = definition.Style or "Text"
		local background, content
		if style == "Filled" then
			background, content = "Primary", "OnPrimary"
		elseif style == "Danger" then
			background, content = "Error", "OnError"
		elseif style == "Tonal" then
			background, content = "SecondaryContainer", "OnSecondaryContainer"
		else
			background, content = nil, "Primary"
		end
		local button = Frame({
			Name = definition.Text or "Button",
			Size = UDim2.fromOffset(0, 40),
			AutoSize = "X",
			Role = background,
			Radius = "Full",
			ZIndex = 605,
			Parent = row,
		})
		button.LayoutOrder = index
		Padding(button, 0, 24, 0, 24)
		Text({
			Parent = button,
			Text = definition.Text or "OK",
			Style = "LabelLarge",
			Role = content,
			Size = UDim2.fromOffset(0, 40),
			AutoSize = "X",
			ZIndex = 606,
		})
		Components.Interactive(button, {
			Radius = "Full",
			StateRole = content,
			ZIndex = 605,
			OnClick = function()
				close()
				if definition.Callback then
					task.spawn(definition.Callback)
				end
			end,
		})
	end
	return { Close = close }
end

--// Theme API \\--
function Library:SetTheme(options, animate)
	Core.SetTheme(options, animate)
	Library.Changed:Fire("Theme", Core.Mode, Core.Preset)
end

function Library:GetTheme()
	return { Mode = Core.Mode, Preset = Core.Preset, Seed = Core.Seed, Overrides = Core.Overrides }
end

function Library:GetColor(role)
	return Core.Roles[role]
end

function Library:SetAnimations(enabled, speed)
	Util.AnimationsEnabled = enabled ~= false
	if speed then
		Util.Speed = math.clamp(speed, 0.25, 4)
	end
end

function Library:SetRipple(enabled)
	Util.RippleEnabled = enabled ~= false
end

function Library:SetCornerScale(scale)
	Core.SetCornerScale(scale)
end

function Library:SetRoundedFont(enabled)
	Assets.SetRounded(enabled)
end

function Library:SetScale(scale)
	if Library.UIScale then
		Library.UIScale.Scale = math.clamp(scale, 0.5, 2)
		Util.Scale = Library.UIScale.Scale
	end
end

function Library:SetToggleKey(key)
	Library.ToggleKey = key
end

function Library:Toggle(visible)
	if Library.Window then
		if visible == nil then
			Library.Window:Toggle()
		else
			Library.Window:SetVisible(visible)
		end
	end
end

--// Config management \\--
local Config = {
	Folder = "ZaridiumUI",
	IgnoredFlags = {},
}
Library.Config = Config

local function canFiles()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function configPath(name)
	return Config.Folder .. "/configs/" .. name .. ".json"
end

function Config:SetFolder(folder)
	Config.Folder = folder
end

function Config:Ignore(flags)
	for _, flag in flags do
		Config.IgnoredFlags[flag] = true
	end
end

function Config:Encode()
	local data = { version = 1, flags = {} }
	for flag, control in Core.Options do
		if not Config.IgnoredFlags[flag] then
			local value = control:Serialize()
			if value ~= nil then
				data.flags[flag] = value
			end
		end
	end
	return HttpService:JSONEncode(data)
end

function Config:Decode(json)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or typeof(data) ~= "table" or typeof(data.flags) ~= "table" then
		return false, "invalid config data"
	end
	for flag, value in data.flags do
		local control = Core.Options[flag]
		if control and not Config.IgnoredFlags[flag] then
			pcall(function()
				control:Deserialize(value, false)
			end)
		end
	end
	return true
end

function Config:Save(name)
	if not canFiles() then
		return false, "executor has no file API"
	end
	if typeof(name) ~= "string" or name:gsub("%s", "") == "" then
		return false, "config name is empty"
	end
	pcall(function()
		if typeof(makefolder) == "function" then
			if not isfolder(Config.Folder) then
				makefolder(Config.Folder)
			end
			if not isfolder(Config.Folder .. "/configs") then
				makefolder(Config.Folder .. "/configs")
			end
		end
	end)
	local ok, err = pcall(writefile, configPath(name), Config:Encode())
	if not ok then
		return false, tostring(err)
	end
	return true
end

function Config:Load(name)
	if not canFiles() then
		return false, "executor has no file API"
	end
	local path = configPath(name)
	if not isfile(path) then
		return false, "config does not exist"
	end
	local ok, content = pcall(readfile, path)
	if not ok then
		return false, tostring(content)
	end
	return Config:Decode(content)
end

function Config:Delete(name)
	if typeof(delfile) == "function" and isfile(configPath(name)) then
		pcall(delfile, configPath(name))
		return true
	end
	return false
end

function Config:List()
	local names = {}
	if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder(Config.Folder .. "/configs") then
		local ok, files = pcall(listfiles, Config.Folder .. "/configs")
		if ok then
			for _, file in files do
				local name = tostring(file):match("([^/\\]+)%.json$")
				if name and name ~= "autoload" then
					table.insert(names, name)
				end
			end
		end
	end
	table.sort(names)
	return names
end

function Config:SetAutoload(name)
	if not canFiles() then
		return false
	end
	pcall(writefile, Config.Folder .. "/configs/autoload.txt", name or "")
	return true
end

function Config:GetAutoload()
	local path = Config.Folder .. "/configs/autoload.txt"
	if canFiles() and isfile(path) then
		local ok, content = pcall(readfile, path)
		if ok and content ~= "" then
			return content
		end
	end
	return nil
end

function Config:LoadAutoload()
	local name = Config:GetAutoload()
	if name then
		return Config:Load(name)
	end
	return false, "no autoload set"
end

function Config:Share()
	return Config:Encode()
end

-- Builds a ready-made "Settings" tab section (appearance + configs) on the given tab.
function Library:BuildSettings(tab, opts)
	opts = opts or {}
	local appearance = tab:AddSection({ Title = "Appearance", Icon = "palette" })
	appearance:AddSegmented({
		Text = "Mode",
		Flag = "_theme_mode",
		Values = Color.Modes,
		Default = Core.Mode,
		Callback = function(value)
			Library:SetTheme({ Mode = value }, true)
		end,
	})
	appearance:AddDropdown({
		Text = "Accent color",
		Flag = "_theme_preset",
		Values = Color.PresetNames(),
		Default = Core.Preset ~= "Custom" and Core.Preset or "Violet",
		Callback = function(value)
			Library:SetTheme({ Preset = value }, true)
		end,
	})
	appearance:AddColorPicker({
		Text = "Custom accent",
		Flag = "_theme_seed",
		Default = Core.Seed,
		Callback = function(color)
			Library:SetTheme({ Seed = color }, true)
		end,
	})
	appearance:AddSlider({
		Text = "Corner roundness",
		Flag = "_ui_corner",
		Min = 0,
		Max = 150,
		Default = Core.CornerScale * 100,
		Suffix = "%",
		Callback = function(value)
			Core.SetCornerScale(value / 100)
		end,
	})
	appearance:AddSlider({
		Text = "Interface scale",
		Flag = "_ui_scale",
		Min = 60,
		Max = 150,
		Default = math.floor(Util.Scale * 100 + 0.5),
		Suffix = "%",
		Callback = function(value)
			Library:SetScale(value / 100)
		end,
	})
	appearance:AddToggle({
		Text = "Animations",
		Description = "Disable for the snappiest feel on low-end devices.",
		Flag = "_ui_animations",
		Default = Util.AnimationsEnabled,
		Callback = function(value)
			Library:SetAnimations(value)
		end,
	})
	appearance:AddSlider({
		Text = "Animation speed",
		Flag = "_ui_speed",
		Min = 0.5,
		Max = 2,
		Step = 0.1,
		Default = Util.Speed,
		Suffix = "x",
		Callback = function(value)
			Library:SetAnimations(Util.AnimationsEnabled, value)
		end,
	})
	appearance:AddToggle({
		Text = "Ripple effect",
		Flag = "_ui_ripple",
		Default = Util.RippleEnabled,
		Callback = function(value)
			Library:SetRipple(value)
		end,
	})
	appearance:AddToggle({
		Text = "Rounded font",
		Description = "Google Sans Flex with soft terminals.",
		Flag = "_ui_rounded",
		Default = Assets.Rounded,
		Callback = function(value)
			Library:SetRoundedFont(value)
		end,
	})
	appearance:AddKeybind({
		Text = "Toggle menu key",
		Flag = "_ui_key",
		Default = Library.ToggleKey,
		Mode = "Press",
		Callback = function() end,
	})
	Core.Options["_ui_key"].Changed:Connect(function()
		local key = Core.Options["_ui_key"]:GetKey()
		if key and key.EnumType == Enum.KeyCode then
			Library.ToggleKey = key
		end
	end)

	Config:Ignore({ "_theme_mode", "_theme_preset", "_theme_seed" })
	if opts.Configs == false then
		return appearance
	end

	local configs = tab:AddSection({ Title = "Configuration", Icon = "save" })
	local nameInput = configs:AddInput({ Text = "Config name", Flag = "_cfg_name", Default = "default", Finished = true })
	local list = configs:AddDropdown({
		Text = "Saved configs",
		Flag = "_cfg_list",
		Values = Config:List(),
		AllowNull = true,
		Placeholder = "No configs yet",
	})
	local function refreshList()
		list:SetValues(Config:List(), true)
	end
	local function target()
		return list.Value or nameInput.Value
	end
	configs:AddButton({
		Text = "Save",
		Icon = "save",
		Style = "Filled",
		Callback = function()
			local name = nameInput.Value ~= "" and nameInput.Value or target()
			local ok, err = Config:Save(name)
			Library:Notify({
				Title = ok and "Config saved" or "Save failed",
				Content = ok and ("Saved '" .. name .. "'.") or tostring(err),
				Type = ok and "Success" or "Error",
			})
			refreshList()
		end,
	})
	configs:AddButton({
		Text = "Load",
		Icon = "download",
		Style = "Tonal",
		Callback = function()
			local name = target()
			local ok, err = Config:Load(name or "")
			Library:Notify({
				Title = ok and "Config loaded" or "Load failed",
				Content = ok and ("Loaded '" .. tostring(name) .. "'.") or tostring(err),
				Type = ok and "Success" or "Error",
			})
		end,
	})
	configs:AddButton({
		Text = "Delete",
		Icon = "delete",
		Style = "Outlined",
		Callback = function()
			local name = target()
			if not name or name == "" then
				return
			end
			Library:Dialog({
				Title = "Delete '" .. name .. "'?",
				Content = "This cannot be undone.",
				Icon = "delete",
				Buttons = {
					{ Text = "Cancel", Style = "Text" },
					{
						Text = "Delete",
						Style = "Danger",
						Callback = function()
							Config:Delete(name)
							refreshList()
						end,
					},
				},
			})
		end,
	})
	configs:AddToggle({
		Text = "Autoload selected config",
		Flag = "_cfg_autoload",
		Default = Config:GetAutoload() ~= nil,
		Callback = function(value)
			Config:SetAutoload(value and target() or nil)
		end,
	})
	configs:AddButton({
		Text = "Copy config to clipboard",
		Icon = "content_copy",
		Style = "Text",
		Callback = function()
			local copy = executorFn("setclipboard")
			if copy then
				copy(Config:Share())
				Library:Notify({ Title = "Copied", Content = "Config JSON copied to the clipboard.", Type = "Success", Duration = 3 })
			else
				Library:Notify({ Title = "Unavailable", Content = "Your executor has no setclipboard.", Type = "Warning" })
			end
		end,
	})
	Config:Ignore({ "_cfg_name", "_cfg_list", "_cfg_autoload" })
	return configs
end

--// Teardown \\--
function Library:Unload()
	if Library.Unloaded then
		return
	end
	Library.Unloaded = true
	Library.Unloading:Fire()
	Core.ClosePopups()
	maid:Clean()
	for _, control in table.clone(Core.Options) do
		pcall(function()
			control:Destroy()
		end)
	end
	table.clear(Core.Options)
	table.clear(Core.Flags)
	if Library.Window then
		pcall(function()
			Library.Window:Destroy()
		end)
		Library.Window = nil
		Core.Window = nil
	end
	if Core.ScreenGui then
		Core.ScreenGui:Destroy()
		Core.ScreenGui = nil
	end
	Library.Root = nil
	Core.Overlay = nil
	initialised = false
	local env = typeof(getgenv) == "function" and getgenv() or nil
	if env and env.ZaridiumUI == Library then
		env.ZaridiumUI = nil
	end
end

function Library:GetAssetStatus()
	return Assets.Status
end

function Library:IsLoaded()
	return initialised and not Library.Unloaded
end

return Library
