local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/MidasRX/Zaridium/main/ui/dist/ZaridiumUI.lua"))()

local Window = Library:CreateWindow({ Title = "My Hub", Icon = "bolt" })
local Tab = Window:AddTab({ Name = "Main", Icon = "home" })
local Section = Tab:AddSection({ Title = "Hello" })

Section:AddToggle({ Text = "Enabled", Flag = "enabled", Default = true, Callback = function(value) print(value) end })
Section:AddButton({ Text = "Click me", Style = "Filled", Callback = function() Library:Notify({ Content = "Clicked!" }) end })