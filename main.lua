repeat task.wait() until game:IsLoaded()

if shared.vape then
    pcall(function() shared.vape:Uninject() end)
end

if identifyexecutor then
    if table.find({'Argon', 'Volt', 'Wave'}, ({identifyexecutor()})[1]) then
        getgenv().setthreadidentity = nil
    end
end

local vape
local rawLoadstring = loadstring

local loadstring = function(...)
    local res, err = rawLoadstring(...)
    if err and vape then
        vape:CreateNotification('Vape', 'Failed to load : '..tostring(err), 30, 'alert')
    end
    return res, err
end

local queue_on_teleport = queue_on_teleport or function() end

local isfile = isfile or function(file)
    local suc, res = pcall(function() return readfile(file) end)
    return suc and res ~= nil
end

local cloneref = cloneref or function(obj) return obj end
local playersService = cloneref(game:GetService('Players'))
local httpService = game:GetService('HttpService')
local isMobile = shared.FlowVapeIsMobile == true

local ALL_PROFILES = {
    ['6872274481'] = {
        {Name = 'Legit', File = 'Legit6872274481'},
        {Name = 'Blatant', File = 'Blatant6872274481'},
        {Name = 'LegitMob', File = 'legitMob6872274481'},
        {Name = 'BlatantMob', File = 'blatantMob6872274481'},
    },
    ['6872265039'] = {
        {Name = 'Legit', File = 'Legit6872265039'},
        {Name = 'Blatant', File = 'Blatant6872265039'},
        {Name = 'LegitMob', File = 'legitMob6872265039'},
        {Name = 'BlatantMob', File = 'blatantMob6872265039'},
    },
}

local function injectProfiles()
    local placeId = tostring(game.PlaceId)
    local profiles = ALL_PROFILES[placeId]
    if not profiles then return end

    local existingProfiles = vape.Profiles or {}
    vape.Profiles = existingProfiles

    for i = 1, #profiles do
        local entry = profiles[i]
        if entry and entry.Name and type(entry.Name) == 'string' then
            local isMobProfile = entry.Name:find('Mob') ~= nil
            if (isMobile and isMobProfile) or (not isMobile and not isMobProfile) then
                local alreadyExists = false
                for j = 1, #existingProfiles do
                    local existing = existingProfiles[j]
                    local existingName = type(existing) == 'table' and existing.Name or tostring(existing)
                    if existingName == entry.Name then
                        alreadyExists = true
                        break
                    end
                end
                if not alreadyExists then
                    table.insert(existingProfiles, {Name = entry.Name, File = entry.File, Bind = {}})
                end
            end
        end
    end

    pcall(function()
        if vape.Categories and vape.Categories.Profiles then
            vape.Categories.Profiles:ChangeValue()
        end
    end)
end

local function downloadFile(path, func)
    if not isfile(path) then
        local suc, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/'..select(1, path:gsub('FlowVape/', '')), true)
        end)
        if not suc then
            error(tostring(res))
        end
        if type(res) ~= 'string' or res == '' or res == '404: Not Found' then
            error('Failed to fetch: '..tostring(path))
        end
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
        end
        writefile(path, res)
    end
    return (func or readfile)(path)
end
shared.downloadFile = downloadFile

local function finishLoading()
    vape.Init = nil
    vape:Load()
    pcall(injectProfiles)

    local lastProfileFile = 'FlowVape/profiles/lastprofile.txt'
    local oldLoadProfile = vape.LoadProfile
    if oldLoadProfile then
        vape.LoadProfile = function(self, name, ...)
            pcall(writefile, lastProfileFile, tostring(name))
            return oldLoadProfile(self, name, ...)
        end
    end

    local lastProfile = nil
    if isfile(lastProfileFile) then
        local okRead, data = pcall(readfile, lastProfileFile)
        if okRead and data and data ~= '' then
            lastProfile = data
        end
    end

    if lastProfile and lastProfile ~= '' then
        task.spawn(function()
            local deadline = tick() + 15
            while not shared.FlowVapeGameReady and tick() < deadline do
                task.wait(0.1)
            end
            pcall(function()
                if vape.LoadProfile then
                    vape:LoadProfile(lastProfile)
                end
                local lobbyFile = 'FlowVape/profiles/'..lastProfile..'6872274481.txt'
                local matchFile = 'FlowVape/profiles/'..lastProfile..'6872265039.txt'
                if isfile(lobbyFile) and isfile(matchFile) then
                    local okL, lobbyData = pcall(function()
                        return httpService:JSONDecode(readfile(lobbyFile))
                    end)
                    local okM, matchData = pcall(function()
                        return httpService:JSONDecode(readfile(matchFile))
                    end)
                    if okL and okM and type(lobbyData) == 'table' and type(matchData) == 'table' then
                        for moduleName, settings in pairs(lobbyData) do
                            if matchData[moduleName] == nil then
                                matchData[moduleName] = settings
                            end
                        end
                        pcall(writefile, matchFile, httpService:JSONEncode(matchData))
                    end
                end
            end)
        end)
    end

    task.spawn(function()
        repeat
            vape:Save()
            task.wait(10)
        until not vape.Loaded
    end)

    local teleportedServers
    vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
        if (not teleportedServers) and (not shared.VapeIndependent) then
            teleportedServers = true
            local teleportScript = [[
shared.vapereload = true
if shared.VapeDeveloper then
    loadstring(readfile('FlowVape/loader.lua'), 'loader')()
else
    loadstring(game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/loader.lua', true), 'loader')()
end
]]
            if shared.VapeDeveloper then
                teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
            end
            if shared.VapeCustomProfile then
                local escaped = shared.VapeCustomProfile:gsub('\\', '\\\\'):gsub('"', '\\"')
                teleportScript = 'shared.VapeCustomProfile = "'..escaped..'"\n'..teleportScript
            end
            vape:Save()
            queue_on_teleport(teleportScript)
        end
    end))

    if not shared.vapereload then
        if not vape.Categories then return end
        if not (vape.Categories.Main
            and vape.Categories.Main.Options
            and vape.Categories.Main.Options['GUI bind indicator']) then
            return
        end
        if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
            vape:CreateNotification(
                'Finished Loading',
                vape.VapeButton and 'Press the button in the top right to open GUI'
                    or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI',
                5
            )
        end
    end
