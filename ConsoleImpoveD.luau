local CoreGui = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local TopBarApp = CoreGui:WaitForChild("TopBarApp"):WaitForChild("TopBarApp")
local UnibarLeftFrame = TopBarApp:WaitForChild("UnibarLeftFrame")
local UnibarMenu = UnibarLeftFrame:WaitForChild("UnibarMenu")
local sausageHolder = UnibarMenu:WaitForChild("2")

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local trackedSize = sausageHolder.Size.X.Offset
local ConsoleButton = nil
local sizeConnection = nil
local childAddedConnection = nil
local childRemovedConnection = nil

local function buildButton()
    if ConsoleButton then
        ConsoleButton:Destroy()
        ConsoleButton = nil
    end

    local btn = Instance.new("TextButton")
    btn.Text = ">_"
    btn.Font = Enum.Font.BuilderSansBold
    btn.TextSize = 20
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.Position = UDim2.new(0, trackedSize + 18, 0.5, 0)
    btn.BackgroundTransparency = 1
    btn.BackgroundColor3 = Color3.new(1, 1, 1)
    btn.ClipsDescendants = false
    btn.Parent = sausageHolder

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = btn

    local function setHighlight(t)
        TweenService:Create(btn, tweenInfo, {BackgroundTransparency = t}):Play()
    end

    btn.MouseEnter:Connect(function() setHighlight(0.75) end)
    btn.MouseLeave:Connect(function() setHighlight(1) end)
    btn.MouseButton1Down:Connect(function() setHighlight(0.5) end)
    btn.MouseButton1Up:Connect(function() setHighlight(0.75) end)

    btn.MouseButton1Click:Connect(function()
        if keypress and keyrelease then
            keypress(0x78)
            task.wait(0.01)
            keyrelease(0x78)
        end
    end)

    ConsoleButton = btn
end

local function applyHolderSize()
    sausageHolder.ClipsDescendants = true
    sausageHolder.Size = UDim2.new(0, trackedSize + 48, 0, sausageHolder.Size.Y.Offset)
end

local function connectSignals()
end

local function disconnectSignals()
    if sizeConnection then
        sizeConnection:Disconnect()
        sizeConnection = nil
    end
    if childAddedConnection then
        childAddedConnection:Disconnect()
        childAddedConnection = nil
    end
    if childRemovedConnection then
        childRemovedConnection:Disconnect()
        childRemovedConnection = nil
    end
end

local function rebuild(newSize)
    disconnectSignals()
    trackedSize = newSize
    buildButton()
    applyHolderSize()
    task.delay(0.1, connectSignals)
end

connectSignals = function()
    sizeConnection = sausageHolder:GetPropertyChangedSignal("Size"):Connect(function()
        local current = sausageHolder.Size.X.Offset
        if current ~= trackedSize + 48 then
            rebuild(current)
        end
    end)

    childAddedConnection = sausageHolder.ChildAdded:Connect(function(child)
        if child == ConsoleButton then return end
        local current = sausageHolder.Size.X.Offset
        rebuild(current ~= trackedSize + 48 and current or trackedSize)
    end)

    childRemovedConnection = sausageHolder.ChildRemoved:Connect(function(child)
        if child == ConsoleButton then return end
        local current = sausageHolder.Size.X.Offset
        rebuild(current ~= trackedSize + 48 and current or trackedSize)
    end)
end

buildButton()
applyHolderSize()
connectSignals()


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

	local function makeButton(name, text, bgColor, anchorX, anchorY, posXScale, posXOffset, posYScale, posYOffset)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Text = text
		btn.Size = UDim2.new(0, 36, 0, 16)
		btn.AnchorPoint = Vector2.new(anchorX, anchorY)
		btn.Position = UDim2.new(posXScale, posXOffset, posYScale, posYOffset)
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

	local copyBtn = makeButton("__CopyBtn", "Copy", Color3.fromRGB(50, 50, 50), 1, 0.5, 1, -6, 0.5, 0)

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

local cmdbarCollapsed = false
local cmdbarFrame = nil
local collapseBtn = nil
local collapsedBtn = nil

