-- Native cash-only upgrade UI adapter. It never writes money, levels or gun values.
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
        local G = P:FindFirstChild("PlayerGui")
        local Button = G and G:FindFirstChild("VoteSkip", true)
        return Z ~= nil and #Z:GetChildren() == 0 and Button ~= nil
            and type(Button.Text) == "string" and Button.Text:find("Ready", 1, true) ~= nil
    end
    function A:OwnedTool(Name)
        local Bag = P:FindFirstChildOfClass("Backpack")
        return Bag and Bag:FindFirstChild(Name) or P.Character and P.Character:FindFirstChild(Name)
    end
    function A:GetContext()
        if self.Context and self.Context.Frame.Parent then return self.Context end
        local Scripts = P:FindFirstChild("PlayerScripts")
        local Manager = Scripts and Scripts:FindFirstChild("GuiManager")
        local Main = Manager and Manager:FindFirstChild("MainGui")
        local Module = Main and Main:FindFirstChild("ShopGui")
        if not Module then return nil end
        local Shop = Load(Module)
        if type(Shop) ~= "table" or type(Shop.Next) ~= "function" then return nil end
        local Update = getfenv(Shop.Next).UpdateUpgrade
        if type(Update) ~= "function" or debug.getinfo(Update).nups < 18 then return nil end
        -- Verified v312 layout, checked by object identity/shape before use.
        local Frame = debug.getupvalue(Update, 4)
        local Info = debug.getupvalue(Update, 8)
        if typeof(Frame) ~= "Instance" or Frame.Name ~= "ShopFrame"
            or typeof(Info) ~= "Instance" then return nil end
        local NativeFrame: any = Frame
        local NativeInfo: any = Info
        if not NativeFrame:FindFirstChild("Upgrade") or not NativeInfo:FindFirstChild("UpgradesFrame") then return nil end
        self.Context = {Update = Update, Frame = NativeFrame, Information = NativeInfo}
        return self.Context
    end
    function A:TryPurchase(Weapon, OrderedLevels)
        if not self.Alive or self.Pending or self.RestockPending then return nil, "Waiting for confirmation" end
        if not self:BetweenRounds() then return nil, "Waiting for round end" end
        if not self:InShop() then return nil, "Enter the shop to upgrade" end
        if not self.Confirmation then return nil, "Native confirmation event unavailable" end
        local Tool = self:OwnedTool(Weapon)
        local Money = P:FindFirstChild("ReplicatedMoney")
        if not Tool or not Money then return nil, "Weapon is not ready" end
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
                        if Price > Money.Value then
                            Reason = "Waiting for cash ($" .. tostring(Price) .. ")"
                            -- All-upgrades mode may still buy a cheaper unlocked category.
                        else
                            local Handler
                            for _, Connection in ipairs(getconnections(Row.MouseButton1Click)) do
                                if Connection.Enabled and type(Connection.Function) == "function" then Handler = Connection.Function; break end
                            end
                            if not Handler then Reason = "Native buy handler unavailable"; return end
                            Pending = {Weapon = Weapon, Level = Level, Before = Level.Value,
                                Price = Price, Started = os.clock(), Confirmed = false}
                            -- Register before invoking: a confirmation can arrive immediately.
                            self.Pending = Pending
                            Handler()
                            return
                        end
                    end
                end
            end
        end)
        -- Always restore the native selection, even when a buy callback throws.
        pcall(debug.setupvalue, Update, 5, PreviousWeapon)
        pcall(function() Context.Frame.Upgrade.Value = PreviousMode; Update() end)
        if not OK then
            if self.Pending then
                -- A callback may have sent its request before throwing: never retry blindly.
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
        if not self.Alive or self.Pending or self.RestockPending then return nil, "Another purchase is pending" end
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
        -- Native restock changes stock/cash optimistically and has no dedicated acknowledgement.
        -- One attempt per round prevents a rejected local update causing repeated spending.
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
            -- Native shop owns its optimistic values. Do not invent a refund or a second buy.
            return "timeout", Pending
        end
        return "waiting", Pending
    end
    function A:Destroy()
        self.Alive = false
        if self.Confirmation then self.Confirmation:Disconnect() end
        self.Pending = nil
        self.RestockPending = nil
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
