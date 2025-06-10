--!strict
-- LCX Gunfight Arena Advanced Cheat GUI (Rayfield)
-- Game: https://www.roblox.com/games/14518422161
-- Features: Aim Assist (Auto / Legit / Spin) • Adjustable Hitbox • Adjustable Speed • BunnyHop • ESP (Color Picker) • WallHack • Fly
-- DISCLAIMER: Breaking Roblox TOS. Educational purposes only.

if game.PlaceId ~= 14518422161 then return end

---------------------------------------------------------------------
-- LOAD RAYFIELD ----------------------------------------------------
---------------------------------------------------------------------
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then warn("Rayfield yüklenemedi: "..tostring(Rayfield)); return end

---------------------------------------------------------------------
-- WINDOW -----------------------------------------------------------
---------------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "LCX | Gunfight Arena",
    LoadingTitle = "LCX Loader",
    LoadingSubtitle = "by LCX Team",
    Theme = "Serenity",
    DisableBuildWarnings = true
})

local Tabs = {
    ESP    = Window:CreateTab("ESP", nil),
    Aim    = Window:CreateTab("Aim", nil),
    Player = Window:CreateTab("Player", nil),
    Misc   = Window:CreateTab("Misc", nil)
}
for _,t in pairs(Tabs) do t:CreateSection("Main") end

---------------------------------------------------------------------
-- SERVICES ---------------------------------------------------------
---------------------------------------------------------------------
local Players, RS, UIS = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local Hum  = Char:WaitForChild("Humanoid")
local Root = Char:WaitForChild("HumanoidRootPart")

---------------------------------------------------------------------
-- STATE ------------------------------------------------------------
---------------------------------------------------------------------
local state = {
    esp           = false,
    wall          = false,
    bhop          = false,
    speed         = false,
    fly           = false,
    aim           = false,
    aimMode       = "Auto", -- Auto / Legit / Spin
    speedMult     = 1.8,
    hitboxSize    = 3,
    espColor      = Color3.new(1,0,0)
}

local conns = {}
local espBoxes   : {[Model]:Drawing} = {}
local highlights : {[Model]:Highlight} = {}
local originalHead : {[BasePart]:Vector3} = {}
local baseSpeed = Hum.WalkSpeed

---------------------------------------------------------------------
-- HELPERS ----------------------------------------------------------
---------------------------------------------------------------------
local function isEnemy(pl: Player)
    if not LP.Team or not pl.Team then return pl~=LP end -- fallback
    return pl.Team ~= LP.Team
end

local function headOf(model:Model):BasePart?
    return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- ESP --------------------------------------------------------------
---------------------------------------------------------------------
local function newBox(char:Model)
    if espBoxes[char] then return end
    local box = Drawing.new("Square")
    box.Thickness = 2; box.Filled=false; box.Color = state.espColor
    espBoxes[char] = box
    conns["esp_"..char:GetDebugId()] = RS.RenderStepped:Connect(function()
        if not state.esp or not char.Parent or not char:FindFirstChild("HumanoidRootPart") or not isEnemy(Players:GetPlayerFromCharacter(char)) then box.Visible=false return end
        local vec,vis = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
        if vis then local sz=2000/vec.Z; box.Size=Vector2.new(sz,sz); box.Position=Vector2.new(vec.X-sz/2,vec.Y-sz/2); box.Color=state.espColor; box.Visible=true else box.Visible=false end
    end)
end
local function destroyBox(char:Model)
    if espBoxes[char] then espBoxes[char]:Remove(); espBoxes[char]=nil end
    local id="esp_"..char:GetDebugId(); if conns[id] then conns[id]:Disconnect(); conns[id]=nil end
end
local function setESP(on:boolean)
    state.esp=on
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then
        if on then if p.Character then newBox(p.Character) end else if p.Character then destroyBox(p.Character) end end
    end end
end

---------------------------------------------------------------------
-- WALLHACK ---------------------------------------------------------
---------------------------------------------------------------------
local function newHL(char:Model)
    if highlights[char] then return end
    local hl=Instance.new("Highlight", game.CoreGui); hl.FillTransparency=0.7; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.OutlineColor=Color3.fromRGB(0,255,0); hl.Adornee=char
    highlights[char]=hl
end
local function destroyHL(char:Model) if highlights[char] then highlights[char]:Destroy(); highlights[char]=nil end end
local function setWall(on:boolean)
    state.wall=on
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then if on then if p.Character then newHL(p.Character) end else if p.Character then destroyHL(p.Character) end end end end
end

---------------------------------------------------------------------
-- HITBOX -----------------------------------------------------------
---------------------------------------------------------------------
local function applyHitbox(char:Model)
    local head=headOf(char) if not head then return end
    if not originalHead[head] then originalHead[head]=head.Size end
    head.Size = Vector3.new(state.hitboxSize, state.hitboxSize, state.hitboxSize)
end
local function restoreHitbox(char:Model)
    local head=headOf(char) if head and originalHead[head] then head.Size=originalHead[head]; originalHead[head]=nil end
end
local function setHitbox(on:boolean)
    state.hitbox=on
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then if on then applyHitbox(p.Character) else restoreHitbox(p.Character) end end end
end

---------------------------------------------------------------------
-- BUNNY HOP --------------------------------------------------------
---------------------------------------------------------------------
local function setBHop(on:boolean)
    state.bhop=on
    if on and not conns.bhop then conns.bhop=RS.Heartbeat:Connect(function() if Hum.FloorMaterial~=Enum.Material.Air then Hum.Jump=true end end)
    elseif not on and conns.bhop then conns.bhop:Disconnect(); conns.bhop=nil end
end

