-- Gun mods only. Native ammo, reload, range, penetration and network data are untouched.
return function(Library: any, Window: any)
    local P: any = game:GetService("Players").LocalPlayer
    local Run = game:GetService("RunService")
    local Input = game:GetService("UserInputService")
    local F: any = {Alive = true, Connections = {}, Weapons = {}, Values = {},
        Retries = {}, Callbacks = {}, Notices = {}, LastApply = 0, FocusPaused = not isrbxactive()}
    local Flags = Library.Flags
    local Keys = {"GunRapidFire", "GunNoSpread", "GunNoRecoil", "FarmAutoShoot"}
    local function Notify(Key, Message)
        if F.Notices[Key] == Message then return end
        F.Notices[Key] = Message
        Window.SendNotification("Warning", Message, 4)
    end
    local function Connect(Signal, Callback)
        local C = Signal:Connect(Callback)
        table.insert(F.Connections, C)
        return C
    end
    local function Disconnect(Connection)
        pcall(function() Connection:Disconnect() end)
    end
    local function NeedUpdates()
        if F.FocusPaused or not isrbxactive() then return false end
        for _, Key in ipairs(Keys) do if Flags[Key] == true then return true end end
        return false
    end
    local function FireRate()
        local Rate = tonumber(Flags.GunFireRate)
        if not Rate or Rate ~= Rate or math.abs(Rate) == math.huge then Rate = 60 end
        return math.clamp(Rate, 1, 120) * 60
    end
    local function Assign(Value, Desired, Enabled)
        if not Value or not Value:IsA("ValueBase") then return false end
        local Record = F.Values[Value]
        if Enabled then
            if not Record then
                Record = {Original = Value.Value, Applied = Desired}
                F.Values[Value] = Record
            elseif Value.Value ~= Record.Applied then
                -- Preserve new native upgrades instead of restoring an obsolete baseline.
                Record.Original = Value.Value
            end
            local Before = Value.Value
            if Before ~= Desired then Value.Value = Desired end
            Record.Applied = Value.Value
            return Value.Value ~= Before
        elseif Record then
            local Changed = Value.Value == Record.Applied and Value.Value ~= Record.Original
            if Value.Value == Record.Applied then Value.Value = Record.Original end
            F.Values[Value] = nil
            return Changed
        end
        return false
    end
    function F:RestoreValues(Tool)
        for Value, Record in pairs(self.Values) do
            local OK, Matches = pcall(function() return not Tool or Value:IsDescendantOf(Tool) end)
            if not OK or Matches then
                pcall(function() if Value.Value == Record.Applied then Value.Value = Record.Original end end)
                self.Values[Value] = nil
            end
        end
    end
    function F:RestoreWeapon(B)
        if B.RecoilIndex then
            pcall(function()
                if debug.getupvalue(B.Fire, B.RecoilIndex) == B.RecoilProxy then
                    debug.setupvalue(B.Fire, B.RecoilIndex, B.Recoil)
                end
            end)
        end
        -- Values must be restored before rebuilding native cached spread.
        if B.UpdateSpread then pcall(B.UpdateSpread) end
    end
    function F:ReleaseWeapon(Tool)
        self:RestoreValues(Tool)
        local B = self.Weapons[Tool]
        if B then self:RestoreWeapon(B); self.Weapons[Tool] = nil end
        self.Retries[Tool] = nil
    end
    function F:BindWeapon(Tool)
        local Script = Tool:FindFirstChild("GunScript")
        local B = self.Weapons[Tool]
        if B and B.Script == Script then return B end
        if B then self:ReleaseWeapon(Tool) end
        if not Script then return nil end
        local Now = os.clock()
        local Retry = self.Retries[Tool]
        if Retry and Now - Retry.Last < 1 then return nil end
        self.Retries[Tool] = {Last = Now}
        local OK, Environment = pcall(getsenv, Script)
        if not OK then return nil end
        local Fire = filtergc("function", {Name = "FireWeapon", Environment = Environment}, true)
        if not Fire then return nil end -- Unequipped new guns may not have initialized yet.
        B = {Tool = Tool, Script = Script, Environment = Environment, Fire = Fire}
        for Index = 1, math.min(debug.getinfo(Fire).nups, 128) do
            local V = debug.getupvalue(Fire, Index)
            if type(V) == "table" and type(V.GetIgnoreList) == "function" then B.Manager = V end
            if not B.RecoilIndex and type(V) == "table" and type(V.AddRecoil) == "function" then
                B.RecoilIndex, B.Recoil = Index, V
            end
        end
        if B.RecoilIndex then
            local Recoil = B.Recoil
            B.RecoilProxy = setmetatable({}, {__index = Recoil})
            function B.RecoilProxy:AddRecoil(...)
                if Flags.GunNoRecoil ~= true or F.Suspended or F.FocusPaused or not isrbxactive() then return Recoil.AddRecoil(Recoil, ...) end
                return nil
            end
            debug.setupvalue(Fire, B.RecoilIndex, B.RecoilProxy)
        elseif Flags.GunNoRecoil == true then
            Notify("recoil-" .. Tool.Name, "No recoil is unavailable for " .. Tool.Name)
        end
        B.UpdateSpread = filtergc("function", {Name = "UpdateSpread", Environment = Environment}, true)
        if not B.UpdateSpread and Flags.GunNoSpread == true then
            Notify("spread-" .. Tool.Name, "No spread is unavailable for " .. Tool.Name)
        end
        self.Weapons[Tool] = B
        self.Retries[Tool] = nil
        return B
    end
    function F:ApplyTool(Tool)
        local BindingNeed = not self.FocusPaused and isrbxactive() and (Flags.GunNoSpread == true or Flags.GunNoRecoil == true or Flags.FarmAutoShoot == true)
        local B = BindingNeed and self:BindWeapon(Tool) or self.Weapons[Tool]
        local V = Tool:FindFirstChild("CurrentValues")
        if not V then return end
        local Suspended = self.Suspended or self.FocusPaused or not isrbxactive()
        for _, Prefix in ipairs({"", "Alt"}) do
            Assign(V:FindFirstChild(Prefix .. "AttackSpeed"), FireRate(), Flags.GunRapidFire == true and not Suspended)
            Assign(V:FindFirstChild(Prefix .. "BurstDelay"), 0, Flags.GunRapidFire == true and not Suspended)
        end
        Assign(V:FindFirstChild("FireType"), "FullAuto", Flags.GunRapidFire == true and not Suspended)
        local SpreadEnabled = Flags.GunNoSpread == true and not Suspended and B ~= nil and B.UpdateSpread ~= nil
        local SpreadChanged = false
        for _, Prefix in ipairs({"", "Zoom", "Alt", "AltZoom"}) do
            local MinSpread = V:FindFirstChild(Prefix .. "Spread")
            local MaxSpread = V:FindFirstChild(Prefix .. "SpreadMax")
            -- Integer spread fields need a representable nonzero interval too.
            local Integer = MaxSpread and (MaxSpread:IsA("IntValue") or MaxSpread.ClassName == "IntConstrainedValue")
            if Assign(MinSpread, Integer and 0 or 0.000001, SpreadEnabled) then SpreadChanged = true end
            if Assign(MaxSpread, Integer and 1 or 0.000002, SpreadEnabled) then SpreadChanged = true end
            if Assign(V:FindFirstChild(Prefix .. "SpreadIncrease"), 0, SpreadEnabled) then SpreadChanged = true end
        end
        if B then
            if SpreadChanged or B.NoSpreadApplied ~= SpreadEnabled then
                B.NoSpreadApplied = SpreadEnabled
                if B.UpdateSpread then pcall(B.UpdateSpread) end
            end
            if not BindingNeed then self:RestoreWeapon(B); self.Weapons[Tool] = nil end
        end
    end
    function F:ApplyWeapons()
        local Owned = {}
        local function Visit(Parent)
            if not Parent then return end
            for _, Tool in ipairs(Parent:GetChildren()) do
                if Tool:IsA("Tool") and Tool:FindFirstChild("GunScript") then
                    Owned[Tool] = true
                    local OK, Error = pcall(self.ApplyTool, self, Tool)
                    if not OK then Notify("weapon-" .. Tool.Name, "Gun controls: " .. tostring(Error)) end
                end
            end
        end
        -- A missing Backpack must not skip guns in the character.
        Visit(P:FindFirstChildOfClass("Backpack"))
        Visit(P.Character)
        for Tool in pairs(self.Weapons) do if not Owned[Tool] then self:ReleaseWeapon(Tool) end end
        for Tool in pairs(self.Retries) do if not Owned[Tool] then self.Retries[Tool] = nil end end
        for Value, Record in pairs(self.Values) do
            local OK, IsOwned = pcall(function()
                return Value:IsDescendantOf(P) or P.Character and Value:IsDescendantOf(P.Character)
            end)
            if not OK or not IsOwned then
                pcall(function() if Value.Value == Record.Applied then Value.Value = Record.Original end end)
                self.Values[Value] = nil
            end
        end
    end
    function F:Refresh()
        if not self.Alive then return end
        local Need = NeedUpdates()
        if Need or next(self.Values) or next(self.Weapons) then self:ApplyWeapons() end
        if Need and not self.Heartbeat then
            self.Heartbeat = Run.Heartbeat:Connect(function()
                if not self.Alive or os.clock() - self.LastApply < 0.25 then return end
                self.LastApply = os.clock()
                local OK, Error = pcall(self.ApplyWeapons, self)
                if not OK then Notify("runtime", "Gun mods: " .. tostring(Error)) end
            end)
        elseif not Need and self.Heartbeat then
            Disconnect(self.Heartbeat); self.Heartbeat = nil
        end
    end
    function F:QueueRefresh()
        if self.Queued or not self.Alive then return end
        self.Queued = true
        task.defer(function() self.Queued = false; if self.Alive then self:Refresh() end end)
    end
    function F:SetSuspended(State)
        self.Suspended = State == true
        self:Refresh()
    end
    function F:WatchInventory(Parent, Key)
        for _, C in ipairs(self[Key] or {}) do Disconnect(C) end
        self[Key] = {}
        if Parent then
            for _, Signal in ipairs({Parent.ChildAdded, Parent.ChildRemoved}) do
                table.insert(self[Key], Signal:Connect(function(Child)
                    if Child:IsA("Tool") then self:QueueRefresh() end
                end))
            end
        end
        self:QueueRefresh()
    end
    local function OwnCallback(Item, Callback)
        local Record = {Previous = Item.Callback, Owned = Callback}
        F.Callbacks[Item] = Record
        Item.Callback = Callback
    end
    function F:Destroy()
        if not self.Alive then return end
        self.Alive = false
        if self.Heartbeat then Disconnect(self.Heartbeat); self.Heartbeat = nil end
        for _, C in ipairs(self.Connections) do Disconnect(C) end
        for _, Key in ipairs({"CharacterConnections", "BackpackConnections"}) do
            for _, C in ipairs(self[Key] or {}) do Disconnect(C) end
            self[Key] = {}
        end
        self:RestoreValues(nil)
        for _, B in pairs(self.Weapons) do self:RestoreWeapon(B) end
        for Item, Record in pairs(self.Callbacks) do
            if Item.Callback == Record.Owned then Item.Callback = Record.Previous end
        end
        table.clear(self.Connections); table.clear(self.Callbacks)
        table.clear(self.Weapons); table.clear(self.Retries)
    end
    F:WatchInventory(P.Character, "CharacterConnections")
    F:WatchInventory(P:FindFirstChildOfClass("Backpack"), "BackpackConnections")
    Connect(P.CharacterAdded, function(Character) F:WatchInventory(Character, "CharacterConnections") end)
    Connect(P.ChildAdded, function(Child)
        if Child:IsA("Backpack") then F:WatchInventory(Child, "BackpackConnections") end
    end)
    Connect(Input.WindowFocusReleased, function() F.FocusPaused = true; F:Refresh() end)
    Connect(Input.WindowFocused, function() F.FocusPaused = false; F:Refresh() end)
    for _, Key in ipairs({"GunRapidFire", "GunNoSpread", "GunNoRecoil", "GunFireRate", "FarmAutoShoot"}) do
        local Item = Library.Items[Key]
        if Item then
            local Previous = Item.Callback
            OwnCallback(Item, function(Value) Previous(Value); F:QueueRefresh() end)
        end
    end
    F:Refresh()
    return F
end
