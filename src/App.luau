-- Main-tab design preview. Controls store UI state only.
-- Weapon and upgrade names below are preview choices, pending inventory/shop integration.
local LoadTime = tick()

Library.CreateLoader("neoperro", Vector2.new(300, 300))
local Window = Library.Window("neoperro | the final stand 2", Vector2.new(500, 620))
local Main = Window:Tab("main")

local GunMods = Main:Section("GUN MODS", "Left")
GunMods:Toggle({Title = "wallbang", Flag = "GunWallbang"})
GunMods:Toggle({Title = "rapid fire", Flag = "GunRapidFire"})
GunMods:Toggle({Title = "infinite ammo", Flag = "GunInfiniteAmmo"})
GunMods:Toggle({Title = "instant reload", Flag = "GunInstantReload"})
GunMods:Toggle({Title = "infinite range", Flag = "GunInfiniteRange"})

local Farm = Main:Section("AUTOFARM", "Left")
Farm:Toggle({Title = "auto shoot zombies", Flag = "FarmAutoShoot"})
Farm:Toggle({Title = "distance checker", Flag = "FarmKeepDistance"})
Farm:Slider({Title = "keep distance (studs)", Flag = "FarmDistance", Symbol = "", Default = 24, Min = 5, Max = 100, Decimals = 1})
Farm:Toggle({Title = "show distance", Flag = "FarmShowDistance"})
Farm:Toggle({Title = "show distance circle", Flag = "FarmShowCircle"})
Farm:Toggle({Title = "avoid walls", Flag = "FarmAvoidWalls", State = true})
Farm:Toggle({Title = "use sprint (Shift)", Flag = "FarmUseSprint", State = true})

local Upgrade = Main:Section("AUTO UPGRADE", "Right")
Upgrade:Toggle({Title = "enabled", Flag = "UpgradeEnabled"})
local Priority, UpgradeMode, UpgradeHint
local function RefreshUpgradeControls(Weapon)
    if Priority then Priority:SetVisible(Weapon ~= "Select weapon") end
    if UpgradeMode then UpgradeMode:SetVisible(Weapon ~= "Select weapon") end
    if UpgradeHint then
        UpgradeHint:Set(Weapon == "Select weapon" and "Select a weapon to set priorities." or
            Library.Flags.UpgradeMode == "All upgrades" and "Priority first, then max the weapon." or
            "Stop when selected upgrade is maxed.")
    end
end
Upgrade:Dropdown({Title = "weapon", Flag = "UpgradeWeapon", List = {"Select weapon", "Pistol"}, Default = "Pistol", Callback = RefreshUpgradeControls})
Priority = Upgrade:Dropdown({Title = "prioritize upgrade", Flag = "UpgradePriority", List = {"Damage", "Fire rate", "Reload speed", "Magazine size", "Range"}, Default = "Damage"})
UpgradeMode = Upgrade:Dropdown({Title = "upgrade mode", Flag = "UpgradeMode", List = {"Selected upgrade only", "All upgrades"}, Default = "Selected upgrade only"})
Upgrade:Toggle({Title = "go to shop if needed", Flag = "UpgradeShopFallback", State = true})
Upgrade:Toggle({Title = "completion notifications", Flag = "UpgradeNotify", State = true})
UpgradeHint = Upgrade:Label("Stop when selected upgrade is maxed.")
UpgradeMode.Callback = function(Mode)
    -- The inherited dropdown calls its callback before updating Library.Flags.
    UpgradeHint:Set(Library.Flags.UpgradeWeapon == "Select weapon" and "Select a weapon to set priorities." or
        Mode == "All upgrades" and "Priority first, then max the weapon." or "Stop when selected upgrade is maxed.")
end

local Camera = Main:Section("THIRD PERSON", "Right")
Camera:Toggle({Title = "enabled", Flag = "CameraThirdPerson"})
Camera:Slider({Title = "camera distance (studs)", Flag = "CameraDistance", Symbol = "", Default = 10, Min = 4, Max = 24, Decimals = 1})

-- Keep the existing interface controls and profiles available.
local Settings = Window:Tab("settings")
local Menu = Settings:Section("interface", "Left")
Library.MenuKeyButton = Menu:Button({Title = "show / hide UI: RightShift", Callback = function()
    Library:BeginMenuKeyCapture()
end})
Menu:Button({Title = "reset UI bind to RightShift", Callback = function()
    Library.CapturingMenuKey = false
    Library:SetMenuKey(Enum.KeyCode.RightShift)
end})
Menu:Toggle({Title = "show keybind list", Flag = "ShowBinds", State = false, Callback = function(Value) Library:SetBindListVisible(Value) end})
Menu:Button({Title = "hide UI (use your bind to reopen)", Callback = function() Library:ChangeVisible(false) end})

local Profile = Settings:Section("profiles", "Right")
Library.SaveButton = Profile:Button({Title = "save profile", Callback = function()
    local OK, Error = pcall(Library.Utility.SaveConfig, "default")
    Window.SendNotification(OK and "Normal" or "Warning", OK and "Profile saved" or tostring(Error), 3)
end})
Library.LoadButton = Profile:Button({Title = "load profile", Callback = function()
    local OK, Error = pcall(Library.Utility.LoadConfig, "default")
    Window.SendNotification(OK and "Normal" or "Warning", OK and "Profile loaded" or tostring(Error), 3)
end})
Profile:Button({Title = "unload UI", Callback = Library.SelfDestruct})

Window:SwitchTab(Main)
Library.WindowInstance = Window
Library.LoadTime = math.floor((tick() - LoadTime) * 1000)
Window.SendNotification("Normal", "Main tab preview loaded | RightShift to toggle", 3)
return Library
