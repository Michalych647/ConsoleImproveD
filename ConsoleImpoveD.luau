local CoreGui = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local TopBarApp = CoreGui:WaitForChild("TopBarApp"):WaitForChild("TopBarApp")
local UnibarLeftFrame = TopBarApp:WaitForChild("UnibarLeftFrame")
local UnibarMenu = UnibarLeftFrame:WaitForChild("UnibarMenu")
local sausageHolder = UnibarMenu:WaitForChild("2")
local originalSize = sausageHolder.Size.X.Offset

local ConsoleButton = Instance.new("TextButton")
ConsoleButton.Text = ">_"
ConsoleButton.Font = Enum.Font.BuilderSansBold
ConsoleButton.TextSize = 20
ConsoleButton.TextColor3 = Color3.new(1, 1, 1)
ConsoleButton.Size = UDim2.new(0, 40, 0, 40)
ConsoleButton.AnchorPoint = Vector2.new(0.5, 0.5)
ConsoleButton.Position = UDim2.new(0, originalSize + 18, 0.5, 0)
ConsoleButton.BackgroundTransparency = 1
ConsoleButton.BackgroundColor3 = Color3.new(1, 1, 1)
ConsoleButton.ClipsDescendants = false
ConsoleButton.Parent = sausageHolder

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = ConsoleButton

sausageHolder.ClipsDescendants = true

sausageHolder.Size = UDim2.new(0, originalSize + 48, 0, sausageHolder.Size.Y.Offset)

game:GetService("RunService").RenderStepped:Connect(function()
    if sausageHolder.Size.X.Offset ~= originalSize + 48 then
        sausageHolder.Size = UDim2.new(0, originalSize + 48, 0, sausageHolder.Size.Y.Offset)
    end
end)

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setHighlight(transparency)
    TweenService:Create(ConsoleButton, tweenInfo, {BackgroundTransparency = transparency}):Play()
end

ConsoleButton.MouseEnter:Connect(function()
    setHighlight(0.75)
end)

ConsoleButton.MouseLeave:Connect(function()
    setHighlight(1)
end)

ConsoleButton.MouseButton1Down:Connect(function()
    setHighlight(0.5)
end)

ConsoleButton.MouseButton1Up:Connect(function()
    setHighlight(0.75)
end)

ConsoleButton.MouseButton1Click:Connect(function()
    if keypress and keyrelease then
        keypress(0x78)
        task.wait(0.01)
        keyrelease(0x78)
    end
end)


local processedLabels = {}
local collectedLogs = {}

local function cleanLog(text)
    local clean = text:gsub("<[^>]+>", "")
    local msg = clean:match("%d+:%d+:%d+ %-%- (.+)")
    return msg and msg:match("^%s*(.-)%s*$") or clean:match("^%s*(.-)%s*$")
end

local function addButtons(textLabel)
    if processedLabels[textLabel] then return end
    if not textLabel.Text:match("%d+:%d+:%d+") then return end

    processedLabels[textLabel] = true

    local parent = textLabel.Parent
    if not parent then return end
    if parent:FindFirstChild("__CopyBtn") then return end

    local function makeButton(name, text, bgColor, posX)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Text = text
        btn.Size = UDim2.new(0, 32, 0, 14)
        btn.Position = UDim2.new(1, posX, 0.5, -7)
        btn.BackgroundColor3 = bgColor
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        btn.TextSize = 9
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 1000000000
        btn.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 3)
        corner.Parent = btn

        return btn
    end

    local copyBtn = makeButton("__CopyBtn", "Copy", Color3.fromRGB(50, 50, 50), -48)

    copyBtn.MouseButton1Click:Connect(function()
        local logText = cleanLog(textLabel.Text)
        setclipboard(logText)
        copyBtn.Text = "✓"
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        task.delay(1.5, function()
            if copyBtn then
                copyBtn.Text = "Copy"
                copyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end)
    end)

    table.insert(collectedLogs, textLabel)
