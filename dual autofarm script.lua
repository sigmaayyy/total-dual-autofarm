local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local DualHit = ReplicatedStorage:WaitForChild("DualHit", 5)

local SAVE_FILE = "DualAutofarm_SavedUser.txt"
local autofarmActive = false
local antiRagdollActive = false
local baseplateCreated = false
local baseplatePart = nil
local autofarmConnection = nil
local autofarmHitThread = nil
local uiVisible = true

local COLOR_MAIN_BG = Color3.fromRGB(20, 20, 24)
local COLOR_SIDE_BG = Color3.fromRGB(14, 14, 18)
local COLOR_WARN_BG = Color3.fromRGB(24, 24, 28)
local COLOR_CONTAINER = Color3.fromRGB(30, 30, 36)

local function hasSavedPreference()
    if readfile and isfile and isfile(SAVE_FILE) then
        return readfile(SAVE_FILE) == LocalPlayer.Name
    end
    return false
end

local function savePreference()
    if writefile then
        writefile(SAVE_FILE, LocalPlayer.Name)
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DualAutofarm_UI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- LOADING SCREEN
local loadingOverlay = Instance.new("Frame")
loadingOverlay.Size = UDim2.new(1, 0, 1, 0)
loadingOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
loadingOverlay.ZIndex = 1000
loadingOverlay.Parent = screenGui

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(1, 0, 0, 40)
loadingTitle.Position = UDim2.new(0, 0, 0.42, 0)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "Dual Autofarm Panel"
loadingTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.TextSize = 22
loadingTitle.ZIndex = 1001
loadingTitle.Parent = loadingOverlay

local loadingSub = Instance.new("TextLabel")
loadingSub.Size = UDim2.new(1, 0, 0, 20)
loadingSub.Position = UDim2.new(0, 0, 0.48, 0)
loadingSub.BackgroundTransparency = 1
loadingSub.Text = "Loading script resources..."
loadingSub.TextColor3 = Color3.fromRGB(140, 140, 160)
loadingSub.Font = Enum.Font.Gotham
loadingSub.TextSize = 13
loadingSub.ZIndex = 1001
loadingSub.Parent = loadingOverlay

local loadingBarBg = Instance.new("Frame")
loadingBarBg.Size = UDim2.new(0, 240, 0, 6)
loadingBarBg.Position = UDim2.new(0.5, -120, 0.54, 0)
loadingBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
loadingBarBg.ZIndex = 1001
loadingBarBg.Parent = loadingOverlay
Instance.new("UICorner", loadingBarBg).CornerRadius = UDim.new(1, 0)

