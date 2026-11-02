--!nonstrict
-- Window: top bar, navigation (rail on desktop / bottom bar on narrow screens), pages, sections, profile card, search.

local Util = require("Util")
local Core = require("Core")
local Assets = require("Assets")
local Icons = require("Icons")
local Components = require("Components")
local Controls = require("Controls")

local UserInputService = game:GetService("UserInputService")

local Frame, Text, List, Padding = Components.Frame, Components.Text, Components.List, Components.Padding

local Window = {}
Window.__index = Window

local RAIL_WIDTH = 88
local TOPBAR_HEIGHT = 64
local COMPACT_BREAKPOINT = 560

--// Section \\--
local Section = {}
Section.__index = Section

Controls.Attach(Section, function(self)
	return self.Body
end)

function Section:_track(control, opts)
	local text = string.lower(table.concat({ opts.Text or "", opts.Description or "", opts.Flag or "" }, " "))
	table.insert(self._items, { control = control, text = text })
end

function Section:_filter(query)
	local anyVisible = false
	for _, item in self._items do
		local show = query == "" or item.text:find(query, 1, true) ~= nil
		item.control._filtered = not show
		item.control:_applyVisible()
		anyVisible = anyVisible or (show and not item.control._hidden)
	end
	if query == "" then
		self.Card.Visible = not self._hidden
		return true
	end
	self.Card.Visible = anyVisible and not self._hidden
	return anyVisible
end

function Section:SetTitle(title)
	self.Title.Text = title
end

function Section:SetVisible(visible)
	self._hidden = not visible
	self.Card.Visible = visible
end

function Section:Destroy()
	for _, item in self._items do
		item.control:Destroy()
	end
	self.Card:Destroy()
end

--// Tab (page) \\--
local Tab = {}
Tab.__index = Tab

