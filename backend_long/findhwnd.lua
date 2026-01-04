local ffi = require("ffi")

------------------------------------------------------------
-- Win32 declarations
------------------------------------------------------------

ffi.cdef[[
typedef void* HWND;
typedef int BOOL;
typedef long LPARAM;
typedef unsigned long DWORD;
typedef wchar_t* LPWSTR;

typedef BOOL (__stdcall *WNDENUMPROC)(HWND hwnd, LPARAM lParam);

BOOL EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
int  GetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount);
int  GetWindowTextLengthW(HWND hWnd);
BOOL IsWindowVisible(HWND hWnd);
]]

local user32 = ffi.load("user32")

------------------------------------------------------------
-- Helper: wchar_t buffer → Lua string (UTF-16LE)
------------------------------------------------------------

local function wchar_to_string(buf, len)
  -- Convert UTF-16LE buffer to Lua string (ASCII-safe; Steam title is ASCII)
  return ffi.string(ffi.cast("char*", buf), len * 2):gsub("\0", "")
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

local M = {}

--- Finds the first visible top-level window whose title matches `title`
--- @param title string (exact match)
--- @return HWND or nil
function M.find_by_title(title)
  local result_hwnd = nil

  local enum_cb
  enum_cb = ffi.cast("WNDENUMPROC", function(hwnd, lparam)
    if user32.IsWindowVisible(hwnd) == 0 then
      return 1 -- continue
    end

    local length = user32.GetWindowTextLengthW(hwnd)
    if length == 0 then
      return 1 -- continue
    end

    local buffer = ffi.new("wchar_t[?]", length + 1)
    user32.GetWindowTextW(hwnd, buffer, length + 1)

    local window_title = wchar_to_string(buffer, length)

    if window_title == title then
      result_hwnd = hwnd
      return 0 -- stop enumeration
    end

    return 1 -- continue
  end)

  user32.EnumWindows(enum_cb, 0)
  enum_cb:free()

  return result_hwnd
end

------------------------------------------------------------
-- Module return
------------------------------------------------------------

return M
