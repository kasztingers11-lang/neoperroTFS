 
return function(Library: any, Window: any)
    local P: any = game:GetService("Players").LocalPlayer
    local RS: any = game:GetService("ReplicatedStorage")
    local Run = game:GetService("RunService")
    local Http = game:GetService("HttpService")
    local W: any = workspace
    local Flags = Library.Flags
    local V: any = {Alive = true, Connections = {}, Callbacks = {}, Tracers = {}, Chams = {},
        Drawings = {}, LastHit = -10, DamageAt = -10, LastRender = -10, LastContactScan = -10}
    local Red = Color3.fromRGB(255, 25, 65)
    local White = Color3.fromRGB(255, 237, 241)
    local RenderName = "NeoperroHitVisuals"
    local function Finite(N) return type(N) == "number" and N == N and math.abs(N) < math.huge end
    function V:Intensity()
        return math.clamp(Finite(Flags.VisualIntensity) and Flags.VisualIntensity or 2, 1, 3)
    end
    function V:ApplyStyle()
        local Scale = self:Intensity()
        for _, T in ipairs(self.Tracers) do T.Glow.Thickness = 7 + Scale * 2; T.Core.Thickness = 2 + Scale * 0.5 end
        for _, Lines in ipairs(self.HitLines or {}) do Lines.Glow.Thickness = 6 + Scale * 2; Lines.Core.Thickness = 2 + Scale * 0.5 end
        if self.DamageText then self.DamageText.Size = 20 + Scale * 3 end
    end
    local function Duration(Key, Default)
        local N = Flags[Key]
        return math.clamp(Finite(N) and N or Default, 0.1, 0.8)
    end
    local function Connect(S, Fn)
        if not S then return end
        local C = S:Connect(Fn); table.insert(V.Connections, C); return C
    end
    local function DrawingObject(Kind, Properties)
        local D = Drawing.new(Kind)
        for K, Value in pairs(Properties) do D[K] = Value end
        table.insert(V.Drawings, D)
        return D
    end
    local function Destroy(O) if O then pcall(function() O:Destroy() end) end end
    function V:BindSignals(Force)
        if not self.Alive or not Force and os.clock() < (self.NextSignalCheck or 0) then return end
        self.NextSignalCheck = os.clock() + 1
        local Scripts = P:FindFirstChild("PlayerScripts")
        local Manager = Scripts and Scripts:FindFirstChild("LocalVisualManager")
        local Remotes = RS:FindFirstChild("RemoteEvents")
        local Objects = {Fire = Manager and Manager:FindFirstChild("LocalFireEvent"),
            Hit = Remotes and Remotes:FindFirstChild("RemoteHitmarker"), Damage = Remotes and Remotes:FindFirstChild("ReturnServerDamage")}
        self.SignalObjects = self.SignalObjects or {}; self.SignalConnections = self.SignalConnections or {}
        for _, Key in ipairs({"Fire", "Hit", "Damage"}) do
            local Object = Objects[Key]
            if Object and not Object:IsA(Key == "Fire" and "BindableEvent" or "RemoteEvent") then Object = nil end
            if self.SignalObjects[Key] ~= Object then
                if self.SignalConnections[Key] then self.SignalConnections[Key]:Disconnect(); self.SignalConnections[Key] = nil end
                self.SignalObjects[Key] = Object
                if Object then
                    if Key == "Fire" then self.SignalConnections[Key] = Object.Event:Connect(function(...) self:OnShot(...) end)
                    elseif Key == "Hit" then self.SignalConnections[Key] = Object.OnClientEvent:Connect(function() self:OnHit() end)
                    else self.SignalConnections[Key] = Object.OnClientEvent:Connect(function(Amount) self:OnDamage(Amount) end) end
                end
                self.ContactHit = nil; self.HitContact = nil
            end
        end
    end
    function V:Point(Value)
        if typeof(Value) == "Vector3" then return Value end
        if type(Value) == "string" and #Value < 2048 then
            local OK, Data = pcall(Http.JSONDecode, Http, Value)
            if OK and type(Data) == "table" and Finite(Data[1]) and Finite(Data[2]) and Finite(Data[3]) then
                return Vector3.new(Data[1], Data[2], Data[3])
            end
        end
        return nil
    end
    function V:Zombie(Part)
        if typeof(Part) ~= "Instance" then return nil end
        local Folder = W:FindFirstChild("Zombies")
        local Node = Part
        for _ = 1, 8 do
            if not Node or Node == W then break end
            if Node:IsA("Model") and Folder and Node:IsDescendantOf(Folder) and Node:FindFirstChildOfClass("Humanoid") then return Node end
            Node = Node.Parent
        end
        return nil
    end
    function V:AddCham(Model)
        if not Flags.VisualHitChams or not Model or Model == P.Character or self:Zombie(Model) ~= Model then return end
        local Existing = self.Chams[Model]
        if Existing then Existing.At = os.clock(); return end
        local Count, OldestModel, Oldest = 0, nil, math.huge
        for M, Record in pairs(self.Chams) do
            Count = Count + 1
            if Record.At < Oldest then Oldest = Record.At; OldestModel = M end
        end
        if Count >= 16 and OldestModel then Destroy(self.Chams[OldestModel].Object); self.Chams[OldestModel] = nil end
        if not self.Folder then
            self.Folder = Instance.new("Folder"); self.Folder.Name = "NeoperroHitEffects"; self.Folder.Parent = W
        end
        local H = Instance.new("Highlight")
        H.Name = "HitFlash"; H.Adornee = Model; H.FillColor = Red; H.OutlineColor = White
        H.FillTransparency = 0.08; H.OutlineTransparency = 0; H.DepthMode = Enum.HighlightDepthMode.Occluded
        H.Parent = self.Folder
        self.Chams[Model] = {Object = H, At = os.clock()}
    end
    function V:AddTracer(Start, Finish)
        if not Flags.VisualTracers or not Start or not Finish or (Finish - Start).Magnitude < 0.05 then return end
        local Record
        for _, T in ipairs(self.Tracers) do if not T.Active then Record = T; break end end
        if not Record and #self.Tracers < 96 then
            Record = {Glow = DrawingObject("Line", {Color = Red, Thickness = 7 + self:Intensity() * 2, ZIndex = 3}),
                Core = DrawingObject("Line", {Color = White, Thickness = 2 + self:Intensity() * 0.5, ZIndex = 4})}
            table.insert(self.Tracers, Record)
        end
        if not Record then
            Record = self.Tracers[1]
            for _, T in ipairs(self.Tracers) do if T.At < Record.At then Record = T end end
        end
        Record.Start = Start; Record.Finish = Finish; Record.At = os.clock(); Record.Active = true
    end
    function V:Contact(Start, Finish, Tool)
        if not Start or not Finish or (Finish - Start).Magnitude < 0.01 then return nil end
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        local Ignore = {}
        if P.Character then table.insert(Ignore, P.Character) end
        if W.CurrentCamera then table.insert(Ignore, W.CurrentCamera) end
        if Tool then table.insert(Ignore, Tool) end
        local Guns = Library.Features
        local B = Guns and Guns.Weapons and Guns.Weapons[Tool]
        if B and B.Manager and type(B.Manager.GetIgnoreList) == "function" then
            local OK, Extra = pcall(B.Manager.GetIgnoreList, B.Manager)
            if OK and type(Extra) == "table" then
                for _, Item in ipairs(Extra) do if typeof(Item) == "Instance" then table.insert(Ignore, Item) end end
            end
        end
        Params.FilterDescendantsInstances = Ignore
        local Delta = Finish - Start
        local Hit = W:Raycast(Start, Delta + Delta.Unit * 0.35, Params)
        return Hit and self:Zombie(Hit.Instance) or nil, Hit and Hit.Position
    end
    function V:OnShot(Player, Tool, Muzzle, Rays)
        if not self.Alive or Player ~= P or type(Rays) ~= "table" then return end
        local Head = P.Character and P.Character:FindFirstChild("Head")
        local Origin = typeof(Muzzle) == "Instance" and Muzzle:IsA("BasePart") and Muzzle.Position or Head and Head.Position
        local Count, Contacts = 0, 0
        local Scan = (Flags.VisualHitChams or Flags.VisualHitIndicator) and os.clock() - self.LastContactScan >= 1 / 30
        for _, Row in pairs(Rays) do
            if type(Row) == "table" then
                Count = Count + 1; if Count > 16 then break end
                local Finish = self:Point(Row[1])
                local Start = self:Point(Row[4]) or Origin
                if type(Row[4]) == "number" and type(Rays[Row[4]]) == "table" then Start = self:Point(Rays[Row[4]][1]) or Start end
                self:AddTracer(Start, Finish)
                local Model = self:Zombie(Row[2])
                local ContactPoint = Finish
                 
                 
                if not Model and Scan and Contacts < 4 then
                    Contacts = Contacts + 1
                    Model, ContactPoint = self:Contact(Head and Head.Position or Start, Finish, Tool)
                end
                if Model then
                    self.ContactHit = {Model = Model, Position = ContactPoint or Finish, At = os.clock()}
                end
                self:AddCham(Model)
            end
        end
        if Scan then self.LastContactScan = os.clock() end
        self:Refresh()
    end
    function V:OnHit()
        if not self.Alive then return end
        self.LastHit = os.clock()
        local Contact = self.ContactHit
        self.HitContact = Contact and os.clock() - Contact.At <= 0.5 and Contact or nil
        self:Refresh()
    end
    function V:OnDamage(Amount)
        if not self.Alive or not Finite(Amount) or Amount <= 0 then return end
        self:OnHit()
        self.RecentDamage = os.clock() - self.DamageAt < 0.15 and (self.RecentDamage or 0) + Amount or Amount
        self.DamageAt = os.clock(); self:Refresh()
    end
    function V:HitDrawings()
        if self.HitLines then return end
        self.HitLines = {}
        for I = 1, 4 do
            self.HitLines[I] = {Glow = DrawingObject("Line", {Color = Red, Thickness = 6 + self:Intensity() * 2, ZIndex = 7}),
                Core = DrawingObject("Line", {Color = White, Thickness = 2 + self:Intensity() * 0.5, ZIndex = 8})}
        end
        self.DamageText = DrawingObject("Text", {Color = White, Font = Drawing.Fonts.System, Size = 20 + self:Intensity() * 3, Center = true, Outline = true, ZIndex = 8})
    end
    function V:Render()
        if not self.Alive then return end
        local Camera = W.CurrentCamera
        local Now = os.clock()
        if Now >= (self.NextSignalCheck or 0) then self:BindSignals() end
        for _, T in ipairs(self.Tracers) do
            if T.Active then
            local Alpha = 1 - (Now - (T.At or -10)) / Duration("VisualTracerTime", 0.35)
            local Visible = T.Active and Flags.VisualTracers and Camera and Alpha > 0
            if Visible then
                local X = Camera:WorldToViewportPoint(T.Start)
                local Y = Camera:WorldToViewportPoint(T.Finish)
                Visible = X.Z > 0 and Y.Z > 0
                if Visible then
                    T.Glow.From = Vector2.new(X.X, X.Y); T.Glow.To = Vector2.new(Y.X, Y.Y)
                    T.Core.From = T.Glow.From; T.Core.To = T.Glow.To
                    T.Glow.Transparency = Alpha * 0.75; T.Core.Transparency = Alpha
                end
            end
            T.Glow.Visible = Visible == true; T.Core.Visible = Visible == true
            if Alpha <= 0 or not Flags.VisualTracers then T.Active = false end
            end
        end
        for Model, Record in pairs(self.Chams) do
            local Alpha = (Now - Record.At) / Duration("VisualHitTime", 0.45)
            if not Flags.VisualHitChams or not Model.Parent or Alpha >= 1 then
                Destroy(Record.Object); self.Chams[Model] = nil
            else Record.Object.FillTransparency = 0.08 + Alpha * 0.92; Record.Object.OutlineTransparency = Alpha end
        end
        if Flags.VisualHitIndicator then self:HitDrawings() end
        if self.HitLines then
            local Alpha = 1 - (Now - self.LastHit) / Duration("VisualHitTime", 0.45)
            local Contact = self.HitContact
            local Point = Contact and Contact.Position
            local Head = Contact and Contact.Model and Contact.Model:FindFirstChild("Head")
            if Head and Head.Parent then Point = Head.Position end
            local Screen, OnScreen
            if Camera and Point then Screen, OnScreen = Camera:WorldToViewportPoint(Point) end
            local Visible = Flags.VisualHitIndicator and Screen and OnScreen and Screen.Z > 0 and Alpha > 0
            for I, Lines in ipairs(self.HitLines) do
                Lines.Glow.Visible = Visible == true; Lines.Core.Visible = Visible == true
                if Visible then
                    local SX = (I == 1 or I == 4) and -1 or 1
                    local SY = I <= 2 and -1 or 1
                    local X, Y = Screen.X, Screen.Y
                    local Scale = self:Intensity()
                    local Offset = 8 + Scale + (1 - Alpha) * 6
                    Lines.Glow.From = Vector2.new(X + SX * Offset, Y + SY * Offset)
                    Lines.Glow.To = Vector2.new(X + SX * (Offset + 12 + Scale * 3), Y + SY * (Offset + 12 + Scale * 3))
                    Lines.Core.From = Lines.Glow.From; Lines.Core.To = Lines.Glow.To
                    Lines.Glow.Transparency = Alpha * 0.8; Lines.Core.Transparency = Alpha
                end
            end
            local DamageAlpha = 1 - (Now - self.DamageAt) / 0.6
            self.DamageText.Visible = Flags.VisualHitIndicator == true and Screen ~= nil and OnScreen == true and Screen.Z > 0 and DamageAlpha > 0
            if self.DamageText.Visible then
                self.DamageText.Text = tostring(math.floor((self.RecentDamage or 0) + 0.5))
                self.DamageText.Position = Vector2.new(Screen.X, Screen.Y + 24 - (1 - DamageAlpha) * 14)
                self.DamageText.Transparency = DamageAlpha
            end
        end
    end
    function V:Refresh()
        self:BindSignals()
        local Need = Flags.VisualTracers or Flags.VisualHitChams or Flags.VisualHitIndicator
        if Need and not self.Rendering then
            self.Rendering = true
            Run:BindToRenderStep(RenderName, Enum.RenderPriority.Last.Value + 3, function()
                local Now = os.clock()
                if Now < (self.NextRender or 0) then return end
                local Next = (self.NextRender or Now) + 1 / 144
                self.NextRender = Next > Now and Next or Now + 1 / 144
                self.LastRender = Now
                local OK, Error = pcall(self.Render, self)
                if not OK then
                    self:Destroy(); Window.SendNotification("Warning", "Visuals stopped: " .. tostring(Error), 5)
                end
            end)
        elseif not Need and self.Rendering then
            self:Render(); Run:UnbindFromRenderStep(RenderName); self.Rendering = false
        end
    end
    function V:Destroy()
        if not self.Alive then return end
        self.Alive = false
        Run:UnbindFromRenderStep(RenderName)
        for _, C in ipairs(self.Connections) do C:Disconnect() end
        for _, C in pairs(self.SignalConnections or {}) do C:Disconnect() end
        self.SignalConnections = {}; self.SignalObjects = {}
        for Item, Record in pairs(self.Callbacks) do if Item.Callback == Record.Owned then Item.Callback = Record.Previous end end
        for _, D in ipairs(self.Drawings) do pcall(function() D:Remove() end) end
        Destroy(self.Folder); self.Chams = {}; self.Tracers = {}
    end
    for _, Key in ipairs({"VisualTracers", "VisualHitChams", "VisualHitIndicator", "VisualIntensity"}) do
        local Item = Library.Items[Key]
        if Item then
            local Previous = Item.Callback
            local Owned = function(Value) Previous(Value); if V.Alive then V:ApplyStyle(); V:Refresh() end end
            V.Callbacks[Item] = {Previous = Previous, Owned = Owned}; Item.Callback = Owned
        end
    end
    V:Refresh()
    return V
end
