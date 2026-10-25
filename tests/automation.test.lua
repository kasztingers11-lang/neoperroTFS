-- State-machine tests of the actual factories; this is not a Roblox/server simulator.
local AutoFactory = LoadSource("Automation")
local ShopFactory = LoadSource("ShopAdapter")
local GunFactory = LoadSource("Features")
local NavFactory = LoadSource("Navigation")
local AmmoFactory = LoadSource("AmmoAdapter")
local VisualFactory = LoadSource("Visuals")
local passed, failed = 0, 0
local function test(name, fn)
    local ok, message = pcall(fn)
    if ok then passed = passed + 1; print("PASS " .. name)
    else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(message)) end
end
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function signal()
    local s = {listeners = {}}
    function s:Connect(fn)
        local c = {Enabled = true, Function = fn}
        function c:Disconnect() self.Enabled = false end
        table.insert(self.listeners, c); return c
    end
    function s:Fire(...)
        local copy = {}; for _, c in ipairs(self.listeners) do table.insert(copy, c) end
        for _, c in ipairs(copy) do if c.Enabled then c.Function(...) end end
    end
    return s
end
local V = {}; V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z) end
    if k == "Unit" then local m = v.Magnitude; return Vector3.new(v.X/m,v.Y/m,v.Z/m) end
    return V[k]
end
function V.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function V.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function V.__mul(a,b) if type(a)=="number" then a,b=b,a end; return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function V.__div(a,b) return Vector3.new(a.X/b,a.Y/b,a.Z/b) end
function V.__unm(a) return Vector3.new(-a.X,-a.Y,-a.Z) end
function V:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
function V:Cross(b) return Vector3.new(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X) end
Vector3 = {new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},V) end}
Vector3.zero=Vector3.new(0,0,0)
Vector2={new=function(x,y) return {X=x,Y=y} end}
local CF={}; CF.__index=CF
function CF:VectorToWorldSpace(v) return self.Right*v.X+self.Up*v.Y+self.Back*v.Z end
function CF:VectorToObjectSpace(v) return Vector3.new(v:Dot(self.Right),v:Dot(self.Up),v:Dot(self.Back)) end
function CF:Inverse()
    local out=setmetatable({Right=Vector3.new(self.Right.X,self.Up.X,self.Back.X),
        Up=Vector3.new(self.Right.Y,self.Up.Y,self.Back.Y),Back=Vector3.new(self.Right.Z,self.Up.Z,self.Back.Z)},CF)
    out.Position=out:VectorToWorldSpace(-self.Position); return out
end
function CF.__mul(a,b)
    return setmetatable({Position=a.Position+a:VectorToWorldSpace(b.Position),Right=a:VectorToWorldSpace(b.Right),
        Up=a:VectorToWorldSpace(b.Up),Back=a:VectorToWorldSpace(b.Back)},CF)
end
CFrame={new=function(p) return setmetatable({Position=p or Vector3.zero,Right=Vector3.new(1,0,0),Up=Vector3.new(0,1,0),Back=Vector3.new(0,0,1)},CF) end,
    lookAt=function(p,t)
        local forward=(t-p).Unit; local right=forward:Cross(Vector3.new(0,1,0)).Unit
        return setmetatable({Position=p,Right=right,Up=right:Cross(forward),Back=-forward},CF)
    end}
Color3={fromRGB=function(...) return {...} end}
math.clamp=function(n,a,b) return math.min(b, math.max(a,n)) end
table.find=function(t,v) for i,x in ipairs(t) do if x==v then return i end end end
table.clear=function(t) for k in pairs(t) do t[k]=nil end end
local Methods = {}
local Obj = {__index=function(self,k) return Methods[k] or rawget(self,k) or self.children[k] end}
local function instance(name, class, parent, props)
    local o=setmetatable({Name=name,ClassName=class or "Folder",children={},ChildAdded=signal(),
        ChildRemoved=signal(),DescendantAdded=signal(),DescendantRemoving=signal()},Obj)
    for k,v in pairs(props or {}) do o[k]=v end
    if parent then parent:Add(o) end
    return o
end
function Methods:Add(o) self.children[o.Name]=o; o.Parent=self end
function Methods:Remove(o) self.children[o.Name]=nil; o.Parent=nil end
function Methods:GetChildren() local t={}; for _,v in pairs(self.children) do table.insert(t,v) end; return t end
function Methods:FindFirstChild(name, recursive)
    if not name then return nil end
    if self.children[name] then return self.children[name] end
    if recursive then for _,v in pairs(self.children) do local x=v:FindFirstChild(name,true); if x then return x end end end
end
function Methods:IsA(c)
    return self.ClassName==c or c=="BasePart" and self.ClassName=="Part"
        or c=="ValueBase" and self.ClassName:find("Value",1,true)~=nil
end
function Methods:FindFirstChildOfClass(c) for _,v in pairs(self.children) do if v:IsA(c) then return v end end end
function Methods:IsDescendantOf(p) local x=self.Parent; while x do if x==p then return true end; x=x.Parent end; return false end
function Methods:Move(direction, relative) self.LastMove=direction; self.Relative=relative end
function Methods:MoveTo(position) self.LastMoveTo=position end
function Methods:EquipTool(tool) tool.Parent:Remove(tool); self.Parent:Add(tool) end
typeof=function(x) return getmetatable(x)==Obj and "Instance" or getmetatable(x)==V and "Vector3" or type(x) end
Enum={KeyCode={LeftShift="LShift",RightShift="RShift"}, UserInputType={MouseButton1="M1"},
    RaycastFilterType={Exclude="Exclude"}, MouseBehavior={LockCenter="Center"},
    CameraMode={Classic="Classic"},RenderPriority={Camera={Value=200},Last={Value=2000}},PathStatus={Success="Success"},
    PathWaypointAction={Jump="Jump"}}