function Tab:AddSection(opts)
	if typeof(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}
	local section = setmetatable({ _items = {}, _hidden = false, Tab = self }, Section)

	local card = Frame({
		Name = opts.Title or "Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutoSize = "Y",
		Role = opts.Elevated and "SurfaceContainerHigh" or "SurfaceContainer",
		Radius = "Large",
		Clip = true,
		Parent = self.Page,
	})
	card.LayoutOrder = opts.LayoutOrder or (#self.Sections + 1)
	section.Card = card
	List(card, 0)

	if opts.Title and opts.Title ~= "" then
		local header = Frame({ Name = "Header", Size = UDim2.new(1, 0, 0, 48), Parent = card })
		header.LayoutOrder = -1
		Padding(header, 0, 16, 0, 16)
		local left = 0
		if opts.Icon then
			Icons.Create(opts.Icon, {
				Size = 20,
				Color = "Primary",
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Parent = header,
			})
			left = 30
		end
		section.Title = Text({
			Parent = header,
			Text = opts.Title,
			Style = "TitleSmall",
			Role = "Primary",
			Size = UDim2.new(1, -left, 1, 0),
			Position = UDim2.fromOffset(left, 0),
			Truncate = true,
		})
	else
		section.Title = { Text = "" }
	end

	local body = Frame({ Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutoSize = "Y", Parent = card })
	body.LayoutOrder = 0
	List(body, 0)
	Padding(body, 0, 0, 8, 0)
	section.Body = body

	table.insert(self.Sections, section)
	if Core.Window then
		Core.Window:_applySearch()
	end
	return section
end

-- Adds controls straight onto the tab inside an automatic section (convenience).
function Tab:Section(title)
	return self:AddSection(title)
end

function Tab:SetBadge(value)
	self._badge = value
	self.Window:_refreshBadge(self)
end

function Tab:Select()
	self.Window:SelectTab(self)
end

function Tab:Destroy()
	self.Window:_removeTab(self)
end

--// Window \\--
function Window.new(library, opts)
	local self = setmetatable({}, Window)
	self.Library = library
	self.Options = opts
	self.Tabs = {}
	self.Selected = nil
	self._maid = Util.Maid.new()
	self._query = ""
	self.Opened = Util.Signal.new()
	self.Closed = Util.Signal.new()
	self.TabChanged = Util.Signal.new()
	self.Visible = false

	local root = library.Root
	local size = opts.Size or Vector2.new(780, 560)
	self.BaseSize = size

	local main = Frame({
		Name = "Window",
		Canvas = true,
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "Surface",
		Radius = "XLarge",
		ZIndex = 10,
		Parent = root,
	})
	local outline = Instance.new("UIStroke")
	outline.Thickness = 1
	Core.Bind(outline, "Color", "OutlineVariant")
	outline.Parent = main
	self.Main = main

	-- Soft shadow made of stacked translucent frames (CanvasGroup clips children, so it lives on the root).
	local shadow = Frame({
		Name = "Shadow",
		Size = UDim2.new(0, size.X + 24, 0, size.Y + 24),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = Color3.new(0, 0, 0),
		Transparency = 0.8,
		Radius = 36,
		ZIndex = 9,
		Parent = root,
	})
	self.Shadow = shadow

	--// Top bar \\--
	local top = Frame({ Name = "TopBar", Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT), Role = "Surface", ZIndex = 12, Parent = main })
	self.TopBar = top
	local topContent = Frame({ Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = top })
	Padding(topContent, 0, 8, 0, 20)

	local left = Frame({ Name = "Left", Size = UDim2.new(0, 0, 1, 0), AutoSize = "X", ZIndex = 13, Parent = topContent })
	List(left, 12, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
	if opts.Icon then
		local logo = Icons.Create(opts.Icon, { Size = 28, Color = "Primary", Parent = left, ZIndex = 14 })
		logo.LayoutOrder = 0
	end
	local titleBlock = Frame({ Name = "Titles", Size = UDim2.new(0, 0, 1, 0), AutoSize = "X", ZIndex = 13, Parent = left })
	titleBlock.LayoutOrder = 1
	List(titleBlock, 0, nil, nil, Enum.VerticalAlignment.Center)
	self.TitleLabel = Text({
		Parent = titleBlock,
		Text = opts.Title or "Window",
		Style = "TitleLarge",
		Size = UDim2.fromOffset(0, 26),
		AutoSize = "X",
		ZIndex = 14,
	})
	self.SubtitleLabel = Text({
		Parent = titleBlock,
		Text = opts.Subtitle or "",
		Style = "BodySmall",
		Role = "OnSurfaceVariant",
		Size = UDim2.fromOffset(0, 16),
		AutoSize = "X",
		ZIndex = 14,
		LayoutOrder = 1,
	})
	self.SubtitleLabel.Visible = (opts.Subtitle or "") ~= ""

	local actions = Frame({
		Name = "Actions",
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		AutoSize = "X",
		ZIndex = 13,
		Parent = topContent,
	})
	List(actions, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
	self.Actions = actions

	-- Search field (collapsed into an icon button on narrow windows)
	local searchHolder = Frame({
		Name = "Search",
		Size = UDim2.fromOffset(200, 40),
		Role = "SurfaceContainerHigh",
		Radius = "Full",
		ZIndex = 13,
		Parent = actions,
	})
	searchHolder.LayoutOrder = 0
	Icons.Create("search", { Size = 20, Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = searchHolder, ZIndex = 14 })
	local searchBox = Instance.new("TextBox")
	searchBox.Name = "Box"
	searchBox.BackgroundTransparency = 1
	searchBox.BorderSizePixel = 0
	searchBox.ClearTextOnFocus = false
	searchBox.PlaceholderText = "Search settings"
	searchBox.Text = ""
	searchBox.TextSize = 14
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.Size = UDim2.new(1, -54, 1, 0)
	searchBox.Position = UDim2.fromOffset(42, 0)
	searchBox.ZIndex = 14
	Assets.Apply(searchBox, "Regular")
	Core.Bind(searchBox, "TextColor3", "OnSurface")
	Core.Bind(searchBox, "PlaceholderColor3", "OnSurfaceVariant")
	searchBox.Parent = searchHolder
	self.SearchHolder = searchHolder
	self.SearchBox = searchBox
	if opts.Search == false then
		searchHolder.Visible = false
	end
	self._maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self._query = string.lower(searchBox.Text)
		self:_applySearch()
	end))

	if opts.ThemeButton ~= false then
		local themeButton = Components.IconButton({
			Parent = actions,
			Icon = "dark_mode",
			Tooltip = "Toggle light / dark",
			Role = "OnSurfaceVariant",
			ZIndex = 14,
			LayoutOrder = 1,
			OnClick = function()
				local mode = Core.Mode == "Light" and "Dark" or "Light"
				Core.SetTheme({ Mode = mode }, true)
				self.Library.Changed:Fire("Theme", mode)
			end,
		})
		self.ThemeButton = themeButton
	end

	local minimize = Components.IconButton({
		Parent = actions,
		Icon = "minimize",
		Tooltip = "Hide (" .. Controls.KeyName(library.ToggleKey) .. ")",
		Role = "OnSurfaceVariant",
		ZIndex = 14,
		LayoutOrder = 2,
		OnClick = function()
			self:SetVisible(false)
		end,
	})
	self.MinimizeButton = minimize
	local closeButton = Components.IconButton({
		Parent = actions,
		Icon = "close",
		Tooltip = "Close",
		Role = "OnSurfaceVariant",
		ZIndex = 14,
		LayoutOrder = 3,
		OnClick = function()
			if opts.ConfirmClose then
				self.Library:Dialog({
					Title = "Close " .. (opts.Title or "window") .. "?",
					Content = "The interface will be destroyed. Your settings stay saved.",
					Icon = "power_settings_new",
					Buttons = {
						{ Text = "Cancel", Style = "Text" },
						{
							Text = "Close",
							Style = "Filled",
							Callback = function()
								self.Library:Unload()
							end,
						},
					},
				})
			else
				self.Library:Unload()
			end
		end,
	})
	self.CloseButton = closeButton

	self:_makeDraggable(top)

	local divider = Frame({
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, TOPBAR_HEIGHT),
		Role = "OutlineVariant",
		ZIndex = 12,
		Parent = main,
	})
	self.Divider = divider

	--// Body \\--
	local body = Frame({
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -(TOPBAR_HEIGHT + 1)),
		Position = UDim2.fromOffset(0, TOPBAR_HEIGHT + 1),
		ZIndex = 11,
		Parent = main,
	})
	self.Body = body

	-- Navigation rail
	local rail = Frame({
		Name = "Rail",
		Size = UDim2.new(0, RAIL_WIDTH, 1, 0),
		Role = "Surface",
		ZIndex = 12,
		Parent = body,
	})
	self.Rail = rail
	local railScroll = Instance.new("ScrollingFrame")
	railScroll.Name = "Items"
	railScroll.BackgroundTransparency = 1
	railScroll.BorderSizePixel = 0
	railScroll.Size = UDim2.new(1, 0, 1, 0)
	railScroll.ScrollBarThickness = 0
	railScroll.CanvasSize = UDim2.new()
	railScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	railScroll.ZIndex = 13
	railScroll.Parent = rail
	self.RailScroll = railScroll
	Padding(railScroll, 12, 0, 12, 0)
	self.RailLayout = List(railScroll, 12, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)

	-- Profile card (bottom of the rail)
	if opts.Profile ~= false then
		self:_buildProfile(rail, opts.Profile)
	end

	-- Pages
	local pages = Frame({
		Name = "Pages",
		Size = UDim2.new(1, -RAIL_WIDTH, 1, 0),
		Position = UDim2.fromOffset(RAIL_WIDTH, 0),
		Role = "Surface",
		ZIndex = 11,
		Clip = true,
		Parent = body,
	})
	self.Pages = pages

	-- Resize grip
	if opts.Resizable ~= false then
		self:_makeResizable(main)
	end

	self._maid:Give(main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_layoutResponsive()
	end))
	self:_layoutResponsive()
	main.Visible = false
	shadow.Visible = false
	return self
