local logger = require("logger")
local millennium = require("millennium")
local ffi = require("ffi")

-- PLUGIN MANAGEMENT

local plugin_status = ""
local plugin_ready = false

local function set_plugin_status(status_message, plugin_okay)
    plugin_status = status_message
    if plugin_okay then
        logger:info(status_message)
    else
        logger:error(status_message)
    end
end

local function on_frontend_loaded()
    logger:info("Frontend loaded")
end

local function on_load()
    logger:info("Backend loaded")
    millennium.ready()
end

local function on_unload()
    --tb.lpVtbl.Release(tb)
    --window_enum_callback = nil
    logger:info("Backend unloaded")
end

-- STARTUP

ffi.cdef[[
typedef struct {
  uint32_t Data1;
  uint16_t Data2;
  uint16_t Data3;
  uint8_t  Data4[8];
} GUID;

typedef GUID CLSID;
typedef GUID IID;
typedef void* HWND;
typedef void* LPVOID;
typedef void* LPUNKNOWN;
typedef const void* REFCLSID;
typedef const void* REFIID;
typedef long LPARAM;
typedef long HRESULT;
typedef unsigned long ULONG;
typedef unsigned long DWORD;
typedef unsigned long long ULONGLONG;
typedef int BOOL;
typedef char* LPSTR;

typedef struct ITaskbarList3 ITaskbarList3;
typedef struct {
  HRESULT (__stdcall *QueryInterface)(ITaskbarList3*,const void*,void**);
  ULONG   (__stdcall *AddRef)(ITaskbarList3*);
  ULONG   (__stdcall *Release)(ITaskbarList3*);
  HRESULT (__stdcall *HrInit)(ITaskbarList3*);
  HRESULT (__stdcall *AddTab)(ITaskbarList3*,HWND);
  HRESULT (__stdcall *DeleteTab)(ITaskbarList3*,HWND);
  HRESULT (__stdcall *ActivateTab)(ITaskbarList3*,HWND);
  HRESULT (__stdcall *SetActiveAlt)(ITaskbarList3*,HWND);
  HRESULT (__stdcall *MarkFullscreenWindow)(ITaskbarList3*,HWND,int);
  HRESULT (__stdcall *SetProgressValue)(ITaskbarList3*,HWND,ULONGLONG,ULONGLONG);
  HRESULT (__stdcall *SetProgressState)(ITaskbarList3*,HWND,int);
} ITaskbarList3Vtbl;
struct ITaskbarList3 { ITaskbarList3Vtbl* lpVtbl; };

typedef int (__stdcall *WNDENUMPROC)(HWND, LPARAM);

BOOL __stdcall EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
int __stdcall GetWindowTextA(HWND hWnd, LPSTR lpString, int nMaxCount);
BOOL __stdcall IsWindowVisible(HWND hWnd);
BOOL __stdcall FlashWindow(HWND hWnd, BOOL bInvert);
HRESULT __stdcall CoInitializeEx(LPVOID pvReserved, DWORD dwCoInit);
HRESULT __stdcall CoCreateInstance(const CLSID* rclsid, LPUNKNOWN pUnkOuter, DWORD dwClsContext, const IID* riid, LPVOID *ppv);
]]

set_plugin_status("Passed CDEF", true)

local user32_ok, user32 = pcall(ffi.load, "user32")
local ole32_ok, ole32 = pcall(ffi.load, "ole32")
if user32_ok and ole32_ok then
    set_plugin_status("Native libraries loaded", true)
else
    set_plugin_status("Native libraries NOT loaded", false)
    return { on_frontend_loaded = on_frontend_loaded, on_load = on_load, on_unload = on_unload }
end

