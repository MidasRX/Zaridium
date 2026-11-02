--!nonstrict
-- Low-level Material 3 building blocks: typography, frames, state layers and ripples.

local Util = require("Util")
local Core = require("Core")
local Assets = require("Assets")
local Icons = require("Icons")

local UserInputService = game:GetService("UserInputService")

local Components = {}

--// Typography (Material 3 type scale) \\--
Components.Type = {
	HeadlineSmall = { 24, "Regular" },
	TitleLarge = { 22, "Medium" },
	TitleMedium = { 16, "SemiBold" },
	TitleSmall = { 14, "SemiBold" },
	LabelLarge = { 14, "Medium" },
	LabelMedium = { 12, "Medium" },
	LabelSmall = { 11, "Medium" },
	BodyLarge = { 16, "Regular" },
	BodyMedium = { 14, "Regular" },
	BodySmall = { 12, "Regular" },
}

-- props: Parent, Text, Style, Role, Size, Position, AnchorPoint, XAlign, YAlign, Wrap, AutoSize ("X"|"Y"|"XY"),
--        LayoutOrder, Truncate, ZIndex, Name
function Components.Text(props)
	local style = Components.Type[props.Style or "BodyMedium"] or Components.Type.BodyMedium
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Text"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = props.Text or ""
	label.TextSize = style[1]
	label.RichText = props.RichText == true
	label.TextXAlignment = props.XAlign or Enum.TextXAlignment.Left
	label.TextYAlignment = props.YAlign or Enum.TextYAlignment.Center
	label.TextWrapped = props.Wrap == true
	label.TextTruncate = props.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
	label.Size = props.Size or UDim2.new(1, 0, 0, style[1] + 6)
	label.Position = props.Position or UDim2.new()
	label.AnchorPoint = props.AnchorPoint or Vector2.zero
	label.ZIndex = props.ZIndex or 2
	label.LayoutOrder = props.LayoutOrder or 0
	if props.AutoSize == "X" then
		label.AutomaticSize = Enum.AutomaticSize.X
	elseif props.AutoSize == "Y" then
		label.AutomaticSize = Enum.AutomaticSize.Y
	elseif props.AutoSize == "XY" then
		label.AutomaticSize = Enum.AutomaticSize.XY
	end
	Assets.Apply(label, style[2])
	Core.Bind(label, "TextColor3", props.Role or "OnSurface")
	label.Parent = props.Parent
	return label
end

-- props: Name, Size, Position, AnchorPoint, Role (background color role), Transparency, Radius, Parent, Clip, LayoutOrder,
--        ZIndex, StrokeRole, StrokeThickness, AutoSize, Canvas (use CanvasGroup)
function Components.Frame(props)
	local frame = Instance.new(props.Canvas and "CanvasGroup" or "Frame")
	frame.Name = props.Name or "Frame"
	frame.BorderSizePixel = 0
	frame.Size = props.Size or UDim2.fromScale(1, 1)
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.ZIndex = props.ZIndex or 1
	frame.LayoutOrder = props.LayoutOrder or 0
	frame.ClipsDescendants = props.Clip == true
	if props.AutoSize == "Y" then
		frame.AutomaticSize = Enum.AutomaticSize.Y
	elseif props.AutoSize == "X" then
		frame.AutomaticSize = Enum.AutomaticSize.X
	elseif props.AutoSize == "XY" then
		frame.AutomaticSize = Enum.AutomaticSize.XY
	end
	if props.Role then
		Core.Bind(frame, "BackgroundColor3", props.Role)
		frame.BackgroundTransparency = props.Transparency or 0
	else
		frame.BackgroundTransparency = 1
	end
	if props.Radius then
		Core.Corner(frame, props.Radius)
	end
	if props.StrokeRole then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = props.StrokeThickness or 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Core.Bind(stroke, "Color", props.StrokeRole)
		stroke.Parent = frame
	end
	frame.Parent = props.Parent
	return frame
end

function Components.Padding(parent, top, right, bottom, left)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingRight = UDim.new(0, right or top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or top or 0)
	padding.PaddingLeft = UDim.new(0, left or right or top or 0)
	padding.Parent = parent
	return padding
end

function Components.List(parent, padding, direction, hAlign, vAlign)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, padding or 0)
	layout.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
	layout.Parent = parent
	return layout
end