end

--// Profile card \\--
function Window:_buildProfile(rail, profileOpts)
	profileOpts = profileOpts or {}
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local card = Frame({
		Name = "Profile",
		Size = UDim2.new(1, -16, 0, 56),
		Position = UDim2.new(0.5, 0, 1, -8),
		AnchorPoint = Vector2.new(0.5, 1),
		Role = "SurfaceContainerHigh",
		Radius = "Large",
		ZIndex = 14,
		Parent = rail,
	})
	self.ProfileCard = card

	local avatar = Frame({
		Name = "AvatarFrame",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "PrimaryContainer",
		Radius = "Full",
		Canvas = true,
		ZIndex = 15,
		Parent = card,
	})
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.BackgroundTransparency = 1
	avatarImage.Size = UDim2.fromScale(1, 1)
	avatarImage.ZIndex = 16
	avatarImage.Parent = avatar
	local initial = Text({
		Parent = avatar,
		Text = "?",
		Style = "TitleMedium",
		Role = "OnPrimaryContainer",
		Size = UDim2.fromScale(1, 1),
		XAlign = Enum.TextXAlignment.Center,
		ZIndex = 15,
	})
	-- online status dot
	local dot = Frame({
		Name = "Status",
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0.5, 14, 0.5, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "Success",
		Radius = "Full",
		StrokeRole = "SurfaceContainerHigh",
		StrokeThickness = 2,
		ZIndex = 17,
		Parent = card,
	})
	local _ = dot

	local displayName = profileOpts.DisplayName or (player and player.DisplayName) or "Guest"
	local userName = profileOpts.Username or (player and player.Name) or "guest"
	initial.Text = string.upper(string.sub(displayName, 1, 1))

	local userId = profileOpts.UserId or (player and player.UserId)
	if profileOpts.Image then
		Icons.Apply(avatarImage, profileOpts.Image)
		initial.Visible = false
	elseif userId and userId > 0 then
		task.spawn(function()
			local ok, content, ready = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)
			if ok and ready and content then
				avatarImage.Image = content
				initial.Visible = false
			end
		end)
	end

	-- Expanded card on wide layouts: name + username next to the avatar.
	local info = Frame({
		Name = "Info",
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.fromOffset(56, 0),
		ZIndex = 15,
		Parent = card,
	})
	List(info, 0, nil, nil, Enum.VerticalAlignment.Center)
	Text({ Parent = info, Text = displayName, Style = "LabelLarge", Size = UDim2.new(1, 0, 0, 18), Truncate = true, ZIndex = 16 })
	Text({
		Parent = info,
		Text = "@" .. userName,
		Style = "LabelSmall",
		Role = "OnSurfaceVariant",
		Size = UDim2.new(1, 0, 0, 14),
		Truncate = true,
		ZIndex = 16,
		LayoutOrder = 1,
	})
	info.Visible = false
	self.ProfileInfo = info
	self.ProfileAvatar = avatar
	self.ProfileTitle = displayName

	Components.Interactive(card, {
		Radius = "Large",
		StateRole = "OnSurface",
		Tooltip = displayName .. "  (@" .. userName .. ")",
		ZIndex = 14,
		OnClick = function()
			if profileOpts.OnClick then
				profileOpts.OnClick()
			end
		end,
	})