RaycastParams={new=function() return {} end}
local Now, Active, Presses, Releases, ShiftPresses, ShiftReleases, Tasks
os.clock=function() return Now end
isrbxactive=function() return Active end
mouse1press=function() Presses=Presses+1 end
mouse1release=function() Releases=Releases+1 end
keypress=function() ShiftPresses=ShiftPresses+1 end
keyrelease=function() ShiftReleases=ShiftReleases+1 end
task={spawn=function(fn) table.insert(Tasks,fn) end, defer=function(fn) fn() end}
Drawing={Fonts={UI=2},new=function()
    return {Remove=function(self) self.Removed=true end}
end}
local function flush() local tasks=Tasks; Tasks={}; for _,fn in ipairs(tasks) do fn() end end
local function setup(native)
    Now=100; Active=true; Presses=0; Releases=0; ShiftPresses=0; ShiftReleases=0; Tasks={}
    local p=instance("Player"); p.CharacterAdded=signal(); p.CameraMode="FirstPerson"
    p.CameraMinZoomDistance=0.5; p.CameraMaxZoomDistance=12
    local mouse={X=500,Y=400}; function p:GetMouse() return mouse end
    local character=instance("Character"); p.Character=character
    local h=instance("Humanoid","Humanoid",character,{Health=100})
    local root=instance("HumanoidRootPart","Part",character,{Position=Vector3.new(0,3,0)})
    instance("Head","Part",character,{Position=Vector3.new(0,4.5,0)})
    local bag=instance("Backpack","Backpack",p)
    local backgear=instance("Backgear","Folder",p)
    local levels=instance("GunUpgrades","Folder",instance("Upgrades","Folder",p))
    local cash=instance("ReplicatedMoney","IntValue",p,{Value=1000})
    instance("InsideShop","BoolValue",p,{Value=true})
    local gui=instance("PlayerGui","Folder",p)
    instance("VoteSkip","TextButton",gui,{Text="Ready"})
    local run={Heartbeat=signal(),Bindings={}}
    function run:BindToRenderStep(name,_,fn) self.Bindings[name]=fn end
    function run:UnbindFromRenderStep(name) self.Bindings[name]=nil end
    local input={MouseBehavior="Default",WindowFocusReleased=signal(),WindowFocused=signal()}
    function input:GetFocusedTextBox() return self.TextBox end
    function input:IsMouseButtonPressed() return self.PhysicalMouse or false end
    function input:IsKeyDown() return self.PhysicalShift or false end
    local rs=instance("ReplicatedStorage")
    local result=instance("RefreshItemStats","RemoteEvent",instance("RemoteEvents","Folder",rs),{OnClientEvent=signal()})
    instance("MainShopRegion","Part",instance("ShopRegions","Folder",rs),{Position=Vector3.new(30,3,0)})
    local world=instance("Workspace"); local zombies=instance("Zombies","Folder",world)
    world.CurrentCamera={CFrame=CFrame.new(Vector3.new(0,5,0)),ViewportSize=Vector2.new(1000,800)}
    function world.CurrentCamera:WorldToViewportPoint(point) return Vector3.new(point.X,point.Z,1),true end
    function world.CurrentCamera:ScreenPointToRay(x,y)
        return {Origin=self.CFrame.Position,Direction=self.CFrame:VectorToWorldSpace(Vector3.new((x-500)/500,-(y-400)/500,-1)).Unit}
    end
    function world:Raycast(origin,direction,params)
        if self.Ray then return self.Ray(origin,direction,params) end
        if direction.Y < -9 and math.abs(direction.X)<0.001 and math.abs(direction.Z)<0.001 then
            return {Position=Vector3.new(origin.X,0,origin.Z),Normal=Vector3.new(0,1,0)}
        end
        return nil
    end
    function world:Blockcast(cf,size,direction,params) if self.Block then return self.Block(cf,size,direction,params) end end
    local paths={}
    function paths:CreatePath()
        return {Status="Success",ComputeAsync=function(self,from,to) self.To=to end,
            GetWaypoints=function(self) return {{Position=root.Position},{Position=self.To,Action="Walk"}} end}
    end
    local services={Players={LocalPlayer=p},RunService=run,UserInputService=input,
        PathfindingService=paths,ReplicatedStorage=rs,HttpService={JSONDecode=function() error("bad JSON") end},Lighting={GetMinutesAfterMidnight=function() return 390 end}}
    game={GetService=function(_,name) return assert(services[name],name) end}; workspace=world
    local flags={UpgradeWeapon="Select weapon",UpgradePriority="Select upgrade",UpgradeMode="Selected upgrade only",
        FarmDistance=24,FarmAvoidWalls=true,FarmUseSprint=true,CameraDistance=10,UpgradeNotify=true,UpgradeShopFallback=true}
    local lib={Flags=flags,Items={},WindowVisible=false}
    function lib:ChangeVisible(v) self.WindowVisible=v end
    local keys={"UpgradeWeapon","UpgradePriority","UpgradeMode","UpgradeEnabled","UpgradeShopFallback","FarmAutoShoot","FarmRestockBox","FarmBackground","FarmAutoReady",
        "FarmKeepDistance","FarmUseSprint","FarmShowDistance","FarmShowCircle","FarmAutoRefill","CameraThirdPerson","CameraDistance"}
    for _,key in ipairs(keys) do
        local item={Callback=function() end,List={}}
        function item:Set(v) flags[key]=v; self.Callback(v) end
        function item:SetOptions(list,selected)
            local same=#list==#self.List; for i,v in ipairs(list) do if self.List[i]~=v then same=false end end
            self.List=list; if not same or flags[key]~=selected then self:Set(selected) end
        end
        lib.Items[key]=item
    end
    local notices={}; local win={SendNotification=function(_,message) table.insert(notices,message) end}
    local guns={Weapons={},Suspended=false,ApplyCount=0}
    function guns:SetSuspended(v) self.Suspended=v; self.ApplyCount=self.ApplyCount+1 end
    function guns:Refresh() end
    function guns:BindWeapon(tool)
        local b={Environment={Range=100,mouse1Down=false,reload=function() self.Reloaded=true end}}
        self.Weapons[tool]=b; return b
    end
    local function weapon(name,parent)
        local t=instance(name,"Tool",parent or bag)
        instance("GunScript","LocalScript",t)
        local values=instance("CurrentValues","Folder",t)
        for k,v in pairs({Range=100,Clip=5,Ammo=30,FireType="Single",AttackSpeed=300}) do
            instance(k,type(v)=="number" and "NumberValue" or "StringValue",values,{Value=v})
        end
        if not levels:FindFirstChild(name) then
            local group=instance(name,"Folder",levels)
            instance("AP Rounds","IntConstrainedValue",group,{Value=0,MaxValue=2})
            instance("Extended Mags","IntConstrainedValue",group,{Value=0,MaxValue=1})
        end
        return t
    end
    local function zombie(name,x,z)
        local m=instance(name,"Model",zombies)
        local head=instance("Head","Part",m,{Position=Vector3.new(x,4.5,z)})
        local hum=instance("Zombie","Humanoid",m,{Health=100})
        return {Model=m,Head=head,Humanoid=hum}
    end
    local shop={Alive=true,Calls=0}
    function shop:Levels(name) return levels:FindFirstChild(name) end
    function shop:InShop() return p.InsideShop.Value end
    function shop:BetweenRounds() return #zombies:GetChildren()==0 and p.PlayerGui.VoteSkip.Text=="Ready" end
    function shop:TryPurchase(name,list)
        self.Calls=self.Calls+1
        self.Pending={Weapon=name,Level=list[1],Before=list[1].Value,Started=Now}
        return self.Pending,"Waiting"
    end
    function shop:Poll()
        if not self.Pending then return "idle" end
        if self.Outcome then local pending=self.Pending; self.Pending=nil; local state=self.Outcome; self.Outcome=nil; return state,pending end
        return "waiting",self.Pending
    end
    function shop:PollRestock() return "idle" end
    function shop:PollReady() return "idle" end
    function shop:TryReady() self.ReadyCalls=(self.ReadyCalls or 0)+1; return {},"Ready sent" end
    function shop:Destroy() self.Alive=false end
    local refill={}
    function refill:Poll() return "idle" end
    function refill:Destroy() self.Destroyed=true end
    function refill:Needs(tool) return tool and tool.CurrentValues.Ammo.Value<=20 end
    function refill:Nearest() return nil,math.huge end
    local c={P=p,H=h,Root=root,Bag=bag,Backgear=backgear,Levels=levels,World=world,Run=run,Input=input,RS=rs,
        Result=result,Cash=cash,Lib=lib,Guns=guns,Shop=shop,Weapon=weapon,Zombie=zombie,Notices=notices,Paths=paths,Refill=refill,Mouse=mouse}
    if native then return c end
    c.A=AutoFactory(lib,win,guns,function() return shop end,NavFactory,function() return refill end)
    return c
end

