-- Abyss Drawing UI adapted from Eazvy/UILibs/Librarys/Abyss/Example.
local Secure = setmetatable({}, {
    __index = function(Idx, Val)
        return game:GetService(Val)
    end
})
local UserInput = Secure.UserInputService
local RunService = Secure.RunService
local CoreGui = Secure.CoreGui
local Players = Secure.Players
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local HttpService = Secure.HttpService
local Mouse = LocalPlayer:GetMouse()
local OriginalMouseIcon = UserInput.MouseIconEnabled
local InputGUI = Instance.new("ScreenGui")
InputGUI.Name = "neoperroInput"
InputGUI.Parent = gethui and gethui() or CoreGui
local Library = {
    Theme = {
        Accent = {
            Color3.fromHex("#f43045"), -- Color3.fromHex("#a280d9"), -- Color3.fromRGB(255, 42, 10), Color3.fromHex("#3599d4")
            Color3.fromRGB(244, 48, 69),
            Color3.fromRGB(114, 0, 198),
            Color3.fromRGB(139, 130, 185),
            Color3.fromHex("#a83299")
        },
        Notification = {
            Error = Color3.fromHex("#c82828"),
            Warning = Color3.fromHex("#fc9803")
        },
        Hitbox = Color3.fromRGB(69, 69, 69),
        Friend = Color3.fromRGB(0, 200, 0),
        Outline = Color3.fromHex("#000005"),
        Inline = Color3.fromHex("#323232"),
        LightContrast = Color3.fromHex("#202020"),
        DarkContrast = Color3.fromHex("#191919"),
        Text = Color3.fromHex("#e8e8e8"),
        TextInactive = Color3.fromHex("#aaaaaa"),
        Font = Drawing.Fonts.UI,
        TextSize = 13,
        UseOutline = false
    },
    Icons = {},
    Popups = {},
    Flags = {},
    Items = {},
    Drawings = {},
    Ignores = {},
    Keybind = {},
    Watermark = {},
    Connections = {},
    Keys = {
        KeyBoard = {["Q"] = "Q", ["W"] = "W", ["E"] = "E", ["R"] = "R", ["T"] = "T", ["Y"] = "Y", ["U"] = "U", ["I"] = "I", ["O"] = "O", ["P"] = "P", ["A"] = "A", ["S"] = "S", ["D"] = "D", ["F"] = "F", ["G"] = "G", ["H"] = "H", ["J"] = "J", ["K"] = "K", ["L"] = "L", ["Z"] = "Z", ["X"] = "X", ["C"] = "C", ["V"] = "V", ["B"] = "B", ["N"] = "N", ["M"] = "M", ["One"] = {"1", "!"}, ["Two"] = {"2", "\""}, ["Three"] = {"3", "£"}, ["Four"] = {"4", "$"}, ["Five"] = {"5", "%"}, ["Six"] = {"6", "^"}, ["Seven"] = {"7", "&"}, ["Eight"] = {"8", "*"}, ["Nine"] = {"9", "("}, ["Zero"] = {"0", ")"}, ["Space"] = " ", ["Slash"] = {"/", "?"}, ["BackSlash"] = {"\\", "|"}, ["Minus"] = {"-", "_"}, ["Equals"] = {"=", "+"}, ["RightBracket"] = {"]", "}"}, ["LeftBracket"] = {"[", "{"}, ["Semicolon"] = {";", ":"}, ["Quote"] = {"'", "@"}, ["Comma"] = {",", "<"}, ["Period"] = {".", ">"}},
        Letters = {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M"},
        KeyCodes = {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Zero", "Insert", "Tab", "Home", "End", "LeftAlt", "LeftControl", "LeftShift", "RightAlt", "RightControl", "RightShift", "CapsLock"},
        Inputs = {"MouseButton1", "MouseButton2", "MouseButton3"},
        Shortened = {["MouseButton1"] = "M1", ["MouseButton2"] = "M2", ["MouseButton3"] = "M3", ["Insert"] = "INS", ["LeftAlt"] = "LA", ["LeftControl"] = "LC", ["LeftShift"] = "LS", ["RightAlt"] = "RA", ["RightControl"] = "RC", ["RightShift"] = "RS", ["CapsLock"] = "CL"}
    },
    Input = {
        Caplock = false,
        LeftShift = false
    },
    Images = {},
    Destroyed = false,
    WindowVisible = true,
    Communication = Instance.new("BindableEvent")
}
local Utility: any = {}
getgenv().Library = Library
getgenv().Utility = Utility
getgenv().NeoperroTFS = Library
Library.Utility = Utility
Library.Animations = true
Library.AccentMode = "Red pulse"
Library.BaseAccent = Library.Theme.Accent[1]
Library.DrawingInfo = {}
Library.Tweens = {}
Library.NextFlag = 0
do
    Utility.AddInstance = function(NewInstance, Properties)
        local NewInstance = Instance.new(NewInstance)
        for Index, Value in pairs(Properties) do
            NewInstance[Index] = Value
        end
        return NewInstance
    end
    Utility.Loop = function(Delay, Call)
        local Callback = typeof(Call) == "function" and Call or function() end
        task.spawn(function()
            while not Library.Destroyed and task.wait(Delay) do
                local Success, Error = pcall(function()
                    Callback()
                end)
                if Error then 
                    return 
                end
            end
        end)
    end
    Utility.RemoveDrawing = function(Object, Location)
        Location = Location or Library.Drawings
        for Index = #Location, 1, -1 do
            if Location[Index][1] == Object then
                table.remove(Location, Index)
                Library.DrawingInfo[Object] = nil
                Library.Tweens[Object] = nil
                pcall(function() Object:Remove() end)
                break
            end
        end
    end
    Utility.NextFlag = function()
        Library.NextFlag += 1
        return "Control_" .. Library.NextFlag
    end
    Utility.Animate = function(Object, Property, Value, Duration)
        if not Library.Animations then Object[Property] = Value; return end
        local Entries = Library.Tweens[Object] or {}
        Library.Tweens[Object] = Entries
        Entries[Property] = {From = Object[Property], To = Value, Start = os.clock(), Duration = Duration or 0.14}
    end
    Utility.AddConnection = function(Type, Callback)
        local Connection = Type:Connect(function(...)
            if not Library.Destroyed then Callback(...) end
        end)
        Library.Connections[#Library.Connections + 1] = Connection
        return Connection
    end
    Utility.Round = function(Num, Float)
        local Bracket = 1 / Float;
        return math.floor(Num * Bracket) / Bracket;
    end
    Utility.AddDrawing = function(Instance, Properties, Location)
        local InstanceType = Instance
        local Instance = Drawing.new(Instance)
        for Index, Value in pairs(Properties) do
            Instance[Index] = Value
            if InstanceType == "Text" then
                if Index == "Font" then
                    Instance.Font = Library.Theme.Font
                end
                if Index == "Size" then
                    Instance.Size = Library.Theme.TextSize
                end
            end
        end
        if Properties.ZIndex ~= nil then
            Instance.ZIndex = Properties.ZIndex + 20
        else
            Instance.ZIndex = 20
        end
        Location = Location or Library.Drawings
        if InstanceType == "Image" then
            Location[#Location + 1] = {Instance, true}
        else
            Location[#Location + 1] = {Instance}
        end
        Library.DrawingInfo[Instance] = {Type = InstanceType, Alpha = Properties.Transparency or 1}
        return Instance
    end
    Utility.OnMouse = function(Instance): boolean
        local Mouse = UserInput:GetMouseLocation()
        if Instance.Visible and (UserInput:GetMouseLocation().X > Instance.Position.X) and (UserInput:GetMouseLocation().X < Instance.Position.X + Instance.Size.X) and (Mouse.Y > Instance.Position.Y) and (Mouse.Y < Instance.Position.Y + Instance.Size.Y) then
            if Library.WindowVisible then
                return true
            end
        end
        return false
    end
    Utility.Rounding = function(Num, DecimalPlaces)
        return tonumber(string.format("%." .. (DecimalPlaces or 0) .. "f", Num))
    end
    Utility.AddDrag = function(Sensor, List)
        local DragUtility = {
            MouseStart = Vector2.new(), MouseEnd = Vector2.new(), Dragging = false
        }
        Utility.AddConnection(UserInput.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if Utility.OnMouse(Sensor) then
                    DragUtility.Dragging = true
                end
            end
        end)
        Utility.AddConnection(UserInput.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                DragUtility.Dragging = false
            end
        end)
        Utility.AddConnection(RunService.RenderStepped, function()
            DragUtility.MouseStart = UserInput:GetMouseLocation()
            for Index, Value in pairs(List) do
                if Index ~= nil and Value ~= nil then
                    if DragUtility.Dragging then
                        Value[1].Position = Vector2.new(
                            Value[1].Position.X + (DragUtility.MouseStart.X - DragUtility.MouseEnd.X), 
                            Value[1].Position.Y + (DragUtility.MouseStart.Y - DragUtility.MouseEnd.Y)
                        )
                    end
                end
            end
            DragUtility.MouseEnd = UserInput:GetMouseLocation()
        end)
    end
    Utility.AddCursor = function(Instance)
        local CursorOutline = Utility.AddDrawing("Triangle", {
            Color = Library.Theme.Accent[1],
            Thickness = 1,
            Filled = false,
            ZIndex = 5
        }, Library.Ignores)
        local Cursor = Utility.AddDrawing("Triangle", {
            Color = Library.Theme.Accent[1],
            Thickness = 3,
            Filled = true,
            Transparency = 1,
            ZIndex = 5
        }, Library.Ignores)
        Utility.AddConnection(Library.Communication.Event, function(Type, Color)
            if Type == "Accent" then
                Cursor.Color = Color
                CursorOutline.Color = Color
            end
        end)
        Utility.AddConnection(RunService.RenderStepped, function()
            local Mouse = UserInput:GetMouseLocation()
            if Library.WindowVisible then
                CursorOutline.Visible = true
                CursorOutline.PointA = Vector2.new(UserInput:GetMouseLocation().X, Mouse.Y)
                CursorOutline.PointB = Vector2.new(UserInput:GetMouseLocation().X + 15, Mouse.Y + 5)
                CursorOutline.PointC = Vector2.new(UserInput:GetMouseLocation().X + 5, Mouse.Y + 15)

                Cursor.Visible = true
                Cursor.PointA = Vector2.new(UserInput:GetMouseLocation().X, Mouse.Y)
                Cursor.PointB = Vector2.new(UserInput:GetMouseLocation().X + 15, Mouse.Y + 5)
                Cursor.PointC = Vector2.new(UserInput:GetMouseLocation().X + 5, Mouse.Y + 15)
            else
                CursorOutline.Visible = false
                Cursor.Visible = false
            end
        end)
    end
    Utility.MiddlePos = function(Instance)
        return Vector2.new(
            (Camera.ViewportSize.X / 2) - (Instance.Size.X / 2), 
            (Camera.ViewportSize.Y / 2) - (Instance.Size.Y / 2)
        )
    end
    Utility.ConfigPath = function(Name)
        assert(type(Name) == "string" and Name:match("^[%w_-]+$"), "Use letters, numbers, underscores or hyphens for profile names")
        Utility.AddFolder("neoperroTFS")
        Utility.AddFolder("neoperroTFS/Configs")
        return "neoperroTFS/Configs/" .. Name .. ".json"
    end
    Utility.SaveConfig = function(Name)
        local Values = {}
        for Flag, Item in pairs(Library.Items) do
            if Item.TypeOf == "Colorpicker" then
                Values[Flag] = {Kind = "Color", HSV = Item.Colors.HSV}
            elseif Item.TypeOf ~= "Keybind" then
                Values[Flag] = Library.Flags[Flag]
            end
        end
        writefile(Utility.ConfigPath(Name), HttpService:JSONEncode(Values))
    end
    Utility.DeleteConfig = function(Name)
        local Path = Utility.ConfigPath(Name)
        if isfile(Path) then delfile(Path) end
    end
    Utility.LoadConfig = function(Name)
        local Values = HttpService:JSONDecode(readfile(Utility.ConfigPath(Name)))
        for Flag, Value in pairs(Values) do
            local Item = Library.Items[Flag]
            if Item then
                if Item.TypeOf == "Colorpicker" and type(Value) == "table" and Value.Kind == "Color" then
                    Item:SetHue({Value = Value.HSV[1]})
                    Item:SetSaturationX({Value = Value.HSV[2]})
                    Item:SetSaturationY({Value = Value.HSV[3]})
                elseif Item.Set and Item.TypeOf ~= "Keybind" then
                    Item:Set(Value)
                end
            end
        end
    end
    Utility.AddFolder = function(GetFolder)
        local Folder = isfolder(GetFolder)
        if Folder then
            return
        else
            makefolder(GetFolder)
            return true
        end
    end
    Utility.AddImage = function(Path, Url)
        local Name = Path:match("[^/]+$")
        if Name == "Logo2.png" then return LogoData end
        if EmbeddedAssets[Name] then return EmbeddedAssets[Name] end
        local Data = game:HttpGet(Url)
        return Data
    end
end
do
    function Library.CreateLoader(Title, WindowSize)
        local Window = {
            Max = 2, Current = 0
        }
        Library.Theme.Logo = LogoData
        Library.Theme.Gradient = EmbeddedAssets["Gradient.png"]
        local WindowOutline = Utility.AddDrawing("Square", {
            Size = WindowSize,
            Thickness = 0,
            Color = Library.Theme.Outline,
            Visible = true,
            Filled = true
        })
        WindowOutline.Position = Utility.MiddlePos(WindowOutline)
        local WindowOutlineBorder = Utility.AddDrawing("Square", {
            Size = Vector2.new(WindowOutline.Size.X - 2, WindowOutline.Size.Y - 2),
            Position = Vector2.new(WindowOutline.Position.X + 1, WindowOutline.Position.Y + 1),
            Thickness = 0,
            Color = Library.Theme.Accent[1],
            Visible = true,
            Filled = true
        })
        local WindowFrame = Utility.AddDrawing("Square", {
            Size = Vector2.new(WindowOutlineBorder.Size.X - 2, WindowOutlineBorder.Size.Y - 2),
            Position = Vector2.new(WindowOutlineBorder.Position.X + 1, WindowOutlineBorder.Position.Y + 1),
            Thickness = 0,
            Transparency = 1,
            Color = Library.Theme.DarkContrast,
            Visible = true,
            Filled = true
        })
        local WindowTopline = Utility.AddDrawing("Square", {
            Size = Vector2.new(WindowOutline.Size.X - 2, 2),
            Position = Vector2.new(WindowOutlineBorder.Position.X, WindowOutlineBorder.Position.Y),
            Thickness = 0,
            Color = Library.Theme.Accent[1],
            Visible = false,
            Filled = true
        })
        local WindowImage = Utility.AddDrawing("Image", {
            Size = WindowFrame.Size,
            Position = WindowFrame.Position,
            Transparency = 1, 
            Visible = true,
            Data = Library.Theme.Gradient
        })
        local WindowTitle = Utility.AddDrawing("Text", {
            Font = Library.Theme.Font,
            Size = Library.Theme.TextSize,
            Color = Library.Theme.Text,
            Text = Title,
            Position = Vector2.new(WindowFrame.Position.X + (WindowFrame.Size.X / 2), WindowOutlineBorder.Position.Y + 8),
            Visible = true,
            Center = true,
            Outline = false
        })
        local WindowText = Utility.AddDrawing("Text", {
            Font = Library.Theme.Font,
            Size = Library.Theme.TextSize,
            Color = Library.Theme.Text,
            Visible = true,
            Center = true,
            Outline = false
        })
        local SliderInline = Utility.AddDrawing("Square", {
            Size = Vector2.new(205, 15),
            Color = Library.Theme.Inline,
            Position = Vector2.new(WindowFrame.Position.X + (WindowFrame.Size.X / 2), WindowOutlineBorder.Position.Y + 8),
            Transparency = 0.75,
            Thickness = 0,
            Visible = true,
            Filled = true
        })
        local SliderOutline = Utility.AddDrawing("Square", {
            Size = Vector2.new(SliderInline.Size.X - 2, SliderInline.Size.Y - 2),
            Color = Library.Theme.Outline,
            Transparency = 0.5,
            Thickness = 0,
            Visible = true,
            Filled = true
        })
        local SliderFrame = Utility.AddDrawing("Square", {
            Size = Vector2.new(((SliderInline.Size.X - 2) / (Window.Max / math.clamp(Window.Current, 0, Window.Max))), SliderInline.Size.Y - 2),
            Color = Library.Theme.Accent[1],
            Transparency = 0.75,
            Thickness = 0,
            Visible = true,
            Filled = true
        })
        local SliderFrameShader = Utility.AddDrawing("Image", {
            Size = Vector2.new(SliderInline.Size.X - 2, SliderInline.Size.Y - 2),
            Transparency = 1, 
            Visible = true,
            Data = Library.Theme.Gradient
        })
        local MiddleIcon = Utility.AddDrawing("Image", {
            Size = Vector2.new(175, 175),
            Transparency = 1, 
            Visible = true,
            Data = Library.Theme.Logo
        })
        MiddleIcon.Position = Vector2.new(WindowOutline.Position.X + (WindowOutline.Size.X / 2) - (MiddleIcon.Size.X / 2), WindowOutline.Position.Y + (WindowOutline.Size.Y / 2) - (MiddleIcon.Size.Y / 2) - 15)
        Window.SetText = function(Val, Txt)
            SliderFrame.Size = Vector2.new(((SliderInline.Size.X - 2) / (Window.Max / math.clamp(Val, 0, Window.Max))), SliderInline.Size.Y - 2)
            WindowText.Text = Txt
        end
        SliderInline.Position = Vector2.new(WindowOutline.Position.X + (WindowOutline.Size.X / 2) - (SliderOutline.Size.X / 2), (WindowOutline.Position.Y + WindowOutline.Size.Y) - 30)
        SliderOutline.Position = Vector2.new(SliderInline.Position.X + 1, SliderInline.Position.Y + 1)
        SliderFrame.Position = Vector2.new(SliderInline.Position.X + 1, SliderInline.Position.Y + 1)
        SliderFrameShader.Position = Vector2.new(SliderInline.Position.X + 1, SliderInline.Position.Y + 1)
        WindowText.Position = Vector2.new(WindowFrame.Position.X + (WindowFrame.Size.X / 2), SliderInline.Position.Y - 16)
        Window.SetText(0, "UI Initialization [ Downloading ]")
        Utility.AddFolder("neoperroTFS")
        Utility.AddFolder("neoperroTFS/Caches")
        Utility.AddFolder("neoperroTFS/Assets")
        Utility.AddFolder("neoperroTFS/Assets/UI")
        Utility.AddFolder("neoperroTFS/Configs")
        Utility.AddFolder("neoperroTFS/Scripts")
        Library.Theme.Gradient = Utility.AddImage("neoperroTFS/Assets/UI/Gradient.png", "https://raw.githubusercontent.com/mvonwalk/Exterium/main/Gradient.png")
        Library.Theme.Hue = Utility.AddImage("neoperroTFS/Assets/UI/Hue.png", "https://raw.githubusercontent.com/mvonwalk/Exterium/main/HuePicker.png")
        Library.Theme.Saturation = Utility.AddImage("neoperroTFS/Assets/UI/Saturation.png", "https://raw.githubusercontent.com/mvonwalk/Exterium/main/SaturationPicker.png")
        Library.Theme.SaturationCursor = Utility.AddImage("neoperroTFS/Assets/UI/HueCursor.png", "https://raw.githubusercontent.com/mvonwalk/splix-assets/main/Images-cursor.png")
        Window.SetText(1, "Checking Assets")
        Window.SetText(1, "Checking Input")
        Window.SetText(2, "Finished")
        Utility.RemoveDrawing(WindowOutline)
        Utility.RemoveDrawing(WindowOutlineBorder)
        Utility.RemoveDrawing(WindowTopline)
        Utility.RemoveDrawing(WindowFrame)
        Utility.RemoveDrawing(WindowTitle)
        Utility.RemoveDrawing(WindowText)
        Utility.RemoveDrawing(SliderOutline)
        Utility.RemoveDrawing(SliderInline)
        Utility.RemoveDrawing(SliderFrame)
        Utility.RemoveDrawing(SliderFrameShader)
        Utility.RemoveDrawing(MiddleIcon)
        Utility.RemoveDrawing(WindowImage)
        UserInput.MouseIconEnabled = false
        return Window
    end
end
do
    function Library:ChangeVisible(State)
        Library.WindowVisible = State
        UserInput.MouseIconEnabled = not State
        for _, Entry in ipairs(Library.Drawings) do
            local Object = Entry[1]
            local Info = Library.DrawingInfo[Object]
            if Info and (Entry[2] or Object.Color ~= Library.Theme.Hitbox) then
                Utility.Animate(Object, "Transparency", State and Info.Alpha or 0)
            end
        end
    end
    function Library:UpdateTheme(Config)
        for _, Key in ipairs({"Accent", "Outline", "Inline", "LightContrast", "DarkContrast", "Text", "TextInactive"}) do
            local Value = Config[Key]
            if Value then
                if Key == "Accent" then Library.Theme.Accent[1] = Value else Library.Theme[Key] = Value end
                Library.Communication:Fire(Key, Value)
            end
        end
    end
    function Library.SelfDestruct()
        if Library.Destroyed then return end
        Library.Destroyed = true
        UserInput.MouseIconEnabled = OriginalMouseIcon
        for _, Connection in ipairs(Library.Connections) do Connection:Disconnect() end
        for Object in pairs(Library.DrawingInfo) do pcall(function() Object:Remove() end) end
        table.clear(Library.DrawingInfo)
        table.clear(Library.Tweens)
        table.clear(Library.Connections)
        InputGUI:Destroy()
        Library.Communication:Destroy()
        if getgenv().NeoperroTFS == Library then getgenv().NeoperroTFS = nil end
        if getgenv().Library == Library then getgenv().Library = nil end
        if getgenv().Utility == Utility then getgenv().Utility = nil end
    end
    Library.Destroy = Library.SelfDestruct
    if STATE then STATE.onCleanup(Library.SelfDestruct) end
    Utility.AddConnection(RunService.RenderStepped, function()
        local Now = os.clock()
        for Object, Entries in pairs(Library.Tweens) do
            for Property, Tween in pairs(Entries) do
                local Alpha = math.clamp((Now - Tween.Start) / Tween.Duration, 0, 1)
                local Eased = 1 - (1 - Alpha)^3
                if type(Tween.From) == "number" then
                    Object[Property] = Tween.From + (Tween.To - Tween.From) * Eased
                else
                    Object[Property] = Tween.From:Lerp(Tween.To, Eased)
                end
                if Alpha == 1 then Entries[Property] = nil end
            end
            if next(Entries) == nil then Library.Tweens[Object] = nil end
        end
    end)
    local LastAccent = 0
    Utility.AddConnection(RunService.RenderStepped, function()
        if not Library.WindowVisible or os.clock() - LastAccent < 1/20 then return end
        LastAccent = os.clock()
        local Accent = Library.BaseAccent
        if Library.AccentMode == "Red pulse" then
            Accent = Accent:Lerp(Color3.fromRGB(255, 85, 101), (math.sin(os.clock() * 1.5) + 1) * 0.18)
        elseif Library.AccentMode == "Spectrum" then
            Accent = Color3.fromHSV((os.clock() / 18) % 1, 0.72, 0.95)
        end
        if Accent ~= Library.Theme.Accent[1] then Library:UpdateTheme({Accent = Accent}) end
    end)
    function Library.Window(Title, Size)
        local Window = {
            Notification = 0,
            Tabs = {},
            LastTab = nil,
            SelectedTab = nil,
            BindList = ""
        }
        do
            local WindowOutline = Utility.AddDrawing("Square", {
                Size = Vector2.new(120, 20),
                Thickness = 0,  
                Color = Library.Theme.Outline,
                Visible = true,
                Filled = true
            }, Library.Keybind)
            WindowOutline.Position = Vector2.new(10, (Camera.ViewportSize.Y / 2) - (WindowOutline.Size.Y / 2))
            local WindowOutlineBorder = Utility.AddDrawing("Square", {
                Size = Vector2.new(WindowOutline.Size.X - 2, WindowOutline.Size.Y - 2),
                Position = Vector2.new(WindowOutline.Position.X + 1, WindowOutline.Position.Y + 1),
                Thickness = 0,
                Color = Library.Theme.Accent[1],
                Visible = false,
                Filled = true
            }, Library.Keybind)
            local WindowFrame = Utility.AddDrawing("Square", {
                Size = Vector2.new(WindowOutlineBorder.Size.X - 2, WindowOutlineBorder.Size.Y - 2),
                Position = Vector2.new(WindowOutlineBorder.Position.X + 1, WindowOutlineBorder.Position.Y + 1),
                Thickness = 0,
                Transparency = 1,
                Color = Library.Theme.DarkContrast,
                Visible = true,
                Filled = true
            }, Library.Keybind)
            local WindowTopline = Utility.AddDrawing("Square", {
                Size = Vector2.new(WindowOutlineBorder.Size.X, 1),
                Position = Vector2.new(WindowOutlineBorder.Position.X, WindowOutlineBorder.Position.Y),
                Thickness = 0,
                Color = Library.Theme.Accent[1],
                Visible = true,
                Filled = true
            }, Library.Keybind)
            local WindowImage = Utility.AddDrawing("Image", {
                Size = WindowFrame.Size,
                Position = WindowFrame.Position,
                Transparency = 1, 
                Visible = true,
                Data = Library.Theme.Gradient
            }, Library.Keybind)
            local WindowText = Utility.AddDrawing("Text", {
                Font = Library.Theme.Font,
                Size = Library.Theme.TextSize,
                Color = Library.Theme.Text,
                Text = "Keybinds",
                Position = Vector2.new(WindowOutlineBorder.Position.X + (WindowOutlineBorder.Size.X / 2), WindowOutlineBorder.Position.Y + 2),
                Visible = true,
                Center = true,
                Outline = false
            }, Library.Keybind)
            local CurrentBinds = Utility.AddDrawing("Text", {
                Font = Library.Theme.Font,
                Size = Library.Theme.TextSize,
                Color = Library.Theme.Text,
                Text = "",
                Position = Vector2.new(WindowOutlineBorder.Position.X + 3, WindowOutlineBorder.Position.Y + 8),
                Visible = true,
                Center = false,
                Outline = false
            }, Library.Keybind)
            Utility.AddConnection(RunService.RenderStepped, function(Type, Color)
                CurrentBinds.Text = Window.BindList

                local CalcuationSize = CurrentBinds.Text ~= "" and Vector2.new(CurrentBinds.TextBounds.X >= 120 and CurrentBinds.TextBounds.X + 6 or 120, 20 + CurrentBinds.TextBounds.Y - 6) or Vector2.new(120, 20)
                WindowOutline.Size = CalcuationSize
                
                WindowOutlineBorder.Size = Vector2.new(WindowOutline.Size.X - 2, WindowOutline.Size.Y - 2)
                WindowOutlineBorder.Position = Vector2.new(WindowOutline.Position.X + 1, WindowOutline.Position.Y + 1)

                WindowTopline.Size = Vector2.new(WindowOutlineBorder.Size.X, 1)
                WindowTopline.Position = Vector2.new(WindowOutlineBorder.Position.X, WindowOutlineBorder.Position.Y)

                WindowImage.Size = WindowFrame.Size
                WindowImage.Position = WindowFrame.Position

                WindowText.Position = Vector2.new(WindowOutlineBorder.Position.X + (WindowOutlineBorder.Size.X / 2), WindowOutlineBorder.Position.Y + 2)
            end)
            Utility.AddDrag(WindowOutline, Library.Keybind)
            Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                if Type == "Accent" then
                    WindowOutlineBorder.Color = Color
                    WindowTopline.Color = Color
                elseif Type == "Outline" then
                    WindowOutline.Color = Color
                elseif Type == "DarkContrast" then
                    WindowFrame.Color = Color
                elseif Type == "Text" then
                    WindowText.Color = Color
                end
            end)
        end
        local WindowOutline = Utility.AddDrawing("Square", {
            Size = Size,
            Thickness = 0,
            Color = Library.Theme.Outline,
            Visible = true,
            Filled = true
        })
        WindowOutline.Position = Utility.MiddlePos(WindowOutline)
        local WindowOutlineBorder = Utility.AddDrawing("Square", {
            Size = Vector2.new(WindowOutline.Size.X - 2, WindowOutline.Size.Y - 2),
            Position = Vector2.new(WindowOutline.Position.X + 1, WindowOutline.Position.Y + 1),
            Thickness = 0,
            Color = Library.Theme.Accent[1],
            Visible = true,
            Filled = true
        })
        local WindowFrame = Utility.AddDrawing("Square", {
            Size = Vector2.new(WindowOutlineBorder.Size.X - 2, WindowOutlineBorder.Size.Y - 2),
            Position = Vector2.new(WindowOutlineBorder.Position.X + 1, WindowOutlineBorder.Position.Y + 1),
            Thickness = 0,
            Transparency = 1,
            Color = Library.Theme.DarkContrast,
            Visible = true,
            Filled = true
        })
        local WatermarkIcon = Utility.AddDrawing("Image", {
            Size = Vector2.new(36, 36),
            Position = Vector2.new(WindowFrame.Position.X + WindowFrame.Size.X - 44, WindowFrame.Position.Y + 4),
            Transparency = 1,
            ZIndex = 3,
            Visible = true,
            Data = Library.Theme.Logo
        })
        Utility.AddCursor(WindowFrame)
        local WindowHeader = Utility.AddDrawing("Square", {
            Size = Vector2.new(WindowOutlineBorder.Size.X - 2, 70),
            Position = Vector2.new(WindowOutlineBorder.Position.X + 1, WindowOutlineBorder.Position.Y + 1),
            Thickness = 0,
            Transparency = 0,
            Color = Library.Theme.Hitbox,
            Visible = true,
            Filled = true
        })
        Utility.AddDrag(WindowHeader, Library.Drawings)
        local WindowTopline = Utility.AddDrawing("Square", {
            Size = Vector2.new(WindowOutlineBorder.Size.X, 1),
            Position = Vector2.new(WindowOutlineBorder.Position.X, WindowOutlineBorder.Position.Y),
            Thickness = 0,
            Color = Library.Theme.Accent[1],
            Visible = false,
            Filled = true
        })
        local WindowImage = Utility.AddDrawing("Image", {
            Size = WindowFrame.Size,
            Position = WindowFrame.Position,
            Transparency = 1, 
            Visible = true,
            Data = Library.Theme.Gradient
        })
        local WindowTitle = Utility.AddDrawing("Text", {
            Font = Library.Theme.Font,
            Size = Library.Theme.TextSize,
            Color = Library.Theme.Text,
            Text = Title,
            Position = Vector2.new(WindowOutlineBorder.Position.X + 8, WindowOutlineBorder.Position.Y + 6),
            Visible = true,
            Center = false,
            Outline = false
        })
        local SecondBorderInline = Utility.AddDrawing("Square", {
            Size = Vector2.new(Size.X - 17, Size.Y - 50),
            Position = Vector2.new(WindowOutlineBorder.Position.X + 8, WindowOutlineBorder.Position.Y + 42),
            Thickness = 0,
            Color = Library.Theme.Inline,
            Visible = true,
            Filled = true
        })
        local SecondBorderOutline = Utility.AddDrawing("Square", {
            Size = Vector2.new(SecondBorderInline.Size.X - 2, SecondBorderInline.Size.Y - 2),
            Position = Vector2.new(SecondBorderInline.Position.X + 1, SecondBorderInline.Position.Y + 1),
            Thickness = 0,
            Color = Library.Theme.LightContrast,
            Visible = true,
            Filled = true
        })
        local TabLine = Utility.AddDrawing("Square", {
            Thickness = 0,
            Color = Library.Theme.Accent[1], --Library.Theme.Outline,
            Visible = true,
            Filled = true,
            ZIndex = 2
        })
        local DisableLine = Utility.AddDrawing("Square", {
            Thickness = 0,
            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
            Visible = true,
            Filled = true,
            ZIndex = 3
        })
        Utility.AddConnection(Library.Communication.Event, function(Type, Color)
            if Type == "Accent" then
                WindowOutlineBorder.Color = Color
                WindowTopline.Color = Color
                TabLine.Color = Color
            elseif Type == "Outline" then
                WindowOutline.Color = Color
            elseif Type == "LightContrast" then
                DisableLine.Color = Color
                SecondBorderOutline.Color = Color
            elseif Type == "DarkContrast" then
                WindowFrame.Color = Color
            elseif Type == "Text" then
                WindowTitle.Color = Color
            elseif Type == "Inline" then
                SecondBorderInline.Color = Color
            end
        end)
        Window["PageCover"] = SecondBorderInline
        function Window.SendNotification(Type, Title, Duration)
            local Notification, Removed = Window.Notification, false
            local NotificationInline = Utility.AddDrawing("Square", {
                Size = Vector2.new(0, 21),
                Position = Vector2.new(0, (Window.Notification * 25) + 100),
                Thickness = 0,
                Color = Library.Theme.Inline,
                Visible = true,
                Filled = true
            }, Library.Ignores)
            local NotificationOutline = Utility.AddDrawing("Square", {
                Size = Vector2.new(0, NotificationInline.Size.Y - 1),
                Position = Vector2.new(NotificationInline.Position.X + 2, NotificationInline.Position.Y + 2),
                Thickness = 0,
                Color = Library.Theme.DarkContrast,
                Visible = true,
                Filled = true
            }, Library.Ignores)
            local NotificationOutlineBorder = Utility.AddDrawing("Square", {
                Size = Vector2.new(NotificationOutline.Size.X - 2, NotificationOutline.Size.Y + 5),
                Position = Vector2.new(NotificationOutline.Position.X + 1, NotificationOutline.Position.Y + 1),
                Thickness = 0,
                Color = Library.Theme.Accent[1],
                Visible = false,
                Filled = true
            }, Library.Ignores)
            local NotificationTopline = Utility.AddDrawing("Square", {
                Size = Vector2.new(NotificationOutline.Size.X, 1),
                Position = Vector2.new(NotificationOutline.Position.X, NotificationOutline.Position.Y),
                Thickness = 0,
                Color = Type == "Warning" and Library.Theme.Notification.Warning or Type == "Error" and Library.Theme.Notification.Error or Library.Theme.DarkContrast,
                Visible = Type == "Warning" or Type == "Error",
                Filled = true
            }, Library.Ignores)
            local NotificationLeftline = Utility.AddDrawing("Square", {
                Size = Vector2.new(1, NotificationOutline.Size.Y),
                Position = Vector2.new(NotificationOutline.Position.X, NotificationOutline.Position.Y),
                Thickness = 0,
                Color = Type == "Normal" and Library.Theme.Accent[1] or Library.Theme.DarkContrast,
                Visible = Type == "Normal",
                Filled = true
            }, Library.Ignores)
            local NotificationImage = Utility.AddDrawing("Image", {
                Size = NotificationOutlineBorder.Size,
                Position = NotificationOutlineBorder.Position,
                Transparency = 1, 
                Visible = true,
                Data = Library.Theme.Gradient
            }, Library.Ignores)
            local NotificationText = Utility.AddDrawing("Text", {
                Font = Library.Theme.Font,
                Size = Library.Theme.TextSize,
                Color = Library.Theme.Text,
                Text = Title,
                Position = Vector2.new(NotificationOutlineBorder.Position.X + 6, NotificationOutlineBorder.Position.Y + 3),
                Visible = true,
                Center = false,
                Outline = false
            }, Library.Ignores)
            NotificationInline.Size = Vector2.new(NotificationText.TextBounds.X + 15, 21)
            NotificationOutline.Size = Vector2.new(NotificationInline.Size.X - 1, NotificationInline.Size.Y - 1)
            NotificationOutline.Position = Vector2.new(NotificationInline.Position.X + 2, NotificationInline.Position.Y + 2)
            NotificationOutlineBorder.Size = Vector2.new(NotificationOutline.Size.X - 2, NotificationOutline.Size.Y - 2)
            NotificationOutlineBorder.Position = Vector2.new(NotificationOutline.Position.X + 1, NotificationOutline.Position.Y + 1)
            NotificationLeftline.Size = Vector2.new(2, NotificationOutline.Size.Y)
            NotificationTopline.Size = Vector2.new(NotificationOutline.Size.X, 1)
            NotificationImage.Size = NotificationOutline.Size
            NotificationImage.Position = NotificationOutline.Position
            task.spawn(function()
                for Index = -100, 0, 2 do
                    if Library.Destroyed then return end
                    pcall(function()
                        NotificationInline.Position = Vector2.new(Index, (Notification * 25) + 100)
                        NotificationOutline.Position = Vector2.new(NotificationInline.Position.X + 2, NotificationInline.Position.Y + 2)
                        NotificationOutlineBorder.Position = Vector2.new(NotificationOutline.Position.X + 2, NotificationOutline.Position.Y + 2)
                        NotificationText.Position = Vector2.new(NotificationOutline.Position.X + 6, NotificationOutline.Position.Y + 3)
                        NotificationTopline.Position = Vector2.new(NotificationOutline.Position.X, NotificationOutline.Position.Y)
                        NotificationImage.Position = NotificationOutline.Position
                        NotificationLeftline.Position = Vector2.new(NotificationOutline.Position.X, NotificationOutline.Position.Y)
                    end)
                    task.wait()
                end
            end)
            Utility.AddConnection(Library.Communication.Event, function(Type)
                if Type == "UpdateNotification" then
                    Notification -= 1
                    pcall(function()
                        NotificationInline.Position = Vector2.new(NotificationInline.Position.X, (Notification * 25) + 100)
                        NotificationOutline.Position = Vector2.new(NotificationInline.Position.X + 2, NotificationInline.Position.Y + 2)
                        NotificationText.Position = Vector2.new(NotificationOutline.Position.X + 6, NotificationOutline.Position.Y + 3)
                        NotificationTopline.Position = Vector2.new(NotificationOutline.Position.X, NotificationOutline.Position.Y)
                        NotificationImage.Position = NotificationOutline.Position
                        NotificationLeftline.Position = Vector2.new(NotificationOutline.Position.X, NotificationOutline.Position.Y)
                    end)
                end
            end)
            Window.Notification += 1
            task.spawn(function()
                task.wait(Duration)
                if Library.Destroyed then return end
                pcall(function()
                    Utility.RemoveDrawing(NotificationInline, Library.Ignores)
                    Utility.RemoveDrawing(NotificationLeftline, Library.Ignores)
                    Utility.RemoveDrawing(NotificationOutline, Library.Ignores)
                    Utility.RemoveDrawing(NotificationOutlineBorder, Library.Ignores)
                    Utility.RemoveDrawing(NotificationText, Library.Ignores)
                    Utility.RemoveDrawing(NotificationTopline, Library.Ignores)
                    Utility.RemoveDrawing(NotificationImage, Library.Ignores)
                end)
                Library.Communication:Fire("UpdateNotification")
                Window.Notification -= 1
            end)
        end
        function Window:RefreshPages()
            Window.LastTab = nil
            for Index, Value in pairs(Window.Tabs) do
                Value:Install()
                Window.LastTab = Value.TabInline
            end
        end
        function Window:SwitchTab(Tab)
            for _, Popup in ipairs(Library.Popups) do
                if Popup.Drop then Popup:Drop(false) elseif Popup.ShowList then Popup:ShowList(false) end
            end
            for Index, Value in pairs(self.Tabs) do
                Value["TabTitle"].Color = Library.Theme.TextInactive
                Value["TabOutline"].Color = Library.Theme.DarkContrast

                for _, Render in pairs(Value["Render"]) do
                    Render.Visible = false
                end
            end

            Tab["TabOutline"].Color = Library.Theme.LightContrast
            Tab["TabTitle"].Color = Library.Theme.Text

            TabLine.Size = Vector2.new(Tab["TabOutline"].Size.X, 1)
            Utility.Animate(TabLine, "Position", Vector2.new(Tab.TabOutline.Position.X, Tab.TabOutline.Position.Y))
            DisableLine.Size = Vector2.new(Tab["TabOutline"].Size.X, 1)
            DisableLine.Position = Vector2.new(Tab["TabOutline"].Position.X, Tab["TabOutline"].Position.Y + Tab["TabOutline"].Size.Y)
            Window.SelectedTab = Tab.CurrentTab

            for _, Render in pairs(Tab["Render"]) do
                Render.Visible = true
            end
        end
        function Window:Tab(Title)
            local Tab = {
                Render = {},
                Visible = {},
                SectionAxis = {0, 0},
                Sections = {},
                Dropdowns = {
                    ["Left"] = {}, 
                    ["Right"] = {}
                },
                CurrentTab = #self.Tabs
            }
            local TabInline = Utility.AddDrawing("Square", {
                Position = Vector2.new(SecondBorderInline.Position.X, SecondBorderOutline.Position.Y - 20),
                Size = Vector2.new(0, 20),
                Thickness = 0,
                Color = Library.Theme.Inline,
                Visible = true,
                Filled = true
            })
            local TabOutline = Utility.AddDrawing("Square", {
                Size = Vector2.new(TabInline.Size.X - 2, TabInline.Size.Y - 2),
                Position = Vector2.new(TabInline.Position.X + 1, TabInline.Position.Y + 1),
                Thickness = 0,
                Color = Library.Theme.DarkContrast, --Library.Theme.Outline,
                Visible = true,
                Filled = true
            })
            local TabTitle = Utility.AddDrawing("Text", {
                Text = Title,
                Center = true,
                Outline = false,
                Font = Library.Theme.Font,
                Size = Library.Theme.TextSize,
                Color = Library.Theme.Text,
                Visible = true,
                ZIndex = 2
            })
            Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                if Type == "DarkContrast" and Window.SelectedTab ~= Tab.CurrentTab then
                    TabOutline.Color = Color
                elseif Type == "LightContrast" and Window.SelectedTab == Tab.CurrentTab then
                    TabOutline.Color = Color
                elseif Type == "Text" then
                    TabTitle.Color = Color
                elseif Type == "Inline" then
                    TabInline.Color = Color
                end
            end)
            function Tab:Install()
                TabInline.Size = Vector2.new(TabTitle.TextBounds.X + 50, 20)
                TabInline.Position = Vector2.new((Window.LastTab ~= nil and Window.LastTab.Position.X + Window.LastTab.Size.X + 5 or SecondBorderInline.Position.X), SecondBorderOutline.Position.Y - 20)

                TabOutline.Size = Vector2.new(TabInline.Size.X - 2, TabInline.Size.Y - 2)
                TabOutline.Position = Vector2.new(TabInline.Position.X + 1, TabInline.Position.Y + 1)

                if Window.LastTab == nil then
                    TabLine.Size = Vector2.new(TabOutline.Size.X, 1)
                    TabLine.Position = Vector2.new(TabOutline.Position.X + 1, TabOutline.Position.Y)

                    DisableLine.Size = Vector2.new(TabOutline.Size.X, 1)
                    DisableLine.Position = Vector2.new(TabOutline.Position.X, TabOutline.Position.Y + TabOutline.Size.Y)

                    Window.SelectedTab = Tab.CurrentTab
                end

                TabTitle.Position = Vector2.new(TabOutline.Position.X + (TabOutline.Size.X / 2), TabOutline.Position.Y + (TabOutline.Size.Y / 2) - 7)
            end
            function Tab:RemoveDrawing(Object)
                local Index = table.find(Tab.Render, Object)
                if Index then table.remove(Tab.Render, Index) end
                Utility.RemoveDrawing(Object)
            end
            function Tab:Section(Title, Side)
                local Section = {
                    ContentAxis = 0
                }
                local AxisX = Side == "Left" and SecondBorderOutline.Position.X + 6 or SecondBorderOutline.Position.X + ((SecondBorderOutline.Size.X / 2) - 10) + 12
                local SectionInline = Utility.AddDrawing("Square", {
                    Position = Vector2.new(AxisX, (Tab.SectionAxis[Side == "Left" and 1 or 2] == 0 and TabOutline.Position.Y + TabOutline.Size.Y + 6 or 6 + Tab.SectionAxis[Side == "Left" and 1 or 2])),
                    Size = Vector2.new((SecondBorderOutline.Size.X / 2) - 8, 24),
                    Thickness = 0,
                    Color = Library.Theme.Inline,
                    Visible = true,
                    Filled = true
                })
                local SectionOutline = Utility.AddDrawing("Square", {
                    Size = Vector2.new(SectionInline.Size.X - 2, SectionInline.Size.Y - 2),
                    Position = Vector2.new(SectionInline.Position.X + 1, SectionInline.Position.Y + 1),
                    Thickness = 0,
                    Color = Library.Theme.DarkContrast, --Library.Theme.Outline,
                    Visible = true,
                    Filled = true
                })
                local SectionTopline = Utility.AddDrawing("Square", {
                    Size = Vector2.new(SectionOutline.Size.X, 1),
                    Position = Vector2.new(SectionOutline.Position.X, SectionOutline.Position.Y),
                    Thickness = 0,
                    Color = Library.Theme.Accent[1],
                    Visible = true,
                    Filled = true
                })
                local SectionTitle = Utility.AddDrawing("Text", {
                    Text = Title,
                    Position = Vector2.new(SectionOutline.Position.X + 4, SectionOutline.Position.Y + 4),
                    Center = false,
                    Outline = false,
                    Font = Library.Theme.Font,
                    Size = Library.Theme.TextSize,
                    Color = Library.Theme.Text,
                    Visible = true,
                    ZIndex = 2
                })
                Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                    if Type == "Accent" then
                        SectionTopline.Color = Color
                    elseif Type == "DarkContrast" then
                        SectionOutline.Color = Color
                    elseif Type == "Text" then
                        SectionTitle.Color = Color
                    elseif Type == "Inline" then
                        SectionInline.Color = Color
                    end
                end)
                function Section:UpdateSizeY(SizeY)
                    SectionInline.Size = Vector2.new(SectionInline.Size.X, SizeY + 10)

                    SectionOutline.Size = Vector2.new(SectionInline.Size.X - 2, SectionInline.Size.Y - 2)
                    SectionOutline.Position = Vector2.new(SectionInline.Position.X + 1, SectionInline.Position.Y + 1)
                end
                Tab.SectionAxis = {
                    Side == "Left" and SectionInline.Position.Y + SectionInline.Size.Y or Tab.SectionAxis[1], 
                    Side == "Right" and SectionInline.Position.Y + SectionInline.Size.Y or Tab.SectionAxis[2]
                }
                Tab["Render"][#Tab["Render"] + 1] = SectionInline
                Tab["Render"][#Tab["Render"] + 1] = SectionOutline
                Tab["Render"][#Tab["Render"] + 1] = SectionTopline
                Tab["Render"][#Tab["Render"] + 1] = SectionTitle
                function Section:Toggle(Options)
                    local Toggle = {
                        Axis = Section.ContentAxis,
                        Toggled = Options.State == true,
                        Drop = false,
                        Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end
                    }
                    Options.Flag = Options.Flag or Utility.NextFlag()
                    Library.Flags[Options.Flag] = Toggle.Toggled
                    local ToggleInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + 8, SectionInline.Position.Y + 23 + Toggle.Axis),
                        Size = Vector2.new(13, 13),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local ToggleOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(ToggleInline.Size.X - 2, ToggleInline.Size.Y - 2),
                        Position = Vector2.new(ToggleInline.Position.X + 1, ToggleInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local ToggleHitbox = Utility.AddDrawing("Square", {
                        Size = Vector2.new(SectionOutline.Size.X - 60, ToggleInline.Size.Y - 2),
                        Position = Vector2.new(ToggleInline.Position.X + 1, ToggleInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.Hitbox, --Library.Theme.Outline,
                        Transparency = 0,
                        Visible = true,
                        Filled = true
                    })
                    local ToggleGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(ToggleInline.Size.X - 2, ToggleInline.Size.Y - 2),
                        Position = Vector2.new(ToggleInline.Position.X + 1, ToggleInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 0.5,
                        Visible = true
                    })
                    local ToggleTitle = Utility.AddDrawing("Text", {
                        Text = Options.Title,
                        Position = Vector2.new(ToggleInline.Position.X + ToggleInline.Size.X + 8, ToggleInline.Position.Y),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Options.Type ~= nil and Options.Type == "Dangerous" and Library.Theme.Accent[1] or Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    function Toggle:Set(State)
                        Toggle.Toggled = State
                        Utility.Animate(ToggleOutline, "Color", Toggle.Toggled and Library.Theme.Accent[1] or Library.Theme.DarkContrast)
                        Library.Flags[Options.Flag] = Toggle.Toggled
                        Toggle.Callback(Toggle.Toggled)
                    end
                    Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                        
                        for Index, Value in pairs(Tab.Dropdowns[Side]) do
                            if Value then
                                return
                            end
                        end
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and Utility.OnMouse(ToggleHitbox) then
                            Toggle.Toggled = not Toggle.Toggled
                            Toggle:Set(Toggle.Toggled)
                        end
                    end)
                    Utility.AddConnection(UserInput.InputChanged, function(Input, Useless)
                        if Input.UserInputType == Enum.UserInputType.MouseMovement then
                            if Utility.OnMouse(ToggleHitbox) then
                                ToggleInline.Color = Library.Theme.Accent[1]
                            else
                                ToggleInline.Color = Library.Theme.Inline
                            end
                        end
                    end)
                    Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                        if Type == "Accent" and Toggle.Toggled then
                            ToggleOutline.Color = Color
                            if Options.Type == "Dangerous" then
                                ToggleTitle.Color = Color
                            end
                        elseif Type == "LightContrast" and not Toggle.Toggled then
                            ToggleOutline.Color = Color
                        elseif Type == "Text" then
                            ToggleTitle.Color = Color
                        elseif Type == "Inline" then
                            ToggleInline.Color = Color
                        end
                    end)
                    Section.ContentAxis = Section.ContentAxis + ToggleOutline.Size.Y + 8
                    Tab.SectionAxis = {
                        Side == "Left" and Tab.SectionAxis[1] + ToggleOutline.Size.Y + 8 or Tab.SectionAxis[1], 
                        Side == "Right" and Tab.SectionAxis[2] + ToggleOutline.Size.Y + 8 or Tab.SectionAxis[2]
                    }
                    self:UpdateSizeY(Section.ContentAxis + ToggleOutline.Size.Y)
                    Tab["Render"][#Tab["Render"] + 1] = ToggleInline
                    Tab["Render"][#Tab["Render"] + 1] = ToggleOutline
                    Tab["Render"][#Tab["Render"] + 1] = ToggleTitle
                    Tab["Render"][#Tab["Render"] + 1] = ToggleGradient
                    Tab["Render"][#Tab["Render"] + 1] = ToggleHitbox
                    function Toggle:Colorpicker(Options)
                        local Colorpicker = {
                            Axis = Section.ContentAxis,
                            Color = Options.Color,
                            HexColor = Options.Color:ToHex(),
                            Dropped = false,
                            Offsets = {
                                X = 0,
                                Y = 0
                            },
                            Colors = {
                                HSV = {1, 1, 1}
                            },
                            SaturationDragging = false,
                            HueDragging = false,
                            Decimals = 50,
                            Rainbow = false,
                            Flag = Options.Flag or Utility.NextFlag(),
                            Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end
                        }
                        Colorpicker.Flag = Colorpicker.Flag or "AWIJGHUIWGHuAW"
                        Library.Flags[Colorpicker.Flag] = Colorpicker.HexColor
                        local H, S, V = Colorpicker.Color:ToHSV()
                        Colorpicker.Colors.HSV[1] = H
                        Colorpicker.Colors.HSV[2] = S
                        Colorpicker.Colors.HSV[3] = V
                        local ColorpickerInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new((SectionInline.Position.X + SectionInline.Size.X) - 38, ToggleInline.Position.Y + 1),
                            Size = Vector2.new(30, 12),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true
                        })
                        local ColorpickerOutline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(ColorpickerInline.Size.X - 2, ColorpickerInline.Size.Y - 2),
                            Position = Vector2.new(ColorpickerInline.Position.X + 1, ColorpickerInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true
                        })
                        local ColorpickerBase = Utility.AddDrawing("Square", {
                            Size = Vector2.new(ColorpickerInline.Size.X - 2, ColorpickerInline.Size.Y - 2),
                            Position = Vector2.new(ColorpickerInline.Position.X + 1, ColorpickerInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Colorpicker.Color, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true
                        })
                        local ColorpickerGradient = Utility.AddDrawing("Image", {
                            Size = Vector2.new(ColorpickerInline.Size.X - 2, ColorpickerInline.Size.Y - 2),
                            Position = Vector2.new(ColorpickerInline.Position.X + 1, ColorpickerInline.Position.Y + 1),
                            Data = Library.Theme.Gradient,
                            Transparency = 0.5,
                            Visible = true
                        })
                        local InternalInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new((ColorpickerInline.Position.X - 225) + ColorpickerInline.Size.X, ToggleInline.Position.Y + 18),
                            Size = Vector2.new(225, 250),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalOutline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(InternalInline.Size.X - 2, InternalInline.Size.Y - 2),
                            Position = Vector2.new(InternalInline.Position.X + 1, InternalInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalTopline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(InternalOutline.Size.X, 1),
                            Position = Vector2.new(InternalOutline.Position.X, InternalOutline.Position.Y),
                            Thickness = 0,
                            Color = Library.Theme.Accent[1],
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                            if Type == "Accent" then
                                InternalTopline.Color = Color
                            end
                        end)
                        local InternalTitle = Utility.AddDrawing("Text", {
                            Text = ToggleTitle.Text,
                            Position = Vector2.new(InternalOutline.Position.X + 8, InternalOutline.Position.Y + 6),
                            Center = false,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        local InternalBaseInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new(InternalOutline.Position.X + 8, InternalOutline.Position.Y + 25),
                            Size = Vector2.new(192, 192),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalBase = Utility.AddDrawing("Square", {
                            Size = Vector2.new(192 - 4, 192 - 4),
                            Position = Vector2.new(InternalBaseInline.Position.X + 2, InternalBaseInline.Position.Y + 2),
                            Thickness = 0,
                            Color = Options.Color, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalSaturation = Utility.AddDrawing("Image", {
                            Size = Vector2.new(196 - 2, 196 - 2),
                            Position = Vector2.new(InternalOutline.Position.X + 8 + 1, InternalOutline.Position.Y + 25 + 1),
                            Data = Library.Theme.Saturation,
                            Transparency = 1,
                            Visible = true,
                            ZIndex = 3
                        })
                        local InternalHueInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new(InternalOutline.Position.X + InternalBase.Size.X + 14, InternalOutline.Position.Y + 26),
                            Size = Vector2.new(16, 196),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalHue = Utility.AddDrawing("Image", {
                            Size = Vector2.new(InternalHueInline.Size.X - 2, InternalHueInline.Size.Y - 2),
                            Position = Vector2.new(InternalHueInline.Position.X + 1, InternalHueInline.Position.Y + 1),
                            Data = Library.Theme.Hue,
                            Transparency = 1,
                            Visible = true,
                            ZIndex = 3
                        })
                        local InternalOutlineHuePicker = Utility.AddDrawing("Square", {
                            Position = Vector2.new(InternalOutline.Position.X + InternalBase.Size.X + 12, InternalOutline.Position.Y + 26),
                            Size = Vector2.new(InternalHueInline.Size.X + 2, 6),
                            Thickness = 2,
                            Color = Library.Theme.Outline,
                            Visible = true,
                            Filled = false,
                            ZIndex = 3
                        })
                        local InternalHuePicker = Utility.AddDrawing("Square", {
                            Position = Vector2.new(InternalOutlineHuePicker.Position.X + 1, InternalOutlineHuePicker.Position.Y + 1),
                            Size = Vector2.new(InternalOutlineHuePicker.Size.X - 2, InternalOutlineHuePicker.Size.Y - 2),
                            Thickness = 2,
                            Color = Library.Theme.Text,
                            Visible = true,
                            Filled = false,
                            ZIndex = 3
                        })
                        local Cursor = Utility.AddDrawing("Image", {
                            Size = Vector2.new(6, 6),
                            Data = Library.Theme.SaturationCursor,
                            Transparency = 1,
                            Visible = true,
                            ZIndex = 6
                        })
                        local InternalInlineHex = Utility.AddDrawing("Square", {
                            Size = Vector2.new(80 - 2, 18 - 2),
                            Position = Vector2.new(InternalOutline.Position.X + 8 + 1, InternalOutline.Position.Y + InternalSaturation.Size.Y + 30 + 1),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalOutlineHex = Utility.AddDrawing("Square", {
                            Size = Vector2.new(InternalInlineHex.Size.X - 2, InternalInlineHex.Size.Y - 2),
                            Position = Vector2.new(InternalInlineHex.Position.X + 1, InternalInlineHex.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalHex = Utility.AddDrawing("Text", {
                            Text = ("#%s"):format(tostring(Colorpicker.HexColor)),
                            Position = Vector2.new(InternalOutlineHex.Position.X + (InternalOutlineHex.Size.X / 2), InternalOutlineHex.Position.Y),
                            Center = true,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        local InternalInlineRGB = Utility.AddDrawing("Square", {
                            Size = Vector2.new(130 - 2, 18 - 2),
                            Position = Vector2.new(InternalOutline.Position.X + 90 + 1, InternalOutline.Position.Y + InternalSaturation.Size.Y + 30 + 1),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalOutlineRGB = Utility.AddDrawing("Square", {
                            Size = Vector2.new(InternalInlineRGB.Size.X - 2, InternalInlineRGB.Size.Y - 2),
                            Position = Vector2.new(InternalInlineRGB.Position.X + 1, InternalInlineRGB.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalRGB = Utility.AddDrawing("Text", {
                            Text = ("%d, %d, %d"):format(math.floor(Colorpicker.Color.R * 255), math.floor(Colorpicker.Color.G * 255), math.floor(Colorpicker.Color.B * 255)),
                            Position = Vector2.new(InternalOutlineRGB.Position.X + (InternalOutlineRGB.Size.X / 2), InternalOutlineRGB.Position.Y),
                            Center = true,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        local InternalInlineRainbow = Utility.AddDrawing("Square", {
                            Size = Vector2.new(100 - 2, 18 - 2),
                            Position = Vector2.new((InternalOutline.Position.X + InternalOutline.Size.X) - 100 - 2 + 1, InternalOutline.Position.Y + 4 + 1),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalOutlineRainbow = Utility.AddDrawing("Square", {
                            Size = Vector2.new(InternalInlineRainbow.Size.X - 2, InternalInlineRainbow.Size.Y - 2),
                            Position = Vector2.new(InternalInlineRainbow.Position.X + 1, InternalInlineRainbow.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local InternalRainbow = Utility.AddDrawing("Text", {
                            Text = "Rainbow",
                            Position = Vector2.new(InternalOutlineRainbow.Position.X + (InternalOutlineRainbow.Size.X / 2), InternalOutlineRainbow.Position.Y),
                            Center = true,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        function Colorpicker:Drop(State)
                            InternalInline.Visible = State
                            InternalOutline.Visible = State
                            InternalTitle.Visible = State
                            InternalBaseInline.Visible = State
                            InternalBase.Visible = State
                            InternalSaturation.Visible = State
                            InternalHueInline.Visible = State
                            InternalHue.Visible = State
                            InternalOutlineHex.Visible = State
                            InternalInlineHex.Visible = State
                            InternalHex.Visible = State
                            InternalInlineRGB.Visible = State
                            InternalOutlineRGB.Visible = State
                            InternalRGB.Visible = State
                            InternalInlineRainbow.Visible = State
                            InternalOutlineRainbow.Visible = State
                            InternalRainbow.Visible = State
                            InternalTopline.Visible = State
                            Cursor.Visible = State
                            InternalOutlineHuePicker.Visible = State
                            InternalHuePicker.Visible = State
                            Tab.Dropdowns[Side][ToggleTitle.Text] = State
                        end
                        Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                            if Type == "Accent" then
                                
                            elseif Type == "LightContrast" then
                                
                            elseif Type == "Text" then
                                InternalTitle.Color = Color
                            elseif Type == "Inline" then
                                InternalInline.Color = Color
                                InternalBaseInline.Color = Color
                                InternalHueInline.Color = Color
                                InternalInlineHex.Color = Color
                            elseif Type == "Outline" then
                                InternalOutline.Color = Color
                                InternalOutlineHex.Color = Color
                                InternalInline.Color = Color
                            end
                        end)
                        Colorpicker.Offsets.X = InternalBase.Position.X
                        Colorpicker.Offsets.Y = InternalBase.Position.Y
                        function Colorpicker:SetHue(Options)
                            local Percent = Options.Percent or Options.Value
        
                            Colorpicker.Colors.HSV[1] = Options.Value

                            local HSVColor = Color3.fromHSV(Colorpicker.Colors.HSV[1], Colorpicker.Colors.HSV[2], Colorpicker.Colors.HSV[3])
                            
                            InternalOutlineHuePicker.Position = Vector2.new(InternalOutline.Position.X + InternalBase.Size.X + 12, InternalHue.Position.Y + (InternalHue.Size.Y * Percent) - 4)
                            InternalHuePicker.Position = Vector2.new(InternalOutlineHuePicker.Position.X + 1, InternalOutlineHuePicker.Position.Y + 1)

                            InternalBase.Color = Color3.fromHSV(Colorpicker.Colors.HSV[1], 1, 1)

                            InternalHex.Text = ("#%s"):format(tostring(HSVColor:ToHex()))
                            
                            local CalculateRGB = Color3.fromRGB(math.floor((HSVColor.R * 255)), math.floor((HSVColor.G * 255)), math.floor((HSVColor.B * 255)))
                            InternalRGB.Text = ("%d, %d, %d"):format(math.floor(CalculateRGB.R * 255), math.floor(CalculateRGB.G * 255), math.floor(CalculateRGB.B * 255))

                            ColorpickerBase.Color = HSVColor

                            if not Options.Visual then
                                Library.Flags[Colorpicker.Flag] = HSVColor
                                Colorpicker.Callback(HSVColor)
                            end
                        end
                        function Colorpicker:RefreshHue()
                            local PercentHue = math.clamp(((UserInput:GetMouseLocation().Y) - InternalHue.Position.Y) / (InternalHue.Size.Y), 0, 1)
                            local ValueHue = math.floor((0 + (1 - 0) * PercentHue) * Colorpicker.Decimals) / Colorpicker.Decimals
                            ValueHue = math.clamp(ValueHue, 0, 1)
                            self:SetHue({
                                Value = ValueHue, 
                                Percent = PercentHue
                            })
                        end
                        function Colorpicker:SetSaturationX(Options)
                            local PercentX = Options.Percent or Options.Value

                            Colorpicker.Colors.HSV[2] = Options.Value

                            local HSVColor = Color3.fromHSV(Colorpicker.Colors.HSV[1], Colorpicker.Colors.HSV[2], Colorpicker.Colors.HSV[3])

                            Cursor.Position = Vector2.new(InternalBase.Position.X + (InternalBase.Size.X * PercentX) - 4, Colorpicker.Offsets.Y)
                            Colorpicker.Offsets.X = Cursor.Position.X

                            InternalHex.Text = ("#%s"):format(tostring(HSVColor:ToHex()))

                            local CalculateRGB = Color3.fromRGB(math.floor((HSVColor.R * 255)), math.floor((HSVColor.G * 255)), math.floor((HSVColor.B * 255)))
                            InternalRGB.Text = ("%d, %d, %d"):format(math.floor(CalculateRGB.R * 255), math.floor(CalculateRGB.G * 255), math.floor(CalculateRGB.B * 255))

                            ColorpickerBase.Color = HSVColor

                            if not Options.Visual then
                                Library.Flags[Colorpicker.Flag] = HSVColor
                                Colorpicker.Callback(HSVColor)
                            end
                        end
                        function Colorpicker:SetSaturationY(Options)
                            local PercentY = Options.Percent or 1 - Options.Value

                            Colorpicker.Colors.HSV[3] = Options.Value

                            local HSVColor = Color3.fromHSV(Colorpicker.Colors.HSV[1], Colorpicker.Colors.HSV[2], Colorpicker.Colors.HSV[3])
        
                            Cursor.Position = Vector2.new(Colorpicker.Offsets.X, InternalBase.Position.Y + (InternalBase.Size.Y * PercentY) - 4)
                            Colorpicker.Offsets.Y = Cursor.Position.Y

                            InternalHex.Text = ("#%s"):format(tostring(HSVColor:ToHex()))

                            local CalculateRGB = Color3.fromRGB(math.floor((HSVColor.R * 255)), math.floor((HSVColor.G * 255)), math.floor((HSVColor.B * 255)))
                            InternalRGB.Text = ("%d, %d, %d"):format(math.floor(CalculateRGB.R * 255), math.floor(CalculateRGB.G * 255), math.floor(CalculateRGB.B * 255))

                            ColorpickerBase.Color = HSVColor

                            if not Options.Visual then
                                Library.Flags[Colorpicker.Flag] = HSVColor
                                Colorpicker.Callback(HSVColor)
                            end
                        end
                        function Colorpicker:RefreshSaturation()
                            local PercentX = math.clamp((UserInput:GetMouseLocation().X - InternalSaturation.Position.X) / (InternalSaturation.Size.X), 0, 1)
                            local ValueX = math.floor((1 * PercentX) * Colorpicker.Decimals) / Colorpicker.Decimals
                            ValueX = math.clamp(ValueX, 0, 1)
                            self:SetSaturationX({
                                Value = ValueX, 
                                Percent = PercentX
                            })
                            local PercentY = math.clamp(((UserInput:GetMouseLocation().Y) - InternalSaturation.Position.Y) / (InternalSaturation.Size.Y), 0, 1)
                            local ValueY = 1 - math.floor((1 * PercentY) * Colorpicker.Decimals) / Colorpicker.Decimals
                            ValueY = math.clamp(ValueY, 0, 1)
                            self:SetSaturationY({
                                Value = ValueY, 
                                Percent = PercentY
                            })
                        end
                        Utility.AddConnection(UserInput.InputEnded, function(Input, Useless)
                            if Useless then
                                return
                            end
                            for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                if Index ~= ToggleTitle.Text and Value then
                                    return
                                end
                            end
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                Colorpicker.HueDragging = false
                                Colorpicker.SaturationDragging = false
                            end
                        end)
        
                        Utility.AddConnection(UserInput.InputChanged, function(Input, Useless)
                            if Useless then
                                return
                            end
                            if Input.UserInputType == Enum.UserInputType.MouseMovement then
                                for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                    if Index ~= ToggleTitle.Text and Value then
                                        return
                                    end
                                end
                                if Colorpicker.HueDragging then
                                    Colorpicker:RefreshHue()
                                elseif Colorpicker.SaturationDragging then
                                    Colorpicker:RefreshSaturation()
                                end
                            end
                        end)
                        Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                            if Useless then
                                return
                            end
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                    if Index ~= ToggleTitle.Text and Value then
                                        return
                                    end
                                end
                                if Utility.OnMouse(ColorpickerInline) then
                                    Colorpicker.Dropped = not Colorpicker.Dropped
                                    Tab.Dropdowns[Side][ToggleTitle.Text] = Colorpicker.Dropped
                                    Colorpicker:Drop(Colorpicker.Dropped)
                                elseif Utility.OnMouse(InternalSaturation) then
                                    Colorpicker:RefreshSaturation()
                                    Colorpicker.SaturationDragging = true
                                elseif Utility.OnMouse(InternalHue) then
                                    Colorpicker:RefreshHue()
                                    Colorpicker.HueDragging = true
                                elseif Utility.OnMouse(InternalInlineRainbow) then
                                    Colorpicker.Rainbow = not Colorpicker.Rainbow
                                    InternalRainbow.Color = Colorpicker.Rainbow and Library.Theme.Accent[1] or Library.Theme.Text
                                    if not Colorpicker.Rainbow then
                                        Colorpicker:SetHue({Value = Colorpicker.Colors.HSV[1]})
                                        Colorpicker:SetSaturationX({Value = Colorpicker.Colors.HSV[2]})
                                        Colorpicker:SetSaturationY({Value = Colorpicker.Colors.HSV[3]})
                                    end
                                else
                                    Colorpicker.Dropped = false
                                    Tab.Dropdowns[Side][ToggleTitle.Text] = Colorpicker.Dropped
                                    Colorpicker:Drop(Colorpicker.Dropped)
                                end
                            end
                        end)
                        Utility.AddConnection(RunService.RenderStepped, function(Input, Useless)
                            if Colorpicker.Rainbow then
                                Library.Flags[Colorpicker.Flag] = Color3.fromHSV(tick() % 2 / 2, 0.5, 1)
                                Colorpicker.Callback(Color3.fromHSV(tick() % 2 / 2, 0.5, 1))
                            end
                        end)
                        Colorpicker:SetHue({Value = Colorpicker.Colors.HSV[1]})
                        Colorpicker:SetSaturationX({Value = Colorpicker.Colors.HSV[2]})
                        Colorpicker:SetSaturationY({Value = Colorpicker.Colors.HSV[3]})
                        Tab["Render"][#Tab["Render"] + 1] = ColorpickerInline
                        Tab["Render"][#Tab["Render"] + 1] = ColorpickerOutline
                        Tab["Render"][#Tab["Render"] + 1] = ColorpickerBase
                        Tab["Render"][#Tab["Render"] + 1] = ColorpickerGradient
                        Colorpicker:Drop(false)
                        Colorpicker.TypeOf = "Colorpicker"
                        Library.Items[Colorpicker.Flag] = Colorpicker
                        table.insert(Library.Popups, Colorpicker)
                        return Colorpicker
                    end
                    function Toggle:Keybind(Options)
                        local Keybind: any = {
                            Axis = Section.ContentAxis,
                            Title = Options.Title or "LOL",
                            EnumType = (Options.Key or Enum.UserInputType.MouseButton2).EnumType == Enum.KeyCode and "KeyCode" or "UserInputType",
                            Key = Options.Key or Enum.UserInputType.MouseButton2,
                            StateType = Options.StateType or "Hold",
                            State = false,
                            Shorten = "",
                            Binding = false,
                            Dropped = false,
                            Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end,
                            ShowRender = "",
                            AddN = false
                        }
                        Options.Flag = Options.Flag or Utility.NextFlag()
                        Library.Flags[Options.Flag] = Keybind.State
                        if Keybind.StateType == "Always" then
                            Keybind.Callback(Keybind.State, Keybind.Key)
                            Library.Flags[Options.Flag] = true
                        end
                        Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                        Keybind.ShowRender = ("[%s] %s"):format(Keybind.Shorten, Options.Title)
                        local KeybindInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X - 40 - 6, SectionInline.Position.Y + Keybind.Axis + 2),
                            Size = Vector2.new(40, 14),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true
                        })
                        local KeybindOutline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(KeybindInline.Size.X - 2, KeybindInline.Size.Y - 2),
                            Position = Vector2.new(KeybindInline.Position.X + 1, KeybindInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true
                        })
                        local KeybindGradient = Utility.AddDrawing("Image", {
                            Size = Vector2.new(KeybindInline.Size.X - 2, KeybindInline.Size.Y - 2),
                            Position = Vector2.new(KeybindInline.Position.X + 1, KeybindInline.Position.Y + 1),
                            Data = Library.Theme.Gradient,
                            Transparency = 1,
                            Visible = true
                        })
                        local KeybindValue = Utility.AddDrawing("Text", {
                            Text = Keybind.Shorten,
                            Position = Vector2.new(KeybindInline.Position.X + (KeybindInline.Size.X / 2), KeybindInline.Position.Y),
                            Center = true,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 2
                        })
                        local KeybindHoldInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X + 2 - 6, SectionInline.Position.Y + Keybind.Axis + 2),
                            Size = Vector2.new(60, 16),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local KeybindHoldOutline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(KeybindHoldInline.Size.X - 2, KeybindHoldInline.Size.Y - 2),
                            Position = Vector2.new(KeybindHoldInline.Position.X + 1, KeybindHoldInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local KeybindHoldGradient = Utility.AddDrawing("Image", {
                            Size = Vector2.new(KeybindHoldInline.Size.X - 2, KeybindHoldInline.Size.Y - 2),
                            Position = Vector2.new(KeybindHoldInline.Position.X + 1, KeybindHoldInline.Position.Y + 1),
                            Data = Library.Theme.Gradient,
                            Transparency = 1,
                            Visible = true,
                            ZIndex = 3
                        })
                        local KeybindHoldValue = Utility.AddDrawing("Text", {
                            Text = "Hold",
                            Position = Vector2.new(KeybindHoldInline.Position.X + (KeybindHoldInline.Size.X / 2), KeybindHoldInline.Position.Y),
                            Center = true,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        local KeybindToggleInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X + 2 - 6, SectionInline.Position.Y + Keybind.Axis + 18),
                            Size = Vector2.new(60, 16),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true
                        })
                        local KeybindToggleOutline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(KeybindToggleInline.Size.X - 2, KeybindToggleInline.Size.Y - 2),
                            Position = Vector2.new(KeybindToggleInline.Position.X + 1, KeybindToggleInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local KeybindToggleGradient = Utility.AddDrawing("Image", {
                            Size = Vector2.new(KeybindToggleInline.Size.X - 2, KeybindToggleInline.Size.Y - 2),
                            Position = Vector2.new(KeybindToggleInline.Position.X + 1, KeybindToggleInline.Position.Y + 1),
                            Data = Library.Theme.Gradient,
                            Transparency = 1,
                            Visible = true,
                            ZIndex = 3
                        })
                        local KeybindToggleValue = Utility.AddDrawing("Text", {
                            Text = "Toggle",
                            Position = Vector2.new(KeybindToggleInline.Position.X + (KeybindToggleInline.Size.X / 2), KeybindToggleInline.Position.Y),
                            Center = true,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        local KeybindAlwaysInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X + 2 - 6, SectionInline.Position.Y + Keybind.Axis + 34),
                            Size = Vector2.new(60, 16),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local KeybindAlwaysOutline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(KeybindAlwaysInline.Size.X - 2, KeybindAlwaysInline.Size.Y - 2),
                            Position = Vector2.new(KeybindAlwaysInline.Position.X + 1, KeybindAlwaysInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local KeybindAlwaysGradient = Utility.AddDrawing("Image", {
                            Size = Vector2.new(KeybindAlwaysInline.Size.X - 2, KeybindAlwaysInline.Size.Y - 2),
                            Position = Vector2.new(KeybindAlwaysInline.Position.X + 1, KeybindAlwaysInline.Position.Y + 1),
                            Data = Library.Theme.Gradient,
                            Transparency = 1,
                            Visible = true,
                            ZIndex = 3
                        })
                        local KeybindAlwaysValue = Utility.AddDrawing("Text", {
                            Text = "Always",
                            Position = Vector2.new(KeybindAlwaysInline.Position.X + (KeybindAlwaysInline.Size.X / 2), KeybindAlwaysInline.Position.Y),
                            Center = true,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        function Keybind:Drop(State)
                            KeybindHoldInline.Visible = State
                            KeybindHoldOutline.Visible = State
                            KeybindHoldGradient.Visible = State
                            KeybindHoldValue.Visible = State
    
                            KeybindToggleInline.Visible = State
                            KeybindToggleOutline.Visible = State
                            KeybindToggleGradient.Visible = State
                            KeybindToggleValue.Visible = State
    
                            KeybindAlwaysInline.Visible = State
                            KeybindAlwaysOutline.Visible = State
                            KeybindAlwaysGradient.Visible = State
                            KeybindAlwaysValue.Visible = State
                        end
                        function Keybind:SetStateType(State)
                            if State == "Hold" then
                                Keybind.StateType = "Hold"
    
                                KeybindAlwaysValue.Color = Library.Theme.Text
                                KeybindToggleValue.Color = Library.Theme.Text
                                KeybindHoldValue.Color = Library.Theme.Accent[1]
                            elseif State == "Toggle" then
                                Keybind.StateType = "Toggle"
    
                                KeybindAlwaysValue.Color = Library.Theme.Text
                                KeybindToggleValue.Color = Library.Theme.Accent[1]
                                KeybindHoldValue.Color = Library.Theme.Text
                            else
                                Keybind.StateType = "Always"
    
                                KeybindAlwaysValue.Color = Library.Theme.Accent[1]
                                KeybindToggleValue.Color = Library.Theme.Text
                                KeybindHoldValue.Color = Library.Theme.Text
                            end
                        end
                        Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                if Keybind.Binding then
                                    Keybind.Binding = false
                                    Keybind.Key = Enum.UserInputType.MouseButton1
                                    Keybind.EnumType = "UserInputType"
                                    local Old = Keybind.Shorten
                                    Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                                    Window.BindList = string.gsub(Window.BindList, "\n%[" .. Old .. "%] " .. Options.Title, ("\n[%s] %s"):format(Keybind.Shorten, Options.Title))
                                    KeybindValue.Text = Keybind.Binding and "[...]" or Keybind.Shorten
                                end
                                if Utility.OnMouse(KeybindHoldInline) then
                                    Keybind:SetStateType("Hold")
                                end
                                if Utility.OnMouse(KeybindToggleInline) then
                                    Keybind:SetStateType("Toggle")
                                end
                                if Utility.OnMouse(KeybindAlwaysInline) then
                                    Keybind:SetStateType("Always")
                                end
                                if Utility.OnMouse(KeybindInline) then
                                    for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                        if Value then
                                            return
                                        end
                                    end
                                    if Keybind.Binding then
                                        Keybind.Binding = false
                                        KeybindValue.Text = Keybind.Shorten
                                        Keybind.ShowRender = ("[%s] %s"):format(Keybind.Shorten, Options.Title)
                                    else
                                        Keybind.Binding = true
                                        KeybindValue.Text = Keybind.Binding and "[...]" or Keybind.Shorten
                                    end
                                else
                                    if Utility.OnMouse(KeybindHoldInline) or Utility.OnMouse(KeybindToggleInline) or Utility.OnMouse(KeybindAlwaysInline) then
                                        return
                                    end
                                    Keybind.Dropped = false
                                    Keybind:Drop(Keybind.Dropped)
                                    Tab.Dropdowns["Left"][ToggleTitle.Text] = Keybind.Dropped
                                    Tab.Dropdowns["Right"][ToggleTitle.Text] = Keybind.Dropped
                                end
                            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                                if Keybind.Binding then
                                    Keybind.Binding = false
                                    Keybind.Key = Input.KeyCode
                                    Keybind.EnumType = "KeyCode"
                                    local Old = Keybind.Shorten
                                    Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                                    KeybindValue.Text = Keybind.Shorten
                                    Window.BindList = string.gsub(Window.BindList, "\n%[" .. Old .. "%] " .. Options.Title, ("\n[%s] %s"):format(Keybind.Shorten, Options.Title))
                                    Keybind.ShowRender = ("[%s] %s"):format(Keybind.Shorten, Options.Title)
                                end
                            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                                if Keybind.Binding then
                                    Keybind.Binding = false
                                    Keybind.Key = Enum.UserInputType.MouseButton2
                                    Keybind.EnumType = "UserInputType"
                                    local Old = Keybind.Shorten
                                    Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                                    KeybindValue.Text = Keybind.Shorten
                                    Window.BindList = string.gsub(Window.BindList, "\n%[" .. Old .. "%] " .. Options.Title, ("\n[%s] %s"):format(Keybind.Shorten, Options.Title))
                                    Keybind.ShowRender = ("[%s] %s"):format(Keybind.Shorten, Options.Title)
                                end
                                if Utility.OnMouse(KeybindInline) then
                                    Keybind.Dropped = not Keybind.Dropped
                                    Keybind:Drop(Keybind.Dropped)
                                    Tab.Dropdowns["Left"][ToggleTitle.Text] = Keybind.Dropped
                                    Tab.Dropdowns["Right"][ToggleTitle.Text] = Keybind.Dropped
                                end
                            end
                        end)
                        Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                            if (Keybind.EnumType == "KeyCode" and Input.KeyCode == Keybind.Key) or (Keybind.EnumType == "UserInputType" and Input.UserInputType == Keybind.Key) then
                                if Keybind.StateType ~= "Always" then
                                    if Keybind.StateType == "Toggle" then
                                        Keybind.State = not Keybind.State
                                    elseif Keybind.StateType == "Hold" then
                                        Keybind.State = true
                                    end
                                    if Keybind.State then
                                        if not string.find(Window.BindList, "\n%[" .. Keybind.Shorten .. "%] " .. Options.Title) then
                                            Window.BindList = Window.BindList .. "\n" .. Keybind.ShowRender
                                        end
                                    else
                                        Keybind:RemoveFromKeyBindGui()
                                    end
                                    Keybind.Callback(Keybind.State, Keybind.Key)
                                    Library.Flags[Options.Flag] = Keybind.State
                                end
                            end
                        end)
                        Utility.AddConnection(RunService.Stepped, function(Input, Useless)
                            if Keybind.StateType == "Always" then
                                Keybind.State = true
                                Keybind.Callback(Keybind.State, Keybind.Key)
                                Library.Flags[Options.Flag] = Keybind.State
                                if not string.find(Window.BindList, "\n%[" .. Keybind.Shorten .. "%] " .. Options.Title) then
                                    Window.BindList = Window.BindList .. "\n" .. Keybind.ShowRender
                                end
                            end
                        end)
                        Keybind:SetStateType(Keybind.StateType)
                        function Keybind:RemoveFromKeyBindGui()
                            Window.BindList = string.gsub(Window.BindList, "\n%[" .. Keybind.Shorten .. "%] " .. Options.Title, "")
                        end
                        Utility.AddConnection(UserInput.InputEnded, function(Input, Useless)
                            if (Keybind.EnumType == "KeyCode" and Input.KeyCode == Keybind.Key) or (Keybind.EnumType == "UserInputType" and Input.UserInputType == Keybind.Key) then
                                if Keybind.StateType ~= "Always" then
                                    if Keybind.StateType == "Hold" then
                                        Keybind.State = false
                                        Keybind:RemoveFromKeyBindGui()
                                        Keybind.Callback(Keybind.State, Keybind.Key)
                                        Library.Flags[Options.Flag] = Keybind.State
                                    end
                                end
                            end
                        end)
                        Keybind:Drop(false)
                        Tab["Render"][#Tab["Render"] + 1] = KeybindGradient
                        Tab["Render"][#Tab["Render"] + 1] = KeybindInline
                        Tab["Render"][#Tab["Render"] + 1] = KeybindOutline
                        Tab["Render"][#Tab["Render"] + 1] = KeybindValue
                        table.insert(Library.Popups, Keybind)
                        return Keybind
                    end
                    Toggle:Set(Toggle.Toggled)
                    Library.Items[Options.Flag] = Toggle
                    return Toggle
                end
                function Section:Slider(Options)
                    local Slider = {
                        TypeOf = "Slider",
                        Default = Options.Default or 100,
                        Decimals = Options.Decimals or 1,
                        Axis = Section.ContentAxis,
                        Max = Options.Max or 200,
                        Min = Options.Min or 0,
                        Dragging = false,
                        Symbol = Options.Symbol or "",
                        Current = Options.Default,
                        Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end
                    }
                    Options.Flag = Options.Flag or Utility.NextFlag()
                    Library.Flags[Options.Flag] = Slider.Default
                    if Slider.Min > Slider.Max then 
                        Slider.Min = Slider.Max - 1 
                    end
                    if Slider.Default < Slider.Min then 
                        Slider.Default = Slider.Min 
                    end
                    if Slider.Default > Slider.Max then 
                        Slider.Default = Slider.Max 
                    end
                    local SliderInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + 8, SectionInline.Position.Y + 23 + Slider.Axis + 15),
                        Size = Vector2.new(SectionOutline.Size.X - 12, 13),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local SliderOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(SliderInline.Size.X - 2, SliderInline.Size.Y - 2),
                        Position = Vector2.new(SliderInline.Position.X + 1, SliderInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local SliderBar = Utility.AddDrawing("Square", {
                        Size = Vector2.new(SliderOutline.Size.X / 2, SliderOutline.Size.Y),
                        Position = Vector2.new(SliderOutline.Position.X, SliderOutline.Position.Y),
                        Thickness = 0,
                        Transparency = 0.75,
                        Color = Library.Theme.Accent[1], --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local SliderGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(SliderInline.Size.X - 2, SliderInline.Size.Y - 2),
                        Position = Vector2.new(SliderInline.Position.X + 1, SliderInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 0.5,
                        Visible = false
                    })
                    local SliderTitle = Utility.AddDrawing("Text", {
                        Text = Options.Title,
                        Position = Vector2.new(SliderInline.Position.X, SliderInline.Position.Y - 17),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local SliderValue = Utility.AddDrawing("Text", {
                        Position = Vector2.new(SliderInline.Position.X + (SliderInline.Size.X / 2), SliderInline.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    SliderValue.Outline = true
                    Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                        if Type == "Accent" then
                            SliderBar.Color = Color
                        elseif Type == "LightContrast" then
                            SliderOutline.Color = Color
                        elseif Type == "Text" then
                            SliderTitle.Color = Color
                            SliderValue.Color = Color
                        elseif Type == "Inline" then
                            SliderInline.Color = Color
                        end
                    end)
                    function Slider:SetText(Text)
                        SliderTitle.Text = Text
                    end
    
                    function Slider:Set(GetValue, ConvertToMin)
                        if GetValue > Slider.Max then return end
                        if GetValue < Slider.Min then return end
                        
                        local Bracket = 1 / Slider.Decimals
                        local DecimalsCon = math.clamp(math.round(GetValue * Bracket) / Bracket, Slider.Min, Slider.Max)
                        local Percent = 1 - ((Slider.Max - DecimalsCon) / (Slider.Max - Slider.Min))
                        SliderBar.Size = Vector2.new(SliderOutline.Size.X * Percent, SliderOutline.Size.Y)
                        SliderValue.Text = ("%s%s/%s%s"):format(DecimalsCon, Slider.Symbol, Slider.Max, Slider.Symbol)
                        Library.Flags[Options.Flag] = GetValue
                        Slider.Callback(GetValue)
                    end
    
                    function Slider:SetMax(NewMax)
                        if NewMax < Slider.Current then Slider.Current = NewMax end
                        if Slider.Current < Slider.Min then return end
    
                        Slider.Max = NewMax
                        local DecimalsCon = math.clamp(math.round(Slider.Current * Slider.Decimals) / Slider.Decimals, Slider.Min, Slider.Max)
                        local Percent = 1 - ((Slider.Max - DecimalsCon) / (Slider.Max - Slider.Min))
                        SliderBar.Size = Vector2.new(SliderOutline.Size.X * Percent, SliderOutline.Size.Y)
                        SliderValue.Text = ("%s%s/%s%s"):format(DecimalsCon, Slider.Symbol, Slider.Max, Slider.Symbol)
                        Library.Flags[Options.Flag] = Slider.Current
                        Slider.Callback(Slider.Current)
                    end
    
                    function Slider:SetMin(NewMin)
                        Slider.Min = NewMin
                        if Slider.Current > Slider.Max then return end
                        if Slider.Current < Slider.Min then return end
    
                        local DecimalsCon = math.clamp(math.round(Slider.Current * Slider.Decimals) / Slider.Decimals, Slider.Min, Slider.Max)
                        local Percent = 1 - ((Slider.Max - DecimalsCon) / (Slider.Max - Slider.Min))
                        SliderBar.Size = Vector2.new(SliderOutline.Size.X * Percent, SliderOutline.Size.Y)
                        SliderValue.Text = ("%s%s/%s%s"):format(DecimalsCon, Slider.Symbol, Slider.Max, Slider.Symbol)
                        Library.Flags[Options.Flag] = Slider.Current
                        Slider.Callback(Slider.Current)
                    end
    
                    function Slider:Refresh()
                        local Percent = math.clamp((UserInput:GetMouseLocation().X - SliderOutline.Position.X) / (SliderOutline.Size.X), 0, 1)
                        local Bracket = 1 / Slider.Decimals
                        local Value = math.floor((Slider.Min + (Slider.Max - Slider.Min) * Percent) * Bracket) / Bracket
                        Value = math.clamp(Value, Slider.Min, Slider.Max)
                        Slider:Set(Value)
                    end
    
                    Slider:Set(Slider.Default)
                    Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                        
                        for Index, Value in pairs(Tab.Dropdowns[Side]) do
                            if Value then
                                return
                            end
                        end
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and Utility.OnMouse(SliderOutline) then
                            Slider:Refresh()
                            Slider.Dragging = true
                        end
                    end)
                    Utility.AddConnection(UserInput.InputEnded, function(Input, Useless)
                        
                        for Index, Value in pairs(Tab.Dropdowns[Side]) do
                            if Value then
                                return
                            end
                        end
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Slider.Dragging = false
                        end
                    end)
                    Utility.AddConnection(UserInput.InputChanged, function(Input, Useless)
                        if Utility.OnMouse(SliderInline) then
                            SliderInline.Color = Library.Theme.Accent[1]
                        else
                            SliderInline.Color = Library.Theme.Inline
                        end
                        
                        for Index, Value in pairs(Tab.Dropdowns[Side]) do
                            if Value then
                                return
                            end
                        end
                        if Input.UserInputType == Enum.UserInputType.MouseMovement and Slider.Dragging then
                            Slider:Refresh()
                        end
                    end)
                    Section.ContentAxis = Section.ContentAxis + SliderOutline.Size.Y + 24
                    Tab.SectionAxis = {
                        Side == "Left" and Tab.SectionAxis[1] + SliderOutline.Size.Y + 24 or Tab.SectionAxis[1], 
                        Side == "Right" and Tab.SectionAxis[2] + SliderOutline.Size.Y + 24 or Tab.SectionAxis[2]
                    }
                    self:UpdateSizeY(Section.ContentAxis + SliderOutline.Size.Y)
                    Tab["Render"][#Tab["Render"] + 1] = SliderInline
                    Tab["Render"][#Tab["Render"] + 1] = SliderOutline
                    Tab["Render"][#Tab["Render"] + 1] = SliderTitle
                    Tab["Render"][#Tab["Render"] + 1] = SliderGradient
                    Tab["Render"][#Tab["Render"] + 1] = SliderBar
                    Tab["Render"][#Tab["Render"] + 1] = SliderValue
                    Library.Items[Options.Flag] = Slider
                    return Slider
                end
                function Section:Button(Options)
                    local Button = {
                        Title = Options.Title or "LMAO",
                        Axis = Section.ContentAxis,
                        Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end
                    }
                    local ButtonInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + 8, SectionInline.Position.Y + 24 + Button.Axis),
                        Size = Vector2.new(SectionOutline.Size.X - 12, 18),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local ButtonOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(ButtonInline.Size.X - 2, ButtonInline.Size.Y - 2),
                        Position = Vector2.new(ButtonInline.Position.X + 1, ButtonInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local ButtonGradient = Utility.AddDrawing("Image", {
                        Size = ButtonOutline.Size,
                        Position = ButtonOutline.Position,
                        Data = Library.Theme.Gradient,
                        Transparency = 0.5,
                        Visible = true
                    })
                    local ButtonTitle = Utility.AddDrawing("Text", {
                        Text = Options.Title,
                        Position = Vector2.new(ButtonInline.Position.X + (ButtonInline.Size.X / 2), ButtonInline.Position.Y + 2),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                        if Type == "LightContrast" then
                            ButtonOutline.Color = Color
                        elseif Type == "Text" then
                            ButtonTitle.Color = Color
                        elseif Type == "Inline" then
                            ButtonInline.Color = Color
                        end
                    end)
                    Utility.AddConnection(UserInput.InputChanged, function(Input, Useless)
                        if Utility.OnMouse(ButtonInline) then
                            ButtonInline.Color = Library.Theme.Accent[1]
                        else
                            ButtonInline.Color = Library.Theme.Inline
                        end
                    end)
                    function Button:EmitEffect()
                        ButtonOutline.Color = Library.Theme.LightContrast
                        delay(0.1, function()
                            pcall(function()
                                ButtonOutline.Color = Library.Theme.DarkContrast
                            end)
                        end)
                    end
                    Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                        
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and Utility.OnMouse(ButtonOutline) then
                            for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                if Value then
                                    return
                                end
                            end
                            Button:EmitEffect()
                            Button.Callback()
                        end
                    end)
                    Section.ContentAxis = Section.ContentAxis + ButtonOutline.Size.Y + 6
                    Tab.SectionAxis = {
                        Side == "Left" and Tab.SectionAxis[1] + ButtonOutline.Size.Y + 6 or Tab.SectionAxis[1], 
                        Side == "Right" and Tab.SectionAxis[2] + ButtonOutline.Size.Y + 6 or Tab.SectionAxis[2]
                    }
                    self:UpdateSizeY(Section.ContentAxis + ButtonOutline.Size.Y)
                    Tab["Render"][#Tab["Render"] + 1] = ButtonInline
                    Tab["Render"][#Tab["Render"] + 1] = ButtonGradient
                    Tab["Render"][#Tab["Render"] + 1] = ButtonOutline
                    Tab["Render"][#Tab["Render"] + 1] = ButtonTitle
                    return Button
                end
                function Section:Colorpicker(Options)
                    local Colorpicker = {
                        Axis = Section.ContentAxis,
                        Color = Options.Color,
                        HexColor = Options.Color:ToHex(),
                        Dropped = false,
                        Offsets = {
                            X = 0,
                            Y = 0
                        },
                        Colors = {
                            HSV = {1, 1, 1}
                        },
                        SaturationDragging = false,
                        HueDragging = false,
                        Decimals = 50,
                        Rainbow = false,
                        Flag = Options.Flag or Utility.NextFlag(),
                        Title = Options.Title or "Color Picker",
                        Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end
                    }
                    Library.Flags[Colorpicker.Flag] = Colorpicker.HexColor
                    local H, S, V = Colorpicker.Color:ToHSV()
                    Colorpicker.Colors.HSV[1] = H
                    Colorpicker.Colors.HSV[2] = S
                    Colorpicker.Colors.HSV[3] = V
                    local ColorpickerTitle = Utility.AddDrawing("Text", {
                        Text = Options.Title,
                        Position = Vector2.new(SectionInline.Position.X + 8, SectionInline.Position.Y + 23 + Colorpicker.Axis),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local ColorpickerInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new((SectionInline.Position.X + SectionInline.Size.X) - 38, SectionInline.Position.Y + 23 + Colorpicker.Axis),
                        Size = Vector2.new(30, 12),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local ColorpickerOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(ColorpickerInline.Size.X - 2, ColorpickerInline.Size.Y - 2),
                        Position = Vector2.new(ColorpickerInline.Position.X + 1, ColorpickerInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local ColorpickerBase = Utility.AddDrawing("Square", {
                        Size = Vector2.new(ColorpickerInline.Size.X - 2, ColorpickerInline.Size.Y - 2),
                        Position = Vector2.new(ColorpickerInline.Position.X + 1, ColorpickerInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Colorpicker.Color, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local ColorpickerGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(ColorpickerInline.Size.X - 2, ColorpickerInline.Size.Y - 2),
                        Position = Vector2.new(ColorpickerInline.Position.X + 1, ColorpickerInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 0.5,
                        Visible = true
                    })
                    local InternalInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new((ColorpickerInline.Position.X - 225) + ColorpickerInline.Size.X, ColorpickerInline.Position.Y + 18),
                        Size = Vector2.new(225, 250),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(InternalInline.Size.X - 2, InternalInline.Size.Y - 2),
                        Position = Vector2.new(InternalInline.Position.X + 1, InternalInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalTopline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(InternalOutline.Size.X, 1),
                        Position = Vector2.new(InternalOutline.Position.X, InternalOutline.Position.Y),
                        Thickness = 0,
                        Color = Library.Theme.Accent[1],
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                        if Type == "Accent" then
                            InternalTopline.Color = Color
                        end
                    end)
                    local InternalTitle = Utility.AddDrawing("Text", {
                        Text = Options.Title,
                        Position = Vector2.new(InternalOutline.Position.X + 8, InternalOutline.Position.Y + 6),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 3
                    })
                    local InternalBaseInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(InternalOutline.Position.X + 8, InternalOutline.Position.Y + 25),
                        Size = Vector2.new(192, 192),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalBase = Utility.AddDrawing("Square", {
                        Size = Vector2.new(192 - 4, 192 - 4),
                        Position = Vector2.new(InternalBaseInline.Position.X + 2, InternalBaseInline.Position.Y + 2),
                        Thickness = 0,
                        Color = Options.Color, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalSaturation = Utility.AddDrawing("Image", {
                        Size = Vector2.new(196 - 2, 196 - 2),
                        Position = Vector2.new(InternalOutline.Position.X + 8 + 1, InternalOutline.Position.Y + 25 + 1),
                        Data = Library.Theme.Saturation,
                        Transparency = 1,
                        Visible = true,
                        ZIndex = 3
                    })
                    local InternalHueInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(InternalOutline.Position.X + InternalBase.Size.X + 14, InternalOutline.Position.Y + 26),
                        Size = Vector2.new(16, 196),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalHue = Utility.AddDrawing("Image", {
                        Size = Vector2.new(InternalHueInline.Size.X - 2, InternalHueInline.Size.Y - 2),
                        Position = Vector2.new(InternalHueInline.Position.X + 1, InternalHueInline.Position.Y + 1),
                        Data = Library.Theme.Hue,
                        Transparency = 1,
                        Visible = true,
                        ZIndex = 3
                    })
                    local InternalOutlineHuePicker = Utility.AddDrawing("Square", {
                        Position = Vector2.new(InternalOutline.Position.X + InternalBase.Size.X + 12, InternalOutline.Position.Y + 26),
                        Size = Vector2.new(InternalHueInline.Size.X + 2, 6),
                        Thickness = 2,
                        Color = Library.Theme.Outline,
                        Visible = true,
                        Filled = false,
                        ZIndex = 3
                    })
                    local InternalHuePicker = Utility.AddDrawing("Square", {
                        Position = Vector2.new(InternalOutlineHuePicker.Position.X + 1, InternalOutlineHuePicker.Position.Y + 1),
                        Size = Vector2.new(InternalOutlineHuePicker.Size.X - 2, InternalOutlineHuePicker.Size.Y - 2),
                        Thickness = 2,
                        Color = Library.Theme.Text,
                        Visible = true,
                        Filled = false,
                        ZIndex = 3
                    })
                    local Cursor = Utility.AddDrawing("Image", {
                        Size = Vector2.new(6, 6),
                        Data = Library.Theme.SaturationCursor,
                        Transparency = 1,
                        Visible = true,
                        ZIndex = 6
                    })
                    local InternalInlineHex = Utility.AddDrawing("Square", {
                        Size = Vector2.new(80 - 2, 18 - 2),
                        Position = Vector2.new(InternalOutline.Position.X + 8 + 1, InternalOutline.Position.Y + InternalSaturation.Size.Y + 30 + 1),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalOutlineHex = Utility.AddDrawing("Square", {
                        Size = Vector2.new(InternalInlineHex.Size.X - 2, InternalInlineHex.Size.Y - 2),
                        Position = Vector2.new(InternalInlineHex.Position.X + 1, InternalInlineHex.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalHex = Utility.AddDrawing("Text", {
                        Text = ("#%s"):format(tostring(Colorpicker.HexColor)),
                        Position = Vector2.new(InternalOutlineHex.Position.X + (InternalOutlineHex.Size.X / 2), InternalOutlineHex.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 3
                    })
                    local InternalInlineRGB = Utility.AddDrawing("Square", {
                        Size = Vector2.new(130 - 2, 18 - 2),
                        Position = Vector2.new(InternalOutline.Position.X + 90 + 1, InternalOutline.Position.Y + InternalSaturation.Size.Y + 30 + 1),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalOutlineRGB = Utility.AddDrawing("Square", {
                        Size = Vector2.new(InternalInlineRGB.Size.X - 2, InternalInlineRGB.Size.Y - 2),
                        Position = Vector2.new(InternalInlineRGB.Position.X + 1, InternalInlineRGB.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalRGB = Utility.AddDrawing("Text", {
                        Text = ("%d, %d, %d"):format(math.floor(Colorpicker.Color.R * 255), math.floor(Colorpicker.Color.G * 255), math.floor(Colorpicker.Color.B * 255)),
                        Position = Vector2.new(InternalOutlineRGB.Position.X + (InternalOutlineRGB.Size.X / 2), InternalOutlineRGB.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 3
                    })
                    local InternalInlineRainbow = Utility.AddDrawing("Square", {
                        Size = Vector2.new(100 - 2, 18 - 2),
                        Position = Vector2.new((InternalOutline.Position.X + InternalOutline.Size.X) - 100 - 2 + 1, InternalOutline.Position.Y + 4 + 1),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalOutlineRainbow = Utility.AddDrawing("Square", {
                        Size = Vector2.new(InternalInlineRainbow.Size.X - 2, InternalInlineRainbow.Size.Y - 2),
                        Position = Vector2.new(InternalInlineRainbow.Position.X + 1, InternalInlineRainbow.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true,
                        ZIndex = 3
                    })
                    local InternalRainbow = Utility.AddDrawing("Text", {
                        Text = "Rainbow",
                        Position = Vector2.new(InternalOutlineRainbow.Position.X + (InternalOutlineRainbow.Size.X / 2), InternalOutlineRainbow.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 3
                    })
                    function Colorpicker:Drop(State)
                        InternalInline.Visible = State
                        InternalOutline.Visible = State
                        InternalTitle.Visible = State
                        InternalBaseInline.Visible = State
                        InternalBase.Visible = State
                        InternalSaturation.Visible = State
                        InternalHueInline.Visible = State
                        InternalHue.Visible = State
                        InternalOutlineHex.Visible = State
                        InternalInlineHex.Visible = State
                        InternalHex.Visible = State
                        InternalInlineRGB.Visible = State
                        InternalOutlineRGB.Visible = State
                        InternalRGB.Visible = State
                        InternalInlineRainbow.Visible = State
                        InternalOutlineRainbow.Visible = State
                        InternalRainbow.Visible = State
                        InternalTopline.Visible = State
                        Cursor.Visible = State
                        InternalOutlineHuePicker.Visible = State
                        InternalHuePicker.Visible = State
                        Tab.Dropdowns[Side][ColorpickerTitle.Text] = State
                    end
                    Colorpicker.Offsets.X = InternalBase.Position.X
                    Colorpicker.Offsets.Y = InternalBase.Position.Y
                    function Colorpicker:SetHue(Options)
                        local Percent = Options.Percent or Options.Value
    
                        Colorpicker.Colors.HSV[1] = Options.Value

                        local HSVColor = Color3.fromHSV(Colorpicker.Colors.HSV[1], Colorpicker.Colors.HSV[2], Colorpicker.Colors.HSV[3])
                        
                        InternalOutlineHuePicker.Position = Vector2.new(InternalOutline.Position.X + InternalBase.Size.X + 12, InternalHue.Position.Y + (InternalHue.Size.Y * Percent) - 4)
                        InternalHuePicker.Position = Vector2.new(InternalOutlineHuePicker.Position.X + 1, InternalOutlineHuePicker.Position.Y + 1)

                        InternalBase.Color = Color3.fromHSV(Colorpicker.Colors.HSV[1], 1, 1)

                        InternalHex.Text = ("#%s"):format(tostring(HSVColor:ToHex()))
                        
                        local CalculateRGB = Color3.fromRGB(math.floor((HSVColor.R * 255)), math.floor((HSVColor.G * 255)), math.floor((HSVColor.B * 255)))
                        InternalRGB.Text = ("%d, %d, %d"):format(math.floor(CalculateRGB.R * 255), math.floor(CalculateRGB.G * 255), math.floor(CalculateRGB.B * 255))

                        ColorpickerBase.Color = HSVColor

                        if not Options.Visual then
                            Library.Flags[Colorpicker.Flag] = HSVColor
                            Colorpicker.Callback(HSVColor)
                        end
                    end
                    function Colorpicker:RefreshHue()
                        local PercentHue = math.clamp(((UserInput:GetMouseLocation().Y) - InternalHue.Position.Y) / (InternalHue.Size.Y), 0, 1)
                        local ValueHue = math.floor((0 + (1 - 0) * PercentHue) * Colorpicker.Decimals) / Colorpicker.Decimals
                        ValueHue = math.clamp(ValueHue, 0, 1)
                        self:SetHue({
                            Value = ValueHue, 
                            Percent = PercentHue
                        })
                    end
                    function Colorpicker:SetSaturationX(Options)
                        local PercentX = Options.Percent or Options.Value

                        Colorpicker.Colors.HSV[2] = Options.Value

                        local HSVColor = Color3.fromHSV(Colorpicker.Colors.HSV[1], Colorpicker.Colors.HSV[2], Colorpicker.Colors.HSV[3])

                        Cursor.Position = Vector2.new(InternalBase.Position.X + (InternalBase.Size.X * PercentX) - 4, Colorpicker.Offsets.Y)
                        Colorpicker.Offsets.X = Cursor.Position.X

                        InternalHex.Text = ("#%s"):format(tostring(HSVColor:ToHex()))

                        local CalculateRGB = Color3.fromRGB(math.floor((HSVColor.R * 255)), math.floor((HSVColor.G * 255)), math.floor((HSVColor.B * 255)))
                        InternalRGB.Text = ("%d, %d, %d"):format(math.floor(CalculateRGB.R * 255), math.floor(CalculateRGB.G * 255), math.floor(CalculateRGB.B * 255))

                        ColorpickerBase.Color = HSVColor

                        if not Options.Visual then
                            Library.Flags[Colorpicker.Flag] = HSVColor
                            Colorpicker.Callback(HSVColor)
                        end
                    end
                    function Colorpicker:SetSaturationY(Options)
                        local PercentY = Options.Percent or 1 - Options.Value

                        Colorpicker.Colors.HSV[3] = Options.Value

                        local HSVColor = Color3.fromHSV(Colorpicker.Colors.HSV[1], Colorpicker.Colors.HSV[2], Colorpicker.Colors.HSV[3])
    
                        Cursor.Position = Vector2.new(Colorpicker.Offsets.X, InternalBase.Position.Y + (InternalBase.Size.Y * PercentY) - 4)
                        Colorpicker.Offsets.Y = Cursor.Position.Y

                        InternalHex.Text = ("#%s"):format(tostring(HSVColor:ToHex()))

                        local CalculateRGB = Color3.fromRGB(math.floor((HSVColor.R * 255)), math.floor((HSVColor.G * 255)), math.floor((HSVColor.B * 255)))
                        InternalRGB.Text = ("%d, %d, %d"):format(math.floor(CalculateRGB.R * 255), math.floor(CalculateRGB.G * 255), math.floor(CalculateRGB.B * 255))

                        ColorpickerBase.Color = HSVColor

                        if not Options.Visual then
                            Library.Flags[Colorpicker.Flag] = HSVColor
                            Colorpicker.Callback(HSVColor)
                        end
                    end
                    function Colorpicker:RefreshSaturation()
                        local PercentX = math.clamp((UserInput:GetMouseLocation().X - InternalSaturation.Position.X) / (InternalSaturation.Size.X), 0, 1)
                        local ValueX = math.floor((1 * PercentX) * Colorpicker.Decimals) / Colorpicker.Decimals
                        ValueX = math.clamp(ValueX, 0, 1)
                        self:SetSaturationX({
                            Value = ValueX, 
                            Percent = PercentX
                        })
                        local PercentY = math.clamp(((UserInput:GetMouseLocation().Y) - InternalSaturation.Position.Y) / (InternalSaturation.Size.Y), 0, 1)
                        local ValueY = 1 - math.floor((1 * PercentY) * Colorpicker.Decimals) / Colorpicker.Decimals
                        ValueY = math.clamp(ValueY, 0, 1)
                        self:SetSaturationY({
                            Value = ValueY, 
                            Percent = PercentY
                        })
                    end
                    Utility.AddConnection(UserInput.InputEnded, function(Input, Useless)
                        
                        for Index, Value in pairs(Tab.Dropdowns[Side]) do
                            if Index ~= ColorpickerTitle.Text and Value then
                                return
                            end
                        end
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Colorpicker.HueDragging = false
                            Colorpicker.SaturationDragging = false
                        end
                    end)
    
                    Utility.AddConnection(UserInput.InputChanged, function(Input, Useless)
                        if Utility.OnMouse(ColorpickerInline) then
                            ColorpickerInline.Color = Library.Theme.Accent[1]
                        else
                            ColorpickerInline.Color = Library.Theme.Inline
                        end
                        if Utility.OnMouse(ColorpickerInline) then
                            ColorpickerInline.Color = Library.Theme.Accent[1]
                        else
                            ColorpickerInline.Color = Library.Theme.Inline
                        end
                        
                        if Input.UserInputType == Enum.UserInputType.MouseMovement then
                            for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                if Index ~= ColorpickerTitle.Text and Value then
                                    return
                                end
                            end
                            if Colorpicker.HueDragging then
                                Colorpicker:RefreshHue()
                            elseif Colorpicker.SaturationDragging then
                                Colorpicker:RefreshSaturation()
                            end
                        end
                    end)
                    Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                        
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                if Index ~= ColorpickerTitle.Text and Value then
                                    return
                                end
                            end
                            if Utility.OnMouse(ColorpickerInline) then
                                Colorpicker.Dropped = not Colorpicker.Dropped
                                Tab.Dropdowns[Side][ColorpickerTitle.Text] = Colorpicker.Dropped
                                Colorpicker:Drop(Colorpicker.Dropped)
                            elseif Utility.OnMouse(InternalSaturation) then
                                Colorpicker:RefreshSaturation()
                                Colorpicker.SaturationDragging = true
                            elseif Utility.OnMouse(InternalHue) then
                                Colorpicker:RefreshHue()
                                Colorpicker.HueDragging = true
                            elseif Utility.OnMouse(InternalInlineRainbow) then
                                Colorpicker.Rainbow = not Colorpicker.Rainbow
                                InternalRainbow.Color = Colorpicker.Rainbow and Library.Theme.Accent[1] or Library.Theme.Text
                                if not Colorpicker.Rainbow then
                                    Colorpicker:SetHue({Value = Colorpicker.Colors.HSV[1]})
                                    Colorpicker:SetSaturationX({Value = Colorpicker.Colors.HSV[2]})
                                    Colorpicker:SetSaturationY({Value = Colorpicker.Colors.HSV[3]})
                                end
                            else
                                Colorpicker.Dropped = false
                                Tab.Dropdowns[Side][ColorpickerTitle.Text] = Colorpicker.Dropped
                                Colorpicker:Drop(Colorpicker.Dropped)
                            end
                        end
                    end)
                    Utility.AddConnection(RunService.RenderStepped, function(Input, Useless)
                        if Colorpicker.Rainbow then
                            Library.Flags[Colorpicker.Flag] = Color3.fromHSV(tick() % 2 / 2, 0.5, 1)
                            Colorpicker.Callback(Color3.fromHSV(tick() % 2 / 2, 0.5, 1))
                        end
                    end)
                    Colorpicker:SetHue({Value = Colorpicker.Colors.HSV[1]})
                    Colorpicker:SetSaturationX({Value = Colorpicker.Colors.HSV[2]})
                    Colorpicker:SetSaturationY({Value = Colorpicker.Colors.HSV[3]})
                    Section.ContentAxis = Section.ContentAxis + ColorpickerBase.Size.Y + 10
                    Tab.SectionAxis = {
                        Side == "Left" and Tab.SectionAxis[1] +  ColorpickerBase.Size.Y + 10 or Tab.SectionAxis[1], 
                        Side == "Right" and Tab.SectionAxis[2] +  ColorpickerBase.Size.Y + 10 or Tab.SectionAxis[2]
                    }
                    self:UpdateSizeY(Section.ContentAxis + ColorpickerBase.Size.Y)
                    Tab["Render"][#Tab["Render"] + 1] = ColorpickerTitle
                    Tab["Render"][#Tab["Render"] + 1] = ColorpickerInline
                    Tab["Render"][#Tab["Render"] + 1] = ColorpickerOutline
                    Tab["Render"][#Tab["Render"] + 1] = ColorpickerBase
                    Tab["Render"][#Tab["Render"] + 1] = ColorpickerGradient
                    Colorpicker:Drop(false)
                    Colorpicker.TypeOf = "Colorpicker"
                        Library.Items[Colorpicker.Flag] = Colorpicker
                    table.insert(Library.Popups, Colorpicker)
                    return Colorpicker
                end
                function Section:Dropdown(Options)
                    local Dropdown = {
                        TypeOf = "Dropdown",
                        Axis = Section.ContentAxis,
                        List = Options.List or {""},
                        ListRender = {
                            Texts = {},
                            Objects = {}
                        }, 
                        Show = true,
                        Selected = Options.Default or Options.List[1],
                        BaseSize = 16,
                        Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end
                    }
                    Options.Flag = Options.Flag or Utility.NextFlag()
                    Library.Flags[Options.Flag] = Dropdown.Selected
                    local DropdownInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + 8, SectionInline.Position.Y + 23 + Dropdown.Axis + 16),
                        Size = Vector2.new(SectionOutline.Size.X - 12, Dropdown.BaseSize),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local DropdownOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(DropdownInline.Size.X - 2, DropdownInline.Size.Y - 2),
                        Position = Vector2.new(DropdownInline.Position.X + 1, DropdownInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local DropdownGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(DropdownInline.Size.X - 2, DropdownInline.Size.Y - 2),
                        Position = Vector2.new(DropdownInline.Position.X + 1, DropdownInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 1,
                        Visible = true
                    })
                    local DropdownTitle = Utility.AddDrawing("Text", {
                        Text = Options.Title,
                        Position = Vector2.new(DropdownInline.Position.X + 2, DropdownInline.Position.Y - 16),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local DropdownValue = Utility.AddDrawing("Text", {
                        Text = Options.Default,
                        Position = Vector2.new(DropdownOutline.Position.X + 4, DropdownOutline.Position.Y),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local DropdownSymbol = Utility.AddDrawing("Text", {
                        Text = "+",
                        Position = Vector2.new(DropdownOutline.Position.X + DropdownOutline.Size.X - 12, DropdownOutline.Position.Y),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local DropdownDetect = Utility.AddDrawing("Square", {
                        Thickness = 0,
                        Transparency = 0,
                        Color = Library.Theme.Hitbox, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    function Dropdown:Set(Selected)
                        for Index, Value in pairs(Dropdown.ListRender.Texts) do
                            Value.Color = Library.Theme.Text
                        end
                        Dropdown.ListRender.Texts[Selected].Color = Library.Theme.Accent[1]
                        Dropdown.Selected = Selected
                        DropdownValue.Text = Selected
                        Dropdown.Callback(Dropdown.Selected)
                        Library.Flags[Options.Flag] = Dropdown.Selected
                    end
                    function Dropdown:ShowList(State)
                        Dropdown.Show = State
                        DropdownSymbol.Text = State and "-" or "+"
                        for Index, Value in pairs(Dropdown.ListRender.Objects) do
                            Value.Visible = State
                        end
                        for Index, Value in pairs(Dropdown.ListRender.Texts) do
                            Value.Visible = State
                        end
                        Tab.Dropdowns[Side][DropdownTitle.Text] = State
                    end
                    Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                        if Type == "Accent" then
                            Dropdown.ListRender.Texts[Dropdown.Selected].Color = Color
                        elseif Type == "LightContrast" then
                            DropdownOutline.Color = Color
                        elseif Type == "Text" then
                            DropdownTitle.Color = Color
                            DropdownSymbol.Color = Color
                            DropdownValue.Color = Color
                        elseif Type == "Inline" then
                            DropdownInline.Color = Color
                        end
                    end)
                    for Index, Value in pairs(Options.List) do
                        local SelectionInline = Utility.AddDrawing("Square", {
                            Position = Vector2.new(DropdownInline.Position.X, (DropdownInline.Position.Y + (Index * (18)))),
                            Size = Vector2.new(SectionOutline.Size.X - 12, 18),
                            Thickness = 0,
                            Color = Library.Theme.Inline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local SelectionOutline = Utility.AddDrawing("Square", {
                            Size = Vector2.new(SelectionInline.Size.X - 2, SelectionInline.Size.Y - 2),
                            Position = Vector2.new(SelectionInline.Position.X + 1, SelectionInline.Position.Y + 1),
                            Thickness = 0,
                            Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                            Visible = true,
                            Filled = true,
                            ZIndex = 3
                        })
                        local SelectionGradient = Utility.AddDrawing("Image", {
                            Size = Vector2.new(SelectionInline.Size.X - 2, SelectionInline.Size.Y - 2),
                            Position = Vector2.new(SelectionInline.Position.X + 1, SelectionInline.Position.Y + 1),
                            Data = Library.Theme.Gradient,
                            Transparency = 1,
                            Visible = true,
                            ZIndex = 3
                        })
                        local SelectionTitle = Utility.AddDrawing("Text", {
                            Text = Value,
                            Position = Vector2.new(SelectionInline.Position.X + 6, SelectionInline.Position.Y + 3),
                            Center = false,
                            Outline = false,
                            Font = Library.Theme.Font,
                            Size = Library.Theme.TextSize,
                            Color = Library.Theme.Text,
                            Visible = true,
                            ZIndex = 3
                        })
                        Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                            if Type == "LightContrast" then
                                SelectionOutline.Color = Color
                            elseif Type == "Text" then
                                SelectionTitle.Color = Color
                            elseif Type == "Inline" then
                                SelectionInline.Color = Color
                            end
                        end)
                        Utility.AddConnection(UserInput.InputChanged, function(Input, Useless)
                            if Input.UserInputType == Enum.UserInputType.MouseMovement then
                                if Utility.OnMouse(SelectionInline) then
                                    SelectionInline.Color = Library.Theme.Accent[1]
                                else
                                    SelectionInline.Color = Library.Theme.Inline
                                end
                            end
                        end)
                        Dropdown.ListRender.Objects[#Dropdown.ListRender.Objects + 1] = SelectionInline
                        Dropdown.ListRender.Objects[#Dropdown.ListRender.Objects + 1] = SelectionOutline
                        Dropdown.ListRender.Objects[#Dropdown.ListRender.Objects + 1] = SelectionGradient
                        Dropdown.ListRender.Texts[Value] = SelectionTitle
                        Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                            if Useless then
                                return
                            end
                            for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                if Index ~= DropdownTitle.Text and Value then
                                    return
                                end
                            end
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Utility.OnMouse(SelectionInline) then
                                Dropdown:Set(Value)
                            end
                        end)
                    end
                    DropdownDetect.Position = Vector2.new(DropdownInline.Position.X, DropdownInline.Position.Y + DropdownInline.Size.Y)
                    DropdownDetect.Size = Vector2.new(SectionOutline.Size.X - 12, (#Options.List * Dropdown.BaseSize) + Dropdown.BaseSize)
                    Dropdown:Set(Dropdown.Selected)
                    Dropdown:ShowList(false)
                    Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                        
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if Utility.OnMouse(DropdownInline) then
                                for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                    if Index ~= DropdownTitle.Text and Value then
                                        return
                                    end
                                end
                                Dropdown.Show = not Dropdown.Show
                                Tab.Dropdowns[Side][DropdownTitle.Text] = Dropdown.Show
                                DropdownSymbol.Text = Dropdown.Show and "-" or "+"
                                Dropdown:ShowList(Dropdown.Show)
                            elseif not Utility.OnMouse(DropdownDetect) then
                                Dropdown.Show = false
                                Tab.Dropdowns[Side][DropdownTitle.Text] = Dropdown.Show
                                DropdownSymbol.Text = "+"
                                Dropdown:ShowList(false)
                            end
                        end
                    end)
                    Utility.AddConnection(UserInput.InputChanged, function(Input, Useless)
                        if Input.UserInputType == Enum.UserInputType.MouseMovement then
                            if Utility.OnMouse(DropdownInline) then
                                DropdownInline.Color = Library.Theme.Accent[1]
                            else
                                DropdownInline.Color = Library.Theme.Inline
                            end
                        end
                    end)
                    Section.ContentAxis = Section.ContentAxis + DropdownOutline.Size.Y + 20
                    Tab.SectionAxis = {
                        Side == "Left" and Tab.SectionAxis[1] + DropdownOutline.Size.Y + 20 or Tab.SectionAxis[1], 
                        Side == "Right" and Tab.SectionAxis[2] + DropdownOutline.Size.Y + 20 or Tab.SectionAxis[2]
                    }
                    self:UpdateSizeY(Section.ContentAxis + DropdownOutline.Size.Y)
                    Tab["Render"][#Tab["Render"] + 1] = DropdownInline
                    Tab["Render"][#Tab["Render"] + 1] = DropdownOutline
                    Tab["Render"][#Tab["Render"] + 1] = DropdownTitle
                    Tab["Render"][#Tab["Render"] + 1] = DropdownGradient
                    Tab["Render"][#Tab["Render"] + 1] = DropdownSymbol
                    Tab["Render"][#Tab["Render"] + 1] = DropdownValue
                    Library.Items[Options.Flag] = Dropdown
                    table.insert(Library.Popups, Dropdown)
                    return Dropdown
                end
                function Section:Label(Title)
                    local Label = {
                        Axis = Section.ContentAxis
                    }
                    local LabelTitle = Utility.AddDrawing("Text", {
                        Text = Title,
                        Position = Vector2.new(SectionInline.Position.X + 6, SectionInline.Position.Y + 23 + Label.Axis),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    function Label:Set(Txt)
                        LabelTitle.Text = Txt
                    end
                    Section.ContentAxis = Section.ContentAxis + LabelTitle.Size + 8
                    Tab.SectionAxis = {
                        Side == "Left" and Tab.SectionAxis[1] +  LabelTitle.Size + 8 or Tab.SectionAxis[1], 
                        Side == "Right" and Tab.SectionAxis[2] +  LabelTitle.Size + 8 or Tab.SectionAxis[2]
                    }
                    self:UpdateSizeY(Section.ContentAxis + LabelTitle.Size)
                    Tab["Render"][#Tab["Render"] + 1] = LabelTitle
                    return Label
                end
                function Section:Keybind(Options)
                    local Keybind: any = {
                        Axis = Section.ContentAxis,
                        Title = Options.Title and Options.Title or "LOL",
                        EnumType = (Options.Key or Enum.UserInputType.MouseButton2).EnumType == Enum.KeyCode and "KeyCode" or "UserInputType",
                        Key = Options.Key or Enum.UserInputType.MouseButton2,
                        StateType = Options.StateType or "Hold",
                        State = false,
                        Shorten = "",
                        Binding = false,
                        Dropped = false,
                        Callback = typeof(Options.Callback) == "function" and Options.Callback or function() end
                    }
                    if Keybind.StateType == "Always" then
                        Keybind.Callback(Keybind.State, Keybind.Key)
                    end
                    Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                    local KeybindTitle = Utility.AddDrawing("Text", {
                        Text = Options.Title,
                        Position = Vector2.new(SectionInline.Position.X + 6, SectionInline.Position.Y + 26 + Keybind.Axis),
                        Center = false,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local KeybindInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X - 40 - 6, SectionInline.Position.Y + 23 + Keybind.Axis + 2),
                        Size = Vector2.new(40, 14),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(KeybindInline.Size.X - 2, KeybindInline.Size.Y - 2),
                        Position = Vector2.new(KeybindInline.Position.X + 1, KeybindInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(KeybindInline.Size.X - 2, KeybindInline.Size.Y - 2),
                        Position = Vector2.new(KeybindInline.Position.X + 1, KeybindInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 1,
                        Visible = true
                    })
                    local KeybindValue = Utility.AddDrawing("Text", {
                        Text = Keybind.Shorten,
                        Position = Vector2.new(KeybindInline.Position.X + (KeybindInline.Size.X / 2), KeybindInline.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local KeybindHoldInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X + 2 - 6, SectionInline.Position.Y + 23 + Keybind.Axis + 2),
                        Size = Vector2.new(60, 16),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindHoldOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(KeybindHoldInline.Size.X - 2, KeybindHoldInline.Size.Y - 2),
                        Position = Vector2.new(KeybindHoldInline.Position.X + 1, KeybindHoldInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindHoldGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(KeybindHoldInline.Size.X - 2, KeybindHoldInline.Size.Y - 2),
                        Position = Vector2.new(KeybindHoldInline.Position.X + 1, KeybindHoldInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 1,
                        Visible = true
                    })
                    local KeybindHoldValue = Utility.AddDrawing("Text", {
                        Text = "Hold",
                        Position = Vector2.new(KeybindHoldInline.Position.X + (KeybindHoldInline.Size.X / 2), KeybindHoldInline.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local KeybindToggleInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X + 2 - 6, SectionInline.Position.Y + 23 + Keybind.Axis + 2 + 18),
                        Size = Vector2.new(60, 16),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindToggleOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(KeybindToggleInline.Size.X - 2, KeybindToggleInline.Size.Y - 2),
                        Position = Vector2.new(KeybindToggleInline.Position.X + 1, KeybindToggleInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindToggleGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(KeybindToggleInline.Size.X - 2, KeybindToggleInline.Size.Y - 2),
                        Position = Vector2.new(KeybindToggleInline.Position.X + 1, KeybindToggleInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 1,
                        Visible = true
                    })
                    local KeybindToggleValue = Utility.AddDrawing("Text", {
                        Text = "Toggle",
                        Position = Vector2.new(KeybindToggleInline.Position.X + (KeybindToggleInline.Size.X / 2), KeybindToggleInline.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    local KeybindAlwaysInline = Utility.AddDrawing("Square", {
                        Position = Vector2.new(SectionInline.Position.X + SectionInline.Size.X + 2 - 6, SectionInline.Position.Y + 23 + Keybind.Axis + 2 + 34),
                        Size = Vector2.new(60, 16),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindAlwaysOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(KeybindAlwaysInline.Size.X - 2, KeybindAlwaysInline.Size.Y - 2),
                        Position = Vector2.new(KeybindAlwaysInline.Position.X + 1, KeybindAlwaysInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.LightContrast, --Library.Theme.Outline,
                        Visible = true,
                        Filled = true
                    })
                    local KeybindAlwaysGradient = Utility.AddDrawing("Image", {
                        Size = Vector2.new(KeybindAlwaysInline.Size.X - 2, KeybindAlwaysInline.Size.Y - 2),
                        Position = Vector2.new(KeybindAlwaysInline.Position.X + 1, KeybindAlwaysInline.Position.Y + 1),
                        Data = Library.Theme.Gradient,
                        Transparency = 1,
                        Visible = true
                    })
                    local KeybindAlwaysValue = Utility.AddDrawing("Text", {
                        Text = "Always",
                        Position = Vector2.new(KeybindAlwaysInline.Position.X + (KeybindAlwaysInline.Size.X / 2), KeybindAlwaysInline.Position.Y),
                        Center = true,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Color = Library.Theme.Text,
                        Visible = true,
                        ZIndex = 2
                    })
                    function Keybind:Drop(State)
                        KeybindHoldInline.Visible = State
                        KeybindHoldOutline.Visible = State
                        KeybindHoldGradient.Visible = State
                        KeybindHoldValue.Visible = State

                        KeybindToggleInline.Visible = State
                        KeybindToggleOutline.Visible = State
                        KeybindToggleGradient.Visible = State
                        KeybindToggleValue.Visible = State

                        KeybindAlwaysInline.Visible = State
                        KeybindAlwaysOutline.Visible = State
                        KeybindAlwaysGradient.Visible = State
                        KeybindAlwaysValue.Visible = State
                    end
                    function Keybind:SetStateType(State)
                        if State == "Hold" then
                            Keybind.StateType = "Hold"

                            KeybindAlwaysValue.Color = Library.Theme.Text
                            KeybindToggleValue.Color = Library.Theme.Text
                            KeybindHoldValue.Color = Library.Theme.Accent[1]
                        elseif State == "Toggle" then
                            Keybind.StateType = "Toggle"

                            KeybindAlwaysValue.Color = Library.Theme.Text
                            KeybindToggleValue.Color = Library.Theme.Accent[1]
                            KeybindHoldValue.Color = Library.Theme.Text
                        else
                            Keybind.StateType = "Always"

                            KeybindAlwaysValue.Color = Library.Theme.Accent[1]
                            KeybindToggleValue.Color = Library.Theme.Text
                            KeybindHoldValue.Color = Library.Theme.Text

                            Keybind.State = true
                            Keybind.Callback(Keybind.State, Keybind.Key)
                        end
                    end
                    Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                        
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if Keybind.Binding then
                                Keybind.Binding = false
                                Keybind.Key = Enum.UserInputType.MouseButton1
                                Keybind.EnumType = "UserInputType"
                                Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                                KeybindValue.Text = Keybind.Binding and "[...]" or Keybind.Shorten
                            end
                            if Utility.OnMouse(KeybindInline) then
                                for Index, Value in pairs(Tab.Dropdowns[Side]) do
                                    if Index ~= KeybindTitle.Text and Value then
                                        return
                                    end
                                end
                                if Keybind.Binding then
                                    Keybind.Binding = false
                                    KeybindValue.Text = Keybind.Shorten
                                else
                                    Keybind.Binding = true
                                    KeybindValue.Text = Keybind.Binding and "[...]" or Keybind.Shorten
                                end
                            end
                            if Utility.OnMouse(KeybindHoldInline) then
                                Keybind:SetStateType("Hold")
                            end
                            if Utility.OnMouse(KeybindToggleInline) then
                                Keybind:SetStateType("Toggle")
                            end
                            if Utility.OnMouse(KeybindAlwaysInline) then
                                Keybind:SetStateType("Always")
                            end
                        elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                            if Keybind.Binding then
                                Keybind.Binding = false
                                Keybind.Key = Input.KeyCode
                                Keybind.EnumType = "KeyCode"
                                Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                                KeybindValue.Text = Keybind.Binding and "[...]" or Keybind.Shorten
                            end
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            if Keybind.Binding then
                                Keybind.Binding = false
                                Keybind.Key = Enum.UserInputType.MouseButton2
                                Keybind.EnumType = "UserInputType"
                                Keybind.Shorten = Library.Keys.Shortened[Keybind.Key.Name] or Keybind.Key.Name
                                KeybindValue.Text = Keybind.Binding and "[...]" or Keybind.Shorten
                            end
                            if Utility.OnMouse(KeybindInline) then
                                Keybind.Dropped = not Keybind.Dropped
                                Keybind:Drop(Keybind.Dropped)
                            end
                        end
                    end)
                    Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                        
                        if (Keybind.EnumType == "KeyCode" and Input.KeyCode == Keybind.Key) or (Keybind.EnumType == "UserInputType" and Input.UserInputType == Keybind.Key) then
                            if Keybind.StateType == "Toggle" then
                                Keybind.State = not Keybind.State
                            elseif Keybind.StateType == "Hold" then
                                Keybind.State = true
                            end
                            Keybind.Callback(Keybind.State, Keybind.Key)
                        end
                    end)
                    Keybind:SetStateType(Keybind.StateType)
                    Utility.AddConnection(UserInput.InputEnded, function(Input, Useless)
                        
                        if (Keybind.EnumType == "KeyCode" and Input.KeyCode == Keybind.Key) or (Keybind.EnumType == "UserInputType" and Input.UserInputType == Keybind.Key) then
                            if Keybind.StateType == "Hold" then
                                Keybind.State = false
                                Keybind.Callback(Keybind.State, Keybind.Key)
                            end
                        end
                    end)
                    Keybind:Drop(false)
                    Section.ContentAxis = Section.ContentAxis + KeybindInline.Size.Y + 8
                    Tab.SectionAxis = {
                        Side == "Left" and Tab.SectionAxis[1] +  KeybindInline.Size.Y + 8 or Tab.SectionAxis[1], 
                        Side == "Right" and Tab.SectionAxis[2] +  KeybindInline.Size.Y + 8 or Tab.SectionAxis[2]
                    }
                    self:UpdateSizeY(Section.ContentAxis + KeybindInline.Size.Y)
                    Tab["Render"][#Tab["Render"] + 1] = KeybindTitle
                    Tab["Render"][#Tab["Render"] + 1] = KeybindInline
                    Tab["Render"][#Tab["Render"] + 1] = KeybindOutline
                    Tab["Render"][#Tab["Render"] + 1] = KeybindValue
                    Tab["Render"][#Tab["Render"] + 1] = KeybindGradient
                    table.insert(Library.Popups, Keybind)
                    return Keybind
                end
                return Section
            end
            Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
                if Useless then
                    return
                end
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and Utility.OnMouse(TabInline) then
                    task.spawn(function()

                        self:SwitchTab(Tab)
                    end)
                end
            end)
            function Tab:AddPlayerlist()
                local PlayerList = {
                    PlayersInList = 0
                }
                local PlayerListTabInline = Utility.AddDrawing("Square", {
                    Size = Vector2.new(SecondBorderOutline.Size.X - 16, 40),
                    Position = Vector2.new(SecondBorderOutline.Position.X + 8, SecondBorderOutline.Position.Y + 6),
                    Thickness = 0,
                    Color = Library.Theme.Inline,
                    Visible = true,
                    Filled = true
                })
                local PlayerListTabOutline = Utility.AddDrawing("Square", {
                    Size = Vector2.new(PlayerListTabInline.Size.X - 2, PlayerListTabInline.Size.Y - 2),
                    Position = Vector2.new(PlayerListTabInline.Position.X + 1, PlayerListTabInline.Position.Y + 1),
                    Thickness = 0,
                    Color = Library.Theme.Outline,
                    Visible = true,
                    Filled = true
                })
                local PlayerListPage = Utility.AddDrawing("Square", {
                    Size = Vector2.new(PlayerListTabOutline.Size.X - 4, PlayerListTabOutline.Size.Y - 4),
                    Position = Vector2.new(PlayerListTabOutline.Position.X + 2, PlayerListTabOutline.Position.Y + 2),
                    Thickness = 0,
                    Color = Library.Theme.DarkContrast,
                    Visible = true,
                    Filled = true
                })
                local PlayerListTopline = Utility.AddDrawing("Square", {
                    Size = Vector2.new(PlayerListTabOutline.Size.X, 1),
                    Position = Vector2.new(PlayerListTabOutline.Position.X, PlayerListTabOutline.Position.Y),
                    Thickness = 0,
                    Color = Library.Theme.Accent[1],
                    Visible = true,
                    Filled = true
                })
                local PlayerListTitle = Utility.AddDrawing("Text", {
                    Text = "Player List",
                    Outline = false,
                    Font = Library.Theme.Font,
                    Size = Library.Theme.TextSize,
                    Position = Vector2.new(PlayerListTabInline.Position.X + 4, PlayerListTabInline.Position.Y + 4),
                    Color = Library.Theme.Text,
                    Visible = true
                })
                local PlayerListName = Utility.AddDrawing("Text", {
                    Text = "Name",
                    Outline = false,
                    Font = Library.Theme.Font,
                    Size = Library.Theme.TextSize,
                    Position = Vector2.new(PlayerListTabInline.Position.X + 6, PlayerListTabInline.Position.Y + 20),
                    Color = Library.Theme.Text,
                    Visible = true
                })
                local PlayerListTeam = Utility.AddDrawing("Text", {
                    Text = "Team",
                    Outline = false,
                    Font = Library.Theme.Font,
                    Size = Library.Theme.TextSize,
                    Position = Vector2.new(PlayerListTabInline.Position.X + 182, PlayerListTabInline.Position.Y + 20),
                    Color = Library.Theme.Text,
                    Visible = true
                })
                local PlayerListStatus = Utility.AddDrawing("Text", {
                    Text = "Status",
                    Outline = false,
                    Font = Library.Theme.Font,
                    Size = Library.Theme.TextSize,
                    Position = Vector2.new(PlayerListTabInline.Position.X + 334, PlayerListTabInline.Position.Y + 20),
                    Color = Library.Theme.Text,
                    Visible = true
                })
                function PlayerList:RefreshList(Int)
                    PlayerListTabInline.Size = Vector2.new(SecondBorderOutline.Size.X - 16, (22 * Int) + 37)
                    PlayerListTabOutline.Size = Vector2.new(PlayerListTabInline.Size.X - 2, PlayerListTabInline.Size.Y - 2)
                    PlayerListTabOutline.Position = Vector2.new(PlayerListTabInline.Position.X + 1, PlayerListTabInline.Position.Y + 1)
                    PlayerListPage.Size = Vector2.new(PlayerListTabOutline.Size.X - 4, PlayerListTabOutline.Size.Y - 4)
                    PlayerListPage.Position = Vector2.new(PlayerListTabOutline.Position.X + 2, PlayerListTabOutline.Position.Y + 2)
                end
                function PlayerList:AddPlayer(Player)
                    PlayerList.PlayersInList += 1
                    local CurrentList, Removed = PlayerList.PlayersInList, false
                    local PlayerTabInline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(PlayerListTabInline.Size.X - 2, 22),
                        Position = Vector2.new(PlayerListTabInline.Position.X + 1, (PlayerListTabInline.Position.Y + 15) + (PlayerList.PlayersInList * 22)),
                        Thickness = 0,
                        Color = Library.Theme.Inline,
                        Visible = Window.SelectedTab == "Settings",
                        Filled = true
                    })
                    local PlayerTabOutline = Utility.AddDrawing("Square", {
                        Size = Vector2.new(PlayerTabInline.Size.X - 2, PlayerTabInline.Size.Y - 2),
                        Position = Vector2.new(PlayerTabInline.Position.X + 1, PlayerTabInline.Position.Y + 1),
                        Thickness = 0,
                        Color = Library.Theme.Outline,
                        Visible = Window.SelectedTab == "Settings",
                        Filled = true
                    })
                    local PlayerName = Utility.AddDrawing("Text", {
                        Text = Player.Name,
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Position = Vector2.new(PlayerTabInline.Position.X + 4, PlayerTabInline.Position.Y + 4),
                        Color = Library.Theme.Text,
                        Visible = Window.SelectedTab == "Settings"
                    })
                    local PlayerTeam = Utility.AddDrawing("Text", {
                        Text = Player.Team ~= nil and Player.Team.Name or "Neutral",
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Position = Vector2.new(PlayerTabInline.Position.X + 180, PlayerTabInline.Position.Y + 4),
                        Color = Player.Team ~= nil and Player.TeamColor.Color or Library.Theme.TextInactive,
                        Visible = Window.SelectedTab == "Settings"
                    })
                    local PlayerStatus = Utility.AddDrawing("Text", {
                        Text = Player == LocalPlayer and "Client" or "None",
                        Outline = false,
                        Font = Library.Theme.Font,
                        Size = Library.Theme.TextSize,
                        Position = Vector2.new(PlayerTabInline.Position.X + 330, PlayerTabInline.Position.Y + 4),
                        Color = Player == LocalPlayer and Library.Theme.Accent[1] or Library.Theme.Text,
                        Visible = Window.SelectedTab == "Settings"
                    })
                    Tab["Render"][#Tab["Render"] + 1] = PlayerTabInline
                    Tab["Render"][#Tab["Render"] + 1] = PlayerTabOutline
                    Tab["Render"][#Tab["Render"] + 1] = PlayerName
                    Tab["Render"][#Tab["Render"] + 1] = PlayerTeam
                    Tab["Render"][#Tab["Render"] + 1] = PlayerStatus
                    self:RefreshList(CurrentList)
                    Utility.AddConnection(Library.Communication.Event, function(Type, User)
                        if Type == "RemovePlayer" then
                            if User == Player.Name then
                                Tab:RemoveDrawing(PlayerTabInline)
                                Tab:RemoveDrawing(PlayerTabOutline)
                                Tab:RemoveDrawing(PlayerName)
                                Tab:RemoveDrawing(PlayerTeam)
                                Tab:RemoveDrawing(PlayerStatus)
                                
                            end
                            CurrentList -= 1
                            self:RefreshList(CurrentList)
                        end
                    end)
                end
                function PlayerList:RemovePlayer(Player)
                    PlayerList[Player.Name] = {}
                    Library.Communication:Fire("RemovePlayer", Player.Name)
                    PlayerList.PlayersInList -= 1
                    self:RefreshList(PlayerList.PlayersInList)
                end
                Tab["Render"][#Tab["Render"] + 1] = PlayerListTabInline
                Tab["Render"][#Tab["Render"] + 1] = PlayerListTabOutline
                Tab["Render"][#Tab["Render"] + 1] = PlayerListTopline
                Tab["Render"][#Tab["Render"] + 1] = PlayerListName
                Tab["Render"][#Tab["Render"] + 1] = PlayerListTeam
                Tab["Render"][#Tab["Render"] + 1] = PlayerListStatus
                Tab["Render"][#Tab["Render"] + 1] = PlayerListPage
                Tab["Render"][#Tab["Render"] + 1] = PlayerListTitle
                return PlayerList
            end
            Tab["TabInline"] = TabInline
            Tab["TabOutline"] = TabOutline
            Tab["TabTitle"] = TabTitle
            Tab:Install()
            Window.LastTab = TabInline
            self.Tabs[#self.Tabs + 1] = Tab
            Tab["Render"] = {}
            return Tab
        end
        function Window.Watermark(Title)
            local Watermark = {
                Title = Title,
                FPS = 60,
                Visible = true
            }
            local WindowOutline = Utility.AddDrawing("Square", {
                Size = Vector2.new(475, 24),
                Position = Vector2.new(150, 8),
                Thickness = 0,
                Color = Library.Theme.Outline,
                Visible = true,
                Filled = true
            }, Library.Watermark)
            local WatermarkIcon = Utility.AddDrawing("Image", {
                Size = Vector2.new(18, 20),
                Position = Vector2.new(WindowOutline.Position.X + 2, WindowOutline.Position.Y + 2),
                Transparency = 1,
                ZIndex = 3,
                Visible = true,
                Data = Library.Theme.Logo
            }, Library.Watermark)
            local WindowOutlineBorder = Utility.AddDrawing("Square", {
                Size = Vector2.new(WindowOutline.Size.X - 2, WindowOutline.Size.Y - 2),
                Position = Vector2.new(WindowOutline.Position.X + 1, WindowOutline.Position.Y + 1),
                Thickness = 0,
                Color = Library.Theme.Accent[1],
                Visible = false,
                Filled = true
            }, Library.Watermark)
            local WindowFrame = Utility.AddDrawing("Square", {
                Size = Vector2.new(WindowOutlineBorder.Size.X - 2, WindowOutlineBorder.Size.Y - 2),
                Position = Vector2.new(WindowOutlineBorder.Position.X + 1, WindowOutlineBorder.Position.Y + 1),
                Thickness = 0,
                Transparency = 1,
                Color = Library.Theme.DarkContrast,
                Visible = true,
                Filled = true
            }, Library.Watermark)
            local WindowTopline = Utility.AddDrawing("Square", {
                Size = Vector2.new(WindowOutlineBorder.Size.X, 1),
                Position = Vector2.new(WindowOutlineBorder.Position.X, WindowOutlineBorder.Position.Y),
                Thickness = 0,
                Color = Library.Theme.Accent[1],
                Visible = true,
                Filled = true
            }, Library.Watermark)
            Utility.AddConnection(Library.Communication.Event, function(Type, Color)
                if Type == "Accent" then
                    WindowOutlineBorder.Color = Color
                    WindowTopline.Color = Color
                end
            end)
            local WindowImage = Utility.AddDrawing("Image", {
                Size = WindowFrame.Size,
                Position = WindowFrame.Position,
                Transparency = 1, 
                Visible = true,
                Data = Library.Theme.Gradient
            }, Library.Watermark)
            local WindowTitle = Utility.AddDrawing("Text", {
                Font = Library.Theme.Font,
                Size = Library.Theme.TextSize,
                Color = Library.Theme.Text,
                Text = Watermark.Title .. " | " .. ("%s, %s, %s"):format(os.date("%B"), os.date("%d"), os.date("%Y")),
                Position = Vector2.new(WindowFrame.Position.X + (WindowFrame.Size.X / 2), WindowOutlineBorder.Position.Y + 4),
                Visible = true,
                Center = false,
                Outline = false
            }, Library.Watermark)
            WindowOutline.Size = Vector2.new(WindowTitle.TextBounds.X + 19, 20)
            WindowTopline.Size = Vector2.new(WindowOutline.Size.X - 2, 2)
            WindowFrame.Size = Vector2.new(WindowOutline.Size.X - 2, WindowOutline.Size.Y - 2)
            
            Utility.AddDrag(WindowOutline, Library.Watermark)
            Utility.AddConnection(RunService.RenderStepped, function()
                Watermark.FPS += 1
                if Watermark.Visible then
                    local Hours, Minutes, Secs = os.date("*t")["hour"], os.date("*t")["min"], os.date("*t")["sec"]
                    local Format = Hours > 12 and Hours - 12 or Hours
                    local AMORPM = Hours > 12 and "PM" or "AM"
                    local FixZero = string.len(tostring(Secs)) == 1 and "0" .. Secs or Secs
                    WindowTitle.Text =  ("%s | %s:%s:%s %s | %s, %s, %s, %s"):format(Watermark.Title, Format, Minutes, FixZero, AMORPM, os.date("%A"), os.date("%B"), os.date("%d"), os.date("%Y"))

                    WindowOutline.Visible = true
                    WindowImage.Visible = true
                    WindowOutline.Size = Vector2.new(WindowTitle.TextBounds.X + 28, 22)
                    WindowOutlineBorder.Size = WindowOutline.Size
                    WindowTopline.Size = Vector2.new(WindowOutline.Size.X - 2, 1)
                    WindowFrame.Size = Vector2.new(WindowOutline.Size.X - 2, WindowOutline.Size.Y - 2)
                    WindowImage.Size = WindowFrame.Size
                    WindowTitle.Position = Vector2.new(WindowTopline.Position.X + 22, WindowTopline.Position.Y + 4)
                    WindowFrame.Visible = true
                    WindowTitle.Visible = true
                    WatermarkIcon.Visible = true
                    WindowTopline.Visible = true
                else
                    WatermarkIcon.Visible = false
                    WindowOutline.Visible = false
                    WindowFrame.Visible = false
                    WindowTitle.Visible = false
                    WindowTopline.Visible = false
                end
            end)
            return Watermark
        end

        return Window
    end
end
Utility.AddConnection(UserInput.InputBegan, function(Input, Useless)
    if Useless then
        return
    end
    if Input.KeyCode == Enum.KeyCode.RightShift then
        Library:ChangeVisible(not Library.WindowVisible)
    end
end)

return Library