--// Interaction: state layer + ripple + click \\--
-- host: the visible GuiObject. opts: Radius, StateRole (default "OnSurface"), Ripple (default true), Disabled,
--       OnClick(input), OnPress(), OnRelease(), OnHover(isHovering), Tooltip, ZIndex, CanFocus
function Components.Interactive(host, opts)
	opts = opts or {}
	local maid = Util.Maid.new()
	local self = {
		Host = host,
		Hovering = false,
		Pressing = false,
		Disabled = opts.Disabled == true,
		Clicked = Util.Signal.new(),
	}

	local layer = Components.Frame({
		Name = "StateLayer",
		Canvas = true,
		ZIndex = opts.ZIndex or 1,
	})
	layer.Parent = host
	if opts.Radius then
		Core.Corner(layer, opts.Radius)
	end

	local state = Components.Frame({ Name = "State", Role = opts.StateRole or "OnSurface", Transparency = 1 })
	state.Parent = layer

	local hit = Instance.new("TextButton")
	hit.Selectable = false
	hit.Name = "Hit"
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = (opts.ZIndex or 1) + 8
	hit.Selectable = opts.CanFocus == true
	hit.Parent = host

	local function refresh()
		local transparency = 1
		if not self.Disabled then
			if self.Pressing then
				transparency = 0.88
			elseif self.Hovering then
				transparency = 0.92
			end
		end
		Util.Tween(state, Util.Motion.Short, { BackgroundTransparency = transparency }, Enum.EasingStyle.Quad)
	end

	local activeRipples = {}

	local function spawnRipple(pointer)
		if not Util.RippleEnabled or not Util.AnimationsEnabled or opts.Ripple == false then
			return
		end
		local size = layer.AbsoluteSize
		if size.X < 1 or size.Y < 1 then
			return
		end
		local scale = math.max(Util.Scale, 0.01)
		local local_ = (pointer - layer.AbsolutePosition) / scale
		local width, height = size.X / scale, size.Y / scale
		local radius = math.sqrt(
			math.max(local_.X, width - local_.X) ^ 2 + math.max(local_.Y, height - local_.Y) ^ 2
		)
		local circle = Components.Frame({
			Name = "Ripple",
			Role = opts.StateRole or "OnSurface",
			Transparency = 0.84,
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(local_.X, local_.Y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Radius = "Full",
			ZIndex = 2,
		})
		circle.Parent = layer
		Util.Tween(
			circle,
			Util.Motion.Long,
			{ Size = UDim2.fromOffset(radius * 2, radius * 2) },
			Enum.EasingStyle.Quint
		)
		table.insert(activeRipples, circle)
		return circle
	end

	local function fadeRipples()
		local list = activeRipples
		activeRipples = {}
		for _, circle in list do
			Util.Tween(circle, Util.Motion.Long, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
			task.delay(Util.Motion.Long + 0.05, function()
				circle:Destroy()
			end)
		end
	end

	maid:Give(hit.MouseEnter:Connect(function()
		self.Hovering = true
		refresh()
		if opts.OnHover then
			opts.OnHover(true)
		end
		if opts.Tooltip then
			Core.ShowTooltip(opts.Tooltip, host)
		end
	end))
	maid:Give(hit.MouseLeave:Connect(function()
		self.Hovering = false
		self.Pressing = false
		refresh()
		fadeRipples()
		if opts.OnHover then
			opts.OnHover(false)
		end
		if opts.Tooltip then
			Core.HideTooltip(host)
		end
	end))
	maid:Give(hit.InputBegan:Connect(function(input)
		if self.Disabled or not Util.IsPointer(input) then
			return
		end
		self.Pressing = true
		refresh()
		spawnRipple(Util.PointerPosition(input))
		if opts.OnPress then
			opts.OnPress(input)
		end
	end))
	maid:Give(hit.InputEnded:Connect(function(input)
		if not Util.IsPointer(input) then
			return
		end
		if self.Pressing then
			self.Pressing = false
			refresh()
			fadeRipples()
			if opts.OnRelease then
				opts.OnRelease(input)
			end
		end
	end))
	maid:Give(hit.Activated:Connect(function(input)
		if self.Disabled then
			return
		end
		self.Clicked:Fire(input)
		if opts.OnClick then
			opts.OnClick(input)
		end
	end))

	function self:SetDisabled(disabled)
		self.Disabled = disabled and true or false
		hit.Active = not self.Disabled
		refresh()
	end

	function self:Destroy()
		maid:Clean()
		layer:Destroy()
		hit:Destroy()
	end

	self.Hit = hit
	self.Layer = layer
	return self
end

--// Common widgets \\--

-- Standalone icon button (round, 40px): props Parent, Icon, Size, Role, Tooltip, OnClick, Position, AnchorPoint
function Components.IconButton(props)
	local size = props.Size or 40
	local button = Components.Frame({
		Name = props.Name or "IconButton",
		Size = UDim2.fromOffset(size, size),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Role = props.Background,
		Radius = "Full",
		Parent = props.Parent,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex or 2,
	})
	local icon = Icons.Create(props.Icon, {
		Size = math.floor(size * 0.6),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = props.Role or "OnSurfaceVariant",
		Parent = button,
		ZIndex = (props.ZIndex or 2) + 1,
	})
	local interactive = Components.Interactive(button, {
		Radius = "Full",
		StateRole = props.StateRole or props.Role or "OnSurface",
		Tooltip = props.Tooltip,
		OnClick = props.OnClick,
		ZIndex = props.ZIndex or 2,
	})
	return button, icon, interactive
end

-- Tooltip lives in the overlay layer; Library wires it up through Core.
function Components.InstallTooltips(overlay)
	local tip = Components.Frame({
		Name = "Tooltip",
		Role = "InverseSurface",
		Radius = "XSmall",
		Size = UDim2.fromOffset(10, 28),
		AutoSize = "XY",
		ZIndex = 400,
		Parent = overlay,
	})
	tip.Visible = false
	Components.Padding(tip, 6, 10, 6, 10)
	local label = Components.Text({
		Parent = tip,
		Style = "BodySmall",
		Role = "InverseOnSurface",
		Size = UDim2.fromOffset(0, 16),
		AutoSize = "XY",
		ZIndex = 401,
	})
	local owner = nil
	local token = 0

	function Core.ShowTooltip(text, host)
		token += 1
		local mine = token
		owner = host
		task.delay(0.45, function()
			if mine ~= token or owner ~= host or not host.Parent then
				return
			end
			label.Text = text
			tip.Visible = true
		end)
	end

	function Core.HideTooltip(host)
		if owner == host or host == nil then
			token += 1
			owner = nil
			tip.Visible = false
		end
	end

	local scale = overlay:FindFirstChildOfClass("UIScale")
	local connection = UserInputService.InputChanged:Connect(function(input)
		if tip.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			local s = scale and scale.Scale or 1
			local origin = overlay.AbsolutePosition
			local mouse = UserInputService:GetMouseLocation()
			tip.Position = UDim2.fromOffset((mouse.X - origin.X) / s + 14, (mouse.Y - origin.Y) / s + 18)
		end
	end)

	return tip, connection
end

return Components
