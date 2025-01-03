-- sandbox.lua

local M = {}

M.new = function(f, env)
    return function()
        setfenv(f, env)
        local success, result = pcall(f)
        if not success then
            print("Error in sandboxed code:", result)
        end
        return success, result
    end
end


return M