local loadingBarFill = Instance.new("Frame")
loadingBarFill.Size = UDim2.new(0, 0, 1, 0)
loadingBarFill.BackgroundColor3 = Color3.fromRGB(140, 50, 210)
loadingBarFill.ZIndex = 1002
loadingBarFill.Parent = loadingBarBg
Instance.new("UICorner", loadingBarFill).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    TweenService:Create(loadingBarFill, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    task.wait(1.4)
    local fadeOut = TweenService:Create(loadingOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
    TweenService:Create(loadingTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(loadingSub, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(loadingBarBg, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(loadingBarFill, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        loadingOverlay:Destroy()
    end)
end)

local notifContainer = Instance.new("Frame")
notifContainer.Size = UDim2.new(0, 280, 0, 300)
notifContainer.Position = UDim2.new(1, -290, 0.05, 0)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = screenGui

local UIList = Instance.new("UIListLayout")
UIList.Parent = notifContainer
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.VerticalAlignment = Enum.VerticalAlignment.Top

local function sendNotification(msg)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 52)
    notif.BackgroundColor3 = COLOR_CONTAINER
    notif.BackgroundTransparency = 1
    notif.ClipsDescendants = true
    notif.Parent = notifContainer

    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(240, 140, 30)
    stroke.Thickness = 1.5
    stroke.Transparency = 1
    stroke.Parent = notif

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -16, 1, -6)
    txt.Position = UDim2.new(0, 8, 0, 2)
    txt.BackgroundTransparency = 1
    txt.Text = msg
    txt.TextColor3 = Color3.fromRGB(245, 245, 245)
    txt.TextWrapped = true
    txt.TextTransparency = 1
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 12
    txt.Parent = notif

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressBar.BackgroundTransparency = 1
    progressBar.BorderSizePixel = 0
    progressBar.Parent = notif

    TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
    TweenService:Create(txt, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
    TweenService:Create(progressBar, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()

    local progressTween = TweenService:Create(progressBar, TweenInfo.new(5, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)})
    progressTween:Play()

    progressTween.Completed:Connect(function()
        local fadeOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
        TweenService:Create(txt, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(progressBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

local hamburgerBtn = Instance.new("TextButton")
hamburgerBtn.Size = UDim2.new(0, 44, 0, 44)
hamburgerBtn.Position = UDim2.new(0.5, -22, 0, 15)
hamburgerBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
hamburgerBtn.Text = "≡"
hamburgerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hamburgerBtn.Font = Enum.Font.GothamBold
hamburgerBtn.TextSize = 24
hamburgerBtn.ZIndex = 100
hamburgerBtn.Parent = screenGui

Instance.new("UICorner", hamburgerBtn).CornerRadius = UDim.new(0, 8)
local hamStroke = Instance.new("UIStroke")
hamStroke.Color = Color3.fromRGB(150, 50, 220)
hamStroke.Thickness = 2
hamStroke.Parent = hamburgerBtn

local warningFrame = Instance.new("Frame")
warningFrame.Size = UDim2.new(0, 360, 0, 220)
warningFrame.Position = UDim2.new(0.5, -180, 0.5, -110)
warningFrame.BackgroundColor3 = COLOR_WARN_BG
warningFrame.BackgroundTransparency = 0
warningFrame.Visible = false
warningFrame.Active = true
warningFrame.Parent = screenGui

Instance.new("UICorner", warningFrame).CornerRadius = UDim.new(0, 10)
local warnStroke = Instance.new("UIStroke")
warnStroke.Color = Color3.fromRGB(230, 120, 20)
warnStroke.Thickness = 1.5
warnStroke.Parent = warningFrame

local warnDragBar = Instance.new("Frame")
warnDragBar.Size = UDim2.new(1, 0, 0, 30)
warnDragBar.BackgroundTransparency = 1
warnDragBar.Parent = warningFrame

local warnText = Instance.new("TextLabel")
warnText.Size = UDim2.new(0.9, 0, 0.45, 0)
warnText.Position = UDim2.new(0.05, 0, 0.18, 0)
warnText.BackgroundTransparency = 1
warnText.Text = "This script requires an alt account to work properly.\n\nIf you have an alt ready, click continue."
warnText.TextColor3 = Color3.fromRGB(220, 220, 220)
warnText.TextWrapped = true
warnText.Font = Enum.Font.Gotham
warnText.TextSize = 13
warnText.Parent = warningFrame

local dontShowBtn = Instance.new("TextButton")
dontShowBtn.Size = UDim2.new(0.42, 0, 0.22, 0)
dontShowBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
dontShowBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
dontShowBtn.Text = "Don't Show Again"
dontShowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dontShowBtn.Font = Enum.Font.GothamBold
dontShowBtn.TextSize = 12
dontShowBtn.Parent = warningFrame
Instance.new("UICorner", dontShowBtn).CornerRadius = UDim.new(0, 6)

local continueBtn = Instance.new("TextButton")
continueBtn.Size = UDim2.new(0.42, 0, 0.22, 0)
continueBtn.Position = UDim2.new(0.53, 0, 0.7, 0)
continueBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
continueBtn.Text = "Continue"
continueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
continueBtn.Font = Enum.Font.GothamBold
continueBtn.TextSize = 12
continueBtn.Parent = warningFrame
Instance.new("UICorner", continueBtn).CornerRadius = UDim.new(0, 6)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 440, 0, 240)
mainFrame.Position = UDim2.new(0.5, -220, 0.5, -120)
mainFrame.BackgroundColor3 = COLOR_MAIN_BG
mainFrame.BackgroundTransparency = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(50, 50, 60)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local mainDragBar = Instance.new("Frame")
mainDragBar.Size = UDim2.new(1, -36, 0, 28)
mainDragBar.BackgroundTransparency = 1
mainDragBar.Parent = mainFrame

local dragTitle = Instance.new("TextLabel")
dragTitle.Size = UDim2.new(1, -16, 1, 0)
dragTitle.Position = UDim2.new(0, 10, 0, 0)
dragTitle.BackgroundTransparency = 1
dragTitle.Text = "Dual Autofarm Panel"
dragTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
dragTitle.Font = Enum.Font.GothamBold
dragTitle.TextSize = 11
dragTitle.TextXAlignment = Enum.TextXAlignment.Left
dragTitle.Parent = mainDragBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local confirmOverlay = Instance.new("Frame")
confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
confirmOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
confirmOverlay.BackgroundTransparency = 0.15
confirmOverlay.Visible = false
confirmOverlay.ZIndex = 10
confirmOverlay.Parent = mainFrame
Instance.new("UICorner", confirmOverlay).CornerRadius = UDim.new(0, 10)

local confirmText = Instance.new("TextLabel")
confirmText.Size = UDim2.new(0.9, 0, 0.4, 0)
confirmText.Position = UDim2.new(0.05, 0, 0.15, 0)
confirmText.BackgroundTransparency = 1
confirmText.Text = "Are you sure you want to close?\nThis will stop all running scripts."
confirmText.TextColor3 = Color3.fromRGB(245, 245, 245)
confirmText.Font = Enum.Font.GothamBold
confirmText.TextSize = 13
confirmText.TextWrapped = true
confirmText.ZIndex = 11
confirmText.Parent = confirmOverlay

local confirmYesBtn = Instance.new("TextButton")
confirmYesBtn.Size = UDim2.new(0.4, 0, 0.25, 0)
confirmYesBtn.Position = UDim2.new(0.08, 0, 0.6, 0)
confirmYesBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
confirmYesBtn.Text = "Close Script"
confirmYesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmYesBtn.Font = Enum.Font.GothamBold
confirmYesBtn.TextSize = 12
confirmYesBtn.ZIndex = 11
confirmYesBtn.Parent = confirmOverlay
Instance.new("UICorner", confirmYesBtn).CornerRadius = UDim.new(0, 6)

local confirmNoBtn = Instance.new("TextButton")
confirmNoBtn.Size = UDim2.new(0.4, 0, 0.25, 0)
confirmNoBtn.Position = UDim2.new(0.52, 0, 0.6, 0)
confirmNoBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
confirmNoBtn.Text = "Cancel"
confirmNoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmNoBtn.Font = Enum.Font.GothamBold
confirmNoBtn.TextSize = 12
confirmNoBtn.ZIndex = 11
confirmNoBtn.Parent = confirmOverlay
Instance.new("UICorner", confirmNoBtn).CornerRadius = UDim.new(0, 6)

local sideBar = Instance.new("Frame")
sideBar.Size = UDim2.new(0, 115, 1, -28)
sideBar.Position = UDim2.new(0, 0, 0, 28)
sideBar.BackgroundColor3 = COLOR_SIDE_BG
sideBar.BackgroundTransparency = 0
sideBar.Parent = mainFrame
Instance.new("UICorner", sideBar).CornerRadius = UDim.new(0, 10)

local mainTabBtn = Instance.new("TextButton")
mainTabBtn.Size = UDim2.new(0, 98, 0, 32)
mainTabBtn.Position = UDim2.new(0, 8, 0, 8)
mainTabBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 210)
mainTabBtn.Text = "Main Account"
mainTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTabBtn.Font = Enum.Font.GothamBold
mainTabBtn.TextSize = 11
mainTabBtn.Parent = sideBar
Instance.new("UICorner", mainTabBtn).CornerRadius = UDim.new(0, 6)

local altTabBtn = Instance.new("TextButton")
altTabBtn.Size = UDim2.new(0, 98, 0, 32)
altTabBtn.Position = UDim2.new(0, 8, 0, 44)
altTabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
altTabBtn.Text = "Alt Account"
altTabBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
altTabBtn.Font = Enum.Font.GothamBold
altTabBtn.TextSize = 11
altTabBtn.Parent = sideBar
Instance.new("UICorner", altTabBtn).CornerRadius = UDim.new(0, 6)

local creditsTabBtn = Instance.new("TextButton")
creditsTabBtn.Size = UDim2.new(0, 98, 0, 32)
creditsTabBtn.Position = UDim2.new(0, 8, 0, 80)
creditsTabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
creditsTabBtn.Text = "Credits"
creditsTabBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
creditsTabBtn.Font = Enum.Font.GothamBold
creditsTabBtn.TextSize = 11
creditsTabBtn.Parent = sideBar
Instance.new("UICorner", creditsTabBtn).CornerRadius = UDim.new(0, 6)

local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(1, -125, 1, -28)
mainContainer.Position = UDim2.new(0, 125, 0, 28)
mainContainer.BackgroundTransparency = 1
mainContainer.Visible = true
mainContainer.Parent = mainFrame

local targetTextBox = Instance.new("TextBox")
targetTextBox.Size = UDim2.new(0.92, 0, 0.22, 0)
targetTextBox.Position = UDim2.new(0.02, 0, 0.08, 0)
targetTextBox.BackgroundColor3 = COLOR_CONTAINER
targetTextBox.PlaceholderText = "Enter target username or display name..."
targetTextBox.Text = ""
targetTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
targetTextBox.Font = Enum.Font.Gotham
targetTextBox.TextSize = 12
targetTextBox.Parent = mainContainer
Instance.new("UICorner", targetTextBox).CornerRadius = UDim.new(0, 6)

local dualAutofarmBtn = Instance.new("TextButton")
dualAutofarmBtn.Size = UDim2.new(0.92, 0, 0.22, 0)
dualAutofarmBtn.Position = UDim2.new(0.02, 0, 0.38, 0)
dualAutofarmBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
dualAutofarmBtn.Text = "Dual Autofarm: OFF"
dualAutofarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dualAutofarmBtn.Font = Enum.Font.GothamBold
dualAutofarmBtn.TextSize = 13
dualAutofarmBtn.Parent = mainContainer
Instance.new("UICorner", dualAutofarmBtn).CornerRadius = UDim.new(0, 6)

local mainBaseplateBtn = Instance.new("TextButton")
mainBaseplateBtn.Size = UDim2.new(0.92, 0, 0.22, 0)
mainBaseplateBtn.Position = UDim2.new(0.02, 0, 0.68, 0)
mainBaseplateBtn.BackgroundColor3 = Color3.fromRGB(45, 95, 175)
mainBaseplateBtn.Text = "Create baseplate"
mainBaseplateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainBaseplateBtn.Font = Enum.Font.GothamBold
mainBaseplateBtn.TextSize = 13
mainBaseplateBtn.Parent = mainContainer
Instance.new("UICorner", mainBaseplateBtn).CornerRadius = UDim.new(0, 6)

local altContainer = Instance.new("Frame")
altContainer.Size = UDim2.new(1, -125, 1, -28)
altContainer.Position = UDim2.new(0, 125, 0, 28)
altContainer.BackgroundTransparency = 1
altContainer.Visible = false
altContainer.Parent = mainFrame

local antiRagdollBtn = Instance.new("TextButton")
antiRagdollBtn.Size = UDim2.new(0.92, 0, 0.32, 0)
antiRagdollBtn.Position = UDim2.new(0.02, 0, 0.12, 0)
antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
antiRagdollBtn.Text = "Anti-Ragdoll: OFF"
antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
antiRagdollBtn.Font = Enum.Font.GothamBold
antiRagdollBtn.TextSize = 13
antiRagdollBtn.Parent = altContainer
Instance.new("UICorner", antiRagdollBtn).CornerRadius = UDim.new(0, 6)

local altBaseplateBtn = Instance.new("TextButton")
altBaseplateBtn.Size = UDim2.new(0.92, 0, 0.32, 0)
altBaseplateBtn.Position = UDim2.new(0.02, 0, 0.54, 0)
altBaseplateBtn.BackgroundColor3 = Color3.fromRGB(45, 95, 175)
altBaseplateBtn.Text = "Create baseplate"
altBaseplateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
altBaseplateBtn.Font = Enum.Font.GothamBold
altBaseplateBtn.TextSize = 13
altBaseplateBtn.Parent = altContainer
Instance.new("UICorner", altBaseplateBtn).CornerRadius = UDim.new(0, 6)

-- CREDITS TAB CONTAINER
local creditsContainer = Instance.new("Frame")
creditsContainer.Size = UDim2.new(1, -125, 1, -28)
creditsContainer.Position = UDim2.new(0, 125, 0, 28)
creditsContainer.BackgroundTransparency = 1
creditsContainer.Visible = false
creditsContainer.Parent = mainFrame

local creditsLabel1 = Instance.new("TextLabel")
creditsLabel1.Size = UDim2.new(0.92, 0, 0.25, 0)
creditsLabel1.Position = UDim2.new(0.02, 0, 0.08, 0)
creditsLabel1.BackgroundTransparency = 1
creditsLabel1.Text = "The GUI and the code was made by total_scripts on discord."
creditsLabel1.TextColor3 = Color3.fromRGB(220, 220, 220)
creditsLabel1.Font = Enum.Font.Gotham
creditsLabel1.TextSize = 11
creditsLabel1.TextWrapped = true
creditsLabel1.TextXAlignment = Enum.TextXAlignment.Left
creditsLabel1.Parent = creditsContainer

local creditsLabel2 = Instance.new("TextLabel")
creditsLabel2.Size = UDim2.new(0.92, 0, 0.25, 0)
creditsLabel2.Position = UDim2.new(0.02, 0, 0.35, 0)
creditsLabel2.BackgroundTransparency = 1
creditsLabel2.Text = "The anti-ragdoll script/button was made by 6xow."
creditsLabel2.TextColor3 = Color3.fromRGB(220, 220, 220)
creditsLabel2.Font = Enum.Font.Gotham
creditsLabel2.TextSize = 11
creditsLabel2.TextWrapped = true
creditsLabel2.TextXAlignment = Enum.TextXAlignment.Left
creditsLabel2.Parent = creditsContainer

local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(0.92, 0, 0.26, 0)
discordBtn.Position = UDim2.new(0.02, 0, 0.65, 0)
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.Text = "Join Our Discord"
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextSize = 12
discordBtn.Parent = creditsContainer
Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 6)

discordBtn.MouseButton1Click:Connect(function()
    local link = "discord.com/invite/WumQzf7quj"
    if setclipboard then
        setclipboard(link)
    elseif toclipboard then
        toclipboard(link)
    end
    sendNotification("Discord link added to clipboard!")
end)

local function applyButtonEffects(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(btn.Size.X.Scale * 1.02, btn.Size.X.Offset, btn.Size.Y.Scale * 1.02, btn.Size.Y.Offset)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(btn.Size.X.Scale / 1.02, btn.Size.X.Offset, btn.Size.Y.Scale / 1.02, btn.Size.Y.Offset)}):Play()
    end)
end

applyButtonEffects(mainTabBtn)
applyButtonEffects(altTabBtn)
applyButtonEffects(creditsTabBtn)
applyButtonEffects(dualAutofarmBtn)
applyButtonEffects(mainBaseplateBtn)
applyButtonEffects(antiRagdollBtn)
applyButtonEffects(altBaseplateBtn)
applyButtonEffects(discordBtn)
applyButtonEffects(closeBtn)

mainTabBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = true
    altContainer.Visible = false
    creditsContainer.Visible = false
    TweenService:Create(mainTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(140, 50, 210), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    TweenService:Create(altTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 34), TextColor3 = Color3.fromRGB(140, 140, 150)}):Play()
    TweenService:Create(creditsTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 34), TextColor3 = Color3.fromRGB(140, 140, 150)}):Play()
