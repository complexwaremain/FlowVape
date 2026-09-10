local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
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
	end
	pcall(writefile, 'FlowVape/profiles/commit.txt', commit)
end

local BASE = 'https://raw.githubusercontent.com/complexwaremain/FlowVape/main/profiles/'
local profileFiles = {
	'gui.txt',
	'commit.txt',
	'2619619496gui.txt',
	'default6872274481.txt',
	'default6872265039.txt',
	'Legit6872265039.txt',
	'Legit6872274481.txt',
	'Blatant6872274481.txt',
	'Blatant6872265039.txt',
}

for i = 1, #profileFiles do
	local filename = profileFiles[i]
	local ok, data = pcall(function()
		return game:HttpGet(BASE..filename)
	end)
	if ok and data and data ~= '404: Not Found' then
		pcall(writefile, 'FlowVape/profiles/'..filename, data)
	end
end

local GAMES_BASE = 'https://raw.githubusercontent.com/complexwaremain/FlowVape/main/games/'
local gameFiles = {
	'6872274481.lua',
	'6872265039.lua',
}

for i = 1, #gameFiles do
	local filename = gameFiles[i]
	local ok, data = pcall(function()
		return game:HttpGet(GAMES_BASE..filename)
	end)
	if ok and data and data ~= '404: Not Found' then
		pcall(writefile, 'FlowVape/games/'..filename, data)
	end
end

local maincontent = game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/main.lua')
pcall(writefile, 'FlowVape/main.lua', maincontent)
return loadstring(maincontent, 'main')()
