-- FlowVape Reinstaller
-- Completely wipes all FlowVape files and subfolders, then relaunches.

-- 1. Uninject Vape if it is currently running to prevent UI overlap
if shared.vape then
    pcall(function() shared.vape:Uninject() end)
    shared.vape = nil
end

-- 2. Recursive function to delete all files and subfolders
local function wipeDirectory(path)
    if not isfolder(path) then return end
    
    -- If the executor has delfolder, use it (fastest method)
    if delfolder then
        pcall(delfolder, path)
        return
    end

    -- Fallback: recursively list and delete files
    if listfiles then
        for _, file in ipairs(listfiles(path)) do
            pcall(function()
                if isfile(file) then
                    -- Delete the file
                    if delfile then 
                        delfile(file) 
                    else 
                        writefile(file, '') -- Last resort if delfile is missing
                    end
                elseif isfolder(file) then
                    -- Recursively wipe subfolders
                    wipeDirectory(file)
                end
            end)
        end
    end
end

print('[FlowVape] Wiping all FlowVape files and folders...')
wipeDirectory('FlowVape')

-- Give the executor a moment to finish clearing the workspace
task.wait(1.5)

print('[FlowVape] Files completely cleared. Launching installer...')
-- 3. Load the installer UI
loadstring(game:HttpGet('https://raw.githubusercontent.com/complexwaremain/FlowVape/main/newmainscript.lua', true))()
