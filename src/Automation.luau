-- Native input, inventory discovery, movement and cash upgrades. No shot packets are fabricated.
return function(Library: any, Window: any, Guns: any, CreateShopAdapter: any, CreateNavigation: any, CreateAmmoAdapter: any)
    local P: any = game:GetService("Players").LocalPlayer
    local Run = game:GetService("RunService")
    local Input = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
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
    -- Automation lifetime and physical input ownership are separate. Menus do not stop native work.
    function A:Focused() return self.Alive and not self.Failed end
    function A:InputAvailable()
        return self:NativeFocused() and Input:GetFocusedTextBox() == nil
            and not Library.WindowVisible and not Library.CapturingMenuKey and not GuiService.MenuIsOpen
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
        if not self:InputAvailable() then State = false end
        if State then
            local Values = P:FindFirstChild("PlayerValues")
            local Current = Values and Values:FindFirstChild("Stamina")
            local Maximum = Values and Values:FindFirstChild("StaminaMax")
            if Current and Maximum and Maximum.Value > 0 then
                local Ratio = Current.Value / Maximum.Value
                if Ratio <= 0.05 then self.SprintRecovering = true end
                if Ratio >= 0.25 or (self.Nearest or math.huge) < 8 and Ratio >= 0.08 then self.SprintRecovering = false end
                if self.SprintRecovering then State = false end
            end
        end
        if not State and self.SprintOwned then self.SprintReleasePending = true end
        if self.SprintReleasePending and self:NativeFocused() then
            keyrelease(0xA0); self.SprintOwned = false; self.SprintReleasePending = false
        end
        if State and not self.SprintOwned and not self.SprintReleasePending and self:NativeFocused()
            and not Input:IsKeyDown(Enum.KeyCode.LeftShift) and not Input:IsKeyDown(Enum.KeyCode.RightShift) then
            keypress(0xA0); self.SprintOwned = true
        end
    end
    function A:ManualMovement()
        if not self:InputAvailable() then return false end
        for _, Key in ipairs({Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
            Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right}) do
            if Input:IsKeyDown(Key) then self.ManualUntil = os.clock() + 0.25; return true end
        end
        return os.clock() < (self.ManualUntil or 0)
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
        self.Target = nil; self.AimedAt = nil; self.BurstPlan = nil
    end
    function A:ScanInventory()
        if self.BindShotFeedback then self:BindShotFeedback() end
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
        self.ScanningLoadout = true
        if Library.RefreshLoadout then Library.RefreshLoadout(Names) end
        if self.SavedLoadout then
            for Key, Name in pairs(self.SavedLoadout) do
                if Owned[Name] ~= nil and Library.Items[Key] then Library.Items[Key]:Set(Name); self.SavedLoadout[Key] = nil end
            end
        end
        self.ScanningLoadout = false
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
        local Profiles = {}
        if type(Values.GunRateProfiles) == "table" then
            local Count = 0
            for Name, Rate in pairs(Values.GunRateProfiles) do
                if type(Name) == "string" and #Name <= 100 and type(Rate) == "number" and Rate == Rate and math.abs(Rate) < math.huge and Count < 128 then
                    Profiles[Name] = math.clamp(Rate, 1, 120); Count = Count + 1
                end
            end
        end
        Library.GunRateProfiles = Profiles
        self.SavedLoadout = {}
        for _, Key in ipairs({"FarmMainWeapon", "FarmBackupWeapon", "GunPresetWeapon"}) do
            if type(Values[Key]) == "string" then self.SavedLoadout[Key] = Values[Key] end
        end
        if Guns.QueueRefresh then Guns:QueueRefresh() end
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
        local Cache = self.VisibilityCache
        if not Cache or Cache.Tool ~= Tool or Cache.Character ~= P.Character or Cache.Camera ~= W.CurrentCamera or os.clock() >= Cache.Expires then
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
            Cache = {Tool = Tool, Character = P.Character, Camera = W.CurrentCamera, Params = Params, Expires = os.clock() + 0.25}
            self.VisibilityCache = Cache
        end
        local Params = Cache.Params
        local Hit = W:Raycast(Origin, Z.Head.Position - Origin, Params)
        return Hit == nil or Hit.Instance:IsDescendantOf(Z.Model)
    end
    function A:SelectTarget(Origin, Range, Tool, ThrottleSearch)
        local Folder = W:FindFirstChild("Zombies")
        local RangeSquared = Range * Range
        local function Valid(Z)
            if not Folder or not Z or Z.Model.Parent ~= Folder or not Z.Head.Parent or Z.Humanoid.Health <= 0 then return false end
            local Delta = Z.Head.Position - Origin
            return Delta:Dot(Delta) <= RangeSquared
        end
        local Now, Used = os.clock(), 0
        self.OccludedUntil = self.OccludedUntil or setmetatable({}, {__mode = "k"})
        local Cooldown = math.max(0.25, math.ceil(#self.Zombies / 8) / 30 + 0.1)
        if Valid(self.Target) then
            Used = 1
            if self:Visible(Origin, self.Target, Tool) then return self.Target end
            self.OccludedUntil[self.Target.Model] = Now + Cooldown
        end
        local Previous = self.Target; self.Target = nil
        if ThrottleSearch and not Previous and Now < (self.NextTargetSearch or 0) then return nil end
        self.NextTargetSearch = Now + 1 / 30
        local Budget = ThrottleSearch and 8 - Used or math.huge
        local Candidates = {}
        local function Before(Rank, Distance, Other) return Rank < Other.Rank or Rank == Other.Rank and Distance < Other.Distance end
        for _, Z in ipairs(self.Zombies) do
            if Valid(Z) and (not ThrottleSearch or Now >= (self.OccludedUntil[Z.Model] or 0)) then
                local Delta = Z.Head.Position - Origin
                local Distance = Delta:Dot(Delta)
                local Rank = ThrottleSearch and (self.OccludedUntil[Z.Model] or -math.huge) or 0
                if not ThrottleSearch then
                    table.insert(Candidates, {Zombie = Z, Distance = Distance, Rank = Rank})
                elseif #Candidates < Budget or Before(Rank, Distance, Candidates[#Candidates]) then
                    local Index = #Candidates + 1
                    while Index > 1 and Before(Rank, Distance, Candidates[Index - 1]) do Index = Index - 1 end
                    table.insert(Candidates, Index, {Zombie = Z, Distance = Distance, Rank = Rank})
                    if #Candidates > Budget then table.remove(Candidates) end
                end
            end
        end
        if not ThrottleSearch then table.sort(Candidates, function(X, Y) return X.Distance < Y.Distance end) end
        for _, Candidate in ipairs(Candidates) do
            if self:Visible(Origin, Candidate.Zombie, Tool) then self.Target = Candidate.Zombie; return self.Target end
            self.OccludedUntil[Candidate.Zombie.Model] = Now + Cooldown
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
        self.NextEquip = os.clock() + 0.35
        local Bag = P:FindFirstChildOfClass("Backpack")
        local Best = Preferred
        if Bag and not Best then
            local Score = -math.huge
            for _, T in ipairs(Bag:GetChildren()) do
                if T:IsA("Tool") and T:FindFirstChild("GunScript") and T:FindFirstChild("CurrentValues")
                    and Value(T, "FireType", "Single") ~= "Charge"
                    and (Value(T, "Clip", 0) ~= 0 or Value(T, "Ammo", 0) ~= 0) then
                    local Clip = Value(T, "Clip", 0)
                    local Ready = Clip ~= 0 and 100000 or 0
                    local Loaded = Clip < 0 and 1000 or math.clamp(Clip, 0, 1000)
                    local Preference = T.Name == Flags.FarmMainWeapon and 2000000 or T.Name == Flags.FarmBackupWeapon and 1000000 or 0
                    local Current = Ready * 100 + Preference + Loaded * 100 + math.clamp(Value(T, "Ammo", 0), 0, 9999)
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
    function A:ReturnMain(H)
        if not H or self.Equipping or os.clock() < (self.NextEquip or 0) or not Flags.FarmAutoShoot or Flags.FarmReturnMain ~= true or self.Reloading or self.Refill.Pending
            or self.Shop.Pending or self.Shop.RestockPending or self.Shop.ReadyPending or self.TravelPurpose == "ammo" then return end
        -- Finish owned inventory resupply before taking a freshly equipped backup away from the box.
        if Flags.FarmAutoRefill and self:AmmoTool() then return end
        local Equipped = self:Equipped()
        if not Equipped or Equipped.Name == Flags.FarmMainWeapon then return end
        local Bag = P:FindFirstChildOfClass("Backpack")
        local Main = Bag and Bag:FindFirstChild(Flags.FarmMainWeapon or "")
        if Main and Main:IsA("Tool") and Main:FindFirstChild("GunScript") and Main:FindFirstChild("CurrentValues")
            and Value(Main, "FireType", "Single") ~= "Charge"
            and (Value(Main, "Clip", 0) ~= 0 or Value(Main, "Ammo", 0) ~= 0) then self:ReleaseAim(); self:Equip(H, Main) end
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
    function A:FireInterval(Tool, Binding)
        local Rate = Number(Binding and Binding.Environment.LAS, Number(Value(Tool, "AttackSpeed", 300), 300, 1, 7200), 1, 7200)
        if Flags.GunRapidFire and not Guns.Suspended then Rate = math.min(Rate, (Guns.RequestedRate and Guns:RequestedRate(Tool) or Number(Flags.GunFireRate, 60, 1, 120)) * 60) end
        return 60 / Rate
    end
    function A:BurstGate(Tool, Binding)
        if Flags.FarmSmartBursts ~= true or not self.ShotFeedbackAvailable or not self.Target then return true end
        local Target = self.Target
        local HP = Target.Humanoid.Health
        if HP <= 0 then return false end
        local Armor = Target.Model:FindFirstChild("HeadArmour") ~= nil
        local Damage = Value(Tool, "Damage", 0)
        local Plan = self.BurstPlan
        if not Plan or Plan.Tool ~= Tool or Plan.Model ~= Target.Model or Plan.Armor ~= Armor or Plan.Damage ~= Damage then
            local Previous = self.BurstEstimate
            local Estimate = Previous and Previous.Tool == Tool and Previous.Armor == Armor and Previous.Damage == Damage and os.clock() - (Previous.At or -math.huge) < 15 and Previous.Value or nil
            Plan = {Tool = Tool, Model = Target.Model, Armor = Armor, Damage = Damage, HP = HP, Pending = {}, Estimate = Estimate, Delay = self.FeedbackDelay or 0.12}
            self.BurstPlan = Plan
        end
        local Now = os.clock()
        local Delta = Plan.HP - HP
        if Delta > 0 and #Plan.Pending > 0 then
            local Count = #Plan.Pending
            -- Learn only uncensored single-shot health changes. A killing hit
            -- reveals remaining health, not the weapon's actual damage.
            if Count == 1 and HP > 0 then
                Plan.Estimate = Plan.Estimate and math.min(Plan.Estimate, Delta) or Delta
                self.BurstEstimate = {Tool = Tool, Armor = Armor, Damage = Damage, Value = Plan.Estimate, At = Now}
            end
            local Sample = math.clamp(Now - Plan.Pending[1], 0.02, 0.4)
            self.FeedbackDelay = self.FeedbackDelay and self.FeedbackDelay * 0.8 + Sample * 0.2 or Sample
            Plan.Delay = self.FeedbackDelay
            local Confirmed = Plan.Estimate and math.max(1, math.floor(Delta / Plan.Estimate + 0.25)) or 1
            for _ = 1, math.min(Count, Confirmed) do table.remove(Plan.Pending, 1) end
        elseif HP > Plan.HP then
            -- Heals/health resets invalidate in-flight damage assumptions.
            Plan.Pending = {}; Plan.Estimate = nil
        end
        Plan.HP = HP
        local Interval = self:FireInterval(Tool, Binding)
        local Window = math.clamp(Plan.Delay * 1.5 + Interval, 0.08, 0.5)
        local Expired = false
        while Plan.Pending[1] and Now - Plan.Pending[1] >= Window do table.remove(Plan.Pending, 1); Expired = true end
        if Expired then
            Plan.Estimate = nil; self.BurstEstimate = nil -- resume with a single probe, not an assumed lethal burst
        end
        local Need = Plan.Estimate and math.max(1, math.ceil(HP / Plan.Estimate)) or 1
        local Limit = math.min(Need, math.clamp(math.ceil(Window / Interval), 1, 8))
        Plan.Needed = Need; Plan.Limit = Limit; Plan.Window = Window
        return #Plan.Pending < Limit
    end
    function A:ObserveShot(Player, Tool)
        if not self.Alive or Player ~= P or not self.MouseOwned or Flags.FarmSmartBursts ~= true then return end
        local Plan = self.BurstPlan
        if not Plan or Plan.Tool ~= Tool or not self.Target or Plan.Model ~= self.Target.Model then return end
        if #Plan.Pending < 16 then table.insert(Plan.Pending, os.clock()) end
        -- Native shot events count real shots, not attempted mouse presses.
        if not self:BurstGate(Tool, Guns.Weapons[Tool]) then self:ReleaseMouse() end
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
        if not self:BurstGate(Tool, B) then self:ReleaseMouse(); return end
        local Native = not self:InputAvailable()
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
            local Interval = math.max(Frame * 2, self:FireInterval(Tool, B))
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
            local Direction = Unit(Flat(Point.Position - Root.Position))
            local Params = self.Navigation:Params(Root)
            if IgnoreDestinationModel then
                local Ignore = Params.FilterDescendantsInstances
                table.insert(Ignore, IgnoreDestinationModel); Params.FilterDescendantsInstances = Ignore
            end
            local Ground = self.Navigation:Ground(Root.Position, Params)
            if not Ground or not self.Navigation:Segment(Root, Direction, math.min(5, (Point.Position - Root.Position).Magnitude), Params, Ground.Position.Y) then
                self.Route = nil; self.PathFailedUntil = os.clock() + 1; self:StopMovement(); return
            end
            -- Share the per-frame movement owner with retreat; native MoveTo
            -- alone can be cancelled by the normal player control update.
            self.MovingHumanoid = H; self.Travelling = true; self.MoveDirection = Direction
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
        local Best, Lowest = nil, math.huge
        if Bag then
            for _, Tool in ipairs(Bag:GetChildren()) do
                if Tool:IsA("Tool") and Tool:FindFirstChild("GunScript") and self.Refill:Needs(Tool, Threshold) then
                    local Ratio = self.Refill.Ratio and self.Refill:Ratio(Tool) or Value(Tool, "Ammo", 0) / math.max(1, Value(Tool, "MaxAmmo", 1))
                    if Ratio < Lowest or Ratio == Lowest and (not Best or Tool.Name < Best.Name) then Best = Tool; Lowest = Ratio end
                end
            end
        end
        return Best
    end
    function A:HasAmmunition()
        for _, Parent in ipairs({P.Character, P:FindFirstChildOfClass("Backpack")}) do
            if Parent then for _, Tool in ipairs(Parent:GetChildren()) do
                if Tool:IsA("Tool") and Tool:FindFirstChild("GunScript") and (Value(Tool, "Clip", 0) ~= 0 or Value(Tool, "Ammo", 0) ~= 0) then return true end
            end end
        end
        return false
    end
    function A:SupplyRouteCost(Points, Zombies, Speed)
        if #Points < 2 or #Points > 64 then return nil end
        local Cost = 0
        for I = 2, #Points do
            local Start, Finish = Points[I - 1].Position, Points[I].Position
            local Length = (Finish - Start).Magnitude
            local Gap = self.Navigation:SweptGap(Start, Finish, Zombies, Speed)
            if Gap < 6 then return nil end
            Cost = Cost + Length / Speed * (1 + 20 / math.max(6, Gap))
        end
        return Cost
    end
    function A:SupplyBox(H, Root)
        local Candidates = {}
        local Nearest, Distance = self.Refill:Nearest(Root, function(Box, D)
            table.insert(Candidates, {Box = Box, Distance = D})
            return D
        end)
        -- A nearby native interaction needs no route; adapters without scoring retain nearest selection.
        if not Nearest or Distance < 7 or #Candidates == 0 then return Nearest, Distance end
        local Now = os.clock()
        local Cache = self.SupplyCache
        local Valid = Cache and Cache.Root == Root and Now - Cache.At < 4 and (Root.Position - Cache.Position).Magnitude < 10
        if not self.SupplyPlanning and Now >= (self.NextSupplyPlan or 0) and (not Valid or Now - Cache.At >= 2) then
            self.SupplyPlanning = true; self.NextSupplyPlan = Now + 2
            local Token = {}; self.SupplyToken = Token
            local Position, Zombies = Root.Position, self.Zombies
            local Speed = Number(H and H.WalkSpeed, 16, 1, 100)
            table.sort(Candidates, function(X, Y) return X.Distance < Y.Distance end)
            task.spawn(function()
                local Costs = {}
                local First = self.SupplyCursor or 1
                for I = 1, math.min(3, #Candidates) do
                    if not self.Alive or self.SupplyToken ~= Token or Root.Parent ~= P.Character then break end
                    local Box = Candidates[(First + I - 2) % #Candidates + 1].Box
                    local OK, Cost = pcall(function()
                        if not Box.PrimaryPart then return nil end
                        local Away = Unit(Flat(Position - Box.PrimaryPart.Position))
                        if Away.Magnitude < 0.01 then Away = Vector3.new(1, 0, 0) end
                        local Goal = Box.PrimaryPart.Position + Away * 5
                        local Path = Paths:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4})
                        Path:ComputeAsync(Position, Goal)
                        if Path.Status ~= Enum.PathStatus.Success then return nil end
                        return self:SupplyRouteCost(Path:GetWaypoints(), Zombies, Speed)
                    end)
                    if OK and Cost then Costs[Box] = Cost end
                end
                if self.SupplyToken ~= Token then return end
                self.SupplyPlanning = false
                self.SupplyCursor = next(Costs) and 1 or (First + 2) % #Candidates + 1
                if self.Alive and Root.Parent == P.Character and (Root.Position - Position).Magnitude < 10 then
                    self.SupplyCache = {Root = Root, Position = Position, At = os.clock(), Costs = Costs}
                end
            end)
        end
        if not Valid then return nil end
        return self.Refill:Nearest(Root, function(Box) return Cache.Costs[Box] or math.huge end)
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
        local Box, Distance = self:SupplyBox(H, Root)
        if not Box then Status("AmmoStatus", "No stocked ammo box available"); return false end
        local Near = self.Navigation:Separation(Root.Position, self.Zombies)
        local Radius = Number(Flags.FarmDistance, 24, 5, 100)
        local Emergency = not self:HasAmmunition()
        if Near < (Emergency and 10 or math.min(Radius, 18)) then
            if self.TravelPurpose == "ammo" then self:CancelTravel() end
            Status("AmmoStatus", "Retreating before resupply"); return false
        end
        if Distance >= 7 then
            if self.AmmoDestination ~= Box and self.TravelPurpose == "ammo" then self:CancelTravel(); self.PathFailedUntil = nil end
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
        local SafeGap = self.Navigation:RefillGap(Root.Position, self.Zombies, Duration)
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
        local Plan = Flags.UpgradePlan or "Manual"
        local function Rank(L)
            local Name = L.Name:lower()
            local Head = Name:find("head", 1, true) ~= nil
            local Damage = Name:find("damage", 1, true) ~= nil or Name:find("stopping power", 1, true) ~= nil or Name:find("ap rounds", 1, true) ~= nil
            if Plan == "Headshots first" then return Head and 0 or Damage and 1 or 2 end
            return Damage and 0 or Head and 1 or 2
        end
        if Plan ~= "Manual" then
            local List = {}
            for _, L in ipairs(Levels:GetChildren()) do if IsLevel(L) then table.insert(List, L) end end
            table.sort(List, function(X, Y) local A1, B1 = Rank(X), Rank(Y); return A1 < B1 or A1 == B1 and X.Name < Y.Name end)
            if Flags.UpgradeMode ~= "All upgrades" then
                for _, L in ipairs(List) do if Rank(L) < 2 then return {L} end end
                return {} -- never silently select an unrelated category
            end
            return List
        end
        local Priority = Levels:FindFirstChild(Flags.UpgradePriority)
        if not IsLevel(Priority) then return {} end
        local List = {Priority}
        if Flags.UpgradeMode == "All upgrades" then
            local Rest = {}
            for _, L in ipairs(Levels:GetChildren()) do if L ~= Priority and IsLevel(L) then table.insert(Rest, L) end end
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
            self.BurstPlan = nil; self.BurstEstimate = nil
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
            local OK, Purchase, Reason = pcall(self.Shop.TryPurchase, self.Shop, Flags.UpgradeWeapon, List, Number(Flags.FarmCashReserve, 0, 0, 1000000))
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
        local CanReady = self.Shop.CanReady and self.Shop:CanReady()
        if not self.Shop.CanReady then CanReady = self.Shop:BetweenRounds() end
        if not H or not self:Focused() or not CanReady then self.ReadyQuietSince = nil; return end
        local Busy = self.Shop.Pending or self.Shop.RestockPending or self.Refill.Pending or self.Travelling or self.PathComputing
            or self.UnconfirmedWeapon or self.RestockError or os.clock() < (self.ManualUntil or 0)
            or Flags.UpgradeEnabled and not self.UpgradeIdle
        if not Busy and Flags.FarmAutoRefill and self:AmmoTool() then
            local _, _, Root = self:Character()
            -- Low reserve alone is not a job: no usable box must not prevent Ready forever.
            local Box = Root and self.Refill:Nearest(Root)
            Busy = Box ~= nil and not (self.PathFailedUntil and os.clock() < self.PathFailedUntil)
        end
        if Busy then self.ReadyQuietSince = nil; Status("ReadyStatus", "Finishing enabled shop / ammo tasks"); return end
        self.ReadyQuietSince = self.ReadyQuietSince or os.clock()
        if os.clock() - self.ReadyQuietSince < 1.5 then Status("ReadyStatus", "Tasks settled; starting shortly"); return end
        local _, Message = self.Shop:TryReady()
        Status("ReadyStatus", Message)
    end
    function A:HideVisuals()
        for _, Line in ipairs(self.Lines) do Line.Visible = false end
    end
    function A:Visuals(Root)
        local Camera = W.CurrentCamera
        if not Root or not Camera then self:HideVisuals(); return end
        local Now = os.clock()
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
        local Active = Flags.FarmAutoShoot or Flags.FarmKeepDistance or Flags.FarmShowCircle or Flags.UpgradeEnabled or Flags.FarmAutoRefill or Flags.FarmRestockBox or Flags.FarmAutoReady
        if self.InventoryDirty or (Active or Library.WindowVisible) and Now - self.LastScan >= 1 then self:ScanInventory() end
        self:CameraState()
        local _, H, Root = self:Character()
        if Active and self:Focused() and Now - (self.LastZombieScan or -10) >= 0.1 then self:SnapshotZombies() end
        self:ReturnMain(H)
        local Radius = math.max(Number(Flags.FarmDistance, 24, 5, 100), self.ResupplyEscapeRadius or 0)
        local Distance = Root and self.Navigation:Separation(Root.Position, self.Zombies) or math.huge
        local Resupply = Flags.FarmAutoRefill and Root and self:AmmoTool() and self.Refill:Nearest(Root)
        local Emergency = Resupply and not self:HasAmmunition()
        local RetreatRadius = self.ResupplyEscapeRadius or (Emergency and math.min(Radius, 10) or Radius)
        local Danger = Flags.FarmKeepDistance and (Distance < RetreatRadius or not Emergency and self.Navigation.Active and Distance < Radius + 8)
        if self.Refill.Pending then Danger = Flags.FarmKeepDistance and Distance < 6 end
        local Manual = self:ManualMovement()
        local Restocking, Travelling = false, false
        -- Emergency retreat owns movement; shop travel cannot steer against it.
        -- Already-submitted transactions still need their normal completion polling.
        if not Danger and not Manual and not Resupply or self.Shop.Pending or self.Shop.RestockPending then
            Restocking = self:Restock(H, Root)
            Travelling = not Restocking and self:Upgrade(H, Root)
        end
        if not H or not self:Focused() or self.Shop.Pending or self.Shop.RestockPending then
            self:ReleaseAim(); self:StopMovement(); self:CancelTravel(); self.Navigation:Reset()
            self.Refill:Poll()
            if Flags.FarmAutoShoot or Flags.FarmKeepDistance then Status("FarmStatus", not H and "Waiting for respawn" or "Hide UI and focus Roblox") end
        elseif Manual then
            self:StopMovement(); self:CancelTravel(); self.Navigation:Reset()
        elseif Travelling or Restocking then self:ReleaseAim(); self.Navigation:Reset()
        else
            if self.TravelPurpose == "shop" then self:CancelTravel() end
            if Danger then
                self:CancelTravel(); self:Kite(H, Root, RetreatRadius)
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
        if Value(Tool, "Clip", 0) == 0 then
            self:ReleaseAim(); self:Shoot(Tool); return
        end
        if self.Reloading then self:ReleaseAim(); return end
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
        local Now = os.clock()
        if Now >= (self.NextVisual or 0) then
            local Interval = Flags.FarmShowCircle and 1 / 144 or 0.1
            local Next = (self.NextVisual or Now) + Interval
            self.NextVisual = Next > Now and Next or Now + Interval
            self.LastVisual = Now; self:Visuals(Root)
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
        local Need = not self.Failed and (Flags.FarmAutoShoot or Flags.FarmKeepDistance or Flags.FarmShowCircle or self.Travelling)
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
        self.Alive = false; self.PathToken = nil; self.SupplyToken = nil
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
    for _, Key in ipairs({"FarmMainWeapon", "FarmBackupWeapon", "GunPresetWeapon"}) do
        Own(Key, function() if A.SavedLoadout and not A.ScanningLoadout then A.SavedLoadout[Key] = nil end end)
    end
    Own("FarmCashReserve", function() A.UpgradeIdle = false; A.ReadyQuietSince = nil end)
    Own("UpgradePlan", function() A.UpgradeIdle = false; A.ReadyQuietSince = nil end)
    Own("UpgradeMode", function() A.UpgradeIdle = false; A.ReadyQuietSince = nil end)
    Own("UpgradePriority", function() A.SavedPriority = nil; A.UpgradeIdle = false; A.ReadyQuietSince = nil end)
    Own("UpgradeEnabled", function(V) A.Notices["upgrade-stop"] = nil; if not V then A:CancelTravel() end end)
    Own("UpgradeShopFallback", function(V) if not V then A:CancelTravel() end end)
    Own("FarmSmartBursts", function() A:ReleaseMouse(); A.BurstPlan = nil; A.BurstEstimate = nil end)
    Own("FarmAutoShoot", function(V) if not V then A:ReleaseAim() end end)
    Own("FarmKeepDistance", function(V) if not V then A:StopMovement(); A.Navigation:Reset() end end)
    Own("FarmAutoRefill", function(V) if not V and A.TravelPurpose == "ammo" then A:CancelTravel() end end)
    Own("FarmRestockBox", function(V) if not V and not Flags.UpgradeEnabled then A:CancelTravel() end end)
    Own("FarmUseSprint", function(V) if not V then A:Sprint(false) end end)
    Own("FarmShowCircle", function() A:HideVisuals() end)
    Own("CameraThirdPerson", function() A:CameraState() end)
    Own("CameraDistance", function() A:CameraState() end)
    Connect(P.CharacterAdded, function(C) A.SupplyToken = nil; A.SupplyPlanning = false; A.SupplyCache = nil; A:ReleaseAim(); A:StopMovement(); A:CancelTravel(); A:Watch("Character", C) end)
    Connect(P.ChildAdded, function(C)
        if C:IsA("Backpack") or C.Name == "Backgear" or C.Name == "Upgrades" then A:Watch(C.Name, C) end
    end)
    Connect(Input.WindowFocusReleased, function()
        A.WindowFocused = false
        A:ReleaseMouse(); A:Sprint(false); A:RestoreView(); A:CameraState()
    end)
    Connect(Input.WindowFocused, function()
        A.WindowFocused = true
        A:ReleaseMouse(); A:Sprint(false); A:CameraState()
    end)
    function A:BindShotFeedback()
        local Scripts = P:FindFirstChild("PlayerScripts")
        local Manager = Scripts and Scripts:FindFirstChild("LocalVisualManager")
        local Event = Manager and Manager:FindFirstChild("LocalFireEvent")
        if Event == self.ShotEvent then return end
        if self.ShotConnection then self.ShotConnection:Disconnect(); self.ShotConnection = nil end
        self.ShotEvent = Event; self.ShotFeedbackAvailable = Event ~= nil
        self.BurstPlan = nil
        if Event then self.ShotConnection = Connect(Event.Event, function(Player, Tool) A:ObserveShot(Player, Tool) end) end
    end
    A:Watch("Character", P.Character)
    A:Watch("Backpack", P:FindFirstChildOfClass("Backpack"))
    A:Watch("Backgear", P:FindFirstChild("Backgear")); A:Watch("Upgrades", P:FindFirstChild("Upgrades"))
    Connect(Input.InputBegan, function(Event)
        local K = Event.KeyCode
        if K == Enum.KeyCode.W or K == Enum.KeyCode.A or K == Enum.KeyCode.S or K == Enum.KeyCode.D
            or K == Enum.KeyCode.Up or K == Enum.KeyCode.Down or K == Enum.KeyCode.Left or K == Enum.KeyCode.Right then
            if A:InputAvailable() then
                A.ManualUntil = os.clock() + 0.25
                A:StopMovement(); A:CancelTravel(); A.Navigation:Reset()
            end
        end
    end)
    Connect(Run.Heartbeat, function()
        if not A.Alive or os.clock() - A.LastStep < 0.05 then return end
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
