-- State-machine tests of the actual factories; this is not a Roblox/server simulator.
local AutoFactory = LoadSource("Automation")
local ShopFactory = LoadSource("ShopAdapter")
local GunFactory = LoadSource("Features")
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
function V:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
Vector3 = {new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},V) end}
Vector3.zero=Vector3.new(0,0,0)
Vector2={new=function(x,y) return {X=x,Y=y} end}
CFrame={new=function(p) return {Position=p or Vector3.zero} end,
    lookAt=function(p,t) return {Position=p,Target=t} end}
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
typeof=function(x) return getmetatable(x)==Obj and "Instance" or type(x) end
Enum={KeyCode={LeftShift="LShift",RightShift="RShift"}, UserInputType={MouseButton1="M1"},
    RaycastFilterType={Exclude="Exclude"}, MouseBehavior={LockCenter="Center"},
    CameraMode={Classic="Classic"},RenderPriority={Last={Value=2000}},PathStatus={Success="Success"},
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
        PathfindingService=paths,ReplicatedStorage=rs}
    game={GetService=function(_,name) return assert(services[name],name) end}; workspace=world
    local flags={UpgradeWeapon="Select weapon",UpgradePriority="Select upgrade",UpgradeMode="Selected upgrade only",
        FarmDistance=24,FarmAvoidWalls=true,FarmUseSprint=true,CameraDistance=10,UpgradeNotify=true,UpgradeShopFallback=true}
    local lib={Flags=flags,Items={},WindowVisible=false}
    local keys={"UpgradeWeapon","UpgradePriority","UpgradeMode","UpgradeEnabled","UpgradeShopFallback","FarmAutoShoot",
        "FarmKeepDistance","FarmUseSprint","FarmShowDistance","FarmShowCircle","CameraThirdPerson","CameraDistance"}
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
    function shop:Destroy() self.Alive=false end
    local c={P=p,H=h,Root=root,Bag=bag,Backgear=backgear,Levels=levels,World=world,Run=run,Input=input,RS=rs,
        Result=result,Cash=cash,Lib=lib,Guns=guns,Shop=shop,Weapon=weapon,Zombie=zombie,Notices=notices,Paths=paths}
    if native then return c end
    c.A=AutoFactory(lib,win,guns,function() return shop end)
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
test("render aims at the head before native press and releases on death/menu/focus",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); local z=c.Zombie("A",8,0)
    c.Guns:BindWeapon(t); c.Lib.Items.FarmAutoShoot:Set(true); c.A:SnapshotZombies()
    c.A:Render(); eq(Presses,0); eq(c.World.CurrentCamera.CFrame.Target,z.Head.Position)
    c.A:Render(); eq(Presses,1); eq(c.Input.MouseBehavior,"Center")
    c.Lib.WindowVisible=true; c.A:Render(); eq(Releases,1); eq(c.Input.MouseBehavior,"Default")
    c.Lib.WindowVisible=false; Now=Now+1; c.A:Render(); c.A:Render(); eq(Presses,2)
    Active=false; c.Input.WindowFocusReleased:Fire(); eq(Releases,1)
    Active=true; c.Input.WindowFocused:Fire(); eq(Releases,2)
    z.Humanoid.Health=0; c.A:Render(); eq(c.A.Target,nil)
end)
test("manual mouse is not owned and unload completes an unfocused owned release",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); c.Zombie("A",8,0)
    c.Guns:BindWeapon(t); c.Lib.Items.FarmAutoShoot:Set(true); c.A:SnapshotZombies()
    c.Input.PhysicalMouse=true; c.A:Render(); c.A:Render(); eq(Presses,0)
    c.Input.PhysicalMouse=false; c.A:Render(); eq(Presses,1)
    Active=false; c.A:Destroy(); Active=true; c.Input.WindowFocused:Fire(); eq(Releases,1)
end)
test("empty clips use native reload once, charge guns fail closed",function()
    local c=setup(); local t=c.Weapon("Pistol",c.P.Character); local z=c.Zombie("A",8,0)
    c.A.Target=z; c.Lib.Flags.FarmAutoShoot=true; t.CurrentValues.Clip.Value=0
    c.Guns:BindWeapon(t); c.A:Shoot(t); c.A:Shoot(t); eq(#Tasks,1); flush(); eq(c.Guns.Reloaded,true)
    t.CurrentValues.Clip.Value=5; t.CurrentValues.FireType.Value="Charge"; c.A:Shoot(t); eq(Presses,0)
end)
test("third person clips camera and restores all native camera settings",function()
    local c=setup(); local z=c.Zombie("A",10,0)
    c.Lib.Items.CameraThirdPerson:Set(true); eq(c.P.CameraMode,"Classic"); eq(c.P.CameraMinZoomDistance,10)
    c.World.Ray=function() return {Position=Vector3.new(-2,4,0),Normal=Vector3.new(1,0,0)} end
    c.A:Aim(c.World.CurrentCamera,c.Root,z); eq(c.World.CurrentCamera.CFrame.Position.X,-1.6)
    eq(c.World.CurrentCamera.CFrame.Target,z.Head.Position)
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
    guns:Destroy(); eq(v.AttackSpeed.Value,400); eq(v.Spread.Value,1.5); eq(up[1],recoil)
    assert(refreshed>=3)
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
    require=function(m) eq(m,module); return {Next=nextFn} end
    getfenv=function(fn) eq(fn,nextFn); return {UpdateUpgrade=update} end
    debug={getinfo=function() return {nups=18} end,
        getupvalue=function(fn,i) eq(fn,update); return up[i] end,
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
    return c
end
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
print(string.format("%d passed, %d failed",passed,failed))
assert(failed==0,"Offline behavioral tests failed")
