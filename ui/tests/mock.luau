--!nocheck
-- Minimal Roblox mock so the bundled library can be smoke-tested under plain `luau` (no Roblox needed).
-- Intentionally forgiving: unknown properties are stored, unknown methods are no-ops.
local M = {}

local V2 = {}
V2.__index = { __t = "Vector2", Magnitude = 0 }
V2.__add = function(a, b) return M.Vector2.new(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return M.Vector2.new(a.X - b.X, a.Y - b.Y) end
V2.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	if type(b) == "number" then return M.Vector2.new(a.X * b, a.Y * b) end
	return M.Vector2.new(a.X * b.X, a.Y * b.Y)
end
V2.__div = function(a, b)
	if type(b) == "number" then return M.Vector2.new(a.X / b, a.Y / b) end
	return M.Vector2.new(a.X / b.X, a.Y / b.Y)
end
V2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
M.Vector2 = { new = function(x, y) return setmetatable({ X = x or 0, Y = y or 0 }, V2) end }
M.Vector2.zero = M.Vector2.new(0, 0)

local C3 = {}
C3.__index = C3
function C3:Lerp(o, a) return M.Color3.new(self.R + (o.R - self.R) * a, self.G + (o.G - self.G) * a, self.B + (o.B - self.B) * a) end
function C3:ToHSV()
	local r, g, b = self.R, self.G, self.B
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local d = max - min
	local h = 0
	if d > 0 then
		if max == r then h = ((g - b) / d) % 6 elseif max == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
		h = h / 6
	end
	return h, max == 0 and 0 or d / max, max
end
M.Color3 = {
	new = function(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0, __t = "Color3" }, C3) end,
	fromRGB = function(r, g, b) return M.Color3.new(r / 255, g / 255, b / 255) end,
	fromHex = function(h)
		h = h:gsub("^#", "")
		return M.Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
	end,
	fromHSV = function(h, s, v)
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		i = i % 6
		local r, g, b
		if i == 0 then r, g, b = v, t, p elseif i == 1 then r, g, b = q, v, p elseif i == 2 then r, g, b = p, v, t
		elseif i == 3 then r, g, b = p, q, v elseif i == 4 then r, g, b = t, p, v else r, g, b = v, p, q end
		return M.Color3.new(r, g, b)
	end,
}

M.UDim = { new = function(s, o) return { Scale = s, Offset = o, __t = "UDim" } end }
M.UDim2 = {
	new = function(xs, xo, ys, yo) return { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 }, __t = "UDim2" } end,
	fromOffset = function(x, y) return M.UDim2.new(0, x, 0, y) end,
	fromScale = function(x, y) return M.UDim2.new(x, 0, y, 0) end,
}
M.ColorSequence = { new = function(...) return { __t = "ColorSequence", ... } end }
M.ColorSequenceKeypoint = { new = function(t, c) return { Time = t, Value = c } end }
M.NumberSequence = { new = function(...) return { __t = "NumberSequence", ... } end }
M.TweenInfo = { new = function(...) return { __t = "TweenInfo", ... } end }

local enumCache = {}
local function enumItem(enumName, name)
	enumCache[enumName] = enumCache[enumName] or {}
	if not enumCache[enumName][name] then enumCache[enumName][name] = { Name = name, EnumType = enumName, __t = "EnumItem" } end
	return enumCache[enumName][name]
end
M.Enum = setmetatable({}, { __index = function(_, enumName) return setmetatable({}, { __index = function(_, name) return enumItem(enumName, name) end }) end })
M.Font = {
	new = function(family, weight, style) return { Family = family, Weight = weight, Style = style, __t = "Font" } end,
	fromEnum = function(e) return { Family = "enum:" .. tostring(e.Name), __t = "Font" } end,
}

local function signal()
	local s = { _h = {} }
	function s:Connect(fn)
		local entry = { fn = fn }
		table.insert(self._h, entry)
		return { Disconnect = function() for i, e in ipairs(self._h) do if e == entry then table.remove(self._h, i) break end end end }
	end
	function s:Wait() end
	function s:Fire(...) for _, e in ipairs(table.clone(self._h)) do e.fn(...) end end
	return s
end
M.newSignal = signal

local EVENTS = { "InputBegan", "InputEnded", "InputChanged", "MouseEnter", "MouseLeave", "Activated", "Focused", "FocusLost", "Destroying" }
local methods = {}
local instanceMt = {}
instanceMt.__index = function(self, key)
	local props = rawget(self, "_props")
	if props[key] ~= nil then return props[key] end
	if key == "ClassName" then return rawget(self, "_class") end
	if key == "Parent" then return rawget(self, "_parent") end
	if key == "Name" then return rawget(self, "_class") end
	if methods[key] then return methods[key] end
	local events = rawget(self, "_events")
	if events[key] then return events[key] end
	if key == "AbsoluteSize" then return M.Vector2.new(200, 48) end
	if key == "AbsolutePosition" then return M.Vector2.new(0, 0) end
	return nil
