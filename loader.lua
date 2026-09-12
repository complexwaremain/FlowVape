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

for _, folder in {'FlowVape', 'FlowVape/games', 'FlowVape/profiles', 'FlowVape/assets', 'FlowVape/assets/new', 'FlowVape/libraries', 'FlowVape/profilesmobile', 'FlowVape/guis'} do
    if not isfolder(folder) then
        pcall(makefolder, folder)
    end
end

task.wait(0.1)

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

local function downloadFile(urlPath, localPath)
    if not isfile(localPath) then
        local suc, res = pcall(function()
            return game:HttpGet(BASE..urlPath, true)
        end)
        if not suc or res == '404: Not Found' then return end
        if localPath:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
        end
        pcall(writefile, localPath, res)
    end
end

local function forceDownloadFile(urlPath, localPath)
    local suc, res = pcall(function()
        return game:HttpGet(BASE..urlPath, true)
    end)
    if not suc or res == '404: Not Found' then return false end
    pcall(writefile, localPath, res)
    return true
end

local isMobile = false
if isfile('FlowVape/profiles/device.txt') then
    isMobile = readfile('FlowVape/profiles/device.txt') == 'mobile'
else
    local inputService = game:GetService('UserInputService')
    isMobile = inputService.TouchEnabled and not inputService.MouseEnabled
    pcall(writefile, 'FlowVape/profiles/device.txt', isMobile and 'mobile' or 'pc')
end
shared.FlowVapeIsMobile = isMobile

downloadFile('guis/new.lua', 'FlowVape/guis/new.lua')
downloadFile('guis/new.lua', 'FlowVape/guis/customgui.lua')

local function downloadAllAssets()
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
            for name in response:gmatch('"name"%s*:%s*"([^"]+)"') do
                if name:match('%.') then
                    table.insert(files, name)
                end
            end
        end

        for _, name in ipairs(files) do
            downloadFile('assets/new/'..name, 'FlowVape/assets/new/'..name)
        end
    else
        local fallbackAssets = {'textv4.png', 'guiv4.png', 'textvape.png', 'guivape.png'}
        for _, asset in ipairs(fallbackAssets) do
            downloadFile('assets/new/'..asset, 'FlowVape/assets/new/'..asset)
        end
    end
end

downloadAllAssets()

local SHARED_FILES = {'gui.txt', 'commit.txt', '2619619496.gui.txt', 'default6872274481.txt', 'default6872265039.txt'}

for i = 1, #SHARED_FILES do
    forceDownloadFile('profiles/'..SHARED_FILES[i], 'FlowVape/profiles/'..SHARED_FILES[i])
end

if isMobile then

    local mobProfiles = {
        {remote = 'legitMob6872274481.txt', local = 'Legit6872274481.txt'},
        {remote = 'blatantMob6872274481.txt', local = 'Blatant6872274481.txt'},
        {remote = 'legitMob6872265039.txt', local = 'Legit6872265039.txt'},
        {remote = 'blatantMob6872265039.txt', local = 'Blatant6872265039.txt'}
    }
    for i = 1, #mobProfiles do
        forceDownloadFile('profilesmobile/'..mobProfiles[i].remote, 'FlowVape/profiles/'..mobProfiles[i].local)
    end
else
    local pcProfiles = {'Legit6872274481.txt', 'Blatant6872274481.txt', 'Legit6872265039.txt', 'Blatant6872265039.txt'}
    for i = 1, #pcProfiles do
        forceDownloadFile('profiles/'..pcProfiles[i], 'FlowVape/profiles/'..pcProfiles[i])
    end
end

local gameFiles = {'6872274481.lua', '6872265039.lua', '8560631822.lua', '8444591321.lua'}
for i = 1, #gameFiles do
    downloadFile('games/'..gameFiles[i], 'FlowVape/games/'..gameFiles[i])
end

downloadFile('main.lua', 'FlowVape/main.lua')
return loadstring(readfile('FlowVape/main.lua'), 'main')()