end

--// Layout (rail vs bottom bar) \\--
function Window:_layoutResponsive()
	local scale = math.max(Util.Scale, 0.01)
	local width = self.Main.AbsoluteSize.X / scale
	local compact = width < COMPACT_BREAKPOINT
	if self._compact == compact and self._railBuilt then
		return
	end
	self._compact = compact
	self._railBuilt = true

	if compact then
		self.Rail.Size = UDim2.new(1, 0, 0, 72)
		self.Rail.Position = UDim2.new(0, 0, 1, -72)
		self.Pages.Size = UDim2.new(1, 0, 1, -72)
		self.Pages.Position = UDim2.new()
		self.RailLayout.FillDirection = Enum.FillDirection.Horizontal
		self.RailLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		self.RailLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		self.RailScroll.Size = UDim2.fromScale(1, 1)
		self.RailScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
		self.RailScroll.CanvasSize = UDim2.new()
		if self.ProfileCard then
			self.ProfileCard.Visible = false
		end
		self.SearchHolder.Size = UDim2.fromOffset(40, 40)
		self.SearchBox.Visible = false
	else
		self.Rail.Size = UDim2.new(0, RAIL_WIDTH, 1, 0)
		self.Rail.Position = UDim2.new()
		self.Pages.Size = UDim2.new(1, -RAIL_WIDTH, 1, 0)
		self.Pages.Position = UDim2.fromOffset(RAIL_WIDTH, 0)
		self.RailLayout.FillDirection = Enum.FillDirection.Vertical
		self.RailLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		self.RailLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		self.RailScroll.Size = UDim2.new(1, 0, 1, self.ProfileCard and -72 or 0)
		self.RailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		if self.ProfileCard then
			self.ProfileCard.Visible = true
		end
		self.SearchHolder.Size = UDim2.fromOffset(200, 40)
		self.SearchBox.Visible = true
	end
	for _, tab in self.Tabs do
		self:_styleNavItem(tab)
	end
