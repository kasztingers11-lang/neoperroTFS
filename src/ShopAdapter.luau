 
return function()
    local P: any = game:GetService("Players").LocalPlayer
    local RS: any = game:GetService("ReplicatedStorage")
    local W: any = workspace
    local Load: any = require
    local A: any = {Alive = true, Pending = nil, Context = nil}
    function A:Levels(Name)
        local U = P:FindFirstChild("Upgrades")
        U = U and U:FindFirstChild("GunUpgrades")
        return U and U:FindFirstChild(Name)
    end
    function A:InShop()
        local V = P:FindFirstChild("InsideShop")
        return V ~= nil and V.Value == true
    end
    function A:BetweenRounds()
        local Z = W:FindFirstChild("Zombies")
        local Values = RS:FindFirstChild("Values")
        local Vote = Values and Values:FindFirstChild("Vote")
        if Vote then
            local Time = game:GetService("Lighting"):GetMinutesAfterMidnight()
            return Vote.Value == true and Time >= 360 and Time < 1080
        end
        local G = P:FindFirstChild("PlayerGui")
        local Button = G and G:FindFirstChild("VoteSkip", true)
        return Z ~= nil and #Z:GetChildren() == 0 and Button ~= nil
            and type(Button.Text) == "string" and Button.Text:find("Ready", 1, true) ~= nil
    end
    function A:CanReady()
        local Values = RS:FindFirstChild("Values")
        local Vote = Values and Values:FindFirstChild("Vote")
        if Vote then return Vote.Value == true end
        return self:BetweenRounds()
    end
    function A:OwnedTool(Name)
        local Bag = P:FindFirstChildOfClass("Backpack")
        return Bag and Bag:FindFirstChild(Name) or P.Character and P.Character:FindFirstChild(Name)
    end
    function A:GetContext()
        local Scripts = P:FindFirstChild("PlayerScripts")
        local Manager = Scripts and Scripts:FindFirstChild("GuiManager")
        local Main = Manager and Manager:FindFirstChild("MainGui")
        local Module = Main and Main:FindFirstChild("ShopGui")
        if not Module then return nil end
        if self.Context and self.Context.Module == Module and self.Context.Frame.Parent and self.Context.Information.Parent then return self.Context end
        self.Context = nil
        if self.ContextModule == Module and os.clock() < (self.ContextRetry or 0) then return nil end
        self.ContextModule = Module; self.ContextRetry = os.clock() + 1
        local OK, Context = pcall(function()
            local Shop = Load(Module)
            if type(Shop) ~= "table" or type(Shop.Next) ~= "function" then return nil end
            local Update = getfenv(Shop.Next).UpdateUpgrade
            if type(Update) ~= "function" or debug.getinfo(Update).nups < 18 then return nil end
            local Frame = debug.getupvalue(Update, 4)
            local Info = debug.getupvalue(Update, 8)
            if typeof(Frame) ~= "Instance" or Frame.Name ~= "ShopFrame" or typeof(Info) ~= "Instance" then return nil end
            local NativeFrame: any = Frame
            local NativeInfo: any = Info
            if not NativeFrame:FindFirstChild("Upgrade") or not NativeInfo:FindFirstChild("UpgradesFrame") then return nil end
            return {Update = Update, Frame = NativeFrame, Information = NativeInfo, Module = Module}
        end)
        if OK then self.Context = Context end
        return self.Context
    end
    function A:TryPurchase(Weapon, OrderedLevels, CashReserve)
        if not self.Alive or self.Pending or self.RestockPending or self.ReadyPending then return nil, "Waiting for confirmation" end
        if not self:BetweenRounds() then return nil, "Waiting for round end" end
        if not self:InShop() then return nil, "Enter the shop to upgrade" end
        if not self.Confirmation then return nil, "Native confirmation event unavailable" end
        local Tool = self:OwnedTool(Weapon)
        local Money = P:FindFirstChild("ReplicatedMoney")
        if not Tool or not Money then return nil, "Weapon is not ready" end
        if CashReserve == nil then CashReserve = 0 end
        if type(CashReserve) ~= "number" or CashReserve ~= CashReserve or math.abs(CashReserve) == math.huge then return nil, "Invalid cash reserve" end
        CashReserve = math.max(0, CashReserve)
        local Context = self:GetContext()
        if not Context then return nil, "Shop version unsupported" end
        if Context.Frame.Visible then return nil, "Close the native shop menu" end
        local Update = Context.Update
        local PreviousWeapon = debug.getupvalue(Update, 5)
        local PreviousMode = Context.Frame.Upgrade.Value
        local Pending, Reason = nil, "Remaining upgrades locked"
        local OK, Error = pcall(function()
            debug.setupvalue(Update, 5, Weapon)
            Context.Frame.Upgrade.Value = false
            Update()
            local Rows = Context.Information.UpgradesFrame.Upgrades
            for _, Level in ipairs(OrderedLevels) do
                if Level.Value < Level.MaxValue then
                    local Row = Rows:FindFirstChild(Level.Name .. " Upgrade")
                    local Buy = Row and Row:FindFirstChild("Buy")
                    local Text = Buy and Buy.Text
                    local Price = type(Text) == "string" and Text:match("^Buy:%s*%$([%d,]+)%s*$")
                    Price = Price and tonumber((Price:gsub(",", "")))
                    if Row and Row.Visible and Buy and Buy.Visible and Price and Price >= 0 then
                        if Price + CashReserve > Money.Value then
                            Reason = "Waiting for cash ($" .. tostring(Price) .. ")"
                             
                        else
                            local Handler
                            for _, Connection in ipairs(getconnections(Row.MouseButton1Click)) do
                                if Connection.Enabled and type(Connection.Function) == "function" then Handler = Connection.Function; break end
                            end
                            if not Handler then Reason = "Native buy handler unavailable"; return end
                            Pending = {Weapon = Weapon, Level = Level, Before = Level.Value,
                                Price = Price, Started = os.clock(), Confirmed = false}
                             
                            self.Pending = Pending
                            Handler()
                            return
                        end
                    end
                end
            end
        end)
         
        pcall(debug.setupvalue, Update, 5, PreviousWeapon)
        pcall(function() Context.Frame.Upgrade.Value = PreviousMode; Update() end)
        if not OK then
            if self.Pending then
                 
                self.Pending.Error = tostring(Error)
                return self.Pending, "Waiting for confirmation"
            end
            return nil, "Native shop could not update"
        end
        return Pending, Pending and "Waiting for confirmation" or Reason
    end
    function A:AmmoBox()
        local Map = W:FindFirstChild("Map")
        local Upgrades = Map and Map:FindFirstChild("Upgrades")
        return Upgrades and Upgrades:FindFirstChild("AmmoBox")
    end
    function A:RestockContext()
        local Scripts = P:FindFirstChild("PlayerScripts")
        local Manager = Scripts and Scripts:FindFirstChild("GuiManager")
        local Main = Manager and Manager:FindFirstChild("MainGui")
        local Shop = Main and Main:FindFirstChild("ShopGui")
        local Module = Shop and Shop:FindFirstChild("ShopPurchase")
        if not Module then return nil end
        local Purchase = Load(Module)
        local Fn = type(Purchase) == "table" and Purchase.RepairStructure
        if type(Fn) ~= "function" or debug.getinfo(Fn).nups ~= 5 then return nil end
        local Utility = debug.getupvalue(Fn, 3)
        local Remote = debug.getupvalue(Fn, 4)
        if debug.getupvalue(Fn, 1) ~= P or type(Utility) ~= "table" or type(Utility.GetStructureRepairInfo) ~= "function"
            or typeof(Remote) ~= "Instance" or Remote.Name ~= "SellRepair" then return nil end
        return {Purchase = Purchase, Utility = Utility}
    end
    function A:TryRestock(Threshold)
        if not self.Alive or self.Pending or self.RestockPending or self.ReadyPending then return nil, "Another purchase is pending" end
        if not self:BetweenRounds() then return nil, "Restock waits for round end" end
        local Minutes = game:GetService("Lighting"):GetMinutesAfterMidnight()
        if Minutes < 360 or Minutes >= 1080 then return nil, "Restock is daytime only" end
        if not self:InShop() then return nil, "Enter the shop to restock" end
        local Frame = self:GetContext()
        if not Frame or Frame.Frame.Visible then return nil, "Close the native shop menu" end
        local Box = self:AmmoBox()
        if not Box or not Box:FindFirstChild("Ammo") or not Box:FindFirstChild("MaxAmmo")
            or Box.MaxAmmo.Value <= 0 then return nil, "Ammo box unavailable" end
        if Box.Ammo.Value > Box.MaxAmmo.Value * math.clamp(Threshold, 5, 50) / 100 then return nil, "Ammo box stock sufficient" end
        local Values = RS:FindFirstChild("Values")
        local Wave = Values and Values:FindFirstChild("LocalWave")
        if not Wave then return nil, "Round identity unavailable" end
        if self.RestockAttemptedWave == Wave.Value then return nil, "Restock already attempted this round" end
        local First = P:FindFirstChild("FirstWave")
        if First and First.Value then return nil, "Survive one night before restocking" end
        local Money = P:FindFirstChild("ReplicatedMoney")
        local Context = self:RestockContext()
        if not Money or not Context then return nil, "Native restock version unsupported" end
        local Amount, Price = Context.Utility:GetStructureRepairInfo("AmmoBox", Money.Value)
        local function Finite(N) return type(N) == "number" and N == N and math.abs(N) < math.huge end
        if not Finite(Amount) or not Finite(Price) or Amount <= 0 or Price <= 0 or Price > Money.Value then
            return nil, "Waiting for restock cash"
        end
        local Record = {Started = os.clock(), Box = Box, BeforeStock = Box.Ammo.Value,
            BeforeCash = Money.Value, Price = Price, Amount = Amount}
        self.RestockPending = Record
         
         
        self.RestockAttemptedWave = Wave.Value
        local OK, Error = pcall(Context.Purchase.RepairStructure, Context.Purchase, "AmmoBox")
        Record.Error = not OK and tostring(Error) or nil
        return Record, "Native restock submitted"
    end
    function A:PollRestock()
        local Record = self.RestockPending
        if not Record then return "idle" end
        if os.clock() - Record.Started < 1 then return "waiting", Record end
        self.RestockPending = nil
        Record.AfterStock = Record.Box.Parent and Record.Box.Ammo.Value or Record.BeforeStock
        return Record.Error and "unconfirmed" or "submitted", Record
    end
    function A:TryReady()
        if not self.Alive or self.Pending or self.RestockPending or self.ReadyPending then return nil, "Waiting for shop transactions" end
        if not self:CanReady() then return nil, "Waiting for round end" end
        local Voted = P:FindFirstChild("Voted")
        if not Voted then return nil, "Native ready state unavailable" end
        if Voted.Value == true then return nil, "Ready; waiting for other players" end
        local Values = RS:FindFirstChild("Values")
        local Wave = Values and Values:FindFirstChild("LocalWave")
        if not Wave or self.ReadyAttemptedWave == Wave.Value then return nil, "Ready already attempted this round" end
        local Scripts = P:FindFirstChild("PlayerScripts")
        local Manager = Scripts and Scripts:FindFirstChild("GuiManager")
        local Main = Manager and Manager:FindFirstChild("MainGui")
        local Module = Main and Main:FindFirstChild("SkipGui")
        if not Module then return nil, "Native ready version unsupported" end
        local Native = Load(Module)
        local Fn = type(Native) == "table" and Native.Vote
        if type(Fn) ~= "function" or debug.getinfo(Fn).nups ~= 6 then return nil, "Native ready version unsupported" end
        local Remote = debug.getupvalue(Fn, 5)
        if debug.getupvalue(Fn, 1) ~= P or typeof(Remote) ~= "Instance" or Remote.Name ~= "VoteSkip" then return nil, "Native ready version unsupported" end
        if debug.getupvalue(Fn, 2) ~= false then return nil, "Native ready request busy" end
        local Record = {Done = false, Started = os.clock()}
        self.ReadyPending = Record
        task.spawn(function()
            if not self.Alive or self.CanStart and not self.CanStart() or not self:CanReady() then
                Record.Cancelled = true; Record.Done = true; return
            end
            if Voted.Value == true then Record.Ready = true; Record.Done = true; return end
            self.ReadyAttemptedWave = Wave.Value
            Record.Submitted = true
            local OK, Error = pcall(Fn, Native)
            Record.Error = not OK and tostring(Error) or nil
            Record.Ready = OK and Voted.Parent ~= nil and Voted.Value == true
            Record.Done = true
        end)
        return Record, "Sending native Ready vote"
    end
    function A:PollReady()
        local Record = self.ReadyPending
        if not Record then return "idle" end
        if not Record.Done then return "waiting" end
        self.ReadyPending = nil
        return Record.Cancelled and "cancelled" or Record.Ready and "ready" or "unconfirmed"
    end
    function A:Poll()
        local Pending = self.Pending
        if not Pending then return "idle" end
        if Pending.Confirmed then
            self.Pending = nil
            if Pending.Level.Parent and Pending.Level.Value > Pending.Before then return "confirmed", Pending end
            return "rejected", Pending
        end
        if os.clock() - Pending.Started >= 6 then
            self.Pending = nil
             
            return "timeout", Pending
        end
        return "waiting", Pending
    end
    function A:Destroy()
        self.Alive = false
        if self.Confirmation then self.Confirmation:Disconnect() end
        self.Pending = nil
        self.RestockPending = nil
        self.ReadyPending = nil
    end
    local Remotes = RS:FindFirstChild("RemoteEvents")
    local Result = Remotes and Remotes:FindFirstChild("RefreshItemStats")
    if Result then
        A.Confirmation = Result.OnClientEvent:Connect(function(Weapon, Structure)
            if A.Alive and A.Pending and not Structure and A.Pending.Weapon == Weapon then A.Pending.Confirmed = true end
        end)
    end
    return A
end
