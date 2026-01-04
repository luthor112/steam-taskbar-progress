local logger = require("logger")
local millennium = require("millennium")
local findhwnd = require("findhwnd")
local tb = require("taskbar")
local flashwindow = require("flashwindow")

local MAX_PROGRESS = 100
local completion_task = 0
local custom_command = ""

local function run_completion_task()
    logger:info("Running task on completion")
    if completion_task == 1 then
        io.popen("shutdown /s /t 0")
        completion_task = 0
    elseif completion_task == 2 then
        io.popen(custom_command)
        completion_task = 0
    end
end

-- INTERFACES

function set_progress_percent(percent)
    logger:info("Progress at " .. percent)

    local hwnd = findhwnd.find_by_title("Steam")
    if not hwnd then
        return false
    end

    if percent == -1 then
        tb.Taskbar.clear(hwnd)
    elseif percent == -2 then
        tb.Taskbar.set_state(hwnd, tb.TBPF_PAUSED)
    elseif percent == 100 then
        tb.Taskbar.clear(hwnd)
        flashwindow.flash(hwnd)
        run_completion_task()
    else
        tb.Taskbar.set_progress(hwnd, percent, MAX_PROGRESS)
    end
    return true
end

function set_completion_task(new_value, new_custom_command)
    logger:info("Setting completion task mode to " .. new_value .. " with command " .. new_custom_command)
    completion_task = new_value
    custom_command = new_custom_command
    return true
end

-- PLUGIN MANAGEMENT

local function on_frontend_loaded()
    logger:info("Frontend loaded")
end

local function on_load()
    logger:info("Backend loaded")
    millennium.ready()
end

local function on_unload()
    tb.shutdown()
    logger:info("Backend unloaded")
end

return {
    on_frontend_loaded = on_frontend_loaded,
    on_load = on_load,
    on_unload = on_unload
}
