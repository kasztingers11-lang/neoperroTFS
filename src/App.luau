-- Main tab. Features owns gameplay state, cleanup and native shop integration.
local LoadTime = tick()

Library.CreateLoader("neoperro", Vector2.new(300, 300))
local Window = Library.Window("neoperro | the final stand 2", Vector2.new(500, 620))
local Main = Window:Tab("main")

local GunMods = Main:Section("GUN MODS", "Left")
GunMods:Toggle({Title = "rapid fire", Flag = "GunRapidFire"})
GunMods:Slider({Title = "fire rate (shots/s)", Flag = "GunFireRate", Symbol = "", Default = 60, Min = 1, Max = 120, Decimals = 1})
GunMods:Toggle({Title = "no spread", Flag = "GunNoSpread"})
GunMods:Toggle({Title = "no recoil", Flag = "GunNoRecoil"})

local Farm = Main:Section("AUTOFARM", "Left")
Farm:Toggle({Title = "auto shoot (head)", Flag = "FarmAutoShoot"})
Farm:Toggle({Title = "auto retreat", Flag = "FarmKeepDistance"})
Farm:Slider({Title = "safe distance (studs)", Flag = "FarmDistance", Symbol = "", Default = 24, Min = 5, Max = 100, Decimals = 1})
Farm:Toggle({Title = "show distance", Flag = "FarmShowDistance"})
Farm:Toggle({Title = "show distance circle", Flag = "FarmShowCircle"})
Farm:Toggle({Title = "sprint when retreating", Flag = "FarmUseSprint", State = true})
Farm:Toggle({Title = "auto refill ammo", Flag = "FarmAutoRefill"})
Farm:Slider({Title = "refill below (%)", Flag = "FarmRefillThreshold", Symbol = "%", Default = 30, Min = 5, Max = 80, Decimals = 1})
Farm:Toggle({Title = "top up between waves", Flag = "FarmTopUp", State = true})
Farm:Toggle({Title = "auto restock ammo box", Flag = "FarmRestockBox"})
Farm:Slider({Title = "restock below (%)", Flag = "FarmRestockThreshold", Symbol = "%", Default = 20, Min = 5, Max = 50, Decimals = 1})
Library.FarmStatus = Farm:Label("Head lock uses native weapon range")
Library.MoveStatus = Farm:Label("Retreat respects walls and ground")
Library.AmmoStatus = Farm:Label("Auto refill uses nearby stocked boxes")
Library.RestockStatus = Farm:Label("Restock uses native shop cash")

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
Upgrade:Dropdown({Title = "weapon", Flag = "UpgradeWeapon", List = {"Select weapon"}, Default = "Select weapon", Callback = RefreshUpgradeControls})
Priority = Upgrade:Dropdown({Title = "prioritize upgrade", Flag = "UpgradePriority", List = {"Select upgrade"}, Default = "Select upgrade"})
UpgradeMode = Upgrade:Dropdown({Title = "upgrade mode", Flag = "UpgradeMode", List = {"Selected upgrade only", "All upgrades"}, Default = "Selected upgrade only"})
Upgrade:Toggle({Title = "go to shop if needed", Flag = "UpgradeShopFallback", State = true})
Upgrade:Toggle({Title = "notify when complete", Flag = "UpgradeNotify", State = true})
UpgradeHint = Upgrade:Label("Select a weapon to set priorities.")
Library.UpgradeStatus = Upgrade:Label("Scanning owned weapons...")
UpgradeMode.Callback = function(Mode)
    UpgradeHint:Set(Library.Flags.UpgradeWeapon == "Select weapon" and "Select a weapon to set priorities." or
        Mode == "All upgrades" and "Priority first, then max the weapon." or "Stop when selected upgrade is maxed.")
end
RefreshUpgradeControls(Library.Flags.UpgradeWeapon)

local Camera = Main:Section("THIRD PERSON", "Right")
Camera:Toggle({Title = "enabled", Flag = "CameraThirdPerson"})
Camera:Slider({Title = "camera distance", Flag = "CameraDistance", Symbol = "", Default = 10, Min = 4, Max = 24, Decimals = 1})

local Control = Main:Section("CONTROL", "Right")
Control:Button({Title = "start farming", Callback = function() if Library.Automation then Library.Automation:StartFarm() end end})
Control:Button({Title = "stop automation", Callback = function() if Library.Automation then Library.Automation:StopAutomation() end end})
Control:Toggle({Title = "run while unfocused", Flag = "FarmBackground"})
Control:Toggle({Title = "auto start round", Flag = "FarmAutoReady"})
Library.RunStatus = Control:Label("READY | automation off")
Library.ReadyStatus = Control:Label("Auto start waits for enabled tasks")

local Visuals = Window:Tab("visuals")
local Impact = Visuals:Section("SHOT EFFECTS", "Left")
Impact:Toggle({Title = "bullet tracers", Flag = "VisualTracers", State = true})
Impact:Slider({Title = "tracer lifetime", Flag = "VisualTracerTime", Symbol = "s", Default = 0.25, Min = 0.1, Max = 0.8, Decimals = 0.01})
Impact:Toggle({Title = "hit chams", Flag = "VisualHitChams", State = true})
Impact:Toggle({Title = "hit indicator", Flag = "VisualHitIndicator", State = true})
Impact:Slider({Title = "hit flash duration", Flag = "VisualHitTime", Symbol = "s", Default = 0.3, Min = 0.1, Max = 0.8, Decimals = 0.01})
Impact:Label("Tracers and chams follow shot contact")
Impact:Label("Hit marker follows server feedback")
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
Library.Features = CreateFeatures(Library, Window)
Library.Automation = CreateAutomation(Library, Window, Library.Features, CreateShopAdapter, CreateNavigation, CreateAmmoAdapter)
Library.Visuals = CreateVisuals(Library, Window)
Library:SetMenuMouseCapture(true)
Library.LoadTime = math.floor((tick() - LoadTime) * 1000)
Window.SendNotification("Normal", "neoperro loaded | RightShift to toggle", 3)
return Library
