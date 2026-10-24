-- // Docs

local LoadTime = tick()

Library.CreateLoader("neoperro", Vector2.new(300, 300))
local Window = Library.Window("neoperro | the final stand 2", Vector2.new(500, 620))
Window.Watermark("neoperro | TFS2")

-- // UI Main \\ --
local Legit = Window:Tab("main")
local Aimbot = Legit:Section("legit", "Left")
Aimbot:Toggle({Title = "aimbot", Flag = "Aimlock"}):Keybind({Title = "Aiming", Flag = "Aiming", Key = Enum.UserInputType.MouseButton2, StateType = "Hold"})
Aimbot:Toggle({Title = "visible check", Flag = "AimlockWallCheck"})
Aimbot:Toggle({Title = "apply prediction", Flag = "AdjustBulletDrop"})
Aimbot:Slider({Title = "smoothing [mouse]", Flag = "Smoothness", Symbol = "", Default = 0, Min = 0, Max = 20, Decimals = 1})
Aimbot:Dropdown({Title = "hitbox priority", List = {"Head", "Body"}, Default = "Head", Flag = "AimlockHitbox"})
Aimbot:Dropdown({Title = "mode", List = {"Camera", "Mouse"}, Default = "Camera", Flag = "AimbotMode"})

local BulletRedirection = Legit:Section("bullet redirection", "Left")
BulletRedirection:Toggle({Title = "silent aim", Flag = "SilentAim", Type = "Dangerous"})
BulletRedirection:Toggle({Title = "apply prediction", Flag = "SilentAimBulletDrop"})
BulletRedirection:Toggle({Title = "custom prediction", Flag = "CustomPrediction"})
BulletRedirection:Slider({Title = "value", Flag = "CustomValue", Symbol = "", Default = 75, Min = 0, Max = 99, Decimals = 1})
BulletRedirection:Toggle({Title = "visible check", Flag = "SilentAimWallCheck"})
BulletRedirection:Slider({Title = "randomization", Flag = "Randomization", Symbol = "%", Default = 0, Min = 0, Max = 100, Decimals = 1})
BulletRedirection:Dropdown({Title = "hitbox priority", Flag = "SilentAimHitbox", List = {"Head", "Body"}, Default = "Head"})

local TriggerBot = Legit:Section("trigger bot", "Left")
TriggerBot:Toggle({Title = "enabled", Flag = "TriggerBot"}):Keybind({Title = "Trigger Bot", Flag = "TriggerBotBind", Key = Enum.KeyCode.M, StateType = "Toggle"})
TriggerBot:Slider({Title = "delay", Flag = "TBDelay", Symbol = "m", Default = 0, Min = 0, Max = 5, Decimals = 1})

local FOV = Legit:Section("drawing field of view", "Right")
FOV:Toggle({Title = "aimbot fov", Flag = "AimlockFOVToggle"}):Colorpicker({Color = Library.Theme.Accent[2], Flag = "AimlockFOVColor"})
FOV:Slider({Title = "size", Flag = "AimlockFOVSize", Symbol = "", Default = 100, Min = 10, Max = 250, Decimals = 1})
FOV:Toggle({Title = "silent aim fov", Flag = "SilentAimFOVToggle"}):Colorpicker({Color = Color3.fromHex("#d4356e"), Flag = "SilentAimFOVColor"})
FOV:Slider({Title = "size", Flag = "SilentAimFOVSize", Symbol = "", Default = 100, Min = 10, Max = 250, Decimals = 1})
FOV:Dropdown({Title = "style", List = {"Outline", "Hot"}, Default = "Outline", Flag = "FOVStyle"})
FOV:Dropdown({Title = "position", List = {"Mouse", "Center"}, Default = "Mouse", Flag = "FOVPosition"})

