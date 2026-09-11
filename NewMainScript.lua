local players = game:GetService('Players')
local inputService = game:GetService('UserInputService')
local runService = game:GetService('RunService')
local tweenService = game:GetService('TweenService')
local httpService = game:GetService('HttpService')
local lplr = players.LocalPlayer
local playerGui = lplr:WaitForChild('PlayerGui')

local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
    writefile(file, '')
end

local BASE = 'https://raw.githubusercontent.com/complexwaremain/FlowVape/main/'

local function wipeFolder(path)
    if not isfolder(path) then return end
    for _, file in listfiles(path) do
        if file:find('loader') then continue end
        if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
            delfile(file)
        end
    end
end

local function setupFolders()
    for _, folder in {
        'FlowVape',
        'FlowVape/games',
        'FlowVape/profiles',
        'FlowVape/profilesmobile',
        'FlowVape/assets',
        'FlowVape/assets/new',
        'FlowVape/libraries',
        'FlowVape/guis',
    } do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
end

local function handleCommit()
    if shared.VapeDeveloper then return end
    local _, subbed = pcall(function()
        return game:HttpGet('https://github.com/complexwaremain/FlowVape')
    end)
    local commit = subbed and subbed:find('currentOid') or nil
    commit = commit and subbed:sub(commit + 13, commit + 52) or nil
    commit = commit and #commit == 40 and commit or 'main'
    if commit == 'main' or (isfile('FlowVape/profiles/commit.txt') and readfile('FlowVape/profiles/commit.txt') or '') ~= commit then
        wipeFolder('FlowVape')
        wipeFolder('FlowVape/games')
        wipeFolder('FlowVape/guis')
        wipeFolder('FlowVape/libraries')
        wipeFolder('FlowVape/profiles')
        wipeFolder('FlowVape/profilesmobile')
        wipeFolder('FlowVape/assets/new')
    end
    pcall(writefile, 'FlowVape/profiles/commit.txt', commit)
end

local SHARED_FILES = {
    'gui.txt',
    'commit.txt',
    '2619619496.gui.txt',
    'default6872274481.txt',
    'default6872265039.txt',
}

local PC_PROFILES = {
    'legit6872274481.txt',
    'blatant6872274481.txt',
    'legit6872265039.txt',
    'blatant6872265039.txt',
}

local MOB_PROFILES = {
    'legitMob6872274481.txt',
    'blatantMob6872274481.txt',
    'legitMob6872265039.txt',
    'blatantMob6872265039.txt',
}

local GAME_FILES = {
    '6872274481.lua',
    '6872265039.lua',
    '8560631822.lua',
    '8444591321.lua',
}

local function dlFile(url, dest)
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if ok and data and data ~= '404: Not Found' then
        pcall(writefile, dest, data)
    end
end

local function clearProfiles(isMobile)
    local allowed = {}
    for _, f in ipairs(SHARED_FILES) do allowed[f] = true end
    if isMobile then
        for _, f in ipairs(MOB_PROFILES) do allowed[f] = true end
    else
        for _, f in ipairs(PC_PROFILES) do allowed[f] = true end
    end

    if isfolder('FlowVape/profiles') then
        for _, file in ipairs(listfiles('FlowVape/profiles')) do
            local fname = file:match('[^/\\]+$')
            if fname and fname:sub(-4) == '.txt' and not allowed[fname] then
                pcall(delfile, file)
            end
        end
    end
end

local function downloadProfiles(isMobile)
    clearProfiles(isMobile)

    for i = 1, #SHARED_FILES do
        dlFile(BASE..'profiles/'..SHARED_FILES[i], 'FlowVape/profiles/'..SHARED_FILES[i])
    end

    if isMobile then
        for i = 1, #MOB_PROFILES do
            dlFile(BASE..'profilesmobile/'..MOB_PROFILES[i], 'FlowVape/profiles/'..MOB_PROFILES[i])
        end
    else
        for i = 1, #PC_PROFILES do
            dlFile(BASE..'profiles/'..PC_PROFILES[i], 'FlowVape/profiles/'..PC_PROFILES[i])
        end
    end
end

local function downloadGames()
    for i = 1, #GAME_FILES do
        dlFile(BASE..'games/'..GAME_FILES[i], 'FlowVape/games/'..GAME_FILES[i])
    end
end

local function downloadAssets()
    if not isfolder('FlowVape/assets/new') then
        makefolder('FlowVape/assets/new')
    end
    local ok, response = pcall(function()
        return game:HttpGet('https://api.github.com/repos/complexwaremain/FlowVape/contents/assets/new?ref=main')
    end)
    if not ok or not response then return end
    local files = {}
    local decOk, decoded = pcall(function()
        return httpService:JSONDecode(response)
    end)
    if decOk and type(decoded) == 'table' then
        for _, f in ipairs(decoded) do
            if f.type == 'file' and f.name and f.download_url then
                table.insert(files, {name = f.name, url = f.download_url})
            end
        end
    end
    for _, f in ipairs(files) do
        dlFile(f.url, 'FlowVape/assets/new/'..f.name)
    end
