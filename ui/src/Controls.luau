--!nonstrict
-- Controls: every Add* method that can be called on a Section (or any container that has been "attached").
-- All controls share one contract, see docs/API.md ("Control contract").

local Util = require("Util")
local Core = require("Core")
local Assets = require("Assets")
local Icons = require("Icons")
local Components = require("Components")

local UserInputService = game:GetService("UserInputService")

local Controls = {}

local Frame, Text, List, Padding = Components.Frame, Components.Text, Components.List, Components.Padding

--// Shared control scaffolding \\--
local function newControl(kind, opts, container)
	local self = {
		Type = kind,
		Flag = opts.Flag,
		Value = nil,
		Changed = Util.Signal.new(),
		Disabled = opts.Disabled == true,
		_hidden = opts.Visible == false,
		_filtered = false,
		_maid = Util.Maid.new(),
		_callback = opts.Callback,
		_setters = {},
	}

	function self:OnChanged(fn)
		return self.Changed:Connect(fn)
	end

	function self:_applyVisible()
		if self.Row then
			self.Row.Visible = not self._hidden and not self._filtered
		end
	end

	function self:SetVisible(visible)
		self._hidden = not visible
		self:_applyVisible()
	end

	function self:SetDisabled(disabled)
		self.Disabled = disabled and true or false
		if self._applyDisabled then
			self._applyDisabled(self.Disabled)
		end
	end

	function self:Get()
		return self.Value
	end

	function self:Serialize()
		return self.Value
	end

	function self:Deserialize(value, silent)
		self:Set(value, silent)
	end

	function self:_emit(silent)
		if silent then
			return
		end
		self.Changed:Fire(self.Value)
		if self._callback then
			task.spawn(self._callback, self.Value)
		end
	end

	Core.Controls[self] = true

	function self:Destroy()
		Core.Controls[self] = nil
		self._maid:Clean()
		self.Changed:Destroy()
		if self.Flag and Core.Options[self.Flag] == self then
			Core.Options[self.Flag] = nil
			Core.Flags[self.Flag] = nil
		end
		if self.Row then
			self.Row:Destroy()
		end
	end

	return self
end

local function register(self)
	if self.Flag then
		if Core.Options[self.Flag] and Core.Options[self.Flag] ~= self then
			warn("[ZaridiumUI] duplicate flag '" .. self.Flag .. "', the previous control was replaced")
		end
		Core.Options[self.Flag] = self
		Core.Flags[self.Flag] = self.Value
		self.Changed:Connect(function(value)
			Core.Flags[self.Flag] = value
		end)
	end
end