test("inventory excludes catalog-only guns, updates ownership and restores saved priority",function()
    local c=setup(); local t=c.Weapon("Pistol")
    instance("Unowned","Folder",c.Levels)
    c.A:RestoreSelection({UpgradeWeapon="Pistol",UpgradePriority="Extended Mags"})
    eq(c.Lib.Flags.UpgradeWeapon,"Pistol"); eq(c.Lib.Flags.UpgradePriority,"Extended Mags")
    eq(#c.Lib.Items.UpgradeWeapon.List,2); eq(#c.Lib.Items.UpgradePriority.List,3)
    c.Bag:Remove(t); c.A:ScanInventory(); eq(c.Lib.Flags.UpgradeWeapon,"Select weapon")
end)
test("inventory replacement and late saved selection are discovered",function()
    local c=setup(); c.Weapon("Pistol"); c.A:ScanInventory(); c.Lib.Items.UpgradeWeapon:Set("Pistol")
    c.A:RestoreSelection({UpgradeWeapon="Sterling",UpgradePriority="Extended Mags"})
    eq(c.A.SavedPriority,"Extended Mags")
    c.Weapon("Sterling"); c.A:ScanInventory()
    eq(c.Lib.Flags.UpgradeWeapon,"Sterling"); eq(c.Lib.Flags.UpgradePriority,"Extended Mags")
    local old=c.Bag.Sterling; c.Bag:Remove(old); local new=c.Weapon("Sterling"); c.A:ScanInventory()
    eq(c.A.Inventory.Sterling,new)
end)
test("upgrade metadata is excluded from the category list",function()
    local c=setup(); c.Weapon("Pistol")
    instance("Metadata","NumberValue",c.Levels.Pistol,{Value=1})
    c.A:ScanInventory(); c.Lib.Items.UpgradeWeapon:Set("Pistol")
    eq(#c.Lib.Items.UpgradePriority.List,3)
end)

test("selecting an owned gun resolves the placeholder to a real upgrade",function()
    local c=setup(); c.Weapon("Pistol"); c.A:ScanInventory()
    c.Lib.Items.UpgradeWeapon:Set("Pistol")
    eq(c.Lib.Flags.UpgradePriority,"AP Rounds"); eq(#c.A:OrderedLevels(),1)
    c.Lib.Items.UpgradePriority:Set("Select upgrade"); c.A:ScanPriorities()
    eq(c.Lib.Flags.UpgradePriority,"AP Rounds")
    instance("Damage","IntConstrainedValue",c.Levels.Pistol,{Value=0,MaxValue=3})
    c.Lib.Items.UpgradePriority:Set("Select upgrade"); c.A:ScanPriorities()
    eq(c.Lib.Flags.UpgradePriority,"Damage")
end)

test("nearest clear target acquisition avoids casting at every zombie",function()
    local c=setup(); local near=c.Zombie("Nearest",3,0)
    for i=1,100 do c.Zombie("Far"..i,10+i,0) end
    local casts=0; c.World.Ray=function() casts=casts+1; return nil end
    c.A:SnapshotZombies(); eq(c.A:SelectTarget(c.Root.Position,500).Model,near.Model); eq(casts,1)
end)

test("blocked target searches stay throttled at 240 render frames per second",function()
    local c=setup(); c.Weapon("Pistol",c.P.Character); c.Zombie("Blocked",8,0)
    local wall=instance("Wall","Part",c.World); local casts=0
    c.World.Ray=function() casts=casts+1; return {Instance=wall} end
    c.Lib.Flags.FarmAutoShoot=true; c.A:SnapshotZombies()
    for i=0,239 do Now=100+i/240; c.A:PreRender(1/240) end
    assert(casts>=20 and casts<=31,tostring(casts)); eq(Presses,0)
end)

test("single-shot cadence is comparable across 60, 144 and 240 FPS without hitch bursts",function()
    for _,fps in ipairs({60,144,240}) do
        local c=setup(); local t=c.Weapon("Pistol",c.P.Character); c.Zombie("Target",8,0)
        c.Guns:BindWeapon(t).Environment.LAS=540
        c.Lib.Flags.FarmAutoShoot=true; c.A:SnapshotZombies()
        for i=0,fps*2-1 do Now=100+i/fps; c.A:PreRender(1/fps); c.A:Render() end
        assert(Presses>=17 and Presses<=19,tostring(fps)..": "..tostring(Presses))
        Now=110; c.A:PreRender(1/fps); c.A:PreRender(1/fps)
        local before=Presses; c.A:PreRender(1/fps); eq(Presses,before)
    end
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); c.Zombie("Target",8,0)
    c.Guns:BindWeapon(t).Environment.LAS=7200
    c.Lib.Flags.FarmAutoShoot=true; c.A:SnapshotZombies()
    for i=0,239 do Now=100+i/240; c.A:PreRender(1/240); c.A:Render() end
    assert(Presses>70 and Presses<=120,tostring(Presses))
end)

test("distance circle follows every render and reuses geometry and drawings",function()
    local c=setup(); c.Lib.Flags.FarmShowCircle=true
    local casts=0
    c.World.CurrentCamera.WorldToViewportPoint=function(_,p) casts=casts+1; return Vector3.new(p.X,p.Y,1),true end
    c.A:Render(); local offsets=c.A.CircleOffsets; local points=c.A.CirclePoints; local line=c.A.Lines[1]
    Now=Now+1/240; c.Root.Position=Vector3.new(2,3,0); c.A:Render()
    eq(casts,96); eq(c.A.CircleOffsets,offsets); eq(c.A.CirclePoints,points); eq(c.A.Lines[1],line)
    c.Lib.Flags.FarmDistance=50; c.A:Render(); assert(c.A.CircleOffsets~=offsets)
    c.Lib.Flags.FarmShowCircle=false; c.A:Visuals(c.Root); eq(line.Visible,false)
end)
test("head target stays until death, then switches, and respects range and walls",function()
    local c=setup(); local a=c.Zombie("A",8,0); local b=c.Zombie("B",15,0)
    c.A:SnapshotZombies(); c.A:SelectTarget(c.Root.Position,100)
    eq(c.A.Target.Model,a.Model); b.Head.Position=Vector3.new(4,4.5,0)
    eq(c.A:SelectTarget(c.Root.Position,100).Model,a.Model)
    a.Humanoid.Health=0; eq(c.A:SelectTarget(c.Root.Position,100).Model,b.Model)
    eq(c.A:SelectTarget(c.Root.Position,2),nil)
    local wall=instance("Wall","Part",c.World)
    c.World.Ray=function() return {Instance=wall} end
    eq(c.A:SelectTarget(c.Root.Position,100),nil)
end)
test("pre-fire head aim compensates free cursor and releases on death/menu/focus",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); local z=c.Zombie("A",8,0)
    c.Guns:BindWeapon(t); c.Lib.Items.FarmAutoShoot:Set(true); c.A:SnapshotZombies()
    c.Mouse.X=120; c.Mouse.Y=710
    c.A:PreRender(); eq(Presses,1); eq(c.A.LastAimPoint,z.Head.Position)
    assert(c.A.AimError<0.001); eq(c.Input.MouseBehavior,"Default")
    c.Lib.WindowVisible=true; c.A:PreRender(); eq(Releases,1)
    c.Lib.WindowVisible=false; Now=Now+1; c.A:PreRender(); eq(Presses,2)
    Active=false; c.Input.WindowFocusReleased:Fire(); eq(Releases,1)
    Active=true; c.Input.WindowFocused:Fire(); eq(Releases,2)
    z.Humanoid.Health=0; c.A:PreRender(); eq(c.A.Target,nil)
end)
test("manual mouse is not owned and unload completes an unfocused owned release",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); c.Zombie("A",8,0)
    c.Guns:BindWeapon(t); c.Lib.Items.FarmAutoShoot:Set(true); c.A:SnapshotZombies()
    c.Input.PhysicalMouse=true; c.A:PreRender(); eq(Presses,0)
    c.Input.PhysicalMouse=false; c.A:PreRender(); eq(Presses,1)
    Active=false; c.A:Destroy(); Active=true; c.Input.WindowFocused:Fire(); eq(Releases,1)
end)

test("focus-loss event blocks automation even when executor focus status remains stale",function()
    local c=setup(); c.Weapon("Pistol",c.P.Character); c.Zombie("Target",8,0)
    c.Lib.Flags.FarmAutoShoot=true; c.Lib.Flags.FarmKeepDistance=true
    c.Lib.Items.CameraThirdPerson:Set(true); c.A:SnapshotZombies(); c.A:PreRender(1/240)
    eq(Presses,1); c.A:Kite(c.H,c.Root); assert(c.A.MoveDirection)
    c.Input.WindowFocusReleased:Fire(); eq(Active,true); eq(c.A:Focused(),false)
    eq(c.A.MoveDirection,nil); eq(c.A.Navigation.Active,false); eq(c.P.CameraMode,"FirstPerson")
    c.A:Step(); c.A:PreRender(1/240); eq(Presses,1); eq(c.Shop.Calls,0)
    c.Input.WindowFocused:Fire(); eq(c.A:Focused(),true); eq(c.P.CameraMode,"Classic")
end)

test("background mode drives the native gun latch without OS mouse or Shift input",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); c.Zombie("Target",8,0)
    local b=c.Guns:BindWeapon(t); c.Lib.Items.FarmBackground:Set(true)
    c.Lib.Flags.FarmAutoShoot=true; c.A:SnapshotZombies()
    Active=false; c.Input.WindowFocusReleased:Fire(); c.Input.PhysicalMouse=true
    c.A:PreRender(1/240); eq(c.A:Focused(),true); eq(Presses,0)
    eq(b.Environment.mouse1Down,true); eq(c.A.MouseMode,"native")
    c.A:Sprint(true); eq(ShiftPresses,0)
    c.A:ReleaseAim(); eq(b.Environment.mouse1Down,false); eq(Releases,0)
    c.Lib.Items.FarmBackground:Set(false); eq(c.A:Focused(),false)
end)

test("start farming discovers the equipped upgrade and stop releases every automatic action",function()
    local c=setup(); c.Weapon("Pistol",c.P.Character)
    c.Lib.WindowVisible=true; c.A:StartFarm()
    eq(c.Lib.WindowVisible,false); eq(c.Lib.Flags.FarmAutoShoot,true); eq(c.Lib.Flags.FarmAutoRefill,true)
    eq(c.Lib.Flags.FarmKeepDistance,true); eq(c.Lib.Flags.UpgradeWeapon,"Pistol")
    eq(c.Lib.Flags.UpgradeEnabled,nil)
    c.Lib.Flags.FarmRestockBox=true; c.Lib.Flags.UpgradeEnabled=true
    c.A:StopAutomation(); eq(c.Lib.Flags.FarmAutoShoot,false); eq(c.Lib.Flags.FarmKeepDistance,false)
    eq(c.Lib.Flags.FarmAutoRefill,false); eq(c.Lib.Flags.FarmRestockBox,false); eq(c.Lib.Flags.UpgradeEnabled,false)
end)