end

local function runLoad(isMobile, statusLabel)
    setupFolders()
    if statusLabel then statusLabel.Text = 'Checking for updates...' end
    task.wait(0.2)
    handleCommit()
    if statusLabel then statusLabel.Text = 'Downloading profiles...' end
    task.wait(0.1)
    downloadProfiles(isMobile)
    if statusLabel then statusLabel.Text = 'Downloading game scripts...' end
    task.wait(0.1)
    downloadGames()
    if statusLabel then statusLabel.Text = 'Downloading assets...' end
    task.wait(0.1)
    downloadAssets()
    if statusLabel then statusLabel.Text = 'Loading FlowVape...' end
    task.wait(0.2)
    shared.FlowVapeIsMobile = isMobile
    local maincontent = game:HttpGet(BASE..'main.lua')
    pcall(writefile, 'FlowVape/main.lua', maincontent)
    local func, err = loadstring(maincontent, 'main')
    if not func then
        return false, 'Syntax error in main.lua: '..tostring(err)
    end
    task.spawn(func)
    return true
end

setupFolders()

if isfile('FlowVape/device.txt') then
    local saved = readfile('FlowVape/device.txt')
    local isMobile = saved == 'mobile'
    local ok, err = runLoad(isMobile, nil)
    if ok then
        if shared.vape then
            shared.vape:CreateNotification('FlowVape', 'Loaded - thanks for using FlowVape!', 2)
        end
    else
        warn('[FlowVape] Load error: '..tostring(err))
    end
    return
end

local sg = Instance.new('ScreenGui')
sg.Name = 'FlowVapeInstaller'
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.Parent = playerGui

local card = Instance.new('Frame')
card.Name = 'Card'
card.Size = UDim2.fromOffset(280, 210)
card.Position = UDim2.fromScale(0.5, 0.5)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.BackgroundColor3 = Color3.fromRGB(18, 17, 19)
card.BorderSizePixel = 0
card.Parent = sg
Instance.new('UICorner', card).CornerRadius = UDim.new(0, 14)
local cardStroke = Instance.new('UIStroke', card)
cardStroke.Color = Color3.fromRGB(45, 43, 48)
cardStroke.Thickness = 1

local topbar = Instance.new('Frame')
topbar.Size = UDim2.new(1, 0, 0, 38)
topbar.BackgroundColor3 = Color3.fromRGB(13, 12, 14)
topbar.BorderSizePixel = 0
topbar.Parent = card
Instance.new('UICorner', topbar).CornerRadius = UDim.new(0, 14)
local tbFix = Instance.new('Frame')
tbFix.Size = UDim2.new(1, 0, 0.5, 0)
tbFix.Position = UDim2.fromScale(0, 0.5)
tbFix.BackgroundColor3 = Color3.fromRGB(13, 12, 14)
tbFix.BorderSizePixel = 0
tbFix.Parent = topbar

local titleLabel = Instance.new('TextLabel')
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = 'FlowVape'
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = topbar

local dot = Instance.new('Frame')
dot.Size = UDim2.fromOffset(10, 10)
dot.Position = UDim2.new(1, -14, 0.5, 0)
dot.AnchorPoint = Vector2.new(1, 0.5)
dot.BackgroundColor3 = Color3.fromRGB(55, 53, 58)
dot.BorderSizePixel = 0
dot.Parent = topbar
Instance.new('UICorner', dot).CornerRadius = UDim.new(1, 0)

local rainbow = Instance.new('Frame')
rainbow.Size = UDim2.new(1, 0, 0, 2)
rainbow.Position = UDim2.new(0, 0, 1, -2)
rainbow.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
rainbow.BorderSizePixel = 0
rainbow.Parent = topbar
local grad = Instance.new('UIGradient', rainbow)
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(248, 113, 113)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(96, 165, 250)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(192, 132, 252)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 113, 113)),
})

local body = Instance.new('Frame')
body.Size = UDim2.new(1, 0, 1, -38)
body.Position = UDim2.fromOffset(0, 38)
body.BackgroundTransparency = 1
body.Parent = card

local mainTitle = Instance.new('TextLabel')
mainTitle.Size = UDim2.new(1, 0, 0, 24)
mainTitle.Position = UDim2.fromOffset(0, 14)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = 'Choose your device'
mainTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
mainTitle.TextSize = 14
mainTitle.Font = Enum.Font.GothamSemibold
mainTitle.Parent = body

