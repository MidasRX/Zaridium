--!nonstrict
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Util = {}

--// Shared runtime state (written by Library, read by components) \\--
Util.AnimationsEnabled = true
Util.RippleEnabled = true
Util.Speed = 1 -- global animation speed multiplier
Util.Scale = 1 -- current UIScale of the root frame

Util.Motion = {
	Instant = 0,
	Short = 0.12,
	Medium = 0.25,
	Long = 0.4,
	Emphasized = Enum.EasingStyle.Quint,
	Standard = Enum.EasingStyle.Quad,
}

--// Signal \\--
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handlers = self._handlers
	local connection = { Connected = true }
	local entry = { fn = fn, connection = connection }
	table.insert(handlers, entry)
	function connection:Disconnect()
		if not self.Connected then
			return
		end
		self.Connected = false
		local index = table.find(handlers, entry)
		if index then
			table.remove(handlers, index)
		end
	end
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Fire(...)
	for _, entry in table.clone(self._handlers) do
		task.spawn(entry.fn, ...)
	end
end

function Signal:Destroy()
	table.clear(self._handlers)
end

Util.Signal = Signal

--// Maid \\--
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(item)
	table.insert(self._tasks, item)
	return item
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for _, item in tasks do
		local kind = typeof(item)
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "function" then
			pcall(item)
		elseif kind == "table" then
			if item.Disconnect then
				item:Disconnect()
			elseif item.Destroy then
				item:Destroy()
			end
		end
	end
end

Maid.Destroy = Maid.Clean

Util.Maid = Maid

--// Instances \\--
function Util.New(className, props, children)
	local instance = Instance.new(className)
	local parent
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				instance[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Util.Tween(instance, duration, props, style, direction)
	if not Util.AnimationsEnabled or not duration or duration <= 0 then
		for key, value in props do
			instance[key] = value
		end
		return nil
	end
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(
			duration / math.max(Util.Speed, 0.01),
			style or Util.Motion.Emphasized,
			direction or Enum.EasingDirection.Out
		),
		props
	)
	tween:Play()
	return tween
end

--// Input helpers \\--
function Util.IsPointer(input)
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

-- Returns a position in the same space as GuiObject.AbsolutePosition (ScreenGui with IgnoreGuiInset).
function Util.PointerPosition(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local inset = GuiService:GetGuiInset()
		return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
	end
	return UserInputService:GetMouseLocation()
end

--// Math / color \\--
function Util.Clamp(value, minimum, maximum)
	return math.clamp(value, minimum, maximum)
end

function Util.Round(value, step)
	if not step or step <= 0 then
		return value
	end
	return math.floor(value / step + 0.5) * step
end

function Util.FormatNumber(value, decimals)
	decimals = decimals or 0
	if decimals <= 0 then
		return tostring(math.floor(value + 0.5))
	end
	local text = string.format("%." .. decimals .. "f", value)
	return text
end

function Util.ToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

function Util.FromHex(text)
	if typeof(text) ~= "string" then
		return nil
	end
	local hex = text:gsub("^#", "")
	if #hex == 3 then
		hex = hex:gsub(".", "%0%0")
	end
	if #hex ~= 6 or hex:find("%X") then
		return nil
	end
	return Color3.fromRGB(
		tonumber(hex:sub(1, 2), 16) :: number,
		tonumber(hex:sub(3, 4), 16) :: number,
		tonumber(hex:sub(5, 6), 16) :: number
	)
end

function Util.DeepCopy(value)
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[key] = Util.DeepCopy(inner)
	end
	return copy
end

function Util.Merge(base, overrides)
	local result = Util.DeepCopy(base)
	if overrides then
		for key, value in overrides do
			if typeof(value) == "table" and typeof(result[key]) == "table" and getmetatable(value) == nil then
				result[key] = Util.Merge(result[key], value)
			else
				result[key] = value
			end
		end
	end
	return result
end

-- Fills missing keys of `target` from `defaults` (one level deep for nested plain tables).
function Util.WithDefaults(target, defaults)
	target = target or {}
	for key, value in defaults do
		if target[key] == nil then
			target[key] = Util.DeepCopy(value)
		elseif typeof(value) == "table" and typeof(target[key]) == "table" and getmetatable(value) == nil then
			Util.WithDefaults(target[key], value)
		end
	end
	return target
end

return Util
