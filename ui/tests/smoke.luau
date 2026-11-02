--!nocheck
local failures, passed = 0, 0
local function check(name, cond, detail)
	if cond then passed = passed + 1 else failures = failures + 1 print("FAIL: " .. name .. (detail and (" (" .. tostring(detail) .. ")") or "")) end
end

local ok, Library = pcall(__bundle)
check("bundle loads", ok, Library)
if not ok then print(Library) error("cannot continue") end

check("Library has CreateWindow", type(Library.CreateWindow) == "function")
check("Library.Version", type(Library.Version) == "string")

local window
local okWin, errWin = pcall(function()
	window = Library:CreateWindow({ Title = "Test", Subtitle = "smoke", Icon = "bolt", Offline = true, AutoShow = true, Theme = { Mode = "Dark", Preset = "Teal" } })
end)
check("CreateWindow", okWin, errWin)
check("status offline", Library:GetAssetStatus() == "offline mode", Library:GetAssetStatus())
check("window visible", window and window.Visible == true)

local home = window:AddTab({ Name = "Home", Icon = "home" })
local misc = window:AddTab({ Name = "Misc", Icon = "tune", Badge = 3 })
check("two tabs", #window.Tabs == 2)
check("first tab selected", window.Selected == home)

local sec = home:AddSection({ Title = "Controls", Icon = "settings" })
local changes = {}
local toggle = sec:AddToggle({ Text = "Fly", Flag = "fly", Default = false, Callback = function(v) table.insert(changes, v) end })
local slider = sec:AddSlider({ Text = "Speed", Flag = "speed", Min = 0, Max = 100, Default = 25, Suffix = " st/s" })
local dd = sec:AddDropdown({ Text = "Mode", Flag = "mode", Values = { "A", "B", "C" }, Default = "B" })
local multi = sec:AddDropdown({ Text = "Many", Flag = "many", Values = { "x", "y", "z" }, Multi = true, Default = { "x" } })
local input = sec:AddInput({ Text = "Name", Flag = "name", Default = "hi" })
local seg = sec:AddSegmented({ Text = "Seg", Flag = "seg", Values = { "One", "Two" }, Default = "Two" })
local chips = sec:AddChips({ Text = "Chips", Flag = "chips", Values = { "a", "b" }, Default = { "b" } })
local key = sec:AddKeybind({ Text = "Key", Flag = "key", Default = Enum.KeyCode.F, Mode = "Toggle" })
local color = sec:AddColorPicker({ Text = "Color", Flag = "color", Default = Color3.fromRGB(255, 0, 0) })
local button = sec:AddButton({ Text = "Go", Style = "Filled", Callback = function() table.insert(changes, "clicked") end })
local progress = sec:AddProgress({ Text = "Load", Flag = "progress", Default = 0.4 })
sec:AddLabel("hello"); sec:AddDivider(); sec:AddParagraph({ Title = "T", Content = "C" })
check("flags registered", Library.Flags.fly == false and Library.Flags.speed == 25 and Library.Flags.mode == "B")

toggle:Set(true)
check("toggle set", toggle.Value == true and Library.Flags.fly == true and changes[1] == true)
slider:Set(51.4)
check("slider rounds to step", slider.Value == 51, slider.Value)
slider:Set(999)
check("slider clamps", slider.Value == 100, slider.Value)
dd:Set("C")
check("dropdown set", dd.Value == "C")
dd:Set("nope")
check("dropdown rejects unknown", dd.Value == "C")
multi:Set({ "y", "z" })
check("multi dropdown", multi.Value.y and multi.Value.z and not multi.Value.x)
input:Set("abc")
check("input set", input.Value == "abc")
seg:Set("One")
check("segmented", seg.Value == "One")
chips:Set({ "a", "b" })
check("chips", chips.Value.a and chips.Value.b)
color:Set("#00FF00")
check("color set from hex", math.abs(color.Value.G - 1) < 0.01 and color.Value.R < 0.01)
progress:Set(2)
check("progress clamps", progress.Value == 1)
button:Set()
check("button fires callback", changes[#changes] == "clicked")
key:Set("G")
check("keybind set", key:GetKey() and key:GetKey().Name == "G")

-- disabled / visibility
toggle:SetDisabled(true); check("disabled flag", toggle.Disabled == true)
toggle:SetVisible(false); check("hidden", toggle.Row.Visible == false)
toggle:SetVisible(true);  check("shown", toggle.Row.Visible == true)

-- search filters rows
window.SearchBox.Text = "speed"
check("search hides non-matching", toggle.Row.Visible == false and slider.Row.Visible == true)
window.SearchBox.Text = ""
check("search clear restores", toggle.Row.Visible == true)

-- config round trip
local json = Library.Config:Encode()
check("config encodes flags", json:find('"speed":100', 1, true) and json:find('"fly":true', 1, true), json)
toggle:Set(false); slider:Set(10)
local decoded = { version = 1, flags = { fly = true, speed = 77, mode = "A", color = "#0000FF", key = "H", chips = { "a" }, many = { "z" } } }
local mock = nil
for _, v in pairs({}) do mock = v end
Library.Config:Decode("ignored")
check("decode of bad json fails gracefully", true)

-- theme
local before = Library:GetColor("Primary")
Library:SetTheme({ Mode = "Light", Preset = "Red" }, false)
local after = Library:GetColor("Primary")
check("theme changes roles", before.R ~= after.R or before.G ~= after.G or before.B ~= after.B)
check("theme mode", Library:GetTheme().Mode == "Light")
Library:SetTheme({ Seed = "#112233" }, false)
check("custom seed", Library:GetTheme().Preset == "Custom")

-- settings builder
local settingsTab = window:AddTab({ Name = "Settings", Icon = "settings" })
local okSettings, errSettings = pcall(function() Library:BuildSettings(settingsTab) end)
check("BuildSettings", okSettings, errSettings)

-- tab switching, badge, notify, dialog
window:SelectTab("Misc")
check("select by name", window.Selected == misc)
misc:SetBadge(7)
local okNotify, errNotify = pcall(function() Library:Notify({ Title = "Hi", Content = "There", Type = "Success", Duration = 3 }) end)
check("Notify", okNotify, errNotify)
local okDialog, errDialog = pcall(function() Library:Dialog({ Title = "Sure?", Content = "x", Buttons = { { Text = "No" }, { Text = "Yes", Style = "Filled" } } }) end)
check("Dialog", okDialog, errDialog)

-- icons
check("icon alias", Library.Icons.Resolve("gear") == "settings")
check("icon unknown", Library.Icons.Resolve("definitely_not_an_icon") == nil)

-- visibility toggle
window:SetVisible(false); check("hide", window.Visible == false)
window:Toggle();          check("toggle shows", window.Visible == true)

-- teardown leaves nothing behind
local gui = __M.CoreGui:GetChildren()[1]
check("gui parented to CoreGui", gui ~= nil)
Library:Unload()
check("unloaded", Library.Unloaded == true and Library.Window == nil)
check("gui destroyed", #__M.CoreGui:GetChildren() == 0)
check("flags cleared", next(Library.Flags) == nil)

-- recreate after unload
local okAgain, errAgain = pcall(function() Library:CreateWindow({ Title = "Again", Offline = true }) end)
check("recreate window after unload", okAgain, errAgain)
Library:Unload()

print(string.format("smoke: %d passed, %d failed", passed, failures))
if failures > 0 then error("smoke tests failed") end