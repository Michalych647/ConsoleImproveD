local CoreGui = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local TopBarApp = CoreGui:WaitForChild("TopBarApp"):WaitForChild("TopBarApp")
local UnibarLeftFrame = TopBarApp:WaitForChild("UnibarLeftFrame")
local UnibarMenu = UnibarLeftFrame:WaitForChild("UnibarMenu")
local sausageHolder = UnibarMenu:WaitForChild("2")

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local trackedSize = sausageHolder.Size.X.Offset
local ConsoleButton = nil
local sizeConnection = nil
local childAddedConnection = nil
local childRemovedConnection = nil
local steppedConnection = nil

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

local function disconnectStepped()
	if steppedConnection then
		steppedConnection:Disconnect()
		steppedConnection = nil
	end
end

local function rebuild(newSize)
	disconnectSignals()
	trackedSize = newSize
	buildButton()
	applyHolderSize()
	task.delay(0.1, connectSignals)
end

local function connectStepped()
	disconnectStepped()
	steppedConnection = RunService.Stepped:Connect(function()
		if not ConsoleButton or not ConsoleButton.Parent then
			return
		end

		sausageHolder.ClipsDescendants = true
		sausageHolder.Size = UDim2.new(0, trackedSize + 48, 0, sausageHolder.Size.Y.Offset)
		ConsoleButton.Position = UDim2.new(0, trackedSize + 18, 0.5, 0)
	end)
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
connectStepped()


local processedLabels = {}
local collectedLogs = {}

local runService = game:GetService("RunService")
local stats = game:GetService("Stats")

local function getPing()
	local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
	local pingNum = ping:match("%d+%.?%d*")
	return tonumber(pingNum) or 0
