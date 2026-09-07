local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
    writefile(file, '')
end

local function downloadFile(path, func)
    if not isfile(path) then
        local suc, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/qyroke2/VapeV4ForRoblox/'..readfile('FlowVape/profiles/commit.txt')..'/'..select(1, path:gsub('FlowVape/', '')), true)
        end)
        if not suc or res == '404: Not Found' then
            error(res)
        end
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
        end
        writefile(path, res)
    end
    return (func or readfile)(path)
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

for _, folder in {'FlowVape', 'FlowVape/games', 'FlowVape/profiles', 'FlowVape/assets', 'FlowVape/libraries', 'FlowVape/guis'} do
    if not isfolder(folder) then
        makefolder(folder)
    end
end

if not shared.VapeDeveloper then
    local _, subbed = pcall(function()
        return game:HttpGet('https://github.com/qyroke2/VapeV4ForRoblox')
    end)
    local commit = subbed:find('currentOid')
    commit = commit and subbed:sub(commit + 13, commit + 52) or nil
    commit = commit and #commit == 40 and commit or 'main'
    if commit == 'main' or (isfile('FlowVape/profiles/commit.txt') and readfile('FlowVape/profiles/commit.txt') or '') ~= commit then
        wipeFolder('FlowVape')
        wipeFolder('FlowVape/games')
        wipeFolder('FlowVape/guis')
        wipeFolder('FlowVape/libraries')
        wipeFolder('FlowVape/profiles') 
    end
    writefile('FlowVape/profiles/commit.txt', commit)
end

local BASE = "https://raw.githubusercontent.com/complexwaremain/FlowVape/main/profiles/"
local files = {
    "gui.txt",
    "commit.txt",
    "2619619496gui.txt",
    "default6872274481.txt",
    "default6872265039.txt",
    "Legit6872265039.txt",
    "Legit6872274481.txt",
    "Blatant6872274481.txt",
    "Blatant6872265039.txt",
}

for _, filename in ipairs(files) do
    local ok, data = pcall(function()
        return game:HttpGet(BASE .. filename)
    end)
    if ok and data and data ~= "404: Not Found" then
        writefile("FlowVape/profiles/" .. filename, data)
    end
end

local GAMES_BASE = "https://raw.githubusercontent.com/complexwaremain/FlowVape/main/games/"
local gameFiles = {
    "6872274481.lua",
}

for _, filename in ipairs(gameFiles) do
    local ok, data = pcall(function()
        return game:HttpGet(GAMES_BASE .. filename)
    end)
    if ok and data and data ~= "404: Not Found" then
        writefile("FlowVape/games/" .. filename, data)
    end
end

return loadstring(downloadFile('FlowVape/main.lua'), 'main')()
