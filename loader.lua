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

-- Create folders FIRST
for _, folder in {'FlowVape', 'FlowVape/games', 'FlowVape/profiles', 'FlowVape/assets', 'FlowVape/libraries', 'FlowVape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

-- Initialize commit BEFORE downloading anything
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
	end
	writefile('FlowVape/profiles/commit.txt', commit)
end

-- NOW define downloadFile (after commit.txt is guaranteed to exist)
local function downloadFile(path, func)
	if not isfile(path) then
		local commitFile = 'FlowVape/profiles/commit.txt'
		local commit = isfile(commitFile) and readfile(commitFile) or 'main'
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/qyroke2/VapeV4ForRoblox/'..commit..'/'..select(1, path:gsub('FlowVape/', '')), true)
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

return loadstring(downloadFile('FlowVape/main.lua'), 'main')()