end

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

	local copyBtn = Instance.new("ImageButton")
	copyBtn.Name = "__CopyBtn"
	copyBtn.Image = "rbxassetid://90434151822042"
	copyBtn.Size = UDim2.new(0, 18, 0, 18)
	copyBtn.AnchorPoint = Vector2.new(1, 0)
	copyBtn.Position = UDim2.new(1, -4, 0, 2)
	copyBtn.BackgroundTransparency = 1
	copyBtn.BorderSizePixel = 0
	copyBtn.ZIndex = 1000000000
	copyBtn.Parent = parent

	local checkLabel = Instance.new("TextLabel")
	checkLabel.Size = UDim2.new(1, 0, 1, 0)
	checkLabel.BackgroundTransparency = 1
	checkLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
	checkLabel.TextSize = 11
	checkLabel.Font = Enum.Font.GothamBold
	checkLabel.Text = ""
	checkLabel.ZIndex = 1000000001
	checkLabel.Visible = false
	checkLabel.Parent = copyBtn

	textLabel.Size = UDim2.new(1, -26, 1, 0)

	copyBtn.MouseButton1Click:Connect(function()
		local logText = cleanLog(textLabel.Text)
		setclipboard(logText)
		copyBtn.Image = ""
		checkLabel.Text = "✓"
		checkLabel.Visible = true
		task.delay(1.5, function()
			if copyBtn then
				copyBtn.Image = "rbxassetid://90434151822042"
				checkLabel.Text = ""
				checkLabel.Visible = false
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
local fpsLabel = nil
local pingLabel = nil
local fpsConnection = nil

local function startFpsPingCounter()
	if fpsConnection then return end
	local lastTime = tick()
	local frameCount = 0
	fpsConnection = runService.RenderStepped:Connect(function()
		frameCount = frameCount + 1
		local now = tick()
		if now - lastTime >= 1 then
			local fps = frameCount / (now - lastTime)
			local ping = getPing()
			if fpsLabel then
				fpsLabel.Text = string.format('<font color="rgb(255,140,0)">FPS: </font><font color="rgb(255,255,255)">%.1f</font>', fps)
			end
			if pingLabel then
				pingLabel.Text = string.format('<font color="rgb(255,140,0)">Ping: </font><font color="rgb(255,255,255)">%dms</font>', ping)
			end
			frameCount = 0
			lastTime = now
		end
	end)
end

local function stopFpsPingCounter()
	if fpsConnection then
		fpsConnection:Disconnect()
		fpsConnection = nil
	end
end

local function createCmdbar(parentWindow)
	if parentWindow:FindFirstChild("CmdbarFrame") then return end

	fpsLabel = Instance.new("TextLabel")
	fpsLabel.Name = "FpsLabel"
	fpsLabel.Size = UDim2.new(0, 90, 0, 24)
	fpsLabel.Position = UDim2.new(0, 514, 0, 38)
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.BorderSizePixel = 0
	fpsLabel.RichText = true
	fpsLabel.TextSize = 14
	fpsLabel.Font = Enum.Font.Code
	fpsLabel.Text = '<font color="rgb(255,140,0)">FPS: </font><font color="rgb(255,255,255)">--</font>'
	fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
	fpsLabel.ZIndex = 1000000000
	fpsLabel.Parent = parentWindow

	pingLabel = Instance.new("TextLabel")
	pingLabel.Name = "PingLabel"
	pingLabel.Size = UDim2.new(0, 110, 0, 24)
	pingLabel.Position = UDim2.new(0, 610, 0, 38)
	pingLabel.BackgroundTransparency = 1
	pingLabel.BorderSizePixel = 0
	pingLabel.RichText = true
	pingLabel.TextSize = 14
	pingLabel.Font = Enum.Font.Code
	pingLabel.Text = '<font color="rgb(255,140,0)">Ping: </font><font color="rgb(255,255,255)">--ms</font>'
	pingLabel.TextXAlignment = Enum.TextXAlignment.Left
	pingLabel.ZIndex = 1000000000
	pingLabel.Parent = parentWindow

	cmdbarFrame = Instance.new("Frame")
	cmdbarFrame.Name = "CmdbarFrame"
	cmdbarFrame.Size = UDim2.new(0, 726, 0, 30)
	cmdbarFrame.Position = UDim2.new(0, 20, 0, 304)
	cmdbarFrame.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
	cmdbarFrame.BorderSizePixel = 0
	cmdbarFrame.ZIndex = 1000000000
	cmdbarFrame.Parent = parentWindow

	local strokeTop = Instance.new("Frame")
	strokeTop.BorderSizePixel = 0
	strokeTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	strokeTop.Size = UDim2.new(0, 726, 0, 2)
	strokeTop.Position = UDim2.new(0, 0, 0, -2)
	strokeTop.ZIndex = 1000000001
	strokeTop.Parent = cmdbarFrame

	local strokeLeft = Instance.new("Frame")
	strokeLeft.BorderSizePixel = 0
	strokeLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	strokeLeft.Size = UDim2.new(0, 2, 0, 32)
	strokeLeft.Position = UDim2.new(0, -2, 0, -2)
	strokeLeft.ZIndex = 1000000001
	strokeLeft.Parent = cmdbarFrame

	local strokeRight = Instance.new("Frame")
	strokeRight.BorderSizePixel = 0
	strokeRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	strokeRight.Size = UDim2.new(0, 2, 0, 32)
	strokeRight.Position = UDim2.new(0, 726, 0, -2)
	strokeRight.ZIndex = 1000000001
	strokeRight.Parent = cmdbarFrame

	local prompt = Instance.new("TextLabel")
	prompt.Name = "Prompt"
	prompt.Size = UDim2.new(0, 20, 1, 0)
	prompt.Position = UDim2.new(0, 6, 0, 0)
	prompt.BackgroundTransparency = 1
	prompt.Text = ">"
	prompt.TextColor3 = Color3.fromRGB(197, 197, 197)
	prompt.TextSize = 15
	prompt.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	prompt.TextXAlignment = Enum.TextXAlignment.Left
	prompt.ZIndex = 1000000002
	prompt.Parent = cmdbarFrame

	local inputBox = Instance.new("TextBox")
	inputBox.Name = "Cmdbar"
	inputBox.Size = UDim2.new(1, -34, 1, 0)
	inputBox.Position = UDim2.new(0, 28, 0, 0)
	inputBox.BackgroundTransparency = 1
	inputBox.TextColor3 = Color3.fromRGB(197, 197, 197)
	inputBox.PlaceholderText = "command line"
	inputBox.PlaceholderColor3 = Color3.fromRGB(210, 210, 210)
	inputBox.Text = ""
	inputBox.TextSize = 15
	inputBox.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	inputBox.BorderSizePixel = 0
	inputBox.ClearTextOnFocus = false
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.TextDirection = Enum.TextDirection.LeftToRight
	inputBox.TextWrapped = true
	inputBox.ZIndex = 1000000002
	inputBox.Parent = cmdbarFrame

	local function executeCommand()
		local cmd = inputBox.Text
		if cmd == "" then return end
		print("> " .. cmd)
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
	collapseBtn.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
	collapseBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
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
	collapsedBtn.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
	collapsedBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
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
				if cmdbarFrame then
					cmdbarFrame.Visible = not cmdbarCollapsed
				end
				if collapsedBtn then
					collapsedBtn.Visible = cmdbarCollapsed
				end
				startFpsPingCounter()
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
				stopFpsPingCounter()
				if fpsLabel then
					fpsLabel.Visible = false
				end
				if pingLabel then
					pingLabel.Visible = false
				end
			end

			if fpsLabel then
				fpsLabel.Visible = isVisible
			end
			if pingLabel then
				pingLabel.Visible = isVisible
			end
		end
	end
end

game:GetService("RunService").Heartbeat:Connect(checkConsoleState)

game:GetService("CoreGui").DescendantAdded:Connect(function(v)
	task.wait()
	tryAdd(v)
end)