test("between-wave top-up raises the reserve trigger without enabling purchases",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character)
    local threshold
    c.Refill.Needs=function(_,tool,n) eq(tool,t); threshold=n; return true end
    c.Lib.Flags.FarmRefillThreshold=35; eq(c.A:AmmoTool(),t); eq(threshold,35)
    c.Lib.Flags.FarmTopUp=true; eq(c.A:AmmoTool(),t); eq(threshold,90)
    c.P.PlayerGui.VoteSkip.Text="Kills 1"; eq(c.A:AmmoTool(),t); eq(threshold,35)
end)

test("empty equipped guns switch to a loaded owned gun before an empty backup",function()
    local c=setup(); local empty=c.Weapon("Empty",c.P.Character)
    empty.CurrentValues.Clip.Value=0; empty.CurrentValues.Ammo.Value=0
    local reload=c.Weapon("NeedsReload"); reload.CurrentValues.Clip.Value=0
    c.Weapon("Ready"); c.Lib.Flags.FarmAutoShoot=true; c.A:Shoot(empty); flush()
    assert(c.P.Character:FindFirstChild("Ready"))
end)
test("empty clips use native reload once, charge guns fail closed",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); local z=c.Zombie("A",8,0)
    c.A.Target=z; c.Lib.Flags.FarmAutoShoot=true; t.CurrentValues.Clip.Value=0
    c.Guns:BindWeapon(t); c.A:Shoot(t); c.A:Shoot(t); eq(#Tasks,1); flush(); eq(c.Guns.Reloaded,true)
    t.CurrentValues.Clip.Value=5; t.CurrentValues.FireType.Value="Charge"; c.A:Shoot(t); eq(Presses,0)
end)
test("third person restores the freely controlled view after the native fire phase",function()
    local c=setup(); local z=c.Zombie("A",10,0)
    c.Lib.Items.CameraThirdPerson:Set(true); eq(c.P.CameraMode,"Classic"); eq(c.P.CameraMinZoomDistance,10)
    local visible=c.World.CurrentCamera.CFrame
    c.Mouse.X=100; c.Mouse.Y=50
    c.A:Aim(c.World.CurrentCamera,c.Root,z); assert(c.A.AimError<0.001)
    eq(c.Input.MouseBehavior,"Default"); c.A:Render(); eq(c.World.CurrentCamera.CFrame,visible)
    c.Lib.Items.CameraThirdPerson:Set(false); eq(c.P.CameraMode,"FirstPerson")
    eq(c.P.CameraMinZoomDistance,0.5); eq(c.P.CameraMaxZoomDistance,12)
    c.A:Destroy(); eq(c.Input.MouseBehavior,"Default")
end)
test("retreat moves away in world coordinates and stops safely outside the radius",function()
    local c=setup(); c.Zombie("A",8,0); c.A:SnapshotZombies()
    c.Lib.Items.FarmKeepDistance:Set(true); c.A:Kite(c.H,c.Root)
    assert(c.A.MoveDirection.X<0); c.A:Render(); assert(c.H.LastMove.X<0); eq(c.H.Relative,false)
    eq(ShiftPresses,1)
    c.Root.Position=Vector3.new(-80,3,0); c.A:Kite(c.H,c.Root)
    eq(c.A.MoveDirection,nil); eq(c.H.LastMove.Magnitude,0); eq(ShiftReleases,1)
end)
test("retreat rejects walls and cliffs, choosing an available side route",function()
    local c=setup(); c.Zombie("A",8,0); c.A:SnapshotZombies()
    c.World.Block=function(_,_,direction) if direction.X < -0.1 then return {Distance=1} end end
    local escape=c.A:ChooseEscape(c.Root,24); assert(escape and escape.X>=-0.01)
    c.World.Block=function() return {Distance=1} end; eq(c.A:ChooseEscape(c.Root,24),nil)
    c.World.Block=nil; c.World.Ray=function() return nil end; eq(c.A:ChooseEscape(c.Root,24),nil)
end)
test("navmesh route follows a corner detour instead of walking through the wall",function()
    local c=setup(); c.Zombie("A",8,0); c.A:SnapshotZombies()
    function c.Paths:CreatePath()
        return {Status="Success",ComputeAsync=function(self,_,to) self.To=to end,
            GetWaypoints=function(self) return {{Position=c.Root.Position},
                {Position=Vector3.new(0,3,7)},{Position=Vector3.new(-10,3,7)},{Position=self.To}} end}
    end
    c.World.Block=function(_,_,d) if d.X < -0.1 and math.abs(d.Z)<1 then return {Distance=1} end end
    c.A:ChooseEscape(c.Root,24); flush()
    local nav=c.A.Navigation; assert(nav.Route and #nav.Route==4)
    local direction=c.A:ChooseEscape(c.Root,24)
    assert(direction.Z>0.9); assert(math.abs(direction.X)<0.01)
end)
test("reset invalidates a pending retreat plan and radius has exit hysteresis",function()
    local c=setup(); local z=c.Zombie("A",8,0); c.A:SnapshotZombies()
    local nav=c.A.Navigation; nav:Update(c.H,c.Root,c.A.Zombies,24)
    assert(nav.Planning); nav:Reset(); flush(); eq(nav.Route,nil)
    nav:Update(c.H,c.Root,c.A.Zombies,24); eq(nav.Active,true)
    z.Head.Position=Vector3.new(27,4.5,0); nav:Update(c.H,c.Root,c.A.Zombies,24); eq(nav.Active,true)
    z.Head.Position=Vector3.new(35,4.5,0); eq(nav:Update(c.H,c.Root,c.A.Zombies,24),nil); eq(nav.Active,false)
end)
test("nearby exits are tried when distant navigation goals are unreachable",function()
    local c=setup(); c.Zombie("A",8,0); c.A:SnapshotZombies(); local tried={}
    function c.Paths:CreatePath()
        return {Status="NoPath",ComputeAsync=function(self,from,to)
            table.insert(tried,(to-from).Magnitude); self.To=to
            if (to-from).Magnitude<14 then self.Status="Success" end
        end,GetWaypoints=function(self) return {{Position=c.Root.Position},{Position=self.To}} end}
    end
    c.A:ChooseEscape(c.Root,37); flush()
    eq(#tried,3); assert(tried[1]>30 and tried[3]<14)
    assert(c.A.Navigation.Route and #c.A.Navigation.Route==2)
end)
test("body steering rejects a cliff in the middle of the segment",function()
    local c=setup(); c.Zombie("A",8,0); c.A:SnapshotZombies()
    c.World.Ray=function(origin,direction)
        if direction.Y< -9 then
            if origin.X < -2 and origin.X > -5 then return nil end
            return {Position=Vector3.new(origin.X,0,origin.Z),Normal=Vector3.new(0,1,0)}
        end
    end
    local d=c.A:ChooseEscape(c.Root,24); assert(d)
    assert(d.X> -0.3 or math.abs(d.Z)>0.7)
end)
test("aim binding runs before native gun and view binding runs after it",function()
    local c=setup(); local priorities={}
    c.Run.BindToRenderStep=function(self,name,priority,fn) priorities[name]=priority; self.Bindings[name]=fn end
    c.Lib.Items.FarmAutoShoot:Set(true)
    eq(priorities.NeoperroAutomationAim,201); eq(priorities.NeoperroAutomation,2001)
    c.Lib.Items.FarmAutoShoot:Set(false); eq(next(c.Run.Bindings),nil)
end)
test("ammo interaction pauses firing but walking to a box can still target heads",function()
    local c=setup(); c.Weapon("Pistol",c.P.Character); c.Zombie("A",8,0)
    c.Lib.Items.FarmAutoShoot:Set(true); c.A:SnapshotZombies()
    c.A.Travelling=true; c.A.TravelPurpose="ammo"; c.A:PreRender(); eq(Presses,1)
    c.Refill.Pending={}; c.A:PreRender(); eq(Releases,1); eq(c.A.Target,nil)
    c.Refill.Pending=nil; c.A.TravelPurpose="shop"; Now=Now+1; c.A:PreRender(); eq(Presses,1)
end)
test("target acquisition sees a newly spawned head before the next slow step",function()
    local c=setup(); c.Weapon("Pistol",c.P.Character); c.Lib.Items.FarmAutoShoot:Set(true)
    c.A:SnapshotZombies(); Now=Now+0.04; local z=c.Zombie("New",8,0)
    c.A:PreRender(); eq(c.A.Target.Model,z.Model); assert(c.A.AimError<0.001)
end)
test("upgrade serializes requests and completion waits for acknowledgement",function()
    local c=setup(); c.Weapon("Pistol"); c.A:ScanInventory(); c.Lib.Items.UpgradeWeapon:Set("Pistol")
    c.Lib.Items.UpgradePriority:Set("AP Rounds")
    c.Lib.Items.UpgradeEnabled:Set(true); c.A:Upgrade(c.H,c.Root)
    eq(c.Shop.Calls,1); eq(c.Guns.Suspended,true)
    local level=c.Shop.Pending.Level; level.Value=level.MaxValue
    Now=Now+2; c.A:Upgrade(c.H,c.Root); eq(c.Shop.Calls,1); eq(c.Lib.Flags.UpgradeEnabled,true)
    c.Shop.Outcome="confirmed"; c.A:Upgrade(c.H,c.Root)
    eq(c.Guns.Suspended,false); eq(c.Lib.Flags.UpgradeEnabled,false)
    eq(c.Notices[#c.Notices],"Selected upgrade fully upgraded")
end)
test("unconfirmed upgrade stops without retry or false completion",function()
    local c=setup(); c.Weapon("Pistol"); c.A:ScanInventory(); c.Lib.Items.UpgradeWeapon:Set("Pistol")
    c.Lib.Items.UpgradePriority:Set("AP Rounds")
    c.Lib.Items.UpgradeEnabled:Set(true); c.A:Upgrade(c.H,c.Root)
    c.Shop.Pending.Level.Value=2; c.Shop.Outcome="timeout"; c.A:Upgrade(c.H,c.Root)
    eq(c.Lib.Flags.UpgradeEnabled,false); eq(c.Guns.Suspended,false)
    c.Lib.Items.UpgradeEnabled:Set(true); Now=Now+10; c.A:Upgrade(c.H,c.Root)
    eq(c.Shop.Calls,1); eq(c.Lib.Flags.UpgradeEnabled,false)
end)
test("shop travel cancels on wave start and rejects stale asynchronous paths",function()
    local c=setup(); c.Weapon("Pistol"); c.A:ScanInventory(); c.Lib.Items.UpgradeWeapon:Set("Pistol")
    c.Lib.Items.UpgradePriority:Set("AP Rounds")
    c.P.InsideShop.Value=false; c.Lib.Items.UpgradeEnabled:Set(true)
    eq(c.A:Upgrade(c.H,c.Root),true); eq(#Tasks,1)
    c.Zombie("A",20,0); c.A:Upgrade(c.H,c.Root); flush()
    eq(c.A.Route,nil); eq(c.A.PathToken,nil); eq(c.Shop.Calls,0)
end)
test("shop travel uses native waypoints and cancellation stops MoveTo and sprint",function()
    local c=setup(); c.A:TravelToShop(c.H,c.Root); flush(); c.A:TravelToShop(c.H,c.Root)
    eq(c.A.Travelling,true); eq(c.H.LastMoveTo.X,30); eq(ShiftPresses,1)
    c.A:CancelTravel(); eq(c.H.LastMoveTo,c.Root.Position); eq(ShiftReleases,1)
end)
test("path service errors clear the pending computation and back off",function()
    local c=setup(); c.Paths.CreatePath=function() error("path unavailable") end
    c.A:TravelToShop(c.H,c.Root); flush()
    eq(c.A.PathComputing,false); eq(c.A.Route,nil); assert(c.A.PathFailedUntil>Now)
    c.A:TravelToShop(c.H,c.Root); eq(#Tasks,0)
end)
test("all-upgrades mode preserves priority and cannot finish while another level remains",function()
    local c=setup(); c.Weapon("Pistol"); c.A:ScanInventory(); c.Lib.Items.UpgradeWeapon:Set("Pistol")
    c.Lib.Items.UpgradePriority:Set("Extended Mags"); c.Lib.Flags.UpgradeMode="All upgrades"
    local list=c.A:OrderedLevels(); eq(list[1].Name,"Extended Mags"); eq(#list,2)
    list[1].Value=list[1].MaxValue
    c.Lib.Items.UpgradeEnabled:Set(true); c.A:Upgrade(c.H,c.Root)
    eq(c.Shop.Calls,1); eq(c.Lib.Flags.UpgradeEnabled,true)
end)
test("disable and unload restore callbacks, camera, visuals and render binding",function()
    local c=setup(); local before=c.A.Callbacks[c.Lib.Items.FarmAutoShoot].Previous
    c.Lib.Items.FarmShowCircle:Set(true); c.Lib.Items.CameraThirdPerson:Set(true)
    c.A:Visuals(c.Root); eq(#c.A.Lines,48); assert(next(c.Run.Bindings))
    c.A:Destroy(); eq(c.Lib.Items.FarmAutoShoot.Callback,before); eq(next(c.Run.Bindings),nil)
    eq(c.A.Lines[1].Removed,true); eq(c.Shop.Alive,false); eq(c.P.CameraMode,"FirstPerson")
    c.A:Destroy()
end)
test("real gun controller suspension restores native values and keeps native upgrade baselines",function()
    local c=setup(); c.A:Destroy(); local t=c.Weapon("Pistol")
    local v=t.CurrentValues
    instance("Spread","NumberValue",v,{Value=2}); instance("SpreadMax","NumberValue",v,{Value=8})
    instance("SpreadIncrease","NumberValue",v,{Value=1})
    local recoil={AddRecoil=function(self) self.Count=(self.Count or 0)+1 end}
    local manager; manager={GetIgnoreList=function(self) eq(self,manager); return {} end}
    local fire=function() end; local up={recoil,manager}
    local env={Range=100}; local refreshed=0
    getsenv=function() return env end
    filtergc=function(_,options)
        if options.Name=="FireWeapon" then return fire end
        if options.Name=="UpdateSpread" then return function() refreshed=refreshed+1 end end
    end
    debug={getinfo=function() return {nups=2} end,getupvalue=function(_,i) return up[i] end,
        setupvalue=function(_,i,x) up[i]=x end}
    c.Lib.Flags.GunRapidFire=true; c.Lib.Flags.GunNoSpread=true; c.Lib.Flags.GunNoRecoil=true
    c.Lib.Flags.GunFireRate=60
    local guns=GunFactory(c.Lib,{SendNotification=function() end})
    eq(v.AttackSpeed.Value,3600); eq(v.Clip.Value,5); eq(v.Ammo.Value,30)
    up[1]:AddRecoil(); eq(recoil.Count,nil)
    guns:SetSuspended(true); eq(v.AttackSpeed.Value,300); eq(v.Spread.Value,2)
    up[1]:AddRecoil(); eq(recoil.Count,1)
    v.AttackSpeed.Value=400; v.Spread.Value=1.5
    guns:SetSuspended(false); eq(v.AttackSpeed.Value,3600)
    c.Input.WindowFocusReleased:Fire(); eq(v.AttackSpeed.Value,400); eq(v.Spread.Value,1.5)
    eq(guns.Heartbeat,nil); eq(up[1],recoil)
    c.Input.WindowFocused:Fire(); eq(v.AttackSpeed.Value,3600)
    guns:Destroy(); eq(v.AttackSpeed.Value,400); eq(v.Spread.Value,1.5); eq(up[1],recoil)
    assert(refreshed>=3)
end)

local function ammoFixture()
    local c=setup(true); local t=c.Weapon("Pistol",c.P.Character)
    instance("Reloading","BoolValue",t,{Value=false}); t.Enabled=true
    instance("MaxAmmo","NumberValue",t.CurrentValues,{Value=100})
    t.CurrentValues.Ammo.Value=10
    local box=instance("AmmoBox","Model",instance("Upgrades","Folder",instance("Map","Folder",c.World)))
    box.PrimaryPart=instance("Handle","Part",box,{Position=Vector3.new(3,3,0)})
    instance("Time","NumberValue",box,{Value=5}); instance("Ammo","NumberValue",box,{Value=500})
    instance("MaxAmmo","NumberValue",box,{Value=500})
    local scripts=instance("PlayerScripts","Folder",c.P)
    local module=instance("MainGui","ModuleScript",instance("GuiManager","Folder",scripts))
    local init=function() end
    local remote=instance("RemoteRefillAmmo","RemoteFunction",c.RS)
    local manager={GetMulti=function() return 2 end}
    local calls=0
    local fn=function()
        calls=calls+1
        c.SeenTime=box.Time.Value
        if c.DestroyDuringNative then c.Ammo:Destroy() end
        if c.Throw then error("refill error") end
        if not c.Reject then t.CurrentValues.Ammo.Value=100 end
    end
    local up={[3]=false,[6]=manager,[7]=remote}
    require=function(m) eq(m,module); return {Init=init} end
    getfenv=function() return {AmmoCrate=fn} end
    debug={getinfo=function() return {nups=11} end,getupvalue=function(_,i) return up[i] end,
        setupvalue=function(_,i,v) up[i]=v end}
    c.Ammo=AmmoFactory(); c.Tool=t; c.Box=box; c.Calls=function() return calls end
    return c
end
test("ammo refill requires nearby stocked box and preserves native timing",function()
    local c=ammoFixture(); eq(c.Ammo:Needs(c.Tool),true)
    eq(c.Ammo:Duration(c.Box,c.Ammo:Context()),0.5)
    c.Root.Position=Vector3.new(30,3,0); eq(c.Ammo:Begin(c.Tool,c.Box,c.Root),false); eq(c.Calls(),0)
    c.Root.Position=Vector3.new(0,3,0); c.Box.Ammo.Value=0
    eq(c.Ammo:Begin(c.Tool,c.Box,c.Root),false); eq(c.Calls(),0)
    c.Box.Ammo.Value=500; assert(c.Ammo:Begin(c.Tool,c.Box,c.Root)); eq(c.Ammo:Poll(),"waiting")
    eq(c.Ammo:Begin(c.Tool,c.Box,c.Root),false); flush(); eq(c.Calls(),1)
    eq(c.Ammo:Poll(),"refilled"); eq(c.Box.Time.Value,5); eq(c.Tool.CurrentValues.Clip.Value,5)
end)
test("rejected native ammo refill reports failure without inventing ammunition",function()
    local c=ammoFixture(); c.Reject=true
    assert(c.Ammo:Begin(c.Tool,c.Box,c.Root)); flush()
    eq(c.Ammo:Poll(),"failed"); eq(c.Tool.CurrentValues.Ammo.Value,10)
    eq(c.Ammo:Begin(c.Tool,c.Box,c.Root),false); eq(c.Box.Time.Value,5)
end)

test("queued native refill cancels before starting when focus is lost",function()
    local c=ammoFixture(); c.Ammo.CanStart=function() return false end
    assert(c.Ammo:Begin(c.Tool,c.Box,c.Root)); flush()
    eq(c.Calls(),0); eq(c.Ammo:Poll(),"failed"); eq(c.Tool.CurrentValues.Ammo.Value,10)
end)

test("reserve thresholds respect native capacity multipliers and exclude unlimited ammo",function()
    local c=ammoFixture(); c.Tool.CurrentValues.Ammo.Value=50
    eq(c.Ammo:Needs(c.Tool,20),false); eq(c.Ammo:Needs(c.Tool,30),true)
    c.Tool.CurrentValues.MaxAmmo.Value=-1; eq(c.Ammo:Needs(c.Tool,90),false)
end)

test("failed refill backs off that box and permits another stocked box",function()
    local c=ammoFixture(); c.Reject=true; assert(c.Ammo:Begin(c.Tool,c.Box,c.Root)); flush()
    eq(c.Ammo:Poll(),"failed"); eq(c.Ammo:Nearest(c.Root),nil)
    Now=Now+9; eq(c.Ammo:Nearest(c.Root),c.Box)
end)

test("refill follows native roof/deployable selection instead of changing an unrelated timer",function()
    local c=ammoFixture(); local roof=instance("RoofAmmo","Model",c.Box.Parent)
    roof.PrimaryPart=instance("Handle","Part",roof,{Position=Vector3.new(2,3,0)})
    for key,value in pairs({Time=5,Ammo=500,MaxAmmo=500}) do instance(key,"NumberValue",roof,{Value=value}) end
    eq(c.Ammo:NativeBox(c.Root),roof); eq(c.Ammo:Begin(c.Tool,c.Box,c.Root),false)
    eq(c.Calls(),0); eq(c.Box.Time.Value,5); assert(c.Ammo:Begin(c.Tool,roof,c.Root))
end)
test("ammo selection respects creator-only deployables and unavailable stock",function()
    local c=ammoFixture(); instance("CreatorOnly","BoolValue",c.Box,{Value=true})
    instance("Creator","ObjectValue",c.Box,{Value={}})
    eq(c.Ammo:Nearest(c.Root),nil)
    c.Box.Creator.Value=c.P; eq(c.Ammo:Nearest(c.Root),c.Box)
    c.Box.Ammo.Value=0; eq(c.Ammo:Nearest(c.Root),nil)
end)

-- Native shop adapter fixture: same row/cash/confirmation contract, no server claims.
local function nativeShop()
    local c=setup(true); c.Weapon("Pistol")
    local scripts=instance("PlayerScripts","Folder",c.P)
    local manager=instance("GuiManager","Folder",scripts)
    local module=instance("ShopGui","ModuleScript",instance("MainGui","Folder",manager))
    local frame=instance("ShopFrame","Frame",c.P.PlayerGui,{Visible=false})
    instance("Upgrade","BoolValue",frame,{Value=true})
    local info=instance("Information","Frame",frame)
    local rows=instance("Upgrades","Frame",instance("UpgradesFrame","Frame",info))
    local update=function() end
    local up={[4]=frame,[5]="PreviousWeapon",[8]=info}
    local nextFn=function() end
    local restockModule=instance("ShopPurchase","ModuleScript",module)
    local map=instance("Map","Folder",c.World)
    local box=instance("AmmoBox","Model",instance("Upgrades","Folder",map))
    instance("Ammo","NumberValue",box,{Value=80}); instance("MaxAmmo","NumberValue",box,{Value=500})
    local wave=instance("LocalWave","IntValue",instance("Values","Folder",c.RS),{Value=2})
    local restockCalls=0
    local utility={GetStructureRepairInfo=function(_,name,cash) eq(name,"AmmoBox"); return 500-box.Ammo.Value,500-box.Ammo.Value end}
    local repair=function(_,name)
        eq(name,"AmmoBox"); restockCalls=restockCalls+1
        box.Ammo.Value=500; c.Cash.Value=c.Cash.Value-420
        if c.RepairThrows then error("native repair failed after sending") end
    end
    local restockRemote=instance("SellRepair","RemoteEvent",c.RS)
    local repairUp={[1]=c.P,[3]=utility,[4]=restockRemote}
    local skipModule=instance("SkipGui","ModuleScript",module.Parent)
    local voted=instance("Voted","BoolValue",c.P,{Value=false})
    local readyCalls=0
    local ready=function() readyCalls=readyCalls+1; if not c.ReadyReject then voted.Value=true end end
    local readyRemote=instance("VoteSkip","RemoteFunction",c.RS)
    local readyUp={[1]=c.P,[2]=false,[5]=readyRemote}
    require=function(m)
        if m==restockModule then return {RepairStructure=repair} end
        if m==skipModule then return {Vote=ready} end
        eq(m,module); return {Next=nextFn}
    end
    getfenv=function(fn) eq(fn,nextFn); return {UpdateUpgrade=update} end
    debug={getinfo=function(fn) return {nups=fn==repair and 5 or fn==ready and 6 or 18} end,
        getupvalue=function(fn,i) if fn==repair then return repairUp[i] end; if fn==ready then return readyUp[i] end; eq(fn,update); return up[i] end,
        setupvalue=function(fn,i,v) eq(fn,update); up[i]=v end}
    getconnections=function(s) return s.listeners end
    local level=c.Levels.Pistol["AP Rounds"]
    local row=instance("AP Rounds Upgrade","TextButton",rows,{Visible=true,MouseButton1Click=signal()})
    instance("Buy","TextLabel",row,{Visible=true,Text="Buy: $100"})
    local clicks=0
    row.MouseButton1Click:Connect(function()
        clicks=clicks+1; level.Value=level.Value+1; c.Cash.Value=c.Cash.Value-100
        if c.Throw then error("callback failed after sending") end
        if c.InstantAck then c.Result.OnClientEvent:Fire("Pistol",false) end
    end)
    local shop=ShopFactory()
    c.Native=shop; c.Row=row; c.Level=level; c.Up=up; c.Frame=frame
    c.Clicks=function() return clicks end
    c.Box=box; c.Wave=wave; c.RepairCalls=function() return restockCalls end
    c.Voted=voted; c.ReadyCalls=function() return readyCalls end
    return c
end

test("native ready is single-flight and never toggles an already-ready vote off",function()
    local c=nativeShop();assert(c.Native:TryReady());eq(c.Native:PollReady(),"waiting")
    eq(c.Native:TryReady(),nil);eq(c.Native:TryPurchase("Pistol",{c.Level}),nil)
    flush();eq(c.ReadyCalls(),1);eq(c.Native:PollReady(),"ready")
    eq(c.Native:TryReady(),nil);eq(c.Voted.Value,true);eq(c.ReadyCalls(),1)
    c.Voted.Value=false;eq(c.Native:TryReady(),nil)
    c.Wave.Value=3;assert(c.Native:TryReady());flush();eq(c.ReadyCalls(),2)
end)

test("intermission follows native Vote state instead of whichever duplicate button is found",function()
    local c=nativeShop();local vote=instance("Vote","BoolValue",c.RS.Values,{Value=true})
    c.P.PlayerGui.VoteSkip.Text="Kills 0";eq(c.Native:BetweenRounds(),true)
    vote.Value=false;c.P.PlayerGui.VoteSkip.Text="Ready";eq(c.Native:BetweenRounds(),false)
end)

test("auto ready waits for purchases, ammo, uncertainty and a settled task interval",function()
    local c=setup();c.Weapon("Pistol",c.P.Character);c.Lib.Flags.FarmAutoReady=true
    c.Shop.Pending={};c.A:AutoReady(c.H);Now=Now+2;c.A:AutoReady(c.H);eq(c.Shop.ReadyCalls,nil)
    c.Shop.Pending=nil;c.A:AutoReady(c.H);Now=Now+1;c.A:AutoReady(c.H);eq(c.Shop.ReadyCalls,nil)
    Now=Now+0.6;c.A:AutoReady(c.H);eq(c.Shop.ReadyCalls,1)
    c.A.UnconfirmedWeapon="Pistol";Now=Now+2;c.A:AutoReady(c.H);eq(c.Shop.ReadyCalls,1)
    c.A.UnconfirmedWeapon=nil;c.Lib.Flags.FarmAutoRefill=true;c.Refill.Needs=function()return true end
    Now=Now+2;c.A:AutoReady(c.H);eq(c.Shop.ReadyCalls,1)
end)

test("native ammo restock shares the purchase lock and attempts only once per round",function()
    local c=nativeShop(); local record=c.Native:TryRestock(20)
    assert(record); eq(c.RepairCalls(),1); eq(c.Box.Ammo.Value,500); eq(c.Cash.Value,580)
    eq(c.Native:TryPurchase("Pistol",{c.Level}),nil); eq(c.Clicks(),0)
    eq(c.Native:PollRestock(),"waiting"); Now=Now+1.1
    eq(c.Native:PollRestock(),"submitted")
    c.Box.Ammo.Value=80; eq(c.Native:TryRestock(20),nil); eq(c.RepairCalls(),1)
    c.Wave.Value=3; assert(c.Native:TryRestock(20)); eq(c.RepairCalls(),2)
end)

test("ammo restock checks stock, shop, round, cash, first night and pending upgrades",function()
    local c=nativeShop()
    c.Box.Ammo.Value=101; eq(c.Native:TryRestock(20),nil)
    c.Box.Ammo.Value=80; c.P.InsideShop.Value=false; eq(c.Native:TryRestock(20),nil)
    c.P.InsideShop.Value=true; c.P.PlayerGui.VoteSkip.Text="Kills 0"; eq(c.Native:TryRestock(20),nil)
    c.P.PlayerGui.VoteSkip.Text="Ready"; c.Cash.Value=10; eq(c.Native:TryRestock(20),nil)
    c.Cash.Value=1000; local first=instance("FirstWave","BoolValue",c.P,{Value=true})
    eq(c.Native:TryRestock(20),nil); first.Value=false
    c.Native.Pending={}; eq(c.Native:TryRestock(20),nil); c.Native.Pending=nil
    c.Frame.Visible=true; eq(c.Native:TryRestock(20),nil); c.Frame.Visible=false
    eq(c.RepairCalls(),0); assert(c.Native:TryRestock(20)); eq(c.RepairCalls(),1)
end)

test("throwing native restock never retries an uncertain transaction in the same round",function()
    local c=nativeShop(); c.RepairThrows=true; assert(c.Native:TryRestock(20))
    Now=Now+1.1; eq(c.Native:PollRestock(),"unconfirmed")
    c.Box.Ammo.Value=80; eq(c.Native:TryRestock(20),nil); eq(c.RepairCalls(),1)
end)
test("native shop cash purchase is single-flight and restores native selection",function()
    local c=nativeShop(); c.InstantAck=true
    local pending=c.Native:TryPurchase("Pistol",{c.Level}); assert(pending)
    eq(c.Clicks(),1); eq(c.Cash.Value,900); eq(c.Up[5],"PreviousWeapon"); eq(c.Frame.Upgrade.Value,true)
    c.Native:TryPurchase("Pistol",{c.Level}); eq(c.Clicks(),1)
    eq(c.Native:Poll(),"confirmed"); eq(c.Native.Pending,nil)
end)
test("native shop refuses locked, unaffordable, premium and visible-menu purchases",function()
    local c=nativeShop()
    for _,text in ipairs({"LOCKED BY AKIMBO","REQUIRES LEVEL 10","Buy: $10,000","100"}) do
        c.Row.Buy.Text=text; eq(c.Native:TryPurchase("Pistol",{c.Level}),nil)
    end
    c.Row.Buy.Text="Buy: $100"; c.Frame.Visible=true
    eq(c.Native:TryPurchase("Pistol",{c.Level}),nil); eq(c.Clicks(),0)
end)
test("native shop timeout and throwing callback do not issue a second request",function()
    local c=nativeShop(); c.Throw=true
    assert(c.Native:TryPurchase("Pistol",{c.Level})); eq(c.Clicks(),1); eq(c.Up[5],"PreviousWeapon")
    eq(c.Native:Poll(),"waiting"); Now=Now+7; eq(c.Native:Poll(),"timeout")
    eq(c.Clicks(),1); eq(c.Cash.Value,900)
end)
test("unrelated and structure refresh events never confirm a gun purchase",function()
    local c=nativeShop(); c.Native:TryPurchase("Pistol",{c.Level})
    c.Result.OnClientEvent:Fire("Sterling",false); c.Result.OnClientEvent:Fire("Pistol",true)
    eq(c.Native:Poll(),"waiting")
    c.Result.OnClientEvent:Fire("Pistol",false); eq(c.Native:Poll(),"confirmed")
    c.Native:Destroy(); eq(c.Native.Confirmation.Enabled,false)
end)
local function visualFixture()
    local c=setup(true)
    Enum.HighlightDepthMode={Occluded="Occluded"}
    Instance={new=function(class) return instance(class,class) end}
    function Methods:Destroy()
        self.Destroyed=true
        if self.Parent then self.Parent:Remove(self) end
        for _,x in ipairs(self:GetChildren()) do x:Destroy() end
    end
    local manager=instance("LocalVisualManager","LocalScript",instance("PlayerScripts","Folder",c.P))
    c.Fire=instance("LocalFireEvent","BindableEvent",manager,{Event=signal()})
    c.Hit=instance("RemoteHitmarker","RemoteEvent",c.RS.RemoteEvents,{OnClientEvent=signal()})
    c.Damage=instance("ReturnServerDamage","RemoteEvent",c.RS.RemoteEvents,{OnClientEvent=signal()})
    c.Wave=instance("LocalWave","IntValue",instance("Values","Folder",c.RS),{Value=2,Changed=signal()})
    for _,key in ipairs({"VisualTracers","VisualHitChams","VisualHitIndicator"}) do
        c.Lib.Flags[key]=true
        local item={Callback=function() end}
        function item:Set(v) c.Lib.Flags[key]=v; self.Callback(v) end
        c.Lib.Items[key]=item
    end
    c.V=VisualFactory(c.Lib,{SendNotification=function(_,m) error(m) end})
    return c
end

test("shot visuals observe local rays while hit indicators require server feedback",function()
    local c=visualFixture(); local t=c.Weapon("Pistol",c.P.Character);local z=c.Zombie("Target",8,0)
    local muzzle=instance("Muzzle","Part",t,{Position=Vector3.new(0,4,0)})
    local rays={{z.Head.Position,z.Head,nil,muzzle.Position}}
    c.Fire.Event:Fire({},t,muzzle,rays); eq(#c.V.Tracers,0)
    c.Fire.Event:Fire(c.P,t,muzzle,rays)
    eq(c.V.LastHit,-10); eq(c.V.RecentDamage,nil)
    eq(#c.V.Tracers,1); assert(c.V.Chams[z.Model])
    c.Hit.OnClientEvent:Fire(); c.Damage.OnClientEvent:Fire(42.5); c.Damage.OnClientEvent:Fire(-5)
    c.Damage.OnClientEvent:Fire(0/0); c.Damage.OnClientEvent:Fire(math.huge)
    eq(c.V.LastHit,Now); eq(c.V.RecentDamage,42.5)
    c.V:Render(); eq(c.V.Panel,nil)
    assert(c.V.DamageText.Visible)
end)

test("tracers and chams remain bounded and expire with elapsed time",function()
    local c=visualFixture()
    for i=1,500 do c.V:AddTracer(Vector3.new(0,4,0),Vector3.new(i,4,10)) end
    eq(#c.V.Tracers,96)
    for i=1,24 do c.V:AddCham(c.Zombie("Z"..i,i,10).Model) end
    local n=0;for _ in pairs(c.V.Chams)do n=n+1 end;eq(n,16)
    Now=Now+1; c.V:Render(); eq(next(c.V.Chams),nil)
    for _,t in ipairs(c.V.Tracers)do eq(t.Active,false); eq(t.Core.Visible,false)end
end)

test("removed round stats stay absent and unload removes every owned effect",function()
    local c=visualFixture(); c.V:OnHit(); c.V:OnDamage(100)
    c.Cash.Value=1500; Now=Now+2; c.Wave.Value=3; c.Wave.Changed:Fire(3)
    eq(c.V.Stats,nil); eq(c.V.Panel,nil); eq(#c.Wave.Changed.listeners,0)
    c.V:AddCham(c.Zombie("Target",8,0).Model);c.V:Render()
    local folder=c.V.Folder; local draws=c.V.Drawings; local callbacks=c.V.Callbacks
    c.V:Destroy();eq(folder.Destroyed,true);eq(c.Run.Bindings.NeoperroHitVisuals,nil)
    for _,d in ipairs(draws)do eq(d.Removed,true)end
    for _,s in ipairs(c.V.Connections)do eq(s.Enabled,false)end
    local last=c.V.LastHit; Now=Now+1; c.Hit.OnClientEvent:Fire();eq(c.V.LastHit,last)
    for item,record in pairs(callbacks)do eq(item.Callback,record.Previous)end
end)

-- Input routing regression: production Library methods, mocked hitboxes only.
local function bindingFixture()
    local e=setmetatable({}, {__index=_G})
    local function item(name,kind) return {Name=name,EnumType=kind} end
    local K,U={},{}; e.Enum={KeyCode=K,UserInputType=U}
    for _,name in ipairs({"Unknown","RightShift","Escape","Backspace","Delete","F7"}) do K[name]=item(name,K) end
    for _,name in ipairs({"MouseButton1","MouseButton2","MouseButton3","Keyboard"}) do U[name]=item(name,U) end
    e.typeof=function(v) return type(v)=="table" and v.EnumType and "EnumItem" or type(v) end
    e.isrbxactive=function() return true end
    e.UserInput={GetFocusedTextBox=function() return nil end}
    e.Library={WindowVisible=true,MenuKey=K.RightShift,Bindings={},Flags={},Keys={Shortened={}},Theme={Text="white",TextInactive="gray",Accent={"red"}}}
    e.Library.ChangeVisible=function(self,v) self.WindowVisible=v end
    e.Toggle={Toggled=true}
    e.Keybind={Key=K.Unknown,EnumType="KeyCode",StateType="Toggle",State=true,Shorten="None",Dropped=false,Binding=false}
    e.Callbacks=0
    e.Keybind.Callback=function(v) e.Callbacks=e.Callbacks+1;e.Toggle.Toggled=v end
    e.Keybind.RemoveFromKeyBindGui=function() end
    e.Options={Flag="Test_Bind",Title="Test"}
    e.Window={BindList="",RefreshBinds=function() end}
    e.Window.ClosePopups=function() e.Keybind.Dropped=false end
    e.Keybind.Drop=function(self,v) self.Dropped=v end
    e.Utility={OnMouse=function(o) return o==e.MouseTarget end}
    e.Tab={Dropdowns={Left={},Right={}}}; e.ToggleTitle={Text="Test"}
    for _,name in ipairs({"ToggleHitbox","KeybindInline","KeybindHoldInline","KeybindToggleInline","KeybindAlwaysInline","KeybindNoneInline","KeybindHoldValue","KeybindToggleValue","KeybindAlwaysValue","KeybindValue"}) do e[name]={} end
    e.Library.Bindings={e.Keybind}
    LoadUIInput(e)
    function e:Input(kind,key) return {UserInputType=U[kind],KeyCode=K[key or "Unknown"]} end
    function e:Dispatch(input)
        if not self.Library.HandleMenuInput(input) then self.Keybind:HandleShortcut(input) end
    end
    return e
end

test("None cannot match mouse Unknown codes or keyboard input",function()
    local e=bindingFixture();e.Library.WindowVisible=false
    for _,kind in ipairs({"MouseButton1","MouseButton2","MouseButton3","Keyboard"})do e:Dispatch(e:Input(kind)) end
    e:Dispatch(e:Input("Keyboard","F7"));eq(e.Callbacks,0);eq(e.Toggle.Toggled,true)
end)
test("right click opens bind popup without changing key mode or feature",function()
    local e=bindingFixture();e.Keybind.Key=e.Enum.UserInputType.MouseButton2;e.Keybind.EnumType="UserInputType"
    e.MouseTarget=e.ToggleHitbox;e:Dispatch(e:Input("MouseButton2"))
    eq(e.Keybind.Dropped,true);eq(e.Callbacks,0);eq(e.Keybind.Key,e.Enum.UserInputType.MouseButton2);eq(e.Keybind.StateType,"Toggle")
end)
test("right click on popup options does not select them",function()
    local e=bindingFixture();e.Keybind.Dropped=true;e.MouseTarget=e.KeybindHoldInline
    e:Dispatch(e:Input("MouseButton2"));eq(e.Callbacks,0);eq(e.Keybind.StateType,"Toggle");eq(e.Keybind.Dropped,false)
end)
test("Set key click starts capture and only the following input assigns a key",function()
    local e=bindingFixture();e.Keybind.Dropped=true;e.MouseTarget=e.KeybindAlwaysInline
    e:Dispatch(e:Input("MouseButton1"));eq(e.Keybind.Binding,true);eq(e.Keybind.Key,e.Enum.KeyCode.Unknown)
    e:Dispatch(e:Input("Keyboard","F7"));eq(e.Keybind.Key,e.Enum.KeyCode.F7);eq(e.Keybind.Binding,false);eq(e.Toggle.Toggled,true)
end)
test("None explicitly clears a Hold binding without changing the checkbox",function()
    local e=bindingFixture();e.Keybind.Key=e.Enum.KeyCode.F7;e.Keybind.StateType="Hold";e.Keybind.Dropped=true
    e.MouseTarget=e.KeybindNoneInline;e:Dispatch(e:Input("MouseButton1"))
    eq(e.Keybind.Key,e.Enum.KeyCode.Unknown);eq(e.Keybind.StateType,"Toggle");eq(e.KeybindValue.Text,"None");eq(e.Toggle.Toggled,true)
    e.Library.WindowVisible=false;e:Dispatch(e:Input("MouseButton2"));eq(e.Toggle.Toggled,true)
end)
test("intentional mouse binds work only with the menu hidden",function()
    local e=bindingFixture();e.Keybind:Set(e.Enum.UserInputType.MouseButton2,"Toggle");e.Callbacks=0
    e:Dispatch(e:Input("MouseButton2"));eq(e.Callbacks,0)
    e.Library.WindowVisible=false;e:Dispatch(e:Input("MouseButton2"));eq(e.Callbacks,1);eq(e.Toggle.Toggled,false)
end)
test("Escape cancels capture and menu key cannot be accidentally assigned",function()
    local e=bindingFixture();e.Keybind.Binding=true
    e:Dispatch(e:Input("Keyboard","RightShift"));eq(e.Keybind.Binding,true);eq(e.Library.WindowVisible,true)
    e:Dispatch(e:Input("Keyboard","Escape"));eq(e.Keybind.Binding,false);eq(e.Keybind.Key,e.Enum.KeyCode.Unknown);eq(e.Callbacks,0)
end)

print(string.format("%d passed, %d failed",passed,failed))
assert(failed==0,"Offline behavioral tests failed")
