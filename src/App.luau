-- Main tab. Features owns gameplay state, cleanup and native shop integration.
local LoadTime = tick()

Library.CreateLoader("NEOPERRO", Vector2.new(300, 300))
local Window = Library.Window("NEOPERRO | THE FINAL STAND 2", Vector2.new(500, 620))
local Main = Window:Tab("MAIN")

local GunMods = Main:Section("GUN MODS", "Left")
GunMods:Toggle({Title = "RAPID FIRE", Flag = "GunRapidFire"})
GunMods:Slider({Title = "FIRE RATE (SHOTS/S)", Flag = "GunFireRate", Symbol = "", Default = 60, Min = 1, Max = 120, Decimals = 1})
GunMods:Toggle({Title = "NO SPREAD", Flag = "GunNoSpread"})
GunMods:Toggle({Title = "NO RECOIL", Flag = "GunNoRecoil"})

local Farm = Main:Section("AUTOFARM", "Left")
Farm:Toggle({Title = "AUTO SHOOT", Flag = "FarmAutoShoot"})
Farm:Toggle({Title = "SMART BURSTS", Flag = "FarmSmartBursts", State = true})
Farm:Toggle({Title = "AUTO RETREAT", Flag = "FarmKeepDistance"})
Farm:Slider({Title = "SAFE DISTANCE (STUDS)", Flag = "FarmDistance", Symbol = "", Default = 24, Min = 5, Max = 100, Decimals = 1})
Farm:Toggle({Title = "SHOW DISTANCE CIRCLE", Flag = "FarmShowCircle"})
Farm:Toggle({Title = "AUTO SPRINT", Flag = "FarmUseSprint", State = true})
Farm:Toggle({Title = "AUTO REFILL AMMO", Flag = "FarmAutoRefill"})
Farm:Slider({Title = "REFILL BELOW (%)", Flag = "FarmRefillThreshold", Symbol = "%", Default = 30, Min = 5, Max = 80, Decimals = 1})
Farm:Toggle({Title = "TOP UP BETWEEN WAVES", Flag = "FarmTopUp", State = true})
Farm:Toggle({Title = "RESTOCK AMMO BOX", Flag = "FarmRestockBox"})
Farm:Slider({Title = "RESTOCK BELOW (%)", Flag = "FarmRestockThreshold", Symbol = "%", Default = 20, Min = 5, Max = 50, Decimals = 1})

local Upgrade = Main:Section("AUTO UPGRADE", "Right")
Upgrade:Toggle({Title = "AUTO UPGRADE", Flag = "UpgradeEnabled"})
local Priority, UpgradeMode
local function RefreshUpgradeControls(Weapon)
    if Priority then Priority:SetVisible(Weapon ~= "Select weapon") end
    if UpgradeMode then UpgradeMode:SetVisible(Weapon ~= "Select weapon") end

end
Upgrade:Dropdown({Title = "WEAPON", Flag = "UpgradeWeapon", List = {"Select weapon"}, Default = "Select weapon", Callback = RefreshUpgradeControls})
Priority = Upgrade:Dropdown({Title = "PRIORITIZE UPGRADE", Flag = "UpgradePriority", List = {"Select upgrade"}, Default = "Select upgrade"})
UpgradeMode = Upgrade:Dropdown({Title = "UPGRADE MODE", Flag = "UpgradeMode", List = {"Selected upgrade only", "All upgrades"}, Default = "Selected upgrade only"})
Upgrade:Toggle({Title = "GO TO SHOP IF NEEDED", Flag = "UpgradeShopFallback", State = true})
Upgrade:Toggle({Title = "NOTIFY WHEN COMPLETE", Flag = "UpgradeNotify", State = true})
Upgrade:Slider({Title = "KEEP CASH FOR SUPPLIES", Flag = "FarmCashReserve", Symbol = "", Default = 0, Min = 0, Max = 5000, Decimals = 50})
RefreshUpgradeControls(Library.Flags.UpgradeWeapon)

local Camera = Main:Section("THIRD PERSON", "Right")
Camera:Toggle({Title = "THIRD PERSON", Flag = "CameraThirdPerson"})
Camera:Slider({Title = "CAMERA DISTANCE", Flag = "CameraDistance", Symbol = "", Default = 10, Min = 4, Max = 24, Decimals = 1})

local Control = Main:Section("CONTROL", "Right")
Control:Button({Title = "START FARMING", Callback = function() if Library.Automation then Library.Automation:StartFarm() end end})
Control:Button({Title = "STOP AUTOMATION", Callback = function() if Library.Automation then Library.Automation:StopAutomation() end end})
Control:Toggle({Title = "AUTO START ROUND", Flag = "FarmAutoReady"})

local Visuals = Window:Tab("VISUALS")
local Impact = Visuals:Section("SHOT EFFECTS", "Left")
Impact:Toggle({Title = "BULLET TRACERS", Flag = "VisualTracers", State = true})
Impact:Slider({Title = "TRACER LIFETIME", Flag = "VisualTracerTime", Symbol = "s", Default = 0.25, Min = 0.1, Max = 0.8, Decimals = 0.01})
Impact:Toggle({Title = "HIT CHAMS", Flag = "VisualHitChams", State = true})
Impact:Toggle({Title = "HIT INDICATOR", Flag = "VisualHitIndicator", State = true})
Impact:Slider({Title = "HIT FLASH DURATION", Flag = "VisualHitTime", Symbol = "s", Default = 0.3, Min = 0.1, Max = 0.8, Decimals = 0.01})
-- Keep the existing interface controls and profiles available.
local Settings = Window:Tab("SETTINGS")
local Menu = Settings:Section("INTERFACE", "Left")
Library.MenuKeyButton = Menu:Button({Title = "SHOW / HIDE UI: RIGHTSHIFT", Callback = function()
    Library:BeginMenuKeyCapture()
end})
Menu:Button({Title = "RESET UI BIND TO RIGHTSHIFT", Callback = function()
    Library.CapturingMenuKey = false
    Library:SetMenuKey(Enum.KeyCode.RightShift)
end})
Menu:Toggle({Title = "SHOW KEYBIND LIST", Flag = "ShowBinds", State = false, Callback = function(Value) Library:SetBindListVisible(Value) end})
Menu:Button({Title = "HIDE UI", Callback = function() Library:ChangeVisible(false) end})

local Profile = Settings:Section("PROFILES", "Right")
Library.SaveButton = Profile:Button({Title = "SAVE PROFILE", Callback = function()
    local OK, Error = pcall(Library.Utility.SaveConfig, "default")
    Window.SendNotification(OK and "Normal" or "Warning", OK and "Profile saved" or tostring(Error), 3)
end})
Library.LoadButton = Profile:Button({Title = "LOAD PROFILE", Callback = function()
    local OK, Error = pcall(Library.Utility.LoadConfig, "default")
    Window.SendNotification(OK and "Normal" or "Warning", OK and "Profile loaded" or tostring(Error), 3)
end})
Profile:Button({Title = "UNLOAD UI", Callback = Library.SelfDestruct})

Window:SwitchTab(Main)
Library.WindowInstance = Window
Library.Features = CreateFeatures(Library, Window)
Library.Automation = CreateAutomation(Library, Window, Library.Features, CreateShopAdapter, CreateNavigation, CreateAmmoAdapter)
Library.Visuals = CreateVisuals(Library, Window)
Library:SetMenuMouseCapture(true)
Library.LoadTime = math.floor((tick() - LoadTime) * 1000)
Window.SendNotification("Normal", "neoperro loaded | RightShift to toggle", 3)
return Library
