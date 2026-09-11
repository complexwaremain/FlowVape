local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
    pcall(writefile, file, '')
end

local httpService = game:GetService('HttpService')
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

-- 1. Create all necessary folders
for _, folder in {'FlowVape', 'FlowVape/games', 'FlowVape/profiles', 'FlowVape/assets', 'FlowVape/assets/new', 'FlowVape/libraries', 'FlowVape/profilesmobile', 'FlowVape/guis'} do
    if not isfolder(folder) then
        pcall(makefolder, folder)
    end
end

task.wait(0.1)

-- 2. Check for updates
if not shared.VapeDeveloper then
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
    end
    pcall(writefile, 'FlowVape/profiles/commit.txt', commit)
end

-- 3. Download Function
local function downloadFile(path)
    if not isfile(path) then
        local suc, res = pcall(function()
            return game:HttpGet(BASE..select(1, path:gsub('FlowVape/', '')), true)
        end)
        if not suc or res == '404: Not Found' then
            return -- Skip if file doesn't exist
        end
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
        end
        pcall(writefile, path, res)
    end
end

-- 4. Auto-detect Mobile or read from saved settings
local isMobile = false
if isfile('FlowVape/profiles/device.txt') then
    isMobile = readfile('FlowVape/profiles/device.txt') == 'mobile'
else
    local inputService = game:GetService('UserInputService')
    isMobile = inputService.TouchEnabled and not inputService.MouseEnabled
    pcall(writefile, 'FlowVape/profiles/device.txt', isMobile and 'mobile' or 'pc')
end
shared.FlowVapeIsMobile = isMobile

-- 5. Download Custom GUI
downloadFile('FlowVape/guis/new.lua')
downloadFile('FlowVape/guis/customgui.lua')

-- 6. Download ALL Assets Dynamically via GitHub API
local function downloadAllAssets()
    if not isfolder('FlowVape/assets/new') then
        pcall(makefolder, 'FlowVape/assets/new')
    end

    local ok, response = pcall(function()
        return game:HttpGet('https://api.github.com/repos/complexwaremain/FlowVape/contents/assets/new?ref=main')
    end)

    if ok and response then
        local files = {}
        local decOk, decoded = pcall(function()
            return httpService:JSONDecode(response)
        end)

        if decOk and type(decoded) == 'table' then
            for _, f in ipairs(decoded) do
                if f.type == 'file' and f.name then
                    table.insert(files, f.name)
                end
            end
        else
            -- Fallback parser if JSONDecode fails
            for name in response:gmatch('"name"%s*:%s*"([^"]+)"') do
                if name:match('%.') then
                    table.insert(files, name)
                end
            end
        end

        for _, name in ipairs(files) do
            downloadFile('FlowVape/assets/new/'..name)
        end
    else
        -- Ultimate fallback if GitHub API is blocked/rate limited
        local fallbackAssets = {'textv4.png', 'guiv4.png', 'textvape.png', 'guivape.png'}
        for _, asset in ipairs(fallbackAssets) do
            downloadFile('FlowVape/assets/new/'..asset)
        end
    end
end

downloadAllAssets()

-- 7. Download Profiles (Fixed Casing!)
local SHARED_FILES = {'gui.txt', 'commit.txt', '2619619496.gui.txt', 'default6872274481.txt', 'default6872265039.txt'}
local PC_PROFILES = {'Legit6872274481.txt', 'Blatant6872274481.txt', 'Legit6872265039.txt', 'Blatant6872265039.txt'}
local MOB_PROFILES = {'LegitMob6872274481.txt', 'BlatantMob6872274481.txt', 'LegitMob6872265039.txt', 'BlatantMob6872265039.txt'}

for i = 1, #SHARED_FILES do
    downloadFile('FlowVape/profiles/'..SHARED_FILES[i])
end

local profileList = isMobile and MOB_PROFILES or PC_PROFILES
for i = 1, #profileList do
    downloadFile('FlowVape/profiles/'..profileList[i])
end

-- 8. Download Game Scripts
local gameFiles = {'6872274481.lua', '6872265039.lua', '8560631822.lua', '8444591321.lua'}
for i = 1, #gameFiles do
    downloadFile('FlowVape/games/'..gameFiles[i])
end

-- 9. Run Main Script
return loadstring(downloadFile('FlowVape/main.lua') or readfile('FlowVape/main.lua'), 'main')()