end)

altTabBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = false
    altContainer.Visible = true
    creditsContainer.Visible = false
    TweenService:Create(altTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(140, 50, 210), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    TweenService:Create(mainTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 34), TextColor3 = Color3.fromRGB(140, 140, 150)}):Play()
    TweenService:Create(creditsTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 34), TextColor3 = Color3.fromRGB(140, 140, 150)}):Play()
end)

creditsTabBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = false
    altContainer.Visible = false
    creditsContainer.Visible = true
    TweenService:Create(creditsTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(140, 50, 210), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    TweenService:Create(mainTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 34), TextColor3 = Color3.fromRGB(140, 140, 150)}):Play()
    TweenService:Create(altTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 34), TextColor3 = Color3.fromRGB(140, 140, 150)}):Play()
end)

local function makeSmoothDraggable(guiObject, handleObject)
    handleObject = handleObject or guiObject
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        guiObject.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    handleObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handleObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

makeSmoothDraggable(hamburgerBtn)
makeSmoothDraggable(mainFrame, mainDragBar)
makeSmoothDraggable(warningFrame, warnDragBar)

local function isDualEquipped()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and (tool.Name == "Dual" or tool.Name:lower():find("dual")) then
            return true
        end
    end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local gloveStat = leaderstats:FindFirstChild("Glove")
        if gloveStat and gloveStat:IsA("StringValue") then
            return gloveStat.Value == "Dual" or gloveStat.Value:lower():find("dual") ~= nil
        end
    end

    return false
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function findTargetPlayer(query)
    query = string.gsub(query, "%s+", ""):lower()
    if #query < 2 then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local name = player.Name:lower()
            local displayName = player.DisplayName:lower()
            if name:find(query, 1, true) or displayName:find(query, 1, true) then
                return player
            end
        end
    end
    return nil
