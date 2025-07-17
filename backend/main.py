import Millennium, PluginUtils # type: ignore
logger = PluginUtils.Logger()

import ctypes
import json
import os
import sys

if sys.platform == "win32":
    import pygetwindow
    from pytaskbr import taskbar, TBPFlag
    taskbar.HrInit()

MAX_PROGRESS = 100


def get_config():
    with open(os.path.join(PLUGIN_BASE_DIR, "config.json"), "rt") as fp:
        return json.load(fp)

class Backend:
    @staticmethod
    def set_progress_percent(percent):
        logger.log(f"set_progress_percent({percent})")

        if sys.platform != "win32":
            return False

        steam_hwnd = None
        for wnd in pygetwindow.getWindowsWithTitle("Steam"):
            if wnd.title == "Steam":
                steam_hwnd = wnd._hWnd

        if steam_hwnd is None:
            return False

        if percent == -1:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.noProgress)
        elif percent == -2:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.paused)
        elif percent == 100:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.noProgress)
            ctypes.windll.user32.FlashWindow(steam_hwnd, True)
        else:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.normal)
            taskbar.setProgressValue(steam_hwnd, percent, MAX_PROGRESS)
        return True

    @staticmethod
    def get_use_old_detection():
        use_old_detection = get_config()["use_old_detection"]
        logger.log(f"get_use_old_detection() -> {use_old_detection}")
        return use_old_detection

class Plugin:
    def _front_end_loaded(self):
        logger.log("Frontend loaded")

    def _load(self):
        logger.log("Backend loaded")
        logger.log(f"Plugin base dir: {PLUGIN_BASE_DIR}")
        Millennium.ready()

    def _unload(self):
        logger.log("Unloading")
