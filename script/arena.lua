--!strict
-- LCX Gunfight Arena Advanced Cheat GUI (Rayfield)
-- Game: https://www.roblox.com/games/14518422161
-- Features: Aim Assist (Auto, Legit, Spin) • Adjustable Hitbox • Adjustable Speed • BunnyHop • ESP (Color Picker) • WallHack (Fix) • Fly
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
    Name = "LCX | Gunfight Arena Advanced",
    LoadingTitle = "LCX Loader",
    LoadingSubtitle = "by Lucid",
    Theme = "Serenity",
    DisableBuildWarnings = true
})

local MainTab   = Window:CreateTab("ESP",   nil)
local AimTab    = Window:CreateTab("Aim",   nil)
local PlayerTab = Window:CreateTab("Player", nil)
local MiscTab   = Window:CreateTab("Misc",  nil)

for _,t in ipairs({MainTab,AimTab,PlayerTab,MiscTab}) do t:CreateSection("Main") end

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
local state = {
    esp = false,
    wall = false,
    bhop = false,
    speed = false,
    fly = false,
    aim = false,
    hitbox = false,
    aimMode = "Auto", -- Auto, Legit, Spin
    hitboxSize = 3,
    speedMultiplier = 1.8,
    espColor = Color3.new(1, 0, 0)
}

local conns = {}
local espBoxes, highlights, headSizes = {}, {}, {}

local speedNormal = Hum.WalkSpeed

local function isEnemy(pl: Player)
    return pl.Team ~= LP.Team
end

local function getHead(c)
    return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- ESP --------------------------------------------------------------
---------------------------------------------------------------------
local function makeESP(char: Model)
    if espBoxes[char] then return end
    local box = Drawing.new("Square")
    box.Color = state.espColor
    box.Thickness = 2
    box.Filled = false
    espBoxes[char] = box

    conns["esp" .. char:GetDebugId()] = RS.RenderStepped:Connect(function()
        if not state.esp or not char or not char:FindFirstChild("HumanoidRootPart") or not isEnemy(Players:GetPlayerFromCharacter(char)) then
            box.Visible = false
            return
        end
        local pos, vis = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
        if vis then
            local size = 2000 / pos.Z
            box.Size = Vector2.new(size, size)
            box.Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
            box.Color = state.espColor
            box.Visible = true
        else
            box.Visible = false
        end
    end)
end

local function clearESP(char: Model)
    if espBoxes[char] then
        espBoxes[char]:Remove()
        espBoxes[char] = nil
    end
    local id = "esp" .. char:GetDebugId()
    if conns[id] then
        conns[id]:Disconnect()
        conns[id] = nil
    end
end

local function toggleESP(v)
    state.esp = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if v then
                if p.Character then makeESP(p.Character) end
            else
                if p.Character then clearESP(p.Character) end
            end
        end
    end
end

local function updateESPColor(color: Color3)
    state.espColor = color
    for char, box in pairs(espBoxes) do
        box.Color = color
    end
end

---------------------------------------------------------------------
-- WALLHACK ---------------------------------------------------------
---------------------------------------------------------------------
local function makeHL(char: Model)
    if highlights[char] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "LCXWallhackHL"
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.7
    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
    hl.Adornee = char
    hl.Parent = game.CoreGui
    highlights[char] = hl
end

local function clearHL(char: Model)
    if highlights[char] then
        highlights[char]:Destroy()
        highlights[char] = nil
    end
end

local function toggleWall(v)
    state.wall = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if v then
                if p.Character then makeHL(p.Character) end
            else
                if p.Character then clearHL(p.Character) end
            end
        end
    end
end

---------------------------------------------------------------------
-- HITBOX -----------------------------------------------------------
---------------------------------------------------------------------
local function resizeHead(char: Model, on: boolean)
    local h = getHead(char)
    if not h then return end
    if on then
        h.Size = Vector3.new(state.hitboxSize, state.hitboxSize, state.hitboxSize)
    else
        if headSizes[h] then
            h.Size = headSizes[h]
            headSizes[h] = nil
        else
            h.Size = Vector3.new(10, 10, 10)
        end
    end
end

local function toggleHitbox(v)
    state.hitbox = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Character then resizeHead(p.Character, v) end
        end
    end
end

---------------------------------------------------------------------
-- BUNNYHOP ---------------------------------------------------------
---------------------------------------------------------------------
local function toggleBH(v)
    state.bhop = v
    if v then
        conns.bhop = RS.Heartbeat:Connect(function()
            if Hum.FloorMaterial ~= Enum.Material.Air then
                Hum.Jump = true
            end
        end)
    else
        if conns.bhop then
            conns.bhop:Disconnect()
            conns.bhop = nil
        end
    end