end

--// Dragging / resizing \\--
function Window:_makeDraggable(handle)
	local dragging = false
	local startPointer, startPos
	local hit = Instance.new("TextButton")
	hit.Selectable = false
	hit.Name = "DragArea"
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = 12
	hit.Parent = handle
	local main, shadow = self.Main, self.Shadow

	self._maid:Give(hit.InputBegan:Connect(function(input)
		if not Util.IsPointer(input) then
			return
		end
		dragging = true
		startPointer = Util.PointerPosition(input)
		startPos = main.AbsolutePosition + main.AbsoluteSize * 0.5
		Core.ClosePopups()
	end))
	self._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local scale = math.max(Util.Scale, 0.01)
			local delta = Util.PointerPosition(input) - startPointer
			local target = startPos + delta
			local rootSize = Core.Overlay.AbsoluteSize
			target = Vector2.new(math.clamp(target.X, 40, rootSize.X - 40), math.clamp(target.Y, 40, rootSize.Y - 40))
			local pos = UDim2.fromOffset((target.X - Core.Overlay.AbsolutePosition.X) / scale, (target.Y - Core.Overlay.AbsolutePosition.Y) / scale)
			main.Position = pos
			shadow.Position = pos
		end
	end))
	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if dragging and Util.IsPointer(input) then
			dragging = false
		end
	end))
end

function Window:_makeResizable(main)
	local grip = Instance.new("TextButton")
	grip.Selectable = false
	grip.Name = "ResizeGrip"
	grip.BackgroundTransparency = 1
	grip.Text = ""
	grip.AutoButtonColor = false
	grip.Size = UDim2.fromOffset(28, 28)
	grip.Position = UDim2.fromScale(1, 1)
	grip.AnchorPoint = Vector2.new(1, 1)
	grip.ZIndex = 40
	grip.Parent = main
	local icon = Icons.Create("drag_handle", { Size = 14, Parent = grip, Position = UDim2.new(1, -6, 1, -6), AnchorPoint = Vector2.new(1, 1), ZIndex = 41 })
	icon.Rotation = -45
	icon.ImageTransparency = 0.5

	local resizing = false
	local startPointer, startSize
	local minimum = self.Options.MinSize or Vector2.new(420, 360)
	self._maid:Give(grip.InputBegan:Connect(function(input)
		if Util.IsPointer(input) then
			resizing = true
			startPointer = Util.PointerPosition(input)
			startSize = main.AbsoluteSize / math.max(Util.Scale, 0.01)
			Core.ClosePopups()
		end
	end))
	self._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local scale = math.max(Util.Scale, 0.01)
			local delta = (Util.PointerPosition(input) - startPointer) / scale
			local overlay = Core.Overlay.AbsoluteSize / scale
			local width = math.clamp(startSize.X + delta.X * 2, minimum.X, overlay.X - 16)
			local height = math.clamp(startSize.Y + delta.Y * 2, minimum.Y, overlay.Y - 16)
			main.Size = UDim2.fromOffset(width, height)
			self.Shadow.Size = UDim2.fromOffset(width + 24, height + 24)
		end
	end))
	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if resizing and Util.IsPointer(input) then
			resizing = false
		end
	end))
end

--// Navigation items \\--
function Window:_styleNavItem(tab)
	local nav = tab._nav
	if not nav then
		return
	end
	if self._compact then
		nav.holder.Size = UDim2.fromOffset(72, 64)
	else
		nav.holder.Size = UDim2.fromOffset(RAIL_WIDTH - 8, 64)
	end
end

function Window:_refreshBadge(tab)
	local nav = tab._nav
	if not nav then
		return
	end
	local badge = tab._badge
	if badge == nil or badge == false or badge == 0 or badge == "" then
		nav.badge.Visible = false
		return
	end
	nav.badge.Visible = true
	nav.badgeLabel.Text = typeof(badge) == "number" and tostring(math.min(badge, 99)) or tostring(badge)
end

