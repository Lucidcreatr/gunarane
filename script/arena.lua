--!strict
-- LCX Gunfight Arena Advanced Cheat GUI (Rayfield)
-- Game: https://www.roblox.com/games/14518422161

if game.PlaceId ~= 14518422161 then return end

-- LOAD RAYFIELD
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then warn("Rayfield yüklenemedi: "..tostring(Rayfield)); return end

-- WINDOW & TABS
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

-- SERVICES
local Players, RS, UIS = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local Hum  = Char:WaitForChild("Humanoid")
local Root = Char:WaitForChild("HumanoidRootPart")

-- STATE
local state = {
    esp = false, wall = false, bhop = false, speed = false, fly = false,
    aim = false, aimMode = "Auto",
    speedMult = 1.8, hitboxSize = 3,
    espColor = Color3.new(1,0,0)
}
local conns = {}
local espBoxes: {[Model]:Drawing} = {}
local highlights: {[Model]:Highlight} = {}
local baseSpeed = Hum.WalkSpeed
local aiming = false

-- HELPERS
local function isEnemy(pl: Player)
    if not LP.Team or not pl.Team then return pl ~= LP end
    return pl.Team ~= LP.Team
end

-- ESP
local function updateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local box = espBoxes[char]
            local pos, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if not box then
                box = Drawing.new("Text")
                box.Size = 14
                box.Center = true
                box.Outline = true
                espBoxes[char] = box
            end
            box.Visible = state.esp and onScreen
            if state.esp and onScreen then
                box.Text = plr.Name
                box.Color = state.espColor
                box.Position = Vector2.new(pos.X, pos.Y - 30)
            end
        end
    end
end

-- UI
MainTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(v)
        state.esp = v
        for _, box in pairs(espBoxes) do box.Visible = false end
    end
})
MainTab:CreateColorPicker({
    Name = "ESP Renk",
    Color = state.espColor,
    Callback = function(c) state.espColor = c end
})
MainTab:CreateToggle({
    Name = "WallHack",
    CurrentValue = false,
    Callback = function(v)
        state.wall = v
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isEnemy(plr) and plr.Character then
                local char = plr.Character
                local hl = highlights[char]
                if not hl then
                    hl = Instance.new("Highlight", char)
                    hl.FillColor = state.espColor
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.new(1,1,1)
                    highlights[char] = hl
                end
                hl.Enabled = v
            end
        end
    end
})

-- SPEED
PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Callback = function(v)
        state.speed = v
        Hum.WalkSpeed = v and math.clamp(baseSpeed * state.speedMult, 0, 50) or baseSpeed
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
            Hum.WalkSpeed = math.clamp(baseSpeed * v, 0, 50)
        end
    end
})

-- HITBOX
PlayerTab:CreateSlider({
    Name = "Hitbox Genişliği",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = state.hitboxSize,
    Callback = function(size)
        state.hitboxSize = math.clamp(size, 1, 100)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isEnemy(plr) and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then head.Size = Vector3.new(size, size, size) end
            end
        end
    end
})

-- BHOP / FLY
PlayerTab:CreateToggle({
    Name = "Bunny Hop",
    CurrentValue = false,
    Callback = function(v) state.bhop = v end
})
PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        state.fly = v
        Root.Anchored = v
    end
})

-- AIMBOT
AimTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v) state.aim = v end
})
AimTab:CreateDropdown({
    Name = "Aim Modu",
    Options = {"Auto", "Legit", "Spin"},
    CurrentOption = "Auto",
    Callback = function(opt) state.aimMode = opt end
})

-- MOUSE INPUT
UIS.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        aiming = true
    end
end)
UIS.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        aiming = false
    end
end)

-- MAIN LOOP
conns.main = RS.RenderStepped:Connect(function()
    if state.esp then updateESP() end

    if state.bhop and Hum.FloorMaterial ~= Enum.Material.Air then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    if state.fly then
        local dir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if dir.Magnitude > 0 then
            Root.CFrame = Root.CFrame + dir.Unit * 0.6
        end
    end

    -- Aimbot
    if state.aim and aiming then
        local closest, target = math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("Head") then
                local head = plr.Character.Head
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if dist < closest then
                        closest = dist
                        target = head
                    end
                end
            end
        end

        if target then
            if state.aimMode == "Auto" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            elseif state.aimMode == "Legit" then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), 0.05)
            elseif state.aimMode == "Spin" then
                Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(15), 0)
            end
        end
    end
end)
