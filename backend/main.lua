local logger = require("logger")
local millennium = require("millennium")
local ffi = require("ffi")

ffi.cdef[[
typedef void* HWND;
typedef long LPARAM;
typedef int BOOL;
typedef char* LPSTR;
typedef int (__stdcall *WNDENUMPROC)(HWND, LPARAM);

BOOL __stdcall EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
int __stdcall GetWindowTextA(HWND hWnd, LPSTR lpString, int nMaxCount);
BOOL __stdcall IsWindowVisible(HWND hWnd);
BOOL __stdcall FlashWindow(HWND hWnd, BOOL bInvert);
]]

local user32 = ffi.load("user32")
local MAX_PROGRESS = 100
local steam_hwnd = nil

local window_enum_callback = ffi.cast("WNDENUMPROC", function(hwnd, lParam)
    if user32.IsWindowVisible(hwnd) == 0 then return 1 end

    local title = ffi.new("char[16]")
    user32.GetWindowTextA(hwnd, title, 16)
    --logger:info(ffi.string(title))
    if ffi.string(title):lower() == "steam" then
        steam_hwnd = hwnd
        return 0
    end

    return 1
end)

local function find_steam()
    user32.EnumWindows(window_enum_callback, 0)
    if steam_hwnd ~= nil and steam_hwnd ~= ffi.NULL then
        logger:info(string.format("Found Steam HWND: %p", steam_hwnd))
        return true
    end
    return false
end

-- INTERFACES

function set_progress_percent(percent)
    logger:info("Progress at " .. percent)

    if not find_steam() then return false end
    if percent == -1 then
        --clear taskbar
        logger:info("a")
    elseif percent == -2 then
        --set to paused
        logger:info("a")
    elseif percent == 100 then
        --clear taskbar
        user32.FlashWindow(steam_hwnd, 1)
    else
        --set progress
        logger:info("a")
    end

    return true
end

-- PLUGIN MANAGEMENT

local function on_frontend_loaded()
    -- TESTING
    --find_steam()
    --user32.FlashWindow(steam_hwnd, 1)

    logger:info("Frontend loaded")
end

local function on_load()
    logger:info("Backend loaded")
    millennium.ready()
end

local function on_unload()
    window_enum_callback = nil
    logger:info("Backend unloaded")
end

return {
    on_frontend_loaded = on_frontend_loaded,
    on_load = on_load,
    on_unload = on_unload
}