function Window:_renderTabState(tab, animate)
	local nav = tab._nav
	local selected = self.Selected == tab
	local duration = animate and Util.Motion.Medium or 0
	Util.Tween(nav.pill, duration, {
		Size = selected and UDim2.fromOffset(56, 32) or UDim2.fromOffset(20, 32),
		BackgroundTransparency = selected and 0 or 1,
	}, Enum.EasingStyle.Quint)
	Core.Set(nav.label, "TextColor3", selected and "OnSurface" or "OnSurfaceVariant", duration)
	Core.Set(nav.icon, "ImageColor3", selected and "OnSecondaryContainer" or "OnSurfaceVariant", duration)
	Icons.Apply(nav.icon, tab.IconName, selected)
	nav.label.FontFace = Assets.Font(selected and "SemiBold" or "Medium")
end

function Window:AddTab(opts)
	if typeof(opts) == "string" then
		opts = { Name = opts }
	end
	opts = opts or {}
	local tab = setmetatable({
		Window = self,
		Name = opts.Name or ("Tab " .. (#self.Tabs + 1)),
		IconName = opts.Icon or "widgets",
		Sections = {},
		_badge = opts.Badge,
	}, Tab)

	local holder = Frame({
		Name = tab.Name,
		Size = UDim2.fromOffset(RAIL_WIDTH - 8, 64),
		ZIndex = 14,
		Parent = self.RailScroll,
	})
	holder.LayoutOrder = #self.Tabs + 1
	local pill = Frame({
		Name = "Pill",
		Size = UDim2.fromOffset(20, 32),
		Position = UDim2.new(0.5, 0, 0, 4),
		AnchorPoint = Vector2.new(0.5, 0),
		Role = "SecondaryContainer",
		Transparency = 1,
		Radius = "Full",
		ZIndex = 15,
		Parent = holder,
	})
	local icon = Icons.Create(tab.IconName, {
		Size = 24,
		Color = "OnSurfaceVariant",
		Position = UDim2.new(0.5, 0, 0, 8),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = holder,
		ZIndex = 17,
	})
	local label = Text({
		Parent = holder,
		Text = tab.Name,
		Style = "LabelMedium",
		Role = "OnSurfaceVariant",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 40),
		XAlign = Enum.TextXAlignment.Center,
		Truncate = true,
		ZIndex = 16,
	})
	local badge = Frame({
		Name = "Badge",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0.5, 10, 0, 4),
		AnchorPoint = Vector2.new(0, 0),
		Role = "Error",
		Radius = "Full",
		ZIndex = 19,
		Parent = holder,
	})
	badge.Visible = false
	local badgeLabel = Text({
		Parent = badge,
		Style = "LabelSmall",
		Role = "OnError",
		Size = UDim2.fromScale(1, 1),
		XAlign = Enum.TextXAlignment.Center,
		ZIndex = 20,
	})
	badgeLabel.TextSize = 10
	tab._nav = { holder = holder, pill = pill, icon = icon, label = label, badge = badge, badgeLabel = badgeLabel }

	Components.Interactive(holder, {
		Radius = "Large",
		StateRole = "OnSurface",
		Tooltip = opts.Tooltip,
		ZIndex = 14,
		OnClick = function()
			self:SelectTab(tab)
		end,
	})

	-- Page
	local page = Instance.new("ScrollingFrame")
	page.Name = tab.Name
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.Size = UDim2.fromScale(1, 1)
	page.CanvasSize = UDim2.new()
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollBarThickness = 4
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ZIndex = 12
	page.Visible = false
	Core.Bind(page, "ScrollBarImageColor3", "Outline")
	page.Parent = self.Pages
	Padding(page, 16, 16, 16, 16)
	List(page, 12)
	tab.Page = page

	table.insert(self.Tabs, tab)
	self:_styleNavItem(tab)
	self:_refreshBadge(tab)
	self:_renderTabState(tab, false)

	if #self.Tabs == 1 or opts.Default then
		self:SelectTab(tab, true)
	end
	return tab
end