end

local function tryAdd(v)
    if v:IsA("TextLabel") then
        v.RichText = true
        addButtons(v)
        v:GetPropertyChangedSignal("Text"):Connect(function()
            addButtons(v)
        end)
    end
end

local function createCmdbar(parentWindow)
    if parentWindow:FindFirstChild("CmdbarFrame") then return end

    local frame = Instance.new("Frame")
    frame.Name = "CmdbarFrame"
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.Position = UDim2.new(0, 0, 1, -28)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.ZIndex = 1000000000
    frame.Parent = parentWindow

    local inputBox = Instance.new("TextBox")
    inputBox.Name = "Cmdbar"
    inputBox.Size = UDim2.new(1, -12, 1, -6)
    inputBox.Position = UDim2.new(0, 6, 0, 3)
    inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    inputBox.TextColor3 = Color3.fromRGB(230, 230, 230)
    inputBox.PlaceholderText = "Enter command..."
    inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    inputBox.Text = ""
    inputBox.TextSize = 11
    inputBox.Font = Enum.Font.RobotoMono
    inputBox.BorderSizePixel = 0
    inputBox.ClearTextOnFocus = false
    inputBox.ZIndex = 1000000000
    inputBox.Parent = frame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = inputBox

    local function executeCommand()
        local cmd = inputBox.Text
        if cmd == "" then return end
        print("> " .. cmd)
        local ok, err = pcall(function()
            loadstring(cmd)()
        end)
        if not ok then
            warn(err)
        end
        inputBox.Text = ""
    end

    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            executeCommand()
        end
    end)
end

local saveBtn = nil

local function createSaveButton(parentWindow)
    if parentWindow:FindFirstChild("__SaveLogsBtn") then return end

    local btn = Instance.new("TextButton")
    btn.Name = "__SaveLogsBtn"
    btn.Text = "Save Logs"
    btn.Size = UDim2.new(0, 72, 0, 18)
    btn.Position = UDim2.new(0.5, 170, 0, 6)
    btn.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 1000000000
    btn.Parent = parentWindow

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    saveBtn = btn

    btn.MouseButton1Click:Connect(function()
        local lines = {}

        local devConsole = game:GetService("CoreGui"):FindFirstChild("DevConsoleMaster")
        if devConsole then
            for _, v in pairs(devConsole:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text:match("%d+:%d+:%d+") then
                    local cleaned = cleanLog(v.Text)
                    if cleaned and cleaned ~= "" then
                        table.insert(lines, cleaned)
                    end
                end
            end
        end

        if #lines == 0 then
            btn.Text = "Empty!"
            btn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            task.delay(1.5, function()
                if btn then
                    btn.Text = "Save Logs"
                    btn.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
                end
            end)
            return
        end

        local content = table.concat(lines, "\n")
        local folderName = "Console Logs"
        local fileName = folderName .. "/logs.txt"

        if not isfolder(folderName) then
            makefolder(folderName)
        end

        writefile(fileName, content)

        btn.Text = "Saved ✓"
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        task.delay(1.5, function()
            if btn then
                btn.Text = "Save Logs"
                btn.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
            end
        end)
    end)
end

local function checkConsoleState()
    local devConsole = game:GetService("CoreGui"):FindFirstChild("DevConsoleMaster")
    if devConsole then
        local devConsoleWindow = devConsole:FindFirstChild("DevConsoleWindow")
        if devConsoleWindow and devConsoleWindow.Visible then
            createCmdbar(devConsoleWindow)
            createSaveButton(devConsoleWindow)
            for _, v in pairs(devConsole:GetDescendants()) do
                tryAdd(v)
            end
        end
    end
end

game:GetService("RunService").Heartbeat:Connect(checkConsoleState)

game:GetService("CoreGui").DescendantAdded:Connect(function(v)
    task.wait()
    tryAdd(v)
end)