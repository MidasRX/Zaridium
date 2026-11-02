--!nonstrict
-- Material Symbols atlas lookup. Icons are white glyphs; tint with ImageColor3 (bound to a theme role).

local Core = require("Core")
local Assets = require("Assets")
local IconData = require("IconData")

local Icons = {}

function Icons.Resolve(name)
	if typeof(name) ~= "string" then
		return nil
	end
	local key = string.lower(name):gsub("[%s%-]", "_")
	local alias = IconData.Aliases[key]
	if alias then
		key = alias
	end
	return IconData.Icons[key] and key or nil
end

function Icons.Has(name)
	return Icons.Resolve(name) ~= nil
end

function Icons.List()
	local names = {}
	for name in IconData.Icons do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- Points an ImageLabel/ImageButton at an icon. Accepts an icon name, an asset id number or an "rbxassetid://" string.
function Icons.Apply(image, name, filled)
	local kind = typeof(name)
	if kind == "number" then
		image.Image = "rbxassetid://" .. name
		image.ImageRectOffset = Vector2.zero
		image.ImageRectSize = Vector2.zero
		return true
	elseif kind == "string" and (name:find("^rbxassetid://") or name:find("^rbxasset://") or name:find("^http")) then
		image.Image = name
		image.ImageRectOffset = Vector2.zero
		image.ImageRectSize = Vector2.zero
		return true
	end

	local key = Icons.Resolve(name)
	if not key or Assets.Atlas == "" then
		image.Image = ""
		return false
	end
	local cell = IconData.Icons[key][filled and "f" or "o"]
	image.Image = Assets.Atlas
	image.ImageRectOffset = Vector2.new(cell[1], cell[2])
	image.ImageRectSize = Vector2.new(IconData.Cell, IconData.Cell)
	return true
end

-- Creates an icon ImageLabel. props: Name, Size (px number), Color (role/Color3), Filled, Position, AnchorPoint, Parent, ZIndex
function Icons.Create(name, props)
	props = props or {}
	local size = props.Size or 24
	local image = Instance.new("ImageLabel")
	image.Name = props.Name or "Icon"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Size = UDim2.fromOffset(size, size)
	image.Position = props.Position or UDim2.new()
	image.AnchorPoint = props.AnchorPoint or Vector2.zero
	image.ZIndex = props.ZIndex or 2
	image.ScaleType = Enum.ScaleType.Fit
	if props.LayoutOrder then
		image.LayoutOrder = props.LayoutOrder
	end
	Core.Bind(image, "ImageColor3", props.Color or "OnSurfaceVariant")
	local ok = Icons.Apply(image, name, props.Filled)
	image.Visible = ok or name == nil
	image.Parent = props.Parent
	return image
end

return Icons