end

local function stopAutofarm()
    autofarmActive = false
    dualAutofarmBtn.Text = "Dual Autofarm: OFF"
    TweenService:Create(dualAutofarmBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}):Play()

    if autofarmConnection then
        autofarmConnection:Disconnect()
        autofarmConnection = nil
    end
    if autofarmHitThread then
        task.cancel(autofarmHitThread)
        autofarmHitThread = nil
    end
end

-- 6xow ANTI-RAGDOLL SCRIPT EXECUTION
local function runAntiRagdollScript()
    if _G.LoadedMobileShiftLock then
        return
    end
    _G.LoadedMobileShiftLock = true

    local existingGui = PlayerGui:FindFirstChild("MobileShiftLock")
    if existingGui then
        existingGui:Destroy()
    end

    local ShiftlockStarterGui = Instance.new("ScreenGui")
    local ImageButton = Instance.new("ImageButton")

    ShiftlockStarterGui.Name = "MobileShiftLock"
    ShiftlockStarterGui.Parent = PlayerGui
    ShiftlockStarterGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ShiftlockStarterGui.ResetOnSpawn = false

    ImageButton.Parent = ShiftlockStarterGui
    ImageButton.Active = true
    ImageButton.Draggable = false
    ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ImageButton.BackgroundTransparency = 1.000
    ImageButton.Position = UDim2.new(0.724731207, 0, 0.753002405, 0)
    ImageButton.Size = UDim2.new(0.0636147112, 0, 0.0661305636, 0)
    ImageButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
    ImageButton.Image = "http://www.roblox.com/asset/?id=182223762"

    local function setupShiftlock(button)
        local players = game:GetService("Players")
        local runservice = game:GetService("RunService")
        local CAS = game:GetService("ContextActionService")
        local player = players.LocalPlayer
        
        local function getChar()
            return player.Character or player.CharacterAdded:Wait()
        end
        
        local uis = game:GetService("UserInputService")
        button.Visible = uis.TouchEnabled
        
        local states = {
            OFF = "rbxasset://textures/ui/mouseLock_off@2x.png",
            ON = "rbxasset://textures/ui/mouseLock_on@2x.png"
        }
        local MAX_LENGTH = 900000
        local active = false
        local ENABLED_OFFSET = CFrame.new(1.7, 0, 0)
        local DISABLED_OFFSET = CFrame.new(-1.7, 0, 0)
        local rootPos = Vector3.new(0,0,0)
        
        local function UpdatePos()
            local char = getChar()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.RootPart then
                rootPos = hum.RootPart.Position
            end
        end
        
        local function UpdateImage(STATE)
            button.Image = states[STATE]
        end
        
        local function UpdateAutoRotate(BOOL)
            local char = getChar()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.AutoRotate = BOOL
            end
        end
        
        local function GetUpdatedCameraCFrame()
            local cam = workspace.CurrentCamera
            if cam then
                return CFrame.new(rootPos, Vector3.new(cam.CFrame.LookVector.X * MAX_LENGTH, rootPos.Y, cam.CFrame.LookVector.Z * MAX_LENGTH))
            end
        end
        
        local function EnableShiftlock()
            UpdatePos()
            UpdateAutoRotate(false)
            UpdateImage("ON")
            local char = getChar()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.RootPart then
                hum.RootPart.CFrame = GetUpdatedCameraCFrame()
            end
            local cam = workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame * ENABLED_OFFSET
            end
        end
        
        local function DisableShiftlock()
            UpdatePos()
            UpdateAutoRotate(true)
            UpdateImage("OFF")
            local cam = workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame * DISABLED_OFFSET
            end
            if typeof(active) == "RBXScriptConnection" then
                active:Disconnect()
                active = false
            end
        end
        
        UpdateImage("OFF")
        active = false
        
        local function ToggleShiftLock()
            if not active then
                active = runservice.RenderStepped:Connect(function()
                    EnableShiftlock()
                end)
            else
                DisableShiftlock()
            end
        end
        
        CAS:BindAction("ShiftLOCK", ToggleShiftLock, false, "On")
        CAS:SetPosition("ShiftLOCK", UDim2.new(0.8, 0, 0.8, 0))
        
        button.MouseButton1Click:Connect(function()
            ToggleShiftLock()
        end)
    end

    task.spawn(setupShiftlock, ImageButton)

    local function hookRagdollValue(char)
        local ragdollVal = char:WaitForChild("Ragdolled", 10)
        if not ragdollVal then return end

        ragdollVal.Changed:Connect(function(newVal)
            if newVal == true then
                char:SetAttribute("ignore_ragdolled", true)
                task.defer(function()
                    if ragdollVal and ragdollVal.Parent then
                        ragdollVal.Value = false
                    end
                end)
            end
        end)
    end

    local function setupRagdoll(char)
        char:SetAttribute("ignore_ragdolled", true)

        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end

        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)

        task.spawn(hookRagdollValue, char)

        local motorSnapshot = {}
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("Motor6D") then
                motorSnapshot[v.Name] = {
                    part0  = v.Part0,
                    part1  = v.Part1,
                    c0     = v.C0,
                    c1     = v.C1,
                    parent = v.Parent,
                }
            end
        end

        char.DescendantAdded:Connect(function(v)
            if v:IsA("Motor6D") and not motorSnapshot[v.Name] then
                task.defer(function()
                    if v and v.Parent then
                        motorSnapshot[v.Name] = {
                            part0  = v.Part0,
                            part1  = v.Part1,
                            c0     = v.C0,
                            c1     = v.C1,
                            parent = v.Parent,
                        }
                    end
                end)
            end
        end)

        local conn
        conn = RunService.Stepped:Connect(function()
            if not char or not char.Parent then
                conn:Disconnect()
                return
            end

            char:SetAttribute("ignore_ragdolled", true)

            local ragVal = char:FindFirstChild("Ragdolled")
            if ragVal and ragVal:IsA("BoolValue") and ragVal.Value then
                ragVal.Value = false
            end

            if hum.PlatformStand then
                hum.PlatformStand = false
            end

            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.GettingUp then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end

            for name, data in pairs(motorSnapshot) do
                local existing = char:FindFirstChild(name, true)
                if existing and existing:IsA("Motor6D") then
                    if not existing.Enabled then
                        existing.Enabled = true
                    end
                else
                    if data.part0 and data.part0.Parent
                    and data.part1 and data.part1.Parent
                    and data.parent and data.parent.Parent then
                        local nj = Instance.new("Motor6D")
                        nj.Name   = name
                        nj.Part0  = data.part0
                        nj.Part1  = data.part1
                        nj.C0     = data.c0
                        nj.C1     = data.c1
                        nj.Parent = data.parent
                    end
                end
            end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if hrp.Anchored then
                    hrp.Anchored = false
                end
                local vel = hrp.AssemblyLinearVelocity
                local hSpeed = Vector2.new(vel.X, vel.Z).Magnitude
                if hSpeed > 80 then
                    local ratio = 80 / hSpeed
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        vel.X * ratio,
                        vel.Y,
                        vel.Z * ratio
                    )
                end
            end
        end)

        local function checkAndAnchor(v)
            if v.Name == "Ragdollballsocket" or (v:IsA("BallSocketConstraint") and v.Name:lower():find("ragdoll")) then
                local part = v.Parent
                if part and part:IsA("BasePart") then
                    part.Anchored = true
                    task.delay(0.5, function()
                        if part and part.Parent then
                            part.Anchored = false
                        end
                    end)
                end
            end
        end

        for _, descendant in ipairs(char:GetDescendants()) do
            checkAndAnchor(descendant)
        end

        char.DescendantAdded:Connect(function(v)
            checkAndAnchor(v)
            if v.Name == "Ragdolled" and v:IsA("BoolValue") then
                task.spawn(hookRagdollValue, char)
            end
        end)
    end

    if LocalPlayer.Character then
        task.spawn(setupRagdoll, LocalPlayer.Character)
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 10)
        task.spawn(setupRagdoll, char)
    end)
