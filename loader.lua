local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
    pcall(writefile, file, '')
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

local function dlFile(url, dest)
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if ok and data and data ~= '404: Not Found' then
        pcall(writefile, dest, data)
    end
end

local function downloadProfiles(isMobile)
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

local isMobile = isfile('FlowVape/device.txt') and readfile('FlowVape/device.txt') == 'mobile'
downloadProfiles(isMobile)

local maincontent = game:HttpGet(BASE..'main.lua')
pcall(writefile, 'FlowVape/main.lua', maincontent)
return loadstring(maincontent, 'main')()
