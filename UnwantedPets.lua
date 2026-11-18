-- ==========================================
-- NATIVE SIMPLE UI & AUTO SELL SCRIPT
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

-- Remove old UI if it already exists
if CoreGui:FindFirstChild("SimplePetGui") then
    CoreGui.SimplePetGui:Destroy()
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimplePetGui"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -60)
mainFrame.Size = UDim2.new(0, 220, 0, 110)

-- Make corners rounded
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Bar / Header
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Parent = mainFrame
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.Font = Enum.Font.GothamBold
titleBar.Text = "Pet Auto-Sell UI"
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.TextSize = 14

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- Fix bottom corners of title bar so they stay square
local titleFix = Instance.new("Frame")
titleFix.Parent = titleBar
titleFix.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
titleFix.BorderSizePixel = 0
titleFix.Position = UDim2.new(0, 0, 1, -5)
titleFix.Size = UDim2.new(1, 0, 0, 5)

-- Toggle Button Container
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Parent = mainFrame
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
toggleButton.BorderSizePixel = 0
toggleButton.Position = UDim2.new(0, 15, 0, 52)
toggleButton.Size = UDim2.new(0, 190, 0, 42)
toggleButton.AutoButtonColor = false
toggleButton.Font = Enum.Font.GothamMedium
toggleButton.Text = "Auto Sell: OFF"
toggleButton.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleButton.TextSize = 13

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

-- ==========================================
-- DRAGGABLE WINDOW LOGIC
-- ==========================================
local dragging, dragInput, dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- AUTO SELL LOGIC & CONFIGURATION
-- ==========================================
local autoSellEnabled = false

-- Updated Pet List to auto sell by name
local autoSellPetsByName = {
    ["Cosmic Invader"] = true,
    ["Alien Slime"] = true
}

-- Toggle Button Action
toggleButton.MouseButton1Click:Connect(function()
    autoSellEnabled = not autoSellEnabled
    
    if autoSellEnabled then
        toggleButton.Text = "Auto Sell: ON"
        toggleButton.TextColor3 = Color3.fromRGB(80, 255, 120)
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 80, 50)}):Play()
    else
        toggleButton.Text = "Auto Sell: OFF"
        toggleButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

-- Background Selling Loop
task.spawn(function()
    while true do
        if autoSellEnabled then
            pcall(function()
                local p = Players.LocalPlayer
                local petsFolder = p:FindFirstChild("petsFolder") or p:FindFirstChild("PetsFolder") or p:FindFirstChild("Pets")
                local rEvents = ReplicatedStorage:FindFirstChild("rEvents") or ReplicatedStorage:FindFirstChild("remotes")
                local sellEvent = rEvents and (rEvents:FindFirstChild("sellPetEvent") or rEvents:FindFirstChild("SellPetEvent") or rEvents:FindFirstChild("sellPet") or rEvents:FindFirstChild("SellPet"))

                if petsFolder and sellEvent then
                    for _, rarityFolder in pairs(petsFolder:GetChildren()) do
                        if not autoSellEnabled then break end
                        
                        if rarityFolder:IsA("Folder") then
                            for _, pet in pairs(rarityFolder:GetChildren()) do
                                if autoSellPetsByName[pet.Name] then
                                    pcall(function()
                                        if sellEvent:IsA("RemoteFunction") then
                                            sellEvent:InvokeServer("sellPet", pet)
                                        else
                                            sellEvent:FireServer("sellPet", pet)
                                        end
                                    end)
                                    task.wait(0.1)
                                end
                            end
                        elseif rarityFolder:IsA("Model") or rarityFolder:IsA("BasePart") then
                            if autoSellPetsByName[rarityFolder.Name] then
                                pcall(function()
                                    if sellEvent:IsA("RemoteFunction") then
                                        sellEvent:InvokeServer("sellPet", rarityFolder)
                                    else
                                        sellEvent:FireServer("sellPet", rarityFolder)
                                    end
                                end)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)
