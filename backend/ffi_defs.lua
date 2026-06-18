local logger = require("logger")
local ffi    = require("ffi")

logger:info("[ffi_defs] Registering type definitions")

ffi.cdef [[
typedef struct { uint32_t Data1; uint16_t Data2; uint16_t Data3; uint8_t Data4[8]; } GUID;
typedef GUID CLSID; typedef GUID IID;
typedef void*     HWND; typedef void* LPVOID; typedef void* LPUNKNOWN;
typedef intptr_t  LPARAM;
typedef long      HRESULT;
typedef unsigned long      ULONG; typedef unsigned long DWORD;
typedef unsigned long long ULONGLONG;
typedef int  BOOL; typedef char* LPSTR;

typedef struct ITaskbarList3 ITaskbarList3;
typedef struct {
  HRESULT (*QueryInterface)(ITaskbarList3*, const void*, void**);
  ULONG   (*AddRef)        (ITaskbarList3*);
  ULONG   (*Release)       (ITaskbarList3*);
  HRESULT (*HrInit)        (ITaskbarList3*);
  HRESULT (*AddTab)        (ITaskbarList3*, HWND);
  HRESULT (*DeleteTab)     (ITaskbarList3*, HWND);
  HRESULT (*ActivateTab)   (ITaskbarList3*, HWND);
  HRESULT (*SetActiveAlt)  (ITaskbarList3*, HWND);
  HRESULT (*MarkFullscreenWindow)(ITaskbarList3*, HWND, int);
  HRESULT (*SetProgressValue)   (ITaskbarList3*, HWND, ULONGLONG, ULONGLONG);
  HRESULT (*SetProgressState)   (ITaskbarList3*, HWND, int);
} ITaskbarList3Vtbl;
struct ITaskbarList3 { ITaskbarList3Vtbl* lpVtbl; };

HWND    FindWindowA     (const char*, const char*);
BOOL    FlashWindow     (HWND, BOOL);
HRESULT CoInitializeEx  (LPVOID, DWORD);
HRESULT CoCreateInstance(const CLSID*, LPUNKNOWN, DWORD, const IID*, LPVOID*);
int strncmp(const char*, const char*, size_t);
]]

logger:info("[ffi_defs] Loading native libraries")

local u32_ok, user32 = pcall(ffi.load, "user32")
local o32_ok, ole32  = pcall(ffi.load, "ole32")
local crt_ok, msvcrt = pcall(ffi.load, "msvcrt")

logger:info(string.format("[ffi_defs] user32=%s  ole32=%s  msvcrt=%s",
    tostring(u32_ok), tostring(o32_ok), tostring(crt_ok)))
if not u32_ok then logger:error("[ffi_defs] user32: " .. tostring(user32)) end
if not o32_ok then logger:error("[ffi_defs] ole32: " .. tostring(ole32)) end
if not crt_ok then logger:error("[ffi_defs] msvcrt: " .. tostring(msvcrt)) end

if not (u32_ok and o32_ok and crt_ok) then
    error("native library load failed")
end

logger:info("[ffi_defs] All libraries loaded")

return {
    user32 = user32,
    ole32  = ole32,
    msvcrt = msvcrt,
}
