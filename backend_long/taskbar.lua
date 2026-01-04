local ffi = require("ffi")

------------------------------------------------------------
-- Windows / COM declarations
------------------------------------------------------------

ffi.cdef[[
typedef unsigned long       DWORD;
typedef long                HRESULT;
typedef int                 BOOL;
typedef unsigned long long  ULONGLONG;
typedef void*               HWND;
typedef void*               LPVOID;
typedef const void*         REFIID;
typedef const void*         REFCLSID;

typedef struct {
  unsigned long Data1;
  unsigned short Data2;
  unsigned short Data3;
  unsigned char Data4[8];
} GUID;

HRESULT CoInitializeEx(LPVOID pvReserved, DWORD dwCoInit);
void CoUninitialize(void);

HRESULT CoCreateInstance(
  REFCLSID rclsid,
  LPVOID pUnkOuter,
  DWORD dwClsContext,
  REFIID riid,
  LPVOID *ppv
);
]]

------------------------------------------------------------
-- Constants
------------------------------------------------------------

local COINIT_APARTMENTTHREADED = 0x2
local CLSCTX_INPROC_SERVER     = 0x1

-- Taskbar progress states
local TBPF_NOPROGRESS    = 0x0
local TBPF_INDETERMINATE = 0x1
local TBPF_NORMAL        = 0x2
local TBPF_ERROR         = 0x4
local TBPF_PAUSED        = 0x8

------------------------------------------------------------
-- GUID helpers
------------------------------------------------------------

local function GUID(str)
  local d1, d2, d3, d4a, d4b, d4c, d4d, d4e, d4f, d4g, d4h =
    str:match("{(%x+)%-(%x+)%-(%x+)%-(%x%x)(%x%x)%-(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)}")

  return ffi.new("GUID", {
    tonumber(d1, 16),
    tonumber(d2, 16),
    tonumber(d3, 16),
    {
      tonumber(d4a, 16), tonumber(d4b, 16),
      tonumber(d4c, 16), tonumber(d4d, 16),
      tonumber(d4e, 16), tonumber(d4f, 16),
      tonumber(d4g, 16), tonumber(d4h, 16)
    }
  })
end

-- CLSID_TaskbarList
local CLSID_TaskbarList =
  GUID("{56FDF344-FD6D-11d0-958A-006097C9A090}")

-- IID_ITaskbarList3
local IID_ITaskbarList3 =
  GUID("{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}")

------------------------------------------------------------
-- ITaskbarList3 vtable
------------------------------------------------------------

ffi.cdef[[
typedef struct ITaskbarList3 ITaskbarList3;

typedef struct ITaskbarList3Vtbl {
  HRESULT (__stdcall *QueryInterface)(ITaskbarList3*, REFIID, void**);
  ULONG   (__stdcall *AddRef)(ITaskbarList3*);
  ULONG   (__stdcall *Release)(ITaskbarList3*);

  HRESULT (__stdcall *HrInit)(ITaskbarList3*);
  HRESULT (__stdcall *AddTab)(ITaskbarList3*, HWND);
  HRESULT (__stdcall *DeleteTab)(ITaskbarList3*, HWND);
  HRESULT (__stdcall *ActivateTab)(ITaskbarList3*, HWND);
  HRESULT (__stdcall *SetActiveAlt)(ITaskbarList3*, HWND);

  HRESULT (__stdcall *MarkFullscreenWindow)(ITaskbarList3*, HWND, BOOL);

  HRESULT (__stdcall *SetProgressValue)(
    ITaskbarList3*, HWND, ULONGLONG, ULONGLONG
  );

  HRESULT (__stdcall *SetProgressState)(
    ITaskbarList3*, HWND, DWORD
  );
} ITaskbarList3Vtbl;

struct ITaskbarList3 {
  ITaskbarList3Vtbl* lpVtbl;
};
]]

------------------------------------------------------------
-- COM initialization
------------------------------------------------------------

local ole32 = ffi.load("ole32")

local hr = ole32.CoInitializeEx(nil, COINIT_APARTMENTTHREADED)
-- S_OK (0) or S_FALSE (1) are both acceptable

------------------------------------------------------------
-- Create TaskbarList object
------------------------------------------------------------

local taskbar_pp = ffi.new("void*[1]")

hr = ole32.CoCreateInstance(
  CLSID_TaskbarList,
  nil,
  CLSCTX_INPROC_SERVER,
  IID_ITaskbarList3,
  taskbar_pp
)

assert(hr == 0, "CoCreateInstance failed")

local taskbar = ffi.cast("ITaskbarList3*", taskbar_pp[0])

-- Initialize
taskbar.lpVtbl.HrInit(taskbar)

------------------------------------------------------------
-- Public API
------------------------------------------------------------

local Taskbar = {}

function Taskbar.set_progress(hwnd, value, total)
  taskbar.lpVtbl.SetProgressState(taskbar, ffi.cast("HWND", hwnd), TBPF_NORMAL)
  taskbar.lpVtbl.SetProgressValue(
    taskbar,
    ffi.cast("HWND", hwnd),
    value,
    total
  )
end

function Taskbar.set_state(hwnd, state)
  taskbar.lpVtbl.SetProgressState(
    taskbar,
    ffi.cast("HWND", hwnd),
    state
  )
end

function Taskbar.clear(hwnd)
  taskbar.lpVtbl.SetProgressState(
    taskbar,
    ffi.cast("HWND", hwnd),
    TBPF_NOPROGRESS
  )
end

function Taskbar.shutdown()
  taskbar.lpVtbl.Release(taskbar)
  ffi.C.CoUninitialize()
end

------------------------------------------------------------
-- Example usage
------------------------------------------------------------

-- Replace with your real HWND
-- local hwnd = 0x00012345
-- Taskbar.set_progress(hwnd, 30, 100)

------------------------------------------------------------
-- Cleanup (optional)
------------------------------------------------------------

-- taskbar.lpVtbl.Release(taskbar)
-- ole32.CoUninitialize()

------------------------------------------------------------
-- Export
------------------------------------------------------------

return {
  Taskbar = Taskbar,
  shutdown = Taskbar.shutdown,

  -- expose constants if desired
  TBPF_NOPROGRESS    = TBPF_NOPROGRESS,
  TBPF_INDETERMINATE = TBPF_INDETERMINATE,
  TBPF_NORMAL        = TBPF_NORMAL,
  TBPF_ERROR         = TBPF_ERROR,
  TBPF_PAUSED        = TBPF_PAUSED
}
