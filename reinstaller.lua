-- FlowVape Reinstaller
-- This script wipes the old FlowVape files and launches the installer for a clean slate.

local function wipeFolder(path)
    if not isfolder(path) then return end
    
    if delfolder then
        pcall(delfolder, path)
        return
    end

    if listfiles then
        for _, file in ipairs(listfiles(path)) do
            pcall(function()
                if isfile(file) then
                    (delfile or function(f) writefile(f, '') end)(file)
                end
            end)
        end
    end
end

print('[FlowVape] Wiping old FlowVape files...')
wipeFolder('FlowVape')

task.wait(1)

print('[FlowVape] Files cleared. Launching installer...')

loadstring(game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/newmainscript.lua', true))()
