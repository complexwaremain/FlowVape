repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

if identifyexecutor then
    if table.find({'Argon', 'Volt', 'Wave'}, ({identifyexecutor()})[1]) then
        getgenv().setthreadidentity = nil
    end
end

local vape
local loadstring = function(...)
    local res, err = loadstring(...)
    if err and vape then
        vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
    end
    return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
    return obj
end
local playersService = cloneref(game:GetService('Players'))

local isMobile = shared.FlowVapeIsMobile == true

local ALL_PROFILES = {
    ['6872274481'] = {
        {Name = 'Legit',   File = 'Legit6872274481'},
        {Name = 'Blatant', File = 'Blatant6872274481'},
        {Name = 'LegitMob',   File = 'LegitMob6872274481'},
        {Name = 'BlatantMob', File = 'BlatantMob6872274481'},
    },
    ['6872265039'] = {
        {Name = 'Legit',   File = 'Legit6872265039'},
        {Name = 'Blatant', File = 'Blatant6872265039'},
        {Name = 'LegitMob',   File = 'LegitMob6872265039'},
        {Name = 'BlatantMob', File = 'BlatantMob6872265039'},
    },
}

if listfiles then
    local oldListFiles = listfiles
    listfiles = function(path)
        if typeof(path) == 'string' and path:lower():match('flowvape/profiles$') then
            return {}
        end
        return oldListFiles(path)
    end
end

local function injectProfiles()
    local placeId = tostring(game.PlaceId)
    local profiles = ALL_PROFILES[placeId]
    if not profiles then return end
    for i = 1, #profiles do
        local entry = profiles[i]
        if entry and entry.Name and type(entry.Name) == 'string' then
            local isMobProfile = entry.Name:find('Mob') ~= nil
            if (isMobile and isMobProfile) or (not isMobile and not isMobProfile) then
                local alreadyExists = false
                for j = 1, #vape.Profiles do
                    local existing = vape.Profiles[j]
                    local existingName = type(existing) == 'table' and existing.Name or tostring(existing)
                    if existingName == entry.Name then
                        alreadyExists = true
                        break
                    end
                end
                if not alreadyExists then
                    table.insert(vape.Profiles, {Name = entry.Name, File = entry.File, Bind = {}})
                end
            end
        end
    end
    pcall(function()
        vape.Categories.Profiles:ChangeValue()
    end)
end

local function downloadFile(path, func)
    if not isfile(path) then
        local suc, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/'..select(1, path:gsub('FlowVape/', '')), true)
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

    local lastProfile = isfile(lastProfileFile) and readfile(lastProfileFile) or nil
    if lastProfile and lastProfile ~= '' then
        task.spawn(function()
            task.wait(1)
            pcall(function()
                if vape.LoadProfile then
                    vape:LoadProfile(lastProfile)
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
                teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
            end
            vape:Save()
            queue_on_teleport(teleportScript)
        end
    end))

    if not shared.vapereload then
        if not vape.Categories then return end
        if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
            vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
        end
    end
end

if not isfile('FlowVape/profiles/gui.txt') then
    writefile('FlowVape/profiles/gui.txt', 'new')
end
local gui = readfile('FlowVape/profiles/gui.txt')
if not gui or gui == '' then
    gui = 'new'
    writefile('FlowVape/profiles/gui.txt', 'new')
end

if not isfolder('FlowVape/assets/'..gui) then
    makefolder('FlowVape/assets/'..gui)
end

local guicontent = game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/guis/'..gui..'.lua')
local guiload, guierr = loadstring(guicontent, 'gui')
if not guiload then
    error('GUI syntax error: '..tostring(guierr))
end
local ok, result = pcall(guiload)
if not ok then
    error('GUI runtime error: '..tostring(result))
end
vape = result
shared.vape = vape

if not shared.VapeIndependent then
    local universalcontent = game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/games/universal.lua')
    loadstring(universalcontent, 'universal')()

    if isfile('FlowVape/games/'..game.PlaceId..'.lua') then
        loadstring(readfile('FlowVape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
    else
        if not shared.VapeDeveloper then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/games/'..game.PlaceId..'.lua', true)
            end)
            if suc and res ~= '404: Not Found' then
                writefile('FlowVape/games/'..game.PlaceId..'.lua', res)
                loadstring(res, tostring(game.PlaceId))(...)
            end
        end
    end
    finishLoading()
else
    vape.Init = finishLoading
    return vape
end