-- Creates the row frame with optional leading icon, title and description. Returns row, rightHolder, textBlock.
local function makeRow(container, opts, minHeight)
	local hasDescription = opts.Description ~= nil and opts.Description ~= ""
	local row = Frame({
		Name = opts.Flag or opts.Text or "Row",
		Size = UDim2.new(1, 0, 0, hasDescription and math.max(minHeight, 64) or minHeight),
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	local content = Frame({ Name = "Content", Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = row })
	Padding(content, 0, 16, 0, 16)

	local leftOffset = 0
	if opts.Icon then
		Icons.Create(opts.Icon, {
			Size = 24,
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Color = "OnSurfaceVariant",
			Parent = content,
		})
		leftOffset = 40
	end

	local right = Frame({
		Name = "Right",
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		AutoSize = "X",
		Parent = content,
	})

	local block = Frame({
		Name = "Text",
		Position = UDim2.fromOffset(leftOffset, 0),
		Size = UDim2.new(1, -leftOffset, 1, 0),
		Parent = content,
	})
	local layout = List(block, 2, nil, nil, Enum.VerticalAlignment.Center)
	layout.Name = "Layout"

	local title = Text({
		Name = "Title",
		Parent = block,
		Text = opts.Text or "",
		Style = "BodyLarge",
		Size = UDim2.new(1, 0, 0, 22),
		Truncate = true,
	})
	local description
	if hasDescription then
		description = Text({
			Name = "Description",
			Parent = block,
			Text = opts.Description,
			Style = "BodySmall",
			Role = "OnSurfaceVariant",
			Size = UDim2.new(1, 0, 0, 0),
			Wrap = true,
			AutoSize = "Y",
			LayoutOrder = 1,
		})
		-- The row keeps a fixed height that follows the measured text. An AutomaticSize row holding a
		-- scale-sized child makes Roblox grow the row in a feedback loop (rows ended up 500+ px tall).
		local function fit()
			local scale = math.max(Util.Scale, 0.01)
			local needed = 20 + 22 + 2 + description.AbsoluteSize.Y / scale
			row.Size = UDim2.new(1, 0, 0, math.max(minHeight, math.ceil(needed)))
		end
		description:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		task.defer(fit)
	end
	if opts.Visible == false then
		row.Visible = false
	end
	return row, right, block, title, description, content
end

local function reserveRight(block, right, extra)
	-- keep the text block clear of the right-hand control
	right:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local scale = math.max(Util.Scale, 0.01)
		block.Size = UDim2.new(block.Size.X.Scale, block.Size.X.Offset, 1, 0)
		local parentWidth = block.Parent.AbsoluteSize.X / scale
		local used = right.AbsoluteSize.X / scale + (extra or 12)
		local left = block.Position.X.Offset
		block.Size = UDim2.new(0, math.max(parentWidth - used - left, 20), 1, 0)
	end)
end

local function bindDisabled(self, ...)
	local targets = { ... }
	self._applyDisabled = function(disabled)
		for _, target in targets do
			Util.Tween(target, Util.Motion.Short, {
				[target:IsA("TextLabel") and "TextTransparency" or "ImageTransparency"] = disabled and 0.62 or 0,
			}, Enum.EasingStyle.Quad)
		end
	end
	if self.Disabled then
		self._applyDisabled(true)
	end
end

--// Label / paragraph \\--
function Controls.AddLabel(container, opts)
	if typeof(opts) == "string" then
		opts = { Text = opts }
	end
	local self = newControl("Label", opts, container)
	local row = Frame({
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 0),
		AutoSize = "Y",
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	Padding(row, 8, 16, 8, 16)
	local label = Text({
		Parent = row,
		Text = opts.Text or "",
		Style = opts.Style or "BodyMedium",
		Role = opts.Role or "OnSurfaceVariant",
		Size = UDim2.new(1, 0, 0, 0),
		AutoSize = "Y",
		Wrap = true,
		RichText = opts.RichText,
		XAlign = opts.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
	})
	self.Row = row
	self.Label = label
	self.Value = opts.Text or ""
	function self:Set(text)
		self.Value = tostring(text)
		label.Text = self.Value
	end
	self.SetText = self.Set
	function self:Serialize()
		return nil
	end
	if opts.Visible == false then
		row.Visible = false
	end
	return self
end

function Controls.AddDivider(container, opts)
	opts = opts or {}
	local self = newControl("Divider", opts, container)
	local row = Frame({
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, 17),
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	self.Line = Frame({
		Role = "OutlineVariant",
		Size = UDim2.new(1, -(opts.Inset == false and 0 or 32), 0, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = row,
	})
	self.Row = row
	function self:Serialize()
		return nil
	end
	self:_applyVisible()
	return self
end

--// Button \\--
-- Style: "Filled" (default) | "Tonal" | "Outlined" | "Text" | "Elevated" | "Danger"
function Controls.AddButton(container, opts)
	local self = newControl("Button", opts, container)
	local style = opts.Style or "Tonal"
	local holder = Frame({
		Name = opts.Text or "Button",
		Size = UDim2.new(1, 0, 0, 56),
		Parent = container,
	})
	holder.LayoutOrder = opts.LayoutOrder or 0
	Padding(holder, 8, 16, 8, 16)

	local background, content, strokeRole
	if style == "Filled" then
		background, content = "Primary", "OnPrimary"
	elseif style == "Danger" then
		background, content = "Error", "OnError"
	elseif style == "Outlined" then
		background, content, strokeRole = nil, "Primary", "Outline"
	elseif style == "Text" then
		background, content = nil, "Primary"
	elseif style == "Elevated" then
		background, content = "SurfaceContainerLow", "Primary"
	else
		background, content = "SecondaryContainer", "OnSecondaryContainer"
	end

	local button = Frame({
		Name = "Button",
		Size = UDim2.fromScale(1, 1),
		Role = background,
		Radius = "Full",
		StrokeRole = strokeRole,
		Parent = holder,
	})
	local inner = Frame({ Name = "Content", Size = UDim2.fromScale(1, 1), Parent = button, ZIndex = 3 })
	List(inner, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local icon
	if opts.Icon then
		icon = Icons.Create(opts.Icon, { Size = 18, Color = content, Parent = inner, ZIndex = 4, LayoutOrder = 0 })
	end
	local label = Text({
		Parent = inner,
		Text = opts.Text or "Button",
		Style = "LabelLarge",
		Role = content,
		Size = UDim2.fromOffset(0, 20),
		AutoSize = "X",
		XAlign = Enum.TextXAlignment.Center,
		ZIndex = 4,
		LayoutOrder = 1,
	})
	local interactive = Components.Interactive(button, {
		Radius = "Full",
		StateRole = content,
		Tooltip = opts.Tooltip,
		Disabled = self.Disabled,
		ZIndex = 2,
		OnClick = function()
			self:_emit(false)
		end,
	})
	self.Row = holder
	self.Interactive = interactive
	self.Value = nil
	function self:SetText(textValue)
		label.Text = tostring(textValue)
	end
	function self:Set()
		self:_emit(false)
	end
	function self:Serialize()
		return nil
	end
	bindDisabled(self, label)
	local baseApply = self._applyDisabled
	self._applyDisabled = function(disabled)
		interactive:SetDisabled(disabled)
		baseApply(disabled)
		if icon then
			Util.Tween(icon, Util.Motion.Short, { ImageTransparency = disabled and 0.62 or 0 }, Enum.EasingStyle.Quad)
		end
	end
	if self.Disabled then
		self._applyDisabled(true)
	end
	if opts.Visible == false then
		holder.Visible = false
	end
	return self
end

--// Toggle (Material 3 switch) \\--
function Controls.AddToggle(container, opts)
	local self = newControl("Toggle", opts, container)
	local row, right, block, title = makeRow(container, opts, 56)
	self.Row = row
	self.Value = opts.Default == true

	local track = Frame({
		Name = "Track",
		Size = UDim2.fromOffset(52, 32),
		Position = UDim2.fromScale(1, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
		Role = "SurfaceContainerHighest",
		Radius = "Full",
		StrokeRole = "Outline",
		StrokeThickness = 2,
		Parent = right,
	})
	right.Size = UDim2.new(0, 52, 1, 0)
	local stroke = track:FindFirstChildOfClass("UIStroke")
	local thumb = Frame({
		Name = "Thumb",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "Outline",
		Radius = "Full",
		ZIndex = 3,
		Parent = track,
	})
	local check = Icons.Create("check", {
		Size = 16,
		Color = "OnPrimaryContainer",
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = thumb,
		ZIndex = 4,
	})
	check.ImageTransparency = 1

	local function render(animate)
		local on = self.Value
		local duration = animate and Util.Motion.Medium or 0
		Core.Set(track, "BackgroundColor3", on and "Primary" or "SurfaceContainerHighest", duration)
		Core.Set(stroke, "Color", on and "Primary" or "Outline", duration)
		Core.Set(thumb, "BackgroundColor3", on and "OnPrimary" or "Outline", duration)
		local size = on and 24 or 16
		local x = on and 36 or 16
		Util.Tween(thumb, duration, {
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.new(0, x, 0.5, 0),
		}, Enum.EasingStyle.Back)
		Util.Tween(check, duration, { ImageTransparency = on and 0 or 1 }, Enum.EasingStyle.Quad)
	end
	render(false)

	function self:Set(value, silent)
		value = value == true
		if value == self.Value then
			return
		end
		self.Value = value
		render(true)
		self:_emit(silent)
	end

	local interactive = Components.Interactive(row, {
		Radius = "Medium",
		Tooltip = opts.Tooltip,
		Disabled = self.Disabled,
		ZIndex = 1,
		OnClick = function()
			self:Set(not self.Value)
		end,
	})
	bindDisabled(self, title)
	local baseApply = self._applyDisabled
	self._applyDisabled = function(disabled)
		interactive:SetDisabled(disabled)
		baseApply(disabled)
		track.BackgroundTransparency = disabled and 0.6 or 0
	end
	reserveRight(block, right, 16)
	register(self)
	if opts.Default and opts.Callback then
		task.spawn(opts.Callback, self.Value)
	end
	return self
end

--// Slider \\--
function Controls.AddSlider(container, opts)
	local self = newControl("Slider", opts, container)
	local minimum, maximum = opts.Min or 0, opts.Max or 100
	local step = opts.Step or 1
	local decimals = opts.Decimals or ((step < 1) and (#tostring(step) - 2) or 0)
	local suffix = opts.Suffix or ""

	local row = Frame({
		Name = opts.Flag or opts.Text or "Slider",
		Size = UDim2.new(1, 0, 0, 64),
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	Padding(row, 8, 16, 8, 16)
	self.Row = row

	local top = Frame({ Name = "Top", Size = UDim2.new(1, 0, 0, 24), Parent = row })
	local leftOffset = 0
	if opts.Icon then
		Icons.Create(opts.Icon, { Size = 20, Position = UDim2.fromOffset(0, 2), Parent = top })
		leftOffset = 30
	end
	local title = Text({
		Parent = top,
		Text = opts.Text or "",
		Style = "BodyLarge",
		Size = UDim2.new(1, -leftOffset - 80, 1, 0),
		Position = UDim2.fromOffset(leftOffset, 0),
		Truncate = true,
	})
	local valueLabel = Text({
		Parent = top,
		Style = "LabelLarge",
		Role = "Primary",
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		XAlign = Enum.TextXAlignment.Right,
	})

	local trackHolder = Frame({
		Name = "TrackHolder",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 28),
		Parent = row,
	})
	local inactive = Frame({
		Name = "Inactive",
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		Role = "SecondaryContainer",
		Radius = "Full",
		Parent = trackHolder,
	})
	local active = Frame({
		Name = "Active",
		Size = UDim2.fromScale(0, 1),
		Role = "Primary",
		Radius = "Full",
		Parent = inactive,
	})
	local handle = Frame({
		Name = "Handle",
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "Primary",
		Radius = "Full",
		ZIndex = 3,
		Parent = inactive,
	})
	local halo = Frame({
		Name = "Halo",
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Role = "Primary",
		Transparency = 1,
		Radius = "Full",
		ZIndex = 2,
		Parent = handle,
	})

	local function format(value)
		local text
		if opts.Format then
			text = opts.Format(value)
		else
			text = Util.FormatNumber(value, decimals) .. suffix
		end
		return text
	end

	local function render(animate)
		local alpha = (self.Value - minimum) / math.max(maximum - minimum, 1e-9)
		valueLabel.Text = format(self.Value)
		local duration = animate and 0.08 or 0
		Util.Tween(active, duration, { Size = UDim2.fromScale(alpha, 1) }, Enum.EasingStyle.Quad)
		Util.Tween(handle, duration, { Position = UDim2.fromScale(alpha, 0.5) }, Enum.EasingStyle.Quad)
	end

	self.Value = math.clamp(Util.Round(opts.Default or minimum, step), minimum, maximum)
	render(false)

	function self:Set(value, silent)
		value = math.clamp(Util.Round(tonumber(value) or minimum, step), minimum, maximum)
		if decimals > 0 then
			value = tonumber(Util.FormatNumber(value, decimals)) or value
		end
		if value == self.Value then
			return
		end
		self.Value = value
		render(true)
		self:_emit(silent)
	end

	local dragging = false
	local function update(input)
		local width = inactive.AbsoluteSize.X
		if width < 1 then
			return
		end
		local alpha = math.clamp((Util.PointerPosition(input).X - inactive.AbsolutePosition.X) / width, 0, 1)
		self:Set(minimum + (maximum - minimum) * alpha)
	end

	local hit = Instance.new("TextButton")
	hit.Selectable = false
	hit.Name = "Hit"
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Size = UDim2.new(1, 20, 1, 8)
	hit.Position = UDim2.fromOffset(-10, -4)
	hit.ZIndex = 9
	hit.Parent = trackHolder

	local function setHalo(active_)
		Util.Tween(halo, Util.Motion.Short, {
			Size = active_ and UDim2.fromOffset(40, 40) or UDim2.fromOffset(20, 20),
			BackgroundTransparency = active_ and 0.84 or 1,
		}, Enum.EasingStyle.Quad)
	end
	self._maid:Give(hit.InputBegan:Connect(function(input)
		if self.Disabled or not Util.IsPointer(input) then
			return
		end
		dragging = true
		setHalo(true)
		update(input)
	end))
	self._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end))
	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if dragging and Util.IsPointer(input) then
			dragging = false
			setHalo(false)
		end
	end))
	self._maid:Give(hit.MouseEnter:Connect(function()
		if not dragging and not self.Disabled then
			setHalo(true)
		end
		if opts.Tooltip then
			Core.ShowTooltip(opts.Tooltip, row)
		end
	end))
	self._maid:Give(hit.MouseLeave:Connect(function()
		if not dragging then
			setHalo(false)
		end
		if opts.Tooltip then
			Core.HideTooltip(row)
		end
	end))

	bindDisabled(self, title, valueLabel)
	if opts.Visible == false then
		row.Visible = false
	end
	register(self)
	return self
end

--// Text input \\--
function Controls.AddInput(container, opts)
	local self = newControl("Input", opts, container)
	self.Value = opts.Default or ""

	local row = Frame({
		Name = opts.Flag or opts.Text or "Input",
		Size = UDim2.new(1, 0, 0, 72),
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	Padding(row, 8, 16, 8, 16)
	self.Row = row

	local field = Frame({
		Name = "Field",
		Size = UDim2.fromScale(1, 1),
		Radius = "XSmall",
		StrokeRole = "Outline",
		Parent = row,
	})
	local stroke = field:FindFirstChildOfClass("UIStroke")

	-- Floating label sits on the border when focused or filled (outlined text field).
	local labelBack = Frame({
		Name = "LabelBack",
		Size = UDim2.fromOffset(0, 12),
		AutoSize = "X",
		Position = UDim2.new(0, 12, 0, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Role = "Surface",
		ZIndex = 4,
		Parent = field,
	})
	Padding(labelBack, 0, 4, 0, 4)
	labelBack.BackgroundTransparency = 1
	local label = Text({
		Parent = labelBack,
		Text = opts.Text or "",
		Style = "BodyLarge",
		Role = "OnSurfaceVariant",
		Size = UDim2.fromOffset(0, 16),
		AutoSize = "X",
		ZIndex = 5,
	})

	local box = Instance.new("TextBox")
	box.Name = "Box"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.PlaceholderText = ""
	box.Text = self.Value
	box.TextSize = 16
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.Size = UDim2.new(1, -28, 1, 0)
	box.Position = UDim2.fromOffset(14, 0)
	box.ZIndex = 5
	Assets.Apply(box, "Regular")
	Core.Bind(box, "TextColor3", "OnSurface")
	Core.Bind(box, "PlaceholderColor3", "OnSurfaceVariant")
	box.Parent = field
	if opts.Numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local filtered = box.Text:gsub("[^%d%.%-]", "")
			if filtered ~= box.Text then
				box.Text = filtered
			end
		end)
	end
	if opts.MaxLength then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if #box.Text > opts.MaxLength then
				box.Text = box.Text:sub(1, opts.MaxLength)
			end
		end)
	end

	local focused = false
	local function renderLabel(animate)
		local floating = focused or box.Text ~= ""
		local duration = animate and Util.Motion.Short or 0
		if floating then
			labelBack.BackgroundTransparency = 0
			Util.Tween(labelBack, duration, { Position = UDim2.new(0, 12, 0, 0) }, Enum.EasingStyle.Quad)
			label.TextSize = 12
			Core.Set(label, "TextColor3", focused and "Primary" or "OnSurfaceVariant", duration)
			Util.Tween(label, duration, { Size = UDim2.fromOffset(0, 14) })
		else
			labelBack.BackgroundTransparency = 1
			Util.Tween(labelBack, duration, { Position = UDim2.new(0, 12, 0.5, 0) }, Enum.EasingStyle.Quad)
			label.TextSize = 16
			Core.Set(label, "TextColor3", "OnSurfaceVariant", duration)
		end
		Core.Set(stroke, "Color", focused and "Primary" or "Outline", duration)
		stroke.Thickness = focused and 2 or 1
	end
	renderLabel(false)
	if opts.Placeholder then
		box.PlaceholderText = opts.Placeholder
	end

	self._maid:Give(box.Focused:Connect(function()
		focused = true
		renderLabel(true)
	end))
	self._maid:Give(box.FocusLost:Connect(function(enterPressed)
		focused = false
		local value = box.Text
		if opts.Numeric then
			local number = tonumber(value)
			if opts.Min and number then
				number = math.max(number, opts.Min)
			end
			if opts.Max and number then
				number = math.min(number, opts.Max)
			end
			value = number and tostring(number) or tostring(self.Value)
			box.Text = value
		end
		renderLabel(true)
		if opts.Finished == false or enterPressed or opts.Finished == nil then
			self:Set(value)
		end
	end))

	function self:Set(value, silent)
		value = tostring(value or "")
		if box.Text ~= value then
			box.Text = value
		end
		renderLabel(true)
		if value == self.Value then
			return
		end
		self.Value = value
		self:_emit(silent)
	end

	self._applyDisabled = function(disabled)
		box.TextEditable = not disabled
		box.TextTransparency = disabled and 0.6 or 0
	end
	if self.Disabled then
		self._applyDisabled(true)
	end
	if opts.Visible == false then
		row.Visible = false
	end
	register(self)
	return self
end

--// Dropdown (menu in the overlay layer) \\--
function Controls.AddDropdown(container, opts)
	local self = newControl("Dropdown", opts, container)
	local multi = opts.Multi == true
	local values = opts.Values or {}
	self.Values = values
	if multi then
		self.Value = {}
		if typeof(opts.Default) == "table" then
			for _, v in opts.Default do
				self.Value[v] = true
			end
		end
	else
		self.Value = opts.Default
		if self.Value == nil and not opts.AllowNull then
			self.Value = values[1]
		end
	end

	local row = Frame({
		Name = opts.Flag or opts.Text or "Dropdown",
		Size = UDim2.new(1, 0, 0, 72),
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	Padding(row, 8, 16, 8, 16)
	self.Row = row

	local field = Frame({
		Name = "Field",
		Size = UDim2.fromScale(1, 1),
		Radius = "XSmall",
		StrokeRole = "Outline",
		Parent = row,
	})
	local stroke = field:FindFirstChildOfClass("UIStroke")
	local labelBack = Frame({
		Size = UDim2.fromOffset(0, 12),
		AutoSize = "X",
		Position = UDim2.new(0, 12, 0, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Role = "Surface",
		ZIndex = 4,
		Parent = field,
	})
	Padding(labelBack, 0, 4, 0, 4)
	Text({
		Parent = labelBack,
		Text = opts.Text or "",
		Style = "BodySmall",
		Role = "OnSurfaceVariant",
		Size = UDim2.fromOffset(0, 14),
		AutoSize = "X",
		ZIndex = 5,
	})
	local valueText = Text({
		Parent = field,
		Style = "BodyLarge",
		Size = UDim2.new(1, -52, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		Truncate = true,
		ZIndex = 5,
	})
	local chevron = Icons.Create("expand_more", {
		Size = 24,
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Parent = field,
		ZIndex = 5,
	})

	local function display()
		if multi then
			local selected = {}
			for _, v in self.Values do
				if self.Value[v] then
					table.insert(selected, tostring(v))
				end
			end
			valueText.Text = #selected == 0 and (opts.Placeholder or "None") or table.concat(selected, ", ")
		else
			valueText.Text = self.Value ~= nil and tostring(self.Value) or (opts.Placeholder or "None")
		end
	end
	display()

	local menu, closeMenu
	local open = false

	local function selectValue(value)
		if multi then
			self.Value[value] = not self.Value[value] or nil
			display()
			self:_emit(false)
		else
			if self.Value ~= value then
				self.Value = value
				display()
				self:_emit(false)
			end
			closeMenu()
		end
	end

	local function buildMenu()
		local overlay = Core.Overlay
		local scale = math.max(Util.Scale, 0.01)
		local width = field.AbsoluteSize.X / scale
		local itemHeight = 48
		local count = #self.Values
		local visibleCount = math.min(count, opts.MaxVisible or 6)
		local height = visibleCount * itemHeight + 16

		menu = Frame({
			Name = "DropdownMenu",
			Canvas = true,
			Size = UDim2.fromOffset(width, 0),
			Role = "SurfaceContainer",
			Radius = "XSmall",
			ZIndex = 300,
			Parent = overlay,
		})
		local menuStroke = Instance.new("UIStroke")
		menuStroke.Thickness = 1
		Core.Bind(menuStroke, "Color", "OutlineVariant")
		menuStroke.Parent = menu

		local origin = overlay.AbsolutePosition
		local fieldPos = (field.AbsolutePosition - origin) / scale
		local overlayHeight = overlay.AbsoluteSize.Y / scale
		local below = fieldPos.Y + field.AbsoluteSize.Y / scale + 4
		local flip = below + height > overlayHeight - 8
		local y = flip and (fieldPos.Y - 4 - height) or below
		menu.Position = UDim2.fromOffset(fieldPos.X, y)
		menu.AnchorPoint = Vector2.new(0, flip and 1 or 0)
		if flip then
			menu.Position = UDim2.fromOffset(fieldPos.X, fieldPos.Y - 4)
		end

		local scroller = Instance.new("ScrollingFrame")
		scroller.Name = "Items"
		scroller.BackgroundTransparency = 1
		scroller.BorderSizePixel = 0
		scroller.Size = UDim2.fromScale(1, 1)
		scroller.ScrollBarThickness = 3
		scroller.CanvasSize = UDim2.new()
		scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroller.ZIndex = 301
		Core.Bind(scroller, "ScrollBarImageColor3", "Outline")
		scroller.Parent = menu
		Padding(scroller, 8, 0, 8, 0)
		List(scroller, 0)

		for index, value in self.Values do
			local item = Frame({
				Name = "Item",
				Size = UDim2.new(1, 0, 0, itemHeight),
				Role = "SecondaryContainer",
				Transparency = 1,
				ZIndex = 302,
				Parent = scroller,
			})
			item.LayoutOrder = index
			local isSelected = multi and self.Value[value] or (not multi and self.Value == value)
			if isSelected and not multi then
				item.BackgroundTransparency = 0
			end
			local textColor = (isSelected and not multi) and "OnSecondaryContainer" or "OnSurface"
			local itemLabel = Text({
				Parent = item,
				Text = tostring(value),
				Style = "BodyLarge",
				Role = textColor,
				Size = UDim2.new(1, -56, 1, 0),
				Position = UDim2.fromOffset(16, 0),
				Truncate = true,
				ZIndex = 303,
			})
			local mark
			if multi or isSelected then
				mark = Icons.Create("check", {
					Size = 20,
					Color = multi and "Primary" or "OnSecondaryContainer",
					Position = UDim2.new(1, -16, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = item,
					ZIndex = 303,
				})
				mark.Visible = isSelected and true or false
			end
			Components.Interactive(item, {
				StateRole = textColor,
				ZIndex = 302,
				OnClick = function()
					selectValue(value)
					if multi then
						local now = self.Value[value] and true or false
						if mark then
							mark.Visible = now
						end
					end
				end,
			})
			local _ = itemLabel
		end

		menu.Size = UDim2.fromOffset(width, 0)
		Util.Tween(menu, Util.Motion.Medium, { Size = UDim2.fromOffset(width, height) }, Enum.EasingStyle.Quint)
	end

	function closeMenu()
		if not open then
			return
		end
		open = false
		Core.UnregisterPopup(closeMenu)
		Util.Tween(chevron, Util.Motion.Medium, { Rotation = 0 }, Enum.EasingStyle.Quint)
		Core.Set(stroke, "Color", "Outline", Util.Motion.Short)
		stroke.Thickness = 1
		local m = menu
		menu = nil
		if m then
			local tween = Util.Tween(m, Util.Motion.Short, { Size = UDim2.fromOffset(m.Size.X.Offset, 0) }, Enum.EasingStyle.Quad)
			task.delay(tween and Util.Motion.Short or 0, function()
				m:Destroy()
			end)
		end
	end

	local function openMenu()
		if open or self.Disabled then
			return
		end
		Core.ClosePopups()
		open = true
		Core.RegisterPopup(closeMenu)
		Util.Tween(chevron, Util.Motion.Medium, { Rotation = 180 }, Enum.EasingStyle.Quint)
		Core.Set(stroke, "Color", "Primary", Util.Motion.Short)
		stroke.Thickness = 2
		buildMenu()
	end

	local interactive = Components.Interactive(field, {
		Radius = "XSmall",
		Tooltip = opts.Tooltip,
		ZIndex = 6,
		OnClick = function()
			if open then
				closeMenu()
			elseif not Core.WasJustClosed(closeMenu) then
				openMenu()
			end
		end,
	})

	self.Open = function()
		openMenu()
	end
	self.Close = function()
		closeMenu()
	end

	function self:Set(value, silent)
		if multi then
			local newValue = {}
			if typeof(value) == "table" then
				for k, v in value do
					if typeof(k) == "number" then
						newValue[v] = true
					elseif v then
						newValue[k] = true
					end
				end
			end
			self.Value = newValue
		else
			if value ~= nil and not table.find(self.Values, value) then
				return
			end
			if value == self.Value then
				return
			end
			self.Value = value
		end
		display()
		self:_emit(silent)
	end

	function self:SetValues(newValues, keepSelection)
		self.Values = newValues
		if not keepSelection or (not multi and not table.find(newValues, self.Value)) then
			if multi then
				self.Value = {}
			else
				self.Value = newValues[1]
			end
		end
		display()
		closeMenu()
	end

	function self:Serialize()
		if multi then
			local list = {}
			for _, v in self.Values do
				if self.Value[v] then
					table.insert(list, v)
				end
			end
			return list
		end
		return self.Value
	end

	function self:Deserialize(value)
		self:Set(value, true)
	end

	self._maid:Give(closeMenu)
	self._applyDisabled = function(disabled)
		interactive:SetDisabled(disabled)
		valueText.TextTransparency = disabled and 0.6 or 0
		if disabled then
			closeMenu()
		end
	end
	if self.Disabled then
		self._applyDisabled(true)
	end
	if opts.Visible == false then
		row.Visible = false
	end
	register(self)
	return self
end

--// Segmented button (single or multi select) \\--
function Controls.AddSegmented(container, opts)
	local self = newControl("Segmented", opts, container)
	local values = opts.Values or {}
	local multi = opts.Multi == true
	self.Values = values
	if multi then
		self.Value = {}
		if typeof(opts.Default) == "table" then
			for _, v in opts.Default do
				self.Value[v] = true
			end
		end
	else
		self.Value = opts.Default or values[1]
	end

	local hasTitle = opts.Text ~= nil and opts.Text ~= ""
	local row = Frame({
		Name = opts.Flag or opts.Text or "Segmented",
		Size = UDim2.new(1, 0, 0, hasTitle and 88 or 56),
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	Padding(row, 8, 16, 8, 16)
	self.Row = row

	if hasTitle then
		Text({ Parent = row, Text = opts.Text, Style = "BodyLarge", Size = UDim2.new(1, 0, 0, 24) })
	end
	local bar = Frame({
		Name = "Bar",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.fromOffset(0, hasTitle and 32 or 0),
		Radius = "Full",
		StrokeRole = "Outline",
		Canvas = true,
		Parent = row,
	})
	bar:FindFirstChildOfClass("UIStroke").Thickness = 1
	local layout = List(bar, 0, Enum.FillDirection.Horizontal)

	local buttons = {}
	local function isSelected(value)
		if multi then
			return self.Value[value] == true
		end
		return self.Value == value
	end

	local function render(animate)
		for value, entry in buttons do
			local selected = isSelected(value)
			local duration = animate and Util.Motion.Short or 0
			Core.Set(entry.frame, "BackgroundColor3", "SecondaryContainer", duration)
			Util.Tween(entry.frame, duration, { BackgroundTransparency = selected and 0 or 1 }, Enum.EasingStyle.Quad)
			Core.Set(entry.label, "TextColor3", selected and "OnSecondaryContainer" or "OnSurface", duration)
			entry.check.Visible = selected
			Core.Set(entry.check, "ImageColor3", "OnSecondaryContainer", 0)
		end
	end

	local function layoutButtons()
		local count = math.max(#values, 1)
		for _, entry in buttons do
			entry.frame.Size = UDim2.new(1 / count, 0, 1, 0)
		end
	end

	for index, value in values do
		local frame = Frame({
			Name = tostring(value),
			Role = "SecondaryContainer",
			Transparency = 1,
			Size = UDim2.new(1 / math.max(#values, 1), 0, 1, 0),
			Parent = bar,
		})
		frame.LayoutOrder = index
		local inner = Frame({ Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = frame })
		List(inner, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
		local check = Icons.Create("check", { Size = 16, Parent = inner, ZIndex = 4, LayoutOrder = 0 })
		check.Visible = false
		local label = Text({
			Parent = inner,
			Text = tostring(value),
			Style = "LabelLarge",
			Size = UDim2.fromOffset(0, 20),
			AutoSize = "X",
			ZIndex = 4,
			LayoutOrder = 1,
		})
		buttons[value] = { frame = frame, label = label, check = check }
		Components.Interactive(frame, {
			StateRole = "OnSurface",
			ZIndex = 2,
			OnClick = function()
				if self.Disabled then
					return
				end
				if multi then
					self.Value[value] = not self.Value[value] or nil
					render(true)
					self:_emit(false)
				elseif self.Value ~= value then
					self.Value = value
					render(true)
					self:_emit(false)
				end
			end,
		})
	end
	layoutButtons()
	render(false)
	local _ = layout

	function self:Set(value, silent)
		if multi then
			local newValue = {}
			if typeof(value) == "table" then
				for k, v in value do
					if typeof(k) == "number" then
						newValue[v] = true
					elseif v then
						newValue[k] = true
					end
				end
			end
			self.Value = newValue
		else
			if not buttons[value] or value == self.Value then
				return
			end
			self.Value = value
		end
		render(true)
		self:_emit(silent)
	end

	function self:Serialize()
		if multi then
			local list = {}
			for _, v in values do
				if self.Value[v] then
					table.insert(list, v)
				end
			end
			return list
		end
		return self.Value
	end
	if opts.Visible == false then
		row.Visible = false
	end
	register(self)
	return self
end

--// Chips (filter chips: multi toggle) \\--
function Controls.AddChips(container, opts)
	opts.Multi = true
	local self = newControl("Chips", opts, container)
	local values = opts.Values or {}
	self.Values = values
	self.Value = {}
	if typeof(opts.Default) == "table" then
		for _, v in opts.Default do
			self.Value[v] = true
		end
	end

	local row = Frame({
		Name = opts.Flag or opts.Text or "Chips",
		Size = UDim2.new(1, 0, 0, 0),
		AutoSize = "Y",
		Parent = container,
	})
	row.LayoutOrder = opts.LayoutOrder or 0
	Padding(row, 8, 16, 8, 16)
	List(row, 8)
	self.Row = row
	if opts.Text and opts.Text ~= "" then
		Text({ Parent = row, Text = opts.Text, Style = "BodyLarge", Size = UDim2.new(1, 0, 0, 24) })
	end
	local flow = Frame({ Size = UDim2.new(1, 0, 0, 0), AutoSize = "Y", Parent = row })
	flow.LayoutOrder = 1
	local grid = Instance.new("UIListLayout")
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.Wraps = true
	grid.Padding = UDim.new(0, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = flow

	local chips = {}
	local function render(animate)
		for value, chip in chips do
			local selected = self.Value[value] == true
			local duration = animate and Util.Motion.Short or 0
			Util.Tween(chip.frame, duration, { BackgroundTransparency = selected and 0 or 1 }, Enum.EasingStyle.Quad)
			Core.Set(chip.label, "TextColor3", selected and "OnSecondaryContainer" or "OnSurfaceVariant", duration)
			chip.check.Visible = selected
			chip.stroke.Transparency = selected and 1 or 0
		end
	end
	for index, value in values do
		local frame = Frame({
			Name = tostring(value),
			Size = UDim2.fromOffset(0, 32),
			AutoSize = "X",
			Role = "SecondaryContainer",
			Transparency = 1,
			Radius = "Small",
			StrokeRole = "Outline",
			Parent = flow,
		})
		frame.LayoutOrder = index
		local stroke = frame:FindFirstChildOfClass("UIStroke")
		Padding(frame, 0, 12, 0, 12)
		local inner = Frame({ Size = UDim2.new(0, 0, 1, 0), AutoSize = "X", ZIndex = 3, Parent = frame })
		List(inner, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
		local check = Icons.Create("check", { Size = 16, Color = "OnSecondaryContainer", Parent = inner, ZIndex = 4 })
		check.Visible = false
		check.LayoutOrder = 0
		local label = Text({
			Parent = inner,
			Text = tostring(value),
			Style = "LabelLarge",
			Role = "OnSurfaceVariant",
			Size = UDim2.fromOffset(0, 20),
			AutoSize = "X",
			ZIndex = 4,
			LayoutOrder = 1,
		})
		chips[value] = { frame = frame, label = label, check = check, stroke = stroke }
		Components.Interactive(frame, {
			Radius = "Small",
			StateRole = "OnSurface",
			ZIndex = 2,
			OnClick = function()
				if self.Disabled then
					return
				end
				self.Value[value] = not self.Value[value] or nil
				render(true)
				self:_emit(false)
			end,
		})
	end
	render(false)

	function self:Set(value, silent)
		local newValue = {}
		if typeof(value) == "table" then
			for k, v in value do
				if typeof(k) == "number" then
					newValue[v] = true
				elseif v then
					newValue[k] = true
				end
			end
		end
		self.Value = newValue
		render(true)
		self:_emit(silent)
	end
	function self:Serialize()
		local list = {}
		for _, v in values do
			if self.Value[v] then
				table.insert(list, v)
			end
		end
		return list
	end
	if opts.Visible == false then
		row.Visible = false
	end
	register(self)
	return self
end

--// Progress \\--
function Controls.AddProgress(container, opts)
	local self = newControl("Progress", opts, container)
	local row, right, block, _, _, content = makeRow(container, {
		Text = opts.Text,
		Description = opts.Description,
		Icon = opts.Icon,
		Flag = opts.Flag,
		LayoutOrder = opts.LayoutOrder,
		Visible = opts.Visible,
	}, 56)
	self.Row = row
	right.Size = UDim2.new(0, 56, 1, 0)
	local percent = Text({
		Parent = right,
		Style = "LabelLarge",
		Role = "Primary",
		Size = UDim2.fromScale(1, 1),
		XAlign = Enum.TextXAlignment.Right,
	})
	local barBack = Frame({
		Name = "Bar",
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.fromScale(0, 1),
		AnchorPoint = Vector2.new(0, 1),
		Role = "SecondaryContainer",
		Radius = "Full",
		Parent = content,
	})
	local fill = Frame({
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Role = "Primary",
		Radius = "Full",
		Parent = barBack,
	})
	reserveRight(block, right, 8)
	self.Value = math.clamp(opts.Default or 0, 0, 1)
	local function render(animate)
		percent.Text = string.format("%d%%", math.floor(self.Value * 100 + 0.5))
		Util.Tween(fill, animate and Util.Motion.Medium or 0, { Size = UDim2.fromScale(self.Value, 1) })
	end
	render(false)
	function self:Set(value, silent)
		value = math.clamp(tonumber(value) or 0, 0, 1)
		if value == self.Value then
			return
		end
		self.Value = value
		render(true)
		self:_emit(silent)
	end
	function self:Serialize()
		return nil
	end
	return self
end

--// Keybind \\--
local KEY_NAMES = {
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftShift = "LShift",
	RightShift = "RShift",
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
	Return = "Enter",
	Backspace = "Backspace",
	Escape = "Esc",
	Space = "Space",
	Zero = "0",
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
}

local function keyName(key)
	if key == nil then
		return "None"
	end
	if typeof(key) == "EnumItem" then
		if key.EnumType == Enum.UserInputType then
			if key == Enum.UserInputType.MouseButton1 then
				return "Mouse 1"
			elseif key == Enum.UserInputType.MouseButton2 then
				return "Mouse 2"
			elseif key == Enum.UserInputType.MouseButton3 then
				return "Mouse 3"
			end
		end
		return KEY_NAMES[key.Name] or key.Name
	end
	return tostring(key)
end

Controls.KeyName = keyName

local function parseKey(value)
	if value == nil or value == "None" then
		return nil
	end
	if typeof(value) == "EnumItem" then
		return value
	end
	if typeof(value) == "string" then
		local keyCode = Enum.KeyCode[value]
		if keyCode then
			return keyCode
		end
		local ok, inputType = pcall(function()
			return Enum.UserInputType[value]
		end)
		if ok and inputType then
			return inputType
		end
	end
	return nil
end

-- Mode: "Press" (callback on press, default) | "Hold" (value true while held) | "Toggle" (value flips on press)
function Controls.AddKeybind(container, opts)
	local self = newControl("Keybind", opts, container)
	local row, right, block, title = makeRow(container, opts, 56)
	self.Row = row
	self.Mode = opts.Mode or "Press"
	self.Key = parseKey(opts.Default)
	if self.Mode ~= "Press" then
		self.Value = false
	end
	self.Pressed = Util.Signal.new()

	local chip = Frame({
		Name = "Chip",
		Size = UDim2.fromOffset(0, 32),
		AutoSize = "X",
		Position = UDim2.fromScale(1, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
		Role = "SurfaceContainerHighest",
		Radius = "Small",
		StrokeRole = "OutlineVariant",
		Parent = right,
	})
	Padding(chip, 0, 12, 0, 12)
	local keyLabel = Text({
		Parent = chip,
		Style = "LabelLarge",
		Size = UDim2.fromOffset(0, 32),
		AutoSize = "X",
		XAlign = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})
	right.Size = UDim2.new(0, 80, 1, 0)

	local listening = false
	local function render()
		keyLabel.Text = listening and "Press a key…" or keyName(self.Key)
		Core.Set(chip, "BackgroundColor3", listening and "PrimaryContainer" or "SurfaceContainerHighest", Util.Motion.Short)
		Core.Set(keyLabel, "TextColor3", listening and "OnPrimaryContainer" or "OnSurface", Util.Motion.Short)
	end
	render()

	local interactive = Components.Interactive(chip, {
		Radius = "Small",
		StateRole = "OnSurface",
		Tooltip = opts.Tooltip or "Click, then press a key (Esc clears)",
		ZIndex = 2,
		OnClick = function()
			if self.Disabled then
				return
			end
			listening = true
			Core.Listening = true
			render()
		end,
	})

	local function trigger(down)
		if self.Mode == "Hold" then
			if self.Value ~= down then
				self.Value = down
				self:_emit(false)
			end
		elseif down then
			if self.Mode == "Toggle" then
				self.Value = not self.Value
				self:_emit(false)
			else
				self.Pressed:Fire()
				if self._callback then
					task.spawn(self._callback)
				end
			end
		end
	end

	local function matches(input)
		local key = self.Key
		if not key then
			return false
		end
		if key.EnumType == Enum.KeyCode then
			return input.KeyCode == key
		end
		return input.UserInputType == key
	end

	self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				task.defer(function()
					Core.Listening = false
				end)
				if input.KeyCode == Enum.KeyCode.Escape then
					self.Key = nil
				else
					self.Key = input.KeyCode
				end
				render()
				self.Changed:Fire(self.Value)
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
				listening = false
				task.defer(function()
					Core.Listening = false
				end)
				self.Key = input.UserInputType
				render()
				self.Changed:Fire(self.Value)
			end
			return
		end
		if processed or self.Disabled then
			return
		end
		if matches(input) then
			trigger(true)
		end
	end))
	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if not listening and matches(input) and self.Mode == "Hold" then
			trigger(false)
		end
	end))

	function self:Set(value, silent)
		self.Key = parseKey(value)
		render()
		if not silent then
			self.Changed:Fire(self.Value)
		end
	end
	function self:GetKey()
		return self.Key
	end
	function self:Serialize()
		return self.Key and self.Key.Name or "None"
	end
	function self:Deserialize(value)
		self:Set(value, true)
	end

	bindDisabled(self, title)
	local baseApply = self._applyDisabled
	self._applyDisabled = function(disabled)
		interactive:SetDisabled(disabled)
		baseApply(disabled)
	end
	reserveRight(block, right, 12)
	register(self)
	return self
end

--// Color picker \\--
function Controls.AddColorPicker(container, opts)
	local self = newControl("ColorPicker", opts, container)
	local row, right, block, title = makeRow(container, opts, 56)
	self.Row = row
	local default = opts.Default
	if typeof(default) == "string" then
		default = Util.FromHex(default)
	end
	self.Value = default or Color3.fromRGB(103, 80, 164)
	local hue, saturation, value = self.Value:ToHSV()

	local swatch = Frame({
		Name = "Swatch",
		Size = UDim2.fromOffset(40, 32),
		Position = UDim2.fromScale(1, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
		Radius = "Small",
		StrokeRole = "Outline",
		Parent = right,
	})
	swatch.BackgroundColor3 = self.Value
	swatch.BackgroundTransparency = 0
	right.Size = UDim2.new(0, 40, 1, 0)

	local popup, closePicker
	local open = false

	local function apply(silent)
		self.Value = Color3.fromHSV(hue, saturation, value)
		swatch.BackgroundColor3 = self.Value
		self:_emit(silent)
	end

	local function openPicker()
		if open or self.Disabled then
			return
		end
		Core.ClosePopups()
		open = true
		Core.RegisterPopup(closePicker)
		local overlay = Core.Overlay
		local scale = math.max(Util.Scale, 0.01)
		local width, height = 264, 288
		popup = Frame({
			Name = "ColorPicker",
			Canvas = true,
			Size = UDim2.fromOffset(width, 0),
			Role = "SurfaceContainerHigh",
			Radius = "Medium",
			ZIndex = 300,
			Parent = overlay,
		})
		local popStroke = Instance.new("UIStroke")
		popStroke.Thickness = 1
		Core.Bind(popStroke, "Color", "OutlineVariant")
		popStroke.Parent = popup

		local origin = overlay.AbsolutePosition
		local at = (swatch.AbsolutePosition - origin) / scale
		local overlaySize = overlay.AbsoluteSize / scale
		local x = math.clamp(at.X + 40 - width, 8, overlaySize.X - width - 8)
		local y = math.clamp(at.Y + 36, 8, overlaySize.Y - height - 8)
		popup.Position = UDim2.fromOffset(x, y)
		Padding(popup, 16, 16, 16, 16)

		local sv = Instance.new("ImageButton")
		sv.Selectable = false
		sv.Name = "SV"
		sv.AutoButtonColor = false
		sv.BorderSizePixel = 0
		sv.Size = UDim2.new(1, 0, 0, 144)
		sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		sv.Image = ""
		sv.ZIndex = 301
		sv.Parent = popup
		Core.Corner(sv, "Small")
		local white = Instance.new("UIGradient")
		white.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
		white.Transparency = NumberSequence.new(0, 1)
		white.Parent = sv
		local blackOverlay = Frame({ Size = UDim2.fromScale(1, 1), Role = Color3.new(0, 0, 0), ZIndex = 302, Parent = sv })
		Core.Corner(blackOverlay, "Small")
		local black = Instance.new("UIGradient")
		black.Rotation = 90
		black.Transparency = NumberSequence.new(1, 0)
		black.Parent = blackOverlay
		local cursor = Frame({
			Size = UDim2.fromOffset(16, 16),
			Role = Color3.new(1, 1, 1),
			Radius = "Full",
			StrokeRole = Color3.new(0, 0, 0),
			StrokeThickness = 2,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 304,
			Parent = sv,
		})

		local hueBar = Instance.new("ImageButton")
		hueBar.Selectable = false
		hueBar.Name = "Hue"
		hueBar.AutoButtonColor = false
		hueBar.BorderSizePixel = 0
		hueBar.Size = UDim2.new(1, 0, 0, 16)
		hueBar.Position = UDim2.fromOffset(0, 156)
		hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
		hueBar.Image = ""
		hueBar.ZIndex = 301
		hueBar.Parent = popup
		Core.Corner(hueBar, "Full")
		local keypoints = {}
		for i = 0, 6 do
			table.insert(keypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
		end
		local hueGradient = Instance.new("UIGradient")
		hueGradient.Color = ColorSequence.new(keypoints)
		hueGradient.Parent = hueBar
		local hueCursor = Frame({
			Size = UDim2.fromOffset(8, 24),
			Role = Color3.new(1, 1, 1),
			Radius = "Full",
			StrokeRole = Color3.new(0, 0, 0),
			StrokeThickness = 2,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(hue, 0.5),
			ZIndex = 303,
			Parent = hueBar,
		})

		local hexBox = Instance.new("TextBox")
		hexBox.Name = "Hex"
		hexBox.Size = UDim2.new(1, 0, 0, 40)
		hexBox.Position = UDim2.fromOffset(0, 184)
		hexBox.BorderSizePixel = 0
		hexBox.ClearTextOnFocus = false
		hexBox.TextSize = 14
		hexBox.ZIndex = 301
		hexBox.PlaceholderText = "#RRGGBB"
		Assets.Apply(hexBox, "Medium")
		Core.Bind(hexBox, "BackgroundColor3", "SurfaceContainerHighest")
		Core.Bind(hexBox, "TextColor3", "OnSurface")
		Core.Bind(hexBox, "PlaceholderColor3", "OnSurfaceVariant")
		hexBox.Parent = popup
		Core.Corner(hexBox, "Small")

		local function sync()
			sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			cursor.Position = UDim2.fromScale(saturation, 1 - value)
			hueCursor.Position = UDim2.fromScale(hue, 0.5)
			hexBox.Text = Util.ToHex(Color3.fromHSV(hue, saturation, value))
		end
		sync()

		local draggingSV, draggingHue = false, false
		local function updateSV(input)
			local pos = Util.PointerPosition(input)
			saturation = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			value = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
			sync()
			apply(false)
		end
		local function updateHue(input)
			local pos = Util.PointerPosition(input)
			hue = math.clamp((pos.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
			sync()
			apply(false)
		end
		sv.InputBegan:Connect(function(input)
			if Util.IsPointer(input) then
				draggingSV = true
				updateSV(input)
			end
		end)
		hueBar.InputBegan:Connect(function(input)
			if Util.IsPointer(input) then
				draggingHue = true
				updateHue(input)
			end
		end)
		local move = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if draggingSV then
					updateSV(input)
				elseif draggingHue then
					updateHue(input)
				end
			end
		end)
		local release = UserInputService.InputEnded:Connect(function(input)
			if Util.IsPointer(input) then
				draggingSV, draggingHue = false, false
			end
		end)
		popup.Destroying:Connect(function()
			move:Disconnect()
			release:Disconnect()
		end)
		hexBox.FocusLost:Connect(function()
			local parsed = Util.FromHex(hexBox.Text)
			if parsed then
				hue, saturation, value = parsed:ToHSV()
				sync()
				apply(false)
			else
				sync()
			end
		end)

		popup.Size = UDim2.fromOffset(width, 0)
		Util.Tween(popup, Util.Motion.Medium, { Size = UDim2.fromOffset(width, height) }, Enum.EasingStyle.Quint)
	end

	function closePicker()
		if not open then
			return
		end
		open = false
		Core.UnregisterPopup(closePicker)
		local p = popup
		popup = nil
		if p then
			local tween = Util.Tween(p, Util.Motion.Short, { Size = UDim2.fromOffset(p.Size.X.Offset, 0) }, Enum.EasingStyle.Quad)
			task.delay(tween and Util.Motion.Short or 0, function()
				p:Destroy()
			end)
		end
	end

	local interactive = Components.Interactive(swatch, {
		Radius = "Small",
		Tooltip = opts.Tooltip,
		ZIndex = 3,
		OnClick = function()
			if open then
				closePicker()
			elseif not Core.WasJustClosed(closePicker) then
				openPicker()
			end
		end,
	})

	self.Open = function()
		openPicker()
	end
	self.Close = function()
		closePicker()
	end

	function self:Set(color, silent)
		if typeof(color) == "string" then
			color = Util.FromHex(color)
		end
		if typeof(color) ~= "Color3" then
			return
		end
		hue, saturation, value = color:ToHSV()
		self.Value = color
		swatch.BackgroundColor3 = color
		self:_emit(silent)
	end
	function self:Serialize()
		return Util.ToHex(self.Value)
	end
	function self:Deserialize(v)
		self:Set(v, true)
	end

	self._maid:Give(closePicker)
	bindDisabled(self, title)
	local baseApply = self._applyDisabled
	self._applyDisabled = function(disabled)
		interactive:SetDisabled(disabled)
		baseApply(disabled)
		if disabled then
			closePicker()
		end
	end
	reserveRight(block, right, 12)
	register(self)
	return self
end

--// Attach all Add* methods to a container-like object \\--
function Controls.Attach(target, getContainer)
	local function wrap(name, fn)
		target[name] = function(self, opts)
			if typeof(opts) == "string" then
				opts = { Text = opts }
			end
			opts = opts or {}
			local control = fn(getContainer(self), opts)
			if self._track then
				self:_track(control, opts)
			end
			return control
		end
	end
	wrap("AddLabel", Controls.AddLabel)
	wrap("AddDivider", Controls.AddDivider)
	wrap("AddButton", Controls.AddButton)
	wrap("AddToggle", Controls.AddToggle)
	wrap("AddSlider", Controls.AddSlider)
	wrap("AddInput", Controls.AddInput)
	wrap("AddDropdown", Controls.AddDropdown)
	wrap("AddSegmented", Controls.AddSegmented)
	wrap("AddChips", Controls.AddChips)
	wrap("AddProgress", Controls.AddProgress)
	wrap("AddKeybind", Controls.AddKeybind)
	wrap("AddColorPicker", Controls.AddColorPicker)
	target.AddParagraph = function(self, opts)
		opts = opts or {}
		local control = Controls.AddLabel(getContainer(self), {
			Text = (opts.Title and ("<b>" .. opts.Title .. "</b>\n") or "") .. (opts.Content or opts.Text or ""),
			RichText = true,
			Role = "OnSurfaceVariant",
		})
		if self._track then
			self:_track(control, { Text = (opts.Title or "") .. " " .. (opts.Content or opts.Text or "") })
		end
		return control
	end
end

return Controls
