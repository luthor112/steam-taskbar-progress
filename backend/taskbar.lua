local logger            = require("logger")
local ffi               = require("ffi")
local libs              = require("ffi_defs")

local user32            = libs.user32
local ole32             = libs.ole32

local CLSID_TaskbarList = ffi.new("CLSID",
    { 0x56FDF344, 0xFD6D, 0x11D0, { 0x95, 0x8A, 0x00, 0x60, 0x97, 0xC9, 0xA0, 0x90 } })
local IID_ITaskbarList  = ffi.new("IID",
    { 0x56FDF342, 0xFD6D, 0x11D0, { 0x95, 0x8A, 0x00, 0x60, 0x97, 0xC9, 0xA0, 0x90 } })
local IID_ITaskbarList3 = ffi.new("IID",
    { 0xEA1AFB91, 0x9E28, 0x4B86, { 0x90, 0xE9, 0x9E, 0x9F, 0x8A, 0x5E, 0xEF, 0xAF } })

logger:info("[taskbar] CoInitializeEx (COINIT_APARTMENTTHREADED)")
local hr = ole32.CoInitializeEx(nil, 2)
logger:info(string.format("[taskbar] CoInitializeEx hr=0x%08X%s",
    hr,
    hr == 0 and " (S_OK)" or hr == 1 and " (S_FALSE: already initialized on this thread)" or ""))
if hr < 0 then
    error(string.format("CoInitializeEx failed: 0x%08X", hr))
end

local ppv = ffi.new("void*[1]")

logger:info("[taskbar] CoCreateInstance(CLSID_TaskbarList)")
hr = ole32.CoCreateInstance(CLSID_TaskbarList, nil, 1, IID_ITaskbarList, ppv)
logger:info(string.format("[taskbar] CoCreateInstance hr=0x%08X  ptr=%s", hr, tostring(ppv[0])))
if hr ~= 0 then
    error(string.format("CoCreateInstance failed: 0x%08X", hr))
end

local tb = ffi.cast("ITaskbarList3*", ppv[0])
logger:info(string.format("[taskbar] QueryInterface(IID_ITaskbarList3) on %s", tostring(tb)))
hr = tb.lpVtbl.QueryInterface(tb, IID_ITaskbarList3, ppv)
logger:info(string.format("[taskbar] QueryInterface hr=0x%08X  ptr=%s", hr, tostring(ppv[0])))
logger:info("[taskbar] Releasing ITaskbarList ref")
tb.lpVtbl.Release(tb)
if hr ~= 0 then
    error(string.format("QueryInterface(ITaskbarList3) failed: 0x%08X", hr))
end

tb = ffi.cast("ITaskbarList3*", ppv[0])
logger:info(string.format("[taskbar] HrInit on %s", tostring(tb)))
hr = tb.lpVtbl.HrInit(tb)
logger:info(string.format("[taskbar] HrInit hr=0x%08X", hr))
if hr ~= 0 then
    tb.lpVtbl.Release(tb)
    error(string.format("HrInit failed: 0x%08X", hr))
end

logger:info("[taskbar] Caching vtable function pointers")
local tb_SetProgressValue = tb.lpVtbl.SetProgressValue
local tb_SetProgressState = tb.lpVtbl.SetProgressState
local tb_Release          = tb.lpVtbl.Release
logger:info(string.format("[taskbar] SetProgressValue=%s  SetProgressState=%s  Release=%s",
    tostring(tb_SetProgressValue), tostring(tb_SetProgressState), tostring(tb_Release)))

local steam_hwnd = nil

local function find_steam()
    local hwnd = user32.FindWindowA(nil, "Steam")
    if hwnd ~= nil then
        steam_hwnd = hwnd
        logger:info(string.format("[taskbar] Steam HWND: %s", tostring(steam_hwnd)))
        return true
    end
    logger:warn("[taskbar] Steam window not found")
    return false
end

local function set_progress_percent(percent)
    logger:info("[taskbar] set_progress_percent(" .. percent .. ")")
    if not find_steam() then return false end
    local hr_s
    if percent == -1 then
        logger:info("[taskbar] SetProgressState -> NOPROGRESS")
        hr_s = tb_SetProgressState(tb, steam_hwnd, 0)
    elseif percent == -2 then
        logger:info("[taskbar] SetProgressState -> PAUSED")
        hr_s = tb_SetProgressState(tb, steam_hwnd, 8)
    elseif percent == 100 then
        logger:info("[taskbar] SetProgressState -> NOPROGRESS + FlashWindow")
        hr_s = tb_SetProgressState(tb, steam_hwnd, 0)
        user32.FlashWindow(steam_hwnd, 1)
    else
        logger:info(string.format("[taskbar] SetProgressState -> NORMAL, SetProgressValue(%d/100)", percent))
        tb_SetProgressState(tb, steam_hwnd, 2)
        hr_s = tb_SetProgressValue(tb, steam_hwnd, percent, 100)
    end
    if hr_s ~= nil and hr_s ~= 0 then
        logger:error(string.format("[taskbar] COM call returned 0x%08X", hr_s))
    end
    return true
end

local function cleanup()
    logger:info("[taskbar] Releasing ITaskbarList3")
    tb_Release(tb)
end

return {
    set_progress_percent = set_progress_percent,
    cleanup              = cleanup,
}
