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
local httpService = game:GetService('HttpService')

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

local function dlFile(url, dest)
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if ok and data and data ~= '404: Not Found' then
        pcall(writefile, dest, data)
    end
end

local function downloadProfiles(isMobile)
    local ok1, res1 = pcall(function()
        return game:HttpGet('https://api.github.com/repos/complexwaremain/FlowVape/contents/profiles?ref=main')
    end)
    if ok1 and res1 then
        local decOk, decoded = pcall(function()
            return httpService:JSONDecode(res1)
        end)
        if decOk and type(decoded) == 'table' then
            for _, f in ipairs(decoded) do
                if f.type == 'file' and f.name and f.download_url then
                    dlFile(f.download_url, 'FlowVape/profiles/'..f.name)
                end
            end
        end
    end

    if isMobile then
        local ok2, res2 = pcall(function()
            return game:HttpGet('https://api.github.com/repos/complexwaremain/FlowVape/contents/profilesmobile?ref=main')
        end)
        if ok2 and res2 then
            local decOk, decoded = pcall(function()
                return httpService:JSONDecode(res2)
            end)
            if decOk and type(decoded) == 'table' then
                for _, f in ipairs(decoded) do
                    if f.type == 'file' and f.name and f.download_url then
                        dlFile(f.download_url, 'FlowVape/profiles/'..f.name)
                    end
                end
            end
        end
    end
end

local isMobile = isfile('FlowVape/device.txt') and readfile('FlowVape/device.txt') == 'mobile'
downloadProfiles(isMobile)

local maincontent = game:HttpGet(BASE..'main.lua')
pcall(writefile, 'FlowVape/main.lua', maincontent)
return loadstring(maincontent, 'main')()
