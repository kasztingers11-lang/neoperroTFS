-- Native input, inventory discovery, movement and cash upgrades. No shot packets are fabricated.
return function(Library: any, Window: any, Guns: any, CreateShopAdapter: any, CreateNavigation: any, CreateAmmoAdapter: any)
    local P: any = game:GetService("Players").LocalPlayer
    local Run = game:GetService("RunService")
    local Input = game:GetService("UserInputService")
    local Paths = game:GetService("PathfindingService")
    local RS: any = game:GetService("ReplicatedStorage")
    local W: any = workspace
    local Flags = Library.Flags
    local A: any = {Alive = true, Connections = {}, Watches = {}, Callbacks = {}, Inventory = {},
        Shop = CreateShopAdapter(), Navigation = CreateNavigation(), Refill = CreateAmmoAdapter(), Zombies = {}, LastScan = -10, LastStep = -10, LastVisual = -10,
        LastBuy = -10, NextPress = 0, Lines = {}, Notices = {}, InventoryDirty = true, WindowFocused = isrbxactive() == true}
    A.Refill.CanStart = function() return A.Alive and A:Focused() end
    A.Shop.CanStart = function() return A.Alive and A:Focused() end
    local RenderName = "NeoperroAutomation"
    local function Connect(Signal, Callback, Bucket)
        local C = Signal:Connect(Callback)
        table.insert(Bucket or A.Connections, C)
        return C
    end
    local function Number(Value, Default, Min, Max)
        if type(Value) ~= "number" or Value ~= Value or math.abs(Value) == math.huge then return Default end
        return math.clamp(Value, Min, Max)
    end
    local function Flat(V) return Vector3.new(V.X, 0, V.Z) end
    local function Unit(V) return V.Magnitude > 0.001 and V.Unit or Vector3.zero end
    local function Value(Tool, Name, Default)
        local Values = Tool and Tool:FindFirstChild("CurrentValues")
        local V = Values and Values:FindFirstChild(Name)
        return V and V.Value or Default
    end
    local function IsLevel(L)
        return L and (L:IsA("IntConstrainedValue") or L:IsA("DoubleConstrainedValue"))
            and type(L.Value) == "number" and type(L.MaxValue) == "number"
    end
    local function Status(Key, Message)
        local Label = Library[Key]
        if A[Key] ~= Message then
            A[Key] = Message
            if Label then Label:Set(#Message > 34 and Message:sub(1, 31) .. "..." or Message) end
        end
    end
    local function Notify(Key, Message)
        if A.Notices[Key] == Message then return end
        A.Notices[Key] = Message
        Window.SendNotification("Normal", Message, 4)
    end
    function A:Character()
        local C = P.Character
        local H = C and C:FindFirstChildOfClass("Humanoid")
        local R = C and C:FindFirstChild("HumanoidRootPart")
        if H and R and H.Health > 0 then return C, H, R end
        return nil
    end
    function A:NativeFocused()
        return self.WindowFocused ~= false and isrbxactive() == true
    end
    function A:Focused()
        return (self:NativeFocused() or Flags.FarmBackground == true) and Input:GetFocusedTextBox() == nil
            and not Library.WindowVisible and not Library.CapturingMenuKey
    end
    function A:ReleaseMouse()
        if self.MouseOwned then
            -- Clear only the latch belonging to our own press; native input can ignore releases unfocused.
            local B = self.PressedBinding
            if B and B.Environment then B.Environment.mouse1Down = false end
            if self.MouseMode ~= "native" then self.ReleasePending = true end
        end
        if self.ReleasePending and self:NativeFocused() then
            mouse1release()
            self.ReleasePending = false
        end
        self.MouseOwned = false
        self.PressedBinding = nil
        self.MouseMode = nil
    end
    function A:Sprint(State)
        if not State and self.SprintOwned then self.SprintReleasePending = true end
        if self.SprintReleasePending and self:NativeFocused() then
            keyrelease(0xA0); self.SprintOwned = false; self.SprintReleasePending = false
        end
        if State and not self.SprintOwned and not self.SprintReleasePending and self:NativeFocused()
            and not Input:IsKeyDown(Enum.KeyCode.LeftShift) and not Input:IsKeyDown(Enum.KeyCode.RightShift) then
            keypress(0xA0); self.SprintOwned = true
        end
    end
    function A:StopMovement()
        if self.MovingHumanoid and self.MovingHumanoid.Parent then
            self.MovingHumanoid:Move(Vector3.zero, false)
            if self.Travelling then
                local R = self.MovingHumanoid.Parent:FindFirstChild("HumanoidRootPart")
                if R then self.MovingHumanoid:MoveTo(R.Position) end
            end
        end
        self.MovingHumanoid = nil; self.MoveDirection = nil; self.Travelling = nil
        self:Sprint(false)
    end
    function A:ReleaseAim()
        self:ReleaseMouse()
        self:RestoreView()
        self.Target = nil; self.AimedAt = nil
    end
    function A:ScanInventory()
        local Owned, Names = {}, {"Select weapon"}
        local function Visit(Parent, Mirror)
            if not Parent then return end
            for _, Tool in ipairs(Parent:GetChildren()) do
                local Name = Tool.Name
                local Levels = self.Shop:Levels(Name)
                if Levels and ((Tool:IsA("Tool") and Tool:FindFirstChild("GunScript") and Tool:FindFirstChild("CurrentValues"))
                    or Mirror and Tool:FindFirstChild("CurrentValues")) then
                    Owned[Name] = Tool:IsA("Tool") and Tool or Owned[Name] or false
                end
            end
        end
        Visit(P:FindFirstChildOfClass("Backpack"), false); Visit(P.Character, false)
        Visit(P:FindFirstChild("Backgear"), true)
        for Name in pairs(Owned) do table.insert(Names, Name) end
        table.sort(Names, function(X, Y)
            if X == Y then return false end
            if X == "Select weapon" then return true end
            if Y == "Select weapon" then return false end
            return X < Y
        end)
        self.Inventory = Owned; self.InventoryDirty = false; self.LastScan = os.clock()
        local Selected = Flags.UpgradeWeapon
        if self.SavedWeapon and Owned[self.SavedWeapon] ~= nil then Selected = self.SavedWeapon; self.SavedWeapon = nil end
        if Owned[Selected] == nil then Selected = "Select weapon" end
        self.Scanning = true
        Library.Items.UpgradeWeapon:SetOptions(Names, Selected)
        self.Scanning = false
        self:ScanPriorities()
    end
    function A:ScanPriorities()
        local Options = {"Select upgrade"}
        local Levels = self.Shop:Levels(Flags.UpgradeWeapon)
        if self.Inventory[Flags.UpgradeWeapon] ~= nil and Levels then
            for _, L in ipairs(Levels:GetChildren()) do
                if IsLevel(L) then
                    table.insert(Options, L.Name)
                end
            end
        end
        table.sort(Options, function(X, Y)
            if X == Y then return false end
            if X == "Select upgrade" then return true end
            if Y == "Select upgrade" then return false end
            return X < Y
        end)
        local Selected = Flags.UpgradePriority
        if not self.SavedWeapon and self.SavedPriority and table.find(Options, self.SavedPriority) then
            Selected = self.SavedPriority; self.SavedPriority = nil
        end
        if Selected == "Select upgrade" or not table.find(Options, Selected) then
            Selected = table.find(Options, "Damage") and "Damage" or Options[2] or Options[1]
        end
        Library.Items.UpgradePriority:SetOptions(Options, Selected)
    end
    function A:RestoreSelection(Values)
        if type(Values.UpgradeWeapon) == "string" then self.SavedWeapon = Values.UpgradeWeapon end
        if type(Values.UpgradePriority) == "string" then self.SavedPriority = Values.UpgradePriority end
        self:ScanInventory()
    end
    function A:Watch(Key, Parent)
        for _, C in ipairs(self.Watches[Key] or {}) do C:Disconnect() end
        local Bucket = {}; self.Watches[Key] = Bucket
        if Parent then
            Connect(Parent.DescendantAdded, function() self.InventoryDirty = true end, Bucket)
            Connect(Parent.DescendantRemoving, function() self.InventoryDirty = true end, Bucket)
        end
        self.InventoryDirty = true
    end
    function A:SnapshotZombies()
        self.LastZombieScan = os.clock()
        local Folder = W:FindFirstChild("Zombies")
        local List = {}
        if Folder then
            for _, Model in ipairs(Folder:GetChildren()) do
                local H = Model:FindFirstChildOfClass("Humanoid")
                local Head = Model:FindFirstChild("Head")
                if H and H.Health > 0 and Head and Head:IsA("BasePart") then
                    table.insert(List, {Model = Model, Humanoid = H, Head = Head})
                end
            end
        end
        self.Zombies = List
    end
    function A:Params(ExcludeZombies)
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        local Ignore = {}
        if P.Character then table.insert(Ignore, P.Character) end
        if ExcludeZombies then
            local Folder = W:FindFirstChild("Zombies")
            if Folder then table.insert(Ignore, Folder) end
        end
        local Camera = W.CurrentCamera
        if Camera then table.insert(Ignore, Camera) end
        Params.FilterDescendantsInstances = Ignore
        Params.RespectCanCollide = ExcludeZombies == true
        return Params
    end
    function A:Visible(Origin, Z, Tool)
        local Params = self:Params(false)
        local B = Tool and Guns.Weapons[Tool]
        if B and B.Manager and type(B.Manager.GetIgnoreList) == "function" then
            local OK, List = pcall(B.Manager.GetIgnoreList, B.Manager)
            if OK and type(List) == "table" then
                local Ignore = Params.FilterDescendantsInstances
                for _, Item in ipairs(List) do if typeof(Item) == "Instance" then table.insert(Ignore, Item) end end
                Params.FilterDescendantsInstances = Ignore
            end
        end
        local Hit = W:Raycast(Origin, Z.Head.Position - Origin, Params)
        return Hit == nil or Hit.Instance:IsDescendantOf(Z.Model)
    end
    function A:SelectTarget(Origin, Range, Tool, ThrottleSearch)
        local Folder = W:FindFirstChild("Zombies")
        local function Valid(Z)
            return Folder ~= nil and Z and Z.Model.Parent == Folder and Z.Head.Parent and Z.Humanoid.Health > 0
                and (Z.Head.Position - Origin).Magnitude <= Range
        end
        if Valid(self.Target) and self:Visible(Origin, self.Target, Tool) then return self.Target end
        local Previous = self.Target
        self.Target = nil
        local Now = os.clock()
        if ThrottleSearch and not Previous and Now < (self.NextTargetSearch or 0) then return nil end
        self.NextTargetSearch = Now + 1 / 30
        local Candidates = {}
        for _, Z in ipairs(self.Zombies) do
            if Valid(Z) then
                local Delta = Z.Head.Position - Origin
                table.insert(Candidates, {Zombie = Z, Distance = Delta:Dot(Delta)})
            end
        end
        table.sort(Candidates, function(X, Y) return X.Distance < Y.Distance end)
        for _, Candidate in ipairs(Candidates) do
            if self:Visible(Origin, Candidate.Zombie, Tool) then
                self.Target = Candidate.Zombie
                return self.Target
            end
        end
        return nil
    end
    function A:Equipped()
        if P.Character then
            for _, T in ipairs(P.Character:GetChildren()) do
                if T:IsA("Tool") and T:FindFirstChild("GunScript") and T:FindFirstChild("CurrentValues") then return T end
            end
        end
        return nil
    end
    function A:Equip(H, Preferred)
        if self.Equipping or os.clock() < (self.NextEquip or 0) then return end
        local Bag = P:FindFirstChildOfClass("Backpack")
        local Best = Preferred
        if Bag and not Best then
            local Score = -math.huge
            for _, T in ipairs(Bag:GetChildren()) do
                if T:IsA("Tool") and T:FindFirstChild("GunScript") and T:FindFirstChild("CurrentValues")
                    and (Value(T, "Clip", 0) ~= 0 or Value(T, "Ammo", 0) ~= 0) then
                    local Ready = Value(T, "Clip", 0) ~= 0 and 100000 or 0
                    local Current = Ready + math.clamp(Value(T, "Ammo", 0), 0, 99999)
                    if Current > Score then Best = T; Score = Current end
                end
            end
        end
        if Best then
            self.Equipping = true; self.NextEquip = os.clock() + 1
            task.spawn(function()
                if self.Alive and (Flags.FarmAutoShoot or Flags.FarmAutoRefill) and self:Focused() and H.Parent == P.Character then pcall(H.EquipTool, H, Best) end
                self.Equipping = false
            end)
        end
    end
    function A:CameraState()
        self:RestoreView()
        if Flags.CameraThirdPerson and self.WindowFocused ~= false and isrbxactive() then
            if not self.CameraSaved then
                self.CameraSaved = {Mode = P.CameraMode, Min = P.CameraMinZoomDistance, Max = P.CameraMaxZoomDistance}
            end
            local D = Number(Flags.CameraDistance, 10, 4, 24)
            P.CameraMode = Enum.CameraMode.Classic
            P.CameraMaxZoomDistance = math.max(P.CameraMaxZoomDistance, D)
            P.CameraMinZoomDistance = D; P.CameraMaxZoomDistance = D
        elseif self.CameraSaved then
            local S = self.CameraSaved
            P.CameraMaxZoomDistance = math.max(P.CameraMaxZoomDistance, S.Max, S.Min)
            P.CameraMinZoomDistance = S.Min; P.CameraMaxZoomDistance = S.Max; P.CameraMode = S.Mode
            self.CameraSaved = nil
        end
    end
    function A:RestoreView()
        local View = self.SavedView
        if View then
            self.SavedView = nil
            if View.Camera == W.CurrentCamera then View.Camera.CFrame = View.CFrame; View.Camera.Focus = View.Focus end
        end
    end
    function A:Aim(Camera, Root, Target)
        -- GunScript fires at Camera+2. This runs at Camera+1; the view restores after firing.
        local Head = P.Character and P.Character:FindFirstChild("Head")
        local Origin = Head and Head.Position or Root.Position + Vector3.new(0, 1.5, 0)
        if (Target.Head.Position - Origin).Magnitude < 0.25 then self.AimError = math.huge; return end
        local Mouse = P:GetMouse()
        local Ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y, 0)
        local LocalRay = Camera.CFrame:VectorToObjectSpace(Ray.Direction)
        if Flags.CameraThirdPerson then
            self.SavedView = {Camera = Camera, CFrame = Camera.CFrame, Focus = Camera.Focus}
        end
        -- Compensate for the free cursor's screen position, instead of forcing LockCenter.
        Camera.CFrame = CFrame.lookAt(Origin, Target.Head.Position) * CFrame.lookAt(Vector3.zero, LocalRay):Inverse()
        self.AimedAt = Target.Head
        self.LastAimPoint = Target.Head.Position
        local ActualRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y, 0)
        self.AimError = math.deg(math.acos(math.clamp(ActualRay.Direction:Dot((Target.Head.Position - Origin).Unit), -1, 1)))
    end
    function A:Shoot(Tool)
        local B = Guns.Weapons[Tool] or Guns:BindWeapon(Tool)
        if not B then self:ReleaseMouse(); Status("FarmStatus", "Waiting for native gun script"); return end
        if Value(Tool, "Clip", 0) == 0 then
            self:ReleaseMouse()
            if Value(Tool, "Ammo", 0) == 0 then self:Equip(P.Character:FindFirstChildOfClass("Humanoid")) end
            if Value(Tool, "Ammo", 0) ~= 0 and not self.Reloading and os.clock() > (self.NextReload or 0)
                and type(B.Environment.reload) == "function" then
                self.Reloading = true; self.NextReload = os.clock() + 1
                task.spawn(function()
                    if self.Alive and self:Focused() and Flags.FarmAutoShoot and Tool.Parent == P.Character then pcall(B.Environment.reload) end
                    self.Reloading = false
                end)
            end
            Status("FarmStatus", Value(Tool, "Ammo", 0) == 0 and "Out of ammunition" or "Native reload")
            return
        end
        local FireType = Value(Tool, "FireType", "Single")
        if FireType == "Charge" then self:ReleaseMouse(); Status("FarmStatus", "Charge weapons need manual fire"); return end
        local Native = not self:NativeFocused() and Flags.FarmBackground == true
        if Native and type(B.Environment.mouse1Down) ~= "boolean" then
            self:ReleaseMouse(); Status("FarmStatus", "Background fire unavailable"); return
        end
        if self.MouseOwned and (self.PressedBinding ~= B or (self.MouseMode == "native") ~= Native) then self:ReleaseMouse() end
        if Native and self.MouseOwned and (FireType == "FullAuto" or FireType == "Continuous") then B.Environment.mouse1Down = true end
        if self.MouseOwned and FireType ~= "FullAuto" and FireType ~= "Continuous" then
            if os.clock() >= self.PressRelease then self:ReleaseMouse() end
        elseif not self.MouseOwned and os.clock() >= self.NextPress
            and (Native or not Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not self.ReleasePending) then
            if Native then B.Environment.mouse1Down = true else mouse1press() end
            self.MouseOwned = true; self.PressedBinding = B; self.MouseMode = Native and "native" or "os"
            local Now = os.clock()
            local Frame = Number(self.FrameDelta, 1 / 60, 1 / 1000, 1 / 15)
            local Interval = math.max(Frame * 2, 60 / Number(B.Environment.LAS or Value(Tool, "AttackSpeed", 300), 300, 1, 7200))
            self.PressRelease = Now + math.min(0.035, math.max(Frame * 0.5, Interval * 0.3))
            -- Keep elapsed-time cadence without replaying missed shots after a hitch.
            self.NextPress = (self.NextPress > Now - Interval and self.NextPress or Now) + Interval
        end
        Status("FarmStatus", (Native and "Background: " or "Head lock: ") .. self.Target.Model.Name)
    end
    function A:ChooseEscape(Root, Radius)
        local H = P.Character and P.Character:FindFirstChildOfClass("Humanoid")
        return self.Navigation:Update(H, Root, self.Zombies, Radius)
    end
    function A:Kite(H, Root, Radius)
        self.MoveDirection = self:ChooseEscape(Root, Radius or Number(Flags.FarmDistance, 24, 5, 100))
        self.Nearest = self.Navigation.Nearest
        Status("MoveStatus", self.Navigation.Status or "Planning retreat")
        if self.MoveDirection then
            self.MovingHumanoid = H; self:Sprint(Flags.FarmUseSprint == true)
        else self:StopMovement() end
    end
    function A:TravelToShop(H, Root, Label)
        local Regions = RS:FindFirstChild("ShopRegions")
        local Region = Regions and Regions:FindFirstChild("MainShopRegion")
        Label = Label or "UpgradeStatus"
        if not Region or not Region:IsA("BasePart") then Status(Label, "Shop location unavailable"); return end
        self:TravelToPoint(H, Root, Region.Position, "shop", Label, "Walking to shop")
    end
    function A:TravelToPoint(H, Root, Goal, Purpose, Label, Message, IgnoreDestinationModel)
        if self.TravelPurpose ~= Purpose then self:CancelTravel(); self:StopMovement(); self.PathFailedUntil = nil end
        self.TravelPurpose = Purpose
        if self.PathFailedUntil and os.clock() < self.PathFailedUntil then Status(Label, "Path blocked; retrying shortly"); return end
        if not self.Route and not self.PathComputing then
            self.PathComputing = true
            local Token = {}; self.PathToken = Token
            local Params = self:Params(true)
            if IgnoreDestinationModel then
                local Ignore = Params.FilterDescendantsInstances
                table.insert(Ignore, IgnoreDestinationModel); Params.FilterDescendantsInstances = Ignore
            end
            local Ground = W:Raycast(Goal + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0), Params)
            local Destination = Ground and Ground.Position or Goal
            task.spawn(function()
                local OK, Route = pcall(function()
                    local Path = Paths:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4})
                    Path:ComputeAsync(Root.Position, Destination)
                    if Path.Status == Enum.PathStatus.Success then return Path:GetWaypoints() end
                    return nil
                end)
                if not self.Alive or self.PathToken ~= Token then return end
                self.PathComputing = false
                if OK and Route and #Route >= 2 then
                    self.Route = Route; self.Waypoint = 2; self.RouteAt = os.clock()
                    self.ProgressPosition = Root.Position; self.ProgressAt = os.clock()
                else self.PathFailedUntil = os.clock() + 3 end
            end)
        end
        local Route = self.Route
        if Route then
            local Point = Route[self.Waypoint]
            if Point and (Root.Position - Point.Position).Magnitude < 3 then self.Waypoint = self.Waypoint + 1; Point = Route[self.Waypoint] end
            if not Point or os.clock() - self.RouteAt > 8 then self.Route = nil; self:StopMovement(); return end
            if os.clock() - self.ProgressAt >= 1.5 then
                if (Root.Position - self.ProgressPosition).Magnitude < 1 then self.Route = nil; self:StopMovement(); return end
                self.ProgressPosition = Root.Position; self.ProgressAt = os.clock()
            end
            self.MovingHumanoid = H; self.Travelling = true; self.MoveDirection = nil
            H:MoveTo(Point.Position)
            if Point.Action == Enum.PathWaypointAction.Jump then H.Jump = true end
            self:Sprint(Flags.FarmUseSprint == true)
        end
        Status(Label, Message)
    end
    function A:CancelTravel()
        self.PathToken = nil; self.PathComputing = false; self.Route = nil; self.TravelPurpose = nil
        if self.Travelling then self:StopMovement() end
    end
    function A:AmmoTool()
        local T = self:Equipped()
        local Threshold = Number(Flags.FarmRefillThreshold, 30, 5, 80)
        if Flags.FarmTopUp and self.Shop:BetweenRounds() then Threshold = 90 end
        if T and self.Refill:Needs(T, Threshold) then return T end
        local Bag = P:FindFirstChildOfClass("Backpack")
        if Bag then
            for _, Tool in ipairs(Bag:GetChildren()) do
                if Tool:IsA("Tool") and Tool:FindFirstChild("GunScript") and self.Refill:Needs(Tool, Threshold) then return Tool end
            end
        end
        return nil
    end
    function A:AutoRefill(H, Root)
        local State = self.Refill:Poll()
        if State == "refilled" then Status("AmmoStatus", "Reserve refilled")
        elseif State == "failed" then Status("AmmoStatus", "Refill interrupted or rejected") end
        if self.Refill.Pending then self:ReleaseAim(); Status("AmmoStatus", "Native ammo-box interaction"); return false end
        if not Flags.FarmAutoRefill or self.Shop.Pending or self.Shop.RestockPending or self.Shop.ReadyPending then
            self.ResupplyEscapeRadius = nil
            if self.TravelPurpose == "ammo" then self:CancelTravel() end
            return false
        end
        local Tool = self:AmmoTool()
        if not Tool then
            self.ResupplyEscapeRadius = nil
            if self.TravelPurpose == "ammo" then self:CancelTravel() end
            Status("AmmoStatus", "Reserve ammo sufficient"); return false
        end
        if not H or not self:Focused() then return false end
        if self.TravelPurpose == "ammo" and self.AmmoDestination and self.PathFailedUntil and os.clock() < self.PathFailedUntil then
            self.Refill:Avoid(self.AmmoDestination, 8); self:CancelTravel(); self.PathFailedUntil = nil
        end
        local Box, Distance = self.Refill:Nearest(Root)
        if not Box then Status("AmmoStatus", "No stocked ammo box available"); return false end
        local Near = self.Navigation:Separation(Root.Position, self.Zombies)
        local Radius = Number(Flags.FarmDistance, 24, 5, 100)
        if Near < Radius + 8 then
            if self.TravelPurpose == "ammo" then self:CancelTravel() end
            Status("AmmoStatus", "Retreating before resupply"); return false
        end
        if Distance >= 7 then
            self.AmmoDestination = Box
            local Delta = Unit(Flat(Root.Position - Box.PrimaryPart.Position))
            if Delta.Magnitude < 0.01 then Delta = Vector3.new(1, 0, 0) end
            self:TravelToPoint(H, Root, Box.PrimaryPart.Position + Delta * 5, "ammo", "AmmoStatus", "Walking to ammo box", Box)
            return true
        end
        self:CancelTravel(); self:StopMovement(); self:ReleaseAim()
        if Tool.Parent ~= P.Character then self:Equip(H, Tool); Status("AmmoStatus", "Equipping gun for resupply"); return false end
        local Context = self.Refill:Context()
        if not Context then Status("AmmoStatus", "Native refill unavailable"); return false end
        local Duration = self.Refill:Duration(Box, Context)
        local SafeGap = math.max(Radius + 8, 12 + Duration * 16)
        if Near < SafeGap then
            Status("AmmoStatus", "Making space for native refill")
            if Flags.FarmKeepDistance then self.ResupplyEscapeRadius = SafeGap; self:Kite(H, Root, SafeGap); return true end
            return false
        end
        self.ResupplyEscapeRadius = nil
        local _, Message = self.Refill:Begin(Tool, Box, Root)
        Status("AmmoStatus", Message)
        return false
    end
    function A:StartFarm()
        self:ScanInventory()
        local Tool = self:Equipped()
        if Flags.UpgradeWeapon == "Select weapon" and Tool and self.Inventory[Tool.Name] ~= nil then Library.Items.UpgradeWeapon:Set(Tool.Name) end
        for _, Key in ipairs({"FarmAutoShoot", "FarmKeepDistance", "FarmAutoRefill"}) do Library.Items[Key]:Set(true) end
        Library:ChangeVisible(false)
    end
    function A:StopAutomation()
        for _, Key in ipairs({"FarmAutoShoot", "FarmKeepDistance", "FarmAutoRefill", "FarmRestockBox", "UpgradeEnabled", "FarmAutoReady"}) do
            Library.Items[Key]:Set(false)
        end
        self:ReleaseAim(); self:CancelTravel(); self:StopMovement(); self.Navigation:Reset()
        Status("FarmStatus", "Automation stopped")
    end
    function A:OrderedLevels()
        local Levels = self.Shop:Levels(Flags.UpgradeWeapon)
        if not Levels or self.Inventory[Flags.UpgradeWeapon] == nil then return {} end
        local Priority = Levels:FindFirstChild(Flags.UpgradePriority)
        if not IsLevel(Priority) then return {} end
        local List = {Priority}
        if Flags.UpgradeMode == "All upgrades" then
            local Rest = {}
            for _, L in ipairs(Levels:GetChildren()) do
                if L ~= Priority and IsLevel(L) then table.insert(Rest, L) end
            end
            table.sort(Rest, function(X, Y) return X.Name < Y.Name end)
            for _, L in ipairs(Rest) do table.insert(List, L) end
        end
        return List
    end
    function A:StopUpgrade(Message, Complete)
        Status("UpgradeStatus", Message)
        Library.Items.UpgradeEnabled:Set(false)
        if not Complete or Flags.UpgradeNotify then Notify("upgrade-stop", Message) end
    end
    function A:Restock(H, Root)
        local State = self.Shop:PollRestock()
        if State == "waiting" then
            self:ReleaseAim(); self:StopMovement()
            Status("RestockStatus", "Waiting for native restock"); return true
        elseif State == "submitted" or State == "unconfirmed" then
            if State == "unconfirmed" then self.RestockError = true end
            Status("RestockStatus", State == "submitted" and "Restock sent; check box stock" or "Restock unconfirmed; no retry")
            return false
        end
        if not Flags.FarmRestockBox or self.Shop.Pending or self.Refill.Pending then return false end
        local Box = self.Shop:AmmoBox()
        local Threshold = Number(Flags.FarmRestockThreshold, 20, 5, 50)
        if not Box or not Box:FindFirstChild("Ammo") or not Box:FindFirstChild("MaxAmmo") or Box.MaxAmmo.Value <= 0 then
            Status("RestockStatus", "Ammo box unavailable"); return false
        end
        if Box.Ammo.Value > Box.MaxAmmo.Value * Threshold / 100 then
            Status("RestockStatus", "Ammo box stock sufficient"); return false
        end
        if not H or not self:Focused() then Status("RestockStatus", "Hide UI and focus to restock"); return false end
        if not self.Shop:BetweenRounds() then Status("RestockStatus", "Restock waits for round end"); return false end
        if not self.Shop:InShop() then self:TravelToShop(H, Root, "RestockStatus"); return true end
        self:CancelTravel(); self:ReleaseAim()
        local _, Message = self.Shop:TryRestock(Threshold)
        Status("RestockStatus", Message)
        return self.Shop.RestockPending ~= nil
    end
    function A:Upgrade(H, Root)
        local State, Pending = self.Shop:Poll()
        if State == "confirmed" then
            Guns:SetSuspended(false)
            self.LastConfirmed = Pending.Weapon .. "\0" .. Pending.Level.Name
            self.LastBuy = os.clock()
            self.InventoryDirty = true
            Status("UpgradeStatus", "Confirmed: " .. Pending.Level.Name)
        elseif State == "timeout" or State == "rejected" then
            Guns:SetSuspended(false)
            self.UnconfirmedWeapon = Pending.Weapon
            self:StopUpgrade("Upgrade unconfirmed; stopped to avoid repeat buys", false)
            return false
        elseif State == "waiting" then Status("UpgradeStatus", "Waiting for server confirmation"); return false end
        if not Flags.UpgradeEnabled or self.Refill.Pending or self.Shop.RestockPending or self.Shop.ReadyPending then return false end
        if self.UnconfirmedWeapon == Flags.UpgradeWeapon then
            self:StopUpgrade("Previous upgrade unconfirmed; check native shop manually", false)
            return false
        end
        local List = self:OrderedLevels()
        if #List == 0 then Status("UpgradeStatus", "Select an owned weapon and upgrade"); return false end
        local Complete = true
        for _, L in ipairs(List) do if L.Value < L.MaxValue then Complete = false end end
        if Complete then
            self:StopUpgrade(Flags.UpgradeMode == "All upgrades" and "Weapon fully upgraded" or "Selected upgrade fully upgraded", true)
            return false
        end
        if not H or not self:Focused() then Status("UpgradeStatus", "Hide UI and focus game to upgrade"); return false end
        if not self.Shop:BetweenRounds() then self:CancelTravel(); Status("UpgradeStatus", "Waiting for round end"); return false end
        if not self.Shop:InShop() then
            if Flags.UpgradeShopFallback then self:TravelToShop(H, Root); return true end
            Status("UpgradeStatus", "Enter shop after round end"); return false
        end
        self:CancelTravel(); self:ReleaseAim()
        if os.clock() - self.LastBuy >= 0.5 then
            self.LastBuy = os.clock()
            Guns:SetSuspended(true)
            local OK, Purchase, Reason = pcall(self.Shop.TryPurchase, self.Shop, Flags.UpgradeWeapon, List)
            if not OK then
                if not self.Shop.Pending then Guns:SetSuspended(false) end
                self:StopUpgrade("Native shop error; auto upgrade stopped", false)
            else
                if not Purchase then Guns:SetSuspended(false) end
                self.UpgradeIdle = not Purchase and type(Reason) == "string"
                    and (Reason == "Remaining upgrades locked" or Reason:find("Waiting for cash", 1, true) ~= nil)
                Status("UpgradeStatus", Reason or "Upgrade unavailable")
            end
        end
        return false
    end
    function A:AutoReady(H)
        local State = self.Shop:PollReady()
        if State == "waiting" then Status("ReadyStatus", "Waiting for native Ready reply"); return end
        if State == "unconfirmed" then Status("ReadyStatus", "Ready unconfirmed; no repeat vote"); return end
        if not Flags.FarmAutoReady then self.ReadyQuietSince = nil; return end
        if not H or not self:Focused() or not self.Shop:BetweenRounds() then self.ReadyQuietSince = nil; return end
        local Busy = self.Shop.Pending or self.Shop.RestockPending or self.Refill.Pending or self.Travelling or self.PathComputing
            or self.UnconfirmedWeapon or self.RestockError
            or Flags.UpgradeEnabled and not self.UpgradeIdle
        if not Busy and Flags.FarmAutoRefill then Busy = self:AmmoTool() ~= nil end
        if Busy then self.ReadyQuietSince = nil; Status("ReadyStatus", "Finishing enabled shop / ammo tasks"); return end
        self.ReadyQuietSince = self.ReadyQuietSince or os.clock()
        if os.clock() - self.ReadyQuietSince < 1.5 then Status("ReadyStatus", "Tasks settled; starting shortly"); return end
        local _, Message = self.Shop:TryReady()
        Status("ReadyStatus", Message)
    end
    function A:HideVisuals()
        for _, Line in ipairs(self.Lines) do Line.Visible = false end
        if self.DistanceText then self.DistanceText.Visible = false end
    end
    function A:Visuals(Root)
        local Camera = W.CurrentCamera
        if not Root or not Camera then self:HideVisuals(); return end
        local Now = os.clock()
        if self.DistanceText then self.DistanceText.Visible = Flags.FarmShowDistance == true end
        if Flags.FarmShowDistance and Now >= (self.NextDistanceText or 0) then
            self.NextDistanceText = Now + 0.1
            if not self.DistanceText then
                self.DistanceText = Drawing.new("Text"); self.DistanceText.Size = 14
                self.DistanceText.Font = Drawing.Fonts.UI; self.DistanceText.Center = true
                self.DistanceText.Outline = true; self.DistanceText.Color = Color3.fromRGB(200, 65, 75)
            end
            local Nearest = math.huge
            for _, Z in ipairs(self.Zombies) do
                if Z.Head.Parent and Z.Humanoid.Health > 0 then Nearest = math.min(Nearest, Flat(Root.Position - Z.Head.Position).Magnitude) end
            end
            self.DistanceText.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.7)
            self.DistanceText.Text = Nearest < math.huge and string.format("Nearest zombie: %.0f studs", Nearest) or "No live zombies"
            self.DistanceText.Visible = true
        end
        if Flags.FarmShowCircle then
            local Radius = math.max(Number(Flags.FarmDistance, 24, 5, 100), self.ResupplyEscapeRadius or 0)
            if self.CircleRadius ~= Radius then
                self.CircleRadius = Radius; self.CircleOffsets = {}
                for I = 0, 47 do
                    local Angle = I * math.pi / 24
                    self.CircleOffsets[I + 1] = Vector3.new(math.cos(Angle) * Radius, 0, math.sin(Angle) * Radius)
                end
            end
            local Center = Root.Position - Vector3.new(0, 2.6, 0)
            self.CirclePoints = self.CirclePoints or {}
            local Points = self.CirclePoints
            for I, Offset in ipairs(self.CircleOffsets) do
                local Point, OnScreen = Camera:WorldToViewportPoint(Center + Offset)
                Points[I] = Points[I] or {}
                Points[I].Point = Point; Points[I].Visible = OnScreen and Point.Z > 0
            end
            for Index = 1, 48 do
                local Line = self.Lines[Index]
                if not Line then
                    Line = Drawing.new("Line"); Line.Color = Color3.fromRGB(235, 24, 59)
                    Line.Thickness = 2; Line.Transparency = 0.85; self.Lines[Index] = Line
                end
                local X, Y = Points[Index], Points[Index % 48 + 1]
                Line.Visible = X.Visible and Y.Visible
                if Line.Visible then
                    Line.From = Vector2.new(X.Point.X, X.Point.Y); Line.To = Vector2.new(Y.Point.X, Y.Point.Y)
                end
            end
        else
            for _, Line in ipairs(self.Lines) do Line.Visible = false end
        end
    end
    function A:Step()
        local Now = os.clock()
        local Active = Flags.FarmAutoShoot or Flags.FarmKeepDistance or Flags.FarmShowDistance or Flags.FarmShowCircle or Flags.UpgradeEnabled or Flags.FarmAutoRefill or Flags.FarmRestockBox or Flags.FarmAutoReady
        if self.InventoryDirty or (Active or Library.WindowVisible) and Now - self.LastScan >= 1 then self:ScanInventory() end
        self:CameraState()
        local _, H, Root = self:Character()
        if Active and self:Focused() then self:SnapshotZombies() end
        local Restocking = self:Restock(H, Root)
        local Travelling = not Restocking and self:Upgrade(H, Root)
        if not H or not self:Focused() or self.Shop.Pending or self.Shop.RestockPending then
            self:ReleaseAim(); self:StopMovement(); self:CancelTravel(); self.Navigation:Reset()
            self.Refill:Poll()
            if Flags.FarmAutoShoot or Flags.FarmKeepDistance then Status("FarmStatus", not H and "Waiting for respawn" or "Hide UI and focus Roblox") end
        elseif Travelling or Restocking then self:ReleaseAim(); self.Navigation:Reset()
        else
            if self.TravelPurpose == "shop" then self:CancelTravel() end
            local Distance = self.Navigation:Separation(Root.Position, self.Zombies)
            local Radius = math.max(Number(Flags.FarmDistance, 24, 5, 100), self.ResupplyEscapeRadius or 0)
            local Retreat = Flags.FarmKeepDistance and (Distance < Radius or self.Navigation.Active and Distance < Radius + 8)
            if Retreat then
                self:CancelTravel(); self:Kite(H, Root, Radius)
                self.Refill:Poll(); Status("AmmoStatus", Flags.FarmAutoRefill and "Retreating before resupply" or "Auto refill off")
            else
                self.Navigation:Reset(); self.ResupplyEscapeRadius = nil
                local AmmoTravelling = self:AutoRefill(H, Root)
                if not AmmoTravelling then self:StopMovement() end
            end
            if not Flags.FarmAutoShoot then self:ReleaseAim() end
        end
        self:AutoReady(H)
        local State = not H and "WAITING | respawn" or Library.WindowVisible and "PAUSED | menu open"
            or not self:Focused() and "PAUSED | Roblox unfocused" or self.Shop.Pending and "SHOP | weapon upgrade"
            or self.Shop.RestockPending and "SHOP | box restock" or self.Refill.Pending and "RESUPPLY | native interaction"
            or self.TravelPurpose == "ammo" and "RESUPPLY | travelling" or self.TravelPurpose == "shop" and "SHOP | travelling"
            or self.MoveDirection and "RETREAT | creating distance" or Flags.FarmAutoShoot and (self:NativeFocused() and "FARM | head targeting" or "BACKGROUND | native firing")
            or "READY | automation off"
        Status("RunStatus", State)
        if Library.RunStatus and Library.RunStatus.SetColor and Library.Theme then
            Library.RunStatus:SetColor(self:Focused() and Active and Library.Theme.Accent[1] or Library.Theme.TextInactive)
        end
        self:RefreshRender()
    end
    function A:PreRender(DeltaTime)
        self:RestoreView()
        if not self.Alive then return end
        self.FrameDelta = Number(DeltaTime, self.FrameDelta or 1 / 60, 1 / 1000, 1 / 15)
        if not Flags.FarmAutoShoot then return end
        local _, H, Root = self:Character()
        local Camera = W.CurrentCamera
        if not (H and Camera and self:Focused() and (not self.Travelling or self.TravelPurpose == "ammo") and not self.Shop.Pending and not self.Shop.RestockPending and not self.Shop.ReadyPending and not self.Refill.Pending and Flags.FarmAutoShoot) then
            self:ReleaseAim(); return
        end
        local Tool = self:Equipped()
        if not Tool then self:ReleaseAim(); self:Equip(H); Status("FarmStatus", "Equipping an available gun"); return end
        local B = Guns.Weapons[Tool] or Guns:BindWeapon(Tool)
        local Range = B and B.Environment.Range or Value(Tool, "Range", 0)
        local Head = P.Character:FindFirstChild("Head")
        local Origin = Head and Head.Position or Root.Position + Vector3.new(0, 1.5, 0)
        if (not self.Target or self.Target.Humanoid.Health <= 0) and os.clock() - (self.LastZombieScan or -10) >= 0.03 then
            self:SnapshotZombies()
        end
        local Target = self:SelectTarget(Origin, Number(Range, 0, 0, 1000000), Tool, true)
        if not Target then self:ReleaseAim(); Status("FarmStatus", "No visible head in native range"); return end
        self:Aim(Camera, Root, Target)
        if self.AimError < 0.25 then self:Shoot(Tool) else self:ReleaseMouse(); Status("FarmStatus", "Waiting for head alignment") end
    end
    function A:Render()
        self:RestoreView()
        if not self.Alive then return end
        local _, H, Root = self:Character()
        if H and self:Focused() and self.MoveDirection then H:Move(self.MoveDirection, false) end
        if Flags.FarmShowCircle or os.clock() - self.LastVisual >= 0.1 then
            self.LastVisual = os.clock(); self:Visuals(Root)
        end
    end
    function A:Fail(Error)
        self:ReleaseAim(); self:StopMovement(); self:CancelTravel(); self.Navigation:Reset(); self:HideVisuals()
        if not self.Shop.Pending then Guns:SetSuspended(false) end
        self.Failed = true
        Notify("runtime-error", "Automation paused: " .. tostring(Error))
        self:RefreshRender()
    end
    function A:RefreshRender()
        local Need = not self.Failed and (Flags.FarmAutoShoot or Flags.FarmKeepDistance or Flags.FarmShowDistance or Flags.FarmShowCircle)
        if Need and not self.Rendering then
            self.Rendering = true
            Run:BindToRenderStep(RenderName .. "Aim", Enum.RenderPriority.Camera.Value + 1, function(DeltaTime)
                local OK, Error = pcall(self.PreRender, self, DeltaTime)
                if not OK then self:Fail(Error) end
            end)
            Run:BindToRenderStep(RenderName, Enum.RenderPriority.Last.Value + 1, function()
                local OK, Error = pcall(self.Render, self)
                if not OK then self:Fail(Error) end
            end)
        elseif not Need and self.Rendering then
            Run:UnbindFromRenderStep(RenderName .. "Aim"); Run:UnbindFromRenderStep(RenderName); self.Rendering = false; self:HideVisuals()
        end
    end
    function A:Destroy()
        if not self.Alive then return end
        self.Alive = false; self.PathToken = nil
        self:ReleaseAim(); self:StopMovement(); self:HideVisuals()
        if self.ReleasePending or self.SprintReleasePending then
            -- OS releases ignored while unfocused must finish once focus returns, including after unload.
            local FinalRelease
            FinalRelease = Input.WindowFocused:Connect(function()
                self.WindowFocused = true
                self:ReleaseMouse(); self:Sprint(false); FinalRelease:Disconnect()
            end)
        end
        if self.Rendering then Run:UnbindFromRenderStep(RenderName .. "Aim"); Run:UnbindFromRenderStep(RenderName); self.Rendering = false end
        for _, C in ipairs(self.Connections) do C:Disconnect() end
        for _, Bucket in pairs(self.Watches) do for _, C in ipairs(Bucket) do C:Disconnect() end end
        for Item, Record in pairs(self.Callbacks) do if Item.Callback == Record.Owned then Item.Callback = Record.Previous end end
        self.Shop:Destroy(); self.Navigation:Destroy(); self.Refill:Destroy(); Guns:SetSuspended(false)
        local Third = Flags.CameraThirdPerson; Flags.CameraThirdPerson = false; self:CameraState(); Flags.CameraThirdPerson = Third
        for _, Line in ipairs(self.Lines) do Line:Remove() end
        if self.DistanceText then self.DistanceText:Remove() end
    end
    local function Own(Key, Action)
        local Item = Library.Items[Key]
        if not Item then return end
        local Previous = Item.Callback
        local Owned = function(V)
            Previous(V)
            if not A.Alive then return end
            A.Failed = false
            Action(V)
            A:RefreshRender()
        end
        A.Callbacks[Item] = {Previous = Previous, Owned = Owned}; Item.Callback = Owned
    end
    Own("UpgradeWeapon", function()
        A.UpgradeIdle = false; A.ReadyQuietSince = nil
        if not A.Scanning then A.SavedWeapon = nil; A.SavedPriority = nil end
        A:ScanPriorities(); A:CancelTravel()
    end)
    Own("UpgradePriority", function() A.SavedPriority = nil; A.UpgradeIdle = false; A.ReadyQuietSince = nil end)
    Own("UpgradeEnabled", function(V) A.Notices["upgrade-stop"] = nil; if not V then A:CancelTravel() end end)
    Own("UpgradeShopFallback", function(V) if not V then A:CancelTravel() end end)
    Own("FarmAutoShoot", function(V) if not V then A:ReleaseAim() end end)
    Own("FarmKeepDistance", function(V) if not V then A:StopMovement(); A.Navigation:Reset() end end)
    Own("FarmAutoRefill", function(V) if not V and A.TravelPurpose == "ammo" then A:CancelTravel() end end)
    Own("FarmBackground", function()
        A:ReleaseAim(); A:StopMovement(); A:CancelTravel(); A.Navigation:Reset(); Guns:Refresh()
    end)
    Own("FarmRestockBox", function(V) if not V and not Flags.UpgradeEnabled then A:CancelTravel() end end)
    Own("FarmUseSprint", function(V) if not V then A:Sprint(false) end end)
    Own("FarmShowDistance", function() A:HideVisuals() end)
    Own("FarmShowCircle", function() A:HideVisuals() end)
    Own("CameraThirdPerson", function() A:CameraState() end)
    Own("CameraDistance", function() A:CameraState() end)
    Connect(P.CharacterAdded, function(C) A:ReleaseAim(); A:StopMovement(); A:CancelTravel(); A:Watch("Character", C) end)
    Connect(P.ChildAdded, function(C)
        if C:IsA("Backpack") or C.Name == "Backgear" or C.Name == "Upgrades" then A:Watch(C.Name, C) end
    end)
    Connect(Input.WindowFocusReleased, function()
        A.WindowFocused = false
        A:ReleaseAim(); A:StopMovement(); A:CancelTravel(); A.Navigation:Reset(); A:CameraState()
    end)
    Connect(Input.WindowFocused, function()
        A.WindowFocused = true
        A:ReleaseMouse(); A:Sprint(false); A:CameraState()
    end)
    A:Watch("Character", P.Character)
    A:Watch("Backpack", P:FindFirstChildOfClass("Backpack"))
    A:Watch("Backgear", P:FindFirstChild("Backgear")); A:Watch("Upgrades", P:FindFirstChild("Upgrades"))
    Connect(Run.Heartbeat, function()
        if not A.Alive or os.clock() - A.LastStep < 0.1 then return end
        A.LastStep = os.clock()
        if A.Failed then
            if A.Shop.Pending then pcall(A.Upgrade, A, nil, nil) end
            return
        end
        local OK, Error = pcall(A.Step, A)
        if not OK then A:Fail(Error) end
    end)
    A:ScanInventory(); A:CameraState(); A:RefreshRender()
    Status("FarmStatus", "Head lock uses native weapon range")
    Status("UpgradeStatus", "Inventory scanned; select a weapon")
    return A
end
