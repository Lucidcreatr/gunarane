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
local MainTab = Tabs.ESP
local AimTab = Tabs.Aim
local PlayerTab = Tabs.Player
local MiscTab = Tabs.Misc

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
    if not LP.Team or not pl.Team then return pl~=LP end
    return pl.Team ~= LP.Team
end

local function headOf(model:Model):BasePart?
    return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- UI CALLBACKS (Eksik olanlar) -------------------------------------
---------------------------------------------------------------------
local function updateESPColor(color: Color3)
    state.espColor = color
end

---------------------------------------------------------------------
-- ESP --------------------------------------------------------------
---------------------------------------------------------------------
local function updateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local box = espBoxes[char]
            local pos, onscreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if not box then
                box = Drawing.new("Text")
                box.Size = 14
                box.Center = true
                box.Outline = true
                espBoxes[char] = box
            end
            if onscreen and state.esp then
                box.Text = plr.Name
                box.Color = state.espColor
                box.Position = Vector2.new(pos.X, pos.Y - 30)
                box.Visible = true
            else
                box.Visible = false
            end
        end
    end
end

MainTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(v)
        state.esp = v
        if not v then
            for _, box in pairs(espBoxes) do
                box.Visible = false
            end
        end
    end
})

MainTab:CreateColorPicker({
    Name = "ESP Renk",
    Color = state.espColor,
    Callback = updateESPColor
})

---------------------------------------------------------------------
-- WALLHACK ---------------------------------------------------------
---------------------------------------------------------------------
MainTab:CreateToggle({
    Name = "WallHack",
    CurrentValue = false,
    Callback = function(v)
        state.wall = v
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isEnemy(plr) and plr.Character then
                local char = plr.Character
                if not highlights[char] then
                    local hl = Instance.new("Highlight", char)
                    hl.FillColor = state.espColor
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.new(1,1,1)
                    hl.OutlineTransparency = 0
                    highlights[char] = hl
                end
                highlights[char].Enabled = v
            end
        end
    end
})

---------------------------------------------------------------------
-- SPEED ------------------------------------------------------------
---------------------------------------------------------------------
PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Callback = function(v)
        state.speed = v
        Hum.WalkSpeed = v and (baseSpeed * state.speedMult) or baseSpeed
    end
})

PlayerTab:CreateSlider({
    Name = "Speed Çarpanı",
    Range = {1, 3},
    Increment = 0.1,
    CurrentValue = state.speedMult,
    Callback = function(v)
        state.speedMult = v
        if state.speed then
            Hum.WalkSpeed = baseSpeed * v
        end
    end
})

---------------------------------------------------------------------
-- BHOP -------------------------------------------------------------
---------------------------------------------------------------------
PlayerTab:CreateToggle({
    Name = "Bunny Hop",
    CurrentValue = false,
    Callback = function(v)
        state.bhop = v
    end
})

---------------------------------------------------------------------
-- FLY --------------------------------------------------------------
---------------------------------------------------------------------
PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        state.fly = v
        Root.Anchored = v
    end
})

---------------------------------------------------------------------
-- AIMBOT -----------------------------------------------------------
---------------------------------------------------------------------
AimTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v)
        state.aim = v
    end
})

AimTab:CreateDropdown({
    Name = "Aim Modu",
    Options = {"Auto", "Legit", "Spin"},
    CurrentOption = "Auto",
    Callback = function(opt)
        state.aimMode = opt
    end
})

---------------------------------------------------------------------
-- ESP LOOP ---------------------------------------------------------
---------------------------------------------------------------------
conns.esp = RS.RenderStepped:Connect(function()
    if state.esp then updateESP() end

    if state.bhop and Hum.FloorMaterial ~= Enum.Material.Air then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    if state.fly then
        local direction = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += Camera.CFrame.RightVector end
        Root.CFrame = Root.CFrame + direction.Unit * 0.6
    end

    if state.aim then
        local target: Player?
        local closest = math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("Head") then
                local head = plr.Character.Head
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if dist < closest then
                        closest = dist
                        target = plr
                    end
                end
            end
        end

        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            if state.aimMode == "Auto" then
                workspace.CurrentCamera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            elseif state.aimMode == "Legit" then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), 0.05)
            elseif state.aimMode == "Spin" then
                Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(15), 0)
            end
        end
    end
end)
