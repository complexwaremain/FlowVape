local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
    pcall(writefile, file, '')
end

local function wipeFolder(path)
    if not isfolder(path) then return end
    for _, file in listfiles(path) do
        if file:find('loader') then continue end
        if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
            delfile(file)
        end
    end
end

    for _, folder in {'FlowVape', 'FlowVape/games', 'FlowVape/profiles', 'FlowVape/assets', 'FlowVape/libraries', 'FlowVape/profilesmobile', 'FlowVape/guis'} do
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

local function downloadFile(path, func)
    if not isfile(path) then
        local commitFile = 'FlowVape/profiles/commit.txt'
        local commit = isfile(commitFile) and readfile(commitFile) or 'main'
        local suc, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/'..select(1, path:gsub('FlowVape/', '')), true)
        end)
        if not suc or res == '404: Not Found' then
            error(res)
        end
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
        end
        pcall(writefile, path, res)
        if func then return func(path) end
        return res 
    end
    return (func or readfile)(path)
end

-- Fixed Profile Downloading with Correct Capitalisation
local function forceDownloadProfile(urlPath, localPath)
    local suc, res = pcall(function()
        return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/'..urlPath, true)
    end)
    if suc and res ~= '404: Not Found' then
        pcall(writefile, 'FlowVape/'..localPath, res)
    end
end

local isMobile = shared.FlowVapeIsMobile == true

if isMobile then
    -- GitHub casing: legitMob... Saved locally as Legit...
    local mobProfiles = {
        {remote = 'profilesmobile/legitMob6872274481.txt', saveAs = 'profiles/Legit6872274481.txt'},
        {remote = 'profilesmobile/blatantMob6872274481.txt', saveAs = 'profiles/Blatant6872274481.txt'},
        {remote = 'profilesmobile/legitMob6872265039.txt', saveAs = 'profiles/Legit6872265039.txt'},
        {remote = 'profilesmobile/blatantMob6872265039.txt', saveAs = 'profiles/Blatant6872265039.txt'}
    }
    for i = 1, #mobProfiles do
        forceDownloadProfile(mobProfiles[i].remote, mobProfiles[i].saveAs)
    end
else
    -- GitHub casing: Legit... Saved locally as Legit...
    local pcProfiles = {
        {remote = 'profiles/Legit6872274481.txt', saveAs = 'profiles/Legit6872274481.txt'},
        {remote = 'profiles/Blatant6872274481.txt', saveAs = 'profiles/Blatant6872274481.txt'},
        {remote = 'profiles/Legit6872265039.txt', saveAs = 'profiles/Legit6872265039.txt'},
        {remote = 'profiles/Blatant6872265039.txt', saveAs = 'profiles/Blatant6872265039.txt'}
    }
    for i = 1, #pcProfiles do
        forceDownloadProfile(pcProfiles[i].remote, pcProfiles[i].saveAs)
    end
end

return loadstring(downloadFile('FlowVape/main.lua'), 'main')()