local CLSID_TaskbarList = ffi.new("CLSID", {
  Data1 = 0x56FDF344,
  Data2 = 0xFD6D,
  Data3 = 0x11D0,
  Data4 = {0x95,0x8A,0x00,0x60,0x97,0xC9,0xA0,0x90}
})
local IID_ITaskbarList = ffi.new("IID", {
  Data1 = 0x56FDF342,
  Data2 = 0xFD6D,
  Data3 = 0x11D0,
  Data4 = {0x95,0x8A,0x00,0x60,0x97,0xC9,0xA0,0x90}
})
local IID_ITaskbarList3 = ffi.new("IID", {
  Data1 = 0xEA1AFB91,
  Data2 = 0x9E28,
  Data3 = 0x4B86,
  Data4 = {0x90,0xE9,0x9E,0x9F,0x8A,0x5E,0xEF,0xAF}
})
local TBPF_NOPROGRESS = 0
local TBPF_INDETERMINATE = 1
local TBPF_NORMAL = 2
local TBPF_ERROR = 4
local TBPF_PAUSED = 8
local MAX_PROGRESS = 100
local steam_hwnd = nil
local title = ffi.new("char[16]")
set_plugin_status("Most variables have been set", true)

local window_enum_callback = ffi.cast("WNDENUMPROC", function(hwnd, lParam)
    if user32.IsWindowVisible(hwnd) == 0 then return 1 end

    if user32.GetWindowTextA(hwnd, title, 16) == 5 then
        if ffi.string(title):lower() == "steam" then
            steam_hwnd = hwnd
            return 0
        end
    end

    return 1
end)
set_plugin_status("WNDENUMPROC has been defined", true)

local hr0 = ole32.CoInitializeEx(nil, 2)
if hr0 >= 0 then
    set_plugin_status("COM Init done", true)
else
    set_plugin_status("COM Init failed", false)
    return { on_frontend_loaded = on_frontend_loaded, on_load = on_load, on_unload = on_unload }
end

local ppv = ffi.new("void*[1]")
local hr = ole32.CoCreateInstance(CLSID_TaskbarList, nil, 1, IID_ITaskbarList, ppv)
logger:info(string.format("CoCreateInstance hr = 0x%08X", hr))
if hr == 0 then
    set_plugin_status("CoCreateInstance successful", true)
else
    set_plugin_status("CoCreateInstance failed", false)
    return { on_frontend_loaded = on_frontend_loaded, on_load = on_load, on_unload = on_unload }
end

local tb = ffi.cast("ITaskbarList3*", ppv[0])
local hr2 = tb.lpVtbl.QueryInterface(tb, IID_ITaskbarList3, ppv)
logger:info(string.format("QueryInterface hr = 0x%08X", hr2))
if hr2 == 0 then
    set_plugin_status("QueryInterface successful", true)
else
    set_plugin_status("QueryInterface falied", false)
    return { on_frontend_loaded = on_frontend_loaded, on_load = on_load, on_unload = on_unload }
end

tb = ffi.cast("ITaskbarList3*", ppv[0])
local hr3 = tb.lpVtbl.HrInit(tb)
if hr3 == 0 then
    set_plugin_status("HrInit successful", true)
else
    set_plugin_status("HrInit failed", false)
    return { on_frontend_loaded = on_frontend_loaded, on_load = on_load, on_unload = on_unload }
end

local function find_steam()
    steam_hwnd = nil
    user32.EnumWindows(window_enum_callback, 0)
    if steam_hwnd ~= nil and steam_hwnd ~= ffi.NULL then
        logger:info(string.format("Found Steam HWND: %p", steam_hwnd))
        return true
    end
    return false
end

-- INTERFACES

function set_progress_percent(percent)
    if not plugin_ready then
        logger:error("Plugin not ready")
        return false
    end

    logger:info("Progress at " .. percent)

    if not find_steam() then return false end
    if percent == -1 then
        tb.lpVtbl.SetProgressState(tb, steam_hwnd, TBPF_NOPROGRESS)
    elseif percent == -2 then
        tb.lpVtbl.SetProgressState(tb, steam_hwnd, TBPF_PAUSED)
    elseif percent == 100 then
        tb.lpVtbl.SetProgressState(tb, steam_hwnd, TBPF_NOPROGRESS)
        user32.FlashWindow(steam_hwnd, 1)
    else
        tb.lpVtbl.SetProgressState(tb, steam_hwnd, TBPF_NORMAL)
        tb.lpVtbl.SetProgressValue(tb, steam_hwnd, percent, MAX_PROGRESS)
    end

    logger:info("Progress set")
    return true
end

function get_plugin_status()
    if plugin_ready then
        return "Ready"
    else
        return "Not ready: " .. plugin_status
    end
end

plugin_ready = true
return { on_frontend_loaded = on_frontend_loaded, on_load = on_load, on_unload = on_unload }