end

---------------------------------------------------------------------
-- SPEED ------------------------------------------------------------
---------------------------------------------------------------------
local function toggleSpeed(v)
    state.speed = v
    Hum.WalkSpeed = v and speedNormal * state.speedMultiplier or speedNormal
end

local function setSpeedMultiplier(mult)
    state.speedMultiplier = mult
    if state.speed then
        Hum.WalkSpeed = speedNormal * mult
    end
end

---------------------------------------------------------------------
-- FLY --------------------------------------------------------------
---------------------------------------------------------------------
local flying = false
local bodyGyro, bodyVelocity

local function toggleFly(v)
    state.fly = v
    local root = Root
    if v then
        flying = true
        bodyGyro = Instance.new("BodyGyro", root)
        bodyGyro.P = 9e4
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = root.CFrame

        bodyVelocity = Instance.new("BodyVelocity", root)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        RS:BindToRenderStep("Fly", 1, function()
            local moveVec = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then
                moveVec = moveVec + workspace.CurrentCamera.CFrame.LookVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.S) then
                moveVec = moveVec - workspace.CurrentCamera.CFrame.LookVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.A) then
                moveVec = moveVec - workspace.CurrentCamera.CFrame.RightVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.D) then
                moveVec = moveVec + workspace.CurrentCamera.CFrame.RightVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                moveVec = moveVec + Vector3.new(0, 1, 0)
            end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveVec = moveVec - Vector3.new(0, 1, 0)
            end
            bodyVelocity.Velocity = moveVec.Unit * 50
            bodyGyro.CFrame = workspace.CurrentCamera.CFrame
        end)
    else
        flying = false
        if bodyGyro then bodyGyro:Destroy() end
        if bodyVelocity then bodyVelocity:Destroy() end
        RS:UnbindFromRenderStep("Fly")
    end
end

---------------------------------------------------------------------
-- AIM ASSIST -------------------------------------------------------
---------------------------------------------------------------------
local function getClosestTarget(maxDistance)
    local closestTarget = nil
    local shortestDistance = maxDistance

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and isEnemy(pl) and pl.Character then
            local h = getHead(pl.Character)
            if h then
                local pos, vis = Camera:WorldToViewportPoint(h.Position)
                if vis then
                    local mousePos = UIS:GetMouseLocation()
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestTarget = h
                    end
                end
            end
        end
    end
    return closestTarget
end

local function aimAt(target: BasePart)
    if not target then return end
    local cameraCFrame = Camera.CFrame
    local direction = (target.Position - cameraCFrame.Position).Unit
    local newCFrame = CFrame.new(cameraCFrame.Position, cameraCFrame.Position + direction)
    Camera.CFrame = newCFrame
end

local spinAngle = 0

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E and state.aim then
        state.aim = false -- E tuşuna basınca aim kapansın
        Rayfield:Notify({Title="LCX", Content="Aim Assist devre dışı bırakıldı!", Duration=3})
    end
end)

conns.aim = RS.RenderStepped:Connect(function()
    if not state.aim then return end

    if state.aimMode == "Auto" then
        local target = getClosestTarget(180)
        if target then
            aimAt(target)
        end

    elseif state.aimMode == "Legit" then
        -- Legit aim: sadece mouse tuşuna basılıyken yavaşça yönel
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = getClosestTarget(150)
            if target then
                local cameraCFrame = Camera.CFrame
                local direction = (target.Position - cameraCFrame.Position).Unit
                local newLook = cameraCFrame.LookVector:Lerp(direction, 0.1)
                Camera.CFrame = CFrame.new(cameraCFrame.Position, cameraCFrame.Position + newLook)
            end
        end

    elseif state.aimMode == "Spin" then
        -- Spin Aim: kamera sürekli dönüyor ve ateş ediyor (ateş komutunu eklemek gerekirse)
        spinAngle = (spinAngle + math.rad(5)) % (2 * math.pi)
        local rootPos = Root.Position
        local lookVector = Vector3.new(math.cos(spinAngle), 0, math.sin(spinAngle))
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
        -- Ateş komutu yok, buraya eklenebilir
    end
end)

---------------------------------------------------------------------
-- PLAYER JOIN/LEAVE -----------------------------------------------
---------------------------------------------------------------------
local function hookPlayer(pl)
    if pl == LP then return end
    local function onChar(c)
        if state.esp then makeESP(c) end
        if state.wall then makeHL(c) end
        if state.hitbox then resizeHead(c, true) end
    end
    if pl.Character then onChar(pl.Character) end
    pl.CharacterAdded:Connect(onChar)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.Player