---------------------------------------------------------------------
-- SPEED ------------------------------------------------------------
---------------------------------------------------------------------
local function setSpeed(on:boolean)
    state.speed=on
    Hum.WalkSpeed = on and baseSpeed*state.speedMult or baseSpeed
end
local function updateSpeedMult(v:number)
    state.speedMult=v
    if state.speed then Hum.WalkSpeed=baseSpeed*v end
end

---------------------------------------------------------------------
-- FLY --------------------------------------------------------------
---------------------------------------------------------------------
local flyBV:BodyVelocity?; local flyBG:BodyGyro?
local function setFly(on:boolean)
    state.fly=on
    if on then
        flyBG=Instance.new("BodyGyro",Root); flyBG.MaxTorque=Vector3.new(9e9,9e9,9e9); flyBG.P=9e4
        flyBV=Instance.new("BodyVelocity",Root); flyBV.MaxForce=Vector3.new(9e9,9e9,9e9)
        conns.fly=RS.RenderStepped:Connect(function()
            flyBG.CFrame=Camera.CFrame
            local dir=Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
            flyBV.Velocity = dir.Magnitude>0 and dir.Unit*60 or Vector3.zero
        end)
    else
        if conns.fly then conns.fly:Disconnect(); conns.fly=nil end
        if flyBG then flyBG:Destroy(); flyBG=nil end
        if flyBV then flyBV:Destroy(); flyBV=nil end
    end
end

---------------------------------------------------------------------
-- AIM ASSIST -------------------------------------------------------
---------------------------------------------------------------------
local function closestTarget(fov:number):BasePart?
    local best=nil; local bestDist=fov
    local mousePos=UIS:GetMouseLocation()
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and isEnemy(pl) and pl.Character then local head=headOf(pl.Character) if head then local pos,vis=Camera:WorldToViewportPoint(head.Position) if vis then local d=(Vector2.new(pos.X,pos.Y)-Vector2.new(mousePos.X,mousePos.Y)).Magnitude if d<bestDist then bestDist=d; best=head end end end end end return best end

local spinAngle=0
local function setAim(on:boolean) state.aim=on end
conns.aimLoop=RS.RenderStepped:Connect(function()
    if not state.aim then return end
    if state.aimMode=="Auto" then
        local target=closestTarget(200); if target then Camera.CFrame=CFrame.new(Camera.CFrame.Position,target.Position) end
    elseif state.aimMode=="Legit" then
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local tgt=closestTarget(200); if tgt then local newLook=Camera.CFrame.LookVector:Lerp((tgt.Position-Camera.CFrame.Position).Unit,0.15); Camera.CFrame=CFrame.new(Camera.CFrame.Position,Camera.CFrame.Position+newLook) end
        end
    elseif state.aimMode=="Spin" then
        spinAngle=(spinAngle+math.rad(6))%(math.pi*2)
        local dir=Vector3.new(math.cos(spinAngle),0,math.sin(spinAngle))
        Camera.CFrame=CFrame.new(Camera.CFrame.Position,Camera.CFrame.Position+dir)
    end
end)

---------------------------------------------------------------------
-- PLAYER HANDLERS --------------------------------------------------
---------------------------------------------------------------------
local function handleChar(char:Model)
    if state.esp then newBox(char) end
    if state.wall then newHL(char) end
    if state.hitbox then applyHitbox(char) end
end
local function hookPlayer(pl:Player)
    if pl==LP then return end
    if pl.Character then handleChar(pl.Character) end
    pl.CharacterAdded:Connect(handleChar)
    pl.CharacterRemoving:Connect(function(c)
        destroyBox(c); destroyHL(c); restoreHitbox(c)
    end)
end
for _,p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)

---------------------------------------------------------------------
-- UI ELEMENTS ------------------------------------------------------
---------------------------------------------------------------------
MainTab:CreateToggle({Name="ESP",CurrentValue=false,Callback=setESP})
MainTab:CreateColorPicker({Name="ESP Color",CurrentValue=state.espColor,Callback=updateESPColor})
MainTab:CreateToggle({Name="WallHack",CurrentValue=false,Callback=setWall})

AimTab:CreateToggle({Name="Aim Assist",CurrentValue=false,Callback=setAim})
AimTab:CreateDropdown({Name="Aim Mode",Options={"Auto","Legit","Spin"},CurrentValue="Auto",Callback=function(v) state.aimMode=v end})
AimTab:CreateToggle({Name="Big Hitbox",CurrentValue=false,Callback=setHitbox})
AimTab:CreateSlider({Name="Hitbox Size",Range={3,10},Increment=1,CurrentValue=state.hitboxSize,Callback=function(v) state.hitboxSize=v; if state.hitbox then setHitbox(true) end end})

PlayerTab:CreateToggle({Name="BunnyHop",CurrentValue=false,Callback=setBHop})
PlayerTab:CreateToggle({Name="Speed",CurrentValue=false,Callback=setSpeed})
PlayerTab:CreateSlider({Name="Speed Mult",Range={1.2,3},Increment=0.1,CurrentValue=state.speedMult,Callback=updateSpeedMult})
PlayerTab:CreateToggle({Name="Fly",CurrentValue=false,Callback=setFly})

MiscTab:CreateButton({Name="Unload",Callback=function() Window:Destroy(); for _,c in pairs(conns) do c:Disconnect() end for char,box in pairs(espBoxes) do box:Remove() end for _,hl in pairs(highlights) do hl:Destroy() end end})

---------------------------------------------------------------------
-- CHARACTER REFRESH -----------------------------------------------
---------------------------------------------------------------------
LP.CharacterAdded:Connect(function(c) Char=c; Hum=c:WaitForChild("Humanoid"); Root=c:WaitForChild("HumanoidRootPart"); baseSpeed=Hum.WalkSpeed end)

Rayfield:Notify({Title="LCX",Content="GUI yüklendi",Duration=4})
