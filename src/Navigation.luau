-- Local steering plus navmesh routes: geometry is always respected.
return function()
    local W: any = workspace
    local P: any = game:GetService("Players").LocalPlayer
    local Paths = game:GetService("PathfindingService")
    local N: any = {Alive = true, NextPlan = 0, LastProgress = 0}
    local function Flat(V) return Vector3.new(V.X, 0, V.Z) end
    local function Unit(V) return V.Magnitude > 0.001 and V.Unit or Vector3.zero end
    function N:Params(Root)
        local R = RaycastParams.new()
        R.FilterType = Enum.RaycastFilterType.Exclude
        local Ignore = {}
        if P.Character then table.insert(Ignore, P.Character) end
        local Z = W:FindFirstChild("Zombies")
        if Z then table.insert(Ignore, Z) end
        if W.CurrentCamera then table.insert(Ignore, W.CurrentCamera) end
        R.FilterDescendantsInstances = Ignore; R.RespectCanCollide = true
        if Root and type(Root.CollisionGroup) == "string" then R.CollisionGroup = Root.CollisionGroup end
        return R
    end
    function N:Ground(Position, Params)
        return W:Raycast(Position + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), Params)
    end
    function N:Separation(Position, Zombies)
        local Distance, Away = math.huge, Vector3.zero
        for _, Z in ipairs(Zombies) do
            if Z.Head.Parent and Z.Humanoid.Health > 0 then
                local Delta = Flat(Position - Z.Head.Position)
                local D = Delta.Magnitude
                Distance = math.min(Distance, D)
                Away = Away + Unit(Delta) / math.max(2, D)
            end
        end
        return Distance, Unit(Away)
    end
    function N:Segment(Root, Direction, Length, Params, FloorY)
        local Hit = W:Blockcast(CFrame.new(Root.Position + Vector3.new(0, 0.3, 0)),
            Vector3.new(3, 4.2, 3), Direction * Length, Params)
        local Clearance = Hit and Hit.Distance or Length
        if Clearance < 2.8 then return false, Clearance end
        local Travel = math.min(Length, Clearance - 0.7)
        for I = 1, 3 do
            local Ground = self:Ground(Root.Position + Direction * (Travel * I / 3), Params)
            if not Ground or Ground.Normal.Y < 0.6 or FloorY and math.abs(Ground.Position.Y - FloorY) > 3 then return false, Clearance end
        end
        return true, Clearance
    end
    function N:LocalDirection(Root, Zombies, Radius, Params, FloorY, Away)
        local Best, BestScore = nil, -math.huge
        for I = 0, 15 do
            local Angle = I * math.pi / 8
            local D = Vector3.new(math.cos(Angle), 0, math.sin(Angle))
            local Valid, Clearance = self:Segment(Root, D, 8, Params, FloorY)
            if Valid then
                local End = Root.Position + D * math.min(7, Clearance - 0.8)
                local Safe = self:Separation(End, Zombies)
                local Score = math.min(Safe, Radius + 20) * 3 + D:Dot(Away) * 5 + Clearance
                if self.LastDirection then Score = Score + D:Dot(self.LastDirection) * 2 end
                if self.StuckDirection then Score = Score - math.max(0, D:Dot(self.StuckDirection)) * 18 end
                if Score > BestScore then Best = D; BestScore = Score end
            end
        end
        return Best
    end
    function N:Plan(Root, Zombies, Radius, Away, Params, FloorY)
        if self.Planning or os.clock() < self.NextPlan then return end
        self.Planning = true; self.NextPlan = os.clock() + 0.8
        local Token = {}; self.Token = Token
        local Start = Root.Position
        local Candidates = {}
        -- One goal per distance band prevents three unreachable long goals starving nearby exits.
        for _, Distance in ipairs({math.clamp(Radius + 8, 20, 45), math.clamp(Radius * 0.6, 14, 25), math.clamp(Radius * 0.3, 8, 12)}) do
            local BestGoal
            for I = 0, 15 do
                local Angle = I * math.pi / 8
                local D = Vector3.new(math.cos(Angle), 0, math.sin(Angle))
                local Goal = Start + D * Distance
                local G = self:Ground(Goal, Params)
                if G and G.Normal.Y >= 0.6 and math.abs(G.Position.Y - FloorY) < 5 then
                    local Safe = self:Separation(G.Position, Zombies)
                    local Score = math.min(Safe, Radius + 30) * 3 + D:Dot(Away) * 8
                    if self.StuckDirection then Score = Score - math.max(0, D:Dot(self.StuckDirection)) * 25 end
                    if not BestGoal or Score > BestGoal.Score then BestGoal = {Position = G.Position, Score = Score} end
                end
            end
            if BestGoal then table.insert(Candidates, BestGoal) end
        end
        task.spawn(function()
            local Best, BestScore = nil, -math.huge
            for I = 1, math.min(3, #Candidates) do
                if not self.Alive or self.Token ~= Token then return end
                local Candidate = Candidates[I]
                local OK, Route = pcall(function()
                    local Path = Paths:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4})
                    Path:ComputeAsync(Start, Candidate.Position)
                    if Path.Status == Enum.PathStatus.Success then return Path:GetWaypoints() end
                    return nil
                end)
                if OK and Route and #Route >= 2 then
                    local Safe, Length, MinDistance = true, 0, math.huge
                    local InitialDistance = self:Separation(Start, Zombies)
                    for J = 2, #Route do
                        local Separation = self:Separation(Route[J].Position, Zombies)
                        MinDistance = math.min(MinDistance, Separation)
                        Length = Length + (Route[J].Position - Route[J - 1].Position).Magnitude
                        if Separation < math.min(8, math.max(1, InitialDistance - 2)) then Safe = false end
                    end
                    local Score = Candidate.Score + math.min(MinDistance, Radius + 15) * 2 - Length * 0.1
                    if Safe and Score > BestScore then Best = Route; BestScore = Score end
                end
            end
            if not self.Alive or self.Token ~= Token then return end
            self.Planning = false
            if Best then self.Route = Best; self.Index = 2; self.RouteAt = os.clock(); self.JumpIndex = nil end
        end)
    end
    function N:Reset()
        self.Token = nil; self.Planning = false; self.Route = nil; self.Active = false
        self.LastDirection = nil; self.Position = nil; self.NextPlan = 0
    end
    function N:Update(H, Root, Zombies, Radius)
        local Nearest, Away = self:Separation(Root.Position, Zombies)
        self.Nearest = Nearest
        if not self.Active and Nearest >= Radius or self.Active and Nearest >= Radius + 8 then
            self:Reset(); self.Status = "Safe distance"; return nil
        end
        self.Active = true
        local Params = self:Params(Root)
        local Ground = self:Ground(Root.Position, Params)
        if not Ground then self.Status = "No ground; retreat paused"; return nil end
        if self.StuckUntil and os.clock() >= self.StuckUntil then self.StuckDirection = nil end
        if not self.Position or os.clock() - self.LastProgress >= 1 then
            if self.Position and self.LastDirection and (Root.Position - self.Position).Magnitude < 0.8 then
                self.StuckDirection = self.LastDirection; self.StuckUntil = os.clock() + 2
                self.Token = nil; self.Planning = false; self.Route = nil; self.NextPlan = 0
            end
            self.Position = Root.Position; self.LastProgress = os.clock()
        end
        self:Plan(Root, Zombies, Radius, Away, Params, Ground.Position.Y)
        local Direction
        if self.Route then
            local Point = self.Route[self.Index]
            while Point and (Point.Position - Root.Position).Magnitude < 3 do
                if Point.Action == Enum.PathWaypointAction.Jump then H.Jump = true end
                self.Index = self.Index + 1; Point = self.Route[self.Index]
            end
            if Point and os.clock() - self.RouteAt < 4 then
                if Point.Action == Enum.PathWaypointAction.Jump and (Point.Position - Root.Position).Magnitude < 6 and self.JumpIndex ~= self.Index then
                    H.Jump = true; self.JumpIndex = self.Index
                end
                Direction = Unit(Flat(Point.Position - Root.Position))
                local Valid = self:Segment(Root, Direction, math.min(5, math.max(3, (Point.Position - Root.Position).Magnitude)), Params, Ground.Position.Y)
                if not Valid then self.Route = nil; self.NextPlan = 0; Direction = nil end
            else self.Route = nil; self.NextPlan = 0 end
        end
        if not Direction or Direction.Magnitude < 0.01 then Direction = self:LocalDirection(Root, Zombies, Radius, Params, Ground.Position.Y, Away) end
        self.LastDirection = Direction
        self.Status = Direction and "Retreating via clear path" or "Blocked; searching for a route"
        return Direction
    end
    function N:Destroy() self.Alive = false; self:Reset() end
    return N
end