end
instanceMt.__newindex = function(self, key, value)
	if key == "Parent" then
		local old = rawget(self, "_parent")
		if old then for i, c in ipairs(old._children) do if c == self then table.remove(old._children, i) break end end end
		rawset(self, "_parent", value)
		if value then table.insert(value._children, self) end
		return
	end
	rawget(self, "_props")[key] = value
	local changed = rawget(self, "_changed")[key]
	if changed then changed:Fire() end
end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
	local out = {}
	local function walk(n) for _, c in ipairs(n._children) do table.insert(out, c) walk(c) end end
	walk(self)
	return out
end
function methods:FindFirstChildOfClass(cls) for _, c in ipairs(self._children) do if c._class == cls then return c end end end
function methods:FindFirstChild(name) for _, c in ipairs(self._children) do if c.Name == name then return c end end end
function methods:IsA(cls) return self._class == cls end
function methods:Destroy()
	if rawget(self, "_destroyed") then return end
	rawset(self, "_destroyed", true)
	self._events.Destroying:Fire()
	for _, c in ipairs(table.clone(self._children)) do c:Destroy() end
	self.Parent = nil
end
function methods:GetPropertyChangedSignal(prop)
	local changed = self._changed
	changed[prop] = changed[prop] or signal()
	return changed[prop]
end
M.Instance = {
	new = function(className)
		local obj = setmetatable({ _class = className, _props = {}, _children = {}, _events = {}, _changed = {}, _parent = nil }, instanceMt)
		for _, e in ipairs(EVENTS) do obj._events[e] = signal() end
		if className == "TextBox" then obj._props.Text = "" end
		return obj
	end,
}
M.countInstances = function(root)
	local n = 0
	local function walk(x) for _, c in ipairs(x._children) do n = n + 1 walk(c) end end
	walk(root)
	return n
end

local uis = { InputBegan = signal(), InputEnded = signal(), InputChanged = signal() }
function uis:GetMouseLocation() return M.Vector2.new(50, 50) end
function uis:GetFocusedTextBox() return nil end
local player = { DisplayName = "Tester", Name = "tester", UserId = 0 }
local players = { LocalPlayer = player }
function players:GetUserThumbnailAsync() return "rbxthumb://test", true end
function player:FindFirstChildOfClass() return nil end
local coreGui = M.Instance.new("Folder")

local services = {
	TweenService = { Create = function(_, instance, _, props) return { Play = function() for k, v in pairs(props) do instance[k] = v end end, Cancel = function() end } end },
	UserInputService = uis,
	GuiService = { GetGuiInset = function() return M.Vector2.new(0, 36) end },
	HttpService = {
		JSONEncode = function(_, v)
			local function enc(x)
				local t = type(x)
				if t == "table" then
					if #x > 0 then
						local parts = {}
						for _, v2 in ipairs(x) do table.insert(parts, enc(v2)) end
						return "[" .. table.concat(parts, ",") .. "]"
					end
					local keys, parts = {}, {}
					for k in pairs(x) do table.insert(keys, tostring(k)) end
					table.sort(keys)
					for _, k in ipairs(keys) do table.insert(parts, '"' .. k .. '":' .. enc(x[k])) end
					return "{" .. table.concat(parts, ",") .. "}"
				elseif t == "string" then return '"' .. x .. '"'
				else return tostring(x) end
			end
			return enc(v)
		end,
		JSONDecode = function() return M.lastDecoded end,
		GenerateGUID = function() return "12345678-aaaa" end,
	},
	CoreGui = coreGui,
	Players = players,
	RunService = { Heartbeat = signal() },
}
M.services = services
M.CoreGui = coreGui
M.uis = uis

M.task = {
	spawn = function(fn, ...) if type(fn) == "function" then return fn(...) end end,
	defer = function(fn, ...) if type(fn) == "function" then return fn(...) end end,
	delay = function() end,
	wait = function() return 0 end,
}

M.globals = {
	Vector2 = M.Vector2, Color3 = M.Color3, UDim = M.UDim, UDim2 = M.UDim2, ColorSequence = M.ColorSequence,
	ColorSequenceKeypoint = M.ColorSequenceKeypoint, NumberSequence = M.NumberSequence, TweenInfo = M.TweenInfo,
	Enum = M.Enum, Font = M.Font, Instance = M.Instance, task = M.task,
	game = { GetService = function(_, name) return services[name] or { Name = name } end, HttpGet = function() error("offline") end },
	typeof = function(v)
		local t = type(v)
		if t == "table" then
			local tag = rawget(v, "__t")
			if tag then return tag end
			if getmetatable(v) == V2 then return "Vector2" end
			if rawget(v, "_class") then return "Instance" end
		end
		return t
	end,
	warn = function(...) print("[warn]", ...) end,
}
return M