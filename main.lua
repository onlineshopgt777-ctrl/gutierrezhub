--[[
    Gutiérrez Hub
    Features:
    - Faster Grab (aumenta rango de recolección)
    - Teleport to Base (detecta respawn de tu base + mantiene el huevo en la mano)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

--// Configuración
local Config = {
    FasterGrabEnabled = false,
    GrabRange = 25,          -- Rango normal suele ser \~8-12
    BaseTeleportCooldown = 1.5
}

local lastTeleport = 0

--// Limpiar GUI anterior si existe
if CoreGui:FindFirstChild("GutiérrezHub") then
    CoreGui.GutiérrezHub:Destroy()
end

--// Crear ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GutiérrezHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

--// Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 220)
Main.Position = UDim2.new(0.5, -140, 0.5, -110)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Main

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 80, 100)
UIStroke.Thickness = 1.5
UIStroke.Parent = Main

--// Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 15)
TitleFix.Position = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Gutiérrez Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

--// Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -33, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--// Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -55)
Content.Position = UDim2.new(0, 10, 0, 48)
Content.BackgroundTransparency = 1
Content.Parent = Main

--// Función para crear botones
local function CreateButton(name, yPos, color)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 38)
    Btn.Position = UDim2.new(0, 0, 0, yPos)
    Btn.BackgroundColor3 = color or Color3.fromRGB(40, 40, 55)
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 14
    Btn.AutoButtonColor = false
    Btn.Parent = Content

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Btn

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = color or Color3.fromRGB(40, 40, 55)}):Play()
    end)

    return Btn
end

--// Botón Faster Grab
local FasterGrabBtn = CreateButton("Faster Grab: OFF", 0, Color3.fromRGB(45, 45, 65))

--// Botón Teleport to Base
local TeleportBtn = CreateButton("Teleport to Base (con Huevo)", 50, Color3.fromRGB(30, 100, 70))

--// Info Label
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 40)
InfoLabel.Position = UDim2.new(0, 0, 0, 105)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Mantén el huevo equipado\nantes de teletransportarte"
InfoLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 12
InfoLabel.TextWrapped = true
InfoLabel.Parent = Content

--// ==================== FUNCIONES ====================

-- Faster Grab
local GrabConnection
local function ToggleFasterGrab()
    Config.FasterGrabEnabled = not Config.FasterGrabEnabled
    
    if Config.FasterGrabEnabled then
        FasterGrabBtn.Text = "Faster Grab: ON"
        FasterGrabBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 60)
        
        GrabConnection = RunService.Heartbeat:Connect(function()
            if not Character or not HumanoidRootPart then return end
            
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower():find("egg") or obj.Name:lower():find("huevo") or obj:FindFirstChild("Pickup") or obj:FindFirstChildOfClass("ClickDetector") or obj:FindFirstChildOfClass("ProximityPrompt")) then
                    local dist = (HumanoidRootPart.Position - obj.Position).Magnitude
                    if dist <= Config.GrabRange then
                        -- Intentar forzar pickup
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                        end
                        
                        local click = obj:FindFirstChildOfClass("ClickDetector")
                        if click then
                            fireclickdetector(click)
                        end
                    end
                end
            end
        end)
    else
        FasterGrabBtn.Text = "Faster Grab: OFF"
        FasterGrabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        if GrabConnection then
            GrabConnection:Disconnect()
            GrabConnection = nil
        end
    end
end

FasterGrabBtn.MouseButton1Click:Connect(ToggleFasterGrab)

-- Detectar Base / Respawn del jugador
local function FindPlayerBase()
    -- Busca de forma inteligente el punto de respawn de la base del jugador
    local possibleNames = {"Base", "Plot", "Island", "Home", "Spawn", "Respawn", "Tycoon"}
    
    for _, name in pairs(possibleNames) do
        local folder = workspace:FindFirstChild(name) or workspace:FindFirstChild(name .. "s")
        if folder then
            for _, plot in pairs(folder:GetChildren()) do
                -- Buscar ownership
                local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player") or plot:GetAttribute("Owner")
                if owner then
                    if (typeof(owner) == "Instance" and owner == LocalPlayer) or 
                       (typeof(owner) == "string" and owner == LocalPlayer.Name) or
                       (plot:GetAttribute("Owner") == LocalPlayer.UserId) then
                        
                        -- Buscar SpawnLocation o RespawnPoint
                        local spawn = plot:FindFirstChild("Spawn") or 
                                      plot:FindFirstChild("Respawn") or 
                                      plot:FindFirstChild("SpawnLocation") or
                                      plot:FindFirstChildWhichIsA("SpawnLocation") or
                                      plot:FindFirstChild("Home")
                        
                        if spawn and spawn:IsA("BasePart") then
                            return spawn.CFrame + Vector3.new(0, 3, 0)
                        elseif spawn and spawn:IsA("Model") and spawn.PrimaryPart then
                            return spawn.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
                        end
                        
                        -- Si no hay spawn claro, usar el centro del plot
                        local primary = plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
                        if primary then
                            return primary.CFrame + Vector3.new(0, 5, 0)
                        end
                    end
                end
            end
        end
    end
    
    -- Fallback: SpawnLocation del jugador o último checkpoint
    if LocalPlayer.RespawnLocation then
        return LocalPlayer.RespawnLocation.CFrame + Vector3.new(0, 3, 0)
    end
    
    return nil
end

-- Teleport manteniendo el tool (huevo)
local function TeleportToBase()
    if tick() - lastTeleport < Config.BaseTeleportCooldown then return end
    lastTeleport = tick()
    
    local targetCFrame = FindPlayerBase()
    
    if not targetCFrame then
        -- Notificación visual simple
        InfoLabel.Text = "No se encontró tu base"
        InfoLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.delay(2, function()
            InfoLabel.Text = "Mantén el huevo equipado\nantes de teletransportarte"
            InfoLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
        end)
        return
    end
    
    -- Guardar el tool actual (huevo)
    local currentTool = Character:FindFirstChildOfClass("Tool")
    
    -- Teleport
    HumanoidRootPart.CFrame = targetCFrame
    
    -- Re-equipar el tool si se desequipó
    task.wait(0.1)
    if currentTool and currentTool.Parent \~= Character then
        Humanoid:EquipTool(currentTool)
    end
    
    InfoLabel.Text = "¡Teletransportado a tu base!"
    InfoLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
    task.delay(2, function()
        InfoLabel.Text = "Mantén el huevo equipado\nantes de teletransportarte"
        InfoLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
    end)
end

TeleportBtn.MouseButton1Click:Connect(TeleportToBase)

-- Actualizar Character al respawnear
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

print("Gutiérrez Hub cargado correctamente")
