local ffi = require("ffi")

------------------------------------------------------------
-- Win32 declarations
------------------------------------------------------------

ffi.cdef[[
typedef void* HWND;
typedef int BOOL;

BOOL FlashWindow(HWND hWnd, BOOL bInvert);
]]

local user32 = ffi.load("user32")

------------------------------------------------------------
-- Public API
------------------------------------------------------------

local M = {}

--- Flashes a window once (equivalent to FlashWindow(hwnd, TRUE))
--- @param hwnd HWND
function M.flash(hwnd)
  if not hwnd then
    return false
  end

  user32.FlashWindow(ffi.cast("HWND", hwnd), 1)
  return true
end

--- Explicit control over invert flag
--- @param hwnd HWND
--- @param invert boolean
function M.flash_with_flag(hwnd, invert)
  if not hwnd then
    return false
  end

  user32.FlashWindow(
    ffi.cast("HWND", hwnd),
    invert and 1 or 0
  )
  return true
end

------------------------------------------------------------
-- Module return
------------------------------------------------------------

return M
