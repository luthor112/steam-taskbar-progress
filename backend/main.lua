local logger = require("logger")
local millennium = require("millennium")

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

    if percent == 100 then
        run_completion_task()
    end

    return true
end

function set_completion_task(a_new_value, b_new_custom_command)
    local new_value = a_new_value
    local new_custom_command = b_new_custom_command

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
    logger:info("Backend unloaded")
end

return {
    on_frontend_loaded = on_frontend_loaded,
    on_load = on_load,
    on_unload = on_unload
}