end

local function startAntiRagdoll()
    antiRagdollActive = true
    antiRagdollBtn.Text = "Anti-Ragdoll: ON"
    TweenService:Create(antiRagdollBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 160, 60)}):Play()
    runAntiRagdollScript()
end

local function startAutofarm(targetPlayer)
    if not isDualEquipped() then
        sendNotification("Make sure to equip Dual before starting autofarm.")
        stopAutofarm()
        return
    end

    autofarmActive = true
    dualAutofarmBtn.Text = "Dual Autofarm: WAITING..."
    TweenService:Create(dualAutofarmBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 140, 30)}):Play()

    local lobby = Workspace:FindFirstChild("Lobby")
    local tele1 = lobby and lobby:FindFirstChild("Teleport1")
    local myRoot = getRoot()

    if tele1 and myRoot then
        myRoot.CFrame = tele1.CFrame * CFrame.new(0, 3, 0)
    end

    task.wait(1)

    if not autofarmActive then return end

    dualAutofarmBtn.Text = "Dual Autofarm: ON"
    TweenService:Create(dualAutofarmBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 160, 60)}):Play()

    autofarmConnection = RunService.Heartbeat:Connect(function()
        if not autofarmActive then return end

        local currentRoot = getRoot()
        local targetChar = targetPlayer and targetPlayer.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

        if currentRoot and targetRoot and targetHum and targetHum.Health > 0 then
            currentRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            currentRoot.AssemblyLinearVelocity = Vector3.zero
        elseif targetHum and targetHum.Health <= 0 then
            stopAutofarm()
            sendNotification("Target died. Autofarm paused.")
        end
    end)

    autofarmHitThread = task.spawn(function()
        while autofarmActive do
            local targetChar = targetPlayer and targetPlayer.Character
            if targetChar and DualHit then
                local targetPart = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    DualHit:FireServer(targetPart, true)
                end
            end
            task.wait(1.5)
        end
    end)
