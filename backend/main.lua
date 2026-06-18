---@diagnostic disable-next-line: undefined-global
jit.off()

local logger     = require("logger")
local millennium = require("millennium")

local function on_frontend_loaded()
    logger:info("[main] Frontend loaded")
end

local function on_load()
    logger:info("[main] Backend loaded")
    millennium.ready()
end

local on_unload = function() end

logger:info("[main] Loading taskbar module")
local ok, taskbar = pcall(require, "taskbar")

if not ok then
    logger:error("[main] Taskbar module failed to load: " .. tostring(taskbar))
    function set_progress_percent(_) return false end
    function get_plugin_status() return "Not ready: " .. tostring(taskbar) end
else
    function set_progress_percent(percent) return taskbar.set_progress_percent(percent) end
    function get_plugin_status() return "Ready" end
    on_unload = function()
        logger:info("[main] Unloading")
        taskbar.cleanup()
    end
    logger:info("[main] Plugin ready")
end

return { on_frontend_loaded = on_frontend_loaded, on_load = on_load, on_unload = on_unload }