end

if not isfile('FlowVape/profiles/gui.txt') then
    pcall(writefile, 'FlowVape/profiles/gui.txt', 'new')
end
local gui = nil
do
    local okRead, data = pcall(readfile, 'FlowVape/profiles/gui.txt')
    if okRead and data and data ~= '' then
        gui = data
    end
end
if not gui or gui == '' then
    gui = 'new'
    pcall(writefile, 'FlowVape/profiles/gui.txt', 'new')
end

gui = gui:gsub('%s+$', ''):gsub('^%s+', '')
if gui == '' then gui = 'new' end

if not isfolder('FlowVape/assets/'..gui) then
    makefolder('FlowVape/assets/'..gui)
end

local okGui, guicontent = pcall(function()
    return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/guis/'..gui..'.lua')
end)
if not okGui or type(guicontent) ~= 'string' or guicontent == '' or guicontent == '404: Not Found' then
    error('Failed to fetch GUI file: '..tostring(gui))
end

local guiload, guierr = loadstring(guicontent, 'gui')
if not guiload then
    warn('[FlowVape] GUI fetch URL: guis/'..gui..'.lua')
    warn('[FlowVape] GUI content length: '..tostring(#guicontent))
    warn('[FlowVape] GUI content preview:', guicontent:sub(1, 500))
    warn('[FlowVape] GUI load error:', tostring(guierr))
    error('GUI syntax error: '..tostring(guierr))
end

local ok, result = pcall(guiload)
if not ok then
    warn('[FlowVape] GUI runtime error:', tostring(result))
    error('GUI runtime error: '..tostring(result))
end

vape = result
if not vape then
    error('GUI returned nil - expected a vape object')
end
shared.vape = vape

if not shared.VapeIndependent then
    local okUni, universalcontent = pcall(function()
        return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/games/universal.lua')
    end)
    if not okUni or type(universalcontent) ~= 'string' or universalcontent == '' or universalcontent == '404: Not Found' then
        error('Failed to fetch universal.lua')
    end

    local uniFunc, uniErr = loadstring(universalcontent, 'universal')
    if not uniFunc then
        warn('[FlowVape] universal.lua load error:', tostring(uniErr))
        error('universal.lua syntax error: '..tostring(uniErr))
    end
    uniFunc()

    local gameScriptPath = 'FlowVape/games/'..game.PlaceId..'.lua'
    if isfile(gameScriptPath) then
        local okRead, cached = pcall(readfile, gameScriptPath)
        if okRead and type(cached) == 'string' and cached ~= '' then
            local gameFunc, gameErr = loadstring(cached, tostring(game.PlaceId))
            if gameFunc then
                gameFunc(...)
            else
                warn('[FlowVape] Cached game script syntax error: '..tostring(gameErr))
            end
        end
    else
        if not shared.VapeDeveloper then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/games/'..game.PlaceId..'.lua', true)
            end)
            if suc and type(res) == 'string' and res ~= '' and res ~= '404: Not Found' then
                writefile(gameScriptPath, res)
                local gameFunc, gameErr = loadstring(res, tostring(game.PlaceId))
                if gameFunc then
                    gameFunc(...)
                else
                    warn('[FlowVape] Downloaded game script syntax error: '..tostring(gameErr))
                end
            end
        end
    end

    finishLoading()
else
    vape.Init = finishLoading
    return vape
end