end

local function handleBaseplateClick()
    local myRoot = getRoot()
    if not myRoot then return end

    if not baseplateCreated or not baseplatePart or not baseplatePart.Parent then
        baseplatePart = Instance.new("Part")
        baseplatePart.Name = "FarmBaseplate"
        baseplatePart.Size = Vector3.new(2048, 5, 2048)
        baseplatePart.Position = Vector3.new(0, 1000, 0)
        baseplatePart.Anchored = true
        baseplatePart.Material = Enum.Material.SmoothPlastic
        baseplatePart.Color = Color3.fromRGB(50, 50, 55)
        baseplatePart.Parent = Workspace
        baseplateCreated = true

        mainBaseplateBtn.Text = "Teleport to baseplate"
        altBaseplateBtn.Text = "Teleport to baseplate"
        sendNotification("Massive baseplate created!")
    else
        myRoot.CFrame = baseplatePart.CFrame * CFrame.new(0, 5, 0)
        sendNotification("Teleported to baseplate.")
    end
end

mainBaseplateBtn.MouseButton1Click:Connect(handleBaseplateClick)
altBaseplateBtn.MouseButton1Click:Connect(handleBaseplateClick)

antiRagdollBtn.MouseButton1Click:Connect(function()
    if not antiRagdollActive then
        startAntiRagdoll()
    end
end)

hamburgerBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    if warningFrame.Visible or not hasSavedPreference() then
        warningFrame.Visible = uiVisible
    else
        mainFrame.Visible = uiVisible
    end
end)

dualAutofarmBtn.MouseButton1Click:Connect(function()
    if autofarmActive then
        stopAutofarm()
    else
        local foundPlayer = findTargetPlayer(targetTextBox.Text)
        if not foundPlayer then
            sendNotification("Target not found. Enter valid username.")
            return
        end
        task.spawn(function()
            startAutofarm(foundPlayer)
        end)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    confirmOverlay.Visible = true
end)

confirmNoBtn.MouseButton1Click:Connect(function()
    confirmOverlay.Visible = false
end)

confirmYesBtn.MouseButton1Click:Connect(function()
    stopAutofarm()
    screenGui:Destroy()
end)

dontShowBtn.MouseButton1Click:Connect(function()
    dontShowBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
    savePreference()
end)

continueBtn.MouseButton1Click:Connect(function()
    warningFrame.Visible = false
    mainFrame.Visible = true
end)

if hasSavedPreference() then
    mainFrame.Visible = true
else
    warningFrame.Visible = true
end