local Blatant = Window:Tab("rage")
local Movement = Blatant:Section("movement", "Left")
Movement:Toggle({Title = "speed", Flag = "SpeedToggle", Type = "Dangerous"}):Keybind({Title = "Speed", Flag = "SpeedBind", Key = Enum.KeyCode.V, StateType = "Toggle"})
Movement:Slider({Title = "move rate", Flag = "MoveRate", Symbol = "", Default = 24, Min = 1, Max = 32, Decimals = 1})


Movement:Toggle({Title = "bunny hop", Flag = "BunnyHop", Type = "Dangerous"})
Movement:Slider({Title = "hop speed", Flag = "HopSpeed", Symbol = "", Default = 24, Min = 1, Max = 32, Decimals = 1})

Movement:Toggle({Title = "flight", Flag = "Fly", Type = "Dangerous"}):Keybind({Title = "Fly", Flag = "FlyBind", Key = Enum.KeyCode.F, StateType = "Toggle"})
Movement:Slider({Title = "flight speed", Flag = "FlyRate", Symbol = "", Default = 24, Min = 1, Max = 100, Decimals = 1})

local CharacterModify = Blatant:Section("Local", "Left")
CharacterModify:Toggle({Title = "no jump cooldown", Flag = "NoJumpCooldown"})
CharacterModify:Toggle({Title = "anti stomp", Flag = "AntiStomp", Type = "Dangerous"})
CharacterModify:Toggle({Title = "anti bag", Flag = "AntiBag"})


local HvH = Blatant:Section("hack vs hack", "Left")
HvH:Toggle({Title = "target strafe", Flag = "TargetStrafe", Type = "Dangerous"}):Keybind({Title = "Target Strafe", Flag = "TSBind", Key = Enum.KeyCode.Space, StateType = "Toggle"})
HvH:Toggle({Title = "display distance", Flag = "TSVisual"}):Colorpicker({Color = Color3.fromHex("#d4356e"), Flag = "TSVColor"})
HvH:Slider({Title = "distance", Flag = "TSDistance", Symbol = "", Default = 5, Min = 1, Max = 60, Decimals = 1})
HvH:Slider({Title = "strafe speed", Flag = "TSSpeed", Symbol = "", Default = 5, Min = 1, Max = 60, Decimals = 1})

local GunMods = Blatant:Section("gun mod", "Right")
GunMods:Toggle({Title = "no recoil", Flag = "NoRecoil"})


local Settings = Window:Tab("settings")
local Appearance = Settings:Section("appearance", "Left")
Appearance:Colorpicker({Title = "accent", Color = Library.BaseAccent, Flag = "UIAccent", Callback = function(Color)
    Library.BaseAccent = Color
    Library:UpdateTheme({Accent = Color})
end})
Appearance:Dropdown({Title = "color mode", List = {"Static", "Red pulse", "Spectrum"}, Default = "Red pulse", Flag = "UIColorMode", Callback = function(Value)
    Library.AccentMode = Value
end})
local AnimationToggle = Appearance:Toggle({Title = "subtle animations", Flag = "UIAnimations", Callback = function(Value)
    Library.Animations = Value
end})
AnimationToggle:Set(true)
local Profile = Settings:Section("menu", "Right")
Profile:Label("RightShift opens / closes the UI")
Profile:Button({Title = "save appearance / controls", Callback = function() Library.Utility.SaveConfig("default") end})
Profile:Button({Title = "load saved profile", Callback = function()
    local OK, Error = pcall(Library.Utility.LoadConfig, "default")
    Window.SendNotification(OK and "Normal" or "Warning", OK and "Profile loaded" or tostring(Error), 3)
end})
Profile:Button({Title = "unload UI", Callback = Library.SelfDestruct})
Window:SwitchTab(Legit)
Library.WindowInstance = Window
Library.LoadTime = math.floor((tick() - LoadTime) * 1000)
Window.SendNotification("Normal", "neoperro UI loaded | RightShift to toggle", 3)
return Library
