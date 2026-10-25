-- Native input, inventory discovery, movement and cash upgrades. No shot packets are fabricated.
return function(Library: any, Window: any, Guns: any, CreateShopAdapter: any)
    local P: any = game:GetService("Players").LocalPlayer
    local Run = game:GetService("RunService")
    local Input = game:GetService("UserInputService")
    local Paths = game:GetService("PathfindingService")
    local RS: any = game:GetService("ReplicatedStorage")
    local W: any = workspace
    local Flags = Library.Flags
    local A: any = {Alive = true, Connections = {}, Watches = {}, Callbacks = {}, Inventory = {},
        Shop = CreateShopAdapter(), Zombies = {}, LastScan = -10, LastStep = -10, LastVisual = -10,
        LastBuy = -10, NextPress = 0, Lines = {}, Notices = {}, InventoryDirty = true}
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
    function A:Focused()
        return isrbxactive() == true and Input:GetFocusedTextBox() == nil
            and not Library.WindowVisible and not Library.CapturingMenuKey
    end
    function A:ReleaseMouse()
        if self.MouseOwned then
            -- Clear only the latch belonging to our own press; native input can ignore releases unfocused.
            local B = self.PressedBinding
            if B and B.Environment then B.Environment.mouse1Down = false end
            self.ReleasePending = true
        end
        if self.ReleasePending and isrbxactive() then
            mouse1release()
            self.ReleasePending = false
        end
        self.MouseOwned = false
        self.PressedBinding = nil
    end
    function A:Sprint(State)
        if not State and self.SprintOwned then self.SprintReleasePending = true end
        if self.SprintReleasePending and isrbxactive() then
            keyrelease(0xA0); self.SprintOwned = false; self.SprintReleasePending = false
        end
        if State and not self.SprintOwned and not self.SprintReleasePending and isrbxactive()
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
        if self.MouseBehavior then Input.MouseBehavior = self.MouseBehavior; self.MouseBehavior = nil end
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
        if not table.find(Options, Selected) then Selected = Options[2] or Options[1] end
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
    function A:SelectTarget(Origin, Range, Tool)
        local function Valid(Z)
            local Folder = W:FindFirstChild("Zombies")
            return Folder ~= nil and Z and Z.Model.Parent == Folder and Z.Head.Parent and Z.Humanoid.Health > 0
                and (Z.Head.Position - Origin).Magnitude <= Range and self:Visible(Origin, Z, Tool)
        end
        if Valid(self.Target) then return self.Target end
        local Best, Distance = nil, math.huge
        for _, Z in ipairs(self.Zombies) do
            if Valid(Z) then
                local D = (Z.Head.Position - Origin).Magnitude
                if D < Distance then Best = Z; Distance = D end
            end
        end
        self.Target = Best
        return Best
    end
    function A:Equipped()
        if P.Character then
            for _, T in ipairs(P.Character:GetChildren()) do
                if T:IsA("Tool") and T:FindFirstChild("GunScript") and T:FindFirstChild("CurrentValues") then return T end
            end
        end
        return nil
    end
    function A:Equip(H)
        if self.Equipping or os.clock() < (self.NextEquip or 0) then return end
        local Bag = P:FindFirstChildOfClass("Backpack")
        local Best
        if Bag then
            for _, T in ipairs(Bag:GetChildren()) do
                if T:IsA("Tool") and T:FindFirstChild("GunScript") and T:FindFirstChild("CurrentValues")
                    and (Value(T, "Clip", 0) ~= 0 or Value(T, "Ammo", 0) ~= 0) then Best = T; break end
            end
        end
        if Best then
            self.Equipping = true; self.NextEquip = os.clock() + 1
            task.spawn(function()
                if self.Alive and Flags.FarmAutoShoot and self:Focused() and H.Parent == P.Character then pcall(H.EquipTool, H, Best) end
                self.Equipping = false
            end)
        end
    end
    function A:CameraState()
        if Flags.CameraThirdPerson then
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
    function A:Aim(Camera, Root, Target)
        if not self.MouseBehavior then self.MouseBehavior = Input.MouseBehavior end
        Input.MouseBehavior = Enum.MouseBehavior.LockCenter
        local Origin = Camera.CFrame.Position
        if Flags.CameraThirdPerson then
            local Head = P.Character and P.Character:FindFirstChild("Head")
            local Pivot = Head and Head.Position or Root.Position + Vector3.new(0, 1.5, 0)
            local Direction = Unit(Target.Head.Position - Pivot)
            local Desired = Pivot - Direction * Number(Flags.CameraDistance, 10, 4, 24) + Vector3.new(0, 1, 0)
            local Hit = W:Raycast(Pivot, Desired - Pivot, self:Params(true))
            Origin = Hit and Hit.Position + Hit.Normal * 0.4 or Desired
        end
        Camera.CFrame = CFrame.lookAt(Origin, Target.Head.Position)
        Camera.Focus = CFrame.new(Target.Head.Position)
    end
    function A:Shoot(Tool)
        local B = Guns.Weapons[Tool] or Guns:BindWeapon(Tool)
        if not B then self:ReleaseMouse(); Status("FarmStatus", "Waiting for native gun script"); return end
        if Value(Tool, "Clip", 0) == 0 then
            self:ReleaseMouse()
            if Value(Tool, "Ammo", 0) ~= 0 and not self.Reloading and os.clock() > (self.NextReload or 0)
                and type(B.Environment.reload) == "function" then
                self.Reloading = true; self.NextReload = os.clock() + 1
                task.spawn(function()
                    if self.Alive and Flags.FarmAutoShoot and Tool.Parent == P.Character then pcall(B.Environment.reload) end
                    self.Reloading = false
                end)
            end
            Status("FarmStatus", Value(Tool, "Ammo", 0) == 0 and "Out of ammunition" or "Native reload")
            return
        end
        local FireType = Value(Tool, "FireType", "Single")
        if FireType == "Charge" then self:ReleaseMouse(); Status("FarmStatus", "Charge weapons need manual fire"); return end
        if self.MouseOwned and self.PressedBinding ~= B then self:ReleaseMouse() end
        if self.MouseOwned and FireType ~= "FullAuto" and FireType ~= "Continuous" then
            if os.clock() >= self.PressRelease then self:ReleaseMouse() end
        elseif not self.MouseOwned and os.clock() >= self.NextPress
            and not Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not self.ReleasePending then
            mouse1press(); self.MouseOwned = true; self.PressedBinding = B
            self.PressRelease = os.clock() + 0.035
            self.NextPress = os.clock() + math.max(0.08, 60 / Number(Value(Tool, "AttackSpeed", 300), 300, 1, 7200))
        end
        Status("FarmStatus", "Head lock: " .. self.Target.Model.Name)
    end
    function A:ChooseEscape(Root, Radius)
        local Position = Root.Position
        local Away, Nearest = Vector3.zero, math.huge
        for _, Z in ipairs(self.Zombies) do
            local Delta = Flat(Position - Z.Head.Position)
            local D = Delta.Magnitude
            Nearest = math.min(Nearest, D)
            if D < Radius + 8 then Away = Away + Unit(Delta) * (Radius + 8 - D) end
        end
        self.Nearest = Nearest
        if Nearest >= Radius then return nil end
        if Away.Magnitude < 0.01 then
            local Z = self.Zombies[1]
            Away = Z and Unit(Flat(Position - Z.Head.Position)) or Vector3.new(1, 0, 0)
            if Away.Magnitude < 0.01 then Away = Vector3.new(1, 0, 0) end
        end
        Away = Unit(Away)
        local Params = self:Params(true)
        local Best, Score = nil, -math.huge
        local Travel = math.clamp(Radius * 0.3, 5, 10)
        for Index = 0, 15 do
            local Angle = Index * math.pi / 8
            local Direction = Vector3.new(math.cos(Angle), 0, math.sin(Angle))
            local Hit = W:Blockcast(CFrame.new(Position), Vector3.new(2.8, 3.5, 2.8), Direction * Travel, Params)
            local Clearance = Hit and Hit.Distance or Travel
            local End = Position + Direction * math.min(Travel, math.max(0, Clearance - 0.6))
            local Ground = W:Raycast(End + Vector3.new(0, 3, 0), Vector3.new(0, -10, 0), Params)
            -- Cliffs and steep surfaces are always excluded; walls may still steer even with the preference off.
            if Clearance >= 3 and Ground and Ground.Normal.Y >= 0.6 and math.abs(Ground.Position.Y - (Position.Y - 3)) < 4 then
                local Safe = math.huge
                for _, Z in ipairs(self.Zombies) do Safe = math.min(Safe, Flat(End - Z.Head.Position).Magnitude) end
                local S = math.min(Safe, Radius + 15) * 2 + Direction:Dot(Away) * 5
                    + (Flags.FarmAvoidWalls and Clearance or 0)
                if self.StuckDirection then S = S - math.max(0, Direction:Dot(self.StuckDirection)) * 20 end
                if S > Score then Score = S; Best = Direction end
            end
        end
        return Best
    end
    function A:Kite(H, Root)
        if not self.LastPosition or os.clock() - self.LastPositionAt >= 1 then
            if self.LastPosition and self.MoveDirection and (Root.Position - self.LastPosition).Magnitude < 1 then
                self.StuckDirection = self.MoveDirection; self.StuckUntil = os.clock() + 2
            end
            self.LastPosition = Root.Position; self.LastPositionAt = os.clock()
        end
        if self.StuckUntil and os.clock() >= self.StuckUntil then self.StuckDirection = nil end
        self.MoveDirection = self:ChooseEscape(Root, Number(Flags.FarmDistance, 24, 5, 100))
        if self.MoveDirection then
            self.MovingHumanoid = H
            self:Sprint(Flags.FarmUseSprint == true)
        else
            self:StopMovement()
            if self.Nearest < Number(Flags.FarmDistance, 24, 5, 100) then Status("FarmStatus", "No safe retreat path") end
        end
    end
    function A:TravelToShop(H, Root)
        local Regions = RS:FindFirstChild("ShopRegions")
        local Region = Regions and Regions:FindFirstChild("MainShopRegion")
        if not Region or not Region:IsA("BasePart") then Status("UpgradeStatus", "Shop location unavailable"); return end
        if self.PathFailedUntil and os.clock() < self.PathFailedUntil then Status("UpgradeStatus", "Shop path blocked; retrying shortly"); return end
        if not self.Route and not self.PathComputing then
            self.PathComputing = true
            local Token = {}; self.PathToken = Token
            local Ground = W:Raycast(Region.Position + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0), self:Params(true))
            local Destination = Ground and Ground.Position or Region.Position
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
        Status("UpgradeStatus", "Walking to shop")
    end
    function A:CancelTravel()
        self.PathToken = nil; self.PathComputing = false; self.Route = nil
        if self.Travelling then self:StopMovement() end
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
        if not Flags.UpgradeEnabled then return false end
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
                Status("UpgradeStatus", Reason or "Upgrade unavailable")
            end
        end
        return false
    end
    function A:HideVisuals()
        for _, Line in ipairs(self.Lines) do Line.Visible = false end
        if self.DistanceText then self.DistanceText.Visible = false end
    end
    function A:Visuals(Root)
        self:HideVisuals()
        local Camera = W.CurrentCamera
        if not Root or not Camera then return end
        if Flags.FarmShowDistance then
            if not self.DistanceText then
                self.DistanceText = Drawing.new("Text"); self.DistanceText.Size = 14
                self.DistanceText.Font = Drawing.Fonts.UI; self.DistanceText.Center = true
                self.DistanceText.Outline = true; self.DistanceText.Color = Color3.fromRGB(200, 65, 75)
            end
            local Nearest = math.huge
            for _, Z in ipairs(self.Zombies) do Nearest = math.min(Nearest, Flat(Root.Position - Z.Head.Position).Magnitude) end
            self.DistanceText.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.7)
            self.DistanceText.Text = Nearest < math.huge and string.format("Nearest zombie: %.0f studs", Nearest) or "No live zombies"
            self.DistanceText.Visible = true
        end
        if Flags.FarmShowCircle then
            local Radius = Number(Flags.FarmDistance, 24, 5, 100)
            for Index = 1, 48 do
                local Line = self.Lines[Index]
                if not Line then
                    Line = Drawing.new("Line"); Line.Color = Color3.fromRGB(125, 15, 30)
                    Line.Thickness = 1; Line.Transparency = 0.7; self.Lines[Index] = Line
                end
                local Angle = (Index - 1) * math.pi / 24
                local Next = Index * math.pi / 24
                local Center = Root.Position - Vector3.new(0, 2.6, 0)
                local X, OnX = Camera:WorldToViewportPoint(Center + Vector3.new(math.cos(Angle) * Radius, 0, math.sin(Angle) * Radius))
                local Y, OnY = Camera:WorldToViewportPoint(Center + Vector3.new(math.cos(Next) * Radius, 0, math.sin(Next) * Radius))
                if OnX and OnY and X.Z > 0 and Y.Z > 0 then
                    Line.From = Vector2.new(X.X, X.Y); Line.To = Vector2.new(Y.X, Y.Y); Line.Visible = true
                end
            end
        end
    end
    function A:Step()
        local Now = os.clock()
        local Active = Flags.FarmAutoShoot or Flags.FarmKeepDistance or Flags.FarmShowDistance or Flags.FarmShowCircle or Flags.UpgradeEnabled
        if self.InventoryDirty or (Active or Library.WindowVisible) and Now - self.LastScan >= 1 then self:ScanInventory() end
        self:CameraState()
        local _, H, Root = self:Character()
        local Travelling = self:Upgrade(H, Root)
        if Active then self:SnapshotZombies() end
        if not H or not self:Focused() or self.Shop.Pending then
            self:ReleaseAim(); self:StopMovement(); self:CancelTravel()
            if Flags.FarmAutoShoot or Flags.FarmKeepDistance then Status("FarmStatus", not H and "Waiting for respawn" or "Hide UI and focus Roblox") end
        elseif Travelling then self:ReleaseAim()
        else
            if not Flags.UpgradeEnabled or not self.Shop:BetweenRounds() then self:CancelTravel() end
            if Flags.FarmKeepDistance then self:Kite(H, Root) else self:StopMovement() end
            if not Flags.FarmAutoShoot then self:ReleaseAim() end
        end
        self:RefreshRender()
    end
    function A:Render()
        if not self.Alive then return end
        local _, H, Root = self:Character()
        local Camera = W.CurrentCamera
        if H and self:Focused() and not self.Travelling and not self.Shop.Pending then
            if self.MoveDirection then H:Move(self.MoveDirection, false) end
            if Flags.FarmAutoShoot and Camera then
                local Tool = self:Equipped()
                if Tool then
                    local B = Guns.Weapons[Tool]
                    local Range = B and B.Environment.Range or Value(Tool, "Range", 0)
                    local Origin = Root.Position + Vector3.new(0, 1.5, 0)
                    local Target = self:SelectTarget(Origin, Number(Range, 0, 0, 1000000), Tool)
                    if Target then
                        self:Aim(Camera, Root, Target)
                        -- Allow native mouse coordinates to settle for one frame after acquiring a head.
                        if self.AimedAt == Target.Head then self:Shoot(Tool)
                        else self:ReleaseMouse(); self.AimedAt = Target.Head end
                    else self:ReleaseAim(); Status("FarmStatus", "No visible zombie in native range") end
                else self:ReleaseAim(); self:Equip(H); Status("FarmStatus", "Equipping an available gun") end
            else self:ReleaseAim() end
        else self:ReleaseAim() end
        if os.clock() - self.LastVisual >= 0.05 then
            self.LastVisual = os.clock(); self:Visuals(Root)
        end
    end
    function A:Fail(Error)
        self:ReleaseAim(); self:StopMovement(); self:CancelTravel(); self:HideVisuals()
        if not self.Shop.Pending then Guns:SetSuspended(false) end
        self.Failed = true
        Notify("runtime-error", "Automation paused: " .. tostring(Error))
        self:RefreshRender()
    end
    function A:RefreshRender()
        local Need = not self.Failed and (Flags.FarmAutoShoot or Flags.FarmKeepDistance or Flags.FarmShowDistance or Flags.FarmShowCircle)
        if Need and not self.Rendering then
            self.Rendering = true
            Run:BindToRenderStep(RenderName, Enum.RenderPriority.Last.Value + 1, function()
                local OK, Error = pcall(self.Render, self)
                if not OK then self:Fail(Error) end
            end)
        elseif not Need and self.Rendering then
            Run:UnbindFromRenderStep(RenderName); self.Rendering = false; self:HideVisuals()
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
                self:ReleaseMouse(); self:Sprint(false); FinalRelease:Disconnect()
            end)
        end
        if self.Rendering then Run:UnbindFromRenderStep(RenderName); self.Rendering = false end
        for _, C in ipairs(self.Connections) do C:Disconnect() end
        for _, Bucket in pairs(self.Watches) do for _, C in ipairs(Bucket) do C:Disconnect() end end
        for Item, Record in pairs(self.Callbacks) do if Item.Callback == Record.Owned then Item.Callback = Record.Previous end end
        self.Shop:Destroy(); Guns:SetSuspended(false)
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
        if not A.Scanning then A.SavedWeapon = nil; A.SavedPriority = nil end
        A:ScanPriorities(); A:CancelTravel()
    end)
    Own("UpgradePriority", function() A.SavedPriority = nil end)
    Own("UpgradeEnabled", function(V) A.Notices["upgrade-stop"] = nil; if not V then A:CancelTravel() end end)
    Own("UpgradeShopFallback", function(V) if not V then A:CancelTravel() end end)
    Own("FarmAutoShoot", function(V) if not V then A:ReleaseAim() end end)
    Own("FarmKeepDistance", function(V) if not V then A:StopMovement() end end)
    Own("FarmUseSprint", function(V) if not V then A:Sprint(false) end end)
    Own("FarmShowDistance", function() A:HideVisuals() end)
    Own("FarmShowCircle", function() A:HideVisuals() end)
    Own("CameraThirdPerson", function() A:CameraState() end)
    Own("CameraDistance", function() A:CameraState() end)
    Connect(P.CharacterAdded, function(C) A:ReleaseAim(); A:StopMovement(); A:CancelTravel(); A:Watch("Character", C) end)
    Connect(P.ChildAdded, function(C)
        if C:IsA("Backpack") or C.Name == "Backgear" or C.Name == "Upgrades" then A:Watch(C.Name, C) end
    end)
    Connect(Input.WindowFocusReleased, function() A:ReleaseAim(); A:StopMovement(); A:CancelTravel() end)
    Connect(Input.WindowFocused, function() A:ReleaseMouse(); A:Sprint(false) end)
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
