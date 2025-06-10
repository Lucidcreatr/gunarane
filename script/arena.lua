--!strict
-- LCX Gunfight Arena Cheat GUI (Rayfield)
-- Game: https://www.roblox.com/games/14518422161
-- Features: Aim Assist • Big Hitbox • Speed • BunnyHop • ESP • WallHack
-- DISCLAIMER: This violates Roblox TOS and is for educational purposes only.

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
    LoadingSubtitle = "By Lucid",
    Theme = "Serenity",
    DisableBuildWarnings = true
})

local MainTab   = Window:CreateTab("ESP",   nil)
local AimTab    = Window:CreateTab("Aim",   nil)
local PlayerTab = Window:CreateTab("Player", nil)

for _,t in ipairs({MainTab,AimTab,PlayerTab}) do t:CreateSection("Main") end

---------------------------------------------------------------------
-- SERVICES / LOCALS ------------------------------------------------
---------------------------------------------------------------------
local Players, RS, UIS = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP      = Players.LocalPlayer
local Char    = LP.Character or LP.CharacterAdded:Wait()
local Hum     = Char:WaitForChild("Humanoid")
local Root    = Char:WaitForChild("HumanoidRootPart")

---------------------------------------------------------------------
-- STATE ------------------------------------------------------------
---------------------------------------------------------------------
local state = {esp=false,wall=false,bhop=false,speed=false,fly=false,aim=false,hitbox=false}
local conns = {}
local espBoxes, highlights, headSizes = {}, {}, {}
local speedNormal = Hum.WalkSpeed

local function isEnemy(pl:Player) return pl.Team ~= LP.Team end
local function getHead(c) return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart") end

---------------------------------------------------------------------
-- ESP --------------------------------------------------------------
---------------------------------------------------------------------
local function makeESP(char:Model)
    if espBoxes[char] then return end
    local box = Drawing.new("Square"); box.Color=Color3.new(1,0,0); box.Thickness=2; box.Filled=false
    espBoxes[char]=box
    conns["esp"..char:GetDebugId()] = RS.RenderStepped:Connect(function()
        if not state.esp or not char or not char:FindFirstChild("HumanoidRootPart") or not isEnemy(Players:GetPlayerFromCharacter(char)) then box.Visible=false return end
        local pos,vis = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
        if vis then local size=2000/pos.Z; box.Size=Vector2.new(size,size); box.Position=Vector2.new(pos.X-size/2,pos.Y-size/2); box.Visible=true else box.Visible=false end
    end)
end
local function clearESP(char:Model)
    if espBoxes[char] then espBoxes[char]:Remove(); espBoxes[char]=nil end
    local id="esp"..char:GetDebugId(); if conns[id] then conns[id]:Disconnect(); conns[id]=nil end
end

local function toggleESP(v)
    state.esp=v
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then if v then makeESP(p.Character or p.CharacterAdded:Wait()) else clearESP(p.Character or p.CharacterAdded:Wait()) end end end
end

---------------------------------------------------------------------
-- WALLHACK ---------------------------------------------------------
---------------------------------------------------------------------
local function makeHL(char:Model)
    if highlights[char] then return end
    local hl = Instance.new("Highlight", game.CoreGui)
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency=1; hl.OutlineColor=Color3.fromRGB(0,255,0)
    hl.Adornee=char; highlights[char]=hl
end
local function clearHL(char:Model) if highlights[char] then highlights[char]:Destroy(); highlights[char]=nil end end
local function toggleWall(v)
    state.wall=v
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then if v then makeHL(p.Character or p.CharacterAdded:Wait()) else clearHL(p.Character or p.CharacterAdded:Wait()) end end end
end

---------------------------------------------------------------------
-- HITBOX -----------------------------------------------------------
---------------------------------------------------------------------
local function resizeHead(char,on)
    local h=getHead(char) if not h then return end
    if on then if not headSizes[h] then headSizes[h]=h.Size; h.Size=h.Size*3 end else if headSizes[h] then h.Size=headSizes[h]; headSizes[h]=nil end end
end
local function toggleHitbox(v)
    state.hitbox=v
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then resizeHead(p.Character or p.CharacterAdded:Wait(),v) end end
end

---------------------------------------------------------------------
-- BUNNYHOP ---------------------------------------------------------
---------------------------------------------------------------------
local function toggleBH(v)
    state.bhop=v
    if v then conns.bhop=RS.Heartbeat:Connect(function() if Hum.FloorMaterial~=Enum.Material.Air then Hum.Jump=true end end) else if conns.bhop then conns.bhop:Disconnect(); conns.bhop=nil end end
end

---------------------------------------------------------------------
-- SPEED ------------------------------------------------------------
---------------------------------------------------------------------
local function toggleSpeed(v)
    state.speed=v; Hum.WalkSpeed=v and speedNormal*1.8 or speedNormal
end

---------------------------------------------------------------------
-- AIM ASSIST -------------------------------------------------------
---------------------------------------------------------------------
local function closest(max)
    local t,d=nil,max
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and isEnemy(pl) and pl.Character then local h=getHead(pl.Character) if h then local pos,vis=Camera:WorldToViewportPoint(h.Position) if vis then local m=(Vector2.new(pos.X,pos.Y)-Vector2.new(UIS:GetMouseLocation().X,UIS:GetMouseLocation().Y)).Magnitude if m<d then d,t=m,h end end end end end return t end
UIS.InputBegan:Connect(function(i,gp) if gp or i.KeyCode~=Enum.KeyCode.E or not state.aim then return end local t=closest(180) if t then Camera.CFrame=CFrame.new(Camera.CFrame.Position,t.Position) end end)
local function toggleAim(v) state.aim=v end

---------------------------------------------------------------------
-- PLAYER JOIN/LEAVE -----------------------------------------------
---------------------------------------------------------------------
local function hookPlayer(pl)
    if pl==LP then return end
    local function onChar(c)
        if state.esp then makeESP(c) end
        if state.wall then makeHL(c) end
        if state.hitbox then resizeHead(c,true) end
    end
    if pl.Character then onChar(pl.Character) end
    pl.CharacterAdded:Connect(onChar)
end
for _,p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(p) if p.Character then clearESP(p.Character); clearHL(p.Character); resizeHead(p.Character,false) end end)

---------------------------------------------------------------------
-- UI ELEMENTS ------------------------------------------------------
---------------------------------------------------------------------
MainTab:CreateToggle({Name="ESP",CurrentValue=false,Callback=toggleESP})
MainTab:CreateToggle({Name="WallHack",CurrentValue=false,Callback=toggleWall})

AimTab:CreateToggle({Name="Aim Assist (E)",CurrentValue=false,Callback=toggleAim})
AimTab:CreateToggle({Name="Big Hitbox",CurrentValue=false,Callback=toggleHitbox})

PlayerTab:CreateToggle({Name="Bunny Hop",CurrentValue=false,Callback=toggleBH})
PlayerTab:CreateToggle({Name="Speed x1.8",CurrentValue=false,Callback=toggleSpeed})

---------------------------------------------------------------------
-- DONE -------------------------------------------------------------
---------------------------------------------------------------------
Rayfield:Notify({Title="LCX",Content="Gunfight Arena GUI yüklendi!",Duration=4})