local function createCmdbar(parentWindow)
	if parentWindow:FindFirstChild("CmdbarFrame") then return end

	cmdbarFrame = Instance.new("Frame")
	cmdbarFrame.Name = "CmdbarFrame"
	cmdbarFrame.Size = UDim2.new(1, 0, 0, 32)
	cmdbarFrame.Position = UDim2.new(0, 0, 1, -32)
	cmdbarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	cmdbarFrame.BorderSizePixel = 0
	cmdbarFrame.ZIndex = 1000000000
	cmdbarFrame.Parent = parentWindow

	local leftAccent = Instance.new("Frame")
	leftAccent.Name = "LeftAccent"
	leftAccent.Size = UDim2.new(0, 3, 1, 0)
	leftAccent.Position = UDim2.new(0, 0, 0, 0)
	leftAccent.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
	leftAccent.BorderSizePixel = 0
	leftAccent.ZIndex = 1000000001
	leftAccent.Parent = cmdbarFrame

	local prompt = Instance.new("TextLabel")
	prompt.Name = "Prompt"
	prompt.Size = UDim2.new(0, 22, 1, 0)
	prompt.Position = UDim2.new(0, 10, 0, 0)
	prompt.BackgroundTransparency = 1
	prompt.Text = ">"
	prompt.TextColor3 = Color3.fromRGB(180, 180, 180)
	prompt.TextSize = 14
	prompt.Font = Enum.Font.RobotoMono
	prompt.TextXAlignment = Enum.TextXAlignment.Left
	prompt.ZIndex = 1000000001
	prompt.Parent = cmdbarFrame

	local inputBox = Instance.new("TextBox")
	inputBox.Name = "Cmdbar"
	inputBox.Size = UDim2.new(1, -80, 1, -8)
	inputBox.Position = UDim2.new(0, 30, 0, 4)
	inputBox.BackgroundTransparency = 1
	inputBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	inputBox.PlaceholderText = "command line"
	inputBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
	inputBox.Text = ""
	inputBox.TextSize = 14
	inputBox.Font = Enum.Font.RobotoMono
	inputBox.BorderSizePixel = 0
	inputBox.ClearTextOnFocus = false
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.ZIndex = 1000000001
	inputBox.Parent = cmdbarFrame

	local function executeCommand()
		local cmd = inputBox.Text
		if cmd == "" then return end
		print(">" .. cmd)
		loadstring(cmd)()
		inputBox.Text = ""
	end

	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			executeCommand()
		end
	end)

	collapseBtn = Instance.new("TextButton")
	collapseBtn.Name = "CollapseBtn"
	collapseBtn.Text = "V"
	collapseBtn.Size = UDim2.new(0, 28, 0, 18)
	collapseBtn.AnchorPoint = Vector2.new(0.5, 1)
	collapseBtn.Position = UDim2.new(0.5, 0, 0, -4)
	collapseBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
	collapseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	collapseBtn.BorderSizePixel = 0
	collapseBtn.TextSize = 10
	collapseBtn.Font = Enum.Font.GothamBold
	collapseBtn.ZIndex = 1000000002
	collapseBtn.Parent = cmdbarFrame

	local collapseBtnCorner = Instance.new("UICorner")
	collapseBtnCorner.CornerRadius = UDim.new(0, 4)
	collapseBtnCorner.Parent = collapseBtn

	collapsedBtn = Instance.new("TextButton")
	collapsedBtn.Name = "CollapsedBtn"
	collapsedBtn.Text = "Ʌ"
	collapsedBtn.Size = UDim2.new(0, 52, 0, 22)
	collapsedBtn.AnchorPoint = Vector2.new(0.5, 1)
	collapsedBtn.Position = UDim2.new(0.5, 0, 1, -4)
	collapsedBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	collapsedBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	collapsedBtn.BorderSizePixel = 0
	collapsedBtn.TextSize = 11
	collapsedBtn.Font = Enum.Font.GothamBold
	collapsedBtn.ZIndex = 1000000002
	collapsedBtn.Visible = false
	collapsedBtn.Parent = parentWindow

	local collapsedCorner = Instance.new("UICorner")
	collapsedCorner.CornerRadius = UDim.new(0, 5)
	collapsedCorner.Parent = collapsedBtn

	collapseBtn.MouseButton1Click:Connect(function()
		cmdbarCollapsed = true
		cmdbarFrame.Visible = false
		collapsedBtn.Visible = true
	end)

	collapsedBtn.MouseButton1Click:Connect(function()
		cmdbarCollapsed = false
		cmdbarFrame.Visible = true
		collapsedBtn.Visible = false
	end)
end

local saveBtn = nil

local function createSaveButton(parentWindow)
	if parentWindow:FindFirstChild("__SaveLogsBtn") then return end

	local btn = Instance.new("TextButton")
	btn.Name = "__SaveLogsBtn"
	btn.Text = "Save Logs"
	btn.Size = UDim2.new(0, 72, 0, 18)
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.Position = UDim2.new(0.5, 170, 0, 15)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 1000000000
	btn.Parent = parentWindow

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
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
					btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
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
				btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			end
		end)
	end)

	game:GetService("RunService").Heartbeat:Connect(function()
		if not btn or not btn.Parent then return end
		local devConsole = game:GetService("CoreGui"):FindFirstChild("DevConsoleMaster")
		if not devConsole then return end
		local mbLabel = nil
		for _, v in pairs(devConsole:GetDescendants()) do
			if v:IsA("TextLabel") and v.Text:match("MB") then
				mbLabel = v
				break
			end
		end
		if mbLabel then
			local absRight = mbLabel.AbsolutePosition.X + mbLabel.AbsoluteSize.X
			local windowAbsX = parentWindow.AbsolutePosition.X
			local localRight = absRight - windowAbsX
			btn.Position = UDim2.new(0, localRight + 8, 0, 6)
		end
	end)
end

local wasVisible = false

local function checkConsoleState()
	local devConsole = game:GetService("CoreGui"):FindFirstChild("DevConsoleMaster")
	if devConsole then
		local devConsoleWindow = devConsole:FindFirstChild("DevConsoleWindow")
		if devConsoleWindow then
			local isVisible = devConsoleWindow.Visible

			if isVisible and not wasVisible then
				wasVisible = true
				createCmdbar(devConsoleWindow)
				createSaveButton(devConsoleWindow)
				if cmdbarFrame then
					cmdbarFrame.Visible = not cmdbarCollapsed
				end
				if collapsedBtn then
					collapsedBtn.Visible = cmdbarCollapsed
				end
				for _, v in pairs(devConsole:GetDescendants()) do
					tryAdd(v)
				end
			elseif not isVisible and wasVisible then
				wasVisible = false
				if cmdbarFrame then
					cmdbarFrame.Visible = false
				end
				if collapsedBtn then
					collapsedBtn.Visible = false
				end
			end
		end
	end
end

game:GetService("RunService").Heartbeat:Connect(checkConsoleState)

game:GetService("CoreGui").DescendantAdded:Connect(function(v)
	task.wait()
	tryAdd(v)
end)
