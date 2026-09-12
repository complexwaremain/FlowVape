local players = game:GetService('Players')
local coreGui = game:GetService('CoreGui')
local playerGui = players.LocalPlayer:WaitForChild('PlayerGui')

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'FlowVapeReinstallerNotif'
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 99999
pcall(function() screenGui.Parent = coreGui end)
if not screenGui.Parent then screenGui.Parent = playerGui end

local notifFrame = Instance.new('Frame')
notifFrame.Size = UDim2.fromOffset(260, 70)
notifFrame.Position = UDim2.new(1, -280, 1, -90)
notifFrame.BackgroundColor3 = Color3.fromRGB(18, 17, 19)
notifFrame.BackgroundTransparency = 0.1
notifFrame.BorderSizePixel = 0
notifFrame.Parent = screenGui

local notifCorner = Instance.new('UICorner')
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = notifFrame

local stroke = Instance.new('UIStroke')
stroke.Color = Color3.fromRGB(96, 165, 250)
stroke.Thickness = 1.5
stroke.Parent = notifFrame

local notifLabel = Instance.new('TextLabel')
notifLabel.Size = UDim2.new(1, -20, 1, -10)
notifLabel.Position = UDim2.fromOffset(10, 5)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = "FlowVape is wiping files...\nThis may take a few seconds."
notifLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
notifLabel.Font = Enum.Font.GothamSemibold
notifLabel.TextSize = 14
notifLabel.TextWrapped = true
notifLabel.TextYAlignment = Enum.TextYAlignment.Center
notifLabel.Parent = notifFrame

if shared.vape then
    pcall(function() shared.vape:Uninject() end)
    shared.vape = nil
end

local function wipeDirectory(path)
    if not isfolder(path) then return end

    if delfolder then
        pcall(delfolder, path)
        if not isfolder(path) then return end
    end

    if listfiles then
        for _, file in ipairs(listfiles(path)) do
            pcall(function()
                if isfile(file) then
                    if delfile then
                        delfile(file)
                    else
                        writefile(file, '')
                    end
                elseif isfolder(file) then
                    wipeDirectory(file)
                end
            end)
        end
    end

    if delfolder then
        pcall(delfolder, path)
    end
end

print('[FlowVape] Wiping all FlowVape files and folders...')
wipeDirectory('FlowVape')
task.wait(1.5)
print('[FlowVape] Files completely cleared. Launching installer...')

local ok, err = pcall(function()
    local content = game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/NewMainScript.lua', true)
    if type(content) ~= 'string' or content == '' or content == '404: Not Found' then
        error('Failed to fetch NewMainScript.lua')
    end
    local func, loadErr = loadstring(content, 'NewMainScript')
    if not func then
        error('Syntax error: '..tostring(loadErr))
    end
    func()
end)

if ok then
    screenGui:Destroy()
else
    notifLabel.Text = "Reinstall failed:\n"..tostring(err):sub(1, 80)
    notifLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
    stroke.Color = Color3.fromRGB(248, 113, 113)
end