local subTitle = Instance.new('TextLabel')
subTitle.Size = UDim2.new(1, 0, 0, 18)
subTitle.Position = UDim2.fromOffset(0, 36)
subTitle.BackgroundTransparency = 1
subTitle.Text = 'Select the platform you are on'
subTitle.TextColor3 = Color3.fromRGB(100, 98, 105)
subTitle.TextSize = 11
subTitle.Font = Enum.Font.Gotham
subTitle.Parent = body

local function makeBtn(name, desc, icon, xOffset, accentColor)
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.fromOffset(118, 90)
    btn.Position = UDim2.fromOffset(xOffset, 62)
    btn.BackgroundColor3 = Color3.fromRGB(23, 22, 25)
    btn.BorderSizePixel = 0
    btn.Text = ''
    btn.AutoButtonColor = false
    btn.Parent = body
    Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 10)
    local s = Instance.new('UIStroke', btn)
    s.Color = Color3.fromRGB(40, 38, 44)
    s.Thickness = 1
    local accent = Instance.new('Frame')
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.Position = UDim2.new(0, 0, 1, -2)
    accent.BackgroundColor3 = accentColor
    accent.BorderSizePixel = 0
    accent.Parent = btn
    Instance.new('UICorner', accent).CornerRadius = UDim.new(0, 10)
    local ic = Instance.new('TextLabel')
    ic.Size = UDim2.new(1, 0, 0, 36)
    ic.Position = UDim2.fromOffset(0, 10)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 28
    ic.Font = Enum.Font.Gotham
    ic.Parent = btn
    local nl = Instance.new('TextLabel')
    nl.Size = UDim2.new(1, 0, 0, 18)
    nl.Position = UDim2.fromOffset(0, 50)
    nl.BackgroundTransparency = 1
    nl.Text = name
    nl.TextColor3 = Color3.fromRGB(200, 200, 200)
    nl.TextSize = 13
    nl.Font = Enum.Font.GothamSemibold
    nl.Parent = btn
    local dl = Instance.new('TextLabel')
    dl.Size = UDim2.new(1, 0, 0, 14)
    dl.Position = UDim2.fromOffset(0, 68)
    dl.BackgroundTransparency = 1
    dl.Text = desc
    dl.TextColor3 = Color3.fromRGB(90, 88, 95)
    dl.TextSize = 10
    dl.Font = Enum.Font.Gotham
    dl.Parent = btn
    btn.MouseEnter:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28, 27, 31)}):Play()
        tweenService:Create(s, TweenInfo.new(0.12), {Color = accentColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(23, 22, 25)}):Play()
        tweenService:Create(s, TweenInfo.new(0.12), {Color = Color3.fromRGB(40, 38, 44)}):Play()
    end)
    return btn, s
end

local pcBtn, pcStroke = makeBtn('PC', 'Windows / Mac', 'PC', 14, Color3.fromRGB(96, 165, 250))
local mobBtn, mobStroke = makeBtn('Mobile', 'iOS / Android', 'MOB', 148, Color3.fromRGB(74, 222, 128))

local statusLabel = Instance.new('TextLabel')
statusLabel.Size = UDim2.new(1, -28, 0, 16)
statusLabel.Position = UDim2.new(0, 14, 1, -30)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ''
statusLabel.TextColor3 = Color3.fromRGB(120, 118, 125)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = body

local hue = 0
local rainbowConn = runService.RenderStepped:Connect(function()
    hue = (hue + 0.003) % 1
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, 0.8, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV((hue + 0.33) % 1, 0.8, 1)),
        ColorSequenceKeypoint.new(0.66, Color3.fromHSV((hue + 0.66) % 1, 0.8, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 0.8, 1)),
    })
end)

local dragging = false
local dragStart, startPos
topbar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = card.Position
    end
end)
inputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        card.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
    end
end)
inputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local function load(isMobile)
    pcBtn.Active = false
    mobBtn.Active = false
    statusLabel.Text = 'Setting up folders...'
    statusLabel.TextColor3 = Color3.fromRGB(120, 118, 125)
    task.wait(0.2)

    local ok, err = runLoad(isMobile, statusLabel)

    if ok then
        pcall(writefile, 'FlowVape/device.txt', isMobile and 'mobile' or 'pc')
        statusLabel.Text = 'Loaded!'
        statusLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
        task.wait(0.5)
        rainbowConn:Disconnect()
        sg:Destroy()
        task.wait(0.3)
        if shared.vape then
            shared.vape:CreateNotification('FlowVape', 'Loaded - thanks for using FlowVape!', 2)
        end
    else
        statusLabel.Text = 'Error: '..tostring(err):sub(1, 50)
        statusLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
        pcBtn.Active = true
        mobBtn.Active = true
    end
end

pcBtn.MouseButton1Click:Connect(function() load(false) end)
mobBtn.MouseButton1Click:Connect(function() load(true) end)
