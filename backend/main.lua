local logger = require("logger")
local millennium = require("millennium")

local MAX_PROGRESS = 100

-- INTERFACES

function set_progress_percent(percent)
    logger:info("Progress at " .. percent)

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
