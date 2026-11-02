--[[
	Zaridium UI: full-featured example.
	Run it in an executor with loadstring + HttpGet, or paste dist/ZaridiumUI.lua first.
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/MidasRX/Zaridium/main/ui/dist/ZaridiumUI.lua"))()

local Window = Library:CreateWindow({
	Title = "Zaridium",
	Subtitle = "Material 3 edition",
	Icon = "bolt",                 -- Material Symbols name, or an rbxassetid number
	Theme = { Mode = "Dark", Preset = "Violet" },
	ToggleKey = Enum.KeyCode.RightControl,
	Size = Vector2.new(780, 560),
	Profile = {},                  -- {} = use the local player; false hides the card
})

--// Tabs \\--
local Main = Window:AddTab({ Name = "Main", Icon = "home" })
local Player = Window:AddTab({ Name = "Player", Icon = "person" })
local Visuals = Window:AddTab({ Name = "Visuals", Icon = "visibility", Badge = "new" })
local Settings = Window:AddTab({ Name = "Settings", Icon = "settings" })

--// Main \\--
local Welcome = Main:AddSection({ Title = "Welcome", Icon = "star" })
Welcome:AddParagraph({
	Title = "Zaridium UI",
	Content = "Material 3 interface with Google Sans Flex, ripples, tonal surfaces and a theme generator.",
})
Welcome:AddButton({
	Text = "Show a notification",
	Icon = "notifications",
	Style = "Filled",
	Callback = function()
		Library:Notify({ Title = "Hello!", Content = "Notifications stack and auto-dismiss.", Type = "Success" })
	end,
})
Welcome:AddButton({
	Text = "Open a dialog",
	Icon = "help",
	Style = "Tonal",
	Callback = function()
		Library:Dialog({
			Title = "Reset everything?",
			Content = "All options go back to their defaults.",
			Icon = "refresh",
			Buttons = {
				{ Text = "Cancel", Style = "Text" },
				{ Text = "Reset", Style = "Danger", Callback = function() Library:Notify({ Content = "Reset!", Type = "Warning" }) end },
			},
		})
	end,
})

--// Player \\--
local Movement = Player:AddSection({ Title = "Movement", Icon = "speed" })
Movement:AddToggle({
	Text = "Fly",
	Description = "Free flight; use WASD, Space and Shift.",
	Icon = "flight",
	Flag = "fly",
	Default = false,
	Callback = function(enabled)
		print("fly:", enabled)
	end,
})
Movement:AddSlider({ Text = "Walk speed", Flag = "walkspeed", Min = 16, Max = 200, Default = 16, Suffix = " st/s", Icon = "speed",
	Callback = function(value)
		local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = value end
	end })
Movement:AddSlider({ Text = "Gravity", Flag = "gravity", Min = 0, Max = 3, Step = 0.05, Default = 1, Format = function(v) return string.format("%.2fx", v) end })
Movement:AddKeybind({ Text = "Fly toggle key", Flag = "flykey", Default = Enum.KeyCode.F, Mode = "Toggle", Icon = "keyboard" })

local Targeting = Player:AddSection({ Title = "Targeting", Icon = "my_location" })
Targeting:AddDropdown({ Text = "Priority", Flag = "priority", Values = { "Closest", "Lowest health", "Random" }, Default = "Closest" })
Targeting:AddDropdown({ Text = "Teams", Flag = "teams", Values = { "Red", "Blue", "Green" }, Multi = true, Default = { "Red" } })
Targeting:AddSegmented({ Text = "Aim part", Flag = "aimpart", Values = { "Head", "Torso", "Legs" }, Default = "Head" })
Targeting:AddChips({ Text = "Ignore", Flag = "ignore", Values = { "Friends", "Dead", "Invisible", "Teammates" }, Default = { "Friends" } })

--// Visuals \\--
local Colors = Visuals:AddSection({ Title = "Colors", Icon = "palette" })
Colors:AddColorPicker({ Text = "Highlight", Flag = "highlight", Default = Color3.fromRGB(255, 80, 80) })
Colors:AddInput({ Text = "Label text", Flag = "label", Default = "Target", Placeholder = "Shown above players" })
Colors:AddInput({ Text = "Max distance", Flag = "distance", Default = "500", Numeric = true, Min = 10, Max = 5000 })
Colors:AddProgress({ Text = "Render budget", Flag = "budget", Default = 0.35 })

--// Settings: theme + configs in one call \\--
Library:BuildSettings(Settings)

-- Manual theme control also works:
-- Library:SetTheme({ Mode = "Amoled", Preset = "Teal" })
-- Library:SetTheme({ Seed = Color3.fromRGB(255, 120, 0) })

-- Load the autoload config (if the user set one)
Library.Config:LoadAutoload()

-- React to any flag from anywhere
Library.Options.fly:OnChanged(function(value)
	print("fly is now", value, "| flags table says", Library.Flags.fly)
end)