function Window:SelectTab(tab, instant)
	if typeof(tab) == "string" then
		for _, candidate in self.Tabs do
			if candidate.Name == tab then
				tab = candidate
				break
			end
		end
	end
	if typeof(tab) ~= "table" or self.Selected == tab then
		return
	end
	Core.ClosePopups()
	local previous = self.Selected
	self.Selected = tab
	for _, candidate in self.Tabs do
		self:_renderTabState(candidate, not instant)
	end

	if previous and not instant and Util.AnimationsEnabled then
		local page = tab.Page
		page.Visible = true
		page.Position = UDim2.fromOffset(0, 14)
		previous.Page.Visible = false
		-- fade content in by sliding up; ScrollingFrame has no group transparency
		Util.Tween(page, Util.Motion.Medium, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
	else
		if previous then
			previous.Page.Visible = false
		end
		tab.Page.Visible = true
		tab.Page.Position = UDim2.new()
	end
	self:_applySearch()
	self.TabChanged:Fire(tab.Name)
end

function Window:_removeTab(tab)
	local index = table.find(self.Tabs, tab)
	if not index then
		return
	end
	table.remove(self.Tabs, index)
	for _, section in tab.Sections do
		section:Destroy()
	end
	tab._nav.holder:Destroy()
	tab.Page:Destroy()
	if self.Selected == tab then
		self.Selected = nil
		if self.Tabs[1] then
			self:SelectTab(self.Tabs[1], true)
		end
	end
end

function Window:GetTab(name)
	for _, tab in self.Tabs do
		if tab.Name == name then
			return tab
		end
	end
	return nil
end

--// Search \\--
function Window:_applySearch()
	local tab = self.Selected
	if not tab then
		return
	end
	local anyVisible = false
	for _, section in tab.Sections do
		anyVisible = section:_filter(self._query) or anyVisible
	end
	if self._emptyState then
		self._emptyState.Visible = self._query ~= "" and not anyVisible
	elseif self._query ~= "" and not anyVisible then
		local empty = Frame({ Name = "Empty", Size = UDim2.new(1, 0, 0, 160), ZIndex = 12, Parent = self.Pages })
		Icons.Create("search", { Size = 40, Position = UDim2.new(0.5, 0, 0.5, -20), AnchorPoint = Vector2.new(0.5, 0.5), Parent = empty, ZIndex = 13 })
		Text({
			Parent = empty,
			Text = "No settings match your search",
			Style = "BodyMedium",
			Role = "OnSurfaceVariant",
			Position = UDim2.new(0, 0, 0.5, 18),
			Size = UDim2.new(1, 0, 0, 20),
			XAlign = Enum.TextXAlignment.Center,
			ZIndex = 13,
		})
		self._emptyState = empty
	end
end

function Window:ClearSearch()
	self.SearchBox.Text = ""
end

--// Visibility \\--
function Window:SetVisible(visible)
	visible = visible and true or false
	if visible == self.Visible then
		return
	end
	self.Visible = visible
	local main, shadow = self.Main, self.Shadow
	Core.ClosePopups()
	if visible then
		main.Visible = true
		shadow.Visible = true
		if Util.AnimationsEnabled then
			self._scale = self._scale or Instance.new("UIScale")
			local uiScale = self._scale
			uiScale.Parent = main
			uiScale.Scale = 0.92
			main.GroupTransparency = 1
			Util.Tween(uiScale, Util.Motion.Medium, { Scale = 1 }, Enum.EasingStyle.Quint)
			Util.Tween(main, Util.Motion.Medium, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
			shadow.BackgroundTransparency = 1
			Util.Tween(shadow, Util.Motion.Medium, { BackgroundTransparency = 0.8 }, Enum.EasingStyle.Quad)
		else
			main.GroupTransparency = 0
		end
		self.Opened:Fire()
	else
		if Util.AnimationsEnabled then
			self._scale = self._scale or Instance.new("UIScale")
			local uiScale = self._scale
			uiScale.Parent = main
			Util.Tween(uiScale, Util.Motion.Short, { Scale = 0.94 }, Enum.EasingStyle.Quad)
			Util.Tween(main, Util.Motion.Short, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
			Util.Tween(shadow, Util.Motion.Short, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
			task.delay(Util.Motion.Short, function()
				if not self.Visible then
					main.Visible = false
					shadow.Visible = false
				end
			end)
		else
			main.Visible = false
			shadow.Visible = false
		end
		self.Closed:Fire()
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:SetTitle(title, subtitle)
	self.TitleLabel.Text = title
	if subtitle ~= nil then
		self.SubtitleLabel.Text = subtitle
		self.SubtitleLabel.Visible = subtitle ~= ""
	end
end

function Window:Destroy()
	self._maid:Clean()
	self.Main:Destroy()
	self.Shadow:Destroy()
end

return Window
