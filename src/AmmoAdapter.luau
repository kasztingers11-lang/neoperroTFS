-- Uses the verified native nearby-box transaction and its real interaction timer.
return function()
    local P: any = game:GetService("Players").LocalPlayer
    local W: any = workspace
    local Load: any = require
    local A: any = {Alive = true, Pending = nil, NextTry = 0, LastBoxes = -10, Boxes = {}, BlockedUntil = {}}
    function A:Context()
        local Scripts = P:FindFirstChild("PlayerScripts")
        local Gui = Scripts and Scripts:FindFirstChild("GuiManager")
        local Module = Gui and Gui:FindFirstChild("MainGui")
        if not Module then return nil end
        local Main = Load(Module)
        local Fn = type(Main) == "table" and type(Main.Init) == "function" and getfenv(Main.Init).AmmoCrate
        if type(Fn) ~= "function" or debug.getinfo(Fn).nups ~= 11 then return nil end
        local Manager = debug.getupvalue(Fn, 6)
        local Remote = debug.getupvalue(Fn, 7)
        if type(Manager) ~= "table" or type(Manager.GetMulti) ~= "function" or typeof(Remote) ~= "Instance"
            or Remote.Name ~= "RemoteRefillAmmo" then return nil end
        return {Function = Fn, Manager = Manager}
    end
    function A:Ratio(Tool)
        local V = Tool and Tool:FindFirstChild("CurrentValues")
        if not V or not V:FindFirstChild("Ammo") or not V:FindFirstChild("MaxAmmo") or V.MaxAmmo.Value <= 0 then return math.huge, 0 end
        local Capacity = V.MaxAmmo.Value
        local Context = self:Context()
        if Context then
            local OK, Multi = pcall(Context.Manager.GetMulti, Context.Manager, "MaxAmmo", P, {Tool = Tool})
            if OK and type(Multi) == "number" and Multi > 0 and Multi < math.huge then Capacity = Capacity * Multi end
        end
        if V.Ammo.Value < 0 or Capacity ~= Capacity or Capacity >= math.huge then return math.huge, 0 end
        return V.Ammo.Value / Capacity, Capacity
    end
    function A:Needs(Tool, Threshold)
        local Ratio, Capacity = self:Ratio(Tool)
        return Capacity > 0 and Ratio <= math.max(1 / Capacity, math.clamp(Threshold or 20, 5, 90) / 100)
    end
    function A:Eligible(Box, AllowEmpty)
        if not Box or not Box.Parent or not Box.PrimaryPart or not Box:FindFirstChild("Time")
            or not Box:FindFirstChild("Ammo") or not Box:FindFirstChild("MaxAmmo") or not AllowEmpty and Box.Ammo.Value <= 0 then return false end
        local Only = Box:FindFirstChild("CreatorOnly")
        local Creator = Box:FindFirstChild("Creator")
        return not Only or not Only.Value or Creator and Creator.Value == P
    end
    function A:Avoid(Box, Seconds)
        self.BlockedUntil[Box] = os.clock() + (Seconds or 8)
    end
    function A:NativeBox(Root)
        local Map = W:FindFirstChild("Map")
        local Upgrades = Map and Map:FindFirstChild("Upgrades")
        local Box = Upgrades and Upgrades:FindFirstChild("AmmoBox")
        local Roof = Upgrades and Upgrades:FindFirstChild("RoofAmmo")
        if Root.Position.X <= 0 and Roof and self:Eligible(Roof, true) then Box = Roof end
        local Deployables = W:FindFirstChild("Deployables")
        if Deployables then
            for _, Group in ipairs(Deployables:GetChildren()) do
                for _, B in ipairs(Group:GetChildren()) do
                    if (B.Name == "DeployableAmmo" or B.Name == "SupplyCrate") and self:Eligible(B, true)
                        and (Root.Position - B.PrimaryPart.Position).Magnitude < 8 then Box = B end
                end
            end
        end
        return Box
    end
    function A:Nearest(Root, Cost)
        if os.clock() - self.LastBoxes >= 1 then
            self.LastBoxes = os.clock(); self.Boxes = {}
            local Map = W:FindFirstChild("Map")
            local Upgrades = Map and Map:FindFirstChild("Upgrades")
            for _, Name in ipairs({"AmmoBox", "RoofAmmo"}) do
                local B = Upgrades and Upgrades:FindFirstChild(Name)
                if B then table.insert(self.Boxes, B) end
            end
            local Deployables = W:FindFirstChild("Deployables")
            if Deployables then
                for _, Group in ipairs(Deployables:GetChildren()) do
                    for _, B in ipairs(Group:GetChildren()) do
                        if B.Name == "DeployableAmmo" or B.Name == "SupplyCrate" then table.insert(self.Boxes, B) end
                    end
                end
            end
        end
        local Best, Distance, Score = nil, math.huge, math.huge
        for _, B in ipairs(self.Boxes) do
            if self:Eligible(B) and os.clock() >= (self.BlockedUntil[B] or 0) then
                local D = (Root.Position - B.PrimaryPart.Position).Magnitude
                local S = Cost and Cost(B, D) or D
                if type(S) == "number" and S < Score then Best = B; Distance = D; Score = S end
            end
        end
        return Best, Distance
    end
    function A:Duration(Box, Context)
        local Time = Box.Time.Value
        local Minutes = game:GetService("Lighting"):GetMinutesAfterMidnight()
        if Minutes >= 360 and Minutes < 1080 then Time = Time / 5 end
        return Time / math.max(0.1, Context.Manager:GetMulti("InteractionSpeed", P, {IgnoreTool = true}))
    end
    function A:Begin(Tool, Box, Root)
        if not self.Alive or self.Pending or os.clock() < self.NextTry then return false, "Refill cooling down" end
        if not self:Eligible(Box) then return false, "Ammo box empty or unavailable" end
        if (Root.Position - Box.PrimaryPart.Position).Magnitude >= 8 then return false, "Move within 8 studs of box" end
        if self:NativeBox(Root) ~= Box then self:Avoid(Box); return false, "Native interaction selects another box" end
        local Gui = P:FindFirstChild("PlayerGui")
        if Gui and Gui:FindFirstChild("MenuGui") then return false, "Close the native game menu" end
        local Reloading = Tool:FindFirstChild("Reloading")
        if Tool.Parent ~= P.Character or not Reloading or Reloading.Value then return false, "Waiting for equipped gun" end
        local Context = self:Context()
        if not Context then return false, "Native refill version unsupported" end
        if debug.getupvalue(Context.Function, 3) ~= false then return false, "Native interaction already busy" end
        local Record = {Tool = Tool, Box = Box, Before = Tool.CurrentValues.Ammo.Value, Started = os.clock(), Done = false}
        self.Pending = Record; self.NextTry = os.clock() + 3
        task.spawn(function()
            if not self.Alive or self.CanStart and not self.CanStart() then Record.Done = true; Record.Error = "Cancelled"; return end
            local OK, Error = pcall(Context.Function)
            if not OK and debug.getupvalue(Context.Function, 3) == true then
                -- Only recover the interaction started by this call, after its thread has returned.
                debug.setupvalue(Context.Function, 3, false)
                Tool.Enabled = true
                local UI: any = debug.getupvalue(Context.Function, 4)
                pcall(function() UI.Progress.Visible = false; UI.Progress.ProgressBar.Visible = false end)
            end
            Record.OK = OK; Record.Error = not OK and tostring(Error) or nil
            Record.After = Tool.Parent and Tool.CurrentValues.Ammo.Value or Record.Before
            Record.Seconds = os.clock() - Record.Started
            Record.Done = true
        end)
        return true, "Refilling reserve at native speed"
    end
    function A:Poll()
        local R = self.Pending
        if not R then return "idle" end
        if not R.Done then return "waiting", R end
        self.Pending = nil
        if R.OK and R.After > R.Before then return "refilled", R end
        self:Avoid(R.Box)
        return "failed", R
    end
    function A:Destroy() self.Alive = false end
    return A
end
