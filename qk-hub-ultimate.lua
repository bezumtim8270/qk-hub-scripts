-- ==================================================
-- 👑 QK HUB ULTIMATE - AUTO FRUIT HUNTER 👑
-- (Bản kết hợp: Noclip + Hybrid Hop + Auto Execute)
-- ==================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local CurrentPlaceId = game.PlaceId
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- ==========================================
-- 1. TỰ ĐỘNG CHẠY LẠI SCRIPT KHI ĐỔI SERVER
-- ==========================================
if queue_on_teleport then
    queue_on_teleport([[
        repeat task.wait() until game:IsLoaded()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/bezumtim8270/qk-hub-scripts/main/qk-hub-ultimate.lua"))()
    ]])
end

-- ==========================================
-- 2. GIAO DIỆN QK HUB (FIX 100% LOAD MENU)
-- ==========================================
local parentTarget = CoreGui
if not pcall(function() local a = CoreGui.Name end) then
    parentTarget = LocalPlayer:WaitForChild("PlayerGui")
end

if parentTarget:FindFirstChild("QK_Hub_UI") then
    parentTarget.QK_Hub_UI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", parentTarget)
ScreenGui.Name = "QK_Hub_UI"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 110)
MainFrame.Position = UDim2.new(0.5, -175, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "👑 QK HUB ULTIMATE 👑"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 50)
StatusLabel.Position = UDim2.new(0, 10, 0, 45)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "⚡ Đang khởi động hệ thống..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true

local function updateStatus(text)
    StatusLabel.Text = text
end

-- ==========================================
-- 3. AUTO CHỌN PHE & NOCLIP
-- ==========================================
task.spawn(function()
    while LocalPlayer.Team == nil do
        pcall(function() CommF:InvokeServer("SetTeam", "Pirates") end)
        task.wait(1)
    end
end)

local isMoving = false
RunService.RenderStepped:Connect(function()
    if isMoving and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false -- Xuyên tường mượt
            end
        end
    end
end)

-- ==========================================
-- 4. TÌM, BAY & LƯU TRÁI (TỐC ĐỘ 250)
-- ==========================================
local function getFruitPart()
    for _, item in pairs(workspace:GetChildren()) do
        if item:IsA("Model") and string.find(item.Name, "Fruit") then
            local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
            if handle then return handle, item end
        end
    end
    return nil, nil
end

local function noclipMoveToFruit(targetPart)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    isMoving = true
    local bv = Instance.new("BodyVelocity", hrp)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

    local speed = 250 -- Đã chuẩn hóa tốc độ 250 theo yêu cầu
    local targetPos = targetPart.Position + Vector3.new(0, 2, 0)

    while targetPart.Parent and (hrp.Position - targetPos).Magnitude > 4 do
        targetPos = targetPart.Position + Vector3.new(0, 2, 0)
        local distance = (hrp.Position - targetPos).Magnitude
        local direction = (targetPos - hrp.Position).Unit
        local moveStep = math.min(speed * task.wait(), distance)
        
        hrp.CFrame = CFrame.new(hrp.Position + direction * moveStep)
    end

    bv:Destroy()
    isMoving = false
    
    if targetPart.Parent then
        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 1.5, 0)
    end
    task.wait(0.2)
end

local function storeAllFruits()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local items = {}

    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if string.find(item.Name, "Fruit") then table.insert(items, item) end
        end
    end
    if char then
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name, "Fruit") then table.insert(items, item) end
        end
    end

    for _, fruit in pairs(items) do
        pcall(function()
            if fruit.Parent == backpack and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid:EquipTool(fruit)
            end
            task.wait(0.2)
            CommF:InvokeServer("StoreFruit", fruit.Name, fruit)
            updateStatus("📦 Đã cất kho: " .. fruit.Name)
            task.wait(0.2)
        end)
    end
end

-- ==========================================
-- 5. HYBRID HOP SERVER (API -> NO-API FALLBACK)
-- ==========================================
local isHopping = false

local function SmartHop()
    if isHopping then return end
    isHopping = true
    
    -- Hủy gia tốc thừa trước khi Hop
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, v in pairs(LocalPlayer.Character.HumanoidRootPart:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
        end
    end

    updateStatus("🔄 Đang quét API Server...")
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. CurrentPlaceId .. "/servers/0?sortOrder=Asc&limit=100"))
    end)

    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                pcall(function() TeleportService:TeleportToPlaceInstance(CurrentPlaceId, server.id, LocalPlayer) end)
                task.wait(2)
            end
        end
    end

    -- Nếu API lỗi hoặc mảng rỗng -> Dùng No-API (Trực tiếp qua TravelMain hoặc Teleport)
    updateStatus("⚠️ API Down! Đang Hop trực tiếp (No-API)...")
    pcall(function() CommF:InvokeServer("TravelMain") end)
    task.wait(1)
    pcall(function() TeleportService:Teleport(CurrentPlaceId, LocalPlayer) end)
    
    task.wait(5)
    isHopping = false
end

TeleportService.TeleportInitFailed:Connect(function()
    isHopping = false
    updateStatus("⚠️ Lỗi Teleport! Thử lại ngay...")
    task.wait(1)
    SmartHop()
end)

-- ==========================================
-- 6. VÒNG LẶP AUTO HUNTER VÔ TẬN
-- ==========================================
task.spawn(function()
    while not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
        task.wait(0.5)
    end
    task.wait(1)

    while true do
        local fruitPart, fruitModel = getFruitPart()
        
        if fruitPart then
            updateStatus("🚀 Phát hiện: " .. fruitModel.Name .. "\nĐang dùng Noclip bay tới...")
            noclipMoveToFruit(fruitPart)
            storeAllFruits()
            SmartHop()
        else
            updateStatus("❌ Không có trái!\nĐang tiến hành Hop Server...")
            SmartHop()
            task.wait(4)
        end
        task.wait(0.2)
    end
end)
